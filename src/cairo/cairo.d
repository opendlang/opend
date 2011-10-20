/**
 * This module contains wrappers for most of cairo's fuctionality.
 * Additional wrappers for subsets of cairo are available in the
 * cairo.* modules.
 *
 * Note:
 * Most cairoD functions could throw an OutOfMemoryError. This is therefore not
 * explicitly stated in the functions' api documenation.
 *
 * See_Also:
 * $(LINK http://cairographics.org/documentation/)
 *
 * License:
 * $(BOOKTABLE ,
 *   $(TR $(TD cairoD wrapper/bindings)
 *     $(TD $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost License 1.0)))
 *   $(TR $(TD $(LINK2 http://cgit.freedesktop.org/cairo/tree/COPYING, _cairo))
 *     $(TD $(LINK2 http://cgit.freedesktop.org/cairo/tree/COPYING-LGPL-2.1, LGPL 2.1) /
 *     $(LINK2 http://cgit.freedesktop.org/cairo/plain/COPYING-MPL-1.1, MPL 1.1)))
 * )
 * Authors:
 * $(BOOKTABLE ,
 *   $(TR $(TD Johannes Pfau) $(TD cairoD))
 *   $(TR $(TD Andrej Mitrovic) $(TD cairoD))
 *   $(TR $(TD $(LINK2 http://cairographics.org, _cairo team)) $(TD _cairo))
 * )
 */
/*
 * Distributed under the Boost Software License, Version 1.0.
 *    (See accompanying file LICENSE_1_0.txt or copy at
 *          http://www.boost.org/LICENSE_1_0.txt)
 */
module cairo.cairo;

import cairo.c.cairo;
import cairo.util;

import core.exception;
import std.algorithm;
import std.conv;
import std.range; //For PathRange unittests
import std.string;
import std.traits;
import std.typecons;

debug(RefCounted)
{
    import std.stdio;
}

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
version(CAIRO_HAS_FT_FONT)
{
    import cairo.ft;
}
version(CAIRO_HAS_XLIB_SURFACE)
{
    import cairo.xlib;
}

/**
 * Mainly used internally by cairoD.
 * If status is CAIRO_STATUS_NO_MEMORY a OutOfMemoryError is thrown.
 * If status is  CAIRO_STATUS_SUCCESS nothing happens.
 * For all other statuses, this functions throws
 * a $(D CairoException) with the status value.
 */
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

/**
 * Exception thrown by cairoD if an error occurs.
 */
public class CairoException : Exception
{
    public:
        /**
         * Cairo's error status.
         * Gives further information about the error.
         */
        cairo_status_t status;

        ///
        this(cairo_status_t stat)
        {
            this.status = stat;
            super(to!string(this.status) ~ ": " ~ to!string(cairo_status_to_string(this.status)));
        }
}

/**
 * Aliases for simple cairo enums and structs.
 * Theses aliases provide D-like names when
 * using the cairoD API.
 *
 * BUGS:
 * DDOC doesn't document what an alias actually aliases.
 * If you can't guess the corresponding cairo C types, you should
 * have a look at the cairo.d source.
 */
public alias cairo_content_t Content;
public alias cairo_antialias_t AntiAlias; ///ditto
public alias cairo_subpixel_order_t SubpixelOrder; ///ditto
public alias cairo_hint_style_t HintStyle; ///ditto
public alias cairo_hint_metrics_t HintMetrics; ///ditto
public alias cairo_surface_type_t SurfaceType; ///ditto
public alias cairo_format_t Format; ///ditto
public alias cairo_extend_t Extend; ///ditto
public alias cairo_filter_t Filter; ///ditto
public alias cairo_pattern_type_t PatternType; ///ditto
public alias cairo_fill_rule_t FillRule; ///ditto
public alias cairo_line_cap_t LineCap; ///ditto
public alias cairo_line_join_t LineJoin; ///ditto
public alias cairo_operator_t Operator; ///ditto
public alias cairo_path_data_type_t PathElementType; ///ditto
public alias cairo_font_extents_t FontExtents; ///ditto
public alias cairo_text_extents_t TextExtents; ///ditto
public alias cairo_glyph_t Glyph; ///ditto
public alias cairo_text_cluster_t TextCluster; ///ditto
public alias cairo_text_cluster_flags_t TextClusterFlags; ///ditto
public alias cairo_font_slant_t FontSlant; ///ditto
public alias cairo_font_weight_t FontWeight; ///ditto
public alias cairo_device_type_t DeviceType; ///ditto
public alias cairo_font_type_t FontType; ///ditto
public alias cairo_region_overlap_t RegionOverlap; ///ditto

/**
 * A simple struct to store the coordinates of a point.
 */
public struct Point
{
    ///
    public this(double x, double y)
    {
        this.x = x;
        this.y = y;
    }

    ///
    double x;
    ///
    double y;
}

///ditto
public struct PointInt
{
    ///
    public this(int x, int y)
    {
        this.x = x;
        this.y = y;
    }

    ///
    int x;
    ///
    int y;
}

/**
 * Checks whether TargetType matches any subsequent types.
 * Use as: isOneOf!(TargetType, Type1, Type2..);
 */
template isOneOf(X, T...)
{
    static if (!T.length)
        enum bool isOneOf = false;
    else static if (is (X == T[0]))
        enum bool isOneOf = true;
    else
        enum bool isOneOf = isOneOf!(X, T[1..$]);
}

/**
 * A simple struct representing a rectangle with $(D int) or $(double) values
 */
public struct Rectangle(T) if (isOneOf!(T, int, double))
{
    static if (is(T == double))
    {
        alias Point PointType;
    }
    else static if (is(T == int))
    {
        alias PointInt PointType;
    }

    ///
    public this(PointType point, T width, T height)
    {
        this.point = point;
        this.width = width;
        this.height = height;
    }

    ///ditto
    public this(T x, T y, T width, T height)
    {
        this.point.x = x;
        this.point.y = y;
        this.width = width;
        this.height = height;
    }

    ///TOP-LEFT point of the rectangle
    PointType point;
    ///
    T width;
    ///
    T height;
}

/**
 * Convenience function to create a $(D Rectangle!int) or $(D Rectangle!double).
 * If any of the arguments are of a floating-point type,
 * Rectangle!double is constructed.
 *
 * Examples:
 * --------------------------------------------------------
 * auto a = rectangle(1, 1, 4, 4);
 * auto b = rectangle(0.99, 0.99, 3.99, 3.99);
 * --------------------------------------------------------
 */
auto rectangle(T...)(T args)
{
    static if (isOneOf!(float, T) || isOneOf!(double, T))
    {
        return Rectangle!(double)(args);
    }
    else
    {
        return Rectangle!(int)(args);
    }
}

unittest
{
    auto a = rectangle(1, 1, 4, 4);
    auto b = rectangle(0.99, 0.99, 3.99, 3.99);

    auto rect1 = rectangle(0, 0, 10, 10);
    Rectangle!int rectInt = rect1;

    auto rect2 = rectangle(0, 0, 10.0, 10);
    Rectangle!double rectDouble = rect2;

    auto rect3 = rectangle(cast(byte)0, cast(short)0, cast(int)10, cast(uint)10);
    Rectangle!int rectInt2 = rect3;
}

/**
 * A simple struct representing a size with only $(D int) values
 */
public struct Size(T) if (is(T == int))
{
    ///
    public this(int width, int height)
    {
        this.width = width;
        this.height = height;
    }

    ///
    int width, height;
}

/**
 * A simple struct representing a size with $(D double) values
 */
public struct Size(T) if (is(T == double))
{
    ///
    public this(double width, double height)
    {
        this.width = width;
        this.height = height;
    }

    ///
    double width, height;
}

unittest
{
    auto a = Size!int(10, 10);
    auto b = Size!double(5, 5);
}

/**
 * A simple struct representing a box.
 * Used for Extents.
 */
public struct Box
{
    ///
    public this(Point point1, Point point2)
    {
        this.point1 = point1;
        this.point2 = point2;
    }
    ///
    public this(double x1, double y1, double x2, double y2)
    {
        this.point1.x = x1;
        this.point1.y = y1;
        this.point2.x = x2;
        this.point2.y = y2;
    }
    ///Top-left point
    Point point1;
    ///Bottom-right point
    Point point2;
}

/**
 * A simple struct representing a resolution
 */
public struct Resolution
{
    ///
    public this(double resX, double resY)
    {
        this.x = resX;
        this.y = resY;
    }

    ///In pixels per inch
    double x, y;
}

//TODO: merge those?
/**
 * Struct representing a RGBA color
 */
public struct RGBA
{
    ///
    public this(double red, double green, double blue, double alpha)
    {
        this.red = red;
        this.green = green;
        this.blue = blue;
        this.alpha = alpha;
    }
    ///
    public double red, green, blue, alpha;

    ///convert RGBA struct to RGB struct. Alpha is discarded
    public RGB opCast(RGB)()
    {
        return RGB(red, green, blue);
    }
}

/**
 * Struct representing a RGB color
 */
public struct RGB
{
    ///
    public this(double red, double green, double blue)
    {
        this.red = red;
        this.green = green;
        this.blue = blue;
    }
    ///
    public double red, green, blue;

    ///convert RGBA struct to RGB struct. Alpha is set to '1.0'
    public RGBA opCast(RGBA)()
    {
        return RGBA(red, green, blue, 1);
    }
}

unittest
{
    auto rgb1 = RGB(0.1, 0.2, 0.3);
    auto rgba1 = cast(RGBA)rgb1;
    assert(rgba1.red == rgb1.red);
    assert(rgba1.green == rgb1.green);
    assert(rgba1.blue == rgb1.blue);
    assert(rgba1.alpha == 1.0);

    auto rgba2 = RGBA(0.3, 0.2, 0.1, 0.5);
    auto rgb2 = cast(RGB)rgba2;
    assert(rgba2.red == rgb2.red);
    assert(rgba2.green == rgb2.green);
    assert(rgba2.blue == rgb2.blue);
}

/* From cairo binding documentation:
 * You should not present an API for mutating or for creating new cairo_path_t
 * objects. In the future, these guidelines may be extended to present an API
 * for creating a cairo_path_t from scratch for use with cairo_append_path()
 * but the current expectation is that cairo_append_path() will mostly be
 * used with paths from cairo_copy_path().*/
 /**
  * Reference counted wrapper around $(D cairo_path_t).
  * This struct can only be obtained from cairoD. It cannot be created
  * manually.
  */
public struct Path
{
    private:
        struct Payload
        {
            cairo_path_t* _payload;
            this(cairo_path_t* h)
            {
                _payload = h;
            }
            ~this()
            {
                if(_payload)
                {
                    cairo_path_destroy(_payload);
                    _payload = null;
                }
            }

            // Should never perform these operations
            this(this) { assert(false); }
            void opAssign(Path.Payload rhs) { assert(false); }
        }
        alias RefCounted!(Payload, RefCountedAutoInitialize.no) Data;
        Data _data;

        @property cairo_status_t status()
        {
            return nativePointer.status;
        }

        @property cairo_path_data_t* data()
        {
            return nativePointer.data;
        }

        @property int num_data()
        {
            return nativePointer.num_data;
        }

    public:
        // @BUG@: Can't pass as range if default ctor is disabled
        // @disable this();
    
        /**
         * Create a Path from a existing $(D cairo_path_t*).
         * Path is a reference-counted type. It will call $(D cairo_path_destroy)
         * when there are no more references to the path.
         *
         * This means you should not destroy the $(D cairo_path_t*) manually
         * and you should not use $(D cairo_path_t*) anymore after you created a Path
         * with this constructor.
         *
         * Warning:
         * $(RED Only use this if you know what your doing!
         * This function should not be needed for standard cairoD usage.)
         */
        this(cairo_path_t* path)
        {
            throwError(path.status);
            _data.RefCounted.initialize(path);
        }

        /**
         * The underlying $(D cairo_path_t*) handle
         */
        @property cairo_path_t* nativePointer()
        {
            return _data._payload;
        }

        version(D_Ddoc)
        {
            /**
             * Enable / disable memory management debugging for this Path
             * instance. Only available if both cairoD and the cairoD user
             * code were compiled with "debug=RefCounted"
             *
             * Output is written to stdout, see
             * $(LINK https://github.com/jpf91/cairoD/wiki/Memory-Management#debugging)
             * for more information
             */
            @property bool debugging();
            ///ditto
            @property void debugging(bool value);
        }
        else debug(RefCounted)
        {
            @property bool debugging()
            {
                return _data.RefCounted.debugging;
            }

            @property void debugging(bool value)
            {
                _data.RefCounted.debugging = value;
            }
        }

        /**
         * Get a $(D PathRange) for this path to iterate the paths
         * elements.
         *
         * Examples:
         * --------------------------
         * auto path = context.copyPath();
         * foreach(PathElement element; path[])
         * {
         *     switch(element.type)
         *     {
         *          case PathElementType.CAIRO_PATH_MOVE_TO:
         *          {
         *              writefln("Move to %s:%s", element.getPoint(0).x,
         *                       element.getPoint(0).y);
         *          }
         *     }
         * }
         * --------------------------
         */
        PathRange opSlice()
        {
            return PathRange(this);
        }
}

/**
 * ForwardRange to iterate a cairo path.
 * This range keeps a reference to its $(D Path) object,
 * so it can be passed around without thinking about memory management.
 */
public struct PathRange
{
    private:
        Path path;
        int pos = 0;
        this(Path path, int pos)
        {
            this.path = path;
            this.pos = pos;
        }

    public:
        /**
         * Constructor to get a PathRange for a $(D Path) object.
         * You should usually use $(D Path)'s opSlice method insted, see
         * the $(D Path) documentation for an example.
         */
        this(Path path)
        {
            this.path = path;
        }

        ///ForwardRange implementation
        @property PathRange save()
        {
            return PathRange(path, pos);
        }

        ///ditto
        @property bool empty()
        {
            assert(pos <= path.num_data);
            return (pos == path.num_data);
        }

        ///ditto
        void popFront()
        {
            pos += path.data[pos].header.length;
            assert(pos <= path.num_data);
        }

        ///ditto
        @property PathElement front()
        {
            return PathElement(&path.data[pos]);
        }
}

unittest
{
    static assert(isForwardRange!PathRange);
}

/**
 * An element of a cairo $(D Path) and the objects iterated by a
 * $(D PathRange).
 */
public struct PathElement
{
    private:
        cairo_path_data_t* data;

        this(cairo_path_data_t* data)
        {
            this.data = data;
        }
    public:
        ///The type of this element.
        @property PathElementType type()
        {
            return data.header.type;
        }

        /**
         * Get a point from this element.
         * Index is zero-based. The number of available points
         * depends on the elements $(D type):
         * --------------------
         *     CAIRO_PATH_MOVE_TO:     1 point
         *     CAIRO_PATH_LINE_TO:     1 point
         *     CAIRO_PATH_CURVE_TO:    3 points
         *     CAIRO_PATH_CLOSE_PATH:  0 points
         * --------------------
         */
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
        
        ///Convenience operator overload.
        alias getPoint opIndex;
}

/**
 * Wrapper for cairo's $(D cairo_matrix_t).
 * A $(D cairo_matrix_t) holds an affine transformation, such as a scale,
 * rotation, shear, or a combination of those. The transformation of
 * a point (x, y) is given by:
 * --------------------------------------
 *     x_new = xx * x + xy * y + x0;
 *     y_new = yx * x + yy * y + y0;
 * --------------------------------------
 **/
public struct Matrix
{
    public:
        /**
         * Cairo's $(D cairo_matrix_t) struct
         */
        cairo_matrix_t nativeMatrix;
        /**
         * Alias, so that $(D cairo_matrix_t) members also work
         * with this $(D Matrix) struct
         */
        alias nativeMatrix this;

        /**
         * Sets matrix to be the affine transformation given by xx, yx, xy, yy, x0, y0.
         * The transformation is given by:
         * ----------------------
         *  x_new = xx * x + xy * y + x0;
         *  y_new = yx * x + yy * y + y0;
         * ----------------------
         *
         * Params:
         * xx = xx component of the affine transformation
         * yx = yx component of the affine transformation
         * xy = xy component of the affine transformation
         * yy = yy component of the affine transformation
         * x0 = X translation component of the affine transformation
         * y0 = Y translation component of the affine transformation
         */
        this(double xx, double yx, double xy, double yy,
            double x0, double y0)
        {
            cairo_matrix_init(&this.nativeMatrix, xx, yx, xy, yy, x0, y0);
        }

        /**
         * Modifies matrix to be an identity transformation.
         */
        void initIdentity()
        {
            cairo_matrix_init_identity(&this.nativeMatrix);
        }

        /**
         * Initializes matrix to a transformation that translates by tx
         * and ty in the X and Y dimensions, respectively.
         *
         * Params:
         * tx = amount to translate in the X direction
         * ty = amount to translate in the Y direction
         */
        void initTranslate(double tx, double ty)
        {
            cairo_matrix_init_translate(&this.nativeMatrix, tx, ty);
        }

        /**
         * nitializes matrix to a transformation that scales by sx and sy
         * in the X and Y dimensions, respectively.
         *
         * Params:
         * sx = scale factor in the X direction
         * sy = scale factor in the Y direction
         */
        void initScale(double sx, double sy)
        {
            cairo_matrix_init_scale(&this.nativeMatrix, sx, sy);
        }

        ///ditto
        void initScale(Point point)
        {
            initScale(point.x, point.y);
        }

        /**
         * Initialized matrix to a transformation that rotates by radians.
         *
         * Params:
         * radians = angle of rotation, in radians. The direction of
         *     rotation is defined such that positive angles rotate in
         *     the direction from the positive X axis toward the positive
         *     Y axis. With the default axis orientation of cairo,
         *     positive angles rotate in a clockwise direction
         */
        void initRotate(double radians)
        {
            cairo_matrix_init_rotate(&this.nativeMatrix, radians);
        }

        /**
         * Applies a translation by tx, ty to the transformation in matrix.
         * The effect of the new transformation is to first translate the
         * coordinates by tx and ty, then apply the original transformation
         * to the coordinates.
         *
         * Params:
         * tx = amount to translate in the X direction
         * ty = amount to translate in the Y direction
         */
        void translate(double tx, double ty)
        {
            cairo_matrix_translate(&this.nativeMatrix, tx, ty);
        }

        /**
         * Applies scaling by sx, sy to the transformation in matrix.
         * The effect of the new transformation is to first scale the
         * coordinates by sx and sy, then apply the original transformation
         * to the coordinates.
         *
         * Params:
         * sx = scale factor in the X direction
         * sy = scale factor in the Y direction
         */
        void scale(double sx, double sy)
        {
            cairo_matrix_scale(&this.nativeMatrix, sx, sy);
        }

        ///ditto
        void scale(Point point)
        {
            scale(point.x, point.y);
        }

        /**
         * Applies rotation by radians to the transformation in matrix.
         * The effect of the new transformation is to first rotate the
         * coordinates by radians, then apply the original transformation
         * to the coordinates.
         *
         * Params:
         * radians = angle of rotation, in radians. The direction of
         * rotation is defined such that positive angles rotate in the
         * direction from the positive X axis toward the positive Y axis.
         * With the default axis orientation of cairo, positive angles
         * rotate in a clockwise direction.
         */
        void rotate(double radians)
        {
            cairo_matrix_rotate(&this.nativeMatrix, radians);
        }

        /**
         * Changes matrix to be the inverse of its original value.
         * Not all transformation matrices have inverses; if the matrix
         * collapses points together (it is degenerate), then it has no
         * inverse and this function will fail.
         *
         * Throws:
         * If matrix has an inverse, modifies matrix to be the inverse matrix.
         * Otherwise, throws a cairo exception
         * with CAIRO_STATUS_INVALID_MATRIX type.
         */
        void invert()
        {
            throwError(cairo_matrix_invert(&this.nativeMatrix));
        }

        /**
         * Multiplies the affine transformations in a and b together and
         * returns the result. The effect of the resulting transformation
         * is to first apply the transformation in a to the coordinates
         * and then apply the transformation in b to the coordinates.
         *
         * It is allowable for result to be identical to either a or b.
         */
        Matrix opBinary(string op)(Matrix rhs) if(op == "*")
        {
            Matrix result;
            cairo_matrix_multiply(&result.nativeMatrix, &this.nativeMatrix, &rhs.nativeMatrix);
            return result;
        }

        /**
         * Transforms the distance vector (dx,dy) by matrix. This is similar
         * to $(D transformPoint) except that the translation
         * components of the transformation are ignored. The calculation
         * of the returned vector is as follows:
         * ------------------
         * dx2 = dx1 * a + dy1 * c;
         * dy2 = dx1 * b + dy1 * d;
         * ------------------
         */
        Point transformDistance(Point dist)
        {
            cairo_matrix_transform_distance(&this.nativeMatrix, &dist.x, &dist.y);
            return dist;
        }

        /**
         * Transforms the point (x, y) by matrix.
         */
        Point transformPoint(Point point)
        {
            cairo_matrix_transform_point(&this.nativeMatrix, &point.x, &point.y);
            return point;
        }
}

/**
 * A $(D Pattern) represents a source when drawing onto a
 * $(D Surface). There are different subtypes of $(D Pattern),
 * for different types of sources; for example,
 * $(D SolidPattern.fromRGB) creates a pattern for a solid
 * opaque color.
 *
 * Other than various $(D Pattern) subclasses,
 * some of the pattern types can be implicitly created
 * using various $(D Context.setSource) functions;
 * for example $(D Context.setSourceRGB).
 *
 * The C type of a pattern can be queried with $(D getType()),
 * although D polymorphism features also work.
 *
 * Memory management of $(D Pattern) can be done with the $(D dispose())
 * method, see $(LINK https://github.com/jpf91/cairoD/wiki/Memory-Management#3-RC-class)
 *
 * Note:
 * This class uses the $(D CairoCountedClass) mixin, so all it's members
 * are also available in $(D Pattern) classes, although they do not show
 * up in the documentation because of a limitation in ddoc.
 **/
public class Pattern
{
    ///
    mixin CairoCountedClass!(cairo_pattern_t*, "cairo_pattern_");

    protected:
        /**
         * Method for use in subclasses.
         * Calls $(D cairo_pattern_status(nativePointer)) and throws
         * an exception if the status isn't CAIRO_STATUS_SUCCESS
         */
        final void checkError()
        {
            throwError(cairo_pattern_status(nativePointer));
        }

    public:
        /**
         * Create a $(D Pattern) from a existing $(D cairo_pattern_t*).
         * Pattern is a garbage collected class. It will call $(D cairo_pattern_destroy)
         * when it gets collected by the GC or when $(D dispose()) is called.
         *
         * Warning:
         * $(D ptr)'s reference count is not increased by this function!
         * Adjust reference count before calling it if necessary
         *
         * $(RED Only use this if you know what your doing!
         * This function should not be needed for standard cairoD usage.)
         */
        this(cairo_pattern_t* ptr)
        {
            this.nativePointer = ptr;
            if(!ptr)
            {
                throw new CairoException(cairo_status_t.CAIRO_STATUS_NULL_POINTER);
            }
            checkError();
        }

        /**
         * The createFromNative method for the Pattern classes.
         * See $(LINK https://github.com/jpf91/cairoD/wiki/Memory-Management#createFromNative)
         * for more information.
         *
         * Warning:
         * $(RED Only use this if you know what your doing!
         * This function should not be needed for standard cairoD usage.)
         */
        static Pattern createFromNative(cairo_pattern_t* ptr, bool adjRefCount = true)
        {
            if(!ptr)
            {
                throw new CairoException(cairo_status_t.CAIRO_STATUS_NULL_POINTER);
            }
            throwError(cairo_pattern_status(ptr));
            //Adjust reference count
            if(adjRefCount)
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

        /**
         * Sets the mode to be used for drawing outside the area of a pattern.
         * See $(D Extend) for details on the semantics of each extend strategy.
         * The default extend mode is CAIRO_EXTEND_NONE for surface patterns
         * and CAIRO_EXTEND_PAD for gradient patterns.
         */
        void setExtend(Extend ext)
        {
            cairo_pattern_set_extend(this.nativePointer, ext);
            checkError();
        }

        /**
         * Gets the current extend mode for a pattern. See $(D Extend)
         * for details on the semantics of each extend strategy.
         */
        Extend getExtend()
        {
            scope(exit)
                checkError();
            return cairo_pattern_get_extend(this.nativePointer);
        }

        /**
         * Sets the filter to be used for resizing when using this pattern.
         * See $(D Filter) for details on each filter.
         *
         * Note:
         * You might want to control filtering even when you do not have
         * an explicit cairo_pattern_t object, (for example when using
         * $(D context.setSourceSourface())). In these cases, it is convenient
         * to use $(D Context.getSource()) to get access to the pattern
         * that cairo creates implicitly.
         * For example:
         * ------------------------
         * context.setSourceSurface(image, x, y);
         * context.getSource().setFilter(Filter.CAIRO_FILTER_NEAREST);
         * ------------------------
         */
        void setFilter(Filter fil)
        {
            cairo_pattern_set_filter(this.nativePointer, fil);
            checkError();
        }

        /**
         * Gets the current filter for a pattern. See $(D Filter) for details on each filter.
         */
        Filter getFilter()
        {
            scope(exit)
                checkError();
            return cairo_pattern_get_filter(this.nativePointer);
        }
        
        ///Convenience property
        void filter(Filter fil)
        {
            setFilter(fil);
        }
        
        ///ditto
        Filter filter()
        {
            return getFilter();
        }
        
        /**
         * Sets the pattern's transformation matrix to matrix.
         * This matrix is a transformation from user space to pattern space.
         *
         * When a pattern is first created it always has the identity matrix
         * for its transformation matrix, which means that pattern space
         * is initially identical to user space.
         * Important: Please note that the direction of this transformation
         * matrix is from user space to pattern space. This means that if
         * you imagine the flow from a pattern to user space (and on to
         * device space), then coordinates in that flow will be transformed
         * by the inverse of the pattern matrix.
         *
         * For example, if you want to make a pattern appear twice as large
         * as it does by default the correct code to use is:
         * -------------------
         * Matrix matrix;
         * matrix.initScale(0.5, 0.5);
         * pattern.setMatrix(matrix);
         * -------------------
         * Meanwhile, using values of 2.0 rather than 0.5 in the code above
         * would cause the pattern to appear at half of its default size.
         *
         * Also, please note the discussion of the user-space locking semantics
         * of $(D Context.setSource()).
         */
        void setMatrix(Matrix mat)
        {
            cairo_pattern_set_matrix(this.nativePointer, &mat.nativeMatrix);
            checkError();
        }

        /**
         * Returns the pattern's transformation matrix.
         */
        Matrix getMatrix()
        {
            Matrix ma;
            cairo_pattern_get_matrix(this.nativePointer, &ma.nativeMatrix);
            checkError();
            return ma;
        }

        ///Convenience property
        @property void matrix(Matrix mat)
        {
            setMatrix(mat);
        }
        
        ///ditto
        @property Matrix matrix()
        {
            return getMatrix();
        }        
        
        /**
         * This function returns the C type of a pattern. See $(D PatternType)
         * for available types.
         */
        PatternType getType()
        {
            scope(exit)
                checkError();
            return cairo_pattern_get_type(this.nativePointer);
        }

        ///Convenience property
        @property PatternType type()
        {
            return getType();
        }
        
        //Cairo binding guidelines say we shouldn't wrap these
        /*
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
        }*/
}

/**
 * A solid pattern.
 *
 * Use the $(D fromRGB) and $(D fromRGBA) methods to create an
 * instance.
 */
public class SolidPattern : Pattern
{
    public:
        /**
         * Create a $(D SolidPattern) from a existing $(D cairo_pattern_t*).
         * SolidPattern is a garbage collected class. It will call $(D cairo_pattern_destroy)
         * when it gets collected by the GC or when $(D dispose()) is called.
         *
         * Warning:
         * $(D ptr)'s reference count is not increased by this function!
         * Adjust reference count before calling it if necessary
         *
         * $(RED Only use this if you know what your doing!
         * This function should not be needed for standard cairoD usage.)
         */
        this(cairo_pattern_t* ptr)
        {
            super(ptr);
        }

        /**
         * Creates a new $(D SolidPattern) corresponding to an opaque color.
         * The color components are floating point numbers in the range 0
         * to 1. If the values passed in are outside that range, they will
         * be clamped.
         */
        static SolidPattern fromRGB(double red, double green, double blue)
        {
            return new SolidPattern(cairo_pattern_create_rgb(red, green, blue));
        }

        ///ditto
        static SolidPattern fromRGB(RGB rgb)
        {
            return new SolidPattern(cairo_pattern_create_rgb(rgb.red, rgb.green, rgb.blue));
        }

        /**
         * Creates a new $(D SolidPattern) corresponding to a translucent color.
         * The color components are floating point numbers in the range 0 to 1.
         * If the values passed in are outside that range, they will be clamped.
         */
        static SolidPattern fromRGBA(double red, double green, double blue, double alpha)
        {
            return new SolidPattern(cairo_pattern_create_rgba(red, green, blue, alpha));
        }

        ///ditto
        static SolidPattern fromRGBA(RGBA rgba)
        {
            return new SolidPattern(cairo_pattern_create_rgba(rgba.red,rgba. green, rgba.blue, rgba.alpha));
        }

        /**
         * Gets the solid color for a solid color pattern.
         */
        RGBA getRGBA()
        {
            RGBA col;
            cairo_pattern_get_rgba(this.nativePointer, &col.red, &col.green, &col.blue, &col.alpha);
            checkError();
            return col;
        }
        
        ///Convenience property (todo: dubious due to lowercase requirement)
        @property RGBA rgba()
        {
            return getRGBA();
        }           
}

/**
 * A surface pattern.
 *
 * Use the $(this(Surface)) constructor to create an
 * instance.
 */
public class SurfacePattern : Pattern
{
    public:
        /**
         * Create a $(D SurfacePattern) from a existing $(D cairo_pattern_t*).
         * SurfacePattern is a garbage collected class. It will call $(D cairo_pattern_destroy)
         * when it gets collected by the GC or when $(D dispose()) is called.
         *
         * Warning:
         * $(D ptr)'s reference count is not increased by this function!
         * Adjust reference count before calling it if necessary
         *
         * $(RED Only use this if you know what your doing!
         * This function should not be needed for standard cairoD usage.)
         */
        this(cairo_pattern_t* ptr)
        {
            super(ptr);
        }

        /**
         * Create a new $(D SurfacePattern) for the given surface.
         */
        this(Surface surface)
        {
            super(cairo_pattern_create_for_surface(surface.nativePointer));
        }

        /**
         * Gets the $(D Surface) of a SurfacePattern.
         */
        Surface getSurface()
        {
            cairo_surface_t* ptr;
            throwError(cairo_pattern_get_surface(this.nativePointer, &ptr));
            return Surface.createFromNative(ptr);
        }
        
        ///Convenience property
        @property Surface surface()
        {
            return getSurface();
        }           
}

/**
 * Base class for $(D LinearGradient) and $(D RadialGradient).
 *
 * It's not possible to create instances of this class.
 */
public class Gradient : Pattern
{
    public:
        /**
         * Create a $(D Gradient) from a existing $(D cairo_pattern_t*).
         * Gradient is a garbage collected class. It will call $(D cairo_pattern_destroy)
         * when it gets collected by the GC or when $(D dispose()) is called.
         *
         * Warning:
         * $(D ptr)'s reference count is not increased by this function!
         * Adjust reference count before calling it if necessary
         *
         * $(RED Only use this if you know what your doing!
         * This function should not be needed for standard cairoD usage.)
         */
        this(cairo_pattern_t* ptr)
        {
            super(ptr);
        }

        /**
         * Adds an opaque color stop to a gradient pattern. The offset
         * specifies the location along the gradient's control vector.
         * For example, a $(D LinearGradient)'s control vector is from
         * (x0,y0) to (x1,y1) while a $(D RadialGradient)'s control vector is
         * from any point on the start circle to the corresponding point
         * on the end circle.
         *
         * The color is specified in the same way as in $(D context.setSourceRGB()).
         *
         * If two (or more) stops are specified with identical offset
         * values, they will be sorted according to the order in which the
         * stops are added, (stops added earlier will compare less than
         * stops added later). This can be useful for reliably making sharp
         * color transitions instead of the typical blend.
         *
         * Params:
         * offset = an offset in the range [0.0 .. 1.0]
         *
         * Note: If the pattern is not a gradient pattern, (eg. a linear
         * or radial pattern), then the pattern will be put into an error
         * status with a status of CAIRO_STATUS_PATTERN_TYPE_MISMATCH.
         */
        void addColorStopRGB(double offset, RGB color)
        {
            cairo_pattern_add_color_stop_rgb(this.nativePointer, offset,
                color.red, color.green, color.blue);
            checkError();
        }

        ///ditto
        void addColorStopRGB(double offset, double red, double green, double blue)
        {
            cairo_pattern_add_color_stop_rgb(this.nativePointer, offset,
                red, green, blue);
            checkError();
        }

        /**
         * Adds a translucent color stop to a gradient pattern. The offset
         * specifies the location along the gradient's control vector. For
         * example, a linear gradient's control vector is from (x0,y0) to
         * (x1,y1) while a radial gradient's control vector is from any point
         * on the start circle to the corresponding point on the end circle.
         *
         * The color is specified in the same way as in
         * $(D context.setSourceRGBA()).
         *
         * If two (or more) stops are specified with identical offset values,
         * they will be sorted according to the order in which the stops are added,
         * (stops added earlier will compare less than stops added later).
         * This can be useful for reliably making sharp color transitions
         * instead of the typical blend.
         *
         * Params:
         * offset = an offset in the range [0.0 .. 1.0]
         *
         * Note: If the pattern is not a gradient pattern, (eg. a linear
         * or radial pattern), then the pattern will be put into an error
         * status with a status of CAIRO_STATUS_PATTERN_TYPE_MISMATCH.
         */
        void addColorStopRGBA(double offset, RGBA color)
        {
            cairo_pattern_add_color_stop_rgba(this.nativePointer, offset,
                color.red, color.green, color.blue, color.alpha);
            checkError();
        }

        ///ditto
        void addColorStopRGBA(double offset, double red, double green,
            double blue, double alpha)
        {
            cairo_pattern_add_color_stop_rgba(this.nativePointer, offset,
                red, green, blue, alpha);
            checkError();
        }
        
        /**
         * Gets the number of color stops specified in the given gradient pattern.
         */
        int getColorStopCount()
        {
            int tmp;
            cairo_pattern_get_color_stop_count(this.nativePointer, &tmp);
            checkError();
            return tmp;
        }

        ///Convenience alias
        alias getColorStopCount colorStopCount;
        
        /**
         * Gets the color and offset information at the given index for a
         * gradient pattern. Values of index are 0 to 1 less than the number
         * returned by $(D getColorStopCount()).
         *
         * Params:
         * index = index of the stop to return data for
         * offset = output: Returns the offset of the color stop
         * color = output: Returns the color of the color stop
         *
         * TODO: Array/Range - like interface?
         */
        void getColorStopRGBA(int index, out double offset, out RGBA color)
        {
            throwError(cairo_pattern_get_color_stop_rgba(this.nativePointer, index, &offset,
                &color.red, &color.green, &color.blue, &color.alpha));
        }
}

/**
 * A linear gradient.
 *
 * Use the $(D this(Point p1, Point p2)) constructor to create an
 * instance.
 */
public class LinearGradient : Gradient
{
    public:
        /**
         * Create a $(D LinearGradient) from a existing $(D cairo_pattern_t*).
         * LinearGradient is a garbage collected class. It will call $(D cairo_pattern_destroy)
         * when it gets collected by the GC or when $(D dispose()) is called.
         *
         * Warning:
         * $(D ptr)'s reference count is not increased by this function!
         * Adjust reference count before calling it if necessary
         *
         * $(RED Only use this if you know what your doing!
         * This function should not be needed for standard cairoD usage.)
         */
        this(cairo_pattern_t* ptr)
        {
            super(ptr);
        }

        /**
         * Create a new linear gradient $(D Pattern) along the line defined
         * by p1 and p2. Before using the gradient pattern, a number of
         * color stops should be defined using $(D Gradient.addColorStopRGB())
         * or  $(D Gradient.addColorStopRGBA()).
         *
         * Params:
         * p1 = the start point
         * p2 = the end point
         *
         * Note: The coordinates here are in pattern space. For a new pattern,
         * pattern space is identical to user space, but the relationship
         * between the spaces can be changed with $(D Pattern.setMatrix()).
         */
        this(Point p1, Point p2)
        {
            super(cairo_pattern_create_linear(p1.x, p1.y, p2.x, p2.y));
        }
        ///ditto
        this(double x1, double y1, double x2, double y2)
        {
            super(cairo_pattern_create_linear(x1, y1, x2, y2));
        }

        /**
         * Gets the gradient endpoints for a linear gradient.
         *
         * Returns:
         * Point[0] = the first point
         *
         * Point[1] = the second point
         */
        Point[2] getLinearPoints()
        {
            Point[2] tmp;
            throwError(cairo_pattern_get_linear_points(this.nativePointer, &tmp[0].x, &tmp[0].y,
                &tmp[1].x, &tmp[1].y));
            return tmp;
        }
        
        ///Convenience alias
        alias getLinearPoints linearPoints;
}

/**
 * A radial gradient.
 *
 * Use the $(D this(Point c0, double radius0, Point c1, double radius1))
 * constructor to create an instance.
 */
public class RadialGradient : Gradient
{
    public:
        /**
         * Create a $(D RadialGradient) from a existing $(D cairo_pattern_t*).
         * RadialGradient is a garbage collected class. It will call $(D cairo_pattern_destroy)
         * when it gets collected by the GC or when $(D dispose()) is called.
         *
         * Warning:
         * $(D ptr)'s reference count is not increased by this function!
         * Adjust reference count before calling it if necessary
         *
         * $(RED Only use this if you know what your doing!
         * This function should not be needed for standard cairoD usage.)
         */
        this(cairo_pattern_t* ptr)
        {
            super(ptr);
        }

        /**
         * Creates a new radial gradient $(D pattern) between the two
         * circles defined by (c0, radius0) and (c1, radius1). Before
         * using the gradient pattern, a number of color stops should
         * be defined using $(D Pattern.addColorStopRGB()) or
         * $(D Pattern.addColorStopRGBA()).
         *
         * Params:
         * c0 = center of the start circle
         * radius0 = radius of the start circle
         * c1 = center of the end circle
         * radius1 = radius of the end circle
         *
         * Note: The coordinates here are in pattern space. For a new pattern,
         * pattern space is identical to user space, but the relationship
         * between the spaces can be changed with $(D Pattern.setMatrix()).
         */
        this(Point c0, double radius0, Point c1, double radius1)
        {
            super(cairo_pattern_create_radial(c0.x, c0.y, radius0, c1.x, c1.y, radius1));
        }
        ///ditto
        this(double c0x, double c0y, double radius0, double c1x, double c1y, double radius1)
        {
            super(cairo_pattern_create_radial(c0x, c0y, radius0, c1x, c1y, radius1));
        }

        /**
         * Gets the gradient endpoint circles for a radial gradient,
         * each specified as a center coordinate and a radius.
         */
        void getRadialCircles(out Point c0, out Point c1, out double radius0, out double radius1)
        {
            throwError(cairo_pattern_get_radial_circles(this.nativePointer, &c0.x, &c0.y, &radius0,
                &c1.x, &c1.y, &radius1));
        }
}

/**
 * Devices are the abstraction Cairo employs for the rendering system used
 * by a $(D Surface). You can get the device of a surface using
 * $(D Surface.getDevice()).
 *
 * Devices are created using custom functions specific to the rendering
 * system you want to use. See the documentation for the surface types
 * for those functions.
 *
 * An important function that devices fulfill is sharing access to the
 * rendering system between Cairo and your application. If you want to access
 * a device directly that you used to draw to with Cairo, you must first
 * call $(D Device.flush()) to ensure that Cairo finishes all operations
 * on the device and resets it to a clean state.
 *
 * Cairo also provides the functions $(D Device.acquire()) and
 * $(D Device.release()) to synchronize access to the rendering system
 * in a multithreaded environment. This is done internally, but can also
 * be used by applications.
 *
 * Note:
 * Please refer to the documentation of each backend for additional usage
 * requirements, guarantees provided, and interactions with existing surface
 * API of the device functions for surfaces of that type.
 *
 * Examples:
 * -------------------------
 * void my_device_modifying_function(Device device)
 * {
 *     // Ensure the device is properly reset
 *     device.flush();
 *     try
 *     {
 *         // Try to acquire the device
 *         device.acquire();
 *     }
 *     catch(CairoException e)
 *     {
 *         writeln("");
 *     }
 *
 *     // Release the device when done.
 *     scope(exit)
 *         device.release();
 *
 *     // Do the custom operations on the device here.
 *     // But do not call any Cairo functions that might acquire devices.
 *
 * }
 * -------------------------
*/
public class Device
{
    ///
    mixin CairoCountedClass!(cairo_device_t*, "cairo_device_");

    protected:
        /**
         * Method for use in subclasses.
         * Calls $(D cairo_device_status(nativePointer)) and throws
         * an exception if the status isn't CAIRO_STATUS_SUCCESS
         */
        final void checkError()
        {
            throwError(cairo_device_status(nativePointer));
        }

    public:
        /**
         * Create a $(D Device) from a existing $(D cairo_device_t*).
         * Device is a garbage collected class. It will call $(D cairo_pattern_destroy)
         * when it gets collected by the GC or when $(D dispose()) is called.
         *
         * Warning:
         * $(D ptr)'s reference count is not increased by this function!
         * Adjust reference count before calling it if necessary
         *
         * $(RED Only use this if you know what your doing!
         * This function should not be needed for standard cairoD usage.)
         */
        this(cairo_device_t* ptr)
        {
            this.nativePointer = ptr;
            if(!ptr)
            {
                throw new CairoException(cairo_status_t.CAIRO_STATUS_NULL_POINTER);
            }
            checkError();
        }

        /**
         * This function finishes the device and drops all references to
         * external resources. All surfaces, fonts and other objects created
         * for this device will be finished, too. Further operations on
         * the device will not affect the device but will instead trigger
         * a CAIRO_STATUS_DEVICE_FINISHED exception.
         *
         * When the reference count reaches zero, cairo will call $(D finish())
         * if it hasn't been called already, before freeing the resources
         * associated with the device.
         *
         * This function may acquire devices.
         *
         * BUGS: How does "All surfaces, fonts and other objects created
         * for this device will be finished" interact with the cairoD?
         */
        void finish()
        {
            cairo_device_finish(this.nativePointer);
            checkError();
        }

        /**
         * Finish any pending operations for the device and also restore
         * any temporary modifications cairo has made to the device's state.
         * This function must be called before switching from using the
         * device with Cairo to operating on it directly with native APIs.
         * If the device doesn't support direct access, then this function does nothing.
         *
         * This function may acquire devices.
         */
        void flush()
        {
            cairo_device_flush(this.nativePointer);
            checkError();
        }

        /**
         * This function returns the C type of a Device. See $(D DeviceType)
         * for available types.
         */
        DeviceType getType()
        {
            auto tmp = cairo_device_get_type(this.nativePointer);
            checkError();
            return tmp;
        }

        ///Convenience alias
        alias getType type;
        
        /**
         * Acquires the device for the current thread. This function will
         * block until no other thread has acquired the device.
         *
         * If no Exception is thrown, you successfully
         * acquired the device. From now on your thread owns the device
         * and no other thread will be able to acquire it until a matching
         * call to $(D Device.release()). It is allowed to recursively
         * acquire the device multiple times from the same thread.
         *
         * Note:
         * You must never acquire two different devices at the same time
         * unless this is explicitly allowed. Otherwise the possibility
         * of deadlocks exist.
         *
         * As various Cairo functions can acquire devices when called,
         * these functions may also cause deadlocks when you call them
         * with an acquired device. So you must not have a device acquired
         * when calling them. These functions are marked in the documentation.
         *
         * Throws:
         * An exception if the device is in an error state and could not
         * be acquired. After a successful call to acquire, a matching call
         * to $(D Device.release()) is required.
         */
        void acquire()
        {
            cairo_device_acquire(this.nativePointer);
            checkError();
        }

        /**
         * Releases a device previously acquired using $(D Device.acquire()).
         * See that function for details.
         */
        void release()
        {
            cairo_device_release(this.nativePointer);
            checkError();
        }
}

/**
 * Surface is the abstract type representing all different drawing targets
 * that cairo can render to. The actual drawings are performed using a cairo context.
 *
 * A cairo surface is created by using backend-specific classes,
 * typically of the form $(D BackendSurface).
 *
 * Most surface types allow accessing the surface without using Cairo
 * functions. If you do this, keep in mind that it is mandatory that
 * you call $(D Surface.flush()) before reading from or writing to the
 * surface and that you must use $(D Surface.markDirty()) after modifying it.
 */
public class Surface
{
    ///
    mixin CairoCountedClass!(cairo_surface_t*, "cairo_surface_");

    protected:
        /**
         * Method for use in subclasses.
         * Calls $(D cairo_surface_status(nativePointer)) and throws
         * an exception if the status isn't CAIRO_STATUS_SUCCESS
         */
        final void checkError()
        {
            throwError(cairo_surface_status(nativePointer));
        }

    public:
        /**
         * Create a $(D Surface) from a existing $(D cairo_surface_t*).
         * Surface is a garbage collected class. It will call $(D cairo_surface_destroy)
         * when it gets collected by the GC or when $(D dispose()) is called.
         *
         * Warning:
         * $(D ptr)'s reference count is not increased by this function!
         * Adjust reference count before calling it if necessary
         *
         * $(RED Only use this if you know what your doing!
         * This function should not be needed for standard cairoD usage.)
         */
        this(cairo_surface_t* ptr)
        {
            this.nativePointer = ptr;
            if(!ptr)
            {
                throw new CairoException(cairo_status_t.CAIRO_STATUS_NULL_POINTER);
            }
            checkError();
        }

        /**
         * The createFromNative method for the Surface classes.
         * See $(LINK https://github.com/jpf91/cairoD/wiki/Memory-Management#createFromNative)
         * for more information.
         *
         * Warning:
         * $(RED Only use this if you know what your doing!
         * This function should not be needed for standard cairoD usage.)
         */
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
                version(CAIRO_HAS_XLIB_SURFACE)
                {
                    case cairo_surface_type_t.CAIRO_SURFACE_TYPE_XLIB:
                        return new XlibSurface(ptr);
                }
                default:
                    return new Surface(ptr);
            }
        }

        /**
         * Create a new surface that is as compatible as possible with
         * an existing surface. For example the new surface will have the
         * same fallback resolution and font options as other. Generally,
         * the new surface will also use the same backend as other, unless
         * that is not possible for some reason. The type of the returned
         * surface may be examined with $(D Surface.getType()).
         *
         * Initially the surface contents are all 0 (transparent if
         * contents have transparency, black otherwise.)
         *
         * Params:
         * other = an existing surface used to select the backend of the new surface
         * content = the content for the new surface
         * width = width of the new surface, (in device-space units)
         * height = height of the new surface (in device-space units)
         */
        static Surface createSimilar(Surface other, Content content, int width, int height)
        {
            return createFromNative(cairo_surface_create_similar(other.nativePointer, content, width, height), false);
        }

        /**
         * Create a new surface that is a rectangle within the target surface.
         * All operations drawn to this surface are then clipped and translated
         * onto the target surface. Nothing drawn via this sub-surface
         * outside of its bounds is drawn onto the target surface,
         * making this a useful method for passing constrained child
         * surfaces to library routines that draw directly onto the parent
         * surface, i.e. with no further backend allocations, double
         * buffering or copies.
         *
         * Note:
         * The semantics of subsurfaces have not been finalized yet unless
         * the rectangle is in full device units, is contained within
         * the extents of the target surface, and the target or
         * subsurface's device transforms are not changed.
         *
         * Params:
         * target = an existing surface for which the sub-surface will point to
         * rect = location of the subsurface
         */
        static Surface createForRectangle(Surface target, Rectangle!double rect)
        {
            return createFromNative(cairo_surface_create_for_rectangle(target.nativePointer,
                rect.point.x, rect.point.y, rect.width, rect.height), false);
        }

        /**
         * This function finishes the surface and drops all references
         * to external resources. For example, for the Xlib backend it
         * means that cairo will no longer access the drawable, which
         * can be freed. After calling $(D Surface.finish()) the only
         * valid operations on a surface are getting and setting user,
         * referencing and destroying, and flushing and finishing it.
         *
         * Further drawing to the surface will not affect the surface
         * but will instead trigger a CAIRO_STATUS_SURFACE_FINISHED exception.
         *
         * When the reference count id decreased to zero, cairo will call
         * $(D Surface.finish()) if it hasn't been called already, before
         * freeing the resources associated with the surface.
         */
        void finish()
        {
            cairo_surface_finish(this.nativePointer);
            checkError();
        }

        /**
         * Do any pending drawing for the surface and also restore any temporary
         * modifications cairo has made to the surface's state. This function
         * must be called before switching from drawing on the surface
         * with cairo to drawing on it directly with native APIs. If the
         * surface doesn't support direct access, then this function does
         * nothing.
         */
        void flush()
        {
            cairo_surface_flush(this.nativePointer);
            checkError();
        }

        /**
         * This function returns the device for a surface. See $(D Device).
         */
        Device getDevice()
        {
            auto ptr = cairo_surface_get_device(this.nativePointer);
            if(!ptr)
                return null;
            cairo_device_reference(ptr);
            return new Device(ptr);
        }

        ///Convenience alias
        alias getDevice device;
        
        /**
         * Retrieves the default font rendering options for the surface.
         * This allows display surfaces to report the correct subpixel
         * order for rendering on them, print surfaces to disable hinting
         * of metrics and so forth. The result can then be used with
         * $(new ScaledFont()).
         */
        FontOptions getFontOptions()
        {
            FontOptions fo = FontOptions();
            cairo_surface_get_font_options(this.nativePointer, fo._data._payload);
            fo.checkError();
            return fo;
        }

        ///Convenience alias
        alias getFontOptions fontOptions;
        
        /**
         * This function returns the content type of surface which indicates
         * whether the surface contains color and/or alpha information.
         * See $(D Content).
         */
        Content getContent()
        {
            scope(exit)
                checkError();
            return cairo_surface_get_content(this.nativePointer);
        }

        ///Convenience alias
        alias getContent content;
        
        /**
         * Tells cairo that drawing has been done to surface using means
         * other than cairo, and that cairo should reread any cached areas.
         * Note that you must call $(D Surface.flush()) before doing such drawing.
         */
        void markDirty()
        {
            cairo_surface_mark_dirty(this.nativePointer);
            checkError();
        }

        /**
         * Like $(D Surface.markDirty()), but drawing has been done only
         * to the specified rectangle, so that cairo can retain cached
         * contents for other parts of the surface.
         *
         * Any cached clip set on the surface will be reset by this function,
         * to make sure that future cairo calls have the clip set that they expect.
         */
        void markDirtyRectangle(int x, int y, int width, int height)
        {
            cairo_surface_mark_dirty_rectangle(this.nativePointer, x, y, width, height);
            checkError();
        }

        ///ditto
        void markDirtyRectangle(Rectangle!int rect)
        {
            cairo_surface_mark_dirty_rectangle(this.nativePointer, rect.point.x,
                rect.point.y, rect.width, rect.height);
            checkError();
        }

        /**
         * Sets an offset that is added to the device coordinates determined
         * by the CTM when drawing to surface. One use case for this function
         * is when we want to create a $(D Surface) that redirects drawing
         * for a portion of an onscreen surface to an offscreen surface
         * in a way that is completely invisible to the user of the cairo API.
         * Setting a transformation via $(D Context.translate()) isn't sufficient
         * to do this, since functions like $(D Context.deviceToUser()) will
         * expose the hidden offset.
         *
         * Note:
         * the offset affects drawing to the surface as well as using the
         * surface in a source pattern.
         *
         * Params:
         * x_offset = the offset in the X direction, in device units
         * y_offset = the offset in the Y direction, in device units
         */
        void setDeviceOffset(double x_offset, double y_offset)
        {
            cairo_surface_set_device_offset(this.nativePointer, x_offset, y_offset);
            checkError();
        }
        ///ditto
        void setDeviceOffset(Point offset)
        {
            cairo_surface_set_device_offset(this.nativePointer, offset.x, offset.y);
            checkError();
        }
        
        /**
         * This function returns the previous device offset set
         * by $(D Surface.setDeviceOffset()).
         *
         * Returns:
         * Offset in device units
         */
        Point getDeviceOffset()
        {
            Point tmp;
            cairo_surface_get_device_offset(this.nativePointer, &tmp.x, &tmp.y);
            checkError();
            return tmp;
        }        
        
        ///Convenience property function
        // todo: enable when new D tuples are implemented
        /+@property void deviceOffset(double x_offset, double y_offset)
        {
            setDeviceOffset(x_offset, y_offset);
        }+/
        
        ///ditto
        @property void deviceOffset(Point offset)
        {
            setDeviceOffset(offset);
        }
        
        ///ditto
        @property Point deviceOffset()
        {
            return getDeviceOffset();
        }

        /**
         * Set the horizontal and vertical resolution for image fallbacks.
         *
         * When certain operations aren't supported natively by a backend,
         * cairo will fallback by rendering operations to an image and
         * then overlaying that image onto the output. For backends that
         * are natively vector-oriented, this function can be used to set
         * the resolution used for these image fallbacks, (larger values
         * will result in more detailed images, but also larger file sizes).
         *
         * Some examples of natively vector-oriented backends are the ps,
         * pdf, and svg backends.
         *
         * For backends that are natively raster-oriented, image fallbacks
         * are still possible, but they are always performed at the native
         * device resolution. So this function has no effect on those backends.
         *
         * Note:
         * The fallback resolution only takes effect at the time of
         * completing a page (with $(D Context.showPage()) or $(D Context.copyPage()))
         * so there is currently no way to have more than one fallback
         * resolution in effect on a single page.
         *
         * The default fallback resoultion is 300 pixels per inch in both
         * dimensions.
         */
        void setFallbackResolution(Resolution res)
        {
            cairo_surface_set_fallback_resolution(this.nativePointer, res.x, res.y);
            checkError();
        }

        /**
         * This function returns the previous fallback resolution set
         * by $(D setFallbackResolution()), or default
         * fallback resolution if never set.
         */
        Resolution getFallbackResolution()
        {
            Resolution res;
            cairo_surface_get_fallback_resolution(this.nativePointer, &res.x, &res.y);
            checkError();
            return res;
        }

        ///Convenience property function
        @property void fallbackResolution(Resolution res)
        {
            setFallbackResolution(res);
        }
        
        ///ditto
        @property Resolution fallbackResolution()
        {
            return getFallbackResolution();
        }
        
        /**
         * This function returns the C type of a Surface. See $(D SurfaceType)
         * for available types.
         */
        SurfaceType getType()
        {
            auto tmp = cairo_surface_get_type(this.nativePointer);
            checkError();
            return tmp;
        }

        ///convenience alias
        alias getType type;
        
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

        /**
         * Emits the current page for backends that support multiple pages,
         * but doesn't clear it, so that the contents of the current page
         * will be retained for the next page. Use $(D Surface.showPage())
         * if you want to get an empty page after the emission.
         *
         * There is a convenience function for this that can be called on
         * a $(D Context), namely $(D Context.copyPage()).
         */
        void copyPage()
        {
            cairo_surface_copy_page(this.nativePointer);
            checkError();
        }

        /**
         * Emits and clears the current page for backends that support
         * multiple pages. Use $(D Surface.copyPage()) if you don't
         * want to clear the page.
         *
         * There is a convenience function for this that can be called on
         * a $(D Context), namely $(D Context.showPage()).
         */
        void showPage()
        {
            cairo_surface_show_page(this.nativePointer);
            checkError();
        }

        /**
         * Returns whether the surface supports sophisticated $(D showTextGlyphs())
         * operations. That is, whether it actually uses the provided text
         * and cluster data to a $(D showTextGlyphs()) call.
         *
         * Note:
         * Even if this function returns false, a $(D showTextGlyphs())
         * operation targeted at surface will still succeed. It just will
         * act like a $(D showGlyphs()) operation. Users can use this
         * function to avoid computing UTF-8 text and cluster mapping
         * if the target surface does not use it.
         *
         * Returns:
         * true if surface supports $(D showTextGlyphs()), false otherwise
         */
        bool hasShowTextGlyphs()
        {
            scope(exit)
                checkError();
            return cairo_surface_has_show_text_glyphs(this.nativePointer) ? true : false;
        }

        /**
         * Attach an image in the format mime_type to surface. To remove
         * the data from a surface, call this function with same mime
         * type and NULL for data.
         *
         * The attached image (or filename) data can later be used by
         * backends which support it (currently: PDF, PS, SVG and Win32
         * Printing surfaces) to emit this data instead of making a snapshot
         * of the surface. This approach tends to be faster and requires
         * less memory and disk space.
         *
         * The recognized MIME types are the following: CAIRO_MIME_TYPE_JPEG,
         * CAIRO_MIME_TYPE_PNG, CAIRO_MIME_TYPE_JP2, CAIRO_MIME_TYPE_URI.
         *
         * See corresponding backend surface docs for details about which
         * MIME types it can handle.
         *
         * Caution: the associated MIME data will be discarded if you draw
         * on the surface afterwards. Use this function with care.
         *
         * Params:
         * mime_type = the MIME type of the image data
         * data = the image data to attach to the surface
         * length = the length of the image data
         * destroy = a cairo_destroy_func_t which will be called when the
         *     surface is destroyed or when new image data is attached using
         *     the same mime type.
         * closure = the data to be passed to the destroy notifier
         *
         * Throws:
         * OutOfMemoryError if a slot could not be allocated for the user data.
         *
         * TODO: More D-like API
         *
         * Note:
         * $(RED Only use this if you know what your doing! Make sure you get
         * memory management of the passed in data right!)
         */
        void setMimeData(string type, ubyte* data, ulong length, cairo_destroy_func_t destroy, void* closure)
        {
            throwError(cairo_surface_set_mime_data(this.nativePointer, toStringz(type),
                data, length, destroy, closure));
        }

        /**
         * Return mime data previously attached to surface using the
         * specified mime type. If no data has been attached with the given
         * mime type, data is set null.
         *
         * Params:
         * type = the mime type of the image data
         *
         * TODO: More D-like API
         *
         * Note:
         * $(RED Only use this if you know what your doing! Make sure you get
         * memory management of the data right!)
         */
        void getMimeData(string type, out ubyte* data, out ulong length)
        {
            cairo_surface_get_mime_data(this.nativePointer, toStringz(type), &data, &length);
            checkError();
        }
}

/**
 * This function provides a stride value that will respect all alignment
 * requirements of the accelerated image-rendering code within cairo.
 *
 * Examples:
 * -----------------------------------
 * int stride;
 * ubyte[] data;
 * Surface surface;
 *
 * stride = formatStrideForWidth(format, width);
 * data = new ubyte[](stride * height); //could also use malloc
 * surface = new ImageSurface(data, format, width, height, stride);
 * -----------------------------------
 *
 * Params:
 * format = The desired Format of an image surface to be created
 * width = The desired width of an image surface to be created
 *
 * Returns:
 * the appropriate stride to use given the desired format and width, or
 * -1 if either the format is invalid or the width too large.
 */
int formatStrideForWidth(Format format, int width)
{
    return cairo_format_stride_for_width(format, width);
}

/**
 * Image Surfaces — Rendering to memory buffers
 *
 * Image surfaces provide the ability to render to memory buffers either
 * allocated by cairo or by the calling code. The supported image
 * formats are those defined in $(D Format).
 */
public class ImageSurface : Surface
{
    public:
        /**
         * Create a $(D ImageSurface) from a existing $(D cairo_surface_t*).
         * ImageSurface is a garbage collected class. It will call $(D cairo_surface_destroy)
         * when it gets collected by the GC or when $(D dispose()) is called.
         *
         * Warning:
         * $(D ptr)'s reference count is not increased by this function!
         * Adjust reference count before calling it if necessary
         *
         * $(RED Only use this if you know what your doing!
         * This function should not be needed for standard cairoD usage.)
         */
        this(cairo_surface_t* ptr)
        {
            super(ptr);
        }

        /**
         * Creates an image surface of the specified format and dimensions.
         * Initially the surface contents are all 0. (Specifically, within
         * each pixel, each color or alpha channel belonging to format will
         * be 0. The contents of bits within a pixel, but not belonging
         * to the given format are undefined).
         *
         * Params:
         * format = format of pixels in the surface to create
         * width = width of the surface, in pixels
         * height = height of the surface, in pixels
         */
        this(Format format, int width, int height)
        {
            super(cairo_image_surface_create(format, width, height));
        }

        /**
         * Creates an image surface for the provided pixel data.
         * $(RED The output buffer must be kept around until the $(D Surface)
         * is destroyed or $(D Surface.finish()) is called on the surface.)
         * The initial contents of data will be used as the initial image
         * contents; you must explicitly clear the buffer, using, for
         * example, $(D Context.rectangle()) and $(D Context.fill()) if you
         * want it cleared.
         *
         * Note that the stride may be larger than width*bytes_per_pixel
         * to provide proper alignment for each pixel and row.
         * This alignment is required to allow high-performance rendering
         * within cairo. The correct way to obtain a legal stride value is
         * to call $(D formatStrideForWidth) with the desired format and
         * maximum image width value, and then use the resulting stride
         * value to allocate the data and to create the image surface.
         * See $(D formatStrideForWidth) for example code.
         *
         * Params:
         * data = a pointer to a buffer supplied by the application in
         *     which to write contents. This pointer must be suitably aligned
         *     for any kind of variable, (for example, a pointer returned by malloc).
         * format = the format of pixels in the buffer
         * width = the width of the image to be stored in the buffer
         * height = the height of the image to be stored in the buffer
         * stride = the number of bytes between the start of rows in the
         *     buffer as allocated. This value should always be computed
         *     by $(D formatStrideForWidth) before allocating
         *     the data buffer.
         */
        this(ubyte[] data, Format format, int width, int height, int stride)
        {
            super(cairo_image_surface_create_for_data(data.ptr, format, width, height, stride));
        }

        /**
         * Get a pointer to the data of the image surface,
         * for direct inspection or modification.
         *
         * Warning: There's no way to get the size of the buffer from
         * cairo, so you'll only get a $(D ubyte*). Be careful!
         */
        ubyte* getData()
        {
            scope(exit)
                checkError();
            return cairo_image_surface_get_data(this.nativePointer);
        }

        ///convenience alias
        alias getData data;
        
        /**
         * Get the format of the surface.
         */
        Format getFormat()
        {
            scope(exit)
                checkError();
            return cairo_image_surface_get_format(this.nativePointer);
        }

        ///convenience alias
        alias getFormat format;
        
        /**
         * Get the width of the image surface in pixels.
         */
        int getWidth()
        {
            scope(exit)
                checkError();
            return cairo_image_surface_get_width(this.nativePointer);
        }

        ///convenience alias
        alias getWidth width;
        
        /**
         * Get the height of the image surface in pixels.
         */
        int getHeight()
        {
            scope(exit)
                checkError();
            return cairo_image_surface_get_height(this.nativePointer);
        }

        ///convenience alias
        alias getHeight height;
        
        /**
         * Get the stride of the image surface in bytes.
         */
        int getStride()
        {
            scope(exit)
                checkError();
            return cairo_image_surface_get_stride(this.nativePointer);
        }

        ///convenience alias
        alias getStride stride;
        
        version(D_Ddoc)
        {
            /**
             * Creates a new image surface and initializes the contents to the given PNG file.
             *
             * Params:
             * file = name of PNG file to load
             *
             * Note:
             * Only available if cairo, cairoD and the cairoD user
             * code were compiled with "version=CAIRO_HAS_PNG_FUNCTIONS"
             */
            static ImageSurface fromPng(string file);
            //TODO: fromPNGStream when phobos gets new streaming api
            /**
             * Writes the contents of surface to a new file filename as a PNG image.
             *
             * Params:
             * file = the name of a file to write to
             *
             * Note:
             * Only available if cairo, cairoD and the cairoD user
             * code were compiled with "version=CAIRO_HAS_PNG_FUNCTIONS"
             */
            void writeToPNG(string file);
            //TODO: toPNGStream when phobos gets new streaming api
        }
        else version(CAIRO_HAS_PNG_FUNCTIONS)
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

/**
 * The cairo drawing context
 *
 * $(D Context) is the main object used when drawing with cairo. To draw
 * with cairo, you create a $(D Context), set the target surface, and drawing
 * options for the $(D Context), create shapes with functions like $(D Context.moveTo())
 * and $(D Context.lineTo()), and then draw shapes with $(D Context.stroke())
 * or $(D Context.fill()).
 *
 * $(D Context)'s can be pushed to a stack via $(D Context.save()).
 * They may then safely be changed, without loosing the current state.
 * Use $(D Context.restore()) to restore to the saved state.
 */
public struct Context
{
    /*---------------------------Reference counting stuff---------------------------*/
    protected:
        @property uint _count()
        {
            return cairo_get_reference_count(this.nativePointer);
        }

        void _reference()
        {
            cairo_reference(this.nativePointer);
        }

        void _dereference()
        {
            cairo_destroy(this.nativePointer);
        }

    public:
        /**
         * The underlying $(D cairo_t*) handle
         */
        cairo_t* nativePointer;
        version(D_Ddoc)
        {
             /**
             * Enable / disable memory management debugging for this Context
             * instance. Only available if both cairoD and the cairoD user
             * code were compiled with "debug=RefCounted"
             *
             * Output is written to stdout, see
             * $(LINK https://github.com/jpf91/cairoD/wiki/Memory-Management#debugging)
             * for more information
             */
             bool debugging = false;
        }
        else debug(RefCounted)
        {
            bool debugging = false;
        }

        /**
         * Constructor that tracks the reference count appropriately. If $(D
         * !refCountedIsInitialized), does nothing.
         */
        this(this)
        {
            if (this.nativePointer is null)
                return;
            this._reference();
            debug(RefCounted)
                if (this.debugging)
            {
                     writeln(typeof(this).stringof,
                    "@", cast(void*) this.nativePointer, ": bumped refcount to ",
                    this._count);
            }
        }

        ~this()
        {
            this.dispose();
        }

        /**
         * Explicitly drecrease the reference count.
         *
         * See $(LINK https://github.com/jpf91/cairoD/wiki/Memory-Management#2.1-structs)
         * for more information.
         */
        void dispose()
        {
            if (this.nativePointer is null)
                return;
            assert(this._count > 0);
            if (this._count > 1)
            {
                debug(RefCounted)
                    if (this.debugging)
                {
                         writeln(typeof(this).stringof,
                        "@", cast(void*)this.nativePointer,
                        ": decrement refcount to ", this._count - 1);
                }
                this._dereference();
                this.nativePointer = null;
                return;
            }
            debug(RefCounted)
                if (this.debugging)
            {
                write(typeof(this).stringof,
                        "@", cast(void*)this.nativePointer, ": freeing... ");
                stdout.flush();
            }
            //Done, deallocate is done by cairo
            this._dereference();
            this.nativePointer = null;
            debug(RefCounted) if (this.debugging) writeln("done!");
        }
        /**
         * Assignment operator
         */
        void opAssign(typeof(this) rhs)
        {
            //Black magic?
            swap(this.nativePointer, rhs.nativePointer);
            debug(RefCounted)
                this.debugging = rhs.debugging;
        }
    /*------------------------End of Reference counting stuff-----------------------*/


    protected:
        final void checkError()
        {
            throwError(cairo_status(nativePointer));
        }


    public:
        /**
         * Creates a new $(D Context) with all graphics state parameters set
         * to default values and with target as a target surface. The
         * target surface should be constructed with a backend-specific
         * function such as $(D new ImageSurface()).
         *
         * This function references target, so you can immediately call
         * $(D Surface.dispose()) on it if you don't need to maintain
         * a separate reference to it.
         */
        this(Surface target)
        {
            //cairo_create already references the pointer, so _reference
            //isn't necessary
            nativePointer = cairo_create(target.nativePointer);
            throwError(cairo_status(nativePointer));
        }

        /**
         * Create a $(D Context) from a existing $(D cairo_t*).
         * Context is a garbage collected class. It will call $(D cairo_destroy)
         * when it gets collected by the GC or when $(D dispose()) is called.
         *
         * Warning:
         * $(D ptr)'s reference count is not increased by this function!
         * Adjust reference count before calling it if necessary
         *
         * $(RED Only use this if you know what your doing!
         * This function should not be needed for standard cairoD usage.)
         */
        this(cairo_t* ptr)
        {
            this.nativePointer = ptr;
            if(!ptr)
            {
                throw new CairoException(cairo_status_t.CAIRO_STATUS_NULL_POINTER);
            }
            checkError();
        }

        /**
         * Makes a copy of the current state of cr and saves it on an
         * internal stack of saved states for cr. When $(D Context.restore())
         * is called, cr will be restored to the saved state. Multiple
         * calls to $(D Context.save()) and  $(D Context.restore()) can be nested; each
         * call to  $(D Context.restore()) restores the state from the matching
         * paired $(D Context.save()).
         *
         * It isn't necessary to clear all saved states before a $(D Context)
         * is freed. If the reference count of a $(D Context) drops to zero
         * , any saved states will be freed along with the $(D Context).
         */
        void save()
        {
            cairo_save(this.nativePointer);
            checkError();
        }

        /**
         * Restores cr to the state saved by a preceding call to
         * $(D Context.save()) and removes that state from the stack of
         * saved states.
         */
        void restore()
        {
            cairo_restore(this.nativePointer);
            checkError();
        }

        /**
         * Gets the target surface for the cairo context as passed to
         * the constructor.
         */
        Surface getTarget()
        {
            return Surface.createFromNative(cairo_get_target(this.nativePointer));
        }
        
        ///convenience alias
        alias getTarget target;

        /**
         * Temporarily redirects drawing to an intermediate surface known
         * as a group. The redirection lasts until the group is completed
         * by a call to $(D Context.popGroup()) or $(D Context.popGroupToSource()).
         * These calls provide the result of any drawing to the group
         * as a pattern, (either as an explicit object, or set as the
         * source pattern).
         *
         * This group functionality can be convenient for performing
         * intermediate compositing. One common use of a group is to render
         * objects as opaque within the group, (so that they occlude each other),
         * and then blend the result with translucence onto the destination.
         *
         * Groups can be nested arbitrarily deep by making balanced calls
         * to $(D Context.pushGgroup())/$(D Context.popGroup()). Each call pushes/pops
         * the new target group onto/from a stack.
         *
         * The $(D Context.pushGroup()) function calls $(D Context.save()) so that any
         * changes to the graphics state will not be visible outside the
         * group, (the $(D Context.popGroup) functions call $(D Context.restore())).
         *
         * By default the intermediate group will have a content type of
         * CAIRO_CONTENT_COLOR_ALPHA. Other content types can be chosen
         * for the group by using $(D Context.pushGroup(Content)) instead.
         *
         * As an example, here is how one might fill and stroke a path with
         * translucence, but without any portion of the fill being visible
         * under the stroke:
         * -------------------------------
         * cr.pushGroup();
         * cr.setSource(fill_pattern);
         * cr.fillPreserve();
         * cr.setSource(stroke_pattern);
         * cr.stroke();
         * cr.popGroupToSource();
         * cr.paintWithAlpha(alpha);
         * -------------------------------
         */
        void pushGroup()
        {
            cairo_push_group(this.nativePointer);
            checkError();
        }

        /**
         * Temporarily redirects drawing to an intermediate surface known
         * as a group. The redirection lasts until the group is completed
         * by a call to $(D Context.popGroup()) or $(D Context.popGroupToSource()).
         * These calls provide the result of any drawing to the group as
         * a pattern, (either as an explicit object, or set as the source
         * pattern).
         *
         * The group will have a content type of content. The ability to
         * control this content type is the only distinction between this
         * function and $(D Context.pushGroup()) which you should see for a more
         * detailed description of group rendering.
         */
        void pushGroup(Content cont)
        {
            cairo_push_group_with_content(this.nativePointer, cont);
            checkError();
        }

        /**
         * Terminates the redirection begun by a call to $(D Context.pushGroup())
         * or $(D Context.pushGroup(Content)) and returns a new pattern
         * containing the results of all drawing operations performed to
         * the group.
         *
         * The $(D Context.popGroup()) function calls $(D Context.restore()), (balancing
         * a call to $(D Context.save()) by the $(D Context.pushGroup()) function), so that any
         * changes to the graphics state will not be visible outside the group.
         */
        Pattern popGroup()
        {
            auto ptr = cairo_pop_group(this.nativePointer);
            return Pattern.createFromNative(ptr, false);
        }

        /**
         * Terminates the redirection begun by a call to $(D Context.pushGroup())
         * or $(D Context.pushGroup(Content)) and installs the resulting
         * pattern as the source pattern in the given cairo context.
         *
         * The behavior of this function is equivalent to the sequence
         * of operations:
         * -----------------------
         * Pattern group = cr.popGroup();
         * cr.setSource(group);
         * group.dispose();
         * -----------------------
         * but is more convenient as their is no need for a variable to
         * store the short-lived pointer to the pattern.
         *
         * The $(D Context.popGroup()) function calls $(D Context.restore()),
         * (balancing a call to $(D Context.save()) by the $(D Context.pushGroup()) function),
         * so that any changes to the graphics state will not be
         * visible outside the group.
         */
        void popGroupToSource()
        {
            cairo_pop_group_to_source(this.nativePointer);
            checkError();
        }

        /**
         * Gets the current destination surface for the context.
         * This is either the original target surface as passed to
         * the Context constructor or the target surface for the current
         * group as started by the most recent call to
         *  $(D Context.pushGroup()) or  $(D Context.pushGroup(Content)).
         */
        Surface getGroupTarget()
        {
            return Surface.createFromNative(cairo_get_group_target(this.nativePointer));
        }

        ///convenience alias
        alias getGroupTarget groupTarget;
        
        /**
         * Sets the source pattern within cr to an opaque color.
         * This opaque color will then be used for any subsequent
         * drawing operation until a new source pattern is set.
         *
         * The color components are floating point numbers in the range
         * 0 to 1. If the values passed in are outside that range,
         * they will be clamped.
         *
         * The default source pattern is opaque black,
         * (that is, it is equivalent to setSourceRGB(0.0, 0.0, 0.0)).
         */
        void setSourceRGB(double red, double green, double blue)
        {
            cairo_set_source_rgb(this.nativePointer, red, green, blue);
            checkError();
        }

        ///ditto
        void setSourceRGB(RGB rgb)
        {
            cairo_set_source_rgb(this.nativePointer, rgb.red, rgb.green, rgb.blue);
            checkError();
        }

        /**
         * Sets the source pattern within cr to a translucent color.
         * This color will then be used for any subsequent drawing
         * operation until a new source pattern is set.
         *
         * The color and alpha components are floating point numbers in
         * the range 0 to 1. If the values passed in are outside that
         * range, they will be clamped.
         *
         * The default source pattern is opaque black, (that is, it is
         * equivalent to setSourceRGBA(0.0, 0.0, 0.0, 1.0)).
         */
        void setSourceRGBA(double red, double green, double blue, double alpha)
        {
            cairo_set_source_rgba(this.nativePointer, red, green, blue, alpha);
            checkError();
        }

        ///ditto
        void setSourceRGBA(RGBA rgba)
        {
            cairo_set_source_rgba(this.nativePointer, rgba.red, rgba.green, rgba.blue, rgba.alpha);
            checkError();
        }

        /**
         * Sets the source pattern within cr to source. This pattern will
         * then be used for any subsequent drawing operation until
         * a new source pattern is set.
         *
         * Note: The pattern's transformation matrix will be locked to
         * the user space in effect at the time of setSource(). This
         * means that further modifications of the current transformation
         * matrix will not affect the source pattern.
         * See $(D Pattern.setMatrix()).
         *
         * The default source pattern is a solid pattern that is opaque
         * black, (that is, it is equivalent
         * to setSourceRGB(0.0, 0.0, 0.0)).
         */
        void setSource(Pattern pat)
        {
            cairo_set_source(this.nativePointer, pat.nativePointer);
            checkError();
        }

        /**
         * Gets the current source pattern for cr.
         */
        Pattern getSource()
        {
            return Pattern.createFromNative(cairo_get_source(this.nativePointer));
        }        
        
        ///Convenience property
        @property void source(Pattern pat)
        {
            setSource(pat);
        }      
        
        ///ditto
        @property Pattern source()
        {
            return getSource();
        }
        
        /**
         * This is a convenience function for creating a pattern from
         * surface and setting it as the source in cr with $(D Context.setSource()).
         *
         * The x and y parameters give the user-space coordinate at
         * which the surface origin should appear. (The surface origin
         * is its upper-left corner before any transformation has been
         * applied.) The x and y parameters are negated and then set
         * as translation values in the pattern matrix.
         *
         * Other than the initial translation pattern matrix,
         * as described above, all other pattern attributes,
         * (such as its extend mode), are set to the default values as
         * in $(D new SurfacePattern()). The resulting pattern can be
         * queried with $(D Context.getSource()) so that these
         * attributes can be modified if desired, (eg. to create a
         * repeating pattern with $(D Pattern.setExtend())).
         *
         * Params:
         * x = User-space X coordinate for surface origin
         * y = User-space Y coordinate for surface origin
         */
        void setSourceSurface(Surface sur, double x, double y)
        {
            cairo_set_source_surface(this.nativePointer, sur.nativePointer, x, y);
            checkError();
        }
        ///ditto
        void setSourceSurface(Surface sur, Point p1)
        {
            cairo_set_source_surface(this.nativePointer, sur.nativePointer, p1.x, p1.y);
            checkError();
        }

        /**
         * Set the antialiasing mode of the rasterizer used for
         * drawing shapes. This value is a hint, and a particular
         * backend may or may not support a particular value. At
         * the current time, no backend supports CAIRO_ANTIALIAS_SUBPIXEL
         * when drawing shapes.
         *
         * Note that this option does not affect text rendering,
         * instead see $(D FontOptions.setAntialias()).
         */
        void setAntiAlias(AntiAlias antialias)
        {
            cairo_set_antialias(this.nativePointer, antialias);
            checkError();
        }

        /**
         * Gets the current shape antialiasing mode, as set by $(D setAntiAlias).
         */
        AntiAlias getAntiAlias()
        {
            scope(exit)
                checkError();
            return cairo_get_antialias(this.nativePointer);
        }

        ///Convenience property
        @property void antiAlias(AntiAlias aa)
        {
            setAntiAlias(aa);
        }
        
        ///ditto
        @property AntiAlias antiAlias()
        {
            return getAntiAlias();
        }
        
        /**
         * Sets the dash pattern to be used by $(D stroke()). A dash
         * pattern is specified by dashes, an array of positive values.
         * Each value provides the length of alternate "on" and
         * "off" portions of the stroke. The offset specifies an offset
         * into the pattern at which the stroke begins.
         *
         * Each "on" segment will have caps applied as if the segment
         * were a separate sub-path. In particular, it is valid to use
         * an "on" length of 0.0 with CAIRO_LINE_CAP_ROUND or
         * CAIRO_LINE_CAP_SQUARE in order to distributed dots
         * or squares along a path.
         *
         * Note: The length values are in user-space units as
         * evaluated at the time of stroking. This is not necessarily
         * the same as the user space at the time of $(D setDash()).
         *
         * If dashes is empty dashing is disabled.
         *
         * If dashes.length is 1 a symmetric pattern is assumed with alternating
         * on and off portions of the size specified by the single value
         * in dashes.
         *
         * If any value in dashes is negative, or if all values are 0, then
         * cr will be put into an error state with a
         * status of CAIRO_STATUS_INVALID_DASH.
         *
         * Params:
         * dashes = an array specifying alternate lengths of on and off stroke portions
         * offset = an offset into the dash pattern at which the stroke should start
         */
        void setDash(const(double[]) dashes, double offset)
        {
            cairo_set_dash(this.nativePointer, dashes.ptr, dashes.length, offset);
            checkError();
        }

        /**
         * Gets the current dash array.
         */
        double[] getDash(out double offset)
        {
            double[] dashes = new double[](this.getDashCount());
            cairo_get_dash(this.nativePointer, dashes.ptr, &offset);
            checkError();
            return dashes;
        }

        /**
         * This function returns the length of the dash array in cr
         * (0 if dashing is not currently in effect).
         */
        int getDashCount()
        {
            scope(exit)
                checkError();
            return cairo_get_dash_count(this.nativePointer);
        }
        
        /**
         * Set the current fill rule within the cairo context. The fill
         * rule is used to determine which regions are inside or outside
         * a complex (potentially self-intersecting) path. The current
         * fill rule affects both $(D fill()) and $(D clip()). See
         * $(D FillRule) for details on the semantics of each
         * available fill rule.
         *
         * The default fill rule is CAIRO_FILL_RULE_WINDING.
         */
        void setFillRule(FillRule rule)
        {
            cairo_set_fill_rule(this.nativePointer, rule);
            checkError();
        }

        /**
         * Gets the current fill rule, as set by $(D setFillRule).
         */
        FillRule getFillRule()
        {
            scope(exit)
                checkError();
            return cairo_get_fill_rule(this.nativePointer);
        }

        ///Convenience property
        @property void fillRule(FillRule rule)
        {
            setFillRule(rule);
        }
        
        ///ditto
        @property FillRule fillRule()
        {
            return getFillRule();
        }
        
        /**
         * Sets the current line cap style within the cairo context.
         * See $(D LineCap) for details about how the available
         * line cap styles are drawn.
         *
         * As with the other stroke parameters, the current line cap
         * style is examined by $(D stroke()), $(D strokeExtents())
         * and $(D strokeToPath()), but does not have any
         * effect during path construction.
         *
         * The default line cap style is CAIRO_LINE_CAP_BUTT.
         */
        void setLineCap(LineCap cap)
        {
            cairo_set_line_cap(this.nativePointer, cap);
            checkError();
        }

        /**
         * Gets the current line cap style, as set by $(D setLineCap()).
         */
        LineCap getLineCap()
        {
            scope(exit)
                checkError();
            return cairo_get_line_cap(this.nativePointer);
        }

        ///Convenience property
        @property void lineCap(LineCap cap)
        {
            setLineCap(cap);
        }
        
        ///ditto
        @property LineCap lineCap()
        {
            return getLineCap();
        }
        
        /**
         * Sets the current line join style within the cairo context.
         * See $(D LineJoin) for details about how the available
         * line join styles are drawn.
         *
         * As with the other stroke parametes, the current line join
         * style is examined by $(D stroke()), $(D strokeExtents())
         * and $(D strokeToPath()), but does not have any effect
         * during path construction.
         *
         * The default line join style is CAIRO_LINE_JOIN_MITER.
         */
        void setLineJoin(LineJoin join)
        {
            cairo_set_line_join(this.nativePointer, join);
            checkError();
        }

        /**
         * Gets the current line join style, as set by $(D setLineJoin)
         */
        LineJoin getLineJoin()
        {
            scope(exit)
                checkError();
            return cairo_get_line_join(this.nativePointer);
        }

        ///Convenience property
        @property void lineJoin(LineJoin join)
        {
            setLineJoin(join);
        }
        
        ///ditto
        @property LineJoin lineJoin()
        {
            return getLineJoin();
        }        
        
        /**
         * Sets the current line width within the cairo context. The line
         * width value specifies the diameter of a pen that is circular
         * in user space, (though device-space pen may be an ellipse
         * in general due to scaling/shear/rotation of the CTM).
         *
         * Note: When the description above refers to user space and CTM
         * it refers to the user space and CTM in effect at the time
         * of the stroking operation, not the user space and CTM in
         * effect at the time of the call to $(D setLineWidth()).
         * The simplest usage makes both of these spaces identical.
         * That is, if there is no change to the CTM between a call to
         * $(D setLineWidth()) and the stroking operation, then one
         * can just pass user-space values to $(D setLineWidth()) and
         * ignore this note.
         *
         * As with the other stroke parameters, the current line width is
         * examined by $(D stroke()), $(D strokeExtents())
         * and $(D strokeToPath()), but does not have any effect during
         * path construction.
         *
         * The default line width value is 2.0.
         */
        void setLineWidth(double width)
        {
            cairo_set_line_width(this.nativePointer, width);
            checkError();
        }

        /**
         * This function returns the current line width value exactly
         * as set by cairo_set_line_width(). Note that the value is
         * unchanged even if the CTM has changed between the calls
         * to $(D setLineWidth()) and $(D getLineWidth()).
         */
        double getLineWidth()
        {
            scope(exit)
                checkError();
            return cairo_get_line_width(this.nativePointer);
        }

        ///Convenience property
        @property void lineWidth(double width)
        {
            setLineWidth(width);
        }
        
        ///ditto
        @property double lineWidth()
        {
            return getLineWidth();
        }           
        
        /**
         * Sets the current miter limit within the cairo context.
         *
         * If the current line join style is set to
         * CAIRO_LINE_JOIN_MITER (see cairo_set_line_join()), the miter
         * limit is used to determine whether the lines should be joined
         * with a bevel instead of a miter. Cairo divides the length of
         * the miter by the line width. If the result is greater than the
         * miter limit, the style is converted to a bevel.
         *
         * As with the other stroke parameters, the current line miter
         * limit is examined by $(D stroke()), $(D strokeExtents())
         * and $(D strokeToPath()), but does not have any effect
         * during path construction.
         *
         * The default miter limit value is 10.0, which will convert
         * joins with interior angles less than 11 degrees to bevels
         * instead of miters. For reference, a miter limit of 2.0 makes
         * the miter cutoff at 60 degrees, and a miter limit of 1.414
         * makes the cutoff at 90 degrees.
         *
         * A miter limit for a desired angle can be computed as: miter
         * limit = 1/sin(angle/2)
         */
        void setMiterLimit(double limit)
        {
            cairo_set_miter_limit(this.nativePointer, limit);
            checkError();
        }

        /**
         * Gets the current miter limit, as set by $(D setMiterLimit)
         */
        double getMiterLimit()
        {
            scope(exit)
                checkError();
            return cairo_get_miter_limit(this.nativePointer);
        }

        ///Convenience property
        @property void miterLimit(double limit)
        {
            setMiterLimit(limit);
        }
        
        ///ditto
        @property double miterLimit()
        {
            return getMiterLimit();
        }               
        
        /**
         * Sets the compositing operator to be used for all
         * drawing operations. See $(D Operator) for details on
         * the semantics of each available compositing operator.
         *
         * The default operator is CAIRO_OPERATOR_OVER.
         */
        void setOperator(Operator op)
        {
            cairo_set_operator(this.nativePointer, op);
            checkError();
        }

        /**
         * Gets the current compositing operator for a cairo context.
         */
        Operator getOperator()
        {
            scope(exit)
                checkError();
            return cairo_get_operator(this.nativePointer);
        }

        ///Convenience property
        @property void operator(Operator op)
        {
            setOperator(op);
        }
        
        ///ditto
        @property Operator operator()
        {
            return getOperator();
        }               
        
        /**
         * Sets the tolerance used when converting paths into trapezoids.
         * Curved segments of the path will be subdivided until the maximum
         * deviation between the original path and the polygonal
         * approximation is less than tolerance. The default value
         * is 0.1. A larger value will give better performance, a smaller
         * value, better appearance. (Reducing the value from the
         * default value of 0.1 is unlikely to improve appearance
         * significantly.) The accuracy of paths within Cairo is limited
         * by the precision of its internal arithmetic, and the prescribed
         * tolerance is restricted to the smallest representable
         * internal value.
         */
        void setTolerance(double tolerance)
        {
            cairo_set_tolerance(this.nativePointer, tolerance);
            checkError();
        }

        /**
         * Gets the current tolerance value, as set by $(D setTolerance)
         */
        double getTolerance()
        {
            scope(exit)
                checkError();
            return cairo_get_tolerance(this.nativePointer);
        }

        ///Convenience property
        @property void tolerance(double tolerance)
        {
            setTolerance(tolerance);
        }
        
        ///ditto
        @property double tolerance()
        {
            return getTolerance();
        }    
        
        /**
         * Establishes a new clip region by intersecting the current
         * clip region with the current path as it would be filled by
         * $(D fill()) and according to the current
         * fill rule (see $(D setFillRule())).
         *
         * After $(D clip()), the current path will be cleared from the
         * cairo context.
         *
         * The current clip region affects all drawing operations by
         * effectively masking out any changes to the surface that are
         * outside the current clip region.
         *
         * Calling $(D clip()) can only make the clip region smaller,
         * never larger. But the current clip is part of the graphics state,
         * so a temporary restriction of the clip region can be achieved
         * by calling $(D clip()) within a $(D save())/$(D restore())
         * pair. The only other means of increasing the size of the clip
         * region is $(D resetClip()).
         */
        void clip()
        {
            cairo_clip(this.nativePointer);
            checkError();
        }

        /**
         * Establishes a new clip region by intersecting the current clip
         * region with the current path as it would be filled by
         * $(D fill()) and according to the current fill rule
         * (see $(D setFillRule())).
         *
         * Unlike $(D clip()), $(D clipPreserve()) preserves the
         * path within the cairo context.
         *
         * The current clip region affects all drawing operations by
         * effectively masking out any changes to the surface that are
         * outside the current clip region.
         *
         * Calling $(D clipPreserve()) can only make the clip region
         * smaller, never larger. But the current clip is part of the
         * graphics state, so a temporary restriction of the clip region
         * can be achieved by calling $(D clip()) within a $(D save())/$(D restore())
         * pair. The only other means of increasing the size of the clip
         * region is $(D resetClip()).
         */
        void clipPreserve()
        {
            cairo_clip_preserve(this.nativePointer);
            checkError();
        }

        /**
         * Computes a bounding box in user coordinates covering the area
         * inside the current clip.
         */
        Box clipExtents()
        {
            Box tmp;
            cairo_clip_extents(this.nativePointer, &tmp.point1.x, &tmp.point1.y, &tmp.point2.x, &tmp.point2.y);
            checkError();
            return tmp;
        }

        /**
         * Tests whether the given point is inside the area that would
         * be visible through the current clip, i.e. the area that
         * would be filled by a cairo_paint() operation.
         *
         * See $(D clip()), and $(D clipPreserve()).
         */
        bool inClip(Point point)
        {
            scope(exit)
                checkError();
            return cairo_in_clip(this.nativePointer, point.x, point.y) ? true : false;
        }

        /**
         * Reset the current clip region to its original, unrestricted
         * state. That is, set the clip region to an infinitely
         * large shape containing the target surface. Equivalently,
         * if infinity is too hard to grasp, one can imagine the clip
         * region being reset to the exact bounds of the target surface.
         *
         * Note that code meant to be reusable should not call
         * $(D resetClip()) as it will cause results unexpected by
         * higher-level code which calls $(D clip()). Consider using
         * $(D save()) and $(D restore()) around $(D clip()) as a
         * more robust means of temporarily restricting the clip region.
         */
        void resetClip()
        {
            cairo_reset_clip(this.nativePointer);
            checkError();
        }

        /**
         * Gets the current clip region as a list of rectangles in user
         * coordinates.
         */
        Rectangle!(double)[] copyClipRectangles()
        {
            Rectangle!(double)[] list;
            auto nList = cairo_copy_clip_rectangle_list(this.nativePointer);
            scope(exit)
                cairo_rectangle_list_destroy(nList);
            throwError(nList.status);
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

        /**
         * A drawing operator that fills the current path according to
         * the current fill rule, (each sub-path is implicitly closed
         * before being filled). After c$(D fill()), the current
         * path will be cleared from the cairo context. See
         * $(D setFillRule()) and $(D fillPreserve()).
         */
        void fill()
        {
            cairo_fill(this.nativePointer);
            checkError();
        }

        /**
         * A drawing operator that fills the current path according to
         * the current fill rule, (each sub-path is implicitly closed
         * before being filled). Unlike $(D fill()), $(D fillPreserve())
         * preserves the path within the cairo context.
         */
        void fillPreserve()
        {
            cairo_fill_preserve(this.nativePointer);
            checkError();
        }

        /**
         * Computes a bounding box in user coordinates covering the area
         * that would be affected, (the "inked" area), by a
         * $(D fill()) operation given the current path and fill parameters.
         * If the current path is empty, returns an empty rectangle
         * ((0,0), (0,0)). Surface dimensions and clipping are not
         * taken into account.
         *
         * Contrast with $(D pathExtents()), which is similar, but
         * returns non-zero extents for some paths with no inked area,
         * (such as a simple line segment).
         *
         * Note that $(D fillExtents()) must necessarily do more work
         * to compute the precise inked areas in light of the fill rule,
         * so $(D pathExtents()) may be more desirable for sake of
         * performance if the non-inked path extents are desired.
         *
         * See $(D fill()), $(D setFillRule()) and $(D fillPreserve()).
         */
        Box fillExtends()
        {
            Box tmp;
            cairo_fill_extents(this.nativePointer, &tmp.point1.x, &tmp.point1.y, &tmp.point2.x, &tmp.point2.y);
            checkError();
            return tmp;
        }

        /**
         * Tests whether the given point is inside the area that would
         * be affected by a cairo_fill() operation given the current path
         * and filling parameters. Surface dimensions and clipping are not
         * taken into account.
         *
         * See $(D fill()), $(D setFillRule()) and $(D fillPreserve()).
         */
        bool inFill(Point point)
        {
            scope(exit)
                checkError();
            return cairo_in_fill(this.nativePointer, point.x, point.y) ? true : false;
        }

        /**
         * A drawing operator that paints the current source using the
         * alpha channel of pattern as a mask. (Opaque areas of pattern
         * are painted with the source, transparent areas are not painted.)
         */
        void mask(Pattern pattern)
        {
            cairo_mask(this.nativePointer, pattern.nativePointer);
            checkError();
        }

        /**
         * A drawing operator that paints the current source using
         * the alpha channel of surface as a mask. (Opaque areas of
         * surface are painted with the source, transparent areas
         * are not painted.)
         *
         * Params:
         * location = coordinates at which to place the origin of surface
         */
        void maskSurface(Surface surface, Point location)
        {
            cairo_mask_surface(this.nativePointer, surface.nativePointer, location.x, location.y);
            checkError();
        }
        ///ditto
        void maskSurface(Surface surface, double x, double y)
        {
            cairo_mask_surface(this.nativePointer, surface.nativePointer, x, y);
            checkError();
        }

        /**
         * A drawing operator that paints the current source everywhere
         * within the current clip region.
         */
        void paint()
        {
            cairo_paint(this.nativePointer);
            checkError();
        }

        /**
         * A drawing operator that paints the current source everywhere
         * within the current clip region using a mask of constant alpha
         * value alpha. The effect is similar to $(D paint()), but
         * the drawing is faded out using the alpha value.
         */
        void paintWithAlpha(double alpha)
        {
            cairo_paint_with_alpha(this.nativePointer, alpha);
            checkError();
        }

        /**
         * A drawing operator that strokes the current path according to
         * the current line width, line join, line cap, and dash settings.
         * After $(D stroke()), the current path will be cleared from
         * the cairo context. See $(D setLineWidth()),
         * $(D setLineJoin()), $(D setLineCap()), $(D setDash()),
         * and $(D strokePreserve()).
         *
         * Note: Degenerate segments and sub-paths are treated specially
         * and provide a useful result. These can result in two
         * different situations:
         *
         * 1. Zero-length "on" segments set in cairo_set_dash(). If the
         * cap style is CAIRO_LINE_CAP_ROUND or CAIRO_LINE_CAP_SQUARE
         * then these segments will be drawn as circular dots or squares
         * respectively. In the case of CAIRO_LINE_CAP_SQUARE, the
         * orientation of the squares is determined by the direction
         * of the underlying path.
         *
         * 2. A sub-path created by $(D moveTo()) followed by either a
         * $(D closePath()) or one or more calls to $(D lineTo()) to
         * the same coordinate as the $(D moveTo()). If the cap style
         * is CAIRO_LINE_CAP_ROUND then these sub-paths will be drawn as
         * circular dots. Note that in the case of CAIRO_LINE_CAP_SQUARE
         * a degenerate sub-path will not be drawn at all, (since the
         * correct orientation is indeterminate).
         *
         * In no case will a cap style of CAIRO_LINE_CAP_BUTT cause
         * anything to be drawn in the case of either degenerate
         * segments or sub-paths.
         */
        void stroke()
        {
            cairo_stroke(this.nativePointer);
            checkError();
        }

        /**
         * A drawing operator that strokes the current path according to
         * the current line width, line join, line cap, and dash settings.
         * Unlike $(D stroke()), $(D strokePreserve()) preserves
         * the path within the cairo context.
         *
         * See $(D setLineWidth()), $(D setLineJoin()),
         * $(D setLineCap()), $(D set_dash()), and $(D strokePreserve()).
         */
        void strokePreserve()
        {
            cairo_stroke_preserve(this.nativePointer);
            checkError();
        }

        /**
         * Computes a bounding box in user coordinates covering the area
         * that would be affected, (the "inked" area), by a $(D stroke())
         * operation given the current path and stroke parameters. If the
         * current path is empty, returns an empty rectangle ((0,0), (0,0)).
         * Surface dimensions and clipping are not taken into account.
         *
         * Note that if the line width is set to exactly zero, then
         * $(D strokeExtents()) will return an empty rectangle.
         * Contrast with $(D pathExtents()) which can be used to
         * compute the non-empty bounds as the line width approaches zero.
         *
         * Note that $(D strokeExtents()) must necessarily do more
         * work to compute the precise inked areas in light of the
         * stroke parameters, so $(D pathExtents()) may be more
         * desirable for sake of performance if non-inked path extents
         * are desired.
         *
         * See $(D stroke()), $(D setLineWidth()), $(D setLineJoin()),
         * $(D setLineCap()), $(D set_dash()), and $(D strokePreserve()).
         */
        Box strokeExtends()
        {
            Box tmp;
            cairo_stroke_extents(this.nativePointer, &tmp.point1.x, &tmp.point1.y, &tmp.point2.x, &tmp.point2.y);
            checkError();
            return tmp;
        }

        /**
         * Tests whether the given point is inside the area that would be
         * affected by a cairo_stroke() operation given the current path
         * and stroking parameters. Surface dimensions and clipping are
         * not taken into account.
         *
         * See $(D stroke()), $(D setLineWidth()), $(D setLineJoin()),
         * $(D setLineCap()), $(D set_dash()), and $(D strokePreserve()).
         */
        bool inStroke(Point point)
        {
            scope(exit)
                checkError();
            return cairo_in_stroke(this.nativePointer, point.x, point.y) ? true : false;
        }
        ///ditto
        bool inStroke(double x, double y)
        {
            scope(exit)
                checkError();
            return cairo_in_stroke(this.nativePointer, x, y) ? true : false;
        }

        /**
         * Emits the current page for backends that support multiple
         * pages, but doesn't clear it, so, the contents of the current
         * page will be retained for the next page too.
         * Use $(D showPage()) if you want to get an empty page after
         * the emission.
         *
         * This is a convenience function that simply calls $(D Surface.copyPage())
         * on this's target.
         */
        void copyPage()
        {
            cairo_copy_page(this.nativePointer);
            checkError();
        }

        /**
         * Emits and clears the current page for backends that support
         * multiple pages. Use $(D copyPage()) if you don't want to
         * clear the page.
         *
         * This is a convenience function that simply calls
         * $(D Surface.showPage()) on this's target.
         */
        void showPage()
        {
            cairo_show_page(this.nativePointer);
            checkError();
        }

        /*
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
        */

        /**
         * Creates a copy of the current path and returns it to the user
         * as a $(D Path). See $(D PathRange) for hints on how to
         * iterate over the returned data structure.
         */
        Path copyPath()
        {
            return Path(cairo_copy_path(this.nativePointer));
        }

        /**
         * Gets a flattened copy of the current path and returns it to
         * the user as a $(D Path). See $(D PathRange) for hints
         * on how to iterate over the returned data structure.
         *
         * This function is like $(D copyPath()) except that any
         * curves in the path will be approximated with piecewise-linear
         * approximations, (accurate to within the current tolerance value).
         * That is, the result is guaranteed to not have any elements of
         * type CAIRO_PATH_CURVE_TO which will instead be replaced by
         * a series of CAIRO_PATH_LINE_TO elements.
         */
        Path copyPathFlat()
        {
            return Path(cairo_copy_path_flat(this.nativePointer));
        }

        /**
         * Append the path onto the current path. The path may be
         * the return value from one of $(D copyPath()) or $(D copyPathFlat()).
         */
        void appendPath(Path p)
        {
            cairo_append_path(this.nativePointer, p.nativePointer);
            checkError();
        }

        /**
         * appendPath for user created paths. There is no high level API
         * for user defined paths. Use $(D appendPath(Path p)) for paths
         * which were obtained from cairo.
         *
         * See $(D cairo_path_t) for details
         * on how the path data structure should be initialized,
         * and note that path.status must be initialized to CAIRO_STATUS_SUCCESS.
         *
         * Warning:
         * $(RED Only use this if you know what your doing!
         * This function should not be needed for standard cairoD usage.)
         */
        void appendPath(cairo_path_t* path)
        {
            cairo_append_path(this.nativePointer, path);
            checkError();
        }

        /**
         * Returns whether a current point is defined on the current path.
         * See $(D getCurrentPoint()) for details on the current point.
         */
        bool hasCurrentPoint()
        {
            scope(exit)
                checkError();
            return cairo_has_current_point(this.nativePointer) ? true : false;
        }

        /**
         * Gets the current point of the current path, which is conceptually
         * the final point reached by the path so far.
         *
         * The current point is returned in the user-space coordinate system.
         * If there is no defined current point or if cr is in an error status,
         * x and y will both be set to 0.0. It is possible to check
         * this in advance with $(D hasCurrentPoint()).
         *
         * Most path construction functions alter the current point. See
         * the following for details on how they affect the current point:
         * $(D newPath()), $(D newSubPath()), $(D appendPath()),
         * $(D closePath()), $(D moveTo()), $(D lineTo()),
         * $(D curveTo()), $(D relMoveTo()), $(D relLineTo()),
         * $(D relCurveTo()), $(D arc()), $(D arcNegative()),
         * $(D rectangle()), $(D textPath()), $(D glyphPath()),
         * $(D strokeToPath()).
         *
         * Some functions use and alter the current point but do not
         * otherwise change current path: $(D showText()).
         *
         * Some functions unset the current path and as a result,
         * current point: $(D fill()), $(D stroke()).
         */
        Point getCurrentPoint()
        {
            Point tmp;
            cairo_get_current_point(this.nativePointer, &tmp.x, &tmp.y);
            checkError();
            return tmp;
        }

        ///convenience alias
        alias getCurrentPoint currentPoint;
        
        /**
         * Clears the current path. After this call there will be no path
         * and no current point.
         */
        void newPath()
        {
            cairo_new_path(this.nativePointer);
            checkError();
        }

        /**
         * Begin a new sub-path. Note that the existing path is not affected.
         * After this call there will be no current point.
         *
         * In many cases, this call is not needed since new sub-paths are
         * frequently started with cairo_move_to().
         *
         * A call to $(D newSubPath()) is particularly useful when
         * beginning a new sub-path with one of the $(D arc()) calls.
         * This makes things easier as it is no longer necessary to
         * manually compute the arc's initial coordinates for a call
         * to $(D moveTo()).
         */
        void newSubPath()
        {
            cairo_new_sub_path(this.nativePointer);
            checkError();
        }

        /**
         * Adds a line segment to the path from the current point to
         * the beginning of the current sub-path, (the most recent
         * point passed to $(D moveTo())), and closes this sub-path.
         * After this call the current point will be at the joined
         * endpoint of the sub-path.
         *
         * The behavior of $(D closePath()) is distinct from simply
         * calling $(D lineTo()) with the equivalent coordinate in
         * the case of stroking. When a closed sub-path is stroked,
         * there are no caps on the ends of the sub-path. Instead,
         * there is a line join connecting the final and initial
         * segments of the sub-path.
         *
         * If there is no current point before the call to $(D closePath()),
         * this function will have no effect.
         *
         * Note: As of cairo version 1.2.4 any call to $(D closePath())
         * will place an explicit MOVE_TO element into the path immediately
         * after the CLOSE_PATH element, (which can be seen in
         * $(D copyPath()) for example). This can simplify path processing
         * in some cases as it may not be necessary to save the "last
         * move_to point" during processing as the MOVE_TO immediately
         * after the CLOSE_PATH will provide that point.
         */
        void closePath()
        {
            cairo_close_path(this.nativePointer);
            checkError();
        }

        /**
         * Adds a circular arc of the given radius to the current path.
         * The arc is centered at center, begins at angle1 and proceeds in
         * the direction of increasing angles to end at angle2.
         * If angle2 is less than angle1 it will be progressively
         * increased by 2*PI until it is greater than angle1.
         *
         * If there is a current point, an initial line segment will be
         * added to the path to connect the current point to the beginning
         * of the arc. If this initial line is undesired, it can be
         * avoided by calling $(D newSubPath()) before calling $(D arc()).
         *
         * Angles are measured in radians. An angle of 0.0 is in the
         * direction of the positive X axis (in user space). An angle
         * of PI/2.0 radians (90 degrees) is in the direction of the
         * positive Y axis (in user space). Angles increase in the
         * direction from the positive X axis toward the positive Y
         * axis. So with the default transformation matrix, angles
         * increase in a clockwise direction.
         *
         * (To convert from degrees to radians, use degrees * (PI / 180))
         *
         * This function gives the arc in the direction of increasing angles;
         * see $(D arcNegative()) to get the arc in the direction of decreasing angles.
         *
         * The arc is circular in user space. To achieve an elliptical arc,
         * you can scale the current transformation matrix by different
         * amounts in the X and Y directions. For example, to draw an
         * ellipse in the box given by x, y, width, height:
         * -------------------
         * cr.save();
         * cr.translate(x + width / 2, y + height / 2);
         * cr.scale(width / 2, height / 2);
         * cr.arc(Point(0, 0), 1, 0, 2 * PI);
         * cr.restore();
         * -------------------
         * Params:
         * radius = the radius of the arc
         * angle1 = the start angle, in radians
         * angle2 = the end angle, in radians
         */
        void arc(Point center, double radius, double angle1, double angle2)
        {
            cairo_arc(this.nativePointer, center.x, center.y, radius, angle1, angle2);
            checkError();
        }
        ///ditto
        void arc(double centerX, double centerY, double radius, double angle1, double angle2)
        {
            cairo_arc(this.nativePointer, centerX, centerY, radius, angle1, angle2);
            checkError();
        }

        /**
         * Adds a circular arc of the given radius to the current path.
         * The arc is centered at center, begins at angle1 and proceeds
         * in the direction of decreasing angles to end at angle2.
         * If angle2 is greater than angle1 it will be progressively
         * decreased by 2*PI until it is less than angle1.
         *
         * See $(D arc()) for more details. This function differs only
         * in the direction of the arc between the two angles.
         *
         * Params:
         * radius = the radius of the arc
         * angle1 = the start angle, in radians
         * angle2 = the end angle, in radians
         */
        void arcNegative(Point center, double radius, double angle1, double angle2)
        {
            cairo_arc_negative(this.nativePointer, center.x, center.y, radius, angle1, angle2);
            checkError();
        }
        ///ditto
        void arcNegative(double centerX, double centerY, double radius, double angle1, double angle2)
        {
            cairo_arc_negative(this.nativePointer, centerX, centerY, radius, angle1, angle2);
            checkError();
        }

        /**
         * Adds a cubic Bézier spline to the path from the current
         * point to position p3 in user-space coordinates, using p1 and p2
         * as the control points. After this call the current point will be p3.
         *
         * If there is no current point before the call to $(D curveTo())
         * this function will behave as if preceded by a call to
         * $(D moveTo(p1)).
         *
         * Params:
         * p1 = First control point
         * p2 = Second control point
         * p3 = End of the curve
         */
        void curveTo(Point p1, Point p2, Point p3)
        {
            cairo_curve_to(this.nativePointer, p1.x, p1.y, p2.x, p2.y, p3.x, p3.y);
            checkError();
        }
        ///ditto
        void curveTo(double p1x, double p1y, double p2x, double p2y,
            double p3x, double p3y)
        {
            cairo_curve_to(this.nativePointer, p1x, p1y, p2x, p2y, p3x, p3y);
            checkError();
        }

        /**
         * Adds a line to the path from the current point to position p1
         * in user-space coordinates. After this call the current point
         * will be p1.
         *
         * If there is no current point before the call to $(D lineTo())
         * this function will behave as $(D moveTo(p1)).
         *
         * Params:
         * p1 = End of the line
         */
        void lineTo(Point p1)
        {
            cairo_line_to(this.nativePointer, p1.x, p1.y);
            checkError();
        }
        ///ditto
        void lineTo(double x, double y)
        {
            cairo_line_to(this.nativePointer, x, y);
            checkError();
        }

        /**
         * Begin a new sub-path. After this call the current point will be p1.
         */
        void moveTo(Point p1)
        {
            cairo_move_to(this.nativePointer, p1.x, p1.y);
            checkError();
        }
        ///ditto
        void moveTo(double x, double y)
        {
            cairo_move_to(this.nativePointer, x, y);
            checkError();
        }

        /**
         * Adds a closed sub-path rectangle of the given size to the
         * current path at position r.point in user-space coordinates.
         * This function is logically equivalent to:
         * ---------------------
         * cr.moveTo(r.point);
         * cr.relLineTo(r.width, 0);
         * cr.relLineTo(0, r.height);
         * cr.relLineTo(-r.width, 0);
         * cr.closePath();
         * ---------------------
         */
        void rectangle(Rectangle!double r)
        {
            cairo_rectangle(this.nativePointer, r.point.x, r.point.y, r.width, r.height);
            checkError();
        }
        ///ditto
        void rectangle(double x, double y, double width, double height)
        {
            cairo_rectangle(this.nativePointer, x, y, width, height);
            checkError();
        }

        /**
         * Adds closed paths for the glyphs to the current path.
         * The generated path if filled, achieves an effect
         * similar to that of $(D showGlyphs()).
         */
        void glyphPath(Glyph[] glyphs)
        {
            cairo_glyph_path(this.nativePointer, glyphs.ptr, glyphs.length);
            checkError();
        }

        /**
         * Adds closed paths for text to the current path. The generated
         * path if filled, achieves an effect similar to that of
         * $(D showText()).
         *
         * Text conversion and positioning is done similar to $(D showText()).
         *
         * Like $(D showText()), After this call the current point is moved
         * to the origin of where the next glyph would be placed in this
         * same progression. That is, the current point will be at the
         * origin of the final glyph offset by its advance values. This
         * allows for chaining multiple calls to to $(D textPath())
         * without having to set current point in between.
         *
         * Note: The $(D textPath()) function call is part of what the
         * cairo designers call the "toy" text API. It is convenient for
         * short demos and simple programs, but it is not expected
         * to be adequate for serious text-using applications. See
         * $(D glyphPath()) for the "real" text path API in cairo.
         */
        void textPath(string text)
        {
            cairo_text_path(this.nativePointer, toStringz(text));
            checkError();
        }

        /**
         * Relative-coordinate version of $(D curveTo()).
         * All offsets are relative to the current point. Adds a
         * cubic Bézier spline to the path from the current point
         * to a point offset from the current point by rp3,
         * using points offset by rp1 and rp2 as the
         * control points. After this call the current point will
         * be offset by rp3.
         *
         * Given a current point of (x, y),
         * cairo_rel_curve_to(cr, dx1, dy1, dx2, dy2, dx3, dy3) is logically
         * equivalent to
         * cairo_curve_to(cr, x+dx1, y+dy1, x+dx2, y+dy2, x+dx3, y+dy3).
         *
         * It is an error to call this function with no current point.
         * Doing so will cause an CairoException with a
         * status of CAIRO_STATUS_NO_CURRENT_POINT.
         *
         * Params:
         * rp1 = First control point
         * rp2 = Second control point
         * rp3 = offset to the end of the curve
         */
        void relCurveTo(Point rp1, Point rp2, Point rp3)
        {
            cairo_rel_curve_to(this.nativePointer, rp1.x, rp1.y, rp2.x, rp2.y, rp3.x, rp3.y);
            checkError();
        }
        ///ditto
        void relCurveTo(double rp1x, double rp1y, double rp2x, double rp2y,
            double rp3x, double rp3y)
        {
            cairo_rel_curve_to(this.nativePointer, rp1x, rp1y, rp2x, rp2y, rp3x, rp3y);
            checkError();
        }

        /**
         * Relative-coordinate version of $(D lineTo()). Adds a line
         * to the path from the current point to a point that is
         * offset from the current point by rp1 in user space.
         * After this call the current point will be offset by rp1.
         *
         * Given a current point of (x, y), cairo_rel_line_to(cr, dx, dy)
         * is logically equivalent to cairo_line_to(cr, x + dx, y + dy).
         *
         * It is an error to call this function with no current point.
         * Doing so will cause an CairoException with a
         * status of CAIRO_STATUS_NO_CURRENT_POINT.
         */
        void relLineTo(Point rp1)
        {
            cairo_rel_line_to(this.nativePointer, rp1.x, rp1.y);
            checkError();
        }
        ///ditto
        void relLineTo(double x, double y)
        {
            cairo_rel_line_to(this.nativePointer, x, y);
            checkError();
        }

        /**
         * Begin a new sub-path. After this call the current point will
         * offset by rp1.
         *
         * Given a current point of (x, y), cairo_rel_move_to(cr, dx, dy)
         * is logically equivalent to cairo_move_to(cr, x + dx, y + dy).
         *
         * It is an error to call this function with no current point.
         * Doing so will cause an CairoException with a status of
         * CAIRO_STATUS_NO_CURRENT_POINT.
         */
        void relMoveTo(Point rp1)
        {
            cairo_rel_move_to(this.nativePointer, rp1.x, rp1.y);
            checkError();
        }
        ///ditto
        void relMoveTo(double x, double y)
        {
            cairo_rel_move_to(this.nativePointer, x, y);
            checkError();
        }

        /**
         * Computes a bounding box in user-space coordinates covering
         * the points on the current path. If the current path is empty,
         * returns an empty Box ((0,0), (0,0)). Stroke parameters,
         * fill rule, surface dimensions and clipping are not taken
         * into account.
         *
         * Contrast with $(D fillExtents()) and $(D strokeExtents())
         * which return the extents of only the area that would be "inked"
         * by the corresponding drawing operations.
         *
         * The result of $(D pathExtents()) is defined as equivalent
         * to the limit of $(D strokeExtents()) with CAIRO_LINE_CAP_ROUND
         * as the line width approaches 0.0, (but never reaching the
         * empty-rectangle returned by $(D strokeExtents()) for a
         * line width of 0.0).
         *
         * Specifically, this means that zero-area sub-paths such as
         * $(D moveTo());$(D lineTo()) segments, (even degenerate
         * cases where the coordinates to both calls are identical),
         * will be considered as contributing to the extents. However,
         * a lone $(D moveTo()) will not contribute to the
         * results of $(D pathExtents()).
         */
        Box pathExtends()
        {
            Box tmp;
            cairo_path_extents(this.nativePointer, &tmp.point1.x, &tmp.point1.y, &tmp.point2.x, &tmp.point2.y);
            checkError();
            return tmp;
        }

        /**
         * Modifies the current transformation matrix (CTM) by translating
         * the user-space origin by (tx, ty). This offset is interpreted
         * as a user-space coordinate according to the CTM in place
         * before the new call to $(D translate()). In other words,
         * the translation of the user-space origin takes place
         * after any existing transformation.
         *
         * Params:
         * tx = amount to translate in the X direction
         * ty = amount to translate in the Y direction
         */
        void translate(double tx, double ty)
        {
            cairo_translate(this.nativePointer, tx, ty);
            checkError();
        }

        /**
         * Modifies the current transformation matrix (CTM) by scaling
         * the X and Y user-space axes by sx and sy respectively.
         * The scaling of the axes takes place after any existing
         * transformation of user space.
         *
         * Params:
         * sx = scale factor for the X dimension
         * sy = scale factor for the Y dimension
         */
        void scale(double sx, double sy)
        {
            cairo_scale(this.nativePointer, sx, sy);
            checkError();
        }

        ///ditto
        void scale(Point point)
        {
            scale(point.x, point.y);
        }

        /**
         * Modifies the current transformation matrix (CTM) by rotating
         * the user-space axes by angle radians. The rotation of the
         * axes takes places after any existing transformation of user
         * space. The rotation direction for positive angles is from
         * the positive X axis toward the positive Y axis.
         *
         * Params:
         * angle = angle (in radians) by which the user-space axes will be rotated
         */
        void rotate(double angle)
        {
            cairo_rotate(this.nativePointer, angle);
            checkError();
        }

        /**
         * Modifies the current transformation matrix (CTM) by applying
         * matrix as an additional transformation. The new
         * transformation of user space takes place after any
         * existing transformation.
         *
         * Params:
         * matrix = a transformation to be applied to the user-space axes
         */
        void transform(const Matrix matrix)
        {
            cairo_transform(this.nativePointer, &matrix.nativeMatrix);
            checkError();
        }

        /**
         * Modifies the current transformation matrix (CTM) by setting it
         * equal to matrix.
         *
         * Params:
         * Matrix = a transformation matrix from user space to device space
         */
        void setMatrix(const Matrix matrix)
        {
            cairo_set_matrix(this.nativePointer, &matrix.nativeMatrix);
            checkError();
        }

        /**
         * Returns the current transformation matrix (CTM)
         */
        Matrix getMatrix()
        {
            Matrix m;
            cairo_get_matrix(this.nativePointer, &m.nativeMatrix);
            checkError();
            return m;
        }

        ///Convenience property
        @property void matrix(const Matrix matrix)
        {
            setMatrix(matrix);
        }
        
        ///ditto
        @property Matrix matrix()
        {
            return getMatrix();
        }  
        
        /**
         * Resets the current transformation matrix (CTM) by setting it
         * equal to the identity matrix. That is, the user-space and
         * device-space axes will be aligned and one user-space unit
         * will transform to one device-space unit.
         */
        void identityMatrix()
        {
            cairo_identity_matrix(this.nativePointer);
            checkError();
        }

        /**
         * Transform a coordinate from user space to device space by
         * multiplying the given point by the current
         * transformation matrix (CTM).
         */
        Point userToDevice(Point inp)
        {
            cairo_user_to_device(this.nativePointer, &inp.x, &inp.y);
            checkError();
            return inp;
        }

        /**
         * Transform a distance vector from user space to device space.
         * This function is similar to $(D userToDevice()) except that
         * the translation components of the CTM will be ignored when
         * transforming inp.
         */
        Point userToDeviceDistance(Point inp)
        {
            cairo_user_to_device_distance(this.nativePointer, &inp.x, &inp.y);
            checkError();
            return inp;
        }

        /**
         * Transform a coordinate from device space to user space by
         * multiplying the given point by the inverse of the current
         * transformation matrix (CTM).
         */
        Point deviceToUser(Point inp)
        {
            cairo_device_to_user(this.nativePointer, &inp.x, &inp.y);
            checkError();
            return inp;
        }

        /**
         * Transform a distance vector from device space to user space.
         * This function is similar to $(D deviceToUser()) except that
         * the translation components of the inverse CTM will be ignored
         * when transforming inp.
         */
        Point deviceToUserDistance(Point inp)
        {
            cairo_device_to_user_distance(this.nativePointer, &inp.x, &inp.y);
            checkError();
            return inp;
        }

        /**
         * Note: The $(D selectFontFace()) function call is part of
         * what the cairo designers call the "toy" text API. It
         * is convenient for short demos and simple programs, but
         * it is not expected to be adequate for serious text-using
         * applications.
         *
         * Selects a family and style of font from a simplified description
         * as a family name, slant and weight. Cairo provides no
         * operation to list available family names on the system
         * (this is a "toy", remember), but the standard CSS2 generic
         * family names, ("serif", "sans-serif", "cursive", "fantasy",
         * "monospace"), are likely to work as expected.
         *
         * If family starts with the string "cairo:", or if no native
         * font backends are compiled in, cairo will use an internal
         * font family. The internal font family recognizes many
         * modifiers in the family string, most notably, it recognizes
         * the string "monospace". That is, the family name
         * "cairo:monospace" will use the monospace version of the
         * internal font family.
         *
         * For "real" font selection, see the font-backend-specific
         * $(D FontFace) classes for the font backend you are using.
         * (For example, if you are using the freetype-based cairo-ft
         * font backend, see $(D FTFontFace))
         *
         * The resulting font face could then be used
         * with $(D ScaledFont) and $(D Context.setScaledFont()).
         *
         * Similarly, when using the "real" font support, you can call
         * directly into the underlying font system, (such as
         * fontconfig or freetype), for operations such as listing
         * available fonts, etc.
         *
         * It is expected that most applications will need to use a more
         * comprehensive font handling and text layout library,
         * (for example, pango), in conjunction with cairo.
         *
         * If text is drawn without a call to $(D selectFontFace()),
         * (nor $(D setFontFace()) nor $(D setScaledFont())),
         * the default family is platform-specific, but is essentially
         * "sans-serif". Default slant is CAIRO_FONT_SLANT_NORMAL,
         * and default weight is CAIRO_FONT_WEIGHT_NORMAL.
         *
         * This function is equivalent to a call to
         * $(D toyFontFaceCreate()) followed by $(D setFontFace()).
         *
         * Params:
         * family = a font family name, encoded in UTF-8
         * slant = the slant for the font
         * weight = the weight for the font
         */
        void selectFontFace(string family, FontSlant slant, FontWeight weight)
        {
            cairo_select_font_face(this.nativePointer, toStringz(family), slant, weight);
            checkError();
        }

        /**
         * Sets the current font matrix to a scale by a factor of size,
         * replacing any font matrix previously set with $(D setFontSize())
         * or $(D setFontMatrix()). This results in a font size of
         * size user space units. (More precisely, this matrix will
         * result in the font's em-square being a size by size
         * square in user space.)
         *
         * If text is drawn without a call to $(D setFontSize()),
         * (nor $(D setFontMatrix()) nor $(D setScaledFont())),
         * the default font size is 10.0.
         *
         * Params:
         * size = the new font size, in user space units
         */
        void setFontSize(double size)
        {
            cairo_set_font_size(this.nativePointer, size);
            checkError();
        }

        /**
         * Sets the current font matrix to matrix. The font matrix gives
         * a transformation from the design space of the font (in this
         * space, the em-square is 1 unit by 1 unit) to user space.
         * Normally, a simple scale is used (see $(D setFontSize())),
         * but a more complex font matrix can be used to shear the font
         * or stretch it unequally along the two axes
         *
         * Params:
         * matrix = a $(D Matrix) describing a transform to be applied
         * to the current font.
         */
        void setFontMatrix(Matrix matrix)
        {
            cairo_set_font_matrix(this.nativePointer, &matrix.nativeMatrix);
            checkError();
        }

        /**
         * Returns the current font matrix. See $(D setFontMatrix).
         */
        Matrix getFontMatrix()
        {
            Matrix res;
            cairo_get_font_matrix(this.nativePointer, &res.nativeMatrix);
            checkError();
            return res;
        }

        ///Convenience property
        @property void fontMatrix(Matrix matrix)
        {
            setFontMatrix(matrix);
        }
        
        ///ditto
        @property Matrix fontMatrix()
        {
            return getFontMatrix();
        }  
        
        /**
         * Sets a set of custom font rendering options for the
         * $(D Context). Rendering options are derived by merging these
         * options with the options derived from underlying surface;
         * if the value in options has a default value (like CAIRO_ANTIALIAS_DEFAULT),
         * then the value from the surface is used.
         */
        void setFontOptions(FontOptions options)
        {
            cairo_set_font_options(this.nativePointer, options.nativePointer);
            checkError();
        }

        /**
         * Retrieves font rendering options set via $(D setFontOptions()).
         * Note that the returned options do not include any options
         * derived from the underlying surface; they are literally
         * the options passed to $(D setFontOptions()).
         */
        FontOptions getFontOptions()
        {
            auto opt = FontOptions();
            cairo_get_font_options(this.nativePointer, opt.nativePointer);
            checkError();
            return opt;
        }

        ///Convenience property
        @property void fontOptions(FontOptions options)
        {
            setFontOptions(options);
        }
        
        ///ditto
        @property FontOptions fontOptions()
        {
            return getFontOptions();
        }  
        
        /**
         * Replaces the current $(D FontFace) object in the $(D Context)
         * with font_face. The replaced font face in the $(D Context) will
         * be destroyed if there are no other references to it.
         */
        void setFontFace(FontFace font_face)
        {
            cairo_set_font_face(this.nativePointer, font_face.nativePointer);
            checkError();
        }

        /**
         * Replaces the current $(D FontFace) object in the $(D Context)
         * with the default font.
         */
        void setFontFace()
        {
            cairo_set_font_face(this.nativePointer, null);
            checkError();
        }
        
        // todo: setFontFace should be renamed to resetFontFace, using alias
        // instead for backwards-compatibility.
        ///convenience alias
        alias setFontFace resetFontFace;

        /**
         * Gets the current font face for a $(D Context).
         */
        FontFace getFontFace()
        {
            return FontFace.createFromNative(cairo_get_font_face(this.nativePointer));
        }

        ///Convenience property
        @property void fontFace(FontFace font_face)
        {
            setFontFace(font_face);
        }
        
        ///ditto
        @property FontFace fontFace()
        {
            return getFontFace();
        }        
        
        /**
         * Replaces the current font face, font matrix, and font options
         * in the $(D Context) with those of the $(D ScaledFont). Except
         * for some translation, the current CTM of the cairo_t should be
         * the same as that of the $(D ScaledFont), which can be
         * accessed using $(D ScaledFont.getCTM()).
         */
        void setScaledFont(ScaledFont scaled_font)
        {
            cairo_set_scaled_font(this.nativePointer, scaled_font.nativePointer);
            checkError();
        }

        /**
         * Gets the current scaled font for a $(D Context).
         */
        ScaledFont getScaledFont()
        {
            return ScaledFont.createFromNative(cairo_get_scaled_font(this.nativePointer));
        }

        ///Convenience property
        @property void scaledFont(ScaledFont scaled_font)
        {
            setScaledFont(scaled_font);
        }
        
        ///ditto
        @property ScaledFont scaledFont()
        {
            return getScaledFont();
        }     
        
        /**
         * A drawing operator that generates the shape from a string of
         * UTF-8 characters, rendered according to the current
         * fontFace, fontSize (fontMatrix), and fontOptions.
         *
         * This function first computes a set of glyphs for the string
         * of text. The first glyph is placed so that its origin is
         * at the current point. The origin of each subsequent glyph
         * is offset from that of the previous glyph by the advance
         * values of the previous glyph.
         *
         * After this call the current point is moved to the origin
         * of where the next glyph would be placed in this same
         * progression. That is, the current point will be at the
         * origin of the final glyph offset by its advance values.
         * This allows for easy display of a single logical string
         * with multiple calls to $(D showText()).
         *
         * Note: The $(D showText()) function call is part of
         * what the cairo designers call the "toy" text API. It
         * is convenient for short demos and simple programs, but
         * it is not expected to be adequate for serious text-using
         * applications. See $(D showGlyphs()) for the "real" text
         * display API in cairo.
         */
        void showText(string text)
        {
            cairo_show_text(this.nativePointer, toStringz(text));
            checkError();
        }

        /**
         * A drawing operator that generates the shape from an array of
         * glyphs, rendered according to the current fontFace,
         * fontSize (fontMatrix), and font options.
         */
        void showGlyphs(Glyph[] glyphs)
        {
            cairo_show_glyphs(this.nativePointer, glyphs.ptr, glyphs.length);
            checkError();
        }

        /**
         * This operation has rendering effects similar to $(D showGlyphs())
         * but, if the target surface supports it, uses the provided
         * text and cluster mapping to embed the text for the glyphs
         * shown in the output. If the target does not support the
         * extended attributes, this function acts like the basic
         * $(D showGlyphs()).
         */
        void showTextGlyphs(TextGlyph glyph)
        {
            cairo_show_text_glyphs(this.nativePointer, glyph.text.ptr,
                glyph.text.length, glyph.glyphs.ptr, glyph.glyphs.length,
                glyph.cluster.ptr, glyph.cluster.length, glyph.flags);
            checkError();
        }

        /**
         * Gets the font extents for the currently selected font.
         */
        FontExtents fontExtents()
        {
            FontExtents res;
            cairo_font_extents(this.nativePointer, &res);
            checkError();
            return res;
        }

        /**
         * Gets the extents for a string of text. The extents describe
         * a user-space rectangle that encloses the "inked"
         * portion of the text, (as it would be drawn by $(D showText())).
         * Additionally, the x_advance and y_advance values indicate
         * the amount by which the current point would be advanced
         * by $(D showText()).
         *
         * Note that whitespace characters do not directly contribute
         * to the size of the rectangle (extents.width and extents.height).
         * They do contribute indirectly by changing the position of
         * non-whitespace characters. In particular, trailing whitespace
         * characters are likely to not affect the size of the rectangle,
         * though they will affect the x_advance and y_advance values.
         */
        TextExtents textExtents(string text)
        {
            TextExtents res;
            cairo_text_extents(this.nativePointer, toStringz(text), &res);
            checkError();
            return res;
        }

        /**
         * Gets the extents for an array of glyphs. The extents describe
         * a user-space rectangle that encloses the "inked" portion of
         * the glyphs, (as they would be drawn by $(D showGlyphs())).
         * Additionally, the x_advance and y_advance values indicate
         * the amount by which the current point would be advanced by
         * $(D showGlyphs()).
         *
         * Note that whitespace glyphs do not contribute to the size of
         * the rectangle (extents.width and extents.height).
         */
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
 * $(D FontOptions) - How a font should be rendered
 *
 * The font options specify how fonts should be rendered. Most of the
 * time the font options implied by a surface are just right and do
 * not need any changes, but for pixel-based targets tweaking font
 * options may result in superior output on a particular display.
 *
 * Warning: Instances must be created with opCall!
 * --------
 * auto options = FontOptions(); //Correct
 * options.toHash();
 * --------
 *
 * --------
 * FontOptions options; //Wrong
 * options.toHash();
 * --------
 *
 * --------
 * FontOptions options;
 * options = FontOptions(); //Correct
 * options.toHash();
 * --------
 */
public struct FontOptions
{
    private:
        struct Payload
        {
            cairo_font_options_t* _payload;
            this(cairo_font_options_t* h)
            {
                _payload = h;
            }
            ~this()
            {
                if(_payload)
                {
                    cairo_font_options_destroy(_payload);
                    _payload = null;
                }
            }

            // Should never perform these operations
            this(this) { assert(false); }
            void opAssign(FontOptions.Payload rhs) { assert(false); }
        }

        alias RefCounted!(Payload, RefCountedAutoInitialize.no) Data;
        Data _data;

    protected:
        final void checkError()
        {
            throwError(cairo_font_options_status(nativePointer));
        }

    public:
        /**
         * The underlying $(D cairo_font_options_t*) handle
         */
        @property cairo_font_options_t* nativePointer()
        {
            return _data._payload;
        }

        version(D_Ddoc)
        {
            /**
             * Enable / disable memory management debugging for this FontOptions
             * instance. Only available if both cairoD and the cairoD user
             * code were compiled with "debug=RefCounted"
             *
             * Output is written to stdout, see
             * $(LINK https://github.com/jpf91/cairoD/wiki/Memory-Management#debugging)
             * for more information
             */
            @property bool debugging();
            ///ditto
            @property void debugging(bool value);
        }
        else debug(RefCounted)
        {
            @property bool debugging()
            {
                return _data.RefCounted.debugging;
            }

            @property void debugging(bool value)
            {
                _data.RefCounted.debugging = value;
            }
        }

        /**
         * Allocates a new font options object with all
         * options initialized to default values.
         */
        static FontOptions opCall()
        {
            FontOptions opt;
            auto ptr = cairo_font_options_create();
            throwError(cairo_font_options_status(ptr));
            opt._data.RefCounted.initialize(ptr);
            return opt;
        }

        /**
         * Create $(D FontOptions) from a existing $(D cairo_font_options_t*).
         * FontOptions is a reference counted struct. It will call
         * $(D cairo_font_options_destroy) when it's reference count is 0.
         * See $(LINK https://github.com/jpf91/cairoD/wiki/Memory-Management#2.2-structs)
         * for more information.
         *
         * Warning:
         * $(RED Only use this if you know what your doing!
         * This function should not be needed for standard cairoD usage.)
         */
        this(cairo_font_options_t* ptr)
        {
            if(!ptr)
            {
                throw new CairoException(cairo_status_t.CAIRO_STATUS_NULL_POINTER);
            }
            throwError(cairo_font_options_status(ptr));
            _data.RefCounted.initialize(ptr);
        }

        /**
         * Allocates a new font options object copying the option values
         * from original.
         *
         * This new object's reference counting is independent from the
         * current object's.
         */
        FontOptions copy()
        {
            return FontOptions(cairo_font_options_copy(nativePointer));
        }

        /**
         * Merges non-default options from other into this object,
         * replacing existing values. This operation can be thought
         * of as somewhat similar to compositing other onto options
         * with the operation of CAIRO_OPERATION_OVER.
         */
        void merge(FontOptions other)
        {
            cairo_font_options_merge(nativePointer, other.nativePointer);
            checkError();
        }

        /**
         * Compute a hash for the font options object; this value
         * will be useful when storing an object containing a
         * FontOptions in a hash table.
         */
        /*
         * Cairo docs say hash can be casted to a 32bit value, if needed
         */
        size_t toHash()
        {
            auto hash = cast(size_t)cairo_font_options_hash(nativePointer);
            checkError();
            return hash;
        }

        /**
         * Compares two font options objects for equality.
         *
         * Returns:
         * true if all fields of the two font options objects match.
         * Note that this function will return false if either object is
         * in error.
         */
        const bool opEquals(ref const(FontOptions) other)
        {
            return cairo_font_options_equal((cast(FontOptions)this).nativePointer,
                (cast(FontOptions)other).nativePointer) ? true : false;
        }

        /**
         * Sets the antialiasing mode for the font options object. This
         * specifies the type of antialiasing to do when rendering text.
         */
        void setAntiAlias(AntiAlias antialias)
        {
            cairo_font_options_set_antialias(nativePointer, antialias);
            checkError();
        }

        /**
         * Gets the antialiasing mode for the font options object.
         */
        AntiAlias getAntiAlias()
        {
            scope(exit)
                checkError();
            return cairo_font_options_get_antialias(nativePointer);
        }

        ///Convenience property
        @property void antiAlias(AntiAlias aa)
        {
            setAntiAlias(aa);
        }
        
        ///ditto
        @property AntiAlias antiAlias()
        {
            return getAntiAlias();
        }
        
        /**
         * Sets the subpixel order for the font options object.
         * The subpixel order specifies the order of color elements
         * within each pixel on the display device when rendering with
         * an antialiasing mode of CAIRO_ANTIALIAS_SUBPIXEL.
         * See the documentation for $(D SubpixelOrder) for full details.
         */
        void setSubpixelOrder(SubpixelOrder order)
        {
            cairo_font_options_set_subpixel_order(nativePointer, order);
            checkError();
        }

        /**
         * Gets the subpixel order for the font options object.
         * See the documentation for $(D SubpixelOrder) for full details.
         */
        SubpixelOrder getSubpixelOrder()
        {
            scope(exit)
                checkError();
            return cairo_font_options_get_subpixel_order(nativePointer);
        }

        ///convenience alias
        alias getSubpixelOrder subpixelOrder;
        
        /**
         * Sets the hint style for font outlines for the font options object.
         * This controls whether to fit font outlines to the pixel grid,
         * and if so, whether to optimize for fidelity or contrast.
         * See the documentation for $(D HintStyle) for full details.
         */
        void setHintStyle(HintStyle style)
        {
            cairo_font_options_set_hint_style(nativePointer, style);
            checkError();
        }

        /**
         * Gets the hint style for font outlines for the font options object.
         * See the documentation for $(D HintStyle) for full details.
         */
        HintStyle getHintStyle()
        {
            scope(exit)
                checkError();
            return cairo_font_options_get_hint_style(nativePointer);
        }
        
        ///Convenience property
        @property void hintStyle(HintStyle style)
        {
            setHintStyle(style);
        }
        
        ///ditto
        @property HintStyle hintStyle()
        {
            return getHintStyle();
        }
        
        /**
         * Sets the metrics hinting mode for the font options object.
         * This controls whether metrics are quantized to integer
         * values in device units. See the documentation for
         * $(D HintMetrics) for full details.
         */
        void setHintMetrics(HintMetrics metrics)
        {
            cairo_font_options_set_hint_metrics(nativePointer, metrics);
            checkError();
        }

        /**
         * Gets the metrics hinting mode for the font options object.
         * See the documentation for $(D HintMetrics) for full details.
         */
        HintMetrics getHintMetrics()
        {
            scope(exit)
                checkError();
            return cairo_font_options_get_hint_metrics(nativePointer);
        }
        
        ///Convenience property
        @property void hintMetrics(HintMetrics metrics)
        {
            setHintMetrics(metrics);
        }
        
        ///ditto
        @property HintMetrics hintMetrics()
        {
            return getHintMetrics();
        }        
}

/**
 * The mapping between utf8 and glyphs is provided by an array
 * of clusters. Each cluster covers a number of text bytes and
 * glyphs, and neighboring clusters cover neighboring areas of
 * utf8 and glyphs. The clusters should collectively cover
 * utf8 and glyphs in entirety.
 *
 * The first cluster always covers bytes from the beginning of
 * utf8. If cluster_flags do not have the
 * CAIRO_TEXT_CLUSTER_FLAG_BACKWARD set, the first cluster also
 * covers the beginning of glyphs, otherwise it covers the end
 * of the glyphs array and following clusters move backward.
 *
 * See cairo_text_cluster_t for constraints on valid clusters.
 */
public struct TextGlyph
{
    public:
        ///array of glyphs
        Glyph[] glyphs;
        ///array of cluster mapping information
        TextCluster[] cluster;
        ///a string of text encoded in UTF-8
        string text;
        ///cluster mapping flags
        TextClusterFlags flags;
}

/**
 * Font face at particular size and options
 *
 * $(D ScaledFont) represents a realization of a font face at a particular
 * size and transformation and a certain set of font options.
 */
public class ScaledFont
{
    ///
    mixin CairoCountedClass!(cairo_scaled_font_t*, "cairo_scaled_font_");

    protected:
        /**
         * Method for use in subclasses.
         * Calls $(D cairo_scaled_font_status(nativePointer)) and throws
         * an exception if the status isn't CAIRO_STATUS_SUCCESS
         */
        final void checkError()
        {
            throwError(cairo_scaled_font_status(nativePointer));
        }

    public:
        /**
         * Create a $(D ScaledFont) from a existing $(D cairo_scaled_font_t*).
         * ScaledFont is a garbage collected class. It will call $(D cairo_scaled_font_destroy)
         * when it gets collected by the GC or when $(D dispose()) is called.
         *
         * Warning:
         * $(D ptr)'s reference count is not increased by this function!
         * Adjust reference count before calling it if necessary
         *
         * $(RED Only use this if you know what your doing!
         * This function should not be needed for standard cairoD usage.)
         */
        this(cairo_scaled_font_t* ptr)
        {
            this.nativePointer = ptr;
            checkError();
        }

        /**
         * Creates a $(D ScaledFont) object from a font face and
         * matrices that describe the size of the font and the
         * environment in which it will be used.
         *
         * Params:
         * font_matrix = font space to user space transformation matrix
         *   for the font. In the simplest case of a N point font, this
         *   matrix is just a scale by N, but it can also be used to
         *   shear the font or stretch it unequally along the two axes.
         *   See $(D Context.setFontMatrix()).
         * ctm = user to device transformation matrix with which
         *   the font will be used.
         */
        this(FontFace font_face, Matrix font_matrix, Matrix ctm,
             FontOptions options)
        {
            this(cairo_scaled_font_create(font_face.nativePointer,
                &font_matrix.nativeMatrix, &ctm.nativeMatrix, options.nativePointer));
        }

        /**
         * The createFromNative method for the ScaledFont classes.
         * See $(LINK https://github.com/jpf91/cairoD/wiki/Memory-Management#createFromNative)
         * for more information.
         *
         * Warning:
         * $(RED Only use this if you know what your doing!
         * This function should not be needed for standard cairoD usage.)
         */
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
                version(CAIRO_HAS_FT_FONT)
                {
                    case cairo_font_type_t.CAIRO_FONT_TYPE_FT:
                        return new FTScaledFont(ptr);
                }
                default:
                    return new ScaledFont(ptr);
            }
        }

        /**
         * Gets the metrics for a $(D ScaledFont).
         */
        FontExtents extents()
        {
            FontExtents res;
            cairo_scaled_font_extents(this.nativePointer, &res);
            checkError();
            return res;
        }

        /**
         * Gets the extents for a string of text. The extents describe a
         * user-space rectangle that encloses the "inked" portion of the
         * text drawn at the origin (0,0) (as it would be drawn by
         * $(D Context.showText()) if the cairo graphics state were set
         * to the same fontFace, fontMatrix, ctm, and fontOptions
         * as $(D ScaledFont)). Additionally, the x_advance and y_advance
         * values indicate the amount by which the current point would
         * be advanced by $(D Context.showText()).
         *
         * Note that whitespace characters do not directly contribute
         * to the size of the rectangle (extents.width and extents.height).
         * They do contribute indirectly by changing the position of
         * non-whitespace characters. In particular, trailing whitespace
         * characters are likely to not affect the size of the
         * rectangle, though they will affect the x_advance
         * and y_advance values.
         */
        TextExtents textExtents(string text)
        {
            TextExtents res;
            cairo_scaled_font_text_extents(this.nativePointer, toStringz(text),
                &res);
            checkError();
            return res;
        }

        /**
         * Gets the extents for an array of glyphs. The extents describe
         * a user-space rectangle that encloses the "inked" portion
         * of the glyphs, (as they would be drawn by $(D Context.showGlyphs())
         * if the cairo graphics state were set to the same fontFace,
         * fontMatrix, ctm, and fontOptions as scaled_font). Additionally,
         * the x_advance and y_advance values indicate the amount by
         * which the current point would be advanced by $(D Context.showGlyphs()).
         *
         * Note that whitespace glyphs do not contribute to the size
         * of the rectangle (extents.width and extents.height).
         */
        TextExtents glyphExtents(Glyph[] glyphs)
        {
            TextExtents res;
            cairo_scaled_font_glyph_extents(this.nativePointer, glyphs.ptr,
                glyphs.length, &res);
            checkError();
            return res;
        }

        /**
         * Converts UTF-8 text to an array of glyphs, optionally with
         * cluster mapping, that can be used to render later using ScaledFont.
         *
         * If glyphBuffer initially points to a non-empty array, that array is
         * used as a glyph buffer. If the provided glyph array is too
         * short for the conversion, a new glyph array is allocated and returned.
         *
         * If clusterBuffer is not empty a cluster mapping will be computed.
         * The semantics of how cluster array allocation works is similar to the glyph array.
         * That is, if clusterBuffer initially points to a non-empty array,
         * that array is used as a cluster buffer.
         * If the provided cluster array is too short for the conversion,
         * a new cluster array is allocated and returned.
         *
         * In the simplest case, glyphs and clusters can be omitted
         * or set to an empty array and a suitable array will be allocated.
         * In code
         * -----------------
         * auto glyphs = scaled_font.textToTextGlyph(x, y, text);
         * cr.showTextGlyphs(glyphs);
         * -----------------
         * If no cluster mapping is needed
         * -----------------
         * auto glyphs = scaled_font.textToGlyphs(x, y, text);
         * cr.showGlyphs(glyphs);
         * -----------------
         * If stack-based glyph and cluster arrays are to be used for small arrays
         * -----------------
         * Glyph[40] stack_glyphs;
         * TextCluster[40] stack_clusters;
         * auto glyphs = scaled_font.textToTextGlyph(x, y, text, stack_glyphs, stack_clusters);
         * cr.showTextGlyphs(glyphs);
         * -----------------
         *
         * The output values can be readily passed to $(D Context.showTextGlyphs())
         * $(D Context.showGlyphs()), or related functions, assuming that
         * the exact same ScaledFont is used for the operation.
         *
         * Params:
         * x = X position to place first glyph
         * y = Y position to place first glyph
         */
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
        ///ditto
        Glyph[] textToGlyphs(Point p1, string text, Glyph[] glyphBuffer = [])
        {
            return textToGlyphs(p1.x, p1.y, text, glyphBuffer);
        }
        ///ditto
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
        ///ditto
        TextGlyph textToTextGlyph(Point p1, string text, Glyph[] glyphBuffer = [],
            TextCluster[] clusterBuffer = [])
        {
            return textToTextGlyph(p1.x, p1.y, text, glyphBuffer, clusterBuffer);
        }

        /**
         * Gets the font face that this scaled font uses. This is the
         * font face passed to $(D new ScaledFont()).
         */
        FontFace getFontFace()
        {
            auto face = cairo_scaled_font_get_font_face(this.nativePointer);
            checkError();
            return FontFace.createFromNative(face);
        }

        ///convenience alias
        alias getFontFace fontFace;
        
        /**
         * Returns the font options with which ScaledFont
         * was created.
         */
        FontOptions getFontOptions()
        {
            //TODO: verify if this is correct
            FontOptions fo = FontOptions();
            cairo_scaled_font_get_font_options(this.nativePointer, fo.nativePointer);
            checkError();
            return fo;
        }

        ///convenience alias
        alias getFontOptions fontOptions;
        
        /**
         * Returns the font matrix with which ScaledFont
         * was created.
         */
        Matrix getFontMatrix()
        {
            Matrix mat;
            cairo_scaled_font_get_font_matrix(this.nativePointer, &mat.nativeMatrix);
            checkError();
            return mat;
        }

        ///convenience alias
        alias getFontMatrix fontMatrix;
        
        /**
         * Returns the CTM with which ScaledFont was created.
         * Note that the translation offsets (x0, y0) of the CTM are
         * ignored by $(D new ScaledFont()). So, the matrix this function
         * returns always has 0,0 as x0,y0.
         */
        Matrix getCTM()
        {
            Matrix mat;
            cairo_scaled_font_get_ctm(this.nativePointer, &mat.nativeMatrix);
            checkError();
            return mat;
        }
        
        ///convenience alias
        alias getCTM CTM;

        /**
         * Returns the scale matrix of ScaledFont.
         * The scale matrix is product of the font matrix and the
         * ctm associated with the scaled font, and hence is the
         * matrix mapping from font space to device space.
         */
        Matrix getScaleMatrix()
        {
            Matrix mat;
            cairo_scaled_font_get_scale_matrix(this.nativePointer, &mat.nativeMatrix);
            checkError();
            return mat;
        }

        ///convenience alias
        alias getScaleMatrix scaleMatrix;
        
        /**
         * This function returns the C type of a ScaledFont. See $(D FontType)
         * for available types.
         */
        FontType getType()
        {
            auto tmp = cairo_scaled_font_get_type(this.nativePointer);
            checkError();
            return tmp;
        }
        
        ///convenience alias
        alias getType type;
}

/**
 * Base class for font faces
 *
 * $(D FontFace) represents a particular font at a particular weight,
 * slant, and other characteristic but no size, transformation, or size.
 *
 * Font faces are created using font-backend-specific classes,
 * typically of the form $(D *FontFace), or implicitly
 * using the toy text API by way of $(D Context.selectFontFace()). The
 * resulting face can be accessed using $(D Context.getFontFace()).
 */
public class FontFace
{
    ///
    mixin CairoCountedClass!(cairo_font_face_t*, "cairo_font_face_");

    protected:
        /**
         * Method for use in subclasses.
         * Calls $(D cairo_font_face_status(nativePointer)) and throws
         * an exception if the status isn't CAIRO_STATUS_SUCCESS
         */
        final void checkError()
        {
            throwError(cairo_font_face_status(nativePointer));
        }

    public:
        /**
         * Create a $(D FontFace) from a existing $(D cairo_font_face_t*).
         * FontFace is a garbage collected class. It will call $(D cairo_font_face_destroy)
         * when it gets collected by the GC or when $(D dispose()) is called.
         *
         * Warning:
         * $(D ptr)'s reference count is not increased by this function!
         * Adjust reference count before calling it if necessary
         *
         * $(RED Only use this if you know what your doing!
         * This function should not be needed for standard cairoD usage.)
         */
        this(cairo_font_face_t* ptr)
        {
            this.nativePointer = ptr;
            checkError();
        }

        /**
         * The createFromNative method for the FontFace classes.
         * See $(LINK https://github.com/jpf91/cairoD/wiki/Memory-Management#createFromNative)
         * for more information.
         *
         * Warning:
         * $(RED Only use this if you know what your doing!
         * This function should not be needed for standard cairoD usage.)
         */
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
                version(CAIRO_HAS_FT_FONT)
                {
                    case cairo_font_type_t.CAIRO_FONT_TYPE_FT:
                        return new FTFontFace(ptr);
                }
                default:
                    return new FontFace(ptr);
            }
        }

        /**
         * This function returns the C type of a FontFace. See $(D FontType)
         * for available types.
         */
        FontType getType()
        {
            auto tmp = cairo_font_face_get_type(this.nativePointer);
            checkError();
            return tmp;
        }
        
        ///convenience alias
        alias getType type;
}

/**
 * Cairo toy font api's FontFace
 */
public class ToyFontFace : FontFace
{
    public:
        /**
         * Create a $(D ToyFontFace) from a existing $(D cairo_font_face_t*).
         * ToyFontFace is a garbage collected class. It will call $(D cairo_surface_destroy)
         * when it gets collected by the GC or when $(D dispose()) is called.
         *
         * Warning:
         * $(D ptr)'s reference count is not increased by this function!
         * Adjust reference count before calling it if necessary
         *
         * $(RED Only use this if you know what your doing!
         * This function should not be needed for standard cairoD usage.)
         */
        this(cairo_font_face_t* ptr)
        {
            super(ptr);
        }

        /**
         * Creates a font face from a triplet of family, slant, and weight.
         * These font faces are used in implementation of the the cairo "toy" font API.
         *
         * If family is the zero-length string "", the platform-specific
         * default family is assumed. The default family then
         * can be queried using $(D getFamily()).
         *
         * The $(D Context.selectFontFace()) function uses this to create
         * font faces. See that function for limitations and
         * other details of toy font faces.
         */
        this(string family, FontSlant slant, FontWeight weight)
        {
            super(cairo_toy_font_face_create(toStringz(family), slant, weight));
        }

        /**
         * Gets the familly name of a toy font.
         */
        string getFamily()
        {
            auto ptr = cairo_toy_font_face_get_family(this.nativePointer);
            checkError();
            return to!string(ptr);
        }

        ///convenience alias
        alias getFamily family;
        
        /**
         * Gets the slant a toy font.
         */
        FontSlant getSlant()
        {
            auto res = cairo_toy_font_face_get_slant(this.nativePointer);
            checkError();
            return res;
        }

        ///convenience alias
        alias getSlant slant;
        
        /**
         * Gets the weight of a toy font.
         */
        FontWeight getWeight()
        {
            auto res = cairo_toy_font_face_get_weight(this.nativePointer);
            checkError();
            return res;
        }
        
        ///convenience alias
        alias getWeight weight;
}

/**
 * Cairo version information
 */
public struct Version
{
    public:
        ///Major, Minor and Micro versions
        uint major;
        uint minor; ///ditto
        uint micro; ///ditto

        /**
         * Construct a version object from a encoded version.
         */
        this(ulong encoded)
        {
            this.major = cast(uint)(encoded / 10000);
            this.minor = cast(uint)((encoded % 10000) / 100);
            this.micro = cast(uint)((encoded % 10000) % 100);
        }

        /**
         * Construct a version object from version components.
         */
        this(uint major, uint minor, uint micro)
        {
            this.major = major;
            this.minor = minor;
            this.micro = micro;
        }

        /**
         * Return the (runtime) version of the used cairo
         * library.
         */
        static @property Version cairoVersion()
        {
            return Version(cairo_version());
        }

        /**
         * Returns the (compile time) version of this binding / wrapper.
         */
        static @property Version bindingVersion()
        {
            return Version(CAIRO_VERSION_MAJOR, CAIRO_VERSION_MINOR,
                CAIRO_VERSION_MICRO);
        }

        /**
         * Returns the version in encoded form.
         */
        ulong encode()
        {
            return CAIRO_VERSION_ENCODE(major, minor, micro);
        }

        /**
         * toString implementation
         */
        string toString()
        {
            return CAIRO_VERSION_STRINGIZE(major, minor, micro);
        }
}


/**
 * RandomAccessRange to iterate or index into Clips of a Cairo Region.
 * This range keeps a reference to its $(D Region) object,
 * so it can be passed around without thinking about memory management.
 */
import std.exception : enforce;

public struct ClipRange
{
    private Region _outer;
    private size_t _a, _b;

    this(Region data)
    {
        _outer = data;
        _b = _outer.numRectangles();
    }
    
    this(Region data, size_t a, size_t b)
    {
        _outer = data;
        _a = a;
        _b = b;
    }

    @property bool empty() // const
    {
        assert(_outer.numRectangles() >= _b);
        return _a >= _b;
    }

    @property typeof(this) save()
    {
        return this;
    }

    @property Rectangle!int front()
    {
        enforce(!empty);
        return _outer.getRectangle(_a);
    }

    @property Rectangle!int back()
    {
        enforce(!empty);
        return _outer.getRectangle(_b - 1);
    }

    void popFront()
    {
        enforce(!empty);
        ++_a;
    }

    void popBack()
    {
        enforce(!empty);
        --_b;
    }

    Rectangle!int opIndex(size_t i)
    {
        i += _a;
        enforce(i < _b && _b <= _outer.numRectangles);
        return _outer.getRectangle(i);
    }

    typeof(this) opSlice()
    {
        return this;
    }    
    
    typeof(this) opSlice(size_t a, size_t b)
    {
        return typeof(this)(_outer, a + _a, b + _a);
    }

    @property size_t length() const {
        return _b - _a;
    }
}

unittest
{
    static assert(isRandomAccessRange!ClipRange);
}

unittest
{
    auto rect1 = Rectangle!int(0, 0, 100, 100);
    auto rect2 = Rectangle!int(200, 200, 100, 100);
    
    auto region = Region(rect1);
    region += rect2;
    
    assert(region.clips.length == 2);
    assert(region.clips[].length == 2);
    assert(array(region.clips) == [rect1, rect2]);
    
    assert(region.clips[1..2].length == 1);
    assert(region.clips[1..2][0] == rect2);
    
    assert(region.clips[0] == rect1);
    assert(region.clips[1] == rect2);
    
    foreach (i, clip; [rect1, rect2])
    {
        assert(region.clips[i] == clip);
    }
    
    /* @BUG@ Access Violation */
    foreach (regRect, oldRect; lockstep(region.clips, [rect1, rect2]))
    {
        //~ assert(regRect == oldRect);
    }
}


public struct Region
{
    /*---------------------------Reference counting stuff---------------------------*/
    protected:
        void _reference()
        {
            cairo_region_reference(this.nativePointer);
        }

        void _dereference()
        {
            cairo_region_destroy(this.nativePointer);
        }

    public:
        /**
         * The underlying $(D cairo_t*) handle
         */
        cairo_region_t* nativePointer;
        version(D_Ddoc)
        {
             /**
             * Enable / disable memory management debugging for this Context
             * instance. Only available if both cairoD and the cairoD user
             * code were compiled with "debug=RefCounted"
             *
             * Output is written to stdout, see 
             * $(LINK https://github.com/jpf91/cairoD/wiki/Memory-Management#debugging)
             * for more information
             */
             bool debugging = false;
        }
        else debug(RefCounted)
        {
            bool debugging = false;
        }
    
        /**
         * Constructor that tracks the reference count appropriately. If $(D
         * !refCountedIsInitialized), does nothing.
         */
        this(this)
        {
            if (this.nativePointer is null)
                return;
            this._reference();
            debug(RefCounted)
                if (this.debugging)
            {
                     writeln(typeof(this).stringof,
                    "@", cast(void*) this.nativePointer, ": bumped refcount.");
            }
        }
    
        ~this()
        {
            this.dispose();
        }

        /**
         * Explicitly drecrease the reference count.
         *
         * See $(LINK https://github.com/jpf91/cairoD/wiki/Memory-Management#2.1-structs)
         * for more information.
         */
        void dispose()
        {
           if (this.nativePointer is null)
                return;

            debug(RefCounted)
                if (this.debugging)
            {
                     writeln(typeof(this).stringof,
                    "@", cast(void*)this.nativePointer,
                    ": decrement refcount");
            }
            this._dereference();
            this.nativePointer = null;
        }
        
        /**
         * Assignment operator
         */
        void opAssign(Region rhs)
        {
            this.nativePointer = cairo_region_copy(rhs.nativePointer);
            debug(RefCounted)
                this.debugging = rhs.debugging;
        }
    /*------------------------End of Reference counting-----------------------*/

    public:
        this(Region region)
        {
            this(cairo_region_copy(region.nativePointer));
            debug(RefCounted)
                this.debugging = region.debugging;
        }
        
        /**
         * Create a $(D Region) from a existing $(D cairo_region_t*).
         * Context is a garbage collected class. It will call $(D cairo_region_destroy)
         * when it gets collected by the GC or when $(D dispose()) is called.
         *
         * Warning:
         * $(D ptr)'s reference count is not increased by this function!
         * Adjust reference count before calling it if necessary
         *
         * $(RED Only use this if you know what your doing!
         * This function should not be needed for standard cairoD usage.)
         */
        this(cairo_region_t* ptr)
        {
            this.nativePointer = ptr;
            if(!ptr)
            {
                throw new CairoException(cairo_status_t.CAIRO_STATUS_NULL_POINTER);
            }
            checkError();
        }        
        
    protected:
        /**
         * Method for use in subclasses.
         * Calls $(D cairo_region_status(nativePointer)) and throws
         * an exception if the status isn't CAIRO_STATUS_SUCCESS
         */
        final void checkError()
        {
            throwError(cairo_region_status(nativePointer));
        }

    public:
        void newRegion()
        {
            this = Region(cairo_region_create());
        }
        
        this(Rectangle!int rect)
        {
            this(cairo_region_create_rectangle(cast(cairo_rectangle_int_t*)&rect));
        }

        this(Rectangle!int[] rects)
        {
            this(cairo_region_create_rectangles(cast(cairo_rectangle_int_t*)rects.ptr, rects.length));
        }

        Rectangle!int getExtents()
        {
            Rectangle!int extents;
            cairo_region_get_extents(this.nativePointer, cast(cairo_rectangle_int_t*)&extents);
            checkError();
            return extents;
        }
        
        ///convenience alias
        alias getExtents extents;
        
        int numRectangles()
        {
            return cairo_region_num_rectangles(this.nativePointer);
        }
        
        Rectangle!int getRectangle(int index)
        {
            Rectangle!int rect;
            cairo_region_get_rectangle(this.nativePointer, index, cast(cairo_rectangle_int_t*)&rect);
            checkError();
            return rect;
        }
        
        @property auto getRectangles()
        {
            return ClipRange(this);
        }        
        
        ///convenience alias
        alias getRectangles rectangles;
        
        @property bool empty()
        {
            return cast(bool)cairo_region_is_empty(this.nativePointer);
        }

        RegionOverlap containsRectangle(Rectangle!int rect)
        {
            return cairo_region_contains_rectangle(this.nativePointer, cast(cairo_rectangle_int_t*)&rect);
        }

        bool containsPoint(PointInt point)
        {
            return cast(bool)cairo_region_contains_point(this.nativePointer, point.x, point.y);
        }

        void translate(int dx, int dy)
        {
            cairo_region_translate(this.nativePointer, dx, dy);
            checkError();
        }

        const bool opEquals(ref const(Region) other)
        {
            return cast(bool)cairo_region_equal(this.nativePointer, other.nativePointer);
        }        
        
        ///subtract
        Region opBinary(string op)(Region rhs) if(op == "-")
        {
            auto result = Region(this);
            throwError(cairo_region_subtract(result.nativePointer, rhs.nativePointer));
            return result;
        }
        
        Region opOpAssign(string op)(Region rhs) if(op == "-")
        {
            throwError(cairo_region_subtract(this.nativePointer, rhs.nativePointer));
            return this;
        }        

        Region opBinary(string op)(Rectangle!int rhs) if(op == "-")
        {
            auto result = Region(this);
            throwError(cairo_region_subtract_rectangle(result.nativePointer, cast(cairo_rectangle_int_t*)&rhs));
            return result;
        }
        
        Region opOpAssign(string op)(Rectangle!int rhs) if(op == "-")
        {
            throwError(cairo_region_subtract_rectangle(this.nativePointer, cast(cairo_rectangle_int_t*)&rhs));
            return this;
        }
        
        ///intersect
        Region opBinary(string op)(Region rhs) if(op == "&")
        {
            auto result = Region(this);
            throwError(cairo_region_intersect(result.nativePointer, rhs.nativePointer));
            return result;
        }

        Region opOpAssign(string op)(Region rhs) if(op == "&")
        {
            throwError(cairo_region_intersect(this.nativePointer, rhs.nativePointer));
            return this;
        }        
        
        Region opBinary(string op)(Rectangle!int rhs) if(op == "&")
        {
            auto result = Region(this);
            throwError(cairo_region_intersect_rectangle(result.nativePointer, cast(cairo_rectangle_int_t*)&rhs));
            return result;
        }
        
        Region opOpAssign(string op)(Rectangle!int rhs) if(op == "&")
        {
            throwError(cairo_region_intersect_rectangle(this.nativePointer, cast(cairo_rectangle_int_t*)&rhs));
            return this;
        }
        
        ///union
        Region opBinary(string op)(Region rhs) if(op == "|")
        {
            auto result = Region(this);
            throwError(cairo_region_union(result.nativePointer, rhs.nativePointer));
            return result;
        }

        Region opOpAssign(string op)(Region rhs) if(op == "|")
        {
            throwError(cairo_region_union(this.nativePointer, rhs.nativePointer));
            return this;
        }        
        
        Region opBinary(string op)(Rectangle!int rhs) if(op == "|")
        {
            auto result = Region(this);
            throwError(cairo_region_union_rectangle(result.nativePointer, cast(cairo_rectangle_int_t*)&rhs));
            return result;
        }

        Region opOpAssign(string op)(Rectangle!int rhs) if(op == "|")
        {
            throwError(cairo_region_union_rectangle(this.nativePointer, cast(cairo_rectangle_int_t*)&rhs));
            return this;
        }        
        
        ///xor
        Region opBinary(string op)(Region rhs) if(op == "^")
        {
            auto result = Region(this);
            throwError(cairo_region_xor(result.nativePointer, rhs.nativePointer));
            return result;
        }

        Region opOpAssign(string op)(Region rhs) if(op == "^")
        {
            throwError(cairo_region_xor(this.nativePointer, rhs.nativePointer));
            return this;
        }        
        
        Region opBinary(string op)(Rectangle!int rhs) if(op == "^")
        {
            auto result = Region(this);
            throwError(cairo_region_xor_rectangle(result.nativePointer, cast(cairo_rectangle_int_t*)&rhs));
            return result;
        }
        
        Region opOpAssign(string op)(Rectangle!int rhs) if(op == "^")
        {
            throwError(cairo_region_xor_rectangle(this.nativePointer, cast(cairo_rectangle_int_t*)&rhs));
            return this;
        }        
}

unittest
{
    auto rect1 = Rectangle!int(0, 0, 100, 100);
    auto region = Region(rect1);
    
    assert(region.numRectangles == 1);
    assert(!region.empty);
    
    assert(region.containsPoint(PointInt(50, 0)));
    assert(!region.containsPoint(PointInt(100, 0)));  // 100 is over the range of 0 .. 100 (99 is max)
    
    region.translate(10, 0);
    assert(region.containsPoint(PointInt(100, 0)));   // range is now 10 .. 110
    assert(!region.containsPoint(PointInt(0, 0)));    // 0 is below the minimum of 10
    
    region = region ^ region;  // xor, 1 ^ 1 == 0 :)
    assert(region.empty);
    
    auto rect2 = Rectangle!int(99, 0, 100, 100);
    region = Region([rect1, rect2]);
    assert(region.numRectangles == 1);  // note: cairo merges the two rectangles as they
                                        // form a closed rectangle path.

    rect2.point.x = 120;
    region = Region([rect1, rect2]);
    assert(region.numRectangles == 2);  // now they can't be merged
    
    region = Region(rect1);
    region = region | rect2;
    assert(region.numRectangles == 2);  // same thing when using a union
    
    rect2.point.x += 10;
    region = region - rect2;
    assert(region.numRectangles == 2);  // still two rectangles due to extra edge
    
    rect2.point.x -= 10;
    region = region - rect2;
    assert(region.numRectangles == 1);  // and now the second rectangle is completely gone
    
    region -= rect1;
    assert(region.empty);             // first rectangle also gone, region is empty

    auto region1 = Region(rect1);
    auto region2 = Region(rect1);
    assert(region1 == region2);
}    

unittest
{
    auto surface = new ImageSurface(Format.CAIRO_FORMAT_ARGB32, 100, 100);
    auto ctx = Context(surface);
    
    ctx.rectangle(10, 20, 100, 100);
    auto path = ctx.copyPath();
    
    size_t index;
    foreach (element; path[])
    {
        switch (element.type)
        {
             case PathElementType.CAIRO_PATH_MOVE_TO:
             {
                 assert(element[0].x == 10 && element[0].y == 20);
                 break;
             }
             case PathElementType.CAIRO_PATH_LINE_TO:
             {
                 if (index == 1)
                     assert(element[0].x == 110 && element[0].y == 20);
                 else if (index == 2)
                     assert(element[0].x == 110 && element[0].y == 120);
                 else if (index == 3)
                     assert(element[0].x == 10 && element[0].y == 120);
                 break;
             }
             default:
        }
        index++;
    }    
}
