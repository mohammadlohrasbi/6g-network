#!/bin/bash

# تولید گواهی‌های رمزنگاری
cryptogen generate --config=./crypto-config.yaml

# تولید بلاک جنسیس و فایل‌های کانال
configtxgen -profile NetworkGenesis -outputBlock ./genesis.block
for channel in Org1Channel Org2Channel Org3Channel Org4Channel Org5Channel Org6Channel Org7Channel Org8Channel GeneralOperationsChannel IoTChannel SecurityChannel AuditChannel BillingChannel ResourceChannel PerformanceChannel SessionChannel ConnectivityChannel PolicyChannel; do
    configtxgen -profile $channel -outputCreateChannelTx ./${channel}.tx -channelID $channel
done

# راه‌اندازی شبکه
docker-compose -f docker-compose.yml up -d

# ایجاد کانال‌ها
for channel in Org1Channel Org2Channel Org3Channel Org4Channel Org5Channel Org6Channel Org7Channel Org8Channel GeneralOperationsChannel IoTChannel SecurityChannel AuditChannel BillingChannel ResourceChannel PerformanceChannel SessionChannel ConnectivityChannel PolicyChannel; do
    docker exec peer0.org1.example.com peer channel create -o orderer1.example.com:7050 -c $channel -f ./${channel}.tx --tls --cafile /crypto-config/ordererOrganizations/example.com/orderers/orderer1.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
    for org in {1..8}; do
        docker exec peer0.org${org}.example.com peer channel join -b ${channel}.block
    done
done

# نصب و اجرای قراردادها
contracts=(
    "LocationBasedAssignment" "LocationBasedConnection" "LocationBasedBandwidth" "LocationBasedQoS"
    "LocationBasedPriority" "LocationBasedStatus" "LocationBasedFault" "LocationBasedTraffic"
    "LocationBasedLatency" "LocationBasedEnergy" "LocationBasedRoaming" "LocationBasedSignalStrength"
    "LocationBasedCoverage" "LocationBasedInterference" "LocationBasedResourceAllocation"
    "LocationBasedNetworkLoad" "LocationBasedCongestion" "LocationBasedDynamicRouting"
    "LocationBasedAntennaConfig" "LocationBasedSignalQuality" "LocationBasedNetworkHealth"
    "LocationBasedPowerManagement" "LocationBasedChannelAllocation" "LocationBasedSessionManagement"
    "LocationBasedIoTConnection" "LocationBasedIoTBandwidth" "LocationBasedIoTStatus"
    "LocationBasedIoTFault" "LocationBasedIoTSession" "LocationBasedIoTAuthentication"
    "LocationBasedIoTRegistration" "LocationBasedIoTRevocation" "LocationBasedIoTResource"
    "LocationBasedNetworkPerformance" "LocationBasedUserActivity" "AuthenticateUser" "AuthenticateIoT"
    "ConnectUser" "ConnectIoT" "RegisterUser" "RegisterIoT" "RevokeUser" "RevokeIoT" "AssignRole"
    "GrantAccess" "LogIdentityAudit" "AllocateIoTBandwidth" "UpdateAntennaLoad" "RequestResource"
    "ShareSpectrum" "AssignGeneralPriority" "LogResourceAudit" "BalanceLoad" "AllocateDynamic"
    "UpdateAntennaStatus" "UpdateIoTStatus" "LogNetworkPerformance" "LogUserActivity"
    "DetectAntennaFault" "DetectIoTFault" "MonitorAntennaTraffic" "GenerateReport" "TrackLatency"
    "MonitorEnergy" "PerformRoaming" "TrackSession" "TrackIoTSession" "DisconnectEntity"
    "GenerateBill" "LogTransaction" "LogConnectionAudit" "EncryptData" "EncryptIoTData" "LogAccess"
    "DetectIntrusion" "ManageKey" "SetPolicy" "CreateSecureChannel" "LogSecurityAudit"
    "AuthenticateAntenna" "MonitorNetworkCongestion" "AllocateNetworkResource" "MonitorNetworkHealth"
    "ManageNetworkPolicy" "LogNetworkAudit"
)

for contract in "${contracts[@]}"; do
    channel=""
    if [[ "LocationBasedAssignment LocationBasedAntennaConfig AssignRole GenerateReport" =~ $contract ]]; then
        channel="GeneralOperationsChannel"
    elif [[ "LocationBasedIoTConnection LocationBasedIoTBandwidth LocationBasedIoTStatus LocationBasedIoTFault LocationBasedIoTSession LocationBasedIoTAuthentication LocationBasedIoTRegistration LocationBasedIoTRevocation LocationBasedIoTResource AuthenticateIoT ConnectIoT RegisterIoT RevokeIoT AllocateIoTBandwidth UpdateIoTStatus DetectIoTFault TrackIoTSession EncryptIoTData" =~ $contract ]]; then
        channel="IoTChannel"
    elif [[ "AuthenticateUser RegisterUser RevokeUser EncryptData DetectIntrusion ManageKey AuthenticateAntenna CreateSecureChannel" =~ $contract ]]; then
        channel="SecurityChannel"
    elif [[ "LocationBasedFault LocationBasedUserActivity LogIdentityAudit LogResourceAudit LogConnectionAudit LogSecurityAudit LogTransaction LogAccess LogNetworkAudit" =~ $contract ]]; then
        channel="AuditChannel"
    elif [[ "GenerateBill" =~ $contract ]]; then
        channel="BillingChannel"
    elif [[ "LocationBasedBandwidth LocationBasedResourceAllocation RequestResource ShareSpectrum AllocateDynamic AllocateNetworkResource" =~ $contract ]]; then
        channel="ResourceChannel"
    elif [[ "LocationBasedQoS LocationBasedTraffic LocationBasedLatency LocationBasedEnergy LocationBasedSignalStrength LocationBasedCoverage LocationBasedNetworkHealth LocationBasedNetworkPerformance UpdateAntennaLoad BalanceLoad TrackLatency MonitorEnergy DetectAntennaFault MonitorAntennaTraffic MonitorNetworkCongestion MonitorNetworkHealth" =~ $contract ]]; then
        channel="PerformanceChannel"
    elif [[ "LocationBasedSessionManagement TrackSession TrackIoTSession" =~ $contract ]]; then
        channel="SessionChannel"
    elif [[ "LocationBasedConnection LocationBasedRoaming LocationBasedDynamicRouting LocationBasedChannelAllocation ConnectUser DisconnectEntity PerformRoaming" =~ $contract ]]; then
        channel="ConnectivityChannel"
    elif [[ "LocationBasedPriority AssignGeneralPriority GrantAccess SetPolicy ManageNetworkPolicy" =~ $contract ]]; then
        channel="PolicyChannel"
    fi

    for org in {1..8}; do
        docker exec peer0.org${org}.example.com peer chaincode install -n $contract -v 1.0 -p github.com/chaincode/$contract
        docker exec peer0.org${org}.example.com peer chaincode instantiate -o orderer1.example.com:7050 --tls --cafile /crypto-config/ordererOrganizations/example.com/orderers/orderer1.example.com/msp/tlscacerts/tlsca.example.com-cert.pem -C $channel -n $contract -v 1.0 -c '{"Args":["init"]}' -P "AND('Org1MSP.member','Org2MSP.member','Org3MSP.member','Org4MSP.member','Org5MSP.member','Org6MSP.member','Org7MSP.member','Org8MSP.member')"
    done
done

# اجرای تست‌های Caliper
cd caliper-workspace
npx caliper launch manager --caliper-workspace . --caliper-networkconfig networks/networkConfig.yaml --caliper-benchconfig benchmarks/myAssetBenchmark.yaml

# اجرای تست‌های Tape
node ../generateTapeArgs.js
tape --config ../tape-config.yaml

# تولید فایل زیپ
cd ..
zip -r 6g-fabric-network.zip chaincode caliper-workspace crypto-config *.tx *.block *.yaml *.sh *.js
mv 6g-fabric-network.zip $HOME/
