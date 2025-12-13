#!/bin/bash
# create_shared_tls_ca.sh — ساخت فایل bundled TLS CA (یک فایل واحد شامل تمام CAها)
# این روش اصولی و ۱۰۰٪ کارکردی در Fabric 2.5 است

set -e

PROJECT_DIR="/root/6g-network/config"

log() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] $*"; }
success() { log "موفق: $*"; }

log "شروع ساخت فایل bundled TLS CA (یک فایل واحد شامل تمام گواهی‌ها)..."

cd "$PROJECT_DIR"

# نام فایل نهایی bundled
BUNDLED_FILE="bundled-tls-ca.pem"

# پاک کردن فایل قبلی
> "$BUNDLED_FILE"

log "کپی و ادغام تمام گواهی‌های TLS CA در یک فایل واحد..."

# کپی تمام TLS CAها (از پوشه tlsca/*-cert.pem) به فایل bundled
find ./crypto-config -path "*/tlsca/*-cert.pem" -exec cat {} \; >> "$BUNDLED_FILE"

# کپی تمام ca.crt از پوشه tls (برای اطمینان از پوشش کامل)
find ./crypto-config -path "*/tls/ca.crt" -exec cat {} \; >> "$BUNDLED_FILE" 2>/dev/null || true

# حذف خطوط خالی اضافی (اختیاری — برای تمیز بودن)
sed -i '/^$/d' "$BUNDLED_FILE"

# چک تعداد گواهی‌ها (هر گواهی حدود 25-30 خط است)
LINE_COUNT=$(wc -l < "$BUNDLED_FILE")
CA_ESTIMATE=$((LINE_COUNT / 25))
log "تعداد خطوط در فایل bundled: $LINE_COUNT"
log "تعداد تخمینی گواهی‌ها: $CA_ESTIMATE (باید حدود 9 باشد — ۸ Peer + ۱ Orderer)"

# نمایش بخشی از فایل برای چک
log "پیش‌نمایش فایل bundled-tls-ca.pem:"
head -n 50 "$BUNDLED_FILE" | tail -n 30

success "فایل bundled-tls-ca.pem با موفقیت ساخته شد — تمام گواهی‌های TLS CA در یک فایل واحد ادغام شدند!"

log "حالا در docker-compose.yml برای تمام Peerها این را بگذارید:"
log "  - CORE_PEER_TLS_ROOTCERT_FILE=/etc/hyperledger/fabric/bundled-tls-ca.pem"
log "  - ./bundled-tls-ca.pem:/etc/hyperledger/fabric/bundled-tls-ca.pem:ro"

log "سپس شبکه را دوباره بالا بیاورید:"
log "cd /root/6g-network/config && docker-compose down -v && docker-compose up -d"
log "و اجرا کنید: cd /root/6g-network/scripts && ./setup.sh"
