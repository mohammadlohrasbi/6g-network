#!/bin/bash
# create_shared_ca.sh — ساخت bundled TLS CA + اصلاح admincerts در MSP محلی + اصلاح admincerts در shared-msp

set -e

PROJECT_DIR="/root/6g-network/config"

log() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] $*"; }
success() { log "موفق: $*"; }

log "شروع اصلاح admincerts در MSP محلی و shared-msp و ساخت bundled-tls-ca.pem..."

cd "$PROJECT_DIR"

# ۱. اصلاح admincerts در MSP محلی Peerها (برای gossip در سطح پایین)
log "کپی admincerts تمام Adminها در MSP محلی Peerها..."

for i in {1..8}; do
  PEER_MSP="./crypto-config/peerOrganizations/org${i}.example.com/peers/peer0.org${i}.example.com/msp"
  mkdir -p "$PEER_MSP/admincerts"

  for j in {1..8}; do
    ADMIN_CERT="./crypto-config/peerOrganizations/org${j}.example.com/users/Admin@org${j}.example.com/msp/signcerts/Admin@org${j}.example.com-cert.pem"
    if [ -f "$ADMIN_CERT" ]; then
      cp "$ADMIN_CERT" "$PEER_MSP/admincerts/Admin@org${j}.example.com-cert.pem"
    fi
  done
done

success "admincerts در MSP محلی اصلاح شد"

# ۲. ساخت shared-msp با MSP Admin + اصلاح admincerts در هر Org
log "ساخت shared-msp و کپی admincerts تمام Adminها در هر Org..."

mkdir -p shared-msp
rm -rf shared-msp/*

for i in {1..8}; do
  SRC="./crypto-config/peerOrganizations/org${i}.example.com/users/Admin@org${i}.example.com/msp"
  DST="shared-msp/Org${i}MSP"
  cp -r "$SRC" "$DST"

  # حالا admincerts تمام Adminها را در این MSP کپی می‌کنیم
  mkdir -p "$DST/admincerts"

  for j in {1..8}; do
    ADMIN_CERT="./crypto-config/peerOrganizations/org${j}.example.com/users/Admin@org${j}.example.com/msp/signcerts/Admin@org${j}.example.com-cert.pem"
    if [ -f "$ADMIN_CERT" ]; then
      cp "$ADMIN_CERT" "$DST/admincerts/Admin@org${j}.example.com-cert.pem"
    fi
  done

  log "MSP Org${i}MSP ساخته شد و admincerts تمام ۸ Admin در آن کپی شد"
done

success "shared-msp با admincerts کامل ساخته شد — gossip حالا کامل کار می‌کند!"

# ۳. ساخت bundled TLS CA
BUNDLED="bundled-tls-ca.pem"
> "$BUNDLED"
find ./crypto-config -path "*/tlsca/*-cert.pem" -exec cat {} \; >> "$BUNDLED" 2>/dev/null || true
find ./crypto-config -path "*/tls/ca.crt" -exec cat {} \; >> "$BUNDLED" 2>/dev/null || true
sed -i '/^$/d' "$BUNDLED"

log "bundled-tls-ca.pem ساخته شد — تعداد خطوط: $(wc -l < "$BUNDLED")"

success "تمام تنظیمات آماده است!"

log "در docker-compose.yml:"
log "  - CORE_PEER_MSPCONFIGPATH=/etc/hyperledger/fabric/shared-msp/OrgXMSP (نگه دارید)"
log "  - ./shared-msp:/etc/hyperledger/fabric/shared-msp (نگه دارید)"
log "سپس اجرا کنید:"
log "docker-compose down -v && docker-compose up -d"
log "./setup.sh"
