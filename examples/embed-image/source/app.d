import std.stdio;
import std.file;
import std.math;

import printed.canvas;

void main(string[] args)
{
    auto pdfDoc = new PDFDocument();
    auto svgDoc = new SVGDocument();
    auto htmlDoc = new HTMLDocument();

    Image png = new Image("dman.png");
    Image jpeg = new Image("flower.jpg");

    foreach(context; [cast(IRenderingContext2D) pdfDoc, 
                      cast(IRenderingContext2D) svgDoc,
                      cast(IRenderingContext2D) htmlDoc,])
    {        
        context.drawImage(jpeg, 10, 10);

        // `printWidth` is the default width when drawn, extracted from DPI information.
        context.drawImage(jpeg, context.pageWidth - jpeg.printWidth - 10, 10);

        foreach(offset; 0..6)
        {
            context.save();
            
            float width = 30 + offset * 5;
            float height = 50 - offset * 5;

            float x = context.pageWidth/2 - width/2;
            float y = 40 + 40*offset - height/2;

            context.translate(x, y);
            context.rotate(offset * 0.1);

            // draw with given width and height
            context.drawImage(png, 0, 0, width, height);
            context.restore();
        }

        context.fillStyle = Brush("red");

        float w = context.pageWidth;
        float h = context.pageHeight;
        context.fillRect(0, 0, 10, 10);
        context.fillRect(w-10, 0, 10, 10);
        context.fillRect(0, h-10, 10, 10);
        context.fillRect(w-10, h-10, 10, 10);

        // test if fillStyle preserved by newPage
        context.newPage();
        context.fillRect(0, 0, 10, 10);
    }

    /// Draw the result of each specific renderer.
    std.file.write("output.pdf", pdfDoc.bytes);
    std.file.write("output.svg", svgDoc.bytes);
    std.file.write("output.html", htmlDoc.bytes);
}
