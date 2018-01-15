import std.stdio;
import std.file;

import pdfd;

void main(string[] args)
{
    PDF pdf = new PDF(210, 297);
    pdf.beginPage();

    pdf.endPage();
    pdf.beginPage();

    pdf.endPage();

    pdf.finish();
    std.file.write("output.pdf", pdf.getBytes());
}