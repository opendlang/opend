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
module cairo.ft;

import cairo.cairo;
import cairo.c.cairo;

version(CAIRO_HAS_FT_FONT)
{
    import cairo.c.ft;
    import derelict.freetype.ft;

    /**
     * Font support for FreeType
     */
    public class FTFontFace : FontFace
    {
        public:
            /**
             * Create a $(D FTFontFace) from a existing $(D cairo_font_face_t*).
             * FTFontFace is a garbage collected class. It will call $(D cairo_font_face_destroy)
             * when it gets collected by the GC or when $(D dispose()) is called.
             *
             * Warning:
             * $(D ptr)'s reference count is not increased by this function!
             * Adjust reference count before calling it if necessary
             *
             * $(RED Only use this if you know what your doing!
             * This function should not be needed for standard cairoD usage.)
             */
            this(cairo_font_face_t* ptr)
            {
                super(ptr);
            }

            /**
             * Creates a new font face for the FreeType font backend from
             * a pre-opened FreeType face. This font can then be
             * used with $(D Context.setFontFace()) or $(D new ScaledFont()).
             * The $(D ScaledFont) returned from
             * $(D new ScaledFont()) is also for
             * the FreeType backend and can be used with functions such
             * as $(FTScaledFont.lockFace()). Note that Cairo may
             * keep a reference to the FT_Face alive in a font-cache
             * and the exact lifetime of the reference depends highly
             * upon the exact usage pattern and is subject to external
             * factors. You must not call FT_Done_Face() before the
             * $(D FTFontFace) has been disposed / collected.
             *
             * TODO: translate example from cairo API docs;
             *  What abou the cairo_font_face_set_user_data part?
             */
            this(FT_Face face, int loadFlags)
            {
                super(cairo_ft_font_face_create_for_ft_face(face, loadFlags));
            }
    }

    /**
     * Font support for FreeType
     */
    public class FTScaledFont : ScaledFont
    {
        public:
            /**
             * Create a $(D FTScaledFont) from a existing $(D cairo_scaled_font_t*).
             * FTScaledFont is a garbage collected class. It will call $(D cairo_scaled_font_destroy)
             * when it gets collected by the GC or when $(D dispose()) is called.
             *
             * Warning:
             * $(D ptr)'s reference count is not increased by this function!
             * Adjust reference count before calling it if necessary
             *
             * $(RED Only use this if you know what your doing!
             * This function should not be needed for standard cairoD usage.)
             */
            this(cairo_scaled_font_t* ptr)
            {
                super(ptr);
            }

            /**
             * $(D lockFace()) gets the FT_Face object from a FreeType
             * backend font and scales it appropriately for the font.
             * You must release the face with $(D unlockFace()) when you
             * are done using it. Since the FT_Face object can be shared
             * between multiple $(D ScaledFont) objects, you must not
             * lock any other font objects until you unlock this one.
             * A count is kept of the number of times $(D lockFace())
             * is called. $(D unlockFace()) must be called the same number of times.
             *
             * You must be careful when using this function in a library
             * or in a threaded application, because freetype's design
             * makes it unsafe to call freetype functions simultaneously
             * from multiple threads, (even if using distinct FT_Face objects).
             * Because of this, application code that acquires an FT_Face
             * object with this call must add its own locking to protect
             * any use of that object, (and which also must protect any
             * other calls into cairo as almost any cairo function
             * might result in a call into the freetype library).
             */
            FT_Face lockFace()
            {
                auto tmp = cairo_ft_scaled_font_lock_face(this.nativePointer);
                checkError();
                return tmp;
            }

            /**
             * Releases a face obtained with $(D lockFace()).
             */
            void unlockFace()
            {
                cairo_ft_scaled_font_unlock_face(this.nativePointer);
                checkError();
                return;
            }
    }
}
