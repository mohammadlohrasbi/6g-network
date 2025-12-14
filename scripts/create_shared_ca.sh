#!/bin/bash
# create_shared_ca.sh — ساخت bundled TLS CA و اصلاح admincerts + shared-msp با MSP Admin (حالت کارکردی قبلی)

set -e

PROJECT_DIR="/root/6g-network/config"

log() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] $*"; }
success() { log "موفق: $*"; }
error() { log "خطا: $*"; exit 1; }

log "شروع ساخت bundled-tls-ca.pem و اصلاح admincerts و shared-msp (با MSP Admin)..."

cd "$PROJECT_DIR"

# ------------------------------
# ۱. اصلاح admincerts در MSP محلی Peerها (برای gossip صحیح)
# ------------------------------
log "اصلاح admincerts در MSP محلی Peerها..."

for i in {1..8}; do
  PEER_MSP="./crypto-config/peerOrganizations/org${i}.example.com/peers/peer0.org${i}.example.com/msp"
  if [ ! -d "$PEER_MSP" ]; then
    error "MSP Peer برای Org${i} پیدا نشد: $PEER_MSP"
  fi
  mkdir -p "$PEER_MSP/admincerts"

  for j in {1..8}; do
    ADMIN_CERT="./crypto-config/peerOrganizations/org${j}.example.com/users/Admin@org${j}.example.com/msp/signcerts/Admin@org${j}.example.com-cert.pem"
    if [ -f "$ADMIN_CERT" ]; then
      cp "$ADMIN_CERT" "$PEER_MSP/admincerts/Admin@org${j}.example.com-cert.pem"
    fi
  done

  log "admincerts برای Peer org${i} اصلاح شد (۸ Admin کپی شد)"
done

success "تمام admincerts در MSP محلی Peerها اصلاح شد!"

# ------------------------------
# ۲. ساخت bundled TLS CA (شامل تمام Peer و Orderer)
# ------------------------------
BUNDLED_TLS_FILE="bundled-tls-ca.pem"

log "ساخت bundled-tls-ca.pem شامل تمام TLS CAها (Peer + Orderer)..."

> "$BUNDLED_TLS_FILE"

# تمام tlsca/*-cert.pem
find ./crypto-config -path "*/tlsca/*-cert.pem" -exec cat {} \; >> "$BUNDLED_TLS_FILE" 2>/dev/null || true

# تمام tls/ca.crt
find ./crypto-config -path "*/tls/ca.crt" -exec cat {} \; >> "$BUNDLED_TLS_FILE" 2>/dev/null || true

sed -i '/^$/d' "$BUNDLED_TLS_FILE"

TLS_LINE_COUNT=$(wc -l < "$BUNDLED_TLS_FILE")
log "bundled-tls-ca.pem ساخته شد — تعداد خطوط: $TLS_LINE_COUNT"

success "فایل bundled-tls-ca.pem کامل ساخته شد!"

# ------------------------------
# ۳. ساخت shared-msp با MSP Admin (حالت قبلی که کار می‌کرد)
# ------------------------------
log "ساخت shared-msp با MSP Admin (برای CORE_PEER_MSPCONFIGPATH)..."

mkdir -p shared-msp
rm -rf shared-msp/*

for i in {1..8}; do
  SRC="./crypto-config/peerOrganizations/org${i}.example.com/users/Admin@org${i}.example.com/msp"
  DST="shared-msp/Org${i}MSP"

  if [ -d "$SRC" ]; then
    cp -r "$SRC" "$DST"
    log "MSP Admin Org${i}MSP کپی شد"
  else
    error "MSP Admin برای Org${i} پیدا نشد!"
  fi
done

MSP_COUNT=$(ls -1 shared-msp | wc -l)
log "تعداد MSP کپی‌شده در shared-msp: $MSP_COUNT (باید 8 باشد)"

success "shared-msp با MSP Admin ساخته شد!"

# ------------------------------
# نمایش نتیجه نهایی
# ------------------------------
log "محتویات نهایی:"
log "bundled-tls-ca.pem (نمونه):"
head -n 20 "$BUNDLED_TLS_FILE" | tail -n 10

log "پوشه shared-msp:"
ls -la shared-msp/

success "تمام تنظیمات آماده است — دقیقاً مثل حالت قبلی که کار می‌کرد!"

log "حالا در docker-compose.yml مطمئن شوید:"
log " - CORE_PEER_MSPCONFIGPATH=/etc/hyperledger/fabric/shared-msp/OrgXMSP"
log " - ./shared-msp:/etc/hyperledger/fabric/shared-msp (بدون :ro بهتر است)"
log "سپس اجرا کنید:"
log "docker-compose down -v && docker-compose up -d"
log "cd /root/6g-network/scripts && ./setup.sh"
