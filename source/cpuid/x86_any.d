/++
$(H1 Common information for all x86 and x86_64 vendors.)

Note:
    `T.max` value value is used to represent fully-associative Cache/TLB.

References:
    $(LINK2 https://en.wikipedia.org/wiki/CPUID, wikipedia:CPUID)

Authors: Ilya Yaroshenko
+/
module cpuid.x86_any;

version(X86)
    version = X86_Any;
else
version(X86_64)
    version = X86_Any;

version(X86_Any):

version(D_InlineAsm_X86)
    version = InlineAsm_X86_Any;
else
version(D_InlineAsm_X86_64)
    version = InlineAsm_X86_Any;

public import cpuid.common;


/// Leaf0
private __gshared immutable uint _maxBasicLeaf;
private __gshared immutable char[12] _vendor;

/// Leaf1
private __gshared immutable Leaf1Information leaf1Information;

/// ExtLeaf0
private __gshared immutable uint _maxExtendedLeaf;

/// ExtLeaf2 ExtLeaf3 ExtLeaf4
private __gshared immutable uint _brand_length;
private __gshared immutable char[48] _brand;

/// Other
private __gshared immutable VendorIndex _vendorId;


//pure nothrow @nogc
shared static this()
{
    import std.stdio;


    CpuInfo info = _cpuid(0);
    _maxBasicLeaf = _cpuid(0).a;

    (cast(uint[3])_vendor)[0] = info.b;
    (cast(uint[3])_vendor)[1] = info.d;
    (cast(uint[3])_vendor)[2] = info.c;

    leaf1Information.info = _cpuid(1);

    _maxExtendedLeaf = _cpuid(0x8000_0000).a;

    foreach(i; 0..3)
    {
        info = _cpuid(i + 2 ^ 0x8000_0000);
        (cast(uint[12])_brand)[i * 4 + 0] = info.a;
        (cast(uint[12])_brand)[i * 4 + 1] = info.b;
        (cast(uint[12])_brand)[i * 4 + 2] = info.c;
        (cast(uint[12])_brand)[i * 4 + 3] = info.d;
    }

    foreach_reverse(i, char b; _brand[])
    {
        if(b != '\0')
        {
            _brand_length = cast(uint) i + 1;
            break;
        }
    }

    foreach(i, ref name; vendors)
    {
        if(cast(uint[3]) _vendor  == cast(uint[3]) name)
        {
            _vendorId = cast(VendorIndex) i;
            break;
        }
    }
}

/// Basic information about CPU.
private struct Leaf1Information
{
    import std.bitmanip: bitfields;

    union
    {
        CpuInfo info;
        struct
        {
            /// EAX
            mixin(bitfields!(
                uint, "stepping", 3 - 0 + 1, /// Stepping ID
                uint, "model", 7 - 4 + 1, /// Model
                uint, "family", 11 - 8 + 1, /// Family ID
                uint, "type", 13 - 12 + 1, /// Processor Type, Specification: Intel
                uint, "", 15 - 14 + 1,
                uint, "extendedModel", 19 - 16 + 1, /// Extended Model ID
                uint, "extendedFamily", 27 - 20 + 1, /// Extended Family ID
                uint, "", 31 - 28 + 1,
            ));

            /// EBX
            ubyte brandIndex;
            ubyte clflushLineSize;
            ubyte maxLogicalProcessors;
            ubyte initialAPIC;

            /// ECX
            mixin(bitfields!(
                bool, "sse3", 1, /// SSE3 Extensions
                bool, "pclmulqdq", 1, /// Carryless Multiplication
                bool, "dtes64", 1, /// 64-bit DS Area
                bool, "monitor", 1, /// MONITOR/MWAIT
                bool, "ds_cpl", 1, /// CPL Qualified Debug Store
                bool, "vmx", 1, /// Virtual Machine Extensions
                bool, "smx", 1, /// Safer Mode Extensions
                bool, "eist", 1, /// Enhanced Intel SpeedStep® Technology
                bool, "tm2", 1, /// Thermal Monitor 2
                bool, "ssse3", 1, /// SSSE3 Extensions
                bool, "cnxt_id", 1, /// L1 Context ID
                bool, "sdbg", 1,
                bool, "fma", 1, /// Fused Multiply Add
                bool, "cmpxchg16b", 1,
                bool, "xtpr", 1, /// TPR Update Control
                bool, "pdcm", 1, /// Perf/Debug Capability MSR xTPR Update Control
                bool, "", 1,
                bool, "pcid", 1, /// Process-context Identifiers
                bool, "dca", 1, /// Direct Cache Access
                bool, "sse41", 1, /// SSE4.1
                bool, "sse42", 1, /// SSE4.2
                bool, "x2apic", 1,
                bool, "movbe", 1,
                bool, "popcnt", 1,
                bool, "tsc_deadline", 1,
                bool, "aes", 1,
                bool, "xsave", 1,
                bool, "osxsave", 1,
                bool, "avx", 1,
                bool, "f16c", 1,
                bool, "rdrand", 1,
                bool, "", 1,
            ));

            /// EDX
            mixin(bitfields!(
                bool, "fpu", 1, /// x87 FPU on Chip
                bool, "vme", 1, /// Virtual-8086 Mode Enhancement
                bool, "de", 1, /// Debugging Extensions
                bool, "pse", 1, /// Page Size Extensions
                bool, "tsc", 1, /// Time Stamp Counter
                bool, "msr", 1, /// RDMSR and WRMSR Support
                bool, "pae", 1, /// Physical Address Extensions
                bool, "mce", 1, /// Machine Check Exception
                bool, "cx8", 1, /// CMPXCHG8B Inst.
                bool, "apic", 1, /// APIC on Chip
                bool, "", 1,
                bool, "sep", 1, /// SYSENTER and SYSEXIT
                bool, "mtrr", 1, /// Memory Type Range Registers
                bool, "pge", 1, /// PTE Global Bit
                bool, "mca", 1, /// Machine Check Architecture
                bool, "cmov", 1, /// Conditional Move/Compare Instruction
                bool, "pat", 1, /// Page Attribute Table
                bool, "pse36", 1, ///  Page Size Extension
                bool, "psn", 1, /// Processor Serial Number
                bool, "clfsh", 1, /// CLFLUSH instruction
                bool, "", 1,
                bool, "ds", 1, /// Debug Store
                bool, "acpi", 1, /// Thermal Monitor and Clock Ctrl
                bool, "mmx", 1, /// MMX Technology
                bool, "fxsr", 1, /// FXSAVE/FXRSTOR
                bool, "sse", 1, /// SSE Extensions
                bool, "sse2", 1, /// SSE2 Extensions
                bool, "ss", 1, /// Self Snoop
                bool, "htt", 1, /// Multi-threading
                bool, "tm", 1, /// Therm. Monitor
                bool, "", 1,
                bool, "pbe", 1, /// Pend. Brk. EN.
            ));
        }
    }
}

/// x86 CPU information
struct CpuInfo
{
    /// EAX
    uint a;
    /// EBX
    uint b;
    /// ECX
    uint c;
    /// EDX
    uint d;
}

/++
Params:
    info = information received from CPUID instruction
    eax = function id
+/
//CpuInfo _cpuid(uint eax)
//{
//    CpuInfo info = void;
//    version(LDC)
//    {
//        import std.meta: Repeat;
//        import ldc.llvmasm;
//        auto asmt = __asmtuple!(Repeat!(4, uint))("cpuid", "={eax},={ebx},={ecx},={edx},{eax},{ecx}", eax, ecx);
//        info.a = asmt[0];
//        info.b = asmt[1];
//        info.c = asmt[2];
//        info.d = asmt[3];
//    }
//    else
//    version(InlineAsm_X86_Any)
//    asm pure nothrow @nogc
//    {
//        mov EAX, eax;
//        mov ECX, ecx;
//        cpuid;
//        mov info + CpuInfo.a.offsetof, EAX;
//        mov info + CpuInfo.b.offsetof, EBX;
//        mov info + CpuInfo.c.offsetof, ECX;
//        mov info + CpuInfo.d.offsetof, EDX;
//    }
//    return info;
//}

/++
Params:
    info = information  received from CPUID instruction
    eax = function id
    ecx = sub-function id

Bugs: `_cpuid` is not `pure @nothrow @nogc` function for now.
See also $(LINK2 https://github.com/ldc-developers/druntime/pull/80, LDC bug fix).
+/
CpuInfo _cpuid(uint eax, uint ecx = 0)
{
    CpuInfo info = void;
    version(LDC)
    {
        import ldc.llvmasm;
        auto asmt = __asmtuple!
        (uint, uint, uint, uint) (
            "cpuid", 
            "={eax},={ebx},={ecx},={edx},{eax},{ecx}", 
            eax, ecx);
        info.a = asmt.v[0];
        info.b = asmt.v[1];
        info.c = asmt.v[2];
        info.d = asmt.v[3];
    }
    else
    version(GNU)
    asm pure nothrow @nogc {
        "cpuid" : 
            "=a" info.a,
            "=b" info.b, 
            "=c" info.c,
            "=d" info.d,
            : "a" eax, "c" ecx;
    }
    else
    version(InlineAsm_X86_Any)
    asm pure nothrow @nogc
    {
        mov EAX, eax;
        mov ECX, ecx;
        cpuid;
        mov info + CpuInfo.a.offsetof, EAX;
        mov info + CpuInfo.b.offsetof, EBX;
        mov info + CpuInfo.c.offsetof, ECX;
        mov info + CpuInfo.d.offsetof, EDX;
    }
    return info;
}

@trusted pure nothrow @nogc @property:

/++
Returns: `true` if CPU vendor is virtual.
Params:
    v = CPU vendor
+/
bool isVirtual(VendorIndex v)
{
    return v >= VendorIndex.undefinedvm;
}

///
unittest
{
    with(VendorIndex)
    {
        assert(!undefined.isVirtual);
        assert(!intel.isVirtual);
        assert(undefinedvm.isVirtual);
        assert(parallels.isVirtual);
    }
}

/// VendorIndex name
immutable(char)[12][] vendors()
{
    align(4)
    static immutable char[12][] vendors =
    [
        "   undefined",
        " SiS SiS SiS",
        " UMC UMC UMC",
        " VIA VIA VIA",
        "AMDisbetter!",
        "AuthenticAMD",
        "CentaurHauls",
        "CyrixInstead",
        "GenuineIntel",
        "GenuineTMx86",
        "Geode by NSC",
        "NexGenDriven",
        "RiseRiseRise",
        "TransmetaCPU",
        "Vortex86 SoC",

        "undefined vm",
        " KVM KVM KVM",
        " lrpepyh  vr",
        "Microsoft Hv",
        "VMwareVMware",
        "XenVMMXenVMM",
    ];
    return vendors;
}

///
unittest
{
    assert(vendors[VendorIndex.intel] == "GenuineIntel");
}

/// VendorIndex encoded value.
VendorIndex vendorIndex()
{
    return _vendorId;
}

/// Maximum Input Value for Basic CPUID Information
uint maxBasicLeaf()
{
    return _maxBasicLeaf;
}

/// Maximum Input Value for Extended CPUID Information
uint maxExtendedLeaf()
{
    return _maxExtendedLeaf;
}

/// Encoded vendors
enum VendorIndex
{
    /// undefined
    undefined,

    /// SiS
    sis,
    /// UMC
    umc,
    /// VIA
    via,
    /// early engineering samples of AMD K5 processor
    amd_old,
    /// AMD
    amd,
    /// Centaur (Including some VIA CPU)
    centaur,
    /// Cyrix
    cyrix,
    /// Intel
    intel,
    /// Transmeta
    transmeta,
    /// National Semiconductor
    nsc,
    /// NexGen
    nexgen,
    /// Rise
    rise,
    /// Transmeta
    transmeta_old,
    /// Vortex
    vortex,

    /// undefined virtual machine
    undefinedvm, 

    /// KVM
    kvm,
    /// Parallels
    parallels,
    /// Microsoft Hyper-V or Windows Virtual PC
    microsoft,
    /// VMware
    vmware,
    /// Xen HVM
    xen,
}

/++
Brand, e.g. `Intel(R) Core(TM) i7-4770HQ CPU @ 2.20GHz`.
+/
string brand()
{
    return _brand[0 .. _brand_length];
}

string vendor()
{
    return _vendor;
}

/++
Brand Index
+/
ubyte brandIndex() { return leaf1Information.brandIndex; }
/++
CLFLUSH line size
Note: Value ∗ 8 = cache line size in bytes; used also by CLFLUSHOPT.
+/
ubyte clflushLineSize() { return leaf1Information.clflushLineSize; }
/++
Maximum number of addressable IDs for logical processors in this physical package.
+/
ubyte maxLogicalProcessors() { return leaf1Information.maxLogicalProcessors; }
/++
Initial APIC ID
+/
ubyte initialAPIC() { return leaf1Information.initialAPIC; }
/// Stepping ID
uint stepping() { return leaf1Information.stepping; }
/// Model
uint model() { return leaf1Information.model; }
/// Family ID
uint family() { return leaf1Information.family; }
/// Processor Type, Specification: Intel
uint type() { return leaf1Information.type; }
/// Extended Model ID
uint extendedModel() { return leaf1Information.extendedModel; }
/// Extended Family ID
uint extendedFamily() { return leaf1Information.extendedFamily; }
/// SSE3 Extensions
bool sse3() { return leaf1Information.sse3; }
/// Carryless Multiplication
bool pclmulqdq() { return leaf1Information.pclmulqdq; }
/// 64-bit DS Area
bool dtes64() { return leaf1Information.dtes64; }
/// MONITOR/MWAIT
bool monitor() { return leaf1Information.monitor; }
/// CPL Qualified Debug Store
bool ds_cpl() { return leaf1Information.ds_cpl; }
/// Virtual Machine Extensions
bool vmx() { return leaf1Information.vmx; }
/// Safer Mode Extensions
bool smx() { return leaf1Information.smx; }
/// Enhanced Intel SpeedStep® Technology
bool eist() { return leaf1Information.eist; }
/// Thermal Monitor 2
bool tm2() { return leaf1Information.tm2; }
/// SSSE3 Extensions
bool ssse3() { return leaf1Information.ssse3; }
/// L1 Context ID
bool cnxt_id() { return leaf1Information.cnxt_id; }
///
bool sdbg() { return leaf1Information.sdbg; }
/// Fused Multiply Add
bool fma() { return leaf1Information.fma; }
///
bool cmpxchg16b() { return leaf1Information.cmpxchg16b; }
/// TPR Update Control
bool xtpr() { return leaf1Information.xtpr; }
/// Perf/Debug Capability MSR xTPR Update Control
bool pdcm() { return leaf1Information.pdcm; }
/// Process-context Identifiers
bool pcid() { return leaf1Information.pcid; }
/// Direct Cache Access
bool dca() { return leaf1Information.dca; }
/// SSE4.1
bool sse41() { return leaf1Information.sse41; }
/// SSE4.2
bool sse42() { return leaf1Information.sse42; }
///
bool x2apic() { return leaf1Information.x2apic; }
///
bool movbe() { return leaf1Information.movbe; }
///
bool popcnt() { return leaf1Information.popcnt; }
///
bool tsc_deadline() { return leaf1Information.tsc_deadline; }
///
bool aes() { return leaf1Information.aes; }
///
bool xsave() { return leaf1Information.xsave; }
///
bool osxsave() { return leaf1Information.osxsave; }
///
bool avx() { return leaf1Information.avx; }
///
bool f16c() { return leaf1Information.f16c; }
///
bool rdrand() { return leaf1Information.rdrand; }
/// x87 FPU on Chip
bool fpu() { return leaf1Information.fpu; }
/// Virtual-8086 Mode Enhancement
bool vme() { return leaf1Information.vme; }
/// Debugging Extensions
bool de() { return leaf1Information.de; }
/// Page Size Extensions
bool pse() { return leaf1Information.pse; }
/// Time Stamp Counter
bool tsc() { return leaf1Information.tsc; }
/// RDMSR and WRMSR Support
bool msr() { return leaf1Information.msr; }
/// Physical Address Extensions
bool pae() { return leaf1Information.pae; }
/// Machine Check Exception
bool mce() { return leaf1Information.mce; }
/// CMPXCHG8B Inst.
bool cx8() { return leaf1Information.cx8; }
/// APIC on Chip
bool apic() { return leaf1Information.apic; }
/// SYSENTER and SYSEXIT
bool sep() { return leaf1Information.sep; }
/// Memory Type Range Registers
bool mtrr() { return leaf1Information.mtrr; }
/// PTE Global Bit
bool pge() { return leaf1Information.pge; }
/// Machine Check Architecture
bool mca() { return leaf1Information.mca; }
/// Conditional Move/Compare Instruction
bool cmov() { return leaf1Information.cmov; }
/// Page Attribute Table
bool pat() { return leaf1Information.pat; }
///  Page Size Extension
bool pse36() { return leaf1Information.pse36; }
/// Processor Serial Number
bool psn() { return leaf1Information.psn; }
/// CLFLUSH instruction
bool clfsh() { return leaf1Information.clfsh; }
/// Debug Store
bool ds() { return leaf1Information.ds; }
/// Thermal Monitor and Clock Ctrl
bool acpi() { return leaf1Information.acpi; }
/// MMX Technology
bool mmx() { return leaf1Information.mmx; }
/// FXSAVE/FXRSTOR
bool fxsr() { return leaf1Information.fxsr; }
/// SSE Extensions
bool sse() { return leaf1Information.sse; }
/// SSE2 Extensions
bool sse2() { return leaf1Information.sse2; }
/// Self Snoop
bool ss() { return leaf1Information.ss; }
/// Multi-threading
bool htt() { return leaf1Information.htt; }
/// Therm. Monitor
bool tm() { return leaf1Information.tm; }
/// Pend. Brk. EN.
bool pbe() { return leaf1Information.pbe; }