#!/bin/bash

rm -rf .repo/local_manifests
rm -rf packages/apps/Updater

repo init -u https://github.com/LumineDroid/platform_manifest -b bellflower --git-lfs

/opt/crave/resync.sh || repo sync -c -j$(nproc --all) --force-sync --no-clone-bundle --no-tags
#safer sync
/opt/crave/resync.sh || repo sync -c -j$(nproc --all) --force-sync --no-clone-bundle --no-tags

rm -rf device/xiaomi/fog
rm -rf vendor/xiaomi/fog
rm -rf device/xiaomi/fog-kernel
rm -rf hardware/xiaomi
rm -rf packages/apps/Updater
rm -rf vendor/lumine
rm -rf out/target/product/fog

git clone https://github.com/AloozChips/device_xiaomi_fog.git device/xiaomi/fog -b lumine --depth 1
git clone https://github.com/AloozChips/vendor_xiaomi_fog.git vendor/xiaomi/fog -b 25qx-staging --depth 1
git clone https://github.com/AloozChips/device_xiaomi_fog-kernel.git device/xiaomi/fog-kernel -b ksu-and-bpf --depth 1
git clone https://github.com/LineageOS/android_hardware_xiaomi.git hardware/xiaomi -b lineage-23.2 --depth 1
git clone https://github.com/AloozChips/lumine_updater.git packages/apps/Updater -b fog --depth 1
git clone https://github.com/AloozChips/platform_vendor_lumine.git vendor/lumine -b bellflower --depth 1

export TZ=Asia/Dhaka
export BUILD_USERNAME=AloozChips
export BUILD_HOSTNAME=crave
export WITH_GMS=true
export TARGET_BUILD_VARIANT=user

. build/envsetup.sh
lunch fog-bp4a-user
m installclean
mka bacon -j$(nproc --all)
