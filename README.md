## پروژه شبکه 6G با Hyperledger Fabric

این پروژه یک شبکه Hyperledger Fabric با ۸ سازمان همتا (Org1 تا Org8)، یک سازمان مرتب‌کننده، و ۲۰ کانال (NetworkChannel، ResourceChannel، و غیره) پیاده‌سازی می‌کند. این سند مراحل راه‌اندازی و اجرای پروژه را شرح می‌دهد.

## پیش‌نیازها

- **Docker** و **Docker Compose**: برای اجرای سرورهای Fabric CA و اجزای شبکه.
- **Hyperledger Fabric 2.5.0**: ابزارهای `cryptogen`، `configtxgen`، و `fabric-ca-client`.
- **Hyperledger Fabric CA 1.5.7**: برای سرورهای CA.
- **Node.js و npm**: برای سرور وب.
- **Nginx**: برای پراکسی وب.
- **yamllint**: برای اعتبارسنجی فایل‌های YAML (توصیه می‌شود).
- **openssl**: برای تولید گواهی‌های TLS.
- **سیستم‌عامل**: Ubuntu/Debian توصیه می‌شود.

### نصب پیش‌نیازها

```bash
# نصب Docker و Docker Compose
sudo apt-get update
sudo apt-get install -y docker.io docker-compose

# نصب Hyperledger Fabric 2.5.0 و Fabric CA 1.5.7
curl -sSL https://bit.ly/2ysbOFE | bash -s -- 2.5.0 1.5.7

# نصب Node.js و npm
sudo apt-get install -y nodejs npm

# نصب Nginx
sudo apt-get install -y nginx

# نصب yamllint
sudo apt-get install -y yamllint
pip install yamllint

# نصب openssl (معمولاً از پیش نصب است)
sudo apt-get install -y openssl
---
## ساختار پروژه

- `/root/6g-network/config`: شامل فایل‌های پیکربندی (`cryptogen.yaml`، `configtx.yaml`، `docker-compose-ca.yml`).
- `/root/6g-network/wallet`: ذخیره هویت‌های ثبت‌شده.
- `/root/6g-network/scripts`: اسکریپت‌های تولید قراردادهای هوشمند و فایل‌های پیکربندی.
- `/root/6g-network/web`: سرور وب برای رابط کاربری.

## مراحل راه‌اندازی

### ۱. اعتبارسنجی فایل‌های پیکربندی

فایل‌های پیکربندی را بررسی کنید تا از نبود خطاها یا کاراکترهای غیرمجاز اطمینان حاصل شود:

```bash
cd /root/6g-network/config
yamllint cryptogen.yaml
yamllint configtx.yaml
yamllint docker-compose-ca.yml
```

**نکته**: اگر خطای تورفتگی در `configtx.yaml` رخ داد، اطمینان حاصل کنید که کلیدهای سطح بالا (مانند `Organizations`) بدون تورفتگی باشند:

```bash
nnano /root/6g-network/config/configtx.yaml
# اطمینان حاصل کنید که خط دوم به صورت زیر است:
---
Organizations:
```

**نکته**: اگر هشدار `missing document start "---"` در `docker-compose-ca.yml` ظاهر شد، فایل را بررسی کنید:

```bash
cat -v /root/6g-network/config/docker-compose-ca.yml
nano /root/6g-network/config/docker-compose-ca.yml
```

### ۲. تولید مواد رمزنگاری

فایل `cryptogen.yaml` مواد رمزنگاری را برای ۸ سازمان همتا و یک مرتب‌کننده تولید می‌کند.

```bash
cd /root/6g-network/config
rm -rf crypto-config  # حذف پوشه قدیمی (در صورت وجود)
cryptogen generate --config=cryptogen.yaml --output=crypto-config
```

**تأیید خروجی**:

- بررسی کنید که پوشه `/root/6g-network/config/crypto-config` شامل زیرپوشه‌های `peerOrganizations` و `ordererOrganizations` باشد:

```bash
ls -R /root/6g-network/config/crypto-config
```

- تأیید کنید که فایل‌های گواهی و کلید خصوصی تولید شده‌اند:

```bash
ls -l /root/6g-network/config/crypto-config/peerOrganizations/*/ca/
ls -l /root/6g-network/config/crypto-config/ordererOrganizations/example.com/orderers/orderer.example.com/tls/
```

### ۳. تولید آرتیفکت‌های کانال

فایل `configtx.yaml` برای تولید بلوک‌های جنسیس و فایل‌های تراکنش کانال استفاده می‌شود.

```bash
export FABRIC_CFG_PATH=${PWD}
mkdir -p channel-artifacts
configtxgen -profile SystemChannel -outputBlock channel-artifacts/system-genesis.block -channelID system-channel
for CHANNEL in NetworkChannel ResourceChannel PerformanceChannel IoTChannel AuthChannel ConnectivityChannel SessionChannel PolicyChannel AuditChannel SecurityChannel DataChannel AnalyticsChannel MonitoringChannel ManagementChannel OptimizationChannel FaultChannel TrafficChannel AccessChannel ComplianceChannel IntegrationChannel; do
    configtxgen -profile ApplicationChannel -outputCreateChannelTx channel-artifacts/${CHANNEL,,}.tx -channelID ${CHANNEL}
done
```

**تأیید خروجی**:

- بررسی کنید که ۴۰ فایل (۲۰ فایل `.block` و ۲۰ فایل `.tx`) تولید شده باشند:

```bash
ls -l /root/6g-network/config/channel-artifacts
```

### ۴. بررسی پورت‌ها

اطمینان حاصل کنید که پورت‌های مورد نیاز (7054 تا 14054 و 17054 تا 24054) آزاد هستند:

```bash
netstat -tuln | grep -E '7054|8054|9054|10054|11054|12054|13054|14054|17054|18054|19054|20054|21054|22054|23054|24054'
```

**نکته**: اگر پورت‌ها اشغال هستند، فرآیندهای مرتبط را متوقف کنید:

```bash
for port in 7054 8054 9054 10054 11054 12054 13054 14054 17054 18054 19054 20054 21054 22054 23054 24054; do
    sudo kill $(sudo lsof -t -i:$port) 2>/dev/null || true
done
```

### ۵. حذف دایرکتوری‌های ناخواسته TLS

برای جلوگیری از خطای `Can't open ... for writing, Is a directory`، دایرکتوری‌های ناخواسته `tls-cert.pem` و `tls-key.pem` را حذف کنید:

```bash
for i in {1..8}; do
    echo "Removing problematic TLS directories for org${i}"
    rm -rf /root/6g-network/config/crypto-config/peerOrganizations/org${i}.example.com/ca/tls-cert.pem
    rm -rf /root/6g-network/config/crypto-config/peerOrganizations/org${i}.example.com/ca/tls-key.pem
done
```

### ۶. تولید گواهی‌های TLS برای سرورهای CA

گواهی‌های TLS را برای هر سازمان تولید کنید:

```bash
for i in {1..8}; do
    echo "Generating TLS cert and key for org${i}"
    openssl req -x509 -newkey ec -pkeyopt ec_paramgen_curve:P-256 -keyout /root/6g-network/config/crypto-config/peerOrganizations/org${i}.example.com/ca/tls-key.pem -out /root/6g-network/config/crypto-config/peerOrganizations/org${i}.example.com/ca/tls-cert.pem -days 3650 -nodes -subj "/C=US/ST=North Carolina/O=Hyperledger/OU=Fabric/CN=ca-org${i}" -addext "subjectAltName = DNS:localhost, DNS:ca-org${i}"
done
```

**تأیید خروجی**:

- بررسی کنید که فایل‌های `tls-cert.pem` و `tls-key.pem` به صورت فایل‌های معمولی (نه دایرکتوری) تولید شده باشند:

```bash
for i in {1..8}; do
    echo "Checking TLS files for org${i}:"
    ls -l /root/6g-network/config/crypto-config/peerOrganizations/org${i}.example.com/ca/
done
```

**نکته**: انتظار می‌رود فایل‌های زیر برای هر سازمان وجود داشته باشند:

- `ca.orgX.example.com-cert.pem`
- `tls-cert.pem` (فایل، نه دایرکتوری)
- `tls-key.pem` (فایل، نه دایرکتوری)
- `priv_sk`

### ۷. حذف فایل‌های پیکربندی پیش‌فرض

برای جلوگیری از تداخل با متغیرهای محیطی در `docker-compose-ca.yml`، فایل‌های پیکربندی پیش‌فرض را حذف کنید:

```bash
for i in {1..8}; do
    echo "Removing config file for org${i}"
    rm -f /root/6g-network/config/crypto-config/peerOrganizations/org${i}.example.com/ca/fabric-ca-server-config.yaml
done
```

### ۸. راه‌اندازی سرورهای Fabric CA

فایل `docker-compose-ca.yml` سرورهای Fabric CA را راه‌اندازی می‌کند. اطمینان حاصل کنید که فایل شامل نگاشت‌های volume برای فایل‌های TLS و CA باشد (نمونه در بخش پشتیبانی).

```bash
cd /root/6g-network/config
docker-compose -f docker-compose-ca.yml down
docker-compose -f docker-compose-ca.yml up -d
```

**تأیید خروجی**:

- بررسی کنید که ۸ کانتینر CA (ca-org1 تا ca-org8) اجرا می‌شوند:

```bash
docker ps -a -f name=ca-org
```

- اگر کانتینرها در حالت `Exited` هستند، لاگ‌ها را بررسی کنید:

```bash
for i in {1..8}; do
    echo "Logs for ca-org${i}:"
    docker logs ca-org${i}
done
```

- بررسی کنید که فایل‌های TLS و CA به درستی در کانتینرها قرار دارند:

```bash
for i in {1..8}; do
    echo "Files in ca-org${i}:"
    docker exec ca-org${i} ls -l /etc/hyperledger/fabric-ca-server/
    docker exec ca-org${i} ls -l /etc/hyperledger/fabric-ca-server/msp/keystore/
done
```

### ۹. ثبت هویت‌های Admin

هویت‌های admin برای هر سازمان ثبت می‌شوند.

```bash
cd /root/6g-network
export FABRIC_CA_CLIENT_HOME=${PWD}/wallet
for i in {1..8}; do
    echo "Enrolling admin for ca-org${i}"
    fabric-ca-client enroll -u https://admin:adminpw@localhost:$((7054 + (i-1)*1000)) --caname ca-org${i} --tls.certfiles /root/6g-network/config/crypto-config/peerOrganizations/org${i}.example.com/ca/tls-cert.pem --mspdir org${i}/admin/msp || echo "Failed to enroll admin for ca-org${i}"
done
```

**تأیید خروجی**:

- بررسی کنید که هویت‌ها در `/root/6g-network/wallet` ذخیره شده‌اند:

```bash
ls -l /root/6g-network/wallet
```

### ۱۰. تولید و استقرار قراردادهای هوشمند

اسکریپت‌های موجود در پوشه `scripts` قراردادهای هوشمند و فایل‌های پیکربندی را تولید می‌کنند.

```bash
cd /root/6g-network/scripts
chmod +x *.sh
for i in {1..10}; do ./generateChaincodes_part${i}.sh; done
./generateConnectionJson.sh
./generateConnectionProfiles.sh
./generateCoreyamls.sh
./generateWorkloadFiles.sh
./setup.sh
cd ..
```

### ۱۱. راه‌اندازی سرور وب و Nginx

سرور وب و Nginx راه‌اندازی می‌شوند.

```bash
cd /root/6g-network/web
npm install express fabric-network js-yaml
node webserver.js &
sudo cp nginx.conf /etc/nginx/sites-available/6g-fabric-network
sudo ln -s /etc/nginx/sites-available/6g-fabric-network /etc/nginx/sites-enabled/
sudo systemctl restart nginx
```

**تأیید خروجی**:

- بررسی کنید که سرور وب و Nginx فعال هستند:

```bash
ps aux | grep node
sudo systemctl status nginx
```

### ۱۲. اجرای تست‌های مقیاس‌پذیری

1. به رابط کاربری در `http://localhost` بروید.
2. پارامترهای تست (تعداد قراردادها، کانال‌ها، TPS، تعداد تراکنش‌ها، کاربران) را تنظیم کنید.
3. روی دکمه "Run Scalability Test" کلیک کنید.

## عیب‌یابی

### رفع خطای `Can't open ... for writing, Is a directory`

این خطا نشان می‌دهد که دایرکتوری‌هایی با نام `tls-cert.pem` یا `tls-key.pem` در مسیرهای `/root/6g-network/config/crypto-config/peerOrganizations/orgX.example.com/ca/` وجود دارند. برای رفع:

```bash
for i in {1..8}; do
    echo "Removing problematic TLS directories for org${i}"
    rm -rf /root/6g-network/config/crypto-config/peerOrganizations/org${i}.example.com/ca/tls-cert.pem
    rm -rf /root/6g-network/config/crypto-config/peerOrganizations/org${i}.example.com/ca/tls-key.pem
done
```

سپس، فایل‌های TLS را دوباره تولید کنید:

```bash
for i in {1..8}; do
    echo "Generating TLS cert and key for org${i}"
    openssl req -x509 -newkey ec -pkeyopt ec_paramgen_curve:P-256 -keyout /root/6g-network/config/crypto-config/peerOrganizations/org${i}.example.com/ca/tls-key.pem -out /root/6g-network/config/crypto-config/peerOrganizations/org${i}.example.com/ca/tls-cert.pem -days 3650 -nodes -subj "/C=US/ST=North Carolina/O=Hyperledger/OU=Fabric/CN=ca-org${i}"
done
```

### رفع خطای `connection refused`

این خطا معمولاً به دلیل متوقف شدن کانتینرهای CA یا مشکلات TLS رخ می‌دهد.

- بررسی کنید که کانتینرها اجرا می‌شوند:

```bash
docker ps -a -f name=ca-org
```

- اگر کانتینرها در حالت `Exited` هستند، لاگ‌ها را بررسی کنید:

```bash
for i in {1..8}; do
    echo "Logs for ca-org${i}:"
    docker logs ca-org${i}
done
```

- اگر خطای `File specified by 'tls.keyfile' does not exist` مشاهده شد، اطمینان حاصل کنید که فایل‌های TLS به درستی تولید و نگاشت شده‌اند (مراحل ۵ و ۶).

- پورت‌ها را بررسی کنید:

```bash
netstat -tuln | grep -E '7054|8054|9054|10054|11054|12054|13054|14054'
```

- اگر پورت‌ها بسته هستند، فایروال را بررسی کنید:

```bash
sudo ufw status
for i in {0..7}; do
    sudo ufw allow $((7054 + i*1000))
done
```

- تست اتصال با HTTP (برای عیب‌یابی موقت بدون TLS):

```bash
for i in {1..8}; do
    echo "Testing connection for ca-org${i}"
    curl http://localhost:$((7054 + (i-1)*1000))
done
```

### رفع خطای `device or resource busy`

این خطا هنگام کپی فایل‌ها با `docker cp` رخ می‌دهد، زیرا فایل‌ها توسط volume‌های `docker-compose-ca.yml` قفل شده‌اند.

- کانتینرها را متوقف کنید:

```bash
docker-compose -f /root/6g-network/config/docker-compose-ca.yml down
```

- فایل‌های TLS و CA را در هاست آماده کنید (مرحله ۵).

- از نگاشت‌های volume در `docker-compose-ca.yml` استفاده کنید (نمونه در بخش پشتیبانی).

- کانتینرها را دوباره راه‌اندازی کنید:

```bash
docker-compose -f /root/6g-network/config/docker-compose-ca.yml up -d
```

### تست بدون TLS (اختیاری)

اگر مشکلات TLS ادامه داشت، TLS را موقتاً غیرفعال کنید:

```bash
nano /root/6g-network/config/docker-compose-ca.yml
```

برای هر سرویس، متغیر زیر را تغییر دهید:

```yaml
- FABRIC_CA_SERVER_TLS_ENABLED=false
```

نگاشت‌های مربوط به `tls-cert.pem` و `tls-key.pem` را از بخش `volumes` حذف کنید. سپس:

```bash
docker-compose -f /root/6g-network/config/docker-compose-ca.yml down
docker-compose -f /root/6g-network/config/docker-compose-ca.yml up -d
```

ثبت‌نام را با HTTP تست کنید:

```bash
cd /root/6g-network
export FABRIC_CA_CLIENT_HOME=${PWD}/wallet
for i in {1..8}; do
    echo "Enrolling admin for ca-org${i}"
    fabric-ca-client enroll -u http://admin:adminpw@localhost:$((7054 + (i-1)*1000)) --caname ca-org${i} --mspdir org${i}/admin/msp || echo "Failed to enroll admin for ca-org${i}"
done
```

## نکات

- **تعداد کانال‌ها**: ۲۰ کانال ممکن است بار زیادی به شبکه تحمیل کند. در صورت نیاز، تعداد را کاهش دهید:

```bash
for CHANNEL in NetworkChannel ResourceChannel; do
    configtxgen -profile ApplicationGenesis -outputBlock channel-artifacts/${CHANNEL}.block -channelID ${CHANNEL}
    configtxgen -profile ApplicationGenesis -outputCreateChannelTx channel-artifacts/${CHANNEL,,}.tx -channelID ${CHANNEL}
done
```

- **نسخه Fabric**: از Hyperledger Fabric 2.5.0 برای ابزارها و 1.5.7 برای Fabric CA استفاده شده است. برای اطمینان:

```bash
configtxgen --version
fabric-ca-client --version
```

## پشتیبانی

برای مشکلات، جزئیات زیر را ارائه دهید:

- خروجی کامل خطا
- خروجی `ls -R /root/6g-network/config/crypto-config`
- خروجی `docker ps -a -f name=ca-org`
- خروجی `ls -l /root/6g-network/wallet`
- خروجی `cat -v /root/6g-network/config/docker-compose-ca.yml`
- خروجی `netstat -tuln | grep -E '7054|8054|9054|10054|11054|12054|13054|14054'`
- لاگ‌های کانتینرهای CA:

```bash
for i in {1..8}; do
    echo "Logs for ca-org${i}:"
    docker logs ca-org${i}
done
```

- خروجی تست `curl`:

```bash
for i in {1..8}; do
    curl --cacert /root/6g-network/config/crypto-config/peerOrganizations/org${i}.example.com/ca/ca.org${i}.example.com-cert.pem https://localhost:$((7054 + (i-1)*1000))
done
```
