module cpuid.common;

///
struct  Cache
{
    ///
    uint size; // KB
    ///
    uint associative;
    ///
    uint line;
}

///
struct TLB
{
    ///
    uint page; // KB
    ///
    uint associative;
    ///
    uint entries;

    /// Computes size in KBs
    uint size() @property @safe pure nothrow @nogc
    {
        return entries * page;
    }
}
