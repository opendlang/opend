/**
 * Note:
 *  Environment variables affecting the backend:
 *
 *  CAIRO_DIRECTFB_NO_ACCEL (boolean)
 *      if found, disables acceleration at all
 *
 *  CAIRO_DIRECTFB_ARGB_FONT (boolean)
 *      if found, enables using ARGB fonts instead of A8
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
module cairo.c.directfb;

import cairo.c.cairo;

version(CAIRO_HAS_DIRECTFB_SURFACE)
{
    pragma(msg, "cairo.c.directfb: FIX: need proper DirectFB bindings");
    //import directfb;
    alias void IDirectFB;
    alias void IDirectFBSurface;

    extern(C):
    ///
    cairo_surface_t*
    cairo_directfb_surface_create (IDirectFB *dfb, IDirectFBSurface *surface);
}
else
{
    //static assert(false, "Cairo was not compiled with support for the directfb backend");
}
