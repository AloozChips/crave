#!/bin/bash

set -o pipefail

# ===== CONFIG =====
TG_TOKEN="8720742374:AAFhqX9pfzrTKeYu-IO_X08RSHTSjwIuu1c"
TG_CHAT_ID="6087243184"
PIXELDRAIN_API="d478bf53-a7dc-4fe9-8572-2933c2b01d0d"
ROM_DIR="out/target/product/fog"

# ===== TELEGRAM =====
send_initial_msg() {
    RESPONSE=$(curl -s -X POST "https://api.telegram.org/bot$TG_TOKEN/sendMessage" \
        -d chat_id="$TG_CHAT_ID" \
        -d text="🚀 <b>Build Started...</b>" \
        -d parse_mode="HTML")

    MSG_ID=$(echo "$RESPONSE" | grep -oP '"message_id":\K[0-9]+')
}

edit_msg() {
    curl -s -X POST "https://api.telegram.org/bot$TG_TOKEN/editMessageText" \
        -d chat_id="$TG_CHAT_ID" \
        -d message_id="$MSG_ID" \
        -d text="$1" \
        -d parse_mode="HTML" > /dev/null
}

send_msg() {
    curl -s -X POST "https://api.telegram.org/bot$TG_TOKEN/sendMessage" \
        -d chat_id="$TG_CHAT_ID" \
        -d text="$1" \
        -d parse_mode="HTML" > /dev/null
}

# ===== PROGRESS BAR =====
progress_bar() {
    PERCENT=$1
    FILLED=$((PERCENT / 5))
    EMPTY=$((20 - FILLED))

    BAR=$(printf "%0.s█" $(seq 1 $FILLED))
    SPACE=$(printf "%0.s░" $(seq 1 $EMPTY))

    echo "[$BAR$SPACE] ${PERCENT}%"
}

# ===== LIVE PROGRESS =====
monitor_progress() {
    LAST=0

    ax -br user -j$(nproc --all) 2>&1 | while read line; do

        if [[ "$line" == *"ninja:"* ]]; then
            PERCENT=$(echo "$line" | grep -oP '\[\K[0-9]+(?=%)')

            if [[ ! -z "$PERCENT" && "$PERCENT" -ge $((LAST+5)) ]]; then
                LAST=$PERCENT

                BAR=$(progress_bar $PERCENT)
                edit_msg "🚀 <b>Building ROM...</b>\n\n📊 $BAR"
            fi
        fi

        echo "$line"
    done
}

# ===== PIXELDRAIN UPLOAD =====
upload_pixeldrain() {
    local FILE_TO_UPLOAD="$1"
    send_msg "📦 Uploading to Pixeldrain..."

    RESPONSE=$(curl -s -T "$FILE_TO_UPLOAD" \
        -u :$PIXELDRAIN_API \
        https://pixeldrain.com/api/file)

    LINK=$(echo "$RESPONSE" | grep -oP '"id":"\K[^"]+')

    if [[ ! -z "$LINK" ]]; then
        URL="https://pixeldrain.com/u/$LINK"
        send_msg "✅ <b>Download Link:</b> $URL"
    else
        send_msg "❌ Pixeldrain upload failed. Check API quota or file size."
    fi
}

# ===== START =====
send_initial_msg

echo ">>> Syncing source..."
if /opt/crave/resync.sh; then
    echo ">>> Resync success"
else
    echo ">>> Fallback repo sync..."
    repo sync -c -j$(nproc --all) --force-sync --no-clone-bundle --no-tags
fi

# ===== CLEAN =====
rm -rf device/xiaomi/fog \
       vendor/xiaomi/fog \
       device/xiaomi/fog-kernel \
       hardware/xiaomi \
       vendor/xiaomi/camera \
       packages/apps/DolbyUI \
       hardware/dolby \
       out/target/product/fog

# ===== CLONE =====
git clone https://github.com/AloozChips/device_xiaomi_fog.git device/xiaomi/fog -b axion --depth 1
git clone https://github.com/AloozChips/vendor_xiaomi_fog.git vendor/xiaomi/fog -b 25qx-staging --depth 1
git clone https://github.com/AloozChips/device_xiaomi_fog-kernel.git device/xiaomi/fog-kernel -b ksu-and-bpf --depth 1
git clone https://github.com/LineageOS/android_hardware_xiaomi.git hardware/xiaomi -b lineage-23.1 --depth 1
git clone https://gitlab.com/ThankYouMario/proprietary_vendor_xiaomi_camera.git vendor/xiaomi/camera -b vauxite-sm6225 --depth 1
git clone https://github.com/swiitch-OFF-Lab/packages_apps_DolbyUI.git packages/apps/DolbyUI -b 16.0 --depth 1
git clone https://github.com/swiitch-OFF-Lab/hardware_dolby.git hardware/dolby -b sony-1.5 --depth 1

# ===== BUILD FLAGS =====
export TZ=Asia/Dhaka
export BUILD_USERNAME=AloozChips
export BUILD_HOSTNAME=crave
export WITH_GMS=true
export TARGET_CORE_GMS=false
export TARGET_GMS_EXTRAS=true
export TARGET_BUILD_VARIANT=user
export TARGET_SHIP_PIXEL_LAUNCHER=false
export TARGET_PREBUILT_GOOGLE_CAMERA=false
export PRODUCT_NO_CAMERA=false

# ===== ENV SETUP =====
. build/envsetup.sh

# ===== LUNCH =====
axion fog user gms

# ===== BUILD & MONITOR PROGRESS =====
monitor_progress

# ===== POST BUILD =====
ZIP=$(find "$ROM_DIR" -maxdepth 1 -type f -iname "*axion*.zip" -printf '%T@ %p\n' | sort -n | tail -1 | cut -f2- -d" ")

if [[ -f "$ZIP" ]]; then
    FILENAME=$(basename "$ZIP")
    BUILD_TIME=$(date "+%Y-%m-%d %H:%M:%S")
    
    # Calculate MD5 and SHA256 hashes for integrity checking
    MD5_HASH=$(md5sum "$ZIP" | awk '{ print $1 }')
    SHA256_HASH=$(sha256sum "$ZIP" | awk '{ print $1 }')

    edit_msg "✅ <b>Build Completed!</b> 🎉

📦 <b>File:</b> <code>$FILENAME</code>
📱 <b>Device:</b> fog
⏰ <b>Time:</b> $BUILD_TIME
🔐 <b>MD5:</b> <code>$MD5_HASH</code>
🛡️ <b>SHA-256:</b> <code>$SHA256_HASH</code>"

    # Upload to Pixeldrain
    upload_pixeldrain "$ZIP"
else
    edit_msg "❌ <b>Build Failed</b>\n\nNo zip found in $ROM_DIR."
    exit 1
fi
