/++
$(H2 AMD CPUID Information)

$(GREEN This module is available for betterC compilation mode.)

References:
    AMD CPUID Specification. Publication # 25481 / Revision: 2.34 / Issue Date: September 2010

License:   $(WEB www.boost.org/LICENSE_1_0.txt, Boost License 1.0).

Authors:   Ilya Yaroshenko
+/
module cpuid.amd;

version(LDC)
{
    version(unittest) {} else
    {
        pragma(LDC_no_moduleinfo);
    }
}

version(X86)
    version = X86_Any;
else
version(X86_64)
    version = X86_Any;

version(X86_Any):

public import cpuid.x86_any;

/++
L1 Cache and TLB Identifiers.

The associativity fields are encoded as follows:
 
Specification: AMD
+/
union LeafExt5Information
{
    version(BigEndian) static assert(0, "Leaf2Information is not implemented for BigEndian architecture.");

    ///
    CpuInfo info;

    ///
    struct
    {
        /// Instruction TLB number of entries for 2 MB and 4 MB pages.
        ubyte L1ITlb2and4MSize;
        /// Instruction TLB associativity for 2 MB and 4 MB pages.
        ubyte L1ITlb2and4MAssoc;
        /// Data TLB number of entries for 2 MB and 4 MB pages.
        ubyte L1DTlb2and4MSize;
        /// Data TLB associativity for 2 MB and 4 MB pages.
        ubyte L1DTlb2and4MAssoc;

        /// Instruction TLB number of entries for 4 KB pages.
        ubyte L1ITlb4KSize;
        /// Instruction TLB associativity for 4 KB pages.
        /// See_also: CPUID Fn8000_0005_EDX[L1IcAssoc].
        ubyte L1ITlb4KAssoc;
        /// Data TLB number of entries for 4 KB pages.
        ubyte L1DTlb4KSize;
        /// Data TLB associativity for 4 KB pages.
        /// See_also: CPUID Fn8000_0005_EDX[L1IcAssoc].
        ubyte L1DTlb4KAssoc;

        /// L1 data cache line size in bytes.
        ubyte L1DcLineSize;
        /// L1 data cache lines per tag.
        ubyte L1DcLinesPerTag;
        /// L1 data cache associativity.
        /// See_also: CPUID Fn8000_0005_EDX[L1IcAssoc].
        ubyte L1DcAssoc;
        /// L1 data cache size in KB.
        ubyte L1DcSize;

        /// L1 instruction cache line size in bytes.
        ubyte L1IcLineSize;
        /// L1 instruction cache lines per tag.
        ubyte L1IcLinesPerTag;
        /// L1 instruction cache associativity.
        ubyte L1IcAssoc;
        /// L1 instruction cache size KB.
        ubyte L1IcSize;
    }
}

/++
L2/L3 Cache and TLB Identifiers.

This function contains the processor’s second level cache and TLB characteristics for each core.
The EDX register contains the processor’s third level cache characteristics that are shared by all cores of the processor.

Note:
    Use $(MREF decodeL2orL3Assoc) to get final result for any `*Assoc` field.

Specification: AMD
+/
union LeafExt6Information
{
    /// CPUID payload
    CpuInfo info;

    ///
    struct
    {
        import std.bitmanip: bitfields;

        version(D_Ddoc)
        {
            const @trusted @property pure nothrow @nogc:
            /// L2 instruction TLB number of entries for 4 KB pages.
            uint L2ITlb4KSize();
            /// L2 instruction TLB associativity for 4 KB pages.
            uint L2ITlb4KAssoc();
            /// L2 data TLB number of entries for 4 KB pages.
            uint L2DTlb4KSize();
            /// L2 data TLB associativity for 4 KB pages.
            uint L2DTlb4KAssoc();
            /// L2 instruction TLB number of entries for 2 MB and 4 MB pages.
            /// The value returned is for the number of entries available for the 2 MB page size; 4 MB pages require two 2 MB entries, so the number of entries available for the 4 MB page size is one-half the returned value.
            uint L2ITlb2and4MSize();
            /// L2 instruction TLB associativity for 2 MB and 4 MB pages.
            uint L2ITlb2and4MAssoc();
            /// L2 data TLB number of entries for 2 MB and 4 MB pages.
            /// The value returned is for the number of entries available for the 2 MB page size; 4 MB pages require two 2 MB entries, so the number of entries available for the 4 MB page size is one-half the returned value.
            uint L2DTlb2and4MSize();
            /// L2 data TLB associativity for 2 MB and 4 MB pages.
            uint L2DTlb2and4MAssoc();
            /// L2 cache line size in bytes.
            uint L2LineSize();
            /// L2 cache lines per tag.
            uint L2LinesPerTag();
            /// L2 cache associativity.
            uint L2Assoc();
            /// L2 cache size in KB.
            uint L2Size();
            /// L3 cache line size in bytes. 
            uint L3LineSize();
            /// L3 cache lines per tag.
            uint L3LinesPerTag();
            /// L3 cache associativity. L3 cache associativity.
            uint L3Assoc();
            /// L3 cache size. Specifies the L3 cache size is within the following range: `(L3Size * 512KB) <= L3 cache size < ((L3Size+1) * 512KB)`.
            uint L3Size();
        }
        else
        {
            @trusted @property pure nothrow @nogc:

            /// EAX
            mixin(bitfields!(
                uint, "L2ITlb4KSize", 11 - 0  + 1,
                uint, "L2ITlb4KAssoc", 15 - 12 + 1,
                uint, "L2DTlb4KSize", 27 - 16 + 1,
                uint, "L2DTlb4KAssoc", 31 - 28 + 1,
            ));

            /// EBX
            mixin(bitfields!(
                uint, "L2ITlb2and4MSize", 11 - 0  + 1,
                uint, "L2ITlb2and4MAssoc", 15 - 12 + 1,
                uint, "L2DTlb2and4MSize", 27 - 16 + 1,
                uint, "L2DTlb2and4MAssoc", 31 - 28 + 1,
            ));

            /// ECD
            mixin(bitfields!(
                uint, "L2LineSize", 7 - 0 + 1,
                uint, "L2LinesPerTag", 11 - 8 + 1,
                uint, "L2Assoc", 15 - 12 + 1,
                uint, "L2Size", 31 - 16 + 1,
            ));

            /// EDX
            mixin(bitfields!(
                uint, "L3LineSize", 7 - 0 + 1,
                uint, "L3LinesPerTag", 11 - 8 + 1,
                uint, "L3Assoc", 15 - 12 + 1,
                uint, "", 17 - 16 + 1,
                uint, "L3Size", 31 - 18 + 1,
            ));
        }
    }
}

/++
Decodes Associativity Fields for L2/L3 Cache or TLB.
`T.max` is used to represent full-associative Cache/TLB.
+/
@safe pure nothrow @nogc
T decodeL2or3Assoc(T = uint)(uint assoc)
{
    switch(assoc)
    {
        case 0x1: return 1;
        case 0x2: return 2;
        case 0x4: return 4;
        case 0x6: return 8;
        case 0x8: return 16;
        case 0xA: return 32;
        case 0xB: return 48;
        case 0xC: return 64;
        case 0xD: return 96;
        case 0xE: return 128;
        case 0xF: return T.max;
        default: return 0;
    }
}
