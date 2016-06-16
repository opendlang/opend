module pdfd.objects;

import std.conv;

/// Root class of PDF objects
class PDFObject
{
public:
/*
    /// Create a PDF object with a given name.
    this(int name)
    {
        _name = name;
    }*/

    /// Returns the object generation, not much used.
    int generation()
    {
        return 0;
    }

    // Converts into bytes
    abstract void toBytes(ref string output);

private:

    /// Object name, is an unique identifier in the document.
    int _name;
}


class BooleanObject : PDFObject
{
public:
    this(bool value)
    {
        _value = value;
    }

    // Converts into bytes
    override void toBytes(ref string output)
    {
        output ~= _value ? "true" : "false";
    }

private:
    bool _value;
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
        return result;
    }

private:
    string _value;
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