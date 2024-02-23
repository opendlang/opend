import cairo;
import std.math;

import cairo.example;

void main()
{
    runExample(&sample3);
}

void sample3(Context context)
{
    context.arc(point(128.0, 128.0), 76.8, 0, 2 * PI);
    context.clip();

    context.newPath();  /* current path is not
                        consumed by cairo_clip() */
    context.rectangle(Rectangle!double(Point!double(0, 0), 256, 256));
    context.fill();
    context.setSourceRGB(0.0, 1.0, 0.0);
    context.moveTo(point(0.0, 0.0));
    context.lineTo(point(256.0, 256.0));
    context.moveTo(point(256.0, 0.0));
    context.lineTo(point(0.0, 256.0));
    context.setLineWidth(10.0);
    context.stroke();
}
