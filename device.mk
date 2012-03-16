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
	device/samsung/manta/init.manta.rc:root/init.manta.rc \
	device/samsung/manta/init.manta.usb.rc:root/init.manta.usb.rc \
	device/samsung/manta/ueventd.manta.rc:root/ueventd.manta.rc

# Input device files for manta
PRODUCT_COPY_FILES += \
	device/samsung/manta/Atmel_maXTouch_Touchscreen.idc:system/usr/idc/Atmel_maXTouch_Touchscreen.idc \
	device/samsung/manta/manta-keypad.kl:system/usr/keylayout/manta-keypad.kl \
	device/samsung/manta/manta-keypad.kcm:system/usr/keychars/manta-keypad.kcm


# Init files for booting smdk5250 with a manta image
PRODUCT_COPY_FILES += \
	device/samsung/manta/init.smdk5250.rc:root/init.smdk5250.rc \
	device/samsung/manta/init.smdk5250.usb.rc:root/init.smdk5250.usb.rc \
	device/samsung/manta/ueventd.smdk5250.rc:root/ueventd.smdk5250.rc

# Input device files for smdk5250
PRODUCT_COPY_FILES += \
	device/samsung/manta/egalax_i2c.idc:system/usr/idc/egalax_i2c.idc \
	device/samsung/manta/smdk5250-keypad.kl:system/usr/keylayout/smdk5250-keypad.kl \
	device/samsung/manta/smdk5250-keypad.kcm:system/usr/keychars/smdk5250-keypad.kcm

PRODUCT_COPY_FILES += \
	frameworks/base/data/etc/tablet_core_hardware.xml:system/etc/permissions/tablet_core_hardware.xml \
	frameworks/base/data/etc/android.hardware.touchscreen.multitouch.jazzhand.xml:system/etc/permissions/android.hardware.touchscreen.multitouch.jazzhand.xml \
	frameworks/base/data/etc/android.hardware.wifi.xml:system/etc/permissions/android.hardware.wifi.xml

PRODUCT_COPY_FILES += \
	device/samsung/manta/bcmdhd.cal:system/etc/wifi/bcmdhd.cal

PRODUCT_PACKAGES := \
        make_ext4fs \
        lights.manta

PRODUCT_AAPT_CONFIG := xlarge hdpi xhdpi
PRODUCT_AAPT_PREF_CONFIG := xhdpi

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

PRODUCT_PROPERTY_OVERRIDES := \
	wifi.interface=wlan0

$(call inherit-product-if-exists, hardware/broadcom/wlan/bcmdhd/firmware/bcm4324/device-bcm.mk)