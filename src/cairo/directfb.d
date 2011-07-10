module cairo.directfb;

import std.string;
import std.conv;

import cairo.cairo;
import cairo.c.cairo;

version(CAIRO_HAS_DIRECTFB_SURFACE)
{
    import cairo.c.directfb;

    public class DirectFBSurface : Surface
    {
        public:
            this(cairo_surface_t* ptr)
            {
                super(ptr);
            }

            this(IDirectFB *dfb, IDirectFBSurface *surface)
            {
                  super(cairo_directfb_surface_create(dfb, surface));
            }
    }
}
