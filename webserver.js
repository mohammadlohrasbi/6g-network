const express = require('express');
const { exec } = require('child_process');
const fs = require('fs');
const app = express();
const port = 3000;

app.use(express.json());
app.use(express.static('.')); // برای index.html و report.html

app.post('/run-test', (req, res) => {
    const { tps, txNumber, contract, users, iot, channels, testMethod } = req.body;
    // تنظیم myAssetBenchmark.yaml بر اساس متغیرها
    let benchmarkContent = `
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
    - label: query
      description: Test query performance
      txNumber: ${txNumber}
      rateControl:
        type: fixed-rate
        opts:
          tps: ${tps}
      workload:
        module: workload/${contract}.js
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

    // تنظیم تعداد کاربران و IoT در workload.js
    let workloadContent = fs.readFileSync(`caliper-workspace/workload/${contract}.js`, 'utf8');
    workloadContent = workloadContent.replace(/const entityID = .*/g, `const entityID = \`user\${this.workerIndex}_\${Math.floor(Math.random() * ${users})}\``);
    workloadContent = workloadContent.replace(/const antennaID = .*/g, `const antennaID = \`Antenna\${Math.floor(Math.random() * ${iot})}\``);
    fs.writeFileSync(`caliper-workspace/workload/${contract}.js`, workloadContent);

    // اجرای تست Caliper یا Tape یا هر دو
    let command = '';
    if (testMethod === 'Caliper' || testMethod === 'Both') {
        command += `cd caliper-workspace && npx caliper launch manager --caliper-workspace . --caliper-networkconfig networks/networkConfig.yaml --caliper-benchconfig benchmarks/myAssetBenchmark.yaml; `;
    }
    if (testMethod === 'Tape' || testMethod === 'Both') {
        command += `node ../generateTapeArgs.js && tape --config ../tape-config.yaml; `;
    }
    exec(command, (error, stdout, stderr) => {
        if (error) {
            res.status(500).send({ error: stderr });
            return;
        }
        res.send({ output: stdout });
    });
});

app.get('/report', (req, res) => {
    fs.readFile('caliper-workspace/report.html', 'utf8', (err, data) => {
        if (err) {
            res.status(500).send({ error: 'Failed to read report' });
            return;
        }
        res.send(data);
    });
});

app.get('/tape-log', (req, res) => {
    fs.readFile('tape.log', 'utf8', (err, data) => {
        if (err) {
            res.status(500).send({ error: 'Failed to read tape log' });
            return;
        }
        res.send(data);
    });
});

app.listen(port, () => {
    console.log(`Server running at http://6gfabric.local:${port}`);
});
