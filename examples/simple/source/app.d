import std.stdio;
import std.file;

import pdfd;

void main(string[] args)
{
    auto doc = new PDFDocument();

    doc.save();

    doc.strokeStyle = "#ff0000";

    doc.lineWidth(4);
    doc.beginPath(100, 150);
    doc.lineTo(100, 250);
    doc.stroke();

    doc.fontFace("Helvetica");
    doc.fontSize(14);
    doc.fillText("Coucou", 100, 100);

    doc.restore();
    std.file.write("output.pdf", doc.bytes);
}
