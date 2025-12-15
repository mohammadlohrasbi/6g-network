#!/bin/bash
# create_shared_ca.sh — ساخت bundled TLS CA + اصلاح admincerts فقط در MSP محلی Peerها + shared-msp ساده (admincerts خالی)

set -e

PROJECT_DIR="/root/6g-network/config"

log() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] $*"; }
success() { log "موفق: $*"; }
error() { log "خطا: $*"; exit 1; }

log "شروع ساخت bundled-tls-ca.pem و اصلاح admincerts و shared-msp..."

cd "$PROJECT_DIR"

# ------------------------------
# ۱. اصلاح admincerts فقط در MSP محلی Peerها (کلید اصلی فعال شدن کامل gossip)
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
# ۲. ساخت bundled TLS CA (شامل تمام Peer و Orderer)
# ------------------------------
BUNDLED_TLS_FILE="bundled-tls-ca.pem"

log "ساخت bundled-tls-ca.pem شامل تمام TLS CAها (Peer + Orderer)..."

> "$BUNDLED_TLS_FILE"

find ./crypto-config -path "*/tlsca/*-cert.pem" -exec cat {} \; >> "$BUNDLED_TLS_FILE" 2>/dev/null || true
find ./crypto-config -path "*/tls/ca.crt" -exec cat {} \; >> "$BUNDLED_TLS_FILE" 2>/dev/null || true

sed -i '/^$/d' "$BUNDLED_TLS_FILE"

TLS_LINE_COUNT=$(wc -l < "$BUNDLED_TLS_FILE")
log "bundled-tls-ca.pem ساخته شد — تعداد خطوط: $TLS_LINE_COUNT"

success "فایل bundled-tls-ca.pem کامل ساخته شد!"

# ------------------------------
# ۳. ساخت shared-msp ساده با MSP Admin (admincerts خالی — برای Peer و CLI)
# ------------------------------
log "ساخت shared-msp ساده با MSP Admin (admincerts خالی — Peerها بالا می‌آیند)..."

mkdir -p shared-msp
rm -rf shared-msp/*

for i in {1..8}; do
  SRC="./crypto-config/peerOrganizations/org${i}.example.com/users/Admin@org${i}.example.com/msp"
  DST="shared-msp/Org${i}MSP"

  if [ -d "$SRC" ]; then
    cp -r "$SRC" "$DST"
    # اطمینان از خالی بودن پوشه admincerts
    rm -rf "$DST/admincerts"
    mkdir "$DST/admincerts"
    log "MSP Admin Org${i}MSP کپی شد — admincerts خالی"
  else
    error "MSP Admin برای Org${i} پیدا نشد!"
  fi
done

MSP_COUNT=$(ls -1 shared-msp | wc -l)
log "تعداد MSP کپی‌شده در shared-msp: $MSP_COUNT (باید 8 باشد)"

success "shared-msp با admincerts خالی ساخته شد!"

# ------------------------------
# نمایش نتیجه نهایی
# ------------------------------
log "محتویات نهایی:"
log "bundled-tls-ca.pem (نمونه):"
head -n 20 "$BUNDLED_TLS_FILE" | tail -n 10

log "پوشه shared-msp (admincerts خالی):"
ls -la shared-msp/

success "تمام تنظیمات آماده است!"

log "در docker-compose.yml:"
log "  - CORE_PEER_MSPCONFIGPATH=/etc/hyperledger/fabric/shared-msp/OrgXMSP را فعال کنید (کامنت را بردارید)"
log "  - ./shared-msp:/etc/hyperledger/fabric/shared-msp را نگه دارید"
log "  - ./bundled-tls-ca.pem:/etc/hyperledger/fabric/bundled-tls-ca.pem:ro"
log ""
log "این تنظیمات باعث می‌شود:"
log "  - Peerها بالا بیایند (shared-msp با admincerts خالی و keystore دارد)"
log "  - gossip کامل کار کند (admincerts تمام Adminها در MSP محلی)"
log "  - عملیات CLI و install chaincode روی همه Orgها موفق شود"
log ""
log "سپس اجرا کنید:"
log "docker-compose down -v && docker-compose up -d"
log "cd /root/6g-network/scripts && ./setup.sh"
