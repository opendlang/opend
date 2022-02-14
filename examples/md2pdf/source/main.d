static import std.file;
import std.stdio;
import std.conv;
import std.format;

import printed.canvas;
import printed.flow;
import commonmarkd;
import arsd.dom;
import colorize;

void usage()
{
    cwriteln("Usage:".white);
    cwriteln("        md2pdf input0.md ... inputN.md [-o output.pdf][--html output.html]".cyan);
    cwriteln();
    cwriteln("Description:".white);
    cwriteln("        Converts CommonMark to PDF.");
    cwriteln;
    cwriteln("Flags:".white);
    cwriteln("        -h, --help  Shows this help");
    cwriteln("        -o          Output file path (default: output.pdf)");
    cwriteln("        --html      Output intermediate HTML (default: no output)");
    cwriteln;
}

int main(string[] args)
{
    try
    {
        bool help = false;
        string[] inputPathes = [];
        string outputPath = "output.pdf";
        string htmlPath = null;

        for (int i = 1; i < args.length; ++i)
        {
            string arg = args[i];
            if (arg == "-h" || arg == "--help")
                help = true;
            else if (arg == "-o")
            {
                ++i;
                outputPath = args[i];
            }
            else if (arg == "--html")
            {
                ++i;
                htmlPath = args[i];
            }
            else
            {
                inputPathes ~= args[i];
            }
        }

        if (help)
        {
            usage();
            return 1;
        }

        if (inputPathes.length == 0) 
            throw new Exception("Need Markdown input files. Use --help for usage.");

        // Concatenate the markdown files
        string concatMD = "";
        foreach(input; inputPathes)
        {
            concatMD ~= cast(string) std.file.read(input);
        }

        string html = concatMD.convertMarkdownToHTML;

        string fullHTML = 
            "<html>\n" ~
            "<body>\n" ~
            html ~
            "</body>\n" ~
            "</html>\n";

        if (htmlPath)
        {
            std.file.write(htmlPath, fullHTML);
            cwritefln(" => Written HTML %s (%s)".green, htmlPath, prettyByteSize(fullHTML.length));
        }

        // Parse DOM
        auto dom = new Document();
        bool caseSensitive = true, strict = true;
        dom.parseUtf8(fullHTML, caseSensitive, strict);

        int widthMm = 210;
        int heightMm = 297;
        auto pdf = new PDFDocument(widthMm, heightMm);

        StyleOptions style;
        style.fontFace = "Jost";
        style.strong.fontWeight = FontWeight.semiBold;
        style.code.color = "rgb(160,95,9)";
        style.pre.color = "rgb(160,95,9)";

        IFlowDocument doc = new FlowDocument(pdf, style);

        // Traverse HTML and generate corresponding IFlowDocument commands

        Element bodyNode = dom.root;
        assert(bodyNode !is null);

        void renderNode(Element elem)
        {
            debug(domTraversal) writeln(">", elem.tagName);
            // Enter the node
            switch(elem.tagName)
            {
                case "p": doc.enterParagraph(); break;
                case "b": case "strong": doc.enterBold(); break;
                case "i": case "em": doc.enterEmph(); break;
                case "code": doc.enterCode(); break;
                case "pre": doc.enterPre(); break;
                case "h1": doc.enterH1(); break;
                case "h2": doc.enterH2(); break;
                case "h3": doc.enterH3(); break;
                case "h4": doc.enterH4(); break;
                case "h5": doc.enterH5(); break;
                case "h6": doc.enterH6(); break;
                case "ol": doc.enterOrderedList(); break;
                case "ul": doc.enterUnorderedList(); break;
                case "li": doc.enterListItem(); break;
                default:
                    break;
            }

            // If it's a text node, display text
            if (auto textNode = cast(TextNode)elem)
            {
                string s = textNode.nodeValue();
                doc.text(s);
            }

            // Render children
            foreach(c; elem.children)
                renderNode(c);

            // Exit the node
            switch(elem.tagName)
            {
                case "html": doc.finalize(); break;
                case "p": doc.exitParagraph(); break;
                case "b": case "strong": doc.exitBold(); break;
                case "i": case "em": doc.exitEmph(); break;
                case "code": doc.exitCode(); break;
                case "pre": doc.exitPre(); break;
                case "h1": doc.exitH1(); break;
                case "h2": doc.exitH2(); break;
                case "h3": doc.exitH3(); break;
                case "h4": doc.exitH4(); break;
                case "h5": doc.exitH5(); break;
                case "h6": doc.exitH6(); break;
                case "br": doc.br(); break; // MAYDO: not sure where a HTML br tag with text inside would put the line break
                case "ol": doc.exitOrderedList(); break;
                case "ul": doc.exitUnorderedList(); break;
                case "li": doc.exitListItem(); break;
                default:
                    break;
            }
            debug(domTraversal) writeln("<", elem.tagName);
        }

        renderNode(bodyNode);

        const(ubyte)[] bytes = pdf.bytes();

        std.file.write(outputPath, bytes);
        cwritefln(" => Written PDF %s (%s)".green, outputPath, prettyByteSize(bytes.length));
        return 0;
    }
    catch(Exception e)
    {
        error(e.msg);
        return 2;
    }
}

bool enableColoredOutput = true;

string white(string s) @property
{
    if (enableColoredOutput) return s.color(fg.light_white);
    return s;
}

string cyan(string s) @property
{
    if (enableColoredOutput) return s.color(fg.light_cyan);
    return s;
}

string green(string s) @property
{
    if (enableColoredOutput) return s.color(fg.light_green);
    return s;
}

string red(string s) @property
{
    if (enableColoredOutput) return s.color(fg.light_red);
    return s;
}

void error(string msg)
{
    cwritefln("error: %s".red, msg);
}

string prettyByteSize(size_t size)
{
    if (size < 10000)
        return format("%s bytes", size);
    else if (size < 1024*1024)
        return format("%s kb", (size + 512) / 1024);
    else
        return format("%s mb", (size + 1024*512) / (1024*1024));
}