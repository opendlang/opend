/++
Helpers for reading values from a given Ion token.

Authors: Harrison Ford
+/
module mir.ion.deser.text.readers;
import mir.ion.deser.text.tokenizer;
import mir.ion.deser.text.skippers;
import mir.ion.deser.text.tokens;
import std.traits : isInstanceOf;
import mir.appender : ScopedBuffer;

// MASSIVE TODO: check if we ever will run into the ScopedBuffers running out of memory!
// IIRC, they *do* not allocate above their max of 1024, so we may *need* to verify this is correct

/++
Read the contents of a given token from the input range.

$(WARNING This function does no checking if the current token
is the given function that you pass in. Use with caution.)
Params:
    t = The tokenizer
    token = The token type to read from the input range.
Returns:
    The string contents of the token given
+/
auto readValue(IonTokenType token)(ref IonTokenizer t) @nogc @safe pure
{
    import std.traits : EnumMembers;
    import std.string : chompPrefix;
    static foreach(i, member; EnumMembers!IonTokenType) {{
        static if (member != IonTokenType.TokenInvalid && member != IonTokenType.TokenEOF 
                    && member != IonTokenType.TokenFloatInf && member != IonTokenType.TokenFloatMinusInf
                    && member < IonTokenType.TokenComma) 
        {
            enum name = __traits(identifier, EnumMembers!IonTokenType[i]);
            static if (token == member) {
                t.finished = true;
                static if (member == IonTokenType.TokenDot) {
                    auto val = t.readSymbolOperator();
                }
                else {
                    auto val = mixin("t.read" ~ name.chompPrefix("Token") ~ "()");
                }
                return val;
            }
        }
    }}
    assert(0);
}
///
version(mir_ion_parser_test) unittest {
    import mir.ion.deser.text.tokenizer : tokenizeString;
    import mir.ion.deser.text.tokens : IonTokenType;

    void testVal(IonTokenType token)(string ts, string expected, char after) {
        auto t = tokenizeString(ts);
        assert(t.nextToken());
        assert(t.currentToken == token);
        auto v = readValue!(token)(t);
        assert(v.matchedText == expected);
        assert(t.readInput() == after);
    }
    with (IonTokenType) {
        testVal!(TokenNumber)("123123", "123123", 0);
    }
}

/++
Read a UTF-32 code-point from the input range (for clobs).
Params:
    t = The tokenizer
Returns:
    a UTF-32 code-point
+/
dchar readEscapedClobChar(ref IonTokenizer t) @nogc @safe pure {
    return readEscapedChar!(true)(t);
}

/++
Read out a UTF-32 code-point from a hex escape within our input range.

For simplicity's sake, this will return the largest type possible (a UTF-32 code-point).
Params:
    t = The tokenizer
Returns:
    a code-point representing the escape value that was read
Throws:
    MirIonTokenizerException if an invalid escape value was found.
+/
dchar readEscapedChar(bool isClob = false)(ref IonTokenizer t) @nogc @safe pure 
{
    dchar readHexEscapeLiteral(int length)() @nogc @safe pure { 
        dchar codePoint = 0, val;
        for (int i = 0; i < length; i++) {
            const(char) c = t.expect!isHexDigit;
            const(char) hexVal = hexLiteral(c);
            codePoint = (codePoint << 4) | hexVal; // TODO: is this correct?
        }
        val = codePoint;
        return val;
    }

    char c;
    static if (isClob) {
        c = t.expect!"a != 'U' && a != 'u'"; // cannot have unicode escapes within clobs
    } else {
        c = t.readInput();
    }

    switch (c) {
        case '0':
            // TODO: will this cause an error and make our code confused? 
            // \0 should not normally exist (except in it's escaped form) -- determine if this is expected behavior
            return '\0'; 
        static foreach(member; ['a', 'b', 't', 'n', 'f', 'r', 'v']) {
            case member:
                return mixin("'\\" ~ member ~ "'");
        }
        static foreach(member; ['?', '/', '\'', '"', '\\']) {
            case member:
                return member;
        }
        case 'U':
            return readHexEscapeLiteral!8;
        case 'u':
            return readHexEscapeLiteral!4;
        case 'x':
            return readHexEscapeLiteral!2;
        default:
            throw IonTokenizerErrorCode.invalidHexEscape.ionTokenizerException;
    }
}
/// Test reading a unicode escape
version(mir_ion_parser_test) unittest
{
    import mir.ion.deser.text.tokenizer : tokenizeString;
    import mir.ion.deser.text.tokens : MirIonTokenizerException;

    void test(string ts, dchar expected) {
        auto t = tokenizeString(ts);
        assert(t.readEscapedChar() == expected);
    }

    void testFail(string ts) {
        import std.exception : assertThrown;
        auto t = tokenizeString(ts);
        assertThrown!MirIonTokenizerException(t.readEscapedChar());
    }

    test("U0001F44D", '\U0001F44D');
    test("u2248", '\u2248');
    test("x20", '\x20');
    test("a", '\a');
    test("b", '\b');
    test("?", '?');
    test("\"", '"');
    test("0", '\0');

    testFail("c0101");
    testFail("d21231");
    testFail("!");
}

/++
Read a UTF-32 escape sequence, and return it as UTF-8 character(s).
Params:
    t = The tokenizer
Returns:
    A string containing the UTF-32 escape sequence, or nothing if we read a new-line.
    The length of the string is not well-defined, it can change depending on the escape sequence.
+/
size_t readEscapeSeq(bool isClob = false)(ref IonTokenizer t) @nogc @safe pure
{
    import std.utf : isValidDchar;
    import std.typecons : No;
    const(char) esc = t.peekOne();
    if (esc == '\n') {
        t.skipOne();
        return 0;
    }
    
    // I hate this, but apparently toUTF8 cannot take in a single UTF-32 code-point
    const(dchar) c = readEscapedChar!(isClob)(t); 
    // Extracted encode logic from std.utf.encode
    // Zero out the escape sequence (since we re-use this buffer)
    t.resetEscapeBuffer();
    if (c <= 0x7F)
    {
        assert(isValidDchar(c));
        t.escapeSequence[0] = cast(char) c;
        return 1;
    }
    if (c <= 0x7FF)
    {
        assert(isValidDchar(c));
        t.escapeSequence[0] = cast(char)(0xC0 | (c >> 6));
        t.escapeSequence[1] = cast(char)(0x80 | (c & 0x3F));
        return 2;
    }
    if (c <= 0xFFFF)
    {
        if (0xD800 <= c && c <= 0xDFFF)
            throw IonTokenizerErrorCode.encodingSurrogateCode.ionTokenizerException;

        assert(isValidDchar(c));
        t.escapeSequence[0] = cast(char)(0xE0 | (c >> 12));
        t.escapeSequence[1] = cast(char)(0x80 | ((c >> 6) & 0x3F));
        t.escapeSequence[2] = cast(char)(0x80 | (c & 0x3F));
        return 3;
    }
    if (c <= 0x10FFFF)
    {
        assert(isValidDchar(c));
        t.escapeSequence[0] = cast(char)(0xF0 | (c >> 18));
        t.escapeSequence[1] = cast(char)(0x80 | ((c >> 12) & 0x3F));
        t.escapeSequence[2] = cast(char)(0x80 | ((c >> 6) & 0x3F));
        t.escapeSequence[3] = cast(char)(0x80 | (c & 0x3F));
        return 4;
    }

    assert(!isValidDchar(c));
    throw IonTokenizerErrorCode.encodingInvalidCode.ionTokenizerException;
}

/++
    Read a non-quoted symbol from our input range.
    Params:
        t = The tokenizer
    Returns:
        A string containing the un-quoted symbol from the input range in the tokenizer.
+/
const(char)[] readSymbol(ref IonTokenizer t) @safe pure @nogc
{
    size_t end = 0, endPos = 0;
    const(char)[] window = t.window;

    if (window.length == 0) return null;
    foreach(c; window) {
        if (!c.isIdentifierPart()) {
            break;
        }
        end++;
    }

    endPos = t.position + end;
    if (end > t.window.length || endPos > t.input.length) {
        assert(0); // should never happen
    }

    window = t.input[t.position .. endPos];
    t.skipExactly(end);

    return cast(typeof(return)) window;
}
/// Test reading a symbol
version(mir_ion_parser_test) unittest
{
    import mir.ion.deser.text.tokenizer : tokenizeString;
    import mir.ion.deser.text.tokens : MirIonTokenizerException, IonTokenType;

    void test(string ts, string expected, IonTokenType after) {
        import std.exception : assertNotThrown;
        auto t = tokenizeString(ts); 
        assertNotThrown!MirIonTokenizerException(t.nextToken());
        assert(t.currentToken == IonTokenType.TokenSymbol);
        assert(t.readSymbol() == expected);
        assertNotThrown!MirIonTokenizerException(t.nextToken());
        assert(t.currentToken == after);
    }

    test("hello", "hello", IonTokenType.TokenEOF);
    test("a", "a", IonTokenType.TokenEOF);
    test("abc", "abc", IonTokenType.TokenEOF);
    test("null +inf", "null", IonTokenType.TokenFloatInf);
    test("false,", "false", IonTokenType.TokenComma);
    test("nan]", "nan", IonTokenType.TokenCloseBracket);
}

/++
Read a quoted symbol from our input range, 
and automatically decode any escape sequences found.
    
Params:
    t = The tokenizer
Returns:
    A string containing the quoted symbol.
+/
IonTextQuotedSymbol readSymbolQuoted(ref IonTokenizer t) @nogc @safe pure
{
    IonTextQuotedSymbol val;
    val.isFinal = true;
    size_t read, startIndex = t.position, endIndex = 0;
    loop: while (true) {
        char c = t.expect!"a != 0 && a != '\\n'";
        s: switch (c) {
            case '\'': // found the end 
                break loop;
            case '\\':
                if (read != 0) {
                    t.unread(c);
                    val.isFinal = false;
                    endIndex = t.position;
                    break loop;
                }

                size_t esc = t.readEscapeSeq();
                if (esc == 0) continue;
                val.matchedText = t.escapeSequence[0 .. esc];
                val.matchedIndex = startIndex;
                val.isEscapeSequence = true;
                val.isFinal = false;
                if (t.peekOne() == '\'') {
                    t.skipOne();
                    val.isFinal = true;
                }
                return val;
            default:
                read++;
                break s;
        }
    }

    if (endIndex == 0) {
        endIndex = t.position - 1;
    }

    val.matchedText = t.input[startIndex .. endIndex];
    val.matchedIndex = startIndex;
    return val;
}
/// Test reading quoted symbols
version(mir_ion_parser_test) unittest
{
    import mir.ion.deser.text.tokenizer : tokenizeString;
    import mir.ion.deser.text.tokens : IonTokenType;

    void test(string ts, string expected, char after) {
        auto t = tokenizeString(ts);
        assert(t.nextToken());
        assert(t.currentToken == IonTokenType.TokenSymbolQuoted);
        auto val = t.readSymbolQuoted();
        assert(val.matchedText == expected);
        assert(val.isFinal);
        assert(!val.isEscapeSequence);
        assert(t.readInput() == after);
    }

    void testMultipart(string ts, string expected1, string expected2, string expected3, char after) {
        auto t = tokenizeString(ts);
        assert(t.nextToken());
        assert(t.currentToken == IonTokenType.TokenSymbolQuoted);

        auto val = t.readSymbolQuoted();
        assert(val.matchedText == expected1);
        assert(!val.isFinal);

        auto val2 = t.readSymbolQuoted();
        assert(val2.matchedText == expected2);
        assert(!val2.isFinal);

        auto val3 = t.readSymbolQuoted();
        assert(val3.matchedText == expected3);
        assert(val3.isFinal);
        assert(t.readInput() == after);
    }

    test("'a'", "a", 0);
    test("'a b c'", "a b c", 0);
    test("'null' ", "null", ' ');
    test("'false',", "false", ',');
    test("'nan']", "nan", ']');

    testMultipart("'a\\'b'", "a", "'", "b", 0);
    testMultipart(`'a\nb'`, "a", "\n", "b", 0);
    testMultipart("'a\\\\b'", "a", "\\", "b", 0);
    testMultipart(`'a\x20b'`, "a", " ", "b", 0);
    testMultipart(`'a\u2248b'`, "a", "≈", "b", 0);
    testMultipart(`'a\U0001F44Db'`, "a", "👍", "b", 0);
}

/++
Read a symbol operator from the input range.
Params:
    t = The tokenizer
Returns:
    A string containing any symbol operators that were able to be read.
+/
IonTextSymbolOperator readSymbolOperator(ref IonTokenizer t) @safe @nogc pure
{
    IonTextSymbolOperator val;
    size_t startIndex = t.position;
    val.matchedIndex = startIndex;
    char c = t.peekOne();
    while (c.isOperatorChar()) {
        t.skipOne();
        c = t.peekOne();
    }

    val.matchedText = t.input[startIndex .. t.position - 1];
    return val;
}

/++
Read a string from the input range and automatically decode any UTF escapes.
Params:
    longString = Is this string a 'long' string, defined by 3 single-quotes?
    isClob = Is this string allowed to have UTF escapes?
    t = The tokenizer
Returns:
    The string's content from the input range.
+/
auto readString(bool longString = false, bool isClob = false)(ref IonTokenizer t) @safe @nogc pure
{
    static if (isClob) {
        IonTextClob val;
    } else {
        IonTextString val;
    } 

    val.isFinal = true;
    static if (longString && !isClob) {
        val.isLongString = true;
    }

    size_t read = 0, startIndex = t.position, endIndex = 0;
    loop: while (true) {
        char c = t.expect!"a != 0";
        t.expectFalse!(isInvalidChar, true)(c);

        static if (!longString) {
            t.expectFalse!(isNewLine, true)(c);
        }

        static if (isClob) {
            t.expectFalse!(isInvalidChar, true)(c);
            t.expect!(isASCIIChar, true)(c);
        }

        s: switch (c) {
            static if (!longString) {
                case '"':
                    break loop;
            } else {
                static if (!isClob) {
                    case '\r':
                        if (read != 0) {
                            t.unread(c);
                            endIndex = t.position;
                            val.isFinal = false;
                            break loop;
                        }

                        const(char)[] v = t.peekMax(1);
                        if (v.length == 1 && v[0] == '\n') { // see if this is \r\n or just \r
                            t.skipOne();
                        }

                        t.resetEscapeBuffer();
                        t.escapeSequence[0] = '\n';
                        val.matchedText = t.escapeSequence[0 .. 1];
                        val.isNormalizedNewLine = true;
                        val.isFinal = false;

                        // do the same check, and see if this string ends *directly* after this newline
                        // again, peekExactly is acceptable here because the long string *MUST* end with
                        // a sequence of 3 quotes, and we should throw if it's not there.
                        if (t.peekExactly(3) == "'''") {
                            // consume, and skip whitespace
                            assert(t.skipExactly(3)); // consume the first quote mark
                            val.isFinal = true;
                            c = t.skipWhitespace!(true, false);
                            t.unread(c);
                        }
                        return val;
                }
                case '\'':
                    const(char)[] v = t.peekMax(2);
                    if (v.length != 2) {
                        goto default;
                    } else {
                        if (v != "''") { // TODO: ugly, fix
                            goto default;
                        }
                    }
                    val.isFinal = true;
                    endIndex = t.position - 1;
                    static if (isClob) {
                        if (t.skipWhitespace!(false, true)) {
                            break loop;
                        } else {
                            break s;
                        }
                    } else {
                        t.skipExactly(2);
                        break loop;
                    }
            }
            case '\\':
                if (read != 0) {
                    t.unread(c);
                    endIndex = t.position;
                    val.isFinal = false;
                    break loop;
                }
                
                size_t esc = readEscapeSeq!(isClob)(t);
                static if (isClob) {
                    assert(esc == 1); // this should throw *way* earlier, just a sanity check 
                } else {
                    assert(esc <= 4); // sanity check that we do not have an escape larger then 4 chars
                }
                
                val.matchedText = t.escapeSequence[0 .. esc];
                val.matchedIndex = startIndex;
                val.isEscapeSequence = true;
                val.isFinal = false;
                // check if the string ends *directly* after this escape,
                // if so, just consume the quotations, and call it a day
                static if (longString) {
                    // if this is a long string, there should be *at least* 3 extra
                    // characters left (for the ending quotes). this will throw 
                    // if they are not there.
                    if (t.peekExactly(3) == "'''") { 
                        // consume, and skip whitespace
                        assert(t.skipExactly(3));
                        val.isFinal = true;
                        static if (isClob) {
                            c = t.skipWhitespace!(false, true);
                        } else {
                            c = t.skipWhitespace!(true, false);
                        }
                        t.unread(c);
                    }
                } else {
                    if (t.peekOne() == '"') {
                        assert(t.skipOne());
                        val.isFinal = true;
                    }
                }
                if (esc >= 1) {
                    val.escapeSequenceType = IonTextEscapeType.UTF;
                } else {
                    val.escapeSequenceType = IonTextEscapeType.Hex;
                }
                return val;
                //break s;
            default:
                read++;
                break s;
        }
    }

    if (endIndex == 0) {
        endIndex = t.position - 1;
    }

    val.matchedText = t.input[startIndex .. endIndex];
    val.matchedIndex = startIndex;
    return val;
}
/// Test reading a string
version(mir_ion_parser_test) unittest
{
    import mir.ion.deser.text.tokenizer : tokenizeString;
    import mir.ion.deser.text.tokens : IonTokenType;

    void test(string ts, string expected, char after) {
        auto t = tokenizeString(ts);
        assert(t.nextToken());
        assert(t.currentToken == IonTokenType.TokenString);
        auto str = t.readString();
        assert(str.matchedText == expected);
        assert(t.readInput() == after);
    }

    void testMultiPart(string ts, string expected, string after, char last) {
        auto t = tokenizeString(ts);

        assert(t.nextToken());
        assert(t.currentToken == IonTokenType.TokenString);
        auto str = t.readString();
        assert(str.matchedText == expected);
        assert(!str.isEscapeSequence);
        assert(!str.isFinal);

        auto str2 = t.readString();
        assert(str2.matchedText == after);
        assert(str2.isEscapeSequence);
        assert(str2.isFinal);
        assert(t.readInput() == last);
    }

    test(`"Hello, world"`, "Hello, world", 0);
    testMultiPart(`"Hello! \U0001F44D"`, "Hello! ", "👍", 0);
    test(`"0xFOOBAR",`, "0xFOOBAR", ',');
}

/++
Read a long string (defined by having three single quotes surrounding it's contents).

$(NOTE If this function encounters another long string in the input range separated by whitespace, 
it will concatenate the contents of the two long strings together. This is not implementation-specific,
rather, part of the Ion specification)

Params:
    t = The tokenizer
Returns:
    A string holding the contents of any long strings found.
+/
IonTextString readLongString(ref IonTokenizer t) @safe @nogc pure
{
    return readString!(true)(t);
}
/// Test reading a long string
version(mir_ion_parser_test) unittest
{
    import mir.ion.deser.text.tokenizer : tokenizeString;
    import mir.ion.deser.text.tokens : IonTokenType;

    void test(string ts, string expected, char after) {
        auto t = tokenizeString(ts);
        assert(t.nextToken());
        assert(t.currentToken == IonTokenType.TokenLongString);
        auto str = t.readLongString();
        assert(str.matchedText == expected);
        assert(t.readInput() == after);
        assert(str.isFinal);
    }

    void testMultiPart(string ts, string expected1, string expected2, char after) {
        auto t = tokenizeString(ts);
        assert(t.nextToken());
        assert(t.currentToken == IonTokenType.TokenLongString);

        auto str = t.readLongString();
        assert(str.matchedText == expected1);
        assert(str.isFinal);

        assert(t.nextToken());
        assert(t.currentToken == IonTokenType.TokenLongString);
        auto str2 = t.readLongString();
        assert(str2.matchedText == expected2);
        assert(t.readInput() == after);
        assert(str.isFinal);
    }

    void testNewLine(string ts, string expected1, string expected2, bool normalized, bool eofFinal, char after) {
        auto t = tokenizeString(ts);
        assert(t.nextToken());
        assert(t.currentToken == IonTokenType.TokenLongString);
        auto str = t.readLongString();
        assert(str.matchedText == expected1);
        if (normalized) {
            assert(!str.isFinal);
            auto str1 = t.readLongString();
            assert(str1.isNormalizedNewLine);
            assert(str1.matchedText == "\n");
            if (eofFinal) {
                assert(str1.isFinal);
                assert(t.nextToken());
                assert(t.currentToken == IonTokenType.TokenLongString);
            } else {
                assert(!str1.isFinal);
            }
        } else {
            assert(str.isFinal);
            assert(t.nextToken());
            assert(t.currentToken == IonTokenType.TokenLongString);
        }
        auto str1 = t.readLongString();
        assert(str1.matchedText == expected2);
        assert(str1.isFinal);
        assert(t.readInput() == after);
    }

    test(`'''Hello, world'''`, "Hello, world", 0);
    testMultiPart(`'''Hello! ''''''\U0001F44D'''`, "Hello! ", "👍", 0);
    test(`'''0xFOOBAR''',`, "0xFOOBAR", ',');
    test(`'''Hello, 'world'!'''`, "Hello, \'world\'!", 0);
    testMultiPart(`'''Hello,'''''' world!'''`, "Hello,", " world!", 0);
    testMultiPart(`'''Hello,'''     ''' world!'''`, "Hello,", " world!", 0);
    // Test the normalization of new-lines in long strings here.
    testNewLine("'''Hello, \r\n''' '''world!'''", "Hello, ", "world!", true, true, 0); // normalized, crlf precedes end of string
    testNewLine("'''Hello, \r\n world!'''", "Hello, ", " world!", true, false, 0); // normalized, but there is extra text
    testNewLine("'''Hello, \n''' '''world!'''", "Hello, \n", "world!", false, false, 0); // not normalized, no extra text
    testNewLine("'''Hello, \r''' '''world!'''", "Hello, ", "world!", true, true, 0); // normalized, crlf precedes end of string
    testNewLine("'''Hello, \r \nworld!'''", "Hello, ", " \nworld!", true, false, 0); // normalized, but there is extra text
}

/++
Read the contents of a clob, and return it as an untyped array.

$(NOTE As per Ion specification, a clob does not contain Base64 data. Use readBlob if you are expecting to decode Base64 data.)

Params:
    longClob = Should this function concatenate the contents of multiple clobs within the brackets?
    t = The tokenizer
Returns:
    An untyped array containing the contents of the clob. This array is guaranteed to have no UTF-8/UTF-32 characters -- only ASCII characters.
+/

IonTextClob readClob(bool longClob = false)(ref IonTokenizer t) @safe @nogc pure
{
    // Always read out bytes, as clobs are octet-based (and not necessarily a string)
    auto data = readString!(longClob, true)(t);
    static if (longClob) {
        data.isLongClob = true;
    }
    // read out the following }}
    char c = t.expect!("a == '}'", true)(t.skipLobWhitespace()); // after skipping any whitespace, it should be the terminator ('}')
    c = t.expect!"a == '}'"; // and no whitespace should between one bracket and another

    t.finished = true; // we're done reading!
    return data;
}
/// Test reading a short clob
version(mir_ion_parser_test) unittest
{
    import mir.ion.deser.text.tokenizer : tokenizeString;
    import mir.ion.deser.text.tokens : IonTokenType;

    void test(string ts, string expected, char after) {
        auto t = tokenizeString(ts);
        assert(t.nextToken());
        assert(t.currentToken == IonTokenType.TokenString);
        assert(t.readClob().matchedText == expected);
        assert(t.readInput() == after);
    }

    test(`"Hello, world"}}`, "Hello, world", 0);
    test(`"0xF00BAR"}}, `, "0xF00BAR", ',');
}

/++
Helper to read a long clob from the input stream.

See [readClob] for any notes.
Params:
    t = The tokenizer
Returns:
    An untyped array holding the contents of the clob.
+/
IonTextClob readLongClob(ref IonTokenizer t) @safe @nogc pure
{
    return readClob!(true)(t);
}

/++
Read a blob from the input stream, and return the Base64 contents.

$(NOTE This function does not verify if the Base64 contained is valid, or if it is even Base64.)
Params:
    t = The tokenizer
Returns:
    An untyped array containing the Base64 contents of the blob.
+/
IonTextBlob readBlob(ref IonTokenizer t) @safe @nogc pure
{
    IonTextBlob val;
    size_t startIndex = t.position;
    char c;
    while (true) {
        c = t.expect!("a != 0", true)(t.skipLobWhitespace());
        if (c == '}') {
            break;
        }
    }

    c = t.expect!"a == '}'";
    t.finished = true;
    val.matchedText = t.input[startIndex .. t.position - 1];
    val.matchedIndex = startIndex;
    return val;
}
/++
Read a number from the input stream, and return the type of number, as well as the number itself.

Params:
    t = The tokenizer
Returns:
    A struct holding the type and value of the number.
    See the examples below on how to access the type/value.
+/

IonTextNumber readNumber(ref IonTokenizer t) @safe @nogc pure
{
    import mir.ion.type_code : IonTypeCode;
    IonTextNumber num;
    size_t startIndex = t.position;

    void readExponent() @safe @nogc pure {
        char c = t.readInput();
        if (c == '+' || c == '-') {
            c = t.expect!"a != 0";
        }

        readDigits(t, c);
    }

    char c = t.readInput();
    if (c == '-') {
        startIndex++;
        c = t.readInput();
        if (c == 0) {
            num.type = IonTypeCode.null_;
            return num;
        } else {
            num.type = IonTypeCode.nInt;
        }
    } else {
        num.type = IonTypeCode.uInt;
    }

    immutable char leader = c;
    const(char)[] digits = readDigits(t, leader);
    if (leader == '0') {
        if (digits.length != 1) { // if it is not just a plain 0, fail since we don't support leading zeros
            throw IonTokenizerErrorCode.invalidLeadingZeros.ionTokenizerException;
        }
    }

    if (t.readInput() == '.') {
        num.type = IonTypeCode.decimal;
        immutable char decimalLeader = t.expect!"a != 0";
        readDigits(t, decimalLeader);
    }

    switch (t.readInput()) {
        case 'e':
        case 'E':
            num.type = IonTypeCode.float_;
            readExponent();
            break;
        case 'd':
        case 'D':
            num.type = IonTypeCode.decimal;
            readExponent();
            break;
        default:
            break;
    }

    c = t.expect!(t.isStopChar);
    t.unread(c);
    num.matchedText = t.input[startIndex .. t.position];
    num.matchedIndex = startIndex;

    return num; 
}
/// Test reading numbers
version(mir_ion_parser_test) unittest
{
    import mir.ion.deser.text.tokenizer : tokenizeString;
    import mir.ion.deser.text.tokens : IonTokenType;
    import mir.ion.type_code : IonTypeCode;

    void test(string ts, string expected, IonTypeCode type, char after) {
        auto t = tokenizeString(ts);
        assert(t.nextToken());
        assert(t.currentToken == IonTokenType.TokenNumber);
        auto n = t.readNumber();
        assert(n.matchedText == expected);
        assert(n.type == type);
        assert(t.readInput() == after);
    }

    test("12341", "12341", IonTypeCode.uInt, 0);
    test("-12312", "12312", IonTypeCode.nInt, 0);
    test("0.420d2", "0.420d2", IonTypeCode.decimal, 0);
    test("1.1999999999999999555910790149937383830547332763671875e0", 
         "1.1999999999999999555910790149937383830547332763671875e0", IonTypeCode.float_, 0);
    test("1.1999999999999999e0, ", "1.1999999999999999e0", IonTypeCode.float_, ',');
}

/++
Read as many digits from the input stream as possible, given the first digit of the digits.

This function will stop reading digits as soon as whitespace is hit.
Params:
    t = The tokenizer
    leader = The leading digit in a sequence of digits following
    buf = The appender on which this function will put it's output
Returns:
    A character located after it has read every single digit in a sequence.
+/
const(char)[] readDigits(ref IonTokenizer t, char leader) @safe @nogc pure
{
    immutable char c = leader;
    if (!isDigit(c)) {
        throw IonTokenizerErrorCode.expectedValidLeader.ionTokenizerException;
    }
    t.unread(c); // unread so the readRadixDigits can consume it
    return readRadixDigits(t);
}

/++
Read as many digits from the input stream as possible, given a validator.

This function will stop reading digits as soon as the validator returns false.
Params:
    isValid = The validation function which is called to determine if the reader should halt.
    t = The tokenizer
    buf = The appender on which this function will put it's output
Returns:
    A character located after it has read every single digit in a sequence.
+/
const(char)[] readRadixDigits(alias isValid = isDigit)(ref IonTokenizer t) 
{
    import mir.functional : naryFun;
    size_t startIndex = t.position;
    while (true) {
        char c = t.readInput();
        if (c == '_') {
            t.expect!(isValid, true)(t.peekOne());
        }

        if (!naryFun!isValid(c)) {
            t.unread(c);
            return t.input[startIndex .. t.position];
        }
    }
}

/++
Read a radix number, given two validation functions for it's marker and the validity of each digit read.

Params:
    isMarker = A validation function to check if the marker is valid (0b/0x/etc)
    isValid = A validation function to check if every digit found is valid (0-1/0-9A-F/etc)
    t = The tokenizer
Returns:
    A string containing the full radix number (including the leading 0 and marker).
+/
const(char)[] readRadix(alias isMarker, alias isValid)(ref IonTokenizer t) @safe @nogc pure
{
    size_t startIndex = t.position;
    char c = t.readInput();
    if (c == '-') {
        c = t.readInput();
    }

    // 0
    t.expect!("a == '0'", true)(c);
    // 0(b || x)
    c = t.expect!isMarker;
    t.expect!("a != '_'", true)(t.peekOne()); // cannot be 0x_ or 0b_
    const(char)[] val = readRadixDigits!(isValid)(t);
    c = t.expect!(t.isStopChar);
    t.unread(c);

    return t.input[startIndex .. t.position];
}

/++
Read a binary number (marked by '0b') from the input stream.

Params:
    t = The tokenizer
Returns:
    A string containing the entire binary number read.
+/
const(char)[] readBinary(ref IonTokenizer t) @safe @nogc pure
{
    return readRadix!("a == 'b' || a == 'B'", "a == '0' || a == '1'")(t);
}
/// Test reading a binary number
version(mir_ion_parser_test) unittest
{
    import mir.ion.deser.text.tokenizer : tokenizeString;
    import mir.ion.deser.text.tokens : IonTokenType;

    void test(string ts, string expected, char after) {
        auto t = tokenizeString(ts);
        assert(t.nextToken());
        assert(t.currentToken == IonTokenType.TokenBinary);
        assert(t.readBinary() == expected);
        assert(t.readInput() == after);
    }

    test("0b101011010", "0b101011010", 0);
    test("0b100000101000001010000010100000101000001 ", "0b100000101000001010000010100000101000001", ' ');
    test("0b11011110101011011011111011101111,", "0b11011110101011011011111011101111", ',');
    test("      0b11011110101011011011111011101111,", "0b11011110101011011011111011101111", ',');  
}

/++
Read a hex number (marked by '0x') from the input stream.

Params:
    t = The tokenizer
Returns:
    A string containing the entire hex number read.
+/
const(char)[] readHex(ref IonTokenizer t) @safe @nogc pure
{
    return readRadix!("a == 'x' || a == 'X'", isHexDigit)(t);
}
/// Test reading a hex number
version(mir_ion_parser_test) unittest
{
    import mir.ion.deser.text.tokenizer : tokenizeString;
    import mir.ion.deser.text.tokens : IonTokenType;

    void test(string ts, string expected, char after) {
        auto t = tokenizeString(ts);
        assert(t.nextToken());
        assert(t.currentToken == IonTokenType.TokenHex);
        assert(t.readHex() == expected);
        assert(t.readInput() == after);
    } 

    void testMultipart(string ts, string expected1, char after, string expected2) {
        auto t = tokenizeString(ts);
        assert(t.nextToken());
        assert(t.currentToken == IonTokenType.TokenHex);
        assert(t.readHex() == expected1);
        assert(t.readInput() == after);
        assert(t.readHex() == expected2);
    }

    test("0xBADBABE", "0xBADBABE", 0);
    test("0x414141", "0x414141", 0);
    test("0x0", "0x0", 0);
    test("     0x414141", "0x414141", 0);
    test("     0x414141,", "0x414141", ',');
    testMultipart("     0x414141,0x414142", "0x414141", ',', "0x414142");
}

/++
Read a ISO-8601 extended timestamp from the input stream.

$(NOTE This function does some rudimentary checks to see if the timestamp is valid,
but it does nothing more then that.)

Params:
    t = The tokenizer
Returns:
    A string containing the entire timestamp read from the input stream.
+/

IonTextTimestamp readTimestamp(ref IonTokenizer t) @safe @nogc pure 
{
    IonTextTimestamp val;
    size_t startIndex = t.position;

    char readTSDigits(int nums) @safe @nogc pure {
        for (int i = 0; i < nums; i++) {
            t.expect!isDigit;
        }
        return t.readInput();
    }

    char readTSOffset(char c) @safe @nogc pure {
        if (c != '-' && c != '+') {
            return c; 
        }
        const(char) cs = t.expect!("a == ':'", true)(readTSDigits(2));
        return readTSDigits(2);
    }

    char readTSOffsetOrZ(char c) @safe @nogc pure {
        t.expect!("a == '-' || a == '+' || a == 'z' || a == 'Z'", true)(c);
        if (c == '-' || c == '+') {
            return readTSOffset(c);
        }
        if (c == 'z' || c == 'Z') {
            return t.readInput();
        }
        assert(0);
    }

    IonTextTimestamp readTSFinish(char c) @safe @nogc pure {
        t.expect!(t.isStopChar, true)(c);
        t.unread(c);
        val.matchedIndex = startIndex;
        val.matchedText = t.input[startIndex .. t.position];
        return val;
    }

    // yyyy(T || -)
    char c = t.expect!("a == 'T' || a == '-'", true)(readTSDigits(4));
    if (c == 'T') {
        // yyyyT
        val.matchedText = t.input[startIndex .. t.position];
        return val;
    }
    // yyyy-mm(T || -)
    c = t.expect!("a == 'T' || a == '-'", true)(readTSDigits(2));
    if (c == 'T') {
        val.matchedText = t.input[startIndex .. t.position];
        return val;
    }
    // yyyy-mm-dd(T)?
    c = readTSDigits(2);
    if (c != 'T') {
        return readTSFinish(c);
    }
    // yyyy-mm-ddT 
    c = t.readInput();
    if (!c.isDigit()) {
        // yyyy-mm-ddT(+ || -)hh:mm
        c = readTSOffset(c);
        return readTSFinish(c);
    }
    // yyyy-mm-ddThh
    c = t.expect!("a == ':'", true)(readTSDigits(1));
    // yyyy-mm-ddThh:mm
    c = readTSDigits(2);
    if (c != ':') {
        // yyyy-mm-ddThh:mm(+-|Z)
        c = readTSOffsetOrZ(c);
        return readTSFinish(c);
    }

    // yyyy-mm-ddThh:mm:ss
    c = readTSDigits(2);

    if (c != '.') {
        // yyyy-mm-ddThh:mm:ssZ
        c = readTSOffsetOrZ(c);
        return readTSFinish(c);
    }

    // yyyy-mm-ddThh:mm:ss.ssssZ
    c = t.readInput();
    if (c.isDigit()) {
        readDigits(t, c);
    }

    c = readTSOffsetOrZ(t.readInput());
    return readTSFinish(c);
}
/// Test reading timestamps
version(mir_ion_parser_test) unittest
{
    import mir.ion.deser.text.tokenizer : tokenizeString;
    import mir.ion.deser.text.tokens : IonTokenType;

    void test(string ts, string expected, char after) {
        auto t = tokenizeString(ts);
        assert(t.nextToken());
        assert(t.currentToken == IonTokenType.TokenTimestamp);
        assert(t.readTimestamp().matchedText == expected);
        assert(t.readInput() == after);
    } 

    test("2001T", "2001T", 0);
    test("2001-01T,", "2001-01T", ',');
    test("2001-01-02}", "2001-01-02", '}');
    test("2001-01-02T ", "2001-01-02T", ' ');
    test("2001-01-02T+00:00\t", "2001-01-02T+00:00", '\t');
    test("2001-01-02T-00:00\n", "2001-01-02T-00:00", '\n');
    test("2001-01-02T03:04+00:00 ", "2001-01-02T03:04+00:00", ' ');
    test("2001-01-02T03:04-00:00 ", "2001-01-02T03:04-00:00", ' ');
    test("2001-01-02T03:04Z ", "2001-01-02T03:04Z", ' ');
    test("2001-01-02T03:04z ", "2001-01-02T03:04z", ' ');
    test("2001-01-02T03:04:05Z ", "2001-01-02T03:04:05Z", ' ');
    test("2001-01-02T03:04:05+00:00 ", "2001-01-02T03:04:05+00:00", ' ');
    test("2001-01-02T03:04:05.666Z ", "2001-01-02T03:04:05.666Z", ' ');
    test("2001-01-02T03:04:05.666666z ", "2001-01-02T03:04:05.666666z", ' ');
}
