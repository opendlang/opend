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
module cairo.c.svg;

import cairo.c.cairo;

version(CAIRO_HAS_SVG_SURFACE)
{
    extern(C):
    /**
     * cairo_svg_version_t is used to describe the version number of the SVG
     * specification that a generated SVG file will conform to.
     */
    enum cairo_svg_version_t
    {
        ///The version 1.1 of the SVG specification.
        CAIRO_SVG_VERSION_1_1,
        ///The version 1.2 of the SVG specification.
        CAIRO_SVG_VERSION_1_2
    }
    ///
    cairo_surface_t*
    cairo_svg_surface_create (const (char*) filename,
                  double	width_in_points,
                  double	height_in_points);
    ///
    cairo_surface_t*
    cairo_svg_surface_create_for_stream (cairo_write_func_t	write_func,
                         void*      closure,
                         double		width_in_points,
                         double		height_in_points);
    ///
    void
    cairo_svg_surface_restrict_to_version (cairo_surface_t*    surface,
                           cairo_svg_version_t  	 vers);
    ///
    void
    cairo_svg_get_versions (immutable(cairo_svg_version_t*)* versions,
                            int*                    num_versions);
    ///
    immutable(char)*
    cairo_svg_version_to_string (cairo_svg_version_t vers);
}
else
{
    //static assert(false, "Cairo was not compiled with support for the svg backend");
}
