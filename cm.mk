#
# Copyright (C) 2012-2016 The CyanogenMod Project
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

# Enhanced NFC
$(call inherit-product, vendor/cm/config/nfc_enhanced.mk)

# Inherit common CM stuff
$(call inherit-product, vendor/cm/config/common_mini_tablet_wifionly.mk)

# Inherit device configurations
$(call inherit-product, device/sony/manta/device.mk)

# Device display
TARGET_BOOTANIMATION_HALF_RES := true
TARGET_SCREEN_HEIGHT := 1600
TARGET_SCREEN_WIDTH := 2560

# Device identifications
PRODUCT_DEVICE := manta
PRODUCT_NAME := cm_manta
PRODUCT_BRAND := Google
PRODUCT_MANUFACTURER := samsung
PRODUCT_MODEL := Nexus 10

# Build fingerprints
PRODUCT_BUILD_PROP_OVERRIDES += PRODUCT_NAME=mantaray BUILD_FINGERPRINT=google/mantaray/manta:5.1.1/LMY49J/2640980:user/release-keys PRIVATE_BUILD_DESC="mantaray-user 5.1.1 LMY49J 2640980 release-keys"
