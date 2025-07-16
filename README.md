# پروژه 6G Fabric Network

این پروژه یک شبکه **Hyperledger Fabric** برای شبیه‌سازی سناریوهای 6G است. شامل **85 قرارداد هوشمند** (50 عمومی و 35 مرتبط با موقعیت) و **18 کانال** (8 سازمانی و 10 عمومی) است. معیار عضویت بر اساس فاصله اقلیدسی از یک نقطه مرجع تصادفی است، و مختصات X و Y به‌صورت تصادفی در بازه [-90, 90] و [-180, 180] تولید می‌شوند. شبکه از طریق رابط کاربری وب روی `http://6gfabric.local:3000` قابل مدیریت است و برای اجرا روی ماشین مجازی با 1 هسته CPU و 1 گیگابایت RAM بهینه شده است.

## پیش‌نیازها
- **سیستم‌عامل**: Ubuntu 20.04 LTS
- **سخت‌افزار**: 1 هسته CPU، 1 گیگابایت RAM، 20 گیگابایت دیسک
- **ابزارها**: Docker، Docker Compose، Node.js (v14+)، npm (v6+)، Go (v1.18+)، Caliper (v0.5)، Tape، Nginx
- **IP و دامنه**: 165.232.71.90 و 6gfabric.local (برای دسترسی اینترنتی، IP عمومی ماشین مجازی را به دامنه متصل کنید)

## ساختار پروژه
```
~/6g-fabric-network/
├── chaincode/
│   ├── LocationBasedAssignment/chaincode.go
│   ├── AuthenticateUser/chaincode.go
│   ├── ... (تا 85 قرارداد)
├── caliper-workspace/
│   ├── networks/networkConfig.yaml
│   ├── benchmarks/myAssetBenchmark.yaml
│   ├── workload/
│   │   ├── utils.js
│   │   ├── LocationBasedAssignment.js
│   │   ├── AuthenticateUser.js
│   │   ├── ... (تا 85 فایل workload)
├── crypto-config/
├── Org1Channel.tx
├── ... (تا Org8Channel.tx)
├── GeneralOperationsChannel.tx
├── IoTChannel.tx
├── SecurityChannel.tx
├── AuditChannel.tx
├── BillingChannel.tx
├── ResourceChannel.tx
├── PerformanceChannel.tx
├── SessionChannel.tx
├── ConnectivityChannel.tx
├── PolicyChannel.tx
├── genesis.block
├── crypto-config.yaml
├── configtx.yaml
├── docker-compose.yml
├── tape-config.yaml
├── generateChaincodes.sh
├── generateWorkloadFiles.sh
├── generateConnectionProfiles.sh
├── generateTapeArgs.js
├── webserver.js
├── index.html  # رابط کاربری وب
├── setup_network.sh
├── 6g-fabric-network.zip
```

## راه‌اندازی
1. **تنظیم IP عمومی**:
   - فایل تنظیمات شبکه را ویرایش کنید:
     ```bash
     sudo nano /etc/netplan/00-installer-config.yaml
     ```
     محتوا:
     ```yaml
     network:
       ethernets:
         enp0s3:
           addresses: [165.232.71.90/24]
           gateway4: 165.232.71.1  # gateway را بر اساس شبکه تنظیم کنید
           nameservers:
             addresses: [8.8.8.8, 8.8.4.4]
       version: 2
     ```
     ```bash
     sudo netplan apply
     ```
   - دامنه 6gfabric.local را به IP عمومی در DNS عمومی (مانند Cloudflare) اضافه کنید.

2. **نصب پیش‌نیازها**:
   ```bash
   sudo apt install -y docker.io docker-compose curl wget npm golang-go nginx
   curl -sSL https://bit.ly/2ysbOFE | bash -s -- 2.5.0 1.5.2
   export PATH=$PWD/bin:$PATH
   npm install --global @hyperledger/caliper-cli@0.5
   npx caliper bind --caliper-bind-sut fabric:2.5
   npm install -g @hyperledger-tape/tape
   npm install express
   ```

3. **کلون و اجرای پروژه**:
   ```bash
   git clone https://github.com/your-repo/6g-fabric.git
   cd 6g-fabric-network
   chmod +x *.sh
   ./generateChaincodes.sh
   ./generateWorkloadFiles.sh
   ./generateConnectionProfiles.sh
   ./setup_network.sh
   node webserver.js
   ```

4. **دسترسی وب**:
   - رابط کاربری در `http://6gfabric.local:3000` یا `http://165.232.71.90:3000` قابل دسترسی است.
   - فرم تنظیمات شامل فیلدهای TPS، تعداد تراکنش‌ها، نام قرارداد، تعداد کاربران، تعداد IoTها، انتخاب کانال‌ها (checkbox برای جداگانه یا همه)، روش تست (dropdown برای Caliper/Tape/هر دو).
   - ظاهر: مدرن با sidebar، navbar، کارت‌ها، و دکمه‌های زیبا (بر اساس AdminLTE و Bootstrap 5).

## قراردادهای هوشمند
### قراردادهای مرتبط با موقعیت (35)
1. **LocationBasedAssignment** (GeneralOperationsChannel, Org1Channel–Org8Channel)
   - **کاربری**: تخصیص آنتن به کاربر یا دستگاه IoT با مختصات تصادفی.
   - **دستورات**:
     ```bash
     peer chaincode invoke -C GeneralOperationsChannel -n LocationBasedAssignment -c '{"function":"AssignAntenna","Args":["user1","Antenna1","40.7128","-74.0060"]}' --tls --cafile /crypto-config/ordererOrganizations/example.com/orderers/orderer1.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
     peer chaincode query -C GeneralOperationsChannel -n LocationBasedAssignment -c '{"function":"QueryAntennaAssignment","Args":["user1"]}'
     ```
2. **LocationBasedConnection** (ConnectivityChannel)
   - **کاربری**: اتصال کاربر یا دستگاه به آنتن با مختصات تصادفی.
   - **دستورات**:
     ```bash
     peer chaincode invoke -C ConnectivityChannel -n LocationBasedConnection -c '{"function":"ConnectEntity","Args":["user1","Antenna1","40.7128","-74.0060"]}' --tls --cafile /crypto-config/ordererOrganizations/example.com/orderers/orderer1.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
     ```
3. **LocationBasedBandwidth** (ResourceChannel)
   - **کاربری**: تخصیص پهنای باند با مختصات تصادفی.
   - **دستورات**:
     ```bash
     peer chaincode invoke -C ResourceChannel -n LocationBasedBandwidth -c '{"function":"AllocateBandwidth","Args":["user1","Antenna1","100","40.7128","-74.0060"]}' --tls --cafile /crypto-config/ordererOrganizations/example.com/orderers/orderer1.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
     ```
4. **LocationBasedQoS** (PerformanceChannel)
5. **LocationBasedPriority** (PolicyChannel)
6. **LocationBasedStatus** (ConnectivityChannel)
7. **LocationBasedFault** (AuditChannel)
8. **LocationBasedTraffic** (PerformanceChannel)
9. **LocationBasedLatency** (PerformanceChannel)
10. **LocationBasedEnergy** (PerformanceChannel)
11. **LocationBasedRoaming** (ConnectivityChannel)
12. **LocationBasedSignalStrength** (PerformanceChannel)
13. **LocationBasedCoverage** (PerformanceChannel)
14. **LocationBasedInterference** (PerformanceChannel)
15. **LocationBasedResourceAllocation** (ResourceChannel)
16. **LocationBasedNetworkLoad** (PerformanceChannel)
17. **LocationBasedCongestion** (PerformanceChannel)
18. **LocationBasedDynamicRouting** (ConnectivityChannel)
19. **LocationBasedAntennaConfig** (GeneralOperationsChannel)
20. **LocationBasedSignalQuality** (PerformanceChannel)
21. **LocationBasedNetworkHealth** (PerformanceChannel)
22. **LocationBasedPowerManagement** (PerformanceChannel)
23. **LocationBasedChannelAllocation** (ConnectivityChannel)
24. **LocationBasedSessionManagement** (SessionChannel)
25. **LocationBasedIoTConnection** (IoTChannel)
26. **LocationBasedIoTBandwidth** (IoTChannel)
27. **LocationBasedIoTStatus** (IoTChannel)
28. **LocationBasedIoTFault** (IoTChannel)
29. **LocationBasedIoTSession** (IoTChannel)
30. **LocationBasedIoTAuthentication** (IoTChannel)
31. **LocationBasedIoTRegistration** (IoTChannel)
32. **LocationBasedIoTRevocation** (IoTChannel)
33. **LocationBasedIoTResource** (IoTChannel)
34. **LocationBasedNetworkPerformance** (PerformanceChannel)
35. **LocationBasedUserActivity** (AuditChannel)

### قراردادهای عمومی (50)
1. **AuthenticateUser** (SecurityChannel)
   - **کاربری**: احراز هویت کاربران.
   - **دستورات**:
     ```bash
     peer chaincode invoke -C SecurityChannel -n AuthenticateUser -c '{"function":"AuthenticateUser","Args":["user1","token123"]}' --tls --cafile /crypto-config/ordererOrganizations/example.com/orderers/orderer1.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
     ```
2. **AuthenticateIoT** (IoTChannel)
3. **ConnectUser** (ConnectivityChannel)
4. **ConnectIoT** (IoTChannel)
5. **RegisterUser** (SecurityChannel)
6. **RegisterIoT** (IoTChannel)
7. **RevokeUser** (SecurityChannel)
8. **RevokeIoT** (IoTChannel)
9. **AssignRole** (GeneralOperationsChannel)
10. **GrantAccess** (PolicyChannel)
11. **LogIdentityAudit** (AuditChannel)
12. **AllocateIoTBandwidth** (IoTChannel)
13. **UpdateAntennaLoad** (PerformanceChannel)
14. **RequestResource** (ResourceChannel)
15. **ShareSpectrum** (ResourceChannel)
16. **AssignGeneralPriority** (PolicyChannel)
17. **LogResourceAudit** (AuditChannel)
18. **BalanceLoad** (PerformanceChannel)
19. **AllocateDynamic** (ResourceChannel)
20. **UpdateAntennaStatus** (PerformanceChannel)
21. **UpdateIoTStatus** (IoTChannel)
22. **LogNetworkPerformance** (PerformanceChannel)
23. **LogUserActivity** (AuditChannel)
24. **DetectAntennaFault** (PerformanceChannel)
25. **DetectIoTFault** (IoTChannel)
26. **MonitorAntennaTraffic** (PerformanceChannel)
27. **GenerateReport** (GeneralOperationsChannel)
28. **TrackLatency** (PerformanceChannel)
29. **MonitorEnergy** (PerformanceChannel)
30. **PerformRoaming** (ConnectivityChannel)
31. **TrackSession** (SessionChannel)
32. **TrackIoTSession** (IoTChannel)
33. **DisconnectEntity** (ConnectivityChannel)
34. **GenerateBill** (BillingChannel)
35. **LogTransaction** (AuditChannel)
36. **LogConnectionAudit** (AuditChannel)
37. **EncryptData** (SecurityChannel)
38. **EncryptIoTData** (IoTChannel)
39. **LogAccess** (AuditChannel)
40. **DetectIntrusion** (SecurityChannel)
41. **ManageKey** (SecurityChannel)
42. **SetPolicy** (PolicyChannel)
43. **CreateSecureChannel** (SecurityChannel)
44. **LogSecurityAudit** (AuditChannel)
45. **AuthenticateAntenna** (SecurityChannel)
46. **MonitorNetworkCongestion** (PerformanceChannel)
47. **AllocateNetworkResource** (ResourceChannel)
48. **MonitorNetworkHealth** (PerformanceChannel)
49. **ManageNetworkPolicy** (PolicyChannel)
50. **LogNetworkAudit** (AuditChannel)

## تست با متغیرهای مختلف
- **متغیرها**:
  - TPS: 5، 10
  - تعداد تراکنش‌ها: 50
  - تعداد کاربران: 10
  - تعداد دستگاه‌های IoT: 5
- **رابط وب**:
  ```json
  {
    "tps": 5,
    "txNumber": 50,
    "contract": "LocationBasedAssignment",
    "users": 10,
    "iot": 5,
    "channels": ["GeneralOperationsChannel", "IoTChannel"],
    "testMethod": "Caliper"
  }
  ```
- **دسترسی**: `http://6gfabric.local:3000/run-test` برای اجرا و `http://6gfabric.local:3000/report` برای گزارش.

## تولید گزارش
- گزارش Caliper: `caliper-workspace/report.html`
- گزارش Tape: `tape.log`
