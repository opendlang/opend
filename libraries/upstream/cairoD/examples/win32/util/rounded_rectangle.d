module util.rounded_rectangle;

/+
 +           Copyright Andrej Mitrovic 2011.
 +  Distributed under the Boost Software License, Version 1.0.
 +     (See accompanying file LICENSE_1_0.txt or copy at
 +           http://www.boost.org/LICENSE_1_0.txt)
 +/

import cairo.cairo;

import std.math;
import std.algorithm;
import std.stdio;

enum RoundMethod
{
    A,
    B,
    C,
    D,
}

/+ @BUG@ 6574 - Erroneous recursive call: http://d.puremagic.com/issues/show_bug.cgi?id=6574
void roundedRectangle(RoundMethod roundMethod = RoundMethod.A)(Context ctx, Rectangle!double rect, double radius1 = 5, double radius2 = 5)
{
    with (rect)
    {
        roundedRectangle!(roundMethod)(ctx, point.x, point.y, width, height, radius1, radius2);
    }
}

void roundedRectangle(RoundMethod roundMethod = RoundMethod.A)(Context ctx, double x, double y, double width, double height, double radius1 = 5, double radius2 = 5)
{
    roundedRectangle!(roundMethod)(ctx, x, y, width, height, radius1, radius2);
}
+/

// convenience
void roundedRectangle(RoundMethod roundMethod)(Context ctx, Rectangle!double rect, double radius1 = 5, double radius2 = 5)
{
    with (rect)
    {
        roundedRectangle!(roundMethod)(ctx, point.x, point.y, width, height, radius1, radius2);
    }
}

void roundedRectangle(RoundMethod roundMethod : RoundMethod.A)(Context ctx, double x, double y, double width, double height, double radiusX = 5, double radiusY = 5)
{
    enum ArcToBezier = 0.55228475;

    if (radiusX > width - radiusX)
        radiusX = width / 2;

    if (radiusY > height - radiusY)
        radiusY = height / 2;

    // approximate the arc using a bezier curve
    auto c1 = ArcToBezier * radiusX;
    auto c2 = ArcToBezier * radiusY;

    ctx.newPath();
    ctx.moveTo(x + radiusX, y);
    ctx.relLineTo(width - 2 * radiusX, 0.0);
    ctx.relCurveTo(c1, 0.0, radiusX, c2, radiusX, radiusY);
    ctx.relLineTo(0, height - 2 * radiusY);
    ctx.relCurveTo(0.0, c2, c1 - radiusX, radiusY, -radiusX, radiusY);
    ctx.relLineTo(-width + 2 * radiusX, 0);
    ctx.relCurveTo(-c1, 0, -radiusX, -c2, -radiusX, -radiusY);
    ctx.relLineTo(0, -height + 2 * radiusY);
    ctx.relCurveTo(0.0, -c2, radiusX - c1, -radiusY, radiusX, -radiusY);
    ctx.closePath();
}

void roundedRectangle(RoundMethod roundMethod:RoundMethod.B)(Context ctx, double x, double y, double width, double height, double radius = 5, double unused = 0)
{
    // a custom shape, that could be wrapped in a function
    // radius = 5; and an approximate curvature radius
    immutable x0 = x + radius / 2.0;  // parameters like cairo_rectangle
    immutable y0 = y + radius / 2.0;
    immutable rectWidth  = width - radius;
    immutable rectHeight = height - radius;

    ctx.save();
    ctx.newPath();
    // ctx.set_line_width (0.04)
    // self.snippet_normalize (cr, width, height)

    immutable x1 = x0 + rectWidth;
    immutable y1 = y0 + rectHeight;

    // if (!rectWidth || !rectHeight)
    //     return

    if (rectWidth / 2 < radius)
    {
        if (rectHeight / 2 < radius)
        {
            ctx.moveTo(x0, (y0 + y1) / 2);
            ctx.curveTo(x0, y0, x0, y0, (x0 + x1) / 2, y0);
            ctx.curveTo(x1, y0, x1, y0, x1, (y0 + y1) / 2);
            ctx.curveTo(x1, y1, x1, y1, (x1 + x0) / 2, y1);
            ctx.curveTo(x0, y1, x0, y1, x0, (y0 + y1) / 2);
        }
        else
        {
            ctx.moveTo(x0, y0 + radius);
            ctx.curveTo(x0, y0, x0, y0, (x0 + x1) / 2, y0);
            ctx.curveTo(x1, y0, x1, y0, x1, y0 + radius);
            ctx.lineTo(x1, y1 - radius);
            ctx.curveTo(x1, y1, x1, y1, (x1 + x0) / 2, y1);
            ctx.curveTo(x0, y1, x0, y1, x0, y1 - radius);
        }
    }

    else
    {
        if (rectHeight / 2 < radius)
        {
            ctx.moveTo(x0, (y0 + y1) / 2);
            ctx.curveTo(x0, y0, x0, y0, x0 + radius, y0);
            ctx.lineTo(x1 - radius, y0);
            ctx.curveTo(x1, y0, x1, y0, x1, (y0 + y1) / 2);
            ctx.curveTo(x1, y1, x1, y1, x1 - radius, y1);
            ctx.lineTo(x0 + radius, y1);
            ctx.curveTo(x0, y1, x0, y1, x0, (y0 + y1) / 2);
        }
        else
        {
            ctx.moveTo(x0, y0 + radius);
            ctx.curveTo(x0, y0, x0, y0, x0 + radius, y0);
            ctx.lineTo(x1 - radius, y0);
            ctx.curveTo(x1, y0, x1, y0, x1, y0 + radius);
            ctx.lineTo(x1, y1 - radius);
            ctx.curveTo(x1, y1, x1, y1, x1 - radius, y1);
            ctx.lineTo(x0 + radius, y1);
            ctx.curveTo(x0, y1, x0, y1, x0, y1 - radius);
        }
    }

    ctx.closePath();
    ctx.restore();
}

void roundedRectangle(RoundMethod roundMethod:RoundMethod.C)(Context ctx, double x, double y, double width, double height, double radius = 10, double unused = 0)
{
    immutable x1 = x + width;
    immutable y1 = y + height;

    ctx.save();
    ctx.moveTo(x + radius, y);                    // Move to A
    ctx.lineTo(x1 - radius, y);                   // Straight line to B
    ctx.curveTo(x1, y, x1, y, x1, y + radius);    // Curve to C, Control points are both at Q
    ctx.lineTo(x1, y1 - radius);                  // Move to D
    ctx.curveTo(x1, y1, x1, y1, x1 - radius, y1); // Curve to E
    ctx.lineTo(x + radius, y1);                   // Line to F
    ctx.curveTo(x, y1, x, y1, x, y1 - radius);    // Curve to G
    ctx.lineTo(x, y + radius);                    // Line to H
    ctx.curveTo(x, y, x, y, x + radius, y);       // Curve to A
    ctx.restore();
}

void roundedRectangle(RoundMethod roundMethod:RoundMethod.D)(Context ctx, double x, double y, double width, double height, double radius = 10, double unused = 0)
{
    immutable x1 = x + width;
    immutable y1 = y + height;

    ctx.save();
    ctx.newPath();
    ctx.arc(x + radius, y + radius, radius, 2.0 * (PI / 2.0), 3.0 * (PI / 2.0));
    ctx.arc(x1 - radius, y + radius, radius, 3.0 * (PI / 2.0), 4.0 * (PI / 2.0));
    ctx.arc(x1 - radius, y1 - radius, radius, 0 * (PI / 2.0), 1.0 * (PI / 2.0));
    ctx.arc(x + radius, y1 - radius, radius, 1.0 * (PI / 2.0), 2.0 * (PI / 2.0));
    ctx.closePath();
    ctx.restore();
}

RGB brightness(RGB rgb, double amount)
{
    with (rgb)
    {
        if (red > 0)
            red = max(0, min(1.0, red + amount));

        if (green > 0)
            green = max(0, min(1.0, green + amount));

        if (blue > 0)
            blue  = max(0, min(1.0, blue  + amount));
    }

    return rgb;
}
