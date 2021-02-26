/++
Helpers to skip over a given Ion Text token.

Authors: Harrison Ford
+/
module mir.ion.deser.text.skippers;
import mir.ion.deser.text.tokenizer;
import mir.ion.deser.text.tokens;
import mir.ion.type_code;
import std.traits : isInstanceOf;
import std.range;
version(mir_ion_parser_test) import unit_threaded;

@safe:
/++
Skip over the contents of a S-Exp/Struct/List/Blob.
Params:
    t = The tokenizer
    term = The last character read from the tokenizer's input range
Returns:
    A character located after the [s-exp, struct, list, blob].
+/
T.inputType skipContainer(T)(ref T t, T.inputType term) 
if (isInstanceOf!(IonTokenizer, T)) {
    skipContainerInternal!T(t, term);
    return t.readInput();
}

/++
Skip over the contents of a S-Exp/Struct/List/Blob, but do not read any character after the terminator.

Params:
    t = The tokenizer
    term = The last character read from the tokenizer's input range
+/
void skipContainerInternal(T)(ref T t, T.inputType term) 
if (isInstanceOf!(IonTokenizer, T)) 
in {
    assert(term == ']' || term == '}' || term == ')', "Unexpected character for skipping");
} body {
    T.inputType c;
    while (true) {
        c = t.skipWhitespace();
        if (c == term) return;
        t.expect!("a != 0", true)(c);
        switch (c) {
            case '"':
                t.skipStringInternal();
                break;
            case '\'':
                if (t.isTripleQuote()) {
                    skipLongStringInternal!(T, true, false)(t);
                } else {
                    t.skipSymbolQuotedInternal();
                }
                break;
            case '(':
                skipContainerInternal!(T)(t, ')');
                break;
            case '[':
                skipContainerInternal!(T)(t, ']');
                break;
            case '{':
                c = t.peekOne();
                if (c == '{') {
                    t.expect!"a != 0";
                    t.skipBlobInternal();
                } else if (c == '}') {
                    t.expect!"a != 0";
                } else {
                    skipContainerInternal!(T)(t, '}');
                }
                break;
            default:
                break;
        }


    }
}

/++
Skip over a single line comment. This will read input up until a newline or the EOF is hit.
Params:
    t = The tokenizer
Returns:
    true if it was able to skip over the comment.
+/
bool skipSingleLineComment(T)(ref T t) 
if (isInstanceOf!(IonTokenizer, T)) {
    while (true) {
        const(T.inputType) c = t.readInput();
        if (c == '\n' || c == 0) {
            return true;
        }
    }
}
///
version(mir_ion_parser_test) @("Test skipping of a single-line comment") unittest 
{
    auto t = tokenizeString("single-line comment\r\nok");
    t.skipSingleLineComment().shouldEqual(true);

    t.testRead('o');
    t.testRead('k');
    t.testRead(0);
}
///
version(mir_ion_parser_test) @("Test skipping of a single-line comment on the last line") unittest
{
    auto t = tokenizeString("single-line comment");
    t.skipSingleLineComment().shouldEqual(true);
    t.testRead(0);
}

/++
    Skip over a block comment. This will read up until `*/` is hit.
    Params:
        t = The tokenizer
    Returns:
        true if the block comment was able to be skipped, false if EOF was hit
+/
bool skipBlockComment(T)(ref T t)
if (isInstanceOf!(IonTokenizer, T)) {
    bool foundStar = false;
    while (true) {
        const(T.inputType) c = t.readInput();
        if (foundStar && c == '/') {
            return true;
        }
        if (c == 0) {
            return false;
        }

        if (c == '*') {
            foundStar = true;
        }
    }
}
///
version(mir_ion_parser_test) @("Test skipping of an invalid comment") unittest
{
    auto t = tokenizeString("this is a string that never ends");
    t.skipBlockComment().shouldEqual(false);
}
///
version(mir_ion_parser_test) @("Test skipping of a block comment") unittest
{
    auto t = tokenizeString("this is/ a\nmulti-line /** comment.**/ok");
    t.skipBlockComment().shouldEqual(true);

    t.testRead('o');
    t.testRead('k');
    t.testRead(0);
}

/++
Skip over a comment (block or single-line) after reading a '/'
Params:
    t = The tokenizer
Returns:
    true if it was able to skip over the comment
+/
bool skipComment(T)(ref T t) 
if (isInstanceOf!(IonTokenizer, T)) {
    if (t.input.empty) {
        return false;
    }
    const(T.inputType) c = t.peekOne();
    switch(c) {
        case '/':
            return t.skipSingleLineComment();
        case '*':
            return t.skipBlockComment();
        default:
            break;
    }

    return false;
}
///
version(mir_ion_parser_test) @("Test different skipping methods (single-line)") unittest
{
    auto t = tokenizeString("/comment\nok");
    t.skipComment().shouldEqual(true);
    t.testRead('o');
    t.testRead('k');
    t.testRead(0);
}
///
version(mir_ion_parser_test) @("Test different skipping methods (block)") unittest
{
    auto t = tokenizeString("*comm\nent*/ok");
    t.skipComment().shouldEqual(true);
    t.testRead('o');
    t.testRead('k');
    t.testRead(0);
}
///
version(mir_ion_parser_test) @("Test different skipping methods (false-alarm)") unittest
{
    auto t = tokenizeString(" 0)");
    t.skipComment().shouldEqual(false);
    t.testRead(' ');
    t.testRead('0');
    t.testRead(')');
    t.testRead(0);
}

/++
Skip any digits after the last character read.
Params:
    t = The tokenizer
    _c = The last character read from the tokenizer input range.
Returns:
    A character located after the last digit skipped.
+/
T.inputType skipDigits(T)(ref T t, T.inputType _c)
if(isInstanceOf!(IonTokenizer, T)) {
    auto c = _c;
    while (c.isDigit()) {
        c = t.readInput();
    }
    return c;
}

/++
Skip over a non-[hex, binary] number.
Params:
    t = The tokenizer
Returns:
    A character located after the number skipped.
+/
T.inputType skipNumber(T)(ref T t) 
if (isInstanceOf!(IonTokenizer, T)) {
    T.inputType c = t.readInput();
    if (c == '-') {
        c = t.readInput();
    }

    c = skipDigits!T(t, c);
    if (c == '.') {
        c = t.readInput();
        c = skipDigits!T(t, c);
    }

    if (c == 'd' || c == 'D' || c == 'e' || c == 'E') {
        c = t.readInput();
        if (c == '+' || c == '-') {
            c = t.readInput();
        }
        c = skipDigits!T(t, c);
    }

    return t.expect!(t.isStopChar, true)(c);
}
///
version(mir_ion_parser_test) @("Test skipping over numbers") unittest
{
    void test(string ts, ubyte expected) {
        auto t = tokenizeString(ts);
        t.skipNumber().shouldEqual(expected);
    }

    void testFail(string ts) {
        auto t = tokenizeString(ts);
        t.skipNumber().shouldThrow();
    }

    test("", 0);
    test("0", 0);
    test("-1234567890,", ',');
    test("1.2 ", ' ');
    test("1d45\n", '\n');
    test("1.4e-12//", '/');
    testFail("1.2d3d");
}

/++
Skip over a binary number.
Params:
    t = The tokenizer
Returns:
    A character located after the number skipped.
+/
T.inputType skipBinary(T)(ref T t) 
if (isInstanceOf!(IonTokenizer, T)) {
    return skipRadix!(T, "a == 'b' || a == 'B'", "a == '0' || a == '1'")(t);   
}
///
version(mir_ion_parser_test) @("Test skipping over binary numbers") unittest
{
    void test(string ts, ubyte expected) {
        auto t = tokenizeString(ts);
        t.skipBinary().shouldEqual(expected);
    }

    void testFail(string ts) {
        auto t = tokenizeString(ts);
        t.skipBinary().shouldThrow();
    }

    test("0b0", 0);
    test("-0b10 ", ' ');
    test("0b010101,", ',');

    testFail("0b2");
}

/++
Skip over a hex number.
Params:
    t = The tokenizer
Returns:
    A character located after the number skipped.
+/
T.inputType skipHex(T)(ref T t) 
if (isInstanceOf!(IonTokenizer, T)) {
    return skipRadix!(T, "a == 'x' || a == 'X'", isHexDigit)(t); 
}
///
version(mir_ion_parser_test) @("Test skipping over hex numbers") unittest
{
    void test(string ts, ubyte expected) {
        auto t = tokenizeString(ts);
        t.skipHex().shouldEqual(expected);
    }

    void testFail(string ts) {
        auto t = tokenizeString(ts);
        t.skipHex().shouldThrow();
    }

    test("0xDEADBABE,0xDEADBABE", ',');
    test("0x0", 0);
    test("-0x0F ", ' ');
    test("0x1234567890abcdefABCDEF,", ',');

    testFail("0xG");
}

/++
Skip over a number given two predicates to determine the number's marker (`0x`, `0b`) and if any input is valid.
Params:
    isMarker = A predicate which determines if the marker in a number is valid.
    isValid = A predicate which determines the validity of digits within a number.
    t = The tokenizer
Returns:
    A character located after the number skipped.
+/
template skipRadix(T, alias isMarker, alias isValid)
if (isInstanceOf!(IonTokenizer, T)) {
    import mir.functional : naryFun;
    T.inputType skipRadix(ref T t) {
        auto c = t.readInput();

        // Skip over negatives 
        if (c == '-') {
            c = t.readInput();
        }

        t.expect!("a == '0'", true)(c); // 0
        t.expect!(isMarker); // 0(x || b)
        while (true) {
            c = t.readInput();
            if (!naryFun!isValid(c)) {
                break;
            }
        }
        return t.expect!(isStopChar, true)(c);
    }
}

/++
Skip over a timestamp (compliant to ISO 8601)
Params:
    t = The tokenizer
Returns:
    A character located after the timestamp skipped.
+/
T.inputType skipTimestamp(T)(ref T t) 
if (isInstanceOf!(IonTokenizer, T)) {
    T.inputType skipTSDigits(int count) {
        int i = count;
        while (i > 0) {
            t.expect!(isDigit);
            i--;
        }
        return t.readInput();
    }

    T.inputType skipTSOffset(T.inputType c) {
        if (c != '+' && c != '-') {
            return c;
        }

        t.expect!("a == ':'", true)(skipTSDigits(2));
        return skipTSDigits(2);
    }

    T.inputType skipTSOffsetOrZ(T.inputType c) {
        t.expect!("a == '+' || a == '-' || a == 'z' || a == 'Z'", true)(c);
        if (c == '+' || c == '-') 
            return skipTSOffset(c);
        if (c == 'z' || c == 'Z') 
            return t.readInput();
        assert(0); // should never hit this
    }

    T.inputType skipTSFinish(T.inputType c) {
        return t.expect!(isStopChar, true)(c);
    }

    // YYYY(T || '-')
    const(T.inputType) afterYear = t.expect!("a == 'T' || a == '-'", true)(skipTSDigits(4));
    if (afterYear == 'T') {
        // skipped yyyyT
        return t.readInput();
    }

    // YYYY-MM('T' || '-')
    const(T.inputType) afterMonth = t.expect!("a == 'T' || a == '-'", true)(skipTSDigits(2));
    if (afterMonth == 'T') {
        // skipped yyyy-mmT
        return t.readInput();
    }

    // YYYY-MM-DD('T')?
    T.inputType afterDay = skipTSDigits(2);
    if (afterDay != 'T') {
        // skipped yyyy-mm-dd
        return skipTSFinish(afterDay);
    }

    // YYYY-MM-DDT('+' || '-' || 'z' || 'Z' || isDigit)
    T.inputType offsetH = t.readInput();
    if (!offsetH.isDigit()) {
        // YYYY-MM-DDT('+' || '-' || 'z' || 'Z')
        // skipped yyyy-mm-ddT(+hh:mm)
        T.inputType afterOffset = skipTSOffset(offsetH);
        return skipTSFinish(afterOffset);
    }

    // YYYY-MM-DDT[0-9][0-9]:
    t.expect!("a == ':'", true)(skipTSDigits(1));

    // YYYY-MM-DDT[0-9][0-9]:[0-9][0-9](':' || '+' || '-' || 'z' || 'Z')
    T.inputType afterOffsetMM = t.expect!("a == ':' || a == '+' || a == '-' || a == 'z' || a == 'Z'", true)
                                                                                            (skipTSDigits(2));
    if (afterOffsetMM != ':') {
        // skipped yyyy-mm-ddThh:mmZ
        T.inputType afterOffset = skipTSOffsetOrZ(afterOffsetMM);
        return skipTSFinish(afterOffset);
    }
    // YYYY-MM-DDT[0-9][0-9]:[0-9][0-9]:[0-9][0-9]('.')?
    T.inputType afterOffsetSS = skipTSDigits(2);
    if (afterOffsetSS != '.') {
        T.inputType afterOffset = skipTSOffsetOrZ(afterOffsetSS);
        return skipTSFinish(afterOffset); 
    }

    // YYYY-MM-DDT[0-9][0-9]:[0-9][0-9]:[0-9][0-9].[0-9]*
    T.inputType offsetNS = t.readInput();
    if (isDigit(offsetNS)) {
        offsetNS = skipDigits!T(t, offsetNS);
    }

    // YYYY-MM-DDT[0-9][0-9]:[0-9][0-9]:[0-9][0-9].[0-9]*('+' || '-' || 'z' || 'Z')([0-9][0-9]:[0-9][0-9])?
    T.inputType afterOffsetNS = skipTSOffsetOrZ(offsetNS);
    return skipTSFinish(afterOffsetNS);  
}
///
version(mir_ion_parser_test) @("Test skipping over timestamps") unittest
{
    void test(string ts, ubyte result) {
        auto t = tokenizeString(ts);
        t.skipTimestamp().shouldEqual(result);
    }

    void testFail(string ts) {
        auto t = tokenizeString(ts);
        t.skipTimestamp().shouldThrow();
    }

    test("2001T", 0);
    test("2001-01T,", ',');
    test("2001-01-02}", '}');
    test("2001-01-02T ", ' ');
    test("2001-01-02T+00:00\t", '\t');
    test("2001-01-02T-00:00\n", '\n');
    test("2001-01-02T03:04+00:00 ", ' ');
    test("2001-01-02T03:04-00:00 ", ' ');
    test("2001-01-02T03:04Z ", ' ');
    test("2001-01-02T03:04z ", ' ');
    test("2001-01-02T03:04:05Z ", ' ');
    test("2001-01-02T03:04:05+00:00 ", ' ');
    test("2001-01-02T03:04:05.666Z ", ' ');
    test("2001-01-02T03:04:05.666666z ", ' ');

    testFail(""); 
    testFail("2001");
    testFail("2001z");
    testFail("20011");
    testFail("2001-0");
    testFail("2001-01");
    testFail("2001-01-02Tz");
    testFail("2001-01-02T03");
    testFail("2001-01-02T03z");
    testFail("2001-01-02T03:04x ");
    testFail("2001-01-02T03:04:05x ");
}

/++
Skip over a symbol.
Params:
    t = The tokenizer
Returns:
    A character located after the symbol skipped.
+/
T.inputType skipSymbol(T)(ref T t) 
if (isInstanceOf!(IonTokenizer, T)) {
    T.inputType c = t.readInput();
    while (isIdentifierPart(c)) { 
        c = t.readInput();
    }

    return c;
}
///
version(mir_ion_parser_test) @("Test skipping over symbols") unittest
{
    void test(string ts, ubyte result) {
        auto t = tokenizeString(ts);
        t.skipSymbol().shouldEqual(result);
    }

    test("f", 0);
    test("foo:", ':');
    test("foo,", ',');
    test("foo ", ' ');
    test("foo\n", '\n');
    test("foo]", ']');
    test("foo}", '}');
    test("foo)", ')');
    test("foo\\n", '\\');
}

/++
Skip over a quoted symbol, but do not read the character after.
Params:
    t = The tokenizer
+/
void skipSymbolQuotedInternal(T)(ref T t) 
if (isInstanceOf!(IonTokenizer, T)) {
    T.inputType c;
    while (true) {
        c = t.expect!"a != 0 && a != '\\n'";
        switch (c) {
            case '\'':
                return;
            case '\\':
                t.expect!"a != 0";
                break;
            default:
                break;
        }
    }
}

/++
Skip over a quoted symbol
Params:
    t = The tokenizer
Returns:
    A character located after the quoted symbol skipped.
+/
T.inputType skipSymbolQuoted(T)(ref T t) 
if (isInstanceOf!(IonTokenizer, T)) {
    t.skipSymbolQuotedInternal();
    return t.readInput();  
}
///
version(mir_ion_parser_test) @("Test skipping over quoted symbols") unittest
{
    void test(string ts, ubyte result) {
        auto t = tokenizeString(ts);
        t.skipSymbolQuoted().shouldEqual(result);
    }

    void testFail(string ts) {
        auto t = tokenizeString(ts);
        t.skipSymbolQuoted().shouldThrow();
    }

    test("'", 0);
    test("foo',", ',');
    test("foo\\'bar':", ':');
    test("foo\\\nbar',", ',');
    testFail("foo");
    testFail("foo\n");
}

/++
Skip over a symbol operator.
Params:
    t = The tokenizer
Returns:
    A character located after the symbol operator skipped.
+/
T.inputType skipSymbolOperator(T)(ref T t) 
if (isInstanceOf!(IonTokenizer, T)) {
    T.inputType c = t.readInput();

    while (isOperatorChar(c)) {
        c = t.readInput();
    }
    return c; 
}
///
version(mir_ion_parser_test) @("Test skipping over symbol operators") unittest
{
    void test(string ts, ubyte result) {
        auto t = tokenizeString(ts);
        t.skipSymbolOperator().shouldEqual(result);
    }

    test("+", 0);
    test("++", 0);
    test("+= ", ' ');
    test("%b", 'b');
}

/++
Skip over a string, but do not read the character following it.
Params:
    t = The tokenizer
+/
void skipStringInternal(T)(ref T t) 
if (isInstanceOf!(IonTokenizer, T)) {
    T.inputType c;
    while (true) {
        c = t.expect!("a != 0 && a != '\\n'");
        switch (c) {
            case '"':
                return;
            case '\\':
                t.expect!"a != 0";
                break;
            default:
                break;
        }
    }
}

/++
Skip over a string.
Params:
    t = The tokenizer
Returns:
    A character located after the string skipped.
+/
T.inputType skipString(T)(ref T t) 
if (isInstanceOf!(IonTokenizer, T)) {
    t.skipStringInternal();
    return t.readInput();  
}
///
version(mir_ion_parser_test) @("Test skipping over strings") unittest
{
    void test(string ts, ubyte result) {
        auto t = tokenizeString(ts);
        t.skipString().shouldEqual(result);
    }

    void testFail(string ts) {
        auto t = tokenizeString(ts);
        t.skipString().shouldThrow();
    }

    test("\"", 0);
    test("\",", ',');
    test("foo\\\"bar\"], \"\"", ']');
    test("foo\\\nbar\" \t\t\t", ' ');

    testFail("foobar");
    testFail("foobar\n"); 
}

/++
Skip over a long string, but do not read the character following it.
Params:
    t = The tokenizer
+/
void skipLongStringInternal(T, bool skipComments = true, bool failOnComment = false)(ref T t) 
if (isInstanceOf!(IonTokenizer, T) && __traits(compiles, { t.skipWhitespace!(skipComments, failOnComment); })) {
    T.inputType c;
    while (true) {
        c = t.expect!("a != 0");
        switch (c) {
            case '\'':
                if(skipLongStringEnd!(T, skipComments, failOnComment)(t)) {
                    return;
                }
                break;
            case '\\':
                t.expect!("a != 0");
                break;
            default:
                break;
        }
    }
}

/++
Skip over the end of a long string (`'''``)
Params:
    t = The tokenizer
Returns:
    true if it was able to skip over the end of the long string.
+/
bool skipLongStringEnd(T, bool skipComments = true, bool failOnComment = false)(ref T t) 
if (isInstanceOf!(IonTokenizer, T) && __traits(compiles, { t.skipWhitespace!(skipComments, failOnComment); })) {
    auto cs = t.peekMax(2);
    if (cs.length < 2 || cs[0] != '\'' || cs[1] != '\'') {
        return false;
    }

    t.skipExactly(2);
    T.inputType c = t.skipWhitespace!(skipComments, failOnComment);
    if (c == '\'') {
        if (t.isTripleQuote()) {
            return false;
        }
    }

    t.unread(c);
    return true;
}

/++
Skip over a long string (marked by `'''`)
Params:
    t = The tokenizer
Returns:
    A character located after the long string skipped.
+/
T.inputType skipLongString(T)(ref T t) 
if (isInstanceOf!(IonTokenizer, T)) {
    skipLongStringInternal!(T, true, false)(t);
    return t.readInput();
}
///
version(mir_ion_parser_test) @("Test skipping over long strings") unittest
{
    void test(string ts, ubyte result) {
        auto t = tokenizeString(ts);
        t.skipLongString().shouldEqual(result);
    }

}

/++
Skip over a blob.
Params:
    t = The tokenizer
Returns:
    A character located after the blob skipped.
+/
T.inputType skipBlob(T)(ref T t) 
if (isInstanceOf!(IonTokenizer, T)) {
    t.skipBlobInternal();
    return t.readInput();  
}
///
version(mir_ion_parser_test) @("Test skipping over blobs") unittest
{
    void test(string ts, ubyte result) {
        auto t = tokenizeString(ts);
        t.skipBlob().shouldEqual(result);
    } 

    test("}}", 0);
    test("oogboog}},{{}}", ',');
    test("'''not encoded'''}}\n", '\n');
}

/++
Skip over a blob, but do not read the character following it.
Params:
    t = The tokenizer
+/
void skipBlobInternal(T)(ref T t) 
if (isInstanceOf!(IonTokenizer, T)) {
    T.inputType c = t.skipLobWhitespace();
    while (c != '}') {
        c = t.skipLobWhitespace();
        t.expect!("a != 0", true)(c);
    }

    t.expect!("a == '}'");

    return;
}

/++
Skip over a struct.
Params:
    t = The tokenizer
Returns:
    A character located after the struct skipped.
+/
T.inputType skipStruct(T)(ref T t) 
if (isInstanceOf!(IonTokenizer, T)) {
    return skipContainer!T(t, '}');
}
///
version(mir_ion_parser_test) @("Test skipping over structs") unittest
{
    void test(string ts, ubyte result) {
        auto t = tokenizeString(ts);
        t.skipStruct().shouldEqual(result);
    }

    test("},", ',');
    test("[\"foo bar baz\"]},", ',');
    test("{}},{}", ','); // skip over an embedded struct inside of a struct
}

/++
Skip over a struct, but do not read the character following it.
Params:
    t = The tokenizer
+/
void skipStructInternal(T)(ref T t) 
if (isInstanceOf!(IonTokenizer, T)) {
    skipContainerInternal!T(t, '}');
    return;
}

/++
Skip over a S-expression.
Params:
    t = The tokenizer
Returns:
    A character located after the S-expression skipped.
+/
T.inputType skipSexp(T)(ref T t) 
if (isInstanceOf!(IonTokenizer, T)) {
    return skipContainer!T(t, ')');
}
///
version(mir_ion_parser_test) @("Test skipping over S-Exps") unittest
{
    void test(string ts, ubyte result) {
        auto t = tokenizeString(ts);
        t.skipSexp().shouldEqual(result);
    }

    test("1231 + 1123),", ',');
    test("0xF00DBAD)", 0);
}

/++
Skip over a S-expression, but do not read the character following it.
Params:
    t = The tokenizer
+/
void skipSexpInternal(T)(ref T t) 
if (isInstanceOf!(IonTokenizer, T)) {
    skipContainerInternal!T(t, ')');
    return;
}

/++
Skip over a list.
Params:
    t = The tokenizer
Returns:
    A character located after the list skipped.
+/
T.inputType skipList(T)(ref T t) 
if (isInstanceOf!(IonTokenizer, T)) {
    return skipContainer!T(t, ']'); 
}
///
version(mir_ion_parser_test) @("Test skipping over a list") unittest
{
    void test(string ts, ubyte result) {
        auto t = tokenizeString(ts);
        t.skipList().shouldEqual(result);
    }

    test("\"foo\", \"bar\", \"baz\"],", ',');
    test("\"foobar\"]", 0);
}

/++
Skip over a list, but do not read the character following it.
Params:
    t = The tokenizer
+/
void skipListInternal(T)(ref T t) 
if (isInstanceOf!(IonTokenizer, T)) {
    skipContainerInternal!T(t, ']');
    return;
}

/++
Skip over the current token.
Params:
    t = The tokenizer
Returns:
    A non-whitespace character following the current token.
+/
T.inputType skipValue(T)(ref T t) 
if (isInstanceOf!(IonTokenizer, T)) {
    T.inputType ret;
    with(IonTokenType) switch(t.currentToken) {
        case TokenNumber:
            ret = t.skipNumber();
            break;
        case TokenBinary:
            ret = t.skipBinary();
            break;
        case TokenHex:
            ret = t.skipHex();
            break;
        case TokenTimestamp:
            ret = t.skipTimestamp();
            break;
        case TokenSymbol:
            ret = t.skipSymbol();
            break;
        case TokenSymbolQuoted:
            ret = t.skipSymbolQuoted();
            break;
        case TokenSymbolOperator:
            ret = t.skipSymbolOperator();
            break;
        case TokenString:
            ret = t.skipString();
            break;
        case TokenLongString:
            ret = t.skipLongString();
            break;
        case TokenOpenDoubleBrace:
            ret = t.skipBlob();
            break;
        case TokenOpenBrace:
            ret = t.skipStruct();
            break;
        case TokenOpenParen:
            ret = t.skipSexp();
            break;
        case TokenOpenBracket:
            ret = t.skipList();
            break;
        default:
            assert(0, "unhandled token: " ~ ionTokenMsg(t.currentToken));
    }

    if (ret.isWhitespace()) {
        ret = t.skipWhitespace();
    }

    t.finished = true;
    return ret;
}