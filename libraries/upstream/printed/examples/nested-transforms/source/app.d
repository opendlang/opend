import std.stdio;
import std.file;
import std.math;

import printed.canvas;

void main(string[] args)
{
    auto pdfDoc = new PDFDocument();
    auto svgDoc = new SVGDocument();
    auto htmlDoc = new HTMLDocument();

    foreach(renderer; [cast(IRenderingContext2D) pdfDoc, 
                       cast(IRenderingContext2D) svgDoc,
                       cast(IRenderingContext2D) htmlDoc,])
    {
        with(renderer)
        {
            // Fill page with light grey
            fillStyle = brush("#202020");
            fillRect(0, 0, pageWidth, pageHeight);

            // Prepare text settings
            fillStyle = brush("#e0e0e0");
            fontFace("Arial");
            fontSize(14);

            save();
                translate(50,50);
                fillText("Translated", 0, 0);

                save();
                rotate(PI / 8);
                fillText("Rotated", 0, 10);
                restore();

                fillText("Back from rotation, should be translated too", 0, 20);
            restore();
        }
    }

    /// Draw the result of each specific renderer.
    std.file.write("output.pdf", pdfDoc.bytes);
    std.file.write("output.svg", svgDoc.bytes);
    std.file.write("output.html", htmlDoc.bytes);
}
