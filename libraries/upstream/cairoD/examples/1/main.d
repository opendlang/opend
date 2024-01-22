import cairo.cairo;
import std.math;

import cairo.example;

void main()
{
    runExample(&sample1);
}

void sample1(Context context)
{
    auto center = Point!double(128, 128);
    double radius = 100.0;
    double angle1 = 45.0  * (PI/180.0);  /* angles are specified */
    double angle2 = 180.0 * (PI/180.0);  /* in radians           */
    
    context.setLineWidth(10);
    context.arc(center, radius, angle1, angle2);
    context.stroke();
    
    /* draw helping lines */
    context.setSourceRGBA(1, 0.2, 0.2, 0.6);
    context.setLineWidth(6);
    
    context.arc(center, 10, 0, 2*PI);
    context.fill();
    
    context.arc(center, radius, angle1, angle1);
    context.lineTo(center);
    context.arc(center, radius, angle2, angle2);
    context.lineTo(center);
    context.stroke();
}
