/**
General functions.

Copyright: Copyright Guillaume Piolat 2022
License:   $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost License 1.0)
*/
module gamut.plugin;

import gamut.types;
import gamut.bitmap;
import gamut.io;
import gamut.internals.mutex;

nothrow @nogc @safe:

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

    /// Function that loads a image from this format.
    alias FI_LoadProc = FIBITMAP* function(FreeImageIO *io, fi_handle handle, int page, int flags, void *data);

    /// Function that saves an image from this format.
    alias FI_SaveProc = bool function(FreeImageIO *io, FIBITMAP *dib, fi_handle handle, int page, int flags, void *data);

    /// Function that detects this format.
    alias FI_ValidateProc = bool function(FreeImageIO *io, fi_handle handle);
}


struct Plugin
{
    /// A non-registered plugin simply does not exist. Used because internal plugins are
    /// stored statically.
    bool isRegistered = false;

    /// A disabled plugin cannot be used to import and export bitmaps, nor  will it identify 
    /// bitmaps. 
    bool isEnabled = false;

    bool supportsRead = false;
    bool supportsWrite = false;    
    bool supportsNoPixels = false;
    bool supportsICCProfiles = false;

    /// Type string for the bitmap. For example, a plugin that loads BMPs returns the string "BMP".
    const(char)* format;

    /// Descriptive string for the bitmap type. For example, a plugin that loads BMPs may return 
    /// "Windows or OS/2 Bitmap"
    const(char)* description;

    /// Comma-separated list of extension. A JPEG plugin would return "jpeg,jif,jfif".
    const(char)* extensionList;

    /// Comma-separated list of MIME types for the plugin. Example = PNG gives "image/png".
    const(char)* mimeTypes;
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
    for(FREE_IMAGE_FORMAT fif = 0; fif <= FREE_IMAGE_FORMAT.max; ++fif)
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

/// Returns FI_TRUE if the plugin belonging to the given FREE_IMAGE_FORMAT can be used to 
/// load bitmaps, FI_FALSE otherwise.
bool FreeImage_FIFSupportsReading(FREE_IMAGE_FORMAT fif) @trusted
{
    g_pluginMutex.lockLazy();
    scope(exit) g_pluginMutex.unlock();    
    bool registered = g_plugins[fif].isRegistered;
    bool enabled = g_plugins[fif].isEnabled;
    bool supportsRead = g_plugins[fif].supportsRead;

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
    bool supportsWrite = g_plugins[fif].supportsWrite;

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

private:

// For now, all plugin resides in a static __gshared part of the memory.
__gshared Plugin[FIF_TIFF.max] g_plugins;

__gshared Mutex g_pluginMutex; // protects g_plugins

// Register one internal format.
void FreeImage_RegisterInternalPlugin(FREE_IMAGE_FORMAT fif,
                                      FI_InitProc proc,
                                      const(char) *format = null, 
                                      const(char) *description = null,
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
}

package void FreeImage_registerInternalPlugins()
{
    FreeImage_RegisterInternalPlugin(FIF_PNG,
                                     &InitProc_PNG,
                                     null,
                                     null,
                                     null,
                                     null);

    //FIF_BMP     =  0, /// Windows or OS/2 Bitmap File (*.BMP)
        //FIF_GIF     =  1, /// Graphics Interchange Format (*.GIF)
        //FIF_JPEG    =  2, /// Independent JPEG Group (*.JPG, *.JIF, *.JPEG, *.JPE)
        //FIF_PNG     =  3, /// Portable Network Graphics (*.PNG)
        //FIF_TIFF    =  4, /// Tagged Image File Format (*.TIF, *.TIFF)
}

extern(Windows)
{

void InitProc_BMP (Plugin *plugin, int format_id)
{
    assert(format_id == FIF_BMP);
}

void InitProc_GIF (Plugin *plugin, int format_id)
{
    assert(format_id == FIF_GIF);
}

void InitProc_JPEG (Plugin *plugin, int format_id)
{
    assert(format_id == FIF_JPEG);
}

void InitProc_PNG (Plugin *plugin, int format_id)
{
    assert(format_id == FIF_PNG);
    plugin.supportsRead = true;    
}

void InitProc_TIFF (Plugin *plugin, int format_id)
{
    assert(format_id == FIF_TIFF);
}

}

