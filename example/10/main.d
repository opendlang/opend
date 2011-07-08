import cairo.cairo;
import cairo.svg;
import std.math;

void main()
{
    auto surface = new SVGSurface("test.svg", 400, 400);
    auto context = Context(surface);
    sample6(context);
    surface.dispose(); //Not strictly needed, GC can take care of that
    //uncomment the above line to test that.
    //It's recommended to call dispose manually, though.
}

void sample6(Context context)
{
    Gradient pat = new LinearGradient(Point(0, 0), Point(0, 256));
    pat.addColorStopRGBA(1, RGBA(0, 0, 0, 1));
    pat.addColorStopRGBA(0, RGBA(1, 1, 1, 1));
    
    context.rectangle(Rectangle(Point(0, 0), 256, 256));
    context.setSource(pat);
    context.fill();
    pat.dispose();
    
    pat = new RadialGradient(Point(115.2, 102.4), 25.6,
                             Point(102.4, 102.4), 128.0);
    pat.addColorStopRGBA(0, RGBA(1, 1, 1, 1));
    pat.addColorStopRGBA(1, RGBA(0, 0, 0, 1));
    
    context.setSource(pat);
    context.arc(Point(128, 128), 76.8, 0, 2*PI);
    context.fill();
    pat.dispose();
}
