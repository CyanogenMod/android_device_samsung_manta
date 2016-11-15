# Audio permissions
PRODUCT_COPY_FILES += \
    frameworks/native/data/etc/android.hardware.audio.low_latency.xml:system/etc/permissions/android.hardware.audio.low_latency.xm

# Audio packages
PRODUCT_PACKAGES += \
    audio.a2dp.default \
    audio.primary.manta \
    audio.r_submix.default \
    audio.usb.default \
    libbubblelevel \
    libaudience_voicefx
