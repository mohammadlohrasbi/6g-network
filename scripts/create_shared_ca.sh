#!/bin/bash
# create_shared_ca.sh — ساخت پوشه‌های مشترک MSP (کامل سازمان) و bundled TLS CA (با Orderer)

set -e

PROJECT_DIR="/root/6g-network/config"

log() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] $*"; }
success() { log "موفق: $*"; }
error() { log "خطا: $*"; exit 1; }

log "شروع ساخت پوشه‌های مشترک MSP و bundled TLS CA..."

cd "$PROJECT_DIR"

# ------------------------------
# ۱. اصلاح admincerts در MSP Admin (برای gossip)
# ------------------------------
log "اصلاح admincerts در MSP Adminها..."

for i in {1..8}; do
  ADMIN_MSP="./crypto-config/peerOrganizations/org${i}.example.com/users/Admin@org${i}.example.com/msp"
  if [ ! -d "$ADMIN_MSP" ]; then
    error "MSP Admin برای Org${i} پیدا نشد: $ADMIN_MSP"
  fi
  mkdir -p "$ADMIN_MSP/admincerts"
  CERT=$(find "$ADMIN_MSP/signcerts" -name "*.pem" | head -1)
  if [ -f "$CERT" ]; then
    cp "$CERT" "$ADMIN_MSP/admincerts/Admin@org${i}.example.com-cert.pem"
    log "admincerts برای Org${i} اصلاح شد"
  else
    error "گواهی Admin برای Org${i} پیدا نشد"
  fi
done

success "تمام admincerts اصلاح شد!"

# ------------------------------
# ۲. ساخت bundled TLS CA (شامل تمام Peer و Orderer)
# ------------------------------
BUNDLED_TLS_FILE="bundled-tls-ca.pem"
log "ساخت bundled-tls-ca.pem شامل تمام TLS CAها (Peer + Orderer)..."

> "$BUNDLED_TLS_FILE"

# تمام tlsca/*-cert.pem (Peer و Orderer)
find ./crypto-config -path "*/tlsca/*-cert.pem" -exec cat {} \; >> "$BUNDLED_TLS_FILE" 2>/dev/null || true

# تمام tls/ca.crt (Peer و Orderer)
find ./crypto-config -path "*/tls/ca.crt" -exec cat {} \; >> "$BUNDLED_TLS_FILE" 2>/dev/null || true

sed -i '/^$/d' "$BUNDLED_TLS_FILE"

TLS_LINE_COUNT=$(wc -l < "$BUNDLED_TLS_FILE")
log "bundled-tls-ca.pem ساخته شد — تعداد خطوط: $TLS_LINE_COUNT (باید حدود 225-250 باشد)"

success "bundled-tls-ca.pem کامل ساخته شد!"

# ------------------------------
# ۳. ساخت shared-msp با MSP کامل سازمان (نه فقط Admin)
# ------------------------------
log "ساخت shared-msp با MSP کامل سازمان‌ها (برای gossip صحیح)..."

mkdir -p shared-msp
rm -rf shared-msp/*

for i in {1..8}; do
  ORG_MSP="./crypto-config/peerOrganizations/org${i}.example.com/msp"  # مسیر MSP کامل سازمان
  DST="shared-msp/Org${i}MSP"

  if [ -d "$ORG_MSP" ]; then
    cp -r "$ORG_MSP" "$DST"
    log "MSP کامل Org${i}MSP کپی شد"
  else
    error "MSP سازمان Org${i} پیدا نشد: $ORG_MSP"
  fi
done

log "تعداد MSP کپی‌شده: $(ls -1 shared-msp | wc -l)"

success "shared-msp با MSP کامل ساخته شد!"

# ------------------------------
# نمایش نهایی
# ------------------------------
log "محتویات نهایی:"
log "bundled-tls-ca.pem (نمونه):"
head -n 20 bundled-tls-ca.pem | tail -n 10

log "پوشه shared-msp:"
ls -la shared-msp/

success "تمام تنظیمات آماده است — شبکه را از نو بالا بیاورید!"

log "اجرای دستورات:"
log "docker-compose down -v"
log "docker-compose up -d"
log "cd /root/6g-network/scripts && ./setup.sh"
