/**
 * This module contains wrappers for most of cairo's fuctionality.
 * Additional wrappers for subsets of cairo are available in the
 * cairo.* modules.
 *
 * Note:
 * Most cairoD functions could throw an OutOfMemoryError. This is therefore not
 * explicitly stated in the functions' api documenation.
 *
 * See also:
 * $(LINK http://cairographics.org/documentation/)
 */
module cairo.cairo;

import cairo.c.cairo;
import cairo.util;

import std.conv;
import std.range; //For PathRange unittests
import std.string;
import std.traits;
import core.exception;
import std.algorithm;
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

/**
 * A simple struct representing a rectangle
 */
public struct Rectangle
{
    ///
    public this(Point point, double width, double height)
    {
        this.point = point;
        this.width = width;
        this.height = height;
    }

    ///TOP-LEFT point of the rectangle
    Point point;
    ///
    double width;
    ///
    double height;
}

/**
 * A simple struct representing a rectangle with only $(D int) values
 */
public struct RectangleInt
{
    ///
    public this(int x, int y, int width, int height)
    {
        this.x = x;
        this.y = y;
        this.width = width;
        this.height = height;
    }

    ///TOP-LEFT point of the rectangle: X coordinate
    int x;
    ///TOP-LEFT point of the rectangle: Y coordinate
    int y;
    ///
    int width, height;
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
}

/* From cairo binding documentation:
 * You should not present an API for mutating or for creating new cairo_path_t
 * objects. In the future, these guidelines may be extended to present an API
 * for creating a cairo_path_t from scratch for use with cairo_append_path()
 * but the current expectation is that cairo_append_path() will mostly be
 * used with paths from cairo_copy_path().*/
 /**
  * Reference counted wrapper around $(D cairo_path_t).
  * This struct can only be obtained from cairoD. It should not be created
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
            void opAssign(FontOptions.Payload rhs) { assert(false); }
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
        void checkError()
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
        void checkError()
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
        void checkError()
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
        static Surface createForRectangle(Surface target, Rectangle rect)
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
        void markDirtyRectangle(RectangleInt rect)
        {
            cairo_surface_mark_dirty_rectangle(this.nativePointer, rect.x,
                rect.y, rect.width, rect.height);
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

        /**
         * Get the format of the surface.
         */
        Format getFormat()
        {
            scope(exit)
                checkError();
            return cairo_image_surface_get_format(this.nativePointer);
        }

        /**
         * Get the width of the image surface in pixels.
         */
        int getWidth()
        {
            scope(exit)
                checkError();
            return cairo_image_surface_get_width(this.nativePointer);
        }

        /**
         * Get the height of the image surface in pixels.
         */
        int getHeight()
        {
            scope(exit)
                checkError();
            return cairo_image_surface_get_height(this.nativePointer);
        }

        /**
         * Get the stride of the image surface in bytes.
         */
        int getStride()
        {
            scope(exit)
                checkError();
            return cairo_image_surface_get_stride(this.nativePointer);
        }

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
        debug(RefCounted)
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


    private:
        void checkError()
        {
            throwError(cairo_status(nativePointer));
        }
        
    
    public:
        this(Surface target)
        {
            //cairo_create already references the pointer, so _reference
            //isn't necessary
            nativePointer = cairo_create(target.nativePointer);
            throwError(cairo_status(nativePointer));
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
        
        void appendPath(Path p)
        {
            cairo_append_path(this.nativePointer, p.nativePointer);
            checkError();
        }

        /**
         * appendPath for user created paths. There is no high level API
         * for user defined paths. Use $(D appendPath(Path p)) for paths
         * which were obtained from cairo.
         */
        void appendPath(cairo_path_t* path)
        {
            cairo_append_path(this.nativePointer, path);
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
    
        
        void checkError()
        {
            throwError(cairo_font_options_status(nativePointer));
        }
    
    public:
        @property cairo_font_options_t* nativePointer()
        {
            return _data._payload;
        }

        debug(RefCounted)
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

        static FontOptions opCall()
        {
            FontOptions opt;
            auto ptr = cairo_font_options_create();
            throwError(cairo_font_options_status(ptr));
            opt._data.RefCounted.initialize(ptr);
            return opt;
        }

        this(cairo_font_options_t* ptr)
        {
            if(!ptr)
            {
                throw new CairoException(cairo_status_t.CAIRO_STATUS_NULL_POINTER);
            }
            throwError(cairo_font_options_status(ptr));
            _data.RefCounted.initialize(ptr);
        }

        FontOptions copy()
        {
            return FontOptions(cairo_font_options_copy(nativePointer));
        }
        
        void merge(FontOptions other)
        {
            cairo_font_options_merge(nativePointer, other.nativePointer);
            checkError();
        }
        
        //TODO: how to merge that with toHash?
        ulong hash()
        {
            ulong hash = cairo_font_options_hash(nativePointer);
            checkError();
            return hash;
        }
        
        const bool opEquals(ref const(FontOptions) other)
        {
            return cairo_font_options_equal((cast(FontOptions)this).nativePointer,
                (cast(FontOptions)other).nativePointer) ? true : false;
        }
        
        void setAntiAlias(AntiAlias antialias)
        {
            cairo_font_options_set_antialias(nativePointer, antialias);
            checkError();
        }
        
        AntiAlias getAntiAlias()
        {
            scope(exit)
                checkError();
            return cairo_font_options_get_antialias(nativePointer);
        }
        
        void setSubpixelOrder(SubpixelOrder order)
        {
            cairo_font_options_set_subpixel_order(nativePointer, order);
            checkError();
        }
        
        SubpixelOrder getSubpixelOrder()
        {
            scope(exit)
                checkError();
            return cairo_font_options_get_subpixel_order(nativePointer);
        }
        
        void setHintStyle(HintStyle style)
        {
            cairo_font_options_set_hint_style(nativePointer, style);
            checkError();
        }
        
        HintStyle getHintStyle()
        {
            scope(exit)
                checkError();
            return cairo_font_options_get_hint_style(nativePointer);
        }
        
        void setHintMetrics(HintMetrics metrics)
        {
            cairo_font_options_set_hint_metrics(nativePointer, metrics);
            checkError();
        }
        
        HintMetrics getHintMetrics()
        {
            scope(exit)
                checkError();
            return cairo_font_options_get_hint_metrics(nativePointer);
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
    mixin CairoCountedClass!(cairo_scaled_font_t*, "cairo_scaled_font_");

    protected:
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
            this(cairo_scaled_font_create(font_face.nativePointer,
                &font_matrix.nativeMatrix, &ctm.nativeMatrix, options.nativePointer));
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
    mixin CairoCountedClass!(cairo_font_face_t*, "cairo_font_face_");

    protected:
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
    public:
        uint major, minor, micro;

        this(ulong encoded)
        {
            this.major = cast(uint)(encoded / 10000);
            this.minor = cast(uint)((encoded % 10000) / 100);
            this.micro = cast(uint)((encoded % 10000) % 100);
        }

        this(uint major, uint minor, uint micro)
        {
            this.major = major;
            this.minor = minor;
            this.micro = micro;
        }
    
        static @property Version cairoVersion()
        {
            return Version(cairo_version);
        }
    
        static @property Version bindingVersion()
        {
            return Version(CAIRO_VERSION_MAJOR, CAIRO_VERSION_MINOR,
                CAIRO_VERSION_MICRO);
        }

        ulong encode()
        {
            return CAIRO_VERSION_ENCODE(major, minor, micro);
        }
}
