import std.stdio; //writeln
import std.string; //toStringz

import cairo;
import derelict.freetype.ft;
import cairo.example;

static assert(CAIRO_HAS_FT_FONT);

FTFontFace cairoFont;

/**
 * Execute like this:
 * ./example /usr/share/fonts/truetype/linux-libertine/LinLibertine_Re.ttf
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

    cairoFont = new FTFontFace(face, 0);
    scope(exit)
        cairoFont.dispose(); //Must be called before FT_Done_Face
    
    runExample(&draw);
}

void draw(Context context)
{
    context.setFontFace(cairoFont);
    context.setSourceRGB(1 ,1 , 1);
    context.rectangle(Rectangle!double(Point!double(0,0), 400, 400));
    context.fill();
    context.setSourceRGB(0 ,0 , 1);
    context.setFontSize(60);
    context.moveTo(Point!double(0, 100));
    context.showText("Hello, FreeType!");
}
