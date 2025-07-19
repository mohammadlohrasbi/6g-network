#!/bin/bash

contracts=(
    "MonitorNetwork" "MonitorIoT" "LogFault" "LogPerformance" "LogSession" "LogTraffic" "LogInterference" "LogResourceAudit"
)

for contract in "${contracts[@]}"; do
    mkdir -p chaincode/$contract
    case $contract in
        MonitorNetwork)
            cat > chaincode/$contract/chaincode.go <<EOF
package main

import (
    "encoding/json"
    "fmt"
    "time"
    "github.com/hyperledger/fabric-contract-api-go/contractapi"
)

type MonitorNetwork struct {
    contractapi.Contract
}

type NetworkMonitorRecord struct {
    NetworkID string `json:"networkID"`
    Status    string `json:"status"`
    Timestamp string `json:"timestamp"`
}

func (s *MonitorNetwork) Init(ctx contractapi.TransactionContextInterface) error {
    return nil
}

func (s *MonitorNetwork) RecordStatus(ctx contractapi.TransactionContextInterface, networkID, status string) error {
    record := NetworkMonitorRecord{
        NetworkID: networkID,
        Status:    status,
        Timestamp: time.Now().String(),
    }
    recordJSON, err := json.Marshal(record)
    if err != nil {
        return err
    }
    return ctx.GetStub().PutState(networkID, recordJSON)
}

func (s *MonitorNetwork) QueryAsset(ctx contractapi.TransactionContextInterface, networkID string) (*NetworkMonitorRecord, error) {
    assetJSON, err := ctx.GetStub().GetState(networkID)
    if err != nil {
        return nil, err
    }
    if assetJSON == nil {
        return nil, fmt.Errorf("network monitor record %s does not exist", networkID)
    }
    var record NetworkMonitorRecord
    err = json.Unmarshal(assetJSON, &record)
    if err != nil {
        return nil, err
    }
    return &record, nil
}

func (s *MonitorNetwork) QueryAllAssets(ctx contractapi.TransactionContextInterface) ([]*NetworkMonitorRecord, error) {
    resultsIterator, err := ctx.GetStub().GetStateByRange("", "")
    if err != nil {
        return nil, err
    }
    defer resultsIterator.Close()

    var records []*NetworkMonitorRecord
    for resultsIterator.HasNext() {
        queryResponse, err := resultsIterator.Next()
        if err != nil {
            return nil, err
        }
        var record NetworkMonitorRecord
        err = json.Unmarshal(queryResponse.Value, &record)
        if err != nil {
            return nil, err
        }
        records = append(records, &record)
    }
    return records, nil
}

func main() {
    chaincode, err := contractapi.NewChaincode(&MonitorNetwork{})
    if err != nil {
        fmt.Printf("Error creating MonitorNetwork chaincode: %v", err)
    }
    if err := chaincode.Start(); err != nil {
        fmt.Printf("Error starting MonitorNetwork chaincode: %v", err)
    }
}
EOF
            ;;
        MonitorIoT)
            cat > chaincode/$contract/chaincode.go <<EOF
package main

import (
    "encoding/json"
    "fmt"
    "time"
    "github.com/hyperledger/fabric-contract-api-go/contractapi"
)

type MonitorIoT struct {
    contractapi.Contract
}

type IoTMonitorRecord struct {
    DeviceID  string `json:"deviceID"`
    Status    string `json:"status"`
    Timestamp string `json:"timestamp"`
}

func (s *MonitorIoT) Init(ctx contractapi.TransactionContextInterface) error {
    return nil
}

func (s *MonitorIoT) RecordStatus(ctx contractapi.TransactionContextInterface, deviceID, status string) error {
    record := IoTMonitorRecord{
        DeviceID:  deviceID,
        Status:    status,
        Timestamp: time.Now().String(),
    }
    recordJSON, err := json.Marshal(record)
    if err != nil {
        return err
    }
    return ctx.GetStub().PutState(deviceID, recordJSON)
}

func (s *MonitorIoT) QueryAsset(ctx contractapi.TransactionContextInterface, deviceID string) (*IoTMonitorRecord, error) {
    assetJSON, err := ctx.GetStub().GetState(deviceID)
    if err != nil {
        return nil, err
    }
    if assetJSON == nil {
        return nil, fmt.Errorf("IoT monitor record %s does not exist", deviceID)
    }
    var record IoTMonitorRecord
    err = json.Unmarshal(assetJSON, &record)
    if err != nil {
        return nil, err
    }
    return &record, nil
}

func (s *MonitorIoT) QueryAllAssets(ctx contractapi.TransactionContextInterface) ([]*IoTMonitorRecord, error) {
    resultsIterator, err := ctx.GetStub().GetStateByRange("", "")
    if err != nil {
        return nil, err
    }
    defer resultsIterator.Close()

    var records []*IoTMonitorRecord
    for resultsIterator.HasNext() {
        queryResponse, err := resultsIterator.Next()
        if err != nil {
            return nil, err
        }
        var record IoTMonitorRecord
        err = json.Unmarshal(queryResponse.Value, &record)
        if err != nil {
            return nil, err
        }
        records = append(records, &record)
    }
    return records, nil
}

func main() {
    chaincode, err := contractapi.NewChaincode(&MonitorIoT{})
    if err != nil {
        fmt.Printf("Error creating MonitorIoT chaincode: %v", err)
    }
    if err := chaincode.Start(); err != nil {
        fmt.Printf("Error starting MonitorIoT chaincode: %v", err)
    }
}
EOF
            ;;
        LogFault)
            cat > chaincode/$contract/chaincode.go <<EOF
package main

import (
    "encoding/json"
    "fmt"
    "time"
    "github.com/hyperledger/fabric-contract-api-go/contractapi"
)

type LogFault struct {
    contractapi.Contract
}

type FaultLog struct {
    EntityID  string `json:"entityID"`
    FaultType string `json:"faultType"`
    Timestamp string `json:"timestamp"`
}

func (s *LogFault) Init(ctx contractapi.TransactionContextInterface) error {
    return nil
}

func (s *LogFault) Log(ctx contractapi.TransactionContextInterface, entityID, faultType string) error {
    log := FaultLog{
        EntityID:  entityID,
        FaultType: faultType,
        Timestamp: time.Now().String(),
    }
    logJSON, err := json.Marshal(log)
    if err != nil {
        return err
    }
    return ctx.GetStub().PutState(entityID, logJSON)
}

func (s *LogFault) QueryAsset(ctx contractapi.TransactionContextInterface, entityID string) (*FaultLog, error) {
    assetJSON, err := ctx.GetStub().GetState(entityID)
    if err != nil {
        return nil, err
    }
    if assetJSON == nil {
        return nil, fmt.Errorf("fault log %s does not exist", entityID)
    }
    var log FaultLog
    err = json.Unmarshal(assetJSON, &log)
    if err != nil {
        return nil, err
    }
    return &log, nil
}

func (s *LogFault) QueryAllAssets(ctx contractapi.TransactionContextInterface) ([]*FaultLog, error) {
    resultsIterator, err := ctx.GetStub().GetStateByRange("", "")
    if err != nil {
        return nil, err
    }
    defer resultsIterator.Close()

    var logs []*FaultLog
    for resultsIterator.HasNext() {
        queryResponse, err := resultsIterator.Next()
        if err != nil {
            return nil, err
        }
        var log FaultLog
        err = json.Unmarshal(queryResponse.Value, &log)
        if err != nil {
            return nil, err
        }
        logs = append(logs, &log)
    }
    return logs, nil
}

func main() {
    chaincode, err := contractapi.NewChaincode(&LogFault{})
    if err != nil {
        fmt.Printf("Error creating LogFault chaincode: %v", err)
    }
    if err := chaincode.Start(); err != nil {
        fmt.Printf("Error starting LogFault chaincode: %v", err)
    }
}
EOF
            ;;
        LogPerformance)
            cat > chaincode/$contract/chaincode.go <<EOF
package main

import (
    "encoding/json"
    "fmt"
    "time"
    "github.com/hyperledger/fabric-contract-api-go/contractapi"
)

type LogPerformance struct {
    contractapi.Contract
}

type PerformanceLog struct {
    EntityID  string `json:"entityID"`
    Metric    string `json:"metric"`
    Value     string `json:"value"`
    Timestamp string `json:"timestamp"`
}

func (s *LogPerformance) Init(ctx contractapi.TransactionContextInterface) error {
    return nil
}

func (s *LogPerformance) Log(ctx contractapi.TransactionContextInterface, entityID, metric, value string) error {
    log := PerformanceLog{
        EntityID:  entityID,
        Metric:    metric,
        Value:     value,
        Timestamp: time.Now().String(),
    }
    logJSON, err := json.Marshal(log)
    if err != nil {
        return err
    }
    return ctx.GetStub().PutState(entityID, logJSON)
}

func (s *LogPerformance) QueryAsset(ctx contractapi.TransactionContextInterface, entityID string) (*PerformanceLog, error) {
    assetJSON, err := ctx.GetStub().GetState(entityID)
    if err != nil {
        return nil, err
    }
    if assetJSON == nil {
        return nil, fmt.Errorf("performance log %s does not exist", entityID)
    }
    var log PerformanceLog
    err = json.Unmarshal(assetJSON, &log)
    if err != nil {
        return nil, err
    }
    return &log, nil
}

func (s *LogPerformance) QueryAllAssets(ctx contractapi.TransactionContextInterface) ([]*PerformanceLog, error) {
    resultsIterator, err := ctx.GetStub().GetStateByRange("", "")
    if err != nil {
        return nil, err
    }
    defer resultsIterator.Close()

    var logs []*PerformanceLog
    for resultsIterator.HasNext() {
        queryResponse, err := resultsIterator.Next()
        if err != nil {
            return nil, err
        }
        var log PerformanceLog
        err = json.Unmarshal(queryResponse.Value, &log)
        if err != nil {
            return nil, err
        }
        logs = append(logs, &log)
    }
    return logs, nil
}

func main() {
    chaincode, err := contractapi.NewChaincode(&LogPerformance{})
    if err != nil {
        fmt.Printf("Error creating LogPerformance chaincode: %v", err)
    }
    if err := chaincode.Start(); err != nil {
        fmt.Printf("Error starting LogPerformance chaincode: %v", err)
    }
}
EOF
            ;;
        LogSession)
            cat > chaincode/$contract/chaincode.go <<EOF
package main

import (
    "encoding/json"
    "fmt"
    "time"
    "github.com/hyperledger/fabric-contract-api-go/contractapi"
)

type LogSession struct {
    contractapi.Contract
}

type SessionLog struct {
    EntityID  string `json:"entityID"`
    SessionID string `json:"sessionID"`
    Status    string `json:"status"`
    Timestamp string `json:"timestamp"`
}

func (s *LogSession) Init(ctx contractapi.TransactionContextInterface) error {
    return nil
}

func (s *LogSession) Log(ctx contractapi.TransactionContextInterface, entityID, sessionID, status string) error {
    log := SessionLog{
        EntityID:  entityID,
        SessionID: sessionID,
        Status:    status,
        Timestamp: time.Now().String(),
    }
    logJSON, err := json.Marshal(log)
    if err != nil {
        return err
    }
    return ctx.GetStub().PutState(entityID, logJSON)
}

func (s *LogSession) QueryAsset(ctx contractapi.TransactionContextInterface, entityID string) (*SessionLog, error) {
    assetJSON, err := ctx.GetStub().GetState(entityID)
    if err != nil {
        return nil, err
    }
    if assetJSON == nil {
        return nil, fmt.Errorf("session log %s does not exist", entityID)
    }
    var log SessionLog
    err = json.Unmarshal(assetJSON, &log)
    if err != nil {
        return nil, err
    }
    return &log, nil
}

func (s *LogSession) QueryAllAssets(ctx contractapi.TransactionContextInterface) ([]*SessionLog, error) {
    resultsIterator, err := ctx.GetStub().GetStateByRange("", "")
    if err != nil {
        return nil, err
    }
    defer resultsIterator.Close()

    var logs []*SessionLog
    for resultsIterator.HasNext() {
        queryResponse, err := resultsIterator.Next()
        if err != nil {
            return nil, err
        }
        var log SessionLog
        err = json.Unmarshal(queryResponse.Value, &log)
        if err != nil {
            return nil, err
        }
        logs = append(logs, &log)
    }
    return logs, nil
}

func main() {
    chaincode, err := contractapi.NewChaincode(&LogSession{})
    if err != nil {
        fmt.Printf("Error creating LogSession chaincode: %v", err)
    }
    if err := chaincode.Start(); err != nil {
        fmt.Printf("Error starting LogSession chaincode: %v", err)
    }
}
EOF
            ;;
        LogTraffic)
            cat > chaincode/$contract/chaincode.go <<EOF
package main

import (
    "encoding/json"
    "fmt"
    "time"
    "github.com/hyperledger/fabric-contract-api-go/contractapi"
)

type LogTraffic struct {
    contractapi.Contract
}

type TrafficLog struct {
    EntityID  string `json:"entityID"`
    Traffic   string `json:"traffic"`
    Timestamp string `json:"timestamp"`
}

func (s *LogTraffic) Init(ctx contractapi.TransactionContextInterface) error {
    return nil
}

func (s *LogTraffic) Log(ctx contractapi.TransactionContextInterface, entityID, traffic string) error {
    log := TrafficLog{
        EntityID:  entityID,
        Traffic:   traffic,
        Timestamp: time.Now().String(),
    }
    logJSON, err := json.Marshal(log)
    if err != nil {
        return err
    }
    return ctx.GetStub().PutState(entityID, logJSON)
}

func (s *LogTraffic) QueryAsset(ctx contractapi.TransactionContextInterface, entityID string) (*TrafficLog, error) {
    assetJSON, err := ctx.GetStub().GetState(entityID)
    if err != nil {
        return nil, err
    }
    if assetJSON == nil {
        return nil, fmt.Errorf("traffic log %s does not exist", entityID)
    }
    var log TrafficLog
    err = json.Unmarshal(assetJSON, &log)
    if err != nil {
        return nil, err
    }
    return &log, nil
}

func (s *LogTraffic) QueryAllAssets(ctx contractapi.TransactionContextInterface) ([]*TrafficLog, error) {
    resultsIterator, err := ctx.GetStub().GetStateByRange("", "")
    if err != nil {
        return nil, err
    }
    defer resultsIterator.Close()

    var logs []*TrafficLog
    for resultsIterator.HasNext() {
        queryResponse, err := resultsIterator.Next()
        if err != nil {
            return nil, err
        }
        var log TrafficLog
        err = json.Unmarshal(queryResponse.Value, &log)
        if err != nil {
            return nil, err
        }
        logs = append(logs, &log)
    }
    return logs, nil
}

func main() {
    chaincode, err := contractapi.NewChaincode(&LogTraffic{})
    if err != nil {
        fmt.Printf("Error creating LogTraffic chaincode: %v", err)
    }
    if err := chaincode.Start(); err != nil {
        fmt.Printf("Error starting LogTraffic chaincode: %v", err)
    }
}
EOF
            ;;
        LogInterference)
            cat > chaincode/$contract/chaincode.go <<EOF
package main

import (
    "encoding/json"
    "fmt"
    "time"
    "github.com/hyperledger/fabric-contract-api-go/contractapi"
)

type LogInterference struct {
    contractapi.Contract
}

type InterferenceLog struct {
    EntityID  string `json:"entityID"`
    InterferenceLevel string `json:"interferenceLevel"`
    Timestamp string `json:"timestamp"`
}

func (s *LogInterference) Init(ctx contractapi.TransactionContextInterface) error {
    return nil
}

func (s *LogInterference) Log(ctx contractapi.TransactionContextInterface, entityID, interferenceLevel string) error {
    log := InterferenceLog{
        EntityID:  entityID,
        InterferenceLevel: interferenceLevel,
        Timestamp: time.Now().String(),
    }
    logJSON, err := json.Marshal(log)
    if err != nil {
        return err
    }
    return ctx.GetStub().PutState(entityID, logJSON)
}

func (s *LogInterference) QueryAsset(ctx contractapi.TransactionContextInterface, entityID string) (*InterferenceLog, error) {
    assetJSON, err := ctx.GetStub().GetState(entityID)
    if err != nil {
        return nil, err
    }
    if assetJSON == nil {
        return nil, fmt.Errorf("interference log %s does not exist", entityID)
    }
    var log InterferenceLog
    err = json.Unmarshal(assetJSON, &log)
    if err != nil {
        return nil, err
    }
    return &log, nil
}

func (s *LogInterference) QueryAllAssets(ctx contractapi.TransactionContextInterface) ([]*InterferenceLog, error) {
    resultsIterator, err := ctx.GetStub().GetStateByRange("", "")
    if err != nil {
        return nil, err
    }
    defer resultsIterator.Close()

    var logs []*InterferenceLog
    for resultsIterator.HasNext() {
        queryResponse, err := resultsIterator.Next()
        if err != nil {
            return nil, err
        }
        var log InterferenceLog
        err = json.Unmarshal(queryResponse.Value, &log)
        if err != nil {
            return nil, err
        }
        logs = append(logs, &log)
    }
    return logs, nil
}

func main() {
    chaincode, err := contractapi.NewChaincode(&LogInterference{})
    if err != nil {
        fmt.Printf("Error creating LogInterference chaincode: %v", err)
    }
    if err := chaincode.Start(); err != nil {
        fmt.Printf("Error starting LogInterference chaincode: %v", err)
    }
}
EOF
            ;;
        LogResourceAudit)
            cat > chaincode/$contract/chaincode.go <<EOF
package main

import (
    "encoding/json"
    "fmt"
    "time"
    "github.com/hyperledger/fabric-contract-api-go/contractapi"
)

type LogResourceAudit struct {
    contractapi.Contract
}

type ResourceAuditLog struct {
    EntityID  string `json:"entityID"`
    Resource  string `json:"resource"`
    Amount    string `json:"amount"`
    Timestamp string `json:"timestamp"`
}

func (s *LogResourceAudit) Init(ctx contractapi.TransactionContextInterface) error {
    return nil
}

func (s *LogResourceAudit) Log(ctx contractapi.TransactionContextInterface, entityID, resource, amount string) error {
    log := ResourceAuditLog{
        EntityID:  entityID,
        Resource:  resource,
        Amount:    amount,
        Timestamp: time.Now().String(),
    }
    logJSON, err := json.Marshal(log)
    if err != nil {
        return err
    }
    return ctx.GetStub().PutState(entityID, logJSON)
}

func (s *LogResourceAudit) QueryAsset(ctx contractapi.TransactionContextInterface, entityID string) (*ResourceAuditLog, error) {
    assetJSON, err := ctx.GetStub().GetState(entityID)
    if err != nil {
        return nil, err
    }
    if assetJSON == nil {
        return nil, fmt.Errorf("resource audit log %s does not exist", entityID)
    }
    var log ResourceAuditLog
    err = json.Unmarshal(assetJSON, &log)
    if err != nil {
        return nil, err
    }
    return &log, nil
}

func (s *LogResourceAudit) QueryAllAssets(ctx contractapi.TransactionContextInterface) ([]*ResourceAuditLog, error) {
    resultsIterator, err := ctx.GetStub().GetStateByRange("", "")
    if err != nil {
        return nil, err
    }
    defer resultsIterator.Close()

    var logs []*ResourceAuditLog
    for resultsIterator.HasNext() {
        queryResponse, err := resultsIterator.Next()
        if err != nil {
            return nil, err
        }
        var log ResourceAuditLog
        err = json.Unmarshal(queryResponse.Value, &log)
        if err != nil {
            return nil, err
        }
        logs = append(logs, &log)
    }
    return logs, nil
}

func main() {
    chaincode, err := contractapi.NewChaincode(&LogResourceAudit{})
    if err != nil {
        fmt.Printf("Error creating LogResourceAudit chaincode: %v", err)
    }
    if err := chaincode.Start(); err != nil {
        fmt.Printf("Error starting LogResourceAudit chaincode: %v", err)
    }
}
EOF
            ;;
    esac
done

echo "Generated chaincode for ${#contracts[@]} contracts in part 6:"
for contract in "${contracts[@]}"; do
    if [ -f "chaincode/$contract/chaincode.go" ]; then
        echo " - $contract: OK"
    else
        echo " - $contract: Failed"
    fi
done
