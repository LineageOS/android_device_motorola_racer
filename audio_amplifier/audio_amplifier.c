/*
 * SPDX-FileCopyrightText: The LineageOS Project
 * SPDX-License-Identifier: Apache-2.0
 */

/*
 * Load the factory speaker calibration into the CS35L41 CSPL firmware,
 * like the stock audio HAL does in audio_extn_cspl_sp_init().
 */

#define LOG_TAG "audio_amplifier"
//#define LOG_NDEBUG 0

#include <endian.h>
#include <errno.h>
#include <hardware/audio_amplifier.h>
#include <hardware/hardware.h>
#include <log/log.h>
#include <pthread.h>
#include <stdbool.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <tinyalsa/asoundlib.h>
#include <unistd.h>

#define UNUSED __attribute__((unused))

#define SND_CARD 0
#define CSPL_RETRIES 100
#define CSPL_RETRY_DELAY_US 100000

#define CAL_STATUS_CALIBRATED 1

typedef struct cspl_amp {
    const char* prefix;
    const char* cal_r_path;
    const char* ambient_path;
    uint32_t cal_r;
    uint32_t ambient;
    bool calibrated;
    bool pending;
} cspl_amp_t;

/* Amps that aren't fitted on a device simply have no controls */
static cspl_amp_t cspl_amps[] = {
        {
                .prefix = "SPK",
                .cal_r_path = "/mnt/vendor/persist/factory/audio/spk_cal_r",
                .ambient_path = "/mnt/vendor/persist/factory/audio/spk_ambient",
        },
        {
                .prefix = "RCV",
                .cal_r_path = "/mnt/vendor/persist/factory/audio/rcv_cal_r",
                .ambient_path = "/mnt/vendor/persist/factory/audio/rcv_ambient",
        },
};

#define NUM_CSPL_AMPS (sizeof(cspl_amps) / sizeof(cspl_amps[0]))

static bool read_cal_value(const char* path, uint32_t* value) {
    FILE* f = fopen(path, "r");
    bool ret;

    if (!f) return false;

    ret = fscanf(f, "%u", value) == 1;
    if (!ret) ALOGE("%s: Failed to parse %s", __func__, path);

    fclose(f);
    return ret;
}

static void cspl_ctl_name(char* name, size_t len, const cspl_amp_t* amp, const char* ctl) {
    snprintf(name, len, "%s DSP1X protection cd %s", amp->prefix, ctl);
}

/* CSPL controls are 4 byte big endian words */
static bool set_cspl_ctl(struct mixer* mixer, const cspl_amp_t* amp, const char* ctl,
                         uint32_t value) {
    char name[64];
    struct mixer_ctl* mixer_ctl;
    uint32_t data = htobe32(value);

    cspl_ctl_name(name, sizeof(name), amp, ctl);
    mixer_ctl = mixer_get_ctl_by_name(mixer, name);
    if (!mixer_ctl || mixer_ctl_set_array(mixer_ctl, &data, sizeof(data))) {
        ALOGE("%s: Failed to set %s", __func__, name);
        return false;
    }
    return true;
}

static bool get_cspl_ctl(struct mixer* mixer, const cspl_amp_t* amp, const char* ctl,
                         uint32_t* value) {
    char name[64];
    struct mixer_ctl* mixer_ctl;
    uint32_t data;

    cspl_ctl_name(name, sizeof(name), amp, ctl);
    mixer_ctl = mixer_get_ctl_by_name(mixer, name);
    if (!mixer_ctl || mixer_ctl_get_array(mixer_ctl, &data, sizeof(data))) return false;

    *value = be32toh(data);
    return true;
}

static struct mixer_ctl* get_amp_ctl(struct mixer* mixer, const cspl_amp_t* amp,
                                     const char* ctl) {
    char name[64];

    snprintf(name, sizeof(name), "%s %s", amp->prefix, ctl);
    return mixer_get_ctl_by_name(mixer, name);
}

static bool set_amp_ctl(struct mixer* mixer, const cspl_amp_t* amp, const char* ctl, int value) {
    struct mixer_ctl* mixer_ctl = get_amp_ctl(mixer, amp, ctl);

    if (!mixer_ctl || mixer_ctl_set_value(mixer_ctl, 0, value)) {
        ALOGE("%s: Failed to set %s %s", __func__, amp->prefix, ctl);
        return false;
    }
    return true;
}

static bool has_cspl_ctls(struct mixer* mixer, const cspl_amp_t* amp) {
    char name[64];

    cspl_ctl_name(name, sizeof(name), amp, "CAL_R");
    return mixer_get_ctl_by_name(mixer, name) != NULL;
}

static bool cal_applied(struct mixer* mixer, const cspl_amp_t* amp) {
    uint32_t selected;

    return get_cspl_ctl(mixer, amp, "CAL_R_SELECTED", &selected) && selected == amp->cal_r;
}

static bool dsp_booted(struct mixer* mixer, const cspl_amp_t* amp) {
    struct mixer_ctl* mixer_ctl = get_amp_ctl(mixer, amp, "DSP Booted");

    return mixer_ctl && mixer_ctl_get_value(mixer_ctl, 0) > 0;
}

/* The CSPL controls show up once the amp firmware has been loaded */
static struct mixer* wait_for_cspl_mixer(void) {
    for (int i = 0; i < CSPL_RETRIES; i++) {
        struct mixer* mixer = mixer_open(SND_CARD);

        if (mixer) {
            for (size_t j = 0; j < NUM_CSPL_AMPS; j++) {
                if (cspl_amps[j].calibrated && has_cspl_ctls(mixer, &cspl_amps[j])) return mixer;
            }
            mixer_close(mixer);
        }
        usleep(CSPL_RETRY_DELAY_US);
    }
    return NULL;
}

static bool write_cal(struct mixer* mixer, const cspl_amp_t* amp) {
    if (!set_cspl_ctl(mixer, amp, "CAL_R", amp->cal_r) ||
        !set_cspl_ctl(mixer, amp, "CAL_AMBIENT", amp->ambient) ||
        !set_cspl_ctl(mixer, amp, "CAL_STATUS", CAL_STATUS_CALIBRATED) ||
        !set_cspl_ctl(mixer, amp, "CAL_CHECKSUM", amp->cal_r + CAL_STATUS_CALIBRATED)) {
        return false;
    }

    /* CSPL only reads the calibration on DSP boot, wm_adsp restores the values set above */
    return set_amp_ctl(mixer, amp, "DSP Booted", 0) &&
           set_amp_ctl(mixer, amp, "DSP1 Preload Switch", 0) &&
           set_amp_ctl(mixer, amp, "DSP1 Preload Switch", 1);
}

static void* cspl_calibrate_thread(UNUSED void* arg) {
    struct mixer* mixer;
    size_t pending = 0;

    mixer = wait_for_cspl_mixer();
    if (!mixer) {
        ALOGE("%s: CSPL controls not found", __func__);
        return NULL;
    }

    for (size_t i = 0; i < NUM_CSPL_AMPS; i++) {
        cspl_amp_t* amp = &cspl_amps[i];

        if (!amp->calibrated) continue;

        if (!has_cspl_ctls(mixer, amp)) {
            ALOGI("%s: %s: no CSPL controls, skipping", __func__, amp->prefix);
        } else if (cal_applied(mixer, amp)) {
            ALOGI("%s: %s: calibration already applied (ReDC %u)", __func__, amp->prefix,
                  amp->cal_r);
        } else if (write_cal(mixer, amp)) {
            amp->pending = true;
            pending++;
        }
    }
    mixer_close(mixer);

    /* The controls get re-registered on DSP boot, so reopen the mixer on every check */
    for (int i = 0; i < CSPL_RETRIES && pending; i++) {
        usleep(CSPL_RETRY_DELAY_US);
        mixer = mixer_open(SND_CARD);
        if (!mixer) continue;

        for (size_t j = 0; j < NUM_CSPL_AMPS; j++) {
            cspl_amp_t* amp = &cspl_amps[j];

            if (!amp->pending || !dsp_booted(mixer, amp) || !cal_applied(mixer, amp)) continue;

            ALOGI("%s: %s: applied speaker calibration: ReDC %u, ambient %u", __func__,
                  amp->prefix, amp->cal_r, amp->ambient);
            amp->pending = false;
            pending--;
        }
        mixer_close(mixer);
    }

    mixer = mixer_open(SND_CARD);
    for (size_t i = 0; i < NUM_CSPL_AMPS; i++) {
        cspl_amp_t* amp = &cspl_amps[i];

        if (!amp->pending) continue;

        /* The DSP may only start running with the next playback, wm_adsp applies the values then */
        if (mixer && !dsp_booted(mixer, amp)) {
            ALOGI("%s: %s: calibration queued for next DSP boot (ReDC %u)", __func__, amp->prefix,
                  amp->cal_r);
        } else {
            ALOGE("%s: %s: CSPL did not accept calibration (ReDC %u)", __func__, amp->prefix,
                  amp->cal_r);
        }
    }
    if (mixer) mixer_close(mixer);

    return NULL;
}

static int amp_calibrate(UNUSED amplifier_device_t* device, UNUSED void* adev) {
    bool calibrated = false;
    pthread_attr_t attr;
    pthread_t thread;
    int rc;

    for (size_t i = 0; i < NUM_CSPL_AMPS; i++) {
        cspl_amp_t* amp = &cspl_amps[i];

        amp->calibrated = read_cal_value(amp->cal_r_path, &amp->cal_r) &&
                          read_cal_value(amp->ambient_path, &amp->ambient);
        calibrated |= amp->calibrated;
    }
    if (!calibrated) {
        ALOGI("%s: Speakers not calibrated, keeping firmware defaults", __func__);
        return 0;
    }

    /* The amp firmware may still be loading, don't hold up the audio HAL */
    pthread_attr_init(&attr);
    pthread_attr_setdetachstate(&attr, PTHREAD_CREATE_DETACHED);
    rc = pthread_create(&thread, &attr, cspl_calibrate_thread, NULL);
    pthread_attr_destroy(&attr);
    if (rc) {
        ALOGE("%s: Failed to create calibration thread: %s", __func__, strerror(rc));
        return -rc;
    }

    return 0;
}

static int amp_dev_close(hw_device_t* device) {
    free(device);

    return 0;
}

static int amp_module_open(const hw_module_t* module, const char* name, hw_device_t** device) {
    amplifier_device_t* amp_dev;

    if (strcmp(name, AMPLIFIER_HARDWARE_INTERFACE)) {
        ALOGE("%s: %s does not match amplifier hardware interface name", __func__, name);
        return -ENODEV;
    }

    amp_dev = calloc(1, sizeof(amplifier_device_t));
    if (!amp_dev) {
        ALOGE("%s: Unable to allocate memory for amplifier device", __func__);
        return -ENOMEM;
    }

    amp_dev->common.tag = HARDWARE_DEVICE_TAG;
    amp_dev->common.module = (hw_module_t*)module;
    amp_dev->common.version = HARDWARE_DEVICE_API_VERSION(1, 0);
    amp_dev->common.close = amp_dev_close;

    amp_dev->calibrate = amp_calibrate;

    *device = (hw_device_t*)amp_dev;

    return 0;
}

static struct hw_module_methods_t hal_module_methods = {
        .open = amp_module_open,
};

/* clang-format off */
amplifier_module_t HAL_MODULE_INFO_SYM = {
    .common = {
        .tag = HARDWARE_MODULE_TAG,
        .module_api_version = AMPLIFIER_MODULE_API_VERSION_0_1,
        .hal_api_version = HARDWARE_HAL_API_VERSION,
        .id = AMPLIFIER_HARDWARE_MODULE_ID,
        .name = "CS35L41 audio amplifier HAL",
        .author = "The LineageOS Project",
        .methods = &hal_module_methods,
    },
};
/* clang-format on */
