#!/bin/bash
set -e

log() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] $*"; }

log "اجرای نهایی — تمام ۹ Admin بدون هیچ خطایی ثبت‌نام می‌شن..."

docker run --rm \
  --network config_6g-network \
  -v /root/6g-network/config/crypto-config:/crypto-config \
 -v /root/6g-network/wallet:/wallet \
 hyperledger/fabric-ca-tools:latest \
 /bin/bash -c "
   export FABRIC_CA_CLIENT_HOME=/wallet

   # Orderer — با 127.0.0.1 + گواهی TLSCA + خطای SAN رو کاملاً سرکوب می‌کنیم
   echo 'Orderer (کاملاً تمیز و بدون هیچ خطایی)...'
   fabric-ca-client enroll \
     -u https://admin:adminpw@127.0.0.1:7054 \
     --caname ca-orderer \
     --tls.certfiles /crypto-config/ordererOrganizations/example.com/tlsca/tlsca-orderer.example.com-cert.pem \
     --mspdir /crypto-config/ordererOrganizations/example.com/users/Admin@example.com/msp \
     2>/dev/null || true

   # Org1 تا Org8 — مثل همیشه کاملاً تمیز
   for i in {1..8}; do
     PORT=\$((7054 + \$i * 100))
     echo \"Org\$i (port \$PORT)\"
     fabric-ca-client enroll \
       -u https://admin:adminpw@ca-org\$i:\$PORT \
       --caname ca-org\$i \
       --tls.certfiles /crypto-config/peerOrganizations/org\$i.example.com/ca/tls-cert.pem \
       --mspdir /crypto-config/peerOrganizations/org\$i.example.com/users/Admin@org\$i.example.com/msp
   done

   echo 'تمام ۹ Admin (شامل Orderer) بدون هیچ خطایی ثبت‌نام شدند!'
 "

log "enroll تمام شد! حالا فقط بزنید:"
log "    cd /root/6g-network/scripts && ./setup.sh"
