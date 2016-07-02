#!/bin/sh

# Copyright (C) 2012 The CyanogenMod Project
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

#--------------------------------------------------------------

DEVICE=manta
MANUFACTURER=samsung
OUTVENDOR=vendor
#--------------------------------------------------------------

#--------------------------------------------------------------
# SAMSUNG
#--------------------------------------------------------------

OUTDIR=$OUTVENDOR/$MANUFACTURER/$DEVICE
mkdir -p ../../../$OUTDIR/proprietary
MAKEFILE=../../../$OUTDIR/device-vendor.mk

(cat << EOF) > $MAKEFILE
# Copyright (C) 2012 The CyanogenMod Project
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

LOCAL_STEM := manta/device-partial.mk

\$(call inherit-product-if-exists, vendor/audience/\$(LOCAL_STEM))
\$(call inherit-product-if-exists, vendor/broadcom/\$(LOCAL_STEM))
\$(call inherit-product-if-exists, vendor/samsung/\$(LOCAL_STEM))
\$(call inherit-product-if-exists, vendor/widevine/\$(LOCAL_STEM))

PRODUCT_RESTRICT_VENDOR_FILES := owner
EOF

#--------------------------------------------------------------

MAKEFILE=../../../$OUTDIR/BoardConfigVendor.mk

(cat << EOF) > $MAKEFILE
# Copyright (C) 2012 The CyanogenMod Project
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

LOCAL_STEM := manta/BoardConfigPartial.mk

-include vendor/audience/\$(LOCAL_STEM)
-include vendor/broadcom/\$(LOCAL_STEM)
-include vendor/samsung/\$(LOCAL_STEM)
-include vendor/widevine/\$(LOCAL_STEM)

EOF

#--------------------------------------------------------------

MAKEFILE=../../../$OUTDIR/BoardConfigPartial.mk

(cat << EOF) > $MAKEFILE
# Copyright (C) 2012 The CyanogenMod Project
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
EOF

#--------------------------------------------------------------
#  SAMSUNG PROPS
#--------------------------------------------------------------

OUTDIR=$OUTVENDOR/samsung/$DEVICE
mkdir -p ../../../$OUTDIR/proprietary
MAKEFILE=../../../$OUTDIR/device-partial.mk

(cat << EOF) > $MAKEFILE
# Copyright (C) 2012 The CyanogenMod Project
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

# Samsung blob(s) necessary for manta hardware
PRODUCT_PACKAGES := \
    fimc_is_fw \\
    fimc_is_fw2 \\
    mfc_fw \\
    maxtouch \\
    setfile \\
    setfile_4e5 \\
    setfile_6a3 \\
    00060308060501020000000000000000 \\
    020a0000000000000000000000000000 \\
    07060000000000000000000000000000 \\
    ffffffff000000000000000000000005 \\
    libGLES_mali \\
    libmalicore \\
    libRSDriverArm \\
    libstagefright_hdcp
EOF

#--------------------------------------------------------------

MAKEFILE=../../../$OUTDIR/proprietary/Android.mk

(cat << EOF) > $MAKEFILE
# Copyright (C) 2012 The CyanogenMod Project
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

LOCAL_PATH := \$(call my-dir)

ifeq (\$(TARGET_DEVICE),manta)

include \$(CLEAR_VARS)
LOCAL_MODULE := fimc_is_fw
LOCAL_SRC_FILES := fimc_is_fw.bin
LOCAL_MODULE_SUFFIX := .bin
LOCAL_MODULE_CLASS := ETC
LOCAL_MODULE_PATH := \$(TARGET_OUT_VENDOR)/firmware
LOCAL_MODULE_TAGS := optional
LOCAL_MODULE_OWNER := samsung
include \$(BUILD_PREBUILT)

include \$(CLEAR_VARS)
LOCAL_MODULE := fimc_is_fw2
LOCAL_SRC_FILES := fimc_is_fw2.bin
LOCAL_MODULE_SUFFIX := .bin
LOCAL_MODULE_CLASS := ETC
LOCAL_MODULE_PATH := \$(TARGET_OUT_VENDOR)/firmware
LOCAL_MODULE_TAGS := optional
LOCAL_MODULE_OWNER := samsung
include \$(BUILD_PREBUILT)

include \$(CLEAR_VARS)
LOCAL_MODULE := maxtouch
LOCAL_SRC_FILES := maxtouch.fw
LOCAL_MODULE_SUFFIX := .fw
LOCAL_MODULE_CLASS := ETC
LOCAL_MODULE_PATH := \$(TARGET_OUT_VENDOR)/firmware
LOCAL_MODULE_TAGS := optional
LOCAL_MODULE_OWNER := samsung
include \$(BUILD_PREBUILT)

include \$(CLEAR_VARS)
LOCAL_MODULE := mfc_fw
LOCAL_SRC_FILES := mfc_fw.bin
LOCAL_MODULE_SUFFIX := .bin
LOCAL_MODULE_CLASS := ETC
LOCAL_MODULE_PATH := \$(TARGET_OUT_VENDOR)/firmware
LOCAL_MODULE_TAGS := optional
LOCAL_MODULE_OWNER := samsung
include \$(BUILD_PREBUILT)

include \$(CLEAR_VARS)
LOCAL_MODULE := setfile
LOCAL_SRC_FILES := setfile.bin
LOCAL_MODULE_SUFFIX := .bin
LOCAL_MODULE_CLASS := ETC
LOCAL_MODULE_PATH := \$(TARGET_OUT_VENDOR)/firmware
LOCAL_MODULE_TAGS := optional
LOCAL_MODULE_OWNER := samsung
include \$(BUILD_PREBUILT)

include \$(CLEAR_VARS)
LOCAL_MODULE := setfile_4e5
LOCAL_SRC_FILES := setfile_4e5.bin
LOCAL_MODULE_SUFFIX := .bin
LOCAL_MODULE_CLASS := ETC
LOCAL_MODULE_PATH := \$(TARGET_OUT_VENDOR)/firmware
LOCAL_MODULE_TAGS := optional
LOCAL_MODULE_OWNER := samsung
include \$(BUILD_PREBUILT)

include \$(CLEAR_VARS)
LOCAL_MODULE := setfile_6a3
LOCAL_SRC_FILES := setfile_6a3.bin
LOCAL_MODULE_SUFFIX := .bin
LOCAL_MODULE_CLASS := ETC
LOCAL_MODULE_PATH := \$(TARGET_OUT_VENDOR)/firmware
LOCAL_MODULE_TAGS := optional
LOCAL_MODULE_OWNER := samsung
include \$(BUILD_PREBUILT)

include \$(CLEAR_VARS)
LOCAL_MODULE := libGLES_mali
LOCAL_SRC_FILES := libGLES_mali.so
LOCAL_MODULE_SUFFIX := .so
LOCAL_MODULE_CLASS := SHARED_LIBRARIES
LOCAL_MODULE_PATH := \$(TARGET_OUT_VENDOR_SHARED_LIBRARIES)/egl
LOCAL_MODULE_TAGS := optional
LOCAL_MODULE_OWNER := samsung_arm
include \$(BUILD_PREBUILT)

include \$(CLEAR_VARS)
LOCAL_MODULE := libmalicore
LOCAL_SRC_FILES := libmalicore.bc
LOCAL_MODULE_SUFFIX := .bc
LOCAL_MODULE_CLASS := ETC
LOCAL_MODULE_PATH := \$(TARGET_OUT_VENDOR_SHARED_LIBRARIES)
LOCAL_MODULE_TAGS := optional
LOCAL_MODULE_OWNER := samsung_arm
include \$(BUILD_PREBUILT)

include \$(CLEAR_VARS)
LOCAL_MODULE := libRSDriverArm
LOCAL_SRC_FILES := libRSDriverArm.so
LOCAL_MODULE_SUFFIX := .so
LOCAL_MODULE_CLASS := SHARED_LIBRARIES
LOCAL_MODULE_PATH := \$(TARGET_OUT_VENDOR_SHARED_LIBRARIES)
LOCAL_MODULE_TAGS := optional
LOCAL_MODULE_OWNER := samsung_arm
include \$(BUILD_PREBUILT)

include \$(CLEAR_VARS)
LOCAL_MODULE := libstagefright_hdcp
LOCAL_SRC_FILES := libstagefright_hdcp.so
LOCAL_MODULE_SUFFIX := .so
LOCAL_MODULE_CLASS := SHARED_LIBRARIES
LOCAL_MODULE_PATH := \$(TARGET_OUT_VENDOR_SHARED_LIBRARIES)
LOCAL_MODULE_TAGS := optional
LOCAL_MODULE_OWNER := samsung_arm
include \$(BUILD_PREBUILT)

include \$(CLEAR_VARS)
LOCAL_MODULE := 00060308060501020000000000000000
LOCAL_SRC_FILES := 00060308060501020000000000000000.tlbin
LOCAL_MODULE_SUFFIX := .tlbin
LOCAL_MODULE_CLASS := ETC
LOCAL_MODULE_PATH := \$(TARGET_OUT_VENDOR)/secapp
LOCAL_MODULE_TAGS := optional
LOCAL_MODULE_OWNER := samsung
include \$(BUILD_PREBUILT)

include \$(CLEAR_VARS)
LOCAL_MODULE := 020a0000000000000000000000000000
LOCAL_SRC_FILES := 020a0000000000000000000000000000.drbin
LOCAL_MODULE_SUFFIX := .drbin
LOCAL_MODULE_CLASS := ETC
LOCAL_MODULE_PATH := \$(TARGET_OUT_VENDOR)/secapp
LOCAL_MODULE_TAGS := optional
LOCAL_MODULE_OWNER := samsung
include \$(BUILD_PREBUILT)

include \$(CLEAR_VARS)
LOCAL_MODULE := 07060000000000000000000000000000
LOCAL_SRC_FILES := 07060000000000000000000000000000.tlbin
LOCAL_MODULE_SUFFIX := .tlbin
LOCAL_MODULE_CLASS := ETC
LOCAL_MODULE_PATH := \$(TARGET_OUT_VENDOR)/secapp
LOCAL_MODULE_TAGS := optional
LOCAL_MODULE_OWNER := samsung
include \$(BUILD_PREBUILT)

include \$(CLEAR_VARS)
LOCAL_MODULE := ffffffff000000000000000000000005
LOCAL_SRC_FILES := ffffffff000000000000000000000005.tlbin
LOCAL_MODULE_SUFFIX := .tlbin
LOCAL_MODULE_CLASS := ETC
LOCAL_MODULE_PATH := \$(TARGET_OUT_VENDOR)/secapp
LOCAL_MODULE_TAGS := optional
LOCAL_MODULE_OWNER := samsung
include \$(BUILD_PREBUILT)


endif
EOF

#--------------------------------------------------------------
#  BROADCOM
#--------------------------------------------------------------

OUTDIR=$OUTVENDOR/broadcom/$DEVICE
mkdir -p ../../../$OUTDIR/proprietary
MAKEFILE=../../../$OUTDIR/proprietary/Android.mk

(cat << EOF) > $MAKEFILE
# Copyright (C) 2012 The CyanogenMod Project
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

LOCAL_PATH := \$(call my-dir)

ifeq (\$(TARGET_DEVICE),manta)

include \$(CLEAR_VARS)
LOCAL_MODULE := bcm2079x_firmware
LOCAL_SRC_FILES := bcm2079x_firmware.ncd
LOCAL_MODULE_SUFFIX := .ncd
LOCAL_MODULE_CLASS := ETC
LOCAL_MODULE_PATH := \$(TARGET_OUT_VENDOR)/firmware
LOCAL_MODULE_TAGS := optional
LOCAL_MODULE_OWNER := broadcom
include \$(BUILD_PREBUILT)

include \$(CLEAR_VARS)
LOCAL_MODULE := bcm2079x_pre_firmware
LOCAL_SRC_FILES := bcm2079x_pre_firmware.ncd
LOCAL_MODULE_SUFFIX := .ncd
LOCAL_MODULE_CLASS := ETC
LOCAL_MODULE_PATH := \$(TARGET_OUT_VENDOR)/firmware
LOCAL_MODULE_TAGS := optional
LOCAL_MODULE_OWNER := broadcom
include \$(BUILD_PREBUILT)

include \$(CLEAR_VARS)
LOCAL_MODULE := bcm43241
LOCAL_SRC_FILES := bcm43241.hcd
LOCAL_MODULE_SUFFIX := .hcd
LOCAL_MODULE_CLASS := ETC
LOCAL_MODULE_PATH := \$(TARGET_OUT_VENDOR)/firmware
LOCAL_MODULE_TAGS := optional
LOCAL_MODULE_OWNER := broadcom
include \$(BUILD_PREBUILT)

endif
EOF

#-------------------------------------------------------------------------

MAKEFILE=../../../$OUTDIR/device-partial.mk

(cat << EOF) > $MAKEFILE
# Copyright (C) 2012 The CyanogenMod Project
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

# Broadcom blob(s) necessary for Manta hardware
PRODUCT_PACKAGES := \\
    bcm2079x_firmware \\
    bcm2079x_pre_firmware \\
    bcm43241
EOF

MAKEFILE=../../../$OUTDIR/BoardConfigPartial.mk

(cat << EOF) > $MAKEFILE
# Copyright (C) 2012 The CyanogenMod Project
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
EOF

#--------------------------------------------------------------
#  AUDIENCE
#--------------------------------------------------------------

OUTDIR=$OUTVENDOR/audience/$DEVICE
mkdir -p ../../../$OUTDIR/proprietary
MAKEFILE=../../../$OUTDIR/proprietary/Android.mk

(cat << EOF) > $MAKEFILE
# Copyright (C) 2012 The CyanogenMod Project
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

LOCAL_PATH := \$(call my-dir)

ifeq (\$(TARGET_DEVICE),manta)

include \$(CLEAR_VARS)
LOCAL_MODULE := es305_fw
LOCAL_SRC_FILES := es305_fw.bin
LOCAL_MODULE_SUFFIX := .bin
LOCAL_MODULE_CLASS := ETC
LOCAL_MODULE_PATH := \$(TARGET_OUT_VENDOR)/firmware
LOCAL_MODULE_TAGS := optional
LOCAL_MODULE_OWNER := audience
include \$(BUILD_PREBUILT)

endif
EOF

#---------------------------------------------------------------

MAKEFILE=../../../$OUTDIR/device-partial.mk

(cat << EOF) > $MAKEFILE
# Copyright (C) 2012 The CyanogenMod Project
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

# Audience blob(s) necessary for manta hardware
PRODUCT_PACKAGES := \\
    es305_fw
EOF

#--------------------------------------------------------------

MAKEFILE=../../../$OUTDIR/BoardConfigPartial.mk

(cat << EOF) > $MAKEFILE
# Copyright (C) 2012 The CyanogenMod Project
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
EOF

#--------------------------------------------------------------
#  WIDEVINE
#--------------------------------------------------------------


OUTDIR=$OUTVENDOR/widevine/$DEVICE
mkdir -p ../../../$OUTDIR/proprietary
MAKEFILE=../../../$OUTDIR/proprietary/Android.mk

(cat << EOF) > $MAKEFILE
# Copyright (C) 2012 The CyanogenMod Project
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

LOCAL_PATH := \$(call my-dir)

ifeq (\$(TARGET_DEVICE),manta)

include \$(CLEAR_VARS)
LOCAL_MODULE := libwvdrm_L1
LOCAL_SRC_FILES := libwvdrm_L1.so
LOCAL_MODULE_SUFFIX := .so
LOCAL_MODULE_CLASS := SHARED_LIBRARIES
LOCAL_MODULE_PATH := \$(TARGET_OUT_VENDOR_SHARED_LIBRARIES)
LOCAL_MODULE_TAGS := optional
LOCAL_MODULE_OWNER := widevine
include \$(BUILD_PREBUILT)

include \$(CLEAR_VARS)
LOCAL_MODULE := libWVStreamControlAPI_L1
LOCAL_SRC_FILES := libWVStreamControlAPI_L1.so
LOCAL_MODULE_SUFFIX := .so
LOCAL_MODULE_CLASS := SHARED_LIBRARIES
LOCAL_MODULE_PATH := \$(TARGET_OUT_VENDOR_SHARED_LIBRARIES)
LOCAL_MODULE_TAGS := optional
LOCAL_MODULE_OWNER := widevine
include \$(BUILD_PREBUILT)

include \$(CLEAR_VARS)
LOCAL_MODULE := libwvm
LOCAL_SRC_FILES := libwvm.so
LOCAL_MODULE_SUFFIX := .so
LOCAL_MODULE_CLASS := SHARED_LIBRARIES
LOCAL_MODULE_PATH := \$(TARGET_OUT_VENDOR_SHARED_LIBRARIES)
LOCAL_MODULE_TAGS := optional
LOCAL_MODULE_OWNER := widevine
include \$(BUILD_PREBUILT)

include \$(CLEAR_VARS)
LOCAL_MODULE := libwvdrmengine
LOCAL_SRC_FILES := libwvdrmengine.so
LOCAL_MODULE_SUFFIX := .so
LOCAL_MODULE_CLASS := SHARED_LIBRARIES
LOCAL_MODULE_PATH := \$(TARGET_OUT_VENDOR_SHARED_LIBRARIES)/mediadrm
LOCAL_MODULE_TAGS := optional
LOCAL_MODULE_OWNER := widevine
include \$(BUILD_PREBUILT)

include \$(CLEAR_VARS)
LOCAL_MODULE := libdrmdecrypt
LOCAL_SRC_FILES := libdrmdecrypt.so
LOCAL_MODULE_SUFFIX := .so
LOCAL_MODULE_CLASS := SHARED_LIBRARIES
LOCAL_MODULE_PATH := \$(TARGET_OUT_VENDOR_SHARED_LIBRARIES)
LOCAL_MODULE_TAGS := optional
LOCAL_MODULE_OWNER := widevine
include \$(BUILD_PREBUILT)

include \$(CLEAR_VARS)
LOCAL_MODULE := libdrmwvmplugin
LOCAL_SRC_FILES := libdrmwvmplugin.so
LOCAL_MODULE_SUFFIX := .so
LOCAL_MODULE_CLASS := SHARED_LIBRARIES
LOCAL_MODULE_PATH := \$(TARGET_OUT_VENDOR_SHARED_LIBRARIES)/drm
LOCAL_MODULE_TAGS := optional
LOCAL_MODULE_OWNER := widevine
include \$(BUILD_PREBUILT)

endif
EOF
#--------------------------------------------------------------

MAKEFILE=../../../$OUTDIR/device-partial.mk

(cat << EOF) > $MAKEFILE
# Copyright (C) 2012 The CyanogenMod Project
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

# Widevine blob(s) necessary for Manta hardware
PRODUCT_PACKAGES := \\
    libwvdrm_L1 \\
    libWVStreamControlAPI_L1 \\
    libwvm \\
    libdrmwvmplugin \\
    libdrmdecrypt \\
    libwvdrmengine
EOF

#--------------------------------------------------------------

MAKEFILE=../../../$OUTDIR/BoardConfigPartial.mk

(cat << EOF) > $MAKEFILE
# Copyright (C) 2012 The CyanogenMod Project
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
EOF

#--------------------------------------------------------------

