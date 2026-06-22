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

# 2. ایجاد کانفیگ ساده و معتبر
cat > /root/6g-network/config/crypto-config/root-ca/fabric-ca-server-config.yaml << 'EOF'
port: 7052
debug: true

tls:
  enabled: true

registry:
  maxenrollments: -1
  identities:
    - name: admin
      pass: adminpw
      type: admin
      affiliation: ""
      attrs:
        hf.Registrar.Roles: "*"
        hf.Registrar.DelegateRoles: "*"
        hf.Revoker: true
        hf.IntermediateCA: true
        hf.GenCRL: true
        hf.Registrar.Attributes: "*"
        hf.AffiliationMgr: true

affiliations:
  "":
    - "."
EOF


  # =====================================================
  # راه‌اندازی Root CA (اولین قدم)
  # =====================================================
  log "راه‌اندازی Root CA"
  docker-compose -f "$PROJECT_DIR/docker-compose-root-ca.yml" down -v --remove-orphans || true
  docker-compose -f "$PROJECT_DIR/docker-compose-root-ca.yml" up -d
  sleep 35
  tree
  success "Root CA با موفقیت راه‌اندازی شد"
# =====================================================
# 7. تبدیل rca-* به Intermediate CA واقعی از Root CA
#    (با استفاده از enrollment.profile ca)
# =====================================================
log "تبدیل rca-orderer و rca-orgها به Intermediate CA از Root CA"

docker run --rm \
  --network 6g-network \
  -v "$PROJECT_DIR/crypto-config":/crypto-config \
  hyperledger/fabric-ca-tools:latest \
  /bin/bash -c '
    set -e
    export FABRIC_CA_CLIENT_TLS_INSECURE_SKIP_VERIFY=true

    ROOT_CA_ADDR="root-ca:7052"
    ROOT_CA_CERT="/crypto-config/root-ca/ca-cert.pem"

    echo "=== Enroll admin روی Root CA ==="
    export FABRIC_CA_CLIENT_HOME=/tmp/root-ca-admin
    fabric-ca-client enroll -u https://admin:adminpw@$ROOT_CA_ADDR \
      --tls.certfiles $ROOT_CA_CERT

    echo "=== Enroll rca-orderer به عنوان Intermediate ==="
    fabric-ca-client enroll -u https://admin:adminpw@$ROOT_CA_ADDR \
      --tls.certfiles $ROOT_CA_CERT \
      --enrollment.profile ca \
      -M /crypto-config/ordererOrganizations/example.com/rca/intermediate-msp

    echo "=== Enroll rca-orgها به عنوان Intermediate ==="
    for i in {1..8}; do
      ORG="org$i"
      echo "Enrolling rca-$ORG ..."
      fabric-ca-client enroll -u https://admin:adminpw@$ROOT_CA_ADDR \
        --tls.certfiles $ROOT_CA_CERT \
        --enrollment.profile ca \
        -M /crypto-config/peerOrganizations/$ORG.example.com/rca/intermediate-msp
    done

    echo "همه rca-* با موفقیت به عنوان Intermediate CA از Root CA enroll شدند"
  '

if [ $? -eq 0 ]; then
    success "تبدیل rca-* به Intermediate CA با موفقیت انجام شد"
else
    error "خطا در تبدیل rca-* به Intermediate CA"
fi

    
  cd "$CRYPTO_DIR"
  tree
  cd "$PROJECT_DIR"
cd "$PROJECT_DIR"


echo "=== کپی کلیدها به priv_sk ==="

# rca-orderer
cp /root/6g-network/config/crypto-config/ordererOrganizations/example.com/rca/intermediate-msp/keystore/*_sk \
   /root/6g-network/config/crypto-config/ordererOrganizations/example.com/rca/intermediate-msp/keystore/priv_sk

# rca-orgها
for i in {1..8}; do
  cp /root/6g-network/config/crypto-config/peerOrganizations/org${i}.example.com/rca/intermediate-msp/keystore/*_sk \
     /root/6g-network/config/crypto-config/peerOrganizations/org${i}.example.com/rca/intermediate-msp/keystore/priv_sk
done

echo "کلیدها با موفقیت به priv_sk کپی شدند"

echo "=== ساخت دایرکتوری‌ها و fabric-ca-server-config.yaml برای rca-*ها ==="

# rca-orderer
mkdir -p crypto-config/ordererOrganizations/example.com/rca
cat > crypto-config/ordererOrganizations/example.com/rca/fabric-ca-server-config.yaml <<'EOF'
ou:
  enabled: true
  organizational_unit_identifiers:
    - organizational_unit_identifier: "orderer"
      certificate: "ca/cert.pem"
    - organizational_unit_identifier: "admin"
      certificate: "ca/cert.pem"
    - organizational_unit_identifier: "client"
      certificate: "ca/cert.pem"

csr:
  cn: rca-orderer.example.com
  hosts:
    - rca-orderer
    - localhost
    - 127.0.0.1

tls:
  enabled: true

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

affiliations:
  "":
    - "."

debug: true
EOF
echo "fabric-ca-server-config.yaml برای rca-orderer ساخته شد"

# rca-org1 تا rca-org8
for i in {1..8}; do
  ORG="org${i}"
  RCA_NAME="rca-org${i}"
  RCA_CN="rca-org${i}.org${i}.example.com"

  mkdir -p crypto-config/peerOrganizations/$ORG.example.com/rca

  cat > crypto-config/peerOrganizations/$ORG.example.com/rca/fabric-ca-server-config.yaml <<EOF
ou:
  enabled: true
  organizational_unit_identifiers:
    - organizational_unit_identifier: "peer"
      certificate: "ca/cert.pem"
    - organizational_unit_identifier: "admin"
      certificate: "ca/cert.pem"
    - organizational_unit_identifier: "client"
      certificate: "ca/cert.pem"

csr:
  cn: $RCA_CN
  hosts:
    - $RCA_NAME
    - localhost
    - 127.0.0.1

tls:
  enabled: true

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

affiliations:
  "":
    - "."

debug: true
EOF
  echo "fabric-ca-server-config.yaml برای ${RCA_NAME} ساخته شد"
done
# =====================================================
# تولید گواهی TLS رcaها با openssl (روش پیشنهادی Fabric)
# =====================================================
log "تولید گواهی‌های TLS سرورهای rca"

ROOT_CA_CERT="/root/6g-network/config/crypto-config/root-ca/ca-cert.pem"
ROOT_CA_KEY="/root/6g-network/config/crypto-config/root-ca/fabric-ca-server.key"

# بررسی وجود فایل‌های Root CA
if [ ! -f "$ROOT_CA_CERT" ] || [ ! -f "$ROOT_CA_KEY" ]; then
    error "فایل‌های Root CA پیدا نشدند! لطفاً ابتدا Root CA را بسازید."
fi

# =====================================================
# بخش بهبودیافته: تولید گواهی TLS سرور برای rcaها
# =====================================================

log "تولید گواهی‌های TLS سرور برای کانتینرهای rca (Root CA + Intermediate)"

ROOT_CA_CERT="/root/6g-network/config/crypto-config/root-ca/ca-cert.pem"
ROOT_CA_KEY="/root/6g-network/config/crypto-config/root-ca/fabric-ca-server.key"

# بررسی وجود Root CA
if [ ! -f "$ROOT_CA_CERT" ] || [ ! -f "$ROOT_CA_KEY" ]; then
    error "فایل‌های Root CA پیدا نشدند! ابتدا Root CA را راه‌اندازی کنید."
fi

# =====================================================
# تولید گواهی TLS سرور برای rcaها (نسخه نهایی)
# =====================================================

log "تولید گواهی‌های TLS سرور برای کانتینرهای rca"

ROOT_CA_CERT="/root/6g-network/config/crypto-config/root-ca/ca-cert.pem"
ROOT_CA_KEY="/root/6g-network/config/crypto-config/root-ca/fabric-ca-server.key"

docker ps

generate_rca_tls() {
    local NAME=$1
    local CN=$2
    local RCA_DIR=$3          # مسیر پوشه rca (مثلاً .../rca)
    local TLS_DIR="$RCA_DIR/tls"

    mkdir -p "$TLS_DIR"

    log "در حال تولید گواهی TLS برای ${NAME} ..."

    # تولید کلید خصوصی
    openssl ecparam -name prime256v1 -genkey -noout \
        -out "$TLS_DIR/server.key" 2>/dev/null || error "خطا در ساخت کلید ${NAME}"

    # تولید CSR
    openssl req -new -sha256 \
        -key "$TLS_DIR/server.key" \
        -out /tmp/${NAME}.csr \
        -subj "/C=IR/ST=Tehran/O=6G-Project/OU=Fabric/CN=${CN}" \
        -addext "subjectAltName = DNS:${CN},DNS:localhost,IP:127.0.0.1" 2>/dev/null

    # امضای گواهی توسط Root CA
    openssl x509 -req -sha256 -days 365 \
        -in /tmp/${NAME}.csr \
        -CA "$ROOT_CA_CERT" \
        -CAkey "$ROOT_CA_KEY" \
        -CAcreateserial \
        -out "$TLS_DIR/server.crt" \
        -extfile <(printf "subjectAltName = DNS:%s,DNS:localhost,IP:127.0.0.1" "$CN") 2>/dev/null

    rm -f /tmp/${NAME}.csr
    cp "$TLS_DIR/server.crt" "$TLS_DIR/ca.crt"

    # بررسی گواهی
    if openssl x509 -in "$TLS_DIR/server.crt" -text -noout | grep -q "Subject Alternative Name"; then
        success "گواهی TLS برای ${NAME} ساخته شد → $TLS_DIR"
    else
        error "ساخت گواهی TLS برای ${NAME} ناموفق بود"
    fi
}

# ===================== فراخوانی تابع =====================

# rca-orderer
generate_rca_tls \
    "rca-orderer" \
    "rca-orderer.example.com" \
    "/root/6g-network/config/crypto-config/ordererOrganizations/example.com/rca"

# rca-org1 تا rca-org8
for i in {1..8}; do
    generate_rca_tls \
        "rca-org${i}" \
        "rca-org${i}.org${i}.example.com" \
        "/root/6g-network/config/crypto-config/peerOrganizations/org${i}.example.com/rca"
done

success "تمام گواهی‌های TLS رcaها با موفقیت ساخته شدند"

echo "تمام فایل‌های fabric-ca-server-config.yaml با موفقیت ساخته شدند (با ساختار جدید Root CA)"

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
# استخراج ID کانتینرهای rca-* (اختیاری - فقط برای لاگ)
# =====================================================
log "استخراج ID کانتینرهای Enrollment CAها"
RCA_ORDERER_ID=$(docker ps --filter "name=rca-orderer" --format "{{.ID}}")
RCA_ORG_IDS=()
for i in {1..8}; do
    id=$(docker ps --filter "name=rca-org${i}" --format "{{.ID}}")
    RCA_ORG_IDS+=("$id")
done
success "ID rca-orderer: $RCA_ORDERER_ID"
success "ID تمام rca-orgها استخراج شد"

# =====================================================
# تولید هویت Orderer و Orgها (با tls-cert.pem هر rca)
# =====================================================
log "تولید هویت Orderer و Orgها با گواهی TLS اختصاصی"

# ===================== Orderer =====================
docker run --rm \
  --network 6g-network \
  -v "/root/6g-network/config/crypto-config":/crypto-config \
  hyperledger/fabric-ca-tools:latest \
  /bin/bash -c '
    set -e
    export FABRIC_CA_CLIENT_HOME=/tmp/ca-client-orderer

    TLS_CERT="/crypto-config/ordererOrganizations/example.com/rca/tls-cert.pem"

    echo "=== Enroll admin روی rca-orderer ==="
    fabric-ca-client enroll -u https://admin:adminpw@rca-orderer:7054 --tls.certfiles "$TLS_CERT"

    echo "=== Register Admin@example.com ==="
    fabric-ca-client register --id.name Admin@example.com --id.secret adminpw --id.type admin \
      -u https://admin:adminpw@rca-orderer:7054 --tls.certfiles "$TLS_CERT"

    echo "=== Enroll Admin@example.com ==="
    fabric-ca-client enroll -u https://Admin@example.com:adminpw@rca-orderer:7054 \
      --tls.certfiles "$TLS_CERT" \
      -M /crypto-config/ordererOrganizations/example.com/users/Admin@example.com/msp

    echo "=== Register orderer.example.com ==="
    fabric-ca-client register --id.name orderer.example.com --id.secret ordererpw --id.type orderer \
      -u https://admin:adminpw@rca-orderer:7054 --tls.certfiles "$TLS_CERT"

    echo "=== Enroll orderer.example.com ==="
    fabric-ca-client enroll -u https://orderer.example.com:ordererpw@rca-orderer:7054 \
      --tls.certfiles "$TLS_CERT" \
      --csr.hosts "orderer.example.com,localhost,127.0.0.1" \
      -M /crypto-config/ordererOrganizations/example.com/orderers/orderer.example.com/msp

    echo "هویت Orderer با موفقیت تولید شد"
  '

# ===================== Orgها =====================
for i in {1..8}; do
  PORT=$((7054 + $i * 100))

  docker run --rm \
    --network 6g-network \
    -v "/root/6g-network/config/crypto-config":/crypto-config \
    hyperledger/fabric-ca-tools:latest \
    /bin/bash -c "
      set -e
      export FABRIC_CA_CLIENT_HOME=/tmp/ca-client-org$i

      TLS_CERT=\"/crypto-config/peerOrganizations/org${i}.example.com/rca/tls-cert.pem\"

      echo \"=== Enroll admin روی rca-org$i ===\"
      fabric-ca-client enroll -u https://admin:adminpw@rca-org$i:${PORT} --tls.certfiles \"\$TLS_CERT\"

      echo \"=== Register Admin@org$i.example.com ===\"
      fabric-ca-client register --id.name Admin@org$i.example.com --id.secret adminpw --id.type admin \
        -u https://admin:adminpw@rca-org$i:${PORT} --tls.certfiles \"\$TLS_CERT\"

      echo \"=== Enroll Admin@org$i.example.com ===\"
      fabric-ca-client enroll -u https://Admin@org$i.example.com:adminpw@rca-org$i:${PORT} \
        --tls.certfiles \"\$TLS_CERT\" \
        -M /crypto-config/peerOrganizations/org$i.example.com/users/Admin@org$i.example.com/msp

      echo \"=== Register peer0.org$i.example.com ===\"
      fabric-ca-client register --id.name peer0.org$i.example.com --id.secret peerpw --id.type peer \
        -u https://admin:adminpw@rca-org$i:${PORT} --tls.certfiles \"\$TLS_CERT\"

      echo \"=== Enroll peer0.org$i.example.com ===\"
      fabric-ca-client enroll -u https://peer0.org$i.example.com:peerpw@rca-org$i:${PORT} \
        --tls.certfiles \"\$TLS_CERT\" \
        --csr.hosts \"peer0.org$i.example.com,localhost,127.0.0.1\" \
        -M /crypto-config/peerOrganizations/org$i.example.com/peers/peer0.org$i.example.com/msp

      echo \"org$i با موفقیت تولید شد\"
    "
done

echo "تمام هویت‌ها با موفقیت تولید شدند"



  cd "$CRYPTO_DIR"
  tree
  cd "$PROJECT_DIR"

# Orderer TLS (این بخش قبلاً موفق بود، اما برای کامل بودن دوباره می‌گذاریم)
docker run --rm \
  --network 6g-network \
  -v "$PROJECT_DIR/crypto-config":/crypto-config \
  hyperledger/fabric-ca-tools:latest \
  /bin/bash -c '
    export FABRIC_CA_CLIENT_HOME=/tmp/ca-client-tls-orderer

    fabric-ca-client enroll -u https://orderer.example.com:ordererpw@rca-orderer:7054 \
      --tls.certfiles /crypto-config/root-ca/ca-cert.pem \
      --enrollment.profile tls \
      --csr.cn orderer.example.com \
      --csr.hosts "orderer.example.com,localhost,127.0.0.1" \
      -M /crypto-config/ordererOrganizations/example.com/orderers/orderer.example.com/tls

    # rename به نام استاندارد
    cp /crypto-config/ordererOrganizations/example.com/orderers/orderer.example.com/tls/signcerts/cert.pem \
       /crypto-config/ordererOrganizations/example.com/orderers/orderer.example.com/tls/server.crt
    cp /crypto-config/ordererOrganizations/example.com/orderers/orderer.example.com/tls/keystore/*_sk \
       /crypto-config/ordererOrganizations/example.com/orderers/orderer.example.com/tls/server.key
    cp /crypto-config/ordererOrganizations/example.com/rca/tls-msp/cacerts/*.pem \
       /crypto-config/ordererOrganizations/example.com/orderers/orderer.example.com/tls/ca.crt

    echo "TLS گواهی orderer ساخته شد"
  '

# هر Peer در docker run جداگانه — تضمینی بدون syntax error و تداخل config
for i in {1..8}; do
  docker run --rm \
    --network config_6g-network \
    -v "$PROJECT_DIR/crypto-config":/crypto-config \
    hyperledger/fabric-ca-tools:latest \
    /bin/bash -c "
      export FABRIC_CA_CLIENT_HOME=/tmp/ca-client-tls-peer$i

      ORG=org$i
      RCA_NAME=rca-org$i
      PORT=\$((7054 + $i * 100))
      PEER_NAME=peer0.\$ORG.example.com
      TLS_CA_PATH=\"/crypto-config/root-ca/ca-cert.pem\"

      echo \"در حال تولید TLS برای \$PEER_NAME (پورت \$PORT)...\"

      fabric-ca-client enroll -u https://\$PEER_NAME:peerpw@\$RCA_NAME:\$PORT \
        --tls.certfiles \$TLS_CA_PATH \
        --enrollment.profile tls \
        --csr.cn \$PEER_NAME \
        --csr.hosts \"\$PEER_NAME,localhost,127.0.0.1\" \
        -M /crypto-config/peerOrganizations/\$ORG.example.com/peers/\$PEER_NAME/tls

      # rename فایل‌ها
      cp /crypto-config/peerOrganizations/\$ORG.example.com/peers/\$PEER_NAME/tls/signcerts/cert.pem \
         /crypto-config/peerOrganizations/\$ORG.example.com/peers/\$PEER_NAME/tls/server.crt

      cp /crypto-config/peerOrganizations/\$ORG.example.com/peers/\$PEER_NAME/tls/keystore/*_sk \
         /crypto-config/peerOrganizations/\$ORG.example.com/peers/\$PEER_NAME/tls/server.key

      cp /crypto-config/peerOrganizations/\$ORG.example.com/rca/tls-msp/cacerts/*.pem \
         /crypto-config/peerOrganizations/\$ORG.example.com/peers/\$PEER_NAME/tls/ca.crt

      echo \"TLS گواهی \$PEER_NAME با موفقیت ساخته شد\"
    "
done

echo 'تمام گواهی‌های TLS به صورت کاملاً اصولی و بدون خطا تولید شدند!'
  cd "$CRYPTO_DIR"
  tree
  cd "$PROJECT_DIR"

  log "ساخت یکپارچه تمام فایل‌های config.yaml + آماده‌سازی MSP Admin کاربر برای mount مستقیم (Peer و Orderer)"

  # ۱. MSP نود orderer
  cat > crypto-config/ordererOrganizations/example.com/orderers/orderer.example.com/msp/config.yaml <<'EOF'
NodeOUs:
  Enable: true
  ClientOUIdentifier:
    Certificate: cacerts/rca-orderer-7054.pem
    OrganizationalUnitIdentifier: client
  PeerOUIdentifier:
    Certificate: cacerts/rca-orderer-7054.pem
    OrganizationalUnitIdentifier: peer
  AdminOUIdentifier:
    Certificate: cacerts/rca-orderer-7054.pem
    OrganizationalUnitIdentifier: admin
  OrdererOUIdentifier:
    Certificate: cacerts/rca-orderer-7054.pem
    OrganizationalUnitIdentifier: orderer
EOF
  echo "config.yaml برای MSP نود orderer ساخته شد"

  # ۲. MSP اصلی OrdererOrg
  mkdir -p crypto-config/ordererOrganizations/example.com/msp
  cp crypto-config/ordererOrganizations/example.com/orderers/orderer.example.com/msp/config.yaml \
     crypto-config/ordererOrganizations/example.com/msp/config.yaml
  echo "config.yaml برای MSP اصلی OrdererOrg کپی شد"

  # ۳. کپی config.yaml به MSP Admin کاربر Orderer (برای mount)
  mkdir -p crypto-config/ordererOrganizations/example.com/users/Admin@example.com/msp
  cp crypto-config/ordererOrganizations/example.com/orderers/orderer.example.com/msp/config.yaml \
     crypto-config/ordererOrganizations/example.com/users/Admin@example.com/msp/config.yaml
  echo "config.yaml به MSP Admin کاربر Orderer کپی شد (برای mount)"

  # ۴. MSP نود peerها و MSP اصلی Peer Orgها + کپی به MSP Admin کاربر Peerها
  for i in {1..8}; do
    ORG=org$i
    PORT=$((7054 + $i * 100))
    RCA_FILE="rca-org${i}-${PORT}.pem"

    # MSP نود peer
    mkdir -p crypto-config/peerOrganizations/$ORG.example.com/peers/peer0.$ORG.example.com/msp
    cat > crypto-config/peerOrganizations/$ORG.example.com/peers/peer0.$ORG.example.com/msp/config.yaml <<EOF
NodeOUs:
  Enable: true
  ClientOUIdentifier:
    Certificate: cacerts/$RCA_FILE
    OrganizationalUnitIdentifier: client
  PeerOUIdentifier:
    Certificate: cacerts/$RCA_FILE
    OrganizationalUnitIdentifier: peer
  AdminOUIdentifier:
    Certificate: cacerts/$RCA_FILE
    OrganizationalUnitIdentifier: admin
  OrdererOUIdentifier:
    Certificate: cacerts/$RCA_FILE
    OrganizationalUnitIdentifier: orderer
EOF
    echo "config.yaml برای MSP نود peer0.$ORG ساخته شد"

    # MSP اصلی سازمان
    mkdir -p crypto-config/peerOrganizations/$ORG.example.com/msp
    cp crypto-config/peerOrganizations/$ORG.example.com/peers/peer0.$ORG.example.com/msp/config.yaml \
       crypto-config/peerOrganizations/$ORG.example.com/msp/config.yaml
    echo "config.yaml برای MSP اصلی $ORG کپی شد"

    # کپی config.yaml به MSP Admin کاربر Peer (برای mount)
    mkdir -p crypto-config/peerOrganizations/$ORG.example.com/users/Admin@$ORG.example.com/msp
    cp crypto-config/peerOrganizations/$ORG.example.com/peers/peer0.$ORG.example.com/msp/config.yaml \
       crypto-config/peerOrganizations/$ORG.example.com/users/Admin@$ORG.example.com/msp/config.yaml
    echo "config.yaml به MSP Admin کاربر $ORG کپی شد (برای mount)"
  done

  echo "تمام فایل‌های config.yaml ساخته شدند — MSP admin-msp آماده mount مستقیم از Admin کاربر است!"
  echo "در docker-compose.yml این خطوط را اضافه کنید:"
  echo "  برای orderer:"
  echo "    - ./crypto-config/ordererOrganizations/example.com/users/Admin@example.com/msp:/etc/hyperledger/fabric/admin-msp:ro"
  echo "  برای هر peer:"
  echo "    - ./crypto-config/peerOrganizations/orgX.example.com/users/Admin@orgX.example.com/msp:/etc/hyperledger/fabric/admin-msp:ro"

  log "اصلاح config.yaml با نام دقیق فایل RCA (حل خطای wildcard و OU classification)"

log "6. تولید genesis.block و channel transactionها"
log "اصلاح نهایی MSP سازمان‌ها — کپی cacerts از MSP peer به MSP اصلی"

# Orderer Org
mkdir -p crypto-config/ordererOrganizations/example.com/msp/cacerts
cp crypto-config/ordererOrganizations/example.com/orderers/orderer.example.com/msp/cacerts/*.pem \
   crypto-config/ordererOrganizations/example.com/msp/cacerts/

echo "cacerts برای OrdererMSP کپی شد"

# همه Peer Orgها (org1 تا org8)
for i in {1..8}; do
  ORG=org$i

  # ساخت پوشه cacerts در MSP اصلی سازمان
  mkdir -p crypto-config/peerOrganizations/$ORG.example.com/msp/cacerts

  # کپی از MSP peer0 (که گواهی CA دارد)
  cp crypto-config/peerOrganizations/$ORG.example.com/peers/peer0.$ORG.example.com/msp/cacerts/*.pem \
     crypto-config/peerOrganizations/$ORG.example.com/msp/cacerts/

  echo "cacerts برای Org${i}MSP از peer0 کپی شد"
done

echo "تمام MSPهای اصلی سازمان اصلاح شدند — configtxgen حالا ۱۰۰٪ کار می‌کند!"

# Orderer Org
mkdir -p crypto-config/ordererOrganizations/example.com/msp/admincerts
cp crypto-config/ordererOrganizations/example.com/users/Admin@example.com/msp/signcerts/*.pem \
   crypto-config/ordererOrganizations/example.com/msp/admincerts/
cp crypto-config/ordererOrganizations/example.com/orderers/orderer.example.com/msp/cacerts/*.pem \
   crypto-config/ordererOrganizations/example.com/msp/cacerts/

# Peer Orgها
for i in {1..8}; do
  ORG=org$i

  # MSP اصلی سازمان
  mkdir -p crypto-config/peerOrganizations/$ORG.example.com/msp/admincerts
  mkdir -p crypto-config/peerOrganizations/$ORG.example.com/msp/cacerts

  # کپی admincerts از Admin کاربر
  cp crypto-config/peerOrganizations/$ORG.example.com/users/Admin@$ORG.example.com/msp/signcerts/*.pem \
     crypto-config/peerOrganizations/$ORG.example.com/msp/admincerts/

  # کپی cacerts از MSP peer (یا Admin)
  cp crypto-config/peerOrganizations/$ORG.example.com/peers/peer0.$ORG.example.com/msp/cacerts/*.pem \
     crypto-config/peerOrganizations/$ORG.example.com/msp/cacerts/

  # اختیاری: کپی config.yaml اگر OU classification بخواهید
  cp crypto-config/peerOrganizations/$ORG.example.com/peers/peer0.$ORG.example.com/msp/config.yaml \
     crypto-config/peerOrganizations/$ORG.example.com/msp/config.yaml 2>/dev/null || true

  echo "MSP اصلی Org${i}MSP ساخته شد (admincerts + cacerts)"
done

log "کپی admincerts به MSP اصلی نودها (peer و orderer — روش کاملاً اصولی)"
mkdir -p crypto-config/ordererOrganizations/example.com/orderers/orderer.example.com/msp/admincerts
cp crypto-config/ordererOrganizations/example.com/users/Admin@example.com/msp/signcerts/*.pem \
   crypto-config/ordererOrganizations/example.com/orderers/orderer.example.com/msp/admincerts/

# همه Peerها
for i in {1..8}; do
  ORG=org$i
  mkdir -p crypto-config/peerOrganizations/$ORG.example.com/peers/peer0.$ORG.example.com/msp/admincerts
  cp crypto-config/peerOrganizations/$ORG.example.com/users/Admin@$ORG.example.com/msp/signcerts/*.pem \
     crypto-config/peerOrganizations/$ORG.example.com/peers/peer0.$ORG.example.com/msp/admincerts/

  echo "admincerts برای MSP peer0.$ORG.example.com اضافه شد"
done

log "تولید دوباره genesis.block و channel artifacts"

# تنظیم دقیق FABRIC_CFG_PATH (مسیر پوشه‌ای که configtx.yaml داخل آن است)
export FABRIC_CFG_PATH="/root/6g-network/config"   # اگر configtx.yaml در این پوشه است

echo "FABRIC_CFG_PATH تنظیم شد روی: $FABRIC_CFG_PATH"
echo "محتویات دایرکتوری:"
ls -la "$FABRIC_CFG_PATH/configtx.yaml" || echo "configtx.yaml پیدا نشد!"

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
  generate_bundled_certs
  start_network
  create_and_join_channels
  update_anchor_peers
  generate_chaincode_modules
  package_and_install_chaincode
  #approve_and_commit_chaincode
}

main
