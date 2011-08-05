/**
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
 *   $(TR $(TD $(LINK2 http://cairographics.org, _cairo team)) $(TD _cairo))
 * )
 */
/*
 * Distributed under the Boost Software License, Version 1.0.
 *    (See accompanying file LICENSE_1_0.txt or copy at
 *          http://www.boost.org/LICENSE_1_0.txt)
 */
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

    /**
     * Microsoft Windows surface support
     *
     * The Microsoft Windows surface is used to render cairo graphics to
     * Microsoft Windows windows, bitmaps, and printing device contexts.
     *
     * If printing is set to true, the surface
     * is of surface type CAIRO_SURFACE_TYPE_WIN32_PRINTING and is
     * a multi-page vector surface type.
     *
     * The surface returned by the other win32 constructors is of
     * surface type CAIRO_SURFACE_TYPE_WIN32 and is a raster surface type.
     */
    public class Win32Surface : Surface
    {
        public:
            /**
             * Create a $(D Win32Surface) from a existing $(D cairo_surface_t*).
             * Win32Surface is a garbage collected class. It will call $(D cairo_surface_destroy)
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
             * If printing is false:
             * 
             * Creates a cairo surface that targets the given DC.
             * The DC will be queried for its initial clip extents,
             * and this will be used as the size of the cairo surface.
             * The resulting surface will always be of format
             * CAIRO_FORMAT_RGB24; should you need another surface
             * format, you will need to us other constructors.
             *
             * If printing is true:
             * Creates a cairo surface that targets the given DC.
             * The DC will be queried for its initial clip extents,
             * and this will be used as the size of the cairo surface.
             * The DC should be a printing DC; antialiasing will be
             * ignored, and GDI will be used as much as possible to
             * draw to the surface.
             *
             * The returned surface will be wrapped using the paginated
             * surface to provide correct complex rendering behaviour;
             * $(D showPage()) and associated methods must be used fo
             * correct output.
             */
            this(HDC hdc, bool printing = false)
            {
                if(printing)
                    super(cairo_win32_printing_surface_create(hdc));
                else
                    super(cairo_win32_surface_create(hdc));
            }

            /**
             * Params:
             * hdc = the DC to create a surface for
             * format = format of pixels in the surface to create
             * width = width of the surface, in pixels
             * height = height of the surface, in pixels
             */
            this(HDC hdc, cairo_format_t format, int width, int height)
            {
                super(cairo_win32_surface_create_with_ddb(hdc, format, width, height));
            }

            /**
             * Creates a device-independent-bitmap surface not associated
             * with any particular existing surface or device context.
             * The created bitmap will be uninitialized.
             *
             * Params:
             * format = format of pixels in the surface to create
             * width = width of the surface, in pixels
             * height = height of the surface, in pixels
             */
            this(cairo_format_t format, int width, int height)
            {
                super(cairo_win32_surface_create_with_dib(format, width, height));
            }

            /**
             * Returns the HDC associated with this surface, or
             * null if none. Also returns null if the surface
             * is not a win32 surface.
             */
            HDC getDC()
            {
                scope(exit)
                    checkError();
                return cairo_win32_surface_get_dc(this.nativePointer);
            }

            /**
             * Returns a $(D Surface) image surface that
             * refers to the same bits as the DIB of the Win32
             * surface. If the passed-in win32 surface is not a
             * DIB surface, null is returned.
             */
            Surface getImage()
            {
                scope(exit)
                    checkError();
                return(Surface.createFromNative(cairo_win32_surface_get_image(this.nativePointer)));
            }
    }
    version(CAIRO_HAS_WIN32_FONT)
    {
        /**
         * The Microsoft Windows font backend is primarily
         * used to render text on Microsoft Windows systems.
         */
        public class Win32FontFace : FontFace
        {
            public:
                /**
                 * Create a $(D Win32FontFace) from a existing $(D cairo_surface_t*).
                 * Win32FontFace is a garbage collected class. It will call $(D cairo_font_face_destroy)
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
                 * Creates a new font for the Win32 font backend based
                 * on a LOGFONT.
                 *
                 * This font can then be used with
                 * $(D Context.setFontFace()) or $(D new ScaledFont()).
                 * The $(D ScaledFont) returned from
                 * $(D new ScaledFont()) is also for
                 * the Win32 backend and can be used with
                 * functions such as $(D Win32ScaledFont.selectFont()).
                 */
                this(LOGFONTW* logfont)
                {
                    super(cairo_win32_font_face_create_for_logfontw(logfont));
                }

                /**
                 * Creates a new font for the Win32 font backend based on a HFONT.
                 *
                 * This font can then be used with
                 * $(D Context.setFontFace()) or $(D new ScaledFont()).
                 * The $(D ScaledFont) returned from
                 * $(D new ScaledFont()) is also for
                 * the Win32 backend and can be used with
                 * functions such as $(D Win32ScaledFont.selectFont()).
                 */
                this(HFONT font)
                {
                    super(cairo_win32_font_face_create_for_hfont(font));
                }

                /**
                 * Creates a new font for the Win32 font backend based
                 * on a LOGFONT.
                 *
                 * This font can then be used with
                 * $(D Context.setFontFace()) or $(D new ScaledFont()).
                 * The $(D ScaledFont) returned from
                 * $(D new ScaledFont()) is also for
                 * the Win32 backend and can be used with
                 * functions such as $(D Win32ScaledFont.selectFont()).
                 *
                 * Params:
                 * logfont = A LOGFONTW structure specifying the font
                 *   to use. If font is NULL then the lfHeight, lfWidth,
                 *   lfOrientation and lfEscapement fields of this
                 *   structure are ignored. Otherwise lfWidth,
                 *   lfOrientation and lfEscapement must be zero.
                 * font = An HFONT that can be used when the font matrix
                 *   is a scale by -lfHeight and the CTM is identity.
                 */
                this(LOGFONTW* logfont, HFONT font)
                {
                    super(cairo_win32_font_face_create_for_logfontw_hfont(logfont, font));
                }
        }

        /**
         * The Microsoft Windows font backend is primarily
         * used to render text on Microsoft Windows systems.
         */
        public class Win32ScaledFont : ScaledFont
        {
            public:
                /**
                 * Create a $(D Win32ScaledFont) from a existing $(D cairo_surface_t*).
                 * Win32ScaledFont is a garbage collected class. It will call $(D cairo_scaled_font_destroy)
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
                    super(ptr);
                }

                /**
                 * 
                 */
                this(Win32FontFace font_face, Matrix font_matrix, Matrix ctm,
                    FontOptions options)
                {
                    super(font_face, font_matrix, ctm, options);
                }

                /**
                 * Selects the font into the given device context and
                 * changes the map mode and world transformation of
                 * the device context to match that of the font. This
                 * function is intended for use when using layout APIs
                 * such as Uniscribe to do text layout with the cairo
                 * font. After finishing using the device context,
                 * you must call $(D Win32ScaledFont.doneFont()) to release
                 * any resources allocated by this function.
                 *
                 * See $(D Win32ScaledFont.getMetricsFactor()) for converting
                 * logical coordinates from the device context to font space.
                 *
                 * Normally, calls to SaveDC() and RestoreDC() would be
                 * made around the use of this function to preserve
                 * the original graphics state.
                 */
                void selectFont(HDC hdc)
                {
                    throwError(cairo_win32_scaled_font_select_font(this.nativePointer, hdc));
                }

                /**
                 * Releases any resources allocated by
                 * $(D Win32ScaledFont.selectFont())
                 */
                void doneFont()
                {
                    cairo_win32_scaled_font_done_font(this.nativePointer);
                    checkError();
                }

                /**
                 * Gets a scale factor between logical coordinates in
                 * the coordinate space used
                 * by $(D Win32ScaledFont.selectFont()) (that is,
                 * the coordinate system used by the Windows functions
                 * to return metrics) and font space coordinates.
                 */
                double getMetricsFactor()
                {
                    auto res = cairo_win32_scaled_font_get_metrics_factor(this.nativePointer);
                    checkError();
                    return res;
                }

                /**
                 * Gets the transformation mapping the logical space
                 * used by ScaledFont to device space.
                 */
                Matrix getLogicalToDevice()
                {
                    Matrix mat;
                    cairo_win32_scaled_font_get_logical_to_device(this.nativePointer,
                        &mat.nativeMatrix);
                    checkError();
                    return mat;
                }

                /**
                 * Gets the transformation mapping device space to the
                 * logical space used by ScaledFont.
                 */
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
