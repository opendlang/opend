/**
  New GIF decoder, to replace gifdec.d.
*/
module gamut.codecs.gif;

version(decodeGIF):

import gamut.io;
import gamut.image;
import core.stdc.string: memcmp;
import core.stdc.stdlib: malloc, free;

nothrow @nogc:

debug = gifLoading;

debug(gifLoading) import core.stdc.stdio;

/// Reference: GIF89a Specification.
struct GIFDecoder
{
nothrow @nogc:

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

        if (imageFlags & 0x80)
        {
            // has Global Color Table
            
            // "Size of Global Color Table - If the Global Color Table Flag is
            // set to 1, the value in this field is used to calculate the number
            // of bytes contained in the Global Color Table."
            gctSize = 1 << ((imageFlags & 0x07) + 1);
            if (gct is null)
            {
                gct = cast(ubyte*) malloc(3 * gctSize);
            }

            // Parse GCT
            if (1 != io.read(gct, gctSize*3, 1, handle))
            {
                *err = true;
                return;
            }
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
        
        int numImages = 0;
        while(true)
        {
            int elem = parseSyntax(err);
            if (*err) return;
            if (elem == 1)
                numImages++;
            else if (elem == 0)
                break;
        }

        restoreFileOffset(offset, err); if (*err) return;

        // TODO: not correct, a single GIF frame can have several "frames" inside
        this.layers = numImages; 

        *err = false;
        return;
    }

    ~this()
    {
        free(gct);
        gct = null;
        free(lct);
        lct = null;
    }

    /// Decode next GIF frame in a rgba8 buffer.
    void decodeNextFrame(ref Image outFrame)
    {
        // TODO
    }

private:
    IOStream *io;
    IOHandle handle;
    bool isGIF89;
    int logicalScreenWidth;
    int logicalScreenHeight;
    int layers;
    ubyte backgroundColorIndex; 
    ubyte pixelAspectRatio; // Aspect Ratio = (Pixel Aspect Ratio + 15) / 64

    ubyte* gct, lct, currentPalette;
    int gctSize, lctSize, currentPaletteSize;

    // Latest frame information
    int frameX, frameY, frameW, frameH;
    bool frameInterlaced;

    static struct GCE
    {
        ubyte disposalMethod;
        bool transparencyFlag;
        int delayTime;
        ubyte transparentColorIndex;
    }

    GCE gce;

    int colorResolution;

    static struct stbi__gif_lzw
    {
        short prefix;
        ubyte first;
        ubyte suffix;
    }
    stbi__gif_lzw[8192] codes; // TODO: allocate that table


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

    // Parse one syntax element (GIF "part"), return:
    // Returns: 0 => the element is an end of stream, stop parsing now
    //          1 => an LWZ image was parsed
    //          2 => a graphics control entry was parsed
    //          3 => a comment entry was parsed
    //          4 => a text entry definition was parsed
    //          5 => an application info definition was parsed
    // *err is true if input error, in which case abandon decoding. Return -1 in that case.
    int parseSyntax(bool* err)
    {
        ubyte sep = read_ubyte(err); if (*err) return -1;
        if (sep == PART_LWZ_IMAGE)
        {
            parseLWZImage(err); if (*err) return -1;
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
                    return 4;

                case LABEL_GRAPHICS_CONTROL:
                    parseGraphicsControlExt(err);
                    if (*err) return -1;
                    return 2;

                case LABEL_COMMENT:
                    parseCommentExt(err);
                    if (*err) return -1;
                    return 3;

                case LABEL_APPLICATION_INFO:
                    parseApplicationInfoExt(err);
                    if (*err) return -1;
                    return 5;

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

    void parseLWZImage(bool* err)
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

            // alloc maximum possible table size, for future lct (if any)
            if (lct is null) lct = cast(ubyte*) malloc(3 * 256);

            // Parse LCT
            if (1 != io.read(gct, lctSize*3, 1, handle))
            {
                *err = true;
                return;
            }

            currentPalette = lct;
            currentPaletteSize = lctSize;
        } 
        else
        {
            currentPalette = gct;
            currentPaletteSize = gctSize;
        }

        // TODO: do something with decoded buffer
        parseImageData(err);
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

    void parseImageData(bool* err)
    {
        *err = false;

        //stbi_uc lzw_cs;
        //stbi__int32 len, init_code;
        //stbi__uint32 first;
        //stbi__int32 codesize, codemask, avail, oldcode, bits, valid_bits, clear;
        
        stbi__gif_lzw *p;
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

                    printf("code %d\n", cast(short)code);
                    //stbi__out_gif_code(g, (stbi__uint16) code);

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

/+
    static void stbi__out_gif_code(stbi__gif *g, stbi__uint16 code)
    {
        stbi_uc *p, *c;
        int idx;

        // recurse to decode the prefixes, since the linked-list is backwards,
        // and working backwards through an interleaved image would be nasty
        if (g->codes[code].prefix >= 0)
            stbi__out_gif_code(g, g->codes[code].prefix);

        if (g->cur_y >= g->max_y) return;

        idx = g->cur_x + g->cur_y;
        p = &g->out[idx];
        g->history[idx / 4] = 1;

        c = &g->color_table[g->codes[code].suffix * 4];
        if (c[3] > 128) { // don't render transparent pixels;
            p[0] = c[2];
            p[1] = c[1];
            p[2] = c[0];
            p[3] = c[3];
        }
        g->cur_x += 4;

        if (g->cur_x >= g->max_x) {
            g->cur_x = g->start_x;
            g->cur_y += g->step;

            while (g->cur_y >= g->max_y && g->parse > 0) {
                g->step = (1 << g->parse) * g->line_size;
                g->cur_y = g->start_y + (g->step >> 1);
                --g->parse;
            }
        }
    }
+/
}

/+
Table * new_table(int key_size)
{
    int key;
    int init_bulk = (1 << (key_size + 1));
    if (init_bulk < 256)
        init_bulk = 256;

    Table* table = cast(Table*) malloc(Table.sizeof + Entry.sizeof * init_bulk);
    if (table) 
    {
        table.bulk = init_bulk;
        table.nentries = (1 << key_size) + 2;
        table.entries = cast(Entry *) &table[1];
        for (key = 0; key < (1 << key_size); key++)
            table.entries[key] = Entry(1, 0xFFF, cast(ubyte)key);
    }
    return table;
}
+/