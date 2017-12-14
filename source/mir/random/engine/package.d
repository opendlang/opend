/++
$(SCRIPT inhibitQuickIndex = 1;)
Uniform random engines.

$(B Sections:)
        $(LINK2 #Convenience, Convenience)
&#8226; $(LINK2 #Entropy, Entropy)
&#8226; $(LINK2 #Traits, Traits)
&#8226; $(LINK2 #CInterface, C Interface)

$(BOOKTABLE

$(LEADINGROW <a id="Convenience"></a>Convenience)
$(TR
    $(RROW Random, Default random number _engine))
    $(RROW rne, Per-thread uniquely-seeded instance of default `Random`. Requires $(LINK2 https://en.wikipedia.org/wiki/Thread-local_storage, TLS).)
    $(TR $(TDNW $(LREF threadLocal)`!(Engine)`) $(TD Per-thread uniquely-seeded instance of of any specified `Engine`. Requires $(LINK2 https://en.wikipedia.org/wiki/Thread-local_storage, TLS).))

$(LEADINGROW <a id="Entropy"></a>Entropy)
$(TR
    $(RROW unpredictableSeed, Seed of `size_t` using system entropy)
    $(RROW unpredictableSeedOf, Generalization of `unpredictableSeed` for unsigned integers of different sizes)
    $(RROW genRandomNonBlocking, Fills a buffer with system entropy, returning number of bytes copied or negative number on error)
    $(RROW genRandomBlocking, Fills a buffer with system entropy, possibly waiting if the system believes it has insufficient entropy. Returns 0 on success.))

$(LEADINGROW <a id="Traits"></a>Traits)
$(TR
    $(RROW isRandomEngine, Check if is random number _engine)
    $(RROW EngineReturnType, Get return type of random number _engine's `opCall()`)
    $(RROW isSaturatedRandomEngine, Check if random number _engine `G` such that `G.max == EngineReturnType!(G).max`)
    $(RROW preferHighBits, Are the high bits of the _engine's output known to have better statistical properties than the low bits?))

$(LEADINGROW <a id="CInterface"></a>C Interface)
    $(RROW mir_random_engine_ctor, Perform any necessary setup. Automatically called by DRuntime.)
    $(RROW mir_random_engine_dtor, Release any resources. Automatically called by DRuntime.)
    $(RROW mir_random_genRandomNonBlocking, External name for $(LREF genRandomNonBlocking))
    $(RROW mir_random_genRandomBlocking, External name for $(LREF genRandomBlocking))
)

Copyright: Ilya Yaroshenko 2016-.
License:  $(HTTP www.boost.org/LICENSE_1_0.txt, Boost License 1.0).
Authors: Ilya Yaroshenko

Macros:
    T2=$(TR $(TDNW $(LREF $1)) $(TD $+))
    RROW = $(TR $(TDNW $(LREF $1)) $(TD $+))
+/
module mir.random.engine;

version (OSX)
    version = Darwin;
else version (iOS)
    version = Darwin;
else version (TVOS)
    version = Darwin;
else version (WatchOS)
    version = Darwin;

version (Darwin)
    version = GOOD_ARC4RANDOM_BUF;//AES
version (OpenBSD)
    version = GOOD_ARC4RANDOM_BUF;//ChaCha20
version (NetBSD)
    version = GOOD_ARC4RANDOM_BUF;//ChaCha20

version (D_betterC)
    private enum bool THREAD_LOCAL_STORAGE_AVAILABLE = false;
else
    private enum bool THREAD_LOCAL_STORAGE_AVAILABLE = __traits(compiles, { static size_t x = 0; });

import std.traits;

import mir.random.engine.mersenne_twister;

/++
Like `std.traits.ReturnType!T` but it works even if
T.opCall is a function template.
+/
template EngineReturnType(T)
{
    import std.traits : ReturnType;
    static if (is(ReturnType!T))
        alias EngineReturnType = ReturnType!T;
    else
        alias EngineReturnType = typeof(T.init());
}

/++
Test if T is a random engine.
A type should define `enum isRandomEngine = true;` to be a random engine.
+/
template isRandomEngine(T)
{
    static if (is(typeof(T.isRandomEngine) : bool) && is(typeof(T.init())))
    {
        private alias R = typeof(T.init());
        static if (T.isRandomEngine && isUnsigned!R)
            enum isRandomEngine = is(typeof({
                enum max = T.max;
                static assert(is(typeof(T.max) == R));
                }));
        else enum isRandomEngine = false;
    }
    else enum isRandomEngine = false;
}

/++
Test if T is a saturated random-bit generator.
A random number generator is saturated if `T.max == ReturnType!T.max`.
A type should define `enum isRandomEngine = true;` to be a random engine.
+/
template isSaturatedRandomEngine(T)
{
    static if (isRandomEngine!T)
        enum isSaturatedRandomEngine = T.max == EngineReturnType!T.max;
    else
        enum isSaturatedRandomEngine = false;
}

/++
Are the high bits of the engine's output known to have
better statistical properties than the low bits of the
output? This property is set by checking the value of
an optional enum named `preferHighBits`. If the property
is missing it is treated as false.

This should be specified as true for:
<ul>
<li>linear congruential generators with power-of-2 modulus</li>
<li>xorshift+ family</li>
<li>xorshift* family</li>
<li>in principle any generator whose final operation is something like
multiplication or addition in which the high bits depend on the low bits
but the low bits are unaffected by the high bits.</li>
</ul>
+/
template preferHighBits(G)
    if (isSaturatedRandomEngine!G)
{
    static if (__traits(compiles, { enum bool e = G.preferHighBits; }))
        private enum bool preferHighBits = G.preferHighBits;
    else
        private enum bool preferHighBits = false;
}

/*
 * Marker indicating it's safe to construct from void
 * (i.e. the constructor doesn't depend on the struct
 * being in an initially valid state).
 * Either checks an explicit flag `_isVoidInitOkay`
 * or tests to make sure that the structure contains
 * nothing that looks like a pointer or an index into
 * an array. Also ensures that there is not an elaborate
 * destructor since it could be called when the struct
 * is in an invalid state.
 * Non-public because we don't want to commit to this
 * design.
 */
package template _isVoidInitOkay(G) if (isRandomEngine!G && is(G == struct))
{
    static if (is(typeof(G._isVoidInitOkay) : bool))
        enum bool _isVoidInitOkay = G._isVoidInitOkay;
    else static if (!hasNested!G && !hasElaborateDestructor!G)
    {
        import std.meta : allSatisfy;
        static if (allSatisfy!(isScalarType, FieldTypeTuple!G))
            //All members are scalars.
            enum bool _isVoidInitOkay = true;
        else static if (FieldTypeTuple!(G).length == 1 && isStaticArray!(FieldTypeTuple!(G)[0]))
            //Only has one member which is a static array of scalars.
            enum bool _isVoidInitOkay = isScalarType!(typeof(FieldTypeTuple!(G)[0].init[0]));
        else
            enum bool _isVoidInitOkay = false;
    }
    else
        enum bool _isVoidInitOkay = false;
}
@nogc nothrow pure @safe version(mir_random_test)
{
    import mir.random.engine.mersenne_twister: Mt19937, Mt19937_64;
    //Ensure that this property is set for the Mersenne Twister,
    //whose internal state is huge enough for this to potentially
    //matter:
    static assert(_isVoidInitOkay!Mt19937);
    static assert(_isVoidInitOkay!Mt19937_64);
    //Check that the property is set for a moderately-sized PRNG.
    import mir.random.engine.xorshift: Xorshift1024StarPhi;
    static assert(_isVoidInitOkay!Xorshift1024StarPhi);
    //Check that PRNGs not explicitly marked as void-init safe
    //can be inferred as such if they only have scalar fields.
    import mir.random.engine.pcg: pcg32, pcg32_oneseq;
    import mir.random.engine.splitmix: SplitMix64;
    static assert(_isVoidInitOkay!pcg32);
    static assert(_isVoidInitOkay!pcg32_oneseq);
    static assert(_isVoidInitOkay!SplitMix64);
    //Check that PRNGs not explicitly marked as void-init safe
    //can be inferred as such if their only field is a static
    //array of scalars.
    import mir.random.engine.xorshift: Xorshift128, Xoroshiro128Plus;
    static assert(_isVoidInitOkay!Xorshift128);
    static assert(_isVoidInitOkay!Xoroshiro128Plus);
}

version (D_Ddoc)
{
    /++
    A "good" seed for initializing random number engines. Initializing
    with $(D_PARAM unpredictableSeed) makes engines generate different
    random number sequences every run.

    Returns:
    A single unsigned integer seed value, different on each successive call
    +/
    pragma(inline, true)
    @property size_t unpredictableSeed() @trusted nothrow @nogc
    {
        return unpredictableSeedOf!size_t;
    }
}
else
{
    //If D_Doc saw this it would produce incorrect documentation:
    //instead of "size_t" it would say either "uint" or "ulong"
    //depending on the machine generating the documentation (!!!)
    public alias unpredictableSeed = unpredictableSeedOf!size_t;
}

/// ditto
pragma(inline, true)
@property T unpredictableSeedOf(T)() @trusted nothrow @nogc
    if (isUnsigned!T && T.sizeof >= uint.sizeof)
{
    T seed = void;
    version (GOOD_ARC4RANDOM_BUF)
    {
        arc4random_buf(&seed, seed.sizeof);
    }
    // fallback to old time/thread-based implementation in case of errors
    else if (genRandomBlocking(&seed, seed.sizeof) < 0)
    {
        version(Windows)
        {
            import core.sys.windows.winbase : QueryPerformanceCounter;
            ulong ticks = void;
            QueryPerformanceCounter(cast(long*)&ticks);
        }
        else
        version(Darwin)
        {
            import core.time : mach_absolute_time;
            ulong ticks = mach_absolute_time();
        }
        else
        version(Posix)
        {
            import core.sys.posix.time : clock_gettime, CLOCK_MONOTONIC, timespec;
            timespec ts;
            if(clock_gettime(CLOCK_MONOTONIC, &ts) != 0)
            {
                import core.internal.abort : abort;
                abort("Call to clock_gettime failed.");
            }
            ulong ticks = (cast(ulong) ts.tv_sec << 32) ^ ts.tv_nsec;
        }
        version(Posix)
        {
            import core.sys.posix.unistd : getpid;
            import core.sys.posix.pthread : pthread_self;
            auto pid = cast(uint) getpid;
            auto tid = cast(uint) pthread_self();
        }
        else
        version(Windows)
        {
            import core.sys.windows.winbase : GetCurrentProcessId, GetCurrentThreadId;
            auto pid = cast(uint) GetCurrentProcessId;
            auto tid = cast(uint) GetCurrentThreadId;
        }
        ulong k = ((cast(ulong)pid << 32) ^ tid) + ticks;
        k ^= k >> 33;
        k *= 0xff51afd7ed558ccd;
        k ^= k >> 33;
        k *= 0xc4ceb9fe1a85ec53;
        k ^= k >> 33;
        seed = cast(T)k;
    }
    return seed;
}

/// ditto
pragma(inline, true)
@property T unpredictableSeedOf(T)() @safe nothrow @nogc
    if (isUnsigned!T && T.sizeof < uint.sizeof)
{
    return cast(T) unpredictableSeedOf!uint;
}

///
@safe version(mir_random_test) unittest
{
    auto rnd = Random(unpredictableSeed);
    auto n = rnd();
    static assert(is(typeof(n) == size_t));
}

/++
The "default", "favorite", "suggested" random number generator type on
the current platform. It is an alias for one of the
generators. You may want to use it if (1) you need to generate some
nice random numbers, and (2) you don't care for the minutiae of the
method being used.
+/
static if (is(size_t == uint))
    alias Random = Mt19937;
else
    alias Random = Mt19937_64;

///
version(mir_random_test) unittest
{
    import std.traits;
    static assert(isSaturatedRandomEngine!Random);
    static assert(is(EngineReturnType!Random == size_t));
}

static if (THREAD_LOCAL_STORAGE_AVAILABLE)
{
    /++
    Thread-local instance of the default $(LREF Random) allocated and seeded independently
    for each thread. Requires $(LINK2 https://en.wikipedia.org/wiki/Thread-local_storage, TLS).
    +/
    alias rne = threadLocal!Random;
    ///
    @nogc nothrow @safe version(mir_random_test) unittest
    {
        import mir.random;
        import std.complex;

        auto c = complex(rne.rand!real, rne.rand!real);

        int[10] array;
        foreach (ref e; array)
            e = rne.rand!int;
        auto picked = array[rne.randIndex(array.length)];
    }

    private static struct TL(Engine)
        if (isSaturatedRandomEngine!Engine && is(Engine == struct))
    {
        static bool initialized;
        static if (_isVoidInitOkay!Engine)
            static Engine engine = void;
        else static if (__traits(compiles, { Engine defaultConstructed; }))
            static Engine engine;
        else
            static Engine engine = Engine.init;
    }
    /++
    Thread-local instance of the specified random number generator allocated and seeded uniquely
    for each thread. Requires $(LINK2 https://en.wikipedia.org/wiki/Thread-local_storage, TLS).

    `threadLocalPtr!Engine` is a pointer to the area of thread-local
    storage used by `threadLocal!Engine`. This function is provided because
    the compiler can infer it is `@safe`, unlike `&(threadLocal!Engine)`.
    Like `threadLocal!Engine` this function will auto-initialize the engine.

    `threadLocalInitialized!Engine` is a low-level way to explicitly change
    the "initialized" flag used by `threadLocal!Engine` to determine whether
    the Engine needs to be seeded. Setting this to `false` gives a way of
    forcing the next call to `threadLocal!Engine` to reseed. In general this
    is unnecessary but there are some specialized use cases where users have
    requested this ability.
    +/
    @property ref Engine threadLocal(Engine)()
        if (isSaturatedRandomEngine!Engine && is(Engine == struct))
    {
        version (DigitalMars)
            pragma(inline);//DMD may fail to inline this.
        else
            pragma(inline, true);
        return *threadLocalPtr!Engine;
    }
    /// ditto
    @property Engine* threadLocalPtr(Engine)()
        if (isSaturatedRandomEngine!Engine && is(Engine == struct))
    {
        version (DigitalMars)
            pragma(inline);//DMD may fail to inline this.
        else
            pragma(inline, true);
        import mir.ndslice.internal: _expect;
        if (_expect(!TL!Engine.initialized, false))
        {
            static if (is(typeof((ulong t) => Engine(t))))
                alias seed_t = ulong;
            else static if (is(typeof((uint t) => Engine(t))))
                alias seed_t = uint;
            else
                alias seed_t = EngineReturnType!Engine;
            static if (seed_t.sizeof <= uint.sizeof)
                seed_t seed = cast(seed_t) unpredictableSeedOf!uint;
            else
                seed_t seed = unpredictableSeedOf!seed_t;
            TL!Engine.engine.__ctor(seed);
        }
        return &(TL!Engine.engine);
    }
    /// ditto
    @property ref bool threadLocalInitialized(Engine)()
        if (isSaturatedRandomEngine!Engine && is(Engine == struct))
    {
        version (DigitalMars)
            pragma(inline);//DMD may fail to inline this.
        else
            pragma(inline, true);
        return TL!Engine.initialized;
    }
    ///
    @nogc nothrow @safe version(mir_random_test) unittest
    {
        import mir.random;
        import mir.random.engine.xorshift;

        alias gen = threadLocal!Xorshift1024StarPhi;
        double x = gen.rand!double;
        size_t i = gen.randIndex(100u);
        ulong a = gen.rand!ulong;
    }
    ///
    @nogc nothrow @safe version(mir_random_test) unittest
    {
        import mir.random;
        //If you need a pointer to the engine, getting it like this is @safe:
        Random* ptr = threadLocalPtr!Random;
    }
    ///
    @nogc nothrow @safe version(mir_random_test) unittest
    {
        import mir.random;
        import mir.random.engine.xorshift;
        //If you need to mark the engine as uninitialized to force a reseed,
        //you can do it like this:
        threadLocalInitialized!Xorshift1024StarPhi = false;
    }
    ///
    @nogc nothrow @safe version(mir_random_test) unittest
    {
        import mir.random;
        import mir.random.engine.mersenne_twister;
        //You can mark the engine as already initialized to skip
        //automatic seeding then initialize it yourself, for instance
        //if you want to use a known seed rather than a random one.
        threadLocalInitialized!Mt19937 = true;
        immutable uint[4] customSeed = [0x123, 0x234, 0x345, 0x456];
        threadLocal!Mt19937.__ctor(customSeed);
        foreach(_; 0..999)
            threadLocal!Mt19937.rand!uint;
        assert(3460025646u == threadLocal!Mt19937.rand!uint);
    }
    ///
    @nogc nothrow @safe version(mir_random_test) unittest
    {
        import mir.random;
        import mir.random.engine.xorshift;

        alias gen = threadLocal!Xorshift1024StarPhi;

        //If you want to you can call the generator's opCall instead of using
        //rand!T but it is somewhat clunky because of the ambiguity of
        //@property syntax: () looks like optional function parentheses.
        static assert(!__traits(compiles, {ulong x0 = gen();}));//<-- Won't work
        static assert(is(typeof(gen()) == Xorshift1024StarPhi));//<-- because the type is this.
        ulong x1 = gen.opCall();//<-- This works though.
        ulong x2 = gen()();//<-- This also works.

        //But instead of any of those you should really just use gen.rand!T.
        ulong x3 = gen.rand!ulong;
    }
//    ///
//    @nogc nothrow pure @safe version(mir_random_test) unittest
//    {
//        //If you want something like Phobos std.random.rndGen and
//        //don't care about the specific algorithm you can do this:
//        alias rndGen = threadLocal!Random;
//    }

    @nogc nothrow @system version(mir_random_test) unittest
    {
        //Verify Returns same instance every time per thread.
        import mir.random;
        import mir.random.engine.xorshift;

        Xorshift1024StarPhi* addr = &(threadLocal!Xorshift1024StarPhi());
        Xorshift1024StarPhi* sameAddr = &(threadLocal!Xorshift1024StarPhi());
        assert(addr is sameAddr);
        assert(sameAddr is threadLocalPtr!Xorshift1024StarPhi);
    }

}
else
{
    static assert(!THREAD_LOCAL_STORAGE_AVAILABLE);

    @property ref Random rne()()
    {
        static assert(0, "Thread-local storage not available!");
    }

    template threadLocal(T)
    {
        static assert(0, "Thread-local storage not available!");
    }

    template threadLocalPtr(T)
    {
        static assert(0, "Thread-local storage not available!");
    }

    template threadLocalInitialized(T)
    {
        static assert(0, "Thread-local storage not available!");
    }
}

version(linux)
{
    import mir.linux._asm.unistd;
    enum bool LINUX_NR_GETRANDOM = (__traits(compiles, {enum e = NR_getrandom;}));
    //If X86_64 or X86 are missing there is a problem with the library.
    static if (!LINUX_NR_GETRANDOM)
    {
        version (X86_64)
            static assert(0, "Missing linux syscall constants!");
        version (X86)
            static assert(0, "Missing linux syscall constants!");
    }
}
else
    enum bool LINUX_NR_GETRANDOM = false;

static if (LINUX_NR_GETRANDOM)
{
    private enum GET_RANDOM {
        UNINITIALIZED,
        NOT_AVAILABLE,
        AVAILABLE,
    }

    // getrandom was introduced in Linux 3.17
    private __gshared GET_RANDOM hasGetRandom = GET_RANDOM.UNINITIALIZED;

    import core.sys.posix.sys.utsname : utsname;

    // druntime isn't properly annotated
    private extern(C) int uname(utsname* __name) @nogc nothrow;

    // checks whether the Linux kernel supports getRandom by looking at the
    // reported version
    private auto initHasGetRandom()() @nogc @trusted nothrow
    {
        import core.stdc.string : strtok;
        import core.stdc.stdlib : atoi;

        utsname uts;
        uname(&uts);
        char* p = uts.release.ptr;

        // poor man's version check
        auto token = strtok(p, ".");
        int major = atoi(token);
        if (major  > 3)
            return true;

        if (major == 3)
        {
            token = strtok(p, ".");
            if (atoi(token) >= 17)
                return true;
        }

        return false;
    }

    private extern(C) int syscall(size_t ident, size_t n, size_t arg1, size_t arg2) @nogc nothrow;

    /*
     * Flags for getrandom(2)
     *
     * GRND_NONBLOCK    Don't block and return EAGAIN instead
     * GRND_RANDOM      Use the /dev/random pool instead of /dev/urandom
     */
    private enum GRND_NONBLOCK = 0x0001;
    private enum GRND_RANDOM = 0x0002;

    private enum GETRANDOM = NR_getrandom;

    /*
        http://man7.org/linux/man-pages/man2/getrandom.2.html
        If the urandom source has been initialized, reads of up to 256 bytes
        will always return as many bytes as requested and will not be
        interrupted by signals.  No such guarantees apply for larger buffer
        sizes.
    */
    private ptrdiff_t genRandomImplSysBlocking()(scope void* ptr, size_t len) @nogc nothrow @system
    {
        while (len > 0)
        {
            auto res = syscall(GETRANDOM, cast(size_t) ptr, len, 0);
            if (res >= 0)
            {
                len -= res;
                ptr += res;
            }
            else
            {
                return res;
            }
        }
        return 0;
    }

    /*
    *   If the GRND_NONBLOCK flag is set, then
    *   getrandom() does not block in these cases, but instead
    *   immediately returns -1 with errno set to EAGAIN.
    */
    private ptrdiff_t genRandomImplSysNonBlocking()(scope void* ptr, size_t len) @nogc nothrow @system
    {
        return syscall(GETRANDOM, cast(size_t) ptr, len, GRND_NONBLOCK);
    }
}

version(GOOD_ARC4RANDOM_BUF)
{
    //ChaCha20 on OpenBSD/NetBSD, AES on Mac OS X.
    extern(C) void arc4random_buf(scope void* buf, size_t nbytes) @nogc nothrow @system;
}

version(Darwin)
{
    //On Darwin /dev/random is identical to /dev/urandom (neither blocks
    //when there is low system entropy) so there is no point mucking
    //about with file descriptors. Just use arc4random_buf for both.
}
else version(Posix)
{
    import core.stdc.stdio : fclose, feof, ferror, fopen, fread;
    alias IOType = typeof(fopen("a", "b"));
    private __gshared IOType fdRandom;
    version (GOOD_ARC4RANDOM_BUF)
    {
        //Don't need /dev/urandom if we have arc4random_buf.
    }
    else
        private __gshared IOType fdURandom;

    ///
    extern(C) shared static ~this()
    {
        if (fdRandom !is null)
            fdRandom.fclose;

        version (GOOD_ARC4RANDOM_BUF)
        {
            //Don't need /dev/urandom if we have arc4random_buf.
        }
        else if (fdURandom !is null)
            fdURandom.fclose;
    }

    /* The /dev/random device is a legacy interface which dates back to a
       time where the cryptographic primitives used in the implementation of
       /dev/urandom were not widely trusted.  It will return random bytes
       only within the estimated number of bits of fresh noise in the
       entropy pool, blocking if necessary.  /dev/random is suitable for
       applications that need high quality randomness, and can afford
       indeterminate delays.

       When the entropy pool is empty, reads from /dev/random will block
       until additional environmental noise is gathered.
    */
    private ptrdiff_t genRandomImplFileBlocking()(scope void* ptr, size_t len) @nogc nothrow @system
    {
        if (fdRandom is null)
        {
            fdRandom = fopen("/dev/random", "r");
            if (fdRandom is null)
                return -1;
        }

        while (len > 0)
        {
            auto res = fread(ptr, 1, len, fdRandom);
            len -= res;
            ptr += res;
            // check for possible permanent errors
            if (len != 0)
            {
                if (fdRandom.ferror)
                    return -1;

                if (fdRandom.feof)
                    return -1;
            }
        }

        return 0;
    }
}

version (GOOD_ARC4RANDOM_BUF)
{
    //Don't need /dev/urandom if we have arc4random_buf.
}
else version(Posix)
{
    /**
       When read, the /dev/urandom device returns random bytes using a
       pseudorandom number generator seeded from the entropy pool.  Reads
       from this device do not block (i.e., the CPU is not yielded), but can
       incur an appreciable delay when requesting large amounts of data.
       When read during early boot time, /dev/urandom may return data prior
       to the entropy pool being initialized.
    */
    private ptrdiff_t genRandomImplFileNonBlocking()(scope void* ptr, size_t len) @nogc nothrow @system
    {
        if (fdURandom is null)
        {
            fdURandom = fopen("/dev/urandom", "r");
            if (fdURandom is null)
                return -1;
        }

        auto res = fread(ptr, 1, len, fdURandom);
        // check for possible errors
        if (res != len)
        {
            if (fdURandom.ferror)
                return -1;

            if (fdURandom.feof)
                return -1;
        }
        return res;
    }
}

version(Windows)
{
    // the wincrypt headers in druntime are broken for x64!
    private alias ULONG_PTR = size_t; // uint in druntime
    private alias BOOL = bool;
    private alias DWORD = size_t; // uint in druntime
    private alias LPCWSTR = wchar*;
    private alias PBYTE = ubyte*;
    private alias HCRYPTPROV = ULONG_PTR;
    private alias LPCSTR = const(char)*;

    private extern(Windows) BOOL CryptGenRandom(HCRYPTPROV, DWORD, PBYTE) @nogc @safe nothrow;
    private extern(Windows) BOOL CryptAcquireContextA(HCRYPTPROV*, LPCSTR, LPCSTR, DWORD, DWORD) @nogc nothrow;
    private extern(Windows) BOOL CryptAcquireContextW(HCRYPTPROV*, LPCWSTR, LPCWSTR, DWORD, DWORD) @nogc nothrow;
    private extern(Windows) BOOL CryptReleaseContext(HCRYPTPROV, ULONG_PTR) @nogc nothrow;

    private __gshared ULONG_PTR hProvider;

    private auto initGetRandom()() @nogc @trusted nothrow
    {
        import core.sys.windows.winbase : GetLastError;
        import core.sys.windows.winerror : NTE_BAD_KEYSET;
        import core.sys.windows.wincrypt : PROV_RSA_FULL, CRYPT_NEWKEYSET, CRYPT_VERIFYCONTEXT, CRYPT_SILENT;

        // https://msdn.microsoft.com/en-us/library/windows/desktop/aa379886(v=vs.85).aspx
        // For performance reasons, we recommend that you set the pszContainer
        // parameter to NULL and the dwFlags parameter to CRYPT_VERIFYCONTEXT
        // in all situations where you do not require a persisted key.
        // CRYPT_SILENT is intended for use with applications for which the UI cannot be displayed by the CSP.
        if (!CryptAcquireContextW(&hProvider, null, null, PROV_RSA_FULL, CRYPT_VERIFYCONTEXT | CRYPT_SILENT))
        {
            if (GetLastError() == NTE_BAD_KEYSET)
            {
                // Attempt to create default container
                if (!CryptAcquireContextA(&hProvider, null, null, PROV_RSA_FULL, CRYPT_NEWKEYSET | CRYPT_SILENT))
                    return 1;
            }
            else
            {
                return 1;
            }
        }

        return 0;
    }
}

/++
Constructs the mir random seed generators.
This constructor needs to be called once $(I before)
other calls in `mir.random.engine`.

Automatically called by DRuntime.
+/
extern(C) void mir_random_engine_ctor()
{
    version(Windows)
    {
        if (hProvider == 0)
            initGetRandom;
    }

    version(linux)
    {
        static if (LINUX_NR_GETRANDOM)
        {
            with(GET_RANDOM)
            {
                if (hasGetRandom == UNINITIALIZED)
                    hasGetRandom = initHasGetRandom ? AVAILABLE : NOT_AVAILABLE;
            }
        }
    }
}

/++
Destructs the mir random seed generators.

Automatically called by DRuntime.
+/
extern(C) void mir_random_engine_dtor()
{
    version(Windows)
    {
        if (hProvider > 0)
            CryptReleaseContext(hProvider, 0);
    }
}

/// Automatically calls the extern(C) module constructor
extern(C) shared static this()
{
    mir_random_engine_ctor();
}

/// Automatically calls the extern(C) module destructor
extern(C) shared static ~this()
{
    mir_random_engine_dtor();
}


/++
Fills a buffer with random data.
If not enough entropy has been gathered, it will block.

Note that on Mac OS X this method will never block.

Params:
    ptr = pointer to the buffer to fill
    len = length of the buffer (in bytes)

Returns:
    A non-zero integer if an error occurred.
+/
extern(C) ptrdiff_t mir_random_genRandomBlocking(scope void* ptr , size_t len) @nogc nothrow @system
{
    version(Windows)
    {
        while(!CryptGenRandom(hProvider, len, cast(PBYTE) ptr)) {}
        return 0;
    }
    else version (Darwin)
    {
        arc4random_buf(ptr, len);
        return 0;
    }
    else static if (LINUX_NR_GETRANDOM)
    {
        with(GET_RANDOM)
        {
            // Linux >= 3.17 has getRandom
            if (hasGetRandom == AVAILABLE)
                return genRandomImplSysBlocking(ptr, len);
            else
                return genRandomImplFileBlocking(ptr, len);
        }
    }
    else
    {
        return genRandomImplFileBlocking(ptr, len);
    }
}

/// ditto
alias genRandomBlocking = mir_random_genRandomBlocking;

/// ditto
ptrdiff_t genRandomBlocking()(scope ubyte[] buffer) @nogc nothrow @trusted
{
    pragma(inline, true);
    return mir_random_genRandomBlocking(buffer.ptr, buffer.length);
}

///
@safe nothrow version(mir_random_test) unittest
{
    ubyte[] buf = new ubyte[10];
    genRandomBlocking(buf);

    import std.algorithm.iteration : sum;
    assert(buf.sum > 0, "Only zero points generated");
}

@nogc nothrow @safe version(mir_random_test) unittest
{
    ubyte[10] buf;
    genRandomBlocking(buf);

    int sum;
    foreach (b; buf)
        sum += b;

    assert(sum > 0, "Only zero points generated");
}

/++
Fills a buffer with random data.
If not enough entropy has been gathered, it won't block.
Hence the error code should be inspected.

On Linux >= 3.17 genRandomNonBlocking is guaranteed to succeed for 256 bytes and
fewer.

On Mac OS X, OpenBSD, and NetBSD genRandomNonBlocking is guaranteed to
succeed for any number of bytes.

Params:
    buffer = the buffer to fill
    len = length of the buffer (in bytes)

Returns:
    The number of bytes filled - a negative number if an error occurred
+/
extern(C) size_t mir_random_genRandomNonBlocking(scope void* ptr, size_t len) @nogc nothrow @system
{
    version(Windows)
    {
        if (!CryptGenRandom(hProvider, len, cast(PBYTE) ptr))
            return -1;
        return len;
    }
    else version(GOOD_ARC4RANDOM_BUF)
    {
        arc4random_buf(ptr, len);
        return len;
    }
    else static if (LINUX_NR_GETRANDOM)
    {
        with(GET_RANDOM)
        {
            // Linux >= 3.17 has getRandom
            if (hasGetRandom == AVAILABLE)
                return genRandomImplSysNonBlocking(ptr, len);
            else
                return genRandomImplFileNonBlocking(ptr, len);
        }
    }
    else
    {
        return genRandomImplFileNonBlocking(ptr, len);
    }
}
/// ditto
alias genRandomNonBlocking = mir_random_genRandomNonBlocking;
/// ditto
size_t genRandomNonBlocking()(scope ubyte[] buffer) @nogc nothrow @trusted
{
    pragma(inline, true);
    return mir_random_genRandomNonBlocking(buffer.ptr, buffer.length);
}

///
@safe nothrow version(mir_random_test) unittest
{
    ubyte[] buf = new ubyte[10];
    genRandomNonBlocking(buf);

    import std.algorithm.iteration : sum;
    assert(buf.sum > 0, "Only zero points generated");
}

@nogc nothrow @safe
version(mir_random_test) unittest
{
    ubyte[10] buf;
    genRandomNonBlocking(buf);

    int sum;
    foreach (b; buf)
        sum += b;

    assert(sum > 0, "Only zero points generated");
}
