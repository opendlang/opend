module pdfd.objects;

import std.conv;

/// Root class of PDF objects
class PDFObject
{
public:
    // Converts into bytes
    abstract void toBytes(ref string output);

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

    string toIndirectReference() pure const
    {
        return to!string(identifier) ~ " 0 R";
    }

    // Converts into bytes
    override void toBytes(ref string output)
    {
        output ~= to!string(identifier) ~ " 0 obj\n";
        _obj.toBytes(output);
        output ~= "endobj\n";
    }

private:
    PDFObject _obj;
    int _identifier;
}

class NullObject : PDFObject
{
public:
    override void toBytes(ref string output)
    {
        output ~= "null";
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
    override void toBytes(ref string output)
    {
        // TODO: round to decimal form
        output ~= to!string(_value);
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
    override void toBytes(ref string output)
    {
        // TODO: round to decimal form
        output ~= escapeString(_value);
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
    override void toBytes(ref string output)
    {   
        string result = "/";
        foreach(char ch; _value)
        {
            if (33 <= ch && ch <= 126)
                result ~= ch;
            else
            {
                result ~= '#';

                // it is recommended that the sequence of bytes (after expansion
                // of #sequences, if any) be interpreted according to UTF-8)
                result ~= byteToHex(ch);                 
            }

        }
        result ~= ">";
        output ~= result;
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

    // Converts into bytes
    override void toBytes(ref string output)
    {   
        string result = "[";
        foreach(int i, item; items)
        {
            if (i > 0)
                result ~= " "; // separator
            item.toBytes(result);
        }
        result ~= "]";        
        output ~= result;        
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

    // Converts into bytes
    override void toBytes(ref string output)
    {   
        string result = "<< ";
        foreach(int i, entry; entries)
        {   
            entry.key.toBytes(result);
            result ~= " ";
            entry.value.toBytes(result);
            result ~= " ";
        }
        result ~= ">>";        
        output ~= result;        
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
    override void toBytes(ref string output)
    {   
        _dictionary.toBytes(output);
        string result = "stream\n";
        output ~= cast(string)_data;
        result ~= "endstream\n";        
        output ~= result;        
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