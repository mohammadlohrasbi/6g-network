#!/bin/bash

# تعداد سازمان‌ها (پیش‌فرض 8، قابل تنظیم)
ORG_COUNT=${ORG_COUNT:-8}

# لیست 20 کانال
CHANNELS=("NetworkChannel" "ResourceChannel" "PerformanceChannel" "IoTChannel" "AuthChannel" "ConnectivityChannel" "SessionChannel" "PolicyChannel" "AuditChannel" "SecurityChannel" "DataChannel" "AnalyticsChannel" "MonitoringChannel" "ManagementChannel" "OptimizationChannel" "FaultChannel" "TrafficChannel" "AccessChannel" "ComplianceChannel" "IntegrationChannel")

# تنظیم متغیرهای محیطی برای Org1 (برای ایجاد کانال‌ها)
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
    if ! command -v peer &> /dev/null; then
        echo "Hyperledger Fabric binaries are not installed. Please install Fabric 2.5."
        exit 1
    fi
}

function generateConfigs() {
    echo "Generating connection profiles, core YAMLs, and workload files..."
    cd scripts
    ./generateConnectionJson.sh
    ./generateConnectionProfiles.sh
    ./generateCoreyamls.sh
    ./generateWorkloadFiles.sh
    cd ..
}

function startNetwork() {
    echo "Starting Fabric network..."
    docker-compose -f config/docker-compose.yml up -d
    sleep 10
}

function createChannels() {
    echo "Creating channels..."
    for CHANNEL in "${CHANNELS[@]}"; do
        peer channel create -o orderer1.example.com:7050 -c ${CHANNEL} -f config/channel-artifacts/${CHANNEL,,}.tx --tls --cafile /crypto-config/ordererOrganizations/example.com/orderers/orderer1.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
    done
}

function joinChannels() {
    echo "Joining channels..."
    for ((i=1; i<=ORG_COUNT; i++)); do
        ORG_NAME="Org${i}"
        PEER_PORT=$((7051 + (i-1)*2000))
        export CORE_PEER_LOCALMSPID="${ORG_NAME}MSP"
        export CORE_PEER_TLS_ROOTCERT_FILE=/crypto-config/peerOrganizations/${ORG_NAME,,}.example.com/peers/peer0.${ORG_NAME,,}.example.com/tls/ca.crt
        export CORE_PEER_MSPCONFIGPATH=/crypto-config/peerOrganizations/${ORG_NAME,,}.example.com/users/Admin@${ORG_NAME,,}.example.com/msp
        export CORE_PEER_ADDRESS=peer0.${ORG_NAME,,}.example.com:${PEER_PORT}
        for CHANNEL in "${CHANNELS[@]}"; do
            peer channel join -b config/channel-artifacts/${CHANNEL}.block
        done
    done
}

function packageChaincodes() {
    echo "Packaging chaincodes..."
    cd scripts
    for i in {1..10}; do
        ./generateChaincodes_part${i}.sh
    done
    cd ..
}

function installChaincodes() {
    echo "Installing chaincodes..."
    for ((i=1; i<=ORG_COUNT; i++)); do
        ORG_NAME="Org${i}"
        PEER_PORT=$((7051 + (i-1)*2000))
        export CORE_PEER_LOCALMSPID="${ORG_NAME}MSP"
        export CORE_PEER_TLS_ROOTCERT_FILE=/crypto-config/peerOrganizations/${ORG_NAME,,}.example.com/peers/peer0.${ORG_NAME,,}.example.com/tls/ca.crt
        export CORE_PEER_MSPCONFIGPATH=/crypto-config/peerOrganizations/${ORG_NAME,,}.example.com/users/Admin@${ORG_NAME,,}.example.com/msp
        export CORE_PEER_ADDRESS=peer0.${ORG_NAME,,}.example.com:${PEER_PORT}
        for contract in $(ls chaincode); do
            peer chaincode package chaincode/$contract.pack -n $contract -v 1.0 -p chaincode/$contract
            peer chaincode install chaincode/$contract.pack
        done
    done
}

function instantiateChaincodes() {
    echo "Instantiating chaincodes..."
    export CORE_PEER_LOCALMSPID="Org1MSP"
    export CORE_PEER_TLS_ROOTCERT_FILE=/crypto-config/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt
    export CORE_PEER_MSPCONFIGPATH=/crypto-config/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp
    export CORE_PEER_ADDRESS=peer0.org1.example.com:7051
    for contract in $(ls chaincode); do
        case $contract in
            AssetManagement|UserManagement|IoTManagement|AntennaManagement|NetworkManagement|ResourceManagement|PerformanceManagement|SessionManagement|PolicyManagement|ManageNetwork|ManageAntenna|ManageIoTDevice|ManageUser)
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
            *)
                peer chaincode instantiate -o orderer1.example.com:7050 -C DataChannel -n $contract -v 1.0 -c '{"Args":["Init"]}' --tls --cafile /crypto-config/ordererOrganizations/example.com/orderers/orderer1.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
                ;;
        esac
        sleep 5
    done
}

# اجرای مراحل راه‌اندازی
checkPrereqs
generateConfigs
startNetwork
createChannels
joinChannels
packageChaincodes
installChaincodes
instantiateChaincodes

echo "Network setup completed successfully!" > setup.sh.log
