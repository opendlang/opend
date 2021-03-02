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
string readValue(T)(ref T t, IonTokenType token) 
if (isInstanceOf!(IonTokenizer, T) && is(T.inputType == ubyte)) {
    string val;

    with(IonTokenType) switch (token) {
        case TokenSymbol:
            val = t.readSymbol();
            break;
        case TokenSymbolQuoted:
            val = t.readSymbolQuoted();
            break;
        case TokenSymbolOperator:
        case TokenDot:
            val = t.readSymbolOperator();
            break;
        case TokenString:
            val = t.readString();
            break;
        case TokenLongString:
            val = t.readLongString();
            break;
        case TokenNumber:
            val = t.readNumber();
            break;
        case TokenBinary:
            val = t.readBinary();
            break;
        case TokenHex:
            val = t.readHex();
            break;
        case TokenTimestamp:
            val = t.readTimestamp();
            break;
        default:
            assert(0, "Unsupported token");
    }

    t.finished = true;
    return val;
}

/++
Read a UTF-32 code-point from the input range (for clobs).
Params:
    t = The tokenizer
Returns:
    a UTF-32 code-point
+/
dchar readEscapedClobChar(T)(ref T t) {
    return readEscapedChar!(T, true)(t);
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
dchar readEscapedChar(T, bool isClob = false)(ref T t) 
if (isInstanceOf!(IonTokenizer, T) && is(T.inputType == ubyte)) {
    dchar readHexEscapeLiteral(int length)() { 
        typeof(return) val;
        dchar codePoint = 0;
        for (int i = 0; i < length; i++) {
            const(ubyte) c = t.expect!isHexDigit;
            const(ubyte) hexVal = hexLiteral(c);
            codePoint = (codePoint << 4) | hexVal; // TODO: is this correct?
        }
        val = codePoint;
        return val;
    }

    T.inputType c;
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
            import mir.format : text;
            throw new MirIonTokenizerException(text("bad escape 0x", c, " (location: ", t.position, ")"));
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
string readEscapeSeq(T, bool isClob = false)(ref T t)
if (isInstanceOf!(IonTokenizer, T) && is(T.inputType == ubyte)) {
    import std.utf : toUTF8;
    const(ubyte) esc = t.peekOne();
    if (esc == '\n') {
        t.skipOne();
        return "";
    }

    // I hate this, but apparently toUTF8 cannot take in a single UTF-32 code-point
    dchar[] r = [readEscapedChar!(T, isClob)(t)]; 
    return r.toUTF8();
}

/++
    Read a non-quoted symbol from our input range.
    Params:
        t = The tokenizer
    Returns:
        A string containing the un-quoted symbol from the input range in the tokenizer.
+/
string readSymbol(T)(ref T t) 
if (isInstanceOf!(IonTokenizer, T) && is(T.inputType == ubyte)) {
    ScopedBuffer!char buf;
    l: while (true) {
        // TODO: can modify this for chunking
        T.inputType[] cbuf = t.peekMax(1); 
        if (cbuf.length == 0) break l;
        foreach(c; cbuf) {
            if (!c.isIdentifierPart()) break l;
            buf.put(c);
            t.skipOne();
        }
    }

    return buf.data.idup;
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
string readSymbolQuoted(T)(ref T t) 
if (isInstanceOf!(IonTokenizer, T) && is(T.inputType == ubyte)) {
    ScopedBuffer!char buf;
    while (true) {
        T.inputType c = t.expect!"a != 0 && a != '\\n'";
        switch (c) {
            case '\'': // found the end 
                return buf.data.idup;
            case '\\':
                string esc = t.readEscapeSeq();
                if (esc == "") continue;
                buf.put(esc);
                break;
            default:
                buf.put(cast(char)c);
                break;
        }
    }
}
/// Test reading quoted symbols
version(mir_ion_parser_test) unittest
{
    import mir.ion.deser.text.tokenizer : tokenizeString;
    import mir.ion.deser.text.tokens : IonTokenType;

    void test(string ts, string expected, ubyte after) {
        auto t = tokenizeString(ts);
        assert(t.nextToken());
        assert(t.currentToken == IonTokenType.TokenSymbolQuoted);
        assert(t.readSymbolQuoted() == expected);
        assert(t.readInput() == after);
    }

    test("'a'", "a", 0);
    test("'a b c'", "a b c", 0);
    test("'null' ", "null", ' ');
    test("'false',", "false", ',');
    test("'nan']", "nan", ']');

    test("'a\\'b'", "a'b", 0);
    test("'a\\\nb'", "ab", 0);
    test("'a\\\\b'", "a\\b", 0);
    test("'a\x20b'", "a b", 0);
    test("'a\\u2248b'", "a≈b", 0);
    test("'a\\U0001F44Db'", "a👍b", 0);
}

/++
Read a symbol operator from the input range.
Params:
    t = The tokenizer
Returns:
    A string containing any symbol operators that were able to be read.
+/
string readSymbolOperator(T)(ref T t) 
if (isInstanceOf!(IonTokenizer, T) && is(T.inputType == ubyte)) {
    ScopedBuffer!char buf;
    T.inputType c = t.peekOne();
    while (c.isOperatorChar()) {
        buf.put(c);
        t.skipOne();
        c = t.peekOne();
    }

    return buf.data.idup;
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
const(char)[] readString(T, bool longString = false, bool isClob = false)(ref T t)
if (isInstanceOf!(IonTokenizer, T) && is(T.inputType == ubyte)) {
    ScopedBuffer!char buf;
    while (true) {
        T.inputType c = t.expect!"a != 0";
        t.expectFalse!(isInvalidChar, true)(c);

        static if (!longString) {
            t.expect!("a != '\\n'", true)(c);
        }

        static if (isClob) {
            t.expectFalse!(isInvalidChar, true)(c);
            t.expect!(isASCIIChar, true)(c);
        }

        s: switch (c) {
            static if (!longString) {
                case '"':
                    return buf.data.idup;
            } else {
                case '\'':
                    const(T.inputType[]) v = t.peekMax(2);
                    if (v.length != 2) {
                        goto default;
                    } else {
                        if (v != ['\'', '\'']) { // TODO: ugly, fix
                            goto default;
                        }
                    }
                    static if (isClob) {
                        if (t.skipLobWhitespace!(false, true)) { // fail on comments
                            return buf.data.idup;
                        }
                    } else {
                        if (t.skipLongStringEnd()) {
                            return buf.data.idup;
                        }
                    }
                    break s;
            }
            case '\\':
                string esc = readEscapeSeq!(T, isClob)(t);
                buf.put(esc);
                break s;
            default:
                buf.put(c);
                break s;
        }
    }
    assert(0);
}
/// Test reading a string
version(mir_ion_parser_test) unittest
{
    import mir.ion.deser.text.tokenizer : tokenizeString;
    import mir.ion.deser.text.tokens : IonTokenType;

    void test(string ts, string expected, ubyte after) {
        auto t = tokenizeString(ts);
        assert(t.nextToken());
        assert(t.currentToken == IonTokenType.TokenString);
        assert(t.readString() == expected);
        assert(t.readInput() == after);
    }

    test(`"Hello, world"`, "Hello, world", 0);
    test(`"Hello! \U0001F44D"`, "Hello! 👍", 0);
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
const(char)[] readLongString(T)(ref T t)
if (isInstanceOf!(IonTokenizer, T) && is(T.inputType == ubyte)) {
    return readString!(T, true)(t);
}
/// Test reading a long string
version(mir_ion_parser_test) unittest
{
    import mir.ion.deser.text.tokenizer : tokenizeString;
    import mir.ion.deser.text.tokens : IonTokenType;

    void test(string ts, string expected, ubyte after) {
        auto t = tokenizeString(ts);
        assert(t.nextToken());
        assert(t.currentToken == IonTokenType.TokenLongString);
        assert(t.readLongString() == expected);
        assert(t.readInput() == after);
    }

    test(`'''Hello, world'''`, "Hello, world", 0);
    test(`'''Hello! \U0001F44D'''`, "Hello! 👍", 0);
    test(`'''0xFOOBAR''',`, "0xFOOBAR", ',');
    test(`'''Hello, 'world'!'''`, "Hello, \'world\'!", 0);
    test(`'''Hello,'''''' world!'''`, "Hello, world!", 0);
    test(`'''Hello,'''     ''' world!'''`, "Hello, world!", 0);
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
ubyte[] readClob(T, bool longClob = false)(ref T t) 
if (isInstanceOf!(IonTokenizer, T) && is(T.inputType == ubyte)) {
    // Always read out bytes, as clobs are octet-based (and not necessarily a string)
    ubyte[] data = cast(ubyte[])(readString!(T, longClob, true)(t).dup);

    // read out the following }}
    T.inputType c = t.expect!("a == '}'", true)(t.skipLobWhitespace()); // after skipping any whitespace, it should be the terminator ('}')
    c = t.expect!"a == '}'"; // and no whitespace should between one bracket and another

    t.finished = true; // we're done reading!
    return data;
}
/// Test reading a short clob
version(mir_ion_parser_test) unittest
{
    import mir.ion.deser.text.tokenizer : tokenizeString;
    import mir.ion.deser.text.tokens : IonTokenType;

    void test(string ts, string expected, ubyte after) {
        auto t = tokenizeString(ts);
        assert(t.nextToken());
        assert(t.currentToken == IonTokenType.TokenString);
        assert(t.readClob() == expected);
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
ubyte[] readLongClob(T)(ref T t) 
if (isInstanceOf!(IonTokenizer, T) && is(T.inputType == ubyte)) {
    return readClob!(T, true)(t);
}

/++
Read a blob from the input stream, and return the Base64 contents.

$(NOTE This function does not verify if the Base64 contained is valid, or if it is even Base64.)
Params:
    t = The tokenizer
Returns:
    An untyped array containing the Base64 contents of the blob.
+/
ubyte[] readBlob(T)(ref T t) 
if (isInstanceOf!(IonTokenizer, T) && is(T.inputType == ubyte)) {
    ScopedBuffer!ubyte buf;
    T.inputType c;
    while (true) {
        c = t.expect!("a != 0", true)(t.skipLobWhitespace());
        if (c == '}') {
            break;
        }
        buf.put(c);
    }

    c = t.expect!"a == '}'";
    t.finished = true;
    return buf.data.dup;
}

/++
Read a number from the input stream, and return the type of number, as well as the number itself.

Params:
    t = The tokenizer
Returns:
    A struct holding the type and value of the number.
    See the examples below on how to access the type/value.
+/
auto readNumber(T)(ref T t) 
if (isInstanceOf!(IonTokenizer, T) && is(T.inputType == ubyte)) {
    import mir.ion.type_code : IonTypeCode;
    struct IonNumberRead {
        string val;
        IonTypeCode type;
    }
    IonNumberRead num;
    ScopedBuffer!char buf;

    T.inputType readExponent() {
        T.inputType c = t.readInput();
        if (c == '+' || c == '-') {
            buf.put(c);
            c = t.expect!"a != 0";
        }

        return readDigits!T(t, c, buf);
    }

    T.inputType c = t.readInput();
    if (c == '-') {
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

    T.inputType leader = c;
    const(size_t) len = buf.length;
    c = readDigits!T(t, leader, buf);
    if (leader == '0') {
        if (buf.length - len > 1) {
            throw new MirIonTokenizerException("invalid leading zeros");
        }
    }

    if (c == '.') {
        buf.put('.');
        num.type = IonTypeCode.decimal;
        T.inputType decimalLeader = t.expect!"a != 0";
        c = readDigits!T(t, decimalLeader, buf);
    }

    switch (c) {
        case 'e':
        case 'E':
            num.type = IonTypeCode.float_;
            buf.put(c);
            c = readExponent();
            break;
        case 'd':
        case 'D':
            num.type = IonTypeCode.decimal;
            buf.put(c);
            c = readExponent();
            break;
        default:
            break;
    }

    t.expect!(t.isStopChar, true)(c);
    t.unread(c);
    num.val = buf.data.idup;

    return num; 
}
/// Test reading numbers
version(mir_ion_parser_test) unittest
{
    import mir.ion.deser.text.tokenizer : tokenizeString;
    import mir.ion.deser.text.tokens : IonTokenType;
    import mir.ion.type_code : IonTypeCode;

    void test(string ts, string expected, IonTypeCode type, ubyte after) {
        auto t = tokenizeString(ts);
        assert(t.nextToken());
        assert(t.currentToken == IonTokenType.TokenNumber);
        auto n = t.readNumber();
        assert(n.val == expected);
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
T.inputType readDigits(T)(ref T t, T.inputType leader, ref ScopedBuffer!(char) buf) 
if (isInstanceOf!(IonTokenizer, T) && is(T.inputType == ubyte)) {
    T.inputType c = leader;
    if (!isDigit(c)) {
        return c;
    }
    buf.put(c);
    return readRadixDigits!T(t, buf);
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
T.inputType readRadixDigits(T, alias isValid = isDigit)(ref T t, ref ScopedBuffer!(char) buf) 
if (isInstanceOf!(IonTokenizer, T) && is(T.inputType == ubyte)) {
    import mir.functional : naryFun;
    T.inputType c;
    while (true) {
        c = t.readInput();
        if (c == '_') {
            t.expect!(isValid, true)(t.peekOne());
        }

        if (!naryFun!isValid(c)) {
            return c;
        }
        buf.put(c);
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
string readRadix(T, alias isMarker, alias isValid)(ref T t) 
if (isInstanceOf!(IonTokenizer, T) && is(T.inputType == ubyte)) {
    ScopedBuffer!char buf;
    T.inputType c = t.readInput();
    if (c == '-') {
        buf.put('-');
        c = t.readInput();
    }

    // 0
    t.expect!("a == '0'", true)(c);
    buf.put('0');
    // 0(b || x)
    c = t.expect!isMarker;
    buf.put(c);
    t.expect!("a != '_'", true)(t.peekOne()); // cannot be 0x_ or 0b_
    c = readRadixDigits!(T, isValid)(t, buf);
    t.expect!(t.isStopChar, true)(c);
    t.unread(c);

    return buf.data.idup; 
}

/++
Read a binary number (marked by '0b') from the input stream.

Params:
    t = The tokenizer
Returns:
    A string containing the entire binary number read.
+/
string readBinary(T)(ref T t) 
if (isInstanceOf!(IonTokenizer, T) && is(T.inputType == ubyte)) {
    return readRadix!(T, "a == 'b' || a == 'B'", "a == '0' || a == '1'")(t);
}
/// Test reading a binary number
version(mir_ion_parser_test) unittest
{
    import mir.ion.deser.text.tokenizer : tokenizeString;
    import mir.ion.deser.text.tokens : IonTokenType;

    void test(string ts, string expected, ubyte after) {
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
string readHex(T)(ref T t) 
if (isInstanceOf!(IonTokenizer, T) && is(T.inputType == ubyte)) {
    return readRadix!(T, "a == 'x' || a == 'X'", isHexDigit)(t);
}
/// Test reading a hex number
version(mir_ion_parser_test) unittest
{
    import mir.ion.deser.text.tokenizer : tokenizeString;
    import mir.ion.deser.text.tokens : IonTokenType;

    void test(string ts, string expected, ubyte after) {
        auto t = tokenizeString(ts);
        assert(t.nextToken());
        assert(t.currentToken == IonTokenType.TokenHex);
        assert(t.readHex() == expected);
        assert(t.readInput() == after);
    } 

    test("0xBADBABE", "0xBADBABE", 0);
    test("0x414141", "0x414141", 0);
    test("0x0", "0x0", 0);
    test("     0x414141", "0x414141", 0);
    test("     0x414141,", "0x414141", ',');
    test("     0x414141,0x414142", "0x414141", ',');
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
string readTimestamp(T)(ref T t) 
if (isInstanceOf!(IonTokenizer, T) && is(T.inputType == ubyte)) {
    ScopedBuffer!char buf;

    T.inputType readTSDigits(int nums) {
        for (int i = 0; i < nums; i++) {
            T.inputType c = t.expect!isDigit;
            buf.put(c);
        }
        return t.readInput();
    }

    T.inputType readTSOffset(T.inputType c) {
        if (c != '-' && c != '+') {
            return c;
        }
        buf.put(c);
        const(T.inputType) cs = t.expect!("a == ':'", true)(readTSDigits(2));
        buf.put(':');
        return readTSDigits(2);
    }

    T.inputType readTSOffsetOrZ(T.inputType c) {
        t.expect!("a == '-' || a == '+' || a == 'z' || a == 'Z'", true)(c);
        if (c == '-' || c == '+') {
            return readTSOffset(c);
        }
        if (c == 'z' || c == 'Z') {
            buf.put(c);
            return t.readInput();
        }
        assert(0);
    }

    string readTSFinish(T.inputType c) {
        t.expect!(t.isStopChar, true)(c);
        t.unread(c);
        return buf.data.idup;
    }

    // yyyy(T || -)
    T.inputType c = t.expect!("a == 'T' || a == '-'", true)(readTSDigits(4));
    if (c == 'T') {
        // yyyyT
        buf.put('T');
        return buf.data.idup;
    }
    buf.put('-');
    // yyyy-mm(T || -)
    c = t.expect!("a == 'T' || a == '-'", true)(readTSDigits(2));
    if (c == 'T') {
        buf.put('T');
        return buf.data.idup;
    }
    buf.put('-');
    // yyyy-mm-dd(T)?
    c = readTSDigits(2);
    if (c != 'T') {
        return readTSFinish(c);
    }
    // yyyy-mm-ddT 
    buf.put('T');
    c = t.readInput();
    if (!c.isDigit()) {
        // yyyy-mm-ddT(+ || -)hh:mm
        c = readTSOffset(c);
        return readTSFinish(c);
    }
    // yyyy-mm-ddTh
    buf.put(c);
    // yyyy-mm-ddThh
    c = t.expect!("a == ':'", true)(readTSDigits(1));
    buf.put(':');
    // yyyy-mm-ddThh:mm
    c = readTSDigits(2);
    if (c != ':') {
        // yyyy-mm-ddThh:mmZ
        c = readTSOffsetOrZ(c);
        return readTSFinish(c);
    }

    buf.put(':');
    // yyyy-mm-ddThh:mm:ss
    c = readTSDigits(2);

    if (c != '.') {
        // yyyy-mm-ddThh:mm:ssZ
        c = readTSOffsetOrZ(c);
        return readTSFinish(c);
    }
    buf.put('.');

    // yyyy-mm-ddThh:mm:ss.ssssZ
    c = t.readInput();
    if (c.isDigit()) {
        c = readDigits!T(t, c, buf);
    }

    c = readTSOffsetOrZ(c);
    return readTSFinish(c);
}
/// Test reading timestamps
version(mir_ion_parser_test) unittest
{
    import mir.ion.deser.text.tokenizer : tokenizeString;
    import mir.ion.deser.text.tokens : IonTokenType;

    void test(string ts, string expected, ubyte after) {
        auto t = tokenizeString(ts);
        assert(t.nextToken());
        assert(t.currentToken == IonTokenType.TokenTimestamp);
        assert(t.readTimestamp() == expected);
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
