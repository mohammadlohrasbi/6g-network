#!/bin/bash

# تولید فایل‌های بار کاری برای همه 85 قرارداد هوشمند و 20 کانال
mkdir -p test/workloads
cat > test/workloads/workload.json <<EOF
{
  "numUsers": 50,
  "numTx": 1000,
  "targetTPS": 50,
  "contracts": [
    {
      "channel": "NetworkChannel",
      "contract": "AssetManagement",
      "function": "CreateAsset",
      "argsTemplate": ["asset{id}", "Network", "{rand:1000}"]
    },
    {
      "channel": "NetworkChannel",
      "contract": "UserManagement",
      "function": "CreateUser",
      "argsTemplate": ["user{id}", "role{rand:1000}"]
    },
    {
      "channel": "NetworkChannel",
      "contract": "IoTManagement",
      "function": "RegisterIoT",
      "argsTemplate": ["iot{id}", "{rand:1000}"]
    },
    {
      "channel": "NetworkChannel",
      "contract": "AntennaManagement",
      "function": "RegisterAntenna",
      "argsTemplate": ["antenna{id}", "{rand:180:-90}", "{rand:360:-180}"]
    },
    {
      "channel": "NetworkChannel",
      "contract": "NetworkManagement",
      "function": "ConfigureNetwork",
      "argsTemplate": ["network{id}", "{rand:1000}"]
    },
    {
      "channel": "NetworkChannel",
      "contract": "ResourceManagement",
      "function": "AllocateResource",
      "argsTemplate": ["resource{id}", "{rand:100}"]
    },
    {
      "channel": "NetworkChannel",
      "contract": "PerformanceManagement",
      "function": "LogPerformance",
      "argsTemplate": ["entity{id}", "{rand:100}"]
    },
    {
      "channel": "NetworkChannel",
      "contract": "SessionManagement",
      "function": "CreateSession",
      "argsTemplate": ["session{id}", "{rand:1000}"]
    },
    {
      "channel": "NetworkChannel",
      "contract": "PolicyManagement",
      "function": "SetPolicy",
      "argsTemplate": ["policy{id}", "rule{rand:1000}"]
    },
    {
      "channel": "ResourceChannel",
      "contract": "LocationBasedAccess",
      "function": "GrantAccess",
      "argsTemplate": ["entity{id}", "{rand:180:-90}", "{rand:360:-180}"]
    },
    {
      "channel": "ResourceChannel",
      "contract": "LocationBasedResource",
      "function": "Allocate",
      "argsTemplate": ["entity{id}", "resource{rand:1000}", "{rand:100}", "{rand:180:-90}", "{rand:360:-180}"]
    },
    {
      "channel": "ResourceChannel",
      "contract": "LocationBasedPerformance",
      "function": "Log",
      "argsTemplate": ["entity{id}", "{rand:100}", "{rand:180:-90}", "{rand:360:-180}"]
    },
    {
      "channel": "ResourceChannel",
      "contract": "LocationBasedSession",
      "function": "Create",
      "argsTemplate": ["session{id}", "{rand:180:-90}", "{rand:360:-180}"]
    },
    {
      "channel": "ResourceChannel",
      "contract": "LocationBasedPolicy",
      "function": "Set",
      "argsTemplate": ["policy{id}", "rule{rand:1000}", "{rand:180:-90}", "{rand:360:-180}"]
    },
    {
      "channel": "ResourceChannel",
      "contract": "LocationBasedConnectivity",
      "function": "Connect",
      "argsTemplate": ["entity{id}", "{rand:180:-90}", "{rand:360:-180}"]
    },
    {
      "channel": "ResourceChannel",
      "contract": "LocationBasedAudit",
      "function": "Log",
      "argsTemplate": ["entity{id}", "event{rand:1000}", "{rand:180:-90}", "{rand:360:-180}"]
    },
    {
      "channel": "ResourceChannel",
      "contract": "LocationBasedSecurity",
      "function": "Secure",
      "argsTemplate": ["entity{id}", "{rand:180:-90}", "{rand:360:-180}"]
    },
    {
      "channel": "ResourceChannel",
      "contract": "LocationBasedNetwork",
      "function": "Configure",
      "argsTemplate": ["network{id}", "{rand:180:-90}", "{rand:360:-180}"]
    },
    {
      "channel": "ResourceChannel",
      "contract": "LocationBasedCongestion",
      "function": "Monitor",
      "argsTemplate": ["network{id}", "{rand:100}", "{rand:180:-90}", "{rand:360:-180}"]
    },
    {
      "channel": "IoTChannel",
      "contract": "LocationBasedIoTConnection",
      "function": "Connect",
      "argsTemplate": ["iot{id}", "network{rand:1000}", "{rand:180:-90}", "{rand:360:-180}"]
    },
    {
      "channel": "IoTChannel",
      "contract": "LocationBasedIoTPerformance",
      "function": "Log",
      "argsTemplate": ["iot{id}", "{rand:100}", "{rand:180:-90}", "{rand:360:-180}"]
    },
    {
      "channel": "IoTChannel",
      "contract": "LocationBasedIoTSecurity",
      "function": "Secure",
      "argsTemplate": ["iot{id}", "{rand:180:-90}", "{rand:360:-180}"]
    },
    {
      "channel": "IoTChannel",
      "contract": "LocationBasedIoTAudit",
      "function": "Log",
      "argsTemplate": ["iot{id}", "event{rand:1000}", "{rand:180:-90}", "{rand:360:-180}"]
    },
    {
      "channel": "IoTChannel",
      "contract": "LocationBasedIoTAccess",
      "function": "GrantAccess",
      "argsTemplate": ["iot{id}", "{rand:180:-90}", "{rand:360:-180}"]
    },
    {
      "channel": "IoTChannel",
      "contract": "LocationBasedIoTResource",
      "function": "Allocate",
      "argsTemplate": ["iot{id}", "resource{rand:1000}", "{rand:180:-90}", "{rand:360:-180}"]
    },
    {
      "channel": "IoTChannel",
      "contract": "LocationBasedIoTNetwork",
      "function": "Configure",
      "argsTemplate": ["iot{id}", "{rand:180:-90}", "{rand:360:-180}"]
    },
    {
      "channel": "IoTChannel",
      "contract": "LocationBasedIoTActivity",
      "function": "Log",
      "argsTemplate": ["iot{id}", "activity{rand:1000}", "{rand:180:-90}", "{rand:360:-180}"]
    },
    {
      "channel": "IoTChannel",
      "contract": "LocationBasedIoTBandwidth",
      "function": "AllocateIoTBandwidth",
      "argsTemplate": ["iot{id}", "Antenna{rand:10}", "{rand:100}Mbps", "{rand:180:-90}", "{rand:360:-180}"]
    },
    {
      "channel": "IoTChannel",
      "contract": "LocationBasedIoTStatus",
      "function": "UpdateStatus",
      "argsTemplate": ["iot{id}", "status{rand:1000}", "{rand:180:-90}", "{rand:360:-180}"]
    },
    {
      "channel": "IoTChannel",
      "contract": "LocationBasedIoTFault",
      "function": "LogFault",
      "argsTemplate": ["iot{id}", "fault{rand:1000}", "{rand:180:-90}", "{rand:360:-180}"]
    },
    {
      "channel": "IoTChannel",
      "contract": "LocationBasedIoTSession",
      "function": "CreateSession",
      "argsTemplate": ["iot{id}", "{rand:180:-90}", "{rand:360:-180}"]
    },
    {
      "channel": "IoTChannel",
      "contract": "LocationBasedIoTAuthentication",
      "function": "Authenticate",
      "argsTemplate": ["iot{id}", "credential{rand:1000}", "{rand:180:-90}", "{rand:360:-180}"]
    },
    {
      "channel": "IoTChannel",
      "contract": "LocationBasedIoTRegistration",
      "function": "Register",
      "argsTemplate": ["iot{id}", "{rand:180:-90}", "{rand:360:-180}"]
    },
    {
      "channel": "IoTChannel",
      "contract": "LocationBasedIoTRevocation",
      "function": "Revoke",
      "argsTemplate": ["iot{id}", "{rand:180:-90}", "{rand:360:-180}"]
    },
    {
      "channel": "IoTChannel",
      "contract": "LocationBasedIoTResource",
      "function": "Allocate",
      "argsTemplate": ["iot{id}", "resource{rand:1000}", "{rand:180:-90}", "{rand:360:-180}"]
    },
    {
      "channel": "IoTChannel",
      "contract": "LocationBasedUserActivity",
      "function": "Log",
      "argsTemplate": ["user{id}", "activity{rand:1000}", "{rand:180:-90}", "{rand:360:-180}"]
    },
    {
      "channel": "AuthChannel",
      "contract": "AuthenticateUser",
      "function": "Authenticate",
      "argsTemplate": ["user{id}", "password{rand:1000}"]
    },
    {
      "channel": "AuthChannel",
      "contract": "AuthenticateIoT",
      "function": "Authenticate",
      "argsTemplate": ["iot{id}", "credential{rand:1000}"]
    },
    {
      "channel": "ConnectivityChannel",
      "contract": "ConnectUser",
      "function": "Connect",
      "argsTemplate": ["user{id}", "network{rand:1000}"]
    },
    {
      "channel": "ConnectivityChannel",
      "contract": "ConnectIoT",
      "function": "Connect",
      "argsTemplate": ["iot{id}", "network{rand:1000}"]
    },
    {
      "channel": "AuthChannel",
      "contract": "RegisterUser",
      "function": "Register",
      "argsTemplate": ["user{id}", "role{rand:1000}"]
    },
    {
      "channel": "AuthChannel",
      "contract": "RegisterIoT",
      "function": "Register",
      "argsTemplate": ["iot{id}", "type{rand:1000}"]
    },
    {
      "channel": "AuthChannel",
      "contract": "RevokeUser",
      "function": "Revoke",
      "argsTemplate": ["user{id}"]
    },
    {
      "channel": "AuthChannel",
      "contract": "RevokeIoT",
      "function": "Revoke",
      "argsTemplate": ["iot{id}"]
    },
    {
      "channel": "AuthChannel",
      "contract": "AssignRole",
      "function": "Assign",
      "argsTemplate": ["user{id}", "role{rand:1000}"]
    },
    {
      "channel": "MonitoringChannel",
      "contract": "MonitorNetwork",
      "function": "Monitor",
      "argsTemplate": ["network{id}", "{rand:100}"]
    },
    {
      "channel": "MonitoringChannel",
      "contract": "MonitorIoT",
      "function": "Monitor",
      "argsTemplate": ["iot{id}", "{rand:100}"]
    },
    {
      "channel": "AuditChannel",
      "contract": "LogFault",
      "function": "Log",
      "argsTemplate": ["entity{id}", "fault{rand:1000}"]
    },
    {
      "channel": "AuditChannel",
      "contract": "LogPerformance",
      "function": "Log",
      "argsTemplate": ["entity{id}", "{rand:100}"]
    },
    {
      "channel": "AuditChannel",
      "contract": "LogSession",
      "function": "Log",
      "argsTemplate": ["session{id}", "start", "{rand:1000}"]
    },
    {
      "channel": "AuditChannel",
      "contract": "LogTraffic",
      "function": "Log",
      "argsTemplate": ["network{id}", "{rand:100}"]
    },
    {
      "channel": "AuditChannel",
      "contract": "LogInterference",
      "function": "Log",
      "argsTemplate": ["network{id}", "{rand:100}"]
    },
    {
      "channel": "AuditChannel",
      "contract": "LogResourceAudit",
      "function": "Log",
      "argsTemplate": ["resource{id}", "{rand:1000}"]
    },
    {
      "channel": "ManagementChannel",
      "contract": "BalanceLoad",
      "function": "Balance",
      "argsTemplate": ["network{id}", "{rand:100}"]
    },
    {
      "channel": "ManagementChannel",
      "contract": "AllocateResource",
      "function": "Allocate",
      "argsTemplate": ["resource{id}", "{rand:100}"]
    },
    {
      "channel": "ManagementChannel",
      "contract": "OptimizeNetwork",
      "function": "Optimize",
      "argsTemplate": ["network{id}", "{rand:100}"]
    },
    {
      "channel": "ManagementChannel",
      "contract": "ManageSession",
      "function": "Manage",
      "argsTemplate": ["session{id}", "{rand:1000}"]
    },
    {
      "channel": "AuditChannel",
      "contract": "LogNetworkPerformance",
      "function": "Log",
      "argsTemplate": ["network{id}", "{rand:100}"]
    },
    {
      "channel": "AuditChannel",
      "contract": "LogUserActivity",
      "function": "Log",
      "argsTemplate": ["user{id}", "activity{rand:1000}"]
    },
    {
      "channel": "AuditChannel",
      "contract": "LogIoTActivity",
      "function": "Log",
      "argsTemplate": ["iot{id}", "activity{rand:1000}"]
    },
    {
      "channel": "AuditChannel",
      "contract": "LogSessionAudit",
      "function": "Log",
      "argsTemplate": ["session{id}", "{rand:1000}"]
    },
    {
      "channel": "AuditChannel",
      "contract": "LogConnectionAudit",
      "function": "Log",
      "argsTemplate": ["connection{id}", "{rand:1000}"]
    },
    {
      "channel": "SecurityChannel",
      "contract": "EncryptData",
      "function": "Encrypt",
      "argsTemplate": ["entity{id}", "data{rand:1000}"]
    },
    {
      "channel": "SecurityChannel",
      "contract": "DecryptData",
      "function": "Decrypt",
      "argsTemplate": ["entity{id}", "data{rand:1000}"]
    },
    {
      "channel": "SecurityChannel",
      "contract": "SecureCommunication",
      "function": "Secure",
      "argsTemplate": ["entity{id}", "{rand:1000}"]
    },
    {
      "channel": "SecurityChannel",
      "contract": "VerifyIdentity",
      "function": "Verify",
      "argsTemplate": ["entity{id}", "credential{rand:1000}"]
    },
    {
      "channel": "SecurityChannel",
      "contract": "SetPolicy",
      "function": "Set",
      "argsTemplate": ["policy{id}", "rule{rand:1000}"]
    },
    {
      "channel": "SecurityChannel",
      "contract": "GetPolicy",
      "function": "Get",
      "argsTemplate": ["policy{id}"]
    },
    {
      "channel": "SecurityChannel",
      "contract": "UpdatePolicy",
      "function": "Update",
      "argsTemplate": ["policy{id}", "rule{rand:1000}"]
    },
    {
      "channel": "SecurityChannel",
      "contract": "LogPolicyAudit",
      "function": "Log",
      "argsTemplate": ["policy{id}", "event{rand:1000}"]
    },
    {
      "channel": "ManagementChannel",
      "contract": "ManageNetwork",
      "function": "Manage",
      "argsTemplate": ["network{id}", "{rand:1000}"]
    },
    {
      "channel": "ManagementChannel",
      "contract": "ManageAntenna",
      "function": "Manage",
      "argsTemplate": ["antenna{id}", "{rand:180:-90}", "{rand:360:-180}"]
    },
    {
      "channel": "ManagementChannel",
      "contract": "ManageIoTDevice",
      "function": "Manage",
      "argsTemplate": ["iot{id}", "{rand:1000}"]
    },
    {
      "channel": "ManagementChannel",
      "contract": "ManageUser",
      "function": "Manage",
      "argsTemplate": ["user{id}", "{rand:1000}"]
    },
    {
      "channel": "MonitoringChannel",
      "contract": "MonitorTraffic",
      "function": "Monitor",
      "argsTemplate": ["network{id}", "{rand:100}"]
    },
    {
      "channel": "MonitoringChannel",
      "contract": "MonitorInterference",
      "function": "Monitor",
      "argsTemplate": ["network{id}", "{rand:100}"]
    },
    {
      "channel": "MonitoringChannel",
      "contract": "MonitorResourceUsage",
      "function": "Monitor",
      "argsTemplate": ["resource{id}", "{rand:100}"]
    },
    {
      "channel": "AuditChannel",
      "contract": "LogSecurityEvent",
      "function": "Log",
      "argsTemplate": ["event{id}", "{rand:1000}"]
    },
    {
      "channel": "AuditChannel",
      "contract": "LogAccessControl",
      "function": "Log",
      "argsTemplate": ["access{id}", "{rand:1000}"]
    },
    {
      "channel": "AuditChannel",
      "contract": "LogNetworkAudit",
      "function": "Log",
      "argsTemplate": ["network{id}", "{rand:1000}"]
    },
    {
      "channel": "AuditChannel",
      "contract": "LogAntennaAudit",
      "function": "Log",
      "argsTemplate": ["antenna{id}", "{rand:1000}"]
    },
    {
      "channel": "AuditChannel",
      "contract": "LogIoTAudit",
      "function": "Log",
      "argsTemplate": ["iot{id}", "{rand:1000}"]
    },
    {
      "channel": "AuditChannel",
      "contract": "LogUserAudit",
      "function": "Log",
      "argsTemplate": ["user{id}", "{rand:1000}"]
    },
    {
      "channel": "AuditChannel",
      "contract": "LogPolicyChange",
      "function": "Log",
      "argsTemplate": ["policy{id}", "{rand:1000}"]
    },
    {
      "channel": "AuditChannel",
      "contract": "LogAccessAudit",
      "function": "Log",
      "argsTemplate": ["access{id}", "{rand:1000}"]
    },
    {
      "channel": "AuditChannel",
      "contract": "LogPerformanceAudit",
      "function": "Log",
      "argsTemplate": ["entity{id}", "Latency", "{rand:100}ms"]
    },
    {
      "channel": "AuditChannel",
      "contract": "LogComplianceAudit",
      "function": "Log",
      "argsTemplate": ["compliance{id}", "{rand:1000}"]
    }
  ]
}
EOF

echo "Generated test/workloads/workload.json for all 85 smart contracts"
