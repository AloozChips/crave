#!/bin/bash

rm -rf .repo/local_manifests
rm -rf packages/apps/Updater
rm -rf vendor/lumine
rm -rf build/soong

repo init -u https://github.com/LumineDroid/platform_manifest -b bellflower --git-lfs

/opt/crave/resync.sh || repo sync -c -j$(nproc --all) --force-sync --no-clone-bundle --no-tags
#safer sync
/opt/crave/resync.sh || repo sync -c -j$(nproc --all) --force-sync --no-clone-bundle --no-tags

pushd packages/apps/Updater
git fetch https://github.com/AloozChips/lumine_updater.git && git cherry-pick ec70f32492ede8b9d5b4a9bb601ca338823bbaa1
popd

pushd vendor/lumine
git fetch https://github.com/AloozChips/platform_vendor_lumine.git && git cherry-pick 113763a54f9e04a9d041126c7c4d5093d199a82d
popd

rm -rf device/xiaomi/fog
rm -rf vendor/xiaomi/fog
rm -rf device/xiaomi/fog-kernel
rm -rf hardware/xiaomi
rm -rf vendor/xiaomi/camera
rm -rf out/target/product/fog

git clone https://github.com/AloozChips/device_xiaomi_fog.git device/xiaomi/fog -b lumine --depth 1
git clone https://github.com/AloozChips/vendor_xiaomi_fog.git vendor/xiaomi/fog -b 25qx-staging --depth 1
git clone https://github.com/AloozChips/device_xiaomi_fog-kernel.git device/xiaomi/fog-kernel -b ksu-and-bpf --depth 1
git clone https://github.com/LineageOS/android_hardware_xiaomi.git hardware/xiaomi -b lineage-23.2 --depth 1
git clone https://gitlab.com/ThankYouMario/proprietary_vendor_xiaomi_camera.git vendor/xiaomi/camera -b vauxite-sm6225 --depth 1

export TZ=Asia/Dhaka
export BUILD_USERNAME=AloozChips
export BUILD_HOSTNAME=crave
export WITH_GMS=true
export TARGET_BUILD_VARIANT=user

. build/envsetup.sh
lunch fog-bp4a-user
m installclean
mka bacon -j$(nproc --all)
