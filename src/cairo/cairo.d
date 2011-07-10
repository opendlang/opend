module cairo.cairo;

import cairo.c.cairo;

import std.conv;
import std.string;
import std.traits;
import core.exception;

version(CAIRO_HAS_PS_SURFACE)
{
    import cairo.ps;
}
version(CAIRO_HAS_PDF_SURFACE)
{
    import cairo.pdf;
}
version(CAIRO_HAS_SVG_SURFACE)
{
    import cairo.svg;
}
version(CAIRO_HAS_WIN32_SURFACE)
{
    import cairo.win32;
}
version(CAIRO_HAS_XCB_SURFACE)
{
    import cairo.xcb;
}
version(CAIRO_HAS_DIRECTFB_SURFACE)
{
    import cairo.directfb;
}

public alias cairo_content_t Content;
public alias cairo_antialias_t AntiAlias;
public alias cairo_subpixel_order_t SubpixelOrder;
public alias cairo_hint_style_t HintStyle;
public alias cairo_hint_metrics_t HintMetrics;
public alias cairo_surface_type_t SurfaceType;
public alias cairo_format_t Format;
public alias cairo_extend_t Extend;
public alias cairo_filter_t Filter;
public alias cairo_pattern_type_t PatternType;
public alias cairo_fill_rule_t FillRule;
public alias cairo_line_cap_t LineCap;
public alias cairo_line_join_t LineJoin;
public alias cairo_operator_t Operator;
public alias cairo_path_data_type_t PathElementType;
public alias cairo_font_extents_t FontExtents;
public alias cairo_text_extents_t TextExtents;
public alias cairo_glyph_t Glyph;
public alias cairo_text_cluster_t TextCluster;
public alias cairo_text_cluster_flags_t TextClusterFlags;
public alias cairo_font_slant_t FontSlant;
public alias cairo_font_weight_t FontWeight;

void throwError(cairo_status_t status)
{
    switch(status)
    {
        case cairo_status_t.CAIRO_STATUS_SUCCESS:
            return;
        case cairo_status_t.CAIRO_STATUS_NO_MEMORY:
            throw new OutOfMemoryError(__FILE__, __LINE__);
        default:
            throw new CairoException(status);
    }
}

int formatStrideForWidth(Format format, int width)
{
    return cairo_format_stride_for_width(format, width);
}

public struct Point
{
    public this(double x, double y)
    {
        this.x = x;
        this.y = y;
    }
    
    double x;
    double y;
}

public struct Rectangle
{
    public this(Point point, double width, double height)
    {
        this.point = point;
        this.width = width;
        this.height = height;
    }
    
    Point point;
    double width;
    double height;
}

public struct Box
{
    public this(Point point1, Point point2)
    {
        this.point1 = point1;
        this.point2 = point2;
    }
    
    Point point1, point2;
}

public struct Resolution
{
    public this(double resX, double resY)
    {
        this.x = resX;
        this.y = resY;
    }
    
    ///Pixels per inch
    double x, y;
}

//TODO: merge those?
public struct RGBA
{
    public this(double red, double green, double blue, double alpha)
    {
        this.red = red;
        this.green = green;
        this.blue = blue;
        this.alpha = alpha;
    }
    
    public double red, green, blue, alpha;
}

public struct RGB
{
    public this(double red, double green, double blue)
    {
        this.red = red;
        this.green = green;
        this.blue = blue;
    }
    
    public double red, green, blue;
}

//TODO: user defined paths
public struct Path
{
    private:
        struct Impl
        {
            cairo_path_t* path;
            uint refs = uint.max / 2;
            this(cairo_path_t* pa, uint r)
            {
                path = pa;
                refs = r;
            }
        }
        Impl* p;
    
        void close()
        {
            if (!p) return; // succeed vacuously
            if (!p.path)
            {
                p = null; // start a new life
                return;
            }
            scope(exit)
            {
                p.path = null; // nullify the handle anyway
                --p.refs;
                p = null;
            }
    
            cairo_path_destroy(p.path);
        }

        cairo_status_t status()
        {
            assert(p);
            return p.path.status;
        }

        cairo_path_data_t* data()
        {
            assert(p);
            return p.path.data;
        }

        int num_data()
        {
            assert(p);
            return p.path.num_data;
        }

    public:
        this(cairo_path_t* path)
        {
            throwError(path.status);
            p = new Impl(path, 1);
        }

        ~this()
        {
            if (!p) return;
            if (p.refs == 1) close;
            else --p.refs;
        }
        
        this(this)
        {
            if (!p) return;
            assert(p.refs);
            ++p.refs;
        }

        void opAssign(Path rhs)
        {
            p = rhs.p;
        }

        PathRange opSlice()
        {
            return PathRange(this);
        }
}

public struct PathRange
{
    private:
        Path path;
        int pos = 0;
    
    public:
        this(Path path)
        {
            this.path = path;
        }
        
        //TODO: save function for ranges
        @property bool empty()
        {
            assert(pos <= path.num_data);
            return (pos == path.num_data);
        }
        
        void popFront()
        {
            pos += path.data[pos].header.length;
            assert(pos <= path.num_data);
        }
        
        @property PathElement front()
        {
            return PathElement(&path.data[pos]);
        }
}

public struct PathElement
{
    private:
        cairo_path_data_t* data;
        
        this(cairo_path_data_t* data)
        {
            this.data = data;
        }
    public:
        @property PathElementType Type()
        {
            return data.header.type;
        }
        
        Point getPoint(int index)
        {
            //length = 1 + number of points, index 0 based
            if(index > (data.header.length - 2))
            {
                throw new RangeError(__FILE__, __LINE__);
            }
            Point p;
            p.x = data[index+1].point.x;
            p.y = data[index+1].point.y;
            return p;
        }
}

public struct Matrix
{
    public:
        cairo_matrix_t nativeMatrix;
        alias nativeMatrix this;
        
        this(double xx, double yx, double xy, double yy,
            double x0, double y0)
        {
            cairo_matrix_init(&this.nativeMatrix, xx, yx, xy, yy, x0, y0);
        }
        
        void initIdentity()
        {
            cairo_matrix_init_identity(&this.nativeMatrix);
        }
        
        void initTranslate(double tx, double ty)
        {
            cairo_matrix_init_translate(&this.nativeMatrix, tx, ty);
        }
        
        void initScale(double sx, double sy)
        {
            cairo_matrix_init_scale(&this.nativeMatrix, sx, sy);
        }
        
        void initRotate(double radians)
        {
            cairo_matrix_init_rotate(&this.nativeMatrix, radians);
        }
        
        void translate(double tx, double ty)
        {
            cairo_matrix_translate(&this.nativeMatrix, tx, ty);
        }
        
        void scale(double sx, double sy)
        {
            cairo_matrix_scale(&this.nativeMatrix, sx, sy);
        }
        
        void rotate(double radians)
        {
            cairo_matrix_rotate(&this.nativeMatrix, radians);
        }
        
        void invert()
        {
            throwError(cairo_matrix_invert(&this.nativeMatrix));
        }
        
        Matrix opBinary(string op)(Matrix rhs) if(op == "*")
        {
            Matrix result;
            cairo_matrix_multiply(&result.nativeMatrix, &this.nativeMatrix, &rhs.nativeMatrix);
            return result;
        }
        
        Point transformDistance(Point dist)
        {
            cairo_matrix_transform_distance(&this.nativeMatrix, &dist.x, &dist.y);
            return dist;
        }
        
        Point transformPoint(Point point)
        {
            cairo_matrix_transform_point(&this.nativeMatrix, &point.x, &point.y);
            return point;
        }
}

public class CairoException : Exception
{
    public:
        cairo_status_t status;
    
        this(cairo_status_t stat)
        {
            this.status = stat;
            super(to!string(this.status) ~ ": " ~ to!string(cairo_status_to_string(this.status)));
        }
}

public class Pattern
{
    protected:
        void checkError()
        {
            throwError(cairo_pattern_status(nativePointer));
        }
        bool _disposed = false;
    
    public:
        cairo_pattern_t* nativePointer;

        /* Warning: ptr reference count is not increased by this function!
         * Adjust reference count before calling it if necessary*/
        this(cairo_pattern_t* ptr)
        {
            this.nativePointer = ptr;
            if(!ptr)
            {
                throw new CairoException(cairo_status_t.CAIRO_STATUS_NULL_POINTER);
            }
            checkError();
        }

        ~this()
        {
            dispose();
        }
        
        static Pattern createFromNative(cairo_pattern_t* ptr)
        {
            if(!ptr)
            {
                throw new CairoException(cairo_status_t.CAIRO_STATUS_NULL_POINTER);
            }
            throwError(cairo_pattern_status(ptr));
            //Adjust reference count
            cairo_pattern_reference(ptr);
            switch(cairo_pattern_get_type(ptr))
            {
                case cairo_pattern_type_t.CAIRO_PATTERN_TYPE_LINEAR:
                    return new LinearGradient(ptr);
                case cairo_pattern_type_t.CAIRO_PATTERN_TYPE_RADIAL:
                    return new RadialGradient(ptr);
                case cairo_pattern_type_t.CAIRO_PATTERN_TYPE_SOLID:
                    return new SolidPattern(ptr);
                case cairo_pattern_type_t.CAIRO_PATTERN_TYPE_SURFACE:
                    return new SurfacePattern(ptr);
                default:
                    return new Pattern(ptr);
            }
        }

        void dispose()
        {
            if(!_disposed)
            {
                cairo_pattern_destroy(this.nativePointer);
                debug
                    this.nativePointer = null;
                _disposed = true;
            }
        }
        
        void setExtend(Extend ext)
        {
            cairo_pattern_set_extend(this.nativePointer, ext);
            checkError();
        }
        
        Extend getExtend()
        {
            scope(exit)
                checkError();
            return cairo_pattern_get_extend(this.nativePointer);
        }
        
        void setFilter(Filter fil)
        {
            cairo_pattern_set_filter(this.nativePointer, fil);
            checkError();
        }
        
        Filter getFilter()
        {
            scope(exit)
                checkError();
            return cairo_pattern_get_filter(this.nativePointer);
        }
        
        void setMatrix(Matrix mat)
        {
            cairo_pattern_set_matrix(this.nativePointer, &mat.nativeMatrix);
            checkError();
        }
        
        Matrix getMatrix()
        {
            Matrix ma;
            cairo_pattern_get_matrix(this.nativePointer, &ma.nativeMatrix);
            checkError();
            return ma;
        }
        
        PatternType getType()
        {
            scope(exit)
                checkError();
            return cairo_pattern_get_type(this.nativePointer);
        }
        
        uint getReferenceCount()
        {
            scope(exit)
                checkError();
            return cairo_pattern_get_reference_count(this.nativePointer);
        }
        
        void setUserData(const cairo_user_data_key_t* key, void* data, cairo_destroy_func_t destroy)
        {
            cairo_pattern_set_user_data(this.nativePointer, key, data, destroy);
            checkError();
        }
        
        void* getUserData(const cairo_user_data_key_t* key)
        {
            scope(exit)
                checkError();
            return cairo_pattern_get_user_data(this.nativePointer, key);
        }
}

public class SolidPattern : Pattern
{
    public:
        /* Warning: ptr reference count is not increased by this function!
         * Adjust reference count before calling it if necessary*/
        this(cairo_pattern_t* ptr)
        {
            super(ptr);
        }
        
        static SolidPattern fromRGB(double red, double green, double blue)
        {
            return new SolidPattern(cairo_pattern_create_rgb(red, green, blue));
        }

        static SolidPattern fromRGB(RGB rgb)
        {
            return new SolidPattern(cairo_pattern_create_rgb(rgb.red, rgb.green, rgb.blue));
        }
        
        static SolidPattern fromRGBA(double red, double green, double blue, double alpha)
        {
            return new SolidPattern(cairo_pattern_create_rgba(red, green, blue, alpha));
        }

        static SolidPattern fromRGBA(RGBA rgba)
        {
            return new SolidPattern(cairo_pattern_create_rgba(rgba.red,rgba. green, rgba.blue, rgba.alpha));
        }
        
        RGBA getRGBA()
        {
            RGBA col;
            cairo_pattern_get_rgba(this.nativePointer, &col.red, &col.green, &col.blue, &col.alpha);
            checkError();
            return col;
        }
}

public class SurfacePattern : Pattern
{
    public:
        this(Surface surface)
        {
            super(cairo_pattern_create_for_surface(surface.nativePointer));
        }

        /* Warning: ptr reference count is not increased by this function!
         * Adjust reference count before calling it if necessary*/
        this(cairo_pattern_t* ptr)
        {
            super(ptr);
        }
        
        Surface getSurface()
        {
            cairo_surface_t* ptr;
            throwError(cairo_pattern_get_surface(this.nativePointer, &ptr));
            return Surface.createFromNative(ptr);
        }
}

public class Gradient : Pattern
{
    public:
        /* Warning: ptr reference count is not increased by this function!
         * Adjust reference count before calling it if necessary*/
        this(cairo_pattern_t* ptr)
        {
            super(ptr);
        }
        
        void addColorStopRGB(double offset, RGB color)
        {
            cairo_pattern_add_color_stop_rgb(this.nativePointer, offset,
                color.red, color.green, color.blue);
            checkError();
        }
        
        void addColorStopRGBA(double offset, RGBA color)
        {
            cairo_pattern_add_color_stop_rgba(this.nativePointer, offset,
                color.red, color.green, color.blue, color.alpha);
            checkError();
        }
        
        int getColorStopCount()
        {
            int tmp;
            cairo_pattern_get_color_stop_count(this.nativePointer, &tmp);
            checkError();
            return tmp;
        }
        
        void getColorStopRGBA(int index, out double offset, out RGBA Color)
        {
            throwError(cairo_pattern_get_color_stop_rgba(this.nativePointer, index, &offset,
                &Color.red, &Color.green, &Color.blue, &Color.alpha));
        }
}

public class LinearGradient : Gradient
{
    public:
        this(Point p1, Point p2)
        {
            super(cairo_pattern_create_linear(p1.x, p1.y, p2.x, p2.y));
        }

        /* Warning: ptr reference count is not increased by this function!
         * Adjust reference count before calling it if necessary*/
        this(cairo_pattern_t* ptr)
        {
            super(ptr);
        }
        
        Point[2] getLinearPoints()
        {
            Point[2] tmp;
            throwError(cairo_pattern_get_linear_points(this.nativePointer, &tmp[0].x, &tmp[0].y,
                &tmp[1].x, &tmp[1].y));
            return tmp;
        }
}
public class RadialGradient : Gradient
{
    public:
        this(Point c0, double radius0, Point c1, double radius1)
        {
            super(cairo_pattern_create_radial(c0.x, c0.y, radius0, c1.x, c1.y, radius1));
        }

        /* Warning: ptr reference count is not increased by this function!
         * Adjust reference count before calling it if necessary*/
        this(cairo_pattern_t* ptr)
        {
            super(ptr);
        }
        
        void getRadialCircles(out Point c0, out Point c1, out double radius0, out double radius1)
        {
            throwError(cairo_pattern_get_radial_circles(this.nativePointer, &c0.x, &c0.y, &radius0,
                &c1.x, &c1.y, &radius1));
        }
}

public class Device
{
    private:
        cairo_device_t* nativePointer;
        bool _disposed = false;

    public:
        /* Warning: ptr reference count is not increased by this function!
         * Adjust reference count before calling it if necessary*/
        this(cairo_device_t* ptr)
        {
            this.nativePointer = ptr;
        }
        ~this()
        {
            dispose();
        }

        void dispose()
        {
            if(!_disposed)
            {
                cairo_device_destroy(this.nativePointer);
                debug
                    this.nativePointer = null;
                _disposed = true;
            }
        }
}

public class Surface
{
    private:
        bool _disposed;

    protected:
        void checkError()
        {
            throwError(cairo_surface_status(nativePointer));
        }
    
    public:
        cairo_surface_t* nativePointer;

        /* Warning: ptr reference count is not increased by this function!
         * Adjust reference count before calling it if necessary*/
        this(cairo_surface_t* ptr)
        {
            this.nativePointer = ptr;
            if(!ptr)
            {
                throw new CairoException(cairo_status_t.CAIRO_STATUS_NULL_POINTER);
            }
            checkError();
        }

        ~this()
        {
            dispose();
        }

        void dispose()
        {
            if(!_disposed)
            {
                cairo_surface_destroy(this.nativePointer);
                debug
                    this.nativePointer = null;
                _disposed = true;
            }
        }

        static Surface castFrom(Surface other)
        {
            return other;
        }
        
        T opCast(T)() if(isImplicitlyConvertible!(T, Surface))
        {
            return T.castFrom(this);
        }
        
        static Surface createFromNative(cairo_surface_t* ptr, bool adjRefCount = true)
        {
            if(!ptr)
            {
                throw new CairoException(cairo_status_t.CAIRO_STATUS_NULL_POINTER);
            }
            throwError(cairo_surface_status(ptr));
            //Adjust reference count
            if(adjRefCount)
                cairo_surface_reference(ptr);
            switch(cairo_surface_get_type(ptr))
            {
                case cairo_surface_type_t.CAIRO_SURFACE_TYPE_IMAGE:
                    return new ImageSurface(ptr);
                version(CAIRO_HAS_PS_SURFACE)
                {
                    case cairo_surface_type_t.CAIRO_SURFACE_TYPE_PS:
                        return new PSSurface(ptr);
                }
                version(CAIRO_HAS_PDF_SURFACE)
                {
                    case cairo_surface_type_t.CAIRO_SURFACE_TYPE_PDF:
                        return new PDFSurface(ptr);
                }
                version(CAIRO_HAS_SVG_SURFACE)
                {
                    case cairo_surface_type_t.CAIRO_SURFACE_TYPE_SVG:
                        return new SVGSurface(ptr);
                }
                version(CAIRO_HAS_WIN32_SURFACE)
                {
                    case cairo_surface_type_t.CAIRO_SURFACE_TYPE_WIN32:
                        return new Win32Surface(ptr);
                    case cairo_surface_type_t.CAIRO_SURFACE_TYPE_WIN32_PRINTING:
                        return new Win32Surface(ptr);
                }
                version(CAIRO_HAS_XCB_SURFACE)
                {
                    case cairo_surface_type_t.CAIRO_SURFACE_TYPE_XCB:
                        return new XCBSurface(ptr);
                }
                version(CAIRO_HAS_DIRECTFB_SURFACE)
                {
                    case cairo_surface_type_t.CAIRO_SURFACE_TYPE_DIRECTFB:
                        return new DirectFBSurface(ptr);
                }
                default:
                    return new Surface(ptr);
            }
        }
        
        static Surface createSimilar(Surface other, Content content, int width, int height)
        {
            return createFromNative(cairo_surface_create_similar(other.nativePointer, content, width, height), false);
        }
        
        static Surface createForRectangle(Surface target, Rectangle rect)
        {
            return createFromNative(cairo_surface_create_for_rectangle(target.nativePointer,
                rect.point.x, rect.point.y, rect.width, rect.height), false);
        }
        
        void finish()
        {
            cairo_surface_finish(this.nativePointer);
            checkError();
        }
        
        void flush()
        {
            cairo_surface_flush(this.nativePointer);
            checkError();
        }
        
        Device getDevice()
        {
            auto ptr = cairo_surface_get_device(this.nativePointer);
            if(!ptr)
                return null;
            cairo_device_reference(ptr);
            return new Device(ptr);
        }
        
        FontOptions getFontOptions()
        {
            FontOptions fo = FontOptions();
            cairo_surface_get_font_options(this.nativePointer, fo.p.nativePointer);
            fo.checkError();
            return fo;
        }
        
        Content getContent()
        {
            scope(exit)
                checkError();
            return cairo_surface_get_content(this.nativePointer);
        }
        
        void markDirty()
        {
            cairo_surface_mark_dirty(this.nativePointer);
            checkError();
        }
        
        void markDirtyRectangle(int x, int y, int width, int height)
        {
            cairo_surface_mark_dirty_rectangle(this.nativePointer, x, y, width, height);
            checkError();
        }
        
        void setDeviceOffset(Point offset)
        {
            cairo_surface_set_device_offset(this.nativePointer, offset.x, offset.y);
            checkError();
        }
        
        Point getDeviceOffset()
        {
            Point tmp;
            cairo_surface_get_device_offset(this.nativePointer, &tmp.x, &tmp.y);
            checkError();
            return tmp;
        }
        
        void setFallbackResolution(Resolution res)
        {
            cairo_surface_set_fallback_resolution(this.nativePointer, res.x, res.y);
            checkError();
        }
        
        Resolution getFallbackResolution()
        {
            Resolution res;
            cairo_surface_get_fallback_resolution(this.nativePointer, &res.x, &res.y);
            checkError();
            return res;
        }
        
        SurfaceType getType()
        {
            scope(exit)
                checkError();
            return cairo_surface_get_type(this.nativePointer);
        }

        /*
        void setUserData(const cairo_user_data_key_t* key, void* data, cairo_destroy_func_t destroy)
        {
            cairo_surface_set_user_data(this.nativePointer, key, data, destroy);
            checkError();
        }
        
        void* getUserData(const cairo_user_data_key_t* key)
        {
            scope(exit)
                checkError();
            return cairo_surface_get_user_data(this.nativePointer, key);
        }*/
        
        void copyPage()
        {
            cairo_surface_copy_page(this.nativePointer);
            checkError();
        }
        
        void showPage()
        {
            cairo_surface_show_page(this.nativePointer);
            checkError();
        }
        
        bool hasShowTextGlyphs()
        {
            scope(exit)
                checkError();
            return cairo_surface_has_show_text_glyphs(this.nativePointer) ? true : false;
        }
        
        //TODO: make this better
        void setMimeData(string type, ubyte* data, ulong length, cairo_destroy_func_t destroy, void* closure)
        {
            throwError(cairo_surface_set_mime_data(this.nativePointer, toStringz(type),
                data, length, destroy, closure));
        }
        
        //TODO: make this better
        void getMimeData(string type, out ubyte* data, out ulong length)
        {
            cairo_surface_get_mime_data(this.nativePointer, toStringz(type), &data, &length);
            checkError();
        }
}

public class ImageSurface : Surface
{
    //need to keep this around to prevent the GC from collecting it
    protected ubyte[] _data;
    
    public:
        /* Warning: ptr reference count is not increased by this function!
         * Adjust reference count before calling it if necessary*/
        this(cairo_surface_t* ptr)
        {
            super(ptr);
        }
        
        this(Format format, int width, int height)
        {
            super(cairo_image_surface_create(format, width, height));
        }
        this(ubyte[] data, Format format, int width, int height, int stride)
        {
            this._data = data;
            super(cairo_image_surface_create_for_data(data.ptr, format, width, height, stride));
        }
        
        static ImageSurface castFrom(Surface other)
        {
            if(!other.nativePointer)
            {
                throw new CairoException(cairo_status_t.CAIRO_STATUS_NULL_POINTER);
            }
            auto type = cairo_surface_get_type(other.nativePointer);
            throwError(cairo_surface_status(other.nativePointer));
            if(type == cairo_surface_type_t.CAIRO_SURFACE_TYPE_IMAGE)
            {
                cairo_surface_reference(other.nativePointer);
                return new ImageSurface(other.nativePointer);
            }
            else
                return null;
        }
        
        ubyte* getData()
        {
            scope(exit)
                checkError();
            return cairo_image_surface_get_data(this.nativePointer);
        }
        
        Format getFormat()
        {
            scope(exit)
                checkError();
            return cairo_image_surface_get_format(this.nativePointer);
        }
        
        int getWidth()
        {
            scope(exit)
                checkError();
            return cairo_image_surface_get_width(this.nativePointer);
        }
        
        int getHeight()
        {
            scope(exit)
                checkError();
            return cairo_image_surface_get_height(this.nativePointer);
        }
        
        int getStride()
        {
            scope(exit)
                checkError();
            return cairo_image_surface_get_stride(this.nativePointer);
        }
        
        version(CAIRO_HAS_PNG_FUNCTIONS)
        {
            static ImageSurface fromPng(string file)
            {
                return new ImageSurface(cairo_image_surface_create_from_png(toStringz(file)));
            }
            //TODO: fromPNGStream when phobos gets new streaming api
            void writeToPNG(string file)
            {
                throwError(cairo_surface_write_to_png(this.nativePointer, toStringz(file)));
            }
            //TODO: toPNGStream when phobos gets new streaming api
        }
}

public struct Context
{
    private:
        struct Impl
        {
            cairo_t* nativePointer;
            uint refs = uint.max / 2;
            this(cairo_t* np, uint r)
            {
                nativePointer = np;
                refs = r;
            }
        }
        Impl* p;
    
        void close()
        {
            if (!p) return; // succeed vacuously
            if (!p.nativePointer)
            {
                p = null; // start a new life
                return;
            }

            cairo_destroy(p.nativePointer);
            p.nativePointer = null; // nullify the handle anyway
            --p.refs;
            p = null;
        }

        @property cairo_t* nativePointer()
        {
            return this.p.nativePointer;
        }

        void checkError()
        {
            throwError(cairo_status(p.nativePointer));
        }
        
    
    public:
        this(Surface target)
        {
            auto ptr = cairo_create(target.nativePointer);
            throwError(cairo_status(ptr));
            p = new Impl(ptr, 1);
        }

        ~this()
        {
            if (!p) return;
            if (p.refs == 1) close;
            else --p.refs;
        }
        
        this(this)
        {
            if (!p) return;
            assert(p.refs);
            ++p.refs;
        }

        void opAssign(Context rhs)
        {
            p = rhs.p;
        }
        
        void save()
        {
            cairo_save(this.nativePointer);
            checkError();
        }
        
        void restore()
        {
            cairo_restore(this.nativePointer);
            checkError();
        }
        
        Surface getTarget()
        {
            return Surface.createFromNative(cairo_get_target(this.nativePointer));
        }
        
        void pushGroup()
        {
            cairo_push_group(this.nativePointer);
            checkError();
        }
        
        void pushGroup(Content cont)
        {
            cairo_push_group_with_content(this.nativePointer, cont);
            checkError();
        }
        
        void popGroup()
        {
            cairo_pop_group(this.nativePointer);
            checkError();
        }
        
        void popGroupToSource()
        {
            cairo_pop_group_to_source(this.nativePointer);
            checkError();
        }
        
        Surface getGroupTarget()
        {
            return Surface.createFromNative(cairo_get_group_target(this.nativePointer));
        }
        
        void setSourceRGB(double red, double green, double blue)
        {
            cairo_set_source_rgb(this.nativePointer, red, green, blue);
            checkError();
        }

        void setSourceRGB(RGB rgb)
        {
            cairo_set_source_rgb(this.nativePointer, rgb.red, rgb.green, rgb.blue);
            checkError();
        }
        
        void setSourceRGBA(double red, double green, double blue, double alpha)
        {
            cairo_set_source_rgba(this.nativePointer, red, green, blue, alpha);
            checkError();
        }

        void setSourceRGBA(RGBA rgba)
        {
            cairo_set_source_rgba(this.nativePointer, rgba.red, rgba.green, rgba.blue, rgba.alpha);
            checkError();
        }
        
        void setSource(Pattern pat)
        {
            cairo_set_source(this.nativePointer, pat.nativePointer);
            checkError();
        }
        
        void setSourceSurface(Surface sur, double x, double y)
        {
            cairo_set_source_surface(this.nativePointer, sur.nativePointer, x, y);
            checkError();
        }
        
        Pattern getSource()
        {
            return Pattern.createFromNative(cairo_get_source(this.nativePointer));
        }
        
        void setAntiAlias(AntiAlias antialias)
        {
            cairo_set_antialias(this.nativePointer, antialias);
            checkError();
        }
        
        AntiAlias getAntiAlias()
        {
            scope(exit)
                checkError();
            return cairo_get_antialias(this.nativePointer);
        }
        
        void setDash(const(double[]) dashes, double offset)
        {
            cairo_set_dash(this.nativePointer, dashes.ptr, dashes.length, offset);
            checkError();
        }
        
        int getDashCount()
        {
            scope(exit)
                checkError();
            return cairo_get_dash_count(this.nativePointer);
        }
        
        double[] getDash(out double offset)
        {
            double[] dashes;
            dashes.length = this.getDashCount();
            cairo_get_dash(this.nativePointer, dashes.ptr, &offset);
            checkError();
            return dashes;
        }
        
        void setFillRule(FillRule rule)
        {
            cairo_set_fill_rule(this.nativePointer, rule);
            checkError();
        }
        
        FillRule getFillRule()
        {
            scope(exit)
                checkError();
            return cairo_get_fill_rule(this.nativePointer);
        }
        
        void setLineCap(LineCap cap)
        {
            cairo_set_line_cap(this.nativePointer, cap);
            checkError();
        }
        
        LineCap getLineCap()
        {
            scope(exit)
                checkError();
            return cairo_get_line_cap(this.nativePointer);
        }
        
        void setLineJoin(LineJoin join)
        {
            cairo_set_line_join(this.nativePointer, join);
            checkError();
        }
        
        LineJoin getLineJoin()
        {
            scope(exit)
                checkError();
            return cairo_get_line_join(this.nativePointer);
        }
        
        void setLineWidth(double width)
        {
            cairo_set_line_width(this.nativePointer, width);
            checkError();
        }
        
        double getLineWidth()
        {
            scope(exit)
                checkError();
            return cairo_get_line_width(this.nativePointer);
        }
        
        void setMiterLimit(double limit)
        {
            cairo_set_miter_limit(this.nativePointer, limit);
            checkError();
        }
        
        double getMiterLimit()
        {
            scope(exit)
                checkError();
            return cairo_get_miter_limit(this.nativePointer);
        }
        
        void setOperator(Operator op)
        {
            cairo_set_operator(this.nativePointer, op);
            checkError();
        }
        
        Operator getOperator()
        {
            scope(exit)
                checkError();
            return cairo_get_operator(this.nativePointer);
        }
        
        void setTolerance(double tolerance)
        {
            cairo_set_tolerance(this.nativePointer, tolerance);
            checkError();
        }
        
        double getTolerance()
        {
            scope(exit)
                checkError();
            return cairo_get_tolerance(this.nativePointer);
        }
        
        void clip()
        {
            cairo_clip(this.nativePointer);
            checkError();
        }
        
        void clipPreserve()
        {
            cairo_clip_preserve(this.nativePointer);
            checkError();
        }
        
        Box clipExtents()
        {
            Box tmp;
            cairo_clip_extents(this.nativePointer, &tmp.point1.x, &tmp.point1.y, &tmp.point2.x, &tmp.point2.y);
            checkError();
            return tmp;
        }
        
        bool inClip(Point point)
        {
            scope(exit)
                checkError();
            return cairo_in_clip(this.nativePointer, point.x, point.y) ? true : false;
        }
        
        void resetClip()
        {
            cairo_reset_clip(this.nativePointer);
            checkError();
        }
        
        Rectangle[] copyClipRectangles()
        {
            Rectangle[] list;
            auto nList = cairo_copy_clip_rectangle_list(this.nativePointer);
            scope(exit)
                cairo_rectangle_list_destroy(nList);
            checkError();
            list.length = nList.num_rectangles;
            for(int i = 0; i < list.length; i++)
            {
                list[i].point.x = nList.rectangles[i].x;
                list[i].point.y = nList.rectangles[i].y;
                list[i].width = nList.rectangles[i].width;
                list[i].height = nList.rectangles[i].height;
            }
            return list;
        }
        
        void fill()
        {
            cairo_fill(this.nativePointer);
            checkError();
        }
        
        void fillPreserve()
        {
            cairo_fill_preserve(this.nativePointer);
            checkError();
        }
        
        Box fillExtends()
        {
            Box tmp;
            cairo_fill_extents(this.nativePointer, &tmp.point1.x, &tmp.point1.y, &tmp.point2.x, &tmp.point2.y);
            checkError();
            return tmp;
        }
        
        bool inFill(Point point)
        {
            scope(exit)
                checkError();
            return cairo_in_fill(this.nativePointer, point.x, point.y) ? true : false;
        }
        
        void mask(Pattern pattern)
        {
            cairo_mask(this.nativePointer, pattern.nativePointer);
            checkError();
        }
        
        void maskSurface(Surface surface, Point location)
        {
            cairo_mask_surface(this.nativePointer, surface.nativePointer, location.x, location.y);
            checkError();
        }
        
        void paint()
        {
            cairo_paint(this.nativePointer);
            checkError();
        }
        
        void paintWithAlpha(double alpha)
        {
            cairo_paint_with_alpha(this.nativePointer, alpha);
            checkError();
        }
        
        void stroke()
        {
            cairo_stroke(this.nativePointer);
            checkError();
        }
        
        void strokePreserve()
        {
            cairo_stroke_preserve(this.nativePointer);
            checkError();
        }
        
        Box strokeExtends()
        {
            Box tmp;
            cairo_stroke_extents(this.nativePointer, &tmp.point1.x, &tmp.point1.y, &tmp.point2.x, &tmp.point2.y);
            checkError();
            return tmp;
        }
        
        bool inStroke(Point point)
        {
            scope(exit)
                checkError();
            return cairo_in_stroke(this.nativePointer, point.x, point.y) ? true : false;
        }
        
        void copyPage()
        {
            cairo_copy_page(this.nativePointer);
            checkError();
        }
        
        void showPage()
        {
            cairo_show_page(this.nativePointer);
            checkError();
        }
        
        uint getReferenceCount()
        {
            scope(exit)
                checkError();
            return cairo_get_reference_count(this.nativePointer);
        }
        
        void setUserData(const cairo_user_data_key_t* key, void* data, cairo_destroy_func_t destroy)
        {
            cairo_set_user_data(this.nativePointer, key, data, destroy);
            checkError();
        }
        
        void* getUserData(const cairo_user_data_key_t* key)
        {
            scope(exit)
                checkError();
            return cairo_get_user_data(this.nativePointer, key);
        }
        
        Path copyPath()
        {
            return Path(cairo_copy_path(this.nativePointer));
        }
        
        Path copyPathFlat()
        {
            return Path(cairo_copy_path_flat(this.nativePointer));
        }
        
        void appendPath(T)(T path) if (is(T == PathRange))
        {
            cairo_append_path(this.nativePointer, path.path.p.path);
            checkError();
        }
        
        bool hasCurrentPoint()
        {
            scope(exit)
                checkError();
            return cairo_has_current_point(this.nativePointer) ? true : false;
        }
        
        Point getCurrentPoint()
        {
            Point tmp;
            cairo_get_current_point(this.nativePointer, &tmp.x, &tmp.y);
            checkError();
            return tmp;
        }
        
        void newPath()
        {
            cairo_new_path(this.nativePointer);
            checkError();
        }
        
        void newSubPath()
        {
            cairo_new_sub_path(this.nativePointer);
            checkError();
        }
        
        void closePath()
        {
            cairo_close_path(this.nativePointer);
            checkError();
        }
        
        void arc(Point center, double radius, double angle1, double angle2)
        {
            cairo_arc(this.nativePointer, center.x, center.y, radius, angle1, angle2);
            checkError();
        }
        
        void arcNegative(Point center, double radius, double angle1, double angle2)
        {
            cairo_arc_negative(this.nativePointer, center.x, center.y, radius, angle1, angle2);
            checkError();
        }
        
        void curveTo(Point p1, Point p2, Point p3)
        {
            cairo_curve_to(this.nativePointer, p1.x, p1.y, p2.x, p2.y, p3.x, p3.y);
            checkError();
        }
        
        void lineTo(Point p1)
        {
            cairo_line_to(this.nativePointer, p1.x, p1.y);
            checkError();
        }
        
        void moveTo(Point p1)
        {
            cairo_move_to(this.nativePointer, p1.x, p1.y);
            checkError();
        }
        
        void rectangle(Rectangle r)
        {
            cairo_rectangle(this.nativePointer, r.point.x, r.point.y, r.width, r.height);
            checkError();
        }
        
        void glyphPath(Glyph[] glyphs)
        {
            cairo_glyph_path(this.nativePointer, glyphs.ptr, glyphs.length);
            checkError();
        }

        void textPath(string text)
        {
            cairo_text_path(this.nativePointer, toStringz(text));
            checkError();
        }
        
        void relCurveTo(Point rp1, Point rp2, Point rp3)
        {
            cairo_rel_curve_to(this.nativePointer, rp1.x, rp1.y, rp2.x, rp2.y, rp3.x, rp3.y);
            checkError();
        }
        
        void relLineTo(Point rp1)
        {
            cairo_rel_line_to(this.nativePointer, rp1.x, rp1.y);
            checkError();
        }
        
        void relMoveTo(Point rp1)
        {
            cairo_rel_move_to(this.nativePointer, rp1.x, rp1.y);
            checkError();
        }
        
        Box pathExtends()
        {
            Box tmp;
            cairo_path_extents(this.nativePointer, &tmp.point1.x, &tmp.point1.y, &tmp.point2.x, &tmp.point2.y);
            checkError();
            return tmp;
        }
        
        void translate(double tx, double ty)
        {
            cairo_translate(this.nativePointer, tx, ty);
            checkError();
        }
        
        void scale(double sx, double sy)
        {
            cairo_scale(this.nativePointer, sx, sy);
            checkError();
        }
        
        void rotate(double angle)
        {
            cairo_rotate(this.nativePointer, angle);
            checkError();
        }
        
        void transform(const Matrix matrix)
        {
            cairo_transform(this.nativePointer, &matrix.nativeMatrix);
            checkError();
        }
        
        void setMatrix(const Matrix matrix)
        {
            cairo_set_matrix(this.nativePointer, &matrix.nativeMatrix);
            checkError();
        }
        
        Matrix getMatrix()
        {
            Matrix m;
            cairo_get_matrix(this.nativePointer, &m.nativeMatrix);
            checkError();
            return m;
        }
        
        void identityMatrix()
        {
            cairo_identity_matrix(this.nativePointer);
            checkError();
        }
        
        Point userToDevice(Point inp)
        {
            cairo_user_to_device(this.nativePointer, &inp.x, &inp.y);
            checkError();
            return inp;
        }
        
        Point userToDeviceDistance(Point inp)
        {
            cairo_user_to_device_distance(this.nativePointer, &inp.x, &inp.y);
            checkError();
            return inp;
        }
        
        Point deviceToUser(Point inp)
        {
            cairo_device_to_user(this.nativePointer, &inp.x, &inp.y);
            checkError();
            return inp;
        }
        
        Point deviceToUserDistance(Point inp)
        {
            cairo_device_to_user_distance(this.nativePointer, &inp.x, &inp.y);
            checkError();
            return inp;
        }

        void selectFontFace(string family, FontSlant slant, FontWeight weight)
        {
            cairo_select_font_face(this.nativePointer, toStringz(family), slant, weight);
            checkError();
        }

        void setFontSize(double size)
        {
            cairo_set_font_size(this.nativePointer, size);
            checkError();
        }

        void setFontMatrix(Matrix matrix)
        {
            cairo_set_font_matrix(this.nativePointer, &matrix.nativeMatrix);
            checkError();
        }

        Matrix getFontMatrix()
        {
            Matrix res;
            cairo_get_font_matrix(this.nativePointer, &res.nativeMatrix);
            checkError();
            return res;
        }

        void setFontOptions(FontOptions options)
        {
            cairo_set_font_options(this.nativePointer, options.nativePointer);
            checkError();
        }

        FontOptions getFontOptions()
        {
            auto opt = FontOptions();
            cairo_get_font_options(this.nativePointer, opt.nativePointer);
            checkError();
            return opt;
        }

        void setFontFace()
        {
            cairo_set_font_face(this.nativePointer, null);
            checkError();
        }

        void setFontFace(FontFace font_face)
        {
            cairo_set_font_face(this.nativePointer, font_face.nativePointer);
            checkError();
        }

        FontFace getFontFace()
        {
            return FontFace.createFromNative(cairo_get_font_face(this.nativePointer));
        }

        void setScaledFont(ScaledFont scaled_font)
        {
            cairo_set_scaled_font(this.nativePointer, scaled_font.nativePointer);
            checkError();
        }

        ScaledFont getScaledFont()
        {
            return ScaledFont.createFromNative(cairo_get_scaled_font(this.nativePointer));
        }

        void showText(string text)
        {
            cairo_show_text(this.nativePointer, toStringz(text));
            checkError();
        }

        void showGlyphs(Glyph[] glyphs)
        {
            cairo_show_glyphs(this.nativePointer, glyphs.ptr, glyphs.length);
            checkError();
        }

        void showTextGlyphs(TextGlyph glyph)
        {
            cairo_show_text_glyphs(this.nativePointer, glyph.text.ptr,
                glyph.text.length, glyph.glyphs.ptr, glyph.glyphs.length,
                glyph.cluster.ptr, glyph.cluster.length, glyph.flags);
            checkError();
        }

        FontExtents fontExtents()
        {
            FontExtents res;
            cairo_font_extents(this.nativePointer, &res);
            checkError();
            return res;
        }

        TextExtents textExtents(string text)
        {
            TextExtents res;
            cairo_text_extents(this.nativePointer, toStringz(text), &res);
            checkError();
            return res;
        }

        TextExtents glyphExtents(Glyph[] glyphs)
        {
            TextExtents res;
            cairo_glyph_extents(this.nativePointer, glyphs.ptr, glyphs.length, &res);
            checkError();
            return res;
        }
}

/* ------------------------------- Fonts ------------------------------ */

/**
 * Warning: Instances must be created with opCall!
 * Correct:
 * --------
 * auto options = FontOptions();
 * --------
 * Wrong:
 * --------
 * FontOptions options;
 * --------
 */
public struct FontOptions
{
    private:
        struct Impl
        {
            cairo_font_options_t* nativePointer;
            uint refs = uint.max / 2;
            this(cairo_font_options_t* np, uint r)
            {
                nativePointer = np;
                refs = r;
            }
        }
        Impl* p;
    
        void close()
        {
            if (!p) return; // succeed vacuously
            if (!p.nativePointer)
            {
                p = null; // start a new life
                return;
            }
            cairo_font_options_destroy(p.nativePointer);
            p.nativePointer = null; // nullify the handle anyway
            --p.refs;
            p = null;
        }

        @property nativePointer()
        {
            return p.nativePointer;
        }
        
        void checkError()
        {
            throwError(cairo_font_options_status(p.nativePointer));
        }
    
    public:
        static FontOptions opCall()
        {
            FontOptions opt;
            auto ptr = cairo_font_options_create();
            throwError(cairo_font_options_status(ptr));
            opt.p = new Impl(ptr, 1);
            return opt;
        }

        this(cairo_font_options_t* ptr)
        {
            if(!ptr)
            {
                throw new CairoException(cairo_status_t.CAIRO_STATUS_NULL_POINTER);
            }
            throwError(cairo_font_options_status(ptr));
            p = new Impl(ptr, 1);
        }

        ~this()
        {
            if (!p) return;
            if (p.refs == 1) close;
            else --p.refs;
        }
        
        this(this)
        {
            if (!p) return;
            assert(p.refs);
            ++p.refs;
        }

        void opAssign(FontOptions rhs)
        {
            p = rhs.p;
        }

        FontOptions copy()
        {
            return FontOptions(cairo_font_options_copy(this.p.nativePointer));
        }
        
        void merge(FontOptions other)
        {
            cairo_font_options_merge(this.p.nativePointer, other.p.nativePointer);
            checkError();
        }
        
        //TODO: how to merge that with toHash?
        ulong hash()
        {
            ulong hash = cairo_font_options_hash(this.p.nativePointer);
            checkError();
            return hash;
        }
        
        const bool opEquals(ref const(FontOptions) other)
        {
            return cairo_font_options_equal(this.p.nativePointer, other.p.nativePointer) ? true : false;
        }
        
        void setAntiAlias(AntiAlias antialias)
        {
            cairo_font_options_set_antialias(this.p.nativePointer, antialias);
            checkError();
        }
        
        AntiAlias getAntiAlias()
        {
            scope(exit)
                checkError();
            return cairo_font_options_get_antialias(this.p.nativePointer);
        }
        
        void setSubpixelOrder(SubpixelOrder order)
        {
            cairo_font_options_set_subpixel_order(this.p.nativePointer, order);
            checkError();
        }
        
        SubpixelOrder getSubpixelOrder()
        {
            scope(exit)
                checkError();
            return cairo_font_options_get_subpixel_order(this.p.nativePointer);
        }
        
        void setHintStyle(HintStyle style)
        {
            cairo_font_options_set_hint_style(this.p.nativePointer, style);
            checkError();
        }
        
        HintStyle getHintStyle()
        {
            scope(exit)
                checkError();
            return cairo_font_options_get_hint_style(this.p.nativePointer);
        }
        
        void setHintMetrics(HintMetrics metrics)
        {
            cairo_font_options_set_hint_metrics(this.p.nativePointer, metrics);
            checkError();
        }
        
        HintMetrics getHintMetrics()
        {
            scope(exit)
                checkError();
            return cairo_font_options_get_hint_metrics(this.p.nativePointer);
        }
}

public struct TextGlyph
{
    public:
        Glyph[] glyphs;
        TextCluster[] cluster;
        string text;
        TextClusterFlags flags;
}

public class ScaledFont
{
    private:
        cairo_scaled_font_t* nativePointer;
        bool _disposed = false;

        void checkError()
        {
            throwError(cairo_scaled_font_status(nativePointer));
        }

    public:
        /* Warning: ptr reference count is not increased by this function!
         * Adjust reference count before calling it if necessary*/
        this(cairo_scaled_font_t* ptr)
        {
            this.nativePointer = ptr;
            checkError();
        }

        this(FontFace font_face, Matrix font_matrix, Matrix ctm,
             FontOptions options)
        {
            this.nativePointer = cairo_scaled_font_create(font_face.nativePointer,
                &font_matrix.nativeMatrix, &ctm.nativeMatrix, options.nativePointer);
            checkError();
        }

        ~this()
        {
            dispose();
        }

        void dispose()
        {
            if(!_disposed)
            {
                cairo_scaled_font_destroy(this.nativePointer);
                debug
                    this.nativePointer = null;
                _disposed = true;
            }
        }

        static ScaledFont createFromNative(cairo_scaled_font_t* ptr, bool adjRefCount = true)
        {
            if(!ptr)
            {
                throw new CairoException(cairo_status_t.CAIRO_STATUS_NULL_POINTER);
            }
            throwError(cairo_scaled_font_status(ptr));
            //Adjust reference count
            if(adjRefCount)
                cairo_scaled_font_reference(ptr);
            switch(cairo_scaled_font_get_type(ptr))
            {
                version(CAIRO_HAS_WIN32_FONT)
                {
                    case cairo_font_type_t.CAIRO_FONT_TYPE_WIN32:
                        return new Win32ScaledFont(ptr);
                }
                default:
                    return new ScaledFont(ptr);
            }
        }

        FontExtents extents()
        {
            FontExtents res;
            cairo_scaled_font_extents(this.nativePointer, &res);
            checkError();
            return res;
        }

        TextExtents textExtents(string text)
        {
            TextExtents res;
            cairo_scaled_font_text_extents(this.nativePointer, toStringz(text),
                &res);
            checkError();
            return res;
        }

        TextExtents glyphExtents(Glyph[] glyphs)
        {
            TextExtents res;
            cairo_scaled_font_glyph_extents(this.nativePointer, glyphs.ptr,
                glyphs.length, &res);
            checkError();
            return res;
        }

        Glyph[] textToGlyphs(double x, double y, string text, Glyph[] glyphBuffer = [])
        {
            Glyph* gPtr = null;
            int gLen = 0;
            if(glyphBuffer.length != 0)
            {
                gPtr = glyphBuffer.ptr;
                gLen = glyphBuffer.length;
            }

            throwError(cairo_scaled_font_text_to_glyphs(this.nativePointer, x, y,
                text.ptr, text.length, &gPtr, &gLen, null, null, null));

            if(gPtr == glyphBuffer.ptr)
            {
                return glyphBuffer[0 .. gLen];
            }
            else
            {
                Glyph[] gCopy = gPtr[0 .. gLen].dup;
                cairo_glyph_free(gPtr);
                return gCopy;
            }
        }
        
        TextGlyph textToTextGlyph(double x, double y, string text, Glyph[] glyphBuffer = [],
            TextCluster[] clusterBuffer = [])
        {
            TextGlyph res;

            Glyph* gPtr = null;
            int gLen = 0;
            TextCluster* cPtr = null;
            int cLen = 0;
            TextClusterFlags cFlags;
            if(glyphBuffer.length != 0)
            {
                gPtr = glyphBuffer.ptr;
                gLen = glyphBuffer.length;
            }
            if(clusterBuffer.length != 0)
            {
                cPtr = clusterBuffer.ptr;
                cLen = clusterBuffer.length;
            }

            throwError(cairo_scaled_font_text_to_glyphs(this.nativePointer, x, y,
                text.ptr, text.length, &gPtr, &gLen, &cPtr, &cLen, &cFlags));

            if(gPtr == glyphBuffer.ptr)
            {
                res.glyphs = glyphBuffer[0 .. gLen];
            }
            else
            {
                res.glyphs = gPtr[0 .. gLen].dup;
                cairo_glyph_free(gPtr);
            }
            if(cPtr == clusterBuffer.ptr)
            {
                res.cluster = clusterBuffer[0 .. cLen];
            }
            else
            {
                res.cluster = cPtr[0 .. cLen].dup;
                cairo_text_cluster_free(cPtr);
            }

            res.text = text;
            res.flags = cFlags;
            return res;
        }

        FontFace getFontFace()
        {
            auto face = cairo_scaled_font_get_font_face(this.nativePointer);
            checkError();
            return FontFace.createFromNative(face);
        }

        FontOptions getFontOptions()
        {
            //TODO: verify if this is correct
            FontOptions fo = FontOptions();
            cairo_scaled_font_get_font_options(this.nativePointer, fo.nativePointer);
            checkError();
            return fo;
        }

        Matrix getFontMatrix()
        {
            Matrix mat;
            cairo_scaled_font_get_font_matrix(this.nativePointer, &mat.nativeMatrix);
            checkError();
            return mat;
        }

        Matrix getCTM()
        {
            Matrix mat;
            cairo_scaled_font_get_ctm(this.nativePointer, &mat.nativeMatrix);
            checkError();
            return mat;
        }

        Matrix getScaleMatrix()
        {
            Matrix mat;
            cairo_scaled_font_get_scale_matrix(this.nativePointer, &mat.nativeMatrix);
            checkError();
            return mat;
        }
}

public class FontFace
{
    protected:
        cairo_font_face_t* nativePointer;
        bool _disposed = false;

        void checkError()
        {
            throwError(cairo_font_face_status(nativePointer));
        }

    public:
        /* Warning: ptr reference count is not increased by this function!
         * Adjust reference count before calling it if necessary*/
        this(cairo_font_face_t* ptr)
        {
            this.nativePointer = ptr;
            checkError();
        }

        ~this()
        {
            dispose();
        }

        void dispose()
        {
            if(!_disposed)
            {
                cairo_font_face_destroy(this.nativePointer);
                debug
                    this.nativePointer = null;
                _disposed = true;
            }
        }

        static FontFace createFromNative(cairo_font_face_t* ptr, bool adjRefCount = true)
        {
            if(!ptr)
            {
                throw new CairoException(cairo_status_t.CAIRO_STATUS_NULL_POINTER);
            }
            throwError(cairo_font_face_status(ptr));
            //Adjust reference count
            if(adjRefCount)
                cairo_font_face_reference(ptr);
            switch(cairo_font_face_get_type(ptr))
            {
                case cairo_font_type_t.CAIRO_FONT_TYPE_TOY:
                    return new ToyFontFace(ptr);
                version(CAIRO_HAS_WIN32_FONT)
                {
                    case cairo_font_type_t.CAIRO_FONT_TYPE_WIN32:
                        return new Win32FontFace(ptr);
                }
                default:
                    return new FontFace(ptr);
            }
        }
}

public class ToyFontFace : FontFace
{
    public:
        /* Warning: ptr reference count is not increased by this function!
         * Adjust reference count before calling it if necessary*/
        this(cairo_font_face_t* ptr)
        {
            super(ptr);
        }

        this(string family, FontSlant slant, FontWeight weight)
        {
            super(cairo_toy_font_face_create(toStringz(family), slant, weight));
        }

        string getFamily()
        {
            auto ptr = cairo_toy_font_face_get_family(this.nativePointer);
            checkError();
            return to!string(ptr);
        }

        FontSlant getSlant()
        {
            auto res = cairo_toy_font_face_get_slant(this.nativePointer);
            checkError();
            return res;
        }

        FontWeight getWeight()
        {
            auto res = cairo_toy_font_face_get_weight(this.nativePointer);
            checkError();
            return res;
        }
}

public struct Version
{
    public uint Major, Minor, Micro;

    public this(int encoded)
    {
        this.Major = encoded / 10000;
        this.Minor = (encoded % 10000) / 100;
        this.Micro = (encoded % 10000) % 100;
    }
}
