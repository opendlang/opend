/++
Token definitions for parsing Ion Text.

Authors: Harrison Ford
+/
module mir.ion.deser.text.tokens;
/++
Ion Token Types
+/
enum IonTokenType : ubyte 
{
    /++ Invalid token +/
    TokenInvalid,

    /++ EOF +/
    TokenEOF,

    /++ numbers +/
    TokenNumber,

    /++ 0b[01]+ +/
    TokenBinary,

    /++ 0x[0-9a-fA-F]+ +/
    TokenHex,

    /++ +inf +/
    TokenFloatInf,

    /++ -inf +/
    TokenFloatMinusInf,

    /++
    2020-01-01T00:00:00.000Z

    All timestamps *must* be compliant to ISO-8601
    +/
    TokenTimestamp,

    /++ [a-zA-Z_]+ +/
    TokenSymbol,

    /++ '[^']+' +/
    TokenSymbolQuoted,

    /++ [+-/*] +/
    TokenSymbolOperator,

    /++ "[^"]+" +/
    TokenString,

    /++ '''[^']+''' +/
    TokenLongString,

    /++ [.] +/
    TokenDot,

    /++ [,] +/
    TokenComma,

    /++ : +/
    TokenColon,

    /++ :: +/
    TokenDoubleColon,

    /++ ( +/
    TokenOpenParen,

    /++ ) +/
    TokenCloseParen,

    /++ { +/
    TokenOpenBrace,

    /++ } +/
    TokenCloseBrace,

    /++ [ +/
    TokenOpenBracket,

    /++ ] +/
    TokenCloseBracket,

    /++ {{ +/ 
    TokenOpenDoubleBrace,

    /++ }} +/ 
    TokenCloseDoubleBrace
}
///
version(mir_ion_test) unittest 
{
    static assert(!IonTokenType.TokenInvalid);
    static assert(IonTokenType.TokenInvalid == IonTokenType.init);
    static assert(IonTokenType.TokenEOF > 0);
}

/++
Get a stringified version of a token.
Params:
    code = $(LREF IonTokenType)
Returns:
    Stringified version of the token
+/
    
string ionTokenMsg(IonTokenType token) @property
@safe pure nothrow @nogc
{
    static immutable string[] tokens = [
        "<invalid>",
        "<EOF>",
        "<number>",
        "<binary>",
        "<hex>",
        "+inf",
        "-inf",
        "<timestamp>",
        "<symbol>",
        "<quoted-symbol>",
        "<operator>",
        "<string>",
        "<long-string>",
        ".",
        ",",
        ":",
        "::",
        "(",
        ")",
        "{",
        "}",
        "[",
        "]",
        "{{",
        "}}",
        "<error>"
    ];
    return tokens[token - IonTokenType.min];
}
///
@safe pure nothrow @nogc
version(mir_ion_test) unittest
{
    static assert(IonTokenType.TokenInvalid.ionTokenMsg == "<invalid>");
    static assert(IonTokenType.TokenCloseDoubleBrace.ionTokenMsg == "}}");
}


/++
All valid Ion operator characters.
+/
static immutable ION_OPERATOR_CHARS = ['!', '#', '%', '&', '*', '+', '-', '.', '/', ';', '<', '=',
        '>', '?', '@', '^', '`', '|', '~'];

/++
All characters that Ion considers to be whitespace
+/
static immutable ION_WHITESPACE = [' ', '\t', '\n', '\r'];

/++
All characters that Ion considers to be the end of a token (stop chars)
+/
static immutable ION_STOP_CHARS = [0, '{', '}', '[', ']', '(', ')', ',', '"', '\'',
        ' ', '\t', '\n', '\r'];

/++
All valid digits within Ion (0-9)
+/
static immutable ION_DIGITS = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];

/++
All valid hex digits within Ion ([a-fA-F0-9])
+/
static immutable ION_HEX_DIGITS = ION_DIGITS ~ ['a', 'b', 'c', 'd', 'e', 'f', 'A', 'B', 'C', 'D', 'E', 'F'];

/++
All valid lowercase letters within Ion
+/
static immutable ION_LOWERCASE = 
    ['a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k', 'l', 'm', 'n', 'o', 'p', 'q', 'r', 's', 't', 'u', 'v', 'w', 'x', 'y', 'z'];

/++
All valid uppercase letters within Ion
+/
static immutable ION_UPPERCASE =
    ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z'];

/++
All valid characters which can be the beginning of an identifier (a-zA-Z_$)
+/
static immutable ION_IDENTIFIER_START_CHARS = ION_LOWERCASE ~ ION_UPPERCASE ~ ['_', '$'];

/++
All valid characters which can be within an identifier (a-zA-Z$_0-9)
+/
static immutable ION_IDENTIFIER_CHARS = ION_IDENTIFIER_START_CHARS ~ ION_DIGITS;

/++
All symbols which must be surrounded by quotes
+/
static immutable ION_QUOTED_SYMBOLS = ["", "null", "true", "false", "nan"];

@safe:
/++
Check if a character is considered by Ion to be a digit.
Params:
    c = The character to check
Returns:
    true if the character is considered by Ion to be a digit.
+/
bool isDigit(ubyte c) {
    static foreach(member; ION_DIGITS) {
        if (c == member) return true;
    }
    return false;
}

/++
Check if a character is considered by Ion to be a hex digit.
Params:
    c = The character to check
Returns:
    true if the character is considered by Ion to be a hex digit.
+/
bool isHexDigit(ubyte c) {
    static foreach(member; ION_HEX_DIGITS) {
        if (c == member) return true;
    }
    return false;
}

/++
Check if a character is considered by Ion to be a valid start to an identifier.
Params:
    c = The character to check
Returns:
    true if the character is considered by Ion to be a valid start to an identifier.
+/
bool isIdentifierStart(ubyte c) {
    static foreach(member; ION_IDENTIFIER_CHARS) {
        if (c == member) return true;
    }
    return false;
}

/++
Check if a character is considered by Ion to be a valid part of an identifier.
Params:
    c = The character to check
Returns:
    true if the character is considered by Ion to be a valid part of an identifier.
+/
bool isIdentifierPart(ubyte c) {
    return isIdentifierStart(c) || isDigit(c);
}   

/++
Check if a character is considered by Ion to be a symbol operator character.
Params:
    c = The character to check
Returns:
    true if the character is considered by Ion to be a symbol operator character.
+/
bool isOperatorChar(ubyte c) {
    static foreach(member; ION_OPERATOR_CHARS) {
        if (c == member) return true;
    }
    return false;
}

/++
Check if a character is considered by Ion to be a "stop" character.
Params:
    c = The character to check
Returns:
    true if the character is considered by Ion to be a "stop" character.
+/
bool isStopChar(ubyte c) {
    static foreach(member; ION_STOP_CHARS) {
        if (c == member) return true;
    }

    return false;
}

/++
Check if a character is considered by Ion to be whitespace.
Params:
    c = The character to check
Returns:
    true if the character is considered by Ion to be whitespace.
+/
bool isWhitespace(ubyte c) {
    static foreach(member; ION_WHITESPACE) {
        if (c == member) return true;
    }
    return false;
}

/++
Check if a character is considered by Ion to be a hex digit.
Params:
    c = The character to check
Returns:
    true if the character is considered by Ion to be a hex digit.
+/
bool symbolNeedsQuotes(string symbol) {
    static foreach(member; ION_QUOTED_SYMBOLS) {
        if (symbol == member) return true;
    }

    if (!isIdentifierStart(symbol[0])) return true;
    for (auto i = 0; i < symbol.length; i++) {
        if (!isIdentifierPart(symbol[i])) return true;
    }
    return false;
}

/++
Check if a character is a new-line character.

Params:
    c = The character to check
Returns:
    true if a character is considered to be a new-line.
+/
bool isNewLine(ubyte c) {
    return c == 0x0A || 0x0D;
}

/++
Check if a character is printable whitespace within a string.

Params:
    c = The character to check
Returns:
    true if a character is considered to be printable whitespace.
+/
bool isStringWhitespace(ubyte c) {
    return c == 0x09 || c == 0x0B || c == 0x0C;
}

/++
Check if a character is a control character.

Params:
    c = The character to check
Returns:
    true if a character is considered a control character.
+/
bool isControlChar(ubyte c) {
    return c < 0x20 || c == 0x7F;
}

/++
Check if a character is within the valid ASCII range (0x00 - 0x7F)
    
Params:
    c = The character to check
Returns:
    true if a character is considered to be valid ASCII.
+/
bool isASCIIChar(ubyte c) {
    return c <= 0x7F;
}

/++
Check if a character is invalid (non-printable).
Params:
    c = The character to check
Returns:
    true if a character is invalid, false otherwise
+/
bool isInvalidChar(ubyte c) {
    if (isStringWhitespace(c) || isNewLine(c)) return false;
    if (isControlChar(c)) return true;
    return false;
}

/++
Convert a character that represents a hex-digit into it's actual form.

This is to convert a hex-literal as fast as possible.
Params:
    c = a hex character
+/
ubyte hexLiteral(ubyte c) {
    if (isDigit(c)) return cast(ubyte)(c - ION_DIGITS[0]);
    else if (c >= 'a' && c <= 'f') return cast(ubyte)(10 + (c - ION_LOWERCASE[0]));
    else if (c >= 'A' && c <= 'F') return cast(ubyte)(10 + (c - ION_UPPERCASE[0]));
    throw new MirIonTokenizerException("invalid hex literal");
}

version(D_Exceptions):
import mir.ion.exception;

/++
Mir Ion Tokenizer Exception
+/
class MirIonTokenizerException : MirIonException 
{
    ///
    @safe pure nothrow @nogc
    this(string msg, string file = __FILE__, int line = __LINE__)
    {
        super(msg, file, line);
    }
}
