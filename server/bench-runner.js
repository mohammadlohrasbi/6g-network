'use strict';

/* ═══════════════════════════════════════════════════════════════════════
   bench-runner.js — runs a benchmark across one or many targets.

   A full 20-channel sweep takes many minutes, so a run is a background
   job: the route returns a job id immediately and the UI polls for
   progress. Targets are executed one at a time — running them
   concurrently would have them compete for the same peers and make every
   number meaningless.
   ═══════════════════════════════════════════════════════════════════════ */

const fs = require('fs');
const os = require('os');
const path = require('path');
const { spawn, execFileSync } = require('child_process');
const yaml = require('js-yaml');

const config = require('./config');
const {
  buildArgs,
  buildKey,
  resolveTargets,
  READ_FN,
} = require('./bench-catalog');

const TEST_TOOLS_DIR =
  process.env.TEST_TOOLS_DIR || path.resolve(__dirname, '..', 'test-tools');
const CALIPER_WORKSPACE =
  process.env.CALIPER_WORKSPACE || path.join(TEST_TOOLS_DIR, 'caliper-workspace');
const TAPE_CONFIG_DIR =
  process.env.TAPE_CONFIG_DIR || path.join(TEST_TOOLS_DIR, 'tape-configs');
// Read at spawn time, not at load time, so the binary path can be changed
// without restarting the server.
const tapeBin = () => process.env.TAPE_BIN || path.join(os.homedir(), 'go', 'bin', 'tape');
const caliperBin = () => process.env.CALIPER_BIN || 'npx';
const RUN_DIR = process.env.BENCH_RUN_DIR || path.join(TEST_TOOLS_DIR, 'bench-runs');

/* ── Endorsement policy ───────────────────────────────────────────────
   The deployed chaincode policy is OR(org1..org8) — a single signature
   commits. Tape needs a matching rego file or it will keep collecting
   endorsements the network never asked for, which inflates its latency
   and makes Tape/Caliper results incomparable.

   'any'      — count(input) >= 1, mirrors the deployed policy (default)
   'majority' — count(input) >= 5, the stricter hypothetical
                configuration, kept so both can be measured.            */
const POLICY_FILES = {
  any: 'endorsement-any.rego',
  majority: 'endorsement-majority.rego',
};

const POLICY_SOURCE = {
  any: `package tape

default allow = false

# Mirrors the deployed chaincode policy:
#   OR('org1MSP.member', ... ,'org8MSP.member')
# A single endorsement satisfies it.
allow {
    count(input) >= 1
}
`,
  majority: `package tape

default allow = false

# Hypothetical stricter policy: MAJORITY of 8 organizations.
# This is NOT what is deployed on the network — use it only for the
# deliberate policy-cost comparison, and say so when reporting results.
allow {
    count(input) >= 5
}
`,
};

/** Write both rego files if absent, return the path of the selected one. */
function ensurePolicyFile(policy = 'any') {
  const key = POLICY_FILES[policy] ? policy : 'any';
  fs.mkdirSync(TAPE_CONFIG_DIR, { recursive: true });
  for (const [name, file] of Object.entries(POLICY_FILES)) {
    const p = path.join(TAPE_CONFIG_DIR, file);
    if (!fs.existsSync(p)) fs.writeFileSync(p, POLICY_SOURCE[name], 'utf8');
  }
  return path.join(TAPE_CONFIG_DIR, POLICY_FILES[key]);
}

/* ── Crypto material ─────────────────────────────────────────────────── */

function firstFileIn(dir) {
  const files = fs.readdirSync(dir).filter((f) => !f.startsWith('.')).sort();
  if (!files.length) throw new Error(`No files in ${dir}`);
  return path.join(dir, files[0]);
}

/* ── Tape ────────────────────────────────────────────────────────────── */

/**
 * Build a tape config for one target.
 * `endorsers` decides how many organizations are asked to endorse — with
 * the 'any' policy one is enough, which is what the network actually
 * requires; more endorsers measures the cost of a stricter policy.
 */
function buildTapeConfig({ target, orgNums, policyPath, connections, clientsPerConn, keyPrefix }) {
  const endorsers = orgNums.map((n) => {
    const o = config.getOrg(n);
    if (!o) throw new Error(`Org ${n} is not in the server config`);
    return {
      addr: o.peerEndpoint,
      tls_ca_cert: config.tlsEnabled ? o.tlsRootCert : '',
      org: `org${n}`,
    };
  });

  const signer = config.getOrg(orgNums[0]);

  return {
    endorsers,
    committers: [
      {
        addr: signer.peerEndpoint,
        tls_ca_cert: config.tlsEnabled ? signer.tlsRootCert : '',
        org: `org${orgNums[0]}`,
      },
    ],
    commitThreshold: 1,
    orderer: {
      addr: config.orderer.endpoint,
      tls_ca_cert: config.tlsEnabled ? config.orderer.tlsCaCert : '',
      org: `org${orgNums[0]}`,
    },
    policyFile: policyPath,
    channel: target.channel,
    chaincode: target.contract,
    args: [target.fn, ...buildArgs(target.contract, 1, keyPrefix)],
    mspid: signer.mspId,
    private_key: firstFileIn(signer.adminKeyDir),
    sign_cert: firstFileIn(signer.adminCertDir),
    num_of_conn: connections,
    client_per_conn: clientsPerConn,
  };
}

// Tape's real output, confirmed against a live run:
//
//   Time     7.03s\tBlock     56\tTx    500
//   From Orderer Time     8.12s\tBlock     59\t Tx     75
//   tx: 1000, duration: 8.464269379s, tps: 118.143688
//
// The last line is the summary. Note what is NOT there: tape reports no
// per-transaction latency in this format, so latency is left unset rather
// than filled with a zero that would read as "instant". Use Caliper when
// latency is the question — that division is why both tools are here.
function parseTape(text) {
  const m = {
    tps: NaN,
    latencyAvg: NaN,
    latencyMin: NaN,
    latencyMax: NaN,
    successCount: NaN,
    failedCount: NaN,
    durationSec: NaN,
    blockCount: NaN,
    avgBlockSize: NaN,
  };

  const summary = text.match(/tx:\s*(\d+),\s*duration:\s*([\d.]+)s,\s*tps:\s*([\d.]+)/i);
  if (summary) {
    m.successCount = parseInt(summary[1], 10);
    m.durationSec = parseFloat(summary[2]);
    m.tps = parseFloat(summary[3]);
    // Tape sends a fixed number and reports how many landed in blocks.
    m.failedCount = 0;
  }

  // Block lines, deduplicated — each block is announced twice, once by the
  // orderer and once on commit. Block size distribution is worth keeping:
  // it shows whether the orderer is batching or starving.
  const blocks = new Map();
  for (const b of text.matchAll(/Block\s+(\d+)\s*\t?\s*Tx\s+(\d+)/gi)) {
    blocks.set(parseInt(b[1], 10), parseInt(b[2], 10));
  }
  if (blocks.size) {
    m.blockCount = blocks.size;
    const sizes = [...blocks.values()];
    m.avgBlockSize = sizes.reduce((a, c) => a + c, 0) / sizes.length;
    if (!Number.isFinite(m.successCount)) {
      m.successCount = sizes.reduce((a, c) => a + c, 0);
    }
  }

  // Older tape builds do print latency; keep reading it when present.
  const last = (re) => {
    const all = [...text.matchAll(re)];
    return all.length ? parseFloat(all[all.length - 1][1]) : NaN;
  };
  const avg = last(/(?:avg|average)\s*latency[:\s]+([\d.]+)/gi);
  if (Number.isFinite(avg)) {
    m.latencyAvg = avg;
    m.latencyMin = last(/min\s*latency[:\s]+([\d.]+)/gi);
    m.latencyMax = last(/max\s*latency[:\s]+([\d.]+)/gi);
  }
  if (!Number.isFinite(m.tps)) m.tps = last(/tps[:\s]+([\d.]+)/gi);

  return m;
}

function runTapeTarget(target, opts, job) {
  return new Promise((resolve) => {
    const cfgPath = path.join(
      RUN_DIR, job.id, `tape-${target.channel}-${target.contract}.yaml`);
    let child;
    try {
      const cfg = buildTapeConfig({
        target,
        orgNums: opts.orgNums,
        policyPath: opts.policyPath,
        connections: opts.connections,
        clientsPerConn: opts.clientsPerConn,
        keyPrefix: opts.keyPrefix,
      });
      fs.mkdirSync(path.dirname(cfgPath), { recursive: true });
      fs.writeFileSync(cfgPath, yaml.dump(cfg), 'utf8');
    } catch (err) {
      return resolve({ ok: false, error: `Could not write the tape config: ${err.message}` });
    }

    const args = ['-c', cfgPath, '-n', String(opts.txNumber)];
    if (opts.rate) args.push('--rate', String(opts.rate));
    if (opts.burst) args.push('--burst', String(opts.burst));

    let out = '';
    try {
      child = spawn(tapeBin(), args, {
        env: { ...process.env, CORE_PEER_TLS_ENABLED: String(config.tlsEnabled) },
      });
    } catch (err) {
      return resolve({ ok: false, error: `Could not start tape: ${err.message}` });
    }

    job._child = child;
    const timer = setTimeout(() => {
      try { child.kill('SIGKILL'); } catch (_) { /* already gone */ }
    }, opts.timeoutMs);

    child.stdout.on('data', (d) => { out += d.toString(); });
    child.stderr.on('data', (d) => { out += d.toString(); });
    child.on('error', (err) => {
      clearTimeout(timer);
      job._child = null;
      resolve({ ok: false, error: `tape could not run: ${err.message}` });
    });
    child.on('close', (code) => {
      clearTimeout(timer);
      job._child = null;
      const m = parseTape(out);
      // A spatial contract refuses every write until its antenna layout
      // exists. That reads as a flat failure unless it is named.
      const unseeded = /SeedNetwork first|no antennas registered|no antenna layout/i.test(out);
      resolve({
        ok: code === 0,
        exitCode: code,
        metrics: m,
        output: out.split('\n').slice(-40).join('\n'),
        error: code === 0 ? null
          : unseeded
            ? `${target.contract} has no antenna layout — run scripts/seed-network.sh`
            : `tape exited with code ${code}`,
        configPath: cfgPath,
      });
    });
  });
}

/* ── Caliper ──────────────────────────────────────────────────────────
   Rather than relying on pre-generated per-function assets, the
   benchmark file is written per target at run time and points at one
   generic workload module. That way every one of the 90 targets is
   reachable without keeping 61 near-identical files in sync.          */

function buildCaliperBenchmark(target, opts) {
  const rounds = [{
    label: `write-${target.contract}`,
    txNumber: opts.txNumber,
    rateControl: { type: 'fixed-rate', opts: { tps: opts.rate } },
    workload: {
      module: 'workload/generic-write.js',
      arguments: {
        // Caliper addresses the contract by its unique alias; the plain
        // name goes along so the workload can look up the argument shape.
        contractId: target.caliperId,
        contractName: target.contract,
        contractFunction: target.fn,
        params: target.params,
        keyPrefix: opts.keyPrefix,
        mspId: config.getOrg(opts.orgNums[0]).mspId,
      },
    },
  }];

  if (opts.readPhase) {
    rounds.push({
      label: `read-${target.contract}`,
      txNumber: opts.txNumber,
      rateControl: { type: 'fixed-rate', opts: { tps: opts.readRate || opts.rate * 2 } },
      workload: {
        module: 'workload/generic-read.js',
        arguments: {
          contractId: target.caliperId,
          contractName: target.contract,
          contractFunction: READ_FN,
          keyPrefix: opts.keyPrefix,
          keySpace: opts.txNumber,
          mspId: config.getOrg(opts.orgNums[0]).mspId,
        },
      },
    });
  }

  return {
    test: {
      name: `${target.channel}-${target.contract}`,
      description: `Benchmark of ${target.fn} on ${target.channel}`,
      workers: { number: opts.workers },
      rounds,
    },
    monitors: {
      resource: [{
        module: 'docker',
        options: {
          interval: 5,
          containers: [
            `peer0.org${opts.orgNums[0]}.example.com`,
            'orderer.example.com',
          ],
        },
      }],
    },
  };
}

/* Caliper's result table, one row per round:

     | write-Contract | 486  | 14   | 20.1 | 1.94 | 0.09 | 0.41 | 19.8 |
       label            succ   fail   send   max    min    avg    tps

   Latency columns are seconds and are converted to milliseconds here.

   Parsing is deliberately strict — anchored on a full eight-cell row.
   A loose fallback previously matched "Benchmark successfully finished"
   and then swallowed the first digits of the NEXT log line, which is the
   year, so failed rounds were reported as 2026 committed transactions. A
   benchmark that invents numbers is worse than one that reports nothing,
   so when no table is present this returns no counts at all. */
function parseCaliper(text) {
  const m = {
    tps: NaN,
    latencyAvg: NaN,
    latencyMin: NaN,
    latencyMax: NaN,
    successCount: NaN,
    failedCount: NaN,
    roundError: null,
  };

  // Caliper says so explicitly when a round dies; keep the reason.
  const failed = text.match(/Failed round\s+\d+\s*\(([^)]*)\):\s*(.+)/);
  if (failed) {
    m.roundError = failed[2].split('\n')[0].replace(/^Error:\s*/, '').trim();
  }

  const rows = [...text.matchAll(
    /^\s*\|([^|\n]+)\|([^|\n]+)\|([^|\n]+)\|([^|\n]+)\|([^|\n]+)\|([^|\n]+)\|([^|\n]+)\|([^|\n]+)\|\s*$/gm)]
    .map((r) => r.slice(1).map((c) => c.trim()))
    // Drop the header and the +---+ separators: a data row has a numeric
    // value in all seven columns after the label.
    .filter((c) => c.slice(1).every((v) => v !== '' && Number.isFinite(Number(v))));

  if (!rows.length) {
    if (!m.roundError) {
      const generic = text.match(/error code:\s*(\d+)/i);
      m.roundError = generic
        ? `Caliper reported no results (error code ${generic[1]})`
        : 'Caliper produced no result table';
    }
    return m;
  }

  // With a read round configured there are two rows; the write round is
  // the one that describes commit throughput.
  const row = rows.find((c) => /^write-/.test(c[0])) || rows[0];
  m.successCount = Number(row[1]);
  m.failedCount = Number(row[2]);
  m.latencyMax = Number(row[4]) * 1000;
  m.latencyMin = Number(row[5]) * 1000;
  m.latencyAvg = Number(row[6]) * 1000;
  m.tps = Number(row[7]);

  const read = rows.find((c) => /^read-/.test(c[0]));
  if (read) {
    m.readTps = Number(read[7]);
    m.readLatencyAvg = Number(read[6]) * 1000;
    m.readSuccessCount = Number(read[1]);
  }

  return m;
}

function runCaliperTarget(target, opts, job) {
  return new Promise((resolve) => {
    const benchPath = path.join(
      RUN_DIR, job.id, `caliper-${target.channel}-${target.contract}.yaml`);
    const netPath = path.join(
      CALIPER_WORKSPACE, 'networks', `org${opts.orgNums[0]}.yaml`);

    const assetError = ensureCaliperAssets(opts.orgNums[0]);
    if (assetError) return resolve({ ok: false, error: assetError });

    try {
      fs.mkdirSync(path.dirname(benchPath), { recursive: true });
      fs.writeFileSync(benchPath, yaml.dump(buildCaliperBenchmark(target, opts)), 'utf8');
    } catch (err) {
      return resolve({ ok: false, error: `Could not write the benchmark file: ${err.message}` });
    }

    const args = [
      'caliper', 'launch', 'manager',
      '--caliper-workspace', CALIPER_WORKSPACE,
      '--caliper-networkconfig', netPath,
      '--caliper-benchconfig', benchPath,
      '--caliper-flow-only-test',
    ];

    let out = '';
    let child;
    try {
      child = spawn(caliperBin(), args, {
        cwd: CALIPER_WORKSPACE,
        env: { ...process.env, CORE_PEER_TLS_ENABLED: String(config.tlsEnabled) },
      });
    } catch (err) {
      return resolve({ ok: false, error: `Could not start caliper: ${err.message}` });
    }

    job._child = child;
    const timer = setTimeout(() => {
      try { child.kill('SIGKILL'); } catch (_) { /* already gone */ }
    }, opts.timeoutMs);

    child.stdout.on('data', (d) => { out += d.toString(); });
    child.stderr.on('data', (d) => { out += d.toString(); });
    child.on('error', (err) => {
      clearTimeout(timer);
      job._child = null;
      resolve({ ok: false, error: `caliper could not run: ${err.message}` });
    });
    child.on('close', (code) => {
      clearTimeout(timer);
      job._child = null;
      const m = parseCaliper(out);
      // Caliper exits 0 even when every round failed, so the presence of
      // results decides the outcome, not the exit code.
      const produced = Number.isFinite(m.successCount);
      resolve({
        ok: code === 0 && produced,
        exitCode: code,
        metrics: m,
        output: out.split('\n').slice(-60).join('\n'),
        error: produced
          ? (code === 0 ? null : `caliper exited with code ${code}`)
          : /SeedNetwork first|no antennas registered|no antenna layout/i.test(out)
            ? `${target.contract} has no antenna layout — run scripts/seed-network.sh`
            : (m.roundError || `caliper exited with code ${code}`),
        configPath: benchPath,
      });
    });
  });
}

/* ── Self-healing asset generation ────────────────────────────────────
   The Caliper workload and network files are pure code generation from
   the catalog — nothing about them is hand-edited, and nothing outside
   this repository is needed to rebuild them. So when they are missing,
   rebuild them instead of failing and asking the operator to run a
   script. This removes a whole class of "works after you also run X"
   support round-trips.                                                 */

const REPO_ROOT = path.resolve(__dirname, '..');

function regenerate(script, label) {
  const file = path.join(REPO_ROOT, 'scripts', script);
  if (!fs.existsSync(file)) {
    return `${label} are missing and ${file} is not there to rebuild them.`;
  }
  try {
    execFileSync(process.execPath, [file, '--workspace', CALIPER_WORKSPACE], {
      cwd: REPO_ROOT,
      timeout: 120_000,
      stdio: 'pipe',
    });
    return null;
  } catch (err) {
    const detail = (err.stderr || err.stdout || '').toString().trim().split('\n').slice(-3).join(' ');
    return `${label} are missing and could not be rebuilt: ${detail || err.message}`;
  }
}

/** Make sure the workload modules and network config exist. */
function ensureCaliperAssets(orgNum) {
  const workload = path.join(CALIPER_WORKSPACE, 'workload', 'generic-write.js');
  if (!fs.existsSync(workload)) {
    const err = regenerate('gen-caliper-assets.js', 'Caliper workloads');
    if (err) return err;
    if (!fs.existsSync(workload)) {
      return `Caliper workloads were rebuilt but ${workload} still is not there.`;
    }
  }

  const net = path.join(CALIPER_WORKSPACE, 'networks', `org${orgNum}.yaml`);
  if (!fs.existsSync(net)) {
    const err = regenerate('gen-caliper-network.js', 'Caliper network configuration');
    if (err) return err;
    if (!fs.existsSync(net)) {
      return `Caliper network configuration was rebuilt but ${net} still is not there. `
        + 'Check that crypto material exists for that organization.';
    }
  }

  return null;
}

/* ── Job store ────────────────────────────────────────────────────────
   In memory, capped. Jobs do not need to survive a restart — the CSV of
   any finished run is written to disk under bench-runs/<id>/.          */

const jobs = new Map();
const JOB_LIMIT = 40;

function newJobId() {
  return `${Date.now().toString(36)}-${Math.random().toString(36).slice(2, 7)}`;
}

function trimJobs() {
  while (jobs.size > JOB_LIMIT) {
    const oldest = jobs.keys().next().value;
    jobs.delete(oldest);
  }
}

function publicJob(job) {
  return {
    id: job.id,
    tool: job.tool,
    status: job.status,
    startedAt: job.startedAt,
    finishedAt: job.finishedAt,
    options: job.options,
    selection: job.selection,
    total: job.targets.length,
    completed: job.results.length,
    current: job.current,
    results: job.results,
    summary: job.summary,
    error: job.error,
  };
}

/** Aggregate per-target results into one headline set of figures. */
function summarize(results) {
  const done = results.filter((r) => r.ok);
  const committed = results.reduce((n, r) => n + (r.successCount || 0), 0);
  const rejected = results.reduce((n, r) => n + (r.failedCount || 0), 0);
  const tpsList = done.map((r) => r.tps).filter(Number.isFinite);
  const latList = done.map((r) => r.latencyAvg).filter(Number.isFinite);
  const mean = (a) => (a.length ? a.reduce((x, y) => x + y, 0) / a.length : 0);
  const ranked = done
    .filter((r) => Number.isFinite(r.tps) && r.tps > 0)
    .sort((a, b) => b.tps - a.tps);
  const best = ranked[0];
  const worst = ranked[ranked.length - 1];
  return {
    targetsRun: results.length,
    targetsOk: done.length,
    targetsFailed: results.length - done.length,
    committed,
    rejected,
    successRate: committed + rejected ? (committed / (committed + rejected)) * 100 : 0,
    tpsMean: mean(tpsList),
    tpsMax: tpsList.length ? Math.max(...tpsList) : 0,
    tpsMin: tpsList.length ? Math.min(...tpsList) : 0,
    latencyMean: mean(latList),
    fastestTarget: best ? best.id : null,
    slowestTarget: worst ? worst.id : null,
  };
}

function resultsToCsv(job) {
  const head = [
    'run_id', 'tool', 'policy', 'repeat', 'channel', 'contract', 'function',
    'org', 'target_tps', 'tx_number', 'workers', 'endorsers',
    'throughput_tps', 'duration_s', 'blocks', 'avg_block_size',
    'latency_avg_ms', 'latency_min_ms', 'latency_max_ms',
    'committed', 'rejected', 'ok', 'error',
  ].join(',');
  const esc = (v) => {
    const s = v === null || v === undefined ? '' : String(v);
    return /[",\n]/.test(s) ? `"${s.replace(/"/g, '""')}"` : s;
  };
  const rows = job.results.map((r) => [
    job.id, job.tool, job.options.policy, r.repeat, r.channel, r.contract, r.fn,
    job.options.orgNums.join('|'), job.options.rate, job.options.txNumber,
    job.options.workers, job.options.orgNums.length,
    r.tps, r.durationSec, r.blockCount, r.avgBlockSize,
    r.latencyReported ? r.latencyAvg : '', r.latencyReported ? r.latencyMin : '',
    r.latencyReported ? r.latencyMax : '',
    r.successCount, r.failedCount, r.ok, r.error,
  ].map(esc).join(','));
  return [head, ...rows].join('\n');
}

/* ── Orchestration ───────────────────────────────────────────────────── */

function normalizeOptions(body = {}) {
  const orgNums = Array.isArray(body.orgs) && body.orgs.length
    ? body.orgs.map(Number).filter((n) => n >= 1 && n <= 8)
    : [Number(body.org) || 1];
  if (!orgNums.length) throw new Error('Pick at least one organization');

  const rate = Math.max(1, Math.min(5000, Number(body.tps) || 20));
  const txNumber = body.txNumber
    ? Math.max(1, Math.min(200000, Number(body.txNumber)))
    : Math.max(1, Math.round(rate * (Number(body.duration) || 30)));

  return {
    policy: POLICY_FILES[body.policy] ? body.policy : 'any',
    orgNums,
    rate,
    txNumber,
    workers: Math.max(1, Math.min(16, Number(body.workers) || 2)),
    repeat: Math.max(1, Math.min(10, Number(body.repeat) || 1)),
    readPhase: !!body.readPhase,
    readRate: Number(body.readTps) || 0,
    burst: Number(body.burst) || 0,
    connections: Math.max(1, Math.min(64, Number(body.connections) || 8)),
    clientsPerConn: Math.max(1, Math.min(64, Number(body.clientsPerConn) || 10)),
    keyPrefix: (body.keyPrefix || 'bench').replace(/[^A-Za-z0-9_-]/g, ''),
    timeoutMs: Math.max(30_000, Math.min(3_600_000, Number(body.timeoutMs) || 600_000)),
  };
}

/**
 * Start a benchmark job. Returns the job id immediately; the run
 * continues in the background.
 */
function startJob(body = {}) {
  const tool = body.tool === 'caliper' ? 'caliper' : 'tape';
  const options = normalizeOptions(body);
  const targets = resolveTargets(body.selection || body);

  if (!targets.length) {
    throw new Error(
      'That selection produced no runnable targets. Read-only contracts are excluded unless you include them.');
  }

  options.policyPath = ensurePolicyFile(options.policy);

  const job = {
    id: newJobId(),
    tool,
    status: 'running',
    startedAt: new Date().toISOString(),
    finishedAt: null,
    options,
    selection: body.selection || { mode: body.mode },
    targets,
    results: [],
    current: null,
    summary: null,
    error: null,
    cancelled: false,
    _child: null,
  };

  jobs.set(job.id, job);
  trimJobs();
  fs.mkdirSync(path.join(RUN_DIR, job.id), { recursive: true });

  // Kick off without blocking the response.
  runJob(job).catch((err) => {
    job.status = 'failed';
    job.error = err.message;
    job.finishedAt = new Date().toISOString();
  });

  return job;
}

async function runJob(job) {
  const { options, targets, tool } = job;
  const runner = tool === 'caliper' ? runCaliperTarget : runTapeTarget;

  for (let rep = 1; rep <= options.repeat; rep++) {
    for (const target of targets) {
      if (job.cancelled) break;

      job.current = {
        id: target.id,
        channel: target.channel,
        contract: target.contract,
        fn: target.fn,
        repeat: rep,
        startedAt: new Date().toISOString(),
      };

      // A distinct prefix per repeat keeps each pass writing fresh keys.
      const opts = {
        ...options,
        keyPrefix: options.repeat > 1
          ? `${options.keyPrefix}${rep}`
          : options.keyPrefix,
      };

      let outcome;
      try {
        outcome = await runner(target, opts, job);
      } catch (err) {
        outcome = { ok: false, error: err.message };
      }

      const m = outcome.metrics || {};
      job.results.push({
        id: target.id,
        channel: target.channel,
        contract: target.contract,
        fn: target.fn,
        repeat: rep,
        ok: !!outcome.ok,
        exitCode: outcome.exitCode ?? null,
        tps: Number.isFinite(m.tps) ? m.tps : 0,
        latencyAvg: Number.isFinite(m.latencyAvg) ? m.latencyAvg : 0,
        latencyMin: Number.isFinite(m.latencyMin) ? m.latencyMin : 0,
        latencyMax: Number.isFinite(m.latencyMax) ? m.latencyMax : 0,
        // null rather than 0 when the tool does not report latency, so the
        // UI can show "not reported" instead of an authoritative-looking zero
        latencyReported: Number.isFinite(m.latencyAvg),
        durationSec: Number.isFinite(m.durationSec) ? m.durationSec : null,
        blockCount: Number.isFinite(m.blockCount) ? m.blockCount : null,
        readTps: Number.isFinite(m.readTps) ? m.readTps : null,
        readLatencyAvg: Number.isFinite(m.readLatencyAvg) ? m.readLatencyAvg : null,
        avgBlockSize: Number.isFinite(m.avgBlockSize) ? m.avgBlockSize : null,
        successCount: Number.isFinite(m.successCount) ? m.successCount : 0,
        failedCount: Number.isFinite(m.failedCount) ? m.failedCount : 0,
        error: outcome.error || null,
        output: outcome.output || '',
        finishedAt: new Date().toISOString(),
      });

      job.summary = summarize(job.results);
    }
    if (job.cancelled) break;
  }

  job.current = null;
  job.summary = summarize(job.results);
  job.status = job.cancelled ? 'cancelled' : 'finished';
  job.finishedAt = new Date().toISOString();

  try {
    fs.writeFileSync(
      path.join(RUN_DIR, job.id, 'results.csv'), resultsToCsv(job), 'utf8');
    fs.writeFileSync(
      path.join(RUN_DIR, job.id, 'job.json'),
      JSON.stringify(publicJob(job), null, 2), 'utf8');
  } catch (_) {
    // Persisting the run is a convenience, not a requirement.
  }
}

function cancelJob(id) {
  const job = jobs.get(id);
  if (!job) return null;
  job.cancelled = true;
  if (job._child) {
    try { job._child.kill('SIGKILL'); } catch (_) { /* already gone */ }
  }
  return job;
}

module.exports = {
  startJob,
  cancelJob,
  getJob: (id) => jobs.get(id) || null,
  listJobs: () => [...jobs.values()].map(publicJob).reverse(),
  publicJob,
  resultsToCsv,
  ensurePolicyFile,
  POLICY_FILES,
  POLICY_SOURCE,
  TEST_TOOLS_DIR,
  CALIPER_WORKSPACE,
  TAPE_CONFIG_DIR,
  RUN_DIR,
};
