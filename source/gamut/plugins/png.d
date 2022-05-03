module gamut.plugins.png;

nothrow @nogc @safe:

import gamut.types;
import gamut.bitmap;
import gamut.io;
import gamut.plugin;

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
    FIBITMAP* Load_PNG(FreeImageIO *io, fi_handle handle, int page, int flags, void *data)
    {
        // TODO
        return null;
    }

    void InitProc_PNG (Plugin *plugin, int format_id)
    {
        assert(format_id == FIF_PNG);
        plugin.supportsRead = true;    

        plugin.loadProc = &Load_PNG;
        plugin.saveProc = null;
        plugin.validateProc = null;
        plugin.mimeProc = &MIME_PNG;
    }

    const(char)* MIME_PNG() @trusted
    {
        return "image/png".ptr;
    }

}

