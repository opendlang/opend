module gamut.plugins.png;

nothrow @nogc @safe:

import core.stdc.stdlib: malloc, free, realloc;
import gamut.types;
import gamut.bitmap;
import gamut.io;
import gamut.plugin;
import gamut.codecs.pngload;
import gamut.codecs.stb_image_write;

// PERF: STB callbacks could disappear in favor of our own callbakcs, to avoid one step.

void registerPNG() @trusted
{
    FreeImage_RegisterInternalPlugin(FIF_PNG, &InitProc_PNG,
                                     "PNG".ptr,
                                     "Portable Network Graphics".ptr,
                                     "png".ptr,
                                     null);
}

extern(Windows)
{
    FIBITMAP* Load_PNG(FreeImageIO *io, fi_handle handle, int page, int flags, void *data) @trusted
    {
        IOAndHandle ioh;
        ioh.io = io;
        ioh.handle = handle;

        stbi_io_callbacks stb_callback;
        stb_callback.read = &stb_read;
        stb_callback.skip = &stb_skip;
        stb_callback.eof = &stb_eof;


        // "FreeImage uses the RGB(A) color model to represent color images in memory. A 8-bit 
        // greyscale image has a single channel, often called the black channel. A 24-bit image is made 
        // up of three 8-bit channels: one for each of the red, green and blue colors. For 32-bit images, 
        // a fourth 8-bit channel, called alpha channel, is used to create and store masks, which let you 
        // manipulate, isolate, and protect specific parts of an image. Unlike the others channels, the 
        // alpha channel doesn’t convey color information, in a physical sense."


        FIBITMAP* bitmap = cast(FIBITMAP*) malloc(FIBITMAP.sizeof);
        if (!bitmap) 
            return null;

        bool is16bit = false;//(stbi__png_is16(&stb_callback, &ioh));

        ubyte* decoded;
        int width, height, components;
        int requiredComp = 0; // keep original number of channels.

        // rewind stream
        if (!io.rewind(handle))
        {
            goto error;
        }

        if (is16bit)
        {
            decoded = cast(ubyte*) stbi_load_16_from_callbacks(&stb_callback, &ioh, &width, &height, &components, requiredComp);
        }
        else
        {
            decoded = stbi_load_from_callbacks(&stb_callback, &ioh, &width, &height, &components, requiredComp);
        }

        if (decoded is null)
            goto error;

        bitmap._width = width;
        bitmap._height = height;
        bitmap._data = decoded; // works because codec.pngload and gamut both use malloc/free
        bitmap._bpp = (is16bit ? 16 : 8) * components; // store even if not significant

        if (!is16bit)
        {
            bitmap._type = FIT_BITMAP;
        }
        else
        {
            if (components == 1)
            {
                bitmap._type = FIT_RGB16;
            }
            else if (components == 2)
            {
                // No support for that in Freeimage.
                free(decoded);
                goto error;
            }
            else if (components == 3)
            {
                bitmap._type = FIT_RGB16;
            }
            else if (components == 4)
            {
                bitmap._type = FIT_RGBA16;
            }
        }

        return bitmap;

        error:
            free(bitmap);
        return null;
    }

    void InitProc_PNG (Plugin *plugin, int format_id)
    {
        assert(format_id == FIF_PNG);
        plugin.supportsRead = true;
        plugin.supportsWrite = true;

        plugin.loadProc = &Load_PNG;
        plugin.saveProc = &Save_PNG;
        plugin.validateProc = &Validate_PNG;
        plugin.mimeProc = &MIME_PNG;
    }

    const(char)* MIME_PNG() @trusted
    {
        return "image/png".ptr;
    }

    bool Validate_PNG(FreeImageIO *io, fi_handle handle) @trusted
    {
        static immutable ubyte[8] pngSignature = [0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a];
        return fileIsStartingWithSignature(io, handle, pngSignature);
    }

    bool Save_PNG(FreeImageIO *io, FIBITMAP *dib, fi_handle handle, int page, int flags, void *data) @trusted
    {
        if (page != 0)
            return false;

        if (!FreeImage_HasPixels(dib))
            return false; // no pixel data

        if (dib._type != FIT_BITMAP)
            return false; // no support for say, 16-bit

        int channels = 0;
        switch (dib._bpp)
        {
            case 8:   channels = 1; break;
            case 16:  channels = 2; break;
            case 24:  channels = 3; break;
            case 32:  channels = 4; break;
            default: break;
        }
        if (channels == 0)
            return false; // unsupported number of channels

        int width = dib._width;
        int height = dib._height;
        int pitch = FreeImage_GetPitch(dib);
        int len;
        ubyte* pixels = dib._data;
        ubyte *img = gamut.codecs.stb_image_write.stbi_write_png_to_mem(pixels, pitch, width, height, channels, &len);
        if (img == null)
            return false;

        scope(exit) free(img);

        // Write to output at once.
        // PERF: adapt stb_image_write.h to output in our own buffer directly.
        if (len != io.write(img, 1, len, handle))
            return false;

        return true;
    }
}

private:

// Need to give both a FreeImageIO* and a fi_handle to STB callbacks.
static struct IOAndHandle
{
    FreeImageIO* io;
    fi_handle handle;
}

// fill 'data' with 'size' bytes.  return number of bytes actually read
int stb_read(void *user, char *data, int size) @system
{
    IOAndHandle* ioh = cast(IOAndHandle*) user;

    // Cannot ask more than 0x7fff_ffff bytes at once.
    assert(size <= 0x7fffffff);

    size_t bytesRead = ioh.io.read(data, 1, size, ioh.handle);
    return cast(int) bytesRead;
}

// skip the next 'n' bytes, or 'unget' the last -n bytes if negative
void stb_skip(void *user, int n) @system
{
    IOAndHandle* ioh = cast(IOAndHandle*) user;
    ioh.io.skipBytes(ioh.handle, n);
}

// returns nonzero if we are at end of file/data
int stb_eof(void *user) @system
{
    IOAndHandle* ioh = cast(IOAndHandle*) user;
    return ioh.io.eof(ioh.handle);
}