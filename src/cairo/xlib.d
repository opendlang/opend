/**
 * X Window System rendering using XLib
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
module cairo.xlib;

import cairo.cairo;
import cairo.c.cairo;

version(CAIRO_HAS_XLIB_SURFACE)
{
    import cairo.c.xlib;
    //Requires XLIB bindings: http://www.dsource.org/projects/bindings/browser/trunk/X11
    import std.c.linux.X11.Xlib;

    /**
     * The XLib surface is used to render cairo graphics to X Window
     * System windows and pixmaps using the XLib library.
     *
     * Note that the XLib surface automatically takes advantage of
     * X render extension if it is available.
     */
    public class XlibSurface : Surface
    {
        public:
            /**
             * Create a $(D XlibSurface) from a existing $(D cairo_surface_t*).
             * XlibSurface is a garbage collected class. It will call $(D cairo_surface_destroy)
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
             * Creates an Xlib surface that draws to the given drawable.
             * The way that colors are represented in the drawable
             * is specified by the provided visual.
             *
             * Note: If drawable is a Window, then the function
             * $(D setSize()) must be called
             * whenever the size of the window changes.
             *
             * When drawable is a Window containing child windows then
             * drawing to the created surface will be clipped by
             * those child windows. When the created surface is
             * used as a source, the contents of the children
             * will be included.
             */
            this(Display* dpy, Drawable drawable, Visual* visual, int width, int height)
            {
                super(cairo_xlib_surface_create(dpy, drawable, visual, width, height));
            }

            /**
             * Creates an Xlib surface that draws to the given bitmap.
             * This will be drawn to as a CAIRO_FORMAT_A1 object.
             */
            this(Display* dpy, Pixmap bitmap, Screen* screen, int width, int height)
            {
                super(cairo_xlib_surface_create_for_bitmap(dpy, bitmap,
                    screen, width, height));
            }

            /**
             * Informs cairo of the new size of the X Drawable underlying
             * the surface. For a surface created for a Window
             * (rather than a Pixmap), this function must be called
             * each time the size of the window changes. (For a
             * subwindow, you are normally resizing the window yourself,
             * but for a toplevel window, it is necessary to
             * listen for ConfigureNotify events.)
             *
             * A Pixmap can never change size, so it is never necessary
             * to call this function on a surface created for a Pixmap.
             */
            void setSize(int width, int height)
            {
                cairo_xlib_surface_set_size(this.nativePointer, width, height);
                checkError();
            }

            /**
             * Get the X Display for the underlying X Drawable.
             */
            Display* getDisplay()
            {
                auto tmp = cairo_xlib_surface_get_display(this.nativePointer);
                checkError();
                return tmp;
            }

            /**
             * Get the X Screen for the underlying X Drawable.
             */
            Screen* getScreen()
            {
                auto tmp = cairo_xlib_surface_get_screen(this.nativePointer);
                checkError();
                return tmp;
            }

            /**
             * Informs cairo of a new X Drawable underlying the surface.
             * The drawable must match the display, screen and format
             * of the existing drawable or the application will
             * get X protocol errors and will probably terminate.
             * No checks are done by this function to ensure this compatibility.
             */
            void setDrawable(Drawable drawable, int width, int height)
            {
                cairo_xlib_surface_set_drawable(this.nativePointer,
                    drawable, width, height);
                checkError();
            }

            /**
             * Get the underlying X Drawable used for the surface.
             */
            Drawable getDrawable()
            {
                auto tmp = cairo_xlib_surface_get_drawable(this.nativePointer);
                checkError();
                return tmp;
            }

            /**
             * Gets the X Visual associated with surface, suitable
             * for use with the underlying X Drawable. If surface
             * was created by cairo_xlib_surface_create(), the return
             * value is the Visual passed to that constructor.
             */
            Visual* getVisual()
            {
                auto tmp = cairo_xlib_surface_get_visual(this.nativePointer);
                checkError();
                return tmp;
            }

            /**
             * Get the width of the X Drawable underlying the surface in pixels
             */
            int getWidth()
            {
                auto tmp = cairo_xlib_surface_get_width(this.nativePointer);
                checkError();
                return tmp;
            }

            /**
             * Get the height of the X Drawable underlying the surface in pixels
             */
            int getHeight()
            {
                auto tmp = cairo_xlib_surface_get_height(this.nativePointer);
                checkError();
                return tmp;
            }

            /**
             * Get the number of bits used to represent each pixel value.
             */
            int getDepth()
            {
                auto tmp = cairo_xlib_surface_get_depth(this.nativePointer);
                checkError();
                return tmp;
            }
    }
}
