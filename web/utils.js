const { Gateway, Wallets } = require('fabric-network');
const fs = require('fs');
const path = require('path');
const yaml = require('js-yaml');

async function connectToNetwork() {
    const walletPath = path.join(process.cwd(), 'wallet');
    const wallet = await Wallets.createFileSystemWallet(walletPath);

    const networkConfigPath = path.resolve(__dirname, '../config/networkConfig.yaml');
    const networkConfig = yaml.load(fs.readFileSync(networkConfigPath, 'utf8'));

    const gateway = new Gateway();
    await gateway.connect(networkConfig, {
        wallet,
        identity: 'Admin@org1.example.com',
        discovery: { enabled: true, asLocalhost: true }
    });

    return gateway;
}

async function invokeContract(channelName, contractName, functionName, ...args) {
    try {
        const gateway = await connectToNetwork();
        const network = await gateway.getNetwork(channelName);
        const contract = network.getContract(contractName);

        const result = await contract.submitTransaction(functionName, ...args);
        await gateway.disconnect();

        return result.toString();
    } catch (error) {
        console.error(`Failed to invoke ${functionName}: ${error}`);
        throw error;
    }
}

async function queryContract(channelName, contractName, functionName, ...args) {
    try {
        const gateway = await connectToNetwork();
        const network = await gateway.getNetwork(channelName);
        const contract = network.getContract(contractName);

        const result = await contract.evaluateTransaction(functionName, ...args);
        await gateway.disconnect();

        return JSON.parse(result.toString());
    } catch (error) {
        console.error(`Failed to query ${functionName}: ${error}`);
        throw error;
    }
}

module.exports = { invokeContract, queryContract };
