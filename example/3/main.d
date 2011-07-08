import cairo.cairo;
import std.math;

void main()
{
    auto surface = new ImageSurface(Format.CAIRO_FORMAT_ARGB32, 400, 400);
    auto context = Context(surface);
    sample3(context);
    surface.writeToPNG("test.png");
    surface.dispose();
}

void sample3(Context context)
{
    context.arc(Point(128.0, 128.0), 76.8, 0, 2 * PI);
    context.clip();

    context.newPath();  /* current path is not
                        consumed by cairo_clip() */
    context.rectangle(Rectangle(Point(0, 0), 256, 256));
    context.fill();
    context.setSourceRBG(0, 1, 0);
    context.moveTo(Point(0, 0));
    context.lineTo(Point(256, 256));
    context.moveTo(Point(256, 0));
    context.lineTo(Point(0, 256));
    context.setLineWidth(10.0);
    context.stroke();
}
