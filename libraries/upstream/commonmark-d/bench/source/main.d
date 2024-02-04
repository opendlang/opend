import std.path;
import std.algorithm;
import core.time;
import dmarkdown;
import std.file;
import std.stdio;
import core.memory;
import hunt.markdown.node.Node;
import hunt.markdown.parser.Parser;
import hunt.markdown.renderer.html.HtmlRenderer;
import commonmarkd;

/// Returns: Most precise clock ticks, in milliseconds.
long getTickUs() nothrow @nogc
{
    import core.time;
    return convClockFreq(MonoTime.currTime.ticks, MonoTime.ticksPerSecond, 1_000_000);
}

void main()
{
    auto files = filter!`endsWith(a.name,".md")`(dirEntries("content",SpanMode.shallow));
    
    Parser parser = Parser.builder().build();
    HtmlRenderer renderer = HtmlRenderer.builder().build();

    // "<p>This is <em>New</em></p>\n"
    foreach(file; files)
    {
        writefln("*** Parsing file %s", file);
        string fileContent = cast(string)(std.file.read(file));

        long A = getTickUs();
        string resultWithDMarkdown = filterMarkdown(fileContent);
        long B = getTickUs();

        Node document = parser.parse(fileContent);
        string resultWithHuntMarkdown = renderer.render(document);
        long C = getTickUs();

        string resultWithCommonMarkD = convertMarkdownToHTML(fileContent);
        long D = getTickUs();

        long timeDMarkdownMs = B - A;
        long timeHuntMs = C - B;
        long timeCommonmarkd = D - C;
        writefln("time dmarkdown     = %s us, HTML length = %s", timeDMarkdownMs, resultWithDMarkdown.length);
        writefln("time hunt-markdown = %s us, HTML length = %s", timeHuntMs, resultWithHuntMarkdown.length);
        writefln("time commonmark-d  = %s us, HTML length = %s", timeCommonmarkd, resultWithCommonMarkD.length);
        writeln;
    }


}