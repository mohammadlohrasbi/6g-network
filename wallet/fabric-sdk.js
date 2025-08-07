const { Gateway, Wallets } = require('fabric-network');
const fs = require('fs');
const path = require('path');
const yaml = require('js-yaml');

async function connectToNetwork(orgNumber = 1) {
    const walletPath = path.join(process.cwd(), 'wallet');
    const wallet = await Wallets.createFileSystemWallet(walletPath);

    const networkConfigPath = path.resolve(__dirname, '../config/networkConfig.yaml');
    const networkConfig = yaml.load(fs.readFileSync(networkConfigPath, 'utf8'));

    const gateway = new Gateway();
    await gateway.connect(networkConfig, {
        wallet,
        identity: `Admin@org${orgNumber}.example.com`,
        discovery: { enabled: true, asLocalhost: true }
    });

    return gateway;
}

async function invokeContract(channelName, contractName, functionName, orgNumber = 1, ...args) {
    const gateway = await connectToNetwork(orgNumber);
    try {
        const network = await gateway.getNetwork(channelName);
        const contract = network.getContract(contractName);
        const result = await contract.submitTransaction(functionName, ...args);
        return result.toString();
    } finally {
        await gateway.disconnect();
    }
}

async function queryContract(channelName, contractName, functionName, orgNumber = 1, ...args) {
    const gateway = await connectToNetwork(orgNumber);
    try {
        const network = await gateway.getNetwork(channelName);
        const contract = network.getContract(contractName);
        const result = await contract.evaluateTransaction(functionName, ...args);
        return JSON.parse(result.toString());
    } finally {
        await gateway.disconnect();
    }
}

module.exports = { connectToNetwork, invokeContract, queryContract };
