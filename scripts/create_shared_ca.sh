#!/bin/bash
# create_shared_ca.sh — راه‌حل نهایی: gossip کامل + Peer بالا می‌آید

set -e

PROJECT_DIR="/root/6g-network/config"

log() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] $*"; }
success() { log "موفق: $*"; }
error() { log "خطا: $*"; exit 1; }

log "شروع ساخت bundled-tls-ca.pem و اصلاح admincerts و shared-msp..."

cd "$PROJECT_DIR"

# ------------------------------
# ۱. اصلاح admincerts فقط در MSP محلی Peerها (برای gossip کامل)
# ------------------------------
log "کپی admincerts تمام Adminها فقط در MSP محلی Peerها..."

for i in {1..8}; do
  PEER_MSP="./crypto-config/peerOrganizations/org${i}.example.com/peers/peer0.org${i}.example.com/msp"
  if [ ! -d "$PEER_MSP" ]; then
    error "MSP محلی Peer برای Org${i} پیدا نشد: $PEER_MSP"
  fi

  mkdir -p "$PEER_MSP/admincerts"

  for j in {1..8}; do
    ADMIN_CERT="./crypto-config/peerOrganizations/org${j}.example.com/users/Admin@org${j}.example.com/msp/signcerts/Admin@org${j}.example.com-cert.pem"
    if [ -f "$ADMIN_CERT" ]; then
      cp "$ADMIN_CERT" "$PEER_MSP/admincerts/Admin@org${j}.example.com-cert.pem"
    else
      error "گواهی Admin@org${j} پیدا نشد!"
    fi
  done

  log "admincerts تمام ۸ Admin در MSP محلی Peer org${i} کپی شد"
done

success "admincerts فقط در MSP محلی اصلاح شد — gossip حالا کامل کار می‌کند!"

# ------------------------------
# ۲. ساخت bundled TLS CA
# ------------------------------
BUNDLED_TLS_FILE="bundled-tls-ca.pem"

log "ساخت bundled-tls-ca.pem..."

> "$BUNDLED_TLS_FILE"

find ./crypto-config -path "*/tlsca/*-cert.pem" -exec cat {} \; >> "$BUNDLED_TLS_FILE" 2>/dev/null || true
find ./crypto-config -path "*/tls/ca.crt" -exec cat {} \; >> "$BUNDLED_TLS_FILE" 2>/dev/null || true

sed -i '/^$/d' "$BUNDLED_TLS_FILE"

log "bundled-tls-ca.pem ساخته شد — تعداد خطوط: $(wc -l < "$BUNDLED_TLS_FILE")"

success "bundled-tls-ca.pem کامل ساخته شد!"

# ------------------------------
# ۳. ساخت shared-msp با admincerts فقط خودش (مانند cryptogen اصلی)
# ------------------------------
log "ساخت shared-msp با admincerts فقط خودش (برای بالا آمدن Peer و CLI)..."

mkdir -p shared-msp
rm -rf shared-msp/*

for i in {1..8}; do
  SRC="./crypto-config/peerOrganizations/org${i}.example.com/users/Admin@org${i}.example.com/msp"
  DST="shared-msp/Org${i}MSP"

  cp -r "$SRC" "$DST"

  # فقط گواهی Admin خودش را در admincerts نگه می‌داریم
  mkdir -p "$DST/admincerts"
  SELF_ADMIN="./crypto-config/peerOrganizations/org${i}.example.com/users/Admin@org${i}.example.com/msp/signcerts/Admin@org${i}.example.com-cert.pem"
  cp "$SELF_ADMIN" "$DST/admincerts/Admin@org${i}.example.com-cert.pem"

  log "MSP Org${i}MSP ساخته شد — admincerts فقط شامل Admin خودش"
done

success "shared-msp آماده است!"

# ------------------------------
# نمایش نتیجه نهایی
# ------------------------------
log "نمونه admincerts در shared-msp/Org1MSP:"
ls -l shared-msp/Org1MSP/admincerts/

success "تمام تنظیمات آماده است!"

log "در docker-compose.yml:"
log "  - CORE_PEER_MSPCONFIGPATH=/etc/hyperledger/fabric/shared-msp/OrgXMSP را فعال کنید"
log "  - ./shared-msp:/etc/hyperledger/fabric/shared-msp را نگه دارید"
log ""
log "اجرا کنید:"
log "docker-compose down -v && docker-compose up -d"
log "./setup.sh"
