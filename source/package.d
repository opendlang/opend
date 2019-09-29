module commonmarkd;


enum MarkdownFlag : int
{
     collapseWhitespace       = 0x0001,  /* Collapse non-trivial whitespace into single ' ' */
     permissiveATXHeaders     = 0x0002,  /* Do not require space in ATX headers ( ###header ) */
     permissiveURLAutoLinks   = 0x0004,  /* Recognize URLs as autolinks even without '<', '>' */
     permissiveEmailAutoLinks = 0x0008,  /* Recognize e-mails as autolinks even without '<', '>' and 'mailto:' */
     noIndentedCodeBlocks     = 0x0010,  /* Disable indented code blocks. (Only fenced code works.) */
     noHTMLBlocks             = 0x0020,  /* Disable raw HTML blocks. */
     noHTMLSpans              = 0x0040,  /* Disable raw HTML (inline). */
     tablesExtension          = 0x0100,  /* Enable tables extension. */
     enableStrikeThrough      = 0x0200,  /* Enable strikethrough extension. */
     permissiveWWWAutoLinks   = 0x0400,  /* Enable WWW autolinks (even without any scheme prefix, if they begin with 'www.') */
     enableTaskLists          = 0x0800,  /* Enable task list extension. */
     latexMathSpans           = 0x1000,  /* Enable $ and $$ containing LaTeX equations. */

     permissiveAutoLinks      = permissiveEmailAutoLinks | permissiveURLAutoLinks | permissiveWWWAutoLinks,
     noHTML                   = noHTMLBlocks | noHTMLSpans,

    /* Convenient sets of flags corresponding to well-known Markdown dialects.
     *
     * Note we may only support subset of features of the referred dialect.
     * The constant just enables those extensions which bring us as close as
     * possible given what features we implement.
     *
     * ABI compatibility note: Meaning of these can change in time as new
     * extensions, bringing the dialect closer to the original, are implemented.
     */
    dialectCommonMark          = 0,
    dialectGitHub              = (permissiveAutoLinks | tablesExtension | enableStrikeThrough | enableTaskLists),
}

//debug = debugOutput;


/// Parses CommonMark input, returns HTML.
/// The only public function of the package!
string convertCommonMarkToHTML(const(char)[] input, MarkdownFlag flags = MarkdownFlag.dialectCommonMark)
{
    import commonmarkd.md4c;

    static struct GrowableBuffer
    {
        string data;

        void append(const(char)[] suffix)
        {
            data ~= suffix;
        }
        
        static void appendCallback(const(char)* chars, uint size, void* userData)
        {
            GrowableBuffer* gb = cast(GrowableBuffer*) userData;
            gb.append(chars[0..size]);
        }
    }

    GrowableBuffer gb;

    debug(debugOutput)
        int renderFlags = MD_RENDER_FLAG_DEBUG;
    else
        int renderFlags = 0;

    int ret = md_render_html(input.ptr, 
                             cast(uint) input.length,
                             &GrowableBuffer.appendCallback,
                             &gb, flags, renderFlags);
    return gb.data;
}

// Execute the CommonMark specification test suite
unittest
{
    import std.file;
    import std.json;
    import std.stdio;
    import std.string;

    const(char)[] json = cast(char[]) std.file.read("spec-tests.json");
    JSONValue root = parseJSON(json);
    assert(root.type() == JSONType.array);

    JSONValue[] tests = root.array;

    writefln("%s tests parsed.", tests.length);

    int numPASS = 0;
    int numFAIL = 0;
    for (size_t n = 0; n < tests.length; ++n)
    {
        JSONValue test = tests[n];
        string markdown = test["markdown"].str;
        string expectedHTML = test["html"].str;
        long example = test["example"].integer;

        string html;
        try
        {
            html = convertCommonMarkToHTML(markdown, MarkdownFlag.dialectCommonMark);
        }
        catch(Throwable t)
        {
            html = t.msg;
        }

        // Note: It seems Markdown spec says nothing about what line endings should get generated.
        // So we replace every \r\n by just \n before comparison, else it create bugs depending
        // on which system CommonMark test suite has been generated.
        html = html.replace("\r\n", "\n");
        expectedHTML = expectedHTML.replace("\r\n", "\n");

        if ( html == expectedHTML )
        {
            numPASS++;
        }
        else
        {
            long start_line = test["start_line"].integer; 
            long end_line = test["end_line"].integer;
            string section = test["section"].str;
            writef("Test %d: ", example);
            writefln("FAIL\n***Markdown:\n\n%s\n\n*** Expected (length %s):\n\n%s\n\n*** Got instead (length %s):\n\n%s\n\nSee specifications lines %d-%d section %s", 
                      markdown, expectedHTML.length, expectedHTML, html.length, html, start_line, end_line, section);
            numFAIL++;
        }
    }

    writefln("%s / %s tests passed.", numPASS, tests.length);

}