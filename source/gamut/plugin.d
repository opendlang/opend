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

import gamut.plugins.jpeg;
import gamut.plugins.png;
import gamut.plugins.qoi;

nothrow @nogc @safe:

/// Function that loads a image from this format.
/// I/O rewinding: this function must be given an I/O cursor at the start of the the format.
///                It doesn't have to preserve that I/O cursor.
alias FI_LoadProc = FIBITMAP* function(FreeImageIO *io, fi_handle handle, int page, int flags, void *data);

/// Function that saves an image from this format.
alias FI_SaveProc = bool function(FreeImageIO *io, FIBITMAP *dib, fi_handle handle, int page, int flags, void *data);

/// Function that detects this format.
/// I/O rewinding: this function must preserve the I/O cursor.
alias FI_ValidateProc = bool function(FreeImageIO *io, fi_handle handle);

struct Plugin
{
    /// Type string for the bitmap. For example, a plugin that loads BMPs returns the string "BMP".
    const(char)* format;

    /// Comma-separated list of extension. A JPEG plugin would return "jpeg,jif,jfif".
    const(char)* extensionList;

    /// MIME types, the first one being the best one.
    const(char)* mimeTypes;

    FI_LoadProc loadProc = null; // null => no read supported
    FI_SaveProc saveProc = null; // null => no write supported
    FI_ValidateProc validateProc = null;
}

// ================================================================================================
//
//                                     PLUGIN FUNCTIONS
//
// ================================================================================================

/// This function takes a filename or a file-extension and returns the plugin that can read/write 
/// files with that extension in the form of a `FREE_IMAGE_FORMAT` identifier.
ImageFormat FreeImage_GetFIFFromFilename(const(char) *filename) @trusted
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

    for(ImageFormat fif = ImageFormat.first; fif < FREE_IMAGE_FORMAT_NUM; ++fif)
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
    return ImageFormat.unknown;
}
unittest
{
    import gamut.general;
    FreeImage_Initialise(true);
    assert(FreeImage_GetFIFFromFilename("mysueprduperphoto.jpg") == FIF_JPEG);
    assert(FreeImage_GetFIFFromFilename("mysueprduperphoto.jfif") == FIF_JPEG);
}


/// Returns: `true` if G plugin can load bitmaps.
bool FreeImage_FIFSupportsReading(ImageFormat fif) @trusted
{
    bool supportsRead = g_plugins[fif].loadProc !is null;
    return supportsRead;
}

/// Returns: `true` if the plugin can save bitmaps.
bool FreeImage_FIFSupportsWriting(ImageFormat fif) @trusted
{    
    bool supportsWrite = g_plugins[fif].saveProc !is null;
    return supportsWrite;
}

//
// INTERNALS
//


package:



// For now, all plugin resides in a static __gshared part of the memory.
static immutable __gshared Plugin[ImageFormat.max+1] g_plugins =
[
    makeJPEGPlugin(),
    makePNGPlugin(),
    makeQOIPlugin()
];
