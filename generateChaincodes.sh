#!/bin/bash

contracts=(
    "LocationBasedAssignment" "LocationBasedConnection" "LocationBasedBandwidth" "LocationBasedQoS"
    "LocationBasedPriority" "LocationBasedStatus" "LocationBasedFault" "LocationBasedTraffic"
    "LocationBasedLatency" "LocationBasedEnergy" "LocationBasedRoaming" "LocationBasedSignalStrength"
    "LocationBasedCoverage" "LocationBasedInterference" "LocationBasedResourceAllocation"
    "LocationBasedNetworkLoad" "LocationBasedCongestion" "LocationBasedDynamicRouting"
    "LocationBasedAntennaConfig" "LocationBasedSignalQuality" "LocationBasedNetworkHealth"
    "LocationBasedPowerManagement" "LocationBasedChannelAllocation" "LocationBasedSessionManagement"
    "LocationBasedIoTConnection" "LocationBasedIoTBandwidth" "LocationBasedIoTStatus"
    "LocationBasedIoTFault" "LocationBasedIoTSession" "LocationBasedIoTAuthentication"
    "LocationBasedIoTRegistration" "LocationBasedIoTRevocation" "LocationBasedIoTResource"
    "LocationBasedNetworkPerformance" "LocationBasedUserActivity"
    "AuthenticateUser" "AuthenticateIoT" "ConnectUser" "ConnectIoT" "RegisterUser" "RegisterIoT"
    "RevokeUser" "RevokeIoT" "AssignRole" "GrantAccess" "LogIdentityAudit" "AllocateIoTBandwidth"
    "UpdateAntennaLoad" "RequestResource" "ShareSpectrum" "AssignGeneralPriority" "LogResourceAudit"
    "BalanceLoad" "AllocateDynamic" "UpdateAntennaStatus" "UpdateIoTStatus" "LogNetworkPerformance"
    "LogUserActivity" "DetectAntennaFault" "DetectIoTFault" "MonitorAntennaTraffic" "GenerateReport"
    "TrackLatency" "MonitorEnergy" "PerformRoaming" "TrackSession" "TrackIoTSession"
    "DisconnectEntity" "GenerateBill" "LogTransaction" "LogConnectionAudit" "EncryptData"
    "EncryptIoTData" "LogAccess" "DetectIntrusion" "ManageKey" "SetPolicy" "CreateSecureChannel"
    "LogSecurityAudit" "AuthenticateAntenna" "MonitorNetworkCongestion" "AllocateNetworkResource"
    "MonitorNetworkHealth" "ManageNetworkPolicy" "LogNetworkAudit"
)

for contract in "${contracts[@]}"; do
    mkdir -p chaincode/$contract
    cat > chaincode/$contract/chaincode.go <<EOF
package main

import (
    "encoding/json"
    "fmt"
    "time"
    "github.com/hyperledger/fabric-contract-api-go/contractapi"
)

type ${contract} struct {
    contractapi.Contract
}

type Asset struct {
    EntityID   string \`json:"entityID"\`
    Value      string \`json:"value"\`
    X          string \`json:"x"\` // برای قراردادهای LocationBased*
    Y          string \`json:"y"\` // برای قراردادهای LocationBased*
    Distance   string \`json:"distance"\` // برای قراردادهای LocationBased*
    Timestamp  string \`json:"timestamp"\`
}

func (s *${contract}) Init(ctx contractapi.TransactionContextInterface) error {
    return nil
}

func (s *${contract}) CreateAsset(ctx contractapi.TransactionContextInterface, entityID, value, x, y, distance string) error {
    asset := Asset{
        EntityID:  entityID,
        Value:     value,
        X:         x,
        Y:         y,
        Distance:  distance,
        Timestamp: time.Now().String(),
    }
    assetJSON, err := json.Marshal(asset)
    if err != nil {
        return err
    }
    return ctx.GetStub().PutState(entityID, assetJSON)
}

func (s *${contract}) QueryAsset(ctx contractapi.TransactionContextInterface, entityID string) (*Asset, error) {
    assetJSON, err := ctx.GetStub().GetState(entityID)
    if err != nil {
        return nil, err
    }
    if assetJSON == nil {
        return nil, fmt.Errorf("asset %s does not exist", entityID)
    }
    var asset Asset
    err = json.Unmarshal(assetJSON, &asset)
    if err != nil {
        return nil, err
    }
    return &asset, nil
}

func (s *${contract}) QueryAllAssets(ctx contractapi.TransactionContextInterface) ([]*Asset, error) {
    resultsIterator, err := ctx.GetStub().GetStateByRange("", "")
    if err != nil {
        return nil, err
    }
    defer resultsIterator.Close()

    var assets []*Asset
    for resultsIterator.HasNext() {
        queryResponse, err := resultsIterator.Next()
        if err != nil {
            return nil, err
        }
        var asset Asset
        err = json.Unmarshal(queryResponse.Value, &asset)
        if err != nil {
            return nil, err
        }
        assets = append(assets, &asset)
    }
    return assets, nil
}

func main() {
    chaincode, err := contractapi.NewChaincode(&${contract}{})
    if err != nil {
        fmt.Printf("Error creating ${contract} chaincode: %v", err)
    }
    if err := chaincode.Start(); err != nil {
        fmt.Printf("Error starting ${contract} chaincode: %v", err)
    }
}
EOF
done

echo "Generated chaincode for ${#contracts[@]} contracts:"
for contract in "${contracts[@]}"; do
    if [ -f "chaincode/$contract/chaincode.go" ]; then
        echo " - $contract: OK"
    else
        echo " - $contract: Failed"
    fi
done
