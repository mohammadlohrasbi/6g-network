#!/bin/bash

# generateAllChaincodes.sh - تولید تمام 85 chaincode در 10 قسمت
# اجرا: ./generateAllChaincodes.sh

set -e

ROOT_DIR="/root/6g-network"
CHAINCODE_DIR="$ROOT_DIR/chaincode"
PARTS_DIR="$ROOT_DIR/parts"  # فرض: فایل‌های JSON در اینجا هستند
mkdir -p "$CHAINCODE_DIR"

echo "Generating all 10 chaincode parts..."

for part in {1..10}; do
  PART_JSON="$PARTS_DIR/part${part}.json"
  PART_SCRIPT="$ROOT_DIR/scripts/generateChaincodes_part${part}.sh"

  # تولید اسکریپت
  cat > "$PART_SCRIPT" <<'EOF'
#!/bin/bash
set -e

contracts=()
while IFS= read -r line; do
  contract=$(echo "$line" | jq -r '.name')
  contracts+=("$contract")
done < <(jq -c '.contracts[]' PART_JSON)

for contract in "${contracts[@]}"; do
  mkdir -p "$CHAINCODE_DIR/$contract"
  cat > "$CHAINCODE_DIR/$contract/chaincode.go" <<'GO'
package main

import (
    "encoding/json"
    "fmt"
    "time"
    "github.com/hyperledger/fabric-contract-api-go/contractapi"
)

type CONTRACT struct {
    contractapi.Contract
}

type Record struct {
    ID        string `json:"id"`
    Value     string `json:"value"`
    Timestamp string `json:"timestamp"`
}

func (s *CONTRACT) Init(ctx contractapi.TransactionContextInterface) error {
    return nil
}

func (s *CONTRACT) Record(ctx contractapi.TransactionContextInterface, id, value string) error {
    record := Record{
        ID:        id,
        Value:     value,
        Timestamp: time.Now().String(),
    }
    data, _ := json.Marshal(record)
    return ctx.GetStub().PutState(id, data)
}

func (s *CONTRACT) Query(ctx contractapi.TransactionContextInterface, id string) (*Record, error) {
    data, err := ctx.GetStub().GetState(id)
    if err != nil || data == nil {
        return nil, fmt.Errorf("not found")
    }
    var r Record
    json.Unmarshal(data, &r)
    return &r, nil
}

func main() {
    chaincode, _ := contractapi.NewChaincode(&CONTRACT{})
    chaincode.Start()
}
GO
  sed -i "s/CONTRACT/$contract/g" "$CHAINCODE_DIR/$contract/chaincode.go"
  echo " - $contract: OK"
done
EOF
  sed -i "s|PART_JSON|$PART_JSON|g" "$PART_SCRIPT"
  chmod +x "$PART_SCRIPT"
  ./"$PART_SCRIPT"
done

echo "All 85 chaincodes generated successfully!"
