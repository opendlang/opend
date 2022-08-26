/*
 * Opus decoder/demuxer
 * Copyright (c) 2012 Andrew D'Addesio
 * Copyright (c) 2013-2014 Mozilla Corporation
 *
 * This file is part of FFmpeg.
 *
 * FFmpeg is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 *
 * FFmpeg is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with FFmpeg; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA
 */
module audioformats.dopus;

version(decodeOPUS):

import core.stdc.string;

import audioformats.io;
import audioformats.internals;


private:

nothrow @nogc {


alias FFTSample = float;

struct FFTComplex {
  FFTSample re, im;
}

alias int8_t = byte;
alias uint8_t = ubyte;
alias int16_t = short;
alias uint16_t = ushort;
alias int32_t = int;
alias uint32_t = uint;
alias int64_t = long;
alias uint64_t = ulong;

enum AV_NOPTS_VALUE = cast(int64_t)0x8000000000000000UL;


T FFABS(T) (in T a) { return (a < 0 ? -a : a); }

T FFMAX(T) (in T a, in T b) { return (a > b ? a : b); }
T FFMIN(T) (in T a, in T b) { return (a < b ? a : b); }

T FFMIN3(T) (in T a, in T b, in T c) { return (a < b ? (a < c ? a : c) : (b < c ? b : c)); }


double ff_exp10 (double x) {
  import std.math : exp2;
  enum M_LOG2_10 = 3.32192809488736234787; /* log_2 10 */
  return exp2(M_LOG2_10 * x);
}


static immutable ubyte[256] ff_log2_tab = [
  0,0,1,1,2,2,2,2,3,3,3,3,3,3,3,3,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,
  5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,
  6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,
  6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,
  7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,
  7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,
  7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,
  7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7
];

alias av_log2 = ff_log2;
alias ff_log2 = ff_log2_c;

int ff_log2_c (uint v) nothrow @trusted @nogc {
  int n = 0;
  if (v & 0xffff0000) {
    v >>= 16;
    n += 16;
  }
  if (v & 0xff00) {
    v >>= 8;
    n += 8;
  }
  n += ff_log2_tab[v];
  return n;
}


/**
 * Clear high bits from an unsigned integer starting with specific bit position
 * @param  a value to clip
 * @param  p bit position to clip at
 * @return clipped value
 */
uint av_mod_uintp2 (uint a, uint p) pure nothrow @safe @nogc { return a & ((1 << p) - 1); }

/* a*inverse[b]>>32 == a/b for all 0<=a<=16909558 && 2<=b<=256
 * for a>16909558, is an overestimate by less than 1 part in 1<<24 */
static immutable uint[257] ff_inverse = [
         0, 4294967295U,2147483648U,1431655766, 1073741824,  858993460,  715827883,  613566757,
 536870912,  477218589,  429496730,  390451573,  357913942,  330382100,  306783379,  286331154,
 268435456,  252645136,  238609295,  226050911,  214748365,  204522253,  195225787,  186737709,
 178956971,  171798692,  165191050,  159072863,  153391690,  148102321,  143165577,  138547333,
 134217728,  130150525,  126322568,  122713352,  119304648,  116080198,  113025456,  110127367,
 107374183,  104755300,  102261127,   99882961,   97612894,   95443718,   93368855,   91382283,
  89478486,   87652394,   85899346,   84215046,   82595525,   81037119,   79536432,   78090315,
  76695845,   75350304,   74051161,   72796056,   71582789,   70409300,   69273667,   68174085,
  67108864,   66076420,   65075263,   64103990,   63161284,   62245903,   61356676,   60492498,
  59652324,   58835169,   58040099,   57266231,   56512728,   55778797,   55063684,   54366675,
  53687092,   53024288,   52377650,   51746594,   51130564,   50529028,   49941481,   49367441,
  48806447,   48258060,   47721859,   47197443,   46684428,   46182445,   45691142,   45210183,
  44739243,   44278014,   43826197,   43383509,   42949673,   42524429,   42107523,   41698712,
  41297763,   40904451,   40518560,   40139882,   39768216,   39403370,   39045158,   38693400,
  38347923,   38008561,   37675152,   37347542,   37025581,   36709123,   36398028,   36092163,
  35791395,   35495598,   35204650,   34918434,   34636834,   34359739,   34087043,   33818641,
  33554432,   33294321,   33038210,   32786010,   32537632,   32292988,   32051995,   31814573,
  31580642,   31350127,   31122952,   30899046,   30678338,   30460761,   30246249,   30034737,
  29826162,   29620465,   29417585,   29217465,   29020050,   28825284,   28633116,   28443493,
  28256364,   28071682,   27889399,   27709467,   27531842,   27356480,   27183338,   27012373,
  26843546,   26676816,   26512144,   26349493,   26188825,   26030105,   25873297,   25718368,
  25565282,   25414008,   25264514,   25116768,   24970741,   24826401,   24683721,   24542671,
  24403224,   24265352,   24129030,   23994231,   23860930,   23729102,   23598722,   23469767,
  23342214,   23216040,   23091223,   22967740,   22845571,   22724695,   22605092,   22486740,
  22369622,   22253717,   22139007,   22025474,   21913099,   21801865,   21691755,   21582751,
  21474837,   21367997,   21262215,   21157475,   21053762,   20951060,   20849356,   20748635,
  20648882,   20550083,   20452226,   20355296,   20259280,   20164166,   20069941,   19976593,
  19884108,   19792477,   19701685,   19611723,   19522579,   19434242,   19346700,   19259944,
  19173962,   19088744,   19004281,   18920561,   18837576,   18755316,   18673771,   18592933,
  18512791,   18433337,   18354562,   18276457,   18199014,   18122225,   18046082,   17970575,
  17895698,   17821442,   17747799,   17674763,   17602325,   17530479,   17459217,   17388532,
  17318417,   17248865,   17179870,   17111424,   17043522,   16976156,   16909321,   16843010,
  16777216
];


static immutable ubyte[256] ff_sqrt_tab = [
  0, 16, 23, 28, 32, 36, 40, 43, 46, 48, 51, 54, 56, 58, 60, 62, 64, 66, 68, 70, 72, 74, 76, 77, 79, 80, 82, 84, 85, 87, 88, 90,
 91, 92, 94, 95, 96, 98, 99,100,102,103,104,105,107,108,109,110,111,112,114,115,116,117,118,119,120,121,122,123,124,125,126,127,
128,129,130,131,132,133,134,135,136,137,138,139,140,141,142,143,144,144,145,146,147,148,149,150,151,151,152,153,154,155,156,156,
157,158,159,160,160,161,162,163,164,164,165,166,167,168,168,169,170,171,171,172,173,174,174,175,176,176,177,178,179,179,180,181,
182,182,183,184,184,185,186,186,187,188,188,189,190,190,191,192,192,193,194,194,195,196,196,197,198,198,199,200,200,201,202,202,
203,204,204,205,205,206,207,207,208,208,209,210,210,211,212,212,213,213,214,215,215,216,216,217,218,218,219,219,220,220,221,222,
222,223,223,224,224,225,226,226,227,227,228,228,229,230,230,231,231,232,232,233,233,234,235,235,236,236,237,237,238,238,239,239,
240,240,241,242,242,243,243,244,244,245,245,246,246,247,247,248,248,249,249,250,250,251,251,252,252,253,253,254,254,255,255,255
];

uint FASTDIV() (uint a, uint b) { return (cast(uint)(((cast(ulong)a) * ff_inverse[b]) >> 32)); }

uint ff_sqrt (uint a) nothrow @safe @nogc {
  uint b;
  alias av_log2_16bit = av_log2;

  if (a < 255) return (ff_sqrt_tab[a + 1] - 1) >> 4;
  else if (a < (1 << 12)) b = ff_sqrt_tab[a >> 4] >> 2;
//#if !CONFIG_SMALL
  else if (a < (1 << 14)) b = ff_sqrt_tab[a >> 6] >> 1;
  else if (a < (1 << 16)) b = ff_sqrt_tab[a >> 8];
//#endif
  else {
      int s = av_log2_16bit(a >> 16) >> 1;
      uint c = a >> (s + 2);
      b = ff_sqrt_tab[c >> (s + 8)];
      b = FASTDIV(c,b) + (b << s);
  }
  return b - (a < b * b);
}

/**
 * Clip a signed integer value into the amin-amax range.
 * @param a value to clip
 * @param amin minimum value of the clip range
 * @param amax maximum value of the clip range
 * @return clipped value
 */
int av_clip (int a, int amin, int amax) pure nothrow @safe @nogc {
  pragma(inline, true);
  //if (a < amin) return amin; else if (a > amax) return amax; else return a;
  return (a < amin ? amin : a > amax ? amax : a);
}

/**
 * Clip a signed integer to an unsigned power of two range.
 * @param  a value to clip
 * @param  p bit position to clip at
 * @return clipped value
 */
uint av_clip_uintp2 (int a, int p) pure nothrow @safe @nogc {
  pragma(inline, true);
  //if (a & ~((1<<p) - 1)) return -a >> 31 & ((1<<p) - 1); else return  a;
  return (a & ~((1<<p) - 1) ? -a >> 31 & ((1<<p) - 1) : a);
}

/**
 * Clip a signed integer value into the -32768,32767 range.
 * @param a value to clip
 * @return clipped value
 */
short av_clip_int16 (int a) pure nothrow @safe @nogc {
  pragma(inline, true);
  return cast(short)((a+0x8000U) & ~0xFFFF ? (a>>31) ^ 0x7FFF : a);
}

/**
 * Clip a float value into the amin-amax range.
 * @param a value to clip
 * @param amin minimum value of the clip range
 * @param amax maximum value of the clip range
 * @return clipped value
 */
float av_clipf (float a, float amin, float amax) pure nothrow @safe @nogc {
  pragma(inline, true);
  return (a < amin ? amin : a > amax ? amax : a);
}


// ////////////////////////////////////////////////////////////////////////// //
// dsp part
void vector_fmul_window (float* dst, const(float)* src0, const(float)* src1, const(float)* win, int len) {
  int i, j;
  dst  += len;
  win  += len;
  src0 += len;
  for (i = -len, j = len-1; i < 0; ++i, --j) {
    float s0 = src0[i];
    float s1 = src1[j];
    float wi = win[i];
    float wj = win[j];
    dst[i] = s0*wj-s1*wi;
    dst[j] = s0*wi+s1*wj;
  }
}

static void vector_fmac_scalar (float* dst, const(float)* src, float mul, int len) {
  for (int i = 0; i < len; i++) dst[i] += src[i]*mul;
}

static void vector_fmul_scalar (float* dst, const(float)* src, float mul, int len) {
  for (int i = 0; i < len; ++i) dst[i] = src[i]*mul;
}


enum {
  EOK = 0,
  EINVAL,
  ENOMEM,
}

int AVERROR (int v) { return -v; }

enum AVERROR_INVALIDDATA = -EINVAL;
enum AVERROR_PATCHWELCOME = -EINVAL;
enum AVERROR_BUG = -EINVAL;

void av_free(T) (T* p) {
  if (p !is null) {
    import core.stdc.stdlib : free;
    free(p);
  }
}


void av_freep(T) (T** p) {
  if (p !is null) {
    if (*p !is null) {
      import core.stdc.stdlib : free;
      free(*p);
      *p = null;
    }
  }
}


T* av_mallocz(T) (size_t cnt=1) {
  if (cnt == 0) return null;
  import core.stdc.stdlib : calloc;
  return cast(T*)calloc(cnt, T.sizeof);
}

alias av_malloc_array = av_mallocz;
alias av_mallocz_array = av_mallocz;
alias av_malloc = av_mallocz;

/*
int av_reallocp_array(T) (T** ptr, size_t cnt) {
  import core.stdc.stdlib : free, realloc;
  if (ptr is null) return -1;
  if (cnt == 0) {
    if (*ptr) free(*ptr);
    *ptr = null;
  } else {
    auto np = realloc(*ptr, T.sizeof*cnt);
    if (np is null) return -1;
    *ptr = cast(T*)np;
  }
  return 0;
}
*/


/*
 * Allocates a buffer, reusing the given one if large enough.
 * Contrary to av_fast_realloc the current buffer contents might not be preserved and on error
 * the old buffer is freed, thus no special handling to avoid memleaks is necessary.
 */
void av_fast_malloc (void** ptr, int* size, uint min_size) {
  static T FFMAX(T) (in T a, in T b) { return (a > b ? a : b); }
  void **p = ptr;
  if (min_size < *size) return;
  *size= FFMAX(17*min_size/16+32, min_size);
  av_free(*p);
  *p = av_malloc!ubyte(*size);
  if (!*p) *size = 0;
}


struct AVAudioFifo {
  //int fmt; // 8
  uint chans;
  float* buf;
  uint rdpos;
  uint used;
  uint alloced;
}

int av_audio_fifo_size (AVAudioFifo* af) {
  //{ import core.stdc.stdio : printf; printf("fifosize=%u\n", (af.used-af.rdpos)/af.chans); }
  return (af !is null ? (af.used-af.rdpos)/af.chans : -1);
}

int av_audio_fifo_read (AVAudioFifo* af, void** data, int nb_samples) {
  if (af is null) return -1;
  //{ import core.stdc.stdio : printf; printf("fiforead=%u\n", nb_samples); }
  auto dp = cast(float**)data;
  int total;
  while (nb_samples > 0) {
    if (af.used-af.rdpos < af.chans) break;
    foreach (immutable chn; 0..af.chans) *dp[chn]++ = af.buf[af.rdpos++];
    ++total;
    --nb_samples;
  }
  return total;
}

int av_audio_fifo_drain (AVAudioFifo* af, int nb_samples) {
  if (af is null) return -1;
  //{ import core.stdc.stdio : printf; printf("fifodrain=%u\n", nb_samples); }
  while (nb_samples > 0) {
    if (af.used-af.rdpos < af.chans) break;
    af.rdpos += af.chans;
    --nb_samples;
  }
  return 0;
}

int av_audio_fifo_write (AVAudioFifo* af, void** data, int nb_samples) {
  import core.stdc.string : memmove;
  { import core.stdc.stdio : printf; printf("fifowrite=%u\n", nb_samples); }
  assert(0);
  /+
  if (af is null || nb_samples < 0) return -1;
  if (nb_samples == 0) return 0;
  if (af.rdpos >= af.used) af.rdpos = af.used = 0;
  if (af.rdpos > 0) {
    memmove(af.buf, af.buf+af.rdpos, (af.used-af.rdpos)*float.sizeof);
    af.used -= af.rdpos;
    af.rdpos = 0;
  }
  if (af.used+nb_samples*af.chans > af.alloced) {
    import core.stdc.stdlib : realloc;
    uint newsz = af.used+nb_samples*af.chans;
    auto nb = cast(float*)realloc(af.buf, newsz*float.sizeof);
    if (nb is null) return -1;
    af.buf = nb;
    af.alloced = newsz;
  }
  auto dp = cast(float**)data;
  int total;
  while (nb_samples > 0) {
    if (af.alloced-af.used < af.chans) assert(0);
    foreach (immutable chn; 0..af.chans) af.buf[af.used++] = *dp[chn]++;
    ++total;
    --nb_samples;
  }
  return total;+/
}

AVAudioFifo* av_audio_fifo_alloc (int samplefmt, int channels, int nb_samples) {
  if (samplefmt != 8) assert(0);
  if (channels < 1 || channels > 255) assert(0);
  if (nb_samples < 0) nb_samples = 0;
  if (nb_samples > int.max/32) nb_samples = int.max/32;
  AVAudioFifo* av = av_mallocz!AVAudioFifo(1);
  if (av is null) return null;
  av.chans = channels;
  av.alloced = channels*nb_samples;
  av.buf = av_mallocz!float(av.alloced);
  if (av.buf is null) {
    av_free(av);
    return null;
  }
  av.rdpos = 0;
  av.used = 0;
  return av;
}

int av_audio_fifo_free (AVAudioFifo* af) {
  if (af !is null) {
    if (af.buf !is null) av_free(af.buf);
    *af = AVAudioFifo.init;
    av_free(af);
  }
  return 0;
}


struct AudioChannelMap {
  int  file_idx,  stream_idx,  channel_idx; // input
  int ofile_idx, ostream_idx;               // output
}


enum AV_CH_FRONT_LEFT = 0x00000001;
enum AV_CH_FRONT_RIGHT = 0x00000002;
enum AV_CH_FRONT_CENTER = 0x00000004;
enum AV_CH_LOW_FREQUENCY = 0x00000008;
enum AV_CH_BACK_LEFT = 0x00000010;
enum AV_CH_BACK_RIGHT = 0x00000020;
enum AV_CH_FRONT_LEFT_OF_CENTER = 0x00000040;
enum AV_CH_FRONT_RIGHT_OF_CENTER = 0x00000080;
enum AV_CH_BACK_CENTER = 0x00000100;
enum AV_CH_SIDE_LEFT = 0x00000200;
enum AV_CH_SIDE_RIGHT = 0x00000400;
enum AV_CH_TOP_CENTER = 0x00000800;
enum AV_CH_TOP_FRONT_LEFT = 0x00001000;
enum AV_CH_TOP_FRONT_CENTER = 0x00002000;
enum AV_CH_TOP_FRONT_RIGHT = 0x00004000;
enum AV_CH_TOP_BACK_LEFT = 0x00008000;
enum AV_CH_TOP_BACK_CENTER = 0x00010000;
enum AV_CH_TOP_BACK_RIGHT = 0x00020000;
enum AV_CH_STEREO_LEFT = 0x20000000;  ///< Stereo downmix.
enum AV_CH_STEREO_RIGHT = 0x40000000;  ///< See AV_CH_STEREO_LEFT.
enum AV_CH_WIDE_LEFT = 0x0000000080000000UL;
enum AV_CH_WIDE_RIGHT = 0x0000000100000000UL;
enum AV_CH_SURROUND_DIRECT_LEFT = 0x0000000200000000UL;
enum AV_CH_SURROUND_DIRECT_RIGHT = 0x0000000400000000UL;
enum AV_CH_LOW_FREQUENCY_2 = 0x0000000800000000UL;

/** Channel mask value used for AVCodecContext.request_channel_layout
    to indicate that the user requests the channel order of the decoder output
    to be the native codec channel order. */
enum AV_CH_LAYOUT_NATIVE = 0x8000000000000000UL;

/**
 * @}
 * @defgroup channel_mask_c Audio channel layouts
 * @{
 * */
enum AV_CH_LAYOUT_MONO = (AV_CH_FRONT_CENTER);
enum AV_CH_LAYOUT_STEREO = (AV_CH_FRONT_LEFT|AV_CH_FRONT_RIGHT);
enum AV_CH_LAYOUT_2POINT1 = (AV_CH_LAYOUT_STEREO|AV_CH_LOW_FREQUENCY);
enum AV_CH_LAYOUT_2_1 = (AV_CH_LAYOUT_STEREO|AV_CH_BACK_CENTER);
enum AV_CH_LAYOUT_SURROUND = (AV_CH_LAYOUT_STEREO|AV_CH_FRONT_CENTER);
enum AV_CH_LAYOUT_3POINT1 = (AV_CH_LAYOUT_SURROUND|AV_CH_LOW_FREQUENCY);
enum AV_CH_LAYOUT_4POINT0 = (AV_CH_LAYOUT_SURROUND|AV_CH_BACK_CENTER);
enum AV_CH_LAYOUT_4POINT1 = (AV_CH_LAYOUT_4POINT0|AV_CH_LOW_FREQUENCY);
enum AV_CH_LAYOUT_2_2 = (AV_CH_LAYOUT_STEREO|AV_CH_SIDE_LEFT|AV_CH_SIDE_RIGHT);
enum AV_CH_LAYOUT_QUAD = (AV_CH_LAYOUT_STEREO|AV_CH_BACK_LEFT|AV_CH_BACK_RIGHT);
enum AV_CH_LAYOUT_5POINT0 = (AV_CH_LAYOUT_SURROUND|AV_CH_SIDE_LEFT|AV_CH_SIDE_RIGHT);
enum AV_CH_LAYOUT_5POINT1 = (AV_CH_LAYOUT_5POINT0|AV_CH_LOW_FREQUENCY);
enum AV_CH_LAYOUT_5POINT0_BACK = (AV_CH_LAYOUT_SURROUND|AV_CH_BACK_LEFT|AV_CH_BACK_RIGHT);
enum AV_CH_LAYOUT_5POINT1_BACK = (AV_CH_LAYOUT_5POINT0_BACK|AV_CH_LOW_FREQUENCY);
enum AV_CH_LAYOUT_6POINT0 = (AV_CH_LAYOUT_5POINT0|AV_CH_BACK_CENTER);
enum AV_CH_LAYOUT_6POINT0_FRONT = (AV_CH_LAYOUT_2_2|AV_CH_FRONT_LEFT_OF_CENTER|AV_CH_FRONT_RIGHT_OF_CENTER);
enum AV_CH_LAYOUT_HEXAGONAL = (AV_CH_LAYOUT_5POINT0_BACK|AV_CH_BACK_CENTER);
enum AV_CH_LAYOUT_6POINT1 = (AV_CH_LAYOUT_5POINT1|AV_CH_BACK_CENTER);
enum AV_CH_LAYOUT_6POINT1_BACK = (AV_CH_LAYOUT_5POINT1_BACK|AV_CH_BACK_CENTER);
enum AV_CH_LAYOUT_6POINT1_FRONT = (AV_CH_LAYOUT_6POINT0_FRONT|AV_CH_LOW_FREQUENCY);
enum AV_CH_LAYOUT_7POINT0 = (AV_CH_LAYOUT_5POINT0|AV_CH_BACK_LEFT|AV_CH_BACK_RIGHT);
enum AV_CH_LAYOUT_7POINT0_FRONT = (AV_CH_LAYOUT_5POINT0|AV_CH_FRONT_LEFT_OF_CENTER|AV_CH_FRONT_RIGHT_OF_CENTER);
enum AV_CH_LAYOUT_7POINT1 = (AV_CH_LAYOUT_5POINT1|AV_CH_BACK_LEFT|AV_CH_BACK_RIGHT);
enum AV_CH_LAYOUT_7POINT1_WIDE = (AV_CH_LAYOUT_5POINT1|AV_CH_FRONT_LEFT_OF_CENTER|AV_CH_FRONT_RIGHT_OF_CENTER);
enum AV_CH_LAYOUT_7POINT1_WIDE_BACK = (AV_CH_LAYOUT_5POINT1_BACK|AV_CH_FRONT_LEFT_OF_CENTER|AV_CH_FRONT_RIGHT_OF_CENTER);
enum AV_CH_LAYOUT_OCTAGONAL = (AV_CH_LAYOUT_5POINT0|AV_CH_BACK_LEFT|AV_CH_BACK_CENTER|AV_CH_BACK_RIGHT);
enum AV_CH_LAYOUT_HEXADECAGONAL = (AV_CH_LAYOUT_OCTAGONAL|AV_CH_WIDE_LEFT|AV_CH_WIDE_RIGHT|AV_CH_TOP_BACK_LEFT|AV_CH_TOP_BACK_RIGHT|AV_CH_TOP_BACK_CENTER|AV_CH_TOP_FRONT_CENTER|AV_CH_TOP_FRONT_LEFT|AV_CH_TOP_FRONT_RIGHT);
enum AV_CH_LAYOUT_STEREO_DOWNMIX = (AV_CH_STEREO_LEFT|AV_CH_STEREO_RIGHT);


struct AVFrame {
  /**
   * number of audio samples (per channel) described by this frame
   */
  int nb_samples;
  /**
   * For video, size in bytes of each picture line.
   * For audio, size in bytes of each plane.
   *
   * For audio, only linesize[0] may be set. For planar audio, each channel
   * plane must be the same size.
   *
   * For video the linesizes should be multiples of the CPUs alignment
   * preference, this is 16 or 32 for modern desktop CPUs.
   * Some code requires such alignment other code can be slower without
   * correct alignment, for yet other it makes no difference.
   *
   * @note The linesize may be larger than the size of usable data -- there
   * may be extra padding present for performance reasons.
   */
  int[1/*AV_NUM_DATA_POINTERS*/] linesize;
  /**
   * pointers to the data planes/channels.
   *
   * For video, this should simply point to data[].
   *
   * For planar audio, each channel has a separate data pointer, and
   * linesize[0] contains the size of each channel buffer.
   * For packed audio, there is just one data pointer, and linesize[0]
   * contains the total size of the buffer for all channels.
   *
   * Note: Both data and extended_data should always be set in a valid frame,
   * but for planar audio with more channels that can fit in data,
   * extended_data must be used in order to access all channels.
   */
  ubyte** extended_data;

  AudioChannelMap* audio_channel_maps; /* one info entry per -map_channel */
  int nb_audio_channel_maps; /* number of (valid) -map_channel settings */
}


int ff_get_buffer (AVFrame* frame, int flags) {
  return 0;
}


struct AVCtx {
  int sample_fmt;
  int sample_rate;
  int channels;
  ubyte* extradata;
  uint extradata_size;
  int delay;
  ulong channel_layout;
  //void* priv;
  int preskip;
  // oggopus_private
  int need_comments;
  int64_t cur_dts;
}


ushort AV_RL16 (const(void*) b) {
  version(LittleEndian) {
    return *cast(const(ushort)*)b;
  } else {
    static assert(0, "boo!");
  }
}


struct AVPacket {
  /**
   * A reference to the reference-counted buffer where the packet data is
   * stored.
   * May be NULL, then the packet data is not reference-counted.
   */
  //AVBufferRef *buf;
  /**
   * Presentation timestamp in AVStream.time_base units; the time at which
   * the decompressed packet will be presented to the user.
   * Can be AV_NOPTS_VALUE if it is not stored in the file.
   * pts MUST be larger or equal to dts as presentation cannot happen before
   * decompression, unless one wants to view hex dumps. Some formats misuse
   * the terms dts and pts/cts to mean something different. Such timestamps
   * must be converted to true pts/dts before they are stored in AVPacket.
   */
  long pts;
  /**
   * Decompression timestamp in AVStream.time_base units; the time at which
   * the packet is decompressed.
   * Can be AV_NOPTS_VALUE if it is not stored in the file.
   */
  long dts;
  ubyte *data;
  int   size;
  int   stream_index;
  /**
   * A combination of AV_PKT_FLAG values
   */
  int   flags;
  /**
   * Additional packet data that can be provided by the container.
   * Packet can contain several types of side information.
   */
  //AVPacketSideData *side_data;
  int side_data_elems;

  /**
   * Duration of this packet in AVStream.time_base units, 0 if unknown.
   * Equals next_pts - this_pts in presentation order.
   */
  long duration;

  long pos;                            ///< byte position in stream, -1 if unknown
}

struct GetBitContext {
nothrow @nogc:
private:
  const(ubyte)* buffer;
  uint pos;
  uint bytestotal;
  ubyte curv;
  ubyte bleft;

public:
  int init_get_bits8 (const(void)* buf, uint bytelen) nothrow @trusted @nogc {
    if (bytelen >= int.max/16) assert(0, "too big");
    buffer = cast(const(ubyte)*)buf;
    bytestotal = bytelen;
    bleft = 0;
    pos = 0;
    return 0;
  }

  T get_bits(T=uint) (uint n) @trusted if (__traits(isIntegral, T)) {
    if (n == 0 || n > 8) assert(0, "invalid number of bits requested");
    T res = 0;
    foreach_reverse (immutable shift; 0..n) {
      if (bleft == 0) {
        if (pos < bytestotal) {
          curv = buffer[pos++];
        } else {
          curv = 0;
          //throw eobserr;
        }
        bleft = 8;
      }
      if (curv&0x80) res |= (1U<<shift);
      curv <<= 1;
      --bleft;
    }
    return res;
  }
}


static immutable uint64_t[9] ff_vorbis_channel_layouts = [
    AV_CH_LAYOUT_MONO,
    AV_CH_LAYOUT_STEREO,
    2/*AV_CH_LAYOUT_SURROUND*/,
    3/*AV_CH_LAYOUT_QUAD*/,
    4/*AV_CH_LAYOUT_5POINT0_BACK*/,
    5/*AV_CH_LAYOUT_5POINT1_BACK*/,
    6/*AV_CH_LAYOUT_5POINT1|AV_CH_BACK_CENTER*/,
    7/*AV_CH_LAYOUT_7POINT1*/,
    0
];

static immutable uint8_t[8][8] ff_vorbis_channel_layout_offsets = [
    [ 0 ],
    [ 0, 1 ],
    [ 0, 2, 1 ],
    [ 0, 1, 2, 3 ],
    [ 0, 2, 1, 3, 4 ],
    [ 0, 2, 1, 5, 3, 4 ],
    [ 0, 2, 1, 6, 5, 3, 4 ],
    [ 0, 2, 1, 7, 5, 6, 3, 4 ],
];


enum M_SQRT1_2 = 0.70710678118654752440; /* 1/sqrt(2) */
enum M_SQRT2 = 1.41421356237309504880; /* sqrt(2) */


enum MAX_FRAME_SIZE = 1275;
enum MAX_FRAMES = 48;
enum MAX_PACKET_DUR = 5760;

enum CELT_SHORT_BLOCKSIZE = 120;
enum CELT_OVERLAP = CELT_SHORT_BLOCKSIZE;
enum CELT_MAX_LOG_BLOCKS = 3;
enum CELT_MAX_FRAME_SIZE = (CELT_SHORT_BLOCKSIZE * (1 << CELT_MAX_LOG_BLOCKS));
enum CELT_MAX_BANDS = 21;
enum CELT_VECTORS = 11;
enum CELT_ALLOC_STEPS = 6;
enum CELT_FINE_OFFSET = 21;
enum CELT_MAX_FINE_BITS = 8;
enum CELT_NORM_SCALE = 16384;
enum CELT_QTHETA_OFFSET = 4;
enum CELT_QTHETA_OFFSET_TWOPHASE = 16;
enum CELT_DEEMPH_COEFF = 0.85000610f;
enum CELT_POSTFILTER_MINPERIOD = 15;
enum CELT_ENERGY_SILENCE = (-28.0f);

enum SILK_HISTORY = 322;
enum SILK_MAX_LPC = 16;

/* signed 16x16 . 32 multiply */
int MUL16() (int ra, int rb) { return ra*rb; }
long MUL64(T0, T1) (T0 a, T1 b) { return cast(int64_t)a * cast(int64_t)b; }
long ROUND_MULL() (int a, int b, int s) { return (((MUL64(a, b) >> ((s) - 1)) + 1) >> 1); }
int ROUND_MUL16() (int a, int b) { return ((MUL16(a, b) + 16384) >> 15); }

int opus_ilog (uint i) nothrow @trusted @nogc { return av_log2(i)+!!i; }

int MULH() (int a, int b) { return cast(int)(MUL64(a, b) >> 32); }
long MULL(T0, T1, T2) (T0 a, T1 b, T2 s) { return (MUL64(a, b) >> (s)); }


enum OPUS_TS_HEADER = 0x7FE0;        // 0x3ff (11 bits)
enum OPUS_TS_MASK = 0xFFE0;        // top 11 bits

static immutable uint8_t[38] opus_default_extradata = [
    'O', 'p', 'u', 's', 'H', 'e', 'a', 'd',
    1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
];

alias OpusMode = int;
enum /*OpusMode*/:int {
    OPUS_MODE_SILK,
    OPUS_MODE_HYBRID,
    OPUS_MODE_CELT
}

alias OpusBandwidth = int;
enum /*OpusBandwidth*/: int {
    OPUS_BANDWIDTH_NARROWBAND,
    OPUS_BANDWIDTH_MEDIUMBAND,
    OPUS_BANDWIDTH_WIDEBAND,
    OPUS_BANDWIDTH_SUPERWIDEBAND,
    OPUS_BANDWIDTH_FULLBAND
};

struct RawBitsContext {
    const(uint8_t)* position;
    uint bytes;
    uint cachelen;
    uint cacheval;
}

struct OpusRangeCoder {
    GetBitContext gb;
    RawBitsContext rb;
    uint range;
    uint value;
    uint total_read_bits;
}

struct OpusPacket {
    int packet_size;                /**< packet size */
    int data_size;                  /**< size of the useful data -- packet size - padding */
    int code;                       /**< packet code: specifies the frame layout */
    int stereo;                     /**< whether this packet is mono or stereo */
    int vbr;                        /**< vbr flag */
    int config;                     /**< configuration: tells the audio mode,
                                     **                bandwidth, and frame duration */
    int frame_count;                /**< frame count */
    int[MAX_FRAMES] frame_offset;   /**< frame offsets */
    int[MAX_FRAMES] frame_size;     /**< frame sizes */
    int frame_duration;             /**< frame duration, in samples @ 48kHz */
    OpusMode mode;             /**< mode */
    OpusBandwidth bandwidth;   /**< bandwidth */
}

struct OpusStreamContext {
    //AVCodecContext *avctx;
    //AVCtx* avctx;
    int output_channels;

    OpusRangeCoder rc;
    OpusRangeCoder redundancy_rc;
    SilkContext *silk;
    CeltContext *celt;
    //AVFloatDSPContext *fdsp;

    float[960][2] silk_buf;
    float*[2] silk_output;
    //DECLARE_ALIGNED(32, float, celt_buf)[2][960];
    float[960][2] celt_buf;
    float*[2] celt_output;

    float[960][2] redundancy_buf;
    float*[2] redundancy_output;

    /* data buffers for the final output data */
    float*[2] out_;
    int out_size;

    float *out_dummy;
    int    out_dummy_allocated_size;

    //SwrContext *swr;
    OpusResampler flr;
    AVAudioFifo *celt_delay;
    int silk_samplerate;
    /* number of samples we still want to get from the resampler */
    int delayed_samples;

    OpusPacket packet;

    int redundancy_idx;
}

// a mapping between an opus stream and an output channel
struct ChannelMap {
    int stream_idx;
    int channel_idx;

    // when a single decoded channel is mapped to multiple output channels, we
    // write to the first output directly and copy from it to the others
    // this field is set to 1 for those copied output channels
    int copy;
    // this is the index of the output channel to copy from
    int copy_idx;

    // this channel is silent
    int silence;
}

struct OpusContext {
    OpusStreamContext *streams;

    int in_channels;

    /* current output buffers for each streams */
    float **out_;
    int   *out_size;
    /* Buffers for synchronizing the streams when they have different resampling delays */
    AVAudioFifo **sync_buffers;
    /* number of decoded samples for each stream */
    int         *decoded_samples;

    int             nb_streams;
    int      nb_stereo_streams;

    //AVFloatDSPContext *fdsp;
    int16_t gain_i;
    float   gain;

    ChannelMap *channel_maps;
}

/*static av_always_inline*/ void opus_rc_normalize(OpusRangeCoder *rc)
{
    while (rc.range <= 1<<23) {
        ubyte b = cast(ubyte)rc.gb.get_bits(8)^0xFF;
        //conwritefln!"b=0x%02x"(b);
        //rc.value = ((rc.value << 8) | (rc.gb.get_bits(8) ^ 0xFF)) & ((1u << 31) - 1);
        rc.value = ((rc.value << 8) | b) & ((1u << 31) - 1);
        rc.range          <<= 8;
        rc.total_read_bits += 8;
    }

/+
  /*If the range is too small, rescale it and input some bits.*/
  while(_this->rng<=EC_CODE_BOT){
    int sym;
    _this->nbits_total+=EC_SYM_BITS;
    _this->rng<<=EC_SYM_BITS;
    /*Use up the remaining bits from our last symbol.*/
    sym=_this->rem;
    /*Read the next value from the input.*/
    _this->rem=ec_read_byte(_this);
    /*Take the rest of the bits we need from this new symbol.*/
    sym=(sym<<EC_SYM_BITS|_this->rem)>>(EC_SYM_BITS-EC_CODE_EXTRA);

    sym=(sym<<8|_this->rem)>>1;

    /*And subtract them from val, capped to be less than EC_CODE_TOP.*/
    _this->val=((_this->val<<EC_SYM_BITS)+(EC_SYM_MAX&~sym))&(EC_CODE_TOP-1);
  }
+/
}

/*static av_always_inline*/ void opus_rc_update(OpusRangeCoder *rc, uint scale,
                                          uint low, uint high,
                                          uint total)
{
    rc.value -= scale * (total - high);
    rc.range  = low ? scale * (high - low)
                      : rc.range - scale * (total - high);
    opus_rc_normalize(rc);
}

/*static av_always_inline*/ uint opus_rc_getsymbol(OpusRangeCoder *rc, const(uint16_t)*cdf)
{
    uint k, scale, total, symbol, low, high;

    total = *cdf++;

    scale   = rc.range / total;
    symbol = rc.value / scale + 1;
    symbol = total - FFMIN(symbol, total);

    for (k = 0; cdf[k] <= symbol; k++) {}
    high = cdf[k];
    low  = k ? cdf[k-1] : 0;

    opus_rc_update(rc, scale, low, high, total);

    return k;
}

/*static av_always_inline*/ uint opus_rc_p2model(OpusRangeCoder *rc, uint bits)
{
    uint k, scale;
    scale = rc.range >> bits; // in this case, scale = symbol

    if (rc.value >= scale) {
        rc.value -= scale;
        rc.range -= scale;
        k = 0;
    } else {
        rc.range = scale;
        k = 1;
    }
    opus_rc_normalize(rc);
    return k;
}

/**
 * CELT: estimate bits of entropy that have thus far been consumed for the
 *       current CELT frame, to integer and fractional (1/8th bit) precision
 */
/*static av_always_inline*/ uint opus_rc_tell(const OpusRangeCoder *rc)
{
    return rc.total_read_bits - av_log2(rc.range) - 1;
}

/*static av_always_inline*/ uint opus_rc_tell_frac(const OpusRangeCoder *rc)
{
    uint i, total_bits, rcbuffer, range;

    total_bits = rc.total_read_bits << 3;
    rcbuffer   = av_log2(rc.range) + 1;
    range      = rc.range >> (rcbuffer-16);

    for (i = 0; i < 3; i++) {
        int bit;
        range = range * range >> 15;
        bit = range >> 16;
        rcbuffer = rcbuffer << 1 | bit;
        range >>= bit;
    }

    return total_bits - rcbuffer;
}

/**
 * CELT: read 1-25 raw bits at the end of the frame, backwards byte-wise
 */
/*static av_always_inline*/ uint opus_getrawbits(OpusRangeCoder *rc, uint count)
{
    uint value = 0;

    while (rc.rb.bytes && rc.rb.cachelen < count) {
        rc.rb.cacheval |= *--rc.rb.position << rc.rb.cachelen;
        rc.rb.cachelen += 8;
        rc.rb.bytes--;
    }

    value = av_mod_uintp2(rc.rb.cacheval, count);
    rc.rb.cacheval    >>= count;
    rc.rb.cachelen     -= count;
    rc.total_read_bits += count;

    return value;
}

/**
 * CELT: read a uniform distribution
 */
/*static av_always_inline*/ uint opus_rc_unimodel(OpusRangeCoder *rc, uint size)
{
    uint bits, k, scale, total;

    bits  = opus_ilog(size - 1);
    total = (bits > 8) ? ((size - 1) >> (bits - 8)) + 1 : size;

    scale  = rc.range / total;
    k      = rc.value / scale + 1;
    k      = total - FFMIN(k, total);
    opus_rc_update(rc, scale, k, k + 1, total);

    if (bits > 8) {
        k = k << (bits - 8) | opus_getrawbits(rc, bits - 8);
        return FFMIN(k, size - 1);
    } else
        return k;
}

/*static av_always_inline*/ int opus_rc_laplace(OpusRangeCoder *rc, uint symbol, int decay)
{
    /* extends the range coder to model a Laplace distribution */
    int value = 0;
    uint scale, low = 0, center;

    scale  = rc.range >> 15;
    center = rc.value / scale + 1;
    center = (1 << 15) - FFMIN(center, 1 << 15);

    if (center >= symbol) {
        value++;
        low = symbol;
        symbol = 1 + ((32768 - 32 - symbol) * (16384-decay) >> 15);

        while (symbol > 1 && center >= low + 2 * symbol) {
            value++;
            symbol *= 2;
            low    += symbol;
            symbol  = (((symbol - 2) * decay) >> 15) + 1;
        }

        if (symbol <= 1) {
            int distance = (center - low) >> 1;
            value += distance;
            low   += 2 * distance;
        }

        if (center < low + symbol)
            value *= -1;
        else
            low += symbol;
    }

    opus_rc_update(rc, scale, low, FFMIN(low + symbol, 32768), 32768);

    return value;
}

/*static av_always_inline*/ uint opus_rc_stepmodel(OpusRangeCoder *rc, int k0)
{
    /* Use a probability of 3 up to itheta=8192 and then use 1 after */
    uint k, scale, symbol, total = (k0+1)*3 + k0;
    scale  = rc.range / total;
    symbol = rc.value / scale + 1;
    symbol = total - FFMIN(symbol, total);

    k = (symbol < (k0+1)*3) ? symbol/3 : symbol - (k0+1)*2;

    opus_rc_update(rc, scale, (k <= k0) ? 3*(k+0) : (k-1-k0) + 3*(k0+1),
                   (k <= k0) ? 3*(k+1) : (k-0-k0) + 3*(k0+1), total);
    return k;
}

/*static av_always_inline*/ uint opus_rc_trimodel(OpusRangeCoder *rc, int qn)
{
    uint k, scale, symbol, total, low, center;

    total = ((qn>>1) + 1) * ((qn>>1) + 1);
    scale   = rc.range / total;
    center = rc.value / scale + 1;
    center = total - FFMIN(center, total);

    if (center < total >> 1) {
        k      = (ff_sqrt(8 * center + 1) - 1) >> 1;
        low    = k * (k + 1) >> 1;
        symbol = k + 1;
    } else {
        k      = (2*(qn + 1) - ff_sqrt(8*(total - center - 1) + 1)) >> 1;
        low    = total - ((qn + 1 - k) * (qn + 2 - k) >> 1);
        symbol = qn + 1 - k;
    }

    opus_rc_update(rc, scale, low, low + symbol, total);

    return k;
}


static immutable uint16_t[32] opus_frame_duration = [
    480, 960, 1920, 2880,
    480, 960, 1920, 2880,
    480, 960, 1920, 2880,
    480, 960,
    480, 960,
    120, 240,  480,  960,
    120, 240,  480,  960,
    120, 240,  480,  960,
    120, 240,  480,  960,
];

/**
 * Read a 1- or 2-byte frame length
 */
int xiph_lacing_16bit (const(uint8_t)** ptr, const(uint8_t)* end) {
  int val;
  if (*ptr >= end) return AVERROR_INVALIDDATA;
  val = *(*ptr)++;
  if (val >= 252) {
    if (*ptr >= end) return AVERROR_INVALIDDATA;
    val += 4 * *(*ptr)++;
  }
  return val;
}

/**
 * Read a multi-byte length (used for code 3 packet padding size)
 */
int xiph_lacing_full (const(uint8_t)** ptr, const(uint8_t)* end) {
  int val = 0;
  int next;
  for (;;) {
    if (*ptr >= end || val > int.max-254) return AVERROR_INVALIDDATA;
    next = *(*ptr)++;
    val += next;
    if (next < 255) break; else --val;
  }
  return val;
}

/**
 * Parse Opus packet info from raw packet data
 */
int ff_opus_parse_packet (OpusPacket* pkt, const(uint8_t)* buf, int buf_size, bool self_delimiting) {
  import core.stdc.string : memset;

  const(uint8_t)* ptr = buf;
  const(uint8_t)* end = buf+buf_size;
  int padding = 0;
  int frame_bytes, i;
  //conwriteln("frame packet size=", buf_size);

  if (buf_size < 1) goto fail;

  // TOC byte
  i = *ptr++;
  pkt.code   = (i   )&0x3;
  pkt.stereo = (i>>2)&0x1;
  pkt.config = (i>>3)&0x1F;

  // code 2 and code 3 packets have at least 1 byte after the TOC
  if (pkt.code >= 2 && buf_size < 2) goto fail;

  //conwriteln("packet code: ", pkt.code);
  final switch (pkt.code) {
    case 0:
      // 1 frame
      pkt.frame_count = 1;
      pkt.vbr = 0;

      if (self_delimiting) {
        int len = xiph_lacing_16bit(&ptr, end);
        if (len < 0 || len > end-ptr) goto fail;
        end = ptr+len;
        buf_size = cast(int)(end-buf);
      }

      frame_bytes = cast(int)(end-ptr);
      if (frame_bytes > MAX_FRAME_SIZE) goto fail;
      pkt.frame_offset[0] = cast(int)(ptr-buf);
      pkt.frame_size[0] = frame_bytes;
      break;
    case 1:
      // 2 frames, equal size
      pkt.frame_count = 2;
      pkt.vbr = 0;

      if (self_delimiting) {
        int len = xiph_lacing_16bit(&ptr, end);
        if (len < 0 || 2 * len > end-ptr) goto fail;
        end = ptr+2*len;
        buf_size = cast(int)(end-buf);
      }

      frame_bytes = cast(int)(end-ptr);
      if ((frame_bytes&1) != 0 || (frame_bytes>>1) > MAX_FRAME_SIZE) goto fail;
      pkt.frame_offset[0] = cast(int)(ptr-buf);
      pkt.frame_size[0] = frame_bytes>>1;
      pkt.frame_offset[1] = pkt.frame_offset[0]+pkt.frame_size[0];
      pkt.frame_size[1] = frame_bytes>>1;
      break;
    case 2:
      // 2 frames, different sizes
      pkt.frame_count = 2;
      pkt.vbr = 1;

      // read 1st frame size
      frame_bytes = xiph_lacing_16bit(&ptr, end);
      if (frame_bytes < 0) goto fail;

      if (self_delimiting) {
        int len = xiph_lacing_16bit(&ptr, end);
        if (len < 0 || len+frame_bytes > end-ptr) goto fail;
        end = ptr+frame_bytes+len;
        buf_size = cast(int)(end-buf);
      }

      pkt.frame_offset[0] = cast(int)(ptr-buf);
      pkt.frame_size[0] = frame_bytes;

      // calculate 2nd frame size
      frame_bytes = cast(int)(end-ptr-pkt.frame_size[0]);
      if (frame_bytes < 0 || frame_bytes > MAX_FRAME_SIZE) goto fail;
      pkt.frame_offset[1] = pkt.frame_offset[0]+pkt.frame_size[0];
      pkt.frame_size[1] = frame_bytes;
      break;
    case 3:
      // 1 to 48 frames, can be different sizes
      i = *ptr++;
      pkt.frame_count = (i   )&0x3F;
      padding         = (i>>6)&0x01;
      pkt.vbr         = (i>>7)&0x01;
      //conwriteln("  frc=", pkt.frame_count, "; padding=", padding, "; vbr=", pkt.vbr);

      if (pkt.frame_count == 0 || pkt.frame_count > MAX_FRAMES) goto fail;

      // read padding size
      if (padding) {
        padding = xiph_lacing_full(&ptr, end);
        if (padding < 0) goto fail;
        //conwriteln("  real padding=", padding);
      }

      // read frame sizes
      if (pkt.vbr) {
        // for VBR, all frames except the final one have their size coded in the bitstream. the last frame size is implicit
        int total_bytes = 0;
        for (i = 0; i < pkt.frame_count-1; i++) {
          frame_bytes = xiph_lacing_16bit(&ptr, end);
          if (frame_bytes < 0) goto fail;
          pkt.frame_size[i] = frame_bytes;
          total_bytes += frame_bytes;
        }

        if (self_delimiting) {
          int len = xiph_lacing_16bit(&ptr, end);
          if (len < 0 || len+total_bytes+padding > end-ptr) goto fail;
          end = ptr+total_bytes+len+padding;
          buf_size = cast(int)(end-buf);
        }

        frame_bytes = cast(int)(end-ptr-padding);
        if (total_bytes > frame_bytes) goto fail;
        pkt.frame_offset[0] = cast(int)(ptr-buf);
        for (i = 1; i < pkt.frame_count; i++) pkt.frame_offset[i] = pkt.frame_offset[i-1]+pkt.frame_size[i-1];
        pkt.frame_size[pkt.frame_count-1] = frame_bytes-total_bytes;
      } else {
        // for CBR, the remaining packet bytes are divided evenly between the frames
        if (self_delimiting) {
          frame_bytes = xiph_lacing_16bit(&ptr, end);
          //conwriteln("frame_bytes=", frame_bytes);
          if (frame_bytes < 0 || pkt.frame_count*frame_bytes+padding > end-ptr) goto fail;
          end = ptr+pkt.frame_count*frame_bytes+padding;
          buf_size = cast(int)(end-buf);
        } else {
          frame_bytes = cast(int)(end-ptr-padding);
          //conwriteln("frame_bytes=", frame_bytes);
          if (frame_bytes % pkt.frame_count || frame_bytes/pkt.frame_count > MAX_FRAME_SIZE) goto fail;
          frame_bytes /= pkt.frame_count;
        }

        pkt.frame_offset[0] = cast(int)(ptr-buf);
        pkt.frame_size[0] = frame_bytes;
        for (i = 1; i < pkt.frame_count; i++) {
          pkt.frame_offset[i] = pkt.frame_offset[i-1]+pkt.frame_size[i-1];
          pkt.frame_size[i] = frame_bytes;
        }
      }
      break;
  }

  pkt.packet_size = buf_size;
  pkt.data_size = pkt.packet_size-padding;

  // total packet duration cannot be larger than 120ms
  pkt.frame_duration = opus_frame_duration[pkt.config];
  if (pkt.frame_duration*pkt.frame_count > MAX_PACKET_DUR) goto fail;

  // set mode and bandwidth
  if (pkt.config < 12) {
    pkt.mode = OPUS_MODE_SILK;
    pkt.bandwidth = pkt.config>>2;
    //conwriteln("SILK: ", pkt.bandwidth);
  } else if (pkt.config < 16) {
    pkt.mode = OPUS_MODE_HYBRID;
    pkt.bandwidth = OPUS_BANDWIDTH_SUPERWIDEBAND+(pkt.config >= 14 ? 1 : 0);
    //conwriteln("HYB: ", pkt.bandwidth);
  } else {
    pkt.mode = OPUS_MODE_CELT;
    pkt.bandwidth = (pkt.config-16)>>2;
    // skip medium band
    if (pkt.bandwidth) ++pkt.bandwidth;
    //conwriteln("CELT: ", pkt.bandwidth);
  }

  return 0;

fail:
  memset(pkt, 0, (*pkt).sizeof);
  return AVERROR_INVALIDDATA;
}

static int channel_reorder_vorbis(int nb_channels, int channel_idx)
{
    return ff_vorbis_channel_layout_offsets[nb_channels - 1][channel_idx];
}

static int channel_reorder_unknown(int nb_channels, int channel_idx)
{
    return channel_idx;
}


int ff_opus_parse_extradata (AVCtx* avctx, OpusContext* s, short cmtgain) {
  static immutable ubyte[2] default_channel_map = [ 0, 1 ];

  int function (int, int) nothrow @nogc channel_reorder = &channel_reorder_unknown;

  const(uint8_t)* extradata, channel_map;
  int extradata_size;
  int ver, channels, map_type, streams, stereo_streams, i, j;
  uint64_t layout;

  if (!avctx.extradata) {
    if (avctx.channels > 2) {
      //conlog("Multichannel configuration without extradata.");
      return AVERROR(EINVAL);
    }
    extradata      = opus_default_extradata.ptr;
    extradata_size = cast(uint)opus_default_extradata.length;
  } else {
    extradata = avctx.extradata;
    extradata_size = avctx.extradata_size;
  }

  if (extradata_size < 19) {
    //conlog("Invalid extradata size: ", extradata_size);
    return AVERROR_INVALIDDATA;
  }

  ver = extradata[8];
  if (ver > 15) {
    //conlog("Extradata version ", ver);
    return AVERROR_PATCHWELCOME;
  }

  avctx.delay = AV_RL16(extradata + 10);

  channels = avctx.extradata ? extradata[9] : (avctx.channels == 1) ? 1 : 2;
  if (!channels) {
    //conlog("Zero channel count specified in the extradata");
    return AVERROR_INVALIDDATA;
  }

  int ii = AV_RL16(extradata + 16);
  ii += cmtgain;
  if (ii < short.min) ii = short.min; else if (ii > short.max) ii = short.max;

  s.gain_i = cast(short)ii;
  if (s.gain_i) s.gain = ff_exp10(s.gain_i / (20.0 * 256));

  map_type = extradata[18];
  if (!map_type) {
    if (channels > 2) {
      //conlog("Channel mapping 0 is only specified for up to 2 channels");
      return AVERROR_INVALIDDATA;
    }
    layout         = (channels == 1) ? AV_CH_LAYOUT_MONO : AV_CH_LAYOUT_STEREO;
    streams        = 1;
    stereo_streams = channels - 1;
    channel_map    = default_channel_map.ptr;
  } else if (map_type == 1 || map_type == 2 || map_type == 255) {
    if (extradata_size < 21 + channels) {
      //conlog("Invalid extradata size: ", extradata_size);
      return AVERROR_INVALIDDATA;
    }

    streams        = extradata[19];
    stereo_streams = extradata[20];
    if (!streams || stereo_streams > streams || streams + stereo_streams > 255) {
      //conlog("Invalid stream/stereo stream count: ", streams, "/", stereo_streams);
      return AVERROR_INVALIDDATA;
    }

    if (map_type == 1) {
      if (channels > 8) {
        //conlog("Channel mapping 1 is only specified for up to 8 channels");
        return AVERROR_INVALIDDATA;
      }
      layout = ff_vorbis_channel_layouts[channels - 1];
      //!channel_reorder = channel_reorder_vorbis;
    } else if (map_type == 2) {
      int ambisonic_order = ff_sqrt(channels) - 1;
      if (channels != (ambisonic_order + 1) * (ambisonic_order + 1)) {
        //conlog("Channel mapping 2 is only specified for channel counts which can be written as (n + 1)^2 for nonnegative integer n");
        return AVERROR_INVALIDDATA;
      }
      layout = 0;
    } else {
      layout = 0;
    }

    channel_map = extradata + 21;
  } else {
    //conlog("Mapping type ", map_type);
    return AVERROR_PATCHWELCOME;
  }

  s.channel_maps = av_mallocz_array!(typeof(s.channel_maps[0]))(channels);
  if (s.channel_maps is null) return AVERROR(ENOMEM);

  for (i = 0; i < channels; i++) {
    ChannelMap* map = &s.channel_maps[i];
    uint8_t idx = channel_map[channel_reorder(channels, i)];

    if (idx == 255) {
      map.silence = 1;
      continue;
    } else if (idx >= streams + stereo_streams) {
      //conlog("Invalid channel map for output channel ", i, ": ", idx);
      return AVERROR_INVALIDDATA;
    }

    // check that we did not see this index yet
    map.copy = 0;
    for (j = 0; j < i; j++) {
      if (channel_map[channel_reorder(channels, j)] == idx) {
        map.copy     = 1;
        map.copy_idx = j;
        break;
      }
    }

    if (idx < 2*stereo_streams) {
      map.stream_idx  = idx/2;
      map.channel_idx = idx&1;
    } else {
      map.stream_idx  = idx-stereo_streams;
      map.channel_idx = 0;
    }
  }

  avctx.channels       = channels;
  avctx.channel_layout = layout;
  s.nb_streams         = streams;
  s.nb_stereo_streams  = stereo_streams;

  return 0;
}


struct IMDCT15Context {
  int fft_n;
  int len2;
  int len4;

  FFTComplex* tmp;

  FFTComplex* twiddle_exptab;

  FFTComplex*[6] exptab;

  /**
   * Calculate the middle half of the iMDCT
   */
  void function (IMDCT15Context* s, float* dst, const(float)* src, ptrdiff_t src_stride, float scale) nothrow @nogc imdct_half;
}


// minimal iMDCT size to make SIMD opts easier
enum CELT_MIN_IMDCT_SIZE = 120;

// complex c = a * b
enum CMUL3(string cre, string cim, string are, string aim, string bre, string bim) =
  ""~cre~" = "~are~" * "~bre~" - "~aim~" * "~bim~";\n"~
  ""~cim~" = "~are~" * "~bim~" + "~aim~" * "~bre~";\n";

enum CMUL(string c, string a, string b) = CMUL3!("("~c~").re", "("~c~").im", "("~a~").re", "("~a~").im", "("~b~").re", "("~b~").im");

// complex c = a * b
//         d = a * conjugate(b)
enum CMUL2(string c, string d, string a, string b) =
"{\n"~
  "float are = ("~a~").re;\n"~
  "float aim = ("~a~").im;\n"~
  "float bre = ("~b~").re;\n"~
  "float bim = ("~b~").im;\n"~
  "float rr  = are * bre;\n"~
  "float ri  = are * bim;\n"~
  "float ir  = aim * bre;\n"~
  "float ii  = aim * bim;\n"~
  "("~c~").re =  rr - ii;\n"~
  "("~c~").im =  ri + ir;\n"~
  "("~d~").re =  rr + ii;\n"~
  "("~d~").im = -ri + ir;\n"~
"}\n";

/*av_cold*/ void ff_imdct15_uninit (IMDCT15Context** ps) {
  IMDCT15Context* s = *ps;
  if (s is null) return;
  for (int i = 0; i < /*FF_ARRAY_ELEMS*/cast(int)s.exptab.length; ++i) av_freep(&s.exptab[i]);
  av_freep(&s.twiddle_exptab);
  av_freep(&s.tmp);
  av_freep(ps);
}

//static void imdct15_half (IMDCT15Context* s, float* dst, const(float)* src, ptrdiff_t stride, float scale);

/*av_cold*/ int ff_imdct15_init (IMDCT15Context** ps, int N) {
  import std.math : cos, sin, PI;

  IMDCT15Context* s;
  int len2 = 15*(1<<N);
  int len  = 2*len2;
  int i, j;

  if (len2 > CELT_MAX_FRAME_SIZE || len2 < CELT_MIN_IMDCT_SIZE) return AVERROR(EINVAL);

  s = av_mallocz!IMDCT15Context();
  if (!s) return AVERROR(ENOMEM);

  s.fft_n = N - 1;
  s.len4 = len2 / 2;
  s.len2 = len2;

  s.tmp = av_malloc_array!(typeof(*s.tmp))(len);
  if (!s.tmp) goto fail;

  s.twiddle_exptab  = av_malloc_array!(typeof(*s.twiddle_exptab))(s.len4);
  if (!s.twiddle_exptab) goto fail;

  for (i = 0; i < s.len4; i++) {
    s.twiddle_exptab[i].re = cos(2 * PI * (i + 0.125 + s.len4) / len);
    s.twiddle_exptab[i].im = sin(2 * PI * (i + 0.125 + s.len4) / len);
  }

  for (i = 0; i < /*FF_ARRAY_ELEMS*/cast(int)s.exptab.length; i++) {
    int NN = 15 * (1 << i);
    s.exptab[i] = av_malloc!(typeof(*s.exptab[i]))(FFMAX(NN, 19));
    if (!s.exptab[i]) goto fail;
    for (j = 0; j < NN; j++) {
      s.exptab[i][j].re = cos(2 * PI * j / NN);
      s.exptab[i][j].im = sin(2 * PI * j / NN);
    }
  }

  // wrap around to simplify fft15
  for (j = 15; j < 19; j++) s.exptab[0][j] = s.exptab[0][j - 15];

  s.imdct_half = &imdct15_half;

  //if (ARCH_AARCH64) ff_imdct15_init_aarch64(s);

  *ps = s;

  return 0;

fail:
  ff_imdct15_uninit(&s);
  return AVERROR(ENOMEM);
}


private void fft5(FFTComplex* out_, const(FFTComplex)* in_, ptrdiff_t stride) {
  // [0] = exp(2 * i * pi / 5), [1] = exp(2 * i * pi * 2 / 5)
  static immutable FFTComplex[2] fact = [ { 0.30901699437494745,  0.95105651629515353 },
                                          { -0.80901699437494734, 0.58778525229247325 } ];

  FFTComplex[4][4] z;

  mixin(CMUL2!("z[0][0]", "z[0][3]", "in_[1 * stride]", "fact[0]"));
  mixin(CMUL2!("z[0][1]", "z[0][2]", "in_[1 * stride]", "fact[1]"));
  mixin(CMUL2!("z[1][0]", "z[1][3]", "in_[2 * stride]", "fact[0]"));
  mixin(CMUL2!("z[1][1]", "z[1][2]", "in_[2 * stride]", "fact[1]"));
  mixin(CMUL2!("z[2][0]", "z[2][3]", "in_[3 * stride]", "fact[0]"));
  mixin(CMUL2!("z[2][1]", "z[2][2]", "in_[3 * stride]", "fact[1]"));
  mixin(CMUL2!("z[3][0]", "z[3][3]", "in_[4 * stride]", "fact[0]"));
  mixin(CMUL2!("z[3][1]", "z[3][2]", "in_[4 * stride]", "fact[1]"));

  out_[0].re = in_[0].re + in_[stride].re + in_[2 * stride].re + in_[3 * stride].re + in_[4 * stride].re;
  out_[0].im = in_[0].im + in_[stride].im + in_[2 * stride].im + in_[3 * stride].im + in_[4 * stride].im;

  out_[1].re = in_[0].re + z[0][0].re + z[1][1].re + z[2][2].re + z[3][3].re;
  out_[1].im = in_[0].im + z[0][0].im + z[1][1].im + z[2][2].im + z[3][3].im;

  out_[2].re = in_[0].re + z[0][1].re + z[1][3].re + z[2][0].re + z[3][2].re;
  out_[2].im = in_[0].im + z[0][1].im + z[1][3].im + z[2][0].im + z[3][2].im;

  out_[3].re = in_[0].re + z[0][2].re + z[1][0].re + z[2][3].re + z[3][1].re;
  out_[3].im = in_[0].im + z[0][2].im + z[1][0].im + z[2][3].im + z[3][1].im;

  out_[4].re = in_[0].re + z[0][3].re + z[1][2].re + z[2][1].re + z[3][0].re;
  out_[4].im = in_[0].im + z[0][3].im + z[1][2].im + z[2][1].im + z[3][0].im;
}

private void fft15 (IMDCT15Context* s, FFTComplex* out_, const(FFTComplex)* in_, ptrdiff_t stride) {
  const(FFTComplex)* exptab = s.exptab[0];
  FFTComplex[5] tmp;
  FFTComplex[5] tmp1;
  FFTComplex[5] tmp2;
  int k;

  fft5(tmp.ptr,  in_,              stride * 3);
  fft5(tmp1.ptr, in_ +     stride, stride * 3);
  fft5(tmp2.ptr, in_ + 2 * stride, stride * 3);

  for (k = 0; k < 5; k++) {
    FFTComplex t1, t2;

    mixin(CMUL!("t1", "tmp1[k]", "exptab[k]"));
    mixin(CMUL!("t2", "tmp2[k]", "exptab[2 * k]"));
    out_[k].re = tmp[k].re + t1.re + t2.re;
    out_[k].im = tmp[k].im + t1.im + t2.im;

    mixin(CMUL!("t1", "tmp1[k]", "exptab[k + 5]"));
    mixin(CMUL!("t2", "tmp2[k]", "exptab[2 * (k + 5)]"));
    out_[k + 5].re = tmp[k].re + t1.re + t2.re;
    out_[k + 5].im = tmp[k].im + t1.im + t2.im;

    mixin(CMUL!("t1", "tmp1[k]", "exptab[k + 10]"));
    mixin(CMUL!("t2", "tmp2[k]", "exptab[2 * k + 5]"));
    out_[k + 10].re = tmp[k].re + t1.re + t2.re;
    out_[k + 10].im = tmp[k].im + t1.im + t2.im;
  }
}

/*
* FFT of the length 15 * (2^N)
*/
private void fft_calc (IMDCT15Context* s, FFTComplex* out_, const(FFTComplex)* in_, int N, ptrdiff_t stride) {
  if (N) {
    const(FFTComplex)* exptab = s.exptab[N];
    const int len2 = 15 * (1 << (N - 1));
    int k;

    fft_calc(s, out_,        in_,          N - 1, stride * 2);
    fft_calc(s, out_ + len2, in_ + stride, N - 1, stride * 2);

    for (k = 0; k < len2; k++) {
      FFTComplex t;

      mixin(CMUL!("t", "out_[len2 + k]", "exptab[k]"));

      out_[len2 + k].re = out_[k].re - t.re;
      out_[len2 + k].im = out_[k].im - t.im;

      out_[k].re += t.re;
      out_[k].im += t.im;
    }
  } else {
    fft15(s, out_, in_, stride);
  }
}

private void imdct15_half (IMDCT15Context* s, float* dst, const(float)* src, ptrdiff_t stride, float scale) {
  FFTComplex *z = cast(FFTComplex *)dst;
  const int len8 = s.len4 / 2;
  const(float)* in1 = src;
  const(float)* in2 = src + (s.len2 - 1) * stride;
  int i;

  for (i = 0; i < s.len4; i++) {
    FFTComplex tmp = { *in2, *in1 };
    mixin(CMUL!("s.tmp[i]", "tmp", "s.twiddle_exptab[i]"));
    in1 += 2 * stride;
    in2 -= 2 * stride;
  }

  fft_calc(s, z, s.tmp, s.fft_n, 1);

  for (i = 0; i < len8; i++) {
    float r0, i0, r1, i1;

    mixin(CMUL3!("r0", "i1", "z[len8 - i - 1].im", "z[len8 - i - 1].re", "s.twiddle_exptab[len8 - i - 1].im", "s.twiddle_exptab[len8 - i - 1].re"));
    mixin(CMUL3!("r1", "i0", "z[len8 + i].im",     "z[len8 + i].re",     "s.twiddle_exptab[len8 + i].im",     "s.twiddle_exptab[len8 + i].re"));
    z[len8 - i - 1].re = scale * r0;
    z[len8 - i - 1].im = scale * i0;
    z[len8 + i].re     = scale * r1;
    z[len8 + i].im     = scale * i1;
  }
}

alias CeltSpread = int;
enum /*CeltSpread*/:int {
    CELT_SPREAD_NONE,
    CELT_SPREAD_LIGHT,
    CELT_SPREAD_NORMAL,
    CELT_SPREAD_AGGRESSIVE
}

struct CeltFrame {
    float[CELT_MAX_BANDS] energy;
    float[CELT_MAX_BANDS][2] prev_energy;

    uint8_t[CELT_MAX_BANDS] collapse_masks;

    /* buffer for mdct output + postfilter */
    //DECLARE_ALIGNED(32, float, buf)[2048];
    float[2048] buf;

    /* postfilter parameters */
    int pf_period_new;
    float[3] pf_gains_new;
    int pf_period;
    float[3] pf_gains;
    int pf_period_old;
    float[3] pf_gains_old;

    float deemph_coeff;
}

struct CeltContext {
    // constant values that do not change during context lifetime
    //AVCodecContext    *avctx;
    IMDCT15Context*[4] imdct;
    //AVFloatDSPContext* dsp;
    int output_channels;

    // values that have inter-frame effect and must be reset on flush
    CeltFrame[2] frame;
    uint32_t seed;
    int flushed;

    // values that only affect a single frame
    int coded_channels;
    int framebits;
    int duration;

    /* number of iMDCT blocks in the frame */
    int blocks;
    /* size of each block */
    int blocksize;

    int startband;
    int endband;
    int codedbands;

    int anticollapse_bit;

    int intensitystereo;
    int dualstereo;
    CeltSpread spread;

    int remaining;
    int remaining2;
    int[CELT_MAX_BANDS] fine_bits;
    int[CELT_MAX_BANDS] fine_priority;
    int[CELT_MAX_BANDS] pulses;
    int[CELT_MAX_BANDS] tf_change;

    //DECLARE_ALIGNED(32, float, coeffs)[2][CELT_MAX_FRAME_SIZE];
    //DECLARE_ALIGNED(32, float, scratch)[22 * 8]; // MAX(celt_freq_range) * 1<<CELT_MAX_LOG_BLOCKS
    float[CELT_MAX_FRAME_SIZE][2] coeffs;
    float[22 * 8] scratch;
}

static immutable uint16_t[4] celt_model_tapset = [ 4, 2, 3, 4 ];

static immutable uint16_t[5] celt_model_spread = [ 32, 7, 9, 30, 32 ];

static immutable uint16_t[12] celt_model_alloc_trim = [
    128,   2,   4,   9,  19,  41,  87, 109, 119, 124, 126, 128
];

static immutable uint16_t[4] celt_model_energy_small = [ 4, 2, 3, 4 ];

static immutable uint8_t[22] celt_freq_bands = [ /* in steps of 200Hz */
    0,  1,  2,  3,  4,  5,  6,  7,  8, 10, 12, 14, 16, 20, 24, 28, 34, 40, 48, 60, 78, 100
];

static immutable uint8_t[21] celt_freq_range = [
    1,  1,  1,  1,  1,  1,  1,  1,  2,  2,  2,  2,  4,  4,  4,  6,  6,  8, 12, 18, 22
];

static immutable uint8_t[21] celt_log_freq_range = [
    0,  0,  0,  0,  0,  0,  0,  0,  8,  8,  8,  8, 16, 16, 16, 21, 21, 24, 29, 34, 36
];

static immutable int8_t[2][2][2][4] celt_tf_select = [
    [ [ [ 0, -1 ], [ 0, -1 ] ], [ [ 0, -1 ], [ 0, -1 ] ] ],
    [ [ [ 0, -1 ], [ 0, -2 ] ], [ [ 1,  0 ], [ 1, -1 ] ] ],
    [ [ [ 0, -2 ], [ 0, -3 ] ], [ [ 2,  0 ], [ 1, -1 ] ] ],
    [ [ [ 0, -2 ], [ 0, -3 ] ], [ [ 3,  0 ], [ 1, -1 ] ] ]
];

static immutable float[25] celt_mean_energy = [
    6.437500f, 6.250000f, 5.750000f, 5.312500f, 5.062500f,
    4.812500f, 4.500000f, 4.375000f, 4.875000f, 4.687500f,
    4.562500f, 4.437500f, 4.875000f, 4.625000f, 4.312500f,
    4.500000f, 4.375000f, 4.625000f, 4.750000f, 4.437500f,
    3.750000f, 3.750000f, 3.750000f, 3.750000f, 3.750000f
];

static immutable float[4] celt_alpha_coef = [
    29440.0f/32768.0f,    26112.0f/32768.0f,    21248.0f/32768.0f,    16384.0f/32768.0f
];

static immutable float[4] celt_beta_coef = [ /* TODO: precompute 1 minus this if the code ends up neater */
    30147.0f/32768.0f,    22282.0f/32768.0f,    12124.0f/32768.0f,     6554.0f/32768.0f
];

static immutable uint8_t[42][2][4] celt_coarse_energy_dist = [
    [
        [       // 120-sample inter
             72, 127,  65, 129,  66, 128,  65, 128,  64, 128,  62, 128,  64, 128,
             64, 128,  92,  78,  92,  79,  92,  78,  90,  79, 116,  41, 115,  40,
            114,  40, 132,  26, 132,  26, 145,  17, 161,  12, 176,  10, 177,  11
        ], [    // 120-sample intra
             24, 179,  48, 138,  54, 135,  54, 132,  53, 134,  56, 133,  55, 132,
             55, 132,  61, 114,  70,  96,  74,  88,  75,  88,  87,  74,  89,  66,
             91,  67, 100,  59, 108,  50, 120,  40, 122,  37,  97,  43,  78,  50
        ]
    ], [
        [       // 240-sample inter
             83,  78,  84,  81,  88,  75,  86,  74,  87,  71,  90,  73,  93,  74,
             93,  74, 109,  40, 114,  36, 117,  34, 117,  34, 143,  17, 145,  18,
            146,  19, 162,  12, 165,  10, 178,   7, 189,   6, 190,   8, 177,   9
        ], [    // 240-sample intra
             23, 178,  54, 115,  63, 102,  66,  98,  69,  99,  74,  89,  71,  91,
             73,  91,  78,  89,  86,  80,  92,  66,  93,  64, 102,  59, 103,  60,
            104,  60, 117,  52, 123,  44, 138,  35, 133,  31,  97,  38,  77,  45
        ]
    ], [
        [       // 480-sample inter
             61,  90,  93,  60, 105,  42, 107,  41, 110,  45, 116,  38, 113,  38,
            112,  38, 124,  26, 132,  27, 136,  19, 140,  20, 155,  14, 159,  16,
            158,  18, 170,  13, 177,  10, 187,   8, 192,   6, 175,   9, 159,  10
        ], [    // 480-sample intra
             21, 178,  59, 110,  71,  86,  75,  85,  84,  83,  91,  66,  88,  73,
             87,  72,  92,  75,  98,  72, 105,  58, 107,  54, 115,  52, 114,  55,
            112,  56, 129,  51, 132,  40, 150,  33, 140,  29,  98,  35,  77,  42
        ]
    ], [
        [       // 960-sample inter
             42, 121,  96,  66, 108,  43, 111,  40, 117,  44, 123,  32, 120,  36,
            119,  33, 127,  33, 134,  34, 139,  21, 147,  23, 152,  20, 158,  25,
            154,  26, 166,  21, 173,  16, 184,  13, 184,  10, 150,  13, 139,  15
        ], [    // 960-sample intra
             22, 178,  63, 114,  74,  82,  84,  83,  92,  82, 103,  62,  96,  72,
             96,  67, 101,  73, 107,  72, 113,  55, 118,  52, 125,  52, 118,  52,
            117,  55, 135,  49, 137,  39, 157,  32, 145,  29,  97,  33,  77,  40
        ]
    ]
];

static immutable uint8_t[21][11] celt_static_alloc = [  /* 1/32 bit/sample */
    [   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0 ],
    [  90,  80,  75,  69,  63,  56,  49,  40,  34,  29,  20,  18,  10,   0,   0,   0,   0,   0,   0,   0,   0 ],
    [ 110, 100,  90,  84,  78,  71,  65,  58,  51,  45,  39,  32,  26,  20,  12,   0,   0,   0,   0,   0,   0 ],
    [ 118, 110, 103,  93,  86,  80,  75,  70,  65,  59,  53,  47,  40,  31,  23,  15,   4,   0,   0,   0,   0 ],
    [ 126, 119, 112, 104,  95,  89,  83,  78,  72,  66,  60,  54,  47,  39,  32,  25,  17,  12,   1,   0,   0 ],
    [ 134, 127, 120, 114, 103,  97,  91,  85,  78,  72,  66,  60,  54,  47,  41,  35,  29,  23,  16,  10,   1 ],
    [ 144, 137, 130, 124, 113, 107, 101,  95,  88,  82,  76,  70,  64,  57,  51,  45,  39,  33,  26,  15,   1 ],
    [ 152, 145, 138, 132, 123, 117, 111, 105,  98,  92,  86,  80,  74,  67,  61,  55,  49,  43,  36,  20,   1 ],
    [ 162, 155, 148, 142, 133, 127, 121, 115, 108, 102,  96,  90,  84,  77,  71,  65,  59,  53,  46,  30,   1 ],
    [ 172, 165, 158, 152, 143, 137, 131, 125, 118, 112, 106, 100,  94,  87,  81,  75,  69,  63,  56,  45,  20 ],
    [ 200, 200, 200, 200, 200, 200, 200, 200, 198, 193, 188, 183, 178, 173, 168, 163, 158, 153, 148, 129, 104 ]
];

static immutable uint8_t[21][2][4] celt_static_caps = [
    [       // 120-sample
        [224, 224, 224, 224, 224, 224, 224, 224, 160, 160,
         160, 160, 185, 185, 185, 178, 178, 168, 134,  61,  37],
        [224, 224, 224, 224, 224, 224, 224, 224, 240, 240,
         240, 240, 207, 207, 207, 198, 198, 183, 144,  66,  40],
    ], [    // 240-sample
        [160, 160, 160, 160, 160, 160, 160, 160, 185, 185,
         185, 185, 193, 193, 193, 183, 183, 172, 138,  64,  38],
        [240, 240, 240, 240, 240, 240, 240, 240, 207, 207,
         207, 207, 204, 204, 204, 193, 193, 180, 143,  66,  40],
    ], [    // 480-sample
        [185, 185, 185, 185, 185, 185, 185, 185, 193, 193,
         193, 193, 193, 193, 193, 183, 183, 172, 138,  65,  39],
        [207, 207, 207, 207, 207, 207, 207, 207, 204, 204,
         204, 204, 201, 201, 201, 188, 188, 176, 141,  66,  40],
    ], [    // 960-sample
        [193, 193, 193, 193, 193, 193, 193, 193, 193, 193,
         193, 193, 194, 194, 194, 184, 184, 173, 139,  65,  39],
        [204, 204, 204, 204, 204, 204, 204, 204, 201, 201,
         201, 201, 198, 198, 198, 187, 187, 175, 140,  66,  40]
    ]
];

static immutable uint8_t[392] celt_cache_bits = [
    40, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7,
    7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7,
    7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 40, 15, 23, 28,
    31, 34, 36, 38, 39, 41, 42, 43, 44, 45, 46, 47, 47, 49, 50,
    51, 52, 53, 54, 55, 55, 57, 58, 59, 60, 61, 62, 63, 63, 65,
    66, 67, 68, 69, 70, 71, 71, 40, 20, 33, 41, 48, 53, 57, 61,
    64, 66, 69, 71, 73, 75, 76, 78, 80, 82, 85, 87, 89, 91, 92,
    94, 96, 98, 101, 103, 105, 107, 108, 110, 112, 114, 117, 119, 121, 123,
    124, 126, 128, 40, 23, 39, 51, 60, 67, 73, 79, 83, 87, 91, 94,
    97, 100, 102, 105, 107, 111, 115, 118, 121, 124, 126, 129, 131, 135, 139,
    142, 145, 148, 150, 153, 155, 159, 163, 166, 169, 172, 174, 177, 179, 35,
    28, 49, 65, 78, 89, 99, 107, 114, 120, 126, 132, 136, 141, 145, 149,
    153, 159, 165, 171, 176, 180, 185, 189, 192, 199, 205, 211, 216, 220, 225,
    229, 232, 239, 245, 251, 21, 33, 58, 79, 97, 112, 125, 137, 148, 157,
    166, 174, 182, 189, 195, 201, 207, 217, 227, 235, 243, 251, 17, 35, 63,
    86, 106, 123, 139, 152, 165, 177, 187, 197, 206, 214, 222, 230, 237, 250,
    25, 31, 55, 75, 91, 105, 117, 128, 138, 146, 154, 161, 168, 174, 180,
    185, 190, 200, 208, 215, 222, 229, 235, 240, 245, 255, 16, 36, 65, 89,
    110, 128, 144, 159, 173, 185, 196, 207, 217, 226, 234, 242, 250, 11, 41,
    74, 103, 128, 151, 172, 191, 209, 225, 241, 255, 9, 43, 79, 110, 138,
    163, 186, 207, 227, 246, 12, 39, 71, 99, 123, 144, 164, 182, 198, 214,
    228, 241, 253, 9, 44, 81, 113, 142, 168, 192, 214, 235, 255, 7, 49,
    90, 127, 160, 191, 220, 247, 6, 51, 95, 134, 170, 203, 234, 7, 47,
    87, 123, 155, 184, 212, 237, 6, 52, 97, 137, 174, 208, 240, 5, 57,
    106, 151, 192, 231, 5, 59, 111, 158, 202, 243, 5, 55, 103, 147, 187,
    224, 5, 60, 113, 161, 206, 248, 4, 65, 122, 175, 224, 4, 67, 127,
    182, 234
];

static immutable int16_t[105] celt_cache_index = [
    -1, -1, -1, -1, -1, -1, -1, -1, 0, 0, 0, 0, 41, 41, 41,
    82, 82, 123, 164, 200, 222, 0, 0, 0, 0, 0, 0, 0, 0, 41,
    41, 41, 41, 123, 123, 123, 164, 164, 240, 266, 283, 295, 41, 41, 41,
    41, 41, 41, 41, 41, 123, 123, 123, 123, 240, 240, 240, 266, 266, 305,
    318, 328, 336, 123, 123, 123, 123, 123, 123, 123, 123, 240, 240, 240, 240,
    305, 305, 305, 318, 318, 343, 351, 358, 364, 240, 240, 240, 240, 240, 240,
    240, 240, 305, 305, 305, 305, 343, 343, 343, 351, 351, 370, 376, 382, 387,
];

static immutable uint8_t[24] celt_log2_frac = [
    0, 8, 13, 16, 19, 21, 23, 24, 26, 27, 28, 29, 30, 31, 32, 32, 33, 34, 34, 35, 36, 36, 37, 37
];

static immutable uint8_t[16] celt_bit_interleave = [
    0, 1, 1, 1, 2, 3, 3, 3, 2, 3, 3, 3, 2, 3, 3, 3
];

static immutable uint8_t[16] celt_bit_deinterleave = [
    0x00, 0x03, 0x0C, 0x0F, 0x30, 0x33, 0x3C, 0x3F,
    0xC0, 0xC3, 0xCC, 0xCF, 0xF0, 0xF3, 0xFC, 0xFF
];

static immutable uint8_t[30] celt_hadamard_ordery = [
    1,   0,
    3,   0,  2,  1,
    7,   0,  4,  3,  6,  1,  5,  2,
    15,  0,  8,  7, 12,  3, 11,  4, 14,  1,  9,  6, 13,  2, 10,  5
];

static immutable uint16_t[8] celt_qn_exp2 = [
    16384, 17866, 19483, 21247, 23170, 25267, 27554, 30048
];

static immutable uint32_t[1272] celt_pvq_u = [
    /* N = 0, K = 0...176 */
    1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    /* N = 1, K = 1...176 */
    1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
    1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
    1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
    1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
    1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
    1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
    1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
    /* N = 2, K = 2...176 */
    3, 5, 7, 9, 11, 13, 15, 17, 19, 21, 23, 25, 27, 29, 31, 33, 35, 37, 39, 41,
    43, 45, 47, 49, 51, 53, 55, 57, 59, 61, 63, 65, 67, 69, 71, 73, 75, 77, 79,
    81, 83, 85, 87, 89, 91, 93, 95, 97, 99, 101, 103, 105, 107, 109, 111, 113,
    115, 117, 119, 121, 123, 125, 127, 129, 131, 133, 135, 137, 139, 141, 143,
    145, 147, 149, 151, 153, 155, 157, 159, 161, 163, 165, 167, 169, 171, 173,
    175, 177, 179, 181, 183, 185, 187, 189, 191, 193, 195, 197, 199, 201, 203,
    205, 207, 209, 211, 213, 215, 217, 219, 221, 223, 225, 227, 229, 231, 233,
    235, 237, 239, 241, 243, 245, 247, 249, 251, 253, 255, 257, 259, 261, 263,
    265, 267, 269, 271, 273, 275, 277, 279, 281, 283, 285, 287, 289, 291, 293,
    295, 297, 299, 301, 303, 305, 307, 309, 311, 313, 315, 317, 319, 321, 323,
    325, 327, 329, 331, 333, 335, 337, 339, 341, 343, 345, 347, 349, 351,
    /* N = 3, K = 3...176 */
    13, 25, 41, 61, 85, 113, 145, 181, 221, 265, 313, 365, 421, 481, 545, 613,
    685, 761, 841, 925, 1013, 1105, 1201, 1301, 1405, 1513, 1625, 1741, 1861,
    1985, 2113, 2245, 2381, 2521, 2665, 2813, 2965, 3121, 3281, 3445, 3613, 3785,
    3961, 4141, 4325, 4513, 4705, 4901, 5101, 5305, 5513, 5725, 5941, 6161, 6385,
    6613, 6845, 7081, 7321, 7565, 7813, 8065, 8321, 8581, 8845, 9113, 9385, 9661,
    9941, 10225, 10513, 10805, 11101, 11401, 11705, 12013, 12325, 12641, 12961,
    13285, 13613, 13945, 14281, 14621, 14965, 15313, 15665, 16021, 16381, 16745,
    17113, 17485, 17861, 18241, 18625, 19013, 19405, 19801, 20201, 20605, 21013,
    21425, 21841, 22261, 22685, 23113, 23545, 23981, 24421, 24865, 25313, 25765,
    26221, 26681, 27145, 27613, 28085, 28561, 29041, 29525, 30013, 30505, 31001,
    31501, 32005, 32513, 33025, 33541, 34061, 34585, 35113, 35645, 36181, 36721,
    37265, 37813, 38365, 38921, 39481, 40045, 40613, 41185, 41761, 42341, 42925,
    43513, 44105, 44701, 45301, 45905, 46513, 47125, 47741, 48361, 48985, 49613,
    50245, 50881, 51521, 52165, 52813, 53465, 54121, 54781, 55445, 56113, 56785,
    57461, 58141, 58825, 59513, 60205, 60901, 61601,
    /* N = 4, K = 4...176 */
    63, 129, 231, 377, 575, 833, 1159, 1561, 2047, 2625, 3303, 4089, 4991, 6017,
    7175, 8473, 9919, 11521, 13287, 15225, 17343, 19649, 22151, 24857, 27775,
    30913, 34279, 37881, 41727, 45825, 50183, 54809, 59711, 64897, 70375, 76153,
    82239, 88641, 95367, 102425, 109823, 117569, 125671, 134137, 142975, 152193,
    161799, 171801, 182207, 193025, 204263, 215929, 228031, 240577, 253575,
    267033, 280959, 295361, 310247, 325625, 341503, 357889, 374791, 392217,
    410175, 428673, 447719, 467321, 487487, 508225, 529543, 551449, 573951,
    597057, 620775, 645113, 670079, 695681, 721927, 748825, 776383, 804609,
    833511, 863097, 893375, 924353, 956039, 988441, 1021567, 1055425, 1090023,
    1125369, 1161471, 1198337, 1235975, 1274393, 1313599, 1353601, 1394407,
    1436025, 1478463, 1521729, 1565831, 1610777, 1656575, 1703233, 1750759,
    1799161, 1848447, 1898625, 1949703, 2001689, 2054591, 2108417, 2163175,
    2218873, 2275519, 2333121, 2391687, 2451225, 2511743, 2573249, 2635751,
    2699257, 2763775, 2829313, 2895879, 2963481, 3032127, 3101825, 3172583,
    3244409, 3317311, 3391297, 3466375, 3542553, 3619839, 3698241, 3777767,
    3858425, 3940223, 4023169, 4107271, 4192537, 4278975, 4366593, 4455399,
    4545401, 4636607, 4729025, 4822663, 4917529, 5013631, 5110977, 5209575,
    5309433, 5410559, 5512961, 5616647, 5721625, 5827903, 5935489, 6044391,
    6154617, 6266175, 6379073, 6493319, 6608921, 6725887, 6844225, 6963943,
    7085049, 7207551,
    /* N = 5, K = 5...176 */
    321, 681, 1289, 2241, 3649, 5641, 8361, 11969, 16641, 22569, 29961, 39041,
    50049, 63241, 78889, 97281, 118721, 143529, 172041, 204609, 241601, 283401,
    330409, 383041, 441729, 506921, 579081, 658689, 746241, 842249, 947241,
    1061761, 1186369, 1321641, 1468169, 1626561, 1797441, 1981449, 2179241,
    2391489, 2618881, 2862121, 3121929, 3399041, 3694209, 4008201, 4341801,
    4695809, 5071041, 5468329, 5888521, 6332481, 6801089, 7295241, 7815849,
    8363841, 8940161, 9545769, 10181641, 10848769, 11548161, 12280841, 13047849,
    13850241, 14689089, 15565481, 16480521, 17435329, 18431041, 19468809,
    20549801, 21675201, 22846209, 24064041, 25329929, 26645121, 28010881,
    29428489, 30899241, 32424449, 34005441, 35643561, 37340169, 39096641,
    40914369, 42794761, 44739241, 46749249, 48826241, 50971689, 53187081,
    55473921, 57833729, 60268041, 62778409, 65366401, 68033601, 70781609,
    73612041, 76526529, 79526721, 82614281, 85790889, 89058241, 92418049,
    95872041, 99421961, 103069569, 106816641, 110664969, 114616361, 118672641,
    122835649, 127107241, 131489289, 135983681, 140592321, 145317129, 150160041,
    155123009, 160208001, 165417001, 170752009, 176215041, 181808129, 187533321,
    193392681, 199388289, 205522241, 211796649, 218213641, 224775361, 231483969,
    238341641, 245350569, 252512961, 259831041, 267307049, 274943241, 282741889,
    290705281, 298835721, 307135529, 315607041, 324252609, 333074601, 342075401,
    351257409, 360623041, 370174729, 379914921, 389846081, 399970689, 410291241,
    420810249, 431530241, 442453761, 453583369, 464921641, 476471169, 488234561,
    500214441, 512413449, 524834241, 537479489, 550351881, 563454121, 576788929,
    590359041, 604167209, 618216201, 632508801,
    /* N = 6, K = 6...96 (technically V(109,5) fits in 32 bits, but that can't be
     achieved by splitting an Opus band) */
    1683, 3653, 7183, 13073, 22363, 36365, 56695, 85305, 124515, 177045, 246047,
    335137, 448427, 590557, 766727, 982729, 1244979, 1560549, 1937199, 2383409,
    2908411, 3522221, 4235671, 5060441, 6009091, 7095093, 8332863, 9737793,
    11326283, 13115773, 15124775, 17372905, 19880915, 22670725, 25765455,
    29189457, 32968347, 37129037, 41699767, 46710137, 52191139, 58175189,
    64696159, 71789409, 79491819, 87841821, 96879431, 106646281, 117185651,
    128542501, 140763503, 153897073, 167993403, 183104493, 199284183, 216588185,
    235074115, 254801525, 275831935, 298228865, 322057867, 347386557, 374284647,
    402823977, 433078547, 465124549, 499040399, 534906769, 572806619, 612825229,
    655050231, 699571641, 746481891, 795875861, 847850911, 902506913, 959946283,
    1020274013, 1083597703, 1150027593, 1219676595, 1292660325, 1369097135,
    1449108145, 1532817275, 1620351277, 1711839767, 1807415257, 1907213187,
    2011371957, 2120032959,
    /* N = 7, K = 7...54 (technically V(60,6) fits in 32 bits, but that can't be
     achieved by splitting an Opus band) */
    8989, 19825, 40081, 75517, 134245, 227305, 369305, 579125, 880685, 1303777,
    1884961, 2668525, 3707509, 5064793, 6814249, 9041957, 11847485, 15345233,
    19665841, 24957661, 31388293, 39146185, 48442297, 59511829, 72616013,
    88043969, 106114625, 127178701, 151620757, 179861305, 212358985, 249612805,
    292164445, 340600625, 395555537, 457713341, 527810725, 606639529, 695049433,
    793950709, 904317037, 1027188385, 1163673953, 1314955181, 1482288821,
    1667010073, 1870535785, 2094367717,
    /* N = 8, K = 8...37 (technically V(40,7) fits in 32 bits, but that can't be
     achieved by splitting an Opus band) */
    48639, 108545, 224143, 433905, 795455, 1392065, 2340495, 3800305, 5984767,
    9173505, 13726991, 20103025, 28875327, 40754369, 56610575, 77500017,
    104692735, 139703809, 184327311, 240673265, 311207743, 398796225, 506750351,
    638878193, 799538175, 993696769, 1226990095, 1505789553, 1837271615,
    2229491905,
    /* N = 9, K = 9...28 (technically V(29,8) fits in 32 bits, but that can't be
     achieved by splitting an Opus band) */
    265729, 598417, 1256465, 2485825, 4673345, 8405905, 14546705, 24331777,
    39490049, 62390545, 96220561, 145198913, 214828609, 312193553, 446304145,
    628496897, 872893441, 1196924561, 1621925137, 2173806145,
    /* N = 10, K = 10...24 */
    1462563, 3317445, 7059735, 14218905, 27298155, 50250765, 89129247, 152951073,
    254831667, 413442773, 654862247, 1014889769, 1541911931, 2300409629,
    3375210671,
    /* N = 11, K = 11...19 (technically V(20,10) fits in 32 bits, but that can't be
     achieved by splitting an Opus band) */
    8097453, 18474633, 39753273, 81270333, 158819253, 298199265, 540279585,
    948062325, 1616336765,
    /* N = 12, K = 12...18 */
    45046719, 103274625, 224298231, 464387817, 921406335, 1759885185,
    3248227095,
    /* N = 13, K = 13...16 */
    251595969, 579168825, 1267854873, 2653649025,
    /* N = 14, K = 14 */
    1409933619
];

//DECLARE_ALIGNED(32, static immutable float, celt_window)[120] = [
static immutable float[120] celt_window = [
    6.7286966e-05f, 0.00060551348f, 0.0016815970f, 0.0032947962f, 0.0054439943f,
    0.0081276923f, 0.011344001f, 0.015090633f, 0.019364886f, 0.024163635f,
    0.029483315f, 0.035319905f, 0.041668911f, 0.048525347f, 0.055883718f,
    0.063737999f, 0.072081616f, 0.080907428f, 0.090207705f, 0.099974111f,
    0.11019769f, 0.12086883f, 0.13197729f, 0.14351214f, 0.15546177f,
    0.16781389f, 0.18055550f, 0.19367290f, 0.20715171f, 0.22097682f,
    0.23513243f, 0.24960208f, 0.26436860f, 0.27941419f, 0.29472040f,
    0.31026818f, 0.32603788f, 0.34200931f, 0.35816177f, 0.37447407f,
    0.39092462f, 0.40749142f, 0.42415215f, 0.44088423f, 0.45766484f,
    0.47447104f, 0.49127978f, 0.50806798f, 0.52481261f, 0.54149077f,
    0.55807973f, 0.57455701f, 0.59090049f, 0.60708841f, 0.62309951f,
    0.63891306f, 0.65450896f, 0.66986776f, 0.68497077f, 0.69980010f,
    0.71433873f, 0.72857055f, 0.74248043f, 0.75605424f, 0.76927895f,
    0.78214257f, 0.79463430f, 0.80674445f, 0.81846456f, 0.82978733f,
    0.84070669f, 0.85121779f, 0.86131698f, 0.87100183f, 0.88027111f,
    0.88912479f, 0.89756398f, 0.90559094f, 0.91320904f, 0.92042270f,
    0.92723738f, 0.93365955f, 0.93969656f, 0.94535671f, 0.95064907f,
    0.95558353f, 0.96017067f, 0.96442171f, 0.96834849f, 0.97196334f,
    0.97527906f, 0.97830883f, 0.98106616f, 0.98356480f, 0.98581869f,
    0.98784191f, 0.98964856f, 0.99125274f, 0.99266849f, 0.99390969f,
    0.99499004f, 0.99592297f, 0.99672162f, 0.99739874f, 0.99796667f,
    0.99843728f, 0.99882195f, 0.99913147f, 0.99937606f, 0.99956527f,
    0.99970802f, 0.99981248f, 0.99988613f, 0.99993565f, 0.99996697f,
    0.99998518f, 0.99999457f, 0.99999859f, 0.99999982f, 1.0000000f,
];

/* square of the window, used for the postfilter */
static immutable float[120] ff_celt_window2 = [
    4.5275357e-09f, 3.66647e-07f, 2.82777e-06f, 1.08557e-05f, 2.96371e-05f, 6.60594e-05f,
    0.000128686f, 0.000227727f, 0.000374999f, 0.000583881f, 0.000869266f, 0.0012475f,
    0.0017363f, 0.00235471f, 0.00312299f, 0.00406253f, 0.00519576f, 0.00654601f,
    0.00813743f, 0.00999482f, 0.0121435f, 0.0146093f, 0.017418f, 0.0205957f, 0.0241684f,
    0.0281615f, 0.0326003f, 0.0375092f, 0.0429118f, 0.0488308f, 0.0552873f, 0.0623012f,
    0.0698908f, 0.0780723f, 0.0868601f, 0.0962664f, 0.106301f, 0.11697f, 0.12828f,
    0.140231f, 0.152822f, 0.166049f, 0.179905f, 0.194379f, 0.209457f, 0.225123f, 0.241356f,
    0.258133f, 0.275428f, 0.293212f, 0.311453f, 0.330116f, 0.349163f, 0.368556f, 0.388253f,
    0.40821f, 0.428382f, 0.448723f, 0.469185f, 0.48972f, 0.51028f, 0.530815f, 0.551277f,
    0.571618f, 0.59179f, 0.611747f, 0.631444f, 0.650837f, 0.669884f, 0.688547f, 0.706788f,
    0.724572f, 0.741867f, 0.758644f, 0.774877f, 0.790543f, 0.805621f, 0.820095f, 0.833951f,
    0.847178f, 0.859769f, 0.87172f, 0.88303f, 0.893699f, 0.903734f, 0.91314f, 0.921928f,
    0.930109f, 0.937699f, 0.944713f, 0.951169f, 0.957088f, 0.962491f, 0.9674f, 0.971838f,
    0.975832f, 0.979404f, 0.982582f, 0.985391f, 0.987857f, 0.990005f, 0.991863f, 0.993454f,
    0.994804f, 0.995937f, 0.996877f, 0.997645f, 0.998264f, 0.998753f, 0.999131f, 0.999416f,
    0.999625f, 0.999772f, 0.999871f, 0.999934f, 0.99997f, 0.999989f, 0.999997f, 0.99999964f, 1.0f,
];

static immutable uint32_t*[15] celt_pvq_u_row = [
    celt_pvq_u.ptr +    0, celt_pvq_u.ptr +  176, celt_pvq_u.ptr +  351,
    celt_pvq_u.ptr +  525, celt_pvq_u.ptr +  698, celt_pvq_u.ptr +  870,
    celt_pvq_u.ptr + 1041, celt_pvq_u.ptr + 1131, celt_pvq_u.ptr + 1178,
    celt_pvq_u.ptr + 1207, celt_pvq_u.ptr + 1226, celt_pvq_u.ptr + 1240,
    celt_pvq_u.ptr + 1248, celt_pvq_u.ptr + 1254, celt_pvq_u.ptr + 1257
];

/*static inline*/ int16_t celt_cos(int16_t x)
{
    x = cast(short)((MUL16(x, x) + 4096) >> 13);
    x = cast(short)((32767-x) + ROUND_MUL16(x, (-7651 + ROUND_MUL16(x, (8277 + ROUND_MUL16(-626, x))))));
    return cast(short)(1+x);
}

/*static inline*/ int celt_log2tan(int isin, int icos)
{
    int lc, ls;
    lc = opus_ilog(icos);
    ls = opus_ilog(isin);
    icos <<= 15 - lc;
    isin <<= 15 - ls;
    return (ls << 11) - (lc << 11) +
           ROUND_MUL16(isin, ROUND_MUL16(isin, -2597) + 7932) -
           ROUND_MUL16(icos, ROUND_MUL16(icos, -2597) + 7932);
}

/*static inline*/ uint32_t celt_rng(CeltContext *s)
{
    s.seed = 1664525 * s.seed + 1013904223;
    return s.seed;
}

private void celt_decode_coarse_energy(CeltContext *s, OpusRangeCoder *rc)
{
    int i, j;
    float[2] prev = 0;
    float alpha, beta;
    const(uint8_t)* model;

    /* use the 2D z-transform to apply prediction in both */
    /* the time domain (alpha) and the frequency domain (beta) */

    if (opus_rc_tell(rc)+3 <= s.framebits && opus_rc_p2model(rc, 3)) {
        /* intra frame */
        alpha = 0;
        beta  = 1.0f - 4915.0f/32768.0f;
        model = celt_coarse_energy_dist[s.duration][1].ptr;
    } else {
        alpha = celt_alpha_coef[s.duration];
        beta  = 1.0f - celt_beta_coef[s.duration];
        model = celt_coarse_energy_dist[s.duration][0].ptr;
    }

    for (i = 0; i < CELT_MAX_BANDS; i++) {
        for (j = 0; j < s.coded_channels; j++) {
            CeltFrame *frame = &s.frame[j];
            float value;
            int available;

            if (i < s.startband || i >= s.endband) {
                frame.energy[i] = 0.0;
                continue;
            }

            available = s.framebits - opus_rc_tell(rc);
            if (available >= 15) {
                /* decode using a Laplace distribution */
                int k = FFMIN(i, 20) << 1;
                value = opus_rc_laplace(rc, model[k] << 7, model[k+1] << 6);
            } else if (available >= 2) {
                int x = opus_rc_getsymbol(rc, celt_model_energy_small.ptr);
                value = (x>>1) ^ -(x&1);
            } else if (available >= 1) {
                value = -cast(float)opus_rc_p2model(rc, 1);
            } else value = -1;

            frame.energy[i] = FFMAX(-9.0f, frame.energy[i]) * alpha + prev[j] + value;
            prev[j] += beta * value;
        }
    }
}

private void celt_decode_fine_energy(CeltContext *s, OpusRangeCoder *rc)
{
    int i;
    for (i = s.startband; i < s.endband; i++) {
        int j;
        if (!s.fine_bits[i])
            continue;

        for (j = 0; j < s.coded_channels; j++) {
            CeltFrame *frame = &s.frame[j];
            int q2;
            float offset;
            q2 = opus_getrawbits(rc, s.fine_bits[i]);
            offset = (q2 + 0.5f) * (1 << (14 - s.fine_bits[i])) / 16384.0f - 0.5f;
            frame.energy[i] += offset;
        }
    }
}

private void celt_decode_final_energy(CeltContext *s, OpusRangeCoder *rc, int bits_left)
{
    int priority, i, j;

    for (priority = 0; priority < 2; priority++) {
        for (i = s.startband; i < s.endband && bits_left >= s.coded_channels; i++) {
            if (s.fine_priority[i] != priority || s.fine_bits[i] >= CELT_MAX_FINE_BITS)
                continue;

            for (j = 0; j < s.coded_channels; j++) {
                int q2;
                float offset;
                q2 = opus_getrawbits(rc, 1);
                offset = (q2 - 0.5f) * (1 << (14 - s.fine_bits[i] - 1)) / 16384.0f;
                s.frame[j].energy[i] += offset;
                bits_left--;
            }
        }
    }
}

private void celt_decode_tf_changes(CeltContext *s, OpusRangeCoder *rc, int transient)
{
    int i, diff = 0, tf_select = 0, tf_changed = 0, tf_select_bit;
    int consumed, bits = transient ? 2 : 4;

    consumed = opus_rc_tell(rc);
    tf_select_bit = (s.duration != 0 && consumed+bits+1 <= s.framebits);

    for (i = s.startband; i < s.endband; i++) {
        if (consumed+bits+tf_select_bit <= s.framebits) {
            diff ^= opus_rc_p2model(rc, bits);
            consumed = opus_rc_tell(rc);
            tf_changed |= diff;
        }
        s.tf_change[i] = diff;
        bits = transient ? 4 : 5;
    }

    if (tf_select_bit && celt_tf_select[s.duration][transient][0][tf_changed] !=
                         celt_tf_select[s.duration][transient][1][tf_changed])
        tf_select = opus_rc_p2model(rc, 1);

    for (i = s.startband; i < s.endband; i++) {
        s.tf_change[i] = celt_tf_select[s.duration][transient][tf_select][s.tf_change[i]];
    }
}

private void celt_decode_allocation(CeltContext *s, OpusRangeCoder *rc)
{
    // approx. maximum bit allocation for each band before boost/trim
    int[CELT_MAX_BANDS] cap;
    int[CELT_MAX_BANDS] boost;
    int[CELT_MAX_BANDS] threshold;
    int[CELT_MAX_BANDS] bits1;
    int[CELT_MAX_BANDS] bits2;
    int[CELT_MAX_BANDS] trim_offset;

    int skip_startband = s.startband;
    int dynalloc       = 6;
    int alloctrim      = 5;
    int extrabits      = 0;

    int skip_bit            = 0;
    int intensitystereo_bit = 0;
    int dualstereo_bit      = 0;

    int remaining, bandbits;
    int low, high, total, done;
    int totalbits;
    int consumed;
    int i, j;

    consumed = opus_rc_tell(rc);

    /* obtain spread flag */
    s.spread = CELT_SPREAD_NORMAL;
    if (consumed + 4 <= s.framebits)
        s.spread = opus_rc_getsymbol(rc, celt_model_spread.ptr);

    /* generate static allocation caps */
    for (i = 0; i < CELT_MAX_BANDS; i++) {
        cap[i] = (celt_static_caps[s.duration][s.coded_channels - 1][i] + 64)
                 * celt_freq_range[i] << (s.coded_channels - 1) << s.duration >> 2;
    }

    /* obtain band boost */
    totalbits = s.framebits << 3; // convert to 1/8 bits
    consumed = opus_rc_tell_frac(rc);
    for (i = s.startband; i < s.endband; i++) {
        int quanta, band_dynalloc;

        boost[i] = 0;

        quanta = celt_freq_range[i] << (s.coded_channels - 1) << s.duration;
        quanta = FFMIN(quanta << 3, FFMAX(6 << 3, quanta));
        band_dynalloc = dynalloc;
        while (consumed + (band_dynalloc<<3) < totalbits && boost[i] < cap[i]) {
            int add = opus_rc_p2model(rc, band_dynalloc);
            consumed = opus_rc_tell_frac(rc);
            if (!add)
                break;

            boost[i]     += quanta;
            totalbits    -= quanta;
            band_dynalloc = 1;
        }
        /* dynalloc is more likely to occur if it's already been used for earlier bands */
        if (boost[i])
            dynalloc = FFMAX(2, dynalloc - 1);
    }

    /* obtain allocation trim */
    if (consumed + (6 << 3) <= totalbits)
        alloctrim = opus_rc_getsymbol(rc, celt_model_alloc_trim.ptr);

    /* anti-collapse bit reservation */
    totalbits = (s.framebits << 3) - opus_rc_tell_frac(rc) - 1;
    s.anticollapse_bit = 0;
    if (s.blocks > 1 && s.duration >= 2 &&
        totalbits >= ((s.duration + 2) << 3))
        s.anticollapse_bit = 1 << 3;
    totalbits -= s.anticollapse_bit;

    /* band skip bit reservation */
    if (totalbits >= 1 << 3)
        skip_bit = 1 << 3;
    totalbits -= skip_bit;

    /* intensity/dual stereo bit reservation */
    if (s.coded_channels == 2) {
        intensitystereo_bit = celt_log2_frac[s.endband - s.startband];
        if (intensitystereo_bit <= totalbits) {
            totalbits -= intensitystereo_bit;
            if (totalbits >= 1 << 3) {
                dualstereo_bit = 1 << 3;
                totalbits -= 1 << 3;
            }
        } else
            intensitystereo_bit = 0;
    }

    for (i = s.startband; i < s.endband; i++) {
        int trim     = alloctrim - 5 - s.duration;
        int band     = celt_freq_range[i] * (s.endband - i - 1);
        int duration = s.duration + 3;
        int scale    = duration + s.coded_channels - 1;

        /* PVQ minimum allocation threshold, below this value the band is
         * skipped */
        threshold[i] = FFMAX(3 * celt_freq_range[i] << duration >> 4,
                             s.coded_channels << 3);

        trim_offset[i] = trim * (band << scale) >> 6;

        if (celt_freq_range[i] << s.duration == 1)
            trim_offset[i] -= s.coded_channels << 3;
    }

    /* bisection */
    low  = 1;
    high = CELT_VECTORS - 1;
    while (low <= high) {
        int center = (low + high) >> 1;
        done = total = 0;

        for (i = s.endband - 1; i >= s.startband; i--) {
            bandbits = celt_freq_range[i] * celt_static_alloc[center][i]
                       << (s.coded_channels - 1) << s.duration >> 2;

            if (bandbits)
                bandbits = FFMAX(0, bandbits + trim_offset[i]);
            bandbits += boost[i];

            if (bandbits >= threshold[i] || done) {
                done = 1;
                total += FFMIN(bandbits, cap[i]);
            } else if (bandbits >= s.coded_channels << 3)
                total += s.coded_channels << 3;
        }

        if (total > totalbits)
            high = center - 1;
        else
            low = center + 1;
    }
    high = low--;

    for (i = s.startband; i < s.endband; i++) {
        bits1[i] = celt_freq_range[i] * celt_static_alloc[low][i]
                   << (s.coded_channels - 1) << s.duration >> 2;
        bits2[i] = high >= CELT_VECTORS ? cap[i] :
                   celt_freq_range[i] * celt_static_alloc[high][i]
                   << (s.coded_channels - 1) << s.duration >> 2;

        if (bits1[i])
            bits1[i] = FFMAX(0, bits1[i] + trim_offset[i]);
        if (bits2[i])
            bits2[i] = FFMAX(0, bits2[i] + trim_offset[i]);
        if (low)
            bits1[i] += boost[i];
        bits2[i] += boost[i];

        if (boost[i])
            skip_startband = i;
        bits2[i] = FFMAX(0, bits2[i] - bits1[i]);
    }

    /* bisection */
    low  = 0;
    high = 1 << CELT_ALLOC_STEPS;
    for (i = 0; i < CELT_ALLOC_STEPS; i++) {
        int center = (low + high) >> 1;
        done = total = 0;

        for (j = s.endband - 1; j >= s.startband; j--) {
            bandbits = bits1[j] + (center * bits2[j] >> CELT_ALLOC_STEPS);

            if (bandbits >= threshold[j] || done) {
                done = 1;
                total += FFMIN(bandbits, cap[j]);
            } else if (bandbits >= s.coded_channels << 3)
                total += s.coded_channels << 3;
        }
        if (total > totalbits)
            high = center;
        else
            low = center;
    }

    done = total = 0;
    for (i = s.endband - 1; i >= s.startband; i--) {
        bandbits = bits1[i] + (low * bits2[i] >> CELT_ALLOC_STEPS);

        if (bandbits >= threshold[i] || done)
            done = 1;
        else
            bandbits = (bandbits >= s.coded_channels << 3) ?
                       s.coded_channels << 3 : 0;

        bandbits     = FFMIN(bandbits, cap[i]);
        s.pulses[i] = bandbits;
        total      += bandbits;
    }

    /* band skipping */
    for (s.codedbands = s.endband; ; s.codedbands--) {
        int allocation;
        j = s.codedbands - 1;

        if (j == skip_startband) {
            /* all remaining bands are not skipped */
            totalbits += skip_bit;
            break;
        }

        /* determine the number of bits available for coding "do not skip" markers */
        remaining   = totalbits - total;
        bandbits    = remaining / (celt_freq_bands[j+1] - celt_freq_bands[s.startband]);
        remaining  -= bandbits  * (celt_freq_bands[j+1] - celt_freq_bands[s.startband]);
        allocation  = s.pulses[j] + bandbits * celt_freq_range[j]
                      + FFMAX(0, remaining - (celt_freq_bands[j] - celt_freq_bands[s.startband]));

        /* a "do not skip" marker is only coded if the allocation is
           above the chosen threshold */
        if (allocation >= FFMAX(threshold[j], (s.coded_channels + 1) <<3 )) {
            if (opus_rc_p2model(rc, 1))
                break;

            total      += 1 << 3;
            allocation -= 1 << 3;
        }

        /* the band is skipped, so reclaim its bits */
        total -= s.pulses[j];
        if (intensitystereo_bit) {
            total -= intensitystereo_bit;
            intensitystereo_bit = celt_log2_frac[j - s.startband];
            total += intensitystereo_bit;
        }

        total += s.pulses[j] = (allocation >= s.coded_channels << 3) ?
                              s.coded_channels << 3 : 0;
    }

    /* obtain stereo flags */
    s.intensitystereo = 0;
    s.dualstereo      = 0;
    if (intensitystereo_bit)
        s.intensitystereo = s.startband +
                          opus_rc_unimodel(rc, s.codedbands + 1 - s.startband);
    if (s.intensitystereo <= s.startband)
        totalbits += dualstereo_bit; /* no intensity stereo means no dual stereo */
    else if (dualstereo_bit)
        s.dualstereo = opus_rc_p2model(rc, 1);

    /* supply the remaining bits in this frame to lower bands */
    remaining = totalbits - total;
    bandbits  = remaining / (celt_freq_bands[s.codedbands] - celt_freq_bands[s.startband]);
    remaining -= bandbits * (celt_freq_bands[s.codedbands] - celt_freq_bands[s.startband]);
    for (i = s.startband; i < s.codedbands; i++) {
        int bits = FFMIN(remaining, celt_freq_range[i]);

        s.pulses[i] += bits + bandbits * celt_freq_range[i];
        remaining    -= bits;
    }

    for (i = s.startband; i < s.codedbands; i++) {
        int N = celt_freq_range[i] << s.duration;
        int prev_extra = extrabits;
        s.pulses[i] += extrabits;

        if (N > 1) {
            int dof;        // degrees of freedom
            int temp;       // dof * channels * log(dof)
            int offset;     // fine energy quantization offset, i.e.
                            // extra bits assigned over the standard
                            // totalbits/dof
            int fine_bits, max_bits;

            extrabits = FFMAX(0, s.pulses[i] - cap[i]);
            s.pulses[i] -= extrabits;

            /* intensity stereo makes use of an extra degree of freedom */
            dof = N * s.coded_channels
                  + (s.coded_channels == 2 && N > 2 && !s.dualstereo && i < s.intensitystereo);
            temp = dof * (celt_log_freq_range[i] + (s.duration<<3));
            offset = (temp >> 1) - dof * CELT_FINE_OFFSET;
            if (N == 2) /* dof=2 is the only case that doesn't fit the model */
                offset += dof<<1;

            /* grant an additional bias for the first and second pulses */
            if (s.pulses[i] + offset < 2 * (dof << 3))
                offset += temp >> 2;
            else if (s.pulses[i] + offset < 3 * (dof << 3))
                offset += temp >> 3;

            fine_bits = (s.pulses[i] + offset + (dof << 2)) / (dof << 3);
            max_bits  = FFMIN((s.pulses[i]>>3) >> (s.coded_channels - 1),
                              CELT_MAX_FINE_BITS);

            max_bits  = FFMAX(max_bits, 0);

            s.fine_bits[i] = av_clip(fine_bits, 0, max_bits);

            /* if fine_bits was rounded down or capped,
               give priority for the final fine energy pass */
            s.fine_priority[i] = (s.fine_bits[i] * (dof<<3) >= s.pulses[i] + offset);

            /* the remaining bits are assigned to PVQ */
            s.pulses[i] -= s.fine_bits[i] << (s.coded_channels - 1) << 3;
        } else {
            /* all bits go to fine energy except for the sign bit */
            extrabits = FFMAX(0, s.pulses[i] - (s.coded_channels << 3));
            s.pulses[i] -= extrabits;
            s.fine_bits[i] = 0;
            s.fine_priority[i] = 1;
        }

        /* hand back a limited number of extra fine energy bits to this band */
        if (extrabits > 0) {
            int fineextra = FFMIN(extrabits >> (s.coded_channels + 2),
                                  CELT_MAX_FINE_BITS - s.fine_bits[i]);
            s.fine_bits[i] += fineextra;

            fineextra <<= s.coded_channels + 2;
            s.fine_priority[i] = (fineextra >= extrabits - prev_extra);
            extrabits -= fineextra;
        }
    }
    s.remaining = extrabits;

    /* skipped bands dedicate all of their bits for fine energy */
    for (; i < s.endband; i++) {
        s.fine_bits[i]     = s.pulses[i] >> (s.coded_channels - 1) >> 3;
        s.pulses[i]        = 0;
        s.fine_priority[i] = s.fine_bits[i] < 1;
    }
}

/*static inline*/ int celt_bits2pulses(const(uint8_t)* cache, int bits)
{
    // TODO: Find the size of cache and make it into an array in the parameters list
    int i, low = 0, high;

    high = cache[0];
    bits--;

    for (i = 0; i < 6; i++) {
        int center = (low + high + 1) >> 1;
        if (cache[center] >= bits)
            high = center;
        else
            low = center;
    }

    return (bits - (low == 0 ? -1 : cache[low]) <= cache[high] - bits) ? low : high;
}

/*static inline*/ int celt_pulses2bits(const(uint8_t)* cache, int pulses)
{
    // TODO: Find the size of cache and make it into an array in the parameters list
   return (pulses == 0) ? 0 : cache[pulses] + 1;
}

/*static inline*/ void celt_normalize_residual(const(int)* /*av_restrict*/ iy, float * /*av_restrict*/ X, int N, float g)
{
    int i;
    for (i = 0; i < N; i++)
        X[i] = g * iy[i];
}

private void celt_exp_rotation1(float *X, uint len, uint stride, float c, float s)
{
    float *Xptr;
    int i;

    Xptr = X;
    for (i = 0; i < len - stride; i++) {
        float x1, x2;
        x1           = Xptr[0];
        x2           = Xptr[stride];
        Xptr[stride] = c * x2 + s * x1;
        *Xptr++      = c * x1 - s * x2;
    }

    Xptr = &X[len - 2 * stride - 1];
    for (i = len - 2 * stride - 1; i >= 0; i--) {
        float x1, x2;
        x1           = Xptr[0];
        x2           = Xptr[stride];
        Xptr[stride] = c * x2 + s * x1;
        *Xptr--      = c * x1 - s * x2;
    }
}

/*static inline*/ void celt_exp_rotation(float *X, uint len, uint stride, uint K, CeltSpread spread)
{
    import std.math : PI, cos, sin;
    uint stride2 = 0;
    float c, s;
    float gain, theta;
    int i;

    if (2*K >= len || spread == CELT_SPREAD_NONE)
        return;

    gain = cast(float)len / (len + (20 - 5*spread) * K);
    theta = PI * gain * gain / 4;

    c = cos(theta);
    s = sin(theta);

    if (len >= stride << 3) {
        stride2 = 1;
        /* This is just a simple (equivalent) way of computing sqrt(len/stride) with rounding.
        It's basically incrementing long as (stride2+0.5)^2 < len/stride. */
        while ((stride2 * stride2 + stride2) * stride + (stride >> 2) < len)
            stride2++;
    }

    /*NOTE: As a minor optimization, we could be passing around log2(B), not B, for both this and for
    extract_collapse_mask().*/
    len /= stride;
    for (i = 0; i < stride; i++) {
        if (stride2)
            celt_exp_rotation1(X + i * len, len, stride2, s, c);
        celt_exp_rotation1(X + i * len, len, 1, c, s);
    }
}

/*static inline*/ uint celt_extract_collapse_mask(const(int)* iy, uint N, uint B)
{
    uint collapse_mask;
    int N0;
    int i, j;

    if (B <= 1)
        return 1;

    /*NOTE: As a minor optimization, we could be passing around log2(B), not B, for both this and for
    exp_rotation().*/
    N0 = N/B;
    collapse_mask = 0;
    for (i = 0; i < B; i++)
        for (j = 0; j < N0; j++)
            collapse_mask |= (iy[i*N0+j]!=0)<<i;
    return collapse_mask;
}

/*static inline*/ void celt_renormalize_vector(float *X, int N, float gain)
{
    import core.stdc.math : sqrtf;
    int i;
    float g = 1e-15f;
    for (i = 0; i < N; i++)
        g += X[i] * X[i];
    g = gain / sqrtf(g);

    for (i = 0; i < N; i++)
        X[i] *= g;
}

/*static inline*/ void celt_stereo_merge(float *X, float *Y, float mid, int N)
{
    import core.stdc.math : sqrtf;
    int i;
    float xp = 0, side = 0;
    float[2] E;
    float mid2;
    float t;
    float[2] gain;

    /* Compute the norm of X+Y and X-Y as |X|^2 + |Y|^2 +/- sum(xy) */
    for (i = 0; i < N; i++) {
        xp   += X[i] * Y[i];
        side += Y[i] * Y[i];
    }

    /* Compensating for the mid normalization */
    xp *= mid;
    mid2 = mid;
    E[0] = mid2 * mid2 + side - 2 * xp;
    E[1] = mid2 * mid2 + side + 2 * xp;
    if (E[0] < 6e-4f || E[1] < 6e-4f) {
        for (i = 0; i < N; i++)
            Y[i] = X[i];
        return;
    }

    t = E[0];
    gain[0] = 1.0f / sqrtf(t);
    t = E[1];
    gain[1] = 1.0f / sqrtf(t);

    for (i = 0; i < N; i++) {
        float[2] value = void;
        /* Apply mid scaling (side is already scaled) */
        value[0] = mid * X[i];
        value[1] = Y[i];
        X[i] = gain[0] * (value[0] - value[1]);
        Y[i] = gain[1] * (value[0] + value[1]);
    }
}

private void celt_interleave_hadamard (float *tmp, float *X, int N0, int stride, int hadamard)
{
    int i, j;
    int N = N0*stride;

    if (hadamard) {
        const(uint8_t)* ordery = celt_hadamard_ordery.ptr + stride - 2;
        for (i = 0; i < stride; i++)
            for (j = 0; j < N0; j++)
                tmp[j*stride+i] = X[ordery[i]*N0+j];
    } else {
        for (i = 0; i < stride; i++)
            for (j = 0; j < N0; j++)
                tmp[j*stride+i] = X[i*N0+j];
    }

    for (i = 0; i < N; i++)
        X[i] = tmp[i];
}

private void celt_deinterleave_hadamard (float *tmp, float *X, int N0, int stride, int hadamard)
{
    int i, j;
    int N = N0*stride;

    if (hadamard) {
        const(uint8_t)* ordery = celt_hadamard_ordery.ptr + stride - 2;
        for (i = 0; i < stride; i++)
            for (j = 0; j < N0; j++)
                tmp[ordery[i]*N0+j] = X[j*stride+i];
    } else {
        for (i = 0; i < stride; i++)
            for (j = 0; j < N0; j++)
                tmp[i*N0+j] = X[j*stride+i];
    }

    for (i = 0; i < N; i++)
        X[i] = tmp[i];
}

private void celt_haar1(float *X, int N0, int stride)
{
    int i, j;
    N0 >>= 1;
    for (i = 0; i < stride; i++) {
        for (j = 0; j < N0; j++) {
            float x0 = X[stride * (2 * j + 0) + i];
            float x1 = X[stride * (2 * j + 1) + i];
            X[stride * (2 * j + 0) + i] = (x0 + x1) * M_SQRT1_2;
            X[stride * (2 * j + 1) + i] = (x0 - x1) * M_SQRT1_2;
        }
    }
}

/*static inline*/ int celt_compute_qn(int N, int b, int offset, int pulse_cap, int dualstereo)
{
    int qn, qb;
    int N2 = 2 * N - 1;
    if (dualstereo && N == 2)
        N2--;

    /* The upper limit ensures that in a stereo split with itheta==16384, we'll
     * always have enough bits left over to code at least one pulse in the
     * side; otherwise it would collapse, since it doesn't get folded. */
    qb = FFMIN3(b - pulse_cap - (4 << 3), (b + N2 * offset) / N2, 8 << 3);
    qn = (qb < (1 << 3 >> 1)) ? 1 : ((celt_qn_exp2[qb & 0x7] >> (14 - (qb >> 3))) + 1) >> 1 << 1;
    return qn;
}

// this code was adapted from libopus
/*static inline*/ uint64_t celt_cwrsi(uint N, uint K, uint i, int *y)
{
    uint64_t norm = 0;
    uint32_t p;
    int s, val;
    int k0;

    while (N > 2) {
        uint32_t q;

        /*Lots of pulses case:*/
        if (K >= N) {
            const uint32_t *row = celt_pvq_u_row[N];

            /* Are the pulses in this dimension negative? */
            p  = row[K + 1];
            s  = -(i >= p ? 1 : 0);
            i -= p & s;

            /*Count how many pulses were placed in this dimension.*/
            k0 = K;
            q = row[N];
            if (q > i) {
                K = N;
                do {
                    p = celt_pvq_u_row[--K][N];
                } while (p > i);
            } else
                for (p = row[K]; p > i; p = row[K])
                    K--;

            i    -= p;
            val   = (k0 - K + s) ^ s;
            norm += val * val;
            *y++  = val;
        } else { /*Lots of dimensions case:*/
            /*Are there any pulses in this dimension at all?*/
            p = celt_pvq_u_row[K    ][N];
            q = celt_pvq_u_row[K + 1][N];

            if (p <= i && i < q) {
                i -= p;
                *y++ = 0;
            } else {
                /*Are the pulses in this dimension negative?*/
                s  = -(i >= q ? 1 : 0);
                i -= q & s;

                /*Count how many pulses were placed in this dimension.*/
                k0 = K;
                do p = celt_pvq_u_row[--K][N];
                while (p > i);

                i    -= p;
                val   = (k0 - K + s) ^ s;
                norm += val * val;
                *y++  = val;
            }
        }
        N--;
    }

    /* N == 2 */
    p  = 2 * K + 1;
    s  = -(i >= p ? 1 : 0);
    i -= p & s;
    k0 = K;
    K  = (i + 1) / 2;

    if (K)
        i -= 2 * K - 1;

    val   = (k0 - K + s) ^ s;
    norm += val * val;
    *y++  = val;

    /* N==1 */
    s     = -i;
    val   = (K + s) ^ s;
    norm += val * val;
    *y    = val;

    return norm;
}

/*static inline*/ float celt_decode_pulses(OpusRangeCoder *rc, int *y, uint N, uint K) {
    uint idx;
    //#define CELT_PVQ_U(n, k) (celt_pvq_u_row[FFMIN(n, k)][FFMAX(n, k)])
    //#define CELT_PVQ_V(n, k) (CELT_PVQ_U(n, k) + CELT_PVQ_U(n, (k) + 1))
    enum CELT_PVQ_U(string n, string k) = "(celt_pvq_u_row[FFMIN("~n~", "~k~")][FFMAX("~n~", "~k~")])";
    enum CELT_PVQ_V(string n, string k) = "("~CELT_PVQ_U!(n, k)~" + "~CELT_PVQ_U!(n, "("~k~") + 1")~")";
    idx = opus_rc_unimodel(rc, mixin(CELT_PVQ_V!("N", "K")));
    return celt_cwrsi(N, K, idx, y);
}

/** Decode pulse vector and combine the result with the pitch vector to produce
    the final normalised signal in the current band. */
/*static inline*/ uint celt_alg_unquant(OpusRangeCoder *rc, float *X, uint N, uint K, CeltSpread spread, uint blocks, float gain)
{
    import core.stdc.math : sqrtf;
    int[176] y = void;

    gain /= sqrtf(celt_decode_pulses(rc, y.ptr, N, K));
    celt_normalize_residual(y.ptr, X, N, gain);
    celt_exp_rotation(X, N, blocks, K, spread);
    return celt_extract_collapse_mask(y.ptr, N, blocks);
}

/*static unsigned*/ int celt_decode_band(CeltContext *s, OpusRangeCoder *rc,
                                     const int band, float *X, float *Y,
                                     int N, int b, uint blocks,
                                     float *lowband, int duration,
                                     float *lowband_out, int level, float gain, float *lowband_scratch, int fill)
{
    import core.stdc.math : sqrtf;
    const(uint8_t)* cache;
    int dualstereo, split;
    int imid = 0, iside = 0;
    uint N0 = N;
    int N_B;
    int N_B0;
    int B0 = blocks;
    int time_divide = 0;
    int recombine = 0;
    int inv = 0;
    float mid = 0, side = 0;
    int longblocks = (B0 == 1);
    uint cm = 0;

    N_B0 = N_B = N / blocks;
    split = dualstereo = (Y !is null);

    if (N == 1) {
        /* special case for one sample */
        int i;
        float *x = X;
        for (i = 0; i <= dualstereo; i++) {
            int sign = 0;
            if (s.remaining2 >= 1<<3) {
                sign           = opus_getrawbits(rc, 1);
                s.remaining2 -= 1 << 3;
                b             -= 1 << 3;
            }
            x[0] = sign ? -1.0f : 1.0f;
            x = Y;
        }
        if (lowband_out)
            lowband_out[0] = X[0];
        return 1;
    }

    if (!dualstereo && level == 0) {
        int tf_change = s.tf_change[band];
        int k;
        if (tf_change > 0)
            recombine = tf_change;
        /* Band recombining to increase frequency resolution */

        if (lowband &&
            (recombine || ((N_B & 1) == 0 && tf_change < 0) || B0 > 1)) {
            int j;
            for (j = 0; j < N; j++)
                lowband_scratch[j] = lowband[j];
            lowband = lowband_scratch;
        }

        for (k = 0; k < recombine; k++) {
            if (lowband)
                celt_haar1(lowband, N >> k, 1 << k);
            fill = celt_bit_interleave[fill & 0xF] | celt_bit_interleave[fill >> 4] << 2;
        }
        blocks >>= recombine;
        N_B <<= recombine;

        /* Increasing the time resolution */
        while ((N_B & 1) == 0 && tf_change < 0) {
            if (lowband)
                celt_haar1(lowband, N_B, blocks);
            fill |= fill << blocks;
            blocks <<= 1;
            N_B >>= 1;
            time_divide++;
            tf_change++;
        }
        B0 = blocks;
        N_B0 = N_B;

        /* Reorganize the samples in time order instead of frequency order */
        if (B0 > 1 && lowband)
            celt_deinterleave_hadamard(s.scratch.ptr, lowband, N_B >> recombine, B0 << recombine, longblocks);
    }

    /* If we need 1.5 more bit than we can produce, split the band in two. */
    cache = celt_cache_bits.ptr + celt_cache_index[(duration + 1) * CELT_MAX_BANDS + band];
    if (!dualstereo && duration >= 0 && b > cache[cache[0]] + 12 && N > 2) {
        N >>= 1;
        Y = X + N;
        split = 1;
        duration -= 1;
        if (blocks == 1)
            fill = (fill & 1) | (fill << 1);
        blocks = (blocks + 1) >> 1;
    }

    if (split) {
        int qn;
        int itheta = 0;
        int mbits, sbits, delta;
        int qalloc;
        int pulse_cap;
        int offset;
        int orig_fill;
        int tell;

        /* Decide on the resolution to give to the split parameter theta */
        pulse_cap = celt_log_freq_range[band] + duration * 8;
        offset = (pulse_cap >> 1) - (dualstereo && N == 2 ? CELT_QTHETA_OFFSET_TWOPHASE :
                                                          CELT_QTHETA_OFFSET);
        qn = (dualstereo && band >= s.intensitystereo) ? 1 :
             celt_compute_qn(N, b, offset, pulse_cap, dualstereo);
        tell = opus_rc_tell_frac(rc);
        if (qn != 1) {
            /* Entropy coding of the angle. We use a uniform pdf for the
            time split, a step for stereo, and a triangular one for the rest. */
            if (dualstereo && N > 2)
                itheta = opus_rc_stepmodel(rc, qn/2);
            else if (dualstereo || B0 > 1)
                itheta = opus_rc_unimodel(rc, qn+1);
            else
                itheta = opus_rc_trimodel(rc, qn);
            itheta = itheta * 16384 / qn;
            /* NOTE: Renormalising X and Y *may* help fixed-point a bit at very high rate.
            Let's do that at higher complexity */
        } else if (dualstereo) {
            inv = (b > 2 << 3 && s.remaining2 > 2 << 3) ? opus_rc_p2model(rc, 2) : 0;
            itheta = 0;
        }
        qalloc = opus_rc_tell_frac(rc) - tell;
        b -= qalloc;

        orig_fill = fill;
        if (itheta == 0) {
            imid = 32767;
            iside = 0;
            fill = av_mod_uintp2(fill, blocks);
            delta = -16384;
        } else if (itheta == 16384) {
            imid = 0;
            iside = 32767;
            fill &= ((1 << blocks) - 1) << blocks;
            delta = 16384;
        } else {
            imid = celt_cos(cast(short)itheta);
            iside = celt_cos(cast(short)(16384-itheta));
            /* This is the mid vs side allocation that minimizes squared error
            in that band. */
            delta = ROUND_MUL16((N - 1) << 7, celt_log2tan(iside, imid));
        }

        mid  = imid  / 32768.0f;
        side = iside / 32768.0f;

        /* This is a special case for N=2 that only works for stereo and takes
        advantage of the fact that mid and side are orthogonal to encode
        the side with just one bit. */
        if (N == 2 && dualstereo) {
            int c;
            int sign = 0;
            float tmp;
            float* x2, y2;
            mbits = b;
            /* Only need one bit for the side */
            sbits = (itheta != 0 && itheta != 16384) ? 1 << 3 : 0;
            mbits -= sbits;
            c = (itheta > 8192);
            s.remaining2 -= qalloc+sbits;

            x2 = c ? Y : X;
            y2 = c ? X : Y;
            if (sbits)
                sign = opus_getrawbits(rc, 1);
            sign = 1 - 2 * sign;
            /* We use orig_fill here because we want to fold the side, but if
            itheta==16384, we'll have cleared the low bits of fill. */
            cm = celt_decode_band(s, rc, band, x2, null, N, mbits, blocks,
                                  lowband, duration, lowband_out, level, gain,
                                  lowband_scratch, orig_fill);
            /* We don't split N=2 bands, so cm is either 1 or 0 (for a fold-collapse),
            and there's no need to worry about mixing with the other channel. */
            y2[0] = -sign * x2[1];
            y2[1] =  sign * x2[0];
            X[0] *= mid;
            X[1] *= mid;
            Y[0] *= side;
            Y[1] *= side;
            tmp = X[0];
            X[0] = tmp - Y[0];
            Y[0] = tmp + Y[0];
            tmp = X[1];
            X[1] = tmp - Y[1];
            Y[1] = tmp + Y[1];
        } else {
            /* "Normal" split code */
            float *next_lowband2     = null;
            float *next_lowband_out1 = null;
            int next_level = 0;
            int rebalance;

            /* Give more bits to low-energy MDCTs than they would
             * otherwise deserve */
            if (B0 > 1 && !dualstereo && (itheta & 0x3fff)) {
                if (itheta > 8192)
                    /* Rough approximation for pre-echo masking */
                    delta -= delta >> (4 - duration);
                else
                    /* Corresponds to a forward-masking slope of
                     * 1.5 dB per 10 ms */
                    delta = FFMIN(0, delta + (N << 3 >> (5 - duration)));
            }
            mbits = av_clip((b - delta) / 2, 0, b);
            sbits = b - mbits;
            s.remaining2 -= qalloc;

            if (lowband && !dualstereo)
                next_lowband2 = lowband + N; /* >32-bit split case */

            /* Only stereo needs to pass on lowband_out.
             * Otherwise, it's handled at the end */
            if (dualstereo)
                next_lowband_out1 = lowband_out;
            else
                next_level = level + 1;

            rebalance = s.remaining2;
            if (mbits >= sbits) {
                /* In stereo mode, we do not apply a scaling to the mid
                 * because we need the normalized mid for folding later */
                cm = celt_decode_band(s, rc, band, X, null, N, mbits, blocks,
                                      lowband, duration, next_lowband_out1,
                                      next_level, dualstereo ? 1.0f : (gain * mid),
                                      lowband_scratch, fill);

                rebalance = mbits - (rebalance - s.remaining2);
                if (rebalance > 3 << 3 && itheta != 0)
                    sbits += rebalance - (3 << 3);

                /* For a stereo split, the high bits of fill are always zero,
                 * so no folding will be done to the side. */
                cm |= celt_decode_band(s, rc, band, Y, null, N, sbits, blocks,
                                       next_lowband2, duration, null,
                                       next_level, gain * side, null,
                                       fill >> blocks) << ((B0 >> 1) & (dualstereo - 1));
            } else {
                /* For a stereo split, the high bits of fill are always zero,
                 * so no folding will be done to the side. */
                cm = celt_decode_band(s, rc, band, Y, null, N, sbits, blocks,
                                      next_lowband2, duration, null,
                                      next_level, gain * side, null,
                                      fill >> blocks) << ((B0 >> 1) & (dualstereo - 1));

                rebalance = sbits - (rebalance - s.remaining2);
                if (rebalance > 3 << 3 && itheta != 16384)
                    mbits += rebalance - (3 << 3);

                /* In stereo mode, we do not apply a scaling to the mid because
                 * we need the normalized mid for folding later */
                cm |= celt_decode_band(s, rc, band, X, null, N, mbits, blocks,
                                       lowband, duration, next_lowband_out1,
                                       next_level, dualstereo ? 1.0f : (gain * mid),
                                       lowband_scratch, fill);
            }
        }
    } else {
        /* This is the basic no-split case */
        uint q         = celt_bits2pulses(cache, b);
        uint curr_bits = celt_pulses2bits(cache, q);
        s.remaining2 -= curr_bits;

        /* Ensures we can never bust the budget */
        while (s.remaining2 < 0 && q > 0) {
            s.remaining2 += curr_bits;
            curr_bits      = celt_pulses2bits(cache, --q);
            s.remaining2 -= curr_bits;
        }

        if (q != 0) {
            /* Finally do the actual quantization */
            cm = celt_alg_unquant(rc, X, N, (q < 8) ? q : (8 + (q & 7)) << ((q >> 3) - 1),
                                  s.spread, blocks, gain);
        } else {
            /* If there's no pulse, fill the band anyway */
            int j;
            uint cm_mask = (1 << blocks) - 1;
            fill &= cm_mask;
            if (!fill) {
                for (j = 0; j < N; j++)
                    X[j] = 0.0f;
            } else {
                if (!lowband) {
                    /* Noise */
                    for (j = 0; j < N; j++)
                        X[j] = ((cast(int32_t)celt_rng(s)) >> 20);
                    cm = cm_mask;
                } else {
                    /* Folded spectrum */
                    for (j = 0; j < N; j++) {
                        /* About 48 dB below the "normal" folding level */
                        X[j] = lowband[j] + (((celt_rng(s)) & 0x8000) ? 1.0f / 256 : -1.0f / 256);
                    }
                    cm = fill;
                }
                celt_renormalize_vector(X, N, gain);
            }
        }
    }

    /* This code is used by the decoder and by the resynthesis-enabled encoder */
    if (dualstereo) {
        int j;
        if (N != 2)
            celt_stereo_merge(X, Y, mid, N);
        if (inv) {
            for (j = 0; j < N; j++)
                Y[j] *= -1;
        }
    } else if (level == 0) {
        int k;

        /* Undo the sample reorganization going from time order to frequency order */
        if (B0 > 1)
            celt_interleave_hadamard(s.scratch.ptr, X, N_B>>recombine, B0<<recombine, longblocks);

        /* Undo time-freq changes that we did earlier */
        N_B = N_B0;
        blocks = B0;
        for (k = 0; k < time_divide; k++) {
            blocks >>= 1;
            N_B <<= 1;
            cm |= cm >> blocks;
            celt_haar1(X, N_B, blocks);
        }

        for (k = 0; k < recombine; k++) {
            cm = celt_bit_deinterleave[cm];
            celt_haar1(X, N0>>k, 1<<k);
        }
        blocks <<= recombine;

        /* Scale output for later folding */
        if (lowband_out) {
            int j;
            float n = sqrtf(N0);
            for (j = 0; j < N0; j++)
                lowband_out[j] = n * X[j];
        }
        cm = av_mod_uintp2(cm, blocks);
    }
    return cm;
}

private void celt_denormalize(CeltContext *s, CeltFrame *frame, float *data)
{
    import std.math : exp2;
    int i, j;

    for (i = s.startband; i < s.endband; i++) {
        float *dst = data + (celt_freq_bands[i] << s.duration);
        float norm = exp2(frame.energy[i] + celt_mean_energy[i]);

        for (j = 0; j < celt_freq_range[i] << s.duration; j++)
            dst[j] *= norm;
    }
}

private void celt_postfilter_apply_transition(CeltFrame *frame, float *data)
{
    const int T0 = frame.pf_period_old;
    const int T1 = frame.pf_period;

    float g00, g01, g02;
    float g10, g11, g12;

    float x0, x1, x2, x3, x4;

    int i;

    if (frame.pf_gains[0]     == 0.0 &&
        frame.pf_gains_old[0] == 0.0)
        return;

    g00 = frame.pf_gains_old[0];
    g01 = frame.pf_gains_old[1];
    g02 = frame.pf_gains_old[2];
    g10 = frame.pf_gains[0];
    g11 = frame.pf_gains[1];
    g12 = frame.pf_gains[2];

    x1 = data[-T1 + 1];
    x2 = data[-T1];
    x3 = data[-T1 - 1];
    x4 = data[-T1 - 2];

    for (i = 0; i < CELT_OVERLAP; i++) {
        float w = ff_celt_window2[i];
        x0 = data[i - T1 + 2];

        data[i] +=  (1.0 - w) * g00 * data[i - T0]                          +
                    (1.0 - w) * g01 * (data[i - T0 - 1] + data[i - T0 + 1]) +
                    (1.0 - w) * g02 * (data[i - T0 - 2] + data[i - T0 + 2]) +
                    w         * g10 * x2                                    +
                    w         * g11 * (x1 + x3)                             +
                    w         * g12 * (x0 + x4);
        x4 = x3;
        x3 = x2;
        x2 = x1;
        x1 = x0;
    }
}

private void celt_postfilter_apply(CeltFrame *frame, float *data, int len)
{
    const int T = frame.pf_period;
    float g0, g1, g2;
    float x0, x1, x2, x3, x4;
    int i;

    if (frame.pf_gains[0] == 0.0 || len <= 0)
        return;

    g0 = frame.pf_gains[0];
    g1 = frame.pf_gains[1];
    g2 = frame.pf_gains[2];

    x4 = data[-T - 2];
    x3 = data[-T - 1];
    x2 = data[-T];
    x1 = data[-T + 1];

    for (i = 0; i < len; i++) {
        x0 = data[i - T + 2];
        data[i] += g0 * x2        +
                   g1 * (x1 + x3) +
                   g2 * (x0 + x4);
        x4 = x3;
        x3 = x2;
        x2 = x1;
        x1 = x0;
    }
}

private void celt_postfilter(CeltContext *s, CeltFrame *frame)
{
    import core.stdc.string : memcpy, memmove;
    int len = s.blocksize * s.blocks;

    celt_postfilter_apply_transition(frame, frame.buf.ptr + 1024);

    frame.pf_period_old = frame.pf_period;
    memcpy(frame.pf_gains_old.ptr, frame.pf_gains.ptr, frame.pf_gains.sizeof);

    frame.pf_period = frame.pf_period_new;
    memcpy(frame.pf_gains.ptr, frame.pf_gains_new.ptr, frame.pf_gains.sizeof);

    if (len > CELT_OVERLAP) {
        celt_postfilter_apply_transition(frame, frame.buf.ptr + 1024 + CELT_OVERLAP);
        celt_postfilter_apply(frame, frame.buf.ptr + 1024 + 2 * CELT_OVERLAP, len - 2 * CELT_OVERLAP);

        frame.pf_period_old = frame.pf_period;
        memcpy(frame.pf_gains_old.ptr, frame.pf_gains.ptr, frame.pf_gains.sizeof);
    }

    memmove(frame.buf.ptr, frame.buf.ptr + len, (1024 + CELT_OVERLAP / 2) * float.sizeof);
}

private int parse_postfilter(CeltContext *s, OpusRangeCoder *rc, int consumed)
{
    import core.stdc.string : memset;
    static immutable float[3][3] postfilter_taps = [
        [ 0.3066406250f, 0.2170410156f, 0.1296386719f ],
        [ 0.4638671875f, 0.2680664062f, 0.0           ],
        [ 0.7998046875f, 0.1000976562f, 0.0           ],
    ];
    int i;

    memset(s.frame[0].pf_gains_new.ptr, 0, (s.frame[0].pf_gains_new).sizeof);
    memset(s.frame[1].pf_gains_new.ptr, 0, (s.frame[1].pf_gains_new).sizeof);

    if (s.startband == 0 && consumed + 16 <= s.framebits) {
        int has_postfilter = opus_rc_p2model(rc, 1);
        if (has_postfilter) {
            float gain;
            int tapset, octave, period;

            octave = opus_rc_unimodel(rc, 6);
            period = (16 << octave) + opus_getrawbits(rc, 4 + octave) - 1;
            gain   = 0.09375f * (opus_getrawbits(rc, 3) + 1);
            tapset = (opus_rc_tell(rc) + 2 <= s.framebits) ?
                     opus_rc_getsymbol(rc, celt_model_tapset.ptr) : 0;

            for (i = 0; i < 2; i++) {
                CeltFrame *frame = &s.frame[i];

                frame.pf_period_new = FFMAX(period, CELT_POSTFILTER_MINPERIOD);
                frame.pf_gains_new[0] = gain * postfilter_taps[tapset][0];
                frame.pf_gains_new[1] = gain * postfilter_taps[tapset][1];
                frame.pf_gains_new[2] = gain * postfilter_taps[tapset][2];
            }
        }

        consumed = opus_rc_tell(rc);
    }

    return consumed;
}

private void process_anticollapse(CeltContext *s, CeltFrame *frame, float *X)
{
    import core.stdc.math : exp2f, exp2, sqrtf;
    int i, j, k;

    for (i = s.startband; i < s.endband; i++) {
        int renormalize = 0;
        float *xptr;
        float[2] prev;
        float Ediff, r;
        float thresh, sqrt_1;
        int depth;

        /* depth in 1/8 bits */
        depth = (1 + s.pulses[i]) / (celt_freq_range[i] << s.duration);
        thresh = exp2f(-1.0 - 0.125f * depth);
        sqrt_1 = 1.0f / sqrtf(celt_freq_range[i] << s.duration);

        xptr = X + (celt_freq_bands[i] << s.duration);

        prev[0] = frame.prev_energy[0][i];
        prev[1] = frame.prev_energy[1][i];
        if (s.coded_channels == 1) {
            CeltFrame *frame1 = &s.frame[1];

            prev[0] = FFMAX(prev[0], frame1.prev_energy[0][i]);
            prev[1] = FFMAX(prev[1], frame1.prev_energy[1][i]);
        }
        Ediff = frame.energy[i] - FFMIN(prev[0], prev[1]);
        Ediff = FFMAX(0, Ediff);

        /* r needs to be multiplied by 2 or 2*sqrt(2) depending on LM because
        short blocks don't have the same energy as long */
        r = exp2(1 - Ediff);
        if (s.duration == 3)
            r *= M_SQRT2;
        r = FFMIN(thresh, r) * sqrt_1;
        for (k = 0; k < 1 << s.duration; k++) {
            /* Detect collapse */
            if (!(frame.collapse_masks[i] & 1 << k)) {
                /* Fill with noise */
                for (j = 0; j < celt_freq_range[i]; j++)
                    xptr[(j << s.duration) + k] = (celt_rng(s) & 0x8000) ? r : -r;
                renormalize = 1;
            }
        }

        /* We just added some energy, so we need to renormalize */
        if (renormalize)
            celt_renormalize_vector(xptr, celt_freq_range[i] << s.duration, 1.0f);
    }
}

private void celt_decode_bands(CeltContext *s, OpusRangeCoder *rc)
{
    import core.stdc.string : memset;
    float[8 * 22] lowband_scratch = void;
    float[2 * 8 * 100] norm = void;

    int totalbits = (s.framebits << 3) - s.anticollapse_bit;

    int update_lowband = 1;
    int lowband_offset = 0;

    int i, j;

    memset(s.coeffs.ptr, 0, s.coeffs.sizeof);

    for (i = s.startband; i < s.endband; i++) {
        int band_offset = celt_freq_bands[i] << s.duration;
        int band_size   = celt_freq_range[i] << s.duration;
        float *X = s.coeffs[0].ptr + band_offset;
        float *Y = (s.coded_channels == 2) ? s.coeffs[1].ptr + band_offset : null;

        int consumed = opus_rc_tell_frac(rc);
        float *norm2 = norm.ptr + 8 * 100;
        int effective_lowband = -1;
        uint[2] cm;
        int b;

        /* Compute how many bits we want to allocate to this band */
        if (i != s.startband)
            s.remaining -= consumed;
        s.remaining2 = totalbits - consumed - 1;
        if (i <= s.codedbands - 1) {
            int curr_balance = s.remaining / FFMIN(3, s.codedbands-i);
            b = av_clip_uintp2(FFMIN(s.remaining2 + 1, s.pulses[i] + curr_balance), 14);
        } else
            b = 0;

        if (celt_freq_bands[i] - celt_freq_range[i] >= celt_freq_bands[s.startband] &&
            (update_lowband || lowband_offset == 0))
            lowband_offset = i;

        /* Get a conservative estimate of the collapse_mask's for the bands we're
        going to be folding from. */
        if (lowband_offset != 0 && (s.spread != CELT_SPREAD_AGGRESSIVE ||
                                    s.blocks > 1 || s.tf_change[i] < 0)) {
            int foldstart, foldend;

            /* This ensures we never repeat spectral content within one band */
            effective_lowband = FFMAX(celt_freq_bands[s.startband],
                                      celt_freq_bands[lowband_offset] - celt_freq_range[i]);
            foldstart = lowband_offset;
            while (celt_freq_bands[--foldstart] > effective_lowband) {}
            foldend = lowband_offset - 1;
            while (celt_freq_bands[++foldend] < effective_lowband + celt_freq_range[i]) {}

            cm[0] = cm[1] = 0;
            for (j = foldstart; j < foldend; j++) {
                cm[0] |= s.frame[0].collapse_masks[j];
                cm[1] |= s.frame[s.coded_channels - 1].collapse_masks[j];
            }
        } else
            /* Otherwise, we'll be using the LCG to fold, so all blocks will (almost
            always) be non-zero.*/
            cm[0] = cm[1] = (1 << s.blocks) - 1;

        if (s.dualstereo && i == s.intensitystereo) {
            /* Switch off dual stereo to do intensity */
            s.dualstereo = 0;
            for (j = celt_freq_bands[s.startband] << s.duration; j < band_offset; j++)
                norm[j] = (norm[j] + norm2[j]) / 2;
        }

        if (s.dualstereo) {
            cm[0] = celt_decode_band(s, rc, i, X, null, band_size, b / 2, s.blocks,
                                     effective_lowband != -1 ? norm.ptr + (effective_lowband << s.duration) : null, s.duration,
            norm.ptr + band_offset, 0, 1.0f, lowband_scratch.ptr, cm[0]);

            cm[1] = celt_decode_band(s, rc, i, Y, null, band_size, b/2, s.blocks,
                                     effective_lowband != -1 ? norm2 + (effective_lowband << s.duration) : null, s.duration,
            norm2 + band_offset, 0, 1.0f, lowband_scratch.ptr, cm[1]);
        } else {
            cm[0] = celt_decode_band(s, rc, i, X, Y, band_size, b, s.blocks,
            effective_lowband != -1 ? norm.ptr + (effective_lowband << s.duration) : null, s.duration,
            norm.ptr + band_offset, 0, 1.0f, lowband_scratch.ptr, cm[0]|cm[1]);

            cm[1] = cm[0];
        }

        s.frame[0].collapse_masks[i]                    = cast(uint8_t)cm[0];
        s.frame[s.coded_channels - 1].collapse_masks[i] = cast(uint8_t)cm[1];
        s.remaining += s.pulses[i] + consumed;

        /* Update the folding position only as long as we have 1 bit/sample depth */
        update_lowband = (b > band_size << 3);
    }
}

int ff_celt_decode_frame(CeltContext *s, OpusRangeCoder *rc,
                         float **output, int coded_channels, int frame_size,
                         int startband,  int endband)
{
    import core.stdc.string : memcpy, memset;
    int i, j;

    int consumed;           // bits of entropy consumed thus far for this frame
    int silence = 0;
    int transient = 0;
    int anticollapse = 0;
    IMDCT15Context *imdct;
    float imdct_scale = 1.0;

    if (coded_channels != 1 && coded_channels != 2) {
        //av_log(AV_LOG_ERROR, "Invalid number of coded channels: %d\n", coded_channels);
        return AVERROR_INVALIDDATA;
    }
    if (startband < 0 || startband > endband || endband > CELT_MAX_BANDS) {
        //av_log(AV_LOG_ERROR, "Invalid start/end band: %d %d\n", startband, endband);
        return AVERROR_INVALIDDATA;
    }

    s.flushed        = 0;
    s.coded_channels = coded_channels;
    s.startband      = startband;
    s.endband        = endband;
    s.framebits      = rc.rb.bytes * 8;

    s.duration = av_log2(frame_size / CELT_SHORT_BLOCKSIZE);
    if (s.duration > CELT_MAX_LOG_BLOCKS ||
        frame_size != CELT_SHORT_BLOCKSIZE * (1 << s.duration)) {
        //av_log(AV_LOG_ERROR, "Invalid CELT frame size: %d\n", frame_size);
        return AVERROR_INVALIDDATA;
    }

    if (!s.output_channels)
        s.output_channels = coded_channels;

    memset(s.frame[0].collapse_masks.ptr, 0, s.frame[0].collapse_masks.sizeof);
    memset(s.frame[1].collapse_masks.ptr, 0, s.frame[1].collapse_masks.sizeof);

    consumed = opus_rc_tell(rc);

    /* obtain silence flag */
    if (consumed >= s.framebits)
        silence = 1;
    else if (consumed == 1)
        silence = opus_rc_p2model(rc, 15);


    if (silence) {
        consumed = s.framebits;
        rc.total_read_bits += s.framebits - opus_rc_tell(rc);
    }

    /* obtain post-filter options */
    consumed = parse_postfilter(s, rc, consumed);

    /* obtain transient flag */
    if (s.duration != 0 && consumed+3 <= s.framebits)
        transient = opus_rc_p2model(rc, 3);

    s.blocks    = transient ? 1 << s.duration : 1;
    s.blocksize = frame_size / s.blocks;

    imdct = s.imdct[transient ? 0 : s.duration];

    if (coded_channels == 1) {
        for (i = 0; i < CELT_MAX_BANDS; i++)
            s.frame[0].energy[i] = FFMAX(s.frame[0].energy[i], s.frame[1].energy[i]);
    }

    celt_decode_coarse_energy(s, rc);
    celt_decode_tf_changes   (s, rc, transient);
    celt_decode_allocation   (s, rc);
    celt_decode_fine_energy  (s, rc);
    celt_decode_bands        (s, rc);

    if (s.anticollapse_bit)
        anticollapse = opus_getrawbits(rc, 1);

    celt_decode_final_energy(s, rc, s.framebits - opus_rc_tell(rc));

    /* apply anti-collapse processing and denormalization to
     * each coded channel */
    for (i = 0; i < s.coded_channels; i++) {
        CeltFrame *frame = &s.frame[i];

        if (anticollapse)
            process_anticollapse(s, frame, s.coeffs[i].ptr);

        celt_denormalize(s, frame, s.coeffs[i].ptr);
    }

    /* stereo . mono downmix */
    if (s.output_channels < s.coded_channels) {
        vector_fmac_scalar(s.coeffs[0].ptr, s.coeffs[1].ptr, 1.0f, /*FFALIGN(frame_size, 16)*/frame_size);
        imdct_scale = 0.5;
    } else if (s.output_channels > s.coded_channels)
        memcpy(s.coeffs[1].ptr, s.coeffs[0].ptr, frame_size * float.sizeof);

    if (silence) {
        for (i = 0; i < 2; i++) {
            CeltFrame *frame = &s.frame[i];

            for (j = 0; j < /*FF_ARRAY_ELEMS*/frame.energy.length; j++)
                frame.energy[j] = CELT_ENERGY_SILENCE;
        }
        memset(s.coeffs.ptr, 0, s.coeffs.sizeof);
    }

    /* transform and output for each output channel */
    for (i = 0; i < s.output_channels; i++) {
        CeltFrame *frame = &s.frame[i];
        float m = frame.deemph_coeff;

        /* iMDCT and overlap-add */
        for (j = 0; j < s.blocks; j++) {
            float *dst  = frame.buf.ptr + 1024 + j * s.blocksize;

            imdct.imdct_half(imdct, dst + CELT_OVERLAP / 2, s.coeffs[i].ptr + j, s.blocks, imdct_scale);
            vector_fmul_window(dst, dst, dst + CELT_OVERLAP / 2, celt_window.ptr, CELT_OVERLAP / 2);
        }

        /* postfilter */
        celt_postfilter(s, frame);

        /* deemphasis and output scaling */
        for (j = 0; j < frame_size; j++) {
            float tmp = frame.buf[1024 - frame_size + j] + m;
            m = tmp * CELT_DEEMPH_COEFF;
            output[i][j] = tmp / 32768.;
        }
        frame.deemph_coeff = m;
    }

    if (coded_channels == 1)
        memcpy(s.frame[1].energy.ptr, s.frame[0].energy.ptr, s.frame[0].energy.sizeof);

    for (i = 0; i < 2; i++ ) {
        CeltFrame *frame = &s.frame[i];

        if (!transient) {
            memcpy(frame.prev_energy[1].ptr, frame.prev_energy[0].ptr, frame.prev_energy[0].sizeof);
            memcpy(frame.prev_energy[0].ptr, frame.energy.ptr,         frame.prev_energy[0].sizeof);
        } else {
            for (j = 0; j < CELT_MAX_BANDS; j++)
                frame.prev_energy[0][j] = FFMIN(frame.prev_energy[0][j], frame.energy[j]);
        }

        for (j = 0; j < s.startband; j++) {
            frame.prev_energy[0][j] = CELT_ENERGY_SILENCE;
            frame.energy[j]         = 0.0;
        }
        for (j = s.endband; j < CELT_MAX_BANDS; j++) {
            frame.prev_energy[0][j] = CELT_ENERGY_SILENCE;
            frame.energy[j]         = 0.0;
        }
    }

    s.seed = rc.range;

    return 0;
}

void ff_celt_flush(CeltContext *s)
{
    import core.stdc.string : memset;
    int i, j;

    if (s.flushed)
        return;

    for (i = 0; i < 2; i++) {
        CeltFrame *frame = &s.frame[i];

        for (j = 0; j < CELT_MAX_BANDS; j++)
            frame.prev_energy[0][j] = frame.prev_energy[1][j] = CELT_ENERGY_SILENCE;

        memset(frame.energy.ptr, 0, frame.energy.sizeof);
        memset(frame.buf.ptr,    0, frame.buf.sizeof);

        memset(frame.pf_gains.ptr,     0, frame.pf_gains.sizeof);
        memset(frame.pf_gains_old.ptr, 0, frame.pf_gains_old.sizeof);
        memset(frame.pf_gains_new.ptr, 0, frame.pf_gains_new.sizeof);

        frame.deemph_coeff = 0.0;
    }
    s.seed = 0;

    s.flushed = 1;
}

void ff_celt_free(CeltContext **ps)
{
    CeltContext *s = *ps;
    int i;

    if (!s)
        return;

    for (i = 0; i < /*FF_ARRAY_ELEMS*/s.imdct.length; i++)
        ff_imdct15_uninit(&s.imdct[i]);

    //av_freep(&s.dsp);
    av_freep(ps);
}

int ff_celt_init(/*AVCodecContext *avctx,*/ CeltContext **ps, int output_channels)
{
    CeltContext *s;
    int i, ret;

    if (output_channels != 1 && output_channels != 2) {
        //av_log(avctx, AV_LOG_ERROR, "Invalid number of output channels: %d\n", output_channels);
        return AVERROR(EINVAL);
    }

    s = av_mallocz!CeltContext();
    if (!s)
        return AVERROR(ENOMEM);

    //s.avctx           = avctx;
    s.output_channels = output_channels;

    for (i = 0; i < /*FF_ARRAY_ELEMS*/s.imdct.length; i++) {
        ret = ff_imdct15_init(&s.imdct[i], i + 3);
        if (ret < 0)
            goto fail;
    }

    //!!!s.dsp = avpriv_float_dsp_alloc(avctx.flags & AV_CODEC_FLAG_BITEXACT);
    /*if (!s.dsp) {
        ret = AVERROR(ENOMEM);
        goto fail;
    }*/

    ff_celt_flush(s);

    *ps = s;

    return 0;
fail:
    ff_celt_free(&s);
    return ret;
}


struct SilkFrame {
    int coded;
    int log_gain;
    int16_t[16] nlsf;
    float[16] lpc;

    float[2 * SILK_HISTORY] output;
    float[2 * SILK_HISTORY] lpc_history;
    int primarylag;

    int prev_voiced;
}

struct SilkContext {
    //AVCodecContext *avctx;
    int output_channels;

    int midonly;
    int subframes;
    int sflength;
    int flength;
    int nlsf_interp_factor;

    OpusBandwidth bandwidth;
    int wb;

    SilkFrame[2] frame;
    float[2] prev_stereo_weights;
    float[2] stereo_weights;

    int prev_coded_channels;
}

static immutable uint16_t[26] silk_model_stereo_s1 = [
    256,   7,   9,  10,  11,  12,  22,  46,  54,  55,  56,  59,  82, 174, 197, 200,
    201, 202, 210, 234, 244, 245, 246, 247, 249, 256
];

static immutable uint16_t[4] silk_model_stereo_s2 = [256, 85, 171, 256];

static immutable uint16_t[6] silk_model_stereo_s3 = [256, 51, 102, 154, 205, 256];

static immutable uint16_t[3] silk_model_mid_only = [256, 192, 256];

static immutable uint16_t[3] silk_model_frame_type_inactive = [256, 26, 256];

static immutable uint16_t[5] silk_model_frame_type_active = [256, 24, 98, 246, 256];

static immutable uint16_t[9][3] silk_model_gain_highbits = [
    [256,  32, 144, 212, 241, 253, 254, 255, 256],
    [256,   2,  19,  64, 124, 186, 233, 252, 256],
    [256,   1,   4,  30, 101, 195, 245, 254, 256]
];

static immutable uint16_t[9] silk_model_gain_lowbits = [256, 32, 64, 96, 128, 160, 192, 224, 256];

static immutable uint16_t[42] silk_model_gain_delta = [
    256,   6,  11,  22,  53, 185, 206, 214, 218, 221, 223, 225, 227, 228, 229, 230,
    231, 232, 233, 234, 235, 236, 237, 238, 239, 240, 241, 242, 243, 244, 245, 246,
    247, 248, 249, 250, 251, 252, 253, 254, 255, 256
];
static immutable uint16_t[33][2][2] silk_model_lsf_s1 = [
    [
        [    // NB or MB, unvoiced
            256,  44,  78, 108, 127, 148, 160, 171, 174, 177, 179, 195, 197, 199, 200, 205,
            207, 208, 211, 214, 215, 216, 218, 220, 222, 225, 226, 235, 244, 246, 253, 255, 256
        ], [ // NB or MB, voiced
            256,   1,  11,  12,  20,  23,  31,  39,  53,  66,  80,  81,  95, 107, 120, 131,
            142, 154, 165, 175, 185, 196, 204, 213, 221, 228, 236, 237, 238, 244, 245, 251, 256
        ]
    ], [
        [    // WB, unvoiced
            256,  31,  52,  55,  72,  73,  81,  98, 102, 103, 121, 137, 141, 143, 146, 147,
            157, 158, 161, 177, 188, 204, 206, 208, 211, 213, 224, 225, 229, 238, 246, 253, 256
        ], [ // WB, voiced
            256,   1,   5,  21,  26,  44,  55,  60,  74,  89,  90,  93, 105, 118, 132, 146,
            152, 166, 178, 180, 186, 187, 199, 211, 222, 232, 235, 245, 250, 251, 252, 253, 256
        ]
    ]
];

static immutable uint16_t[10][32] silk_model_lsf_s2 = [
    // NB, MB
    [ 256,   1,   2,   3,  18, 242, 253, 254, 255, 256 ],
    [ 256,   1,   2,   4,  38, 221, 253, 254, 255, 256 ],
    [ 256,   1,   2,   6,  48, 197, 252, 254, 255, 256 ],
    [ 256,   1,   2,  10,  62, 185, 246, 254, 255, 256 ],
    [ 256,   1,   4,  20,  73, 174, 248, 254, 255, 256 ],
    [ 256,   1,   4,  21,  76, 166, 239, 254, 255, 256 ],
    [ 256,   1,   8,  32,  85, 159, 226, 252, 255, 256 ],
    [ 256,   1,   2,  20,  83, 161, 219, 249, 255, 256 ],

    // WB
    [ 256,   1,   2,   3,  12, 244, 253, 254, 255, 256 ],
    [ 256,   1,   2,   4,  32, 218, 253, 254, 255, 256 ],
    [ 256,   1,   2,   5,  47, 199, 252, 254, 255, 256 ],
    [ 256,   1,   2,  12,  61, 187, 252, 254, 255, 256 ],
    [ 256,   1,   5,  24,  72, 172, 249, 254, 255, 256 ],
    [ 256,   1,   2,  16,  70, 170, 242, 254, 255, 256 ],
    [ 256,   1,   2,  17,  78, 165, 226, 251, 255, 256 ],
    [ 256,   1,   8,  29,  79, 156, 237, 254, 255, 256 ]
];

static immutable uint16_t[8] silk_model_lsf_s2_ext = [ 256, 156, 216, 240, 249, 253, 255, 256 ];

static immutable uint16_t[6] silk_model_lsf_interpolation_offset = [ 256, 13, 35, 64, 75, 256 ];

static immutable uint16_t[33] silk_model_pitch_highbits = [
    256,   3,   6,  12,  23,  44,  74, 106, 125, 136, 146, 158, 171, 184, 196, 207,
    216, 224, 231, 237, 241, 243, 245, 247, 248, 249, 250, 251, 252, 253, 254, 255, 256
];

static immutable uint16_t[5] silk_model_pitch_lowbits_nb= [ 256, 64, 128, 192, 256 ];

static immutable uint16_t[7] silk_model_pitch_lowbits_mb= [ 256, 43, 85, 128, 171, 213, 256 ];

static immutable uint16_t[9] silk_model_pitch_lowbits_wb= [ 256, 32, 64, 96, 128, 160, 192, 224, 256 ];

static immutable uint16_t[22] silk_model_pitch_delta = [
    256,  46,  48,  50,  53,  57,  63,  73,  88, 114, 152, 182, 204, 219, 229, 236,
    242, 246, 250, 252, 254, 256
];

static immutable uint16_t[4] silk_model_pitch_contour_nb10ms = [ 256, 143, 193, 256 ];

static immutable uint16_t[12] silk_model_pitch_contour_nb20ms = [
    256,  68,  80, 101, 118, 137, 159, 189, 213, 230, 246, 256
];

static immutable uint16_t[13] silk_model_pitch_contour_mbwb10ms = [
    256,  91, 137, 176, 195, 209, 221, 229, 236, 242, 247, 252, 256
];

static immutable uint16_t[35] silk_model_pitch_contour_mbwb20ms = [
    256,  33,  55,  73,  89, 104, 118, 132, 145, 158, 168, 177, 186, 194, 200, 206,
    212, 217, 221, 225, 229, 232, 235, 238, 240, 242, 244, 246, 248, 250, 252, 253,
    254, 255, 256
];

static immutable uint16_t[4] silk_model_ltp_filter = [ 256, 77, 157, 256 ];

static immutable uint16_t[9] silk_model_ltp_filter0_sel = [
    256, 185, 200, 213, 226, 235, 244, 250, 256
];

static immutable uint16_t[17] silk_model_ltp_filter1_sel = [
    256,  57,  91, 112, 132, 147, 160, 172, 185, 195, 205, 214, 224, 233, 241, 248, 256
];

static immutable uint16_t[33] silk_model_ltp_filter2_sel = [
    256,  15,  31,  45,  57,  69,  81,  92, 103, 114, 124, 133, 142, 151, 160, 168,
    176, 184, 192, 199, 206, 212, 218, 223, 227, 232, 236, 240, 244, 247, 251, 254, 256
];

static immutable uint16_t[4] silk_model_ltp_scale_index = [ 256, 128, 192, 256 ];

static immutable uint16_t[5] silk_model_lcg_seed = [ 256, 64, 128, 192, 256 ];

static immutable uint16_t[10][2] silk_model_exc_rate = [
    [ 256,  15,  66,  78, 124, 169, 182, 215, 242, 256 ], // unvoiced
    [ 256,  33,  63,  99, 116, 150, 199, 217, 238, 256 ]  // voiced
];

static immutable uint16_t[19][11] silk_model_pulse_count = [
    [ 256, 131, 205, 230, 238, 241, 244, 245, 246,
      247, 248, 249, 250, 251, 252, 253, 254, 255, 256 ],
    [ 256,  58, 151, 211, 234, 241, 244, 245, 246,
      247, 248, 249, 250, 251, 252, 253, 254, 255, 256 ],
    [ 256,  43,  94, 140, 173, 197, 213, 224, 232,
      238, 241, 244, 247, 249, 250, 251, 253, 254, 256 ],
    [ 256,  17,  69, 140, 197, 228, 240, 245, 246,
      247, 248, 249, 250, 251, 252, 253, 254, 255, 256 ],
    [ 256,   6,  27,  68, 121, 170, 205, 226, 237,
      243, 246, 248, 250, 251, 252, 253, 254, 255, 256 ],
    [ 256,   7,  21,  43,  71, 100, 128, 153, 173,
      190, 203, 214, 223, 230, 235, 239, 243, 246, 256 ],
    [ 256,   2,   7,  21,  50,  92, 138, 179, 210,
      229, 240, 246, 249, 251, 252, 253, 254, 255, 256 ],
    [ 256,   1,   3,   7,  17,  36,  65, 100, 137,
      171, 199, 219, 233, 241, 246, 250, 252, 254, 256 ],
    [ 256,   1,   3,   5,  10,  19,  33,  53,  77,
      104, 132, 158, 181, 201, 216, 227, 235, 241, 256 ],
    [ 256,   1,   2,   3,   9,  36,  94, 150, 189,
      214, 228, 238, 244, 247, 250, 252, 253, 254, 256 ],
    [ 256,   2,   3,   9,  36,  94, 150, 189, 214,
      228, 238, 244, 247, 250, 252, 253, 254, 256, 256 ]
];

static immutable uint16_t[168][4] silk_model_pulse_location = [
    [
        256, 126, 256,
        256, 56, 198, 256,
        256, 25, 126, 230, 256,
        256, 12, 72, 180, 244, 256,
        256, 7, 42, 126, 213, 250, 256,
        256, 4, 24, 83, 169, 232, 253, 256,
        256, 3, 15, 53, 125, 200, 242, 254, 256,
        256, 2, 10, 35, 89, 162, 221, 248, 255, 256,
        256, 2, 7, 24, 63, 126, 191, 233, 251, 255, 256,
        256, 1, 5, 17, 45, 94, 157, 211, 241, 252, 255, 256,
        256, 1, 5, 13, 33, 70, 125, 182, 223, 245, 253, 255, 256,
        256, 1, 4, 11, 26, 54, 98, 151, 199, 232, 248, 254, 255, 256,
        256, 1, 3, 9, 21, 42, 77, 124, 172, 212, 237, 249, 254, 255, 256,
        256, 1, 2, 6, 16, 33, 60, 97, 144, 187, 220, 241, 250, 254, 255, 256,
        256, 1, 2, 3, 11, 25, 47, 80, 120, 163, 201, 229, 245, 253, 254, 255, 256,
        256, 1, 2, 3, 4, 17, 35, 62, 98, 139, 180, 214, 238, 252, 253, 254, 255, 256
    ],[
        256, 127, 256,
        256, 53, 202, 256,
        256, 22, 127, 233, 256,
        256, 11, 72, 183, 246, 256,
        256, 6, 41, 127, 215, 251, 256,
        256, 4, 24, 83, 170, 232, 253, 256,
        256, 3, 16, 56, 127, 200, 241, 254, 256,
        256, 3, 12, 39, 92, 162, 218, 246, 255, 256,
        256, 3, 11, 30, 67, 124, 185, 229, 249, 255, 256,
        256, 3, 10, 25, 53, 97, 151, 200, 233, 250, 255, 256,
        256, 1, 8, 21, 43, 77, 123, 171, 209, 237, 251, 255, 256,
        256, 1, 2, 13, 35, 62, 97, 139, 186, 219, 244, 254, 255, 256,
        256, 1, 2, 8, 22, 48, 85, 128, 171, 208, 234, 248, 254, 255, 256,
        256, 1, 2, 6, 16, 36, 67, 107, 149, 189, 220, 240, 250, 254, 255, 256,
        256, 1, 2, 5, 13, 29, 55, 90, 128, 166, 201, 227, 243, 251, 254, 255, 256,
        256, 1, 2, 4, 10, 22, 43, 73, 109, 147, 183, 213, 234, 246, 252, 254, 255, 256
    ],[
        256, 127, 256,
        256, 49, 206, 256,
        256, 20, 127, 236, 256,
        256, 11, 71, 184, 246, 256,
        256, 7, 43, 127, 214, 250, 256,
        256, 6, 30, 87, 169, 229, 252, 256,
        256, 5, 23, 62, 126, 194, 236, 252, 256,
        256, 6, 20, 49, 96, 157, 209, 239, 253, 256,
        256, 1, 16, 39, 74, 125, 175, 215, 245, 255, 256,
        256, 1, 2, 23, 55, 97, 149, 195, 236, 254, 255, 256,
        256, 1, 7, 23, 50, 86, 128, 170, 206, 233, 249, 255, 256,
        256, 1, 6, 18, 39, 70, 108, 148, 186, 217, 238, 250, 255, 256,
        256, 1, 4, 13, 30, 56, 90, 128, 166, 200, 226, 243, 252, 255, 256,
        256, 1, 4, 11, 25, 47, 76, 110, 146, 180, 209, 231, 245, 252, 255, 256,
        256, 1, 3, 8, 19, 37, 62, 93, 128, 163, 194, 219, 237, 248, 253, 255, 256,
        256, 1, 2, 6, 15, 30, 51, 79, 111, 145, 177, 205, 226, 241, 250, 254, 255, 256
    ],[
        256, 128, 256,
        256, 42, 214, 256,
        256, 21, 128, 235, 256,
        256, 12, 72, 184, 245, 256,
        256, 8, 42, 128, 214, 249, 256,
        256, 8, 31, 86, 176, 231, 251, 256,
        256, 5, 20, 58, 130, 202, 238, 253, 256,
        256, 6, 18, 45, 97, 174, 221, 241, 251, 256,
        256, 6, 25, 53, 88, 128, 168, 203, 231, 250, 256,
        256, 4, 18, 40, 71, 108, 148, 185, 216, 238, 252, 256,
        256, 3, 13, 31, 57, 90, 128, 166, 199, 225, 243, 253, 256,
        256, 2, 10, 23, 44, 73, 109, 147, 183, 212, 233, 246, 254, 256,
        256, 1, 6, 16, 33, 58, 90, 128, 166, 198, 223, 240, 250, 255, 256,
        256, 1, 5, 12, 25, 46, 75, 110, 146, 181, 210, 231, 244, 251, 255, 256,
        256, 1, 3, 8, 18, 35, 60, 92, 128, 164, 196, 221, 238, 248, 253, 255, 256,
        256, 1, 3, 7, 14, 27, 48, 76, 110, 146, 180, 208, 229, 242, 249, 253, 255, 256
    ]
];

static immutable uint16_t[3] silk_model_excitation_lsb = [256, 136, 256];

static immutable uint16_t[3][7][2][3] silk_model_excitation_sign = [
    [    // Inactive
        [    // Low offset
            [256,   2, 256],
            [256, 207, 256],
            [256, 189, 256],
            [256, 179, 256],
            [256, 174, 256],
            [256, 163, 256],
            [256, 157, 256]
        ], [ // High offset
            [256,  58, 256],
            [256, 245, 256],
            [256, 238, 256],
            [256, 232, 256],
            [256, 225, 256],
            [256, 220, 256],
            [256, 211, 256]
        ]
    ], [ // Unvoiced
        [    // Low offset
            [256,   1, 256],
            [256, 210, 256],
            [256, 190, 256],
            [256, 178, 256],
            [256, 169, 256],
            [256, 162, 256],
            [256, 152, 256]
        ], [ // High offset
            [256,  48, 256],
            [256, 242, 256],
            [256, 235, 256],
            [256, 224, 256],
            [256, 214, 256],
            [256, 205, 256],
            [256, 190, 256]
        ]
    ], [ // Voiced
        [    // Low offset
            [256,   1, 256],
            [256, 162, 256],
            [256, 152, 256],
            [256, 147, 256],
            [256, 144, 256],
            [256, 141, 256],
            [256, 138, 256]
        ], [ // High offset
            [256,   8, 256],
            [256, 203, 256],
            [256, 187, 256],
            [256, 176, 256],
            [256, 168, 256],
            [256, 161, 256],
            [256, 154, 256]
        ]
    ]
];

static immutable int16_t[16] silk_stereo_weights = [
    -13732, -10050,  -8266,  -7526,  -6500,  -5000,  -2950,   -820,
       820,   2950,   5000,   6500,   7526,   8266,  10050,  13732
];

static immutable uint8_t[10][32] silk_lsf_s2_model_sel_nbmb = [
    [ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ],
    [ 1, 3, 1, 2, 2, 1, 2, 1, 1, 1 ],
    [ 2, 1, 1, 1, 1, 1, 1, 1, 1, 1 ],
    [ 1, 2, 2, 2, 2, 1, 2, 1, 1, 1 ],
    [ 2, 3, 3, 3, 3, 2, 2, 2, 2, 2 ],
    [ 0, 5, 3, 3, 2, 2, 2, 2, 1, 1 ],
    [ 0, 2, 2, 2, 2, 2, 2, 2, 2, 1 ],
    [ 2, 3, 6, 4, 4, 4, 5, 4, 5, 5 ],
    [ 2, 4, 5, 5, 4, 5, 4, 6, 4, 4 ],
    [ 2, 4, 4, 7, 4, 5, 4, 5, 5, 4 ],
    [ 4, 3, 3, 3, 2, 3, 2, 2, 2, 2 ],
    [ 1, 5, 5, 6, 4, 5, 4, 5, 5, 5 ],
    [ 2, 7, 4, 6, 5, 5, 5, 5, 5, 5 ],
    [ 2, 7, 5, 5, 5, 5, 5, 6, 5, 4 ],
    [ 3, 3, 5, 4, 4, 5, 4, 5, 4, 4 ],
    [ 2, 3, 3, 5, 5, 4, 4, 4, 4, 4 ],
    [ 2, 4, 4, 6, 4, 5, 4, 5, 5, 5 ],
    [ 2, 5, 4, 6, 5, 5, 5, 4, 5, 4 ],
    [ 2, 7, 4, 5, 4, 5, 4, 5, 5, 5 ],
    [ 2, 5, 4, 6, 7, 6, 5, 6, 5, 4 ],
    [ 3, 6, 7, 4, 6, 5, 5, 6, 4, 5 ],
    [ 2, 7, 6, 4, 4, 4, 5, 4, 5, 5 ],
    [ 4, 5, 5, 4, 6, 6, 5, 6, 5, 4 ],
    [ 2, 5, 5, 6, 5, 6, 4, 6, 4, 4 ],
    [ 4, 5, 5, 5, 3, 7, 4, 5, 5, 4 ],
    [ 2, 3, 4, 5, 5, 6, 4, 5, 5, 4 ],
    [ 2, 3, 2, 3, 3, 4, 2, 3, 3, 3 ],
    [ 1, 1, 2, 2, 2, 2, 2, 3, 2, 2 ],
    [ 4, 5, 5, 6, 6, 6, 5, 6, 4, 5 ],
    [ 3, 5, 5, 4, 4, 4, 4, 3, 3, 2 ],
    [ 2, 5, 3, 7, 5, 5, 4, 4, 5, 4 ],
    [ 4, 4, 5, 4, 5, 6, 5, 6, 5, 4 ]
];

static immutable uint8_t[16][32] silk_lsf_s2_model_sel_wb = [
    [  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8 ],
    [ 10, 11, 11, 11, 11, 11, 10, 10, 10, 10, 10,  9,  9,  9,  8, 11 ],
    [ 10, 13, 13, 11, 15, 12, 12, 13, 10, 13, 12, 13, 13, 12, 11, 11 ],
    [  8, 10,  9, 10, 10,  9,  9,  9,  9,  9,  8,  8,  8,  8,  8,  9 ],
    [  8, 14, 13, 12, 14, 12, 15, 13, 12, 12, 12, 13, 13, 12, 12, 11 ],
    [  8, 11, 13, 13, 12, 11, 11, 13, 11, 11, 11, 11, 11, 11, 10, 12 ],
    [  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8 ],
    [  8, 10, 14, 11, 15, 10, 13, 11, 12, 13, 13, 12, 11, 11, 10, 11 ],
    [  8, 14, 10, 14, 14, 12, 13, 12, 14, 13, 12, 12, 13, 11, 11, 11 ],
    [ 10,  9,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8 ],
    [  8,  9,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  9 ],
    [ 10, 10, 11, 12, 13, 11, 11, 11, 11, 11, 11, 11, 10, 10,  9, 11 ],
    [ 10, 10, 11, 11, 12, 11, 11, 11, 11, 11, 11, 11, 11, 10,  9, 11 ],
    [ 11, 12, 12, 12, 14, 12, 12, 13, 11, 13, 12, 12, 13, 12, 11, 12 ],
    [  8, 14, 12, 13, 12, 15, 13, 10, 14, 13, 15, 12, 12, 11, 13, 11 ],
    [  8,  9,  8,  9,  9,  9,  9,  9,  9,  9,  8,  8,  8,  8,  9,  8 ],
    [  9, 14, 13, 15, 13, 12, 13, 11, 12, 13, 12, 12, 12, 11, 11, 12 ],
    [  9, 11, 11, 12, 12, 11, 11, 13, 10, 11, 11, 13, 13, 13, 11, 12 ],
    [ 10, 11, 11, 10, 10, 10, 11, 10,  9, 10,  9, 10,  9,  9,  9, 12 ],
    [  8, 10, 11, 13, 11, 11, 10, 10, 10,  9,  9,  8,  8,  8,  8,  8 ],
    [ 11, 12, 11, 13, 11, 11, 10, 10,  9,  9,  9,  9,  9, 10, 10, 12 ],
    [ 10, 14, 11, 15, 15, 12, 13, 12, 13, 11, 13, 11, 11, 10, 11, 11 ],
    [ 10, 11, 13, 14, 14, 11, 13, 11, 12, 12, 11, 11, 11, 11, 10, 12 ],
    [  9, 11, 11, 12, 12, 12, 12, 11, 13, 13, 13, 11,  9,  9,  9,  9 ],
    [ 10, 13, 11, 14, 14, 12, 15, 12, 12, 13, 11, 12, 12, 11, 11, 11 ],
    [  8, 14,  9,  9,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8 ],
    [  8, 14, 14, 11, 13, 10, 13, 13, 11, 12, 12, 15, 15, 12, 12, 12 ],
    [ 11, 11, 15, 11, 13, 12, 11, 11, 11, 10, 10, 11, 11, 11, 10, 11 ],
    [  8,  8,  9,  8,  8,  8, 10,  9, 10,  9,  9, 10, 10, 10,  9,  9 ],
    [  8, 11, 10, 13, 11, 11, 10, 11, 10,  9,  8,  8,  9,  8,  8,  9 ],
    [ 11, 13, 13, 12, 15, 13, 11, 11, 10, 11, 10, 10,  9,  8,  9,  8 ],
    [ 10, 11, 13, 11, 12, 11, 11, 11, 10,  9, 10, 14, 12,  8,  8,  8 ]
];

static immutable uint8_t[9][2] silk_lsf_pred_weights_nbmb = [
    [179, 138, 140, 148, 151, 149, 153, 151, 163],
    [116,  67,  82,  59,  92,  72, 100,  89,  92]
];

static immutable uint8_t[15][2] silk_lsf_pred_weights_wb = [
    [175, 148, 160, 176, 178, 173, 174, 164, 177, 174, 196, 182, 198, 192, 182],
    [ 68,  62,  66,  60,  72, 117,  85,  90, 118, 136, 151, 142, 160, 142, 155]
];

static immutable uint8_t[9][32] silk_lsf_weight_sel_nbmb = [
    [ 0, 1, 0, 0, 0, 0, 0, 0, 0 ],
    [ 1, 0, 0, 0, 0, 0, 0, 0, 0 ],
    [ 0, 0, 0, 0, 0, 0, 0, 0, 0 ],
    [ 1, 1, 1, 0, 0, 0, 0, 1, 0 ],
    [ 0, 1, 0, 0, 0, 0, 0, 0, 0 ],
    [ 0, 1, 0, 0, 0, 0, 0, 0, 0 ],
    [ 1, 0, 1, 1, 0, 0, 0, 1, 0 ],
    [ 0, 1, 1, 0, 0, 1, 1, 0, 0 ],
    [ 0, 0, 1, 1, 0, 1, 0, 1, 1 ],
    [ 0, 0, 1, 1, 0, 0, 1, 1, 1 ],
    [ 0, 0, 0, 0, 0, 0, 0, 0, 0 ],
    [ 0, 1, 0, 1, 1, 1, 1, 1, 0 ],
    [ 0, 1, 0, 1, 1, 1, 1, 1, 0 ],
    [ 0, 1, 1, 1, 1, 1, 1, 1, 0 ],
    [ 1, 0, 1, 1, 0, 1, 1, 1, 1 ],
    [ 0, 1, 1, 1, 1, 1, 0, 1, 0 ],
    [ 0, 0, 1, 1, 0, 1, 0, 1, 0 ],
    [ 0, 0, 1, 1, 1, 0, 1, 1, 1 ],
    [ 0, 1, 1, 0, 0, 1, 1, 1, 0 ],
    [ 0, 0, 0, 1, 1, 1, 0, 1, 0 ],
    [ 0, 1, 1, 0, 0, 1, 0, 1, 0 ],
    [ 0, 1, 1, 0, 0, 0, 1, 1, 0 ],
    [ 0, 0, 0, 0, 0, 1, 1, 1, 1 ],
    [ 0, 0, 1, 1, 0, 0, 0, 1, 1 ],
    [ 0, 0, 0, 1, 0, 1, 1, 1, 1 ],
    [ 0, 1, 1, 1, 1, 1, 1, 1, 0 ],
    [ 0, 0, 0, 0, 0, 0, 0, 0, 0 ],
    [ 0, 0, 0, 0, 0, 0, 0, 0, 0 ],
    [ 0, 0, 1, 0, 1, 1, 0, 1, 0 ],
    [ 1, 0, 0, 1, 0, 0, 0, 0, 0 ],
    [ 0, 0, 0, 1, 1, 0, 1, 0, 1 ],
    [ 1, 0, 1, 1, 0, 1, 1, 1, 1 ]
];

static immutable uint8_t[15][32] silk_lsf_weight_sel_wb = [
    [ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1 ],
    [ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ],
    [ 0, 0, 1, 0, 0, 1, 1, 1, 0, 1, 1, 1, 1, 0, 0 ],
    [ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0 ],
    [ 0, 1, 1, 0, 1, 0, 1, 1, 0, 1, 1, 1, 1, 1, 0 ],
    [ 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ],
    [ 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 1, 0 ],
    [ 0, 1, 1, 0, 0, 0, 1, 0, 1, 1, 1, 0, 1, 0, 1 ],
    [ 0, 1, 0, 1, 1, 0, 1, 0, 1, 0, 1, 1, 1, 1, 1 ],
    [ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1 ],
    [ 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ],
    [ 0, 0, 1, 0, 1, 1, 1, 1, 1, 1, 1, 0, 1, 0, 0 ],
    [ 0, 0, 1, 0, 0, 1, 0, 1, 0, 1, 0, 0, 1, 0, 0 ],
    [ 0, 0, 0, 0, 1, 1, 0, 1, 0, 1, 1, 1, 1, 0, 0 ],
    [ 0, 1, 0, 0, 0, 1, 1, 0, 1, 1, 1, 0, 1, 1, 1 ],
    [ 0, 0, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 0 ],
    [ 0, 1, 1, 0, 1, 0, 1, 1, 1, 1, 1, 0, 1, 0, 0 ],
    [ 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 1, 1, 1, 0, 0 ],
    [ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1 ],
    [ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0 ],
    [ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ],
    [ 0, 1, 0, 1, 0, 1, 1, 0, 1, 0, 1, 0, 1, 1, 0 ],
    [ 0, 0, 1, 1, 1, 1, 0, 1, 1, 0, 0, 1, 1, 0, 0 ],
    [ 0, 1, 1, 0, 1, 0, 1, 0, 1, 0, 0, 0, 0, 1, 0 ],
    [ 0, 0, 0, 1, 1, 0, 1, 0, 1, 1, 1, 1, 1, 1, 1 ],
    [ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1 ],
    [ 0, 1, 1, 0, 0, 0, 1, 1, 0, 0, 1, 1, 1, 1, 1 ],
    [ 0, 0, 0, 0, 0, 1, 0, 1, 1, 1, 1, 0, 1, 1, 1 ],
    [ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1 ],
    [ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1 ],
    [ 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0 ],
    [ 0, 0, 1, 0, 0, 1, 1, 1, 0, 0, 1, 0, 0, 1, 0 ]
];

static immutable uint8_t[10][32] silk_lsf_codebook_nbmb = [
    [ 12,  35,  60,  83, 108, 132, 157, 180, 206, 228 ],
    [ 15,  32,  55,  77, 101, 125, 151, 175, 201, 225 ],
    [ 19,  42,  66,  89, 114, 137, 162, 184, 209, 230 ],
    [ 12,  25,  50,  72,  97, 120, 147, 172, 200, 223 ],
    [ 26,  44,  69,  90, 114, 135, 159, 180, 205, 225 ],
    [ 13,  22,  53,  80, 106, 130, 156, 180, 205, 228 ],
    [ 15,  25,  44,  64,  90, 115, 142, 168, 196, 222 ],
    [ 19,  24,  62,  82, 100, 120, 145, 168, 190, 214 ],
    [ 22,  31,  50,  79, 103, 120, 151, 170, 203, 227 ],
    [ 21,  29,  45,  65, 106, 124, 150, 171, 196, 224 ],
    [ 30,  49,  75,  97, 121, 142, 165, 186, 209, 229 ],
    [ 19,  25,  52,  70,  93, 116, 143, 166, 192, 219 ],
    [ 26,  34,  62,  75,  97, 118, 145, 167, 194, 217 ],
    [ 25,  33,  56,  70,  91, 113, 143, 165, 196, 223 ],
    [ 21,  34,  51,  72,  97, 117, 145, 171, 196, 222 ],
    [ 20,  29,  50,  67,  90, 117, 144, 168, 197, 221 ],
    [ 22,  31,  48,  66,  95, 117, 146, 168, 196, 222 ],
    [ 24,  33,  51,  77, 116, 134, 158, 180, 200, 224 ],
    [ 21,  28,  70,  87, 106, 124, 149, 170, 194, 217 ],
    [ 26,  33,  53,  64,  83, 117, 152, 173, 204, 225 ],
    [ 27,  34,  65,  95, 108, 129, 155, 174, 210, 225 ],
    [ 20,  26,  72,  99, 113, 131, 154, 176, 200, 219 ],
    [ 34,  43,  61,  78,  93, 114, 155, 177, 205, 229 ],
    [ 23,  29,  54,  97, 124, 138, 163, 179, 209, 229 ],
    [ 30,  38,  56,  89, 118, 129, 158, 178, 200, 231 ],
    [ 21,  29,  49,  63,  85, 111, 142, 163, 193, 222 ],
    [ 27,  48,  77, 103, 133, 158, 179, 196, 215, 232 ],
    [ 29,  47,  74,  99, 124, 151, 176, 198, 220, 237 ],
    [ 33,  42,  61,  76,  93, 121, 155, 174, 207, 225 ],
    [ 29,  53,  87, 112, 136, 154, 170, 188, 208, 227 ],
    [ 24,  30,  52,  84, 131, 150, 166, 186, 203, 229 ],
    [ 37,  48,  64,  84, 104, 118, 156, 177, 201, 230 ]
];

static immutable uint8_t[16][32] silk_lsf_codebook_wb = [
    [  7,  23,  38,  54,  69,  85, 100, 116, 131, 147, 162, 178, 193, 208, 223, 239 ],
    [ 13,  25,  41,  55,  69,  83,  98, 112, 127, 142, 157, 171, 187, 203, 220, 236 ],
    [ 15,  21,  34,  51,  61,  78,  92, 106, 126, 136, 152, 167, 185, 205, 225, 240 ],
    [ 10,  21,  36,  50,  63,  79,  95, 110, 126, 141, 157, 173, 189, 205, 221, 237 ],
    [ 17,  20,  37,  51,  59,  78,  89, 107, 123, 134, 150, 164, 184, 205, 224, 240 ],
    [ 10,  15,  32,  51,  67,  81,  96, 112, 129, 142, 158, 173, 189, 204, 220, 236 ],
    [  8,  21,  37,  51,  65,  79,  98, 113, 126, 138, 155, 168, 179, 192, 209, 218 ],
    [ 12,  15,  34,  55,  63,  78,  87, 108, 118, 131, 148, 167, 185, 203, 219, 236 ],
    [ 16,  19,  32,  36,  56,  79,  91, 108, 118, 136, 154, 171, 186, 204, 220, 237 ],
    [ 11,  28,  43,  58,  74,  89, 105, 120, 135, 150, 165, 180, 196, 211, 226, 241 ],
    [  6,  16,  33,  46,  60,  75,  92, 107, 123, 137, 156, 169, 185, 199, 214, 225 ],
    [ 11,  19,  30,  44,  57,  74,  89, 105, 121, 135, 152, 169, 186, 202, 218, 234 ],
    [ 12,  19,  29,  46,  57,  71,  88, 100, 120, 132, 148, 165, 182, 199, 216, 233 ],
    [ 17,  23,  35,  46,  56,  77,  92, 106, 123, 134, 152, 167, 185, 204, 222, 237 ],
    [ 14,  17,  45,  53,  63,  75,  89, 107, 115, 132, 151, 171, 188, 206, 221, 240 ],
    [  9,  16,  29,  40,  56,  71,  88, 103, 119, 137, 154, 171, 189, 205, 222, 237 ],
    [ 16,  19,  36,  48,  57,  76,  87, 105, 118, 132, 150, 167, 185, 202, 218, 236 ],
    [ 12,  17,  29,  54,  71,  81,  94, 104, 126, 136, 149, 164, 182, 201, 221, 237 ],
    [ 15,  28,  47,  62,  79,  97, 115, 129, 142, 155, 168, 180, 194, 208, 223, 238 ],
    [  8,  14,  30,  45,  62,  78,  94, 111, 127, 143, 159, 175, 192, 207, 223, 239 ],
    [ 17,  30,  49,  62,  79,  92, 107, 119, 132, 145, 160, 174, 190, 204, 220, 235 ],
    [ 14,  19,  36,  45,  61,  76,  91, 108, 121, 138, 154, 172, 189, 205, 222, 238 ],
    [ 12,  18,  31,  45,  60,  76,  91, 107, 123, 138, 154, 171, 187, 204, 221, 236 ],
    [ 13,  17,  31,  43,  53,  70,  83, 103, 114, 131, 149, 167, 185, 203, 220, 237 ],
    [ 17,  22,  35,  42,  58,  78,  93, 110, 125, 139, 155, 170, 188, 206, 224, 240 ],
    [  8,  15,  34,  50,  67,  83,  99, 115, 131, 146, 162, 178, 193, 209, 224, 239 ],
    [ 13,  16,  41,  66,  73,  86,  95, 111, 128, 137, 150, 163, 183, 206, 225, 241 ],
    [ 17,  25,  37,  52,  63,  75,  92, 102, 119, 132, 144, 160, 175, 191, 212, 231 ],
    [ 19,  31,  49,  65,  83, 100, 117, 133, 147, 161, 174, 187, 200, 213, 227, 242 ],
    [ 18,  31,  52,  68,  88, 103, 117, 126, 138, 149, 163, 177, 192, 207, 223, 239 ],
    [ 16,  29,  47,  61,  76,  90, 106, 119, 133, 147, 161, 176, 193, 209, 224, 240 ],
    [ 15,  21,  35,  50,  61,  73,  86,  97, 110, 119, 129, 141, 175, 198, 218, 237 ]
];

static immutable uint16_t[11] silk_lsf_min_spacing_nbmb = [
    250, 3, 6, 3, 3, 3, 4, 3, 3, 3, 461
];

static immutable uint16_t[17] silk_lsf_min_spacing_wb = [
    100, 3, 40, 3, 3, 3, 5, 14, 14, 10, 11, 3, 8, 9, 7, 3, 347
];

static immutable uint8_t[10] silk_lsf_ordering_nbmb = [
    0, 9, 6, 3, 4, 5, 8, 1, 2, 7
];

static immutable uint8_t[16] silk_lsf_ordering_wb = [
    0, 15, 8, 7, 4, 11, 12, 3, 2, 13, 10, 5, 6, 9, 14, 1
];

static immutable int16_t[129] silk_cosine = [ /* (0.12) */
     4096,  4095,  4091,  4085,
     4076,  4065,  4052,  4036,
     4017,  3997,  3973,  3948,
     3920,  3889,  3857,  3822,
     3784,  3745,  3703,  3659,
     3613,  3564,  3513,  3461,
     3406,  3349,  3290,  3229,
     3166,  3102,  3035,  2967,
     2896,  2824,  2751,  2676,
     2599,  2520,  2440,  2359,
     2276,  2191,  2106,  2019,
     1931,  1842,  1751,  1660,
     1568,  1474,  1380,  1285,
     1189,  1093,   995,   897,
      799,   700,   601,   501,
      401,   301,   201,   101,
        0,  -101,  -201,  -301,
     -401,  -501,  -601,  -700,
     -799,  -897,  -995, -1093,
    -1189, -1285, -1380, -1474,
    -1568, -1660, -1751, -1842,
    -1931, -2019, -2106, -2191,
    -2276, -2359, -2440, -2520,
    -2599, -2676, -2751, -2824,
    -2896, -2967, -3035, -3102,
    -3166, -3229, -3290, -3349,
    -3406, -3461, -3513, -3564,
    -3613, -3659, -3703, -3745,
    -3784, -3822, -3857, -3889,
    -3920, -3948, -3973, -3997,
    -4017, -4036, -4052, -4065,
    -4076, -4085, -4091, -4095,
    -4096
];

static immutable uint16_t[3] silk_pitch_scale   = [  4,   6,   8];

static immutable uint16_t[3] silk_pitch_min_lag = [ 16,  24,  32];

static immutable uint16_t[3] silk_pitch_max_lag = [144, 216, 288];

static immutable int8_t[2][3] silk_pitch_offset_nb10ms = [
    [ 0,  0],
    [ 1,  0],
    [ 0,  1]
];

static immutable int8_t[4][11] silk_pitch_offset_nb20ms = [
    [ 0,  0,  0,  0],
    [ 2,  1,  0, -1],
    [-1,  0,  1,  2],
    [-1,  0,  0,  1],
    [-1,  0,  0,  0],
    [ 0,  0,  0,  1],
    [ 0,  0,  1,  1],
    [ 1,  1,  0,  0],
    [ 1,  0,  0,  0],
    [ 0,  0,  0, -1],
    [ 1,  0,  0, -1]
];

static immutable int8_t[2][12] silk_pitch_offset_mbwb10ms = [
    [ 0,  0],
    [ 0,  1],
    [ 1,  0],
    [-1,  1],
    [ 1, -1],
    [-1,  2],
    [ 2, -1],
    [-2,  2],
    [ 2, -2],
    [-2,  3],
    [ 3, -2],
    [-3,  3]
];

static immutable int8_t[4][34] silk_pitch_offset_mbwb20ms = [
    [ 0,  0,  0,  0],
    [ 0,  0,  1,  1],
    [ 1,  1,  0,  0],
    [-1,  0,  0,  0],
    [ 0,  0,  0,  1],
    [ 1,  0,  0,  0],
    [-1,  0,  0,  1],
    [ 0,  0,  0, -1],
    [-1,  0,  1,  2],
    [ 1,  0,  0, -1],
    [-2, -1,  1,  2],
    [ 2,  1,  0, -1],
    [-2,  0,  0,  2],
    [-2,  0,  1,  3],
    [ 2,  1, -1, -2],
    [-3, -1,  1,  3],
    [ 2,  0,  0, -2],
    [ 3,  1,  0, -2],
    [-3, -1,  2,  4],
    [-4, -1,  1,  4],
    [ 3,  1, -1, -3],
    [-4, -1,  2,  5],
    [ 4,  2, -1, -3],
    [ 4,  1, -1, -4],
    [-5, -1,  2,  6],
    [ 5,  2, -1, -4],
    [-6, -2,  2,  6],
    [-5, -2,  2,  5],
    [ 6,  2, -1, -5],
    [-7, -2,  3,  8],
    [ 6,  2, -2, -6],
    [ 5,  2, -2, -5],
    [ 8,  3, -2, -7],
    [-9, -3,  3,  9]
];

static immutable int8_t[5][8] silk_ltp_filter0_taps = [
    [  4,   6,  24,   7,   5],
    [  0,   0,   2,   0,   0],
    [ 12,  28,  41,  13,  -4],
    [ -9,  15,  42,  25,  14],
    [  1,  -2,  62,  41,  -9],
    [-10,  37,  65,  -4,   3],
    [ -6,   4,  66,   7,  -8],
    [ 16,  14,  38,  -3,  33]
];

static immutable int8_t[5][16] silk_ltp_filter1_taps = [
    [ 13,  22,  39,  23,  12],
    [ -1,  36,  64,  27,  -6],
    [ -7,  10,  55,  43,  17],
    [  1,   1,   8,   1,   1],
    [  6, -11,  74,  53,  -9],
    [-12,  55,  76, -12,   8],
    [ -3,   3,  93,  27,  -4],
    [ 26,  39,  59,   3,  -8],
    [  2,   0,  77,  11,   9],
    [ -8,  22,  44,  -6,   7],
    [ 40,   9,  26,   3,   9],
    [ -7,  20, 101,  -7,   4],
    [  3,  -8,  42,  26,   0],
    [-15,  33,  68,   2,  23],
    [ -2,  55,  46,  -2,  15],
    [  3,  -1,  21,  16,  41]
];

static immutable int8_t[5][32] silk_ltp_filter2_taps = [
    [ -6,  27,  61,  39,   5],
    [-11,  42,  88,   4,   1],
    [ -2,  60,  65,   6,  -4],
    [ -1,  -5,  73,  56,   1],
    [ -9,  19,  94,  29,  -9],
    [  0,  12,  99,   6,   4],
    [  8, -19, 102,  46, -13],
    [  3,   2,  13,   3,   2],
    [  9, -21,  84,  72, -18],
    [-11,  46, 104, -22,   8],
    [ 18,  38,  48,  23,   0],
    [-16,  70,  83, -21,  11],
    [  5, -11, 117,  22,  -8],
    [ -6,  23, 117, -12,   3],
    [  3,  -8,  95,  28,   4],
    [-10,  15,  77,  60, -15],
    [ -1,   4, 124,   2,  -4],
    [  3,  38,  84,  24, -25],
    [  2,  13,  42,  13,  31],
    [ 21,  -4,  56,  46,  -1],
    [ -1,  35,  79, -13,  19],
    [ -7,  65,  88,  -9, -14],
    [ 20,   4,  81,  49, -29],
    [ 20,   0,  75,   3, -17],
    [  5,  -9,  44,  92,  -8],
    [  1,  -3,  22,  69,  31],
    [ -6,  95,  41, -12,   5],
    [ 39,  67,  16,  -4,   1],
    [  0,  -6, 120,  55, -36],
    [-13,  44, 122,   4, -24],
    [ 81,   5,  11,   3,   7],
    [  2,   0,   9,  10,  88]
];

static immutable uint16_t[3] silk_ltp_scale_factor = [15565, 12288, 8192];

static immutable uint8_t[2][3] silk_shell_blocks = [
    [ 5, 10], // NB
    [ 8, 15], // MB
    [10, 20]  // WB
];

static immutable uint8_t[2][2] silk_quant_offset = [ /* (0.23) */
    [25, 60], // Inactive or Unvoiced
    [ 8, 25]  // Voiced
];

static immutable int[3] silk_stereo_interp_len = [
    64, 96, 128
];


/*static inline*/ void silk_stabilize_lsf(int16_t* nlsf/*[16]*/, int order, const(uint16_t)* min_delta/*[17]*/)
{
    int pass, i;
    for (pass = 0; pass < 20; pass++) {
        int k, min_diff = 0;
        for (i = 0; i < order+1; i++) {
            int low  = i != 0     ? nlsf[i-1] : 0;
            int high = i != order ? nlsf[i]   : 32768;
            int diff = (high - low) - (min_delta[i]);

            if (diff < min_diff) {
                min_diff = diff;
                k = i;

                if (pass == 20)
                    break;
            }
        }
        if (min_diff == 0) /* no issues; stabilized */
            return;

        /* wiggle one or two LSFs */
        if (k == 0) {
            /* repel away from lower bound */
            nlsf[0] = min_delta[0];
        } else if (k == order) {
            /* repel away from higher bound */
            nlsf[order-1] = cast(short)(32768 - min_delta[order]);
        } else {
            /* repel away from current position */
            int min_center = 0, max_center = 32768, center_val;

            /* lower extent */
            for (i = 0; i < k; i++)
                min_center += min_delta[i];
            min_center += min_delta[k] >> 1;

            /* upper extent */
            for (i = order; i > k; i--)
                max_center -= min_delta[i];
            max_center -= min_delta[k] >> 1;

            /* move apart */
            center_val = nlsf[k - 1] + nlsf[k];
            center_val = (center_val >> 1) + (center_val & 1); // rounded divide by 2
            center_val = FFMIN(max_center, FFMAX(min_center, center_val));

            nlsf[k - 1] = cast(short)(center_val - (min_delta[k] >> 1));
            nlsf[k]     = cast(short)(nlsf[k - 1] + min_delta[k]);
        }
    }

    /* resort to the fall-back method, the standard method for LSF stabilization */

    /* sort; as the LSFs should be nearly sorted, use insertion sort */
    for (i = 1; i < order; i++) {
        int j, value = nlsf[i];
        for (j = i - 1; j >= 0 && nlsf[j] > value; j--)
            nlsf[j + 1] = nlsf[j];
        nlsf[j + 1] = cast(short)value;
    }

    /* push forwards to increase distance */
    if (nlsf[0] < min_delta[0])
        nlsf[0] = min_delta[0];
    for (i = 1; i < order; i++)
        if (nlsf[i] < nlsf[i - 1] + min_delta[i])
            nlsf[i] = cast(short)(nlsf[i - 1] + min_delta[i]);

    /* push backwards to increase distance */
    if (nlsf[order-1] > 32768 - min_delta[order])
        nlsf[order-1] = cast(short)(32768 - min_delta[order]);
    for (i = order-2; i >= 0; i--)
        if (nlsf[i] > nlsf[i + 1] - min_delta[i+1])
            nlsf[i] = cast(short)(nlsf[i + 1] - min_delta[i+1]);

    return;
}

/*static inline*/ int silk_is_lpc_stable(const(int16_t)* lpc/*[16]*/, int order)
{
    int k, j, DC_resp = 0;
    int32_t[16][2] lpc32;       // Q24
    int totalinvgain = 1 << 30; // 1.0 in Q30
    int32_t *row = lpc32[0].ptr;
    int32_t *prevrow;

    /* initialize the first row for the Levinson recursion */
    for (k = 0; k < order; k++) {
        DC_resp += lpc[k];
        row[k] = lpc[k] * 4096;
    }

    if (DC_resp >= 4096)
        return 0;

    /* check if prediction gain pushes any coefficients too far */
    for (k = order - 1; 1; k--) {
        int rc;      // Q31; reflection coefficient
        int gaindiv; // Q30; inverse of the gain (the divisor)
        int gain;    // gain for this reflection coefficient
        int fbits;   // fractional bits used for the gain
        int error;   // Q29; estimate of the error of our partial estimate of 1/gaindiv

        if (FFABS(row[k]) > 16773022)
            return 0;

        rc      = -(row[k] * 128);
        gaindiv = (1 << 30) - MULH(rc, rc);

        totalinvgain = MULH(totalinvgain, gaindiv) << 2;
        if (k == 0)
            return (totalinvgain >= 107374);

        /* approximate 1.0/gaindiv */
        fbits = opus_ilog(gaindiv);
        gain  = ((1 << 29) - 1) / (gaindiv >> (fbits + 1 - 16)); // Q<fbits-16>
        error = cast(int)((1 << 29) - MULL(gaindiv << (15 + 16 - fbits), gain, 16));
        gain  = ((gain << 16) + (error * gain >> 13));

        /* switch to the next row of the LPC coefficients */
        prevrow = row;
        row = lpc32[k & 1].ptr;

        for (j = 0; j < k; j++) {
            int x = cast(int)(prevrow[j] - ROUND_MULL(prevrow[k - j - 1], rc, 31));
            row[j] = cast(int)(ROUND_MULL(x, gain, fbits));
        }
    }
}

static void silk_lsp2poly(const(int32_t)* lsp/*[16]*/, int32_t* pol/*[16]*/, int half_order)
{
    int i, j;

    pol[0] = 65536; // 1.0 in Q16
    pol[1] = -lsp[0];

    for (i = 1; i < half_order; i++) {
        pol[i + 1] = cast(int)(pol[i - 1] * 2 - ROUND_MULL(lsp[2 * i], pol[i], 16));
        for (j = i; j > 1; j--)
            pol[j] += pol[j - 2] - ROUND_MULL(lsp[2 * i], pol[j - 1], 16);

        pol[1] -= lsp[2 * i];
    }
}

static void silk_lsf2lpc(const(int16_t)* nlsf/*[16]*/, float* lpcf/*[16]*/, int order)
{
    int i, k;
    int32_t[16] lsp;     // Q17; 2*cos(LSF)
    int32_t[9] p, q;     // Q16
    int32_t[16] lpc32;   // Q17
    int16_t[16] lpc;     // Q12

    /* convert the LSFs to LSPs, i.e. 2*cos(LSF) */
    for (k = 0; k < order; k++) {
        int index = nlsf[k] >> 8;
        int offset = nlsf[k] & 255;
        int k2 = (order == 10) ? silk_lsf_ordering_nbmb[k] : silk_lsf_ordering_wb[k];

        /* interpolate and round */
        lsp[k2]  = silk_cosine[index] * 256;
        lsp[k2] += (silk_cosine[index + 1] - silk_cosine[index]) * offset;
        lsp[k2]  = (lsp[k2] + 4) >> 3;
    }

    silk_lsp2poly(lsp.ptr    , p.ptr, order >> 1);
    silk_lsp2poly(lsp.ptr + 1, q.ptr, order >> 1);

    /* reconstruct A(z) */
    for (k = 0; k < order>>1; k++) {
        lpc32[k]         = -p[k + 1] - p[k] - q[k + 1] + q[k];
        lpc32[order-k-1] = -p[k + 1] - p[k] + q[k + 1] - q[k];
    }

    /* limit the range of the LPC coefficients to each fit within an int16_t */
    for (i = 0; i < 10; i++) {
        int j;
        uint maxabs = 0;
        for (j = 0, k = 0; j < order; j++) {
            uint x = FFABS(lpc32[k]);
            if (x > maxabs) {
                maxabs = x; // Q17
                k      = j;
            }
        }

        maxabs = (maxabs + 16) >> 5; // convert to Q12

        if (maxabs > 32767) {
            /* perform bandwidth expansion */
            uint chirp, chirp_base; // Q16
            maxabs = FFMIN(maxabs, 163838); // anything above this overflows chirp's numerator
            chirp_base = chirp = 65470 - ((maxabs - 32767) << 14) / ((maxabs * (k+1)) >> 2);

            for (k = 0; k < order; k++) {
                lpc32[k] = cast(int)(ROUND_MULL(lpc32[k], chirp, 16));
                chirp    = (chirp_base * chirp + 32768) >> 16;
            }
        } else break;
    }

    if (i == 10) {
        /* time's up: just clamp */
        for (k = 0; k < order; k++) {
            int x = (lpc32[k] + 16) >> 5;
            lpc[k] = av_clip_int16(x);
            lpc32[k] = lpc[k] << 5; // shortcut mandated by the spec; drops lower 5 bits
        }
    } else {
        for (k = 0; k < order; k++)
            lpc[k] = cast(short)((lpc32[k] + 16) >> 5);
    }

    /* if the prediction gain causes the LPC filter to become unstable,
       apply further bandwidth expansion on the Q17 coefficients */
    for (i = 1; i <= 16 && !silk_is_lpc_stable(lpc.ptr, order); i++) {
        uint chirp, chirp_base;
        chirp_base = chirp = 65536 - (1 << i);

        for (k = 0; k < order; k++) {
            lpc32[k] = cast(int)(ROUND_MULL(lpc32[k], chirp, 16));
            lpc[k]   = cast(short)((lpc32[k] + 16) >> 5);
            chirp    = (chirp_base * chirp + 32768) >> 16;
        }
    }

    for (i = 0; i < order; i++)
        lpcf[i] = lpc[i] / 4096.0f;
}

/*static inline*/ void silk_decode_lpc(SilkContext *s, SilkFrame *frame,
                                   OpusRangeCoder *rc,
                                   float* lpc_leadin/*[16]*/, float* lpc/*[16]*/,
                                   int *lpc_order, int *has_lpc_leadin, int voiced)
{
    import core.stdc.string : memcpy;
    int i;
    int order;                   // order of the LP polynomial; 10 for NB/MB and 16 for WB
    int8_t lsf_i1;
    int8_t[16]  lsf_i2;  // stage-1 and stage-2 codebook indices
    int16_t[16] lsf_res;         // residual as a Q10 value
    int16_t[16] nlsf;            // Q15

    *lpc_order = order = s.wb ? 16 : 10;

    /* obtain LSF stage-1 and stage-2 indices */
    lsf_i1 = cast(byte)opus_rc_getsymbol(rc, silk_model_lsf_s1[s.wb][voiced].ptr);
    for (i = 0; i < order; i++) {
        int index = s.wb ? silk_lsf_s2_model_sel_wb  [lsf_i1][i] :
                            silk_lsf_s2_model_sel_nbmb[lsf_i1][i];
        lsf_i2[i] = cast(byte)(opus_rc_getsymbol(rc, silk_model_lsf_s2[index].ptr) - 4);
        if (lsf_i2[i] == -4)
            lsf_i2[i] -= opus_rc_getsymbol(rc, silk_model_lsf_s2_ext.ptr);
        else if (lsf_i2[i] == 4)
            lsf_i2[i] += opus_rc_getsymbol(rc, silk_model_lsf_s2_ext.ptr);
    }

    /* reverse the backwards-prediction step */
    for (i = order - 1; i >= 0; i--) {
        int qstep = s.wb ? 9830 : 11796;

        lsf_res[i] = cast(short)(lsf_i2[i] * 1024);
        if (lsf_i2[i] < 0)      lsf_res[i] += 102;
        else if (lsf_i2[i] > 0) lsf_res[i] -= 102;
        lsf_res[i] = (lsf_res[i] * qstep) >> 16;

        if (i + 1 < order) {
            int weight = s.wb ? silk_lsf_pred_weights_wb  [silk_lsf_weight_sel_wb  [lsf_i1][i]][i] :
                                 silk_lsf_pred_weights_nbmb[silk_lsf_weight_sel_nbmb[lsf_i1][i]][i];
            lsf_res[i] += (lsf_res[i+1] * weight) >> 8;
        }
    }

    /* reconstruct the NLSF coefficients from the supplied indices */
    for (i = 0; i < order; i++) {
        const uint8_t * codebook = s.wb ? silk_lsf_codebook_wb[lsf_i1].ptr : silk_lsf_codebook_nbmb[lsf_i1].ptr;
        int cur, prev, next, weight_sq, weight, ipart, fpart, y, value;

        /* find the weight of the residual */
        /* TODO: precompute */
        cur = codebook[i];
        prev = i ? codebook[i - 1] : 0;
        next = i + 1 < order ? codebook[i + 1] : 256;
        weight_sq = (1024 / (cur - prev) + 1024 / (next - cur)) << 16;

        /* approximate square-root with mandated fixed-point arithmetic */
        ipart = opus_ilog(weight_sq);
        fpart = (weight_sq >> (ipart-8)) & 127;
        y = ((ipart & 1) ? 32768 : 46214) >> ((32 - ipart)>>1);
        weight = y + ((213 * fpart * y) >> 16);

        value = cur * 128 + (lsf_res[i] * 16384) / weight;
        nlsf[i] = cast(short)av_clip_uintp2(value, 15);
    }

    /* stabilize the NLSF coefficients */
    silk_stabilize_lsf(nlsf.ptr, order, s.wb ? silk_lsf_min_spacing_wb.ptr : silk_lsf_min_spacing_nbmb.ptr);

    /* produce an interpolation for the first 2 subframes, */
    /* and then convert both sets of NLSFs to LPC coefficients */
    *has_lpc_leadin = 0;
    if (s.subframes == 4) {
        int offset = opus_rc_getsymbol(rc, silk_model_lsf_interpolation_offset.ptr);
        if (offset != 4 && frame.coded) {
            *has_lpc_leadin = 1;
            if (offset != 0) {
                int16_t[16] nlsf_leadin;
                for (i = 0; i < order; i++)
                    nlsf_leadin[i] = cast(short)(frame.nlsf[i] + ((nlsf[i] - frame.nlsf[i]) * offset >> 2));
                silk_lsf2lpc(nlsf_leadin.ptr, lpc_leadin, order);
            } else  /* avoid re-computation for a (roughly) 1-in-4 occurrence */
                memcpy(lpc_leadin, frame.lpc.ptr, 16 * float.sizeof);
        } else
            offset = 4;
        s.nlsf_interp_factor = offset;

        silk_lsf2lpc(nlsf.ptr, lpc, order);
    } else {
        s.nlsf_interp_factor = 4;
        silk_lsf2lpc(nlsf.ptr, lpc, order);
    }

    memcpy(frame.nlsf.ptr, nlsf.ptr, order * nlsf[0].sizeof);
    memcpy(frame.lpc.ptr,  lpc,  order * lpc[0].sizeof);
}

/*static inline*/ void silk_count_children(OpusRangeCoder *rc, int model, int32_t total, int32_t* child/*[2]*/)
{
    if (total != 0) {
        child[0] = opus_rc_getsymbol(rc, silk_model_pulse_location[model].ptr + (((total - 1 + 5) * (total - 1)) >> 1));
        child[1] = total - child[0];
    } else {
        child[0] = 0;
        child[1] = 0;
    }
}

/*static inline*/ void silk_decode_excitation(SilkContext *s, OpusRangeCoder *rc,
                                          float* excitationf,
                                          int qoffset_high, int active, int voiced)
{
    import core.stdc.string : memset;
    int i;
    uint32_t seed;
    int shellblocks;
    int ratelevel;
    uint8_t[20] pulsecount;     // total pulses in each shell block
    uint8_t[20] lsbcount = 0;   // raw lsbits defined for each pulse in each shell block
    int32_t[320] excitation;    // Q23

    /* excitation parameters */
    seed = opus_rc_getsymbol(rc, silk_model_lcg_seed.ptr);
    shellblocks = silk_shell_blocks[s.bandwidth][s.subframes >> 2];
    ratelevel = opus_rc_getsymbol(rc, silk_model_exc_rate[voiced].ptr);

    for (i = 0; i < shellblocks; i++) {
        pulsecount[i] = cast(ubyte)opus_rc_getsymbol(rc, silk_model_pulse_count[ratelevel].ptr);
        if (pulsecount[i] == 17) {
            while (pulsecount[i] == 17 && ++lsbcount[i] != 10)
                pulsecount[i] = cast(ubyte)opus_rc_getsymbol(rc, silk_model_pulse_count[9].ptr);
            if (lsbcount[i] == 10)
                pulsecount[i] = cast(ubyte)opus_rc_getsymbol(rc, silk_model_pulse_count[10].ptr);
        }
    }

    /* decode pulse locations using PVQ */
    for (i = 0; i < shellblocks; i++) {
        if (pulsecount[i] != 0) {
            int a, b, c, d;
            int32_t * location = excitation.ptr + 16*i;
            int32_t[2][4] branch;
            branch[0][0] = pulsecount[i];

            /* unrolled tail recursion */
            for (a = 0; a < 1; a++) {
                silk_count_children(rc, 0, branch[0][a], branch[1].ptr);
                for (b = 0; b < 2; b++) {
                    silk_count_children(rc, 1, branch[1][b], branch[2].ptr);
                    for (c = 0; c < 2; c++) {
                        silk_count_children(rc, 2, branch[2][c], branch[3].ptr);
                        for (d = 0; d < 2; d++) {
                            silk_count_children(rc, 3, branch[3][d], location);
                            location += 2;
                        }
                    }
                }
            }
        } else
            memset(excitation.ptr + 16*i, 0, 16*int32_t.sizeof);
    }

    /* decode least significant bits */
    for (i = 0; i < shellblocks << 4; i++) {
        int bit;
        for (bit = 0; bit < lsbcount[i >> 4]; bit++)
            excitation[i] = (excitation[i] << 1) |
                            opus_rc_getsymbol(rc, silk_model_excitation_lsb.ptr);
    }

    /* decode signs */
    for (i = 0; i < shellblocks << 4; i++) {
        if (excitation[i] != 0) {
            int sign = opus_rc_getsymbol(rc, silk_model_excitation_sign[active + voiced][qoffset_high][FFMIN(pulsecount[i >> 4], 6)].ptr);
            if (sign == 0)
                excitation[i] *= -1;
        }
    }

    /* assemble the excitation */
    for (i = 0; i < shellblocks << 4; i++) {
        int value = excitation[i];
        excitation[i] = value * 256 | silk_quant_offset[voiced][qoffset_high];
        if (value < 0)      excitation[i] += 20;
        else if (value > 0) excitation[i] -= 20;

        /* invert samples pseudorandomly */
        seed = 196314165 * seed + 907633515;
        if (seed & 0x80000000)
            excitation[i] *= -1;
        seed += value;

        excitationf[i] = excitation[i] / 8388608.0f;
    }
}

/** Maximum residual history according to 4.2.7.6.1 */
enum SILK_MAX_LAG = (288 + LTP_ORDER / 2);

/** Order of the LTP filter */
enum LTP_ORDER = 5;

static void silk_decode_frame(SilkContext *s, OpusRangeCoder *rc,
                              int frame_num, int channel, int coded_channels, int active, int active1)
{
    import core.stdc.string : memmove;
    /* per frame */
    int voiced;       // combines with active to indicate inactive, active, or active+voiced
    int qoffset_high;
    int order;                             // order of the LPC coefficients
    float[16] lpc_leadin;
    float[16] lpc_body;
    float[SILK_MAX_LAG + SILK_HISTORY] residual;
    int has_lpc_leadin;
    float ltpscale;

    /* per subframe */
    static struct SF {
        float gain;
        int pitchlag;
        float[5] ltptaps;
    }
    SF[4] sf = void;

    //const(SilkFrame)* frame = s.frame.ptr + channel;
    SilkFrame* frame = s.frame.ptr + channel;

    int i;

    /* obtain stereo weights */
    if (coded_channels == 2 && channel == 0) {
        int n;
        int[2] wi, ws, w;
        n     = opus_rc_getsymbol(rc, silk_model_stereo_s1.ptr);
        wi[0] = opus_rc_getsymbol(rc, silk_model_stereo_s2.ptr) + 3 * (n / 5);
        ws[0] = opus_rc_getsymbol(rc, silk_model_stereo_s3.ptr);
        wi[1] = opus_rc_getsymbol(rc, silk_model_stereo_s2.ptr) + 3 * (n % 5);
        ws[1] = opus_rc_getsymbol(rc, silk_model_stereo_s3.ptr);

        for (i = 0; i < 2; i++)
            w[i] = silk_stereo_weights[wi[i]] +
                   (((silk_stereo_weights[wi[i] + 1] - silk_stereo_weights[wi[i]]) * 6554) >> 16)
                    * (ws[i]*2 + 1);

        s.stereo_weights[0] = (w[0] - w[1]) / 8192.0;
        s.stereo_weights[1] = w[1]          / 8192.0;

        /* and read the mid-only flag */
        s.midonly = active1 ? 0 : opus_rc_getsymbol(rc, silk_model_mid_only.ptr);
    }

    /* obtain frame type */
    if (!active) {
        qoffset_high = opus_rc_getsymbol(rc, silk_model_frame_type_inactive.ptr);
        voiced = 0;
    } else {
        int type = opus_rc_getsymbol(rc, silk_model_frame_type_active.ptr);
        qoffset_high = type & 1;
        voiced = type >> 1;
    }

    /* obtain subframe quantization gains */
    for (i = 0; i < s.subframes; i++) {
        int log_gain;     //Q7
        int ipart, fpart, lingain;

        if (i == 0 && (frame_num == 0 || !frame.coded)) {
            /* gain is coded absolute */
            int x = opus_rc_getsymbol(rc, silk_model_gain_highbits[active + voiced].ptr);
            log_gain = (x<<3) | opus_rc_getsymbol(rc, silk_model_gain_lowbits.ptr);

            if (frame.coded)
                log_gain = FFMAX(log_gain, frame.log_gain - 16);
        } else {
            /* gain is coded relative */
            int delta_gain = opus_rc_getsymbol(rc, silk_model_gain_delta.ptr);
            log_gain = av_clip_uintp2(FFMAX((delta_gain<<1) - 16,
                                     frame.log_gain + delta_gain - 4), 6);
        }

        frame.log_gain = log_gain;

        /* approximate 2**(x/128) with a Q7 (i.e. non-integer) input */
        log_gain = (log_gain * 0x1D1C71 >> 16) + 2090;
        ipart = log_gain >> 7;
        fpart = log_gain & 127;
        lingain = (1 << ipart) + ((-174 * fpart * (128-fpart) >>16) + fpart) * ((1<<ipart) >> 7);
        sf[i].gain = lingain / 65536.0f;
    }

    /* obtain LPC filter coefficients */
    silk_decode_lpc(s, frame, rc, lpc_leadin.ptr, lpc_body.ptr, &order, &has_lpc_leadin, voiced);

    /* obtain pitch lags, if this is a voiced frame */
    if (voiced) {
        int lag_absolute = (!frame_num || !frame.prev_voiced);
        int primarylag;         // primary pitch lag for the entire SILK frame
        int ltpfilter;
        const(int8_t)* offsets;

        if (!lag_absolute) {
            int delta = opus_rc_getsymbol(rc, silk_model_pitch_delta.ptr);
            if (delta)
                primarylag = frame.primarylag + delta - 9;
            else
                lag_absolute = 1;
        }

        if (lag_absolute) {
            /* primary lag is coded absolute */
            int highbits, lowbits;
            static immutable uint16_t*[3] model = [
                silk_model_pitch_lowbits_nb.ptr, silk_model_pitch_lowbits_mb.ptr,
                silk_model_pitch_lowbits_wb.ptr
            ];
            highbits = opus_rc_getsymbol(rc, silk_model_pitch_highbits.ptr);
            lowbits  = opus_rc_getsymbol(rc, model[s.bandwidth]);

            primarylag = silk_pitch_min_lag[s.bandwidth] +
                         highbits*silk_pitch_scale[s.bandwidth] + lowbits;
        }
        frame.primarylag = primarylag;

        if (s.subframes == 2)
            offsets = (s.bandwidth == OPUS_BANDWIDTH_NARROWBAND)
                     ? silk_pitch_offset_nb10ms[opus_rc_getsymbol(rc, silk_model_pitch_contour_nb10ms.ptr)].ptr
                     : silk_pitch_offset_mbwb10ms[opus_rc_getsymbol(rc, silk_model_pitch_contour_mbwb10ms.ptr)].ptr;
        else
            offsets = (s.bandwidth == OPUS_BANDWIDTH_NARROWBAND)
                     ? silk_pitch_offset_nb20ms[opus_rc_getsymbol(rc, silk_model_pitch_contour_nb20ms.ptr)].ptr
                     : silk_pitch_offset_mbwb20ms[opus_rc_getsymbol(rc, silk_model_pitch_contour_mbwb20ms.ptr)].ptr;

        for (i = 0; i < s.subframes; i++)
            sf[i].pitchlag = av_clip(primarylag + offsets[i],
                                     silk_pitch_min_lag[s.bandwidth],
                                     silk_pitch_max_lag[s.bandwidth]);

        /* obtain LTP filter coefficients */
        ltpfilter = opus_rc_getsymbol(rc, silk_model_ltp_filter.ptr);
        for (i = 0; i < s.subframes; i++) {
            int index, j;
            static immutable uint16_t*[3] filter_sel = [
                silk_model_ltp_filter0_sel.ptr, silk_model_ltp_filter1_sel.ptr,
                silk_model_ltp_filter2_sel.ptr
            ];
            static immutable int8_t[5]*[3] /*(*filter_taps[])[5]*/ filter_taps = [
                silk_ltp_filter0_taps.ptr, silk_ltp_filter1_taps.ptr, silk_ltp_filter2_taps.ptr
            ];
            index = opus_rc_getsymbol(rc, filter_sel[ltpfilter]);
            for (j = 0; j < 5; j++)
                sf[i].ltptaps[j] = filter_taps[ltpfilter][index][j] / 128.0f;
        }
    }

    /* obtain LTP scale factor */
    if (voiced && frame_num == 0)
        ltpscale = silk_ltp_scale_factor[opus_rc_getsymbol(rc, silk_model_ltp_scale_index.ptr)] / 16384.0f;
    else ltpscale = 15565.0f/16384.0f;

    /* generate the excitation signal for the entire frame */
    silk_decode_excitation(s, rc, residual.ptr + SILK_MAX_LAG, qoffset_high, active, voiced);

    /* skip synthesising the side channel if we want mono-only */
    if (s.output_channels == channel)
        return;

    /* generate the output signal */
    for (i = 0; i < s.subframes; i++) {
        const(float)* lpc_coeff = (i < 2 && has_lpc_leadin) ? lpc_leadin.ptr : lpc_body.ptr;
        float *dst    = frame.output.ptr      + SILK_HISTORY + i * s.sflength;
        float *resptr = residual.ptr           + SILK_MAX_LAG + i * s.sflength;
        float *lpc    = frame.lpc_history.ptr + SILK_HISTORY + i * s.sflength;
        float sum;
        int j, k;

        if (voiced) {
            int out_end;
            float scale;

            if (i < 2 || s.nlsf_interp_factor == 4) {
                out_end = -i * s.sflength;
                scale   = ltpscale;
            } else {
                out_end = -(i - 2) * s.sflength;
                scale   = 1.0f;
            }

            /* when the LPC coefficients change, a re-whitening filter is used */
            /* to produce a residual that accounts for the change */
            for (j = - sf[i].pitchlag - LTP_ORDER/2; j < out_end; j++) {
                sum = dst[j];
                for (k = 0; k < order; k++)
                    sum -= lpc_coeff[k] * dst[j - k - 1];
                resptr[j] = av_clipf(sum, -1.0f, 1.0f) * scale / sf[i].gain;
            }

            if (out_end) {
                float rescale = sf[i-1].gain / sf[i].gain;
                for (j = out_end; j < 0; j++)
                    resptr[j] *= rescale;
            }

            /* LTP synthesis */
            for (j = 0; j < s.sflength; j++) {
                sum = resptr[j];
                for (k = 0; k < LTP_ORDER; k++)
                    sum += sf[i].ltptaps[k] * resptr[j - sf[i].pitchlag + LTP_ORDER/2 - k];
                resptr[j] = sum;
            }
        }

        /* LPC synthesis */
        for (j = 0; j < s.sflength; j++) {
            sum = resptr[j] * sf[i].gain;
            for (k = 1; k <= order; k++)
                sum += lpc_coeff[k - 1] * lpc[j - k];

            lpc[j] = sum;
            dst[j] = av_clipf(sum, -1.0f, 1.0f);
        }
    }

    frame.prev_voiced = voiced;
    memmove(frame.lpc_history.ptr, frame.lpc_history.ptr + s.flength, SILK_HISTORY * float.sizeof);
    memmove(frame.output.ptr,      frame.output.ptr      + s.flength, SILK_HISTORY * float.sizeof);

    frame.coded = 1;
}

static void silk_unmix_ms(SilkContext *s, float *l, float *r)
{
    import core.stdc.string : memcpy;
    float *mid    = s.frame[0].output.ptr + SILK_HISTORY - s.flength;
    float *side   = s.frame[1].output.ptr + SILK_HISTORY - s.flength;
    float w0_prev = s.prev_stereo_weights[0];
    float w1_prev = s.prev_stereo_weights[1];
    float w0      = s.stereo_weights[0];
    float w1      = s.stereo_weights[1];
    int n1        = silk_stereo_interp_len[s.bandwidth];
    int i;

    for (i = 0; i < n1; i++) {
        float interp0 = w0_prev + i * (w0 - w0_prev) / n1;
        float interp1 = w1_prev + i * (w1 - w1_prev) / n1;
        float p0      = 0.25 * (mid[i - 2] + 2 * mid[i - 1] + mid[i]);

        l[i] = av_clipf((1 + interp1) * mid[i - 1] + side[i - 1] + interp0 * p0, -1.0, 1.0);
        r[i] = av_clipf((1 - interp1) * mid[i - 1] - side[i - 1] - interp0 * p0, -1.0, 1.0);
    }

    for (; i < s.flength; i++) {
        float p0 = 0.25 * (mid[i - 2] + 2 * mid[i - 1] + mid[i]);

        l[i] = av_clipf((1 + w1) * mid[i - 1] + side[i - 1] + w0 * p0, -1.0, 1.0);
        r[i] = av_clipf((1 - w1) * mid[i - 1] - side[i - 1] - w0 * p0, -1.0, 1.0);
    }

    memcpy(s.prev_stereo_weights.ptr, s.stereo_weights.ptr, s.stereo_weights.sizeof);
}

static void silk_flush_frame(SilkFrame *frame)
{
    import core.stdc.string : memset;
    if (!frame.coded)
        return;

    memset(frame.output.ptr,      0, frame.output.sizeof);
    memset(frame.lpc_history.ptr, 0, frame.lpc_history.sizeof);

    memset(frame.lpc.ptr,  0, frame.lpc.sizeof);
    memset(frame.nlsf.ptr, 0, frame.nlsf.sizeof);

    frame.log_gain = 0;

    frame.primarylag  = 0;
    frame.prev_voiced = 0;
    frame.coded       = 0;
}

int ff_silk_decode_superframe(SilkContext *s, OpusRangeCoder *rc,
                              float** output/*[2]*/,
                              OpusBandwidth bandwidth,
                              int coded_channels,
                              int duration_ms)
{
    import core.stdc.string : memcpy;
    int[6][2] active;
    int[2] redundancy;
    int nb_frames, i, j;

    if (bandwidth > OPUS_BANDWIDTH_WIDEBAND ||
        coded_channels > 2 || duration_ms > 60) {
        //av_log(s.avctx, AV_LOG_ERROR, "Invalid parameters passed to the SILK decoder.\n");
        return AVERROR(EINVAL);
    }

    nb_frames = 1 + (duration_ms > 20) + (duration_ms > 40);
    s.subframes = duration_ms / nb_frames / 5;         // 5ms subframes
    s.sflength  = 20 * (bandwidth + 2);
    s.flength   = s.sflength * s.subframes;
    s.bandwidth = bandwidth;
    s.wb        = bandwidth == OPUS_BANDWIDTH_WIDEBAND;

    /* make sure to flush the side channel when switching from mono to stereo */
    if (coded_channels > s.prev_coded_channels)
        silk_flush_frame(&s.frame[1]);
    s.prev_coded_channels = coded_channels;

    /* read the LP-layer header bits */
    for (i = 0; i < coded_channels; i++) {
        for (j = 0; j < nb_frames; j++)
            active[i][j] = opus_rc_p2model(rc, 1);

        redundancy[i] = opus_rc_p2model(rc, 1);
        if (redundancy[i]) {
            //av_log(s.avctx, AV_LOG_ERROR, "LBRR frames present; this is unsupported\n");
            return AVERROR_PATCHWELCOME;
        }
    }

    for (i = 0; i < nb_frames; i++) {
        for (j = 0; j < coded_channels && !s.midonly; j++)
            silk_decode_frame(s, rc, i, j, coded_channels, active[j][i], active[1][i]);

        /* reset the side channel if it is not coded */
        if (s.midonly && s.frame[1].coded)
            silk_flush_frame(&s.frame[1]);

        if (coded_channels == 1 || s.output_channels == 1) {
            for (j = 0; j < s.output_channels; j++) {
                memcpy(output[j] + i * s.flength, s.frame[0].output.ptr + SILK_HISTORY - s.flength - 2, s.flength * float.sizeof);
            }
        } else {
            silk_unmix_ms(s, output[0] + i * s.flength, output[1] + i * s.flength);
        }

        s.midonly        = 0;
    }

    return nb_frames * s.flength;
}

void ff_silk_free(SilkContext **ps)
{
    av_freep(ps);
}

void ff_silk_flush(SilkContext *s)
{
    import core.stdc.string : memset;
    silk_flush_frame(&s.frame[0]);
    silk_flush_frame(&s.frame[1]);

    memset(s.prev_stereo_weights.ptr, 0, s.prev_stereo_weights.sizeof);
}

int ff_silk_init(/*AVCodecContext *avctx,*/ SilkContext **ps, int output_channels)
{
    SilkContext *s;

    if (output_channels != 1 && output_channels != 2) {
        //av_log(avctx, AV_LOG_ERROR, "Invalid number of output channels: %d\n", output_channels);
        return AVERROR(EINVAL);
    }

    s = av_mallocz!SilkContext();
    if (!s)
        return AVERROR(ENOMEM);

    //s.avctx           = avctx;
    s.output_channels = output_channels;

    ff_silk_flush(s);

    *ps = s;

    return 0;
}


version = sincresample_use_full_table;
version(X86) {
  version(D_PIC) {} else version = sincresample_use_sse;
}


// ////////////////////////////////////////////////////////////////////////// //
public struct OpusResampler {
nothrow @nogc:
public:
  alias Quality = int;
  enum : uint {
    Fastest = 0,
    Voip = 3,
    Default = 4,
    Desktop = 5,
    Best = 10,
  }

  enum Error {
    OK = 0,
    NoMemory,
    BadState,
    BadArgument,
    BadData,
  }

private:
nothrow @trusted @nogc:
  alias ResamplerFn = int function (ref OpusResampler st, uint chanIdx, const(float)* indata, uint *indataLen, float *outdata, uint *outdataLen);

private:
  uint inRate;
  uint outRate;
  uint numRate; // from
  uint denRate; // to

  Quality srQuality;
  uint chanCount;
  uint filterLen;
  uint memAllocSize;
  uint bufferSize;
  int intAdvance;
  int fracAdvance;
  float cutoff;
  uint oversample;
  bool started;

  // these are per-channel
  int[64] lastSample;
  uint[64] sampFracNum;
  uint[64] magicSamples;

  float* mem;
  uint realMemLen; // how much memory really allocated
  float* sincTable;
  uint sincTableLen;
  uint realSincTableLen; // how much memory really allocated
  ResamplerFn resampler;

  int inStride;
  int outStride;

public:
  static string errorStr (int err) {
    switch (err) with (Error) {
      case OK: return "success";
      case NoMemory: return "memory allocation failed";
      case BadState: return "bad resampler state";
      case BadArgument: return "invalid argument";
      case BadData: return "bad data passed";
      default:
    }
    return "unknown error";
  }

public:
  @disable this (this);
  ~this () { deinit(); }

  bool inited () const pure { return (resampler !is null); }

  void deinit () {
    import core.stdc.stdlib : free;
    if (mem !is null) { free(mem); mem = null; }
    if (sincTable !is null) { free(sincTable); sincTable = null; }
    /*
    memAllocSize = realMemLen = 0;
    sincTableLen = realSincTableLen = 0;
    resampler = null;
    started = false;
    */
    inRate = outRate = numRate = denRate = 0;
    srQuality = cast(Quality)666;
    chanCount = 0;
    filterLen = 0;
    memAllocSize = 0;
    bufferSize = 0;
    intAdvance = 0;
    fracAdvance = 0;
    cutoff = 0;
    oversample = 0;
    started = 0;

    mem = null;
    realMemLen = 0; // how much memory really allocated
    sincTable = null;
    sincTableLen = 0;
    realSincTableLen = 0; // how much memory really allocated
    resampler = null;

    inStride = outStride = 0;
  }

  /** Create a new resampler with integer input and output rates.
   *
   * Params:
   *  chans = Number of channels to be processed
   *  inRate = Input sampling rate (integer number of Hz).
   *  outRate = Output sampling rate (integer number of Hz).
   *  aquality = Resampling quality between 0 and 10, where 0 has poor quality and 10 has very high quality.
   *
   * Returns:
   *  0 or error code
   */
  Error setup (uint chans, uint ainRate, uint aoutRate, Quality aquality/*, size_t line=__LINE__*/) {
    //{ import core.stdc.stdio; printf("init: %u -> %u at %u\n", ainRate, aoutRate, cast(uint)line); }
    import core.stdc.stdlib : malloc, free;

    deinit();
    if (aquality < 0) aquality = 0;
    if (aquality > OpusResampler.Best) aquality = OpusResampler.Best;
    if (chans < 1 || chans > 16) return Error.BadArgument;

    started = false;
    inRate = 0;
    outRate = 0;
    numRate = 0;
    denRate = 0;
    srQuality = cast(Quality)666; // it's ok
    sincTableLen = 0;
    memAllocSize = 0;
    filterLen = 0;
    mem = null;
    resampler = null;

    cutoff = 1.0f;
    chanCount = chans;
    inStride = 1;
    outStride = 1;

    bufferSize = 160;

    // per channel data
    lastSample[] = 0;
    magicSamples[] = 0;
    sampFracNum[] = 0;

    setQuality(aquality);
    setRate(ainRate, aoutRate);

    if (auto filterErr = updateFilter()) { deinit(); return filterErr; }
    skipZeros(); // make sure that the first samples to go out of the resamplers don't have leading zeros

    return Error.OK;
  }

  /** Set (change) the input/output sampling rates (integer value).
   *
   * Params:
   *  ainRate = Input sampling rate (integer number of Hz).
   *  aoutRate = Output sampling rate (integer number of Hz).
   *
   * Returns:
   *  0 or error code
   */
  Error setRate (uint ainRate, uint aoutRate/*, size_t line=__LINE__*/) {
    //{ import core.stdc.stdio; printf("changing rate: %u -> %u at %u\n", ainRate, aoutRate, cast(uint)line); }
    if (inRate == ainRate && outRate == aoutRate) return Error.OK;
    //{ import core.stdc.stdio; printf("changing rate: %u -> %u at %u\n", ratioNum, ratioDen, cast(uint)line); }

    uint oldDen = denRate;
    inRate = ainRate;
    outRate = aoutRate;
    auto div = gcd(ainRate, aoutRate);
    numRate = ainRate/div;
    denRate = aoutRate/div;

    if (oldDen > 0) {
      foreach (ref v; sampFracNum.ptr[0..chanCount]) {
        v = v*denRate/oldDen;
        // safety net
        if (v >= denRate) v = denRate-1;
      }
    }

    return (inited ? updateFilter() : Error.OK);
  }

  /** Get the current input/output sampling rates (integer value).
   *
   * Params:
   *  ainRate = Input sampling rate (integer number of Hz) copied.
   *  aoutRate = Output sampling rate (integer number of Hz) copied.
   */
  void getRate (out uint ainRate, out uint aoutRate) {
    ainRate = inRate;
    aoutRate = outRate;
  }

  uint getInRate () { return inRate; }
  uint getOutRate () { return outRate; }

  uint getChans () { return chanCount; }

  /** Get the current resampling ratio. This will be reduced to the least common denominator.
   *
   * Params:
   *  ratioNum = Numerator of the sampling rate ratio copied
   *  ratioDen = Denominator of the sampling rate ratio copied
   */
  void getRatio (out uint ratioNum, out uint ratioDen) {
    ratioNum = numRate;
    ratioDen = denRate;
  }

  /** Set (change) the conversion quality.
   *
   * Params:
   *  quality = Resampling quality between 0 and 10, where 0 has poor quality and 10 has very high quality.
   *
   * Returns:
   *  0 or error code
   */
  Error setQuality (Quality aquality) {
    if (aquality < 0) aquality = 0;
    if (aquality > OpusResampler.Best) aquality = OpusResampler.Best;
    if (srQuality == aquality) return Error.OK;
    srQuality = aquality;
    return (inited ? updateFilter() : Error.OK);
  }

  /** Get the conversion quality.
   *
   * Returns:
   *  Resampling quality between 0 and 10, where 0 has poor quality and 10 has very high quality.
   */
  int getQuality () { return srQuality; }

  /** Get the latency introduced by the resampler measured in input samples.
   *
   * Returns:
   *  Input latency;
   */
  int inputLatency () { return filterLen/2; }

  /** Get the latency introduced by the resampler measured in output samples.
   *
   * Returns:
   *  Output latency.
   */
  int outputLatency () { return ((filterLen/2)*denRate+(numRate>>1))/numRate; }

  /* Make sure that the first samples to go out of the resamplers don't have
   * leading zeros. This is only useful before starting to use a newly created
   * resampler. It is recommended to use that when resampling an audio file, as
   * it will generate a file with the same length. For real-time processing,
   * it is probably easier not to use this call (so that the output duration
   * is the same for the first frame).
   *
   * Setup/reset sequence will automatically call this, so it is private.
   */
  private void skipZeros () { foreach (immutable i; 0..chanCount) lastSample.ptr[i] = filterLen/2; }

  static struct Data {
    const(float)[] dataIn;
    float[] dataOut;
    uint inputSamplesUsed; // out value, in samples (i.e. multiplied by channel count)
    uint outputSamplesUsed; // out value, in samples (i.e. multiplied by channel count)
  }

  /** Resample (an interleaved) float array. The input and output buffers must *not* overlap.
   * `data.dataIn` can be empty, but `data.dataOut` can't.
   * Function will return number of consumed samples (*not* *frames*!) in `data.inputSamplesUsed`,
   * and number of produced samples in `data.outputSamplesUsed`.
   * You should provide enough samples for all channels, and all channels will be processed.
   *
   * Params:
   *  data = input and output buffers, number of frames consumed and produced
   *
   * Returns:
   *  0 or error code
   */
  Error process(string mode="interleaved") (ref Data data) {
    static assert(mode == "interleaved" || mode == "sequential");

    data.inputSamplesUsed = data.outputSamplesUsed = 0;
    if (!inited) return Error.BadState;

    if (data.dataIn.length%chanCount || data.dataOut.length < 1 || data.dataOut.length%chanCount) return Error.BadData;
    if (data.dataIn.length > uint.max/4 || data.dataOut.length > uint.max/4) return Error.BadData;

    static if (mode == "interleaved") {
      inStride = outStride = chanCount;
    } else {
      inStride = outStride = 1;
    }
    uint iofs = 0, oofs = 0;
    immutable uint idclen = cast(uint)(data.dataIn.length/chanCount);
    immutable uint odclen = cast(uint)(data.dataOut.length/chanCount);
    foreach (immutable i; 0..chanCount) {
      data.inputSamplesUsed = idclen;
      data.outputSamplesUsed = odclen;
      if (data.dataIn.length) {
        processOneChannel(i, data.dataIn.ptr+iofs, &data.inputSamplesUsed, data.dataOut.ptr+oofs, &data.outputSamplesUsed);
      } else {
        processOneChannel(i, null, &data.inputSamplesUsed, data.dataOut.ptr+oofs, &data.outputSamplesUsed);
      }
      static if (mode == "interleaved") {
        ++iofs;
        ++oofs;
      } else {
        iofs += idclen;
        oofs += odclen;
      }
    }
    data.inputSamplesUsed *= chanCount;
    data.outputSamplesUsed *= chanCount;
    return Error.OK;
  }


  //HACK for libswresample
  // return -1 or number of outframes
  int swrconvert (float** outbuf, int outframes, const(float)**inbuf, int inframes) {
    if (!inited || outframes < 1 || inframes < 0) return -1;
    inStride = outStride = 1;
    Data data;
    foreach (immutable i; 0..chanCount) {
      data.dataIn = (inframes ? inbuf[i][0..inframes] : null);
      data.dataOut = (outframes ? outbuf[i][0..outframes] : null);
      data.inputSamplesUsed = inframes;
      data.outputSamplesUsed = outframes;
      if (inframes > 0) {
        processOneChannel(i, data.dataIn.ptr, &data.inputSamplesUsed, data.dataOut.ptr, &data.outputSamplesUsed);
      } else {
        processOneChannel(i, null, &data.inputSamplesUsed, data.dataOut.ptr, &data.outputSamplesUsed);
      }
    }
    return data.outputSamplesUsed;
  }

  /// Reset a resampler so a new (unrelated) stream can be processed.
  void reset () {
    lastSample[] = 0;
    magicSamples[] = 0;
    sampFracNum[] = 0;
    //foreach (immutable i; 0..chanCount*(filterLen-1)) mem[i] = 0;
    if (mem !is null) mem[0..chanCount*(filterLen-1)] = 0;
    skipZeros(); // make sure that the first samples to go out of the resamplers don't have leading zeros
  }

private:
  Error processOneChannel (uint chanIdx, const(float)* indata, uint* indataLen, float* outdata, uint* outdataLen) {
    uint ilen = *indataLen;
    uint olen = *outdataLen;
    float* x = mem+chanIdx*memAllocSize;
    const int filterOfs = filterLen-1;
    const uint xlen = memAllocSize-filterOfs;
    const int istride = inStride;
    if (magicSamples.ptr[chanIdx]) olen -= magic(chanIdx, &outdata, olen);
    if (!magicSamples.ptr[chanIdx]) {
      while (ilen && olen) {
        uint ichunk = (ilen > xlen ? xlen : ilen);
        uint ochunk = olen;
        if (indata !is null) {
          foreach (immutable j; 0..ichunk) x[j+filterOfs] = indata[j*istride];
        } else {
          foreach (immutable j; 0..ichunk) x[j+filterOfs] = 0;
        }
        processNative(chanIdx, &ichunk, outdata, &ochunk);
        ilen -= ichunk;
        olen -= ochunk;
        outdata += ochunk*outStride;
        if (indata) indata += ichunk*istride;
      }
    }
    *indataLen -= ilen;
    *outdataLen -= olen;
    return Error.OK;
  }

  Error processNative (uint chanIdx, uint* indataLen, float* outdata, uint* outdataLen) {
    immutable N = filterLen;
    int outSample = 0;
    float* x = mem+chanIdx*memAllocSize;
    uint ilen;

    started = true;

    // call the right resampler through the function ptr
    outSample = resampler(this, chanIdx, x, indataLen, outdata, outdataLen);

    if (lastSample.ptr[chanIdx] < cast(int)*indataLen) *indataLen = lastSample.ptr[chanIdx];
    *outdataLen = outSample;
    lastSample.ptr[chanIdx] -= *indataLen;

    ilen = *indataLen;

    foreach (immutable j; 0..N-1) x[j] = x[j+ilen];

    return Error.OK;
  }

  int magic (uint chanIdx, float **outdata, uint outdataLen) {
    uint tempInLen = magicSamples.ptr[chanIdx];
    float* x = mem+chanIdx*memAllocSize;
    processNative(chanIdx, &tempInLen, *outdata, &outdataLen);
    magicSamples.ptr[chanIdx] -= tempInLen;
    // if we couldn't process all "magic" input samples, save the rest for next time
    if (magicSamples.ptr[chanIdx]) {
      immutable N = filterLen;
      foreach (immutable i; 0..magicSamples.ptr[chanIdx]) x[N-1+i] = x[N-1+i+tempInLen];
    }
    *outdata += outdataLen*outStride;
    return outdataLen;
  }

  Error updateFilter () {
    uint oldFilterLen = filterLen;
    uint oldAllocSize = memAllocSize;
    bool useDirect;
    uint minSincTableLen;
    uint minAllocSize;

    intAdvance = numRate/denRate;
    fracAdvance = numRate%denRate;
    oversample = qualityMap.ptr[srQuality].oversample;
    filterLen = qualityMap.ptr[srQuality].baseLength;

    if (numRate > denRate) {
      // down-sampling
      cutoff = qualityMap.ptr[srQuality].downsampleBandwidth*denRate/numRate;
      // FIXME: divide the numerator and denominator by a certain amount if they're too large
      filterLen = filterLen*numRate/denRate;
      // Round up to make sure we have a multiple of 8 for SSE
      filterLen = ((filterLen-1)&(~0x7))+8;
      if (2*denRate < numRate) oversample >>= 1;
      if (4*denRate < numRate) oversample >>= 1;
      if (8*denRate < numRate) oversample >>= 1;
      if (16*denRate < numRate) oversample >>= 1;
      if (oversample < 1) oversample = 1;
    } else {
      // up-sampling
      cutoff = qualityMap.ptr[srQuality].upsampleBandwidth;
    }

    // choose the resampling type that requires the least amount of memory
    version(sincresample_use_full_table) {
      useDirect = true;
      if (int.max/float.sizeof/denRate < filterLen) goto fail;
    } else {
      useDirect = (filterLen*denRate <= filterLen*oversample+8 && int.max/float.sizeof/denRate >= filterLen);
    }

    if (useDirect) {
      minSincTableLen = filterLen*denRate;
    } else {
      if ((int.max/float.sizeof-8)/oversample < filterLen) goto fail;
      minSincTableLen = filterLen*oversample+8;
    }

    if (sincTableLen < minSincTableLen) {
      import core.stdc.stdlib : realloc;
      auto nslen = cast(uint)(minSincTableLen*float.sizeof);
      if (nslen > realSincTableLen) {
        if (nslen < 512*1024) nslen = 512*1024; // inc to 3 mb?
        auto x = cast(float*)realloc(sincTable, nslen);
        if (!x) goto fail;
        sincTable = x;
        realSincTableLen = nslen;
      }
      sincTableLen = minSincTableLen;
    }

    if (useDirect) {
      foreach (int i; 0..denRate) {
        foreach (int j; 0..filterLen) {
          sincTable[i*filterLen+j] = sinc(cutoff, ((j-cast(int)filterLen/2+1)-(cast(float)i)/denRate), filterLen, qualityMap.ptr[srQuality].windowFunc);
        }
      }
      if (srQuality > 8) {
        resampler = &resamplerBasicDirect!double;
      } else {
        resampler = &resamplerBasicDirect!float;
      }
    } else {
      foreach (immutable int i; -4..cast(int)(oversample*filterLen+4)) {
        sincTable[i+4] = sinc(cutoff, (i/cast(float)oversample-filterLen/2), filterLen, qualityMap.ptr[srQuality].windowFunc);
      }
      if (srQuality > 8) {
        resampler = &resamplerBasicInterpolate!double;
      } else {
        resampler = &resamplerBasicInterpolate!float;
      }
    }

    /* Here's the place where we update the filter memory to take into account
       the change in filter length. It's probably the messiest part of the code
       due to handling of lots of corner cases. */

    // adding bufferSize to filterLen won't overflow here because filterLen could be multiplied by float.sizeof above
    minAllocSize = filterLen-1+bufferSize;
    if (minAllocSize > memAllocSize) {
      import core.stdc.stdlib : realloc;
      if (int.max/float.sizeof/chanCount < minAllocSize) goto fail;
      auto nslen = cast(uint)(chanCount*minAllocSize*mem[0].sizeof);
      if (nslen > realMemLen) {
        if (nslen < 16384) nslen = 16384;
        auto x = cast(float*)realloc(mem, nslen);
        if (x is null) goto fail;
        mem = x;
        realMemLen = nslen;
      }
      memAllocSize = minAllocSize;
    }
    if (!started) {
      //foreach (i=0;i<chanCount*memAllocSize;i++) mem[i] = 0;
      mem[0..chanCount*memAllocSize] = 0;
    } else if (filterLen > oldFilterLen) {
      // increase the filter length
      foreach_reverse (uint i; 0..chanCount) {
        uint j;
        uint olen = oldFilterLen;
        {
          // try and remove the magic samples as if nothing had happened
          //FIXME: this is wrong but for now we need it to avoid going over the array bounds
          olen = oldFilterLen+2*magicSamples.ptr[i];
          for (j = oldFilterLen-1+magicSamples.ptr[i]; j--; ) mem[i*memAllocSize+j+magicSamples.ptr[i]] = mem[i*oldAllocSize+j];
          //for (j = 0; j < magicSamples.ptr[i]; ++j) mem[i*memAllocSize+j] = 0;
          mem[i*memAllocSize..i*memAllocSize+magicSamples.ptr[i]] = 0;
          magicSamples.ptr[i] = 0;
        }
        if (filterLen > olen) {
          // if the new filter length is still bigger than the "augmented" length
          // copy data going backward
          for (j = 0; j < olen-1; ++j) mem[i*memAllocSize+(filterLen-2-j)] = mem[i*memAllocSize+(olen-2-j)];
          // then put zeros for lack of anything better
          for (; j < filterLen-1; ++j) mem[i*memAllocSize+(filterLen-2-j)] = 0;
          // adjust lastSample
          lastSample.ptr[i] += (filterLen-olen)/2;
        } else {
          // put back some of the magic!
          magicSamples.ptr[i] = (olen-filterLen)/2;
          for (j = 0; j < filterLen-1+magicSamples.ptr[i]; ++j) mem[i*memAllocSize+j] = mem[i*memAllocSize+j+magicSamples.ptr[i]];
        }
      }
    } else if (filterLen < oldFilterLen) {
      // reduce filter length, this a bit tricky
      // we need to store some of the memory as "magic" samples so they can be used directly as input the next time(s)
      foreach (immutable i; 0..chanCount) {
        uint j;
        uint oldMagic = magicSamples.ptr[i];
        magicSamples.ptr[i] = (oldFilterLen-filterLen)/2;
        // we must copy some of the memory that's no longer used
        // copy data going backward
        for (j = 0; j < filterLen-1+magicSamples.ptr[i]+oldMagic; ++j) {
          mem[i*memAllocSize+j] = mem[i*memAllocSize+j+magicSamples.ptr[i]];
        }
        magicSamples.ptr[i] += oldMagic;
      }
    }
    return Error.OK;

  fail:
    resampler = null;
    /* mem may still contain consumed input samples for the filter.
       Restore filterLen so that filterLen-1 still points to the position after
       the last of these samples. */
    filterLen = oldFilterLen;
    return Error.NoMemory;
  }
}


// ////////////////////////////////////////////////////////////////////////// //
static immutable double[68] kaiser12Table = [
  0.99859849, 1.00000000, 0.99859849, 0.99440475, 0.98745105, 0.97779076,
  0.96549770, 0.95066529, 0.93340547, 0.91384741, 0.89213598, 0.86843014,
  0.84290116, 0.81573067, 0.78710866, 0.75723148, 0.72629970, 0.69451601,
  0.66208321, 0.62920216, 0.59606986, 0.56287762, 0.52980938, 0.49704014,
  0.46473455, 0.43304576, 0.40211431, 0.37206735, 0.34301800, 0.31506490,
  0.28829195, 0.26276832, 0.23854851, 0.21567274, 0.19416736, 0.17404546,
  0.15530766, 0.13794294, 0.12192957, 0.10723616, 0.09382272, 0.08164178,
  0.07063950, 0.06075685, 0.05193064, 0.04409466, 0.03718069, 0.03111947,
  0.02584161, 0.02127838, 0.01736250, 0.01402878, 0.01121463, 0.00886058,
  0.00691064, 0.00531256, 0.00401805, 0.00298291, 0.00216702, 0.00153438,
  0.00105297, 0.00069463, 0.00043489, 0.00025272, 0.00013031, 0.0000527734,
  0.00001000, 0.00000000];

static immutable double[36] kaiser10Table = [
  0.99537781, 1.00000000, 0.99537781, 0.98162644, 0.95908712, 0.92831446,
  0.89005583, 0.84522401, 0.79486424, 0.74011713, 0.68217934, 0.62226347,
  0.56155915, 0.50119680, 0.44221549, 0.38553619, 0.33194107, 0.28205962,
  0.23636152, 0.19515633, 0.15859932, 0.12670280, 0.09935205, 0.07632451,
  0.05731132, 0.04193980, 0.02979584, 0.02044510, 0.01345224, 0.00839739,
  0.00488951, 0.00257636, 0.00115101, 0.00035515, 0.00000000, 0.00000000];

static immutable double[36] kaiser8Table = [
  0.99635258, 1.00000000, 0.99635258, 0.98548012, 0.96759014, 0.94302200,
  0.91223751, 0.87580811, 0.83439927, 0.78875245, 0.73966538, 0.68797126,
  0.63451750, 0.58014482, 0.52566725, 0.47185369, 0.41941150, 0.36897272,
  0.32108304, 0.27619388, 0.23465776, 0.19672670, 0.16255380, 0.13219758,
  0.10562887, 0.08273982, 0.06335451, 0.04724088, 0.03412321, 0.02369490,
  0.01563093, 0.00959968, 0.00527363, 0.00233883, 0.00050000, 0.00000000];

static immutable double[36] kaiser6Table = [
  0.99733006, 1.00000000, 0.99733006, 0.98935595, 0.97618418, 0.95799003,
  0.93501423, 0.90755855, 0.87598009, 0.84068475, 0.80211977, 0.76076565,
  0.71712752, 0.67172623, 0.62508937, 0.57774224, 0.53019925, 0.48295561,
  0.43647969, 0.39120616, 0.34752997, 0.30580127, 0.26632152, 0.22934058,
  0.19505503, 0.16360756, 0.13508755, 0.10953262, 0.08693120, 0.06722600,
  0.05031820, 0.03607231, 0.02432151, 0.01487334, 0.00752000, 0.00000000];

struct FuncDef {
  immutable(double)* table;
  int oversample;
}

static immutable FuncDef Kaiser12 = FuncDef(kaiser12Table.ptr, 64);
static immutable FuncDef Kaiser10 = FuncDef(kaiser10Table.ptr, 32);
static immutable FuncDef Kaiser8 = FuncDef(kaiser8Table.ptr, 32);
static immutable FuncDef Kaiser6 = FuncDef(kaiser6Table.ptr, 32);


struct QualityMapping {
  int baseLength;
  int oversample;
  float downsampleBandwidth;
  float upsampleBandwidth;
  immutable FuncDef* windowFunc;
}


/* This table maps conversion quality to internal parameters. There are two
   reasons that explain why the up-sampling bandwidth is larger than the
   down-sampling bandwidth:
   1) When up-sampling, we can assume that the spectrum is already attenuated
      close to the Nyquist rate (from an A/D or a previous resampling filter)
   2) Any aliasing that occurs very close to the Nyquist rate will be masked
      by the sinusoids/noise just below the Nyquist rate (guaranteed only for
      up-sampling).
*/
static immutable QualityMapping[11] qualityMap = [
  QualityMapping(  8,  4, 0.830f, 0.860f, &Kaiser6 ), /* Q0 */
  QualityMapping( 16,  4, 0.850f, 0.880f, &Kaiser6 ), /* Q1 */
  QualityMapping( 32,  4, 0.882f, 0.910f, &Kaiser6 ), /* Q2 */  /* 82.3% cutoff ( ~60 dB stop) 6  */
  QualityMapping( 48,  8, 0.895f, 0.917f, &Kaiser8 ), /* Q3 */  /* 84.9% cutoff ( ~80 dB stop) 8  */
  QualityMapping( 64,  8, 0.921f, 0.940f, &Kaiser8 ), /* Q4 */  /* 88.7% cutoff ( ~80 dB stop) 8  */
  QualityMapping( 80, 16, 0.922f, 0.940f, &Kaiser10), /* Q5 */  /* 89.1% cutoff (~100 dB stop) 10 */
  QualityMapping( 96, 16, 0.940f, 0.945f, &Kaiser10), /* Q6 */  /* 91.5% cutoff (~100 dB stop) 10 */
  QualityMapping(128, 16, 0.950f, 0.950f, &Kaiser10), /* Q7 */  /* 93.1% cutoff (~100 dB stop) 10 */
  QualityMapping(160, 16, 0.960f, 0.960f, &Kaiser10), /* Q8 */  /* 94.5% cutoff (~100 dB stop) 10 */
  QualityMapping(192, 32, 0.968f, 0.968f, &Kaiser12), /* Q9 */  /* 95.5% cutoff (~100 dB stop) 10 */
  QualityMapping(256, 32, 0.975f, 0.975f, &Kaiser12), /* Q10 */ /* 96.6% cutoff (~100 dB stop) 10 */
];


nothrow @trusted @nogc:
/*8, 24, 40, 56, 80, 104, 128, 160, 200, 256, 320*/
double computeFunc (float x, immutable FuncDef* func) {
  import core.stdc.math : lrintf;
  import std.math : floor;
  //double[4] interp;
  float y = x*func.oversample;
  int ind = cast(int)lrintf(floor(y));
  float frac = (y-ind);
  immutable f2 = frac*frac;
  immutable f3 = f2*frac;
  double interp3 = -0.1666666667*frac+0.1666666667*(f3);
  double interp2 = frac+0.5*(f2)-0.5*(f3);
  //double interp2 = 1.0f-0.5f*frac-f2+0.5f*f3;
  double interp0 = -0.3333333333*frac+0.5*(f2)-0.1666666667*(f3);
  // just to make sure we don't have rounding problems
  double interp1 = 1.0f-interp3-interp2-interp0;
  //sum = frac*accum[1]+(1-frac)*accum[2];
  return interp0*func.table[ind]+interp1*func.table[ind+1]+interp2*func.table[ind+2]+interp3*func.table[ind+3];
}


// the slow way of computing a sinc for the table; should improve that some day
float sinc (float cutoff, float x, int N, immutable FuncDef *windowFunc) {
  version(LittleEndian) {
    align(1) union temp_float { align(1): float f; uint n; }
  } else {
    static T fabs(T) (T n) pure { return (n < 0 ? -n : n); }
  }
  import std.math : sin, PI;
  version(LittleEndian) {
    temp_float txx = void;
    txx.f = x;
    txx.n &= 0x7fff_ffff; // abs
    if (txx.f < 1.0e-6f) return cutoff;
    if (txx.f > 0.5f*N) return 0;
  } else {
    if (fabs(x) < 1.0e-6f) return cutoff;
    if (fabs(x) > 0.5f*N) return 0;
  }
  //FIXME: can it really be any slower than this?
  immutable float xx = x*cutoff;
  immutable pixx = PI*xx;
  version(LittleEndian) {
    return cutoff*sin(pixx)/pixx*computeFunc(2.0*txx.f/N, windowFunc);
  } else {
    return cutoff*sin(pixx)/pixx*computeFunc(fabs(2.0*x/N), windowFunc);
  }
}


void cubicCoef (in float frac, float* interp) {
  immutable f2 = frac*frac;
  immutable f3 = f2*frac;
  // compute interpolation coefficients; i'm not sure whether this corresponds to cubic interpolation but I know it's MMSE-optimal on a sinc
  interp[0] =  -0.16667f*frac+0.16667f*f3;
  interp[1] = frac+0.5f*f2-0.5f*f3;
  //interp[2] = 1.0f-0.5f*frac-f2+0.5f*f3;
  interp[3] = -0.33333f*frac+0.5f*f2-0.16667f*f3;
  // just to make sure we don't have rounding problems
  interp[2] = 1.0-interp[0]-interp[1]-interp[3];
}


// ////////////////////////////////////////////////////////////////////////// //
int resamplerBasicDirect(T) (ref OpusResampler st, uint chanIdx, const(float)* indata, uint* indataLen, float* outdata, uint* outdataLen)
if (is(T == float) || is(T == double))
{
  auto N = st.filterLen;
  static if (is(T == double)) assert(N%4 == 0);
  int outSample = 0;
  int lastSample = st.lastSample.ptr[chanIdx];
  uint sampFracNum = st.sampFracNum.ptr[chanIdx];
  const(float)* sincTable = st.sincTable;
  immutable outStride = st.outStride;
  immutable intAdvance = st.intAdvance;
  immutable fracAdvance = st.fracAdvance;
  immutable denRate = st.denRate;
  T sum = void;
  while (!(lastSample >= cast(int)(*indataLen) || outSample >= cast(int)(*outdataLen))) {
    const(float)* sinct = &sincTable[sampFracNum*N];
    const(float)* iptr = &indata[lastSample];
    static if (is(T == float)) {
      // at least 2x speedup with SSE here (but for unrolled loop)
      if (N%4 == 0) {
        version(sincresample_use_sse) {
          //align(64) __gshared float[4] zero = 0;
          align(64) __gshared float[4+128] zeroesBuf = 0; // dmd cannot into such aligns, alas
          __gshared uint zeroesptr = 0;
          if (zeroesptr == 0) {
            zeroesptr = cast(uint)zeroesBuf.ptr;
            if (zeroesptr&0x3f) zeroesptr = (zeroesptr|0x3f)+1;
          }
          //assert((zeroesptr&0x3f) == 0, "wtf?!");
          asm nothrow @safe @nogc {
            mov       ECX,[N];
            shr       ECX,2;
            mov       EAX,[zeroesptr];
            movaps    XMM0,[EAX];
            mov       EAX,[sinct];
            mov       EBX,[iptr];
            mov       EDX,16;
            align 8;
           rbdseeloop:
            movups    XMM1,[EAX];
            movups    XMM2,[EBX];
            mulps     XMM1,XMM2;
            addps     XMM0,XMM1;
            add       EAX,EDX;
            add       EBX,EDX;
            dec       ECX;
            jnz       rbdseeloop;
            // store result in sum
            movhlps   XMM1,XMM0; // now low part of XMM1 contains high part of XMM0
            addps     XMM0,XMM1; // low part of XMM0 is ok
            movaps    XMM1,XMM0;
            shufps    XMM1,XMM0,0b_01_01_01_01; // 2nd float of XMM0 goes to the 1st float of XMM1
            addss     XMM0,XMM1;
            movss     [sum],XMM0;
          }
          /*
          float sum1 = 0;
          foreach (immutable j; 0..N) sum1 += sinct[j]*iptr[j];
          import std.math;
          if (fabs(sum-sum1) > 0.000001f) {
            import core.stdc.stdio;
            printf("sum=%f; sum1=%f\n", sum, sum1);
            assert(0);
          }
          */
        } else {
          // no SSE; for my i3 unrolled loop is almost of the speed of SSE code
          T[4] accum = 0;
          foreach (immutable j; 0..N/4) {
            accum.ptr[0] += *sinct++ * *iptr++;
            accum.ptr[1] += *sinct++ * *iptr++;
            accum.ptr[2] += *sinct++ * *iptr++;
            accum.ptr[3] += *sinct++ * *iptr++;
          }
          sum = accum.ptr[0]+accum.ptr[1]+accum.ptr[2]+accum.ptr[3];
        }
      } else {
        sum = 0;
        foreach (immutable j; 0..N) sum += *sinct++ * *iptr++;
      }
      outdata[outStride*outSample++] = sum;
    } else {
      if (N%4 == 0) {
        //TODO: write SSE code here!
        // for my i3 unrolled loop is ~2 times faster
        T[4] accum = 0;
        foreach (immutable j; 0..N/4) {
          accum.ptr[0] += cast(double)*sinct++ * cast(double)*iptr++;
          accum.ptr[1] += cast(double)*sinct++ * cast(double)*iptr++;
          accum.ptr[2] += cast(double)*sinct++ * cast(double)*iptr++;
          accum.ptr[3] += cast(double)*sinct++ * cast(double)*iptr++;
        }
        sum = accum.ptr[0]+accum.ptr[1]+accum.ptr[2]+accum.ptr[3];
      } else {
        sum = 0;
        foreach (immutable j; 0..N) sum += cast(double)*sinct++ * cast(double)*iptr++;
      }
      outdata[outStride*outSample++] = cast(float)sum;
    }
    lastSample += intAdvance;
    sampFracNum += fracAdvance;
    if (sampFracNum >= denRate) {
      sampFracNum -= denRate;
      ++lastSample;
    }
  }
  st.lastSample.ptr[chanIdx] = lastSample;
  st.sampFracNum.ptr[chanIdx] = sampFracNum;
  return outSample;
}


int resamplerBasicInterpolate(T) (ref OpusResampler st, uint chanIdx, const(float)* indata, uint *indataLen, float *outdata, uint *outdataLen)
if (is(T == float) || is(T == double))
{
  immutable N = st.filterLen;
  assert(N%4 == 0);
  int outSample = 0;
  int lastSample = st.lastSample.ptr[chanIdx];
  uint sampFracNum = st.sampFracNum.ptr[chanIdx];
  immutable outStride = st.outStride;
  immutable intAdvance = st.intAdvance;
  immutable fracAdvance = st.fracAdvance;
  immutable denRate = st.denRate;
  float sum;

  float[4] interp = void;
  T[4] accum = void;
  while (!(lastSample >= cast(int)(*indataLen) || outSample >= cast(int)(*outdataLen))) {
    const(float)* iptr = &indata[lastSample];
    const int offset = sampFracNum*st.oversample/st.denRate;
    const float frac = (cast(float)((sampFracNum*st.oversample)%st.denRate))/st.denRate;
    accum[] = 0;
    //TODO: optimize!
    foreach (immutable j; 0..N) {
      immutable T currIn = iptr[j];
      accum.ptr[0] += currIn*(st.sincTable[4+(j+1)*st.oversample-offset-2]);
      accum.ptr[1] += currIn*(st.sincTable[4+(j+1)*st.oversample-offset-1]);
      accum.ptr[2] += currIn*(st.sincTable[4+(j+1)*st.oversample-offset]);
      accum.ptr[3] += currIn*(st.sincTable[4+(j+1)*st.oversample-offset+1]);
    }

    cubicCoef(frac, interp.ptr);
    sum = (interp.ptr[0]*accum.ptr[0])+(interp.ptr[1]*accum.ptr[1])+(interp.ptr[2]*accum.ptr[2])+(interp.ptr[3]*accum.ptr[3]);

    outdata[outStride*outSample++] = sum;
    lastSample += intAdvance;
    sampFracNum += fracAdvance;
    if (sampFracNum >= denRate) {
      sampFracNum -= denRate;
      ++lastSample;
    }
  }

  st.lastSample.ptr[chanIdx] = lastSample;
  st.sampFracNum.ptr[chanIdx] = sampFracNum;
  return outSample;
}


// ////////////////////////////////////////////////////////////////////////// //
uint gcd (uint a, uint b) pure {
  if (a == 0) return b;
  if (b == 0) return a;
  for (;;) {
    if (a > b) {
      a %= b;
      if (a == 0) return b;
      if (a == 1) return 1;
    } else {
      b %= a;
      if (b == 0) return a;
      if (b == 1) return 1;
    }
  }
}


enum AV_SAMPLE_FMT_FLTP = 8; //HACK


static immutable uint16_t[16] silk_frame_duration_ms = [
  10, 20, 40, 60,
  10, 20, 40, 60,
  10, 20, 40, 60,
  10, 20,
  10, 20,
];

/* number of samples of silence to feed to the resampler at the beginning */
static immutable int[5] silk_resample_delay = [ 4, 8, 11, 11, 11 ];

static immutable uint8_t[5] celt_band_end = [ 13, 17, 17, 19, 21 ];

static int get_silk_samplerate (int config) {
  return (config < 4 ? 8000 : config < 8 ? 12000 : 16000);
}

/**
 * Range decoder
 */
static int opus_rc_init (OpusRangeCoder *rc, const(uint8_t)* data, int size) {
  //conwritefln!"size=%s; 0x%02x"(size, data[0]);
  int ret = rc.gb.init_get_bits8(data, size);
  if (ret < 0) return ret;

  rc.range = 128;
  rc.value = 127 - rc.gb.get_bits(7);
  rc.total_read_bits = 9;
  opus_rc_normalize(rc);
  //conwriteln("range=", rc.range, "; value=", rc.value);
  //assert(0);

  return 0;
}

static void opus_raw_init (OpusRangeCoder* rc, const(uint8_t)* rightend, uint bytes) {
  rc.rb.position = rightend;
  rc.rb.bytes    = bytes;
  rc.rb.cachelen = 0;
  rc.rb.cacheval = 0;
}

static void opus_fade (float *out_, const(float)* in1, const(float)* in2, const(float)* window, int len) {
  for (int i = 0; i < len; i++) out_[i] = in2[i] * window[i] + in1[i] * (1.0 - window[i]);
}

static int opus_flush_resample (OpusStreamContext* s, int nb_samples) {
  int celt_size = av_audio_fifo_size(s.celt_delay); //k8
  int ret, i;
  ret = s.flr.swrconvert(cast(float**)s.out_, nb_samples, null, 0);
  if (ret < 0) return AVERROR_BUG;
  if (ret != nb_samples) {
    //av_log(s.avctx, AV_LOG_ERROR, "Wrong number of flushed samples: %d\n", ret);
    return AVERROR_BUG;
  }

  if (celt_size) {
    if (celt_size != nb_samples) {
      //av_log(s.avctx, AV_LOG_ERROR, "Wrong number of CELT delay samples.\n");
      return AVERROR_BUG;
    }
    av_audio_fifo_read(s.celt_delay, cast(void**)s.celt_output.ptr, nb_samples);
    for (i = 0; i < s.output_channels; i++) {
      vector_fmac_scalar(s.out_[i], s.celt_output[i], 1.0, nb_samples);
    }
  }

  if (s.redundancy_idx) {
    for (i = 0; i < s.output_channels; i++) {
      opus_fade(s.out_[i], s.out_[i], s.redundancy_output[i] + 120 + s.redundancy_idx, ff_celt_window2.ptr + s.redundancy_idx, 120 - s.redundancy_idx);
    }
    s.redundancy_idx = 0;
  }

  s.out_[0]   += nb_samples;
  s.out_[1]   += nb_samples;
  s.out_size -= nb_samples * float.sizeof;

  return 0;
}

static int opus_init_resample (OpusStreamContext* s) {
  float[16] delay = 0.0;
  const(float)*[2] delayptr = [ cast(immutable(float)*)delay.ptr, cast(immutable(float)*)delay.ptr ];
  float[128] odelay = void;
  float*[2] odelayptr = [ odelay.ptr, odelay.ptr ];
  int ret;

  if (s.flr.inited && s.flr.getInRate == s.silk_samplerate) {
    s.flr.reset();
  } else if (!s.flr.inited || s.flr.getChans != s.output_channels) {
    // use Voip(3) quality
    if (s.flr.setup(s.output_channels, s.silk_samplerate, 48000, 3) != s.flr.Error.OK) return AVERROR_BUG;
  } else {
    if (s.flr.setRate(s.silk_samplerate, 48000)  != s.flr.Error.OK) return AVERROR_BUG;
  }

  ret = s.flr.swrconvert(odelayptr.ptr, 128, delayptr.ptr, silk_resample_delay[s.packet.bandwidth]);
  if (ret < 0) {
    //av_log(s.avctx, AV_LOG_ERROR, "Error feeding initial silence to the resampler.\n");
    return AVERROR_BUG;
  }

  return 0;
}

static int opus_decode_redundancy (OpusStreamContext* s, const(uint8_t)* data, int size) {
  int ret;
  OpusBandwidth bw = s.packet.bandwidth;

  if (s.packet.mode == OPUS_MODE_SILK && bw == OPUS_BANDWIDTH_MEDIUMBAND) bw = OPUS_BANDWIDTH_WIDEBAND;

  ret = opus_rc_init(&s.redundancy_rc, data, size);
  if (ret < 0) goto fail;
  opus_raw_init(&s.redundancy_rc, data + size, size);

  ret = ff_celt_decode_frame(s.celt, &s.redundancy_rc, s.redundancy_output.ptr, s.packet.stereo + 1, 240, 0, celt_band_end[s.packet.bandwidth]);
  if (ret < 0) goto fail;

  return 0;
fail:
  //av_log(s.avctx, AV_LOG_ERROR, "Error decoding the redundancy frame.\n");
  return ret;
}

static int opus_decode_frame (OpusStreamContext* s, const(uint8_t)* data, int size) {
  import core.stdc.string : memcpy;
  int samples = s.packet.frame_duration;
  int redundancy = 0;
  int redundancy_size, redundancy_pos;
  int ret, i, consumed;
  int delayed_samples = s.delayed_samples;

  ret = opus_rc_init(&s.rc, data, size);
  if (ret < 0) return ret;

  //if (s.packet.mode != OPUS_MODE_CELT) assert(0);
  // decode the silk frame
  if (s.packet.mode == OPUS_MODE_SILK || s.packet.mode == OPUS_MODE_HYBRID) {
    if (!s.flr.inited) {
      ret = opus_init_resample(s);
      if (ret < 0) return ret;
    }
    //conwriteln("silk sr: ", s.silk_samplerate);

    samples = ff_silk_decode_superframe(s.silk, &s.rc, s.silk_output.ptr,
                                        FFMIN(s.packet.bandwidth, OPUS_BANDWIDTH_WIDEBAND),
                                        s.packet.stereo + 1,
                                        silk_frame_duration_ms[s.packet.config]);
    if (samples < 0) {
      //av_log(s.avctx, AV_LOG_ERROR, "Error decoding a SILK frame.\n");
      return samples;
    }
    //samples = swr_convert(s.swr, cast(uint8_t**)s.out_.ptr, s.packet.frame_duration, cast(const(uint8_t)**)s.silk_output.ptr, samples);
    immutable insamples = samples;
    samples = s.flr.swrconvert(cast(float**)s.out_.ptr, s.packet.frame_duration, cast(const(float)**)s.silk_output.ptr, samples);
    if (samples < 0) {
      //av_log(s.avctx, AV_LOG_ERROR, "Error resampling SILK data.\n");
      return samples;
    }
    //conwriteln("dcsamples: ", samples, "; outs=", s.packet.frame_duration, "; ins=", insamples);
    //k8???!!! assert((samples & 7) == 0);
    s.delayed_samples += s.packet.frame_duration - samples;
  } else {
    ff_silk_flush(s.silk);
  }

  // decode redundancy information
  consumed = opus_rc_tell(&s.rc);
  if (s.packet.mode == OPUS_MODE_HYBRID && consumed + 37 <= size * 8) redundancy = opus_rc_p2model(&s.rc, 12);
  else if (s.packet.mode == OPUS_MODE_SILK && consumed + 17 <= size * 8) redundancy = 1;

  if (redundancy) {
    redundancy_pos = opus_rc_p2model(&s.rc, 1);

    if (s.packet.mode == OPUS_MODE_HYBRID)
      redundancy_size = opus_rc_unimodel(&s.rc, 256) + 2;
    else
      redundancy_size = size - (consumed + 7) / 8;
    size -= redundancy_size;
    if (size < 0) {
      //av_log(s.avctx, AV_LOG_ERROR, "Invalid redundancy frame size.\n");
      return AVERROR_INVALIDDATA;
    }

    if (redundancy_pos) {
      ret = opus_decode_redundancy(s, data + size, redundancy_size);
      if (ret < 0) return ret;
      ff_celt_flush(s.celt);
    }
  }

  // decode the CELT frame
  if (s.packet.mode == OPUS_MODE_CELT || s.packet.mode == OPUS_MODE_HYBRID) {
    float*[2] out_tmp = [ s.out_[0], s.out_[1] ];
    float **dst = (s.packet.mode == OPUS_MODE_CELT ? out_tmp.ptr : s.celt_output.ptr);
    int celt_output_samples = samples;
    int delay_samples = av_audio_fifo_size(s.celt_delay);

    if (delay_samples) {
      if (s.packet.mode == OPUS_MODE_HYBRID) {
        av_audio_fifo_read(s.celt_delay, cast(void**)s.celt_output.ptr, delay_samples);

        for (i = 0; i < s.output_channels; i++) {
          vector_fmac_scalar(out_tmp[i], s.celt_output[i], 1.0, delay_samples);
          out_tmp[i] += delay_samples;
        }
        celt_output_samples -= delay_samples;
      } else {
        //av_log(s.avctx, AV_LOG_WARNING, "Spurious CELT delay samples present.\n");
        av_audio_fifo_drain(s.celt_delay, delay_samples);
        //if (s.avctx.err_recognition & AV_EF_EXPLODE) return AVERROR_BUG;
      }
    }

    opus_raw_init(&s.rc, data + size, size);

    ret = ff_celt_decode_frame(s.celt, &s.rc, dst,
                               s.packet.stereo + 1,
                               s.packet.frame_duration,
                               (s.packet.mode == OPUS_MODE_HYBRID) ? 17 : 0,
                               celt_band_end[s.packet.bandwidth]);
    if (ret < 0) return ret;

    if (s.packet.mode == OPUS_MODE_HYBRID) {
      int celt_delay = s.packet.frame_duration - celt_output_samples;
      void*[2] delaybuf = [ s.celt_output[0] + celt_output_samples,
                            s.celt_output[1] + celt_output_samples ];

      for (i = 0; i < s.output_channels; i++) {
        vector_fmac_scalar(out_tmp[i], s.celt_output[i], 1.0, celt_output_samples);
      }

      ret = av_audio_fifo_write(s.celt_delay, delaybuf.ptr, celt_delay);
      if (ret < 0) return ret;
    }
  } else {
    ff_celt_flush(s.celt);
  }

  if (s.redundancy_idx) {
    for (i = 0; i < s.output_channels; i++) {
      opus_fade(s.out_[i], s.out_[i],
                s.redundancy_output[i] + 120 + s.redundancy_idx,
                ff_celt_window2.ptr + s.redundancy_idx, 120 - s.redundancy_idx);
    }
    s.redundancy_idx = 0;
  }

  if (redundancy) {
    if (!redundancy_pos) {
      ff_celt_flush(s.celt);
      ret = opus_decode_redundancy(s, data + size, redundancy_size);
      if (ret < 0) return ret;

      for (i = 0; i < s.output_channels; i++) {
        opus_fade(s.out_[i] + samples - 120 + delayed_samples,
                  s.out_[i] + samples - 120 + delayed_samples,
                  s.redundancy_output[i] + 120,
                  ff_celt_window2.ptr, 120 - delayed_samples);
        if (delayed_samples)
            s.redundancy_idx = 120 - delayed_samples;
      }
    } else {
      for (i = 0; i < s.output_channels; i++) {
        memcpy(s.out_[i] + delayed_samples, s.redundancy_output[i], 120 * float.sizeof);
        opus_fade(s.out_[i] + 120 + delayed_samples,
                  s.redundancy_output[i] + 120,
                  s.out_[i] + 120 + delayed_samples,
                  ff_celt_window2.ptr, 120);
      }
    }
  }

  return samples;
}

static int opus_decode_subpacket (OpusStreamContext* s, const(uint8_t)* buf, int buf_size, float** out_, int out_size, int nb_samples) {
  import core.stdc.string : memset;
  int output_samples = 0;
  int flush_needed   = 0;
  int i, j, ret;

  s.out_[0]   = out_[0];
  s.out_[1]   = out_[1];
  s.out_size = out_size;

  /* check if we need to flush the resampler */
  if (s.flr.inited) {
    if (buf) {
      int64_t cur_samplerate = s.flr.getInRate;
      //av_opt_get_int(s.swr, "in_sample_rate", 0, &cur_samplerate);
      flush_needed = (s.packet.mode == OPUS_MODE_CELT) || (cur_samplerate != s.silk_samplerate);
    } else {
      flush_needed = !!s.delayed_samples;
    }
  }

  if (!buf && !flush_needed)
      return 0;

  /* use dummy output buffers if the channel is not mapped to anything */
  if (s.out_[0] is null ||
      (s.output_channels == 2 && s.out_[1] is null)) {
      av_fast_malloc(cast(void**)&s.out_dummy, &s.out_dummy_allocated_size, s.out_size);
      if (!s.out_dummy)
          return AVERROR(ENOMEM);
      if (!s.out_[0])
          s.out_[0] = s.out_dummy;
      if (!s.out_[1])
          s.out_[1] = s.out_dummy;
  }

  /* flush the resampler if necessary */
  if (flush_needed) {
      ret = opus_flush_resample(s, s.delayed_samples);
      if (ret < 0) {
          //av_log(s.avctx, AV_LOG_ERROR, "Error flushing the resampler.\n");
          return ret;
      }
      //swr_close(s.swr);
      s.flr.deinit();
      output_samples += s.delayed_samples;
      s.delayed_samples = 0;

      if (!buf)
          goto finish;
  }

  /* decode all the frames in the packet */
  for (i = 0; i < s.packet.frame_count; i++) {
      int size = s.packet.frame_size[i];
      int samples = opus_decode_frame(s, buf + s.packet.frame_offset[i], size);

      if (samples < 0) {
          //av_log(s.avctx, AV_LOG_ERROR, "Error decoding an Opus frame.\n");
          //if (s.avctx.err_recognition & AV_EF_EXPLODE) return samples;

          for (j = 0; j < s.output_channels; j++)
              memset(s.out_[j], 0, s.packet.frame_duration * float.sizeof);
          samples = s.packet.frame_duration;
      }
      output_samples += samples;

      for (j = 0; j < s.output_channels; j++)
          s.out_[j] += samples;
      s.out_size -= samples * float.sizeof;
  }

finish:
  s.out_[0] = s.out_[1] = null;
  s.out_size = 0;

  return output_samples;
}


// ////////////////////////////////////////////////////////////////////////// //
int opus_decode_packet (/*AVCtx* avctx,*/ OpusContext* c, AVFrame* frame, int* got_frame_ptr, AVPacket* avpkt) {
  import core.stdc.string : memcpy, memset;
  //AVFrame *frame      = data;
  const(uint8_t)*buf  = avpkt.data;
  int buf_size        = avpkt.size;
  int coded_samples   = 0;
  int decoded_samples = int.max;
  int delayed_samples = 0;
  int i, ret;

  // calculate the number of delayed samples
  for (i = 0; i < c.nb_streams; i++) {
    OpusStreamContext *s = &c.streams[i];
    s.out_[0] = s.out_[1] = null;
    delayed_samples = FFMAX(delayed_samples, s.delayed_samples+av_audio_fifo_size(c.sync_buffers[i]));
  }

  // decode the header of the first sub-packet to find out the sample count
  if (buf !is null) {
    OpusPacket *pkt = &c.streams[0].packet;
    ret = ff_opus_parse_packet(pkt, buf, buf_size, c.nb_streams > 1);
    if (ret < 0) {
      //av_log(avctx, AV_LOG_ERROR, "Error parsing the packet header.\n");
      return ret;
    }
    coded_samples += pkt.frame_count * pkt.frame_duration;
    c.streams[0].silk_samplerate = get_silk_samplerate(pkt.config);
  }

  frame.nb_samples = coded_samples + delayed_samples;
  //conwriteln("frame samples: ", frame.nb_samples);

  /* no input or buffered data => nothing to do */
  if (!frame.nb_samples) {
    *got_frame_ptr = 0;
    return 0;
  }

  /* setup the data buffers */
  ret = ff_get_buffer(frame, 0);
  if (ret < 0) return ret;
  frame.nb_samples = 0;

  memset(c.out_, 0, c.nb_streams*2*(*c.out_).sizeof);
  for (i = 0; i < c.in_channels; i++) {
    ChannelMap *map = &c.channel_maps[i];
    //if (!map.copy) conwriteln("[", 2*map.stream_idx+map.channel_idx, "] = [", i, "]");
    if (!map.copy) c.out_[2*map.stream_idx+map.channel_idx] = cast(float*)frame.extended_data[i];
  }

  // read the data from the sync buffers
  for (i = 0; i < c.nb_streams; i++) {
    float** out_ = c.out_+2*i;
    int sync_size = av_audio_fifo_size(c.sync_buffers[i]);

    float[32] sync_dummy = void;
    int out_dummy = (!out_[0]) | ((!out_[1]) << 1);

    if (!out_[0]) out_[0] = sync_dummy.ptr;
    if (!out_[1]) out_[1] = sync_dummy.ptr;
    if (out_dummy && sync_size > /*FF_ARRAY_ELEMS*/sync_dummy.length) return AVERROR_BUG;

    ret = av_audio_fifo_read(c.sync_buffers[i], cast(void**)out_, sync_size);
    if (ret < 0) return ret;

    if (out_dummy & 1) out_[0] = null; else out_[0] += ret;
    if (out_dummy & 2) out_[1] = null; else out_[1] += ret;

    //conwriteln("ret=", ret);
    c.out_size[i] = cast(int)(frame.linesize[0]-ret*float.sizeof);
  }

  // decode each sub-packet
  for (i = 0; i < c.nb_streams; i++) {
    OpusStreamContext *s = &c.streams[i];
    if (i && buf) {
      ret = ff_opus_parse_packet(&s.packet, buf, buf_size, (i != c.nb_streams-1));
      if (ret < 0) {
        //av_log(avctx, AV_LOG_ERROR, "Error parsing the packet header.\n");
        return ret;
      }
      if (coded_samples != s.packet.frame_count * s.packet.frame_duration) {
        //av_log(avctx, AV_LOG_ERROR, "Mismatching coded sample count in substream %d.\n", i);
        return AVERROR_INVALIDDATA;
      }
      s.silk_samplerate = get_silk_samplerate(s.packet.config);
    }

    ret = opus_decode_subpacket(&c.streams[i], buf, s.packet.data_size, c.out_+2*i, c.out_size[i], coded_samples);
    if (ret < 0) return ret;
    c.decoded_samples[i] = ret;
    decoded_samples = FFMIN(decoded_samples, ret);

    buf += s.packet.packet_size;
    buf_size -= s.packet.packet_size;
  }

  // buffer the extra samples
  for (i = 0; i < c.nb_streams; i++) {
    int buffer_samples = c.decoded_samples[i]-decoded_samples;
    if (buffer_samples) {
      float*[2] buff = [ c.out_[2 * i + 0] ? c.out_[2 * i + 0] : cast(float*)frame.extended_data[0],
                         c.out_[2 * i + 1] ? c.out_[2 * i + 1] : cast(float*)frame.extended_data[0] ];
      buff[0] += decoded_samples;
      buff[1] += decoded_samples;
      ret = av_audio_fifo_write(c.sync_buffers[i], cast(void**)buff.ptr, buffer_samples);
      if (ret < 0) return ret;
    }
  }

  for (i = 0; i < c.in_channels; i++) {
    ChannelMap *map = &c.channel_maps[i];
    // handle copied channels
    if (map.copy) {
      memcpy(frame.extended_data[i], frame.extended_data[map.copy_idx], frame.linesize[0]);
    } else if (map.silence) {
      memset(frame.extended_data[i], 0, frame.linesize[0]);
    }
    if (c.gain_i && decoded_samples > 0) {
      vector_fmul_scalar(cast(float*)frame.extended_data[i], cast(float*)frame.extended_data[i], c.gain, /*FFALIGN(decoded_samples, 8)*/decoded_samples);
    }
  }

  //frame.nb_samples = decoded_samples;
  *got_frame_ptr = !!decoded_samples;

  //return /*avpkt.size*/datasize;
  return decoded_samples;
}


void opus_decode_flush (OpusContext* c) {
  import core.stdc.string : memset;
  for (int i = 0; i < c.nb_streams; i++) {
    OpusStreamContext *s = &c.streams[i];

    memset(&s.packet, 0, s.packet.sizeof);
    s.delayed_samples = 0;

    if (s.celt_delay) av_audio_fifo_drain(s.celt_delay, av_audio_fifo_size(s.celt_delay));
    //swr_close(s.swr);
    s.flr.deinit();

    av_audio_fifo_drain(c.sync_buffers[i], av_audio_fifo_size(c.sync_buffers[i]));

    ff_silk_flush(s.silk);
    ff_celt_flush(s.celt);
  }
}

int opus_decode_close (OpusContext* c) {
  int i;

  for (i = 0; i < c.nb_streams; i++) {
    OpusStreamContext *s = &c.streams[i];

    ff_silk_free(&s.silk);
    ff_celt_free(&s.celt);

    av_freep(&s.out_dummy);
    s.out_dummy_allocated_size = 0;

    av_audio_fifo_free(s.celt_delay);
    //swr_free(&s.swr);
    s.flr.deinit();
  }

  av_freep(&c.streams);

  if (c.sync_buffers) {
    for (i = 0; i < c.nb_streams; i++) av_audio_fifo_free(c.sync_buffers[i]);
  }
  av_freep(&c.sync_buffers);
  av_freep(&c.decoded_samples);
  av_freep(&c.out_);
  av_freep(&c.out_size);

  c.nb_streams = 0;

  av_freep(&c.channel_maps);
  //av_freep(&c.fdsp);

  return 0;
}

int opus_decode_init (AVCtx* avctx, OpusContext* c, short cmtgain) {
  int ret, i, j;

  avctx.sample_fmt  = AV_SAMPLE_FMT_FLTP;
  avctx.sample_rate = 48000;

  //c.fdsp = avpriv_float_dsp_alloc(0);
  //if (!c.fdsp) return AVERROR(ENOMEM);

  // find out the channel configuration
  ret = ff_opus_parse_extradata(avctx, c, cmtgain);
  if (ret < 0) {
    av_freep(&c.channel_maps);
    //av_freep(&c.fdsp);
    return ret;
  }
  c.in_channels = avctx.channels;

  //conwriteln("c.nb_streams=", c.nb_streams);
  //conwriteln("chans=", c.in_channels);
  // allocate and init each independent decoder
  c.streams = av_mallocz_array!(typeof(c.streams[0]))(c.nb_streams);
  c.out_ = av_mallocz_array!(typeof(c.out_[0]))(c.nb_streams * 2);
  c.out_size = av_mallocz_array!(typeof(c.out_size[0]))(c.nb_streams);
  c.sync_buffers = av_mallocz_array!(typeof(c.sync_buffers[0]))(c.nb_streams);
  c.decoded_samples = av_mallocz_array!(typeof(c.decoded_samples[0]))(c.nb_streams);
  if (c.streams is null || c.sync_buffers is null || c.decoded_samples is null || c.out_ is null || c.out_size is null) {
    c.nb_streams = 0;
    ret = AVERROR(ENOMEM);
    goto fail;
  }

  for (i = 0; i < c.nb_streams; i++) {
    OpusStreamContext *s = &c.streams[i];
    uint64_t layout;

    s.output_channels = (i < c.nb_stereo_streams) ? 2 : 1;
    //conwriteln("stream #", i, "; chans: ", s.output_channels);

    //s.avctx = avctx;

    for (j = 0; j < s.output_channels; j++) {
      s.silk_output[j] = s.silk_buf[j].ptr;
      s.celt_output[j] = s.celt_buf[j].ptr;
      s.redundancy_output[j] = s.redundancy_buf[j].ptr;
    }

    //s.fdsp = c.fdsp;
    layout = (s.output_channels == 1) ? AV_CH_LAYOUT_MONO : AV_CH_LAYOUT_STEREO;

    /+
    s.swr = swr_alloc();
    if (!s.swr) goto fail;

    /*
    av_opt_set_int(s.swr, "in_sample_fmt",      avctx.sample_fmt,  0);
    av_opt_set_int(s.swr, "out_sample_fmt",     avctx.sample_fmt,  0);
    av_opt_set_int(s.swr, "in_channel_layout",  layout,             0);
    av_opt_set_int(s.swr, "out_channel_layout", layout,             0);
    av_opt_set_int(s.swr, "out_sample_rate",    avctx.sample_rate, 0);
    av_opt_set_int(s.swr, "filter_size",        16,                 0);
    */
    +/
    /*
    s.swr = swr_alloc_set_opts(null,
      layout, // out_ch_layout
      AV_SAMPLE_FMT_FLTP, // out_sample_fmt
      avctx.sample_rate, // out_sample_rate
      layout, // in_ch_layout
      AV_SAMPLE_FMT_FLTP, // in_sample_fmt
      avctx.sample_rate, // in_sample_rate
      0, null);

    conwriteln("in_sample_fmt     : ", avctx.sample_fmt);
    conwriteln("out_sample_fmt    : ", avctx.sample_fmt);
    conwriteln("in_channel_layout : ", layout);
    conwriteln("out_channel_layout: ", layout);
    conwriteln("out_sample_rate   : ", avctx.sample_rate);
    conwriteln("filter_size       : ", 16);
    */

    ret = ff_silk_init(/*avctx, */&s.silk, s.output_channels);
    if (ret < 0) goto fail;

    ret = ff_celt_init(/*avctx, */&s.celt, s.output_channels);
    if (ret < 0) goto fail;

    s.celt_delay = av_audio_fifo_alloc(avctx.sample_fmt, s.output_channels, 1024);
    if (!s.celt_delay) {
      ret = AVERROR(ENOMEM);
      goto fail;
    }

    c.sync_buffers[i] = av_audio_fifo_alloc(avctx.sample_fmt, s.output_channels, 32);
    if (!c.sync_buffers[i]) {
      ret = AVERROR(ENOMEM);
      goto fail;
    }
  }

  return 0;
fail:
  opus_decode_close(/*avctx*/c);
  return ret;
}


int opus_decode_init_ll (OpusContext* c) {
  int channels = 2;
  c.gain_i = 0;
  c.gain = 0;
  c.nb_streams = 1;
  c.nb_stereo_streams = 1;
  c.in_channels = channels;
  c.channel_maps = av_mallocz_array!(typeof(c.channel_maps[0]))(channels);
  if (c.channel_maps is null) return AVERROR(ENOMEM);
  c.channel_maps[0].stream_idx = 0;
  c.channel_maps[0].channel_idx = 0;
  c.channel_maps[1].stream_idx = 0;
  c.channel_maps[1].channel_idx = 1;

  //conwriteln("c.nb_streams=", c.nb_streams);
  // allocate and init each independent decoder
  c.streams = av_mallocz_array!(typeof(c.streams[0]))(c.nb_streams);
  c.out_ = av_mallocz_array!(typeof(c.out_[0]))(c.nb_streams * 2);
  c.out_size = av_mallocz_array!(typeof(c.out_size[0]))(c.nb_streams);
  c.sync_buffers = av_mallocz_array!(typeof(c.sync_buffers[0]))(c.nb_streams);
  c.decoded_samples = av_mallocz_array!(typeof(c.decoded_samples[0]))(c.nb_streams);
  if (c.streams is null || c.sync_buffers is null || c.decoded_samples is null || c.out_ is null || c.out_size is null) {
    c.nb_streams = 0;
    opus_decode_close(c);
    return AVERROR(ENOMEM);
  }

  foreach (immutable i; 0..c.nb_streams) {
    OpusStreamContext *s = &c.streams[i];
    uint64_t layout;

    s.output_channels = (i < c.nb_stereo_streams ? 2 : 1);
    //conwriteln("stream #", i, "; chans: ", s.output_channels);

    foreach (immutable j; 0..s.output_channels) {
      s.silk_output[j] = s.silk_buf[j].ptr;
      s.celt_output[j] = s.celt_buf[j].ptr;
      s.redundancy_output[j] = s.redundancy_buf[j].ptr;
    }

    layout = (s.output_channels == 1) ? AV_CH_LAYOUT_MONO : AV_CH_LAYOUT_STEREO;

    /+
    s.swr = swr_alloc_set_opts(null,
      layout, // out_ch_layout
      AV_SAMPLE_FMT_FLTP, // out_sample_fmt
      48000, // out_sample_rate
      layout, // in_ch_layout
      AV_SAMPLE_FMT_FLTP, // in_sample_fmt
      48000, // in_sample_rate
      0, null);
    +/

    if (ff_silk_init(/*avctx, */&s.silk, s.output_channels) < 0) {
      opus_decode_close(c);
      return AVERROR(ENOMEM);
    }

    if (ff_celt_init(/*avctx, */&s.celt, s.output_channels) < 0) {
      opus_decode_close(c);
      return AVERROR(ENOMEM);
    }

    s.celt_delay = av_audio_fifo_alloc(AV_SAMPLE_FMT_FLTP, s.output_channels, 1024);
    if (!s.celt_delay) {
      opus_decode_close(c);
      return AVERROR(ENOMEM);
    }

    c.sync_buffers[i] = av_audio_fifo_alloc(AV_SAMPLE_FMT_FLTP, s.output_channels, 32);
    if (!c.sync_buffers[i]) {
      opus_decode_close(c);
      return AVERROR(ENOMEM);
    }
  }

  return 0;
}
} // nothrow @nogc

@nogc:

// ////////////////////////////////////////////////////////////////////////// //
struct OggStream {
private:

@nogc:
  enum MaxPageSize = 65025+Offsets.Lacing+255;
  //pragma(msg, MaxPageSize); // 65307 bytes
  //enum MaxPageSize = 65536;

  // Ogg header entry offsets
  enum Offsets {
    Capture = 0,
    Version = 4,
    Flags = 5,
    Granulepos = 6,
    Serialno = 14,
    Sequenceno = 18,
    Crc = 22,
    Segments = 26,
    Lacing = 27,
  }

private:
  IOCallbacks* _io;
  void* _userData;
//  VFile fl;
  //ubyte[] buf;
  ubyte[65536*2] buf;
  uint bufpos, bufused;
  uint serno, seqno;
  bool eofhit; // "end-of-stream" hit
  long logStreamSize;
  ulong bytesRead;
  ulong newpos;
  long firstpagepos;
  long firstdatapgofs = -1;
  ulong firstgranule;

  // current page info
  bool pgbos, pgeos, pgcont;
  ulong pggranule;
  ubyte segments;
  uint pgseqno, pgserno;
  uint pglength, pgdatalength;
  ubyte[255] seglen;
  uint curseg; // for packet reader

  PageInfo lastpage;

public:
  bool packetBos;
  bool packetEos;
  bool packetBop; // first packet in page?
  bool packetEop; // last packet in page?
  ulong packetGranule;
  Vec!ubyte packetData;
  uint packetLength;

private:

  // Extends I/O callbakcs
  void[] rawRead (void[] buf)
  {
    int bytesRead = _io.read(buf.ptr, cast(int)buf.length, _userData);
    return buf[0..bytesRead];
  }

  void moveBuf () {
    if (bufpos >= bufused) { bufpos = bufused = 0; return; }
    if (bufpos > 0) {
      import core.stdc.string : memmove;
      memmove(buf.ptr, buf.ptr+bufpos, bufused-bufpos);
      bufused -= bufpos;
      bufpos = 0;
    }
  }

  bool ensureBytes (uint len) {
    import core.stdc.string : memmove;
    if (len > buf.length) assert(0, "internal OggStream error");
    if (bufused-bufpos >= len) return true;
    if (eofhit) return false;
    // shift bytes
    if (bufused-bufpos > 0) {
      memmove(buf.ptr, buf.ptr+bufpos, bufused-bufpos);
      bufused -= bufpos;
      bufpos = 0;
    } else {
      bufused = bufpos = 0;
    }
    assert(bufpos == 0);
    assert(bufused < len);
    while (bufused < len) 
    {
      auto rd = rawRead(buf[bufused..len]);
      if (rd.length == 0) { eofhit = true; return false; }
      bufused += cast(uint)rd.length;
    }
    return true;
  }

  bool parsePageHeader () {
    if (!ensureBytes(Offsets.Lacing)) return false;
    if (!ensureBytes(Offsets.Lacing+buf.ptr[bufpos+Offsets.Segments])) return false;
    if (bufpos >= bufused) return false;
    auto p = (cast(const(ubyte)*)buf.ptr)+bufpos;
    if (p[0] != 'O' || p[1] != 'g' || p[2] != 'g' || p[3] != 'S') return false;
    if (p[Offsets.Version] != 0) return false;
    ubyte flags = p[Offsets.Flags];
    if ((flags&~0x07) != 0) return false;
    ulong grpos = getMemInt!ulong(p+Offsets.Granulepos);
    uint serialno = getMemInt!uint(p+Offsets.Serialno);
    uint sequenceno = getMemInt!uint(p+Offsets.Sequenceno);
    uint crc = getMemInt!uint(p+Offsets.Crc);
    ubyte segcount = p[Offsets.Segments];
    if (!ensureBytes(Offsets.Lacing+segcount)) return false;
    p = (cast(const(ubyte)*)buf.ptr)+bufpos;
    // calculate page size
    uint len = Offsets.Lacing+segcount;
    foreach (ubyte b; p[Offsets.Lacing..Offsets.Lacing+segcount]) len += b;
    if (!ensureBytes(len)) return false; // alas, invalid page
    //conwriteln("len=", len);
    p = (cast(const(ubyte)*)buf.ptr)+bufpos;
    // check page crc
    uint newcrc = crc32(p[0..Offsets.Crc]);
    ubyte[4] zeroes = 0;
    newcrc = crc32(zeroes[], newcrc); // per spec
    newcrc = crc32(p[Offsets.Crc+4..len], newcrc);
    if (newcrc != crc) return false; // bad crc
    // setup values for valid page
    pgcont = (flags&0x01 ? true : false);
    pgbos = (flags&0x02 ? true : false);
    pgeos = (flags&0x04 ? true : false);
    segments = segcount;
    if (segcount) seglen[0..segcount] = p[Offsets.Lacing..Offsets.Lacing+segcount];
    pggranule = grpos;
    pgseqno = sequenceno;
    pgserno = serialno;
    pglength = len;
    pgdatalength = len-Offsets.Lacing-segcount;
    return true;
  }

  long getfpos () {
    return _io.tell(_userData) -bufused+bufpos;
  }

  // scan for page
  bool nextPage(bool first, bool ignoreseqno=false) (long maxbytes=long.max) {
    if (eofhit) return false;
    scope(failure) eofhit = true;
    curseg = 0;
    static if (!first) bufpos += pglength; // skip page data
    clearPage();
    while (maxbytes >= Offsets.Lacing) {
      //conwriteln("0: bufpos=", bufpos, "; bufused=", bufused);
      //{ import core.stdc.stdio; printf("0: bufpos=%u; bufused=%u\n", bufpos, bufused); }
      while (bufpos >= bufused || bufused-bufpos < 4) {
        if (eofhit) break;
        if (bufpos < bufused) {
          import core.stdc.string : memmove;
          memmove(buf.ptr, buf.ptr+bufpos, bufused-bufpos);
          bufused -= bufpos;
          bufpos = 0;
        } else {
          bufpos = bufused = 0;
        }
        assert(bufused <= MaxPageSize);
        uint rdx = MaxPageSize-bufused;
        if (rdx > maxbytes) rdx = cast(uint)maxbytes;
        auto rd = rawRead(buf[bufused..bufused+rdx]);
        if (rd.length == 0) break;
        bufused += cast(uint)rd.length;
        maxbytes -= cast(uint)rd.length;
      }
      //conwriteln("1: bufpos=", bufpos, "; bufused=", bufused, "; bleft=", bufused-bufpos);
      //{ import core.stdc.stdio; printf("1: bufpos=%u; bufused=%u\n", bufpos, bufused); }
      if (bufpos >= bufused || bufused-bufpos < 4) { eofhit = true; return false; }
      uint bleft = bufused-bufpos;
      auto b = (cast(const(ubyte)*)buf.ptr)+bufpos;
      while (bleft >= 4) {
        if (b[0] == 'O' && b[1] == 'g' && b[2] == 'g' && b[3] == 'S') {
          bufpos = bufused-bleft;
          if (parsePageHeader()) {
            //conwriteln("1: bufpos=", bufpos, "; bufused=", bufused, "; segs: ", seglen[0..segments], "; pgseqno=", pgseqno, "; seqno=", seqno, "; pgserno=", pgserno, "; serno=", serno);
            eofhit = pgeos;
            static if (first) {
              firstpagepos = _io.tell(_userData)-bufused+bufpos;
              firstdatapgofs = (pggranule && pggranule != -1 ? firstpagepos : -1);
              firstgranule = pggranule;
              serno = pgserno;
              seqno = pgseqno;
              return true;
            } else {
              if (serno == pgserno) {
                //conwriteln("2: bufpos=", bufpos, "; bufused=", bufused, "; segs: ", seglen[0..segments], "; pgseqno=", pgseqno, "; seqno=", seqno, "; pgserno=", pgserno, "; serno=", serno);
                static if (!ignoreseqno) {
                  bool ok = (seqno+1 == pgseqno);
                  if (ok) ++seqno;
                } else {
                  enum ok = true;
                }
                if (ok) {
                  if (firstdatapgofs == -1 && pggranule && pggranule != -1) {
                    firstdatapgofs = _io.tell(_userData)-bufused+bufpos;
                    firstgranule = pggranule;
                  }
                  //conwriteln("3: bufpos=", bufpos, "; bufused=", bufused, "; segs: ", seglen[0..segments], "; pgseqno=", pgseqno, "; seqno=", seqno, "; pgserno=", pgserno, "; serno=", serno);
                  return true;
                }
                // alas
                static if (!ignoreseqno) {
                  eofhit = true;
                  return false;
                }
              }
            }
            // continue
          } else {
            if (eofhit) return false;
          }
          bleft = bufused-bufpos;
          b = (cast(const(ubyte)*)buf.ptr)+bufpos;
        }
        ++b;
        --bleft;
      }
      bufpos = bufused;
    }
    return false;
  }

  void clearPage () {
    pgbos = pgeos = pgcont = false;
    pggranule = 0;
    segments = 0;
    pgseqno = pgserno = 0;
    pglength = pgdatalength = 0;
    seglen[] = 0;
  }

  void clearPacket () {
    packetBos = packetBop = packetEop = packetEos = false;
    packetGranule = 0;
    packetData.fill(0);
    packetLength = 0;
  }

public:
  void close () {
    _io = null;
    lastpage = lastpage.init;
    bufpos = bufused = 0;
    curseg = 0;
    bytesRead = 0;
    eofhit = true;
    firstpagepos = 0;
    bytesRead = newpos = 0;
    logStreamSize = -1;
    clearPage();
    clearPacket();
  }

  void setup (IOCallbacks* io, void* userData) {
    scope(failure) close();
    close();
    //if (buf.length < MaxPageSize) buf.length = MaxPageSize;
    _io = io;
    _userData = userData;
    eofhit = false;
    if (!nextPage!true()) throw mallocNew!AudioFormatsException("can't find valid Ogg page");
    if (pgcont || !pgbos) throw mallocNew!AudioFormatsException("invalid starting Ogg page");
    if (!loadPacket()) throw mallocNew!AudioFormatsException("can't load Ogg packet");
  }

  static struct PageInfo {
    uint seqnum;
    ulong granule;
    long pgfpos = -1;
  }

  bool findLastPage (out PageInfo pi) {
    if (lastpage.pgfpos >= 0) {
      pi = lastpage;
      return true;
    }
    enum ChunkSize = 65535;
    //if (buf.length-bufused < ChunkSize) buf.length = bufused+ChunkSize;
    moveBuf();
    assert(buf.length-bufused >= ChunkSize);
    auto lastfpos = _io.tell(_userData);
    scope(success) _io.seek(lastfpos, false, _userData);
    auto flsize = _io.getFileLength(_userData);
    if (flsize < 0) return false;
    // linear scan backward
    auto flpos = flsize-firstpagepos-ChunkSize;
    if (flpos < firstpagepos) flpos = firstpagepos;
    for (;;) {
      _io.seek(flpos, false, _userData);
      uint bulen = (flpos+ChunkSize <= flsize ? ChunkSize : cast(uint)(flsize-flpos));
      if (bulen < 27) break;
      //{ import core.stdc.stdio; printf("bulen=%u\n", bulen); }
      {
          auto read = rawRead(buf[bufused..bufused+bulen]);
          if (read.length != bulen) 
              throw mallocNew!AudioFormatsException("read error");
      }
      uint pos = bufused+bulen-27;
      uint pend = bufused+bulen;
      for (;;) {
        if (buf.ptr[pos] == 'O' && buf.ptr[pos+1] == 'g' && buf.ptr[pos+2] == 'g' && buf.ptr[pos+3] == 'S') {
          ulong gran = getMemInt!ulong(buf.ptr+pos+Offsets.Granulepos);
          if (gran > 0 && gran != -1 && buf.ptr[pos+Offsets.Version] == 0 && getMemInt!uint(buf.ptr+pos+Offsets.Serialno) == serno) {
            // ok, possible page found
            bool rereadbuf = false;
            auto opos = pos;
            // calc page size
            ubyte segs = buf.ptr[pos+Offsets.Segments];
            uint pgsize = Offsets.Lacing+segs;
            ubyte[4] zeroes = 0;
            ubyte* p;
            uint newcrc;
            //conwritefln!"0x%08x (left: %s; pgsize0=%s)"(flpos+opos-bufused, pend-pos, pgsize);
            if (pend-pos < pgsize) {
              // load page
              pos = pend = bufused;
              rereadbuf = true;
              _io.seek(flpos+opos-bufused, false, _userData);
              for (uint bp = 0; bp < MaxPageSize; ) {
                auto rd = rawRead(buf.ptr[pos+bp..pos+MaxPageSize]);
                if (rd.length == 0) {
                  if (bp < pgsize) goto badpage;
                  break;
                }
                bp += cast(uint)rd.length;
                pend += cast(uint)rd.length;
              }
            }
            foreach (ubyte ss; buf.ptr[pos+Offsets.Lacing..pos+Offsets.Lacing+segs]) pgsize += ss;
            //conwritefln!"0x%08x (left: %s; pgsize1=%s)"(flpos+opos-bufused, pend-pos, pgsize);
            if (pend-pos < pgsize) {
              // load page
              pos = bufused;
              rereadbuf = true;
              _io.seek(flpos+opos-bufused, false, _userData);
              for (uint bp = 0; bp < MaxPageSize; ) {
                auto rd = rawRead(buf.ptr[pos+bp..pos+MaxPageSize]);
                if (rd.length == 0) {
                  if (bp < pgsize) goto badpage;
                  break;
                }
                bp += cast(uint)rd.length;
                pend += cast(uint)rd.length;
              }
            }
            // check page CRC
            p = buf.ptr+pos;
            newcrc = crc32(p[0..Offsets.Crc]);
            newcrc = crc32(zeroes[], newcrc); // per spec
            newcrc = crc32(p[Offsets.Crc+4..pgsize], newcrc);
            if (newcrc != getMemInt!uint(p+Offsets.Crc)) goto badpage;
            pi.seqnum = getMemInt!uint(p+Offsets.Sequenceno);
            pi.granule = gran;
            pi.pgfpos = flpos+opos-bufused;
            lastpage = pi;
            return true;
           badpage:
            if (rereadbuf) {
              _io.seek(flpos, false, _userData);
              auto sliceOut = rawRead(buf[bufused..bufused+ChunkSize]);
              if (sliceOut.length != ChunkSize)
                throw mallocNew!AudioFormatsException("Bad parsing");
              pos = opos;
              pend = bufused+ChunkSize;
            }
          }
        }
        if (pos == bufused) break; // prev chunk
        --pos;
      }
      if (flpos == firstpagepos) break; // not found
      flpos -= ChunkSize-30;
      if (flpos < firstpagepos) flpos = firstpagepos;
    }
    return false;
  }

  // end of stream?
  bool eos () const pure nothrow @safe @nogc { return eofhit; }

  // logical beginning of stream?
  bool bos () const pure nothrow @safe @nogc { return pgbos; }

  bool loadPacket () {
    //conwritefln!"serno=0x%08x; seqno=%s"(serno, seqno);
    packetLength = 0;
    packetBos = pgbos;
    packetEos = pgeos;
    packetGranule = pggranule;
    packetBop = (curseg == 0);
    if (curseg >= segments) {
      if (!nextPage!false()) return false;
      if (pgcont || pgbos) throw mallocNew!AudioFormatsException("invalid starting Ogg page");
      packetBos = pgbos;
      packetBop = true;
      packetGranule = pggranule;
    }
    for (;;) {
      uint copyofs = bufpos+Offsets.Lacing+segments;
      foreach (ubyte psz; seglen[0..curseg]) copyofs += psz;
      uint copylen = 0;
      bool endofpacket = false;
      while (!endofpacket && curseg < segments) {
        copylen += seglen[curseg];
        endofpacket = (seglen[curseg++] < 255);
      }
      //conwriteln("copyofs=", copyofs, "; copylen=", copylen, "; eop=", eop, "; packetLength=", packetLength, "; segments=", segments, "; curseg=", curseg);
      if (copylen > 0) {
        if (packetLength+copylen > 1024*1024*32) throw mallocNew!AudioFormatsException("Ogg packet too big");
        if (packetLength+copylen > packetData.length) 
        {
            packetData.resize(packetLength+copylen);
        }
        memcpy(&packetData[packetLength], &buf[copyofs], copylen);
        //packetData[packetLength..packetLength+copylen] = buf.ptr[copyofs..copyofs+copylen];
        packetLength += copylen;
      }
      if (endofpacket) {
        packetEop = (curseg >= segments);
        packetEos = pgeos;
        return true;
      }
      assert(curseg >= segments);
      // get next page
      if (!nextPage!false()) return false;
      if (!pgcont || pgbos) throw mallocNew!AudioFormatsException("invalid cont Ogg page");
    }
  }

  /* Page granularity seek (faster than sample granularity because we
     don't do the last bit of decode to find a specific sample).

     Seek to the last [granule marked] page preceding the specified pos
     location, such that decoding past the returned point will quickly
     arrive at the requested position. */
  // return PCM (granule) position for loaded packet
  public long seekPCM (long pos) {
    enum ChunkSize = 65535;
    eofhit = false;

    // rescales the number x from the range of [0,from] to [0,to] x is in the range [0,from] from, to are in the range [1, 1<<62-1]
    static long rescale64 (long x, long from, long to) {
      if (x >= from) return to;
      if (x <= 0) return 0;

      long frac = 0;
      long ret = 0;

      foreach (immutable _; 0..64) {
        if (x >= from) { frac |= 1; x -= from; }
        x <<= 1;
        frac <<= 1;
      }

      foreach (immutable _; 0..64) {
        if (frac&1) ret += to;
        frac >>= 1;
        ret >>= 1;
      }

      return ret;
    }

    if (pos < 0) return -1;
    if (pos <= firstgranule) {
      bufused = bufpos = 0;
      pglength = 0;
      curseg = 0;
      _io.seek(firstpagepos, false, _userData);
      eofhit = false;
      if (!nextPage!true()) throw mallocNew!AudioFormatsException("can't find valid Ogg page");
      if (pgcont || !pgbos) throw mallocNew!AudioFormatsException("invalid starting Ogg page");
      for (;;) {
        if (pggranule && pggranule != -1) {
          curseg = 0;
          //for (int p = 0; p < segments; ++p) if (seglen[p] < 255) curseg = p+1;
          //auto rtg = pggranule;
          if (!loadPacket()) throw mallocNew!AudioFormatsException("can't load Ogg packet");
          return 0;
        }
        if (!nextPage!false()) throw mallocNew!AudioFormatsException("can't find valid Ogg page");
      }
    }

    if (lastpage.pgfpos < 0) {
      PageInfo pi;
      if (!findLastPage(pi)) throw mallocNew!AudioFormatsException("can't find last Ogg page");
    }

    if (firstdatapgofs < 0) assert(0, "internal error");

    if (pos > lastpage.granule) pos = lastpage.granule;

    //if (buf.length < ChunkSize) buf.length = ChunkSize;

    long total = lastpage.granule;

    long end = lastpage.pgfpos;
    long begin = firstdatapgofs;
    long begintime = 0/*firstgranule*/;
    long endtime = lastpage.granule;
    long target = pos;//-total+begintime;
    long best = -1;
    bool got_page = false;

    // if we have only one page, there will be no bisection: grab the page here
    if (begin == end) {
      bufused = bufpos = 0;
      pglength = 0;
      curseg = 0;
      _io.seek(begin, false, _userData);
      eofhit = false;
      if (!nextPage!false()) return false;
      if (!loadPacket()) return false;
      return true;
    }

    // bisection loop
    while (begin < end) {
      long bisect;

      if (end-begin < ChunkSize) {
        bisect = begin;
      } else {
        // take a (pretty decent) guess
        bisect = begin+rescale64(target-begintime, endtime-begintime, end-begin)-ChunkSize;
        if (bisect < begin+ChunkSize) bisect = begin;
        //conwriteln("begin=", begin, "; end=", end, "; bisect=", bisect, "; rsc=", rescale64(target-begintime, endtime-begintime, end-begin));
      }

      bufused = bufpos = 0;
      pglength = 0;
      curseg = 0;
      _io.seek(bisect, false, _userData);
      eofhit = false;

      // read loop within the bisection loop
      while (begin < end) {
        // hack for nextpage
        if (!nextPage!(false, true)(end-getfpos)) {
          // there is no next page!
          if (bisect <= begin+1) {
            // no bisection left to perform: we've either found the best candidate already or failed; exit loop
            end = begin;
          } else {
            // we tried to load a fraction of the last page; back up a bit and try to get the whole last page
            if (bisect == 0) throw mallocNew!AudioFormatsException("seek error");
            bisect -= ChunkSize;

            // don't repeat/loop on a read we've already performed
            if (bisect <= begin) bisect = begin+1;

            // seek and continue bisection
            bufused = bufpos = 0;
            pglength = 0;
            curseg = 0;
            _io.seek(bisect, false, _userData);
          }
        } else {
          //conwriteln("page #", pgseqno, " (", pggranule, ") at ", getfpos);
          long granulepos;
          got_page = true;

          // got a page: analyze it
          // only consider pages from primary vorbis stream
          if (pgserno != serno) continue;

          // only consider pages with the granulepos set
          granulepos = pggranule;
          if (granulepos == -1) continue;
          //conwriteln("pos=", pos, "; gran=", granulepos, "; target=", target);

          if (granulepos < target) {
            // this page is a successful candidate! Set state
            best = getfpos; // raw offset of packet with granulepos
            begin = getfpos+pglength; // raw offset of next page
            begintime = granulepos;

            // if we're before our target but within a short distance, don't bisect; read forward
            if (target-begintime > 48000) break;

            bisect = begin; // *not* begin+1 as above
          } else {
            // this is one of our pages, but the granpos is post-target; it is not a bisection return candidate
            // the only way we'd use it is if it's the first page in the stream; we handle that case later outside the bisection
            if (bisect <= begin+1) {
              // no bisection left to perform: we've either found the best candidate already or failed; exit loop
              end = begin;
            } else {
              if (end == getfpos+pglength) {
                // bisection read to the end; use the known page boundary (result) to update bisection, back up a little bit, and try again
                end = getfpos;
                bisect -= ChunkSize;
                if (bisect <= begin) bisect = begin+1;
                bufused = bufpos = 0;
                pglength = 0;
                curseg = 0;
                _io.seek(bisect, false, _userData);
                eofhit = false;
              } else {
                // normal bisection
                end = bisect;
                endtime = granulepos;
                break;
              }
            }
          }
        }
      }
    }

    // out of bisection: did it 'fail?'
    if (best == -1) {
      bufused = bufpos = 0;
      pglength = 0;
      curseg = 0;
      //{ import core.stdc.stdio; printf("fpp=%lld\n", firstpagepos); }
      _io.seek(firstpagepos, false, _userData);
      eofhit = false;
      if (!nextPage!true()) throw mallocNew!AudioFormatsException("can't find valid Ogg page");
      if (pgcont || !pgbos) throw mallocNew!AudioFormatsException("invalid starting Ogg page");
      for (;;) {
        if (pggranule && pggranule != -1) {
          curseg = 0;
          if (!loadPacket()) throw mallocNew!AudioFormatsException("can't load Ogg packet");
          return 0;
        }
        if (!nextPage!false()) throw mallocNew!AudioFormatsException("can't find valid Ogg page");
      }
      //return 0;
    }

    // bisection found our page. seek to it, update pcm offset; easier case than raw_seek, don't keep packets preceding granulepos
    bufused = bufpos = 0;
    pglength = 0;
    curseg = 0;
    _io.seek(best, false, _userData);    
    if (!nextPage!(false, true)()) throw mallocNew!AudioFormatsException("wtf?!");
    auto rtg = pggranule;
    seqno = pgseqno;
    // pull out all but last packet; the one right after granulepos
    for (int p = 0; p < segments; ++p) if (seglen[p] < 255) curseg = p+1;
    if (!loadPacket()) throw mallocNew!AudioFormatsException("wtf?!");
    return rtg;
  }

static:
  T getMemInt(T) (const(void)* pp) {
    static if (is(T == byte) || is(T == ubyte)) {
      return *cast(const(ubyte)*)pp;
    } else static if (is(T == short) || is(T == ushort)) {
      version(LittleEndian) {
        return *cast(const(T)*)pp;
      } else {
        auto pp = cast(const(ubyte)*)pp;
        return cast(T)(pp[0]|(pp[1]<<8));
      }
    } else static if (is(T == int) || is(T == uint)) {
      version(LittleEndian) {
        return *cast(const(T)*)pp;
      } else {
        auto pp = cast(const(ubyte)*)pp;
        return cast(T)(pp[0]|(pp[1]<<8)|(pp[2]<<16)|(pp[3]<<24));
      }
    } else static if (is(T == long) || is(T == ulong)) {
      version(LittleEndian) {
        return *cast(const(T)*)pp;
      } else {
        auto pp = cast(const(ubyte)*)pp;
        return cast(T)(
          (cast(ulong)pp[0])|((cast(ulong)pp[1])<<8)|((cast(ulong)pp[2])<<16)|((cast(ulong)pp[3])<<24)|
          ((cast(ulong)pp[4])<<32)|((cast(ulong)pp[5])<<40)|((cast(ulong)pp[6])<<48)|((cast(ulong)pp[7])<<56)
        );
      }
    } else {
      static assert(0, "invalid type for getMemInt: '"~T.stringof~"'");
    }
  }

  uint crc32 (const(void)[] buf, uint crc=0) nothrow @trusted @nogc {
    static immutable uint[256] crctable = (){
      // helper to initialize lookup for direct-table CRC (illustrative; we use the static init below)
      static uint _ogg_crc_entry (uint index) {
        uint r = index<<24;
        foreach (immutable _; 0..8) {
          if (r&0x80000000U) {
            r = (r<<1)^0x04c11db7;
            /* The same as the ethernet generator
                polynomial, although we use an
                unreflected alg and an init/final
                of 0, not 0xffffffff */
          } else {
            r <<= 1;
          }
        }
        return (r&0xffffffffU);
      }
      uint[256] res;
      foreach (immutable idx, ref uint v; res[]) v = _ogg_crc_entry(cast(uint)idx);
      return res;
    }();
    foreach (ubyte b; cast(const(ubyte)[])buf) crc = (crc<<8)^crctable.ptr[((crc>>24)&0xFF)^b];
    return crc;
  }
}


// ////////////////////////////////////////////////////////////////////////// //
nothrow @nogc {
enum OPUS_SEEK_PREROLL_MS = 80;
enum OPUS_HEAD_SIZE = 19;

static int opus_header (AVCtx* avf, ref OggStream ogg) {
  //uint8_t *packet              = os.buf + os.pstart;
  if (ogg.packetBos) {
    if (ogg.packetLength < OPUS_HEAD_SIZE || (ogg.packetData[8]&0xF0) != 0) return AVERROR_INVALIDDATA;
      //st.codecpar.codec_type = AVMEDIA_TYPE_AUDIO;
      //st.codecpar.codec_id   = AV_CODEC_ID_OPUS;
      //st.codecpar.channels   = ost.packetData[8];

      avf.preskip = ogg.getMemInt!ushort(ogg.packetData.ptr+10);
      //!!!st.codecpar.initial_padding = priv.pre_skip;
      /*orig_sample_rate    = AV_RL32(packet + 12);*/
      /*gain                = AV_RL16(packet + 16);*/
      /*channel_map         = AV_RL8 (packet + 18);*/

      //if (ff_alloc_extradata(st.codecpar, os.psize)) return AVERROR(ENOMEM);
      if (avf.extradata) av_free(avf.extradata);
      avf.extradata = av_mallocz!ubyte(ogg.packetLength);
      if (avf.extradata is null) return -1;
      avf.extradata[0..ogg.packetLength] = ogg.packetData[0..ogg.packetLength];
      avf.extradata_size = cast(uint)ogg.packetLength;

      //st.codecpar.sample_rate = 48000;
      //st.codecpar.seek_preroll = av_rescale(OPUS_SEEK_PREROLL_MS, st.codecpar.sample_rate, 1000);
      //avpriv_set_pts_info(st, 64, 1, 48000);
      avf.need_comments = 1;
      return 2;
  }

  if (avf.need_comments) {
    import core.stdc.string : memcmp;
    if (ogg.packetLength < 8 || memcmp(ogg.packetData.ptr, "OpusTags".ptr, 8) != 0) return AVERROR_INVALIDDATA;
    //ff_vorbis_stream_comment(avf, st, ogg.packetData.ptr + 8, ogg.packetLength - 8);
    --avf.need_comments;
    return 1;
  }

  return 0;
}

static int opus_duration (const(uint8_t)* src, int size) {
  uint nb_frames  = 1;
  uint toc        = src[0];
  uint toc_config = toc>>3;
  uint toc_count  = toc&3;
  uint frame_size = toc_config < 12 ? FFMAX(480, 960 * (toc_config & 3)) :
                    toc_config < 16 ? 480 << (toc_config & 1) : 120 << (toc_config & 3);
  if (toc_count == 3) {
    if (size < 2) return AVERROR_INVALIDDATA;
    nb_frames = src[1]&0x3F;
  } else if (toc_count) {
    nb_frames = 2;
  }
  return frame_size*nb_frames;
}

static int opus_packet (AVCtx* avf, ref OggStream ogg) {
  int ret;

  if (!ogg.packetLength) return AVERROR_INVALIDDATA;
  if (ogg.packetGranule > (1UL<<62)) {
    //av_log(avf, AV_LOG_ERROR, "Unsupported huge granule pos %"PRId64 "\n", os.granule);
    return AVERROR_INVALIDDATA;
  }

  //if ((!ogg.lastpts || ogg.lastpts == AV_NOPTS_VALUE) && !(ogg.flags & OGG_FLAG_EOS))
  if (ogg.packetGranule != 0 && !ogg.packetEos) {
      /*!
      int seg, d;
      int duration;
      uint8_t *last_pkt  = os.buf + os.pstart;
      uint8_t *next_pkt  = last_pkt;

      duration = 0;
      seg = os.segp;
      d = opus_duration(last_pkt, ogg.packetLength);
      if (d < 0) {
          os.pflags |= AV_PKT_FLAG_CORRUPT;
          return 0;
      }
      duration += d;
      last_pkt = next_pkt =  next_pkt + ogg.packetLength;
      for (; seg < os.nsegs; seg++) {
          next_pkt += os.segments[seg];
          if (os.segments[seg] < 255 && next_pkt != last_pkt) {
              int d = opus_duration(last_pkt, next_pkt - last_pkt);
              if (d > 0)
                  duration += d;
              last_pkt = next_pkt;
          }
      }
      os.lastpts                 =
      os.lastdts                 = os.granule - duration;
      */
  }

  if ((ret = opus_duration(ogg.packetData.ptr, ogg.packetLength)) < 0) return ret;

  /*!
  os.pduration = ret;
  if (os.lastpts != AV_NOPTS_VALUE) {
      if (st.start_time == AV_NOPTS_VALUE)
          st.start_time = os.lastpts;
      priv.cur_dts = os.lastdts = os.lastpts -= priv.pre_skip;
  }

  priv.cur_dts += os.pduration;
  if ((os.flags & OGG_FLAG_EOS)) {
      int64_t skip = priv.cur_dts - os.granule + priv.pre_skip;
      skip = FFMIN(skip, os.pduration);
      if (skip > 0) {
          os.pduration = skip < os.pduration ? os.pduration - skip : 1;
          os.end_trimming = skip;
          //av_log(avf, AV_LOG_DEBUG, "Last packet was truncated to %d due to end trimming.\n", os.pduration);
      }
  }
  */

  return 0;
}

} // nothrow @nogc


// ////////////////////////////////////////////////////////////////////////// //
align(1) union TrickyFloatUnion {
align(1):
  float f;
  int i;
}
static assert(TrickyFloatUnion.i.sizeof == 4 && TrickyFloatUnion.f.sizeof == 4);
// add (1<<23) to convert to int, then divide by 2^SHIFT, then add 0.5/2^SHIFT to round
enum Float2IntScaled(string x, string d) =
  "{ TrickyFloatUnion temp = void; temp.f = ("~x~")+(1.5f*(1<<(23-15))+0.5f/(1<<15));"~
  "("~d~") = temp.i-(((150-15)<<23)+(1<<22));"~
  "if (cast(uint)(("~d~")+32768) > 65535) ("~d~") = (("~d~") < 0 ? -32768 : 32767); }";


// ////////////////////////////////////////////////////////////////////////// //

struct OpusFileCtx {
private:
@nogc:
  AVCtx ctx;
  ubyte* commbuf;
  uint cblen;
  OpusContext c;
  public OggStream ogg;
  OggStream.PageInfo lastpage;
  short[960*3*2] samples;
  float[960*3*2] sbuffer;
  bool wantNewPacket;
  ulong curpcm; // for page end; let's hope that nobody will create huge ogg pages

  void close () {
    av_freep(&commbuf);
    av_freep(&ctx.extradata);
    opus_decode_close(&c);
    ogg.close();
  }

public:
  enum rate = 48000; // always
  ubyte channels () const pure nothrow @safe @nogc { return cast(ubyte)c.streams[0].output_channels; }
  // all timing is in milliseconds
  long duration () const pure nothrow @safe @nogc { return (lastpage.granule/48); }
  long curtime () const pure nothrow @safe @nogc { return (curpcm/48); }

  // in samples, not multiplied by channel count
  long smpduration () const pure nothrow @safe @nogc { return lastpage.granule; }
  long smpcurtime () const pure nothrow @safe @nogc { return curpcm; }

  const(char)[] vendor () const pure nothrow @trusted @nogc {
    if (commbuf is null || cblen < 4) return null;
    uint len = commbuf[0]|(commbuf[1]<<8)|(commbuf[2]<<16)|(commbuf[3]<<24);
    if (len > cblen || cblen-len < 4) return null;
    return cast(const(char)[])(commbuf[4..4+len]);
  }

  uint commentCount () const pure nothrow @trusted @nogc {
    if (commbuf is null || cblen < 4) return 0;
    uint len = commbuf[0]|(commbuf[1]<<8)|(commbuf[2]<<16)|(commbuf[3]<<24);
    if (len > cblen || cblen-len < 4) return 0;
    uint cpos = 4+len;
    if (cpos >= cblen || cblen-cpos < 4) return 0;
    uint count = commbuf[cpos+0]|(commbuf[cpos+1]<<8)|(commbuf[cpos+2]<<16)|(commbuf[cpos+3]<<24);
    cpos += 4;
    uint res = 0;
    while (count > 0 && cpos+4 <= cblen) {
      len = commbuf[cpos+0]|(commbuf[cpos+1]<<8)|(commbuf[cpos+2]<<16)|(commbuf[cpos+3]<<24);
      cpos += 4;
      if (cpos > cblen || cblen-cpos < len) break;
      ++res;
      cpos += len;
      --count;
    }
    return res;
  }

  const(char)[] comment (uint cidx) const pure nothrow @trusted @nogc {
    if (commbuf is null || cblen < 4) return null;
    uint len = commbuf[0]|(commbuf[1]<<8)|(commbuf[2]<<16)|(commbuf[3]<<24);
    if (len > cblen || cblen-len < 4) return null;
    uint cpos = 4+len;
    if (cpos >= cblen || cblen-cpos < 4) return null;
    uint count = commbuf[cpos+0]|(commbuf[cpos+1]<<8)|(commbuf[cpos+2]<<16)|(commbuf[cpos+3]<<24);
    cpos += 4;
    while (count > 0 && cpos+4 <= cblen) {
      len = commbuf[cpos+0]|(commbuf[cpos+1]<<8)|(commbuf[cpos+2]<<16)|(commbuf[cpos+3]<<24);
      cpos += 4;
      if (cpos > cblen || cblen-cpos < len) break;
      if (cidx == 0) return cast(const(char)[])(commbuf[cpos..cpos+len]);
      --cidx;
      cpos += len;
      --count;
    }
    return null;
  }

  private short getGain () const pure nothrow @trusted @nogc {
    if (commbuf is null || cblen < 4) return 0;
    uint len = commbuf[0]|(commbuf[1]<<8)|(commbuf[2]<<16)|(commbuf[3]<<24);
    if (len > cblen || cblen-len < 4) return 0;
    uint cpos = 4+len;
    if (cpos >= cblen || cblen-cpos < 4) return 0;
    uint count = commbuf[cpos+0]|(commbuf[cpos+1]<<8)|(commbuf[cpos+2]<<16)|(commbuf[cpos+3]<<24);
    cpos += 4;
    while (count > 0 && cpos+4 <= cblen) {
      len = commbuf[cpos+0]|(commbuf[cpos+1]<<8)|(commbuf[cpos+2]<<16)|(commbuf[cpos+3]<<24);
      cpos += 4;
      if (cpos > cblen || cblen-cpos < len) break;
      {
        auto cmt = cast(const(char)[])(commbuf[cpos..cpos+len]);
        enum GainName = "R128_TRACK_GAIN="; //-573
        while (cmt.length && cmt.ptr[0] <= ' ') cmt = cmt[1..$];
        while (cmt.length && cmt[$-1] <= ' ') cmt = cmt[0..$-1];
        if (cmt.length > GainName.length) {
          bool ok = true;
          foreach (immutable xidx, char ch; cmt[0..GainName.length]) {
            if (ch >= 'a' && ch <= 'z') ch -= 32;
            if (ch != GainName[xidx]) { ok = false; break; }
          }
          if (ok) {
            bool neg = false;
            int v = 0;
            cmt = cmt[GainName.length..$];
                 if (cmt.length && cmt[0] == '-') { neg = true; cmt = cmt[1..$]; }
            else if (cmt.length && cmt[0] == '+') cmt = cmt[1..$];
            if (cmt.length == 0) v = -1;
            while (cmt.length) {
              int c = cmt.ptr[0];
              cmt = cmt[1..$];
              if (c < '0' || c > '9') { v = -1; break; }
              v = v*10+c-'0';
              if ((neg && v > 32768) || (!neg && v > 32767)) { v = -1; break; }
            }
            if (v >= 0) {
              if (neg) v = -v;
              return cast(short)v;
            }
          }
        }
      }
      cpos += len;
      --count;
    }
    return 0;
  }

  void seek (long newtime) {
    if (newtime < 0) newtime = 0;
    if (newtime >= duration) newtime = duration;
    if (newtime >= duration) {
      ogg.bufused = ogg.bufpos = 0;
      ogg.pglength = 0;
      ogg.curseg = 0;
      ogg._io.seek(ogg.lastpage.pgfpos, false, ogg._userData);
      //{ import core.stdc.stdio; printf("lpofs=0x%08llx\n", ogg.lastpage.pgfpos); }
      ogg.eofhit = false;
      if (!ogg.nextPage!(false, true)()) throw mallocNew!AudioFormatsException("can't find valid Ogg page");
      ogg.seqno = ogg.pgseqno;
      ogg.curseg = 0;
      for (int p = 0; p < ogg.segments; ++p) if (ogg.seglen[p] < 255) ogg.curseg = p+1;
      curpcm = ogg.pggranule;
      wantNewPacket = true;
      return;
    }
    long np = ogg.seekPCM(newtime*48 < ctx.preskip ? 0 : newtime*48-ctx.preskip);
    wantNewPacket = false;
    if (np < ctx.preskip) {
      curpcm = 0;
    } else {
      curpcm = np-ctx.preskip;
      // skip 80 msecs, as per specs (buggy, but...)
      auto oldpcm = curpcm;
      while (curpcm-oldpcm < 3840) {
        if (readFrame().length == 0) break;
        //{ import core.stdc.stdio; printf("frdiff=%lld\n", curpcm-oldpcm); }
      }
    }
  }

  // read and decode one sound frame; return samples or null
  short[] readFrame () return {
    AVFrame frame;
    AVPacket pkt;
    ubyte*[2] eptr;
    float*[2] fptr;
    for (;;) {
      if (wantNewPacket) {
        if (!ogg.loadPacket()) return null;
      }
      //if (ogg.pggranule > 0 && ogg.pggranule != -1 && ogg.pggranule >= ctx.preskip) curpcm = ogg.pggranule-ctx.preskip;
      wantNewPacket = true;
      frame.linesize[0] = sbuffer.length*sbuffer[0].sizeof;
      pkt.data = ogg.packetData.ptr;
      pkt.size = cast(uint)ogg.packetLength;
      eptr[0] = cast(ubyte*)&sbuffer[0];
      eptr[1] = cast(ubyte*)&sbuffer[sbuffer.length/2];
      fptr[0] = cast(float*)eptr[0];
      fptr[1] = cast(float*)eptr[1];
      frame.extended_data = eptr.ptr;
      int gotfrptr = 0;
      auto r = opus_decode_packet(&c, &frame, &gotfrptr, &pkt);
      if (r < 0) throw mallocNew!AudioFormatsException("error processing opus frame");
      if (!gotfrptr) continue;
      curpcm += r;
      //if (ogg.packetGranule && ogg.packetGranule != -1) lastgran = ogg.packetGranule-ctx.preskip;
      //conwritef!"\r%s:%02s / %s:%02s"((lastgran/48000)/60, (lastgran/48000)%60, (lastpage.granule/48000)/60, (lastpage.granule/48000)%60);
      short* dptr = samples.ptr;
      int v;
      foreach (immutable spos; 0..r) {
        foreach (immutable chn; 0..channels) {
          mixin(Float2IntScaled!("*fptr[chn]++", "v"));
          *dptr++ = cast(short)v;
        }
      }
      return samples.ptr[0..r*channels];
    }
  }
}


public alias OpusFile = OpusFileCtx*;


public OpusFile opusOpen (IOCallbacks* io, void* userData) 
{
  OpusFile of = av_mallocz!OpusFileCtx(1);
  if (of is null) throw mallocNew!AudioFormatsException("out of memory");
  *of = OpusFileCtx.init; // just in case
  scope(failure) { av_freep(&of.commbuf); av_freep(&of.ctx.extradata); av_free(of); }

  io.seek(false, false, userData);
  of.ogg.setup(io, userData);
  scope(failure) of.ogg.close();

  if (!of.ogg.findLastPage(of.lastpage)) throw mallocNew!AudioFormatsException("can't find last page");

  for (;;) {
    auto r = opus_header(&of.ctx, of.ogg);
    if (r < 0) throw mallocNew!AudioFormatsException("can't find opus header");
    // current packet is tags?
    if (of.ogg.packetLength >= 12 && of.commbuf is null && cast(const(char)[])(of.ogg.packetData[0..8]) == "OpusTags") {
      of.commbuf = av_mallocz!ubyte(of.ogg.packetLength-8);
      if (of.commbuf !is null) {
        import core.stdc.string : memcpy;
        memcpy(of.commbuf, of.ogg.packetData.ptr+8, of.ogg.packetLength-8);
        of.cblen = of.ogg.packetLength-8;
      }
    }
    if (!of.ogg.loadPacket()) throw mallocNew!AudioFormatsException("invalid opus file");
    if (r == 1) break;
  }

  if (of.ogg.pggranule < of.ctx.preskip) throw mallocNew!AudioFormatsException("invalid starting granule");
  if (of.lastpage.granule < of.ctx.preskip) throw mallocNew!AudioFormatsException("invalid ending granule");
  of.lastpage.granule -= of.ctx.preskip;

  if (opus_decode_init(&of.ctx, &of.c, of.getGain) < 0) throw mallocNew!AudioFormatsException("can't init opus decoder");
  scope(failure) opus_decode_close(&of.c);

  if (of.c.nb_streams != 1) throw mallocNew!AudioFormatsException("only mono and stereo opus streams are supported");
  // just in case, check the impossible
  if (of.c.streams[0].output_channels < 1 || of.c.streams[0].output_channels > 2) throw mallocNew!AudioFormatsException("only mono and stereo opus streams are supported");

  return of;
}


public void opusClose (ref OpusFile of) {
  if (of !is null) {
    of.close();
    av_freep(&of);
  }
}
