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
module cairo.c.xlib;

import cairo.c.cairo;

version(CAIRO_HAS_XLIB_SURFACE)
{
    import std.c.linux.X11.Xlib;

    extern(C):
    ///
    cairo_surface_t *
    cairo_xlib_surface_create (Display     *dpy,
                   Drawable	drawable,
                   Visual      *visual,
                   int		width,
                   int		height);
    ///
    cairo_surface_t *
    cairo_xlib_surface_create_for_bitmap (Display  *dpy,
                          Pixmap	bitmap,
                          Screen	*screen,
                          int	width,
                          int	height);
    ///
    void
    cairo_xlib_surface_set_size (cairo_surface_t *surface,
                     int              width,
                     int              height);
    ///
    void
    cairo_xlib_surface_set_drawable (cairo_surface_t *surface,
                     Drawable	  drawable,
                     int              width,
                     int              height);
    ///
    Display *
    cairo_xlib_surface_get_display (cairo_surface_t *surface);

    ///
    Drawable
    cairo_xlib_surface_get_drawable (cairo_surface_t *surface);

    ///
    Screen *
    cairo_xlib_surface_get_screen (cairo_surface_t *surface);

    ///
    Visual *
    cairo_xlib_surface_get_visual (cairo_surface_t *surface);

    ///
    int
    cairo_xlib_surface_get_depth (cairo_surface_t *surface);

    ///
    int
    cairo_xlib_surface_get_width (cairo_surface_t *surface);

    ///
    int
    cairo_xlib_surface_get_height (cairo_surface_t *surface);
}
