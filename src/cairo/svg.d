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
module cairo.svg;

import std.string;
import std.conv;

import cairo.cairo;
import cairo.c.cairo;

version(CAIRO_HAS_SVG_SURFACE)
{
    import cairo.c.svg;
    ///
    public alias cairo_svg_version_t SVGVersion;

    /**
     * Used to retrieve the list of supported versions.
     * See $(D SVGSurface.restrictToVersion()).
     */
    SVGVersion[] getSVGVersions()
    {
        int num;
        immutable(cairo_svg_version_t*) vers;
        cairo_svg_get_versions(&vers, &num);
        SVGVersion[] dvers;
        for(int i = 0; i < num; i++)
        {
            dvers ~= vers[i];
        }
        return dvers;
    }

    /**
     * Get the string representation of the given version id. This
     * function will return null if version isn't valid.
     * See $(D getSVGVersions()) for a way to get the list of
     * valid version ids.
     */
    string SVGVersionToString(SVGVersion vers)
    {
        return to!string(cairo_svg_version_to_string(vers));
    }

    /**
     * The SVG surface is used to render cairo graphics to SVG
     * files and is a multi-page vector surface backend.
     */
    public class SVGSurface : Surface
    {
        public:
            /**
             * Create a $(D SVGSurface) from a existing $(D cairo_surface_t*).
             * SVGSurface is a garbage collected class. It will call $(D cairo_surface_destroy)
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
             * Creates a SVG surface of the specified size in points to
             * be written to filename.
             *
             * The SVG surface backend recognizes the following MIME types
             * for the data attached to a surface
             * (see $(D Surface.setMimeData())) when it is used as a
             * source pattern for drawing on this surface:
             * CAIRO_MIME_TYPE_JPEG, CAIRO_MIME_TYPE_PNG, CAIRO_MIME_TYPE_URI.
             * If any of them is specified, the SVG backend emits a href
             * with the content of MIME data instead of a surface
             * snapshot (PNG, Base64-encoded) in the corresponding image tag.
             *
             * The unofficial MIME type CAIRO_MIME_TYPE_URI is examined
             * first. If present, the URI is emitted as is: assuring the
             * correctness of URI is left to the client code.
             *
             * If CAIRO_MIME_TYPE_URI is not present, but CAIRO_MIME_TYPE_JPEG
             * or CAIRO_MIME_TYPE_PNG is specified, the corresponding
             * data is Base64-encoded and emitted.
             *
             * Params:
             * width = width of the surface, in points (1 point == 1/72.0 inch)
             * height = height of the surface, in points (1 point == 1/72.0 inch)
             */
            this(string fileName, double width, double height)
            {
                super(cairo_svg_surface_create(toStringz(fileName), width, height));
            }

            /**
             * Creates a SVG surface of the specified size in points.
             * This will generate a SVG surface that may be queried and
             * used as a source, without generating a temporary file.
             *
             * The SVG surface backend recognizes the following MIME types
             * for the data attached to a surface
             * (see $(D Surface.setMimeData())) when it is used as a
             * source pattern for drawing on this surface:
             * CAIRO_MIME_TYPE_JPEG, CAIRO_MIME_TYPE_PNG, CAIRO_MIME_TYPE_URI.
             * If any of them is specified, the SVG backend emits a href
             * with the content of MIME data instead of a surface
             * snapshot (PNG, Base64-encoded) in the corresponding image tag.
             *
             * The unofficial MIME type CAIRO_MIME_TYPE_URI is examined
             * first. If present, the URI is emitted as is: assuring the
             * correctness of URI is left to the client code.
             *
             * If CAIRO_MIME_TYPE_URI is not present, but CAIRO_MIME_TYPE_JPEG
             * or CAIRO_MIME_TYPE_PNG is specified, the corresponding
             * data is Base64-encoded and emitted.
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
             * Restricts the generated SVG file to version.
             * See $(D getSVGVersions()) for a list of available
             * version values that can be used here.
             *
             * This function should only be called before any
             * drawing operations have been performed on the given surface.
             * The simplest way to do this is to call this function
             * immediately after creating the surface.
             */
            void restrictToVersion(SVGVersion vers)
            {
                scope(exit)
                    checkError();
                cairo_svg_surface_restrict_to_version(this.nativePointer, vers);
            }
    }
}
