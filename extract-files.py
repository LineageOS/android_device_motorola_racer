#!/usr/bin/env -S PYTHONPATH=../../../tools/extract-utils python3
#
# SPDX-FileCopyrightText: 2024 The LineageOS Project
# SPDX-License-Identifier: Apache-2.0
#

from extract_utils.fixups_blob import (
    blob_fixup,
    blob_fixups_user_type,
)
from extract_utils.fixups_lib import (
    lib_fixups,
)
from extract_utils.main import (
    ExtractUtils,
    ExtractUtilsModule,
)

namespace_imports = [
    'device/motorola/racer',
    'hardware/motorola',
    'vendor/motorola/sm7250-common',
    'vendor/qcom/opensource/display',
]

blob_fixups: blob_fixups_user_type = {
    ('vendor/lib64/hw/com.qti.chi.override.so', 'vendor/lib64/hw/camera.qcom.so', 'vendor/lib64/com.qti.feature2.gs.so'): blob_fixup()
        .binary_regex_replace(b'camera.mot.is.coming.cts', b'vendor.camera.coming.cts'),
    'vendor/lib64/libgf_hal.so': blob_fixup()
        .replace_needed('vendor.goodix.hardware.biometrics.fingerprint@2.1_vendor.so', 'vendor.goodix.hardware.biometrics.fingerprint@2.1.so'),
    'vendor/lib64/libvidhance.so': blob_fixup()
        .add_needed('libcomparetf2_shim.so'),
    'vendor/lib64/sensors.moto.so': blob_fixup()
        .add_needed('libbase_shim.so'),
    'vendor/lib64/vendor.qti.hardware.camera.postproc@1.0-service-impl.so': blob_fixup()
        .sig_replace('8A 0A 00 94', '1F 20 03 D5'),
}  # fmt: skip

module = ExtractUtilsModule(
    'racer',
    'motorola',
    namespace_imports=namespace_imports,
    blob_fixups=blob_fixups,
    lib_fixups=lib_fixups,
    add_firmware_proprietary_file=False,
)

if __name__ == '__main__':
    utils = ExtractUtils.device_with_common(
        module, 'sm7250-common', module.vendor
    )
    utils.run()
