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
module cairo.xcb;

import std.string;
import std.conv;

import cairo.cairo;
import cairo.c.cairo;

version(CAIRO_HAS_XCB_SURFACE)
{
    import cairo.c.xcb;

    public class XCBSurface : Surface
    {
        public:
            this(cairo_surface_t* ptr)
            {
                super(ptr);
            }

            this(xcb_connection_t* connection, xcb_drawable_t drawable,
                xcb_visualtype_t* visual, int width, int height)
            {
                  super(cairo_xcb_surface_create(connection, drawable,
                      visual, width, height));
            }

            this(xcb_connection_t* connection, xcb_screen_t* screen,
                xcb_pixmap_t bitmap, int width, int height)
            {
                  super(cairo_xcb_surface_create_for_bitmap(connection, screen,
                      bitmap, width, height));
            }

            this(xcb_connection_t* connection, xcb_screen_t* screen,
                xcb_drawable_t drawable, xcb_render_pictforminfo_t* format,
                int width, int height)
            {
                  super(cairo_xcb_surface_create_with_xrender_format(connection,
                      screen, drawable, format, width, height));
            }

            void setSize(int width, int height)
            {
                cairo_xcb_surface_set_size(this.nativePointer, width, height);
                checkError();
            }

            /* debug interface */
            /* not exported, use c api*/
    }
}
