#
# SPDX-FileCopyrightText: The LineageOS Project
# SPDX-License-Identifier: Apache-2.0
#

# Inherit from sm7250-common
include device/motorola/sm7250-common/BoardConfigCommon.mk

DEVICE_PATH := device/motorola/racer

# Display
TARGET_SCREEN_DENSITY := 420

# Fingerprint
TARGET_SURFACEFLINGER_UDFPS_LIB := //$(DEVICE_PATH):libudfps_extension.racer
TARGET_USES_FOD_ZPOS := true

# HIDL
DEVICE_MANIFEST_FILE += $(DEVICE_PATH)/manifest.xml

# Kernel
TARGET_KERNEL_CONFIG := vendor/racer_defconfig vendor/debugfs.config

# Kernel modules - Audio
TARGET_MODULE_ALIASES += \
    snd-soc-aov-trigger.ko:aov_trigger.ko \
    snd-soc-cs35l41-spi.ko:cirrus_cs35l41-spi.ko \
    snd-soc-cs35l41.ko:cirrus_cs35l41.ko \
    snd-soc-cs47l35.ko:cirrus_cs47l35.ko \
    snd-soc-madera.ko:cirrus_madera.ko \
    snd-soc-wm-adsp.ko:cirrus_wm_adsp.ko \
    irq-madera.ko:cirrus_irq-madera.ko

# Partitions
BOARD_DTBOIMG_PARTITION_SIZE := 2097152

# Properties
TARGET_PRODUCT_PROP += $(DEVICE_PATH)/product.prop
TARGET_VENDOR_PROP += $(DEVICE_PATH)/vendor.prop

# Copy to recovery
BOARD_RECOVERY_RAMDISK_KERNEL_MODULES_LOAD := \
    utags \
    mmi_annotate \
    mmi_info \
    tzlog_dump \
    mmi_sys_temp \
    qpnp-power-on-mmi \
    qpnp-smbcharger-mmi \
    slg5bm43670 \
    exfat \
    sensors_class \
    sx933x_sar \
    mmi_relay \
    touchscreen_mmi \
    goodix_v1430_mmi \
    goodix_v1430_update_mmi \
    goodix_v1430_ts_tools_mmi \
    goodix_fod_mmi \
    sec_mmi \
    synaptics_i2c \
    synaptics_core_module \
    synaptics_device \
    synaptics_diagnostics \
    synaptics_recovery \
    synaptics_reflash \
    synaptics_testing

RECOVERY_KERNEL_MODULES := $(addsuffix .ko,$(BOARD_RECOVERY_RAMDISK_KERNEL_MODULES_LOAD))

# Security
VENDOR_SECURITY_PATCH := 2022-08-01

# ODM
ODM_MANIFEST_SKUS := \
    dn \
    n

ODM_MANIFEST_DN_FILES := $(DEVICE_PATH)/odm/manifest_dn.xml
ODM_MANIFEST_N_FILES := $(DEVICE_PATH)/odm/manifest_n.xml

# SELinux
BOARD_VENDOR_SEPOLICY_DIRS += $(DEVICE_PATH)/sepolicy/vendor

# Inherit the proprietary files
include vendor/motorola/racer/BoardConfigVendor.mk
