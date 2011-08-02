/**
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
 *   $(TR $(TD $(LINK2 http://cairographics.org, _cairo team)) $(TD _cairo))
 * )
 */
/*
 * Distributed under the Boost Software License, Version 1.0.
 *    (See accompanying file LICENSE_1_0.txt or copy at
 *          http://www.boost.org/LICENSE_1_0.txt)
 */
module cairo.c.win32;

import cairo.c.cairo;

version(CAIRO_HAS_WIN32_SURFACE)
{
    //Requires WindowsAPI: http://www.dsource.org/projects/bindings/wiki/WindowsApi
    import win32.windef;
    import win32.wingdi;

    extern(C):
    ///
    cairo_surface_t* cairo_win32_surface_create (HDC hdc);
    ///
    cairo_surface_t* cairo_win32_printing_surface_create (HDC hdc);
    ///
    cairo_surface_t* cairo_win32_surface_create_with_ddb (HDC hdc,
                                         cairo_format_t format,
                                         int width,
                                         int height);
    ///
    cairo_surface_t* cairo_win32_surface_create_with_dib (cairo_format_t format,
                                         int width,
                                         int height);
    ///
    HDC cairo_win32_surface_get_dc (cairo_surface_t* surface);
    ///
    cairo_surface_t* cairo_win32_surface_get_image (cairo_surface_t* surface);

    version(CAIRO_HAS_WIN32_FONT)
    {
        extern(C):
        /*
         * Win32 font support
         */
        ///
        cairo_font_face_t* cairo_win32_font_face_create_for_logfontw (LOGFONTW *logfont);
        ///
        cairo_font_face_t* cairo_win32_font_face_create_for_hfont (HFONT font);
        ///
        cairo_font_face_t* cairo_win32_font_face_create_for_logfontw_hfont (LOGFONTW *logfont, HFONT font);
        ///
        cairo_status_t cairo_win32_scaled_font_select_font (cairo_scaled_font_t* scaled_font,
                             HDC                  hdc);
        ///
        void
        cairo_win32_scaled_font_done_font (cairo_scaled_font_t* scaled_font);
        ///
        double
        cairo_win32_scaled_font_get_metrics_factor (cairo_scaled_font_t* scaled_font);
        ///
        void
        cairo_win32_scaled_font_get_logical_to_device (cairo_scaled_font_t* scaled_font,
                                   cairo_matrix_t *logical_to_device);
        ///
        void
        cairo_win32_scaled_font_get_device_to_logical (cairo_scaled_font_t* scaled_font,
                                   cairo_matrix_t* device_to_logical);
    }
}
else
{
    //static assert(false, "Cairo was not compiled with support for the win32 backend");
}
