module commonmarkd.ast;


// The AST describes a "document". It should be designed to support
// the following outputs: HTML, PDF, Markdown, SVG, images...

enum NodeType
{
    text,
    paragraph
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

class NodeParagraph
{

}