module commonmarkd;

/// Parses CommonMark input, returns HTML.
/// The only public function of the package!
string convertCommonMarkToHTML(const(char)[] input)
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

    int ret = md_render_html(input.ptr, 
                             cast(uint) input.length,
                             &GrowableBuffer.appendCallback,
                             &gb, 0, 0);
    return gb.data;
}

// Execute the CommonMark specification test suite
unittest
{
    import std.file;
    import std.json;
    import std.stdio;

    const(char)[] json = cast(char[]) std.file.read("spec-tests.json");
    JSONValue root = parseJSON(json);
    assert(root.type() == JSONType.array);

    JSONValue[] tests = root.array;

    writefln("%s tests parsed.", tests.length);

    for (size_t n = 0; n < tests.length; ++n)
    {
        JSONValue test = tests[n];
        string markdown = test["markdown"].str;
        string expectedHTML = test["html"].str;
        long example = test["example"].integer;

        writef("Test %d: ", example);

        string html;
        try
        {
            html = convertCommonMarkToHTML(markdown);
        }
        catch(Throwable t)
        {
            html = t.msg;
        }

        if ( html == expectedHTML )
        {
            writeln("PASS");
        }
        else
        {            
            long start_line = test["start_line"].integer; 
            long end_line = test["end_line"].integer;
            string section = test["section"].str;

            writefln("FAIL\n***Markdown:\n\n%s\n\n*** Expected:\n\n%s\n\n*** Got instead:\n\n%s\n\nSee specifications lines %d-%d section %s", 
                      markdown, expectedHTML, html, start_line, end_line, section);
            assert(false);
        }
    }
}