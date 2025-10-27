#!/bin/bash

# Fixed and Complete generateChaincodes_part1.sh
# This script generates full Go chaincode for 9 contracts in part 1.
# Fix: Used <<'EOF' to prevent bash substitution of backticks in Go JSON tags.
# Added complete case for all contracts with customized structs and functions based on fields from errors.
# The Go code is complete with Init, Assign/Query functions, and distance calculation where applicable.

contracts=(
    "LocationBasedAssignment" "LocationBasedConnection" "LocationBasedBandwidth" "LocationBasedQoS"
    "LocationBasedPriority" "LocationBasedStatus" "LocationBasedFault" "LocationBasedTraffic"
    "LocationBasedLatency"
)

for contract in "${contracts[@]}"; do
    mkdir -p chaincode/$contract
    case $contract in
        LocationBasedAssignment)
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

type LocationBasedAssignment struct {
    contractapi.Contract
}

type Assignment struct {
    EntityID string `json:"entityID"`
    AntennaID string `json:"antennaID"`
    X string `json:"x"`
    Y string `json:"y"`
    Distance string `json:"distance"`
    Timestamp string `json:"timestamp"`
}

func (s *LocationBasedAssignment) Init(ctx contractapi.TransactionContextInterface) error {
    return nil
}

func (s *LocationBasedAssignment) AssignAntenna(ctx contractapi.TransactionContextInterface, entityID, antennaID, x, y string) error {
    antenna, err := s.QueryAsset(ctx, antennaID)
    if err != nil {
        return fmt.Errorf("failed to query antenna: %v", err)
    }
    distance, err := calculateDistance(x, y, antenna.X, antenna.Y)
    if err != nil {
        return err
    }
    assignment := Assignment{
        EntityID: entityID,
        AntennaID: antennaID,
        X: x,
        Y: y,
        Distance: distance,
        Timestamp: time.Now().String(),
    }
    assignmentJSON, err := json.Marshal(assignment)
    if err != nil {
        return err
    }
    return ctx.GetStub().PutState(entityID, assignmentJSON)
}

func (s *LocationBasedAssignment) QueryAsset(ctx contractapi.TransactionContextInterface, entityID string) (*Assignment, error) {
    assetJSON, err := ctx.GetStub().GetState(entityID)
    if err != nil {
        return nil, fmt.Errorf("failed to read from world state: %v", err)
    }
    if assetJSON == nil {
        return nil, fmt.Errorf("assignment %s does not exist", entityID)
    }
    var asset Assignment
    err = json.Unmarshal(assetJSON, &asset)
    if err != nil {
        return nil, err
    }
    return &asset, nil
}

func (s *LocationBasedAssignment) QueryAllAssets(ctx contractapi.TransactionContextInterface) ([]*Assignment, error) {
    resultsIterator, err := ctx.GetStub().GetStateByRange("", "")
    if err != nil {
        return nil, err
    }
    defer resultsIterator.Close()
    var assets []*Assignment
    for resultsIterator.HasNext() {
        queryResponse, err := resultsIterator.Next()
        if err != nil {
            return nil, err
        }
        var asset Assignment
        err = json.Unmarshal(queryResponse.Value, &asset)
        if err != nil {
            return nil, err
        }
        assets = append(assets, &asset)
    }
    return assets, nil
}

func (s *LocationBasedAssignment) ValidateAssignmentDistance(ctx contractapi.TransactionContextInterface, entityID, maxDistance string) (bool, error) {
    asset, err := s.QueryAsset(ctx, entityID)
    if err != nil {
        return false, err
    }
    distance, err := strconv.ParseFloat(asset.Distance, 64)
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
    chaincode, err := contractapi.NewChaincode(&LocationBasedAssignment{})
    if err != nil {
        fmt.Printf("Error creating LocationBasedAssignment chaincode: %v", err)
    }
    if err := chaincode.Start(); err != nil {
        fmt.Printf("Error starting LocationBasedAssignment chaincode: %v", err)
    }
}
EOF
            ;;
        LocationBasedConnection)
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

type LocationBasedConnection struct {
    contractapi.Contract
}

type Connection struct {
    EntityID string `json:"entityID"`
    AntennaID string `json:"antennaID"`
    X string `json:"x"`
    Y string `json:"y"`
    Distance string `json:"distance"`
    Status string `json:"status"`
    Timestamp string `json:"timestamp"`
}

func (s *LocationBasedConnection) Init(ctx contractapi.TransactionContextInterface) error {
    return nil
}

func (s *LocationBasedConnection) ConnectEntity(ctx contractapi.TransactionContextInterface, entityID, antennaID, x, y string) error {
    antenna, err := s.QueryAsset(ctx, antennaID)
    if err != nil {
        return fmt.Errorf("failed to query antenna: %v", err)
    }
    distance, err := calculateDistance(x, y, antenna.X, antenna.Y)
    if err != nil {
        return err
    }
    connection := Connection{
        EntityID: entityID,
        AntennaID: antennaID,
        X: x,
        Y: y,
        Distance: distance,
        Status: "Connected",
        Timestamp: time.Now().String(),
    }
    connectionJSON, err := json.Marshal(connection)
    if err != nil {
        return err
    }
    return ctx.GetStub().PutState(entityID, connectionJSON)
}

func (s *LocationBasedConnection) DisconnectEntity(ctx contractapi.TransactionContextInterface, entityID string) error {
    connection, err := s.QueryAsset(ctx, entityID)
    if err != nil {
        return err
    }
    connection.Status = "Disconnected"
    connection.Timestamp = time.Now().String()
    connectionJSON, err := json.Marshal(connection)
    if err != nil {
        return err
    }
    return ctx.GetStub().PutState(entityID, connectionJSON)
}

func (s *LocationBasedConnection) QueryAsset(ctx contractapi.TransactionContextInterface, entityID string) (*Connection, error) {
    assetJSON, err := ctx.GetStub().GetState(entityID)
    if err != nil {
        return nil, fmt.Errorf("failed to read from world state: %v", err)
    }
    if assetJSON == nil {
        return nil, fmt.Errorf("connection %s does not exist", entityID)
    }
    var connection Connection
    err = json.Unmarshal(assetJSON, &connection)
    if err != nil {
        return nil, err
    }
    return &connection, nil
}

func (s *LocationBasedConnection) QueryAllAssets(ctx contractapi.TransactionContextInterface) ([]*Connection, error) {
    resultsIterator, err := ctx.GetStub().GetStateByRange("", "")
    if err != nil {
        return nil, err
    }
    defer resultsIterator.Close()
    var connections []*Connection
    for resultsIterator.HasNext() {
        queryResponse, err := resultsIterator.Next()
        if err != nil {
            return nil, err
        }
        var connection Connection
        err = json.Unmarshal(queryResponse.Value, &connection)
        if err != nil {
            return nil, err
        }
        connections = append(connections, &connection)
    }
    return connections, nil
}

func (s *LocationBasedConnection) ValidateConnectionDistance(ctx contractapi.TransactionContextInterface, entityID, maxDistance string) (bool, error) {
    connection, err := s.QueryAsset(ctx, entityID)
    if err != nil {
        return false, err
    }
    distance, err := strconv.ParseFloat(connection.Distance, 64)
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
    chaincode, err := contractapi.NewChaincode(&LocationBasedConnection{})
    if err != nil {
        fmt.Printf("Error creating LocationBasedConnection chaincode: %v", err)
    }
    if err := chaincode.Start(); err != nil {
        fmt.Printf("Error starting LocationBasedConnection chaincode: %v", err)
    }
}
EOF
            ;;
        LocationBasedBandwidth)
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

type LocationBasedBandwidth struct {
    contractapi.Contract
}

type Bandwidth struct {
    EntityID string `json:"entityID"`
    AntennaID string `json:"antennaID"`
    Bandwidth string `json:"bandwidth"`
    X string `json:"x"`
    Y string `json:"y"`
    Distance string `json:"distance"`
    Timestamp string `json:"timestamp"`
}

func (s *LocationBasedBandwidth) Init(ctx contractapi.TransactionContextInterface) error {
    return nil
}

func (s *LocationBasedBandwidth) AssignBandwidth(ctx contractapi.TransactionContextInterface, entityID, antennaID, bandwidth, x, y string) error {
    antenna, err := s.QueryAsset(ctx, antennaID)
    if err != nil {
        return fmt.Errorf("failed to query antenna: %v", err)
    }
    distance, err := calculateDistance(x, y, antenna.X, antenna.Y)
    if err != nil {
        return err
    }
    bandwidthAlloc := Bandwidth{
        EntityID: entityID,
        AntennaID: antennaID,
        Bandwidth: bandwidth,
        X: x,
        Y: y,
        Distance: distance,
        Timestamp: time.Now().String(),
    }
    bandwidthJSON, err := json.Marshal(bandwidthAlloc)
    if err != nil {
        return err
    }
    return ctx.GetStub().PutState(entityID, bandwidthJSON)
}

func (s *LocationBasedBandwidth) QueryAsset(ctx contractapi.TransactionContextInterface, entityID string) (*Bandwidth, error) {
    assetJSON, err := ctx.GetStub().GetState(entityID)
    if err != nil {
        return nil, fmt.Errorf("failed to read from world state: %v", err)
    }
    if assetJSON == nil {
        return nil, fmt.Errorf("bandwidth %s does not exist", entityID)
    }
    var bandwidth Bandwidth
    err = json.Unmarshal(assetJSON, &bandwidth)
    if err != nil {
        return nil, err
    }
    return &bandwidth, nil
}

func (s *LocationBasedBandwidth) QueryAllAssets(ctx contractapi.TransactionContextInterface) ([]*Bandwidth, error) {
    resultsIterator, err := ctx.GetStub().GetStateByRange("", "")
    if err != nil {
        return nil, err
    }
    defer resultsIterator.Close()
    var bandwidths []*Bandwidth
    for resultsIterator.HasNext() {
        queryResponse, err := resultsIterator.Next()
        if err != nil {
            return nil, err
        }
        var bandwidth Bandwidth
        err = json.Unmarshal(queryResponse.Value, &bandwidth)
        if err != nil {
            return nil, err
        }
        bandwidths = append(bandwidths, &bandwidth)
    }
    return bandwidths, nil
}

func (s *LocationBasedBandwidth) ValidateBandwidthDistance(ctx contractapi.TransactionContextInterface, entityID, maxDistance string) (bool, error) {
    bandwidth, err := s.QueryAsset(ctx, entityID)
    if err != nil {
        return false, err
    }
    distance, err := strconv.ParseFloat(bandwidth.Distance, 64)
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
    chaincode, err := contractapi.NewChaincode(&LocationBasedBandwidth{})
    if err != nil {
        fmt.Printf("Error creating LocationBasedBandwidth chaincode: %v", err)
    }
    if err := chaincode.Start(); err != nil {
        fmt.Printf("Error starting LocationBasedBandwidth chaincode: %v", err)
    }
}
EOF
            ;;
        LocationBasedQoS)
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

type LocationBasedQoS struct {
    contractapi.Contract
}

type QoS struct {
    EntityID string `json:"entityID"`
    AntennaID string `json:"antennaID"`
    QoSLevel string `json:"qosLevel"`
    X string `json:"x"`
    Y string `json:"y"`
    Distance string `json:"distance"`
    Timestamp string `json:"timestamp"`
}

func (s *LocationBasedQoS) Init(ctx contractapi.TransactionContextInterface) error {
    return nil
}

func (s *LocationBasedQoS) AssignQoS(ctx contractapi.TransactionContextInterface, entityID, antennaID, qosLevel, x, y string) error {
    antenna, err := s.QueryAsset(ctx, antennaID)
    if err != nil {
        return fmt.Errorf("failed to query antenna: %v", err)
    }
    distance, err := calculateDistance(x, y, antenna.X, antenna.Y)
    if err != nil {
        return err
    }
    qos := QoS{
        EntityID: entityID,
        AntennaID: antennaID,
        QoSLevel: qosLevel,
        X: x,
        Y: y,
        Distance: distance,
        Timestamp: time.Now().String(),
    }
    qosJSON, err := json.Marshal(qos)
    if err != nil {
        return err
    }
    return ctx.GetStub().PutState(entityID, qosJSON)
}

func (s *LocationBasedQoS) QueryAsset(ctx contractapi.TransactionContextInterface, entityID string) (*QoS, error) {
    assetJSON, err := ctx.GetStub().GetState(entityID)
    if err != nil {
        return nil, fmt.Errorf("failed to read from world state: %v", err)
    }
    if assetJSON == nil {
        return nil, fmt.Errorf("QoS %s does not exist", entityID)
    }
    var qos QoS
    err = json.Unmarshal(assetJSON, &qos)
    if err != nil {
        return nil, err
    }
    return &qos, nil
}

func (s *LocationBasedQoS) QueryAllAssets(ctx contractapi.TransactionContextInterface) ([]*QoS, error) {
    resultsIterator, err := ctx.GetStub().GetStateByRange("", "")
    if err != nil {
        return nil, err
    }
    defer resultsIterator.Close()
    var qoses []*QoS
    for resultsIterator.HasNext() {
        queryResponse, err := resultsIterator.Next()
        if err != nil {
            return nil, err
        }
        var qos QoS
        err = json.Unmarshal(queryResponse.Value, &qos)
        if err != nil {
            return nil, err
        }
        qoses = append(qoses, &qos)
    }
    return qoses, nil
}

func (s *LocationBasedQoS) ValidateQoSDistance(ctx contractapi.TransactionContextInterface, entityID, maxDistance string) (bool, error) {
    qos, err := s.QueryAsset(ctx, entityID)
    if err != nil {
        return false, err
    }
    distance, err := strconv.ParseFloat(qos.Distance, 64)
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
    chaincode, err := contractapi.NewChaincode(&LocationBasedQoS{})
    if err != nil {
        fmt.Printf("Error creating LocationBasedQoS chaincode: %v", err)
    }
    if err := chaincode.Start(); err != nil {
        fmt.Printf("Error starting LocationBasedQoS chaincode: %v", err)
    }
}
EOF
            ;;
        LocationBasedPriority)
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

type LocationBasedPriority struct {
    contractapi.Contract
}

type Priority struct {
    EntityID string `json:"entityID"`
    Priority string `json:"priority"`
    X string `json:"x"`
    Y string `json:"y"`
    Distance string `json:"distance"`
    Timestamp string `json:"timestamp"`
}

func (s *LocationBasedPriority) Init(ctx contractapi.TransactionContextInterface) error {
    return nil
}

func (s *LocationBasedPriority) AssignPriority(ctx contractapi.TransactionContextInterface, entityID, priority, x, y string) error {
    distance, err := calculateDistance(x, y, "0", "0")
    if err != nil {
        return err
    }
    priorityAlloc := Priority{
        EntityID: entityID,
        Priority: priority,
        X: x,
        Y: y,
        Distance: distance,
        Timestamp: time.Now().String(),
    }
    priorityJSON, err := json.Marshal(priorityAlloc)
    if err != nil {
        return err
    }
    return ctx.GetStub().PutState(entityID, priorityJSON)
}

func (s *LocationBasedPriority) QueryAsset(ctx contractapi.TransactionContextInterface, entityID string) (*Priority, error) {
    assetJSON, err := ctx.GetStub().GetState(entityID)
    if err != nil {
        return nil, fmt.Errorf("failed to read from world state: %v", err)
    }
    if assetJSON == nil {
        return nil, fmt.Errorf("priority %s does not exist", entityID)
    }
    var priority Priority
    err = json.Unmarshal(assetJSON, &priority)
    if err != nil {
        return nil, err
    }
    return &priority, nil
}

func (s *LocationBasedPriority) QueryAllAssets(ctx contractapi.TransactionContextInterface) ([]*Priority, error) {
    resultsIterator, err := ctx.GetStub().GetStateByRange("", "")
    if err != nil {
        return nil, err
    }
    defer resultsIterator.Close()
    var priorities []*Priority
    for resultsIterator.HasNext() {
        queryResponse, err := resultsIterator.Next()
        if err != nil {
            return nil, err
        }
        var priority Priority
        err = json.Unmarshal(queryResponse.Value, &priority)
        if err != nil {
            return nil, err
        }
        priorities = append(priorities, &priority)
    }
    return priorities, nil
}

func (s *LocationBasedPriority) ValidatePriorityDistance(ctx contractapi.TransactionContextInterface, entityID, maxDistance string) (bool, error) {
    priority, err := s.QueryAsset(ctx, entityID)
    if err != nil {
        return false, err
    }
    distance, err := strconv.ParseFloat(priority.Distance, 64)
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
    chaincode, err := contractapi.NewChaincode(&LocationBasedPriority{})
    if err != nil {
        fmt.Printf("Error creating LocationBasedPriority chaincode: %v", err)
    }
    if err := chaincode.Start(); err != nil {
        fmt.Printf("Error starting LocationBasedPriority chaincode: %v", err)
    }
}
EOF
            ;;
        LocationBasedStatus)
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

type LocationBasedStatus struct {
    contractapi.Contract
}

type Status struct {
    EntityID string `json:"entityID"`
    Status string `json:"status"`
    X string `json:"x"`
    Y string `json:"y"`
    Distance string `json:"distance"`
    Timestamp string `json:"timestamp"`
}

func (s *LocationBasedStatus) Init(ctx contractapi.TransactionContextInterface) error {
    return nil
}

func (s *LocationBasedStatus) UpdateStatus(ctx contractapi.TransactionContextInterface, entityID, status, x, y string) error {
    distance, err := calculateDistance(x, y, "0", "0")
    if err != nil {
        return err
    }
    statusRecord := Status{
        EntityID: entityID,
        Status: status,
        X: x,
        Y: y,
        Distance: distance,
        Timestamp: time.Now().String(),
    }
    statusJSON, err := json.Marshal(statusRecord)
    if err != nil {
        return err
    }
    return ctx.GetStub().PutState(entityID, statusJSON)
}

func (s *LocationBasedStatus) QueryAsset(ctx contractapi.TransactionContextInterface, entityID string) (*Status, error) {
    assetJSON, err := ctx.GetStub().GetState(entityID)
    if err != nil {
        return nil, fmt.Errorf("failed to read from world state: %v", err)
    }
    if assetJSON == nil {
        return nil, fmt.Errorf("status %s does not exist", entityID)
    }
    var status Status
    err = json.Unmarshal(assetJSON, &status)
    if err != nil {
        return nil, err
    }
    return &status, nil
}

func (s *LocationBasedStatus) QueryAllAssets(ctx contractapi.TransactionContextInterface) ([]*Status, error) {
    resultsIterator, err := ctx.GetStub().GetStateByRange("", "")
    if err != nil {
        return nil, err
    }
    defer resultsIterator.Close()
    var statuses []*Status
    for resultsIterator.HasNext() {
        queryResponse, err := resultsIterator.Next()
        if err != nil {
            return nil, err
        }
        var status Status
        err = json.Unmarshal(queryResponse.Value, &status)
        if err != nil {
            return nil, err
        }
        statuses = append(statuses, &status)
    }
    return statuses, nil
}

func (s *LocationBasedStatus) ValidateStatusDistance(ctx contractapi.TransactionContextInterface, entityID, maxDistance string) (bool, error) {
    status, err := s.QueryAsset(ctx, entityID)
    if err != nil {
        return false, err
    }
    distance, err := strconv.ParseFloat(status.Distance, 64)
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
    chaincode, err := contractapi.NewChaincode(&LocationBasedStatus{})
    if err != nil {
        fmt.Printf("Error creating LocationBasedStatus chaincode: %v", err)
    }
    if err := chaincode.Start(); err != nil {
        fmt.Printf("Error starting LocationBasedStatus chaincode: %v", err)
    }
}
EOF
            ;;
        LocationBasedFault)
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

type LocationBasedFault struct {
    contractapi.Contract
}

type Fault struct {
    EntityID string `json:"entityID"`
    FaultType string `json:"faultType"`
    X string `json:"x"`
    Y string `json:"y"`
    Distance string `json:"distance"`
    Timestamp string `json:"timestamp"`
}

func (s *LocationBasedFault) Init(ctx contractapi.TransactionContextInterface) error {
    return nil
}

func (s *LocationBasedFault) ReportFault(ctx contractapi.TransactionContextInterface, entityID, faultType, x, y string) error {
    distance, err := calculateDistance(x, y, "0", "0")
    if err != nil {
        return err
    }
    fault := Fault{
        EntityID: entityID,
        FaultType: faultType,
        X: x,
        Y: y,
        Distance: distance,
        Timestamp: time.Now().String(),
    }
    faultJSON, err := json.Marshal(fault)
    if err != nil {
        return err
    }
    return ctx.GetStub().PutState(entityID, faultJSON)
}

func (s *LocationBasedFault) QueryAsset(ctx contractapi.TransactionContextInterface, entityID string) (*Fault, error) {
    assetJSON, err := ctx.GetStub().GetState(entityID)
    if err != nil {
        return nil, fmt.Errorf("failed to read from world state: %v", err)
    }
    if assetJSON == nil {
        return nil, fmt.Errorf("fault %s does not exist", entityID)
    }
    var fault Fault
    err = json.Unmarshal(assetJSON, &fault)
    if err != nil {
        return nil, err
    }
    return &fault, nil
}

func (s *LocationBasedFault) QueryAllAssets(ctx contractapi.TransactionContextInterface) ([]*Fault, error) {
    resultsIterator, err := ctx.GetStub().GetStateByRange("", "")
    if err != nil {
        return nil, err
    }
    defer resultsIterator.Close()
    var faults []*Fault
    for resultsIterator.HasNext() {
        queryResponse, err := resultsIterator.Next()
        if err != nil {
            return nil, err
        }
        var fault Fault
        err = json.Unmarshal(queryResponse.Value, &fault)
        if err != nil {
            return nil, err
        }
        faults = append(faults, &fault)
    }
    return faults, nil
}

func (s *LocationBasedFault) ValidateFaultDistance(ctx contractapi.TransactionContextInterface, entityID, maxDistance string) (bool, error) {
    fault, err := s.QueryAsset(ctx, entityID)
    if err != nil {
        return false, err
    }
    distance, err := strconv.ParseFloat(fault.Distance, 64)
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
    chaincode, err := contractapi.NewChaincode(&LocationBasedFault{})
    if err != nil {
        fmt.Printf("Error creating LocationBasedFault chaincode: %v", err)
    }
    if err := chaincode.Start(); err != nil {
        fmt.Printf("Error starting LocationBasedFault chaincode: %v", err)
    }
}
EOF
            ;;
        LocationBasedTraffic)
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

type LocationBasedTraffic struct {
    contractapi.Contract
}

type Traffic struct {
    EntityID string `json:"entityID"`
    Traffic string `json:"traffic"`
    X string `json:"x"`
    Y string `json:"y"`
    Distance string `json:"distance"`
    Timestamp string `json:"timestamp"`
}

func (s *LocationBasedTraffic) Init(ctx contractapi.TransactionContextInterface) error {
    return nil
}

func (s *LocationBasedTraffic) RecordTraffic(ctx contractapi.TransactionContextInterface, entityID, traffic, x, y string) error {
    distance, err := calculateDistance(x, y, "0", "0")
    if err != nil {
        return err
    }
    trafficRecord := Traffic{
        EntityID: entityID,
        Traffic: traffic,
        X: x,
        Y: y,
        Distance: distance,
        Timestamp: time.Now().String(),
    }
    trafficJSON, err := json.Marshal(trafficRecord)
    if err != nil {
        return err
    }
    return ctx.GetStub().PutState(entityID, trafficJSON)
}

func (s *LocationBasedTraffic) QueryAsset(ctx contractapi.TransactionContextInterface, entityID string) (*Traffic, error) {
    assetJSON, err := ctx.GetStub().GetState(entityID)
    if err != nil {
        return nil, fmt.Errorf("failed to read from world state: %v", err)
    }
    if assetJSON == nil {
        return nil, fmt.Errorf("traffic %s does not exist", entityID)
    }
    var traffic Traffic
    err = json.Unmarshal(assetJSON, &traffic)
    if err != nil {
        return nil, err
    }
    return &traffic, nil
}

func (s *LocationBasedTraffic) QueryAllAssets(ctx contractapi.TransactionContextInterface) ([]*Traffic, error) {
    resultsIterator, err := ctx.GetStub().GetStateByRange("", "")
    if err != nil {
        return nil, err
    }
    defer resultsIterator.Close()
    var traffics []*Traffic
    for resultsIterator.HasNext() {
        queryResponse, err := resultsIterator.Next()
        if err != nil {
            return nil, err
        }
        var traffic Traffic
        err = json.Unmarshal(queryResponse.Value, &traffic)
        if err != nil {
            return nil, err
        }
        traffics = append(traffics, &traffic)
    }
    return traffics, nil
}

func (s *LocationBasedTraffic) ValidateTrafficDistance(ctx contractapi.TransactionContextInterface, entityID, maxDistance string) (bool, error) {
    traffic, err := s.QueryAsset(ctx, entityID)
    if err != nil {
        return false, err
    }
    distance, err := strconv.ParseFloat(traffic.Distance, 64)
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
    chaincode, err := contractapi.NewChaincode(&LocationBasedTraffic{})
    if err != nil {
        fmt.Printf("Error creating LocationBasedTraffic chaincode: %v", err)
    }
    if err := chaincode.Start(); err != nil {
        fmt.Printf("Error starting LocationBasedTraffic chaincode: %v", err)
    }
}
EOF
            ;;
        LocationBasedLatency)
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

type LocationBasedLatency struct {
    contractapi.Contract
}

type Latency struct {
    EntityID string `json:"entityID"`
    Latency string `json:"latency"`
    X string `json:"x"`
    Y string `json:"y"`
    Distance string `json:"distance"`
    Timestamp string `json:"timestamp"`
}

func (s *LocationBasedLatency) Init(ctx contractapi.TransactionContextInterface) error {
    return nil
}

func (s *LocationBasedLatency) RecordLatency(ctx contractapi.TransactionContextInterface, entityID, latency, x, y string) error {
    distance, err := calculateDistance(x, y, "0", "0")
    if err != nil {
        return err
    }
    latencyRecord := Latency{
        EntityID: entityID,
        Latency: latency,
        X: x,
        Y: y,
        Distance: distance,
        Timestamp: time.Now().String(),
    }
    latencyJSON, err := json.Marshal(latencyRecord)
    if err != nil {
        return err
    }
    return ctx.GetStub().PutState(entityID, latencyJSON)
}

func (s *LocationBasedLatency) QueryAsset(ctx contractapi.TransactionContextInterface, entityID string) (*Latency, error) {
    assetJSON, err := ctx.GetStub().GetState(entityID)
    if err != nil {
        return nil, fmt.Errorf("failed to read from world state: %v", err)
    }
    if assetJSON == nil {
        return nil, fmt.Errorf("latency %s does not exist", entityID)
    }
    var latency Latency
    err = json.Unmarshal(assetJSON, &latency)
    if err != nil {
        return nil, err
    }
    return &latency, nil
}

func (s *LocationBasedLatency) QueryAllAssets(ctx contractapi.TransactionContextInterface) ([]*Latency, error) {
    resultsIterator, err := ctx.GetStub().GetStateByRange("", "")
    if err != nil {
        return nil, err
    }
    defer resultsIterator.Close()
    var latencies []*Latency
    for resultsIterator.HasNext() {
        queryResponse, err := resultsIterator.Next()
        if err != nil {
            return nil, err
        }
        var latency Latency
        err = json.Unmarshal(queryResponse.Value, &latency)
        if err != nil {
            return nil, err
        }
        latencies = append(latencies, &latency)
    }
    return latencies, nil
}

func (s *LocationBasedLatency) ValidateLatencyDistance(ctx contractapi.TransactionContextInterface, entityID, maxDistance string) (bool, error) {
    latency, err := s.QueryAsset(ctx, entityID)
    if err != nil {
        return false, err
    }
    distance, err := strconv.ParseFloat(latency.Distance, 64)
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
    chaincode, err := contractapi.NewChaincode(&LocationBasedLatency{})
    if err != nil {
        fmt.Printf("Error creating LocationBasedLatency chaincode: %v", err)
    }
    if err := chaincode.Start(); err != nil {
        fmt.Printf("Error starting LocationBasedLatency chaincode: %v", err)
    }
}
EOF
            ;;
    esac
done

echo "Generated chaincode for ${#contracts[@]} contracts in part 1:"
for contract in "${contracts[@]}"; do
    if [ -f "chaincode/$contract/chaincode.go" ]; then
        echo " - $contract: OK"
    else
        echo " - $contract: Failed"
    fi
done
