module gamut.plugins.jpeg;

nothrow @nogc @safe:

import core.stdc.stdlib: malloc, free, realloc;
import gamut.types;
import gamut.bitmap;
import gamut.io;
import gamut.plugin;
import gamut.codecs.jpegload;

void registerJPEG() @trusted
{
    FreeImage_RegisterInternalPlugin(FIF_JPEG, &InitProc_JPEG,
                                     "JPEG".ptr,
                                     "Independent JPEG Group".ptr,
                                     "jpeg,jif,jfif".ptr,
                                     null);
}

extern(Windows)
{
    FIBITMAP* Load_JPEG(FreeImageIO *io, fi_handle handle, int page, int flags, void *data) @trusted
    {
        // TODO: a way to decompress JPEG directly to RGBA8?
        // TODO: grayscale JPEG.
        // TODO: do NOT mandata a particular channel number. Just respect original content.

        JPEGIOHandle jio;
        jio.wrapped = io;
        jio.handle = handle;

        int requestedComp = 3;
        int width, height, actualComp;
        ubyte[] decoded = decompress_jpeg_image_from_stream(&stream_read_jpeg, &jio, width, height, actualComp, requestedComp);
        if (decoded is null)
            return null;

        FIBITMAP* bitmap = cast(FIBITMAP*) malloc(FIBITMAP.sizeof);
        if (!bitmap) 
            return null;

        bitmap._width = width;
        bitmap._height = height;
        bitmap._data = decoded.ptr;
        bitmap._bpp = 8 * requestedComp;
        bitmap._type = FIT_BITMAP;
        return bitmap;

        error:
            free(bitmap);
        return null;
    }

    void InitProc_JPEG (Plugin *plugin, int format_id)
    {
        assert(format_id == FIF_JPEG);
        plugin.supportsRead = true;    

        plugin.loadProc = &Load_JPEG;
        plugin.saveProc = null;
        plugin.validateProc = null;
        plugin.mimeProc = &MIME_JPEG;
    }

    const(char)* MIME_JPEG() @trusted
    {
        return "image/jpeg".ptr;
    }

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
    alias JpegStreamReadFunc = int function(void* pBuf, int max_bytes_to_read, bool* pEOF_flag, void* userData);

private:


struct JPEGIOHandle
{
    FreeImageIO* wrapped;
    fi_handle handle;
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