/**
Images suitable to be drawn on a canvas. This is an _undecoded_ image, with metadata extracted.

Copyright: Guillaume Piolat 2018.
License:   $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost License 1.0)
*/
module printed.canvas.image;

import std.exception;
import std.file;
import std.math;
import std.typecons;
import std.base64;
import std.array;

/// Represented an encoded image (JPEG or PNG).
class Image
{
    this(const(char)[] relativePath)
    {
        ubyte[] dataFromFile = cast(ubyte[])( std.file.read(relativePath) );
        // has been allocated, can be assumed unique
        this( assumeUnique(dataFromFile) );
    }

    this(immutable(ubyte)[] data)
    {
        // embed for future use
        _data = data.idup;

        import gamut;

        ImageFormat fmt = gamut.Image.identifyFormatFromMemory(data);
        bool isPNG = (fmt == ImageFormat.PNG);
        bool isJPEG = (fmt == ImageFormat.JPEG);
        if (!isPNG && !isJPEG)
            throw new Exception("Unidentified format");

        gamut.image.Image img;
        img.loadFromMemory(data, LOAD_NO_PIXELS);

        if (img.errored)
            throw new Exception("Can't decode image.");

        _width = img.width();
        _height = img.height();

        if (isPNG) _MIME = "image/png";
        else _MIME = "image/jpeg";

        // Use defaults if missing

        float pixelAspectRatio = img.pixelAspectRatio == GAMUT_UNKNOWN_ASPECT_RATIO ? 1.0 : img.pixelAspectRatio;
        float verticalDPI = img.dotsPerInchY() == GAMUT_UNKNOWN_RESOLUTION ? 1.0 : img.dotsPerInchY;
     
        _pixelsPerMeterX = convertMetersToInches(verticalDPI * pixelAspectRatio);
        _pixelsPerMeterY = convertMetersToInches(verticalDPI);
    }

    string MIME()
    {
        return _MIME;
    }

    string toDataURI()
    {
        string r = "data:";
        r ~= _MIME;
        r ~= ";charset=utf-8;base64,";
        r ~= Base64.encode(_data);
        return r;
    }

    /// Width in pixels.
    int width()
    {
        return _width;
    }

    /// Height in pixels.
    int height()
    {
        return _height;
    }
    
    /// Default width when printed, in mm.
    float printWidth()
    {
        return 1000 * _width / pixelsPerMeterX();
    }

    /// Default height when printed, in mm.
    float printHeight()
    {
        return 1000 * _height / pixelsPerMeterY();
    }

    float pixelsPerMeterX()
    {  
        return _pixelsPerMeterX;
    }

    float pixelsPerMeterY()
    {
        return _pixelsPerMeterY;
    }

    immutable(ubyte)[] encodedData() const
    {
        return _data;
    }

private:

    // Number of horizontal pixels.
    int _width = -1;

    // Number of vertical pixels.
    int _height = -1;

    // DPI and aspect ratio information, critical for print
    float _pixelsPerMeterX = float.nan; // stays NaN if not available
    float _pixelsPerMeterY = float.nan; // stays NaN if not available

    // Encoded data.
    immutable(ubyte)[] _data;

    // Parsed MIME type.
    string _MIME;
}
