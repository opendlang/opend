/* Author: Romain "Artefact2" Dalmaso <artefact2@gmail.com> */

/* This program is free software. It comes without any warranty, to the
 * extent permitted by applicable law. You can redistribute it and/or
 * modify it under the terms of the Do What The Fuck You Want To Public
 * License, Version 2, as published by Sam Hocevar. See
 * http://sam.zoy.org/wtfpl/COPYING for more details. */
module audioformats.libxm;

import core.stdc.config: c_ulong;
import core.stdc.stdlib: malloc, free;
import core.stdc.string: memcpy, memcmp, memset;
import std.math;

nothrow:
@nogc:

private alias int8_t = byte;
private alias int16_t = short;
private alias int32_t = int;
private alias uint8_t = ubyte;
private alias uint16_t = ushort;
private alias uint32_t = uint;
private alias uint64_t = ulong;

// xm_internal.h

version(BigEndian)
{
    static assert(false, "Big endian platforms are not yet supported, sorry");
}

/* ----- XM constants ----- */

enum SAMPLE_NAME_LENGTH = 22;
enum INSTRUMENT_HEADER_LENGTH = 263;
enum INSTRUMENT_NAME_LENGTH = 22;
enum MODULE_NAME_LENGTH = 20;
enum TRACKER_NAME_LENGTH = 20;
enum PATTERN_ORDER_TABLE_LENGTH = 256;
enum NUM_NOTES = 96;
enum NUM_ENVELOPE_POINTS = 12;
enum MAX_NUM_ROWS = 256;


// Options
version = XM_RAMPING; // sounds better to me when on
//version = XM_STRINGS;
enum XM_DEFENSIVE = true;
enum XM_LINEAR_INTERPOLATION = false; // sounds better/digital to me when off
enum XM_DEBUG = false;

version(XM_RAMPING)
{
    enum XM_SAMPLE_RAMPING_POINTS = 0x20;
}

/* ----- Data types ----- */

alias xm_waveform_type_t = int;
enum : xm_waveform_type_t {
    XM_SINE_WAVEFORM = 0,
    XM_RAMP_DOWN_WAVEFORM = 1,
    XM_SQUARE_WAVEFORM = 2,
    XM_RANDOM_WAVEFORM = 3,
    XM_RAMP_UP_WAVEFORM = 4,
}

alias xm_loop_type_t = int;
enum : xm_loop_type_t
{
    XM_NO_LOOP,
    XM_FORWARD_LOOP,
    XM_PING_PONG_LOOP,
}

alias xm_frequency_type_t = int;
enum : xm_frequency_type_t 
{
    XM_LINEAR_FREQUENCIES,
    XM_AMIGA_FREQUENCIES,
}

struct xm_envelope_point_t 
{
    uint16_t frame;
    uint16_t value;
}

struct xm_envelope_t
{
    xm_envelope_point_t[NUM_ENVELOPE_POINTS] points;
    uint8_t num_points;
    uint8_t sustain_point;
    uint8_t loop_start_point;
    uint8_t loop_end_point;
    bool enabled;
    bool sustain_enabled;
    bool loop_enabled;
}

struct xm_sample_t 
{
    version(XM_STRINGS)
    {
        char[SAMPLE_NAME_LENGTH + 1] name;
    }

    uint8_t bits; /* Either 8 or 16 */

    uint32_t length;
    uint32_t loop_start;
    uint32_t loop_length;
    uint32_t loop_end;
    float volume;
    int8_t finetune;
    xm_loop_type_t loop_type;
    float panning;
    int8_t relative_note;
    uint64_t latest_trigger;

    union {
        int8_t* data8;
        int16_t* data16;
    };
}

struct xm_instrument_t
{
    version(XM_STRINGS)
    {
         char[INSTRUMENT_NAME_LENGTH + 1] name;
    }
    uint16_t num_samples;
    uint8_t[NUM_NOTES] sample_of_notes;
    xm_envelope_t volume_envelope;
    xm_envelope_t panning_envelope;
    xm_waveform_type_t vibrato_type;
    uint8_t vibrato_sweep;
    uint8_t vibrato_depth;
    uint8_t vibrato_rate;
    uint16_t volume_fadeout;
    uint64_t latest_trigger;
    bool muted;

    xm_sample_t* samples;
}

struct xm_pattern_slot_t 
{
    uint8_t note; /* 1-96, 97 = Key Off note */
    uint8_t instrument; /* 1-128 */
    uint8_t volume_column;
    uint8_t effect_type;
    uint8_t effect_param;

    nothrow:
    @nogc:

    bool HAS_TONE_PORTAMENTO()
    {
        return effect_type == 3  || effect_type == 5 || ((volume_column >> 4) == 0xF);
    }

    bool HAS_ARPEGGIO()
    {
        return effect_param != 0;
    }

    bool HAS_VIBRATO()
    {
        return effect_type == 4 || effect_type == 6 || (volume_column >> 4) == 0xB;
    }
}

struct xm_pattern_t
{
    uint16_t num_rows;
    xm_pattern_slot_t* slots; /* Array of size num_rows * num_channels */
}

struct xm_module_t 
{
    version(XM_STRINGS)
    {
        char[MODULE_NAME_LENGTH + 1] name;
        char[TRACKER_NAME_LENGTH + 1] trackername;
    }

    uint16_t length;
    uint16_t restart_position;
    uint16_t num_channels;
    uint16_t num_patterns;
    uint16_t num_instruments;
    xm_frequency_type_t frequency_type;
    uint8_t[PATTERN_ORDER_TABLE_LENGTH] pattern_table;

    xm_pattern_t* patterns;
    xm_instrument_t* instruments; /* Instrument 1 has index 0,
                                   * instrument 2 has index 1, etc. */
}

struct xm_channel_context_t 
{
    float note;
    float orig_note; /* The original note before effect modifications, as read in the pattern. */
    xm_instrument_t* instrument; /* Could be null */
    xm_sample_t* sample; /* Could be null */
    xm_pattern_slot_t* current;

    float sample_position;
    float period;
    float frequency;
    float step;
    bool ping; /* For ping-pong samples: true is -., false is <-- */

    float volume; /* Ideally between 0 (muted) and 1 (loudest) */
    float panning; /* Between 0 (left) and 1 (right); 0.5 is centered */

    uint16_t autovibrato_ticks;

    bool sustained;
    float fadeout_volume;
    float volume_envelope_volume;
    float panning_envelope_panning;
    uint16_t volume_envelope_frame_count;
    uint16_t panning_envelope_frame_count;

    float autovibrato_note_offset;

    bool arp_in_progress;
    uint8_t arp_note_offset;
    uint8_t volume_slide_param;
    uint8_t fine_volume_slide_param;
    uint8_t global_volume_slide_param;
    uint8_t panning_slide_param;
    uint8_t portamento_up_param;
    uint8_t portamento_down_param;
    uint8_t fine_portamento_up_param;
    uint8_t fine_portamento_down_param;
    uint8_t extra_fine_portamento_up_param;
    uint8_t extra_fine_portamento_down_param;
    uint8_t tone_portamento_param;
    float tone_portamento_target_period;
    uint8_t multi_retrig_param;
    uint8_t note_delay_param;
    uint8_t pattern_loop_origin; /* Where to restart a E6y loop */
    uint8_t pattern_loop_count; /* How many loop passes have been done */
    bool vibrato_in_progress;
    xm_waveform_type_t vibrato_waveform;
    bool vibrato_waveform_retrigger; /* True if a new note retriggers the waveform */
    uint8_t vibrato_param;
    uint16_t vibrato_ticks; /* Position in the waveform */
    float vibrato_note_offset;
    xm_waveform_type_t tremolo_waveform;
    bool tremolo_waveform_retrigger;
    uint8_t tremolo_param;
    uint8_t tremolo_ticks;
    float tremolo_volume;
    uint8_t tremor_param;
    bool tremor_on;

    uint64_t latest_trigger;
    bool muted;

    version(XM_RAMPING)
    {
        /* These values are updated at the end of each tick, to save
         * a couple of float operations on every generated sample. */
        float[2] target_volume;

        c_ulong frame_count;
        float[XM_SAMPLE_RAMPING_POINTS] end_of_previous_sample;
    }

    float[2] actual_volume;
}

struct xm_context_t
{
    size_t ctx_size; /* Must be first, see xm_create_context_from_libxmize() */
    xm_module_t module_;
    uint32_t rate;

    uint16_t tempo;
    uint16_t bpm;
    float global_volume;
    float amplification;

    version(XM_RAMPING)
    {
        /* How much is a channel final volume allowed to change per
         * sample; this is used to avoid abrubt volume changes which
         * manifest as "clicks" in the generated sound. */
        float volume_ramp;
    }

    uint next_rand;

    uint8_t current_table_index;
    uint8_t current_row;
    uint16_t current_tick; /* Can go below 255, with high tempo and a pattern delay */
    float remaining_samples_in_tick;
    uint64_t generated_samples;

    bool position_jump;
    bool pattern_break;
    uint8_t jump_dest;
    uint8_t jump_row;


    /* Extra ticks to be played before going to the next row -
     * Used for EEy effect */
    uint16_t extra_ticks;

    uint8_t* row_loop_count; /* Array of size MAX_NUM_ROWS * module_length */
    uint8_t loop_count;
    uint8_t max_loop_count;

    xm_channel_context_t* channels;
}

// xm.c

/* .xm files are little-endian. */

/* Bounded reader macros.
* If we attempt to read the buffer out-of-bounds, pretend that the buffer is
* infinitely padded with zeroes.
*/
/*
#define READ_U8_BOUND(offset, bound) (((offset) < bound) ? (*(uint8_t*)(moddata + (offset))) : 0)
#define READ_U16_BOUND(offset, bound) ((uint16_t)READ_U8(offset) | ((uint16_t)READ_U8((offset) + 1) << 8))
#define READ_U32_BOUND(offset, bound) ((uint32_t)READ_U16(offset) | ((uint32_t)READ_U16((offset) + 2) << 16))
#define READ_MEMCPY_BOUND(ptr, offset, length, bound) memcpy_pad(ptr, length, moddata, bound, offset)

#define READ_U8(offset) READ_U8_BOUND(offset, moddata_length)
#define READ_U16(offset) READ_U16_BOUND(offset, moddata_length)
#define READ_U32(offset) READ_U32_BOUND(offset, moddata_length)
#define READ_MEMCPY(ptr, offset, length) READ_MEMCPY_BOUND(ptr, offset, length, moddata_length)
*/
void memcpy_pad(void* dst, size_t dst_len, const(void)* src, size_t src_len, size_t offset) 
{
    uint8_t* dst_c = cast(uint8_t*)dst;
    const(uint8_t)* src_c = cast(const(uint8_t)*)src;

    /* how many bytes can be copied without overrunning `src` */
    size_t copy_bytes = (src_len >= offset) ? (src_len - offset) : 0;
    copy_bytes = copy_bytes > dst_len ? dst_len : copy_bytes;

    memcpy(dst_c, src_c + offset, copy_bytes);
    /* padded bytes */
    memset(dst_c + copy_bytes, 0, dst_len - copy_bytes);
}

/** Check the module data for errors/inconsistencies.
 *
 * @returns 0 if everything looks OK. Module should be safe to load.
 */
int xm_check_sanity_preload(const(char)* module_, size_t module_length) 
{
    if(module_length < 60) {
        return 4;
    }

    if(memcmp("Extended Module: ".ptr, module_, 17) != 0) {
        return 1;
    }

    if(module_[37] != 0x1A) {
        return 2;
    }

    if(module_[59] != 0x01 || module_[58] != 0x04) {
        /* Not XM 1.04 */
        return 3;
    }

    return 0;
}

/** Check a loaded module for errors/inconsistencies.
 *
 * @returns 0 if everything looks OK.
 */

int xm_check_sanity_postload(xm_context_t* ctx) 
{   
    /* @todo: plenty of stuff to do here */

    /* Check the POT */
    for(uint8_t i = 0; i < ctx.module_.length; ++i) {
        if(ctx.module_.pattern_table[i] >= ctx.module_.num_patterns) {
            if(i+1 == ctx.module_.length && ctx.module_.length > 1) {
                /* Cheap fix */
                --ctx.module_.length;
                // DEBUG("trimming invalid POT at pos %X", i);
            } 
            else 
            {
                import core.stdc.stdio;
                printf("module has invalid POT, pos %X references nonexistent pattern %X", i, ctx.module_.pattern_table[i]);
                
                return 1;
            }
        }
    }

    return 0;
}

/** Get the number of bytes needed to store the module data in a
 * dynamically allocated blank context.
 *
 * Things that are dynamically allocated:
 * - sample data
 * - sample structures in instruments
 * - pattern data
 * - row loop count arrays
 * - pattern structures in module
 * - instrument structures in module
 * - channel contexts
 * - context structure itself

 * @returns 0 if everything looks OK.
 */
size_t xm_get_memory_needed_for_context(const char* moddata, size_t moddata_length) 
{
    size_t memory_needed = 0;
    size_t offset = 60; /* Skip the first header */
    uint16_t num_channels;
    uint16_t num_patterns;
    uint16_t num_instruments;

    /* Read the module header */

    ubyte READ_U8_BOUND(size_t offset, size_t bound)
    {
        return (offset < bound) ? *cast(uint8_t*)(moddata + offset) : 0;
    }

    ubyte READ_U8(size_t offset)
    {
        return READ_U8_BOUND(offset, moddata_length);
    }

    ushort READ_U16_BOUND(size_t offset, size_t bound)
    {
        return (cast(uint16_t)READ_U8(offset) | (cast(uint16_t)READ_U8((offset) + 1) << 8));
    }

    ushort READ_U16(size_t offset)
    {
        return READ_U16_BOUND(offset, moddata_length);
    }

    uint READ_U32_BOUND(size_t offset, size_t bound)
    {
        return (cast(uint32_t)READ_U16(offset) | (cast(uint32_t)READ_U16((offset) + 2) << 16));
    }

    uint READ_U32(size_t offset)
    {
        return READ_U32_BOUND(offset, moddata_length);
    }

    void READ_MEMCPY_BOUND(void* ptr, size_t offset, size_t length, size_t bound)
    {
        memcpy_pad(ptr, length, moddata, bound, offset);
    }

    void READ_MEMCPY(void* ptr, size_t ffset, size_t length) 
    {
        return READ_MEMCPY_BOUND(ptr, offset, length, moddata_length);
    }


    num_channels = READ_U16(offset + 8);
    num_channels = READ_U16(offset + 8);

    num_patterns = READ_U16(offset + 10);
    memory_needed += num_patterns * xm_pattern_t.sizeof;

    num_instruments = READ_U16(offset + 12);
    memory_needed += num_instruments * xm_instrument_t.sizeof;

    memory_needed += MAX_NUM_ROWS * READ_U16(offset + 4) * uint8_t.sizeof; /* Module length */

    /* Header size */
    offset += READ_U32(offset);

    /* Read pattern headers */
    for(uint16_t i = 0; i < num_patterns; ++i) {
        uint16_t num_rows;

        num_rows = READ_U16(offset + 5);
        memory_needed += num_rows * num_channels * xm_pattern_slot_t.sizeof;

        /* Pattern header length + packed pattern data size */
        offset += READ_U32(offset) + READ_U16(offset + 7);
    }

    /* Read instrument headers */
    for(uint16_t i = 0; i < num_instruments; ++i) {
        uint16_t num_samples;
        uint32_t sample_size_aggregate = 0;

        num_samples = READ_U16(offset + 27);
        memory_needed += num_samples * xm_sample_t.sizeof;

        /* Instrument header size */
        uint32_t ins_header_size = READ_U32(offset);
        if (ins_header_size == 0 || ins_header_size > INSTRUMENT_HEADER_LENGTH)
            ins_header_size = INSTRUMENT_HEADER_LENGTH;
        offset += ins_header_size;

        for(uint16_t j = 0; j < num_samples; ++j) {
            uint32_t sample_size;

            sample_size = READ_U32(offset);
            sample_size_aggregate += sample_size;
            memory_needed += sample_size;
            offset += 40; /* See comment in xm_load_module() */
        }

        offset += sample_size_aggregate;
    }

    memory_needed += num_channels * xm_channel_context_t.sizeof;
    memory_needed += xm_context_t.sizeof;

    return memory_needed;
}

/** Populate the context from module data.
 *
 * @returns pointer to the memory pool
 */
char* xm_load_module(xm_context_t* ctx, const char* moddata, size_t moddata_length, char* mempool) {
    size_t offset = 0;
    xm_module_t* mod = &(ctx.module_);

    ubyte READ_U8_BOUND(size_t offset, size_t bound)
    {
        return (offset < bound) ? *cast(uint8_t*)(moddata + offset) : 0;
    }

    ubyte READ_U8(size_t offset)
    {
        return READ_U8_BOUND(offset, moddata_length);
    }

    ushort READ_U16_BOUND(size_t offset, size_t bound)
    {
        return (cast(uint16_t)READ_U8(offset) | (cast(uint16_t)READ_U8((offset) + 1) << 8));
    }

    ushort READ_U16(size_t offset)
    {
        return READ_U16_BOUND(offset, moddata_length);
    }

    uint READ_U32_BOUND(size_t offset, size_t bound)
    {
        return (cast(uint32_t)READ_U16(offset) | (cast(uint32_t)READ_U16((offset) + 2) << 16));
    }

    uint READ_U32(size_t offset)
    {
        return READ_U32_BOUND(offset, moddata_length);
    }

    void READ_MEMCPY_BOUND(void* ptr, size_t offset, size_t length, size_t bound)
    {
        memcpy_pad(ptr, length, moddata, bound, offset);
    }

    void READ_MEMCPY(void* ptr, size_t offset, size_t length) 
    {
        return READ_MEMCPY_BOUND(ptr, offset, length, moddata_length);
    }

    /* Read XM header */
    version(XM_STRINGS)
    {
        READ_MEMCPY(mod.name.ptr, offset + 17, MODULE_NAME_LENGTH);
        READ_MEMCPY(mod.trackername.ptr, offset + 38, TRACKER_NAME_LENGTH);
    }
    offset += 60;

    /* Read module header */
    uint32_t header_size = READ_U32(offset);

    mod.length = READ_U16(offset + 4);
    mod.restart_position = READ_U16(offset + 6);
    mod.num_channels = READ_U16(offset + 8);
    mod.num_patterns = READ_U16(offset + 10);
    mod.num_instruments = READ_U16(offset + 12);

    mod.patterns = cast(xm_pattern_t*)mempool;
    mempool += mod.num_patterns * xm_pattern_t.sizeof;

    mod.instruments = cast(xm_instrument_t*)mempool;
    mempool += mod.num_instruments * xm_instrument_t.sizeof;

    uint16_t flags = cast(ushort) READ_U32(offset + 14);
    mod.frequency_type = (flags & (1 << 0)) ? XM_LINEAR_FREQUENCIES : XM_AMIGA_FREQUENCIES;

    ctx.tempo = READ_U16(offset + 16);
    ctx.bpm = READ_U16(offset + 18);

    READ_MEMCPY(mod.pattern_table.ptr, offset + 20, PATTERN_ORDER_TABLE_LENGTH);
    offset += header_size;

    /* Read patterns */
    for(uint16_t i = 0; i < mod.num_patterns; ++i) {
        uint16_t packed_patterndata_size = READ_U16(offset + 7);
        xm_pattern_t* pat = mod.patterns + i;

        pat.num_rows = READ_U16(offset + 5);

        pat.slots = cast(xm_pattern_slot_t*)mempool;
        mempool += mod.num_channels * pat.num_rows * xm_pattern_slot_t.sizeof;

        /* Pattern header length */
        offset += READ_U32(offset);

        if(packed_patterndata_size == 0) {
            /* No pattern data is present */
            memset(pat.slots, 0, xm_pattern_slot_t.sizeof * pat.num_rows * mod.num_channels);
        } else {
            /* This isn't your typical for loop */
            for(uint16_t j = 0, k = 0; j < packed_patterndata_size; ++k) {
                uint8_t note = READ_U8(offset + j);
                xm_pattern_slot_t* slot = pat.slots + k;

                if(note & (1 << 7)) {
                    /* MSB is set, this is a compressed packet */
                    ++j;

                    if(note & (1 << 0)) {
                        /* Note follows */
                        slot.note = READ_U8(offset + j);
                        ++j;
                    } else {
                        slot.note = 0;
                    }

                    if(note & (1 << 1)) {
                        /* Instrument follows */
                        slot.instrument = READ_U8(offset + j);
                        ++j;
                    } else {
                        slot.instrument = 0;
                    }

                    if(note & (1 << 2)) {
                        /* Volume column follows */
                        slot.volume_column = READ_U8(offset + j);
                        ++j;
                    } else {
                        slot.volume_column = 0;
                    }

                    if(note & (1 << 3)) {
                        /* Effect follows */
                        slot.effect_type = READ_U8(offset + j);
                        ++j;
                    } else {
                        slot.effect_type = 0;
                    }

                    if(note & (1 << 4)) {
                        /* Effect parameter follows */
                        slot.effect_param = READ_U8(offset + j);
                        ++j;
                    } else {
                        slot.effect_param = 0;
                    }
                } else {
                    /* Uncompressed packet */
                    slot.note = note;
                    slot.instrument = READ_U8(offset + j + 1);
                    slot.volume_column = READ_U8(offset + j + 2);
                    slot.effect_type = READ_U8(offset + j + 3);
                    slot.effect_param = READ_U8(offset + j + 4);
                    j += 5;
                }
            }
        }

        offset += packed_patterndata_size;
    }

    /* Read instruments */
    for(uint16_t i = 0; i < ctx.module_.num_instruments; ++i) {
        xm_instrument_t* instr = mod.instruments + i;

        /* Original FT2 would load instruments with a direct read into the
        instrument data structure that was previously zeroed. This means
        that if the declared length was less than INSTRUMENT_HEADER_LENGTH,
        all excess data would be zeroed. This is used by the XM compressor
        BoobieSqueezer. To implement this, bound all reads to the header size. */
        uint32_t ins_header_size = READ_U32(offset);
        if (ins_header_size == 0 || ins_header_size > INSTRUMENT_HEADER_LENGTH)
            ins_header_size = INSTRUMENT_HEADER_LENGTH;

        version(XM_STRINGS)
        {
            READ_MEMCPY_BOUND(instr.name.ptr, offset + 4, INSTRUMENT_NAME_LENGTH, offset + ins_header_size);
            instr.name[INSTRUMENT_NAME_LENGTH] = 0;
        }
        instr.num_samples = READ_U16_BOUND(offset + 27, offset + ins_header_size);

        if(instr.num_samples > 0) {
            /* Read extra header properties */
            READ_MEMCPY_BOUND(instr.sample_of_notes.ptr, offset + 33, NUM_NOTES, offset + ins_header_size);

            instr.volume_envelope.num_points = READ_U8_BOUND(offset + 225, offset + ins_header_size);
            if (instr.volume_envelope.num_points > NUM_ENVELOPE_POINTS)
                instr.volume_envelope.num_points = NUM_ENVELOPE_POINTS;

            instr.panning_envelope.num_points = READ_U8_BOUND(offset + 226, offset + ins_header_size);
            if (instr.panning_envelope.num_points > NUM_ENVELOPE_POINTS)
                instr.panning_envelope.num_points = NUM_ENVELOPE_POINTS;

            for(uint8_t j = 0; j < instr.volume_envelope.num_points; ++j) {
                instr.volume_envelope.points[j].frame = READ_U16_BOUND(offset + 129 + 4 * j, offset + ins_header_size);
                instr.volume_envelope.points[j].value = READ_U16_BOUND(offset + 129 + 4 * j + 2, offset + ins_header_size);
            }

            for(uint8_t j = 0; j < instr.panning_envelope.num_points; ++j) {
                instr.panning_envelope.points[j].frame = READ_U16_BOUND(offset + 177 + 4 * j, offset + ins_header_size);
                instr.panning_envelope.points[j].value = READ_U16_BOUND(offset + 177 + 4 * j + 2, offset + ins_header_size);
            }

            instr.volume_envelope.sustain_point = READ_U8_BOUND(offset + 227, offset + ins_header_size);
            instr.volume_envelope.loop_start_point = READ_U8_BOUND(offset + 228, offset + ins_header_size);
            instr.volume_envelope.loop_end_point = READ_U8_BOUND(offset + 229, offset + ins_header_size);

            instr.panning_envelope.sustain_point = READ_U8_BOUND(offset + 230, offset + ins_header_size);
            instr.panning_envelope.loop_start_point = READ_U8_BOUND(offset + 231, offset + ins_header_size);
            instr.panning_envelope.loop_end_point = READ_U8_BOUND(offset + 232, offset + ins_header_size);

            uint8_t flags_ = READ_U8_BOUND(offset + 233, offset + ins_header_size);
            instr.volume_envelope.enabled = ( flags_ & (1 << 0) ) != 0;
            instr.volume_envelope.sustain_enabled = (flags_ & (1 << 1) ) != 0;
            instr.volume_envelope.loop_enabled = ( flags_ & (1 << 2)  ) != 0;

            flags_ = READ_U8_BOUND(offset + 234, offset + ins_header_size);
            instr.panning_envelope.enabled = flags_ & (1 << 0);
            instr.panning_envelope.sustain_enabled = (flags_ & (1 << 1)) != 0;
            instr.panning_envelope.loop_enabled =    (flags_ & (1 << 2)) != 0;

            instr.vibrato_type = READ_U8_BOUND(offset + 235, offset + ins_header_size);
            if(instr.vibrato_type == 2) {
                instr.vibrato_type = 1;
            } else if(instr.vibrato_type == 1) {
                instr.vibrato_type = 2;
            }
            instr.vibrato_sweep = READ_U8_BOUND(offset + 236, offset + ins_header_size);
            instr.vibrato_depth = READ_U8_BOUND(offset + 237, offset + ins_header_size);
            instr.vibrato_rate = READ_U8_BOUND(offset + 238, offset + ins_header_size);
            instr.volume_fadeout = READ_U16_BOUND(offset + 239, offset + ins_header_size);

            instr.samples = cast(xm_sample_t*)mempool;
            mempool += instr.num_samples * xm_sample_t.sizeof;
        } else {
            instr.samples = null;
        }

        /* Instrument header size */
        offset += ins_header_size;

        for(uint16_t j = 0; j < instr.num_samples; ++j) {
            /* Read sample header */
            xm_sample_t* sample = instr.samples + j;

            sample.length = READ_U32(offset);
            sample.loop_start = READ_U32(offset + 4);
            sample.loop_length = READ_U32(offset + 8);
            sample.loop_end = sample.loop_start + sample.loop_length;
            sample.volume = cast(float)READ_U8(offset + 12) / cast(float)0x40;
            sample.finetune = cast(int8_t)READ_U8(offset + 13);

            /* Fix invalid loop definitions */
            if (sample.loop_start > sample.length)
                sample.loop_start = sample.length;
            if (sample.loop_end > sample.length)
                sample.loop_end = sample.length;
            sample.loop_length = sample.loop_end - sample.loop_start;

            uint8_t flags2 = READ_U8(offset + 14);
            if((flags2 & 3) == 0 || sample.loop_length == 0) {
                sample.loop_type = XM_NO_LOOP;
            } else if((flags2 & 3) == 1) {
                sample.loop_type = XM_FORWARD_LOOP;
            } else {
                sample.loop_type = XM_PING_PONG_LOOP;
            }

            sample.bits = (flags2 & (1 << 4)) ? 16 : 8;

            sample.panning = cast(float)READ_U8(offset + 15) / cast(float)0xFF;
            sample.relative_note = cast(int8_t)READ_U8(offset + 16);
            version( XM_STRINGS)
            {
                READ_MEMCPY(sample.name.ptr, 18, SAMPLE_NAME_LENGTH);
            }
            sample.data8 = cast(int8_t*)mempool;
            mempool += sample.length;

            if(sample.bits == 16) {
                sample.loop_start >>= 1;
                sample.loop_length >>= 1;
                sample.loop_end >>= 1;
                sample.length >>= 1;
            }

            /* Notice that, even if there's a "sample header size" in the
            instrument header, that value seems ignored, and might even
            be wrong in some corrupted modules. */
            offset += 40;
        }

        for(uint16_t j = 0; j < instr.num_samples; ++j) {
            /* Read sample data */
            xm_sample_t* sample = instr.samples + j;
            uint32_t length = sample.length;

            if(sample.bits == 16) {
                int16_t v = 0;
                for(uint32_t k = 0; k < length; ++k) {
                    v = cast(short)( v + cast(int16_t)READ_U16(offset + (k << 1)) );
                    sample.data16[k] = v;
                }
                offset += sample.length << 1;
            } else {
                int8_t v = 0;
                for(uint32_t k = 0; k < length; ++k) {
                    v = cast(byte)( v + cast(int8_t)READ_U8(offset + k) );
                    sample.data8[k] = v;
                }
                offset += sample.length;
            }
        }
    }

    return mempool;
}



// context.c -- public API

int xm_create_context_safe(xm_context_t** ctxp, const char* moddata, size_t moddata_length, uint32_t rate) 
{
	size_t bytes_needed;
	char* mempool;
	xm_context_t* ctx;

	if(XM_DEFENSIVE) 
    {
		int ret = xm_check_sanity_preload(moddata, moddata_length);
		if (ret != 0) 
        {
			//("xm_check_sanity_preload() returned %i, module is not safe to load", ret);
			return 1;
		}
	}

	bytes_needed = xm_get_memory_needed_for_context(moddata, moddata_length);
	mempool = cast(char*) malloc(bytes_needed);
	if(mempool == null && bytes_needed > 0) {
		/* malloc() failed, trouble ahead */
		//DEBUG("call to malloc() failed, returned %p", (void*)mempool);
		return 2;
	}

	/* Initialize most of the fields to 0, 0.0f, null or false depending on type */
	memset(mempool, 0, bytes_needed);

	ctx = (*ctxp = cast(xm_context_t*)mempool);
	ctx.ctx_size = bytes_needed; /* Keep original requested size for xmconvert */
    mempool += xm_context_t.sizeof;

	ctx.rate = rate;
	mempool = xm_load_module(ctx, moddata, moddata_length, mempool);

	ctx.channels = cast(xm_channel_context_t*)mempool;
	mempool += ctx.module_.num_channels * (xm_channel_context_t).sizeof;

	ctx.global_volume = 1.0f;
	ctx.amplification = 0.25f; /* XXX: some bad modules may still clip. Find out something better. */
    ctx.next_rand = 24492; // see rng

    version(XM_RAMPING)
    {
	    ctx.volume_ramp = (1.0f / 128.0f);
    }

	for(uint8_t i = 0; i < ctx.module_.num_channels; ++i) {
		xm_channel_context_t* ch = ctx.channels + i;

		ch.ping = true;
		ch.vibrato_waveform = XM_SINE_WAVEFORM;
		ch.vibrato_waveform_retrigger = true;
		ch.tremolo_waveform = XM_SINE_WAVEFORM;
		ch.tremolo_waveform_retrigger = true;

		ch.volume = ch.volume_envelope_volume = ch.fadeout_volume = 1.0f;
		ch.panning = ch.panning_envelope_panning = .5f;
		ch.actual_volume[0] = .0f;
		ch.actual_volume[1] = .0f;
	}

	ctx.row_loop_count = cast(uint8_t*)mempool;
	mempool += ctx.module_.length * MAX_NUM_ROWS * uint8_t.sizeof;

	if(XM_DEFENSIVE) {
		int ret = xm_check_sanity_postload(ctx);
		if(ret != 0) 
        {
			//DEBUG("xm_check_sanity_postload() returned %i, module is not safe to play", ret);
			xm_free_context(ctx);
            *ctxp = null;
			return 1;
		}
	}

	return 0;
}

int xm_count_remaining_samples(xm_context_t* context) {
    // TODO: implement
    return 0;
}

void xm_free_context(xm_context_t* context) {
	free(context);
}

void xm_set_max_loop_count(xm_context_t* context, uint8_t loopcnt) {
	context.max_loop_count = loopcnt;
}

uint8_t xm_get_loop_count(xm_context_t* context) {
	return context.loop_count;
}

bool xm_seek(xm_context_t* ctx, int pot, int row, int tick) 
{
    // TODO: check validity of position, return false otherwise.
	ctx.current_table_index = cast(uint8_t)pot;
	ctx.current_row = cast(uint8_t) row;
	ctx.current_tick = cast(uint16_t) tick;
	ctx.remaining_samples_in_tick = 0;
    return true;
}

bool xm_mute_channel(xm_context_t* ctx, uint16_t channel, bool mute) {
	bool old = ctx.channels[channel - 1].muted;
	ctx.channels[channel - 1].muted = mute;
	return old;
}

bool xm_mute_instrument(xm_context_t* ctx, uint16_t instr, bool mute) {
	bool old = ctx.module_.instruments[instr - 1].muted;
	ctx.module_.instruments[instr - 1].muted = mute;
	return old;
}



version(XM_STRINGS)
{
    const(char)* xm_get_module_name(xm_context_t* ctx) 
    {
	    return ctx.module_.name.ptr;
    }

    const(char)* xm_get_tracker_name(xm_context_t* ctx) 
    {
	    return ctx.module_.trackername.ptr;
    }
}
else
{
    const(char)* xm_get_module_name(xm_context_t* ctx) 
    {
	    return null;
    }

    const(char)* xm_get_tracker_name(xm_context_t* ctx) 
    {
	    return null;
    }
}

uint16_t xm_get_number_of_channels(xm_context_t* ctx) {
	return ctx.module_.num_channels;
}

uint16_t xm_get_module_length(xm_context_t* ctx) {
	return ctx.module_.length;
}

uint16_t xm_get_number_of_patterns(xm_context_t* ctx) {
	return ctx.module_.num_patterns;
}

uint16_t xm_get_number_of_rows(xm_context_t* ctx, uint16_t pattern) {
	return ctx.module_.patterns[pattern].num_rows;
}

uint16_t xm_get_number_of_instruments(xm_context_t* ctx) {
	return ctx.module_.num_instruments;
}

uint16_t xm_get_number_of_samples(xm_context_t* ctx, uint16_t instrument) {
	return ctx.module_.instruments[instrument - 1].num_samples;
}

void* xm_get_sample_waveform(xm_context_t* ctx, uint16_t i, uint16_t s, size_t* size, uint8_t* bits) {
	*size = ctx.module_.instruments[i - 1].samples[s].length;
	*bits = ctx.module_.instruments[i - 1].samples[s].bits;
	return ctx.module_.instruments[i - 1].samples[s].data8;
}

void xm_get_playing_speed(xm_context_t* ctx, uint16_t* bpm, uint16_t* tempo) {
	if(bpm) *bpm = ctx.bpm;
	if(tempo) *tempo = ctx.tempo;
}

void xm_get_position(xm_context_t* ctx, uint8_t* pattern_index, uint8_t* pattern, uint8_t* row, uint64_t* samples) {
	if(pattern_index) *pattern_index = ctx.current_table_index;
	if(pattern) *pattern = ctx.module_.pattern_table[ctx.current_table_index];
	if(row) *row = ctx.current_row;
	if(samples) *samples = ctx.generated_samples;
}

uint64_t xm_get_latest_trigger_of_instrument(xm_context_t* ctx, uint16_t instr) {
	return ctx.module_.instruments[instr - 1].latest_trigger;
}

uint64_t xm_get_latest_trigger_of_sample(xm_context_t* ctx, uint16_t instr, uint16_t sample) {
	return ctx.module_.instruments[instr - 1].samples[sample].latest_trigger;
}

uint64_t xm_get_latest_trigger_of_channel(xm_context_t* ctx, uint16_t chn) {
	return ctx.channels[chn - 1].latest_trigger;
}

bool xm_is_channel_active(xm_context_t* ctx, uint16_t chn) {
	xm_channel_context_t* ch = ctx.channels + (chn - 1);
	return ch.instrument != null && ch.sample != null && ch.sample_position >= 0;
}

float xm_get_frequency_of_channel(xm_context_t* ctx, uint16_t chn) {
	return ctx.channels[chn - 1].frequency;
}

float xm_get_volume_of_channel(xm_context_t* ctx, uint16_t chn) {
	return ctx.channels[chn - 1].volume * ctx.global_volume;
}

float xm_get_panning_of_channel(xm_context_t* ctx, uint16_t chn) {
	return ctx.channels[chn - 1].panning;
}

uint16_t xm_get_instrument_of_channel(xm_context_t* ctx, uint16_t chn) 
{
	xm_channel_context_t* ch = ctx.channels + (chn - 1);
	if(ch.instrument == null) return 0;
	return cast(ushort)( 1 + (ch.instrument - ctx.module_.instruments) );
}


// play.c

/* Author: Romain "Artefact2" Dalmaso <artefact2@gmail.com> */
/* Contributor: Daniel Oaks <daniel@danieloaks.net> */

/* This program is free software. It comes without any warranty, to the
* extent permitted by applicable law. You can redistribute it and/or
* modify it under the terms of the Do What The Fuck You Want To Public
* License, Version 2, as published by Sam Hocevar. See
* http://sam.zoy.org/wtfpl/COPYING for more details. */

/* ----- Other oddities ----- */

enum XM_TRIGGER_KEEP_VOLUME = (1 << 0);
enum  XM_TRIGGER_KEEP_PERIOD = (1 << 1);
enum  XM_TRIGGER_KEEP_SAMPLE_POSITION = (1 << 2);
enum  XM_TRIGGER_KEEP_ENVELOPE = (1 << 3);

enum AMIGA_FREQ_SCALE = 1024;

static immutable uint32_t[13] amiga_frequencies =
[
	1712*AMIGA_FREQ_SCALE, 1616*AMIGA_FREQ_SCALE, 1525*AMIGA_FREQ_SCALE, 1440*AMIGA_FREQ_SCALE, /* C-2, C#2, D-2, D#2 */
	1357*AMIGA_FREQ_SCALE, 1281*AMIGA_FREQ_SCALE, 1209*AMIGA_FREQ_SCALE, 1141*AMIGA_FREQ_SCALE, /* E-2, F-2, F#2, G-2 */
	1077*AMIGA_FREQ_SCALE, 1017*AMIGA_FREQ_SCALE,  961*AMIGA_FREQ_SCALE,  907*AMIGA_FREQ_SCALE, /* G#2, A-2, A#2, B-2 */
	856*AMIGA_FREQ_SCALE,                                                                       /* C-3 */
];

static immutable float[16] multi_retrig_add = 
[
    0.0f,  -1.0f,  -2.0f,  -4.0f,  /* 0, 1, 2, 3 */
	-8.0f, -16.0f,   0.0f,   0.0f,  /* 4, 5, 6, 7 */
    0.0f,   1.0f,   2.0f,   4.0f,  /* 8, 9, A, B */
    8.0f,  16.0f,   0.0f,   0.0f   /* C, D, E, F */
];

static const float[16] multi_retrig_multiply =
[
	1.0f,   1.0f,  1.0f,        1.0f,  /* 0, 1, 2, 3 */
	1.0f,   1.0f,   .6666667f,  .5f, /* 4, 5, 6, 7 */
	1.0f,   1.0f,  1.0f,        1.0f,  /* 8, 9, A, B */
	1.0f,   1.0f,  1.5f,       2.0f   /* C, D, E, F */
];

void XM_SLIDE_TOWARDS(ref float val, float goal, float incr)
{
    if (val > goal)
    {
        val -= incr;
        if (val < goal) val = goal;
    }
    else if (val < goal)
    {
        val += incr;
        if (val > goal) val = goal;
    }
}

float XM_LERP(float u, float v, float t)
{
    return u + t * (v - u);
}

float XM_INVERSE_LERP(float u, float v, float lerp)
{
    return  (lerp - u) / (v - u);
}

bool NOTE_IS_VALID(int n)
{
    return (n > 0) && (n < 97);
}

/* ----- Function definitions ----- */

float xm_waveform(xm_context_t* context, xm_waveform_type_t waveform, uint8_t step) {
	step %= 0x40;
	switch(waveform) 
    {

        case XM_SINE_WAVEFORM:
            /* Why not use a table? For saving space, and because there's
            * very very little actual performance gain. */
            return -sin(2.0f * 3.141592f * cast(float)step / cast(float)0x40);

        case XM_RAMP_DOWN_WAVEFORM:
            /* Ramp down: 1.0f when step = 0; -1.0f when step = 0x40 */
            return cast(float)(0x20 - step) / 0x20;

        case XM_SQUARE_WAVEFORM:
            /* Square with a 50% duty */
            return (step >= 0x20) ? 1.0f : -1.0f;

        case XM_RANDOM_WAVEFORM:
            /* Use the POSIX.1-2001 example, just to be deterministic
            * across different machines */
            context.next_rand = context.next_rand * 1103515245 + 12345;
            return cast(float)((context.next_rand >> 16) & 0x7FFF) / cast(float)0x4000 - 1.0f;

        case XM_RAMP_UP_WAVEFORM:
            /* Ramp up: -1.0f when step = 0; 1.0f when step = 0x40 */
            return cast(float)(step - 0x20) / 0x20;

        default:
            break;

	}

	return .0f;
}

void xm_autovibrato(xm_context_t* ctx, xm_channel_context_t* ch) {
	if(ch.instrument == null || ch.instrument.vibrato_depth == 0){
		if (ch.autovibrato_note_offset){
			ch.autovibrato_note_offset = 0.0f;
			xm_update_frequency(ctx, ch);
		}
		return;
	}
	xm_instrument_t* instr = ch.instrument;
	float sweep = 1.0f;

	if(ch.autovibrato_ticks < instr.vibrato_sweep) {
		/* No idea if this is correct, but it sounds close enough… */
		sweep = XM_LERP(0.0f, 1.0f, cast(float)ch.autovibrato_ticks / cast(float)instr.vibrato_sweep);
	}

	uint step = ((ch.autovibrato_ticks++) * instr.vibrato_rate) >> 2;
	ch.autovibrato_note_offset = .25f * xm_waveform(ctx, instr.vibrato_type, cast(ubyte)step)
		* cast(float)instr.vibrato_depth / cast(float)0xF * sweep;
	xm_update_frequency(ctx, ch);
}

void xm_vibrato(xm_context_t* ctx, xm_channel_context_t* ch, uint8_t param) {
	ch.vibrato_ticks += (param >> 4);
	ch.vibrato_note_offset =
		-2.0f
		* xm_waveform(ctx, ch.vibrato_waveform, cast(ubyte)ch.vibrato_ticks)
		* cast(float)(param & 0x0F) / cast(float)0xF;
	xm_update_frequency(ctx, ch);
}

void xm_tremolo(xm_context_t* ctx, xm_channel_context_t* ch, uint8_t param, uint16_t pos) {
	uint step = pos * (param >> 4);
	/* Not so sure about this, it sounds correct by ear compared with
    * MilkyTracker, but it could come from other bugs */
	ch.tremolo_volume = -1.0f * xm_waveform(ctx, ch.tremolo_waveform, cast(ubyte)step)
		* cast(float)(param & 0x0F) / cast(float)0xF;
}

void xm_arpeggio(xm_context_t* ctx, xm_channel_context_t* ch, uint8_t param, uint16_t tick) {
	switch(tick % 3) {
        case 0:
            ch.arp_in_progress = false;
            ch.arp_note_offset = 0;
            break;
        case 2:
            ch.arp_in_progress = true;
            ch.arp_note_offset = param >> 4;
            break;
        case 1:
            ch.arp_in_progress = true;
            ch.arp_note_offset = param & 0x0F;
            break;

        default:
            assert(false);
	}

	xm_update_frequency(ctx, ch);
}

void xm_tone_portamento(xm_context_t* ctx, xm_channel_context_t* ch) 
{
	/* 3xx called without a note, wait until we get an actual
    * target note. */
	if(ch.tone_portamento_target_period == 0.0f) 
        return;

	if(ch.period != ch.tone_portamento_target_period) 
    {
		XM_SLIDE_TOWARDS(ch.period,
		                 ch.tone_portamento_target_period,
		                 (ctx.module_.frequency_type == XM_LINEAR_FREQUENCIES ? 4.0f : 1.0f) * ch.tone_portamento_param);
		xm_update_frequency(ctx, ch);
	}
}

void xm_pitch_slide(xm_context_t* ctx, xm_channel_context_t* ch, float period_offset) {
	/* Don't ask about the 4.0f coefficient. I found mention of it
    * nowhere. Found by ear™. */
	if(ctx.module_.frequency_type == XM_LINEAR_FREQUENCIES) {
		period_offset *= 4.0f;
	}

	ch.period += period_offset;
    if (ch.period < 0) ch.period = 0;
	/* XXX: upper bound of period ? */

	xm_update_frequency(ctx, ch);
}

void xm_panning_slide(xm_channel_context_t* ch, uint8_t rawval) {
	float f;

	if((rawval & 0xF0) && (rawval & 0x0F)) {
		/* Illegal state */
		return;
	}

	if(rawval & 0xF0) {
		/* Slide right */
		f = cast(float)(rawval >> 4) / cast(float)0xFF;
		ch.panning += f;
        if (ch.panning > 1) 
            ch.panning = 1;
	} else {
		/* Slide left */
		f = cast(float)(rawval & 0x0F) / cast(float)0xFF;
		ch.panning -= f;
        if (ch.panning < 0)
            ch.panning = 0;
	}
}

void xm_volume_slide(xm_channel_context_t* ch, uint8_t rawval) {
	float f;

	if((rawval & 0xF0) && (rawval & 0x0F)) {
		/* Illegal state */
		return;
	}

	if(rawval & 0xF0) {
		/* Slide up */
		f = cast(float)(rawval >> 4) / cast(float)0x40;
		ch.volume += f;
        if (ch.volume > 1)
            ch.volume = 1;
	} else {
		/* Slide down */
		f = cast(float)(rawval & 0x0F) / cast(float)0x40;
		ch.volume -= f;
        if (ch.volume < 0)
            ch.volume = 0;
	}
}

float xm_envelope_lerp(xm_envelope_point_t* a, xm_envelope_point_t* b, uint16_t pos) {
	/* Linear interpolation between two envelope points */
	if(pos <= a.frame) return a.value;
	else if(pos >= b.frame) return b.value;
	else {
		float p = cast(float)(pos - a.frame) / cast(float)(b.frame - a.frame);
		return a.value * (1 - p) + b.value * p;
	}
}

void xm_post_pattern_change(xm_context_t* ctx) {
	/* Loop if necessary */
	if(ctx.current_table_index >= ctx.module_.length) 
    {
		ctx.current_table_index = cast(ubyte)(ctx.module_.restart_position);
	}
}

float xm_linear_period(float note) {
	return 7680.0f - note * 64.0f;
}

float xm_linear_frequency(float period) {
	return 8363.0f * pow(2.0f, (4608.0f - period) / 768.0f);
}

float xm_amiga_period(float note) {
	uint intnote = cast(uint)note;
	uint8_t a = intnote % 12;
	int8_t octave = cast(int8_t)(note / 12.0f - 2);
	int32_t p1 = amiga_frequencies[a], p2 = amiga_frequencies[a + 1];

	if(octave > 0) {
		p1 >>= octave;
		p2 >>= octave;
	} else if(octave < 0) {
		p1 <<= (-cast(int)octave);
		p2 <<= (-cast(int)octave);
	}

	return XM_LERP(p1, p2, note - intnote) / AMIGA_FREQ_SCALE;
}

float xm_amiga_frequency(float period) {
	if(period == .0f) return .0f;

	/* This is the PAL value. No reason to choose this one over the
    * NTSC value. */
	return 7093789.2f / (period * 2.0f);
}

float xm_period(xm_context_t* ctx, float note) 
{
	switch(ctx.module_.frequency_type) 
    {
        case XM_LINEAR_FREQUENCIES:
            return xm_linear_period(note);
        case XM_AMIGA_FREQUENCIES:
            return xm_amiga_period(note);
        default:
	}
	return .0f;
}

float xm_frequency(xm_context_t* ctx, float period, float note_offset, float period_offset) {
	uint8_t a;
	int8_t octave;
	float note;
	int32_t p1, p2;

	switch(ctx.module_.frequency_type) 
    {

        case XM_LINEAR_FREQUENCIES:
            return xm_linear_frequency(period - 64.0f * note_offset - 16.0f * period_offset);

        case XM_AMIGA_FREQUENCIES:
            if(note_offset == 0) {
                /* A chance to escape from insanity */
                return xm_amiga_frequency(period + 16.0f * period_offset);
            }

            /* FIXME: this is very crappy at best */
            a = octave = 0;

            /* Find the octave of the current period */
            period *= AMIGA_FREQ_SCALE;
            if(period > amiga_frequencies[0]) {
                --octave;
                while(period > (amiga_frequencies[0] << (-cast(int)octave))) --octave;
            } else if(period < amiga_frequencies[12]) {
                ++octave;
                while(period < (amiga_frequencies[12] >> octave)) ++octave;
            }

            /* Find the smallest note closest to the current period */
            for(uint8_t i = 0; i < 12; ++i) {
                p1 = amiga_frequencies[i], p2 = amiga_frequencies[i + 1];

                if(octave > 0) {
                    p1 >>= octave;
                    p2 >>= octave;
                } else if(octave < 0) {
                    p1 <<= (-cast(int)octave);
                    p2 <<= (-cast(int)octave);
                }

                if(p2 <= period && period <= p1) {
                    a = i;
                    break;
                }
            }

            /*if(XM_DEBUG && (p1 < period || p2 > period)) 
            {
                //DEBUG("%" PRId32 " <= %f <= %" PRId32 " should hold but doesn't, this is a bug", p2, period, p1);
                assert(false);
            }*/

            note = 12.0f * (octave + 2) + a + XM_INVERSE_LERP(p1, p2, period);

            return xm_amiga_frequency(xm_amiga_period(note + note_offset) + 16.0f * period_offset);

        default:
	}

	return .0f;
}

void xm_update_frequency(xm_context_t* ctx, xm_channel_context_t* ch) {
	ch.frequency = xm_frequency(
                                 ctx, ch.period,
                                 ch.arp_note_offset,
                                 ch.vibrato_note_offset + ch.autovibrato_note_offset
                                 );
	ch.step = ch.frequency / ctx.rate;
}

void xm_handle_note_and_instrument(xm_context_t* ctx, xm_channel_context_t* ch,
										  xm_pattern_slot_t* s) {
                                            if(s.instrument > 0) {
                                                if(ch.current.HAS_TONE_PORTAMENTO() && ch.instrument != null && ch.sample != null) {
                                                    /* Tone portamento in effect, unclear stuff happens */
                                                    xm_trigger_note(ctx, ch, XM_TRIGGER_KEEP_PERIOD | XM_TRIGGER_KEEP_SAMPLE_POSITION);
                                                } else if(s.note == 0 && ch.sample != null) {
                                                    /* Ghost instrument, trigger note */
                                                    /* Sample position is kept, but envelopes are reset */
                                                    xm_trigger_note(ctx, ch, XM_TRIGGER_KEEP_SAMPLE_POSITION);
                                                } else if(s.instrument > ctx.module_.num_instruments) {
                                                    /* Invalid instrument, Cut current note */
                                                    xm_cut_note(ch);
                                                    ch.instrument = null;
                                                    ch.sample = null;
                                                } else {
                                                    ch.instrument = ctx.module_.instruments + (s.instrument - 1);
                                                }
                                            }

                                            if(NOTE_IS_VALID(s.note)) {
                                                /* Yes, the real note number is s.note -1. Try finding
                                                * THAT in any of the specs! :-) */

                                                xm_instrument_t* instr = ch.instrument;

                                                if(ch.current.HAS_TONE_PORTAMENTO() && instr != null && ch.sample != null) {
                                                    /* Tone portamento in effect */
                                                    ch.note = s.note + ch.sample.relative_note + ch.sample.finetune / 128.0f - 1.0f;
                                                    ch.tone_portamento_target_period = xm_period(ctx, ch.note);
                                                } else if(instr == null || ch.instrument.num_samples == 0) {
                                                    /* Bad instrument */
                                                    xm_cut_note(ch);
                                                } else {
                                                    if(instr.sample_of_notes[s.note - 1] < instr.num_samples) {
                                                        version(XM_RAMPING)
                                                        {
                                                            for(uint z = 0; z < XM_SAMPLE_RAMPING_POINTS; ++z) {
                                                                ch.end_of_previous_sample[z] = xm_next_of_sample(ch);
                                                            }
                                                            ch.frame_count = 0;
                                                        }
                                                        ch.sample = instr.samples + instr.sample_of_notes[s.note - 1];
                                                        ch.orig_note = ch.note = s.note + ch.sample.relative_note
                                                            + ch.sample.finetune / 128.0f - 1.0f;
                                                        if(s.instrument > 0) {
                                                            xm_trigger_note(ctx, ch, 0);
                                                        } else {
                                                            /* Ghost note: keep old volume */
                                                            xm_trigger_note(ctx, ch, XM_TRIGGER_KEEP_VOLUME);
                                                        }
                                                    } else {
                                                        /* Bad sample */
                                                        xm_cut_note(ch);
                                                    }
                                                }
                                            } else if(s.note == 97) {
                                                /* Key Off */
                                                xm_key_off(ch);
                                            }

                                            switch(s.volume_column >> 4) {

                                                case 0x5:
                                                    if(s.volume_column > 0x50) break;
                                                    goto case 0x1;

                                                case 0x1:
                                                case 0x2:
                                                case 0x3:
                                                case 0x4:
                                                    /* Set volume */
                                                    ch.volume = cast(float)(s.volume_column - 0x10) / cast(float)0x40;
                                                    break;

                                                case 0x8: /* Fine volume slide down */
                                                    xm_volume_slide(ch, s.volume_column & 0x0F);
                                                    break;

                                                case 0x9: /* Fine volume slide up */
                                                    xm_volume_slide(ch, cast(ubyte)(s.volume_column << 4));
                                                    break;

                                                case 0xA: /* Set vibrato speed */
                                                    ch.vibrato_param = (ch.vibrato_param & 0x0F) | ((s.volume_column & 0x0F) << 4);
                                                    break;

                                                case 0xC: /* Set panning */
                                                    ch.panning = cast(float)(
                                                                          ((s.volume_column & 0x0F) << 4) | (s.volume_column & 0x0F)
                                                                          ) / cast(float)0xFF;
                                                    break;

                                                case 0xF: /* Tone portamento */
                                                    if(s.volume_column & 0x0F) {
                                                        ch.tone_portamento_param = ((s.volume_column & 0x0F) << 4)
                                                            | (s.volume_column & 0x0F);
                                                    }
                                                    break;

                                                default:
                                                    break;

                                            }

                                            switch(s.effect_type) {

                                                case 1: /* 1xx: Portamento up */
                                                    if(s.effect_param > 0) {
                                                        ch.portamento_up_param = s.effect_param;
                                                    }
                                                    break;

                                                case 2: /* 2xx: Portamento down */
                                                    if(s.effect_param > 0) {
                                                        ch.portamento_down_param = s.effect_param;
                                                    }
                                                    break;

                                                case 3: /* 3xx: Tone portamento */
                                                    if(s.effect_param > 0) {
                                                        ch.tone_portamento_param = s.effect_param;
                                                    }
                                                    break;

                                                case 4: /* 4xy: Vibrato */
                                                    if(s.effect_param & 0x0F) {
                                                        /* Set vibrato depth */
                                                        ch.vibrato_param = (ch.vibrato_param & 0xF0) | (s.effect_param & 0x0F);
                                                    }
                                                    if(s.effect_param >> 4) {
                                                        /* Set vibrato speed */
                                                        ch.vibrato_param = (s.effect_param & 0xF0) | (ch.vibrato_param & 0x0F);
                                                    }
                                                    break;

                                                case 5: /* 5xy: Tone portamento + Volume slide */
                                                    if(s.effect_param > 0) {
                                                        ch.volume_slide_param = s.effect_param;
                                                    }
                                                    break;

                                                case 6: /* 6xy: Vibrato + Volume slide */
                                                    if(s.effect_param > 0) {
                                                        ch.volume_slide_param = s.effect_param;
                                                    }
                                                    break;

                                                case 7: /* 7xy: Tremolo */
                                                    if(s.effect_param & 0x0F) {
                                                        /* Set tremolo depth */
                                                        ch.tremolo_param = (ch.tremolo_param & 0xF0) | (s.effect_param & 0x0F);
                                                    }
                                                    if(s.effect_param >> 4) {
                                                        /* Set tremolo speed */
                                                        ch.tremolo_param = (s.effect_param & 0xF0) | (ch.tremolo_param & 0x0F);
                                                    }
                                                    break;

                                                case 8: /* 8xx: Set panning */
                                                    ch.panning = cast(float)s.effect_param / cast(float)0xFF;
                                                    break;

                                                case 9: /* 9xx: Sample offset */
                                                    if(ch.sample != null && NOTE_IS_VALID(s.note)) {
                                                        uint32_t final_offset = s.effect_param << (ch.sample.bits == 16 ? 7 : 8);
                                                        if(final_offset >= ch.sample.length) {
                                                            /* Pretend the sample dosen't loop and is done playing */
                                                            ch.sample_position = -1;
                                                            break;
                                                        }
                                                        ch.sample_position = final_offset;
                                                    }
                                                    break;

                                                case 0xA: /* Axy: Volume slide */
                                                    if(s.effect_param > 0) {
                                                        ch.volume_slide_param = s.effect_param;
                                                    }
                                                    break;

                                                case 0xB: /* Bxx: Position jump */
                                                    if(s.effect_param < ctx.module_.length) {
                                                        ctx.position_jump = true;
                                                        ctx.jump_dest = s.effect_param;
                                                        ctx.jump_row = 0;
                                                    }
                                                    break;

                                                case 0xC: /* Cxx: Set volume */
                                                    ch.volume = cast(float)((s.effect_param > 0x40)
                                                                         ? 0x40 : s.effect_param) / cast(float)0x40;
                                                    break;

                                                case 0xD: /* Dxx: Pattern break */
                                                    /* Jump after playing this line */
                                                    ctx.pattern_break = true;
                                                    ctx.jump_row = (s.effect_param >> 4) * 10 + (s.effect_param & 0x0F);
                                                    break;

                                                case 0xE: /* EXy: Extended command */
                                                    switch(s.effect_param >> 4) {

                                                        case 1: /* E1y: Fine portamento up */
                                                            if(s.effect_param & 0x0F) {
                                                                ch.fine_portamento_up_param = s.effect_param & 0x0F;
                                                            }
                                                            xm_pitch_slide(ctx, ch, -cast(int)(ch.fine_portamento_up_param));
                                                            break;

                                                        case 2: /* E2y: Fine portamento down */
                                                            if(s.effect_param & 0x0F) {
                                                                ch.fine_portamento_down_param = s.effect_param & 0x0F;
                                                            }
                                                            xm_pitch_slide(ctx, ch, ch.fine_portamento_down_param);
                                                            break;

                                                        case 4: /* E4y: Set vibrato control */
                                                            ch.vibrato_waveform = s.effect_param & 3;
                                                            ch.vibrato_waveform_retrigger = !((s.effect_param >> 2) & 1);
                                                            break;

                                                        case 5: /* E5y: Set finetune */
                                                            if(NOTE_IS_VALID(ch.current.note) && ch.sample != null) {
                                                                ch.note = ch.current.note + ch.sample.relative_note +
                                                                    cast(float)(((s.effect_param & 0x0F) - 8) << 4) / 128.0f - 1.0f;
                                                                ch.period = xm_period(ctx, ch.note);
                                                                xm_update_frequency(ctx, ch);
                                                            }
                                                            break;

                                                        case 6: /* E6y: Pattern loop */
                                                            if(s.effect_param & 0x0F) {
                                                                if((s.effect_param & 0x0F) == ch.pattern_loop_count) {
                                                                    /* Loop is over */
                                                                    ch.pattern_loop_count = 0;
                                                                    break;
                                                                }

                                                                /* Jump to the beginning of the loop */
                                                                ch.pattern_loop_count++;
                                                                ctx.position_jump = true;
                                                                ctx.jump_row = ch.pattern_loop_origin;
                                                                ctx.jump_dest = ctx.current_table_index;
                                                            } else {
                                                                /* Set loop start point */
                                                                ch.pattern_loop_origin = ctx.current_row;
                                                                /* Replicate FT2 E60 bug */
                                                                ctx.jump_row = ch.pattern_loop_origin;
                                                            }
                                                            break;

                                                        case 7: /* E7y: Set tremolo control */
                                                            ch.tremolo_waveform = s.effect_param & 3;
                                                            ch.tremolo_waveform_retrigger = !((s.effect_param >> 2) & 1);
                                                            break;

                                                        case 0xA: /* EAy: Fine volume slide up */
                                                            if(s.effect_param & 0x0F) {
                                                                ch.fine_volume_slide_param = s.effect_param & 0x0F;
                                                            }
                                                            xm_volume_slide(ch, cast(ubyte)(ch.fine_volume_slide_param << 4));
                                                            break;

                                                        case 0xB: /* EBy: Fine volume slide down */
                                                            if(s.effect_param & 0x0F) {
                                                                ch.fine_volume_slide_param = s.effect_param & 0x0F;
                                                            }
                                                            xm_volume_slide(ch, ch.fine_volume_slide_param);
                                                            break;

                                                        case 0xD: /* EDy: Note delay */
                                                            /* XXX: figure this out better. EDx triggers
                                                            * the note even when there no note and no
                                                            * instrument. But ED0 acts like like a ghost
                                                            * note, EDx (x ≠ 0) does not. */
                                                            if(s.note == 0 && s.instrument == 0) {
                                                                uint flags = XM_TRIGGER_KEEP_VOLUME;

                                                                if(ch.current.effect_param & 0x0F) {
                                                                    ch.note = ch.orig_note;
                                                                    xm_trigger_note(ctx, ch, flags);
                                                                } else {
                                                                    xm_trigger_note(
                                                                                    ctx, ch,
                                                                                    flags
                                                                                    | XM_TRIGGER_KEEP_PERIOD
                                                                                    | XM_TRIGGER_KEEP_SAMPLE_POSITION
                                                                                    );
                                                                }
                                                            }
                                                            break;

                                                        case 0xE: /* EEy: Pattern delay */
                                                            ctx.extra_ticks = cast(ushort)( (ch.current.effect_param & 0x0F) * ctx.tempo );
                                                            break;

                                                        default:
                                                            break;

                                                    }
                                                    break;

                                                case 0xF: /* Fxx: Set tempo/BPM */
                                                    if(s.effect_param > 0) {
                                                        if(s.effect_param <= 0x1F) {
                                                            ctx.tempo = s.effect_param;
                                                        } else {
                                                            ctx.bpm = s.effect_param;
                                                        }
                                                    }
                                                    break;

                                                case 16: /* Gxx: Set global volume */
                                                    ctx.global_volume = cast(float)((s.effect_param > 0x40)
                                                                                 ? 0x40 : s.effect_param) / cast(float)0x40;
                                                    break;

                                                case 17: /* Hxy: Global volume slide */
                                                    if(s.effect_param > 0) {
                                                        ch.global_volume_slide_param = s.effect_param;
                                                    }
                                                    break;

                                                case 21: /* Lxx: Set envelope position */
                                                    ch.volume_envelope_frame_count = s.effect_param;
                                                    ch.panning_envelope_frame_count = s.effect_param;
                                                    break;

                                                case 25: /* Pxy: Panning slide */
                                                    if(s.effect_param > 0) {
                                                        ch.panning_slide_param = s.effect_param;
                                                    }
                                                    break;

                                                case 27: /* Rxy: Multi retrig note */
                                                    if(s.effect_param > 0) {
                                                        if((s.effect_param >> 4) == 0) {
                                                            /* Keep previous x value */
                                                            ch.multi_retrig_param = (ch.multi_retrig_param & 0xF0) | (s.effect_param & 0x0F);
                                                        } else {
                                                            ch.multi_retrig_param = s.effect_param;
                                                        }
                                                    }
                                                    break;

                                                case 29: /* Txy: Tremor */
                                                    if(s.effect_param > 0) {
                                                        /* Tremor x and y params do not appear to be separately
                                                        * kept in memory, unlike Rxy */
                                                        ch.tremor_param = s.effect_param;
                                                    }
                                                    break;

                                                case 33: /* Xxy: Extra stuff */
                                                    switch(s.effect_param >> 4) {

                                                        case 1: /* X1y: Extra fine portamento up */
                                                            if(s.effect_param & 0x0F) {
                                                                ch.extra_fine_portamento_up_param = s.effect_param & 0x0F;
                                                            }
                                                            xm_pitch_slide(ctx, ch, -1.0f * ch.extra_fine_portamento_up_param);
                                                            break;

                                                        case 2: /* X2y: Extra fine portamento down */
                                                            if(s.effect_param & 0x0F) {
                                                                ch.extra_fine_portamento_down_param = s.effect_param & 0x0F;
                                                            }
                                                            xm_pitch_slide(ctx, ch, ch.extra_fine_portamento_down_param);
                                                            break;

                                                        default:
                                                            break;

                                                    }
                                                    break;

                                                default:
                                                    break;

                                            }
                                          }

void xm_trigger_note(xm_context_t* ctx, xm_channel_context_t* ch, uint flags) {
	if(!(flags & XM_TRIGGER_KEEP_SAMPLE_POSITION)) {
		ch.sample_position = 0.0f;
		ch.ping = true;
	}

	if(ch.sample != null) {
		if(!(flags & XM_TRIGGER_KEEP_VOLUME)) {
			ch.volume = ch.sample.volume;
		}

		ch.panning = ch.sample.panning;
	}

	if(!(flags & XM_TRIGGER_KEEP_ENVELOPE)) {
		ch.sustained = true;
		ch.fadeout_volume = ch.volume_envelope_volume = 1.0f;
		ch.panning_envelope_panning = .5f;
		ch.volume_envelope_frame_count = ch.panning_envelope_frame_count = 0;
	}
	ch.vibrato_note_offset = 0.0f;
	ch.tremolo_volume = 0.0f;
	ch.tremor_on = false;

	ch.autovibrato_ticks = 0;

	if(ch.vibrato_waveform_retrigger) {
		ch.vibrato_ticks = 0; /* XXX: should the waveform itself also
        * be reset to sine? */
	}
	if(ch.tremolo_waveform_retrigger) {
		ch.tremolo_ticks = 0;
	}

	if(!(flags & XM_TRIGGER_KEEP_PERIOD)) {
		ch.period = xm_period(ctx, ch.note);
		xm_update_frequency(ctx, ch);
	}

	ch.latest_trigger = ctx.generated_samples;
	if(ch.instrument != null) {
		ch.instrument.latest_trigger = ctx.generated_samples;
	}
	if(ch.sample != null) {
		ch.sample.latest_trigger = ctx.generated_samples;
	}
}

void xm_cut_note(xm_channel_context_t* ch) {
	/* NB: this is not the same as Key Off */
	ch.volume = .0f;
}

void xm_key_off(xm_channel_context_t* ch) {
	/* Key Off */
	ch.sustained = false;

	/* If no volume envelope is used, also cut the note */
	if(ch.instrument == null || !ch.instrument.volume_envelope.enabled) {
		xm_cut_note(ch);
	}
}

void xm_row(xm_context_t* ctx) {
	if(ctx.position_jump) {
		ctx.current_table_index = ctx.jump_dest;
		ctx.current_row = ctx.jump_row;
		ctx.position_jump = false;
		ctx.pattern_break = false;
		ctx.jump_row = 0;
		xm_post_pattern_change(ctx);
	} else if(ctx.pattern_break) {
		ctx.current_table_index++;
		ctx.current_row = ctx.jump_row;
		ctx.pattern_break = false;
		ctx.jump_row = 0;
		xm_post_pattern_change(ctx);
	}

	xm_pattern_t* cur = ctx.module_.patterns + ctx.module_.pattern_table[ctx.current_table_index];
	bool in_a_loop = false;

	/* Read notes… */
	for(uint8_t i = 0; i < ctx.module_.num_channels; ++i) {
		xm_pattern_slot_t* s = cur.slots + ctx.current_row * ctx.module_.num_channels + i;
		xm_channel_context_t* ch = ctx.channels + i;

		ch.current = s;

		if(s.effect_type != 0xE || s.effect_param >> 4 != 0xD) {
			xm_handle_note_and_instrument(ctx, ch, s);
		} else {
			ch.note_delay_param = s.effect_param & 0x0F;
		}

		if(!in_a_loop && ch.pattern_loop_count > 0) {
			in_a_loop = true;
		}
	}

	if(!in_a_loop) {
		/* No E6y loop is in effect (or we are in the first pass) */
		ctx.loop_count = (ctx.row_loop_count[MAX_NUM_ROWS * ctx.current_table_index + ctx.current_row]++);
	}

	ctx.current_row++; /* Since this is an uint8, this line can
    * increment from 255 to 0, in which case it
    * is still necessary to go the next
    * pattern. */
	if(!ctx.position_jump && !ctx.pattern_break &&
	   (ctx.current_row >= cur.num_rows || ctx.current_row == 0)) {
		ctx.current_table_index++;
		ctx.current_row = ctx.jump_row; /* This will be 0 most of
        * the time, except when E60
        * is used */
		ctx.jump_row = 0;
		xm_post_pattern_change(ctx);
       }
}

void xm_envelope_tick(xm_channel_context_t* ch,
							 xm_envelope_t* env,
							 uint16_t* counter,
							 float* outval) {
                                if(env.num_points < 2) {
                                    /* Don't really know what to do… */
                                    if(env.num_points == 1) {
                                        /* XXX I am pulling this out of my ass */
                                        *outval = cast(float)env.points[0].value / cast(float)0x40;
                                        if(*outval > 1) {
                                            *outval = 1;
                                        }
                                    }

                                    return;
                                } else {
                                    uint8_t j;

                                    if(env.loop_enabled) {
                                        uint16_t loop_start = env.points[env.loop_start_point].frame;
                                        uint16_t loop_end = env.points[env.loop_end_point].frame;
                                        uint16_t loop_length = cast(ushort)(loop_end - loop_start);

                                        if(*counter >= loop_end) {
                                            *counter -= loop_length;
                                        }
                                    }

                                    for(j = 0; j < (env.num_points - 2); ++j) {
                                        if(env.points[j].frame <= *counter &&
                                           env.points[j+1].frame >= *counter) {
                                            break;
                                           }
                                    }

                                    *outval = xm_envelope_lerp(env.points.ptr + j, env.points.ptr + j + 1, *counter) / cast(float)0x40;

                                    /* Make sure it is safe to increment frame count */
                                    if(!ch.sustained || !env.sustain_enabled ||
                                       *counter != env.points[env.sustain_point].frame) {
                                        (*counter)++;
                                       }
                                }
                             }

void xm_envelopes(xm_channel_context_t* ch) {
	if(ch.instrument != null) {
		if(ch.instrument.volume_envelope.enabled) {
			if(!ch.sustained) {
				ch.fadeout_volume -= ch.instrument.volume_fadeout / 32768.0f;
				if(ch.fadeout_volume < 0) ch.fadeout_volume = 0;
			}

			xm_envelope_tick(ch,
							 &(ch.instrument.volume_envelope),
							 &(ch.volume_envelope_frame_count),
							 &(ch.volume_envelope_volume));
		}

		if(ch.instrument.panning_envelope.enabled) {
			xm_envelope_tick(ch,
							 &(ch.instrument.panning_envelope),
							 &(ch.panning_envelope_frame_count),
							 &(ch.panning_envelope_panning));
		}
	}
}

void xm_tick(xm_context_t* ctx) {
	if(ctx.current_tick == 0) {
		xm_row(ctx);
	}

	for(uint8_t i = 0; i < ctx.module_.num_channels; ++i) {
		xm_channel_context_t* ch = ctx.channels + i;

		xm_envelopes(ch);
		xm_autovibrato(ctx, ch);

		if(ch.arp_in_progress && !ch.current.HAS_ARPEGGIO()) {
			ch.arp_in_progress = false;
			ch.arp_note_offset = 0;
			xm_update_frequency(ctx, ch);
		}
		if(ch.vibrato_in_progress && !ch.current.HAS_VIBRATO()) {
			ch.vibrato_in_progress = false;
			ch.vibrato_note_offset = 0.0f;
			xm_update_frequency(ctx, ch);
		}

		switch(ch.current.volume_column >> 4) {

            case 0x6: /* Volume slide down */
                if(ctx.current_tick == 0) break;
                xm_volume_slide(ch, ch.current.volume_column & 0x0F);
                break;

            case 0x7: /* Volume slide up */
                if(ctx.current_tick == 0) break;
                xm_volume_slide(ch, cast(ubyte)(ch.current.volume_column << 4));
                break;

            case 0xB: /* Vibrato */
                if(ctx.current_tick == 0) break;
                ch.vibrato_in_progress = false;
                xm_vibrato(ctx, ch, ch.vibrato_param);
                break;

            case 0xD: /* Panning slide left */
                if(ctx.current_tick == 0) break;
                xm_panning_slide(ch, ch.current.volume_column & 0x0F);
                break;

            case 0xE: /* Panning slide right */
                if(ctx.current_tick == 0) break;
                xm_panning_slide(ch, cast(ubyte)(ch.current.volume_column << 4));
                break;

            case 0xF: /* Tone portamento */
                if(ctx.current_tick == 0) break;
                xm_tone_portamento(ctx, ch);
                break;

            default:
                break;

		}

		switch(ch.current.effect_type) {

            case 0: /* 0xy: Arpeggio */
                if(ch.current.effect_param > 0) {
                    char arp_offset = ctx.tempo % 3;
                    switch(arp_offset) {
                        case 2: /* 0 . x . 0 . y . x . … */
                            if(ctx.current_tick == 1) {
                                ch.arp_in_progress = true;
                                ch.arp_note_offset = ch.current.effect_param >> 4;
                                xm_update_frequency(ctx, ch);
                                break;
                            }
                            /* No break here, this is intended */
                            goto case 1;

                        case 1: /* 0 . 0 . y . x . … */
                            if(ctx.current_tick == 0) 
                            {
                                ch.arp_in_progress = false;
                                ch.arp_note_offset = 0;
                                xm_update_frequency(ctx, ch);
                                break;
                            }
                            /* No break here, this is intended */
                            goto case 0;

                        case 0: /* 0 . y . x . … */
                            xm_arpeggio(ctx, ch, ch.current.effect_param, cast(ushort)(ctx.current_tick - arp_offset));
                            break;

                        default:
                            break;
                    }
                }
                break;

            case 1: /* 1xx: Portamento up */
                if(ctx.current_tick == 0) break;
                xm_pitch_slide(ctx, ch, -cast(int)ch.portamento_up_param);
                break;

            case 2: /* 2xx: Portamento down */
                if(ctx.current_tick == 0) break;
                xm_pitch_slide(ctx, ch, ch.portamento_down_param);
                break;

            case 3: /* 3xx: Tone portamento */
                if(ctx.current_tick == 0) break;
                xm_tone_portamento(ctx, ch);
                break;

            case 4: /* 4xy: Vibrato */
                if(ctx.current_tick == 0) break;
                ch.vibrato_in_progress = true;
                xm_vibrato(ctx, ch, ch.vibrato_param);
                break;

            case 5: /* 5xy: Tone portamento + Volume slide */
                if(ctx.current_tick == 0) break;
                xm_tone_portamento(ctx, ch);
                xm_volume_slide(ch, ch.volume_slide_param);
                break;

            case 6: /* 6xy: Vibrato + Volume slide */
                if(ctx.current_tick == 0) break;
                ch.vibrato_in_progress = true;
                xm_vibrato(ctx, ch, ch.vibrato_param);
                xm_volume_slide(ch, ch.volume_slide_param);
                break;

            case 7: /* 7xy: Tremolo */
                if(ctx.current_tick == 0) break;
                xm_tremolo(ctx, ch, ch.tremolo_param, ch.tremolo_ticks++);
                break;

            case 0xA: /* Axy: Volume slide */
                if(ctx.current_tick == 0) break;
                xm_volume_slide(ch, ch.volume_slide_param);
                break;

            case 0xE: /* EXy: Extended command */
                switch(ch.current.effect_param >> 4) {

                    case 0x9: /* E9y: Retrigger note */
                        if(ctx.current_tick != 0 && ch.current.effect_param & 0x0F) {
                            if(!(ctx.current_tick % (ch.current.effect_param & 0x0F))) {
                                xm_trigger_note(ctx, ch, XM_TRIGGER_KEEP_VOLUME);
                                xm_envelopes(ch);
                            }
                        }
                        break;

                    case 0xC: /* ECy: Note cut */
                        if((ch.current.effect_param & 0x0F) == ctx.current_tick) {
                            xm_cut_note(ch);
                        }
                        break;

                    case 0xD: /* EDy: Note delay */
                        if(ch.note_delay_param == ctx.current_tick) {
                            xm_handle_note_and_instrument(ctx, ch, ch.current);
                            xm_envelopes(ch);
                        }
                        break;

                    default:
                        break;

                }
                break;

            case 17: /* Hxy: Global volume slide */
                if(ctx.current_tick == 0) break;
                if((ch.global_volume_slide_param & 0xF0) &&
                   (ch.global_volume_slide_param & 0x0F)) {
                    /* Illegal state */
                    break;
                   }
                if(ch.global_volume_slide_param & 0xF0) {
                    /* Global slide up */
                    float f = cast(float)(ch.global_volume_slide_param >> 4) / cast(float)0x40;
                    ctx.global_volume += f;
                    if(ctx.global_volume > 1)
                        ctx.global_volume = 1;
                } else {
                    /* Global slide down */
                    float f = cast(float)(ch.global_volume_slide_param & 0x0F) / cast(float)0x40;
                    ctx.global_volume -= f;
                    if (ctx.global_volume < 0)
                        ctx.global_volume = 0;
                }
                break;

            case 20: /* Kxx: Key off */
                /* Most documentations will tell you the parameter has no
                * use. Don't be fooled. */
                if(ctx.current_tick == ch.current.effect_param) {
                    xm_key_off(ch);
                }
                break;

            case 25: /* Pxy: Panning slide */
                if(ctx.current_tick == 0) break;
                xm_panning_slide(ch, ch.panning_slide_param);
                break;

            case 27: /* Rxy: Multi retrig note */
                if(ctx.current_tick == 0) break;
                if(((ch.multi_retrig_param) & 0x0F) == 0) break;
                if((ctx.current_tick % (ch.multi_retrig_param & 0x0F)) == 0) {
                    xm_trigger_note(ctx, ch, XM_TRIGGER_KEEP_VOLUME | XM_TRIGGER_KEEP_ENVELOPE);

                    /* Rxy doesn't affect volume if there's a command in the volume
                    column, or if the instrument has a volume envelope. */
                    if (!ch.current.volume_column && !ch.instrument.volume_envelope.enabled){
                        float v = ch.volume * multi_retrig_multiply[ch.multi_retrig_param >> 4]
                            + multi_retrig_add[ch.multi_retrig_param >> 4] / cast(float)0x40;
                        if (v < 0) v = 0;
                        if (v > 1) v = 1;
                        ch.volume = v;
                    }
                }
                break;

            case 29: /* Txy: Tremor */
                if(ctx.current_tick == 0) break;
                ch.tremor_on = (
                                 (ctx.current_tick - 1) % ((ch.tremor_param >> 4) + (ch.tremor_param & 0x0F) + 2)
                                 >
                                 (ch.tremor_param >> 4)
                                 );
                break;

            default:
                break;

		}

		float panning, volume;

		panning = ch.panning +
			(ch.panning_envelope_panning - .5f) * (.5f - abs(ch.panning - .5f)) * 2.0f;

		if(ch.tremor_on) {
            volume = .0f;
		} else {
			volume = ch.volume + ch.tremolo_volume;
			if (volume < 0) volume = 0;
            if (volume > 1) volume = 1;
			volume *= ch.fadeout_volume * ch.volume_envelope_volume;
		}

        version(XM_RAMPING)
        {
		    /* See https://modarchive.org/forums/index.php?topic=3517.0
            * and https://github.com/Artefact2/libxm/pull/16 */
		    ch.target_volume[0] = volume * sqrt(1.0f - panning);
		    ch.target_volume[1] = volume * sqrt(panning);
        }
        else
        {
		    ch.actual_volume[0] = volume * fast_sqrt(1.0f - panning);
		    ch.actual_volume[1] = volume * fast_sqrt(panning);
        }
	}

	ctx.current_tick++;
	if(ctx.current_tick >= ctx.tempo + ctx.extra_ticks) {
		ctx.current_tick = 0;
		ctx.extra_ticks = 0;
	}

	/* FT2 manual says number of ticks / second = BPM * 0.4 */
	ctx.remaining_samples_in_tick += cast(float)ctx.rate / (cast(float)ctx.bpm * 0.4f);
}

float xm_sample_at(xm_sample_t* sample, size_t k) {
	return sample.bits == 8 ? (sample.data8[k] / 128.0f) : (sample.data16[k] / 32768.0f);
}

float xm_next_of_sample(xm_channel_context_t* ch) {
	if(ch.instrument == null || ch.sample == null || ch.sample_position < 0) {
        version(XM_RAMPING)
        {
		    if(ch.frame_count < XM_SAMPLE_RAMPING_POINTS) {
			    return XM_LERP(ch.end_of_previous_sample[ch.frame_count], .0f,
			                   cast(float)ch.frame_count / cast(float)XM_SAMPLE_RAMPING_POINTS);
		    }
        }
		return .0f;
	}
	if(ch.sample.length == 0) {
		return .0f;
	}

	float u, v, t;
	uint32_t a, b;
	a = cast(uint32_t)ch.sample_position; /* This cast is fine,
    * sample_position will not
    * go above integer
    * ranges */
	if(XM_LINEAR_INTERPOLATION) {
		b = a + 1;
		t = ch.sample_position - a;
	}
	u = xm_sample_at(ch.sample, a);

	switch(ch.sample.loop_type) {

        case XM_NO_LOOP:
            if(XM_LINEAR_INTERPOLATION) {
                v = (b < ch.sample.length) ? xm_sample_at(ch.sample, b) : .0f;
            }
            ch.sample_position += ch.step;
            if(ch.sample_position >= ch.sample.length) {
                ch.sample_position = -1;
            }
            break;

        case XM_FORWARD_LOOP:
            if(XM_LINEAR_INTERPOLATION) {
                v = xm_sample_at(
                                 ch.sample,
                                 (b == ch.sample.loop_end) ? ch.sample.loop_start : b
                                 );
            }
            ch.sample_position += ch.step;
            while(ch.sample_position >= ch.sample.loop_end) {
                ch.sample_position -= ch.sample.loop_length;
            }
            break;

        case XM_PING_PONG_LOOP:
            if(ch.ping) {
                ch.sample_position += ch.step;
            } else {
                ch.sample_position -= ch.step;
            }
            /* XXX: this may not work for very tight ping-pong loops
            * (ie switches direction more than once per sample */
            if(ch.ping) {
                if(XM_LINEAR_INTERPOLATION) {
                    v = xm_sample_at(ch.sample, (b >= ch.sample.loop_end) ? a : b);
                }
                if(ch.sample_position >= ch.sample.loop_end) {
                    ch.ping = false;
                    ch.sample_position = (ch.sample.loop_end << 1) - ch.sample_position;
                }
                /* sanity checking */
                if(ch.sample_position >= ch.sample.length) {
                    ch.ping = false;
                    ch.sample_position -= ch.sample.length - 1;
                }
            } else {
                if(XM_LINEAR_INTERPOLATION) {
                    v = u;
                    u = xm_sample_at(
                                     ch.sample,
                                     (b == 1 || b - 2 <= ch.sample.loop_start) ? a : (b - 2)
                                     );
                }
                if(ch.sample_position <= ch.sample.loop_start) {
                    ch.ping = true;
                    ch.sample_position = (ch.sample.loop_start << 1) - ch.sample_position;
                }
                /* sanity checking */
                if(ch.sample_position <= .0f) {
                    ch.ping = true;
                    ch.sample_position = .0f;
                }
            }
            break;

        default:
            v = .0f;
            break;
	}

	float endval = (XM_LINEAR_INTERPOLATION ? XM_LERP(u, v, t) : u);

    version(XM_RAMPING)
    {
	    if(ch.frame_count < XM_SAMPLE_RAMPING_POINTS) {
		    /* Smoothly transition between old and new sample. */
		    return XM_LERP(ch.end_of_previous_sample[ch.frame_count], endval,
		                   cast(float)ch.frame_count / cast(float)XM_SAMPLE_RAMPING_POINTS);
	    }
    }

	return endval;
}

void xm_sample(xm_context_t* ctx, float* left, float* right) {
	if(ctx.remaining_samples_in_tick <= 0) {
		xm_tick(ctx);
	}
	ctx.remaining_samples_in_tick--;

	*left = 0.0f;
	*right = 0.0f;

	if(ctx.max_loop_count > 0 && ctx.loop_count >= ctx.max_loop_count) {
		return;
	}

	for(uint8_t i = 0; i < ctx.module_.num_channels; ++i) {
		xm_channel_context_t* ch = ctx.channels + i;

		if(ch.instrument == null || ch.sample == null || ch.sample_position < 0) {
			continue;
		}

		const float fval = xm_next_of_sample(ch);

		if(!ch.muted && !ch.instrument.muted) {
			*left += fval * ch.actual_volume[0];
			*right += fval * ch.actual_volume[1];
		}

        version(XM_RAMPING)
        {
		    ch.frame_count++;
		    XM_SLIDE_TOWARDS(ch.actual_volume[0], ch.target_volume[0], ctx.volume_ramp);
		    XM_SLIDE_TOWARDS(ch.actual_volume[1], ch.target_volume[1], ctx.volume_ramp);
        }
	}

	const float fgvol = ctx.global_volume * ctx.amplification;
	*left *= fgvol;
	*right *= fgvol;

	/*if(XM_DEBUG) {
		if(fast_fabs(*left) > 1 || fast_fabs(*right) > 1) 
        {
            assert(false);
			//DEBUG("clipping frame: %f %f, this is a bad module or a libxm bug", *left, *right);
		}
	}*/
}

void xm_generate_samples(xm_context_t* ctx, float* output, size_t numsamples) {
	ctx.generated_samples += numsamples;

	for(size_t i = 0; i < numsamples; i++) {
		xm_sample(ctx, output + (2 * i), output + (2 * i + 1));
	}
}
