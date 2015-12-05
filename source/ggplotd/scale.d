module ggplotd.scale;

import cairo = cairo.cairo;
import ggplotd.bounds : Bounds, width, height;

alias ScaleType = 
    cairo.Context delegate(cairo.Context context, Bounds bounds,
    double width, double height);

///
ScaleType scale()
{
    return (cairo.Context context, Bounds bounds, 
        double pixelWidth, double pixelHeight) {
        context.translate(0, pixelHeight);
        context.scale(pixelWidth / bounds.width, -pixelHeight / bounds.height);
        context.translate(-bounds.min_x, -bounds.min_y);
        return context;
    };
}
