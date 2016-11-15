# Audio configurations
PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/audio/etc/audio_effects.conf:system/vendor/etc/audio_effects.conf \
    $(LOCAL_PATH)/audio/etc/audio_policy.conf:system/etc/audio_policy.conf \
    $(LOCAL_PATH)/audio/etc/mixer_paths.xml:system/etc/mixer_paths.xml

# Audio properties
PRODUCT_PROPERTY_OVERRIDES += \
    af.fast_track_multiplier=1 \
    media.aac_51_output_enabled=true
