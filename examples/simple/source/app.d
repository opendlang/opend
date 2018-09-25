import std.stdio;
import std.file;

import pdfd;

void main(string[] args)
{
    auto pdfDoc = new PDFDocument();
    auto svgDoc = new SVGDocument();
    auto htmlDoc = new HTMLDocument();

    foreach(renderer; [cast(IRenderingContext2D) pdfDoc, 
                       cast(IRenderingContext2D) svgDoc,
                       cast(IRenderingContext2D) htmlDoc,])
        with(renderer)
        {
            save();

            // Fill page with light grey
            fillStyle = "#eee";
            fillRect(0, 0, pageWidth, pageHeight);


            strokeStyle = "#ff0000";
            lineWidth(4);
            beginPath(100, 150);
            lineTo(100, 250);
            stroke();

            fillStyle = "#000";
            fontFace("Arial");
            fontWeight(FontWeight.bold);
            fontStyle(FontStyle.italic);
            fontSize(14);

            fillText("çéù%ù»", 20, 20); // Unicode test
            
            restore();

            newPage();
            fillText("Empty page", 20, 20);
        }

    std.file.write("output.pdf", pdfDoc.bytes);
    std.file.write("output.svg", svgDoc.bytes);
    std.file.write("output.html", htmlDoc.bytes);
}
