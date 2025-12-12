#!/bin/bash
# create_shared_ca.sh — ساخت پوشه shared-ca و کپی تمام گواهی‌های CA
# این اسکریپت فقط پوشه را می‌سازد — docker-compose را تغییر نمی‌دهد

set -e

PROJECT_DIR="/root/6g-network/config"

log() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] $*"; }
success() { log "موفق: $*"; }

log "شروع ساخت پوشه shared-ca..."

cd "$PROJECT_DIR"

# ساخت پوشه
mkdir -p shared-ca

# پاک کردن محتوای قبلی (اگر وجود داشته باشد)
rm -f shared-ca/*.crt

# کپی تمام ca.crtها از peerOrganizations و ordererOrganizations
find ./crypto-config/peerOrganizations -name "ca.crt" -exec cp {} shared-ca/ \; 2>/dev/null || true
find ./crypto-config/ordererOrganizations -name "ca.crt" -exec cp {} shared-ca/ \; 2>/dev/null || true

# چک تعداد فایل‌ها
CA_COUNT=$(ls -1 shared-ca/*.crt 2>/dev/null | wc -l || echo 0)
log "تعداد ca.crt کپی‌شده: $CA_COUNT (باید ۹ باشد — ۸ Peer + ۱ Orderer)"

if [ $CA_COUNT -ge 8 ]; then
  success "پوشه shared-ca با موفقیت ساخته شد و تمام گواهی‌ها کپی شدند!"
  log "حالا شبکه را دوباره بالا بیاورید:"
  log "cd /root/6g-network/config && docker-compose down -v && docker-compose up -d"
  log "سپس اجرا کنید: cd /root/6g-network/scripts && ./setup.sh"
else
  log "هشدار: تعداد گواهی‌ها کمتر از حد انتظار است — crypto-config را چک کنید"
fi
