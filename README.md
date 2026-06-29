# شبکه 6G مبتنی بر Hyperledger Fabric

شبیه‌سازی شبکه نسل ششم (6G) با ۸ سازمان، ۲۰ کانال موضوعی و ۸۶ قرارداد هوشمند.

## معماری
- **۱ orderer** (solo)
- **۲ CA**: root-ca (پورت 7052) + rca-main (پورت 7054)
- **۸ سازمان** (org1–org8)، هر کدام یک peer
- **۲۰ کانال موضوعی**
- **۸۶ قرارداد** (chaincode) توزیع‌شده روی کانال‌ها
- TLS بین peer/orderer غیرفعال (سازگاری با rca-main مستقل)

## ساختار فایل‌ها
```
scripts/
  network.sh                  # ساخت کامل شبکه (CA, MSP, peer, orderer)
  generateChaincodes_part*.sh # ساخت ۸۶ قرارداد (۱۰ فایل)
  channel_contract_map.sh     # نگاشت قرارداد ↔ کانال
  deploy_functions.sh         # توابع deploy دسته‌ای
  deploy-staged.sh            # deploy پله‌پله کانال‌ها
config/
  configtx.yaml               # تنظیمات کانال و سازمان‌ها
  docker-compose.yml          # ۸ peer + orderer (با mem_limit)
  docker-compose-root-ca.yml  # سرویس root-ca
```

## پیش‌نیاز: ساخت swap (برای سرور کم‌حافظه)
```bash
fallocate -l 4G /swapfile && chmod 600 /swapfile
mkswap /swapfile && swapon /swapfile
echo '/swapfile none swap sw 0 0' >> /etc/fstab
```

## اجرا

### ۱) clone و آماده‌سازی
```bash
cd
rm -rf 6g-network
git clone https://github.com/USERNAME/6g-network.git
cd /root/6g-network/scripts
chmod +x *.sh
```

### ۲) ساخت قراردادها (هر ۱۰ فایل)
```bash
for f in generateChaincodes_part*.sh; do ./"$f"; done
```

### ۳) ساخت و راه‌اندازی شبکه
```bash
./network.sh
```

### ۴) ساخت artifact همه ۲۰ کانال
```bash
./deploy-staged.sh artifacts
```

### ۵) deploy پله‌پله (کانال‌به‌کانال)
```bash
# یک کانال را deploy کن
./deploy-staged.sh channel datachannel

# وضعیت را ببین
./deploy-staged.sh list

# حافظه را آزاد کن (قبل از کانال بعدی)
./deploy-staged.sh cleanup-dev datachannel

# کانال بعدی...
./deploy-staged.sh channel iotchannel
```

### یا deploy همه (با پاک‌سازی خودکار بین کانال‌ها)
```bash
./deploy-staged.sh all
```

## تست یک قرارداد
```bash
docker exec \
  -e CORE_PEER_LOCALMSPID=org1MSP \
  -e CORE_PEER_MSPCONFIGPATH=/etc/hyperledger/fabric/admin-msp \
  -e CORE_PEER_ADDRESS=peer0.org1.example.com:7051 \
  -e CORE_PEER_TLS_ENABLED=false \
  peer0.org1.example.com \
  peer chaincode invoke -o orderer.example.com:7050 \
    -C datachannel -n LocationBasedAssignment \
    --peerAddresses peer0.org1.example.com:7051 \
    --peerAddresses peer0.org2.example.com:8051 \
    -c '{"Args":["Record","device1","antenna1","100","10","20"]}'
```

## نکات منابع
- هر peer ~۸۵MB، هر dev-container ~۱۹MB
- بزرگ‌ترین کانال (iotchannel) = ۹ قرارداد × ۸ peer = ۷۲ dev (~۱.۴GB)
- بعد از هر کانال `cleanup-dev` بزن تا حافظه آزاد شود
