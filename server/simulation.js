'use strict';

// simulation.js — شبیه‌سازی توپولوژی 6G روی بلاک‌چین
// ۸ سازمان = آنتن ماکروسل با موقعیت تصادفی در مربع ۱۰×۱۰ کیلومتر (متر: 0..10000)
// IoT و کاربران: تعداد دلخواه، موقعیت تصادفی، اتصال به نزدیک‌ترین آنتن (زیرمجموعه همان سازمان)
// تراکنش هر موجودیت از طریق gateway سازمانِ آنتنِ میزبانش ارسال می‌شود.

const { invokeChaincode, CHANNEL_CHAINCODE_MAP } = require('./fabric');

const AREA = 10000; // متر

const CONTRACT_SIM = {
  AllocateResource: { fn: 'Allocate', entity: 'iot', args: (ent) => [ent.id, 'spectrum', '100'] },
  AssignRole: { fn: 'Assign', entity: 'iot', args: (ent) => [ent.id, 'member'] },
  AuthenticateIoT: { fn: 'Authenticate', entity: 'iot', args: (ent) => [ent.id, 'tok-'+ent.id] },
  AuthenticateUser: { fn: 'Authenticate', entity: 'user', args: (ent) => [ent.id, 'tok-'+ent.id] },
  BalanceLoad: { fn: 'Balance', entity: 'iot', args: (ent) => [ent.id, '55'] },
  ConnectIoT: { fn: 'Connect', entity: 'iot', args: (ent) => [ent.id, ent.antennaID] },
  ConnectUser: { fn: 'Connect', entity: 'user', args: (ent) => [ent.id, ent.antennaID] },
  DecryptData: { fn: 'Decrypt', entity: 'iot', args: (ent) => [ent.id, 'sim-data'] },
  EncryptData: { fn: 'Encrypt', entity: 'iot', args: (ent) => [ent.id, 'sim-data'] },
  LocationBasedAntennaConfig: { fn: 'SetAntennaConfig', entity: 'antenna', args: (ent) => [ent.antennaID, 'default', String(ent.x), String(ent.y)] },
  LocationBasedAssignment: { skip: 'antenna-dependent (no antenna record in namespace)' },
  LocationBasedBandwidth: { skip: 'antenna-dependent (no antenna record in namespace)' },
  LocationBasedChannelAllocation: { fn: 'AllocateChannel', entity: 'iot', args: (ent) => [ent.id, 'ch-1', String(ent.x), String(ent.y)] },
  LocationBasedCongestion: { fn: 'RecordCongestion', entity: 'iot', args: (ent) => [ent.id, 'low', String(ent.x), String(ent.y)] },
  LocationBasedConnection: { skip: 'antenna-dependent (no antenna record in namespace)' },
  LocationBasedCoverage: { fn: 'RecordCoverage', entity: 'iot', args: (ent) => [ent.id, '85', String(ent.x), String(ent.y)] },
  LocationBasedDynamicRouting: { fn: 'SetDynamicRoute', entity: 'iot', args: (ent) => [ent.id, 'direct', String(ent.x), String(ent.y)] },
  LocationBasedEnergy: { fn: 'RecordEnergy', entity: 'iot', args: (ent) => [ent.id, '40', String(ent.x), String(ent.y)] },
  LocationBasedFault: { fn: 'ReportFault', entity: 'iot', args: (ent) => [ent.id, 'none', String(ent.x), String(ent.y)] },
  LocationBasedInterference: { fn: 'RecordInterference', entity: 'iot', args: (ent) => [ent.id, 'low', String(ent.x), String(ent.y)] },
  LocationBasedIoTAuthentication: { fn: 'AuthenticateIoT', entity: 'iot', args: (ent) => [ent.id, 'tok-'+ent.id, String(ent.x), String(ent.y)] },
  LocationBasedIoTBandwidth: { skip: 'antenna-dependent (no antenna record in namespace)' },
  LocationBasedIoTConnection: { skip: 'antenna-dependent (no antenna record in namespace)' },
  LocationBasedIoTFault: { fn: 'ReportIoTFault', entity: 'iot', args: (ent) => [ent.id, 'none', String(ent.x), String(ent.y)] },
  LocationBasedIoTRegistration: { fn: 'RegisterIoT', entity: 'iot', args: (ent) => [ent.id, 'Active', String(ent.x), String(ent.y)] },
  LocationBasedIoTResource: { fn: 'AllocateIoTResource', entity: 'iot', args: (ent) => [ent.id, ent.id, '100', String(ent.x), String(ent.y)] },
  LocationBasedIoTRevocation: { fn: 'RevokeIoT', entity: 'iot', args: (ent) => [ent.id, 'Active', String(ent.x), String(ent.y)] },
  LocationBasedIoTSession: { fn: 'StartIoTSession', entity: 'iot', args: (ent) => [ent.id, String(Date.now()), String(ent.x), String(ent.y), 'Active'] },
  LocationBasedIoTStatus: { fn: 'UpdateIoTStatus', entity: 'iot', args: (ent) => [ent.id, 'Active', String(ent.x), String(ent.y)] },
  LocationBasedLatency: { fn: 'RecordLatency', entity: 'iot', args: (ent) => [ent.id, '12', String(ent.x), String(ent.y)] },
  LocationBasedNetworkHealth: { fn: 'RecordNetworkHealth', entity: 'iot', args: (ent) => [ent.id, 'healthy', String(ent.x), String(ent.y)] },
  LocationBasedNetworkLoad: { fn: 'RecordNetworkLoad', entity: 'iot', args: (ent) => [ent.id, '55', String(ent.x), String(ent.y)] },
  LocationBasedPowerManagement: { fn: 'SetPowerLevel', entity: 'iot', args: (ent) => [ent.id, '20', String(ent.x), String(ent.y)] },
  LocationBasedPriority: { fn: 'AssignPriority', entity: 'iot', args: (ent) => [ent.id, 'high', String(ent.x), String(ent.y)] },
  LocationBasedQoS: { skip: 'antenna-dependent (no antenna record in namespace)' },
  LocationBasedResourceAllocation: { fn: 'AllocateResource', entity: 'iot', args: (ent) => [ent.id, ent.id, '100', String(ent.x), String(ent.y)] },
  LocationBasedRoaming: { skip: 'antenna-dependent (no antenna record in namespace)' },
  LocationBasedSessionManagement: { fn: 'ManageSession', entity: 'iot', args: (ent) => [ent.id, String(Date.now()), String(ent.x), String(ent.y), 'Active'] },
  LocationBasedSignalQuality: { fn: 'RecordSignalQuality', entity: 'iot', args: (ent) => [ent.id, 'good', String(ent.x), String(ent.y)] },
  LocationBasedSignalStrength: { fn: 'RecordSignalStrength', entity: 'iot', args: (ent) => [ent.id, '-70', String(ent.x), String(ent.y)] },
  LocationBasedStatus: { fn: 'UpdateStatus', entity: 'iot', args: (ent) => [ent.id, 'Active', String(ent.x), String(ent.y)] },
  LocationBasedTraffic: { fn: 'RecordTraffic', entity: 'iot', args: (ent) => [ent.id, '800', String(ent.x), String(ent.y)] },
  LocationBasedUserActivity: { fn: 'RecordUserActivity', entity: 'user', args: (ent) => [ent.id, 'connected', String(ent.x), String(ent.y)] },
  LogAccessAudit: { fn: 'Log', entity: 'iot', args: (ent) => [ent.id, 'sim-event'] },
  LogAccessControl: { fn: 'Log', entity: 'iot', args: (ent) => [ent.id, 'sim-event'] },
  LogAntennaAudit: { fn: 'Log', entity: 'antenna', args: (ent) => [ent.antennaID, 'sim-event'] },
  LogComplianceAudit: { fn: 'Log', entity: 'iot', args: (ent) => [ent.id, 'compliant'] },
  LogConnectionAudit: { fn: 'Log', entity: 'iot', args: (ent) => [ent.id, ent.antennaID, 'sim-event'] },
  LogFault: { fn: 'LogFault', entity: 'iot', args: (ent) => [ent.id, 'none'] },
  LogInterference: { fn: 'LogInterference', entity: 'iot', args: (ent) => [ent.id, 'low'] },
  LogIoTActivity: { fn: 'Log', entity: 'iot', args: (ent) => [ent.id, 'connected'] },
  LogIoTAudit: { fn: 'Log', entity: 'iot', args: (ent) => [ent.id, 'sim-event'] },
  LogNetworkAudit: { fn: 'Log', entity: 'iot', args: (ent) => [ent.id, 'sim-event'] },
  LogNetworkPerformance: { fn: 'Log', entity: 'iot', args: (ent) => [ent.id, 'latency', '1'] },
  LogPerformance: { fn: 'LogPerformance', entity: 'iot', args: (ent) => [ent.id, 'latency', '1'] },
  LogPerformanceAudit: { fn: 'Log', entity: 'iot', args: (ent) => [ent.id, 'latency', '1'] },
  LogPolicyAudit: { fn: 'Log', entity: 'iot', args: (ent) => [ent.id, 'sim-event'] },
  LogPolicyChange: { fn: 'Log', entity: 'iot', args: (ent) => [ent.id, 'sim-update'] },
  LogResourceAudit: { fn: 'LogResourceAudit', entity: 'iot', args: (ent) => [ent.id, 'spectrum', '100'] },
  LogSecurityAudit: { fn: 'Log', entity: 'iot', args: (ent) => [ent.id, 'sim-event'] },
  LogSecurityEvent: { fn: 'Log', entity: 'iot', args: (ent) => [ent.id, 'sim-event'] },
  LogSession: { fn: 'LogSession', entity: 'iot', args: (ent) => [ent.id, String(Date.now()), 'Active'] },
  LogSessionAudit: { fn: 'Log', entity: 'iot', args: (ent) => [ent.id, String(Date.now()), 'sim-event'] },
  LogTraffic: { fn: 'LogTraffic', entity: 'iot', args: (ent) => [ent.id, '800'] },
  LogUserActivity: { fn: 'Log', entity: 'user', args: (ent) => [ent.id, 'connected'] },
  LogUserAudit: { fn: 'Log', entity: 'user', args: (ent) => [ent.id, 'sim-event'] },
  ManageAntenna: { fn: 'UpdateAntennaStatus', entity: 'antenna', args: (ent) => [ent.antennaID, 'Active'] },
  ManageIoTDevice: { fn: 'UpdateDeviceStatus', entity: 'iot', args: (ent) => [ent.id, 'Active'] },
  ManageNetwork: { fn: 'UpdateNetworkStatus', entity: 'iot', args: (ent) => [ent.id, 'Active'] },
  ManageSession: { fn: 'StartSession', entity: 'iot', args: (ent) => [ent.id, String(Date.now())] },
  ManageUser: { fn: 'UpdateUserStatus', entity: 'user', args: (ent) => [ent.id, 'Active'] },
  MonitorInterference: { fn: 'RecordInterference', entity: 'iot', args: (ent) => [ent.id, 'low'] },
  MonitorIoT: { fn: 'RecordStatus', entity: 'iot', args: (ent) => [ent.id, 'Active'] },
  MonitorNetwork: { fn: 'RecordStatus', entity: 'iot', args: (ent) => [ent.id, 'Active'] },
  MonitorResourceUsage: { fn: 'RecordUsage', entity: 'iot', args: (ent) => [ent.id, 'spectrum', '100'] },
  MonitorTraffic: { fn: 'RecordTraffic', entity: 'iot', args: (ent) => [ent.id, '800'] },
  OptimizeNetwork: { fn: 'Optimize', entity: 'iot', args: (ent) => [ent.id, 'balance'] },
  RegisterIoT: { fn: 'Register', entity: 'iot', args: (ent) => [ent.id, 'Active'] },
  RegisterUser: { fn: 'Register', entity: 'user', args: (ent) => [ent.id, 'Active'] },
  RevokeIoT: { fn: 'Revoke', entity: 'iot', args: (ent) => [ent.id, 'Active'] },
  RevokeUser: { fn: 'Revoke', entity: 'user', args: (ent) => [ent.id, 'Active'] },
  SecureCommunication: { fn: 'Establish', entity: 'iot', args: (ent) => [ent.id, 'ch-1'] },
  SetPolicy: { fn: 'Set', entity: 'iot', args: (ent) => [ent.id, 'allow'] },
  UpdatePolicy: { fn: 'Update', entity: 'iot', args: (ent) => [ent.id, 'allow'] },
};

function rnd(max) { return Math.round(Math.random() * max); }

function generateTopology(iotCount, userCount) {
  const antennas = [];
  for (let i = 1; i <= 8; i++) {
    antennas.push({ id: 'antenna-org' + i, orgNum: i, x: rnd(AREA), y: rnd(AREA) });
  }
  const nearest = (x, y) => {
    let best = antennas[0], bd = Infinity;
    for (const a of antennas) {
      const d = (a.x - x) ** 2 + (a.y - y) ** 2;
      if (d < bd) { bd = d; best = a; }
    }
    return { antenna: best, distance: Math.sqrt(bd) };
  };
  const mk = (prefix, n) => {
    const out = [];
    for (let i = 1; i <= n; i++) {
      const x = rnd(AREA), y = rnd(AREA);
      const { antenna, distance } = nearest(x, y);
      out.push({ id: `${prefix}-${i}`, x, y, antennaID: antenna.id,
                 orgNum: antenna.orgNum, distance: Math.round(distance) });
    }
    return out;
  };
  const iots = mk('iot', iotCount);
  const users = mk('user', userCount);
  // آنتن‌ها هم موجودیت‌اند (برای قراردادهای antenna): میزبان خودشان
  const antennaEnts = antennas.map(a => ({ id: a.id, x: a.x, y: a.y,
                                           antennaID: a.id, orgNum: a.orgNum }));
  return { antennas, iots, users, antennaEnts };
}

// اجرای موازی با سقف همزمانی
async function runPool(tasks, limit) {
  const results = [];
  let idx = 0;
  async function worker() {
    while (idx < tasks.length) {
      const i = idx++;
      results[i] = await tasks[i]().catch(e => ({ error: e.message || String(e) }));
    }
  }
  await Promise.all(Array.from({ length: Math.min(limit, tasks.length) }, worker));
  return results;
}

async function runSimulation({ iotCount = 20, userCount = 10, channels = [], chaincodes = null, concurrency = 10 }) {
  const topo = generateTopology(iotCount, userCount);
  const selChannels = channels.length ? channels : Object.keys(CHANNEL_CHAINCODE_MAP);
  const perChannel = [];
  const t0 = Date.now();

  for (const channel of selChannels) {
    const all = CHANNEL_CHAINCODE_MAP[channel] || [];
    const sel = chaincodes && chaincodes.length ? all.filter(c => chaincodes.includes(c)) : all;
    const chStats = { channel, contracts: [] };

    for (const cc of sel) {
      const spec = CONTRACT_SIM[cc];
      if (!spec || spec.skip) {
        chStats.contracts.push({ chaincode: cc, skipped: spec ? spec.skip : 'read-only (no write fn)' });
        continue;
      }
      const ents = spec.entity === 'antenna' ? topo.antennaEnts
                 : spec.entity === 'user'    ? topo.users
                 : topo.iots;
      const started = Date.now();
      const tasks = ents.map(ent => () =>
        invokeChaincode(ent.orgNum, channel, cc, spec.fn, spec.args(ent)));
      const res = await runPool(tasks, concurrency);
      const failed = res.filter(r => r && r.error);
      const dur = (Date.now() - started) / 1000;
      chStats.contracts.push({
        chaincode: cc, fn: spec.fn, entity: spec.entity,
        total: ents.length, success: ents.length - failed.length,
        failed: failed.length, durationSec: +dur.toFixed(2),
        tps: dur > 0 ? +((ents.length - failed.length) / dur).toFixed(2) : null,
        sampleError: failed.length ? failed[0].error.slice(0, 200) : undefined,
      });
    }
    perChannel.push(chStats);
  }

  const totals = perChannel.flatMap(c => c.contracts).filter(c => !c.skipped);
  return {
    topology: { area: AREA, antennas: topo.antennas, iots: topo.iots, users: topo.users },
    results: perChannel,
    summary: {
      channels: selChannels.length,
      contractsRun: totals.length,
      txTotal: totals.reduce((s, c) => s + c.total, 0),
      txSuccess: totals.reduce((s, c) => s + c.success, 0),
      txFailed: totals.reduce((s, c) => s + c.failed, 0),
      durationSec: +((Date.now() - t0) / 1000).toFixed(2),
    },
  };
}

function registerSimulationRoutes(app) {
  // متادیتا برای UI: قراردادهای قابل اجرا و نوع موجودیت هر یک
  app.get('/api/simulation/meta', (req, res) => {
    const contracts = {};
    for (const [name, spec] of Object.entries(CONTRACT_SIM)) {
      contracts[name] = spec.skip ? { skip: spec.skip } : { fn: spec.fn, entity: spec.entity };
    }
    res.json({ area: AREA, channels: CHANNEL_CHAINCODE_MAP, contracts });
  });

  app.post('/api/simulation/execute', async (req, res) => {
    try {
      const { iotCount, userCount, channels, chaincodes, concurrency } = req.body || {};
      const ic = Math.min(Math.max(parseInt(iotCount) || 20, 1), 500);
      const uc = Math.min(Math.max(parseInt(userCount) || 10, 0), 500);
      const out = await runSimulation({
        iotCount: ic, userCount: uc,
        channels: Array.isArray(channels) ? channels : [],
        chaincodes: Array.isArray(chaincodes) && chaincodes.length ? chaincodes : null,
        concurrency: Math.min(Math.max(parseInt(concurrency) || 10, 1), 30),
      });
      res.json(out);
    } catch (e) {
      res.status(500).json({ error: e.message || String(e) });
    }
  });
}

module.exports = { registerSimulationRoutes, runSimulation, generateTopology, CONTRACT_SIM };
