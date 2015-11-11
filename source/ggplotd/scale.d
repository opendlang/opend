module ggplotd.scale;

import cairo = cairo.cairo;
import ggplotd.bounds : Bounds, width, height;

///
auto scale(double pixelWidth = 400, double pixelHeight = 400)
{
    return (cairo.Context context, Bounds bounds) {
        context.translate(0, pixelHeight);
        context.scale(pixelWidth / bounds.width, -pixelHeight / bounds.height);
        context.translate(-bounds.min_x, -bounds.min_y);
        return context;
    };
}
