/**
Bridge FreeImage and JPEG codec.

Copyright: Copyright Guillaume Piolat 2022
License:   $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost License 1.0)

Note: This library is re-implemented in D from FreeImage documentation (FreeImage3180.pdf).
      See the differences in DIFFERENCES.md
*/
module gamut.plugins.jpeg;

nothrow @nogc @safe:

import core.stdc.stdlib: malloc, free, realloc;
import gamut.types;
import gamut.bitmap;
import gamut.io;
import gamut.plugin;
import gamut.codecs.jpegload;
import gamut.codecs.stb_image_write;

void registerJPEG() @trusted
{
    FreeImage_RegisterInternalPlugin(FIF_JPEG, &InitProc_JPEG,
                                     "JPEG".ptr,
                                     "Independent JPEG Group".ptr,
                                     "jpg,jpeg,jif,jfif".ptr,
                                     null);
}

extern(Windows)
{
    FIBITMAP* Load_JPEG(FreeImageIO *io, fi_handle handle, int page, int flags, void *data) @trusted
    {
        JPEGIOHandle jio;
        jio.wrapped = io;
        jio.handle = handle;

        int requestedComp = -1; // keep original

        int forceFlags = 0;
        if (flags & JPEG_GREYSCALE) forceFlags++;
        if (flags & JPEG_RGB) forceFlags++;
        if (flags & JPEG_RGBA) forceFlags++;

        if (forceFlags > 1)
            return null; // JPEG_GREYSCALE, JPEG_RGB and JPEG_RGBA are mutually exclusive.

        if (flags & JPEG_GREYSCALE) requestedComp = 1;
        if (flags & JPEG_RGB)       requestedComp = 3;
        if (flags & JPEG_RGBA)      requestedComp = 4;

        int width, height, actualComp;
        ubyte[] decoded = decompress_jpeg_image_from_stream(&stream_read_jpeg, &jio, width, height, actualComp, requestedComp);
        if (decoded is null)
            return null;

        FIBITMAP* bitmap = null;

        if (actualComp != 1 && actualComp != 3 && actualComp != 4)
            goto error2;

        bitmap = cast(FIBITMAP*) malloc(FIBITMAP.sizeof);
        if (!bitmap) 
            goto error2;

         if (width > GAMUT_MAX_WIDTH || height > GAMUT_MAX_HEIGHT)
            goto error;

        bitmap._width = width;
        bitmap._height = height;
        bitmap._data = decoded.ptr;
        bitmap._pitch = width * actualComp;
        bitmap._bpp = 8 * actualComp;
        bitmap._type = FIT_BITMAP;
        return bitmap;

    error:
        free(bitmap);

    error2:
        free(decoded.ptr);

        return null;
    }

    void InitProc_JPEG (Plugin *plugin, int format_id)
    {
        assert(format_id == FIF_JPEG);
        plugin.supportsRead = true;
        plugin.supportsWrite = true;
        plugin.loadProc = &Load_JPEG;
        plugin.saveProc = &Save_JPEG;
        plugin.validateProc = &Validate_JPEG;
        plugin.mimeProc = &MIME_JPEG;
    }

    const(char)* MIME_JPEG() @trusted
    {
        return "image/jpeg".ptr;
    }

    bool Validate_JPEG(FreeImageIO *io, fi_handle handle) @trusted
    {
        static immutable ubyte[2] jpegSignature = [0xFF, 0xD8];
        return fileIsStartingWithSignature(io, handle, jpegSignature);
    }

    bool Save_JPEG(FreeImageIO *io, FIBITMAP *dib, fi_handle handle, int page, int flags, void *data) @trusted
    {
        if (page != 0)
            return false;

        if (!FreeImage_HasPixels(dib))
            return false; // no pixel data

        if (dib._type != FIT_BITMAP)
            return false;

        int components;

        switch (dib._bpp)
        {
            case 8:  components = 1; break;
            case 16: return false; // stb would throw away alpha
            case 24: components = 3; break;
            case 32: return false; // stb would throw away alpha
            default:
                return false;
        }

        JPEGIOHandle jio;
        jio.wrapped = io;
        jio.handle = handle;

        void* userPointer = cast(void*)&jio;

        int quality = 90; // TODO: option to choose that.

        int res = stbi_write_jpg_to_func(&stb_stream_write, userPointer, 
                                         dib._width, 
                                         dib._height, 
                                         components, 
                                         dib._data, quality);

        return res == 1 && !jio.errored;
    }

    /// Input stream interface.
    /// This function is called when the internal input buffer is empty.
    /// Parameters:
    ///   pBuf - input buffer
    ///   max_bytes_to_read - maximum bytes that can be written to pBuf
    ///   pEOF_flag - set this to true if at end of stream (no more bytes remaining)
    ///   userData - user context for being used as closure.
    ///   Returns -1 on error, otherwise return the number of bytes actually written to the buffer (which may be 0).
    ///   Notes: This delegate will be called in a loop until you set *pEOF_flag to true or the internal buffer is full.
   // alias JpegStreamReadFunc = int function(void* pBuf, int max_bytes_to_read, bool* pEOF_flag, void* userData);

}

private:


struct JPEGIOHandle
{
    FreeImageIO* wrapped;
    fi_handle handle;

    // stb_image_write doesn't check errors for write, so keep a flag and start ignoring output if
    // an I/O error occurs.
    bool errored = false;
}

/// This function is called when the internal input buffer is empty.
// userData must be a JPEGIOHandle*
int stream_read_jpeg(void* pBuf, int max_bytes_to_read, bool* pEOF_flag, void* userData) @system
{
    JPEGIOHandle* jio = cast(JPEGIOHandle*) userData;
    size_t read = jio.wrapped.read(pBuf, 1, max_bytes_to_read, jio.handle);
    if (pEOF_flag)
    {
        *pEOF_flag = jio.wrapped.eof(jio.handle) != 0;
    }
    assert(read >= 0 && read <= 0x7fff_ffff);
    return cast(int) read;
}

// Note: context is a user pointer on a JPEGIOHandle.
void stb_stream_write(void *context, const(void)* data, int size) @system
{    
    JPEGIOHandle* jio = cast(JPEGIOHandle*) context;

    if (jio.errored)
        return;

    size_t written = jio.wrapped.write(data, 1, size, jio.handle);
    if (written != size)
        jio.errored = true; // poison the JPEGIOHandleB
}