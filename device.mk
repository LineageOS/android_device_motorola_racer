#
# SPDX-FileCopyrightText: The LineageOS Project
# SPDX-License-Identifier: Apache-2.0
#

# Inherit from sm7250-common
$(call inherit-product, device/motorola/sm7250-common/common.mk)

# Overlays
DEVICE_PACKAGE_OVERLAYS += \
    $(LOCAL_PATH)/overlay \
    $(LOCAL_PATH)/overlay-lineage

PRODUCT_PACKAGES += \
    LatinIMEResRacer

PRODUCT_PACKAGES += \
    AvoidAppsInCutoutOverlay \
    NoCutoutOverlay

# Audio
PRODUCT_PACKAGES += \
    audio.primary.lito \
    libqcompostprocbundle

PRODUCT_COPY_FILES += \
    frameworks/av/services/audiopolicy/config/bluetooth_audio_policy_configuration.xml:$(TARGET_COPY_OUT_VENDOR)/etc/bluetooth_audio_policy_configuration.xml \
    frameworks/av/services/audiopolicy/config/usb_audio_policy_configuration.xml:$(TARGET_COPY_OUT_VENDOR)/etc/usb_audio_policy_configuration.xml

PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/audio/audio_effects.xml:$(TARGET_COPY_OUT_VENDOR)/etc/audio_effects.xml \
    $(LOCAL_PATH)/audio/mixer_paths_madera_evt.xml:$(TARGET_COPY_OUT_VENDOR)/etc/mixer_paths_madera_evt.xml \
    $(LOCAL_PATH)/audio/mixer_paths.xml:$(TARGET_COPY_OUT_VENDOR)/etc/mixer_paths.xml \
    $(LOCAL_PATH)/audio/audio_platform_info.xml:$(TARGET_COPY_OUT_VENDOR)/etc/audio_platform_info.xml \
    $(LOCAL_PATH)/audio/audio_policy_configuration.xml:$(TARGET_COPY_OUT_VENDOR)/etc/audio_policy_configuration.xml \
    $(LOCAL_PATH)/audio/audio_policy_volumes.xml:$(TARGET_COPY_OUT_VENDOR)/etc/audio_policy_volumes.xml \
    $(LOCAL_PATH)/audio/default_volume_tables.xml:$(TARGET_COPY_OUT_VENDOR)/etc/default_volume_tables.xml

# Fingerprint
PRODUCT_PACKAGES += \
    android.hardware.biometrics.fingerprint@2.3-service.racer

$(call soong_config_set,surfaceflinger,udfps_lib,//$(LOCAL_PATH):libudfps_extension.racer)

# FM
PRODUCT_PACKAGES += \
    FM2

# Init
PRODUCT_PACKAGES += \
    init.mmi.laser.sh \
    init.mmi.overlay.rc \
    init.qti.chg_policy.sh

# NFC
PRODUCT_PACKAGES += \
    android.hardware.nfc-service.st

# Power
PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/configs/powerhint.json:$(TARGET_COPY_OUT_VENDOR)/etc/powerhint.json

# Sensors
PRODUCT_PACKAGES += \
    sensors.moto_ext

PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/configs/sensors/tcs3708.json:$(TARGET_COPY_OUT_VENDOR)/etc/sensors/tcs3708.json \
    $(LOCAL_PATH)/configs/sensors/tcs3708_boe_always.json:$(TARGET_COPY_OUT_VENDOR)/etc/sensors/tcs3708_boe_always.json \
    $(LOCAL_PATH)/configs/sensors/tcs3708_boeB4_always.json:$(TARGET_COPY_OUT_VENDOR)/etc/sensors/tcs3708_boeB4_always.json \
    $(LOCAL_PATH)/configs/sensors/tcs3708_csot_always.json:$(TARGET_COPY_OUT_VENDOR)/etc/sensors/tcs3708_csot_always.json \
    $(LOCAL_PATH)/configs/sensors/tcs3708_csotB5_always.json:$(TARGET_COPY_OUT_VENDOR)/etc/sensors/tcs3708_csotB5_always.json \
    $(LOCAL_PATH)/configs/sensors/tcs3708_tianma_always.json:$(TARGET_COPY_OUT_VENDOR)/etc/sensors/tcs3708_tianma_always.json

# Soong namespaces
PRODUCT_SOONG_NAMESPACES += \
    $(LOCAL_PATH)

# Inherit the proprietary files
$(call inherit-product, vendor/motorola/racer/racer-vendor.mk)
