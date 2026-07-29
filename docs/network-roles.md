# نقش هر قرارداد و کانال در شبکه — و اینکه واقعاً چطور کار می‌کند

این سند از بدنه توابع Go نوشته شده، نه از نامشان. جاهایی که نام یک قرارداد
کاری را وعده می‌دهد که کد انجام نمی‌دهد، صریح گفته شده — چون برای پایان‌نامه
نوشتن «قرارداد رمزنگاری» درباره کدی که رمزنگاری نمی‌کند، ادعای نادرستی است.

## ۱. دفتر اینجا چه نقشی دارد

پیش از هر جزئیاتی، مهم‌ترین نکته درباره کل سامانه:

**هیچ قراردادی عملیات شبکه را انجام نمی‌دهد. همه فقط ثبت می‌کنند که انجام شد.**

نمونه‌ای که این را روشن می‌کند:

```go
func (s *EncryptData) Encrypt(ctx, entityID, data string) error {
    encrypted := EncryptedData{
        EntityID:  entityID,
        Data:      data,            // ← داده همان‌طور که آمده ذخیره می‌شود
        Timestamp: txTimestamp(ctx),
    }
    return ctx.GetStub().PutState(entityID, encryptedJSON)
}
```

`Encrypt` هیچ رمزگذاری‌ای نمی‌کند. `Decrypt` هیچ رمزگشایی‌ای نمی‌کند.
`Authenticate` توکن را اعتبارسنجی نمی‌کند. `Optimize` چیزی را بهینه نمی‌کند.
`BalanceLoad` باری را متوازن نمی‌کند.

**این لزوماً ایراد نیست.** این معماری رایج بلاکچین در مخابرات است: عملیات
واقعی در تجهیزات شبکه انجام می‌شود و دفتر یک **ردپای غیرقابل‌انکار و مشترک
بین اپراتورها** می‌سازد. ارزش دفتر در اجرا نیست، در توافق است — هشت سازمان
روی یک روایت واحد از آنچه رخ داده به اجماع می‌رسند.

اما در نگارش پایان‌نامه باید دقیق باشید: این سامانه **لایه ثبت و اجماع** برای
شبکه 6G است، نه لایه اجرا. و برای بنچمارک این خبر خوبی است — چون یعنی زمانی
که اندازه می‌گیرید تقریباً خالص هزینه **تأیید، ترتیب‌دهی و کامیت** است، نه
منطق کسب‌وکار.

## ۲. سه سطح منطق — و اینکه چقدر از شبکه واقعاً «مکان‌محور» است

از ۸۵ تابع نوشتنی اصلی:

| سطح | تعداد | چه می‌کند |
|---|---|---|
| **ثبت خالص** | ۵۰ | ساختار می‌سازد، JSON می‌کند، می‌نویسد. تمام. |
| **شبه‌مکانی** | ۲۷ | فاصله را از **مبدأ (0,0)** حساب می‌کند |
| **مکانی واقعی** | ۷ | فاصله را تا **رکورد آنتن واقعی** حساب می‌کند |
| **خواندن-تغییر-نوشتن** | ۱ | رکورد موجود را می‌خواند و بازمی‌نویسد |

### نکته‌ای که احتمالاً انتظارش را ندارید

۲۷ قرارداد از خانواده `LocationBased*` این کار را می‌کنند:

```go
distance, err := calculateDistance(x, y, "0", "0")   // ← مبدأ نقشه
```

یعنی `distance` که ذخیره می‌کنند فقط `√(x² + y²)` است — فاصله تا گوشه نقشه.
**هیچ معنای شبکه‌ای ندارد**: فاصله تا آنتن سرویس‌دهنده نیست، تا هیچ آنتنی نیست.
نام `LocationBased` برای این ۲۷ تا گمراه‌کننده است؛ اینها مختصات را *ثبت*
می‌کنند ولی از آن *استفاده* نمی‌کنند.

فقط این ۷ قرارداد منطق مکانی واقعی دارند:

```go
antenna, err := s.QueryAsset(ctx, antennaID)              // آنتن واقعی
distance, err := calculateDistance(x, y, antenna.X, antenna.Y)   // فاصله واقعی
```

- **LocationBasedAssignment** — تخصیص موجودیت به آنتن — با فاصله واقعی تا آن آنتن
- **LocationBasedBandwidth** — پهنای باند تخصیص‌یافته از یک آنتن مشخص
- **LocationBasedConnection** — اتصال موجودیت به آنتن — با فاصله واقعی تا آن آنتن
- **LocationBasedIoTBandwidth** — پهنای باند تخصیص‌یافته به دستگاه از یک آنتن مشخص
- **LocationBasedIoTConnection** — اتصال دستگاه IoT به آنتن — با فاصله واقعی تا آن آنتن
- **LocationBasedQoS** — سطح کیفیت سرویس تخصیص‌یافته از یک آنتن مشخص
- **LocationBasedRoaming** — جابه‌جایی موجودیت بین آنتن‌ها — با فاصله واقعی

**و این دقیقاً همان ۷ تایی است که قفل بوت‌استرپ دارند و نمی‌توانند اجرا شوند.**

یعنی: تنها بخشی از شبکه که واقعاً «مکان‌محور» است، تنها بخشی است که کار
نمی‌کند. این برای تصمیم شما درباره تغییر chaincode تعیین‌کننده است — اگر
موضوع پایان‌نامه شبکه مکان‌محور 6G است، بدون این ۷ قرارداد ادعای مکان‌محوری
پشتوانه اجرایی ندارد.

## ۳. بازیگران شبکه

| بازیگر | در سامانه | تعداد |
|---|---|---|
| آنتن ماکروسل | یک سازمان فابریک با peer خودش | ۸ |
| دستگاه IoT | فرستنده کوچک با شناسه `deviceID` | متغیر |
| کاربر | گیرنده با شناسه `userID` | متغیر |
| شبکه | موجودیت انتزاعی با `networkID` | ۱ |

هر سازمان = یک آنتن. تراکنش هر موجودیت از دروازه سازمانی می‌رود که آنتنش
نزدیک‌ترین است (تخصیص ورونوی). این یعنی در یک آزمایش با جای‌گذاری واقعی،
بار به‌طور طبیعی بین ۸ peer پخش می‌شود — نه اینکه همه روی org1 بیفتد.

شناسه‌ها در ساختارها: `entityID` در ۴۴ قرارداد، `deviceID` در ۱۷،
`userID` در ۹، `networkID` در ۸. این پراکندگی نشان می‌دهد کدام قرارداد برای
کدام بازیگر نوشته شده.

## ۴. چرخه عمر یک دستگاه IoT — مسیر واقعی در سامانه

برای فهم اینکه قراردادها چطور کنار هم کار می‌کنند، مسیر یک دستگاه را دنبال کنیم:

| گام | کانال | قرارداد | چه ثبت می‌شود |
|---|---|---|---|
| ۱. ثبت‌نام | accesschannel | `RegisterIoT` | دستگاه وارد شبکه شد |
| ۲. احراز هویت | authchannel | `AuthenticateIoT` | با این توکن تأیید شد |
| ۳. اتصال | iotchannel | `LocationBasedIoTConnection` | به کدام آنتن، با چه فاصله‌ای 🔴 |
| ۴. پهنای باند | iotchannel | `LocationBasedIoTBandwidth` | چقدر ظرفیت گرفت 🔴 |
| ۵. نشست | iotchannel | `LocationBasedIoTSession` | نشست فعال شد |
| ۶. فعالیت | iotchannel | `LogIoTActivity` | چه کاری کرد |
| ۷. پایش | monitoringchannel | `MonitorTraffic` | چقدر ترافیک تولید کرد |
| ۸. خرابی | faultchannel | `LocationBasedIoTFault` | اگر مشکلی پیش آمد |
| ۹. ابطال | accesschannel | `RevokeIoT` | دسترسی قطع شد |
| ۱۰. حسابرسی | auditchannel | `LogIoTAudit` | ردپای همه اینها |

🔴 = مسدود. **دو گام از ده گام چرخه عمر قابل اجرا نیست** — و هر دو همان
گام‌هایی هستند که به آنتن واقعی وصل می‌شوند.

### چرا این گام‌ها به هم وصل نیستند

نکته‌ای که در فابریک تازه‌کارها را غافلگیر می‌کند: **هر chaincode فضای حالت
کاملاً مستقل دارد.** یعنی `RegisterIoT` که دستگاه را ثبت می‌کند، و
`AuthenticateIoT` که احراز هویتش می‌کند، هیچ‌کدام نمی‌توانند رکورد دیگری را
ببینند. هیچ قراردادی بررسی نمی‌کند که دستگاه از قبل ثبت شده باشد.

پس این «چرخه عمر» یک روایت است، نه یک زنجیره اجباری. هر گام مستقل قابل
اجراست. برای بنچمارک این خوب است (هر هدف را می‌شود جدا سنجید)، ولی یعنی
سامانه یکپارچگی ارجاعی ندارد.

## ۵. کانال به کانال — نقش و سازوکار

### networkchannel — وضعیت کل شبکه

رکوردهای سطح شبکه — بار، سلامت، پیکربندی. موجودیت اینجا خودِ شبکه است، نه کاربر یا دستگاه.

| قرارداد | نقش | تابع | ثبت می‌کند |
|---|---|---|---|
| **LocationBasedNetworkLoad** | بار لحظه‌ای شبکه در یک نقطه — چقدر ظرفیت مصرف شده | `RecordNetworkLoad` | entityID, load, x, y, distance |
| **LocationBasedNetworkHealth** | سلامت شبکه در یک نقطه — وضعیت کلی سرویس | `RecordNetworkHealth` | entityID, healthStatus, x, y, distance |
| **ManageNetwork** | تغییر پیکربندی سطح شبکه — چه چیزی و کِی عوض شد | `UpdateNetworkStatus` | networkID, status |
| **MonitorNetwork** | سنجه پایش شبکه — مقدار یک متریک در یک لحظه | `RecordStatus` | networkID, status |

### resourcechannel — تخصیص منابع رادیویی

چه کسی چه مقدار از کدام منبع را گرفت. در شبکه واقعی این طیف، بلوک زمانی-فرکانسی یا ظرفیت backhaul است.

| قرارداد | نقش | تابع | ثبت می‌کند |
|---|---|---|---|
| **LocationBasedResourceAllocation** | تخصیص منبع رادیویی به یک موجودیت در یک نقطه | `AllocateResource` | entityID, resourceID, amount, x, y, distance |
| **LocationBasedIoTResource** | تخصیص منبع به یک دستگاه IoT در یک نقطه | `AllocateIoTResource` | deviceID, resourceID, amount, x, y, distance |
| **AllocateResource** | تخصیص مقدار مشخصی از یک منبع نام‌دار به یک موجودیت | `Allocate` | entityID, resource, amount |
| **LogResourceAudit** | ردپای حسابرسی برای هر عمل روی منابع | `LogResourceAudit` | entityID, resource, amount |
| **MonitorResourceUsage** | میزان مصرف جاری یک منبع | `RecordUsage` | entityID, resource, amount |

### performancechannel — سنجه‌های کارایی

تله‌متری: تأخیر و کارایی مشاهده‌شده. داده‌ای که اپراتور برای SLA لازم دارد.

| قرارداد | نقش | تابع | ثبت می‌کند |
|---|---|---|---|
| **LocationBasedLatency** | تأخیر مشاهده‌شده در یک نقطه از شبکه | `RecordLatency` | entityID, latency, x, y, distance |
| **LogPerformance** | ثبت یک سنجه کارایی نام‌دار با مقدارش | `LogPerformance` | entityID, metric, value |
| **LogNetworkPerformance** | ثبت کارایی در سطح شبکه، نه موجودیت | `Log` | networkID, metric, value |
| **LogPerformanceAudit** | ردپای حسابرسی برای رویدادهای کارایی | `Log` | entityID, metric, value |

### iotchannel — چرخه عمر دستگاه IoT

پرتنوع‌ترین کانال: اتصال، پهنای باند، وضعیت، خرابی، نشست، مدیریت، پایش و فعالیت — یعنی کل عمر یک دستگاه.

| قرارداد | نقش | تابع | ثبت می‌کند |
|---|---|---|---|
| **LocationBasedIoTConnection** 🔴 | اتصال دستگاه IoT به آنتن — با فاصله واقعی تا آن آنتن | `ConnectIoT` | deviceID, antennaID, x, y, distance, status |
| **LocationBasedIoTBandwidth** 🔴 | پهنای باند تخصیص‌یافته به دستگاه از یک آنتن مشخص | `AllocateIoTBandwidth` | deviceID, antennaID, bandwidth, x, y, distance |
| **LocationBasedIoTStatus** | وضعیت جاری دستگاه IoT در یک موقعیت | `UpdateIoTStatus` | deviceID, status, x, y, distance |
| **LocationBasedIoTFault** | خرابی گزارش‌شده از یک دستگاه IoT در یک موقعیت | `ReportIoTFault` | deviceID, faultType, x, y, distance |
| **LocationBasedIoTSession** | نشست فعال یک دستگاه IoT | `StartIoTSession` | deviceID, sessionID, x, y, distance, status |
| **ManageIoTDevice** | تغییر وضعیت مدیریتی دستگاه (فعال/غیرفعال/تعمیر) | `UpdateDeviceStatus` | deviceID, status |
| **MonitorIoT** | سنجه پایش یک دستگاه IoT | `RecordStatus` | deviceID, status |
| **LogIoTActivity** | ثبت فعالیت دستگاه — چه کاری انجام داد | `Log` | deviceID, activity |

🔴 LocationBasedIoTConnection، LocationBasedIoTBandwidth — قفل بوت‌استرپ آنتن

روی کانال دیگر هم هست: **LocationBasedIoTFault** (faultchannel)، **LocationBasedIoTSession** (sessionchannel). توجه: هر کانال نسخه مستقل خودش را دارد — حالتشان مشترک نیست.

### authchannel — احراز هویت

ثبت اینکه چه کسی با چه توکنی و کِی احراز هویت شد. مسیر بحرانی تأخیر در شبکه واقعی.

| قرارداد | نقش | تابع | ثبت می‌کند |
|---|---|---|---|
| **LocationBasedIoTAuthentication** | احراز هویت دستگاه IoT همراه با موقعیتش | `AuthenticateIoT` | deviceID, token, x, y, distance |
| **AuthenticateUser** | ثبت اینکه کاربر با این توکن احراز هویت شد | `Authenticate` | userID, token |
| **AuthenticateIoT** | ثبت اینکه دستگاه با این توکن احراز هویت شد | `Authenticate` | deviceID, token |
| **VerifyIdentity** | نتیجه تأیید هویت یک موجودیت (بله/خیر) | `Verify` | entityID, verified |

### connectivitychannel — اتصال و رومینگ

برقراری، قطع و جابه‌جایی بین آنتن‌ها. تنها کانالی که هم اتصال و هم قطع اتصال دارد.

| قرارداد | نقش | تابع | ثبت می‌کند |
|---|---|---|---|
| **LocationBasedConnection** 🔴 | اتصال موجودیت به آنتن — با فاصله واقعی تا آن آنتن | `ConnectEntity` | entityID, antennaID, x, y, distance, status |
| **LocationBasedRoaming** 🔴 | جابه‌جایی موجودیت بین آنتن‌ها — با فاصله واقعی | `PerformRoaming` | entityID, antennaID, x, y, distance |
| **ConnectUser** | برقراری و قطع اتصال کاربر | `Connect` | userID, antennaID, status |
| **ConnectIoT** | برقراری و قطع اتصال دستگاه IoT | `Connect` | deviceID, antennaID, status |
| **LogConnectionAudit** | ردپای حسابرسی برای رویدادهای اتصال | `Log` | entityID, antennaID, action |

🔴 LocationBasedConnection، LocationBasedRoaming — قفل بوت‌استرپ آنتن

### sessionchannel — مدیریت نشست

چرخه عمر نشست از شروع تا پایان — لایه بالاتر از اتصال.

| قرارداد | نقش | تابع | ثبت می‌کند |
|---|---|---|---|
| **LocationBasedSessionManagement** | مدیریت نشست همراه با موقعیت | `ManageSession` | entityID, sessionID, x, y, distance, status |
| **LocationBasedIoTSession** | نشست فعال یک دستگاه IoT | `StartIoTSession` | deviceID, sessionID, x, y, distance, status |
| **ManageSession** | شروع و پایان نشست — جفت متقارن | `StartSession` | entityID, sessionID, status |
| **LogSession** | ثبت رویداد نشست | `LogSession` | entityID, sessionID, status |
| **LogSessionAudit** | ردپای حسابرسی برای نشست‌ها | `Log` | entityID, sessionID, action |

روی کانال دیگر هم هست: **LocationBasedIoTSession** (iotchannel). توجه: هر کانال نسخه مستقل خودش را دارد — حالتشان مشترک نیست.

### policychannel — سیاست‌های شبکه

قواعد حاکم بر شبکه. تنها کانالی که قرارداد خواندن-تغییر-نوشتن دارد.

| قرارداد | نقش | تابع | ثبت می‌کند |
|---|---|---|---|
| **SetPolicy** | ثبت یک سیاست شبکه | `Set` | policyID, policy |
| **GetPolicy** 🔴 | خواندن سیاست — ولی فضای حالتش هرگز پر نمی‌شود | `—` | policyID, policy |
| **UpdatePolicy** ⚠️ | به‌روزرسانی سیاست موجود — تنها قرارداد خواندن-تغییر-نوشتن | `Update` | policyID, policy |
| **LogPolicyAudit** | ردپای حسابرسی برای تغییرات سیاست | `Log` | policyID, action |
| **LogPolicyChange** | ثبت اینکه چه تغییری در سیاست داده شد | `Log` | policyID, change |

🔴 GetPolicy — بدون تابع نوشتن

### auditchannel — ردپای حسابرسی

هفت قرارداد که همه یک کار می‌کنند: ثبت غیرقابل‌انکار اینکه چه اتفاقی افتاد. هیچ منطقی ندارند — و همین نکته است.

| قرارداد | نقش | تابع | ثبت می‌کند |
|---|---|---|---|
| **LogNetworkAudit** | ردپای حسابرسی رویدادهای شبکه | `Log` | networkID, action |
| **LogAntennaAudit** | ردپای حسابرسی عملیات آنتن | `Log` | antennaID, action |
| **LogIoTAudit** | ردپای حسابرسی رویدادهای IoT | `Log` | deviceID, action |
| **LogUserAudit** | ردپای حسابرسی اعمال کاربر | `Log` | userID, action |
| **LogAccessAudit** | ردپای حسابرسی دسترسی‌ها | `Log` | entityID, action |
| **LogSecurityAudit** | ردپای حسابرسی رویدادهای امنیتی | `Log` | entityID, event |
| **LogComplianceAudit** | ردپای حسابرسی انطباق مقرراتی | `Log` | entityID, complianceStatus |

روی کانال دیگر هم هست: **LogComplianceAudit** (compliancechannel). توجه: هر کانال نسخه مستقل خودش را دارد — حالتشان مشترک نیست.

### securitychannel — رویدادهای امنیتی

ثبت رمزگذاری، رمزگشایی، ارتباط امن و رویداد امنیتی. هیچ‌کدام عملیات رمزنگاری واقعی انجام نمی‌دهند.

| قرارداد | نقش | تابع | ثبت می‌کند |
|---|---|---|---|
| **EncryptData** | ثبت اینکه داده‌ای رمزگذاری شد — خود رمزگذاری را انجام نمی‌دهد | `Encrypt` | entityID, data |
| **DecryptData** | ثبت اینکه داده‌ای رمزگشایی شد — خود رمزگشایی را انجام نمی‌دهد | `Decrypt` | entityID, data |
| **SecureCommunication** | برقراری کانال ارتباطی امن بین موجودیت و یک channelID | `Establish` | entityID, channelID, status |
| **LogSecurityEvent** | ثبت یک رویداد امنیتی | `Log` | entityID, event |

### datachannel — اندازه‌گیری رادیویی

قدرت و کیفیت سیگنال، تخصیص و پهنای باند. نزدیک‌ترین کانال به لایه فیزیکی.

| قرارداد | نقش | تابع | ثبت می‌کند |
|---|---|---|---|
| **LocationBasedAssignment** 🔴 | تخصیص موجودیت به آنتن — با فاصله واقعی تا آن آنتن | `AssignAntenna` | entityID, antennaID, x, y, distance |
| **LocationBasedBandwidth** 🔴 | پهنای باند تخصیص‌یافته از یک آنتن مشخص | `AssignBandwidth` | entityID, antennaID, bandwidth, x, y, distance |
| **LocationBasedSignalStrength** | قدرت سیگنال اندازه‌گیری‌شده در یک نقطه (dBm) | `RecordSignalStrength` | entityID, signal, x, y, distance |
| **LocationBasedSignalQuality** | کیفیت سیگنال اندازه‌گیری‌شده در یک نقطه | `RecordSignalQuality` | entityID, signalQuality, x, y, distance |

🔴 LocationBasedAssignment، LocationBasedBandwidth — قفل بوت‌استرپ آنتن

روی کانال دیگر هم هست: **LocationBasedSignalStrength** (integrationchannel). توجه: هر کانال نسخه مستقل خودش را دارد — حالتشان مشترک نیست.

### analyticschannel — تحلیل پوشش و انرژی

کیفیت سرویس، پوشش و مصرف انرژی — داده‌ای که برای برنامه‌ریزی شبکه لازم است.

| قرارداد | نقش | تابع | ثبت می‌کند |
|---|---|---|---|
| **LocationBasedQoS** 🔴 | سطح کیفیت سرویس تخصیص‌یافته از یک آنتن مشخص | `AssignQoS` | entityID, antennaID, qosLevel, x, y, distance |
| **LocationBasedCoverage** | میزان پوشش در یک نقطه | `RecordCoverage` | entityID, coverage, x, y, distance |
| **LocationBasedEnergy** | مصرف انرژی در یک نقطه | `RecordEnergy` | entityID, energy, x, y, distance |

🔴 LocationBasedQoS — قفل بوت‌استرپ آنتن

### monitoringchannel — پایش لحظه‌ای

ترافیک، تداخل و وضعیت. در شبکه واقعی پرنرخ‌ترین جریان داده.

| قرارداد | نقش | تابع | ثبت می‌کند |
|---|---|---|---|
| **MonitorTraffic** | حجم ترافیک جاری | `RecordTraffic` | networkID, traffic |
| **MonitorInterference** | سطح تداخل رادیویی | `RecordInterference` | networkID, interferenceLevel |
| **LocationBasedStatus** | وضعیت عمومی یک موجودیت در یک موقعیت | `UpdateStatus` | entityID, status, x, y, distance |

### managementchannel — مدیریت زیرساخت

آنتن، کاربر، پیکربندی، توان و کانال فرکانسی. عملیات کم‌تکرار ولی پرتأثیر.

| قرارداد | نقش | تابع | ثبت می‌کند |
|---|---|---|---|
| **ManageAntenna** | تغییر وضعیت مدیریتی آنتن | `UpdateAntennaStatus` | antennaID, status |
| **ManageUser** | تغییر وضعیت مدیریتی کاربر | `UpdateUserStatus` | userID, status |
| **LocationBasedAntennaConfig** | پیکربندی آنتن در یک موقعیت | `SetAntennaConfig` | antennaID, config, x, y, distance |
| **LocationBasedPowerManagement** | سطح توان ارسال در یک موقعیت | `SetPowerLevel` | entityID, powerLevel, x, y, distance |
| **LocationBasedChannelAllocation** | تخصیص کانال فرکانسی در یک موقعیت | `AllocateChannel` | entityID, channelID, x, y, distance |

### optimizationchannel — بهینه‌سازی

راهبرد بهینه‌سازی، توازن بار و مسیریابی پویا — تصمیم‌هایی که شبکه خودکار می‌گیرد.

| قرارداد | نقش | تابع | ثبت می‌کند |
|---|---|---|---|
| **OptimizeNetwork** | ثبت اینکه چه راهبرد بهینه‌سازی اعمال شد | `Optimize` | networkID, strategy |
| **BalanceLoad** | ثبت وضعیت توازن بار شبکه | `Balance` | networkID, load |
| **LocationBasedDynamicRouting** | مسیر انتخاب‌شده برای یک موجودیت در یک موقعیت | `SetDynamicRoute` | entityID, route, x, y, distance |

### faultchannel — خرابی

گزارش خرابی از نقاط مختلف شبکه. نرخ پایین ولی انفجاری.

| قرارداد | نقش | تابع | ثبت می‌کند |
|---|---|---|---|
| **LocationBasedFault** | خرابی گزارش‌شده در یک نقطه | `ReportFault` | entityID, faultType, x, y, distance |
| **LocationBasedIoTFault** | خرابی گزارش‌شده از یک دستگاه IoT در یک موقعیت | `ReportIoTFault` | deviceID, faultType, x, y, distance |
| **LogFault** | ثبت یک خرابی نام‌دار | `LogFault` | entityID, faultType |

روی کانال دیگر هم هست: **LocationBasedIoTFault** (iotchannel). توجه: هر کانال نسخه مستقل خودش را دارد — حالتشان مشترک نیست.

### trafficchannel — ترافیک و ازدحام

حجم و ازدحام. جریان داده پیوسته.

| قرارداد | نقش | تابع | ثبت می‌کند |
|---|---|---|---|
| **LocationBasedTraffic** | حجم ترافیک در یک نقطه | `RecordTraffic` | entityID, traffic, x, y, distance |
| **LogTraffic** | ثبت حجم ترافیک یک موجودیت | `LogTraffic` | entityID, traffic |
| **LocationBasedCongestion** | میزان ازدحام در یک نقطه | `RecordCongestion` | entityID, congestion, x, y, distance |

### accesschannel — کنترل دسترسی

بزرگ‌ترین کانال (۸ قرارداد): ثبت‌نام، ابطال و نقش برای هر دو نوع موجودیت.

| قرارداد | نقش | تابع | ثبت می‌کند |
|---|---|---|---|
| **RegisterUser** | ثبت‌نام کاربر جدید در شبکه | `Register` | userID, status |
| **RegisterIoT** | ثبت‌نام دستگاه IoT جدید | `Register` | deviceID, status |
| **RevokeUser** | ابطال دسترسی کاربر | `Revoke` | userID, status |
| **RevokeIoT** | ابطال دسترسی دستگاه | `Revoke` | deviceID, status |
| **AssignRole** | تخصیص نقش دسترسی به کاربر | `Assign` | userID, role |
| **LocationBasedIoTRegistration** | ثبت‌نام دستگاه همراه با موقعیتش | `RegisterIoT` | deviceID, status, x, y, distance |
| **LocationBasedIoTRevocation** | ابطال دستگاه همراه با موقعیتش | `RevokeIoT` | deviceID, status, x, y, distance |
| **LogAccessControl** | ثبت تصمیم کنترل دسترسی | `Log` | entityID, action |

### compliancechannel — انطباق مقرراتی

کوچک‌ترین کانال (۲ قرارداد): حسابرسی انطباق و اولویت.

| قرارداد | نقش | تابع | ثبت می‌کند |
|---|---|---|---|
| **LogComplianceAudit** | ردپای حسابرسی انطباق مقرراتی | `Log` | entityID, complianceStatus |
| **LocationBasedPriority** | اولویت تخصیص‌یافته به موجودیت در یک موقعیت | `AssignPriority` | entityID, priority, x, y, distance |

روی کانال دیگر هم هست: **LogComplianceAudit** (auditchannel). توجه: هر کانال نسخه مستقل خودش را دارد — حالتشان مشترک نیست.

### integrationchannel — یکپارچه‌سازی

تداخل و فعالیت کاربر — سه قرارداد مشترک با کانال‌های دیگر دارد.

| قرارداد | نقش | تابع | ثبت می‌کند |
|---|---|---|---|
| **LocationBasedInterference** | سطح تداخل در یک نقطه | `RecordInterference` | entityID, interferenceLevel, x, y, distance |
| **LocationBasedSignalStrength** | قدرت سیگنال اندازه‌گیری‌شده در یک نقطه (dBm) | `RecordSignalStrength` | entityID, signal, x, y, distance |
| **LocationBasedUserActivity** | فعالیت کاربر در یک موقعیت | `RecordUserActivity` | userID, activity, x, y, distance |
| **LogUserActivity** | ثبت فعالیت کاربر | `Log` | userID, activity |
| **LogInterference** | ثبت سطح تداخل | `LogInterference` | entityID, interferenceLevel |

روی کانال دیگر هم هست: **LocationBasedSignalStrength** (datachannel). توجه: هر کانال نسخه مستقل خودش را دارد — حالتشان مشترک نیست.

## ۶. الگوهای تکرارشونده که ارزش دانستن دارند

### هفت قرارداد حسابرسی که همه یک کار می‌کنند

`auditchannel` هفت قرارداد دارد — `LogNetworkAudit`، `LogAntennaAudit`،
`LogIoTAudit`، `LogUserAudit`، `LogAccessAudit`، `LogSecurityAudit`،
`LogComplianceAudit` — و هر هفت ساختار یکسانی دارند و یک کار می‌کنند: یک
رکورد با شناسه، یک عمل و یک زمان می‌نویسند.

تفکیکشان معنایی است نه فنی: هر کدام فضای حالت جدا دارد، پس حسابرسی شبکه با
حسابرسی امنیت قاطی نمی‌شود. برای بنچمارک این یعنی `auditchannel` **تمیزترین
پایه ممکن** است: هفت هدف با رفتار یکسان، صفر وابستگی، صفر محاسبه.

### جفت‌های متقارن

هشت قرارداد تابع دوم دارند که عمل معکوس را ثبت می‌کند:

| قرارداد | ایجاد | معکوس |
|---|---|---|
| ConnectIoT | `Connect` | `Disconnect` |
| ConnectUser | `Connect` | `Disconnect` |
| LocationBasedBandwidth | `AssignBandwidth` | `UpdateBandwidth` |
| LocationBasedConnection | `ConnectEntity` | `DisconnectEntity` |
| LocationBasedIoTConnection | `ConnectIoT` | `DisconnectIoT` |
| LocationBasedPriority | `AssignPriority` | `UpdatePriority` |
| LocationBasedQoS | `AssignQoS` | `UpdateQoS` |
| ManageSession | `StartSession` | `EndSession` |

در شبکه واقعی این جفت‌ها چرخه کامل را می‌سازند: اتصال/قطع، شروع/پایان نشست،
تخصیص/به‌روزرسانی. **هیچ‌کدام از توابع معکوس تا حالا بنچمارک نشده‌اند** چون
کاتالوگ فقط تابع اول را می‌گیرد.

### توابع Validate — لایه خواندنی که استفاده نمی‌شود

36 قرارداد تابع `Validate*` دارند:

```go
func (s *X) ValidateAssignmentDistance(ctx, entityID, maxDistance string) (bool, error) {
    asset, err := s.QueryAsset(ctx, entityID)
    // آیا asset.Distance از maxDistance کمتر است؟
}
```

نقششان در شبکه: بررسی اینکه یک موجودیت هنوز در محدوده آنتنش هست یا نه — یعنی
تصمیم handover. هیچ‌جای سامانه فعلی صدایشان نمی‌زند.

## ۷. جمع‌بندی برای تصمیم شما

### آنچه سامانه هست

یک **لایه ثبت و اجماع** برای شبکه 6G: هشت اپراتور (آنتن) روی یک روایت واحد از
رویدادهای شبکه به توافق می‌رسند. ۲۰ کانال، ۸۶ قرارداد، پوشش کل چرخه عمر
دستگاه و کاربر — از ثبت‌نام تا ابطال، با ردپای حسابرسی کامل.

### آنچه نیست

لایه اجرا. رمزنگاری، احراز هویت، بهینه‌سازی و توازن بار **ثبت می‌شوند، انجام
نمی‌شوند**. و ۲۷ قرارداد `LocationBased*` مختصات را ثبت می‌کنند ولی از آن
استفاده نمی‌کنند.

### چرا این برای تصمیم «همه قراردادها فعال شوند» مهم است

تنها ۷ قراردادی که منطق مکانی واقعی دارند، همان ۷ تایی هستند که قفل‌اند.
اگر آنها را فعال نکنید:

- بنچمارک شما ۸۲ هدف را می‌سنجد که همه تقریباً یک کار می‌کنند (ساخت ساختار و نوشتن)
- تنوع اعداد از اندازه payload و تعداد پارامتر می‌آید، نه از تفاوت منطق
- ادعای «مکان‌محور» در پایان‌نامه پشتوانه اجرایی ندارد

اگر فعالشان کنید:

- خانواده `Assign*` قابل سنجش می‌شود — تنها قراردادهایی که پیش از نوشتن می‌خوانند
- مقایسه «نوشتن کور» در برابر «خواندن سپس نوشتن» ممکن می‌شود، که یک بُعد
  واقعی کارایی در فابریک است
- جای‌گذاری تصادفی معنا پیدا می‌کند، چون فاصله واقعاً محاسبه می‌شود

### هزینه

۸ chaincode تغییر و ارتقا روی ۶ کانال. بدون بازسازی شبکه یا کانال.
