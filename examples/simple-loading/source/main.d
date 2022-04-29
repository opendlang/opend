import gamut;

import gamut.internals.mutex;

void main(string[] args) @trusted
{
    FIBITMAP *bitmap = FreeImage_Load(FIF_PNG, "material.png", PNG_DEFAULT);
    assert(bitmap);

    if (bitmap) 
    {
        assert(FreeImage_GetWidth(bitmap) == 1252);
        assert(FreeImage_GetHeight(bitmap) == 974);

        FreeImage_Unload(bitmap);
    }
}