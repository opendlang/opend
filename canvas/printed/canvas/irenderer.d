/// Generic 2D vector renderer
module printed.canvas.irenderer;

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



    // COLOURS

    /// Changes the current fill color.
    /// Params:
    ///    color Any HTML color string.
    void fillStyle(string color);

    /// Changes the current stroke color.
    /// Params:
    ///    color Any HTML color string.
    void strokeStyle(string style);


    // BASIC SHAPES

    ///
    void fillRect(float x, float y, float width, float height);
    void strokeRect(float x, float y, float width, float height);

    /// Draw filled text. 
    void fillText(string text, float x, float y);

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
    
    /// Changes font face.
    void fontFace(string fontFace);

    /// Changes font weight.
    void fontWeight(FontWeight fontWeight);

    /// Changes font style.
    void fontStyle(FontStyle fontStyle);

    /// Changes font size in points (1/72 inch).
    /// Warning: not millimeters.
    void fontSize(float sizeInPt);

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