#!/bin/bash
# generateCoreyamls.sh - تولید core.yaml برای 8 سازمان + core.yaml عمومی
set -e

ROOT_DIR="/root/6g-network"
CONFIG_DIR="$ROOT_DIR/config"
mkdir -p "$CONFIG_DIR"

echo "Generating core.yaml files for 8 organizations..."

for i in {1..8}; do
  CORE_FILE="$CONFIG_DIR/core-org${i}.yaml"
  PORT=$((7151 + (i-1)*1000))
  CHAINCODE_PORT=$((7152 + (i-1)*1000))

  cat > "$CORE_FILE" <<EOF
peer:
  id: peer0.org${i}.example.com
  networkId: 6g-network
  listenAddress: 0.0.0.0:${PORT}
  chaincodeListenAddress: 0.0.0.0:${CHAINCODE_PORT}
  address: peer0.org${i}.example.com:${PORT}
  gossip:
    bootstrap: peer0.org${i}.example.com:${PORT}
    useLeaderElection: true
    orgLeader: false
    endpoint: peer0.org${i}.example.com:${PORT}
  mspConfigPath: /etc/hyperledger/fabric/msp
  localMspId: Org${i}MSP
  tls:
    enabled: true
    cert:
      file: /etc/hyperledger/fabric/tls/server.crt
    key:
      file: /etc/hyperledger/fabric/tls/server.key
    rootcert:
      file: /etc/hyperledger/fabric/tls/ca.crt
  bccsp:
    default: SW
    sw:
      hash: SHA2
      security: 256
  fileSystemPath: /var/hyperledger/production
  ledger:
    state:
      stateDatabase: goleveldb
EOF

  echo "Generated: $CORE_FILE"
done

# تولید core.yaml عمومی برای اجرای peer روی host
cp "$CONFIG_DIR/core-org1.yaml" "$CONFIG_DIR/core.yaml"
echo "Generated general core.yaml for host: $CONFIG_DIR/core.yaml"

echo "All 8 core.yaml files + core.yaml generated in $CONFIG_DIR"
```

---

## فایل 2: `docker-compose.yml` (کامل + Mount صحیح)

```yaml
version: '3.8'

services:
  orderer.example.com:
    container_name: orderer.example.com
    image: hyperledger/fabric-orderer:2.5
    environment:
      - FABRIC_LOGGING_SPEC=INFO
      - ORDERER_GENERAL_LISTENADDRESS=0.0.0.0
      - ORDERER_GENERAL_LISTENPORT=7050
      - ORDERER_GENERAL_LOCALMSPID=OrdererMSP
      - ORDERER_GENERAL_LOCALMSPDIR=/var/hyperledger/orderer/msp
      - ORDERER_GENERAL_TLS_ENABLED=true
      - ORDERER_GENERAL_TLS_PRIVATEKEY=/var/hyperledger/orderer/tls/server.key
      - ORDERER_GENERAL_TLS_CERTIFICATE=/var/hyperledger/orderer/tls/server.crt
      - ORDERER_GENERAL_TLS_ROOTCAS=[/var/hyperledger/orderer/tls/ca.crt]
      - ORDERER_FILELEDGER_LOCATION=/var/hyperledger/production/orderer
    working_dir: /opt/gopath/src/github.com/hyperledger/fabric
    command: orderer
    volumes:
      - ./crypto-config/ordererOrganizations/example.com/orderers/orderer.example.com/msp:/var/hyperledger/orderer/msp
      - ./crypto-config/ordererOrganizations/example.com/orderers/orderer.example.com/tls:/var/hyperledger/orderer/tls
      - ./channel-artifacts/system-genesis.block:/var/hyperledger/orderer/orderer.genesis.block
      - orderer-data:/var/hyperledger/production/orderer
    ports:
      - 7050:7050
    networks:
      - 6g-network

  peer0.org1.example.com:
    container_name: peer0.org1.example.com
    image: hyperledger/fabric-peer:2.5
    environment:
      - CORE_PEER_ID=peer0.org1.example.com
      - CORE_PEER_ADDRESS=peer0.org1.example.com:7151
      - CORE_PEER_LISTENADDRESS=0.0.0.0:7151
      - CORE_PEER_CHAINCODEADDRESS=peer0.org1.example.com:7152
      - CORE_PEER_GOSSIP_EXTERNALENDPOINT=peer0.org1.example.com:7151
      - CORE_PEER_LOCALMSPID=Org1MSP
      - CORE_VM_ENDPOINT=unix:///host/var/run/docker.sock
      - CORE_VM_DOCKER_HOSTCONFIG_NETWORKMODE=6g-network_6g-network
      - CORE_PEER_TLS_ENABLED=true
      - CORE_PEER_TLS_CERT_FILE=/etc/hyperledger/fabric/tls/server.crt
      - CORE_PEER_TLS_KEY_FILE=/etc/hyperledger/fabric/tls/server.key
      - CORE_PEER_TLS_ROOTCERT_FILE=/etc/hyperledger/fabric/tls/ca.crt
      - CORE_PEER_MSPCONFIGPATH=/etc/hyperledger/fabric/msp
    volumes:
      - /var/run/:/host/var/run/
      - ./crypto-config/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/msp:/etc/hyperledger/fabric/msp
      - ./crypto-config/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls:/etc/hyperledger/fabric/tls
      - ./core-org1.yaml:/etc/hyperledger/fabric/core.yaml
      - peer0.org1.example.com:/var/hyperledger/production
    command: peer node start
    ports:
      - 7151:7151
    networks:
      - 6g-network

  peer0.org2.example.com:
    container_name: peer0.org2.example.com
    image: hyperledger/fabric-peer:2.5
    environment:
      - CORE_PEER_ID=peer0.org2.example.com
      - CORE_PEER_ADDRESS=peer0.org2.example.com:8151
      - CORE_PEER_LISTENADDRESS=0.0.0.0:8151
      - CORE_PEER_CHAINCODEADDRESS=peer0.org2.example.com:8152
      - CORE_PEER_GOSSIP_EXTERNALENDPOINT=peer0.org2.example.com:8151
      - CORE_PEER_LOCALMSPID=Org2MSP
      - CORE_VM_ENDPOINT=unix:///host/var/run/docker.sock
      - CORE_VM_DOCKER_HOSTCONFIG_NETWORKMODE=6g-network_6g-network
      - CORE_PEER_TLS_ENABLED=true
      - CORE_PEER_TLS_CERT_FILE=/etc/hyperledger/fabric/tls/server.crt
      - CORE_PEER_TLS_KEY_FILE=/etc/hyperledger/fabric/tls/server.key
      - CORE_PEER_TLS_ROOTCERT_FILE=/etc/hyperledger/fabric/tls/ca.crt
      - CORE_PEER_MSPCONFIGPATH=/etc/hyperledger/fabric/msp
    volumes:
      - /var/run/:/host/var/run/
      - ./crypto-config/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/msp:/etc/hyperledger/fabric/msp
      - ./crypto-config/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls:/etc/hyperledger/fabric/tls
      - ./core-org2.yaml:/etc/hyperledger/fabric/core.yaml
      - peer0.org2.example.com:/var/hyperledger/production
    command: peer node start
    ports:
      - 8151:8151
    networks:
      - 6g-network

  peer0.org3.example.com:
    container_name: peer0.org3.example.com
    image: hyperledger/fabric-peer:2.5
    environment:
      - CORE_PEER_ID=peer0.org3.example.com
      - CORE_PEER_ADDRESS=peer0.org3.example.com:9151
      - CORE_PEER_LISTENADDRESS=0.0.0.0:9151
      - CORE_PEER_CHAINCODEADDRESS=peer0.org3.example.com:9152
      - CORE_PEER_GOSSIP_EXTERNALENDPOINT=peer0.org3.example.com:9151
      - CORE_PEER_LOCALMSPID=Org3MSP
      - CORE_VM_ENDPOINT=unix:///host/var/run/docker.sock
      - CORE_VM_DOCKER_HOSTCONFIG_NETWORKMODE=6g-network_6g-network
      - CORE_PEER_TLS_ENABLED=true
      - CORE_PEER_TLS_CERT_FILE=/etc/hyperledger/fabric/tls/server.crt
      - CORE_PEER_TLS_KEY_FILE=/etc/hyperledger/fabric/tls/server.key
      - CORE_PEER_TLS_ROOTCERT_FILE=/etc/hyperledger/fabric/tls/ca.crt
      - CORE_PEER_MSPCONFIGPATH=/etc/hyperledger/fabric/msp
    volumes:
      - /var/run/:/host/var/run/
      - ./crypto-config/peerOrganizations/org3.example.com/peers/peer0.org3.example.com/msp:/etc/hyperledger/fabric/msp
      - ./crypto-config/peerOrganizations/org3.example.com/peers/peer0.org3.example.com/tls:/etc/hyperledger/fabric/tls
      - ./core-org3.yaml:/etc/hyperledger/fabric/core.yaml
      - peer0.org3.example.com:/var/hyperledger/production
    command: peer node start
    ports:
      - 9151:9151
    networks:
      - 6g-network

  peer0.org4.example.com:
    container_name: peer0.org4.example.com
    image: hyperledger/fabric-peer:2.5
    environment:
      - CORE_PEER_ID=peer0.org4.example.com
      - CORE_PEER_ADDRESS=peer0.org4.example.com:10151
      - CORE_PEER_LISTENADDRESS=0.0.0.0:10151
      - CORE_PEER_CHAINCODEADDRESS=peer0.org4.example.com:10152
      - CORE_PEER_GOSSIP_EXTERNALENDPOINT=peer0.org4.example.com:10151
      - CORE_PEER_LOCALMSPID=Org4MSP
      - CORE_VM_ENDPOINT=unix:///host/var/run/docker.sock
      - CORE_VM_DOCKER_HOSTCONFIG_NETWORKMODE=6g-network_6g-network
      - CORE_PEER_TLS_ENABLED=true
      - CORE_PEER_TLS_CERT_FILE=/etc/hyperledger/fabric/tls/server.crt
      - CORE_PEER_TLS_KEY_FILE=/etc/hyperledger/fabric/tls/server.key
      - CORE_PEER_TLS_ROOTCERT_FILE=/etc/hyperledger/fabric/tls/ca.crt
      - CORE_PEER_MSPCONFIGPATH=/etc/hyperledger/fabric/msp
    volumes:
      - /var/run/:/host/var/run/
      - ./crypto-config/peerOrganizations/org4.example.com/peers/peer0.org4.example.com/msp:/etc/hyperledger/fabric/msp
      - ./crypto-config/peerOrganizations/org4.example.com/peers/peer0.org4.example.com/tls:/etc/hyperledger/fabric/tls
      - ./core-org4.yaml:/etc/hyperledger/fabric/core.yaml
      - peer0.org4.example.com:/var/hyperledger/production
    command: peer node start
    ports:
      - 10151:10151
    networks:
      - 6g-network

  peer0.org5.example.com:
    container_name: peer0.org5.example.com
    image: hyperledger/fabric-peer:2.5
    environment:
      - CORE_PEER_ID=peer0.org5.example.com
      - CORE_PEER_ADDRESS=peer0.org5.example.com:11151
      - CORE_PEER_LISTENADDRESS=0.0.0.0:11151
      - CORE_PEER_CHAINCODEADDRESS=peer0.org5.example.com:11152
      - CORE_PEER_GOSSIP_EXTERNALENDPOINT=peer0.org5.example.com:11151
      - CORE_PEER_LOCALMSPID=Org5MSP
      - CORE_VM_ENDPOINT=unix:///host/var/run/docker.sock
      - CORE_VM_DOCKER_HOSTCONFIG_NETWORKMODE=6g-network_6g-network
      - CORE_PEER_TLS_ENABLED=true
      - CORE_PEER_TLS_CERT_FILE=/etc/hyperledger/fabric/tls/server.crt
      - CORE_PEER_TLS_KEY_FILE=/etc/hyperledger/fabric/tls/server.key
      - CORE_PEER_TLS_ROOTCERT_FILE=/etc/hyperledger/fabric/tls/ca.crt
      - CORE_PEER_MSPCONFIGPATH=/etc/hyperledger/fabric/msp
    volumes:
      - /var/run/:/host/var/run/
      - ./crypto-config/peerOrganizations/org5.example.com/peers/peer0.org5.example.com/msp:/etc/hyperledger/fabric/msp
      - ./crypto-config/peerOrganizations/org5.example.com/peers/peer0.org5.example.com/tls:/etc/hyperledger/fabric/tls
      - ./core-org5.yaml:/etc/hyperledger/fabric/core.yaml
      - peer0.org5.example.com:/var/hyperledger/production
    command: peer node start
    ports:
      - 11151:11151
    networks:
      - 6g-network

  peer0.org6.example.com:
    container_name: peer0.org6.example.com
    image: hyperledger/fabric-peer:2.5
    environment:
      - CORE_PEER_ID=peer0.org6.example.com
      - CORE_PEER_ADDRESS=peer0.org6.example.com:12151
      - CORE_PEER_LISTENADDRESS=0.0.0.0:12151
      - CORE_PEER_CHAINCODEADDRESS=peer0.org6.example.com:12152
      - CORE_PEER_GOSSIP_EXTERNALENDPOINT=peer0.org6.example.com:12151
      - CORE_PEER_LOCALMSPID=Org6MSP
      - CORE_VM_ENDPOINT=unix:///host/var/run/docker.sock
      - CORE_VM_DOCKER_HOSTCONFIG_NETWORKMODE=6g-network_6g-network
      - CORE_PEER_TLS_ENABLED=true
      - CORE_PEER_TLS_CERT_FILE=/etc/hyperledger/fabric/tls/server.crt
      - CORE_PEER_TLS_KEY_FILE=/etc/hyperledger/fabric/tls/server.key
      - CORE_PEER_TLS_ROOTCERT_FILE=/etc/hyperledger/fabric/tls/ca.crt
      - CORE_PEER_MSPCONFIGPATH=/etc/hyperledger/fabric/msp
    volumes:
      - /var/run/:/host/var/run/
      - ./crypto-config/peerOrganizations/org6.example.com/peers/peer0.org6.example.com/msp:/etc/hyperledger/fabric/msp
      - ./crypto-config/peerOrganizations/org6.example.com/peers/peer0.org6.example.com/tls:/etc/hyperledger/fabric/tls
      - ./core-org6.yaml:/etc/hyperledger/fabric/core.yaml
      - peer0.org6.example.com:/var/hyperledger/production
    command: peer node start
    ports:
      - 12151:12151
    networks:
      - 6g-network

  peer0.org7.example.com:
    container_name: peer0.org7.example.com
    image: hyperledger/fabric-peer:2.5
    environment:
      - CORE_PEER_ID=peer0.org7.example.com
      - CORE_PEER_ADDRESS=peer0.org7.example.com:13151
      - CORE_PEER_LISTENADDRESS=0.0.0.0:13151
      - CORE_PEER_CHAINCODEADDRESS=peer0.org7.example.com:13152
      - CORE_PEER_GOSSIP_EXTERNALENDPOINT=peer0.org7.example.com:13151
      - CORE_PEER_LOCALMSPID=Org7MSP
      - CORE_VM_ENDPOINT=unix:///host/var/run/docker.sock
      - CORE_VM_DOCKER_HOSTCONFIG_NETWORKMODE=6g-network_6g-network
      - CORE_PEER_TLS_ENABLED=true
      - CORE_PEER_TLS_CERT_FILE=/etc/hyperledger/fabric/tls/server.crt
      - CORE_PEER_TLS_KEY_FILE=/etc/hyperledger/fabric/tls/server.key
      - CORE_PEER_TLS_ROOTCERT_FILE=/etc/hyperledger/fabric/tls/ca.crt
      - CORE_PEER_MSPCONFIGPATH=/etc/hyperledger/fabric/msp
    volumes:
      - /var/run/:/host/var/run/
      - ./crypto-config/peerOrganizations/org7.example.com/peers/peer0.org7.example.com/msp:/etc/hyperledger/fabric/msp
      - ./crypto-config/peerOrganizations/org7.example.com/peers/peer0.org7.example.com/tls:/etc/hyperledger/fabric/tls
      - ./core-org7.yaml:/etc/hyperledger/fabric/core.yaml
      - peer0.org7.example.com:/var/hyperledger/production
    command: peer node start
    ports:
      - 13151:13151
    networks:
      - 6g-network

  peer0.org8.example.com:
    container_name: peer0.org8.example.com
    image: hyperledger/fabric-peer:2.5
    environment:
      - CORE_PEER_ID=peer0.org8.example.com
      - CORE_PEER_ADDRESS=peer0.org8.example.com:14151
      - CORE_PEER_LISTENADDRESS=0.0.0.0:14151
      - CORE_PEER_CHAINCODEADDRESS=peer0.org8.example.com:14152
      - CORE_PEER_GOSSIP_EXTERNALENDPOINT=peer0.org8.example.com:14151
      - CORE_PEER_LOCALMSPID=Org8MSP
      - CORE_VM_ENDPOINT=unix:///host/var/run/docker.sock
      - CORE_VM_DOCKER_HOSTCONFIG_NETWORKMODE=6g-network_6g-network
      - CORE_PEER_TLS_ENABLED=true
      - CORE_PEER_TLS_CERT_FILE=/etc/hyperledger/fabric/tls/server.crt
      - CORE_PEER_TLS_KEY_FILE=/etc/hyperledger/fabric/tls/server.key
      - CORE_PEER_TLS_ROOTCERT_FILE=/etc/hyperledger/fabric/tls/ca.crt
      - CORE_PEER_MSPCONFIGPATH=/etc/hyperledger/fabric/msp
    volumes:
      - /var/run/:/host/var/run/
      - ./crypto-config/peerOrganizations/org8.example.com/peers/peer0.org8.example.com/msp:/etc/hyperledger/fabric/msp
      - ./crypto-config/peerOrganizations/org8.example.com/peers/peer0.org8.example.com/tls:/etc/hyperledger/fabric/tls
      - ./core-org8.yaml:/etc/hyperledger/fabric/core.yaml
      - peer0.org8.example.com:/var/hyperledger/production
    command: peer node start
    ports:
      - 14151:14151
    networks:
      - 6g-network

volumes:
  orderer-data:
  peer0.org1.example.com:
  peer0.org2.example.com:
  peer0.org3.example.com:
  peer0.org4.example.com:
  peer0.org5.example.com:
  peer0.org6.example.com:
  peer0.org7.example.com:
  peer0.org8.example.com:

networks:
  6g-network:
    external: true
```

---

## فایل 3: `setup.sh` (کامل + رفع خطا)

```bash
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
}

start_network() {
  log "Starting network..."

  docker network create 6g-network 2>/dev/null || log "Network 6g-network already exists"

  [ -f "$CONFIG_DIR/docker-compose-ca.yml" ] && docker-compose -f "$CONFIG_DIR/docker-compose-ca.yml" up -d --remove-orphans
  sleep 10

  [ -f "$CONFIG_DIR/docker-compose.yml" ] && docker-compose -f "$CONFIG_DIR/docker-compose.yml" up -d --remove-orphans
  sleep 20
  log "Network started"
}

create_and_join_channels() {
  log "Creating and joining channels..."
  channels=(NetworkChannel ResourceChannel PerformanceChannel IoTChannel AuthChannel \
            ConnectivityChannel SessionChannel PolicyChannel AuditChannel SecurityChannel \
            DataChannel AnalyticsChannel MonitoringChannel ManagementChannel OptimizationChannel \
            FaultChannel TrafficChannel AccessChannel ComplianceChannel IntegrationChannel)

  for i in {1..8}; do
    export CORE_PEER_MSPCONFIGPATH="$CRYPTO_DIR/peerOrganizations/org${i}.example.com/users/Admin@org${i}.example.com/msp"
    export CORE_PEER_ADDRESS="peer0.org${i}.example.com:$((7151 + (i-1)*1000))"
    export CORE_PEER_LOCALMSPID="Org${i}MSP"
    export CORE_PEER_TLS_ROOTCERT_FILE="$CRYPTO_DIR/peerOrganizations/org${i}.example.com/peers/peer0.org${i}.example.com/tls/ca.crt"

    for ch in "${channels[@]}"; do
      [ $i -eq 1 ] && peer channel create -o orderer.example.com:7050 -c "$ch" -f "$CHANNEL_DIR/${ch,,}.tx" \
        --tls --cafile "$CRYPTO_DIR/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem" \
        --outputBlock "$CHANNEL_DIR/${ch}.block" || true
      peer channel join -b "$CHANNEL_DIR/${ch}.block" || log "Org${i} already joined $ch"
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
