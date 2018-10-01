module printed.canvas.htmlrender;

import std.string;
import printed.canvas.irenderer;
import printed.canvas.svgrender;


/// Renders 2D commands in a HTML file.
/// This simply embed a SVG inside.
class HTMLDocument : SVGDocument
{
public:
    this(int pageWidthMm = 210, int pageHeightMm = 297)
    {
        super(pageWidthMm, pageHeightMm);
    }

    override const(ubyte)[] bytes()
    {
        auto svgBytes = super.bytes();
        auto htmlHeader = cast(const(ubyte)[])( getHTMLHeader() );
        auto htmlFooter = cast(const(ubyte)[])( getHTMLFooter() );

        return htmlHeader ~ svgBytes ~ htmlFooter;
    }

    void setTitle(string title)
    {
        _title = title;
    }

protected:
    override string getXMLHeader()
    {
        return "";
    }

private:

    string _title = null;

    string getHTMLHeader()
    {
        string header =
             `<!doctype html>`
             ~ `<html>`
             ~ `<head>`
             ~ `<meta charset="utf-8">`;

        if (_title)
            header ~= format(`<title>%s</title>`, _title);

        header ~= `</head>`
                ~ `<body>`;
        return header;
    }

    string getHTMLFooter()
    {
        return "</body></html>";
    }
}