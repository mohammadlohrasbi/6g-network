#!/bin/bash

# تولید فایل‌های بار کاری
mkdir -p test/workloads
cat > test/workloads/workload.json <<EOF
{
  "numUsers": 50,
  "numTx": 1000,
  "targetTPS": 50,
  "contracts": [
    {
      "channel": "IoTChannel",
      "contract": "LocationBasedIoTBandwidth",
      "function": "AllocateIoTBandwidth",
      "argsTemplate": ["iot{id}", "Antenna{rand:10}", "{rand:100}Mbps", "{rand:180:-90}", "{rand:360:-180}"]
    },
    {
      "channel": "AuditChannel",
      "contract": "LogPerformanceAudit",
      "function": "Log",
      "argsTemplate": ["entity{id}", "Latency", "{rand:100}ms"]
    },
    {
      "channel": "NetworkChannel",
      "contract": "AssetManagement",
      "function": "CreateAsset",
      "argsTemplate": ["asset{id}", "Network", "{rand:1000}"]
    },
    {
      "channel": "AuthChannel",
      "contract": "AuthenticateUser",
      "function": "Authenticate",
      "argsTemplate": ["user{id}", "password{rand:1000}"]
    },
    {
      "channel": "SecurityChannel",
      "contract": "EncryptData",
      "function": "Encrypt",
      "argsTemplate": ["entity{id}", "data{rand:1000}"]
    },
    {
      "channel": "ResourceChannel",
      "contract": "LocationBasedResource",
      "function": "Allocate",
      "argsTemplate": ["entity{id}", "resource{rand:1000}", "{rand:100}", "{rand:180:-90}", "{rand:360:-180}"]
    },
    {
      "channel": "PerformanceChannel",
      "contract": "LogPerformance",
      "function": "Log",
      "argsTemplate": ["entity{id}", "Performance", "{rand:100}"]
    },
    {
      "channel": "SessionChannel",
      "contract": "LogSession",
      "function": "Log",
      "argsTemplate": ["session{id}", "start", "{rand:1000}"]
    },
    {
      "channel": "PolicyChannel",
      "contract": "SetPolicy",
      "function": "Set",
      "argsTemplate": ["policy{id}", "rule{rand:1000}"]
    },
    {
      "channel": "MonitoringChannel",
      "contract": "MonitorNetwork",
      "function": "Monitor",
      "argsTemplate": ["network{id}", "{rand:100}"]
    }
  ]
}
EOF

echo "Generated test/workloads/workload.json"
