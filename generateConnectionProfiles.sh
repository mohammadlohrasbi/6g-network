#!/bin/bash

for org in {1..8}; do
    cat > crypto-config/peerOrganizations/org${org}.example.com/connection-org${org}.yaml <<EOF
name: 6g-fabric-network-org${org}
version: 1.0.0
client:
  organization: Org${org}MSP
  connection:
    timeout:
      peer:
        endorser: '300'
      orderer: '300'
organizations:
  Org${org}MSP:
    mspid: Org${org}MSP
    peers:
      - peer0.org${org}.example.com
    certificateAuthorities:
      - ca.org${org}.example.com
peers:
  peer0.org${org}.example.com:
    url: grpcs://165.232.71.90:$((7051 + (org-1)*1000))
    tlsCACerts:
      path: crypto-config/peerOrganizations/org${org}.example.com/peers/peer0.org${org}.example.com/tls/ca.crt
    grpcOptions:
      ssl-target-name-override: peer0.org${org}.example.com
certificateAuthorities:
  ca.org${org}.example.com:
    url: https://165.232.71.90:$((7054 + (org-1)*1000))
    caName: ca-org${org}
    tlsCACerts:
      path: crypto-config/peerOrganizations/org${org}.example.com/ca/ca.org${org}.example.com-cert.pem
EOF
done
