/++
$(H2 Common information for all x86 and x86_64 vendors.)

$(GREEN This module is compatible with betterC compilation mode.)

Note:
    `T.max` value value is used to represent fully-associative Cache/TLB.

References:
    $(LINK2 https://en.wikipedia.org/wiki/CPUID, wikipedia:CPUID)

License:   $(WEB www.boost.org/LICENSE_1_0.txt, Boost License 1.0).

Authors:   Ilya Yaroshenko
+/
module cpuid.x86_any;

version(LDC)
{
    import ldc.llvmasm;
    // @@@FIXME@@@
    // https://github.com/ldc-developers/druntime/pull/80
    pragma(LDC_inline_asm)
    {
        template __asmtuple(T...)
        {
            __asmtuple_t!(T) __asmtuple(const(char)[] asmcode, const(char)[] constraints, ...) pure nothrow @nogc;
        }
    }
}

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
private immutable uint _maxBasicLeaf;

/// Leaf1
private immutable Leaf1Information leaf1Information;
/// Leaf7
private immutable Leaf7Information leaf7Information;

/// ExtLeaf0
private immutable uint _maxExtendedLeaf;

/// Other
private immutable VendorIndex _vendorId;
private immutable VendorIndex _virtualVendorId;

/++
Initialize basic x86 CPU information.
It is safe to call this function multiple times.
+/
export extern(C)
nothrow @nogc
void mir_cpuid_x86_any_init()
{
    import cpuid.unified: _mut;
    static if (__VERSION__ >= 2068)
        pragma(inline, false);
    CpuInfo info = void;

    info = _cpuid(0);
    _maxBasicLeaf._mut = info.a;

    {
        uint[3] n = void;
        n[0] = info.b;
        n[1] = info.d;
        n[2] = info.c;
        _vendorId._mut = VendorIndex.undefined;
        auto vs = vendors[0 .. $ - 1];
        foreach(i, ref name; (cast(uint[3]*)(vs.ptr))[0 .. vs.length])
        {
            if (n[0] == name[0] && n[1] == name[1] && n[2] == name[2])
            {
                _vendorId._mut = cast(VendorIndex) i;
                break;
            }
        }
    }
    _virtualVendorId._mut = _vendorId;
    leaf1Information._mut.info = _cpuid(1);
    if(_maxBasicLeaf >= 7)
        leaf7Information._mut.info = _cpuid(0x07);
    if(leaf1Information.virtual)
    {
        auto infov = _cpuid(0x4000_0000);
        uint[3] n = void;
        n[0] = infov.b;
        n[1] = infov.c;
        n[2] = infov.d;
        _virtualVendorId._mut = VendorIndex.undefinedvm;
        auto vs = vendors[VendorIndex.undefined + 1 .. $ - 1];
        foreach(i, ref name; (cast(uint[3]*)(vs.ptr))[0 .. vs.length])
        {
            if (n[0] == name[0] && n[1] == name[1] && n[2] == name[2])
            {
                _virtualVendorId._mut = cast(VendorIndex) (i + VendorIndex.undefined + 1);
                break;
            }
        }
    }
    _maxExtendedLeaf._mut = _cpuid(0x8000_0000).a;
}

/// Basic information about CPU.
union Leaf1Information
{
    import mir.bitmanip: bitfields;
    /// CPUID payload
    CpuInfo info;
    struct
    {
        @trusted @property pure nothrow @nogc:
        version(D_Ddoc)
        {
        const:
            /// Stepping ID
            uint stepping();
            /// Model
            uint model();
            /// Family ID
            uint family();
            /// Processor Type, Specification: Intel
            uint type();
            /// Extended Model ID
            uint extendedModel();
            /// Extended Family ID
            uint extendedFamily();


            /// Brand Index
            ubyte brandIndex;
            /// `clflush` line size
            ubyte clflushLineSize;
            /// maximal number of logical processors
            ubyte maxLogicalProcessors;
            /// initial APIC
            ubyte initialAPIC;

            /// SSE3 Extensions
            bool sse3();
            /// Carryless Multiplication
            bool pclmulqdq();
            /// 64-bit DS Area
            bool dtes64();
            /// MONITOR/MWAIT
            bool monitor();
            ///(); /// CPL Qualified Debug Store
            bool ds_cpl();
            /// Virtual Machine Extensions
            bool vmx();
            /// Safer Mode Extensions
            bool smx();
            /// Enhanced Intel SpeedStep® Technology
            bool eist();
            /// Thermal Monitor 2
            bool therm_monitor2();
            /// SSSE3 Extensions
            bool ssse3();
            /// L1 Context ID
            bool cnxt_id();
            ///
            bool sdbg();
            /// Fused Multiply Add
            bool fma();
            ///
            bool cmpxchg16b();
            /// TPR Update Control
            bool xtpr();
            /// Perf/Debug Capability MSR xTPR Update Control
            bool pdcm();
            /// Process-context Identifiers
            bool pcid();
            /// Direct Cache Access
            bool dca();
            /// SSE4.1
            bool sse41();
            /// SSE4.2
            bool sse42();
            ///
            bool x2apic();
            ///
            bool movbe();
            ///
            bool popcnt();
            ///
            bool tsc_deadline();
            ///
            bool aes();
            ///
            bool xsave();
            ///
            bool osxsave();
            ///
            bool avx();
            ///
            bool f16c();
            ///
            bool rdrand();
            ///
            bool virtual();
            /// x87 FPU on Chip
            bool fpu();
            /// Virtual-8086 Mode Enhancement
            bool vme();
            /// Debugging Extensions
            bool de();
            /// Page Size Extensions
            bool pse();
            /// Time Stamp Counter
            bool tsc();
            /// RDMSR and WRMSR Support
            bool msr();
            /// Physical Address Extensions
            bool pae();
            /// Machine Check Exception
            bool mce();
            /// CMPXCHG8B Inst.
            bool cx8();
            /// APIC on Chip
            bool apic();
            /// SYSENTER and SYSEXIT
            bool sep();
            /// Memory Type Range Registers
            bool mtrr();
            /// PTE Global Bit
            bool pge();
            /// Machine Check Architecture
            bool mca();
            /// Conditional Move/Compare Instruction
            bool cmov();
            /// Page Attribute Table
            bool pat();
            ///  Page Size Extension
            bool pse36();
            /// Processor Serial Number
            bool psn();
            /// CLFLUSH instruction
            bool clfsh();
            /// Debug Store
            bool ds();
            /// Thermal Monitor and Clock Ctrl
            bool acpi();
            /// MMX Technology
            bool mmx();
            /// FXSAVE/FXRSTOR
            bool fxsr();
            /// SSE Extensions
            bool sse();
            /// SSE2 Extensions
            bool sse2();
            /// Self Snoop
            bool self_snoop();
            /// Multi-threading
            bool htt();
            /// Therm. Monitor
            bool therm_monitor();
            /// Pend. Brk. EN.
            bool pbe();
        }
        else
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
                bool, "therm_monitor2", 1, /// Thermal Monitor 2
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
                bool, "virtual", 1,
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
                bool, "self_snoop", 1, /// Self Snoop
                bool, "htt", 1, /// Multi-threading
                bool, "therm_monitor", 1, /// Therm. Monitor
                bool, "", 1,
                bool, "pbe", 1, /// Pend. Brk. EN.
            ));
        }
    }
}

/// ditto
alias cpuid_x86_any_init = mir_cpuid_x86_any_init;

/// Extended information about CPU.
union Leaf7Information
{
    import mir.bitmanip: bitfields;
    /// CPUID payload
    CpuInfo info;
    struct
    {
        /// Reports the maximum input value for supported leaf 7 sub-leaves
        uint max7SubLeafs;
        @trusted @property pure nothrow @nogc:
        version(D_Ddoc)
        {
        const:
             /// Supports RDFSBASE/RDGSBASE/WRFSBASE/WRGSBASE if 1.
             bool fsgsbase();
             ///MSR is supported if 1.
             bool ia32_tsc_adjust();
             /// Supports Intel® Software Guard Extensions (Intel® SGX Extensions) if 1.
             bool sgx();
             /// Bit Manipulation Instruction Set 1
             bool bmi1();
             /// Transactional Synchronization Extensions
             bool hle();
             /// Advanced Vector Extensions 2
             bool avx2();
             /// x87 FPU Data Pointer updated only on x87 exceptions if 1.
             bool fdp_excptn_only();
             /// Supports Supervisor-Mode Execution Prevention if 1.
             bool smep();
             /// Bit Manipulation Instruction Set 2
             bool bmi2();
             /// Enhanced REP MOVSB/STOSB if 1.
             bool supports();
             /// If 1, supports INVPCID instruction for system software that manages process-context identifiers.
             bool invpcid();
             /// Transactional Synchronization Extensions
             bool rtm();
             /// Supports Intel® Resource Director Technology (Intel® RDT) Monitoring capability if 1.
             bool rdt_m();
             ///FPU CS and FPU DS values if 1.
             bool deprecates();
             /// Supports Intel® Memory Protection Extensions if 1.
             bool mpx();
             /// Supports Intel® Resource Director Technology (Intel® RDT) Allocation capability if 1.
             bool rdt_a();
             /// AVX-512 Foundation
             bool avx512f();
             /// AVX-512 Doubleword and Quadword Instructions
             bool avx512dq();
             /// RDSEED instruction
             bool rdseed();
             /// Intel ADX (Multi-Precision Add-Carry Instruction Extensions)
             bool adx();
             /// Supports Supervisor-Mode Access Prevention (and the CLAC/STAC instructions) if 1.
             bool smap();
             /// AVX-512 Integer Fused Multiply-Add Instructions
             bool avx512ifma();
             /// PCOMMIT instruction
             bool pcommit();
             /// CLFLUSHOPT instruction
             bool clflushopt();
             /// CLWB instruction
             bool clwb();
             /// Intel Processor Trace.
             bool intel_pt();
             /// AVX-512 Prefetch Instructions
             bool avx512pf();
             /// AVX-512 Exponential and Reciprocal Instructions
             bool avx512er();
             /// AVX-512 Conflict Detection Instructions
             bool avx512cd();
             /// supports Intel® Secure Hash Algorithm Extens
             bool sha();
             /// AVX-512 Byte and Word Instructions
             bool avx512bw();
             /// AVX-512 Vector Length Extensions
             bool avx512vl();
             /// PREFETCHWT1 instruction
             bool prefetchwt1();
             /// AVX-512 Vector Bit Manipulation Instructions
             bool avx512vbmi();
             /// Memory Protection Keys for User-mode pages
             bool pku();
             /// PKU enabled by OS
             bool ospke();

        }
        else
        {
            mixin(bitfields!(
                bool, "fsgsbase", 1, /// Supports RDFSBASE/RDGSBASE/WRFSBASE/WRGSBASE if 1.
                bool, "ia32_tsc_adjust", 1, ///MSR is supported if 1.
                bool, "sgx", 1, /// Supports Intel® Software Guard Extensions (Intel® SGX Extensions) if 1.
                bool, "bmi1", 1, /// Bit Manipulation Instruction Set 1
                bool, "hle", 1, /// Transactional Synchronization Extensions
                bool, "avx2", 1, /// Advanced Vector Extensions 2
                bool, "fdp_excptn_only", 1, /// x87 FPU Data Pointer updated only on x87 exceptions if 1.
                bool, "smep", 1, /// Supports Supervisor-Mode Execution Prevention if 1.
                bool, "bmi2", 1, /// Bit Manipulation Instruction Set 2
                bool, "supports", 1, /// Enhanced REP MOVSB/STOSB if 1.
                bool, "invpcid", 1, /// If 1, supports INVPCID instruction for system software that manages process-context identifiers.
                bool, "rtm", 1, /// Transactional Synchronization Extensions
                bool, "rdt_m", 1, /// Supports Intel® Resource Director Technology (Intel® RDT) Monitoring capability if 1.
                bool, "deprecates", 1, ///FPU CS and FPU DS values if 1.
                bool, "mpx", 1, /// Supports Intel® Memory Protection Extensions if 1.
                bool, "rdt_a", 1, /// Supports Intel® Resource Director Technology (Intel® RDT) Allocation capability if 1.
                bool, "avx512f", 1, /// AVX-512 Foundation
                bool, "avx512dq", 1, /// AVX-512 Doubleword and Quadword Instructions
                bool, "rdseed", 1, /// RDSEED instruction
                bool, "adx", 1, /// Intel ADX (Multi-Precision Add-Carry Instruction Extensions)
                bool, "smap", 1, /// Supports Supervisor-Mode Access Prevention (and the CLAC/STAC instructions) if 1.
                bool, "avx512ifma", 1, /// AVX-512 Integer Fused Multiply-Add Instructions
                bool, "pcommit", 1, /// PCOMMIT instruction
                bool, "clflushopt", 1, /// CLFLUSHOPT instruction
                bool, "clwb", 1, /// CLWB instruction
                bool, "intel_pt", 1, /// Intel Processor Trace.
                bool, "avx512pf", 1, /// AVX-512 Prefetch Instructions
                bool, "avx512er", 1, /// AVX-512 Exponential and Reciprocal Instructions
                bool, "avx512cd", 1, /// AVX-512 Conflict Detection Instructions
                bool, "sha", 1, /// supports Intel® Secure Hash Algorithm Extens
                bool, "avx512bw", 1, /// AVX-512 Byte and Word Instructions
                bool, "avx512vl", 1, /// AVX-512 Vector Length Extensions
            ));
            mixin(bitfields!(
                bool, "prefetchwt1", 1, /// PREFETCHWT1 instruction
                bool, "avx512vbmi", 1, /// AVX-512 Vector Bit Manipulation Instructions
                bool, "", 1, ///
                bool, "pku", 1, /// Memory Protection Keys for User-mode pages
                bool, "ospke", 1, /// PKU enabled by OS
                bool, "", 27, ///
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
    eax = function id
    ecx = sub-function id
+/
pure nothrow @nogc @trusted
CpuInfo _cpuid()(uint eax, uint ecx = 0)
{
    uint a = void;
    uint b = void;
    uint c = void;
    uint d = void;
    version(LDC)
    {
        pragma(inline, true);
        auto asmt = __asmtuple!
        (uint, uint, uint, uint) (
            "cpuid", 
            "={eax},={ebx},={ecx},={edx},{eax},{ecx}", 
            eax, ecx);
        a = asmt.v[0];
        b = asmt.v[1];
        c = asmt.v[2];
        d = asmt.v[3];
    }
    else
    version(GNU)
    asm pure nothrow @nogc
    {
        "cpuid" : 
            "=a" a,
            "=b" b, 
            "=c" c,
            "=d" d,
            : "a" eax, "c" ecx;
    }
    else
    version(InlineAsm_X86_Any)
    asm pure nothrow @nogc
    {
        mov EAX, eax;
        mov ECX, ecx;
        cpuid;
        mov a, EAX;
        mov b, EBX;
        mov c, ECX;
        mov d, EDX;
    }
    else static assert(0);
    return CpuInfo(a, b, c, d);
}

nothrow @nogc @property:

align(4)
private __gshared immutable char[12][21] _vendors =
[
    "GenuineIntel",
    "AuthenticAMD",

    " SiS SiS SiS",
    " UMC UMC UMC",
    " VIA VIA VIA",
    "AMDisbetter!",
    "CentaurHauls",
    "CyrixInstead",
    "GenuineTMx86",
    "Geode by NSC",
    "NexGenDriven",
    "RiseRiseRise",
    "TransmetaCPU",
    "Vortex86 SoC",
    "   undefined",

    " KVM KVM KVM",
    " lrpepyh  vr",
    "Microsoft Hv",
    "VMwareVMware",
    "XenVMMXenVMM",
    "undefined vm",
];

/// VendorIndex name
immutable(char)[12][] vendors()()
{
    return _vendors;
}

///
unittest
{
    assert(vendors[VendorIndex.intel] == "GenuineIntel");
}

/// VendorIndex encoded value.
VendorIndex vendorIndex()()
{
    return _vendorId;
}

/// VendorIndex encoded value for virtual machine.
VendorIndex virtualVendorIndex()()
{
    return _virtualVendorId;
}

/// Maximum Input Value for Basic CPUID Information
uint maxBasicLeaf()()
{
    return _maxBasicLeaf;
}

/// Maximum Input Value for Extended CPUID Information
uint maxExtendedLeaf()()
{
    return _maxExtendedLeaf;
}

/// Reports the maximum input value for supported leaf 7 sub-leaves.
uint max7SubLeafs()()
{
    return leaf7Information.max7SubLeafs;
}

/// Encoded vendors
enum VendorIndex
{
    /// Intel
    intel,
    /// AMD
    amd,

    /// SiS
    sis,
    /// UMC
    umc,
    /// VIA
    via,
    /// early engineering samples of AMD K5 processor
    amd_old,
    /// Centaur (Including some VIA CPU)
    centaur,
    /// Cyrix
    cyrix,
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

    /// undefined
    undefined,


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

    /// undefined virtual machine
    undefinedvm, 
}

/++
Brand, e.g. `Intel(R) Core(TM) i7-4770HQ CPU @ 2.20GHz`.
Returns: brand length
Params: brand = fixed length string to initiate
+/
size_t brand()(ref char[48] brand)
{
    static if (__VERSION__ >= 2068)
        pragma(inline, false);
    CpuInfo info = void;
    info = _cpuid(0 + 2 ^ 0x8000_0000);
    (cast(uint[12])brand)[0 * 4 + 0] = info.a;
    (cast(uint[12])brand)[0 * 4 + 1] = info.b;
    (cast(uint[12])brand)[0 * 4 + 2] = info.c;
    (cast(uint[12])brand)[0 * 4 + 3] = info.d;
    info = _cpuid(1 + 2 ^ 0x8000_0000);
    (cast(uint[12])brand)[1 * 4 + 0] = info.a;
    (cast(uint[12])brand)[1 * 4 + 1] = info.b;
    (cast(uint[12])brand)[1 * 4 + 2] = info.c;
    (cast(uint[12])brand)[1 * 4 + 3] = info.d;
    info = _cpuid(2 + 2 ^ 0x8000_0000);
    (cast(uint[12])brand)[2 * 4 + 0] = info.a;
    (cast(uint[12])brand)[2 * 4 + 1] = info.b;
    (cast(uint[12])brand)[2 * 4 + 2] = info.c;
    (cast(uint[12])brand)[2 * 4 + 3] = info.d;

    size_t i = brand.length;
    while(brand[i - 1] == '\0')
    {
        --i;
        if(i == 0)
            break;
    }
    return i;
}

/++
Vendor, e.g. `GenuineIntel`.
+/
string vendor()()
{
    return vendors[_vendorId];
}

/++
Virtual vendor, e.g. `GenuineIntel` or `VMwareVMware`.
+/
string virtualVendor()()
{
    return vendors[_virtualVendorId];
}

/++
Brand Index
+/
ubyte brandIndex()() { return leaf1Information.brandIndex; }
/++
CLFLUSH line size
Note: Value ∗ 8 = cache line size in bytes; used also by CLFLUSHOPT.
+/
ubyte clflushLineSize()() { return leaf1Information.clflushLineSize; }
/++
Maximum number of addressable IDs for logical processors in this physical package.
+/
ubyte maxLogicalProcessors()() { return leaf1Information.maxLogicalProcessors; }
/++
Initial APIC ID
+/
ubyte initialAPIC()() { return leaf1Information.initialAPIC; }
/// Stepping ID
uint stepping()() { return leaf1Information.stepping; }
/// Model
uint model()() { return leaf1Information.model; }
/// Family ID
uint family()() { return leaf1Information.family; }
/// Processor Type, Specification: Intel
uint type()() { return leaf1Information.type; }
/// Extended Model ID
uint extendedModel()() { return leaf1Information.extendedModel; }
/// Extended Family ID
uint extendedFamily()() { return leaf1Information.extendedFamily; }
/// SSE3 Extensions
bool sse3()() { return leaf1Information.sse3; }
/// Carryless Multiplication
bool pclmulqdq()() { return leaf1Information.pclmulqdq; }
/// 64-bit DS Area
bool dtes64()() { return leaf1Information.dtes64; }
/// MONITOR/MWAIT
bool monitor()() { return leaf1Information.monitor; }
/// CPL Qualified Debug Store
bool ds_cpl()() { return leaf1Information.ds_cpl; }
/// Virtual Machine Extensions
bool vmx()() { return leaf1Information.vmx; }
/// Safer Mode Extensions
bool smx()() { return leaf1Information.smx; }
/// Enhanced Intel SpeedStep® Technology
bool eist()() { return leaf1Information.eist; }
/// Thermal Monitor 2
bool therm_monitor2()() { return leaf1Information.therm_monitor2; }
/// SSSE3 Extensions
bool ssse3()() { return leaf1Information.ssse3; }
/// L1 Context ID
bool cnxt_id()() { return leaf1Information.cnxt_id; }
///
bool sdbg()() { return leaf1Information.sdbg; }
/// Fused Multiply Add
bool fma()() { return leaf1Information.fma; }
///
bool cmpxchg16b()() { return leaf1Information.cmpxchg16b; }
/// TPR Update Control
bool xtpr()() { return leaf1Information.xtpr; }
/// Perf/Debug Capability MSR xTPR Update Control
bool pdcm()() { return leaf1Information.pdcm; }
/// Process-context Identifiers
bool pcid()() { return leaf1Information.pcid; }
/// Direct Cache Access
bool dca()() { return leaf1Information.dca; }
/// SSE4.1
bool sse41()() { return leaf1Information.sse41; }
/// SSE4.2
bool sse42()() { return leaf1Information.sse42; }
///
bool x2apic()() { return leaf1Information.x2apic; }
///
bool movbe()() { return leaf1Information.movbe; }
///
bool popcnt()() { return leaf1Information.popcnt; }
///
bool tsc_deadline()() { return leaf1Information.tsc_deadline; }
///
bool aes()() { return leaf1Information.aes; }
///
bool xsave()() { return leaf1Information.xsave; }
///
bool osxsave()() { return leaf1Information.osxsave; }
///
bool avx()() { return leaf1Information.avx; }
///
bool f16c()() { return leaf1Information.f16c; }
///
bool rdrand()() { return leaf1Information.rdrand; }
/// Virtual machine
bool virtual()() { return leaf1Information.virtual; }
/// x87 FPU on Chip
bool fpu()() { return leaf1Information.fpu; }
/// Virtual-8086 Mode Enhancement
bool vme()() { return leaf1Information.vme; }
/// Debugging Extensions
bool de()() { return leaf1Information.de; }
/// Page Size Extensions
bool pse()() { return leaf1Information.pse; }
/// Time Stamp Counter
bool tsc()() { return leaf1Information.tsc; }
/// RDMSR and WRMSR Support
bool msr()() { return leaf1Information.msr; }
/// Physical Address Extensions
bool pae()() { return leaf1Information.pae; }
/// Machine Check Exception
bool mce()() { return leaf1Information.mce; }
/// CMPXCHG8B Inst.
bool cx8()() { return leaf1Information.cx8; }
/// APIC on Chip
bool apic()() { return leaf1Information.apic; }
/// SYSENTER and SYSEXIT
bool sep()() { return leaf1Information.sep; }
/// Memory Type Range Registers
bool mtrr()() { return leaf1Information.mtrr; }
/// PTE Global Bit
bool pge()() { return leaf1Information.pge; }
/// Machine Check Architecture
bool mca()() { return leaf1Information.mca; }
/// Conditional Move/Compare Instruction
bool cmov()() { return leaf1Information.cmov; }
/// Page Attribute Table
bool pat()() { return leaf1Information.pat; }
///  Page Size Extension
bool pse36()() { return leaf1Information.pse36; }
/// Processor Serial Number
bool psn()() { return leaf1Information.psn; }
/// CLFLUSH instruction
bool clfsh()() { return leaf1Information.clfsh; }
/// Debug Store
bool ds()() { return leaf1Information.ds; }
/// Thermal Monitor and Clock Ctrl
bool acpi()() { return leaf1Information.acpi; }
/// MMX Technology
bool mmx()() { return leaf1Information.mmx; }
/// FXSAVE/FXRSTOR
bool fxsr()() { return leaf1Information.fxsr; }
/// SSE Extensions
bool sse()() { return leaf1Information.sse; }
/// SSE2 Extensions
bool sse2()() { return leaf1Information.sse2; }
/// Self Snoop
bool self_snoop()() { return leaf1Information.self_snoop; }
/// Multi-threading
bool htt()() { return leaf1Information.htt; }
/// Therm. Monitor
bool therm_monitor()() { return leaf1Information.therm_monitor; }
/// Pend. Brk. EN.
bool pbe()() { return leaf1Information.pbe; }

// EXTENDED 7

/// Supports RDFSBASE/RDGSBASE/WRFSBASE/WRGSBASE if 1.
bool fsgsbase()() { return leaf7Information.fsgsbase; }
///MSR is supported if 1.
bool ia32_tsc_adjust()() { return leaf7Information.ia32_tsc_adjust; }
/// Supports Intel® Software Guard Extensions (Intel® SGX Extensions) if 1.
bool sgx()() { return leaf7Information.sgx; }
/// Bit Manipulation Instruction Set 1
bool bmi1()() { return leaf7Information.bmi1; }
/// Transactional Synchronization Extensions
bool hle()() { return leaf7Information.hle; }
/// Advanced Vector Extensions 2
bool avx2()() { return leaf7Information.avx2; }
/// x87 FPU Data Pointer updated only on x87 exceptions if 1.
bool fdp_excptn_only()() { return leaf7Information.fdp_excptn_only; }
/// Supports Supervisor-Mode Execution Prevention if 1.
bool smep()() { return leaf7Information.smep; }
/// Bit Manipulation Instruction Set 2
bool bmi2()() { return leaf7Information.bmi2; }
/// Enhanced REP MOVSB/STOSB if 1.
bool supports()() { return leaf7Information.supports; }
/// If 1, supports INVPCID instruction for system software that manages process-context identifiers.
bool invpcid()() { return leaf7Information.invpcid; }
/// Transactional Synchronization Extensions
bool rtm()() { return leaf7Information.rtm; }
/// Supports Intel® Resource Director Technology (Intel® RDT) Monitoring capability if 1.
bool rdt_m()() { return leaf7Information.rdt_m; }
///FPU CS and FPU DS values if 1.
bool deprecates()() { return leaf7Information.deprecates; }
/// Supports Intel® Memory Protection Extensions if 1.
bool mpx()() { return leaf7Information.mpx; }
/// Supports Intel® Resource Director Technology (Intel® RDT) Allocation capability if 1.
bool rdt_a()() { return leaf7Information.rdt_a; }
/// AVX-512 Foundation
bool avx512f()() { return leaf7Information.avx512f; }
/// AVX-512 Doubleword and Quadword Instructions
bool avx512dq()() { return leaf7Information.avx512dq; }
/// RDSEED instruction
bool rdseed()() { return leaf7Information.rdseed; }
/// Intel ADX (Multi-Precision Add-Carry Instruction Extensions)
bool adx()() { return leaf7Information.adx; }
/// Supports Supervisor-Mode Access Prevention (and the CLAC/STAC instructions) if 1.
bool smap()() { return leaf7Information.smap; }
/// AVX-512 Integer Fused Multiply-Add Instructions
bool avx512ifma()() { return leaf7Information.avx512ifma; }
/// PCOMMIT instruction
bool pcommit()() { return leaf7Information.pcommit; }
/// CLFLUSHOPT instruction
bool clflushopt()() { return leaf7Information.clflushopt; }
/// CLWB instruction
bool clwb()() { return leaf7Information.clwb; }
/// Intel Processor Trace.
bool intel_pt()() { return leaf7Information.intel_pt; }
/// AVX-512 Prefetch Instructions
bool avx512pf()() { return leaf7Information.avx512pf; }
/// AVX-512 Exponential and Reciprocal Instructions
bool avx512er()() { return leaf7Information.avx512er; }
/// AVX-512 Conflict Detection Instructions
bool avx512cd()() { return leaf7Information.avx512cd; }
/// supports Intel® Secure Hash Algorithm Extens
bool sha()() { return leaf7Information.sha; }
/// AVX-512 Byte and Word Instructions
bool avx512bw()() { return leaf7Information.avx512bw; }
/// AVX-512 Vector Length Extensions
bool avx512vl()() { return leaf7Information.avx512vl; }
/// PREFETCHWT1 instruction
bool prefetchwt1()() { return leaf7Information.prefetchwt1; }
/// AVX-512 Vector Bit Manipulation Instructions
bool avx512vbmi()() { return leaf7Information.avx512vbmi; }
/// Memory Protection Keys for User-mode pages
bool pku()() { return leaf7Information.pku; }
/// PKU enabled by OS
bool ospke()() { return leaf7Information.ospke; }