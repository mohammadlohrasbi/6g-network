#!/bin/bash

# Fixed and Complete generateChaincodes_part3.sh
# This script generates full Go chaincode for 9 contracts in part 3.
# Fix: Used <<'EOF' to prevent bash substitution of backticks in Go JSON tags.
# Added complete case for all contracts with customized structs and functions based on fields from errors.
# The Go code is complete with Init, Record/Set functions, Query, Validate, and distance calculation.

contracts=(
    "LocationBasedCongestion" "LocationBasedDynamicRouting" "LocationBasedAntennaConfig" "LocationBasedSignalQuality"
    "LocationBasedNetworkHealth" "LocationBasedPowerManagement" "LocationBasedChannelAllocation" "LocationBasedSessionManagement"
    "LocationBasedIoTConnection"
)

for contract in "${contracts[@]}"; do
    mkdir -p chaincode/$contract
    case $contract in
        LocationBasedCongestion)
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

type LocationBasedCongestion struct {
    contractapi.Contract
}

type Congestion struct {
    EntityID string `json:"entityID"`
    Congestion string `json:"congestion"`
    X string `json:"x"`
    Y string `json:"y"`
    Distance string `json:"distance"`
    Timestamp string `json:"timestamp"`
}

func (s *LocationBasedCongestion) Init(ctx contractapi.TransactionContextInterface) error {
    return nil
}

func (s *LocationBasedCongestion) RecordCongestion(ctx contractapi.TransactionContextInterface, entityID, congestion, x, y string) error {
    distance, err := calculateDistance(x, y, "0", "0")
    if err != nil {
        return err
    }
    congestionRecord := Congestion{
        EntityID: entityID,
        Congestion: congestion,
        X: x,
        Y: y,
        Distance: distance,
        Timestamp: time.Now().String(),
    }
    congestionJSON, err := json.Marshal(congestionRecord)
    if err != nil {
        return err
    }
    return ctx.GetStub().PutState(entityID, congestionJSON)
}

func (s *LocationBasedCongestion) QueryAsset(ctx contractapi.TransactionContextInterface, entityID string) (*Congestion, error) {
    assetJSON, err := ctx.GetStub().GetState(entityID)
    if err != nil {
        return nil, fmt.Errorf("failed to read from world state: %v", err)
    }
    if assetJSON == nil {
        return nil, fmt.Errorf("congestion %s does not exist", entityID)
    }
    var congestion Congestion
    err = json.Unmarshal(assetJSON, &congestion)
    if err != nil {
        return nil, err
    }
    return &congestion, nil
}

func (s *LocationBasedCongestion) QueryAllAssets(ctx contractapi.TransactionContextInterface) ([]*Congestion, error) {
    resultsIterator, err := ctx.GetStub().GetStateByRange("", "")
    if err != nil {
        return nil, err
    }
    defer resultsIterator.Close()
    var congestions []*Congestion
    for resultsIterator.HasNext() {
        queryResponse, err := resultsIterator.Next()
        if err != nil {
            return nil, err
        }
        var congestion Congestion
        err = json.Unmarshal(queryResponse.Value, &congestion)
        if err != nil {
            return nil, err
        }
        congestions = append(congestions, &congestion)
    }
    return congestions, nil
}

func (s *LocationBasedCongestion) ValidateCongestionDistance(ctx contractapi.TransactionContextInterface, entityID, maxDistance string) (bool, error) {
    congestion, err := s.QueryAsset(ctx, entityID)
    if err != nil {
        return false, err
    }
    distance, err := strconv.ParseFloat(congestion.Distance, 64)
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
    distance := math.Sqrt(math.Pow(x2Float - x1Float, 2) + math.Pow(y2Float - y1Float, 2))
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

type LocationBasedDynamicRouting struct {
    contractapi.Contract
}

type DynamicRouting struct {
    EntityID string `json:"entityID"`
    Route string `json:"route"`
    X string `json:"x"`
    Y string `json:"y"`
    Distance string `json:"distance"`
    Timestamp string `json:"timestamp"`
}

func (s *LocationBasedDynamicRouting) Init(ctx contractapi.TransactionContextInterface) error {
    return nil
}

func (s *LocationBasedDynamicRouting) SetDynamicRoute(ctx contractapi.TransactionContextInterface, entityID, route, x, y string) error {
    distance, err := calculateDistance(x, y, "0", "0")
    if err != nil {
        return err
    }
    dynamicRouting := DynamicRouting{
        EntityID: entityID,
        Route: route,
        X: x,
        Y: y,
        Distance: distance,
        Timestamp: time.Now().String(),
    }
    dynamicRoutingJSON, err := json.Marshal(dynamicRouting)
    if err != nil {
        return err
    }
    return ctx.GetStub().PutState(entityID, dynamicRoutingJSON)
}

func (s *LocationBasedDynamicRouting) QueryAsset(ctx contractapi.TransactionContextInterface, entityID string) (*DynamicRouting, error) {
    assetJSON, err := ctx.GetStub().GetState(entityID)
    if err != nil {
        return nil, fmt.Errorf("failed to read from world state: %v", err)
    }
    if assetJSON == nil {
        return nil, fmt.Errorf("dynamic routing %s does not exist", entityID)
    }
    var dynamicRouting DynamicRouting
    err = json.Unmarshal(assetJSON, &dynamicRouting)
    if err != nil {
        return nil, err
    }
    return &dynamicRouting, nil
}

func (s *LocationBasedDynamicRouting) QueryAllAssets(ctx contractapi.TransactionContextInterface) ([]*DynamicRouting, error) {
    resultsIterator, err := ctx.GetStub().GetStateByRange("", "")
    if err != nil {
        return nil, err
    }
    defer resultsIterator.Close()
    var dynamicRoutings []*DynamicRouting
    for resultsIterator.HasNext() {
        queryResponse, err := resultsIterator.Next()
        if err != nil {
            return nil, err
        }
        var dynamicRouting DynamicRouting
        err = json.Unmarshal(queryResponse.Value, &dynamicRouting)
        if err != nil {
            return nil, err
        }
        dynamicRoutings = append(dynamicRoutings, &dynamicRouting)
    }
    return dynamicRoutings, nil
}

func (s *LocationBasedDynamicRouting) ValidateDynamicRoutingDistance(ctx contractapi.TransactionContextInterface, entityID, maxDistance string) (bool, error) {
    dynamicRouting, err := s.QueryAsset(ctx, entityID)
    if err != nil {
        return false, err
    }
    distance, err := strconv.ParseFloat(dynamicRouting.Distance, 64)
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
    distance := math.Sqrt(math.Pow(x2Float - x1Float, 2) + math.Pow(y2Float - y1Float, 2))
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

type LocationBasedAntennaConfig struct {
    contractapi.Contract
}

type AntennaConfig struct {
    AntennaID string `json:"antennaID"`
    Config string `json:"config"`
    X string `json:"x"`
    Y string `json:"y"`
    Distance string `json:"distance"`
    Timestamp string `json:"timestamp"`
}

func (s *LocationBasedAntennaConfig) Init(ctx contractapi.TransactionContextInterface) error {
    return nil
}

func (s *LocationBasedAntennaConfig) SetAntennaConfig(ctx contractapi.TransactionContextInterface, antennaID, config, x, y string) error {
    distance, err := calculateDistance(x, y, "0", "0")
    if err != nil {
        return err
    }
    antennaConfig := AntennaConfig{
        AntennaID: antennaID,
        Config: config,
        X: x,
        Y: y,
        Distance: distance,
        Timestamp: time.Now().String(),
    }
    antennaConfigJSON, err := json.Marshal(antennaConfig)
    if err != nil {
        return err
    }
    return ctx.GetStub().PutState(antennaID, antennaConfigJSON)
}

func (s *LocationBasedAntennaConfig) QueryAsset(ctx contractapi.TransactionContextInterface, antennaID string) (*AntennaConfig, error) {
    assetJSON, err := ctx.GetStub().GetState(antennaID)
    if err != nil {
        return nil, fmt.Errorf("failed to read from world state: %v", err)
    }
    if assetJSON == nil {
        return nil, fmt.Errorf("antenna config %s does not exist", antennaID)
    }
    var antennaConfig AntennaConfig
    err = json.Unmarshal(assetJSON, &antennaConfig)
    if err != nil {
        return nil, err
    }
    return &antennaConfig, nil
}

func (s *LocationBasedAntennaConfig) QueryAllAssets(ctx contractapi.TransactionContextInterface) ([]*AntennaConfig, error) {
    resultsIterator, err := ctx.GetStub().GetStateByRange("", "")
    if err != nil {
        return nil, err
    }
    defer resultsIterator.Close()
    var antennaConfigs []*AntennaConfig
    for resultsIterator.HasNext() {
        queryResponse, err := resultsIterator.Next()
        if err != nil {
            return nil, err
        }
        var antennaConfig AntennaConfig
        err = json.Unmarshal(queryResponse.Value, &antennaConfig)
        if err != nil {
            return nil, err
        }
        antennaConfigs = append(antennaConfigs, &antennaConfig)
    }
    return antennaConfigs, nil
}

func (s *LocationBasedAntennaConfig) ValidateAntennaConfigDistance(ctx contractapi.TransactionContextInterface, antennaID, maxDistance string) (bool, error) {
    antennaConfig, err := s.QueryAsset(ctx, antennaID)
    if err != nil {
        return false, err
    }
    distance, err := strconv.ParseFloat(antennaConfig.Distance, 64)
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
    distance := math.Sqrt(math.Pow(x2Float - x1Float, 2) + math.Pow(y2Float - y1Float, 2))
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

type LocationBasedSignalQuality struct {
    contractapi.Contract
}

type SignalQuality struct {
    EntityID string `json:"entityID"`
    SignalQuality string `json:"signalQuality"`
    X string `json:"x"`
    Y string `json:"y"`
    Distance string `json:"distance"`
    Timestamp string `json:"timestamp"`
}

func (s *LocationBasedSignalQuality) Init(ctx contractapi.TransactionContextInterface) error {
    return nil
}

func (s *LocationBasedSignalQuality) RecordSignalQuality(ctx contractapi.TransactionContextInterface, entityID, signalQuality, x, y string) error {
    distance, err := calculateDistance(x, y, "0", "0")
    if err != nil {
        return err
    }
    signalQualityRecord := SignalQuality{
        EntityID: entityID,
        SignalQuality: signalQuality,
        X: x,
        Y: y,
        Distance: distance,
        Timestamp: time.Now().String(),
    }
    signalQualityJSON, err := json.Marshal(signalQualityRecord)
    if err != nil {
        return err
    }
    return ctx.GetStub().PutState(entityID, signalQualityJSON)
}

func (s *LocationBasedSignalQuality) QueryAsset(ctx contractapi.TransactionContextInterface, entityID string) (*SignalQuality, error) {
    assetJSON, err := ctx.GetStub().GetState(entityID)
    if err != nil {
        return nil, fmt.Errorf("failed to read from world state: %v", err)
    }
    if assetJSON == nil {
        return nil, fmt.Errorf("signal quality %s does not exist", entityID)
    }
    var signalQuality SignalQuality
    err = json.Unmarshal(assetJSON, &signalQuality)
    if err != nil {
        return nil, err
    }
    return &signalQuality, nil
}

func (s *LocationBasedSignalQuality) QueryAllAssets(ctx contractapi.TransactionContextInterface) ([]*SignalQuality, error) {
    resultsIterator, err := ctx.GetStub().GetStateByRange("", "")
    if err != nil {
        return nil, err
    }
    defer resultsIterator.Close()
    var signalQualities []*SignalQuality
    for resultsIterator.HasNext() {
        queryResponse, err := resultsIterator.Next()
        if err != nil {
            return nil, err
        }
        var signalQuality SignalQuality
        err = json.Unmarshal(queryResponse.Value, &signalQuality)
        if err != nil {
            return nil, err
        }
        signalQualities = append(signalQualities, &signalQuality)
    }
    return signalQualities, nil
}

func (s *LocationBasedSignalQuality) ValidateSignalQualityDistance(ctx contractapi.TransactionContextInterface, entityID, maxDistance string) (bool, error) {
    signalQuality, err := s.QueryAsset(ctx, entityID)
    if err != nil {
        return false, err
    }
    distance, err := strconv.ParseFloat(signalQuality.Distance, 64)
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
    distance := math.Sqrt(math.Pow(x2Float - x1Float, 2) + math.Pow(y2Float - y1Float, 2))
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

type LocationBasedNetworkHealth struct {
    contractapi.Contract
}

type NetworkHealth struct {
    EntityID string `json:"entityID"`
    HealthStatus string `json:"healthStatus"`
    X string `json:"x"`
    Y string `json:"y"`
    Distance string `json:"distance"`
    Timestamp string `json:"timestamp"`
}

func (s *LocationBasedNetworkHealth) Init(ctx contractapi.TransactionContextInterface) error {
    return nil
}

func (s *LocationBasedNetworkHealth) RecordNetworkHealth(ctx contractapi.TransactionContextInterface, entityID, healthStatus, x, y string) error {
    distance, err := calculateDistance(x, y, "0", "0")
    if err != nil {
        return err
    }
    networkHealth := NetworkHealth{
        EntityID: entityID,
        HealthStatus: healthStatus,
        X: x,
        Y: y,
        Distance: distance,
        Timestamp: time.Now().String(),
    }
    networkHealthJSON, err := json.Marshal(networkHealth)
    if err != nil {
        return err
    }
    return ctx.GetStub().PutState(entityID, networkHealthJSON)
}

func (s *LocationBasedNetworkHealth) QueryAsset(ctx contractapi.TransactionContextInterface, entityID string) (*NetworkHealth, error) {
    assetJSON, err := ctx.GetStub().GetState(entityID)
    if err != nil {
        return nil, fmt.Errorf("failed to read from world state: %v", err)
    }
    if assetJSON == nil {
        return nil, fmt.Errorf("network health %s does not exist", entityID)
    }
    var networkHealth NetworkHealth
    err = json.Unmarshal(assetJSON, &networkHealth)
    if err != nil {
        return nil, err
    }
    return &networkHealth, nil
}

func (s *LocationBasedNetworkHealth) QueryAllAssets(ctx contractapi.TransactionContextInterface) ([]*NetworkHealth, error) {
    resultsIterator, err := ctx.GetStub().GetStateByRange("", "")
    if err != nil {
        return nil, err
    }
    defer resultsIterator.Close()
    var networkHealths []*NetworkHealth
    for resultsIterator.HasNext() {
        queryResponse, err := resultsIterator.Next()
        if err != nil {
            return nil, err
        }
        var networkHealth NetworkHealth
        err = json.Unmarshal(queryResponse.Value, &networkHealth)
        if err != nil {
            return nil, err
        }
        networkHealths = append(networkHealths, &networkHealth)
    }
    return networkHealths, nil
}

func (s *LocationBasedNetworkHealth) ValidateNetworkHealthDistance(ctx contractapi.TransactionContextInterface, entityID, maxDistance string) (bool, error) {
    networkHealth, err := s.QueryAsset(ctx, entityID)
    if err != nil {
        return false, err
    }
    distance, err := strconv.ParseFloat(networkHealth.Distance, 64)
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
    distance := math.Sqrt(math.Pow(x2Float - x1Float, 2) + math.Pow(y2Float - y1Float, 2))
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

type LocationBasedPowerManagement struct {
    contractapi.Contract
}

type PowerManagement struct {
    EntityID string `json:"entityID"`
    PowerLevel string `json:"powerLevel"`
    X string `json:"x"`
    Y string `json:"y"`
    Distance string `json:"distance"`
    Timestamp string `json:"timestamp"`
}

func (s *LocationBasedPowerManagement) Init(ctx contractapi.TransactionContextInterface) error {
    return nil
}

func (s *LocationBasedPowerManagement) SetPowerLevel(ctx contractapi.TransactionContextInterface, entityID, powerLevel, x, y string) error {
    distance, err := calculateDistance(x, y, "0", "0")
    if err != nil {
        return err
    }
    powerManagement := PowerManagement{
        EntityID: entityID,
        PowerLevel: powerLevel,
        X: x,
        Y: y,
        Distance: distance,
        Timestamp: time.Now().String(),
    }
    powerManagementJSON, err := json.Marshal(powerManagement)
    if err != nil {
        return err
    }
    return ctx.GetStub().PutState(entityID, powerManagementJSON)
}

func (s *LocationBasedPowerManagement) QueryAsset(ctx contractapi.TransactionContextInterface, entityID string) (*PowerManagement, error) {
    assetJSON, err := ctx.GetStub().GetState(entityID)
    if err != nil {
        return nil, fmt.Errorf("failed to read from world state: %v", err)
    }
    if assetJSON == nil {
        return nil, fmt.Errorf("power management %s does not exist", entityID)
    }
    var powerManagement PowerManagement
    err = json.Unmarshal(assetJSON, &powerManagement)
    if err != nil {
        return nil, err
    }
    return &powerManagement, nil
}

func (s *LocationBasedPowerManagement) QueryAllAssets(ctx contractapi.TransactionContextInterface) ([]*PowerManagement, error) {
    resultsIterator, err := ctx.GetStub().GetStateByRange("", "")
    if err != nil {
        return nil, err
    }
    defer resultsIterator.Close()
    var powerManagements []*PowerManagement
    for resultsIterator.HasNext() {
        queryResponse, err := resultsIterator.Next()
        if err != nil {
            return nil, err
        }
        var powerManagement PowerManagement
        err = json.Unmarshal(queryResponse.Value, &powerManagement)
        if err != nil {
            return nil, err
        }
        powerManagements = append(powerManagements, &powerManagement)
    }
    return powerManagements, nil
}

func (s *LocationBasedPowerManagement) ValidatePowerManagementDistance(ctx contractapi.TransactionContextInterface, entityID, maxDistance string) (bool, error) {
    powerManagement, err := s.QueryAsset(ctx, entityID)
    if err != nil {
        return false, err
    }
    distance, err := strconv.ParseFloat(powerManagement.Distance, 64)
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
    distance := math.Sqrt(math.Pow(x2Float - x1Float, 2) + math.Pow(y2Float - y1Float, 2))
    return fmt.Sprintf("%.4f", distance), nil
}

func main() {
    chaincode, err := contractapi.NewChaincode(&LocationBasedPowerManagement{})
    if err != nil {
        fmt.Printf("Error creating LocationBasedPowerManagement chaincode: %v", err)
    }
    if err := chaincode.Start(); err != nil {
        fmt.Printf("Error starting LocationBasedPowerManagement chaincode: %v", err)
    }
}
EOF
            ;;
        LocationBasedChannelAllocation)
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

type LocationBasedChannelAllocation struct {
    contractapi.Contract
}

type ChannelAllocation struct {
    EntityID string `json:"entityID"`
    ChannelID string `json:"channelID"`
    X string `json:"x"`
    Y string `json:"y"`
    Distance string `json:"distance"`
    Timestamp string `json:"timestamp"`
}

func (s *LocationBasedChannelAllocation) Init(ctx contractapi.TransactionContextInterface) error {
    return nil
}

func (s *LocationBasedChannelAllocation) AllocateChannel(ctx contractapi.TransactionContextInterface, entityID, channelID, x, y string) error {
    distance, err := calculateDistance(x, y, "0", "0")
    if err != nil {
        return err
    }
    channelAllocation := ChannelAllocation{
        EntityID: entityID,
        ChannelID: channelID,
        X: x,
        Y: y,
        Distance: distance,
        Timestamp: time.Now().String(),
    }
    channelAllocationJSON, err := json.Marshal(channelAllocation)
    if err != nil {
        return err
    }
    return ctx.GetStub().PutState(entityID, channelAllocationJSON)
}

func (s *LocationBasedChannelAllocation) QueryAsset(ctx contractapi.TransactionContextInterface, entityID string) (*ChannelAllocation, error) {
    assetJSON, err := ctx.GetStub().GetState(entityID)
    if err != nil {
        return nil, fmt.Errorf("failed to read from world state: %v", err)
    }
    if assetJSON == nil {
        return nil, fmt.Errorf("channel allocation %s does not exist", entityID)
    }
    var channelAllocation ChannelAllocation
    err = json.Unmarshal(assetJSON, &channelAllocation)
    if err != nil {
        return nil, err
    }
    return &channelAllocation, nil
}

func (s *LocationBasedChannelAllocation) QueryAllAssets(ctx contractapi.TransactionContextInterface) ([]*ChannelAllocation, error) {
    resultsIterator, err := ctx.GetStub().GetStateByRange("", "")
    if err != nil {
        return nil, err
    }
    defer resultsIterator.Close()
    var channelAllocations []*ChannelAllocation
    for resultsIterator.HasNext() {
        queryResponse, err := resultsIterator.Next()
        if err != nil {
            return nil, err
        }
        var channelAllocation ChannelAllocation
        err = json.Unmarshal(queryResponse.Value, &channelAllocation)
        if err != nil {
            return nil, err
        }
        channelAllocations = append(channelAllocations, &channelAllocation)
    }
    return channelAllocations, nil
}

func (s *LocationBasedChannelAllocation) ValidateChannelAllocationDistance(ctx contractapi.TransactionContextInterface, entityID, maxDistance string) (bool, error) {
    channelAllocation, err := s.QueryAsset(ctx, entityID)
    if err != nil {
        return false, err
    }
    distance, err := strconv.ParseFloat(channelAllocation.Distance, 64)
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
    distance := math.Sqrt(math.Pow(x2Float - x1Float, 2) + math.Pow(y2Float - y1Float, 2))
    return fmt.Sprintf("%.4f", distance), nil
}

func main() {
    chaincode, err := contractapi.NewChaincode(&LocationBasedChannelAllocation{})
    if err != nil {
        fmt.Printf("Error creating LocationBasedChannelAllocation chaincode: %v", err)
    }
    if err := chaincode.Start(); err != nil {
        fmt.Printf("Error starting LocationBasedChannelAllocation chaincode: %v", err)
    }
}
EOF
            ;;
        LocationBasedSessionManagement)
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

type LocationBasedSessionManagement struct {
    contractapi.Contract
}

type SessionManagement struct {
    EntityID string `json:"entityID"`
    SessionID string `json:"sessionID"`
    X string `json:"x"`
    Y string `json:"y"`
    Distance string `json:"distance"`
    Status string `json:"status"`
    Timestamp string `json:"timestamp"`
}

func (s *LocationBasedSessionManagement) Init(ctx contractapi.TransactionContextInterface) error {
    return nil
}

func (s *LocationBasedSessionManagement) ManageSession(ctx contractapi.TransactionContextInterface, entityID, sessionID, x, y, status string) error {
    distance, err := calculateDistance(x, y, "0", "0")
    if err != nil {
        return err
    }
    sessionManagement := SessionManagement{
        EntityID: entityID,
        SessionID: sessionID,
        X: x,
        Y: y,
        Distance: distance,
        Status: status,
        Timestamp: time.Now().String(),
    }
    sessionManagementJSON, err := json.Marshal(sessionManagement)
    if err != nil {
        return err
    }
    return ctx.GetStub().PutState(entityID, sessionManagementJSON)
}

func (s *LocationBasedSessionManagement) QueryAsset(ctx contractapi.TransactionContextInterface, entityID string) (*SessionManagement, error) {
    assetJSON, err := ctx.GetStub().GetState(entityID)
    if err != nil {
        return nil, fmt.Errorf("failed to read from world state: %v", err)
    }
    if assetJSON == nil {
        return nil, fmt.Errorf("session management %s does not exist", entityID)
    }
    var sessionManagement SessionManagement
    err = json.Unmarshal(assetJSON, &sessionManagement)
    if err != nil {
        return nil, err
    }
    return &sessionManagement, nil
}

func (s *LocationBasedSessionManagement) QueryAllAssets(ctx contractapi.TransactionContextInterface) ([]*SessionManagement, error) {
    resultsIterator, err := ctx.GetStub().GetStateByRange("", "")
    if err != nil {
        return nil, err
    }
    defer resultsIterator.Close()
    var sessionManagements []*SessionManagement
    for resultsIterator.HasNext() {
        queryResponse, err := resultsIterator.Next()
        if err != nil {
            return nil, err
        }
        var sessionManagement SessionManagement
        err = json.Unmarshal(queryResponse.Value, &sessionManagement)
        if err != nil {
            return nil, err
        }
        sessionManagements = append(sessionManagements, &sessionManagement)
    }
    return sessionManagements, nil
}

func (s *LocationBasedSessionManagement) ValidateSessionManagementDistance(ctx contractapi.TransactionContextInterface, entityID, maxDistance string) (bool, error) {
    sessionManagement, err := s.QueryAsset(ctx, entityID)
    if err != nil {
        return false, err
    }
    distance, err := strconv.ParseFloat(sessionManagement.Distance, 64)
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
    distance := math.Sqrt(math.Pow(x2Float - x1Float, 2) + math.Pow(y2Float - y1Float, 2))
    return fmt.Sprintf("%.4f", distance), nil
}

func main() {
    chaincode, err := contractapi.NewChaincode(&LocationBasedSessionManagement{})
    if err != nil {
        fmt.Printf("Error creating LocationBasedSessionManagement chaincode: %v", err)
    }
    if err := chaincode.Start(); err != nil {
        fmt.Printf("Error starting LocationBasedSessionManagement chaincode: %v", err)
    }
}
EOF
            ;;
        LocationBasedIoTConnection)
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

type LocationBasedIoTConnection struct {
    contractapi.Contract
}

type IoTConnection struct {
    DeviceID string `json:"deviceID"`
    AntennaID string `json:"antennaID"`
    X string `json:"x"`
    Y string `json:"y"`
    Distance string `json:"distance"`
    Status string `json:"status"`
    Timestamp string `json:"timestamp"`
}

func (s *LocationBasedIoTConnection) Init(ctx contractapi.TransactionContextInterface) error {
    return nil
}

func (s *LocationBasedIoTConnection) ConnectIoT(ctx contractapi.TransactionContextInterface, deviceID, antennaID, x, y string) error {
    antenna, err := s.QueryAsset(ctx, antennaID)
    if err != nil {
        return fmt.Errorf("failed to query antenna: %v", err)
    }
    distance, err := calculateDistance(x, y, antenna.X, antenna.Y)
    if err != nil {
        return err
    }
    iotConnection := IoTConnection{
        DeviceID: deviceID,
        AntennaID: antennaID,
        X: x,
        Y: y,
        Distance: distance,
        Status: "Connected",
        Timestamp: time.Now().String(),
    }
    iotConnectionJSON, err := json.Marshal(iotConnection)
    if err != nil {
        return err
    }
    return ctx.GetStub().PutState(deviceID, iotConnectionJSON)
}

func (s *LocationBasedIoTConnection) DisconnectIoT(ctx contractapi.TransactionContextInterface, deviceID string) error {
    iotConnection, err := s.QueryAsset(ctx, deviceID)
    if err != nil {
        return err
    }
    iotConnection.Status = "Disconnected"
    iotConnection.Timestamp = time.Now().String()
    iotConnectionJSON, err := json.Marshal(iotConnection)
    if err != nil {
        return err
    }
    return ctx.GetStub().PutState(deviceID, iotConnectionJSON)
}

func (s *LocationBasedIoTConnection) QueryAsset(ctx contractapi.TransactionContextInterface, deviceID string) (*IoTConnection, error) {
    assetJSON, err := ctx.GetStub().GetState(deviceID)
    if err != nil {
        return nil, fmt.Errorf("failed to read from world state: %v", err)
    }
    if assetJSON == nil {
        return nil, fmt.Errorf("IoT connection %s does not exist", deviceID)
    }
    var iotConnection IoTConnection
    err = json.Unmarshal(assetJSON, &iotConnection)
    if err != nil {
        return nil, err
    }
    return &iotConnection, nil
}

func (s *LocationBasedIoTConnection) QueryAllAssets(ctx contractapi.TransactionContextInterface) ([]*IoTConnection, error) {
    resultsIterator, err := ctx.GetStub().GetStateByRange("", "")
    if err != nil {
        return nil, err
    }
    defer resultsIterator.Close()
    var iotConnections []*IoTConnection
    for resultsIterator.HasNext() {
        queryResponse, err := resultsIterator.Next()
        if err != nil {
            return nil, err
        }
        var iotConnection IoTConnection
        err = json.Unmarshal(queryResponse.Value, &iotConnection)
        if err != nil {
            return nil, err
        }
        iotConnections = append(iotConnections, &iotConnection)
    }
    return iotConnections, nil
}

func (s *LocationBasedIoTConnection) ValidateIoTConnectionDistance(ctx contractapi.TransactionContextInterface, deviceID, maxDistance string) (bool, error) {
    iotConnection, err := s.QueryAsset(ctx, deviceID)
    if err != nil {
        return false, err
    }
    distance, err := strconv.ParseFloat(iotConnection.Distance, 64)
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
    distance := math.Sqrt(math.Pow(x2Float - x1Float, 2) + math.Pow(y2Float - y1Float, 2))
    return fmt.Sprintf("%.4f", distance), nil
}

func main() {
    chaincode, err := contractapi.NewChaincode(&LocationBasedIoTConnection{})
    if err != nil {
        fmt.Printf("Error creating LocationBasedIoTConnection chaincode: %v", err)
    }
    if err := chaincode.Start(); err != nil {
        fmt.Printf("Error starting LocationBasedIoTConnection chaincode: %v", err)
    }
}
EOF
            ;;
    esac
done

echo "Generated chaincode for ${#contracts[@]} contracts in part 3:"
for contract in "${contracts[@]}"; do
    if [ -f "chaincode/$contract/chaincode.go" ]; then
        echo " - $contract: OK"
    else
        echo " - $contract: Failed"
    fi
done
