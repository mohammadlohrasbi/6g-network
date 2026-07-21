#!/bin/bash
# patch-index.sh (v3) — چهار اصلاح idempotent روی server/index.js:
#  ۱) SCENARIO_FN → توابع واقعی chaincode
#  ۲) generateTapeConfig → ۸ endorser + policyFile (majority.rego) + committer از peer org1
#  ۳) اجرای tape از UI → استفاده از عملیات واقعی کانال (CHANNEL_TEST_FN از fabric.js)
#  ۴) اتصال روتر سناریوی 6G (scenario-routes.js) به /api/scenario
# پشتیبان می‌گیرد، پچ می‌کند، syntax چک می‌کند و در صورت خطا برمی‌گرداند.
set -e

INDEX="/root/6g-network/server/index.js"
[ ! -f "$INDEX" ] && { echo "یافت نشد: $INDEX"; exit 1; }

BK="${INDEX}.bak_$(date +%Y%m%d_%H%M%S)"
cp "$INDEX" "$BK"
echo "پشتیبان: $BK"

node << 'NODE_EOF'
const fs = require('fs');
const p = '/root/6g-network/server/index.js';
let s = fs.readFileSync(p, 'utf8');
let changed = 0;

// ── ۱) SCENARIO_FN ──
const oldFn = `const SCENARIO_FN = {
  iotRegister: 'RegisterDevice',
  iotUpdate: 'UpdateDeviceState',
  iotQuery: 'QueryDevice',
  userRegister: 'RegisterUser',
  userQuery: 'QueryUser',
  handover: 'RecordHandover',
  createAsset: 'CreateAsset',
  readAsset: 'ReadAsset',
};`;
const newFn = `const SCENARIO_FN = {
  iotRegister: 'Register',
  iotUpdate: 'UpdateIoTStatus',
  iotQuery: 'QueryAsset',
  userRegister: 'Register',
  userQuery: 'QueryAsset',
  handover: 'Connect',
  createAsset: 'RecordSignalStrength',
  readAsset: 'QueryAsset',
};`;
if (s.includes(oldFn)) { s = s.replace(oldFn, newFn); changed++; console.log('۱) SCENARIO_FN اصلاح شد'); }
else if (s.includes("iotUpdate: 'UpdateIoTStatus'")) { console.log('۱) SCENARIO_FN از قبل اصلاح بود'); }
else { console.error('۱) بلوک SCENARIO_FN پیدا نشد — دستی بررسی کنید'); }

// ── ۲) generateTapeConfig ──
const oldTape = `  const endorsers = [
    {
      addr: org.peerEndpoint,
      tls_ca_cert: org.tlsRootCert,
      org: org.mspId,
    },
  ];

  const committers = [
    {
      addr: config.orderer.endpoint,
      tls_ca_cert: config.orderer.tlsCaCert,
      org: 'OrdererMSP',
    },
  ];`;
const newTape = `  // همه ۸ سازمان endorse می‌کنند تا سیاست MAJORITY (۵ از ۸) برآورده شود
  const endorsers = [];
  for (let i = 1; i <= 8; i++) {
    const o = config.getOrg(i);
    if (!o) continue;
    endorsers.push({
      addr: o.peerEndpoint,
      tls_ca_cert: o.tlsRootCert || '',
      org: o.mspId.replace('MSP', ''),
    });
  }

  const org1 = config.getOrg(1);
  const committers = [
    {
      addr: org1.peerEndpoint,
      tls_ca_cert: org1.tlsRootCert || '',
      org: 'org1',
    },
  ];`;
if (s.includes(oldTape)) { s = s.replace(oldTape, newTape); changed++; console.log('۲) generateTapeConfig: endorsers/committers اصلاح شد'); }
else if (s.includes("o.mspId.replace('MSP', '')")) { console.log('۲) generateTapeConfig از قبل اصلاح بود'); }
else { console.error('۲) بلوک endorsers پیدا نشد — دستی بررسی کنید'); }

// policyFile در شیء بازگشتی
const oldRet = `    channel,
    chaincode,
    args: [fn, ...(args || [])],`;
const newRet = `    channel,
    chaincode,
    policyFile: path.join(TAPE_CONFIG_DIR, 'majority.rego'),
    args: [fn, ...(args || [])],`;
if (s.includes(newRet)) { console.log('۲ب) policyFile از قبل بود'); }
else if (s.includes(oldRet)) { s = s.replace(oldRet, newRet); changed++; console.log('۲ب) policyFile اضافه شد'); }
else { console.error('۲ب) محل درج policyFile پیدا نشد'); }

// ── ۳) tape از UI با عملیات واقعی کانال ──
const oldArgs = `      // build args for tape from the scenario params when not given explicitly
      const tapeArgs = Array.isArray(args)
        ? args
        : [String(iotCount || userCount || 1)];
      result = await runTapeTest({
        orgDef,
        channel,
        chaincode,
        fn,`;
const newArgs = `      // برای tape، عملیات واقعی کانال (CHANNEL_TEST_FN) با آرگومان‌های معتبر استفاده می‌شود
      const { CHANNEL_TEST_FN } = require('./fabric');
      const op = CHANNEL_TEST_FN[channel];
      const useOp = op && !Array.isArray(args) && !fnDirect;
      const tapeFn = useOp ? op.fn : fn;
      const tapeChaincode = useOp ? op.chaincode : chaincode;
      const tapeArgs = Array.isArray(args)
        ? args
        : useOp
          ? op.buildArgs('ui-' + Date.now())
          : [String(iotCount || userCount || 1)];
      result = await runTapeTest({
        orgDef,
        channel,
        chaincode: tapeChaincode,
        fn: tapeFn,`;
if (s.includes(oldArgs)) { s = s.replace(oldArgs, newArgs); changed++; console.log('۳) اجرای tape با عملیات واقعی کانال اصلاح شد'); }
else if (s.includes('CHANNEL_TEST_FN[channel]')) { console.log('۳) از قبل اصلاح بود'); }
else { console.error('۳) بلوک args پیدا نشد — دستی بررسی کنید'); }

// ── ۴) اتصال روتر سناریو ──
const mount = "app.use('/api/scenario', require('./scenario-routes'));";
if (s.includes(mount)) { console.log('۴) روتر سناریو از قبل متصل بود'); }
else {
  const anchorRoute = "app.post('/api/test/execute'";
  const j = s.indexOf(anchorRoute);
  if (j === -1) { console.error('۴) انکر /api/test/execute پیدا نشد'); }
  else {
    s = s.slice(0, j) + '// سناریوی شبیه‌سازی 6G (توپولوژی تصادفی + تخصیص نزدیک‌ترین آنتن)\n' + mount + '\n\n' + s.slice(j);
    changed++; console.log('۴) روتر سناریو متصل شد');
  }
}

fs.writeFileSync(p, s);
console.log('تغییرات اعمال‌شده: ' + changed);
NODE_EOF

if node --check "$INDEX" 2>/dev/null; then
    echo "✅ پچ اعمال شد و syntax سالم است."
    echo "ری‌استارت سرور:  systemctl restart dashboard"
else
    echo "❌ خطای syntax — بازگردانی از پشتیبان..."
    cp "$BK" "$INDEX"
    exit 1
fi
