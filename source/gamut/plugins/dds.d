/**
DDS support, containing BC7 encoded textures.

Copyright: Copyright Guillaume Piolat 2022
License:   $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost License 1.0)
*/
module gamut.plugins.dds;

nothrow @nogc @safe:

//port core.stdc.stdlib: malloc, free, realloc;
import core.stdc.string: memset;
import gamut.types;
import gamut.io;
import gamut.image;
import gamut.plugin;
import gamut.internals.errors;

version(encodeDDS)
    import gamut.codecs.bc7enc16;

ImageFormatPlugin makeDDSPlugin()
{
    ImageFormatPlugin p;
    p.format = "DDS";
    p.extensionList = "dds";

    p.mimeTypes = "image/vnd.ms-dds";

    p.loadProc = null;

    version(encodeDDS)
        p.saveProc = &saveDDS;
    else
        p.saveProc = null;
    p.detectProc = &detectDDS;
    return p;
}

bool detectDDS(IOStream *io, IOHandle handle) @trusted
{
    static immutable ubyte[4] ddsSignature = [0x44, 0x44, 0x53, 0x20]; // "DDS "
    return fileIsStartingWithSignature(io, handle, ddsSignature);
}

version(encodeDDS)
bool saveDDS(ref const(Image) image, IOStream *io, IOHandle handle, int page, int flags, void *data) @trusted
{
    if (page != 0)
        return false; 
        
    int channels = 0;

    // The following format are accepted: 8-bit with 1/2/3/4 channels.
    switch (image._type)
    {
        case ImageType.uint8: channels = 1; break;
        case ImageType.la8:   channels = 2; break;
        case ImageType.rgb8:  channels = 3; break;
        case ImageType.rgba8: channels = 4; break;
        default: 
            return false; // not supported
    }

    // Encode to blocks. How many 4x4 block do we need?
    int width = image.width();
    int height = image.height();
    int block_W = (image.width + 3) / 4;
    int block_H = (image.height + 3) / 4;
    int numBlocks = block_W * block_H;


    // 1. Write DDS header and stuff
    {
        char[4] magic = "DDS ";
        if (4 != io.write(magic.ptr, 1, 4, handle))
            return false;

        static uint PIXEL_FMT_FOURCC(ubyte a, ubyte b, ubyte c, ubyte d)
        {
            return ((a) | ((b) << 8U) | ((c) << 16U) | ((d) << 24U));
        }

        DDSURFACEDESC2 desc;
        memset(&desc, 0, desc.sizeof);
        desc.dwSize = desc.sizeof;
        desc.dwFlags = DDSD_WIDTH | DDSD_HEIGHT | DDSD_PIXELFORMAT | DDSD_CAPS;
        desc.dwWidth = width;
        desc.dwHeight = height;
        desc.ddsCaps.dwCaps = DDSCAPS_TEXTURE;
        desc.ddpfPixelFormat.dwSize = (desc.ddpfPixelFormat).sizeof;
        desc.ddpfPixelFormat.dwFlags |= DDPF_FOURCC;
        desc.ddpfPixelFormat.dwFourCC = cast(uint) PIXEL_FMT_FOURCC('D', 'X', '1', '0');
        desc.ddpfPixelFormat.dwRGBBitCount = 0;
        const uint pixel_format_bpp = 8;
        desc.lPitch = (((desc.dwWidth + 3) & ~3) * ((desc.dwHeight + 3) & ~3) * pixel_format_bpp) >> 3;
        desc.dwFlags |= DDSD_LINEARSIZE;

        if (1 != io.write(&desc, desc.sizeof, 1, handle))
            return false;

        DDS_HEADER_DXT10 hdr10;
        memset(&hdr10, 0, hdr10.sizeof);

        // Not all tools support DXGI_FORMAT_BC7_UNORM_SRGB (like NVTT), but ddsview in DirectXTex pays attention to it. So not sure what to do here.
        // For best compatibility just write DXGI_FORMAT_BC7_UNORM.
        //hdr10.dxgiFormat = srgb ? DXGI_FORMAT_BC7_UNORM_SRGB : DXGI_FORMAT_BC7_UNORM;
        hdr10.dxgiFormat = DXGI_FORMAT_BC7_UNORM;
        hdr10.resourceDimension = 3; /* D3D10_RESOURCE_DIMENSION_TEXTURE2D; */
        hdr10.arraySize = 1;

        if (1 != io.write(&hdr10, hdr10.sizeof, 1, handle))
            return false;
    }


    // 2. Write compressed blocks

    bc7enc16_compress_block_init();
    alias bc7_block_t = ubyte[16]; // A 128-bit block containing a 4x4 pixel patch.

    enum bool perceptual = true;

    bc7enc16_compress_block_params pack_params;
    bc7enc16_compress_block_params_init(&pack_params);
    if (!perceptual)
        bc7enc16_compress_block_params_init_linear_weights(&pack_params);

    bool hasAlpha = false;
    
    for (int y = 0; y < block_H; ++y)
    {
        for (int x = 0; x < block_W; ++x)
        {           
            color_quad_u8[16] pixels; // init important, in case dimension not multiple of 4.

            // Read a patch of 4x4 pixels, put it in `pixels`.
            {
                for (int ly = 0; ly < 4; ++ly)
                {
                    if (y*4 + ly < height)
                    {
                        const(ubyte)* line = image.scanline(y*4 + ly);
                        const(ubyte)* pixel = &line[x * 4 * channels];

                        assert(x*4 < width);

                        int avail_x = 4;
                        if (x*4 + 4 > width) 
                            avail_x = width - x*4;

                        switch (channels)
                        {
                            case 1:
                            {
                                for (int lx = 0; lx < avail_x; ++lx)
                                {
                                    color_quad_u8* p = &pixels[lx + ly * 4];
                                    p.m_c[0] = p.m_c[1] = p.m_c[2] = pixel[lx];
                                    p.m_c[3] = 255;
                                }
                                break;
                            }
                            case 2:
                            {
                                for (int lx = 0; lx < avail_x; ++lx)
                                {
                                    color_quad_u8* p = &pixels[lx + ly * 4];
                                    p.m_c[0] = p.m_c[1] = p.m_c[2] = pixel[lx*2];
                                    p.m_c[3] = pixel[lx*2+1];
                                }
                                break;
                            }
                            case 3:
                            {
                                for (int lx = 0; lx < avail_x; ++lx)
                                {
                                    color_quad_u8* p = &pixels[lx + ly * 4];
                                    p.m_c[0] = pixel[lx*3+0];
                                    p.m_c[1] = pixel[lx*3+1];
                                    p.m_c[2] = pixel[lx*3+2];
                                    p.m_c[3] = 255;
                                }
                                break;
                            }
                            case 4:
                            {
                                for (int lx = 0; lx < avail_x; ++lx)
                                {
                                    color_quad_u8* p = &pixels[lx + ly * 4];
                                    p.m_c[0] = pixel[lx*4+0];
                                    p.m_c[1] = pixel[lx*4+1];
                                    p.m_c[2] = pixel[lx*4+2];
                                    p.m_c[3] = pixel[lx*4+3];
                                }
                                break;
                            }
                            default:
                                assert(false);
                        }
                    }
                }
            }

            bc7_block_t block;

            if (bc7enc16_compress_block(block.ptr, pixels.ptr, &pack_params))
                hasAlpha = true; // Note: hasAlpha unused with .dds

            if (1 != io.write(&block, block.sizeof, 1, handle))
                return false;
        }
    }
    
    return true;
}


struct DDCOLORKEY
{
    uint dwUnused0;
    uint dwUnused1;
};

struct DDPIXELFORMAT
{
    uint dwSize;
    uint dwFlags;
    uint dwFourCC;
    uint dwRGBBitCount;     // ATI compressonator will place a FOURCC code here for swizzled/cooked DXTn formats
    uint dwRBitMask;
    uint dwGBitMask;
    uint dwBBitMask;
    uint dwRGBAlphaBitMask;
}

struct DDSCAPS2
{
    uint dwCaps;
    uint dwCaps2;
    uint dwCaps3;
    uint dwCaps4;
}

struct DDSURFACEDESC2
{
    uint dwSize;
    uint dwFlags;
    uint dwHeight;
    uint dwWidth;
    union
    {
        int lPitch;
        uint dwLinearSize;
    }
    uint dwBackBufferCount;
    uint dwMipMapCount;
    uint dwAlphaBitDepth;
    uint dwUnused0;
    uint lpSurface;
    DDCOLORKEY unused0;
    DDCOLORKEY unused1;
    DDCOLORKEY unused2;
    DDCOLORKEY unused3;
    DDPIXELFORMAT ddpfPixelFormat;
    DDSCAPS2 ddsCaps;
    uint dwUnused1;
}

enum uint DDSD_CAPS = 0x00000001;
enum uint DDSD_HEIGHT = 0x00000002;
enum uint DDSD_WIDTH = 0x00000004;
enum uint DDSD_PIXELFORMAT = 0x00001000;
enum uint DDSD_LINEARSIZE = 0x00080000;
enum uint DDPF_FOURCC = 0x00000004;
enum uint DDSCAPS_TEXTURE = 0x00001000;

alias DXGI_FORMAT = int;
enum : DXGI_FORMAT 
{
    DXGI_FORMAT_UNKNOWN = 0,
    DXGI_FORMAT_BC7_UNORM = 98,
    DXGI_FORMAT_BC7_UNORM_SRGB = 99,
}

struct DDS_HEADER_DXT10
{
    DXGI_FORMAT              dxgiFormat;
    int                      resourceDimension;
    uint                     miscFlag;
    uint                     arraySize;
    uint                     miscFlags2;
}

