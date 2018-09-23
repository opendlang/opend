module pdfd.renderer;

public import pdfd.opentype: FontWeight, FontStyle;

/// Describes a HTML5-style renderer.
interface IRenderer2D
{
    // GRAPHICAL CONTEXT

    /// Save the graphical context: transformation matrices.
    void save();

    /// Restore the graphical contect: transformation matrices.
    void restore();

    /// Start a new page, finish the previous one.
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

    ///
    void beginPath(float x, float y);

    /// Change the width of a line.
    void lineWidth(float width);

    ///
    void lineTo(float dx, float dy);

    ///
    void fill();

    ///
    void stroke();

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
