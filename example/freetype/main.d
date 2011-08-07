import std.stdio; //writeln
import std.string; //toStringz

import cairo.cairo;
import cairo.ft;

import derelict.freetype.ft;

/**
 * Execute like this:
 * ./main /usr/share/fonts/truetype/linux-libertine/LinLibertine_Re.ttf
 */
void main(string[] args)
{
    /* Freetype initialization */
    DerelictFT.load();

    FT_Library library;
    auto error = FT_Init_FreeType(&library);
    if(error)
    {
        writeln("Couldn't initialize FreeType");
        return;
    }
    /* Loading a font */
    FT_Face face;
    error = FT_New_Face(library,
                       toStringz(args[1]),
                       0, &face);
    if(error)
    {
        writeln("Couldn't load Font");
        return;
    }
    scope(exit)
        FT_Done_Face(face);

    /* Cairo FreeType integration */
    auto surface = new ImageSurface(Format.CAIRO_FORMAT_ARGB32, 400, 400);
    scope(exit)
        surface.dispose();

    auto context = Context(surface);
    auto cairoFont = new FTFontFace(face, 0);
    scope(exit)
        cairoFont.dispose(); //Must be called before FT_Done_Face

    context.setFontFace(cairoFont);
    context.setSourceRGB(1 ,1 , 1);
    context.rectangle(Rectangle(Point(0,0), 400, 400));
    context.fill();
    context.setSourceRGB(0 ,0 , 1);
    context.setFontSize(60);
    context.moveTo(Point(0, 100));
    context.showText("Hello, FreeType!");
    
    surface.writeToPNG("test.png");
}
