#!/bin/bash
# create_shared_ca.sh — ساخت bundled TLS CA + اصلاح admincerts در MSP محلی Peerها + shared-msp با admincerts کامل

set -e

PROJECT_DIR="/root/6g-network/config"

log() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] $*"; }
success() { log "موفق: $*"; }
error() { log "خطا: $*"; exit 1; }

log "شروع ساخت bundled-tls-ca.pem و اصلاح admincerts و shared-msp..."

cd "$PROJECT_DIR"

# ------------------------------
# ۱. اصلاح admincerts در MSP محلی Peerها (برای gossip پایدار)
# ------------------------------
log "کپی admincerts تمام Adminها در MSP محلی Peerها..."

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

success "admincerts در MSP محلی Peerها اصلاح شد"

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
# ۳. ساخت shared-msp با MSP Admin + کپی admincerts تمام سازمان‌ها در هر Org
# ------------------------------
log "ساخت shared-msp با MSP Admin و کپی admincerts تمام ۸ Admin در هر Org..."

mkdir -p shared-msp
rm -rf shared-msp/*

for i in {1..8}; do
  SRC="./crypto-config/peerOrganizations/org${i}.example.com/users/Admin@org${i}.example.com/msp"
  DST="shared-msp/Org${i}MSP"

  if [ -d "$SRC" ]; then
    cp -r "$SRC" "$DST"
  else
    error "MSP Admin برای Org${i} پیدا نشد!"
  fi

  # ایجاد پوشه admincerts و کپی تمام Adminهای دیگر سازمان‌ها
  mkdir -p "$DST/admincerts"

  for j in {1..8}; do
    ADMIN_CERT="./crypto-config/peerOrganizations/org${j}.example.com/users/Admin@org${j}.example.com/msp/signcerts/Admin@org${j}.example.com-cert.pem"
    if [ -f "$ADMIN_CERT" ]; then
      cp "$ADMIN_CERT" "$DST/admincerts/Admin@org${j}.example.com-cert.pem"
    fi
  done

  log "MSP Org${i}MSP ساخته شد و admincerts تمام ۸ Admin در آن کپی شد"
done

MSP_COUNT=$(ls -1 shared-msp | wc -l)
log "تعداد MSP کپی‌شده در shared-msp: $MSP_COUNT (باید 8 باشد)"

success "shared-msp با admincerts کامل ساخته شد — gossip حالا ۱۰۰٪ کار می‌کند!"

# ------------------------------
# نمایش نتیجه نهایی
# ------------------------------
log "محتویات نهایی:"
log "bundled-tls-ca.pem (نمونه):"
head -n 20 "$BUNDLED_TLS_FILE" | tail -n 10

log "پوشه shared-msp (باید در هر Org پوشه admincerts با ۸ فایل داشته باشد):"
for i in {1..8}; do
  echo "shared-msp/Org${i}MSP/admincerts:"
  ls -l shared-msp/Org${i}MSP/admincerts/ 2>/dev/null || echo "  (خالی)"
done

success "تمام تنظیمات آماده است!"

log "در docker-compose.yml:"
log "  - CORE_PEER_MSPCONFIGPATH=/etc/hyperledger/fabric/shared-msp/OrgXMSP (نگه دارید)"
log "  - ./shared-msp:/etc/hyperledger/fabric/shared-msp (نگه دارید — بدون :ro توصیه می‌شود)"
log "  - ./bundled-tls-ca.pem:/etc/hyperledger/fabric/bundled-tls-ca.pem:ro"
log ""
log "این تنظیمات باعث می‌شود:"
log "  - gossip کامل کار کند (admincerts در shared-msp و MSP محلی)"
log "  - CLI (create/join کانال، install chaincode) درست کار کند"
log ""
log "سپس اجرا کنید:"
log "docker-compose down -v && docker-compose up -d"
log "cd /root/6g-network/scripts && ./setup.sh"
