#!/bin/bash
# generateCoreyamls.sh – تولید core.yaml برای 8 سازمان
# خروجی: /root/6g-network/config/core-org1.yaml … core-org8.yaml
set -e

ROOT_DIR="/root/6g-network"
CONFIG_DIR="$ROOT_DIR/config"
mkdir -p "$CONFIG_DIR"

echo "Generating core.yaml files for 8 organizations..."

for i in {1..8}; do
  CORE_FILE="$CONFIG_DIR/core-org${i}.yaml"
  PORT=$((7151 + (i-1)*1000))
  CHAINCODE_PORT=$((7152 + (i-1)*1000))

  # استفاده از <<'EOF' تا متغیرها در زمان نوشتن جایگزین نشوند
  cat > "$CORE_FILE" <<'EOF'
peer:
  id: peer0.org{{ORG}}.example.com
  networkId: 6g-network
  listenAddress: 0.0.0.0:{{PORT}}
  chaincodeListenAddress: 0.0.0.0:{{CHAINCODE_PORT}}
  address: peer0.org{{ORG}}.example.com:{{PORT}}
  gossip:
    bootstrap: peer0.org{{ORG}}.example.com:{{PORT}}
    useLeaderElection: true
    orgLeader: false
    endpoint: peer0.org{{ORG}}.example.com:{{PORT}}
  mspConfigPath: /etc/hyperledger/fabric/msp
  localMspId: Org{{ORG}}MSP
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

  # جایگزینی متغیرها
  sed -i "s/{{ORG}}/$i/g; s/{{PORT}}/$PORT/g; s/{{CHAINCODE_PORT}}/$CHAINCODE_PORT/g" "$CORE_FILE"

  echo "Generated: $CORE_FILE"
done

echo "All 8 core.yaml files generated in $CONFIG_DIR"
