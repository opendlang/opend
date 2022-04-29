import gamut;

void main(string[] args) @trusted
{
    Image image;    
    image.load("material.png");
    assert(image.width == 1252);
    assert(image.height == 974);
}