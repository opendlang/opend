/**
Bridge FreeImage and QOI codec.

Copyright: Copyright Guillaume Piolat 2022
License:   $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost License 1.0)

Note: This library is re-implemented in D from FreeImage documentation (FreeImage3180.pdf).
See the differences in DIFFERENCES.md
*/
module gamut.plugins.qoi;

nothrow @nogc @safe:

import core.stdc.stdlib: malloc, free, realloc;
import gamut.types;
import gamut.bitmap;
import gamut.io;
import gamut.plugin;
import gamut.codecs.qoi;

void registerQOI() @trusted
{
    FreeImage_RegisterInternalPlugin(FIF_QOI, &InitProc_QOI,
                                     "QOI".ptr,
                                     "Quite OK Image format".ptr,
                                     "qoi".ptr,
                                     null);
}

extern(Windows)
{
    FIBITMAP* Load_QOI(FreeImageIO *io, fi_handle handle, int page, int flags, void *data) @trusted
    {
        // Read all available bytes from input
        // PERF: qoi_decode should understand FreeImageIO directly.
        // This is temporary.

        // Find length of input
        if (io.seek(handle, 0, SEEK_END) != 0)
            return null;

        int len = io.tell(handle);

        if (!io.rewind(handle))
            return null;

        ubyte* buf = cast(ubyte*) malloc(len);
        if (buf is null)
            return null;

        FIBITMAP* bitmap = null;
        ubyte* decoded;
        qoi_desc desc;

        // read all input at once.
        if (len != io.read(buf, 1, len, handle))
            goto error;
        
        decoded = cast(ubyte*) qoi_decode(buf, len, &desc, 0);
        if (decoded is null)
            goto error;        

        if (desc.width > GAMUT_MAX_WIDTH || desc.height > GAMUT_MAX_HEIGHT)
            goto error2;

        // TODO: support desc.colorspace information

        bitmap = cast(FIBITMAP*) malloc(FIBITMAP.sizeof);
        if (!bitmap) 
            goto error2;

        bitmap._data = decoded;
        bitmap._width = desc.width;
        bitmap._height = desc.height;
        
        bitmap._type = FIT_BITMAP;
        if (desc.channels == 3)
            bitmap._bpp = 24;
        else if (desc.channels == 4)
            bitmap._bpp = 32;
        else
            goto error3;

        bitmap._pitch = desc.channels * desc.width;
        return bitmap;

        error3:
            free(bitmap);
    
        error2:
            free(decoded);

        error:
            free(buf);
            return null;
    }

    void InitProc_QOI (Plugin *plugin, int format_id)
    {
        assert(format_id == FIF_QOI);
        plugin.supportsRead = true;
        plugin.supportsWrite = false;

        plugin.loadProc = &Load_QOI;
        plugin.saveProc = &Save_QOI;
        plugin.validateProc = &Validate_QOI;
        plugin.mimeProc = &MIME_QOI;
    }

    const(char)* MIME_QOI() @trusted
    {
        return "image/qoi".ptr; // TODO: proper MIME
    }

    bool Validate_QOI(FreeImageIO *io, fi_handle handle) @trusted
    {
        static immutable ubyte[4] qoiSignature = [0x71, 0x6f, 0x69, 0x66]; // "qoif"
        return fileIsStartingWithSignature(io, handle, qoiSignature);
    }

    bool Save_QOI(FreeImageIO *io, FIBITMAP *dib, fi_handle handle, int page, int flags, void *data) @trusted
    {
        assert(false);
        // TODO
    }
}
