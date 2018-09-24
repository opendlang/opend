import std.stdio;
import std.file;

import pdfd;

void main(string[] args)
{
    auto pdfDoc = new PDFDocument();
    auto svgDoc = new SVGDocument();

    foreach(renderer; [cast(IRenderingContext2D) pdfDoc , cast(IRenderingContext2D) svgDoc])
        with(renderer)
        {
            save();
            strokeStyle = "#ff0000";
            lineWidth(4);
            beginPath(100, 150);
            lineTo(100, 250);
            stroke();
            fontFace("Arial");
            fontWeight(FontWeight.bold);
            fontStyle(FontStyle.italic);
            fontSize(14);
            fillText("This is a Unicode test: çéù%ù»", 20, 20);
            restore();
        }

    std.file.write("output.pdf", pdfDoc.bytes);
    std.file.write("output.svg", svgDoc.bytes);
}
