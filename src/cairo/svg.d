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
        immutable(cairo_svg_version_t*) vers;
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

            void restrictToVersion(SVGVersion vers)
            {
                scope(exit)
                    checkError();
                cairo_svg_surface_restrict_to_version(this.nativePointer, vers);
            }
    }
}
