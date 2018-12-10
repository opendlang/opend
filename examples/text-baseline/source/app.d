import std.stdio;
import std.file;
import std.math;
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

            foreach(int i, TextBaseline baseline; 
                    [
                        TextBaseline.top,
                        TextBaseline.hanging,
                        TextBaseline.middle,
                        TextBaseline.alphabetic,
                        TextBaseline.bottom
                    ])
            {
                float y = i * 20 + 20;
                textBaseline = baseline;
                beginPath(20, y);
                lineTo(pageWidth-20, y);
                stroke();
                fillText("Abcdefghijklmnop (" ~ to!string(baseline) ~ ")", 20, y);
            }
        }
    }

    /// Draw the result of each specific renderer.
    std.file.write("text-baseline.pdf", pdfDoc.bytes);
    std.file.write("text-baseline.svg", svgDoc.bytes);
    std.file.write("text-baseline.html", htmlDoc.bytes);
}


