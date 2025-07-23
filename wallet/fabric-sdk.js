const { Wallets, Gateway } = require('fabric-network');
const fs = require('fs');
const path = require('path');

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

async function getBlocks(channelName, org, username) {
    const { gateway, network } = await connectToNetwork(org, username);
    const contract = network.getContract('qscc');
    const chainInfo = JSON.parse((await contract.evaluateTransaction('GetChainInfo', channelName)).toString());
    const blocks = [];
    for (let i = 0; i < chainInfo.height; i++) {
        const block = JSON.parse((await contract.evaluateTransaction('GetBlockByNumber', channelName, i.toString())).toString());
        blocks.push({
            height: block.header.number,
            hash: block.header.data_hash,
            txCount: block.data.transactions.length,
            timestamp: new Date(block.data.transactions[0]?.timestamp).toISOString()
        });
    }
    gateway.disconnect();
    return blocks;
}

async function getTransactions(channelName, org, username) {
    const { gateway, network } = await connectToNetwork(org, username);
    const contract = network.getContract('qscc');
    const chainInfo = JSON.parse((await contract.evaluateTransaction('GetChainInfo', channelName)).toString());
    const transactions = [];
    for (let i = 0; i < chainInfo.height; i++) {
        const block = JSON.parse((await contract.evaluateTransaction('GetBlockByNumber', channelName, i.toString())).toString());
        block.data.transactions.forEach(tx => {
            transactions.push({
                id: tx.transaction_id,
                contract: tx.payload?.chaincode_id || 'Unknown',
                channel: channelName,
                timestamp: new Date(tx.timestamp).toISOString()
            });
        });
    }
    gateway.disconnect();
    return transactions;
}

module.exports = { connectToNetwork, getBlocks, getTransactions };
