/**
General functions.

Copyright: Copyright Guillaume Piolat 2022
License:   $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost License 1.0)
*/
module gamut.plugin;

import core.stdc.string;
import gamut.types;
import gamut.image;
import gamut.io;

import gamut.plugins.jpeg;
import gamut.plugins.png;
import gamut.plugins.qoi;
import gamut.plugins.qoix;
import gamut.plugins.dds;

nothrow @nogc @safe:

/// Function that loads a image from this format.
/// I/O rewinding: this function must be given an I/O cursor at the start of the the format.
///                It doesn't have to preserve that I/O cursor.
alias LoadImageProc = void function(ref Image image, IOStream *io, IOHandle handle, int page, int flags, void *data);

/// Saves an image from this format.
alias SaveImageProc = bool function(ref const(Image) image, IOStream *io, IOHandle handle, int page, int flags, void *data);

/// Function that detects this format.
/// I/O rewinding: this function must preserve the I/O cursor by contract.
alias DetectImageFormatProc = bool function(IOStream *io, IOHandle handle);

struct ImageFormatPlugin
{
    /// Type string for the bitmap. For example, a plugin that loads BMPs returns the string "BMP".
    const(char)* format;

    /// Comma-separated list of extension. A JPEG plugin would return "jpeg,jif,jfif".
    const(char)* extensionList;

    /// MIME types, the first one being the best one.
    const(char)* mimeTypes;

    LoadImageProc loadProc = null; // null => no read supported
    SaveImageProc saveProc = null; // null => no write supported
    DetectImageFormatProc detectProc = null;
}

ImageFormat identifyImageFormatFromFilename(const(char) *filename) @trusted
{
    if (filename is null)
        return ImageFormat.unknown;

    // find extension inside filename
    size_t ilen = strlen(filename);
    size_t pos = ilen;
    assert(filename[pos] == 0);
    while(pos > 0 && filename[pos] != '.')
        pos = pos - 1;
    if (filename[pos] == '.') 
        pos++;

    const(char)* fextension = filename + pos; // ex: "jpg", "png"...

    for(ImageFormat fif = ImageFormat.first; fif <= ImageFormat.max; ++fif)
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
    assert(identifyImageFormatFromFilename("mysueprduperphoto.jpg") == ImageFormat.JPEG);
    assert(identifyImageFormatFromFilename("mysueprduperphoto.jfif") == ImageFormat.JPEG);
}

package:



// For now, all plugin resides in a static __gshared part of the memory.
static immutable __gshared ImageFormatPlugin[ImageFormat.max+1] g_plugins =
[
    makeJPEGPlugin(),
    makePNGPlugin(),
    makeQOIPlugin(),
    makeQOIXPlugin(),
    makeDDSPlugin(),
];
