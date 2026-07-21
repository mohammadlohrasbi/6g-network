const API = window.location.origin + '/api';
let auth = '';
let OPTIONS = null;

const ORG_COLORS = ['#e6194b','#3cb44b','#4363d8','#f58231','#911eb4','#0aa2c0','#f032e6','#9a6324'];

document.addEventListener('DOMContentLoaded', async () => {
  const u = prompt('Username:');
  const p = prompt('Password:');
  auth = 'Basic ' + btoa(`${u}:${p}`);
  await loadOptions();
  await loadLast(); // نقشه آخرین جای‌گذاری، بدون نیاز به اجرای مجدد
  document.getElementById('runBtn').addEventListener('click', run);
  document.getElementById('selAll').addEventListener('change', toggleAll);
});

async function loadOptions() {
  const res = await fetch(`${API}/scenario/options`, { headers: { Authorization: auth } });
  if (!res.ok) { alert('خطا در بارگذاری گزینه‌ها (احراز هویت؟)'); return; }
  OPTIONS = await res.json();
  const box = document.getElementById('channelList');
  box.innerHTML = '';
  for (const ch of OPTIONS.channels) {
    const row = document.createElement('div');
    row.className = 'chrow';
    const cb = document.createElement('input');
    cb.type = 'checkbox'; cb.dataset.channel = ch.channel; cb.className = 'chk';
    const lbl = document.createElement('b');
    lbl.textContent = ch.channel;
    lbl.style.minWidth = '170px';
    const sel = document.createElement('select');
    sel.multiple = true; sel.size = 3; sel.dataset.channel = ch.channel;
    for (const cc of ch.chaincodes) {
      const o = document.createElement('option');
      o.value = cc.name;
      o.textContent = cc.available ? `${cc.name} → ${cc.fn}` : `${cc.name} (غیرفعال)`;
      o.disabled = !cc.available;
      if (cc.name === ch.defaultChaincode) o.selected = true;
      sel.appendChild(o);
    }
    row.append(cb, lbl, sel);
    box.appendChild(row);
  }
}

// آخرین جای‌گذاری ذخیره‌شده در سرور
async function loadLast() {
  try {
    const res = await fetch(`${API}/scenario/last`, { headers: { Authorization: auth } });
    if (!res.ok) return; // هنوز اجرایی نبوده
    const d = await res.json();
    render(d, true);
  } catch (_) { /* بی‌صدا */ }
}

function toggleAll(e) {
  document.querySelectorAll('.chk').forEach((c) => { c.checked = e.target.checked; });
}

function collectSelection() {
  const out = [];
  document.querySelectorAll('.chk').forEach((c) => {
    if (!c.checked) return;
    const sel = document.querySelector(`select[data-channel="${c.dataset.channel}"]`);
    const ccs = [...sel.selectedOptions].filter((o) => !o.disabled).map((o) => o.value);
    if (ccs.length) out.push({ channel: c.dataset.channel, chaincodes: ccs });
  });
  return out;
}

async function run() {
  const body = {
    iotCount: +document.getElementById('iotCount').value || 0,
    userCount: +document.getElementById('userCount').value || 0,
    seed: document.getElementById('seed').value,
    concurrency: +document.getElementById('concurrency').value || 6,
    connectEntities: document.getElementById('connectToggle').checked,
    selection: collectSelection(),
  };
  if (!body.selection.length && !body.connectEntities) {
    alert('حداقل یک کانال انتخاب کنید یا گزینه برقراری اتصال را فعال بگذارید.');
    return;
  }
  document.getElementById('runBtn').disabled = true;
  document.getElementById('spin').style.display = 'block';
  try {
    const res = await fetch(`${API}/scenario/execute`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json', Authorization: auth },
      body: JSON.stringify(body),
    });
    const data = await res.json();
    if (!res.ok) throw new Error(data.error || res.statusText);
    render(data, false);
  } catch (err) {
    alert('خطا: ' + err.message);
  } finally {
    document.getElementById('runBtn').disabled = false;
    document.getElementById('spin').style.display = 'none';
  }
}

function render(d, fromLast) {
  document.getElementById('results').style.display = 'block';

  const info = document.getElementById('lastInfo');
  const when = d.savedAt ? new Date(d.savedAt).toLocaleString('fa-IR') : '';
  info.textContent = fromLast
    ? `📌 آخرین جای‌گذاری ذخیره‌شده (${when}) — Seed: ${d.seed}`
    : `اجرای جدید (${when}) — Seed: ${d.seed}`;

  const P = d.performance || {};
  document.getElementById('rSeed').textContent = d.seed;
  document.getElementById('rTotal').textContent = P.totalTasks ?? '-';
  document.getElementById('rOk').textContent = P.successCount != null ? `${P.successCount} / ${P.failedCount}` : '-';
  document.getElementById('rTps').textContent = P.tps ?? '-';
  document.getElementById('rLat').textContent = P.latency ? `${P.latency.avg} (${P.latency.min}–${P.latency.max})` : '-';
  if (P.successCount === 0 && P.totalTasks > 0) {
    document.getElementById('lastInfo').innerHTML += ' — <b style="color:#c00">همه تراکنش‌ها ناموفق؛ نمونه خطا را پایین ببینید</b>';
  }
  document.getElementById('rDur').textContent = P.durationMs != null ? (P.durationMs / 1000).toFixed(1) : '-';

  drawMap(d);

  // جدول محدوده هر آنتن
  const cov = document.getElementById('covTable');
  cov.innerHTML = '<tr><th>سازمان</th><th>آنتن (فرستنده ماکرو)</th><th>x (m)</th><th>y (m)</th><th>IoT (فرستنده کوچک)</th><th>کاربر (گیرنده)</th><th>مجموع زیرمجموعه</th></tr>';
  for (const [org, c] of Object.entries(d.coverage || {})) {
    cov.innerHTML += `<tr>
      <td><span class="dot" style="background:${ORG_COLORS[org-1]}"></span>org${org}</td>
      <td>${c.antennaId}</td><td>${c.x}</td><td>${c.y}</td>
      <td>${c.iotCount}</td><td>${c.userCount}</td><td><b>${c.iotCount + c.userCount}</b></td></tr>`;
  }

  // جدول کانال/نوع
  const ct = document.getElementById('chTable');
  ct.innerHTML = '<tr><th>کانال</th><th>کل</th><th>موفق</th><th>ناموفق</th></tr>';
  for (const [ch, v] of Object.entries(P.perChannel || {})) {
    ct.innerHTML += `<tr><td>${ch}</td><td>${v.total}</td><td style="color:green">${v.ok}</td><td style="color:${v.fail ? 'red' : '#999'}">${v.fail}</td></tr>`;
  }
  ct.innerHTML += '<tr><th>نوع تراکنش</th><th>کل</th><th>موفق</th><th>ناموفق</th></tr>';
  const kindNames = { antenna: 'ثبت فرستنده‌های ماکرو', connect: 'برقراری اتصال گیرنده/فرستنده', 'entity-data': 'داده موجودیت‌ها' };
  for (const [k, v] of Object.entries(P.perKind || {})) {
    ct.innerHTML += `<tr><td>${kindNames[k] || k}</td><td>${v.total}</td><td style="color:green">${v.ok}</td><td style="color:${v.fail ? 'red' : '#999'}">${v.fail}</td></tr>`;
  }

  const fb = document.getElementById('failBox');
  fb.innerHTML = '';
  if (P.failureSamples && P.failureSamples.length) {
    fb.innerHTML = '<p class="note">نمونه خطاها: ' +
      P.failureSamples.map((f) => `${f.chaincode}.${f.fn}: ${f.error}`).join(' | ') + '</p>';
  }
}

// ═══ نقشه: فرستنده‌ها (▲ ماکروسل با موج انتشار، ● IoT) و گیرنده‌ها (■ کاربر با پیوند دریافت) ═══
function drawMap(d) {
  const svg = document.getElementById('map');
  const W = 560, pad = 14, scale = (W - 2 * pad) / d.areaMeters;
  const X = (v) => pad + v * scale;
  const Y = (v) => W - pad - v * scale; // محور y رو به بالا
  const antByOrg = {};
  for (const a of d.topology.antennas) antByOrg[a.orgNum] = a;
  let s = '';

  // شبکه هر ۲ کیلومتر + برچسب محور
  for (let km = 0; km <= d.areaMeters; km += 2000) {
    s += `<line x1="${X(km)}" y1="${Y(0)}" x2="${X(km)}" y2="${Y(d.areaMeters)}" stroke="#eee"/>`;
    s += `<line x1="${X(0)}" y1="${Y(km)}" x2="${X(d.areaMeters)}" y2="${Y(km)}" stroke="#eee"/>`;
    s += `<text x="${X(km)}" y="${W-2}" font-size="9" text-anchor="middle" fill="#999">${km/1000}km</text>`;
  }

  // لایه ۱ — پیوندهای دریافت: هر گیرنده (کاربر) به فرستنده ماکروی خودش
  for (const e of d.topology.users) {
    const a = antByOrg[e.orgNum];
    s += `<line x1="${X(e.x)}" y1="${Y(e.y)}" x2="${X(a.x)}" y2="${Y(a.y)}" stroke="${ORG_COLORS[e.orgNum-1]}" stroke-width="1" stroke-opacity="0.35"/>`;
  }
  // پیوند فرستنده‌های IoT به آنتن سرویس‌دهنده (نقطه‌چین کم‌رنگ)
  for (const e of d.topology.iots) {
    const a = antByOrg[e.orgNum];
    s += `<line x1="${X(e.x)}" y1="${Y(e.y)}" x2="${X(a.x)}" y2="${Y(a.y)}" stroke="${ORG_COLORS[e.orgNum-1]}" stroke-width="1" stroke-opacity="0.18" stroke-dasharray="3,3"/>`;
  }

  // لایه ۲ — فرستنده‌های IoT: دایره + کمان انتشار کوچک
  for (const e of d.topology.iots) {
    const c = ORG_COLORS[e.orgNum-1], x = X(e.x), y = Y(e.y);
    s += `<circle cx="${x}" cy="${y}" r="4.5" fill="${c}"><title>فرستنده ${e.id} → org${e.orgNum} (فاصله ${e.distToAntenna}m)</title></circle>`;
    s += `<circle cx="${x}" cy="${y}" r="9" fill="none" stroke="${c}" stroke-width="1" stroke-opacity="0.5" stroke-dasharray="2,2"/>`;
  }

  // لایه ۳ — گیرنده‌ها (کاربران): مربع
  for (const e of d.topology.users) {
    const c = ORG_COLORS[e.orgNum-1], x = X(e.x), y = Y(e.y);
    s += `<rect x="${x-4.5}" y="${y-4.5}" width="9" height="9" fill="#fff" stroke="${c}" stroke-width="2.2"><title>گیرنده ${e.id} → org${e.orgNum} (فاصله ${e.distToAntenna}m)</title></rect>`;
  }

  // لایه ۴ — فرستنده‌های ماکروسل: دکل مثلثی + امواج انتشار هم‌مرکز
  for (const a of d.topology.antennas) {
    const c = ORG_COLORS[a.orgNum-1], x = X(a.x), y = Y(a.y);
    for (const r of [16, 26, 36]) {
      s += `<circle cx="${x}" cy="${y}" r="${r}" fill="none" stroke="${c}" stroke-width="1.2" stroke-opacity="${0.55 - r/100}" stroke-dasharray="4,4"/>`;
    }
    s += `<polygon points="${x},${y-12} ${x-11},${y+9} ${x+11},${y+9}" fill="${c}" stroke="#222" stroke-width="1.3"><title>فرستنده ماکروسل ${a.id} — (${a.x}, ${a.y})</title></polygon>`;
    s += `<line x1="${x}" y1="${y+9}" x2="${x}" y2="${y+15}" stroke="#222" stroke-width="2"/>`;
    s += `<text x="${x}" y="${y+27}" font-size="10" font-weight="bold" text-anchor="middle" fill="#333">org${a.orgNum}</text>`;
  }
  svg.innerHTML = s;

  const lg = document.getElementById('legend');
  lg.innerHTML = '<b>راهنما — فرستنده‌ها و گیرنده‌ها</b><br>' +
    d.topology.antennas.map((a) =>
      `<span class="dot" style="background:${ORG_COLORS[a.orgNum-1]}"></span> org${a.orgNum} — ماکروسل (${(a.x/1000).toFixed(1)}, ${(a.y/1000).toFixed(1)}) km`
    ).join('<br>') +
    '<br><br>▲ فرستنده ماکروسل (با امواج انتشار)<br>● فرستنده IoT (آنتن کوچک)<br>■ گیرنده (کاربر)<br>— خط ممتد: پیوند دریافت کاربر از آنتن<br>┄ خط‌چین: اتصال IoT به آنتن سرویس‌دهنده<br><br>رنگ هر جزء = سازمانِ (سلولِ) تخصیص‌یافته؛ Hover = شناسه و فاصله.';
}
