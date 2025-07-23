#!/bin/bash

# تنظیم متغیرهای محیطی
export PATH=${PWD}/bin:$PATH
export FABRIC_CFG_PATH=${PWD}/config
export CORE_PEER_TLS_ENABLED=true
export CORE_PEER_LOCALMSPID="Org1MSP"
export CORE_PEER_TLS_ROOTCERT_FILE=/crypto-config/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt
export CORE_PEER_MSPCONFIGPATH=/crypto-config/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp
export CORE_PEER_ADDRESS=peer0.org1.example.com:7051

# توابع کمکی
function checkPrereqs() {
    if ! command -v docker &> /dev/null; then
        echo "Docker is not installed. Please install Docker."
        exit 1
    fi
    if ! command -v docker-compose &> /dev/null; then
        echo "Docker Compose is not installed. Please install Docker Compose."
        exit 1
    fi
}

function startNetwork() {
    echo "Starting Fabric network..."
    docker-compose -f docker-compose.yml up -d
    sleep 10
}

function createChannels() {
    echo "Creating channels..."
    peer channel create -o orderer1.example.com:7050 -c NetworkChannel -f ./channel-artifacts/networkchannel.tx --tls --cafile /crypto-config/ordererOrganizations/example.com/orderers/orderer1.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
    peer channel create -o orderer1.example.com:7050 -c ResourceChannel -f ./channel-artifacts/resourcechannel.tx --tls --cafile /crypto-config/ordererOrganizations/example.com/orderers/orderer1.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
    peer channel create -o orderer1.example.com:7050 -c PerformanceChannel -f ./channel-artifacts/performancechannel.tx --tls --cafile /crypto-config/ordererOrganizations/example.com/orderers/orderer1.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
    peer channel create -o orderer1.example.com:7050 -c IoTChannel -f ./channel-artifacts/iotchannel.tx --tls --cafile /crypto-config/ordererOrganizations/example.com/orderers/orderer1.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
    peer channel create -o orderer1.example.com:7050 -c AuthChannel -f ./channel-artifacts/authchannel.tx --tls --cafile /crypto-config/ordererOrganizations/example.com/orderers/orderer1.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
    peer channel create -o orderer1.example.com:7050 -c ConnectivityChannel -f ./channel-artifacts/connectivitychannel.tx --tls --cafile /crypto-config/ordererOrganizations/example.com/orderers/orderer1.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
    peer channel create -o orderer1.example.com:7050 -c SessionChannel -f ./channel-artifacts/sessionchannel.tx --tls --cafile /crypto-config/ordererOrganizations/example.com/orderers/orderer1.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
    peer channel create -o orderer1.example.com:7050 -c PolicyChannel -f ./channel-artifacts/policychannel.tx --tls --cafile /crypto-config/ordererOrganizations/example.com/orderers/orderer1.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
    peer channel create -o orderer1.example.com:7050 -c AuditChannel -f ./channel-artifacts/auditchannel.tx --tls --cafile /crypto-config/ordererOrganizations/example.com/orderers/orderer1.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
    peer channel create -o orderer1.example.com:7050 -c SecurityChannel -f ./channel-artifacts/securitychannel.tx --tls --cafile /crypto-config/ordererOrganizations/example.com/orderers/orderer1.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
}

function joinChannels() {
    echo "Joining channels..."
    peer channel join -b NetworkChannel.block
    peer channel join -b ResourceChannel.block
    peer channel join -b PerformanceChannel.block
    peer channel join -b IoTChannel.block
    peer channel join -b AuthChannel.block
    peer channel join -b ConnectivityChannel.block
    peer channel join -b SessionChannel.block
    peer channel join -b PolicyChannel.block
    peer channel join -b AuditChannel.block
    peer channel join -b SecurityChannel.block
}

function packageChaincodes() {
    echo "Packaging chaincodes..."
    for i in {1..10}; do
        ./generateChaincodes_part${i}.sh
    done
}

function installChaincodes() {
    echo "Installing chaincodes..."
    for contract in $(ls chaincode); do
        peer chaincode package chaincode/$contract.pack -n $contract -v 1.0 -p chaincode/$contract
        peer chaincode install chaincode/$contract.pack
    done
}

function instantiateChaincodes() {
    echo "Instantiating chaincodes..."
    for contract in $(ls chaincode); do
        case $contract in
            AssetManagement|UserManagement|IoTManagement|AntennaManagement|NetworkManagement|ResourceManagement|PerformanceManagement|SessionManagement|PolicyManagement)
                peer chaincode instantiate -o orderer1.example.com:7050 -C NetworkChannel -n $contract -v 1.0 -c '{"Args":["Init"]}' --tls --cafile /crypto-config/ordererOrganizations/example.com/orderers/orderer1.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
                ;;
            LocationBased*)
                peer chaincode instantiate -o orderer1.example.com:7050 -C ResourceChannel -n $contract -v 1.0 -c '{"Args":["Init"]}' --tls --cafile /crypto-config/ordererOrganizations/example.com/orderers/orderer1.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
                ;;
            Authenticate*|Register*|Revoke*|AssignRole)
                peer chaincode instantiate -o orderer1.example.com:7050 -C AuthChannel -n $contract -v 1.0 -c '{"Args":["Init"]}' --tls --cafile /crypto-config/ordererOrganizations/example.com/orderers/orderer1.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
                ;;
            Connect*)
                peer chaincode instantiate -o orderer1.example.com:7050 -C ConnectivityChannel -n $contract -v 1.0 -c '{"Args":["Init"]}' --tls --cafile /crypto-config/ordererOrganizations/example.com/orderers/orderer1.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
                ;;
            Monitor*|Log*)
                peer chaincode instantiate -o orderer1.example.com:7050 -C AuditChannel -n $contract -v 1.0 -c '{"Args":["Init"]}' --tls --cafile /crypto-config/ordererOrganizations/example.com/orderers/orderer1.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
                ;;
            EncryptData|DecryptData|SecureCommunication|VerifyIdentity|SetPolicy|GetPolicy|UpdatePolicy)
                peer chaincode instantiate -o orderer1.example.com:7050 -C SecurityChannel -n $contract -v 1.0 -c '{"Args":["Init"]}' --tls --cafile /crypto-config/ordererOrganizations/example.com/orderers/orderer1.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
                ;;
            Manage*)
                peer chaincode instantiate -o orderer1.example.com:7050 -C NetworkChannel -n $contract -v 1.0 -c '{"Args":["Init"]}' --tls --cafile /crypto-config/ordererOrganizations/example.com/orderers/orderer1.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
                ;;
        esac
        sleep 5
    done
}

# اجرای مراحل راه‌اندازی
checkPrereqs
startNetwork
createChannels
joinChannels
packageChaincodes
installChaincodes
instantiateChaincodes

echo "Network setup completed successfully!"
