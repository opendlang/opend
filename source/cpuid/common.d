/++
Auxiliary data types and functions.
+/
module cpuid.common;

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

    ///
    bool isFullyAssociative()
    {
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

    /// Computes size in KBs
    uint size()
    {
        pragma(inline, true);
        return entries * page;
    }
    ///
    bool isFullyAssociative()
    {
        pragma(inline, true);
        return associative == associative.max;
    }
}
