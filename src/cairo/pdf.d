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
module cairo.pdf;

import std.string;
import std.conv;

import cairo.cairo;
import cairo.c.cairo;

version(CAIRO_HAS_PDF_SURFACE)
{
    import cairo.c.pdf;
    public alias cairo_pdf_version_t PDFVersion;
    PDFVersion[] getPDFVersions()
    {
        int num;
        immutable(cairo_pdf_version_t*) vers;
        cairo_pdf_get_versions(&vers, &num);
        PDFVersion[] dvers;
        for(int i = 0; i < num; i++)
        {
            dvers ~= vers[i];
        }
        return dvers;
    }

    string PDFVersionToString(PDFVersion vers)
    {
        return to!string(cairo_pdf_version_to_string(vers));
    }

    public class PDFSurface : Surface
    {
        public:
            this(cairo_surface_t* ptr)
            {
                super(ptr);
            }

            this(double width, double height)
            {
                this("", width, height);
            }

            this(string fileName, double width, double height)
            {
                super(cairo_pdf_surface_create(toStringz(fileName), width, height));
            }

            void restrictToVersion(PDFVersion vers)
            {
                scope(exit)
                    checkError();
                cairo_pdf_surface_restrict_to_version(this.nativePointer, vers);
            }

            void setSize(double width, double height)
            {
                scope(exit)
                    checkError();
                return cairo_pdf_surface_set_size(this.nativePointer, width, height);
            }
    }
}
