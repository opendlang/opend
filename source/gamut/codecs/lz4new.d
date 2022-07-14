/*
   LZ4 - Fast LZ compression algorithm
   Copyright (C) 2011-2020, Yann Collet.

   BSD 2-Clause License (http://www.opensource.org/licenses/bsd-license.php)

   Redistribution and use in source and binary forms, with or without
   modification, are permitted provided that the following conditions are
   met:

       * Redistributions of source code must retain the above copyright
   notice, this list of conditions and the following disclaimer.
       * Redistributions in binary form must reproduce the above
   copyright notice, this list of conditions and the following disclaimer
   in the documentation and/or other materials provided with the
   distribution.

   THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
   "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
   LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
   A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
   OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
   SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
   LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
   DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
   THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
   (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
   OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

   You can contact the author at :
    - LZ4 homepage : http://www.lz4.org
    - LZ4 source repository : https://github.com/lz4/lz4
*/
// Another translation attempt of LZ4 repo commit 510dc6370610fc6f02bef963040b35d2712c4b7e
module gamut.codecs.lz4new; 

import core.bitop;
import core.stdc.stdlib: malloc, calloc, free;
import core.stdc.string: memset, memcpy, memmove;

nothrow @nogc:

/**
Introduction

LZ4 is lossless compression algorithm, providing compression speed >500 MB/s per core,
scalable with multi-cores CPU. It features an extremely fast decoder, with speed in
multiple GB/s per core, typically reaching RAM speed limits on multi-core systems.

The LZ4 compression library provides in-memory compression and decompression functions.
It gives full buffer control to user.
Compression can be done in:
- a single step (described as Simple Functions)
- a single step, reusing a context (described in Advanced Functions)
- unbounded multiple steps (described as Streaming compression)

lz4.h generates and decodes LZ4-compressed blocks (doc/lz4_Block_format.md).
Decompressing such a compressed block requires additional metadata.
Exact metadata depends on exact decompression function.
For the typical case of LZ4_decompress_safe(),
metadata includes block's compressed size, and maximum bound of decompressed size.
Each application is free to encode and pass such metadata in whichever way it wants.

lz4.h only handle blocks, it can not generate Frames.

Blocks are different from Frames (doc/lz4_Frame_format.md).
Frames bundle both blocks and metadata in a specified manner.
Embedding metadata is required for compressed data to be self-contained and portable.
Frame format is delivered through a companion API, declared in lz4frame.h.
The `lz4` CLI can only manage frames.
*/


/*------   Version   ------*/
enum LZ4_VERSION_MAJOR    = 1;    /* for breaking interface changes  */
enum LZ4_VERSION_MINOR    = 9;    /* for new (non-breaking) interface capabilities */
enum LZ4_VERSION_RELEASE  = 4;    /* for tweaks, bug-fixes, or development */

enum LZ4_VERSION_NUMBER = (LZ4_VERSION_MAJOR *100*100 + LZ4_VERSION_MINOR *100 + LZ4_VERSION_RELEASE);
enum string LZ4_VERSION_STRING = "1.9.4";

/*-************************************
*  Tuning parameter
**************************************/
enum LZ4_MEMORY_USAGE_MIN = 10;
enum LZ4_MEMORY_USAGE_DEFAULT = 14;
enum LZ4_MEMORY_USAGE_MAX = 20;

/*!
* LZ4_MEMORY_USAGE :
* Memory usage formula : N.2^N Bytes (examples : 10 . 1KB; 12 . 4KB ; 16 . 64KB; 20 . 1MB; )
* Increasing memory usage improves compression ratio, at the cost of speed.
* Reduced memory usage may improve speed at the cost of ratio, thanks to better cache locality.
* Default value is 14, for 16KB, which nicely fits into Intel x86 L1 cache
*/
enum LZ4_MEMORY_USAGE = LZ4_MEMORY_USAGE_DEFAULT;

static assert (LZ4_MEMORY_USAGE >= LZ4_MEMORY_USAGE_MIN);
static assert (LZ4_MEMORY_USAGE <= LZ4_MEMORY_USAGE_MAX);


/*-************************************
*  Advanced Functions
**************************************/
enum LZ4_MAX_INPUT_SIZE = 0x7E000000;   /* 2 113 929 216 bytes */

alias LZ4_COMPRESSBOUND = LZ4_compressBound; ///

/*-**********************************************
*  Streaming Decompression Functions
*  Bufferless synchronous API
************************************************/
alias LZ4_streamDecode_t = LZ4_streamDecode_u; /* tracking context */

int LZ4_DECODER_RING_BUFFER_SIZE(int maxBlockSize)
{
    assert (maxBlockSize >= 0 && maxBlockSize <= LZ4_MAX_INPUT_SIZE);
    return 65536 + 14 + maxBlockSize;
}

/*! In-place compression and decompression
*
* It's possible to have input and output sharing the same buffer,
* for highly constrained memory environments.
* In both cases, it requires input to lay at the end of the buffer,
* and decompression to start at beginning of the buffer.
* Buffer size must feature some margin, hence be larger than final size.
*
* |<------------------------buffer--------------------------------.|
*                             |<-----------compressed data--------.|
* |<-----------decompressed size-----------------.|
*                                                  |<----margin---.|
*
* This technique is more useful for decompression,
* since decompressed size is typically larger,
* and margin is short.
*
* In-place decompression will work inside any buffer
* which size is >= LZ4_DECOMPRESS_INPLACE_BUFFER_SIZE(decompressedSize).
* This presumes that decompressedSize > compressedSize.
* Otherwise, it means compression actually expanded data,
* and it would be more efficient to store such data with a flag indicating it's not compressed.
* This can happen when data is not compressible (already compressed, or encrypted).
*
* For in-place compression, margin is larger, as it must be able to cope with both
* history preservation, requiring input data to remain unmodified up to LZ4_DISTANCE_MAX,
* and data expansion, which can happen when input is not compressible.
* As a consequence, buffer size requirements are much higher,
* and memory savings offered by in-place compression are more limited.
*
* There are ways to limit this cost for compression :
* - Reduce history size, by modifying LZ4_DISTANCE_MAX.
*   Note that it is a compile-time constant, so all compressions will apply this limit.
*   Lower values will reduce compression ratio, except when input_size < LZ4_DISTANCE_MAX,
*   so it's a reasonable trick when inputs are known to be small.
* - Require the compressor to deliver a "maximum compressed size".
*   This is the `dstCapacity` parameter in `LZ4_compress*()`.
*   When this size is < LZ4_COMPRESSBOUND(inputSize), then compression can fail,
*   in which case, the return code will be 0 (zero).
*   The caller must be ready for these cases to happen,
*   and typically design a backup scheme to send data uncompressed.
* The combination of both techniques can significantly reduce
* the amount of margin required for in-place compression.
*
* In-place compression can work in any buffer
* which size is >= (maxCompressedSize)
* with maxCompressedSize == LZ4_COMPRESSBOUND(srcSize) for guaranteed compression success.
* LZ4_COMPRESS_INPLACE_BUFFER_SIZE() depends on both maxCompressedSize and LZ4_DISTANCE_MAX,
* so it's possible to reduce memory requirements by playing with them.
*/

int LZ4_DECOMPRESS_INPLACE_MARGIN(int compressedSize)
{
    return (compressedSize >> 8) + 32;
}

int LZ4_DECOMPRESS_INPLACE_BUFFER_SIZE(int decompressedSize)
{
    /**< note: presumes that compressedSize < decompressedSize. 
    note2: margin is overestimated a bit, since it could use compressedSize 
    instead */
    return decompressedSize + LZ4_DECOMPRESS_INPLACE_MARGIN(decompressedSize);
}

/* history window size; can be user-defined at compile time */
enum int LZ4_DISTANCE_MAX = 65535;   /* set to maximum value by default */

/* LZ4_DISTANCE_MAX can be safely replaced by srcSize when it's smaller */
enum int LZ4_COMPRESS_INPLACE_MARGIN = (LZ4_DISTANCE_MAX + 32);

int LZ4_COMPRESS_INPLACE_BUFFER_SIZE(int maxCompressedSize)
{
    /**< maxCompressedSize is generally LZ4_COMPRESSBOUND(inputSize), 
    but can be set to any lower value, with the risk that compression 
    can fail (return code 0(zero)) */
    return maxCompressedSize + LZ4_COMPRESS_INPLACE_MARGIN;
}

/*-************************************************************
*  Private Definitions
**************************************************************
* Do not use these definitions directly.
* They are only exposed to allow static allocation of `LZ4_stream_t` and `LZ4_streamDecode_t`.
* Accessing members will expose user code to API and/or ABI break in future versions of the library.
**************************************************************/
enum LZ4_HASHLOG       = (LZ4_MEMORY_USAGE-2);
enum LZ4_HASHTABLESIZE = (1 << LZ4_MEMORY_USAGE);
enum LZ4_HASH_SIZE_U32 =(1 << LZ4_HASHLOG);       /* required as macro for static allocation */

alias LZ4_i8 = byte;
alias LZ4_byte = ubyte;
alias LZ4_u16 = ushort;
alias LZ4_u32 = uint;

struct LZ4_stream_t_internal 
{
    LZ4_u32[LZ4_HASH_SIZE_U32] hashTable;
    LZ4_u32 currentOffset;
    LZ4_u32 tableType;
    const(LZ4_byte)* dictionary;
    const(LZ4_stream_t_internal)* dictCtx;
    LZ4_u32 dictSize;
}

struct LZ4_streamDecode_t_internal 
{
    const(LZ4_byte)* externalDict;
    size_t extDictSize;
    const(LZ4_byte)* prefixEnd;
    size_t prefixSize;
}


/*! LZ4_stream_t :
*  Do not use below internal definitions directly !
*  Declare or allocate an LZ4_stream_t instead.
*  LZ4_stream_t can also be created using LZ4_createStream(), which is recommended.
*  The structure definition can be convenient for static allocation
*  (on stack, or as part of larger structure).
*  Init this structure with LZ4_initStream() before first use.
*  note : only use this definition in association with static linking !
*  this definition is not API/ABI safe, and may change in future versions.
*  Note : OS400 pointers are 16 bytes and the compiler adds 8 bytes of padding after
*  tableType and 12 bytes after dictSize to ensure the structure is word aligned:
*  |=========================================================
*  |      Offset       |      Length       | Member Name
*  |=========================================================
*  |       0           |   16384           |  hashTable[4096]
*  |   16384           |       4           |  currentOffset
*  |   16388           |       4           |  tableType
*  |   16392           |       8           |  ***PADDING***
*  |   16400           |      16           |  dictionary
*  |   16416           |      16           |  dictCtx
*  |   16432           |       4           |  dictSize
*  |   16436           |      12           |  ***PADDING***
*  ==========================================================
*/
enum size_t LZ4_STREAMSIZE = ((1UL << LZ4_MEMORY_USAGE) + (((void*).sizeof==16) ? 64 : 32));  /* static size, for inter-version compatibility */
enum LZ4_STREAMSIZE_VOIDP = (LZ4_STREAMSIZE / (void*).sizeof);

union LZ4_stream_t 
{
    void*[LZ4_STREAMSIZE_VOIDP] table;
    LZ4_stream_t_internal internal_donotuse;
} /* previously typedef'd to LZ4_stream_t */


/*! LZ4_streamDecode_t :
*  information structure to track an LZ4 stream during decompression.
*  init this structure  using LZ4_setStreamDecode() before first use.
*  note : only use in association with static linking !
*         this definition is not API/ABI safe,
*         and may change in a future version !
*  Note : Same story as LZ4_STREAMSIZE for OS400 in terms of additional padding to 
*         ensure pointers start on and structures finish on 16 byte boundaries
*         |=========================================================
*         |      Offset       |      Length       | Member Name
*         |=========================================================
*         |       0           |      16           |    externalDict 
*         |      16           |       4           |    extDictSize  
*         |      20           |      12           |    ***PADDING***
*         |      32           |      16           |    prefixEnd    
*         |      48           |       4           |    prefixSize   
*         |      52           |      12           |    ***PADDING***
*         ==========================================================
*/
enum size_t LZ4_STREAMDECODESIZE_U64 = (4 + (((void*).sizeof==16) ? 4 : 0));
enum size_t LZ4_STREAMDECODESIZE     = LZ4_STREAMDECODESIZE_U64 * ulong.sizeof;
union LZ4_streamDecode_u 
{
    ulong[LZ4_STREAMDECODESIZE_U64] table;
    LZ4_streamDecode_t_internal internal_donotuse;
}   /* previously typedef'd to LZ4_streamDecode_t */


/*! LZ4_resetStream() :
*  An LZ4_stream_t structure must be initialized at least once.
*  This is done with LZ4_initStream(), or LZ4_resetStream().
*  Consider switching to LZ4_initStream(),
*  invoking LZ4_resetStream() will trigger deprecation warnings in the future.
*/
public void LZ4_resetStream (LZ4_stream_t* streamPtr);



/*-************************************
*  Tuning parameters
**************************************/
/*
 * LZ4_HEAPMODE :
 * Select how default compression functions will allocate memory for their hash table,
 * in memory stack (0:default, fastest), or in memory heap (1:requires malloc()).
 */
enum LZ4_HEAPMODE = 0; // Note: both supported in this translation

/*
 * LZ4_ACCELERATION_DEFAULT :
 * Select "acceleration" for LZ4_compress_fast() when parameter value <= 0
 */
enum LZ4_ACCELERATION_DEFAULT = 1;

/*
 * LZ4_ACCELERATION_MAX :
 * Any "acceleration" value higher than this threshold
 * get treated as LZ4_ACCELERATION_MAX instead (fix #876)
 */
enum LZ4_ACCELERATION_MAX = 65537;


/*-************************************
*  CPU Feature Detection
**************************************/
/* LZ4_FORCE_MEMORY_ACCESS
 * By default, access to unaligned memory is controlled by `memcpy()`, which is safe and portable.
 * Unfortunately, on some target/compiler combinations, the generated assembly is sub-optimal.
 * The below switch allow to select different access method for improved performance.
 * Method 0 (default) : use `memcpy()`. Safe and portable.
 */
enum LZ4_FORCE_MEMORY_ACCESS = 0; // always memcpy

/*-************************************
*  Dependency
**************************************/

bool likely(bool b) { return b; } // PERF: use the hint
bool unlikely(bool b) { return b; } // PERF: use the hint


/* Should the alignment test prove unreliable, for some reason,
 * it can be disabled by setting LZ4_ALIGN_TEST to 0 */
enum LZ4_ALIGN_TEST = 1;


/*-************************************
*  Memory routines
**************************************/

alias ALLOC = malloc;

void* ALLOC_AND_ZERO(size_t s)
{
    return calloc(1, s);
}

void FREEMEM(void* p)
{
    free(p);
}

alias MEM_INIT = memset;


/*-************************************
*  Common Constants
**************************************/
enum MINMATCH = 4;

enum WILDCOPYLENGTH = 8;
enum LASTLITERALS   = 5;    /* see ../doc/lz4_Block_format.md#parsing-restrictions */
enum MFLIMIT        = 12;   /* see ../doc/lz4_Block_format.md#parsing-restrictions */
enum MATCH_SAFEGUARD_DISTANCE = ((2*WILDCOPYLENGTH) - MINMATCH);   /* ensure it's possible to write 2 x wildcopyLength without overflowing output buffer */
enum FASTLOOP_SAFE_DISTANCE = 64;
enum int LZ4_minLength = (MFLIMIT+1);

enum KB = (1 <<10);
enum MB = (1 <<20);
enum GB = (1U<<30);

enum LZ4_DISTANCE_ABSOLUTE_MAX = 65535;
static if (LZ4_DISTANCE_MAX > LZ4_DISTANCE_ABSOLUTE_MAX)   /* max supported by LZ4 format */
{
    static assert(false, "LZ4_DISTANCE_MAX is too big : must be <= 65535");
}

enum ML_BITS  = 4;
enum ML_MASK  = ((1U<<ML_BITS)-1);
enum RUN_BITS = (8-ML_BITS);
enum RUN_MASK = ((1U<<RUN_BITS)-1);



int LZ4_isAligned(const(void)* ptr, size_t alignment)
{
    return (cast(size_t)ptr & (alignment -1)) == 0;
}


/*-************************************
*  Types
**************************************/
alias BYTE = ubyte;
alias U16 = ushort;
alias U32 = uint;
alias S32 = int;
alias U64 = ulong;
alias uptrval = size_t;
alias reg_t = size_t;

alias limitedOutput_directive = int;
enum : limitedOutput_directive
{
    notLimited = 0,
    limitedOutput = 1,
    fillOutput = 2
}


/*-************************************
*  Reading and writing into memory
**************************************/

/**
 * LZ4 relies on memcpy with a constant size being inlined. In freestanding
 * environments, the compiler can't assume the implementation of memcpy() is
 * standard compliant, so it can't apply its specialized memcpy() inlining
 * logic. When possible, use __builtin_memcpy() to tell the compiler to analyze
 * memcpy() as if it were standard compliant, so it can inline it in freestanding
 * environments. This is needed when decompressing the Linux Kernel, for example.
 */
alias LZ4_memcpy = memcpy;

bool LZ4_isLittleEndian()
{
    version(LittleEndian)
        return true;
    else
        return false;
}

// GP Note: we don't target exotic arch like original LZ4, so it's way easier here.

U16 LZ4_read16(const(void)* memPtr)       { return *cast(const(U16)*) memPtr; }
U32 LZ4_read32(const(void)* memPtr)       { return *cast(const(U32)*) memPtr; }
reg_t LZ4_read_ARCH(const(void)* memPtr)  { return *cast(const(reg_t)*) memPtr; }

void LZ4_write16(void* memPtr, U16 value) { *cast(U16*)memPtr = value; }
void LZ4_write32(void* memPtr, U32 value) { *cast(U32*)memPtr = value; }


U16 LZ4_readLE16(const(void)* memPtr)
{
    version(LittleEndian)
    {
        return LZ4_read16(memPtr);
    } else {
        const(BYTE)* p = cast(const(BYTE)*)memPtr;
        return cast(U16)(cast(U16)p[0] + (p[1]<<8));
    }
}

void LZ4_writeLE16(void* memPtr, U16 value)
{
    version(LittleEndian)
    {
        LZ4_write16(memPtr, value);
    } else {
        BYTE* p = cast(BYTE*)memPtr;
        p[0] = cast(BYTE) value;
        p[1] = cast(BYTE)(value>>8);
    }
}

/* customized variant of memcpy, which can overwrite up to 8 bytes beyond dstEnd */
void LZ4_wildCopy8(void* dstPtr, const(void)* srcPtr, void* dstEnd)
{
    BYTE* d = cast(BYTE*)dstPtr;
    const(BYTE)* s = cast(const(BYTE)*)srcPtr;
    BYTE* e = cast(BYTE*)dstEnd;

    do { LZ4_memcpy(d,s,8); d+=8; s+=8; } while (d<e);
}

static immutable uint[8] inc32table = [0, 1, 2,  1,  0,  4, 4, 4];
static immutable int[8]  dec64table = [0, 0, 0, -1, -4,  1, 2, 3];

enum LZ4_FAST_DEC_LOOP = 1;

static if (LZ4_FAST_DEC_LOOP)
{

void LZ4_memcpy_using_offset_base(BYTE* dstPtr, const(BYTE)* srcPtr, BYTE* dstEnd, const size_t offset)
{
    assert(srcPtr + offset == dstPtr);
    if (offset < 8) {
        LZ4_write32(dstPtr, 0);   /* silence an msan warning when offset==0 */
        dstPtr[0] = srcPtr[0];
        dstPtr[1] = srcPtr[1];
        dstPtr[2] = srcPtr[2];
        dstPtr[3] = srcPtr[3];
        srcPtr += inc32table[offset];
        LZ4_memcpy(dstPtr+4, srcPtr, 4);
        srcPtr -= dec64table[offset];
        dstPtr += 8;
    } else {
        LZ4_memcpy(dstPtr, srcPtr, 8);
        dstPtr += 8;
        srcPtr += 8;
    }

    LZ4_wildCopy8(dstPtr, srcPtr, dstEnd);
}

/* customized variant of memcpy, which can overwrite up to 32 bytes beyond dstEnd
 * this version copies two times 16 bytes (instead of one time 32 bytes)
 * because it must be compatible with offsets >= 16. */
void LZ4_wildCopy32(void* dstPtr, const(void)* srcPtr, void* dstEnd)
{
    BYTE* d = cast(BYTE*)dstPtr;
    const(BYTE)* s = cast(const(BYTE)*)srcPtr;
    BYTE* e = cast(BYTE*)dstEnd;

    do { LZ4_memcpy(d,s,16); LZ4_memcpy(d+16,s+16,16); d+=32; s+=32; } while (d<e);
}

/* LZ4_memcpy_using_offset()  presumes :
 * - dstEnd >= dstPtr + MINMATCH
 * - there is at least 8 bytes available to write after dstEnd */
void LZ4_memcpy_using_offset(BYTE* dstPtr, const(BYTE)* srcPtr, BYTE* dstEnd, const size_t offset)
{
    BYTE[8] v;

    assert(dstEnd >= dstPtr + MINMATCH);

    switch(offset) {
    case 1:
        MEM_INIT(v.ptr, *srcPtr, 8);
        break;
    case 2:
        LZ4_memcpy(v.ptr, srcPtr, 2);
        LZ4_memcpy(&v[2], srcPtr, 2);
        LZ4_memcpy(&v[4], v.ptr, 4);
        break;
    case 4:
        LZ4_memcpy(v.ptr, srcPtr, 4);
        LZ4_memcpy(&v[4], srcPtr, 4);
        break;
    default:
        LZ4_memcpy_using_offset_base(dstPtr, srcPtr, dstEnd, offset);
        return;
    }

    LZ4_memcpy(dstPtr, v.ptr, 8);
    dstPtr += 8;
    while (dstPtr < dstEnd) {
        LZ4_memcpy(dstPtr, v.ptr, 8);
        dstPtr += 8;
    }
}

}


/*-************************************
*  Common functions
**************************************/
uint LZ4_NbCommonBytes (reg_t val)
{
    assert(val != 0);
    return bsf(val) >> 3; 
}
unittest
{
    assert(LZ4_NbCommonBytes(4) == 0);
    assert(LZ4_NbCommonBytes(256) == 1);
    assert(LZ4_NbCommonBytes(65534) == 2);
    assert(LZ4_NbCommonBytes(0xffffff) == 2);
    assert(LZ4_NbCommonBytes(0x1000000) == 3);
}


enum size_t STEPSIZE = reg_t.sizeof;

uint LZ4_count(const(BYTE)* pIn, const(BYTE)* pMatch, const(BYTE)* pInLimit)
{
    const(BYTE)* pStart = pIn;

    if (likely(pIn < pInLimit-(STEPSIZE-1))) 
    {
        const reg_t diff = LZ4_read_ARCH(pMatch) ^ LZ4_read_ARCH(pIn);
        if (!diff) 
        {
            pIn+=STEPSIZE; pMatch+=STEPSIZE;
        } else 
        {
            return LZ4_NbCommonBytes(diff);
    }   }

    while (likely(pIn < pInLimit-(STEPSIZE-1))) 
    {
        const reg_t diff = LZ4_read_ARCH(pMatch) ^ LZ4_read_ARCH(pIn);
        if (!diff) { pIn+=STEPSIZE; pMatch+=STEPSIZE; continue; }
        pIn += LZ4_NbCommonBytes(diff);
        return cast(uint)(pIn - pStart);
    }

    if ((STEPSIZE==8) && (pIn<(pInLimit-3)) && (LZ4_read32(pMatch) == LZ4_read32(pIn))) { pIn+=4; pMatch+=4; }
    if ((pIn<(pInLimit-1)) && (LZ4_read16(pMatch) == LZ4_read16(pIn))) { pIn+=2; pMatch+=2; }
    if ((pIn<pInLimit) && (*pMatch == *pIn)) pIn++;
    return cast(uint)(pIn - pStart);
}


/*************************************
*  Local Constants
**************************************/
enum int LZ4_64Klimit = ((64*KB) + (MFLIMIT-1));
enum U32 LZ4_skipTrigger = 6;  /* Increase this value ==> compression run slower on incompressible data */


/*************************************
*  Local Structures and types
**************************************/
alias tableType_t = int;
enum : tableType_t
{ 
    clearedTable = 0, byPtr, byU32, byU16 
}

/**
 * This enum distinguishes several different modes of accessing previous
 * content in the stream.
 *
 * - noDict        : There is no preceding content.
 * - withPrefix64k : Table entries up to ctx.dictSize before the current blob
 *                   blob being compressed are valid and refer to the preceding
 *                   content (of length ctx.dictSize), which is available
 *                   contiguously preceding in memory the content currently
 *                   being compressed.
 * - usingExtDict  : Like withPrefix64k, but the preceding content is somewhere
 *                   else in memory, starting at ctx.dictionary with length
 *                   ctx.dictSize.
 * - usingDictCtx  : Everything concerning the preceding content is
 *                   in a separate context, pointed to by ctx.dictCtx.
 *                   ctx.dictionary, ctx.dictSize, and table entries
 *                   in the current context that refer to positions
 *                   preceding the beginning of the current compression are
 *                   ignored. Instead, ctx.dictCtx.dictionary and ctx.dictCtx
 *                   .dictSize describe the location and size of the preceding
 *                   content, and matches are found by looking in the ctx
 *                   .dictCtx.hashTable.
 */
alias dict_directive = int;
enum : dict_directive
{ 
    noDict = 0, 
    withPrefix64k, 
    usingExtDict, 
    usingDictCtx 
}

alias dictIssue_directive = int;
enum : dictIssue_directive
{ 
    noDictIssue = 0, 
    dictSmall 
}

// TODO: remove, this is deprecated in original.
int LZ4_compress(const char* src, char* dest, int srcSize)
{
    return LZ4_compress_default(src, dest, srcSize, LZ4_compressBound(srcSize));
}

/*************************************
*  Local Utils
**************************************/
int LZ4_versionNumber() 
{ 
    return LZ4_VERSION_NUMBER; 
}

const(char)* LZ4_versionString() 
{ 
    return LZ4_VERSION_STRING; 
}

/*! LZ4_compressBound() :
Provides the maximum size that LZ4 compression may output in a "worst case" scenario (input data not compressible)
This function is primarily useful for memory allocation purposes (destination buffer size).
Macro LZ4_COMPRESSBOUND() is also provided for compilation-time evaluation (stack memory allocation for example).
Note that LZ4_compress_default() compresses faster when dstCapacity is >= LZ4_compressBound(srcSize)
inputSize  : max supported value is LZ4_MAX_INPUT_SIZE
return : maximum output size in a "worst case" scenario
or 0, if input size is incorrect (too large or negative)
*/
int LZ4_compressBound(int isize)  
{
    assert( cast(uint)(isize) <= cast(uint)LZ4_MAX_INPUT_SIZE);
    return isize + (isize/255) + 16;
}

/*! LZ4_compress_fast_extState() :
*  Same as LZ4_compress_fast(), using an externally allocated memory space for its state.
*  Use LZ4_sizeofState() to know how much memory must be allocated,
*  and allocate it on 8-bytes boundaries (using `malloc()` typically).
*  Then, provide this buffer as `void* state` to compression function.
*/
int LZ4_sizeofState() 
{ 
    return LZ4_STREAMSIZE; 
}

/*-******************************
*  Compression functions
********************************/
U32 LZ4_hash4(U32 sequence, const tableType_t tableType)
{
    if (tableType == byU16)
        return ((sequence * 2654435761U) >> ((MINMATCH*8)-(LZ4_HASHLOG+1)));
    else
        return ((sequence * 2654435761U) >> ((MINMATCH*8)-LZ4_HASHLOG));
}

U32 LZ4_hash5(U64 sequence, const tableType_t tableType)
{
    const U32 hashLog = (tableType == byU16) ? LZ4_HASHLOG+1 : LZ4_HASHLOG;
    if (LZ4_isLittleEndian()) {
        const U64 prime5bytes = 889523592379UL;
        return cast(U32)(((sequence << 24) * prime5bytes) >> (64 - hashLog));
    } else {
        const U64 prime8bytes = 11400714785074694791UL;
        return cast(U32)(((sequence >> 24) * prime8bytes) >> (64 - hashLog));
    }
}

U32 LZ4_hashPosition(const(void)* p, const tableType_t tableType)
{
    if (((reg_t.sizeof)==8) && (tableType != byU16)) 
        return LZ4_hash5(LZ4_read_ARCH(p), tableType);
    return LZ4_hash4(LZ4_read32(p), tableType);
}

void LZ4_clearHash(U32 h, void* tableBase, tableType_t tableType)
{
    switch (tableType)
    {
    case clearedTable: { /* illegal! */ assert(0); }
    case byPtr: { const(BYTE)** hashTable = cast(const(BYTE)**)tableBase; hashTable[h] = null; return; }
    case byU32: { U32* hashTable = cast(U32*) tableBase; hashTable[h] = 0; return; }
    case byU16: { U16* hashTable = cast(U16*) tableBase; hashTable[h] = 0; return; }
    default: goto case clearedTable;
    }
}

void LZ4_putIndexOnHash(U32 idx, U32 h, void* tableBase, const tableType_t tableType)
{
    switch (tableType)
    {
    default:  /* fallthrough */
    case clearedTable: /* fallthrough */
    case byPtr: { /* illegal! */ assert(0); }
    case byU32: { U32* hashTable = cast(U32*) tableBase; hashTable[h] = idx; return; }
    case byU16: { U16* hashTable = cast(U16*) tableBase; assert(idx < 65536); hashTable[h] = cast(U16)idx; return; }
    }
}

void LZ4_putPositionOnHash(const(BYTE)* p, U32 h,
                           void* tableBase, const tableType_t tableType,
                           const(BYTE)* srcBase)
{
    switch (tableType)
    {
    default:
    case clearedTable: { /* illegal! */ assert(0); }
    case byPtr: { const(BYTE)** hashTable = cast(const(BYTE)**)tableBase; hashTable[h] = p; return; }
    case byU32: { U32* hashTable = cast(U32*) tableBase; hashTable[h] = cast(U32)(p-srcBase); return; }
    case byU16: { U16* hashTable = cast(U16*) tableBase; hashTable[h] = cast(U16)(p-srcBase); return; }
    }
}

void LZ4_putPosition(const BYTE* p, void* tableBase, tableType_t tableType, const BYTE* srcBase)
{
    const U32 h = LZ4_hashPosition(p, tableType);
    LZ4_putPositionOnHash(p, h, tableBase, tableType, srcBase);
}

/* LZ4_getIndexOnHash() :
 * Index of match position registered in hash table.
 * hash position must be calculated by using base+index, or dictBase+index.
 * Assumption 1 : only valid if tableType == byU32 or byU16.
 * Assumption 2 : h is presumed valid (within limits of hash table)
 */
U32 LZ4_getIndexOnHash(U32 h, const(void)* tableBase, tableType_t tableType)
{
    static assert(LZ4_MEMORY_USAGE > 2);
    if (tableType == byU32) {
        const(U32)* hashTable = cast(const(U32)*) tableBase;
        assert(h < (1U << (LZ4_MEMORY_USAGE-2)));
        return hashTable[h];
    }
    if (tableType == byU16) {
        const(U16)* hashTable = cast(const(U16)*) tableBase;
        assert(h < (1U << (LZ4_MEMORY_USAGE-1)));
        return hashTable[h];
    }
    assert(0);   /* forbidden case */
}

const(BYTE)* LZ4_getPositionOnHash(U32 h, const(void)* tableBase, tableType_t tableType, const(BYTE)* srcBase)
{
    if (tableType == byPtr) { const(BYTE*)* hashTable = cast(const(BYTE*)*) tableBase; return hashTable[h]; }
    if (tableType == byU32) { const(U32*) hashTable = cast(const U32*) tableBase; return hashTable[h] + srcBase; }
    { const(U16*) hashTable = cast(const U16*) tableBase; return hashTable[h] + srcBase; }   /* default, to ensure a return */
}

const(BYTE)* LZ4_getPosition(const(BYTE)* p, 
                             const(void)* tableBase, 
                             tableType_t tableType,
                             const(BYTE)* srcBase)
{
    const U32 h = LZ4_hashPosition(p, tableType);
    return LZ4_getPositionOnHash(h, tableBase, tableType, srcBase);
}

void LZ4_prepareTable(LZ4_stream_t_internal* cctx,
                      const int inputSize,
                      const tableType_t tableType) 
{
    /* If the table hasn't been used, it's guaranteed to be zeroed out, and is
     * therefore safe to use no matter what mode we're in. Otherwise, we figure
     * out if it's safe to leave as is or whether it needs to be reset.
     */
    if (cast(tableType_t)cctx.tableType != clearedTable) {
        assert(inputSize >= 0);
        if (cast(tableType_t)cctx.tableType != tableType
          || ((tableType == byU16) && cctx.currentOffset + cast(uint)inputSize >= 0xFFFFU)
          || ((tableType == byU32) && cctx.currentOffset > 1 * GB)
          || tableType == byPtr
          || inputSize >= 4*KB)
        {
            MEM_INIT(cctx.hashTable.ptr, 0, LZ4_HASHTABLESIZE);
            cctx.currentOffset = 0;
            cctx.tableType = cast(U32)clearedTable;
        } else {
        }
    }

    /* Adding a gap, so all previous entries are > LZ4_DISTANCE_MAX back,
     * is faster than compressing without a gap.
     * However, compressing with currentOffset == 0 is faster still,
     * so we preserve that case.
     */
    if (cctx.currentOffset != 0 && tableType == byU32) {
        cctx.currentOffset += 64*KB;
    }

    /* Finally, clear history */
    cctx.dictCtx = null;
    cctx.dictionary = null;
    cctx.dictSize = 0;
}

/** LZ4_compress_generic() :
 *  inlined, to ensure branches are decided at compilation time.
 *  Presumed already validated at this stage:
 *  - source != null
 *  - inputSize > 0
 */
 int LZ4_compress_generic_validated(
                 LZ4_stream_t_internal* cctx,
                 const(char*) source,
                 char* dest,
                 const int inputSize,
                 int*  inputConsumed, /* only written when outputDirective == fillOutput */
                 const int maxOutputSize,
                 const limitedOutput_directive outputDirective,
                 const tableType_t tableType,
                 const dict_directive dictDirective,
                 const dictIssue_directive dictIssue,
                 const int acceleration)
{
    int result;
    const(BYTE)* ip = cast(const(BYTE)*) source;

    const U32 startIndex = cctx.currentOffset;
    const(BYTE)* base = cast(const(BYTE)*) source - startIndex;
    const(BYTE)* lowLimit;

    const(LZ4_stream_t_internal)* dictCtx = cast(const(LZ4_stream_t_internal)*) cctx.dictCtx;
    const(BYTE*) dictionary =
        dictDirective == usingDictCtx ? dictCtx.dictionary : cctx.dictionary;
    const U32 dictSize =
        dictDirective == usingDictCtx ? dictCtx.dictSize : cctx.dictSize;
    const U32 dictDelta = (dictDirective == usingDictCtx) ? startIndex - dictCtx.currentOffset : 0;   /* make indexes in dictCtx comparable with index in current context */

    const int maybe_extMem = (dictDirective == usingExtDict) || (dictDirective == usingDictCtx);
    const U32 prefixIdxLimit = startIndex - dictSize;   /* used when dictDirective == dictSmall */
    const(BYTE*) dictEnd = dictionary ? dictionary + dictSize : dictionary;
    const(BYTE)* anchor = cast(const(BYTE)*) source;
    const(BYTE*) iend = ip + inputSize;
    const(BYTE*) mflimitPlusOne = iend - MFLIMIT + 1;
    const(BYTE*) matchlimit = iend - LASTLITERALS;

    /* the dictCtx currentOffset is indexed on the start of the dictionary,
     * while a dictionary in the current context precedes the currentOffset */
    const(BYTE)* dictBase = (dictionary == null) ? null :
                            (dictDirective == usingDictCtx) ?
                             dictionary + dictSize - dictCtx.currentOffset :
                             dictionary + dictSize - startIndex;

    BYTE* op = cast(BYTE*) dest;
    BYTE* olimit = op + maxOutputSize;

    U32 offset = 0;
    U32 forwardH;

    assert(ip != null);
    /* If init conditions are not met, we don't have to mark stream
     * as having dirty context, since no action was taken yet */
    if (outputDirective == fillOutput && maxOutputSize < 1) { return 0; } /* Impossible to store anything */
    if ((tableType == byU16) && (inputSize>=LZ4_64Klimit)) { return 0; }  /* Size too large (not within 64K limit) */
    if (tableType==byPtr) assert(dictDirective==noDict);      /* only supported use case with byPtr */
    assert(acceleration >= 1);

    lowLimit = cast(const(BYTE)*)source - (dictDirective == withPrefix64k ? dictSize : 0);

    /* Update context state */
    if (dictDirective == usingDictCtx) {
        /* Subsequent linked blocks can't use the dictionary. */
        /* Instead, they use the block we just compressed. */
        cctx.dictCtx = null;
        cctx.dictSize = cast(U32)inputSize;
    } else {
        cctx.dictSize += cast(U32)inputSize;
    }
    cctx.currentOffset += cast(U32)inputSize;
    cctx.tableType = cast(U32)tableType;

    if (inputSize<LZ4_minLength) goto _last_literals;        /* Input too small, no compression (all literals) */

    /* First Byte */
    LZ4_putPosition(ip, cctx.hashTable.ptr, tableType, base);
    ip++; forwardH = LZ4_hashPosition(ip, tableType);

    /* Main Loop */
    for ( ; ; ) {
        const(BYTE)* match;
        BYTE* token;
        const(BYTE)* filledIp;

        /* Find a match */
        if (tableType == byPtr) {
            const(BYTE)* forwardIp = ip;
            int step = 1;
            int searchMatchNb = acceleration << LZ4_skipTrigger;
            do {
                const U32 h = forwardH;
                ip = forwardIp;
                forwardIp += step;
                step = (searchMatchNb++ >> LZ4_skipTrigger);

                if (unlikely(forwardIp > mflimitPlusOne)) goto _last_literals;
                assert(ip < mflimitPlusOne);

                match = LZ4_getPositionOnHash(h, cctx.hashTable.ptr, tableType, base);
                forwardH = LZ4_hashPosition(forwardIp, tableType);
                LZ4_putPositionOnHash(ip, h, cctx.hashTable.ptr, tableType, base);

            } while ( (match+LZ4_DISTANCE_MAX < ip)
                   || (LZ4_read32(match) != LZ4_read32(ip)) );

        } else {   /* byU32, byU16 */

            const(BYTE)* forwardIp = ip;
            int step = 1;
            int searchMatchNb = acceleration << LZ4_skipTrigger;
            do {
                const U32 h = forwardH;
                const U32 current = cast(U32)(forwardIp - base);
                U32 matchIndex = LZ4_getIndexOnHash(h, cctx.hashTable.ptr, tableType);
                assert(matchIndex <= current);
                assert(forwardIp - base < cast(ptrdiff_t)(2 * GB - 1));
                ip = forwardIp;
                forwardIp += step;
                step = (searchMatchNb++ >> LZ4_skipTrigger);

                if (unlikely(forwardIp > mflimitPlusOne)) goto _last_literals;
                assert(ip < mflimitPlusOne);

                if (dictDirective == usingDictCtx) {
                    if (matchIndex < startIndex) {
                        /* there was no match, try the dictionary */
                        assert(tableType == byU32);
                        matchIndex = LZ4_getIndexOnHash(h, dictCtx.hashTable.ptr, byU32);
                        match = dictBase + matchIndex;
                        matchIndex += dictDelta;   /* make dictCtx index comparable with current context */
                        lowLimit = dictionary;
                    } else {
                        match = base + matchIndex;
                        lowLimit = cast(const(BYTE)*)source;
                    }
                } else if (dictDirective == usingExtDict) {
                    if (matchIndex < startIndex) {
                        assert(startIndex - matchIndex >= MINMATCH);
                        assert(dictBase);
                        match = dictBase + matchIndex;
                        lowLimit = dictionary;
                    } else {
                        match = base + matchIndex;
                        lowLimit = cast(const(BYTE)*)source;
                    }
                } else {   /* single continuous memory segment */
                    match = base + matchIndex;
                }
                forwardH = LZ4_hashPosition(forwardIp, tableType);
                LZ4_putIndexOnHash(current, h, cctx.hashTable.ptr, tableType);

                if ((dictIssue == dictSmall) && (matchIndex < prefixIdxLimit)) { continue; }    /* match outside of valid area */
                assert(matchIndex < current);
                if ( ((tableType != byU16) || (LZ4_DISTANCE_MAX < LZ4_DISTANCE_ABSOLUTE_MAX))
                  && (matchIndex+LZ4_DISTANCE_MAX < current)) {
                    continue;
                } /* too far */
                assert((current - matchIndex) <= LZ4_DISTANCE_MAX);  /* match now expected within distance */

                if (LZ4_read32(match) == LZ4_read32(ip)) {
                    if (maybe_extMem) offset = current - matchIndex;
                    break;   /* match found */
                }

            } while(1);
        }

        /* Catch up */
        filledIp = ip;
        while (((ip>anchor) & (match > lowLimit)) && (unlikely(ip[-1]==match[-1]))) { ip--; match--; }

        /* Encode Literals */
        {   uint litLength = cast(uint)(ip - anchor);
            token = op++;
            if ((outputDirective == limitedOutput) &&  /* Check output buffer overflow */
                (unlikely(op + litLength + (2 + 1 + LASTLITERALS) + (litLength/255) > olimit)) ) {
                return 0;   /* cannot compress within `dst` budget. Stored indexes in hash table are nonetheless fine */
            }
            if ((outputDirective == fillOutput) &&
                (unlikely(op + (litLength+240)/255 /* litlen */ + litLength /* literals */ + 2 /* offset */ + 1 /* token */ + MFLIMIT - MINMATCH /* min last literals so last match is <= end - MFLIMIT */ > olimit))) {
                op--;
                goto _last_literals;
            }
            if (litLength >= RUN_MASK) {
                int len = cast(int)(litLength - RUN_MASK);
                *token = (RUN_MASK<<ML_BITS);
                for(; len >= 255 ; len-=255) *op++ = 255;
                *op++ = cast(BYTE)len;
            }
            else *token = cast(BYTE)(litLength<<ML_BITS);

            /* Copy Literals */
            LZ4_wildCopy8(op, anchor, op+litLength);
            op+=litLength;
        }

_next_match:
        /* at this stage, the following variables must be correctly set :
         * - ip : at start of LZ operation
         * - match : at start of previous pattern occurrence; can be within current prefix, or within extDict
         * - offset : if maybe_ext_memSegment==1 (constant)
         * - lowLimit : must be == dictionary to mean "match is within extDict"; must be == source otherwise
         * - token and *token : position to write 4-bits for match length; higher 4-bits for literal length supposed already written
         */

        if ((outputDirective == fillOutput) &&
            (op + 2 /* offset */ + 1 /* token */ + MFLIMIT - MINMATCH /* min last literals so last match is <= end - MFLIMIT */ > olimit)) {
            /* the match was too close to the end, rewind and go to last literals */
            op = token;
            goto _last_literals;
        }

        /* Encode Offset */
        if (maybe_extMem) {   /* static test */
            assert(offset <= LZ4_DISTANCE_MAX && offset > 0);
            LZ4_writeLE16(op, cast(U16)offset); op+=2;
        } else  {
            assert(ip-match <= LZ4_DISTANCE_MAX);
            LZ4_writeLE16(op, cast(U16)(ip - match)); op+=2;
        }

        /* Encode MatchLength */
        {   uint matchCode;

            if ( (dictDirective==usingExtDict || dictDirective==usingDictCtx)
              && (lowLimit==dictionary) /* match within extDict */ ) {
                const(BYTE)* limit = ip + (dictEnd-match);
                assert(dictEnd > match);
                if (limit > matchlimit) limit = matchlimit;
                matchCode = LZ4_count(ip+MINMATCH, match+MINMATCH, limit);
                ip += cast(size_t)matchCode + MINMATCH;
                if (ip==limit) {
                    const uint more = LZ4_count(limit, cast(const(BYTE)*)source, matchlimit);
                    matchCode += more;
                    ip += more;
                }
            } else {
                matchCode = LZ4_count(ip+MINMATCH, match+MINMATCH, matchlimit);
                ip += cast(size_t)matchCode + MINMATCH;
            }

            if ((outputDirective) &&    /* Check output buffer overflow */
                (unlikely(op + (1 + LASTLITERALS) + (matchCode+240)/255 > olimit)) ) {
                if (outputDirective == fillOutput) {
                    /* Match description too long : reduce it */
                    U32 newMatchCode = 15 /* in token */ - 1 /* to avoid needing a zero byte */ + (cast(U32)(olimit - op) - 1 - LASTLITERALS) * 255;
                    ip -= matchCode - newMatchCode;
                    assert(newMatchCode < matchCode);
                    matchCode = newMatchCode;
                    if (unlikely(ip <= filledIp)) {
                        /* We have already filled up to filledIp so if ip ends up less than filledIp
                         * we have positions in the hash table beyond the current position. This is
                         * a problem if we reuse the hash table. So we have to remove these positions
                         * from the hash table.
                         */
                        const(BYTE)* ptr;
                        for (ptr = ip; ptr <= filledIp; ++ptr) {
                            const U32 h = LZ4_hashPosition(ptr, tableType);
                            LZ4_clearHash(h, cctx.hashTable.ptr, tableType);
                        }
                    }
                } else {
                    assert(outputDirective == limitedOutput);
                    return 0;   /* cannot compress within `dst` budget. Stored indexes in hash table are nonetheless fine */
                }
            }
            if (matchCode >= ML_MASK) {
                *token += ML_MASK;
                matchCode -= ML_MASK;
                LZ4_write32(op, 0xFFFFFFFF);
                while (matchCode >= 4*255) {
                    op+=4;
                    LZ4_write32(op, 0xFFFFFFFF);
                    matchCode -= 4*255;
                }
                op += matchCode / 255;
                *op++ = cast(BYTE)(matchCode % 255);
            } else
                *token +=cast(BYTE)(matchCode);
        }
        /* Ensure we have enough space for the last literals. */
        assert(!(outputDirective == fillOutput && op + 1 + LASTLITERALS > olimit));

        anchor = ip;

        /* Test end of chunk */
        if (ip >= mflimitPlusOne) break;

        /* Fill table */
        LZ4_putPosition(ip-2, cctx.hashTable.ptr, tableType, base);

        /* Test next position */
        if (tableType == byPtr) {

            match = LZ4_getPosition(ip, cctx.hashTable.ptr, tableType, base);
            LZ4_putPosition(ip, cctx.hashTable.ptr, tableType, base);
            if ( (match+LZ4_DISTANCE_MAX >= ip)
              && (LZ4_read32(match) == LZ4_read32(ip)) )
            { token=op++; *token=0; goto _next_match; }

        } else {   /* byU32, byU16 */

            const U32 h = LZ4_hashPosition(ip, tableType);
            const U32 current = cast(U32)(ip-base);
            U32 matchIndex = LZ4_getIndexOnHash(h, cctx.hashTable.ptr, tableType);
            assert(matchIndex < current);
            if (dictDirective == usingDictCtx) {
                if (matchIndex < startIndex) {
                    /* there was no match, try the dictionary */
                    matchIndex = LZ4_getIndexOnHash(h, dictCtx.hashTable.ptr, byU32);
                    match = dictBase + matchIndex;
                    lowLimit = dictionary;   /* required for match length counter */
                    matchIndex += dictDelta;
                } else {
                    match = base + matchIndex;
                    lowLimit = cast(const(BYTE)*)source;  /* required for match length counter */
                }
            } else if (dictDirective==usingExtDict) {
                if (matchIndex < startIndex) {
                    assert(dictBase);
                    match = dictBase + matchIndex;
                    lowLimit = dictionary;   /* required for match length counter */
                } else {
                    match = base + matchIndex;
                    lowLimit = cast(const(BYTE)*)source;   /* required for match length counter */
                }
            } else {   /* single memory segment */
                match = base + matchIndex;
            }
            LZ4_putIndexOnHash(current, h, cctx.hashTable.ptr, tableType);
            assert(matchIndex < current);
            if ( ((dictIssue==dictSmall) ? (matchIndex >= prefixIdxLimit) : 1)
              && (((tableType==byU16) && (LZ4_DISTANCE_MAX == LZ4_DISTANCE_ABSOLUTE_MAX)) ? 1 : (matchIndex+LZ4_DISTANCE_MAX >= current))
              && (LZ4_read32(match) == LZ4_read32(ip)) ) {
                token=op++;
                *token=0;
                if (maybe_extMem) offset = current - matchIndex;
                goto _next_match;
            }
        }

        /* Prepare next loop */
        forwardH = LZ4_hashPosition(++ip, tableType);

    }

_last_literals:
    /* Encode Last Literals */
    {   size_t lastRun = cast(size_t)(iend - anchor);
        if ( (outputDirective) &&  /* Check output buffer overflow */
            (op + lastRun + 1 + ((lastRun+255-RUN_MASK)/255) > olimit)) {
            if (outputDirective == fillOutput) {
                /* adapt lastRun to fill 'dst' */
                assert(olimit >= op);
                lastRun  = cast(size_t)(olimit-op) - 1/*token*/;
                lastRun -= (lastRun + 256 - RUN_MASK) / 256;  /*additional length tokens*/
            } else {
                assert(outputDirective == limitedOutput);
                return 0;   /* cannot compress within `dst` budget. Stored indexes in hash table are nonetheless fine */
            }
        }
        if (lastRun >= RUN_MASK) {
            size_t accumulator = lastRun - RUN_MASK;
            *op++ = RUN_MASK << ML_BITS;
            for(; accumulator >= 255 ; accumulator-=255) *op++ = 255;
            *op++ = cast(BYTE) accumulator;
        } else {
            *op++ = cast(BYTE)(lastRun<<ML_BITS);
        }
        LZ4_memcpy(op, anchor, lastRun);
        ip = anchor + lastRun;
        op += lastRun;
    }

    if (outputDirective == fillOutput) {
        *inputConsumed = cast(int) ((cast(const(char)*)ip)-source);
    }
    result = cast(int)((cast(char*)op) - dest);
    assert(result > 0);
    return result;
}

/** LZ4_compress_generic() :
 *  inlined, to ensure branches are decided at compilation time;
 *  takes care of src == (null, 0)
 *  and forward the rest to LZ4_compress_generic_validated */
public int LZ4_compress_generic(
                 LZ4_stream_t_internal* cctx,
                 const(char*) src,
                 char* dst,
                 const int srcSize,
                 int *inputConsumed, /* only written when outputDirective == fillOutput */
                 const int dstCapacity,
                 const limitedOutput_directive outputDirective,
                 const tableType_t tableType,
                 const dict_directive dictDirective,
                 const dictIssue_directive dictIssue,
                 const int acceleration)
{
    if (cast(U32)srcSize > cast(U32)LZ4_MAX_INPUT_SIZE) { return 0; }  /* Unsupported srcSize, too large (or negative) */
    if (srcSize == 0) {   /* src == null supported if srcSize == 0 */
        if (outputDirective != notLimited && dstCapacity <= 0) return 0;  /* no output, can't write anything */
        assert(outputDirective == notLimited || dstCapacity >= 1);
        assert(dst != null);
        dst[0] = 0;
        if (outputDirective == fillOutput) {
            assert (inputConsumed != null);
            *inputConsumed = 0;
        }
        return 1;
    }
    assert(src != null);

    return LZ4_compress_generic_validated(cctx, src, dst, srcSize,
                inputConsumed, /* only written into if outputDirective == fillOutput */
                dstCapacity, outputDirective,
                tableType, dictDirective, dictIssue, acceleration);
}

/*! LZ4_compress_fast_extState() :
*  Same as LZ4_compress_fast(), using an externally allocated memory space for its state.
*  Use LZ4_sizeofState() to know how much memory must be allocated,
*  and allocate it on 8-bytes boundaries (using `malloc()` typically).
*  Then, provide this buffer as `void* state` to compression function.
*/
public int LZ4_compress_fast_extState(void* state, const(char)* source, char* dest, int inputSize, int maxOutputSize, int acceleration)
{
    LZ4_stream_t_internal* ctx = & LZ4_initStream(state, (LZ4_stream_t).sizeof) . internal_donotuse;
    assert(ctx != null);
    if (acceleration < 1) acceleration = LZ4_ACCELERATION_DEFAULT;
    if (acceleration > LZ4_ACCELERATION_MAX) acceleration = LZ4_ACCELERATION_MAX;
    if (maxOutputSize >= LZ4_compressBound(inputSize)) {
        if (inputSize < LZ4_64Klimit) {
            return LZ4_compress_generic(ctx, source, dest, inputSize, null, 0, notLimited, byU16, noDict, noDictIssue, acceleration);
        } else {
            const tableType_t tableType = (((void*).sizeof==4) && (cast(uptrval)source > LZ4_DISTANCE_MAX)) ? byPtr : byU32;
            return LZ4_compress_generic(ctx, source, dest, inputSize, null, 0, notLimited, tableType, noDict, noDictIssue, acceleration);
        }
    } else {
        if (inputSize < LZ4_64Klimit) {
            return LZ4_compress_generic(ctx, source, dest, inputSize, null, maxOutputSize, limitedOutput, byU16, noDict, noDictIssue, acceleration);
        } else {
            const tableType_t tableType = (((void*).sizeof==4) && (cast(uptrval)source > LZ4_DISTANCE_MAX)) ? byPtr : byU32;
            return LZ4_compress_generic(ctx, source, dest, inputSize, null, maxOutputSize, limitedOutput, tableType, noDict, noDictIssue, acceleration);
        }
    }
}

/**
 * LZ4_compress_fast_extState_fastReset() :
 * A variant of LZ4_compress_fast_extState().
 *
 * Using this variant avoids an expensive initialization step. It is only safe
 * to call if the state buffer is known to be correctly initialized already
 * (see comment in lz4.h on LZ4_resetStream_fast() for a definition of
 * "correctly initialized").
 */
public int LZ4_compress_fast_extState_fastReset(void* state, const char* src, char* dst, int srcSize, int dstCapacity, int acceleration)
{
    LZ4_stream_t_internal* ctx = &(cast(LZ4_stream_t*)state).internal_donotuse;
    if (acceleration < 1) acceleration = LZ4_ACCELERATION_DEFAULT;
    if (acceleration > LZ4_ACCELERATION_MAX) acceleration = LZ4_ACCELERATION_MAX;

    if (dstCapacity >= LZ4_compressBound(srcSize)) {
        if (srcSize < LZ4_64Klimit) {
            const tableType_t tableType = byU16;
            LZ4_prepareTable(ctx, srcSize, tableType);
            if (ctx.currentOffset) {
                return LZ4_compress_generic(ctx, src, dst, srcSize, null, 0, notLimited, tableType, noDict, dictSmall, acceleration);
            } else {
                return LZ4_compress_generic(ctx, src, dst, srcSize, null, 0, notLimited, tableType, noDict, noDictIssue, acceleration);
            }
        } else {
            const tableType_t tableType = (((void*).sizeof == 4) && (cast(uptrval)src > LZ4_DISTANCE_MAX)) ? byPtr : byU32;
            LZ4_prepareTable(ctx, srcSize, tableType);
            return LZ4_compress_generic(ctx, src, dst, srcSize, null, 0, notLimited, tableType, noDict, noDictIssue, acceleration);
        }
    } else {
        if (srcSize < LZ4_64Klimit) {
            const tableType_t tableType = byU16;
            LZ4_prepareTable(ctx, srcSize, tableType);
            if (ctx.currentOffset) {
                return LZ4_compress_generic(ctx, src, dst, srcSize, null, dstCapacity, limitedOutput, tableType, noDict, dictSmall, acceleration);
            } else {
                return LZ4_compress_generic(ctx, src, dst, srcSize, null, dstCapacity, limitedOutput, tableType, noDict, noDictIssue, acceleration);
            }
        } else {
            const tableType_t tableType = (((void*).sizeof==4) && (cast(uptrval)src > LZ4_DISTANCE_MAX)) ? byPtr : byU32;
            LZ4_prepareTable(ctx, srcSize, tableType);
            return LZ4_compress_generic(ctx, src, dst, srcSize, null, dstCapacity, limitedOutput, tableType, noDict, noDictIssue, acceleration);
        }
    }
}

/*! LZ4_compress_fast() :
Same as LZ4_compress_default(), but allows selection of "acceleration" factor.
The larger the acceleration value, the faster the algorithm, but also the lesser the compression.
It's a trade-off. It can be fine tuned, with each successive value providing roughly +~3% to speed.
An acceleration value of "1" is the same as regular LZ4_compress_default()
Values <= 0 will be replaced by LZ4_ACCELERATION_DEFAULT (currently == 1, see lz4.c).
Values > LZ4_ACCELERATION_MAX will be replaced by LZ4_ACCELERATION_MAX (currently == 65537, see lz4.c).
*/
public int LZ4_compress_fast(const(char)* source, char* dest, int inputSize, int maxOutputSize, int acceleration)
{
    int result;
    static if (LZ4_HEAPMODE)
    {
        LZ4_stream_t* ctxPtr = cast(LZ4_stream_t*)ALLOC(LZ4_stream_t.sizeof);   /* malloc-calloc always properly aligned */
        if (ctxPtr == null) return 0;
    }
    else
    {
        LZ4_stream_t ctx;
        LZ4_stream_t* ctxPtr = &ctx;
    }
    result = LZ4_compress_fast_extState(ctxPtr, source, dest, inputSize, maxOutputSize, acceleration);

    static if (LZ4_HEAPMODE)
    {
        FREEMEM(ctxPtr);
    }
    return result;
}

/*! LZ4_compress_default() :
*  Compresses 'srcSize' bytes from buffer 'src'
*  into already allocated 'dst' buffer of size 'dstCapacity'.
*  Compression is guaranteed to succeed if 'dstCapacity' >= LZ4_compressBound(srcSize).
*  It also runs faster, so it's a recommended setting.
*  If the function cannot compress 'src' into a more limited 'dst' budget,
*  compression stops *immediately*, and the function result is zero.
*  In which case, 'dst' content is undefined (invalid).
*      srcSize : max supported value is LZ4_MAX_INPUT_SIZE.
*      dstCapacity : size of buffer 'dst' (which must be already allocated)
*     @return  : the number of bytes written into buffer 'dst' (necessarily <= dstCapacity)
*                or 0 if compression fails
* Note : This function is protected against buffer overflow scenarios (never writes outside 'dst' buffer, nor read outside 'source' buffer).
*/
int LZ4_compress_default(const char* src, char* dst, int srcSize, int maxOutputSize)
{
    return LZ4_compress_fast(src, dst, srcSize, maxOutputSize, 1);
}


/* Note!: This function leaves the stream in an unclean/broken state!
 * It is not safe to subsequently use the same state with a _fastReset() or
 * _continue() call without resetting it. */
static int LZ4_compress_destSize_extState (LZ4_stream_t* state, const char* src, char* dst, int* srcSizePtr, int targetDstSize)
{
    void* s = LZ4_initStream(state, (*state).sizeof);
    assert(s != null); 
    cast(void)s;

    if (targetDstSize >= LZ4_compressBound(*srcSizePtr)) {  /* compression success is guaranteed */
        return LZ4_compress_fast_extState(state, src, dst, *srcSizePtr, targetDstSize, 1);
    } else {
        if (*srcSizePtr < LZ4_64Klimit) {
            return LZ4_compress_generic(&state.internal_donotuse, src, dst, *srcSizePtr, srcSizePtr, targetDstSize, fillOutput, byU16, noDict, noDictIssue, 1);
        } else {
            tableType_t addrMode = (((void*).sizeof==4) && (cast(uptrval)src > LZ4_DISTANCE_MAX)) ? byPtr : byU32;
            return LZ4_compress_generic(&state.internal_donotuse, src, dst, *srcSizePtr, srcSizePtr, targetDstSize, fillOutput, addrMode, noDict, noDictIssue, 1);
    }   }
}

/*! LZ4_compress_destSize() :
*  Reverse the logic : compresses as much data as possible from 'src' buffer
*  into already allocated buffer 'dst', of size >= 'targetDestSize'.
*  This function either compresses the entire 'src' content into 'dst' if it's large enough,
*  or fill 'dst' buffer completely with as much data as possible from 'src'.
*  note: acceleration parameter is fixed to "default".
*
* *srcSizePtr : will be modified to indicate how many bytes where read from 'src' to fill 'dst'.
*               New value is necessarily <= input value.
* @return : Nb bytes written into 'dst' (necessarily <= targetDestSize)
*           or 0 if compression fails.
*
* Note : from v1.8.2 to v1.9.1, this function had a bug (fixed un v1.9.2+):
*        the produced compressed content could, in specific circumstances,
*        require to be decompressed into a destination buffer larger
*        by at least 1 byte than the content to decompress.
*        If an application uses `LZ4_compress_destSize()`,
*        it's highly recommended to update liblz4 to v1.9.2 or better.
*        If this can't be done or ensured,
*        the receiving decompression function should provide
*        a dstCapacity which is > decompressedSize, by at least 1 byte.
*        See https://github.com/lz4/lz4/issues/859 for details
*/
public int LZ4_compress_destSize(const char* src, char* dst, int* srcSizePtr, int targetDstSize)
{
    static if (LZ4_HEAPMODE)
    {
        LZ4_stream_t* ctx = cast(LZ4_stream_t*)ALLOC(LZ4_stream_t.sizeof);   /* malloc-calloc always properly aligned */
        if (ctx == null) return 0;
    }
    else
    {
        LZ4_stream_t ctxBody;
        LZ4_stream_t* ctx = &ctxBody;
    }

    int result = LZ4_compress_destSize_extState(ctx, src, dst, srcSizePtr, targetDstSize);

    static if (LZ4_HEAPMODE)
        FREEMEM(ctx);

    return result;
}



/*-******************************
*  Streaming functions
********************************/

public LZ4_stream_t* LZ4_createStream()
{
    LZ4_stream_t* lz4s = cast(LZ4_stream_t*) ALLOC(LZ4_stream_t.sizeof);
    static assert(LZ4_STREAMSIZE >= LZ4_stream_t_internal.sizeof);    /* A compilation error here means LZ4_STREAMSIZE is not large enough */
    if (lz4s == null) return null;
    LZ4_initStream(lz4s, (*lz4s).sizeof);
    return lz4s;
}

public size_t LZ4_stream_t_alignment()
{
    static if (LZ4_ALIGN_TEST)
    {
        static struct align_t
        {
            char c;
            LZ4_stream_t t;
        }
        align_t t_a;
        return (t_a).sizeof - (LZ4_stream_t).sizeof;
    }
    else
    {
        return 1;  /* effectively disabled */
    }
}

/*! LZ4_initStream() : v1.9.0+
*  An LZ4_stream_t structure must be initialized at least once.
*  This is automatically done when invoking LZ4_createStream(),
*  but it's not when the structure is simply declared on stack (for example).
*
*  Use LZ4_initStream() to properly initialize a newly declared LZ4_stream_t.
*  It can also initialize any arbitrary buffer of sufficient size,
*  and will @return a pointer of proper type upon initialization.
*
*  Note : initialization fails if size and alignment conditions are not respected.
*         In which case, the function will @return null.
*  Note2: An LZ4_stream_t structure guarantees correct alignment and size.
*  Note3: Before v1.9.0, use LZ4_resetStream() instead
*/
public LZ4_stream_t* LZ4_initStream (void* buffer, size_t size)
{
    if (buffer == null) { return null; }
    if (size < (LZ4_stream_t.sizeof)) { return null; }
    if (!LZ4_isAligned(buffer, LZ4_stream_t_alignment())) return null;
    MEM_INIT(buffer, 0, (LZ4_stream_t_internal.sizeof));
    return cast(LZ4_stream_t*)buffer;
}

/* resetStream is now deprecated,
 * prefer initStream() which is more general */
public void LZ4_resetStream (LZ4_stream_t* LZ4_stream)
{
    MEM_INIT(LZ4_stream, 0, (LZ4_stream_t_internal.sizeof));
}

public void LZ4_resetStream_fast(LZ4_stream_t* ctx) {
    LZ4_prepareTable(&(ctx.internal_donotuse), 0, byU32);
}

public int LZ4_freeStream (LZ4_stream_t* LZ4_stream)
{
    if (!LZ4_stream) return 0;   /* support free on null */
    FREEMEM(LZ4_stream);
    return (0);
}


enum size_t HASH_UNIT = (reg_t).sizeof;

/*! LZ4_loadDict() :
*  Use this function to reference a static dictionary into LZ4_stream_t.
*  The dictionary must remain available during compression.
*  LZ4_loadDict() triggers a reset, so any previous data will be forgotten.
*  The same dictionary will have to be loaded on decompression side for successful decoding.
*  Dictionary are useful for better compression of small data (KB range).
*  While LZ4 accept any input as dictionary,
*  results are generally better when using Zstandard's Dictionary Builder.
*  Loading a size of 0 is allowed, and is the same as reset.
* @return : loaded dictionary size, in bytes (necessarily <= 64 KB)
*/
int LZ4_loadDict (LZ4_stream_t* LZ4_dict, const char* dictionary, int dictSize)
{
    LZ4_stream_t_internal* dict = &LZ4_dict.internal_donotuse;
    const tableType_t tableType = byU32;
    const(BYTE)* p = cast(const(BYTE)*)dictionary;
    const(BYTE*) dictEnd = p + dictSize;
    const(BYTE)* base;

    /* It's necessary to reset the context,
     * and not just continue it with prepareTable()
     * to avoid any risk of generating overflowing matchIndex
     * when compressing using this dictionary */
    LZ4_resetStream(LZ4_dict);

    /* We always increment the offset by 64 KB, since, if the dict is longer,
     * we truncate it to the last 64k, and if it's shorter, we still want to
     * advance by a whole window length so we can provide the guarantee that
     * there are only valid offsets in the window, which allows an optimization
     * in LZ4_compress_fast_continue() where it uses noDictIssue even when the
     * dictionary isn't a full 64k. */
    dict.currentOffset += 64*KB;

    if (dictSize < cast(int)HASH_UNIT) {
        return 0;
    }

    if ((dictEnd - p) > 64*KB) p = dictEnd - 64*KB;
    base = dictEnd - dict.currentOffset;
    dict.dictionary = p;
    dict.dictSize = cast(U32)(dictEnd - p);
    dict.tableType = cast(U32)tableType;

    while (p <= dictEnd-HASH_UNIT) {
        LZ4_putPosition(p, dict.hashTable.ptr, tableType, base);
        p+=3;
    }

    return cast(int)dict.dictSize;
}

void LZ4_attach_dictionary(LZ4_stream_t* workingStream, const LZ4_stream_t* dictionaryStream)
{
    const(LZ4_stream_t_internal)* dictCtx = (dictionaryStream == null) ? null :
        &(dictionaryStream.internal_donotuse);

    if (dictCtx != null) {
        /* If the current offset is zero, we will never look in the
         * external dictionary context, since there is no value a table
         * entry can take that indicate a miss. In that case, we need
         * to bump the offset to something non-zero.
         */
        if (workingStream.internal_donotuse.currentOffset == 0) {
            workingStream.internal_donotuse.currentOffset = 64*KB;
        }

        /* Don't actually attach an empty dictionary.
         */
        if (dictCtx.dictSize == 0) {
            dictCtx = null;
        }
    }
    workingStream.internal_donotuse.dictCtx = dictCtx;
}


static void LZ4_renormDictT(LZ4_stream_t_internal* LZ4_dict, int nextSize)
{
    assert(nextSize >= 0);
    if (LZ4_dict.currentOffset + cast(uint)nextSize > 0x80000000) {   /* potential ptrdiff_t overflow (32-bits mode) */
        /* rescale hash table */
        U32 delta = LZ4_dict.currentOffset - 64*KB;
        const(BYTE)* dictEnd = LZ4_dict.dictionary + LZ4_dict.dictSize;
        int i;
        for (i=0; i<LZ4_HASH_SIZE_U32; i++) {
            if (LZ4_dict.hashTable[i] < delta) LZ4_dict.hashTable[i]=0;
            else LZ4_dict.hashTable[i] -= delta;
        }
        LZ4_dict.currentOffset = 64*KB;
        if (LZ4_dict.dictSize > 64*KB) LZ4_dict.dictSize = 64*KB;
        LZ4_dict.dictionary = dictEnd - LZ4_dict.dictSize;
    }
}

/*! LZ4_compress_fast_continue() :
*  Compress 'src' content using data from previously compressed blocks, for better compression ratio.
* 'dst' buffer must be already allocated.
*  If dstCapacity >= LZ4_compressBound(srcSize), compression is guaranteed to succeed, and runs faster.
*
* @return : size of compressed block
*           or 0 if there is an error (typically, cannot fit into 'dst').
*
*  Note 1 : Each invocation to LZ4_compress_fast_continue() generates a new block.
*           Each block has precise boundaries.
*           Each block must be decompressed separately, calling LZ4_decompress_*() with relevant metadata.
*           It's not possible to append blocks together and expect a single invocation of LZ4_decompress_*() to decompress them together.
*
*  Note 2 : The previous 64KB of source data is __assumed__ to remain present, unmodified, at same address in memory !
*
*  Note 3 : When input is structured as a double-buffer, each buffer can have any size, including < 64 KB.
*           Make sure that buffers are separated, by at least one byte.
*           This construction ensures that each block only depends on previous block.
*
*  Note 4 : If input buffer is a ring-buffer, it can have any size, including < 64 KB.
*
*  Note 5 : After an error, the stream status is undefined (invalid), it can only be reset or freed.
*/
int LZ4_compress_fast_continue (LZ4_stream_t* LZ4_stream,
                                const(char)* source, char* dest,
                                int inputSize, int maxOutputSize,
                                int acceleration)
{
    const tableType_t tableType = byU32;
    LZ4_stream_t_internal* streamPtr = &LZ4_stream.internal_donotuse;
    const(char)* dictEnd = streamPtr.dictSize ? cast(const(char)*)streamPtr.dictionary + streamPtr.dictSize : null;

    LZ4_renormDictT(streamPtr, inputSize);   /* fix index overflow */
    if (acceleration < 1) acceleration = LZ4_ACCELERATION_DEFAULT;
    if (acceleration > LZ4_ACCELERATION_MAX) acceleration = LZ4_ACCELERATION_MAX;

    /* invalidate tiny dictionaries */
    if ( (streamPtr.dictSize < 4)     /* tiny dictionary : not enough for a hash */
      && (dictEnd != source)           /* prefix mode */
      && (inputSize > 0)               /* tolerance : don't lose history, in case next invocation would use prefix mode */
      && (streamPtr.dictCtx == null)  /* usingDictCtx */
      ) {
        /* remove dictionary existence from history, to employ faster prefix mode */
        streamPtr.dictSize = 0;
        streamPtr.dictionary = cast(const(BYTE)*)source;
        dictEnd = source;
    }

    /* Check overlapping input/dictionary space */
    {   const(char*) sourceEnd = source + inputSize;
        if ((sourceEnd > cast(const char*)streamPtr.dictionary) && (sourceEnd < dictEnd)) {
            streamPtr.dictSize = cast(U32)(dictEnd - sourceEnd);
            if (streamPtr.dictSize > 64 * KB) streamPtr.dictSize = 64 * KB;
            if (streamPtr.dictSize < 4) streamPtr.dictSize = 0;
            streamPtr.dictionary = cast(const(BYTE)*)dictEnd - streamPtr.dictSize;
        }
    }

    /* prefix mode : source data follows dictionary */
    if (dictEnd == source) {
        if ((streamPtr.dictSize < 64 * KB) && (streamPtr.dictSize < streamPtr.currentOffset))
            return LZ4_compress_generic(streamPtr, source, dest, inputSize, null, maxOutputSize, limitedOutput, tableType, withPrefix64k, dictSmall, acceleration);
        else
            return LZ4_compress_generic(streamPtr, source, dest, inputSize, null, maxOutputSize, limitedOutput, tableType, withPrefix64k, noDictIssue, acceleration);
    }

    /* external dictionary mode */
    {   int result;
        if (streamPtr.dictCtx) {
            /* We depend here on the fact that dictCtx'es (produced by
             * LZ4_loadDict) guarantee that their tables contain no references
             * to offsets between dictCtx.currentOffset - 64 KB and
             * dictCtx.currentOffset - dictCtx.dictSize. This makes it safe
             * to use noDictIssue even when the dict isn't a full 64 KB.
             */
            if (inputSize > 4 * KB) {
                /* For compressing large blobs, it is faster to pay the setup
                 * cost to copy the dictionary's tables into the active context,
                 * so that the compression loop is only looking into one table.
                 */
                LZ4_memcpy(streamPtr, streamPtr.dictCtx, (*streamPtr).sizeof);
                result = LZ4_compress_generic(streamPtr, source, dest, inputSize, null, maxOutputSize, limitedOutput, tableType, usingExtDict, noDictIssue, acceleration);
            } else {
                result = LZ4_compress_generic(streamPtr, source, dest, inputSize, null, maxOutputSize, limitedOutput, tableType, usingDictCtx, noDictIssue, acceleration);
            }
        } else {  /* small data <= 4 KB */
            if ((streamPtr.dictSize < 64 * KB) && (streamPtr.dictSize < streamPtr.currentOffset)) {
                result = LZ4_compress_generic(streamPtr, source, dest, inputSize, null, maxOutputSize, limitedOutput, tableType, usingExtDict, dictSmall, acceleration);
            } else {
                result = LZ4_compress_generic(streamPtr, source, dest, inputSize, null, maxOutputSize, limitedOutput, tableType, usingExtDict, noDictIssue, acceleration);
            }
        }
        streamPtr.dictionary = cast(const(BYTE)*)source;
        streamPtr.dictSize = cast(U32)inputSize;
        return result;
    }
}


/* Hidden debug function, to force-test external dictionary mode */
int LZ4_compress_forceExtDict (LZ4_stream_t* LZ4_dict, const(char)* source, char* dest, int srcSize)
{
    LZ4_stream_t_internal* streamPtr = &LZ4_dict.internal_donotuse;
    int result;

    LZ4_renormDictT(streamPtr, srcSize);

    if ((streamPtr.dictSize < 64 * KB) && (streamPtr.dictSize < streamPtr.currentOffset)) {
        result = LZ4_compress_generic(streamPtr, source, dest, srcSize, null, 0, notLimited, byU32, usingExtDict, dictSmall, 1);
    } else {
        result = LZ4_compress_generic(streamPtr, source, dest, srcSize, null, 0, notLimited, byU32, usingExtDict, noDictIssue, 1);
    }

    streamPtr.dictionary = cast(const BYTE*)source;
    streamPtr.dictSize = cast(U32)srcSize;

    return result;
}


/*! LZ4_saveDict() :
 *  If previously compressed data block is not guaranteed to remain available at its memory location,
 *  save it into a safer place (char* safeBuffer).
 *  Note : no need to call LZ4_loadDict() afterwards, dictionary is immediately usable,
 *         one can therefore call LZ4_compress_fast_continue() right after.
 * @return : saved dictionary size in bytes (necessarily <= dictSize), or 0 if error.
 */
int LZ4_saveDict (LZ4_stream_t* LZ4_dict, char* safeBuffer, int dictSize)
{
    LZ4_stream_t_internal* dict = &LZ4_dict.internal_donotuse;

    if (cast(U32)dictSize > 64 * KB) { dictSize = 64 * KB; } /* useless to define a dictionary > 64 KB */
    if (cast(U32)dictSize > dict.dictSize) { dictSize = cast(int)dict.dictSize; }

    if (safeBuffer == null) assert(dictSize == 0);
    if (dictSize > 0) {
        const(BYTE*) previousDictEnd = dict.dictionary + dict.dictSize;
        assert(dict.dictionary);
        memmove(safeBuffer, previousDictEnd - dictSize, dictSize);
    }

    dict.dictionary = cast(const BYTE*)safeBuffer;
    dict.dictSize = cast(U32)dictSize;

    return dictSize;
}



/*-*******************************
 *  Decompression functions
 ********************************/

alias endCondition_directive = int;
enum : endCondition_directive
{ 
    endOnOutputSize = 0, 
    endOnInputSize = 1 
}

alias earlyEnd_directive = int;
enum : earlyEnd_directive
{ 
    decode_full_block = 0, 
    partial_decode = 1 
}

int MIN(int a, int b)
{
    return ( (a) < (b) ? (a) : (b) );
}

size_t MIN(size_t a, size_t b)
{
    return ( (a) < (b) ? (a) : (b) );
}


/* Read the variable-length literal or match length.
 *
 * ip - pointer to use as input.
 * lencheck - end ip.  Return an error if ip advances >= lencheck.
 * loop_check - check ip >= lencheck in body of loop.  Returns loop_error if so.
 * initial_check - check ip >= lencheck before start of loop.  Returns initial_error if so.
 * error (output) - error code.  Should be set to 0 before call.
 */
alias variable_length_error = int;
enum : variable_length_error
{
    loop_error = -2, 
    initial_error = -1, 
    ok = 0 
}

uint read_variable_length(const(BYTE)**ip, const BYTE* lencheck,
                          int loop_check, int initial_check,
                          variable_length_error* error)
{
    U32 length = 0;
    U32 s;
    if (initial_check && unlikely((*ip) >= lencheck)) {    /* overflow detection */
        *error = initial_error;
        return length;
    }
    do {
        s = **ip;
        (*ip)++;
        length += s;
        if (loop_check && unlikely((*ip) >= lencheck)) {    /* overflow detection */
            *error = loop_error;
            return length;
        }
    } while (s==255);

    return length;
}

/*! LZ4_decompress_generic() :
 *  This generic decompression function covers all use cases.
 *  It shall be instantiated several times, using different sets of directives.
 *  Note that it is important for performance that this function really get inlined,
 *  in order to remove useless branches during compilation optimization.
 */
int LZ4_decompress_generic(
                 const(char*) src,
                 char* dst,
                 int srcSize,
                 int outputSize,         /* If endOnInput==endOnInputSize, this value is `dstCapacity` */

                 endCondition_directive endOnInput,   /* endOnOutputSize, endOnInputSize */
                 earlyEnd_directive partialDecoding,  /* full, partial */
                 dict_directive dict,                 /* noDict, withPrefix64k, usingExtDict */
                 const(BYTE*) lowPrefix,  /* always <= dst, == dst when no prefix */
                 const(BYTE*) dictStart,  /* only if dict==usingExtDict */
                 const size_t dictSize         /* note : = 0 if noDict */
                 )
{
    if ((src == null) || (outputSize < 0)) { return -1; }

    {   const(BYTE)* ip = cast(const(BYTE)*) src;
        const(BYTE*) iend = ip + srcSize;

        BYTE* op = cast(BYTE*) dst;
        BYTE* oend = op + outputSize;
        BYTE* cpy;

        const(BYTE*) dictEnd = (dictStart == null) ? null : dictStart + dictSize;

        const int safeDecode = (endOnInput==endOnInputSize);
        const int checkOffset = ((safeDecode) && (dictSize < cast(int)(64 * KB)));


        /* Set up the "end" pointers for the shortcut. */
        const(BYTE*) shortiend = iend - (endOnInput ? 14 : 8) /*maxLL*/ - 2 /*offset*/;
        const(BYTE*) shortoend = oend - (endOnInput ? 14 : 8) /*maxLL*/ - 18 /*maxML*/;

        const(BYTE)* match;
        size_t offset;
        uint token;
        size_t length;


        /* Special cases */
        assert(lowPrefix <= op);
        if ((endOnInput) && (unlikely(outputSize==0))) {
            /* Empty output buffer */
            if (partialDecoding) return 0;
            return ((srcSize==1) && (*ip==0)) ? 0 : -1;
        }
        if ((!endOnInput) && (unlikely(outputSize==0))) { return (*ip==0 ? 1 : -1); }
        if ((endOnInput) && unlikely(srcSize==0)) { return -1; }

        /* Currently the fast loop shows a regression on qualcomm arm chips. */
        static if (LZ4_FAST_DEC_LOOP)
        {
            if ((oend - op) < FASTLOOP_SAFE_DISTANCE) {
                goto safe_decode;
            }

            /* Fast loop : decode sequences as long as output < iend-FASTLOOP_SAFE_DISTANCE */
            while (1) {
                /* Main fastloop assertion: We can always wildcopy FASTLOOP_SAFE_DISTANCE */
                assert(oend - op >= FASTLOOP_SAFE_DISTANCE);
                if (endOnInput) { assert(ip < iend); }
                token = *ip++;
                length = token >> ML_BITS;  /* literal length */

                assert(!endOnInput || ip <= iend); /* ip < iend before the increment */

                /* decode literal length */
                if (length == RUN_MASK) {
                    variable_length_error error = ok;
                    length += read_variable_length(&ip, iend-RUN_MASK, cast(int)endOnInput, cast(int)endOnInput, &error);
                    if (error == initial_error) { goto _output_error; }
                    if ((safeDecode) && unlikely(cast(uptrval)(op)+length<cast(uptrval)(op))) { goto _output_error; } /* overflow detection */
                    if ((safeDecode) && unlikely(cast(uptrval)(ip)+length<cast(uptrval)(ip))) { goto _output_error; } /* overflow detection */

                    /* copy literals */
                    cpy = op+length;
                    static assert(MFLIMIT >= WILDCOPYLENGTH);
                    if (endOnInput) {  /* LZ4_decompress_safe() */
                        if ((cpy>oend-32) || (ip+length>iend-32)) { goto safe_literal_copy; }
                        LZ4_wildCopy32(op, ip, cpy);
                    } else {   /* LZ4_decompress_fast() */
                        if (cpy>oend-8) { goto safe_literal_copy; }
                        LZ4_wildCopy8(op, ip, cpy); /* LZ4_decompress_fast() cannot copy more than 8 bytes at a time :
                                                     * it doesn't know input length, and only relies on end-of-block properties */
                    }
                    ip += length; op = cpy;
                } else {
                    cpy = op+length;
                    if (endOnInput) {  /* LZ4_decompress_safe() */
                        /* We don't need to check oend, since we check it once for each loop below */
                        if (ip > iend-(16 + 1/*max lit + offset + nextToken*/)) { goto safe_literal_copy; }
                        /* Literals can only be 14, but hope compilers optimize if we copy by a register size */
                        LZ4_memcpy(op, ip, 16);
                    } else {  /* LZ4_decompress_fast() */
                        /* LZ4_decompress_fast() cannot copy more than 8 bytes at a time :
                         * it doesn't know input length, and relies on end-of-block properties */
                        LZ4_memcpy(op, ip, 8);
                        if (length > 8) { LZ4_memcpy(op+8, ip+8, 8); }
                    }
                    ip += length; op = cpy;
                }

                /* get offset */
                offset = LZ4_readLE16(ip); ip+=2;
                match = op - offset;
                assert(match <= op);

                /* get matchlength */
                length = token & ML_MASK;

                if (length == ML_MASK) {
                    variable_length_error error = ok;
                    if ((checkOffset) && (unlikely(match + dictSize < lowPrefix))) { goto _output_error; } /* Error : offset outside buffers */
                    length += read_variable_length(&ip, iend - LASTLITERALS + 1, cast(int)endOnInput, 0, &error);
                    if (error != ok) { goto _output_error; }
                    if ((safeDecode) && unlikely(cast(uptrval)(op)+length<cast(uptrval)op)) { goto _output_error; } /* overflow detection */
                    length += MINMATCH;
                    if (op + length >= oend - FASTLOOP_SAFE_DISTANCE) {
                        goto safe_match_copy;
                    }
                } else {
                    length += MINMATCH;
                    if (op + length >= oend - FASTLOOP_SAFE_DISTANCE) {
                        goto safe_match_copy;
                    }

                    /* Fastpath check: Avoids a branch in LZ4_wildCopy32 if true */
                    if ((dict == withPrefix64k) || (match >= lowPrefix)) {
                        if (offset >= 8) {
                            assert(match >= lowPrefix);
                            assert(match <= op);
                            assert(op + 18 <= oend);

                            LZ4_memcpy(op, match, 8);
                            LZ4_memcpy(op+8, match+8, 8);
                            LZ4_memcpy(op+16, match+16, 2);
                            op += length;
                            continue;
                }   }   }

                if (checkOffset && (unlikely(match + dictSize < lowPrefix))) { goto _output_error; } /* Error : offset outside buffers */
                /* match starting within external dictionary */
                if ((dict==usingExtDict) && (match < lowPrefix)) {
                    if (unlikely(op+length > oend-LASTLITERALS)) {
                        if (partialDecoding) {
                            length = MIN(length, cast(size_t)(oend-op));
                        } else {
                            goto _output_error;  /* end-of-block condition violated */
                    }   }

                    if (length <= cast(size_t)(lowPrefix-match)) {
                        /* match fits entirely within external dictionary : just copy */
                        memmove(op, dictEnd - (lowPrefix-match), length);
                        op += length;
                    } else {
                        /* match stretches into both external dictionary and current block */
                        size_t copySize = cast(size_t)(lowPrefix - match);
                        size_t restSize = length - copySize;
                        LZ4_memcpy(op, dictEnd - copySize, copySize);
                        op += copySize;
                        if (restSize > cast(size_t)(op - lowPrefix)) {  /* overlap copy */
                            BYTE* endOfMatch = op + restSize;
                            const(BYTE)* copyFrom = lowPrefix;
                            while (op < endOfMatch) { *op++ = *copyFrom++; }
                        } else {
                            LZ4_memcpy(op, lowPrefix, restSize);
                            op += restSize;
                    }   }
                    continue;
                }

                /* copy match within block */
                cpy = op + length;

                assert((op <= oend) && (oend-op >= 32));
                if (unlikely(offset<16)) {
                    LZ4_memcpy_using_offset(op, match, cpy, offset);
                } else {
                    LZ4_wildCopy32(op, match, cpy);
                }

                op = cpy;   /* wildcopy correction */
            }
        safe_decode:
        }

        /* Main Loop : decode remaining sequences where output < FASTLOOP_SAFE_DISTANCE */
        while (1) {
            token = *ip++;
            length = token >> ML_BITS;  /* literal length */

            assert(!endOnInput || ip <= iend); /* ip < iend before the increment */

            /* A two-stage shortcut for the most common case:
             * 1) If the literal length is 0..14, and there is enough space,
             * enter the shortcut and copy 16 bytes on behalf of the literals
             * (in the fast mode, only 8 bytes can be safely copied this way).
             * 2) Further if the match length is 4..18, copy 18 bytes in a similar
             * manner; but we ensure that there's enough space in the output for
             * those 18 bytes earlier, upon entering the shortcut (in other words,
             * there is a combined check for both stages).
             */
            if ( (endOnInput ? length != RUN_MASK : length <= 8)
                /* strictly "less than" on input, to re-enter the loop with at least one byte */
              && likely((endOnInput ? ip < shortiend : 1) & (op <= shortoend)) ) {
                /* Copy the literals */
                LZ4_memcpy(op, ip, endOnInput ? 16 : 8);
                op += length; ip += length;

                /* The second stage: prepare for match copying, decode full info.
                 * If it doesn't work out, the info won't be wasted. */
                length = token & ML_MASK; /* match length */
                offset = LZ4_readLE16(ip); ip += 2;
                match = op - offset;
                assert(match <= op); /* check overflow */

                /* Do not deal with overlapping matches. */
                if ( (length != ML_MASK)
                  && (offset >= 8)
                  && (dict==withPrefix64k || match >= lowPrefix) ) {
                    /* Copy the match. */
                    LZ4_memcpy(op + 0, match + 0, 8);
                    LZ4_memcpy(op + 8, match + 8, 8);
                    LZ4_memcpy(op +16, match +16, 2);
                    op += length + MINMATCH;
                    /* Both stages worked, load the next token. */
                    continue;
                }

                /* The second stage didn't work out, but the info is ready.
                 * Propel it right to the point of match copying. */
                goto _copy_match;
            }

            /* decode literal length */
            if (length == RUN_MASK) {
                variable_length_error error = ok;
                length += read_variable_length(&ip, iend-RUN_MASK, cast(int)endOnInput, cast(int)endOnInput, &error);
                if (error == initial_error) { goto _output_error; }
                if ((safeDecode) && unlikely(cast(uptrval)(op)+length<cast(uptrval)(op))) { goto _output_error; } /* overflow detection */
                if ((safeDecode) && unlikely(cast(uptrval)(ip)+length<cast(uptrval)(ip))) { goto _output_error; } /* overflow detection */
            }

            /* copy literals */
            cpy = op+length;
    static if (LZ4_FAST_DEC_LOOP)
    {
        safe_literal_copy:
    }
            static assert(MFLIMIT >= WILDCOPYLENGTH);
            if ( ((endOnInput) && ((cpy>oend-MFLIMIT) || (ip+length>iend-(2+1+LASTLITERALS))) )
              || ((!endOnInput) && (cpy>oend-WILDCOPYLENGTH)) )
            {
                /* We've either hit the input parsing restriction or the output parsing restriction.
                 * In the normal scenario, decoding a full block, it must be the last sequence,
                 * otherwise it's an error (invalid input or dimensions).
                 * In partialDecoding scenario, it's necessary to ensure there is no buffer overflow.
                 */
                if (partialDecoding) {
                    /* Since we are partial decoding we may be in this block because of the output parsing
                     * restriction, which is not valid since the output buffer is allowed to be undersized.
                     */
                    assert(endOnInput);
                    /* Finishing in the middle of a literals segment,
                     * due to lack of input.
                     */
                    if (ip+length > iend) {
                        length = cast(size_t)(iend-ip);
                        cpy = op + length;
                    }
                    /* Finishing in the middle of a literals segment,
                     * due to lack of output space.
                     */
                    if (cpy > oend) {
                        cpy = oend;
                        assert(op<=oend);
                        length = cast(size_t)(oend-op);
                    }
                } else {
                    /* We must be on the last sequence because of the parsing limitations so check
                     * that we exactly regenerate the original size (must be exact when !endOnInput).
                     */
                    if ((!endOnInput) && (cpy != oend)) { goto _output_error; }
                     /* We must be on the last sequence (or invalid) because of the parsing limitations
                      * so check that we exactly consume the input and don't overrun the output buffer.
                      */
                    if ((endOnInput) && ((ip+length != iend) || (cpy > oend))) {
                        goto _output_error;
                    }
                }
                memmove(op, ip, length);  /* supports overlapping memory regions; only matters for in-place decompression scenarios */
                ip += length;
                op += length;
                /* Necessarily EOF when !partialDecoding.
                 * When partialDecoding, it is EOF if we've either
                 * filled the output buffer or
                 * can't proceed with reading an offset for following match.
                 */
                if (!partialDecoding || (cpy == oend) || (ip >= (iend-2))) {
                    break;
                }
            } else {
                LZ4_wildCopy8(op, ip, cpy);   /* may overwrite up to WILDCOPYLENGTH beyond cpy */
                ip += length; op = cpy;
            }

            /* get offset */
            offset = LZ4_readLE16(ip); ip+=2;
            match = op - offset;

            /* get matchlength */
            length = token & ML_MASK;

    _copy_match:
            if (length == ML_MASK) {
              variable_length_error error = ok;
              length += read_variable_length(&ip, iend - LASTLITERALS + 1, cast(int)endOnInput, 0, &error);
              if (error != ok) goto _output_error;
                if ((safeDecode) && unlikely(cast(uptrval)(op)+length<cast(uptrval)op)) goto _output_error;   /* overflow detection */
            }
            length += MINMATCH;

static if (LZ4_FAST_DEC_LOOP)
{
        safe_match_copy:
}
            if ((checkOffset) && (unlikely(match + dictSize < lowPrefix))) goto _output_error;   /* Error : offset outside buffers */
            /* match starting within external dictionary */
            if ((dict==usingExtDict) && (match < lowPrefix)) {
                if (unlikely(op+length > oend-LASTLITERALS)) {
                    if (partialDecoding) length = MIN(length, cast(size_t)(oend-op));
                    else goto _output_error;   /* doesn't respect parsing restriction */
                }

                if (length <= cast(size_t)(lowPrefix-match)) {
                    /* match fits entirely within external dictionary : just copy */
                    memmove(op, dictEnd - (lowPrefix-match), length);
                    op += length;
                } else {
                    /* match stretches into both external dictionary and current block */
                    size_t copySize = cast(size_t)(lowPrefix - match);
                    size_t restSize = length - copySize;
                    LZ4_memcpy(op, dictEnd - copySize, copySize);
                    op += copySize;
                    if (restSize > cast(size_t)(op - lowPrefix)) {  /* overlap copy */
                        BYTE* endOfMatch = op + restSize;
                        const(BYTE)* copyFrom = lowPrefix;
                        while (op < endOfMatch) *op++ = *copyFrom++;
                    } else {
                        LZ4_memcpy(op, lowPrefix, restSize);
                        op += restSize;
                }   }
                continue;
            }
            assert(match >= lowPrefix);

            /* copy match within block */
            cpy = op + length;

            /* partialDecoding : may end anywhere within the block */
            assert(op<=oend);
            if (partialDecoding && (cpy > oend-MATCH_SAFEGUARD_DISTANCE)) {
                size_t mlen = MIN(length, cast(size_t)(oend-op));
                const(BYTE*) matchEnd = match + mlen;
                BYTE* copyEnd = op + mlen;
                if (matchEnd > op) {   /* overlap copy */
                    while (op < copyEnd) { *op++ = *match++; }
                } else {
                    LZ4_memcpy(op, match, mlen);
                }
                op = copyEnd;
                if (op == oend) { break; }
                continue;
            }

            if (unlikely(offset<8)) {
                LZ4_write32(op, 0);   /* silence msan warning when offset==0 */
                op[0] = match[0];
                op[1] = match[1];
                op[2] = match[2];
                op[3] = match[3];
                match += inc32table[offset];
                LZ4_memcpy(op+4, match, 4);
                match -= dec64table[offset];
            } else {
                LZ4_memcpy(op, match, 8);
                match += 8;
            }
            op += 8;

            if (unlikely(cpy > oend-MATCH_SAFEGUARD_DISTANCE)) {
                BYTE* oCopyLimit = oend - (WILDCOPYLENGTH-1);
                if (cpy > oend-LASTLITERALS) { goto _output_error; } /* Error : last LASTLITERALS bytes must be literals (uncompressed) */
                if (op < oCopyLimit) {
                    LZ4_wildCopy8(op, match, oCopyLimit);
                    match += oCopyLimit - op;
                    op = oCopyLimit;
                }
                while (op < cpy) { *op++ = *match++; }
            } else {
                LZ4_memcpy(op, match, 8);
                if (length > 16)  { LZ4_wildCopy8(op+8, match+8, cpy); }
            }
            op = cpy;   /* wildcopy correction */
        }

        /* end of decoding */
        if (endOnInput) {
           return cast(int) ((cast(char*)op)-dst);     /* Nb of output bytes decoded */
       } else {
           return cast(int) ((cast(const char*)ip)-src);   /* Nb of input bytes read */
       }

        /* Overflow error detected */
    _output_error:
        return cast(int) (-((cast(const char*)ip)-src))-1;
    }
}


/*===== Instantiate the API decoding functions. =====*/

/*! LZ4_decompress_safe() :
*  compressedSize : is the exact complete size of the compressed block.
*  dstCapacity : is the size of destination buffer (which must be already allocated), presumed an upper bound of decompressed size.
* @return : the number of bytes decompressed into destination buffer (necessarily <= dstCapacity)
*           If destination buffer is not large enough, decoding will stop and output an error code (negative value).
*           If the source stream is detected malformed, the function will stop decoding and return a negative result.
* Note 1 : This function is protected against malicious data packets :
*          it will never writes outside 'dst' buffer, nor read outside 'source' buffer,
*          even if the compressed block is maliciously modified to order the decoder to do these actions.
*          In such case, the decoder stops immediately, and considers the compressed block malformed.
* Note 2 : compressedSize and dstCapacity must be provided to the function, the compressed block does not contain them.
*          The implementation is free to send / store / derive this information in whichever way is most beneficial.
*          If there is a need for a different format which bundles together both compressed data and its metadata, consider looking at lz4frame.h instead.
*/
public int LZ4_decompress_safe(const(char)* source, char* dest, int compressedSize, int maxDecompressedSize)
{
    return LZ4_decompress_generic(source, dest, compressedSize, maxDecompressedSize,
                                  endOnInputSize, decode_full_block, noDict,
                                  cast(BYTE*)dest, null, 0);
}

/*! LZ4_decompress_safe_partial() :
*  Decompress an LZ4 compressed block, of size 'srcSize' at position 'src',
*  into destination buffer 'dst' of size 'dstCapacity'.
*  Up to 'targetOutputSize' bytes will be decoded.
*  The function stops decoding on reaching this objective.
*  This can be useful to boost performance
*  whenever only the beginning of a block is required.
*
* @return : the number of bytes decoded in `dst` (necessarily <= targetOutputSize)
*           If source stream is detected malformed, function returns a negative result.
*
*  Note 1 : @return can be < targetOutputSize, if compressed block contains less data.
*
*  Note 2 : targetOutputSize must be <= dstCapacity
*
*  Note 3 : this function effectively stops decoding on reaching targetOutputSize,
*           so dstCapacity is kind of redundant.
*           This is because in older versions of this function,
*           decoding operation would still write complete sequences.
*           Therefore, there was no guarantee that it would stop writing at exactly targetOutputSize,
*           it could write more bytes, though only up to dstCapacity.
*           Some "margin" used to be required for this operation to work properly.
*           Thankfully, this is no longer necessary.
*           The function nonetheless keeps the same signature, in an effort to preserve API compatibility.
*
*  Note 4 : If srcSize is the exact size of the block,
*           then targetOutputSize can be any value,
*           including larger than the block's decompressed size.
*           The function will, at most, generate block's decompressed size.
*
*  Note 5 : If srcSize is _larger_ than block's compressed size,
*           then targetOutputSize **MUST** be <= block's decompressed size.
*           Otherwise, *silent corruption will occur*.
*/
public int LZ4_decompress_safe_partial(const char* src, char* dst, int compressedSize, int targetOutputSize, int dstCapacity)
{
    dstCapacity = MIN(targetOutputSize, dstCapacity);
    return LZ4_decompress_generic(src, dst, compressedSize, dstCapacity,
                                  endOnInputSize, partial_decode,
                                  noDict, cast(BYTE*)dst, null, 0);
}

int LZ4_decompress_fast(const(char)* source, char* dest, int originalSize)
{
    return LZ4_decompress_generic(source, dest, 0, originalSize,
                                  endOnOutputSize, decode_full_block, withPrefix64k,
                                  cast(BYTE*)dest - 64*KB, null, 0);
}

/*===== Instantiate a few more decoding cases, used more than once. =====*/

/* Exported, an obsolete API function. */
int LZ4_decompress_safe_withPrefix64k(const(char)* source, char* dest, int compressedSize, int maxOutputSize)
{
    return LZ4_decompress_generic(source, dest, compressedSize, maxOutputSize,
                                  endOnInputSize, decode_full_block, withPrefix64k,
                                  cast(BYTE*)dest - 64*KB, null, 0);
}

static int LZ4_decompress_safe_partial_withPrefix64k(const(char)* source, char* dest, int compressedSize, int targetOutputSize, int dstCapacity)
{
    dstCapacity = MIN(targetOutputSize, dstCapacity);
    return LZ4_decompress_generic(source, dest, compressedSize, dstCapacity,
                                  endOnInputSize, partial_decode, withPrefix64k,
                                  cast(BYTE*)dest - 64*KB, null, 0);
}

/* Another obsolete API function, paired with the previous one. */
int LZ4_decompress_fast_withPrefix64k(const(char)* source, char* dest, int originalSize)
{
    /* LZ4_decompress_fast doesn't validate match offsets,
     * and thus serves well with any prefixed dictionary. */
    return LZ4_decompress_fast(source, dest, originalSize);
}

static int LZ4_decompress_safe_withSmallPrefix(const(char)* source, char* dest, int compressedSize, int maxOutputSize,
                                               size_t prefixSize)
{
    return LZ4_decompress_generic(source, dest, compressedSize, maxOutputSize,
                                  endOnInputSize, decode_full_block, noDict,
                                  cast(BYTE*)dest-prefixSize, null, 0);
}

static int LZ4_decompress_safe_partial_withSmallPrefix(const(char)* source, char* dest, int compressedSize, int targetOutputSize, int dstCapacity,
                                               size_t prefixSize)
{
    dstCapacity = MIN(targetOutputSize, dstCapacity);
    return LZ4_decompress_generic(source, dest, compressedSize, dstCapacity,
                                  endOnInputSize, partial_decode, noDict,
                                  cast(BYTE*)dest-prefixSize, null, 0);
}

int LZ4_decompress_safe_forceExtDict(const(char)* source, char* dest,
                                     int compressedSize, int maxOutputSize,
                                     const(void)* dictStart, size_t dictSize)
{
    return LZ4_decompress_generic(source, dest, compressedSize, maxOutputSize,
                                  endOnInputSize, decode_full_block, usingExtDict,
                                  cast(BYTE*)dest, cast(const(BYTE)*)dictStart, dictSize);
}

int LZ4_decompress_safe_partial_forceExtDict(const(char)* source, char* dest,
                                     int compressedSize, int targetOutputSize, int dstCapacity,
                                     const(void)* dictStart, size_t dictSize)
{
    dstCapacity = MIN(targetOutputSize, dstCapacity);
    return LZ4_decompress_generic(source, dest, compressedSize, dstCapacity,
                                  endOnInputSize, partial_decode, usingExtDict,
                                  cast(BYTE*)dest, cast(const(BYTE)*)dictStart, dictSize);
}

static int LZ4_decompress_fast_extDict(const(char)* source, char* dest, int originalSize,
                                       const(void)* dictStart, size_t dictSize)
{
    return LZ4_decompress_generic(source, dest, 0, originalSize,
                                  endOnOutputSize, decode_full_block, usingExtDict,
                                  cast(BYTE*)dest, cast(const(BYTE)*)dictStart, dictSize);
}

/* The "double dictionary" mode, for use with e.g. ring buffers: the first part
 * of the dictionary is passed as prefix, and the second via dictStart + dictSize.
 * These routines are used only once, in LZ4_decompress_*_continue().
 */
int LZ4_decompress_safe_doubleDict(const(char)* source, char* dest, int compressedSize, int maxOutputSize,
                                   size_t prefixSize, const(void)* dictStart, size_t dictSize)
{
    return LZ4_decompress_generic(source, dest, compressedSize, maxOutputSize,
                                  endOnInputSize, decode_full_block, usingExtDict,
                                  cast(BYTE*)dest-prefixSize, cast(const BYTE*)dictStart, dictSize);
}

int LZ4_decompress_fast_doubleDict(const(char)* source, char* dest, int originalSize,
                                   size_t prefixSize, const(void)* dictStart, size_t dictSize)
{
    return LZ4_decompress_generic(source, dest, 0, originalSize,
                                  endOnOutputSize, decode_full_block, usingExtDict,
                                  cast(BYTE*)dest-prefixSize, cast(const BYTE*)dictStart, dictSize);
}

/*===== streaming decompression functions =====*/


/*! LZ4_createStreamDecode() and LZ4_freeStreamDecode() :
*  creation / destruction of streaming decompression tracking context.
*  A tracking context can be re-used multiple times.
*/
public LZ4_streamDecode_t* LZ4_createStreamDecode()
{
    LZ4_streamDecode_t* lz4s = cast(LZ4_streamDecode_t*) ALLOC_AND_ZERO(LZ4_streamDecode_t.sizeof);
    static assert(LZ4_STREAMDECODESIZE >= LZ4_streamDecode_t_internal.sizeof);    /* A compilation error here means LZ4_STREAMDECODESIZE is not large enough */
    return lz4s;
}

///ditto
public int LZ4_freeStreamDecode (LZ4_streamDecode_t* LZ4_stream)
{
    if (LZ4_stream == null) { return 0; }  /* support free on null */
    FREEMEM(LZ4_stream);
    return 0;
}

/*! LZ4_setStreamDecode() :
*  An LZ4_streamDecode_t context can be allocated once and re-used multiple times.
*  Use this function to start decompression of a new stream of blocks.
*  A dictionary can optionally be set. Use null or size 0 for a reset order.
*  Dictionary is presumed stable : it must remain accessible and unmodified during next decompression.
* @return : 1 if OK, 0 if error
*/
/*! LZ4_setStreamDecode() :
 *  Use this function to instruct where to find the dictionary.
 *  This function is not necessary if previous data is still available where it was decoded.
 *  Loading a size of 0 is allowed (same effect as no dictionary).
 * @return : 1 if OK, 0 if error
 */
int LZ4_setStreamDecode (LZ4_streamDecode_t* LZ4_streamDecode, const char* dictionary, int dictSize)
{
    LZ4_streamDecode_t_internal* lz4sd = &LZ4_streamDecode.internal_donotuse;
    lz4sd.prefixSize = cast(size_t)dictSize;
    if (dictSize) {
        assert(dictionary != null);
        lz4sd.prefixEnd = cast(const(BYTE)*) dictionary + dictSize;
    } else {
        lz4sd.prefixEnd = cast(const(BYTE)*) dictionary;
    }
    lz4sd.externalDict = null;
    lz4sd.extDictSize  = 0;
    return 1;
}

/*! LZ4_decoderRingBufferSize() : v1.8.2+
*  Note : in a ring buffer scenario (optional),
*  blocks are presumed decompressed next to each other
*  up to the moment there is not enough remaining space for next block (remainingSize < maxBlockSize),
*  at which stage it resumes from beginning of ring buffer.
*  When setting such a ring buffer for streaming decompression,
*  provides the minimum size of this ring buffer
*  to be compatible with any source respecting maxBlockSize condition.
* @return : minimum ring buffer size,
*           or 0 if there is an error (invalid maxBlockSize).
*/
/*! LZ4_decoderRingBufferSize() :
 *  when setting a ring buffer for streaming decompression (optional scenario),
 *  provides the minimum size of this ring buffer
 *  to be compatible with any source respecting maxBlockSize condition.
 *  Note : in a ring buffer scenario,
 *  blocks are presumed decompressed next to each other.
 *  When not enough space remains for next block (remainingSize < maxBlockSize),
 *  decoding resumes from beginning of ring buffer.
 * @return : minimum ring buffer size,
 *           or 0 if there is an error (invalid maxBlockSize).
 */
public int LZ4_decoderRingBufferSize(int maxBlockSize)
{
    if (maxBlockSize < 0) return 0;
    if (maxBlockSize > LZ4_MAX_INPUT_SIZE) return 0;
    if (maxBlockSize < 16) maxBlockSize = 16;
    return LZ4_DECODER_RING_BUFFER_SIZE(maxBlockSize);
}

/*! LZ4_decompress_*_continue() :
*  These decoding functions allow decompression of consecutive blocks in "streaming" mode.
*  A block is an unsplittable entity, it must be presented entirely to a decompression function.
*  Decompression functions only accepts one block at a time.
*  The last 64KB of previously decoded data *must* remain available and unmodified at the memory position where they were decoded.
*  If less than 64KB of data has been decoded, all the data must be present.
*
*  Special : if decompression side sets a ring buffer, it must respect one of the following conditions :
*  - Decompression buffer size is _at least_ LZ4_decoderRingBufferSize(maxBlockSize).
*    maxBlockSize is the maximum size of any single block. It can have any value > 16 bytes.
*    In which case, encoding and decoding buffers do not need to be synchronized.
*    Actually, data can be produced by any source compliant with LZ4 format specification, and respecting maxBlockSize.
*  - Synchronized mode :
*    Decompression buffer size is _exactly_ the same as compression buffer size,
*    and follows exactly same update rule (block boundaries at same positions),
*    and decoding function is provided with exact decompressed size of each block (exception for last block of the stream),
*    _then_ decoding & encoding ring buffer can have any size, including small ones ( < 64 KB).
*  - Decompression buffer is larger than encoding buffer, by a minimum of maxBlockSize more bytes.
*    In which case, encoding and decoding buffers do not need to be synchronized,
*    and encoding ring buffer can have any size, including small ones ( < 64 KB).
*
*  Whenever these conditions are not possible,
*  save the last 64KB of decoded data into a safe buffer where it can't be modified during decompression,
*  then indicate where this data is saved using LZ4_setStreamDecode(), before decompressing next block.
*/
/*
*_continue() :
    These decoding functions allow decompression of multiple blocks in "streaming" mode.
    Previously decoded blocks must still be available at the memory position where they were decoded.
    If it's not possible, save the relevant part of decoded data into a safe buffer,
    and indicate where it stands using LZ4_setStreamDecode()
*/
int LZ4_decompress_safe_continue (LZ4_streamDecode_t* LZ4_streamDecode, const(char)* source, char* dest, int compressedSize, int maxOutputSize)
{
    LZ4_streamDecode_t_internal* lz4sd = &LZ4_streamDecode.internal_donotuse;
    int result;

    if (lz4sd.prefixSize == 0) {
        /* The first call, no dictionary yet. */
        assert(lz4sd.extDictSize == 0);
        result = LZ4_decompress_safe(source, dest, compressedSize, maxOutputSize);
        if (result <= 0) return result;
        lz4sd.prefixSize = cast(size_t)result;
        lz4sd.prefixEnd = cast(BYTE*)dest + result;
    } else if (lz4sd.prefixEnd == cast(BYTE*)dest) {
        /* They're rolling the current segment. */
        if (lz4sd.prefixSize >= 64*KB - 1)
            result = LZ4_decompress_safe_withPrefix64k(source, dest, compressedSize, maxOutputSize);
        else if (lz4sd.extDictSize == 0)
            result = LZ4_decompress_safe_withSmallPrefix(source, dest, compressedSize, maxOutputSize,
                                                         lz4sd.prefixSize);
        else
            result = LZ4_decompress_safe_doubleDict(source, dest, compressedSize, maxOutputSize,
                                                    lz4sd.prefixSize, lz4sd.externalDict, lz4sd.extDictSize);
        if (result <= 0) return result;
        lz4sd.prefixSize += cast(size_t)result;
        lz4sd.prefixEnd  += result;
    } else {
        /* The buffer wraps around, or they're switching to another buffer. */
        lz4sd.extDictSize = lz4sd.prefixSize;
        lz4sd.externalDict = lz4sd.prefixEnd - lz4sd.extDictSize;
        result = LZ4_decompress_safe_forceExtDict(source, dest, compressedSize, maxOutputSize,
                                                  lz4sd.externalDict, lz4sd.extDictSize);
        if (result <= 0) return result;
        lz4sd.prefixSize = cast(size_t)result;
        lz4sd.prefixEnd  = cast(BYTE*)dest + result;
    }

    return result;
}

int LZ4_decompress_fast_continue (LZ4_streamDecode_t* LZ4_streamDecode, const(char)* source, char* dest, int originalSize)
{
    LZ4_streamDecode_t_internal* lz4sd = &LZ4_streamDecode.internal_donotuse;
    int result;
    assert(originalSize >= 0);

    if (lz4sd.prefixSize == 0) {
        assert(lz4sd.extDictSize == 0);
        result = LZ4_decompress_fast(source, dest, originalSize);
        if (result <= 0) return result;
        lz4sd.prefixSize = cast(size_t)originalSize;
        lz4sd.prefixEnd = cast(BYTE*)dest + originalSize;
    } else if (lz4sd.prefixEnd == cast(BYTE*)dest) {
        if (lz4sd.prefixSize >= 64*KB - 1 || lz4sd.extDictSize == 0)
            result = LZ4_decompress_fast(source, dest, originalSize);
        else
            result = LZ4_decompress_fast_doubleDict(source, dest, originalSize,
                                                    lz4sd.prefixSize, lz4sd.externalDict, lz4sd.extDictSize);
        if (result <= 0) return result;
        lz4sd.prefixSize += cast(size_t)originalSize;
        lz4sd.prefixEnd  += originalSize;
    } else {
        lz4sd.extDictSize = lz4sd.prefixSize;
        lz4sd.externalDict = lz4sd.prefixEnd - lz4sd.extDictSize;
        result = LZ4_decompress_fast_extDict(source, dest, originalSize,
                                             lz4sd.externalDict, lz4sd.extDictSize);
        if (result <= 0) return result;
        lz4sd.prefixSize = cast(size_t)originalSize;
        lz4sd.prefixEnd  = cast(BYTE*)dest + originalSize;
    }

    return result;
}


/*
Advanced decoding functions :
*_usingDict() :
    These decoding functions work the same as "_continue" ones,
    the dictionary must be explicitly provided within parameters
*/
/*! LZ4_decompress_*_usingDict() :
*  These decoding functions work the same as
*  a combination of LZ4_setStreamDecode() followed by LZ4_decompress_*_continue()
*  They are stand-alone, and don't need an LZ4_streamDecode_t structure.
*  Dictionary is presumed stable : it must remain accessible and unmodified during decompression.
*  Performance tip : Decompression speed can be substantially increased
*                    when dst == dictStart + dictSize.
*/
int LZ4_decompress_safe_usingDict(const(char)* source, char* dest, int compressedSize, int maxOutputSize, const char* dictStart, int dictSize)
{
    if (dictSize==0)
        return LZ4_decompress_safe(source, dest, compressedSize, maxOutputSize);
    if (dictStart+dictSize == dest) {
        if (dictSize >= 64*KB - 1) {
            return LZ4_decompress_safe_withPrefix64k(source, dest, compressedSize, maxOutputSize);
        }
        assert(dictSize >= 0);
        return LZ4_decompress_safe_withSmallPrefix(source, dest, compressedSize, maxOutputSize, cast(size_t)dictSize);
    }
    assert(dictSize >= 0);
    return LZ4_decompress_safe_forceExtDict(source, dest, compressedSize, maxOutputSize, dictStart, cast(size_t)dictSize);
}

int LZ4_decompress_safe_partial_usingDict(const(char)* source, char* dest, int compressedSize, int targetOutputSize, int dstCapacity, const char* dictStart, int dictSize)
{
    if (dictSize==0)
        return LZ4_decompress_safe_partial(source, dest, compressedSize, targetOutputSize, dstCapacity);
    if (dictStart+dictSize == dest) {
        if (dictSize >= 64*KB - 1) {
            return LZ4_decompress_safe_partial_withPrefix64k(source, dest, compressedSize, targetOutputSize, dstCapacity);
        }
        assert(dictSize >= 0);
        return LZ4_decompress_safe_partial_withSmallPrefix(source, dest, compressedSize, targetOutputSize, dstCapacity, cast(size_t)dictSize);
    }
    assert(dictSize >= 0);
    return LZ4_decompress_safe_partial_forceExtDict(source, dest, compressedSize, targetOutputSize, dstCapacity, dictStart, cast(size_t)dictSize);
}

int LZ4_decompress_fast_usingDict(const(char)* source, char* dest, int originalSize, const char* dictStart, int dictSize)
{
    if (dictSize==0 || dictStart+dictSize == dest)
        return LZ4_decompress_fast(source, dest, originalSize);
    assert(dictSize >= 0);
    return LZ4_decompress_fast_extDict(source, dest, originalSize, dictStart, cast(size_t)dictSize);
}

