#!/bin/bash
#
# Copyright (C) 2016 The CyanogenMod Project
# Copyright (C) 2017-2020 The LineageOS Project
#
# SPDX-License-Identifier: Apache-2.0
#

function blob_fixup() {
    case "${1}" in
    # Patch configureRpcThreadpool
    vendor/lib64/vendor.qti.hardware.camera.postproc@1.0-service-impl.so)
        hexdump -ve '1/1 "%.2X"' "${2}" | sed "s/8A0A0094/1F2003D5/g" | xxd -r -p > "${EXTRACT_TMP_DIR}/${1##*/}"
        mv "${EXTRACT_TMP_DIR}/${1##*/}" "${2}"
        ;;
    # memset shim
    vendor/bin/charge_only_mode)
        "${PATCHELF}" --add-needed libmemset_shim.so "${2}"
        ;;
    # rename moto modified tinyalsa
    vendor/lib/libtinyalsa-moto.so | vendor/lib64/libtinyalsa-moto.so)
        "${PATCHELF}" --set-soname libtinyalsa-moto.so "${2}"
        ;;
    # rename moto modified tinyalsa
    vendor/lib/motorola.hardware.audio.adspd@1.0-impl.so | vendor/lib64/motorola.hardware.audio.adspd@1.0-impl.so)
        "${PATCHELF}" --replace-needed libtinyalsa.so libtinyalsa-moto.so "${2}"
        ;;
    # __lttf2 shim
    vendor/lib64/libvidhance.so)
        "${PATCHELF}" --print-needed "${2}" |grep -q libcomparetf2_shim || "${PATCHELF}" --add-needed libcomparetf2_shim.so "${2}"
        ;;
    esac
}

# If we're being sourced by the common script that we called,
# stop right here. No need to go down the rabbit hole.
if [ "${BASH_SOURCE[0]}" != "${0}" ]; then
    return
fi

set -e

export DEVICE=racer
export DEVICE_COMMON=sm7250-common
export VENDOR=motorola
export VENDOR_COMMON=${VENDOR}

"./../../${VENDOR_COMMON}/${DEVICE_COMMON}/extract-files.sh" "$@"
