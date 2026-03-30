#!/bin/bash

rm -rf .repo/local_manifests

repo init -u https://github.com/AxionAOSP/android.git -b lineage-23.2 --git-lfs

/opt/crave/resync.sh || repo sync -c -j$(nproc --all) --force-sync --no-clone-bundle --no-tags
#safer sync
/opt/crave/resync.sh || repo sync -c -j$(nproc --all) --force-sync --no-clone-bundle --no-tags

pushd packages/apps/Updater
git fetch https://github.com/AloozChips/axion_updater.git
(git cherry-pick ef1ac7e9a79d308ab95f8fe03caeaa6f3c2821dd --no-edit && echo "pached custom OTA")  || (git cherry-pick --abort && echo "failed to patch custom OTA!")
popd

pushd bionic
(git revert 9857de532657f1f0d5147bbbbb713e281e514670 --no-edit && echo "reverted [jemalloc] dual allocator support (jemalloc default + Scudo fallback)") || (git revert --abort && echo "failed reverting [jemalloc] dual allocator support (jemalloc default + Scudo fallback)!")
popd

rm -rf device/xiaomi/fog
rm -rf vendor/xiaomi/fog
rm -rf device/xiaomi/fog-kernel
rm -rf hardware/xiaomi
rm -rf vendor/xiaomi/camera
rm -rf packages/apps/DolbyUI
rm -rf hardware/dolby
rm -rf out/target/product/fog

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
ax -br user -j$(nproc --all)
