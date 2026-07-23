/* ═══════════════════════════════════════════════════════════════
   test-app.js — benchmark controller.
   Auth is handled by the browser against nginx basic auth; every
   request is same-origin so credentials ride along automatically.
   ═══════════════════════════════════════════════════════════════ */

const API = window.location.origin + '/api';
let chart = null;

async function api(path, options = {}) {
  const res = await fetch(`${API}${path}`, { credentials: 'same-origin', ...options });
  const body = await res.json().catch(() => ({}));
  if (!res.ok) throw new Error(body.error || `${res.status} ${res.statusText}`);
  return body;
}

async function loadHealth() {
  const dot = document.getElementById('healthDot');
  const text = document.getElementById('healthText');
  if (!dot) return;
  try {
    await api('/health');
    dot.className = 'dot online';
    text.textContent = 'Network online';
  } catch {
    dot.className = 'dot offline';
    text.textContent = 'Network unreachable';
  }
}

async function loadNetworkInfo() {
  try {
    const data = await api('/network/info');

    const orgSelect = document.getElementById('orgSelect');
    orgSelect.innerHTML = '';
    data.organizations.forEach((org) => {
      const o = document.createElement('option');
      o.value = org.orgNumber;
      o.textContent = `${org.name} — org${org.orgNumber}`;
      orgSelect.appendChild(o);
    });

    const channelSelect = document.getElementById('channelSelect');
    channelSelect.innerHTML = '';
    data.channels.forEach((ch) => {
      const o = document.createElement('option');
      o.value = ch;
      o.textContent = ch;
      if (ch === 'datachannel') o.selected = true;
      channelSelect.appendChild(o);
    });

    await loadChaincodes();
  } catch (err) {
    alert(`Could not read the network — ${err.message}`);
  }
}

async function loadChaincodes() {
  const channel = document.getElementById('channelSelect').value;
  const sel = document.getElementById('chaincodeSelect');
  sel.innerHTML = '';
  try {
    const data = await api(`/channels/${channel}`);
    data.chaincodes.forEach((cc) => {
      const o = document.createElement('option');
      o.value = cc;
      o.textContent = cc;
      sel.appendChild(o);
    });
  } catch (err) {
    const o = document.createElement('option');
    o.textContent = 'none available';
    sel.appendChild(o);
  }
}

async function runTest() {
  const payload = {
    tool: document.getElementById('toolSelect').value,
    scenario: document.getElementById('scenarioSelect').value,
    channel: document.getElementById('channelSelect').value,
    chaincode: document.getElementById('chaincodeSelect').value,
    iotCount: parseInt(document.getElementById('iotCount').value, 10),
    userCount: parseInt(document.getElementById('userCount').value, 10),
    tps: parseInt(document.getElementById('tpsTarget').value, 10),
    duration: parseInt(document.getElementById('duration').value, 10),
    org: parseInt(document.getElementById('orgSelect').value, 10),
  };

  const btn = document.getElementById('runTestBtn');
  const spinner = document.getElementById('loadingSpinner');
  btn.disabled = true;
  spinner.style.display = 'flex';

  try {
    const results = await api('/test/execute', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(payload),
    });
    display(results, payload);
    document.getElementById('resultsSection').scrollIntoView({ behavior: 'smooth', block: 'start' });
  } catch (err) {
    alert(`Benchmark failed — ${err.message}`);
  } finally {
    btn.disabled = false;
    spinner.style.display = 'none';
  }
}

function display(r, sent) {
  document.getElementById('resultsSection').style.display = 'block';

  const tps = Number(r.tps) || 0;
  const lat = (r.latency && Number(r.latency.avg)) || 0;
  const ok = Number(r.successCount) || 0;
  const bad = Number(r.failedCount) || 0;
  const total = ok + bad;
  const rate = total ? (ok / total) * 100 : 0;

  const set = (id, v) => { document.getElementById(id).firstChild.nodeValue = v; };
  set('resultTps', tps.toFixed(2));
  set('resultLatency', lat.toFixed(1));
  set('resultSuccess', rate.toFixed(1));
  set('resultFailed', String(bad));

  const info = document.getElementById('runInfo');
  const toolName = sent.tool === 'tape' ? 'Tape' : 'Caliper';
  if (r.success === false || (total > 0 && ok === 0)) {
    info.className = 'note warn';
    info.textContent = `${toolName} finished but nothing committed on ${sent.channel}. Check the tool output below.`;
  } else {
    info.className = 'note info';
    info.textContent = `${toolName} on ${sent.channel} · ${sent.chaincode} — ${ok} of ${total} transactions committed at a ${sent.tps} tps target.`;
  }

  const outPanel = document.getElementById('outputPanel');
  const out = [r.stdout, r.stderr].filter(Boolean).join('\n').trim();
  if (out) {
    outPanel.style.display = 'block';
    document.getElementById('toolOutput').textContent = out.split('\n').slice(-25).join('\n');
  } else {
    outPanel.style.display = 'none';
  }

  drawChart(ok, bad, tps, lat);
}

function drawChart(ok, bad, tps, lat) {
  if (chart) chart.destroy();
  const ctx = document.getElementById('performanceChart').getContext('2d');
  const ink = getComputedStyle(document.body).getPropertyValue('--ink-faint').trim() || '#8792AB';
  const grid = 'rgba(255,255,255,0.06)';

  chart = new Chart(ctx, {
    type: 'bar',
    data: {
      labels: ['Committed', 'Rejected', 'Throughput (tps)', 'Mean latency (ms)'],
      datasets: [{
        data: [ok, bad, tps, lat],
        backgroundColor: ['#35D6C4', '#E36FA8', '#6C8CFF', '#F2A93B'],
        borderRadius: 4,
        borderSkipped: false,
      }],
    },
    options: {
      responsive: true,
      maintainAspectRatio: false,
      plugins: { legend: { display: false } },
      scales: {
        y: { beginAtZero: true, grid: { color: grid }, ticks: { color: ink } },
        x: { grid: { display: false }, ticks: { color: ink } },
      },
    },
  });
}

document.addEventListener('DOMContentLoaded', async () => {
  loadHealth();
  await loadNetworkInfo();
  document.getElementById('channelSelect').addEventListener('change', loadChaincodes);
  document.getElementById('runTestBtn').addEventListener('click', runTest);
});
