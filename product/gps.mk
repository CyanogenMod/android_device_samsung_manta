# GPS configurations
PRODUCT_COPY_FILES += \
   $(LOCAL_PATH)/gps/gps.conf:system/etc/gps.conf \
   $(LOCAL_PATH)/gps/gps.xml:system/vendor/etc/gps.xml

# GPS packages
PRODUCT_COPY_FILES += \
   $(LOCAL_PATH)/gps/gpsd:system/vendor/bin/gpsd
   $(LOCAL_PATH)/gps/gps.manta.so:system/lib/hw/gps.manta.so
