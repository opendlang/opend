module commonmarkd.lexer;

enum TokenType
{
	endOfLine,
}

struct Token
{
	TokenType type;
	int line;
	int column;
}

struct CommonMarkLexer
{
public:
	void initialize(const(char)[] input)
	{
		_input = input;
		_currentLine = 1;
		_currentColumn = 1;
	}

	Token makeToken(TokenType type)
	{
		Token t;
		t.type = type;
		t.line = _currentLine;
		t.column = _currentColumn;
		return t;
	}

	Token nextToken()
	{
		return makeToken(TokenType.endOfLine);
	}

private:
	const(char)[] _input;
	int _currentColumn;
	int _currentLine;
}

private:

pure nothrow @nogc @safe
{
    bool isWhite(dchar ch)
    {
        return ch == ' ' || ch == '\n' || ch == '\r' || ch == 0x0b || ch == 0x0C || ch == '\t';
    }

    bool isUniWhite(dchar ch)
    {
        switch (ch)
        {
            case 0x0009: case 0x000A: case 0x000C: case 0x000D: 
            case 0x0020: case 0x00A0: case 0x1680: case 0x2000: 
            case 0x2001: case 0x2002: case 0x2003: case 0x2004: 
            case 0x2005: case 0x2006: case 0x2007: case 0x2008: 
            case 0x2009: case 0x200A: case 0x202F: case 0x205F: 
            case 0x3000: 
                return true;
            default:
                return false;
        }
    }

    bool isAsciiControlChar(dchar ch)
    {
        return ch < 0x0080u;
    }

    bool isAsciiPunctuationCharacter(dchar ch)
    {
        return ((ch >= 0x21) && (ch <= 0x2f))
            || ((ch >= 0x3A) && (ch <= 0x40))
            || ((ch >= 0x5B) && (ch <= 0x60))
            || ((ch >= 0x7B) && (ch <= 0x7E));
    }
}