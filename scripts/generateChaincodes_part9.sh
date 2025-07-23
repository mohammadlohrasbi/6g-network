#!/bin/bash

contracts=(
    "ManageNetwork" "ManageAntenna" "ManageIoTDevice" "ManageUser" "MonitorTraffic" "MonitorInterference" "MonitorResourceUsage" "LogSecurityEvent" "LogAccessControl"
)

for contract in "${contracts[@]}"; do
    mkdir -p chaincode/$contract
    case $contract in
        ManageNetwork)
            cat > chaincode/$contract/chaincode.go <<EOF
package main

import (
    "encoding/json"
    "fmt"
    "time"
    "github.com/hyperledger/fabric-contract-api-go/contractapi"
)

type ManageNetwork struct {
    contractapi.Contract
}

type NetworkRecord struct {
    NetworkID string `json:"networkID"`
    Status    string `json:"status"`
    Timestamp string `json:"timestamp"`
}

func (s *ManageNetwork) Init(ctx contractapi.TransactionContextInterface) error {
    return nil
}

func (s *ManageNetwork) UpdateNetworkStatus(ctx contractapi.TransactionContextInterface, networkID, status string) error {
    record := NetworkRecord{
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

func (s *ManageNetwork) QueryAsset(ctx contractapi.TransactionContextInterface, networkID string) (*NetworkRecord, error) {
    assetJSON, err := ctx.GetStub().GetState(networkID)
    if err != nil {
        return nil, err
    }
    if assetJSON == nil {
        return nil, fmt.Errorf("network record %s does not exist", networkID)
    }
    var record NetworkRecord
    err = json.Unmarshal(assetJSON, &record)
    if err != nil {
        return nil, err
    }
    return &record, nil
}

func (s *ManageNetwork) QueryAllAssets(ctx contractapi.TransactionContextInterface) ([]*NetworkRecord, error) {
    resultsIterator, err := ctx.GetStub().GetStateByRange("", "")
    if err != nil {
        return nil, err
    }
    defer resultsIterator.Close()

    var records []*NetworkRecord
    for resultsIterator.HasNext() {
        queryResponse, err := resultsIterator.Next()
        if err != nil {
            return nil, err
        }
        var record NetworkRecord
        err = json.Unmarshal(queryResponse.Value, &record)
        if err != nil {
            return nil, err
        }
        records = append(records, &record)
    }
    return records, nil
}

func main() {
    chaincode, err := contractapi.NewChaincode(&ManageNetwork{})
    if err != nil {
        fmt.Printf("Error creating ManageNetwork chaincode: %v", err)
    }
    if err := chaincode.Start(); err != nil {
        fmt.Printf("Error starting ManageNetwork chaincode: %v", err)
    }
}
EOF
            ;;
        ManageAntenna)
            cat > chaincode/$contract/chaincode.go <<EOF
package main

import (
    "encoding/json"
    "fmt"
    "time"
    "github.com/hyperledger/fabric-contract-api-go/contractapi"
)

type ManageAntenna struct {
    contractapi.Contract
}

type AntennaRecord struct {
    AntennaID string `json:"antennaID"`
    Status    string `json:"status"`
    Timestamp string `json:"timestamp"`
}

func (s *ManageAntenna) Init(ctx contractapi.TransactionContextInterface) error {
    return nil
}

func (s *ManageAntenna) UpdateAntennaStatus(ctx contractapi.TransactionContextInterface, antennaID, status string) error {
    record := AntennaRecord{
        AntennaID: antennaID,
        Status:    status,
        Timestamp: time.Now().String(),
    }
    recordJSON, err := json.Marshal(record)
    if err != nil {
        return err
    }
    return ctx.GetStub().PutState(antennaID, recordJSON)
}

func (s *ManageAntenna) QueryAsset(ctx contractapi.TransactionContextInterface, antennaID string) (*AntennaRecord, error) {
    assetJSON, err := ctx.GetStub().GetState(antennaID)
    if err != nil {
        return nil, err
    }
    if assetJSON == nil {
        return nil, fmt.Errorf("antenna record %s does not exist", antennaID)
    }
    var record AntennaRecord
    err = json.Unmarshal(assetJSON, &record)
    if err != nil {
        return nil, err
    }
    return &record, nil
}

func (s *ManageAntenna) QueryAllAssets(ctx contractapi.TransactionContextInterface) ([]*AntennaRecord, error) {
    resultsIterator, err := ctx.GetStub().GetStateByRange("", "")
    if err != nil {
        return nil, err
    }
    defer resultsIterator.Close()

    var records []*AntennaRecord
    for resultsIterator.HasNext() {
        queryResponse, err := resultsIterator.Next()
        if err != nil {
            return nil, err
        }
        var record AntennaRecord
        err = json.Unmarshal(queryResponse.Value, &record)
        if err != nil {
            return nil, err
        }
        records = append(records, &record)
    }
    return records, nil
}

func main() {
    chaincode, err := contractapi.NewChaincode(&ManageAntenna{})
    if err != nil {
        fmt.Printf("Error creating ManageAntenna chaincode: %v", err)
    }
    if err := chaincode.Start(); err != nil {
        fmt.Printf("Error starting ManageAntenna chaincode: %v", err)
    }
}
EOF
            ;;
        ManageIoTDevice)
            cat > chaincode/$contract/chaincode.go <<EOF
package main

import (
    "encoding/json"
    "fmt"
    "time"
    "github.com/hyperledger/fabric-contract-api-go/contractapi"
)

type ManageIoTDevice struct {
    contractapi.Contract
}

type IoTDeviceRecord struct {
    DeviceID  string `json:"deviceID"`
    Status    string `json:"status"`
    Timestamp string `json:"timestamp"`
}

func (s *ManageIoTDevice) Init(ctx contractapi.TransactionContextInterface) error {
    return nil
}

func (s *ManageIoTDevice) UpdateDeviceStatus(ctx contractapi.TransactionContextInterface, deviceID, status string) error {
    record := IoTDeviceRecord{
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

func (s *ManageIoTDevice) QueryAsset(ctx contractapi.TransactionContextInterface, deviceID string) (*IoTDeviceRecord, error) {
    assetJSON, err := ctx.GetStub().GetState(deviceID)
    if err != nil {
        return nil, err
    }
    if assetJSON == nil {
        return nil, fmt.Errorf("IoT device record %s does not exist", deviceID)
    }
    var record IoTDeviceRecord
    err = json.Unmarshal(assetJSON, &record)
    if err != nil {
        return nil, err
    }
    return &record, nil
}

func (s *ManageIoTDevice) QueryAllAssets(ctx contractapi.TransactionContextInterface) ([]*IoTDeviceRecord, error) {
    resultsIterator, err := ctx.GetStub().GetStateByRange("", "")
    if err != nil {
        return nil, err
    }
    defer resultsIterator.Close()

    var records []*IoTDeviceRecord
    for resultsIterator.HasNext() {
        queryResponse, err := resultsIterator.Next()
        if err != nil {
            return nil, err
        }
        var record IoTDeviceRecord
        err = json.Unmarshal(queryResponse.Value, &record)
        if err != nil {
            return nil, err
        }
        records = append(records, &record)
    }
    return records, nil
}

func main() {
    chaincode, err := contractapi.NewChaincode(&ManageIoTDevice{})
    if err != nil {
        fmt.Printf("Error creating ManageIoTDevice chaincode: %v", err)
    }
    if err := chaincode.Start(); err != nil {
        fmt.Printf("Error starting ManageIoTDevice chaincode: %v", err)
    }
}
EOF
            ;;
        ManageUser)
            cat > chaincode/$contract/chaincode.go <<EOF
package main

import (
    "encoding/json"
    "fmt"
    "time"
    "github.com/hyperledger/fabric-contract-api-go/contractapi"
)

type ManageUser struct {
    contractapi.Contract
}

type UserRecord struct {
    UserID    string `json:"userID"`
    Status    string `json:"status"`
    Timestamp string `json:"timestamp"`
}

func (s *ManageUser) Init(ctx contractapi.TransactionContextInterface) error {
    return nil
}

func (s *ManageUser) UpdateUserStatus(ctx contractapi.TransactionContextInterface, userID, status string) error {
    record := UserRecord{
        UserID:    userID,
        Status:    status,
        Timestamp: time.Now().String(),
    }
    recordJSON, err := json.Marshal(record)
    if err != nil {
        return err
    }
    return ctx.GetStub().PutState(userID, recordJSON)
}

func (s *ManageUser) QueryAsset(ctx contractapi.TransactionContextInterface, userID string) (*UserRecord, error) {
    assetJSON, err := ctx.GetStub().GetState(userID)
    if err != nil {
        return nil, err
    }
    if assetJSON == nil {
        return nil, fmt.Errorf("user record %s does not exist", userID)
    }
    var record UserRecord
    err = json.Unmarshal(assetJSON, &record)
    if err != nil {
        return nil, err
    }
    return &record, nil
}

func (s *ManageUser) QueryAllAssets(ctx contractapi.TransactionContextInterface) ([]*UserRecord, error) {
    resultsIterator, err := ctx.GetStub().GetStateByRange("", "")
    if err != nil {
        return nil, err
    }
    defer resultsIterator.Close()

    var records []*UserRecord
    for resultsIterator.HasNext() {
        queryResponse, err := resultsIterator.Next()
        if err != nil {
            return nil, err
        }
        var record UserRecord
        err = json.Unmarshal(queryResponse.Value, &record)
        if err != nil {
            return nil, err
        }
        records = append(records, &record)
    }
    return records, nil
}

func main() {
    chaincode, err := contractapi.NewChaincode(&ManageUser{})
    if err != nil {
        fmt.Printf("Error creating ManageUser chaincode: %v", err)
    }
    if err := chaincode.Start(); err != nil {
        fmt.Printf("Error starting ManageUser chaincode: %v", err)
    }
}
EOF
            ;;
        MonitorTraffic)
            cat > chaincode/$contract/chaincode.go <<EOF
package main

import (
    "encoding/json"
    "fmt"
    "time"
    "github.com/hyperledger/fabric-contract-api-go/contractapi"
)

type MonitorTraffic struct {
    contractapi.Contract
}

type TrafficRecord struct {
    NetworkID string `json:"networkID"`
    Traffic   string `json:"traffic"`
    Timestamp string `json:"timestamp"`
}

func (s *MonitorTraffic) Init(ctx contractapi.TransactionContextInterface) error {
    return nil
}

func (s *MonitorTraffic) RecordTraffic(ctx contractapi.TransactionContextInterface, networkID, traffic string) error {
    record := TrafficRecord{
        NetworkID: networkID,
        Traffic:   traffic,
        Timestamp: time.Now().String(),
    }
    recordJSON, err := json.Marshal(record)
    if err != nil {
        return err
    }
    return ctx.GetStub().PutState(networkID, recordJSON)
}

func (s *MonitorTraffic) QueryAsset(ctx contractapi.TransactionContextInterface, networkID string) (*TrafficRecord, error) {
    assetJSON, err := ctx.GetStub().GetState(networkID)
    if err != nil {
        return nil, err
    }
    if assetJSON == nil {
        return nil, fmt.Errorf("traffic record %s does not exist", networkID)
    }
    var record TrafficRecord
    err = json.Unmarshal(assetJSON, &record)
    if err != nil {
        return nil, err
    }
    return &record, nil
}

func (s *MonitorTraffic) QueryAllAssets(ctx contractapi.TransactionContextInterface) ([]*TrafficRecord, error) {
    resultsIterator, err := ctx.GetStub().GetStateByRange("", "")
    if err != nil {
        return nil, err
    }
    defer resultsIterator.Close()

    var records []*TrafficRecord
    for resultsIterator.HasNext() {
        queryResponse, err := resultsIterator.Next()
        if err != nil {
            return nil, err
        }
        var record TrafficRecord
        err = json.Unmarshal(queryResponse.Value, &record)
        if err != nil {
            return nil, err
        }
        records = append(records, &record)
    }
    return records, nil
}

func main() {
    chaincode, err := contractapi.NewChaincode(&MonitorTraffic{})
    if err != nil {
        fmt.Printf("Error creating MonitorTraffic chaincode: %v", err)
    }
    if err := chaincode.Start(); err != nil {
        fmt.Printf("Error starting MonitorTraffic chaincode: %v", err)
    }
}
EOF
            ;;
        MonitorInterference)
            cat > chaincode/$contract/chaincode.go <<EOF
package main

import (
    "encoding/json"
    "fmt"
    "time"
    "github.com/hyperledger/fabric-contract-api-go/contractapi"
)

type MonitorInterference struct {
    contractapi.Contract
}

type InterferenceRecord struct {
    NetworkID string `json:"networkID"`
    InterferenceLevel string `json:"interferenceLevel"`
    Timestamp string `json:"timestamp"`
}

func (s *MonitorInterference) Init(ctx contractapi.TransactionContextInterface) error {
    return nil
}

func (s *MonitorInterference) RecordInterference(ctx contractapi.TransactionContextInterface, networkID, interferenceLevel string) error {
    record := InterferenceRecord{
        NetworkID: networkID,
        InterferenceLevel: interferenceLevel,
        Timestamp: time.Now().String(),
    }
    recordJSON, err := json.Marshal(record)
    if err != nil {
        return err
    }
    return ctx.GetStub().PutState(networkID, recordJSON)
}

func (s *MonitorInterference) QueryAsset(ctx contractapi.TransactionContextInterface, networkID string) (*InterferenceRecord, error) {
    assetJSON, err := ctx.GetStub().GetState(networkID)
    if err != nil {
        return nil, err
    }
    if assetJSON == nil {
        return nil, fmt.Errorf("interference record %s does not exist", networkID)
    }
    var record InterferenceRecord
    err = json.Unmarshal(assetJSON, &record)
    if err != nil {
        return nil, err
    }
    return &record, nil
}

func (s *MonitorInterference) QueryAllAssets(ctx contractapi.TransactionContextInterface) ([]*InterferenceRecord, error) {
    resultsIterator, err := ctx.GetStub().GetStateByRange("", "")
    if err != nil {
        return nil, err
    }
    defer resultsIterator.Close()

    var records []*InterferenceRecord
    for resultsIterator.HasNext() {
        queryResponse, err := resultsIterator.Next()
        if err != nil {
            return nil, err
        }
        var record InterferenceRecord
        err = json.Unmarshal(queryResponse.Value, &record)
        if err != nil {
            return nil, err
        }
        records = append(records, &record)
    }
    return records, nil
}

func main() {
    chaincode, err := contractapi.NewChaincode(&MonitorInterference{})
    if err != nil {
        fmt.Printf("Error creating MonitorInterference chaincode: %v", err)
    }
    if err := chaincode.Start(); err != nil {
        fmt.Printf("Error starting MonitorInterference chaincode: %v", err)
    }
}
EOF
            ;;
        MonitorResourceUsage)
            cat > chaincode/$contract/chaincode.go <<EOF
package main

import (
    "encoding/json"
    "fmt"
    "time"
    "github.com/hyperledger/fabric-contract-api-go/contractapi"
)

type MonitorResourceUsage struct {
    contractapi.Contract
}

type ResourceUsageRecord struct {
    EntityID  string `json:"entityID"`
    Resource  string `json:"resource"`
    Amount    string `json:"amount"`
    Timestamp string `json:"timestamp"`
}

func (s *MonitorResourceUsage) Init(ctx contractapi.TransactionContextInterface) error {
    return nil
}

func (s *MonitorResourceUsage) RecordUsage(ctx contractapi.TransactionContextInterface, entityID, resource, amount string) error {
    record := ResourceUsageRecord{
        EntityID:  entityID,
        Resource:  resource,
        Amount:    amount,
        Timestamp: time.Now().String(),
    }
    recordJSON, err := json.Marshal(record)
    if err != nil {
        return err
    }
    return ctx.GetStub().PutState(entityID, recordJSON)
}

func (s *MonitorResourceUsage) QueryAsset(ctx contractapi.TransactionContextInterface, entityID string) (*ResourceUsageRecord, error) {
    assetJSON, err := ctx.GetStub().GetState(entityID)
    if err != nil {
        return nil, err
    }
    if assetJSON == nil {
        return nil, fmt.Errorf("resource usage record %s does not exist", entityID)
    }
    var record ResourceUsageRecord
    err = json.Unmarshal(assetJSON, &record)
    if err != nil {
        return nil, err
    }
    return &record, nil
}

func (s *MonitorResourceUsage) QueryAllAssets(ctx contractapi.TransactionContextInterface) ([]*ResourceUsageRecord, error) {
    resultsIterator, err := ctx.GetStub().GetStateByRange("", "")
    if err != nil {
        return nil, err
    }
    defer resultsIterator.Close()

    var records []*ResourceUsageRecord
    for resultsIterator.HasNext() {
        queryResponse, err := resultsIterator.Next()
        if err != nil {
            return nil, err
        }
        var record ResourceUsageRecord
        err = json.Unmarshal(queryResponse.Value, &record)
        if err != nil {
            return nil, err
        }
        records = append(records, &record)
    }
    return records, nil
}

func main() {
    chaincode, err := contractapi.NewChaincode(&MonitorResourceUsage{})
    if err != nil {
        fmt.Printf("Error creating MonitorResourceUsage chaincode: %v", err)
    }
    if err := chaincode.Start(); err != nil {
        fmt.Printf("Error starting MonitorResourceUsage chaincode: %v", err)
    }
}
EOF
            ;;
        LogSecurityEvent)
            cat > chaincode/$contract/chaincode.go <<EOF
package main

import (
    "encoding/json"
    "fmt"
    "time"
    "github.com/hyperledger/fabric-contract-api-go/contractapi"
)

type LogSecurityEvent struct {
    contractapi.Contract
}

type SecurityEventLog struct {
    EntityID  string `json:"entityID"`
    Event     string `json:"event"`
    Timestamp string `json:"timestamp"`
}

func (s *LogSecurityEvent) Init(ctx contractapi.TransactionContextInterface) error {
    return nil
}

func (s *LogSecurityEvent) Log(ctx contractapi.TransactionContextInterface, entityID, event string) error {
    log := SecurityEventLog{
        EntityID:  entityID,
        Event:     event,
        Timestamp: time.Now().String(),
    }
    logJSON, err := json.Marshal(log)
    if err != nil {
        return err
    }
    return ctx.GetStub().PutState(entityID, logJSON)
}

func (s *LogSecurityEvent) QueryAsset(ctx contractapi.TransactionContextInterface, entityID string) (*SecurityEventLog, error) {
    assetJSON, err := ctx.GetStub().GetState(entityID)
    if err != nil {
        return nil, err
    }
    if assetJSON == nil {
        return nil, fmt.Errorf("security event log %s does not exist", entityID)
    }
    var log SecurityEventLog
    err = json.Unmarshal(assetJSON, &log)
    if err != nil {
        return nil, err
    }
    return &log, nil
}

func (s *LogSecurityEvent) QueryAllAssets(ctx contractapi.TransactionContextInterface) ([]*SecurityEventLog, error) {
    resultsIterator, err := ctx.GetStub().GetStateByRange("", "")
    if err != nil {
        return nil, err
    }
    defer resultsIterator.Close()

    var logs []*SecurityEventLog
    for resultsIterator.HasNext() {
        queryResponse, err := resultsIterator.Next()
        if err != nil {
            return nil, err
        }
        var log SecurityEventLog
        err = json.Unmarshal(queryResponse.Value, &log)
        if err != nil {
            return nil, err
        }
        logs = append(logs, &log)
    }
    return logs, nil
}

func main() {
    chaincode, err := contractapi.NewChaincode(&LogSecurityEvent{})
    if err != nil {
        fmt.Printf("Error creating LogSecurityEvent chaincode: %v", err)
    }
    if err := chaincode.Start(); err != nil {
        fmt.Printf("Error starting LogSecurityEvent chaincode: %v", err)
    }
}
EOF
            ;;
        LogAccessControl)
            cat > chaincode/$contract/chaincode.go <<EOF
package main

import (
    "encoding/json"
    "fmt"
    "time"
    "github.com/hyperledger/fabric-contract-api-go/contractapi"
)

type LogAccessControl struct {
    contractapi.Contract
}

type AccessControlLog struct {
    EntityID  string `json:"entityID"`
    Action    string `json:"action"`
    Timestamp string `json:"timestamp"`
}

func (s *LogAccessControl) Init(ctx contractapi.TransactionContextInterface) error {
    return nil
}

func (s *LogAccessControl) Log(ctx contractapi.TransactionContextInterface, entityID, action string) error {
    log := AccessControlLog{
        EntityID:  entityID,
        Action:    action,
        Timestamp: time.Now().String(),
    }
    logJSON, err := json.Marshal(log)
    if err != nil {
        return err
    }
    return ctx.GetStub().PutState(entityID, logJSON)
}

func (s *LogAccessControl) QueryAsset(ctx contractapi.TransactionContextInterface, entityID string) (*AccessControlLog, error) {
    assetJSON, err := ctx.GetStub().GetState(entityID)
    if err != nil {
        return nil, err
    }
    if assetJSON == nil {
        return nil, fmt.Errorf("access control log %s does not exist", entityID)
    }
    var log AccessControlLog
    err = json.Unmarshal(assetJSON, &log)
    if err != nil {
        return nil, err
    }
    return &log, nil
}

func (s *LogAccessControl) QueryAllAssets(ctx contractapi.TransactionContextInterface) ([]*AccessControlLog, error) {
    resultsIterator, err := ctx.GetStub().GetStateByRange("", "")
    if err != nil {
        return nil, err
    }
    defer resultsIterator.Close()

    var logs []*AccessControlLog
    for resultsIterator.HasNext() {
        queryResponse, err := resultsIterator.Next()
        if err != nil {
            return nil, err
        }
        var log AccessControlLog
        err = json.Unmarshal(queryResponse.Value, &log)
        if err != nil {
            return nil, err
        }
        logs = append(logs, &log)
    }
    return logs, nil
}

func main() {
    chaincode, err := contractapi.NewChaincode(&LogAccessControl{})
    if err != nil {
        fmt.Printf("Error creating LogAccessControl chaincode: %v", err)
    }
    if err := chaincode.Start(); err != nil {
        fmt.Printf("Error starting LogAccessControl chaincode: %v", err)
    }
}
EOF
            ;;
    esac
done

echo "Generated chaincode for ${#contracts[@]} contracts in part 9:"
for contract in "${contracts[@]}"; do
    if [ -f "chaincode/$contract/chaincode.go" ]; then
        echo " - $contract: OK"
    else
        echo " - $contract: Failed"
    fi
done
