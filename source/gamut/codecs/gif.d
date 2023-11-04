/**
  New GIF decoder, to replace gifdec.d.
*/
module gamut.codecs.gif;

version(decodeGIF):



import gamut.io;
import gamut.image;
import gamut.types;
import core.stdc.string: memcmp, memset, memcpy;
import core.stdc.stdlib: malloc, free;

nothrow @nogc:

//debug = gifLoading;

debug(gifLoading) import core.stdc.stdio;

/// Reference: GIF89a Specification.
struct GIFDecoder
{
nothrow @nogc:

    // MAYDO: it's not sure if disposal 3 method should be better supported. 
    // it seems that different open source GIF decoders do it differently, 
    // and it's quite uncommon too. So, we have no support (it will decode incorrectly).

    // Parse the GIF minimally to have the layers count.
    void open(IOStream *io, IOHandle handle, bool* err)
    {
        this.io = io;
        this.handle = handle;
        parseHeader(err); if (*err) return;
    }

    // <available after open>
    int width()
    {
        return logicalScreenWidth;
    }
    int height()
    {
        return logicalScreenHeight;
    }
    int numLayers()
    {
        return layers;
    }
    float FPS()
    {
        return imageFPS;
    }
    float getPixelAspectRatio()
    {
        if (pixelAspectRatio == 0)
        {
            return GAMUT_UNKNOWN_ASPECT_RATIO;
        }
        else
        {
            return (pixelAspectRatio + 15.0f) / 64;
        }
    }
    // </available after open>

    void parseHeader(bool* err)
    {
        debug(gifLoading) printf("HEADER\n");
        char[6] magic;
        if (1 != io.read(magic.ptr, 6, 1, handle))
        {
            *err = true;
            return;
        }

        if (memcmp(magic.ptr, "GIF87a".ptr, 6) == 0)
        {
            isGIF89 = false;
        }
        else if (memcmp(magic.ptr, "GIF89a".ptr, 6) == 0)
        {
            isGIF89 = true;
        }
        else
        {
            *err = true;
            return;
        }

        logicalScreenWidth      = read_ushort(err); if (*err) return;
        logicalScreenHeight     = read_ushort(err); if (*err) return;
        ubyte imageFlags        = read_ubyte(err); if (*err) return;
        backgroundColorIndex    = read_ubyte(err); if (*err) return;
        pixelAspectRatio        = read_ubyte(err); if (*err) return;

        transparent = -1;


        // Allocate all memory needed for decoder
        int pcount = logicalScreenWidth * logicalScreenHeight;

        if (globalAlloc is null)
        {
            // Always need 34kb of memory.
            size_t gctSizeMax = 256*4;
            size_t lctSizeMax = 256*4;
            size_t outSize = pcount*4;
            size_t bgSize  = pcount*4;
            size_t historySize = pcount;
            size_t codesSize = 8192 * LZWCode.sizeof;
            globalAlloc = cast(ubyte*) malloc(gctSizeMax + lctSizeMax + outSize 
                                               + bgSize + historySize + codesSize);
            ubyte* mem = globalAlloc;
            gct        = mem; mem += gctSizeMax;
            lct        = mem; mem += lctSizeMax;
            out_       = mem; mem += outSize;
            background = mem; mem += bgSize;
            history    = mem; mem += historySize;
            codes      = cast(LZWCode*)mem; mem += codesSize;
        }

        if (imageFlags & 0x80)
        {
            // "Size of Global Color Table - If the Global Color Table Flag is
            // set to 1, the value in this field is used to calculate the number
            // of bytes contained in the Global Color Table."
            gctSize = 1 << ((imageFlags & 0x07) + 1);

            // Parse GCT
            parseColortable(gct, gctSize, -1, err); if (*err) return;
        }
        else
        {
            gct = null;
            gctSize = 0;
        }

        currentPalette = gct;
        currentPaletteSize = gctSize;

        // Number of bits to represent components.
        // "For example, if the value in this field is 3, then the palette of
        // the original image had 4 bits per primary color available to create
        // the image.  This value should be set to indicate the richness of
        // the original palette, even if not every color from the whole
        // palette is available on the source machine."
        colorResolution = ((imageFlags >> 4) & 7) + 1;

        // Count frames in image.

        auto offset = saveFileOffset(err); if (*err) return;

        layers = 0;
        int frameDurationMs = 100;
        double sumDurationsMs = 0.0;
        firstFrame = true;
        while(true)
        {
            bool gotOneFrame;
            decodeNextFrame(&gotOneFrame, null, &frameDurationMs, err);
            if (*err) return;
            if (!gotOneFrame)
                break;
            layers++;
            sumDurationsMs += frameDurationMs;

            // note: by breaking here, we can limit number of decoded frames.
            //break;
        } 
        // Note: last GCE encountered gives the "FPS", we assume GIF frame have same delay,
        // which is incorrect.
        if (sumDurationsMs == 0)
        {
            imageFPS = 10;
        }
        else
        {
            imageFPS = layers * 1000.0f / sumDurationsMs;
        }

        restoreFileOffset(offset, err); if (*err) return;

        firstFrame = true;
        *err = false;
        return;
    }

    ~this()
    {
        free(globalAlloc);
        globalAlloc = null;
    }

    /// Decode next GIF frame in a rgba8 buffer.
    void decodeNextFrame(bool* gotOneFrame,    // Filled with true if got one frame.
                         Image* outFrame,      // can be null if no pixel decoding needed, pixels if got one frame
                         int* frameDurationMs, // written with that frame duration.
                         bool* err)
    {
        *gotOneFrame = false;
        *err = false;
        bool needDecode = outFrame !is null;
        int res = parseFrame(err, needDecode);
        if (*err) return;

        if (res == 0)
        {
            // end of stream
            return;
        }
        else if (res == 1)
        {
            if (outFrame)
            {
                assert(outFrame.width == logicalScreenWidth);
                assert(outFrame.height == logicalScreenHeight);

                int scanlineBytes = 4 * outFrame.width;
                for (int y = 0; y < outFrame.height; ++y)
                {
                    int pixelIndex = y * logicalScreenWidth;
                    memcpy( outFrame.scanptr(y), &out_[pixelIndex*4], scanlineBytes );
                }
            }

            *gotOneFrame = true;
            *frameDurationMs = gce.frameDurationMs;
        }
        else
            assert(false);
    }

private:
    IOStream *io;
    IOHandle handle;
    bool isGIF89;
    int logicalScreenWidth;
    int logicalScreenHeight;
    int layers;
    float imageFPS;
    ubyte backgroundColorIndex; 
    ubyte pixelAspectRatio;

    // like in stb_image, palette are a RGBA quadruplet
    ubyte* gct, lct, currentPalette;
    int gctSize, lctSize, currentPaletteSize;

    // Latest frame information
    int frameX, frameY, frameW, frameH;

    // Next pixel to write to.
    int currentX, currentY;

    // Pass of interlaced scan (0 to 3).
    int interlacedPass;

    // If the frame is interlaced in first place.
    bool frameInterlaced;

    // Current transparent color index. This is used to modify global color palette in place.
    int transparent;

    ubyte* globalAlloc;
    ubyte* background;
    ubyte* history;
    ubyte* out_;
    bool firstFrame;

    static struct GCE
    {
    nothrow @nogc:
        ubyte disposalMethod;
        bool transparencyFlag;
        ushort delayTime = 0;
        ubyte transparentColorIndex;

        int frameDurationMs()
        {
            if (delayTime == 0 || delayTime == 1)
                return 100; // 100 ms duration
            else
                return delayTime * 10;
        }
    }

    GCE gce;

    int colorResolution;

    align(1) static struct LZWCode
    {
        align(1):
        short prefix;
        ubyte first;
        ubyte suffix;
    }
    static assert(LZWCode.sizeof == 4);
    LZWCode* codes;


    ushort read_ushort(bool* err)
    {
        return io.read_ushort_LE(handle, err);
    }

    ubyte read_ubyte(bool* err)
    {
        return io.read_ubyte(handle, err);
    }

    c_long saveFileOffset(bool* err)
    {
        c_long res = io.tell(handle);
        if (res == -1)
            *err = true;
        else
            *err = false;
        return res;
    }

    void restoreFileOffset(c_long absOffset, bool* err)
    {
        if (io.seekAbsolute(handle, absOffset))
            *err = false;
        else
            *err = true;
    }

    enum ubyte PART_LWZ_IMAGE     = ','; // 0x2C
    enum ubyte PART_END_OF_STREAM = ';'; // 0x3B
    enum ubyte PART_EXTENSION     = '!'; // 0x21

    enum ubyte LABEL_TEXT_ENTRY_DEFINITION = 0x01;
    enum ubyte LABEL_GRAPHICS_CONTROL      = 0xF9;
    enum ubyte LABEL_COMMENT               = 0xFE;
    enum ubyte LABEL_APPLICATION_INFO      = 0xFF;

    // Parse until can return one frame.
    // Return 0 for end of stream.
    // Return 1 for one frame.
    // *err is true if input error, in which case abandon decoding. Return -1 in that case.
    // outImage can be null if no pixel decoding needed.
    int parseFrame(bool* err, bool needDecode)
    {
        if (firstFrame)
        {
            int pcount = logicalScreenWidth * logicalScreenHeight;

            // image is treated as "transparent" at the start - ie, nothing overwrites the current 
            // background;
            // background colour is only used for pixels that are not rendered first frame, after 
            // that "background" color refers to the color that was there the previous frame.
            memset(out_,       0, 4 * pcount);
            memset(background, 0, 4 * pcount); // state of the background (starts transparent)
            memset(history,    0, pcount);        // pixels that were affected previous frame

            firstFrame = false;
        }
        else if (needDecode)
        {
            // Dispose previous frame
            // second frame - how do we dispose of the previous one?

            int dispose = gce.disposalMethod;
            int pcount = logicalScreenWidth * logicalScreenHeight;

            ubyte* two_back = null;

            if ((dispose == 3) && (two_back == null)) 
            {
                dispose = 2; // if I don't have an image to revert back to, default to the old background
            }

            if (dispose == 3) // use previous graphic
            { 
                for (int pi = 0; pi < pcount; ++pi) 
                {
                    if (history[pi]) 
                    {
                        memcpy(&out_[pi * 4], &two_back[pi * 4], 4 );
                    }
                }
            } 
            else if (dispose == 2) 
            {                
                // restore what was changed last frame to background before that frame;
                for (int pi = 0; pi < pcount; ++pi) 
                {
                    if (history[pi]) 
                    {
                        memcpy(&out_[pi * 4], &background[pi * 4], 4 );
                    }
                }
            } 
            else 
            {
                // This is a non-disposal case either way, so just
                // leave the pixels as is, and they will become the new background
                // 1: do not dispose
                // 0:  not specified.
            }

            // background is what out is after the undoing of the previou frame;
            assert(background !is null);
            assert(out_ !is null);
            memcpy(background, out_, 4 * pcount);
        }

        while(true)
        {
            ubyte sep = read_ubyte(err); if (*err) return -1;
            if (sep == PART_LWZ_IMAGE)
            {
                parseLWZImage(err, needDecode); if (*err) return -1;
                return 1;
            }
            else if (sep == PART_END_OF_STREAM)
            {
                return 0; // EOF
            }
            else if (sep == PART_EXTENSION)
            {
                ubyte label = read_ubyte(err); if (*err) return -1;

                switch (label) 
                {
                    case LABEL_TEXT_ENTRY_DEFINITION:
                        parseTextEntryExt(err);
                        if (*err) return -1;
                        break;

                    case LABEL_GRAPHICS_CONTROL:
                        parseGraphicsControlExt(err);
                        if (*err) return -1;
                        break;

                    case LABEL_COMMENT:
                        parseCommentExt(err);
                        if (*err) return -1;
                        break;

                    case LABEL_APPLICATION_INFO:
                        parseApplicationInfoExt(err);
                        if (*err) return -1;
                        break;

                    default:
                        *err = true;
                        return  -1;
                        // unknown extension, error
                }
            }
            else
            {
                *err = true;
                return -1; // unknown syntax
            }
        }
    }

    bool skip_bytes(int numBytes)
    {
        return io.skipBytes(handle, numBytes);
    }

    void skipSubblocks(bool* err)
    {
        ubyte size;
        do 
        {
            size = read_ubyte(err); if (*err) return;
            if (!skip_bytes(size))
            {
                *err = true;
                return;
            }
        } while (size);
        *err = false;
    }

    void parseGraphicsControlExt(bool* err)
    {  
        debug(gifLoading) printf("GCE\n");

        ubyte size = read_ubyte(err); if (*err) return;
        if (size != 4) 
        {
            *err = true;
            return;
        }

        ubyte rdit = read_ubyte(err); if (*err) return;

        gce.disposalMethod        = (rdit >> 2) & 3;
        gce.transparencyFlag      = rdit & 1;
        gce.delayTime             = read_ushort(err); if (*err) return;
        gce.transparentColorIndex = read_ubyte(err); if (*err) return;

        // unset old transparent
        if (transparent >= 0 && gct) 
        {
            gct[4 * transparent + 3] = 255;
        }

        if (gce.transparencyFlag) 
        {
            transparent = gce.transparentColorIndex;
            if (transparent >= 0 && gct) 
            {
                gct[4 * transparent + 3] = 0;
            }
        } 
        else 
        {
            transparent = -1;
        }

        debug(gifLoading) printf(" * delayTime = %d ms\n", gce.frameDurationMs());
        debug(gifLoading) printf(" * disposal method = %d\n", gce.disposalMethod);

        ubyte zero = read_ubyte(err); if (*err) return;
        if (zero != 0)
        {
            *err = true;
            return;
        }

        *err = false;
    }

    void parseCommentExt(bool* err)
    {
        debug(gifLoading) printf("COMMENT\n");

        skipSubblocks(err); // ignore all
    }

    void parseTextEntryExt(bool* err)
    {
        debug(gifLoading) printf("TEXT ENTRY\n");
        // Discard plain text metadata.
        if (!skip_bytes(13)) /* block size = 12 */
        {
            *err = true;
            return;
        }
         skipSubblocks(err);
    }

    void parseLWZImage(bool* err, bool needDecode)
    {
        debug(gifLoading) printf("IMAGE\n");

        frameX = read_ushort(err); if (*err) return;
        frameY = read_ushort(err); if (*err) return;
        frameW = read_ushort(err); if (*err) return;
        frameH = read_ushort(err); if (*err) return;
        ubyte frameFlags = read_ubyte(err); if (*err) return;

        // Reference: https://commandlinefanatic.com/cgi-bin/showarticle.cgi?article=art011
        // "If the interlace flag is set, then the lines of the image will be included out of 
        // order: first, every 8th line. Second, every 8th line, starting from the fourth. 
        // Third, every 4th line, starting from the second, and finally every other line, 
        // completing the image.
        frameInterlaced = (frameFlags & 0x40) != 0;

        /* Local Color Table? */
        if (frameFlags & 0x80) 
        {
            // has local table
            lctSize = 1 << ((frameFlags & 0x07) + 1);

            // Parse LCT
            int transpIndex = gce.transparencyFlag ? transparent : -1;
            if (needDecode)
            {
                parseColortable(lct, lctSize, transpIndex, err); if (*err) return;
            }
            else
            {
                if (!io.skipBytes(handle, lctSize*3))
                {
                    *err = true;
                    return;
                }
            }

            currentPalette = lct;
            currentPaletteSize = lctSize;
        } 
        else
        {
            currentPalette = gct;
            currentPaletteSize = gctSize;
        }

        debug(gifLoading) printf(" * frameX = %d\n", frameX); 
        debug(gifLoading) printf(" * frameY = %d\n", frameY);
        debug(gifLoading) printf(" * frameW = %d\n", frameW);
        debug(gifLoading) printf(" * frameH = %d\n", frameH);
        debug(gifLoading) printf(" * interlaced = %d\n", frameInterlaced);
        debug(gifLoading) printf(" * local table = %d\n", (frameFlags & 0x80) );

        interlacedPass = 0;
        currentX = frameX;
        currentY = frameY;

        parseImageData(err, needDecode);
    }

    void parseApplicationInfoExt(bool* err)
    {
        debug(gifLoading) printf("APPLICATION INFO\n");
        ubyte blockSize = read_ubyte(err); if (*err) return;

        // skip
        if (!skip_bytes(blockSize))
        {
            *err = true;
            return;
        }
        skipSubblocks(err);
    }

    void parseImageData(bool* err, bool needDecode)
    {
        *err = false;

        LZWCode *p;
        ubyte lzw_cs = read_ubyte(err); if (*err) return;

        if (lzw_cs > 12) 
        {
            *err = true;
            return;
        }

        int clear = 1 << lzw_cs;
        uint first = 1;
        int codesize = lzw_cs + 1;
        int codemask = (1 << codesize) - 1;
        int bits = 0;
        int valid_bits = 0;
        int init_code;

        for (init_code = 0; init_code < clear; init_code++) 
        {
            codes[init_code].prefix = -1;
            codes[init_code].first = cast(ubyte) init_code;
            codes[init_code].suffix = cast(ubyte) init_code;
        }

        // support no starting clear code
        int avail = clear+2;
        int oldcode = -1;

        int len = 0;

        void* output = null;

        while(true)
        {
            if (valid_bits < codesize) 
            {
                if (len == 0) 
                {
                    len = read_ubyte(err); if (*err) return;
                    if (len == 0)
                        return /* output */;
                }
                --len;
                int newbits = read_ubyte(err); if (*err) return;
                bits |= (newbits << valid_bits);
                valid_bits += 8;
            } 
            else 
            {
                int code = bits & codemask;
                bits >>= codesize;
                valid_bits -= codesize;
                // @OPTIMIZE: is there some way we can accelerate the non-clear path?
                if (code == clear) 
                {
                    // clear code
                    codesize = lzw_cs + 1;
                    codemask = (1 << codesize) - 1;
                    avail = clear + 2;
                    oldcode = -1;
                    first = 0;
                } 
                else if (code == clear + 1) 
                { 
                    // end of stream code
                    if (!io.skipBytes(handle, len))
                    {
                        *err = true;
                        return;
                    }

                    len = read_ubyte(err); if (*err) return;
                    while (len > 0)
                    {
                        if (!io.skipBytes(handle, len))
                        {
                            *err = true;
                            return;
                        }
                        len = read_ubyte(err); if (*err) return;
                    }
                    return /* output */;
                } 
                else if (code <= avail) 
                {
                    if (first) 
                    {
                        // no clear code, corrupt GIF
                        *err = true;
                        return;
                    }

                    if (oldcode >= 0) 
                    {
                        p = &codes[avail++];
                        if (avail > 8192) 
                        {
                            // too many codes, corrupt GIF
                            *err = true;
                            return;
                        }
                        p.prefix = cast(short) oldcode;
                        p.first = codes[oldcode].first;
                        p.suffix = (code == avail) ? p.first : codes[code].first;
                    } 
                    else if (code == avail)
                    {
                        // illegal code in raster, corrupt GIF
                        *err = true;
                        return;
                    }

                    //printf("code %d\n", cast(short)code);
                    if (needDecode)
                        stbi__out_gif_code(cast(ushort) code);

                    if ((avail & codemask) == 0 && avail <= 0x0FFF) 
                    {
                        codesize++;
                        codemask = (1 << codesize) - 1;
                    }

                    oldcode = code;
                } 
                else 
                {
                    // illegal code in raster, corrupt GIF
                    *err = true;
                    return;
                }
            }
        }
    }

    // "The rows of an Interlaced images are arranged in the following order:
    //
    //   Group 1 : Every 8th. row, starting with row 0.              (Pass 1)
    //   Group 2 : Every 8th. row, starting with row 4.              (Pass 2)
    //   Group 3 : Every 4th. row, starting with row 2.              (Pass 3)
    //   Group 4 : Every 2nd. row, starting with row 1.              (Pass 4)"
    static immutable interlacedPassYStep  = [8, 8, 4, 2];
    static immutable interlacedPassYStart = [0, 4, 2, 1];

    void stbi__out_gif_code(ushort code)
    {
        // Recurse to decode the prefixes, since the linked-list is backwards,
        // and working backwards through an interleaved image would be nasty
        if (codes[code].prefix >= 0)
            stbi__out_gif_code(codes[code].prefix);

        if (currentY >= logicalScreenHeight) 
            return;

        int pIndex = (currentY * logicalScreenWidth + currentX);

        ubyte* pixelptr = &out_[pIndex * 4 ];

        history[pIndex] = 1;

        ubyte* c = &currentPalette[codes[code].suffix * 4];

        if (c[3] > 128) 
        { 
            pixelptr[0] = c[0];
            pixelptr[1] = c[1];
            pixelptr[2] = c[2];
            pixelptr[3] = 255;
        }

        // Manages location of next pixel

        currentX += 1;
        if (currentX >= frameX + frameW)
        {
            currentX = frameX;
            if (frameInterlaced)
            {
                currentY += interlacedPassYStep[interlacedPass];

                if (currentY >= frameY + frameH)
                {
                    if (interlacedPass < 3)
                    {
                        interlacedPass += 1;
                        currentY = frameY + interlacedPassYStart[interlacedPass];
                    }
                }
            }
            else
            {
                currentY += 1;
            }
        }
    }

    void parseColortable(ubyte* palette, int num_entries, int transp, bool* err)
    {
        *err = false;
        for (int i = 0; i < num_entries; ++i) 
        {
            if (1 != io.read(&palette[4*i], 3, 1, handle))
            {
                *err = true;
                return;
            }
            palette[4*i+3] = (transp == i ? 0 : 255);
        }
    }
}