#!/bin/bash
# create_shared_ca.sh — راه‌حل نهایی: همه Adminها در admincerts shared-msp

set -e

PROJECT_DIR="/root/6g-network/config"

log() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] $*"; }
success() { log "موفق: $*"; }
error() { log "خطا: $*"; exit 1; }

log "شروع ساخت bundled-tls-ca.pem و اصلاح shared-msp..."

cd "$PROJECT_DIR"

# ۱. ساخت bundled TLS CA
BUNDLED_TLS_FILE="bundled-tls-ca.pem"

log "ساخت bundled-tls-ca.pem..."

> "$BUNDLED_TLS_FILE"

find ./crypto-config -path "*/tlsca/*-cert.pem" -exec cat {} \; >> "$BUNDLED_TLS_FILE" 2>/dev/null || true
find ./crypto-config -path "*/tls/ca.crt" -exec cat {} \; >> "$BUNDLED_TLS_FILE" 2>/dev/null || true

sed -i '/^$/d' "$BUNDLED_TLS_FILE"

success "bundled-tls-ca.pem ساخته شد"

# ۲. ساخت shared-msp با admincerts کامل (همه ۸ Admin)
log "ساخت shared-msp با admincerts کامل..."

mkdir -p shared-msp
rm -rf shared-msp/*

for i in {1..8}; do
  SRC="./crypto-config/peerOrganizations/org${i}.example.com/users/Admin@org${i}.example.com/msp"
  DST="shared-msp/Org${i}MSP"

  cp -r "$SRC" "$DST"

  # admincerts را با همه ۸ Admin پر می‌کنیم
  rm -rf "$DST/admincerts"
  mkdir "$DST/admincerts"

  for j in {1..8}; do
    ADMIN_CERT="./crypto-config/peerOrganizations/org${j}.example.com/users/Admin@org${j}.example.com/msp/signcerts/Admin@org${j}.example.com-cert.pem"
    cp "$ADMIN_CERT" "$DST/admincerts/Admin@org${j}.example.com-cert.pem"
  done

  log "MSP Org${i}MSP ساخته شد — admincerts شامل همه ۸ Admin"
done

success "shared-msp با admincerts کامل آماده است!"

# نمایش نتیجه
log "نمونه admincerts در shared-msp/Org1MSP:"
ls -l shared-msp/Org1MSP/admincerts/ | wc -l  # باید ۸ فایل باشد

success "تمام تنظیمات آماده است!"

log "در docker-compose.yml:"
log "  - CORE_PEER_MSPCONFIGPATH=/etc/hyperledger/fabric/shared-msp/OrgXMSP را فعال کنید"
log "  - ./shared-msp:/etc/hyperledger/fabric/shared-msp را نگه دارید"
log ""
log "اجرا کنید:"
log "docker-compose down -v && docker-compose up -d"
log "./setup.sh"
