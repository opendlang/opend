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
    Image jpeg0 = new Image("smiley.jpg");
    Image jpeg1 = new Image("made-by-android.jpg");
    Image jpeg2 = new Image("made-by-photoshop.jpg");

    foreach(context; [//cast(IRenderingContext2D) pdfDoc, 
                      cast(IRenderingContext2D) svgDoc,
                      cast(IRenderingContext2D) htmlDoc,])
    {        
        context.drawImage(png, 10, 10);        
        context.drawImage(jpeg0, 10, 20);
        context.drawImage(jpeg1, 10, 30);
        context.drawImage(jpeg2, 10, 100);
    }

    /// Draw the result of each specific renderer.
    std.file.write("output.pdf", pdfDoc.bytes);
    std.file.write("output.svg", svgDoc.bytes);
    std.file.write("output.html", htmlDoc.bytes);
}
