/++
$(H2 Auxiliary data types and functions.)

$(GREEN This module is available for betterC compilation mode.)

License:   $(WEB www.boost.org/LICENSE_1_0.txt, Boost License 1.0).

Authors:   Ilya Yaroshenko
+/
module cpuid.common;

version(LDC)
{
    version(unittest) {} else
    {
        pragma(LDC_no_moduleinfo);
    }
}

/// Cache Information
struct  Cache
{
    /// Cache size in KBs
    uint size;
    /// Ways of associativity. Equals `associative.max` if cache is fully associative.
    ushort associative;
    /// Cache line in KBs
    ushort line;
    /// CPU cores per cache
    ubyte cores;
    /// `true` if cache is inclusive of lower cache levels.
    bool inclusive;

    const @property @safe pure nothrow @nogc:

    /// Code: `associative == associative.max`
    bool isFullyAssociative()
    {
        static if (__VERSION__ >= 2068)
            pragma(inline, true);
        return associative == associative.max;
    }
}

/// Translation Lookaside Buffer Information
struct Tlb
{
    /// Page size in KBs
    uint page;
    /// Amount of pages TLB
    uint entries;
    /// Ways of associativity. Equals `associative.max` if TLB is fully associative.
    ushort associative;

    const @property @safe pure nothrow @nogc:

    /** Computes size in KBs.
    Code: `entries * page`
    */
    uint size()
    {
        static if (__VERSION__ >= 2068)
            pragma(inline, true);
        return entries * page;
    }
    /// Code: `associative == associative.max`
    bool isFullyAssociative()
    {
        static if (__VERSION__ >= 2068)
            pragma(inline, true);
        return associative == associative.max;
    }
}
