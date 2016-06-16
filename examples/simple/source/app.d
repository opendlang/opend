import std.stdio;
import std.file;

import pdfd;

void main(string[] args)
{
    PDF pdf = new PDF();
    std.file.write("output.pdf", pdf.toBytes());
}