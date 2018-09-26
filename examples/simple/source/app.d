import std.stdio;
import std.file;
import std.math;

import printed;

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
            fillStyle = "#eee";
            fillRect(0, 0, pageWidth, pageHeight);

            // Draw a red line
            strokeStyle = "#ff0000";
            lineWidth(4);
            beginPath(100, 150);
            lineTo(100, 250);
            stroke();

            // Prepare text settings
            fillStyle = "#000";
            fontFace("Arial");
            fontWeight(FontWeight.bold);
            fontStyle(FontStyle.italic);
            fontSize(14);

            // Unicode test
            translate(20, 20);
            fillText("çéù%ù»", 0, 0);
            
            // Go to the next page
            newPage();

            // Draw rotated text
            fontStyle(FontStyle.normal);
            save();
                translate(20, 20);
                fillText("Straight", 15, 0);
                rotate(PI / 4);
                fillText("Rotated 45°", 15, 0);

                rotate(PI / 4);
                fillText("Rotated 90°", 15, 0);
            restore();
        }
    }

    /// Draw the result of each specific renderer.
    std.file.write("output.pdf", pdfDoc.bytes);
    std.file.write("output.svg", svgDoc.bytes);
    std.file.write("output.html", htmlDoc.bytes);
}
