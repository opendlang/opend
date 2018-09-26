/++
$(H2 High level abstraction on top of all architectures.)

$(GREEN This module is compatible with betterC compilation mode.)


License:   $(WEB www.boost.org/LICENSE_1_0.txt, Boost License 1.0).

Authors:   Ilya Yaroshenko
+/
module cpuid.unified;

///
unittest
{
    void smallReport()
    {
        import cpuid.unified;

        import std.stdio: writefln;
        enum fmt = "%14s: %s";

        fmt.writefln("cores", cores);
        fmt.writefln("threads", threads);

        fmt.writefln("data caches", dCache.length);
        fmt.writefln("code caches", iCache.length);
        fmt.writefln("unified caches", uCache.length);

        fmt.writefln("data TLBs", dTlb.length);
        fmt.writefln("code TLBs", iTlb.length);
        fmt.writefln("unified TLBs", uTlb.length);
    }
}

public import cpuid.common;

version(X86)
    version = X86_Any;
version(X86_64)
    version = X86_Any;

version(X86_Any)
{
    enum uint _dCache_max_length = 1;
    enum uint _iCache_max_length = 1;
    enum uint _uCache_max_length = 3;

    enum uint _dTlb_max_length   = 2;
    enum uint _iTlb_max_length   = 2;
    enum uint _uTlb_max_length   = 1;
}
else
static assert(0);

private __gshared
{
    immutable uint _cpus;
    immutable uint _cores;
    immutable uint _threads;
    immutable uint _iCache_length; immutable Cache[_iCache_max_length] _iCache;
    immutable uint _dCache_length; immutable Cache[_dCache_max_length] _dCache;
    immutable uint _uCache_length; immutable Cache[_uCache_max_length] _uCache;
    immutable uint _iTlb_length;   immutable Tlb[_iTlb_max_length] _iTlb;
    immutable uint _dTlb_length;   immutable Tlb[_dTlb_max_length] _dTlb;
    immutable uint _uTlb_length;   immutable Tlb[_uTlb_max_length] _uTlb;
}

private T2 assocCopy(T2, T1)(T1 from)
{
    import std.traits: Unqual;
    Unqual!T2 to = cast(T2) from;
    static if(!is(Unqual!T1 == Unqual!T2))
    {
        if(from == T1.max)
        {
            to = T2.max;
        }
    }
    return to;
}

package ref T _mut(T)(return ref immutable T value)
{
    return *cast(T*)&value;
}

export
nothrow @nogc
extern(C):

version(LDC) version = CRT;
version(D_BetterC) version = CRT;

version(CRT)
{
    pragma(crt_constructor)
    void crt_mir_cpuid_init()
    {
        mir_cpuid_init();
    }
}
else
{
    shared static this()
    {
        mir_cpuid_init();
    }
}

/++
Initialize basic CPU information including basic architecture.
It is safe to call this function multiple times.
It calls appropriate basic initialization for each module (`cpuid_x86_any_init` for X86 machines).
+/
version(X86_Any)
void mir_cpuid_init()
{
    static if (__VERSION__ >= 2068)
        pragma(inline, false);

    import cpuid.x86_any;

    mir_cpuid_x86_any_init();

    static import cpuid.intel;
    static import cpuid.amd;

    if(htt)
    {
        /// for old CPUs
        _threads._mut = _cores._mut = maxLogicalProcessors;
    }
    if (vendorIndex == VendorIndex.amd || 
        vendorIndex == VendorIndex.amd_old || 
        vendorIndex == VendorIndex.centaur)
    {
        // Caches and TLB
        if(maxExtendedLeaf >= 0x8000_0005)
        {
            // Level 1
            auto leafExt5 = cpuid.amd.LeafExt5Information(_cpuid(0x8000_0005));

            alias CacheAssoc = typeof(Cache.associative);
            alias TlbAssoc = typeof(Tlb.associative);

             if(leafExt5.L1DTlb4KSize)
             {
                _dTlb._mut[0].page = 4;
                _dTlb._mut[0].entries = leafExt5.L1DTlb4KSize;
                _dTlb._mut[0].associative = leafExt5.L1DTlb4KAssoc.assocCopy!TlbAssoc;
                _dTlb_length._mut = 1;
             }
             if(leafExt5.L1ITlb4KSize)
             {
                _iTlb._mut[0].page = 4;
                _iTlb._mut[0].entries = leafExt5.L1ITlb4KSize;
                _iTlb._mut[0].associative = leafExt5.L1ITlb4KAssoc.assocCopy!TlbAssoc;
                _iTlb_length._mut = 1;
            }
            if(leafExt5.L1DcSize)
            {
                _dCache_length._mut = 1;
                _dCache._mut[0].size = leafExt5.L1DcSize;
                _dCache._mut[0].line = leafExt5.L1DcLineSize;
                _dCache._mut[0].associative = leafExt5.L1DcAssoc.assocCopy!CacheAssoc;
            }
            if(leafExt5.L1IcSize)
            {
                _iCache_length._mut = 1;
                _iCache._mut[0].size = leafExt5.L1IcSize;
                _iCache._mut[0].line = leafExt5.L1IcLineSize;
                _iCache._mut[0].associative = leafExt5.L1IcAssoc.assocCopy!CacheAssoc;
            }

            // Levels 2 and 3
            if(maxExtendedLeaf >= 0x8000_0006)
            {
                import cpuid.amd: decodeL2or3Assoc;
                auto leafExt6 = cpuid.amd.LeafExt6Information(_cpuid(0x8000_0006));

                if(leafExt6.L2DTlb4KSize)
                {
                    _dTlb._mut[_dTlb_length].page = 4;
                    _dTlb._mut[_dTlb_length].entries = leafExt6.L2DTlb4KSize;
                    _dTlb._mut[_dTlb_length].associative = leafExt6.L2DTlb4KAssoc.decodeL2or3Assoc!TlbAssoc;
                    _dTlb_length._mut++;
                }
                if(leafExt6.L2ITlb4KSize)
                {
                    _iTlb._mut[_iTlb_length].page = 4;
                    _iTlb._mut[_iTlb_length].entries = leafExt6.L2ITlb4KSize;
                    _iTlb._mut[_iTlb_length].associative = leafExt6.L2ITlb4KAssoc.decodeL2or3Assoc!TlbAssoc;
                    _iTlb_length._mut++;
                }
                if(leafExt6.L2Size)
                {
                    _uCache._mut[_uCache_length].size = leafExt6.L2Size;
                    _uCache._mut[_uCache_length].line = cast(typeof(Cache.line)) leafExt6.L2LineSize;
                    _uCache._mut[_uCache_length].associative = leafExt6.L2Assoc.decodeL2or3Assoc!CacheAssoc;
                    _uCache_length._mut++;
                }
                if(leafExt6.L3Size)
                {
                    _uCache._mut[_uCache_length].size = leafExt6.L3Size * 512;
                    _uCache._mut[_uCache_length].line = cast(typeof(Cache.line)) leafExt6.L3LineSize;
                    _uCache._mut[_uCache_length].associative = leafExt6.L3Assoc.decodeL2or3Assoc!CacheAssoc;
                    _uCache_length._mut++;
                }
            }
        }
    }
    else
    {
        /// Other vendors
        if(maxBasicLeaf >= 0x2)
        {
            /// Get TLB and Cache info
            auto leaf2 = cpuid.intel.Leaf2Information(_cpuid(2));

            /// Fill cache info
            if(leaf2.dtlb.size)
            {
                _dTlb._mut[0] = leaf2.dtlb;
                _dTlb_length._mut = 1;
            }
            if(leaf2.dtlb1.size)
            {
                _dTlb._mut[_dTlb_length] = leaf2.dtlb1;
                _dTlb_length._mut++;
            }
            if(leaf2.itlb.size)
            {
                _iTlb._mut[0] = leaf2.itlb;
                _iTlb_length._mut = 1;
            }
            if(leaf2.utlb.size)
            {
                _uTlb._mut[0] = leaf2.utlb;
                _uTlb_length._mut = 1;
            }

            if(maxBasicLeaf >= 0x4)
            {
                /// Fill cache info from leaf 4
                cpuid.intel.Leaf4Information leaf4 = void;
                Cache cache;
                Leaf4Loop: foreach(uint ecx; 0 .. 12)
                {
                    leaf4.info = _cpuid(4, ecx);
                    leaf4.fill(cache);

                    with(cpuid.intel.Leaf4Information.Type)
                    switch(leaf4.type)
                    {
                        case data:
                            if(_dCache_length < _dCache.length)
                                _dCache._mut[_dCache_length._mut++] = cache;
                            break;
                        case instruction:
                            if(_iCache_length < _iCache.length)
                                _iCache._mut[_iCache_length._mut++] = cache;
                            break;
                        case unified:
                            if(_uCache_length < _uCache.length)
                                _uCache._mut[_uCache_length._mut++] = cache;
                            break;
                        default: break Leaf4Loop;
                    }
                    /// Fill core number for old CPUs
                    _cores._mut = leaf4.maxCorePerCPU;
                }
                if(maxBasicLeaf >= 0xB)
                {
                    auto th = cast(ushort) _cpuid(0xB, 1).b;
                    if(th > 0)
                        _threads._mut = th;
                    auto threadsPerCore = cast(ushort) _cpuid(0xB, 0).b;
                    if(threadsPerCore)
                    {
                        _cores._mut = _threads / threadsPerCore;
                    }
                }
            }
            else
            {
                /// Fill cache info from leaf 2
                if(leaf2.l1.size)
                {
                    _dCache._mut[0] = leaf2.l1;
                    _dCache_length._mut = 1;
                }
                if(leaf2.il1.size)
                {
                    _iCache._mut[0] = leaf2.il1;
                    _iCache_length._mut = 1;
                }
                if(leaf2.l2.size)
                {
                    _uCache._mut[0] = leaf2.l2;
                    _uCache_length._mut = 1;
                }
                if(leaf2.l3.size)
                {
                    _uCache._mut[_uCache_length] = leaf2.l3;
                    _uCache_length._mut++;
                }
            }
        }
    }

    if(!_cpus) _cpus._mut = 1;
    if(!_cores) _cores._mut = 1;
    if(!_threads) _threads._mut = 1;
    if(_threads < _cores) _threads._mut = _cores;

    if(_iCache_length) _iCache._mut[0].cores = 1;
    if(_dCache_length) _dCache._mut[0].cores = 1;
    switch(_uCache_length)
    {
        case 0:
            break;
        case 1:
            _uCache._mut[0].cores = cast(typeof(Cache.cores)) _cores;
            break;
        default:
            _uCache._mut[0].cores = 1;
            foreach(i; 1.._uCache_length)
                _uCache._mut[i].cores = cast(typeof(Cache.cores)) _cores;
    }
}
else
void mir_cpuid_init()
{
    _cpus._mut = 1;
    _cores._mut = 1;
    _threads._mut = 1;
}
/// ditto

alias cpuid_init = mir_cpuid_init;

pure @trusted:

/++
Total number of CPU packages.
Note: not implemented
+/
uint mir_cpuid_cpus() { return _cpus; }
/// ditto
alias cpus = mir_cpuid_cpus;

/++
Total number of cores per CPU.
+/
uint mir_cpuid_cores() { return _cores; }
/// ditto
alias cores = mir_cpuid_cores;

/++
Total number of threads per CPU.
+/
uint mir_cpuid_threads() { return _threads; }
/// ditto
alias threads = mir_cpuid_threads;

/++
Data Caches

Returns:
    Array composed of detected data caches. Array is sorted in ascending order.
+/
immutable(Cache)[] mir_cpuid_dCache() { return _dCache[0 .. _dCache_length]; }
/// ditto
alias dCache = mir_cpuid_dCache;

/++
Instruction Caches

Returns:
    Array composed of detected instruction caches. Array is sorted in ascending order.
+/
immutable(Cache)[] mir_cpuid_iCache() { return _iCache[0 .. _iCache_length]; }
/// ditto
alias iCache = mir_cpuid_iCache;

/++
Unified Caches

Returns:
    Array composed of detected unified caches. Array is sorted in ascending order.
+/
immutable(Cache)[] mir_cpuid_uCache() { return _uCache[0 .. _uCache_length]; }
/// ditto
alias uCache = mir_cpuid_uCache;

/++
Data Translation Lookaside Buffers

Returns:
    Array composed of detected data translation lookaside buffers. Array is sorted in ascending order.
+/
immutable(Tlb)[] mir_cpuid_dTlb() { return _dTlb[0 .. _dTlb_length]; }
/// ditto
alias dTlb = mir_cpuid_dTlb;

/++
Instruction Translation Lookaside Buffers

Returns:
    Array composed of detected instruction translation lookaside buffers. Array is sorted in ascending order.
+/
immutable(Tlb)[] mir_cpuid_iTlb() { return _iTlb[0 .. _iTlb_length]; }
/// ditto
alias iTlb = mir_cpuid_iTlb;

/++
Unified Translation Lookaside Buffers

Returns:
    Array composed of detected unified translation lookaside buffers. Array is sorted in ascending order.
+/
immutable(Tlb)[] mir_cpuid_uTlb() { return _uTlb[0 .. _uTlb_length]; }
/// ditto
alias uTlb = mir_cpuid_uTlb;
