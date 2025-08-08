const express = require('express');
const { invokeContract, queryContract } = require('./utils.js');
const fs = require('fs');
const path = require('path');
const yaml = require('js-yaml');
const { execSync } = require('child_process');

const app = express();

app.use(express.static('public'));
app.use(express.json());

app.post('/invoke', async (req, res) => {
    const { channelName, contractName, functionName, orgNumber, args } = req.body;
    try {
        const result = await invokeContract(channelName, contractName, functionName, orgNumber || 1, ...args);
        res.json({ status: 'success', result });
    } catch (error) {
        res.status(500).json({ status: 'error', error: error.message });
    }
});

app.get('/query', async (req, res) => {
    const { channelName, contractName, functionName, orgNumber, args } = req.query;
    try {
        const result = await queryContract(channelName, contractName, functionName, orgNumber || 1, ...args);
        res.json({ status: 'success', result });
    } catch (error) {
        res.status(500).json({ status: 'error', error: error.message });
    }
});

app.get('/contracts', (req, res) => {
    const contracts = [
        'AssetManagement', 'UserManagement', 'IoTManagement', 'AntennaManagement', 'NetworkManagement',
        'ResourceManagement', 'PerformanceManagement', 'SessionManagement', 'PolicyManagement',
        'LocationBasedAccess', 'LocationBasedResource', 'LocationBasedPerformance', 'LocationBasedSession',
        'LocationBasedPolicy', 'LocationBasedConnectivity', 'LocationBasedAudit', 'LocationBasedSecurity',
        'LocationBasedNetwork', 'LocationBasedCongestion', 'LocationBasedIoTConnection',
        'LocationBasedIoTPerformance', 'LocationBasedIoTSecurity', 'LocationBasedIoTAudit',
        'LocationBasedIoTAccess', 'LocationBasedIoTResource', 'LocationBasedIoTNetwork',
        'LocationBasedIoTActivity', 'LocationBasedIoTBandwidth', 'LocationBasedIoTStatus',
        'LocationBasedIoTFault', 'LocationBasedIoTSession', 'LocationBasedIoTAuthentication',
        'LocationBasedIoTRegistration', 'LocationBasedIoTRevocation', 'LocationBasedIoTResource',
        'LocationBasedUserActivity', 'AuthenticateUser', 'AuthenticateIoT', 'ConnectUser', 'ConnectIoT',
        'RegisterUser', 'RegisterIoT', 'RevokeUser', 'RevokeIoT', 'AssignRole', 'MonitorNetwork',
        'MonitorIoT', 'LogFault', 'LogPerformance', 'LogSession', 'LogTraffic', 'LogInterference',
        'LogResourceAudit', 'BalanceLoad', 'AllocateResource', 'OptimizeNetwork', 'ManageSession',
        'LogNetworkPerformance', 'LogUserActivity', 'LogIoTActivity', 'LogSessionAudit',
        'LogConnectionAudit', 'EncryptData', 'DecryptData', 'SecureCommunication', 'VerifyIdentity',
        'SetPolicy', 'GetPolicy', 'UpdatePolicy', 'LogPolicyAudit', 'ManageNetwork', 'ManageAntenna',
        'ManageIoTDevice', 'ManageUser', 'MonitorTraffic', 'MonitorInterference', 'MonitorResourceUsage',
        'LogSecurityEvent', 'LogAccessControl', 'LogNetworkAudit', 'LogAntennaAudit', 'LogIoTAudit',
        'LogUserAudit', 'LogPolicyChange', 'LogAccessAudit', 'LogPerformanceAudit', 'LogComplianceAudit'
    ];
    res.json({ contracts });
});

app.post('/set-org-count', (req, res) => {
    const { orgCount } = req.body;
    if (!orgCount || isNaN(orgCount) || orgCount < 1) {
        return res.status(400).json({ status: 'error', error: 'Invalid orgCount' });
    }
    try {
        // به‌روزرسانی ORG_COUNT و تولید مجدد فایل‌های پیکربندی
        execSync(`export ORG_COUNT=${orgCount} && cd scripts && ./generateConnectionJson.sh && ./generateConnectionProfiles.sh && ./generateCoreyamls.sh && ./setup.sh`, { stdio: 'inherit' });
        res.json({ status: 'success', message: `Network reconfigured for ${orgCount} organizations` });
    } catch (error) {
        res.status(500).json({ status: 'error', error: error.message });
    }
});

app.get('/org-count', (req, res) => {
    const orgCount = process.env.ORG_COUNT || '8';
    res.json({ orgCount: parseInt(orgCount) });
});

app.listen(3000, () => {
    console.log('Server running on http://localhost:3000');
});
