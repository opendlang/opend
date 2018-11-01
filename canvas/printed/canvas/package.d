/**
Implements a 2D Canvas vectorial abstraction with multiple backends.

Copyright: Guillaume Piolat 2018.
License:   $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost License 1.0)
*/
module printed.canvas;

public import printed.canvas.irenderer;
public import printed.canvas.svgrender;
public import printed.canvas.htmlrender;
public import printed.canvas.pdfrender;
