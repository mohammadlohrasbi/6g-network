'use strict';

const { WorkloadModuleBase } = require('@hyperledger/caliper-core');
const { generateRandomID, generateRandomCoords } = require('./utils.js');

class LocationBasedAssignmentWorkload extends WorkloadModuleBase {
    constructor() {
        super();
        this.chaincodeID = 'LocationBasedAssignment';
        this.channel = 'GeneralOperationsChannel';
        this.centerX = 0;
        this.centerY = 0;
        this.sideLength = 100;
    }

    async initializeWorkloadModule(workerIndex, totalWorkers, roundIndex, roundArguments, sutAdapter, sutContext) {
        await super.initializeWorkloadModule(workerIndex, totalWorkers, roundIndex, roundArguments, sutAdapter, sutContext);
        this.centerX = roundArguments.centerX || 0;
        this.centerY = roundArguments.centerY || 0;
        this.sideLength = roundArguments.sideLength || 100;
    }

    async submitTransaction() {
        const entityID = generateRandomID('user', 1000);
        const antennaID = generateRandomID('Antenna', 100);
        const { x, y } = generateRandomCoords(this.centerX, this.centerY, this.sideLength);
        const args = {
            contractId: this.chaincodeID,
            contractFunction: 'CreateAsset',
            contractArguments: [entityID, antennaID, x, y, '100'],
            readOnly: false
        };
        await this.sutAdapter.sendRequests({
            contractId: this.chaincodeID,
            channel: this.channel,
            args: args,
            timeout: 30
        });
    }

    async cleanupWorkloadModule() {}
}

function createWorkloadModule() {
    return new LocationBasedAssignmentWorkload();
}

module.exports.createWorkloadModule = createWorkloadModule;
