#!/bin/bash

# تعداد سازمان‌ها (پیش‌فرض 8، قابل تنظیم)
ORG_COUNT=${ORG_COUNT:-8}

# تولید core.yaml برای هر سازمان
mkdir -p config/core

for ((i=1; i<=ORG_COUNT; i++)); do
    ORG_NAME="Org${i}"
    PEER_PORT=$((7051 + (i-1)*2000))
    COUCHDB_PORT=$((5984 + (i-1)*1000))
    cat > config/core/core-org${i}.yaml <<EOF
peer:
  id: peer0.${ORG_NAME,,}.example.com
  networkId: 6g-network
  address: peer0.${ORG_NAME,,}.example.com:${PEER_PORT}
  localMspId: ${ORG_NAME}MSP
  listenAddress: 0.0.0.0:${PEER_PORT}
  chaincodeAddress: peer0.${ORG_NAME,,}.example.com:$((PEER_PORT + 1))
  chaincodeListenAddress: 0.0.0.0:$((PEER_PORT + 1))
  gossip:
    bootstrap: peer0.${ORG_NAME,,}.example.com:${PEER_PORT}
    externalEndpoint: peer0.${ORG_NAME,,}.example.com:${PEER_PORT}
    useLeaderElection: true
    orgLeader: false
  tls:
    enabled: true
    cert:
      file: /crypto-config/peerOrganizations/${ORG_NAME,,}.example.com/peers/peer0.${ORG_NAME,,}.example.com/tls/server.crt
    key:
      file: /crypto-config/peerOrganizations/${ORG_NAME,,}.example.com/peers/peer0.${ORG_NAME,,}.example.com/tls/server.key
    rootcert:
      file: /crypto-config/peerOrganizations/${ORG_NAME,,}.example.com/peers/peer0.${ORG_NAME,,}.example.com/tls/ca.crt
    clientAuthRequired: false
  mspConfigPath: /crypto-config/peerOrganizations/${ORG_NAME,,}.example.com/peers/peer0.${ORG_NAME,,}.example.com/msp
ledger:
  state:
    stateDatabase: CouchDB
    couchDBConfig:
      couchDBAddress: couchdb-org${i}:${COUCHDB_PORT}
      username: admin
      password: adminpw
      maxRetries: 3
      maxRetriesOnStartup: 10
      requestTimeout: 35s
      queryLimit: 10000
vm:
  endpoint: unix:///host/var/run/docker.sock
  docker:
    hostConfig:
      Memory: 4G
      CpuCount: 2
chaincode:
  externalBuilders: []
operations:
  listenAddress: 127.0.0.1:$((9443 + i-1))
  tls:
    enabled: false
metrics:
  provider: prometheus
  statsd:
    network: udp
    address: 127.0.0.1:8125
    writeInterval: 10s
    prefix: peer0_${ORG_NAME,,}_example_com
EOF
done

echo "Generated core YAML files for $ORG_COUNT organizations"
