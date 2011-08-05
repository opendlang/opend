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

    ///
    public alias cairo_pdf_version_t PDFVersion;

    /**
     * Used to retrieve the list of supported versions.
     * See $(D PDFSurface.restrictToVersion()).
     */
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

    /**
     * Get the string representation of the given version id.
     * This function will return null if version isn't valid.
     * See $(D getPDFVersions()) for a way to get the list of valid version ids.
     */
    string PDFVersionToString(PDFVersion vers)
    {
        return to!string(cairo_pdf_version_to_string(vers));
    }

    /**
     * The PDF surface is used to render cairo graphics to Adobe PDF
     * files and is a multi-page vector surface backend.
     */
    public class PDFSurface : Surface
    {
        public:
            /**
             * Create a $(D PDFSurface) from a existing $(D cairo_surface_t*).
             * PDFSurface is a garbage collected class. It will call $(D cairo_surface_destroy)
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
             * Creates a PDF surface of the specified size in points to
             * be written to filename.
             *
             * Params:
             * fileName = a filename for the PDF output (must be writable)
             * width = width of the surface, in points (1 point == 1/72.0 inch)
             * height = height of the surface, in points (1 point == 1/72.0 inch)
             */
            this(string fileName, double width, double height)
            {
                super(cairo_pdf_surface_create(toStringz(fileName), width, height));
            }

            /**
             * Creates a PDF surface of the specified size in points.
             * This will generate a PDF surface that may be queried and
             * used as a source, without generating a temporary file.
             * 
             * Params:
             * width = width of the surface, in points (1 point == 1/72.0 inch)
             * height = height of the surface, in points (1 point == 1/72.0 inch)
             */
            this(double width, double height)
            {
                this("", width, height);
            }

            /**
             * Restricts the generated PDF file to version. See
             * $(D getPDFVersions()) for a list of available
             * version values that can be used here.
             *
             * This function should only be called before any drawing
             * operations have been performed on the given surface.
             * The simplest way to do this is to call this function
             * immediately after creating the surface
             */
            void restrictToVersion(PDFVersion vers)
            {
                scope(exit)
                    checkError();
                cairo_pdf_surface_restrict_to_version(this.nativePointer, vers);
            }

            /**
             * Changes the size of a PDF surface for the current
             * (and subsequent) pages.
             *
             * This function should only be called before any drawing
             * operations have been performed on the current page.
             * The simplest way to do this is to call this function
             * immediately after creating the surface or immediately
             * after completing a page with either $(D Context.showPage())
             * or $(D Context.copyPage()).
             *
             * Params:
             * width = width of the surface, in points (1 point == 1/72.0 inch)
             * height = height of the surface, in points (1 point == 1/72.0 inch)
             */
            void setSize(double width, double height)
            {
                scope(exit)
                    checkError();
                return cairo_pdf_surface_set_size(this.nativePointer, width, height);
            }
    }
}
