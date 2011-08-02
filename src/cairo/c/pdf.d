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
module cairo.c.pdf;

import cairo.c.cairo;

version(CAIRO_HAS_PDF_SURFACE)
{
    extern(C)
    {
        /**
         * $(D cairo_pdf_version_t) is used to describe the version number of the PDF
         * specification that a generated PDF file will conform to.
         *
         * Since 1.10
         */
        enum cairo_pdf_version_t
        {
            CAIRO_PDF_VERSION_1_4, ///The version 1.4 of the PDF specification.
            CAIRO_PDF_VERSION_1_5 ///The version 1.5 of the PDF specification.
        }
        ///
        cairo_surface_t *
        cairo_pdf_surface_create (const char		*filename,
                      double		 width_in_points,
                      double		 height_in_points);
        ///
        cairo_surface_t *
        cairo_pdf_surface_create_for_stream (cairo_write_func_t	write_func,
                             void	       *closure,
                             double		width_in_points,
                             double		height_in_points);
        ///
        void
        cairo_pdf_surface_restrict_to_version (cairo_surface_t 		*surface,
                               cairo_pdf_version_t  	 ver);
        ///
        void
        cairo_pdf_get_versions (immutable(cairo_pdf_version_t*)* versions,
                                int                      	 *num_versions);
        ///
        immutable(char)*
        cairo_pdf_version_to_string (cairo_pdf_version_t ver);
        ///
        void
        cairo_pdf_surface_set_size (cairo_surface_t	*surface,
                        double		 width_in_points,
                        double		 height_in_points);
    }
}
else
{
    //static assert(false, "CairoD was not compiled with support for the pdf backend");
}
