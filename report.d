/+ dub.json:
{
    "name": "cpuid-report",
    "dependencies": {"mir-cpuid": {"path": "./"}},
}
+/
/++
Text information generators.

License:   $(WEB www.boost.org/LICENSE_1_0.txt, Boost License 1.0).

Authors:   Ilya Yaroshenko
+/
module cpuid.report;

void main()
{
    import cpuid.unified;
    import cpuid.report;

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
    char[48] brandName = void;
    auto len = brand(brandName);
    app.formattedWrite("%20s: %s\n", "brand", brandName[0 .. len]);

    foreach(i, name; AliasSeq!(
        "vendor",
        "virtualVendor",
        "virtual",
        "vendorIndex",
        "virtualVendorIndex",
        "brandIndex",
        "maxBasicLeaf",
        "maxExtendedLeaf",
        "max7SubLeafs",
        "acpi",
        "adx",
        "aes",
        "apic",
        "avx",
        "avx2",
        "avx512bw",
        "avx512cd",
        "avx512dq",
        "avx512er",
        "avx512f",
        "avx512ifma",
        "avx512pf",
        "avx512vbmi",
        "avx512vl",
        "bmi1",
        "bmi2",
        "clflushLineSize",
        "clflushopt",
        "clfsh",
        "clwb",
        "cmov",
        "cmpxchg16b",
        "cnxt_id",
        "cx8",
        "dca",
        "de",
        "deprecates",
        "ds",
        "ds_cpl",
        "dtes64",
        "eist",
        "extendedFamily",
        "extendedModel",
        "f16c",
        "family",
        "fdp_excptn_only",
        "fma",
        "fpu",
        "fsgsbase",
        "fxsr",
        "hle",
        "htt",
        "ia32_tsc_adjust",
        "initialAPIC",
        "intel_pt",
        "invpcid",
        "maxLogicalProcessors",
        "mca",
        "mce",
        "mmx",
        "model",
        "monitor",
        "movbe",
        "mpx",
        "msr",
        "mtrr",
        "ospke",
        "osxsave",
        "pae",
        "pat",
        "pbe",
        "pcid",
        "pclmulqdq",
        "pcommit",
        "pdcm",
        "pge",
        "pku",
        "popcnt",
        "prefetchwt1",
        "pse",
        "pse36",
        "psn",
        "rdrand",
        "rdseed",
        "rdt_a",
        "rdt_m",
        "rtm",
        "sdbg",
        "sep",
        "sgx",
        "sha",
        "smap",
        "smep",
        "smx",
        "self_snoop",
        "sse",
        "sse2",
        "sse3",
        "sse41",
        "sse42",
        "ssse3",
        "stepping",
        "supports",
        "therm_monitor",
        "therm_monitor2",
        "tsc",
        "tsc_deadline",
        "type",
        "vme",
        "vmx",
        "x2apic",
        "xsave",
        "xtpr",
        ))
        static if(mixin(`isIntegral!(typeof(` ~ name ~ `))`))
            mixin(`app.formattedWrite("%20s: 0x%X\n", "` ~ name ~ `",  ` ~ name ~ `);`);
        else
            mixin(`app.formattedWrite("%20s: %s\n", "` ~ name ~ `",  ` ~ name ~ `);`);

    return app.data;
}
