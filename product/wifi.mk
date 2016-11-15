# WiFi WCNSS configurations
PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/wifi/bcmdhd.cal:system/etc/wifi/bcmdhd.cal

# WiFi properties
PRODUCT_PROPERTY_OVERRIDES += \
    wifi.interface=wlan0
