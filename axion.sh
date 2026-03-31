#!/bin/bash

START_TIME=$(date +%s)

TG_TOKEN="8720742374:AAFhqX9pfzrTKeYu-IO_X08RSHTSjwIuu1c"
TG_CHAT_ID="6087243184"
ROM_DIR="out/target/product/fog"

send_initial_msg() {
    RESPONSE=$(curl -s -X POST "https://api.telegram.org/bot$TG_TOKEN/sendMessage" \
        -d chat_id="$TG_CHAT_ID" \
        -d text="🚀 <b>Build Started: AxionAOSP for fog/wind/rain"</b> \
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

send_initial_msg

repo init -u https://github.com/AxionAOSP/android.git -b lineage-23.2 --git-lfs

/opt/crave/resync.sh || repo sync -c -j$(nproc --all) --force-sync --no-clone-bundle --no-tags
# safer sync
/opt/crave/resync.sh || repo sync -c -j$(nproc --all) --force-sync --no-clone-bundle --no-tags

pushd packages/apps/Updater
git fetch https://github.com/AloozChips/axion_updater.git
(git cherry-pick ef1ac7e9a79d308ab95f8fe03caeaa6f3c2821dd --no-edit && echo "patched custom OTA")  || (git cherry-pick --abort && echo "failed to patch custom OTA!")
popd

pushd bionic
(git revert 9857de532657f1f0d5147bbbbb713e281e514670 --no-edit && echo "reverted [jemalloc] dual allocator support (jemalloc default + Scudo fallback)") || (git revert --abort && echo "failed reverting [jemalloc] dual allocator support (jemalloc default + Scudo fallback)!")
popd

rm -rf device/xiaomi/fog \
       vendor/xiaomi/fog \
       device/xiaomi/fog-kernel \
       hardware/xiaomi \
       vendor/xiaomi/camera \
       packages/apps/DolbyUI \
       hardware/dolby \
       out/target/product/fog

git clone https://github.com/AloozChips/device_xiaomi_fog.git device/xiaomi/fog -b axionbp4a --depth 1
git clone https://github.com/AloozChips/vendor_xiaomi_fog.git vendor/xiaomi/fog -b baklava-and-beyond --depth 1
git clone https://github.com/AloozChips/device_xiaomi_fog-kernel.git device/xiaomi/fog-kernel -b ksu-and-bpf --depth 1
git clone https://github.com/LineageOS/android_hardware_xiaomi.git hardware/xiaomi -b lineage-23.2 --depth 1
git clone https://gitlab.com/ThankYouMario/proprietary_vendor_xiaomi_camera.git vendor/xiaomi/camera -b vauxite-sm6225 --depth 1
git clone https://github.com/swiitch-OFF-Lab/packages_apps_DolbyUI.git packages/apps/DolbyUI -b 16.0 --depth 1
git clone https://github.com/swiitch-OFF-Lab/hardware_dolby.git hardware/dolby -b sony-1.5 --depth 1

export TZ=Asia/Dhaka
export BUILD_USERNAME=AloozChips
export BUILD_HOSTNAME=crave
export WITH_GMS=true
export TARGET_CORE_GMS=false
export TARGET_GMS_EXTRAS=true
export PERF_ANIM_OVERRIDE=false
export TARGET_BUILD_VARIANT=user
export TARGET_INCLUDE_AXFX=true
export PRODUCT_NO_CAMERA=false
export TARGET_PREBUILT_GOOGLE_CAMERA=false
export TARGET_SHIP_PIXEL_LAUNCHER=false
export TARGET_SUPPORTS_FACE_UNLOCK=true

. build/envsetup.sh
axion fog user gms

if ! ax -br user -j$(nproc --all); then
    edit_msg "❌ <b>Build Failed: AxionAOSP for fog/wind/rain.</b>
Compilation error encountered."
    exit 1
fi

END_TIME=$(date +%s)
DIFF=$((END_TIME - START_TIME))
TOTAL_BUILD_TIME="$(($DIFF / 3600))h $(($DIFF % 3600 / 60))m $(($DIFF % 60))s"

ZIP=$(find "$ROM_DIR" -maxdepth 1 -type f -iname "*axion*.zip" -printf '%T@ %p\n' | sort -n | tail -1 | cut -f2- -d" ")

if [[ -f "$ZIP" ]]; then
    FILENAME=$(basename "$ZIP")
    BUILD_DATE=$(date "+%Y-%m-%d %H:%M:%S")
    
    MD5_HASH=$(md5sum "$ZIP" | awk '{ print $1 }')
    SHA256_HASH=$(sha256sum "$ZIP" | awk '{ print $1 }')

    edit_msg "✅ <b>Build Completed!</b> 🎉

📦 <b>File:</b> <code>$FILENAME</code>
📱 <b>Device:</b> Redmi 10C (fog/wind/rain)
⏰ <b>Time:</b> $BUILD_DATE
⏱️ <b>Total Build Time:</b> $TOTAL_BUILD_TIME
🔐 <b>MD5:</b> <code>$MD5_HASH</code>
🛡️ <b>SHA-256:</b> <code>$SHA256_HASH</code>"

else
    edit_msg "❌ <b>Build Failed: AxionAOSP for fog/wind/rain.</b>
No zip found in $ROM_DIR."
    exit 1
fi

pushd $ROM_DIR > /dev/null

send_msg "📦 Uploading to Pixeldrain..."

PD_RESPONSE=$(curl -s -T "$FILENAME" -u ":916da83f-7303-42b6-9087-9ea56551ce94" https://pixeldrain.com/api/file/)
PD_ID=$(echo "$PD_RESPONSE" | grep -oP '"id":"\K[^"]+')

if [[ -n "$PD_ID" ]]; then
    DOWNLOAD_LINK="https://pixeldrain.com/u/$PD_ID"
    send_msg "✅ <b>Upload successful!</b>
📥 <b>Download Link:</b> $DOWNLOAD_LINK"
else
    send_msg "❌ Pixeldrain upload failed.
API Response: <code>$PD_RESPONSE</code>"
    popd > /dev/null
fi

popd > /dev/null
