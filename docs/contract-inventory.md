# موجودی کامل قراردادها و کانال‌ها

استخراج‌شده مستقیماً از کد Go در ده اسکریپت `generateChaincodes_part*.sh` —
نه از نگاشت خودکار `contract-fn-map.js`، چون هدف پیدا کردن جاهایی بود که آن
نگاشت اشتباه کرده است.

## خلاصه

| | |
|---|---|
| منابع Go تجزیه‌شده | 86 |
| قرارداد در کاتالوگ | 86 (هیچ‌کدام گم‌شده) |
| کانال | 20 |
| هدف (جفت کانال×قرارداد) | 90 — چهار قرارداد روی دو کانال |
| قرارداد با تابع نوشتن | 85 |
| قرارداد وابسته به مکان (x,y) | 34 |
| قرارداد مسدود | 9 → **پس از اصلاح: صفر** |

## چرا ۹ قرارداد مسدودند — سه علت کاملاً متفاوت

### الف) VerifyIdentity — مسدود نیست، اشتباه رده‌بندی شده

```go
func (s *VerifyIdentity) Verify(ctx, entityID string, verified bool) error {
    identity := Identity{EntityID: entityID, Verified: verified, ...}
    return ctx.GetStub().PutState(entityID, identityJSON)   // نوشتن کور
}
```

تابع نوشتن دارد و هیچ خواندنی قبلش نیست. تنها قرارداد شبکه است که پارامتر
غیر-رشته‌ای دارد (`bool`)، و نگاشت خودکار به همین دلیل ردش کرده.

**هزینه فعال‌سازی: صفر.** contractapi رشته `"true"` را خودش به bool تبدیل می‌کند.

### ب) هفت قرارداد Assign* — قفل بوت‌استرپ در خود chaincode

```go
func (s *LocationBasedAssignment) AssignAntenna(ctx, entityID, antennaID, x, y string) error {
    antenna, err := s.QueryAsset(ctx, antennaID)   // رکورد باید از قبل باشد
    if err != nil { return ... }
    ...
}
func (s *LocationBasedAssignment) QueryAsset(ctx, entityID string) (*Assignment, error) {
    if assetJSON == nil { return nil, fmt.Errorf("... does not exist") }
}
func (s *LocationBasedAssignment) Init(ctx) error { return nil }   // هیچ کاری نمی‌کند
```

تنها تابع نوشتن به رکوردی نیاز دارد که فقط خودش می‌تواند بسازد. «رکورد آنتن»
چیز خاصی نیست — یک رکورد معمولی در همان فضای حالت با کلید `antennaID`.

در فابریک هر chaincode فضای حالت مستقل دارد، پس آنتن‌هایی که `ManageAntenna`
ثبت می‌کند برای این هفت‌تا نامرئی‌اند. **هر هفت جداگانه قفل‌اند.**

| قرارداد | کانال | تابع اصلی |
|---|---|---|
| LocationBasedAssignment | datachannel | `AssignAntenna(entityID, antennaID, x, y)` |
| LocationBasedBandwidth | datachannel | `AssignBandwidth(entityID, antennaID, bandwidth, x, y)` |
| LocationBasedConnection | connectivitychannel | `ConnectEntity(entityID, antennaID, x, y)` |
| LocationBasedIoTBandwidth | iotchannel | `AllocateIoTBandwidth(deviceID, antennaID, bandwidth, x, y)` |
| LocationBasedIoTConnection | iotchannel | `ConnectIoT(deviceID, antennaID, x, y)` |
| LocationBasedQoS | analyticschannel | `AssignQoS(entityID, antennaID, qosLevel, x, y)` |
| LocationBasedRoaming | connectivitychannel | `PerformRoaming(entityID, antennaID, x, y)` |

### ج) GetPolicy — کد مرده

فقط `Init`، `QueryAsset`، `QueryAllAssets`. هیچ تابع نوشتنی ندارد و هیچ‌چیز
به فضای حالتش نمی‌نویسد (`SetPolicy` یک chaincode جداست با فضای جدا)، پس
خواندن هم همیشه خطا می‌دهد. نه نوشتنی است نه خواندنی.

## دو یافته که در تحلیل بیرون آمد

### تنها یک قرارداد «خواندن-تغییر-نوشتن» است

**UpdatePolicy** روی `policychannel` — تابع `Update`.

این برای Tape مهم است: Tape آرگومان‌ها را ثابت نگه می‌دارد و هر ۱۰۰۰ تراکنش را
روی همان کلید می‌فرستد. برای ۸۴ قرارداد دیگر که نوشتن کورند بی‌ضرر است، ولی
اینجا هر تراکنش همان کلید را می‌خواند و بازمی‌نویسد → **تعارض MVCC**. عددی که
Tape برای این قرارداد می‌دهد گذردهی نیست، نرخ رد شدن است.

Caliper این مشکل را ندارد چون کلید یکتا می‌نویسد.

### هشت قرارداد تابع نوشتن دوم دارند که هرگز بنچمارک نمی‌شود

- **ConnectIoT** — `Connect`, `Disconnect`
- **ConnectUser** — `Connect`, `Disconnect`
- **LocationBasedBandwidth** — `AssignBandwidth`, `UpdateBandwidth`
- **LocationBasedConnection** — `ConnectEntity`, `DisconnectEntity`
- **LocationBasedIoTConnection** — `ConnectIoT`, `DisconnectIoT`
- **LocationBasedPriority** — `AssignPriority`, `UpdatePriority`
- **LocationBasedQoS** — `AssignQoS`, `UpdateQoS`
- **ManageSession** — `StartSession`, `EndSession`

کاتالوگ فقط تابع اول را می‌گیرد. توابع `Update*`/`Disconnect*`/`End*` مسیر
کد متفاوتی دارند (اغلب خواندن-تغییر-نوشتن) و می‌توانند بُعد دوم ارزیابی باشند.

## جدول کانال‌ها

| کانال | قرارداد | مسدود | وابسته‌مکان |
|---|---|---|---|
| networkchannel | 4 | — | 2 |
| resourcechannel | 5 | — | 2 |
| performancechannel | 4 | — | 1 |
| iotchannel | 8 | 2 | 5 |
| authchannel | 4 | — | 1 |
| connectivitychannel | 5 | 2 | 2 |
| sessionchannel | 5 | — | 2 |
| policychannel | 5 | 1 | — |
| auditchannel | 7 | — | — |
| securitychannel | 4 | — | — |
| datachannel | 4 | 2 | 4 |
| analyticschannel | 3 | 1 | 3 |
| monitoringchannel | 3 | — | 1 |
| managementchannel | 5 | — | 3 |
| optimizationchannel | 3 | — | 1 |
| faultchannel | 3 | — | 2 |
| trafficchannel | 3 | — | 2 |
| accesschannel | 8 | — | 2 |
| compliancechannel | 2 | — | 1 |
| integrationchannel | 5 | — | 3 |

«وابسته‌مکان» یعنی تابع اصلی پارامتر `x` و `y` می‌گیرد — ۳۴ قرارداد. اینها
همان‌هایی هستند که از جای‌گذاری تصادفی معنا می‌گیرند؛ برای بقیه مختصات بی‌اثر است.

## فهرست کامل ۸۶ قرارداد

| قرارداد | کانال | تابع نوشتن | پارامترها | وضعیت |
|---|---|---|---|---|
| AllocateResource | resourcechannel | `Allocate` | entityID, resource, amount | ✅ |
| AssignRole | accesschannel | `Assign` | userID, role | ✅ |
| AuthenticateIoT | authchannel | `Authenticate` | deviceID, token | ✅ |
| AuthenticateUser | authchannel | `Authenticate` | userID, token | ✅ |
| BalanceLoad | optimizationchannel | `Balance` | networkID, load | ✅ |
| ConnectIoT | connectivitychannel | `Connect` | deviceID, antennaID | ✅ |
| ConnectUser | connectivitychannel | `Connect` | userID, antennaID | ✅ |
| DecryptData | securitychannel | `Decrypt` | entityID, data | ✅ |
| EncryptData | securitychannel | `Encrypt` | entityID, data | ✅ |
| GetPolicy | policychannel | `—` | — | 🔴 بدون نوشتن |
| LocationBasedAntennaConfig | managementchannel | `SetAntennaConfig` | antennaID, config, x, y | ✅ |
| LocationBasedAssignment | datachannel | `AssignAntenna` | entityID, antennaID, x, y | 🔴 بذر لازم |
| LocationBasedBandwidth | datachannel | `AssignBandwidth` | entityID, antennaID, bandwidth, x, y | 🔴 بذر لازم |
| LocationBasedChannelAllocation | managementchannel | `AllocateChannel` | entityID, channelID, x, y | ✅ |
| LocationBasedCongestion | trafficchannel | `RecordCongestion` | entityID, congestion, x, y | ✅ |
| LocationBasedConnection | connectivitychannel | `ConnectEntity` | entityID, antennaID, x, y | 🔴 بذر لازم |
| LocationBasedCoverage | analyticschannel | `RecordCoverage` | entityID, coverage, x, y | ✅ |
| LocationBasedDynamicRouting | optimizationchannel | `SetDynamicRoute` | entityID, route, x, y | ✅ |
| LocationBasedEnergy | analyticschannel | `RecordEnergy` | entityID, energy, x, y | ✅ |
| LocationBasedFault | faultchannel | `ReportFault` | entityID, faultType, x, y | ✅ |
| LocationBasedInterference | integrationchannel | `RecordInterference` | entityID, interferenceLevel, x, y | ✅ |
| LocationBasedIoTAuthentication | authchannel | `AuthenticateIoT` | deviceID, token, x, y | ✅ |
| LocationBasedIoTBandwidth | iotchannel | `AllocateIoTBandwidth` | deviceID, antennaID, bandwidth, x, y | 🔴 بذر لازم |
| LocationBasedIoTConnection | iotchannel | `ConnectIoT` | deviceID, antennaID, x, y | 🔴 بذر لازم |
| LocationBasedIoTFault | iotchannel, faultchannel | `ReportIoTFault` | deviceID, faultType, x, y | ✅ |
| LocationBasedIoTRegistration | accesschannel | `RegisterIoT` | deviceID, status, x, y | ✅ |
| LocationBasedIoTResource | resourcechannel | `AllocateIoTResource` | deviceID, resourceID, amount, x, y | ✅ |
| LocationBasedIoTRevocation | accesschannel | `RevokeIoT` | deviceID, status, x, y | ✅ |
| LocationBasedIoTSession | iotchannel, sessionchannel | `StartIoTSession` | deviceID, sessionID, x, y, status | ✅ |
| LocationBasedIoTStatus | iotchannel | `UpdateIoTStatus` | deviceID, status, x, y | ✅ |
| LocationBasedLatency | performancechannel | `RecordLatency` | entityID, latency, x, y | ✅ |
| LocationBasedNetworkHealth | networkchannel | `RecordNetworkHealth` | entityID, healthStatus, x, y | ✅ |
| LocationBasedNetworkLoad | networkchannel | `RecordNetworkLoad` | entityID, load, x, y | ✅ |
| LocationBasedPowerManagement | managementchannel | `SetPowerLevel` | entityID, powerLevel, x, y | ✅ |
| LocationBasedPriority | compliancechannel | `AssignPriority` | entityID, priority, x, y | ✅ |
| LocationBasedQoS | analyticschannel | `AssignQoS` | entityID, antennaID, qosLevel, x, y | 🔴 بذر لازم |
| LocationBasedResourceAllocation | resourcechannel | `AllocateResource` | entityID, resourceID, amount, x, y | ✅ |
| LocationBasedRoaming | connectivitychannel | `PerformRoaming` | entityID, antennaID, x, y | 🔴 بذر لازم |
| LocationBasedSessionManagement | sessionchannel | `ManageSession` | entityID, sessionID, x, y, status | ✅ |
| LocationBasedSignalQuality | datachannel | `RecordSignalQuality` | entityID, signalQuality, x, y | ✅ |
| LocationBasedSignalStrength | datachannel, integrationchannel | `RecordSignalStrength` | entityID, signal, x, y | ✅ |
| LocationBasedStatus | monitoringchannel | `UpdateStatus` | entityID, status, x, y | ✅ |
| LocationBasedTraffic | trafficchannel | `RecordTraffic` | entityID, traffic, x, y | ✅ |
| LocationBasedUserActivity | integrationchannel | `RecordUserActivity` | userID, activity, x, y | ✅ |
| LogAccessAudit | auditchannel | `Log` | entityID, action | ✅ |
| LogAccessControl | accesschannel | `Log` | entityID, action | ✅ |
| LogAntennaAudit | auditchannel | `Log` | antennaID, action | ✅ |
| LogComplianceAudit | auditchannel, compliancechannel | `Log` | entityID, complianceStatus | ✅ |
| LogConnectionAudit | connectivitychannel | `Log` | entityID, antennaID, action | ✅ |
| LogFault | faultchannel | `LogFault` | entityID, faultType | ✅ |
| LogInterference | integrationchannel | `LogInterference` | entityID, interferenceLevel | ✅ |
| LogIoTActivity | iotchannel | `Log` | deviceID, activity | ✅ |
| LogIoTAudit | auditchannel | `Log` | deviceID, action | ✅ |
| LogNetworkAudit | auditchannel | `Log` | networkID, action | ✅ |
| LogNetworkPerformance | performancechannel | `Log` | networkID, metric, value | ✅ |
| LogPerformance | performancechannel | `LogPerformance` | entityID, metric, value | ✅ |
| LogPerformanceAudit | performancechannel | `Log` | entityID, metric, value | ✅ |
| LogPolicyAudit | policychannel | `Log` | policyID, action | ✅ |
| LogPolicyChange | policychannel | `Log` | policyID, change | ✅ |
| LogResourceAudit | resourcechannel | `LogResourceAudit` | entityID, resource, amount | ✅ |
| LogSecurityAudit | auditchannel | `Log` | entityID, event | ✅ |
| LogSecurityEvent | securitychannel | `Log` | entityID, event | ✅ |
| LogSession | sessionchannel | `LogSession` | entityID, sessionID, status | ✅ |
| LogSessionAudit | sessionchannel | `Log` | entityID, sessionID, action | ✅ |
| LogTraffic | trafficchannel | `LogTraffic` | entityID, traffic | ✅ |
| LogUserActivity | integrationchannel | `Log` | userID, activity | ✅ |
| LogUserAudit | auditchannel | `Log` | userID, action | ✅ |
| ManageAntenna | managementchannel | `UpdateAntennaStatus` | antennaID, status | ✅ |
| ManageIoTDevice | iotchannel | `UpdateDeviceStatus` | deviceID, status | ✅ |
| ManageNetwork | networkchannel | `UpdateNetworkStatus` | networkID, status | ✅ |
| ManageSession | sessionchannel | `StartSession` | entityID, sessionID | ✅ |
| ManageUser | managementchannel | `UpdateUserStatus` | userID, status | ✅ |
| MonitorInterference | monitoringchannel | `RecordInterference` | networkID, interferenceLevel | ✅ |
| MonitorIoT | iotchannel | `RecordStatus` | deviceID, status | ✅ |
| MonitorNetwork | networkchannel | `RecordStatus` | networkID, status | ✅ |
| MonitorResourceUsage | resourcechannel | `RecordUsage` | entityID, resource, amount | ✅ |
| MonitorTraffic | monitoringchannel | `RecordTraffic` | networkID, traffic | ✅ |
| OptimizeNetwork | optimizationchannel | `Optimize` | networkID, strategy | ✅ |
| RegisterIoT | accesschannel | `Register` | deviceID, status | ✅ |
| RegisterUser | accesschannel | `Register` | userID, status | ✅ |
| RevokeIoT | accesschannel | `Revoke` | deviceID, status | ✅ |
| RevokeUser | accesschannel | `Revoke` | userID, status | ✅ |
| SecureCommunication | securitychannel | `Establish` | entityID, channelID | ✅ |
| SetPolicy | policychannel | `Set` | policyID, policy | ✅ |
| UpdatePolicy | policychannel | `Update` | policyID, policy | ⚠️ خواندن-نوشتن |
| VerifyIdentity | authchannel | `Verify` | entityID, verified:bool | ✅ |
