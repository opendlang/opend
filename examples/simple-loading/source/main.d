import gamut;



void main(string[] args)
{
    FIBITMAP *bitmap = FreeImage_Load(FIF_PNG, "material.png", PNG_DEFAULT);

    if (bitmap) 
    {
        assert(FreeImage_GetWidth(bitmap) == 1252);
        assert(FreeImage_GetHeight(bitmap) == 974);

        FreeImage_Unload(bitmap);
    }
}