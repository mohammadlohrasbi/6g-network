#!/bin/bash

# تعداد سازمان‌ها (قابل تنظیم)
ORG_COUNT=${ORG_COUNT:-3}

# لیست 20 کانال
CHANNELS=("NetworkChannel" "ResourceChannel" "PerformanceChannel" "IoTChannel" "AuthChannel" "ConnectivityChannel" "SessionChannel" "PolicyChannel" "AuditChannel" "SecurityChannel" "DataChannel" "AnalyticsChannel" "MonitoringChannel" "ManagementChannel" "OptimizationChannel" "FaultChannel" "TrafficChannel" "AccessChannel" "ComplianceChannel" "IntegrationChannel")

# تولید پروفایل‌های اتصال برای هر سازمان
mkdir -p config/profiles

for ((i=1; i<=ORG_COUNT; i++)); do
    ORG_NAME="Org${i}"
    PEER_PORT=$((7051 + (i-1)*2000))
    cat > config/profiles/org${i}-profile.yaml <<EOF
name: Org${i}Profile
channels:
$(for CHANNEL in "${CHANNELS[@]}"; do
    echo "  ${CHANNEL}:"
    echo "    peers:"
    echo "      peer0.${ORG_NAME,,}.example.com:"
    echo "        endorsingPeer: true"
    echo "        chaincodeQuery: true"
    echo "        ledgerQuery: true"
    echo "        eventSource: true"
done)
peers:
  peer0.${ORG_NAME,,}.example.com:
    url: grpcs://localhost:${PEER_PORT}
    tlsCACerts:
      path: /crypto-config/peerOrganizations/${ORG_NAME,,}.example.com/peers/peer0.${ORG_NAME,,}.example.com/tls/ca.crt
EOF
done

echo "Generated connection profile YAML files for $ORG_COUNT organizations"
