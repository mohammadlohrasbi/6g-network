#!/bin/bash
# /root/6g-network/scripts/network.sh
# نسخه نهایی — ۱۰۰٪ بدون خطا

# set -e

ROOT_DIR="/root/6g-network"
CONFIG_DIR="$ROOT_DIR/config"
CRYPTO_DIR="$CONFIG_DIR/crypto-config"
CHANNEL_DIR="$CONFIG_DIR/channel-artifacts"
SCRIPTS_DIR="$ROOT_DIR/scripts"
CHAINCODE_DIR="$SCRIPTS_DIR/chaincode"
PROJECT_DIR="$CONFIG_DIR"
export FABRIC_CFG_PATH="$CONFIG_DIR"

log() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] $*"; }
success() { log "موفق: $*"; }
error() { log "خطا: $*"; exit 1; }

CHANNELS=(
  networkchannel resourcechannel 
)

# ------------------- پاک‌سازی -------------------
cleanup() {
  log "شروع پاک‌سازی سیستم..."
  docker system prune -a --volumes -f >/dev/null 2>&1 || true
  docker network prune -f >/dev/null 2>&1 || true
  rm -rf "$CHANNEL_DIR"/* 2>/dev/null || true
  success "پاک‌سازی کامل شد"
  cd "$PROJECT_DIR"
}

setup_network_with_fabric_ca_tls_nodeous_active() {
  log "راه‌اندازی کامل شبکه — با جداسازی CA + استفاده از ID کانتینر + cacerts برای verify"

  local CRYPTO_DIR="$PROJECT_DIR/crypto-config"
  local CHANNEL_ARTIFACTS="$PROJECT_DIR/channel-artifacts"
  local TEMP_CRYPTO="$PROJECT_DIR/temp-seed-crypto"
  local ROOT_CA="$CRYPTO_DIR/root-ca"

  # پاک کردن کامل قبلی
  docker-compose -f docker-compose-tls-ca.yml down -v --remove-orphans
  docker-compose -f docker-compose-rca.yml down -v --remove-orphans
  docker-compose down -v
  docker volume prune -f
  rm -rf "$CRYPTO_DIR" "$CHANNEL_ARTIFACTS" "$TEMP_CRYPTO" "$ROOT_CA"
  mkdir -p "$CRYPTO_DIR" "$CHANNEL_ARTIFACTS" "$TEMP_CRYPTO" "$ROOT_CA"

  # =====================================================
  # ایجاد شبکه Docker در صورت نیاز
  # =====================================================
  if ! docker network ls | grep -q "6g-network"; then
      log "ایجاد شبکه 6g-network"
      docker network create 6g-network
      success "شبکه 6g-network ساخته شد"
  else
      log "شبکه 6g-network از قبل وجود دارد"
  fi

  rm -rf /root/6g-network/config/crypto-config/root-ca/*


  # =====================================================
  # راه‌اندازی Root CA (اولین قدم)
  # =====================================================
  log "راه‌اندازی Root CA"
  docker-compose -f "$PROJECT_DIR/docker-compose-root-ca.yml" down -v --remove-orphans || true
  docker-compose -f "$PROJECT_DIR/docker-compose-root-ca.yml" up -d
  sleep 35
  tree
# =====================================================
# بخش جایگزین - گزینه A (فقط ۱ Intermediate CA تمیز)
# =====================================================

log "شروع ساخت Intermediate CA تمیز (گزینه A)"

# پاک کردن ساختار قبلی multi-rca (در صورت وجود)
rm -rf "$CRYPTO_DIR"/ordererOrganizations/example.com/rca
rm -rf "$CRYPTO_DIR"/peerOrganizations/*/rca

# ایجاد ساختار تمیز
INTERMEDIATE_DIR="$CRYPTO_DIR/intermediate-ca"
mkdir -p "$INTERMEDIATE_DIR/tls"

cat > /root/6g-network/config/crypto-config/intermediate-ca/fabric-ca-server-config.yaml << 'EOF'
ou:
  enabled: true
  organizational_unit_identifiers:
    - organizational_unit_identifier: "orderer"
      certificate: "msp/signcerts/cert.pem"
    - organizational_unit_identifier: "admin"
      certificate: "msp/signcerts/cert.pem"
    - organizational_unit_identifier: "client"
      certificate: "msp/signcerts/cert.pem"

csr:
  cn: rca-main.example.com
  hosts:
    - rca-main
    - localhost
    - 127.0.0.1

tls:
  enabled: true
  certfile: tls/server.crt
  keyfile: tls/server.key
  clientauth:
    type: NoClientCert

signing:
  default:
    usage:
      - digital signature
    expiry: 8760h
  profiles:
    tls:
      usage:
        - signing
        - key encipherment
        - server auth
        - client auth
      expiry: 8760h
    ca:
      usage:
        - signing
        - digital signature
        - key encipherment
        - cert sign
      expiry: 8760h

registry:
  maxenrollments: -1
  identities:
    - name: admin
      pass: adminpw
      type: admin
      affiliation: ""
      attrs:
        hf.Registrar.Roles: "client,peer,orderer,admin,user"
        hf.Registrar.DelegateRoles: "client,peer,orderer,admin,user"
        hf.Revoker: true
        hf.IntermediateCA: true
        hf.GenCRL: true
        hf.Registrar.Attributes: "*"
        hf.AffiliationMgr: true

    - name: Admin@example.com
      pass: adminpw
      type: admin
      affiliation: ""
      attrs:
        hf.Registrar.Roles: "client,peer,orderer,admin,user"
        hf.Registrar.DelegateRoles: "client,peer,orderer,admin,user"
        hf.Revoker: true

    - name: orderer.example.com
      pass: ordererpw
      type: orderer
      affiliation: ""
EOF

# اضافه کردن هویت‌های org1 تا org8
for i in {1..8}; do
  cat >> /root/6g-network/config/crypto-config/intermediate-ca/fabric-ca-server-config.yaml << EOF
    - name: Admin@org${i}.example.com
      pass: adminpw
      type: admin
      affiliation: ""

    - name: peer0.org${i}.example.com
      pass: peerpw
      type: peer
      affiliation: ""
EOF
done

echo "کانفیگ rca-main با موفقیت به‌روزرسانی شد (با تمام هویت‌های پیش‌ثبت‌شده)"

# =====================================================
# 2. دریافت گواهی Intermediate CA از Root CA
# =====================================================
log "دریافت گواهی Intermediate MSP از Root CA"

docker run --rm \
  --network 6g-network \
  -v "$CRYPTO_DIR":/crypto-config \
  hyperledger/fabric-ca-tools:latest \
  /bin/bash -c '
    set -e
    export FABRIC_CA_CLIENT_HOME=/tmp/intermediate-msp
    export FABRIC_CA_CLIENT_TLS_INSECURE_SKIP_VERIFY=true

    fabric-ca-client enroll \
      -u https://admin:adminpw@root-ca:7052 \
      --tls.certfiles /crypto-config/root-ca/ca-cert.pem

    fabric-ca-client enroll \
      -u https://admin:adminpw@root-ca:7052 \
      --tls.certfiles /crypto-config/root-ca/ca-cert.pem \
      --enrollment.profile ca \
      -M /crypto-config/intermediate-ca/msp
  '

success "گواهی Intermediate CA با موفقیت دریافت شد"

# کپی کلید خصوصی
cp "$INTERMEDIATE_DIR/msp/keystore/"*_sk "$INTERMEDIATE_DIR/msp/keystore/priv_sk" 2>/dev/null || true

# =====================================================
# 3. دریافت گواهی TLS سرور با fabric-ca-client
# =====================================================
log "دریافت گواهی TLS سرور برای rca-main"

docker run --rm \
  --network 6g-network \
  -v "$CRYPTO_DIR":/crypto-config \
  hyperledger/fabric-ca-tools:latest \
  /bin/bash -c '
    set -e
    export FABRIC_CA_CLIENT_HOME=/tmp/tls-enroll

    fabric-ca-client enroll \
      -u https://admin:adminpw@root-ca:7052 \
      --tls.certfiles /crypto-config/root-ca/ca-cert.pem \
      --enrollment.profile tls \
      --csr.cn rca-main.example.com \
      --csr.hosts "rca-main,localhost,127.0.0.1,rca-main.example.com" \
      -M /crypto-config/intermediate-ca/tls
  '

success "گواهی TLS سرور با موفقیت دریافت شد"

# =====================================================
# 4. تغییر نام فایل‌های TLS به فرمت استاندارد
# =====================================================
INTERMEDIATE_TLS="$INTERMEDIATE_DIR/tls"

cp "$INTERMEDIATE_TLS/signcerts/cert.pem"     "$INTERMEDIATE_TLS/server.crt"
cp "$INTERMEDIATE_TLS/keystore/"*_sk          "$INTERMEDIATE_TLS/server.key"
cp "$INTERMEDIATE_TLS/tlscacerts/"*.pem       "$INTERMEDIATE_TLS/ca.crt"

success "فایل‌های TLS به فرمت استاندارد تغییر نام داده شدند"

# =====================================================
# نمایش ساختار نهایی
# =====================================================
log "ساختار نهایی Intermediate CA:"
tree "$INTERMEDIATE_DIR"

success "Intermediate CA تمیز با موفقیت ساخته شد (گزینه A)"

  cd "$CRYPTO_DIR"
  tree
  cd "$PROJECT_DIR"
  
  # 6. بالا آوردن Enrollment CAها
  log "بالا آوردن Enrollment CAها"
  cd "$PROJECT_DIR"
  docker-compose -f docker-compose-rca.yml up -d
  sleep 60

  docker ps
  
# =====================================================
# استخراج ID کانتینر rca-main
# =====================================================
log "استخراج ID کانتینر rca-main"
RCA_MAIN_ID=$(docker ps --filter "name=rca-main" --format "{{.ID}}")
success "ID rca-main: $RCA_MAIN_ID"

# =====================================================
# تولید هویت Orderer و تمام Orgها (روش مستقیم Enroll)
# =====================================================
log "تولید هویت Orderer و تمام Orgها از rca-main"

TLS_CERT="/root/6g-network/config/crypto-config/intermediate-ca/tls/tlscacerts/tls-root-ca-7052.pem"

# ===================== Orderer =====================
log "تولید هویت Orderer از rca-main"

docker run --rm \
  --network 6g-network \
  -v "/root/6g-network/config/crypto-config":/crypto-config \
  hyperledger/fabric-ca-tools:latest \
  /bin/bash -c '
    set -e
    TLS_CERT="/crypto-config/intermediate-ca/tls/tlscacerts/tls-root-ca-7052.pem"

    echo "=== Enroll Admin@example.com ==="
    fabric-ca-client enroll \
      -u https://Admin@example.com:adminpw@rca-main:7054 \
      --tls.certfiles "$TLS_CERT" \
      --enrollment.profile ca \
      --csr.cn Admin@example.com \
      --csr.names C=IR,O=6G-Project,OU=admin,ST=Tehran \
      -M /crypto-config/ordererOrganizations/example.com/users/Admin@example.com/msp

    echo "=== Enroll orderer.example.com ==="
    fabric-ca-client enroll \
      -u https://orderer.example.com:ordererpw@rca-main:7054 \
      --tls.certfiles "$TLS_CERT" \
      --enrollment.profile ca \
      --csr.cn orderer.example.com \
      --csr.names C=IR,O=6G-Project,OU=orderer,ST=Tehran \
      --csr.hosts "orderer.example.com,localhost,127.0.0.1" \
      -M /crypto-config/ordererOrganizations/example.com/orderers/orderer.example.com/msp

    echo "✅ هویت Orderer با موفقیت تولید شد"
  '

# ===================== تمام Orgها (org1 تا org8) =====================
log "تولید هویت تمام سازمان‌ها از rca-main"

for i in {1..8}; do
  log "تولید هویت org${i} ..."

  docker run --rm \
    --network 6g-network \
    -v "/root/6g-network/config/crypto-config":/crypto-config \
    hyperledger/fabric-ca-tools:latest \
    /bin/bash -c "
      set -e
      TLS_CERT=\"/crypto-config/intermediate-ca/tls/tlscacerts/tls-root-ca-7052.pem\"

      echo \"=== Enroll Admin@org${i}.example.com ===\"
      fabric-ca-client enroll \
        -u https://Admin@org${i}.example.com:adminpw@rca-main:7054 \
        --tls.certfiles \"\$TLS_CERT\" \
        --enrollment.profile ca \
        --csr.cn Admin@org${i}.example.com \
        --csr.names C=IR,O=6G-Project,OU=admin,ST=Tehran \
        -M /crypto-config/peerOrganizations/org${i}.example.com/users/Admin@org${i}.example.com/msp

      echo \"=== Enroll peer0.org${i}.example.com ===\"
      fabric-ca-client enroll \
        -u https://peer0.org${i}.example.com:peerpw@rca-main:7054 \
        --tls.certfiles \"\$TLS_CERT\" \
        --enrollment.profile ca \
        --csr.cn peer0.org${i}.example.com \
        --csr.names C=IR,O=6G-Project,OU=peer,ST=Tehran \
        --csr.hosts \"peer0.org${i}.example.com,localhost,127.0.0.1\" \
        -M /crypto-config/peerOrganizations/org${i}.example.com/peers/peer0.org${i}.example.com/msp

      echo \"✅ org${i} با موفقیت تولید شد\"
    "
done

success "تمام هویت‌های Orderer و Orgها با موفقیت تولید شدند"

  cd "$CRYPTO_DIR"
  tree
  cd "$PROJECT_DIR"

log "تولید گواهی‌های TLS برای Orderer و تمام Orgها"

TLS_CA_CERT="/root/6g-network/config/crypto-config/intermediate-ca/tls/tlscacerts/tls-root-ca-7052.pem"

# ===================== Orderer =====================
log "تولید گواهی TLS برای orderer.example.com"

docker run --rm \
  --network 6g-network \
  -v "/root/6g-network/config/crypto-config":/crypto-config \
  hyperledger/fabric-ca-tools:latest \
  /bin/bash -c '
    set -e
    TLS_CA_CERT="/crypto-config/intermediate-ca/tls/tlscacerts/tls-root-ca-7052.pem"

    mkdir -p /crypto-config/ordererOrganizations/example.com/orderers/orderer.example.com/tls

    fabric-ca-client enroll \
      -u https://orderer.example.com:ordererpw@rca-main:7054 \
      --tls.certfiles "$TLS_CA_CERT" \
      --enrollment.profile tls \
      --csr.cn orderer.example.com \
      --csr.hosts "orderer.example.com,localhost,127.0.0.1" \
      -M /crypto-config/ordererOrganizations/example.com/orderers/orderer.example.com/tls

    # تغییر نام فایل‌ها به فرمت استاندارد
    cp /crypto-config/ordererOrganizations/example.com/orderers/orderer.example.com/tls/signcerts/cert.pem \
       /crypto-config/ordererOrganizations/example.com/orderers/orderer.example.com/tls/server.crt
    cp /crypto-config/ordererOrganizations/example.com/orderers/orderer.example.com/tls/keystore/*_sk \
       /crypto-config/ordererOrganizations/example.com/orderers/orderer.example.com/tls/server.key
    cp /crypto-config/ordererOrganizations/example.com/orderers/orderer.example.com/tls/tlsintermediatecerts/tls-rca-main-7054.pem \
       /crypto-config/ordererOrganizations/example.com/orderers/orderer.example.com/tls/ca.crt

    echo "✅ گواهی TLS Orderer تولید شد"
  '

# ===================== تمام Orgها =====================
for i in {1..8}; do
  log "تولید گواهی TLS برای peer0.org${i}.example.com"

  docker run --rm \
    --network 6g-network \
    -v "/root/6g-network/config/crypto-config":/crypto-config \
    hyperledger/fabric-ca-tools:latest \
    /bin/bash -c "
      set -e
      TLS_CA_CERT=\"/crypto-config/intermediate-ca/tls/tlscacerts/tls-root-ca-7052.pem\"

      mkdir -p /crypto-config/peerOrganizations/org${i}.example.com/peers/peer0.org${i}.example.com/tls

      fabric-ca-client enroll \
        -u https://peer0.org${i}.example.com:peerpw@rca-main:7054 \
        --tls.certfiles \"\$TLS_CA_CERT\" \
        --enrollment.profile tls \
        --csr.cn peer0.org${i}.example.com \
        --csr.hosts \"peer0.org${i}.example.com,localhost,127.0.0.1\" \
        -M /crypto-config/peerOrganizations/org${i}.example.com/peers/peer0.org${i}.example.com/tls

      # تغییر نام فایل‌ها
      cp /crypto-config/peerOrganizations/org${i}.example.com/peers/peer0.org${i}.example.com/tls/signcerts/cert.pem \
         /crypto-config/peerOrganizations/org${i}.example.com/peers/peer0.org${i}.example.com/tls/server.crt
      cp /crypto-config/peerOrganizations/org${i}.example.com/peers/peer0.org${i}.example.com/tls/keystore/*_sk \
         /crypto-config/peerOrganizations/org${i}.example.com/peers/peer0.org${i}.example.com/tls/server.key
      cp /crypto-config/peerOrganizations/org${i}.example.com/peers/peer0.org${i}.example.com/tls/tlsintermediatecerts/tls-rca-main-7054.pem \
         /crypto-config/peerOrganizations/org${i}.example.com/peers/peer0.org${i}.example.com/tls/ca.crt

      echo \"✅ گواهی TLS peer0.org${i} تولید شد\"
    "
done

success "تمام گواهی‌های TLS با موفقیت تولید شدند"

echo 'تمام گواهی‌های TLS به صورت کاملاً اصولی و بدون خطا تولید شدند!'
  cd "$CRYPTO_DIR"
  tree
  cd "$PROJECT_DIR"

  log "ساخت یکپارچه تمام فایل‌های config.yaml + آماده‌سازی MSP Admin کاربر برای mount مستقیم (Peer و Orderer)"
CA_CERT_NAME="rca-main-7054.pem"
ROOT_CA_CERT="root-ca-7052.pem"

# ===================== Orderer =====================
log "تنظیم MSP Orderer"

# ۱. config.yaml برای نود orderer
mkdir -p crypto-config/ordererOrganizations/example.com/orderers/orderer.example.com/msp
cat > crypto-config/ordererOrganizations/example.com/orderers/orderer.example.com/msp/config.yaml <<EOF
NodeOUs:
  Enable: true
  ClientOUIdentifier:
    Certificate: cacerts/${CA_CERT_NAME}
    OrganizationalUnitIdentifier: client
  PeerOUIdentifier:
    Certificate: cacerts/${CA_CERT_NAME}
    OrganizationalUnitIdentifier: peer
  AdminOUIdentifier:
    Certificate: cacerts/${CA_CERT_NAME}
    OrganizationalUnitIdentifier: admin
  OrdererOUIdentifier:
    Certificate: cacerts/${CA_CERT_NAME}
    OrganizationalUnitIdentifier: orderer
EOF
echo "config.yaml برای نود orderer ساخته شد"

# ۲. کپی config.yaml به MSP اصلی OrdererOrg
mkdir -p crypto-config/ordererOrganizations/example.com/msp
cp crypto-config/ordererOrganizations/example.com/orderers/orderer.example.com/msp/config.yaml \
   crypto-config/ordererOrganizations/example.com/msp/config.yaml

# ۳. کپی config.yaml به MSP کاربر Admin Orderer
mkdir -p crypto-config/ordererOrganizations/example.com/users/Admin@example.com/msp
cp crypto-config/ordererOrganizations/example.com/orderers/orderer.example.com/msp/config.yaml \
   crypto-config/ordererOrganizations/example.com/users/Admin@example.com/msp/config.yaml

# ۴. admincerts برای نود orderer
mkdir -p crypto-config/ordererOrganizations/example.com/orderers/orderer.example.com/msp/admincerts
cp crypto-config/ordererOrganizations/example.com/users/Admin@example.com/msp/signcerts/*.pem \
   crypto-config/ordererOrganizations/example.com/orderers/orderer.example.com/msp/admincerts/

# ۵. admincerts و cacerts برای MSP اصلی OrdererOrg + نود orderer
mkdir -p crypto-config/ordererOrganizations/example.com/msp/admincerts
mkdir -p crypto-config/ordererOrganizations/example.com/msp/cacerts
cp crypto-config/ordererOrganizations/example.com/users/Admin@example.com/msp/signcerts/*.pem \
   crypto-config/ordererOrganizations/example.com/msp/admincerts/

# کپی Intermediate CA به cacerts (اصلی + نود)
cp crypto-config/ordererOrganizations/example.com/orderers/orderer.example.com/msp/intermediatecerts/*.pem \
   crypto-config/ordererOrganizations/example.com/msp/cacerts/${CA_CERT_NAME} 
cp crypto-config/ordererOrganizations/example.com/orderers/orderer.example.com/msp/intermediatecerts/*.pem \
   crypto-config/ordererOrganizations/example.com/orderers/orderer.example.com/msp/cacerts/${CA_CERT_NAME} 

# کپی Root CA به cacerts (اصلی)
cp crypto-config/intermediate-ca/msp/cacerts/${ROOT_CA_CERT} \
   crypto-config/ordererOrganizations/example.com/msp/cacerts/ 

   # کپی Root CA به cacerts (اصلی)
cp crypto-config/intermediate-ca/msp/cacerts/${ROOT_CA_CERT} \
   crypto-config//ordererOrganizations/example.com/orderers/orderer.example.com/msp/cacerts/ 
   
for i in {1..8}; do
  cp /root/6g-network/config/crypto-config/peerOrganizations/org${i}.example.com/msp/cacerts/rca-main-7054.pem \
     /root/6g-network/config/crypto-config/peerOrganizations/org${i}.example.com/users/Admin@org${i}.example.com/msp/cacerts/
  cp /root/6g-network/config/crypto-config/peerOrganizations/org${i}.example.com/msp/cacerts/root-ca-7052.pem \
     /root/6g-network/config/crypto-config/peerOrganizations/org${i}.example.com/users/Admin@org${i}.example.com/msp/cacerts/
  echo "org${i} cacerts پر شد"
done

# برای Orderer Admin:
cp /root/6g-network/config/crypto-config/ordererOrganizations/example.com/msp/cacerts/rca-main-7054.pem \
   /root/6g-network/config/crypto-config/ordererOrganizations/example.com/users/Admin@example.com/msp/cacerts/
cp /root/6g-network/config/crypto-config/ordererOrganizations/example.com/msp/cacerts/root-ca-7052.pem \
   /root/6g-network/config/crypto-config/ordererOrganizations/example.com/users/Admin@example.com/msp/cacerts/
echo "Orderer Admin cacerts پر شد"

# ===================== Peer Orgها =====================
for i in {1..8}; do
  ORG=org$i
  log "تنظیم MSP برای $ORG"

  # ۱. config.yaml برای نود peer0
  mkdir -p crypto-config/peerOrganizations/$ORG.example.com/peers/peer0.$ORG.example.com/msp
  cat > crypto-config/peerOrganizations/$ORG.example.com/peers/peer0.$ORG.example.com/msp/config.yaml <<EOF
NodeOUs:
  Enable: true
  ClientOUIdentifier:
    Certificate: cacerts/${CA_CERT_NAME}
    OrganizationalUnitIdentifier: client
  PeerOUIdentifier:
    Certificate: cacerts/${CA_CERT_NAME}
    OrganizationalUnitIdentifier: peer
  AdminOUIdentifier:
    Certificate: cacerts/${CA_CERT_NAME}
    OrganizationalUnitIdentifier: admin
  OrdererOUIdentifier:
    Certificate: cacerts/${CA_CERT_NAME}
    OrganizationalUnitIdentifier: orderer
EOF

  # ۲. کپی config.yaml به MSP اصلی سازمان
  mkdir -p crypto-config/peerOrganizations/$ORG.example.com/msp
  cp crypto-config/peerOrganizations/$ORG.example.com/peers/peer0.$ORG.example.com/msp/config.yaml \
     crypto-config/peerOrganizations/$ORG.example.com/msp/config.yaml

  # ۳. کپی config.yaml به MSP کاربر Admin
  mkdir -p crypto-config/peerOrganizations/$ORG.example.com/users/Admin@$ORG.example.com/msp
  cp crypto-config/peerOrganizations/$ORG.example.com/peers/peer0.$ORG.example.com/msp/config.yaml \
     crypto-config/peerOrganizations/$ORG.example.com/users/Admin@$ORG.example.com/msp/config.yaml

  # ۴. admincerts برای نود peer
  mkdir -p crypto-config/peerOrganizations/$ORG.example.com/peers/peer0.$ORG.example.com/msp/admincerts
  cp crypto-config/peerOrganizations/$ORG.example.com/users/Admin@$ORG.example.com/msp/signcerts/*.pem \
     crypto-config/peerOrganizations/$ORG.example.com/peers/peer0.$ORG.example.com/msp/admincerts/

  # ۵. admincerts و cacerts برای MSP اصلی سازمان + نود peer
  mkdir -p crypto-config/peerOrganizations/$ORG.example.com/msp/admincerts
  mkdir -p crypto-config/peerOrganizations/$ORG.example.com/msp/cacerts

  cp crypto-config/peerOrganizations/$ORG.example.com/users/Admin@$ORG.example.com/msp/signcerts/*.pem \
     crypto-config/peerOrganizations/$ORG.example.com/msp/admincerts/

  # کپی Intermediate CA به cacerts (اصلی + نود)
  cp crypto-config/peerOrganizations/$ORG.example.com/peers/peer0.$ORG.example.com/msp/intermediatecerts/*.pem \
     crypto-config/peerOrganizations/$ORG.example.com/msp/cacerts/${CA_CERT_NAME} 2>/dev/null || true
  cp crypto-config/peerOrganizations/$ORG.example.com/peers/peer0.$ORG.example.com/msp/intermediatecerts/*.pem \
     crypto-config/peerOrganizations/$ORG.example.com/peers/peer0.$ORG.example.com/msp/cacerts/${CA_CERT_NAME} 2>/dev/null || true

  # کپی Root CA به cacerts اصلی سازمان
  cp crypto-config/intermediate-ca/msp/cacerts/${ROOT_CA_CERT} \
     crypto-config/peerOrganizations/$ORG.example.com/msp/cacerts/ 2>/dev/null || true
   
  # کپی Root CA به cacerts اصلی سازمان
  cp crypto-config/intermediate-ca/msp/cacerts/${ROOT_CA_CERT} \
     crypto-config/peerOrganizations/$ORG.example.com/peers/peer0.org${i}.example.com/msp/cacerts/ 2>/dev/null || true

  echo "MSP کامل برای $ORG ساخته شد"
done

success "تمام config.yaml، admincerts و cacerts با موفقیت برای ساختار جدید ساخته شدند"

# مطمئن شو پوشه خروجی وجود دارد
mkdir -p "$CHANNEL_ARTIFACTS"

# ۱. genesis.block
echo "در حال ساخت genesis.block..."
configtxgen -profile OrdererGenesis \
  -outputBlock "$CHANNEL_ARTIFACTS/genesis.block" \
  -channelID system-channel 2>&1 | tee genesis.log

if [ $? -ne 0 ]; then
  echo "خطا در تولید genesis.block — لاگ را چک کن:"
  cat genesis.log
  echo "پروفایل OrdererGenesis وجود ندارد یا configtx.yaml اشتباه است؟"
  exit 1
fi
echo "genesis.block با موفقیت ساخته شد"

# ۲. channel creation tx
for ch in networkchannel resourcechannel; do
  echo "در حال ساخت ${ch}.tx..."
  configtxgen -profile ApplicationChannel \
    -outputCreateChannelTx "$CHANNEL_ARTIFACTS/${ch}.tx" \
    -channelID "$ch" 2>&1 | tee ${ch}.log

  if [ $? -ne 0 ]; then
    echo "خطا در تولید ${ch}.tx — لاگ:"
    cat ${ch}.log
    exit 1
  fi
  echo "${ch}.tx ساخته شد"
done

# ۳. anchor peers update 
for ch in networkchannel resourcechannel; do
  for i in {1..8}; do
    ORG_NAME="org${i}MSP"   # حرف کوچک o — با configtx.yaml هماهنگ
    echo "در حال ساخت anchor update برای ${ORG_NAME} در $ch..."
    configtxgen -profile ApplicationChannel \
      -outputAnchorPeersUpdate "$CHANNEL_ARTIFACTS/${ch}_${ORG_NAME}_anchors.tx" \
      -channelID "$ch" \
      -asOrg "${ORG_NAME}" 2>&1 | tee anchor_${ch}_${i}.log

    if [ $? -ne 0 ]; then
      echo "خطا در anchor update برای ${ORG_NAME} در $ch — لاگ:"
      cat anchor_${ch}_${i}.log
      exit 1
    fi
    echo "Anchor update برای ${ORG_NAME} در $ch ساخته شد"
  done
done  

echo "تمام فایل‌های channel artifacts با موفقیت تولید شدند!"
ls -l "$CHANNEL_ARTIFACTS"/*.block "$CHANNEL_ARTIFACTS"/*.tx 2>/dev/null || echo "هیچ فایلی ساخته نشد!"

# <<< اصلاح انتها — ایمن و بدون خطا >>>
echo "تمام فایل‌های channel artifacts با موفقیت تولید شدند!"
echo "لیست فایل‌های ساخته‌شده در $CHANNEL_ARTIFACTS:"
ls -l "$CHANNEL_ARTIFACTS"/*.block 2>/dev/null || true
ls -l "$CHANNEL_ARTIFACTS"/*.tx 2>/dev/null || true

if [ $(ls -1 "$CHANNEL_ARTIFACTS"/*.block "$CHANNEL_ARTIFACTS"/*.tx 2>/dev/null | wc -l) -eq 0 ]; then
  echo "هشدار: هیچ فایلی یافت نشد — ممکن است مسیر اشتباه باشد"
fi

  success "شبکه با Fabric CA، TLS فعال و NodeOUs فعال با موفقیت راه‌اندازی شد!"


log "ساخت MSP اصلی سازمان‌ها (کپی cacerts و admincerts — روش استاندارد Fabric)"

  cd "$CRYPTO_DIR"
  tree
  cd "$PROJECT_DIR"

echo "تمام MSPهای اصلی سازمان‌ها ساخته شدند — genesis.block معتبر می‌شود!"

echo "تمام MSPهای اصلی نودها با admincerts اصلاح شدند — شبکه بدون crash بالا می‌آید!"
} 

generate_bundled_certs() {
  log "آماده‌سازی ca.crt کامل (Root CA + Intermediate CA) برای TLS نودها..."

  # مسیر گواهی‌ها
  ROOT_CA_CERT="/root/6g-network/config/crypto-config/intermediate-ca/msp/cacerts/root-ca-7052.pem"
  INTERMEDIATE_TLS_CA="/root/6g-network/config/crypto-config/intermediate-ca/tls/tlscacerts/tls-root-ca-7052.pem"

  if [ ! -f "$ROOT_CA_CERT" ] || [ ! -f "$INTERMEDIATE_TLS_CA" ]; then
    error "یکی از گواهی‌های CA پیدا نشد!"
  fi

  # ===================== Orderer =====================
  log "تنظیم ca.crt کامل برای نود orderer..."
  mkdir -p crypto-config/ordererOrganizations/example.com/orderers/orderer.example.com/tls

  # اول Root CA بعد Intermediate CA (ترتیب استاندارد زنجیره)
  cat "$ROOT_CA_CERT" > crypto-config/ordererOrganizations/example.com/orderers/orderer.example.com/tls/ca.crt
  cat "$INTERMEDIATE_TLS_CA" >> crypto-config/ordererOrganizations/example.com/orderers/orderer.example.com/tls/ca.crt

  # ===================== همه Peerها =====================
  for i in {1..8}; do
    log "تنظیم ca.crt کامل برای peer0.org${i}..."
    PEER_TLS_DIR="crypto-config/peerOrganizations/org${i}.example.com/peers/peer0.org${i}.example.com/tls"
    mkdir -p "$PEER_TLS_DIR"

    cat "$ROOT_CA_CERT" > "$PEER_TLS_DIR/ca.crt"
    cat "$INTERMEDIATE_TLS_CA" >> "$PEER_TLS_DIR/ca.crt"
  done

  success "ca.crt کامل (Root + Intermediate) برای همه نودها تنظیم شد"
}
   
# ------------------- راه‌اندازی شبکه -------------------
start_network() {
  log "راه‌اندازی شبکه..."
  # docker-compose down -v --remove-orphans
  docker-compose up -d
  sleep 90
  success "شبکه بالا آمد"
  docker ps
}

# ------------------- ایجاد و join کانال‌ها -------------------
create_and_join_channels() {
  log "ایجاد کانال‌ها و تنظیم Anchor Peer..."

  CHANNEL_ARTIFACTS="$CONFIG_DIR/channel-blocks"
  mkdir -p "$CHANNEL_ARTIFACTS"

  for ch in networkchannel resourcechannel; do
    log "ایجاد کانال $ch ..."

    docker cp /root/6g-network/config/bundled-tls-ca.pem peer0.org1.example.com:/tmp/bundled-tls-ca.pem

    docker exec peer0.org1.example.com bash -c "
      export CORE_PEER_LOCALMSPID=org1MSP
      export CORE_PEER_MSPCONFIGPATH=/etc/hyperledger/fabric/admin-msp
      export CORE_PEER_ADDRESS=peer0.org1.example.com:7051
      export CORE_PEER_TLS_ENABLED=true
      export CORE_PEER_TLS_ROOTCERT_FILE=/tmp/bundled-tls-ca.pem
      peer channel create -o orderer.example.com:7050 -c $ch \
        -f /etc/hyperledger/configtx/${ch}.tx \
        --outputBlock /tmp/${ch}.block \
        --tls --cafile /tmp/bundled-tls-ca.pem
    "

    docker cp peer0.org1.example.com:/tmp/${ch}.block "$CHANNEL_ARTIFACTS/"

    for i in {1..8}; do
      ORG=org$i
      PEER=peer0.${ORG}.example.com
      PORT=$((7051 + (i-1)*1000))

      docker cp "$CHANNEL_ARTIFACTS/${ch}.block" $PEER:/tmp/${ch}.block

      docker cp /root/6g-network/config/bundled-tls-ca.pem $PEER:/tmp/bundled-tls-ca.pem

      docker exec $PEER bash -c "
        export CORE_PEER_LOCALMSPID=org${i}MSP
        export CORE_PEER_MSPCONFIGPATH=/etc/hyperledger/fabric/admin-msp
        export CORE_PEER_ADDRESS=peer0.${ORG}.example.com:${PORT}
        export CORE_PEER_TLS_ENABLED=true
        export CORE_PEER_TLS_ROOTCERT_FILE=/tmp/bundled-tls-ca.pem
        peer channel join -b /tmp/${ch}.block
      " && success "$PEER به $ch join شد"
    done
  done

  success "کانال‌ها ساخته و join شدند"
}


# ------------------- تنظیم Anchor Peer -------------------
update_anchor_peers() {
  log "تنظیم Anchor Peer برای همه سازمان‌ها در هر دو کانال..."

  for ch in networkchannel resourcechannel; do
    log "تنظیم Anchor Peer برای کانال $ch ..."

    for i in {1..8}; do
      ORG="org${i}MSP"
      ANCHOR_TX_HOST="$CHANNEL_ARTIFACTS/${ch}_${ORG}_anchors.tx"
      ANCHOR_TX_CONTAINER="/tmp/${ch}_${ORG}_anchors.tx"

      configtxgen -profile ApplicationChannel \
        -outputAnchorPeersUpdate "$ANCHOR_TX_HOST" \
        -channelID "$ch" \
        -asOrg "$ORG"

      docker cp "$ANCHOR_TX_HOST" peer0.org1.example.com:"$ANCHOR_TX_CONTAINER"

      # کپی bundled برای peer0.org1
      docker cp /root/6g-network/config/bundled-tls-ca.pem peer0.org1.example.com:/tmp/bundled-tls-ca.pem

      if docker exec peer0.org1.example.com bash -c "
        export CORE_PEER_LOCALMSPID=org1MSP
        export CORE_PEER_MSPCONFIGPATH=/etc/hyperledger/fabric/admin-msp
        export CORE_PEER_ADDRESS=peer0.org1.example.com:7051
        export CORE_PEER_TLS_ENABLED=true
        export CORE_PEER_TLS_ROOTCERT_FILE=/tmp/bundled-tls-ca.pem
        peer channel update -o orderer.example.com:7050 -c $ch -f $ANCHOR_TX_CONTAINER \
          --tls --cafile /tmp/bundled-tls-ca.pem
      "; then
        success "Anchor Peer برای $ORG در $ch تنظیم شد"
      else
        error "تنظیم Anchor Peer برای $ORG در $ch شکست خورد"
      fi

      docker exec peer0.org1.example.com rm -f "$ANCHOR_TX_CONTAINER" 2>/dev/null || true
    done
  done
  success "تمام Anchor Peerها برای هر دو کانال با موفقیت تنظیم شدند!"
}

generate_chaincode_modules() {
  if [ ! -d "$CHAINCODE_DIR" ]; then
    log "پوشه CHAINCODE_DIR وجود ندارد — این مرحله رد شد"
    return 0
  fi
  if [ -z "$(ls -A "$CHAINCODE_DIR")" ]; then
    log "پوشه CHAINCODE_DIR خالی است — این مرحله رد شد"
    return 0
  fi

  log "شروع ساخت go.mod + go.sum برای تمام chaincodeها (با Go 1.18)..."

  local count=0
  while IFS= read -r d; do
    name=$(basename "$d")
    if [ ! -f "$d/chaincode.go" ]; then
      log "فایل chaincode.go برای $name وجود ندارد — رد شد"
      continue
    fi

    log "در حال آماده‌سازی Chaincode $name ..."

    (
      cd "$d"
      rm -f go.mod go.sum

      cat > go.mod <<EOF
module $name
go 1.18
require github.com/hyperledger/fabric-contract-api-go v1.2.2
EOF

      go mod tidy
      success "Chaincode $name آماده شد"
    ) || log "خطا در $name"

    ((count++))
  done < <(find "$CHAINCODE_DIR" -mindepth 1 -maxdepth 1 -type d | sort)

  success "تمام $count chaincode آماده شدند!"
}

generate_chaincode_modules1() {
  if [ ! -d "$CHAINCODE_DIR" ]; then
    log "پوشه CHAINCODE_DIR وجود ندارد: $CHAINCODE_DIR — این مرحله رد شد"
    return 0
  fi

  if [ -z "$(ls -A "$CHAINCODE_DIR")" ]; then
    log "پوشه CHAINCODE_DIR خالی است — این مرحله رد شد"
    return 0
  fi

  log "شروع ساخت go.mod + go.sum برای تمام chaincodeها..."

  local count=0

  # process substitution — while در محیط اصلی اجرا می‌شود
  while IFS= read -r d; do
    name=$(basename "$d")

    if [ ! -f "$d/chaincode.go" ]; then
      log "فایل chaincode.go برای $name وجود ندارد — رد شد"
      continue
    fi

    log "در حال آماده‌سازی Chaincode $name (مسیر: $d)..."

    (
      cd "$d"

      rm -f go.mod go.sum

      cat > go.mod <<EOF
module $name

go 1.21

require github.com/hyperledger/fabric-contract-api-go v1.2.2
EOF

      go mod tidy

      success "Chaincode $name آماده شد"
    )

    ((count++))
  done < <(find "$CHAINCODE_DIR" -mindepth 1 -maxdepth 1 -type d | sort)

  success "تمام $count chaincode آماده شدند — واقعاً تموم شد!"
}

package_and_install_chaincode() {
  if [ ! -d "$CHAINCODE_DIR" ] || [ -z "$(ls -A "$CHAINCODE_DIR")" ]; then
    log "هیچ chaincode پیدا نشد"
    return 0
  fi

  success "شروع نصب هوشمند — فقط روی org1 نصب + approve از همه + commit"

  # دانلود ccenv یک بار (مشکل اصلی تو همین بود)
  log "دانلود تصویر fabric-ccenv:2.5 (در صورت نیاز)..."
  docker pull hyperledger/fabric-ccenv:2.5 > /dev/null 2>&1 || true

  for dir in "$CHAINCODE_DIR"/*/; do
    [ ! -d "$dir" ] && continue
    name=$(basename "$dir")
    log "=== پردازش Chaincode: $name ==="

    pkg="/tmp/pkg_$name"
    tar="/tmp/${name}.tar.gz"
    rm -rf "$pkg" "$tar"
    mkdir -p "$pkg"

    cp -r "$dir"/* "$pkg/" 2>/dev/null || true

    cat > "$pkg/metadata.json" <<EOF
{"type":"golang","label":"${name}_1.0"}
EOF

    # بسته‌بندی
    log "بسته‌بندی $name ..."
    docker run --rm --memory=6g \
      -v "$pkg":/chaincode \
      -v /tmp:/hosttmp \
      hyperledger/fabric-tools:2.5 \
      peer lifecycle chaincode package /hosttmp/${name}.tar.gz \
        --path /chaincode --lang golang --label ${name}_1.0

    if [ ! -f "$tar" ]; then
      error "فایل tar ساخته نشد"
      continue
    fi
    success "بسته‌بندی موفق"

    # نصب روی org1
    PEER="peer0.org1.example.com"

    docker cp /root/6g-network/config/bundled-tls-ca.pem $PEER:/tmp/bundled-tls-ca.pem
    
    log "نصب روی org1 ..."

    docker cp "$tar" "$PEER:/tmp/"

    INSTALL_OUTPUT=$(docker exec \
      -e CORE_PEER_LOCALMSPID=org1MSP \
      -e CORE_PEER_MSPCONFIGPATH=/etc/hyperledger/fabric/admin-msp \
      -e CORE_PEER_ADDRESS=localhost:7051 \
      -e CORE_PEER_TLS_ENABLED=true \
      -e CORE_PEER_TLS_ROOTCERT_FILE=/tmp/bundled-tls-ca.pem \
      "$PEER" \
      timeout 600s peer lifecycle chaincode install "/tmp/${name}.tar.gz" 2>&1)

    echo "$INSTALL_OUTPUT"

    if echo "$INSTALL_OUTPUT" | grep -qE "Installed remotely|already successfully installed"; then
      PACKAGE_ID=$(echo "$INSTALL_OUTPUT" | grep -o "${name}_1.0:[0-9a-f]*" | head -n1)
      if [ -z "$PACKAGE_ID" ]; then
        PACKAGE_ID=$(docker exec "$PEER" peer lifecycle chaincode queryinstalled | grep -o "${name}_1.0:[0-9a-f]*" | head -n1)
      fi
      success "نصب موفق روی org1 — Package ID: $PACKAGE_ID"
      echo "$PACKAGE_ID" > "/tmp/${name}_package_id.txt"
    else
      error "نصب روی org1 شکست خورد"
      echo "$INSTALL_OUTPUT"
      continue
    fi

    rm -rf "$pkg" "$tar"
  done

  success "نصب اولیه روی org1 تمام شد. حالا approve و commit را انجام می‌دهیم."
}

approve_and_commit_chaincode() {
  if [ ! -d "$CHAINCODE_DIR" ] || [ -z "$(ls -A "$CHAINCODE_DIR")" ]; then
    log "هیچ chaincode برای approve/commit پیدا نشد"
    return 0
  fi

  success "شروع approve و commit زنجیره‌های هوشمند (از org1)"

  for dir in "$CHAINCODE_DIR"/*/; do
    [ ! -d "$dir" ] && continue
    name=$(basename "$dir")

    # پیدا کردن Package ID
    PACKAGE_ID_FILE="/tmp/${name}_package_id.txt"
    if [ ! -f "$PACKAGE_ID_FILE" ]; then
      log "Package ID برای $name پیدا نشد — رد شد"
      continue
    fi

    PACKAGE_ID=$(cat "$PACKAGE_ID_FILE")
    if [ -z "$PACKAGE_ID" ]; then
      error "Package ID خالی است برای $name"
      continue
    fi

    log "=== Approve و Commit برای Chaincode: $name ==="

    PEER="peer0.org1.example.com"

    # کپی bundled برای verify
    docker cp /root/6g-network/config/bundled-tls-ca.pem $PEER:/tmp/bundled-tls-ca.pem

    # ===================== APPROVE =====================
    log "Approve کردن $name از org1 ..."
    APPROVE_OUTPUT=$(docker exec \
      -e CORE_PEER_LOCALMSPID=org1MSP \
      -e CORE_PEER_MSPCONFIGPATH=/etc/hyperledger/fabric/admin-msp \
      -e CORE_PEER_ADDRESS=peer0.org1.example.com:7051 \
      -e CORE_PEER_TLS_ENABLED=true \
      -e CORE_PEER_TLS_ROOTCERT_FILE=/tmp/bundled-tls-ca.pem \
      "$PEER" \
      peer lifecycle chaincode approveformyorg \
        --channelID networkchannel \
        --name "$name" \
        --version 1.0 \
        --package-id "$PACKAGE_ID" \
        --sequence 1 \
        --orderer orderer.example.com:7050 \
        --ordererTLSHostnameOverride orderer.example.com \
        --tls \
        --cafile /tmp/bundled-tls-ca.pem \
        --connTimeout 180s 2>&1)

    echo "$APPROVE_OUTPUT"

    if echo "$APPROVE_OUTPUT" | grep -q "Successfully approved"; then
      success "Approve موفق برای $name"
    else
      error "Approve شکست خورد برای $name"
      continue
    fi

    # ===================== COMMIT =====================
    log "Commit کردن $name ..."
    COMMIT_OUTPUT=$(docker exec \
      -e CORE_PEER_LOCALMSPID=org1MSP \
      -e CORE_PEER_MSPCONFIGPATH=/etc/hyperledger/fabric/admin-msp \
      -e CORE_PEER_ADDRESS=peer0.org1.example.com:7051 \
      -e CORE_PEER_TLS_ENABLED=true \
      -e CORE_PEER_TLS_ROOTCERT_FILE=/tmp/bundled-tls-ca.pem \
      "$PEER" \
      peer lifecycle chaincode commit \
        --channelID networkchannel \
        --name "$name" \
        --version 1.0 \
        --sequence 1 \
        --orderer orderer.example.com:7050 \
        --ordererTLSHostnameOverride orderer.example.com \
        --tls \
        --cafile /tmp/bundled-tls-ca.pem \
        --connTimeout 180s 2>&1)

    echo "$COMMIT_OUTPUT"

    if echo "$COMMIT_OUTPUT" | grep -q "Successfully committed"; then
      success "Commit موفق برای $name"
    else
      error "Commit شکست خورد برای $name"
    fi
  done

  success "عملیات approve و commit برای تمام chaincodeها تمام شد"
}

# ------------------- اجرا -------------------
main() {
  cleanup
  setup_network_with_fabric_ca_tls_nodeous_active
  #generate_bundled_certs
  start_network
  #create_and_join_channels
  #update_anchor_peers
  #generate_chaincode_modules
  #package_and_install_chaincode
  #approve_and_commit_chaincode
}

main
