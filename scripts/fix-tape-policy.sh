#!/bin/bash
# fix-tape-policy.sh — رفع خطای «empty endorsement policy» در Tape
# ۱) ساخت فایل سیاست OPA/rego معادل MAJORITY (حداقل ۵ سازمان از ۸)
# ۲) افزودن فیلد org به همه endorser/committer/orderer ها و policyFile به هر ۲۰ کانفیگ
# اجرای چندباره بی‌ضرر است.
set -e

TAPE_DIR="/root/6g-network/test-tools/tape-configs"
REGO="${TAPE_DIR}/majority.rego"
[ ! -d "$TAPE_DIR" ] && { echo "یافت نشد: $TAPE_DIR"; exit 1; }

# ── ۱) سیاست MAJORITY: تراکنش وقتی معتبر است که حداقل ۵ endorsement جمع شده باشد ──
cat > "$REGO" << 'EOF'
package tape

default allow = false

# MAJORITY از ۸ سازمان = حداقل ۵ امضا
allow {
    count(input) >= 5
}
EOF
echo "✓ سیاست rego ساخته شد: $REGO"

# ── ۲) پچ کانفیگ‌ها ──
python3 - "$TAPE_DIR" "$REGO" << 'PYEOF'
import re, sys, glob, os

tape_dir, rego = sys.argv[1], sys.argv[2]
patched = skipped = 0

for path in sorted(glob.glob(os.path.join(tape_dir, 'config-*.yaml')) +
                   [os.path.join(tape_dir, 'config.yaml')]):
    if not os.path.exists(path):
        continue
    s = open(path).read()
    if 'policyFile:' in s and 'commitThreshold' in s:
        skipped += 1
        continue
    orig = s
    s = re.sub(r'(  - addr: peer0\.(org\d)\.example\.com:\d+\n    tls_ca_cert: "")',
               lambda m: m.group(1) + f'\n    org: {m.group(2)}', s)
    s = s.replace('committer:\n  addr: peer0.org1.example.com:7051\n  tls_ca_cert: ""',
                  'committer:\n  addr: peer0.org1.example.com:7051\n  tls_ca_cert: ""\n  org: org1')
    s = re.sub(r'(orderer:\n  addr: orderer\.example\.com:\d+\n  tls_ca_cert: "")',
               r'\1\n  org: org1', s)
    s = re.sub(r'^channel: ', f'policyFile: {rego}\nchannel: ', s, flags=re.M)
    # tape v0.2.9: قالب committers (لیست) + commitThreshold
    s = s.replace('''committer:
  addr: peer0.org1.example.com:7051
  tls_ca_cert: ""
  org: org1''', '''committers:
  - addr: peer0.org1.example.com:7051
    tls_ca_cert: ""
    org: org1
commitThreshold: 1''')
    if s != orig:
        open(path, 'w').write(s)
        patched += 1

print(f"✓ {patched} کانفیگ پچ شد، {skipped} از قبل پچ بود")
PYEOF

echo ""
echo "نمونه (datachannel):"
grep -E "org:|policyFile:" "${TAPE_DIR}/config-datachannel.yaml" | head -12
echo ""
echo "حالا اجرا کنید:  /root/6g-network/test-tools/run-tape.sh datachannel"
