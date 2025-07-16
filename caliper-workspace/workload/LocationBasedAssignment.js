const { WorkloadModuleBase } = require('@hyperledger/caliper-core');

class LocationBasedAssignmentWorkload extends WorkloadModuleBase {
    constructor() {
        super();
        this.chaincodeID = 'LocationBasedAssignment';
        this.channel = 'GeneralOperationsChannel';
    }

    async initializeWorkloadModule(workerIndex, totalWorkers, roundIndex, roundArguments, sutAdapter, sutContext) {
        await super.initializeWorkloadModule(workerIndex, totalWorkers, roundIndex, roundArguments, sutAdapter, sutContext);
    }

    async submitTransaction() {
        const entityID = `user${this.workerIndex}_${Math.floor(Math.random() * 1000)}`;
        const antennaID = `Antenna${Math.floor(Math.random() * 100)}`;
        const x = (Math.random() * 180 - 90).toFixed(4); // Random latitude [-90, 90]
        const y = (Math.random() * 360 - 180).toFixed(4); // Random longitude [-180, 180]

        const args = {
            contractId: this.chaincodeID,
            contractFunction: 'AssignAntenna',
            contractArguments: [entityID, antennaID, x, y],
            readOnly: false
        };

        await this.sutAdapter.sendRequests({
            contractId: this.chaincodeID,
            channel: this.channel,
            args: args,
            timeout: 30
        });
    }

    async cleanupWorkloadModule() {
        // Cleanup logic if needed
    }
}

function createWorkloadModule() {
    return new LocationBasedAssignmentWorkload();
}

module.exports.createWorkloadModule = createWorkloadModule;
