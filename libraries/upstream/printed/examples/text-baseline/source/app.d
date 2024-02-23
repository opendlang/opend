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
            strokeStyle = "red";
            fontSize = 11;

            beginPath(pageWidth/2, 20);
            lineTo(pageWidth/2, pageHeight-20);
            stroke();

            foreach(size_t j, TextAlign alignment; 
                    [
                        TextAlign.left,
                        TextAlign.right,
                        TextAlign.center
                    ])
            {
                foreach(size_t i, TextBaseline baseline; 
                        [
                            TextBaseline.top,
                            TextBaseline.hanging,
                            TextBaseline.middle,
                            TextBaseline.alphabetic,
                            TextBaseline.bottom
                        ])
                {
                    float x = pageWidth*0.5f;
                    float y = cast(int)i * 15 + 20 + cast(int)j * 80;
                    textAlign = alignment;
                    textBaseline = baseline;
                    strokeStyle = "red";
                    beginPath(20, y);
                    lineTo(pageWidth-20, y);
                    stroke();

                    string text = format("Abcdefghijklmnop (align '%s', baseline '%s')", alignment, baseline);

                    // Get text metrics for this block of text, and displays its bounding box.
                    // This should enclose the text.
                    TextMetrics m = measureText(text);
                    strokeStyle = "green";
                    strokeRect(x - m.actualBoundingBoxLeft,
                               y - m.fontBoundingBoxAscent,
                               m.actualBoundingBoxWidth,
                               m.fontBoundingBoxHeight);

                    // Draw text
                    fillText(text, x, y);

                    // Draw anchor
                    fillRect(x-0.5, y-0.5, 1, 1);
                }
            }
        }
    }

    /// Draw the result of each specific renderer.
    std.file.write("text-baseline.pdf", pdfDoc.bytes);
    std.file.write("text-baseline.svg", svgDoc.bytes);
    std.file.write("text-baseline.html", htmlDoc.bytes);
}


