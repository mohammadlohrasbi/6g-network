#!/bin/bash

for i in {1..8}; do
    cat > core-org${i}.yaml <<EOF
peer:
  id: peer0.org${i}.example.com
  networkId: 6g-fabric
  listenAddress: 0.0.0.0:$((7051 + (i-1)*1000))
  chaincodeListenAddress: 0.0.0.0:$((7052 + (i-1)*1000))
  address: 165.232.71.90:$((7051 + (i-1)*1000))
  localMspId: Org${i}MSP
  mspConfigPath: /var/hyperledger/msp
  tls:
    enabled: true
    cert:
      file: /var/hyperledger/tls/server.crt
    key:
      file: /var/hyperledger/tls/server.key
    rootcert:
      file: /var/hyperledger/tls/ca.crt
  fileSystemPath: /var/hyperledger/production
  ledger:
    state:
      stateDatabase: CouchDB
      couchDBConfig:
        couchDBAddress: couchdb-org${i}:$((5984 + (i-1)*1000))
        username: admin
        password: adminpw
        maxRetries: 3
        maxRetriesOnStartup: 10
        requestTimeout: 35s
  logging:
    level: error
EOF
done
