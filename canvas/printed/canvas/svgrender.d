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
import printed.canvas.internals;

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
    this(float pageWidthMm = 210, float pageHeightMm = 297, RenderOptions options = defaultRenderOptions)
    {
        _pageWidthMm = pageWidthMm;
        _pageHeightMm = pageHeightMm;
        _options = options;

        _stateStack = [ State(0) ];
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
        _stateStack ~= State(currentOpenedNestedGroups() + 1);
        output("<g>");
    }

    /// Restore the graphical contect: transformation matrices.
    override void restore()
    {
        // if you crash here => too much restore() without save()
        assert(_stateStack.length > 1);

        int nestedGroupsBefore = currentOpenedNestedGroups();
        _stateStack = _stateStack[0..$-1]; // pop
        int nestedGroupsAfter = currentOpenedNestedGroups();

        for (int n = nestedGroupsBefore; n > nestedGroupsAfter; --n)
        {
            output("</g>");
        }
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

    override void fillStyle(const(char)[] color)
    {
        fillStyle(brush(color));
    }

    override void strokeStyle(Brush brush)
    {
        _currentStroke = brush.toSVGColor();
    }

    override void strokeStyle(const(char)[] color)
    {
        strokeStyle(brush(color));
    }

    override void setLineDash(float[] segments = [])
    {
        if (isValidLineDashPattern(segments))
            _dashSegments = normalizeLineDashPattern(segments);
    }

    override float[] getLineDash()
    {
        return _dashSegments.dup;
    }

    override void lineDashOffset(float offset)
    {
        _dashOffset = offset;
    }

    override float lineDashOffset()
    {
        return _dashOffset;
    }

    override void fillRect(float x, float y, float width, float height)
    {
        output(format(`<rect x="%s" y="%s" width="%s" height="%s" fill="%s"/>`,
                      convertFloatToText(x), convertFloatToText(y), convertFloatToText(width), convertFloatToText(height), _currentFill));
    }

    override void strokeRect(float x, float y, float width, float height)
    {
        output(format(`<rect x="%s" y="%s" width="%s" height="%s" stroke="%s" stroke-width="%s" stroke-dasharray="%-(%f %)" stroke-dashoffset="%f" fill="none"/>`,
                      convertFloatToText(x), convertFloatToText(y), convertFloatToText(width), convertFloatToText(height), 
                      _currentStroke, convertFloatToText(_currentLineWidth), _dashSegments, _dashOffset));
    }

    override TextMetrics measureText(const(char)[] text)
    {
        string svgFamilyName;
        OpenTypeFont font;
        getFont(_fontFace, _fontWeight, _fontStyle, svgFamilyName, font);
        OpenTypeTextMetrics otMetrics = font.measureText(text);
        TextMetrics metrics;
        metrics.width = _fontSize * otMetrics.horzAdvance * font.invUPM(); // convert to millimeters
        metrics.lineGap = _fontSize * font.lineGap() * font.invUPM();
        return metrics;
    }

    override void fillText(const(char)[] text, float x, float y)
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

        output(format(`<text x="%s" y="%s" font-family="%s" font-size="%s" fill="%s" text-anchor="%s">%s</text>`,
                      convertFloatToText(x), convertFloatToText(y + textBaselineInMm), svgFamilyName, convertFloatToText(_fontSize), _currentFill, textAnchor, text));
        // TODO escape XML sequences in text
    }

    override void beginPath(float x, float y)
    {
        _currentPath = format("M%s %s", convertFloatToText(x), convertFloatToText(y));
    }

    override void lineWidth(float width)
    {
        _currentLineWidth = width;
    }

    override void lineTo(float dx, float dy)
    {
        _currentPath ~= format(" L%s %s", convertFloatToText(dx), convertFloatToText(dy));
    }

    override void fill()
    {
        output(format(`<path d="%s" fill="%s"/>`, _currentPath, _currentFill));
    }

    override void stroke()
    {
        output(format(`<path d="%s" fill="none" stroke="%s" stroke-width="%s" stroke-dasharray="%-(%f %)" stroke-dashoffset="%f"/>`, _currentPath, _currentStroke, convertFloatToText(_currentLineWidth), _dashSegments, _dashOffset));
    }

    override void fillAndStroke()
    {
        output(format(`<path d="%s" fill="%s" stroke="%s" stroke-width="%s" stroke-dasharray="%-(%f %)" stroke-dashoffset="%f"/>`, _currentPath, _currentFill, _currentStroke, convertFloatToText(_currentLineWidth), _dashSegments, _dashOffset));
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
        output(format(`<g transform="scale(%s %s)">`, convertFloatToText(x), convertFloatToText(y)));
        currentState().openedNestedGroups += 1;
    }

    override void translate(float dx, float dy)
    {
        output(format(`<g transform="translate(%s %s)">`, convertFloatToText(dx), convertFloatToText(dy)));
        currentState().openedNestedGroups += 1;
    }

    override void rotate(float angle)
    {
        float angleInDegrees = (angle * 180) / PI;
        output(format(`<g transform="rotate(%s)">`, convertFloatToText(angleInDegrees)));
        currentState().openedNestedGroups += 1;
    }

    override void drawImage(Image image, float x, float y)
    {
        drawImage(image, x, y, image.printWidth(), image.printHeight());
    }

    override void drawImage(Image image, float x, float y, float width, float height)
    {
        output(format(`<image xlink:href="%s" x="%s" y="%s" width="%s" height="%s" preserveAspectRatio="none"/>`,
                      image.toDataURI(), convertFloatToText(x), convertFloatToText(y), convertFloatToText(width), convertFloatToText(height)));
    }

protected:
    string getXMLHeader()
    {
        return `<?xml version="1.0" encoding="UTF-8" standalone="no"?>`;
    }

private:

    bool _finished = false;
    ubyte[] _bytes;
    RenderOptions _options;

    string _currentFill = "#000";
    string _currentStroke = "#000";
    float _currentLineWidth = 1;

    int _numberOfPage = 1;
    float _pageWidthMm;
    float _pageHeightMm;

    string _currentPath;
    float[] _dashSegments = [];
    float _dashOffset = 0f;

    string _fontFace = "Helvetica";
    FontWeight _fontWeight = FontWeight.normal;
    FontStyle _fontStyle = FontStyle.normal;
    float _fontSize = convertPointsToMillimeters(11.0f);
    TextAlign _textAlign = TextAlign.start;
    TextBaseline _textBaseline = TextBaseline.alphabetic;

    static struct State
    {
        int openedNestedGroups; // Number of opened <g> at the point `save()` is called.
    }
    State[] _stateStack;

    ref State currentState()
    {
        assert(_stateStack.length > 0);
        return _stateStack[$-1];
    }

    int currentOpenedNestedGroups()
    {
        return _stateStack[$-1].openedNestedGroups;
    }

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
        assert(_stateStack.length == 1);
    }

    void beginPage()
    {
        _stateStack ~= State(currentOpenedNestedGroups() + 1);
        output(format(`<g transform="translate(0,%s)">`, convertFloatToText(_pageHeightMm * (_numberOfPage-1))));
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
                     convertFloatToText(_pageWidthMm), convertFloatToText(heightInMm), convertFloatToText(_pageWidthMm), convertFloatToText(heightInMm));
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
                            `font-family: ` ~ info.svgFamilyName ~ `;`;

                    if (_options.embedFonts)
                        defs ~= `src: url('data:application/x-font-ttf;charset=utf-8;base64,` ~ base64font ~ `');`; 
                    else
                    {
                        /// Ref: MDN
                        /// "Specifies the name of a locally-installed font face using the local() function, 
                        ///  which uniquely identifies a single font face within a larger family."
                        string fullFontName = font.fullFontName();
                        assert(fullFontName !is null); // if false, it would mean not all font have this table and name and we have to chnge our method
                        defs ~= `src: local('` ~ fullFontName ~ `');`;
                    }
                        
                    defs ~= "}\n";
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

private:

const(char)[] convertFloatToText(float f)
{
    char[] fstr = format("%f", f).dup;
    replaceCommaPerDot(fstr);
    return stripNumber(fstr);
}

const(char)[] stripNumber(const(char)[] s)
{
    assert(s.length > 0);

    // Remove leading +
    // "+0.4" => "0.4"
    if (s[0] == '+')
        s = s[1..$];

    // if there is a dot, remove all trailing zeroes
    // ".45000" => ".45"
    int positionOfDot = -1;
    foreach(size_t i, char c; s)
    {
        if (c == '.')
            positionOfDot = cast(int)i;
    }
    if (positionOfDot != -1)
    {
        for (size_t i = s.length - 1; i > positionOfDot ; --i)
        {
            bool isZero = (s[i] == '0');
            if (isZero)
                s = s[0..$-1]; // drop last char
            else
                break;
        }
    }

    // if the final character is a dot, drop it
    if (s.length >= 2 && s[$-1] == '.')
        s = s[0..$-1];

    // Remove useless zero
    // "-0.1" => "-.1"
    // "0.1" => ".1"
    if (s.length >= 2 && s[0..2] == "0.")
        s = "." ~ s[2..$]; // TODO: this allocates
    else if (s.length >= 3 && s[0..3] == "-0.")
        s = "-." ~ s[3..$]; // TODO: this allocates

    return s;
}

void replaceCommaPerDot(char[] s)
{
    foreach(ref char ch; s)
    {
        if (ch == ',')
        {
            ch = '.';
            break;
        }
    }
}
unittest
{
    char[] s = "1,5".dup;
    replaceCommaPerDot(s);
    assert(s == "1.5");
}
