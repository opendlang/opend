/++
Generic utilities.

$(BOOKTABLE Cheat Sheet,
$(TR $(TH Function Name) $(TH Description))
$(T2 swap, Swaps two values.)
$(T2 extMul, Extended unsigned multiplications.)
$(T2 min, Minimum value.)
$(T2 max, Maximum value.)
)

License: $(HTTP www.apache.org/licenses/LICENSE-2.0, Apache-2.0)
Authors: Ilia Ki, $(HTTP erdani.com, Andrei Alexandrescu) (original std.* modules), 
Macros:
T2=$(TR $(TDNW $(LREF $1)) $(TD $+))
+/
module mir.utility;

import std.traits;

import mir.math.common: optmath;

version(LDC)
pragma(LDC_inline_ir) R inlineIR(string s, R, P...)(P) @safe pure nothrow @nogc;

@optmath:

version(LDC)
{
    ///
    public import ldc.intrinsics: _expect = llvm_expect;
}
else version(GNU)
{
    import gcc.builtins: __builtin_expect, __builtin_clong;

    ///
    T _expect(T)(in T val, in T expected_val) if (__traits(isIntegral, T))
    {
        static if (T.sizeof <= __builtin_clong.sizeof)
            return cast(T) __builtin_expect(val, expected_val);
        else
            return val;
    }
}
else
{
    ///
    T _expect(T)(in T val, in T expected_val) if (__traits(isIntegral, T))
    {
        return val;
    }
}

public import std.algorithm.mutation: swap;

void swapStars(I1, I2)(auto ref I1 i1, auto ref I2 i2)
{
    static if (__traits(compiles, swap(*i1, *i2)))
    {
        swap(*i1, *i2);
    }
    else
    {
        import mir.functional: unref;
        auto e = unref(*i1);
        i1[0] = *i2;
        i2[0] = e;
    }
}

/++
Iterates the passed arguments and returns the minimum value.
Params: args = The values to select the minimum from. At least two arguments
    must be passed, and they must be comparable with `<`.
Returns: The minimum of the passed-in values.
+/
auto min(T...)(T args)
    if (T.length >= 2)
{
    //Get "a"
    static if (T.length <= 2)
        alias a = args[0];
    else
        auto a = min(args[0 .. ($+1)/2]);
    alias T0 = typeof(a);

    //Get "b"
    static if (T.length <= 3)
        alias b = args[$-1];
    else
        auto b = min(args[($+1)/2 .. $]);
    alias T1 = typeof(b);

    static assert (is(typeof(a < b)), "Invalid arguments: Cannot compare types " ~ T0.stringof ~ " and " ~ T1.stringof ~ ".");

    static if ((isFloatingPoint!T0 && isNumeric!T1) || (isFloatingPoint!T1 && isNumeric!T0))
    {
        import mir.math.common: fmin;
        return fmin(a, b);
    }
    else
    {
        static if (isIntegral!T0 && isIntegral!T1)
            static assert(isSigned!T0 == isSigned!T1, 
                "mir.utility.min is not defined for signed + unsigned pairs because of security reasons."
                ~ "Please unify type or use a Phobos analog.");
        //Do the "min" proper with a and b
        return a < b ? a : b;
    }
}

@safe version(mir_core_test) unittest
{
    int a = 5;
    short b = 6;
    double c = 2;
    auto d = min(a, b);
    static assert(is(typeof(d) == int));
    assert(d == 5);
    auto e = min(a, b, c);
    static assert(is(typeof(e) == double));
    assert(e == 2);
}

/++
`min` is not defined for arguments of mixed signedness because of security reasons.
Please unify type or use a Phobos analog.
+/
version(mir_core_test) unittest
{
    int a = -10;
    uint b = 10;
    static assert(!is(typeof(min(a, b))));
}


/++
Iterates the passed arguments and returns the minimum value.
Params: args = The values to select the minimum from. At least two arguments
    must be passed, and they must be comparable with `<`.
Returns: The minimum of the passed-in values.
+/
auto max(T...)(T args)
    if (T.length >= 2)
{
    //Get "a"
    static if (T.length <= 2)
        alias a = args[0];
    else
        auto a = max(args[0 .. ($+1)/2]);
    alias T0 = typeof(a);

    //Get "b"
    static if (T.length <= 3)
        alias b = args[$-1];
    else
        auto b = max(args[($+1)/2 .. $]);
    alias T1 = typeof(b);

    static assert (is(typeof(a < b)), "Invalid arguments: Cannot compare types " ~ T0.stringof ~ " and " ~ T1.stringof ~ ".");

    static if ((isFloatingPoint!T0 && isNumeric!T1) || (isFloatingPoint!T1 && isNumeric!T0))
    {
        import mir.math.common: fmax;
        return fmax(a, b);
    }
    else
    {
        static if (isIntegral!T0 && isIntegral!T1)
            static assert(isSigned!T0 == isSigned!T1, 
                "mir.utility.max is not defined for signed + unsigned pairs because of security reasons."
                ~ "Please unify type or use a Phobos analog.");
        //Do the "max" proper with a and b
        return a > b ? a : b;
    }
}

///
@safe version(mir_core_test) unittest
{
    int a = 5;
    short b = 6;
    double c = 2;
    auto d = max(a, b);
    static assert(is(typeof(d) == int));
    assert(d == 6);
    auto e = min(a, b, c);
    static assert(is(typeof(e) == double));
    assert(e == 2);
}

/++
`max` is not defined for arguments of mixed signedness because of security reasons.
Please unify type or use a Phobos analog.
+/
version(mir_core_test) unittest
{
    int a = -10;
    uint b = 10;
    static assert(!is(typeof(max(a, b))));
}

/++
Return type for $(LREF extMul);

The payload order of `low` and `high` parts depends on the endianness.
+/
struct ExtMulResult(I)
    if (isUnsigned!I)
{
    version (LittleEndian)
    {
        /// Lower I.sizeof * 8 bits
        I low;
        /// Higher I.sizeof * 8 bits
        I high;
    }
    else
    {
        /// Higher I.sizeof * 8 bits
        I high;
        /// Lower I.sizeof * 8 bits
        I low;
    }

    T opCast(T : ulong)()
    {
        static if (is(I == ulong))
        {
            return cast(T)low;
        }
        else
        {
            return cast(T)(low | (ulong(high) << (I.sizeof * 8)));
        }
    }
}

private struct ExtDivResult(I)
    if (isUnsigned!I)
{
    version (LittleEndian)
    {
        /// Quotient
        I quotient;
        /// Remainder
        I remainder;
    }
    else
    {
        /// Remainder
        I remainder;
        /// Quotient
        I quotient;
    }
}

/++
Extended unsigned multiplications.
Performs U x U multiplication and returns $(LREF ExtMulResult)!U that contains extended result.
Params:
    a = unsigned integer
    b = unsigned integer
Returns:
    128bit result if U is ulong or 256bit result if U is ucent.
Optimization:
    Algorithm is optimized for LDC (LLVM IR, any target) and for DMD (X86_64).
+/
ExtMulResult!U extMul(U)(in U a, in U b) @nogc nothrow pure @trusted
    if(isUnsigned!U)
{
    static if (is(U == ulong))
        alias H = uint;
    else // ucent
        alias H = ulong;

    enum hbc = H.sizeof * 8;

    static if (U.sizeof < 4)
    {
        auto ret = uint(a) * b;
        version (LittleEndian)
            return typeof(return)(cast(U) ret, cast(U)(ret >>> (U.sizeof * 8)));
        else
            return typeof(return)(cast(U)(ret >>> (U.sizeof * 8)), cast(U) ret);
    }
    else
    static if (is(U == uint))
    {
        auto ret = ulong(a) * b;
        version (LittleEndian)
            return typeof(return)(cast(uint) ret, cast(uint)(ret >>> 32));
        else
            return typeof(return)(cast(uint)(ret >>> 32), cast(uint) ret);
    }
    else
    static if (is(U == ulong) && __traits(compiles, ucent.init))
    {
        auto ret = ucent(a) * b;
        version (LittleEndian)
            return typeof(return)(cast(ulong) ret, cast(ulong)(ret >>> 64));
        else
            return typeof(return)(cast(ulong)(ret >>> 64), cast(ulong) ret);
    }
    else
    {
        if (!__ctfe)
        {
            static if (size_t.sizeof == 4)
            {
                // https://github.com/ldc-developers/ldc/issues/2391
            }
            else
            version(LDC)
            {
                // LLVM IR by n8sh
                pragma(inline, true);
                static if (is(U == ulong))
                {
                    auto r = inlineIR!(`
                    %a = zext i64 %0 to i128
                    %b = zext i64 %1 to i128
                    %m = mul i128 %a, %b
                    %n = lshr i128 %m, 64
                    %h = trunc i128 %n to i64
                    %l = trunc i128 %m to i64
                    %agg1 = insertvalue [2 x i64] undef, i64 %l, 0
                    %agg2 = insertvalue [2 x i64] %agg1, i64 %h, 1
                    ret [2 x i64] %agg2`, ulong[2])(a, b);
                    version (LittleEndian)
                        return ExtMulResult!U(r[0], r[1]);
                    else
                        return ExtMulResult!U(r[1], r[0]);
                }
                else
                static if (false)
                {
                    auto r = inlineIR!(`
                    %a = zext i128 %0 to i256
                    %b = zext i128 %1 to i256
                    %m = mul i256 %a, %b
                    %n = lshr i256 %m, 128
                    %h = trunc i256 %n to i128
                    %l = trunc i256 %m to i128
                    %agg1 = insertvalue [2 x i128] undef, i128 %l, 0
                    %agg2 = insertvalue [2 x i128] %agg1, i128 %h, 1
                    ret [2 x i128] %agg2`, ucent[2])(a, b);
                    version (LittleEndian)
                        return ExtMulResult!U(r[0], r[1]);
                    else
                        return ExtMulResult!U(r[1], r[0]);
                }
            }
            else
            version(D_InlineAsm_X86_64)
            {
                static if (is(U == ulong))
                {
                    return extMul_X86_64(a, b);
                }
            }
        }

        U al = cast(H)a;
        U ah = a >>> hbc;
        U bl = cast(H)b;
        U bh = b >>> hbc;

        U p0 = al * bl;
        U p1 = al * bh;
        U p2 = ah * bl;
        U p3 = ah * bh;

        H cy = cast(H)(((p0 >>> hbc) + cast(H)p1 + cast(H)p2) >>> hbc);
        U lo = p0 + (p1 << hbc) + (p2 << hbc);
        U hi = p3 + (p1 >>> hbc) + (p2 >>> hbc) + cy;

        version(LittleEndian)
            return typeof(return)(lo, hi);
        else
            return typeof(return)(hi, lo);
    }
}

/// 64bit x 64bit -> 128bit
version(mir_core_test) unittest
{
    immutable a = 0x93_8d_28_00_0f_50_a5_56;
    immutable b = 0x54_c3_2f_e8_cc_a5_97_10;
    enum c = extMul(a, b);     // Compile time algorithm
    assert(extMul(a, b) == c); // Fast runtime algorithm
    static assert(c.high == 0x30_da_d1_42_95_4a_50_78);
    static assert(c.low == 0x27_9b_4b_b4_9e_fe_0f_60);
}

/// 32bit x 32bit -> 64bit
version(mir_core_test) unittest
{
    immutable a = 0x0f_50_a5_56;
    immutable b = 0xcc_a5_97_10;
    static assert(cast(ulong)extMul(a, b) == ulong(a) * b);
}

///
version(mir_core_test) unittest
{
    immutable ushort a = 0xa5_56;
    immutable ushort b = 0x97_10;
    static assert(cast(uint)extMul(a, b) == a * b);
}

///
version(mir_core_test) unittest
{
    immutable ubyte a = 0x56;
    immutable ubyte b = 0x10;
    static assert(cast(ushort)extMul(a, b) == a * b);
}

version(D_InlineAsm_X86_64)
{
    version(Windows)
    {
        private ulong[2] extMul_X86_64_impl()(ulong a, ulong b)
        {
            asm @safe pure nothrow @nogc
            {
                naked;
                mov RAX, RCX;
                mul RDX;
                ret;
            }
        }

        private ExtMulResult!ulong extMul_X86_64()(ulong a, ulong b)
        {
            auto res = extMul_X86_64_impl(a, b);
            return ExtMulResult!ulong(res[0], res[1]);
        }
    }
    else
    private ExtMulResult!ulong extMul_X86_64()(ulong a, ulong b)   
    {  
        asm @safe pure nothrow @nogc
        {
            naked;
            mov RAX, RDI;
            mul RSI;
            ret;
        }
    }

    version(Windows)
    {
        private ulong[2] extDiv_X86_64_impl()(ulong high, ulong low, ulong d)
        {
            asm @safe pure nothrow @nogc
            {
                naked;
                mov RAX, RCX;
                div RDX;
                ret;
            }
        }

        private ExtDivResult!ulong extDiv_X86_64()(ExtMulResult!ulong pair, ulong d)
        {
            auto res = extDiv_X86_64_impl(pair.high, pair.low);
            return ExtDivResult!ulong(res[0], res[1]);
        }
    }
    else
    private ExtDivResult!ulong extDiv_X86_64()(ExtMulResult!ulong pair, ulong d)   
    {  
        asm @safe pure nothrow @nogc
        {
            naked;
            mov RAX, RDI;
            div RSI;
            ret;
        }
    }
}

version(LDC) {} else version(D_InlineAsm_X86_64)
@nogc nothrow pure @safe version(mir_core_test) unittest
{
    immutable a = 0x93_8d_28_00_0f_50_a5_56;
    immutable b = 0x54_c3_2f_e8_cc_a5_97_10;

    immutable ExtMulResult!ulong c = extMul_X86_64(a, b);

    assert(c.high == 0x30_da_d1_42_95_4a_50_78);
    assert(c.low == 0x27_9b_4b_b4_9e_fe_0f_60);
}

// draft
// https://www.codeproject.com/Tips/785014/UInt-Division-Modulus
private ulong divmod128by64(const ulong u1, const ulong u0, ulong v, out ulong r)
{
    const ulong b = 1L << 32;
    ulong un1, un0, vn1, vn0, q1, q0, un32, un21, un10, rhat, left, right;

    import mir.bitop;

    auto s = ctlz(v);
    v <<= s;
    vn1 = v >> 32;
    vn0 = v & 0xffffffff;

    un32 = (u1 << s) | (u0 >> (64 - s));
    un10 = u0 << s;

    un1 = un10 >> 32;
    un0 = un10 & 0xffffffff;

    q1 = un32 / vn1;
    rhat = un32 % vn1;

    left = q1 * vn0;
    right = (rhat << 32) + un1;

    while ((q1 >= b) || (left > right))
    {
        --q1;
        rhat += vn1;
        if (rhat >= b)
            break;
        left -= vn0;
        right = (rhat << 32) | un1;
    }

    un21 = (un32 << 32) + (un1 - (q1 * v));

    q0 = un21 / vn1;
    rhat = un21 % vn1;

    left = q0 * vn0;
    right = (rhat << 32) | un0;

    while ((q0 >= b) || (left > right))
    {
        --q0;
        rhat += vn1;
        if (rhat >= b)
            break;
        left -= vn0;
        right = (rhat << 32) | un0;
    }

    r = ((un21 << 32) + (un0 - (q0 * v))) >> s;
    return (q1 << 32) | q0;
}

/++
Simple sort algorithm usefull for CTFE code.
+/
template simpleSort(alias cmp = "a < b")
{
    ///
    T[] simpleSort(T)(return T[] array)
    {
        size_t i = 1;
        while (i < array.length)
        {
            size_t j = i;
            import mir.functional: naryFun;
            while (j > 0 && !naryFun!cmp(array[j - 1], array[j]))
            {
                swap(array[j - 1], array[j]);
                j--;
            }
            i++;
        }
        return array;
    }
}
