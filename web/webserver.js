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

app.get('/org-count', (req, res) => {
    const orgCount = process.env.ORG_COUNT || '8';
    res.json({ orgCount: parseInt(orgCount) });
});

app.post('/set-org-count', (req, res) => {
    const { orgCount } = req.body;
    if (!orgCount || isNaN(orgCount) || orgCount < 1) {
        return res.status(400).json({ status: 'error', error: 'Invalid orgCount' });
    }
    try {
        execSync(`export ORG_COUNT=${orgCount} && cd scripts && ./generateConnectionJson.sh && ./generateConnectionProfiles.sh && ./generateCoreyamls.sh && ./setup.sh`, { stdio: 'inherit' });
        res.json({ status: 'success', message: `Network reconfigured for ${orgCount} organizations` });
    } catch (error) {
        res.status(500).json({ status: 'error', error: error.message });
    }
});

app.post('/run-test', (req, res) => {
    const { orgCount, contractCount, channelCount, tps, txNumber, users } = req.body;
    if (!orgCount || !contractCount || !channelCount || !tps || !txNumber || !users) {
        return res.status(400).json({ status: 'error', error: 'Missing required parameters' });
    }
    try {
        // تولید workload.json پویا
        const channels = [
            'NetworkChannel', 'ResourceChannel', 'PerformanceChannel', 'IoTChannel', 'AuthChannel',
            'ConnectivityChannel', 'SessionChannel', 'PolicyChannel', 'AuditChannel', 'SecurityChannel',
            'DataChannel', 'AnalyticsChannel', 'MonitoringChannel', 'ManagementChannel', 'OptimizationChannel',
            'FaultChannel', 'TrafficChannel', 'AccessChannel', 'ComplianceChannel', 'IntegrationChannel'
        ].slice(0, channelCount);
        const contracts = [
            { name: 'AssetManagement', channel: 'NetworkChannel', function: 'CreateAsset', args: ['asset{id}', 'Network', '{rand:1000}'] },
            { name: 'UserManagement', channel: 'NetworkChannel', function: 'CreateUser', args: ['user{id}', 'role{rand:1000}'] },
            { name: 'IoTManagement', channel: 'NetworkChannel', function: 'RegisterIoT', args: ['iot{id}', '{rand:1000}'] },
            { name: 'AntennaManagement', channel: 'NetworkChannel', function: 'RegisterAntenna', args: ['antenna{id}', '{rand:180:-90}', '{rand:360:-180}'] },
            { name: 'NetworkManagement', channel: 'NetworkChannel', function: 'ConfigureNetwork', args: ['network{id}', '{rand:1000}'] },
            { name: 'ResourceManagement', channel: 'NetworkChannel', function: 'AllocateResource', args: ['resource{id}', '{rand:100}'] },
            { name: 'PerformanceManagement', channel: 'NetworkChannel', function: 'LogPerformance', args: ['entity{id}', '{rand:100}'] },
            { name: 'SessionManagement', channel: 'NetworkChannel', function: 'CreateSession', args: ['session{id}', '{rand:1000}'] },
            { name: 'PolicyManagement', channel: 'NetworkChannel', function: 'SetPolicy', args: ['policy{id}', 'rule{rand:1000}'] },
            { name: 'LocationBasedAccess', channel: 'ResourceChannel', function: 'GrantAccess', args: ['entity{id}', '{rand:180:-90}', '{rand:360:-180}'] },
            { name: 'LocationBasedResource', channel: 'ResourceChannel', function: 'Allocate', args: ['entity{id}', 'resource{rand:1000}', '{rand:100}', '{rand:180:-90}', '{rand:360:-180}'] },
            { name: 'LocationBasedPerformance', channel: 'ResourceChannel', function: 'Log', args: ['entity{id}', '{rand:100}', '{rand:180:-90}', '{rand:360:-180}'] },
            { name: 'LocationBasedSession', channel: 'ResourceChannel', function: 'Create', args: ['session{id}', '{rand:180:-90}', '{rand:360:-180}'] },
            { name: 'LocationBasedPolicy', channel: 'ResourceChannel', function: 'Set', args: ['policy{id}', 'rule{rand:1000}', '{rand:180:-90}', '{rand:360:-180}'] },
            { name: 'LocationBasedConnectivity', channel: 'ResourceChannel', function: 'Connect', args: ['entity{id}', '{rand:180:-90}', '{rand:360:-180}'] },
            { name: 'LocationBasedAudit', channel: 'ResourceChannel', function: 'Log', args: ['entity{id}', 'event{rand:1000}', '{rand:180:-90}', '{rand:360:-180}'] },
            { name: 'LocationBasedSecurity', channel: 'ResourceChannel', function: 'Secure', args: ['entity{id}', '{rand:180:-90}', '{rand:360:-180}'] },
            { name: 'LocationBasedNetwork', channel: 'ResourceChannel', function: 'Configure', args: ['network{id}', '{rand:180:-90}', '{rand:360:-180}'] },
            { name: 'LocationBasedCongestion', channel: 'ResourceChannel', function: 'Monitor', args: ['network{id}', '{rand:100}', '{rand:180:-90}', '{rand:360:-180}'] },
            { name: 'LocationBasedIoTConnection', channel: 'IoTChannel', function: 'Connect', args: ['iot{id}', 'network{rand:1000}', '{rand:180:-90}', '{rand:360:-180}'] },
            { name: 'LocationBasedIoTPerformance', channel: 'IoTChannel', function: 'Log', args: ['iot{id}', '{rand:100}', '{rand:180:-90}', '{rand:360:-180}'] },
            { name: 'LocationBasedIoTSecurity', channel: 'IoTChannel', function: 'Secure', args: ['iot{id}', '{rand:180:-90}', '{rand:360:-180}'] },
            { name: 'LocationBasedIoTAudit', channel: 'IoTChannel', function: 'Log', args: ['iot{id}', 'event{rand:1000}', '{rand:180:-90}', '{rand:360:-180}'] },
            { name: 'LocationBasedIoTAccess', channel: 'IoTChannel', function: 'GrantAccess', args: ['iot{id}', '{rand:180:-90}', '{rand:360:-180}'] },
            { name: 'LocationBasedIoTResource', channel: 'IoTChannel', function: 'Allocate', args: ['iot{id}', 'resource{rand:1000}', '{rand:180:-90}', '{rand:360:-180}'] },
            { name: 'LocationBasedIoTNetwork', channel: 'IoTChannel', function: 'Configure', args: ['iot{id}', '{rand:180:-90}', '{rand:360:-180}'] },
            { name: 'LocationBasedIoTActivity', channel: 'IoTChannel', function: 'Log', args: ['iot{id}', 'activity{rand:1000}', '{rand:180:-90}', '{rand:360:-180}'] },
            { name: 'LocationBasedIoTBandwidth', channel: 'IoTChannel', function: 'AllocateIoTBandwidth', args: ['iot{id}', 'Antenna{rand:10}', '{rand:100}Mbps', '{rand:180:-90}', '{rand:360:-180}'] },
            { name: 'LocationBasedIoTStatus', channel: 'IoTChannel', function: 'UpdateStatus', args: ['iot{id}', 'status{rand:1000}', '{rand:180:-90}', '{rand:360:-180}'] },
            { name: 'LocationBasedIoTFault', channel: 'IoTChannel', function: 'LogFault', args: ['iot{id}', 'fault{rand:1000}', '{rand:180:-90}', '{rand:360:-180}'] },
            { name: 'LocationBasedIoTSession', channel: 'IoTChannel', function: 'CreateSession', args: ['iot{id}', '{rand:180:-90}', '{rand:360:-180}'] },
            { name: 'LocationBasedIoTAuthentication', channel: 'IoTChannel', function: 'Authenticate', args: ['iot{id}', 'credential{rand:1000}', '{rand:180:-90}', '{rand:360:-180}'] },
            { name: 'LocationBasedIoTRegistration', channel: 'IoTChannel', function: 'Register', args: ['iot{id}', '{rand:180:-90}', '{rand:360:-180}'] },
            { name: 'LocationBasedIoTRevocation', channel: 'IoTChannel', function: 'Revoke', args: ['iot{id}', '{rand:180:-90}', '{rand:360:-180}'] },
            { name: 'LocationBasedIoTResource', channel: 'IoTChannel', function: 'Allocate', args: ['iot{id}', 'resource{rand:1000}', '{rand:180:-90}', '{rand:360:-180}'] },
            { name: 'LocationBasedUserActivity', channel: 'IoTChannel', function: 'Log', args: ['user{id}', 'activity{rand:1000}', '{rand:180:-90}', '{rand:360:-180}'] },
            { name: 'AuthenticateUser', channel: 'AuthChannel', function: 'Authenticate', args: ['user{id}', 'password{rand:1000}'] },
            { name: 'AuthenticateIoT', channel: 'AuthChannel', function: 'Authenticate', args: ['iot{id}', 'credential{rand:1000}'] },
            { name: 'ConnectUser', channel: 'ConnectivityChannel', function: 'Connect', args: ['user{id}', 'network{rand:1000}'] },
            { name: 'ConnectIoT', channel: 'ConnectivityChannel', function: 'Connect', args: ['iot{id}', 'network{rand:1000}'] },
            { name: 'RegisterUser', channel: 'AuthChannel', function: 'Register', args: ['user{id}', 'role{rand:1000}'] },
            { name: 'RegisterIoT', channel: 'AuthChannel', function: 'Register', args: ['iot{id}', 'type{rand:1000}'] },
            { name: 'RevokeUser', channel: 'AuthChannel', function: 'Revoke', args: ['user{id}'] },
            { name: 'RevokeIoT', channel: 'AuthChannel', function: 'Revoke', args: ['iot{id}'] },
            { name: 'AssignRole', channel: 'AuthChannel', function: 'Assign', args: ['user{id}', 'role{rand:1000}'] },
            { name: 'MonitorNetwork', channel: 'MonitoringChannel', function: 'Monitor', args: ['network{id}', '{rand:100}'] },
            { name: 'MonitorIoT', channel: 'MonitoringChannel', function: 'Monitor', args: ['iot{id}', '{rand:100}'] },
            { name: 'LogFault', channel: 'AuditChannel', function: 'Log', args: ['entity{id}', 'fault{rand:1000}'] },
            { name: 'LogPerformance', channel: 'AuditChannel', function: 'Log', args: ['entity{id}', '{rand:100}'] },
            { name: 'LogSession', channel: 'AuditChannel', function: 'Log', args: ['session{id}', 'start', '{rand:1000}'] },
            { name: 'LogTraffic', channel: 'AuditChannel', function: 'Log', args: ['network{id}', '{rand:100}'] },
            { name: 'LogInterference', channel: 'AuditChannel', function: 'Log', args: ['network{id}', '{rand:100}'] },
            { name: 'LogResourceAudit', channel: 'AuditChannel', function: 'Log', args: ['resource{id}', '{rand:1000}'] },
            { name: 'BalanceLoad', channel: 'ManagementChannel', function: 'Balance', args: ['network{id}', '{rand:100}'] },
            { name: 'AllocateResource', channel: 'ManagementChannel', function: 'Allocate', args: ['resource{id}', '{rand:100}'] },
            { name: 'OptimizeNetwork', channel: 'ManagementChannel', function: 'Optimize', args: ['network{id}', '{rand:100}'] },
            { name: 'ManageSession', channel: 'ManagementChannel', function: 'Manage', args: ['session{id}', '{rand:1000}'] },
            { name: 'LogNetworkPerformance', channel: 'AuditChannel', function: 'Log', args: ['network{id}', '{rand:100}'] },
            { name: 'LogUserActivity', channel: 'AuditChannel', function: 'Log', args: ['user{id}', 'activity{rand:1000}'] },
            { name: 'LogIoTActivity', channel: 'AuditChannel', function: 'Log', args: ['iot{id}', 'activity{rand:1000}'] },
            { name: 'LogSessionAudit', channel: 'AuditChannel', function: 'Log', args: ['session{id}', '{rand:1000}'] },
            { name: 'LogConnectionAudit', channel: 'AuditChannel', function: 'Log', args: ['connection{id}', '{rand:1000}'] },
            { name: 'EncryptData', channel: 'SecurityChannel', function: 'Encrypt', args: ['entity{id}', 'data{rand:1000}'] },
            { name: 'DecryptData', channel: 'SecurityChannel', function: 'Decrypt', args: ['entity{id}', 'data{rand:1000}'] },
            { name: 'SecureCommunication', channel: 'SecurityChannel', function: 'Secure', args: ['entity{id}', '{rand:1000}'] },
            { name: 'VerifyIdentity', channel: 'SecurityChannel', function: 'Verify', args: ['entity{id}', 'credential{rand:1000}'] },
            { name: 'SetPolicy', channel: 'SecurityChannel', function: 'Set', args: ['policy{id}', 'rule{rand:1000}'] },
            { name: 'GetPolicy', channel: 'SecurityChannel', function: 'Get', args: ['policy{id}'] },
            { name: 'UpdatePolicy', channel: 'SecurityChannel', function: 'Update', args: ['policy{id}', 'rule{rand:1000}'] },
            { name: 'LogPolicyAudit', channel: 'SecurityChannel', function: 'Log', args: ['policy{id}', 'event{rand:1000}'] },
            { name: 'ManageNetwork', channel: 'ManagementChannel', function: 'Manage', args: ['network{id}', '{rand:1000}'] },
            { name: 'ManageAntenna', channel: 'ManagementChannel', function: 'Manage', args: ['antenna{id}', '{rand:180:-90}', '{rand:360:-180}'] },
            { name: 'ManageIoTDevice', channel: 'ManagementChannel', function: 'Manage', args: ['iot{id}', '{rand:1000}'] },
            { name: 'ManageUser', channel: 'ManagementChannel', function: 'Manage', args: ['user{id}', '{rand:1000}'] },
            { name: 'MonitorTraffic', channel: 'MonitoringChannel', function: 'Monitor', args: ['network{id}', '{rand:100}'] },
            { name: 'MonitorInterference', channel: 'MonitoringChannel', function: 'Monitor', args: ['network{id}', '{rand:100}'] },
            { name: 'MonitorResourceUsage', channel: 'MonitoringChannel', function: 'Monitor', args: ['resource{id}', '{rand:100}'] },
            { name: 'LogSecurityEvent', channel: 'AuditChannel', function: 'Log', args: ['event{id}', '{rand:1000}'] },
            { name: 'LogAccessControl', channel: 'AuditChannel', function: 'Log', args: ['access{id}', '{rand:1000}'] },
            { name: 'LogNetworkAudit', channel: 'AuditChannel', function: 'Log', args: ['network{id}', '{rand:1000}'] },
            { name: 'LogAntennaAudit', channel: 'AuditChannel', function: 'Log', args: ['antenna{id}', '{rand:1000}'] },
            { name: 'LogIoTAudit', channel: 'AuditChannel', function: 'Log', args: ['iot{id}', '{rand:1000}'] },
            { name: 'LogUserAudit', channel: 'AuditChannel', function: 'Log', args: ['user{id}', '{rand:1000}'] },
            { name: 'LogPolicyChange', channel: 'AuditChannel', function: 'Log', args: ['policy{id}', '{rand:1000}'] },
            { name: 'LogAccessAudit', channel: 'AuditChannel', function: 'Log', args: ['access{id}', '{rand:1000}'] },
            { name: 'LogPerformanceAudit', channel: 'AuditChannel', function: 'Log', args: ['entity{id}', 'Latency', '{rand:100}ms'] },
            { name: 'LogComplianceAudit', channel: 'AuditChannel', function: 'Log', args: ['compliance{id}', '{rand:1000}'] }
        ].slice(0, contractCount);

        const workload = {
            numUsers: parseInt(users),
            numTx: parseInt(txNumber),
            targetTPS: parseInt(tps),
            contracts: contracts.map(({ name, channel, function: func, args }) => ({
                channel: channels[Math.min(channels.length - 1, Math.floor(Math.random() * channelCount))],
                contract: name,
                function: func,
                argsTemplate: args
            }))
        };

        fs.writeFileSync(path.resolve(__dirname, '../test/workloads/workload.json'), JSON.stringify(workload, null, 2));

        // اجرای تست
        execSync(`cd test && node test.js`, { stdio: 'inherit' });

        res.json({ status: 'success', message: `Test completed with ${contractCount} contracts, ${channelCount} channels, TPS=${tps}, txNumber=${txNumber}, users=${users}` });
    } catch (error) {
        res.status(500).json({ status: 'error', error: error.message });
    }
});

app.listen(3000, () => {
    console.log('Server running on http://localhost:3000');
});
