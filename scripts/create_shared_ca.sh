#!/bin/bash
# create_shared_ca.sh — ساخت پوشه‌های مشترک MSP و فایل bundled TLS CA
# این اسکریپت هر دو پوشه مشترک را می‌سازد

set -e

PROJECT_DIR="/root/6g-network/config"

log() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] $*"; }
success() { log "موفق: $*"; }

log "شروع ساخت پوشه‌های مشترک MSP و فایل bundled TLS CA..."

cd "$PROJECT_DIR"

# ------------------------------
# ۱. ساخت فایل bundled TLS CA (یک فایل واحد شامل تمام گواهی‌ها)
# ------------------------------
BUNDLED_TLS_FILE="bundled-tls-ca.pem"

log "ساخت فایل bundled TLS CA ($BUNDLED_TLS_FILE)..."

> "$BUNDLED_TLS_FILE"  # پاک کردن فایل قبلی

# کپی تمام TLS CAها (از پوشه tlsca/*-cert.pem)
find ./crypto-config -path "*/tlsca/*-cert.pem" -exec cat {} \; >> "$BUNDLED_TLS_FILE" 2>/dev/null || true

# کپی تمام ca.crt از پوشه tls (برای پوشش کامل)
find ./crypto-config -path "*/tls/ca.crt" -exec cat {} \; >> "$BUNDLED_TLS_FILE" 2>/dev/null || true

# حذف خطوط خالی اضافی
sed -i '/^$/d' "$BUNDLED_TLS_FILE"

TLS_LINE_COUNT=$(wc -l < "$BUNDLED_TLS_FILE")
TLS_ESTIMATE=$((TLS_LINE_COUNT / 25))
log "تعداد خطوط در bundled-tls-ca.pem: $TLS_LINE_COUNT"
log "تعداد تخمینی TLS CAها: $TLS_ESTIMATE (باید حدود ۹ باشد)"

success "فایل bundled-tls-ca.pem با موفقیت ساخته شد!"

# ------------------------------
# ۲. ساخت پوشه مشترک MSP برای Adminها
# ------------------------------
log "ساخت پوشه مشترک MSP برای Adminها (shared-msp)..."

mkdir -p shared-msp
rm -rf shared-msp/*  # پاک کردن محتوای قبلی

# کپی MSP هر Admin@orgX.example.com
for org_dir in ./crypto-config/peerOrganizations/org*.example.com; do
  if [ -d "$org_dir/users/Admin@$(basename $org_dir)" ]; then
    org_name=$(basename $org_dir .example.com)
    cp -r "$org_dir/users/Admin@$(basename $org_dir)/msp" "shared-msp/$org_name"
    log "MSP سازمان $org_name کپی شد"
  fi
done

# اگر Orderer هم Admin داشته باشد (اختیاری)
if [ -d "./crypto-config/ordererOrganizations/example.com/users/Admin@example.com" ]; then
  cp -r "./crypto-config/ordererOrganizations/example.com/users/Admin@example.com/msp" "shared-msp/OrdererMSP"
  log "MSP OrdererMSP کپی شد"
fi

MSP_COUNT=$(ls -1 shared-msp | wc -l)
log "تعداد MSP کپی‌شده: $MSP_COUNT (باید ۸ یا ۹ باشد)"

success "پوشه shared-msp با موفقیت ساخته شد!"

# ------------------------------
# نمایش نتیجه نهایی
# ------------------------------
log "فایل‌ها و پوشه‌های ساخته‌شده:"
ls -la bundled-tls-ca.pem
ls -la shared-msp/

success "تمام پوشه‌های مشترک (bundled-tls-ca.pem و shared-msp) با موفقیت ساخته شدند!"

log "حالا در docker-compose.yml برای تمام Peerها این تنظیمات را اعمال کنید:"
log "  - CORE_PEER_TLS_ROOTCERT_FILE=/etc/hyperledger/fabric/bundled-tls-ca.pem"
log "  - ./bundled-tls-ca.pem:/etc/hyperledger/fabric/bundled-tls-ca.pem:ro"
log "  - CORE_PEER_MSPCONFIGPATH=/etc/hyperledger/fabric/shared-msp/OrgXMSP  # OrgX = نام سازمان (مثلاً Org1MSP)"
log "  - ./shared-msp:/etc/hyperledger/fabric/shared-msp:ro"

log "سپس شبکه را دوباره بالا بیاورید:"
log "cd /root/6g-network/config && docker-compose down -v && docker-compose up -d"
log "و اجرا کنید: cd /root/6g-network/scripts && ./setup.sh"
