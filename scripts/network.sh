#!/bin/bash
# /root/6g-network/scripts/network.sh
# نسخه اصلاح‌شده نهایی

ROOT_DIR="/root/6g-network"
CONFIG_DIR="$ROOT_DIR/config"
CRYPTO_DIR="$CONFIG_DIR/crypto-config"
CHANNEL_DIR="$CONFIG_DIR/channel-artifacts"
PROJECT_DIR="$CONFIG_DIR"
export FABRIC_CFG_PATH="$CONFIG_DIR"

log() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] $*"; }
success() { log "موفق: $*"; }
error() { log "خطا: $*"; exit 1; }

CHANNELS=(networkchannel resourcechannel)

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
  log "راه‌اندازی کامل شبکه"

  local CRYPTO_DIR="$PROJECT_DIR/crypto-config"
  local CHANNEL_ARTIFACTS="$PROJECT_DIR/channel-artifacts"
  local TEMP_CRYPTO="$PROJECT_DIR/temp-seed-crypto"
  local ROOT_CA_DIR="$CRYPTO_DIR/root-ca"
  local INTERMEDIATE_DIR="$CRYPTO_DIR/intermediate-ca"

  # پاک کردن کامل قبلی
  docker-compose -f docker-compose-tls-ca.yml down -v --remove-orphans 2>/dev/null || true
  docker-compose -f docker-compose-rca.yml down -v --remove-orphans 2>/dev/null || true
  docker-compose down -v 2>/dev/null || true
  docker volume prune -f
  rm -rf "$CRYPTO_DIR" "$CHANNEL_ARTIFACTS" "$TEMP_CRYPTO"
  mkdir -p "$CRYPTO_DIR" "$CHANNEL_ARTIFACTS" "$TEMP_CRYPTO" "$ROOT_CA_DIR" "$INTERMEDIATE_DIR/tls"

  # =====================================================
  # ایجاد شبکه Docker
  # =====================================================
  if ! docker network ls | grep -q "6g-network"; then
    log "ایجاد شبکه 6g-network"
    docker network create 6g-network
    success "شبکه 6g-network ساخته شد"
  else
    log "شبکه 6g-network از قبل وجود دارد"
  fi

  # =====================================================
  # ساخت config برای Root CA — قبل از start
  # =====================================================
  log "ساخت config برای Root CA"
  cat > "$ROOT_CA_DIR/fabric-ca-server-config.yaml" << 'EOF'
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
  success "config Root CA ساخته شد"

  # =====================================================
  # راه‌اندازی Root CA
  # =====================================================
  log "راه‌اندازی Root CA"
  docker-compose -f "$PROJECT_DIR/docker-compose-root-ca.yml" down -v --remove-orphans || true
  docker-compose -f "$PROJECT_DIR/docker-compose-root-ca.yml" up -d
  sleep 35
  tree

  # =====================================================
  # دریافت گواهی TLS برای rca-main از Root CA
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
        --csr.hosts "rca-main,localhost,127.0.0.1,rca-main.example.com" \
        -M /crypto-config/intermediate-ca/tls
    ' || error "دریافت گواهی TLS ناموفق بود"

  cp "$INTERMEDIATE_DIR/tls/signcerts/cert.pem"  "$INTERMEDIATE_DIR/tls/server.crt"
  cp "$INTERMEDIATE_DIR/tls/keystore/"*_sk        "$INTERMEDIATE_DIR/tls/server.key"
  cp "$CRYPTO_DIR/root-ca/ca-cert.pem"            "$INTERMEDIATE_DIR/tls/ca.crt"
  success "فایل‌های TLS rca-main آماده شدند"

  # =====================================================
  # ساخت config برای rca-main با تمام identity‌ها
  # =====================================================
  log "ساخت config برای rca-main"
  cat > "$INTERMEDIATE_DIR/fabric-ca-server-config.yaml" << 'EOF'
port: 7054
debug: true

tls:
  enabled: true
  certfile: tls/server.crt
  keyfile: tls/server.key

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
        - crl sign
      expiry: 8760h
      caconstraint:
        isca: true

affiliations:
  "":
    - "."

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
      attrs:
        hf.Revoker: true
EOF

  for i in {1..8}; do
    cat >> "$INTERMEDIATE_DIR/fabric-ca-server-config.yaml" << EOF

    - name: Admin@org${i}.example.com
      pass: adminpw
      type: admin
      affiliation: ""
      attrs:
        hf.Registrar.Roles: "client,peer,orderer,admin,user"
        hf.Registrar.DelegateRoles: "client,peer,orderer,admin,user"
        hf.Revoker: true

    - name: peer0.org${i}.example.com
      pass: peerpw
      type: peer
      affiliation: ""
      attrs:
        hf.Revoker: true
EOF
  done
  success "config rca-main با تمام identity‌ها ساخته شد"

  # =====================================================
  # ساخت docker-compose-rca.yml و راه‌اندازی rca-main
  # =====================================================
  log "ساخت docker-compose-rca.yml"
  cat > "$PROJECT_DIR/docker-compose-rca.yml" << 'EOF'
version: '3.8'
networks:
  6g-network:
    external: true
services:
  rca-main:
    image: hyperledger/fabric-ca:1.5
    container_name: rca-main
    hostname: rca-main
    ports:
      - "7054:7054"
    environment:
      - FABRIC_CA_SERVER_HOME=/etc/hyperledger/fabric-ca-server
      - FABRIC_CA_SERVER_PORT=7054
      - FABRIC_CA_SERVER_CA_NAME=rca-main
      - FABRIC_CA_SERVER_TLS_ENABLED=true
      - FABRIC_CA_SERVER_TLS_CERTFILE=/etc/hyperledger/fabric-ca-server/tls/server.crt
      - FABRIC_CA_SERVER_TLS_KEYFILE=/etc/hyperledger/fabric-ca-server/tls/server.key
      - FABRIC_CA_SERVER_CSR_CN=rca-main.example.com
      - FABRIC_CA_SERVER_CSR_HOSTS=rca-main,localhost,127.0.0.1
    volumes:
      - ./crypto-config/intermediate-ca:/etc/hyperledger/fabric-ca-server
    command: sh -c 'fabric-ca-server start -b admin:adminpw --registry.maxenrollments -1'
    networks:
      - 6g-network
    restart: unless-stopped
EOF

  log "راه‌اندازی rca-main"
  docker-compose -f "$PROJECT_DIR/docker-compose-rca.yml" up -d
  sleep 60

  docker ps

  # تأیید rca-main
  docker logs rca-main 2>&1 | grep -i "warning\|error\|listening" | tail -5

  # =====================================================
  # تولید هویت Orderer
  # =====================================================
  log "تولید هویت Orderer از rca-main"
  docker run --rm \
    --network 6g-network \
    -v "$CRYPTO_DIR":/crypto-config \
    hyperledger/fabric-ca-tools:latest \
    /bin/bash -c '
      set -e
      TLS_CERT="/crypto-config/intermediate-ca/tls/ca.crt"

      echo "=== Enroll Admin@example.com ==="
      fabric-ca-client enroll \
        -u https://Admin@example.com:adminpw@rca-main:7054 \
        --tls.certfiles "$TLS_CERT" \
        --csr.cn Admin@example.com \
        --csr.names C=IR,O=6G-Project,OU=admin,ST=Tehran \
        -M /crypto-config/ordererOrganizations/example.com/users/Admin@example.com/msp

      echo "=== Enroll orderer.example.com ==="
      fabric-ca-client enroll \
        -u https://orderer.example.com:ordererpw@rca-main:7054 \
        --tls.certfiles "$TLS_CERT" \
        --csr.cn orderer.example.com \
        --csr.names C=IR,O=6G-Project,OU=orderer,ST=Tehran \
        --csr.hosts "orderer.example.com,localhost,127.0.0.1" \
        -M /crypto-config/ordererOrganizations/example.com/orderers/orderer.example.com/msp

      echo "✅ هویت Orderer تولید شد"
    ' || error "تولید هویت Orderer ناموفق بود"

  # =====================================================
  # تولید هویت همه Orgها
  # =====================================================
  log "تولید هویت تمام سازمان‌ها از rca-main"
  for i in {1..8}; do
    log "تولید هویت org${i}"
    docker run --rm \
      --network 6g-network \
      -v "$CRYPTO_DIR":/crypto-config \
      hyperledger/fabric-ca-tools:latest \
      /bin/bash -c "
        set -e
        TLS_CERT=\"/crypto-config/intermediate-ca/tls/ca.crt\"

        fabric-ca-client enroll \
          -u https://Admin@org${i}.example.com:adminpw@rca-main:7054 \
          --tls.certfiles \"\$TLS_CERT\" \
          --csr.cn Admin@org${i}.example.com \
          --csr.names C=IR,O=6G-Project,OU=admin,ST=Tehran \
          -M /crypto-config/peerOrganizations/org${i}.example.com/users/Admin@org${i}.example.com/msp

        fabric-ca-client enroll \
          -u https://peer0.org${i}.example.com:peerpw@rca-main:7054 \
          --tls.certfiles \"\$TLS_CERT\" \
          --csr.cn peer0.org${i}.example.com \
          --csr.names C=IR,O=6G-Project,OU=peer,ST=Tehran \
          --csr.hosts \"peer0.org${i}.example.com,localhost,127.0.0.1\" \
          -M /crypto-config/peerOrganizations/org${i}.example.com/peers/peer0.org${i}.example.com/msp

        echo \"✅ org${i} تولید شد\"
      " || error "تولید هویت org${i} ناموفق بود"
  done
  success "تمام هویت‌های Orgها تولید شدند"

  # =====================================================
  # تولید گواهی TLS برای Orderer
  # =====================================================
  log "تولید گواهی TLS برای orderer.example.com"
  docker run --rm \
    --network 6g-network \
    -v "$CRYPTO_DIR":/crypto-config \
    hyperledger/fabric-ca-tools:latest \
    /bin/bash -c '
      set -e
      TLS_CERT="/crypto-config/intermediate-ca/tls/ca.crt"
      mkdir -p /crypto-config/ordererOrganizations/example.com/orderers/orderer.example.com/tls

      fabric-ca-client enroll \
        -u https://orderer.example.com:ordererpw@rca-main:7054 \
        --tls.certfiles "$TLS_CERT" \
        --enrollment.profile tls \
        --csr.cn orderer.example.com \
        --csr.hosts "orderer.example.com,localhost,127.0.0.1" \
        -M /crypto-config/ordererOrganizations/example.com/orderers/orderer.example.com/tls

      cp /crypto-config/ordererOrganizations/example.com/orderers/orderer.example.com/tls/signcerts/cert.pem \
         /crypto-config/ordererOrganizations/example.com/orderers/orderer.example.com/tls/server.crt
      cp /crypto-config/ordererOrganizations/example.com/orderers/orderer.example.com/tls/keystore/*_sk \
         /crypto-config/ordererOrganizations/example.com/orderers/orderer.example.com/tls/server.key
      cp /crypto-config/root-ca/ca-cert.pem \
         /crypto-config/ordererOrganizations/example.com/orderers/orderer.example.com/tls/ca.crt
      echo "✅ گواهی TLS Orderer تولید شد"
    ' || error "تولید TLS Orderer ناموفق بود"

  # =====================================================
  # تولید گواهی TLS برای همه Peerها
  # =====================================================
  for i in {1..8}; do
    log "تولید گواهی TLS برای peer0.org${i}"
    docker run --rm \
      --network 6g-network \
      -v "$CRYPTO_DIR":/crypto-config \
      hyperledger/fabric-ca-tools:latest \
      /bin/bash -c "
        set -e
        TLS_CERT=\"/crypto-config/intermediate-ca/tls/ca.crt\"
        mkdir -p /crypto-config/peerOrganizations/org${i}.example.com/peers/peer0.org${i}.example.com/tls

        fabric-ca-client enroll \
          -u https://peer0.org${i}.example.com:peerpw@rca-main:7054 \
          --tls.certfiles \"\$TLS_CERT\" \
          --enrollment.profile tls \
          --csr.cn peer0.org${i}.example.com \
          --csr.hosts \"peer0.org${i}.example.com,localhost,127.0.0.1\" \
          -M /crypto-config/peerOrganizations/org${i}.example.com/peers/peer0.org${i}.example.com/tls

        cp /crypto-config/peerOrganizations/org${i}.example.com/peers/peer0.org${i}.example.com/tls/signcerts/cert.pem \
           /crypto-config/peerOrganizations/org${i}.example.com/peers/peer0.org${i}.example.com/tls/server.crt
        cp /crypto-config/peerOrganizations/org${i}.example.com/peers/peer0.org${i}.example.com/tls/keystore/*_sk \
           /crypto-config/peerOrganizations/org${i}.example.com/peers/peer0.org${i}.example.com/tls/server.key
        cp /crypto-config/root-ca/ca-cert.pem \
           /crypto-config/peerOrganizations/org${i}.example.com/peers/peer0.org${i}.example.com/tls/ca.crt
        echo \"✅ گواهی TLS peer0.org${i} تولید شد\"
      " || error "تولید TLS peer0.org${i} ناموفق بود"
  done
  success "تمام گواهی‌های TLS تولید شدند"

  # =====================================================
  # ساخت MSP کامل با cacerts، admincerts و config.yaml
  # =====================================================
  log "ساخت MSP کامل برای همه سازمان‌ها"

  CA_CERT_NAME="ca-cert.pem"
  # گواهی CA اصلی که گواهی‌های peer و orderer را صادر کرده
  RCA_CERT="$INTERMEDIATE_DIR/ca-cert.pem"
  ROOT_CERT="$CRYPTO_DIR/root-ca/ca-cert.pem"

  # استخراج ca-cert.pem از ca-chain.pem اگر وجود ندارد
  if [ ! -f "$RCA_CERT" ] && [ -f "$INTERMEDIATE_DIR/ca-chain.pem" ]; then
    awk '/-----BEGIN CERTIFICATE-----/{p=1; count++} p && count==1{print} /-----END CERTIFICATE-----/ && count==1{p=0}' \
      "$INTERMEDIATE_DIR/ca-chain.pem" > "$RCA_CERT"
    log "ca-cert.pem از ca-chain.pem استخراج شد"
  fi

  # اگر ca-cert.pem وجود ندارد از Root CA استفاده کن
  if [ ! -f "$RCA_CERT" ]; then
    cp "$ROOT_CERT" "$RCA_CERT"
    log "از Root CA به عنوان CA اصلی استفاده شد"
  fi

  # ===================== Orderer =====================
  log "تنظیم MSP Orderer"

  mkdir -p "$CRYPTO_DIR/ordererOrganizations/example.com/orderers/orderer.example.com/msp"
  mkdir -p "$CRYPTO_DIR/ordererOrganizations/example.com/msp"
  mkdir -p "$CRYPTO_DIR/ordererOrganizations/example.com/users/Admin@example.com/msp"

  cat > "$CRYPTO_DIR/ordererOrganizations/example.com/orderers/orderer.example.com/msp/config.yaml" << EOF
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

  cp "$CRYPTO_DIR/ordererOrganizations/example.com/orderers/orderer.example.com/msp/config.yaml" \
     "$CRYPTO_DIR/ordererOrganizations/example.com/msp/config.yaml"
  cp "$CRYPTO_DIR/ordererOrganizations/example.com/orderers/orderer.example.com/msp/config.yaml" \
     "$CRYPTO_DIR/ordererOrganizations/example.com/users/Admin@example.com/msp/config.yaml"

  # cacerts
  mkdir -p "$CRYPTO_DIR/ordererOrganizations/example.com/msp/cacerts"
  mkdir -p "$CRYPTO_DIR/ordererOrganizations/example.com/orderers/orderer.example.com/msp/cacerts"
  mkdir -p "$CRYPTO_DIR/ordererOrganizations/example.com/users/Admin@example.com/msp/cacerts"
  cp "$RCA_CERT" "$CRYPTO_DIR/ordererOrganizations/example.com/msp/cacerts/${CA_CERT_NAME}"
  cp "$RCA_CERT" "$CRYPTO_DIR/ordererOrganizations/example.com/orderers/orderer.example.com/msp/cacerts/${CA_CERT_NAME}"
  cp "$RCA_CERT" "$CRYPTO_DIR/ordererOrganizations/example.com/users/Admin@example.com/msp/cacerts/${CA_CERT_NAME}"

  # tlscacerts
  mkdir -p "$CRYPTO_DIR/ordererOrganizations/example.com/msp/tlscacerts"
  cp "$ROOT_CERT" "$CRYPTO_DIR/ordererOrganizations/example.com/msp/tlscacerts/ca-cert.pem"

  # admincerts
  mkdir -p "$CRYPTO_DIR/ordererOrganizations/example.com/msp/admincerts"
  mkdir -p "$CRYPTO_DIR/ordererOrganizations/example.com/orderers/orderer.example.com/msp/admincerts"
  cp "$CRYPTO_DIR/ordererOrganizations/example.com/users/Admin@example.com/msp/signcerts/cert.pem" \
     "$CRYPTO_DIR/ordererOrganizations/example.com/msp/admincerts/"
  cp "$CRYPTO_DIR/ordererOrganizations/example.com/users/Admin@example.com/msp/signcerts/cert.pem" \
     "$CRYPTO_DIR/ordererOrganizations/example.com/orderers/orderer.example.com/msp/admincerts/"

  success "MSP Orderer ساخته شد"

  # ===================== Peer Orgها =====================
  for i in {1..8}; do
    ORG="org${i}"
    log "تنظیم MSP برای $ORG"

    mkdir -p "$CRYPTO_DIR/peerOrganizations/$ORG.example.com/peers/peer0.$ORG.example.com/msp"
    mkdir -p "$CRYPTO_DIR/peerOrganizations/$ORG.example.com/msp"
    mkdir -p "$CRYPTO_DIR/peerOrganizations/$ORG.example.com/users/Admin@$ORG.example.com/msp"

    cat > "$CRYPTO_DIR/peerOrganizations/$ORG.example.com/peers/peer0.$ORG.example.com/msp/config.yaml" << EOF
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

    cp "$CRYPTO_DIR/peerOrganizations/$ORG.example.com/peers/peer0.$ORG.example.com/msp/config.yaml" \
       "$CRYPTO_DIR/peerOrganizations/$ORG.example.com/msp/config.yaml"
    cp "$CRYPTO_DIR/peerOrganizations/$ORG.example.com/peers/peer0.$ORG.example.com/msp/config.yaml" \
       "$CRYPTO_DIR/peerOrganizations/$ORG.example.com/users/Admin@$ORG.example.com/msp/config.yaml"

    # cacerts
    mkdir -p "$CRYPTO_DIR/peerOrganizations/$ORG.example.com/msp/cacerts"
    mkdir -p "$CRYPTO_DIR/peerOrganizations/$ORG.example.com/peers/peer0.$ORG.example.com/msp/cacerts"
    mkdir -p "$CRYPTO_DIR/peerOrganizations/$ORG.example.com/users/Admin@$ORG.example.com/msp/cacerts"
    cp "$RCA_CERT" "$CRYPTO_DIR/peerOrganizations/$ORG.example.com/msp/cacerts/${CA_CERT_NAME}"
    cp "$RCA_CERT" "$CRYPTO_DIR/peerOrganizations/$ORG.example.com/peers/peer0.$ORG.example.com/msp/cacerts/${CA_CERT_NAME}"
    cp "$RCA_CERT" "$CRYPTO_DIR/peerOrganizations/$ORG.example.com/users/Admin@$ORG.example.com/msp/cacerts/${CA_CERT_NAME}"

    # tlscacerts
    mkdir -p "$CRYPTO_DIR/peerOrganizations/$ORG.example.com/msp/tlscacerts"
    cp "$ROOT_CERT" "$CRYPTO_DIR/peerOrganizations/$ORG.example.com/msp/tlscacerts/ca-cert.pem"

    # admincerts
    mkdir -p "$CRYPTO_DIR/peerOrganizations/$ORG.example.com/msp/admincerts"
    mkdir -p "$CRYPTO_DIR/peerOrganizations/$ORG.example.com/peers/peer0.$ORG.example.com/msp/admincerts"
    cp "$CRYPTO_DIR/peerOrganizations/$ORG.example.com/users/Admin@$ORG.example.com/msp/signcerts/cert.pem" \
       "$CRYPTO_DIR/peerOrganizations/$ORG.example.com/msp/admincerts/"
    cp "$CRYPTO_DIR/peerOrganizations/$ORG.example.com/users/Admin@$ORG.example.com/msp/signcerts/cert.pem" \
       "$CRYPTO_DIR/peerOrganizations/$ORG.example.com/peers/peer0.$ORG.example.com/msp/admincerts/"

    success "MSP $ORG ساخته شد"
  done

  cd "$CRYPTO_DIR"
  tree
  cd "$PROJECT_DIR"

  # =====================================================
  # ساخت channel artifacts
  # =====================================================
  mkdir -p "$CHANNEL_ARTIFACTS"

  log "ساخت genesis.block"
  configtxgen -profile OrdererGenesis \
    -outputBlock "$CHANNEL_ARTIFACTS/genesis.block" \
    -channelID system-channel 2>&1
  [ $? -ne 0 ] && error "خطا در ساخت genesis.block"
  success "genesis.block ساخته شد"

  for ch in networkchannel resourcechannel; do
    log "ساخت ${ch}.tx"
    configtxgen -profile ApplicationChannel \
      -outputCreateChannelTx "$CHANNEL_ARTIFACTS/${ch}.tx" \
      -channelID "$ch" 2>&1
    [ $? -ne 0 ] && error "خطا در ساخت ${ch}.tx"

    for i in {1..8}; do
      ORG_NAME="org${i}MSP"
      configtxgen -profile ApplicationChannel \
        -outputAnchorPeersUpdate "$CHANNEL_ARTIFACTS/${ch}_${ORG_NAME}_anchors.tx" \
        -channelID "$ch" \
        -asOrg "${ORG_NAME}" 2>&1
    done
    success "${ch} artifacts ساخته شدند"
  done

  success "تمام channel artifacts تولید شدند"
  ls -la "$CHANNEL_ARTIFACTS"
  success "شبکه با موفقیت آماده شد!"
}

# ------------------- راه‌اندازی شبکه -------------------
start_network() {
  log "راه‌اندازی شبکه..."
  cd "$PROJECT_DIR"
  docker-compose up -d
  sleep 90
  success "شبکه بالا آمد"
  docker ps
}

create_and_join_channels() {
  log "ایجاد کانال‌ها و تنظیم Anchor Peer..."

  local CHANNEL_ARTIFACTS="$CONFIG_DIR/channel-artifacts"
  local CRYPTO_DIR="$CONFIG_DIR/crypto-config"

  # پورت هر org
  declare -A ORG_PORTS=(
    [1]=7051 [2]=8051 [3]=9051 [4]=10051
    [5]=11051 [6]=12051 [7]=13051 [8]=14051
  )

  # =====================================================
  # ساخت bundled-tls-ca.pem
  # =====================================================
  log "ساخت bundled-tls-ca.pem"
  cat "$CRYPTO_DIR/root-ca/ca-cert.pem" \
      "$CRYPTO_DIR/intermediate-ca/ca-cert.pem" \
    > /tmp/bundled-tls-ca.pem 2>/dev/null || \
  cp "$CRYPTO_DIR/root-ca/ca-cert.pem" /tmp/bundled-tls-ca.pem
  success "bundled-tls-ca.pem ساخته شد"

  # =====================================================
  # ایجاد و join کانال‌ها
  # =====================================================
  for ch in networkchannel resourcechannel; do
    log "ایجاد کانال $ch ..."

    docker cp /tmp/bundled-tls-ca.pem peer0.org1.example.com:/tmp/bundled-tls-ca.pem
    docker cp "$CHANNEL_ARTIFACTS/${ch}.tx" peer0.org1.example.com:/tmp/${ch}.tx

    # ایجاد کانال توسط peer0.org1 با admin-msp
    docker exec peer0.org1.example.com bash -c "
      export CORE_PEER_LOCALMSPID=org1MSP
      export CORE_PEER_MSPCONFIGPATH=/etc/hyperledger/fabric/admin-msp
      export CORE_PEER_ADDRESS=peer0.org1.example.com:7051
      export CORE_PEER_TLS_ENABLED=true
      export CORE_PEER_TLS_ROOTCERT_FILE=/tmp/bundled-tls-ca.pem

      peer channel create \
        -o orderer.example.com:7050 \
        -c ${ch} \
        -f /tmp/${ch}.tx \
        --outputBlock /tmp/${ch}.block \
        --tls \
        --cafile /tmp/bundled-tls-ca.pem \
        --timeout 30s
    " || error "ایجاد کانال ${ch} ناموفق بود"

    docker cp peer0.org1.example.com:/tmp/${ch}.block "$CHANNEL_ARTIFACTS/"
    success "کانال ${ch} ساخته شد"

    # join همه peerها به کانال با admin-msp
    for i in {1..8}; do
      ORG="org${i}"
      PEER="peer0.${ORG}.example.com"
      PORT="${ORG_PORTS[$i]}"

      log "join کردن $PEER به $ch"

      docker cp "$CHANNEL_ARTIFACTS/${ch}.block" $PEER:/tmp/${ch}.block
      docker cp /tmp/bundled-tls-ca.pem $PEER:/tmp/bundled-tls-ca.pem

      docker exec $PEER bash -c "
        export CORE_PEER_LOCALMSPID=org${i}MSP
        export CORE_PEER_MSPCONFIGPATH=/etc/hyperledger/fabric/admin-msp
        export CORE_PEER_ADDRESS=${PEER}:${PORT}
        export CORE_PEER_TLS_ENABLED=true
        export CORE_PEER_TLS_ROOTCERT_FILE=/tmp/bundled-tls-ca.pem

        peer channel join -b /tmp/${ch}.block
      " && success "$PEER به $ch join شد" || error "$PEER نتوانست به $ch join شود"
    done

    # =====================================================
    # تنظیم Anchor Peer برای هر org
    # =====================================================
    log "تنظیم Anchor Peer برای $ch"
    for i in {1..8}; do
      ORG="org${i}"
      PEER="peer0.${ORG}.example.com"
      PORT="${ORG_PORTS[$i]}"
      ORG_MSP="org${i}MSP"
      ANCHOR_TX="${ch}_${ORG_MSP}_anchors.tx"

      if [ ! -f "$CHANNEL_ARTIFACTS/$ANCHOR_TX" ]; then
        log "فایل anchor tx برای $ORG_MSP در $ch وجود ندارد — رد شد"
        continue
      fi

      docker cp "$CHANNEL_ARTIFACTS/$ANCHOR_TX" $PEER:/tmp/$ANCHOR_TX
      docker cp /tmp/bundled-tls-ca.pem $PEER:/tmp/bundled-tls-ca.pem

      docker exec $PEER bash -c "
        export CORE_PEER_LOCALMSPID=${ORG_MSP}
        export CORE_PEER_MSPCONFIGPATH=/etc/hyperledger/fabric/admin-msp
        export CORE_PEER_ADDRESS=${PEER}:${PORT}
        export CORE_PEER_TLS_ENABLED=true
        export CORE_PEER_TLS_ROOTCERT_FILE=/tmp/bundled-tls-ca.pem

        peer channel update \
          -o orderer.example.com:7050 \
          -c ${ch} \
          -f /tmp/${ANCHOR_TX} \
          --tls \
          --cafile /tmp/bundled-tls-ca.pem
      " && success "Anchor Peer $PEER در $ch تنظیم شد" \
        || log "هشدار: Anchor Peer $PEER در $ch تنظیم نشد"
    done

    success "کانال $ch کامل شد"
  done

  success "تمام کانال‌ها ساخته و join شدند"
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

# ------------------- اجرا -------------------
main() {
  cleanup
  setup_network_with_fabric_ca_tls_nodeous_active
  start_network
  create_and_join_channels
  generate_chaincode_modules
}

main
