module cairo.win32;

import std.string;
import std.conv;

import cairo.cairo;
import cairo.c.cairo;

version(CAIRO_HAS_WIN32_SURFACE)
{
    import cairo.c.win32;
    import core.sys.windows.windows;
    
    public class Win32Surface : Surface
    {
        public:
            this(cairo_surface_t* ptr)
            {
                super(ptr);
            }

            this(HDC hdc, bool printing = false)
            {
                if(printing)
                    super(cairo_win32_printing_surface_create(hdc));
                else
                    super(cairo_win32_surface_create(hdc));
            }

            this(HDC hdc, cairo_format_t format, int width, int height)
            {
                super(cairo_win32_surface_create_with_ddb(hdc, format, width, height));
            }

            this(cairo_format_t format, int width, int height)
            {
                super(cairo_win32_surface_create_with_dib(format, width, height));
            }

            static Win32Surface castFrom(Surface other)
            {
                if(!other.nativePointer)
                {
                    throw new CairoException(cairo_status_t.CAIRO_STATUS_NULL_POINTER);
                }
                auto type = cairo_surface_get_type(other.nativePointer);
                throwError(cairo_surface_status(other.nativePointer));
                if(type == cairo_surface_type_t.CAIRO_SURFACE_TYPE_WIN32 ||
                   type == cairo_surface_type_t.CAIRO_SURFACE_TYPE_WIN32_PRINTING)
                    return new Win32Surface(other.nativePointer);
                else
                    return null;
            }

            HDC getDC()
            {
                scope(exit)
                    checkError();
                return cairo_win32_surface_get_dc(this.nativePointer);
            }

            Surface getImage()
            {
                scope(exit)
                    checkError();
                return(Surface.createFromNative(cairo_win32_surface_get_image(this.nativePointer)));
            }
    }
    version(CAIRO_HAS_WIN32_FONT)
    {
        //TODO: Font support
    }
}
