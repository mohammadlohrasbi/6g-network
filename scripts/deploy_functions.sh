# =====================================================================
# توابع deploy دسته‌ای کانال‌به‌کانال برای ۸۶ قرارداد روی ۲۰ کانال
# با ۸ سازمان و پاک‌سازی خودکار dev-container برای صرفه‌جویی حافظه
# این بخش جایگزین create_and_join_channels و package_and_install_chaincode می‌شود
# =====================================================================

# نگاشت کانال↔قرارداد را از فایل جداگانه source می‌کنیم
# source "$SCRIPTS_DIR/channel_contract_map.sh"

# --------- ساخت artifact برای همه ۲۰ کانال ---------
generate_all_channel_artifacts() {
  log "ساخت artifact برای ${#CHANNELS[@]} کانال..."
  local CHANNEL_ARTIFACTS="$CONFIG_DIR/channel-artifacts"
  mkdir -p "$CHANNEL_ARTIFACTS"

  for ch in "${CHANNELS[@]}"; do
    log "ساخت ${ch}.tx ..."
    configtxgen -profile ApplicationChannel \
      -outputCreateChannelTx "$CHANNEL_ARTIFACTS/${ch}.tx" \
      -channelID "$ch" 2>&1 | grep -iE "error|panic" && error "خطا در ${ch}.tx" || true

    for i in {1..8}; do
      configtxgen -profile ApplicationChannel \
        -outputAnchorPeersUpdate "$CHANNEL_ARTIFACTS/${ch}_org${i}MSP_anchors.tx" \
        -channelID "$ch" \
        -asOrg "org${i}MSP" 2>&1 | grep -iE "error|panic" && true || true
    done
  done
  success "همه artifact‌های کانال ساخته شدند"
}

# --------- ساخت و join یک کانال خاص ---------
create_and_join_one_channel() {
  local ch="$1"
  local CHANNEL_ARTIFACTS="$CONFIG_DIR/channel-artifacts"

  log "=== ساخت کانال $ch ==="
  # اگر بلاک کانال از قبل ساخته شده، دوباره create نکن
  if [ -f "$CHANNEL_ARTIFACTS/${ch}.block" ]; then
    log "  کانال $ch از قبل ساخته شده — فقط join انجام می‌شود"
  else
    docker cp "$CHANNEL_ARTIFACTS/${ch}.tx" peer0.org1.example.com:/tmp/${ch}.tx
    docker exec \
      -e CORE_PEER_LOCALMSPID=org1MSP \
      -e CORE_PEER_MSPCONFIGPATH=/etc/hyperledger/fabric/admin-msp \
      -e CORE_PEER_ADDRESS=peer0.org1.example.com:7051 \
      -e CORE_PEER_TLS_ENABLED=false \
      peer0.org1.example.com \
      peer channel create \
        -o orderer.example.com:7050 \
        -c ${ch} -f /tmp/${ch}.tx \
        --outputBlock /tmp/${ch}.block --timeout 30s 2>&1 \
      || { log "هشدار: ساخت $ch ناموفق (شاید از قبل هست)"; }
    docker cp peer0.org1.example.com:/tmp/${ch}.block "$CHANNEL_ARTIFACTS/" 2>/dev/null || true
  fi

  # join همه ۸ peer
  for i in {1..8}; do
    local PEER="peer0.org${i}.example.com"
    local PORT="${ORG_PORTS[$i]}"
    docker cp "$CHANNEL_ARTIFACTS/${ch}.block" $PEER:/tmp/${ch}.block 2>/dev/null
    docker exec \
      -e CORE_PEER_LOCALMSPID=org${i}MSP \
      -e CORE_PEER_MSPCONFIGPATH=/etc/hyperledger/fabric/admin-msp \
      -e CORE_PEER_ADDRESS=${PEER}:${PORT} \
      -e CORE_PEER_TLS_ENABLED=false \
      $PEER peer channel join -b /tmp/${ch}.block 2>&1 \
      | grep -iE "already exists|Successfully" >/dev/null && true || true
  done
  success "کانال $ch ساخته و همه peer‌ها join شدند"
}

# --------- نصب یک قرارداد روی همه ۸ peer ---------
install_one_chaincode() {
  local name="$1"
  local dir="$CHAINCODE_DIR/$name"
  local tar="/tmp/${name}.tar.gz"

  [ ! -d "$dir" ] && { log "قرارداد $name یافت نشد" >&2; return 1; }

  rm -f "$tar"
  docker run --rm \
    -v "$dir":/chaincode/input:ro -v /tmp:/hosttmp \
    hyperledger/fabric-tools:2.5 \
    peer lifecycle chaincode package /hosttmp/${name}.tar.gz \
      --path /chaincode/input --lang golang --label ${name}_1.0 >/dev/null 2>&1

  [ ! -f "$tar" ] && { log "بسته‌بندی $name ناموفق" >&2; return 1; }

  log "  بسته‌بندی $name انجام شد، شروع نصب روی ۸ peer..." >&2
  local PACKAGE_ID=""
  for i in {1..8}; do
    local PEER="peer0.org${i}.example.com"
    local PORT="${ORG_PORTS[$i]}"
    printf "    نصب روی org%d... " "$i" >&2
    docker cp "$tar" $PEER:/tmp/${name}.tar.gz >/dev/null 2>&1
    local OUT
    OUT=$(docker exec \
      -e CORE_PEER_LOCALMSPID=org${i}MSP \
      -e CORE_PEER_MSPCONFIGPATH=/etc/hyperledger/fabric/admin-msp \
      -e CORE_PEER_ADDRESS=${PEER}:${PORT} \
      -e CORE_PEER_TLS_ENABLED=false \
      $PEER peer lifecycle chaincode install /tmp/${name}.tar.gz 2>&1)
    if echo "$OUT" | grep -qE "Installed remotely|already successfully"; then
      echo "✅" >&2
    else
      echo "⚠️" >&2
    fi
    if [ $i -eq 1 ]; then
      PACKAGE_ID=$(echo "$OUT" | grep -o "${name}_1.0:[0-9a-f]*" | head -n1)
      [ -z "$PACKAGE_ID" ] && PACKAGE_ID=$(docker exec \
        -e CORE_PEER_LOCALMSPID=org1MSP \
        -e CORE_PEER_MSPCONFIGPATH=/etc/hyperledger/fabric/admin-msp \
        -e CORE_PEER_ADDRESS=${PEER}:${PORT} \
        -e CORE_PEER_TLS_ENABLED=false \
        $PEER peer lifecycle chaincode queryinstalled 2>&1 \
        | grep -o "${name}_1.0:[0-9a-f]*" | head -n1)
    fi
  done
  rm -f "$tar"
  echo "$PACKAGE_ID"
}

# --------- approve + commit یک قرارداد روی یک کانال ---------
approve_commit_one() {
  local name="$1" ch="$2" pkgid="$3"

  log "  approve $name روی ۸ سازمان..."
  for i in {1..8}; do
    local PEER="peer0.org${i}.example.com"
    local PORT="${ORG_PORTS[$i]}"
    docker exec \
      -e CORE_PEER_LOCALMSPID=org${i}MSP \
      -e CORE_PEER_MSPCONFIGPATH=/etc/hyperledger/fabric/admin-msp \
      -e CORE_PEER_ADDRESS=${PEER}:${PORT} \
      -e CORE_PEER_TLS_ENABLED=false \
      $PEER peer lifecycle chaincode approveformyorg \
        -o orderer.example.com:7050 \
        --channelID $ch --name $name --version 1.0 \
        --package-id "$pkgid" --sequence 1 >/dev/null 2>&1 \
      && true || log "هشدار: approve $name/org$i/$ch ناموفق"
  done

  local PEER_ARGS=""
  for i in {1..8}; do
    PEER_ARGS="$PEER_ARGS --peerAddresses peer0.org${i}.example.com:${ORG_PORTS[$i]}"
  done
  docker exec \
    -e CORE_PEER_LOCALMSPID=org1MSP \
    -e CORE_PEER_MSPCONFIGPATH=/etc/hyperledger/fabric/admin-msp \
    -e CORE_PEER_ADDRESS=peer0.org1.example.com:7051 \
    -e CORE_PEER_TLS_ENABLED=false \
    peer0.org1.example.com peer lifecycle chaincode commit \
      -o orderer.example.com:7050 \
      --channelID $ch --name $name --version 1.0 --sequence 1 \
      $PEER_ARGS >/dev/null 2>&1 \
    && success "✅ $name روی $ch commit شد" \
    || log "هشدار: commit $name/$ch ناموفق"
}

# --------- پاک‌سازی dev-container‌های یک قرارداد (آزادسازی حافظه) ---------
cleanup_dev_containers() {
  local name="$1"
  local ids
  ids=$(docker ps -aq --filter "name=dev-peer.*-${name}_1.0" 2>/dev/null)
  if [ -n "$ids" ]; then
    docker rm -f $ids >/dev/null 2>&1 || true
    log "🧹 dev-container‌های $name پاک شدند"
  fi
}

# --------- deploy کامل یک کانال (همه قراردادهایش) ---------
deploy_one_channel() {
  local ch="$1"
  local contracts="${CHANNEL_CONTRACTS[$ch]}"

  [ -z "$contracts" ] && { log "کانال $ch قراردادی ندارد"; return 0; }

  log "════════════════════════════════════════"
  log "شروع deploy کانال: $ch"
  log "قراردادها: $contracts"
  log "════════════════════════════════════════"

  create_and_join_one_channel "$ch"

  for cc in $contracts; do
    log "── قرارداد $cc روی $ch ──"
    local pkgid
    pkgid=$(install_one_chaincode "$cc")
    if [ -z "$pkgid" ]; then
      log "هشدار: نصب $cc ناموفق — رد شد"
      continue
    fi
    log "Package ID: $pkgid"
    approve_commit_one "$cc" "$ch" "$pkgid"
  done

  # نمایش مصرف حافظه فعلی
  local mem_free
  mem_free=$(free -m | awk '/^Mem:/{print $7}')
  log "💾 حافظه در دسترس بعد از کانال $ch: ${mem_free}MB"

  success "کانال $ch کامل deploy شد"
}
