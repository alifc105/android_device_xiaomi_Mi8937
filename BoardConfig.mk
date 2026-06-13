#
# Copyright (C) 2021 The LineageOS Project
#
# SPDX-License-Identifier: Apache-2.0
#

# ==========================================
# 1. Platform & Kernel Base
# ==========================================
TARGET_BOARD_PLATFORM := msm8937
TARGET_KERNEL_VERSION := 4.19

TARGET_KERNEL_ARCH := arm64
TARGET_KERNEL_HEADER_ARCH := arm64
TARGET_USES_MITHORIUM_KERNEL := true

# ==========================================
# 2. Partitions Setup (TOTAL MIGRATION to EROFS)
# ==========================================
SSI_PARTITIONS := product system system_ext
TREBLE_PARTITIONS := odm vendor
ALL_PARTITIONS := $(SSI_PARTITIONS) $(TREBLE_PARTITIONS)

# Set all output partition to use EROFS
$(foreach p, $(call to-upper, $(ALL_PARTITIONS)), \
    $(eval BOARD_$(p)IMAGE_FILE_SYSTEM_TYPE := erofs) \
    $(eval TARGET_COPY_OUT_$(p) := $(call to-lower, $(p))))

# Add high compression arg LZ4HC to saving more block RDP size.
BOARD_EROFS_COMMANDLINE := -b 4096 -C 16384 -z lz4hc,9

# ==========================================
# 3. Inherit from Common Mithorium
# ==========================================
# Calling device common board config & setting the device version for it
include device/xiaomi/mithorium-common/BoardConfigCommon.mk

DEVICE_PATH := device/xiaomi/Mi8937
USES_DEVICE_XIAOMI_MI8937 := true

# Asserts
TARGET_BOARD_INFO_FILE := $(DEVICE_PATH)/board-info.txt
TARGET_OTA_ASSERT_DEVICE := mi8937,land,santoni,prada,ulysse,ugglite,ugg,rolex,riva,Mi8937,Mi8937_4_19,Mi8937_Ld

# Camera
#MI8937_CAM_USE_LATEST_CAMERA_STACK := true
ifeq ($(TARGET_KERNEL_VERSION),4.19)
TARGET_SUPPORT_HAL1 := false
endif

# Display
TARGET_SCREEN_DENSITY := 280

# Fastboot
TARGET_BOARD_FASTBOOT_INFO_FILE := $(DEVICE_PATH)/fastboot-info.txt

# HIDL
DEVICE_MANIFEST_FILE += $(DEVICE_PATH)/manifest.xml

# Init
$(call soong_config_set,libinit,vendor_init_lib,//$(DEVICE_PATH):init_xiaomi_mi8937)

# Kernel CMDLINE & Fragment Configurations
BOARD_KERNEL_CMDLINE += androidboot.boot_devices=soc/7824900.sdhci

ifeq ($(TARGET_KERNEL_VERSION),4.19)
TARGET_KERNEL_CONFIG += \
    vendor/msm8937-legacy.config
endif
TARGET_KERNEL_CONFIG += \
    vendor/xiaomi/msm8937/common.config \
    vendor/xiaomi/msm8937/mi8937.config

ifeq ($(MI8937_CAM_USE_LATEST_CAMERA_STACK),true)
TARGET_KERNEL_CONFIG += vendor/xiaomi/msm8937/optional/latest-camera-stack.config
endif

ifeq ($(TARGET_KERNEL_VERSION),4.19)
TARGET_KERNEL_RECOVERY_CONFIG += \
    vendor/msm8937-legacy.config
endif
TARGET_KERNEL_RECOVERY_CONFIG += \
    vendor/xiaomi/msm8937/common.config \
    vendor/xiaomi/msm8937/mi8937.config

# Partitions Size & Config
BOARD_USES_METADATA_PARTITION := true

BOARD_BOOTIMAGE_PARTITION_SIZE := 67108864
BOARD_RECOVERYIMAGE_PARTITION_SIZE := 67108864
BOARD_CACHEIMAGE_FILE_SYSTEM_TYPE := ext4
BOARD_CACHEIMAGE_PARTITION_SIZE := 268435456
BOARD_USERDATAIMAGE_PARTITION_SIZE := 10332634112 # 10332650496 - 16384

# Partitions - dynamic (Retrofit Dynamic Partitions)
BOARD_SUPER_PARTITION_BLOCK_DEVICES := cust system
BOARD_SUPER_PARTITION_METADATA_DEVICE := system
BOARD_SUPER_PARTITION_CUST_DEVICE_SIZE := 536870912
BOARD_SUPER_PARTITION_SYSTEM_DEVICE_SIZE := 3221225472
BOARD_SUPER_PARTITION_SIZE := $(shell expr $(BOARD_SUPER_PARTITION_CUST_DEVICE_SIZE) + $(BOARD_SUPER_PARTITION_SYSTEM_DEVICE_SIZE) )

# Setting group size to leaving space for metadata partition (preventing status 1 error in TWRP)
BOARD_SUPER_PARTITION_GROUPS := mi8937_dynpart
BOARD_MI8937_DYNPART_SIZE := $(shell expr $(BOARD_SUPER_PARTITION_SIZE) - 8388608 )
BOARD_MI8937_DYNPART_PARTITION_LIST := $(ALL_PARTITIONS)

# Partitions - reserved size (value is 0 because EROFS will calculating it dynamicly)
$(foreach p, $(call to-upper, $(ALL_PARTITIONS)), \
    $(eval BOARD_$(p)IMAGE_EXTFS_INODE_COUNT := -1) \
    $(eval BOARD_$(p)IMAGE_PARTITION_RESERVED_SIZE := 0))

# Properties
TARGET_VENDOR_PROP += $(DEVICE_PATH)/vendor.prop

# Recovery fstab
ifeq ($(TARGET_KERNEL_VERSION),4.19)
TARGET_RECOVERY_FSTAB := $(DEVICE_PATH)/rootdir/etc/fstab_4_19.qcom
else
TARGET_RECOVERY_FSTAB := $(DEVICE_PATH)/rootdir/etc/fstab_4_9.qcom
endif

# Rootdir
SOONG_CONFIG_NAMESPACES += XIAOMI_MI8937_ROOTDIR
SOONG_CONFIG_XIAOMI_MI8937_ROOTDIR := KERNEL_VERSION
ifeq ($(TARGET_KERNEL_VERSION),4.19)
SOONG_CONFIG_XIAOMI_MI8937_ROOTDIR_KERNEL_VERSION := k4_19
else
SOONG_CONFIG_XIAOMI_MI8937_ROOTDIR_KERNEL_VERSION := k4_9
endif

# Security patch level
VENDOR_SECURITY_PATCH := 2017-04-01

# SELinux
BOARD_ODM_SEPOLICY_DIRS += $(DEVICE_PATH)/sepolicy/odm
BOARD_VENDOR_SEPOLICY_DIRS += $(DEVICE_PATH)/sepolicy/vendor
BOARD_ODM_SEPOLICY_DIRS += $(DEVICE_PATH)/biometrics/sepolicy-odm
BOARD_VENDOR_SEPOLICY_DIRS += $(DEVICE_PATH)/biometrics/sepolicy

# Inherit from the proprietary version
include vendor/xiaomi/Mi8937/BoardConfigVendor.mk
