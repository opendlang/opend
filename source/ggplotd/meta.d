module ggplotd.meta;

import std.traits;

/// 
static if (__traits(hasMember, std.meta, "ApplyLeft"))
{
    import std.meta : ApplyLeft;
    alias ApplyLeft = std.meta.ApplyLeft;
} else { // Compatibility with older versions
    template ApplyLeft(alias Template, args...)
    {
        static if (args.length)
        {
            template ApplyLeft(right...)
            {
                static if (is(typeof(Template!(args, right))))
                    enum ApplyLeft = Template!(args, right); // values
                else
                    alias ApplyLeft = Template!(args, right); // symbols
            }
        }
        else
            alias ApplyLeft = Template;
    }
}
