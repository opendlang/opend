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
            parsePNGMetadata(_data, _width, _height, _pixelsPerMeterX, _pixelsPerMeterY);
        }
        else if (isJPEG)
        {
            _MIME = "image/jpeg";
            parseJPEGMetadata(_data, _width, _height, _pixelsPerMeterX, _pixelsPerMeterY);
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

void parsePNGMetadata(immutable(ubyte)[] data, out int width, out int height, out float pixelsPerMeterX, out float pixelsPerMeterY)
{
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
                return; // we're done here

            default:
                data.skipBytes(chunkLen);
        }

        popBE!uint(data); // skip CRC
    }
}

void parseJPEGMetadata(immutable(ubyte)[] data, out int width, out int height, out float pixelsPerMeterX, out float pixelsPerMeterY)
{
    int actual_comp;
    extract_jpeg_metadata(data, width, height, pixelsPerMeterX, pixelsPerMeterY);
}

// Below: a stripped down JPEG decoder for metadata only


// jpgd.h - C++ class for JPEG decompression.
// Rich Geldreich <richgel99@gmail.com>
// Alex Evans: Linear memory allocator (taken from jpge.h).
// v1.04, May. 19, 2012: Code tweaks to fix VS2008 static code analysis warnings (all looked harmless)
// D translation by Ketmar // Invisible Vector
//
// This is free and unencumbered software released into the public domain.
//
// Anyone is free to copy, modify, publish, use, compile, sell, or
// distribute this software, either in source code form or as a compiled
// binary, for any purpose, commercial or non-commercial, and by any
// means.
//
// In jurisdictions that recognize copyright laws, the author or authors
// of this software dedicate any and all copyright interest in the
// software to the public domain. We make this dedication for the benefit
// of the public at large and to the detriment of our heirs and
// successors. We intend this dedication to be an overt act of
// relinquishment in perpetuity of all present and future rights to this
// software under copyright law.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
// EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
// MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
// IN NO EVENT SHALL THE AUTHORS BE LIABLE FOR ANY CLAIM, DAMAGES OR
// OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
// ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
// OTHER DEALINGS IN THE SOFTWARE.
//
// For more information, please refer to <http://unlicense.org/>
//
// Supports progressive and baseline sequential JPEG image files, and the most common chroma subsampling factors: Y, H1V1, H2V1, H1V2, and H2V2.
//
// Chroma upsampling quality: H2V2 is upsampled in the frequency domain, H2V1 and H1V2 are upsampled using point sampling.
// Chroma upsampling reference: "Fast Scheme for Image Size Change in the Compressed Domain"
// http://vision.ai.uiuc.edu/~dugad/research/dct/index.html
/**
* Loads a JPEG image from a memory buffer or a file.
* req_comps can be 1 (grayscale), 3 (RGB), or 4 (RGBA).
* On return, width/height will be set to the image's dimensions, and actual_comps will be set to the either 1 (grayscale) or 3 (RGB).
* Requesting a 8 or 32bpp image is currently a little faster than 24bpp because the jpeg_decoder class itself currently always unpacks to either 8 or 32bpp.
*/
/// JPEG image loading.


/// Input stream interface.
/// This delegate is called when the internal input buffer is empty.
/// Parameters:
///   pBuf - input buffer
///   max_bytes_to_read - maximum bytes that can be written to pBuf
///   pEOF_flag - set this to true if at end of stream (no more bytes remaining)
///   Returns -1 on error, otherwise return the number of bytes actually written to the buffer (which may be 0).
///   Notes: This delegate will be called in a loop until you set *pEOF_flag to true or the internal buffer is full.
alias JpegStreamReadFunc = int delegate (void* pBuf, int max_bytes_to_read, bool* pEOF_flag);


// ////////////////////////////////////////////////////////////////////////// //
private:

import core.stdc.stdlib: malloc, free;

alias jpgd_malloc = malloc;
alias jpgd_free = free;

// Success/failure error codes.
alias jpgd_status = int;
enum /*jpgd_status*/ {
    JPGD_SUCCESS = 0, JPGD_FAILED = -1, JPGD_DONE = 1,
    JPGD_BAD_DHT_COUNTS = -256, JPGD_BAD_DHT_INDEX, JPGD_BAD_DHT_MARKER, JPGD_BAD_DQT_MARKER, JPGD_BAD_DQT_TABLE,
    JPGD_BAD_PRECISION, JPGD_BAD_HEIGHT, JPGD_BAD_WIDTH, JPGD_TOO_MANY_COMPONENTS,
    JPGD_BAD_SOF_LENGTH, JPGD_BAD_VARIABLE_MARKER, JPGD_BAD_DRI_LENGTH, JPGD_BAD_SOS_LENGTH,
    JPGD_BAD_SOS_COMP_ID, JPGD_W_EXTRA_BYTES_BEFORE_MARKER, JPGD_NO_ARITHMITIC_SUPPORT, JPGD_UNEXPECTED_MARKER,
    JPGD_NOT_JPEG, JPGD_UNSUPPORTED_MARKER, JPGD_BAD_DQT_LENGTH, JPGD_TOO_MANY_BLOCKS,
    JPGD_UNDEFINED_QUANT_TABLE, JPGD_UNDEFINED_HUFF_TABLE, JPGD_NOT_SINGLE_SCAN, JPGD_UNSUPPORTED_COLORSPACE,
    JPGD_UNSUPPORTED_SAMP_FACTORS, JPGD_DECODE_ERROR, JPGD_BAD_RESTART_MARKER, JPGD_ASSERTION_ERROR,
    JPGD_BAD_SOS_SPECTRAL, JPGD_BAD_SOS_SUCCESSIVE, JPGD_STREAM_READ, JPGD_NOTENOUGHMEM,
}

enum {
    JPGD_IN_BUF_SIZE = 8192, JPGD_MAX_BLOCKS_PER_MCU = 10, JPGD_MAX_HUFF_TABLES = 8, JPGD_MAX_QUANT_TABLES = 4,
    JPGD_MAX_COMPONENTS = 4, JPGD_MAX_COMPS_IN_SCAN = 4, JPGD_MAX_BLOCKS_PER_ROW = 8192, JPGD_MAX_HEIGHT = 16384, JPGD_MAX_WIDTH = 16384,
}

alias JPEG_MARKER = int;
enum /*JPEG_MARKER*/ {
    M_SOF0  = 0xC0, M_SOF1  = 0xC1, M_SOF2  = 0xC2, M_SOF3  = 0xC3, M_SOF5  = 0xC5, M_SOF6  = 0xC6, M_SOF7  = 0xC7, M_JPG   = 0xC8,
    M_SOF9  = 0xC9, M_SOF10 = 0xCA, M_SOF11 = 0xCB, M_SOF13 = 0xCD, M_SOF14 = 0xCE, M_SOF15 = 0xCF, M_DHT   = 0xC4, M_DAC   = 0xCC,
    M_RST0  = 0xD0, M_RST1  = 0xD1, M_RST2  = 0xD2, M_RST3  = 0xD3, M_RST4  = 0xD4, M_RST5  = 0xD5, M_RST6  = 0xD6, M_RST7  = 0xD7,
    M_SOI   = 0xD8, M_EOI   = 0xD9, M_SOS   = 0xDA, M_DQT   = 0xDB, M_DNL   = 0xDC, M_DRI   = 0xDD, M_DHP   = 0xDE, M_EXP   = 0xDF,
    M_APP0  = 0xE0, M_APP15 = 0xEF, M_JPG0  = 0xF0, M_JPG13 = 0xFD, M_COM   = 0xFE, M_TEM   = 0x01, M_ERROR = 0x100, RST0   = 0xD0,
}

struct jpeg_decoder {

    private import core.stdc.string : memcpy, memset;
private:

    alias jpgd_quant_t = short;
    alias jpgd_block_t = short;
    alias pDecode_block_func = void function (ref jpeg_decoder, int, int, int);

    static struct coeff_buf {
        ubyte* pData;
        int block_num_x, block_num_y;
        int block_len_x, block_len_y;
        int block_size;
    }

    int m_image_x_size;
    int m_image_y_size;
    JpegStreamReadFunc readfn;
    jpgd_quant_t*[JPGD_MAX_QUANT_TABLES] m_quant; // pointer to quantization tables
    int m_comps_in_frame;                         // # of components in frame
    int[JPGD_MAX_COMPONENTS] m_comp_ident;        // component's ID
    int[JPGD_MAX_COMPONENTS] m_comp_h_blocks;
    int[JPGD_MAX_COMPONENTS] m_comp_v_blocks;
    int m_comps_in_scan;                          // # of components in scan
    int[JPGD_MAX_COMPS_IN_SCAN] m_comp_list;      // components in this scan
    int[JPGD_MAX_COMPONENTS] m_comp_dc_tab;       // component's DC Huffman coding table selector
    int[JPGD_MAX_COMPONENTS] m_comp_ac_tab;       // component's AC Huffman coding table selector
    int m_blocks_per_mcu;
    int m_max_blocks_per_row;
    int m_mcus_per_row, m_mcus_per_col;
    int[JPGD_MAX_BLOCKS_PER_MCU] m_mcu_org;
    int m_total_lines_left;                       // total # lines left in image
    int m_mcu_lines_left;                         // total # lines left in this MCU
    int m_real_dest_bytes_per_scan_line;
    int m_dest_bytes_per_scan_line;               // rounded up
    int m_dest_bytes_per_pixel;                   // 4 (RGB) or 1 (Y)
    int m_eob_run;
    int[JPGD_MAX_COMPONENTS] m_block_y_mcu;
    ubyte* m_pIn_buf_ofs;
    int m_in_buf_left;
    int m_tem_flag;
    bool m_eof_flag;
    ubyte[128] m_in_buf_pad_start;
    ubyte[JPGD_IN_BUF_SIZE+128] m_in_buf;
    ubyte[128] m_in_buf_pad_end;
    int m_bits_left;
    uint m_bit_buf;
    int m_restart_interval;
    int m_restarts_left;
    int m_next_restart_num;
    int m_max_mcus_per_row;
    int m_max_blocks_per_mcu;
    int m_expanded_blocks_per_mcu;
    int m_expanded_blocks_per_row;
    int m_expanded_blocks_per_component;
    bool m_freq_domain_chroma_upsample;
    int m_max_mcus_per_col;
    uint[JPGD_MAX_COMPONENTS] m_last_dc_val;
    jpgd_block_t* m_pMCU_coefficients;
    ubyte* m_pSample_buf;
    int[256] m_crr;
    int[256] m_cbb;
    int[256] m_crg;
    int[256] m_cbg;
    ubyte* m_pScan_line_0;
    ubyte* m_pScan_line_1;
    jpgd_status m_error_code;

    float m_pixelsPerMeterX, m_pixelsPerMeterY;


public:
    // Inspect `error_code` after constructing to determine if the stream is valid or not. You may look at the `width`, `height`, etc.
    // methods after the constructor is called. You may then either destruct the object, or begin decoding the image by calling begin_decoding(), then decode() on each scanline.
    this (JpegStreamReadFunc rfn) 
    {
        initit(rfn);
        locate_sof_marker();
    }

    jpgd_status error_code () { return m_error_code; }

private:
    // Retrieve one character from the input stream.
    uint get_char () {
        // Any bytes remaining in buffer?
        if (!m_in_buf_left) {
            // Try to get more bytes.
            prep_in_buffer();
            // Still nothing to get?
            if (!m_in_buf_left) {
                // Pad the end of the stream with 0xFF 0xD9 (EOI marker)
                int t = m_tem_flag;
                m_tem_flag ^= 1;
                return (t ? 0xD9 : 0xFF);
            }
        }
        uint c = *m_pIn_buf_ofs++;
        --m_in_buf_left;
        return c;
    }

    // Same as previous method, except can indicate if the character is a pad character or not.
    uint get_char (bool* pPadding_flag) {
        if (!m_in_buf_left) {
            prep_in_buffer();
            if (!m_in_buf_left) {
                *pPadding_flag = true;
                int t = m_tem_flag;
                m_tem_flag ^= 1;
                return (t ? 0xD9 : 0xFF);
            }
        }
        *pPadding_flag = false;
        uint c = *m_pIn_buf_ofs++;
        --m_in_buf_left;
        return c;
    }

    // Inserts a previously retrieved character back into the input buffer.
    void stuff_char (ubyte q) {
        *(--m_pIn_buf_ofs) = q;
        m_in_buf_left++;
    }

    // Retrieves one character from the input stream, but does not read past markers. Will continue to return 0xFF when a marker is encountered.
    ubyte get_octet () {
        bool padding_flag;
        int c = get_char(&padding_flag);
        if (c == 0xFF) {
            if (padding_flag) return 0xFF;
            c = get_char(&padding_flag);
            if (padding_flag) { stuff_char(0xFF); return 0xFF; }
            if (c == 0x00) return 0xFF;
            stuff_char(cast(ubyte)(c));
            stuff_char(0xFF);
            return 0xFF;
        }
        return cast(ubyte)(c);
    }

    // Retrieves a variable number of bits from the input stream. Does not recognize markers.
    uint get_bits (int num_bits) {
        if (!num_bits) return 0;
        uint i = m_bit_buf >> (32 - num_bits);
        if ((m_bits_left -= num_bits) <= 0) {
            m_bit_buf <<= (num_bits += m_bits_left);
            uint c1 = get_char();
            uint c2 = get_char();
            m_bit_buf = (m_bit_buf & 0xFFFF0000) | (c1 << 8) | c2;
            m_bit_buf <<= -m_bits_left;
            m_bits_left += 16;
            assert(m_bits_left >= 0);
        } else {
            m_bit_buf <<= num_bits;
        }
        return i;
    }

    // Retrieves a variable number of bits from the input stream. Markers will not be read into the input bit buffer. Instead, an infinite number of all 1's will be returned when a marker is encountered.
    uint get_bits_no_markers (int num_bits) {
        if (!num_bits) return 0;
        uint i = m_bit_buf >> (32 - num_bits);
        if ((m_bits_left -= num_bits) <= 0) {
            m_bit_buf <<= (num_bits += m_bits_left);
            if (m_in_buf_left < 2 || m_pIn_buf_ofs[0] == 0xFF || m_pIn_buf_ofs[1] == 0xFF) {
                uint c1 = get_octet();
                uint c2 = get_octet();
                m_bit_buf |= (c1 << 8) | c2;
            } else {
                m_bit_buf |= (cast(uint)m_pIn_buf_ofs[0] << 8) | m_pIn_buf_ofs[1];
                m_in_buf_left -= 2;
                m_pIn_buf_ofs += 2;
            }
            m_bit_buf <<= -m_bits_left;
            m_bits_left += 16;
            assert(m_bits_left >= 0);
        } else {
            m_bit_buf <<= num_bits;
        }
        return i;
    }

    void word_clear (void *p, ushort c, uint n) {
        ubyte *pD = cast(ubyte*)p;
        immutable ubyte l = c & 0xFF, h = (c >> 8) & 0xFF;
        while (n)
        {
            pD[0] = l; pD[1] = h; pD += 2;
            n--;
        }
    }

    // Refill the input buffer.
    // This method will sit in a loop until (A) the buffer is full or (B)
    // the stream's read() method reports and end of file condition.
    void prep_in_buffer () {
        m_in_buf_left = 0;
        m_pIn_buf_ofs = m_in_buf.ptr;

        if (m_eof_flag)
            return;

        do
        {
            int bytes_read = readfn(m_in_buf.ptr + m_in_buf_left, JPGD_IN_BUF_SIZE - m_in_buf_left, &m_eof_flag);
            if (bytes_read == -1)
                stop_decoding(JPGD_STREAM_READ);

            m_in_buf_left += bytes_read;
        } while ((m_in_buf_left < JPGD_IN_BUF_SIZE) && (!m_eof_flag));


        // Pad the end of the block with M_EOI (prevents the decompressor from going off the rails if the stream is invalid).
        // (This dates way back to when this decompressor was written in C/asm, and the all-asm Huffman decoder did some fancy things to increase perf.)
        word_clear(m_pIn_buf_ofs + m_in_buf_left, 0xD9FF, 64);
    }

    void stop_decoding(int err)
    {
        throw new Exception("Couldn't parse JPEG");
    }
    
    // Read the start of frame (SOF) marker.
    void read_sof_marker () {
        int i;
        uint num_left;

        num_left = get_bits(16);

        if (get_bits(8) != 8)   /* precision: sorry, only 8-bit precision is supported right now */
            stop_decoding(JPGD_BAD_PRECISION);

        m_image_y_size = get_bits(16);

        if ((m_image_y_size < 1) || (m_image_y_size > JPGD_MAX_HEIGHT))
            stop_decoding(JPGD_BAD_HEIGHT);

        m_image_x_size = get_bits(16);

        if ((m_image_x_size < 1) || (m_image_x_size > JPGD_MAX_WIDTH))
            stop_decoding(JPGD_BAD_WIDTH);

        m_comps_in_frame = get_bits(8);

        if (num_left != cast(uint)(m_comps_in_frame * 3 + 8))
            stop_decoding(JPGD_BAD_SOF_LENGTH);

        for (i = 0; i < m_comps_in_frame; i++)
        {
            m_comp_ident.ptr[i]  = get_bits(8);
            get_bits(4);
            get_bits(4);
            get_bits(8);
        }
    }

    // Used to skip unrecognized markers.
    void skip_variable_marker () {
        uint num_left;

        num_left = get_bits(16);

        if (num_left < 2)
            stop_decoding(JPGD_BAD_VARIABLE_MARKER);

        num_left -= 2;

        while (num_left)
        {
            get_bits(8);
            num_left--;
        }
    }

    // Read a start of scan (SOS) marker.
    void read_sos_marker () {
        uint num_left;
        int i, ci, n, c, cc;

        num_left = get_bits(16);

        n = get_bits(8);

        m_comps_in_scan = n;

        num_left -= 3;

        if ( (num_left != cast(uint)(n * 2 + 3)) || (n < 1) || (n > JPGD_MAX_COMPS_IN_SCAN) )
            stop_decoding(JPGD_BAD_SOS_LENGTH);

        for (i = 0; i < n; i++)
        {
            cc = get_bits(8);
            c = get_bits(8);
            num_left -= 2;

            for (ci = 0; ci < m_comps_in_frame; ci++)
                if (cc == m_comp_ident.ptr[ci])
                    break;

            if (ci >= m_comps_in_frame)
                stop_decoding(JPGD_BAD_SOS_COMP_ID);

            m_comp_list.ptr[i]    = ci;
            m_comp_dc_tab.ptr[ci] = (c >> 4) & 15;
            m_comp_ac_tab.ptr[ci] = (c & 15) + (JPGD_MAX_HUFF_TABLES >> 1);
        }

        get_bits(8);
        get_bits(8);
        get_bits(4);
        get_bits(4);

        num_left -= 3;

        /* read past whatever is num_left */
        while (num_left)
        {
            get_bits(8);
            num_left--;
        }
    }

    // Finds the next marker.
    int next_marker () {
        uint c, bytes;

        bytes = 0;

        do
        {
            do
            {
                bytes++;
                c = get_bits(8);
            } while (c != 0xFF);

            do
            {
                c = get_bits(8);
            } while (c == 0xFF);

        } while (c == 0);

        // If bytes > 0 here, there where extra bytes before the marker (not good).

        return c;
    }

    // Process markers. Returns when an SOFx, SOI, EOI, or SOS marker is
    // encountered.
    int process_markers () {
        int c;

        for ( ; ; ) {
            c = next_marker();

            switch (c)
            {
                case M_SOF0:
                case M_SOF1:
                case M_SOF2:
                case M_SOF3:
                case M_SOF5:
                case M_SOF6:
                case M_SOF7:
                    //case M_JPG:
                case M_SOF9:
                case M_SOF10:
                case M_SOF11:
                case M_SOF13:
                case M_SOF14:
                case M_SOF15:
                case M_SOI:
                case M_EOI:
                case M_SOS:
                    return c;

                case M_APP0:
                    uint num_left;

                    num_left = get_bits(16);

                    if (num_left < 7)
                        stop_decoding(JPGD_BAD_VARIABLE_MARKER);

                    num_left -= 2;

                    ubyte[5] jfif_id;
                    foreach(i; 0..5)
                        jfif_id[i] = cast(ubyte) get_bits(8);

                    num_left -= 5;
                    static immutable ubyte[5] JFIF = [0x4A, 0x46, 0x49, 0x46, 0x00];
                    if (jfif_id == JFIF && num_left >= 7)
                    {
                        // skip version
                        get_bits(16);
                        uint units = get_bits(8);
                        int Xdensity = get_bits(16);
                        int Ydensity = get_bits(16);
                        num_left -= 7;

                        switch (units)
                        {
                            case 0: // no units
                                m_pixelsPerMeterX = defaultDPI;
                                m_pixelsPerMeterY = (Ydensity/cast(double)Xdensity) * m_pixelsPerMeterX;
                                break;
      
                            case 1: // dot per inch
                                m_pixelsPerMeterX = convertMetersToInches(Xdensity);
                                m_pixelsPerMeterY = convertMetersToInches(Ydensity);
                                break;
                            
                            case 2: // dot per cm
                                m_pixelsPerMeterX = Xdensity * 100.0f;
                                m_pixelsPerMeterY = Ydensity * 100.0f;
                                break;
                            default:
                        }
                    }

                    // skip rests of chunk

                    while (num_left)
                    {
                        get_bits(8);
                        num_left--;
                    }
                    break;

                case M_JPG:
                case M_RST0:    /* no parameters */
                case M_RST1:
                case M_RST2:
                case M_RST3:
                case M_RST4:
                case M_RST5:
                case M_RST6:
                case M_RST7:
                case M_TEM:
                    stop_decoding(JPGD_UNEXPECTED_MARKER);
                    break;
                default:    /* must be DNL, DHP, EXP, APPn, JPGn, COM, or RESn or APP0 */
                    skip_variable_marker();
                    break;
            }
        }
    }

    // Finds the start of image (SOI) marker.
    // This code is rather defensive: it only checks the first 512 bytes to avoid
    // false positives.
    void locate_soi_marker () {
        uint lastchar, thischar;
        uint bytesleft;

        lastchar = get_bits(8);

        thischar = get_bits(8);

        /* ok if it's a normal JPEG file without a special header */

        if ((lastchar == 0xFF) && (thischar == M_SOI))
            return;

        bytesleft = 4096; //512;

        for ( ; ; )
        {
            if (--bytesleft == 0)
                stop_decoding(JPGD_NOT_JPEG);

            lastchar = thischar;

            thischar = get_bits(8);

            if (lastchar == 0xFF)
            {
                if (thischar == M_SOI)
                    break;
                else if (thischar == M_EOI) // get_bits will keep returning M_EOI if we read past the end
                    stop_decoding(JPGD_NOT_JPEG);
            }
        }

        // Check the next character after marker: if it's not 0xFF, it can't be the start of the next marker, so the file is bad.
        thischar = (m_bit_buf >> 24) & 0xFF;

        if (thischar != 0xFF)
            stop_decoding(JPGD_NOT_JPEG);
    }

    // Find a start of frame (SOF) marker.
    void locate_sof_marker () {
        locate_soi_marker();

        int c = process_markers();

        switch (c)
        {
            case M_SOF2:
                goto case;
            case M_SOF0:  /* baseline DCT */
            case M_SOF1:  /* extended sequential DCT */
                read_sof_marker();
                break;
            case M_SOF9:  /* Arithmitic coding */
                stop_decoding(JPGD_NO_ARITHMITIC_SUPPORT);
                break;
            default:
                stop_decoding(JPGD_UNSUPPORTED_MARKER);
                break;
        }
    }

    // Reset everything to default/uninitialized state.
    void initit (JpegStreamReadFunc rfn) {
        m_error_code = JPGD_SUCCESS;
        m_image_x_size = m_image_y_size = 0;
        readfn = rfn;

        memset(m_quant.ptr, 0, m_quant.sizeof);

        m_comps_in_frame = 0;

        memset(m_comp_ident.ptr, 0, m_comp_ident.sizeof);
        memset(m_comp_h_blocks.ptr, 0, m_comp_h_blocks.sizeof);
        memset(m_comp_v_blocks.ptr, 0, m_comp_v_blocks.sizeof);

        m_comps_in_scan = 0;
        memset(m_comp_list.ptr, 0, m_comp_list.sizeof);
        memset(m_comp_dc_tab.ptr, 0, m_comp_dc_tab.sizeof);
        memset(m_comp_ac_tab.ptr, 0, m_comp_ac_tab.sizeof);

        m_blocks_per_mcu = 0;
        m_max_blocks_per_row = 0;
        m_mcus_per_row = 0;
        m_mcus_per_col = 0;
        m_expanded_blocks_per_component = 0;
        m_expanded_blocks_per_mcu = 0;
        m_expanded_blocks_per_row = 0;
        m_freq_domain_chroma_upsample = false;

        memset(m_mcu_org.ptr, 0, m_mcu_org.sizeof);

        m_total_lines_left = 0;
        m_mcu_lines_left = 0;
        m_real_dest_bytes_per_scan_line = 0;
        m_dest_bytes_per_scan_line = 0;
        m_dest_bytes_per_pixel = 0;

        memset(m_block_y_mcu.ptr, 0, m_block_y_mcu.sizeof);

        m_eob_run = 0;

        memset(m_block_y_mcu.ptr, 0, m_block_y_mcu.sizeof);

        m_pIn_buf_ofs = m_in_buf.ptr;
        m_in_buf_left = 0;
        m_eof_flag = false;
        m_tem_flag = 0;

        memset(m_in_buf_pad_start.ptr, 0, m_in_buf_pad_start.sizeof);
        memset(m_in_buf.ptr, 0, m_in_buf.sizeof);
        memset(m_in_buf_pad_end.ptr, 0, m_in_buf_pad_end.sizeof);

        m_restart_interval = 0;
        m_restarts_left    = 0;
        m_next_restart_num = 0;

        m_max_mcus_per_row = 0;
        m_max_blocks_per_mcu = 0;
        m_max_mcus_per_col = 0;

        memset(m_last_dc_val.ptr, 0, m_last_dc_val.sizeof);
        m_pMCU_coefficients = null;
        m_pSample_buf = null;

        m_pScan_line_0 = null;
        m_pScan_line_1 = null;

        // Ready the input buffer.
        prep_in_buffer();

        // Prime the bit buffer.
        m_bits_left = 16;
        m_bit_buf = 0;

        get_bits(16);
        get_bits(16);
    }

    // This method throws back into the stream any bytes that where read
    // into the bit buffer during initial marker scanning.
    void fix_in_buffer () {
        // In case any 0xFF's where pulled into the buffer during marker scanning.
        assert((m_bits_left & 7) == 0);

        if (m_bits_left == 16)
            stuff_char(cast(ubyte)(m_bit_buf & 0xFF));

        if (m_bits_left >= 8)
            stuff_char(cast(ubyte)((m_bit_buf >> 8) & 0xFF));

        stuff_char(cast(ubyte)((m_bit_buf >> 16) & 0xFF));
        stuff_char(cast(ubyte)((m_bit_buf >> 24) & 0xFF));

        m_bits_left = 16;
        get_bits_no_markers(16);
        get_bits_no_markers(16);
    }
}



// ////////////////////////////////////////////////////////////////////////// //
/// decompress JPEG image, what else?
/// you can specify required color components in `req_comps` (3 for RGB or 4 for RGBA), or leave it as is to use image value.
void extract_jpeg_metadata(scope JpegStreamReadFunc rfn, out int width, out int height, out float pixelsPerMeterX, out float pixelsPerMeterY) 
{
    auto decoder = jpeg_decoder(rfn);
    if (decoder.error_code != JPGD_SUCCESS) 
        return;
    width =  decoder.m_image_x_size;
    height = decoder.m_image_y_size; 
    pixelsPerMeterX = decoder.m_pixelsPerMeterX;
    pixelsPerMeterY = decoder.m_pixelsPerMeterY;
}

// ////////////////////////////////////////////////////////////////////////// //
/// decompress JPEG image from memory buffer.
/// you can specify required color components in `req_comps` (3 for RGB or 4 for RGBA), or leave it as is to use image value.
void extract_jpeg_metadata(const(ubyte)[] buf, out int width, out int height, out float pixelsPerMeterX, out float pixelsPerMeterY) {
    bool m_eof_flag;
    size_t bufpos;
    auto b = cast(const(ubyte)*)buf.ptr;
    extract_jpeg_metadata(      delegate int (void* pBuf, int max_bytes_to_read, bool *pEOF_flag) {
                                                import core.stdc.string : memcpy;
                                                if (bufpos >= buf.length) {
                                                    *pEOF_flag = true;
                                                    return 0;
                                                }
                                                if (buf.length-bufpos < max_bytes_to_read) max_bytes_to_read = cast(int)(buf.length-bufpos);
                                                memcpy(pBuf, b, max_bytes_to_read);
                                                b += max_bytes_to_read;
                                                return max_bytes_to_read;
                                             },
                                             width, height, pixelsPerMeterX, pixelsPerMeterY);
}
