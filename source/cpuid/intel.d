/++
$(H1 Intel 64 and IA-32 CPUID Information)

References:
    Intel® 64 and IA-32 Architectures Software Developer’s Manual

Authors:
    Ilya Yaroshenko
+/
module cpuid.intel;

version(X86)
    version = X86_Any;
else
version(X86_64)
    version = X86_Any;

version(X86_Any):

public import cpuid.x86_any;

/++
TLB and Cache information.

For convinient Cache information see also $(MREF Leaf4Information).

Specification: Intel
+/
struct Leaf2Information
{
    ///
    static struct  Cache
    {
        ///
        uint size; // KB
        ///
        uint associative;
        ///
        uint line;
    }

    ///
    static struct TLB
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


    /// Level-1 instuciton cache
    Cache il1;
    /// Level-2 data cache
    Cache l1;
    /// Level-2 data cache
    Cache l2;
    /// Level-2 data cache
    Cache l3;
    /// Intruction TLB
    TLB itlb;
    /// Intruction TLB, huge pages
    TLB hitlb;
    /// Data TLB
    TLB dtlb;
    /// Data TLB, huge pages
    TLB hdtlb;
    /// Data TLB, giant pages
    TLB gdtlb;
    /// Data TLB1
    TLB dtlb1;
    /// Data TLB1, huge pages
    TLB hdtlb1;
    /// Second-level unified TLB
    TLB stlb;
    /// Second-level unified TLB, huge pages
    TLB hstlb;
    /// Second-level unified TLB, giant pages
    TLB gstlb;
    /// prefetch line size
    int prefetch;
    /// Cache trace
    int trace;
    /// `true` if CPUID leaf 2 does not report cache descriptor information. use CPUID leaf 4 to query cache parameters.
    bool noCacheInfo;
    // No 2nd-level cache or, if processor contains a valid 2nd-level cache, no 3rd-level cache
    bool noL2Or3;
}

/+
Dencoding of CPUID Leaf 2 Descriptors.

Specification: Intel
+/
pure nothrow @nogc
void _leaf2(
    ref uint[4] info,
    ref Leaf2Information leaf2,
    )
{
    info[0] >>>= 8;

    with(leaf2)
    foreach(b; (cast(ubyte[16])info)[1..$])
    switch(b)
    {
        default:
            break;
        case 0x00:
            // General     Null descriptor, this byte contains no information
            break;
        case 0x01:
            itlb.page = 4;
            itlb.associative = 4;
            itlb.entries = 32;
            break;
        case 0x02:
            hitlb.page = 4 * 1024;
            hitlb.associative = hitlb.associative.max;
            hitlb.entries = 2;
            break;
        case 0x03:
            dtlb.page = 4;
            dtlb.associative = 4;
            dtlb.entries = 64;
            break;
        case 0x04:
            hdtlb.page = 4 * 1024;
            hdtlb.associative = 4;
            hdtlb.entries = 8;
            break;
        case 0x05:
            hdtlb1.page = 4 * 1024;
            hdtlb1.associative = 4;
            hdtlb1.entries = 32;
            break;
        case 0x06:
            il1.size = 8;
            il1.associative = 4;
            il1.line = 32;
            break;
        case 0x08:
            il1.size = 16;
            il1.associative = 4;
            il1.line = 32;
            break;
        case 0x09:
            il1.size = 32;
            il1.associative = 4;
            il1.line = 64;
            break;
        case 0x0A:
            l1.size = 8;
            l1.associative = 2;
            l1.line = 32;
            break;
        case 0x0B:
            hitlb.page = 4 * 1024;
            hitlb.associative = 4;
            hitlb.entries = 4;
            break;
        case 0x0C:
            l1.size = 16;
            l1.associative = 4;
            l1.line = 32;
            break;
        case 0x0D:
            l1.size = 16;
            l1.associative = 4;
            l1.line = 64;
            break;
        case 0x0E:
            l1.size = 24;
            l1.associative = 6;
            l1.line = 64;
            break;
        case 0x1D:
            l2.size = 128;
            l2.associative = 2;
            l2.line = 64;
            break;
        case 0x21:
            l2.size = 256;
            l2.associative = 8;
            l2.line = 64;
            break;
        case 0x22:
            l3.size = 512;
            l3.associative = 4;
            l3.line = 64;
            break;
        case 0x23:
            l3.size = 1 * 1024;
            l3.associative = 8;
            l3.line = 64;
            break;
        case 0x24:
            l2.size = 1 * 1024;
            l2.associative = 16;
            l2.line = 64;
            break;
        case 0x25:
            l3.size = 2 * 1024;
            l3.associative = 8;
            l3.line = 64;
            break;
        case 0x29:
            l3.size = 4 * 1024;
            l3.associative = 8;
            l3.line = 64;
            break;
        case 0x2C:
            l1.size = 32;
            l1.associative = 8;
            l1.line = 64;
            break;
        case 0x30:
            il1.size = 32;
            il1.associative = 8;
            il1.line = 64;
            break;
        case 0x40:
            noL2Or3 = true;
            break;
        case 0x41:
            l2.size = 128;
            l2.associative = 4;
            l2.line = 32;
            break;
        case 0x42:
            l2.size = 256;
            l2.associative = 4;
            l2.line = 32;
            break;
        case 0x43:
            l2.size = 512;
            l2.associative = 4;
            l2.line = 32;
            break;
        case 0x44:
            l2.size = 1 * 1024;
            l2.associative = 4;
            l2.line = 32;
            break;
        case 0x45:
            l2.size = 2 * 1024;
            l2.associative = 4;
            l2.line = 32;
            break;
        case 0x46:
            l3.size = 4 * 1024;
            l3.associative = 4;
            l3.line = 64;
            break;
        case 0x47:
            l3.size = 8 * 1024;
            l3.associative = 8;
            l3.line = 64;
            break;
        case 0x48:
            l2.size = 3 * 1024;
            l2.associative = 12;
            l2.line = 64;
            break;
        case 0x49:
            l3.size = 4 * 1024;
            l3.associative = 16;
            l3.line = 64;
            l2.size = 4 * 1024;
            l2.associative = 16;
            l2.line = 64;
            break;
        case 0x4A:
            l3.size = 6 * 1024;
            l3.associative = 12;
            l3.line = 64;
            break;
        case 0x4B:
            l3.size = 8 * 1024;
            l3.associative = 16;
            l3.line = 64;
            break;
        case 0x4C:
            l3.size = 12 * 1024;
            l3.associative = 12;
            l3.line = 64;
            break;
        case 0x4D:
            l3.size = 16 * 1024;
            l3.associative = 16;
            l3.line = 64;
            break;
        case 0x4E:
            l2.size = 6 * 1024;
            l2.associative = 24;
            l2.line = 64;
            break;
        case 0x4F:
            itlb.page = 4;
            itlb.associative = 1;
            itlb.entries = 32;
            break;
        case 0x50:
            itlb.page = 4;
            itlb.associative = 1;
            itlb.entries = 64;
            hitlb.page = 2 * 1024;
            hitlb.associative = 1;
            hitlb.entries = 64;
            break;
        case 0x51:
            itlb.page = 4;
            itlb.associative = 1;
            itlb.entries = 128;
            hitlb.page = 2 * 1024;
            hitlb.associative = 1;
            hitlb.entries = 128;
            break;
        case 0x52:
            itlb.page = 4;
            itlb.associative = 1;
            itlb.entries = 256;
            hitlb.page = 2 * 1024;
            hitlb.associative = 1;
            hitlb.entries = 256;
            break;
        case 0x55:
            itlb.page = 2 * 1024;
            itlb.associative = itlb.associative.max;
            itlb.entries = 7;
            break;
        case 0x56:
            hdtlb.page = 4 * 1024;
            hdtlb.associative = 4;
            hdtlb.entries = 16;
            break;
        case 0x57:
            dtlb.page = 4;
            dtlb.associative = 4;
            dtlb.entries = 16;
            break;
        case 0x59:
            dtlb.page = 4;
            dtlb.associative = dtlb.associative.max;
            dtlb.entries = 16;
            break;
        case 0x5A:
            hdtlb.page = 2 * 1024;
            hdtlb.associative = 4;
            hdtlb.entries = 32;
            break;
        case 0x5B:
            dtlb.page = 4;
            dtlb.associative = 1;
            dtlb.entries = 64;
            hdtlb.page = 4 * 1024;
            hdtlb.associative = 1;
            hdtlb.entries = 64;
            break;
        case 0x5C:
            dtlb.page = 4;
            dtlb.associative = 1;
            dtlb.entries = 128;
            hdtlb.page = 4 * 1024;
            hdtlb.associative = 1;
            hdtlb.entries = 128;
            break;
        case 0x5D:
            dtlb.page = 4;
            dtlb.associative = 1;
            dtlb.entries = 256;
            hdtlb.page = 4 * 1024;
            hdtlb.associative = 1;
            hdtlb.entries = 256;
            break;
        case 0x60:
            l1.size = 16;
            l1.associative = 8;
            l1.line = 64;
            break;
        case 0x61:
            itlb.page = 4;
            itlb.associative = itlb.associative.max;
            itlb.entries = 48;
            break;
        case 0x63:
            hdtlb.page = 2 * 1024;
            hdtlb.associative = 4;
            hdtlb.entries = 32;
            gdtlb.page = 1024 * 1024;
            gdtlb.associative = 4;
            gdtlb.entries = 4;
            break;
        case 0x64:
            dtlb.page = 4;
            dtlb.associative = 4;
            dtlb.entries = 512;
            break;
        case 0x66:
            l1.size = 8;
            l1.associative = 4;
            l1.line = 64;
            break;
        case 0x67:
            l1.size = 16;
            l1.associative = 4;
            l1.line = 64;
            break;
        case 0x68:
            l1.size = 32;
            l1.associative = 4;
            l1.line = 64;
            break;
        case 0x6A:
            dtlb.page = 4;
            dtlb.associative = 8;
            dtlb.entries = 64;
            break;
        case 0x6B:
            dtlb.page = 4;
            dtlb.associative = 8;
            dtlb.entries = 256;
            break;
        case 0x6C:
            hdtlb.page = 2 * 1024;
            hdtlb.associative = 8;
            hdtlb.entries = 128;
            break;
        case 0x6D:
            gdtlb.page = 1024 * 1024;
            gdtlb.associative = gdtlb.associative.max;
            gdtlb.entries = 16;
            break;
        case 0x70:
            trace = 12;
            break;
        case 0x71:
            trace = 16;
            break;
        case 0x72:
            trace = 32;
            break;
        case 0x76:
            itlb.page = 2 * 1024;
            itlb.associative = itlb.associative.max;
            itlb.entries = 8;
            break;
        case 0x78:
            l2.size = 1 * 1024;
            l2.associative = 4;
            l2.line = 6;
            break;
        case 0x79:
            l2.size = 128;
            l2.associative = 8;
            l2.line = 64;
            break;
        case 0x7A:
            l2.size = 256;
            l2.associative = 8;
            l2.line = 64;
            break;
        case 0x7B:
            l2.size = 512;
            l2.associative = 8;
            l2.line = 64;
            break;
        case 0x7C:
            l2.size = 1 * 1024;
            l2.associative = 8;
            l2.line = 64;
            break;
        case 0x7D:
            l2.size = 2 * 1024;
            l2.associative = 8;
            l2.line = 6;
            break;
        case 0x7F:
            l2.size = 512;
            l2.associative = 2;
            l2.line = 64;
            break;
        case 0x80:
            l2.size = 512;
            l2.associative = 8;
            l2.line = 64;
            break;
        case 0x82:
            l2.size = 256;
            l2.associative = 8;
            l2.line = 32;
            break;
        case 0x83:
            l2.size = 512;
            l2.associative = 8;
            l2.line = 32;
            break;
        case 0x84:
            l2.size = 1 * 1024;
            l2.associative = 8;
            l2.line = 32;
            break;
        case 0x85:
            l2.size = 2 * 1024;
            l2.associative = 8;
            l2.line = 32;
            break;
        case 0x86:
            l2.size = 512;
            l2.associative = 4;
            l2.line = 64;
            break;
        case 0x87:
            l2.size = 1 * 1024;
            l2.associative = 8;
            l2.line = 64;
            break;
        case 0xA0:
            dtlb.page = 4;
            dtlb.associative = dtlb.associative.max;
            dtlb.entries = 32;
            break;
        case 0xB0:
            itlb.page = 4;
            itlb.associative = 4;
            itlb.entries = 128;
            break;
        case 0xB1:
            itlb.page = 2 * 1024;
            itlb.associative = 4;
            itlb.entries = 8;
            break;
        case 0xB2:
            itlb.page = 4;
            itlb.associative = 4;
            itlb.entries = 64;
            break;
        case 0xB3:
            dtlb.page = 4;
            dtlb.associative = 4;
            dtlb.entries = 128;
            break;
        case 0xB4:
            dtlb1.page = 4;
            dtlb1.associative = 4;
            dtlb1.entries = 256;
            break;
        case 0xB5:
            itlb.page = 4;
            itlb.associative = 8;
            itlb.entries = 64;
            break;
        case 0xB6:
            itlb.page = 4;
            itlb.associative = 8;
            itlb.entries = 128;
            break;
        case 0xBA:
            dtlb1.page = 4;
            dtlb1.associative = 4;
            dtlb1.entries = 64;
            break;
        case 0xC0:
            dtlb.page = 4;
            dtlb.associative = 4;
            dtlb.entries = 8;
            hdtlb.page = 4 * 1024;
            hdtlb.associative = 4;
            hdtlb.entries = 8;
            break;
        case 0xC1:
            stlb.page = 4;
            stlb.associative = 8;
            stlb.entries = 1024;
            hstlb.page = 2 * 1024;
            hstlb.associative = 8;
            hstlb.entries = 1024;
            break;
        case 0xC2:
            dtlb.page = 4;
            dtlb.associative = 4;
            dtlb.entries = 16;
            hdtlb.page = 2 * 1024;
            hdtlb.associative = 4;
            hdtlb.entries = 16;
            break;
        case 0xC3:
            stlb.page = 4;
            stlb.associative = 6;
            stlb.entries = 1536;
            hstlb.page = 2 * 1024;
            hstlb.associative = 6;
            hstlb.entries = 1536;
            gstlb.page = 1024 * 1024;
            gstlb.associative = 4;
            gstlb.entries = 16;
            break;
        case 0xC4:
            hdtlb.page = 2 * 1024;
            hdtlb.associative = 4;
            hdtlb.entries = 32;
            break;
        case 0xCA:
            stlb.page = 4;
            stlb.associative = 4;
            stlb.entries = 512;
            break;
        case 0xD0:
            l3.size = 512;
            l3.associative = 4;
            l3.line = 64;
            break;
        case 0xD1:
            l3.size = 1 * 1024;
            l3.associative = 4;
            l3.line = 64;
            break;
        case 0xD2:
            l3.size = 2 * 1024;
            l3.associative = 4;
            l3.line = 64;
            break;
        case 0xD6:
            l3.size = 1 * 1024;
            l3.associative = 8;
            l3.line = 64;
            break;
        case 0xD7:
            l3.size = 2 * 1024;
            l3.associative = 8;
            l3.line = 64;
            break;
        case 0xD8:
            l3.size = 4 * 1024;
            l3.associative = 8;
            l3.line = 64;
            break;
        case 0xDC:
            l3.size = 1536;
            l3.associative = 12;
            l3.line = 64;
            break;
        case 0xDD:
            l3.size = 3 * 1024;
            l3.associative = 12;
            l3.line = 64;
            break;
        case 0xDE:
            l3.size = 6 * 1024;
            l3.associative = 12;
            l3.line = 64;
            break;
        case 0xE2:
            l3.size = 2 * 1024;
            l3.associative = 16;
            l3.line = 64;
            break;
        case 0xE3:
            l3.size = 4 * 1024;
            l3.associative = 16;
            l3.line = 64;
            break;
        case 0xE4:
            l3.size = 8 * 1024;
            l3.associative = 16;
            l3.line = 64;
            break;
        case 0xEA:
            l3.size = 12 * 1024;
            l3.associative = 24;
            l3.line = 64;
            break;
        case 0xEB:
            l3.size = 18 * 1024;
            l3.associative = 24;
            l3.line = 64;
            break;
        case 0xEC:
            l3.size = 24 * 1024;
            l3.associative = 24;
            l3.line = 64;
            break;
        case 0xF0:
            // Prefetch    64-B prefetching
            prefetch = 64;
            break;
        case 0xF1:
            // Prefetch    128-B prefetching
            prefetch = 128;
            break;
        case 0xFF:
            // General     CPUID leaf 2 does not report cache descriptor information, use CPUID leaf 4 to query cache parameters
            noCacheInfo = true;
            break;
    }
}

///
unittest
{
    Leaf2Information leaf2;
    uint[4] info;
    _cpuid(info, 2);
    _leaf2(info, leaf2);
    //import std.stdio;
    //writeln(leaf2);
}

/++
Deterministic Cache Parameters for Each Level.

** - Add one to the return value to get the result.

Specification: Intel
+/
union Leaf4Information
{
    import std.bitmanip: bitfields;

    ///
    uint[4] info;

    ///
    struct
    {

        ///
        enum Type
        {
            ///
            noMoreCaches,
            ///
            data,
            ///
            instruciton,
            ///
            unified,
        }

        version(D_Ddoc)
        {
            @property pure nothrow @nogc:
            /// Cache Type Field.
            Type type();
            /// Cache Level (starts at 1).
            uint level();
            /// Self Initializing cache level (does not need SW initialization).
            bool selfInitializing();
            /// Fully Associative cache.
            bool fullyAssociative();
            /// Maximum number of addressable IDs for logical processors sharing this cache. **
            uint logicalIDs();
            /// Maximum number of addressable IDs for processor cores in the physical package **
            uint physicalIDs();
            /// System Coherency Line Size **.
            uint l();
            /// Physical Line partitions **.
            uint p();
            /// Ways of associativity **.
            uint w();
            /// Number of Sets **.
            uint s;
            ///  Write-Back Invalidate/Invalidate.
            /// `false` if WBINVD/INVD from threads sharing this cache acts upon lower level caches for threads sharing this cache.
            /// `true` if WBINVD/INVD is not guaranteed to act upon lower level caches of non-originating threads sharing this cache.
            bool invalidate();
            /// `true` - Cache is not inclusive of lower cache levels. `false` - Cache is inclusive of lower cache levels.
            bool inclusiveness();
            /// `false` - Direct mapped cache. `true` A complex function is used to index the cache, potentially using all address bits.
            bool complex();
        }
        else
        {
            /// EAX
            mixin(bitfields!(
                Type, "type", 5,
                uint, "level", 3,
                bool, "selfInitializing", 1,
                bool, "fullyAssociative", 1,
                uint, "", 4,
                uint, "logicalIDs", 12,
                uint, "physicalIDs", 6,
                ));

            /// EBX
            mixin(bitfields!(
                uint, "l", 12,
                uint, "p", 10,
                uint, "w", 10,
                ));

            /// Number of Sets**.
            uint s;

            /// EDX
            mixin(bitfields!(
                bool, "invalidate", 1,
                bool, "inclusiveness", 1,
                bool, "complex", 1,
                uint, "",  29,
                ));
        }

        /// Compute cache size in KBs.
        pure nothrow @nogc
        uint size() @property
        {
            return cast(uint) (
                size_t(l + 1) * 
                size_t(p + 1) * 
                size_t(w + 1) * 
                size_t(s + 1) >> 10);
        }
    }
}

///
unittest
{
    if(maxBasicLeaf >= 4)
    {
        Leaf4Information leaf4;
        //uint[4] info;
        uint ecx;
        for(;;)
        {
            //_cpuid(info, 4, ecx++);
            _cpuid(leaf4.info, 4, ecx++);
            if(!leaf4.type)
                break;
            debug(cpuid) import std.stdio;
            debug(cpuid) writefln("Cache #%s has type '%s' and %s KB size", ecx, leaf4.type, leaf4.size);
        }
    }
}
