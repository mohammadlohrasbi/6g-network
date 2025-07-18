'use strict';

const { WorkloadModuleBase } = require('@hyperledger/caliper-core');
const { generateRandomID } = require('./utils.js');

class AuthenticateUserWorkload extends WorkloadModuleBase {
    constructor() {
        super();
        this.chaincodeID = 'AuthenticateUser';
        this.channel = 'SecurityChannel';
    }

    async initializeWorkloadModule(workerIndex, totalWorkers, roundIndex, roundArguments, sutAdapter, sutContext) {
        await super.initializeWorkloadModule(workerIndex, totalWorkers, roundIndex, roundArguments, sutAdapter, sutContext);
    }

    async submitTransaction() {
        const entityID = generateRandomID('user', 1000);
        const token = generateRandomID('token', 1000);
        const args = {
            contractId: this.chaincodeID,
            contractFunction: 'CreateAsset
