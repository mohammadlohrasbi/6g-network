const fs = require('fs');

const tapeConfig = {
    "network": {
        "orderer": {
            "url": "grpcs://165.232.71.90:7050",
            "mspid": "OrdererMSP",
            "tlsCACerts": "./crypto-config/ordererOrganizations/example.com/orderers/orderer1.example.com/tls/ca.crt"
        },
        "org1": {
            "mspid": "Org1MSP",
            "peers": ["grpcs://165.232.71.90:7051"],
            "certificateAuthorities": ["https://165.232.71.90:7054"]
        }
    },
    "channel": "GeneralOperationsChannel",
    "chaincode": "LocationBasedAssignment",
    "txNumber": 50,
    "rateControl": {
        "type": "fixed-rate",
        "opts": {
            "tps": 5
        }
    }
};

fs.writeFileSync('tape-config.yaml', JSON.stringify(tapeConfig, null, 2));
