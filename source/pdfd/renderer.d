module pdfd.renderer;

public import pdfd.opentype: FontWeight, FontStyle;

/// Describes a HTML5-style renderer.
interface IRenderingContext2D 
{
    // GRAPHICAL CONTEXT

    /// Number of units in a page.
    /// Return: Page width in millimeters.
    int pageWidth();

    /// Number of units in a page.
    /// Return: Page height in millimeters.
    int pageHeight();

    /// Save the graphical context: transformation matrices.
    void save();

    /// Restore the graphical contect: transformation matrices.
    void restore();

    /// Start a new page, finish the previous one.
    /// This invalidates any transformation.
    void newPage();



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

    ///
    void fillText(string text, float x, float y);

    // PATHS
    /// The context always has a current default path. 
    /// There is only one current path, it is not part of the drawing state.

    /// Resets the current path, and move the cursor to (x, y).
    void beginPath(float x, float y);

    /// Change the width of a line.
    void lineWidth(float width);

    ///
    void lineTo(float dx, float dy);

    /// Fills the subpaths of the current path or the given path with the current fill style.
    void fill();

    /// Strokes the subpaths of the current path or the given path with the current stroke style.
    void stroke();

    /// Both fills and strokes the subpaths of the current path, in a way more efficient than calling
    /// `fill` and `stroke` separately.
    void fillAndStroke();

    ///
    void closePath();


    // FONTS
    
    ///
    void fontFace(string fontFace);

    ///
    void fontWeight(FontWeight fontWeight);

    ///
    void fontStyle(FontStyle fontStyle);

    ///
    void fontSize(float size);
}
