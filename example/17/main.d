import cairo.cairo;
import std.math;

void main()
{
    auto surface = new ImageSurface(Format.CAIRO_FORMAT_ARGB32, 400, 400);

    auto context = Context(surface);
    sample17(context);
    surface.writeToPNG("test.png");
    surface.dispose();
}

void sample17(Context context)
{
    context.selectFontFace("Sans", FontSlant.CAIRO_FONT_SLANT_NORMAL,
                                   FontWeight.CAIRO_FONT_WEIGHT_BOLD);
    context.setFontSize(90);

    context.moveTo(Point(10, 135));
    context.showText("Hello");
    
    context.moveTo(Point(70, 165));
    context.textPath("void");
    context.setSourceRGB(0.5, 0.5, 1);
    context.fillPreserve();
    context.setSourceRGB(0, 0, 0);
    context.setLineWidth(2.56);
    context.stroke();
    
    /* draw helping lines */
    context.setSourceRGBA(1, 0.2, 0.2, 0.6);
    context.arc(Point(10.0, 135.0), 5.12, 0, 2*PI);
    context.closePath();
    context.arc(Point(70.0, 165.0), 5.12, 0, 2*PI);
    context.fill();
}
