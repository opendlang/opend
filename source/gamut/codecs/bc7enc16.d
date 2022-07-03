/// BC7 encoding image loading.
/// D translation of bc7enc16 d3b037f33b8c6df184177a0ae6a0f4cfec1434ad
module gamut.codecs.bc7enc16;

import core.stdc.string: memset, memcpy;
import std.math: abs, sqrt, floor;
import gamut.internals.mutex;

// File: bc7enc16.h - Richard Geldreich, Jr. - MIT license or public domain (see end of bc7enc16.c)

enum BC7ENC16_BLOCK_SIZE = 16;
enum BC7ENC16_MAX_PARTITIONS1 = 64;
enum BC7ENC16_MAX_UBER_LEVEL = 4;

alias bc7enc16_bool = ubyte;
enum BC7ENC16_TRUE = 1;
enum BC7ENC16_FALSE = 0;

nothrow @nogc @safe:

struct bc7enc16_compress_block_params
{
    // m_max_partitions_mode1 may range from 0 (disables mode 1) to BC7ENC16_MAX_PARTITIONS1. The higher this value, the slower the compressor, but the higher the quality.
    uint m_max_partitions_mode1;
    
    // Relative RGBA or YCbCrA weights.
    uint[4] m_weights;
    
    // m_uber_level may range from 0 to BC7ENC16_MAX_UBER_LEVEL. The higher this value, the slower the compressor, but the higher the quality.
    uint m_uber_level;

    // If m_perceptual is true, colorspace error is computed in YCbCr space, otherwise RGB.
    bc7enc16_bool m_perceptual;

    // Set m_try_least_squares to false for slightly faster/lower quality compression.
    bc7enc16_bool m_try_least_squares;
    
    // When m_mode1_partition_estimation_filterbank, the mode1 partition estimator skips lesser used partition patterns unless they are strongly predicted to be potentially useful.
    // There's a slight loss in quality with this enabled (around .08 dB RGB PSNR or .05 dB Y PSNR), but up to a 11% gain in speed depending on the other settings.
    bc7enc16_bool m_mode1_partition_estimation_filterbank;
}

void bc7enc16_compress_block_params_init_linear_weights(bc7enc16_compress_block_params *p) pure
{
    p.m_perceptual = BC7ENC16_FALSE;
    p.m_weights[0] = 1;
    p.m_weights[1] = 1;
    p.m_weights[2] = 1;
    p.m_weights[3] = 1;
}

void bc7enc16_compress_block_params_init_perceptual_weights(bc7enc16_compress_block_params *p) pure
{
    p.m_perceptual = BC7ENC16_TRUE;
    p.m_weights[0] = 128;
    p.m_weights[1] = 64;
    p.m_weights[2] = 16;
    p.m_weights[3] = 32;
}

void bc7enc16_compress_block_params_init(bc7enc16_compress_block_params *p) pure
{
    p.m_max_partitions_mode1 = BC7ENC16_MAX_PARTITIONS1;
    p.m_try_least_squares = BC7ENC16_TRUE;
    p.m_mode1_partition_estimation_filterbank = BC7ENC16_TRUE;
    p.m_uber_level = 0;
    bc7enc16_compress_block_params_init_perceptual_weights(p);
}


// File: bc7enc16.c - Richard Geldreich, Jr. 4/2018 - MIT license or public domain (see end of file)

// Helpers
int clampi(int value, int low, int high) pure
{ 
    if (value < low) 
        value = low; 
    else if (value > high) 
        value = high;   
    return value; 
}

float clampf(float value, float low, float high) pure
{ 
    if (value < low) 
        value = low; 
    else if (value > high) 
        value = high;   
    return value; 
}

float saturate(float value) pure
{ 
    return clampf(value, 0, 1.0f); 
}

ubyte minimumub(ubyte a, ubyte b) pure
{ 
    return (a < b) ? a : b; 
}

uint minimumu(uint a, uint b) pure
{ 
    return (a < b) ? a : b; 
}

float minimumf(float a, float b) pure
{ 
    return (a < b) ? a : b; 
}

ubyte maximumub(ubyte a, ubyte b) pure
{ 
    return (a > b) ? a : b; 
}

uint maximumu(uint a, uint b) pure
{
    return (a > b) ? a : b; 
}

float maximumf(float a, float b) pure
{ 
    return (a > b) ? a : b; 
}

int squarei(int i) pure 
{ 
    return i * i; 
}

float squaref(float i) pure
{ 
    return i * i; 
}

struct color_quad_u8 
{ 
    ubyte[4] m_c; 
}

struct vec4F 
{ 
    float[4] m_c; 
}

color_quad_u8 *color_quad_u8_set_clamped(color_quad_u8 *pRes, int r, int g, int b, int a) pure @system
{
    pRes.m_c[0] = cast(ubyte)clampi(r, 0, 255); 
    pRes.m_c[1] = cast(ubyte)clampi(g, 0, 255); 
    pRes.m_c[2] = cast(ubyte)clampi(b, 0, 255); 
    pRes.m_c[3] = cast(ubyte)clampi(a, 0, 255); 
    return pRes; 
}

color_quad_u8 *color_quad_u8_set(color_quad_u8 *pRes, int r, int g, int b, int a) pure @system
{
    assert(cast(uint)(r | g | b | a) <= 255); 
    pRes.m_c[0] = cast(ubyte)r; 
    pRes.m_c[1] = cast(ubyte)g; 
    pRes.m_c[2] = cast(ubyte)b; 
    pRes.m_c[3] = cast(ubyte)a; 
    return pRes; 
}

bc7enc16_bool color_quad_u8_notequals(ref const(color_quad_u8) pLHS, ref const(color_quad_u8) pRHS) pure
{
    return (pLHS.m_c[0] != pRHS.m_c[0]) 
        || (pLHS.m_c[1] != pRHS.m_c[1]) 
        || (pLHS.m_c[2] != pRHS.m_c[2]) 
        || (pLHS.m_c[3] != pRHS.m_c[3]); 
}

vec4F* vec4F_set_scalar(vec4F *pV, float x) pure
{
    pV.m_c[0] = x; 
    pV.m_c[1] = x;
    pV.m_c[2] = x;  
    pV.m_c[3] = x;
    return pV; 
}

vec4F* vec4F_set(vec4F *pV, float x, float y, float z, float w) pure
{
    pV.m_c[0] = x;  
    pV.m_c[1] = y;  
    pV.m_c[2] = z;  
    pV.m_c[3] = w;  
    return pV; 
}

void vec4F_saturate_in_place(ref vec4F pV) pure
{
    pV.m_c[0] = saturate(pV.m_c[0]); 
    pV.m_c[1] = saturate(pV.m_c[1]); 
    pV.m_c[2] = saturate(pV.m_c[2]); 
    pV.m_c[3] = saturate(pV.m_c[3]); 
}

vec4F vec4F_saturate(const(vec4F)* pV) pure 
{ 
    vec4F res; 
    res.m_c[0] = saturate(pV.m_c[0]); 
    res.m_c[1] = saturate(pV.m_c[1]); 
    res.m_c[2] = saturate(pV.m_c[2]); 
    res.m_c[3] = saturate(pV.m_c[3]); 
    return res; 
}

vec4F vec4F_from_color(const(color_quad_u8)* pC) pure @trusted
{ 
    vec4F res; 
    vec4F_set(&res, pC.m_c[0], pC.m_c[1], pC.m_c[2], pC.m_c[3]); 
    return res; 
}

vec4F vec4F_add(const(vec4F)* pLHS, const(vec4F)* pRHS) pure @trusted
{ 
    vec4F res; 
    vec4F_set(&res, pLHS.m_c[0] + pRHS.m_c[0], pLHS.m_c[1] + pRHS.m_c[1], 
                    pLHS.m_c[2] + pRHS.m_c[2], pLHS.m_c[3] + pRHS.m_c[3]); 
    return res; 
}

vec4F vec4F_sub(const(vec4F)* pLHS, const(vec4F)* pRHS) pure @trusted
{ 
    vec4F res; 
    vec4F_set(&res, pLHS.m_c[0] - pRHS.m_c[0], pLHS.m_c[1] - pRHS.m_c[1], 
                    pLHS.m_c[2] - pRHS.m_c[2], pLHS.m_c[3] - pRHS.m_c[3]); 
    return res; 
}

float vec4F_dot(const(vec4F)* pLHS, const(vec4F)* pRHS) pure 
{ 
    return pLHS.m_c[0] * pRHS.m_c[0] + pLHS.m_c[1] * pRHS.m_c[1] 
         + pLHS.m_c[2] * pRHS.m_c[2] + pLHS.m_c[3] * pRHS.m_c[3]; 
}

vec4F vec4F_mul(const(vec4F)* pLHS, float s) pure @trusted
{ 
    vec4F res; vec4F_set(&res, pLHS.m_c[0] * s, pLHS.m_c[1] * s, 
                               pLHS.m_c[2] * s, pLHS.m_c[3] * s); 
    return res; 
}

vec4F* vec4F_normalize_in_place(vec4F *pV) pure
{ 
    float s = pV.m_c[0] * pV.m_c[0] + pV.m_c[1] * pV.m_c[1] + pV.m_c[2] * pV.m_c[2] + pV.m_c[3] * pV.m_c[3]; 
    if (s != 0.0f) 
    { 
        s = 1.0f / sqrt(s); 
        pV.m_c[0] *= s; 
        pV.m_c[1] *= s; 
        pV.m_c[2] *= s; 
        pV.m_c[3] *= s; 
    } 
    return pV; 
}

// Various BC7 tables
static immutable uint[8] g_bc7_weights3 = [ 0, 9, 18, 27, 37, 46, 55, 64 ];
static immutable uint[16] g_bc7_weights4 = [ 0, 4, 9, 13, 17, 21, 26, 30, 34, 38, 43, 47, 51, 55, 60, 64 ];
// Precomputed weight constants used during least fit determination. For each entry in g_bc7_weights[]: w * w, (1.0f - w) * w, (1.0f - w) * (1.0f - w), w
static immutable float[8 * 4] g_bc7_weights3x = 
[ 0.000000f, 0.000000f, 1.000000f, 0.000000f, 0.019775f, 0.120850f, 0.738525f, 0.140625f, 
  0.079102f, 0.202148f, 0.516602f, 0.281250f, 0.177979f, 0.243896f, 0.334229f, 0.421875f, 
  0.334229f, 0.243896f, 0.177979f, 0.578125f, 0.516602f, 0.202148f, 0.079102f, 0.718750f, 
  0.738525f, 0.120850f, 0.019775f, 0.859375f, 1.000000f, 0.000000f, 0.000000f, 1.000000f ];

static immutable float[16 * 4] g_bc7_weights4x = 
[ 0.000000f, 0.000000f, 1.000000f, 0.000000f, 0.003906f, 0.058594f, 0.878906f, 0.062500f, 
  0.019775f, 0.120850f, 0.738525f, 0.140625f, 0.041260f, 0.161865f, 0.635010f, 0.203125f, 
  0.070557f, 0.195068f, 0.539307f, 0.265625f, 0.107666f, 0.220459f, 0.451416f, 0.328125f, 
  0.165039f, 0.241211f, 0.352539f, 0.406250f, 0.219727f, 0.249023f, 0.282227f, 0.468750f, 
  0.282227f, 0.249023f, 0.219727f, 0.531250f, 0.352539f, 0.241211f, 0.165039f, 0.593750f, 
  0.451416f, 0.220459f, 0.107666f, 0.671875f, 0.539307f, 0.195068f, 0.070557f, 0.734375f,
  0.635010f, 0.161865f, 0.041260f, 0.796875f, 0.738525f, 0.120850f, 0.019775f, 0.859375f, 
  0.878906f, 0.058594f, 0.003906f, 0.937500f, 1.000000f, 0.000000f, 0.000000f, 1.000000f ];

static immutable ubyte[64] g_bc7_partition1 = [ 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 ];
static immutable ubyte[64*16] g_bc7_partition2 =
[
    0,0,1,1,0,0,1,1,0,0,1,1,0,0,1,1,        0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,        0,1,1,1,0,1,1,1,0,1,1,1,0,1,1,1,        0,0,0,1,0,0,1,1,0,0,1,1,0,1,1,1,        0,0,0,0,0,0,0,1,0,0,0,1,0,0,1,1,        0,0,1,1,0,1,1,1,0,1,1,1,1,1,1,1,        0,0,0,1,0,0,1,1,0,1,1,1,1,1,1,1,        0,0,0,0,0,0,0,1,0,0,1,1,0,1,1,1,
    0,0,0,0,0,0,0,0,0,0,0,1,0,0,1,1,        0,0,1,1,0,1,1,1,1,1,1,1,1,1,1,1,        0,0,0,0,0,0,0,1,0,1,1,1,1,1,1,1,        0,0,0,0,0,0,0,0,0,0,0,1,0,1,1,1,        0,0,0,1,0,1,1,1,1,1,1,1,1,1,1,1,        0,0,0,0,0,0,0,0,1,1,1,1,1,1,1,1,        0,0,0,0,1,1,1,1,1,1,1,1,1,1,1,1,        0,0,0,0,0,0,0,0,0,0,0,0,1,1,1,1,
    0,0,0,0,1,0,0,0,1,1,1,0,1,1,1,1,        0,1,1,1,0,0,0,1,0,0,0,0,0,0,0,0,        0,0,0,0,0,0,0,0,1,0,0,0,1,1,1,0,        0,1,1,1,0,0,1,1,0,0,0,1,0,0,0,0,        0,0,1,1,0,0,0,1,0,0,0,0,0,0,0,0,        0,0,0,0,1,0,0,0,1,1,0,0,1,1,1,0,        0,0,0,0,0,0,0,0,1,0,0,0,1,1,0,0,        0,1,1,1,0,0,1,1,0,0,1,1,0,0,0,1,
    0,0,1,1,0,0,0,1,0,0,0,1,0,0,0,0,        0,0,0,0,1,0,0,0,1,0,0,0,1,1,0,0,        0,1,1,0,0,1,1,0,0,1,1,0,0,1,1,0,        0,0,1,1,0,1,1,0,0,1,1,0,1,1,0,0,        0,0,0,1,0,1,1,1,1,1,1,0,1,0,0,0,        0,0,0,0,1,1,1,1,1,1,1,1,0,0,0,0,        0,1,1,1,0,0,0,1,1,0,0,0,1,1,1,0,        0,0,1,1,1,0,0,1,1,0,0,1,1,1,0,0,
    0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,        0,0,0,0,1,1,1,1,0,0,0,0,1,1,1,1,        0,1,0,1,1,0,1,0,0,1,0,1,1,0,1,0,        0,0,1,1,0,0,1,1,1,1,0,0,1,1,0,0,        0,0,1,1,1,1,0,0,0,0,1,1,1,1,0,0,        0,1,0,1,0,1,0,1,1,0,1,0,1,0,1,0,        0,1,1,0,1,0,0,1,0,1,1,0,1,0,0,1,        0,1,0,1,1,0,1,0,1,0,1,0,0,1,0,1,
    0,1,1,1,0,0,1,1,1,1,0,0,1,1,1,0,        0,0,0,1,0,0,1,1,1,1,0,0,1,0,0,0,        0,0,1,1,0,0,1,0,0,1,0,0,1,1,0,0,        0,0,1,1,1,0,1,1,1,1,0,1,1,1,0,0,        0,1,1,0,1,0,0,1,1,0,0,1,0,1,1,0,        0,0,1,1,1,1,0,0,1,1,0,0,0,0,1,1,        0,1,1,0,0,1,1,0,1,0,0,1,1,0,0,1,        0,0,0,0,0,1,1,0,0,1,1,0,0,0,0,0,
    0,1,0,0,1,1,1,0,0,1,0,0,0,0,0,0,        0,0,1,0,0,1,1,1,0,0,1,0,0,0,0,0,        0,0,0,0,0,0,1,0,0,1,1,1,0,0,1,0,        0,0,0,0,0,1,0,0,1,1,1,0,0,1,0,0,        0,1,1,0,1,1,0,0,1,0,0,1,0,0,1,1,        0,0,1,1,0,1,1,0,1,1,0,0,1,0,0,1,        0,1,1,0,0,0,1,1,1,0,0,1,1,1,0,0,        0,0,1,1,1,0,0,1,1,1,0,0,0,1,1,0,
    0,1,1,0,1,1,0,0,1,1,0,0,1,0,0,1,        0,1,1,0,0,0,1,1,0,0,1,1,1,0,0,1,        0,1,1,1,1,1,1,0,1,0,0,0,0,0,0,1,        0,0,0,1,1,0,0,0,1,1,1,0,0,1,1,1,        0,0,0,0,1,1,1,1,0,0,1,1,0,0,1,1,        0,0,1,1,0,0,1,1,1,1,1,1,0,0,0,0,        0,0,1,0,0,0,1,0,1,1,1,0,1,1,1,0,        0,1,0,0,0,1,0,0,0,1,1,1,0,1,1,1
];

static immutable ubyte[64] g_bc7_table_anchor_index_second_subset = 
    [ 15,15,15,15,15,15,15,15,        15,15,15,15,15,15,15,15,
      15, 2, 8, 2, 2, 8, 8,15,        2, 8, 2, 2, 8, 8, 2, 2,
      15,15, 6, 8, 2, 8,15,15,        2, 8, 2, 2, 2,15,15, 6,
       6, 2, 6, 8,15,15, 2, 2,        15,15,15,15,15, 2, 2,15 ];

static immutable ubyte[8] g_bc7_num_subsets = [ 3, 2, 3, 2, 1, 1, 1, 2 ];
static immutable ubyte[8] g_bc7_partition_bits = [ 4, 6, 6, 6, 0, 0, 0, 6 ];
static immutable ubyte[8] g_bc7_color_index_bitcount = [ 3, 3, 2, 2, 2, 2, 4, 2 ];

int get_bc7_color_index_size(int mode, int index_selection_bit) pure
{ 
    return g_bc7_color_index_bitcount[mode] + index_selection_bit; 
}

static immutable ubyte[8] g_bc7_mode_has_p_bits        = [ 1, 1, 0, 1, 0, 0, 1, 1 ];
static immutable ubyte[8] g_bc7_mode_has_shared_p_bits = [ 0, 1, 0, 0, 0, 0, 0, 0 ];
static immutable ubyte[8] g_bc7_color_precision_table  = [ 4, 6, 5, 7, 5, 7, 7, 5 ];
static immutable byte[8] g_bc7_alpha_precision_table   = [ 0, 0, 0, 0, 6, 8, 7, 5 ];

struct endpoint_err 
{ 
    ushort m_error; 
    ubyte m_lo; 
    ubyte m_hi; 
}

__gshared endpoint_err[2][256] g_bc7_mode_1_optimal_endpoints; // [c][pbit]
__gshared Mutex g_tableProtect;
__gshared bool g_tableInitialized = false;

enum uint BC7ENC16_MODE_1_OPTIMAL_INDEX = 2;

// Initialize the lookup table used for optimal single color compression in mode 1
// Warning: bc7enc16_compress_block_init() MUST be called before calling bc7enc16_compress_block() (or you'll get artifacts).
// Note: this is racey, so we use a self-init mutex.
void bc7enc16_compress_block_init() @trusted
{
    g_tableProtect.lockLazy();
    scope(exit) g_tableProtect.unlock();

    if (g_tableInitialized)
        return;

    g_tableInitialized = true;

    for (int c = 0; c < 256; c++)
    {
        for (uint lp = 0; lp < 2; lp++)
        {
            endpoint_err best;
            best.m_error = ushort.max;
            for (uint l = 0; l < 64; l++)
            {
                uint low = ((l << 1) | lp) << 1;
                low |= (low >> 7);
                for (uint h = 0; h < 64; h++)
                {
                    uint high = ((h << 1) | lp) << 1;
                    high |= (high >> 7);
                    const int k = (low * (64 - g_bc7_weights3[BC7ENC16_MODE_1_OPTIMAL_INDEX]) + high * g_bc7_weights3[BC7ENC16_MODE_1_OPTIMAL_INDEX] + 32) >> 6;
                    const int err = (k - c) * (k - c);
                    if (err < best.m_error)
                    {
                        best.m_error = cast(ushort)err;
                        best.m_lo = cast(ubyte)l;
                        best.m_hi = cast(ubyte)h;
                    }
                }
            }
            g_bc7_mode_1_optimal_endpoints[c][lp] = best;
        }
    }
}

void compute_least_squares_endpoints_rgba(uint N, 
                                          const(ubyte)* pSelectors, 
                                          const(vec4F)* pSelector_weights, 
                                          vec4F *pXl, 
                                          vec4F *pXh, 
                                          const(color_quad_u8)* pColors) @system
{
    // Least squares using normal equations: http://www.cs.cornell.edu/~bindel/class/cs3220-s12/notes/lec10.pdf
    // I did this in matrix form first, expanded out all the ops, then optimized it a bit.
    float z00 = 0.0f, z01 = 0.0f, z10 = 0.0f, z11 = 0.0f;
    float q00_r = 0.0f, q10_r = 0.0f, t_r = 0.0f;
    float q00_g = 0.0f, q10_g = 0.0f, t_g = 0.0f;
    float q00_b = 0.0f, q10_b = 0.0f, t_b = 0.0f;
    float q00_a = 0.0f, q10_a = 0.0f, t_a = 0.0f;
    for (uint i = 0; i < N; i++)
    {
        const uint sel = pSelectors[i];
        z00 += pSelector_weights[sel].m_c[0];
        z10 += pSelector_weights[sel].m_c[1];
        z11 += pSelector_weights[sel].m_c[2];
        float w = pSelector_weights[sel].m_c[3];
        q00_r += w * pColors[i].m_c[0]; t_r += pColors[i].m_c[0];
        q00_g += w * pColors[i].m_c[1]; t_g += pColors[i].m_c[1];
        q00_b += w * pColors[i].m_c[2]; t_b += pColors[i].m_c[2];
        q00_a += w * pColors[i].m_c[3]; t_a += pColors[i].m_c[3];
    }

    q10_r = t_r - q00_r;
    q10_g = t_g - q00_g;
    q10_b = t_b - q00_b;
    q10_a = t_a - q00_a;

    z01 = z10;

    float det = z00 * z11 - z01 * z10;
    if (det != 0.0f)
        det = 1.0f / det;

    float iz00, iz01, iz10, iz11;
    iz00 = z11 * det;
    iz01 = -z01 * det;
    iz10 = -z10 * det;
    iz11 = z00 * det;

    pXl.m_c[0] = cast(float)(iz00 * q00_r + iz01 * q10_r); pXh.m_c[0] = cast(float)(iz10 * q00_r + iz11 * q10_r);
    pXl.m_c[1] = cast(float)(iz00 * q00_g + iz01 * q10_g); pXh.m_c[1] = cast(float)(iz10 * q00_g + iz11 * q10_g);
    pXl.m_c[2] = cast(float)(iz00 * q00_b + iz01 * q10_b); pXh.m_c[2] = cast(float)(iz10 * q00_b + iz11 * q10_b);
    pXl.m_c[3] = cast(float)(iz00 * q00_a + iz01 * q10_a); pXh.m_c[3] = cast(float)(iz10 * q00_a + iz11 * q10_a);
}

void compute_least_squares_endpoints_rgb(uint N, const ubyte *pSelectors, 
                                         const(vec4F)* pSelector_weights, 
                                         vec4F *pXl, vec4F *pXh, const(color_quad_u8)*pColors) @system
{
    float z00 = 0.0f, z01 = 0.0f, z10 = 0.0f, z11 = 0.0f;
    float q00_r = 0.0f, q10_r = 0.0f, t_r = 0.0f;
    float q00_g = 0.0f, q10_g = 0.0f, t_g = 0.0f;
    float q00_b = 0.0f, q10_b = 0.0f, t_b = 0.0f;
    for (uint i = 0; i < N; i++)
    {
        const uint sel = pSelectors[i];
        z00 += pSelector_weights[sel].m_c[0];
        z10 += pSelector_weights[sel].m_c[1];
        z11 += pSelector_weights[sel].m_c[2];
        float w = pSelector_weights[sel].m_c[3];
        q00_r += w * pColors[i].m_c[0]; t_r += pColors[i].m_c[0];
        q00_g += w * pColors[i].m_c[1]; t_g += pColors[i].m_c[1];
        q00_b += w * pColors[i].m_c[2]; t_b += pColors[i].m_c[2];
    }

    q10_r = t_r - q00_r;
    q10_g = t_g - q00_g;
    q10_b = t_b - q00_b;

    z01 = z10;

    float det = z00 * z11 - z01 * z10;
    if (det != 0.0f)
        det = 1.0f / det;

    float iz00, iz01, iz10, iz11;
    iz00 = z11 * det;
    iz01 = -z01 * det;
    iz10 = -z10 * det;
    iz11 = z00 * det;

    pXl.m_c[0] = cast(float)(iz00 * q00_r + iz01 * q10_r); pXh.m_c[0] = cast(float)(iz10 * q00_r + iz11 * q10_r);
    pXl.m_c[1] = cast(float)(iz00 * q00_g + iz01 * q10_g); pXh.m_c[1] = cast(float)(iz10 * q00_g + iz11 * q10_g);
    pXl.m_c[2] = cast(float)(iz00 * q00_b + iz01 * q10_b); pXh.m_c[2] = cast(float)(iz10 * q00_b + iz11 * q10_b);
    pXl.m_c[3] = 255.0f; pXh.m_c[3] = 255.0f;
}

struct color_cell_compressor_params
{
    uint m_num_pixels;
    const(color_quad_u8)* m_pPixels;
    uint m_num_selector_weights;
    const(uint)* m_pSelector_weights;
    const(vec4F)* m_pSelector_weightsx;
    uint m_comp_bits;
    uint[4] m_weights;
    bc7enc16_bool m_has_alpha;
    bc7enc16_bool m_has_pbits;
    bc7enc16_bool m_endpoints_share_pbit;
    bc7enc16_bool m_perceptual;
}

struct color_cell_compressor_results
{
    ulong m_best_overall_err;
    color_quad_u8 m_low_endpoint;
    color_quad_u8 m_high_endpoint;
    uint[2] m_pbits;
    ubyte *m_pSelectors;
    ubyte *m_pSelectors_temp;
}

color_quad_u8 scale_color(ref const(color_quad_u8) pC, const(color_cell_compressor_params) *pParams) pure
{
    color_quad_u8 results;

    const uint n = pParams.m_comp_bits + (pParams.m_has_pbits ? 1 : 0);
    assert((n >= 4) && (n <= 8));

    for (uint i = 0; i < 4; i++)
    {
        uint v = pC.m_c[i] << (8 - n);
        v |= (v >> n);
        assert(v <= 255);
        results.m_c[i] = cast(ubyte)(v);
    }

    return results;
}

ulong compute_color_distance_rgb(const(color_quad_u8)* pE1, 
                                 const(color_quad_u8)* pE2, 
                                 bc7enc16_bool perceptual, 
                                 const(uint)* weights) pure @system
{
    int dr, dg, db;

    if (perceptual)
    {
        const int l1 = pE1.m_c[0] * 109 + pE1.m_c[1] * 366 + pE1.m_c[2] * 37;
        const int cr1 = (cast(int)pE1.m_c[0] << 9) - l1;
        const int cb1 = (cast(int)pE1.m_c[2] << 9) - l1;
        const int l2 = pE2.m_c[0] * 109 + pE2.m_c[1] * 366 + pE2.m_c[2] * 37;
        const int cr2 = (cast(int)pE2.m_c[0] << 9) - l2;
        const int cb2 = (cast(int)pE2.m_c[2] << 9) - l2;
        dr = (l1 - l2) >> 8;
        dg = (cr1 - cr2) >> 8;
        db = (cb1 - cb2) >> 8;
    }
    else
    {
        dr = cast(int)pE1.m_c[0] - cast(int)pE2.m_c[0];
        dg = cast(int)pE1.m_c[1] - cast(int)pE2.m_c[1];
        db = cast(int)pE1.m_c[2] - cast(int)pE2.m_c[2];
    }

    return weights[0] * cast(uint)(dr * dr) + weights[1] * cast(uint)(dg * dg) + weights[2] * cast(uint)(db * db);
}

ulong compute_color_distance_rgba(const(color_quad_u8)* pE1, const(color_quad_u8)* pE2, bc7enc16_bool perceptual, const(uint)* weights /* [4] */) @system
{
    int da = cast(int)pE1.m_c[3] - cast(int)pE2.m_c[3];
    return compute_color_distance_rgb(pE1, pE2, perceptual, weights) + (weights[3] * cast(uint)(da * da));
}

ulong pack_mode1_to_one_color(const(color_cell_compressor_params)* pParams, 
                              color_cell_compressor_results *pResults, 
                              uint r, uint g, uint b, ubyte *pSelectors) @system
{
    uint best_err = uint.max;
    uint best_p = 0;

    for (uint p = 0; p < 2; p++)
    {
        uint err = g_bc7_mode_1_optimal_endpoints[r][p].m_error + g_bc7_mode_1_optimal_endpoints[g][p].m_error + g_bc7_mode_1_optimal_endpoints[b][p].m_error;
        if (err < best_err)
        {
            best_err = err;
            best_p = p;
        }
    }

    const endpoint_err *pEr = &g_bc7_mode_1_optimal_endpoints[r][best_p];
    const endpoint_err *pEg = &g_bc7_mode_1_optimal_endpoints[g][best_p];
    const endpoint_err *pEb = &g_bc7_mode_1_optimal_endpoints[b][best_p];

    color_quad_u8_set(&pResults.m_low_endpoint, pEr.m_lo, pEg.m_lo, pEb.m_lo, 0);
    color_quad_u8_set(&pResults.m_high_endpoint, pEr.m_hi, pEg.m_hi, pEb.m_hi, 0);
    pResults.m_pbits[0] = best_p;
    pResults.m_pbits[1] = 0;

    memset(pSelectors, BC7ENC16_MODE_1_OPTIMAL_INDEX, pParams.m_num_pixels);

    color_quad_u8 p;
    for (uint i = 0; i < 3; i++)
    {
        uint low = ((pResults.m_low_endpoint.m_c[i] << 1) | pResults.m_pbits[0]) << 1;
        low |= (low >> 7);

        uint high = ((pResults.m_high_endpoint.m_c[i] << 1) | pResults.m_pbits[0]) << 1;
        high |= (high >> 7);

        p.m_c[i] = cast(ubyte)((low * (64 - g_bc7_weights3[BC7ENC16_MODE_1_OPTIMAL_INDEX]) + high * g_bc7_weights3[BC7ENC16_MODE_1_OPTIMAL_INDEX] + 32) >> 6);
    }
    p.m_c[3] = 255;

    ulong total_err = 0;
    for (uint i = 0; i < pParams.m_num_pixels; i++)
        total_err += compute_color_distance_rgb(&p, &pParams.m_pPixels[i], pParams.m_perceptual, pParams.m_weights.ptr);

    pResults.m_best_overall_err = total_err;

    return total_err;
}

ulong evaluate_solution(const(color_quad_u8)* pLow, const(color_quad_u8)* pHigh, 
                        const(uint)* pbits /*[2]*/, const(color_cell_compressor_params)* pParams, 
                        color_cell_compressor_results *pResults) @system
{
    color_quad_u8 quantMinColor = *pLow;
    color_quad_u8 quantMaxColor = *pHigh;

    if (pParams.m_has_pbits)
    {
        uint minPBit, maxPBit;

        if (pParams.m_endpoints_share_pbit)
            maxPBit = minPBit = pbits[0];
        else
        {
            minPBit = pbits[0];
            maxPBit = pbits[1];
        }

        quantMinColor.m_c[0] = cast(ubyte)((pLow.m_c[0] << 1) | minPBit);
        quantMinColor.m_c[1] = cast(ubyte)((pLow.m_c[1] << 1) | minPBit);
        quantMinColor.m_c[2] = cast(ubyte)((pLow.m_c[2] << 1) | minPBit);
        quantMinColor.m_c[3] = cast(ubyte)((pLow.m_c[3] << 1) | minPBit);

        quantMaxColor.m_c[0] = cast(ubyte)((pHigh.m_c[0] << 1) | maxPBit);
        quantMaxColor.m_c[1] = cast(ubyte)((pHigh.m_c[1] << 1) | maxPBit);
        quantMaxColor.m_c[2] = cast(ubyte)((pHigh.m_c[2] << 1) | maxPBit);
        quantMaxColor.m_c[3] = cast(ubyte)((pHigh.m_c[3] << 1) | maxPBit);
    }

    color_quad_u8 actualMinColor = scale_color(quantMinColor, pParams);
    color_quad_u8 actualMaxColor = scale_color(quantMaxColor, pParams);

    const uint N = pParams.m_num_selector_weights;

    color_quad_u8[16] weightedColors;
    weightedColors[0] = actualMinColor;
    weightedColors[N - 1] = actualMaxColor;

    const uint nc = pParams.m_has_alpha ? 4 : 3;
    for (uint i = 1; i < (N - 1); i++)
        for (uint j = 0; j < nc; j++)
            weightedColors[i].m_c[j] = cast(ubyte)((actualMinColor.m_c[j] * (64 - pParams.m_pSelector_weights[i]) + actualMaxColor.m_c[j] * pParams.m_pSelector_weights[i] + 32) >> 6);

    const int lr = actualMinColor.m_c[0];
    const int lg = actualMinColor.m_c[1];
    const int lb = actualMinColor.m_c[2];
    const int dr = actualMaxColor.m_c[0] - lr;
    const int dg = actualMaxColor.m_c[1] - lg;
    const int db = actualMaxColor.m_c[2] - lb;

    ulong total_err = 0;

    if (!pParams.m_perceptual)
    {
        if (pParams.m_has_alpha)
        {
            const int la = actualMinColor.m_c[3];
            const int da = actualMaxColor.m_c[3] - la;

            const float f = N / cast(float)(squarei(dr) + squarei(dg) + squarei(db) + squarei(da) + .00000125f);

            for (uint i = 0; i < pParams.m_num_pixels; i++)
            {
                const(color_quad_u8)* pC = &pParams.m_pPixels[i];
                int r = pC.m_c[0];
                int g = pC.m_c[1];
                int b = pC.m_c[2];
                int a = pC.m_c[3];

                int best_sel = cast(int)(cast(float)((r - lr) * dr + (g - lg) * dg + (b - lb) * db + (a - la) * da) * f + .5f);
                best_sel = clampi(best_sel, 1, N - 1);

                ulong err0 = compute_color_distance_rgba(&weightedColors[best_sel - 1], pC, BC7ENC16_FALSE, pParams.m_weights.ptr);
                ulong err1 = compute_color_distance_rgba(&weightedColors[best_sel], pC, BC7ENC16_FALSE, pParams.m_weights.ptr);

                if (err1 > err0)
                {
                    err1 = err0;
                    --best_sel;
                }
                total_err += err1;

                pResults.m_pSelectors_temp[i] = cast(ubyte)best_sel;
            }
        }
        else
        {
            const float f = N / cast(float)(squarei(dr) + squarei(dg) + squarei(db) + .00000125f);

            for (uint i = 0; i < pParams.m_num_pixels; i++)
            {
                const color_quad_u8 *pC = &pParams.m_pPixels[i];
                int r = pC.m_c[0];
                int g = pC.m_c[1];
                int b = pC.m_c[2];

                int sel = cast(int)(cast(float)((r - lr) * dr + (g - lg) * dg + (b - lb) * db) * f + .5f);
                sel = clampi(sel, 1, N - 1);

                ulong err0 = compute_color_distance_rgb(&weightedColors[sel - 1], pC, BC7ENC16_FALSE, pParams.m_weights.ptr);
                ulong err1 = compute_color_distance_rgb(&weightedColors[sel], pC, BC7ENC16_FALSE, pParams.m_weights.ptr);

                int best_sel = sel;
                ulong best_err = err1;
                if (err0 < best_err)
                {
                    best_err = err0;
                    best_sel = sel - 1;
                }

                total_err += best_err;

                pResults.m_pSelectors_temp[i] = cast(ubyte)best_sel;
            }
        }
    }
    else
    {
        for (uint i = 0; i < pParams.m_num_pixels; i++)
        {
            ulong best_err = ulong.max;
            uint best_sel = 0;

            if (pParams.m_has_alpha)
            {
                for (uint j = 0; j < N; j++)
                {
                    ulong err = compute_color_distance_rgba(&weightedColors[j], &pParams.m_pPixels[i], BC7ENC16_TRUE, pParams.m_weights.ptr);
                    if (err < best_err)
                    {
                        best_err = err;
                        best_sel = j;
                    }
                }
            }
            else
            {
                for (uint j = 0; j < N; j++)
                {
                    ulong err = compute_color_distance_rgb(&weightedColors[j], &pParams.m_pPixels[i], BC7ENC16_TRUE, pParams.m_weights.ptr);
                    if (err < best_err)
                    {
                        best_err = err;
                        best_sel = j;
                    }
                }
            }

            total_err += best_err;

            pResults.m_pSelectors_temp[i] = cast(ubyte)best_sel;
        }
    }

    if (total_err < pResults.m_best_overall_err)
    {
        pResults.m_best_overall_err = total_err;

        pResults.m_low_endpoint = *pLow;
        pResults.m_high_endpoint = *pHigh;

        pResults.m_pbits[0] = pbits[0];
        pResults.m_pbits[1] = pbits[1];

        memcpy(pResults.m_pSelectors, pResults.m_pSelectors_temp, (pResults.m_pSelectors[0]).sizeof * pParams.m_num_pixels);
    }

    return total_err;
}

void fixDegenerateEndpoints(uint mode, 
                            ref color_quad_u8 pTrialMinColor, 
                            ref color_quad_u8 pTrialMaxColor, 
                            ref const(vec4F) pXl, ref const(vec4F) pXh, uint iscale)
{
    if (mode == 1)
    {
        // fix degenerate case where the input collapses to a single colorspace voxel, and we loose all freedom (test with grayscale ramps)
        for (uint i = 0; i < 3; i++)
        {
            if (pTrialMinColor.m_c[i] == pTrialMaxColor.m_c[i])
            {
                if (abs(pXl.m_c[i] - pXh.m_c[i]) > 0.0f)
                {
                    if (pTrialMinColor.m_c[i] > (iscale >> 1))
                    {
                        if (pTrialMinColor.m_c[i] > 0)
                            pTrialMinColor.m_c[i]--;
                        else
                            if (pTrialMaxColor.m_c[i] < iscale)
                                pTrialMaxColor.m_c[i]++;
                    }
                    else
                    {
                        if (pTrialMaxColor.m_c[i] < iscale)
                            pTrialMaxColor.m_c[i]++;
                        else if (pTrialMinColor.m_c[i] > 0)
                            pTrialMinColor.m_c[i]--;
                    }
                }
            }
        }
    }
}

static ulong find_optimal_solution(uint mode, vec4F xl, vec4F xh, const color_cell_compressor_params *pParams, color_cell_compressor_results *pResults) @system
{
    vec4F_saturate_in_place(xl); 
    vec4F_saturate_in_place(xh);

    if (pParams.m_has_pbits)
    {
        const int iscalep = (1 << (pParams.m_comp_bits + 1)) - 1;
        const float scalep = cast(float)iscalep;

        const int totalComps = pParams.m_has_alpha ? 4 : 3;

        uint[2] best_pbits;
        color_quad_u8 bestMinColor, bestMaxColor;

        if (!pParams.m_endpoints_share_pbit)
        {
            float best_err0 = 1e+9;
            float best_err1 = 1e+9;

            for (int p = 0; p < 2; p++)
            {
                color_quad_u8 xMinColor, xMaxColor;

                // Notes: The pbit controls which quantization intervals are selected.
                // total_levels=2^(comp_bits+1), where comp_bits=4 for mode 0, etc.
                // pbit 0: v=(b*2)/(total_levels-1), pbit 1: v=(b*2+1)/(total_levels-1) where b is the component bin from [0,total_levels/2-1] and v is the [0,1] component value
                // rearranging you get for pbit 0: b=floor(v*(total_levels-1)/2+.5)
                // rearranging you get for pbit 1: b=floor((v*(total_levels-1)-1)/2+.5)
                for (uint c = 0; c < 4; c++)
                {
                    xMinColor.m_c[c] = cast(ubyte)(clampi((cast(int)((xl.m_c[c] * scalep - p) / 2.0f + .5f)) * 2 + p, p, iscalep - 1 + p));
                    xMaxColor.m_c[c] = cast(ubyte)(clampi((cast(int)((xh.m_c[c] * scalep - p) / 2.0f + .5f)) * 2 + p, p, iscalep - 1 + p));
                }

                color_quad_u8 scaledLow = scale_color(xMinColor, pParams);
                color_quad_u8 scaledHigh = scale_color(xMaxColor, pParams);

                float err0 = 0, err1 = 0;
                for (int i = 0; i < totalComps; i++)
                {
                    err0 += squaref(scaledLow.m_c[i] - xl.m_c[i] * 255.0f);
                    err1 += squaref(scaledHigh.m_c[i] - xh.m_c[i] * 255.0f);
                }

                if (err0 < best_err0)
                {
                    best_err0 = err0;
                    best_pbits[0] = p;

                    bestMinColor.m_c[0] = xMinColor.m_c[0] >> 1;
                    bestMinColor.m_c[1] = xMinColor.m_c[1] >> 1;
                    bestMinColor.m_c[2] = xMinColor.m_c[2] >> 1;
                    bestMinColor.m_c[3] = xMinColor.m_c[3] >> 1;
                }

                if (err1 < best_err1)
                {
                    best_err1 = err1;
                    best_pbits[1] = p;

                    bestMaxColor.m_c[0] = xMaxColor.m_c[0] >> 1;
                    bestMaxColor.m_c[1] = xMaxColor.m_c[1] >> 1;
                    bestMaxColor.m_c[2] = xMaxColor.m_c[2] >> 1;
                    bestMaxColor.m_c[3] = xMaxColor.m_c[3] >> 1;
                }
            }
        }
        else
        {
            // Endpoints share pbits
            float best_err = 1e+9;

            for (int p = 0; p < 2; p++)
            {
                color_quad_u8 xMinColor, xMaxColor;
                for (uint c = 0; c < 4; c++)
                {
                    xMinColor.m_c[c] = cast(ubyte)(clampi((cast(int)((xl.m_c[c] * scalep - p) / 2.0f + .5f)) * 2 + p, p, iscalep - 1 + p));
                    xMaxColor.m_c[c] = cast(ubyte)(clampi((cast(int)((xh.m_c[c] * scalep - p) / 2.0f + .5f)) * 2 + p, p, iscalep - 1 + p));
                }

                color_quad_u8 scaledLow = scale_color(xMinColor, pParams);
                color_quad_u8 scaledHigh = scale_color(xMaxColor, pParams);

                float err = 0;
                for (int i = 0; i < totalComps; i++)
                    err += squaref((scaledLow.m_c[i] / 255.0f) - xl.m_c[i]) + squaref((scaledHigh.m_c[i] / 255.0f) - xh.m_c[i]);

                if (err < best_err)
                {
                    best_err = err;
                    best_pbits[0] = p;
                    best_pbits[1] = p;
                    for (uint j = 0; j < 4; j++)
                    {
                        bestMinColor.m_c[j] = xMinColor.m_c[j] >> 1;
                        bestMaxColor.m_c[j] = xMaxColor.m_c[j] >> 1;
                    }
                }
            }
        }

        fixDegenerateEndpoints(mode, bestMinColor, bestMaxColor, xl, xh, iscalep >> 1);

        if ( (pResults.m_best_overall_err == ulong.max) 
             || color_quad_u8_notequals(bestMinColor, pResults.m_low_endpoint) 
             || color_quad_u8_notequals(bestMaxColor, pResults.m_high_endpoint) 
             || (best_pbits[0] != pResults.m_pbits[0]) 
             || (best_pbits[1] != pResults.m_pbits[1]) )
            evaluate_solution(&bestMinColor, &bestMaxColor, best_pbits.ptr, pParams, pResults);
    }
    else
    {
        const int iscale = (1 << pParams.m_comp_bits) - 1;
        const float scale = cast(float)iscale;

        color_quad_u8 trialMinColor, trialMaxColor;
        color_quad_u8_set_clamped(&trialMinColor, cast(int)(xl.m_c[0] * scale + .5f), cast(int)(xl.m_c[1] * scale + .5f), cast(int)(xl.m_c[2] * scale + .5f), cast(int)(xl.m_c[3] * scale + .5f));
        color_quad_u8_set_clamped(&trialMaxColor, cast(int)(xh.m_c[0] * scale + .5f), cast(int)(xh.m_c[1] * scale + .5f), cast(int)(xh.m_c[2] * scale + .5f), cast(int)(xh.m_c[3] * scale + .5f));

        fixDegenerateEndpoints(mode, trialMinColor, trialMaxColor, xl, xh, iscale);

        if (  (pResults.m_best_overall_err == ulong.max) 
             || color_quad_u8_notequals(trialMinColor, pResults.m_low_endpoint) 
             || color_quad_u8_notequals(trialMaxColor, pResults.m_high_endpoint) )
            evaluate_solution(&trialMinColor, &trialMaxColor, pResults.m_pbits.ptr, pParams, pResults);
    }

    return pResults.m_best_overall_err;
}

ulong color_cell_compression(uint mode, 
                             const(color_cell_compressor_params)* pParams, 
                             color_cell_compressor_results *pResults, 
                             const(bc7enc16_compress_block_params)* pComp_params) @system
{
    assert((mode == 6) || (!pParams.m_has_alpha));

    pResults.m_best_overall_err = ulong.max;

    // If the partition's colors are all the same in mode 1, then just pack them as a single color.
    if (mode == 1)
    {
        const uint cr = pParams.m_pPixels[0].m_c[0], cg = pParams.m_pPixels[0].m_c[1], cb = pParams.m_pPixels[0].m_c[2];

        bc7enc16_bool allSame = BC7ENC16_TRUE;
        for (uint i = 1; i < pParams.m_num_pixels; i++)
        {
            if ((cr != pParams.m_pPixels[i].m_c[0]) || (cg != pParams.m_pPixels[i].m_c[1]) || (cb != pParams.m_pPixels[i].m_c[2]))
            {
                allSame = BC7ENC16_FALSE;
                break;
            }
        }

        if (allSame)
            return pack_mode1_to_one_color(pParams, pResults, cr, cg, cb, pResults.m_pSelectors);
    }

    // Compute partition's mean color and principle axis.
    vec4F meanColor, axis;
    vec4F_set_scalar(&meanColor, 0.0f);

    for (uint i = 0; i < pParams.m_num_pixels; i++)
    {
        vec4F color = vec4F_from_color(&pParams.m_pPixels[i]);
        meanColor = vec4F_add(&meanColor, &color);
    }

    vec4F meanColorScaled = vec4F_mul(&meanColor, 1.0f / cast(float)(pParams.m_num_pixels));

    meanColor = vec4F_mul(&meanColor, 1.0f / cast(float)(pParams.m_num_pixels * 255.0f));
    vec4F_saturate_in_place(meanColor);

    if (pParams.m_has_alpha)
    {
        // Use incremental PCA for RGBA PCA, because it's simple.
        vec4F_set_scalar(&axis, 0.0f);
        for (uint i = 0; i < pParams.m_num_pixels; i++)
        {
            vec4F color = vec4F_from_color(&pParams.m_pPixels[i]);
            color = vec4F_sub(&color, &meanColorScaled);
            vec4F a = vec4F_mul(&color, color.m_c[0]);
            vec4F b = vec4F_mul(&color, color.m_c[1]);
            vec4F c = vec4F_mul(&color, color.m_c[2]);
            vec4F d = vec4F_mul(&color, color.m_c[3]);
            vec4F n = i ? axis : color;
            vec4F_normalize_in_place(&n);
            axis.m_c[0] += vec4F_dot(&a, &n);
            axis.m_c[1] += vec4F_dot(&b, &n);
            axis.m_c[2] += vec4F_dot(&c, &n);
            axis.m_c[3] += vec4F_dot(&d, &n);
        }
        vec4F_normalize_in_place(&axis);
    }
    else
    {
        // Use covar technique for RGB PCA, because it doesn't require per-pixel normalization.
        float[6] cov = [ 0, 0, 0, 0, 0, 0 ];

        for (uint i = 0; i < pParams.m_num_pixels; i++)
        {
            const color_quad_u8 *pV = &pParams.m_pPixels[i];
            float r = pV.m_c[0] - meanColorScaled.m_c[0];
            float g = pV.m_c[1] - meanColorScaled.m_c[1];
            float b = pV.m_c[2] - meanColorScaled.m_c[2];
            cov[0] += r*r; cov[1] += r*g; cov[2] += r*b; cov[3] += g*g; cov[4] += g*b; cov[5] += b*b;
        }

        float vfr = .9f, vfg = 1.0f, vfb = .7f;
        for (uint iter = 0; iter < 3; iter++)
        {
            float r = vfr*cov[0] + vfg*cov[1] + vfb*cov[2];
            float g = vfr*cov[1] + vfg*cov[3] + vfb*cov[4];
            float b = vfr*cov[2] + vfg*cov[4] + vfb*cov[5];

            float m = maximumf(maximumf(abs(r), abs(g)), abs(b));
            if (m > 1e-10f)
            {
                m = 1.0f / m;
                r *= m; g *= m; b *= m;
            }

            vfr = r; vfg = g; vfb = b;
        }

        float len = vfr*vfr + vfg*vfg + vfb*vfb;
        if (len < 1e-10f)
            vec4F_set_scalar(&axis, 0.0f);
        else
        {
            len = 1.0f / sqrt(len);
            vfr *= len; vfg *= len; vfb *= len;
            vec4F_set(&axis, vfr, vfg, vfb, 0);
        }
    }

    if (vec4F_dot(&axis, &axis) < .5f)
    {
        if (pParams.m_perceptual)
            vec4F_set(&axis, .213f, .715f, .072f, pParams.m_has_alpha ? .715f : 0);
        else
            vec4F_set(&axis, 1.0f, 1.0f, 1.0f, pParams.m_has_alpha ? 1.0f : 0);
        vec4F_normalize_in_place(&axis);
    }

    float l = 1e+9f, h = -1e+9f;

    for (uint i = 0; i < pParams.m_num_pixels; i++)
    {
        vec4F color = vec4F_from_color(&pParams.m_pPixels[i]);

        vec4F q = vec4F_sub(&color, &meanColorScaled);
        float d = vec4F_dot(&q, &axis);

        l = minimumf(l, d);
        h = maximumf(h, d);
    }

    l *= (1.0f / 255.0f);
    h *= (1.0f / 255.0f);

    vec4F b0 = vec4F_mul(&axis, l);
    vec4F b1 = vec4F_mul(&axis, h);
    vec4F c0 = vec4F_add(&meanColor, &b0);
    vec4F c1 = vec4F_add(&meanColor, &b1);
    vec4F minColor = vec4F_saturate(&c0);
    vec4F maxColor = vec4F_saturate(&c1);

    vec4F whiteVec;
    vec4F_set_scalar(&whiteVec, 1.0f);
    if (vec4F_dot(&minColor, &whiteVec) > vec4F_dot(&maxColor, &whiteVec))
    {
        vec4F temp = minColor;
        minColor = maxColor;
        maxColor = temp;
    }
    // First find a solution using the block's PCA.
    if (!find_optimal_solution(mode, minColor, maxColor, pParams, pResults))
        return 0;

    if (pComp_params.m_try_least_squares)
    {
        // Now try to refine the solution using least squares by computing the optimal endpoints from the current selectors.
        vec4F xl, xh;
        vec4F_set_scalar(&xl, 0.0f);
        vec4F_set_scalar(&xh, 0.0f);
        if (pParams.m_has_alpha)
            compute_least_squares_endpoints_rgba(pParams.m_num_pixels, pResults.m_pSelectors, pParams.m_pSelector_weightsx, &xl, &xh, pParams.m_pPixels);
        else
            compute_least_squares_endpoints_rgb(pParams.m_num_pixels, pResults.m_pSelectors, pParams.m_pSelector_weightsx, &xl, &xh, pParams.m_pPixels);

        xl = vec4F_mul(&xl, (1.0f / 255.0f));
        xh = vec4F_mul(&xh, (1.0f / 255.0f));

        if (!find_optimal_solution(mode, xl, xh, pParams, pResults))
            return 0;
    }

    if (pComp_params.m_uber_level > 0)
    {
        // In uber level 1, try varying the selectors a little, somewhat like cluster fit would. First try incrementing the minimum selectors,
        // then try decrementing the selectrors, then try both.
        ubyte[16] selectors_temp, selectors_temp1;
        memcpy(selectors_temp.ptr, pResults.m_pSelectors, pParams.m_num_pixels);

        const int max_selector = pParams.m_num_selector_weights - 1;

        uint min_sel = 16;
        uint max_sel = 0;
        for (uint i = 0; i < pParams.m_num_pixels; i++)
        {
            uint sel = selectors_temp[i];
            min_sel = minimumu(min_sel, sel);
            max_sel = maximumu(max_sel, sel);
        }

        for (uint i = 0; i < pParams.m_num_pixels; i++)
        {
            uint sel = selectors_temp[i];
            if ((sel == min_sel) && (sel < (pParams.m_num_selector_weights - 1)))
                sel++;
            selectors_temp1[i] = cast(ubyte)sel;
        }

        vec4F xl, xh;
        vec4F_set_scalar(&xl, 0.0f);
        vec4F_set_scalar(&xh, 0.0f);
        if (pParams.m_has_alpha)
            compute_least_squares_endpoints_rgba(pParams.m_num_pixels, selectors_temp1.ptr, 
                                                 pParams.m_pSelector_weightsx, &xl, &xh, pParams.m_pPixels);
        else
            compute_least_squares_endpoints_rgb(pParams.m_num_pixels, selectors_temp1.ptr, 
                                                pParams.m_pSelector_weightsx, &xl, &xh, pParams.m_pPixels);

        xl = vec4F_mul(&xl, (1.0f / 255.0f));
        xh = vec4F_mul(&xh, (1.0f / 255.0f));

        if (!find_optimal_solution(mode, xl, xh, pParams, pResults))
            return 0;

        for (uint i = 0; i < pParams.m_num_pixels; i++)
        {
            uint sel = selectors_temp[i];
            if ((sel == max_sel) && (sel > 0))
                sel--;
            selectors_temp1[i] = cast(ubyte)sel;
        }

        if (pParams.m_has_alpha)
            compute_least_squares_endpoints_rgba(pParams.m_num_pixels, selectors_temp1.ptr, 
                                                 pParams.m_pSelector_weightsx, &xl, &xh, pParams.m_pPixels);
        else
            compute_least_squares_endpoints_rgb(pParams.m_num_pixels, selectors_temp1.ptr, 
                                                pParams.m_pSelector_weightsx, &xl, &xh, pParams.m_pPixels);

        xl = vec4F_mul(&xl, (1.0f / 255.0f));
        xh = vec4F_mul(&xh, (1.0f / 255.0f));

        if (!find_optimal_solution(mode, xl, xh, pParams, pResults))
            return 0;

        for (uint i = 0; i < pParams.m_num_pixels; i++)
        {
            uint sel = selectors_temp[i];
            if ((sel == min_sel) && (sel < (pParams.m_num_selector_weights - 1)))
                sel++;
            else if ((sel == max_sel) && (sel > 0))
                sel--;
            selectors_temp1[i] = cast(ubyte)sel;
        }

        if (pParams.m_has_alpha)
            compute_least_squares_endpoints_rgba(pParams.m_num_pixels, selectors_temp1.ptr, 
                                                 pParams.m_pSelector_weightsx, &xl, &xh, pParams.m_pPixels);
        else
            compute_least_squares_endpoints_rgb(pParams.m_num_pixels, selectors_temp1.ptr, 
                                                pParams.m_pSelector_weightsx, &xl, &xh, pParams.m_pPixels);

        xl = vec4F_mul(&xl, (1.0f / 255.0f));
        xh = vec4F_mul(&xh, (1.0f / 255.0f));

        if (!find_optimal_solution(mode, xl, xh, pParams, pResults))
            return 0;

        // In uber levels 2+, try taking more advantage of endpoint extrapolation by scaling the selectors in one direction or another.
        const uint uber_err_thresh = (pParams.m_num_pixels * 56) >> 4;
        if ((pComp_params.m_uber_level >= 2) && (pResults.m_best_overall_err > uber_err_thresh))
        {
            const int Q = (pComp_params.m_uber_level >= 4) ? (pComp_params.m_uber_level - 2) : 1;
            for (int ly = -Q; ly <= 1; ly++)
            {
                for (int hy = max_selector - 1; hy <= (max_selector + Q); hy++)
                {
                    if ((ly == 0) && (hy == max_selector))
                        continue;

                    for (uint i = 0; i < pParams.m_num_pixels; i++)
                        selectors_temp1[i] = cast(ubyte)clampf(floor(cast(float)max_selector * (cast(float)selectors_temp[i] - cast(float)ly) / (cast(float)hy - cast(float)ly) + .5f), 0, cast(float)max_selector);

                    //vec4F xl, xh;
                    vec4F_set_scalar(&xl, 0.0f);
                    vec4F_set_scalar(&xh, 0.0f);
                    if (pParams.m_has_alpha)
                        compute_least_squares_endpoints_rgba(pParams.m_num_pixels, selectors_temp1.ptr, pParams.m_pSelector_weightsx, &xl, &xh, pParams.m_pPixels);
                    else
                        compute_least_squares_endpoints_rgb(pParams.m_num_pixels, selectors_temp1.ptr, pParams.m_pSelector_weightsx, &xl, &xh, pParams.m_pPixels);

                    xl = vec4F_mul(&xl, (1.0f / 255.0f));
                    xh = vec4F_mul(&xh, (1.0f / 255.0f));

                    if (!find_optimal_solution(mode, xl, xh, pParams, pResults))
                        return 0;
                }
            }
        }
    }

    if (mode == 1)
    {
        // Try encoding the partition as a single color by using the optimal singe colors tables to encode the block to its mean.
        color_cell_compressor_results avg_results = *pResults;
        const uint r = cast(int)(.5f + meanColor.m_c[0] * 255.0f), 
                   g = cast(int)(.5f + meanColor.m_c[1] * 255.0f), 
                   b = cast(int)(.5f + meanColor.m_c[2] * 255.0f);
        ulong avg_err = pack_mode1_to_one_color(pParams, &avg_results, r, g, b, pResults.m_pSelectors_temp);
        if (avg_err < pResults.m_best_overall_err)
        {
            *pResults = avg_results;
            memcpy(pResults.m_pSelectors, pResults.m_pSelectors_temp, (pResults.m_pSelectors[0]).sizeof * pParams.m_num_pixels);
            pResults.m_best_overall_err = avg_err;
        }
    }

    return pResults.m_best_overall_err;
}

ulong color_cell_compression_est(uint num_pixels, const color_quad_u8 *pPixels, bc7enc16_bool perceptual, uint* pweights/*[4]*/, ulong best_err_so_far) @system
{
    // Find RGB bounds as an approximation of the block's principle axis
    uint lr = 255, lg = 255, lb = 255;
    uint hr = 0, hg = 0, hb = 0;
    for (uint i = 0; i < num_pixels; i++)
    {
        const color_quad_u8 *pC = &pPixels[i];
        if (pC.m_c[0] < lr) lr = pC.m_c[0];
        if (pC.m_c[1] < lg) lg = pC.m_c[1];
        if (pC.m_c[2] < lb) lb = pC.m_c[2];
        if (pC.m_c[0] > hr) hr = pC.m_c[0];
        if (pC.m_c[1] > hg) hg = pC.m_c[1];
        if (pC.m_c[2] > hb) hb = pC.m_c[2];
    }

    color_quad_u8 lowColor; color_quad_u8_set(&lowColor, lr, lg, lb, 0);
    color_quad_u8 highColor; color_quad_u8_set(&highColor, hr, hg, hb, 0);

    // Place endpoints at bbox diagonals and compute interpolated colors
    const uint N = 8;
    color_quad_u8[8] weightedColors;

    weightedColors[0] = lowColor;
    weightedColors[N - 1] = highColor;
    for (uint i = 1; i < (N - 1); i++)
    {
        weightedColors[i].m_c[0] = cast(ubyte)((lowColor.m_c[0] * (64 - g_bc7_weights3[i]) + highColor.m_c[0] * g_bc7_weights3[i] + 32) >> 6);
        weightedColors[i].m_c[1] = cast(ubyte)((lowColor.m_c[1] * (64 - g_bc7_weights3[i]) + highColor.m_c[1] * g_bc7_weights3[i] + 32) >> 6);
        weightedColors[i].m_c[2] = cast(ubyte)((lowColor.m_c[2] * (64 - g_bc7_weights3[i]) + highColor.m_c[2] * g_bc7_weights3[i] + 32) >> 6);
    }

    // Compute dots and thresholds
    const int ar = highColor.m_c[0] - lowColor.m_c[0];
    const int ag = highColor.m_c[1] - lowColor.m_c[1];
    const int ab = highColor.m_c[2] - lowColor.m_c[2];

    int[8] dots;
    for (uint i = 0; i < N; i++)
        dots[i] = weightedColors[i].m_c[0] * ar + weightedColors[i].m_c[1] * ag + weightedColors[i].m_c[2] * ab;

    int[8 - 1] thresh;
    for (uint i = 0; i < (N - 1); i++)
        thresh[i] = (dots[i] + dots[i + 1] + 1) >> 1;

    ulong total_err = 0;
    if (perceptual)
    {
        // Transform block's interpolated colors to YCbCr
        int[8] l1, cr1, cb1;
        for (int j = 0; j < 8; j++)
        {
            const color_quad_u8 *pE1 = &weightedColors[j];
            l1[j] = pE1.m_c[0] * 109 + pE1.m_c[1] * 366 + pE1.m_c[2] * 37;
            cr1[j] = (cast(int)pE1.m_c[0] << 9) - l1[j];
            cb1[j] = (cast(int)pE1.m_c[2] << 9) - l1[j];
        }

        for (uint i = 0; i < num_pixels; i++)
        {
            const color_quad_u8 *pC = &pPixels[i];

            int d = ar * pC.m_c[0] + ag * pC.m_c[1] + ab * pC.m_c[2];

            // Find approximate selector
            uint s = 0;
            if (d >= thresh[6])
                s = 7;
            else if (d >= thresh[5])
                s = 6;
            else if (d >= thresh[4])
                s = 5;
            else if (d >= thresh[3])
                s = 4;
            else if (d >= thresh[2])
                s = 3;
            else if (d >= thresh[1])
                s = 2;
            else if (d >= thresh[0])
                s = 1;

            // Compute error
            const int l2 = pC.m_c[0] * 109 + pC.m_c[1] * 366 + pC.m_c[2] * 37;
            const int cr2 = (cast(int)pC.m_c[0] << 9) - l2;
            const int cb2 = (cast(int)pC.m_c[2] << 9) - l2;

            const int dl = (l1[s] - l2) >> 8;
            const int dcr = (cr1[s] - cr2) >> 8;
            const int dcb = (cb1[s] - cb2) >> 8;

            int ie = (pweights[0] * dl * dl) + (pweights[1] * dcr * dcr) + (pweights[2] * dcb * dcb);

            total_err += ie;
            if (total_err > best_err_so_far)
                break;
        }
    }
    else
    {
        for (uint i = 0; i < num_pixels; i++)
        {
            const color_quad_u8 *pC = &pPixels[i];

            int d = ar * pC.m_c[0] + ag * pC.m_c[1] + ab * pC.m_c[2];

            // Find approximate selector
            uint s = 0;
            if (d >= thresh[6])
                s = 7;
            else if (d >= thresh[5])
                s = 6;
            else if (d >= thresh[4])
                s = 5;
            else if (d >= thresh[3])
                s = 4;
            else if (d >= thresh[2])
                s = 3;
            else if (d >= thresh[1])
                s = 2;
            else if (d >= thresh[0])
                s = 1;

            // Compute error
            const color_quad_u8 *pE1 = &weightedColors[s];

            int dr = cast(int)pE1.m_c[0] - cast(int)pC.m_c[0];
            int dg = cast(int)pE1.m_c[1] - cast(int)pC.m_c[1];
            int db = cast(int)pE1.m_c[2] - cast(int)pC.m_c[2];

            total_err += pweights[0] * (dr * dr) + pweights[1] * (dg * dg) + pweights[2] * (db * db);
            if (total_err > best_err_so_far)
                break;
        }
    }

    return total_err;
}

// This table contains bitmasks indicating which "key" partitions must be best ranked before this partition is worth evaluating.
// We first rank the best/most used 14 partitions (sorted by usefulness), record the best one found as the key partition, then use
// that to control the other partitions to evaluate. The quality loss is ~.08 dB RGB PSNR, the perf gain is up to ~11% (at uber level 0).
static immutable uint[35] g_partition_predictors =
[
    uint.max,
    uint.max,
    uint.max,
    uint.max,
    uint.max,
    (1 << 1) | (1 << 2) | (1 << 8),
    (1 << 1) | (1 << 3) | (1 << 7),
    uint.max,
    uint.max,
    (1 << 2) | (1 << 8) | (1 << 16),
    (1 << 7) | (1 << 3) | (1 << 15),
    uint.max,
    (1 << 8) | (1 << 14) | (1 << 16),
    (1 << 7) | (1 << 14) | (1 << 15),
    uint.max,
    uint.max,
    uint.max,
    uint.max,
    (1 << 14) | (1 << 15),
    (1 << 16) | (1 << 22) | (1 << 14),
    (1 << 17) | (1 << 24) | (1 << 14),
    (1 << 2) | (1 << 14) | (1 << 15) | (1 << 1),
    uint.max,
    (1 << 1) | (1 << 3) | (1 << 14) | (1 << 16) | (1 << 22),
    uint.max,
    (1 << 1) | (1 << 2) | (1 << 15) | (1 << 17) | (1 << 24),
    (1 << 1) | (1 << 3) | (1 << 22),
    uint.max,
    uint.max,
    uint.max,
    (1 << 14) | (1 << 15) | (1 << 16) | (1 << 17),
    uint.max,
    uint.max,
    (1 << 1) | (1 << 2) | (1 << 3) | (1 << 27) | (1 << 4) | (1 << 24),
    (1 << 14) | (1 << 15) | (1 << 16) | (1 << 11) | (1 << 17) | (1 << 27)
];

// Estimate the partition used by mode 1. This scans through each partition and computes an approximate error for each.
uint estimate_partition(const(color_quad_u8)* pPixels, 
                        const(bc7enc16_compress_block_params)* pComp_params, 
                        uint* pweights/*[4]*/) @system
{
    const uint total_partitions = minimumu(pComp_params.m_max_partitions_mode1, BC7ENC16_MAX_PARTITIONS1);
    if (total_partitions <= 1)
        return 0;

    ulong best_err = ulong.max;
    uint best_partition = 0;

    // Partition order sorted by usage frequency across a large test corpus. Pattern 34 (checkerboard) must appear in slot 34.
    // Using a sorted order allows the user to decrease the # of partitions to scan with minimal loss in quality.
    static immutable ubyte[64] s_sorted_partition_order =
    [
        1 - 1, 14 - 1, 2 - 1, 3 - 1, 16 - 1, 15 - 1, 11 - 1, 17 - 1,
        4 - 1, 24 - 1, 27 - 1, 7 - 1, 8 - 1, 22 - 1, 20 - 1, 30 - 1,
        9 - 1, 5 - 1, 10 - 1, 21 - 1, 6 - 1, 32 - 1, 23 - 1, 18 - 1,
        19 - 1, 12 - 1, 13 - 1, 31 - 1, 25 - 1, 26 - 1, 29 - 1, 28 - 1,
        33 - 1, 34 - 1, 35 - 1, 46 - 1, 47 - 1, 52 - 1, 50 - 1, 51 - 1,
        49 - 1, 39 - 1, 40 - 1, 38 - 1, 54 - 1, 53 - 1, 55 - 1, 37 - 1,
        58 - 1, 59 - 1, 56 - 1, 42 - 1, 41 - 1, 43 - 1, 44 - 1, 60 - 1,
        45 - 1, 57 - 1, 48 - 1, 36 - 1, 61 - 1, 64 - 1, 63 - 1, 62 - 1
    ];

    assert(s_sorted_partition_order[34] == 34);

    int best_key_partition = 0;

    for (uint partition_iter = 0; (partition_iter < total_partitions) && (best_err > 0); partition_iter++)
    {
        const uint partition = s_sorted_partition_order[partition_iter];

        // Check to see if we should bother evaluating this partition at all, depending on the best partition found from the first 14.
        if (pComp_params.m_mode1_partition_estimation_filterbank)
        {
            if ((partition_iter >= 14) && (partition_iter <= 34))
            {
                const uint best_key_partition_bitmask = 1 << (best_key_partition + 1);
                if ((g_partition_predictors[partition] & best_key_partition_bitmask) == 0)
                {
                    if (partition_iter == 34)
                        break;

                    continue;
                }
            }
        }

        const ubyte *pPartition = &g_bc7_partition2[partition * 16];

        color_quad_u8[16][2] subset_colors;
        uint[2] subset_total_colors = [ 0, 0 ];
        for (uint index = 0; index < 16; index++)
            subset_colors[pPartition[index]][subset_total_colors[pPartition[index]]++] = pPixels[index];

        ulong total_subset_err = 0;
        for (uint subset = 0; (subset < 2) && (total_subset_err < best_err); subset++)
            total_subset_err += color_cell_compression_est(subset_total_colors[subset], &subset_colors[subset][0], pComp_params.m_perceptual, pweights, best_err);

        if (total_subset_err < best_err)
        {
            best_err = total_subset_err;
            best_partition = partition;
        }

        // If the checkerboard pattern doesn't get the highest ranking vs. the previous (lower frequency) patterns, then just stop now because statistically the subsequent patterns won't do well either.
        if ((partition == 34) && (best_partition != 34))
            break;

        if (partition_iter == 13)
            best_key_partition = best_partition;

    } // partition

    return best_partition;
}

void set_block_bits(ubyte *pBytes, uint val, uint num_bits, uint *pCur_ofs) @system
{
    assert((num_bits <= 32) && (val < (1UL << num_bits)));
    while (num_bits)
    {
        const uint n = minimumu(8 - (*pCur_ofs & 7), num_bits);
        pBytes[*pCur_ofs >> 3] |= cast(ubyte)(val << (*pCur_ofs & 7));
        val >>= n;
        num_bits -= n;
        *pCur_ofs += n;
    }
    assert(*pCur_ofs <= 128);
}

struct bc7_optimization_results
{
    uint m_mode;
    uint m_partition;
    ubyte[16] m_selectors;
    color_quad_u8[2] m_low;
    color_quad_u8[2] m_high;
    uint[2][2] m_pbits;
}

static void encode_bc7_block(void *pBlock, const(bc7_optimization_results)* pResults) @system
{
    const uint best_mode = pResults.m_mode;
    const uint total_subsets = g_bc7_num_subsets[best_mode];
    const uint total_partitions = 1 << g_bc7_partition_bits[best_mode];
    const ubyte *pPartition = (total_subsets == 2) ? &g_bc7_partition2[pResults.m_partition * 16] : &g_bc7_partition1[0];

    ubyte[16] color_selectors;
    memcpy(color_selectors.ptr, pResults.m_selectors.ptr, 16);

    color_quad_u8[2] low, high;
    memcpy(low.ptr, pResults.m_low.ptr, low.sizeof);
    memcpy(high.ptr, pResults.m_high.ptr, high.sizeof);

    uint[2][2] pbits;
    static assert(pbits.sizeof == 16);
    memcpy(pbits.ptr, pResults.m_pbits.ptr, pbits.sizeof);

    int[2] anchor = [ -1, -1 ];

    for (uint k = 0; k < total_subsets; k++)
    {
        const uint anchor_index = k ? g_bc7_table_anchor_index_second_subset[pResults.m_partition] : 0;
        anchor[k] = anchor_index;

        const uint color_index_bits = get_bc7_color_index_size(best_mode, 0);
        const uint num_color_indices = 1 << color_index_bits;

        if (color_selectors[anchor_index] & (num_color_indices >> 1))
        {
            for (uint i = 0; i < 16; i++)
                if (pPartition[i] == k)
                    color_selectors[i] = cast(ubyte)((num_color_indices - 1) - color_selectors[i]);

            color_quad_u8 tmp = low[k];
            low[k] = high[k];
            high[k] = tmp;

            if (!g_bc7_mode_has_shared_p_bits[best_mode])
            {
                uint t = pbits[k][0];
                pbits[k][0] = pbits[k][1];
                pbits[k][1] = t;
            }
        }
    }

    ubyte *pBlock_bytes = cast(ubyte *)(pBlock);
    memset(pBlock_bytes, 0, BC7ENC16_BLOCK_SIZE);

    uint cur_bit_ofs = 0;
    set_block_bits(pBlock_bytes, 1 << best_mode, best_mode + 1, &cur_bit_ofs);

    if (total_partitions > 1)
        set_block_bits(pBlock_bytes, pResults.m_partition, 6, &cur_bit_ofs);

    const uint total_comps = (best_mode >= 4) ? 4 : 3;
    for (uint comp = 0; comp < total_comps; comp++)
    {
        for (uint subset = 0; subset < total_subsets; subset++)
        {
            set_block_bits(pBlock_bytes, low[subset].m_c[comp], (comp == 3) ? g_bc7_alpha_precision_table[best_mode] : g_bc7_color_precision_table[best_mode], &cur_bit_ofs);
            set_block_bits(pBlock_bytes, high[subset].m_c[comp], (comp == 3) ? g_bc7_alpha_precision_table[best_mode] : g_bc7_color_precision_table[best_mode], &cur_bit_ofs);
        }
    }

    for (uint subset = 0; subset < total_subsets; subset++)
    {
        set_block_bits(pBlock_bytes, pbits[subset][0], 1, &cur_bit_ofs);
        if (!g_bc7_mode_has_shared_p_bits[best_mode])
            set_block_bits(pBlock_bytes, pbits[subset][1], 1, &cur_bit_ofs);
    }

    for (int idx = 0; idx < 16; idx++)
    {
        uint n = get_bc7_color_index_size(best_mode, 0);
        if ((idx == anchor[0]) || (idx == anchor[1]))
            n--;
        set_block_bits(pBlock_bytes, color_selectors[idx], n, &cur_bit_ofs);
    }

    assert(cur_bit_ofs == 128);
}

void handle_alpha_block(void *pBlock, const(color_quad_u8)* pPixels, 
                        const(bc7enc16_compress_block_params)* pComp_params, 
                        color_cell_compressor_params *pParams) @system
{
    color_cell_compressor_results results6;

    pParams.m_pSelector_weights = g_bc7_weights4.ptr;
    pParams.m_pSelector_weightsx = cast(const(vec4F)*) g_bc7_weights4x.ptr;
    pParams.m_num_selector_weights = 16;
    pParams.m_comp_bits = 7;
    pParams.m_has_pbits = BC7ENC16_TRUE;
    pParams.m_has_alpha = BC7ENC16_TRUE;
    pParams.m_perceptual = pComp_params.m_perceptual;
    pParams.m_num_pixels = 16;
    pParams.m_pPixels = pPixels;

    bc7_optimization_results opt_results;
    results6.m_pSelectors = opt_results.m_selectors.ptr;

    ubyte[16] selectors_temp;
    results6.m_pSelectors_temp = selectors_temp.ptr;

    color_cell_compression(6, pParams, &results6, pComp_params);

    opt_results.m_mode = 6;
    opt_results.m_partition = 0;
    opt_results.m_low[0] = results6.m_low_endpoint;
    opt_results.m_high[0] = results6.m_high_endpoint;
    opt_results.m_pbits[0][0] = results6.m_pbits[0];
    opt_results.m_pbits[0][1] = results6.m_pbits[1];

    encode_bc7_block(pBlock, &opt_results);
}

static void handle_opaque_block(void *pBlock, 
                                const(color_quad_u8)* pPixels, 
                                const(bc7enc16_compress_block_params)* pComp_params, 
                                color_cell_compressor_params *pParams) @system
{
    ubyte[16] selectors_temp;

    // Mode 6
    bc7_optimization_results opt_results;

    pParams.m_pSelector_weights = g_bc7_weights4.ptr;
    pParams.m_pSelector_weightsx = cast(const vec4F *)g_bc7_weights4x;
    pParams.m_num_selector_weights = 16;
    pParams.m_comp_bits = 7;
    pParams.m_has_pbits = BC7ENC16_TRUE;
    pParams.m_endpoints_share_pbit = BC7ENC16_FALSE;
    pParams.m_perceptual = pComp_params.m_perceptual;
    pParams.m_num_pixels = 16;
    pParams.m_pPixels = pPixels;
    pParams.m_has_alpha = BC7ENC16_FALSE;

    color_cell_compressor_results results6;
    results6.m_pSelectors = opt_results.m_selectors.ptr;
    results6.m_pSelectors_temp = selectors_temp.ptr;

    ulong best_err = color_cell_compression(6, pParams, &results6, pComp_params);

    opt_results.m_mode = 6;
    opt_results.m_partition = 0;
    opt_results.m_low[0] = results6.m_low_endpoint;
    opt_results.m_high[0] = results6.m_high_endpoint;
    opt_results.m_pbits[0][0] = results6.m_pbits[0];
    opt_results.m_pbits[0][1] = results6.m_pbits[1];

    // Mode 1
    if ((best_err > 0) && (pComp_params.m_max_partitions_mode1 > 0))
    {
        const uint trial_partition = estimate_partition(pPixels, pComp_params, pParams.m_weights.ptr);
        pParams.m_pSelector_weights = g_bc7_weights3.ptr;
        pParams.m_pSelector_weightsx = cast(const vec4F *)g_bc7_weights3x;
        pParams.m_num_selector_weights = 8;
        pParams.m_comp_bits = 6;
        pParams.m_has_pbits = BC7ENC16_TRUE;
        pParams.m_endpoints_share_pbit = BC7ENC16_TRUE;

        const ubyte *pPartition = &g_bc7_partition2[trial_partition * 16];

        color_quad_u8[16][2] subset_colors;

        uint[2] subset_total_colors1 = [ 0, 0 ];

        ubyte[16][2] subset_pixel_index1;
        ubyte[16][2] subset_selectors1;
        color_cell_compressor_results[2] subset_results1;

        for (uint idx = 0; idx < 16; idx++)
        {
            const uint p = pPartition[idx];
            subset_colors[p][subset_total_colors1[p]] = pPixels[idx];
            subset_pixel_index1[p][subset_total_colors1[p]] = cast(ubyte)idx;
            subset_total_colors1[p]++;
        }

        ulong trial_err = 0;
        for (uint subset = 0; subset < 2; subset++)
        {
            pParams.m_num_pixels = subset_total_colors1[subset];
            pParams.m_pPixels = &subset_colors[subset][0];

            color_cell_compressor_results *pResults = &subset_results1[subset];
            pResults.m_pSelectors = &subset_selectors1[subset][0];
            pResults.m_pSelectors_temp = selectors_temp.ptr;
            ulong err = color_cell_compression(1, pParams, pResults, pComp_params);
            trial_err += err;
            if (trial_err > best_err)
                break;

        } // subset

        if (trial_err < best_err)
        {
            best_err = trial_err;
            opt_results.m_mode = 1;
            opt_results.m_partition = trial_partition;
            for (uint subset = 0; subset < 2; subset++)
            {
                for (uint i = 0; i < subset_total_colors1[subset]; i++)
                    opt_results.m_selectors[subset_pixel_index1[subset][i]] = subset_selectors1[subset][i];
                opt_results.m_low[subset] = subset_results1[subset].m_low_endpoint;
                opt_results.m_high[subset] = subset_results1[subset].m_high_endpoint;
                opt_results.m_pbits[subset][0] = subset_results1[subset].m_pbits[0];
            }
        }
    }

    encode_bc7_block(pBlock, &opt_results);
}

// Packs a single block of 16x16 RGBA pixels (R first in memory) to 128-bit BC7 block pBlock, using either mode 1 and/or 6.
// Alpha blocks will always use mode 6, and by default opaque blocks will use either modes 1 or 6.
// Returns BC7ENC16_TRUE if the block had any pixels with alpha < 255, otherwise it return BC7ENC16_FALSE. (This is not an error code - a block is always encoded.)
bc7enc16_bool bc7enc16_compress_block(void *pBlock, 
                                      const(void)* pPixelsRGBA, 
                                      const(bc7enc16_compress_block_params)* pComp_params) @system
{
    assert(g_bc7_mode_1_optimal_endpoints[255][0].m_hi != 0);

    const color_quad_u8 *pPixels = cast(const color_quad_u8 *)(pPixelsRGBA);

    color_cell_compressor_params params;
    if (pComp_params.m_perceptual)
    {
        // https://en.wikipedia.org/wiki/YCbCr#ITU-R_BT.709_conversion
        const float pr_weight = (.5f / (1.0f - .2126f)) * (.5f / (1.0f - .2126f));
        const float pb_weight = (.5f / (1.0f - .0722f)) * (.5f / (1.0f - .0722f));
        params.m_weights[0] = cast(int)(pComp_params.m_weights[0] * 4.0f);
        params.m_weights[1] = cast(int)(pComp_params.m_weights[1] * 4.0f * pr_weight);
        params.m_weights[2] = cast(int)(pComp_params.m_weights[2] * 4.0f * pb_weight);
        params.m_weights[3] = pComp_params.m_weights[3] * 4;
    }
    else
        memcpy(params.m_weights.ptr, pComp_params.m_weights.ptr, (params.m_weights).sizeof);

    for (uint i = 0; i < 16; i++)
    {
        if (pPixels[i].m_c[3] < 255)
        {
            handle_alpha_block(pBlock, pPixels, pComp_params, &params);
            return BC7ENC16_TRUE;
        }
    }
    handle_opaque_block(pBlock, pPixels, pComp_params, &params);
    return BC7ENC16_FALSE;
}

/*
------------------------------------------------------------------------------
This software is available under 2 licenses -- choose whichever you prefer.
------------------------------------------------------------------------------
ALTERNATIVE A - MIT License
Copyright(c) 2018 Richard Geldreich, Jr.
Permission is hereby granted, free of charge, to any person obtaining a copy of
this software and associated documentation files(the "Software"), to deal in
the Software without restriction, including without limitation the rights to
use, copy, modify, merge, publish, distribute, sublicense, and / or sell copies
of the Software, and to permit persons to whom the Software is furnished to do
so, subject to the following conditions :
The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
------------------------------------------------------------------------------
ALTERNATIVE B - Public Domain(www.unlicense.org)
This is free and unencumbered software released into the public domain.
Anyone is free to copy, modify, publish, use, compile, sell, or distribute this
software, either in source code form or as a compiled binary, for any purpose,
commercial or non - commercial, and by any means.
In jurisdictions that recognize copyright laws, the author or authors of this
software dedicate any and all copyright interest in the software to the public
domain.We make this dedication for the benefit of the public at large and to
the detriment of our heirs and successors.We intend this dedication to be an
overt act of relinquishment in perpetuity of all present and future rights to
this software under copyright law.
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.IN NO EVENT SHALL THE
AUTHORS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN
ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
------------------------------------------------------------------------------
*/
