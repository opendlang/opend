/**
General functions.

Copyright: Copyright Guillaume Piolat 2022
License:   $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost License 1.0)
*/
module gamut.plugin;

import gamut.types;

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

struct Plugin
{
    bool supportsRead = false;
    bool supportsWrite = false;
    bool isRegistered = false;
    bool supportsNoPixels = false;
    bool supportsICCProfiles = false;

}

/// Function that initialize a `Plugin` structure.
alias FI_InitProc = void function (Plugin *plugin, int format_id);


// ================================================================================================
//
//                                     PLUGIN FUNCTIONS
//
// ================================================================================================

/**
Retrieves the number of `FREE_IMAGE_FORMAT` identifiers being currently registered. In 
FreeImage `FREE_IMAGE_FORMAT` became, through evolution, synonymous with plugin.
*/
int FreeImage_GetFIFCount() @trusted
{
    int registered = 0;
    for(FREE_IMAGE_FORMAT fif = 0; fif <= FREE_IMAGE_FORMAT.max; ++fif)
    {
        // TODO: race here
        if (g_plugins[fif].isRegistered)
            registered++;
    }
    return registered;
}


/**
Registers a new plugin to be used in FreeImage. The plugin is residing directly in the 
application driving FreeImage. The first parameter is a pointer to a function that is used to 
initialise the plugin. The initialization function is responsible for filling in a Plugin structure and 
storing a system-assigned format identification number used for message logging.
*/
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

// Register one internal format.
// Warning! Race condition on g_plugins.
void FreeImage_RegisterInternalPlugin(FREE_IMAGE_FORMAT fif,
                                      FI_InitProc proc,
                                      const(char) *format = null, 
                                      const(char) *description = null,
                                      const(char)* extension = null,
                                      const(char)* regexpr = null) @trusted
{
    Plugin* p = &g_plugins[fif];
    proc(p, fif);
}

void FreeImage_internalInitializePlugins()
{
    //FreeImage_RegisterInternalPlugin(

    //FIF_BMP     =  0, /// Windows or OS/2 Bitmap File (*.BMP)
        //FIF_GIF     =  1, /// Graphics Interchange Format (*.GIF)
        //FIF_JPEG    =  2, /// Independent JPEG Group (*.JPG, *.JIF, *.JPEG, *.JPE)
        //FIF_PNG     =  3, /// Portable Network Graphics (*.PNG)
        //FIF_TIFF    =  4, /// Tagged Image File Format (*.TIF, *.TIFF)
}


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
}

void InitProc_TIFF (Plugin *plugin, int format_id)
{
    assert(format_id == FIF_TIFF);
}

