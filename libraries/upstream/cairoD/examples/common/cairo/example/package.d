module cairo.example;

import cairo;
import std.getopt, std.stdio, core.runtime;
version(GTK)
    import cairo.examples.gtk;


alias DrawFunction = void function(Context ctx);

enum Output
{
    _auto,
    gtk,
    png
}

void runExample(DrawFunction draw)
{
    auto args = Runtime.args;

    Output output = Output._auto;
    getopt(
        args,
        "output",  &output);

    final switch(output)
    {
        case Output._auto:
            version(GTK)
                gtkRunExample(draw);
            else static if(CAIRO_HAS_PNG_FUNCTIONS)
                pngRunExample(draw);
            else
                writeln("No useable backend compiled in");
            break;
        case Output.gtk:
            version(GTK)
                gtkRunExample(draw);
            else
                writeln("GTK support not compiled in");
            break;
        case Output.png:
            static if(CAIRO_HAS_PNG_FUNCTIONS)
                pngRunExample(draw);
            else
                writeln("PNG support not compiled in");
            break;
    }
}

static if(CAIRO_HAS_PNG_FUNCTIONS)
{
    void pngRunExample(DrawFunction draw)
    {
        auto surface = new ImageSurface(Format.CAIRO_FORMAT_ARGB32, 400, 400);
        auto context = Context(surface);
        draw(context);
        surface.writeToPNG("example.png");
        surface.dispose();
        writeln("Wrote result to example.png");
    }
}
