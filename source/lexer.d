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