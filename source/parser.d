module commonmarkd.parser;

import commonmarkd.lexer;
import commonmarkd.ast;

struct CommonMarkParser
{
public:
    
    /// Initialize the parser with the whole input.
    /// Input doesn't gets copied.
    /// Only UTF-8 input supported.
    void initialize(const(char)[] input)
    {
        _lexer.initialize(input);
        next(); // pop first token
    }

    /// Parse a CommonMark input
    Node parseDocument()
    {
        return new NodeText("Hey");
    }

private:
    CommonMarkLexer _lexer;

    NodeType _type;
    Token _tok;

    Token peek()
    {
        return _tok;
    }

    void next()
    {
        _tok = _lexer.nextToken();
    }    
}


/// Parses CommonMark input, returns an AST.
Node parseCommonMark(const(char)[] input)
{
    CommonMarkParser parser;
    parser.initialize(input);
    return parser.parseDocument();
}

/// Parses CommonMark input, returns HTML.
string convertCommonMarkToHTML(const(char)[] input)
{
    return parseCommonMark(input).renderHTML();
}


/// Parses CommonMark input, returns CommonMark (normalizing).
string convertCommonMarkToCommonMark(const(char)[] input)
{
    return parseCommonMark(input).renderCommonMark();
}


