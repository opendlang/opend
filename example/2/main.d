import cairo.cairo;
import std.math;

void main()
{
    auto surface = new ImageSurface(Format.CAIRO_FORMAT_ARGB32, 400, 400);
    auto context = Context(surface);
    sample2(context);
    surface.writeToPNG("test.png");
    surface.dispose();
}

void sample2(Context context)
{
    double xc = 128.0;
    double yc = 128.0;
    auto point = Point(128.0, 128.0);
    double radius = 100.0;
    double angle1 = 45.0  * (PI/180.0);  /* angles are specified */
    double angle2 = 180.0 * (PI/180.0);  /* in radians           */
    
    context.setLineWidth(10.0);
    context.arcNegative(point, radius, angle1, angle2);
    context.stroke();
    
    /* draw helping lines */
    context.setSourceRGBA(1, 0.2, 0.2, 0.6);
    context.setLineWidth(6.0);
    
    context.arc(point, 10.0, 0, 2*PI);
    context.fill();
    
    context.arc(point, radius, angle1, angle1);
    context.lineTo(point);
    context.arc(point, radius, angle2, angle2);
    context.lineTo(point);
    context.stroke();
}
