module pdfd.document;

import std.string;
import pdfd.color;
import pdfd.systemfonts;

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


class PDFDocument
{
    this(int pageWidthMm = 210, int pageHeightMm = 297)
    {
        _pageWidthMm = pageWidthMm;
        _pageHeightMm = pageHeightMm;

        _pageTreeId = _pool.allocateObjectId();

        // header
        output("%PDF-1.7\n");

        // "If a PDF file contains binary data, as most do (see 7.2, "Lexical Conventions"), 
        // the header line shall be immediately followed by a comment line containing at least 
        // four binary characters—that is, characters whose codes are 128 or greater.
        // This ensures proper behaviour of file transfer applications that inspect data near 
        // the beginning of a file to determine whether to treat the file’s contents as text or as binary."
        output("%¥±ë\n");

        // Start the first page
        beginPage();
    }

    PDFDocument addPage()
    {
        // end the current page, and add one
        endPage();
        beginPage();
        return this;
    }

    PDFDocument end()
    {
        if (_finished)
            throw new PDFException("PDFDocument already finalized.");

        _finished = true;

        // end the current page
        endPage();

        // Add all deferred object and finalize the PDF output
        finalizeOutput();

        return this;
    }    

    const(ubyte)[] bytes()
    {
        if (!_finished)
            end();
        return _bytes;
    }

    // <Graphics operations>

    // Text drawing

    float _fontSize = 11;
    string _fontFace = "Helvetica";

    void fontFace(string face)
    {
        _fontFace = face;
    }

    void fontSize(float size)
    {
        _fontSize = size;
    }

    void fillText(string text, float x, float y)
    {
        string fontPDFName;
        object_id fontObjectId;

        _fontManager.getFont(_pool, _fontFace, false, false, fontPDFName, fontObjectId);

        // Mark the current page as using this font
        currentPage.markAsUsingThisFont(fontPDFName, fontObjectId);

        outDelim();
        output("BT");
        outName(fontPDFName);
        outFloat(_fontSize);
        output(" Tf");
        outFloat(x);
        outFloat(y);
        outString(text);
        output(" Tj");
    }

    // State stack

    void save()
    {
        outDelim();
        output('q');
    }

    void restore()
    {
        outDelim();
        output('Q');
    }

    // Color selection

    void fillStyle(string color)
    {
        ubyte[3] c = parseHTMLColor(color);
        outFloat(c[0] / 255.0f);
        outFloat(c[1] / 255.0f);
        outFloat(c[2] / 255.0f);
        output(" rg");
    }

    void strokeStyle(string color)
    {
        ubyte[3] c = parseHTMLColor(color);
        outFloat(c[0] / 255.0f);
        outFloat(c[1] / 255.0f);
        outFloat(c[2] / 255.0f);
        output(" RG");
    }

    // Basic shapes
    // UB if you are into a path.

    void fillRect(float x, float y, float width, float height)
    {
        outFloat(x);
        outFloat(y);
        outFloat(width);
        outFloat(height);
        output(" re");
        fill();
    }

    void strokeRect(float x, float y, float width, float height)
    {
        outFloat(x);
        outFloat(y);
        outFloat(width);
        outFloat(height);
        output(" re");
        stroke();
    }

    // Path construction

    void beginPath(float x, float y)
    {
        outFloat(x);
        outFloat(y);
        output(" m");
    }

    void lineTo(float x, float y)
    {
        outFloat(x);
        outFloat(y);
        output(" l");
    }

    // line parameters

    void lineWidth(float width)
    {
        outFloat(width);
        output(" w");
    }

    // Path painting operators

    void fill()
    {
        outDelim();
        output("f");
    }

    void stroke()
    {
        outDelim();
        output("S");
    }

    void fillAndStroke()
    {
        outDelim();
        output("B");
    }

    void closePath()
    {
        outDelim();
        output(" h");
    }  

    // </Graphics operations>

private:

    bool _finished = false;

    void finalizeOutput()
    {
        // Add every page object
        foreach(i; 0..numberOfPages())
        {
            beginDictObject(_pageDescriptions[i].id);
            outName("Type"); outName("Page");
            outName("Parent"); outReference(_pageTreeId);
            outName("Contents"); outReference(_pageDescriptions[i].contentId);

            // List all fonts used by that page
            outName("Resources");
                outBeginDict();                    
                    outName("Font"); 
                    outBeginDict();
                        foreach(f; _pageDescriptions[i].fontUsed.byKeyValue)
                        {
                            outName(f.key);
                            outReference(f.value);
                        }
                    outEndDict();
                outEndDict();
            endDictObject();
        }

        // Include every font object
        // TODO: TTF embed
        foreach(fontDesc; _fontManager.usedFonts)
        {
            beginDictObject(fontDesc.id);
                outName("Type"); outName("Font");
                outName("Subtype"); outName("Type1");
                outName("BaseFont"); outName("Helvetica");
            endDictObject();
        }

        // Add the pages object
        beginDictObject(_pageTreeId);
            outName("Type"); outName("Catalog");
            outName("Count"); outInteger(numberOfPages());
            outName("MediaBox"); 
            outBeginArray();
            outInteger(0);
            outInteger(0);
            outInteger(_pageWidthMm);
            outInteger(_pageHeightMm);
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

        // Note: at this point all indirect objects should have been added to the output
        byte_offset offsetOfXref = generatexrefTable();

        output("trailer\n");
        outBeginDict();
        outName("Size");
        outInteger(_pool.numberOfObjects());
        outName("Root");
        outReference(rootId);
        outEndDict();

        output("startxref\n");
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

    int _pageWidthMm, _pageHeightMm;

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

    /// Returns: the offset of the xref table generated
    byte_offset generatexrefTable()
    {
        int numberOfObjects = _pool.numberOfObjects;
        size_t offsetOfLastXref = currentOffset();
        output("xref\n");
        output(format("0 %s\n", numberOfObjects));

        // special object 0, head of the freelist of objects
        output("0000000000 65535 f \n");

        // writes all labelled objects
        foreach(id; 1..numberOfObjects+1)
        {
            // Writing offset of object (i+1), not (i)
            // Note: all objects are generation 0
            output(format("%010s 000000 n \n",  _pool.offsetOfObject(id)));
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

    void output(string s)
    {
        _bytes ~= s.representation;
    }

    void outString(string s)
    {
        outDelim();
        output('(');
        output(s); // TODO: it is only allowed for latin-1 and matching parenthesis, etc
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
        output(format("%.3f", f));
    }

    void outName(string name)
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

    // Enough data to describe a font resource in a PDF
    static struct FontDesc
    {
        object_id id;
        string pdfName; // "Fxx", associated name in the PDF (will be of the form /Fxx)
    }

    // Hold a list of all font used in the document, to be added at the end.
    // This also associate names with fonts
    static struct FontManager
    {
        // Ensure this font exist, generate a /name and give it back 
        // Only PDF builtin fonts supported.
        // TODO: bold and oblique support
        void getFont(ObjectPool pool, string fontFace, bool bold, bool oblique, 
                        out string fontPDFName, out object_id fontObjectId)
        {
            FontDesc* desc = fontFace in _usedFonts;
            if (desc is null)
            {
                // lazily create the font object in the PDF
                _usedFonts[fontFace].id = pool.allocateObjectId();
                _usedFonts[fontFace].pdfName = format("F%d", ++_fontCount);
            }

            fontObjectId = _usedFonts[fontFace].id;
            fontPDFName = _usedFonts[fontFace].pdfName;
        }

        int _fontCount = 0;
        FontDesc[string] _usedFonts;

        // Returns: something foreachable with FontDesc elements
        auto usedFonts()
        {
            return _usedFonts.byValue();
        }
    }

    FontManager _fontManager;
}
