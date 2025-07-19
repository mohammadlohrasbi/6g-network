#!/bin/bash

contracts=(
    "LocationBasedIoTBandwidth" "LocationBasedIoTStatus" "LocationBasedIoTFault" "LocationBasedIoTSession"
    "LocationBasedIoTAuthentication" "LocationBasedIoTRegistration" "LocationBasedIoTRevocation" "LocationBasedIoTResource"
    "LocationBasedUserActivity"
)

for contract in "${contracts[@]}"; do
    mkdir -p chaincode/$contract
    case $contract in
        LocationBasedIoTBandwidth)
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

type LocationBasedIoTBandwidth struct {
    contractapi.Contract
}

type IoTBandwidthAllocation struct {
    DeviceID   string `json:"deviceID"`
    AntennaID  string `json:"antennaID"`
    Bandwidth  string `json:"bandwidth"`
    X          string `json:"x"`
    Y          string `json:"y"`
    Distance   string `json:"distance"`
    Timestamp  string `json:"timestamp"`
}

func (s *LocationBasedIoTBandwidth) Init(ctx contractapi.TransactionContextInterface) error {
    return nil
}

func (s *LocationBasedIoTBandwidth) AllocateIoTBandwidth(ctx contractapi.TransactionContextInterface, deviceID, antennaID, bandwidth, x, y string) error {
    antenna, err := s.QueryAsset(ctx, antennaID)
    if err != nil {
        return fmt.Errorf("failed to query antenna: %v", err)
    }
    distance, err := calculateDistance(x, y, antenna.X, antenna.Y)
    if err != nil {
        return err
    }
    allocation := IoTBandwidthAllocation{
        DeviceID:  deviceID,
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
    return ctx.GetStub().PutState(deviceID, allocationJSON)
}

func (s *LocationBasedIoTBandwidth) UpdateIoTBandwidth(ctx contractapi.TransactionContextInterface, deviceID, newBandwidth string) error {
    allocation, err := s.QueryAsset(ctx, deviceID)
    if err != nil {
        return err
    }
    allocation.Bandwidth = newBandwidth
    allocation.Timestamp = time.Now().String()
    allocationJSON, err := json.Marshal(allocation)
    if err != nil {
        return err
    }
    return ctx.GetStub().PutState(deviceID, allocationJSON)
}

func (s *LocationBasedIoTBandwidth) QueryAsset(ctx contractapi.TransactionContextInterface, deviceID string) (*IoTBandwidthAllocation, error) {
    assetJSON, err := ctx.GetStub().GetState(deviceID)
    if err != nil {
        return nil, err
    }
    if assetJSON == nil {
        return nil, fmt.Errorf("IoT bandwidth allocation %s does not exist", deviceID)
    }
    var allocation IoTBandwidthAllocation
    err = json.Unmarshal(assetJSON, &allocation)
    if err != nil {
        return nil, err
    }
    return &allocation, nil
}

func (s *LocationBasedIoTBandwidth) QueryAllAssets(ctx contractapi.TransactionContextInterface) ([]*IoTBandwidthAllocation, error) {
    resultsIterator, err := ctx.GetStub().GetStateByRange("", "")
    if err != nil {
        return nil, err
    }
    defer resultsIterator.Close()

    var allocations []*IoTBandwidthAllocation
    for resultsIterator.HasNext() {
        queryResponse, err := resultsIterator.Next()
        if err != nil {
            return nil, err
        }
        var allocation IoTBandwidthAllocation
        err = json.Unmarshal(queryResponse.Value, &allocation)
        if err != nil {
            return nil, err
        }
        allocations = append(allocations, &allocation)
    }
    return allocations, nil
}

func (s *LocationBasedIoTBandwidth) ValidateIoTBandwidthDistance(ctx contractapi.TransactionContextInterface, deviceID, maxDistance string) (bool, error) {
    allocation, err := s.QueryAsset(ctx, deviceID)
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
    chaincode, err := contractapi.NewChaincode(&LocationBasedIoTBandwidth{})
    if err != nil {
        fmt.Printf("Error creating LocationBasedIoTBandwidth chaincode: %v", err)
    }
    if err := chaincode.Start(); err != nil {
        fmt.Printf("Error starting LocationBasedIoTBandwidth chaincode: %v", err)
    }
}
EOF
            ;;
        LocationBasedIoTStatus)
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

type LocationBasedIoTStatus struct {
    contractapi.Contract
}

type IoTStatusRecord struct {
    DeviceID   string `json:"deviceID"`
    Status     string `json:"status"`
    X          string `json:"x"`
    Y          string `json:"y"`
    Distance   string `json:"distance"`
    Timestamp  string `json:"timestamp"`
}

func (s *LocationBasedIoTStatus) Init(ctx contractapi.TransactionContextInterface) error {
    return nil
}

func (s *LocationBasedIoTStatus) UpdateIoTStatus(ctx contractapi.TransactionContextInterface, deviceID, status, x, y string) error {
    distance, err := calculateDistance(x, y, "0", "0")
    if err != nil {
        return err
    }
    record := IoTStatusRecord{
        DeviceID:  deviceID,
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
    return ctx.GetStub().PutState(deviceID, recordJSON)
}

func (s *LocationBasedIoTStatus) QueryAsset(ctx contractapi.TransactionContextInterface, deviceID string) (*IoTStatusRecord, error) {
    assetJSON, err := ctx.GetStub().GetState(deviceID)
    if err != nil {
        return nil, err
    }
    if assetJSON == nil {
        return nil, fmt.Errorf("IoT status record %s does not exist", deviceID)
    }
    var record IoTStatusRecord
    err = json.Unmarshal(assetJSON, &record)
    if err != nil {
        return nil, err
    }
    return &record, nil
}

func (s *LocationBasedIoTStatus) QueryAllAssets(ctx contractapi.TransactionContextInterface) ([]*IoTStatusRecord, error) {
    resultsIterator, err := ctx.GetStub().GetStateByRange("", "")
    if err != nil {
        return nil, err
    }
    defer resultsIterator.Close()

    var records []*IoTStatusRecord
    for resultsIterator.HasNext() {
        queryResponse, err := resultsIterator.Next()
        if err != nil {
            return nil, err
        }
        var record IoTStatusRecord
        err = json.Unmarshal(queryResponse.Value, &record)
        if err != nil {
            return nil, err
        }
        records = append(records, &record)
    }
    return records, nil
}

func (s *LocationBasedIoTStatus) ValidateIoTStatusDistance(ctx contractapi.TransactionContextInterface, deviceID, maxDistance string) (bool, error) {
    record, err := s.QueryAsset(ctx, deviceID)
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
    chaincode, err := contractapi.NewChaincode(&LocationBasedIoTStatus{})
    if err != nil {
        fmt.Printf("Error creating LocationBasedIoTStatus chaincode: %v", err)
    }
    if err := chaincode.Start(); err != nil {
        fmt.Printf("Error starting LocationBasedIoTStatus chaincode: %v", err)
    }
}
EOF
            ;;
        LocationBasedIoTFault)
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

type LocationBasedIoTFault struct {
    contractapi.Contract
}

type IoTFaultRecord struct {
    DeviceID   string `json:"deviceID"`
    FaultType  string `json:"faultType"`
    X          string `json:"x"`
    Y          string `json:"y"`
    Distance   string `json:"distance"`
    Timestamp  string `json:"timestamp"`
}

func (s *LocationBasedIoTFault) Init(ctx contractapi.TransactionContextInterface) error {
    return nil
}

func (s *LocationBasedIoTFault) ReportIoTFault(ctx contractapi.TransactionContextInterface, deviceID, faultType, x, y string) error {
    distance, err := calculateDistance(x, y, "0", "0")
    if err != nil {
        return err
    }
    record := IoTFaultRecord{
        DeviceID:  deviceID,
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
    return ctx.GetStub().PutState(deviceID, recordJSON)
}

func (s *LocationBasedIoTFault) QueryAsset(ctx contractapi.TransactionContextInterface, deviceID string) (*IoTFaultRecord, error) {
    assetJSON, err := ctx.GetStub().GetState(deviceID)
    if err != nil {
        return nil, err
    }
    if assetJSON == nil {
        return nil, fmt.Errorf("IoT fault record %s does not exist", deviceID)
    }
    var record IoTFaultRecord
    err = json.Unmarshal(assetJSON, &record)
    if err != nil {
        return nil, err
    }
    return &record, nil
}

func (s *LocationBasedIoTFault) QueryAllAssets(ctx contractapi.TransactionContextInterface) ([]*IoTFaultRecord, error) {
    resultsIterator, err := ctx.GetStub().GetStateByRange("", "")
    if err != nil {
        return nil, err
    }
    defer resultsIterator.Close()

    var records []*IoTFaultRecord
    for resultsIterator.HasNext() {
        queryResponse, err := resultsIterator.Next()
        if err != nil {
            return nil, err
        }
        var record IoTFaultRecord
        err = json.Unmarshal(queryResponse.Value, &record)
        if err != nil {
            return nil, err
        }
        records = append(records, &record)
    }
    return records, nil
}

func (s *LocationBasedIoTFault) ValidateIoTFaultDistance(ctx contractapi.TransactionContextInterface, deviceID, maxDistance string) (bool, error) {
    record, err := s.QueryAsset(ctx, deviceID)
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
    chaincode, err := contractapi.NewChaincode(&LocationBasedIoTFault{})
    if err != nil {
        fmt.Printf("Error creating LocationBasedIoTFault chaincode: %v", err)
    }
    if err := chaincode.Start(); err != nil {
        fmt.Printf("Error starting LocationBasedIoTFault chaincode: %v", err)
    }
}
EOF
            ;;
        LocationBasedIoTSession)
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

type LocationBasedIoTSession struct {
    contractapi.Contract
}

type IoTSessionRecord struct {
    DeviceID   string `json:"deviceID"`
    SessionID  string `json:"sessionID"`
    X          string `json:"x"`
    Y          string `json:"y"`
    Distance   string `json:"distance"`
    Status     string `json:"status"`
    Timestamp  string `json:"timestamp"`
}

func (s *LocationBasedIoTSession) Init(ctx contractapi.TransactionContextInterface) error {
    return nil
}

func (s *LocationBasedIoTSession) StartIoTSession(ctx contractapi.TransactionContextInterface, deviceID, sessionID, x, y string) error {
    distance, err := calculateDistance(x, y, "0", "0")
    if err != nil {
        return err
    }
    record := IoTSessionRecord{
        DeviceID:  deviceID,
        SessionID: sessionID,
        X:         x,
        Y:         y,
        Distance:  distance,
        Status:    "Active",
        Timestamp: time.Now().String(),
    }
    recordJSON, err := json.Marshal(record)
    if err != nil {
        return err
    }
    return ctx.GetStub().PutState(deviceID, recordJSON)
}

func (s *LocationBasedIoTSession) EndIoTSession(ctx contractapi.TransactionContextInterface, deviceID string) error {
    record, err := s.QueryAsset(ctx, deviceID)
    if err != nil {
        return err
    }
    record.Status = "Ended"
    record.Timestamp = time.Now().String()
    recordJSON, err := json.Marshal(record)
    if err != nil {
        return err
    }
    return ctx.GetStub().PutState(deviceID, recordJSON)
}

func (s *LocationBasedIoTSession) QueryAsset(ctx contractapi.TransactionContextInterface, deviceID string) (*IoTSessionRecord, error) {
    assetJSON, err := ctx.GetStub().GetState(deviceID)
    if err != nil {
        return nil, err
    }
    if assetJSON == nil {
        return nil, fmt.Errorf("IoT session record %s does not exist", deviceID)
    }
    var record IoTSessionRecord
    err = json.Unmarshal(assetJSON, &record)
    if err != nil {
        return nil, err
    }
    return &record, nil
}

func (s *LocationBasedIoTSession) QueryAllAssets(ctx contractapi.TransactionContextInterface) ([]*IoTSessionRecord, error) {
    resultsIterator, err := ctx.GetStub().GetStateByRange("", "")
    if err != nil {
        return nil, err
    }
    defer resultsIterator.Close()

    var records []*IoTSessionRecord
    for resultsIterator.HasNext() {
        queryResponse, err := resultsIterator.Next()
        if err != nil {
            return nil, err
        }
        var record IoTSessionRecord
        err = json.Unmarshal(queryResponse.Value, &record)
        if err != nil {
            return nil, err
        }
        records = append(records, &record)
    }
    return records, nil
}

func (s *LocationBasedIoTSession) ValidateIoTSessionDistance(ctx contractapi.TransactionContextInterface, deviceID, maxDistance string) (bool, error) {
    record, err := s.QueryAsset(ctx, deviceID)
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
    chaincode, err := contractapi.NewChaincode(&LocationBasedIoTSession{})
    if err != nil {
        fmt.Printf("Error creating LocationBasedIoTSession chaincode: %v", err)
    }
    if err := chaincode.Start(); err != nil {
        fmt.Printf("Error starting LocationBasedIoTSession chaincode: %v", err)
    }
}
EOF
            ;;
        LocationBasedIoTAuthentication)
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

type LocationBasedIoTAuthentication struct {
    contractapi.Contract
}

type IoTAuthRecord struct {
    DeviceID   string `json:"deviceID"`
    Token      string `json:"token"`
    X          string `json:"x"`
    Y          string `json:"y"`
    Distance   string `json:"distance"`
    Timestamp  string `json:"timestamp"`
}

func (s *LocationBasedIoTAuthentication) Init(ctx contractapi.TransactionContextInterface) error {
    return nil
}

func (s *LocationBasedIoTAuthentication) AuthenticateIoTDevice(ctx contractapi.TransactionContextInterface, deviceID, token, x, y string) error {
    distance, err := calculateDistance(x, y, "0", "0")
    if err != nil {
        return err
    }
    record := IoTAuthRecord{
        DeviceID:  deviceID,
        Token:     token,
        X:         x,
        Y:         y,
        Distance:  distance,
        Timestamp: time.Now().String(),
    }
    recordJSON, err := json.Marshal(record)
    if err != nil {
        return err
    }
    return ctx.GetStub().PutState(deviceID, recordJSON)
}

func (s *LocationBasedIoTAuthentication) QueryAsset(ctx contractapi.TransactionContextInterface, deviceID string) (*IoTAuthRecord, error) {
    assetJSON, err := ctx.GetStub().GetState(deviceID)
    if err != nil {
        return nil, err
    }
    if assetJSON == nil {
        return nil, fmt.Errorf("IoT auth record %s does not exist", deviceID)
    }
    var record IoTAuthRecord
    err = json.Unmarshal(assetJSON, &record)
    if err != nil {
        return nil, err
    }
    return &record, nil
}

func (s *LocationBasedIoTAuthentication) QueryAllAssets(ctx contractapi.TransactionContextInterface) ([]*IoTAuthRecord, error) {
    resultsIterator, err := ctx.GetStub().GetStateByRange("", "")
    if err != nil {
        return nil, err
    }
    defer resultsIterator.Close()

    var records []*IoTAuthRecord
    for resultsIterator.HasNext() {
        queryResponse, err := resultsIterator.Next()
        if err != nil {
            return nil, err
        }
        var record IoTAuthRecord
        err = json.Unmarshal(queryResponse.Value, &record)
        if err != nil {
            return nil, err
        }
        records = append(records, &record)
    }
    return records, nil
}

func (s *LocationBasedIoTAuthentication) ValidateIoTAuthDistance(ctx contractapi.TransactionContextInterface, deviceID, maxDistance string) (bool, error) {
    record, err := s.QueryAsset(ctx, deviceID)
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

func (s *LocationBasedIoTAuthentication) ValidateIoTToken(ctx contractapi.TransactionContextInterface, deviceID, token string) (bool, error) {
    record, err := s.QueryAsset(ctx, deviceID)
    if err != nil {
        return false, err
    }
    return record.Token == token, nil
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
    chaincode, err := contractapi.NewChaincode(&LocationBasedIoTAuthentication{})
    if err != nil {
        fmt.Printf("Error creating LocationBasedIoTAuthentication chaincode: %v", err)
    }
    if err := chaincode.Start(); err != nil {
        fmt.Printf("Error starting LocationBasedIoTAuthentication chaincode: %v", err)
    }
}
EOF
            ;;
        LocationBasedIoTRegistration)
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

type LocationBasedIoTRegistration struct {
    contractapi.Contract
}

type IoTRegistrationRecord struct {
    DeviceID   string `json:"deviceID"`
    Status     string `json:"status"`
    X          string `json:"x"`
    Y          string `json:"y"`
    Distance   string `json:"distance"`
    Timestamp  string `json:"timestamp"`
}

func (s *LocationBasedIoTRegistration) Init(ctx contractapi.TransactionContextInterface) error {
    return nil
}

func (s *LocationBasedIoTRegistration) RegisterIoTDevice(ctx contractapi.TransactionContextInterface, deviceID, status, x, y string) error {
    distance, err := calculateDistance(x, y, "0", "0")
    if err != nil {
        return err
    }
    record := IoTRegistrationRecord{
        DeviceID:  deviceID,
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
    return ctx.GetStub().PutState(deviceID, recordJSON)
}

func (s *LocationBasedIoTRegistration) QueryAsset(ctx contractapi.TransactionContextInterface, deviceID string) (*IoTRegistrationRecord, error) {
    assetJSON, err := ctx.GetStub().GetState(deviceID)
    if err != nil {
        return nil, err
    }
    if assetJSON == nil {
        return nil, fmt.Errorf("IoT registration record %s does not exist", deviceID)
    }
    var record IoTRegistrationRecord
    err = json.Unmarshal(assetJSON, &record)
    if err != nil {
        return nil, err
    }
    return &record, nil
}

func (s *LocationBasedIoTRegistration) QueryAllAssets(ctx contractapi.TransactionContextInterface) ([]*IoTRegistrationRecord, error) {
    resultsIterator, err := ctx.GetStub().GetStateByRange("", "")
    if err != nil {
        return nil, err
    }
    defer resultsIterator.Close()

    var records []*IoTRegistrationRecord
    for resultsIterator.HasNext() {
        queryResponse, err := resultsIterator.Next()
        if err != nil {
            return nil, err
        }
        var record IoTRegistrationRecord
        err = json.Unmarshal(queryResponse.Value, &record)
        if err != nil {
            return nil, err
        }
        records = append(records, &record)
    }
    return records, nil
}

func (s *LocationBasedIoTRegistration) ValidateIoTRegistrationDistance(ctx contractapi.TransactionContextInterface, deviceID, maxDistance string) (bool, error) {
    record, err := s.QueryAsset(ctx, deviceID)
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
    chaincode, err := contractapi.NewChaincode(&LocationBasedIoTRegistration{})
    if err != nil {
        fmt.Printf("Error creating LocationBasedIoTRegistration chaincode: %v", err)
    }
    if err := chaincode.Start(); err != nil {
        fmt.Printf("Error starting LocationBasedIoTRegistration chaincode: %v", err)
    }
}
EOF
            ;;
        LocationBasedIoTRevocation)
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

type LocationBasedIoTRevocation struct {
    contractapi.Contract
}

type IoTRevocationRecord struct {
    DeviceID   string `json:"deviceID"`
    Status     string `json:"status"`
    X          string `json:"x"`
    Y          string `json:"y"`
    Distance   string `json:"distance"`
    Timestamp  string `json:"timestamp"`
}

func (s *LocationBasedIoTRevocation) Init(ctx contractapi.TransactionContextInterface) error {
    return nil
}

func (s *LocationBasedIoTRevocation) RevokeIoTDevice(ctx contractapi.TransactionContextInterface, deviceID, status, x, y string) error {
    distance, err := calculateDistance(x, y, "0", "0")
    if err != nil {
        return err
    }
    record := IoTRevocationRecord{
        DeviceID:  deviceID,
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
    return ctx.GetStub().PutState(deviceID, recordJSON)
}

func (s *LocationBasedIoTRevocation) QueryAsset(ctx contractapi.TransactionContextInterface, deviceID string) (*IoTRevocationRecord, error) {
    assetJSON, err := ctx.GetStub().GetState(deviceID)
    if err != nil {
        return nil, err
    }
    if assetJSON == nil {
        return nil, fmt.Errorf("IoT revocation record %s does not exist", deviceID)
    }
    var record IoTRevocationRecord
    err = json.Unmarshal(assetJSON, &record)
    if err != nil {
        return nil, err
    }
    return &record, nil
}

func (s *LocationBasedIoTRevocation) QueryAllAssets(ctx contractapi.TransactionContextInterface) ([]*IoTRevocationRecord, error) {
    resultsIterator, err := ctx.GetStub().GetStateByRange("", "")
    if err != nil {
        return nil, err
    }
    defer resultsIterator.Close()

    var records []*IoTRevocationRecord
    for resultsIterator.HasNext() {
        queryResponse, err := resultsIterator.Next()
        if err != nil {
            return nil, err
        }
        var record IoTRevocationRecord
        err = json.Unmarshal(queryResponse.Value, &record)
        if err != nil {
            return nil, err
        }
        records = append(records, &record)
    }
    return records, nil
}

func (s *LocationBasedIoTRevocation) ValidateIoTRevocationDistance(ctx contractapi.TransactionContextInterface, deviceID, maxDistance string) (bool, error) {
    record, err := s.QueryAsset(ctx, deviceID)
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
    chaincode, err := contractapi.NewChaincode(&LocationBasedIoTRevocation{})
    if err != nil {
        fmt.Printf("Error creating LocationBasedIoTRevocation chaincode: %v", err)
    }
    if err := chaincode.Start(); err != nil {
        fmt.Printf("Error starting LocationBasedIoTRevocation chaincode: %v", err)
    }
}
EOF
            ;;
        LocationBasedIoTResource)
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

type LocationBasedIoTResource struct {
    contractapi.Contract
}

type IoTResourceAllocation struct {
    DeviceID   string `json:"deviceID"`
    ResourceID string `json:"resourceID"`
    Amount     string `json:"amount"`
    X          string `json:"x"`
    Y          string `json:"y"`
    Distance   string `json:"distance"`
    Timestamp  string `json:"timestamp"`
}

func (s *LocationBasedIoTResource) Init(ctx contractapi.TransactionContextInterface) error {
    return nil
}

func (s *LocationBasedIoTResource) AllocateIoTResource(ctx contractapi.TransactionContextInterface, deviceID, resourceID, amount, x, y string) error {
    distance, err := calculateDistance(x, y, "0", "0")
    if err != nil {
        return err
    }
    allocation := IoTResourceAllocation{
        DeviceID:   deviceID,
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
    return ctx.GetStub().PutState(deviceID, allocationJSON)
}

func (s *LocationBasedIoTResource) QueryAsset(ctx contractapi.TransactionContextInterface, deviceID string) (*IoTResourceAllocation, error) {
    assetJSON, err := ctx.GetStub().GetState(deviceID)
    if err != nil {
        return nil, err
    }
    if assetJSON == nil {
        return nil, fmt.Errorf("IoT resource allocation %s does not exist", deviceID)
    }
    var allocation IoTResourceAllocation
    err = json.Unmarshal(assetJSON, &allocation)
    if err != nil {
        return nil, err
    }
    return &allocation, nil
}

func (s *LocationBasedIoTResource) QueryAllAssets(ctx contractapi.TransactionContextInterface) ([]*IoTResourceAllocation, error) {
    resultsIterator, err := ctx.GetStub().GetStateByRange("", "")
    if err != nil {
        return nil, err
    }
    defer resultsIterator.Close()

    var allocations []*IoTResourceAllocation
    for resultsIterator.HasNext() {
        queryResponse, err := resultsIterator.Next()
        if err != nil {
            return nil, err
        }
        var allocation IoTResourceAllocation
        err = json.Unmarshal(queryResponse.Value, &allocation)
        if err != nil {
            return nil, err
        }
        allocations = append(allocations, &allocation)
    }
    return allocations, nil
}

func (s *LocationBasedIoTResource) ValidateIoTResourceDistance(ctx contractapi.TransactionContextInterface, deviceID, maxDistance string) (bool, error) {
    allocation, err := s.QueryAsset(ctx, deviceID)
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
    chaincode, err := contractapi.NewChaincode(&LocationBasedIoTResource{})
    if err != nil {
        fmt.Printf("Error creating LocationBasedIoTResource chaincode: %v", err)
    }
    if err := chaincode.Start(); err != nil {
        fmt.Printf("Error starting LocationBasedIoTResource chaincode: %v", err)
    }
}
EOF
            ;;
        LocationBasedUserActivity)
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

type LocationBasedUserActivity struct {
    contractapi.Contract
}

type UserActivityRecord struct {
    UserID     string `json:"userID"`
    Activity   string `json:"activity"`
    X          string `json:"x"`
    Y          string `json:"y"`
    Distance   string `json:"distance"`
    Timestamp  string `json:"timestamp"`
}

func (s *LocationBasedUserActivity) Init(ctx contractapi.TransactionContextInterface) error {
    return nil
}

func (s *LocationBasedUserActivity) RecordUserActivity(ctx contractapi.TransactionContextInterface, userID, activity, x, y string) error {
    distance, err := calculateDistance(x, y, "0", "0")
    if err != nil {
        return err
    }
    record := UserActivityRecord{
        UserID:    userID,
        Activity:  activity,
        X:         x,
        Y:         y,
        Distance:  distance,
        Timestamp: time.Now().String(),
    }
    recordJSON, err := json.Marshal(record)
    if err != nil {
        return err
    }
    return ctx.GetStub().PutState(userID, recordJSON)
}

func (s *LocationBasedUserActivity) QueryAsset(ctx contractapi.TransactionContextInterface, userID string) (*UserActivityRecord, error) {
    assetJSON, err := ctx.GetStub().GetState(userID)
    if err != nil {
        return nil, err
    }
    if assetJSON == nil {
        return nil, fmt.Errorf("user activity record %s does not exist", userID)
    }
    var record UserActivityRecord
    err = json.Unmarshal(assetJSON, &record)
    if err != nil {
        return nil, err
    }
    return &record, nil
}

func (s *LocationBasedUserActivity) QueryAllAssets(ctx contractapi.TransactionContextInterface) ([]*UserActivityRecord, error) {
    resultsIterator, err := ctx.GetStub().GetStateByRange("", "")
    if err != nil {
        return nil, err
    }
    defer resultsIterator.Close()

    var records []*UserActivityRecord
    for resultsIterator.HasNext() {
        queryResponse, err := resultsIterator.Next()
        if err != nil {
            return nil, err
        }
        var record UserActivityRecord
        err = json.Unmarshal(queryResponse.Value, &record)
        if err != nil {
            return nil, err
        }
        records = append(records, &record)
    }
    return records, nil
}

func (s *LocationBasedUserActivity) ValidateUserActivityDistance(ctx contractapi.TransactionContextInterface, userID, maxDistance string) (bool, error) {
    record, err := s.QueryAsset(ctx, userID)
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
    chaincode, err := contractapi.NewChaincode(&LocationBasedUserActivity{})
    if err != nil {
        fmt.Printf("Error creating LocationBasedUserActivity chaincode: %v", err)
    }
    if err := chaincode.Start(); err != nil {
        fmt.Printf("Error starting LocationBasedUserActivity chaincode: %v", err)
    }
}
EOF
            ;;
    esac
done

echo "Generated chaincode for ${#contracts[@]} contracts in part 4:"
for contract in "${contracts[@]}"; do
    if [ -f "chaincode/$contract/chaincode.go" ]; then
        echo " - $contract: OK"
    else
        echo " - $contract: Failed"
    fi
done
