module commonmarkd.ast;


// The AST describes a "document". It should be designed to support
// the following outputs: HTML, PDF, Markdown, SVG, images...

enum NodeType
{
    text,
    paragraph,
    italic,
    bold,
}


class Node
{
private:
    NodeType _type;

public:
    this(NodeType type)
    {
        _type = type;
    }

    NodeType type()
    {
        return _type;
    }

    /// Renders HTML and return a UTF-8 string
    abstract string renderHTML();

    /// Renders CommonMark and return a UTF-8 string
    abstract string renderCommonMark();
}

class NodeText : Node
{
    this(string text)
    {
        super(NodeType.text);
        _text = text;
    }

    override string renderHTML()
    {
        // TODO: escape HTML
        return _text;
    }

    override string renderCommonMark()
    {
        return _text;
    }

private:
    string _text;
}

class NodeParagraph : Node
{
    this(Node wrapped)
    {
        super(NodeType.paragraph);
        _wrapped = wrapped;
    }

    override string renderHTML()
    {
        // TODO: escape HTML
        return "<p>" ~ _wrapped.renderHTML() ~ "</p>";
    }

    override string renderCommonMark()
    {
        return _wrapped.renderCommonMark() ~ "\n\n";
    }
private:
    Node _wrapped;
}

class NodeItalic : Node
{
    this(Node wrapped)
    {
        super(NodeType.italic);
        _wrapped = wrapped;
    }

    override string renderHTML()
    {
        // TODO: escape HTML
        return "<em>" ~ _wrapped.renderHTML() ~ "</em>";
    }

    override string renderCommonMark()
    {
        return "_" ~ _wrapped.renderCommonMark() ~ "_";
    }
private:
    Node _wrapped;
}

class NodeBold : Node
{
    this(Node wrapped)
    {
        super(NodeType.bold);
        _wrapped = wrapped;
    }

    override string renderHTML()
    {
        // TODO: escape HTML
        return "<strong>" ~ _wrapped.renderHTML() ~ "</strong>";
    }

    override string renderCommonMark()
    {
        return "**" ~ _wrapped.renderCommonMark() ~ "**";
    }

private:
    Node _wrapped;    
}