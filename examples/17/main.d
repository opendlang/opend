import cairo.cairo;
import std.math;

import cairo.example;

void main()
{
    runExample(&sample17);
}
void sample17(Context context)
{
    context.selectFontFace("Sans", FontSlant.CAIRO_FONT_SLANT_NORMAL,
                                   FontWeight.CAIRO_FONT_WEIGHT_BOLD);
    context.setFontSize(90);

    context.moveTo(Point!double(10, 135));
    context.showText("Hello");
    
    context.moveTo(Point!double(70, 165));
    context.textPath("void");
    context.setSourceRGB(0.5, 0.5, 1);
    context.fillPreserve();
    context.setSourceRGB(0, 0, 0);
    context.setLineWidth(2.56);
    context.stroke();
    
    /* draw helping lines */
    context.setSourceRGBA(1, 0.2, 0.2, 0.6);
    context.arc(Point!double(10.0, 135.0), 5.12, 0, 2*PI);
    context.closePath();
    context.arc(Point!double(70.0, 165.0), 5.12, 0, 2*PI);
    context.fill();
}
