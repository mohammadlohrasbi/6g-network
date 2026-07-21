#!/bin/bash
# ══════════════════════════════════════════════════════════════
# add-test-endpoint.sh (بازنویسی‌شده)
#
# نسخه قبلی این اسکریپت کد endpoint را به index.js تزریق می‌کرد؛
# اما index.js فعلی از قبل endpoint کامل /api/test/execute دارد
# (پیاده‌سازی spawn-محور که از نسخه تزریقی بهتر است). تزریق مجدد
# حذف شد. این اسکریپت حالا سه کار انجام می‌دهد:
#   1) راستی‌آزمایی: endpoint، وابستگی js-yaml، و نگاشت توابع واقعی
#   2) هماهنگ‌سازی مسیرها: symlink هایی که index.js انتظار دارد
#      (test-tools/caliper/{networks,benchmarks,workloads})
#   3) اعتبارسنجی syntax سرور
# اجرای چندباره بی‌ضرر است (idempotent).
# ══════════════════════════════════════════════════════════════
set -e

ROOT_DIR="/root/6g-network"
SERVER_DIR="${ROOT_DIR}/server"
INDEX_FILE="${SERVER_DIR}/index.js"
TEST_DIR="${ROOT_DIR}/test-tools"
WORKSPACE="${TEST_DIR}/caliper-workspace"

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; NC='\033[0m'
ok()   { echo -e "${GREEN}✓${NC} $1"; }
warn() { echo -e "${YELLOW}⚠${NC} $1"; }
fail() { echo -e "${RED}✗${NC} $1"; FAILED=1; }
FAILED=0

echo "=== راستی‌آزمایی زیرساخت تست سرور ==="

# ── ۱) endpoint موجود است؟ ──
if [ ! -f "$INDEX_FILE" ]; then
    fail "index.js یافت نشد: $INDEX_FILE"; exit 1
fi
if grep -qE "app\.post\(['\"]\/api\/test\/execute['\"]" "$INDEX_FILE"; then
    ok "endpoint /api/test/execute در index.js موجود است"
else
    fail "endpoint /api/test/execute در index.js نیست — index.js اصلاح‌شده را کپی کنید"
fi

# ── ۲) وابستگی js-yaml ──
if [ -d "${SERVER_DIR}/node_modules/js-yaml" ]; then
    ok "js-yaml نصب است"
else
    warn "js-yaml نصب نیست — در حال نصب..."
    (cd "$SERVER_DIR" && npm install js-yaml@4 --save)
    ok "js-yaml نصب شد"
fi

# ── ۳) نگاشت توابع واقعی (SCENARIO_FN اصلاح‌شده) ──
if grep -q "UpdateIoTStatus" "$INDEX_FILE"; then
    ok "SCENARIO_FN به توابع واقعی chaincode اشاره می‌کند"
else
    warn "SCENARIO_FN هنوز توابع قدیمی (RegisterDevice/CreateAsset...) دارد — patch-index.sh را اجرا کنید"
fi

# ── ۴) symlink های مسیر (سازگاری index.js با خروجی installer) ──
if [ -d "$WORKSPACE" ]; then
    ln -sfn "$WORKSPACE" "${TEST_DIR}/caliper"
    ln -sfn workload "${WORKSPACE}/workloads"
    ok "symlink ها: test-tools/caliper → caliper-workspace ، workloads → workload"
else
    warn "caliper-workspace هنوز ساخته نشده — اول install-test-tools.sh را اجرا کنید"
fi

# ── ۵) اعتبارسنجی syntax ──
if node --check "$INDEX_FILE" 2>/dev/null; then
    ok "syntax سرور سالم است"
else
    fail "خطای syntax در index.js"
fi
for f in fabric.js connection.js config.js; do
    if node --check "${SERVER_DIR}/${f}" 2>/dev/null; then
        ok "syntax ${f} سالم است"
    else
        fail "خطای syntax در ${f}"
    fi
done

echo ""
[ "$FAILED" -eq 0 ] && echo -e "${GREEN}✅ همه بررسی‌ها موفق — سرور آماده اجرای تست‌هاست${NC}" \
                    || echo -e "${RED}برخی بررسی‌ها ناموفق — موارد بالا را برطرف کنید${NC}"
exit $FAILED
