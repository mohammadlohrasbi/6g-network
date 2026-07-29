# فهرست بسته

## نصب

```bash
./install.sh /root/6g-network        # کپی فایل‌ها و نصب وابستگی
DRY_RUN=1 ./install.sh /root/6g-network   # فقط نشان بده چه می‌کند
```

نصب‌کننده فقط کپی می‌کند و از هر فایلی که جایگزین می‌شود پشتیبان می‌گیرد.
هیچ قراردادی تولید نمی‌کند و هیچ‌چیز مستقر نمی‌کند.

**سپس `RUNBOOK.md` را بخوانید و مسیر A یا B را انتخاب کنید.**

## محتوا

### `scripts/` — روی سرور اجرا می‌شوند

| فایل | نقش |
|---|---|
| `generateChaincodes_part1..4.sh` | جایگزین نسخه قدیمی؛ به اسکریپت مکانی واگذار می‌کنند |
| `generateChaincodes_spatial.sh` | ۳۴ قرارداد مکانی با مدل رادیویی واقعی (۹۳۵KB) |
| `upgrade-spatial.sh` | ارتقای ۳۷ جفت کانال-قرارداد — **فقط شبکه موجود** |
| `seed-network.sh` | چیدمان آنتن در ۳۷ جفت — **بدون این هیچ تراکنشی commit نمی‌شود** |
| `update-fn-map.js` | همگام‌سازی نگاشت توابع با امضاهای جدید |
| `gen-caliper-assets.js` | ۲ workload عمومی + ۶۱ نام‌دار |
| `gen-caliper-network.js` | کانفیگ شبکه Caliper با هر ۹۰ قرارداد |
| `install-test-tools.sh` | نصب Caliper 0.6.0 و Tape |
| `fix-tape-policy.sh` | هم‌ترازی سیاست Tape با سیاست مستقر |
| `add-test-endpoint.sh` | راستی‌آزمایی نصب |
| `gen-spatial-contracts.js` | مولد اسکریپت مکانی (برای بازتولید) |
| `check-go.js` | بررسی ساختاری کد Go بدون کامپایلر |

### `server/`

`bench-catalog.js` (تک‌منبع حقیقت: ۲۰ کانال، ۹۰ هدف)،
`bench-runner.js` (اجرای پس‌زمینه)، `bench-routes.js` (`/api/bench/*`)،
`contract-fn-map.js` (امضای ۸۵ قرارداد)، `patch-index.sh` (شش اصلاح idempotent)،
`scenario-core.js` (اصلاح‌شده — بذر را به قراردادها پاس می‌دهد و چیدمان آنتن را
از دفتر می‌پذیرد)

### `public/`

`test.html`، `test-app.js`، `styles.css` — صفحه Benchmark با پنج حالت انتخاب
دامنه، دو تب مجزا Tape/Caliper و ماتریس پوشش

### `docs/` — مرجع، اجرا نمی‌شوند

| سند | محتوا |
|---|---|
| `contract-inventory.md` | فهرست ۸۶ قرارداد با تابع، پارامتر و وضعیت |
| `architecture-guide.md` | معماری، خانواده‌های داده، دلالت‌های ارزیابی |
| `network-roles.md` | نقش هر قرارداد و کانال در شبکه و سازوکارش |
| `spatial-signatures.md` | امضاهای جدید ۳۴ قرارداد مکانی |

### `reference/` — برای مطالعه

`radio.go` (هسته رادیویی با توضیح هر تصمیم)، `radio-mirror.js` (آینه
جاوااسکریپت که الگوریتم‌ها با آن اعتبارسنجی شدند)، `analyse-contracts.js` و
`analyse-deep.js` (تحلیلگرهایی که اسناد `docs/` را از کد Go استخراج کردند)

## آنچه در بسته نیست

فایل‌های پایه مخزن — `network.sh`، `deploy-staged.sh`، `deploy_functions.sh`،
`secure-dashboard.sh`، `harden-docker-ports.sh`، `generateChaincodes_part5..10.sh`،
`config/`، بقیه `server/` و `public/`. آنها تغییری نکرده‌اند و از خود مخزن
می‌آیند.

## فایل‌هایی که بررسی شدند و تغییر لازم نداشتند

`network.sh`، `deploy-staged.sh`، `deploy_functions.sh`، `channel_contract_map.sh`،
`harden-docker-ports.sh`، `secure-dashboard.sh`، `config.js`، `connection.js`،
`fabric.js`، `index.js` (توسط patch-index اصلاح می‌شود)، `package.json`،
`explorer-routes.js`، `scenario-routes.js`، و همه فایل‌های `public/` جز سه‌تای بالا.

`generateChaincodes_part5..10.sh`: صفر مورد `math.Pow`، صفر `calculateDistance`،
و اصلاح `txTimestamp` سرجایش است.

## دو فایل که وضعیت خاصی دارند

**`simulation.js`** — هر ۲۷ فراخوانی قرارداد مکانی در آن امضای قدیمی دارد و
می‌شکند. ولی هیچ فایلی آن را `require` نمی‌کند؛ `scenario-routes.js` از
`scenario-core.js` استفاده می‌کند. **کد مرده است** — یا حذفش کنید یا رهایش کنید،
اثری ندارد.

**`setup-test-interface.sh`** — پنج workload با نام سناریو می‌ساخت که سرور هرگز
نمی‌جست. زائد است؛ اجرایش فقط پنج فایل بی‌استفاده اضافه می‌کند.

## یک شکاف باقی‌مانده که باید بدانید

صفحه Simulation چیدمان آنتن خودش را با `mulberry32` می‌سازد، ولی قراردادها
چیدمان خودشان را با `PlaceOnGrid` از بذر می‌سازند. **دو مولد متفاوت‌اند، پس
بذر یکسان چیدمان یکسان نمی‌دهد** و نقشه پوشش با آنچه دفتر واقعاً حساب می‌کند
یکی نیست.

`scenario-core.js` اصلاح‌شده حالا می‌تواند چیدمان را از دفتر بپذیرد:

```js
const status = await queryChaincode(1, 'datachannel',
                 'LocationBasedAssignment', 'NetworkStatus', []);
const topology = generateTopology({ seed, antennas: JSON.parse(status) });
// topology.antennaSource === 'ledger'
```

برای وصل کردن این به رابط وب باید `scenario-routes.js` تغییر کند تا پیش از
ساخت توپولوژی `NetworkStatus` را بخواند. تا آن زمان موقعیت آنتن‌ها روی نقشه
تزئینی است؛ موقعیت موجودیت‌ها و خودِ تراکنش‌ها درست‌اند.
