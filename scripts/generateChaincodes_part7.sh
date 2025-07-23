#!/bin/bash

contracts=(
    "BalanceLoad" "AllocateResource" "OptimizeNetwork" "ManageSession" "LogNetworkPerformance" "LogUserActivity" "LogIoTActivity" "LogSessionAudit" "LogConnectionAudit"
)

for contract in "${contracts[@]}"; do
    mkdir -p chaincode/$contract
    case $contract in
        BalanceLoad)
            cat > chaincode/$contract/chaincode.go <<EOF
package main

import (
    "encoding/json"
    "fmt"
    "time"
    "github.com/hyperledger/fabric-contract-api-go/contractapi"
)

type BalanceLoad struct {
    contractapi.Contract
}

type LoadBalanceRecord struct {
    NetworkID string `json:"networkID"`
    Load      string `json:"load"`
    Timestamp string `json:"timestamp"`
}

func (s *BalanceLoad) Init(ctx contractapi.TransactionContextInterface) error {
    return nil
}

func (s *BalanceLoad) Balance(ctx contractapi.TransactionContextInterface, networkID, load string) error {
    record := LoadBalanceRecord{
        NetworkID: networkID,
        Load:      load,
        Timestamp: time.Now().String(),
    }
    recordJSON, err := json.Marshal(record)
    if err != nil {
        return err
    }
    return ctx.GetStub().PutState(networkID, recordJSON)
}

func (s *BalanceLoad) QueryAsset(ctx contractapi.TransactionContextInterface, networkID string) (*LoadBalanceRecord, error) {
    assetJSON, err := ctx.GetStub().GetState(networkID)
    if err != nil {
        return nil, err
    }
    if assetJSON == nil {
        return nil, fmt.Errorf("load balance record %s does not exist", networkID)
    }
    var record LoadBalanceRecord
    err = json.Unmarshal(assetJSON, &record)
    if err != nil {
        return nil, err
    }
    return &record, nil
}

func (s *BalanceLoad) QueryAllAssets(ctx contractapi.TransactionContextInterface) ([]*LoadBalanceRecord, error) {
    resultsIterator, err := ctx.GetStub().GetStateByRange("", "")
    if err != nil {
        return nil, err
    }
    defer resultsIterator.Close()

    var records []*LoadBalanceRecord
    for resultsIterator.HasNext() {
        queryResponse, err := resultsIterator.Next()
        if err != nil {
            return nil, err
        }
        var record LoadBalanceRecord
        err = json.Unmarshal(queryResponse.Value, &record)
        if err != nil {
            return nil, err
        }
        records = append(records, &record)
    }
    return records, nil
}

func main() {
    chaincode, err := contractapi.NewChaincode(&BalanceLoad{})
    if err != nil {
        fmt.Printf("Error creating BalanceLoad chaincode: %v", err)
    }
    if err := chaincode.Start(); err != nil {
        fmt.Printf("Error starting BalanceLoad chaincode: %v", err)
    }
}
EOF
            ;;
        AllocateResource)
            cat > chaincode/$contract/chaincode.go <<EOF
package main

import (
    "encoding/json"
    "fmt"
    "time"
    "github.com/hyperledger/fabric-contract-api-go/contractapi"
)

type AllocateResource struct {
    contractapi.Contract
}

type ResourceAllocation struct {
    EntityID  string `json:"entityID"`
    Resource  string `json:"resource"`
    Amount    string `json:"amount"`
    Timestamp string `json:"timestamp"`
}

func (s *AllocateResource) Init(ctx contractapi.TransactionContextInterface) error {
    return nil
}

func (s *AllocateResource) Allocate(ctx contractapi.TransactionContextInterface, entityID, resource, amount string) error {
    allocation := ResourceAllocation{
        EntityID:  entityID,
        Resource:  resource,
        Amount:    amount,
        Timestamp: time.Now().String(),
    }
    allocationJSON, err := json.Marshal(allocation)
    if err != nil {
        return err
    }
    return ctx.GetStub().PutState(entityID, allocationJSON)
}

func (s *AllocateResource) QueryAsset(ctx contractapi.TransactionContextInterface, entityID string) (*ResourceAllocation, error) {
    assetJSON, err := ctx.GetStub().GetState(entityID)
    if err != nil {
        return nil, err
    }
    if assetJSON == nil {
        return nil, fmt.Errorf("resource allocation %s does not exist", entityID)
    }
    var allocation ResourceAllocation
    err = json.Unmarshal(assetJSON, &allocation)
    if err != nil {
        return nil, err
    }
    return &allocation, nil
}

func (s *AllocateResource) QueryAllAssets(ctx contractapi.TransactionContextInterface) ([]*ResourceAllocation, error) {
    resultsIterator, err := ctx.GetStub().GetStateByRange("", "")
    if err != nil {
        return nil, err
    }
    defer resultsIterator.Close()

    var allocations []*ResourceAllocation
    for resultsIterator.HasNext() {
        queryResponse, err := resultsIterator.Next()
        if err != nil {
            return nil, err
        }
        var allocation ResourceAllocation
        err = json.Unmarshal(queryResponse.Value, &allocation)
        if err != nil {
            return nil, err
        }
        allocations = append(allocations, &allocation)
    }
    return allocations, nil
}

func main() {
    chaincode, err := contractapi.NewChaincode(&AllocateResource{})
    if err != nil {
        fmt.Printf("Error creating AllocateResource chaincode: %v", err)
    }
    if err := chaincode.Start(); err != nil {
        fmt.Printf("Error starting AllocateResource chaincode: %v", err)
    }
}
EOF
            ;;
        OptimizeNetwork)
            cat > chaincode/$contract/chaincode.go <<EOF
package main

import (
    "encoding/json"
    "fmt"
    "time"
    "github.com/hyperledger/fabric-contract-api-go/contractapi"
)

type OptimizeNetwork struct {
    contractapi.Contract
}

type NetworkOptimization struct {
    NetworkID string `json:"networkID"`
    Strategy  string `json:"strategy"`
    Timestamp string `json:"timestamp"`
}

func (s *OptimizeNetwork) Init(ctx contractapi.TransactionContextInterface) error {
    return nil
}

func (s *OptimizeNetwork) Optimize(ctx contractapi.TransactionContextInterface, networkID, strategy string) error {
    optimization := NetworkOptimization{
        NetworkID: networkID,
        Strategy:  strategy,
        Timestamp: time.Now().String(),
    }
    optimizationJSON, err := json.Marshal(optimization)
    if err != nil {
        return err
    }
    return ctx.GetStub().PutState(networkID, optimizationJSON)
}

func (s *OptimizeNetwork) QueryAsset(ctx contractapi.TransactionContextInterface, networkID string) (*NetworkOptimization, error) {
    assetJSON, err := ctx.GetStub().GetState(networkID)
    if err != nil {
        return nil, err
    }
    if assetJSON == nil {
        return nil, fmt.Errorf("network optimization %s does not exist", networkID)
    }
    var optimization NetworkOptimization
    err = json.Unmarshal(assetJSON, &optimization)
    if err != nil {
        return nil, err
    }
    return &optimization, nil
}

func (s *OptimizeNetwork) QueryAllAssets(ctx contractapi.TransactionContextInterface) ([]*NetworkOptimization, error) {
    resultsIterator, err := ctx.GetStub().GetStateByRange("", "")
    if err != nil {
        return nil, err
    }
    defer resultsIterator.Close()

    var optimizations []*NetworkOptimization
    for resultsIterator.HasNext() {
        queryResponse, err := resultsIterator.Next()
        if err != nil {
            return nil, err
        }
        var optimization NetworkOptimization
        err = json.Unmarshal(queryResponse.Value, &optimization)
        if err != nil {
            return nil, err
        }
        optimizations = append(optimizations, &optimization)
    }
    return optimizations, nil
}

func main() {
    chaincode, err := contractapi.NewChaincode(&OptimizeNetwork{})
    if err != nil {
        fmt.Printf("Error creating OptimizeNetwork chaincode: %v", err)
    }
    if err := chaincode.Start(); err != nil {
        fmt.Printf("Error starting OptimizeNetwork chaincode: %v", err)
    }
}
EOF
            ;;
        ManageSession)
            cat > chaincode/$contract/chaincode.go <<EOF
package main

import (
    "encoding/json"
    "fmt"
    "time"
    "github.com/hyperledger/fabric-contract-api-go/contractapi"
)

type ManageSession struct {
    contractapi.Contract
}

type SessionRecord struct {
    EntityID  string `json:"entityID"`
    SessionID string `json:"sessionID"`
    Status    string `json:"status"`
    Timestamp string `json:"timestamp"`
}

func (s *ManageSession) Init(ctx contractapi.TransactionContextInterface) error {
    return nil
}

func (s *ManageSession) StartSession(ctx contractapi.TransactionContextInterface, entityID, sessionID string) error {
    record := SessionRecord{
        EntityID:  entityID,
        SessionID: sessionID,
        Status:    "Active",
        Timestamp: time.Now().String(),
    }
    recordJSON, err := json.Marshal(record)
    if err != nil {
        return err
    }
    return ctx.GetStub().PutState(entityID, recordJSON)
}

func (s *ManageSession) EndSession(ctx contractapi.TransactionContextInterface, entityID string) error {
    record, err := s.QueryAsset(ctx, entityID)
    if err != nil {
        return err
    }
    record.Status = "Ended"
    record.Timestamp = time.Now().String()
    recordJSON, err := json.Marshal(record)
    if err != nil {
        return err
    }
    return ctx.GetStub().PutState(entityID, recordJSON)
}

func (s *ManageSession) QueryAsset(ctx contractapi.TransactionContextInterface, entityID string) (*SessionRecord, error) {
    assetJSON, err := ctx.GetStub().GetState(entityID)
    if err != nil {
        return nil, err
    }
    if assetJSON == nil {
        return nil, fmt.Errorf("session record %s does not exist", entityID)
    }
    var record SessionRecord
    err = json.Unmarshal(assetJSON, &record)
    if err != nil {
        return nil, err
    }
    return &record, nil
}

func (s *ManageSession) QueryAllAssets(ctx contractapi.TransactionContextInterface) ([]*SessionRecord, error) {
    resultsIterator, err := ctx.GetStub().GetStateByRange("", "")
    if err != nil {
        return nil, err
    }
    defer resultsIterator.Close()

    var records []*SessionRecord
    for resultsIterator.HasNext() {
        queryResponse, err := resultsIterator.Next()
        if err != nil {
            return nil, err
        }
        var record SessionRecord
        err = json.Unmarshal(queryResponse.Value, &record)
        if err != nil {
            return nil, err
        }
        records = append(records, &record)
    }
    return records, nil
}

func main() {
    chaincode, err := contractapi.NewChaincode(&ManageSession{})
    if err != nil {
        fmt.Printf("Error creating ManageSession chaincode: %v", err)
    }
    if err := chaincode.Start(); err != nil {
        fmt.Printf("Error starting ManageSession chaincode: %v", err)
    }
}
EOF
            ;;
        LogNetworkPerformance)
            cat > chaincode/$contract/chaincode.go <<EOF
package main

import (
    "encoding/json"
    "fmt"
    "time"
    "github.com/hyperledger/fabric-contract-api-go/contractapi"
)

type LogNetworkPerformance struct {
    contractapi.Contract
}

type NetworkPerformanceLog struct {
    NetworkID string `json:"networkID"`
    Metric    string `json:"metric"`
    Value     string `json:"value"`
    Timestamp string `json:"timestamp"`
}

func (s *LogNetworkPerformance) Init(ctx contractapi.TransactionContextInterface) error {
    return nil
}

func (s *LogNetworkPerformance) Log(ctx contractapi.TransactionContextInterface, networkID, metric, value string) error {
    log := NetworkPerformanceLog{
        NetworkID: networkID,
        Metric:    metric,
        Value:     value,
        Timestamp: time.Now().String(),
    }
    logJSON, err := json.Marshal(log)
    if err != nil {
        return err
    }
    return ctx.GetStub().PutState(networkID, logJSON)
}

func (s *LogNetworkPerformance) QueryAsset(ctx contractapi.TransactionContextInterface, networkID string) (*NetworkPerformanceLog, error) {
    assetJSON, err := ctx.GetStub().GetState(networkID)
    if err != nil {
        return nil, err
    }
    if assetJSON == nil {
        return nil, fmt.Errorf("network performance log %s does not exist", networkID)
    }
    var log NetworkPerformanceLog
    err = json.Unmarshal(assetJSON, &log)
    if err != nil {
        return nil, err
    }
    return &log, nil
}

func (s *LogNetworkPerformance) QueryAllAssets(ctx contractapi.TransactionContextInterface) ([]*NetworkPerformanceLog, error) {
    resultsIterator, err := ctx.GetStub().GetStateByRange("", "")
    if err != nil {
        return nil, err
    }
    defer resultsIterator.Close()

    var logs []*NetworkPerformanceLog
    for resultsIterator.HasNext() {
        queryResponse, err := resultsIterator.Next()
        if err != nil {
            return nil, err
        }
        var log NetworkPerformanceLog
        err = json.Unmarshal(queryResponse.Value, &log)
        if err != nil {
            return nil, err
        }
        logs = append(logs, &log)
    }
    return logs, nil
}

func main() {
    chaincode, err := contractapi.NewChaincode(&LogNetworkPerformance{})
    if err != nil {
        fmt.Printf("Error creating LogNetworkPerformance chaincode: %v", err)
    }
    if err := chaincode.Start(); err != nil {
        fmt.Printf("Error starting LogNetworkPerformance chaincode: %v", err)
    }
}
EOF
            ;;
        LogUserActivity)
            cat > chaincode/$contract/chaincode.go <<EOF
package main

import (
    "encoding/json"
    "fmt"
    "time"
    "github.com/hyperledger/fabric-contract-api-go/contractapi"
)

type LogUserActivity struct {
    contractapi.Contract
}

type UserActivityLog struct {
    UserID    string `json:"userID"`
    Activity  string `json:"activity"`
    Timestamp string `json:"timestamp"`
}

func (s *LogUserActivity) Init(ctx contractapi.TransactionContextInterface) error {
    return nil
}

func (s *LogUserActivity) Log(ctx contractapi.TransactionContextInterface, userID, activity string) error {
    log := UserActivityLog{
        UserID:    userID,
        Activity:  activity,
        Timestamp: time.Now().String(),
    }
    logJSON, err := json.Marshal(log)
    if err != nil {
        return err
    }
    return ctx.GetStub().PutState(userID, logJSON)
}

func (s *LogUserActivity) QueryAsset(ctx contractapi.TransactionContextInterface, userID string) (*UserActivityLog, error) {
    assetJSON, err := ctx.GetStub().GetState(userID)
    if err != nil {
        return nil, err
    }
    if assetJSON == nil {
        return nil, fmt.Errorf("user activity log %s does not exist", userID)
    }
    var log UserActivityLog
    err = json.Unmarshal(assetJSON, &log)
    if err != nil {
        return nil, err
    }
    return &log, nil
}

func (s *LogUserActivity) QueryAllAssets(ctx contractapi.TransactionContextInterface) ([]*UserActivityLog, error) {
    resultsIterator, err := ctx.GetStub().GetStateByRange("", "")
    if err != nil {
        return nil, err
    }
    defer resultsIterator.Close()

    var logs []*UserActivityLog
    for resultsIterator.HasNext() {
        queryResponse, err := resultsIterator.Next()
        if err != nil {
            return nil, err
        }
        var log UserActivityLog
        err = json.Unmarshal(queryResponse.Value, &log)
        if err != nil {
            return nil, err
        }
        logs = append(logs, &log)
    }
    return logs, nil
}

func main() {
    chaincode, err := contractapi.NewChaincode(&LogUserActivity{})
    if err != nil {
        fmt.Printf("Error creating LogUserActivity chaincode: %v", err)
    }
    if err := chaincode.Start(); err != nil {
        fmt.Printf("Error starting LogUserActivity chaincode: %v", err)
    }
}
EOF
            ;;
        LogIoTActivity)
            cat > chaincode/$contract/chaincode.go <<EOF
package main

import (
    "encoding/json"
    "fmt"
    "time"
    "github.com/hyperledger/fabric-contract-api-go/contractapi"
)

type LogIoTActivity struct {
    contractapi.Contract
}

type IoTActivityLog struct {
    DeviceID  string `json:"deviceID"`
    Activity  string `json:"activity"`
    Timestamp string `json:"timestamp"`
}

func (s *LogIoTActivity) Init(ctx contractapi.TransactionContextInterface) error {
    return nil
}

func (s *LogIoTActivity) Log(ctx contractapi.TransactionContextInterface, deviceID, activity string) error {
    log := IoTActivityLog{
        DeviceID:  deviceID,
        Activity:  activity,
        Timestamp: time.Now().String(),
    }
    logJSON, err := json.Marshal(log)
    if err != nil {
        return err
    }
    return ctx.GetStub().PutState(deviceID, logJSON)
}

func (s *LogIoTActivity) QueryAsset(ctx contractapi.TransactionContextInterface, deviceID string) (*IoTActivityLog, error) {
    assetJSON, err := ctx.GetStub().GetState(deviceID)
    if err != nil {
        return nil, err
    }
    if assetJSON == nil {
        return nil, fmt.Errorf("IoT activity log %s does not exist", deviceID)
    }
    var log IoTActivityLog
    err = json.Unmarshal(assetJSON, &log)
    if err != nil {
        return nil, err
    }
    return &log, nil
}

func (s *LogIoTActivity) QueryAllAssets(ctx contractapi.TransactionContextInterface) ([]*IoTActivityLog, error) {
    resultsIterator, err := ctx.GetStub().GetStateByRange("", "")
    if err != nil {
        return nil, err
    }
    defer resultsIterator.Close()

    var logs []*IoTActivityLog
    for resultsIterator.HasNext() {
        queryResponse, err := resultsIterator.Next()
        if err != nil {
            return nil, err
        }
        var log IoTActivityLog
        err = json.Unmarshal(queryResponse.Value, &log)
        if err != nil {
            return nil, err
        }
        logs = append(logs, &log)
    }
    return logs, nil
}

func main() {
    chaincode, err := contractapi.NewChaincode(&LogIoTActivity{})
    if err != nil {
        fmt.Printf("Error creating LogIoTActivity chaincode: %v", err)
    }
    if err := chaincode.Start(); err != nil {
        fmt.Printf("Error starting LogIoTActivity chaincode: %v", err)
    }
}
EOF
            ;;
        LogSessionAudit)
            cat > chaincode/$contract/chaincode.go <<EOF
package main

import (
    "encoding/json"
    "fmt"
    "time"
    "github.com/hyperledger/fabric-contract-api-go/contractapi"
)

type LogSessionAudit struct {
    contractapi.Contract
}

type SessionAuditLog struct {
    EntityID  string `json:"entityID"`
    SessionID string `json:"sessionID"`
    Action    string `json:"action"`
    Timestamp string `json:"timestamp"`
}

func (s *LogSessionAudit) Init(ctx contractapi.TransactionContextInterface) error {
    return nil
}

func (s *LogSessionAudit) Log(ctx contractapi.TransactionContextInterface, entityID, sessionID, action string) error {
    log := SessionAuditLog{
        EntityID:  entityID,
        SessionID: sessionID,
        Action:    action,
        Timestamp: time.Now().String(),
    }
    logJSON, err := json.Marshal(log)
    if err != nil {
        return err
    }
    return ctx.GetStub().PutState(entityID, logJSON)
}

func (s *LogSessionAudit) QueryAsset(ctx contractapi.TransactionContextInterface, entityID string) (*SessionAuditLog, error) {
    assetJSON, err := ctx.GetStub().GetState(entityID)
    if err != nil {
        return nil, err
    }
    if assetJSON == nil {
        return nil, fmt.Errorf("session audit log %s does not exist", entityID)
    }
    var log SessionAuditLog
    err = json.Unmarshal(assetJSON, &log)
    if err != nil {
        return nil, err
    }
    return &log, nil
}

func (s *LogSessionAudit) QueryAllAssets(ctx contractapi.TransactionContextInterface) ([]*SessionAuditLog, error) {
    resultsIterator, err := ctx.GetStub().GetStateByRange("", "")
    if err != nil {
        return nil, err
    }
    defer resultsIterator.Close()

    var logs []*SessionAuditLog
    for resultsIterator.HasNext() {
        queryResponse, err := resultsIterator.Next()
        if err != nil {
            return nil, err
        }
        var log SessionAuditLog
        err = json.Unmarshal(queryResponse.Value, &log)
        if err != nil {
            return nil, err
        }
        logs = append(logs, &log)
    }
    return logs, nil
}

func main() {
    chaincode, err := contractapi.NewChaincode(&LogSessionAudit{})
    if err != nil {
        fmt.Printf("Error creating LogSessionAudit chaincode: %v", err)
    }
    if err := chaincode.Start(); err != nil {
        fmt.Printf("Error starting LogSessionAudit chaincode: %v", err)
    }
}
EOF
            ;;
        LogConnectionAudit)
            cat > chaincode/$contract/chaincode.go <<EOF
package main

import (
    "encoding/json"
    "fmt"
    "time"
    "github.com/hyperledger/fabric-contract-api-go/contractapi"
)

type LogConnectionAudit struct {
    contractapi.Contract
}

type ConnectionAuditLog struct {
    EntityID  string `json:"entityID"`
    AntennaID string `json:"antennaID"`
    Action    string `json:"action"`
    Timestamp string `json:"timestamp"`
}

func (s *LogConnectionAudit) Init(ctx contractapi.TransactionContextInterface) error {
    return nil
}

func (s *LogConnectionAudit) Log(ctx contractapi.TransactionContextInterface, entityID, antennaID, action string) error {
    log := ConnectionAuditLog{
        EntityID:  entityID,
        AntennaID: antennaID,
        Action:    action,
        Timestamp: time.Now().String(),
    }
    logJSON, err := json.Marshal(log)
    if err != nil {
        return err
    }
    return ctx.GetStub().PutState(entityID, logJSON)
}

func (s *LogConnectionAudit) QueryAsset(ctx contractapi.TransactionContextInterface, entityID string) (*ConnectionAuditLog, error) {
    assetJSON, err := ctx.GetStub().GetState(entityID)
    if err != nil {
        return nil, err
    }
    if assetJSON == nil {
        return nil, fmt.Errorf("connection audit log %s does not exist", entityID)
    }
    var log ConnectionAuditLog
    err = json.Unmarshal(assetJSON, &log)
    if err != nil {
        return nil, err
    }
    return &log, nil
}

func (s *LogConnectionAudit) QueryAllAssets(ctx contractapi.TransactionContextInterface) ([]*ConnectionAuditLog, error) {
    resultsIterator, err := ctx.GetStub().GetStateByRange("", "")
    if err != nil {
        return nil, err
    }
    defer resultsIterator.Close()

    var logs []*ConnectionAuditLog
    for resultsIterator.HasNext() {
        queryResponse, err := resultsIterator.Next()
        if err != nil {
            return nil, err
        }
        var log ConnectionAuditLog
        err = json.Unmarshal(queryResponse.Value, &log)
        if err != nil {
            return nil, err
        }
        logs = append(logs, &log)
    }
    return logs, nil
}

func main() {
    chaincode, err := contractapi.NewChaincode(&LogConnectionAudit{})
    if err != nil {
        fmt.Printf("Error creating LogConnectionAudit chaincode: %v", err)
    }
    if err := chaincode.Start(); err != nil {
        fmt.Printf("Error starting LogConnectionAudit chaincode: %v", err)
    }
}
EOF
            ;;
    esac
done

echo "Generated chaincode for ${#contracts[@]} contracts in part 7:"
for contract in "${contracts[@]}"; do
    if [ -f "chaincode/$contract/chaincode.go" ]; then
        echo " - $contract: OK"
    else
        echo " - $contract: Failed"
    fi
done
