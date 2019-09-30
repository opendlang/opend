module commonmarkd;

/// Options for Markdown parsing.
enum MarkdownFlag : int
{
     collapseWhitespace       = 0x0001,  /** Collapse non-trivial whitespace into single ' ' */
     permissiveATXHeaders     = 0x0002,  /** Do not require space in ATX headers ( ###header ) */
     permissiveURLAutoLinks   = 0x0004,  /** Recognize URLs as autolinks even without '<', '>' */
     permissiveEmailAutoLinks = 0x0008,  /** Recognize e-mails as autolinks even without '<', '>' and 'mailto:' */
     noIndentedCodeBlocks     = 0x0010,  /** Disable indented code blocks. (Only fenced code works.) */
     noHTMLBlocks             = 0x0020,  /** Disable raw HTML blocks. */
     noHTMLSpans              = 0x0040,  /** Disable raw HTML (inline). */
     tablesExtension          = 0x0100,  /** Enable tables extension. */
     enableStrikeThrough      = 0x0200,  /** Enable strikethrough extension. */
     permissiveWWWAutoLinks   = 0x0400,  /** Enable WWW autolinks (even without any scheme prefix, if they begin with 'www.') */
     enableTaskLists          = 0x0800,  /** Enable task list extension. */
     latexMathSpans           = 0x1000,  /** Enable $ and $$ containing LaTeX equations. */

     permissiveAutoLinks      = permissiveEmailAutoLinks | permissiveURLAutoLinks | permissiveWWWAutoLinks, /** Recognize e-mails, URL and WWW links */
     noHTML                   = noHTMLBlocks | noHTMLSpans, /** Disable raw HTML. */

    /* Convenient sets of flags corresponding to well-known Markdown dialects.
     *
     * Note we may only support subset of features of the referred dialect.
     * The constant just enables those extensions which bring us as close as
     * possible given what features we implement.
     *
     * ABI compatibility note: Meaning of these can change in time as new
     * extensions, bringing the dialect closer to the original, are implemented.
     */
    dialectCommonMark          = 0, /** CommonMark */
    dialectGitHub              = (permissiveAutoLinks | tablesExtension | enableStrikeThrough | enableTaskLists), /** Github Flavoured Markdown */
}

deprecated("Use convertMarkdownToHTML instead") alias convertCommonMarkToHTML = convertMarkdownToHTML;

/// Parses a Markdown input, returns HTML. `flags` set the particular Markdown dialect that is used.
string convertMarkdownToHTML(const(char)[] input, MarkdownFlag flags = MarkdownFlag.dialectCommonMark)
{
    import commonmarkd.md4c;
    import core.stdc.stdlib;

    static struct GrowableBuffer
    {
    nothrow:
    @nogc:
        char* buf = null;
        size_t size = 0;
        size_t allocated = 0;

        void ensureSize(size_t atLeastthisSize)
        {
            if (atLeastthisSize > allocated)
            {
                allocated = 2 * allocated + atLeastthisSize + 1; // TODO: enhancing this estimation probably beneficial to performance
                buf = cast(char*) realloc(buf, allocated);
            }

        }

        ~this()
        {
            if (buf)
            {
                free(buf);
                buf = null;
                size = 0;
                allocated = 0;
            }
        }

        void append(const(char)[] suffix)
        {
            size_t L = suffix.length;
            ensureSize(size + L);            
            buf[size..size+L] = suffix[0..L];
            size += L;
        }

        const(char)[] getData()
        {
            return buf[0..size];
        }

        static void appendCallback(const(char)* chars, uint size, void* userData)
        {
            GrowableBuffer* gb = cast(GrowableBuffer*) userData;
            gb.append(chars[0..size]);
        }
    }

    GrowableBuffer gb;
    gb.ensureSize(input.length); // TODO: enhancing this estimation probably beneficial to performance

    //int renderFlags = MD_RENDER_FLAG_DEBUG;
    int renderFlags = 0;

    int ret = md_render_html(input.ptr, 
                             cast(uint) input.length,
                             &GrowableBuffer.appendCallback,
                             &gb, flags, renderFlags);
    return gb.getData.idup; // Note: this is the only GC-using stuff
}

// Execute the CommonMark specification test suite
unittest
//void main()
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
            html = convertMarkdownToHTML(markdown, MarkdownFlag.dialectCommonMark);
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

        // Poor attempt at HTML normalization
        html = html.replace("\n", "");
        expectedHTML = expectedHTML.replace("\n", "");

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