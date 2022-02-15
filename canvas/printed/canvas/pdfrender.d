/**
PDF renderer.

Copyright: Guillaume Piolat 2018.
License:   $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost License 1.0)
*/
module printed.canvas.pdfrender;

import core.stdc.string: strlen;
import core.stdc.stdio: snprintf;

import std.string;
import std.conv;
import std.math;
import std.zlib;
import printed.canvas.irenderer;
import printed.canvas.internals;
import printed.font.fontregistry;
import printed.font.opentype;

class PDFException : Exception
{
    public
    {
        @safe pure nothrow this(string message,
                                string file =__FILE__,
                                size_t line = __LINE__,
                                Throwable next = null)
        {
            super(message, file, line, next);
        }
    }
}


final class PDFDocument : IRenderingContext2D
{
    this(float pageWidthMm = 210, float pageHeightMm = 297, RenderOptions options = defaultRenderOptions)
    {
        // Not embedding fonts isn't supported.
        assert(options.embedFonts);

        _pageWidthMm = pageWidthMm;
        _pageHeightMm = pageHeightMm;

        _pageTreeId = _pool.allocateObjectId();
        _extGStateId = _pool.allocateObjectId();

        // header
        output("%PDF-1.4\n");

        // "If a PDF file contains binary data, as most do (see 7.2, "Lexical Conventions"),
        // the header line shall be immediately followed by a comment line containing at least
        // four binary characters—that is, characters whose codes are 128 or greater.
        // This ensures proper behaviour of file transfer applications that inspect data near
        // the beginning of a file to determine whether to treat the file’s contents as text or as binary."
        output("%¥±ë\n");

        // Start the first page
        beginPage();
    }

    override float pageWidth()
    {
        return _pageWidthMm;
    }

    override float pageHeight()
    {
        return _pageHeightMm;
    }

    override void newPage()
    {
        // end the current page, and add one
        endPage();
        beginPage();
    }

    void end()
    {
        if (_finished)
            throw new PDFException("PDFDocument already finalized.");

        _finished = true;

        // end the current page
        endPage();

        // Add all deferred object and finalize the PDF output
        finalizeOutput();
    }

    const(ubyte)[] bytes()
    {
        if (!_finished)
            end();
        return _bytes;
    }

    // <Graphics operations>

    // Text drawing

    override void fontFace(string face)
    {
        _fontFace = face;
    }

    override void fontSize(float size)
    {
        _fontSize = convertPointsToMillimeters(size);
    }

    override void textAlign(TextAlign alignment)
    {
        _textAlign = alignment;
    }

    override void textBaseline(TextBaseline baseline)
    {
        _textBaseline = baseline;
    }

    override void fontWeight(FontWeight weight)
    {
        _fontWeight = weight;
    }

    override void fontStyle(FontStyle style)
    {
        _fontStyle = style;
    }

    override TextMetrics measureText(const(char)[] text)
    {
        string fontPDFName;
        object_id fontObjectId;
        OpenTypeFont font;
        getFont(_fontFace, _fontWeight, _fontStyle, fontPDFName, fontObjectId, font);
        OpenTypeTextMetrics otMetrics = font.measureText(text);
        TextMetrics metrics;
        metrics.width = _fontSize * otMetrics.horzAdvance * font.invUPM(); // convert to millimeters
        metrics.lineGap = _fontSize * font.lineGap() * font.invUPM();
        return metrics;
    }

    override void fillText(const(char)[] text, float x, float y)
    {
        string fontPDFName;
        object_id fontObjectId;

        OpenTypeFont font;
        getFont(_fontFace, _fontWeight, _fontStyle, fontPDFName, fontObjectId, font);

        // We need a baseline offset in millimeters
        float textBaselineInGlyphUnits = font.getBaselineOffset(cast(FontBaseline)_textBaseline);
        float textBaselineInMm = _fontSize * textBaselineInGlyphUnits * font.invUPM();
        y += textBaselineInMm;

        // Get width aka horizontal advance
        OpenTypeTextMetrics otMetrics = font.measureText(text);
        float horzAdvanceMm = _fontSize * otMetrics.horzAdvance * font.invUPM();
        final switch(_textAlign) with (TextAlign)
        {
            case start: // TODO bidir text
            case left:
                break;
            case end:
            case right:
                x -= horzAdvanceMm;
                break;
            case center:
                x -= horzAdvanceMm * 0.5f;
        }

        // Mark the current page as using this font
        currentPage.markAsUsingThisFont(fontPDFName, fontObjectId);



        // save CTM
        outDelim();
        output('q');

        // Note: text has to be flipped vertically since we have flipped PDF coordinates vertically
        scale(1, -1);

        // begin text object
        outDelim();
        output("BT");

            outName(fontPDFName);
            outFloat(_fontSize);
            output(" Tf");

            outFloat(x);
            outFloat(-y); // inverted else text is not positionned rightly
            output(" Td");

            outStringForDisplay(text);
            output(" Tj");

        // end text object
        outDelim();
        output("ET");

        // restore CTM
        outDelim();
        output('Q');
    }

    // State stack

    override void save()
    {
        outDelim();
        output('q');
    }

    override void restore()
    {
        outDelim();
        output('Q');
    }

    // Transformations
    override void scale(float x, float y)
    {
        if (x == 1 && y == 1) return;
        transform(x, 0,
                  0, y,
                  0, 0);
    }

    override void translate(float dx, float dy)
    {
        if (dx == 0 && dy == 0) return;
        transform(1, 0,
                  0, 1,
                  dx, dy);
    }

    override void rotate(float angle)
    {
        if (angle == 0) return;
        float cosi = cos(angle);
        float sine = sin(angle);
        transform(cosi, sine,
                  -sine, cosi,
                  0, 0);
    }

    /// Multiply current transformation matrix by:
    /// [a b 0
    ///  c d 0
    ///  e f 1]
    void transform(float a, float b, float c, float d, float e, float f)
    {
        outFloat(a);
        outFloat(b);
        outFloat(c);
        outFloat(d);
        outFloat(e);
        outFloat(f);
        output(" cm");
    }

    // Images

    override void drawImage(Image image, float x, float y)
    {
        float widthMm = image.printWidth;
        float heightMm = image.printHeight;
        drawImage(image, x, y, widthMm, heightMm);
    }

    override void drawImage(Image image, float x, float y, float width, float height)
    {
        string imageName;
        object_id id;
        getImage(image, imageName, id);

        // save CTM
        outDelim();
        output('q');

        translate(x, y + height);

        // Note: image has to be flipped vertically, since PDF is bottom to up
        scale(width, -height);

        outName(imageName);
        output(" Do");

        // restore CTM
        outDelim();
        output('Q');

        // Mark the current page as using this image
        currentPage.markAsUsingThisImage(imageName, id);
    }

    // Color selection

    override void fillStyle(Brush brush)
    {
        ubyte[4] c = brush.toRGBAColor();
        outFloat(c[0] / 255.0f);
        outFloat(c[1] / 255.0f);
        outFloat(c[2] / 255.0f);
        output(" rg");
        setNonStrokeAlpha(c[3]);
    }

    override void fillStyle(const(char)[] color)
    {
        fillStyle(brush(color));
    }

    override void strokeStyle(Brush brush)
    {
        ubyte[4] c = brush.toRGBAColor();
        outFloat(c[0] / 255.0f);
        outFloat(c[1] / 255.0f);
        outFloat(c[2] / 255.0f);
        output(" RG");
        setStrokeAlpha(c[3]);
    }

    override void strokeStyle(const(char)[] color)
    {
        strokeStyle(brush(color));
    }

    override void setLineDash(float[] segments = [])
    {
        if (isValidLineDashPattern(segments))
        {
            auto normSegments = normalizeLineDashPattern(segments);
            if (normSegments != _dashSegments)
            {
                _dashSegments = normalizeLineDashPattern(segments);
                _isSetDashPattern = false;
            }
        }
    }

    override float[] getLineDash()
    {
        return _dashSegments.dup;
    }

    override void lineDashOffset(float offset)
    {
        if (offset != _dashOffset && -float.infinity < offset && offset < float.infinity)
        {
            _dashOffset = offset;
            _isSetDashPattern = false;
        }
    }

    override float lineDashOffset()
    {
        return _dashOffset;
    }

    // Basic shapes
    // UB if you are into a path.

    override void fillRect(float x, float y, float width, float height)
    {
        outFloat(x);
        outFloat(y);
        outFloat(width);
        outFloat(height);
        output(" re");
        fill();
    }

    override void strokeRect(float x, float y, float width, float height)
    {
        setDashPattern();
        outDelim();
        outFloat(x);
        outFloat(y);
        outFloat(width);
        outFloat(height);
        output(" re");
        stroke();
    }

    // Path construction

    override void beginPath(float x, float y)
    {
        setDashPattern();
        outDelim();
        outFloat(x);
        outFloat(y);
        output(" m");
    }

    override void lineTo(float x, float y)
    {
        outFloat(x);
        outFloat(y);
        output(" l");
    }

    // line parameters

    override void lineWidth(float width)
    {
        outFloat(width);
        output(" w");
    }

    // Path painting operators

    override void fill()
    {
        outDelim();
        output("f");
    }

    override void stroke()
    {
        outDelim();
        output("S");
    }

    override void fillAndStroke()
    {
        outDelim();
        output("B");
    }

    override void closePath()
    {
        outDelim();
        output(" h");
    }

    // </Graphics operations>

private:

    bool _finished = false;

    // Current font size
    float _fontSize = convertPointsToMillimeters(11.0f);

    // Current font face
    string _fontFace = "Helvetica";

    // Current font weight
    FontWeight _fontWeight = FontWeight.normal;

    // Current font style
    FontStyle _fontStyle = FontStyle.normal;

    // Current font baseline
    TextBaseline _textBaseline = TextBaseline.alphabetic;

    // Current text alignment
    TextAlign _textAlign = TextAlign.start;

    // <alpha support>

    object_id _extGStateId;

    /// Whether this opacity value is used at all in the document (stroke operations).
    bool[256] _strokeAlpha;

    /// Whether this opacity value is used at all in the document (non-stroke operations).
    bool[256] _nonStrokeAlpha;

    bool _isSetDashPattern;

    float[] _dashSegments = [];

    float _dashOffset = 0f;

    void setStrokeAlpha(ubyte alpha)
    {
        _strokeAlpha[alpha] = true;
        char[3] gsName;
        makeStrokeAlphaName(alpha, gsName);
        outName(gsName[]);
        output(" gs");
    }

    void setNonStrokeAlpha(ubyte alpha)
    {
        _nonStrokeAlpha[alpha] = true;
        char[3] gsName;
        makeNonStrokeAlphaName(alpha, gsName);
        outName(gsName[]);
        output(" gs");
    }

    void setDashPattern()
    {
        if (_isSetDashPattern)
            return; // already emitted to PDF; do nothing

        output(format!"[%-(%f %)] %f d"(_dashSegments, _dashOffset));
    }

    // </alpha support>


    void finalizeOutput()
    {
        // Add every page object
        foreach(i; 0..numberOfPages())
        {
            beginDictObject(_pageDescriptions[i].id);
            outName("Type"); outName("Page");
            outName("Parent"); outReference(_pageTreeId);
            outName("Contents"); outReference(_pageDescriptions[i].contentId);

            // Necessary for transparent PNGs
            {
                outName("Group");
                outBeginDict();
                    outName("Type"); outName("Group");
                    outName("S"); outName("Transparency");
                    outName("CS"); outName("DeviceRGB");
                outEndDict();
            }

            outName("Resources");
                outBeginDict();

                    // List all fonts used by that page
                    outName("Font");
                        outBeginDict();
                            foreach(f; _pageDescriptions[i].fontUsed.byKeyValue)
                            {
                                outName(f.key);
                                outReference(f.value);
                            }
                        outEndDict();

                    // List all images used by that page
                    outName("XObject");
                        outBeginDict();
                        foreach(iu; _pageDescriptions[i].imageUsed.byKeyValue)
                        {
                            outName(iu.key);
                            outReference(iu.value);
                        }
                        outEndDict();

                    // Point to extended graphics state (shared across pages)
                    outName("ExtGState");
                    outReference(_extGStateId);
                outEndDict();
            endDictObject();
        }

        // Generates ExtGState object with alpha graphics states
        beginDictObject(_extGStateId);
            foreach(alpha; 0..256)
                if (_strokeAlpha[alpha])
                {
                    char[3] gs;
                    makeStrokeAlphaName(cast(ubyte)alpha, gs);
                    outName(gs[]);
                    outBeginDict();
                        outName("CA"); outFloat(alpha / 255.0f);
                    outEndDict();
                }

            foreach(alpha; 0..256)
                if (_nonStrokeAlpha[alpha])
                {
                    char[3] gs;
                    makeNonStrokeAlphaName(cast(ubyte)alpha, gs);
                    outName(gs[]);
                    outBeginDict();
                        outName("ca"); outFloat(alpha / 255.0f);
                    outEndDict();
                }
        endDictObject();

        // Generates /Image objects
        foreach(pair; _imagePDFInfos.byKeyValue())
        {
            Image image = pair.key;
            ImagePDFInfo info = pair.value;

            bool isPNG = image.MIME == "image/png";
            bool isJPEG = image.MIME == "image/jpeg";
            if (!isPNG && !isJPEG)
                throw new Exception("Unsupported image as PDF embed");

            const(ubyte)[] originalEncodedData = image.encodedData();

            // For JPEG, we can use the JPEG-encoded original image directly.
            // For PNG, we need to decode it, and reencode using DEFLATE

            string filter;
            if (isJPEG)
                filter = "DCTDecode";
            else if (isPNG)
                filter = "FlateDecode";
            else
                assert(false);

            const(ubyte)[] pdfData = originalEncodedData; // what content will be embeded
            const(ubyte)[] smaskData = null; // optional smask object
            object_id smaskId;
            if (isPNG)
            {
                import dplug.graphics.pngload; // because it's one of the fastest PNG decoder in D world
                import core.stdc.stdlib: free;

                // decode to RGBA
                int width, height, origComponents;

                // Made a mistake of breaking a function inside dplug:graphics that was used directly by printed
                static if (__traits(compiles, { int w, h, comp; stbi_load_png_from_memory(null, w, h, comp, 4); }))
                {
                    ubyte* decoded = stbi_load_png_from_memory(originalEncodedData, width, height, origComponents, 4);
                }
                else
                {
                    ubyte* decoded = stbi_load_from_memory(originalEncodedData.ptr,
                                                           cast(int)(originalEncodedData.length), 
                                                           &width, &height, &origComponents, 4);
                }
                if (origComponents != 3 && origComponents != 4)
                    throw new Exception("Only support embed of RGB or RGBA PNG");

                int size = width * height * 4;
                ubyte[] decodedRGBA = decoded[0..size];
                scope(exit) free(decoded);

                // Extract RGB data
                ubyte[] rgbData = new ubyte[width * height * 3];
                foreach(i; 0 .. width*height)
                    rgbData[3*i..3*i+3] = decodedRGBA[4*i..4*i+3];
                pdfData = compress(rgbData);

                // if PNG has actual alpha information, use separate PDF image as mask
                if (origComponents == 4)
                {
                    // Eventually extract alpha data to a plane, that will be in a separate PNG image
                    ubyte[] alphaData = new ubyte[width * height];
                    foreach(i; 0 .. width*height)
                        alphaData[i] = decodedRGBA[4*i+3];
                    smaskData = compress(alphaData);
                    smaskId = _pool.allocateObjectId();  // MAYDO: allocate this on first use, detect PNG with alpha before
                }
            }

            beginObject(info.streamId);
                outBeginDict();
                    outName("Type"); outName("XObject");
                    outName("Subtype"); outName("Image");
                    outName("Width"); outFloat(image.width());
                    outName("Height"); outFloat(image.height());
                    outName("ColorSpace"); outName("DeviceRGB");
                    outName("BitsPerComponent"); outInteger(8);
                    outName("Length"); outInteger(cast(int)(pdfData.length));
                    outName("Filter"); outName(filter);
                    if (smaskData)
                    {
                        outName("SMask"); outReference(smaskId);
                    }
                outEndDict();
                outBeginStream();
                    outputBytes(pdfData);
                outEndStream();
            endObject();

            if (smaskData)
            {
                beginObject(smaskId);
                    outBeginDict();
                        outName("Type"); outName("XObject");
                        outName("Subtype"); outName("Image");
                        outName("Width"); outFloat(image.width());
                        outName("Height"); outFloat(image.height());
                        outName("ColorSpace"); outName("DeviceGray");
                        outName("BitsPerComponent"); outInteger(8);
                        outName("Length"); outInteger(cast(int)(smaskData.length));
                        outName("Filter"); outName("FlateDecode");
                    outEndDict();
                    outBeginStream();
                        outputBytes(smaskData);
                    outEndStream();
                endObject();
            }
        }

        // Generates /Font object
        foreach(pair; _fontPDFInfos.byKeyValue())
        {
            OpenTypeFont font = pair.key;
            FontPDFInfo info = pair.value;

            // Important: the font sizes given in the PDF have to be in the default glyph space where 1em = 1000 units
            float scale = font.scaleFactorForPDF();

            beginDictObject(info.compositeFontId);
                outName("Type"); outName("Font");
                outName("Subtype"); outName("Type0");
                outName("BaseFont"); outName(info.baseFont);
                outName("DescendantFonts");
                    outBeginArray();
                        outReference(info.cidFontId);
                    outEndArray();

                // TODO ToUnicode?
                outName("Encoding"); outName("Identity-H"); // map character to same CID
            endDictObject();

            beginDictObject(info.cidFontId);
                outName("Type"); outName("Font");
                outName("Subtype"); outName("CIDFontType2");
                outName("BaseFont"); outName(info.baseFont);
                outName("FontDescriptor"); outReference(info.descriptorId);

                // Export text advance ("widths") of glyphs in the font
                outName("W");
                    outBeginArray();
                        foreach(crange; font.charRanges())
                        {
                            outInteger(crange.start); // first glyph index is always 0
                            outBeginArray();
                                foreach(dchar ch; crange.start .. crange.stop)
                                {
                                    int glyph = font.glyphIndexFor(ch);
                                    outFloat(scale * font.horizontalAdvanceForGlyph(glyph));
                                }
                            outEndArray();
                        }
                    outEndArray();

                outName("CIDToGIDMap"); outReference(info.cidToGidId);

                outName("CIDSystemInfo");
                outBeginDict();
                    outName("Registry"); outLiteralString("Adobe");
                    outName("Ordering"); outLiteralString("Identity");
                    outName("Supplement"); outInteger(0);
                outEndDict();
            endDictObject();

            beginDictObject(info.descriptorId);
                outName("Type"); outName("FontDescriptor");
                outName("FontName"); outName(info.baseFont);
                outName("Flags"); outInteger( font.isMonospaced ? 5 : 4);

                outName("FontBBox");
                    outBeginArray();
                        int[4] bb = font.boundingBox();
                        outFloat(scale * bb[0]);
                        outFloat(scale * bb[1]);
                        outFloat(scale * bb[2]);
                        outFloat(scale * bb[3]);
                    outEndArray();

                outName("ItalicAngle"); outFloat(font.postScriptItalicAngle);

                outName("Ascent"); outFloat(scale * font.ascent);
                outName("Descent"); outFloat(scale * font.descent);
                outName("Leading"); outFloat(scale * font.lineGap);
                outName("CapHeight"); outFloat(scale * font.capHeight);

                // See_also: https://stackoverflow.com/questions/35485179/stemv-value-of-the-truetype-font
                outName("StemV"); outFloat(scale * 120); // since the font is always embedded in the PDF, we do not feel obligated with a valid value

               outName("FontFile2"); outReference(info.streamId);
            endDictObject();

            // font embedded as stream
            outStream(info.streamId, font.fileData);

            // CIDToGIDMap as a stream
            // this can take quite some space
            {
                dchar N = font.maxAvailableChar()+1;
                ubyte[] cidToGid = new ubyte[N*2];
                foreach(dchar ch;  0..N)
                {
                    ushort gid = font.glyphIndexFor(ch);
                    cidToGid[ch*2] = (gid >> 8);
                    cidToGid[ch*2+1] = (gid & 255);
                }
                outStream(info.cidToGidId, cidToGid[]);
            }
        }


        // Add the pages object
        beginDictObject(_pageTreeId);
            outName("Type"); outName("Pages");
            outName("Count"); outInteger(numberOfPages());
            outName("MediaBox");
            outBeginArray();
                outInteger(0);
                outInteger(0);
                // Note: device space is in point by default
                outFloat(convertMillimetersToPoints(_pageWidthMm));
                outFloat(convertMillimetersToPoints(_pageHeightMm));
            outEndArray();
            outName("Kids");
            outBeginArray();
                foreach(i; 0..numberOfPages())
                    outReference(_pageDescriptions[i].id);
            outEndArray();
        endDictObject();

        // Add the root object
        object_id rootId = _pool.allocateObjectId();
        beginDictObject(rootId);
            outName("Type"); outName("Catalog");
            outName("Pages"); outReference(_pageTreeId);
        endDictObject();
        output("\n");

        // Note: at this point all indirect objects should have been added to the output
        byte_offset offsetOfXref = generatexrefTable();

        output("trailer\n");
        outBeginDict();
            outName("Size");
            outInteger(_pool.numberOfObjects());
            outName("Root");
            outReference(rootId);
        outEndDict();

        output("\nstartxref\n");
        output(format("%s\n", offsetOfXref));
        output("%%EOF\n");
    }

    alias object_id = int;
    alias byte_offset = int;

    // <pages>

    void beginPage()
    {
        PageDesc p;
        p.id = _pool.allocateObjectId();
        p.contentId = _pool.allocateObjectId();
        p.fontUsed = null;

        _pageDescriptions ~= p;

        _currentStreamLengthId = _pool.allocateObjectId();

        // start a new stream object with this id, referencing a future length object
        // (as described in the PDF 32000-1:2008 specification section 7.3.2)
        beginObject(p.contentId);
        outBeginDict();
            outName("Length"); outReference(_currentStreamLengthId);
        outEndDict();
        _currentStreamStart = outBeginStream();

        // Change coordinate system to match CSS, SVG, and general intuition
        float scale = kMillimetersToPoints;
        transform(scale, 0.0f,
                  0.0f, -1 * scale,
                  0.0f, scale * _pageHeightMm);
    }

    byte_offset _currentStreamStart;
    object_id _currentStreamLengthId;

    void endPage()
    {
        // end the stream object started in beginPage()
        byte_offset streamStop = outEndStream();
        int streamBytes = streamStop - _currentStreamStart;
        endObject();

        // Create a new object with the length
        beginObject(_currentStreamLengthId);
        outInteger(streamBytes);
        endObject();

        // close stream object
    }

    object_id _pageTreeId;

    struct PageDesc
    {
        object_id id;              // page id
        object_id contentId;       // content of the page id
        object_id[string] fontUsed;  // a map of font objects used in that page
        object_id[string] imageUsed;  // a map of image objects used in that page

        void markAsUsingThisImage(string imagePDFName, object_id imageObjectId)
        {
            imageUsed[imagePDFName] = imageObjectId;
        }

        void markAsUsingThisFont(string fontPDFName, object_id fontObjectId)
        {
            fontUsed[fontPDFName] = fontObjectId;
        }
    }

    PageDesc[] _pageDescriptions;

    int numberOfPages()
    {
        return cast(int)(_pageDescriptions.length);
    }

    PageDesc* currentPage()
    {
        return &_pageDescriptions[$-1];
    }

    float _pageWidthMm, _pageHeightMm;

    // </pages>

    // <Mid-level syntax>, knows about indirect objects

    // Opens a new dict object.
    // Returns: the object ID.
    void beginDictObject(object_id id)
    {
        beginObject(id);
        outBeginDict();
    }

    // Closes a dict object.
    void endDictObject()
    {
        outEndDict();
        endObject();
    }

    // Opens a new indirect object.
    // Returns: the object ID.
    void beginObject(object_id id)
    {
        outDelim();

        _pool.setObjectOffset(id, currentOffset());

        // Note: all objects are generation zero
        output(format("%s 0 obj", id));
    }

    // Closes an indirect object.
    void endObject()
    {
        outDelim();
        output("endobj");
    }

    void outStream(object_id id, const(ubyte)[] content)
    {
        // Note: there is very little to win between compression level 6 and 9
        ubyte[] compressedContent = compress(content);

        // Only compress if this actually reduce sizes
        bool compressed = true;
        if (compressedContent.length > content.length)
            compressed = false;

        const(ubyte)[] streamData = compressed ? compressedContent : content;

        beginObject(id);
            outBeginDict();
                outName("Length"); outInteger(cast(int)(streamData.length));
                if (compressed)
                {
                    outName("Filter"); outName("FlateDecode");
                }
            outEndDict();
            outBeginStream();
                outputBytes(streamData);
            outEndStream();
        endObject();
    }

    /// Returns: the offset of the xref table generated
    byte_offset generatexrefTable()
    {
        int numberOfObjects = _pool.numberOfObjects;
        byte_offset offsetOfLastXref = currentOffset();
        output("xref\n");
        output(format("0 %s\n", numberOfObjects+1));

        // special object 0, head of the freelist of objects
        output("0000000000 65535 f \n");

        // writes all labelled objects
        foreach(id; 1..numberOfObjects+1)
        {
            // Writing offset of object (i+1), not (i)
            // Note: all objects are generation 0
            output(format("%010s 00000 n \n",  _pool.offsetOfObject(id)));
        }
        return offsetOfLastXref;
    }

    // </Mid-level syntax>


    // <Low-level syntax>, don't know about objects

    static immutable bool[256] spaceOrdelimiterFlag =
        (){
            bool[256] t;

            // space characters
            t[0] = true;
            t[9] = true;
            t[10] = true;
            t[12] = true;
            t[13] = true;
            t[32] = true;

            // delimiter
            t['('] = true;
            t[')'] = true;
            t['<'] = true;
            t['>'] = true;
            t['['] = true;
            t[']'] = true;
            t['{'] = true;
            t['}'] = true;
            t['/'] = true; // Note: % left out
            return t;
        }();

    bool isDelimiter(char c)
    {
        return spaceOrdelimiterFlag[c];
    }

    // insert delimiter only if necessary
    void outDelim()
    {
        char lastChar = _bytes[$-1];
        if (!isDelimiter(lastChar))
            output(' '); // space separates entities
    }

    void outReference(object_id id)
    {
        outDelim();
        output( format("%d 0 R", id) );
    }

    ubyte[] _bytes;

    byte_offset currentOffset()
    {
        return cast(byte_offset) _bytes.length;
    }

    void output(ubyte b)
    {
        _bytes ~= b;
    }

    void outputBytes(const(ubyte)[] b)
    {
        _bytes ~= b;
    }

    void output(const(char)[] s)
    {
        _bytes ~= s.representation;
    }

    void outStringForDisplay(const(char)[] s)
    {
        // TODO: selection of shortest encoding instead of always UTF16-BE

        bool allCharUnder512 = true;

        foreach(dchar ch; s)
        {
            if (ch >= 512)
            {
                allCharUnder512 = false;
                break;
            }
        }

  /*      if (allCharUnder512)
        {
            outDelim();
            output('(');

            output(')');
        }
        else */
        {
            // Using encoding UTF16-BE
            output('<');
            foreach(dchar ch; s)
            {
                ushort CID = cast(ushort)(ch);
                ubyte hi = (CID >> 8) & 255;
                ubyte lo = CID & 255;
                static immutable string hex = "0123456789ABCDEF";
                output(hex[hi >> 4]);
                output(hex[hi & 15]);
                output(hex[lo >> 4]);
                output(hex[lo & 15]);
            }
            output('>');
        }
    }

    void outLiteralString(string s)
    {
        outLiteralString(cast(ubyte[])s);
    }

    void outLiteralString(const(ubyte)[] s)
    {
        outDelim();
        output('(');
        foreach(ubyte b; s)
        {
            if (b == '(')
            {
                output('\\');
                output('(');
            }
            else if (b == ')')
            {
                output('\\');
                output(')');
            }
            else if (b == '\\')
            {
                output('\\');
                output('\\');
            }
            else
                output(b);
        }
        output(')');
    }

    void outBool(bool b)
    {
        outDelim();
        output(b ? "true" : "false");
    }

    void outInteger(int d)
    {
        outDelim();
        output(format("%d", d));
    }

    void outFloat(float f)
    {
        outDelim();
        char[] fstr = format("%f", f).dup;
        replaceCommaPerDot(fstr);
        output(stripNumber(fstr));
    }

    void outName(const(char)[] name)
    {
        // no delimiter needed as '/' is a delimiter
        output('/');
        output(name);
    }

    // begins a stream, return the current byte offset
    byte_offset outBeginStream()
    {
        outDelim();
        output("stream\n");
        return currentOffset();
    }

    byte_offset outEndStream()
    {
        byte_offset here = currentOffset();
        output("endstream");
        return here;
    }

    void outBeginDict()
    {
        output("<<");
    }

    void outEndDict()
    {
        output(">>");
    }

    void outBeginArray()
    {
        output("[");
    }

    void outEndArray()
    {
        output("]");
    }
    // </Low-level syntax>


    // <Object Pool>
    // The object pool stores id and offsets of indirect objects
    // exluding the "zero object".
    // There is support for allocating objects in advance, in order to reference them
    // in the stream before they appear.
    ObjectPool _pool;

    static struct ObjectPool
    {
    public:

        enum invalidOffset = cast(byte_offset)-1;

        // Return a new object ID
        object_id allocateObjectId()
        {
            _currentObject += 1;
            _offsetsOfIndirectObjects ~= invalidOffset;
            assert(_currentObject == _offsetsOfIndirectObjects.length);
            return _currentObject;
        }

        byte_offset offsetOfObject(object_id id)
        {
            assert(id > 0);
            assert(id <= _currentObject);
            return _offsetsOfIndirectObjects[id - 1];
        }

        int numberOfObjects()
        {
            assert(_currentObject == _offsetsOfIndirectObjects.length);
            return _currentObject;
        }

        void setObjectOffset(object_id id, byte_offset offset)
        {
            assert(id > 0);
            assert(id <= _currentObject);
            _offsetsOfIndirectObjects[id - 1] = offset;
        }

    private:
        byte_offset[] _offsetsOfIndirectObjects; // offset of
        object_id _currentObject = 0;
    }

    static struct ImagePDFInfo
    {
        string pdfName;            // "Ixx", associated name in the PDF (will be of the form /Ixx)
        object_id streamId;
    }

    /// Associates with each open image information about
    /// the PDF embedding of that image.
    /// Note: they key act as reference that keeps the Image alive
    ImagePDFInfo[Image] _imagePDFInfos;

    void getImage(Image image,
                  out string imagePdfName,
                  out object_id imageObjectId)
    {
        // Is this image known already? lazily create it
        ImagePDFInfo* pInfo = image in _imagePDFInfos;
        if (pInfo is null)
        {
            // Give a PDF name, and object id for this image
            ImagePDFInfo info;
            info.pdfName = format("I%d", _imagePDFInfos.length);
            info.streamId = _pool.allocateObjectId();
            _imagePDFInfos[image] = info;
            pInfo = image in _imagePDFInfos;
        }
        imagePdfName = pInfo.pdfName;
        imageObjectId = pInfo.streamId;
    }

    // Enough data to describe a font resource in a PDF
    static struct FontPDFInfo
    {
        object_id compositeFontId; // ID for the composite Type0 /Font object
        object_id cidFontId;       // ID for the CID /Font object
        object_id descriptorId;    // ID for the /FontDescriptor object
        object_id streamId;        // ID for the file stream
        object_id cidToGidId;      // ID for the /CIDToGIDMap stream object
        string pdfName;            // "Fxx", associated name in the PDF (will be of the form /Fxx)
        string baseFont;
    }

    // Ensure this font exist, generate a /name and give it back
    // Only PDF builtin fonts supported.
    // TODO: bold and oblique support
    void getFont(string fontFamily,
                 FontWeight weight,
                 FontStyle style,
                 out string fontPDFName,
                 out object_id fontObjectId,
                 out OpenTypeFont outFont)
    {
        auto otWeight = cast(OpenTypeFontWeight)weight;
        auto otStyle = cast(OpenTypeFontStyle)style;
        OpenTypeFont font = theFontRegistry().findBestMatchingFont(fontFamily, otWeight, otStyle);
        outFont = font;

        // is this font known already?
        FontPDFInfo* info = font in _fontPDFInfos;

        // lazily create the font object in the PDF
        if (info is null)
        {
            // Give a PDF name, and object id for this font
            FontPDFInfo f;
            f.compositeFontId = _pool.allocateObjectId();
            f.cidFontId = _pool.allocateObjectId();
            f.descriptorId = _pool.allocateObjectId();
            f.streamId = _pool.allocateObjectId();
            f.cidToGidId = _pool.allocateObjectId();
            f.pdfName = format("F%d", _fontPDFInfos.length); // technically this is only namespaced at the /Page resource level

            /*
            This is tricky. The specification says:

            "The PostScript name for the value of BaseFont
            may be determined in one of two ways:
            - If the TrueType font program's “name” table contains a
              PostScript name, it shall be used.
            - In the absence of such an entry in the “name” table, a
              PostScript name shall be derived from the name by
              which the font is known in the host operating system.
              On a Windows system, the name shall be based on
              the lfFaceName field in a LOGFONT structure; in the Mac OS,
              it shall be based on the name of the FOND resource. If the
              name contains any SPACEs, the SPACEs shall be removed."
            */
            f.baseFont = font.postScriptName();

            // FIXME: follow the above instruction if no PostScript name in the truetype file.
            if (f.baseFont is null)
                throw new Exception("Couldn't find a PostScript name in the %s font.");

            // TODO: throw if the PostScript name is not a valid PDF name

            _fontPDFInfos[font] = f;
            info = font in _fontPDFInfos;
            assert(info !is null);
        }

        fontObjectId = info.compositeFontId;
        fontPDFName = info.pdfName;
    }

    /// Associates with each open font information about
    /// the PDF embedding of that font.
    FontPDFInfo[OpenTypeFont] _fontPDFInfos;
}

private:

void replaceCommaPerDot(char[] s)
{
    foreach(ref char ch; s)
    {
        if (ch == ',')
        {
            ch = '.';
            break;
        }
    }
}
unittest
{
    char[] s = "1,5".dup;
    replaceCommaPerDot(s);
    assert(s == "1.5");
}

// Strip number of non-significant characters.
// "1.10000" => "1.1"
// "1.00000" => "1"
// "4"       => "4"
const(char)[] stripNumber(const(char)[] s)
{
    assert(s.length > 0);

    // Remove leading +
    // "+0.4" => "0.4"
    if (s[0] == '+')
        s = s[1..$];

    // if there is a dot, remove all trailing zeroes
    // ".45000" => ".45"
    int positionOfDot = -1;
    foreach(size_t i, char c; s)
    {
        if (c == '.')
            positionOfDot = cast(int)i;
    }
    if (positionOfDot != -1)
    {
        for (size_t i = s.length - 1; i > positionOfDot ; --i)
        {
            bool isZero = (s[i] == '0');
            if (isZero)
                s = s[0..$-1]; // drop last char
            else
                break;
        }
    }

    // if the final character is a dot, drop it
    if (s.length >= 2 && s[$-1] == '.')
        s = s[0..$-1];

    // Remove useless zero
    // "-0.1" => "-.1"
    // "0.1" => ".1"
    if (s.length >= 2 && s[0..2] == "0.")
        s = "." ~ s[2..$]; // TODO: this allocates
    else if (s.length >= 3 && s[0..3] == "-0.")
        s = "-." ~ s[3..$]; // TODO: this allocates

    return s;
}

unittest
{
    assert(stripNumber("1.10000") == "1.1");
    assert(stripNumber("1.0000") == "1");
    assert(stripNumber("4") == "4");
    assert(stripNumber("+0.4") == ".4");
    assert(stripNumber("-0.4") == "-.4");
    assert(stripNumber("0.0") == "0");
}

/// Returns: scale factor to convert from glyph space to the PDF glyph space which is fixed for the CIFFont we use.
float scaleFactorForPDF(OpenTypeFont font)
{
    return 1000.0f * font.invUPM();
}

enum float kMillimetersToPoints = 2.83465f;


/// Returns: scale factor to convert from glyph space to the PDF glyph space which is fixed for the CIFFont we use.
float convertMillimetersToPoints(float x) pure
{
    return x * kMillimetersToPoints;
}

static immutable string HEX = "0123456789abcdef";

// Name /S80 means a stroke alpha value of 128.0 / 255.0
void makeStrokeAlphaName(ubyte alpha, ref char[3] outName) pure
{
    outName[0] = 'S';
    outName[1] = HEX[(alpha >> 4)];
    outName[2] = HEX[alpha & 15];
}

// Name /T80 means a non-stroke alpha value of 128.0 / 255.0
void makeNonStrokeAlphaName(ubyte alpha, ref char[3] outName) pure
{
    outName[0] = 'T';
    outName[1] = HEX[(alpha >> 4)];
    outName[2] = HEX[alpha & 15];
}
