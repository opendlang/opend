/**
 * Font support for FreeType
 *
 * Requires $(LINK2 http://www.dsource.org/projects/derelict, DerelictFT)
 *
 * This module only contains basic documentation. For more information
 * see $(LINK http://cairographics.org/manual/)
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
module cairo.c.ft;

version(CAIRO_HAS_FT_FONT)
{
    import cairo.c.cairo;
    import derelict.freetype.ft;

    extern(C):
    /* Fontconfig/Freetype platform-specific font interface */
    
    /*#if CAIRO_HAS_FC_FONT
    #include <fontconfig/fontconfig.h>
    #endif*/

    ///
    cairo_font_face_t* cairo_ft_font_face_create_for_ft_face (FT_Face face,
                           int load_flags);
    
    ///
    FT_Face cairo_ft_scaled_font_lock_face (cairo_scaled_font_t *scaled_font);
    
    ///
    void cairo_ft_scaled_font_unlock_face (cairo_scaled_font_t *scaled_font);
    
    /*#if CAIRO_HAS_FC_FONT
    
    cairo_public cairo_font_face_t *
    cairo_ft_font_face_create_for_pattern (FcPattern *pattern);
    
    cairo_public void
    cairo_ft_font_options_substitute (const cairo_font_options_t *options,
                      FcPattern                  *pattern);
    
    #endif*/
}
