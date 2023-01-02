module main;

import std.stdio;
import std.file;
import gamut;

void main(string[] args)
{ 
    testIssue35();
}

void testIssue35()
{
    Image image;
    image.loadFromFile("test-images/issue35.jpg", LOAD_RGB | LOAD_8BIT | LOAD_ALPHA | LAYOUT_VERT_STRAIGHT | LAYOUT_GAPLESS);
    assert(!image.errored);
    image.saveToFile("output/issue35.png");
}