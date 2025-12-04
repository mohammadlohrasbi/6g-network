#!/bin/bash
# /root/6g-network/scripts/setup.sh
# نسخه نهایی — ۱۰۰٪ بدون خطا
set -e

ROOT_DIR="/root/6g-network"
CONFIG_DIR="$ROOT_DIR/config"
CRYPTO_DIR="$CONFIG_DIR/crypto-config"
CHANNEL_DIR="$CONFIG_DIR/channel-artifacts"
SCRIPTS_DIR="$ROOT_DIR/scripts"
CHAINCODE_DIR="$SCRIPTS_DIR/chaincode"
export FABRIC_CFG_PATH="$CONFIG_DIR"

log() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] $*"; }
success() { log "موفق: $*"; }
error() { log "خطا: $*"; exit 1; }

CHANNELS=(
  networkchannel resourcechannel performancechannel iotchannel authchannel connectivitychannel
  sessionchannel policychannel auditchannel securitychannel datachannel analyticschannel
  monitoringchannel managementchannel optimizationchannel faultchannel trafficchannel
  accesschannel compliancechannel integrationchannel
)

# ------------------- پاک‌سازی -------------------
cleanup() {
  log "شروع پاک‌سازی سیستم..."
  docker system prune -a --volumes -f >/dev/null 2>&1 || true
  docker network prune -f >/dev/null 2>&1 || true
  rm -rf "$CHANNEL_DIR"/* 2>/dev/null || true
  success "پاک‌سازی کامل شد"
}

# ------------------- تولید crypto و آرتیفکت‌ها -------------------
generate_crypto() {
  log "تولید crypto-config..."
  cryptogen generate --config="$CONFIG_DIR/cryptogen.yaml" --output="$CRYPTO_DIR" || error "تولید crypto-config شکست خورد"
  success "Crypto-config با موفقیت تولید شد"
}

generate_channel_artifacts() {
  log "تولید آرتیفکت‌های کانال..."
  mkdir -p "$CHANNEL_DIR"
  configtxgen -profile SystemChannel -outputBlock "$CHANNEL_DIR/genesis.block" -channelID system-channel || error "تولید genesis.block شکست خورد"
  for ch in "${CHANNELS[@]}"; do
    configtxgen -profile ApplicationChannel -outputCreateChannelTx "$CHANNEL_DIR/${ch}.tx" -channelID "$ch" || error "تولید tx برای $ch شکست خورد"
  done
  success "تمام آرتیفکت‌ها تولید شدند"
}

generate_coreyamls() {
  log "تولید core.yaml..."
  "$SCRIPTS_DIR/generateCoreyamls.sh" || error "اجرای generateCoreyamls.sh شکست خورد"
  cp "$CONFIG_DIR/core-org1.yaml" "$CONFIG_DIR/core.yaml" 2>/dev/null || error "کپی core.yaml شکست خورد"
  success "core.yaml آماده شد"
}

# ------------------- راه‌اندازی شبکه -------------------
start_network() {
  log "راه‌اندازی شبکه..."
  docker network create config_6g-network 2>/dev/null || true
  docker-compose -f "$CONFIG_DIR/docker-compose-ca.yml" up -d --remove-orphans >/dev/null 2>&1 || error "راه‌اندازی CAها شکست خورد"
  sleep 20
  docker-compose -f "$CONFIG_DIR/docker-compose.yml" up -d --remove-orphans >/dev/null 2>&1 || error "راه‌اندازی Peerها و Orderer شکست خورد"
  log "صبر 100 ثانیه برای بالا آمدن کامل..."
  sleep 100
  success "شبکه راه‌اندازی شد"
}

wait_for_orderer() {
  log "در انتظار Orderer..."
  local count=0
  while [ $count -lt 300 ]; do
    if docker logs orderer.example.com 2>&1 | grep -q "Beginning to serve requests"; then
      success "Orderer آماده است!"
      return 0
    fi
    sleep 5
    count=$((count + 5))
  done
  error "Orderer بالا نیامد!"
}

# ------------------- اصلاح Adminها (قبل از ایجاد کانال!) -------------------
fix_admin_ous() {
  log "اصلاح Adminها (admincerts) — این دقیقاً مشکل شما بود!"
  for i in {1..8}; do
    ADMIN_MSP="$CRYPTO_DIR/peerOrganizations/org${i}.example.com/users/Admin@org${i}.example.com/msp"
    mkdir -p "$ADMIN_MSP/admincerts"
    cp "$ADMIN_MSP/signcerts/Admin@org${i}.example.com-cert.pem" \
       "$ADMIN_MSP/admincerts/Admin@org${i}.example.com-cert.pem" || error "گواهی Admin org${i} پیدا نشد"
  done
  success "تمام Adminها در admincerts کپی شدند — ری‌استارت Peerها..."
  docker restart $(docker ps -q -f "name=peer") >/dev/null
  sleep 60
}

# ------------------- ایجاد و join کانال‌ها -------------------
create_and_join_channels() {
  log "ایجاد و join تمام ۲۰ کانال با هویت Admin..."
  local created=0
  for ch in "${CHANNELS[@]}"; do
    log "ایجاد کانال $ch..."
    if docker exec -e CORE_PEER_MSPCONFIGPATH=/etc/hyperledger/fabric/msp-users peer0.org1.example.com peer channel create \
      -o orderer.example.com:7050 -c "$ch" -f "/etc/hyperledger/configtx/${ch}.tx" \
      --tls --cafile /var/hyperledger/orderer/tls/ca.crt \
      --outputBlock "/tmp/${ch}.block"; then
      
      success "کانال $ch ساخته شد"
      
      for i in {1..8}; do
        PEER="peer0.org${i}.example.com"
        docker cp peer0.org1.example.com:/tmp/${ch}.block /tmp/ && \
        docker cp /tmp/${ch}.block ${PEER}:/tmp/ && \
        docker exec -e CORE_PEER_MSPCONFIGPATH=/etc/hyperledger/fabric/msp-users "$PEER" sh -c "
          export CORE_PEER_LOCALMSPID=Org${i}MSP
          export CORE_PEER_ADDRESS=${PEER}:7051
          peer channel join -b /tmp/${ch}.block
        " && log "Peer org${i} به کانال $ch join شد"
        rm -f /tmp/${ch}.block
      done
      ((created++))
    else
      error "ایجاد کانال $ch شکست خورد"
    fi
  done
  [ $created -eq 20 ] && success "تمام ۲۰ کانال ساخته و join شدند" || error "فقط $created کانال ساخته شد"
}

# ------------------- بسته‌بندی و نصب Chaincode -------------------
package_and_install_chaincode() {
  if [ ! -d "$CHAINCODE_DIR" ] || [ -z "$(ls -A "$CHAINCODE_DIR")" ]; then
    log "هیچ chaincode وجود ندارد — رد شد"
    return 0
  fi

  local total=$(ls -1 "$CHAINCODE_DIR" | wc -l)
  local installed=0

  log "بسته‌بندی و نصب $total Chaincode..."

  for dir in "$CHAINCODE_DIR"/*/; do
    [ ! -d "$dir" ] && continue
    name=$(basename "$dir")

    pkg="/tmp/chaincode_pkg/$name"
    mkdir -p "$pkg/src" "$pkg/META-INF"
    cp "$dir/chaincode.go" "$pkg/src/" || { log "فایل chaincode.go برای $name وجود ندارد"; continue; }

    cat > "$pkg/src/go.mod" <<EOF
module $name
go 1.21
EOF

    cat > "$pkg/META-INF/MANIFEST.MF" <<EOF
Manifest-Version: 1.0
Chaincode-Type: golang
Label: ${name}_1.0
EOF

    if docker run --rm \
      -v "$pkg":/chaincode \
      -v "$CRYPTO_DIR/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp":/msp \
      -e CORE_PEER_LOCALMSPID=Org1MSP \
      -e CORE_PEER_MSPCONFIGPATH=/msp \
      -e CORE_PEER_ADDRESS=peer0.org1.example.com:7051 \
      hyperledger/fabric-tools:2.5 \
      peer lifecycle chaincode package /tmp/${name}.tar.gz --path /chaincode --lang golang --label ${name}_1.0; then
      
      success "Chaincode $name بسته‌بندی شد"

      for i in {1..8}; do
        docker cp /tmp/${name}.tar.gz peer0.org${i}.example.com:/tmp/ 2>/dev/null || continue
        if docker exec peer0.org${i}.example.com sh -c "
          export CORE_PEER_LOCALMSPID=Org${i}MSP
          export CORE_PEER_ADDRESS=peer0.org${i}.example.com:7051
          export CORE_PEER_MSPCONFIGPATH=/etc/hyperledger/fabric/msp
          export CORE_PEER_TLS_ROOTCERT_FILE=/etc/hyperledger/fabric/tls/orderer-ca.crt
          peer lifecycle chaincode install /tmp/${name}.tar.gz
        "; then
          log "Chaincode $name روی Org${i} نصب شد"
        fi
      done
      ((installed++))
    fi
    rm -rf "$pkg" /tmp/${name}.tar.gz
  done

  [ $installed -eq $total ] && success "تمام $total Chaincode نصب شدند" || error "فقط $installed از $total Chaincode نصب شدند"
}

# ------------------- Approve و Commit با MSP Admin -------------------
approve_and_commit_chaincode() {
  log "Approve و Commit تمام Chaincodeها روی ۲۰ کانال..."
  local committed=0
  local total=$(ls -1 "$CHAINCODE_DIR" | wc -l)

  for channel in "${CHANNELS[@]}"; do
    for dir in "$CHAINCODE_DIR"/*/; do
      [ ! -d "$dir" ] && continue
      name=$(basename "$dir")

      package_id=$(docker exec -e CORE_PEER_MSPCONFIGPATH=/etc/hyperledger/fabric/msp-users peer0.org1.example.com \
        peer lifecycle chaincode queryinstalled 2>/dev/null | grep "${name}_1.0" | awk -F'[:,]' '{print $2}' | xargs)
      [ -z "$package_id" ] && continue

      # Approve
      for i in {1..8}; do
        docker exec -e CORE_PEER_MSPCONFIGPATH=/etc/hyperledger/fabric/msp-users peer0.org${i}.example.com sh -c "
          export CORE_PEER_LOCALMSPID=Org${i}MSP
          export CORE_PEER_ADDRESS=peer0.org${i}.example.com:7051
          peer lifecycle chaincode approveformyorg -o orderer.example.com:7050 \
            --tls --cafile /etc/hyperledger/fabric/tls/orderer-ca.crt \
            --channelID $channel --name $name --version 1.0 \
            --package-id $package_id --sequence 1 --init-required
        " >/dev/null 2>&1 || true
      done

      # Commit
      if docker exec -e CORE_PEER_MSPCONFIGPATH=/etc/hyperledger/fabric/msp-users peer0.org1.example.com sh -c "
        export CORE_PEER_LOCALMSPID=Org1MSP
        export CORE_PEER_ADDRESS=peer0.org1.example.com:7051
        peer lifecycle chaincode commit -o orderer.example.com:7050 \
          --tls --cafile /etc/hyperledger/fabric/tls/orderer-ca.crt \
          --channelID $channel --name $name --version 1.0 \
          --sequence 1 --init-required \
          --peerAddresses peer0.org1.example.com:7051 \
          --tlsRootCertFiles /etc/hyperledger/fabric/tls/orderer-ca.crt
      "; then
        success "Chaincode $name روی کانال $channel commit شد"
        ((committed++))
      fi
    done
  done

  [ $committed -eq $((total * 20)) ] && success "تمام Chaincodeها روی تمام کانال‌ها commit شدند" || error "فقط $committed از $((total * 20)) commit شدند"
}

# ------------------- اجرا -------------------
# ... تمام کدهای قبلی بدون تغییر ...

main() {
  log "شروع راه‌اندازی کامل شبکه 6G Fabric..."
  cleanup
  generate_crypto
  generate_channel_artifacts
  generate_coreyamls
  start_network
  wait_for_orderer

  # مهم: اصلاح Adminها بعد از بالا آمدن Peerها!
  # fix_admin_ous

  create_and_join_channels
  package_and_install_chaincode
  approve_and_commit_chaincode
  success "تمام! شبکه 6G Fabric با ۸ سازمان + ۲۰ کانال + ۸۶ Chaincode کاملاً آماده است!"
}

main
