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

struct ScaleFunction
{
    string field;

    this(string fld) {
        field = fld;
    }

    double delegate(double) scale;
}

unittest
{
    auto sf = ScaleFunction("bla");
    assertEqual(sf.field, "bla");
}

auto scale(string field = "")(string type)
{
    auto sf = ScaleFunction(field);
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

///
void applyScaleFunction(F, X, Y, Col, Size)(in F func,
    ref X x, ref Y y, ref Col col, ref Size size)
{
    if (func.field == "x")
        x.scaleFunction = func.scale;
    else if (func.field == "y")
        y.scaleFunction = func.scale;
    else if (func.field == "colour")
        col.scaleFunction = func.scale;
    else if (func.field == "size")
        size.scaleFunction = func.scale;
}

auto applyScale(B, XF, XStore, YF, YStore)(ref B bounds,
    XF xf, XStore xStore, YF yf, YStore yStore)
{
    import ggplotd.algorithm : safeMax, safeMin;
    import std.range : iota;
    import std.algorithm : each;
    auto xmin = xStore.min();
    auto xmax = xStore.max();
    auto ymin = yStore.min();
    auto ymax = yStore.max();
    if (!xf.scaleFunction.isNull)
    {
        // xmax won't be included in the iota so use that to initialize
        xmax = xf.scaleFunction.get()(xmax);
        xmin = xf.scaleFunction.get()(xmax);
        foreach(x; iota(xmin, xmax, (xmax-xmin)/100.0))
        {
            xmin = safeMin(xmin, xf.scaleFunction.get()(x));
            xmax = safeMax(xmax, xf.scaleFunction.get()(x));
        }
    }
    if (!yf.scaleFunction.isNull)
    {
        // ymax won't be included in the iota so use that to initialize
        ymax = yf.scaleFunction.get()(ymax);
        ymin = yf.scaleFunction.get()(ymax);
        foreach(y; iota(ymin, ymax, (ymax-ymin)/100.0))
        {
            ymin = safeMin(ymin, yf.scaleFunction.get()(y));
            ymax = safeMax(ymax, yf.scaleFunction.get()(y));
        }
    }

    bounds.adapt(xmin, ymin);
    bounds.adapt(xmax, ymax);
    return bounds;
}
