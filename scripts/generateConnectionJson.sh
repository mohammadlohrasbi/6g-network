#!/bin/bash

# تعداد سازمان‌ها (پیش‌فرض 8، قابل تنظیم)
ORG_COUNT=${ORG_COUNT:-8}

# لیست 20 کانال
CHANNELS=("NetworkChannel" "ResourceChannel" "PerformanceChannel" "IoTChannel" "AuthChannel" "ConnectivityChannel" "SessionChannel" "PolicyChannel" "AuditChannel" "SecurityChannel" "DataChannel" "AnalyticsChannel" "MonitoringChannel" "ManagementChannel" "OptimizationChannel" "FaultChannel" "TrafficChannel" "AccessChannel" "ComplianceChannel" "IntegrationChannel")

# تولید فایل‌های اتصال JSON برای هر سازمان
mkdir -p config

for ((i=1; i<=ORG_COUNT; i++)); do
    ORG_NAME="Org${i}"
    PEER_PORT=$((7051 + (i-1)*2000))
    CA_PORT=$((7054 + (i-1)*1000))
    cat > config/connection-org${i}.json <<EOF
{
  "name": "6g-fabric-network-org${i}",
  "version": "1.0.0",
  "client": {
    "organization": "${ORG_NAME}",
    "connection": {
      "timeout": {
        "peer": {
          "endorser": "300",
          "eventHub": "300",
          "eventReg": "300"
        },
        "orderer": "300"
      }
    }
  },
  "organizations": {
    "${ORG_NAME}": {
      "mspid": "${ORG_NAME}MSP",
      "peers": ["peer0.${ORG_NAME,,}.example.com"],
      "certificateAuthorities": ["ca.${ORG_NAME,,}.example.com"]
    }
  },
  "peers": {
    "peer0.${ORG_NAME,,}.example.com": {
      "url": "grpcs://localhost:${PEER_PORT}",
      "tlsCACerts": {
        "path": "/crypto-config/peerOrganizations/${ORG_NAME,,}.example.com/peers/peer0.${ORG_NAME,,}.example.com/tls/ca.crt"
      },
      "grpcOptions": {
        "ssl-target-name-override": "peer0.${ORG_NAME,,}.example.com",
        "hostnameOverride": "peer0.${ORG_NAME,,}.example.com"
      }
    }
  },
  "certificateAuthorities": {
    "ca.${ORG_NAME,,}.example.com": {
      "url": "https://localhost:${CA_PORT}",
      "caName": "ca-org${i}",
      "tlsCACerts": {
        "path": "/crypto-config/peerOrganizations/${ORG_NAME,,}.example.com/ca/ca.${ORG_NAME,,}.example.com-cert.pem"
      },
      "httpOptions": {
        "verify": false
      }
    }
  },
  "orderers": {
    "orderer1.example.com": {
      "url": "grpcs://localhost:7050",
      "tlsCACerts": {
        "path": "/crypto-config/ordererOrganizations/example.com/orderers/orderer1.example.com/tls/ca.crt"
      },
      "grpcOptions": {
        "ssl-target-name-override": "orderer1.example.com"
      }
    }
  },
  "channels": {
$(for CHANNEL in "${CHANNELS[@]}"; do
    echo "    \"${CHANNEL}\": {\"peers\": {\"peer0.${ORG_NAME,,}.example.com\": {}}},"
done | sed '$s/,$//')
  }
}
EOF
done

echo "Generated connection JSON files for $ORG_COUNT organizations"
