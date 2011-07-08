module cairo.svg;

import std.string;
import std.conv;

import cairo.cairo;
import cairo.c.cairo;

version(CAIRO_HAS_SVG_SURFACE)
{
    import cairo.c.svg;
    
    public alias cairo_svg_version_t SVGVersion;
    SVGVersion[] getSVGVersions()
    {
        int num;
        const(cairo_svg_version_t*) vers;
        cairo_svg_get_versions(&vers, &num);
        SVGVersion[] dvers;
        for(int i = 0; i < num; i++)
        {
            dvers ~= vers[i];
        }
        return dvers;
    }

    string SVGVersionToString(SVGVersion vers)
    {
        return to!string(cairo_svg_version_to_string(vers));
    }

    public class SVGSurface : Surface
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
                super(cairo_svg_surface_create(toStringz(fileName), width, height));
            }

            static SVGSurface castFrom(Surface other)
            {
                if(!other.nativePointer)
                {
                    throw new CairoException(cairo_status_t.CAIRO_STATUS_NULL_POINTER);
                }
                auto type = cairo_surface_get_type(other.nativePointer);
                throwError(cairo_surface_status(other.nativePointer));
                if(type == cairo_surface_type_t.CAIRO_SURFACE_TYPE_SVG)
                    return new SVGSurface(other.nativePointer);
                else
                    return null;
            }

            void restrictToVersion(SVGVersion vers)
            {
                scope(exit)
                    checkError();
                cairo_svg_surface_restrict_to_version(this.nativePointer, vers);
            }
    }
}
