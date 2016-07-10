/++
Common data types and functions for all architectures.
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
    /// Logical processors per thread
    ubyte threads = 1;
    /// Physical processors per thread
    ubyte cores = 1;
    /// `true` if cache is inclusive of lower cache levels.
    bool inclusive = true;
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

    /// Computes size in KBs
    uint size() const @property @safe pure nothrow @nogc
    {
        return entries * page;
    }
}
