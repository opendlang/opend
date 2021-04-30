/++
Tokenizer to split up the contents of an Ion Text file into tokens

Authors: Harrison Ford
+/
module mir.ion.deser.text.tokenizer;

import mir.ion.deser.text.readers;
import mir.ion.deser.text.skippers;
import mir.ion.deser.text.tokens;
import mir.ion.internal.data_holder : IonTapeHolder;

/++
Create a tokenizer for a given UTF-8 string.

This function will take in a given string, and duplicate it.
Then, it will proceed to tokenize it.

$(NOTE If this string is not a UTF-8 string, consider using the overload which accepts a UTF-16/UTF-32 string.)

Params:
    input = String to tokenize
Returns:
    [IonTokenizer]
+/
IonTokenizer tokenizeString(const(char)[] input) @safe @nogc pure {
    return IonTokenizer(input);
}

/++
Create a tokenizer for a given UTF-16/UTF-32 string.

This function will take in a UTF-16/UTF-32 string, and convert it to a UTF-8 string before tokenizing.

Params:
    input = UTF-16 string to tokenize.
Returns:
    [IonTokenizer]
+/
auto tokenizeString(Input)(Input input) @safe pure  
if (is(Input : const(wchar)[]) || is(Input : const(dchar)[])) {
    import std.utf : toUTF8;
    auto range = input.toUTF8();
    return tokenizeString(range);
}

/// UTF-16 string
version(mir_ion_parser_test) unittest {
    import mir.ion.deser.text.tokens : IonTokenType;
    import mir.ion.deser.text.readers : readString;
    auto t = tokenizeString(`"hello𐐷world"`w);
    assert(t.nextToken());
    assert(t.currentToken == IonTokenType.TokenString);
    assert(t.readString().matchedText == "hello𐐷world");
}
/// UTF-32 string
version(mir_ion_parser_test) unittest {
    import mir.ion.deser.text.tokens : IonTokenType;
    import mir.ion.deser.text.readers : readString;
    auto t = tokenizeString(`"hello𐐷world"`d);
    assert(t.nextToken());
    assert(t.currentToken == IonTokenType.TokenString);
    assert(t.readString().matchedText == "hello𐐷world");
}
/++
Tokenizer based off of how ion-go handles tokenization
+/
struct IonTokenizer {
    /++ Our input range that we read from +/
    const(char)[] input;

    /++ The current window that we're reading from (sliding window) +/
    const(char)[] window;

    /++ The escape sequence that we're reading from the wire +/
    char[4] escapeSequence; 

    /++ Bool specifying if we want to read through the contents of the current token +/
    bool finished;

    /++ Current position within our input range +/
    size_t position;

    /++ Current token that we're located on +/
    IonTokenType currentToken;

    /++ 
    Constructor
    Params:
        input = The input range to read over 
    +/
    this(const(char)[] input) @safe @nogc pure {
        this.input = input;
        resizeWindow(0);
    }

    /++
    Update the sliding window's beginning index
    Params:
        start = The beginning index to start at
    +/
    void resizeWindow(size_t start) @safe @nogc pure {
        if (start > input.length) {
            throw IonTokenizerErrorCode.cannotUpdateWindow.ionTokenizerException;
        }

        window = input[start .. $];
        this.position = start;
    }

    /++
    Clear out the escape sequence buffer.
    +/
    void resetEscapeBuffer() @safe @nogc pure {
        this.escapeSequence[0] = '\0';
        this.escapeSequence[1] = '\0';
        this.escapeSequence[2] = '\0';
        this.escapeSequence[3] = '\0';
    }

    /++
    Variable to indicate if we at the end of our range
    Returns:
        true if end of file, false otherwise
    +/
    bool isEOF() @safe @nogc pure {
        return this.window.length == 0
               || this.currentToken == IonTokenType.TokenEOF 
               || this.position >= this.input.length;
    }

    /++ 
    Unread a given character and append it to the peek buffer 
    Params:
        c = Character to append to the top of the peek buffer.
    +/
    void unread(char c) @safe @nogc pure  {
        if (this.position <= 0) {
            throw ionTokenizerException(IonTokenizerErrorCode.cannotUnreadAtPos0);
        }

        if (c == 0) {
            return;
        } else {
            resizeWindow(this.position - 1);
        }
    }
    /// Test reading / unreading bytes
    version(mir_ion_parser_test) unittest
    {
        auto t = tokenizeString("abc\rd\ne\r\n");

        t.testRead('a');
        t.unread('a');

        t.testRead('a');
        t.testRead('b');
        t.testRead('c');
        t.unread('c');
        t.unread('b');

        t.testRead('b');
        t.testRead('c');
        t.testRead('\r');
        t.unread('\r');

        t.testRead('\r');
        t.testRead('d');
        t.testRead('\n');
        t.testRead('e');
        t.testRead('\r');
        t.testRead('\n');
        t.testRead(0); // test EOF

        t.unread(0); // unread EOF
        t.unread('\n');

        t.testRead('\n');
        t.testRead(0); // test EOF
        t.testRead(0); // test EOF
    }

    /++ 
    Skip a single character within our input range, and discard it 
    Returns:
        true if it was able to skip a single character,
        false if it was unable (due to hitting an EOF or the like)
    +/
    bool skipOne() @safe @nogc pure  {
        const(char) c = readInput();
        if (c == 0) {
            return false;
        }
        return true;
    }

    /++
    Skip exactly n input characters from the input range

    $(NOTE
        This function will only return true IF it is able to skip *the entire amount specified*)
    Params:
        n = Number of characters to skip
    Returns:
        true if skipped the entire range,
        false if unable to skip the full range specified.
    +/
    bool skipExactly(size_t n) @safe @nogc pure {
        for (size_t i = 0; i < n; i++) {
            if (!skipOne()) { 
                return false;
            }
        }
        return true;
    }

    /++
    Read ahead at most n characters from the input range without discarding them.

    $(NOTE
        This function does not require n characters to be present.
        If it encounters an EOF, it will simply return a shorter range.)
    Params:
        n = Max number of characters to peek
    Returns:
        Array of peeked characters
    +/
    auto peekMax(size_t wanted = 4096) @safe @nogc pure {
        size_t n = wanted; 
        if (n >= window.length) {
            n = window.length;
        }

        auto arr = window[0 .. n];
        return arr;
    }

    /++
    Read ahead exactly n characters from the input range without discarding them.

    $(NOTE
        This function will throw if all n characters are not present.
        If you would like to peek as many as possible, use [peekMax] instead.)
    Params:
        n = Number of characters to peek
    Returns:
        An array filled with n characters.
    Throws:
        [MirIonTokenizerException]
    +/
    auto peekExactly(size_t required = 4096) @safe @nogc pure {
        size_t n = required; 
        if (n > window.length) {
            unexpectedEOF();
        }

        auto buf = window[0 .. n];

        return buf;
    }
    /// Test peekExactly
    version(mir_ion_parser_test) unittest
    {
        import std.exception : assertThrown;
        import mir.exception : enforce;
        import mir.ion.deser.text.tokens : MirIonTokenizerException;

        auto t = tokenizeString("abc\r\ndef");
        
        assert(t.peekExactly(1).ptr == t.window.ptr);
        assert(t.peekExactly(1) == "a");
        assert(t.peekExactly(2) == "ab");
        assert(t.peekExactly(3) == "abc");

        t.testRead('a');
        t.testRead('b');
        
        assert(t.peekExactly(3).ptr == t.window.ptr);
        assert(t.peekExactly(3) == "c\r\n");
        assert(t.peekExactly(2) == "c\r");
        assert(t.peekExactly(3) == "c\r\n");

        t.testRead('c');
        t.testRead('\r');
        t.testRead('\n');
        t.testRead('d');

        assertThrown!MirIonTokenizerException(t.peekExactly(3));
        assertThrown!MirIonTokenizerException(t.peekExactly(3));
        assert(t.peekExactly(2) == "ef");

        t.testRead('e');
        t.testRead('f');
        t.testRead(0);

        assertThrown!MirIonTokenizerException(t.peekExactly(10));
    }

    /++
    Read ahead one character from the input range without discarding it.

    $(NOTE
        This function will throw if it cannot read one character ahead.
        Use [peekMax] if you want to read without throwing.)
    Returns:
        A single character read ahead from the input range.
    Throws:
        [MirIonTokenizerException]
    +/
    char peekOne() @safe @nogc pure {
        if (isEOF) {
            this.unexpectedEOF();
        }

        char c;
        c = readInput();
        unread(c);
        
        return c;
    }
    /// Test peeking the next byte in the stream
    version(mir_ion_parser_test) unittest
    {
        import std.exception : assertThrown;
        import mir.ion.deser.text.tokens : MirIonTokenizerException;

        auto t = tokenizeString("abc");

        t.testPeek('a');
        t.testPeek('a');
        t.testRead('a');

        t.testPeek('b');
        t.unread('a');

        t.testPeek('a');
        t.testRead('a');
        t.testRead('b');
        t.testPeek('c');
        t.testPeek('c');
        t.testRead('c');
        
        assertThrown!MirIonTokenizerException(t.peekOne() == 0);
        assertThrown!MirIonTokenizerException(t.peekOne() == 0);
        assert(t.readInput() == 0);
    }

    /++
    Read a single character from the input range (or from the peek buffer, if it's not empty)

    $(NOTE `readInput` does NOT normalize CRLF to a simple new-line.)
    Returns:
        a single character from the input range, or 0 if the EOF is encountered.
    Throws:
        [MirIonTokenizerException]
    +/
    char readInput() @safe @nogc pure {
        if (isEOF) {
            return 0;
        }

        immutable char c = this.window[0];
        resizeWindow(this.position + 1);
        /*
        if (c == '\r') {
            // EOFs should've been normalized at the first stage
            throw ionTokenizerException(IonTokenizerErrorCode.normalizeEOFFail);
        }
        */

        return c;
    }
    /// Test reading bytes off of a range
    version(mir_ion_parser_test) unittest 
    {
        auto t = tokenizeString("abcdefghijklmopqrstuvwxyz1234567890");
        t.testRead('a');
        t.testRead('b');
        t.testRead('c');
        t.testRead('d');
        t.testRead('e');
        t.testRead('f');
        t.testRead('g');
        t.testRead('h');
        t.testRead('i');
    }
    /// Test the normalization of CRLFs
    version(mir_ion_parser_test) unittest
    {
        auto t = tokenizeString("a\r\nb\r\nc\rd");
        t.testRead('a');
        t.testRead('\r');
        t.testRead('\n');
        t.testRead('b');
        t.testRead('\r');
        t.testRead('\n');
        t.testRead('c');
        t.testRead('\r');
        t.testRead('d');
        t.testRead(0);
    }

    /++
    Skip any whitespace that is present between our current token and the next valid token.

    Additionally, skip comments (or fail on comments).

    $(NOTE `skipComments` and `failOnComment` cannot both be true.)
    Returns:
        The character located directly after the whitespace.
    Throws:
        [MirIonTokenizerException]
    +/
    char skipWhitespace(bool skipComments = true, bool failOnComment = false)() @safe @nogc pure 
    if (skipComments != failOnComment || (skipComments == false && skipComments == failOnComment)) { // just a sanity check, we cannot skip comments and also fail on comments -- it is one or another (fail or skip)
        while (true) {
            char c = readInput();
            sw: switch(c) {
                static foreach(member; ION_WHITESPACE) {
                    case member:
                        break sw;
                }
                
                case '/': {
                    static if (failOnComment) {
                        throw IonTokenizerErrorCode.commentsNotAllowed.ionTokenizerException; 
                    } else static if(skipComments) {
                        // Peek on the next letter, and check if it's a second slash / star
                        // This may fail if we read a comment and do not find the end (newline / '*/')
                        // Undetermined if I need to unread the last char if this happens?
                        if (this.skipComment()) 
                            break;
                        else
                            goto default;
                    } else {
                        return '/';
                    }
                }
                // If this is a non-whitespace character, unread it
                default:
                    return c;
            }
        }
        return 0;
    }
    /// Test skipping over whitespace 
    version(mir_ion_parser_test) unittest
    {
        import std.exception : assertNotThrown;
        import mir.exception : enforce;
        import mir.ion.deser.text.tokens : MirIonTokenizerException;
        void test(string txt, char expectedChar) {
            auto t = tokenizeString(txt);
            assertNotThrown!MirIonTokenizerException(
                enforce!"skipWhitespace did not return expected character"(t.skipWhitespace() == expectedChar)
            );
        }

        test("/ 0)", '/');
        test("xyz_", 'x');
        test(" / 0)", '/');
        test(" xyz_", 'x');
        test(" \t\r\n / 0)", '/');
        test("\t\t  // comment\t\r\n\t\t  x", 'x');
        test(" \r\n /* comment *//* \r\n comment */x", 'x');
    }

    /++
    Skip whitespace within a clob/blob. 

    This function is just a wrapper around skipWhitespace, but toggles on it's "fail on comment" mode, as
    comments are not allowed within clobs/blobs.
    Returns:
        a character located after the whitespace within a clob/blob
    Throws:
        MirIonTokenizerException if a comment is found
    +/
    char skipLobWhitespace() @safe @nogc pure {
        return skipWhitespace!(false, false);
    }
    /// Test skipping over whitespace within a (c|b)lob
    version(mir_ion_parser_test) unittest
    {
        import std.exception : assertNotThrown;
        import mir.exception : enforce;
        import mir.ion.deser.text.tokens : MirIonTokenizerException;
        void test(string txt, char expectedChar)() {
            auto t = tokenizeString(txt);
            assertNotThrown!MirIonTokenizerException(
                enforce!"Lob whitespace did not match expected character"(t.skipLobWhitespace() == expectedChar)
            );
        }

        test!("///=", '/');
        test!("xyz_", 'x');
        test!(" ///=", '/');
        test!(" xyz_", 'x');
        test!("\r\n\t///=", '/');
        test!("\r\n\txyz_", 'x');
    }

    /++
    Check if the next characters within the input range are the special "infinity" type.

    Params:
        c = The last character read off of the stream (typically '+' or '-')
    Returns:
        true if it is the infinity type, false if it is not.
    +/
    bool isInfinity(char c) @safe @nogc pure {
        if (c != '+' && c != '-') return false;

        auto cs = peekMax(5);

        if (cs.length == 3 || (cs.length >= 3 && isStopChar(cs[3]))) {
            if (cs[0] == 'i' && cs[1] == 'n' && cs[2] == 'f') {
                skipExactly(3);
                return true;
            }
        }

        if ((cs.length > 3 && cs[3] == '/') && cs.length > 4 && (cs[4] == '/' || cs[4] == '*')) {
            skipExactly(3);
            return true;
        }

        return false;
    }
    /// Test scanning for inf
    version(mir_ion_parser_test) unittest
    {
        void test(string txt, bool inf, char after) {
            auto t = tokenizeString(txt);
            auto c = t.readInput();
            assert(t.isInfinity(c) == inf);
            assert(t.readInput() == after);
        }
        
        test("+inf", true, 0);
        test("-inf", true, 0);
        test("+inf ", true, ' ');
        test("-inf\t", true, '\t');
        test("-inf\n", true, '\n');
        test("+inf,", true, ',');
        test("-inf}", true, '}');
        test("+inf)", true, ')');
        test("-inf]", true, ']');
        test("+inf//", true, '/');
        test("+inf/*", true, '/');

        test("+inf/", false, 'i');
        test("-inf/0", false, 'i');
        test("+int", false, 'i');
        test("-iot", false, 'i');
        test("+unf", false, 'u');
        test("_inf", false, 'i');

        test("-in", false, 'i');
        test("+i", false, 'i');
        test("+", false, 0);
        test("-", false, 0);
    }

    /++
    Check if the current character selected is part of a triple quote (''')

    $(NOTE This function will not throw if an EOF is hit. It will simply return false.)
    Returns:
        true if the character is part of a triple quote,
        false if it is not.
    +/
    bool isTripleQuote() @safe @nogc pure {
        try {
            auto cs = peekExactly(2);

            // If the next two characters are '', then it is a triple-quote.
            if (cs[0] == '\'' && cs[1] == '\'') { 
                skipExactly(2);
                return true;
            }

            return false;
        } catch (MirIonTokenizerException e) {
            return false;
        }
    }

    /++
    Check if the current character selected is part of a whole number.

    If it is part of a whole number, then return the type of number (hex, binary, timestamp, number)
    Params:
        c = The last character read from the range
    Returns:
        the corresponding number type (or invalid)
    +/
    IonTokenType scanForNumber(char c) @safe @nogc pure 
    in {
        assert(isDigit(c), "Scan for number called with non-digit number");
    } body {
        const(char)[] cs;
        try {
            cs = peekMax(4);
        } catch(MirIonTokenizerException e) {
            return IonTokenType.TokenInvalid;
        }

        // Check if the first character is a 0, then check if the next character is a radix identifier (binary / hex)
        if (c == '0' && cs.length > 0) {
            switch(cs[0]) {
                case 'b':
                case 'B':
                    return IonTokenType.TokenBinary;
                
                case 'x':
                case 'X':
                    return IonTokenType.TokenHex;
                
                default:
                    break;
            }
        }

        // Otherwise, it's not, and we check if it's a timestamp or just a plain number.
        if (cs.length == 4) {
            foreach(i; 0 .. 3) {
                if (!isDigit(cs[i])) return IonTokenType.TokenNumber;
            }

            if (cs[3] == '-' || cs[3] == 'T') {
                return IonTokenType.TokenTimestamp;
            }
        }
        return IonTokenType.TokenNumber;

    }
    /// Test scanning for numbers 
    version(mir_ion_parser_test) unittest
    {
        import mir.ion.deser.text.tokens : IonTokenType;

        void test(string txt, IonTokenType expectedToken) {
            auto t = tokenizeString(txt);
            auto c = t.readInput();
            assert(t.scanForNumber(c) == expectedToken);
        }

        test("0b0101", IonTokenType.TokenBinary);
        test("0B", IonTokenType.TokenBinary);
        test("0xABCD", IonTokenType.TokenHex);
        test("0X", IonTokenType.TokenHex);
        test("0000-00-00", IonTokenType.TokenTimestamp);
        test("0000T", IonTokenType.TokenTimestamp);

        test("0", IonTokenType.TokenNumber);
        test("1b0101", IonTokenType.TokenNumber);
        test("1B", IonTokenType.TokenNumber);
        test("1x0101", IonTokenType.TokenNumber);
        test("1X", IonTokenType.TokenNumber);
        test("1234", IonTokenType.TokenNumber);
        test("12345", IonTokenType.TokenNumber);
        test("1,23T", IonTokenType.TokenNumber);
        test("12,3T", IonTokenType.TokenNumber);
        test("123,T", IonTokenType.TokenNumber);
    }

    /++
    Set the current token, and if we want to go into the token.
    Params:
        token = The updated token type
        finished = Whether or not we want to go into the token (and parse it)
    +/
    void ok(IonTokenType token, bool unfinished) @safe @nogc pure {
        this.currentToken = token;
        this.finished = !unfinished;
    }

    /++
    Read the next token from the range.
    Returns:
        true if it was able to read a valid token from the range.
    +/
    bool nextToken() @safe @nogc pure {
        char c;
        // if we're finished with the current value, then skip over the rest of it and go to the next token
        // this typically happens when we hit commas (or the like) and don't have anything to extract
        if (this.finished) {
            c = this.skipValue();
        } else {
            c = skipWhitespace();
        }

        // NOTE: these variable declarations are up here
        // since we would miss them within the switch decl.

        // have we hit an inf?
        bool inf;

        // second character
        char cs;
        
        with(IonTokenType) switch(c) {
            case 0:
                ok(TokenEOF, true);
                return true;
            case ':':
                cs = peekOne();
                if (cs == ':') {
                    skipOne();
                    ok(TokenDoubleColon, false);
                } else {
                    ok(TokenColon, false);
                }
                return true;
            case '{': 
                cs = peekOne();
                if (cs == '{') {
                    skipOne();
                    ok(TokenOpenDoubleBrace, true);
                } else {
                    ok(TokenOpenBrace, true);
                }
                return true;
            case '}':
                ok(TokenCloseBrace, false);
                return true;
            case '[':
                ok(TokenOpenBracket, true);
                return true;
            case ']':
                ok(TokenCloseBracket, true);
                return true;
            case '(':
                ok(TokenOpenParen, true);
                return true;
            case ')':
                ok(TokenCloseParen, true);
                return true;
            case ',':
                ok(TokenComma, false);
                return true;
            case '.':
                cs = peekOne();
                if (isOperatorChar(cs)) {
                    unread(cs);
                    ok(TokenSymbolOperator, true);
                    return true;
                }

                if (cs == ' ' || isIdentifierPart(cs)) {
                    unread(cs);
                }
                ok(TokenDot, false);
                return true;
            case '\'':
                if (isTripleQuote()) {
                    ok(TokenLongString, true);
                    return true;
                }
                ok(TokenSymbolQuoted, true);
                return true;
            case '+':
                inf = isInfinity(c);
                if (inf) {
                    ok(TokenFloatInf, false);
                    return true;
                }
                unread(c);
                ok(TokenSymbolOperator, true);
                return true;
            case '-':
                cs = peekOne();
                if (isDigit(cs)) {
                    skipOne();
                    IonTokenType tokenType = scanForNumber(cs);
                    if (tokenType == TokenTimestamp) {
                        throw ionTokenizerException(IonTokenizerErrorCode.negativeTimestamp);
                    }
                    unread(cs);
                    unread(c);
                    ok(tokenType, true);
                    return true;
                }

                inf = isInfinity(c);
                if (inf) {
                    ok(TokenFloatMinusInf, false);
                    return true;
                }
                unread(c);
                ok(TokenSymbolOperator, true);
                return true;

           static foreach(member; ION_OPERATOR_CHARS) {
                static if (member != '+' && member != '-' && member != '"' && member != '.') {
                    case member:
                        unread(c);
                        ok(TokenSymbolOperator, true);
                        return true;
                }
            }

            case '"':
                ok(TokenString, true);
                return true;

            static foreach(member; ION_IDENTIFIER_START_CHARS) {
                case member:
                    unread(c);
                    ok(TokenSymbol, true);
                    return true;
            } 

            static foreach(member; ION_DIGITS) {
                case member:
                    IonTokenType t = scanForNumber(c);
                    unread(c);
                    ok(t, true);
                    return true;
            }

            default:
                unexpectedChar(c);
                return false;
        }
    }

    /++
    Finish reading the current token, and skip to the end of it.
    
    This function will only work if we are in the middle of reading a token.
    Returns:
        false if we already finished with a token,
        true if we were able to skip to the end of it.
    Throws:
        MirIonTokenizerException if we were not able to skip to the end.
    +/
    bool finish() @safe @nogc pure {
        if (finished) {
            return false;
        }

        immutable char c = this.skipValue();
        unread(c);
        finished = true;
        return true;
    }

    /++
    Check if the given character is a "stop" character.

    Stop characters are typically terminators of objects, but here we overload and check if there's a comment after our character.
    Params:
        c = The last character read from the input range.
    Returns:
        true if the character is the "stop" character.
    +/
    bool isStopChar(char c) @safe @nogc pure {
        if (mir.ion.deser.text.tokens.isStopChar(c)) { // make sure
            return true;
        }

        if (c == '/') {
            const(char) c2 = peekOne();
            if (c2 == '/' || c2 == '*') {
                return true;
            }
        }

        return false;
    }

    /++
    Helper to generate a thrown exception (if an unexpected character is hit)
    +/
    void unexpectedChar(string file = __FILE__, int line = __LINE__)(char c, size_t pos = -1) @safe @nogc pure {
        if (c == 0) {
            throw ionTokenizerException!(file, line)(IonTokenizerErrorCode.unexpectedEOF);
        } else {
            throw ionTokenizerException!(file, line)(IonTokenizerErrorCode.unexpectedCharacter);
        }
    }

    /++
    Helper to throw if an unexpected end-of-file is hit.
    +/
    void unexpectedEOF(string file = __FILE__, int line = __LINE__)(size_t pos = -1) @safe @nogc pure {
        if (pos == -1) pos = this.position;
        unexpectedChar!(file, line)(0, pos);
    }

    /++
    Ensure that the next item in the range fulfills the predicate given.
    Params:
        pred = A predicate that the next character in the range must fulfill
    Throws:
        [MirIonTokenizerException] if the predicate is not fulfilled
    +/
    template expect(alias pred = "a", bool noRead = false, string file = __FILE__, int line = __LINE__) {
        import mir.functional : naryFun;
        static if (noRead) {
            char expect(char c) @trusted @nogc pure {
                if (!naryFun!pred(c)) {
                    unexpectedChar!(file, line)(c);
                }

                return c;
            }
        } else {
            char expect() @trusted @nogc pure {
                char c = readInput();
                if (!naryFun!pred(c)) {
                    unexpectedChar!(file, line)(c);
                }

                return c;
            }
        }
    }
    /// Text expect()
    version(mir_ion_parser_test) unittest
    {
        import mir.ion.deser.text.tokens : MirIonTokenizerException, isHexDigit;

        void testIsHex(string ts) {
            auto t = tokenizeString(ts);
            while (!t.isEOF) {
                import std.exception : assertNotThrown;
                assertNotThrown!MirIonTokenizerException(t.expect!(isHexDigit));
            }
        }

        void testFailHex(string ts) {
            auto t = tokenizeString(ts);
            while (!t.isEOF) {
                import std.exception : assertThrown;
                assertThrown!MirIonTokenizerException(t.expect!(isHexDigit));
            }
        }

        testIsHex("1231231231");
        testIsHex("BADBAB3");
        testIsHex("F00BAD");
        testIsHex("420");
        testIsHex("41414141");
        testIsHex("BADF00D");
        testIsHex("BaDf00D");
        testIsHex("badf00d");
        testIsHex("AbCdEf123");

        testFailHex("HIWORLT");
        testFailHex("Tst");
    }

    /++
    Ensure that the next item in the range does NOT fulfill the predicate given.

    This is the opposite of `expect` - which expects that the predicate is fulfilled.
    However, for all intents and purposes, the functionality of `expectFalse` is identical to `expect`.
    Params:
        pred = A predicate that the next character in the range must NOT fulfill.
    Throws:
        [MirIonTokenizerException] if the predicate is fulfilled.
    +/
    template expectFalse(alias pred = "a", bool noRead = false, string file = __FILE__, int line = __LINE__) {
        import mir.functional : naryFun;
        static if (noRead) {
            char expectFalse(char c) @trusted @nogc pure {
                if (naryFun!pred(c)) {
                    unexpectedChar!(file, line)(c);
                }

                return c;
            }
        } else {
            char expectFalse() @trusted @nogc pure {
                char c = readInput();
                if (naryFun!pred(c)) {
                    unexpectedChar!(file, line)(c);
                }

                return c;
            }
        }
    }
}

/++
Generic helper to verify the functionality of the parsing code in unit-tests
+/
void testRead(T)(ref T t, char expected, string file = __FILE__, int line = __LINE__) {
    import mir.exception : MirError;
    char v = t.readInput();
    if (v != expected) {
        import mir.format : stringBuf, print;
        stringBuf buf;
        throw new MirError(buf.print("Expected ", expected, " but got ", v).data, file, line);
    }
}

/++
Generic helper to verify the functionality of the parsing code in unit-tests
+/
void testPeek(T)(ref T t, char expected, string file = __FILE__, int line = __LINE__) {
    import mir.exception : MirError;
    char v = t.peekOne();
    if (v != expected) {
        import mir.format : stringBuf, print;
        stringBuf buf;
        throw new MirError(buf.print("Expected ", expected, " but got ", v).data, file, line);
    }
}
