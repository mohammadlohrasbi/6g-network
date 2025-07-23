#!/bin/bash

contracts=(
    "AuthenticateUser" "AuthenticateIoT" "ConnectUser" "ConnectIoT" "RegisterUser" "RegisterIoT" "RevokeUser" "RevokeIoT" "AssignRole"
)

for contract in "${contracts[@]}"; do
    mkdir -p chaincode/$contract
    case $contract in
        AuthenticateUser)
            cat > chaincode/$contract/chaincode.go <<EOF
package main

import (
    "encoding/json"
    "fmt"
    "time"
    "github.com/hyperledger/fabric-contract-api-go/contractapi"
)

type AuthenticateUser struct {
    contractapi.Contract
}

type UserAuthRecord struct {
    UserID    string `json:"userID"`
    Token     string `json:"token"`
    Timestamp string `json:"timestamp"`
}

func (s *AuthenticateUser) Init(ctx contractapi.TransactionContextInterface) error {
    return nil
}

func (s *AuthenticateUser) Authenticate(ctx contractapi.TransactionContextInterface, userID, token string) error {
    record := UserAuthRecord{
        UserID:    userID,
        Token:     token,
        Timestamp: time.Now().String(),
    }
    recordJSON, err := json.Marshal(record)
    if err != nil {
        return err
    }
    return ctx.GetStub().PutState(userID, recordJSON)
}

func (s *AuthenticateUser) QueryAsset(ctx contractapi.TransactionContextInterface, userID string) (*UserAuthRecord, error) {
    assetJSON, err := ctx.GetStub().GetState(userID)
    if err != nil {
        return nil, err
    }
    if assetJSON == nil {
        return nil, fmt.Errorf("user auth record %s does not exist", userID)
    }
    var record UserAuthRecord
    err = json.Unmarshal(assetJSON, &record)
    if err != nil {
        return nil, err
    }
    return &record, nil
}

func (s *AuthenticateUser) QueryAllAssets(ctx contractapi.TransactionContextInterface) ([]*UserAuthRecord, error) {
    resultsIterator, err := ctx.GetStub().GetStateByRange("", "")
    if err != nil {
        return nil, err
    }
    defer resultsIterator.Close()

    var records []*UserAuthRecord
    for resultsIterator.HasNext() {
        queryResponse, err := resultsIterator.Next()
        if err != nil {
            return nil, err
        }
        var record UserAuthRecord
        err = json.Unmarshal(queryResponse.Value, &record)
        if err != nil {
            return nil, err
        }
        records = append(records, &record)
    }
    return records, nil
}

func (s *AuthenticateUser) ValidateToken(ctx contractapi.TransactionContextInterface, userID, token string) (bool, error) {
    record, err := s.QueryAsset(ctx, userID)
    if err != nil {
        return false, err
    }
    return record.Token == token, nil
}

func main() {
    chaincode, err := contractapi.NewChaincode(&AuthenticateUser{})
    if err != nil {
        fmt.Printf("Error creating AuthenticateUser chaincode: %v", err)
    }
    if err := chaincode.Start(); err != nil {
        fmt.Printf("Error starting AuthenticateUser chaincode: %v", err)
    }
}
EOF
            ;;
        AuthenticateIoT)
            cat > chaincode/$contract/chaincode.go <<EOF
package main

import (
    "encoding/json"
    "fmt"
    "time"
    "github.com/hyperledger/fabric-contract-api-go/contractapi"
)

type AuthenticateIoT struct {
    contractapi.Contract
}

type IoTAuthRecord struct {
    DeviceID  string `json:"deviceID"`
    Token     string `json:"token"`
    Timestamp string `json:"timestamp"`
}

func (s *AuthenticateIoT) Init(ctx contractapi.TransactionContextInterface) error {
    return nil
}

func (s *AuthenticateIoT) Authenticate(ctx contractapi.TransactionContextInterface, deviceID, token string) error {
    record := IoTAuthRecord{
        DeviceID:  deviceID,
        Token:     token,
        Timestamp: time.Now().String(),
    }
    recordJSON, err := json.Marshal(record)
    if err != nil {
        return err
    }
    return ctx.GetStub().PutState(deviceID, recordJSON)
}

func (s *AuthenticateIoT) QueryAsset(ctx contractapi.TransactionContextInterface, deviceID string) (*IoTAuthRecord, error) {
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

func (s *AuthenticateIoT) QueryAllAssets(ctx contractapi.TransactionContextInterface) ([]*IoTAuthRecord, error) {
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

func (s *AuthenticateIoT) ValidateToken(ctx contractapi.TransactionContextInterface, deviceID, token string) (bool, error) {
    record, err := s.QueryAsset(ctx, deviceID)
    if err != nil {
        return false, err
    }
    return record.Token == token, nil
}

func main() {
    chaincode, err := contractapi.NewChaincode(&AuthenticateIoT{})
    if err != nil {
        fmt.Printf("Error creating AuthenticateIoT chaincode: %v", err)
    }
    if err := chaincode.Start(); err != nil {
        fmt.Printf("Error starting AuthenticateIoT chaincode: %v", err)
    }
}
EOF
            ;;
        ConnectUser)
            cat > chaincode/$contract/chaincode.go <<EOF
package main

import (
    "encoding/json"
    "fmt"
    "time"
    "github.com/hyperledger/fabric-contract-api-go/contractapi"
)

type ConnectUser struct {
    contractapi.Contract
}

type UserConnection struct {
    UserID    string `json:"userID"`
    AntennaID string `json:"antennaID"`
    Status    string `json:"status"`
    Timestamp string `json:"timestamp"`
}

func (s *ConnectUser) Init(ctx contractapi.TransactionContextInterface) error {
    return nil
}

func (s *ConnectUser) Connect(ctx contractapi.TransactionContextInterface, userID, antennaID string) error {
    connection := UserConnection{
        UserID:    userID,
        AntennaID: antennaID,
        Status:    "Connected",
        Timestamp: time.Now().String(),
    }
    connectionJSON, err := json.Marshal(connection)
    if err != nil {
        return err
    }
    return ctx.GetStub().PutState(userID, connectionJSON)
}

func (s *ConnectUser) Disconnect(ctx contractapi.TransactionContextInterface, userID string) error {
    connection, err := s.QueryAsset(ctx, userID)
    if err != nil {
        return err
    }
    connection.Status = "Disconnected"
    connection.Timestamp = time.Now().String()
    connectionJSON, err := json.Marshal(connection)
    if err != nil {
        return err
    }
    return ctx.GetStub().PutState(userID, connectionJSON)
}

func (s *ConnectUser) QueryAsset(ctx contractapi.TransactionContextInterface, userID string) (*UserConnection, error) {
    assetJSON, err := ctx.GetStub().GetState(userID)
    if err != nil {
        return nil, err
    }
    if assetJSON == nil {
        return nil, fmt.Errorf("user connection %s does not exist", userID)
    }
    var connection UserConnection
    err = json.Unmarshal(assetJSON, &connection)
    if err != nil {
        return nil, err
    }
    return &connection, nil
}

func (s *ConnectUser) QueryAllAssets(ctx contractapi.TransactionContextInterface) ([]*UserConnection, error) {
    resultsIterator, err := ctx.GetStub().GetStateByRange("", "")
    if err != nil {
        return nil, err
    }
    defer resultsIterator.Close()

    var connections []*UserConnection
    for resultsIterator.HasNext() {
        queryResponse, err := resultsIterator.Next()
        if err != nil {
            return nil, err
        }
        var connection UserConnection
        err = json.Unmarshal(queryResponse.Value, &connection)
        if err != nil {
            return nil, err
        }
        connections = append(connections, &connection)
    }
    return connections, nil
}

func main() {
    chaincode, err := contractapi.NewChaincode(&ConnectUser{})
    if err != nil {
        fmt.Printf("Error creating ConnectUser chaincode: %v", err)
    }
    if err := chaincode.Start(); err != nil {
        fmt.Printf("Error starting ConnectUser chaincode: %v", err)
    }
}
EOF
            ;;
        ConnectIoT)
            cat > chaincode/$contract/chaincode.go <<EOF
package main

import (
    "encoding/json"
    "fmt"
    "time"
    "github.com/hyperledger/fabric-contract-api-go/contractapi"
)

type ConnectIoT struct {
    contractapi.Contract
}

type IoTConnection struct {
    DeviceID  string `json:"deviceID"`
    AntennaID string `json:"antennaID"`
    Status    string `json:"status"`
    Timestamp string `json:"timestamp"`
}

func (s *ConnectIoT) Init(ctx contractapi.TransactionContextInterface) error {
    return nil
}

func (s *ConnectIoT) Connect(ctx contractapi.TransactionContextInterface, deviceID, antennaID string) error {
    connection := IoTConnection{
        DeviceID:  deviceID,
        AntennaID: antennaID,
        Status:    "Connected",
        Timestamp: time.Now().String(),
    }
    connectionJSON, err := json.Marshal(connection)
    if err != nil {
        return err
    }
    return ctx.GetStub().PutState(deviceID, connectionJSON)
}

func (s *ConnectIoT) Disconnect(ctx contractapi.TransactionContextInterface, deviceID string) error {
    connection, err := s.QueryAsset(ctx, deviceID)
    if err != nil {
        return err
    }
    connection.Status = "Disconnected"
    connection.Timestamp = time.Now().String()
    connectionJSON, err := json.Marshal(connection)
    if err != nil {
        return err
    }
    return ctx.GetStub().PutState(deviceID, connectionJSON)
}

func (s *ConnectIoT) QueryAsset(ctx contractapi.TransactionContextInterface, deviceID string) (*IoTConnection, error) {
    assetJSON, err := ctx.GetStub().GetState(deviceID)
    if err != nil {
        return nil, err
    }
    if assetJSON == nil {
        return nil, fmt.Errorf("IoT connection %s does not exist", deviceID)
    }
    var connection IoTConnection
    err = json.Unmarshal(assetJSON, &connection)
    if err != nil {
        return nil, err
    }
    return &connection, nil
}

func (s *ConnectIoT) QueryAllAssets(ctx contractapi.TransactionContextInterface) ([]*IoTConnection, error) {
    resultsIterator, err := ctx.GetStub().GetStateByRange("", "")
    if err != nil {
        return nil, err
    }
    defer resultsIterator.Close()

    var connections []*IoTConnection
    for resultsIterator.HasNext() {
        queryResponse, err := resultsIterator.Next()
        if err != nil {
            return nil, err
        }
        var connection IoTConnection
        err = json.Unmarshal(queryResponse.Value, &connection)
        if err != nil {
            return nil, err
        }
        connections = append(connections, &connection)
    }
    return connections, nil
}

func main() {
    chaincode, err := contractapi.NewChaincode(&ConnectIoT{})
    if err != nil {
        fmt.Printf("Error creating ConnectIoT chaincode: %v", err)
    }
    if err := chaincode.Start(); err != nil {
        fmt.Printf("Error starting ConnectIoT chaincode: %v", err)
    }
}
EOF
            ;;
        RegisterUser)
            cat > chaincode/$contract/chaincode.go <<EOF
package main

import (
    "encoding/json"
    "fmt"
    "time"
    "github.com/hyperledger/fabric-contract-api-go/contractapi"
)

type RegisterUser struct {
    contractapi.Contract
}

type UserRegistration struct {
    UserID    string `json:"userID"`
    Status    string `json:"status"`
    Timestamp string `json:"timestamp"`
}

func (s *RegisterUser) Init(ctx contractapi.TransactionContextInterface) error {
    return nil
}

func (s *RegisterUser) Register(ctx contractapi.TransactionContextInterface, userID, status string) error {
    registration := UserRegistration{
        UserID:    userID,
        Status:    status,
        Timestamp: time.Now().String(),
    }
    registrationJSON, err := json.Marshal(registration)
    if err != nil {
        return err
    }
    return ctx.GetStub().PutState(userID, registrationJSON)
}

func (s *RegisterUser) QueryAsset(ctx contractapi.TransactionContextInterface, userID string) (*UserRegistration, error) {
    assetJSON, err := ctx.GetStub().GetState(userID)
    if err != nil {
        return nil, err
    }
    if assetJSON == nil {
        return nil, fmt.Errorf("user registration %s does not exist", userID)
    }
    var registration UserRegistration
    err = json.Unmarshal(assetJSON, &registration)
    if err != nil {
        return nil, err
    }
    return &registration, nil
}

func (s *RegisterUser) QueryAllAssets(ctx contractapi.TransactionContextInterface) ([]*UserRegistration, error) {
    resultsIterator, err := ctx.GetStub().GetStateByRange("", "")
    if err != nil {
        return nil, err
    }
    defer resultsIterator.Close()

    var registrations []*UserRegistration
    for resultsIterator.HasNext() {
        queryResponse, err := resultsIterator.Next()
        if err != nil {
            return nil, err
        }
        var registration UserRegistration
        err = json.Unmarshal(queryResponse.Value, &registration)
        if err != nil {
            return nil, err
        }
        registrations = append(registrations, &registration)
    }
    return registrations, nil
}

func main() {
    chaincode, err := contractapi.NewChaincode(&RegisterUser{})
    if err != nil {
        fmt.Printf("Error creating RegisterUser chaincode: %v", err)
    }
    if err := chaincode.Start(); err != nil {
        fmt.Printf("Error starting RegisterUser chaincode: %v", err)
    }
}
EOF
            ;;
        RegisterIoT)
            cat > chaincode/$contract/chaincode.go <<EOF
package main

import (
    "encoding/json"
    "fmt"
    "time"
    "github.com/hyperledger/fabric-contract-api-go/contractapi"
)

type RegisterIoT struct {
    contractapi.Contract
}

type IoTRegistration struct {
    DeviceID  string `json:"deviceID"`
    Status    string `json:"status"`
    Timestamp string `json:"timestamp"`
}

func (s *RegisterIoT) Init(ctx contractapi.TransactionContextInterface) error {
    return nil
}

func (s *RegisterIoT) Register(ctx contractapi.TransactionContextInterface, deviceID, status string) error {
    registration := IoTRegistration{
        DeviceID:  deviceID,
        Status:    status,
        Timestamp: time.Now().String(),
    }
    registrationJSON, err := json.Marshal(registration)
    if err != nil {
        return err
    }
    return ctx.GetStub().PutState(deviceID, registrationJSON)
}

func (s *RegisterIoT) QueryAsset(ctx contractapi.TransactionContextInterface, deviceID string) (*IoTRegistration, error) {
    assetJSON, err := ctx.GetStub().GetState(deviceID)
    if err != nil {
        return nil, err
    }
    if assetJSON == nil {
        return nil, fmt.Errorf("IoT registration %s does not exist", deviceID)
    }
    var registration IoTRegistration
    err = json.Unmarshal(assetJSON, &registration)
    if err != nil {
        return nil, err
    }
    return &registration, nil
}

func (s *RegisterIoT) QueryAllAssets(ctx contractapi.TransactionContextInterface) ([]*IoTRegistration, error) {
    resultsIterator, err := ctx.GetStub().GetStateByRange("", "")
    if err != nil {
        return nil, err
    }
    defer resultsIterator.Close()

    var registrations []*IoTRegistration
    for resultsIterator.HasNext() {
        queryResponse, err := resultsIterator.Next()
        if err != nil {
            return nil, err
        }
        var registration IoTRegistration
        err = json.Unmarshal(queryResponse.Value, &registration)
        if err != nil {
            return nil, err
        }
        registrations = append(registrations, &registration)
    }
    return registrations, nil
}

func main() {
    chaincode, err := contractapi.NewChaincode(&RegisterIoT{})
    if err != nil {
        fmt.Printf("Error creating RegisterIoT chaincode: %v", err)
    }
    if err := chaincode.Start(); err != nil {
        fmt.Printf("Error starting RegisterIoT chaincode: %v", err)
    }
}
EOF
            ;;
        RevokeUser)
            cat > chaincode/$contract/chaincode.go <<EOF
package main

import (
    "encoding/json"
    "fmt"
    "time"
    "github.com/hyperledger/fabric-contract-api-go/contractapi"
)

type RevokeUser struct {
    contractapi.Contract
}

type UserRevocation struct {
    UserID    string `json:"userID"`
    Status    string `json:"status"`
    Timestamp string `json:"timestamp"`
}

func (s *RevokeUser) Init(ctx contractapi.TransactionContextInterface) error {
    return nil
}

func (s *RevokeUser) Revoke(ctx contractapi.TransactionContextInterface, userID, status string) error {
    revocation := UserRevocation{
        UserID:    userID,
        Status:    status,
        Timestamp: time.Now().String(),
    }
    revocationJSON, err := json.Marshal(revocation)
    if err != nil {
        return err
    }
    return ctx.GetStub().PutState(userID, revocationJSON)
}

func (s *RevokeUser) QueryAsset(ctx contractapi.TransactionContextInterface, userID string) (*UserRevocation, error) {
    assetJSON, err := ctx.GetStub().GetState(userID)
    if err != nil {
        return nil, err
    }
    if assetJSON == nil {
        return nil, fmt.Errorf("user revocation %s does not exist", userID)
    }
    var revocation UserRevocation
    err = json.Unmarshal(assetJSON, &revocation)
    if err != nil {
        return nil, err
    }
    return &revocation, nil
}

func (s *RevokeUser) QueryAllAssets(ctx contractapi.TransactionContextInterface) ([]*UserRevocation, error) {
    resultsIterator, err := ctx.GetStub().GetStateByRange("", "")
    if err != nil {
        return nil, err
    }
    defer resultsIterator.Close()

    var revocations []*UserRevocation
    for resultsIterator.HasNext() {
        queryResponse, err := resultsIterator.Next()
        if err != nil {
            return nil, err
        }
        var revocation UserRevocation
        err = json.Unmarshal(queryResponse.Value, &revocation)
        if err != nil {
            return nil, err
        }
        revocations = append(revocations, &revocation)
    }
    return revocations, nil
}

func main() {
    chaincode, err := contractapi.NewChaincode(&RevokeUser{})
    if err != nil {
        fmt.Printf("Error creating RevokeUser chaincode: %v", err)
    }
    if err := chaincode.Start(); err != nil {
        fmt.Printf("Error starting RevokeUser chaincode: %v", err)
    }
}
EOF
            ;;
        RevokeIoT)
            cat > chaincode/$contract/chaincode.go <<EOF
package main

import (
    "encoding/json"
    "fmt"
    "time"
    "github.com/hyperledger/fabric-contract-api-go/contractapi"
)

type RevokeIoT struct {
    contractapi.Contract
}

type IoTRevocation struct {
    DeviceID  string `json:"deviceID"`
    Status    string `json:"status"`
    Timestamp string `json:"timestamp"`
}

func (s *RevokeIoT) Init(ctx contractapi.TransactionContextInterface) error {
    return nil
}

func (s *RevokeIoT) Revoke(ctx contractapi.TransactionContextInterface, deviceID, status string) error {
    revocation := IoTRevocation{
        DeviceID:  deviceID,
        Status:    status,
        Timestamp: time.Now().String(),
    }
    revocationJSON, err := json.Marshal(revocation)
    if err != nil {
        return err
    }
    return ctx.GetStub().PutState(deviceID, revocationJSON)
}

func (s *RevokeIoT) QueryAsset(ctx contractapi.TransactionContextInterface, deviceID string) (*IoTRevocation, error) {
    assetJSON, err := ctx.GetStub().GetState(deviceID)
    if err != nil {
        return nil, err
    }
    if assetJSON == nil {
        return nil, fmt.Errorf("IoT revocation %s does not exist", deviceID)
    }
    var revocation IoTRevocation
    err = json.Unmarshal(assetJSON, &revocation)
    if err != nil {
        return nil, err
    }
    return &revocation, nil
}

func (s *RevokeIoT) QueryAllAssets(ctx contractapi.TransactionContextInterface) ([]*IoTRevocation, error) {
    resultsIterator, err := ctx.GetStub().GetStateByRange("", "")
    if err != nil {
        return nil, err
    }
    defer resultsIterator.Close()

    var revocations []*IoTRevocation
    for resultsIterator.HasNext() {
        queryResponse, err := resultsIterator.Next()
        if err != nil {
            return nil, err
        }
        var revocation IoTRevocation
        err = json.Unmarshal(queryResponse.Value, &revocation)
        if err != nil {
            return nil, err
        }
        revocations = append(revocations, &revocation)
    }
    return revocations, nil
}

func main() {
    chaincode, err := contractapi.NewChaincode(&RevokeIoT{})
    if err != nil {
        fmt.Printf("Error creating RevokeIoT chaincode: %v", err)
    }
    if err := chaincode.Start(); err != nil {
        fmt.Printf("Error starting RevokeIoT chaincode: %v", err)
    }
}
EOF
            ;;
        AssignRole)
            cat > chaincode/$contract/chaincode.go <<EOF
package main

import (
    "encoding/json"
    "fmt"
    "time"
    "github.com/hyperledger/fabric-contract-api-go/contractapi"
)

type AssignRole struct {
    contractapi.Contract
}

type RoleAssignment struct {
    UserID    string `json:"userID"`
    Role      string `json:"role"`
    Timestamp string `json:"timestamp"`
}

func (s *AssignRole) Init(ctx contractapi.TransactionContextInterface) error {
    return nil
}

func (s *AssignRole) Assign(ctx contractapi.TransactionContextInterface, userID, role string) error {
    assignment := RoleAssignment{
        UserID:    userID,
        Role:      role,
        Timestamp: time.Now().String(),
    }
    assignmentJSON, err := json.Marshal(assignment)
    if err != nil {
        return err
    }
    return ctx.GetStub().PutState(userID, assignmentJSON)
}

func (s *AssignRole) QueryAsset(ctx contractapi.TransactionContextInterface, userID string) (*RoleAssignment, error) {
    assetJSON, err := ctx.GetStub().GetState(userID)
    if err != nil {
        return nil, err
    }
    if assetJSON == nil {
        return nil, fmt.Errorf("role assignment %s does not exist", userID)
    }
    var assignment RoleAssignment
    err = json.Unmarshal(assetJSON, &assignment)
    if err != nil {
        return nil, err
    }
    return &assignment, nil
}

func (s *AssignRole) QueryAllAssets(ctx contractapi.TransactionContextInterface) ([]*RoleAssignment, error) {
    resultsIterator, err := ctx.GetStub().GetStateByRange("", "")
    if err != nil {
        return nil, err
    }
    defer resultsIterator.Close()

    var assignments []*RoleAssignment
    for resultsIterator.HasNext() {
        queryResponse, err := resultsIterator.Next()
        if err != nil {
            return nil, err
        }
        var assignment RoleAssignment
        err = json.Unmarshal(queryResponse.Value, &assignment)
        if err != nil {
            return nil, err
        }
        assignments = append(assignments, &assignment)
    }
    return assignments, nil
}

func main() {
    chaincode, err := contractapi.NewChaincode(&AssignRole{})
    if err != nil {
        fmt.Printf("Error creating AssignRole chaincode: %v", err)
    }
    if err := chaincode.Start(); err != nil {
        fmt.Printf("Error starting AssignRole chaincode: %v", err)
    }
}
EOF
            ;;
    esac
done

echo "Generated chaincode for ${#contracts[@]} contracts in part 5:"
for contract in "${contracts[@]}"; do
    if [ -f "chaincode/$contract/chaincode.go" ]; then
        echo " - $contract: OK"
    else
        echo " - $contract: Failed"
    fi
done
