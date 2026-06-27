#
# Copyright (C) 2021 The LineageOS Project
#
# SPDX-License-Identifier: Apache-2.0
#

# ==========================================
# 1. Platform & Kernel Base (Wajib di Atas)
# ==========================================
TARGET_BOARD_PLATFORM := msm8937
TARGET_KERNEL_VERSION := 4.19

# Spesifikasi Arsitektur Kernel untuk Axion/AOSP Modern
TARGET_KERNEL_ARCH := arm64
TARGET_KERNEL_HEADER_ARCH := arm64

# Flag Ekosistem Mithorium
TARGET_USES_MITHORIUM_KERNEL := true

# ==========================================
# 2. Partitions Setup (MIGRASI TOTAL KE EROFS)
# ==========================================
SSI_PARTITIONS := product system system_ext
TREBLE_PARTITIONS := odm vendor
ALL_PARTITIONS := $(SSI_PARTITIONS) $(TREBLE_PARTITIONS)

# Set semua partisi output agar menggunakan EROFS
$(foreach p, $(call to-upper, $(ALL_PARTITIONS)), \
    $(eval BOARD_$(p)IMAGE_FILE_SYSTEM_TYPE := erofs) \
    $(eval TARGET_COPY_OUT_$(p) := $(call to-lower, $(p))))

# Argumen Kompresi Kuat LZ4HC untuk menghemat ruang block RDP
BOARD_EROFS_COMMANDLINE := -b 4096 -C 16384 -z lz4hc,9

# ==========================================
# 3. Inherit from Common Mithorium
# ==========================================
# Dipanggil setelah platform & versi di-set agar filenya tidak bingung
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

# ==========================================
# 4. Partitions Size & Config (Infinity-X & KSU Next Adopted)
# ==========================================
BOARD_USES_METADATA_PARTITION := true

# Size boot & recovery dinaikkan untuk menampung kernel Axion + patch KSU Next & RAMDISK
BOARD_BOOTIMAGE_PARTITION_SIZE := 134217728
BOARD_RECOVERYIMAGE_PARTITION_SIZE := 67108864
BOARD_CACHEIMAGE_FILE_SYSTEM_TYPE := ext4
BOARD_CACHEIMAGE_PARTITION_SIZE := 268435456
BOARD_USERDATAIMAGE_PARTITION_SIZE := 10332634112

# RETROFIT DYNAMIC PARTITIONS CONFIG
BOARD_SUPER_PARTITION_BLOCK_DEVICES := cust system
BOARD_SUPER_PARTITION_METADATA_DEVICE := system

# Ukuran eMMC fisik presisi gabungan cust + system
BOARD_SUPER_PARTITION_CUST_DEVICE_SIZE := 536870912
BOARD_SUPER_PARTITION_SYSTEM_DEVICE_SIZE := 3285073920
BOARD_SUPER_PARTITION_SIZE := 3821944832

# Mengaktifkan flag retrofit murni agar updater-script otomatis rebuild tabel virtual saat flash
PRODUCT_RETROFIT_DYNAMIC_PARTITIONS := true

# SETUP GRUP DINAMIS - Di-lock ke nilai maksimal Infinity-X msm8937 yang sukses booting
BOARD_SUPER_PARTITION_GROUPS := mi8937_dynpart
BOARD_MI8937_DYNPART_SIZE := 3753902080
BOARD_MI8937_DYNPART_PARTITION_LIST := $(ALL_PARTITIONS)

# Partitions - reserved size (Diberi nilai 0 karena EROFS menghitung otomatis secara dinamis)
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
#BOARD_KERNEL_CMDLINE += androidboot.selinux=permissive

# Inherit from the proprietary version
include vendor/xiaomi/Mi8937/BoardConfigVendor.mk

# Axion Official/Unofficial Maintainer Identity
AXION_MAINTAINER := ALIF.C_105
AXION_BUILD_TYPE := UNOFFICIAL
