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
rm -rf out/target/product/fog

git clone https://github.com/AloozChips/device_xiaomi_fog.git device/xiaomi/fog -b yaapbq2 --depth 1
git clone https://github.com/AloozChips/vendor_xiaomi_fog.git vendor/xiaomi/fog -b 25qx-staging --depth 1
git clone https://github.com/AloozChips/device_xiaomi_fog-kernel.git device/xiaomi/fog-kernel -b ksu-and-bpf --depth 1
git clone https://github.com/yaap/hardware_xiaomi.git hardware/xiaomi -b sixteen --depth 1

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
