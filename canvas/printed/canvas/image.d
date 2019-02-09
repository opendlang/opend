/**
Images suitable to be drawn on a canvas.

Copyright: Guillaume Piolat 2018.
License:   $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost License 1.0)
*/
module printed.canvas.image;

import std.file;
import std.typecons;
import std.base64;

import imageformats;

/// Represented an encoded image (JPEG or PNG).
class Image
{
    this(const(char)[] relativePath)
    {
        // embed all data for future use
        _data = cast(ubyte[]) std.file.read(relativePath);

        static immutable ubyte[8] pngSignature = [0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a];
        bool isPNG = _data.length >= 8 && (_data[0..8] == pngSignature);
        bool isJPEG = (_data.length >= 2) && (_data[0] == 0xff) && (_data[1] == 0xd8);

        if (isPNG)
        {
            _MIME = "image/png";
        }
        else if (isJPEG)
        {
            _MIME = "image/jpeg";
        }
        else
            throw new Exception("Only JPEG and PNG are supported for now");

        int chans;
        read_image_info(relativePath, _width, _height, chans);
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
        // TODO: read DPI information from file        

        // default to 72 ppi
        return 39.3701 * 72;        
    }

    float pixelsPerMeterY()
    {
        /// TODO: read DPI information from file

        // default to 72 ppi
        return 39.3701 * 72;        
    }

private:
    int _width;
    int _height;    
    ubyte[] _data;
    string _MIME;
}
