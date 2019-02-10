import std.stdio;
import std.file;
import std.math;

import printed.canvas;

void main(string[] args)
{
    auto pdfDoc = new PDFDocument();
    auto svgDoc = new SVGDocument();
    auto htmlDoc = new HTMLDocument();

    Image png = new Image("smiley.png");
    Image jpeg = new Image("smiley.jpg");

    foreach(context; [cast(IRenderingContext2D) pdfDoc, 
                      cast(IRenderingContext2D) svgDoc,
                      cast(IRenderingContext2D) htmlDoc,])
    {        
 //       context.drawImage(png, 10, 10);        
        context.drawImage(jpeg, 10, 10);

        context.fillStyle = Brush("red");

        float w = context.pageWidth;
        float h = context.pageHeight;
        context.fillRect(0, 0, 10, 10);
        context.fillRect(w-10, 0, 10, 10);
        context.fillRect(0, h-10, 10, 10);
        context.fillRect(w-10, h-10, 10, 10);
    }

    /// Draw the result of each specific renderer.
    std.file.write("output.pdf", pdfDoc.bytes);
    std.file.write("output.svg", svgDoc.bytes);
    std.file.write("output.html", htmlDoc.bytes);
}
