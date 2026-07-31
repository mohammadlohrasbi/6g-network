'use strict';

/* marketBlock — the resource market, injected into every spatial contract.
 *
 * The governing rule is that a contract only accepts what it can check for
 * itself. That rules out self-reported numbers and shapes every mechanism
 * here:
 *
 *   spectrum  the contract issued the grant, so it knows exactly how much
 *             an entity holds; sharing moves part of that grant
 *   energy    the contract meters every transmission, so the battery
 *             figure is its own, not the entity's claim
 *   compute   nothing on-chain can watch a CPU, so work is proven rather
 *             than reported: the worker searches for a nonce, the contract
 *             verifies it with a single hash
 *
 * Accounts are striped. A payment concentrates writes on whoever is paid,
 * and with eight operators that is eight keys taking every credit in the
 * block — the same read-modify-write contention that capacity tracking
 * showed. Splitting a balance across sub-keys spreads it; the stripe count
 * is configurable so the effect can be measured rather than assumed.
 */

module.exports = function marketBlock(contract, recordType) {
  return `
// ═══════════════════════════════════════════════════════════════════════
// Resource market — accounts, verifiable sharing, proof of work, relaying.
// ═══════════════════════════════════════════════════════════════════════

const (
    accountPrefix = "~ACC:"
    taskPrefix    = "~TASK:"
    grantPrefix   = "~GRANT:"
    defaultStripes     = int64(1)
    defaultPriceScale  = int64(1000)  // micro-tokens per µJ-equivalent
    defaultWorkReward  = int64(1000)
    maxDifficultyBits  = int64(24)
)

// Account is one participant's balance. It is stored across Stripes
// sub-keys: see stripeOf for why.
type Account struct {
    AccountID   string \`json:"accountID"\`
    Balance     int64  \`json:"balance"\`
    Earned      int64  \`json:"earned"\`
    Spent       int64  \`json:"spent"\`
    TxCount     int64  \`json:"txCount"\`
    Timestamp   string \`json:"timestamp"\`
}

// SpectrumGrant is what an entity holds and may sublet. The contract
// issued it, so the figure cannot be forged by the holder.
type SpectrumGrant struct {
    EntityID  string \`json:"entityID"\`
    Cell      string \`json:"servingCell"\`
    HeldHz    int64  \`json:"heldHz"\`
    SubletHz  int64  \`json:"subletHz"\`
    Timestamp string \`json:"timestamp"\`
}

// WorkTask is a unit of computation someone wants done. The reward is
// escrowed at post time, so a worker who solves it is certain to be paid.
type WorkTask struct {
    TaskID          string \`json:"taskID"\`
    Requester       string \`json:"requester"\`
    Challenge       string \`json:"challenge"\`
    DifficultyBits  int64  \`json:"difficultyBits"\`
    RewardMicro     int64  \`json:"rewardMicro"\`
    Worker          string \`json:"worker"\`
    Nonce           string \`json:"nonce"\`
    Solved          bool   \`json:"solved"\`
    PostedAt        string \`json:"postedAt"\`
    SolvedAt        string \`json:"solvedAt"\`
}

// RelayDeal records a two-hop delivery: the edge entity paid, the relay
// carried. Both figures come from the propagation model, not from either
// party.
type RelayDeal struct {
    DealID        string \`json:"dealID"\`
    EdgeEntity    string \`json:"edgeEntity"\`
    RelayEntity   string \`json:"relayEntity"\`
    DirectEnergy  int64  \`json:"directEnergyMicroJ"\`
    RelayedEnergy int64  \`json:"relayedEnergyMicroJ"\`
    SavedMicroJ   int64  \`json:"savedMicroJ"\`
    PaidMicro     int64  \`json:"paidMicro"\`
    Timestamp     string \`json:"timestamp"\`
}

/* ── striping ──────────────────────────────────────────────────────────
   Credits land on a stripe chosen from the transaction id, which every
   endorsing peer derives identically. Debits walk the stripes from the
   same starting point and take from the first that can cover the amount.  */

func stripeOf(ctx contractapi.TransactionContextInterface, accountID string, stripes int64) int64 {
    if stripes <= 1 {
        return 0
    }
    return int64(mix32(fnv1a(ctx.GetStub().GetTxID()+"|"+accountID))) % stripes
}

func stripeKey(accountID string, stripe int64) string {
    return accountPrefix + accountID + ":" + strconv.FormatInt(stripe, 10)
}

func (s *${contract}) readStripe(ctx contractapi.TransactionContextInterface, accountID string, stripe int64) (*Account, error) {
    b, err := ctx.GetStub().GetState(stripeKey(accountID, stripe))
    if err != nil {
        return nil, err
    }
    if b == nil {
        return &Account{AccountID: accountID}, nil
    }
    var a Account
    if err := json.Unmarshal(b, &a); err != nil {
        return nil, err
    }
    return &a, nil
}

func (s *${contract}) writeStripe(ctx contractapi.TransactionContextInterface, a *Account, stripe int64) error {
    a.Timestamp = txTimestamp(ctx)
    b, err := json.Marshal(a)
    if err != nil {
        return err
    }
    return ctx.GetStub().PutState(stripeKey(a.AccountID, stripe), b)
}

// credit adds to one stripe — the write that striping is meant to spread.
func (s *${contract}) credit(ctx contractapi.TransactionContextInterface, accountID string, amount int64, cfg *NetworkConfig) error {
    if amount <= 0 {
        return nil
    }
    st := stripeOf(ctx, accountID, cfg.Stripes)
    a, err := s.readStripe(ctx, accountID, st)
    if err != nil {
        return err
    }
    a.Balance += amount
    a.Earned += amount
    a.TxCount++
    return s.writeStripe(ctx, a, st)
}

// debit takes from the first stripe that can cover the amount, starting at
// the transaction's own stripe so concurrent debits do not all begin at
// stripe zero.
func (s *${contract}) debit(ctx contractapi.TransactionContextInterface, accountID string, amount int64, cfg *NetworkConfig) error {
    if amount <= 0 {
        return nil
    }
    start := stripeOf(ctx, accountID, cfg.Stripes)
    for i := int64(0); i < cfg.Stripes; i++ {
        st := (start + i) % cfg.Stripes
        a, err := s.readStripe(ctx, accountID, st)
        if err != nil {
            return err
        }
        if a.Balance >= amount {
            a.Balance -= amount
            a.Spent += amount
            a.TxCount++
            return s.writeStripe(ctx, a, st)
        }
    }
    return fmt.Errorf("%s cannot cover %d micro-tokens across %d stripes",
        accountID, amount, cfg.Stripes)
}

// Mint creates tokens. Bootstrap only — there is no supply counter, which
// deliberately avoids one global key every mint would contend on.
func (s *${contract}) Mint(ctx contractapi.TransactionContextInterface, accountID, amount string) error {
    cfg, err := s.loadConfig(ctx)
    if err != nil {
        return err
    }
    n, err := strconv.ParseInt(amount, 10, 64)
    if err != nil || n <= 0 {
        return fmt.Errorf("amount must be a positive whole number, got %q", amount)
    }
    return s.credit(ctx, accountID, n, cfg)
}

// BalanceOf sums every stripe.
func (s *${contract}) BalanceOf(ctx contractapi.TransactionContextInterface, accountID string) (*Account, error) {
    cfg, err := s.loadConfig(ctx)
    if err != nil {
        return nil, err
    }
    total := Account{AccountID: accountID}
    for st := int64(0); st < cfg.Stripes; st++ {
        a, err := s.readStripe(ctx, accountID, st)
        if err != nil {
            return nil, err
        }
        total.Balance += a.Balance
        total.Earned += a.Earned
        total.Spent += a.Spent
        total.TxCount += a.TxCount
    }
    return &total, nil
}

// Transfer moves tokens between accounts. Both keys are per-account, so
// entity-to-entity trade carries no shared-key contention — unlike paying
// an operator, where every payer writes the same few keys.
func (s *${contract}) Transfer(ctx contractapi.TransactionContextInterface, from, to, amount string) error {
    cfg, err := s.loadConfig(ctx)
    if err != nil {
        return err
    }
    if from == to {
        return fmt.Errorf("cannot transfer to the same account")
    }
    n, err := strconv.ParseInt(amount, 10, 64)
    if err != nil || n <= 0 {
        return fmt.Errorf("amount must be a positive whole number, got %q", amount)
    }
    if err := s.debit(ctx, from, n, cfg); err != nil {
        return err
    }
    return s.credit(ctx, to, n, cfg)
}

/* ── sharing what you actually hold ───────────────────────────────────── */

func (s *${contract}) grantOf(ctx contractapi.TransactionContextInterface, entityID string) (*SpectrumGrant, error) {
    b, err := ctx.GetStub().GetState(grantPrefix + entityID)
    if err != nil {
        return nil, err
    }
    if b == nil {
        return &SpectrumGrant{EntityID: entityID}, nil
    }
    var g SpectrumGrant
    if err := json.Unmarshal(b, &g); err != nil {
        return nil, err
    }
    return &g, nil
}

func (s *${contract}) saveGrant(ctx contractapi.TransactionContextInterface, g *SpectrumGrant) error {
    g.Timestamp = txTimestamp(ctx)
    b, err := json.Marshal(g)
    if err != nil {
        return err
    }
    return ctx.GetStub().PutState(grantPrefix+g.EntityID, b)
}

// GrantOf reports the spectrum an entity holds and how much it has sublet.
func (s *${contract}) GrantOf(ctx contractapi.TransactionContextInterface, entityID string) (*SpectrumGrant, error) {
    return s.grantOf(ctx, entityID)
}

// ShareBandwidth sublets part of a grant.
//
// The holder cannot invent capacity: the grant was issued by this contract
// when the entity was admitted, and the check below is against that record
// rather than against anything the caller says it owns.
func (s *${contract}) ShareBandwidth(ctx contractapi.TransactionContextInterface, from, to, hz, priceMicro string) error {
    cfg, err := s.loadConfig(ctx)
    if err != nil {
        return err
    }
    if from == to {
        return fmt.Errorf("cannot sublet to yourself")
    }
    amount, err := strconv.ParseInt(hz, 10, 64)
    if err != nil || amount <= 0 {
        return fmt.Errorf("hz must be a positive whole number, got %q", hz)
    }
    price := parseIntOr(priceMicro, 0)

    g, err := s.grantOf(ctx, from)
    if err != nil {
        return err
    }
    available := g.HeldHz - g.SubletHz
    if available < amount {
        return fmt.Errorf("%s holds %d Hz with %d already sublet, so only %d Hz is free",
            from, g.HeldHz, g.SubletHz, available)
    }

    recipient, err := s.grantOf(ctx, to)
    if err != nil {
        return err
    }
    if recipient.Cell == "" {
        recipient.Cell = g.Cell
    }
    if recipient.Cell != g.Cell {
        return fmt.Errorf("spectrum is only usable on the cell that issued it: %s holds %s, %s is on %s",
            from, g.Cell, to, recipient.Cell)
    }

    g.SubletHz += amount
    recipient.HeldHz += amount
    if err := s.saveGrant(ctx, g); err != nil {
        return err
    }
    if err := s.saveGrant(ctx, recipient); err != nil {
        return err
    }
    if price > 0 {
        if err := s.debit(ctx, to, price, cfg); err != nil {
            return err
        }
        return s.credit(ctx, from, price, cfg)
    }
    return nil
}

// ShareEnergy moves battery between entities.
//
// The budget is metered by this contract on every transmission, so what is
// moved here is a figure the contract itself produced.
func (s *${contract}) ShareEnergy(ctx contractapi.TransactionContextInterface, from, to, microJ, priceMicro string) error {
    cfg, err := s.loadConfig(ctx)
    if err != nil {
        return err
    }
    if from == to {
        return fmt.Errorf("cannot share energy with yourself")
    }
    amount, err := strconv.ParseInt(microJ, 10, 64)
    if err != nil || amount <= 0 {
        return fmt.Errorf("microJ must be a positive whole number, got %q", microJ)
    }
    price := parseIntOr(priceMicro, 0)

    donor, err := s.energyOf(ctx, from, cfg)
    if err != nil {
        return err
    }
    if donor.RemainingMicroJ < amount {
        return fmt.Errorf("%s has %d µJ, cannot share %d µJ",
            from, donor.RemainingMicroJ, amount)
    }
    receiver, err := s.energyOf(ctx, to, cfg)
    if err != nil {
        return err
    }

    donor.RemainingMicroJ -= amount
    receiver.RemainingMicroJ += amount
    if receiver.RemainingMicroJ > receiver.TotalMicroJ {
        receiver.TotalMicroJ = receiver.RemainingMicroJ
    }

    db, err := json.Marshal(donor)
    if err != nil {
        return err
    }
    if err := ctx.GetStub().PutState(energyPrefix+from, db); err != nil {
        return err
    }
    rb, err := json.Marshal(receiver)
    if err != nil {
        return err
    }
    if err := ctx.GetStub().PutState(energyPrefix+to, rb); err != nil {
        return err
    }

    if price > 0 {
        if err := s.debit(ctx, to, price, cfg); err != nil {
            return err
        }
        return s.credit(ctx, from, price, cfg)
    }
    return nil
}

/* ── verifiable computation ────────────────────────────────────────────
   Nothing on a ledger can observe a processor, so compute cannot be
   reported — it has to be proven. The scheme is the one the mining
   literature uses, repurposed: the requester states a challenge and a
   difficulty, the worker searches for a nonce whose hash clears the
   threshold, and the contract confirms it with a single hash.

   The asymmetry is the whole mechanism. At 16 bits the worker averages
   65536 hashes; the contract does one. A worker cannot claim work it did
   not do, and the network pays nothing to check.                          */

func workHash(challenge, nonce string) uint32 {
    return mix32(fnv1a(challenge + "|" + nonce))
}

// meetsDifficulty reports whether the hash has at least bits leading zeros.
func meetsDifficulty(h uint32, bits int64) bool {
    if bits <= 0 {
        return true
    }
    if bits >= 32 {
        return h == 0
    }
    return h < (uint32(1) << uint(32-bits))
}

// PostTask advertises work and escrows the reward, so a worker who solves
// it cannot be left unpaid.
func (s *${contract}) PostTask(ctx contractapi.TransactionContextInterface, taskID, requester, challenge, difficultyBits, rewardMicro string) error {
    cfg, err := s.loadConfig(ctx)
    if err != nil {
        return err
    }
    if taskID == "" || requester == "" || challenge == "" {
        return fmt.Errorf("taskID, requester and challenge are all required")
    }
    existing, err := ctx.GetStub().GetState(taskPrefix + taskID)
    if err != nil {
        return err
    }
    if existing != nil {
        return fmt.Errorf("task %s already exists", taskID)
    }

    bits := parseIntOr(difficultyBits, 16)
    if bits < 1 || bits > maxDifficultyBits {
        return fmt.Errorf("difficultyBits must be between 1 and %d, got %d", maxDifficultyBits, bits)
    }
    reward := parseIntOr(rewardMicro, cfg.WorkReward)
    if reward <= 0 {
        return fmt.Errorf("reward must be positive, got %d", reward)
    }

    // Escrow: the requester pays now, the worker is paid on proof.
    if err := s.debit(ctx, requester, reward, cfg); err != nil {
        return fmt.Errorf("cannot escrow the reward: %v", err)
    }

    t := WorkTask{
        TaskID:         taskID,
        Requester:      requester,
        Challenge:      challenge,
        DifficultyBits: bits,
        RewardMicro:    reward,
        PostedAt:       txTimestamp(ctx),
    }
    b, err := json.Marshal(t)
    if err != nil {
        return err
    }
    return ctx.GetStub().PutState(taskPrefix+taskID, b)
}

// SubmitWork claims a task with a nonce. The proof is checked here; a wrong
// nonce is rejected and nothing is paid.
func (s *${contract}) SubmitWork(ctx contractapi.TransactionContextInterface, taskID, worker, nonce string) error {
    cfg, err := s.loadConfig(ctx)
    if err != nil {
        return err
    }
    b, err := ctx.GetStub().GetState(taskPrefix + taskID)
    if err != nil {
        return err
    }
    if b == nil {
        return fmt.Errorf("no task %s", taskID)
    }
    var t WorkTask
    if err := json.Unmarshal(b, &t); err != nil {
        return err
    }
    if t.Solved {
        return fmt.Errorf("task %s was already solved by %s", taskID, t.Worker)
    }
    if worker == "" {
        return fmt.Errorf("worker is required")
    }

    if !meetsDifficulty(workHash(t.Challenge, nonce), t.DifficultyBits) {
        return fmt.Errorf(
            "nonce %q does not clear %d bits for challenge %q",
            nonce, t.DifficultyBits, t.Challenge)
    }

    t.Solved = true
    t.Worker = worker
    t.Nonce = nonce
    t.SolvedAt = txTimestamp(ctx)
    tb, err := json.Marshal(t)
    if err != nil {
        return err
    }
    if err := ctx.GetStub().PutState(taskPrefix+taskID, tb); err != nil {
        return err
    }
    return s.credit(ctx, worker, t.RewardMicro, cfg)
}

// TaskOf reads a task.
func (s *${contract}) TaskOf(ctx contractapi.TransactionContextInterface, taskID string) (*WorkTask, error) {
    b, err := ctx.GetStub().GetState(taskPrefix + taskID)
    if err != nil {
        return nil, err
    }
    if b == nil {
        return nil, fmt.Errorf("no task %s", taskID)
    }
    var t WorkTask
    if err := json.Unmarshal(b, &t); err != nil {
        return nil, err
    }
    return &t, nil
}

/* ── relaying ──────────────────────────────────────────────────────────
   The paper routes small-cell users through an SBS. The same idea works
   between entities: an edge device with a weak link sends through a
   neighbour that has a strong one.

   Both energy figures come from the propagation model, so neither party
   states its own saving. The relay is paid a share of what the edge entity
   avoided spending — capped so the deal is worthwhile for both.            */

func (s *${contract}) RelayFor(ctx contractapi.TransactionContextInterface, dealID, edgeEntity, edgeX, edgeY, relayEntity, relayX, relayY string) error {
    cfg, err := s.loadConfig(ctx)
    if err != nil {
        return err
    }
    if dealID == "" || edgeEntity == "" || relayEntity == "" {
        return fmt.Errorf("dealID, edgeEntity and relayEntity are all required")
    }
    if edgeEntity == relayEntity {
        return fmt.Errorf("an entity cannot relay for itself")
    }
    existing, err := ctx.GetStub().GetState(taskPrefix + "relay:" + dealID)
    if err != nil {
        return err
    }
    if existing != nil {
        return fmt.Errorf("deal %s already exists", dealID)
    }

    ex, err := parseCoord(edgeX)
    if err != nil {
        return err
    }
    ey, err := parseCoord(edgeY)
    if err != nil {
        return err
    }
    rx, err := parseCoord(relayX)
    if err != nil {
        return err
    }
    ry, err := parseCoord(relayY)
    if err != nil {
        return err
    }

    antennas, err := s.listAntennas(ctx)
    if err != nil {
        return err
    }
    edgeReports, _, err := s.evaluate(antennas, cfg, edgeEntity, ex, ey)
    if err != nil {
        return err
    }
    relayReports, _, err := s.evaluate(antennas, cfg, relayEntity, rx, ry)
    if err != nil {
        return err
    }
    edgeDirect := edgeReports[0]
    relayLink := relayReports[0]

    if edgeDirect.EnergyMicroJ < 0 || relayLink.EnergyMicroJ < 0 {
        return fmt.Errorf("neither path carries a usable rate")
    }
    if relayLink.SinrMilliDb <= edgeDirect.SinrMilliDb {
        return fmt.Errorf(
            "relaying gains nothing: %s sees %d mdB, %s sees %d mdB",
            relayEntity, relayLink.SinrMilliDb, edgeEntity, edgeDirect.SinrMilliDb)
    }

    // The device-to-device hop is short, so it costs far less than the
    // direct uplink. Its rate is derived the same way as any other link.
    d2dDist := DistanceM(ex, ey, rx, ry)
    d2dPl := PathLossMilliDb(d2dDist, defaultFreqMHz, cfg.PathLossExponentMilli)
    d2dRssi := RssiMilliDbm(cfg.TxPowerMilliDbm, 0, d2dPl, 0)
    d2dSinr := SinrMilliDb(d2dRssi, []int64{},
        NoiseFloorMilliDbm(defaultBandwidthHz, cfg.NoiseFigureMilliDb))
    d2dRate := ShannonBps(cfg.RequestHz, d2dSinr)
    d2dEnergy := TransmitEnergyMicroJ(cfg.TxPowerMilliDbm, cfg.PayloadBits, d2dRate)
    if d2dEnergy < 0 {
        return fmt.Errorf("the device-to-device hop carries no usable rate over %d m", d2dDist)
    }

    saved := edgeDirect.EnergyMicroJ - d2dEnergy
    if saved <= relayLink.EnergyMicroJ {
        return fmt.Errorf(
            "relaying costs more than it saves: %d µJ saved against %d µJ spent by the relay",
            saved, relayLink.EnergyMicroJ)
    }

    // The relay recovers its own cost plus a share of the surplus.
    surplus := saved - relayLink.EnergyMicroJ
    pay := ((relayLink.EnergyMicroJ + (surplus*cfg.RelayShareHundred)/100) * cfg.PriceScale) / 1000

    if err := s.debit(ctx, edgeEntity, pay, cfg); err != nil {
        return fmt.Errorf("%s cannot pay the relay: %v", edgeEntity, err)
    }
    if err := s.credit(ctx, relayEntity, pay, cfg); err != nil {
        return err
    }

    // Both parties spend the energy the model says they spend.
    if cfg.TrackEnergy {
        if err := s.spendEnergy(ctx, edgeEntity, d2dEnergy, cfg); err != nil {
            return err
        }
        if err := s.spendEnergy(ctx, relayEntity, relayLink.EnergyMicroJ, cfg); err != nil {
            return err
        }
    }

    deal := RelayDeal{
        DealID:        dealID,
        EdgeEntity:    edgeEntity,
        RelayEntity:   relayEntity,
        DirectEnergy:  edgeDirect.EnergyMicroJ,
        RelayedEnergy: d2dEnergy,
        SavedMicroJ:   saved,
        PaidMicro:     pay,
        Timestamp:     txTimestamp(ctx),
    }
    db, err := json.Marshal(deal)
    if err != nil {
        return err
    }
    return ctx.GetStub().PutState(taskPrefix+"relay:"+dealID, db)
}

// spendEnergy debits a battery, refusing rather than going negative.
func (s *${contract}) spendEnergy(ctx contractapi.TransactionContextInterface, entityID string, amount int64, cfg *NetworkConfig) error {
    b, err := s.energyOf(ctx, entityID, cfg)
    if err != nil {
        return err
    }
    if b.RemainingMicroJ < amount {
        return fmt.Errorf("%s has %d µJ but the hop costs %d µJ",
            entityID, b.RemainingMicroJ, amount)
    }
    b.RemainingMicroJ -= amount
    b.SpentMicroJ += amount
    b.TxCount++
    b.Timestamp = txTimestamp(ctx)
    bb, err := json.Marshal(b)
    if err != nil {
        return err
    }
    return ctx.GetStub().PutState(energyPrefix+entityID, bb)
}

// RelayOf reads a deal.
func (s *${contract}) RelayOf(ctx contractapi.TransactionContextInterface, dealID string) (*RelayDeal, error) {
    b, err := ctx.GetStub().GetState(taskPrefix + "relay:" + dealID)
    if err != nil {
        return nil, err
    }
    if b == nil {
        return nil, fmt.Errorf("no relay deal %s", dealID)
    }
    var d RelayDeal
    if err := json.Unmarshal(b, &d); err != nil {
        return nil, err
    }
    return &d, nil
}

// SetMarket configures the market.
//   stripes     sub-keys per account; 1 is the naive layout, higher spreads
//               the contention a payee otherwise concentrates
//   priceScale  micro-tokens per 1000 µJ of value
//   relayShare  the relay's cut of the surplus, in percent
//   workReward  default reward for a posted task
func (s *${contract}) SetMarket(ctx contractapi.TransactionContextInterface, stripes, priceScale, relayShare, workReward string) error {
    cfg, err := s.loadConfig(ctx)
    if err != nil {
        return err
    }
    cfg.Stripes = parseIntOr(stripes, cfg.Stripes)
    cfg.PriceScale = parseIntOr(priceScale, cfg.PriceScale)
    cfg.RelayShareHundred = parseIntOr(relayShare, cfg.RelayShareHundred)
    cfg.WorkReward = parseIntOr(workReward, cfg.WorkReward)

    if cfg.Stripes < 1 || cfg.Stripes > 256 {
        return fmt.Errorf("stripes must be between 1 and 256, got %d", cfg.Stripes)
    }
    if cfg.RelayShareHundred < 0 || cfg.RelayShareHundred > 100 {
        return fmt.Errorf("relayShare must be a percentage, got %d", cfg.RelayShareHundred)
    }
    cfgJSON, err := json.Marshal(cfg)
    if err != nil {
        return err
    }
    return ctx.GetStub().PutState(configKey, cfgJSON)
}
`;
};
