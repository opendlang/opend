#!/bin/sh
VERSIONS="-version=CAIRO_HAS_PS_SURFACE -version=CAIRO_HAS_PDF_SURFACE -version=CAIRO_HAS_SVG_SURFACE -version=CAIRO_HAS_WIN32_SURFACE -version=CAIRO_HAS_XCB_SURFACE -version=CAIRO_HAS_DIRECTFB_SURFACE -version=CAIRO_HAS_PNG_FUNCTIONS -version=CAIRO_HAS_WIN32_FONT"
cd src
dmd ../doc/cairo.ddoc -c -o- -wi -D -Dd../doc/generated/ -Dfcairo_c_cairo.html -I../../WindowsAPI $VERSIONS cairo/c/cairo.d
dmd ../doc/cairo.ddoc -c -o- -wi -D -Dd../doc/generated/ -Dfcairo_c_directfb.html -I../../WindowsAPI $VERSIONS cairo/c/directfb.d
dmd ../doc/cairo.ddoc -c -o- -wi -D -Dd../doc/generated/ -Dfcairo_c_pdf.html -I../../WindowsAPI $VERSIONS cairo/c/pdf.d
dmd ../doc/cairo.ddoc -c -o- -wi -D -Dd../doc/generated/ -Dfcairo_c_ps.html -I../../WindowsAPI $VERSIONS cairo/c/ps.d
dmd ../doc/cairo.ddoc -c -o- -wi -D -Dd../doc/generated/ -Dfcairo_c_svg.html -I../../WindowsAPI $VERSIONS cairo/c/svg.d
dmd ../doc/cairo.ddoc -c -o- -wi -D -Dd../doc/generated/ -Dfcairo_c_win32.html -I../../WindowsAPI $VERSIONS cairo/c/win32.d
dmd ../doc/cairo.ddoc -c -o- -wi -D -Dd../doc/generated/ -Dfcairo_c_xcb.html -I../../WindowsAPI $VERSIONS cairo/c/xcb.d

dmd ../doc/cairo.ddoc -c -o- -wi -D -Dd../doc/generated/ -Dfcairo_util.html -I../../WindowsAPI $VERSIONS cairo/util.d
dmd ../doc/cairo.ddoc -c -o- -wi -D -Dd../doc/generated/ -Dfcairo_cairo.html -I../../WindowsAPI $VERSIONS cairo/cairo.d
cd ../
