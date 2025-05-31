#
# SPDX-FileCopyrightText: The LineageOS Project
# SPDX-License-Identifier: Apache-2.0
#

# Inherit from those products. Most specific first.
$(call inherit-product, $(SRC_TARGET_DIR)/product/core_64_bit.mk)
TARGET_SUPPORTS_OMX_SERVICE := false
$(call inherit-product, $(SRC_TARGET_DIR)/product/full_base_telephony.mk)

# Inherit from racer device
$(call inherit-product, device/motorola/racer/device.mk)

# Inherit some common Lineage stuff.
$(call inherit-product, vendor/lineage/config/common_full_phone.mk)

# Device identifier. This must come after all inclusions.
PRODUCT_NAME := lineage_racer
PRODUCT_DEVICE := racer
PRODUCT_BRAND := motorola
PRODUCT_MODEL := motorola edge
PRODUCT_MANUFACTURER := motorola
PRODUCT_SYSTEM_NAME := racer_retail

PRODUCT_AAPT_CONFIG := xxxhdpi
PRODUCT_AAPT_PREF_CONFIG := xxxhdpi

# Boot animation
TARGET_SCREEN_HEIGHT := 2340
TARGET_SCREEN_WIDTH := 1080

PRODUCT_GMS_CLIENTID_BASE := android-motorola

# Build info
PRODUCT_BUILD_PROP_OVERRIDES += \
    BuildDesc="racer_retail-user 11 RPDS31.Q4U-39-26-14-13 17601e release-keys" \
    BuildFingerprint=motorola/racer_retail/racer:11/RPDS31.Q4U-39-26-14-13/17601e:user/release-keys \
    DeviceProduct=$(PRODUCT_SYSTEM_NAME)
