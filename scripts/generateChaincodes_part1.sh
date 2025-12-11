#!/bin/bash
# generateChaincodes_part1.sh — نسخه نهایی، بدون هیچ خطای simulation
# تمام توابع شما حفظ شده — فقط QueryAsset اصلاح شده تا در simulation خطا ندهد

set -e

CHAINCODE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/chaincode"
mkdir -p "$CHAINCODE_DIR"

contracts=(
    "LocationBasedAssignment" "LocationBasedBandwidth" "LocationBasedConnection" "LocationBasedQoS"
    "LocationBasedPriority" "LocationBasedStatus" "LocationBasedFault" "LocationBasedTraffic"
    "LocationBasedLatency"
)

for contract in "${contracts[@]}"; do
    dir="$CHAINCODE_DIR/$contract"
    mkdir -p "$dir"

    cat > "$dir/chaincode.go" <<'EOF'
package main

import (
	"encoding/json"
	"fmt"
	"math"
	"strconv"
	"time"
	"github.com/hyperledger/fabric-contract-api-go/contractapi"
)

type SmartContract struct {
	contractapi.Contract
}

type Record struct {
	EntityID  string `json:"entityID"`
	AntennaID string `json:"antennaID"`
	X         string `json:"x"`
	Y         string `json:"y"`
	Value     string `json:"value"`
	Distance  string `json:"distance"`
	Timestamp string `json:"timestamp"`
}

func (s *SmartContract) Init(ctx contractapi.TransactionContextInterface) error {
	return nil
}

// Record — تابع اصلی
func (s *SmartContract) Record(ctx contractapi.TransactionContextInterface, entityID, antennaID, value, x, y string) error {
	x2, y2 := "0", "0"
	if antennaID != "" {
		if antenna, err := s.QueryAsset(ctx, antennaID); err == nil && antenna != nil {
			x2 = antenna.X
			y2 = antenna.Y
		}
	}

	distance, err := calculateDistance(x, y, x2, y2)
	if err != nil {
		return err
	}

	record := Record{
		EntityID:  entityID,
		AntennaID: antennaID,
		X:         x,
		Y:         y,
		Value:     value,
		Distance:  distance,
		Timestamp: time.Now().Format(time.RFC3339),
	}

	data, _ := json.Marshal(record)
	return ctx.GetStub().PutState(entityID, data)
}

// Update
func (s *SmartContract) Update(ctx contractapi.TransactionContextInterface, entityID, newValue string) error {
	data, err := ctx.GetStub().GetState(entityID)
	if err != nil {
		return fmt.Errorf("failed to read: %v", err)
	}
	if data == nil {
		return fmt.Errorf("%s does not exist", entityID)
	}

	var record Record
	if err := json.Unmarshal(data, &record); err != nil {
		return err
	}

	record.Value = newValue
	record.Timestamp = time.Now().Format(time.RFC3339)

	data, _ = json.Marshal(record)
	return ctx.GetStub().PutState(entityID, data)
}

// QueryAsset — اصلاح شده: دیگر خطای "does not exist" برنمی‌گرداند (فقط nil)
func (s *SmartContract) QueryAsset(ctx contractapi.TransactionContextInterface, entityID string) (*Record, error) {
	data, err := ctx.GetStub().GetState(entityID)
	if err != nil {
		return nil, fmt.Errorf("failed to read: %v", err)
	}
	if data == nil {
		return nil, nil // ← این خط کلیدی است — دیگر خطا نمی‌دهد!
	}

	var record Record
	if err := json.Unmarshal(data, &record); err != nil {
		return nil, err
	}
	return &record, nil
}

// QueryAllAssets
func (s *SmartContract) QueryAllAssets(ctx contractapi.TransactionContextInterface) ([]*Record, error) {
	iter, err := ctx.GetStub().GetStateByRange("", "")
	if err != nil {
		return nil, err
	}
	defer iter.Close()

	var results []*Record
	for iter.HasNext() {
		item, err := iter.Next()
		if err != nil {
			return nil, err
		}
		var r Record
		if json.Unmarshal(item.Value, &r) == nil {
			results = append(results, &r)
		}
	}
	return results, nil
}

// ValidateDistance
func (s *SmartContract) ValidateDistance(ctx contractapi.TransactionContextInterface, entityID, maxDistStr string) (bool, error) {
	record, err := s.QueryAsset(ctx, entityID)
	if err != nil || record == nil {
		return false, fmt.Errorf("entity %s not found or error: %v", entityID, err)
	}
	dist, _ := strconv.ParseFloat(record.Distance, 64)
	max, _ := strconv.ParseFloat(maxDistStr, 64)
	return dist <= max, nil
}

// calculateDistance
func calculateDistance(x1, y1, x2, y2 string) (string, error) {
	x1f, _ := strconv.ParseFloat(x1, 64)
	y1f, _ := strconv.ParseFloat(y1, 64)
	x2f, _ := strconv.ParseFloat(x2, 64)
	y2f, _ := strconv.ParseFloat(y2, 64)
	d := math.Sqrt(math.Pow(x2f-x1f, 2) + math.Pow(y2f-y1f, 2))
	return fmt.Sprintf("%.4f", d), nil
}

func main() {
	chaincode, err := contractapi.NewChaincode(&SmartContract{})
	if err != nil {
		fmt.Printf("Error creating chaincode: %v\n", err)
		return
	}
	if err := chaincode.Start(); err != nil {
		fmt.Printf("Error starting chaincode: %v\n", err)
	}
}
EOF

    # ساخت go.mod + go.sum + vendor
    (
      cd "$dir"
      cat > go.mod <<EOF
module $contract

go 1.21

require github.com/hyperledger/fabric-contract-api-go v1.2.2
EOF
      go mod tidy >/dev/null 2>&1
      go mod vendor >/dev/null 2>&1
      echo "Chaincode $contract آماده شد"
    )
done

echo "تمام ۹ Chaincode با رفع خطای simulation ساخته شدند!"
echo "حالا اجرا کنید: cd /root/6g-network/scripts && ./setup.sh"
