#!/bin/sh
VERSIONS="-version=CAIRO_HAS_PS_SURFACE -version=CAIRO_HAS_PDF_SURFACE -version=CAIRO_HAS_SVG_SURFACE -version=CAIRO_HAS_WIN32_SURFACE -version=CAIRO_HAS_XCB_SURFACE -version=CAIRO_HAS_DIRECTFB_SURFACE -version=CAIRO_HAS_PNG_FUNCTIONS -version=CAIRO_HAS_WIN32_FONT -version=CAIRO_HAS_FT_FONT"
INCLUDES="-I../../Derelict2/import -I../../WindowsAPI"
FLAGS="-c -o- -wi $VERSIONS $INCLUDES"
DC="dmd"
DDOC="../doc/cairo.ddoc -D"
OUTDIR="-Dd../doc/generated/"

cd src
$DC $DDOC $OUTDIR -Dfcairo_c_cairo.html $FLAGS cairo/c/cairo.d
$DC $DDOC $OUTDIR -Dfcairo_c_directfb.html $FLAGS cairo/c/directfb.d
$DC $DDOC $OUTDIR -Dfcairo_c_pdf.html $FLAGS cairo/c/pdf.d
$DC $DDOC $OUTDIR -Dfcairo_c_ps.html $FLAGS cairo/c/ps.d
$DC $DDOC $OUTDIR -Dfcairo_c_svg.html $FLAGS cairo/c/svg.d
$DC $DDOC $OUTDIR -Dfcairo_c_win32.html $FLAGS cairo/c/win32.d
$DC $DDOC $OUTDIR -Dfcairo_c_xcb.html $FLAGS cairo/c/xcb.d
$DC $DDOC $OUTDIR -Dfcairo_c_ft.html  $FLAGS cairo/c/ft.d

$DC $DDOC $OUTDIR -Dfcairo_util.html $FLAGS cairo/util.d
$DC $DDOC $OUTDIR -Dfcairo_cairo.html $FLAGS cairo/cairo.d
$DC $DDOC $OUTDIR -Dfcairo_directfb.html $FLAGS cairo/directfb.d
$DC $DDOC $OUTDIR -Dfcairo_pdf.html $FLAGS cairo/pdf.d
$DC $DDOC $OUTDIR -Dfcairo_ps.html $FLAGS cairo/ps.d
$DC $DDOC $OUTDIR -Dfcairo_svg.html $FLAGS cairo/svg.d
$DC $DDOC $OUTDIR -Dfcairo_win32.html  $FLAGS cairo/win32.d
$DC $DDOC $OUTDIR -Dfcairo_xcb.html $FLAGS cairo/xcb.d
$DC $DDOC $OUTDIR -Dfcairo_ft.html  $FLAGS cairo/ft.d
cd ../
