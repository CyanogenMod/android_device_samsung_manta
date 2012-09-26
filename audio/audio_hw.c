/*
 * Copyright (C) 2012 The Android Open Source Project
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#define LOG_TAG "audio_hw_primary"
/*#define LOG_NDEBUG 0*/

#include <errno.h>
#include <pthread.h>
#include <stdint.h>
#include <stdlib.h>
#include <sys/time.h>
#include <fcntl.h>

#include <cutils/log.h>
#include <cutils/properties.h>
#include <cutils/str_parms.h>

#include <hardware/audio.h>
#include <hardware/hardware.h>

#include <system/audio.h>

#include <tinyalsa/asoundlib.h>

#include <audio_utils/resampler.h>

#include "audio_route.h"

#define PCM_CARD 0
#define PCM_CARD_SPDIF 1
#define PCM_TOTAL 2

#define PCM_DEVICE 0
#define PCM_DEVICE_DEEP 1
#define PCM_DEVICE_VOICE 2
#define PCM_DEVICE_SCO 3

/* duration in ms of volume ramp applied when starting capture to remove plop */
#define CAPTURE_START_RAMP_MS 100

#define ES305_SYSFS_PATH "/sys/class/i2c-dev/i2c-4/device/4-003e/"
#define ES305_PRESET_PATH ES305_SYSFS_PATH "preset"
#define ES305_VOICE_PROCESSING_PATH ES305_SYSFS_PATH "voice_processing"

#define ES305_ON "1"
#define ES305_OFF "0"

struct pcm_config pcm_config = {
    .channels = 2,
    .rate = 44100,
    .period_size = 256,
    .period_count = 2,
    .format = PCM_FORMAT_S16_LE,
};

struct pcm_config pcm_config_sco = {
    .channels = 1,
    .rate = 8000,
    .period_size = 128,
    .period_count = 2,
    .format = PCM_FORMAT_S16_LE,
};

struct pcm_config pcm_config_deep = {
    .channels = 2,
    .rate = 44100,
    /* FIXME This is an arbitrary number, may change.
     * Dynamic configuration based on screen on/off is not implemented;
     * let's see what power consumption is first to see if necessary.
     */
    .period_size = 8192,
    .period_count = 2,
    .format = PCM_FORMAT_S16_LE,
};

enum output_type {
    OUTPUT_DEEP_BUF,      // deep PCM buffers output stream
    OUTPUT_LOW_LATENCY,   // low latency output stream
    OUTPUT_TOTAL
};

struct audio_device {
    struct audio_hw_device hw_device;

    pthread_mutex_t lock; /* see note below on mutex acquisition order */
    audio_devices_t out_device; /* "or" of stream_out.device for all active output streams */
    bool mic_mute;
    struct audio_route *ar;
    audio_source_t input_source;
    int cur_route_id;     /* current route ID: combination of input source
                           * and output device IDs */
    struct pcm *pcm_voice_out;
    struct pcm *pcm_sco_out;
    struct pcm *pcm_voice_in;
    struct pcm *pcm_sco_in;
    int es305_preset;
    int es305_mode;
    int es305_vp_fd;
    int es305_preset_fd;
    struct stream_out *outputs[OUTPUT_TOTAL];
};

struct stream_out {
    struct audio_stream_out stream;

    pthread_mutex_t lock; /* see note below on mutex acquisition order */
    struct pcm *pcm[PCM_TOTAL];
    struct pcm_config *config;
    unsigned int pcm_device;
    bool standby; /* true if all PCMs are inactive */
    unsigned int device;

    struct audio_device *dev;
};

struct stream_in {
    struct audio_stream_in stream;

    pthread_mutex_t lock; /* see note below on mutex acquisition order */
    struct pcm *pcm;
    bool standby;

    unsigned int requested_rate;
    struct resampler_itfe *resampler;
    struct resampler_buffer_provider buf_provider;
    int16_t *buffer;
    size_t frames_in;
    int read_status;
    audio_source_t input_source;
    uint16_t ramp_vol;
    uint16_t ramp_step;
    size_t  ramp_frames;

    struct audio_device *dev;
};

enum {
    OUT_DEVICE_SPEAKER,
    OUT_DEVICE_HEADSET,
    OUT_DEVICE_HEADPHONES,
    OUT_DEVICE_BT_SCO,
    OUT_DEVICE_SPEAKER_AND_HEADSET,
    OUT_DEVICE_TAB_SIZE,           /* number of rows in route_configs[][] */
    OUT_DEVICE_NONE,
    OUT_DEVICE_CNT
};

enum {
    IN_SOURCE_MIC,
    IN_SOURCE_CAMCORDER,
    IN_SOURCE_VOICE_RECOGNITION,
    IN_SOURCE_VOICE_COMMUNICATION,
    IN_SOURCE_TAB_SIZE,            /* number of lines in route_configs[][] */
    IN_SOURCE_NONE,
    IN_SOURCE_CNT
};

enum {
    ES305_PRESET_INIT = -3,
    ES305_PRESET_CURRENT = -2,
    ES305_PRESET_OFF = -1,
    ES305_PRESET_VOIP_HANDHELD = 0,
    ES305_PRESET_ASRA_HANDHELD = 1,
    ES305_PRESET_VOIP_DESKTOP = 2,
    ES305_PRESET_ASRA_DESKTOP = 3,
    ES305_PRESET_VOIP_HEADSET = 4,
    ES305_PRESET_ASRA_HEADSET = 5,
    ES305_PRESET_VOIP_HEADPHONES = 6,
    ES305_PRESET_VOIP_HP_DESKTOP = 7,
    ES305_PRESET_CAMCORDER = 8,
};

enum {
    ES305_MODE_DEFAULT,
    ES305_MODE_DESKTOP,
    ES305_NUM_MODES,
};

int get_output_device_id(unsigned int device)
{
    if (device == AUDIO_DEVICE_NONE)
        return OUT_DEVICE_NONE;

    if (popcount(device) == 2) {
        if ((device == (AUDIO_DEVICE_OUT_SPEAKER |
                       AUDIO_DEVICE_OUT_WIRED_HEADSET)) ||
                (device == (AUDIO_DEVICE_OUT_SPEAKER |
                        AUDIO_DEVICE_OUT_WIRED_HEADPHONE)))
            return OUT_DEVICE_SPEAKER_AND_HEADSET;
        else
            return OUT_DEVICE_NONE;
    }

    if (popcount(device) != 1)
        return OUT_DEVICE_NONE;

    switch (device) {
    case AUDIO_DEVICE_OUT_SPEAKER:
        return OUT_DEVICE_SPEAKER;
    case AUDIO_DEVICE_OUT_WIRED_HEADSET:
        return OUT_DEVICE_HEADSET;
    case AUDIO_DEVICE_OUT_WIRED_HEADPHONE:
        return OUT_DEVICE_HEADPHONES;
    case AUDIO_DEVICE_OUT_BLUETOOTH_SCO:
    case AUDIO_DEVICE_OUT_BLUETOOTH_SCO_HEADSET:
    case AUDIO_DEVICE_OUT_BLUETOOTH_SCO_CARKIT:
        return OUT_DEVICE_BT_SCO;
    default:
        return OUT_DEVICE_NONE;
    }
}

int get_input_source_id(audio_source_t source)
{
    switch (source) {
    case AUDIO_SOURCE_DEFAULT:
        return IN_SOURCE_NONE;
    case AUDIO_SOURCE_MIC:
        return IN_SOURCE_MIC;
    case AUDIO_SOURCE_CAMCORDER:
        return IN_SOURCE_CAMCORDER;
    case AUDIO_SOURCE_VOICE_RECOGNITION:
        return IN_SOURCE_VOICE_RECOGNITION;
    case AUDIO_SOURCE_VOICE_COMMUNICATION:
        return IN_SOURCE_VOICE_COMMUNICATION;
    default:
        return IN_SOURCE_NONE;
    }
}

struct route_config {
    const char * const output_route;
    const char * const input_route;
    int es305_preset[ES305_NUM_MODES]; // es305 preset for this route.
                                       // -1 means es305 bypass
};

const struct route_config media_speaker = {
    "media-speaker",
    "media-main-mic",
    { ES305_PRESET_OFF,
      ES305_PRESET_OFF }
};

const struct route_config media_headphones = {
    "media-headphones",
    "media-main-mic",
    { ES305_PRESET_OFF,
      ES305_PRESET_OFF }
};

const struct route_config media_headset = {
    "media-headphones",
    "media-headset-mic",
    { ES305_PRESET_OFF,
      ES305_PRESET_OFF }
};

const struct route_config camcorder_speaker = {
    "media-speaker",
    "media-second-mic",
    { ES305_PRESET_CAMCORDER,
      ES305_PRESET_CAMCORDER }
};

const struct route_config camcorder_headphones = {
    "media-headphones",
    "media-second-mic",
    { ES305_PRESET_CAMCORDER,
      ES305_PRESET_CAMCORDER }
};

const struct route_config voice_rec_speaker = {
    "voice-rec-speaker",
    "voice-rec-main-mic",
    { ES305_PRESET_ASRA_HANDHELD,
      ES305_PRESET_ASRA_DESKTOP }
};

const struct route_config voice_rec_headphones = {
    "voice-rec-headphones",
    "voice-rec-main-mic",
    { ES305_PRESET_ASRA_HANDHELD,
      ES305_PRESET_ASRA_DESKTOP }
};

const struct route_config voice_rec_headset = {
    "voice-rec-headphones",
    "voice-rec-headset-mic",
    { ES305_PRESET_ASRA_HEADSET,
      ES305_PRESET_ASRA_HEADSET }
};

const struct route_config communication_speaker = {
    "communication-speaker",
    "communication-main-mic",
    { ES305_PRESET_VOIP_HANDHELD,
      ES305_PRESET_VOIP_DESKTOP }
};

const struct route_config communication_headphones = {
    "communication-headphones",
    "communication-main-mic",
    { ES305_PRESET_VOIP_HEADPHONES,
      ES305_PRESET_VOIP_HP_DESKTOP}
};

const struct route_config communication_headset = {
    "communication-headphones",
    "communication-headset-mic",
    { ES305_PRESET_VOIP_HEADSET,
      ES305_PRESET_VOIP_HEADSET }
};

const struct route_config speaker_and_headphones = {
    "speaker-and-headphones",
    "main-mic",
    { ES305_PRESET_CURRENT,
      ES305_PRESET_CURRENT }
};

const struct route_config bluetooth_sco = {
    "bt-sco-headset",
    "bt-sco-mic",
    { ES305_PRESET_OFF,
      ES305_PRESET_OFF }
};

const struct route_config * const route_configs[IN_SOURCE_TAB_SIZE]
                                               [OUT_DEVICE_TAB_SIZE] = {
    {   /* IN_SOURCE_MIC */
        &media_speaker,             /* OUT_DEVICE_SPEAKER */
        &media_headset,             /* OUT_DEVICE_HEADSET */
        &media_headphones,          /* OUT_DEVICE_HEADPHONES */
        &bluetooth_sco,             /* OUT_DEVICE_BT_SCO */
        &speaker_and_headphones     /* OUT_DEVICE_SPEAKER_AND_HEADSET */
    },
    {   /* IN_SOURCE_CAMCORDER */
        &camcorder_speaker,         /* OUT_DEVICE_SPEAKER */
        &camcorder_headphones,      /* OUT_DEVICE_HEADSET */
        &camcorder_headphones,      /* OUT_DEVICE_HEADPHONES */
        &bluetooth_sco,             /* OUT_DEVICE_BT_SCO */
        &speaker_and_headphones     /* OUT_DEVICE_SPEAKER_AND_HEADSET */
    },
    {   /* IN_SOURCE_VOICE_RECOGNITION */
        &voice_rec_speaker,         /* OUT_DEVICE_SPEAKER */
        &voice_rec_headset,         /* OUT_DEVICE_HEADSET */
        &voice_rec_headphones,      /* OUT_DEVICE_HEADPHONES */
        &bluetooth_sco,             /* OUT_DEVICE_BT_SCO */
        &speaker_and_headphones     /* OUT_DEVICE_SPEAKER_AND_HEADSET */
    },
    {   /* IN_SOURCE_VOICE_COMMUNICATION */
        &communication_speaker,     /* OUT_DEVICE_SPEAKER */
        &communication_headset,     /* OUT_DEVICE_HEADSET */
        &communication_headphones,  /* OUT_DEVICE_HEADPHONES */
        &bluetooth_sco,             /* OUT_DEVICE_BT_SCO */
        &speaker_and_headphones     /* OUT_DEVICE_SPEAKER_AND_HEADSET */
    }
};

/**
 * NOTE: when multiple mutexes have to be acquired, always respect the
 * following order: hw device > in stream > out stream
 */

/* Helper functions */

static void select_devices(struct audio_device *adev)
{
    int output_device_id = get_output_device_id(adev->out_device);
    int input_source_id = get_input_source_id(adev->input_source);
    const char *output_route = NULL;
    const char *input_route = NULL;
    int new_route_id;
    int new_es305_preset = -1;

    reset_mixer_state(adev->ar);

    new_route_id = (1 << (input_source_id + OUT_DEVICE_CNT)) + (1 << output_device_id);
    if (new_route_id == adev->cur_route_id)
        return;
    adev->cur_route_id = new_route_id;

    if (input_source_id != IN_SOURCE_NONE) {
        if (output_device_id != OUT_DEVICE_NONE) {
            input_route =
                    route_configs[input_source_id][output_device_id]->input_route;
            output_route =
                    route_configs[input_source_id][output_device_id]->output_route;
            new_es305_preset =
                route_configs[input_source_id][output_device_id]->es305_preset[adev->es305_mode];
        } else {
            input_route =
                    route_configs[input_source_id][OUT_DEVICE_SPEAKER]->input_route;
            new_es305_preset =
                route_configs[input_source_id][OUT_DEVICE_SPEAKER]->es305_preset[adev->es305_mode];
        }
    } else {
        if (output_device_id != OUT_DEVICE_NONE) {
            output_route =
                    route_configs[IN_SOURCE_MIC][output_device_id]->output_route;
        }
    }

    ALOGV("select_devices() devices %#x input src %d output route %s input route %s",
          adev->out_device, adev->input_source,
          output_route ? output_route : "none",
          input_route ? input_route : "none");

    if (output_route)
        audio_route_apply_path(adev->ar, output_route);
    if (input_route)
        audio_route_apply_path(adev->ar, input_route);

    if ((new_es305_preset != ES305_PRESET_CURRENT) &&
            (new_es305_preset != adev->es305_preset)) {
        ALOGV("select_devices() changing es305 preset from %d to %d",
              adev->es305_preset, new_es305_preset);
        /* open es305 control files */
        if (adev->es305_vp_fd < 0) {
            adev->es305_vp_fd = open(ES305_VOICE_PROCESSING_PATH, O_RDWR);
            ALOGE_IF(adev->es305_vp_fd < 0,
                     "Could not open es305 voice processing enable file: %s",
                     strerror(errno));
        }
        if (adev->es305_preset_fd < 0) {
            adev->es305_preset_fd = open(ES305_PRESET_PATH, O_RDWR);
            ALOGE_IF(adev->es305_preset_fd < 0,
                     "Could not open es305 preset file: %s",
                     strerror(errno));
        }

        if (new_es305_preset == ES305_PRESET_OFF) {
            if (adev->es305_vp_fd >= 0) {
                write(adev->es305_vp_fd, ES305_OFF, strlen(ES305_OFF));
            }
        } else {
            if (adev->es305_vp_fd >= 0) {
                write(adev->es305_vp_fd, ES305_ON, strlen(ES305_ON));
            }
            if (adev->es305_preset_fd >= 0) {
                char str[8];
                sprintf(str, "%d", new_es305_preset);
                write(adev->es305_preset_fd, str, strlen(str));
            }
        }
        if ((adev->es305_preset_fd >= 0) && (adev->es305_vp_fd >= 0))
            adev->es305_preset = new_es305_preset;
    }

    update_mixer_state(adev->ar);
}

/* must be called with hw device and output stream mutexes locked */
static int start_output_stream(struct stream_out *out)
{
    struct audio_device *adev = out->dev;

    if (out->device & (AUDIO_DEVICE_OUT_SPEAKER |
                       AUDIO_DEVICE_OUT_WIRED_HEADSET |
                       AUDIO_DEVICE_OUT_WIRED_HEADPHONE |
                       AUDIO_DEVICE_OUT_AUX_DIGITAL |
                       AUDIO_DEVICE_OUT_ALL_SCO)) {
        out->pcm[PCM_CARD] = pcm_open(PCM_CARD, out->pcm_device,
                                      PCM_OUT, out->config);

        if (out->pcm[PCM_CARD] && !pcm_is_ready(out->pcm[PCM_CARD])) {
            ALOGE("pcm_open(PCM_CARD) failed: %s",
                  pcm_get_error(out->pcm[PCM_CARD]));
            pcm_close(out->pcm[PCM_CARD]);
            return -ENOMEM;
        }
    }

    if (out->device & AUDIO_DEVICE_OUT_DGTL_DOCK_HEADSET) {
        out->pcm[PCM_CARD_SPDIF] = pcm_open(PCM_CARD_SPDIF, PCM_DEVICE,
                                            PCM_OUT, &pcm_config);

        if (out->pcm[PCM_CARD_SPDIF] &&
                !pcm_is_ready(out->pcm[PCM_CARD_SPDIF])) {
            ALOGE("pcm_open(PCM_CARD_SPDIF) failed: %s",
                  pcm_get_error(out->pcm[PCM_CARD_SPDIF]));
            pcm_close(out->pcm[PCM_CARD_SPDIF]);
            return -ENOMEM;
        }
    }

    adev->out_device |= out->device;
    select_devices(adev);

    return 0;
}

/* must be called with hw device and input stream mutexes locked */
static int start_input_stream(struct stream_in *in)
{
    struct audio_device *adev = in->dev;

    in->pcm = pcm_open(PCM_CARD, PCM_DEVICE, PCM_IN, &pcm_config);

    if (in->pcm && !pcm_is_ready(in->pcm)) {
        ALOGE("pcm_open() failed: %s", pcm_get_error(in->pcm));
        pcm_close(in->pcm);
        return -ENOMEM;
    }

    /* if no supported sample rate is available, use the resampler */
    if (in->resampler)
        in->resampler->reset(in->resampler);

    in->frames_in = 0;
    adev->input_source = in->input_source;
    select_devices(adev);

    /* initialize volume ramp */
    in->ramp_frames = (CAPTURE_START_RAMP_MS * in->requested_rate) / 1000;
    in->ramp_step = (uint16_t)(USHRT_MAX / in->ramp_frames);
    in->ramp_vol = 0;;

    return 0;
}

/* must be called with the hw device mutex locked, OK to hold other mutexes */
static void start_bt_sco(struct audio_device *adev) {
    adev->pcm_voice_out = pcm_open(PCM_CARD, PCM_DEVICE_VOICE, PCM_OUT,
                              &pcm_config_sco);
    if (adev->pcm_voice_out && !pcm_is_ready(adev->pcm_voice_out)) {
        ALOGE("pcm_open(VOICE_OUT) failed: %s", pcm_get_error(adev->pcm_voice_out));
        goto err_voice_out;
    }
    adev->pcm_sco_out = pcm_open(PCM_CARD, PCM_DEVICE_SCO, PCM_OUT,
                            &pcm_config_sco);
    if (adev->pcm_sco_out && !pcm_is_ready(adev->pcm_sco_out)) {
        ALOGE("pcm_open(SCO_OUT) failed: %s", pcm_get_error(adev->pcm_sco_out));
        goto err_sco_out;
    }
    adev->pcm_voice_in = pcm_open(PCM_CARD, PCM_DEVICE_VOICE, PCM_IN,
                                 &pcm_config_sco);
    if (adev->pcm_voice_in && !pcm_is_ready(adev->pcm_voice_in)) {
        ALOGE("pcm_open(VOICE_IN) failed: %s", pcm_get_error(adev->pcm_voice_in));
        goto err_voice_in;
    }
    adev->pcm_sco_in = pcm_open(PCM_CARD, PCM_DEVICE_SCO, PCM_IN,
                               &pcm_config_sco);
    if (adev->pcm_sco_in && !pcm_is_ready(adev->pcm_sco_in)) {
        ALOGE("pcm_open(SCO_IN) failed: %s", pcm_get_error(adev->pcm_sco_in));
        goto err_sco_in;
    }

    pcm_start(adev->pcm_voice_out);
    pcm_start(adev->pcm_sco_out);
    pcm_start(adev->pcm_voice_in);
    pcm_start(adev->pcm_sco_in);

    return;

err_sco_in:
    pcm_close(adev->pcm_sco_in);
err_voice_in:
    pcm_close(adev->pcm_voice_in);
err_sco_out:
    pcm_close(adev->pcm_sco_out);
err_voice_out:
    pcm_close(adev->pcm_voice_out);
}

/* must be called with the hw device mutex locked, OK to hold other mutexes */
static void stop_bt_sco(struct audio_device *adev) {
    pcm_stop(adev->pcm_voice_out);
    pcm_stop(adev->pcm_sco_out);
    pcm_stop(adev->pcm_voice_in);
    pcm_stop(adev->pcm_sco_in);

    pcm_close(adev->pcm_voice_out);
    pcm_close(adev->pcm_sco_out);
    pcm_close(adev->pcm_voice_in);
    pcm_close(adev->pcm_sco_in);
}

static size_t get_input_buffer_size(unsigned int sample_rate,
                                    audio_format_t format,
                                    unsigned int channel_count)
{
    size_t size;

    /*
     * take resampling into account and return the closest majoring
     * multiple of 16 frames, as audioflinger expects audio buffers to
     * be a multiple of 16 frames
     */
    size = (pcm_config.period_size * sample_rate) / pcm_config.rate;
    size = ((size + 15) / 16) * 16;

    return size * channel_count * audio_bytes_per_sample(format);
}

static int get_next_buffer(struct resampler_buffer_provider *buffer_provider,
                                   struct resampler_buffer* buffer)
{
    struct stream_in *in;
    size_t i;

    if (buffer_provider == NULL || buffer == NULL)
        return -EINVAL;

    in = (struct stream_in *)((char *)buffer_provider -
                                   offsetof(struct stream_in, buf_provider));

    if (in->pcm == NULL) {
        buffer->raw = NULL;
        buffer->frame_count = 0;
        in->read_status = -ENODEV;
        return -ENODEV;
    }

    if (in->frames_in == 0) {
        in->read_status = pcm_read(in->pcm,
                                   (void*)in->buffer,
                                   pcm_frames_to_bytes(in->pcm, pcm_config.period_size));
        if (in->read_status != 0) {
            ALOGE("get_next_buffer() pcm_read error %d", in->read_status);
            buffer->raw = NULL;
            buffer->frame_count = 0;
            return in->read_status;
        }

        in->frames_in = pcm_config.period_size;

        /* Do stereo to mono conversion in place by discarding right channel */
        for (i = 1; i < in->frames_in; i++)
            in->buffer[i] = in->buffer[i * 2];
    }

    buffer->frame_count = (buffer->frame_count > in->frames_in) ?
                                in->frames_in : buffer->frame_count;
    buffer->i16 = in->buffer + (pcm_config.period_size - in->frames_in);

    return in->read_status;

}

static void release_buffer(struct resampler_buffer_provider *buffer_provider,
                                  struct resampler_buffer* buffer)
{
    struct stream_in *in;

    if (buffer_provider == NULL || buffer == NULL)
        return;

    in = (struct stream_in *)((char *)buffer_provider -
                                   offsetof(struct stream_in, buf_provider));

    in->frames_in -= buffer->frame_count;
}

/* read_frames() reads frames from kernel driver, down samples to capture rate
 * if necessary and output the number of frames requested to the buffer specified */
static ssize_t read_frames(struct stream_in *in, void *buffer, ssize_t frames)
{
    ssize_t frames_wr = 0;
    size_t frame_size = audio_stream_frame_size(&in->stream.common);

    while (frames_wr < frames) {
        size_t frames_rd = frames - frames_wr;
        if (in->resampler != NULL) {
            in->resampler->resample_from_provider(in->resampler,
                    (int16_t *)((char *)buffer +
                            frames_wr * frame_size),
                    &frames_rd);
        } else {
            struct resampler_buffer buf = {
                    { raw : NULL, },
                    frame_count : frames_rd,
            };
            get_next_buffer(&in->buf_provider, &buf);
            if (buf.raw != NULL) {
                memcpy((char *)buffer +
                           frames_wr * frame_size,
                        buf.raw,
                        buf.frame_count * frame_size);
                frames_rd = buf.frame_count;
            }
            release_buffer(&in->buf_provider, &buf);
        }
        /* in->read_status is updated by getNextBuffer() also called by
         * in->resampler->resample_from_provider() */
        if (in->read_status != 0)
            return in->read_status;

        frames_wr += frames_rd;
    }
    return frames_wr;
}

/* API functions */

static uint32_t out_get_sample_rate(const struct audio_stream *stream)
{
    return pcm_config.rate;
}

static int out_set_sample_rate(struct audio_stream *stream, uint32_t rate)
{
    return -ENOSYS;
}

static size_t out_get_buffer_size(const struct audio_stream *stream)
{
    struct stream_out *out = (struct stream_out *) stream;

    return out->config->period_size * audio_stream_frame_size(stream);
}

static audio_channel_mask_t out_get_channels(const struct audio_stream *stream)
{
    return AUDIO_CHANNEL_OUT_STEREO;
}

static audio_format_t out_get_format(const struct audio_stream *stream)
{
    return AUDIO_FORMAT_PCM_16_BIT;
}

static int out_set_format(struct audio_stream *stream, audio_format_t format)
{
    return -ENOSYS;
}

/* Return the set of output devices associated with active streams
 * other than out.  Assumes out is non-NULL and out->dev is locked.
 */
static audio_devices_t output_devices(struct stream_out *out)
{
    struct audio_device *dev = out->dev;
    enum output_type type;
    audio_devices_t devices = AUDIO_DEVICE_NONE;

    for (type = 0; type < OUTPUT_TOTAL; ++type) {
        struct stream_out *other = dev->outputs[type];
        if (other && (other != out) && !other->standby) {
            /* safe to access other stream without a mutex,
             * because we hold the dev lock,
             * which prevents the other stream from being closed
             */
            devices |= other->device;
        }
    }

    return devices;
}

static int do_out_standby(struct stream_out *out)
{
    int i;
    struct audio_device *dev;

    if (!out->standby) {
        for (i = 0; i < PCM_TOTAL; i++) {
            if (out->pcm[i]) {
                pcm_close(out->pcm[i]);
                out->pcm[i] = NULL;
            }
        }
        out->standby = true;

        /* re-calculate the set of active devices from other streams */
        dev = out->dev;
        dev->out_device = output_devices(out);
        select_devices(dev);

    }

    return 0;
}

static int out_standby(struct audio_stream *stream)
{
    struct stream_out *out = (struct stream_out *)stream;
    int ret;

    pthread_mutex_lock(&out->dev->lock);
    pthread_mutex_lock(&out->lock);

    ret = do_out_standby(out);

    pthread_mutex_unlock(&out->lock);
    pthread_mutex_unlock(&out->dev->lock);

    return ret;
}

static int out_dump(const struct audio_stream *stream, int fd)
{
    return 0;
}

static int out_set_parameters(struct audio_stream *stream, const char *kvpairs)
{
    struct stream_out *out = (struct stream_out *)stream;
    struct audio_device *adev = out->dev;
    struct str_parms *parms;
    char value[32];
    int ret;
    unsigned int val;

    parms = str_parms_create_str(kvpairs);

    ret = str_parms_get_str(parms, AUDIO_PARAMETER_STREAM_ROUTING,
                            value, sizeof(value));
    pthread_mutex_lock(&adev->lock);
    pthread_mutex_lock(&out->lock);
    if (ret >= 0) {
        val = atoi(value);
        if ((out->device != val) && (val != 0)) {
            /* Force standby if moving to/from SPDIF or if the output
             * device changes when in SPDIF mode */
            if (((val & AUDIO_DEVICE_OUT_DGTL_DOCK_HEADSET) ^
                 (adev->out_device & AUDIO_DEVICE_OUT_DGTL_DOCK_HEADSET)) ||
                (adev->out_device & AUDIO_DEVICE_OUT_DGTL_DOCK_HEADSET)) {
                do_out_standby(out);
            }

            /* Start/stop the BT SCO stream */
            if ((val & AUDIO_DEVICE_OUT_ALL_SCO) ^
                (adev->out_device & AUDIO_DEVICE_OUT_ALL_SCO)) {
                if (val & AUDIO_DEVICE_OUT_ALL_SCO)
                    start_bt_sco(adev);
                else
                    stop_bt_sco(adev);
            }

            out->device = val;
            if (!out->standby) {
                adev->out_device = output_devices(out) | out->device;
                select_devices(adev);
            }
        }
    }
    pthread_mutex_unlock(&out->lock);
    pthread_mutex_unlock(&adev->lock);

    str_parms_destroy(parms);
    return ret;
}

static char * out_get_parameters(const struct audio_stream *stream, const char *keys)
{
    return strdup("");
}

static uint32_t out_get_latency(const struct audio_stream_out *stream)
{
    struct stream_out *out = (struct stream_out *) stream;

    return (out->config->period_size * out->config->period_count * 1000) /
            out->config->rate;
}

static int out_set_volume(struct audio_stream_out *stream, float left,
                          float right)
{
    return -ENOSYS;
}

static ssize_t out_write(struct audio_stream_out *stream, const void* buffer,
                         size_t bytes)
{
    int ret;
    struct stream_out *out = (struct stream_out *)stream;
    struct audio_device *adev = out->dev;
    int i;

    /*
     * acquiring hw device mutex systematically is useful if a low
     * priority thread is waiting on the output stream mutex - e.g.
     * executing out_set_parameters() while holding the hw device
     * mutex
     */
    pthread_mutex_lock(&adev->lock);
    pthread_mutex_lock(&out->lock);
    if (out->standby) {
        ret = start_output_stream(out);
        if (ret != 0) {
            pthread_mutex_unlock(&adev->lock);
            goto exit;
        }
        out->standby = false;
    }
    pthread_mutex_unlock(&adev->lock);

    /* Write to all active PCMs */
    for (i = 0; i < PCM_TOTAL; i++)
        if (out->pcm[i])
           pcm_write(out->pcm[i], (void *)buffer, bytes);

exit:
    pthread_mutex_unlock(&out->lock);

    if (ret != 0) {
        usleep(bytes * 1000000 / audio_stream_frame_size(&stream->common) /
               out_get_sample_rate(&stream->common));
    }

    return bytes;
}

static int out_get_render_position(const struct audio_stream_out *stream,
                                   uint32_t *dsp_frames)
{
    return -EINVAL;
}

static int out_add_audio_effect(const struct audio_stream *stream, effect_handle_t effect)
{
    return 0;
}

static int out_remove_audio_effect(const struct audio_stream *stream, effect_handle_t effect)
{
    return 0;
}

static int out_get_next_write_timestamp(const struct audio_stream_out *stream,
                                        int64_t *timestamp)
{
    return -EINVAL;
}

/** audio_stream_in implementation **/
static uint32_t in_get_sample_rate(const struct audio_stream *stream)
{
    struct stream_in *in = (struct stream_in *)stream;

    return in->requested_rate;
}

static int in_set_sample_rate(struct audio_stream *stream, uint32_t rate)
{
    return 0;
}

static audio_channel_mask_t in_get_channels(const struct audio_stream *stream)
{
    return AUDIO_CHANNEL_IN_MONO;
}


static size_t in_get_buffer_size(const struct audio_stream *stream)
{
    struct stream_in *in = (struct stream_in *)stream;

    return get_input_buffer_size(in->requested_rate,
                                 AUDIO_FORMAT_PCM_16_BIT,
                                 popcount(in_get_channels(stream)));
}

static audio_format_t in_get_format(const struct audio_stream *stream)
{
    return AUDIO_FORMAT_PCM_16_BIT;
}

static int in_set_format(struct audio_stream *stream, audio_format_t format)
{
    return -ENOSYS;
}

static int in_standby(struct audio_stream *stream)
{
    struct stream_in *in = (struct stream_in *)stream;

    pthread_mutex_lock(&in->dev->lock);
    pthread_mutex_lock(&in->lock);

    if (!in->standby) {
        pcm_close(in->pcm);
        in->pcm = NULL;
        in->dev->input_source = AUDIO_SOURCE_DEFAULT;
        select_devices(in->dev);
        in->standby = true;
    }

    pthread_mutex_unlock(&in->lock);
    pthread_mutex_unlock(&in->dev->lock);

    return 0;
}

static int in_dump(const struct audio_stream *stream, int fd)
{
    return 0;
}

static int in_set_parameters(struct audio_stream *stream, const char *kvpairs)
{
    struct stream_in *in = (struct stream_in *)stream;
    struct audio_device *adev = in->dev;
    struct str_parms *parms;
    char value[32];
    int ret;
    unsigned int val;
    bool apply_now = false;

    parms = str_parms_create_str(kvpairs);

    ret = str_parms_get_str(parms, AUDIO_PARAMETER_STREAM_INPUT_SOURCE,
                            value, sizeof(value));

    pthread_mutex_lock(&adev->lock);
    pthread_mutex_lock(&in->lock);
    if (ret >= 0) {
        val = atoi(value);
        /* no audio source uses val == 0 */
        if ((in->input_source != val) && (val != 0)) {
            in->input_source = val;
            apply_now = !in->standby;
        }
    }

    if (apply_now) {
        adev->input_source = in->input_source;
        select_devices(adev);
    }

    pthread_mutex_unlock(&in->lock);
    pthread_mutex_unlock(&adev->lock);

    str_parms_destroy(parms);
    return ret;
}

static char * in_get_parameters(const struct audio_stream *stream,
                                const char *keys)
{
    return strdup("");
}

static int in_set_gain(struct audio_stream_in *stream, float gain)
{
    return 0;
}

static void in_apply_ramp(struct stream_in *in, int16_t *buffer, size_t frames)
{
    size_t i;
    uint16_t vol = in->ramp_vol;
    uint16_t step = in->ramp_step;

    frames = (frames < in->ramp_frames) ? frames : in->ramp_frames;

    for (i = 0; i < frames; i++)
    {
        buffer[i] = (int16_t)((buffer[i] * vol) >> 16);
        vol += step;
    }

    in->ramp_vol = vol;
    in->ramp_frames -= frames;
}

static ssize_t in_read(struct audio_stream_in *stream, void* buffer,
                       size_t bytes)
{
    int ret = 0;
    struct stream_in *in = (struct stream_in *)stream;
    struct audio_device *adev = in->dev;
    size_t frames_rq = bytes / audio_stream_frame_size(&stream->common);

    /*
     * acquiring hw device mutex systematically is useful if a low
     * priority thread is waiting on the input stream mutex - e.g.
     * executing in_set_parameters() while holding the hw device
     * mutex
     */
    pthread_mutex_lock(&adev->lock);
    pthread_mutex_lock(&in->lock);
    if (in->standby) {
        ret = start_input_stream(in);
        if (ret == 0)
            in->standby = 0;
    }
    pthread_mutex_unlock(&adev->lock);

    if (ret < 0)
        goto exit;

    /*if (in->num_preprocessors != 0)
        ret = process_frames(in, buffer, frames_rq);
      else */
    ret = read_frames(in, buffer, frames_rq);

    if (ret > 0)
        ret = 0;

    if (in->ramp_frames > 0)
        in_apply_ramp(in, buffer, frames_rq);

    /*
     * Instead of writing zeroes here, we could trust the hardware
     * to always provide zeroes when muted.
     */
    if (ret == 0 && adev->mic_mute)
        memset(buffer, 0, bytes);

exit:
    if (ret < 0)
        usleep(bytes * 1000000 / audio_stream_frame_size(&stream->common) /
               in_get_sample_rate(&stream->common));

    pthread_mutex_unlock(&in->lock);
    return bytes;
}

static uint32_t in_get_input_frames_lost(struct audio_stream_in *stream)
{
    return 0;
}

static int in_add_audio_effect(const struct audio_stream *stream,
                               effect_handle_t effect)
{
    return 0;
}

static int in_remove_audio_effect(const struct audio_stream *stream,
                                  effect_handle_t effect)
{
    return 0;
}


static int adev_open_output_stream(struct audio_hw_device *dev,
                                   audio_io_handle_t handle,
                                   audio_devices_t devices,
                                   audio_output_flags_t flags,
                                   struct audio_config *config,
                                   struct audio_stream_out **stream_out)
{
    struct audio_device *adev = (struct audio_device *)dev;
    struct stream_out *out;
    int ret;
    enum output_type type;

    out = (struct stream_out *)calloc(1, sizeof(struct stream_out));
    if (!out)
        return -ENOMEM;

    out->stream.common.get_sample_rate = out_get_sample_rate;
    out->stream.common.set_sample_rate = out_set_sample_rate;
    out->stream.common.get_buffer_size = out_get_buffer_size;
    out->stream.common.get_channels = out_get_channels;
    out->stream.common.get_format = out_get_format;
    out->stream.common.set_format = out_set_format;
    out->stream.common.standby = out_standby;
    out->stream.common.dump = out_dump;
    out->stream.common.set_parameters = out_set_parameters;
    out->stream.common.get_parameters = out_get_parameters;
    out->stream.common.add_audio_effect = out_add_audio_effect;
    out->stream.common.remove_audio_effect = out_remove_audio_effect;
    out->stream.get_latency = out_get_latency;
    out->stream.set_volume = out_set_volume;
    out->stream.write = out_write;
    out->stream.get_render_position = out_get_render_position;
    out->stream.get_next_write_timestamp = out_get_next_write_timestamp;

    out->dev = adev;

    config->format = out_get_format(&out->stream.common);
    config->channel_mask = out_get_channels(&out->stream.common);
    config->sample_rate = out_get_sample_rate(&out->stream.common);

    out->standby = true;

    if (flags & AUDIO_OUTPUT_FLAG_DEEP_BUFFER) {
        out->config = &pcm_config_deep;
        out->pcm_device = PCM_DEVICE_DEEP;
        type = OUTPUT_DEEP_BUF;
    } else {
        out->config = &pcm_config;
        out->pcm_device = PCM_DEVICE;
        type = OUTPUT_LOW_LATENCY;
    }

    pthread_mutex_lock(&adev->lock);
    if (adev->outputs[type]) {
        pthread_mutex_unlock(&adev->lock);
        ret = -EBUSY;
        goto err_open;
    }
    adev->outputs[type] = out;
    pthread_mutex_unlock(&adev->lock);

    *stream_out = &out->stream;
    return 0;

err_open:
    free(out);
    *stream_out = NULL;
    return ret;
}

static void adev_close_output_stream(struct audio_hw_device *dev,
                                     struct audio_stream_out *stream)
{
    struct audio_device *adev;
    enum output_type type;

    out_standby(&stream->common);
    adev = (struct audio_device *)dev;
    pthread_mutex_lock(&adev->lock);
    for (type = 0; type < OUTPUT_TOTAL; ++type) {
        if (adev->outputs[type] == (struct stream_out *) stream) {
            adev->outputs[type] = NULL;
        }
    }
    pthread_mutex_unlock(&adev->lock);
    free(stream);
}

static int adev_set_parameters(struct audio_hw_device *dev, const char *kvpairs)
{
    struct audio_device *adev = (struct audio_device *)dev;
    struct str_parms *parms;
    char *str;
    char value[32];
    int ret;

    parms = str_parms_create_str(kvpairs);
    ret = str_parms_get_str(parms, "desktop", value, sizeof(value));
    if (ret >= 0) {
        int es305_mode;

        if (strcmp(value, "yes") == 0)
            es305_mode = ES305_MODE_DESKTOP;
        else
            es305_mode = ES305_MODE_DEFAULT;

        ALOGV("adev_set_parameters() changing es305 mode to %d", es305_mode);
        pthread_mutex_lock(&adev->lock);
        if (es305_mode != adev->es305_mode) {
            adev->es305_mode = es305_mode;
            select_devices(adev);
        }
        pthread_mutex_unlock(&adev->lock);
    }
    return ret;
}

static char * adev_get_parameters(const struct audio_hw_device *dev,
                                  const char *keys)
{
    struct audio_device *adev = (struct audio_device *)dev;
    struct str_parms *parms = str_parms_create_str(keys);
    char value[32];
    int ret = str_parms_get_str(parms, "ec_supported", value, sizeof(value));
    char *str;

    str_parms_destroy(parms);
    if (ret >= 0) {
        if ((adev->es305_preset_fd >= 0) && (adev->es305_vp_fd >= 0))
            parms = str_parms_create_str("ec_supported=yes");
        else
            parms = str_parms_create_str("ec_supported=no");

        str = str_parms_to_str(parms);
        str_parms_destroy(parms);
        return str;
    }
    return strdup("");
}

static int adev_init_check(const struct audio_hw_device *dev)
{
    return 0;
}

static int adev_set_voice_volume(struct audio_hw_device *dev, float volume)
{
    return -ENOSYS;
}

static int adev_set_master_volume(struct audio_hw_device *dev, float volume)
{
    return -ENOSYS;
}

static int adev_set_mode(struct audio_hw_device *dev, audio_mode_t mode)
{
    return 0;
}

static int adev_set_mic_mute(struct audio_hw_device *dev, bool state)
{
    struct audio_device *adev = (struct audio_device *)dev;

    adev->mic_mute = state;

    return 0;
}

static int adev_get_mic_mute(const struct audio_hw_device *dev, bool *state)
{
    struct audio_device *adev = (struct audio_device *)dev;

    *state = adev->mic_mute;

    return 0;
}

static size_t adev_get_input_buffer_size(const struct audio_hw_device *dev,
                                         const struct audio_config *config)
{

    return get_input_buffer_size(config->sample_rate, config->format,
                                 popcount(config->channel_mask));
}

static int adev_open_input_stream(struct audio_hw_device *dev,
                                  audio_io_handle_t handle,
                                  audio_devices_t devices,
                                  struct audio_config *config,
                                  struct audio_stream_in **stream_in)
{
    struct audio_device *adev = (struct audio_device *)dev;
    struct stream_in *in;
    int ret;

    *stream_in = NULL;

    /* Respond with a request for mono if a different format is given. */
    if (config->channel_mask != AUDIO_CHANNEL_IN_MONO) {
        config->channel_mask = AUDIO_CHANNEL_IN_MONO;
        return -EINVAL;
    }

    in = (struct stream_in *)calloc(1, sizeof(struct stream_in));
    if (!in)
        return -ENOMEM;

    in->stream.common.get_sample_rate = in_get_sample_rate;
    in->stream.common.set_sample_rate = in_set_sample_rate;
    in->stream.common.get_buffer_size = in_get_buffer_size;
    in->stream.common.get_channels = in_get_channels;
    in->stream.common.get_format = in_get_format;
    in->stream.common.set_format = in_set_format;
    in->stream.common.standby = in_standby;
    in->stream.common.dump = in_dump;
    in->stream.common.set_parameters = in_set_parameters;
    in->stream.common.get_parameters = in_get_parameters;
    in->stream.common.add_audio_effect = in_add_audio_effect;
    in->stream.common.remove_audio_effect = in_remove_audio_effect;
    in->stream.set_gain = in_set_gain;
    in->stream.read = in_read;
    in->stream.get_input_frames_lost = in_get_input_frames_lost;

    in->dev = adev;
    in->standby = true;
    in->requested_rate = config->sample_rate;
    in->input_source = AUDIO_SOURCE_DEFAULT;

    in->buffer = malloc(pcm_config.period_size * pcm_config.channels
                                               * audio_stream_frame_size(&in->stream.common));

    if (!in->buffer) {
        ret = -ENOMEM;
        goto err_malloc;
    }

    if (in->requested_rate != pcm_config.rate) {
        in->buf_provider.get_next_buffer = get_next_buffer;
        in->buf_provider.release_buffer = release_buffer;

        ret = create_resampler(pcm_config.rate,
                               in->requested_rate,
                               1,
                               RESAMPLER_QUALITY_DEFAULT,
                               &in->buf_provider,
                               &in->resampler);
        if (ret != 0) {
            ret = -EINVAL;
            goto err_resampler;
        }
    }

    *stream_in = &in->stream;
    return 0;

err_resampler:
    free(in->buffer);
err_malloc:
    free(in);
    return ret;
}

static void adev_close_input_stream(struct audio_hw_device *dev,
                                   struct audio_stream_in *stream)
{
    struct stream_in *in = (struct stream_in *)stream;

    in_standby(&stream->common);
    if (in->resampler) {
        release_resampler(in->resampler);
        in->resampler = NULL;
    }
    free(in->buffer);
    free(stream);
}

static int adev_dump(const audio_hw_device_t *device, int fd)
{
    return 0;
}

static int adev_close(hw_device_t *device)
{
    struct audio_device *adev = (struct audio_device *)device;

    audio_route_free(adev->ar);

    if(adev->es305_vp_fd >= 0)
        close(adev->es305_vp_fd);
    if(adev->es305_preset_fd >= 0)
        close(adev->es305_preset_fd);

    free(device);
    return 0;
}

static int adev_open(const hw_module_t* module, const char* name,
                     hw_device_t** device)
{
    struct audio_device *adev;
    int ret;

    if (strcmp(name, AUDIO_HARDWARE_INTERFACE) != 0)
        return -EINVAL;

    adev = calloc(1, sizeof(struct audio_device));
    if (!adev)
        return -ENOMEM;

    adev->hw_device.common.tag = HARDWARE_DEVICE_TAG;
    adev->hw_device.common.version = AUDIO_DEVICE_API_VERSION_2_0;
    adev->hw_device.common.module = (struct hw_module_t *) module;
    adev->hw_device.common.close = adev_close;

    adev->hw_device.init_check = adev_init_check;
    adev->hw_device.set_voice_volume = adev_set_voice_volume;
    adev->hw_device.set_master_volume = adev_set_master_volume;
    adev->hw_device.set_mode = adev_set_mode;
    adev->hw_device.set_mic_mute = adev_set_mic_mute;
    adev->hw_device.get_mic_mute = adev_get_mic_mute;
    adev->hw_device.set_parameters = adev_set_parameters;
    adev->hw_device.get_parameters = adev_get_parameters;
    adev->hw_device.get_input_buffer_size = adev_get_input_buffer_size;
    adev->hw_device.open_output_stream = adev_open_output_stream;
    adev->hw_device.close_output_stream = adev_close_output_stream;
    adev->hw_device.open_input_stream = adev_open_input_stream;
    adev->hw_device.close_input_stream = adev_close_input_stream;
    adev->hw_device.dump = adev_dump;

    adev->ar = audio_route_init();
    adev->input_source = AUDIO_SOURCE_DEFAULT;
    /* adev->cur_route_id initial value is 0 and such that first device
     * selection is always applied by select_devices() */

    adev->es305_vp_fd = -1;
    adev->es305_preset_fd = -1;
    adev->es305_preset = ES305_PRESET_INIT;
    adev->es305_mode = ES305_MODE_DEFAULT;

    *device = &adev->hw_device.common;

    return 0;
}

static struct hw_module_methods_t hal_module_methods = {
    .open = adev_open,
};

struct audio_module HAL_MODULE_INFO_SYM = {
    .common = {
        .tag = HARDWARE_MODULE_TAG,
        .module_api_version = AUDIO_MODULE_API_VERSION_0_1,
        .hal_api_version = HARDWARE_HAL_API_VERSION,
        .id = AUDIO_HARDWARE_MODULE_ID,
        .name = "Manta audio HW HAL",
        .author = "The Android Open Source Project",
        .methods = &hal_module_methods,
    },
};
