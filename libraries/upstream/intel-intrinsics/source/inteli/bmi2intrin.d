/**
* BMI2 intrinsics.
* https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#othertechs=BMI2
*
* Copyright: Copyright Johan Engelen 2021.
* License:   $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost License 1.0)
*/
module inteli.bmi2intrin;

import inteli.internals;

nothrow @nogc pure @safe:

/// Copy all bits from unsigned 32-bit integer `a` to dst, and reset (set to 0) the high bits in dst starting at index.
uint _bzhi_u32 (uint a, uint index)
{
    static if (GDC_or_LDC_with_BMI2)
    {
        if (!__ctfe)
            return __builtin_ia32_bzhi_si(a, index);
        else
            return bzhi!uint(a, index);
    }
    else
    {
        return bzhi!uint(a, index);
    }
}
unittest
{
    static assert (_bzhi_u32(0x1234_5678, 5) == 0x18);
           assert (_bzhi_u32(0x1234_5678, 5) == 0x18);
    static assert (_bzhi_u32(0x1234_5678, 10) == 0x278);
           assert (_bzhi_u32(0x1234_5678, 10) == 0x278);
    static assert (_bzhi_u32(0x1234_5678, 21) == 0x14_5678);
           assert (_bzhi_u32(0x1234_5678, 21) == 0x14_5678);
}

/// Copy all bits from unsigned 64-bit integer `a` to dst, and reset (set to 0) the high bits in dst starting at index.
ulong _bzhi_u64 (ulong a, uint index)
{
    static if (GDC_or_LDC_with_BMI2)
    {
        if (!__ctfe)
        {
            version(X86_64)
            {
                // This instruction not available in 32-bit x86.
                return __builtin_ia32_bzhi_di(a, index);
            }
            else
                return bzhi!ulong(a, index);
        }
        else
            return bzhi!ulong(a, index);
    }
    else
    {
        return bzhi!ulong(a, index);
    }
}
unittest
{
    static assert (_bzhi_u64(0x1234_5678, 5) == 0x18);
           assert (_bzhi_u64(0x1234_5678, 5) == 0x18);
    static assert (_bzhi_u64(0x1234_5678, 10) == 0x278);
           assert (_bzhi_u64(0x1234_5678, 10) == 0x278);
    static assert (_bzhi_u64(0x1234_5678, 21) == 0x14_5678);
           assert (_bzhi_u64(0x1234_5678, 21) == 0x14_5678);
    static assert (_bzhi_u64(0x8765_4321_1234_5678, 54) == 0x0025_4321_1234_5678);
           assert (_bzhi_u64(0x8765_4321_1234_5678, 54) == 0x0025_4321_1234_5678);
}

// Helper function for BZHI
private T bzhi(T)(T a, uint index)
{
    /+
        n := index[7:0]
        dst := a
        IF (n < number of bits)
            dst[MSB:n] := 0
        FI
    +/
    enum numbits = T.sizeof*8;
    T dst = a;
    if (index < numbits)
    {
        T mask = (T(1) << index) - 1;
        dst &= mask;
    }
    return dst;
}

/// Multiply unsigned 32-bit integers `a` and `b`, store the low 32-bits of the result in dst, 
/// and store the high 32-bits in `hi`. This does not read or write arithmetic flags.
/// Note: the implementation _does_ set arithmetic flags, unlike the instruction semantics say.
///       But, those particular semantics don't exist at the level of intrinsics.
uint _mulx_u32 (uint a, uint b, uint* hi)
{
    // Note: that does NOT generate mulx with LDC, and there seems to be no way to do that for
    // some reason, even with LLVM IR.
    // Also same with GDC.
    ulong result = cast(ulong) a * b;
    *hi = cast(uint) (result >>> 32);
    return cast(uint)result;
}
@system unittest
{
    uint hi;
    assert (_mulx_u32(0x1234_5678, 0x1234_5678, &hi) == 0x1DF4_D840);
    assert (hi == 0x014B_66DC);
}

/// Multiply unsigned 64-bit integers `a` and `b`, store the low 64-bits of the result in dst, and 
/// store the high 64-bits in `hi`. This does not read or write arithmetic flags.
/// Note: the implementation _does_ set arithmetic flags, unlike the instruction semantics say.
///       But, those particular semantics don't exist at the level of intrinsics.
ulong _mulx_u64 (ulong a, ulong b, ulong* hi)
{
    /+
        dst[63:0] := (a * b)[63:0]
        MEM[hi+63:hi]  := (a * b)[127:64]
    +/

    static if (LDC_with_optimizations)
    {
        static if (__VERSION__ >= 2094)
            enum bool withLDCIR = true;
        else
            enum bool withLDCIR = false;
    }
    else
    {
        enum bool withLDCIR = false;
    }

    static if (withLDCIR)
    {
        // LDC x86: Generates mulx from -O0
        enum ir = `
            %4 = zext i64 %0 to i128
            %5 = zext i64 %1 to i128
            %6 = mul nuw i128 %5, %4
            %7 = lshr i128 %6, 64
            %8 = trunc i128 %7 to i64
            store i64 %8, i64* %2, align 8
            %9 = trunc i128 %6 to i64
            ret i64 %9`;
        return LDCInlineIR!(ir, ulong, ulong, ulong, ulong*)(a, b, hi);
    }
    else
    {
        /+ Straight-forward implementation with `ucent`:
        ucent result = cast(ucent) a * b;
        *hi = cast(ulong) ((result >>> 64) & 0xFFFF_FFFF_FFFF_FFFF);
        return cast(ulong) (result & 0xFFFF_FFFF_FFFF_FFFF);
        +/

        /+
            Implementation using 64bit math is more complex...
            a * b = (a_high << 32 + a_low) * (b_high << 32 + b_low)
                  = (a_high << 32)*(b_high << 32) + (a_high << 32)*b_low + a_low* (b_high << 32) + a_low*b_low
                  = (a_high*b_high) << 64 + (a_high*b_low) << 32 + (a_low*b_high) << 32 + a_low*b_low
                  = c2 << 64 + c11 << 32 + c12 << 32 + c0
                  = z1 << 64  +  z0
        // The sums may overflow, so we need to carry the carry (from low 64bits to high 64bits). We can do that
        // by separately creating the sum to get the high 32 bits of z0 using 64bit math. The high 32 bits of that
        // intermediate result is then the 'carry' that we need to add when calculating z1's sum.
            z0 = (c0 & 0xFFFF_FFFF) + (c0 >> 32 + c11 & 0xFFFF_FFFF + c12 & 0xFFFF_FFFF ) << 32
        The carry part from z0's sum = (c0 >> 32 + c11 & 0xFFFF_FFFF + c12 & 0xFFFF_FFFF ) >> 32
            z1 = c2 + (c11 >> 32 + c12 >> 32 + (c0 >> 32 + c11 & 0xFFFF_FFFF + c12 & 0xFFFF_FFFF ) >> 32
        +/

        const ulong a_low = a & 0xFFFF_FFFF;
        const ulong a_high = a >>> 32;
        const ulong b_low = b & 0xFFFF_FFFF;
        const ulong b_high = b >>> 32;

        const ulong c2 = a_high*b_high;
        const ulong c11 = a_high*b_low;
        const ulong c12 = a_low*b_high;
        const ulong c0 = a_low*b_low;

        const ulong common_term = (c0 >> 32) + (c11 & 0xFFFF_FFFF) + (c12 & 0xFFFF_FFFF);
        const ulong z0 = (c0 & 0xFFFF_FFFF) + (common_term << 32);
        const ulong z1 = c2 + (c11 >> 32) + (c12 >> 32) + (common_term >> 32);

        *hi = z1;
        return z0;
    }
}
@system unittest
{
    ulong hi;
    // 0x1234_5678_9ABC_DEF0 * 0x1234_5678_9ABC_DEF0 == 0x14b_66dc_33f6_acdc_a5e2_0890_f2a5_2100
    assert (_mulx_u64(0x1234_5678_9ABC_DEF0, 0x1234_5678_9ABC_DEF0, &hi) == 0xa5e2_0890_f2a5_2100);
    assert (hi == 0x14b_66dc_33f6_acdc);
}

/// Deposit contiguous low bits from unsigned 32-bit integer `a` to dst at the corresponding bit locations specified by `mask`; all other bits in dst are set to zero.
uint _pdep_u32 (uint a, uint mask)
{
    static if (GDC_or_LDC_with_BMI2)
    {
        if (!__ctfe)
            return __builtin_ia32_pdep_si(a, mask);
        else
            return pdep!uint(a, mask);
    }
    else
    {
        return pdep!uint(a, mask);
    }
}
unittest
{
    static assert (_pdep_u32(0x1234_5678, 0x0F0F_0F0F) == 0x0506_0708);
           assert (_pdep_u32(0x1234_5678, 0x0F0F_0F0F) == 0x0506_0708);
}

/// Deposit contiguous low bits from unsigned 64-bit integer `a` to dst at the corresponding bit locations specified by `mask`; all other bits in dst are set to zero.
ulong _pdep_u64 (ulong a, ulong mask)
{
    static if (GDC_or_LDC_with_BMI2)
    {
        if (!__ctfe)
        {
            version(X86_64)
            {
                // This instruction not available in 32-bit x86.
                return __builtin_ia32_pdep_di(a, mask);
            }
            else
                return pdep!ulong(a, mask);
        }
        else
            return pdep!ulong(a, mask);
    }
    else
    {
        return pdep!ulong(a, mask);
    }
}
unittest
{
    static assert (_pdep_u64(0x1234_5678_8765_4321, 0x0F0F_0F0F_0F0F_0F0F) == 0x0807_0605_0403_0201);
           assert (_pdep_u64(0x1234_5678_8765_4321, 0x0F0F_0F0F_0F0F_0F0F) == 0x0807_0605_0403_0201);
}

// Helper function for PDEP
private T pdep(T)(T a, T mask)
{
    /+
        tmp := a
        dst := 0
        m := 0
        k := 0
        DO WHILE m < 32
            IF mask[m] == 1
                dst[m] := tmp[k]
                k := k + 1
            FI
            m := m + 1
        OD
    +/
    T dst;
    T k_bitpos = 1;
    T m_bitpos = 1; // for each iteration, this has one bit set to 1 in the position probed
    foreach (m; 0..T.sizeof*8)
    {
        if (mask & m_bitpos)
        {
            dst |= (a & k_bitpos) ? m_bitpos : 0;
            k_bitpos <<= 1;
        }
        m_bitpos <<= 1;
    }
    return dst;
}


/// Extract bits from unsigned 32-bit integer `a` at the corresponding bit locations specified by 
/// `mask` to contiguous low bits in dst; the remaining upper bits in dst are set to zero.
uint _pext_u32 (uint a, uint mask)
{
    static if (GDC_or_LDC_with_BMI2)
    {
        if (!__ctfe)
            return __builtin_ia32_pext_si(a, mask);
        else
            return pext!uint(a, mask);
    }
    else
    {
        return pext!uint(a, mask);
    }
}
unittest
{
    static assert (_pext_u32(0x1234_5678, 0x0F0F_0F0F) == 0x2468);
           assert (_pext_u32(0x1234_5678, 0x0F0F_0F0F) == 0x2468);
}

/// Extract bits from unsigned 64-bit integer `a` at the corresponding bit locations specified by 
/// `mask` to contiguous low bits in dst; the remaining upper bits in dst are set to zero.
ulong _pext_u64 (ulong a, ulong mask)
{
    static if (GDC_or_LDC_with_BMI2)
    {
        if (!__ctfe)
        {
            version(X86_64)
            {
                // This instruction not available in 32-bit x86.
                return __builtin_ia32_pext_di(a, mask);
            }
            else
                return pext!ulong(a, mask);
        }
        else
            return pext!ulong(a, mask);
    }
    else
    {
        return pext!ulong(a, mask);
    }
}
unittest
{
    static assert (_pext_u64(0x1234_5678_8765_4321, 0x0F0F_0F0F_0F0F_0F0F) == 0x2468_7531);
           assert (_pext_u64(0x1234_5678_8765_4321, 0x0F0F_0F0F_0F0F_0F0F) == 0x2468_7531);
}

// Helper function for PEXT
private T pext(T)(T a, T mask)
{
    /+
        tmp := a
        dst := 0
        m := 0
        k := 0
        DO WHILE m < number of bits in T
            IF mask[m] == 1
                dst[k] := tmp[m]
                k := k + 1
            FI
            m := m + 1
        OD
    +/
    T dst;
    T k_bitpos = 1;
    T m_bitpos = 1; // for each iteration, this has one bit set to 1 in the position probed
    foreach (m; 0..T.sizeof*8)
    {
        if (mask & m_bitpos)
        {
            dst |= (a & m_bitpos) ? k_bitpos : 0;
            k_bitpos <<= 1;
        }
        m_bitpos <<= 1;
    }
    return dst;
}
