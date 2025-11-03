#!/bin/bash

# Fixed and Complete generateChaincodes_part2.sh
# This script generates full Go chaincode for 7 contracts in part 2.
# No dependency on external JSON files - hardcoded contracts and Go code.
# Fix: Used <<'EOF' to prevent bash substitution of backticks in Go JSON tags.
# The Go code is complete with Init, Record/Perform/Allocate functions, Query, ValidateDistance, calculateDistance.

set -e  # Stop on first error

contracts=(
    "LocationBasedEnergy" "LocationBasedRoaming" "LocationBasedSignalStrength" "LocationBasedCoverage"
    "LocationBasedInterference" "LocationBasedResourceAllocation" "LocationBasedNetworkLoad"
)

for contract in "${contracts[@]}"; do
    mkdir -p chaincode/$contract
    case $contract in
        LocationBasedEnergy)
            cat > chaincode/$contract/chaincode.go <<'EOF'
package main

import (
    "encoding/json"
    "fmt"
    "math"
    "strconv"
    "time"

    "github.com/hyperledger/fabric-contract-api-go/contractapi"
)

type LocationBasedEnergy struct {
    contractapi.Contract
}

type EnergyRecord struct {
    EntityID  string `json:"entityID"`
    Energy    string `json:"energy"`
    X         string `json:"x"`
    Y         string `json:"y"`
    Distance  string `json:"distance"`
    Timestamp string `json:"timestamp"`
}

func (s *LocationBasedEnergy) Init(ctx contractapi.TransactionContextInterface) error {
    return nil
}

func (s *LocationBasedEnergy) RecordEnergy(ctx contractapi.TransactionContextInterface, entityID, energy, x, y string) error {
    distance, err := calculateDistance(x, y, "0", "0")
    if err != nil {
        return err
    }
    record := EnergyRecord{
        EntityID:  entityID,
        Energy:    energy,
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

func (s *LocationBasedEnergy) QueryAsset(ctx contractapi.TransactionContextInterface, entityID string) (*EnergyRecord, error) {
    assetJSON, err := ctx.GetStub().GetState(entityID)
    if err != nil {
        return nil, fmt.Errorf("failed to read from world state: %v", err)
    }
    if assetJSON == nil {
        return nil, fmt.Errorf("energy record %s does not exist", entityID)
    }
    var record EnergyRecord
    err = json.Unmarshal(assetJSON, &record)
    if err != nil {
        return nil, err
    }
    return &record, nil
}

func (s *LocationBasedEnergy) QueryAllAssets(ctx contractapi.TransactionContextInterface) ([]*EnergyRecord, error) {
    resultsIterator, err := ctx.GetStub().GetStateByRange("", "")
    if err != nil {
        return nil, err
    }
    defer resultsIterator.Close()
    var records []*EnergyRecord
    for resultsIterator.HasNext() {
        queryResponse, err := resultsIterator.Next()
        if err != nil {
            return nil, err
        }
        var record EnergyRecord
        err = json.Unmarshal(queryResponse.Value, &record)
        if err != nil {
            return nil, err
        }
        records = append(records, &record)
    }
    return records, nil
}

func (s *LocationBasedEnergy) ValidateEnergyDistance(ctx contractapi.TransactionContextInterface, entityID, maxDistance string) (bool, error) {
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
    chaincode, err := contractapi.NewChaincode(&LocationBasedEnergy{})
    if err != nil {
        fmt.Printf("Error creating LocationBasedEnergy chaincode: %v", err)
    }
    if err := chaincode.Start(); err != nil {
        fmt.Printf("Error starting LocationBasedEnergy chaincode: %v", err)
    }
}
EOF
            ;;
        LocationBasedRoaming)
            cat > "$CHAINCODE_DIR/$contract/chaincode.go" <<'EOF'
package main

import (
    "encoding/json"
    "fmt"
    "math"
    "strconv"
    "time"

    "github.com/hyperledger/fabric-contract-api-go/contractapi"
)

type LocationBasedRoaming struct {
    contractapi.Contract
}

type RoamingRecord struct {
    EntityID  string `json:"entityID"`
    AntennaID string `json:"antennaID"`
    X         string `json:"x"`
    Y         string `json:"y"`
    Distance  string `json:"distance"`
    Timestamp string `json:"timestamp"`
}

func (s *LocationBasedRoaming) Init(ctx contractapi.TransactionContextInterface) error {
    return nil
}

func (s *LocationBasedRoaming) PerformRoaming(ctx contractapi.TransactionContextInterface, entityID, antennaID, x, y string) error {
    antenna, err := s.QueryAsset(ctx, antennaID)
    if err != nil {
        return fmt.Errorf("failed to query antenna: %v", err)
    }
    distance, err := calculateDistance(x, y, antenna.X, antenna.Y)
    if err != nil {
        return err
    }
    record := RoamingRecord{
        EntityID:  entityID,
        AntennaID: antennaID,
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

func (s *LocationBasedRoaming) QueryAsset(ctx contractapi.TransactionContextInterface, entityID string) (*RoamingRecord, error) {
    assetJSON, err := ctx.GetStub().GetState(entityID)
    if err != nil {
        return nil, fmt.Errorf("failed to read from world state: %v", err)
    }
    if assetJSON == nil {
        return nil, fmt.Errorf("roaming record %s does not exist", entityID)
    }
    var record RoamingRecord
    err = json.Unmarshal(assetJSON, &record)
    if err != nil {
        return nil, err
    }
    return &record, nil
}

func (s *LocationBasedRoaming) QueryAllAssets(ctx contractapi.TransactionContextInterface) ([]*RoamingRecord, error) {
    resultsIterator, err := ctx.GetStub().GetStateByRange("", "")
    if err != nil {
        return nil, err
    }
    defer resultsIterator.Close()
    var records []*RoamingRecord
    for resultsIterator.HasNext() {
        queryResponse, err := resultsIterator.Next()
        if err != nil {
            return nil, err
        }
        var record RoamingRecord
        err = json.Unmarshal(queryResponse.Value, &record)
        if err != nil {
            return nil, err
        }
        records = append(records, &record)
    }
    return records, nil
}

func (s *LocationBasedRoaming) ValidateRoamingDistance(ctx contractapi.TransactionContextInterface, entityID, maxDistance string) (bool, error) {
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
    chaincode, err := contractapi.NewChaincode(&LocationBasedRoaming{})
    if err != nil {
        fmt.Printf("Error creating LocationBasedRoaming chaincode: %v", err)
    }
    if err := chaincode.Start(); err != nil {
        fmt.Printf("Error starting LocationBasedRoaming chaincode: %v", err)
    }
}
EOF
            ;;
        LocationBasedSignalStrength)
            cat > "$CHAINCODE_DIR/$contract/chaincode.go" <<'EOF'
package main

import (
    "encoding/json"
    "fmt"
    "math"
    "strconv"
    "time"

    "github.com/hyperledger/fabric-contract-api-go/contractapi"
)

type LocationBasedSignalStrength struct {
    contractapi.Contract
}

type SignalStrengthRecord struct {
    EntityID  string `json:"entityID"`
    Signal    string `json:"signal"`
    X         string `json:"x"`
    Y         string `json:"y"`
    Distance  string `json:"distance"`
    Timestamp string `json:"timestamp"`
}

func (s *LocationBasedSignalStrength) Init(ctx contractapi.TransactionContextInterface) error {
    return nil
}

func (s *LocationBasedSignalStrength) RecordSignalStrength(ctx contractapi.TransactionContextInterface, entityID, signal, x, y string) error {
    distance, err := calculateDistance(x, y, "0", "0")
    if err != nil {
        return err
    }
    record := SignalStrengthRecord{
        EntityID:  entityID,
        Signal:    signal,
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

func (s *LocationBasedSignalStrength) QueryAsset(ctx contractapi.TransactionContextInterface, entityID string) (*SignalStrengthRecord, error) {
    assetJSON, err := ctx.GetStub().GetState(entityID)
    if err != nil {
        return nil, fmt.Errorf("failed to read from world state: %v", err)
    }
    if assetJSON == nil {
        return nil, fmt.Errorf("signal strength record %s does not exist", entityID)
    }
    var record SignalStrengthRecord
    err = json.Unmarshal(assetJSON, &record)
    if err != nil {
        return nil, err
    }
    return &record, nil
}

func (s *LocationBasedSignalStrength) QueryAllAssets(ctx contractapi.TransactionContextInterface) ([]*SignalStrengthRecord, error) {
    resultsIterator, err := ctx.GetStub().GetStateByRange("", "")
    if err != nil {
        return nil, err
    }
    defer resultsIterator.Close()
    var records []*SignalStrengthRecord
    for resultsIterator.HasNext() {
        queryResponse, err := resultsIterator.Next()
        if err != nil {
            return nil, err
        }
        var record SignalStrengthRecord
        err = json.Unmarshal(queryResponse.Value, &record)
        if err != nil {
            return nil, err
        }
        records = append(records, &record)
    }
    return records, nil
}

func (s *LocationBasedSignalStrength) ValidateSignalDistance(ctx contractapi.TransactionContextInterface, entityID, maxDistance string) (bool, error) {
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
    chaincode, err := contractapi.NewChaincode(&LocationBasedSignalStrength{})
    if err != nil {
        fmt.Printf("Error creating LocationBasedSignalStrength chaincode: %v", err)
    }
    if err := chaincode.Start(); err != nil {
        fmt.Printf("Error starting LocationBasedSignalStrength chaincode: %v", err)
    }
}
EOF
            ;;
        LocationBasedCoverage)
            cat > "$CHAINCODE_DIR/$contract/chaincode.go" <<'EOF'
package main

import (
    "encoding/json"
    "fmt"
    "math"
    "strconv"
    "time"

    "github.com/hyperledger/fabric-contract-api-go/contractapi"
)

type LocationBasedCoverage struct {
    contractapi.Contract
}

type CoverageRecord struct {
    EntityID  string `json:"entityID"`
    Coverage  string `json:"coverage"`
    X         string `json:"x"`
    Y         string `json:"y"`
    Distance  string `json:"distance"`
    Timestamp string `json:"timestamp"`
}

func (s *LocationBasedCoverage) Init(ctx contractapi.TransactionContextInterface) error {
    return nil
}

func (s *LocationBasedCoverage) RecordCoverage(ctx contractapi.TransactionContextInterface, entityID, coverage, x, y string) error {
    distance, err := calculateDistance(x, y, "0", "0")
    if err != nil {
        return err
    }
    record := CoverageRecord{
        EntityID:  entityID,
        Coverage:  coverage,
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

func (s *LocationBasedCoverage) QueryAsset(ctx contractapi.TransactionContextInterface, entityID string) (*CoverageRecord, error) {
    assetJSON, err := ctx.GetStub().GetState(entityID)
    if err != nil {
        return nil, fmt.Errorf("failed to read from world state: %v", err)
    }
    if assetJSON == nil {
        return nil, fmt.Errorf("coverage record %s does not exist", entityID)
    }
    var record CoverageRecord
    err = json.Unmarshal(assetJSON, &record)
    if err != nil {
        return nil, err
    }
    return &record, nil
}

func (s *LocationBasedCoverage) QueryAllAssets(ctx contractapi.TransactionContextInterface) ([]*CoverageRecord, error) {
    resultsIterator, err := ctx.GetStub().GetStateByRange("", "")
    if err != nil {
        return nil, err
    }
    defer resultsIterator.Close()
    var records []*CoverageRecord
    for resultsIterator.HasNext() {
        queryResponse, err := resultsIterator.Next()
        if err != nil {
            return nil, err
        }
        var record CoverageRecord
        err = json.Unmarshal(queryResponse.Value, &record)
        if err != nil {
            return nil, err
        }
        records = append(records, &record)
    }
    return records, nil
}

func (s *LocationBasedCoverage) ValidateCoverageDistance(ctx contractapi.TransactionContextInterface, entityID, maxDistance string) (bool, error) {
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
    chaincode, err := contractapi.NewChaincode(&LocationBasedCoverage{})
    if err != nil {
        fmt.Printf("Error creating LocationBasedCoverage chaincode: %v", err)
    }
    if err := chaincode.Start(); err != nil {
        fmt.Printf("Error starting LocationBasedCoverage chaincode: %v", err)
    }
}
EOF
            ;;
        LocationBasedInterference)
            cat > "$CHAINCODE_DIR/$contract/chaincode.go" <<'EOF'
package main

import (
    "encoding/json"
    "fmt"
    "math"
    "strconv"
    "time"

    "github.com/hyperledger/fabric-contract-api-go/contractapi"
)

type LocationBasedInterference struct {
    contractapi.Contract
}

type InterferenceRecord struct {
    EntityID          string `json:"entityID"`
    InterferenceLevel string `json:"interferenceLevel"`
    X                 string `json:"x"`
    Y                 string `json:"y"`
    Distance          string `json:"distance"`
    Timestamp         string `json:"timestamp"`
}

func (s *LocationBasedInterference) Init(ctx contractapi.TransactionContextInterface) error {
    return nil
}

func (s *LocationBasedInterference) RecordInterference(ctx contractapi.TransactionContextInterface, entityID, interferenceLevel, x, y string) error {
    distance, err := calculateDistance(x, y, "0", "0")
    if err != nil {
        return err
    }
    record := InterferenceRecord{
        EntityID:          entityID,
        InterferenceLevel: interferenceLevel,
        X:                 x,
        Y:                 y,
        Distance:          distance,
        Timestamp:         time.Now().String(),
    }
    recordJSON, err := json.Marshal(record)
    if err != nil {
        return err
    }
    return ctx.GetStub().PutState(entityID, recordJSON)
}

func (s *LocationBasedInterference) QueryAsset(ctx contractapi.TransactionContextInterface, entityID string) (*InterferenceRecord, error) {
    assetJSON, err := ctx.GetStub().GetState(entityID)
    if err != nil {
        return nil, fmt.Errorf("failed to read from world state: %v", err)
    }
    if assetJSON == nil {
        return nil, fmt.Errorf("interference record %s does not exist", entityID)
    }
    var record InterferenceRecord
    err = json.Unmarshal(assetJSON, &record)
    if err != nil {
        return nil, err
    }
    return &record, nil
}

func (s *LocationBasedInterference) QueryAllAssets(ctx contractapi.TransactionContextInterface) ([]*InterferenceRecord, error) {
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

func (s *LocationBasedInterference) ValidateInterferenceDistance(ctx contractapi.TransactionContextInterface, entityID, maxDistance string) (bool, error) {
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
    chaincode, err := contractapi.NewChaincode(&LocationBasedInterference{})
    if err != nil {
        fmt.Printf("Error creating LocationBasedInterference chaincode: %v", err)
    }
    if err := chaincode.Start(); err != nil {
        fmt.Printf("Error starting LocationBasedInterference chaincode: %v", err)
    }
}
EOF
            ;;
        LocationBasedResourceAllocation)
            cat > "$CHAINCODE_DIR/$contract/chaincode.go" <<'EOF'
package main

import (
    "encoding/json"
    "fmt"
    "math"
    "strconv"
    "time"

    "github.com/hyperledger/fabric-contract-api-go/contractapi"
)

type LocationBasedResourceAllocation struct {
    contractapi.Contract
}

type ResourceAllocation struct {
    EntityID   string `json:"entityID"`
    ResourceID string `json:"resourceID"`
    Amount     string `json:"amount"`
    X          string `json:"x"`
    Y          string `json:"y"`
    Distance   string `json:"distance"`
    Timestamp  string `json:"timestamp"`
}

func (s *LocationBasedResourceAllocation) Init(ctx contractapi.TransactionContextInterface) error {
    return nil
}

func (s *LocationBasedResourceAllocation) AllocateResource(ctx contractapi.TransactionContextInterface, entityID, resourceID, amount, x, y string) error {
    distance, err := calculateDistance(x, y, "0", "0")
    if err != nil {
        return err
    }
    allocation := ResourceAllocation{
        EntityID:   entityID,
        ResourceID: resourceID,
        Amount:     amount,
        X:          x,
        Y:          y,
        Distance:   distance,
        Timestamp:  time.Now().String(),
    }
    allocationJSON, err := json.Marshal(allocation)
    if err != nil {
        return err
    }
    return ctx.GetStub().PutState(entityID, allocationJSON)
}

func (s *LocationBasedResourceAllocation) QueryAsset(ctx contractapi.TransactionContextInterface, entityID string) (*ResourceAllocation, error) {
    assetJSON, err := ctx.GetStub().GetState(entityID)
    if err != nil {
        return nil, fmt.Errorf("failed to read from world state: %v", err)
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

func (s *LocationBasedResourceAllocation) QueryAllAssets(ctx contractapi.TransactionContextInterface) ([]*ResourceAllocation, error) {
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

func (s *LocationBasedResourceAllocation) ValidateResourceDistance(ctx contractapi.TransactionContextInterface, entityID, maxDistance string) (bool, error) {
    allocation, err := s.QueryAsset(ctx, entityID)
    if err != nil {
        return false, err
    }
    distance, err := strconv.ParseFloat(allocation.Distance, 64)
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
    chaincode, err := contractapi.NewChaincode(&LocationBasedResourceAllocation{})
    if err != nil {
        fmt.Printf("Error creating LocationBasedResourceAllocation chaincode: %v", err)
    }
    if err := chaincode.Start(); err != nil {
        fmt.Printf("Error starting LocationBasedResourceAllocation chaincode: %v", err)
    }
}
EOF
            ;;
        LocationBasedNetworkLoad)
            cat > "$CHAINCODE_DIR/$contract/chaincode.go" <<'EOF'
package main

import (
    "encoding/json"
    "fmt"
    "math"
    "strconv"
    "time"

    "github.com/hyperledger/fabric-contract-api-go/contractapi"
)

type LocationBasedNetworkLoad struct {
    contractapi.Contract
}

type NetworkLoadRecord struct {
    EntityID  string `json:"entityID"`
    Load      string `json:"load"`
    X         string `json:"x"`
    Y         string `json:"y"`
    Distance  string `json:"distance"`
    Timestamp string `json:"timestamp"`
}

func (s *LocationBasedNetworkLoad) Init(ctx contractapi.TransactionContextInterface) error {
    return nil
}

func (s *LocationBasedNetworkLoad) RecordNetworkLoad(ctx contractapi.TransactionContextInterface, entityID, load, x, y string) error {
    distance, err := calculateDistance(x, y, "0", "0")
    if err != nil {
        return err
    }
    record := NetworkLoadRecord{
        EntityID:  entityID,
        Load:      load,
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

func (s *LocationBasedNetworkLoad) QueryAsset(ctx contractapi.TransactionContextInterface, entityID string) (*NetworkLoadRecord, error) {
    assetJSON, err := ctx.GetStub().GetState(entityID)
    if err != nil {
        return nil, fmt.Errorf("failed to read from world state: %v", err)
    }
    if assetJSON == nil {
        return nil, fmt.Errorf("network load record %s does not exist", entityID)
    }
    var record NetworkLoadRecord
    err = json.Unmarshal(assetJSON, &record)
    if err != nil {
        return nil, err
    }
    return &record, nil
}

func (s *LocationBasedNetworkLoad) QueryAllAssets(ctx contractapi.TransactionContextInterface) ([]*NetworkLoadRecord, error) {
    resultsIterator, err := ctx.GetStub().GetStateByRange("", "")
    if err != nil {
        return nil, err
    }
    defer resultsIterator.Close()
    var records []*NetworkLoadRecord
    for resultsIterator.HasNext() {
        queryResponse, err := resultsIterator.Next()
        if err != nil {
            return nil, err
        }
        var record NetworkLoadRecord
        err = json.Unmarshal(queryResponse.Value, &record)
        if err != nil {
            return nil, err
        }
        records = append(records, &record)
    }
    return records, nil
}

func (s *LocationBasedNetworkLoad) ValidateLoadDistance(ctx contractapi.TransactionContextInterface, entityID, maxDistance string) (bool, error) {
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
    chaincode, err := contractapi.NewChaincode(&LocationBasedNetworkLoad{})
    if err != nil {
        fmt.Printf("Error creating LocationBasedNetworkLoad chaincode: %v", err)
    }
    if err := chaincode.Start(); err != nil {
        fmt.Printf("Error starting LocationBasedNetworkLoad chaincode: %v", err)
    }
}
EOF
            ;;
    esac
done

echo "Generated chaincode for ${#contracts[@]} contracts in part 2:"
for contract in "${contracts[@]}"; do
    if [ -f "$CHAINCODE_DIR/$contract/chaincode.go" ]; then
        echo " - $contract: OK"
    else
        echo " - $contract: Failed"
    fi
done
