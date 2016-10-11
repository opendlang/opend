/++
$(H2 High level absraction on top of all architectures.)

$(GREEN This module is available for betterC compilation mode.)


License:   $(WEB www.boost.org/LICENSE_1_0.txt, Boost License 1.0).

Authors:   Ilya Yaroshenko
+/
module cpuid.unified;

///
unittest
{
    void smallReport()
    {
        import std.stdio;
        import cpuid.unified;

        cpuid_init();

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

version(LDC)
{
    version(unittest) {} else
    {
        pragma(LDC_no_moduleinfo);
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
    uint _cpus;
    uint _cores;
    uint _threads;
    uint _iCache_length; Cache[_iCache_max_length] _iCache;
    uint _dCache_length; Cache[_dCache_max_length] _dCache;
    uint _uCache_length; Cache[_uCache_max_length] _uCache;
    uint _iTlb_length;   Tlb[_iTlb_max_length] _iTlb;
    uint _dTlb_length;   Tlb[_dTlb_max_length] _dTlb;
    uint _uTlb_length;   Tlb[_uTlb_max_length] _uTlb;
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

/++
Initialize basic CPU information including basic architecture.
It is safe to call this function multiple times.
It calls appropriate basic initialization for each module (`cpuid_x86_any_init` for X86 machines).
+/
version(X86_Any)
nothrow @nogc
extern(C)
void cpuid_init()
{
    static if (__VERSION__ >= 2068)
        pragma(inline, false);

    import cpuid.x86_any;

    cpuid_x86_any_init();

    static import cpuid.intel;
    static import cpuid.amd;

    if(htt)
    {
        /// for old CPUs
        _threads = _cores = maxLogicalProcessors;
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
                _dTlb[0].page = 4;
                _dTlb[0].entries = leafExt5.L1DTlb4KSize;
                _dTlb[0].associative = leafExt5.L1DTlb4KAssoc.assocCopy!TlbAssoc;
                _dTlb_length = 1;
             }
             if(leafExt5.L1ITlb4KSize)
             {
                _iTlb[0].page = 4;
                _iTlb[0].entries = leafExt5.L1ITlb4KSize;
                _iTlb[0].associative = leafExt5.L1ITlb4KAssoc.assocCopy!TlbAssoc;
                _iTlb_length = 1;
            }
            if(leafExt5.L1DcSize)
            {
                _dCache_length = 1;
                _dCache[0].size = leafExt5.L1DcSize;
                _dCache[0].line = leafExt5.L1DcLineSize;
                _dCache[0].associative = leafExt5.L1DcAssoc.assocCopy!CacheAssoc;
            }
            if(leafExt5.L1IcSize)
            {
                _iCache_length = 1;
                _iCache[0].size = leafExt5.L1IcSize;
                _iCache[0].line = leafExt5.L1IcLineSize;
                _iCache[0].associative = leafExt5.L1IcAssoc.assocCopy!CacheAssoc;
            }

            // Levels 2 and 3
            if(maxExtendedLeaf >= 0x8000_0006)
            {
                import cpuid.amd: decodeL2or3Assoc;
                auto leafExt6 = cpuid.amd.LeafExt6Information(_cpuid(0x8000_0006));

                if(leafExt6.L2DTlb4KSize)
                {
                    _dTlb[_dTlb_length].page = 4;
                    _dTlb[_dTlb_length].entries = leafExt6.L2DTlb4KSize;
                    _dTlb[_dTlb_length].associative = leafExt6.L2DTlb4KAssoc.decodeL2or3Assoc!TlbAssoc;
                    _dTlb_length++;
                }
                if(leafExt6.L2ITlb4KSize)
                {
                    _iTlb[_iTlb_length].page = 4;
                    _iTlb[_iTlb_length].entries = leafExt6.L2ITlb4KSize;
                    _iTlb[_iTlb_length].associative = leafExt6.L2ITlb4KAssoc.decodeL2or3Assoc!TlbAssoc;
                    _iTlb_length++;
                }
                if(leafExt6.L2Size)
                {
                    _uCache[_uCache_length].size = leafExt6.L2Size;
                    _uCache[_uCache_length].line = cast(typeof(Cache.line)) leafExt6.L2LineSize;
                    _uCache[_uCache_length].associative = leafExt6.L2Assoc.decodeL2or3Assoc!CacheAssoc;
                    _uCache_length++;
                }
                if(leafExt6.L3Size)
                {
                    _uCache[_uCache_length].size = leafExt6.L3Size * 512;
                    _uCache[_uCache_length].line = cast(typeof(Cache.line)) leafExt6.L3LineSize;
                    _uCache[_uCache_length].associative = leafExt6.L3Assoc.decodeL2or3Assoc!CacheAssoc;
                    _uCache_length++;
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
                _dTlb[0] = leaf2.dtlb;
                _dTlb_length = 1;
            }
            if(leaf2.dtlb1.size)
            {
                _dTlb[_dTlb_length] = leaf2.dtlb1;
                _dTlb_length++;
            }
            if(leaf2.itlb.size)
            {
                _iTlb[0] = leaf2.itlb;
                _iTlb_length = 1;
            }
            if(leaf2.utlb.size)
            {
                _uTlb[0] = leaf2.utlb;
                _uTlb_length = 1;
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
                                _dCache[_dCache_length++] = cache;
                            break;
                        case instruction:
                            if(_iCache_length < _iCache.length)
                                _iCache[_iCache_length++] = cache;
                            break;
                        case unified:
                            if(_uCache_length < _uCache.length)
                                _uCache[_uCache_length++] = cache;
                            break;
                        default: break Leaf4Loop;
                    }
                    /// Fill core number for old CPUs
                    _cores = leaf4.maxCorePerCPU;
                }
                if(maxBasicLeaf >= 0xB)
                {
                    _threads = cast(ushort) _cpuid(0xB, 1).b;
                    auto threadsPerCore = cast(ushort) _cpuid(0xB, 0).b;
                    if(_threads == 0 || threadsPerCore == 0) // appveyor workaround
                    {
                        _threads = 1;
                        threadsPerCore = 1;
                    }
                    _cores = _threads / threadsPerCore;
                }
            }
            else
            {
                /// Fill cache info from leaf 2
                if(leaf2.l1.size)
                {
                    _dCache[0] = leaf2.l1;
                    _dCache_length = 1;
                }
                if(leaf2.il1.size)
                {
                    _iCache[0] = leaf2.il1;
                    _iCache_length = 1;
                }
                if(leaf2.l2.size)
                {
                    _uCache[0] = leaf2.l2;
                    _uCache_length = 1;
                }
                if(leaf2.l3.size)
                {
                    _uCache[_uCache_length] = leaf2.l3;
                    _uCache_length++;
                }
            }
        }
    }

    if(!_cpus) _cpus = 1;
    if(!_cores) _cores = 1;
    if(!_threads) _threads = 1;
    if(_threads < _cores) _threads = _cores;

    if(_iCache_length) _iCache[0].cores = 1;
    if(_dCache_length) _dCache[0].cores = 1;
    switch(_uCache_length)
    {
        case 0:
            break;
        case 1:
            _uCache[0].cores = cast(typeof(Cache.cores)) _cores;
            break;
        default:
            _uCache[0].cores = 1;
            foreach(i; 1.._uCache_length)
                _uCache[i].cores = cast(typeof(Cache.cores)) _cores;
    }
}
else
static assert(0, "cpuid_init is not implemented for this target.");

@trusted nothrow @nogc:

/++
Total number of CPU packages.
Note: not implemented
+/

uint cpus() { return _cpus; }

/++
Total number of cores per CPU.
+/
uint cores() { return _cores; }

/++
Total number of threads per CPU.
+/
uint threads() { return _threads; }

/++
Data Caches

Returns:
    Array composed of detected data caches. Array is sorted in ascending order.
+/
const(Cache)[] dCache() { return _dCache[0 .. _dCache_length]; }

/++
Instruction Caches

Returns:
    Array composed of detected instruction caches. Array is sorted in ascending order.
+/
const(Cache)[] iCache() { return _iCache[0 .. _iCache_length]; }

/++
Unified Caches

Returns:
    Array composed of detected unified caches. Array is sorted in ascending order.
+/
const(Cache)[] uCache() { return _uCache[0 .. _uCache_length]; }

/++
Data Translation Lookaside Buffers

Returns:
    Array composed of detected data translation lookaside buffers. Array is sorted in ascending order.
+/
const(Tlb)[] dTlb() { return _dTlb[0 .. _dTlb_length]; }

/++
Instruction Translation Lookaside Buffers

Returns:
    Array composed of detected instruction translation lookaside buffers. Array is sorted in ascending order.
+/
const(Tlb)[] iTlb() { return _iTlb[0 .. _iTlb_length]; }

/++
Unified Translation Lookaside Buffers

Returns:
    Array composed of detected unified translation lookaside buffers. Array is sorted in ascending order.
+/
const(Tlb)[] uTlb() { return _uTlb[0 .. _uTlb_length]; }

