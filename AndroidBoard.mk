#
# Copyright (C) 2017-2021 The LineageOS Project
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

INSTALLED_KERNEL_TARGET := $(PRODUCT_OUT)/kernel
recovery_uncompressed_ramdisk := $(PRODUCT_OUT)/ramdisk-recovery.cpio

RECOVERY_KMOD_TARGETS := \
    utags.ko \
    mmi_annotate.ko \
    mmi_info.ko \
    tzlog_dump.ko \
    mmi_sys_temp.ko \
    qpnp-power-on-mmi.ko \
    qpnp-smbcharger-mmi.ko \
    slg5bm43670.ko \
    aw8695.ko \
    exfat.ko \
    sensors_class.ko \
    sx933x_sar.ko \
    mmi_relay.ko \
    touchscreen_mmi.ko \
    goodix_v1430_mmi.ko \
    goodix_v1430_update_mmi.ko \
    goodix_v1430_ts_tools_mmi.ko \
    goodix_fod_mmi.ko sec_mmi.ko \
    synaptics_i2c.ko \
    synaptics_core_module.ko \
    synaptics_device.ko \
    synaptics_diagnostics.ko \
    synaptics_recovery.ko \
    synaptics_reflash.ko \
    synaptics_testing.ko \
    mmi_sigprint.ko

INSTALLED_RECOVERY_KMOD_TARGETS := $(RECOVERY_KMOD_TARGETS:%=$(TARGET_RECOVERY_ROOT_OUT)/vendor/lib/modules/%)
$(INSTALLED_RECOVERY_KMOD_TARGETS): $(INSTALLED_KERNEL_TARGET)
	echo -e ${CL_GRN}"Copying kernel modules to recovery"${CL_RST}
	@mkdir -p $(dir $@)
	cp $(@F:%=$(TARGET_OUT_VENDOR)/lib/modules/%) $(TARGET_RECOVERY_ROOT_OUT)/vendor/lib/modules/

RECOVERY_FIRMWARE_TARGETS := \
    aw8695_haptic.bin \
    aw8695_rtp.bin \
    samsung-boe-se77c-20033021-17110105-racer.bin \
    samsung-boe-se77c-20033021-17110305-racer-pvt.bin \
    samsung-csot-se77c-20042009-17120108-racer.bin \
    samsung-csot-se77c-20042009-17120308-racer-pvt.bin \
    synaptics-tianma-s3908-20052606-313204-racer.tdat

INSTALLED_RECOVERY_FIRMWARE_TARGETS := $(RECOVERY_FIRMWARE_TARGETS:%=$(TARGET_RECOVERY_ROOT_OUT)/vendor/firmware/%)
$(INSTALLED_RECOVERY_FIRMWARE_TARGETS): $(INSTALLED_KERNEL_TARGET)
	echo -e ${CL_GRN}"Copying firmware to recovery"${CL_RST}
	@mkdir -p $(dir $@)
	cp $(@F:%=$(TARGET_OUT_VENDOR)/firmware/%) $(TARGET_RECOVERY_ROOT_OUT)/vendor/firmware/

$(recovery_uncompressed_ramdisk): $(INSTALLED_RECOVERY_KMOD_TARGETS) $(INSTALLED_RECOVERY_FIRMWARE_TARGETS)
