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
module cairo.ps;

import std.string;
import std.conv;

import cairo.cairo;
import cairo.c.cairo;

version(CAIRO_HAS_PS_SURFACE)
{
    import cairo.c.ps;

    ///
    public alias cairo_ps_level_t PSLevel;

    /**
     * Used to retrieve the list of supported levels.
     * See $(D PSSurface.restrictToLevel()).
     */
    PSLevel[] getPSLevels()
    {
        int num;
        immutable(cairo_ps_level_t*) levels;
        cairo_ps_get_levels(&levels, &num);
        PSLevel[] dlevels;
        for(int i = 0; i < num; i++)
        {
            dlevels ~= levels[i];
        }
        return dlevels;
    }

    /**
     * Get the string representation of the given level id. This function
     * will return NULL if level id isn't valid. See $(D getPSLevels())
     * for a way to get the list of valid level ids.
     */
    string PSLevelToString(PSLevel level)
    {
        return to!string(cairo_ps_level_to_string(level));
    }

    /**
     * The PostScript surface is used to render cairo graphics to
     * Adobe PostScript files and is a multi-page vector surface backend.
     */
    public class PSSurface : Surface
    {
        public:
            /**
             * Create a $(D PSSurface) from a existing $(D cairo_surface_t*).
             * PSSurface is a garbage collected class. It will call $(D cairo_surface_destroy)
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
             * Creates a PostScript surface of the specified size in
             * points to be written to filename.
             *
             * Note that the size of individual pages of the PostScript
             * output can vary. See $(D setSize()).
             *
             * Params:
             * width = width of the surface, in points (1 point == 1/72.0 inch)
             * height = height of the surface, in points (1 point == 1/72.0 inch)
             */
            this(string fileName, double width, double height)
            {
                super(cairo_ps_surface_create(toStringz(fileName), width, height));
            }

            /**
             * Creates a PostScript surface of the specified size in
             * points.This will generate a PSSurface that may be queried and
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
             * Restricts the generated PostSript file to level.
             * See $(D getPSLevels()) for a list of available
             * level values that can be used here.
             *
             * This function should only be called before any
             * drawing operations have been performed on the given
             * surface. The simplest way to do this is to call this
             * function immediately after creating the surface.
             */
            void restrictToLevel(PSLevel level)
            {
                scope(exit)
                    checkError();
                cairo_ps_surface_restrict_to_level(this.nativePointer, level);
            }

            /**
             * If eps is true, the PostScript surface will output
             * Encapsulated PostScript.
             *
             * This function should only be called before any drawing
             * operations have been performed on the current page.
             * The simplest way to do this is to call this function
             * immediately after creating the surface. An Encapsulated
             * PostScript file should never contain more than one page.
             */
            void setEPS(bool eps)
            {
                scope(exit)
                    checkError();
                cairo_ps_surface_set_eps(this.nativePointer, cast(int)eps);
            }

            /**
             * Check whether the PostScript surface will output Encapsulated
             * PostScript.
             */
            bool getEPS(bool eps)
            {
                scope(exit)
                    checkError();
                return cairo_ps_surface_get_eps(this.nativePointer)  ? true : false;
            }

            /**
             * hanges the size of a PostScript surface for the current
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
                return cairo_ps_surface_set_size(this.nativePointer, width, height);
            }

            /**
             * This function indicates that subsequent calls to
             * $(D dscComment()) should direct comments
             * to the Setup section of the PostScript output.
             *
             * This function should be called at most once per surface,
             * and must be called before any call
             * to $(D dscBeginPageSetup()) and before
             * any drawing is performed to the surface.
             *
             * See $(D dscComment()) for more details.
             */
            void dscBeginSetup()
            {
                scope(exit)
                    checkError();
                cairo_ps_surface_dsc_begin_setup(this.nativePointer);
            }

            /**
             * This function indicates that subsequent calls to
             * $(D dscComment()) should direct
             * comments to the PageSetup section of the PostScript output.
             *
             * This function call is only needed for the first
             * page of a surface. It should be called after any
             * call to $(D dscBeginSetup()) and
             * before any drawing is performed to the surface.
             *
             * See $(D dscComment()) for more details.
             */
            void dscBeginPageSetup()
            {
                scope(exit)
                    checkError();
                cairo_ps_surface_dsc_begin_page_setup(this.nativePointer);
            }

            /**
             * See
             * $(LINK http://cairographics.org/manual/cairo-PostScript-Surfaces.html#cairo-ps-surface-dsc-comment)
             */
            void dscComment(string comment)
            {
                scope(exit)
                    checkError();
                cairo_ps_surface_dsc_comment(this.nativePointer, toStringz(comment));
            }
    }
}
