import gamut;



void main(string[] args)
{
    FIBITMAP *bitmap = FreeImage_AllocateT(FIT_RGB16, 512, 512);
    if (bitmap) {
        // bitmap successfully created!
        FreeImage_Unload(bitmap);
    }
}