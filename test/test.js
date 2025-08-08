const { invokeContract, queryContract } = require('../web/utils.js');
const fs = require('fs');
const path = require('path');

async function runTests() {
    const workload = JSON.parse(fs.readFileSync(path.resolve(__dirname, 'workloads/workload.json'), 'utf8'));
    const { numUsers, numTx, targetTPS, contracts } = workload;
    const orgCount = parseInt(process.env.ORG_COUNT || '8');

    console.log(`Starting scalability test: ${numUsers} users/IoT, ${numTx} transactions, target TPS=${targetTPS}, ${orgCount} organizations, ${contracts.length} contracts`);

    const startTime = Date.now();
    const promises = [];

    for (let i = 0; i < numTx; i++) {
        for (let org = 1; org <= orgCount; org++) {
            for (const contract of contracts) {
                const { channel, contract: contractName, function: functionName, argsTemplate } = contract;
                const args = argsTemplate.map(arg => {
                    if (arg.includes('{id}')) return arg.replace('{id}', (i % numUsers).toString());
                    if (arg.includes('{rand:')) {
                        const [_, range, offset] = arg.match(/{rand:(\d+):?(-?\d+)?}/) || [null, 100, 0];
                        const min = offset ? parseInt(offset) : 0;
                        const max = parseInt(range) + min;
                        return (Math.random() * (max - min) + min).toFixed(4);
                    }
                    return arg;
                });

                promises.push(invokeContract(channel, contractName, functionName, org, ...args));

                if (promises.length >= targetTPS) {
                    await Promise.all(promises);
                    promises.length = 0;
                    await new Promise(resolve => setTimeout(resolve, 1000 / targetTPS));
                }
            }
        }
    }

    await Promise.all(promises);

    const endTime = Date.now();
    const duration = (endTime - startTime) / 1000;
    const actualTPS = numTx / duration;

    console.log(`Test completed in ${duration} seconds`);
    console.log(`Achieved TPS: ${actualTPS.toFixed(2)}`);

    // Query sample data from Org1 for a few contracts
    const sampleContracts = ['LocationBasedIoTBandwidth', 'AssetManagement', 'AuthenticateUser'];
    for (const contract of sampleContracts) {
        const channelMap = {
            'AssetManagement': 'NetworkChannel',
            'AuthenticateUser': 'AuthChannel',
            'LocationBasedIoTBandwidth': 'IoTChannel'
        };
        const channel = channelMap[contract] || 'DataChannel';
        const result = await queryContract(channel, contract, 'QueryAllAssets', 1);
        console.log(`Sample query result for ${contract} from Org1:`, result.slice(0, 5));
    }
}

runTests().catch(console.error);
