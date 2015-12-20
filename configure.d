import std.conv, std.file, std.string, std.path, std.process, std.stdio;

struct CairoConfiguration
{
    // if true, use minimal default set as defined in cairo.c.config
    bool CAIROD_CONFIGURE_FAILED = false;
    bool CAIRO_HAS_PS_SURFACE = false;
    bool CAIRO_HAS_PDF_SURFACE = false;
    bool CAIRO_HAS_SVG_SURFACE = false;
    bool CAIRO_HAS_WIN32_SURFACE = false;
    bool CAIRO_HAS_WIN32_FONT = false;
    bool CAIRO_HAS_FT_FONT = false;
    bool CAIRO_HAS_XCB_SURFACE = false;
    bool CAIRO_HAS_DIRECTFB_SURFACE = false;
    bool CAIRO_HAS_XLIB_SURFACE = false;
    bool CAIRO_HAS_PNG_FUNCTIONS = false;
}

void main(string[] args)
{
    writeDoubleLine();
    writeln("=> Configuring cairoD");
    writeln("=> Environment variables:");
    writeln("   CC               C compiler used to detect cairo features");
    writeln("   CAIROD_FEATURES  Manually overwrite feature flags");
    writeln();

    CairoConfiguration conf;
    // First check manual configuration
    string features = environment.get("CAIROD_FEATURES");
    if (features !is null)
    {
        foreach (entry; features.split(" "))
        {
            switch (entry)
            {
            case "CAIRO_HAS_PS_SURFACE":
                conf.CAIRO_HAS_PS_SURFACE = true;
                break;
            case "CAIRO_HAS_PDF_SURFACE":
                conf.CAIRO_HAS_PDF_SURFACE = true;
                break;
            case "CAIRO_HAS_SVG_SURFACE":
                conf.CAIRO_HAS_SVG_SURFACE = true;
                break;
            case "CAIRO_HAS_WIN32_SURFACE":
                conf.CAIRO_HAS_WIN32_SURFACE = true;
                break;
            case "CAIRO_HAS_WIN32_FONT":
                conf.CAIRO_HAS_WIN32_FONT = true;
                break;
            case "CAIRO_HAS_FT_FONT":
                conf.CAIRO_HAS_FT_FONT = true;
                break;
            case "CAIRO_HAS_XCB_SURFACE":
                conf.CAIRO_HAS_XCB_SURFACE = true;
                break;
            case "CAIRO_HAS_DIRECTFB_SURFACE":
                conf.CAIRO_HAS_DIRECTFB_SURFACE = true;
                break;
            case "CAIRO_HAS_XLIB_SURFACE":
                conf.CAIRO_HAS_XLIB_SURFACE = true;
                break;
            case "CAIRO_HAS_PNG_FUNCTIONS":
                conf.CAIRO_HAS_PNG_FUNCTIONS = true;
                break;
            default:
                writefln("Error: Unknown feature '%s'!", entry);
                return;
            }
        }
    }
    else
    {
        try
            conf = detectFeatures();
        catch (Exception e)
        {
            conf.CAIROD_CONFIGURE_FAILED = true;
        }
        writeln();
    }

    string pkgDir = ".";
    if (args.length > 1)
        pkgDir = args[1];
    writeConfiguration(conf, pkgDir);
    writeln("=> Configuration:");
    if (conf.CAIROD_CONFIGURE_FAILED)
    {
        writeln("   Using minimal native configuration");
    }
    else
    {
        string[] surfaces, fonts;
        if (conf.CAIRO_HAS_PS_SURFACE)
            surfaces ~= "PostScript";
        if (conf.CAIRO_HAS_PDF_SURFACE)
            surfaces ~= "PDF";
        if (conf.CAIRO_HAS_SVG_SURFACE)
            surfaces ~= "SVG";
        if (conf.CAIRO_HAS_WIN32_SURFACE)
            surfaces ~= "Win32";
        if (conf.CAIRO_HAS_XCB_SURFACE)
            surfaces ~= "XCB";
        if (conf.CAIRO_HAS_DIRECTFB_SURFACE)
            surfaces ~= "DirectFB";
        if (conf.CAIRO_HAS_XLIB_SURFACE)
            surfaces ~= "xlib";

        if (conf.CAIRO_HAS_WIN32_FONT)
            fonts ~= "Win32";
        if (conf.CAIRO_HAS_FT_FONT)
            fonts ~= "FreeType";

        writefln("   PNG support: %s", conf.CAIRO_HAS_PNG_FUNCTIONS);
        writefln("   Surfaces: %s", surfaces.join(" "));
        writefln("   Font backends: %s", fonts.join(" "));
    }
    writeDoubleLine();
}

CairoConfiguration detectFeatures()
{
    writeln("=> Trying to detect features supported by cairo library");

    string compiler = environment.get("CC", "gcc");
    writeResult("   Searching for C compiler name...", compiler);

    auto cairoOK = compiler.tryCompile("#include <cairo/cairo.h>");
    writeResult("   Whether C compiler can compile cairo programs...", to!string(cairoOK));

    if (!cairoOK)
    {
        writeln("=> Can not autodetect features! Using minimal configuration.");
        writeln("   Use CAIROD_FEATURES environment variable to specify features manually.");
        throw new Exception("error");
    }

    CairoConfiguration conf;
    conf.CAIRO_HAS_PS_SURFACE = compiler.testFeature("CAIRO_HAS_PS_SURFACE");
    conf.CAIRO_HAS_PDF_SURFACE = compiler.testFeature("CAIRO_HAS_PDF_SURFACE");
    conf.CAIRO_HAS_SVG_SURFACE = compiler.testFeature("CAIRO_HAS_SVG_SURFACE");
    conf.CAIRO_HAS_WIN32_SURFACE = compiler.testFeature("CAIRO_HAS_WIN32_SURFACE");
    conf.CAIRO_HAS_WIN32_FONT = compiler.testFeature("CAIRO_HAS_WIN32_FONT");
    conf.CAIRO_HAS_FT_FONT = compiler.testFeature("CAIRO_HAS_FT_FONT");
    conf.CAIRO_HAS_XCB_SURFACE = compiler.testFeature("CAIRO_HAS_XCB_SURFACE");
    conf.CAIRO_HAS_DIRECTFB_SURFACE = compiler.testFeature("CAIRO_HAS_DIRECTFB_SURFACE");
    conf.CAIRO_HAS_XLIB_SURFACE = compiler.testFeature("CAIRO_HAS_XLIB_SURFACE");
    conf.CAIRO_HAS_PNG_FUNCTIONS = compiler.testFeature("CAIRO_HAS_PNG_FUNCTIONS");
    return conf;
}

void writeConfiguration(CairoConfiguration conf, string pkgDir)
{
    string basePath = pkgDir.buildPath("src", "cairo", "c", "config.d");

    auto basePart = File(basePath ~ ".part", "r");
    auto outFile = File(basePath, "w");
    foreach (line; basePart.byLine())
        outFile.writeln(line);

    if (conf.CAIROD_CONFIGURE_FAILED)
        return;

    outFile.writeln("version(D_Ddoc) {}");
    outFile.writeln("else");
    outFile.writeln("{");

    outFile.writefln("    enum bool CAIRO_HAS_PNG_FUNCTIONS = %s;", conf.CAIRO_HAS_PNG_FUNCTIONS);
    outFile.writefln("    enum bool CAIRO_HAS_PS_SURFACE = %s;", conf.CAIRO_HAS_PS_SURFACE);
    outFile.writefln("    enum bool CAIRO_HAS_PDF_SURFACE = %s;", conf.CAIRO_HAS_PDF_SURFACE);
    outFile.writefln("    enum bool CAIRO_HAS_SVG_SURFACE = %s;", conf.CAIRO_HAS_SVG_SURFACE);
    outFile.writefln("    enum bool CAIRO_HAS_WIN32_SURFACE = %s;", conf.CAIRO_HAS_WIN32_SURFACE);
    outFile.writefln("    enum bool CAIRO_HAS_WIN32_FONT = %s;", conf.CAIRO_HAS_WIN32_FONT);
    outFile.writefln("    enum bool CAIRO_HAS_FT_FONT = %s;", conf.CAIRO_HAS_FT_FONT);
    outFile.writefln("    enum bool CAIRO_HAS_XCB_SURFACE = %s;", conf.CAIRO_HAS_XCB_SURFACE);
    outFile.writefln("    enum bool CAIRO_HAS_DIRECTFB_SURFACE = %s;",
        conf.CAIRO_HAS_DIRECTFB_SURFACE);
    outFile.writefln("    enum bool CAIRO_HAS_XLIB_SURFACE = %s;", conf.CAIRO_HAS_XLIB_SURFACE);
    outFile.writeln("    enum bool CAIROD_IS_CONFIGURED = true;");

    outFile.writeln("}");
}

bool tryCompile(string compiler, string program)
{
    auto tempPath = tempDir().buildPath("cairod_test.c");

    scope (exit)
    {
        if (tempPath.exists)
            remove(tempPath);
    }
    std.file.write(tempPath, program);

    try
    {
        auto result = execute([compiler, "-c", tempPath]);
        return result.status == 0;
    }
    catch (Exception e)
    {
        return false;
    }
}

bool compileTestFeature(string compiler, string feature)
{
    import std.ascii;

    string program = "#include <cairo/cairo.h>" ~ newline ~ newline;
    program ~= "#ifndef " ~ feature ~ newline;
    program ~= "  #error \"Feature not available\"" ~ newline;
    program ~= "#endif" ~ newline;

    return tryCompile(compiler, program);
}

bool testFeature(string compiler, string feature)
{
    auto result = compiler.compileTestFeature(feature);
    writeResult("   For " ~ feature ~ "...", to!string(result));
    return result;
}

/*
 * Console output functions
 */
enum lineLength = 80;
enum minResultLength = 10;

/**
 * Format one output line
 */
void writeResult(string msg, string result)
{
    if (msg.length >= lineLength - minResultLength)
    {
        writefln("%s    %s", msg, result);
    }
    else
    {
        auto remaining = lineLength - msg.length - 1; //One space
        writefln("%s %*.*s", msg, remaining, remaining, result);
    }
}

void writeDoubleLine()
{
    for (size_t i = 0; i < lineLength; i++)
        write("=");
    writeln();
}
