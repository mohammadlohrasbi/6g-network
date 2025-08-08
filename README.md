# 6G Fabric Network

The **6G Fabric Network** is a scalable, decentralized blockchain network built on **Hyperledger Fabric** for managing and optimizing 6G networks. It includes **85 smart contracts** organized into 10 functional groups, supports **20 channels** for contract isolation, and is designed to scale across **an arbitrary number of organizations** (default: 8 organizations). The project leverages **location-based coordinates (x, y)** for managing users and IoT devices, integrates with **CouchDB** for state storage, and provides **graphical visualization** using **D3.js**. It ensures **security** with TLS and smart contracts for authentication and encryption, and supports **scalability** with TPS=50, txNumber=1000, and users/iot=50. The web interface allows dynamic configuration of the number of organizations and test parameters (contracts, channels, TPS, transactions, users).

## Project Objectives
- **Location-Based Management**: Utilize (x, y) coordinates in a square grid for managing users and IoT devices.
- **Security**: Implement authentication, encryption, and access control via smart contracts.
- **Auditability**: Log and audit network activities, policies, and performance.
- **Graphical Visualization**: Display network data (e.g., device and antenna positions) using D3.js.
- **Scalability**: Support TPS=50, txNumber=1000, and 50 users/IoT devices.
- **State Storage**: Use CouchDB for advanced querying of contract states.
- **Multi-Organization Support**: Scale to an arbitrary number of organizations (default: 8).
- **Dynamic Test Configuration**: Configure test parameters (number of contracts, channels, TPS, transactions, users) via the web interface.

## Prerequisites
- **Hyperledger Fabric**: Version 2.5
- **Docker** and **Docker Compose**: For running the blockchain network
- **Node.js**: Version 14 or higher (for web server and tests)
- **Go**: Version 1.18 or higher (for smart contracts)
- **CouchDB**: For state storage
- **Nginx**: For serving static files and proxying requests
- **D3.js**: For graphical visualization
- **Fabric Tools**: `peer`, `configtxgen`, `cryptogen`

### Installation
1. **Install Hyperledger Fabric**:
   ```bash
   curl -sSL https://raw.githubusercontent.com/hyperledger/fabric/main/scripts/bootstrap.sh | bash -s -- 2.5.0 1.5.2
   export PATH=${PWD}/bin:$PATH
   ```
2. **Install Node.js and npm**:
   ```bash
   sudo apt-get update
   sudo apt-get install -y nodejs npm
   npm install -g js-yaml
   ```
3. **Install Go**:
   ```bash
   sudo apt-get install -y golang-go
   ```
4. **Install Docker and Docker Compose**:
   ```bash
   sudo apt-get install -y docker.io docker-compose
   sudo systemctl start docker
   sudo systemctl enable docker
   ```
5. **Install Nginx**:
   ```bash
   sudo apt-get install -y nginx
   ```

## Project Structure
- **chaincode/**: Contains 85 Go smart contracts, each in a separate subdirectory (e.g., `chaincode/AssetManagement`, `chaincode/LocationBasedIoTBandwidth`).
- **scripts/**:
  - `generateChaincodes_part[1-10].sh`: Generate the 85 smart contracts.
  - `setup.sh`: Set up the network, channels, and deploy contracts.
  - `generateConnectionJson.sh`: Generate connection JSON files for organizations.
  - `generateConnectionProfiles.sh`: Generate connection profiles for organizations.
  - `generateCoreyamls.sh`: Generate `core.yaml` files for peers.
  - `generateWorkloadFiles.sh`: Generate initial workload files for scalability tests.
  - `net`: Manage the network (start/stop/restart/logs).
- **docs/**:
  - `contract_descriptions_part[1-10].md`: Detailed documentation for the 85 smart contracts.
- **web/**:
  - `utils.js`: Helper functions for interacting with contracts.
  - `webserver.js`: Node.js server for API, data visualization, and test configuration.
  - `fabric-sdk.js`: Fabric SDK integration for blockchain interaction.
  - `index.html`: Web interface with D3.js visualization and test configuration.
  - `nginx.conf`: Nginx configuration for static files and proxying.
- **test/**:
  - `test.js`: Scalability test script for dynamic test parameters.
  - `workloads/workload.json`: Workload configuration generated dynamically via the web interface.
- **config/**:
  - `docker-compose.yml`: Network configuration with CouchDB, peers, orderers, and Nginx.
  - `configtx.yaml`: Channel configuration for all 20 channels.
  - `cryptogen.yaml`: TLS and MSP certificate generation.
  - `networkConfig.yaml`: Network configuration for Fabric SDK.
  - `core/core-org[1-8].yaml`: Peer configurations for each organization.
  - `core/orderer.yaml`: Orderer configuration.
  - `profiles/org[1-8]-profile.yaml`: Connection profiles for each organization.
  - `connection-org[1-8].json`: Connection JSON files for each organization.
  - `channel-artifacts/*.tx`: Channel configuration files for 20 channels.
- **crypto-config/**: TLS and MSP certificates for all organizations.
- **wallet/**: Wallet for Fabric SDK identities.

## Smart Contracts
The project includes **85 smart contracts** organized into 10 groups:
1. **Group 1 (1-8)**: Base contracts (e.g., `AssetManagement`, `UserManagement`, `IoTManagement`).
2. **Group 2 (9-17)**: Location-based contracts (e.g., `LocationBasedAccess`, `LocationBasedResource`).
3. **Group 3 (18-26)**: Advanced location-based contracts (e.g., `LocationBasedCongestion`).
4. **Group 4 (27-35)**: IoT contracts (e.g., `LocationBasedIoTBandwidth`, `LocationBasedIoTStatus`).
5. **Group 5 (36-43)**: Authentication and connection contracts (e.g., `AuthenticateUser`, `ConnectIoT`).
6. **Group 6 (44-51)**: Monitoring contracts (e.g., `MonitorNetwork`, `LogFault`).
7. **Group 7 (52-60)**: Management and optimization contracts (e.g., `BalanceLoad`, `OptimizeNetwork`).
8. **Group 8 (61-68)**: Security contracts (e.g., `EncryptData`, `SetPolicy`).
9. **Group 9 (69-77)**: Advanced management and monitoring (e.g., `ManageNetwork`, `MonitorTraffic`).
10. **Group 10 (78-85)**: Audit contracts (e.g., `LogNetworkAudit`, `LogComplianceAudit`).

Detailed documentation is available in `docs/contract_descriptions_part[1-10].md`.

### Example Contract Commands
For the `LocationBasedIoTBandwidth` contract on Org1:
```bash
export CORE_PEER_LOCALMSPID="Org1MSP"
export CORE_PEER_TLS_ROOTCERT_FILE=/crypto-config/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt
export CORE_PEER_MSPCONFIGPATH=/crypto-config/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp
export CORE_PEER_ADDRESS=peer0.org1.example.com:7051
peer chaincode invoke -C IoTChannel -n LocationBasedIoTBandwidth -c '{"function":"AllocateIoTBandwidth","Args":["iot1","Antenna1","50Mbps","40.7128","-74.0060"]}' --tls --cafile /crypto-config/ordererOrganizations/example.com/orderers/orderer1.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
peer chaincode query -C IoTChannel -n LocationBasedIoTBandwidth -c '{"function":"QueryAsset","Args":["iot1"]}'
```

## Setup Instructions
### 1. Create Project Structure
```bash
mkdir -p 6g-fabric-network/{chaincode,scripts,docs,web/public,test/workloads,config/{channel-artifacts,core,profiles},crypto-config,wallet}
cd 6g-fabric-network
```

### 2. Copy Project Files
Copy the following files to their respective directories:
- `scripts/`: `generateChaincodes_part[1-10].sh`, `setup.sh`, `generateConnectionJson.sh`, `generateConnectionProfiles.sh`, `generateCoreyamls.sh`, `generateWorkloadFiles.sh`, `net`
- `docs/`: `contract_descriptions_part[1-10].md`
- `web/`: `utils.js`, `webserver.js`, `fabric-sdk.js`, `index.html`, `nginx.conf`
- `test/`: `test.js`, `workloads/workload.json`
- `config/`: `docker-compose.yml`, `configtx.yaml`, `cryptogen.yaml`, `networkConfig.yaml`, `core/core-org[1-8].yaml`, `core/orderer.yaml`, `profiles/org[1-8]-profile.yaml`, `connection-org[1-8].json`, `channel-artifacts/*.tx`

### 3. Install Prerequisites
```bash
sudo apt-get update
sudo apt-get install -y docker.io docker-compose nodejs npm golang-go nginx
npm install -g js-yaml
curl -sSL https://raw.githubusercontent.com/hyperledger/fabric/main/scripts/bootstrap.sh | bash -s -- 2.5.0 1.5.2
export PATH=${PWD}/bin:$PATH
```

### 4. Generate Certificates and Channel Artifacts
```bash
cd config
cryptogen generate --config=cryptogen.yaml
export FABRIC_CFG_PATH=${PWD}
for CHANNEL in NetworkChannel ResourceChannel PerformanceChannel IoTChannel AuthChannel ConnectivityChannel SessionChannel PolicyChannel AuditChannel SecurityChannel DataChannel AnalyticsChannel MonitoringChannel ManagementChannel OptimizationChannel FaultChannel TrafficChannel AccessChannel ComplianceChannel IntegrationChannel; do
    configtxgen -profile ApplicationGenesis -outputBlock channel-artifacts/${CHANNEL}.block -channelID ${CHANNEL}
    configtxgen -profile ApplicationGenesis -outputCreateChannelTx channel-artifacts/${CHANNEL,,}.tx -channelID ${CHANNEL}
done
cd ..
```

### 5. Register Identities in Wallet
```bash
export FABRIC_CA_CLIENT_HOME=${PWD}/wallet
for i in {1..8}; do
    fabric-ca-client enroll -u https://admin:adminpw@localhost:$((7054 + (i-1)*1000)) --caname ca-org${i} --tls.certfiles crypto-config/peerOrganizations/org${i}.example.com/ca/ca.org${i}.example.com-cert.pem
done
```

### 6. Generate and Deploy Smart Contracts
```bash
cd scripts
chmod +x *.sh
for i in {1..10}; do ./generateChaincodes_part${i}.sh; done
./generateConnectionJson.sh
./generateConnectionProfiles.sh
./generateCoreyamls.sh
./generateWorkloadFiles.sh
./setup.sh
cd ..
```

### 7. Start Web Server and Nginx
```bash
cd web
npm install express fabric-network js-yaml
node webserver.js &
sudo cp nginx.conf /etc/nginx/sites-available/6g-fabric-network
sudo ln -s /etc/nginx/sites-available/6g-fabric-network /etc/nginx/sites-enabled/
sudo systemctl restart nginx
```

### 8. Run Scalability Tests via Web Interface
1. Open `http://localhost` in a browser.
2. Configure test parameters:
   - **Number of Organizations**: Set the desired number of organizations (default: 8).
   - **Number of Contracts**: Choose up to 85 contracts.
   - **Number of Channels**: Choose up to 20 channels.
   - **Target TPS**: Set the target transactions per second (default: 50).
   - **Number of Transactions**: Set the total number of transactions (default: 1000).
   - **Number of Users/IoT**: Set the number of users or IoT devices (default: 50).
3. Click "Run Scalability Test" to execute the test.
4. Check the console output or logs for test results.

## Key Configurations
- **CouchDB**:
  ```yaml
  couchdb-org1:
    image: couchdb:latest
    ports:
      - "5984:5984"
    environment:
      - COUCHDB_USER=admin
      - COUCHDB_PASSWORD=adminpw
  ```
  Access: `http://localhost:5984/_utils` (username: `admin`, password: `adminpw`).
- **Nginx**:
  ```bash
  sudo nginx -t
  ```
- **TLS**:
  ```bash
  /crypto-config/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt
  /crypto-config/ordererOrganizations/example.com/orderers/orderer1.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
  ```
- **Channels**: 20 channels for contract isolation.
- **Orderer Configuration**:
  ```bash
  config/core/orderer.yaml
  ```
- **Workload Configuration**:
  ```bash
  test/workloads/workload.json
  ```
  Generated dynamically via the web interface.

## Troubleshooting
- **Docker Issues**:
  ```bash
  docker ps
  docker logs peer0.org1.example.com
  docker logs orderer1.example.com
  docker logs couchdb-org1
  docker logs nginx
  ```
- **Nginx Issues**:
  ```bash
  sudo nginx -t
  sudo journalctl -u nginx
  ```
- **Contract Issues**:
  ```bash
  cat scripts/setup.sh.log
  ls -l chaincode/
  ```
- **CouchDB Issues**:
  ```bash
  curl http://admin:adminpw@localhost:5984/_utils
  ```
- **SDK Issues**:
  ```bash
  ls -l wallet/
  cat config/networkConfig.yaml
  ```

## For Developers
To add a new smart contract:
1. Update `scripts/generateChaincodes_part*.sh`.
2. Add documentation to `docs/contract_descriptions_part*.md`.
3. Modify `webserver.js` to include the new contract in the `/contracts` endpoint.
4. Test the contract:
   ```bash
   peer chaincode invoke -C IoTChannel -n NewContract -c '{"function":"Init","Args":[]}' --tls --cafile /crypto-config/ordererOrganizations/example.com/orderers/orderer1.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
   ```

To change test parameters:
1. Open `http://localhost` in a browser.
2. Set the desired test parameters (orgCount, contractCount, channelCount, tps, txNumber, users).
3. Click "Run Scalability Test" to generate `workload.json` and execute tests.

## Notes
- **Certificates**: Ensure `crypto-config/` contains TLS and MSP certificates.
- **API**: For more details, visit https://x.ai/api.
- **Contract Updates**: Increment contract version in `setup.sh` (e.g., from 1.0 to 1.1).
