const { WorkloadModuleBase } = require('@hyperledger/caliper-core');

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
        const userID = `user${this.workerIndex}_${Math.floor(Math.random() * 1000)}`;
        const token = `token${Math.floor(Math.random() * 10000)}`;

        const args = {
            contractId: this.chaincodeID,
            contractFunction: 'AuthenticateUser',
            contractArguments: [userID, token],
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
    return new AuthenticateUserWorkload();
}

module.exports.createWorkloadModule = createWorkloadModule;
