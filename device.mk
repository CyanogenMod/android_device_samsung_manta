#
# Copyright (C) 2011 The Android Open-Source Project
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

ifeq ($(TARGET_PREBUILT_KERNEL),)
LOCAL_KERNEL := device/samsung/manta/kernel
else
LOCAL_KERNEL := $(TARGET_PREBUILT_KERNEL)
endif

PRODUCT_COPY_FILES := \
	$(LOCAL_KERNEL):kernel \
	device/samsung/manta/init.smdk5250.rc:root/init.smdk5250.rc \
	device/samsung/manta/init.smdk5250.usb.rc:root/init.smdk5250.usb.rc \
	device/samsung/manta/ueventd.smdk5250.rc:root/ueventd.smdk5250.rc

# Input device files for smdk5250
PRODUCT_COPY_FILES += \
	device/samsung/manta/egalax_i2c.idc:system/usr/idc/egalax_i2c.idc \
	device/samsung/manta/smdk5250-keypad.kl:system/usr/keylayout/smdk5250-keypad.kl \
	device/samsung/manta/smdk5250-keypad.kcm:system/usr/keychars/smdk5250-keypad.kcm

PRODUCT_PACKAGES := \
        make_ext4fs

PRODUCT_PROPERTY_OVERRIDES :=

PRODUCT_CHARACTERISTICS := tablet,nosdcard

DEVICE_PACKAGE_OVERLAYS := \
    device/samsung/manta/overlay

# for now include gralloc here. should come from hardware/samsung_slsi/exynos5
PRODUCT_PACKAGES += \
    gralloc.exynos5

PRODUCT_TAGS += dalvik.gc.type-precise

PRODUCT_PACKAGES += \
	librs_jni \
	com.android.future.usb.accessory

PRODUCT_PACKAGES += \
	audio.primary.default \
	audio.a2dp.default

# Filesystem management tools
PRODUCT_PACKAGES += \
	make_ext4fs

$(call inherit-product-if-exists, vendor/samsung_slsi/exynos5/exynos5-vendor.mk)
$(call inherit-product-if-exists, vendor/samsung/manta/device-vendor.mk)
$(call inherit-product, frameworks/base/build/tablet-dalvik-heap.mk)
