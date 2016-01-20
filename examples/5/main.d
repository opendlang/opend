import cairo;
import std.math;

import cairo.example;

void main()
{
    runExample(&sample5);
}

void sample5(Context context)
{
    /* a custom shape that is wrapped in a function */
    double x0      = 25.6,   /* parameters like Rectangle */
           y0      = 25.6,
           rect_width  = 204.8,
           rect_height = 204.8,
           radius = 102.4;   /* and an approximate curvature radius */
    
    double x1, y1;
    
    x1=x0+rect_width;
    y1=y0+rect_height;
    if (!rect_width || !rect_height)
        return;
    if (rect_width / 2 < radius)
    {
        if (rect_height / 2 < radius)
        {
            context.moveTo (point(x0, (y0 + y1)/2));
            context.curveTo(point(x0 ,y0), point(x0, y0), point((x0 + x1)/2, y0));
            context.curveTo(point(x1, y0), point(x1, y0), point(x1, (y0 + y1)/2));
            context.curveTo(point(x1, y1), point(x1, y1), point((x1 + x0)/2, y1));
            context.curveTo(point(x0, y1), point(x0, y1), point(x0, (y0 + y1)/2));
        }
        else
        {
            context.moveTo (point(x0, y0 + radius));
            context.curveTo(point(x0 ,y0), point(x0, y0), point((x0 + x1)/2, y0));
            context.curveTo(point(x1, y0), point(x1, y0), point(x1, y0 + radius));
            context.lineTo (point(x1, y1 - radius));
            context.curveTo(point(x1, y1), point(x1, y1), point((x1 + x0)/2, y1));
            context.curveTo(point(x0, y1), point(x0, y1), point(x0, y1- radius));
        }
    }
    else
    {
        if (rect_height / 2 < radius)
        {
            context.moveTo (point(x0, (y0 + y1)/2));
            context.curveTo(point(x0 , y0), point(x0 , y0), point(x0 + radius, y0));
            context.lineTo (point(x1 - radius, y0));
            context.curveTo(point(x1, y0), point(x1, y0), point(x1, (y0 + y1)/2));
            context.curveTo(point(x1, y1), point(x1, y1), point(x1 - radius, y1));
            context.lineTo (point(x0 + radius, y1));
            context.curveTo(point(x0, y1), point(x0, y1), point(x0, (y0 + y1)/2));
        }
        else
        {
            context.moveTo(point(x0, y0 + radius));
            context.curveTo(point(x0 , y0), point(x0 , y0), point(x0 + radius, y0));
            context.lineTo(point(x1 - radius, y0));
            context.curveTo(point(x1, y0), point(x1, y0), point(x1, y0 + radius));
            context.lineTo(point(x1 , y1 - radius));
            context.curveTo(point(x1, y1), point(x1, y1), point(x1 - radius, y1));
            context.lineTo(point(x0 + radius, y1));
            context.curveTo(point(x0, y1), point(x0, y1), point(x0, y1- radius));
        }
    }
    context.closePath();
    
    context.setSourceRGB(0.5, 0.5, 1);
    context.fillPreserve();
    context.setSourceRGBA(0.5, 0, 0, 0.5);
    context.setLineWidth(10.0);
    context.stroke();
}
