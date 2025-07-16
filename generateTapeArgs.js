const fs = require('fs');

const contracts = [
    "LocationBasedAssignment", "LocationBasedConnection", "LocationBasedBandwidth", "LocationBasedQoS",
    "LocationBasedPriority", "LocationBasedStatus", "LocationBasedFault", "LocationBasedTraffic",
    "LocationBasedLatency", "LocationBasedEnergy", "LocationBasedRoaming", "LocationBasedSignalStrength",
    "LocationBasedCoverage", "LocationBasedInterference", "LocationBasedResourceAllocation",
    "LocationBasedNetworkLoad", "LocationBasedCongestion", "LocationBasedDynamicRouting",
    "LocationBasedAntennaConfig", "LocationBasedSignalQuality", "LocationBasedNetworkHealth",
    "LocationBasedPowerManagement", "LocationBasedChannelAllocation", "LocationBasedSessionManagement",
    "LocationBasedIoTConnection", "LocationBasedIoTBandwidth", "LocationBasedIoTStatus",
    "LocationBasedIoTFault", "LocationBasedIoTSession", "LocationBasedIoTAuthentication",
    "LocationBasedIoTRegistration", "LocationBasedIoTRevocation", "LocationBasedIoTResource",
    "LocationBasedNetworkPerformance", "LocationBasedUserActivity", "AuthenticateUser", "AuthenticateIoT",
    "ConnectUser", "ConnectIoT", "RegisterUser", "RegisterIoT", "RevokeUser", "RevokeIoT", "AssignRole",
    "GrantAccess", "LogIdentityAudit", "AllocateIoTBandwidth", "UpdateAntennaLoad", "RequestResource",
    "ShareSpectrum", "AssignGeneralPriority", "LogResourceAudit", "BalanceLoad", "AllocateDynamic",
    "UpdateAntennaStatus", "UpdateIoTStatus", "LogNetworkPerformance", "LogUserActivity",
    "DetectAntennaFault", "DetectIoTFault", "MonitorAntennaTraffic", "GenerateReport", "TrackLatency",
    "MonitorEnergy", "PerformRoaming", "TrackSession", "TrackIoTSession", "DisconnectEntity",
    "GenerateBill", "LogTransaction", "LogConnectionAudit", "EncryptData", "EncryptIoTData", "LogAccess",
    "DetectIntrusion", "ManageKey", "SetPolicy", "CreateSecureChannel", "LogSecurityAudit",
    "AuthenticateAntenna", "MonitorNetworkCongestion", "AllocateNetworkResource", "MonitorNetworkHealth",
    "ManageNetworkPolicy", "LogNetworkAudit"
];

const channels = [
    "Org1Channel", "Org2Channel", "Org3Channel", "Org4Channel", "Org5Channel", "Org6Channel",
    "Org7Channel", "Org8Channel", "GeneralOperationsChannel", "IoTChannel", "SecurityChannel",
    "AuditChannel", "BillingChannel", "ResourceChannel", "PerformanceChannel", "SessionChannel",
    "ConnectivityChannel", "PolicyChannel"
];

const tapeConfig = {
    network: {
        orderers: ["orderer1.example.com:7050"],
        peers: {
            "peer0.org1.example.com": { url: "grpcs://165.232.71.90:7051" },
            "peer0.org2.example.com": { url: "grpcs://165.232.71.90:8051" },
            "peer0.org3.example.com": { url: "grpcs://165.232.71.90:9051" },
            "peer0.org4.example.com": { url: "grpcs://165.232.71.90:10051" },
            "peer0.org5.example.com": { url: "grpcs://165.232.71.90:11051" },
            "peer0.org6.example.com": { url: "grpcs://165.232.71.90:12051" },
            "peer0.org7.example.com": { url: "grpcs://165.232.71.90:13051" },
            "peer0.org8.example.com": { url: "grpcs://165.232.71.90:14051" }
        }
    },
    chaincodes: []
};

contracts.forEach(contract => {
    let channel = "";
    if (["LocationBasedAssignment", "LocationBasedAntennaConfig", "AssignRole", "GenerateReport"].includes(contract)) {
        channel = "GeneralOperationsChannel";
    } else if (["LocationBasedIoTConnection", "LocationBasedIoTBandwidth", "LocationBasedIoTStatus", "LocationBasedIoTFault", "LocationBasedIoTSession", "LocationBasedIoTAuthentication", "LocationBasedIoTRegistration", "LocationBasedIoTRevocation", "LocationBasedIoTResource", "AuthenticateIoT", "ConnectIoT", "RegisterIoT", "RevokeIoT", "AllocateIoTBandwidth", "UpdateIoTStatus", "DetectIoTFault", "TrackIoTSession", "EncryptIoTData"].includes(contract)) {
        channel = "IoTChannel";
    } else if (["AuthenticateUser", "RegisterUser", "RevokeUser", "EncryptData", "DetectIntrusion", "ManageKey", "AuthenticateAntenna", "CreateSecureChannel"].includes(contract)) {
        channel = "SecurityChannel";
    } else if (["LocationBasedFault", "LocationBasedUserActivity", "LogIdentityAudit", "LogResourceAudit", "LogConnectionAudit", "LogSecurityAudit", "LogTransaction", "LogAccess", "LogNetworkAudit"].includes(contract)) {
        channel = "AuditChannel";
    } else if (["GenerateBill"].includes(contract)) {
        channel = "BillingChannel";
    } else if (["LocationBasedBandwidth", "LocationBasedResourceAllocation", "RequestResource", "ShareSpectrum", "AllocateDynamic", "AllocateNetworkResource"].includes(contract)) {
        channel = "ResourceChannel";
    } else if (["LocationBasedQoS", "LocationBasedTraffic", "LocationBasedLatency", "LocationBasedEnergy", "LocationBasedSignalStrength", "LocationBasedCoverage", "LocationBasedNetworkHealth", "LocationBasedNetworkPerformance", "UpdateAntennaLoad", "BalanceLoad", "TrackLatency", "MonitorEnergy", "DetectAntennaFault", "MonitorAntennaTraffic", "MonitorNetworkCongestion", "MonitorNetworkHealth"].includes(contract)) {
        channel = "PerformanceChannel";
    } else if (["LocationBasedSessionManagement", "TrackSession", "TrackIoTSession"].includes(contract)) {
        channel = "SessionChannel";
    } else if (["LocationBasedConnection", "LocationBasedRoaming", "LocationBasedDynamicRouting", "LocationBasedChannelAllocation", "ConnectUser", "DisconnectEntity", "PerformRoaming"].includes(contract)) {
        channel = "ConnectivityChannel";
    } else if (["LocationBasedPriority", "AssignGeneralPriority", "GrantAccess", "SetPolicy", "ManageNetworkPolicy"].includes(contract)) {
        channel = "PolicyChannel";
    }

    const args = contract.includes("LocationBased") ?
        ["user1", "Antenna1", `${(Math.random() * 180 - 90).toFixed(4)}`, `${(Math.random() * 360 - 180).toFixed(4)}`] :
        ["user1", "value"];

    tapeConfig.chaincodes.push({
        chaincodeId: contract,
        channelName: channel,
        invoke: {
            target: `invoke`,
            arguments: args,
            transient: {}
        }
    });
});

fs.writeFileSync('tape-config.yaml', JSON.stringify(tapeConfig, null, 2));
