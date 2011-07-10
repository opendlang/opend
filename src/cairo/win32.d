module cairo.win32;

import std.string;
import std.conv;

import cairo.cairo;
import cairo.c.cairo;

version(CAIRO_HAS_WIN32_SURFACE)
{
    import cairo.c.win32;
    //Requires WindowsAPI: http://www.dsource.org/projects/bindings/wiki/WindowsApi
    import win32.windef;
    import win32.wingdi;
    
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
        public class Win32FontFace : FontFace
        {
            public:
                /* Warning: ptr reference count is not increased by this function!
                 * Adjust reference count before calling it if necessary*/
                this(cairo_font_face_t* ptr)
                {
                    super(ptr);
                }

                this(LOGFONTW* logfont)
                {
                    super(cairo_win32_font_face_create_for_logfontw(logfont));
                }

                this(HFONT font)
                {
                    super(cairo_win32_font_face_create_for_hfont(font));
                }

                this(LOGFONTW* logfont, HFONT font)
                {
                    super(cairo_win32_font_face_create_for_logfontw_hfont(logfont, font));
                }
        }

        public class Win32ScaledFont : ScaledFont
        {
            public:
                /* Warning: ptr reference count is not increased by this function!
                 * Adjust reference count before calling it if necessary*/
                this(cairo_scaled_font_t* ptr)
                {
                    super(ptr);
                }
                this(Win32FontFace font_face, Matrix font_matrix, Matrix ctm,
                    FontOptions options)
                {
                    super(font_face, font_matrix, ctm, options);
                }

                void selectFont(HDC hdc)
                {
                    throwError(cairo_win32_scaled_font_select_font(this.nativePointer, hdc));
                }

                void doneFont()
                {
                    cairo_win32_scaled_font_done_font(this.nativePointer);
                    checkError();
                }

                double getMetricsFactor()
                {
                    auto res = cairo_win32_scaled_font_get_metrics_factor(this.nativePointer);
                    checkError();
                    return res;
                }

                Matrix getLogicalToDevice()
                {
                    Matrix mat;
                    cairo_win32_scaled_font_get_logical_to_device(this.nativePointer,
                        &mat.nativeMatrix);
                    checkError();
                    return mat;
                }

                Matrix getDeviceToLogical()
                {
                    Matrix mat;
                    cairo_win32_scaled_font_get_device_to_logical(this.nativePointer,
                        &mat.nativeMatrix);
                    checkError();
                    return mat;
                }
        }
    }
}
