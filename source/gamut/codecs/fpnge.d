module gamut.codecs.fpnge;

// Copyright 2021 Google LLC
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//    https://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import core.stdc.stdlib: malloc, free;
import core.stdc.string: memcpy, memset;
import inteli.nmmintrin; // SSE4.1 only, there was an AVX2 path but not translated

alias FPNGECicpColorspace = int;
enum : FPNGECicpColorspace 
{ 
    FPNGE_CICP_NONE, 
    FPNGE_CICP_PQ 
}

alias FPNGEOptionsPredictor = int;
enum : FPNGEOptionsPredictor 
{
    FPNGE_PREDICTOR_FIXED_NOOP,
    FPNGE_PREDICTOR_FIXED_SUB,
    FPNGE_PREDICTOR_FIXED_TOP,
    FPNGE_PREDICTOR_FIXED_AVG,
    FPNGE_PREDICTOR_FIXED_PAETH,
    FPNGE_PREDICTOR_APPROX,
    FPNGE_PREDICTOR_BEST
}

struct FPNGEOptions 
{
    FPNGEOptionsPredictor predictor;
    char huffman_sample;                 // 0-127: how much of the image to sample
    FPNGECicpColorspace cicp_colorspace;
}

enum FPNGE_COMPRESS_LEVEL_DEFAULT = 4;
enum FPNGE_COMPRESS_LEVEL_BEST = 5;

nothrow @nogc:

void FPNGEFillOptions(FPNGEOptions *options, int level, FPNGECicpColorspace cicp_colorspace) 
{
    if (level == 0)
        level = FPNGE_COMPRESS_LEVEL_DEFAULT;
    options.cicp_colorspace = cicp_colorspace;
    options.huffman_sample = 1;
    switch (level) 
    {
        case 1:
            options.predictor = 2;
            break;
        case 2:
            options.predictor = 4;
            break;
        case 3:
            options.predictor = 5;
            break;
        case 5:
            options.huffman_sample = 23;
            goto default;
        default:
            options.predictor = 6;
        break;
    }
}


size_t FPNGEOutputAllocSize(size_t bytes_per_channel, size_t num_channels, size_t width, size_t height) 
{
    // likely an overestimate
    return 1024 + 2 * bytes_per_channel * num_channels * width * height; // TODO: overflow here
}

// #define MM(f) _mm_##f
// #define MMSI(f) _mm_##f##_si128
// #define __m128i __m128i
// #define BCAST128(v) (v)
enum SIMD_WIDTH = 16;
enum uint SIMD_MASK = 0xffff;

align(16) static immutable ubyte[16] kBitReverseNibbleLookup = 
[
    0b0000, 0b1000, 0b0100, 0b1100, 0b0010, 0b1010, 0b0110, 0b1110,
    0b0001, 0b1001, 0b0101, 0b1101, 0b0011, 0b1011, 0b0111, 0b1111,
];

static immutable ubyte[29] kLZ77NBits = 
[
    0, 0, 0, 0, 0, 0, 0, 0, 1, 1,
    1, 1, 2, 2, 2, 2, 3, 3, 3, 3,
    4, 4, 4, 4, 5, 5, 5, 5, 0
];

static immutable ushort[29] kLZ77Base = 
[
    3,  4,  5,  6,  7,  8,  9,  10, 11,  13,  15,  17,  19,  23, 27,
    31, 35, 43, 51, 59, 67, 83, 99, 115, 131, 163, 195, 227, 258
];

ushort BitReverse(size_t nbits, ushort bits) 
{
    ushort rev16 = cast(ushort) (
                     (kBitReverseNibbleLookup[bits & 0xF] << 12) |
                     (kBitReverseNibbleLookup[(bits >> 4) & 0xF] << 8) |
                     (kBitReverseNibbleLookup[(bits >> 8) & 0xF] << 4) |
                     (kBitReverseNibbleLookup[bits >> 12]) );
    return rev16 >> (16 - nbits);
}

struct HuffmanTable // PERF: the .init will be massive...
{
nothrow @nogc:
    ubyte[286] nbits;
    ushort end_bits;

    align(16)
    {
        ubyte[16] approx_nbits;
        ubyte[16] first16_nbits;
        ubyte[16] first16_bits;
        ubyte[16] last16_nbits;
        ubyte[16] last16_bits;
        ubyte[16] mid_lowbits;
    }

    ubyte mid_nbits;
    uint[259] lz77_length_nbits;
    uint[259] lz77_length_bits;
    uint[259] lz77_length_sym;

    uint dist_nbits, dist_bits;

    // Computes nbits[i] for i <= n, subject to min_limit[i] <= nbits[i] <=
    // max_limit[i], so to minimize sum(nbits[i] * freqs[i]).
    static void ComputeCodeLengths(const(ulong)* freqs, size_t n, ubyte *min_limit, ubyte *max_limit, ubyte *nbits) 
    {
        size_t precision = 0;
        ulong freqsum = 0;
        for (size_t i = 0; i < n; i++) 
        {
            assert(freqs[i] != 0);
            freqsum += freqs[i];
            if (min_limit[i] < 1)
            min_limit[i] = 1;
            assert(min_limit[i] <= max_limit[i]);
            if (precision < max_limit[i])
                precision = max_limit[i];
        }

        ulong infty = freqsum * precision;


        // original code create a new std::vector here, this allocates

        size_t dynp_size = ((1U << precision) + 1) * (n + 1);
        ulong *dynp = cast(ulong*) malloc(dynp_size * ulong.sizeof);
        scope(exit) free(dynp);
        dynp[0..dynp_size] = infty;

        ref ulong d(size_t sym, size_t off)
        {
            return dynp[sym * ((1 << precision) + 1) + off];
        }

        d(0, 0) = 0;

        for (size_t sym = 0; sym < n; sym++) 
        {
            for (size_t bits = min_limit[sym]; bits <= max_limit[sym]; bits++) 
            {
                size_t off_delta = 1U << (precision - bits);
                for (size_t off = 0; off + off_delta <= (1U << precision); off++) 
                {
                    ulong A = d(sym, off) + freqs[sym] * bits;
                    ulong B = d(sym + 1, off + off_delta);
                    if (A > B) 
                        A = B;
                    d(sym + 1, off + off_delta) = A;
                }
            }
        }

        size_t sym = n;
        size_t off = 1U << precision;

        while (sym-- > 0) 
        {
            assert(off > 0);
            for (size_t bits = min_limit[sym]; bits <= max_limit[sym]; bits++) 
            {
                size_t off_delta = 1U << (precision - bits);
                if (off_delta <= off && d(sym + 1, off) == d(sym, off - off_delta) + freqs[sym] * bits) 
                {
                    off -= off_delta;
                    nbits[sym] = cast(ubyte) bits;
                    break;
                }
            }
        }
    }

    void ComputeNBits(const(ulong)* collected_data) 
    {
        static immutable ulong[286] kBaselineData = 
        [
            113, 54, 28, 18, 12, 9, 7, 6, 5, 4, 3, 3, 2, 2, 2, 2, 1, 1, 1, 1, 1,
            1,   1,  1,  1,  1,  1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
            1,   1,  1,  1,  1,  1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
            1,   1,  1,  1,  1,  1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
            1,   1,  1,  1,  1,  1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
            1,   1,  1,  1,  1,  1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
            1,   1,  1,  1,  1,  1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
            1,   1,  1,  1,  1,  1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
            1,   1,  1,  1,  1,  1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
            1,   1,  1,  1,  1,  1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
            1,   1,  1,  1,  1,  1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
            1,   1,  1,  1,  1,  1, 1, 1, 1, 2, 2, 2, 2, 2, 3, 3, 4, 5, 6, 7, 9,
            12,  18, 29, 54, 1,  1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
            1,   1,  1,  1,  1,  1, 1, 1, 1, 1, 1, 1, 1,
        ];

        ulong[286] data;

        for (size_t i = 0; i < 286; i++) 
        {
            data[i] = collected_data[i] + kBaselineData[i];
        }

        // Compute Huffman code length ensuring that all the "fake" symbols for [16,
        // 240) and [255, 285) have their maximum length.
        ulong[16 + 14 + 16 + 2] collapsed_data;
        ubyte[16 + 14 + 16 + 2] collapsed_min_limit;

        ubyte[16 + 14 + 16 + 2] collapsed_max_limit = void;
        for (size_t i = 0; i < 48; i++) 
        {
            collapsed_max_limit[i] = 8;
        }
        for (size_t i = 0; i < 16; i++) 
        {
            collapsed_data[i] = data[i];
        }
        for (size_t i = 0; i < 14; i++) 
        {
            collapsed_data[16 + i] = 1;
            collapsed_min_limit[16 + i] = 8;
        }
        for (size_t j = 0; j < 16; j++) 
        {
            collapsed_data[16 + 14 + j] += data[240 + j];
        }
        collapsed_data[16 + 14 + 16] = 1;
        collapsed_min_limit[16 + 14 + 16] = 8;
        collapsed_data[16 + 14 + 16 + 1] = data[285];

        ubyte[48] collapsed_nbits;
        ComputeCodeLengths(collapsed_data.ptr, 48, collapsed_min_limit.ptr,
                           collapsed_max_limit.ptr, collapsed_nbits.ptr);

        // Compute "extra" code lengths for symbols >= 256, except 285.
        ubyte[29] tail_nbits;
        ubyte[29] tail_min_limit;
        ubyte[29] tail_max_limit;

        for (size_t i = 0; i < 29; i++) 
        {
            tail_min_limit[i] = 4;
            tail_max_limit[i] = 7;
        }

        ComputeCodeLengths(data.ptr + 256, 29, tail_min_limit.ptr, tail_max_limit.ptr, tail_nbits.ptr);

        for (size_t i = 0; i < 16; i++) 
        {
            nbits[i] = collapsed_nbits[i];
        }

        for (size_t i = 0; i < 14; i++) 
        {
            for (size_t j = 0; j < 16; j++) 
            {
                nbits[(i + 1) * 16 + j] = cast(ubyte)( collapsed_nbits[16 + i] + 4 );
            }
        }

        for (size_t i = 0; i < 16; i++) 
        {
            nbits[240 + i] = collapsed_nbits[30 + i];
        }

        for (size_t i = 0; i < 29; i++) 
        {
            nbits[256 + i] = cast(ubyte)( collapsed_nbits[46] + tail_nbits[i] );
        }

        nbits[285] = collapsed_nbits[47];
    }

    void ComputeCanonicalCode(const ubyte *nbits, ushort *bits) 
    {
        ubyte[16] code_length_counts;
        for (size_t i = 0; i < 286; i++) 
        {
            code_length_counts[nbits[i]]++;
        }
        ushort[16] next_code;
        ushort code = 0;
        for (size_t i = 1; i < 16; i++) 
        {
            code = cast(ushort) ( (code + code_length_counts[i - 1]) << 1 );
            next_code[i] = code;
        }
        for (size_t i = 0; i < 286; i++) 
        {
            bits[i] = BitReverse(nbits[i], next_code[nbits[i]]++);
        }
    }

    void FillNBits() 
    {
        for (size_t i = 0; i < 16; i++) 
        {
            first16_nbits[i] = nbits[i];
            last16_nbits[i] = nbits[240 + i];
        }
        mid_nbits = nbits[16];
        for (size_t i = 16; i < 240; i++) 
        {
            assert(nbits[i] == mid_nbits);
        }
        // Construct lz77 lookup tables.
        for (size_t i = 0; i < 29; i++) 
        {
            for (size_t j = 0; j < (1U << kLZ77NBits[i]); j++) 
            {
                lz77_length_nbits[kLZ77Base[i] + j] = nbits[257 + i] + kLZ77NBits[i];
                lz77_length_sym[kLZ77Base[i] + j] = cast(uint)(257 + i);
            }
        }

        dist_nbits = 1;
        approx_nbits[0] = cast(ubyte)(nbits[0] - 1); // subtract 1 as a fudge for catering for RLE
        for (size_t i = 1; i < 15; i++) 
        {
            approx_nbits[i] = (nbits[i] + nbits[256 - i] + 1) / 2;
        }
        approx_nbits[15] = mid_nbits;
    }

    void FillBits() 
    {
        ushort[286] bits;
        ComputeCanonicalCode(nbits.ptr, bits.ptr);
        for (size_t i = 0; i < 16; i++) 
        {
            first16_bits[i] = cast(ubyte)(bits[i]);
            last16_bits[i]  = cast(ubyte)(bits[240 + i]);
        }
        mid_lowbits[0] = mid_lowbits[15] = 0;
        for (size_t i = 16; i < 240; i += 16) 
        {
            mid_lowbits[i / 16] = cast(ubyte)( bits[i] & ((1U << (mid_nbits - 4)) - 1) );
        }
        for (size_t i = 16; i < 240; i++) 
        {
            assert((uint(mid_lowbits[i / 16]) |
                  (kBitReverseNibbleLookup[i % 16] << (mid_nbits - 4))) == bits[i]);
        }
        end_bits = bits[256];
        // Construct lz77 lookup tables.
        for (size_t i = 0; i < 29; i++) 
        {
            for (size_t j = 0; j < (1U << kLZ77NBits[i]); j++) 
            {
                lz77_length_bits[kLZ77Base[i] + j] = cast(uint)( bits[257 + i] | (j << nbits[257 + i]) );
            }
        }

        dist_bits = 0;
    }

    void initialize(const(ulong)* collected_data) 
    {
        ComputeNBits(collected_data);
        FillNBits();
        FillBits();
    }

    // estimate for CollectSymbolCounts
    // only fills nbits; skips computing actual codes
    void initialize() 
    {
        // the following is similar to ComputeNBits(0, 0, 0 ...), but much faster
        static immutable ubyte[62] collapsed_nbits = 
        [
            2,  3,  4,  5,  5,  6,  6,  6,  7,  7,  7,  7,  8,  8,  8,  8,
            8,  8,  8,  8,  8,  7,  7,  7,  7,  6,  6,  6,  5,  5,  4,  3,

            13, 13, 13, 13, 13, 13, 13, 13, 13, 13, 13, 13, 13, 13, 13, 13,
            13, 13, 13, 13, 13, 13, 13, 13, 13, 13, 12, 12, 12, 8
        ];
        
        for (size_t i = 0; i < 16; i++) 
        {
            nbits[i] = collapsed_nbits[i];
            nbits[240 + i] = collapsed_nbits[16 + i];
        }

        for (size_t i = 16; i < 240; i++) 
        {
         nbits[i] = 12;
        }

        for (size_t i = 0; i < 30; i++) 
        {
            nbits[256 + i] = collapsed_nbits[32 + i];
        }

        FillNBits();
    }
}

struct BitWriter 
{
nothrow @nogc:
    void Write(uint count, ulong bits) 
    {
        buffer |= bits << bits_in_buffer;
        bits_in_buffer += count;
        memcpy(data + bytes_written, &buffer, 8);
        size_t bytes_in_buffer = bits_in_buffer / 8;
        bits_in_buffer &= 7;
        buffer >>= bytes_in_buffer * 8;
        bytes_written += bytes_in_buffer;
    }

    void ZeroPadToByte() 
    {
        if (bits_in_buffer != 0) 
        {
            Write(cast(uint)(8 - bits_in_buffer), 0);
        }
    }

    ubyte* data;
    size_t bytes_written = 0;
    size_t bits_in_buffer = 0;
    ulong buffer = 0;
}

void WriteHuffmanCode(ref const(HuffmanTable) table, BitWriter* writer) 
{
    static immutable ubyte[19] kCodeLengthNbits = 
    [
        4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 0, 0, 0,
    ];

    static immutable ubyte[19] kCodeLengthOrder = 
    [
        16, 17, 18, 0, 8, 7, 9, 6, 10, 5, 11, 4, 12, 3, 13, 2, 14, 1, 15,
    ];

    writer.Write(5, 29); // all lit/len codes
    writer.Write(5, 0);  // distance code up to dist, included
    writer.Write(4, 15); // all code length codes

    for (size_t i = 0; i < 19; i++) 
    {
        writer.Write(3, kCodeLengthNbits[kCodeLengthOrder[i]]);
    }

    for (size_t i = 0; i < 286; i++) 
    {
        writer.Write(4, kBitReverseNibbleLookup[table.nbits[i]]);
    }
    writer.Write(4, 0b1000);
}

// 4 kb of compile-time table, arghh


// PERF: precompute this crap
static immutable uint[256 * 8] kCrcSlice8LUT = 
(){
    uint[256 * 8] r = void;
    for (uint n = 0; n < 256*8; ++n)
    {
        r[n] = crc32_slice8_gen(n); // does sound that much efficient at all
    }
    return r;
}();

uint crc32_slice8_gen(uint n) pure
{
    uint crc = n & 0xff;
    for (int i = n >> 8; i >= 0; i--) 
    {
        for (int j = 0; j < 8; j++) 
        {
            crc = (crc >> 1) ^ ((crc & 1) * 0xEDB88320); // 0xEDB88320 = CRC32 polynomial
        }
    }
    return crc;
}


struct Crc32 
{
nothrow @nogc:
private:

    uint state;

    // this is based off Fast CRC32 slice-by-8:
    // https://create.stephan-brumme.com/crc32/
    uint crc_process_iter(uint crc, const(uint)* current) 
    {
        uint one = *current++ ^ crc;
        uint two = *current;
        return kCrcSlice8LUT[(two >> 24) & 0xFF] ^
               kCrcSlice8LUT[0x100 + ((two >> 16) & 0xFF)] ^
               kCrcSlice8LUT[0x200 + ((two >> 8) & 0xFF)] ^
               kCrcSlice8LUT[0x300 + (two & 0xFF)] ^
               kCrcSlice8LUT[0x400 + ((one >> 24) & 0xFF)] ^
               kCrcSlice8LUT[0x500 + ((one >> 16) & 0xFF)] ^
               kCrcSlice8LUT[0x600 + ((one >> 8) & 0xFF)] ^
               kCrcSlice8LUT[0x700 + (one & 0xFF)];
    }

public:

    void initialize()
    {
        state = 0xffffffff;
    }

    size_t update(const(ubyte)* data, size_t len) 
    {
        auto amount = len & ~7;
        for (size_t i = 0; i < amount; i += 8) 
        {
            state = crc_process_iter(state, cast(uint *)(data + i));
        }
        return amount;
    }
    uint update_final(const(ubyte)* data, size_t len) 
    {
        auto i = update(data, len);
        for (; i < len; i++) {
            state = (state >> 8) ^ kCrcSlice8LUT[(state & 0xFF) ^ data[i]];
        }
        return ~state;
    }
}

enum uint kAdler32Mod = 65521;

void UpdateAdler32(ref uint s1, ref uint s2, ubyte byte_) 
{
    s1 += byte_;
    s2 += s1;
    s1 %= kAdler32Mod;
    s2 %= kAdler32Mod;
}

static uint hadd(__m128i v) 
{
  auto sum = v;
  sum = _mm_hadd_epi32(sum, sum);
  sum = _mm_hadd_epi32(sum, sum);
  return _mm_cvtsi128_si32(sum);
}

__m128i PredictVec(size_t predictor)(const(ubyte)* current_buf,
                                     const(ubyte)* top_buf,
                                     const(ubyte)* left_buf,
                                     const(ubyte)* topleft_buf) 
{
    auto data = _mm_load_si128(cast(__m128i *)(current_buf));
    static if (predictor == 0) 
    {
        return data;
    } 
    else static if (predictor == 1) 
    {
        auto pred = _mm_loadu_si128(cast(__m128i *)(left_buf));
        return _mm_sub_epi8(data, pred);
    } 
    else static if (predictor == 2) 
    {
        auto pred = _mm_load_si128(cast(__m128i *)(top_buf));
        return _mm_sub_epi8(data, pred);
    } 
    else static if (predictor == 3) 
    {
        auto left = _mm_loadu_si128(cast(__m128i *)(left_buf));
        auto top = _mm_load_si128(cast(__m128i *)(top_buf));
        auto pred = _mm_avg_epu8(top, left);
        // emulate truncating average
        pred =
            _mm_sub_epi8(pred, _mm_and_si128(_mm_xor_si128(top, left), _mm_set1_epi8(1)));
        return _mm_sub_epi8(data, pred);
    } 
    else 
    {
        auto a = _mm_loadu_si128(cast(__m128i *)(left_buf));
        auto b = _mm_load_si128(cast(__m128i *)(top_buf));
        auto c = _mm_loadu_si128(cast(__m128i *)(topleft_buf));
        // compute |a-b| via max(a,b)-min(a,b)
        auto min_bc = _mm_min_epu8(b, c);
        auto min_ac = _mm_min_epu8(a, c);
        auto pa = _mm_sub_epi8(_mm_max_epu8(b, c), min_bc);
        auto pb = _mm_sub_epi8(_mm_max_epu8(a, c), min_ac);
        // pc = |(b-c) + (a-c)| = |pa-pb|, unless a>c>b or b>c>a, in which case,
        // pc isn't used
        auto min_pab = _mm_min_epu8(pa, pb);
        auto pc = _mm_sub_epi8(_mm_max_epu8(pa, pb), min_pab);
        pc = _mm_or_si128(
            pc, _mm_xor_si128(_mm_cmpeq_epi8(min_bc, c), _mm_cmpeq_epi8(min_ac, a)));

        auto use_a = _mm_cmpeq_epi8(_mm_min_epu8(min_pab, pc), pa);
        auto use_b = _mm_cmpeq_epi8(_mm_min_epu8(pb, pc), pb);

        auto pred = _mm_blendv_epi8(_mm_blendv_epi8(c, b, use_b), a, use_a);
        return _mm_sub_epi8(data, pred);

        /*
        // Equivalent scalar code:
        for (size_t ii = 0; ii < 32; ii++) {
          ubyte a = left_buf[i + ii];
          ubyte b = top_buf[i + ii];
          ubyte c = topleft_buf[i + ii];
          ubyte bc = b - c;
          ubyte ca = c - a;
          ubyte pa = c < b ? bc : -bc;
          ubyte pb = a < c ? ca : -ca;
          ubyte pc = (a < c) == (c < b) ? (bc >= ca ? bc - ca : ca - bc) : 255;
          ubyte pred = pa <= pb && pa <= pc ? a : pb <= pc ? b : c;
          ubyte data = current_row_buf[i + ii] - pred;
          predicted_data[ii] = data;
        }
        */
    }
}

align(16) static immutable int[16] _kMaskVec = 
[ 0,  0,  0,  0,
  0,  0,  0,  0,
 -1, -1, -1, -1,
 -1, -1, -1, -1 ];

const(ubyte)* kMaskVec() 
{
    return cast(const(ubyte)*)(_kMaskVec.ptr) + SIMD_WIDTH;
}

// various callback types, original fpgne uses templated C++ closures
nothrow @nogc
{
    alias ProcessRow_CB_t     = void delegate(__m128i bytes, size_t bytes_in_vec);
    alias ProcessRow_CB_ADL_t = void delegate(__m128i, size_t, size_t);
    alias ProcessRow_CB_RLE_t = void delegate(size_t run);    
}

void ProcessRow(size_t predictor)
                (size_t bytes_per_line, const(ubyte)* current_row_buf,
                const(ubyte)* top_buf, const(ubyte)* left_buf,
                const(ubyte)* topleft_buf, 
                scope ProcessRow_CB_t cb, 
                scope ProcessRow_CB_ADL_t cb_adl,
                scope ProcessRow_CB_RLE_t cb_rle) 
{
  size_t run = 0;
  size_t i = 0;
  for (; i + SIMD_WIDTH <= bytes_per_line; i += SIMD_WIDTH) {
    auto pdata = PredictVec!predictor(current_row_buf + i, top_buf + i,
                                      left_buf + i, topleft_buf + i);
    uint pdatais0 =
        _mm_movemask_epi8(_mm_cmpeq_epi8(pdata, _mm_setzero_si128()));
    if (pdatais0 == SIMD_MASK) {
      run += SIMD_WIDTH;
    } else {
      if (run != 0) {
        cb_rle(run);
      }
      run = 0;
      cb(pdata, SIMD_WIDTH);
    }
    cb_adl(pdata, SIMD_WIDTH, i);
  }
  size_t bytes_remaining =
      bytes_per_line ^ i; // equivalent to `bytes_per_line - i`
  if (bytes_remaining) {
    auto pdata = PredictVec!predictor(current_row_buf + i, top_buf + i,
                                      left_buf + i, topleft_buf + i);
    uint pdatais0 = _mm_movemask_epi8(_mm_cmpeq_epi8(pdata, _mm_setzero_si128()));
    auto mask = (1UL << bytes_remaining) - 1;

    if ((pdatais0 & mask) == mask && run + bytes_remaining >= 16) {
      run += bytes_remaining;
    } else {
      if (run != 0) {
        cb_rle(run);
      }
      run = 0;
      cb(pdata, bytes_remaining);
    }
    cb_adl(pdata, bytes_remaining, i);
  }
  if (run != 0) {
    cb_rle(run);
  }
}

void ProcessRowPred(ubyte predictor, size_t bytes_per_line,
               const ubyte *current_row_buf, const ubyte *top_buf,
               const ubyte *left_buf, const ubyte *topleft_buf,
                scope ProcessRow_CB_t cb, 
                scope ProcessRow_CB_ADL_t cb_adl,
                scope ProcessRow_CB_RLE_t cb_rle) 
{
  if (predictor == 1) {
    ProcessRow!1(bytes_per_line, current_row_buf, top_buf, left_buf,
                 topleft_buf, cb, cb_adl, cb_rle);
  } else if (predictor == 2) {
    ProcessRow!2(bytes_per_line, current_row_buf, top_buf, left_buf,
                 topleft_buf, cb, cb_adl, cb_rle);
  } else if (predictor == 3) {
    ProcessRow!3(bytes_per_line, current_row_buf, top_buf, left_buf,
                 topleft_buf, cb, cb_adl, cb_rle);
  } else if (predictor == 4) {
    ProcessRow!4(bytes_per_line, current_row_buf, top_buf, left_buf,
                 topleft_buf, cb, cb_adl, cb_rle);
  } else {
    assert(predictor == 0);
    ProcessRow!0(bytes_per_line, current_row_buf, top_buf, left_buf,
                 topleft_buf, cb, cb_adl, cb_rle);
  }
}

nothrow @nogc
{
    alias ForAllRLESymbols_callback_t = void delegate(size_t len, size_t count);
}

void ForAllRLESymbols(size_t length, scope ForAllRLESymbols_callback_t cb) 
{
  assert(length >= 4);
  length -= 1;

  if (length < 258) {
    // fast path if long sequences are rare in the image
    cb(length, 1);
  } else {
    auto runs = length / 258;
    auto remain = length % 258;
    if (remain == 1 || remain == 2) {
      remain += 258 - 3;
      runs--;
      cb(3, 1);
    }
    if (runs) {
      cb(258, runs);
    }
    if (remain) {
      cb(remain, 1);
    }
  }
}

void
TryPredictor(size_t pred, bool store_pred)
             (size_t bytes_per_line, const ubyte *current_row_buf,
             const ubyte *top_buf, const ubyte *left_buf,
             const ubyte *topleft_buf, ubyte *predicted_data,
             ref const HuffmanTable table, ref size_t best_cost, ref ubyte predictor) 
{
  size_t cost_rle = 0;
  __m128i cost_direct = _mm_setzero_si128();

  const(HuffmanTable)* ptable = &table;


  void cost_chunk_cb(__m128i bytes, size_t bytes_in_vec) nothrow @nogc
  {
    auto data_for_lut = _mm_and_si128(_mm_set1_epi8(0xF), bytes);
    // get a mask of `bytes` that are between -16 and 15 inclusive
    // (`-16 <= bytes <= 15` is equivalent to `bytes + 112 > 95`)
    auto use_lowhi = _mm_cmpgt_epi8(_mm_add_epi8(bytes, _mm_set1_epi8(112)),
                                    _mm_set1_epi8(95));

    auto nbits_low16 = _mm_shuffle_epi8(
        (_mm_load_si128(cast(__m128i *)ptable.first16_nbits)), data_for_lut);
    auto nbits_hi16 = _mm_shuffle_epi8(
        (_mm_load_si128(cast(__m128i *)ptable.last16_nbits)), data_for_lut);

    auto nbits = _mm_blendv_epi8(nbits_low16, nbits_hi16, bytes);
    nbits = _mm_blendv_epi8(_mm_set1_epi8(ptable.mid_nbits), nbits, use_lowhi);

    auto nbits_discard =
        _mm_and_si128(nbits, _mm_loadu_si128(cast(__m128i *)(kMaskVec - bytes_in_vec)));

    cost_direct =
        _mm_add_epi32(cost_direct, _mm_sad_epu8(nbits, nbits_discard));
  }
  
  void rle_cost_cb(size_t run) nothrow @nogc
  {
    cost_rle += table.first16_nbits[0];

    void accumCost(size_t len, size_t count) nothrow @nogc
    {
        cost_rle += (table.dist_nbits + table.lz77_length_nbits[len]) * count;
    }

    ForAllRLESymbols(run, &accumCost);
  }

  if (store_pred) 
  {
    // Not sure what second arg is
    void store_pred_cb(__m128i pdata, size_t whatever, size_t i) nothrow @nogc
    {
        _mm_store_si128(cast(__m128i *)(predicted_data + i), pdata);
    }

    ProcessRow!pred(
        bytes_per_line, current_row_buf, top_buf, left_buf, topleft_buf,
        &cost_chunk_cb,
        &store_pred_cb,
        &rle_cost_cb);

  } 
  else 
  {
    void nostore_pred_cb(__m128i, size_t, size_t)
    {
    }


    ProcessRow!pred(
        bytes_per_line, current_row_buf, top_buf, left_buf, topleft_buf,
        &cost_chunk_cb, &nostore_pred_cb, &rle_cost_cb);
  }
  size_t cost = cost_rle + hadd(cost_direct);
  if (cost < best_cost) {
    best_cost = cost;
    predictor = pred;
  }
}

static void WriteBitsLong(__m128i nbits, __m128i bits_lo,
                          __m128i bits_hi, size_t mid_lo_nbits,
                          BitWriter * writer) 
{
  auto nbits0 = _mm_unpacklo_epi8(nbits, _mm_setzero_si128());
  auto nbits1 = _mm_unpackhi_epi8(nbits, _mm_setzero_si128());
  __m128i bits0, bits1;
  if (mid_lo_nbits == 8) {
    bits0 = _mm_unpacklo_epi8(bits_lo, bits_hi);
    bits1 = _mm_unpackhi_epi8(bits_lo, bits_hi);
  } else {
    __m128i nbits_shift = _mm_cvtsi32_si128(8 - cast(int)mid_lo_nbits);
    __m128i bits_lo_shifted = _mm_sll_epi16(bits_lo, nbits_shift);
    bits0 = _mm_unpacklo_epi8(bits_lo_shifted, bits_hi);
    bits1 = _mm_unpackhi_epi8(bits_lo_shifted, bits_hi);

    bits0 = _mm_srl_epi16(bits0, nbits_shift);
    bits1 = _mm_srl_epi16(bits1, nbits_shift);
  }

  // 16 . 32
  auto nbits0_32_lo = _mm_and_si128(nbits0, _mm_set1_epi32(0xFFFF));
  auto nbits1_32_lo = _mm_and_si128(nbits1, _mm_set1_epi32(0xFFFF));

  auto bits0_32_lo = _mm_and_si128(bits0, _mm_set1_epi32(0xFFFF));
  auto bits1_32_lo = _mm_and_si128(bits1, _mm_set1_epi32(0xFFFF));

  // emulate variable shift by abusing float exponents
  // this works because Huffman symbols are not allowed to exceed 15 bits, so
  // will fit within a float's mantissa and (number << 15) won't overflow when
  // converted back to a signed int
  auto bits0_32_hi =
      _mm_castps_si128(_mm_cvtepi32_ps(_mm_srli_epi32(bits0, 16)));
  auto bits1_32_hi =
      _mm_castps_si128(_mm_cvtepi32_ps(_mm_srli_epi32(bits1, 16)));

  // add shift amount to the exponent
  bits0_32_hi = _mm_add_epi32(bits0_32_hi, _mm_slli_epi32(nbits0_32_lo, 23));
  bits1_32_hi = _mm_add_epi32(bits1_32_hi, _mm_slli_epi32(nbits1_32_lo, 23));

  bits0_32_hi = _mm_cvtps_epi32(_mm_castsi128_ps(bits0_32_hi));
  bits1_32_hi = _mm_cvtps_epi32(_mm_castsi128_ps(bits1_32_hi));

  nbits0 = _mm_madd_epi16(nbits0, _mm_set1_epi16(1));
  nbits1 = _mm_madd_epi16(nbits1, _mm_set1_epi16(1));
  auto bits0_32 = _mm_or_si128(bits0_32_lo, bits0_32_hi);
  auto bits1_32 = _mm_or_si128(bits1_32_lo, bits1_32_hi);

  // 32 . 64
  __m128i nbits0_64_lo = _mm_and_si128(nbits0, _mm_set1_epi64x(0xFFFFFFFF));
  __m128i nbits1_64_lo = _mm_and_si128(nbits1, _mm_set1_epi64x(0xFFFFFFFF));
  // just do two shifts for SSE variant
  __m128i bits0_64_lo = _mm_and_si128(bits0_32, _mm_set1_epi64x(0xFFFFFFFF));
  __m128i bits1_64_lo = _mm_and_si128(bits1_32, _mm_set1_epi64x(0xFFFFFFFF));
  __m128i bits0_64_hi = _mm_srli_epi64(bits0_32, 32);
  __m128i bits1_64_hi = _mm_srli_epi64(bits1_32, 32);

  bits0_64_hi = _mm_blend_epi16!0xf0(
      _mm_sll_epi64(bits0_64_hi, nbits0_64_lo),
      _mm_sll_epi64(bits0_64_hi,
                    _mm_unpackhi_epi64(nbits0_64_lo, nbits0_64_lo)));
  bits1_64_hi = _mm_blend_epi16!0xf0(
      _mm_sll_epi64(bits1_64_hi, nbits1_64_lo),
      _mm_sll_epi64(bits1_64_hi,
                    _mm_unpackhi_epi64(nbits1_64_lo, nbits1_64_lo)));

  bits0 = _mm_or_si128(bits0_64_lo, bits0_64_hi);
  bits1 = _mm_or_si128(bits1_64_lo, bits1_64_hi);

  auto nbits01 = _mm_hadd_epi32(nbits0, nbits1);

  // nbits_a <= 40 as we have at most 10 bits per symbol, so the call to the
  // writer is safe.
  align(SIMD_WIDTH) uint[SIMD_WIDTH / 4] nbits_a;
  _mm_store_si128(cast(__m128i *)nbits_a, nbits01);

  align(SIMD_WIDTH) ulong[SIMD_WIDTH / 4] bits_a;
  _mm_store_si128(cast(__m128i *)bits_a, bits0);
  _mm_store_si128(cast(__m128i *)bits_a + 1, bits1);

  __gshared static immutable ubyte[4] kPerm = [0, 1, 2, 3];

  for (size_t ii = 0; ii < SIMD_WIDTH / 4; ii++) 
  {
    ulong bits = bits_a[kPerm[ii]];
    auto count = nbits_a[ii];
    writer.Write(count, bits);
  }
}

// as above, but where nbits <= 8, so we can ignore bits_hi
void WriteBitsShort(__m128i nbits, __m128i bits, BitWriter * writer) 
{
  // 8 . 16
  auto prod = _mm_slli_epi16(
      _mm_shuffle_epi8(_mm_set_epi32(
                           //  since we can't handle 8 bits, we'll under-shift
                           //  it and do an extra shift later on
                           -1, 0xffffff80, 0x40201008, 0x040201ff),
                       nbits),
      8);
  auto bits_hi =
      _mm_mulhi_epu16(_mm_andnot_si128(_mm_set1_epi16(0xff), bits), prod);
  bits_hi = _mm_add_epi16(bits_hi, bits_hi); // fix under-shifting
  bits = _mm_or_si128(_mm_and_si128(bits, _mm_set1_epi16(0xff)), bits_hi);
  nbits = _mm_maddubs_epi16(nbits, _mm_set1_epi8(1));

  // 16 . 32
  auto nbits_32_lo = _mm_and_si128(nbits, _mm_set1_epi32(0xFFFF));
  auto bits_32_lo = _mm_and_si128(bits, _mm_set1_epi32(0xFFFF));
  auto bits_32_hi = _mm_srli_epi32(bits, 16);

  // need to avoid overflow when converting float . int, because it converts to
  // a signed int; do this by offsetting the shift by 1
  nbits_32_lo = _mm_add_epi16(nbits_32_lo, _mm_set1_epi32(0xFFFF));
  bits_32_hi = _mm_castps_si128(_mm_cvtepi32_ps(bits_32_hi));
  bits_32_hi = _mm_add_epi32(bits_32_hi, _mm_slli_epi32(nbits_32_lo, 23));
  bits_32_hi = _mm_cvtps_epi32(_mm_castsi128_ps(bits_32_hi));
  bits_32_hi = _mm_add_epi32(bits_32_hi, bits_32_hi); // fix under-shifting

  nbits = _mm_madd_epi16(nbits, _mm_set1_epi16(1));
  bits = _mm_or_si128(bits_32_lo, bits_32_hi);

  // 32 . 64
  auto nbits_64_lo = _mm_and_si128(nbits, _mm_set1_epi64x(0xFFFFFFFF));
  auto bits_64_lo = _mm_and_si128(bits, _mm_set1_epi64x(0xFFFFFFFF));
  auto bits_64_hi = _mm_srli_epi64(bits, 32);
  bits_64_hi = _mm_blend_epi16!0xf0(
      _mm_sll_epi64(bits_64_hi, nbits_64_lo),
      _mm_sll_epi64(bits_64_hi, _mm_unpackhi_epi64(nbits_64_lo, nbits_64_lo)));
  bits = _mm_or_si128(bits_64_lo, bits_64_hi);

  auto nbits2 = _mm_hadd_epi32(
      nbits, nbits
  );

  align(16) uint[4] nbits_a;
  align(SIMD_WIDTH) ulong[SIMD_WIDTH / 8] bits_a;

  _mm_store_si128(cast(__m128i *)nbits_a, nbits2);
  _mm_store_si128(cast(__m128i *)bits_a, bits);

  for (size_t ii = 0; ii < SIMD_WIDTH / 8; ii++) 
  {
    ulong bits64 = bits_a[ii];

    if (nbits_a[ii] + writer.bits_in_buffer > 63) 
    {
      // hope this case rarely occurs
      writer.Write(16, bits64 & 0xffff);
      bits64 >>= 16;
      nbits_a[ii] -= 16;
    }
    writer.Write(nbits_a[ii], bits64);
  }
}

void AddApproxCost(ref __m128i total, __m128i pdata, __m128i bit_costs) 
{
  auto approx_sym = _mm_min_epu8(_mm_abs_epi8(pdata), _mm_set1_epi8(15));
  auto cost = _mm_shuffle_epi8(bit_costs, approx_sym);
  total = _mm_add_epi64(total, _mm_sad_epu8(cost, _mm_setzero_si128()));
}

void AddApproxCost(ref __m128i total, __m128i pdata, __m128i bit_costs, __m128i maskv) 
{
  auto approx_sym = _mm_min_epu8(_mm_abs_epi8(pdata), _mm_set1_epi8(15));
  auto cost = _mm_shuffle_epi8(bit_costs, approx_sym);
  auto cost_mask = _mm_and_si128(maskv, cost);
  total = _mm_add_epi64(total, _mm_sad_epu8(cost, cost_mask));
}

static ubyte
SelectPredictor(size_t bytes_per_line, const ubyte *current_row_buf,
                const ubyte *top_buf, const ubyte *left_buf,
                const ubyte *topleft_buf, ubyte *paeth_data,
                ref const HuffmanTable table, const FPNGEOptions* options) 
{
  if (options.predictor <= 4) 
  {
    return cast(ubyte) options.predictor;
  }
  if (options.predictor == FPNGE_PREDICTOR_APPROX) 
  {
    __m128i bit_costs = _mm_load_si128(cast(__m128i *)(table.approx_nbits));
    size_t i = 0;
    __m128i cost1 = _mm_setzero_si128();
    __m128i cost2 = _mm_setzero_si128();
    __m128i cost3 = _mm_setzero_si128();
    __m128i cost4 = _mm_setzero_si128();
    __m128i pdata;

    for (; i + SIMD_WIDTH <= bytes_per_line; i += SIMD_WIDTH) {
      pdata = PredictVec!1(current_row_buf + i, top_buf + i, left_buf + i,
                           topleft_buf + i);
      AddApproxCost(cost1, pdata, bit_costs);

      pdata = PredictVec!2(current_row_buf + i, top_buf + i, left_buf + i,
                           topleft_buf + i);
      AddApproxCost(cost2, pdata, bit_costs);

      pdata = PredictVec!3(current_row_buf + i, top_buf + i, left_buf + i,
                           topleft_buf + i);
      AddApproxCost(cost3, pdata, bit_costs);

      pdata = PredictVec!4(current_row_buf + i, top_buf + i, left_buf + i,
                           topleft_buf + i);
      AddApproxCost(cost4, pdata, bit_costs);
      _mm_store_si128(cast(__m128i *)(paeth_data + i), pdata);
    }

    size_t bytes_remaining =
        bytes_per_line ^ i; // equivalent to `bytes_per_line - i`
    if (bytes_remaining) {
      auto maskv = _mm_loadu_si128(cast(__m128i *)(kMaskVec - bytes_remaining));

      pdata = PredictVec!1(current_row_buf + i, top_buf + i, left_buf + i,
                           topleft_buf + i);
      AddApproxCost(cost1, pdata, bit_costs, maskv);

      pdata = PredictVec!2(current_row_buf + i, top_buf + i, left_buf + i,
                            topleft_buf + i);
      AddApproxCost(cost2, pdata, bit_costs, maskv);

      pdata = PredictVec!3(current_row_buf + i, top_buf + i, left_buf + i,
                            topleft_buf + i);
      AddApproxCost(cost3, pdata, bit_costs, maskv);

      pdata = PredictVec!4(current_row_buf + i, top_buf + i, left_buf + i,
                            topleft_buf + i);
      AddApproxCost(cost4, pdata, bit_costs, maskv);
      _mm_store_si128(cast(__m128i *)(paeth_data + i), pdata);
    }

    ubyte predictor = 1;
    size_t best_cost = hadd(cost1);
    void test_cost(__m128i costv, ubyte pred) 
    {
      size_t cost = hadd(costv);
      if (cost < best_cost) 
      {
        best_cost = cost;
        predictor = pred;
      }
    }
    test_cost(cost2, 2);
    test_cost(cost3, 3);
    test_cost(cost4, 4);
    return predictor;
  }

  assert(options.predictor == FPNGE_PREDICTOR_BEST);
  ubyte predictor;
  size_t best_cost = ~0U;
  TryPredictor!(1, /*store_pred=*/false)(bytes_per_line, current_row_buf,
                                        top_buf, left_buf, topleft_buf, null,
                                        table, best_cost, predictor);
  TryPredictor!(2, /*store_pred=*/false)(bytes_per_line, current_row_buf,
                                        top_buf, left_buf, topleft_buf, null,
                                        table, best_cost, predictor);
  TryPredictor!(3, /*store_pred=*/false)(bytes_per_line, current_row_buf,
                                        top_buf, left_buf, topleft_buf, null,
                                        table, best_cost, predictor);
  TryPredictor!(4, /*store_pred=*/true)(bytes_per_line, current_row_buf, top_buf,
                                       left_buf, topleft_buf, paeth_data, table,
                                       best_cost, predictor);
  return predictor;
}

void EncodeOneRow(size_t bytes_per_line, const ubyte *current_row_buf,
                  const ubyte *top_buf, const ubyte *left_buf,
                  const ubyte *topleft_buf, ubyte *paeth_data,
                  ref const HuffmanTable table, ref uint s1, ref uint s2,
                  BitWriter * writer, const FPNGEOptions *options) 
{
  ubyte predictor =
      SelectPredictor(bytes_per_line, current_row_buf, top_buf, left_buf,
                      topleft_buf, paeth_data, table, options);

  writer.Write(table.first16_nbits[predictor], table.first16_bits[predictor]);
  UpdateAdler32(s1, s2, predictor);

  auto adler_accum_s1 = _mm_cvtsi32_si128(s1);
  auto adler_accum_s2 = _mm_cvtsi32_si128(s2);
  auto adler_s1_sum = _mm_setzero_si128();

  ushort bytes_since_flush = 1;

  void flush_adler() nothrow @nogc
  {
    adler_accum_s2 = _mm_add_epi32(
        adler_accum_s2, _mm_slli_epi32(adler_s1_sum, SIMD_WIDTH == 32 ? 5 : 4));
    adler_s1_sum = _mm_setzero_si128();

    uint ls1 = hadd(adler_accum_s1);
    uint ls2 = hadd(adler_accum_s2);
    ls1 %= kAdler32Mod;
    ls2 %= kAdler32Mod;
    s1 = ls1;
    s2 = ls2;
    adler_accum_s1 = _mm_cvtsi32_si128(s1);
    adler_accum_s2 = _mm_cvtsi32_si128(s2);
    bytes_since_flush = 0;
  }

  void encode_chunk_cb(__m128i bytes, size_t bytes_in_vec) nothrow @nogc
  {
    auto maskv = _mm_loadu_si128(cast(__m128i *)(kMaskVec - bytes_in_vec));

    auto data_for_lut = _mm_and_si128(_mm_set1_epi8(0xF), bytes);
    data_for_lut = _mm_or_si128(data_for_lut, maskv);
    // get a mask of `bytes` that are between -16 and 15 inclusive
    // (`-16 <= bytes <= 15` is equivalent to `bytes + 112 > 95`)
    auto use_lowhi = _mm_cmpgt_epi8(_mm_add_epi8(bytes, _mm_set1_epi8(112)),
                                    _mm_set1_epi8(95));

    auto nbits_low16 = _mm_shuffle_epi8(
        (_mm_load_si128(cast(__m128i *)table.first16_nbits)), data_for_lut);
    auto nbits_hi16 = _mm_shuffle_epi8(
        (_mm_load_si128(cast(__m128i *)table.last16_nbits)), data_for_lut);
    auto nbits = _mm_blendv_epi8(nbits_low16, nbits_hi16, bytes);

    auto bits_low16 = _mm_shuffle_epi8(
        (_mm_load_si128(cast(__m128i *)table.first16_bits)), data_for_lut);
    auto bits_hi16 = _mm_shuffle_epi8(
        (_mm_load_si128(cast(__m128i *)table.last16_bits)), data_for_lut);
    auto bits_lo = _mm_blendv_epi8(bits_low16, bits_hi16, bytes);

    if (_mm_movemask_epi8(use_lowhi) ^ SIMD_MASK) {
      auto data_for_midlut =
          _mm_and_si128(_mm_set1_epi8(0xF), _mm_srai_epi16(bytes, 4));

      auto bits_mid_lo = _mm_shuffle_epi8(
          (_mm_load_si128(cast(__m128i *)table.mid_lowbits)),
          data_for_midlut);

      auto bits_hi = _mm_shuffle_epi8(
          (_mm_load_si128(cast(__m128i *)kBitReverseNibbleLookup)),
          data_for_lut);

      use_lowhi = _mm_or_si128(use_lowhi, maskv);
      nbits = _mm_blendv_epi8(_mm_set1_epi8(table.mid_nbits), nbits, use_lowhi);
      bits_lo = _mm_blendv_epi8(bits_mid_lo, bits_lo, use_lowhi);

      bits_hi = _mm_andnot_si128(use_lowhi, bits_hi);

      WriteBitsLong(nbits, bits_lo, bits_hi, table.mid_nbits - 4, writer);
    } else {
      // since mid (symbols 16-239) is not present, we can take some shortcuts
      // this is expected to occur frequently if compression is effective
      WriteBitsShort(nbits, bits_lo, writer);
    }
  }

  void adler_chunk_cb(__m128i pdata, size_t bytes_in_vec, size_t) 
  {
    bytes_since_flush += bytes_in_vec;
    auto bytes = pdata;

    auto muls = _mm_set_epi8(
        1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16
    );

    if (bytes_in_vec < SIMD_WIDTH) {
      adler_accum_s2 = _mm_add_epi32(
          _mm_mul_epu32(_mm_set1_epi32(cast(int)bytes_in_vec), adler_accum_s1),
          adler_accum_s2);
      bytes =
          _mm_andnot_si128(_mm_loadu_si128(cast(__m128i *)(kMaskVec - bytes_in_vec)), bytes);
      muls = _mm_add_epi8(muls, _mm_set1_epi8(cast(byte)(bytes_in_vec - SIMD_WIDTH)));
    } else {
      adler_s1_sum = _mm_add_epi32(adler_s1_sum, adler_accum_s1);
    }

    adler_accum_s1 =
        _mm_add_epi32(adler_accum_s1, _mm_sad_epu8(bytes, _mm_setzero_si128()));

    auto bytesmuls = _mm_maddubs_epi16(bytes, muls);
    adler_accum_s2 = _mm_add_epi32(
        adler_accum_s2, _mm_madd_epi16(bytesmuls, _mm_set1_epi16(1)));

    if (bytes_since_flush >= 5500) {
      flush_adler();
    }
  }

  void encode_rle_cb(size_t run) nothrow @nogc
  {
    writer.Write(table.first16_nbits[0], table.first16_bits[0]);

    void writeThings(size_t len, size_t count) nothrow @nogc
    {
        uint bits = (table.dist_bits << table.lz77_length_nbits[len]) |
            table.lz77_length_bits[len];
        auto nbits = table.lz77_length_nbits[len] + table.dist_nbits;
        while (count--) {
            writer.Write(nbits, bits);
        }
    }
    ForAllRLESymbols(run, &writeThings);
  }

  if (options.predictor > 4 && predictor == 4) 
  {
    // re-use Paeth data
    ProcessRow!0(bytes_per_line, paeth_data, null, null, null,
                 &encode_chunk_cb, &adler_chunk_cb, &encode_rle_cb);
  } else {
    ProcessRowPred(predictor, bytes_per_line, current_row_buf, top_buf, left_buf,
               topleft_buf, &encode_chunk_cb, &adler_chunk_cb, &encode_rle_cb);
  }

  flush_adler();
}

static void
CollectSymbolCounts(size_t bytes_per_line, const ubyte *current_row_buf,
                    const ubyte *top_buf, const ubyte *left_buf,
                    const ubyte *topleft_buf, ubyte *paeth_data,
                    ulong * symbol_counts,
                    const FPNGEOptions *options) {

  void encode_chunk_cb(__m128i pdata, size_t bytes_in_vec) nothrow @nogc
  {
    align(SIMD_WIDTH) ubyte[SIMD_WIDTH] predicted_data;
    _mm_store_si128(cast(__m128i *)predicted_data, pdata);
    for (size_t i = 0; i < bytes_in_vec; i++) {
      symbol_counts[predicted_data[i]] += 1;
    }
  }

  void adler_chunk_cb(__m128i, size_t, size_t) nothrow @nogc
  {
  }

  void encode_rle_cb(size_t run) nothrow @nogc
  {
    symbol_counts[0] += 1;
    __gshared static immutable size_t[259] kLZ77Sym = [
        0,   0,   0,   257, 258, 259, 260, 261, 262, 263, 264, 265, 265, 266,
        266, 267, 267, 268, 268, 269, 269, 269, 269, 270, 270, 270, 270, 271,
        271, 271, 271, 272, 272, 272, 272, 273, 273, 273, 273, 273, 273, 273,
        273, 274, 274, 274, 274, 274, 274, 274, 274, 275, 275, 275, 275, 275,
        275, 275, 275, 276, 276, 276, 276, 276, 276, 276, 276, 277, 277, 277,
        277, 277, 277, 277, 277, 277, 277, 277, 277, 277, 277, 277, 277, 278,
        278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278,
        278, 279, 279, 279, 279, 279, 279, 279, 279, 279, 279, 279, 279, 279,
        279, 279, 279, 280, 280, 280, 280, 280, 280, 280, 280, 280, 280, 280,
        280, 280, 280, 280, 280, 281, 281, 281, 281, 281, 281, 281, 281, 281,
        281, 281, 281, 281, 281, 281, 281, 281, 281, 281, 281, 281, 281, 281,
        281, 281, 281, 281, 281, 281, 281, 281, 281, 282, 282, 282, 282, 282,
        282, 282, 282, 282, 282, 282, 282, 282, 282, 282, 282, 282, 282, 282,
        282, 282, 282, 282, 282, 282, 282, 282, 282, 282, 282, 282, 282, 283,
        283, 283, 283, 283, 283, 283, 283, 283, 283, 283, 283, 283, 283, 283,
        283, 283, 283, 283, 283, 283, 283, 283, 283, 283, 283, 283, 283, 283,
        283, 283, 283, 284, 284, 284, 284, 284, 284, 284, 284, 284, 284, 284,
        284, 284, 284, 284, 284, 284, 284, 284, 284, 284, 284, 284, 284, 284,
        284, 284, 284, 284, 284, 284, 285,
    ];

    void countThings(size_t len, size_t count) nothrow @nogc
    {
        symbol_counts[kLZ77Sym[len]] += count;
    }
    ForAllRLESymbols(run, &countThings);
  }

  if (options.predictor == FPNGE_PREDICTOR_APPROX) {
    // filter selection here seems to be slightly more effective when using the
    // approximate selector; more investigation is probably warranted
    HuffmanTable dummy_table;
    ubyte predictor =
        SelectPredictor(bytes_per_line, current_row_buf, top_buf, left_buf,
                        topleft_buf, paeth_data, dummy_table, options);
    if (predictor == 4) {
      ProcessRow!0(bytes_per_line, paeth_data, null, null, null,
                   &encode_chunk_cb, &adler_chunk_cb, &encode_rle_cb);
    } else {
      ProcessRowPred(predictor, bytes_per_line, current_row_buf, top_buf, left_buf,
                 topleft_buf, &encode_chunk_cb, &adler_chunk_cb, &encode_rle_cb);
    }
  } else {
    ubyte predictor = cast(ubyte)(options.predictor > 4 ? 4 : options.predictor);
    ProcessRowPred(predictor, bytes_per_line, current_row_buf, top_buf, left_buf,
               topleft_buf, &encode_chunk_cb, &adler_chunk_cb, &encode_rle_cb);
  }
}

static void AppendBE32(size_t value, BitWriter * writer) {
  writer.Write(8, value >> 24);
  writer.Write(8, (value >> 16) & 0xFF);
  writer.Write(8, (value >> 8) & 0xFF);
  writer.Write(8, value & 0xFF);
}

static void WriteHeader(size_t width, size_t height, size_t bytes_per_channel,
                        size_t num_channels, FPNGECicpColorspace cicp_colorspace,
                        BitWriter * writer) {
  __gshared static immutable ubyte[8] kPNGHeader = [137, 80, 78, 71, 13, 10, 26, 10];
  for (size_t i = 0; i < 8; i++) {
    writer.Write(8, kPNGHeader[i]);
  }
  // Length
  writer.Write(32, 0x0d000000);
  assert(writer.bits_in_buffer == 0);
  size_t crc_start = writer.bytes_written;
  // IHDR
  writer.Write(32, 0x52444849);
  AppendBE32(width, writer);
  AppendBE32(height, writer);
  // Bit depth
  writer.Write(8, bytes_per_channel * 8);
  // Colour type
  __gshared static immutable ubyte[5] numc_to_colour_type = [0, 0, 4, 2, 6];
  writer.Write(8, numc_to_colour_type[num_channels]);
  // Compression, filter and interlace methods.
  writer.Write(24, 0);
  assert(writer.bits_in_buffer == 0);
  size_t crc_end = writer.bytes_written;

  Crc32 crcHeader;
  crcHeader.initialize();
  uint crc = crcHeader.update_final(writer.data + crc_start, crc_end - crc_start);
  AppendBE32(crc, writer);

  if (cicp_colorspace == FPNGE_CICP_PQ) {
    writer.Write(32, 0x04000000);
    writer.Write(32, 0x50434963); // cICP
    writer.Write(32, 0x01001009); // PQ, Rec2020
    writer.Write(32, 0xfe23234d); // CRC
  }
}

// bytes_per_channel = 1/2 for 8-bit and 16-bit. num_channels: 1/2/3/4
// (G/GA/RGB/RGBA)

size_t FPNGEEncode(size_t bytes_per_channel, 
                   size_t num_channels,
                   const(void)*data, 
                   size_t width, 
                   ptrdiff_t row_stride, // in bytes, can be negative
                   size_t height, 
                   void *output,
                   const(FPNGEOptions)* options) 
{
  assert(bytes_per_channel == 1 || bytes_per_channel == 2);
  assert(num_channels != 0 && num_channels <= 4);
  size_t bytes_per_line = bytes_per_channel * num_channels * width;

  // allows for padding, and for extra initial space for the "left" pixel for
  // predictors.
  size_t bytes_per_line_buf =
      (bytes_per_line + 4 * bytes_per_channel + SIMD_WIDTH - 1) / SIMD_WIDTH *
      SIMD_WIDTH;

  // Extra space for alignment purposes.

  size_t buf_len = bytes_per_line_buf * 2 + SIMD_WIDTH - 1 + 4 * bytes_per_channel;
  ubyte* buf = cast(ubyte*) malloc(buf_len);
  scope(exit) free(buf);
  
  ubyte *aligned_buf_ptr = buf + 4 * bytes_per_channel;
  aligned_buf_ptr += cast(ptrdiff_t)aligned_buf_ptr % SIMD_WIDTH
                         ? (SIMD_WIDTH - cast(ptrdiff_t)aligned_buf_ptr % SIMD_WIDTH)
                         : 0;

  ubyte* pdata_buf = cast(ubyte*) malloc(bytes_per_line_buf + SIMD_WIDTH - 1);
  scope(exit) free(pdata_buf);

  ubyte *aligned_pdata_ptr = pdata_buf;
  aligned_pdata_ptr +=
      cast(ptrdiff_t)aligned_pdata_ptr % SIMD_WIDTH
          ? (SIMD_WIDTH - cast(ptrdiff_t)aligned_pdata_ptr % SIMD_WIDTH)
          : 0;

  FPNGEOptions default_options;
  if (options == null) {
    FPNGEFillOptions(&default_options, FPNGE_COMPRESS_LEVEL_DEFAULT,
                     FPNGE_CICP_NONE);
    options = &default_options;
  }

  // options sanity check
  assert(options.predictor >= 0 && options.predictor <= FPNGE_PREDICTOR_BEST);
  assert(options.huffman_sample >= 0 && options.huffman_sample <= 127);

  BitWriter writer;
  writer.data = cast(ubyte*)(output);

  WriteHeader(width, height, bytes_per_channel, num_channels,
              options.cicp_colorspace, &writer);

  assert(writer.bits_in_buffer == 0);
  size_t chunk_length_pos = writer.bytes_written;
  writer.bytes_written += 4; // Skip space for length.
  size_t crc_pos = writer.bytes_written;
  writer.Write(32, 0x54414449); // IDAT
  // Deflate header
  writer.Write(8, 8);  // deflate with smallest window
  writer.Write(8, 29); // cfm+flg check value

  // TODO That's a bit much on the stack, no?
  ulong[286] symbol_counts;
  symbol_counts[] = 0;

  // Sample rows in the center of the image.
  size_t y0 = height * (127 - options.huffman_sample) / 256;
  size_t y1 = height * (129 + options.huffman_sample) / 256;
  if (y1 == 0 && height > 0) { // for 1 pixel high images
    y1 = 1;
  }

  for (size_t y = y0; y < y1; y++) {
    const ubyte *current_row_in =
        cast(const(ubyte)*)(data) + row_stride * y;
    ubyte *current_row_buf =
        aligned_buf_ptr + (y % 2 ? bytes_per_line_buf : 0);
    const ubyte *top_buf =
        aligned_buf_ptr + ((y + 1) % 2 ? bytes_per_line_buf : 0);
    const ubyte *left_buf =
        current_row_buf - bytes_per_channel * num_channels;
    const ubyte *topleft_buf =
        top_buf - bytes_per_channel * num_channels;

    memcpy(current_row_buf, current_row_in, bytes_per_line);
    if (y == y0 && y != 0) {
      continue;
    }

    CollectSymbolCounts(bytes_per_line, current_row_buf, top_buf, left_buf,
                        topleft_buf, aligned_pdata_ptr, symbol_counts.ptr, options);
  }

  memset(buf, 0, buf_len);

  HuffmanTable huffman_table;
  huffman_table.initialize(symbol_counts.ptr);

  // Single block, dynamic huffman
  writer.Write(3, 0b101);
  WriteHuffmanCode(huffman_table, &writer);

  Crc32 crc;
  crc.initialize();
  uint s1 = 1;
  uint s2 = 0;
  for (size_t y = 0; y < height; y++) {
    const ubyte *current_row_in =
        cast(const(ubyte)*)(data) + row_stride * y;
    ubyte *current_row_buf =
        aligned_buf_ptr + (y % 2 ? bytes_per_line_buf : 0);
    const ubyte *top_buf =
        aligned_buf_ptr + ((y + 1) % 2 ? bytes_per_line_buf : 0);
    const ubyte *left_buf =
        current_row_buf - bytes_per_channel * num_channels;
    const ubyte *topleft_buf =
        top_buf - bytes_per_channel * num_channels;

    memcpy(current_row_buf, current_row_in, bytes_per_line);

    EncodeOneRow(bytes_per_line, current_row_buf, top_buf, left_buf,
                 topleft_buf, aligned_pdata_ptr, huffman_table, s1, s2, &writer,
                 options);

    crc_pos +=
        crc.update(writer.data + crc_pos, writer.bytes_written - crc_pos);
  }

  // EOB
  writer.Write(huffman_table.nbits[256], huffman_table.end_bits);

  writer.ZeroPadToByte();
  assert(writer.bits_in_buffer == 0);
  s1 %= kAdler32Mod;
  s2 %= kAdler32Mod;
  uint adler32 = (s2 << 16) | s1;
  AppendBE32(adler32, &writer);

  size_t data_len = writer.bytes_written - chunk_length_pos - 8;
  writer.data[chunk_length_pos + 0] = cast(ubyte)(data_len >> 24);
  writer.data[chunk_length_pos + 1] = (data_len >> 16) & 0xFF;
  writer.data[chunk_length_pos + 2] = (data_len >> 8) & 0xFF;
  writer.data[chunk_length_pos + 3] = data_len & 0xFF;

  auto final_crc =
      crc.update_final(writer.data + crc_pos, writer.bytes_written - crc_pos);
  AppendBE32(final_crc, &writer);

  // IEND
  writer.Write(32, 0);
  writer.Write(32, 0x444e4549);
  writer.Write(32, 0x826042ae);

  return writer.bytes_written;
}
