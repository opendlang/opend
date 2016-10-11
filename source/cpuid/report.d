/++
Text information generators.

License:   $(WEB www.boost.org/LICENSE_1_0.txt, Boost License 1.0).

Authors:   Ilya Yaroshenko
+/
module cpuid.report;

///
unittest
{
    import cpuid.unified;
    import cpuid.report;
    cpuid_init();
    import std.stdio;
    cpuid.report.unified.writeln;
    version(X86)
        cpuid.report.x86_any.writeln;
    version(X86_64)
        cpuid.report.x86_any.writeln;
}

/// Returns report for `cpuid.unified`.
string unified()()
{
    import std.traits;
    import std.array;
    import std.format;

    import cpuid.unified;

    auto app = appender!string;

    void putAssociative(T)(T v)
    {
        switch(v)
        {
            case 1:
                app.formattedWrite("\t\tAssociativity: direct mapped\n");
                break;
            case T.max:
                app.formattedWrite("\t\tAssociativity: Fully associative\n");
                break;
            default:
                app.formattedWrite("\t\tAssociativity: %s-way associative\n", v);
        }
    }

    void putCache(Cache cache)
    {
        app.formattedWrite("\t\tCache size = %s KB\n", cache.size);
        app.formattedWrite("\t\tLine = %s bytes\n", cache.line);
        app.formattedWrite("\t\tCores per cache = %s\n", cache.cores);
        app.formattedWrite("\t\tInclusive: %s\n", cache.inclusive);
        putAssociative(cache.associative);
    }

    void putTlb(Tlb tlb)
    {
        app.formattedWrite("\t\tPage size = %s KB\n", tlb.page);
        app.formattedWrite("\t\tPages count = %s\n", tlb.entries);
        putAssociative(tlb.associative);
    }

    app.formattedWrite("################ Unified Information ################\n");
    app.formattedWrite("Cores per CPU: %s\n", cores);
    app.formattedWrite("Threads per CPU: %s\n", threads);


    app.formattedWrite("------------------ TLB Information ------------------\n");

    app.formattedWrite("Instruction TLB:\n");
    foreach(i, tlb; iTlb)
    {
        app.formattedWrite("- - - - - ITLB%s: - - - - - - - - - - - - - - - - - -\n", i + 1);
        putTlb(tlb);
    }

    app.formattedWrite("Data TLB:\n");
    foreach(i, tlb; dTlb)
    {
        app.formattedWrite("- - - - - DTLB%s: - - - - - - - - - - - - - - - - - -\n", i + 1);
        putTlb(tlb);
    }

    app.formattedWrite("Unified TLB:\n");
    foreach(i, tlb; uTlb)
    {
        app.formattedWrite("- - - - - UTLB%s: - - - - - - - - - - - - - - - - - -\n", i + 1);
        putTlb(tlb);
    }

    app.formattedWrite("----------------- Cache Information -----------------\n");

    app.formattedWrite("Instruction Cache:\n");
    foreach(i, cache; iCache)
    {
        app.formattedWrite("- - - - - ICache%s: - - - - - - - - - - - - - - - - -\n", i + 1);
        putCache(cache);
    }

    app.formattedWrite("Data Cache:\n");
    foreach(i, cache; dCache)
    {
        app.formattedWrite("- - - - - DCache%s: - - - - - - - - - - - - - - - - -\n", i + 1);
        putCache(cache);
    }

    app.formattedWrite("Unified Cache:\n");
    foreach(i, cache; uCache)
    {
        app.formattedWrite("- - - - - UCache%s: - - - - - - - - - - - - - - - - -\n", i + 1);
        putCache(cache);
    }

    return app.data;
}

private alias AliasSeq(T...) = T;

/// Returns report for `cpuid.x86_any`.
string x86_any()()
{

    import std.traits;
    import std.array;
    import std.format;

    import cpuid.x86_any;

    auto app = appender!string;

    app.formattedWrite("################## x86 Information ##################\n");

    //app.formattedWrite("CPU count =  %s\n", cpus);
    app.formattedWrite("%20s: %s\n", "vendor", vendor);
    char[48] brandName = void;
    auto len = brand(brandName);
    app.formattedWrite("%20s: %s\n", "brand", brandName[0 .. len]);

    foreach(i, name; AliasSeq!(
        "vendorIndex",
        "brandIndex",
        "maxBasicLeaf",
        "maxExtendedLeaf",
        "clflushLineSize",
        "maxLogicalProcessors",
        "initialAPIC",
        "stepping",
        "model",
        "family",
        "type",
        "extendedModel",
        "extendedFamily",
        "sse3",
        "pclmulqdq",
        "dtes64",
        "monitor",
        "ds_cpl",
        "vmx",
        "smx",
        "eist",
        "tm2",
        "ssse3",
        "cnxt_id",
        "sdbg",
        "fma",
        "cmpxchg16b",
        "xtpr",
        "pdcm",
        "pcid",
        "dca",
        "sse41",
        "sse42",
        "x2apic",
        "movbe",
        "popcnt",
        "tsc_deadline",
        "aes",
        "xsave",
        "osxsave",
        "avx",
        "f16c",
        "rdrand",
        "fpu",
        "vme",
        "de",
        "pse",
        "tsc",
        "msr",
        "pae",
        "mce",
        "cx8",
        "apic",
        "sep",
        "mtrr",
        "pge",
        "mca",
        "cmov",
        "pat",
        "pse36",
        "psn",
        "clfsh",
        "ds",
        "acpi",
        "mmx",
        "fxsr",
        "sse",
        "sse2",
        "ss",
        "htt",
        "tm",
        "pbe",
        ))
        static if(mixin(`isIntegral!(typeof(` ~ name ~ `))`))
            mixin(`app.formattedWrite("%20s: 0x%X\n", "` ~ name ~ `",  ` ~ name ~ `);`);
        else
            mixin(`app.formattedWrite("%20s: %s\n", "` ~ name ~ `",  ` ~ name ~ `);`);

    return app.data;
}
