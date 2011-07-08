module cairo.xcb;

import std.string;
import std.conv;

import cairo.cairo;
import cairo.c.cairo;

version(CAIRO_HAS_XCB_SURFACE)
{
    import cairo.c.xcb;

    public class XCBSurface : Surface
    {
        public:
            this(cairo_surface_t* ptr)
            {
                super(ptr);
            }

            this(xcb_connection_t* connection, xcb_drawable_t drawable,
                xcb_visualtype_t* visual, int width, int height)
            {
                  super(cairo_xcb_surface_create(connection, drawable,
                      visual, width, height));
            }

            this(xcb_connection_t* connection, xcb_screen_t* screen,
                xcb_pixmap_t bitmap, int width, int height)
            {
                  super(cairo_xcb_surface_create_for_bitmap(connection, screen,
                      bitmap, width, height));
            }

            this(xcb_connection_t* connection, xcb_screen_t* screen,
                xcb_drawable_t drawable, xcb_render_pictforminfo_t* format,
                int width, int height)
            {
                  super(cairo_xcb_surface_create_with_xrender_format(connection,
                      screen, drawable, format, width, height));
            }

            static XCBSurface castFrom(Surface other)
            {
                if(!other.nativePointer)
                {
                    throw new CairoException(cairo_status_t.CAIRO_STATUS_NULL_POINTER);
                }
                auto type = cairo_surface_get_type(other.nativePointer);
                throwError(cairo_surface_status(other.nativePointer));
                if(type == cairo_surface_type_t.CAIRO_SURFACE_TYPE_XCB)
                    return new XCBSurface(other.nativePointer);
                else
                    return null;
            }

            void setSize(int width, int height)
            {
                cairo_xcb_surface_set_size(this.nativePointer, width, height);
                checkError();
            }

            /* debug interface */
            /* not exported, use c api*/
    }
}
