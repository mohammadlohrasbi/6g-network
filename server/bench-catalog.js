'use strict';

/* ═══════════════════════════════════════════════════════════════════════
   bench-catalog.js — single source of truth for benchmark targets.

   Both the Tape runner and the Caliper asset generator read from here, so
   a contract's write function and its argument shape are defined exactly
   once. Derived from contract-fn-map.js (the 84 mapped contracts) and
   CHANNEL_CHAINCODE_MAP in fabric.js (which contract lives on which
   channel).

   A "target" is one (channel, contract) pair. Every benchmark run — from
   a single contract to a full 20-channel sweep — is just a list of
   targets, so the same code path serves every mode in the UI.
   ═══════════════════════════════════════════════════════════════════════ */

const { CONTRACT_FN } = require('./contract-fn-map');

// Canonical channel → contract map, mirroring scripts/channel_contract_map.sh.
// It lives here rather than being imported from fabric.js so this module
// stays loadable without the Fabric SDK — the Caliper asset generator runs
// it from the command line. fabric.js keeps an identical copy for the
// ledger routes; assertCatalogInSync() below flags any divergence.
const CHANNEL_CHAINCODE_MAP = {
  networkchannel: ['LocationBasedNetworkLoad', 'LocationBasedNetworkHealth', 'ManageNetwork', 'MonitorNetwork'],
  resourcechannel: ['LocationBasedResourceAllocation', 'LocationBasedIoTResource', 'AllocateResource', 'LogResourceAudit', 'MonitorResourceUsage'],
  performancechannel: ['LocationBasedLatency', 'LogPerformance', 'LogNetworkPerformance', 'LogPerformanceAudit'],
  iotchannel: ['LocationBasedIoTConnection', 'LocationBasedIoTBandwidth', 'LocationBasedIoTStatus', 'LocationBasedIoTFault', 'LocationBasedIoTSession', 'ManageIoTDevice', 'MonitorIoT', 'LogIoTActivity'],
  authchannel: ['LocationBasedIoTAuthentication', 'AuthenticateUser', 'AuthenticateIoT', 'VerifyIdentity'],
  connectivitychannel: ['LocationBasedConnection', 'LocationBasedRoaming', 'ConnectUser', 'ConnectIoT', 'LogConnectionAudit'],
  sessionchannel: ['LocationBasedSessionManagement', 'LocationBasedIoTSession', 'ManageSession', 'LogSession', 'LogSessionAudit'],
  policychannel: ['SetPolicy', 'GetPolicy', 'UpdatePolicy', 'LogPolicyAudit', 'LogPolicyChange'],
  auditchannel: ['LogNetworkAudit', 'LogAntennaAudit', 'LogIoTAudit', 'LogUserAudit', 'LogAccessAudit', 'LogSecurityAudit', 'LogComplianceAudit'],
  securitychannel: ['EncryptData', 'DecryptData', 'SecureCommunication', 'LogSecurityEvent'],
  datachannel: ['LocationBasedAssignment', 'LocationBasedBandwidth', 'LocationBasedSignalStrength', 'LocationBasedSignalQuality'],
  analyticschannel: ['LocationBasedQoS', 'LocationBasedCoverage', 'LocationBasedEnergy'],
  monitoringchannel: ['MonitorTraffic', 'MonitorInterference', 'LocationBasedStatus'],
  managementchannel: ['ManageAntenna', 'ManageUser', 'LocationBasedAntennaConfig', 'LocationBasedPowerManagement', 'LocationBasedChannelAllocation'],
  optimizationchannel: ['OptimizeNetwork', 'BalanceLoad', 'LocationBasedDynamicRouting'],
  faultchannel: ['LocationBasedFault', 'LocationBasedIoTFault', 'LogFault'],
  trafficchannel: ['LocationBasedTraffic', 'LogTraffic', 'LocationBasedCongestion'],
  accesschannel: ['RegisterUser', 'RegisterIoT', 'RevokeUser', 'RevokeIoT', 'AssignRole', 'LocationBasedIoTRegistration', 'LocationBasedIoTRevocation', 'LogAccessControl'],
  compliancechannel: ['LogComplianceAudit', 'LocationBasedPriority'],
  integrationchannel: ['LocationBasedInterference', 'LocationBasedSignalStrength', 'LocationBasedUserActivity', 'LogUserActivity', 'LogInterference'],
};

/**
 * Compare this map against the one in fabric.js and return a list of
 * differences. Returns [] when they agree or when fabric.js cannot be
 * loaded (no SDK installed — the generator case).
 */
function assertCatalogInSync() {
  let other;
  try {
    ({ CHANNEL_CHAINCODE_MAP: other } = require('./fabric'));
  } catch (_) {
    return [];
  }
  const diffs = [];
  const keys = new Set([...Object.keys(CHANNEL_CHAINCODE_MAP), ...Object.keys(other)]);
  for (const k of keys) {
    const a = (CHANNEL_CHAINCODE_MAP[k] || []).slice().sort().join(',');
    const b = (other[k] || []).slice().sort().join(',');
    if (a !== b) diffs.push(k);
  }
  return diffs;
}

// Contracts with no write function at all. They expose only reads, so a
// write benchmark against them can never commit anything.
//
// VerifyIdentity is NOT one of them, despite having been treated as such:
// it writes with a blind PutState. The auto-mapper skipped it because its
// second parameter is a bool — the only non-string writer on the network —
// and contractapi parses "true" itself.
const READ_ONLY_CONTRACTS = new Set(['GetPolicy']);

// Every generated contract exposes these two read functions.
const READ_FN = 'QueryAsset';
const READ_ALL_FN = 'QueryAllAssets';

/* ── Argument synthesis ────────────────────────────────────────────────
   Parameter names in contract-fn-map.js are consistent across all 86
   contracts (entityID, antennaID, x, y, signal, status, …), so a value
   can be derived from the name. `i` makes each transaction write a
   distinct key, which is what keeps a benchmark from measuring MVCC
   conflicts instead of throughput.                                      */

// Parameters that can serve as the ledger key.
const ID_PARAMS = new Set([
  'entityID', 'deviceID', 'userID', 'networkID', 'antennaID',
  'policyID', 'sessionID', 'channelID', 'resourceID',
]);

// antennaID in second position points at an antenna record that must
// already exist, so it stays fixed instead of varying per transaction.
const SHARED_REF_PARAMS = new Set(['antennaID']);

// Coordinates are metres on the scenario grid. The spatial contracts now
// place antennas across a 10 km square and pick a serving cell, so x and y
// have to span that square — the old 1..100 range put every entity in one
// corner and every transaction on the same cell.
const GRID_SIZE_M = 10000;
const BENCH_SEED = '42';
const ANTENNA_COUNT = 8;   // one macrocell per organization

function paramValue(name, i, keyPrefix) {
  // The first ID parameter is the ledger key — it must be unique per tx.
  switch (name) {
    case 'seed':              return BENCH_SEED;
    case 'verified':          return i % 5 === 0 ? 'false' : 'true';
    case 'x':                 return String((i * 2654435761) % GRID_SIZE_M);
    case 'y':                 return String((i * 1597334677) % GRID_SIZE_M);
    case 'signal':            return String(-60 - (i % 40));
    case 'signalQuality':     return String(50 + (i % 50));
    case 'load':              return String(10 + (i % 90));
    case 'coverage':          return String(50 + (i % 50));
    case 'congestion':        return String(i % 100);
    case 'energy':            return String(100 + (i % 900));
    case 'latency':           return String(1 + (i % 50));
    case 'traffic':           return String(100 + (i % 2000));
    case 'interferenceLevel': return String(i % 30);
    case 'bandwidth':         return String(10 + (i % 90));
    case 'amount':            return String(1 + (i % 500));
    case 'value':             return String(1 + (i % 100));
    case 'powerLevel':        return String(1 + (i % 40));
    case 'priority':          return ['low', 'normal', 'high'][i % 3];
    case 'qosLevel':          return ['bronze', 'silver', 'gold'][i % 3];
    case 'status':            return 'Active';
    case 'healthStatus':      return 'Healthy';
    case 'complianceStatus':  return 'Compliant';
    case 'token':             return `token-${i}`;
    case 'role':              return ['reader', 'writer', 'admin'][i % 3];
    case 'policy':            return 'allow-all';
    case 'change':            return 'threshold-raised';
    case 'action':            return 'config-change';
    case 'activity':          return 'handover';
    case 'event':             return 'login-ok';
    case 'metric':            return 'latency';
    case 'resource':          return 'spectrum';
    case 'strategy':          return 'load-balance';
    case 'route':             return 'path-a';
    case 'config':            return 'band-n78';
    case 'faultType':         return 'link-down';
    case 'data':              return `payload-${i}`;
    case 'maxDistance':       return '5000';
    default:                  return `v-${i}`;
  }
}

/**
 * Build the full argument list for one write transaction.
 * The first parameter is treated as the ledger key.
 */
function buildArgs(contract, i, keyPrefix = 'bench') {
  const def = CONTRACT_FN[contract];
  if (!def) return null;
  let keyTaken = false;
  return def.params.map((p) => {
    // antennaID always names a cell in the registry, never a fresh key —
    // even when it is the first parameter, as it is for the contract that
    // reconfigures a cell rather than being served by one. Cycling across
    // the eight keeps every cell exercised.
    if (SHARED_REF_PARAMS.has(p)) {
      keyTaken = true;
      return `antenna-${1 + (i % ANTENNA_COUNT)}`;
    }
    if (!keyTaken && ID_PARAMS.has(p)) {
      keyTaken = true;
      return `${keyPrefix}-${i}`;
    }
    if (ID_PARAMS.has(p)) return `${p}-${keyPrefix}-${i}`;
    return paramValue(p, i, keyPrefix);
  });
}

/** The ledger key a given iteration wrote — used by read benchmarks. */
function buildKey(i, keyPrefix = 'bench') {
  return `${keyPrefix}-${i}`;
}

/* ── Target catalog ────────────────────────────────────────────────── */

/**
 * Describe one (channel, contract) pair.
 * `writable` is false when the contract has no write function.
 * `antennaDep` marks contracts that read an antenna record before
 * writing — they fail unless that record was seeded first, so they are
 * excluded from sweeps by default.
 */
/**
 * Caliper indexes contracts by a globally unique contractID, not per
 * channel. Four contracts here sit on two channels each
 * (LocationBasedIoTSession, LocationBasedIoTFault, LocationBasedSignalStrength,
 * LogComplianceAudit), so declaring them under their plain name makes
 * Caliper reject the whole configuration as a duplicate definition.
 * Channel-qualifying every id keeps each (channel, contract) pair
 * separately addressable, which is what per-target benchmarking needs.
 */
function caliperId(channel, contract) {
  return `${channel}_${contract}`;
}

function describeTarget(channel, contract) {
  const def = CONTRACT_FN[contract];
  const readOnly = READ_ONLY_CONTRACTS.has(contract) || !def;
  return {
    channel,
    contract,
    id: `${channel}/${contract}`,
    caliperId: caliperId(channel, contract),
    fn: def ? def.fn : null,
    params: def ? def.params : [],
    readFn: READ_FN,
    readAllFn: READ_ALL_FN,
    writable: !readOnly,
    antennaDep: def ? !!def.antennaDep : false,
    // Spatial contracts pick their own serving cell, so the antenna layout
    // has to exist before they will accept a write.
    needsSeed: def ? !!def.needsSeed : false,
    sampleArgs: def ? buildArgs(contract, 1) : [],
  };
}

/** Every (channel, contract) pair in the network — 86 contracts, 20 channels. */
function allTargets() {
  const out = [];
  for (const [channel, contracts] of Object.entries(CHANNEL_CHAINCODE_MAP)) {
    for (const contract of contracts) out.push(describeTarget(channel, contract));
  }
  return out;
}

/** Targets grouped by channel, for the UI's channel picker. */
function catalog() {
  const channels = Object.entries(CHANNEL_CHAINCODE_MAP).map(([channel, contracts]) => ({
    channel,
    contracts: contracts.map((c) => describeTarget(channel, c)),
  }));
  return {
    channels,
    counts: {
      channels: channels.length,
      targets: channels.reduce((n, c) => n + c.contracts.length, 0),
      writable: channels.reduce(
        (n, c) => n + c.contracts.filter((t) => t.writable).length, 0),
      antennaDep: channels.reduce(
        (n, c) => n + c.contracts.filter((t) => t.antennaDep).length, 0),
    },
  };
}

/**
 * Turn a UI selection into a concrete, ordered target list.
 *
 *   mode 'contract' → one pair, needs { channel, contract }
 *   mode 'channel'  → every contract on { channel }
 *   mode 'channels' → every contract on each of { channels: [] }
 *   mode 'targets'  → exactly the pairs in { targets: [{channel,contract}] }
 *   mode 'all'      → the whole network
 *
 * `includeAntennaDep` and `includeReadOnly` default to false because
 * those targets cannot commit a blind write.
 */
function resolveTargets(sel = {}) {
  const {
    mode = 'contract',
    channel,
    contract,
    channels = [],
    targets = [],
    includeAntennaDep = false,
    includeReadOnly = false,
  } = sel;

  let list = [];
  switch (mode) {
    case 'contract':
      if (!channel || !contract) throw new Error('mode "contract" needs a channel and a contract');
      list = [describeTarget(channel, contract)];
      break;
    case 'channel': {
      if (!channel) throw new Error('mode "channel" needs a channel');
      const ccs = CHANNEL_CHAINCODE_MAP[channel];
      if (!ccs) throw new Error(`Unknown channel: ${channel}`);
      list = ccs.map((c) => describeTarget(channel, c));
      break;
    }
    case 'channels': {
      if (!channels.length) throw new Error('mode "channels" needs at least one channel');
      for (const ch of channels) {
        const ccs = CHANNEL_CHAINCODE_MAP[ch];
        if (!ccs) throw new Error(`Unknown channel: ${ch}`);
        list.push(...ccs.map((c) => describeTarget(ch, c)));
      }
      break;
    }
    case 'targets':
      if (!targets.length) throw new Error('mode "targets" needs at least one target');
      list = targets.map((t) => describeTarget(t.channel, t.contract));
      break;
    case 'all':
      list = allTargets();
      break;
    default:
      throw new Error(`Unknown selection mode: ${mode}`);
  }

  // Deduplicate — a contract can sit on more than one channel, and the
  // same pair can arrive twice from overlapping selections.
  const seen = new Set();
  list = list.filter((t) => {
    if (seen.has(t.id)) return false;
    seen.add(t.id);
    return true;
  });

  if (!includeReadOnly) list = list.filter((t) => t.writable);
  if (!includeAntennaDep) list = list.filter((t) => !t.antennaDep);
  return list;
}

/** Distinct write function names across the network — one Caliper asset each. */
function writeFunctions() {
  const fns = new Set();
  for (const t of allTargets()) if (t.writable && t.fn) fns.add(t.fn);
  return [...fns].sort();
}

module.exports = {
  CONTRACT_FN,
  CHANNEL_CHAINCODE_MAP,
  READ_ONLY_CONTRACTS,
  GRID_SIZE_M,
  BENCH_SEED,
  ANTENNA_COUNT,
  READ_FN,
  READ_ALL_FN,
  buildArgs,
  buildKey,
  describeTarget,
  allTargets,
  catalog,
  caliperId,
  resolveTargets,
  writeFunctions,
  assertCatalogInSync,
};
