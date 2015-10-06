module ggplotd.scale;

import cairo = cairo.cairo;
import ggplotd.bounds : Bounds, width, height;

/+
cairo.Context plotContextFromSurface(cairo.Surface surface, Bounds plotBounds,
    Bounds marginBounds = Bounds(100, 400, 100, 400))
{
    // Create a sub surface. Makes sure everything is plotted within plot surface
    auto plotSurface = cairo.Surface.createForRectangle(surface, cairo.Rectangle!double(marginBounds
        .min_x, 0,  // No support for margin at top yet. Would need to know the surface dimensions
        marginBounds.width, marginBounds.height));
    auto context = cairo.Context(plotSurface);
    context.translate(0, marginBounds.height);
    context.scale(marginBounds.width / plotBounds.width, -marginBounds.height
        / plotBounds.height);
    context.translate(-plotBounds.min_x, -plotBounds.min_y);
    context.setFontSize(14.0);
    return context;
}
+/

auto scale( double pixelWidth = 400, double pixelHeight = 400 )
{
    return (cairo.Context context, Bounds bounds) {
        context.translate(0, pixelHeight);
        context.scale( pixelWidth/bounds.width, 
                -pixelHeight/bounds.height);
        context.translate(-bounds.min_x, -bounds.min_y);
        return context;
    };
}
