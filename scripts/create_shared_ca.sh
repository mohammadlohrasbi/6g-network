#!/bin/bash
# create_shared_tls_ca.sh — ساخت پوشه shared-tls-ca و کپی تمام TLS CAها (بدون تداخل نام)

set -e

PROJECT_DIR="/root/6g-network/config"

log() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] $*"; }
success() { log "موفق: $*"; }

log "شروع ساخت پوشه shared-tls-ca (فقط TLS CAها — بدون تداخل نام)..."

cd "$PROJECT_DIR"

# ساخت پوشه و پاک کردن قبلی
mkdir -p shared-tls-ca
rm -f shared-tls-ca/*

log "کپی تمام TLS CAها (از tlsca/*-cert.pem)..."

# کپی TLS CA از تمام سازمان‌ها (نام منحصربه‌فرد — هیچ تداخلی ندارد)
find ./crypto-config -path "*/tlsca/*-cert.pem" -exec cp {} shared-tls-ca/ \;

# چک تعداد فایل‌ها (باید ۹ باشد — ۸ Peer + ۱ Orderer)
TLS_CA_COUNT=$(ls -1 shared-tls-ca/*-cert.pem 2>/dev/null | wc -l || echo 0)
log "تعداد TLS CA کپی‌شده: $TLS_CA_COUNT (باید ۹ باشد)"

# نمایش فایل‌ها
log "فایل‌های موجود در shared-tls-ca:"
ls -la shared-tls-ca/

if [ $TLS_CA_COUNT -ge 8 ]; then
  success "پوشه shared-tls-ca با موفقیت ساخته شد — تمام TLS CAها کپی شدند (بدون تداخل نام)!"
  log "حالا در docker-compose.yml برای تمام Peerها این را بگذارید:"
  log "  - CORE_PEER_TLS_ROOTCERT_FILE=/etc/hyperledger/fabric/shared-tls-ca"
  log "  - ./shared-tls-ca:/etc/hyperledger/fabric/shared-tls-ca:ro"
  log "سپس شبکه را بالا بیاورید:"
  log "docker-compose down -v && docker-compose up -d"
else
  log "هشدار: تعداد TLS CAها کمتر از حد انتظار است — crypto-config را چک کنید"
fi
