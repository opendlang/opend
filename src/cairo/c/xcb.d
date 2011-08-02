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
module cairo.c.xcb;

import cairo.c.cairo;

version(CAIRO_HAS_XCB_SURFACE)
{
    pragma(msg, "cairo.c.xcb: FIX: need proper xcb bindings");
    //import xcb.xcb;
    //import xcb.render;
    alias void xcb_connection_t;
    alias void xcb_screen_t;
    alias void xcb_visualtype_t;
    alias void xcb_render_pictforminfo_t;
    alias uint xcb_drawable_t;
    alias uint xcb_pixmap_t;

    extern (C):
    ///
    cairo_surface_t* 
    cairo_xcb_surface_create (xcb_connection_t* connection,
                  xcb_drawable_t	 drawable,
                  xcb_visualtype_t* visual,
                  int			 width,
                  int			 height);
    ///
    cairo_surface_t* 
    cairo_xcb_surface_create_for_bitmap (xcb_connection_t* connection,
                         xcb_screen_t* screen,
                         xcb_pixmap_t	 bitmap,
                         int		 width,
                         int		 height);
    ///
    cairo_surface_t* 
    cairo_xcb_surface_create_with_xrender_format (xcb_connection_t* connection,
                              xcb_screen_t* screen,
                              xcb_drawable_t			 drawable,
                              xcb_render_pictforminfo_t* format,
                              int				 width,
                              int				 height);
    ///
    void
    cairo_xcb_surface_set_size (cairo_surface_t* surface,
                    int		     width,
                    int		     height);
    
    /** debug interface */
    void
    cairo_xcb_device_debug_cap_xshm_version (cairo_device_t *device,
                                             int major_version,
                                             int minor_version);
    ///ditto
    void
    cairo_xcb_device_debug_cap_xrender_version (cairo_device_t *device,
                                                int major_version,
                                                int minor_version);
}
else
{
    //static assert(false, "Cairo was not compiled with support for the xcb backend");
}
