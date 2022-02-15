/**
Generic 2D vector renderer.

Copyright: Guillaume Piolat 2018.
License:   $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost License 1.0)
*/
module printed.canvas.irenderer;

public import printed.canvas.image;

/// Describes the `printed` 2D renderer.
///
/// This is the law, specific implementation MUST obey this interface and
/// not the underlying implementation in PDF/SVG/whatever (and if necessary revise this spec).
///
/// We are heavily influenced by the HTML5 Canvas 2D context API, for its familiarity.
/// See_also: https://www.w3.org/TR/2dcontext/
interface IRenderingContext2D
{
    // GRAPHICAL CONTEXT

    /// Number of units in a page.
    /// Return: Page width in millimeters.
    float pageWidth();

    /// Number of units in a page.
    /// Return: Page height in millimeters.
    float pageHeight();

    /// Push state on state stack.
    /// What this states contains:
    /// - transformation matrices
    void save();

    /// Pop state stack and restore state
    void restore();

    /// Start a new page, finish the previous one.
    /// This invalidates any transformation.
    /// The origin (0, 0) becomes again the top-left point of each page.
    void newPage();


    // TRANSFORMATIONS (default: transform is the identity matrix)
    // The origin (0, 0) of the default is the top-left point of each page.

    /// Changes the transformation matrix to apply a scaling transformation with the given characteristics.
    void scale(float x, float y);

    /// Changes the transformation matrix to apply a translation transformation with the given characteristics.
    void translate(float dx, float dy);

    /// Changes the transformation matrix to apply a rotation transformation with the given characteristics.
    /// The angle is in radians, the direction is clockwise.
    /// Params:
    ///     angle The rotation angle, in radians.
    void rotate(float angle);


    // IMAGES

    /// Draws an image at the given position.
    void drawImage(Image image, float x, float y);

    /// Draws an image at the given position, with the given width and height.
    /// Both `width` and `height` must be provided.
    void drawImage(Image image, float x, float y, float width, float height);

    // COLOURS

    /// Changes the current fill brush.
    /// Params:
    ///    color Any HTML color string, or a `Brush` if you want to save the parsing cost.
    void fillStyle(Brush brush);
    ///ditto
    void fillStyle(const(char)[] color); // equivalent to `fillStyle(brush(color));`

    /// Changes the current stroke brush.
    /// Params:
    ///    color Any HTML color string.
    void strokeStyle(Brush brush);
    ///ditto
    void strokeStyle(const(char)[] color); // equivalent to `strokeStyle(brush(color));`

    // DASHED LINES

    /// Sets the current line dash pattern (as used when stroking). The
    /// argument is an array of distances for which to alternately have the
    /// line on and the line off.
    ///
    /// Params:
    ///    segments = array of distances for which to alternately have the line on and
    ///               the line off.
    void setLineDash(float[] segments = []);

    /// Returns a copy of the current line dash pattern. The array returned
    /// will always have an even number of entries (i.e. the pattern is
    /// normalized).
    float[] getLineDash();

    /// Returns the phase offset (in the same units as the line dash pattern).
    /// Can be set, to change the phase offset. Values that are not finite
    /// values are ignored.
    void lineDashOffset(float offset);
    /// ditto
    float lineDashOffset();

    // BASIC SHAPES

    ///
    void fillRect(float x, float y, float width, float height);
    void strokeRect(float x, float y, float width, float height);

    /// Draw filled text.
    void fillText(const(char)[] text, float x, float y);

    // PATHS
    /// The context always has a current default path.
    /// There is only one current path, it is not part of the drawing state.

    /// Resets the current path, and move the cursor to (x, y).
    void beginPath(float x, float y);

    /// Change the width of a line.
    /// The whole path has the same line width.
    void lineWidth(float width);

    /// Add a subpath forming a line. Its exact width is set when the path is drawn with `fill`, `stroke` or `fillAndStroke`.
    void lineTo(float dx, float dy);

    /// Fills the subpaths of the current path or the given path with the current fill style.
    /// Uses the last set fill style, line width for the whole path.
    void fill();

    /// Strokes the subpaths of the current path or the given path with the current stroke style.
    /// Uses the last set fill style, line width for the whole path.
    void stroke();

    /// Both fills and strokes the subpaths of the current path, in a more efficient way than calling
    /// `fill` and `stroke` separately.
    /// Uses the last set fill style, line width for the whole path.
    void fillAndStroke();

    /// Close the path, returning to the initial first point.
    /// TODO: specify exactly what it does.
    void closePath();


    // FONTS
    // The specific font will be lazily choosen across all available fonts,
    // with a matching algorithm.
    // See_also: `findBestMatchingFont`.

    /// Changes font face (default = Helvetica)
    void fontFace(string fontFace);

    /// Changes font weight (Default = FontWeight.normal)
    void fontWeight(FontWeight fontWeight);

    /// Changes font style (default = FontStyle.normal)
    void fontStyle(FontStyle fontStyle);

    /// Changes font size in points (default = 11pt)
    /// Warning: not millimeters.
    void fontSize(float sizeInPt);

    /// Changes text alignment (default = TextAlign.start)
    void textAlign(TextAlign alignment);

    /// Changes text baseline (default = TextBaseline.alphabetic)
    void textBaseline(TextBaseline baseline);

    /// Returns a `TextMetrics` struct that contains information about the measured text
    /// (such as its width, for example).
    TextMetrics measureText(const(char)[] text);
}

enum TextAlign
{
    /// Align to the start edge of the text (left side in left-to-right text, right side in right-to-left text).
    /// This is the default.
    start,

    /// Align to the end edge of the text (right side in left-to-right text, left side in right-to-left text).
    end,

    /// Align to the left.
    left,

    /// Align to the right.
    right,

    /// Align to the center.
    center
}

enum TextBaseline
{
    top,
    hanging,
    middle,
    alphabetic, // default
    bottom
}

/// Font weight
enum FontWeight : int
{
    thinest = 0, // Note: thinest doesn't exist in PostScript
    thin = 100,
    extraLight = 200,
    light = 300,
    normal = 400,
    medium = 500,
    semiBold = 600,
    bold = 700,
    extraBold = 800,
    black = 900
}

/// Font style
enum FontStyle
{
    normal,
    italic,
    oblique
}

/// Make a brush suitable for `fillStyle` and `strokeStyle`.
Brush brush(int r, int g, int b, int a)
{
    return Brush(r, g, b, a);
}

///ditto
Brush brush(int r, int g, int b)
{
    return Brush(r, g, b);
}

///ditto
Brush brush(const(char)[] htmlColor)
{
    return Brush(htmlColor);
}

struct Brush
{
    ubyte[4] rgba;

    this(int r, int g, int b)
    {
        rgba[0] = cast(ubyte)r;
        rgba[1] = cast(ubyte)g;
        rgba[2] = cast(ubyte)b;
        rgba[3] = 255;
    }

    this(int r, int g, int b, int a)
    {
        rgba[0] = cast(ubyte)r;
        rgba[1] = cast(ubyte)g;
        rgba[2] = cast(ubyte)b;
        rgba[3] = cast(ubyte)a;
    }

    this(const(char)[] htmlColor)
    {
        import printed.htmlcolors;
        rgba = parseHTMLColor(htmlColor);
    }

    bool isOpaque()
    {
        return rgba[3] == 255;
    }

    ubyte[4] toRGBAColor()
    {
        return rgba;
    }

    string toSVGColor()
    {
        import std.string;
        // TODO: optimize
        return format("rgba(%d,%d,%d,%f)", rgba[0], rgba[1], rgba[2], rgba[3] / 255.0f);
    }
}


// Utility functions

float convertPointsToMillimeters(float pt) pure nothrow @nogc @safe
{
    return pt * 0.35277777778f;
}

float convertMillimetersToPoints(float pt) pure nothrow @nogc @safe
{
    return pt * 2.83464567f;
}


/// The `TextMetrics` interface represents the dimensions of a piece of text,
/// as created by the `measureText()` method.
struct TextMetrics
{
    float width;   /// Suggested horizontal advance to the next block of text.
    float lineGap; /// Suggested offset to the next line, baseline to baseline.
}


/// Allows to customize rendering, for format-specific features.
struct RenderOptions
{
    // `true` for reproducibility.
    // `false` for not embedding fonts and have smaller file sizes. 
    // Only supported by SVG/HTML.
    bool embedFonts; 
}

/// The default render options.
__gshared immutable RenderOptions defaultRenderOptions = RenderOptions(true);