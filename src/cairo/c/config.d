/**
 * This module contains information on what optional features are
 * available with the used cairo library.
 */
module cairo.c.config;

version (D_Ddoc)
{
    ///PNG functions are available
    enum bool CAIRO_HAS_PNG_FUNCTIONS = true;
    ///Postscript surface support
    enum bool CAIRO_HAS_PS_SURFACE = true;
    ///PDF surface support
    enum bool CAIRO_HAS_PDF_SURFACE = true;
    ///SVG surface support
    enum bool CAIRO_HAS_SVG_SURFACE = true;

    //These require external libraries / bindings

    ///Win32 surface support
    enum bool CAIRO_HAS_WIN32_SURFACE = false;
    ///Win32 font support
    enum bool CAIRO_HAS_WIN32_FONT = false;
    ///Freetype font support
    enum bool CAIRO_HAS_FT_FONT = false;
    ///XCB surface support
    enum bool CAIRO_HAS_XCB_SURFACE = false;
    ///DirectFB surface support
    enum bool CAIRO_HAS_DIRECTFB_SURFACE = false;
    ///XLIB surface support
    enum bool CAIRO_HAS_XLIB_SURFACE = false;
}
else
{
    static if (__traits(compiles, CAIROD_IS_CONFIGURED) && CAIROD_IS_CONFIGURED)
    {
        // Use variables from configure.d
    }
    else
    {
        // Configured using -version compiler arguments
        version (CairoPNG)
            enum bool CAIRO_HAS_PNG_FUNCTIONS = true;
        else
            enum bool CAIRO_HAS_PNG_FUNCTIONS = false;

        version (CairoPSSurface)
            enum bool CAIRO_HAS_PS_SURFACE = true;
        else
            enum bool CAIRO_HAS_PS_SURFACE = false;

        version (CairoPDFSurface)
            enum bool CAIRO_HAS_PDF_SURFACE = true;
        else
            enum bool CAIRO_HAS_PDF_SURFACE = false;

        version (CairoSVGSurface)
            enum bool CAIRO_HAS_SVG_SURFACE = true;
        else
            enum bool CAIRO_HAS_SVG_SURFACE = false;

        version (CairoWin32Surface)
            enum bool CAIRO_HAS_WIN32_SURFACE = true;
        else
            enum bool CAIRO_HAS_WIN32_SURFACE = false;

        version (CairoWin32Font)
            enum bool CAIRO_HAS_WIN32_FONT = true;
        else
            enum bool CAIRO_HAS_WIN32_FONT = false;

        version (CairoFTFont)
            enum bool CAIRO_HAS_FT_FONT = true;
        else
            enum bool CAIRO_HAS_FT_FONT = false;

        version (CairoXCBSurface)
            enum bool CAIRO_HAS_XCB_SURFACE = true;
        else
            enum bool CAIRO_HAS_XCB_SURFACE = false;

        version (CairoDirectFBSurface)
            enum bool CAIRO_HAS_DIRECTFB_SURFACE = true;
        else
            enum bool CAIRO_HAS_DIRECTFB_SURFACE = false;

        version (CairoXlibSurface)
            enum bool CAIRO_HAS_XLIB_SURFACE = true;
        else
            enum bool CAIRO_HAS_XLIB_SURFACE = false;

        version (CarioGLSurface)
            enum bool CAIRO_HAS_GL_SURFACE = true;
        else
            enum bool CAIRO_HAS_GL_SURFACE = false;

        version (CarioGLESV2Surface)
            enum bool CAIRO_HAS_GLESV2_SURFACE = true;
        else
            enum bool CAIRO_HAS_GLESV2_SURFACE = false;

        version (CairoGLX)
            enum bool CAIRO_HAS_GLX_FUNCTIONS = true;
        else
            enum bool CAIRO_HAS_GLX_FUNCTIONS = false;

        version (CairoWGL)
            enum bool CAIRO_HAS_WGL_FUNCTIONS = true;
        else
            enum bool CAIRO_HAS_WGL_FUNCTIONS = false;

        version (CairoEGL)
            enum bool CAIRO_HAS_EGL_FUNCTIONS = true;
        else
            enum bool CAIRO_HAS_EGL_FUNCTIONS = false;
    }
}

/*
 * configure.d appends the actual enums at the end of this file
 */
