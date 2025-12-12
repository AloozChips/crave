#!/bin/bash

rm -rf .repo/local_manifests
rm -rf packages/apps/Updater

repo init -u https://github.com/Evolution-X/manifest -b bq2 --git-lfs

/opt/crave/resync.sh || repo sync -c -j$(nproc --all) --force-sync --no-clone-bundle --no-tags
#safer sync
/opt/crave/resync.sh || repo sync -c -j$(nproc --all) --force-sync --no-clone-bundle --no-tags

rm -rf device/xiaomi/fog
rm -rf vendor/xiaomi/fog
rm -rf device/xiaomi/fog-kernel
rm -rf hardware/xiaomi
rm -rf packages/apps/Updater
rm -rf out/target/product/fog

git clone https://github.com/AloozChips/device_xiaomi_fog.git device/xiaomi/fog -b evoq2 --depth 1
git clone https://github.com/AloozChips/vendor_xiaomi_fog.git vendor/xiaomi/fog -b baklava-and-beyond --depth 1
git clone https://github.com/AloozChips/device_xiaomi_fog-kernel.git device/xiaomi/fog-kernel -b ksu-and-bpf --depth 1
git clone https://github.com/LineageOS/android_hardware_xiaomi.git hardware/xiaomi -b lineage-23.2 --depth 1
git clone https://github.com/AloozChips/evo_updater.git packages/apps/Updater -b fog --depth 1

export TZ=Asia/Dhaka
export BUILD_USERNAME=AloozChips
export BUILD_HOSTNAME=crave
export WITH_GMS=true
export TARGET_BUILD_VARIANT=user

. build/envsetup.sh
lunch lineage_fog-bp4a-user
m installclean
m evolution -j$(nproc --all)
