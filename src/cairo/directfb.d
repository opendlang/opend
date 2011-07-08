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

            static DirectFBSurface castFrom(Surface other)
            {
                if(!other.nativePointer)
                {
                    throw new CairoException(cairo_status_t.CAIRO_STATUS_NULL_POINTER);
                }
                auto type = cairo_surface_get_type(other.nativePointer);
                throwError(cairo_surface_status(other.nativePointer));
                if(type == cairo_surface_type_t.CAIRO_SURFACE_TYPE_DIRECTFB)
                    return new DirectFBSurface(other.nativePointer);
                else
                    return null;
            }
    }
}
