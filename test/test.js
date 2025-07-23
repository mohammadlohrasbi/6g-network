const { invokeContract, queryContract } = require('../web/fabric-sdk.js');
const fs = require('fs');
const path = require('path');

async function runTests() {
    const workload = JSON.parse(fs.readFileSync(path.resolve(__dirname, 'workloads/workload.json'), 'utf8'));
    const { numUsers, numTx, targetTPS, contracts } = workload;

    console.log(`Starting scalability test: ${numUsers} users/IoT, ${numTx} transactions, target TPS=${targetTPS}`);

    const startTime = Date.now();
    const promises = [];

    for (let i = 0; i < numTx; i++) {
        for (const contract of contracts) {
            const { channel, contract: contractName, function: functionName, argsTemplate } = contract;
            const args = argsTemplate.map(arg => {
                if (arg.includes('{id}')) return arg.replace('{id}', (i % numUsers).toString());
                if (arg.includes('{rand:')) {
                    const [_, range, offset] = arg.match(/{rand:(\d+):?(-?\d+)?}/);
                    const min = offset ? parseInt(offset) : 0;
                    const max = parseInt(range) + min;
                    return (Math.random() * (max - min) + min).toFixed(4);
                }
                return arg;
            });

            promises.push(invokeContract(channel, contractName, functionName, ...args));

            if (promises.length >= targetTPS) {
                await Promise.all(promises);
                promises.length = 0;
                await new Promise(resolve => setTimeout(resolve, 1000 / targetTPS));
            }
        }
    }

    await Promise.all(promises);

    const endTime = Date.now();
    const duration = (endTime - startTime) / 1000;
    const actualTPS = numTx / duration;

    console.log(`Test completed in ${duration} seconds`);
    console.log(`Achieved TPS: ${actualTPS.toFixed(2)}`);

    // Query sample data
    const result = await queryContract('IoTChannel', 'LocationBasedIoTBandwidth', 'QueryAllAssets');
    console.log('Sample query result:', result.slice(0, 5));
}

runTests().catch(console.error);
