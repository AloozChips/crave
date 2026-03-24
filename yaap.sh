#!/bin/bash

rm -rf .repo/local_manifests

repo init -u https://github.com/yaap/manifest.git -b sixteen --git-lfs

/opt/crave/resync.sh || repo sync -j$(nproc --all) --no-tags --no-clone-bundle --current-branch
#safer sync
/opt/crave/resync.sh || repo sync -j$(nproc --all) --no-tags --no-clone-bundle --current-branch

rm -rf device/xiaomi/fog
rm -rf vendor/xiaomi/fog
rm -rf device/xiaomi/fog-kernel
rm -rf hardware/xiaomi
rm -rf vendor/xiaomi/camera
rm -rf packages/apps/ViPER4AndroidFX
rm -rf packages/apps/DolbyUI
rm -rf hardware/dolby
rm -rf out/target/product/fog

git clone https://github.com/AloozChips/device_xiaomi_fog.git device/xiaomi/fog -b yaapbp4a --depth 1
git clone https://github.com/AloozChips/vendor_xiaomi_fog.git vendor/xiaomi/fog -b baklava-and-beyond --depth 1
git clone https://github.com/AloozChips/device_xiaomi_fog-kernel.git device/xiaomi/fog-kernel -b ksu-and-bpf --depth 1
git clone https://github.com/yaap/hardware_xiaomi.git hardware/xiaomi -b sixteen --depth 1
git clone https://gitlab.com/ThankYouMario/proprietary_vendor_xiaomi_camera.git vendor/xiaomi/camera -b vauxite-sm6225 --depth 1
git clone https://github.com/Evolution-X-Devices/packages_apps_ViPER4AndroidFX.git packages/apps/ViPER4AndroidFX -b bka --depth 1
git clone https://github.com/swiitch-OFF-Lab/packages_apps_DolbyUI.git packages/apps/DolbyUI -b 16.0 --depth 1
git clone https://github.com/swiitch-OFF-Lab/hardware_dolby.git hardware/dolby -b sony-1.5 --depth 1

export TZ=Asia/Dhaka
export BUILD_USERNAME=AloozChips
export BUILD_HOSTNAME=crave
export TARGET_BUILD_GAPPS=true
export TARGET_SUPPORTS_64_BIT_APPS=true
export TARGET_BUILD_VARIANT=user

. build/envsetup.sh
lunch yaap_fog-user
m installclean
m yaap
