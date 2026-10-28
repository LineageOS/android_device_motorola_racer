/*
 * SPDX-FileCopyrightText: The LineageOS Project
 * SPDX-License-Identifier: Apache-2.0
 */

/*
 * Load the factory speaker calibration into the CS35L41 CSPL firmware,
 * like the stock audio HAL does in audio_extn_cspl_sp_init().
 */

#include <android-base/file.h>
#include <android-base/logging.h>
#include <android-base/parseint.h>
#include <android-base/strings.h>
#include <endian.h>
#include <tinyalsa/asoundlib.h>

#include <chrono>
#include <cstdint>
#include <string>
#include <thread>
#include <vector>

using namespace std::chrono_literals;

namespace {

constexpr unsigned int kCard = 0;
constexpr int kRetries = 100;
constexpr auto kRetryDelay = 100ms;

constexpr uint32_t kCalStatusCalibrated = 1;

struct Amp {
    std::string prefix;
    std::string cal_r_path;
    std::string ambient_path;
    uint32_t cal_r = 0;
    uint32_t ambient = 0;

    std::string Ctl(const std::string& name) const {
        return prefix + " DSP1X protection cd " + name;
    }
};

// Amps that aren't fitted on a device simply have no controls
const std::vector<Amp> kAmps = {
        {"SPK", "/mnt/vendor/persist/factory/audio/spk_cal_r",
         "/mnt/vendor/persist/factory/audio/spk_ambient"},
        {"RCV", "/mnt/vendor/persist/factory/audio/rcv_cal_r",
         "/mnt/vendor/persist/factory/audio/rcv_ambient"},
};

bool ReadCalValue(const std::string& path, uint32_t* value) {
    std::string buf;
    if (!android::base::ReadFileToString(path, &buf)) {
        return false;
    }
    if (!android::base::ParseUint(android::base::Trim(buf), value)) {
        LOG(ERROR) << "Failed to parse " << path << ": " << buf;
        return false;
    }
    return true;
}

// CSPL controls are 4 byte big endian words
bool SetCsplCtl(struct mixer* mixer, const std::string& name, uint32_t value) {
    struct mixer_ctl* ctl = mixer_get_ctl_by_name(mixer, name.c_str());
    uint32_t data = htobe32(value);
    if (!ctl || mixer_ctl_set_array(ctl, &data, sizeof(data))) {
        LOG(ERROR) << "Failed to set " << name;
        return false;
    }
    return true;
}

bool GetCsplCtl(struct mixer* mixer, const std::string& name, uint32_t* value) {
    struct mixer_ctl* ctl = mixer_get_ctl_by_name(mixer, name.c_str());
    uint32_t data;
    if (!ctl || mixer_ctl_get_array(ctl, &data, sizeof(data))) {
        return false;
    }
    *value = be32toh(data);
    return true;
}

bool SetCtl(struct mixer* mixer, const std::string& name, int value) {
    struct mixer_ctl* ctl = mixer_get_ctl_by_name(mixer, name.c_str());
    if (!ctl || mixer_ctl_set_value(ctl, 0, value)) {
        LOG(ERROR) << "Failed to set " << name;
        return false;
    }
    return true;
}

bool HasCsplCtls(struct mixer* mixer, const Amp& amp) {
    return mixer_get_ctl_by_name(mixer, amp.Ctl("CAL_R").c_str()) != nullptr;
}

bool CalApplied(struct mixer* mixer, const Amp& amp) {
    uint32_t selected;
    return GetCsplCtl(mixer, amp.Ctl("CAL_R_SELECTED"), &selected) && selected == amp.cal_r;
}

bool DspBooted(struct mixer* mixer, const Amp& amp) {
    struct mixer_ctl* ctl = mixer_get_ctl_by_name(mixer, (amp.prefix + " DSP Booted").c_str());
    return ctl && mixer_ctl_get_value(ctl, 0) > 0;
}

// The CSPL controls show up once the amp firmware has been loaded
struct mixer* WaitForCsplMixer(const std::vector<Amp>& amps) {
    for (int i = 0; i < kRetries; i++) {
        struct mixer* mixer = mixer_open(kCard);
        if (mixer) {
            for (const Amp& amp : amps) {
                if (HasCsplCtls(mixer, amp)) return mixer;
            }
            mixer_close(mixer);
        }
        std::this_thread::sleep_for(kRetryDelay);
    }
    return nullptr;
}

bool WriteCal(struct mixer* mixer, const Amp& amp) {
    if (!SetCsplCtl(mixer, amp.Ctl("CAL_R"), amp.cal_r) ||
        !SetCsplCtl(mixer, amp.Ctl("CAL_AMBIENT"), amp.ambient) ||
        !SetCsplCtl(mixer, amp.Ctl("CAL_STATUS"), kCalStatusCalibrated) ||
        !SetCsplCtl(mixer, amp.Ctl("CAL_CHECKSUM"), amp.cal_r + kCalStatusCalibrated)) {
        return false;
    }

    // CSPL only reads the calibration on DSP boot, wm_adsp restores the values set above
    return SetCtl(mixer, amp.prefix + " DSP Booted", 0) &&
           SetCtl(mixer, amp.prefix + " DSP1 Preload Switch", 0) &&
           SetCtl(mixer, amp.prefix + " DSP1 Preload Switch", 1);
}

}  // anonymous namespace

int main(int /* argc */, char** argv) {
    android::base::InitLogging(argv, android::base::LogdLogger(android::base::MAIN));

    std::vector<Amp> amps;
    for (Amp amp : kAmps) {
        if (ReadCalValue(amp.cal_r_path, &amp.cal_r) &&
            ReadCalValue(amp.ambient_path, &amp.ambient)) {
            amps.push_back(amp);
        }
    }
    if (amps.empty()) {
        LOG(INFO) << "Speakers not calibrated, keeping firmware defaults";
        return 0;
    }

    struct mixer* mixer = WaitForCsplMixer(amps);
    if (!mixer) {
        LOG(ERROR) << "CSPL controls not found";
        return 1;
    }

    std::vector<Amp> pending;
    bool failed = false;
    for (const Amp& amp : amps) {
        if (!HasCsplCtls(mixer, amp)) {
            LOG(INFO) << amp.prefix << ": no CSPL controls, skipping";
        } else if (CalApplied(mixer, amp)) {
            LOG(INFO) << amp.prefix << ": calibration already applied (ReDC " << amp.cal_r << ")";
        } else if (WriteCal(mixer, amp)) {
            pending.push_back(amp);
        } else {
            failed = true;
        }
    }
    mixer_close(mixer);

    // The controls get re-registered on DSP boot, so reopen the mixer on every check
    for (int i = 0; i < kRetries && !pending.empty(); i++) {
        std::this_thread::sleep_for(kRetryDelay);
        mixer = mixer_open(kCard);
        if (!mixer) continue;
        std::erase_if(pending, [&](const Amp& amp) {
            if (!DspBooted(mixer, amp) || !CalApplied(mixer, amp)) return false;
            LOG(INFO) << amp.prefix << ": applied speaker calibration: ReDC " << amp.cal_r
                      << ", ambient " << amp.ambient;
            return true;
        });
        mixer_close(mixer);
    }

    mixer = mixer_open(kCard);
    for (const Amp& amp : pending) {
        // The DSP may only start running with the next playback, wm_adsp applies the values then
        if (mixer && !DspBooted(mixer, amp)) {
            LOG(INFO) << amp.prefix << ": calibration queued for next DSP boot (ReDC "
                      << amp.cal_r << ")";
        } else {
            LOG(ERROR) << amp.prefix << ": CSPL did not accept calibration (ReDC " << amp.cal_r
                       << ")";
            failed = true;
        }
    }
    if (mixer) mixer_close(mixer);

    return failed ? 1 : 0;
}
