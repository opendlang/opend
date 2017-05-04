module commonmarkd.ast;

enum NodeType
{
    text,
    paragraph
}


class Node
{
public:
    this(NodeType type)
    {
        _type = type;
    }

    NodeType type()
    {
        return _type;
    }

    abstract void renderHTML(RendererHTML r);

private:
    NodeType _type;
}

interface RendererHTML
{
    void outString(string s);
}

class NodeText : Node
{
    this(string text)
    {
        super(NodeType.text);
        _text = text;
    }

    override void renderHTML(RendererHTML r)
    {
        // TODO: escape HTML
        r.outString(_text);
    }

private:
    string _text;
}

class NodeParagraph
{

}