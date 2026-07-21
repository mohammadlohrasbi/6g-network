#!/bin/bash
# setup-test-interface.sh - Create test interface files

set -e

echo "========================================="
echo "Setting up Test Interface"
echo "=========================================="

GREEN='\033[0;32m'
NC='\033[0m'

PUBLIC_DIR="/root/6g-network/public"
SERVER_DIR="/root/6g-network/server"

# NOTE: test.html and test-app.js are now maintained manually in ${PUBLIC_DIR}.
# Their auto-generation was removed so manual edits (dashboard back-link, header)
# are not overwritten on each run.

# Create Caliper workload templates
WORKLOAD_DIR="/root/6g-network/caliper/workload"
mkdir -p "${WORKLOAD_DIR}"

# --- RegisterIoT ---
cat > "${WORKLOAD_DIR}/RegisterIoT.js" << 'EOF'
'use strict';

const { WorkloadModuleBase } = require('@hyperledger/caliper-core');

class RegisterIoTWorkload extends WorkloadModuleBase {
    async initializeWorkloadModule(workerIndex, totalWorkers, roundIndex, roundArguments, sutAdapter, sutContext) {
        await super.initializeWorkloadModule(workerIndex, totalWorkers, roundIndex, roundArguments, sutAdapter, sutContext);
        this.workerIndex = workerIndex;
        this.txIndex = 0;
        this.keyCount = Number(roundArguments.keyCount) || 250;
    }

    async submitTransaction() {
        this.txIndex++;
        const args = {
            contractId: this.roundArguments.chaincode || process.env.CALIPER_CHAINCODE,
            contractFunction: 'Register',
            invokerIdentity: 'Admin@org' + (this.roundArguments.org || 1) + '.example.com',
            contractArguments: [`IoT_w${this.workerIndex}_${this.txIndex}`, 'Active'],
            readOnly: false
        };
        await this.sutAdapter.sendRequests(args);
    }
}

function createWorkloadModule() {
    return new RegisterIoTWorkload();
}

module.exports.createWorkloadModule = createWorkloadModule;

EOF

# --- RegisterUser ---
cat > "${WORKLOAD_DIR}/RegisterUser.js" << 'EOF'
'use strict';

const { WorkloadModuleBase } = require('@hyperledger/caliper-core');

class RegisterUserWorkload extends WorkloadModuleBase {
    async initializeWorkloadModule(workerIndex, totalWorkers, roundIndex, roundArguments, sutAdapter, sutContext) {
        await super.initializeWorkloadModule(workerIndex, totalWorkers, roundIndex, roundArguments, sutAdapter, sutContext);
        this.workerIndex = workerIndex;
        this.txIndex = 0;
        this.keyCount = Number(roundArguments.keyCount) || 250;
    }

    async submitTransaction() {
        this.txIndex++;
        const args = {
            contractId: this.roundArguments.chaincode || process.env.CALIPER_CHAINCODE,
            contractFunction: 'Register',
            invokerIdentity: 'Admin@org' + (this.roundArguments.org || 1) + '.example.com',
            contractArguments: [`User_w${this.workerIndex}_${this.txIndex}`, 'Active'],
            readOnly: false
        };
        await this.sutAdapter.sendRequests(args);
    }
}

function createWorkloadModule() {
    return new RegisterUserWorkload();
}

module.exports.createWorkloadModule = createWorkloadModule;

EOF

# -- QueryIoT (read-only) ---
cat > "${WORKLOAD_DIR}/QueryIoT.js" << 'EOF'
'use strict';

const { WorkloadModuleBase } = require('@hyperledger/caliper-core');

class QueryIoTWorkload extends WorkloadModuleBase {
    async initializeWorkloadModule(workerIndex, totalWorkers, roundIndex, roundArguments, sutAdapter, sutContext) {
        await super.initializeWorkloadModule(workerIndex, totalWorkers, roundIndex, roundArguments, sutAdapter, sutContext);
        this.workerIndex = workerIndex;
        this.txIndex = 0;
        this.keyCount = Number(roundArguments.keyCount) || 250;
    }

    async submitTransaction() {
        this.txIndex++;
        const args = {
            contractId: this.roundArguments.chaincode || process.env.CALIPER_CHAINCODE,
            contractFunction: 'QueryAsset',
            invokerIdentity: 'Admin@org' + (this.roundArguments.org || 1) + '.example.com',
            contractArguments: [`IoT_w${this.workerIndex}_${1 + Math.floor(Math.random() * this.keyCount)}`],
            readOnly: true
        };
        await this.sutAdapter.sendRequests(args);
    }
}

function createWorkloadModule() {
    return new QueryIoTWorkload();
}

module.exports.createWorkloadModule = createWorkloadModule;

EOF

# --- UpdateIoT ---
cat > "${WORKLOAD_DIR}/UpdateIoT.js" << 'EOF'
'use strict';

const { WorkloadModuleBase } = require('@hyperledger/caliper-core');

class UpdateIoTWorkload extends WorkloadModuleBase {
    async initializeWorkloadModule(workerIndex, totalWorkers, roundIndex, roundArguments, sutAdapter, sutContext) {
        await super.initializeWorkloadModule(workerIndex, totalWorkers, roundIndex, roundArguments, sutAdapter, sutContext);
        this.workerIndex = workerIndex;
        this.txIndex = 0;
        this.keyCount = Number(roundArguments.keyCount) || 250;
    }

    async submitTransaction() {
        this.txIndex++;
        const args = {
            contractId: this.roundArguments.chaincode || process.env.CALIPER_CHAINCODE,
            contractFunction: 'UpdateIoTStatus',
            invokerIdentity: 'Admin@org' + (this.roundArguments.org || 1) + '.example.com',
            contractArguments: [`IoT_w${this.workerIndex}_${1 + Math.floor(Math.random() * this.keyCount)}`, 'Active', String(Math.floor(Math.random()*100)), String(Math.floor(Math.random()*100))],
            readOnly: false
        };
        await this.sutAdapter.sendRequests(args);
    }
}

function createWorkloadModule() {
    return new UpdateIoTWorkload();
}

module.exports.createWorkloadModule = createWorkloadModule;

EOF

# --- RevokeIoT ---
cat > "${WORKLOAD_DIR}/RevokeIoT.js" << 'EOF'
'use strict';

const { WorkloadModuleBase } = require('@hyperledger/caliper-core');

class RevokeIoTWorkload extends WorkloadModuleBase {
    async initializeWorkloadModule(workerIndex, totalWorkers, roundIndex, roundArguments, sutAdapter, sutContext) {
        await super.initializeWorkloadModule(workerIndex, totalWorkers, roundIndex, roundArguments, sutAdapter, sutContext);
        this.workerIndex = workerIndex;
        this.txIndex = 0;
        this.keyCount = Number(roundArguments.keyCount) || 250;
    }

    async submitTransaction() {
        this.txIndex++;
        const args = {
            contractId: this.roundArguments.chaincode || process.env.CALIPER_CHAINCODE,
            contractFunction: 'Revoke',
            invokerIdentity: 'Admin@org' + (this.roundArguments.org || 1) + '.example.com',
            contractArguments: [`IoT_w${this.workerIndex}_${this.txIndex}`, 'Revoked'],
            readOnly: false
        };
        await this.sutAdapter.sendRequests(args);
    }
}

function createWorkloadModule() {
    return new RevokeIoTWorkload();
}

module.exports.createWorkloadModule = createWorkloadModule;

EOF

CALIPER_WL="/root/6g-network/test-tools/caliper-workspace/workload"
if [ -d "$CALIPER_WL" ]; then
    cp "${WORKLOAD_DIR}"/*.js "$CALIPER_WL"/
    echo -e "${GREEN}✓ Workloads copied into caliper-workspace${NC}"
fi
echo -e "${GREEN}✓ Caliper workload templates created (5 scenarios)${NC}"
echo -e "${GREEN}✓ Test interface setup complete${NC}"
