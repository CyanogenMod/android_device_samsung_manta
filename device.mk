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
    device/samsung/manta/init.recovery.manta.rc:root/init.recovery.manta.rc \
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
    device/samsung/manta/media_profiles.xml:system/etc/media_profiles.xml \
    frameworks/native/data/etc/android.hardware.camera.xml:system/etc/permissions/android.hardware.camera.xml \
    frameworks/native/data/etc/android.hardware.camera.front.xml:system/etc/permissions/android.hardware.camera.front.xml \
    frameworks/native/data/etc/android.hardware.usb.accessory.xml:system/etc/permissions/android.hardware.usb.accessory.xml \
    frameworks/native/data/etc/android.hardware.usb.host.xml:system/etc/permissions/android.hardware.usb.host.xml \
    frameworks/native/data/etc/android.hardware.location.gps.xml:system/etc/permissions/android.hardware.location.gps.xml \
    frameworks/native/data/etc/android.hardware.sensor.accelerometer.xml:system/etc/permissions/android.hardware.sensor.accelerometer.xml \
    frameworks/native/data/etc/android.hardware.sensor.barometer.xml:system/etc/permissions/android.hardware.sensor.barometer.xml \
    frameworks/native/data/etc/android.hardware.sensor.compass.xml:system/etc/permissions/android.hardware.sensor.compass.xml \
    frameworks/native/data/etc/android.hardware.sensor.gyroscope.xml:system/etc/permissions/android.hardware.sensor.gyroscope.xml \
    frameworks/native/data/etc/android.hardware.sensor.light.xml:system/etc/permissions/android.hardware.sensor.light.xml


PRODUCT_COPY_FILES += $(call add-to-product-copy-files-if-exists,\
packages/wallpapers/LivePicker/android.software.live_wallpaper.xml:system/etc/permissions/android.software.live_wallpaper.xml)


PRODUCT_COPY_FILES += \
    device/samsung/manta/bcmdhd.cal:system/etc/wifi/bcmdhd.cal

# audio mixer paths
PRODUCT_COPY_FILES += \
    device/samsung/manta/mixer_paths.xml:system/etc/mixer_paths.xml
# audio mixer paths for lunch box: remove when deprecated
PRODUCT_COPY_FILES += \
    device/samsung/manta/mixer_paths_lb.xml:system/etc/mixer_paths_lb.xml

# audio policy configuration
PRODUCT_COPY_FILES += \
    device/samsung/manta/audio_policy.conf:system/etc/audio_policy.conf

# for bugmailer
PRODUCT_PACKAGES := send_bug
PRODUCT_COPY_FILES += \
    system/extras/bugmailer/bugmailer.sh:system/bin/bugmailer.sh \
    system/extras/bugmailer/send_bug:system/bin/send_bug

# BCM47511 GPS
PRODUCT_COPY_FILES += \
    device/samsung/manta/gps/gps.conf:system/etc/gps.conf \
    device/samsung/manta/gps/gpsd:system/vendor/bin/gpsd \
    device/samsung/manta/gps/gps.xml:system/vendor/etc/gps.xml \
    device/samsung/manta/gps/gps.exynos5.so:system/lib/hw/gps.exynos5.so

# NFC packages
PRODUCT_PACKAGES += \
    libnfc-nci \
    libnfc_nci_jni \
    NfcNci \
    Tag \
    com.android.nfc_extras

# NFCEE access control
ifeq ($(TARGET_BUILD_VARIANT),user)
    NFCEE_ACCESS_PATH := device/samsung/manta/nfc/nfcee_access.xml
else
    NFCEE_ACCESS_PATH := device/samsung/manta/nfc/nfcee_access_debug.xml
endif

# NFC access control + feature files + configuration
PRODUCT_COPY_FILES += \
    $(NFCEE_ACCESS_PATH):system/etc/nfcee_access.xml \
    frameworks/native/data/etc/com.android.nfc_extras.xml:system/etc/permissions/com.android.nfc_extras.xml \
    frameworks/native/data/etc/android.hardware.nfc.xml:system/etc/permissions/android.hardware.nfc.xml \
    device/samsung/manta/nfc/libnfc-brcm.conf:system/etc/libnfc-brcm.conf

# NFC firmware for BCM2079x
PRODUCT_COPY_FILES += \
    hardware/broadcom/nfc/bcm2079x/bcm2079x_firmware.ncd:system/vendor/firmware/bcm2079x_firmware.ncd \
    hardware/broadcom/nfc/bcm2079x/bcm2079x_pre_firmware.ncd:system/vendor/firmware/bcm2079x_pre_firmware.ncd

PRODUCT_PACKAGES += \
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

PRODUCT_PACKAGES += \
    libion

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
$(call inherit-product, frameworks/native/build/tablet-10in-xhdpi-2048-dalvik-heap.mk)

# set default USB configuration
PRODUCT_DEFAULT_PROPERTY_OVERRIDES += \
    persist.sys.usb.config=mtp

# for off charging mode
PRODUCT_PACKAGES += \
    charger \
    charger_res_images

$(call inherit-product, hardware/samsung_slsi/exynos5/exynos5.mk)
$(call inherit-product-if-exists, vendor/samsung_slsi/exynos5/exynos5-vendor.mk)
$(call inherit-product-if-exists, vendor/samsung/manta/device-vendor.mk)

$(call inherit-product-if-exists, hardware/broadcom/wlan/bcmdhd/firmware/bcm4324/device-bcm.mk)
