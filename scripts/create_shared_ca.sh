#!/bin/bash
# create_shared_ca.sh — ساخت bundled TLS CA + اصلاح admincerts در MSP محلی Peerها + (اختیاری) shared-msp با MSP Admin

set -e

PROJECT_DIR="/root/6g-network/config"

log() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] $*"; }
success() { log "موفق: $*"; }
error() { log "خطا: $*"; exit 1; }

log "شروع ساخت bundled-tls-ca.pem و اصلاح admincerts..."

cd "$PROJECT_DIR"

# ------------------------------
# ۱. اصلاح admincerts در MSP محلی Peerها (کلید اصلی فعال شدن gossip)
# ------------------------------
log "کپی admincerts تمام Adminها در MSP محلی Peerها (برای gossip کامل)..."

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

  log "admincerts تمام ۸ Admin در MSP Peer org${i} کپی شد"
done

success "تمام admincerts در MSP محلی Peerها اصلاح شد — gossip حالا کامل کار می‌کند!"

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
# ۳. (اختیاری) ساخت shared-msp با MSP Admin
# ------------------------------
log "ساخت shared-msp با MSP Admin (اگر می‌خواهید از CORE_PEER_MSPCONFIGPATH استفاده کنید)..."

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

success "shared-msp با MSP Admin ساخته شد (اختیاری)"

# ------------------------------
# نمایش نتیجه نهایی
# ------------------------------
log "محتویات نهایی:"
log "bundled-tls-ca.pem (نمونه):"
head -n 20 "$BUNDLED_TLS_FILE" | tail -n 10

log "پوشه shared-msp:"
ls -la shared-msp/

success "تمام تنظیمات آماده است!"

log "دو حالت برای docker-compose.yml:"
log "حالت ۱ (توصیه‌شده — ساده‌تر و پایدارتر):"
log "  - CORE_PEER_MSPCONFIGPATH را حذف کنید"
log "  - volume shared-msp را حذف کنید"
log "  - فقط MSP محلی Peer و bundled-tls-ca.pem را نگه دارید"
log ""
log "حالت ۲ (اگر می‌خواهید از shared-msp استفاده کنید):"
log "  - CORE_PEER_MSPCONFIGPATH=/etc/hyperledger/fabric/shared-msp/OrgXMSP"
log "  - ./shared-msp:/etc/hyperledger/fabric/shared-msp (بدون :ro توصیه می‌شود)"
log ""
log "سپس اجرا کنید:"
log "docker-compose down -v && docker-compose up -d"
log "cd /root/6g-network/scripts && ./setup.sh"
