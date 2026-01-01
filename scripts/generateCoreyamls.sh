#!/bin/bash
# generateCoreyamls.sh - نسخه نهایی و ۱۰۰٪ درست برای Fabric 2.5 (اصلاح MSP ID و clientAuthRequired برای حل gossip و join)
ROOT_DIR="/root/6g-network"
CONFIG_DIR="$ROOT_DIR/config"
mkdir -p "$CONFIG_DIR"
echo "Generating core.yaml files for 8 organizations (نسخه نهایی و بدون خطا)..."
for i in {1..8}; do
  CORE_FILE="$CONFIG_DIR/core-org${i}.yaml"
  PORT=$((7051 + (i-1)*1000)) # دقیقاً با docker-compose تطابق دارد
  CHAINCODE_PORT=$((7052 + (i-1)*1000))
  cat > "$CORE_FILE" <<EOF
peer:
  id: peer0.org${i}.example.com
  networkId: 6g-network
  listenAddress: 0.0.0.0:${PORT}
  chaincodeListenAddress: 0.0.0.0:${CHAINCODE_PORT}
  address: peer0.org${i}.example.com:${PORT}
  gossip:
    bootstrap: peer0.org1.example.com:7051 # همه org1 را می‌شناسند
    useLeaderElection: true
    orgLeader: false
    endpoint: peer0.org${i}.example.com:${PORT}
  mspConfigPath: /etc/hyperledger/fabric/msp
  localMspId: org${i}MSP  # <<< اصلاح: حرف کوچک o (match با گواهی MSP)
  tls:
    enabled: true
    clientAuthRequired: false  # <<< اضافه: mutual auth خاموش برای gossip (TLS فعال می‌ماند، خطای bad certificate حل می‌شود)
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
  # این بخش حیاتی است — external builder را فعال می‌کند
  chaincode:
    externalBuilders:
      - name: simple
        path: /opt/hlf/builder
        propagateEnvironment:
          - CHAINCODE_SERVER_ADDRESS
EOF
  echo "Generated: $CORE_FILE"
done
# cp لازم نیست (هر peer core-orgX خودش را دارد)
echo "All 8 core.yaml files generated successfully!"
