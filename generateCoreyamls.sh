#!/bin/bash

for org in {1..8}; do
    cat > core-org${org}.yaml <<EOF
peer:
  id: peer0.org${org}.example.com
  networkId: 6g-fabric
  listenAddress: 0.0.0.0:$((7051 + (org-1)*1000))
  chaincodeListenAddress: 0.0.0.0:$((7052 + (org-1)*1000))
  address: 165.232.71.90:$((7051 + (org-1)*1000))
  localMspId: Org${org}MSP
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
      stateDatabase: LevelDB
  logging:
    level: error
EOF
done
