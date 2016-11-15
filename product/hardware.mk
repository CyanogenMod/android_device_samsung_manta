# Hardware permissions
PRODUCT_COPY_FILES += \
    frameworks/native/data/etc/tablet_core_hardware.xml:system/etc/permissions/tablet_core_hardware.xml

# Lights package
PRODUCT_PACKAGES += \
    lights.manta

# Product characteristics
PRODUCT_CHARACTERISTICS := tablet,nosdcard
