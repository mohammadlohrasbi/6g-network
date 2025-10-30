#!/bin/bash

# setup.sh - راه‌اندازی کامل شبکه 6G Fabric با 8 سازمان
# شامل: تولید crypto, channel, core.yaml, راه‌اندازی Docker, ایجاد کانال, نصب chaincode

set -e  # توقف در اولین خطا

ROOT_DIR="/root/6g-network"
CONFIG_DIR="$ROOT_DIR/config"
CRYPTO_DIR="$CONFIG_DIR/crypto-config"
CHANNEL_DIR="$CONFIG_DIR/channel-artifacts"
CHAINCODE_DIR="$ROOT_DIR/chaincode"
SCRIPTS_DIR="$ROOT_DIR/scripts"

# تنظیم مسیر FABRIC_CFG_PATH
export FABRIC_CFG_PATH="$CONFIG_DIR"

# تابع نمایش پیام
log() {
  echo "[$(date +'%Y-%m-%d %H:%M:%S')] $*"
}

# مرحله 1: تولید crypto-config
generate_crypto() {
  log "Generating crypto-config..."
  cryptogen generate --config="$CONFIG_DIR/cryptogen.yaml" --output="$CRYPTO_DIR"
  log "Crypto-config generated in $CRYPTO_DIR"
}

# مرحله 2: تولید channel artifacts و genesis block
generate_channel_artifacts() {
  log "Generating channel artifacts and genesis block..."
  configtxgen -profile EightOrgsGenesis -channelID system-channel -outputBlock "$CHANNEL_DIR/genesis.block"
  
  # ایجاد کانال‌های 19 تایی
  channels=(
    NetworkChannel ResourceChannel PerformanceChannel IoTChannel AuthChannel
    ConnectivityChannel SessionChannel PolicyChannel AuditChannel SecurityChannel
    DataChannel AnalyticsChannel MonitoringChannel OptimizationChannel FaultChannel
    TrafficChannel AccessChannel ComplianceChannel IntegrationChannel
  )
  
  for channel in "${channels[@]}"; do
    configtxgen -profile EightOrgsChannel -outputCreateChannelTx "$CHANNEL_DIR/${channel,,}.tx" -channelID "$channel"
    log "  Created: $CHANNEL_DIR/${channel,,}.tx"
  done
  log "All channel artifacts generated in $CHANNEL_DIR"
}

# مرحله 3: تولید core.yaml
generate_coreyamls() {
  log "Generating core.yaml files..."
  "$SCRIPTS_DIR/generateCoreyamls.sh"
}

# مرحله 4: راه‌اندازی شبکه Docker
start_network() {
  log "Creating Docker network: 6g-network"
  docker network create 6g-network || true

  log "Starting CA servers..."
  docker-compose -f "$CONFIG_DIR/docker-compose-ca.yml" up -d

  log "Waiting 10 seconds for CAs to start..."
  sleep 10

  log "Starting Orderer and Peers..."
  docker-compose -f "$CONFIG_DIR/docker-compose.yml" up -d

  log "Waiting 15 seconds for nodes to initialize..."
  sleep 15
}

# مرحله 5: ایجاد و جوین کردن کانال‌ها
create_and_join_channels() {
  log "Creating and joining channels..."

  channels=(
    NetworkChannel ResourceChannel PerformanceChannel IoTChannel AuthChannel
    ConnectivityChannel SessionChannel PolicyChannel AuditChannel SecurityChannel
    DataChannel AnalyticsChannel MonitoringChannel OptimizationChannel FaultChannel
    TrafficChannel AccessChannel ComplianceChannel IntegrationChannel
  )

  for i in {1..8}; do
    export CORE_PEER_MSPCONFIGPATH="$CRYPTO_DIR/peerOrganizations/org${i}.example.com/users/Admin@org${i}.example.com/msp"
    export CORE_PEER_ADDRESS="peer0.org${i}.example.com:$((7151 + (i-1)*1000))"
    export CORE_PEER_LOCALMSPID="Org${i}MSP"
    export CORE_PEER_TLS_ROOTCERT_FILE="$CRYPTO_DIR/peerOrganizations/org${i}.example.com/peers/peer0.org${i}.example.com/tls/ca.crt"

    for channel in "${channels[@]}"; do
      # ایجاد کانال (فقط یک بار)
      if [ $i -eq 1 ]; then
        peer channel create -o orderer.example.com:7050 \
          -c "$channel" \
          -f "$CHANNEL_DIR/${channel,,}.tx" \
          --tls --cafile "$CRYPTO_DIR/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem" \
          --outputBlock "$CHANNEL_DIR/${channel}.block"
        log "  Created channel: $channel"
      fi

      # جوین به کانال
      peer channel join -b "$CHANNEL_DIR/${channel}.block"
      log "  Org${i} joined $channel"
    done
  done
}

# مرحله 6: بسته‌بندی و نصب chaincode
package_and_install_chaincode() {
  log "Packaging and installing chaincodes..."

  for part in {1..10}; do
    PART_DIR="$CHAINCODE_DIR/part$part"
    [ ! -d "$PART_DIR" ] && continue

    for contract_dir in "$PART_DIR"/*/; do
      contract=$(basename "$contract_dir")
      tar_file="$PART_DIR/${contract}.tar.gz"

      # بسته‌بندی
      peer lifecycle chaincode package "$tar_file" \
        --path "$contract_dir" \
        --lang golang \
        --label "${contract}_1.0"

      # نصب روی همه Peerها
      for i in {1..8}; do
        export CORE_PEER_MSPCONFIGPATH="$CRYPTO_DIR/peerOrganizations/org${i}.example.com/users/Admin@org${i}.example.com/msp"
        export CORE_PEER_ADDRESS="peer0.org${i}.example.com:$((7151 + (i-1)*1000))"
        export CORE_PEER_LOCALMSPID="Org${i}MSP"
        export CORE_PEER_TLS_ROOTCERT_FILE="$CRYPTO_DIR/peerOrganizations/org${i}.example.com/peers/peer0.org${i}.example.com/tls/ca.crt"

        peer lifecycle chaincode install "$tar_file" > /dev/null 2>&1
      done
      log "  Installed: $contract"
    done
  done
}

# مرحله 7: تأیید و commit chaincode
approve_and_commit_chaincode() {
  log "Approving and committing chaincodes..."

  channels=(
    NetworkChannel ResourceChannel PerformanceChannel IoTChannel AuthChannel
    ConnectivityChannel SessionChannel PolicyChannel AuditChannel SecurityChannel
    DataChannel AnalyticsChannel MonitoringChannel OptimizationChannel FaultChannel
    TrafficChannel AccessChannel ComplianceChannel IntegrationChannel
  )

  for channel in "${channels[@]}"; do
    for part in {1..10}; do
      PART_DIR="$CHAINCODE_DIR/part$part"
      [ ! -d "$PART_DIR" ] && continue

      for contract_dir in "$PART_DIR"/*/; do
        contract=$(basename "$contract_dir")
        package_id=$(peer lifecycle chaincode queryinstalled | grep "${contract}_1.0" | awk -F', ' '{print $2}' | cut -d' ' -f2)

        if [ -z "$package_id" ]; then
          log "  Skipping $contract (not installed)"
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
            --tls --cafile "$CRYPTO_DIR/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem" \
            --channelID "$channel" \
            --name "$contract" \
            --version 1.0 \
            --package-id "$package_id" \
            --sequence 1 \
            --init-required > /dev/null 2>&1
        done

        # Commit (فقط یک بار)
        if [ $i -eq 1 ]; then
          peer lifecycle chaincode commit \
            -o orderer.example.com:7050 \
            --tls --cafile "$CRYPTO_DIR/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem" \
            --channelID "$channel" \
            --name "$contract" \
            --version 1.0 \
            --sequence 1 \
            --init-required \
            --peerAddresses peer0.org1.example.com:7151 \
            --tlsRootCertFiles "$CRYPTO_DIR/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt" > /dev/null 2>&1
          log "  Committed: $contract on $channel"
        fi
      done
    done
  done
}

# اجرای مراحل
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
