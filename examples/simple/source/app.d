import std.stdio;
import std.file;

import pdfd;

void main(string[] args)
{
    auto doc = new PDFDocument();

    doc.save();


    doc.lineWidth(4);
    doc.beginPath(100, 150);
    doc.lineTo(100, 250);
    doc.stroke();

    doc.restore();
    std.file.write("output.pdf", doc.bytes);
}
