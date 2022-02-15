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
            fillStyle = brush("#eee");
            fillRect(0, 0, pageWidth, pageHeight);

            // Draw a red line
            strokeStyle = brush("#ff0000");
            lineWidth(4);
            beginPath(100, 150);
            lineTo(100, 250);
            stroke();

            // Draw a blue rect
            lineWidth(2);
            setLineDash([ 2, 1, 1]); // with dash pattern
            strokeStyle = "lightblue";
            strokeRect(50, 50, 40, 40);
            setLineDash(); // without dash pattern
            strokeRect(70, 70, 40, 40);

            // Draw a 50% transparent green triangle
            fillStyle = "rgba(0, 255, 0, 0.5)";
            beginPath(80, 170);
            lineTo(180, 170);
            lineTo(105, 240);
            closePath();
            fill();

            // Prepare text settings
            fillStyle = brush("black");
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
