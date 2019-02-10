/**
Images suitable to be drawn on a canvas. This is an _undecoded_ image, with metadata extracted.

Copyright: Guillaume Piolat 2018.
License:   $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost License 1.0)
*/
module printed.image.image;

import std.exception;
import std.file;
import std.math;
import std.typecons;
import std.base64;
import std.array;

import binrange;

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

        bool isPNG = _data.length >= 8 && (_data[0..8] == pngSignature);
        bool isJPEG = (_data.length >= 2) && (_data[0] == 0xff) && (_data[1] == 0xd8);

        if (isPNG)
        {
            _MIME = "image/png";
            readPNGMetadata(_data, _width, _height, _pixelsPerMeterX, _pixelsPerMeterY);
        }
        else if (isJPEG)
        {
            _MIME = "image/jpeg";
        }
        else
            throw new Exception("Only JPEG and PNG are supported for now");
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
        return _width;
    }

    float pixelsPerMeterX()
    {
        if (isNaN(_pixelsPerMeterX))
            return defaultDPI;
        else
            return _pixelsPerMeterX;
    }

    float pixelsPerMeterY()
    {
        if (isNaN(_pixelsPerMeterY))
            return defaultDPI;
        else
            return _pixelsPerMeterY;
    }

    immutable(ubyte)[] encodedData() const
    {
        return _data;
    }

private:

    // Number of horizontal pixels.
    int _width;

    // Number of vertical pixels.
    int _height;

    // DPI and aspect ratio information, critical for print
    float _pixelsPerMeterX; // NaN is not available
    float _pixelsPerMeterY; // NaN is not available

    // Encoded data.
    immutable(ubyte)[] _data;

    // Parsed MIME type.
    string _MIME;
}

private:

// Default to 72 ppi if missing
// This is the default ppi GIMP uses when saving PNG.
static immutable defaultDPI = convertMetersToInches(72);

double convertMetersToInches(double x)
{
    return x * 39.37007874;
}

double convertInchesToMeters(double x)
{
    return x / 39.37007874;
}

static immutable ubyte[8] pngSignature = [0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a];

void readPNGMetadata(immutable(ubyte)[] data, out int width, out int height, out float pixelsPerMeterX, out float pixelsPerMeterY)
{
    width = -1;
    height = -1;
    pixelsPerMeterX = float.nan;
    pixelsPerMeterY = float.nan;

    data.skipBytes(8);

    while (!data.empty)
    {
        uint chunkLen = popBE!uint(data);
        uint chunkType = popBE!uint(data);        

        switch (chunkType)
        {
            case 0x49484452: // 'IHDR'
                width = popBE!int(data);
                height = popBE!int(data);
                data.skipBytes(5);
                break;

            case 0x70485973: // 'pHYs'
                int pixelsPerUnitX = popBE!int(data);
                int pixelsPerUnitY = popBE!int(data);
                ubyte unit = popBE!ubyte(data);
                if (unit == 1)
                {
                    pixelsPerMeterX = pixelsPerUnitX;
                    pixelsPerMeterY = pixelsPerUnitY;
                }
                else
                {
                    // assume default DPI, but keep aspect ratio
                    pixelsPerMeterX = defaultDPI;
                    pixelsPerMeterY = (pixelsPerUnitY/cast(double)pixelsPerUnitX) * pixelsPerMeterX;
                }
                break;

            default:
                data.skipBytes(chunkLen);
        }

        popBE!uint(data); // skip CRC
    }
}
