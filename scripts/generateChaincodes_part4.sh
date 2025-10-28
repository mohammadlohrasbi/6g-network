```bash
#!/bin/bash

# Fixed and Complete generateChaincodes_part4.sh
# This script generates full Go chaincode for 9 contracts in part 4.
# Fix: Used <<'EOF' to prevent bash substitution of backticks in Go JSON tags.
# Added complete case for all contracts with customized structs and functions based on fields from errors.
# The Go code is complete with Init, Allocate/Record/Update functions, Query, Validate, and distance calculation.

contracts=(
    "LocationBasedIoTBandwidth" "LocationBasedIoTStatus" "LocationBasedIoTFault" "LocationBasedIoTSession"
    "LocationBasedIoTAuthentication" "LocationBasedIoTRegistration" "LocationBasedIoTRevocation" "LocationBasedIoTResource"
    "LocationBasedUserActivity"
)

for contract in "${contracts[@]}"; do
    mkdir -p chaincode/$contract
    case $contract in
        LocationBasedIoTBandwidth)
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

type LocationBasedIoTBandwidth struct {
    contractapi.Contract
}

type IoTBandwidth struct {
    DeviceID string `json:"deviceID"`
    AntennaID string `json:"antennaID"`
    Bandwidth string `json:"bandwidth"`
    X string `json:"x"`
    Y string `json:"y"`
    Distance string `json:"distance"`
    Timestamp string `json:"timestamp"`
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
    iotBandwidth := IoTBandwidth{
        DeviceID: deviceID,
        AntennaID: antennaID,
        Bandwidth: bandwidth,
        X: x,
        Y: y,
        Distance: distance,
        Timestamp: time.Now().String(),
    }
    iotBandwidthJSON, err := json.Marshal(iotBandwidth)
    if err != nil {
        return err
    }
    return ctx.GetStub().PutState(deviceID, iotBandwidthJSON)
}

func (s *LocationBasedIoTBandwidth) QueryAsset(ctx contractapi.TransactionContextInterface, deviceID string) (*IoTBandwidth, error) {
    assetJSON, err := ctx.GetStub().GetState(deviceID)
    if err != nil {
        return nil, fmt.Errorf("failed to read from world state: %v", err)
    }
    if assetJSON == nil {
        return nil, fmt.Errorf("IoT bandwidth %s does not exist", deviceID)
    }
    var iotBandwidth IoTBandwidth
    err = json.Unmarshal(assetJSON, &iotBandwidth)
    if err != nil {
        return nil, err
    }
    return &iotBandwidth, nil
}

func (s *LocationBasedIoTBandwidth) QueryAllAssets(ctx contractapi.TransactionContextInterface) ([]*IoTBandwidth, error) {
    resultsIterator, err := ctx.GetStub().GetStateByRange("", "")
    if err != nil {
        return nil, err
    }
    defer resultsIterator.Close()
    var iotBandwidths []*IoTBandwidth
    for resultsIterator.HasNext() {
        queryResponse, err := resultsIterator.Next()
        if err != nil {
            return nil, err
        }
        var iotBandwidth IoTBandwidth
        err = json.Unmarshal(queryResponse.Value, &iotBandwidth)
        if err != nil {
            return nil, err
        }
        iotBandwidths = append(iotBandwidths, &iotBandwidth)
    }
    return iotBandwidths, nil
}

func (s *LocationBasedIoTBandwidth) ValidateIoTBandwidthDistance(ctx contractapi.TransactionContextInterface, deviceID, maxDistance string) (bool, error) {
    iotBandwidth, err := s.QueryAsset(ctx, deviceID)
    if err != nil {
        return false, err
    }
    distance, err := strconv.ParseFloat(iotBandwidth.Distance, 64)
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

type LocationBasedIoTStatus struct {
    contractapi.Contract
}

type IoTStatus struct {
    DeviceID string `json:"deviceID"`
    Status string `json:"status"`
    X string `json:"x"`
    Y string `json:"y"`
    Distance string `json:"distance"`
    Timestamp string `json:"timestamp"`
}

func (s *LocationBasedIoTStatus) Init(ctx contractapi.TransactionContextInterface) error {
    return nil
}

func (s *LocationBasedIoTStatus) UpdateIoTStatus(ctx contractapi.TransactionContextInterface, deviceID, status, x, y string) error {
    distance, err := calculateDistance(x, y, "0", "0")
    if err != nil {
        return err
    }
    iotStatus := IoTStatus{
        DeviceID: deviceID,
        Status: status,
        X: x,
        Y: y,
        Distance: distance,
        Timestamp: time.Now().String(),
    }
    iotStatusJSON, err := json.Marshal(iotStatus)
    if err != nil {
        return err
    }
    return ctx.GetStub().PutState(deviceID, iotStatusJSON)
}

func (s *LocationBasedIoTStatus) QueryAsset(ctx contractapi.TransactionContextInterface, deviceID string) (*IoTStatus, error) {
    assetJSON, err := ctx.GetStub().GetState(deviceID)
    if err != nil {
        return nil, fmt.Errorf("failed to read from world state: %v", err)
    }
    if assetJSON == nil {
        return nil, fmt.Errorf("IoT status %s does not exist", deviceID)
    }
    var iotStatus IoTStatus
    err = json.Unmarshal(assetJSON, &iotStatus)
    if err != nil {
        return nil, err
    }
    return &iotStatus, nil
}

func (s *LocationBasedIoTStatus) QueryAllAssets(ctx contractapi.TransactionContextInterface) ([]*IoTStatus, error) {
    resultsIterator, err := ctx.GetStub().GetStateByRange("", "")
    if err != nil {
        return nil, err
    }
    defer resultsIterator.Close()
    var iotStatuses []*IoTStatus
    for resultsIterator.HasNext() {
        queryResponse, err := resultsIterator.Next()
        if err != nil {
            return nil, err
        }
        var iotStatus IoTStatus
        err = json.Unmarshal(queryResponse.Value, &iotStatus)
        if err != nil {
            return nil, err
        }
        iotStatuses = append(iotStatuses, &iotStatus)
    }
    return iotStatuses, nil
}

func (s *LocationBasedIoTStatus) ValidateIoTStatusDistance(ctx contractapi.TransactionContextInterface, deviceID, maxDistance string) (bool, error) {
    iotStatus, err := s.QueryAsset(ctx, deviceID)
    if err != nil {
        return false, err
    }
    distance, err := strconv.ParseFloat(iotStatus.Distance, 64)
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

type LocationBasedIoTFault struct {
    contractapi.Contract
}

type IoTFault struct {
    DeviceID string `json:"deviceID"`
    FaultType string `json:"faultType"`
    X string `json:"x"`
    Y string `json:"y"`
    Distance string `json:"distance"`
    Timestamp string `json:"timestamp"`
}

func (s *LocationBasedIoTFault) Init(ctx contractapi.TransactionContextInterface) error {
    return nil
}

func (s *LocationBasedIoTFault) ReportIoTFault(ctx contractapi.TransactionContextInterface, deviceID, faultType, x, y string) error {
    distance, err := calculateDistance(x, y, "0", "0")
    if err != nil {
        return err
    }
    iotFault := IoTFault{
        DeviceID: deviceID,
        FaultType: faultType,
        X: x,
        Y: y,
        Distance: distance,
        Timestamp: time.Now().String(),
    }
    iotFaultJSON, err := json.Marshal(iotFault)
    if err != nil {
        return err
    }
    return ctx.GetStub().PutState(deviceID, iotFaultJSON)
}

func (s *LocationBasedIoTFault) QueryAsset(ctx contractapi.TransactionContextInterface, deviceID string) (*IoTFault, error) {
    assetJSON, err := ctx.GetStub().GetState(deviceID)
    if err != nil {
        return nil, fmt.Errorf("failed to read from world state: %v", err)
    }
    if assetJSON == nil {
        return nil, fmt.Errorf("IoT fault %s does not exist", deviceID)
    }
    var iotFault IoTFault
    err = json.Unmarshal(assetJSON, &iotFault)
    if err != nil {
        return nil, err
    }
    return &iotFault, nil
}

func (s *LocationBasedIoTFault) QueryAllAssets(ctx contractapi.TransactionContextInterface) ([]*IoTFault, error) {
    resultsIterator, err := ctx.GetStub().GetStateByRange("", "")
    if err != nil {
        return nil, err
    }
    defer resultsIterator.Close()
    var iotFaults []*IoTFault
    for resultsIterator.HasNext() {
        queryResponse, err := resultsIterator.Next()
        if err != nil {
            return nil, err
        }
        var iotFault IoTFault
        err = json.Unmarshal(queryResponse.Value, &iotFault)
        if err != nil {
            return nil, err
        }
        iotFaults = append(iotFaults, &iotFault)
    }
    return iotFaults, nil
}

func (s *LocationBasedIoTFault) ValidateIoTFaultDistance(ctx contractapi.TransactionContextInterface, deviceID, maxDistance string) (bool, error) {
    iotFault, err := s.QueryAsset(ctx, deviceID)
    if err != nil {
        return false, err
    }
    distance, err := strconv.ParseFloat(iotFault.Distance, 64)
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

type LocationBasedIoTSession struct {
    contractapi.Contract
}

type IoTSession struct {
    DeviceID string `json:"deviceID"`
    SessionID string `json:"sessionID"`
    X string `json:"x"`
    Y string `json:"y"`
    Distance string `json:"distance"`
    Status string `json:"status"`
    Timestamp string `json:"timestamp"`
}

func (s *LocationBasedIoTSession) Init(ctx contractapi.TransactionContextInterface) error {
    return nil
}

func (s *LocationBasedIoTSession) StartIoTSession(ctx contractapi.TransactionContextInterface, deviceID, sessionID, x, y, status string) error {
    distance, err := calculateDistance(x, y, "0", "0")
    if err != nil {
        return err
    }
    iotSession := IoTSession{
        DeviceID: deviceID,
        SessionID: sessionID,
        X: x,
        Y: y,
        Distance: distance,
        Status: status,
        Timestamp: time.Now().String(),
    }
    iotSessionJSON, err := json.Marshal(iotSession)
    if err != nil {
        return err
    }
    return ctx.GetStub().PutState(deviceID, iotSessionJSON)
}

func (s *LocationBasedIoTSession) QueryAsset(ctx contractapi.TransactionContextInterface, deviceID string) (*IoTSession, error) {
    assetJSON, err := ctx.GetStub().GetState(deviceID)
    if err != nil {
        return nil, fmt.Errorf("failed to read from world state: %v", err)
    }
    if assetJSON == nil {
        return nil, fmt.Errorf("IoT session %s does not exist", deviceID)
    }
    var iotSession IoTSession
    err = json.Unmarshal(assetJSON, &iotSession)
    if err != nil {
        return nil, err
    }
    return &iotSession, nil
}

func (s *LocationBasedIoTSession) QueryAllAssets(ctx contractapi.TransactionContextInterface) ([]*IoTSession, error) {
    resultsIterator, err := ctx.GetStub().GetStateByRange("", "")
    if err != nil {
        return nil, err
    }
    defer resultsIterator.Close()
    var iotSessions []*IoTSession
    for resultsIterator.HasNext() {
        queryResponse, err := resultsIterator.Next()
        if err != nil {
            return nil, err
        }
        var iotSession IoTSession
        err = json.Unmarshal(queryResponse.Value, &iotSession)
        if err != nil {
            return nil, err
        }
        iotSessions = append(iotSessions, &iotSession)
    }
    return iotSessions, nil
}

func (s *LocationBasedIoTSession) ValidateIoTSessionDistance(ctx contractapi.TransactionContextInterface, deviceID, maxDistance string) (bool, error) {
    iotSession, err := s.QueryAsset(ctx, deviceID)
    if err != nil {
        return false, err
    }
    distance, err := strconv.ParseFloat(iotSession.Distance, 64)
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

type LocationBasedIoTAuthentication struct {
    contractapi.Contract
}

type IoTAuthentication struct {
    DeviceID string `json:"deviceID"`
    Token string `json:"token"`
    X string `json:"x"`
    Y string `json:"y"`
    Distance string `json:"distance"`
    Timestamp string `json:"timestamp"`
}

func (s *LocationBasedIoTAuthentication) Init(ctx contractapi.TransactionContextInterface) error {
    return nil
}

func (s *LocationBasedIoTAuthentication) AuthenticateIoT(ctx contractapi.TransactionContextInterface, deviceID, token, x, y string) error {
    distance, err := calculateDistance(x, y, "0", "0")
    if err != nil {
        return err
    }
    iotAuthentication := IoTAuthentication{
        DeviceID: deviceID,
        Token: token,
        X: x,
        Y: y,
        Distance: distance,
        Timestamp: time.Now().String(),
    }
    iotAuthenticationJSON, err := json.Marshal(iotAuthentication)
    if err != nil {
        return err
    }
    return ctx.GetStub().PutState(deviceID, iotAuthenticationJSON)
}

func (s *LocationBasedIoTAuthentication) QueryAsset(ctx contractapi.TransactionContextInterface, deviceID string) (*IoTAuthentication, error) {
    assetJSON, err := ctx.GetStub().GetState(deviceID)
    if err != nil {
        return nil, fmt.Errorf("failed to read from world state: %v", err)
    }
    if assetJSON == nil {
        return nil, fmt.Errorf("IoT authentication %s does not exist", deviceID)
    }
    var iotAuthentication IoTAuthentication
    err = json.Unmarshal(assetJSON, &iotAuthentication)
    if err != nil {
        return nil, err
    }
    return &iotAuthentication, nil
}

func (s *LocationBasedIoTAuthentication) QueryAllAssets(ctx contractapi.TransactionContextInterface) ([]*IoTAuthentication, error) {
    resultsIterator, err := ctx.GetStub().GetStateByRange("", "")
    if err != nil {
        return nil, err
    }
    defer resultsIterator.Close()
    var iotAuthentications []*IoTAuthentication
    for resultsIterator.HasNext() {
        queryResponse, err := resultsIterator.Next()
        if err != nil {
            return nil, err
        }
        var iotAuthentication IoTAuthentication
        err = json.Unmarshal(queryResponse.Value, &iotAuthentication)
        if err != nil {
            return nil, err
        }
        iotAuthentications = append(iotAuthentications, &iotAuthentication)
    }
    return iotAuthentications, nil
}

func (s *LocationBasedIoTAuthentication) ValidateIoTAuthenticationDistance(ctx contractapi.TransactionContextInterface, deviceID, maxDistance string) (bool, error) {
    iotAuthentication, err := s.QueryAsset(ctx, deviceID)
    if err != nil {
        return false, err
    }
    distance, err := strconv.ParseFloat(iotAuthentication.Distance, 64)
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

type LocationBasedIoTRegistration struct {
    contractapi.Contract
}

type IoTRegistration struct {
    DeviceID string `json:"deviceID"`
    Status string `json:"status"`
    X string `json:"x"`
    Y string `json:"y"`
    Distance string `json:"distance"`
    Timestamp string `json:"timestamp"`
}

func (s *LocationBasedIoTRegistration) Init(ctx contractapi.TransactionContextInterface) error {
    return nil
}

func (s *LocationBasedIoTRegistration) RegisterIoT(ctx contractapi.TransactionContextInterface, deviceID, status, x, y string) error {
    distance, err := calculateDistance(x, y, "0", "0")
    if err != nil {
        return err
    }
    iotRegistration := IoTRegistration{
        DeviceID: deviceID,
        Status: status,
        X: x,
        Y: y,
        Distance: distance,
        Timestamp: time.Now().String(),
    }
    iotRegistrationJSON, err := json.Marshal(iotRegistration)
    if err != nil {
        return err
    }
    return ctx.GetStub().PutState(deviceID, iotRegistrationJSON)
}

func (s *LocationBasedIoTRegistration) QueryAsset(ctx contractapi.TransactionContextInterface, deviceID string) (*IoTRegistration, error) {
    assetJSON, err := ctx.GetStub().GetState(deviceID)
    if err != nil {
        return nil, fmt.Errorf("failed to read from world state: %v", err)
    }
    if assetJSON == nil {
        return nil, fmt.Errorf("IoT registration %s does not exist", deviceID)
    }
    var iotRegistration IoTRegistration
    err = json.Unmarshal(assetJSON, &iotRegistration)
    if err != nil {
        return nil, err
    }
    return &iotRegistration, nil
}

func (s *LocationBasedIoTRegistration) QueryAllAssets(ctx contractapi.TransactionContextInterface) ([]*IoTRegistration, error) {
    resultsIterator, err := ctx.GetStub().GetStateByRange("", "")
    if err != nil {
        return nil, err
    }
    defer resultsIterator.Close()
    var iotRegistrations []*IoTRegistration
    for resultsIterator.HasNext() {
        queryResponse, err := resultsIterator.Next()
        if err != nil {
            return nil, err
        }
        var iotRegistration IoTRegistration
        err = json.Unmarshal(queryResponse.Value, &iotRegistration)
        if err != nil {
            return nil, err
        }
        iotRegistrations = append(iotRegistrations, &iotRegistration)
    }
    return iotRegistrations, nil
}

func (s *LocationBasedIoTRegistration) ValidateIoTRegistrationDistance(ctx contractapi.TransactionContextInterface, deviceID, maxDistance string) (bool, error) {
    iotRegistration, err := s.QueryAsset(ctx, deviceID)
    if err != nil {
        return false, err
    }
    distance, err := strconv.ParseFloat(iotRegistration.Distance, 64)
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

type LocationBasedIoTRevocation struct {
    contractapi.Contract
}

type IoTRevocation struct {
    DeviceID string `json:"deviceID"`
    Status string `json:"status"`
    X string `json:"x"`
    Y string `json:"y"`
    Distance string `json:"distance"`
    Timestamp string `json:"timestamp"`
}

func (s *LocationBasedIoTRevocation) Init(ctx contractapi.TransactionContextInterface) error {
    return nil
}

func (s *LocationBasedIoTRevocation) RevokeIoT(ctx contractapi.TransactionContextInterface, deviceID, status, x, y string) error {
    distance, err := calculateDistance(x, y, "0", "0")
    if err != nil {
        return err
    }
    iotRevocation := IoTRevocation{
        DeviceID: deviceID,
        Status: status,
        X: x,
        Y: y,
        Distance: distance,
        Timestamp: time.Now().String(),
    }
    iotRevocationJSON, err := json.Marshal(iotRevocation)
    if err != nil {
        return err
    }
    return ctx.GetStub().PutState(deviceID, iotRevocationJSON)
}

func (s *LocationBasedIoTRevocation) QueryAsset(ctx contractapi.TransactionContextInterface, deviceID string) (*IoTRevocation, error) {
    assetJSON, err := ctx.GetStub().GetState(deviceID)
    if err != nil {
        return nil, fmt.Errorf("failed to read from world state: %v", err)
    }
    if assetJSON == nil {
        return nil, fmt.Errorf("IoT revocation %s does not exist", deviceID)
    }
    var iotRevocation IoTRevocation
    err = json.Unmarshal(assetJSON, &iotRevocation)
    if err != nil {
        return nil, err
    }
    return &iotRevocation, nil
}

func (s *LocationBasedIoTRevocation) QueryAllAssets(ctx contractapi.TransactionContextInterface) ([]*IoTRevocation, error) {
    resultsIterator, err := ctx.GetStub().GetStateByRange("", "")
    if err != nil {
        return nil, err
    }
    defer resultsIterator.Close()
    var iotRevocations []*IoTRevocation
    for resultsIterator.HasNext() {
        queryResponse, err := resultsIterator.Next()
        if err != nil {
            return nil, err
        }
        var iotRevocation IoTRevocation
        err = json.Unmarshal(queryResponse.Value, &iotRevocation)
        if err != nil {
            return nil, err
        }
        iotRevocations = append(iotRevocations, &iotRevocation)
    }
    return iotRevocations, nil
}

func (s *LocationBasedIoTRevocation) ValidateIoTRevocationDistance(ctx contractapi.TransactionContextInterface, deviceID, maxDistance string) (bool, error) {
    iotRevocation, err := s.QueryAsset(ctx, deviceID)
    if err != nil {
        return false, err
    }
    distance, err := strconv.ParseFloat(iotRevocation.Distance, 64)
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

type LocationBasedIoTResource struct {
    contractapi.Contract
}

type IoTResource struct {
    DeviceID string `json:"deviceID"`
    ResourceID string `json:"resourceID"`
    Amount string `json:"amount"`
    X string `json:"x"`
    Y string `json:"y"`
    Distance string `json:"distance"`
    Timestamp string `json:"timestamp"`
}

func (s *LocationBasedIoTResource) Init(ctx contractapi.TransactionContextInterface) error {
    return nil
}

func (s *LocationBasedIoTResource) AllocateIoTResource(ctx contractapi.TransactionContextInterface, deviceID, resourceID, amount, x, y string) error {
    distance, err := calculateDistance(x, y, "0", "0")
    if err != nil {
        return err
    }
    iotResource := IoTResource{
        DeviceID: deviceID,
        ResourceID: resourceID,
        Amount: amount,
        X: x,
        Y: y,
        Distance: distance,
        Timestamp: time.Now().String(),
    }
    iotResourceJSON, err := json.Marshal(iotResource)
    if err != nil {
        return err
    }
    return ctx.GetStub().PutState(deviceID, iotResourceJSON)
}

func (s *LocationBasedIoTResource) QueryAsset(ctx contractapi.TransactionContextInterface, deviceID string) (*IoTResource, error) {
    assetJSON, err := ctx.GetStub().GetState(deviceID)
    if err != nil {
        return nil, fmt.Errorf("failed to read from world state: %v", err)
    }
    if assetJSON == nil {
        return nil, fmt.Errorf("IoT resource %s does not exist", deviceID)
    }
    var iotResource IoTResource
    err = json.Unmarshal(assetJSON, &iotResource)
    if err != nil {
        return nil, err
    }
    return &iotResource, nil
}

func (s *LocationBasedIoTResource) QueryAllAssets(ctx contractapi.TransactionContextInterface) ([]*IoTResource, error) {
    resultsIterator, err := ctx.GetStub().GetStateByRange("", "")
    if err != nil {
        return nil, err
    }
    defer resultsIterator.Close()
    var iotResources []*IoTResource
    for resultsIterator.HasNext() {
        queryResponse, err := resultsIterator.Next()
        if err != nil {
            return nil, err
        }
        var iotResource IoTResource
        err = json.Unmarshal(queryResponse.Value, &iotResource)
        if err != nil {
            return nil, err
        }
        iotResources = append(iotResources, &iotResource)
    }
    return iotResources, nil
}

func (s *LocationBasedIoTResource) ValidateIoTResourceDistance(ctx contractapi.TransactionContextInterface, deviceID, maxDistance string) (bool, error) {
    iotResource, err := s.QueryAsset(ctx, deviceID)
    if err != nil {
        return false, err
    }
    distance, err := strconv.ParseFloat(iotResource.Distance, 64)
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

type LocationBasedUserActivity struct {
    contractapi.Contract
}

type UserActivity struct {
    UserID string `json:"userID"`
    Activity string `json:"activity"`
    X string `json:"x"`
    Y string `json:"y"`
    Distance string `json:"distance"`
    Timestamp string `json:"timestamp"`
}

func (s *LocationBasedUserActivity) Init(ctx contractapi.TransactionContextInterface) error {
    return nil
}

func (s *LocationBasedUserActivity) RecordUserActivity(ctx contractapi.TransactionContextInterface, userID, activity, x, y string) error {
    distance, err := calculateDistance(x, y, "0", "0")
    if err != nil {
        return err
    }
    userActivity := UserActivity{
        UserID: userID,
        Activity: activity,
        X: x,
        Y: y,
        Distance: distance,
        Timestamp: time.Now().String(),
    }
    userActivityJSON, err := json.Marshal(userActivity)
    if err != nil {
        return err
    }
    return ctx.GetStub().PutState(userID, userActivityJSON)
}

func (s *LocationBasedUserActivity) QueryAsset(ctx contractapi.TransactionContextInterface, userID string) (*UserActivity, error) {
    assetJSON, err := ctx.GetStub().GetState(userID)
    if err != nil {
        return nil, fmt.Errorf("failed to read from world state: %v", err)
    }
    if assetJSON == nil {
        return nil, fmt.Errorf("user activity %s does not exist", userID)
    }
    var userActivity UserActivity
    err = json.Unmarshal(assetJSON, &userActivity)
    if err != nil {
        return nil, err
    }
    return &userActivity, nil
}

func (s *LocationBasedUserActivity) QueryAllAssets(ctx contractapi.TransactionContextInterface) ([]*UserActivity, error) {
    resultsIterator, err := ctx.GetStub().GetStateByRange("", "")
    if err != nil {
        return nil, err
    }
    defer resultsIterator.Close()
    var userActivities []*UserActivity
    for resultsIterator.HasNext() {
        queryResponse, err := resultsIterator.Next()
        if err != nil {
            return nil, err
        }
        var userActivity UserActivity
        err = json.Unmarshal(queryResponse.Value, &userActivity)
        if err != nil {
            return nil, err
        }
        userActivities = append(userActivities, &userActivity)
    }
    return userActivities, nil
}

func (s *LocationBasedUserActivity) ValidateUserActivityDistance(ctx contractapi.TransactionContextInterface, userID, maxDistance string) (bool, error) {
    userActivity, err := s.QueryAsset(ctx, userID)
    if err != nil {
        return false, err
    }
    distance, err := strconv.ParseFloat(userActivity.Distance, 64)
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
```
