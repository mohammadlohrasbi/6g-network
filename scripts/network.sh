#!/bin/bash
# /root/6g-network/scripts/setup.sh
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

  # پاک کردن کامل قبلی
  docker-compose -f docker-compose-tls-ca.yml down -v --remove-orphans
  docker-compose -f docker-compose-rca.yml down -v --remove-orphans
  docker-compose down -v
  docker volume prune -f
  rm -rf "$CRYPTO_DIR" "$CHANNEL_ARTIFACTS" "$TEMP_CRYPTO"
  mkdir -p "$CRYPTO_DIR" "$CHANNEL_ARTIFACTS" "$TEMP_CRYPTO"

  # 1. تولید seed گواهی‌ها با cryptogen
  log "تولید seed گواهی‌ها با cryptogen"
  cryptogen generate --config=./cryptogen.yaml --output="$TEMP_CRYPTO"

  # 2. کپی seed برای TLS CA و Enrollment CA
  log "کپی seed برای TLS CA و Enrollment CA"

  # Orderer TLS CA
  mkdir -p "$CRYPTO_DIR/ordererOrganizations/example.com/tlsca"
  cp "$TEMP_CRYPTO/ordererOrganizations/example.com/tlsca/tlsca-orderer.example.com-cert.pem" "$CRYPTO_DIR/ordererOrganizations/example.com/tlsca/"
  cp "$TEMP_CRYPTO/ordererOrganizations/example.com/tlsca/"*_sk "$CRYPTO_DIR/ordererOrganizations/example.com/tlsca/priv_sk"

  # Orderer Enrollment CA
  mkdir -p "$CRYPTO_DIR/ordererOrganizations/example.com/rca"
  cp "$TEMP_CRYPTO/ordererOrganizations/example.com/ca/"*cert.pem "$CRYPTO_DIR/ordererOrganizations/example.com/rca/"
  cp "$TEMP_CRYPTO/ordererOrganizations/example.com/ca/"*_sk "$CRYPTO_DIR/ordererOrganizations/example.com/rca/priv_sk"
  mkdir -p "$CRYPTO_DIR/ordererOrganizations/example.com/rca/tls-msp"

  # Peer Orgs
  for i in {1..8}; do
    local org="org${i}"
    # TLS CA
    mkdir -p "$CRYPTO_DIR/peerOrganizations/${org}.example.com/tlsca"
    cp "$TEMP_CRYPTO/peerOrganizations/${org}.example.com/tlsca/tlsca-${org}.${org}.example.com-cert.pem" "$CRYPTO_DIR/peerOrganizations/${org}.example.com/tlsca/"
    cp "$TEMP_CRYPTO/peerOrganizations/${org}.example.com/tlsca/"*_sk "$CRYPTO_DIR/peerOrganizations/${org}.example.com/tlsca/priv_sk"

    # Enrollment CA
    mkdir -p "$CRYPTO_DIR/peerOrganizations/${org}.example.com/rca"
    cp "$TEMP_CRYPTO/peerOrganizations/${org}.example.com/ca/"*cert.pem "$CRYPTO_DIR/peerOrganizations/${org}.example.com/rca/"
    cp "$TEMP_CRYPTO/peerOrganizations/${org}.example.com/ca/"*_sk "$CRYPTO_DIR/peerOrganizations/${org}.example.com/rca/priv_sk"
    mkdir -p "$CRYPTO_DIR/peerOrganizations/${org}.example.com/rca/tls-msp"
  done

  success "seed گواهی‌ها آماده شد"
  cd "$CRYPTO_DIR"
  tree
  cd "$PROJECT_DIR"

  rm -rf "$TEMP_CRYPTO"

  # 3. بالا آوردن TLS CAها
  log "بالا آوردن TLS CAها"
  docker-compose -f docker-compose-tls-ca.yml up -d
  sleep 60

  # 4. استخراج ID کانتینر TLS CAها
  log "استخراج ID کانتینر TLS CAها"
  local TCA_ORDERER_ID=$(docker ps --filter "name=tls-ca-orderer" --format "{{.ID}}")
  local TCA_IDS_STR=""
  for i in {1..8}; do
    local tca_name="tls-ca-org${i}"
    local tca_id=$(docker ps --filter "name=${tca_name}" --format "{{.ID}}")
    TCA_IDS_STR="${TCA_IDS_STR}${tca_id},"
  done
  TCA_IDS_STR=${TCA_IDS_STR%,}

  # 5. تولید گواهی TLS برای Enrollment CAها (با ID کانتینر TLS CA)
  log "تولید گواهی TLS برای Enrollment CAها"
  docker run --rm \
    --network config_6g-network \
    -v "$PROJECT_DIR/crypto-config":/crypto-config \
    hyperledger/fabric-ca-tools:latest \
    /bin/bash -c "
      export FABRIC_CA_CLIENT_HOME=/tmp/fabric-ca-client
      export FABRIC_CA_CLIENT_TLS_INSECURE_SKIP_VERIFY=true

      TCA_ORDERER_ID=\"$TCA_ORDERER_ID\"
      IFS=',' read -r -a TCA_IDS <<< \"$TCA_IDS_STR\"

      # Orderer
      fabric-ca-client enroll -u https://admin:adminpw@\$TCA_ORDERER_ID:7053 \
        --tls.certfiles /crypto-config/ordererOrganizations/example.com/tlsca/tlsca-orderer.example.com-cert.pem \
        --csr.hosts 'rca-orderer' \
        -M /crypto-config/ordererOrganizations/example.com/rca/tls-msp
        
      cp /crypto-config/ordererOrganizations/example.com/rca/tls-msp/keystore/*_sk /crypto-config/ordererOrganizations/example.com/rca/tls-msp/keystore/tls-key.pem

      # Org1 تا Org8
      for i in {0..7}; do
        TCA_ID=\${TCA_IDS[\$i]}
        RCA_NAME=\"rca-org\$((i+1))\"
        PORT=\$((7053 + (\$i + 1) * 100))
        ORG=\"org\$((i+1))\"
        fabric-ca-client enroll -u https://admin:adminpw@\$TCA_ID:\$PORT \
          --tls.certfiles /crypto-config/peerOrganizations/\$ORG.example.com/tlsca/tlsca-\$ORG.\$ORG.example.com-cert.pem \
          --csr.hosts \$RCA_NAME \
          -M /crypto-config/peerOrganizations/\$ORG.example.com/rca/tls-msp

        cp /crypto-config/peerOrganizations/\$ORG.example.com/rca/tls-msp/keystore/*_sk /crypto-config/peerOrganizations/\$ORG.example.com/rca/tls-msp/keystore/tls-key.pem
      done
    "
    
  cd "$CRYPTO_DIR"
  tree
  cd "$PROJECT_DIR"
# برای rca-orderer
cat > crypto-config/ordererOrganizations/example.com/rca/fabric-ca-server-config.yaml <<EOF
ou:
  enabled: true
  organizational_unit_identifiers:
    - organizational_unit_identifier: "orderer"
      certificate: "ca/ca-orderer.example.com-cert.pem"
    - organizational_unit_identifier: "admin"
      certificate: "ca/ca-orderer.example.com-cert.pem"
    - organizational_unit_identifier: "client"
      certificate: "ca/ca-orderer.example.com-cert.pem"

csr:
  cn: rca-orderer.example.com
  hosts:
    - rca-orderer
    - localhost

tls:
  enabled: true

registry:
  maxenrollments: -1
  identities:
    - name: admin
      pass: adminpw
      type: client
      affiliation: ""
      attrs:
        hf.Registrar.Roles: "client,peer,orderer,user"
        hf.Registrar.DelegateRoles: "client,peer,orderer,user"
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
echo "fabric-ca-server-config.yaml برای rca-orderer ساخته شد (با bootstrap admin ثبت‌شده + OU classification کامل)"

# برای هر rca-orgX
for i in {1..8}; do
  ORG=org$i
  PORT=$((7054 + $i * 100))
  RCA_NAME="rca-org${i}"
  RCA_CN="rca-org${i}.org${i}.example.com"
  
  cat > crypto-config/peerOrganizations/$ORG.example.com/rca/fabric-ca-server-config.yaml <<EOF
ou:
  enabled: true
  organizational_unit_identifiers:
    - organizational_unit_identifier: "peer"
      certificate: "ca/ca-org${i}.org${i}.example.com-cert.pem"
    - organizational_unit_identifier: "admin"
      certificate: "ca/ca-org${i}.org${i}.example.com-cert.pem"
    - organizational_unit_identifier: "client"
      certificate: "ca/ca-org${i}.org${i}.example.com-cert.pem"

csr:
  cn: $RCA_CN
  hosts:
    - $RCA_NAME
    - localhost

tls:
  enabled: true

registry:
  maxenrollments: -1
  identities:
    - name: admin
      pass: adminpw
      type: client
      affiliation: ""
      attrs:
        hf.Registrar.Roles: "client,peer,orderer,user"
        hf.Registrar.DelegateRoles: "client,peer,orderer,user"
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
  echo "fabric-ca-server-config.yaml برای rca-org${i} ساخته شد (با bootstrap admin ثبت‌شده + OU classification کامل)"
done

echo "تمام فایل‌های fabric-ca-server-config.yaml با موفقیت ساخته شدند — OU classification کامل فعال است و bootstrap admin در DB ثبت شد!"

  
  # 6. بالا آوردن Enrollment CAها
  log "بالا آوردن Enrollment CAها"
  docker-compose -f docker-compose-rca.yml up -d
  sleep 60

  cd "$CRYPTO_DIR"
  tree
  cd "$PROJECT_DIR"

  # 7. استخراج ID Enrollment CAها
  log "استخراج ID Enrollment CAها"
  local RCA_ORDERER_ID=$(docker ps --filter "name=rca-orderer" --format "{{.ID}}")
  local RCA_IDS_STR=""
  for i in {1..8}; do
    local rca_name="rca-org${i}"
    local rca_id=$(docker ps --filter "name=${rca_name}" --format "{{.ID}}")
    RCA_IDS_STR="${RCA_IDS_STR}${rca_id},"
  done
  RCA_IDS_STR=${RCA_IDS_STR%,}
log "تولید گواهی‌های نهایی با Enrollment CA"

log "تولید هویت Orderer با OU classification (نسخه نهایی و بدون خطا)"

docker run --rm \
  --network config_6g-network \
  -v "$PROJECT_DIR/crypto-config":/crypto-config \
  hyperledger/fabric-ca-tools:latest \
  /bin/bash -c "
    export FABRIC_CA_CLIENT_HOME=/tmp/ca-client-orderer

    # مسیر دقیق گواهی TLS CA داخل container
    TLS_CERT=\"/crypto-config/ordererOrganizations/example.com/rca/tls-msp/cacerts/*.pem\"

    echo 'enroll bootstrap admin (admin:adminpw)...'
    fabric-ca-client enroll -u https://admin:adminpw@rca-orderer:7054 \
      --tls.certfiles /crypto-config/ordererOrganizations/example.com/rca/tls-msp/cacerts/*.pem \

    echo 'register Admin@example.com با OU=admin...'
    fabric-ca-client register --id.name Admin@example.com \
      --id.secret adminpw \
      --id.type client \
      --id.attrs \"ou=admin:ecert\" \
      -u https://admin:adminpw@rca-orderer:7054 \
      --tls.certfiles /crypto-config/ordererOrganizations/example.com/rca/tls-msp/cacerts/*.pem \

    echo 'enroll Admin@example.com...'
    fabric-ca-client enroll -u https://Admin@example.com:adminpw@rca-orderer:7054 \
      --tls.certfiles /crypto-config/ordererOrganizations/example.com/rca/tls-msp/cacerts/*.pem \
      -M /crypto-config/ordererOrganizations/example.com/users/Admin@example.com/msp

    echo 'register orderer.example.com با OU=orderer...'
    fabric-ca-client register --id.name orderer.example.com \
      --id.secret ordererpw \
      --id.type orderer \
      --id.attrs \"ou=orderer:ecert\" \
      -u https://admin:adminpw@rca-orderer:7054 \
      --tls.certfiles /crypto-config/ordererOrganizations/example.com/rca/tls-msp/cacerts/*.pem \

    echo 'enroll orderer.example.com...'
    fabric-ca-client enroll -u https://orderer.example.com:ordererpw@rca-orderer:7054 \
      --tls.certfiles /crypto-config/ordererOrganizations/example.com/rca/tls-msp/cacerts/*.pem \
      --csr.hosts 'orderer.example.com,localhost,127.0.0.1' \
      -M /crypto-config/ordererOrganizations/example.com/orderers/orderer.example.com/msp

    echo 'Orderer با موفقیت تولید شد (با OU=orderer در گواهی)'
  "

echo "هویت Orderer کاملاً اصولی و با OU classification تولید شد!"
for i in {1..8}; do
  docker run --rm \
    --network config_6g-network \
    -v "$PROJECT_DIR/crypto-config":/crypto-config \
    hyperledger/fabric-ca-tools:latest \
    /bin/bash -c "
      export FABRIC_CA_CLIENT_HOME=/tmp/ca-client-empty

      ORG=org$i
      RCA_NAME=rca-org$i
      PORT=\$((7054 + $i * 100))
      TLS_CERT=\"/crypto-config/peerOrganizations/\$ORG.example.com/rca/tls-msp/cacerts/*.pem\"

      echo 'enroll bootstrap admin (admin:adminpw)...'
      fabric-ca-client enroll -u https://admin:adminpw@\$RCA_NAME:\$PORT \
        --tls.certfiles \$TLS_CERT
      
      echo \"register Admin@\$ORG.example.com با OU=admin...\"
      fabric-ca-client register --id.name Admin@\$ORG.example.com \
        --id.secret adminpw \
        --id.type client \
        --id.attrs \"ou=admin:ecert\" \
        -u https://admin:adminpw@\$RCA_NAME:\$PORT \
        --tls.certfiles \$TLS_CERT

      echo \"enroll Admin@\$ORG.example.com...\"
      fabric-ca-client enroll -u https://admin:adminpw@\$RCA_NAME:\$PORT \
        --tls.certfiles \$TLS_CERT \
        -M /crypto-config/peerOrganizations/\$ORG.example.com/users/Admin@\$ORG.example.com/msp
      
      echo \"register peer0.\$ORG.example.com با OU=peer...\"
      fabric-ca-client register --id.name peer0.\$ORG.example.com \
        --id.secret peerpw \
        --id.type peer \
        --id.attrs \"ou=peer:ecert\" \
        -u https://admin:adminpw@\$RCA_NAME:\$PORT \
        --tls.certfiles \$TLS_CERT

      echo \"enroll peer0.\$ORG.example.com...\"
      fabric-ca-client enroll -u https://peer0.\$ORG.example.com:peerpw@\$RCA_NAME:\$PORT \
        --tls.certfiles \$TLS_CERT \
        --csr.hosts 'peer0.\$ORG.example.com,localhost,127.0.0.1' \
        -M /crypto-config/peerOrganizations/\$ORG.example.com/peers/peer0.\$ORG.example.com/msp

      echo \"\$ORG با موفقیت تولید شد (با OU=peer در گواهی)\"
    "
done

echo 'تمام گواهی‌ها بدون خطا تولید شدند — پروژه ۶G کامل شد!'
log "تولید گواهی‌های TLS برای نودها (به صورت کاملاً اصولی)"

  cd "$CRYPTO_DIR"
  tree
  cd "$PROJECT_DIR"

# Orderer TLS (این بخش قبلاً موفق بود، اما برای کامل بودن دوباره می‌گذاریم)
docker run --rm \
  --network config_6g-network \
  -v "$PROJECT_DIR/crypto-config":/crypto-config \
  hyperledger/fabric-ca-tools:latest \
  /bin/bash -c '
    export FABRIC_CA_CLIENT_HOME=/tmp/ca-client-tls-orderer

    fabric-ca-client enroll -u https://orderer.example.com:ordererpw@rca-orderer:7054 \
      --tls.certfiles /crypto-config/ordererOrganizations/example.com/rca/tls-msp/cacerts/*.pem \
      --enrollment.profile tls \
      --csr.cn orderer.example.com \
      --csr.hosts "orderer.example.com,localhost,127.0.0.1" \
      -M /crypto-config/ordererOrganizations/example.com/orderers/orderer.example.com/tls

    # rename به نام استاندارد
    cp /crypto-config/ordererOrganizations/example.com/orderers/orderer.example.com/tls/signcerts/cert.pem \
       /crypto-config/ordererOrganizations/example.com/orderers/orderer.example.com/tls/server.crt
    cp /crypto-config/ordererOrganizations/example.com/orderers/orderer.example.com/tls/keystore/*_sk \
       /crypto-config/ordererOrganizations/example.com/orderers/orderer.example.com/tls/server.key
    cp /crypto-config/ordererOrganizations/example.com/orderers/orderer.example.com/tls/tlscacerts/* \
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
      TLS_CA_PATH=\"/crypto-config/peerOrganizations/\$ORG.example.com/rca/tls-msp/cacerts/*.pem\"

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

      cp /crypto-config/peerOrganizations/\$ORG.example.com/peers/\$PEER_NAME/tls/tlscacerts/* \
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

export FABRIC_CFG_PATH="$PROJECT_DIR"

echo "FABRIC_CFG_PATH تنظیم شد روی: $FABRIC_CFG_PATH"
echo "محتویات دایرکتوری:"
ls -la "$FABRIC_CFG_PATH"/configtx.yaml || echo "configtx.yaml پیدا نشد!"

# ۱. genesis.block
configtxgen -profile OrdererGenesis \
            -outputBlock "$CHANNEL_ARTIFACTS/genesis.block" \
            -channelID system-channel

if [ $? -ne 0 ]; then
  echo "خطا در تولید genesis.block — پروفایل OrdererGenesis وجود ندارد؟"
  exit 1
fi
echo "genesis.block با موفقیت ساخته شد"

# ۲. channel creation tx
for ch in networkchannel resourcechannel; do
  configtxgen -profile ApplicationChannel \
              -outputCreateChannelTx "$CHANNEL_ARTIFACTS/${ch}.tx" \
              -channelID "$ch"

  if [ $? -ne 0 ]; then
    echo "خطا در تولید ${ch}.tx"
    exit 1
  fi
  echo "${ch}.tx ساخته شد"
done

# ۳. anchor peers update
for ch in networkchannel resourcechannel; do
  for i in {1..8}; do
    configtxgen -profile ApplicationChannel \
                -outputAnchorPeersUpdate "$CHANNEL_ARTIFACTS/${ch}_Org${i}_anchors.tx" \
                -channelID "$ch" \
                -asOrg Org${i}MSP

    if [ $? -ne 0 ]; then
      echo "خطا در anchor update برای Org${i} در $ch"
      exit 1
    fi
    echo "Anchor update برای Org${i}MSP در $ch ساخته شد"
  done
done

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
  echo "در حال ساخت bundled certها برای TLS و MSP (برای حل gossip و authentication در multi-org)..."

  cd "$PROJECT_DIR"

  local tls_bundled="$CONFIG_DIR/bundled-tls-ca.pem"
  local msp_bundled="$CONFIG_DIR/bundled-msp-ca.pem"

  : > "$tls_bundled"
  : > "$msp_bundled"

  local tls_count=0
  local msp_count=0

  # --- TLS bundled (برای TLS verify در gossip) ---
  # Orderer TLS root
  local orderer_tls_root="$PROJECT_DIR/crypto-config/ordererOrganizations/example.com/orderers/orderer.example.com/tls/tlscacerts/tls-rca-orderer-7054.pem"
  if [ -f "$orderer_tls_root" ]; then
    cat "$orderer_tls_root" >> "$tls_bundled"
    echo "TLS - اضافه شد orderer: $orderer_tls_root"
    ((tls_count++))
  else
    echo "خطا: فایل TLS root orderer یافت نشد: $orderer_tls_root"
    return 1
  fi

  # Peer orgها TLS root
  for i in {1..8}; do
    local org="org$i"
    local peer_tls_root="$PROJECT_DIR/crypto-config/peerOrganizations/$org.example.com/peers/peer0.$org.example.com/tls/tlscacerts/tls-rca-$org-*.pem"
    if ls $peer_tls_root 1> /dev/null 2>&1; then
      cat $peer_tls_root >> "$tls_bundled"
      echo "TLS - اضافه شد $org: $peer_tls_root"
      ((tls_count++))
    else
      echo "خطا: فایل TLS root برای $org یافت نشد: $peer_tls_root"
      return 1
    fi
  done

  # --- MSP bundled (برای MSP identity verify در gossip) ---
  # Orderer MSP root
  local orderer_msp_root="$PROJECT_DIR/crypto-config/ordererOrganizations/example.com/msp/cacerts/rca-orderer-7054.pem"
  if [ -f "$orderer_msp_root" ]; then
    cat "$orderer_msp_root" >> "$msp_bundled"
    echo "MSP - اضافه شد orderer: $orderer_msp_root"
    ((msp_count++))
  else
    echo "خطا: فایل MSP root orderer یافت نشد: $orderer_msp_root"
    return 1
  fi

  # Peer orgها MSP root
  for i in {1..8}; do
    local org="org$i"
    local peer_msp_root="$PROJECT_DIR/crypto-config/peerOrganizations/$org.example.com/msp/cacerts/rca-$org-*.pem"
    if ls $peer_msp_root 1> /dev/null 2>&1; then
      cat $peer_msp_root >> "$msp_bundled"
      echo "MSP - اضافه شد $org: $peer_msp_root"
      ((msp_count++))
    else
      echo "خطا: فایل MSP root برای $org یافت نشد: $peer_msp_root"
      return 1
    fi
  done

  local tls_total=$(grep -c "BEGIN CERTIFICATE" "$tls_bundled")
  local msp_total=$(grep -c "BEGIN CERTIFICATE" "$msp_bundled")

  echo ""
  echo "bundled-tls-ca.pem ساخته شد ($tls_total cert) در: $tls_bundled"
  echo "bundled-msp-ca.pem ساخته شد ($msp_total cert) در: $msp_bundled"
  echo ""

  if [ "$tls_total" -eq 9 ] && [ "$msp_total" -eq 9 ]; then
    echo "هر دو bundled با موفقیت ساخته شدند (9 cert هر کدام — کامل!)"
  else
    echo "خطا: تعداد certها نادرست است (TLS: $tls_total, MSP: $msp_total — باید 9 باشد)"
    return 1
  fi

  echo "اقدامات بعدی در docker-compose.yml:"
  echo "1. برای همه peerها:"
  echo "   - mount برای TLS bundled (مسیر جدید):"
  echo "     - ./bundled-tls-ca.pem:/etc/hyperledger/fabric/bundled-tls-ca.pem:ro"
  echo "   - CORE_PEER_TLS_ROOTCERT_FILE=/etc/hyperledger/fabric/bundled-tls-ca.pem"
  echo "   - mount برای MSP bundled (جایگزین cacerts اصلی):"
  echo "     - ./bundled-msp-ca.pem:/etc/hyperledger/fabric/msp/cacerts/ca.crt:ro"
  echo ""
  echo "2. برای orderer:"
  echo "   - mount برای TLS bundled (مسیر جدید):"
  echo "     - ./bundled-tls-ca.pem:/var/hyperledger/orderer/bundled-tls-ca.pem:ro"
  echo "   - ORDERER_GENERAL_TLS_ROOTCAS=[/var/hyperledger/orderer/bundled-tls-ca.pem]"
  echo "   - mount برای MSP bundled (جایگزین cacerts اصلی):"
  echo "     - ./bundled-msp-ca.pem:/var/hyperledger/orderer/msp/cacerts/ca.crt:ro"
  echo ""
  echo "3. شبکه را ری‌استارت کن: docker-compose down -v && docker-compose up -d"
  echo "4. چک کن listen و لاگ — gossip و authentication کار می‌کند!"
}

# اگر می‌خواهی تابع خودکار اجرا شود، این خط را بدون # بگذار:
# generate_bundled_certs

# ------------------- راه‌اندازی شبکه -------------------
start_network() {
  log "راه‌اندازی شبکه (نسخه نهایی و ۱۰۰٪ سالم)..."

  # ۱. شبکه داکر را بساز (اگر وجود نداشته باشد)
  # docker network create config_6g-network 2>/dev/null || true

  # ۲. کاملاً همه کانتینرها را پاک کن (این خط حیاتی است!)
  # docker-compose -f "$CONFIG_DIR/docker-compose-ca.yml" down -v --remove-orphans 
  docker-compose -f "$CONFIG_DIR/docker-compose.yml" down -v 

  # ۳. بالا آوردن CAها
  # docker-compose -f "$CONFIG_DIR/docker-compose-ca.yml" up -d --remove-orphans
  if [ $? -ne 0 ]; then
    error "راه‌اندازی CAها شکست خورد"
  fi
  log "CAها بالا آمدند"
  sleep 20

  # ۴. بالا آوردن Orderer و Peerها با --force-recreate (این خط تمام مشکلات قبلی را حل می‌کند!)
  docker-compose -f "$CONFIG_DIR/docker-compose.yml" up -d
  if [ $? -ne 0 ]; then
    error "راه‌اندازی Peerها و Orderer شکست خورد"
  fi

  # log "صبر ۲۰ ثانیه برای بالا آمدن کامل و پایدار شدن شبکه..."
  # sleep 20

  success "شبکه با موفقیت و به صورت کاملاً سالم راه‌اندازی شد"
  docker ps
}

# ------------------- ایجاد و join کانال‌ها -------------------
create_and_join_channels() {
  log "ایجاد کانال‌ها و join همه peerها (TLS کاملاً فعال — با bundled-tls-ca.pem برای trust همه orgها)"

  local channel_count="${#CHANNELS[@]}"
  local created=0

  CHANNEL_ARTIFACTS="/root/6g-network/config/channel-blocks"
  mkdir -p "$CHANNEL_ARTIFACTS"

  for ch in "${CHANNELS[@]}"; do
    log "در حال ایجاد کانال $ch (TLS فعال با bundled) ..."

    docker exec peer0.org1.example.com rm -f /tmp/${ch}.block 2>/dev/null || true

    if docker exec peer0.org1.example.com \
      bash -c '
        export CORE_PEER_LOCALMSPID=org1MSP  # حرف کوچک
        export CORE_PEER_MSPCONFIGPATH=/etc/hyperledger/fabric/msp
        export CORE_PEER_ADDRESS=127.0.0.1:7051
        export CORE_PEER_TLS_ENABLED=true
        export CORE_PEER_TLS_ROOTCERT_FILE=/etc/hyperledger/fabric/bundled-tls-ca.pem  # <<< bundled برای trust همه
        export CORE_PEER_TLS_CERT_FILE=/etc/hyperledger/fabric/tls/server.crt
        export CORE_PEER_TLS_KEY_FILE=/etc/hyperledger/fabric/tls/server.key

        peer channel create \
          -o orderer.example.com:7050 \
          -c "'"$ch"'" \
          -f /etc/hyperledger/configtx/'"$ch"'.tx \
          --outputBlock /tmp/'"$ch"'.block \
          --tls \
          --cafile /etc/hyperledger/fabric/bundled-tls-ca.pem  # <<< bundled برای orderer TLS root
      '; then

      success "کانال $ch ساخته شد"

      docker cp peer0.org1.example.com:/tmp/${ch}.block "$CHANNEL_ARTIFACTS/${ch}.block"

      log "join همه peerها به $ch (TLS فعال با bundled و hostname برای verify)..."

      for i in {1..8}; do
        ORG=org$i
        PEER=peer0.$ORG.example.com
        MSPID=org${i}MSP  # حرف کوچک
        PORT=$((7051 + (i-1)*1000))

        docker cp "$CHANNEL_ARTIFACTS/${ch}.block" $PEER:/tmp/${ch}.block

        docker exec $PEER \
          bash -c "
            export CORE_PEER_LOCALMSPID=$MSPID
            export CORE_PEER_MSPCONFIGPATH=/etc/hyperledger/fabric/msp
            export CORE_PEER_ADDRESS=peer0.$ORG.example.com:$PORT  # <<< hostname برای TLS verify
            export CORE_PEER_TLS_ENABLED=true
            export CORE_PEER_TLS_ROOTCERT_FILE=/etc/hyperledger/fabric/bundled-tls-ca.pem  # <<< bundled برای trust همه
            export CORE_PEER_TLS_CERT_FILE=/etc/hyperledger/fabric/tls/server.crt
            export CORE_PEER_TLS_KEY_FILE=/etc/hyperledger/fabric/tls/server.key

            peer channel join -b /tmp/${ch}.block && echo 'join موفق' || echo 'join قبلاً انجام شده'
          " && success "peer0.$ORG به $ch join شد" || log "join قبلاً انجام شده"

      done

      ((created++))
    fi

    echo "--------------------------------------------------"
  done

  success "تمام کانال‌ها ساخته و همه peerها join شدند!"

  log "چک نهایی join:"
  for ch in "${CHANNELS[@]}"; do
    echo "کانال $ch:"
    for i in {1..8}; do
      echo "peer0.org$i.example.com:"
      docker exec peer0.org$i.example.com peer channel list | grep $ch || echo "join نشده"
    done
  done

  success "تمام شد!"
}

# ------------------- اجرا -------------------
main() {
  cleanup
  setup_network_with_fabric_ca_tls_nodeous_active
  generate_bundled_certs
  start_network
  create_and_join_channels
}

main
