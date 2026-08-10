#!/bin/bash
set -euo pipefail

ROM_DIR="out/target/product/fog"
PIXELDRAIN_API_KEY="916da83f-7303-42b6-9087-9ea56551ce94"

export NINJA_ARGS="-j$(nproc --all)"

repo init -u https://github.com/Evolution-X/manifest -b cnb --git-lfs --depth=1

if [ -x "/opt/crave/resync.sh" ]; then
    /opt/crave/resync.sh
else
    repo sync -c -j$(nproc --all) --force-sync --no-clone-bundle --no-tags
fi

rm -rf "$ROM_DIR" \
       device/xiaomi/fog \
       vendor/xiaomi/fog \
       device/xiaomi/fog-kernel \
       hardware/xiaomi \
       vendor/evolution-priv/keys

git clone https://github.com/AloozChips/device_xiaomi_fog.git device/xiaomi/fog -b evoxa17 --depth=1
git clone https://github.com/AloozChips/vendor_xiaomi_fog.git vendor/xiaomi/fog -b baklava-and-beyond --depth=1
git clone https://github.com/AloozChips/device_xiaomi_fog-kernel.git device/xiaomi/fog-kernel -b motregen --depth=1
git clone https://github.com/LineageOS/android_hardware_xiaomi.git hardware/xiaomi -b lineage-23.2 --depth=1

git clone https://github.com/Evolution-X/vendor_evolution-priv_keys-template.git vendor/evolution-priv/keys --depth=1
pushd vendor/evolution-priv/keys > /dev/null
chmod +x keys.sh
./keys.sh
popd > /dev/null

export TZ=Asia/Dhaka
export BUILD_USERNAME=AloozChips
export BUILD_HOSTNAME=crave
export WITH_GMS=true
export TARGET_BUILD_VARIANT=user
export PERF_ANIM_OVERRIDE=false

source build/envsetup.sh
lunch lineage_fog-cp2a-user

m installclean
m evolution

pushd "$ROM_DIR" > /dev/null

TARGET_ZIP=$(ls Evo*.zip 2>/dev/null | tail -n 1)

if [ -n "$TARGET_ZIP" ] && [ -f "$TARGET_ZIP" ]; then
    echo "Uploading $TARGET_ZIP to PixelDrain..."
    curl -s -T "$TARGET_ZIP" -u ":$PIXELDRAIN_API_KEY" https://pixeldrain.com/api/file/
    echo -e "\nUpload complete!"
else
    echo "Error: Output ZIP file not found in $ROM_DIR"
    exit 1
fi

popd > /dev/null
