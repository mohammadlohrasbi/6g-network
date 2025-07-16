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

    mkdir -p caliper-workspace/workload
    if [[ $contract == LocationBased* ]]; then
        cp caliper-workspace/workload/LocationBasedAssignment.js caliper-workspace/workload/$contract.js
        sed -i "s/LocationBasedAssignment/$contract/g" caliper-workspace/workload/$contract.js
        sed -i "s/GeneralOperationsChannel/$channel/g" caliper-workspace/workload/$contract.js
    else
        cp caliper-workspace/workload/AuthenticateUser.js caliper-workspace/workload/$contract.js
        sed -i "s/AuthenticateUser/$contract/g" caliper-workspace/workload/$contract.js
        sed -i "s/SecurityChannel/$channel/g" caliper-workspace/workload/$contract.js
        sed -i '/const x =/d' caliper-workspace/workload/$contract.js
        sed -i '/const y =/d' caliper-workspace/workload/$contract.js
        sed -i "s/contractArguments: \[entityID, antennaID, x, y\]/contractArguments: \[entityID, antennaID\]/g" caliper-workspace/workload/$contract.js
    fi
done
