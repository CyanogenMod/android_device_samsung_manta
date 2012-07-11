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
    device/samsung/manta/fstab.manta:root/fstab.manta \
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
    device/samsung/manta/fstab.smdk5250:root/fstab.smdk5250 \
    device/samsung/manta/ueventd.smdk5250.rc:root/ueventd.smdk5250.rc

# Input device files for smdk5250
PRODUCT_COPY_FILES += \
    device/samsung/manta/egalax_i2c.idc:system/usr/idc/egalax_i2c.idc \
    device/samsung/manta/smdk5250-keypad.kl:system/usr/keylayout/smdk5250-keypad.kl \
    device/samsung/manta/smdk5250-keypad.kcm:system/usr/keychars/smdk5250-keypad.kcm

PRODUCT_COPY_FILES += \
    frameworks/native/data/etc/tablet_core_hardware.xml:system/etc/permissions/tablet_core_hardware.xml \
    frameworks/native/data/etc/android.hardware.touchscreen.multitouch.jazzhand.xml:system/etc/permissions/android.hardware.touchscreen.multitouch.jazzhand.xml \
    frameworks/native/data/etc/android.hardware.wifi.xml:system/etc/permissions/android.hardware.wifi.xml \
    frameworks/native/data/etc/android.hardware.wifi.direct.xml:system/etc/permissions/android.hardware.wifi.direct.xml \
    device/samsung/manta/media_codecs.xml:system/etc/media_codecs.xml \
    frameworks/native/data/etc/android.hardware.camera.xml:system/etc/permissions/android.hardware.camera.xml \
    frameworks/native/data/etc/android.hardware.camera.front.xml:system/etc/permissions/android.hardware.camera.front.xml \


PRODUCT_COPY_FILES += \
    device/samsung/manta/bcmdhd.cal:system/etc/wifi/bcmdhd.cal

# audio mixer paths
PRODUCT_COPY_FILES += \
    device/samsung/manta/mixer_paths.xml:system/etc/mixer_paths.xml

# audio policy configuration
PRODUCT_COPY_FILES += \
    device/samsung/manta/audio_policy.conf:system/etc/audio_policy.conf

# for bugmailer
PRODUCT_PACKAGES += send_bug
PRODUCT_COPY_FILES += \
    system/extras/bugmailer/bugmailer.sh:system/bin/bugmailer.sh \
    system/extras/bugmailer/send_bug:system/bin/send_bug

# BCM47511 GPS
PRODUCT_COPY_FILES += \
    device/samsung/manta/gps/gps.conf:system/etc/gps.conf \
    device/samsung/manta/gps/gpsd:system/vendor/bin/gpsd \
    device/samsung/manta/gps/gps.xml:system/vendor/etc/gps.xml \
    device/samsung/manta/gps/gps.exynos5.so:system/lib/hw/gps.exynos5.so

PRODUCT_PACKAGES := \
    make_ext4fs \
    lights.manta \
    sensors.manta

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
    audio.primary.manta \
    audio.a2dp.default

PRODUCT_PACKAGES += \
    power.manta

PRODUCT_PACKAGES += \
    camera.exynos5

# Filesystem management tools
PRODUCT_PACKAGES += \
    make_ext4fs

PRODUCT_PROPERTY_OVERRIDES := \
    wifi.interface=wlan0 \
    ro.sf.lcd_density=320

# setup dalvik vm configs.
# this is temporary until we figure out what the new
# framework config should be for devices of this class:
# Currently, this device is:
#     xhdpi
#     xlarge screen (tablet)
#     2560x1600 resolution (high end?)
#     2048MB RAM
PRODUCT_PROPERTY_OVERRIDES += \
    dalvik.vm.heapstartsize=8m \
    dalvik.vm.heapgrowthlimit=64m \
    dalvik.vm.heapsize=256m

# for off charging mode
PRODUCT_PACKAGES += \
    charger \
    charger_res_images

$(call inherit-product, hardware/samsung_slsi/exynos5/exynos5.mk)
$(call inherit-product-if-exists, vendor/samsung_slsi/exynos5/exynos5-vendor.mk)
$(call inherit-product-if-exists, vendor/samsung/manta/device-vendor.mk)

$(call inherit-product-if-exists, hardware/broadcom/wlan/bcmdhd/firmware/bcm4324/device-bcm.mk)
