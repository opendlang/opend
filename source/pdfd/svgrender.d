module pdfd.svgrender;

import std.string;
import pdfd.renderer;

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
class SVGDocument : IRenderer2D
{
public:
    this(int pageWidthMm = 210, int pageHeightMm = 297)
    {

        // write header
        output(`<?xml version="1.0" encoding="UTF-8" standalone="no"?>`);
        output(format(`<svg xmlns="http://www.w3.org/2000/svg" xmlns:svg="http://www.w3.org/2000/svg"`
                     ~` width="%dmm" height="%dmm" viewBox="0 0 %d %d" version="1.1">`,
                      pageWidthMm, pageHeightMm, pageWidthMm, pageHeightMm));



    }

    const(ubyte)[] bytes()
    {
        if (!_finished)
            end();
        return _bytes;
    }


    /// Save the graphical context: transformation matrices.
    override void save()
    {
        // nothing to do, a new <g> is open for each transform
    }

    /// Restore the graphical contect: transformation matrices.
    override void restore()
    {
        output("</g>");
    }

    /// Start a new page, finish the previous one.
    override void newPage()
    {
        assert(false, "not implemented");
    }

    override void fillStyle(string color)
    {
        assert(false, "not implemented");
    }

    override void strokeStyle(string style)
    {
        assert(false, "not implemented");
    }

    override void fillRect(float x, float y, float width, float height)
    {
        assert(false, "not implemented");
    }

    override void strokeRect(float x, float y, float width, float height)
    {
        assert(false, "not implemented");
    }

    override void fillText(string text, float x, float y)
    {
        assert(false, "not implemented");
    }

    override void beginPath(float x, float y)
    {
        assert(false, "not implemented");
    }

    override void lineWidth(float width)
    {
        assert(false, "not implemented");
    }

    override void lineTo(float dx, float dy)
    {
        assert(false, "not implemented");
    }

    override void fill()
    {
        assert(false, "not implemented");
    }

    override void stroke()
    {
        assert(false, "not implemented");
    }

    override void closePath()
    {
        assert(false, "not implemented");
    }

    override void fontFace(string fontFace)
    {
        assert(false, "not implemented");
    }

    override void fontWeight(FontWeight fontWeight)
    {
        assert(false, "not implemented");
    }

    override void fontStyle(FontStyle fontStyle)
    {
        assert(false, "not implemented");
    }

    override void fontSize(float size)
    {
        assert(false, "not implemented");
    }

private:

    bool _finished = false;
    ubyte[] _bytes;

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

    void end()
    {
        if (_finished)
            throw new SVGException("SVGDocument already finalized.");

        _finished = true;

        output(`</svg>`);
    }
}