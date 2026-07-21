# شبکه هایپرلجر فابریک برای شبکه‌های سلولی 6G

پیاده‌سازی یک شبکه بلاک‌چین مجوزدار با **۸ سازمان** (در نقش آنتن‌های ماکروسل)، **۲۰ کانال موضوعی** و **۸۶ قرارداد هوشمند Go**، به‌همراه داشبورد وب، ابزارهای بنچمارک (Tape و Caliper) و **سناریوی شبیه‌سازی جانمایی تصادفی** در پهنه ۱۰×۱۰ کیلومتر. این README دستورالعمل اجرای کامل از صفر تا صد است. شرح مشکلات حل‌شده و علت هر اصلاح در `CHANGES.md` و معماری سامانه تست در `test-system-report.md` آمده است.

## پیش‌نیازها

سرور لینوکس (آزموده‌شده روی Ubuntu 24.04) با دست‌کم ۴ گیگابایت RAM (به‌علاوه swap) و ۴۰ گیگابایت دیسک (۶۰+ توصیه می‌شود). بسته‌های لازم: Docker Engine، **docker-compose-v2** (نسخه v1 با Docker جدید در بازسازی کانتینرها باگ دارد — همیشه از `docker compose` بدون خط تیره استفاده کنید)، Go 1.21+، Node.js 18+، git، jq.

```bash
apt-get update && apt-get install -y docker.io docker-compose-v2 golang nodejs npm git jq
git clone https://github.com/mohammadlohrasbi/6g-network.git /root/6g-network
cd /root/6g-network/scripts && chmod +x *.sh
```

## فاز ۱ — تولید قراردادها و راه‌اندازی شبکه

```bash
cd /root/6g-network/scripts
for f in generateChaincodes_part*.sh; do ./"$f"; done   # ۸۶ قرارداد با timestamp قطعی (GetTxTimestamp)
./network.sh                                             # CA دو سطحی، MSP، ۸ peer، orderer، external builder
```

اسکریپت network.sh همه‌چیز را از صفر می‌سازد: زیرساخت کلید عمومی (root-ca و rca-main)، هویت‌ها، آرتیفکت‌های کانال، و external builder به نام `prebuilt` با هر چهار اسکریپت detect/build/release/run (اسکریپت run باینری از پیش‌ساخته را با فلگ `-peer.address` اجرا می‌کند — این فلگ برای shim فابریک الزامی است).

## فاز ۲ — استقرار کانال‌ها

برای شروع فقط کانال اصلی، و در صورت تمایل بقیه:

```bash
./deploy-staged.sh artifacts
./deploy-staged.sh channel datachannel        # کانال مرجع آزمایش‌ها
./deploy-staged.sh channel connectivitychannel # برای فاز اتصال سناریو
./deploy-staged.sh list                        # وضعیت: n/n یعنی کامل
# استقرار همه ۲۰ کانال (۳۰-۴۵ دقیقه، ترجیحاً داخل tmux):
./deploy-staged.sh all
```

## فاز ۳ — تست دودی لایه بلاک‌چین (الزامی)

```bash
docker exec -e CORE_PEER_LOCALMSPID=org1MSP \
  -e CORE_PEER_MSPCONFIGPATH=/etc/hyperledger/fabric/admin-msp \
  -e CORE_PEER_ADDRESS=peer0.org1.example.com:7051 -e CORE_PEER_TLS_ENABLED=false \
  peer0.org1.example.com peer chaincode invoke -o orderer.example.com:7050 \
  -C datachannel -n LocationBasedSignalStrength \
  --peerAddresses peer0.org1.example.com:7051 --peerAddresses peer0.org2.example.com:8051 \
  --peerAddresses peer0.org3.example.com:9051 --peerAddresses peer0.org4.example.com:10051 \
  --peerAddresses peer0.org5.example.com:11051 \
  -c '{"Args":["RecordSignalStrength","smoke1","-70","10","20"]}' --waitForEvent
```

انتظار: `committed with status (VALID)`. سیاست endorsement کانال‌ها MAJORITY است (۵ امضا از ۸)، پس invoke دستی باید دست‌کم ۵ peer را آدرس بدهد.

## فاز ۴ — ابزارهای تست و سرور داشبورد

```bash
./install-test-tools.sh     # Caliper 0.6.0 + bind + SDK های سراسری، Tape، rego سیاست ۵از۸، کانفیگ‌ها، /etc/hosts، symlink ها
./setup-test-interface.sh   # workload های پنج سناریو با کلیدهای قطعی
bash ../server/patch-index.sh   # چهار اصلاح idempotent روی index.js (از جمله اتصال روتر سناریو)
./add-test-endpoint.sh      # راستی‌آزمایی — همه موارد باید ✓ باشند
```

## فاز ۵ — امنیت و راه‌اندازی داشبورد

```bash
./secure-dashboard.sh       # تعاملی اجرا کنید؛ نام کاربری و رمز را تایپ کنید (paste نکنید)
./harden-docker-ports.sh    # مقید کردن پورت‌های peer/orderer به 127.0.0.1 در فایل‌های compose
cd /root/6g-network/config && docker compose up -d && docker compose -f docker-compose-root-ca.yml up -d
systemctl restart dashboard
```

secure-dashboard.sh گواهی TLS خودامضا، nginx با Basic Auth، فایروال UFW و Fail2Ban را برپا می‌کند. توجه: UFW به‌تنهایی پورت‌های publish شده Docker را نمی‌بندد؛ harden-docker-ports دقیقاً همین شکاف را با نگاشت به loopback می‌بندد و چون ابزارهای هاست (tape/caliper/سرور) از طریق /etc/hosts به 127.0.0.1 متصل‌اند، چیزی نمی‌شکند.

## فاز ۶ — اجرای تست‌ها

**از خط فرمان:** `run-tape.sh datachannel` (بار حداکثری خام؛ خط پایانی tps می‌دهد — با حجم کم عدد پایین‌تر است، برای اعداد پایدار 500+ تراکنش) و `run-caliper.sh` (دو دور نوشتن/خواندن با گزارش HTML در `test-tools/caliper-workspace/report.html`).

**از UI (تست کارایی):** مرورگر → `https://IP-سرور` → ورود → صفحه تست. برای datachannel ابزار **Tape** را انتخاب کنید (Caliper از UI برای سناریوهای IoT روی accesschannel/iotchannel است). نرخ و مدت انتخابی فقط بر Tape اثر دارد.

**از UI (سناریوی شبیه‌سازی 6G):** صفحه `scenario.html`. در هر اجرا ۸ سازمان به‌عنوان **فرستنده ماکروسل** به‌صورت تصادفی در مربع ۱۰×۱۰ کیلومتر جانمایی می‌شوند؛ تعداد دلخواه **فرستنده IoT** و **گیرنده (کاربر)** با موقعیت تصادفی تولید و هر یک به نزدیک‌ترین ماکروسل تخصیص می‌یابد (زیرمجموعه همان سازمان) و تراکنش‌هایش از دروازه همان سازمان ثبت می‌شود. اتصال کاربرها و IoT ها با ConnectUser/ConnectIoT روی connectivitychannel برقرار می‌گردد. کانال‌ها و قراردادها به دلخواه (همه/چندتا/یکی) انتخاب می‌شوند؛ قراردادهای خاکستری یا تابع نوشتنی ندارند یا به رکورد آنتنِ از پیش موجود وابسته‌اند. فیلد Seed توپولوژی را تکرارپذیر می‌کند و نقشه «آخرین جانمایی» در سرور ذخیره می‌شود و با باز کردن مجدد صفحه نمایش می‌یابد.

## نگه‌داری

پس از هر reboot سرور: `cd /root/6g-network/config && docker compose up -d && docker compose -f docker-compose-root-ca.yml up -d && systemctl start dashboard`. برای پاک‌سازی فضای دیسک، کش build گو (`go clean -cache`) و `docker image prune -f` امن‌اند؛ هرگز `docker volume prune` نزنید — لجر کانال‌ها در volume ها است. بازسازی کامل شبکه: اجرای دوباره network.sh (همه‌چیز از جمله لجر پاک و از نو ساخته می‌شود، سپس فاز ۲ به بعد).

## عیب‌یابی سریع

«could not launch chaincode ... run: no such file» → اسکریپت run در scripts/builders/golang/bin نیست (network.sh قدیمی)؛ «container exited with 0» → run بدون فلگ `-peer.address` باینری را اجرا کرده؛ «empty endorsement policy» در tape → کانفیگ فاقد policyFile/org است (fix-tape-policy.sh)؛ «Unable to detect required Fabric binding packages» در Caliper → SDK ها سراسری نصب نیستند (installer جدید نصب می‌کند)؛ «KeyError: ContainerConfig» → از docker-compose v1 استفاده شده؛ با `docker compose` (v2) تکرار کنید. جزئیات همه این‌ها در CHANGES.md.
