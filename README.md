# پروژه شبکه 6G با Hyperledger Fabric

این پروژه یک شبکه Hyperledger Fabric با ۸ سازمان همتا (Org1 تا Org8)، یک سازمان مرتب‌کننده، و ۲۰ کانال (NetworkChannel، ResourceChannel، و غیره) پیاده‌سازی می‌کند. این سند مراحل راه‌اندازی و اجرای پروژه را شرح می‌دهد.

## پیش‌نیازها
- **Docker** و **Docker Compose**: برای اجرای سرورهای Fabric CA و اجزای شبکه.
- **Hyperledger Fabric 2.5.0**: ابزارهای `cryptogen`، `configtxgen`، و `fabric-ca-client`.
- **Node.js و npm**: برای سرور وب.
- **Nginx**: برای پراکسی وب.
- **yamllint**: برای اعتبارسنجی فایل‌های YAML (توصیه می‌شود).
- **سیستم‌عامل**: Ubuntu/Debian توصیه می‌شود.

### نصب پیش‌نیازها
```bash
# نصب Docker و Docker Compose
sudo apt-get update
sudo apt-get install -y docker.io docker-compose

# نصب Hyperledger Fabric 2.5.0
curl -sSL https://bit.ly/2ysbOFE | bash -s

# نصب Node.js و npm
sudo apt-get install -y nodejs npm

# نصب Nginx
sudo apt-get install -y nginx

# نصب yamllint
sudo apt-get install -y yamllint
pip install yamllint
```

## ساختار پروژه
- `/root/6g-network/config`: شامل فایل‌های پیکربندی (`cryptogen.yaml`، `configtx.yaml`، `docker-compose-ca.yml`).
- `/root/6g-network/wallet`: ذخیره هویت‌های ثبت‌شده.
- `/root/6g-network/scripts`: اسکریپت‌های تولید قراردادهای هوشمند و فایل‌های پیکربندی.
- `/root/6g-network/web`: سرور وب برای رابط کاربری.

## مراحل راه‌اندازی

### ۱. اعتبارسنجی فایل‌های پیکربندی
فایل‌های `cryptogen.yaml`، `configtx.yaml`، و `docker-compose-ca.yml` را بررسی کنید تا از نبود کاراکترهای غیرمجاز (مانند `` ` `` یا BOM) اطمینان حاصل شود:
```bash
cd /root/6g-network/config
yamllint cryptogen.yaml
yamllint configtx.yaml
yamllint docker-compose-ca.yml
```
**نکته**: اگر خطای YAML (مانند کاراکتر غیرمجاز) رخ داد، فایل را با ویرایشگر متنی باز کنید:
```bash
cat -v /root/6g-network/config/docker-compose-ca.yml
nano /root/6g-network/config/docker-compose-ca.yml
```

### ۲. تولید مواد رمزنگاری
فایل `cryptogen.yaml` مواد رمزنگاری را برای ۸ سازمان همتا (Org1 تا Org8) و یک سازمان مرتب‌کننده تولید می‌کند.

```bash
cd /root/6g-network/config
rm -rf crypto-config  # حذف پوشه قدیمی (در صورت وجود)
cryptogen generate --config=cryptogen.yaml
```

**تأیید خروجی**:
- بررسی کنید که پوشه `/root/6g-network/config/crypto-config` شامل زیرپوشه‌های `peerOrganizations` (برای Org1 تا Org8) و `ordererOrganizations` باشد:
  ```bash
  ls -R /root/6g-network/config/crypto-config
  ```
- تأیید کنید که فایل‌های TLS مرتب‌کننده تولید شده‌اند:
  ```bash
  ls -l /root/6g-network/config/crypto-config/ordererOrganizations/example.com/orderers/orderer1.example.com/tls/
  ```

### ۳. تولید آرتیفکت‌های کانال
فایل `configtx.yaml` برای تولید بلوک‌های جنسیس و فایل‌های تراکنش ایجاد کانال برای ۲۰ کانال استفاده می‌شود.

```bash
export FABRIC_CFG_PATH=${PWD}
mkdir -p channel-artifacts
for CHANNEL in NetworkChannel ResourceChannel PerformanceChannel IoTChannel AuthChannel ConnectivityChannel SessionChannel PolicyChannel AuditChannel SecurityChannel DataChannel AnalyticsChannel MonitoringChannel ManagementChannel OptimizationChannel FaultChannel TrafficChannel AccessChannel ComplianceChannel IntegrationChannel; do
    configtxgen -profile ApplicationGenesis -outputBlock channel-artifacts/${CHANNEL}.block -channelID ${CHANNEL}
    configtxgen -profile ApplicationGenesis -outputCreateChannelTx channel-artifacts/${CHANNEL,,}.tx -channelID ${CHANNEL}
done
```

**تأیید خروجی**:
- بررسی کنید که ۴۰ فایل (۲۰ فایل `.block` و ۲۰ فایل `.tx`) در `/root/6g-network/config/channel-artifacts` تولید شده باشند:
  ```bash
  ls -l /root/6g-network/config/channel-artifacts
  ```

### ۴. راه‌اندازی سرورهای Fabric CA
فایل `docker-compose-ca.yml` سرورهای Fabric CA را برای ۸ سازمان راه‌اندازی می‌کند.

```bash
docker-compose -f docker-compose-ca.yml up -d
```

**تأیید خروجی**:
- بررسی کنید که ۸ کانتینر CA (ca-org1 تا ca-org8) روی پورت‌های 7054 تا 14054 اجرا می‌شوند:
  ```bash
  docker ps | grep fabric-ca
  ```

### ۵. ثبت هویت‌های Admin
هویت‌های admin برای هر سازمان در کیف‌پول ثبت می‌شوند.

```bash
cd /root/6g-network
export FABRIC_CA_CLIENT_HOME=${PWD}/wallet
for i in {1..8}; do
    fabric-ca-client enroll -u https://admin:adminpw@localhost:$((7054 + (i-1)*1000)) --caname ca-org${i} --tls.certfiles /root/6g-network/config/crypto-config/peerOrganizations/org${i}.example.com/ca/ca.org${i}.example.com-cert.pem
done
```

**تأیید خروجی**:
- بررسی کنید که هویت‌ها در `/root/6g-network/wallet` ذخیره شده‌اند:
  ```bash
  ls -l /root/6g-network/wallet
  ```

### ۶. تولید و استقرار قراردادهای هوشمند
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

### ۷. راه‌اندازی سرور وب و Nginx
سرور وب برای رابط کاربری و Nginx برای پراکسی راه‌اندازی می‌شود.

```bash
cd /root/6g-network/web
npm install express fabric-network js-yaml
node webserver.js &
sudo cp nginx.conf /etc/nginx/sites-available/6g-fabric-network
sudo ln -s /etc/nginx/sites-available/6g-fabric-network /etc/nginx/sites-enabled/
sudo systemctl restart nginx
```

**تأیید خروجی**:
- بررسی کنید که سرور وب در حال اجرا است:
  ```bash
  ps aux | grep node
  ```
- بررسی کنید که Nginx فعال است:
  ```bash
  sudo systemctl status nginx
  ```

### ۸. اجرای تست‌های مقیاس‌پذیری
1. به رابط کاربری در `http://localhost` بروید.
2. پارامترهای تست (تعداد قراردادها، کانال‌ها، TPS، تعداد تراکنش‌ها، کاربران) را تنظیم کنید.
3. روی دکمه "Run Scalability Test" کلیک کنید.

## عیب‌یابی
- **بررسی فایل‌های TLS**:
  ```bash
  ls -l /root/6g-network/config/crypto-config/ordererOrganizations/example.com/orderers/orderer1.example.com/tls/
  ```
- **بررسی لاگ‌های CA**:
  ```bash
  docker logs ca-org1
  # و غیره برای ca-org2 تا ca-org8
  ```
- **بررسی فایل‌های تولیدشده**:
  ```bash
  ls -R /root/6g-network/config/crypto-config
  ls -l /root/6g-network/config/channel-artifacts
  ls -l /root/6g-network/wallet
  ```
- **لاگ دیباگ برای configtxgen**:
  ```bash
  FABRIC_LOGGING_SPEC=DEBUG configtxgen -profile ApplicationGenesis -outputBlock channel-artifacts/NetworkChannel.block -channelID NetworkChannel
  ```
- **رفع خطای YAML**:
  - اگر خطای کاراکتر غیرمجاز (مانند `` ` ``) رخ داد، فایل را بررسی کنید:
    ```bash
    cat -v /root/6g-network/config/docker-compose-ca.yml
    nano /root/6g-network/config/docker-compose-ca.yml
    ```

## نکات
- **تعداد کانال‌ها**: ۲۰ کانال ممکن است بار زیادی به شبکه تحمیل کند. در صورت نیاز، لیست کانال‌ها را کاهش دهید:
  ```bash
  for CHANNEL in NetworkChannel ResourceChannel; do
      configtxgen -profile ApplicationGenesis -outputBlock channel-artifacts/${CHANNEL}.block -channelID ${CHANNEL}
      configtxgen -profile ApplicationGenesis -outputCreateChannelTx channel-artifacts/${CHANNEL,,}.tx -channelID ${CHANNEL}
  done
  ```
- **نسخه Fabric**: از Hyperledger Fabric 2.5.0 استفاده شده است. برای اطمینان:
  ```bash
  configtxgen --version
  ```

## پشتیبانی
برای سؤالات یا مشکلات، جزئیات زیر را ارائه دهید:
- خروجی کامل خطا
- خروجی `ls -R /root/6g-network/config/crypto-config`
- خروجی `docker ps | grep fabric-ca`
- خروجی `ls -l /root/6g-network/wallet`
- خروجی `cat -v /root/6g-network/config/docker-compose-ca.yml`
- تنظیمات رابط کاربری (در صورت وجود)
