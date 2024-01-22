module gamut.codecs.msf_gif;

version(encodeGIF):

/*
HOW TO USE:

    In exactly one translation unit (.c or .cpp file), #define MSF_GIF_IMPL before including the header, like so:

    #define MSF_GIF_IMPL
    #include "msf_gif.h"

    Everywhere else, just include the header like normal.


USAGE EXAMPLE:

    int width = 480, height = 320, centisecondsPerFrame = 5, bitDepth = 16;
    MsfGifState gifState = {};
    // msf_gif_bgra_flag = true; //optionally, set this flag if your pixels are in BGRA format instead of RGBA
    // msf_gif_alpha_threshold = 128; //optionally, enable transparency (see function documentation below for details)
    msf_gif_begin(&gifState, width, height);
    msf_gif_frame(&gifState, ..., centisecondsPerFrame, bitDepth, width * 4); //frame 1
    msf_gif_frame(&gifState, ..., centisecondsPerFrame, bitDepth, width * 4); //frame 2
    msf_gif_frame(&gifState, ..., centisecondsPerFrame, bitDepth, width * 4); //frame 3, etc...
    MsfGifResult result = msf_gif_end(&gifState);
    if (result.data) {
        FILE * fp = fopen("MyGif.gif", "wb");
        fwrite(result.data, result.dataSize, 1, fp);
        fclose(fp);
    }
    msf_gif_free(result);

Detailed function documentation can be found in the header section below.


ERROR HANDLING:

    If memory allocation fails, the functions will signal the error via their return values.
    If one function call fails, the library will free all of its allocations,
    and all subsequent calls will safely no-op and return 0 until the next call to `msf_gif_begin()`.
    Therefore, it's safe to check only the return value of `msf_gif_end()`.


REPLACING MALLOC:

    This library uses malloc+realloc+free internally for memory allocation.
    To facilitate integration with custom memory allocators, these calls go through macros, which can be redefined.
    The expected function signature equivalents of the macros are as follows:

    void * MSF_GIF_MALLOC(void * context, size_t newSize)
    void * MSF_GIF_REALLOC(void * context, void * oldMemory, size_t oldSize, size_t newSize)
    void MSF_GIF_FREE(void * context, void * oldMemory, size_t oldSize)

    If your allocator needs a context pointer, you can set the `customAllocatorContext` field of the MsfGifState struct
    before calling msf_gif_begin(), and it will be passed to all subsequent allocator macro calls.

    The maximum number of bytes the library will allocate to encode a single gif is bounded by the following formula:
    `(2 * 1024 * 1024) + (width * height * 8) + ((1024 + width * height * 1.5) * 3 * frameCount)`
    The peak heap memory usage in bytes, if using a general-purpose heap allocator, is bounded by the following formula:
    `(2 * 1024 * 1024) + (width * height * 9.5) + 1024 + (16 * frameCount) + (2 * sizeOfResultingGif)


See end of file for license information.
*/

import core.stdc.stdint;
import core.stdc.stdlib: malloc, free, realloc;
import core.stdc.string: memset, memcpy;
import inteli.emmintrin;

nothrow @nogc:

//version 2.2

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/// HEADER                                                                                                           ///
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

struct MsfGifResult
{
    void * data;
    size_t dataSize;
    size_t allocSize; //internal use
    void * contextPointer; //internal use
}

struct MsfCookedFrame //internal use
{
    uint32_t* pixels = null;
    int depth, count, rbits, gbits, bbits;
}

struct MsfGifBuffer 
{
    MsfGifBuffer * next;
    size_t size;
    uint8_t[1] data;
}

extern(C)
{
    alias MsfGifFileWriteFunc = size_t function(const(void)* buffer, size_t size, size_t count, void* stream);
}

struct MsfGifState
{
    MsfGifFileWriteFunc fileWriteFunc;
    void * fileWriteData;
    MsfCookedFrame previousFrame;
    MsfCookedFrame currentFrame;
    int16_t * lzwMem;
    MsfGifBuffer * listHead;
    MsfGifBuffer * listTail;
    int width, height;
    void * customAllocatorContext;
    int framesSubmitted; //needed for transparency to work correctly (because we reach into the previous frame)

    //The gif format only supports 1-bit transparency, meaning a pixel will either be fully transparent or fully opaque.
    //Pixels with an alpha value less than the alpha threshold will be treated as transparent.
    //To enable exporting transparent gifs, set it to a value between 1 and 255 (inclusive) before calling msf_gif_frame().
    //Setting it to 0 causes the alpha channel to be ignored. Its initial value is 0.
    int msf_gif_alpha_threshold = 10; // GP: tuned grossly
}


/**
 * @return                     A block of memory containing the gif file data, or NULL on error.
 *                             You are responsible for freeing this via `msf_gif_free()`.
 */
MsfGifResult msf_gif_end(MsfGifState * handle);

/**
 * @param result                The MsfGifResult struct, verbatim as it was returned from `msf_gif_end()`.
 */
void msf_gif_free(MsfGifResult result);



void* MSF_GIF_MALLOC(void* contextPointer, size_t newSize) 
{
    return malloc(newSize);
}

void* MSF_GIF_REALLOC(void* contextPointer, void* oldMemory, size_t oldSize, size_t newSize)
{
    return realloc(oldMemory, newSize);
}

void MSF_GIF_FREE(void* contextPointer, void* oldMemory, size_t oldSize)
{
    free(oldMemory);
}

// PERf: original file use the intrinsics for bit scan
int msf_bit_log(int i) 
{
    __gshared static immutable int[32] MultiplyDeBruijnBitPosition = 
    [
        0, 9, 1, 10, 13, 21, 2, 29, 11, 14, 16, 18, 22, 25, 3, 30,
        8, 12, 20, 28, 15, 17, 24, 7, 19, 27, 23, 6, 26, 5, 4, 31,
    ];
    i |= i >> 1;
    i |= i >> 2;
    i |= i >> 4;
    i |= i >> 8;
    i |= i >> 16;
    return MultiplyDeBruijnBitPosition[cast(uint)(i * 0x07C4ACDDU) >> 27] + 1;
}


int msf_imin(int a, int b) { return a < b? a : b; }
int msf_imax(int a, int b) { return b < a? a : b; }

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/// Frame Cooking                                                                                                    ///
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

enum int msf_gif_bgra_flag = 0;

void msf_cook_frame(MsfCookedFrame * frame, const(uint8_t)* raw, uint8_t * used,
                    int width, int height, int pitch, int depth, int msf_gif_alpha_threshold)
{
    //bit depth for each channel
    static immutable int[17] rdepthsArray = [ 0, 0, 1, 1, 1, 2, 2, 2, 3, 3, 3, 4, 4, 4, 5, 5, 5 ];
    static immutable int[17] gdepthsArray = [ 0, 1, 1, 1, 2, 2, 2, 3, 3, 3, 4, 4, 4, 5, 5, 5, 6 ];
    static immutable int[17] bdepthsArray = [ 0, 0, 0, 1, 1, 1, 2, 2, 2, 3, 3, 3, 4, 4, 4, 5, 5 ];
    //this extra level of indirection looks unnecessary but we need to explicitly decay the arrays to pointers
    //in order to be able to swap them because of C's annoying not-quite-pointers, not-quite-value-types stack arrays.
    const(int)* rdepths = rdepthsArray.ptr;
    const(int)* gdepths = gdepthsArray.ptr;
    const(int)* bdepths = bdepthsArray.ptr;

    static immutable int[16] ditherKernel = 
    [
         0 << 12,  8 << 12,  2 << 12, 10 << 12,
        12 << 12,  4 << 12, 14 << 12,  6 << 12,
         3 << 12, 11 << 12,  1 << 12,  9 << 12,
        15 << 12,  7 << 12, 13 << 12,  5 << 12,
    ];

    uint32_t * cooked = frame.pixels;
    int count = 0;
    do 
    {
        int rbits = rdepths[depth], gbits = gdepths[depth], bbits = bdepths[depth];
        int paletteSize = (1 << (rbits + gbits + bbits)) + 1;
        memset(used, 0, paletteSize * uint8_t.sizeof);

        //TODO: document what this math does and why it's correct
        int rdiff = (1 << (8 - rbits)) - 1;
        int gdiff = (1 << (8 - gbits)) - 1;
        int bdiff = (1 << (8 - bbits)) - 1;
        short rmul = cast(short) ((255.0f - rdiff) / 255.0f * 257);
        short gmul = cast(short) ((255.0f - gdiff) / 255.0f * 257);
        short bmul = cast(short) ((255.0f - bdiff) / 255.0f * 257);

        int gmask = ((1 << gbits) - 1) << rbits;
        int bmask = ((1 << bbits) - 1) << rbits << gbits;

        for (int y = 0; y < height; ++y) 
        {
            int x = 0;
            
            __m128i k = _mm_loadu_si128(cast(__m128i *) &ditherKernel[(y & 3) * 4]);
            __m128i k2 = _mm_or_si128(_mm_srli_epi32(k, rbits), _mm_slli_epi32(_mm_srli_epi32(k, bbits), 16));
            for (; x < width - 3; x += 4) 
            {
                const(uint8_t)* pixels = &raw[y * pitch + x * 4];
                __m128i p = _mm_loadu_si128(cast(__m128i *) pixels);

                __m128i rb = _mm_and_si128(p, _mm_set1_epi32(0x00FF00FF));
                __m128i rb1 = _mm_mullo_epi16(rb, _mm_set_epi16(bmul, rmul, bmul, rmul, bmul, rmul, bmul, rmul));
                __m128i rb2 = _mm_adds_epu16(rb1, k2);
                __m128i r3 = _mm_srli_epi32(_mm_and_si128(rb2, _mm_set1_epi32(0x0000FFFF)), 16 - rbits);
                __m128i b3 = _mm_and_si128(_mm_srli_epi32(rb2, 32 - rbits - gbits - bbits), _mm_set1_epi32(bmask));

                __m128i g = _mm_and_si128(_mm_srli_epi32(p, 8), _mm_set1_epi32(0x000000FF));
                __m128i g1 = _mm_mullo_epi16(g, _mm_set1_epi32(gmul));
                __m128i g2 = _mm_adds_epu16(g1, _mm_srli_epi32(k, gbits));
                __m128i g3 = _mm_and_si128(_mm_srli_epi32(g2, 16 - rbits - gbits), _mm_set1_epi32(gmask));

                __m128i out_ = _mm_or_si128(_mm_or_si128(r3, g3), b3);

                //mask in transparency based on threshold
                //NOTE: we can theoretically do a sub instead of srli by doing an unsigned compare via bias
                //      to maybe save a TINY amount of throughput? but lol who cares maybe I'll do it later -m
                __m128i invAlphaMask = _mm_cmplt_epi32(_mm_srli_epi32(p, 24), _mm_set1_epi32(msf_gif_alpha_threshold));
                out_ = _mm_or_si128(_mm_and_si128(invAlphaMask, _mm_set1_epi32(paletteSize - 1)), _mm_andnot_si128(invAlphaMask, out_));

                //TODO: does storing this as a __m128i then reading it back as a uint32_t violate strict aliasing?
                uint32_t * c = &cooked[y * width + x];
                _mm_storeu_si128(cast(__m128i *) c, out_);
            }

            //scalar cleanup loop
            for (; x < width; ++x) 
            {
                const(uint8_t)* p = &raw[y * pitch + x * 4];

                //transparent pixel if alpha is low
                if (p[3] < msf_gif_alpha_threshold) {
                    cooked[y * width + x] = paletteSize - 1;
                    continue;
                }

                int dx = x & 3, dy = y & 3;
                int k3 = ditherKernel[dy * 4 + dx];
                cooked[y * width + x] =
                    (msf_imin(65535, p[2] * bmul + (k3 >> bbits)) >> (16 - rbits - gbits - bbits) & bmask) |
                    (msf_imin(65535, p[1] * gmul + (k3 >> gbits)) >> (16 - rbits - gbits        ) & gmask) |
                     msf_imin(65535, p[0] * rmul + (k3 >> rbits)) >> (16 - rbits                );
            }
        }

        count = 0;
        for (int i = 0; i < width * height; ++i) 
        {
            used[cooked[i]] = 1;
        }

        //count used colors, transparent is ignored
        for (int j = 0; j < paletteSize - 1; ++j) 
        {
            count += used[j];
        }
    } while (count >= 256 && --depth);

    MsfCookedFrame ret = { cooked, depth, count, rdepths[depth], gdepths[depth], bdepths[depth] };
    *frame = ret;
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/// Frame Compression                                                                                                ///
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

void msf_put_code(uint8_t * * writeHead, uint32_t * blockBits, int len, uint32_t code) 
{
    //insert new code into block buffer
    int idx = *blockBits / 8;
    int bit = *blockBits % 8;
    (*writeHead)[idx + 0] |= code <<       bit ;
    (*writeHead)[idx + 1] |= code >> ( 8 - bit);
    (*writeHead)[idx + 2] |= code >> (16 - bit);
    *blockBits += len;

    //prep the next block buffer if the current one is full
    if (*blockBits >= 256 * 8) {
        *blockBits -= 255 * 8;
        (*writeHead) += 256;
        (*writeHead)[2] = (*writeHead)[1];
        (*writeHead)[1] = (*writeHead)[0];
        (*writeHead)[0] = 255;
        memset((*writeHead) + 4, 0, 256);
    }
}

struct MsfStridedList
{
    int16_t * data;
    int len;
    int stride;
}

void msf_lzw_reset(MsfStridedList* lzw, int tableSize, int stride) 
{
    memset(lzw.data, 0xFF, 4096 * stride * int16_t.sizeof);
    lzw.len = tableSize + 2;
    lzw.stride = stride;
}

MsfGifBuffer * msf_compress_frame(void * allocContext, int width, int height, int centiSeconds, 
                                  MsfCookedFrame frame, MsfGifState * handle, uint8_t * used, int16_t * lzwMem)
{
    //NOTE: we reserve enough memory for theoretical the worst case upfront because it's a reasonable amount,
    //      and prevents us from ever having to check size or realloc during compression
    int maxGIFSize = 0;
    {
        maxGIFSize += 32; // headers
        maxGIFSize += 256*3;
        int maxData = width * height * 3 / 2;
        int maxFramingOverhead = 256;
        maxGIFSize += maxData;
        maxGIFSize += maxFramingOverhead; // issue #63, else small GIF might exceed buffer.
    }
    int maxBufSize = cast(int)(MsfGifBuffer.data.offsetof) + maxGIFSize;
    MsfGifBuffer * buffer = cast(MsfGifBuffer *) MSF_GIF_MALLOC(allocContext, maxBufSize);
    if (!buffer) { return null; }
    uint8_t * writeHead = buffer.data.ptr;
    MsfStridedList lzw = { lzwMem };

    //allocate tlb
    int totalBits = frame.rbits + frame.gbits + frame.bbits;
    int tlbSize = (1 << totalBits) + 1;

    //only 64k, so stack allocating is fine
    // GP: I don't think that's fine.
    uint8_t[(1 << 16) + 1] tlb; 

    //generate palette
    static struct Color3 
    { 
        uint8_t r = 0, g = 0, b = 0; 
    } 
    static assert(Color3.sizeof == 3);
    Color3[256] table;

    int tableIdx = 1; //we start counting at 1 because 0 is the transparent color
    //transparent is always last in the table
    tlb[tlbSize-1] = 0;
    for (int i = 0; i < tlbSize-1; ++i) 
    {
        if (used[i]) 
        {
            tlb[i] = cast(ubyte)tableIdx;
            int rmask = (1 << frame.rbits) - 1;
            int gmask = (1 << frame.gbits) - 1;
            //isolate components
            int r = i & rmask;
            int g = i >> frame.rbits & gmask;
            int b = i >> (frame.rbits + frame.gbits);
            //shift into highest bits
            r <<= 8 - frame.rbits;
            g <<= 8 - frame.gbits;
            b <<= 8 - frame.bbits;
            table[tableIdx].r = cast(ubyte)(r | r >> frame.rbits | r >> (frame.rbits * 2) | r >> (frame.rbits * 3));
            table[tableIdx].g = cast(ubyte)(g | g >> frame.gbits | g >> (frame.gbits * 2) | g >> (frame.gbits * 3));
            table[tableIdx].b = cast(ubyte)(b | b >> frame.bbits | b >> (frame.bbits * 2) | b >> (frame.bbits * 3));
            if (msf_gif_bgra_flag) {
                uint8_t temp = table[tableIdx].r;
                table[tableIdx].r = table[tableIdx].b;
                table[tableIdx].b = temp;
            }
            ++tableIdx;
        }
    }
    int hasTransparentPixels = used[tlbSize-1];

    //SPEC: "Because of some algorithmic constraints however, black & white images which have one color bit
    //       must be indicated as having a code size of 2."
    int tableBits = msf_imax(2, msf_bit_log(tableIdx - 1));
    int tableSize = 1 << tableBits;
    //NOTE: we don't just compare `depth` field here because it will be wrong for the first frame and we will segfault
    MsfCookedFrame previous = handle.previousFrame;
    int hasSamePal = frame.rbits == previous.rbits && frame.gbits == previous.gbits && frame.bbits == previous.bbits;
    int framesCompatible = hasSamePal && !hasTransparentPixels;

    char[19] headerBytes = "\x21\xF9\x04\x05\0\0\0\0\x2C\0\0\0\0\0\0\0\0\x80";
    //NOTE: we need to check the frame number because if we reach into the buffer prior to the first frame,
    //      we'll just clobber the file header instead, which is a bug
    if (hasTransparentPixels && handle.framesSubmitted > 0) {
        handle.listTail.data.ptr[3] = 0x09; //set the previous frame's disposal to background, so transparency is possible
    }
    memcpy(&headerBytes[4], &centiSeconds, 2); // Note: Only works on LittleEndian!
    memcpy(&headerBytes[13], &width, 2); // Note: Only works on LittleEndian!
    memcpy(&headerBytes[15], &height, 2); // Note: Only works on LittleEndian!
    headerBytes[17] |= tableBits - 1;
    memcpy(writeHead, headerBytes.ptr, 18);
    writeHead += 18;

    //local color table
    memcpy(writeHead, table.ptr, tableSize * Color3.sizeof);
    writeHead += tableSize * Color3.sizeof;
    *writeHead++ = cast(ubyte)tableBits;

    //prep block
    memset(writeHead, 0, 260);
    writeHead[0] = 255;
    uint32_t blockBits = 8; //relative to block.head

    //SPEC: "Encoders should output a Clear code as the first code of each image data stream."
    msf_lzw_reset(&lzw, tableSize, tableIdx);
    msf_put_code(&writeHead, &blockBits, msf_bit_log(lzw.len - 1), tableSize);

    int lastCode = framesCompatible && frame.pixels[0] == previous.pixels[0]? 0 : tlb[frame.pixels[0]];
    for (int i = 1; i < width * height; ++i) 
    {
        //PERF: branching vs. branchless version of this line is observed to have no discernable impact on speed
        int color = framesCompatible && frame.pixels[i] == previous.pixels[i]? 0 : tlb[frame.pixels[i]];
        int code = (&lzw.data[lastCode * lzw.stride])[color];
        if (code < 0) {
            //write to code stream
            int codeBits = msf_bit_log(lzw.len - 1);
            msf_put_code(&writeHead, &blockBits, codeBits, lastCode);

            if (lzw.len > 4095) {
                //reset buffer code table
                msf_put_code(&writeHead, &blockBits, codeBits, tableSize);
                msf_lzw_reset(&lzw, tableSize, tableIdx);
            } else {
                (&lzw.data[lastCode * lzw.stride])[color] = cast(short)lzw.len;
                ++lzw.len;
            }

            lastCode = color;
        } else {
            lastCode = code;
        }
    }

    //write code for leftover index buffer contents, then the end code
    msf_put_code(&writeHead, &blockBits, msf_imin(12, msf_bit_log(lzw.len - 1)), lastCode);
    msf_put_code(&writeHead, &blockBits, msf_imin(12, msf_bit_log(lzw.len)), tableSize + 1);

    //flush remaining data
    if (blockBits > 8) {
        int bytes = (blockBits + 7) / 8; //round up
        writeHead[0] = cast(ubyte)(bytes - 1);
        writeHead += bytes;
    }
    *writeHead++ = 0; //terminating block

    //fill in buffer header and shrink buffer to fit data
    buffer.next = null;
    buffer.size = writeHead - buffer.data.ptr;
    MsfGifBuffer * moved =
        cast(MsfGifBuffer *) MSF_GIF_REALLOC(allocContext, buffer, maxBufSize, MsfGifBuffer.data.offsetof + buffer.size);
    if (!moved) 
    {
        MSF_GIF_FREE(allocContext, buffer, maxBufSize); 
        return null; 
    }
    return moved;
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/// To-memory API                                                                                                    ///
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

enum int lzwAllocSize = 4096 * 256 * 2;

//NOTE: by C standard library conventions, freeing NULL should be a no-op,
//      but just in case the user's custom free doesn't follow that rule, we do null checks on our end as well.
static void msf_free_gif_state(MsfGifState * handle) {
    if (handle.previousFrame.pixels) MSF_GIF_FREE(handle.customAllocatorContext, handle.previousFrame.pixels,
                                                   handle.width * handle.height * uint32_t.sizeof);
    if (handle.currentFrame.pixels)  MSF_GIF_FREE(handle.customAllocatorContext, handle.currentFrame.pixels,
                                                   handle.width * handle.height * uint32_t.sizeof);
    if (handle.lzwMem) MSF_GIF_FREE(handle.customAllocatorContext, handle.lzwMem, lzwAllocSize);
    for (MsfGifBuffer * node = handle.listHead; node;) {
        MsfGifBuffer * next = node.next; //NOTE: we have to copy the `next` pointer BEFORE freeing the node holding it
        MSF_GIF_FREE(handle.customAllocatorContext, node, MsfGifBuffer.data.offsetof + node.size);
        node = next;
    }
    handle.listHead = null; //this implicitly marks the handle as invalid until the next msf_gif_begin() call
}

/**
 * @param width                Image width in pixels.
 * @param height               Image height in pixels.
 * @return                     Non-zero on success, 0 on error.
 */
int msf_gif_begin(MsfGifState * handle, int width, int height) 
{
    //NOTE: we cannot stomp the entire struct to zero because we must preserve `customAllocatorContext`.
    MsfCookedFrame empty;
    handle.previousFrame = empty;
    handle.currentFrame = empty;
    handle.width = width;
    handle.height = height;
    handle.framesSubmitted = 0;

    //allocate memory for LZW buffer
    //NOTE: Unfortunately we can't just use stack memory for the LZW table because it's 2MB,
    //      which is more stack space than most operating systems give by default,
    //      and we can't realistically expect users to be willing to override that just to use our library,
    //      so we have to allocate this on the heap.
    handle.lzwMem = cast(int16_t *) MSF_GIF_MALLOC(handle.customAllocatorContext, lzwAllocSize);
    handle.previousFrame.pixels =
        cast(uint32_t *) MSF_GIF_MALLOC(handle.customAllocatorContext, handle.width * handle.height * uint32_t.sizeof);
    handle.currentFrame.pixels =
        cast(uint32_t *) MSF_GIF_MALLOC(handle.customAllocatorContext, handle.width * handle.height * uint32_t.sizeof);

    //setup header buffer header (lol)
    handle.listHead = cast(MsfGifBuffer *) MSF_GIF_MALLOC(handle.customAllocatorContext, MsfGifBuffer.data.offsetof + 32);
    if (!handle.listHead || !handle.lzwMem || !handle.previousFrame.pixels || !handle.currentFrame.pixels) {
        msf_free_gif_state(handle);
        return 0;
    }
    handle.listTail = handle.listHead;
    handle.listHead.next = null;
    handle.listHead.size = 32;

    //NOTE: because __attribute__((__packed__)) is annoyingly compiler-specific, we do this unreadable weirdness
    char[33] headerBytes = "GIF89a\0\0\0\0\x70\0\0\x21\xFF\x0BNETSCAPE2.0\x03\x01\0\0\0";
    memcpy(&headerBytes[6], &width, 2); // same, only works in little-endian
    memcpy(&headerBytes[8], &height, 2); // same, only works in little-endian
    memcpy(handle.listHead.data.ptr, headerBytes.ptr, 32);
    return 1;
}

/**
* @param pixelData            Pointer to raw framebuffer data. Rows must be contiguous in memory, in RGBA8 format
*                             (or BGRA8 if you have set `msf_gif_bgra_flag = true`).
*                             Note: This function does NOT free `pixelData`. You must free it yourself afterwards.
* @param centiSecondsPerFrame How many hundredths of a second this frame should be displayed for.
*                             Note: This being specified in centiseconds is a limitation of the GIF format.
* @param maxBitDepth          Limits how many bits per pixel can be used when quantizing the gif.
*                             The actual bit depth chosen for a given frame will be less than or equal to
*                             the supplied maximum, depending on the variety of colors used in the frame.
*                             `maxBitDepth` will be clamped between 1 and 16. The recommended default is 16.
*                             Lowering this value can result in faster exports and smaller gifs,
*                             but the quality may suffer.
*                             Please experiment with this value to find what works best for your application.
* @param pitchInBytes         The number of bytes from the beginning of one row of pixels to the beginning of the next.
*                             If you want to flip the image, just pass in a negative pitch.
* @return                     Non-zero on success, 0 on error.
*/
int msf_gif_frame(MsfGifState * handle, const(uint8_t)* pixelData, int centiSecondsPerFame, int maxBitDepth, int pitchInBytes)
{
    if (!handle.listHead) { return 0; }

    maxBitDepth = msf_imax(1, msf_imin(16, maxBitDepth));

    //only 64k, so stack allocating is fine
    //GP: again argh
    uint8_t[(1 << 16) + 1] used; 
    msf_cook_frame(&handle.currentFrame, pixelData, used.ptr, handle.width, handle.height, pitchInBytes,
        msf_imin(maxBitDepth, handle.previousFrame.depth + 160 / msf_imax(1, handle.previousFrame.count)),
                   handle.msf_gif_alpha_threshold);

    MsfGifBuffer * buffer = msf_compress_frame(handle.customAllocatorContext, handle.width, handle.height,
        centiSecondsPerFame, handle.currentFrame, handle, used.ptr, handle.lzwMem);
    if (!buffer) { msf_free_gif_state(handle); return 0; }
    handle.listTail.next = buffer;
    handle.listTail = buffer;

    //swap current and previous frames
    MsfCookedFrame tmp = handle.previousFrame;
    handle.previousFrame = handle.currentFrame;
    handle.currentFrame = tmp;

    handle.framesSubmitted += 1;
    return 1;
}

MsfGifResult msf_gif_end(MsfGifState * handle) 
{
    if (!handle.listHead) 
    { 
        MsfGifResult empty; 
        return empty; 
    }

    //first pass: determine total size
    size_t total = 1; //1 byte for trailing marker
    for (MsfGifBuffer * node = handle.listHead; node; node = node.next) { total += node.size; }

    //second pass: write data
    uint8_t * buffer = cast(uint8_t *) MSF_GIF_MALLOC(handle.customAllocatorContext, total);
    if (buffer) 
    {
        uint8_t * writeHead = buffer;
        for (MsfGifBuffer * node = handle.listHead; node; node = node.next) 
        {
            memcpy(writeHead, node.data.ptr, node.size);
            writeHead += node.size;
        }
        *writeHead++ = 0x3B;
    }

    //third pass: free buffers
    msf_free_gif_state(handle);

    MsfGifResult ret = { buffer, total, total, handle.customAllocatorContext };
    return ret;
}

void msf_gif_free(MsfGifResult result) 
{
    if (result.data)
    {
        MSF_GIF_FREE(result.contextPointer, result.data, result.allocSize);
    }
}

/*
------------------------------------------------------------------------------
This software is available under 2 licenses -- choose whichever you prefer.
------------------------------------------------------------------------------
ALTERNATIVE A - MIT License
Copyright (c) 2021 Miles Fogle
Permission is hereby granted, free of charge, to any person obtaining a copy of
this software and associated documentation files (the "Software"), to deal in
the Software without restriction, including without limitation the rights to
use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
of the Software, and to permit persons to whom the Software is furnished to do
so, subject to the following conditions:
The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
------------------------------------------------------------------------------
ALTERNATIVE B - Public Domain (www.unlicense.org)
This is free and unencumbered software released into the public domain.
Anyone is free to copy, modify, publish, use, compile, sell, or distribute this
software, either in source code form or as a compiled binary, for any purpose,
commercial or non-commercial, and by any means.
In jurisdictions that recognize copyright laws, the author or authors of this
software dedicate any and all copyright interest in the software to the public
domain. We make this dedication for the benefit of the public at large and to
the detriment of our heirs and successors. We intend this dedication to be an
overt act of relinquishment in perpetuity of all present and future rights to
this software under copyright law.
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN
ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
------------------------------------------------------------------------------
*/
