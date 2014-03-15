import cairo;
import std.math;

void main()
{
    auto surface = new ImageSurface(Format.CAIRO_FORMAT_ARGB32, 400, 400);
    auto context = Context(surface);
    sample6(context);
    surface.writeToPNG("test.png");
    surface.dispose();
}

void sample6(Context context)
{
    Gradient pat = new LinearGradient(Point!double(0, 0), Point!double(0, 256));
    pat.addColorStopRGBA(1, RGBA(0, 0, 0, 1));
    pat.addColorStopRGBA(0, RGBA(1, 1, 1, 1));
    
    context.rectangle(Rectangle!double(Point!double(0, 0), 256.0, 256.0));
    context.setSource(pat);
    context.fill();
    pat.dispose();
    
    pat = new RadialGradient(Point!double(115.2, 102.4), 25.6,
                             Point!double(102.4, 102.4), 128.0);
    pat.addColorStopRGBA(0, RGBA(1, 1, 1, 1));
    pat.addColorStopRGBA(1, RGBA(0, 0, 0, 1));
    
    context.setSource(pat);
    context.arc(Point!double(128, 128), 76.8, 0, 2*PI);
    context.fill();
    pat.dispose();
}
