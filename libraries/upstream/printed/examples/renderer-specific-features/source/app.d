import std.stdio;
import std.file;
import std.math;

import printed.canvas;

void main(string[] args)
{
    RenderOptions options;
    options.embedFonts = false;
    auto svgDoc = new SVGDocument(210, 297, options);

    foreach(renderer; [cast(IRenderingContext2D) svgDoc])
    {
        with(renderer)
        {
            // Fill page with light grey
   //         fillStyle = brush("#fff");
   //         fillRect(0, 0, pageWidth, pageHeight);

            // Prepare text settings
     //       fillStyle = brush("black");
            fontFace("Arial");
            fontSize(14);

            // Unicode test
            fillText("This is a pretty small SVG file, but less reproducible.", 20, 20);            
        }
    }
    std.file.write("output.svg", svgDoc.bytes);
}
