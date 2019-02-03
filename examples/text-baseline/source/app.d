import std.stdio;
import std.file;
import std.math;
import std.string;
import std.conv;

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
            lineWidth = 0.1f;
            strokeStyle = Brush("red");

            beginPath(pageWidth/2, 20);
            lineTo(pageWidth/2, pageHeight-20);
            stroke();

            foreach(int j, TextAlign alignment; 
                    [
                        TextAlign.left,
                        TextAlign.right,
                        TextAlign.center
                    ])
            {
                foreach(int i, TextBaseline baseline; 
                        [
                            TextBaseline.top,
                            TextBaseline.hanging,
                            TextBaseline.middle,
                            TextBaseline.alphabetic,
                            TextBaseline.bottom
                        ])
                {
                    float y = i * 15 + 20 + j * 80;
                    textAlign = alignment;
                    textBaseline = baseline;
                    beginPath(20, y);
                    lineTo(pageWidth-20, y);
                    stroke();
                    string text = format("Abcdefghijklmnop (align '%s', baseline '%s')", alignment, baseline);
                    fillText(text, pageWidth*0.5f, y);
                }
            }
        }
    }

    /// Draw the result of each specific renderer.
    std.file.write("text-baseline.pdf", pdfDoc.bytes);
    std.file.write("text-baseline.svg", svgDoc.bytes);
    std.file.write("text-baseline.html", htmlDoc.bytes);
}


