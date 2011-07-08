import cairo.cairo;
import std.math;

void main()
{
    auto surface = new ImageSurface(Format.CAIRO_FORMAT_ARGB32, 400, 400);
    auto context = Context(surface);
    sample4(context);
    surface.writeToPNG("test.png");
    surface.dispose();
}

void sample4(Context context)
{
    int w, h;
    
    context.arc(Point(128.0, 128.0), 76.8, 0, 2*PI);
    context.clip();
    context.newPath(); /* path not consumed by clip()*/
    
    auto image = ImageSurface.fromPng("data/romedalen.png");
    w = image.getWidth();
    h = image.getHeight();
    
    context.scale(256.0/w, 256.0/h);
    
    context.setSourceSurface(image, 0, 0);
    context.paint();
    
    image.dispose();
}
