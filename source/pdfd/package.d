module pdfd;

import std.string;


@safe:

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
@safe:

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

    // Path construction

    void beginPath(int x, int y)
    {
        outInteger(x);
        outInteger(y);
        output(" m");
    }

    void lineTo(int x, int y)
    {
        outInteger(x);
        outInteger(y);
        output(" l");
    }

    // line parameters

    void lineWidth(int width)
    {
        outInteger(width);
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
        object_id id; // page id
        object_id contentId; // content of the page id
        object_id contentLengthId; // content of the page's length id
    }

    PageDesc[] _pageDescriptions;

    int numberOfPages()
    {
        return cast(int)(_pageDescriptions.length);
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
        assert(false); // TODO
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
    pure:
    @safe:
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
}


ubyte[3] parseHTMLColor(string s)
{
    int fromHex(char ch)
    {
        if (ch >= '0' && ch <= '9')
            return ch - '0';
        if (ch >= 'a' && ch <= 'f')
            return ch + 10 - 'a';
        if (ch >= 'A' && ch <= 'F')
            return ch + 10 - 'A';
        throw new Exception("Couldn't parse color " ~ s);
    }

    if (s.length == 4) // eg: "#4af"
    {
        if (s[0] != '#')
            throw new Exception("Couldn't parse color " ~ s);

        int r = fromHex(s[1]);
        int g = fromHex(s[2]);
        int b = fromHex(s[3]);
        r |= (r << 4);
        g |= (g << 4);
        b |= (b << 4);
        return [cast(ubyte)r, cast(ubyte)g, cast(ubyte)b];
    }
    else if (s.length == 7) // eg: "#44AAff"
    {
        int r = (fromHex(s[1]) << 4)| fromHex(s[2]);
        int g = (fromHex(s[3]) << 4)| fromHex(s[4]);
        int b = (fromHex(s[5]) << 4)| fromHex(s[6]);
        return [cast(ubyte)r, cast(ubyte)g, cast(ubyte)b];
    }
    else
        throw new Exception("Couldn't parse color " ~ s);
}