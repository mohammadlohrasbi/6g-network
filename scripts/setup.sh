#!/bin/bash

# setup.sh - راه‌اندازی کامل شبکه 6G Fabric با 8 سازمان
# شامل: تولید crypto, channel, core.yaml, رفع orphan, رفع network exists, نصب chaincode
set -e

# متغیرهای اصلی
ROOT_DIR="/root/6g-network"
CONFIG_DIR="$ROOT_DIR/config"
CRYPTO_DIR="$CONFIG_DIR/crypto-config"
CHANNEL_DIR="$CONFIG_DIR/channel-artifacts"
CHAINCODE_DIR="$ROOT_DIR/chaincode"
SCRIPTS_DIR="$ROOT_DIR/scripts"

# تنظیم مسیر FABRIC
export FABRIC_CFG_PATH="$CONFIG_DIR"

# تابع لاگ
log() {
  echo "[$(date +'%Y-%m-%d %H:%M:%S')] $*"
}

# مرحله 1: تولید crypto-config
generate_crypto() {
  log "Generating crypto-config..."
  if [ ! -f "$CONFIG_DIR/cryptogen.yaml" ]; then
    echo "خطا: cryptogen.yaml یافت نشد در $CONFIG_DIR"
    exit 1
  fi
  cryptogen generate --config="$CONFIG_DIR/cryptogen.yaml" --output="$CRYPTO_DIR"
  log "Crypto-config generated in $CRYPTO_DIR"
}

# مرحله 2: تولید channel artifacts و genesis block
generate_channel_artifacts() {
  log "Generating channel artifacts and genesis block..."
  if [ ! -f "$CONFIG_DIR/configtx.yaml" ]; then
    echo "خطا: configtx.yaml یافت نشد در $CONFIG_DIR"
    exit 1
  fi
  mkdir -p "$CHANNEL_DIR"

  # تولید genesis block
  configtxgen -profile SystemChannel \
    -outputBlock "$CHANNEL_DIR/system-genesis.block" \
    -channelID system-channel
  log "Generated: $CHANNEL_DIR/system-genesis.block"

  # لیست کانال‌ها
  channels=(
    NetworkChannel ResourceChannel PerformanceChannel IoTChannel AuthChannel
    ConnectivityChannel SessionChannel PolicyChannel AuditChannel SecurityChannel
    DataChannel AnalyticsChannel MonitoringChannel ManagementChannel OptimizationChannel
    FaultChannel TrafficChannel AccessChannel ComplianceChannel IntegrationChannel
  )

  # تولید فایل .tx برای هر کانال
  for channel in "${channels[@]}"; do
    configtxgen -profile ApplicationChannel \
      -outputCreateChannelTx "$CHANNEL_DIR/${channel,,}.tx" \
      -channelID "$channel"
    log "Created: $CHANNEL_DIR/${channel,,}.tx"
  done
  log "All channel artifacts generated in $CHANNEL_DIR"
}

# مرحله 3: تولید core.yaml برای هر Peer
generate_coreyamls() {
  log "Generating core.yaml files..."
  if [ -f "$SCRIPTS_DIR/generateCoreyamls.sh" ]; then
    "$SCRIPTS_DIR/generateCoreyamls.sh"
    log "Generated 8 core-orgX.yaml files in $CONFIG_DIR"
  else
    log "generateCoreyamls.sh not found. Skipping."
  fi
}

# مرحله 4: راه‌اندازی شبکه Docker (رفع orphan و network exists)
start_network() {
  log "Starting network from $CONFIG_DIR..."
  cd "$CONFIG_DIR"
  docker network create 6g-network 2>/dev/null || log "Network 6g-network already exists"

  log "Starting CA servers..."
  if [ -f "$CONFIG_DIR/docker-compose-ca.yml" ]; then
    docker-compose -f "$CONFIG_DIR/docker-compose-ca.yml" up -d --remove-orphans
  else
    log "docker-compose-ca.yml not found. Skipping CA startup."
  fi
  sleep 10

  log "Starting Orderer and Peers..."
  if [ -f "$CONFIG_DIR/docker-compose.yml" ]; then
    docker-compose -f "$CONFIG_DIR/docker-compose.yml" up -d --remove-orphans
  else
    echo "خطا: docker-compose.yml یافت نشد در $CONFIG_DIR"
    exit 1
  fi
  sleep 20
  cd - > /dev/null
  log "Network started. Use 'docker ps' to verify."
}

# مرحله 5: ایجاد و جوین کردن کانال‌ها
create_and_join_channels() {
  log "Creating and joining channels..."
  cd "$CONFIG_DIR"

  channels=(
    NetworkChannel ResourceChannel PerformanceChannel IoTChannel AuthChannel
    ConnectivityChannel SessionChannel PolicyChannel AuditChannel SecurityChannel
    DataChannel AnalyticsChannel MonitoringChannel ManagementChannel OptimizationChannel
    FaultChannel TrafficChannel AccessChannel ComplianceChannel IntegrationChannel
  )

  for i in {1..8}; do
    export CORE_PEER_MSPCONFIGPATH="$CRYPTO_DIR/peerOrganizations/org${i}.example.com/users/Admin@org${i}.example.com/msp"
    export CORE_PEER_ADDRESS="peer0.org${i}.example.com:$((7151 + (i-1)*1000))"
    export CORE_PEER_LOCALMSPID="Org${i}MSP"
    export CORE_PEER_TLS_ROOTCERT_FILE="$CRYPTO_DIR/peerOrganizations/org${i}.example.com/peers/peer0.org${i}.example.com/tls/ca.crt"

    for channel in "${channels[@]}"; do
      # فقط Org1 کانال را ایجاد می‌کند
      if [ $i -eq 1 ]; then
        peer channel create \
          -o orderer.example.com:7050 \
          -c "$channel" \
          -f "$CHANNEL_DIR/${channel,,}.tx" \
          --tls \
          --cafile "$CRYPTO_DIR/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem" \
          --outputBlock "$CHANNEL_DIR/${channel}.block" || true
        log "Created channel: $channel"
      fi

      # جوین به کانال
      peer channel join -b "$CHANNEL_DIR/${channel}.block" && log "Org${i} joined $channel" || log "Org${i} already joined $channel"
    done
  done
  cd - > /dev/null
}

# مرحله 6: بسته‌بندی و نصب chaincode
package_and_install_chaincode() {
  log "Packaging and installing chaincodes..."

  for part in {1..10}; do
    PART_DIR="$CHAINCODE_DIR/part$part"
    [ ! -d "$PART_DIR" ] && continue

    for contract_dir in "$PART_DIR"/*/; do
      [ ! -d "$contract_dir" ] && continue
      contract=$(basename "$contract_dir")
      tar_file="$PART_DIR/${contract}.tar.gz"

      # بسته‌بندی
      if [ ! -f "$tar_file" ]; then
        peer lifecycle chaincode package "$tar_file" \
          --path "$contract_dir" \
          --lang golang \
          --label "${contract}_1.0"
        log "Packaged: $contract"
      fi

      # نصب روی همه Peerها
      for i in {1..8}; do
        export CORE_PEER_MSPCONFIGPATH="$CRYPTO_DIR/peerOrganizations/org${i}.example.com/users/Admin@org${i}.example.com/msp"
        export CORE_PEER_ADDRESS="peer0.org${i}.example.com:$((7151 + (i-1)*1000))"
        export CORE_PEER_LOCALMSPID="Org${i}MSP"
        export CORE_PEER_TLS_ROOTCERT_FILE="$CRYPTO_DIR/peerOrganizations/org${i}.example.com/peers/peer0.org${i}.example.com/tls/ca.crt"

        peer lifecycle chaincode install "$tar_file" > /dev/null 2>&1 && log "Installed $contract on Org${i}" || true
      done
    done
  done
}

# مرحله 7: تأیید و commit chaincode
approve_and_commit_chaincode() {
  log "Approving and committing chaincodes..."

  channels=(
    NetworkChannel ResourceChannel PerformanceChannel IoTChannel AuthChannel
    ConnectivityChannel SessionChannel PolicyChannel AuditChannel SecurityChannel
    DataChannel AnalyticsChannel MonitoringChannel ManagementChannel OptimizationChannel
    FaultChannel TrafficChannel AccessChannel ComplianceChannel IntegrationChannel
  )

  for channel in "${channels[@]}"; do
    for part in {1..10}; do
      PART_DIR="$CHAINCODE_DIR/part$part"
      [ ! -d "$PART_DIR" ] && continue

      for contract_dir in "$PART_DIR"/*/; do
        [ ! -d "$contract_dir" ] && continue
        contract=$(basename "$contract_dir")

        # دریافت package_id
        package_id=$(peer lifecycle chaincode queryinstalled | grep "${contract}_1.0" | awk -F', ' '{print $2}' | cut -d' ' -f2 || echo "")
        if [ -z "$package_id" ]; then
          log "Skipping $contract (not installed)"
          continue
        fi

        # تأیید برای همه سازمان‌ها
        for i in {1..8}; do
          export CORE_PEER_MSPCONFIGPATH="$CRYPTO_DIR/peerOrganizations/org${i}.example.com/users/Admin@org${i}.example.com/msp"
          export CORE_PEER_ADDRESS="peer0.org${i}.example.com:$((7151 + (i-1)*1000))"
          export CORE_PEER_LOCALMSPID="Org${i}MSP"
          export CORE_PEER_TLS_ROOTCERT_FILE="$CRYPTO_DIR/peerOrganizations/org${i}.example.com/peers/peer0.org${i}.example.com/tls/ca.crt"

          peer lifecycle chaincode approveformyorg \
            -o orderer.example.com:7050 \
            --tls \
            --cafile "$CRYPTO_DIR/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem" \
            --channelID "$channel" \
            --name "$contract" \
            --version 1.0 \
            --package-id "$package_id" \
            --sequence 1 \
            --init-required > /dev/null 2>&1 || true
        done

        # Commit فقط یک بار (از Org1)
        export CORE_PEER_MSPCONFIGPATH="$CRYPTO_DIR/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp"
        export CORE_PEER_ADDRESS="peer0.org1.example.com:7151"
        export CORE_PEER_LOCALMSPID="Org1MSP"
        export CORE_PEER_TLS_ROOTCERT_FILE="$CRYPTO_DIR/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt"

        peer lifecycle chaincode commit \
          -o orderer.example.com:7050 \
          --tls \
          --cafile "$CRYPTO_DIR/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem" \
          --channelID "$channel" \
          --name "$contract" \
          --version 1.0 \
          --sequence 1 \
          --init-required \
          --peerAddresses peer0.org1.example.com:7151 \
          --tlsRootCertFiles "$CRYPTO_DIR/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt" \
          --peerAddresses peer0.org2.example.com:8151 \
          --tlsRootCertFiles "$CRYPTO_DIR/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/ca.crt" \
          > /dev/null 2>&1 || true

        log "Committed: $contract on $channel"
      done
    done
  done
}

# اجرای اصلی
main() {
  log "Starting 6G Network Setup..."
  generate_crypto
  generate_channel_artifacts
  generate_coreyamls
  start_network
  create_and_join_channels
  package_and_install_chaincode
  approve_and_commit_chaincode
  log "6G Network setup completed successfully!"
  log "Use 'docker ps' to check running containers."
}

main
