#!/bin/bash

contracts=(
    "LocationBasedAssignment" "LocationBasedConnection" "LocationBasedBandwidth" "LocationBasedQoS"
    "LocationBasedPriority" "LocationBasedStatus" "LocationBasedFault" "LocationBasedTraffic"
    "LocationBasedLatency"
)

for contract in "${contracts[@]}"; do
    mkdir -p chaincode/$contract
    case $contract in
        LocationBasedAssignment)
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

type LocationBasedAssignment struct {
    contractapi.Contract
}

type Assignment struct {
    EntityID   string `json:"entityID"`
    AntennaID  string `json:"antennaID"`
    X          string `json:"x"`
    Y          string `json:"y"`
    Distance   string `json:"distance"`
    Timestamp  string `json:"timestamp"`
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
        EntityID:  entityID,
        AntennaID: antennaID,
        X:         x,
        Y:         y,
        Distance:  distance,
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
        return nil, err
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

type LocationBasedConnection struct {
    contractapi.Contract
}

type Connection struct {
    EntityID   string `json:"entityID"`
    AntennaID  string `json:"antennaID"`
    X          string `json:"x"`
    Y          string `json:"y"`
    Distance   string `json:"distance"`
    Status     string `json:"status"`
    Timestamp  string `json:"timestamp"`
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
        EntityID:  entityID,
        AntennaID: antennaID,
        X:         x,
        Y:         y,
        Distance:  distance,
        Status:    "Connected",
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
        return nil, err
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

type LocationBasedBandwidth struct {
    contractapi.Contract
}

type BandwidthAllocation struct {
    EntityID   string `json:"entityID"`
    AntennaID  string `json:"antennaID"`
    Bandwidth  string `json:"bandwidth"`
    X          string `json:"x"`
    Y          string `json:"y"`
    Distance   string `json:"distance"`
    Timestamp  string `json:"timestamp"`
}

func (s *LocationBasedBandwidth) Init(ctx contractapi.TransactionContextInterface) error {
    return nil
}

func (s *LocationBasedBandwidth) AllocateBandwidth(ctx contractapi.TransactionContextInterface, entityID, antennaID, bandwidth, x, y string) error {
    antenna, err := s.QueryAsset(ctx, antennaID)
    if err != nil {
        return fmt.Errorf("failed to query antenna: %v", err)
    }
    distance, err := calculateDistance(x, y, antenna.X, antenna.Y)
    if err != nil {
        return err
    }
    allocation := BandwidthAllocation{
        EntityID:  entityID,
        AntennaID: antennaID,
        Bandwidth: bandwidth,
        X:         x,
        Y:         y,
        Distance:  distance,
        Timestamp: time.Now().String(),
    }
    allocationJSON, err := json.Marshal(allocation)
    if err != nil {
        return err
    }
    return ctx.GetStub().PutState(entityID, allocationJSON)
}

func (s *LocationBasedBandwidth) UpdateBandwidth(ctx contractapi.TransactionContextInterface, entityID, newBandwidth string) error {
    allocation, err := s.QueryAsset(ctx, entityID)
    if err != nil {
        return err
    }
    allocation.Bandwidth = newBandwidth
    allocation.Timestamp = time.Now().String()
    allocationJSON, err := json.Marshal(allocation)
    if err != nil {
        return err
    }
    return ctx.GetStub().PutState(entityID, allocationJSON)
}

func (s *LocationBasedBandwidth) QueryAsset(ctx contractapi.TransactionContextInterface, entityID string) (*BandwidthAllocation, error) {
    assetJSON, err := ctx.GetStub().GetState(entityID)
    if err != nil {
        return nil, err
    }
    if assetJSON == nil {
        return nil, fmt.Errorf("bandwidth allocation %s does not exist", entityID)
    }
    var allocation BandwidthAllocation
    err = json.Unmarshal(assetJSON, &allocation)
    if err != nil {
        return nil, err
    }
    return &allocation, nil
}

func (s *LocationBasedBandwidth) QueryAllAssets(ctx contractapi.TransactionContextInterface) ([]*BandwidthAllocation, error) {
    resultsIterator, err := ctx.GetStub().GetStateByRange("", "")
    if err != nil {
        return nil, err
    }
    defer resultsIterator.Close()

    var allocations []*BandwidthAllocation
    for resultsIterator.HasNext() {
        queryResponse, err := resultsIterator.Next()
        if err != nil {
            return nil, err
        }
        var allocation BandwidthAllocation
        err = json.Unmarshal(queryResponse.Value, &allocation)
        if err != nil {
            return nil, err
        }
        allocations = append(allocations, &allocation)
    }
    return allocations, nil
}

func (s *LocationBasedBandwidth) ValidateBandwidthDistance(ctx contractapi.TransactionContextInterface, entityID, maxDistance string) (bool, error) {
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

type LocationBasedQoS struct {
    contractapi.Contract
}

type QoSAllocation struct {
    EntityID   string `json:"entityID"`
    AntennaID  string `json:"antennaID"`
    QoSLevel   string `json:"qosLevel"`
    X          string `json:"x"`
    Y          string `json:"y"`
    Distance   string `json:"distance"`
    Timestamp  string `json:"timestamp"`
}

func (s *LocationBasedQoS) Init(ctx contractapi.TransactionContextInterface) error {
    return nil
}

func (s *LocationBasedQoS) AllocateQoS(ctx contractapi.TransactionContextInterface, entityID, antennaID, qosLevel, x, y string) error {
    antenna, err := s.QueryAsset(ctx, antennaID)
    if err != nil {
        return fmt.Errorf("failed to query antenna: %v", err)
    }
    distance, err := calculateDistance(x, y, antenna.X, antenna.Y)
    if err != nil {
        return err
    }
    allocation := QoSAllocation{
        EntityID:  entityID,
        AntennaID: antennaID,
        QoSLevel:  qosLevel,
        X:         x,
        Y:         y,
        Distance:  distance,
        Timestamp: time.Now().String(),
    }
    allocationJSON, err := json.Marshal(allocation)
    if err != nil {
        return err
    }
    return ctx.GetStub().PutState(entityID, allocationJSON)
}

func (s *LocationBasedQoS) UpdateQoS(ctx contractapi.TransactionContextInterface, entityID, newQoSLevel string) error {
    allocation, err := s.QueryAsset(ctx, entityID)
    if err != nil {
        return err
    }
    allocation.QoSLevel = newQoSLevel
    allocation.Timestamp = time.Now().String()
    allocationJSON, err := json.Marshal(allocation)
    if err != nil {
        return err
    }
    return ctx.GetStub().PutState(entityID, allocationJSON)
}

func (s *LocationBasedQoS) QueryAsset(ctx contractapi.TransactionContextInterface, entityID string) (*QoSAllocation, error) {
    assetJSON, err := ctx.GetStub().GetState(entityID)
    if err != nil {
        return nil, err
    }
    if assetJSON == nil {
        return nil, fmt.Errorf("QoS allocation %s does not exist", entityID)
    }
    var allocation QoSAllocation
    err = json.Unmarshal(assetJSON, &allocation)
    if err != nil {
        return nil, err
    }
    return &allocation, nil
}

func (s *LocationBasedQoS) QueryAllAssets(ctx contractapi.TransactionContextInterface) ([]*QoSAllocation, error) {
    resultsIterator, err := ctx.GetStub().GetStateByRange("", "")
    if err != nil {
        return nil, err
    }
    defer resultsIterator.Close()

    var allocations []*QoSAllocation
    for resultsIterator.HasNext() {
        queryResponse, err := resultsIterator.Next()
        if err != nil {
            return nil, err
        }
        var allocation QoSAllocation
        err = json.Unmarshal(queryResponse.Value, &allocation)
        if err != nil {
            return nil, err
        }
        allocations = append(allocations, &allocation)
    }
    return allocations, nil
}

func (s *LocationBasedQoS) ValidateQoSDistance(ctx contractapi.TransactionContextInterface, entityID, maxDistance string) (bool, error) {
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

type LocationBasedPriority struct {
    contractapi.Contract
}

type PriorityAllocation struct {
    EntityID   string `json:"entityID"`
    Priority   string `json:"priority"`
    X          string `json:"x"`
    Y          string `json:"y"`
    Distance   string `json:"distance"`
    Timestamp  string `json:"timestamp"`
}

func (s *LocationBasedPriority) Init(ctx contractapi.TransactionContextInterface) error {
    return nil
}

func (s *LocationBasedPriority) AssignPriority(ctx contractapi.TransactionContextInterface, entityID, priority, x, y string) error {
    distance, err := calculateDistance(x, y, "0", "0")
    if err != nil {
        return err
    }
    allocation := PriorityAllocation{
        EntityID:  entityID,
        Priority:  priority,
        X:         x,
        Y:         y,
        Distance:  distance,
        Timestamp: time.Now().String(),
    }
    allocationJSON, err := json.Marshal(allocation)
    if err != nil {
        return err
    }
    return ctx.GetStub().PutState(entityID, allocationJSON)
}

func (s *LocationBasedPriority) UpdatePriority(ctx contractapi.TransactionContextInterface, entityID, newPriority string) error {
    allocation, err := s.QueryAsset(ctx, entityID)
    if err != nil {
        return err
    }
    allocation.Priority = newPriority
    allocation.Timestamp = time.Now().String()
    allocationJSON, err := json.Marshal(allocation)
    if err != nil {
        return err
    }
    return ctx.GetStub().PutState(entityID, allocationJSON)
}

func (s *LocationBasedPriority) QueryAsset(ctx contractapi.TransactionContextInterface, entityID string) (*PriorityAllocation, error) {
    assetJSON, err := ctx.GetStub().GetState(entityID)
    if err != nil {
        return nil, err
    }
    if assetJSON == nil {
        return nil, fmt.Errorf("priority allocation %s does not exist", entityID)
    }
    var allocation PriorityAllocation
    err = json.Unmarshal(assetJSON, &allocation)
    if err != nil {
        return nil, err
    }
    return &allocation, nil
}

func (s *LocationBasedPriority) QueryAllAssets(ctx contractapi.TransactionContextInterface) ([]*PriorityAllocation, error) {
    resultsIterator, err := ctx.GetStub().GetStateByRange("", "")
    if err != nil {
        return nil, err
    }
    defer resultsIterator.Close()

    var allocations []*PriorityAllocation
    for resultsIterator.HasNext() {
        queryResponse, err := resultsIterator.Next()
        if err != nil {
            return nil, err
        }
        var allocation PriorityAllocation
        err = json.Unmarshal(queryResponse.Value, &allocation)
        if err != nil {
            return nil, err
        }
        allocations = append(allocations, &allocation)
    }
    return allocations, nil
}

func (s *LocationBasedPriority) ValidatePriorityDistance(ctx contractapi.TransactionContextInterface, entityID, maxDistance string) (bool, error) {
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

type LocationBasedStatus struct {
    contractapi.Contract
}

type StatusRecord struct {
    EntityID   string `json:"entityID"`
    Status     string `json:"status"`
    X          string `json:"x"`
    Y          string `json:"y"`
    Distance   string `json:"distance"`
    Timestamp  string `json:"timestamp"`
}

func (s *LocationBasedStatus) Init(ctx contractapi.TransactionContextInterface) error {
    return nil
}

func (s *LocationBasedStatus) UpdateStatus(ctx contractapi.TransactionContextInterface, entityID, status, x, y string) error {
    distance, err := calculateDistance(x, y, "0", "0")
    if err != nil {
        return err
    }
    record := StatusRecord{
        EntityID:  entityID,
        Status:    status,
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

func (s *LocationBasedStatus) QueryAsset(ctx contractapi.TransactionContextInterface, entityID string) (*StatusRecord, error) {
    assetJSON, err := ctx.GetStub().GetState(entityID)
    if err != nil {
        return nil, err
    }
    if assetJSON == nil {
        return nil, fmt.Errorf("status record %s does not exist", entityID)
    }
    var record StatusRecord
    err = json.Unmarshal(assetJSON, &record)
    if err != nil {
        return nil, err
    }
    return &record, nil
}

func (s *LocationBasedStatus) QueryAllAssets(ctx contractapi.TransactionContextInterface) ([]*StatusRecord, error) {
    resultsIterator, err := ctx.GetStub().GetStateByRange("", "")
    if err != nil {
        return nil, err
    }
    defer resultsIterator.Close()

    var records []*StatusRecord
    for resultsIterator.HasNext() {
        queryResponse, err := resultsIterator.Next()
        if err != nil {
            return nil, err
        }
        var record StatusRecord
        err = json.Unmarshal(queryResponse.Value, &record)
        if err != nil {
            return nil, err
        }
        records = append(records, &record)
    }
    return records, nil
}

func (s *LocationBasedStatus) ValidateStatusDistance(ctx contractapi.TransactionContextInterface, entityID, maxDistance string) (bool, error) {
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

type LocationBasedFault struct {
    contractapi.Contract
}

type FaultRecord struct {
    EntityID   string `json:"entityID"`
    FaultType  string `json:"faultType"`
    X          string `json:"x"`
    Y          string `json:"y"`
    Distance   string `json:"distance"`
    Timestamp  string `json:"timestamp"`
}

func (s *LocationBasedFault) Init(ctx contractapi.TransactionContextInterface) error {
    return nil
}

func (s *LocationBasedFault) ReportFault(ctx contractapi.TransactionContextInterface, entityID, faultType, x, y string) error {
    distance, err := calculateDistance(x, y, "0", "0")
    if err != nil {
        return err
    }
    record := FaultRecord{
        EntityID:  entityID,
        FaultType: faultType,
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

func (s *LocationBasedFault) QueryAsset(ctx contractapi.TransactionContextInterface, entityID string) (*FaultRecord, error) {
    assetJSON, err := ctx.GetStub().GetState(entityID)
    if err != nil {
        return nil, err
    }
    if assetJSON == nil {
        return nil, fmt.Errorf("fault record %s does not exist", entityID)
    }
    var record FaultRecord
    err = json.Unmarshal(assetJSON, &record)
    if err != nil {
        return nil, err
    }
    return &record, nil
}

func (s *LocationBasedFault) QueryAllAssets(ctx contractapi.TransactionContextInterface) ([]*FaultRecord, error) {
    resultsIterator, err := ctx.GetStub().GetStateByRange("", "")
    if err != nil {
        return nil, err
    }
    defer resultsIterator.Close()

    var records []*FaultRecord
    for resultsIterator.HasNext() {
        queryResponse, err := resultsIterator.Next()
        if err != nil {
            return nil, err
        }
        var record FaultRecord
        err = json.Unmarshal(queryResponse.Value, &record)
        if err != nil {
            return nil, err
        }
        records = append(records, &record)
    }
    return records, nil
}

func (s *LocationBasedFault) ValidateFaultDistance(ctx contractapi.TransactionContextInterface, entityID, maxDistance string) (bool, error) {
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

type LocationBasedTraffic struct {
    contractapi.Contract
}

type TrafficRecord struct {
    EntityID   string `json:"entityID"`
    Traffic    string `json:"traffic"`
    X          string `json:"x"`
    Y          string `json:"y"`
    Distance   string `json:"distance"`
    Timestamp  string `json:"timestamp"`
}

func (s *LocationBasedTraffic) Init(ctx contractapi.TransactionContextInterface) error {
    return nil
}

func (s *LocationBasedTraffic) RecordTraffic(ctx contractapi.TransactionContextInterface, entityID, traffic, x, y string) error {
    distance, err := calculateDistance(x, y, "0", "0")
    if err != nil {
        return err
    }
    record := TrafficRecord{
        EntityID:  entityID,
        Traffic:   traffic,
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

func (s *LocationBasedTraffic) QueryAsset(ctx contractapi.TransactionContextInterface, entityID string) (*TrafficRecord, error) {
    assetJSON, err := ctx.GetStub().GetState(entityID)
    if err != nil {
        return nil, err
    }
    if assetJSON == nil {
        return nil, fmt.Errorf("traffic record %s does not exist", entityID)
    }
    var record TrafficRecord
    err = json.Unmarshal(assetJSON, &record)
    if err != nil {
        return nil, err
    }
    return &record, nil
}

func (s *LocationBasedTraffic) QueryAllAssets(ctx contractapi.TransactionContextInterface) ([]*TrafficRecord, error) {
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

func (s *LocationBasedTraffic) ValidateTrafficDistance(ctx contractapi.TransactionContextInterface, entityID, maxDistance string) (bool, error) {
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

type LocationBasedLatency struct {
    contractapi.Contract
}

type LatencyRecord struct {
    EntityID   string `json:"entityID"`
    Latency    string `json:"latency"`
    X          string `json:"x"`
    Y          string `json:"y"`
    Distance   string `json:"distance"`
    Timestamp  string `json:"timestamp"`
}

func (s *LocationBasedLatency) Init(ctx contractapi.TransactionContextInterface) error {
    return nil
}

func (s *LocationBasedLatency) RecordLatency(ctx contractapi.TransactionContextInterface, entityID, latency, x, y string) error {
    distance, err := calculateDistance(x, y, "0", "0")
    if err != nil {
        return err
    }
    record := LatencyRecord{
        EntityID:  entityID,
        Latency:   latency,
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

func (s *LocationBasedLatency) QueryAsset(ctx contractapi.TransactionContextInterface, entityID string) (*LatencyRecord, error) {
    assetJSON, err := ctx.GetStub().GetState(entityID)
    if err != nil {
        return nil, err
    }
    if assetJSON == nil {
        return nil, fmt.Errorf("latency record %s does not exist", entityID)
    }
    var record LatencyRecord
    err = json.Unmarshal(assetJSON, &record)
    if err != nil {
        return nil, err
    }
    return &record, nil
}

func (s *LocationBasedLatency) QueryAllAssets(ctx contractapi.TransactionContextInterface) ([]*LatencyRecord, error) {
    resultsIterator, err := ctx.GetStub().GetStateByRange("", "")
    if err != nil {
        return nil, err
    }
    defer resultsIterator.Close()

    var records []*LatencyRecord
    for resultsIterator.HasNext() {
        queryResponse, err := resultsIterator.Next()
        if err != nil {
            return nil, err
        }
        var record LatencyRecord
        err = json.Unmarshal(queryResponse.Value, &record)
        if err != nil {
            return nil, err
        }
        records = append(records, &record)
    }
    return records, nil
}

func (s *LocationBasedLatency) ValidateLatencyDistance(ctx contractapi.TransactionContextInterface, entityID, maxDistance string) (bool, error) {
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
