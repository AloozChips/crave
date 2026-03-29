#!/bin/bash

rm -rf .repo/local_manifests
rm -rf frameworks/av
rm -rf packages/apps/Updater

repo init -u https://github.com/Evolution-X/manifest -b bq2 --git-lfs

/opt/crave/resync.sh || repo sync -c -j$(nproc --all) --force-sync --no-clone-bundle --no-tags
#safer sync
/opt/crave/resync.sh || repo sync -c -j$(nproc --all) --force-sync --no-clone-bundle --no-tags

pushd frameworks/av
git fetch https://github.com/AloozChips/frameworks_av.git && git cherry-pick aa1fd74e803570e1f8b4814ddf04b8b20c2e13c5
popd

pushd packages/apps/Updater
git fetch https://github.com/AloozChips/evo_updater.git && git cherry-pick a633145592f88ac8c36236b20eead2047b9dc540
popd

rm -rf device/xiaomi/fog
rm -rf vendor/xiaomi/fog
rm -rf device/xiaomi/fog-kernel
rm -rf hardware/xiaomi
rm -rf vendor/xiaomi/camera
rm -rf packages/apps/ViPER4AndroidFX
rm -rf packages/apps/DolbyUI
rm -rf hardware/dolby
rm -rf out/target/product/fog

git clone https://github.com/AloozChips/device_xiaomi_fog.git device/xiaomi/fog -b evox --depth 1
git clone https://github.com/AloozChips/vendor_xiaomi_fog.git vendor/xiaomi/fog -b baklava-and-beyond --depth 1
git clone https://github.com/AloozChips/device_xiaomi_fog-kernel.git device/xiaomi/fog-kernel -b ksu-and-bpf --depth 1
git clone https://github.com/LineageOS/android_hardware_xiaomi.git hardware/xiaomi -b lineage-23.2 --depth 1
git clone https://gitlab.com/ThankYouMario/proprietary_vendor_xiaomi_camera.git vendor/xiaomi/camera -b vauxite-sm6225 --depth 1
git clone https://github.com/Evolution-X-Devices/packages_apps_ViPER4AndroidFX.git packages/apps/ViPER4AndroidFX -b bka --depth 1
git clone https://github.com/swiitch-OFF-Lab/packages_apps_DolbyUI.git packages/apps/DolbyUI -b 16.0 --depth 1
git clone https://github.com/swiitch-OFF-Lab/hardware_dolby.git hardware/dolby -b sony-1.5 --depth 1

export TZ=Asia/Dhaka
export BUILD_USERNAME=AloozChips
export BUILD_HOSTNAME=crave
export WITH_GMS=true
export TARGET_BUILD_VARIANT=user
export PERF_ANIM_OVERRIDE=false

. build/envsetup.sh
lunch lineage_fog-bp4a-user
m installclean
m evolution -j$(nproc --all)

pushd out/target/product/fog || { echo ">>> Directory not found!"; exit 1; }

shopt -s nocaseglob

files=( *evolution*.zip )

if [ ! -e "${files[0]}" ]; then
    echo ">>> Error: No file found!"
    shopt -u nocaseglob
    popd
    exit 1
fi

if [ ${#files[@]} -gt 1 ]; then
    echo ">>> Warning: Multiple files found. Uploading the first one: ${files[0]}"
fi

if curl -T "${files[0]}" -u ":916da83f-7303-42b6-9087-9ea56551ce94" https://pixeldrain.com/api/file/; then
    echo -e "\n>>> pixeldrain upload done!"
else
    echo -e "\n>>> pixeldrain upload failed!"
    shopt -u nocaseglob
    popd
    exit 1
fi

shopt -u nocaseglob
popd
