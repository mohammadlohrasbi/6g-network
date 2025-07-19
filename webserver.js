const express = require('express');
const { Wallets, Gateway } = require('fabric-network');
const fs = require('fs');
const path = require('path');
const { exec } = require('child_process');
const app = express();

app.use(express.static(path.join(__dirname, 'public')));
app.use(express.json());

async function connectToNetwork(org, username) {
    const walletPath = path.join(__dirname, 'wallet');
    const wallet = await Wallets.newFileSystemWallet(walletPath);
    const connectionProfile = JSON.parse(fs.readFileSync(`crypto-config/peerOrganizations/org${org}.example.com/connection-org${org}.json`, 'utf8'));
    const gateway = new Gateway();
    await gateway.connect(connectionProfile, {
        wallet,
        identity: username,
        discovery: { enabled: false }
    });
    return { gateway, network: await gateway.getNetwork('GeneralOperationsChannel') };
}

app.get('/api/entities', async (req, res) => {
    try {
        const { gateway, network } = await connectToNetwork(1, 'admin-org1');
        const contract = network.getContract('LocationBasedAssignment');
        const result = await contract.evaluateTransaction('QueryAllAssets');
        const entities = JSON.parse(result.toString()).map(asset => ({
            id: asset.EntityID,
            type: asset.EntityID.startsWith('Antenna') ? 'Antenna' : asset.EntityID.startsWith('user') ? 'User' : 'IoT',
            x: parseFloat(asset.X),
            y: parseFloat(asset.Y)
        }));
        gateway.disconnect();
        res.json(entities);
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

app.post('/api/run-test', async (req, res) => {
    const { contract, channel, tps, txNumber, users, iot, centerX, centerY, sideLength } = req.body;
    const benchmarkConfig = `
test:
  name: 6g-fabric-benchmark
  description: Benchmark for 6G Fabric Network
  workers:
    type: local
    number: 1
  rounds:
    - label: invoke
      description: Test invoke performance
      txNumber: ${txNumber}
      rateControl:
        type: fixed-rate
        opts:
          tps: ${tps}
      workload:
        module: workload/${contract}.js
        arguments:
          centerX: ${centerX}
          centerY: ${centerY}
          sideLength: ${sideLength}
          users: ${users}
          iot: ${iot}
    - label: query
      description: Test query performance
      txNumber: ${txNumber}
      rateControl:
        type: fixed-rate
        opts:
          tps: ${tps}
      workload:
        module: workload/${contract}.js
        arguments:
          centerX: ${centerX}
          centerY: ${centerY}
          sideLength: ${sideLength}
          users: ${users}
          iot: ${iot}
  monitors:
    resource:
      - module: docker
        options:
          interval: 1
          containers:
            - orderer1.example.com
            - peer0.org1.example.com
            - couchdb-org1
            - peer0.org2.example.com
            - couchdb-org2
            - peer0.org3.example.com
            - couchdb-org3
            - peer0.org4.example.com
            - couchdb-org4
            - peer0.org5.example.com
            - couchdb-org5
            - peer0.org6.example.com
            - couchdb-org6
            - peer0.org7.example.com
            - couchdb-org7
            - peer0.org8.example.com
            - couchdb-org8
`;
    fs.writeFileSync('caliper-workspace/benchmarks/myAssetBenchmark.yaml', benchmarkConfig);
    exec('cd caliper-workspace && npx caliper launch manager --caliper-workspace . --caliper-networkconfig networks/networkConfig.yaml --caliper-benchconfig benchmarks/myAssetBenchmark.yaml', (err, stdout, stderr) => {
        if (err) {
            res.status(500).json({ error: stderr });
            return;
        }
        res.json({ message: 'Test started', log: stdout });
    });
});

app.listen(3000, () => console.log('Server running on port 3000'));
