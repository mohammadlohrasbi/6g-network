#!/bin/bash

contracts=(
    "LocationBasedCongestion" "LocationBasedDynamicRouting" "LocationBasedAntennaConfig" "LocationBasedSignalQuality"
    "LocationBasedNetworkHealth" "LocationBasedPowerManagement" "LocationBasedChannelAllocation" "LocationBasedSessionManagement"
    "LocationBasedIoTConnection"
)

for contract in "${contracts[@]}"; do
    mkdir -p chaincode/$contract
    case $contract in
        LocationBasedCongestion)
            cat > chaincode/$contract/chaincode.go <<EOF
package main

import (
    "encoding/json"
    "fmt"
    "math"
    "strconv"
    "time"
    "github.com/hyperledger/fabric-contract-api-go/contractapi"
)

type LocationBasedCongestion struct {
    contractapi.Contract
}

type CongestionRecord struct {
    EntityID   string `json:"entityID"`
    Congestion string `json:"congestion"`
    X          string `json:"x"`
    Y          string `json:"y"`
    Distance   string `json:"distance"`
    Timestamp  string `json:"timestamp"`
}

func (s *LocationBasedCongestion) Init(ctx contractapi.TransactionContextInterface) error {
    return nil
}

func (s *LocationBasedCongestion) RecordCongestion(ctx contractapi.TransactionContextInterface, entityID, congestion, x, y string) error {
    distance, err := calculateDistance(x, y, "0", "0")
    if err != nil {
        return err
    }
    record := CongestionRecord{
        EntityID:   entityID,
        Congestion: congestion,
        X:          x,
        Y:          y,
        Distance:   distance,
        Timestamp:  time.Now().String(),
    }
    recordJSON, err := json.Marshal(record)
    if err != nil {
        return err
    }
    return ctx.GetStub().PutState(entityID, recordJSON)
}

func (s *LocationBasedCongestion) QueryAsset(ctx contractapi.TransactionContextInterface, entityID string) (*CongestionRecord, error) {
    assetJSON, err := ctx.GetStub().GetState(entityID)
    if err != nil {
        return nil, err
    }
    if assetJSON == nil {
        return nil, fmt.Errorf("congestion record %s does not exist", entityID)
    }
    var record CongestionRecord
    err = json.Unmarshal(assetJSON, &record)
    if err != nil {
        return nil, err
    }
    return &record, nil
}

func (s *LocationBasedCongestion) QueryAllAssets(ctx contractapi.TransactionContextInterface) ([]*CongestionRecord, error) {
    resultsIterator, err := ctx.GetStub().GetStateByRange("", "")
    if err != nil {
        return nil, err
    }
    defer resultsIterator.Close()

    var records []*CongestionRecord
    for resultsIterator.HasNext() {
        queryResponse, err := resultsIterator.Next()
        if err != nil {
            return nil, err
        }
        var record CongestionRecord
        err = json.Unmarshal(queryResponse.Value, &record)
        if err != nil {
            return nil, err
        }
        records = append(records, &record)
    }
    return records, nil
}

func (s *LocationBasedCongestion) ValidateCongestionDistance(ctx contractapi.TransactionContextInterface, entityID, maxDistance string) (bool, error) {
    record, err := s.QueryAsset(ctx, entityID)
    if err != nil {
        return false, err
    }
    distance, err := strconv.ParseFloat(record.Distance, 64)
    if err != nil {
        return false, err
    }
    max, err := strconv.ParseFloat(maxDistance, 64)
    if err != nil {
        return false, err
    }
    return distance <= max, nil
}

func calculateDistance(x1, y1, x2, y2 string) (string, error) {
    x1Float, err := strconv.ParseFloat(x1, 64)
    if err != nil {
        return "", err
    }
    y1Float, err := strconv.ParseFloat(y1, 64)
    if err != nil {
        return "", err
    }
    x2Float, err := strconv.ParseFloat(x2, 64)
    if err != nil {
        return "", err
    }
    y2Float, err := strconv.ParseFloat(y2, 64)
    if err != nil {
        return "", err
    }
    distance := math.Sqrt(math.Pow(x2Float-x1Float, 2) + math.Pow(y2Float-y1Float, 2))
    return fmt.Sprintf("%.4f", distance), nil
}

func main() {
    chaincode, err := contractapi.NewChaincode(&LocationBasedCongestion{})
    if err != nil {
        fmt.Printf("Error creating LocationBasedCongestion chaincode: %v", err)
    }
    if err := chaincode.Start(); err != nil {
        fmt.Printf("Error starting LocationBasedCongestion chaincode: %v", err)
    }
}
EOF
            ;;
        LocationBasedDynamicRouting)
            cat > chaincode/$contract/chaincode.go <<EOF
package main

import (
    "encoding/json"
    "fmt"
    "math"
    "strconv"
    "time"
    "github.com/hyperledger/fabric-contract-api-go/contractapi"
)

type LocationBasedDynamicRouting struct {
    contractapi.Contract
}

type RoutingRecord struct {
    EntityID   string `json:"entityID"`
    Route      string `json:"route"`
    X          string `json:"x"`
    Y          string `json:"y"`
    Distance   string `json:"distance"`
    Timestamp  string `json:"timestamp"`
}

func (s *LocationBasedDynamicRouting) Init(ctx contractapi.TransactionContextInterface) error {
    return nil
}

func (s *LocationBasedDynamicRouting) SetRoute(ctx contractapi.TransactionContextInterface, entityID, route, x, y string) error {
    distance, err := calculateDistance(x, y, "0", "0")
    if err != nil {
        return err
    }
    record := RoutingRecord{
        EntityID:  entityID,
        Route:     route,
        X:         x,
        Y:         y,
        Distance:  distance,
        Timestamp: time.Now().String(),
    }
    recordJSON, err := json.Marshal(record)
    if err != nil {
        return err
    }
    return ctx.GetStub().PutState(entityID, recordJSON)
}

func (s *LocationBasedDynamicRouting) QueryAsset(ctx contractapi.TransactionContextInterface, entityID string) (*RoutingRecord, error) {
    assetJSON, err := ctx.GetStub().GetState(entityID)
    if err != nil {
        return nil, err
    }
    if assetJSON == nil {
        return nil, fmt.Errorf("routing record %s does not exist", entityID)
    }
    var record RoutingRecord
    err = json.Unmarshal(assetJSON, &record)
    if err != nil {
        return nil, err
    }
    return &record, nil
}

func (s *LocationBasedDynamicRouting) QueryAllAssets(ctx contractapi.TransactionContextInterface) ([]*RoutingRecord, error) {
    resultsIterator, err := ctx.GetStub().GetStateByRange("", "")
    if err != nil {
        return nil, err
    }
    defer resultsIterator.Close()

    var records []*RoutingRecord
    for resultsIterator.HasNext() {
        queryResponse, err := resultsIterator.Next()
        if err != nil {
            return nil, err
        }
        var record RoutingRecord
        err = json.Unmarshal(queryResponse.Value, &record)
        if err != nil {
            return nil, err
        }
        records = append(records, &record)
    }
    return records, nil
}

func (s *LocationBasedDynamicRouting) ValidateRouteDistance(ctx contractapi.TransactionContextInterface, entityID, maxDistance string) (bool, error) {
    record, err := s.QueryAsset(ctx, entityID)
    if err != nil {
        return false, err
    }
    distance, err := strconv.ParseFloat(record.Distance, 64)
    if err != nil {
        return false, err
    }
    max, err := strconv.ParseFloat(maxDistance, 64)
    if err != nil {
        return false, err
    }
    return distance <= max, nil
}

func calculateDistance(x1, y1, x2, y2 string) (string, error) {
    x1Float, err := strconv.ParseFloat(x1, 64)
    if err != nil {
        return "", err
    }
    y1Float, err := strconv.ParseFloat(y1, 64)
    if err != nil {
        return "", err
    }
    x2Float, err := strconv.ParseFloat(x2, 64)
    if err != nil {
        return "", err
    }
    y2Float, err := strconv.ParseFloat(y2, 64)
    if err != nil {
        return "", err
    }
    distance := math.Sqrt(math.Pow(x2Float-x1Float, 2) + math.Pow(y2Float-y1Float, 2))
    return fmt.Sprintf("%.4f", distance), nil
}

func main() {
    chaincode, err := contractapi.NewChaincode(&LocationBasedDynamicRouting{})
    if err != nil {
        fmt.Printf("Error creating LocationBasedDynamicRouting chaincode: %v", err)
    }
    if err := chaincode.Start(); err != nil {
        fmt.Printf("Error starting LocationBasedDynamicRouting chaincode: %v", err)
    }
}
EOF
            ;;
        LocationBasedAntennaConfig)
            cat > chaincode/$contract/chaincode.go <<EOF
package main

import (
    "encoding/json"
    "fmt"
    "math"
    "strconv"
    "time"
    "github.com/hyperledger/fabric-contract-api-go/contractapi"
)

type LocationBasedAntennaConfig struct {
    contractapi.Contract
}

type AntennaConfig struct {
    AntennaID  string `json:"antennaID"`
    Config     string `json:"config"`
    X          string `json:"x"`
    Y          string `json:"y"`
    Distance   string `json:"distance"`
    Timestamp  string `json:"timestamp"`
}

func (s *LocationBasedAntennaConfig) Init(ctx contractapi.TransactionContextInterface) error {
    return nil
}

func (s *LocationBasedAntennaConfig) SetAntennaConfig(ctx contractapi.TransactionContextInterface, antennaID, config, x, y string) error {
    distance, err := calculateDistance(x, y, "0", "0")
    if err != nil {
        return err
    }
    record := AntennaConfig{
        AntennaID: antennaID,
        Config:    config,
        X:         x,
        Y:         y,
        Distance:  distance,
        Timestamp: time.Now().String(),
    }
    recordJSON, err := json.Marshal(record)
    if err != nil {
        return err
    }
    return ctx.GetStub().PutState(antennaID, recordJSON)
}

func (s *LocationBasedAntennaConfig) QueryAsset(ctx contractapi.TransactionContextInterface, antennaID string) (*AntennaConfig, error) {
    assetJSON, err := ctx.GetStub().GetState(antennaID)
    if err != nil {
        return nil, err
    }
    if assetJSON == nil {
        return nil, fmt.Errorf("antenna config %s does not exist", antennaID)
    }
    var record AntennaConfig
    err = json.Unmarshal(assetJSON, &record)
    if err != nil {
        return nil, err
    }
    return &record, nil
}

func (s *LocationBasedAntennaConfig) QueryAllAssets(ctx contractapi.TransactionContextInterface) ([]*AntennaConfig, error) {
    resultsIterator, err := ctx.GetStub().GetStateByRange("", "")
    if err != nil {
        return nil, err
    }
    defer resultsIterator.Close()

    var records []*AntennaConfig
    for resultsIterator.HasNext() {
        queryResponse, err := resultsIterator.Next()
        if err != nil {
            return nil, err
        }
        var record AntennaConfig
        err = json.Unmarshal(queryResponse.Value, &record)
        if err != nil {
            return nil, err
        }
        records = append(records, &record)
    }
    return records, nil
}

func (s *LocationBasedAntennaConfig) ValidateConfigDistance(ctx contractapi.TransactionContextInterface, antennaID, maxDistance string) (bool, error) {
    record, err := s.QueryAsset(ctx, antennaID)
    if err != nil {
        return false, err
    }
    distance, err := strconv.ParseFloat(record.Distance, 64)
    if err != nil {
        return false, err
    }
    max, err := strconv.ParseFloat(maxDistance, 64)
    if err != nil {
        return false, err
    }
    return distance <= max, nil
}

func calculateDistance(x1, y1, x2, y2 string) (string, error) {
    x1Float, err := strconv.ParseFloat(x1, 64)
    if err != nil {
        return "", err
    }
    y1Float, err := strconv.ParseFloat(y1, 64)
    if err != nil {
        return "", err
    }
    x2Float, err := strconv.ParseFloat(x2, 64)
    if err != nil {
        return "", err
    }
    y2Float, err := strconv.ParseFloat(y2, 64)
    if err != nil {
        return "", err
    }
    distance := math.Sqrt(math.Pow(x2Float-x1Float, 2) + math.Pow(y2Float-y1Float, 2))
    return fmt.Sprintf("%.4f", distance), nil
}

func main() {
    chaincode, err := contractapi.NewChaincode(&LocationBasedAntennaConfig{})
    if err != nil {
        fmt.Printf("Error creating LocationBasedAntennaConfig chaincode: %v", err)
    }
    if err := chaincode.Start(); err != nil {
        fmt.Printf("Error starting LocationBasedAntennaConfig chaincode: %v", err)
    }
}
EOF
            ;;
        LocationBasedSignalQuality)
            cat > chaincode/$contract/chaincode.go <<EOF
package main

import (
    "encoding/json"
    "fmt"
    "math"
    "strconv"
    "time"
    "github.com/hyperledger/fabric-contract-api-go/contractapi"
)

type LocationBasedSignalQuality struct {
    contractapi.Contract
}

type SignalQualityRecord struct {
    EntityID   string `json:"entityID"`
    SignalQuality string `json:"signalQuality"`
    X          string `json:"x"`
    Y          string `json:"y"`
    Distance   string `json:"distance"`
    Timestamp  string `json:"timestamp"`
}

func (s *LocationBasedSignalQuality) Init(ctx contractapi.TransactionContextInterface) error {
    return nil
}

func (s *LocationBasedSignalQuality) RecordSignalQuality(ctx contractapi.TransactionContextInterface, entityID, signalQuality, x, y string) error {
    distance, err := calculateDistance(x, y, "0", "0")
    if err != nil {
        return err
    }
    record := SignalQualityRecord{
        EntityID:      entityID,
        SignalQuality: signalQuality,
        X:             x,
        Y:             y,
        Distance:      distance,
        Timestamp:     time.Now().String(),
    }
    recordJSON, err := json.Marshal(record)
    if err != nil {
        return err
    }
    return ctx.GetStub().PutState(entityID, recordJSON)
}

func (s *LocationBasedSignalQuality) QueryAsset(ctx contractapi.TransactionContextInterface, entityID string) (*SignalQualityRecord, error) {
    assetJSON, err := ctx.GetStub().GetState(entityID)
    if err != nil {
        return nil, err
    }
    if assetJSON == nil {
        return nil, fmt.Errorf("signal quality record %s does not exist", entityID)
    }
    var record SignalQualityRecord
    err = json.Unmarshal(assetJSON, &record)
    if err != nil {
        return nil, err
    }
    return &record, nil
}

func (s *LocationBasedSignalQuality) QueryAllAssets(ctx contractapi.TransactionContextInterface) ([]*SignalQualityRecord, error) {
    resultsIterator, err := ctx.GetStub().GetStateByRange("", "")
    if err != nil {
        return nil, err
    }
    defer resultsIterator.Close()

    var records []*SignalQualityRecord
    for resultsIterator.HasNext() {
        queryResponse, err := resultsIterator.Next()
        if err != nil {
            return nil, err
        }
        var record SignalQualityRecord
        err = json.Unmarshal(queryResponse.Value, &record)
        if err != nil {
            return nil, err
        }
        records = append(records, &record)
    }
    return records, nil
}

func (s *LocationBasedSignalQuality) ValidateSignalQualityDistance(ctx contractapi.TransactionContextInterface, entityID, maxDistance string) (bool, error) {
    record, err := s.QueryAsset(ctx, entityID)
    if err != nil {
        return false, err
    }
    distance, err := strconv.ParseFloat(record.Distance, 64)
    if err != nil {
        return false, err
    }
    max, err := strconv.ParseFloat(maxDistance, 64)
    if err != nil {
        return false, err
    }
    return distance <= max, nil
}

func calculateDistance(x1, y1, x2, y2 string) (string, error) {
    x1Float, err := strconv.ParseFloat(x1, 64)
    if err != nil {
        return "", err
    }
    y1Float, err := strconv.ParseFloat(y1, 64)
    if err != nil {
        return "", err
    }
    x2Float, err := strconv.ParseFloat(x2, 64)
    if err != nil {
        return "", err
    }
    y2Float, err := strconv.ParseFloat(y2, 64)
    if err != nil {
        return "", err
    }
    distance := math.Sqrt(math.Pow(x2Float-x1Float, 2) + math.Pow(y2Float-y1Float, 2))
    return fmt.Sprintf("%.4f", distance), nil
}

func main() {
    chaincode, err := contractapi.NewChaincode(&LocationBasedSignalQuality{})
    if err != nil {
        fmt.Printf("Error creating LocationBasedSignalQuality chaincode: %v", err)
    }
    if err := chaincode.Start(); err != nil {
        fmt.Printf("Error starting LocationBasedSignalQuality chaincode: %v", err)
    }
}
EOF
            ;;
        LocationBasedNetworkHealth)
            cat > chaincode/$contract/chaincode.go <<EOF
package main

import (
    "encoding/json"
    "fmt"
    "math"
    "strconv"
    "time"
    "github.com/hyperledger/fabric-contract-api-go/contractapi"
)

type LocationBasedNetworkHealth struct {
    contractapi.Contract
}

type NetworkHealthRecord struct {
    EntityID   string `json:"entityID"`
    HealthStatus string `json:"healthStatus"`
    X          string `json:"x"`
    Y          string `json:"y"`
    Distance   string `json:"distance"`
    Timestamp  string `json:"timestamp"`
}

func (s *LocationBasedNetworkHealth) Init(ctx contractapi.TransactionContextInterface) error {
    return nil
}

func (s *LocationBasedNetworkHealth) RecordNetworkHealth(ctx contractapi.TransactionContextInterface, entityID, healthStatus, x, y string) error {
    distance, err := calculateDistance(x, y, "0", "0")
    if err != nil {
        return err
    }
    record := NetworkHealthRecord{
        EntityID:     entityID,
        HealthStatus: healthStatus,
        X:            x,
        Y:            y,
        Distance:     distance,
        Timestamp:    time.Now().String(),
    }
    recordJSON, err := json.Marshal(record)
    if err != nil {
        return err
    }
    return ctx.GetStub().PutState(entityID, recordJSON)
}

func (s *LocationBasedNetworkHealth) QueryAsset(ctx contractapi.TransactionContextInterface, entityID string) (*NetworkHealthRecord, error) {
    assetJSON, err := ctx.GetStub().GetState(entityID)
    if err != nil {
        return nil, err
    }
    if assetJSON == nil {
        return nil, fmt.Errorf("network health record %s does not exist", entityID)
    }
    var record NetworkHealthRecord
    err = json.Unmarshal(assetJSON, &record)
    if err != nil {
        return nil, err
    }
    return &record, nil
}

func (s *LocationBasedNetworkHealth) QueryAllAssets(ctx contractapi.TransactionContextInterface) ([]*NetworkHealthRecord, error) {
    resultsIterator, err := ctx.GetStub().GetStateByRange("", "")
    if err != nil {
        return nil, err
    }
    defer resultsIterator.Close()

    var records []*NetworkHealthRecord
    for resultsIterator.HasNext() {
        queryResponse, err := resultsIterator.Next()
        if err != nil {
            return nil, err
        }
        var record NetworkHealthRecord
        err = json.Unmarshal(queryResponse.Value, &record)
        if err != nil {
            return nil, err
        }
        records = append(records, &record)
    }
    return records, nil
}

func (s *LocationBasedNetworkHealth) ValidateHealthDistance(ctx contractapi.TransactionContextInterface, entityID, maxDistance string) (bool, error) {
    record, err := s.QueryAsset(ctx, entityID)
    if err != nil {
        return false, err
    }
    distance, err := strconv.ParseFloat(record.Distance, 64)
    if err != nil {
        return false, err
    }
    max, err := strconv.ParseFloat(maxDistance, 64)
    if err != nil {
        return false, err
    }
    return distance <= max, nil
}

func calculateDistance(x1, y1, x2, y2 string) (string, error) {
    x1Float, err := strconv.ParseFloat(x1, 64)
    if err != nil {
        return "", err
    }
    y1Float, err := strconv.ParseFloat(y1, 64)
    if err != nil {
        return "", err
    }
    x2Float, err := strconv.ParseFloat(x2, 64)
    if err != nil {
        return "", err
    }
    y2Float, err := strconv.ParseFloat(y2, 64)
    if err != nil {
        return "", err
    }
    distance := math.Sqrt(math.Pow(x2Float-x1Float, 2) + math.Pow(y2Float-y1Float, 2))
    return fmt.Sprintf("%.4f", distance), nil
}

func main() {
    chaincode, err := contractapi.NewChaincode(&LocationBasedNetworkHealth{})
    if err != nil {
        fmt.Printf("Error creating LocationBasedNetworkHealth chaincode: %v", err)
    }
    if err := chaincode.Start(); err != nil {
        fmt.Printf("Error starting LocationBasedNetworkHealth chaincode: %v", err)
    }
}
EOF
            ;;
        LocationBasedPowerManagement)
            cat > chaincode/$contract/chaincode.go <<EOF
package main

import (
    "encoding/json"
    "fmt"
    "math"
    "strconv"
    "time"
    "github.com/hyperledger/fabric-contract-api-go/contractapi"
)

type LocationBasedPowerManagement struct {
    contractapi.Contract
}

type PowerRecord struct {
    EntityID   string `json:"entityID"`
    PowerLevel string `json:"powerLevel"`
    X          string `json:"x"`
    Y          string `json:"y"`
    Distance   string `json:"distance"`
    Timestamp  string `json:"timestamp"`
}

func (s *LocationBasedPowerManagement) Init(ctx contractapi.TransactionContextInterface) error {
    return nil
}

func (s *LocationBasedPowerManagement) SetPowerLevel(ctx contractapi.TransactionContextInterface, entityID, powerLevel, x, y string) error {
    distance, err := calculateDistance(x, y, "0", "0")
    if err != nil {
        return err
    }
    record := PowerRecord{
        EntityID:   entityID,
        PowerLevel: powerLevel,
        X:          x,
        Y:          y,
        Distance:   distance,
        Timestamp:  time.Now().String(),
    }
    recordJSON, err := json.Marshal(record)
    if err != nil {
        return err
    }
    return ctx.GetStub().PutState(entityID, recordJSON)
}

func (s *LocationBasedPowerManagement) QueryAsset(ctx contractapi.TransactionContextInterface, entityID string) (*PowerRecord, error) {
    assetJSON, err := ctx.GetStub().GetState(entityID)
    if err != nil {
        return nil, err
    }
    if assetJSON == nil {
        return nil, fmt.Errorf("power record %s does not exist", entityID)
    }
    var record PowerRecord
    err = json.Unmarshal(assetJSON, &record)
    if err != nil {
        return nil, err
    }
    return &record, nil
}

func (s *LocationBasedPowerManagement) QueryAllAssets(ctx contractapi.TransactionContextInterface) ([]*PowerRecord, error) {
    resultsIterator, err := ctx.GetStub().GetStateByRange("", "")
    if err != nil {
        return nil, err
    }
    defer resultsIterator.Close()

    var records []*PowerRecord
    for resultsIterator.HasNext() {
        queryResponse, err := resultsIterator.Next()
        if err != nil {
            return nil, err
        }
        var record PowerRecord
        err = json.Unmarshal(queryResponse.Value, &record)
        if err != nil {
            return nil, err
        }
        records = append(records, &record)
    }
    return records, nil
}

func (s *LocationBasedPowerManagement) ValidatePowerDistance(ctx contractapi.TransactionContextInterface, entityID, maxDistance string) (bool, error) {
    record, err := s.QueryAsset(ctx, entityID)
    if err != nil {
        return false, err
    }
    distance, err := strconv.ParseFloat(record.Distance, 64)
    if err != nil {
        return false, err
    }
    max, err := strconv.ParseFloat(maxDistance, 64)
    if err != nil {
        return false, err
    }
    return distance <= max, nil
}

func calculateDistance(x1, y1, x2, y2 string) (string, error) {
    x1Float, err := strconv.ParseFloat(x1, 64)
    if err != nil {
        return "", err
    }
    y1Float, err := strconv.ParseFloat(y1, 64)
    if err != nil {
        return "", err
    }
    x2Float, err := strconv.ParseFloat(x2, 64)
    if err != nil {
        return "", err
    }
    y2Float, err := strconv.ParseFloat(y2, 64)
    if
