# دستورالعمل اجرا — صفر تا صد

شبکه هایپرلجر فابریک برای شبکه سلولی 6G: ۸ سازمان در نقش آنتن ماکروسل،
۲۰ کانال، ۸۶ قرارداد Go، داشبورد وب، و بنچمارک با Tape و Caliper.

**دو مسیر وجود دارد. اول تعیین کنید کدام‌یک:**

| وضعیت شما | مسیر |
|---|---|
| شبکه‌ای ندارید یا می‌خواهید از نو بسازید | **مسیر A — نصب تازه** |
| شبکه بالاست و کانال‌ها مستقرند | **مسیر B — ارتقا** |

تفاوت مهم است: در نصب تازه، قراردادهای مکانی از همان ابتدا با نسخه جدید
مستقر می‌شوند و اسکریپت `upgrade-spatial.sh` اصلاً لازم نیست. در ارتقا،
باید نسخه chaincode را بالا ببرید.

---

# فایل‌های تحویلی

پیش از شروع، این فایل‌ها را در جای درست بگذارید.

## در `scripts/`

| فایل | چه می‌کند |
|---|---|
| `generateChaincodes_part1.sh` … `part4.sh` | جایگزین نسخه قدیمی — به اسکریپت مکانی واگذار می‌کنند |
| `generateChaincodes_spatial.sh` | ۳۴ قرارداد مکانی با مدل رادیویی واقعی |
| `gen-spatial-contracts.js` | مولد اسکریپت بالا (فقط اگر خواستید بازتولید کنید) |
| `check-go.js` | بررسی ساختاری کد Go بدون کامپایلر |
| `upgrade-spatial.sh` | ارتقای ۳۷ جفت کانال-قرارداد (فقط مسیر B) |
| `seed-network.sh` | چیدمان آنتن در هر ۳۷ جفت — **بدون این هیچ تراکنشی commit نمی‌شود** |
| `update-fn-map.js` | همگام‌سازی نگاشت توابع با امضاهای جدید |
| `gen-caliper-assets.js` | ۲ workload عمومی + ۶۱ نام‌دار |
| `gen-caliper-network.js` | کانفیگ شبکه Caliper با هر ۹۰ قرارداد |
| `install-test-tools.sh` | نصب Caliper و Tape |

## در `server/`

`bench-catalog.js`، `bench-runner.js`، `bench-routes.js`، `contract-fn-map.js`،
`patch-index.sh`

## در `public/`

`test.html`، `test-app.js`، `styles.css`

## در `chaincode/` — هیچ‌چیز

`radio.go` فقط برای مطالعه است؛ محتوایش داخل هر ۳۴ قرارداد تزریق شده.

---

# مسیر A — نصب تازه

## پیش‌نیازها

سرور لینوکس (آزموده روی Ubuntu 24.04)، دست‌کم ۴ گیگابایت RAM به‌علاوه swap،
۴۰ گیگابایت دیسک (۶۰+ توصیه می‌شود).

```bash
apt-get update && apt-get install -y \
    docker.io docker-compose-v2 golang nodejs npm git jq

git clone https://github.com/mohammadlohrasbi/6g-network.git /root/6g-network
cd /root/6g-network/scripts && chmod +x *.sh
```

**همیشه `docker compose` بدون خط تیره.** نسخه v1 با Docker جدید در بازسازی
کانتینر باگ `KeyError: ContainerConfig` می‌دهد.

## A1 — استقرار فایل‌های تحویلی

```bash
cd /root/6g-network

cp /path/to/generateChaincodes_part{1,2,3,4}.sh scripts/
cp /path/to/generateChaincodes_spatial.sh       scripts/
cp /path/to/{gen-spatial-contracts.js,check-go.js,seed-network.sh} scripts/
cp /path/to/{update-fn-map.js,gen-caliper-assets.js,gen-caliper-network.js} scripts/
cp /path/to/install-test-tools.sh scripts/
cp /path/to/{bench-catalog.js,bench-runner.js,bench-routes.js} server/
cp /path/to/{contract-fn-map.js,patch-index.sh} server/
cp /path/to/{test.html,test-app.js,styles.css} public/

chmod +x scripts/*.sh server/patch-index.sh
cd server && npm install js-yaml && cd ..
```

## A2 — تولید ۸۶ قرارداد

```bash
cd /root/6g-network
for f in scripts/generateChaincodes_part*.sh; do bash "$f"; done
```

part1 تا part4 به `generateChaincodes_spatial.sh` واگذار می‌کنند و ۳۴ قرارداد
مکانی را با مدل رادیویی می‌سازند. part5 تا part10 همان ۵۲ قرارداد ثبت‌محور را
بدون تغییر می‌سازند.

**بررسی:**

```bash
ls chaincode | wc -l                                   # باید 86 باشد
grep -l SeedNetwork chaincode/*/chaincode.go | wc -l   # باید 34 باشد
```

اگر عدد دوم صفر شد، اسکریپت مکانی کنار part1-4 نیست.

## A3 — راه‌اندازی شبکه

```bash
cd /root/6g-network/scripts
./network.sh
```

CA دو سطحی، MSPها، هویت‌ها، آرتیفکت کانال، ۸ peer، orderer و external builder
به نام `prebuilt` را می‌سازد.

**بررسی:**

```bash
docker ps --format '{{.Names}}' | sort   # 8 peer + orderer + 2 CA
```

## A4 — استقرار کانال‌ها

```bash
./deploy-staged.sh artifacts
./deploy-staged.sh channel datachannel          # کانال مرجع
./deploy-staged.sh list                         # وضعیت n/n یعنی کامل
```

برای شروع فقط `datachannel` کافی است. استقرار هر ۲۰ کانال ۳۰ تا ۴۵ دقیقه طول
می‌کشد — داخل `tmux` اجرا کنید:

```bash
tmux new -s deploy
./deploy-staged.sh all
```

## A5 — تست دودی

```bash
docker exec -e CORE_PEER_LOCALMSPID=org1MSP \
  -e CORE_PEER_MSPCONFIGPATH=/etc/hyperledger/fabric/admin-msp \
  -e CORE_PEER_ADDRESS=peer0.org1.example.com:7051 \
  -e CORE_PEER_TLS_ENABLED=false \
  peer0.org1.example.com peer chaincode invoke \
  -o orderer.example.com:7050 -C datachannel -n LocationBasedSignalStrength \
  --peerAddresses peer0.org1.example.com:7051 \
  -c '{"Args":["RecordSignalStrength","smoke1","-70","3000","4000","42"]}' \
  --waitForEvent
```

انتظار: `committed with status (VALID)`.

سه نکته درباره آرگومان‌ها:

- **مختصات حالا متر است**، نه ۱ تا ۱۰۰. شبکه ۱۰ کیلومتری است.
- **`"42"` بذر است** — پارامتر جدید همه قراردادهای مکانی.
- **یک `--peerAddresses` کافی است.** سیاست `OR(...)` است، یک امضا commit می‌کند.

اگر خطای `no antenna layout yet — call SeedNetwork first` گرفتید، همین انتظار
می‌رود: گام بعد را انجام دهید.

## A6 — بذرکاری چیدمان آنتن

**این گام اختیاری نیست.** بدون آن هر تراکنش روی قراردادهای مکانی رد می‌شود.

```bash
cd /root/6g-network/scripts
./seed-network.sh
```

۳۷ فراخوانی `SeedNetwork` انجام می‌دهد — یکی به ازای هر جفت کانال-قرارداد.
چرا ۳۷ و نه ۳۴؟ سه قرارداد روی دو کانال‌اند و در فابریک **هر chaincode فضای
حالت مستقل دارد**، پس رجیستری آنتن مشترک ممکن نیست.

**تنظیمات:**

```bash
SEED=7 ./seed-network.sh                   # چیدمان دیگر
ANTENNAS=16 GRID=20000 ./seed-network.sh   # شبکه بزرگ‌تر
./seed-network.sh datachannel              # فقط یک کانال
VERIFY_ONLY=1 ./seed-network.sh            # گزارش وضعیت، بدون نوشتن
```

اگر کانال‌ها را ناقص مستقر کرده‌اید، فقط همان‌ها را بذرکاری کنید — بقیه با
خطای «مستقر نیست» رد می‌شوند که طبیعی است.

**بررسی:**

```bash
docker exec -e CORE_PEER_LOCALMSPID=org1MSP \
  -e CORE_PEER_MSPCONFIGPATH=/etc/hyperledger/fabric/admin-msp \
  -e CORE_PEER_ADDRESS=peer0.org1.example.com:7051 \
  peer0.org1.example.com peer chaincode query -C datachannel \
  -n LocationBasedAssignment \
  -c '{"function":"ServingCell","Args":["dev-1","3000","4000"]}'
```

باید سلول سرویس‌دهنده، فاصله، RSSI، SINR و ظرفیت شانون برگردد. حالا تست دودی
گام A5 را دوباره بزنید — این‌بار باید VALID بگیرد.

## A7 — همگام‌سازی نگاشت و سرور

```bash
cd /root/6g-network
node scripts/update-fn-map.js
bash server/patch-index.sh
systemctl restart dashboard
```

`patch-index.sh` شش اصلاح idempotent روی `index.js` می‌زند، از جمله اتصال
`/api/bench`. اجرای چندباره بی‌ضرر است — بار دوم «۰ تغییر» می‌گوید.

**بررسی:**

```bash
curl -s localhost:3000/api/bench/catalog | head -c 200
```

باید JSON با ۲۰ کانال برگردد.

## A8 — ابزارهای تست

```bash
cd /root/6g-network/scripts
./install-test-tools.sh        # Caliper 0.6.0، Tape، کانفیگ‌ها، /etc/hosts
node ./gen-caliper-assets.js   # اگر لازم شد جداگانه
node ./gen-caliper-network.js  # کانفیگ شبکه با هر ۹۰ قرارداد
./fix-tape-policy.sh           # سیاست Tape را با سیاست مستقر هم‌تراز می‌کند
./add-test-endpoint.sh         # راستی‌آزمایی — همه باید ✓ باشند
```

`setup-test-interface.sh` را اجرا نکنید؛ زائد است.

## A9 — امنیت و داشبورد

```bash
./secure-dashboard.sh       # تعاملی — رمز را تایپ کنید، paste نکنید
./harden-docker-ports.sh    # مقید کردن پورت‌ها به 127.0.0.1
cd /root/6g-network/config
docker compose up -d
docker compose -f docker-compose-root-ca.yml up -d
systemctl restart dashboard
```

UFW به‌تنهایی پورت‌های publish شده Docker را نمی‌بندد؛ `harden-docker-ports`
همین شکاف را می‌بندد. ابزارهای هاست از طریق `/etc/hosts` به `127.0.0.1` وصل
می‌شوند، پس چیزی نمی‌شکند.

**حالا به فاز تست بروید (بخش «اجرای تست‌ها»).**

---

# مسیر B — ارتقای شبکه موجود

شبکه بالاست، کانال‌ها مستقرند، ولی قراردادهای مکانی نسخه قدیمی‌اند.

## B1 — استقرار فایل‌ها

همان گام A1، به‌علاوه:

```bash
cp /path/to/upgrade-spatial.sh scripts/
chmod +x scripts/upgrade-spatial.sh
```

## B2 — بازتولید قراردادهای مکانی

```bash
cd /root/6g-network
bash scripts/generateChaincodes_spatial.sh
grep -l SeedNetwork chaincode/*/chaincode.go | wc -l   # باید 34 باشد
```

## B3 — ارتقا

```bash
cd /root/6g-network/scripts
DRY_RUN=1 ./upgrade-spatial.sh     # اول نقشه را ببینید
./upgrade-spatial.sh
```

اسکریپت شماره sequence را **از خود شبکه** می‌خواند، نه حدس می‌زند. پس اگر
نیمه‌کاره ماند یا قبلاً ارتقا داده‌اید، از همان جا ادامه می‌دهد و اجرای مجدد
بی‌ضرر است.

برای یک کانال:

```bash
./upgrade-spatial.sh datachannel
```

**اگر نیمه‌کاره شکست:** اسکریپت فهرست ناموفق‌ها را چاپ می‌کند و دستور تلاش
دوباره را می‌دهد. روی سرور ۳.۷ گیگابایتی، ۳۴ ارتقای پشت‌سرهم ممکن است به
کمبود حافظه بخورد — اسکریپت dev-containerهای نسخه قدیم را پاک می‌کند ولی
اگر باز هم شکست، کانال‌به‌کانال پیش بروید.

## B4 — بذرکاری، نگاشت، ابزار

گام‌های A6 تا A8 را انجام دهید. `install-test-tools.sh` را اگر قبلاً اجرا
کرده‌اید لازم نیست تکرار کنید، ولی این دو را بزنید:

```bash
node scripts/gen-caliper-network.js
node scripts/update-fn-map.js
systemctl restart dashboard
```

---

# اجرای تست‌ها

## سیاست تأیید — پیش از هر عددی

قراردادها با `OR('org1MSP.member', … ,'org8MSP.member')` مستقر شده‌اند: **یک
امضا** تراکنش را commit می‌کند. اگر Tape با آستانه بالاتری بسنجد، امضاهایی جمع
می‌کند که شبکه نخواسته، اعدادش مصنوعاً بد می‌شود، و مقایسه‌اش با Caliper بی‌معنا
می‌ماند.

| فایل | آستانه | کاربرد |
|---|---|---|
| `endorsement-any.rego` | ۱ از ۸ | **پیش‌فرض** — مطابق استقرار |
| `endorsement-majority.rego` | ۵ از ۸ | فرضی؛ فقط برای سنجش هزینه سیاست سخت‌گیرانه‌تر |

```bash
./fix-tape-policy.sh            # سیاست مطابق استقرار
./fix-tape-policy.sh majority   # حالت فرضی
```

از رابط وب هم در تب Tape انتخاب‌شدنی است. **هر عددی که با `majority` گرفته
می‌شود باید در گزارش «سیاست فرضی» برچسب بخورد.**

## از رابط وب

مرورگر → `https://IP-سرور` → ورود → **Benchmark**.

سه بخش:

1. **دامنه** — پنج حالت: یک قرارداد، یک کانال، چند کانال، دستچین، کل شبکه.
   زیر انتخابگر تعداد هدف و زمان تخمینی نشان داده می‌شود.
2. **ابزار** — دو تب مجزا. Tape (تعداد endorser، سیاست، burst، connections،
   سقف نرخ) و Caliper (workers، نرخ ارسال ثابت، دور خواندن).
3. **اجرا** — ماتریس پوشش حین اجرا پر می‌شود، سپس جدول، نمودار و CSV.

اجرا در پس‌زمینه سرور است، پس بستن مرورگر قطعش نمی‌کند و sweep کل شبکه timeout
نمی‌خورد. دکمه توقف بعد از هدف جاری متوقف می‌شود و ردیف‌های جمع‌شده می‌مانند.

**۹۰ هدف، ۸۹ تای پیش‌فرض قابل‌اجرا.** تنها استثنا `GetPolicy` است که هیچ تابع
نوشتنی ندارد.

## از خط فرمان

```bash
/root/6g-network/test-tools/run-tape.sh datachannel
/root/6g-network/test-tools/run-caliper.sh
```

برای اعداد پایدار با Tape دست‌کم ۵۰۰ تراکنش بفرستید؛ زیر آن عدد را زمان
راه‌اندازی تعیین می‌کند.

## خروجی برای تحلیل

هر اجرا زیر `test-tools/bench-runs/<شناسه>/`:

- `results.csv` — یک ردیف به ازای هر هدف، شامل نرخ هدف، تعداد endorser،
  سیاست، مدت، تعداد بلاک، میانگین اندازه بلاک و شماره پاس
- `job.json` — کل جزئیات

برای سنجش واریانس فیلد Repeats را بالا ببرید؛ هر پاس با پیشوند کلید متفاوت
می‌نویسد، پس روی کلیدهای پاس قبل نمی‌افتد.

---

# آنچه باید درباره اعداد بدانید

## Tape تأخیر گزارش نمی‌کند

خروجی واقعی Tape فقط گذردهی و تعداد بلاک دارد. جدول نتایج برای تأخیر `n/r`
نشان می‌دهد، نه صفر. **Tape سقف گذردهی می‌دهد، Caliper تأخیر.** برای همین هر
دو ابزار لازم‌اند و این تقسیم کار خودش قابل گزارش است.

## Tape همیشه یک کلید می‌نویسد

Tape آرگومان‌ها را ثابت نگه می‌دارد. برای نوشتن کور بی‌ضرر است، ولی برای
قراردادی که پیش از نوشتن می‌خواند تعارض MVCC می‌سازد. Caliper به هر worker
برش جدا از فضای کلید می‌دهد و این مشکل را ندارد.

## تأخیر ۱۴۲۵ms گلوگاه شبکه نیست

`BatchTimeout=2s` و `MaxMessageCount=500` است. در نرخ ۲۰ tps فقط ۴۰ تراکنش در
هر بازه تایم‌اوت می‌رسد — خیلی کمتر از سقف ۵۰۰ — پس بلاک **همیشه با تایم‌اوت
بسته می‌شود**، نه با پر شدن. انتظار میانگین ۱ ثانیه به‌علاوه تأیید و اعتبارسنجی
حدود ۰.۴ ثانیه، جمعاً حدود ۱۴۰۰ میلی‌ثانیه.

آزمایش پیشنهادی: نرخ ارسال Caliper را ۲۰ → ۵۰ → ۱۰۰ → ۲۰۰ ببرید و نقطه گذار از
«تایم‌اوت‌محور» به «ظرفیت‌محور» را نشان دهید.

## ردیابی ظرفیت پیش‌فرض خاموش است — عمداً

شمردن پذیرش‌ها یعنی نوشتن روی رکورد آنتن، و فقط ۸ آنتن هست. فابریک مجموعه
خواندن-نوشتن را **پس از** ترتیب‌دهی اعتبارسنجی می‌کند، پس چند تراکنش در یک
بلاک که همان کلید را بخوانند، یکی commit می‌شود و بقیه `MVCC_READ_CONFLICT`
می‌گیرند. در ۲۰ tps نرخ موفقیت حدود ۲۰٪، در ۱۰۹ tps زیر ۴٪.

با `maxCapacity=0` (پیش‌فرض) هیچ نوشتنی روی آنتن انجام نمی‌شود و مشکل حذف است.

**برای مطالعه کنترل پذیرش عمداً روشنش کنید:**

```bash
CAPACITY=200 ./seed-network.sh
```

آن‌وقت تعارض خودش یافته است، نه اشکال.

## `LocationBasedAntennaConfig` ذاتاً کلید داغ دارد

این قرارداد آنتن را جابه‌جا می‌کند، پس نوشتن روی رجیستری اجتناب‌ناپذیر است.
با نرخ پایین بنچمارک کنید یا نرخ رد را به‌عنوان نتیجه بخوانید.

## بنچمارک‌های قبلی با بعدی‌ها قابل مقایسه نیستند

تا پیش از این تغییر همه تراکنش‌ها موفق بودند چون هیچ قراردادی شرطی نداشت.
حالا نرخ پذیرش خودش یک متریک است.

---

# ترتیب پیشنهادی برای اولین اعداد

```
۱. datachannel، یک قرارداد (LocationBasedSignalStrength)، Tape، ۱۰۰۰ تراکنش
۲. همان، Caliper، ۵۰۰ تراکنش با نرخ ۲۰
۳. کل datachannel (۴ قرارداد)
۴. auditchannel (۷ قرارداد، تمیزترین پایه — همه نوشتن کور، صفر وابستگی)
۵. کل شبکه، ۸۹ هدف
```

اگر گام ۱ خطا داد، مشکل در استقرار است نه در بنچمارک.

---

# نگه‌داری

**پس از هر reboot:**

```bash
cd /root/6g-network/config
docker compose up -d
docker compose -f docker-compose-root-ca.yml up -d
systemctl start dashboard
```

**پس از هر `git pull`:**

```bash
bash server/patch-index.sh
```

مخزن عمداً نسخه patch نشده `index.js` را نگه می‌دارد.

**پاک‌سازی دیسک:** `go clean -cache` و `docker image prune -f` امن‌اند.
**هرگز `docker volume prune` نزنید** — لجر کانال‌ها در volumeهاست.

---

# عیب‌یابی

## استقرار

| نشانه | علت | اصلاح |
|---|---|---|
| `could not launch chaincode ... run: no such file` | اسکریپت run در builders نیست | `network.sh` نسخه جدید |
| `container exited with 0` | run بدون `-peer.address` اجرا شده | همان |
| `KeyError: ContainerConfig` | docker-compose v1 | `docker compose` (v2) |

## قراردادهای مکانی

| نشانه | علت | اصلاح |
|---|---|---|
| `no antenna layout yet — call SeedNetwork first` | بذرکاری نشده | `./seed-network.sh` |
| `out of coverage: SINR ... below threshold` | رفتار درست — نقطه خارج پوشش است | مختصات دیگر، یا `SetPropagation` |
| `cell ... is saturated` | ظرفیت پر شده | `CAPACITY=0 ./seed-network.sh` |
| `seed ... does not match the layout in place` | بذر آرگومان با بذر مستقر فرق دارد | بذر یکسان، یا بذرکاری مجدد |
| `coordinate ... must be a whole number of metres` | مختصات اعشاری یا غیرعددی | عدد صحیح بفرستید |
| نرخ رد بالا با MVCC | ردیابی ظرفیت روشن است | `CAPACITY=0 ./seed-network.sh` |

## بنچمارک

| نشانه | علت | اصلاح |
|---|---|---|
| صفحه Benchmark: «کاتالوگ خوانده نشد» | روتر متصل نیست | `bash server/patch-index.sh` |
| `/api/bench` خطای ۵۰۰ | js-yaml نصب نیست | `cd server && npm install js-yaml` |
| `Caliper workload not found` | دارایی‌ها ساخته نشده | `node scripts/gen-caliper-assets.js` |
| `No connection profile file found` | مسیر نسبی در کانفیگ | `node scripts/gen-caliper-network.js` |
| `... has already been defined in the configuration` | contractID تکراری | همان دستور بالا |
| `Cannot find module '@hyperledger/caliper-core'` | workload قدیمی | `node scripts/gen-caliper-assets.js --force` |
| Tape تراکنش‌ها را نامعتبر می‌شمارد ولی CLI موفق است | سیاست rego سخت‌گیرتر | `./fix-tape-policy.sh` |
| `empty endorsement policy` در Tape | کانفیگ بدون policyFile | همان |

## اگر چیزی جا افتاده

```bash
./scripts/add-test-endpoint.sh
```

ماژول‌های bench، اتصال روتر، هم‌خوانی کاتالوگ، دارایی‌های Caliper و سیاست Tape
را بررسی می‌کند. خروجی این اسکریپت بهترین نقطه شروع برای گزارش مشکل است.

---

# اسناد مرجع

| سند | محتوا |
|---|---|
| `contract-inventory.md` | فهرست ۸۶ قرارداد با تابع، پارامتر و وضعیت |
| `architecture-guide.md` | معماری کامل، خانواده‌های داده، دلالت‌های ارزیابی |
| `network-roles.md` | نقش هر قرارداد و کانال در شبکه و سازوکارش |
| `spatial-signatures.md` | امضاهای جدید ۳۴ قرارداد مکانی |
| `radio.go` | هسته رادیویی با توضیح هر تصمیم طراحی |

---

# یک هشدار صادقانه

`generateChaincodes_spatial.sh` روی محیطی ساخته شد که کامپایلر Go نداشت. یک
بررسی ساختاری نوشته شد (تعادل پرانتز، تعریف همه کمکی‌ها، تطابق import با
کاربرد، فیلدهای ساختار، صفر `math.`/`rand`/`float`) و هر ۳۴ قرارداد از آن
عبور کردند — ولی **اولین `go build` روی سرور ممکن است چیزی بگیرد که این
بررسی نمی‌گیرد**.

اگر گام A2 یا B2 خطای کامپایل داد، متن کامل خطا را بفرستید. این محتمل‌ترین
نقطه شکست در کل این دستورالعمل است.
