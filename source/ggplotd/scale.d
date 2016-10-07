module ggplotd.scale;

import cairo = cairo.cairo;
import ggplotd.bounds : Bounds, width, height;

version (unittest)
{
    import dunit.toolkit;
}

alias ScaleType = 
    cairo.Context delegate(cairo.Context context, in Bounds bounds,
    double width, double height);

/// Scale context by plot boundaries
ScaleType scale()
{
    return (cairo.Context context, in Bounds bounds, 
        double pixelWidth, double pixelHeight) {
        context.translate(0, pixelHeight);
        context.scale(pixelWidth / bounds.width, -pixelHeight / bounds.height);
        context.translate(-bounds.min_x, -bounds.min_y);
        return context;
    };
}

struct ScaleFunction(string type = "")
{
    string field = type;

    double delegate(double) scale;
}

unittest
{
    auto sf = ScaleFunction!"bla"();
    assertEqual(sf.field, "bla");
}

auto scale(string field = "")(string type)
{
    ScaleFunction!field sf;
    import std.math : log;
    if (type == "log10") {
        sf.scale = (v) { return log(v)/log(10.0); };
    } else if (type == "log") {
        sf.scale = (v) { return log(v); };
    } else if (type == "polar") {
        assert(0, "Polar not implemented yet");
    } else {
        // dummy
        sf.scale = (v) { return v; };
    }
    return sf;
}

unittest
{
    auto sf = scale!"bla"("log10");
    assertEqual(sf.scale(10.0), 1);
}
