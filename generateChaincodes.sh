#!/bin/bash

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
    mkdir -p chaincode/$contract
    if [[ $contract == LocationBased* ]]; then
        cp chaincode/LocationBasedAssignment/chaincode.go chaincode/$contract/chaincode.go
        sed -i "s/LocationBasedAssignment/$contract/g" chaincode/$contract/chaincode.go
        sed -i "s/Assignment/$contract/g" chaincode/$contract/chaincode.go
    else
        cp chaincode/AuthenticateUser/chaincode.go chaincode/$contract/chaincode.go
        sed -i "s/AuthenticateUser/$contract/g" chaincode/$contract/chaincode.go
        sed -i "s/Auth/$contract/g" chaincode/$contract/chaincode.go
        sed -i '/x string, y string/d' chaincode/$contract/chaincode.go
        sed -i '/Distance/d' chaincode/$contract/chaincode.go
        sed -i '/xCoord/d' chaincode/$contract/chaincode.go
        sed -i '/yCoord/d' chaincode/$contract/chaincode.go
        sed -i '/refX/d' chaincode/$contract/chaincode.go
        sed -i '/refY/d' chaincode/$contract/chaincode.go
        sed -i '/distance/d' chaincode/$contract/chaincode.go
        sed -i '/xVal/d' chaincode/$contract/chaincode.go
        sed -i '/yVal/d' chaincode/$contract/chaincode.go
    fi
done
