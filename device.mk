#
# Copyright (C) 2017-2020 The LineageOS Project
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

$(call inherit-product, device/motorola/sm7250-common/common.mk)

# Get non-open-source specific aspects
$(call inherit-product, vendor/motorola/racer/racer-vendor.mk)

# Properties
-include $(LOCAL_PATH)/properties.mk

# Overlays
DEVICE_PACKAGE_OVERLAYS += \
    $(LOCAL_PATH)/overlay \
    $(LOCAL_PATH)/overlay-lineage

PRODUCT_ENFORCE_RRO_EXCLUDED_OVERLAYS += \
    $(LOCAL_PATH)/overlay-lineage/lineage-sdk

PRODUCT_PACKAGES += \
    AvoidAppsInCutoutOverlay \
    LatinIMEResRacer \
    NoCutoutOverlay \
    SettingsResRacer

# Audio

PRODUCT_COPY_FILES += \
    frameworks/av/services/audiopolicy/config/bluetooth_audio_policy_configuration.xml:$(TARGET_COPY_OUT_VENDOR)/etc/bluetooth_audio_policy_configuration.xml \
    frameworks/av/services/audiopolicy/config/usb_audio_policy_configuration.xml:$(TARGET_COPY_OUT_VENDOR)/etc/usb_audio_policy_configuration.xml

PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/audio/audio_effects.xml:$(TARGET_COPY_OUT_VENDOR)/etc/audio_effects.xml \
    $(LOCAL_PATH)/audio/audio_ext_spkr.conf:$(TARGET_COPY_OUT_VENDOR)/etc/audio_ext_spkr.conf \
    $(LOCAL_PATH)/audio/mixer_paths_madera_evt.xml:$(TARGET_COPY_OUT_VENDOR)/etc/mixer_paths_madera_evt.xml \
    $(LOCAL_PATH)/audio/mixer_paths.xml:$(TARGET_COPY_OUT_VENDOR)/etc/mixer_paths.xml \
    $(LOCAL_PATH)/audio/audio_platform_info.xml:$(TARGET_COPY_OUT_VENDOR)/etc/audio_platform_info.xml \
    $(LOCAL_PATH)/audio/audio_policy_configuration.xml:$(TARGET_COPY_OUT_VENDOR)/etc/audio_policy_configuration.xml \
    $(LOCAL_PATH)/audio/audio_policy_volumes.xml:$(TARGET_COPY_OUT_VENDOR)/etc/audio_policy_volumes.xml \
    $(LOCAL_PATH)/audio/default_volume_tables.xml:$(TARGET_COPY_OUT_VENDOR)/etc/default_volume_tables.xml

# Fingerprint
PRODUCT_PACKAGES += \
    android.hardware.biometrics.fingerprint@2.3-service.racer

# FM
PRODUCT_PACKAGES += \
    FM2 \
    libqcomfm_jni \
    init.qti.fm.sh \
    qcom.fmradio

PRODUCT_BOOT_JARS += qcom.fmradio

# Init
PRODUCT_PACKAGES += \
    init.mmi.laser.sh \
    init.mmi.overlay.rc \
    init.recovery.lkm.rc

# NFC
PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/nfc/libnfc-hal-st.conf:$(TARGET_COPY_OUT_VENDOR)/etc/libnfc-hal-st.conf \
    $(LOCAL_PATH)/nfc/libnfc-nci-st.conf:$(TARGET_COPY_OUT_VENDOR)/etc/libnfc-nci.conf \
    $(LOCAL_PATH)/nfc/st21nfc_conf_ds.txt:$(TARGET_COPY_OUT_VENDOR)/etc/st21nfc_conf_ds.txt \
    $(LOCAL_PATH)/nfc/st21nfc_conf_ss.txt:$(TARGET_COPY_OUT_VENDOR)/etc/st21nfc_conf_ss.txt

# Sensors
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
