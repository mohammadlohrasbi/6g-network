#!/bin/bash
# setup-all.sh — ساخت همه ۸۶ قرارداد (اجرای هر ۱۰ فایل generate)
# این فقط chaincode.go ها را می‌سازد؛ go.mod/vendor توسط network.sh ساخته می‌شود

set -e
cd "$(dirname "${BASH_SOURCE[0]}")"

echo "=== ساخت همه قراردادها ==="
for f in generateChaincodes_part*.sh; do
  echo "اجرای $f ..."
  bash "./$f"
done

echo ""
echo "=== شمارش قراردادهای ساخته‌شده ==="
count=$(find chaincode -mindepth 1 -maxdepth 1 -type d 2>/dev/null | wc -l)
echo "تعداد قرارداد: $count"
echo "✅ همه قراردادها ساخته شدند"
