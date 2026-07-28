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
    if a.UsedCapacity > 0 {
        a.UsedCapacity--
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
}

// Defaults model a 3.5 GHz macrocell deployment.
const (
    defaultTxPowerMilliDbm = int64(46000)  // 46 dBm
    defaultGainMilliDb     = int64(15000)  // 15 dBi
    defaultFreqMHz         = int64(3500)   // 3.5 GHz
    defaultBandwidthHz     = int64(20000000)
    defaultMaxCapacity     = int64(100000) // effectively unlimited by default
    defaultGridSizeM       = int64(10000)  // 10 km square
    defaultAntennaCount    = int64(8)      // one per organization
    defaultExponentMilli   = int64(300)    // n = 3.0, urban
    defaultShadowSigma     = int64(8000)   // 8 dB
    defaultNoiseFigure     = int64(7000)   // 7 dB
    defaultMinSinr         = int64(-6000)  // −6 dB decoding floor
)

// SeedNetwork lays out the antenna grid. Placement is pseudo-random but
// derived entirely from the seed, so the same seed reproduces the same
// network on every peer and in every replay — which is what makes a
// benchmark comparable across runs.
//
// maxCapacity is how many entities one cell will admit. The default is high
// enough that a throughput benchmark never hits it — capacity refusals would
// otherwise appear partway through a long run and be mistaken for network
// degradation. Set it low deliberately when admission control is the subject
// of the experiment: load is uneven across cells, so with 8 antennas the
// busiest one takes roughly 20% of arrivals and saturates first.
//
// Passing "" for a numeric argument accepts the default.
func (s *${contract}) SeedNetwork(ctx contractapi.TransactionContextInterface, seed, antennaCount, gridSizeM, maxCapacity string) error {
    if seed == "" {
        return fmt.Errorf("a seed is required so the layout can be reproduced")
    }
    count := parseIntOr(antennaCount, defaultAntennaCount)
    grid := parseIntOr(gridSizeM, defaultGridSizeM)
    capacity := parseIntOr(maxCapacity, defaultMaxCapacity)
    if capacity < 1 {
        return fmt.Errorf("maxCapacity must be at least 1, got %d", capacity)
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
    if capacity < 1 {
        return fmt.Errorf("maxCapacity must be at least 1, got %d", capacity)
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

// evaluate is where the network decision actually happens.
//
// Every antenna is a candidate. Received power is computed for each one
// through path loss and a per-link shadow fade; the strongest becomes the
// serving cell and all the others become interference. SINR follows from
// summing that interference with thermal noise in the linear domain.
func (s *${contract}) evaluate(antennas []*Antenna, cfg *NetworkConfig, entityID string, x, y int64) (*CellReport, *Antenna, error) {
    var best *Antenna
    bestRssi := int64(-1 << 40)
    rssi := make([]int64, len(antennas))
    bestIdx := 0
    bestDist := int64(0)
    bestPl := int64(0)
    bestShadow := int64(0)

    for i, a := range antennas {
        d := DistanceM(x, y, a.X, a.Y)
        pl := PathLossMilliDb(d, a.FreqMHz, cfg.PathLossExponentMilli)
        sh := ShadowingMilliDb(cfg.Seed, entityID, a.AntennaID, cfg.ShadowSigmaMilliDb)
        rssi[i] = RssiMilliDbm(a.TxPowerMilliDbm, a.GainMilliDb, pl, sh)
        if rssi[i] > bestRssi {
            bestRssi = rssi[i]
            best = a
            bestIdx = i
            bestDist = d
            bestPl = pl
            bestShadow = sh
        }
    }
    if best == nil {
        return nil, nil, fmt.Errorf("no serving cell could be selected")
    }

    interferers := make([]int64, 0, len(antennas)-1)
    for i := range antennas {
        if i != bestIdx {
            interferers = append(interferers, rssi[i])
        }
    }
    noise := NoiseFloorMilliDbm(best.BandwidthHz, cfg.NoiseFigureMilliDb)
    sinr := SinrMilliDb(bestRssi, interferers, noise)

    return &CellReport{
        ServingCell:   best.AntennaID,
        DistanceM:     bestDist,
        RssiMilliDbm:  bestRssi,
        SinrMilliDb:   sinr,
        CapacityBps:   ShannonBps(best.BandwidthHz, sinr),
        PathLossMilli: bestPl,
        ShadowMilliDb: bestShadow,
        Candidates:    int64(len(antennas)),
        UsedCapacity:  best.UsedCapacity,
        MaxCapacity:   best.MaxCapacity,
    }, best, nil
}

// admit runs the evaluation and applies the two rules that can refuse a
// connection: coverage and capacity. Refusal is the point — before this
// change every transaction succeeded, because nothing was ever checked.
func (s *${contract}) admit(ctx contractapi.TransactionContextInterface, entityID string, x, y int64) (*CellReport, *Antenna, error) {
    cfg, err := s.loadConfig(ctx)
    if err != nil {
        return nil, nil, err
    }
    antennas, err := s.listAntennas(ctx)
    if err != nil {
        return nil, nil, err
    }
    rep, best, err := s.evaluate(antennas, cfg, entityID, x, y)
    if err != nil {
        return nil, nil, err
    }
    if rep.SinrMilliDb < cfg.MinSinrMilliDb {
        return rep, best, fmt.Errorf(
            "out of coverage: SINR %d mdB on %s is below the %d mdB threshold",
            rep.SinrMilliDb, rep.ServingCell, cfg.MinSinrMilliDb)
    }
    if best.UsedCapacity >= best.MaxCapacity {
        return rep, best, fmt.Errorf(
            "cell %s is saturated: %d of %d in use",
            best.AntennaID, best.UsedCapacity, best.MaxCapacity)
    }
    return rep, best, nil
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
    rep, _, err := s.evaluate(antennas, cfg, entityID, px, py)
    return rep, err
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
    if seed != "" {
        if cfg, cerr := s.loadConfig(ctx); cerr == nil && cfg.Seed != seed {
            return fmt.Errorf(
                "seed %q does not match the layout in place (%q) — re-seed before mixing scenarios",
                seed, cfg.Seed)
        }
    }

    rep, best, err := s.admit(ctx, ${keyParam}, px, py)
    if err != nil {
        return err
    }

    best.UsedCapacity++
    if err := s.saveAntenna(ctx, best); err != nil {
        return err
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

contracts=(
${spatial.map((r) => `    "${r.name}"`).join('\n')}
)

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

echo "Regenerated \${#contracts[@]} location-aware contracts."
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
