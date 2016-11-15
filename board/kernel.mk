# Kernel properties
TARGET_KERNEL_SOURCE := kernel/samsung/manta
TARGET_KERNEL_CONFIG := cyanogenmod_manta_defconfig

# Use 4.8 until booting with 4.9 is fixed
KERNEL_TOOLCHAIN := $(ANDROID_BUILD_TOP)/prebuilts/gcc/$(HOST_OS)-x86/arm/arm-eabi-4.8/bin
TARGET_KERNEL_CROSS_COMPILE_PREFIX := arm-eabi-
