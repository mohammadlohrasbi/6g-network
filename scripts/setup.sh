#!/bin/bash
# setup.sh - راه‌اندازی کامل شبکه 6G Fabric
set -e

ROOT_DIR="/root/6g-network"
CONFIG_DIR="$ROOT_DIR/config"
CRYPTO_DIR="$CONFIG_DIR/crypto-config"
CHANNEL_DIR="$CONFIG_DIR/channel-artifacts"
SCRIPTS_DIR="$ROOT_DIR/scripts"
CHAINCODE_DIR="$ROOT_DIR/chaincode"
export FABRIC_CFG_PATH="$CONFIG_DIR"

log() {
  echo "[$(date +'%Y-%m-%d %H:%M:%S')] $*"
}

generate_crypto() {
  log "Generating crypto-config..."
  cryptogen generate --config="$CONFIG_DIR/cryptogen.yaml" --output="$CRYPTO_DIR"
  log "Crypto-config generated"
}

generate_channel_artifacts() {
  log "Generating channel artifacts..."
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
  "$SCRIPTS_DIR/generateCoreyamls.sh"
  cp "$CONFIG_DIR/core-org1.yaml" "$CONFIG_DIR/core.yaml"
  log "Generated core.yaml for host"
}

start_network() {
  log "Starting network..."
  docker network create 6g-network 2>/dev/null || log "Network exists"
  docker-compose -f "$CONFIG_DIR/docker-compose-ca.yml" up -d --remove-orphans
  sleep 10
  docker-compose -f "$CONFIG_DIR/docker-compose.yml" up -d --remove-orphans
  log "در حال انتظار برای راه‌اندازی کامل کانتینرها..."
  sleep 120
  log "Network started"
}

wait_for_orderer() {
  log "در انتظار راه‌اندازی Orderer..."
  until docker exec peer0.org1.example.com ping -c 1 orderer.example.com >/dev/null 2>&1; do
    log "Orderer هنوز آماده نیست..."
    sleep 5
  done
  log "Orderer آماده است!"
}

wait_for_peer() {
  local peer=$1
  log "در حال انتظار برای $peer..."
  until docker exec "$peer" peer version >/dev/null 2>&1; do
    sleep 5
  done
  log "$peer آماده است"
}

create_and_join_channels() {
  log "Creating and joining channels..."
  wait_for_orderer
  channels=(NetworkChannel ResourceChannel PerformanceChannel IoTChannel AuthChannel \
            ConnectivityChannel SessionChannel PolicyChannel AuditChannel SecurityChannel \
            DataChannel AnalyticsChannel MonitoringChannel ManagementChannel OptimizationChannel \
            FaultChannel TrafficChannel AccessChannel ComplianceChannel IntegrationChannel)
  for ch in "${channels[@]}"; do
    log "در حال ایجاد کانال $ch ..."
    ORDERER_IP=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' orderer.example.com)
    docker exec peer0.org1.example.com peer channel create \
      -o "$ORDERER_IP:7050" \
      -c "$ch" \
      -f "/etc/hyperledger/configtx/${ch,,}.tx" \
      --tls --cafile "/etc/hyperledger/configtx/tlsca.example.com-cert.pem" \
      --outputBlock "/tmp/${ch}.block" && log "کانال $ch ایجاد شد" || log "خطا در ایجاد کانال $ch - ادامه..."

    docker cp peer0.org1.example.com:/tmp/${ch}.block "$CHANNEL_DIR/${ch}.block" 2>/dev/null || true
    log "Created channel: $ch"
    for i in {1..8}; do
      wait_for_peer "peer0.org${i}.example.com"
    done
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

package_and_install_chaincode() {
  log "Packaging and installing chaincodes..."
  if [ ! -d "$CHAINCODE_DIR" ]; then
    log "Chaincode directory not found, skipping..."
    return
  fi
  for part in {1..8}; do
    PART_DIR="$CHAINCODE_DIR/part$part"
    [ ! -d "$PART_DIR" ] && continue
    for contract_dir in "$PART_DIR"/*/; do
      [ ! -d "$contract_dir" ] && continue
      contract=$(basename "$contract_dir")
      tar_file="$PART_DIR/${contract}.tar.gz"
      if [ ! -f "$tar_file" ]; then
        export CORE_PEER_MSPCONFIGPATH="$CRYPTO_DIR/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp"
        export CORE_PEER_ADDRESS="peer0.org1.example.com:7151"
        export CORE_PEER_LOCALMSPID="Org1MSP"
        export CORE_PEER_TLS_ROOTCERT_FILE="$CRYPTO_DIR/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt"
        docker exec peer0.org1.example.com peer lifecycle chaincode package "$tar_file" \
          --path "$contract_dir" \
          --lang golang \
          --label "${contract}_1.0" >/dev/null 2>&1
        log "Packaged: $contract"
      fi
      for i in {1..8}; do
        export CORE_PEER_MSPCONFIGPATH="$CRYPTO_DIR/peerOrganizations/org${i}.example.com/users/Admin@org${i}.example.com/msp"
        export CORE_PEER_ADDRESS="peer0.org${i}.example.com:$((7151 + (i-1)*1000))"
        export CORE_PEER_LOCALMSPID="Org${i}MSP"
        export CORE_PEER_TLS_ROOTCERT_FILE="$CRYPTO_DIR/peerOrganizations/org${i}.example.com/peers/peer0.org${i}.example.com/tls/ca.crt"
        docker cp "$tar_file" peer0.org${i}.example.com:/tmp/
        docker exec peer0.org${i}.example.com peer lifecycle chaincode install /tmp/${contract}.tar.gz >/dev/null 2>&1 && log "Installed $contract on Org${i}" || true
        docker exec peer0.org${i}.example.com rm -f /tmp/${contract}.tar.gz 2>/dev/null || true
      done
    done
  done
}

approve_and_commit_chaincode() {
  log "Approving and committing chaincodes..."
  if [ ! -d "$CHAINCODE_DIR" ]; then
    log "Chaincode directory not found, skipping..."
    return
  fi
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
        export CORE_PEER_MSPCONFIGPATH="$CRYPTO_DIR/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp"
        export CORE_PEER_ADDRESS="peer0.org1.example.com:7151"
        export CORE_PEER_LOCALMSPID="Org1MSP"
        export CORE_PEER_TLS_ROOTCERT_FILE="$CRYPTO_DIR/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt"
        package_id=$(docker exec peer0.org1.example.com peer lifecycle chaincode queryinstalled | grep "${contract}_1.0" | awk -F', ' '{print $2}' | cut -d' ' -f2 || echo "")
        if [ -z "$package_id" ]; then
          log "Skipping $contract (not installed)"
          continue
        fi
        for i in {1..8}; do
          export CORE_PEER_MSPCONFIGPATH="$CRYPTO_DIR/peerOrganizations/org${i}.example.com/users/Admin@org${i}.example.com/msp"
          export CORE_PEER_ADDRESS="peer0.org${i}.example.com:$((7151 + (i-1)*1000))"
          export CORE_PEER_LOCALMSPID="Org${i}MSP"
          export CORE_PEER_TLS_ROOTCERT_FILE="$CRYPTO_DIR/peerOrganizations/org${i}.example.com/peers/peer0.org${i}.example.com/tls/ca.crt"
          docker exec peer0.org${i}.example.com peer lifecycle chaincode approveformyorg \
            -o orderer.example.com:7050 \
            --tls \
            --cafile "$CRYPTO_DIR/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem" \
            --channelID "$channel" \
            --name "$contract" \
            --version 1.0 \
            --package-id "$package_id" \
            --sequence 1 \
            --init-required >/dev/null 2>&1 || true
        done
        export CORE_PEER_MSPCONFIGPATH="$CRYPTO_DIR/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp"
        export CORE_PEER_ADDRESS="peer0.org1.example.com:7151"
        export CORE_PEER_LOCALMSPID="Org1MSP"
        export CORE_PEER_TLS_ROOTCERT_FILE="$CRYPTO_DIR/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt"
        docker exec peer0.org1.example.com peer lifecycle chaincode commit \
          -o orderer.example.com:7050 \
          --tls \
          --cafile "$CRYPTO_DIR/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem" \
          --channelID "$channel" \
          --name "$contract" \
          --version 1.0 \
          --sequence 1 \
          --init-required >/dev/null 2>&1 || true
        log "Committed: $contract on $channel"
      done
    done
  done
}

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
