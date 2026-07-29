# معماری کامل قراردادها و کانال‌ها

استخراج‌شده از کد Go در ده اسکریپت `generateChaincodes_part*.sh`. هر ادعای این
سند از خود کد آمده، نه از نام توابع و نه از نگاشت خودکار `contract-fn-map.js` —
چون هدف پیدا کردن جاهایی بود که آن نگاشت اشتباه کرده.

## ۱. شکل کلی سامانه

| | |
|---|---|
| قرارداد | 86 |
| کانال | 20 |
| هدف بنچمارک (کانال × قرارداد) | 90 |
| وابسته‌مکان (پارامتر x,y) | 34 |
| دارای تابع Validate خواندنی | 36 |
| دارای تابع نوشتن دوم | 8 |
| مسدود | 9 |

**الگوی مشترک هر ۸۶ قرارداد.** همه دقیقاً یک ساختار داده دارند، همه فیلد
`timestamp` دارند (از `GetTxTimestamp` می‌آید نه `time.Now` — همان اصلاح قطعیت
که قبلاً انجام شد)، و در هر ۸۵ قرارداد نوشتنی **کلید دفتر همان پارامتر اول است**.
این یکنواختی چیز خوبی است: یعنی یک workload عمومی می‌تواند همه را پوشش دهد،
و همان کاری است که `generic-write.js` می‌کند.

**اسکلت مشترک هر قرارداد:**

```go
func (s *X) Init(ctx) error                          // خالی — هیچ کاری نمی‌کند
func (s *X) <تابع اصلی>(ctx, id, ...) error          // PutState(id, json)
func (s *X) QueryAsset(ctx, id) (*T, error)          // GetState — خطا اگر نبود
func (s *X) QueryAllAssets(ctx) ([]*T, error)        // GetStateByRange("","")
func (s *X) Validate<...>(ctx, id, max) (bool, error) // فقط در ۳۶ قرارداد
```

## ۲. خانواده‌های مدل داده

قراردادها بر اساس شکل ساختارشان به چند خانواده می‌افتند. این برای بنچمارک مهم
است چون اندازه payload و هزینه سریال‌سازی را تعیین می‌کند.

| فیلدها | تعداد | نمونه |
|---|---|---|
| `deviceID, status, timestamp` | 4 | ManageIoTDevice, MonitorIoT … |
| `amount, entityID, resource, timestamp` | 3 | AllocateResource, LogResourceAudit … |
| `policy, policyID, timestamp` | 3 | GetPolicy, SetPolicy … |
| `deviceID, distance, status, timestamp, x, y` | 3 | LocationBasedIoTRegistration, LocationBasedIoTRevocation … |
| `status, timestamp, userID` | 3 | ManageUser, RegisterUser … |
| `data, entityID, timestamp` | 2 | DecryptData, EncryptData |
| `antennaID, distance, entityID, timestamp, x, y` | 2 | LocationBasedAssignment, LocationBasedRoaming |
| `action, entityID, timestamp` | 2 | LogAccessAudit, LogAccessControl |
| `entityID, metric, timestamp, value` | 2 | LogPerformance, LogPerformanceAudit |
| `entityID, event, timestamp` | 2 | LogSecurityAudit, LogSecurityEvent |

**خانواده وابسته‌مکان** (34 قرارداد) فیلدهای `x`، `y` و `distance`
دارند و در تابع اصلی `calculateDistance` را صدا می‌زنند — یعنی هر تراکنش یک
محاسبه اقلیدسی با `math.Sqrt` انجام می‌دهد. این تنها جایی است که قراردادها بار
محاسباتی واقعی دارند؛ بقیه فقط JSON می‌سازند و می‌نویسند.

برای پایان‌نامه: مقایسه گذردهی این دو خانواده، هزینه محاسبه درون‌قراردادی را
جدا می‌کند از هزینه مسیر تأیید-ترتیب-کامیت.

## ۳. نه قرارداد مسدود — با کد

### ۳ــ۱  هفت قرارداد وابسته به آنتن — قفل بوت‌استرپ

```go
func (s *LocationBasedAssignment) AssignAntenna(ctx, entityID, antennaID, x, y string) error {
    antenna, err := s.QueryAsset(ctx, antennaID)   // ← رکورد باید از قبل باشد
    if err != nil { return fmt.Errorf("failed to query antenna: %v", err) }
    distance, _ := calculateDistance(x, y, antenna.X, antenna.Y)
    ...
    return ctx.GetStub().PutState(entityID, assignmentJSON)
}

func (s *LocationBasedAssignment) QueryAsset(ctx, entityID string) (*Assignment, error) {
    if assetJSON == nil {
        return nil, fmt.Errorf("assignment %s does not exist", entityID)  // ← خطا
    }
}

func (s *LocationBasedAssignment) Init(ctx) error { return nil }   // ← خالی
```

تنها تابع نوشتن به رکوردی نیاز دارد که فقط خودش می‌سازد. «رکورد آنتن» چیز
خاصی نیست — یک رکورد `Assignment` معمولی با کلید `antennaID` در همان فضای حالت.

**نکته‌ای که ساده به نظر می‌رسد ولی نیست:** در فابریک هر chaincode فضای حالت
مستقل دارد. آنتن‌هایی که `ManageAntenna` ثبت می‌کند برای این هفت‌تا نامرئی‌اند.
پس هر هفت باید جداگانه بذرکاری شوند — و هیچ‌کدام تابعی برای این کار ندارند.

| قرارداد | کانال | تابع اصلی | ساختار |
|---|---|---|---|
| LocationBasedAssignment | datachannel | `AssignAntenna(entityID, antennaID, x, y)` | Assignment |
| LocationBasedBandwidth | datachannel | `AssignBandwidth(entityID, antennaID, bandwidth, x, y)` | Bandwidth |
| LocationBasedConnection | connectivitychannel | `ConnectEntity(entityID, antennaID, x, y)` | Connection |
| LocationBasedIoTBandwidth | iotchannel | `AllocateIoTBandwidth(deviceID, antennaID, bandwidth, x, y)` | IoTBandwidth |
| LocationBasedIoTConnection | iotchannel | `ConnectIoT(deviceID, antennaID, x, y)` | IoTConnection |
| LocationBasedQoS | analyticschannel | `AssignQoS(entityID, antennaID, qosLevel, x, y)` | QoS |
| LocationBasedRoaming | connectivitychannel | `PerformRoaming(entityID, antennaID, x, y)` | RoamingRecord |

### ۳ــ۲  GetPolicy — کد مرده

توابع موجود: `Init`، `QueryAsset`، `QueryAllAssets`

هیچ تابع نوشتنی ندارد و هیچ‌چیز به فضای حالتش نمی‌نویسد. `SetPolicy` یک
chaincode جداست با فضای حالت جدا، پس `GetPolicy.QueryAsset` همیشه خطای
«وجود ندارد» می‌دهد. نه نوشتنی است نه خواندنی.

### ۳ــ۳  VerifyIdentity — مسدود نیست، اشتباه رده‌بندی شده

```go
func (s *VerifyIdentity) Verify(entityID, verified: bool) error {
    identity := Identity{EntityID: entityID, Verified: verified, Timestamp: txTimestamp(ctx)}
    return ctx.GetStub().PutState(entityID, identityJSON)   // نوشتن کور
}
```

تابع نوشتن دارد و هیچ خواندنی قبلش نیست. **تنها قرارداد شبکه با پارامتر
غیر-رشته‌ای** (`bool`) و نگاشت خودکار دقیقاً به همین دلیل ردش کرده.

هزینه فعال‌سازی: صفر. `contractapi` رشته `"true"` را با `strconv.ParseBool`
خودش تبدیل می‌کند.

## ۴. تعارض MVCC — یک قرارداد استثناست

از ۸۵ قرارداد نوشتنی، 84 تا **نوشتن کور** هستند: مستقیم
`PutState` بدون خواندن قبلی. فقط اینها خواندن-تغییر-نوشتن‌اند:

- **UpdatePolicy** روی `policychannel` — `Update(policyID, policy)`
  ابتدا `policyID` را می‌خواند، سپس بازمی‌نویسد.

**چرا این برای Tape خطرناک است.** Tape آرگومان‌ها را ثابت نگه می‌دارد و هر
۱۰۰۰ تراکنش را روی همان کلید می‌فرستد. برای نوشتن کور بی‌ضرر است — تراکنش‌ها
روی هم می‌نویسند و همه معتبرند. ولی برای خواندن-تغییر-نوشتن، هر تراکنش نسخه
کلید را می‌خواند و تراکنش بعدی همان نسخه را نامعتبر می‌کند →
`MVCC_READ_CONFLICT`.

نکته ظریف: Tape این تراکنش‌ها را **کامیت‌شده می‌شمارد**، چون در بلاک هستند.
اعتبارسنجی بعد از ترتیب‌دهی اتفاق می‌افتد و Tape آن مرحله را نمی‌بیند. پس عددی
که برای `UpdatePolicy` می‌دهد گذردهی نیست — نرخ تراکنش‌های نوشته‌شده در بلاک
است که اکثرشان نامعتبرند.

Caliper این مشکل را ندارد چون کلید یکتا می‌نویسد و وضعیت واقعی را چک می‌کند.
**این خودش یک یافته روش‌شناختی قابل گزارش است.**

## ۵. توابع نوشتن دومی که هرگز بنچمارک نمی‌شوند

کاتالوگ فقط تابع نوشتن اول هر قرارداد را می‌گیرد. اینها هم وجود دارند:

| قرارداد | کانال | تابع اول | تابع دوم |
|---|---|---|---|
| ConnectIoT | connectivitychannel | `Connect` | `Disconnect(deviceID)` |
| ConnectUser | connectivitychannel | `Connect` | `Disconnect(userID)` |
| LocationBasedBandwidth | datachannel | `AssignBandwidth` | `UpdateBandwidth(entityID, newBandwidth)` |
| LocationBasedConnection | connectivitychannel | `ConnectEntity` | `DisconnectEntity(entityID)` |
| LocationBasedIoTConnection | iotchannel | `ConnectIoT` | `DisconnectIoT(deviceID)` |
| LocationBasedPriority | compliancechannel | `AssignPriority` | `UpdatePriority(entityID, newPriority)` |
| LocationBasedQoS | analyticschannel | `AssignQoS` | `UpdateQoS(entityID, newQoSLevel)` |
| ManageSession | sessionchannel | `StartSession` | `EndSession(entityID)` |

این توابع مسیر کد متفاوتی دارند — `Update*` معمولاً رکورد موجود را می‌خواند و
یک فیلد را عوض می‌کند، `Disconnect*`/`End*` وضعیت را تغییر می‌دهند. **بدون هیچ
تغییری در chaincode** می‌توانند بُعد دوم ارزیابی باشند: مقایسه ایجاد در برابر
به‌روزرسانی.

## ۶. توابع Validate — بار خواندنی سنگین‌تر

36 قرارداد تابع `Validate*` دارند که
رکورد را می‌خواند و یک محاسبه انجام می‌دهد:

```go
func (s *X) ValidateAssignmentDistance(ctx, entityID, maxDistance string) (bool, error) {
    asset, err := s.QueryAsset(ctx, entityID)
    // مقایسه asset.Distance با maxDistance
}
```

اینها از `QueryAsset` ساده سنگین‌ترند (خواندن + تجزیه + محاسبه) و از تابع
نوشتن سبک‌ترند (بدون ترتیب‌دهی و کامیت). یعنی یک نقطه میانی برای سنجش —
مفید اگر بخواهید هزینه خواندن را از هزینه اجماع تفکیک کنید.

## ۷. کانال به کانال

### networkchannel

**وضعیت و بار کل شبکه** — 4 قرارداد، 2 وابسته‌مکان.

رکوردهای سطح شبکه، نه سطح موجودیت. حجم تراکنش کم ولی هر تراکنش سنگین‌تر.

| قرارداد | تابع | پارامترها | ساختار | وضعیت |
|---|---|---|---|---|
| LocationBasedNetworkLoad | `RecordNetworkLoad` | entityID, load, x, y | NetworkLoadRecord | ✅ مکانی |
| LocationBasedNetworkHealth | `RecordNetworkHealth` | entityID, healthStatus, x, y | NetworkHealth | ✅ مکانی |
| ManageNetwork | `UpdateNetworkStatus` | networkID, status | Network | ✅ |
| MonitorNetwork | `RecordStatus` | networkID, status | NetworkMonitor | ✅ |

### resourcechannel

**تخصیص منابع رادیویی** — 5 قرارداد، 2 وابسته‌مکان.

تخصیص طیف و پهنای باند. مدل داده amount/resource دارد.

| قرارداد | تابع | پارامترها | ساختار | وضعیت |
|---|---|---|---|---|
| LocationBasedResourceAllocation | `AllocateResource` | entityID, resourceID, amount, x, y | ResourceAllocation | ✅ مکانی |
| LocationBasedIoTResource | `AllocateIoTResource` | deviceID, resourceID, amount, x, y | IoTResource | ✅ مکانی |
| AllocateResource | `Allocate` | entityID, resource, amount | ResourceAllocation | ✅ |
| LogResourceAudit | `LogResourceAudit` | entityID, resource, amount | ResourceAuditLog | ✅ |
| MonitorResourceUsage | `RecordUsage` | entityID, resource, amount | ResourceUsage | ✅ |

### performancechannel

**سنجه‌های کارایی** — 4 قرارداد، 1 وابسته‌مکان.

تأخیر و گذردهی مشاهده‌شده شبکه — داده تله‌متری.

| قرارداد | تابع | پارامترها | ساختار | وضعیت |
|---|---|---|---|---|
| LocationBasedLatency | `RecordLatency` | entityID, latency, x, y | Latency | ✅ مکانی |
| LogPerformance | `LogPerformance` | entityID, metric, value | PerformanceLog | ✅ |
| LogNetworkPerformance | `Log` | networkID, metric, value | NetworkPerformanceLog | ✅ |
| LogPerformanceAudit | `Log` | entityID, metric, value | PerformanceAuditLog | ✅ |

### iotchannel

**دستگاه‌های IoT** — 8 قرارداد، 5 وابسته‌مکان، 2 مسدود.

پرجمعیت‌ترین کانال از نظر تعداد موجودیت واقعی؛ پنج قرارداد از هشت وابسته‌مکان.

| قرارداد | تابع | پارامترها | ساختار | وضعیت |
|---|---|---|---|---|
| LocationBasedIoTConnection | `ConnectIoT` | deviceID, antennaID, x, y | IoTConnection | 🔴 بذر |
| LocationBasedIoTBandwidth | `AllocateIoTBandwidth` | deviceID, antennaID, bandwidth, x, y | IoTBandwidth | 🔴 بذر |
| LocationBasedIoTStatus | `UpdateIoTStatus` | deviceID, status, x, y | IoTStatus | ✅ مکانی |
| LocationBasedIoTFault | `ReportIoTFault` | deviceID, faultType, x, y | IoTFault | ✅ مکانی |
| LocationBasedIoTSession | `StartIoTSession` | deviceID, sessionID, x, y, status | IoTSession | ✅ مکانی |
| ManageIoTDevice | `UpdateDeviceStatus` | deviceID, status | IoTDevice | ✅ |
| MonitorIoT | `RecordStatus` | deviceID, status | IoTMonitor | ✅ |
| LogIoTActivity | `Log` | deviceID, activity | IoTActivityLog | ✅ |

مشترک با کانال دیگر: **LocationBasedIoTFault** (faultchannel)، **LocationBasedIoTSession** (sessionchannel).

### authchannel

**احراز هویت** — 4 قرارداد، 1 وابسته‌مکان.

توکن و تأیید هویت کاربر و دستگاه. مسیر بحرانی تأخیر در شبکه واقعی.

| قرارداد | تابع | پارامترها | ساختار | وضعیت |
|---|---|---|---|---|
| LocationBasedIoTAuthentication | `AuthenticateIoT` | deviceID, token, x, y | IoTAuthentication | ✅ مکانی |
| AuthenticateUser | `Authenticate` | userID, token | UserAuth | ✅ |
| AuthenticateIoT | `Authenticate` | deviceID, token | IoTAuth | ✅ |
| VerifyIdentity | `Verify` | entityID, verified:bool | Identity | ✅ |

### connectivitychannel

**اتصال و رومینگ** — 5 قرارداد، 2 وابسته‌مکان، 2 مسدود.

برقراری و قطع اتصال؛ تنها کانالی که هم Connect و هم Disconnect دارد.

| قرارداد | تابع | پارامترها | ساختار | وضعیت |
|---|---|---|---|---|
| LocationBasedConnection | `ConnectEntity` | entityID, antennaID, x, y | Connection | 🔴 بذر |
| LocationBasedRoaming | `PerformRoaming` | entityID, antennaID, x, y | RoamingRecord | 🔴 بذر |
| ConnectUser | `Connect` | userID, antennaID | UserConnection | ✅ |
| ConnectIoT | `Connect` | deviceID, antennaID | IoTConnection | ✅ |
| LogConnectionAudit | `Log` | entityID, antennaID, action | ConnectionAuditLog | ✅ |

### sessionchannel

**مدیریت نشست** — 5 قرارداد، 2 وابسته‌مکان.

چرخه عمر نشست؛ StartSession/EndSession جفت متقارن.

| قرارداد | تابع | پارامترها | ساختار | وضعیت |
|---|---|---|---|---|
| LocationBasedSessionManagement | `ManageSession` | entityID, sessionID, x, y, status | SessionManagement | ✅ مکانی |
| LocationBasedIoTSession | `StartIoTSession` | deviceID, sessionID, x, y, status | IoTSession | ✅ مکانی |
| ManageSession | `StartSession` | entityID, sessionID | Session | ✅ |
| LogSession | `LogSession` | entityID, sessionID, status | SessionLog | ✅ |
| LogSessionAudit | `Log` | entityID, sessionID, action | SessionAuditLog | ✅ |

مشترک با کانال دیگر: **LocationBasedIoTSession** (iotchannel).

### policychannel

**سیاست‌های شبکه** — 5 قرارداد، 0 وابسته‌مکان، 1 مسدود.

تنها کانالی که قرارداد خواندن-تغییر-نوشتن دارد — رفتار MVCC متفاوت.

| قرارداد | تابع | پارامترها | ساختار | وضعیت |
|---|---|---|---|---|
| SetPolicy | `Set` | policyID, policy | Policy | ✅ |
| GetPolicy | `—` | — | Policy | 🔴 بدون نوشتن |
| UpdatePolicy | `Update` | policyID, policy | Policy | ⚠️ خواندن-نوشتن |
| LogPolicyAudit | `Log` | policyID, action | PolicyAudit | ✅ |
| LogPolicyChange | `Log` | policyID, change | PolicyChangeLog | ✅ |

### auditchannel

**ردگیری و حسابرسی** — 7 قرارداد، 0 وابسته‌مکان.

فقط الحاق (append-only)؛ هیچ قرارداد وابسته‌مکانی ندارد. سبک‌ترین بار.

| قرارداد | تابع | پارامترها | ساختار | وضعیت |
|---|---|---|---|---|
| LogNetworkAudit | `Log` | networkID, action | NetworkAuditLog | ✅ |
| LogAntennaAudit | `Log` | antennaID, action | AntennaAuditLog | ✅ |
| LogIoTAudit | `Log` | deviceID, action | IoTAuditLog | ✅ |
| LogUserAudit | `Log` | userID, action | UserAuditLog | ✅ |
| LogAccessAudit | `Log` | entityID, action | AccessAuditLog | ✅ |
| LogSecurityAudit | `Log` | entityID, event | SecurityAuditLog | ✅ |
| LogComplianceAudit | `Log` | entityID, complianceStatus | ComplianceAuditLog | ✅ |

مشترک با کانال دیگر: **LogComplianceAudit** (compliancechannel).

### securitychannel

**رمزنگاری و امنیت** — 4 قرارداد، 0 وابسته‌مکان.

رمزگذاری/رمزگشایی داده؛ payload بزرگ‌تر از بقیه.

| قرارداد | تابع | پارامترها | ساختار | وضعیت |
|---|---|---|---|---|
| EncryptData | `Encrypt` | entityID, data | EncryptedData | ✅ |
| DecryptData | `Decrypt` | entityID, data | DecryptedData | ✅ |
| SecureCommunication | `Establish` | entityID, channelID | Communication | ✅ |
| LogSecurityEvent | `Log` | entityID, event | SecurityEvent | ✅ |

### datachannel

**اندازه‌گیری سیگنال** — 4 قرارداد، 4 وابسته‌مکان، 2 مسدود.

هر چهار قرارداد وابسته‌مکان — بیشترین حساسیت به جای‌گذاری تصادفی.

| قرارداد | تابع | پارامترها | ساختار | وضعیت |
|---|---|---|---|---|
| LocationBasedAssignment | `AssignAntenna` | entityID, antennaID, x, y | Assignment | 🔴 بذر |
| LocationBasedBandwidth | `AssignBandwidth` | entityID, antennaID, bandwidth, x, y | Bandwidth | 🔴 بذر |
| LocationBasedSignalStrength | `RecordSignalStrength` | entityID, signal, x, y | SignalStrengthRecord | ✅ مکانی |
| LocationBasedSignalQuality | `RecordSignalQuality` | entityID, signalQuality, x, y | SignalQuality | ✅ مکانی |

مشترک با کانال دیگر: **LocationBasedSignalStrength** (integrationchannel).

### analyticschannel

**تحلیل پوشش و انرژی** — 3 قرارداد، 3 وابسته‌مکان، 1 مسدود.

هر سه وابسته‌مکان؛ محاسبات عددی سنگین‌تر.

| قرارداد | تابع | پارامترها | ساختار | وضعیت |
|---|---|---|---|---|
| LocationBasedQoS | `AssignQoS` | entityID, antennaID, qosLevel, x, y | QoS | 🔴 بذر |
| LocationBasedCoverage | `RecordCoverage` | entityID, coverage, x, y | CoverageRecord | ✅ مکانی |
| LocationBasedEnergy | `RecordEnergy` | entityID, energy, x, y | EnergyRecord | ✅ مکانی |

### monitoringchannel

**پایش ترافیک و تداخل** — 3 قرارداد، 1 وابسته‌مکان.

داده پیوسته با نرخ بالا در شبکه واقعی.

| قرارداد | تابع | پارامترها | ساختار | وضعیت |
|---|---|---|---|---|
| MonitorTraffic | `RecordTraffic` | networkID, traffic | Traffic | ✅ |
| MonitorInterference | `RecordInterference` | networkID, interferenceLevel | Interference | ✅ |
| LocationBasedStatus | `UpdateStatus` | entityID, status, x, y | Status | ✅ مکانی |

### managementchannel

**مدیریت آنتن و کاربر** — 5 قرارداد، 3 وابسته‌مکان.

پیکربندی و توان؛ عملیات کم‌تکرار ولی حیاتی.

| قرارداد | تابع | پارامترها | ساختار | وضعیت |
|---|---|---|---|---|
| ManageAntenna | `UpdateAntennaStatus` | antennaID, status | Antenna | ✅ |
| ManageUser | `UpdateUserStatus` | userID, status | User | ✅ |
| LocationBasedAntennaConfig | `SetAntennaConfig` | antennaID, config, x, y | AntennaConfig | ✅ مکانی |
| LocationBasedPowerManagement | `SetPowerLevel` | entityID, powerLevel, x, y | PowerManagement | ✅ مکانی |
| LocationBasedChannelAllocation | `AllocateChannel` | entityID, channelID, x, y | ChannelAllocation | ✅ مکانی |

### optimizationchannel

**بهینه‌سازی شبکه** — 3 قرارداد، 1 وابسته‌مکان.

توازن بار و مسیریابی پویا.

| قرارداد | تابع | پارامترها | ساختار | وضعیت |
|---|---|---|---|---|
| OptimizeNetwork | `Optimize` | networkID, strategy | NetworkOptimization | ✅ |
| BalanceLoad | `Balance` | networkID, load | LoadBalance | ✅ |
| LocationBasedDynamicRouting | `SetDynamicRoute` | entityID, route, x, y | DynamicRouting | ✅ مکانی |

### faultchannel

**ثبت خرابی** — 3 قرارداد، 2 وابسته‌مکان.

رویدادمحور؛ در شبکه واقعی نرخ پایین ولی انفجاری.

| قرارداد | تابع | پارامترها | ساختار | وضعیت |
|---|---|---|---|---|
| LocationBasedFault | `ReportFault` | entityID, faultType, x, y | Fault | ✅ مکانی |
| LocationBasedIoTFault | `ReportIoTFault` | deviceID, faultType, x, y | IoTFault | ✅ مکانی |
| LogFault | `LogFault` | entityID, faultType | FaultLog | ✅ |

مشترک با کانال دیگر: **LocationBasedIoTFault** (iotchannel).

### trafficchannel

**ترافیک و ازدحام** — 3 قرارداد، 2 وابسته‌مکان.

داده تله‌متری با نرخ بالا.

| قرارداد | تابع | پارامترها | ساختار | وضعیت |
|---|---|---|---|---|
| LocationBasedTraffic | `RecordTraffic` | entityID, traffic, x, y | Traffic | ✅ مکانی |
| LogTraffic | `LogTraffic` | entityID, traffic | TrafficLog | ✅ |
| LocationBasedCongestion | `RecordCongestion` | entityID, congestion, x, y | Congestion | ✅ مکانی |

### accesschannel

**ثبت و لغو دسترسی** — 8 قرارداد، 2 وابسته‌مکان.

بیشترین تعداد قرارداد (۸)؛ ثبت‌نام و ابطال.

| قرارداد | تابع | پارامترها | ساختار | وضعیت |
|---|---|---|---|---|
| RegisterUser | `Register` | userID, status | UserRegistration | ✅ |
| RegisterIoT | `Register` | deviceID, status | IoTRegistration | ✅ |
| RevokeUser | `Revoke` | userID, status | UserRevocation | ✅ |
| RevokeIoT | `Revoke` | deviceID, status | IoTRevocation | ✅ |
| AssignRole | `Assign` | userID, role | RoleAssignment | ✅ |
| LocationBasedIoTRegistration | `RegisterIoT` | deviceID, status, x, y | IoTRegistration | ✅ مکانی |
| LocationBasedIoTRevocation | `RevokeIoT` | deviceID, status, x, y | IoTRevocation | ✅ مکانی |
| LogAccessControl | `Log` | entityID, action | AccessControl | ✅ |

### compliancechannel

**انطباق مقرراتی** — 2 قرارداد، 1 وابسته‌مکان.

کوچک‌ترین کانال (۲ قرارداد).

| قرارداد | تابع | پارامترها | ساختار | وضعیت |
|---|---|---|---|---|
| LogComplianceAudit | `Log` | entityID, complianceStatus | ComplianceAuditLog | ✅ |
| LocationBasedPriority | `AssignPriority` | entityID, priority, x, y | Priority | ✅ مکانی |

مشترک با کانال دیگر: **LogComplianceAudit** (auditchannel).

### integrationchannel

**یکپارچه‌سازی** — 5 قرارداد، 3 وابسته‌مکان.

قراردادهای مشترک با کانال‌های دیگر — محل تکرار.

| قرارداد | تابع | پارامترها | ساختار | وضعیت |
|---|---|---|---|---|
| LocationBasedInterference | `RecordInterference` | entityID, interferenceLevel, x, y | InterferenceRecord | ✅ مکانی |
| LocationBasedSignalStrength | `RecordSignalStrength` | entityID, signal, x, y | SignalStrengthRecord | ✅ مکانی |
| LocationBasedUserActivity | `RecordUserActivity` | userID, activity, x, y | UserActivity | ✅ مکانی |
| LogUserActivity | `Log` | userID, activity | UserActivityLog | ✅ |
| LogInterference | `LogInterference` | entityID, interferenceLevel | InterferenceLog | ✅ |

مشترک با کانال دیگر: **LocationBasedSignalStrength** (datachannel).

## ۸. دلالت‌ها برای برنامه ارزیابی

### کدام کانال برای چه آزمایشی

| هدف آزمایش | کانال پیشنهادی | چرا |
|---|---|---|
| پایه تمیز، کمترین متغیر | `auditchannel` | ۷ قرارداد، همه نوشتن کور، هیچ وابستگی مکانی، هیچ مسدودی |
| اثر جای‌گذاری فضایی | `datachannel` | هر ۴ قرارداد وابسته‌مکان |
| بار محاسباتی درون‌قرارداد | `analyticschannel` | هر ۳ وابسته‌مکان با محاسبه سنگین‌تر |
| رفتار MVCC | `policychannel` | تنها کانال با قرارداد خواندن-تغییر-نوشتن |
| بیشترین تنوع | `iotchannel` | ۸ قرارداد، ۵ مکانی، ۲ مسدود، ۲ تابع دوم |
| بزرگ‌ترین دامنه | `accesschannel` | ۸ قرارداد، همه سالم |

### سه بُعد که همین حالا بدون تغییر chaincode در دسترس‌اند

1. **نوشتن کور در برابر خواندن-تغییر-نوشتن** — ۸۴ در برابر ۱
2. **وابسته‌مکان در برابر ساده** — ۳۴ در برابر ۵۲؛ هزینه `calculateDistance`
3. **تابع اول در برابر تابع دوم** — ۸ قرارداد هر دو را دارند

### آنچه تغییر chaincode باز می‌کند

- ۷ قرارداد وابسته به آنتن → کل خانواده `Assign*` قابل سنجش می‌شود
- `GetPolicy` → یک قرارداد فقط‌خواندنی واقعی برای مقایسه خواندن/نوشتن

### ترتیب پیشنهادی

**گام ۱ (رایگان):** `VerifyIdentity` را فعال کنید — فقط اصلاح کاتالوگ، بدون
ارتقا. جاروی کل شبکه با ۸۲ هدف. این اولین داده کامل شماست و مشخص می‌کند آیا
مشکل دیگری در ۸۲ هدف پنهان مانده.

**گام ۲:** ۸ chaincode را تغییر و ارتقا دهید → ۹۰ هدف.

**گام ۳:** جای‌گذاری تصادفی با بذر ثابت برای آن ۳۴ قرارداد مکانی.

دلیل این ترتیب: اگر همه را یک‌جا عوض کنیم و چیزی بشکند، نمی‌دانیم از کدام
تغییر بود. گام ۱ عملاً رایگان است و پایه مقایسه می‌سازد.
