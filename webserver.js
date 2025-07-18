const express = require('express');
const { exec } = require('child_process');
const fs = require('fs');
const { Wallets, Gateway, FabricCAServices } = require('fabric-network');
const path = require('path');
const app = express();
const port = 3000;

app.use(express.json());
app.use(express.static('.'));

const profiles = []; // Temporary storage for test profiles

async function connectToNetwork(org, username) {
    const walletPath = path.join(__dirname, 'wallet');
    const wallet = await Wallets.newFileSystemWallet(walletPath);
    const connectionProfile = JSON.parse(fs.readFileSync(`crypto-config/peerOrganizations/org${org}.example.com/connection-org${org}.json`, 'utf8'));
    const gateway = new Gateway();
    await gateway.connect(connectionProfile, {
        wallet,
        identity: username,
        discovery: { enabled: true, asLocalhost: false }
    });
    return { gateway, network: await gateway.getNetwork('GeneralOperationsChannel') };
}

app.post('/login', async (req, res) => {
    const { username, password, org } = req.body;
    try {
        const ca = new FabricCAServices(`https://165.232.71.90:${7054 + (org-1)*1000}`, {
            trustedRoots: fs.readFileSync(`crypto-config/peerOrganizations/org${org}.example.com/ca/ca.org${org}.example.com-cert.pem`),
            verify: false
        });
        const walletPath = path.join(__dirname, 'wallet');
        const wallet = await Wallets.newFileSystemWallet(walletPath);
        await ca.enroll({
            enrollmentID: username,
            enrollmentSecret: password
        }).then(enrollment => {
            const identity = {
                credentials: {
                    certificate: enrollment.certificate,
                    privateKey: enrollment.key.toBytes()
                },
                mspId: `Org${org}MSP`,
                type: 'X.509'
            };
            return wallet.put(username, identity);
        });
        res.json({ message: 'Login successful' });
    } catch (error) {
        res.status(401).json({ error: 'Authentication failed: ' + error.message });
    }
});

app.post('/run-test', async (req, res) => {
    const { tps, txNumber, contract, users, iot, testMethod, testType, maxDistance, batchSize, timeout, channels } = req.body;

    let dockerCompose = fs.readFileSync('docker-compose.yml', 'utf8');
    dockerCompose = dockerCompose.replace(/MaxMessageCount: \d+/, `MaxMessageCount: ${batchSize}`);
    fs.writeFileSync('docker-compose.yml', dockerCompose);

    let benchmarkContent = `
test:
  name: 6g-fabric-benchmark
  description: Benchmark for 6G Fabric Network
  workers:
    type: local
    number: 1
  rounds:
    ${testType === 'invoke' || testType === 'both' ? `
    - label: invoke
      description: Test invoke performance
      txNumber: ${txNumber}
      rateControl:
        type: fixed-rate
        opts:
          tps: ${tps}
      workload:
        module: workload/${contract}.js` : ''}
    ${testType === 'query' || testType === 'both' ? `
    - label: query
      description: Test query performance
      txNumber: ${txNumber}
      rateControl:
        type: fixed-rate
        opts:
          tps: ${tps}
      workload:
        module: workload/${contract}.js` : ''}
  monitors:
    resource:
      - module: docker
        options:
          interval: 1
          containers:
            - orderer1.example.com
            - peer0.org1.example.com
            - peer0.org2.example.com
            - peer0.org3.example.com
            - peer0.org4.example.com
            - peer0.org5.example.com
            - peer0.org6.example.com
            - peer0.org7.example.com
            - peer0.org8.example.com
`;
    fs.writeFileSync('caliper-workspace/benchmarks/myAssetBenchmark.yaml', benchmarkContent);

    let workloadContent = fs.readFileSync(`caliper-workspace/workload/${contract}.js`, 'utf8');
    workloadContent = workloadContent.replace(/const entityID = .*/g, `const entityID = \`user\${this.workerIndex}_\${Math.floor(Math.random() * ${users})}\``);
    workloadContent = workloadContent.replace(/const antennaID = .*/g, `const antennaID = \`Antenna\${Math.floor(Math.random() * ${iot})}\``);
    if (contract.includes('LocationBased')) {
        workloadContent = workloadContent.replace(/timeout: \d+/g, `timeout: ${timeout}`);
        workloadContent += `
        async validateDistance() {
            const args = {
                contractId: this.chaincodeID,
                contractFunction: 'Validate${contract}Distance',
                contractArguments: [entityID, '${maxDistance}'],
                readOnly: true
            };
            await this.sutAdapter.sendRequests({
                contractId: this.chaincodeID,
                channel: this.channel,
                args: args,
                timeout: ${timeout}
            });
        }`;
    }
    fs.writeFileSync(`caliper-workspace/workload/${contract}.js`, workloadContent);

    let command = '';
    channels.forEach(channel => {
        if (testMethod === 'Caliper' || testMethod === 'Both') {
            command += `cd caliper-workspace && npx caliper launch manager --caliper-workspace . --caliper-networkconfig networks/networkConfig.yaml --caliper-benchconfig benchmarks/myAssetBenchmark.yaml --caliper-flow-only-test; `;
        }
        if (testMethod === 'Tape' || testMethod === 'Both') {
            command += `node ../generateTapeArgs.js && tape --config ../tape-config.yaml; `;
        }
    });

    exec(command, (error, stdout, stderr) => {
        if (error) {
            res.status(500).json({ error: stderr });
            return;
        }
        res.json({ output: stdout });
    });
});

app.get('/network-stats', async (req, res) => {
    try {
        const { gateway, network } = await connectToNetwork(1, 'admin-org1');
        const contract = network.getContract('qscc');
        const chainInfo = JSON.parse((await contract.evaluateTransaction('GetChainInfo', 'GeneralOperationsChannel')).toString());
        const blockCount = chainInfo.height;
        let txCount = 0;
        for (let i = 0; i < blockCount; i++) {
            const block = JSON.parse((await contract.evaluateTransaction('GetBlockByNumber', 'GeneralOperationsChannel', i.toString())).toString());
            txCount += block.data.transactions.length;
        }
        const tpsData = { labels: ['1m', '2m', '3m'], values: [5, 7, 6] }; // Replace with real data from Caliper
        const latencyData = { labels: ['1m', '2m', '3m'], values: [10, 12, 11] }; // Replace with real data
        res.json({ blockCount, txCount, tpsData, latencyData });
        gateway.disconnect();
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

app.get('/blocks', async (req, res) => {
    try {
        const { gateway, network } = await connectToNetwork(1, 'admin-org1');
        const contract = network.getContract('qscc');
        const chainInfo = JSON.parse((await contract.evaluateTransaction('GetChainInfo', 'GeneralOperationsChannel')).toString());
        const blocks = [];
        for (let i = 0; i < chainInfo.height; i++) {
            const block = JSON.parse((await contract.evaluateTransaction('GetBlockByNumber', 'GeneralOperationsChannel', i.toString())).toString());
            blocks.push({
                height: block.header.number,
                hash: block.header.data_hash,
                txCount: block.data.transactions.length,
                timestamp: new Date(block.data.transactions[0]?.timestamp).toISOString()
            });
        }
        res.json(blocks);
        gateway.disconnect();
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

app.get('/transactions', async (req, res) => {
    try {
        const { gateway, network } = await connectToNetwork(1, 'admin-org1');
        const contract = network.getContract('qscc');
        const chainInfo = JSON.parse((await contract.evaluateTransaction('GetChainInfo', 'GeneralOperationsChannel')).toString());
        const transactions = [];
        for (let i = 0; i < chainInfo.height; i++) {
            const block = JSON.parse((await contract.evaluateTransaction('GetBlockByNumber', 'GeneralOperationsChannel', i.toString())).toString());
            block.data.transactions.forEach(tx => {
                transactions.push({
                    id: tx.transaction_id,
                    contract: tx.payload?.chaincode_id || 'Unknown',
                    channel: 'GeneralOperationsChannel',
                    timestamp: new Date(tx.timestamp).toISOString()
                });
            });
        }
        res.json(transactions);
        gateway.disconnect();
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

app.get('/peers', (req, res) => {
    exec('docker ps -a --format "{{.Names}} {{.Status}}"', (error, stdout) => {
        if (error) {
            res.status(500).json({ error: error.message });
            return;
        }
        const peers = stdout.split('\n').filter(line => line.includes('peer0')).map(line => {
            const [name, status] = line.split(' ');
            return { name, status: status.includes('Up') ? 'Running' : 'Stopped' };
        });
        res.json(peers);
    });
});

app.get('/chaincodes', async (req, res) => {
    try {
        const { gateway, network } = await connectToNetwork(1, 'admin-org1');
        const contract = network.getContract('lifecycle');
        const chaincodes = [];
        const channels = ['Org1Channel', 'Org2Channel', 'Org3Channel', 'Org4Channel', 'Org5Channel', 'Org6Channel', 'Org7Channel', 'Org8Channel', 'GeneralOperationsChannel', 'IoTChannel', 'SecurityChannel', 'AuditChannel', 'BillingChannel', 'ResourceChannel', 'PerformanceChannel', 'SessionChannel', 'ConnectivityChannel', 'PolicyChannel'];
        for (const channel of channels) {
            const result = await contract.evaluateTransaction('GetChaincodes', channel);
            const chaincodeList = JSON.parse(result.toString());
            chaincodeList.forEach(cc => {
                chaincodes.push({ name: cc.name, version: cc.version, channel });
            });
        }
        res.json(chaincodes);
        gateway.disconnect();
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

app.post('/start-peer/:peer', (req, res) => {
    exec(`docker start ${req.params.peer}`, (error, stdout, stderr) => {
        if (error) return res.status(500).json({ error: stderr });
        res.json({ message: `Peer ${req.params.peer} started` });
    });
});

app.post('/stop-peer/:peer', (req, res) => {
    exec(`docker stop ${req.params.peer}`, (error, stdout, stderr) => {
        if (error) return res.status(500).json({ error: stderr });
        res.json({ message: `Peer ${req.params.peer} stopped` });
    });
});

app.post('/install-chaincode/:cc', (req, res) => {
    exec(`docker exec peer0.org1.example.com peer chaincode install -n ${req.params.cc} -v 1.0 -p github.com/chaincode/${req.params.cc}`, (error, stdout, stderr) => {
        if (error) return res.status(500).json({ error: stderr });
        res.json({ message: `Chaincode ${req.params.cc} installed` });
    });
});

app.post('/upgrade-chaincode/:cc', (req, res) => {
    exec(`docker exec peer0.org1.example.com peer chaincode upgrade -o orderer1.example.com:7050 --tls --cafile /crypto-config/ordererOrganizations/example.com/orderers/orderer1.example.com/msp/tlscacerts/tlsca.example.com-cert.pem -C GeneralOperationsChannel -n ${req.params.cc} -v 1.1 -c '{"Args":["init"]}'`, (error, stdout, stderr) => {
        if (error) return res.status(500).json({ error: stderr });
        res.json({ message: `Chaincode ${req.params.cc} upgraded` });
    });
});

app.get('/download-report', (req, res) => {
    res.download('caliper-workspace/report.html');
});

app.get('/download-tape-log', (req, res) => {
    res.download('tape.log');
});

app.post('/save-profile', (req, res) => {
    profiles.push(req.body);
    res.json({ message: `Profile ${req.body.name} saved` });
});

app.get('/load-profiles', (req, res) => {
    res.json(profiles);
});

app.get('/load-profile/:name', (req, res) => {
    const profile = profiles.find(p => p.name === req.params.name);
    if (!profile) return res.status(404).json({ error: 'Profile not found' });
    res.json(profile);
});

app.listen(port, () => {
    console.log(`Server running at https://165.232.71.90:${port}`);
});
