#!/usr/bin/env node
'use strict';

/* ═══════════════════════════════════════════════════════════════════════
   gen-spatial-contracts.js — regenerates the 34 location-aware contracts
   so they PERFORM network operations instead of merely recording them.

   Before: the contract was handed an antenna id and wrote whatever it was
   told. Seven of them could never run at all, because the only write
   function needed an antenna record that only it could create. The other
   27 computed distance against the map origin (0,0), which has no network
   meaning at all.

   After: every one of them
     · seeds its own antenna layout from a scenario seed,
     · selects the serving cell itself by strongest received power,
     · computes interference from every other cell and derives SINR,
     · refuses the connection when SINR is below threshold — out of coverage,
     · refuses it when the chosen cell is at capacity — admission control,
     · accounts for the load it just added, so the next call sees it.

   All radio maths comes from the integer kernel in radio.go: Fabric compares
   endorsement results byte for byte, and Go's math.Pow and math.Log10 carry
   no cross-platform bit guarantee. The existing calculateDistance already
   used math.Pow on float64 — a latent risk that only stayed hidden because
   all eight peers run one binary.

   Output: scripts/generateChaincodes_spatial.sh
   ═══════════════════════════════════════════════════════════════════════ */

const fs = require('fs');
const path = require('path');

const deep = require('/tmp/deep.json');
const marketBlock = require('./market-block');
const RADIO_GO = fs.readFileSync(
  path.join(__dirname, '..', 'radio', 'radio.go'), 'utf8');

// Strip the package clause; the kernel is appended into each contract file.
const RADIO_BODY = RADIO_GO.slice(RADIO_GO.indexOf('package main') + 'package main'.length).trim();

const spatial = deep.filter((r) => r.spatial && r.primary);

/* ── parameter transformation ────────────────────────────────────────
   antennaID leaves the signature: the contract now chooses the serving
   cell rather than being told which one to use. seed joins it, so the
   layout a transaction is evaluated against is reproducible.          */
function newParams(r) {
  if (isAntennaSubject(r)) {
    // The antenna is what this contract acts on, so its id stays and x,y
    // are where the antenna is being moved to.
    const domain = r.primary.params.filter((p) => p.name !== 'x' && p.name !== 'y');
    return [...domain.map((p) => p.name), 'x', 'y', 'seed'];
  }
  const domain = r.primary.params
    .filter((p) => p.name !== 'x' && p.name !== 'y' && p.name !== 'antennaID');
  return [...domain.map((p) => p.name), 'x', 'y', 'seed'];
}

/* A contract whose first parameter is antennaID operates ON a cell rather
   than being served BY one. Dropping the id there would leave the record
   keyed on a config string, and the contract would have nothing to act on. */
function isAntennaSubject(r) {
  return r.primary.params[0] && r.primary.params[0].name === 'antennaID';
}

const goStr = (s) => JSON.stringify(s);

/* ── the shared network-model block ──────────────────────────────── */
function networkBlock(contract, recordType, withRelease) {
  // Release is only meaningful where the record names a serving cell; the
  // antenna-subject contract has no such field, so it omits this method.
  const releaseBlock = !withRelease ? '' : `
// Release gives back one unit of capacity — the counterpart to admission,
// so a long benchmark does not saturate every cell and stall.
func (s *${contract}) Release(ctx contractapi.TransactionContextInterface, entityID string) error {
    b, err := ctx.GetStub().GetState(entityID)
    if err != nil {
        return err
    }
    if b == nil {
        return fmt.Errorf("%s holds no allocation", entityID)
    }
    var rec ${recordType}
    if err := json.Unmarshal(b, &rec); err != nil {
        return err
    }
    if rec.ServingCell == "" {
        return fmt.Errorf("%s has no serving cell recorded", entityID)
    }
    ab, err := ctx.GetStub().GetState(antennaPrefix + rec.ServingCell)
    if err != nil {
        return err
    }
    if ab == nil {
        return fmt.Errorf("serving cell %s is not registered", rec.ServingCell)
    }
    var a Antenna
    if err := json.Unmarshal(ab, &a); err != nil {
        return err
    }
    cfg, cerr := s.loadConfig(ctx)
    if cerr != nil {
        return cerr
    }
    if a.UsedCapacity > 0 {
        a.UsedCapacity--
    }
    if cfg.TrackBandwidth {
        a.AllocatedHz -= cfg.RequestHz
        if a.AllocatedHz < 0 {
            a.AllocatedHz = 0
        }
    }
    if err := s.saveAntenna(ctx, &a); err != nil {
        return err
    }
    return ctx.GetStub().DelState(entityID)
}
`;

  return `
// ═══════════════════════════════════════════════════════════════════════
// Network model — antenna registry, cell selection and admission control.
//
// Each chaincode in Fabric owns an isolated state space, so a contract
// cannot see antennas registered by any other chaincode. Every contract
// therefore keeps its own registry, seeded through SeedNetwork.
//
// Key layout: entity records keep their bare id, so QueryAsset is unchanged.
// Model keys carry a "~" prefix, which sorts after alphanumerics and lets
// QueryAllAssets skip them.
// ═══════════════════════════════════════════════════════════════════════

const antennaPrefix = "~ANT:"
const configKey = "~CFG"

// Antenna is one macrocell: where it is, what it radiates, how loaded it is.
type Antenna struct {
    AntennaID       string \`json:"antennaID"\`
    X               int64  \`json:"x"\`
    Y               int64  \`json:"y"\`
    TxPowerMilliDbm int64  \`json:"txPowerMilliDbm"\`
    GainMilliDb     int64  \`json:"gainMilliDb"\`
    FreqMHz         int64  \`json:"freqMHz"\`
    BandwidthHz     int64  \`json:"bandwidthHz"\`
    MaxCapacity     int64  \`json:"maxCapacity"\`
    UsedCapacity    int64  \`json:"usedCapacity"\`
    AllocatedHz     int64  \`json:"allocatedHz"\`
    LoadFactor      int64  \`json:"loadFactorHundredths"\`
    EarnedMicro     int64  \`json:"earnedMicro"\`
}

// NetworkConfig holds the propagation parameters the whole cell layout
// shares. Stored once at seed time so every later transaction evaluates
// against the same environment.
type NetworkConfig struct {
    Seed                  string \`json:"seed"\`
    GridSizeM             int64  \`json:"gridSizeM"\`
    AntennaCount          int64  \`json:"antennaCount"\`
    PathLossExponentMilli int64  \`json:"pathLossExponentMilli"\`
    ShadowSigmaMilliDb    int64  \`json:"shadowSigmaMilliDb"\`
    NoiseFigureMilliDb    int64  \`json:"noiseFigureMilliDb"\`
    MinSinrMilliDb        int64  \`json:"minSinrMilliDb"\`
    TrackCapacity         bool   \`json:"trackCapacity"\`

    // Resource accounting, modelled on the uplink cost formulation in
    // Zuo, Jin & Zhang (VTC2021-Fall): a bandwidth share per entity, a
    // rate that follows from that share, and an energy budget spent at
    // e = P·D/R with the constraint e ≤ E_max.
    //
    // Both are off by default. Turning on bandwidth means writing the
    // cell record on every admission, which is a read-modify-write on one
    // of only eight keys — see SetCapacity for what that costs. Energy is
    // keyed per entity, so it carries no such contention.
    TrackBandwidth        bool   \`json:"trackBandwidth"\`
    RequestHz             int64  \`json:"requestHz"\`
    TrackEnergy           bool   \`json:"trackEnergy"\`
    EnergyBudgetMicroJ    int64  \`json:"energyBudgetMicroJ"\`
    TxPowerMilliDbm       int64  \`json:"txPowerMilliDbm"\`
    PayloadBits           int64  \`json:"payloadBits"\`

    // Association policy. "nearest" picks the strongest cell and stops —
    // the traditional NBA rule. "loadaware" implements Algorithm 2 of Zuo,
    // Jin & Zhang: walk the candidates strongest-first and take the first
    // one whose load is still under its share, so a busy cell hands its
    // overflow to the next-best rather than refusing service.
    // Market
    Stripes               int64  \`json:"stripes"\`
    PriceScale            int64  \`json:"priceScale"\`
    RelayShareHundred     int64  \`json:"relaySharePercent"\`
    WorkReward            int64  \`json:"workReward"\`

    AssociationMode       string \`json:"associationMode"\`
    LoadToleranceHundred  int64  \`json:"loadToleranceHundredths"\`

    // Charging, following the cost/revenue structure of the same paper:
    // users pay for the spectrum they hold and the data they move, and the
    // operator of the serving cell is credited.
    TrackEconomy          bool   \`json:"trackEconomy"\`
    PricePerKHzMicro      int64  \`json:"pricePerKHzMicro"\`
    PricePerKbitMicro     int64  \`json:"pricePerKbitMicro"\`
    InitialBalanceMicro   int64  \`json:"initialBalanceMicro"\`
}

// TokenAccount is one entity's wallet. Like the energy budget it lives
// under its own key, so spending never contends between entities.
type TokenAccount struct {
    EntityID     string \`json:"entityID"\`
    BalanceMicro int64  \`json:"balanceMicro"\`
    SpentMicro   int64  \`json:"spentMicro"\`
    TxCount      int64  \`json:"txCount"\`
    Timestamp    string \`json:"timestamp"\`
}

// EnergyBudget is one entity's battery. It lives under its own key, so
// two entities never contend — the asymmetry with the shared bandwidth
// pool is the point worth measuring.
type EnergyBudget struct {
    EntityID        string \`json:"entityID"\`
    TotalMicroJ     int64  \`json:"totalMicroJ"\`
    RemainingMicroJ int64  \`json:"remainingMicroJ"\`
    SpentMicroJ     int64  \`json:"spentMicroJ"\`
    TxCount         int64  \`json:"txCount"\`
    Timestamp       string \`json:"timestamp"\`
}

// CellReport is what the radio evaluation produces for one position.
type CellReport struct {
    ServingCell   string \`json:"servingCell"\`
    DistanceM     int64  \`json:"distanceM"\`
    RssiMilliDbm  int64  \`json:"rssiMilliDbm"\`
    SinrMilliDb   int64  \`json:"sinrMilliDb"\`
    CapacityBps   int64  \`json:"capacityBps"\`
    PathLossMilli int64  \`json:"pathLossMilliDb"\`
    ShadowMilliDb int64  \`json:"shadowMilliDb"\`
    Candidates    int64  \`json:"candidates"\`
    UsedCapacity  int64  \`json:"usedCapacity"\`
    MaxCapacity   int64  \`json:"maxCapacity"\`
    GrantedHz     int64  \`json:"grantedHz"\`
    FreeHz        int64  \`json:"freeHz"\`
    TxTimeMicroS  int64  \`json:"txTimeMicroS"\`
    EnergyMicroJ  int64  \`json:"energyMicroJ"\`
    Rank          int64  \`json:"rank"\`
}

// CellLoad is one cell's spectrum load against the share it should carry.
type CellLoad struct {
    AntennaID    string \`json:"antennaID"\`
    AllocatedHz  int64  \`json:"allocatedHz"\`
    BandwidthHz  int64  \`json:"bandwidthHz"\`
    FairShareHz  int64  \`json:"fairShareHz"\`
    DeviationHz  int64  \`json:"deviationHz"\`
    UsedCapacity int64  \`json:"usedCapacity"\`
    EarnedMicro  int64  \`json:"earnedMicro"\`
}

// Defaults model a 3.5 GHz macrocell deployment.
const (
    defaultTxPowerMilliDbm = int64(46000)  // 46 dBm
    defaultGainMilliDb     = int64(15000)  // 15 dBi
    defaultFreqMHz         = int64(3500)   // 3.5 GHz
    defaultBandwidthHz     = int64(20000000)
    defaultMaxCapacity     = int64(0)      // 0 = unlimited, capacity not tracked
    defaultGridSizeM       = int64(10000)  // 10 km square
    defaultAntennaCount    = int64(8)      // one per organization
    defaultExponentMilli   = int64(300)    // n = 3.0, urban
    defaultShadowSigma     = int64(8000)   // 8 dB
    defaultNoiseFigure     = int64(7000)   // 7 dB
    defaultMinSinr         = int64(-6000)  // −6 dB decoding floor
    defaultRequestHz       = int64(100000) // 100 kHz per entity
    defaultEnergyMicroJ    = int64(5000000) // 5 J, the budget used in the paper
    defaultTxPowerMilliDbm = int64(23000)  // 23 dBm entity uplink
    defaultPayloadBits     = int64(3808)   // 608-bit header + 100 × 32-bit
    defaultLoadFactor      = int64(100)    // ε = 1.0; a macro tier would be higher
    defaultLoadTolerance   = int64(120)    // admit up to 1.2× the fair share
    defaultPricePerKHz     = int64(10)     // micro-coin per kHz held
    defaultPricePerKbit    = int64(100)    // micro-coin per kbit moved
    defaultInitialBalance  = int64(1000000000) // 1000 coins
    energyPrefix           = "~NRG:"
    tokenPrefix            = "~TOK:"
)

// SeedNetwork lays out the antenna grid. Placement is pseudo-random but
// derived entirely from the seed, so the same seed reproduces the same
// network on every peer and in every replay — which is what makes a
// benchmark comparable across runs.
//
// maxCapacity is how many entities one cell will admit. Zero — the default —
// means unlimited AND turns off capacity accounting entirely.
//
// That second half matters more than it looks. Counting admissions means
// incrementing a field on the serving cell's record, which is a
// read-modify-write on one of only eight keys. Fabric validates read sets
// after ordering: when several transactions in the same block read the same
// key at the same version, one commits and the rest are rejected with
// MVCC_READ_CONFLICT. At 20 tps the busiest cell takes about eight
// transactions per block, so roughly 20% would survive; at 109 tps, under 4%.
// A throughput benchmark would be measuring lock contention on eight keys
// rather than anything about the network.
//
// So capacity tracking is opt-in. Turn it on when admission control is the
// subject of the experiment — the contention is then the finding, not an
// artefact — and leave it off when measuring throughput.
//
// Passing "" for a numeric argument accepts the default.
func (s *${contract}) SeedNetwork(ctx contractapi.TransactionContextInterface, seed, antennaCount, gridSizeM, maxCapacity string) error {
    if seed == "" {
        return fmt.Errorf("a seed is required so the layout can be reproduced")
    }
    count := parseIntOr(antennaCount, defaultAntennaCount)
    grid := parseIntOr(gridSizeM, defaultGridSizeM)
    capacity := parseIntOr(maxCapacity, defaultMaxCapacity)
    if capacity < 0 {
        return fmt.Errorf("maxCapacity cannot be negative, got %d", capacity)
    }
    if count < 1 || count > 256 {
        return fmt.Errorf("antennaCount must be between 1 and 256, got %d", count)
    }
    if grid < 100 {
        return fmt.Errorf("gridSizeM must be at least 100, got %d", grid)
    }

    for i := int64(0); i < count; i++ {
        id := fmt.Sprintf("antenna-%d", i+1)
        x, y := PlaceOnGrid(seed, id, grid)
        a := Antenna{
            AntennaID:       id,
            X:               x,
            Y:               y,
            TxPowerMilliDbm: defaultTxPowerMilliDbm,
            GainMilliDb:     defaultGainMilliDb,
            FreqMHz:         defaultFreqMHz,
            BandwidthHz:     defaultBandwidthHz,
            MaxCapacity:     capacity,
            UsedCapacity:    0,
            AllocatedHz:     0,
            LoadFactor:      defaultLoadFactor,
            EarnedMicro:     0,
        }
        if err := s.saveAntenna(ctx, &a); err != nil {
            return err
        }
    }

    cfg := NetworkConfig{
        Seed:                  seed,
        GridSizeM:             grid,
        AntennaCount:          count,
        PathLossExponentMilli: defaultExponentMilli,
        ShadowSigmaMilliDb:    defaultShadowSigma,
        NoiseFigureMilliDb:    defaultNoiseFigure,
        MinSinrMilliDb:        defaultMinSinr,
        TrackCapacity:         capacity > 0,
        TrackBandwidth:        false,
        RequestHz:             defaultRequestHz,
        TrackEnergy:           false,
        EnergyBudgetMicroJ:    defaultEnergyMicroJ,
        TxPowerMilliDbm:       defaultTxPowerMilliDbm,
        PayloadBits:           defaultPayloadBits,
        Stripes:               defaultStripes,
        PriceScale:            defaultPriceScale,
        RelayShareHundred:     50,
        WorkReward:            defaultWorkReward,
        AssociationMode:       "nearest",
        LoadToleranceHundred:  defaultLoadTolerance,
        TrackEconomy:          false,
        PricePerKHzMicro:      defaultPricePerKHz,
        PricePerKbitMicro:     defaultPricePerKbit,
        InitialBalanceMicro:   defaultInitialBalance,
    }
    cfgJSON, err := json.Marshal(cfg)
    if err != nil {
        return err
    }
    return ctx.GetStub().PutState(configKey, cfgJSON)
}

// SetPropagation overrides the environment without moving the antennas, so
// a sweep can vary one parameter at a time.
func (s *${contract}) SetPropagation(ctx contractapi.TransactionContextInterface, exponentMilli, shadowSigmaMilliDb, minSinrMilliDb string) error {
    cfg, err := s.loadConfig(ctx)
    if err != nil {
        return err
    }
    cfg.PathLossExponentMilli = parseIntOr(exponentMilli, cfg.PathLossExponentMilli)
    cfg.ShadowSigmaMilliDb = parseIntOr(shadowSigmaMilliDb, cfg.ShadowSigmaMilliDb)
    cfg.MinSinrMilliDb = parseIntOr(minSinrMilliDb, cfg.MinSinrMilliDb)
    if cfg.PathLossExponentMilli < 150 || cfg.PathLossExponentMilli > 600 {
        return fmt.Errorf("path-loss exponent must be between 1.5 and 6.0")
    }
    cfgJSON, err := json.Marshal(cfg)
    if err != nil {
        return err
    }
    return ctx.GetStub().PutState(configKey, cfgJSON)
}

// SetCapacity re-caps every cell without moving them, so an admission-control
// sweep can vary the limit while holding the layout fixed.
func (s *${contract}) SetCapacity(ctx contractapi.TransactionContextInterface, maxCapacity string) error {
    capacity := parseIntOr(maxCapacity, defaultMaxCapacity)
    if capacity < 0 {
        return fmt.Errorf("maxCapacity cannot be negative, got %d", capacity)
    }
    antennas, err := s.listAntennas(ctx)
    if err != nil {
        return err
    }
    for _, a := range antennas {
        a.MaxCapacity = capacity
        if err := s.saveAntenna(ctx, a); err != nil {
            return err
        }
    }
    return nil
}

// SetResources turns the two accounting mechanisms on or off and sets
// their parameters. Both default to off so a throughput benchmark is not
// silently measuring something else.
//
//   requestHz     spectrum each entity is granted; 0 keeps the current value
//   energyMicroJ  starting battery per entity
//   txPowerMdbm   entity uplink power, used for e = P·D/R
//   payloadBits   how much each transaction transmits
//
// Pass "off" for trackBandwidth or trackEnergy to disable, "on" to enable.
func (s *${contract}) SetResources(ctx contractapi.TransactionContextInterface, trackBandwidth, trackEnergy, requestHz, energyMicroJ, txPowerMdbm, payloadBits string) error {
    cfg, err := s.loadConfig(ctx)
    if err != nil {
        return err
    }
    if trackBandwidth != "" {
        cfg.TrackBandwidth = trackBandwidth == "on" || trackBandwidth == "true"
    }
    if trackEnergy != "" {
        cfg.TrackEnergy = trackEnergy == "on" || trackEnergy == "true"
    }
    cfg.RequestHz = parseIntOr(requestHz, cfg.RequestHz)
    cfg.EnergyBudgetMicroJ = parseIntOr(energyMicroJ, cfg.EnergyBudgetMicroJ)
    cfg.TxPowerMilliDbm = parseIntOr(txPowerMdbm, cfg.TxPowerMilliDbm)
    cfg.PayloadBits = parseIntOr(payloadBits, cfg.PayloadBits)

    if cfg.RequestHz < 1 {
        return fmt.Errorf("requestHz must be positive, got %d", cfg.RequestHz)
    }
    if cfg.PayloadBits < 1 {
        return fmt.Errorf("payloadBits must be positive, got %d", cfg.PayloadBits)
    }
    cfgJSON, err := json.Marshal(cfg)
    if err != nil {
        return err
    }
    return ctx.GetStub().PutState(configKey, cfgJSON)
}

// SetAssociation switches between the traditional nearest-cell rule and
// the load-aware alternative, and sets how far above its share a cell may
// go before it starts handing entities on.
//
//   mode       "nearest" or "loadaware"
//   tolerance  hundredths; 120 means 1.2× the fair share
func (s *${contract}) SetAssociation(ctx contractapi.TransactionContextInterface, mode, toleranceHundredths string) error {
    cfg, err := s.loadConfig(ctx)
    if err != nil {
        return err
    }
    if mode != "" {
        if mode != "nearest" && mode != "loadaware" {
            return fmt.Errorf("mode must be \"nearest\" or \"loadaware\", got %q", mode)
        }
        cfg.AssociationMode = mode
    }
    cfg.LoadToleranceHundred = parseIntOr(toleranceHundredths, cfg.LoadToleranceHundred)
    if cfg.LoadToleranceHundred < 100 {
        return fmt.Errorf("tolerance below 100 would refuse every cell")
    }
    cfgJSON, err := json.Marshal(cfg)
    if err != nil {
        return err
    }
    return ctx.GetStub().PutState(configKey, cfgJSON)
}

// SetTier sets one cell's load factor — ε_m in the paper. A macro cell
// carrying twice its neighbours' load is SetTier("antenna-1", "200").
func (s *${contract}) SetTier(ctx contractapi.TransactionContextInterface, antennaID, loadFactorHundredths string) error {
    b, err := ctx.GetStub().GetState(antennaPrefix + antennaID)
    if err != nil {
        return err
    }
    if b == nil {
        return fmt.Errorf("antenna %s is not registered", antennaID)
    }
    var a Antenna
    if err := json.Unmarshal(b, &a); err != nil {
        return err
    }
    a.LoadFactor = parseIntOr(loadFactorHundredths, a.LoadFactor)
    if a.LoadFactor < 1 {
        return fmt.Errorf("load factor must be positive")
    }
    return s.saveAntenna(ctx, &a)
}

// SetEconomy turns charging on or off and sets the tariff.
func (s *${contract}) SetEconomy(ctx contractapi.TransactionContextInterface, track, pricePerKHz, pricePerKbit, initialBalance string) error {
    cfg, err := s.loadConfig(ctx)
    if err != nil {
        return err
    }
    if track != "" {
        cfg.TrackEconomy = track == "on" || track == "true"
    }
    cfg.PricePerKHzMicro = parseIntOr(pricePerKHz, cfg.PricePerKHzMicro)
    cfg.PricePerKbitMicro = parseIntOr(pricePerKbit, cfg.PricePerKbitMicro)
    cfg.InitialBalanceMicro = parseIntOr(initialBalance, cfg.InitialBalanceMicro)
    cfgJSON, err := json.Marshal(cfg)
    if err != nil {
        return err
    }
    return ctx.GetStub().PutState(configKey, cfgJSON)
}

// energyOf reads an entity's battery, creating it at full charge on first
// use so a benchmark does not need a separate provisioning pass.
func (s *${contract}) energyOf(ctx contractapi.TransactionContextInterface, entityID string, cfg *NetworkConfig) (*EnergyBudget, error) {
    b, err := ctx.GetStub().GetState(energyPrefix + entityID)
    if err != nil {
        return nil, err
    }
    if b == nil {
        return &EnergyBudget{
            EntityID:        entityID,
            TotalMicroJ:     cfg.EnergyBudgetMicroJ,
            RemainingMicroJ: cfg.EnergyBudgetMicroJ,
        }, nil
    }
    var e EnergyBudget
    if err := json.Unmarshal(b, &e); err != nil {
        return nil, err
    }
    return &e, nil
}

// EnergyOf reports an entity's remaining battery.
func (s *${contract}) EnergyOf(ctx contractapi.TransactionContextInterface, entityID string) (*EnergyBudget, error) {
    cfg, err := s.loadConfig(ctx)
    if err != nil {
        return nil, err
    }
    return s.energyOf(ctx, entityID, cfg)
}

// RechargeEntity restores a battery to full — the counterpart to depletion.
func (s *${contract}) RechargeEntity(ctx contractapi.TransactionContextInterface, entityID string) error {
    cfg, err := s.loadConfig(ctx)
    if err != nil {
        return err
    }
    e := EnergyBudget{
        EntityID:        entityID,
        TotalMicroJ:     cfg.EnergyBudgetMicroJ,
        RemainingMicroJ: cfg.EnergyBudgetMicroJ,
        Timestamp:       txTimestamp(ctx),
    }
    b, err := json.Marshal(e)
    if err != nil {
        return err
    }
    return ctx.GetStub().PutState(energyPrefix+entityID, b)
}

// SpectrumStatus reports how much of each cell's spectrum is committed.
func (s *${contract}) SpectrumStatus(ctx contractapi.TransactionContextInterface) ([]*Antenna, error) {
    return s.listAntennas(ctx)
}

// transactionCost prices one service grant, following the cost structure
// of the paper: a charge for the spectrum held and a charge for the data
// moved. Deterministic and integer, like everything else here.
func transactionCost(cfg *NetworkConfig) int64 {
    spectrum := (cfg.RequestHz / 1000) * cfg.PricePerKHzMicro
    data := (cfg.PayloadBits / 1000) * cfg.PricePerKbitMicro
    return spectrum + data
}

func (s *${contract}) accountOf(ctx contractapi.TransactionContextInterface, entityID string, cfg *NetworkConfig) (*TokenAccount, error) {
    b, err := ctx.GetStub().GetState(tokenPrefix + entityID)
    if err != nil {
        return nil, err
    }
    if b == nil {
        return &TokenAccount{EntityID: entityID, BalanceMicro: cfg.InitialBalanceMicro}, nil
    }
    var a TokenAccount
    if err := json.Unmarshal(b, &a); err != nil {
        return nil, err
    }
    return &a, nil
}

// BalanceOf reports an entity's wallet.
func (s *${contract}) BalanceOf(ctx contractapi.TransactionContextInterface, entityID string) (*TokenAccount, error) {
    cfg, err := s.loadConfig(ctx)
    if err != nil {
        return nil, err
    }
    return s.accountOf(ctx, entityID, cfg)
}

// Credit tops up a wallet.
func (s *${contract}) Credit(ctx contractapi.TransactionContextInterface, entityID, amountMicro string) error {
    cfg, err := s.loadConfig(ctx)
    if err != nil {
        return err
    }
    amount := parseIntOr(amountMicro, 0)
    if amount <= 0 {
        return fmt.Errorf("amount must be positive, got %d", amount)
    }
    acct, err := s.accountOf(ctx, entityID, cfg)
    if err != nil {
        return err
    }
    acct.BalanceMicro += amount
    acct.Timestamp = txTimestamp(ctx)
    b, err := json.Marshal(acct)
    if err != nil {
        return err
    }
    return ctx.GetStub().PutState(tokenPrefix+entityID, b)
}

// Transfer moves value between two wallets.
//
// Both keys are per-entity, so two transfers between different pairs never
// contend. Two transfers from the SAME payer in one block do — that is the
// account-model limit in Fabric, and it is inherent rather than a defect
// of this code.
func (s *${contract}) Transfer(ctx contractapi.TransactionContextInterface, fromID, toID, amountMicro string) error {
    if fromID == toID {
        return fmt.Errorf("cannot transfer to the same account")
    }
    cfg, err := s.loadConfig(ctx)
    if err != nil {
        return err
    }
    amount := parseIntOr(amountMicro, 0)
    if amount <= 0 {
        return fmt.Errorf("amount must be positive, got %d", amount)
    }
    from, err := s.accountOf(ctx, fromID, cfg)
    if err != nil {
        return err
    }
    if from.BalanceMicro < amount {
        return fmt.Errorf("%s has %d micro-coin, cannot send %d",
            fromID, from.BalanceMicro, amount)
    }
    to, err := s.accountOf(ctx, toID, cfg)
    if err != nil {
        return err
    }
    from.BalanceMicro -= amount
    from.SpentMicro += amount
    from.Timestamp = txTimestamp(ctx)
    to.BalanceMicro += amount
    to.Timestamp = txTimestamp(ctx)

    fb, err := json.Marshal(from)
    if err != nil {
        return err
    }
    if err := ctx.GetStub().PutState(tokenPrefix+fromID, fb); err != nil {
        return err
    }
    tb, err := json.Marshal(to)
    if err != nil {
        return err
    }
    return ctx.GetStub().PutState(tokenPrefix+toID, tb)
}

// Quote prices a service grant without charging for it.
func (s *${contract}) Quote(ctx contractapi.TransactionContextInterface) (int64, error) {
    cfg, err := s.loadConfig(ctx)
    if err != nil {
        return 0, err
    }
    return transactionCost(cfg), nil
}

func (s *${contract}) saveAntenna(ctx contractapi.TransactionContextInterface, a *Antenna) error {
    b, err := json.Marshal(a)
    if err != nil {
        return err
    }
    return ctx.GetStub().PutState(antennaPrefix+a.AntennaID, b)
}

func (s *${contract}) loadConfig(ctx contractapi.TransactionContextInterface) (*NetworkConfig, error) {
    b, err := ctx.GetStub().GetState(configKey)
    if err != nil {
        return nil, fmt.Errorf("failed to read the network config: %v", err)
    }
    if b == nil {
        return nil, fmt.Errorf("no antenna layout yet — call SeedNetwork first")
    }
    var cfg NetworkConfig
    if err := json.Unmarshal(b, &cfg); err != nil {
        return nil, err
    }
    return &cfg, nil
}

func (s *${contract}) listAntennas(ctx contractapi.TransactionContextInterface) ([]*Antenna, error) {
    it, err := ctx.GetStub().GetStateByRange(antennaPrefix, antennaPrefix+"\\uffff")
    if err != nil {
        return nil, err
    }
    defer it.Close()

    var out []*Antenna
    for it.HasNext() {
        kv, err := it.Next()
        if err != nil {
            return nil, err
        }
        var a Antenna
        if err := json.Unmarshal(kv.Value, &a); err != nil {
            continue
        }
        out = append(out, &a)
    }
    if len(out) == 0 {
        return nil, fmt.Errorf("no antennas registered — call SeedNetwork first")
    }
    return out, nil
}

// evaluate ranks every cell for a position.
//
// Received power is computed for each antenna through path loss and a
// per-link shadow fade. The candidates come back ordered strongest-first;
// for each one, SINR treats that cell as the server and all others as
// interference, so the figures are correct whichever candidate is finally
// chosen. That is what makes Algorithm 2 possible: falling back to the
// second-best cell needs the second-best cell's SINR, not the first's.
func (s *${contract}) evaluate(antennas []*Antenna, cfg *NetworkConfig, entityID string, x, y int64) ([]*CellReport, []*Antenna, error) {
    n := len(antennas)
    if n == 0 {
        return nil, nil, fmt.Errorf("no antennas registered")
    }

    rssi := make([]int64, n)
    dist := make([]int64, n)
    pl := make([]int64, n)
    shadow := make([]int64, n)

    for i, a := range antennas {
        dist[i] = DistanceM(x, y, a.X, a.Y)
        pl[i] = PathLossMilliDb(dist[i], a.FreqMHz, cfg.PathLossExponentMilli)
        shadow[i] = ShadowingMilliDb(cfg.Seed, entityID, a.AntennaID, cfg.ShadowSigmaMilliDb)
        rssi[i] = RssiMilliDbm(a.TxPowerMilliDbm, a.GainMilliDb, pl[i], shadow[i])
    }

    // Order by received power, strongest first. Insertion sort: eight cells
    // makes anything cleverer pointless, and this stays deterministic.
    order := make([]int, n)
    for i := range order {
        order[i] = i
    }
    for i := 1; i < n; i++ {
        k := order[i]
        j := i - 1
        for j >= 0 && rssi[order[j]] < rssi[k] {
            order[j+1] = order[j]
            j--
        }
        order[j+1] = k
    }

    reports := make([]*CellReport, n)
    cells := make([]*Antenna, n)

    for rank, idx := range order {
        a := antennas[idx]
        interferers := make([]int64, 0, n-1)
        for j := range antennas {
            if j != idx {
                interferers = append(interferers, rssi[j])
            }
        }
        noise := NoiseFloorMilliDbm(a.BandwidthHz, cfg.NoiseFigureMilliDb)
        sinr := SinrMilliDb(rssi[idx], interferers, noise)

        // With spectrum accounting on, the achievable rate follows from the
        // slice this entity is granted rather than the whole cell. That is
        // the difference between "this link could carry 77 Mbps" and "this
        // entity can carry 0.39 Mbps".
        rateBandwidth := a.BandwidthHz
        granted := int64(0)
        free := a.BandwidthHz
        if cfg.TrackBandwidth {
            granted = cfg.RequestHz
            free = a.BandwidthHz - a.AllocatedHz
            rateBandwidth = cfg.RequestHz
        }
        capacity := ShannonBps(rateBandwidth, sinr)

        reports[rank] = &CellReport{
            ServingCell:   a.AntennaID,
            DistanceM:     dist[idx],
            RssiMilliDbm:  rssi[idx],
            SinrMilliDb:   sinr,
            CapacityBps:   capacity,
            PathLossMilli: pl[idx],
            ShadowMilliDb: shadow[idx],
            Candidates:    int64(n),
            UsedCapacity:  a.UsedCapacity,
            MaxCapacity:   a.MaxCapacity,
            GrantedHz:     granted,
            FreeHz:        free,
            TxTimeMicroS:  TransmitTimeMicroS(cfg.PayloadBits, capacity),
            EnergyMicroJ:  TransmitEnergyMicroJ(cfg.TxPowerMilliDbm, cfg.PayloadBits, capacity),
            Rank:          int64(rank + 1),
        }
        cells[rank] = a
    }
    return reports, cells, nil
}

// fairShareHz is the load each cell would carry if spectrum were spread
// evenly, scaled by that cell's tier factor — X̄ and ε_m in the paper.
func fairShareHz(antennas []*Antenna) int64 {
    total := int64(0)
    for _, a := range antennas {
        total += a.AllocatedHz
    }
    return total / int64(len(antennas))
}

// loadDeviation is |Σ X_j − ε_m·X̄|, the balance metric the paper reports.
func loadDeviation(a *Antenna, share int64) int64 {
    target := (share * a.LoadFactor) / 100
    d := a.AllocatedHz - target
    if d < 0 {
        return -d
    }
    return d
}

// LoadBalance reports each cell's spectrum load against its fair share.
// Lower deviation means better balance — the comparison the paper draws
// between nearest-cell association and its load-aware alternative.
func (s *${contract}) LoadBalance(ctx contractapi.TransactionContextInterface) ([]*CellLoad, error) {
    antennas, err := s.listAntennas(ctx)
    if err != nil {
        return nil, err
    }
    share := fairShareHz(antennas)
    out := make([]*CellLoad, 0, len(antennas))
    for _, a := range antennas {
        out = append(out, &CellLoad{
            AntennaID:   a.AntennaID,
            AllocatedHz: a.AllocatedHz,
            BandwidthHz: a.BandwidthHz,
            FairShareHz: (share * a.LoadFactor) / 100,
            DeviationHz: loadDeviation(a, share),
            UsedCapacity: a.UsedCapacity,
            EarnedMicro: a.EarnedMicro,
        })
    }
    return out, nil
}

// admit chooses a cell and applies every constraint that can refuse one.
//
// Under "nearest" only the strongest candidate is considered, and a full
// cell means refusal. Under "loadaware" the candidates are walked in order
// and the first one that clears every check wins — so an overloaded cell
// sheds to its neighbour instead of dropping the entity.
func (s *${contract}) admit(ctx contractapi.TransactionContextInterface, entityID string, x, y int64) (*CellReport, *Antenna, error) {
    cfg, err := s.loadConfig(ctx)
    if err != nil {
        return nil, nil, err
    }
    antennas, err := s.listAntennas(ctx)
    if err != nil {
        return nil, nil, err
    }
    reports, cells, err := s.evaluate(antennas, cfg, entityID, x, y)
    if err != nil {
        return nil, nil, err
    }

    loadAware := cfg.AssociationMode == "loadaware" && cfg.TrackBandwidth
    share := fairShareHz(antennas)

    // The paper computes X̄ from the whole user population up front. A
    // ledger sees entities one at a time, so the running average stands in
    // for it — but early on that average is near zero and the rule would
    // refuse every cell. It only starts biting once there is load to
    // balance, which is one grant per cell.
    applyLoadRule := loadAware && share >= cfg.RequestHz

    var firstRep *CellReport
    var firstCell *Antenna
    var lastErr error

    // Two passes. The first honours the load rule; if no cell is under its
    // share, the second drops that rule and takes the best cell that has
    // room. Refusing service because every cell is busy would be worse than
    // an unbalanced assignment.
    for pass := 0; pass < 2; pass++ {
        useLoadRule := applyLoadRule && pass == 0
        if pass == 1 && !applyLoadRule {
            break // the first pass already had no load rule
        }
        limit := 1
        if loadAware {
            limit = len(reports)
        }

        for i := 0; i < limit; i++ {
            rep, cell := reports[i], cells[i]
            if firstRep == nil {
                firstRep, firstCell = rep, cell
            }

            if rep.SinrMilliDb < cfg.MinSinrMilliDb {
                lastErr = fmt.Errorf(
                    "out of coverage: SINR %d mdB on %s is below the %d mdB threshold",
                    rep.SinrMilliDb, rep.ServingCell, cfg.MinSinrMilliDb)
                continue
            }
            if cfg.TrackCapacity && cell.UsedCapacity >= cell.MaxCapacity {
                lastErr = fmt.Errorf("cell %s is saturated: %d of %d in use",
                    cell.AntennaID, cell.UsedCapacity, cell.MaxCapacity)
                continue
            }
            if cfg.TrackBandwidth && cell.AllocatedHz+cfg.RequestHz > cell.BandwidthHz {
                lastErr = fmt.Errorf("cell %s has no spectrum left: %d Hz free, %d Hz requested",
                    cell.AntennaID, cell.BandwidthHz-cell.AllocatedHz, cfg.RequestHz)
                continue
            }
            if useLoadRule {
                tolerated := (share * cell.LoadFactor * cfg.LoadToleranceHundred) / 10000
                if cell.AllocatedHz+cfg.RequestHz > tolerated {
                    lastErr = fmt.Errorf("cell %s is above its share: %d Hz against %d Hz tolerated",
                        cell.AntennaID, cell.AllocatedHz, tolerated)
                    continue
                }
            }

            if cfg.TrackEnergy {
                if rep.EnergyMicroJ < 0 {
                    lastErr = fmt.Errorf("link to %s carries no usable rate", cell.AntennaID)
                    continue
                }
                budget, berr := s.energyOf(ctx, entityID, cfg)
                if berr != nil {
                    return rep, cell, berr
                }
                if budget.RemainingMicroJ < rep.EnergyMicroJ {
                    // A flat battery is the entity's problem, not the cell's,
                    // so another cell cannot help — a weaker one costs more.
                    return rep, cell, fmt.Errorf(
                        "%s has %d µJ left but the transmission costs %d µJ",
                        entityID, budget.RemainingMicroJ, rep.EnergyMicroJ)
                }
            }

            if cfg.TrackEconomy {
                cost := transactionCost(cfg)
                acct, aerr := s.accountOf(ctx, entityID, cfg)
                if aerr != nil {
                    return rep, cell, aerr
                }
                if acct.BalanceMicro < cost {
                    return rep, cell, fmt.Errorf(
                        "%s has %d micro-coin but the service costs %d",
                        entityID, acct.BalanceMicro, cost)
                }
            }

            return rep, cell, nil
        }
    }

    if lastErr == nil {
        lastErr = fmt.Errorf("no cell could serve this position")
    }
    return firstRep, firstCell, lastErr
}

// ServingCell reports which cell would serve a position, without writing.
// A planning query rather than a connection request.
func (s *${contract}) ServingCell(ctx contractapi.TransactionContextInterface, entityID, x, y string) (*CellReport, error) {
    cfg, err := s.loadConfig(ctx)
    if err != nil {
        return nil, err
    }
    antennas, err := s.listAntennas(ctx)
    if err != nil {
        return nil, err
    }
    px, err := parseCoord(x)
    if err != nil {
        return nil, err
    }
    py, err := parseCoord(y)
    if err != nil {
        return nil, err
    }
    reports, _, err := s.evaluate(antennas, cfg, entityID, px, py)
    if err != nil {
        return nil, err
    }
    return reports[0], nil
}

// RankCells returns every candidate for a position, strongest first — what
// load-aware association walks through when the best cell is busy.
func (s *${contract}) RankCells(ctx contractapi.TransactionContextInterface, entityID, x, y string) ([]*CellReport, error) {
    cfg, err := s.loadConfig(ctx)
    if err != nil {
        return nil, err
    }
    antennas, err := s.listAntennas(ctx)
    if err != nil {
        return nil, err
    }
    px, err := parseCoord(x)
    if err != nil {
        return nil, err
    }
    py, err := parseCoord(y)
    if err != nil {
        return nil, err
    }
    reports, _, err := s.evaluate(antennas, cfg, entityID, px, py)
    return reports, err
}

// NetworkStatus returns the current load of every cell.
func (s *${contract}) NetworkStatus(ctx contractapi.TransactionContextInterface) ([]*Antenna, error) {
    return s.listAntennas(ctx)
}

${releaseBlock}
// ── helpers ─────────────────────────────────────────────────────────

func parseCoord(v string) (int64, error) {
    n, err := strconv.ParseInt(v, 10, 64)
    if err != nil {
        return 0, fmt.Errorf("coordinate %q must be a whole number of metres", v)
    }
    return n, nil
}

func parseIntOr(v string, fallback int64) int64 {
    if v == "" {
        return fallback
    }
    n, err := strconv.ParseInt(v, 10, 64)
    if err != nil {
        return fallback
    }
    return n
}

func txTimestamp(ctx contractapi.TransactionContextInterface) string {
    ts, err := ctx.GetStub().GetTxTimestamp()
    if err != nil {
        return ""
    }
    return time.Unix(ts.Seconds, int64(ts.Nanos)).UTC().Format(time.RFC3339Nano)
}
`;
}

/* ── the record type and the rewritten primary function ────────────── */
function antennaSubjectSource(r) {
  const c = r.name;
  const rec = r.struct.name;
  const params = newParams(r);
  const domain = params.filter((p) => p !== 'x' && p !== 'y' && p !== 'seed' && p !== 'antennaID');
  const carried = r.struct.fields.filter((f) =>
    !['x', 'y', 'distance', 'timestamp', 'antennaID'].includes(f.json));
  const fieldLines = carried.map((f) => `    ${f.name} string \`json:${goStr(f.json)}\``);
  const assignLines = carried.map((f) => {
    const src = domain.find((p) => p.toLowerCase() === f.json.toLowerCase());
    return `        ${f.name}: ${src || goStr('')},`;
  });

  return `package main

import (
    "encoding/json"
    "fmt"
    "strconv"
    "time"

    "github.com/hyperledger/fabric-contract-api-go/contractapi"
)

type ${c} struct {
    contractapi.Contract
}

// ${rec} records a cell reconfiguration: where the antenna now stands and
// what coverage that produces.
type ${rec} struct {
    AntennaID     string \`json:"antennaID"\`
${fieldLines.join('\n')}
    X             int64  \`json:"x"\`
    Y             int64  \`json:"y"\`
    CoverageM     int64  \`json:"coverageRadiusM"\`
    EdgeRssiMilli int64  \`json:"edgeRssiMilliDbm"\`
    Timestamp     string \`json:"timestamp"\`
}

func (s *${c}) Init(ctx contractapi.TransactionContextInterface) error {
    return nil
}

// ${r.primary.name} moves a cell and records the coverage that results.
//
// This contract acts ON an antenna rather than being served BY one: the
// antenna is relocated to (x,y), the registry is updated so every later
// evaluation sees the new position, and the resulting coverage radius is
// computed from the propagation model.
//
// Note for benchmarking: updating the registry is inherent here, not
// optional as it is in the serving contracts. There are only eight cells,
// so several transactions in one block will touch the same record and all
// but one will be rejected with MVCC_READ_CONFLICT. That is not a defect —
// reconfiguring a cell is genuinely a serialised operation — but it means
// this contract measures contention rather than throughput. Benchmark it at
// a low rate, or read the rejection rate as the result.
func (s *${c}) ${r.primary.name}(ctx contractapi.TransactionContextInterface, ${params.join(', ')} string) error {
    if antennaID == "" {
        return fmt.Errorf("antennaID is required")
    }
    px, err := parseCoord(x)
    if err != nil {
        return err
    }
    py, err := parseCoord(y)
    if err != nil {
        return err
    }
    cfg, err := s.loadConfig(ctx)
    if err != nil {
        return err
    }
    if seed != "" && cfg.Seed != seed {
        return fmt.Errorf(
            "seed %q does not match the layout in place (%q) — re-seed before mixing scenarios",
            seed, cfg.Seed)
    }
    if px < 0 || py < 0 || px > cfg.GridSizeM || py > cfg.GridSizeM {
        return fmt.Errorf("position (%d,%d) is outside the %d m grid", px, py, cfg.GridSizeM)
    }

    ab, err := ctx.GetStub().GetState(antennaPrefix + antennaID)
    if err != nil {
        return err
    }
    if ab == nil {
        return fmt.Errorf("antenna %s is not registered — call SeedNetwork first", antennaID)
    }
    var a Antenna
    if err := json.Unmarshal(ab, &a); err != nil {
        return err
    }

    a.X, a.Y = px, py
    if err := s.saveAntenna(ctx, &a); err != nil {
        return err
    }

    radius, edge := s.coverageRadius(&a, cfg)
    record := ${rec}{
        AntennaID:     antennaID,
${assignLines.join('\n')}
        X:             px,
        Y:             py,
        CoverageM:     radius,
        EdgeRssiMilli: edge,
        Timestamp:     txTimestamp(ctx),
    }
    recordJSON, err := json.Marshal(record)
    if err != nil {
        return err
    }
    return ctx.GetStub().PutState(antennaID, recordJSON)
}

// coverageRadius finds the furthest distance at which the cell still clears
// the noise floor by the SINR margin, by bisection over the path-loss curve.
func (s *${c}) coverageRadius(a *Antenna, cfg *NetworkConfig) (int64, int64) {
    noise := NoiseFloorMilliDbm(a.BandwidthHz, cfg.NoiseFigureMilliDb)
    target := noise + cfg.MinSinrMilliDb
    lo, hi := int64(1), cfg.GridSizeM*2
    for lo < hi {
        mid := (lo + hi + 1) / 2
        pl := PathLossMilliDb(mid, a.FreqMHz, cfg.PathLossExponentMilli)
        if RssiMilliDbm(a.TxPowerMilliDbm, a.GainMilliDb, pl, 0) >= target {
            lo = mid
        } else {
            hi = mid - 1
        }
    }
    pl := PathLossMilliDb(lo, a.FreqMHz, cfg.PathLossExponentMilli)
    return lo, RssiMilliDbm(a.TxPowerMilliDbm, a.GainMilliDb, pl, 0)
}

func (s *${c}) QueryAsset(ctx contractapi.TransactionContextInterface, antennaID string) (*${rec}, error) {
    assetJSON, err := ctx.GetStub().GetState(antennaID)
    if err != nil {
        return nil, fmt.Errorf("failed to read from world state: %v", err)
    }
    if assetJSON == nil {
        return nil, fmt.Errorf("record %s does not exist", antennaID)
    }
    var asset ${rec}
    if err := json.Unmarshal(assetJSON, &asset); err != nil {
        return nil, err
    }
    return &asset, nil
}

// QueryAllAssets skips the model keys, which carry the "~" prefix.
func (s *${c}) QueryAllAssets(ctx contractapi.TransactionContextInterface) ([]*${rec}, error) {
    it, err := ctx.GetStub().GetStateByRange("", "")
    if err != nil {
        return nil, err
    }
    defer it.Close()

    var assets []*${rec}
    for it.HasNext() {
        kv, err := it.Next()
        if err != nil {
            return nil, err
        }
        if len(kv.Key) > 0 && kv.Key[0] == '~' {
            continue
        }
        var asset ${rec}
        if err := json.Unmarshal(kv.Value, &asset); err != nil {
            continue
        }
        assets = append(assets, &asset)
    }
    return assets, nil
}

// ValidateCoverage reports whether a position falls inside the cell's radius.
func (s *${c}) ValidateCoverage(ctx contractapi.TransactionContextInterface, antennaID string) (bool, error) {
    asset, err := s.QueryAsset(ctx, antennaID)
    if err != nil {
        return false, err
    }
    return asset.CoverageM > 0, nil
}
${networkBlock(c, rec, false)}
${marketBlock(c, rec)}
${RADIO_BODY}

func main() {
    chaincode, err := contractapi.NewChaincode(new(${c}))
    if err != nil {
        fmt.Printf("Error creating chaincode: %v\\n", err)
        return
    }
    if err := chaincode.Start(); err != nil {
        fmt.Printf("Error starting chaincode: %v\\n", err)
    }
}
`;
}

function contractSource(r) {
  if (isAntennaSubject(r)) return antennaSubjectSource(r);
  const c = r.name;
  const rec = r.struct.name;
  const params = newParams(r);
  const domain = params.filter((p) => p !== 'x' && p !== 'y' && p !== 'seed');
  const keyParam = domain[0] || 'entityID';

  // Domain fields carried over from the original record, minus the ones
  // the radio evaluation now owns.
  const carried = r.struct.fields.filter((f) =>
    !['x', 'y', 'distance', 'timestamp', 'antennaID'].includes(f.json));

  const fieldLines = carried.map((f) =>
    `    ${f.name} string \`json:${goStr(f.json)}\``);

  const assignLines = carried.map((f) => {
    const src = domain.find((p) => p.toLowerCase() === f.json.toLowerCase());
    return `        ${f.name}: ${src || goStr('')},`;
  });

  const sig = params.map((p) => p).join(', ');

  return `package main

import (
    "encoding/json"
    "fmt"
    "strconv"
    "time"

    "github.com/hyperledger/fabric-contract-api-go/contractapi"
)

type ${c} struct {
    contractapi.Contract
}

// ${rec} is what a successful admission writes: the domain fields the
// caller supplied, plus the radio outcome the contract computed.
type ${rec} struct {
${fieldLines.join('\n')}
    X             int64  \`json:"x"\`
    Y             int64  \`json:"y"\`
    ServingCell   string \`json:"servingCell"\`
    DistanceM     int64  \`json:"distanceM"\`
    RssiMilliDbm  int64  \`json:"rssiMilliDbm"\`
    SinrMilliDb   int64  \`json:"sinrMilliDb"\`
    CapacityBps   int64  \`json:"capacityBps"\`
    GrantedHz     int64  \`json:"grantedHz"\`
    TxTimeMicroS  int64  \`json:"txTimeMicroS"\`
    EnergyMicroJ  int64  \`json:"energyMicroJ"\`
    Timestamp     string \`json:"timestamp"\`
}

func (s *${c}) Init(ctx contractapi.TransactionContextInterface) error {
    return nil
}

// ${r.primary.name} requests service at a position.
//
// The caller no longer names an antenna — the contract picks the serving
// cell, checks coverage and capacity, and may refuse. On success the load
// it added is written back, so the next caller sees a fuller cell.
func (s *${c}) ${r.primary.name}(ctx contractapi.TransactionContextInterface, ${sig} string) error {
    if ${keyParam} == "" {
        return fmt.Errorf("${keyParam} is required")
    }
    px, err := parseCoord(x)
    if err != nil {
        return err
    }
    py, err := parseCoord(y)
    if err != nil {
        return err
    }
    cfg, err := s.loadConfig(ctx)
    if err != nil {
        return err
    }
    if seed != "" && cfg.Seed != seed {
        return fmt.Errorf(
            "seed %q does not match the layout in place (%q) — re-seed before mixing scenarios",
            seed, cfg.Seed)
    }
    trackCapacity := cfg.TrackCapacity

    rep, best, err := s.admit(ctx, ${keyParam}, px, py)
    if err != nil {
        return err
    }

    // Writing the cell back is what creates the hot key, so it only happens
    // when something on the cell actually changes. See SeedNetwork.
    cellChanged := false
    if trackCapacity {
        best.UsedCapacity++
        cellChanged = true
    }
    if cfg.TrackBandwidth {
        best.AllocatedHz += cfg.RequestHz
        cellChanged = true
    }
    // The operator of the serving cell is credited for the service. This
    // lands on the cell record, which is already a hot key when spectrum
    // is tracked — see SetCapacity for what that costs.
    if cfg.TrackEconomy {
        best.EarnedMicro += transactionCost(cfg)
        cellChanged = true
    }
    if cellChanged {
        if err := s.saveAntenna(ctx, best); err != nil {
            return err
        }
    }

    // The wallet is keyed per entity, so debiting never contends between
    // entities — unlike crediting the operator above.
    if cfg.TrackEconomy {
        acct, aerr := s.accountOf(ctx, ${keyParam}, cfg)
        if aerr != nil {
            return aerr
        }
        cost := transactionCost(cfg)
        acct.BalanceMicro -= cost
        acct.SpentMicro += cost
        acct.TxCount++
        acct.Timestamp = txTimestamp(ctx)
        ab, aerr := json.Marshal(acct)
        if aerr != nil {
            return aerr
        }
        if aerr := ctx.GetStub().PutState(tokenPrefix+${keyParam}, ab); aerr != nil {
            return aerr
        }
    }

    // Record what this entity now holds, so a later sublet can be checked
    // against a figure this contract issued rather than one the caller
    // claims to own.
    if cfg.TrackBandwidth {
        g, gerr := s.grantOf(ctx, ${keyParam})
        if gerr != nil {
            return gerr
        }
        g.Cell = rep.ServingCell
        g.HeldHz += cfg.RequestHz
        if gerr := s.saveGrant(ctx, g); gerr != nil {
            return gerr
        }
    }

    // The battery is keyed per entity, so this write never contends.
    if cfg.TrackEnergy {
        budget, berr := s.energyOf(ctx, ${keyParam}, cfg)
        if berr != nil {
            return berr
        }
        budget.RemainingMicroJ -= rep.EnergyMicroJ
        budget.SpentMicroJ += rep.EnergyMicroJ
        budget.TxCount++
        budget.Timestamp = txTimestamp(ctx)
        bb, berr := json.Marshal(budget)
        if berr != nil {
            return berr
        }
        if berr := ctx.GetStub().PutState(energyPrefix+${keyParam}, bb); berr != nil {
            return berr
        }
    }

    record := ${rec}{
${assignLines.join('\n')}
        X:            px,
        Y:            py,
        ServingCell:  rep.ServingCell,
        DistanceM:    rep.DistanceM,
        RssiMilliDbm: rep.RssiMilliDbm,
        SinrMilliDb:  rep.SinrMilliDb,
        CapacityBps:  rep.CapacityBps,
        GrantedHz:    rep.GrantedHz,
        TxTimeMicroS: rep.TxTimeMicroS,
        EnergyMicroJ: rep.EnergyMicroJ,
        Timestamp:    txTimestamp(ctx),
    }
    recordJSON, err := json.Marshal(record)
    if err != nil {
        return err
    }
    return ctx.GetStub().PutState(${keyParam}, recordJSON)
}

func (s *${c}) QueryAsset(ctx contractapi.TransactionContextInterface, ${keyParam} string) (*${rec}, error) {
    assetJSON, err := ctx.GetStub().GetState(${keyParam})
    if err != nil {
        return nil, fmt.Errorf("failed to read from world state: %v", err)
    }
    if assetJSON == nil {
        return nil, fmt.Errorf("record %s does not exist", ${keyParam})
    }
    var asset ${rec}
    if err := json.Unmarshal(assetJSON, &asset); err != nil {
        return nil, err
    }
    return &asset, nil
}

// QueryAllAssets skips the model keys, which carry the "~" prefix.
func (s *${c}) QueryAllAssets(ctx contractapi.TransactionContextInterface) ([]*${rec}, error) {
    it, err := ctx.GetStub().GetStateByRange("", "")
    if err != nil {
        return nil, err
    }
    defer it.Close()

    var assets []*${rec}
    for it.HasNext() {
        kv, err := it.Next()
        if err != nil {
            return nil, err
        }
        if len(kv.Key) > 0 && kv.Key[0] == '~' {
            continue
        }
        var asset ${rec}
        if err := json.Unmarshal(kv.Value, &asset); err != nil {
            continue
        }
        assets = append(assets, &asset)
    }
    return assets, nil
}

// ValidateCoverage answers whether a recorded entity still meets the SINR
// threshold — the decision a real network makes before a handover.
func (s *${c}) ValidateCoverage(ctx contractapi.TransactionContextInterface, ${keyParam} string) (bool, error) {
    asset, err := s.QueryAsset(ctx, ${keyParam})
    if err != nil {
        return false, err
    }
    cfg, err := s.loadConfig(ctx)
    if err != nil {
        return false, err
    }
    return asset.SinrMilliDb >= cfg.MinSinrMilliDb, nil
}
${networkBlock(c, rec, true)}
${marketBlock(c, rec)}
${RADIO_BODY}

func main() {
    chaincode, err := contractapi.NewChaincode(new(${c}))
    if err != nil {
        fmt.Printf("Error creating chaincode: %v\\n", err)
        return
    }
    if err := chaincode.Start(); err != nil {
        fmt.Printf("Error starting chaincode: %v\\n", err)
    }
}
`;
}

/* ── emit the bash generator ─────────────────────────────────────── */
const parts = [`#!/bin/bash
# generateChaincodes_spatial.sh — regenerates the ${spatial.length} location-aware contracts
# with a real radio model: serving-cell selection, SINR, admission control
# and capacity accounting.
#
# Generated by scripts/gen-spatial-contracts.js — do not edit by hand.
#
# Run it from the repository root, exactly like the generateChaincodes_part*
# scripts, then upgrade the affected chaincodes.

set -e

# The generated Go lands beside the part5..10 scripts, in scripts/chaincode —
# that is where deploy_functions.sh looks for it. Anchoring to this script's
# own location rather than the current directory means it no longer matters
# where you run it from; running from the repository root used to put the
# contracts one level up, and deploy then reported "directory not found".
SCRIPT_DIR="$(cd "$(dirname "\${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

ALL_CONTRACTS=(
${spatial.map((r) => `    "${r.name}"`).join('\n')}
)

# With no arguments every location-aware contract is regenerated. Named
# arguments narrow it down, which is what the replacement part1-4 scripts
# use so the README's generateChaincodes_part*.sh loop keeps working and
# stays order-independent.
if [ $# -gt 0 ]; then
    contracts=("$@")
    for want in "\${contracts[@]}"; do
        found=0
        for have in "\${ALL_CONTRACTS[@]}"; do
            [ "$want" = "$have" ] && found=1 && break
        done
        if [ "$found" = "0" ]; then
            echo "$want is not a location-aware contract — it is generated by generateChaincodes_part5..10.sh" >&2
            exit 1
        fi
    done
else
    contracts=("\${ALL_CONTRACTS[@]}")
fi

for contract in "\${contracts[@]}"; do
    mkdir -p chaincode/$contract
    case $contract in`];

for (const r of spatial) {
  parts.push(`        ${r.name})
            cat > chaincode/$contract/chaincode.go <<'CHAINCODE_EOF'
${contractSource(r)}CHAINCODE_EOF
            ;;`);
}

parts.push(`        *)
            echo "No template for $contract" >&2
            exit 1
            ;;
    esac

    (
      cd chaincode/$contract
      if [ ! -f go.mod ]; then
          go mod init $contract >/dev/null 2>&1
      fi
      go mod edit -require=github.com/hyperledger/fabric-contract-api-go@v1.2.1
      go mod tidy >/dev/null 2>&1
      go mod vendor >/dev/null 2>&1
    )
done

echo "Regenerated \${#contracts[@]} of \${#ALL_CONTRACTS[@]} location-aware contracts in $SCRIPT_DIR/chaincode"
for contract in "\${contracts[@]}"; do
    if [ -f "chaincode/$contract/chaincode.go" ]; then
        echo " - $contract: OK"
    else
        echo " - $contract: Failed"
    fi
done`);

const outPath = process.argv[2] || '/home/claude/work/out/scripts/generateChaincodes_spatial.sh';
fs.writeFileSync(outPath, parts.join('\n') + '\n', 'utf8');

// A machine-readable summary of the new signatures, so the benchmark
// catalog can be regenerated from the same source of truth.
const sig = spatial.map((r) => ({
  contract: r.name,
  channels: r.channels,
  fn: r.primary.name,
  params: newParams(r),
  wasLocked: r.blocked === 'needs-seed',
  record: r.struct.name,
}));
fs.writeFileSync('/tmp/spatial-signatures.json', JSON.stringify(sig, null, 1));

console.log(`wrote ${outPath}`);
console.log(`contracts: ${spatial.length} (${sig.filter((s) => s.wasLocked).length} previously unrunnable)`);
