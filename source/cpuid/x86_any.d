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

private __gshared immutable Vendor _vendorId;
private __gshared immutable uint _maxBasicLeaf;
private __gshared immutable uint _maxExtendedLeaf;

pure nothrow @nogc
shared static this()
{
    BasicInfo info = void;
    _basicLeafs(info);
    _maxBasicLeaf = info.maxBasicLeaf;
    _maxExtendedLeaf = info.maxExtendedLeaf;

    foreach(i, ref name; vendorName)
    {
        if(cast(uint[3]) info.vendor  == cast(uint[3]) name)
        {
            _vendorId = cast(Vendor) i;
            break;
        }
    }

    with(Vendor)
        if(_vendorId == undefined)
            _vendorId = undefinedvm;
}

/// Vendor encoded value.
pragma(inline, true)
pure nothrow @nogc @property @safe
Vendor vendor()
{
    return _vendorId;
}

///
unittest
{
    debug(cpuid) import std.stdio;
    debug(cpuid) writefln("Vendor enumeration is '%s'", vendor);
}

/// Maximum Input Value for Basic CPUID Information
pragma(inline, true)
pure nothrow @nogc @property @safe
uint maxBasicLeaf()
{
    return _maxBasicLeaf;
}

///
unittest
{
    debug(cpuid) import std.stdio;
    debug(cpuid) writefln("Maximum Input Value for Basic CPUID Information = 0x%X", _maxBasicLeaf);
}

/// Maximum Input Value for Extended CPUID Information
pragma(inline, true)
pure nothrow @nogc @property @safe
uint maxExtendedLeaf()
{
    return _maxExtendedLeaf;
}

///
unittest
{
    debug(cpuid) import std.stdio;
    debug(cpuid) writefln("Maximum Input Value for Extended CPUID Information = 0x8000_0000 | 0x%X", _maxExtendedLeaf ^ 0x8000_0000);
}

/++
Returns: `true` if CPU vendor is virtual.
Params:
    v = CPU vendor
+/
pragma(inline, true)
pure nothrow @nogc @property
bool isVirtual(Vendor v)
{
    return v >= Vendor.undefinedvm;
}

///
unittest
{
    with(Vendor)
    {
        assert(!undefined.isVirtual);
        assert(!intel.isVirtual);
        assert(undefinedvm.isVirtual);
        assert(parallels.isVirtual);
    }
}

/// Encoded vendors
enum Vendor
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

/// Vendor name
align(4)
static immutable char[12][] vendorName =
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

///
unittest
{
    assert(vendorName[Vendor.intel] == "GenuineIntel");
}

/++
Params:
    info = information received from CPUID instruction
    eax = function id
+/

pragma(inline, true)
pure nothrow @nogc
void _cpuid(ref uint[4] info, uint eax)
{
    version(D_InlineAsm_X86)
    asm pure nothrow @nogc
    {
        push ESI;
        mov ESI, info;
        mov EAX, eax;
        cpuid;
        mov [ESI + 0x0], EAX;
        mov [ESI + 0x4], EBX;
        mov [ESI + 0x8], ECX;
        mov [ESI + 0xC], EDX;
        pop ESI;
    }
    else
    version(D_InlineAsm_X86_64)
    asm pure nothrow @nogc
    {
        push RSI;
        mov RSI, info;
        mov EAX, eax;
        cpuid;
        mov [RSI + 0x0], EAX;
        mov [RSI + 0x4], EBX;
        mov [RSI + 0x8], ECX;
        mov [RSI + 0xC], EDX;
        pop RSI;
    }
    else static assert(0);
}

/++
Params:
    info = information  received from CPUID instruction
    eax = function id
    ecx = sub-function id
+/
pragma(inline, true)
pure nothrow @nogc
void _cpuid(ref uint[4] info, uint eax, uint ecx)
{
    version(D_InlineAsm_X86)
    asm pure nothrow @nogc
    {
        push ESI;
        mov ESI, info;
        mov EAX, eax;
        mov ECX, ecx;
        cpuid;
        mov [ESI + 0x0], EAX;
        mov [ESI + 0x4], EBX;
        mov [ESI + 0x8], ECX;
        mov [ESI + 0xC], EDX;
        pop ESI;
    }
    else
    version(D_InlineAsm_X86_64)
    asm pure nothrow @nogc
    {
        push RSI;
        mov RSI, info;
        mov EAX, eax;
        mov ECX, ecx;
        cpuid;
        mov [RSI + 0x0], EAX;
        mov [RSI + 0x4], EBX;
        mov [RSI + 0x8], ECX;
        mov [RSI + 0xC], EDX;
        pop RSI;
    }
}

/// Basic information about CPU.
struct BasicInfo
{
    /// Maximum Input Value for Basic CPUID Information.
    uint maxBasicLeaf;
    /// Maximum Input Value for Extended CPUID Information.
    uint maxExtendedLeaf;
    /// Vendor name.
    char[12] vendor;
}

/// Fills basic information.
pragma(inline, true)
pure nothrow @nogc
private void _basicLeafs(ref BasicInfo info)
{
    version(D_InlineAsm_X86)
    asm pure nothrow @nogc
    {
        push ESI;
        mov ESI, info;

        mov EAX, 0;
        cpuid;

        mov [ESI + BasicInfo.maxBasicLeaf.offsetof], EAX;
        mov [ESI + BasicInfo.vendor.offsetof + 0x0], EBX;
        mov [ESI + BasicInfo.vendor.offsetof + 0x4], EDX;
        mov [ESI + BasicInfo.vendor.offsetof + 0x8], ECX;

        mov EAX, 0x8000_0000;
        cpuid;
        mov [ESI + BasicInfo.maxExtendedLeaf.offsetof], EAX;

        pop ESI;
    }
    else
    version(D_InlineAsm_X86_64)
    asm pure nothrow @nogc
    {
        push RSI;
        mov RSI, info;

        mov EAX, 0;
        cpuid;

        mov [RSI + BasicInfo.maxBasicLeaf.offsetof], EAX;
        mov [RSI + BasicInfo.vendor.offsetof + 0x0], EBX;
        mov [RSI + BasicInfo.vendor.offsetof + 0x4], EDX;
        mov [RSI + BasicInfo.vendor.offsetof + 0x8], ECX;

        mov EAX, 0x8000_0000;
        cpuid;
        mov [RSI + BasicInfo.maxExtendedLeaf.offsetof], EAX;

        pop RSI;
    }
    else static assert(0);
}

///
unittest
{
    BasicInfo info = void;
    _basicLeafs(info);
}

/// Fills brand name, e.g. `Intel(R) Core(TM) i7-4770HQ CPU @ 2.20GHz`
pragma(inline, true)
pure nothrow @nogc
private void _brand(ref char[48] name)
{
    version(D_InlineAsm_X86)
    asm pure nothrow @nogc
    {
        push ESI;
        mov ESI, name;

        mov EAX, 0x80000002;
        cpuid;
        mov [ESI + 0x00], EAX;
        mov [ESI + 0x04], EBX;
        mov [ESI + 0x08], ECX;
        mov [ESI + 0x0C], EDX;

        mov EAX, 0x80000003;
        cpuid;
        mov [ESI + 0x10], EAX;
        mov [ESI + 0x14], EBX;
        mov [ESI + 0x18], ECX;
        mov [ESI + 0x1C], EDX;

        mov EAX, 0x80000004;
        cpuid;
        mov [ESI + 0x20], EAX;
        mov [ESI + 0x24], EBX;
        mov [ESI + 0x28], ECX;
        mov [ESI + 0x2C], EDX;

        pop ESI;
    }
    else
    version(D_InlineAsm_X86_64)
    asm pure nothrow @nogc
    {
        push RSI;
        mov RSI, name;

        mov EAX, 0x80000002;
        cpuid;
        mov [RSI + 0x00], EAX;
        mov [RSI + 0x04], EBX;
        mov [RSI + 0x08], ECX;
        mov [RSI + 0x0C], EDX;

        mov EAX, 0x80000003;
        cpuid;
        mov [RSI + 0x10], EAX;
        mov [RSI + 0x14], EBX;
        mov [RSI + 0x18], ECX;
        mov [RSI + 0x1C], EDX;

        mov EAX, 0x80000004;
        cpuid;
        mov [RSI + 0x20], EAX;
        mov [RSI + 0x24], EBX;
        mov [RSI + 0x28], ECX;
        mov [RSI + 0x2C], EDX;

        pop RSI;
    }
    else static assert(0);
}

///
unittest
{
    align(4) char[48] name = void;
    _brand(name);
    debug(cpuid) import std.stdio;
    debug(cpuid) writeln(name[]); // null `'\0'` chars are possible in the end of a name
}
