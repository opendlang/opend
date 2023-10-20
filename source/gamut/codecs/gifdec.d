/**
  Port of https://github.com/lecram/gifdec
*/
// All of the source code and documentation for gifdec is released into the
// public domain and provided without warranty of any kind.
module gamut.codecs.gifdec;

version(decodeGIF):

import gamut.io;

nothrow @nogc:

import core.stdc.stdlib: malloc, calloc, free, realloc;
import core.stdc.string: memcmp, memset, memcpy, strncmp;

struct gd_Palette 
{
    int size;
    ubyte[255 * 3] colors;
}

struct gd_GCE 
{
    ushort delay;
    ubyte tindex;
    ubyte disposal;
    int input;
    int transparency;
}

struct gd_GIF 
{
nothrow @nogc:
    IOStream *io;
    IOHandle handle;

    c_long anim_start;
    ushort width, height;
    ushort depth;
    ushort loop_count;
    gd_GCE gce;
    gd_Palette *palette;
    gd_Palette lct, gct;

    void function(gd_GIF *gif, ushort tx, ushort ty,
                  ushort tw, ushort th, ubyte cw, ubyte ch,
                  ubyte fg, ubyte bg) plain_text;

    void function(gd_GIF *gif) comment;
    void function(gd_GIF *gif, char* id /* 8 chars */, char* auth /* 3 chars */) application;

    ushort fx, fy, fw, fh;
    ubyte bgindex;
    ubyte* canvas;
    ubyte* frame;
}

ushort MIN_ushort(ushort A, ushort B) 
{
    return A < B ? A : B;
}

int MIN_int(int A, int B) 
{
    return A < B ? A : B;
}

int MAX_int(int A, int B) 
{
    return A > B ? A : B;
}

//#define MIN(A, B) ((A) < (B) ? (A) : (B))
//#define MAX(A, B) ((A) > (B) ? (A) : (B))

struct Entry 
{
    ushort length;
    ushort prefix;
    ubyte  suffix;
}

struct Table 
{
    int bulk;
    int nentries;
    Entry *entries;
}

/// Read one little-endian ushort
ushort read_num(gd_GIF* gif, bool* err)
{
    return gif.io.read_ushort_LE(gif.handle, err);
}

/// Returns: null in case of parse failure.
gd_GIF* gd_open_gif(IOStream *io, IOHandle handle)
{
    ubyte[3] sigver;
    ushort width, height, depth;
    ubyte fdsz;
    int i, gct_sz;
    ubyte *bgcolor;
    bool err;
    ubyte bgidx;
    ubyte aspect;
    gd_GIF *gif;

    // Read magic signature
    if (1 != io.read(sigver.ptr, 3, 1, handle))
        goto fail;

    if (memcmp(sigver.ptr, "GIF".ptr, 3) != 0)
        goto fail;

    // Read version
    if (1 != io.read(sigver.ptr, 3, 1, handle))
        goto fail;

    if (memcmp(sigver.ptr, "89a".ptr, 3) != 0) // TODO: shall we support 87a???
        goto fail;

    /* Width x Height */    
    width = io.read_ushort_LE(handle, &err);
    if (err) 
        goto fail;
    height = io.read_ushort_LE(handle, &err);
    if (err) 
        goto fail;

    /* FDSZ */
    if (1 != io.read(&fdsz, 1, 1, handle))
        goto fail;

    /* Presence of GCT */
    if (!(fdsz & 0x80)) 
    {
        goto fail; // no global color table
    }

    /* Color Space's Depth */
    depth = ((fdsz >> 4) & 7) + 1;

    /* Ignore Sort Flag. */
    /* GCT Size */
    gct_sz = 1 << ((fdsz & 0x07) + 1);

    /* Background Color Index */    
    if (1 != io.read(&bgidx, 1, 1, handle))
        goto fail;

    /* Aspect Ratio */    
    if (1 != io.read(&aspect, 1, 1, handle))
        goto fail;

    /* Create gd_GIF Structure. */
    gif = cast(gd_GIF*) calloc(1, gd_GIF.sizeof);
    if (!gif) 
        goto fail;

    gif.io = io;
    gif.handle = handle;
    gif.width  = width;
    gif.height = height;
    gif.depth  = depth;

    /* Read GCT */
    gif.gct.size = gct_sz;
    if (1 != io.read(gif.gct.colors.ptr, gif.gct.size * 3, 1, handle))
        goto fail;

    gif.palette = &gif.gct;
    gif.bgindex = bgidx;
    gif.frame = cast(ubyte*) calloc(4, width * height); // rgba8 apparently
    if (!gif.frame) 
        goto fail_dealloc;

    gif.canvas = &gif.frame[width * height];
    if (gif.bgindex)
        memset(gif.frame, gif.bgindex, gif.width * gif.height);
    bgcolor = &gif.palette.colors[gif.bgindex*3];
    if (bgcolor[0] || bgcolor[1] || bgcolor [2])
        for (i = 0; i < gif.width * gif.height; i++)
            memcpy(&gif.canvas[i*3], bgcolor, 3);

    // Note: in original decoder, storing the offset here (ftell) allows to rewing the animation
    goto ok;

fail_dealloc:
    free(gif);
fail:
    return null;
ok:
    return gif;
}

void discard_sub_blocks(gd_GIF *gif, bool* err)
{
    ubyte size;
    do 
    {
        if (1 != gif.io.read(&size, 1, 1, gif.handle))
            goto failure;
        if (!gif.io.skipBytes(gif.handle, size))
            goto failure;
    } while (size);
    
    *err = false;
    return;

failure:
    *err = true;
}

void read_plain_text_ext(gd_GIF *gif, bool* err)
{
    if (gif.plain_text) 
    {
        ushort tx, ty, tw, th;
        ubyte cw, ch, fg, bg;
        c_long sub_block;
        if (!gif.io.skipBytes(gif.handle, 1)) /* block size = 12 */
            goto failure;
        tx = read_num(gif, err); if (*err) goto failure;
        ty = read_num(gif, err); if (*err) goto failure;
        tw = read_num(gif, err); if (*err) goto failure;
        th = read_num(gif, err); if (*err) goto failure;
        cw = gif.io.read_ubyte(gif.handle, err); if (*err) goto failure;
        ch = gif.io.read_ubyte(gif.handle, err); if (*err) goto failure;
        fg = gif.io.read_ubyte(gif.handle, err); if (*err) goto failure;
        bg = gif.io.read_ubyte(gif.handle, err); if (*err) goto failure;

        sub_block = gif.io.tell(gif.handle);
        if (sub_block == -1)
            goto failure;
        gif.plain_text(gif, tx, ty, tw, th, cw, ch, fg, bg);
        if (!gif.io.seekAbsolute(gif.handle, sub_block))
            goto failure;
    } 
    else 
    {
        /* Discard plain text metadata. */
        if (!gif.io.skipBytes(gif.handle, 13)) /* block size = 12 */
            goto failure;
    }
    /* Discard plain text sub-blocks. */
    discard_sub_blocks(gif, err); if (*err) goto failure;

    *err = false;
    return;

    failure:
        *err = true;
}

void read_graphic_control_ext(gd_GIF *gif, bool* err)
{
    ubyte rdit;

    /* Discard block size (always 0x04). */
    if (!gif.io.skipBytes(gif.handle, 1)) /* block size = 12 */
        goto failure;

    rdit = gif.io.read_ubyte(gif.handle, err); if (*err) goto failure;
    gif.gce.disposal = (rdit >> 2) & 3;
    gif.gce.input = rdit & 2;
    gif.gce.transparency = rdit & 1;
    gif.gce.delay = read_num(gif, err); if (*err) goto failure;

    gif.gce.tindex = gif.io.read_ubyte(gif.handle, err); if (*err) goto failure;
    
    /* Skip block terminator. */
    if (!gif.io.skipBytes(gif.handle, 1)) /* block size = 12 */
        goto failure;

    *err = false;
    return;

failure:
    *err = true;
}

void read_comment_ext(gd_GIF *gif, bool* err)
{
    if (gif.comment) 
    {
        c_long sub_block = gif.io.tell(gif.handle);
        if (sub_block == -1)
            goto failure;
        gif.comment(gif);
        if (!gif.io.seekAbsolute(gif.handle, sub_block))
            goto failure;
    }
    /* Discard comment sub-blocks. */
    discard_sub_blocks(gif, err);
    if (*err) goto failure;

    *err = false;
    return;

failure:
    *err = true;
}

void read_application_ext(gd_GIF *gif, bool* err)
{
    char[8] app_id;
    char[3] app_auth_code;

    /* Discard block size (always 0x0B). */
    if (!gif.io.skipBytes(gif.handle, 1))
        goto failure;

    /* Application Identifier. */
    if (1 != gif.io.read(app_id.ptr, 8, 1, gif.handle))
        goto failure;

    /* Application Authentication Code. */
    if (1 != gif.io.read(app_auth_code.ptr, 3, 1, gif.handle))
        goto failure;

    if (!strncmp(app_id.ptr, "NETSCAPE".ptr, 8)) 
    {
        /* Discard block size (0x03) and constant byte (0x01). */
        if (!gif.io.skipBytes(gif.handle, 2))
            goto failure;

        bool err2;
        gif.loop_count = gif.io.read_ushort_LE(gif.handle, &err2);
        if (err2)
            goto failure;

        /* Skip block terminator. */
        if (!gif.io.skipBytes(gif.handle, 1))
            goto failure;
    } 
    else if (gif.application) 
    {
        c_long sub_block = gif.io.tell(gif.handle);
        if (sub_block == -1)
            goto failure;
        gif.application(gif, app_id.ptr, app_auth_code.ptr);
        if (!gif.io.seekAbsolute(gif.handle, sub_block))
            goto failure;
        bool err2;
        discard_sub_blocks(gif, &err2);
        if (err2)
            goto failure;
    } 
    else 
    {
        bool err2;
        discard_sub_blocks(gif, &err2);
        if (err2)
            goto failure;
    }

    *err = false;
    return;

    failure:
    *err = true;
}

void read_ext(gd_GIF *gif, bool* err)
{
    ubyte label = gif.io.read_ubyte(gif.handle, err);
    if (*err) goto failure;

    switch (label) 
    {
        case 0x01:
            read_plain_text_ext(gif, err);
            if (*err) goto failure;
            break;
        case 0xF9:
            read_graphic_control_ext(gif, err);
            if (*err) goto failure;
            break;
        case 0xFE:
            read_comment_ext(gif, err);
            if (*err) goto failure;
            break;
        case 0xFF:
            read_application_ext(gif, err);
            if (*err) goto failure;
            break;
        default:
            // unknown extension
    }

    *err = false;
    return;

failure:
    *err = true;
}

Table * new_table(int key_size)
{
    int key;
    int init_bulk = MAX_int(1 << (key_size + 1), 0x100);
    Table* table = cast(Table*) malloc(Table.sizeof + Entry.sizeof * init_bulk);
    if (table) 
    {
        table.bulk = init_bulk;
        table.nentries = (1 << key_size) + 2;
        table.entries = cast(Entry *) &table[1];
        for (key = 0; key < (1 << key_size); key++)
            table.entries[key] = Entry(1, 0xFFF, cast(ubyte)key);
    }
    return table;
}

/* Add table entry. Return value:
 *  0 on success
 *  +1 if key size must be incremented after this addition
 *  -1 if could not realloc table */
int add_entry(Table **tablep, ushort length, ushort prefix, ubyte suffix)
{
    Table *table = *tablep;
    if (table.nentries == table.bulk) 
    {
        table.bulk *= 2;
        table = cast(Table*) realloc(table, Table.sizeof + Entry.sizeof * table.bulk);
        if (!table) return -1;
        table.entries = cast(Entry *) &table[1];
        *tablep = table;
    }
    table.entries[table.nentries] = Entry(length, prefix, suffix);
    table.nentries++;
    if ((table.nentries & (table.nentries - 1)) == 0)
        return 1;
    return 0;
}

ushort get_key(gd_GIF *gif, int key_size, ubyte *sub_len, ubyte *shift, ubyte *byte_, bool* err)
{
    *err = false;
    int bits_read;
    int rpad;
    int frag_size;
    ushort key;

    key = 0;
    for (bits_read = 0; bits_read < key_size; bits_read += frag_size) {
        rpad = (*shift + bits_read) % 8;
        if (rpad == 0) 
        {
            /* Update byte. */
            if (*sub_len == 0) 
            {
                *sub_len = gif.io.read_ubyte(gif.handle, err); 
                if (*err)
                    return 0; // return the error

                if (*sub_len == 0)
                    return 0x1000;
            }
            *byte_ = gif.io.read_ubyte(gif.handle, err); 
            if (*err)
                return 0; // return the error

            (*sub_len)--;
        }
        frag_size = MIN_int(key_size - bits_read, 8 - rpad);
        key |= (cast(ushort) ((*byte_) >> rpad)) << bits_read;
    }
    /* Clear extra bits to the left. */
    key &= (1 << key_size) - 1;
    *shift = cast(ubyte)( (*shift + key_size) % 8 );
    return key;
}

/* Compute output index of y-th input line, in frame of height h. */
static int
interlaced_line_index(int h, int y)
{
    int p; /* number of lines in current pass */

    p = (h - 1) / 8 + 1;
    if (y < p) /* pass 1 */
        return y * 8;
    y -= p;
    p = (h - 5) / 8 + 1;
    if (y < p) /* pass 2 */
        return y * 8 + 4;
    y -= p;
    p = (h - 3) / 4 + 1;
    if (y < p) /* pass 3 */
        return y * 4 + 2;
    y -= p;
    /* pass 4 */
    return y * 2 + 1;
}

/* Decompress image pixels.
 * Return 0 on success or -1 on error. */
int read_image_data(gd_GIF *gif, int interlace)
{
    ubyte sub_len, shift, byte_;
    int init_key_size, key_size, table_is_full;
    int frm_off, frm_size, str_len, i, p, x, y;
    ushort key, clear, stop;
    int ret;
    Table *table;
    Entry entry;
    c_long start, end;

    bool err;
    byte_ = gif.io.read_ubyte(gif.handle, &err);
    if (err)
        return -1;

    key_size = cast(int) byte_;
    if (key_size < 2 || key_size > 8)
        return -1;
    
    start = gif.io.tell(gif.handle);
    if (start == -1)
        return -1;
    discard_sub_blocks(gif, &err);
    if (err)
        return -1;
    end = gif.io.tell(gif.handle);
    if (end == -1)
        return -1;
    if (!gif.io.seekAbsolute(gif.handle, start))
        return -1;

    clear = cast(ushort)(1 << key_size);
    stop = cast(ushort)(clear + 1);
    table = new_table(key_size);
    if (!table)
        return -1;
    key_size++;
    init_key_size = key_size;
    sub_len = shift = 0;
    key = get_key(gif, key_size, &sub_len, &shift, &byte_, &err); /* clear code */
    if (err)
    {
        free(table);
        return -1;
    }
    frm_off = 0;
    ret = 0;
    frm_size = gif.fw*gif.fh;
    while (frm_off < frm_size) 
    {
        if (key == clear) {
            key_size = init_key_size;
            table.nentries = (1 << (key_size - 1)) + 2;
            table_is_full = 0;
        } else if (!table_is_full) {
            ret = add_entry(&table, cast(ushort)(str_len + 1), key, entry.suffix);
            if (ret == -1) {
                free(table);
                return -1;
            }
            if (table.nentries == 0x1000) {
                ret = 0;
                table_is_full = 1;
            }
        }
        key = get_key(gif, key_size, &sub_len, &shift, &byte_, &err);
        if (err)
            return -1;
        if (key == clear) continue;
        if (key == stop || key == 0x1000) break;
        if (ret == 1) key_size++;
        entry = table.entries[key];
        str_len = entry.length;
        for (i = 0; i < str_len; i++) {
            p = frm_off + entry.length - 1;
            x = p % gif.fw;
            y = p / gif.fw;
            if (interlace)
                y = interlaced_line_index(cast(int) gif.fh, y);
            gif.frame[(gif.fy + y) * gif.width + gif.fx + x] = entry.suffix;
            if (entry.prefix == 0xFFF)
                break;
            else
                entry = table.entries[entry.prefix];
        }
        frm_off += str_len;
        if (key < table.nentries - 1 && !table_is_full)
            table.entries[table.nentries - 1].suffix = entry.suffix;
    }
    free(table);
    if (key == stop)
    {
        sub_len = gif.io.read_ubyte(gif.handle, &err);
        if (err) return -1;
    }
    if (!gif.io.seekAbsolute(gif.handle, end))
        return -1;
    return 0;
}

/* Read image.
 * Return 0 on success or -1 on error */
int read_image(gd_GIF *gif)
{
    ubyte fisrz;
    int interlace;

    bool err;

    /* Image Descriptor. */
    gif.fx = read_num(gif, &err); if (err) return -1;
    gif.fy = read_num(gif, &err); if (err) return -1;
    
    if (gif.fx >= gif.width || gif.fy >= gif.height)
        return -1;
    
    gif.fw = read_num(gif, &err); if (err) return -1;
    gif.fh = read_num(gif, &err); if (err) return -1;
    
    gif.fw = cast(ushort) MIN_int(gif.fw, gif.width - gif.fx);
    gif.fh = cast(ushort) MIN_int(gif.fh, gif.height - gif.fy);
    
    fisrz = gif.io.read_ubyte(gif.handle, &err);
    if (err)
        return -1;

    interlace = fisrz & 0x40;
    /* Ignore Sort Flag. */
    /* Local Color Table? */
    if (fisrz & 0x80) {
        /* Read LCT */
        gif.lct.size = 1 << ((fisrz & 0x07) + 1);

        if (1 != gif.io.read(gif.lct.colors.ptr, 3 * gif.lct.size, 1, gif.handle))
            return -1;
        gif.palette = &gif.lct;
    } else
        gif.palette = &gif.gct;

    /* Image Data. */
    return read_image_data(gif, interlace);
}

void render_frame_rect(gd_GIF *gif, ubyte *buffer)
{
    int i, j, k;
    ubyte index;
    ubyte* color;
    i = gif.fy * gif.width + gif.fx;
    for (j = 0; j < gif.fh; j++) 
    {
        for (k = 0; k < gif.fw; k++) 
        {
            index = gif.frame[(gif.fy + j) * gif.width + gif.fx + k];
            color = &gif.palette.colors[index*3];
            if (!gif.gce.transparency || index != gif.gce.tindex)
                memcpy(&buffer[(i+k)*3], color, 3);
        }
        i += gif.width;
    }
}

void dispose(gd_GIF *gif)
{
    int i, j, k;
    ubyte *bgcolor;
    switch (gif.gce.disposal) {
    case 2: /* Restore to background color. */
        bgcolor = &gif.palette.colors[gif.bgindex*3];
        i = gif.fy * gif.width + gif.fx;
        for (j = 0; j < gif.fh; j++) {
            for (k = 0; k < gif.fw; k++)
                memcpy(&gif.canvas[(i+k)*3], bgcolor, 3);
            i += gif.width;
        }
        break;
    case 3: /* Restore to previous, i.e., don't update canvas.*/
        break;
    default:
        /* Add frame non-transparent pixels to canvas. */
        render_frame_rect(gif, gif.canvas);
    }
}

/* Return 1 if got a frame; 0 if got GIF trailer; -1 if error. */
int gd_get_frame(gd_GIF *gif)
{
    char sep;
    bool err;

    dispose(gif);
    ulong res = gif.io.read(&sep, 1, 1, gif.handle);
    if (1 != res)
        return -1;

    while (sep != ',') 
    {
        if (sep == ';')
            return 0;

        if (sep == '!')
        {
            read_ext(gif, &err);
            if (err)
                return -1;
        }
        else 
            return -1;
        if (1 != gif.io.read(&sep, 1, 1, gif.handle))
            return -1;
    }

    if (read_image(gif) == -1)
        return -1;
    return 1;
}

void gd_render_frame(gd_GIF *gif, ubyte *buffer)
{
    memcpy(buffer, gif.canvas, gif.width * gif.height * 3);
    render_frame_rect(gif, buffer);
}

int gd_is_bgcolor(gd_GIF *gif, ubyte* color /* point to 3 bytes */)
{
    return !memcmp(&gif.palette.colors[gif.bgindex*3], color, 3);
}

void gd_close_gif(gd_GIF *gif)
{
    free(gif.frame);    
    free(gif);
}
