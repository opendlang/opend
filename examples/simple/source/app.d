import std.stdio;
import std.file;

import pdfd;

void main(string[] args)
{
    PDF pdf = new PDF(210, 297);
    pdf.newPage();
    pdf.newPage();
    std.file.write("output.pdf", pdf.toBytes());
}