/**
General functions.

Copyright: Copyright Guillaume Piolat 2022
License:   $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost License 1.0)

Note: This library is re-implemented in D from FreeImage documentation (FreeImage3180.pdf).
See the differences in DIFFERENCES.md
*/
module gamut.plugin;

import core.stdc.string;
import gamut.types;
import gamut.bitmap;
import gamut.io;
import gamut.internals.mutex;

nothrow @nogc @safe:


/// Note sure how many of those constant I want.
version(decodePNG)
    version = encodeOrDecodePNG;
else version(encodePNG)
    version = encodeOrDecodePNG;

version(decodeQOI)
    version = encodeOrDecodeQOI;
else version(encodeQOI)
    version = encodeOrDecodeQOI;

version(decodeJPEG)
    version = encodeOrDecodeJPEG;
else version(encodeJPEG)
    version = encodeOrDecodeJPEG;

/**
"Through average use you won’t probably notice it, FreeImage is plugin driven. Each bitmap 
loader/saver is in fact a plugin module that is linked inside the integrated plugin manager. 
You won’t notice it, until you decide to write your own plugins.
Almost every plugin in FreeImage is incorporated directly into the DLL. The reason why this is 
done this way is a mixture of evolution and design. The first versions of FreeImage (actually, 
about the whole first year of its existence) it had no notion of plugins. This meant that all 
bitmap functionality was available only from the main DLL. In the second year Floris decided 
to create plugins, because he wanted to support some bitmaps formats that have license 
restrictions on them, such as GIF. In fear that he would put all its bitmap loaders/savers in 
tiny DLLs that would splatter the hard drive, his most important ‘customer’ strongly 
encouraged him to keep as much bitmap formats in one DLL as possible. He took his word 
for it and it lead to the design you see here today.
The actual plugin system evolved from something very simple to a very flexible mechanism 
that he now often reuses in other software. At this moment it’s possible to have plugins in the 
main FREEIMAGE.DLL, in external DLLs, and even directly in an application that drives 
FreeImage."
*/

extern(Windows)
{
    /// Function that initialize a `Plugin` structure.
    alias FI_InitProc = void function (Plugin *plugin, int format_id);


    // <need to be setup by FI_InitProc>

    /// Function that loads a image from this format.
    /// I/O rewinding: this function must be given an I/O cursor at the start of the the format.
    ///                It doesn't have to preserve that I/O cursor.
    alias FI_LoadProc = FIBITMAP* function(FreeImageIO *io, fi_handle handle, int page, int flags, void *data);

    /// Function that saves an image from this format.
    alias FI_SaveProc = bool function(FreeImageIO *io, FIBITMAP *dib, fi_handle handle, int page, int flags, void *data);

    /// Function that detects this format.
    /// I/O rewinding: this function must preserve the I/O cursor.
    alias FI_ValidateProc = bool function(FreeImageIO *io, fi_handle handle);

    /// Function that return a comma-separated list of MIME types.
    /// Example = PNG gives "image/png".
    alias FI_MIMEProc = const(char)* function();

    // </need to be setup by FI_InitProc>
}

// TODO: add usage count, so that a plugin can be unloaded after use in case is it disabled.

struct Plugin
{
    /// A non-registered plugin simply does not exist. Used because internal plugins are
    /// stored statically.
    bool isRegistered = false;

    /// A disabled plugin cannot be used to import and export bitmaps, nor  will it identify 
    /// bitmaps. 
    bool isEnabled = false;

    /// Type string for the bitmap. For example, a plugin that loads BMPs returns the string "BMP".
    const(char)* format;

    /// Descriptive string for the bitmap type. For example, a plugin that loads BMPs may return 
    /// "Windows or OS/2 Bitmap"
    const(char)* description;

    /// Comma-separated list of extension. A JPEG plugin would return "jpeg,jif,jfif".
    const(char)* extensionList;

    /// Regular expression.
    const(char)* regexpr;

    //
    // <TO BE FILLED BY THE FI_InitProc FOR THE FORMAT>
    //

    /// Does this plugin support loading no pixels?
    bool supportsNoPixels = false;

    /// Does this plugin support ICC profiles?
    bool supportsICCProfiles = false;

    FI_LoadProc loadProc = null; // null => no read supported
    FI_SaveProc saveProc = null; // null => no write supported
    FI_ValidateProc validateProc = null;
    FI_MIMEProc mimeProc = null;

    //
    // </TO BE FILLED BY THE FI_InitProc FOR THE FORMAT>
    //
}

// ================================================================================================
//
//                                     PLUGIN FUNCTIONS
//
// ================================================================================================

/// Retrieves the number of `FREE_IMAGE_FORMAT` identifiers being currently registered. In 
/// FreeImage `FREE_IMAGE_FORMAT` became, through evolution, synonymous with plugin.
int FreeImage_GetFIFCount() @trusted
{
    g_pluginMutex.lockLazy();
    scope(exit) g_pluginMutex.unlock();

    int registered = 0;
    for(FREE_IMAGE_FORMAT fif = 0; fif < FREE_IMAGE_FORMAT_NUM; ++fif)
    {
        if (g_plugins[fif].isRegistered)
            registered++;
    }
    return registered;
}

/// Enables or disables a plugin. A disabled plugin cannot be used to import and export bitmaps, 
/// nor will it identify bitmaps. 
/// When called, this function returns the previous plugin state (FI_TRUE / 1 or FI_FALSE / 0), or
/// –1 if the plugin doesn’t exist.
int FreeImage_SetPluginEnabled(FREE_IMAGE_FORMAT fif, bool enable) @trusted
{
    g_pluginMutex.lockLazy();
    scope(exit) g_pluginMutex.unlock();

    bool registered = g_plugins[fif].isRegistered;
    if (!registered)
        return -1; // doesn't exist

    bool wasEnabled = g_plugins[fif].isEnabled;
    g_plugins[fif].isEnabled = enable;
    return wasEnabled ? FI_TRUE : FI_FALSE;
}

/// Returns FI_TRUE when the plugin is enabled, FI_FALSE when the plugin is disabled, -1 otherwise.
int FreeImage_IsPluginEnabled(FREE_IMAGE_FORMAT fif) @trusted
{
    g_pluginMutex.lockLazy();
    scope(exit) g_pluginMutex.unlock();

    bool registered = g_plugins[fif].isRegistered;
    if (!registered)
        return -1; // doesn't exist
    return g_plugins[fif].isEnabled ? FI_TRUE : FI_FALSE;
}


/// This function takes a filename or a file-extension and returns the plugin that can read/write 
/// files with that extension in the form of a `FREE_IMAGE_FORMAT` identifier.
FREE_IMAGE_FORMAT FreeImage_GetFIFFromFilename(const(char) *filename) @trusted
{
    // find extension inside filename
    size_t ilen = strlen(filename);
    size_t pos = ilen;
    assert(filename[pos] == 0);
    while(pos > 0 && filename[pos] != '.')
        pos = pos - 1;
    if (filename[pos] == '.') 
        pos++;

    const(char)* fextension = filename + pos; // ex: "jpg", "png"...

    g_pluginMutex.lockLazy();
    scope(exit) g_pluginMutex.unlock();

    for(FREE_IMAGE_FORMAT fif = 0; fif < FREE_IMAGE_FORMAT_NUM; ++fif)
    {
        if (g_plugins[fif].isRegistered)
        {
            // Is fextension in the list?

            const(char)* str = g_plugins[fif].extensionList;

            while(true)
            {
                const(char)* end = str;
                while (*end != ',' && *end != '\0')
                    end++;
                size_t sublen = end - str;
                if (sublen == 0)
                    break;

                if (strncmp(fextension, str, sublen) == 0)
                    return fif;

                if (*end == '\0') // last extension for this format
                    break;

                str = end + 1;
            }
        }
    }
    return FIF_UNKNOWN;
}
unittest
{
    import gamut.general;
    FreeImage_Initialise(true);
    assert(FreeImage_GetFIFFromFilename("mysueprduperphoto.jpg") == FIF_JPEG);
    assert(FreeImage_GetFIFFromFilename("mysueprduperphoto.jfif") == FIF_JPEG);
}


/// Returns FI_TRUE if the plugin belonging to the given FREE_IMAGE_FORMAT can be used to 
/// load bitmaps, FI_FALSE otherwise.
bool FreeImage_FIFSupportsReading(FREE_IMAGE_FORMAT fif) @trusted
{
    g_pluginMutex.lockLazy();
    scope(exit) g_pluginMutex.unlock();    
    bool registered = g_plugins[fif].isRegistered;
    bool enabled = g_plugins[fif].isEnabled;
    bool supportsRead = g_plugins[fif].loadProc !is null;

    // Note: is being enabled mandatory? Not sure from documentation.
    return registered && enabled && supportsRead;
}

/// Returns TRUE if the plugin belonging to the given FREE_IMAGE_FORMAT can be used to 
/// save bitmaps, FALSE otherwise.
bool FreeImage_FIFSupportsWriting(FREE_IMAGE_FORMAT fif) @trusted
{
    g_pluginMutex.lockLazy();
    scope(exit) g_pluginMutex.unlock();    
    bool registered = g_plugins[fif].isRegistered;
    bool enabled = g_plugins[fif].isEnabled;
    bool supportsWrite = g_plugins[fif].saveProc !is null;

    // Note: is being enabled mandatory? Not sure from documentation.
    return registered && enabled && supportsWrite;
}


/// Registers a new plugin to be used in FreeImage. The plugin is residing directly in the 
/// application driving FreeImage. The first parameter is a pointer to a function that is used to
/// initialise the plugin. The initialization function is responsible for filling in a Plugin 
/// structure and storing a system-assigned format identification number used for message logging.
FREE_IMAGE_FORMAT FreeImage_RegisterLocalPlugin(FI_InitProc proc_address, 
                                                const(char) *format = null, 
                                                const(char) *description = null,
                                                const(char)* extension = null,
                                                const(char)* regexpr = null)
{
    // Custom plugins not supported yet.
    assert(false);
}

//
// INTERNALS
//

package:


// Acquire plugin in a thread-safe manner. Once acquired, the plugin cannot be unloaded/disabled.
// Call `FreeImage_PluginRelease` once done.

// Returns: null if no plugin is registered for this format, or if it is disabled for reading.
Plugin* FreeImage_PluginAcquireForReading(FREE_IMAGE_FORMAT fif) @trusted
{
    g_pluginMutex.lockLazy();
    scope(exit) g_pluginMutex.unlock();
    bool registered = g_plugins[fif].isRegistered;
    bool enabled = g_plugins[fif].isEnabled;
    bool supportsRead = g_plugins[fif].loadProc !is null;
    
    if ( !(registered && enabled && supportsRead) )
        return null;

    // TODO: actually do something for atomicity.
    return &g_plugins[fif];
}

Plugin* FreeImage_PluginAcquireForWriting(FREE_IMAGE_FORMAT fif) @trusted
{
    g_pluginMutex.lockLazy();
    scope(exit) g_pluginMutex.unlock();
    bool registered = g_plugins[fif].isRegistered;
    bool enabled = g_plugins[fif].isEnabled;
    bool supportsWrite = g_plugins[fif].saveProc !is null;

    if ( !(registered && enabled && supportsWrite) )
        return null;

    // TODO: actually do something for atomicity.
    return &g_plugins[fif];
}

// Return 0 if properly release. assert(false) else, as it is a programming error.
int FreeImage_PluginRelease(Plugin* plugin)
{
    // TODO: have a counter and use it.
    return 0;
}


// Register one internal format.
package void FreeImage_RegisterInternalPlugin(FREE_IMAGE_FORMAT fif,
                                              FI_InitProc proc,
                                              const(char)* format = null, 
                                              const(char)* description = null,
                                              const(char)* extension = null,
                                              const(char)* regexpr = null) @trusted
{
    g_pluginMutex.lockLazy();
    scope(exit) g_pluginMutex.unlock();
    Plugin* p = &g_plugins[fif];
    proc(p, fif);

    // Begin its life enabled, and registered.
    p.isEnabled = true;
    p.isRegistered = true;

    p.format = format;
    p.description = description;
    p.extensionList = extension;
    p.regexpr = regexpr;
}

package void FreeImage_registerInternalPlugins()
{
    version(encodeOrDecodePNG)
    {
        import gamut.plugins.png;
        registerPNG();
    }

    version(encodeOrDecodeJPEG)
    {
        import gamut.plugins.jpeg;
        registerJPEG();
    }

    version(encodeOrDecodeQOI)
    {
        import gamut.plugins.qoi;
        registerQOI();
    }
}


private:


// For now, all plugin resides in a static __gshared part of the memory.
__gshared Plugin[FREE_IMAGE_FORMAT_NUM] g_plugins;

__gshared Mutex g_pluginMutex; // protects g_plugins



