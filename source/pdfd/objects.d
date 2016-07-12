module pdfd.objects;

import std.conv;

/// Serialization context passed to objects
class PDFSerializer
{
    ubyte[] buffer;

    void put(char ch)
    {
        buffer ~= cast(ubyte)ch;
    }

    void put(string str)
    {
        buffer ~= cast(ubyte[])str;
    }

    void put(ubyte[] bytes)
    {
        buffer ~= bytes;
    }

    size_t currentOffset()
    {
        return buffer.length;
    }
}

/// Root class of PDF objects
class PDFObject
{
public:
    // Converts into bytes
    abstract void toBytes(PDFSerializer output);

private:

    /// Object name, is an unique identifier in the document.
    int _name;
}

// TODO: maybe this is inefficient representation, eventually merge with PDFObject
class IndirectObject : PDFObject
{
    this(PDFObject wrapped, int identifier)
    {
        _obj = wrapped;        
        _identifier = identifier;
    }

    /// Returns the object generation, not much used.
    int generation() pure const nothrow @nogc
    {
        return 0;
    }

    int identifier() pure const nothrow @nogc
    {
        return _identifier;
    }

    // Converts into bytes, writes the full object
    void toBytesDirect(PDFSerializer output)
    {
        output.put( to!string(identifier) ~ " 0 obj\n" );
        _obj.toBytes(output);
        output.put("\nendobj\n");
    }

    // Converts into bytes, write only the reference
    override void toBytes(PDFSerializer output)
    {
        assert(generation == 0);
        output.put(to!string(identifier) ~ " 0 R");
    }

private:
    PDFObject _obj;
    int _identifier;
}


class NullObject : PDFObject
{
public:
    override void toBytes(PDFSerializer output)
    {
        output.put("null");
    }

private:
    double _value;
}

class NumericObject : PDFObject
{
public:
    this(double value)
    {
        _value = value;
    }

    // Converts into bytes
    override void toBytes(PDFSerializer output)
    {
        // TODO: round to decimal form
        output.put(to!string(_value));
    }

private:
    double _value;
}

class StringObject : PDFObject
{
public:
    this(string value)
    {
        _value = value;
    }

    // Converts into bytes
    override void toBytes(PDFSerializer output)
    {
        // TODO: round to decimal form
        output.put( escapeString(_value) );
    }

    // TODO: there are limits to string length within a PDF
    static string escapeString(string value)
    {
        string result = "<";
        foreach(char ch; value)
        {
            if (ch > 127)
                throw new Exception("Not supposed to be such a character in a String object");
            result ~= byteToHex(ch);
        }
        result ~= ">";
        return result;
    }

private:
    string _value;
}

class NameObject : PDFObject
{
public:
    this(string value)
    {
        // check validity of this name
        foreach(dchar ch; value) // auto-decoding here
            // Starting with PDF 1.2, the only character forbidden in a name is the null character
            assert(ch != 0);
        _value = value;
    }

    // Converts into bytes
    override void toBytes(PDFSerializer output)
    {   
        output.put("/");
        foreach(char ch; _value)
        {
            if (33 <= ch && ch <= 126)
                output.put(ch);
            else
            {
                output.put("#");

                // it is recommended that the sequence of bytes (after expansion
                // of #sequences, if any) be interpreted according to UTF-8)
                output.put(byteToHex(ch));
            }
        }
    }

private:
    string _value;
}

class ArrayObject : PDFObject
{
public:

    PDFObject[] items;

    this(PDFObject[] items = null)
    {
        this.items = items;
    }

    void add(PDFObject obj)
    {
        items ~= obj;
    }

    // Converts into bytes
    override void toBytes(PDFSerializer output)
    {
        output.put("[");
        foreach(int i, item; items)
        {
            if (i > 0)
                output.put(" ");
            item.toBytes(output);
        }
        output.put("]");
    }
}

class DictionaryObject : PDFObject
{
public:

    struct Entry
    {
        NameObject key;
        PDFObject value;
    }

    Entry[] entries; // Note: just a slice instead of an associative array

    this(Entry[] entries = null)
    {
        this.entries = entries;
    }

    void add(NameObject key, PDFObject value)
    {
        this.entries ~= Entry(key, value);
    }

    // Converts into bytes
    override void toBytes(PDFSerializer output)
    {   
        output.put("<< ");
        foreach(int i, entry; entries)
        {   
            entry.key.toBytes(output);
            output.put(" ");
            entry.value.toBytes(output);
            output.put(" ");
        }
        output.put(">>");
    }
}

class StreamObject : PDFObject
{
public:

    this(DictionaryObject dictionary, ubyte[] data)
    {
        this._data = data;
        this._dictionary = dictionary;
    }

    // Converts into bytes
    override void toBytes(PDFSerializer output)
    {   
        _dictionary.toBytes(output);
        output.put("stream\n");
        output.put(_data);
        output.put("endstream\n");
    }
private:
    ubyte[] _data;
    DictionaryObject _dictionary;
}

private
{
    string byteToHex(ubyte b)
    {
        static immutable hexChars = "0123456789ABCDEF";
        return "" ~ hexChars[b >> 4] ~ hexChars[b & 0x0f];
    }

    // PDF character sets

    bool isWhitespaceChar(dchar ch) pure nothrow @nogc
    {
        switch(ch)
        {
            case 0:
            case 9:
            case 10:
            case 12:
            case 13:
            case 32:
                return true;
            default:
                return false;
        }
    }

    bool isDelimiterChar(dchar ch) pure nothrow @nogc
    {
        switch(ch)
        {
            case ')':
            case '(':
            case '<':
            case '>':
            case '[':
            case ']':
            case '{':
            case '}':
            case '/':
            case '%':
                return true;
            default:
                return false;
        }
    }

    bool isRegularChar(dchar ch) pure nothrow @nogc
    {
        return !isWhitespaceChar(ch) && !isDelimiterChar(ch);
    }
}