#!/bin/bash
# generateCoreyamls.sh - نسخه نهایی (با externalEndpoint برای حل discovery و listen)

ROOT_DIR="/root/6g-network"
CONFIG_DIR="$ROOT_DIR/config"
mkdir -p "$CONFIG_DIR"

echo "Generating core.yaml files for 8 organizations (با externalEndpoint برای gossip کامل)..."

for i in {1..8}; do
  CORE_FILE="$CONFIG_DIR/core-org${i}.yaml"
  PORT=$((7051 + (i-1)*1000))
  CHAINCODE_PORT=$((7052 + (i-1)*1000))
  ORG_LEADER="false"
  if [ "$i" -eq 1 ]; then
    ORG_LEADER="true"
  fi
  cat > "$CORE_FILE" <<EOF
peer:
  id: peer0.org${i}.example.com
  networkId: 6g-network
  listenAddress: 0.0.0.0:${PORT}
  chaincodeListenAddress: 0.0.0.0:${CHAINCODE_PORT}
  address: peer0.org${i}.example.com:${PORT}
  gossip:
    bootstrap: peer0.org1.example.com:7051 peer0.org2.example.com:8051 peer0.org3.example.com:9051 peer0.org4.example.com:10051 peer0.org5.example.com:11051 peer0.org6.example.com:12051 peer0.org7.example.com:13051 peer0.org8.example.com:14051
    useLeaderElection: true
    orgLeader: ${ORG_LEADER}
    endpoint: peer0.org${i}.example.com:${PORT}
    externalEndpoint: peer0.org${i}.example.com:${PORT}  # <<< حل discovery و membership
    skipMSPValidation: true
  mspConfigPath: /etc/hyperledger/fabric/msp
  localMspId: org${i}MSP
  tls:
    enabled: true
    clientAuthRequired: false
    cert:
      file: /etc/hyperledger/fabric/tls/server.crt
    key:
      file: /etc/hyperledger/fabric/tls/server.key
    rootcert:
      file: /etc/hyperledger/fabric/bundled-tls-ca.pem
  bccsp:
    default: SW
    sw:
      hash: SHA2
      security: 256
  fileSystemPath: /var/hyperledger/production
  ledger:
    state:
      stateDatabase: goleveldb
  chaincode:
    externalBuilders:
      - name: simple
        path: /opt/hlf/builder
        propagateEnvironment:
          - CHAINCODE_SERVER_ADDRESS
EOF
  echo "Generated: $CORE_FILE"
done

echo "All 8 core.yaml files generated successfully!"
