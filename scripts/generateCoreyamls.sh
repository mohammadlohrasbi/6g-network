#!/bin/bash
# generateCoreyamls.sh
set -e

CONFIG_DIR="/root/6g-network/config"
mkdir -p "$CONFIG_DIR"

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
done

cp "$CONFIG_DIR/core-org1.yaml" "$CONFIG_DIR/core.yaml"
