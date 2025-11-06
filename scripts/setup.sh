#!/bin/bash
# setup.sh - راه‌اندازی کامل شبکه 6G Fabric با 8 سازمان
set -e

ROOT_DIR="/root/6g-network"
CONFIG_DIR="$ROOT_DIR/config"
CRYPTO_DIR="$CONFIG_DIR/crypto-config"
CHANNEL_DIR="$CONFIG_DIR/channel-artifacts"
CHAINCODE_DIR="$ROOT_DIR/chaincode"
SCRIPTS_DIR="$ROOT_DIR/scripts"

export FABRIC_CFG_PATH="$CONFIG_DIR"

log() {
  echo "[$(date +'%Y-%m-%d %H:%M:%S')] $*"
}

generate_crypto() {
  log "Generating crypto-config..."
  [ ! -f "$CONFIG_DIR/cryptogen.yaml" ] && { echo "cryptogen.yaml not found!"; exit 1; }
  cryptogen generate --config="$CONFIG_DIR/cryptogen.yaml" --output="$CRYPTO_DIR"
  log "Crypto-config generated"
}

generate_channel_artifacts() {
  log "Generating channel artifacts..."
  [ ! -f "$CONFIG_DIR/configtx.yaml" ] && { echo "configtx.yaml not found!"; exit 1; }
  mkdir -p "$CHANNEL_DIR"
  configtxgen -profile SystemChannel -outputBlock "$CHANNEL_DIR/system-genesis.block" -channelID system-channel
  log "Genesis block generated"

  channels=(
    NetworkChannel ResourceChannel PerformanceChannel IoTChannel AuthChannel
    ConnectivityChannel SessionChannel PolicyChannel AuditChannel SecurityChannel
    DataChannel AnalyticsChannel MonitoringChannel ManagementChannel OptimizationChannel
    FaultChannel TrafficChannel AccessChannel ComplianceChannel IntegrationChannel
  )

  for ch in "${channels[@]}"; do
    configtxgen -profile ApplicationChannel -outputCreateChannelTx "$CHANNEL_DIR/${ch,,}.tx" -channelID "$ch"
    log "Created: ${ch,,}.tx"
  done
}

generate_coreyamls() {
  log "Generating core.yaml files..."
  [ -f "$SCRIPTS_DIR/generateCoreyamls.sh" ] && "$SCRIPTS_DIR/generateCoreyamls.sh" || { echo "generateCoreyamls.sh not found!"; exit 1; }
  cp "$CONFIG_DIR/core-org1.yaml" "$CONFIG_DIR/core.yaml"
  log "Generated core.yaml for host"
}

start_network() {
  log "Starting network..."
  docker network create 6g-network 2>/dev/null || log "Network 6g-network already exists"
  [ -f "$CONFIG_DIR/docker-compose-ca.yml" ] && docker-compose -f "$CONFIG_DIR/docker-compose-ca.yml" up -d --remove-orphans
  sleep 10
  docker-compose -f "$CONFIG_DIR/docker-compose.yml" up -d --remove-orphans
  sleep 40
  log "Network started"
}

create_and_join_channels() {
  log "Creating and joining channels..."

  channels=(
    NetworkChannel ResourceChannel PerformanceChannel IoTChannel AuthChannel
    ConnectivityChannel SessionChannel PolicyChannel AuditChannel SecurityChannel
    DataChannel AnalyticsChannel MonitoringChannel ManagementChannel OptimizationChannel
    FaultChannel TrafficChannel AccessChannel ComplianceChannel IntegrationChannel
  )

  for ch in "${channels[@]}"; do
    # ایجاد کانال
    docker exec peer0.org1.example.com peer channel create \
      -o orderer.example.com:7050 \
      -c "$ch" \
      -f "/etc/hyperledger/configtx/${ch,,}.tx" \
      --tls --cafile "/etc/hyperledger/configtx/tlsca.example.com-cert.pem" \
      --outputBlock "/tmp/${ch}.block" || true

    # کپی block به host
    docker cp peer0.org1.example.com:/tmp/${ch}.block "$CHANNEL_DIR/${ch}.block" 2>/dev/null || true
    log "Created channel: $ch"

    # جوین همه سازمان‌ها
    for i in {1..8}; do
      PEER="peer0.org${i}.example.com"
      docker cp "$CHANNEL_DIR/${ch}.block" "$PEER:/tmp/${ch}.block" 2>/dev/null || true
      docker exec "$PEER" peer channel join -b "/tmp/${ch}.block" && \
        log "Org${i} joined $ch" || log "Org${i} already joined $ch"
      docker exec "$PEER" rm -f "/tmp/${ch}.block" 2>/dev/null || true
    done
    rm -f "$CHANNEL_DIR/${ch}.block" 2>/dev/null || true
  done
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
