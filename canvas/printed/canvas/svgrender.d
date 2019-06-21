/**
SVG renderer.

Copyright: Guillaume Piolat 2018.
License:   $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost License 1.0)
*/
module printed.canvas.svgrender;

import std.string;
import std.file;
import std.math;
import std.base64;

import printed.canvas.irenderer;
import printed.font.fontregistry;
import printed.font.opentype;

class SVGException : Exception
{
    public
    {
        @safe pure nothrow this(string message,
                                string file =__FILE__,
                                size_t line = __LINE__,
                                Throwable next = null)
        {
            super(message, file, line, next);
        }
    }
}

/// Renders 2D commands in a SVG file.
/// For comparisons between PDF and SVG.
class SVGDocument : IRenderingContext2D
{
public:
    this(float pageWidthMm = 210, float pageHeightMm = 297)
    {
        _pageWidthMm = pageWidthMm;
        _pageHeightMm = pageHeightMm;
        beginPage();
    }

    const(ubyte)[] bytes()
    {
        if (!_finished)
            end();
        auto header = cast(const(ubyte)[])( getHeader() );
        auto defs = cast(const(ubyte)[])( getDefinitions() );

        return header ~ defs ~ _bytes;
    }

    override float pageWidth()
    {
        return _pageWidthMm;
    }

    override float pageHeight()
    {
        return _pageHeightMm;
    }

    override void save()
    {
        _numberOfNestedGroups += 1;
        output("<g>");
    }

    /// Restore the graphical contect: transformation matrices.
    override void restore()
    {        
        foreach(i; 0.._numberOfNestedGroups)
        {
            output("</g>");
        }
        _numberOfNestedGroups = 0;
    }

    /// Start a new page, finish the previous one.
    override void newPage()
    {
        endPage();
        _numberOfPage += 1;
        beginPage();        
    }

    override void fillStyle(Brush brush)
    {
        _currentFill = brush.toSVGColor();
    }

    override void strokeStyle(Brush brush)
    {
        _currentStroke = brush.toSVGColor();
    }

    override void fillRect(float x, float y, float width, float height)
    {
        output(format(`<rect x="%s" y="%s" width="%s" height="%s" fill="%s"/>`, x, y, width, height, _currentFill));
    }

    override void strokeRect(float x, float y, float width, float height)
    {
        output(format(`<rect x="%s" y="%s" width="%s" height="%s" stroke="%s" fill="none"/>`, x, y, width, height, _currentStroke));
    }

    override TextMetrics measureText(string text)
    {
        string svgFamilyName;
        OpenTypeFont font;
        getFont(_fontFace, _fontWeight, _fontStyle, svgFamilyName, font);    
        OpenTypeTextMetrics otMetrics = font.measureText(text);
        TextMetrics metrics;
        metrics.width = _fontSize * otMetrics.horzAdvance * font.invUPM(); // convert to millimeters
        return metrics;
    }

    override void fillText(string text, float x, float y)
    {
        string svgFamilyName;
        OpenTypeFont font;
        getFont(_fontFace, _fontWeight, _fontStyle, svgFamilyName, font);    

        // We need a baseline offset in millimeters
        float textBaselineInGlyphUnits = font.getBaselineOffset(cast(FontBaseline)_textBaseline);
        float textBaselineInMm = _fontSize * textBaselineInGlyphUnits * font.invUPM();

        // Get width aka horizontal advance
        // TODO: instead of relying on the SVG viewer, compute the right x here.
        version(manualHorzAlign)
        {
            OpenTypeTextMetrics otMetrics = font.measureText(text);
            float horzAdvanceMm = _fontSize * otMetrics.horzAdvance * font.invUPM();
        }

        string textAnchor="start";
        final switch(_textAlign) with (TextAlign)
        {
            case start: // TODO bidir text
            case left:
                textAnchor="start";
                break;
            case end:
            case right:
                textAnchor="end";
                break;
            case center:
                textAnchor="middle";
        }

        output(format(`<text x="%f" y="%f" font-family="%s" font-size="%s" fill="%s" text-anchor="%s">%s</text>`, 
                      x, y + textBaselineInMm, svgFamilyName, _fontSize, _currentFill, textAnchor, text)); 
        // TODO escape XML sequences in text
    }

    override void beginPath(float x, float y)
    {
        _currentPath = format("M%s %s", x, y);
    }

    override void lineWidth(float width)
    {
        _currentLineWidth = width;
    }

    override void lineTo(float dx, float dy)
    {
        _currentPath ~= format(" L%s %s", dx, dy);
    }

    override void fill()
    {
        output(format(`<path d="%s" fill="%s"/>`, _currentPath, _currentFill));
    }

    override void stroke()
    {
        output(format(`<path d="%s" stroke="%s" stroke-width="%s"/>`, _currentPath, _currentStroke, _currentLineWidth));
    }

    override void fillAndStroke()
    {
        output(format(`<path d="%s" fill="%s" stroke="%s" stroke-width="%s"/>`, _currentPath, _currentFill, _currentStroke, _currentLineWidth));
    }

    override void closePath()
    {
        _currentPath ~= " Z";
    }

    override void fontFace(string fontFace)
    {
        _fontFace = fontFace;
    }

    override void fontWeight(FontWeight fontWeight)
    {
        _fontWeight = fontWeight;
    }

    override void fontStyle(FontStyle fontStyle)
    {
        _fontStyle = fontStyle;
    }

    override void fontSize(float size)
    {
        _fontSize = convertPointsToMillimeters(size);
    }

    override void textAlign(TextAlign alignment)
    {
        _textAlign = alignment;
    }

    override void textBaseline(TextBaseline baseline)
    {
        _textBaseline = baseline;
    }

    override void scale(float x, float y)
    {
        output(format(`<g transform="scale(%s %s)">`, x, y));
        _numberOfNestedGroups++;
    }

    override void translate(float dx, float dy)
    {
        output(format(`<g transform="translate(%s %s)">`, dx, dy));
        _numberOfNestedGroups++;
    }

    override void rotate(float angle)
    {
        float angleInDegrees = (angle * 180) / PI;
        output(format(`<g transform="rotate(%s)">`, angleInDegrees));
        _numberOfNestedGroups++;
    }

    override void drawImage(Image image, float x, float y)
    {
        float widthMm = (1000.0f * image.width) / image.pixelsPerMeterX();
        float heightMm = (1000.0f * image.height) / image.pixelsPerMeterY();
        output(format(`<image xlink:href="%s" x="%s" y="%s" width="%s" height="%s" preserveAspectRatio="none"/>`, 
                      image.toDataURI(), x, y, widthMm, heightMm));
    }

protected:
    string getXMLHeader()
    {
        return `<?xml version="1.0" encoding="UTF-8" standalone="no"?>`;
    }

private:

    bool _finished = false;
    ubyte[] _bytes;

    string _currentFill = "#000";
    string _currentStroke = "#000";
    float _currentLineWidth = 1;
    int _numberOfNestedGroups = 0;
    int _numberOfPage = 1;
    float _pageWidthMm;
    float _pageHeightMm;

    string _currentPath;

    string _fontFace = "Helvetica";    
    FontWeight _fontWeight = FontWeight.normal;
    FontStyle _fontStyle = FontStyle.normal;
    float _fontSize = convertPointsToMillimeters(11.0f);
    TextAlign _textAlign = TextAlign.start;
    TextBaseline _textBaseline = TextBaseline.alphabetic;

    void output(ubyte b)
    {
        _bytes ~= b;
    }

    void outputBytes(const(ubyte)[] b)
    {
        _bytes ~= b;
    }

    void output(string s)
    {
        _bytes ~= s.representation;
    }

    void endPage()
    {
        restore();
    }

    void beginPage()
    {        
        output(format(`<g transform="translate(0,%s)">`, _pageHeightMm * (_numberOfPage-1)));
        _numberOfNestedGroups = 1;
    }

    void end()
    {
        if (_finished)
            throw new SVGException("SVGDocument already finalized.");

        _finished = true;

        endPage();
        output(`</svg>`);
    }    

    string getHeader()
    {
        float heightInMm = _pageHeightMm * _numberOfPage;
        return getXMLHeader()
            ~ format(`<svg xmlns="http://www.w3.org/2000/svg" xmlns:svg="http://www.w3.org/2000/svg" xmlns:xlink= "http://www.w3.org/1999/xlink"`
                     ~` width="%smm" height="%smm" viewBox="0 0 %s %s" version="1.1">`,
                     _pageWidthMm, heightInMm, _pageWidthMm, heightInMm);
    }

    static struct FontSVGInfo
    {
        string svgFamilyName; // name used as family name in this SVG, doesn't have to be the real one
    }
    
    /// Associates with each open font information about
    /// the SVG embedding of that font.
    FontSVGInfo[OpenTypeFont] _fontSVGInfos;

    // Generates the <defs> section.
    string getDefinitions()
    {
        string defs;
        defs ~= 
        `<defs>` ~
            `<style type="text/css">` ~
                "<![CDATA[\n";

                // Embed this font into the SVG as a base64 data URI
                foreach(pair; _fontSVGInfos.byKeyValue())
                {
                    OpenTypeFont font = pair.key;
                    FontSVGInfo info = pair.value;

                    const(ubyte)[] fontContent = font.fileData;
                    const(char)[] base64font = Base64.encode(fontContent);
                    defs ~= 
                        `@font-face` ~
                        `{` ~
                            `font-family: ` ~ info.svgFamilyName ~ `;` ~
                            `src: url('data:application/x-font-ttf;charset=utf-8;base64,` ~ base64font ~ `');` ~
                        "}\n";
                }

        defs ~= `]]>`~
            `</style>` ~
        `</defs>`;
        return defs;
    }

    // Ensure this font exist, generate a /name and give it back
    // Only PDF builtin fonts supported.
    // TODO: bold and oblique support
    void getFont(string fontFamily,
                 FontWeight weight,
                 FontStyle style,
                 out string svgFamilyName,
                 out OpenTypeFont outFont)
    {
        auto otWeight = cast(OpenTypeFontWeight)weight;
        auto otStyle = cast(OpenTypeFontStyle)style;
        OpenTypeFont font = theFontRegistry().findBestMatchingFont(fontFamily, otWeight, otStyle);
        outFont = font;

        // is this font known already?
        FontSVGInfo* info = font in _fontSVGInfos;

        // lazily create the font object in the PDF
        if (info is null)
        {
            // Give a family name for this font
            FontSVGInfo f;
            f.svgFamilyName = format("f%d", cast(int)(_fontSVGInfos.length));
            _fontSVGInfos[font] = f;
            info = font in _fontSVGInfos;
            assert(info !is null);
        }

        svgFamilyName = info.svgFamilyName;
    }
}
