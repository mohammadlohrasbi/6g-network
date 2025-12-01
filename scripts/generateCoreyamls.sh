#!/bin/bash
# generateCoreyamls.sh - تولید core.yaml برای 8 سازمان
#set -e

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

cp "$CONFIG_DIR/core-org1.yaml" "$CONFIG_DIR/core.yaml"
echo "Generated general core.yaml for host: $CONFIG_DIR/core.yaml"

echo "All 8 core.yaml files generated in $CONFIG_DIR"
