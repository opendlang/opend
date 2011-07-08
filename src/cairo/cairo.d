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

public struct PathRange
{
    private:
        cairo_path_t* path;
        int pos = 0;
    
    public:
        this(cairo_path_t* path)
        {
            this.path = path;
            throwError(path.status);
        }
        
        //TODO: Refcounting? & cairo_path_destroy()
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
        
        //TODO: find a better way?
        void transformDistance(ref Point dist)
        {
            cairo_matrix_transform_distance(&this.nativeMatrix, &dist.x, &dist.y);
        }
        
        void transformPoint(ref Point point)
        {
            cairo_matrix_transform_point(&this.nativeMatrix, &point.x, &point.y);
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
    private:
        void checkError()
        {
            throwError(cairo_pattern_status(nativePointer));
        }
    
    public:
        cairo_pattern_t* nativePointer;
        
        this(cairo_pattern_t* ptr)
        {
            this.nativePointer = ptr;
            if(!ptr)
            {
                throw new CairoException(cairo_status_t.CAIRO_STATUS_NULL_POINTER);
            }
            checkError();
        }
        
        static Pattern createFromNative(cairo_pattern_t* ptr)
        {
            if(!ptr)
            {
                throw new CairoException(cairo_status_t.CAIRO_STATUS_NULL_POINTER);
            }
            throwError(cairo_pattern_status(ptr));
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
        
        void reference()
        {
            cairo_pattern_reference(this.nativePointer);
            checkError();
        }
        
        void destroy()
        {
            cairo_pattern_destroy(this.nativePointer);
            checkError();
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
        this(cairo_pattern_t* ptr)
        {
            super(ptr);
        }
        
        static SolidPattern fromRGB(double red, double green, double blue)
        {
            return new SolidPattern(cairo_pattern_create_rgb(red, green, blue));
        }
        
        static SolidPattern fromRGBA(double red, double green, double blue, double alpha)
        {
            return new SolidPattern(cairo_pattern_create_rgba(red, green, blue, alpha));
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

public class FontOptions
{
    private:
        void checkError()
        {
            throwError(cairo_font_options_status(nativePointer));
        }
    
    public:
        cairo_font_options_t* nativePointer;
        
        this()
        {
            this.nativePointer = cairo_font_options_create();
            checkError();
        }
        
        this(cairo_font_options_t* ptr)
        {
            this.nativePointer = ptr;
            if(!ptr)
            {
                throw new CairoException(cairo_status_t.CAIRO_STATUS_NULL_POINTER);
            }
            checkError();
        }
        
        FontOptions copy()
        {
            return new FontOptions(cairo_font_options_copy(this.nativePointer));
        }
        
        void destroy()
        {
            cairo_font_options_destroy(this.nativePointer);
        }
        
        void merge(FontOptions other)
        {
            cairo_font_options_merge(this.nativePointer, other.nativePointer);
            checkError();
        }
        
        //TODO: how to merge that with toHash?
        ulong hash()
        {
            ulong hash = cairo_font_options_hash(this.nativePointer);
            checkError();
            return hash;
        }
        
        bool opEquals(FontOptions other)
        {
            scope(exit)
                checkError();
            
            return cairo_font_options_equal(this.nativePointer, other.nativePointer) ? true : false;
        }
        
        void setAntiAlias(AntiAlias antialias)
        {
            cairo_font_options_set_antialias(this.nativePointer, antialias);
            checkError();
        }
        
        AntiAlias getAntiAlias()
        {
            scope(exit)
                checkError();
            return cairo_font_options_get_antialias(this.nativePointer);
        }
        
        void setSubpixelOrder(SubpixelOrder order)
        {
            cairo_font_options_set_subpixel_order(this.nativePointer, order);
            checkError();
        }
        
        SubpixelOrder getSubpixelOrder()
        {
            scope(exit)
                checkError();
            return cairo_font_options_get_subpixel_order(this.nativePointer);
        }
        
        void setHintStyle(HintStyle style)
        {
            cairo_font_options_set_hint_style(this.nativePointer, style);
            checkError();
        }
        
        HintStyle getHintStyle()
        {
            scope(exit)
                checkError();
            return cairo_font_options_get_hint_style(this.nativePointer);
        }
        
        void setHintMetrics(HintMetrics metrics)
        {
            cairo_font_options_set_hint_metrics(this.nativePointer, metrics);
            checkError();
        }
        
        HintMetrics getHintMetrics()
        {
            scope(exit)
                checkError();
            return cairo_font_options_get_hint_metrics(this.nativePointer);
        }
}

public class Device
{
    public:
        cairo_device_t* nativePointer;
    
    public this(cairo_device_t* ptr)
    {
        this.nativePointer = ptr;
    }
}

public class Surface
{
    protected:
        void checkError()
        {
            throwError(cairo_surface_status(nativePointer));
        }
    
    public:
        cairo_surface_t* nativePointer;
        
        this(cairo_surface_t* ptr)
        {
            this.nativePointer = ptr;
            if(!ptr)
            {
                throw new CairoException(cairo_status_t.CAIRO_STATUS_NULL_POINTER);
            }
            checkError();
        }
        
        static Surface castFrom(Surface other)
        {
            return other;
        }
        
        T opCast(T)() if(isImplicitlyConvertible!(T, Surface))
        {
            return T.castFrom(this);
        }
        
        static Surface createFromNative(cairo_surface_t* ptr)
        {
            if(!ptr)
            {
                throw new CairoException(cairo_status_t.CAIRO_STATUS_NULL_POINTER);
            }
            throwError(cairo_surface_status(ptr));
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
                default:
                    return new Surface(ptr);
            }
        }
        
        static Surface createSimilar(Surface other, Content content, int width, int height)
        {
            return createFromNative(cairo_surface_create_similar(other.nativePointer, content, width, height));
        }
        
        static Surface createForRectangle(Surface target, Rectangle rect)
        {
            return createFromNative(cairo_surface_create_for_rectangle(target.nativePointer,
                rect.point.x, rect.point.y, rect.width, rect.height));
        }
        
        void reference()
        {
            cairo_surface_reference(this.nativePointer);
            checkError();
        }
        
        void destroy()
        {
            cairo_surface_destroy(this.nativePointer);
            checkError();
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
            return new Device(ptr);
        }
        
        FontOptions getFontOptions()
        {
            FontOptions fo = new FontOptions();
            cairo_surface_get_font_options(this.nativePointer, fo.nativePointer);
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
        
        uint getReferenceCount()
        {
            scope(exit)
                checkError();
            return cairo_surface_get_reference_count(this.nativePointer);
        }
        
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
        }
        
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
                return new ImageSurface(other.nativePointer);
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
        void checkError()
        {
            throwError(cairo_status(nativePointer));
        }
    
    public:
        cairo_t* nativePointer;
        
        this(Surface target)
        {
            nativePointer = cairo_create(target.nativePointer);
            checkError();
        }
        
        void reference()
        {
            cairo_reference(this.nativePointer);
            checkError();
        }
        
        void destroy()
        {
            cairo_destroy(this.nativePointer);
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
        
        void setSourceRBG(double red, double green, double blue)
        {
            cairo_set_source_rgb(this.nativePointer, red, green, blue);
            checkError();
        }
        
        void setSourceRGBA(double red, double green, double blue, double alpha)
        {
            cairo_set_source_rgba(this.nativePointer, red, green, blue, alpha);
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
        
        PathRange copyPath()
        {
            return PathRange(cairo_copy_path(this.nativePointer));
        }
        
        PathRange copyPathFlat()
        {
            return PathRange(cairo_copy_path_flat(this.nativePointer));
        }
        
        //TODO: implement for custom Ranges
        void appendPath(T)(T path) if (is(T == PathRange))
        {
            cairo_append_path(this.nativePointer, path.path);
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
        
        //TODO: Glyph path
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
}

public struct Version
{
    public uint Major, Minor, Micro;
    
    public static Version decodeVersion(int encoded)
    {
        Version tmp;
        tmp.Major = encoded / 10000;
        tmp.Minor = (encoded % 10000) / 100;
        tmp.Micro = (encoded % 10000) % 100;
        return tmp;
    }
}
