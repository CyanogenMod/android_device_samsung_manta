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

# Don't use the CM charger
WITH_CM_CHARGER := false

# These two variables are set first, so they can be overridden
# by BoardConfigVendor.mk
BOARD_USES_GENERIC_AUDIO := true

TARGET_BOARD_INFO_FILE := device/samsung/manta/board-info.txt
BOARD_BLUETOOTH_BDROID_BUILDCFG_INCLUDE_DIR := device/samsung/manta/bluetooth

# Use the non-open-source parts, if they're present
-include vendor/samsung/manta/BoardConfigVendor.mk

TARGET_CPU_ABI := armeabi-v7a
TARGET_CPU_ABI2 := armeabi
TARGET_ARCH := arm
TARGET_ARCH_VARIANT := armv7-a-neon
TARGET_CPU_VARIANT := cortex-a15

# Define kernel config for inline building
TARGET_KERNEL_CONFIG := cyanogenmod_manta_defconfig
TARGET_KERNEL_SOURCE := kernel/samsung/manta

#Bluetooth
BOARD_HAVE_BLUETOOTH := true
BOARD_HAVE_BLUETOOTH_BCM := true
BCM_BLUETOOTH_MANTA_BUG := true

# build/core/Makefile
TARGET_NO_BOOTLOADER := true

USE_CLANG_PLATFORM_BUILD := true

TARGET_NO_RADIOIMAGE := true
TARGET_BOARD_PLATFORM := exynos5
TARGET_BOOTLOADER_BOARD_NAME := manta

BOARD_EGL_CFG := device/samsung/manta/egl.cfg

OVERRIDE_RS_DRIVER := libRSDriverArm.so

NUM_FRAMEBUFFER_SURFACE_BUFFERS := 3

TARGET_RECOVERY_FSTAB = device/samsung/manta/fstab.manta
RECOVERY_FSTAB_VERSION := 2
TARGET_USERIMAGES_USE_EXT4 := true
BOARD_SYSTEMIMAGE_PARTITION_SIZE := 838860800
# Disable journaling on system.img to save space.
BOARD_SYSTEMIMAGE_JOURNAL_SIZE := 0
BOARD_USERDATAIMAGE_PARTITION_SIZE := 14273216512
BOARD_CACHEIMAGE_PARTITION_SIZE := 553648128
BOARD_CACHEIMAGE_FILE_SYSTEM_TYPE := ext4
BOARD_FLASH_BLOCK_SIZE := 4096

WITH_DEXPREOPT_BOOT_IMG_ONLY ?= false
WITH_DEXPREOPT := false
DONT_DEXPREOPT_PREBUILTS := true

# Wifi related defines
BOARD_WPA_SUPPLICANT_DRIVER := NL80211
WPA_SUPPLICANT_VERSION      := VER_0_8_X
BOARD_WPA_SUPPLICANT_PRIVATE_LIB := lib_driver_cmd_bcmdhd
BOARD_HOSTAPD_DRIVER        := NL80211
BOARD_HOSTAPD_PRIVATE_LIB   := lib_driver_cmd_bcmdhd
BOARD_WLAN_DEVICE           := bcmdhd
WIFI_DRIVER_FW_PATH_PARAM   := "/sys/module/bcmdhd/parameters/firmware_path"
WIFI_DRIVER_FW_PATH_STA     := "/vendor/firmware/fw_bcmdhd.bin"
WIFI_DRIVER_FW_PATH_AP      := "/vendor/firmware/fw_bcmdhd_apsta.bin"

BOARD_HAL_STATIC_LIBRARIES := libhealthd.manta libdumpstate.manta

BOARD_CHARGER_DISABLE_INIT_BLANK := true
BOARD_CHARGER_SHOW_PERCENTAGE := true

TARGET_RECOVERY_UPDATER_LIBS += librecovery_updater_manta
TARGET_RELEASETOOLS_EXTENSIONS := device/samsung/manta
BOARD_USE_CUSTOM_RECOVERY_FONT := \"roboto_23x41.h\"

# Default card id for USB audio
BOARD_USB_AUDIO_CARD_ID := 2

BOARD_SEPOLICY_DIRS += \
	device/samsung/manta/sepolicy

MALLOC_IMPL := dlmalloc

BOARD_INV_LIBMLLITE_FROM_SOURCE := true