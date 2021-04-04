module mir.ion.internal.stage1;

version (LDC) import ldc.attributes;
import mir.bitop;
import mir.checkedint: addu;
import mir.ion.internal.simd;

version (ARM)
    version = ARM_Any;

version (AArch64)
    version = ARM_Any;

version (X86)
    version = X86_Any;

version (X86_64)
    version = X86_Any;

@system pure nothrow @nogc
size_t stage1 (
    size_t n,
    scope const(ubyte[64])* vector,
    scope ulong[2]* pairedMask,
    ref bool backwardEscapeBit,
    )
{
    version (LDC) pragma(inline, false);
    alias AliasSeq(T...) = T;
    alias params = AliasSeq!(n, vector, pairedMask, backwardEscapeBit);
    version (LDC)
    {
        version (X86_Any)
        {
            static if (!__traits(targetHasFeature, "avx512bw"))
            {
                import cpuid.x86_any;
                if (avx512bw)
                    return stage1_impl!"skylake-avx512"(params);
                static if (!__traits(targetHasFeature, "avx2"))
                {
                    if (avx2)
                        return stage1_impl!"broadwell"(params);
                    static if (!__traits(targetHasFeature, "avx"))
                    {
                        if (avx)
                            return stage1_impl!"sandybridge"(params);
                        static if (!__traits(targetHasFeature, "sse4.2"))
                        {
                            if (sse42) // && popcnt is assumed to be true
                                return stage1_impl!"westmere"(params);
                        }
                    }
                }
            }
        }
    }
    return stage1_impl!""(params);
}

private template stage1_impl(string arch)
{
    version (LDC)
    {
        static if (arch.length)
            enum Target = target("arch=" ~ arch);
        else
            enum Target;
    }
    else
    {
        enum Target;
    }

    @Target
    size_t stage1_impl(
        size_t n,
        scope const(ubyte[64])* vector,
        scope ulong[2]* pairedMask,
        ref bool backwardEscapeBit,
        )
    {
        version (LDC) pragma(inline, true);
        enum ubyte quote = '"';
        enum ubyte escape = '\\';

        version (ARM_Any)
        {
            const __vector(ubyte[16]) quoteMask = quote;
            const __vector(ubyte[16]) escapeMask = escape;
            const __vector(ubyte[16])[2] stringMasks = [quoteMask, escapeMask];
            const __vector(ubyte[16]) mask = [
                0x01, 0x02, 0x04, 0x08, 0x10, 0x20, 0x40, 0x80, 0x01, 0x02, 0x04, 0x08, 0x10, 0x20, 0x40, 0x80,
            ];
        }
        else
        version (LDC)
        {
            alias __vector(ubyte[64]) ubyte64;
            ubyte64 quoteMask = quote;
            ubyte64 escapeMask = escape;
        }

        size_t count;
        assert(n);
        bool beb = backwardEscapeBit;
        do
        {
            version (ARM_Any)
            {
                import ldc.simd: extractelement;
                auto v = *cast(__vector(ubyte[16])[4]*)vector++;
                __vector(ubyte[16])[4][2] d;
                static foreach (i; 0 .. 2)
                static foreach (j; 0 .. 4)
                    d[i][j] = cast(__vector(ubyte[16])) __builtin_vceqq_u8(v[j], stringMasks[i]);
                static foreach (i; 0 .. 2)
                static foreach (j; 0 .. 4)
                    d[i][j] &= mask;
                version (AArch64)
                {
                    static foreach (_; 0 .. 3)
                    static foreach (i; 0 .. 2)
                    static foreach (j; 0 .. 4)
                        d[i][j] = __builtin_vpadd_u32(d[i][j], d[i][j]);

                    __vector(ushort[8]) result;
                    static foreach (i; 0 .. 2)
                    static foreach (j; 0 .. 4)
                        result[i * 4 + j] = extractelement!(__vector(ushort[8]), i * 4 + j)(cast(__vector(ushort[8])) d[i][j]);
                }
                else
                {
                    align(8) ubyte[16] result;
                    static foreach (i; 0 .. 2)
                    static foreach (j; 0 .. 4)
                    {
                        d[i][j] = d[i][j]
                            .__builtin_vpaddlq_u8
                            .__builtin_vpaddlq_u16
                            .__builtin_vpaddlq_u32;
                        result[i * 8 + j * 2 + 0] = extractelement!(__vector(ubyte[16]), 0)(d[i][j]);
                        result[i * 8 + j * 2 + 1] = extractelement!(__vector(ubyte[16]), 8)(d[i][j]);
                    }
                }
                ulong[2] maskPair = cast(ulong[2]) result;
            }
            else
            version (LDC) // works well for all X86 and x86_64 targets
            {
                auto v = *cast(ubyte64*)vector++;
                ulong[2] maskPair = [
                    equalMaskB!ubyte64(v, quoteMask),
                    equalMaskB!ubyte64(v, escapeMask),
                ];
            }
            else
            {
                ulong[2] maskPair;
                foreach_reverse (b; *vector++)
                {
                    maskPair[0] <<= 1;
                    maskPair[1] <<= 1;
                    maskPair[0] |= b == quote;
                    maskPair[1] |= b == escape;
                }
            }
            maskPair[1] &= ~ulong(beb);
            auto followsEscape = (maskPair[1] << 1) | beb;
            auto evenBits = 0x5555555555555555UL;
            auto odds = maskPair[1] & ~(evenBits | followsEscape);
            auto inversion = addu(odds, maskPair[1], beb) << 1;
            maskPair[1] = (evenBits ^ inversion) & followsEscape;
            maskPair[0] &= ~maskPair[1];
            *pairedMask++ = maskPair;
        }
        while(--n);
        backwardEscapeBit = beb;
        return count;
    }
}

version(mir_ion_test) unittest
{
    bool backwardEscapeBit = 0;
    align(64) ubyte[64][4] dataA;

    auto data = dataA.ptr.ptr[0 .. dataA.length * 64];

    foreach (i; 0 .. 256)
        data[i] = cast(ubyte)i;
    
    ulong[2][dataA.length] pairedMasks;

    stage1(pairedMasks.length, cast(const) dataA.ptr, pairedMasks.ptr, backwardEscapeBit);

    import mir.ndslice;
    auto maskData = pairedMasks.sliced;
    auto qbits = maskData.map!"a[0]".bitwise;
    auto ebits = maskData.map!"a[1]".bitwise;
    assert(qbits.length == 256);
    assert(ebits.length == 256);

    foreach (i; 0 .. 128)
    {
        assert (qbits[i] == (i == '\"'));
        assert (i == 0 || ebits[i] == (i-1 == '\\'));
    }

    foreach (i; 128 .. 256)
    {
        assert (!qbits[i]);
        assert (!ebits[i]);
    }
}

version(mir_ion_test) unittest
{
    bool backwardEscapeBit = 0;
    align(64) ubyte[64][4] dataA;

    auto data = dataA.ptr.ptr[0 .. dataA.length * 64];

    data[160] = '\\';
    data[161] = '\\';
    data[162] = '\\';

    data[165] = '\\';
    data[166] = '\"';

    data[63] = '\\';
    data[64] = '\\';
    data[65] = '\\';
    data[66] = '\"';

    data[70] = '\"';
    data[71] = '\\';
    data[72] = '\\';
    data[73] = '\\';
    data[74] = '\\';
    data[75] = '\"';

    ulong[2][dataA.length] pairedMasks;

    stage1(pairedMasks.length, cast(const) dataA.ptr, pairedMasks.ptr, backwardEscapeBit);

    import mir.ndslice;
    auto maskData = pairedMasks.sliced;
    auto qbits = maskData.map!"a[0]".bitwise;
    auto ebits = maskData.map!"a[1]".bitwise;

    foreach (i; 0 .. 68)
    {
        assert (qbits[i] == (i == 70 || i == 75));
    }

    //4992
}
