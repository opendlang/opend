module cairo.ps;

import std.string;
import std.conv;

import cairo.cairo;
import cairo.c.cairo;

version(CAIRO_HAS_PS_SURFACE)
{
    import cairo.c.ps;
    
    public alias cairo_ps_level_t PSLevel;
    PSLevel[] getPSLevels()
    {
        int num;
        const(cairo_ps_level_t*) levels;
        cairo_ps_get_levels(&levels, &num);
        PSLevel[] dlevels;
        for(int i = 0; i < num; i++)
        {
            dlevels ~= levels[i];
        }
        return dlevels;
    }

    string PSLevelToString(PSLevel level)
    {
        return to!string(cairo_ps_level_to_string(level));
    }

    public class PSSurface : Surface
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
                super(cairo_ps_surface_create(toStringz(fileName), width, height));
            }

            static PSSurface castFrom(Surface other)
            {
                if(!other.nativePointer)
                {
                    throw new CairoException(cairo_status_t.CAIRO_STATUS_NULL_POINTER);
                }
                auto type = cairo_surface_get_type(other.nativePointer);
                throwError(cairo_surface_status(other.nativePointer));
                if(type == cairo_surface_type_t.CAIRO_SURFACE_TYPE_PS)
                    return new PSSurface(other.nativePointer);
                else
                    return null;
            }

            void restrictToLevel(PSLevel level)
            {
                scope(exit)
                    checkError();
                cairo_ps_surface_restrict_to_level(this.nativePointer, level);
            }

            void setEPS(bool eps)
            {
                scope(exit)
                    checkError();
                cairo_ps_surface_set_eps(this.nativePointer, cast(int)eps);
            }

            bool getEPS(bool eps)
            {
                scope(exit)
                    checkError();
                return cairo_ps_surface_get_eps(this.nativePointer)  ? true : false;
            }

            void setSize(double width, double height)
            {
                scope(exit)
                    checkError();
                return cairo_ps_surface_set_size(this.nativePointer, width, height);
            }

            void dscBeginSetup()
            {
                scope(exit)
                    checkError();
                cairo_ps_surface_dsc_begin_setup(this.nativePointer);
            }

            void dscBeginPageSetup()
            {
                scope(exit)
                    checkError();
                cairo_ps_surface_dsc_begin_page_setup(this.nativePointer);
            }

            void dscComment(string comment)
            {
                scope(exit)
                    checkError();
                cairo_ps_surface_dsc_comment(this.nativePointer, toStringz(comment));
            }
    }
}
