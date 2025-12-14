#!/bin/bash
# create_shared_ca.sh — ساخت پوشه‌های مشترک MSP و فایل bundled TLS CA با اصلاح admincerts
# این اسکریپت قبل از بالا آوردن شبکه اجرا شود

set -e

PROJECT_DIR="/root/6g-network/config"

log() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] $*"; }
success() { log "موفق: $*"; }
error() { log "خطا: $*"; exit 1; }

log "شروع ساخت پوشه‌های مشترک MSP و فایل bundled TLS CA..."

cd "$PROJECT_DIR"

# ------------------------------
# ۱. اصلاح admincerts در هاست (ضروری برای gossip و MSP)
# ------------------------------
log "اصلاح admincerts برای تمام سازمان‌ها در هاست..."

for i in {1..8}; do
  MSP_DIR="./crypto-config/peerOrganizations/org${i}.example.com/users/Admin@org${i}.example.com/msp"

  if [ ! -d "$MSP_DIR" ]; then
    error "پوشه MSP برای Org${i} پیدا نشد: $MSP_DIR"
  fi

  mkdir -p "$MSP_DIR/admincerts"

  # پیدا کردن گواهی Admin (اول فایل دقیق، سپس هر pem)
  CERT_SOURCE="$MSP_DIR/signcerts/Admin@org${i}.example.com-cert.pem"
  if [ ! -f "$CERT_SOURCE" ]; then
    CERT_SOURCE=$(find "$MSP_DIR/signcerts" -name "*.pem" | head -1)
  fi

  if [ -f "$CERT_SOURCE" ]; then
    cp "$CERT_SOURCE" "$MSP_DIR/admincerts/Admin@org${i}.example.com-cert.pem"
    log "admincerts برای Org${i} اصلاح شد"
  else
    error "گواهی Admin برای Org${i} پیدا نشد در $MSP_DIR/signcerts"
  fi
done

success "تمام admincerts با موفقیت در هاست اصلاح شد!"

# ------------------------------
# ۲. ساخت فایل bundled TLS CA (شامل تمام Peerها و Orderer)
# ------------------------------
BUNDLED_TLS_FILE="bundled-tls-ca.pem"

log "ساخت فایل bundled TLS CA ($BUNDLED_TLS_FILE) شامل تمام Peerها و Orderer..."

> "$BUNDLED_TLS_FILE"

# TLS CA از tlsca (اولویت بالاتر)
find ./crypto-config -path "*/tlsca/*-cert.pem" -exec cat {} \; >> "$BUNDLED_TLS_FILE" 2>/dev/null || true

# ca.crt از پوشه tls (برای پوشش کامل)
find ./crypto-config -path "*/tls/ca.crt" -exec cat {} \; >> "$BUNDLED_TLS_FILE" 2>/dev/null || true

# حذف خطوط خالی
sed -i '/^$/d' "$BUNDLED_TLS_FILE"

TLS_LINE_COUNT=$(wc -l < "$BUNDLED_TLS_FILE")
TLS_ESTIMATE=$((TLS_LINE_COUNT / 25))
log "تعداد خطوط در bundled-tls-ca.pem: $TLS_LINE_COUNT"
log "تعداد تخمینی TLS CAها: $TLS_ESTIMATE (باید حدود 9 باشد — ۸ Peer + ۱ Orderer)"

success "فایل bundled-tls-ca.pem با موفقیت ساخته شد!"

# ------------------------------
# ۳. ساخت پوشه مشترک MSP با نام دقیق OrgXMSP
# ------------------------------
log "ساخت پوشه مشترک MSP با نام دقیق OrgXMSP (shared-msp)..."

mkdir -p shared-msp
rm -rf shared-msp/*

for i in {1..8}; do
  SRC="./crypto-config/peerOrganizations/org${i}.example.com/users/Admin@org${i}.example.com/msp"
  DST="shared-msp/Org${i}MSP"

  if [ -d "$SRC" ]; then
    cp -r "$SRC" "$DST"
    log "MSP Org${i}MSP کپی شد"
  else
    error "MSP Admin برای Org${i} پیدا نشد!"
  fi
done

MSP_COUNT=$(ls -1 shared-msp | wc -l)
log "تعداد MSP کپی‌شده: $MSP_COUNT (باید 8 باشد)"

success "پوشه shared-msp با موفقیت ساخته شد!"

# ------------------------------
# نمایش نتیجه نهایی
# ------------------------------
log "محتویات نهایی:"
log "bundled-tls-ca.pem (تعداد خطوط: $TLS_LINE_COUNT):"
head -n 20 bundled-tls-ca.pem | tail -n 10

log "پوشه shared-msp:"
ls -la shared-msp/

success "تمام پوشه‌های مشترک (bundled-tls-ca.pem و shared-msp) با اصلاح admincerts ساخته شدند!"

log "حالا در docker-compose.yml برای هر Peer این تنظیمات را اعمال کنید:"
log "  - CORE_PEER_TLS_ROOTCERT_FILE=/etc/hyperledger/fabric/bundled-tls-ca.pem"
log "  - CORE_PEER_MSPCONFIGPATH=/etc/hyperledger/fabric/shared-msp/OrgXMSP  # X = شماره سازمان (مثلاً Org1MSP)"
log "  - ./bundled-tls-ca.pem:/etc/hyperledger/fabric/bundled-tls-ca.pem:ro"
log "  - ./shared-msp:/etc/hyperledger/fabric/shared-msp:ro"

log "سپس شبکه را بالا بیاورید:"
log "docker-compose down -v && docker-compose up -d"
log "و اجرا کنید: cd /root/6g-network/scripts && ./setup.sh"
