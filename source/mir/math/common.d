/++
Common floating point math functions.

This module has generic LLVM-oriented API compatible with all D compilers.

License:   $(HTTP boost.org/LICENSE_1_0.txt, Boost License 1.0).
Copyright: Copyright © 2016-, Ilya Yaroshenko
Authors:   Ilya Yaroshenko, Phobos Team
+/
module mir.math.common;

import mir.internal.utility: isComplex, isFloatingPoint;

version(LDC)
{
    static import ldc.attributes;

    private alias AliasSeq(T...) = T;

    /++
    Functions attribute, an alias for `AliasSeq!(llvmFastMathFlag("contract"));`.
        
    $(UL
    $(LI 1. Allow floating-point contraction (e.g. fusing a multiply followed by an addition into a fused multiply-and-add). )
    )

    Note: Can be used with all compilers.
    +/
    alias fmamath = AliasSeq!(ldc.attributes.llvmFastMathFlag("contract"));

    /++
    Functions attribute, an alias for `AliasSeq!(llvmAttr("unsafe-fp-math", "false"), llvmFastMathFlag("fast"))`.
    
    It is similar to $(LREF fastmath), but does not allow unsafe-fp-math.
    This flag does NOT force LDC to use the reciprocal of an argument rather than perform division.

    This flag is default for string lambdas.

    Note: Can be used with all compilers.
    +/
    alias optmath = AliasSeq!(ldc.attributes.llvmFastMathFlag("fast"));

    /++
    Functions attribute, an alias for `ldc.attributes.fastmath = AliasSeq!(llvmAttr("unsafe-fp-math", "true"), llvmFastMathFlag("fast"))` .
    
    $(UL

    $(LI 1. Enable optimizations that make unsafe assumptions about IEEE math (e.g. that addition is associative) or may not work for all input ranges.
    These optimizations allow the code generator to make use of some instructions which would otherwise not be usable (such as fsin on X86). )

    $(LI 2. Allow optimizations to assume the arguments and result are not NaN.
        Such optimizations are required to retain defined behavior over NaNs,
        but the value of the result is undefined. )

    $(LI 3. Allow optimizations to assume the arguments and result are not +$(BACKTICK)-inf.
        Such optimizations are required to retain defined behavior over +$(BACKTICK)-Inf,
        but the value of the result is undefined. )

    $(LI 4. Allow optimizations to treat the sign of a zero argument or result as insignificant. )

    $(LI 5. Allow optimizations to use the reciprocal of an argument rather than perform division. )

    $(LI 6. Allow floating-point contraction (e.g. fusing a multiply followed by an addition into a fused multiply-and-add). )

    $(LI 7. Allow algebraically equivalent transformations that may dramatically change results in floating point (e.g. reassociate). )
    )
    
    Note: Can be used with all compilers.
    +/
    alias fastmath = ldc.attributes.fastmath;
}
else
enum
{
    /++
    Functions attribute, an alias for `AliasSeq!(llvmFastMathFlag("contract"));`.

    $(UL
    $(LI Allow floating-point contraction (e.g. fusing a multiply followed by an addition into a fused multiply-and-add). )
    )

    Note: Can be used with all compilers.
    +/
    fmamath,

    /++
    Functions attribute, an alias for `AliasSeq!(llvmAttr("unsafe-fp-math", "false"), llvmFastMathFlag("fast"))`.

    It is similar to $(LREF fastmath), but does not allow unsafe-fp-math.
    This flag does NOT force LDC to use the reciprocal of an argument rather than perform division.

    This flag is default for string lambdas.

    Note: Can be used with all compilers.
    +/
    optmath,

    /++
    Functions attribute, an alias for `ldc.attributes.fastmath = AliasSeq!(llvmAttr("unsafe-fp-math", "true"), llvmFastMathFlag("fast"))` .

    $(UL

    $(LI Enable optimizations that make unsafe assumptions about IEEE math (e.g. that addition is associative) or may not work for all input ranges.
    These optimizations allow the code generator to make use of some instructions which would otherwise not be usable (such as fsin on X86). )

    $(LI Allow optimizations to assume the arguments and result are not NaN.
        Such optimizations are required to retain defined behavior over NaNs,
        but the value of the result is undefined. )

    $(LI Allow optimizations to assume the arguments and result are not +$(BACKTICK)-inf.
        Such optimizations are required to retain defined behavior over +$(BACKTICK)-Inf,
        but the value of the result is undefined. )

    $(LI Allow optimizations to treat the sign of a zero argument or result as insignificant. )

    $(LI Allow optimizations to use the reciprocal of an argument rather than perform division. )

    $(LI Allow floating-point contraction (e.g. fusing a multiply followed by an addition into a fused multiply-and-add). )

    $(LI Allow algebraically equivalent transformations that may dramatically change results in floating point (e.g. reassociate). )
    )

    Note: Can be used with all compilers.
    +/
    fastmath
}

version(LDC)
{
    nothrow @nogc pure @safe:

    pragma(LDC_intrinsic, "llvm.sqrt.f#")
    ///
    T sqrt(T)(in T val) if (isFloatingPoint!T);

    pragma(LDC_intrinsic, "llvm.sin.f#")
    ///
    T sin(T)(in T val) if (isFloatingPoint!T);

    pragma(LDC_intrinsic, "llvm.cos.f#")
    ///
    T cos(T)(in T val) if (isFloatingPoint!T);

    pragma(LDC_intrinsic, "llvm.powi.f#")
    ///
    T powi(T)(in T val, int power) if (isFloatingPoint!T);

    pragma(LDC_intrinsic, "llvm.pow.f#")
    ///
    T pow(T)(in T val, in T power) if (isFloatingPoint!T);

    pragma(LDC_intrinsic, "llvm.exp.f#")
    ///
    T exp(T)(in T val) if (isFloatingPoint!T);

    pragma(LDC_intrinsic, "llvm.log.f#")
    ///
    T log(T)(in T val) if (isFloatingPoint!T);

    pragma(LDC_intrinsic, "llvm.fma.f#")
    ///
    T fma(T)(T vala, T valb, T valc) if (isFloatingPoint!T);

    pragma(LDC_intrinsic, "llvm.fabs.f#")
    ///
    T fabs(T)(in T val) if (isFloatingPoint!T);

    pragma(LDC_intrinsic, "llvm.floor.f#")
    ///
    T floor(T)(in T val) if (isFloatingPoint!T);

    pragma(LDC_intrinsic, "llvm.exp2.f#")
    ///
    T exp2(T)(in T val) if (isFloatingPoint!T);

    pragma(LDC_intrinsic, "llvm.log10.f#")
    ///
    T log10(T)(in T val) if (isFloatingPoint!T);

    pragma(LDC_intrinsic, "llvm.log2.f#")
    ///
    T log2(T)(in T val) if (isFloatingPoint!T);

    pragma(LDC_intrinsic, "llvm.ceil.f#")
    ///
    T ceil(T)(in T val) if (isFloatingPoint!T);

    pragma(LDC_intrinsic, "llvm.trunc.f#")
    ///
    T trunc(T)(in T val) if (isFloatingPoint!T);

    pragma(LDC_intrinsic, "llvm.rint.f#")
    ///
    T rint(T)(in T val) if (isFloatingPoint!T);

    pragma(LDC_intrinsic, "llvm.nearbyint.f#")
    ///
    T nearbyint(T)(in T val) if (isFloatingPoint!T);

    pragma(LDC_intrinsic, "llvm.copysign.f#")
    ///
    T copysign(T)(in T mag, in T sgn) if (isFloatingPoint!T);

    pragma(LDC_intrinsic, "llvm.round.f#")
    ///
    T round(T)(in T val) if (isFloatingPoint!T);

    pragma(LDC_intrinsic, "llvm.fmuladd.f#")
    ///
    T fmuladd(T)(in T vala, in T valb, in T valc) if (isFloatingPoint!T);

    pragma(LDC_intrinsic, "llvm.minnum.f#")
    ///
    T fmin(T)(in T vala, in T valb) if (isFloatingPoint!T);

    pragma(LDC_intrinsic, "llvm.maxnum.f#")
    ///
    T fmax(T)(in T vala, in T valb) if (isFloatingPoint!T);
}
else version(GNU)
{
    static import gcc.builtins;

    // Calls GCC builtin for either float (suffix "f"), double (no suffix), or real (suffix "l").
    private enum mixinGCCBuiltin(string fun) =
    `static if (T.mant_dig == float.mant_dig) return gcc.builtins.__builtin_`~fun~`f(x);`~
    ` else static if (T.mant_dig == double.mant_dig) return gcc.builtins.__builtin_`~fun~`(x);`~
    ` else static if (T.mant_dig == real.mant_dig) return gcc.builtins.__builtin_`~fun~`l(x);`~
    ` else static assert(0);`;

    // As above but for two-argument function.
    private enum mixinGCCBuiltin2(string fun) =
    `static if (T.mant_dig == float.mant_dig) return gcc.builtins.__builtin_`~fun~`f(x, y);`~
    ` else static if (T.mant_dig == double.mant_dig) return gcc.builtins.__builtin_`~fun~`(x, y);`~
    ` else static if (T.mant_dig == real.mant_dig) return gcc.builtins.__builtin_`~fun~`l(x, y);`~
    ` else static assert(0);`;

    ///
    T sqrt(T)(in T x) if (isFloatingPoint!T) { mixin(mixinGCCBuiltin!`sqrt`); }
    ///
    T sin(T)(in T x) if (isFloatingPoint!T) { mixin(mixinGCCBuiltin!`sin`); }
    ///
    T cos(T)(in T x) if (isFloatingPoint!T) { mixin(mixinGCCBuiltin!`cos`); }
    ///
    T pow(T)(in T x, in T power) if (isFloatingPoint!T) { alias y = power; mixin(mixinGCCBuiltin2!`pow`); }
    ///
    T powi(T)(in T x, int power) if (isFloatingPoint!T) { alias y = power; mixin(mixinGCCBuiltin2!`powi`); }
    ///
    T exp(T)(in T x) if (isFloatingPoint!T) { mixin(mixinGCCBuiltin!`exp`); }
    ///
    T log(T)(in T x) if (isFloatingPoint!T) { mixin(mixinGCCBuiltin!`log`); }
    ///
    T fabs(T)(in T x) if (isFloatingPoint!T) { mixin(mixinGCCBuiltin!`fabs`); }
    ///
    T floor(T)(in T x) if (isFloatingPoint!T) { mixin(mixinGCCBuiltin!`floor`); }
    ///
    T exp2(T)(in T x) if (isFloatingPoint!T) { mixin(mixinGCCBuiltin!`exp2`); }
    ///
    T log10(T)(in T x) if (isFloatingPoint!T) { mixin(mixinGCCBuiltin!`log10`); }
    ///
    T log2(T)(in T x) if (isFloatingPoint!T) { mixin(mixinGCCBuiltin!`log2`); }
    ///
    T ceil(T)(in T x) if (isFloatingPoint!T) { mixin(mixinGCCBuiltin!`ceil`); }
    ///
    T trunc(T)(in T x) if (isFloatingPoint!T) { mixin(mixinGCCBuiltin!`trunc`); }
    ///
    T rint(T)(in T x) if (isFloatingPoint!T) { mixin(mixinGCCBuiltin!`rint`); }
    ///
    T nearbyint(T)(in T x) if (isFloatingPoint!T) { mixin(mixinGCCBuiltin!`nearbyint`); }
    ///
    T copysign(T)(in T mag, in T sgn) if (isFloatingPoint!T) { alias y = sgn; mixin(mixinGCCBuiltin2!`copysign`); }
    ///
    T round(T)(in T x) if (isFloatingPoint!T) { mixin(mixinGCCBuiltin!`round`); }
    ///
    T fmuladd(T)(in T a, in T b, in T c) if (isFloatingPoint!T)
    {
        static if (T.mant_dig == float.mant_dig)
            return gcc.builtins.__builtin_fmaf(a, b, c);
        else static if (T.mant_dig == double.mant_dig)
            return gcc.builtins.__builtin_fma(a, b, c);
        else static if (T.mant_dig == real.mant_dig)
            return gcc.builtins.__builtin_fmal(a, b, c);
        else
            static assert(0);
    }
    version(mir_test)
    unittest { assert(fmuladd!double(2, 3, 4) == 2 * 3 + 4); }
    ///
    T fmin(T)(in T x, in T y) if (isFloatingPoint!T) { mixin(mixinGCCBuiltin2!`fmin`); }
    ///
    T fmax(T)(in T x, in T y) if (isFloatingPoint!T) { mixin(mixinGCCBuiltin2!`fmax`); }
}
else static if (__VERSION__ >= 2082) // DMD 2.082 onward.
{
    static import std.math;
    static import core.stdc.math;

    // Calls either std.math or cmath function for either float (suffix "f")
    // or double (no suffix). std.math will always be used during CTFE or for
    // arguments with greater than double precision or if the cmath function
    // is impure.
    private enum mixinCMath(string fun) =
        `pragma(inline, true);
        static if (!is(typeof(std.math.`~fun~`(0.5f)) == float)
            && is(typeof(() pure => core.stdc.math.`~fun~`f(0.5f))))
        if (!__ctfe)
        {
            static if (T.mant_dig == float.mant_dig) return core.stdc.math.`~fun~`f(x);
            else static if (T.mant_dig == double.mant_dig) return core.stdc.math.`~fun~`(x);
        }
        return std.math.`~fun~`(x);`;

    // As above but for two-argument function (both arguments must be floating point).
    private enum mixinCMath2(string fun) =
        `pragma(inline, true);
        static if (!is(typeof(std.math.`~fun~`(0.5f, 0.5f)) == float)
            && is(typeof(() pure => core.stdc.math.`~fun~`f(0.5f, 0.5f))))
        if (!__ctfe)
        {
            static if (T.mant_dig == float.mant_dig) return core.stdc.math.`~fun~`f(x, y);
            else static if (T.mant_dig == double.mant_dig) return core.stdc.math.`~fun~`(x, y);
        }
        return std.math.`~fun~`(x, y);`;

    // Some std.math functions have appropriate return types (float,
    // double, real) without need for a wrapper. We can alias them
    // directly but we leave the templates afterwards for documentation
    // purposes and so explicit template instantiation still works.
    // The aliases will always match before the templates.
    // Note that you cannot put any "static if" around the aliases or
    // compilation will fail due to conflict with the templates!
    alias sqrt = std.math.sqrt;
    alias sin = std.math.sin;
    alias cos = std.math.cos;
    alias exp = std.math.exp;
    //alias fabs = std.math.fabs;
    alias floor = std.math.floor;
    alias exp2 = std.math.exp2;
    alias ceil = std.math.ceil;
    alias rint = std.math.rint;

    ///
    T sqrt(T)(in T x) if (isFloatingPoint!T) { return std.math.sqrt(x); }
    ///
    T sin(T)(in T x) if (isFloatingPoint!T) { return std.math.sin(x); }
    ///
    T cos(T)(in T x) if (isFloatingPoint!T) { return std.math.cos(x); }
    ///
    T pow(T)(in T x, in T power) if (isFloatingPoint!T) { alias y = power; mixin(mixinCMath2!`pow`); }
    ///
    T powi(T)(in T x, int power) if (isFloatingPoint!T) { alias y = power; mixin(mixinCMath2!`pow`); }
    ///
    T exp(T)(in T x) if (isFloatingPoint!T) { return std.math.exp(x); }
    ///
    T log(T)(in T x) if (isFloatingPoint!T) { mixin(mixinCMath!`log`); }
    ///
    T fabs(T)(in T x) if (isFloatingPoint!T) { return std.math.fabs(x); }
    ///
    T floor(T)(in T x) if (isFloatingPoint!T) { return std.math.floor(x); }
    ///
    T exp2(T)(in T x) if (isFloatingPoint!T) { return std.math.exp2(x); }
    ///
    T log10(T)(in T x) if (isFloatingPoint!T) { mixin(mixinCMath!`log10`); }
    ///
    T log2(T)(in T x) if (isFloatingPoint!T) { mixin(mixinCMath!`log2`); }
    ///
    T ceil(T)(in T x) if (isFloatingPoint!T) { return std.math.ceil(x); }
    ///
    T trunc(T)(in T x) if (isFloatingPoint!T) { mixin(mixinCMath!`trunc`); }
    ///
    T rint(T)(in T x) if (isFloatingPoint!T) { return std.math.rint(x); }
    ///
    T nearbyint(T)(in T x) if (isFloatingPoint!T) { mixin(mixinCMath!`nearbyint`); }
    ///
    T copysign(T)(in T mag, in T sgn) if (isFloatingPoint!T)
    {
        alias x = mag;
        alias y = sgn;
        mixin(mixinCMath2!`copysign`);
    }
    ///
    T round(T)(in T x) if (isFloatingPoint!T) { mixin(mixinCMath!`round`); }
    ///
    T fmuladd(T)(in T a, in T b, in T c) if (isFloatingPoint!T) { return a * b + c; }
    version(mir_test)
    unittest { assert(fmuladd!double(2, 3, 4) == 2 * 3 + 4); }
    ///
    T fmin(T)(in T x, in T y) if (isFloatingPoint!T)
    {
        version (Windows) // https://issues.dlang.org/show_bug.cgi?id=19798
        {
            version (CRuntime_Microsoft)
                mixin(mixinCMath2!`fmin`);
            else
                return std.math.fmin(x, y);
        }
        else
            mixin(mixinCMath2!`fmin`);
    }
    ///
    T fmax(T)(in T x, in T y) if (isFloatingPoint!T)
    {
        version (Windows) // https://issues.dlang.org/show_bug.cgi?id=19798
        {
            version (CRuntime_Microsoft)
                mixin(mixinCMath2!`fmax`);
            else
                return std.math.fmax(x, y);
        }
        else
            mixin(mixinCMath2!`fmax`);
    }

    version (mir_test) @nogc nothrow pure @safe unittest
    {
        // Check the aliases are correct.
        static assert(is(typeof(sqrt(1.0f)) == float));
        static assert(is(typeof(sin(1.0f)) == float));
        static assert(is(typeof(cos(1.0f)) == float));
        static assert(is(typeof(exp(1.0f)) == float));
        static assert(is(typeof(fabs(1.0f)) == float));
        static assert(is(typeof(floor(1.0f)) == float));
        static assert(is(typeof(exp2(1.0f)) == float));
        static assert(is(typeof(ceil(1.0f)) == float));
        static assert(is(typeof(rint(1.0f)) == float));

        auto x = sqrt!float(2.0f); // Explicit template instantiation still works.
        auto fp = &sqrt!float; // Can still take function address.

        // Test for DMD linker problem with fmin on Windows.
        static assert(is(typeof(fmin!float(1.0f, 1.0f))));
        static assert(is(typeof(fmax!float(1.0f, 1.0f))));
    }
}
else // DMD version prior to 2.082
{
    static import std.math;
    static import core.stdc.math;

    // Calls either std.math or cmath function for either float (suffix "f")
    // or double (no suffix). std.math will always be used during CTFE or for
    // arguments with greater than double precision or if the cmath function
    // is impure.
    private enum mixinCMath(string fun) =
        `pragma(inline, true);
        static if (!is(typeof(std.math.`~fun~`(0.5f)) == float)
            && is(typeof(() pure => core.stdc.math.`~fun~`f(0.5f))))
        if (!__ctfe)
        {
            static if (T.mant_dig == float.mant_dig) return core.stdc.math.`~fun~`f(x);
            else static if (T.mant_dig == double.mant_dig) return core.stdc.math.`~fun~`(x);
        }
        return std.math.`~fun~`(x);`;

    // As above but for two-argument function (both arguments must be floating point).
    private enum mixinCMath2(string fun) =
        `pragma(inline, true);
        static if (!is(typeof(std.math.`~fun~`(0.5f, 0.5f)) == float)
            && is(typeof(() pure => core.stdc.math.`~fun~`f(0.5f, 0.5f))))
        if (!__ctfe)
        {
            static if (T.mant_dig == float.mant_dig) return core.stdc.math.`~fun~`f(x, y);
            else static if (T.mant_dig == double.mant_dig) return core.stdc.math.`~fun~`(x, y);
        }
        return std.math.`~fun~`(x, y);`;

    // Some std.math functions have appropriate return types (float,
    // double, real) without need for a wrapper.
    alias sqrt = std.math.sqrt;

    ///
    T sqrt(T)(in T x) if (isFloatingPoint!T) { return std.math.sqrt(x); }
    ///
    T sin(T)(in T x) if (isFloatingPoint!T) { mixin(mixinCMath!`sin`); }
    ///
    T cos(T)(in T x) if (isFloatingPoint!T) { mixin(mixinCMath!`cos`); }
    ///
    T pow(T)(in T x, in T power) if (isFloatingPoint!T) { alias y = power; mixin(mixinCMath2!`pow`); }
    ///
    T powi(T)(in T x, int power) if (isFloatingPoint!T) { alias y = power; mixin(mixinCMath2!`pow`); }
    ///
    T exp(T)(in T x) if (isFloatingPoint!T) { mixin(mixinCMath!`exp`); }
    ///
    T log(T)(in T x) if (isFloatingPoint!T) { mixin(mixinCMath!`log`); }
    ///
    T fabs(T)(in T x) if (isFloatingPoint!T) { mixin(mixinCMath!`fabs`); }
    ///
    T floor(T)(in T x) if (isFloatingPoint!T) { mixin(mixinCMath!`floor`); }
    ///
    T exp2(T)(in T x) if (isFloatingPoint!T) { mixin(mixinCMath!`exp2`); }
    ///
    T log10(T)(in T x) if (isFloatingPoint!T) { mixin(mixinCMath!`log10`); }
    ///
    T log2(T)(in T x) if (isFloatingPoint!T) { mixin(mixinCMath!`log2`); }
    ///
    T ceil(T)(in T x) if (isFloatingPoint!T) { mixin(mixinCMath!`ceil`); }
    ///
    T trunc(T)(in T x) if (isFloatingPoint!T) { mixin(mixinCMath!`trunc`); }
    ///
    T rint(T)(in T x) if (isFloatingPoint!T) { mixin(mixinCMath!`rint`); }
    ///
    T nearbyint(T)(in T x) if (isFloatingPoint!T) { mixin(mixinCMath!`nearbyint`); }
    ///
    T copysign(T)(in T mag, in T sgn) if (isFloatingPoint!T)
    {
        alias x = mag;
        alias y = sgn;
        mixin(mixinCMath2!`copysign`);
    }
    ///
    T round(T)(in T x) if (isFloatingPoint!T) { mixin(mixinCMath!`round`); }
    ///
    T fmuladd(T)(in T a, in T b, in T c) if (isFloatingPoint!T) { return a * b + c; }
    version(mir_test)
    unittest { assert(fmuladd!double(2, 3, 4) == 2 * 3 + 4); }
    ///
    T fmin(T)(in T x, in T y) if (isFloatingPoint!T)
    {
        version (Windows) // https://issues.dlang.org/show_bug.cgi?id=19798
        {
            version (CRuntime_Microsoft)
                mixin(mixinCMath2!`fmin`);
            else
                return std.math.fmin(x, y);
        }
        else
            mixin(mixinCMath2!`fmin`);
    }
    ///
    T fmax(T)(in T x, in T y) if (isFloatingPoint!T)
    {
        version (Windows) // https://issues.dlang.org/show_bug.cgi?id=19798
        {
            version (CRuntime_Microsoft)
                mixin(mixinCMath2!`fmax`);
            else
                return std.math.fmax(x, y);
        }
        else
            mixin(mixinCMath2!`fmax`);
    }

    version (mir_test) @nogc nothrow pure @safe unittest
    {
        // Check the aliases are correct.
        static assert(is(typeof(sqrt(1.0f)) == float));
        auto x = sqrt!float(2.0f); // Explicit template instantiation still works.
        auto fp = &sqrt!float; // Can still take function address.

        // Test for DMD linker problem with fmin on Windows.
        static assert(is(typeof(fmin!float(1.0f, 1.0f))));
        static assert(is(typeof(fmax!float(1.0f, 1.0f))));
    }
}

version (mir_test)
@nogc nothrow pure @safe unittest
{
    import mir.math: PI, feqrel;
    assert(feqrel(pow(2.0L, -0.5L), cos(PI / 4)) >= real.mant_dig - 1);
}

/// Overload for cdouble, cfloat and creal
@optmath auto fabs(T)(in T x)
    if (isComplex!T)
{
    return x.re * x.re + x.im * x.im;
}

///
unittest
{
    assert(fabs(3 + 4i) == 25);
}

/++
Computes whether two values are approximately equal, admitting a maximum
relative difference, and a maximum absolute difference.
Params:
    lhs = First item to compare.
    rhs = Second item to compare.
    maxRelDiff = Maximum allowable difference relative to `rhs`. Defaults to `0.5 ^^ 20`.
    maxAbsDiff = Maximum absolute difference. Defaults to `0.5 ^^ 20`.
        
Returns:
    `true` if the two items are equal or approximately equal under either criterium.
+/
bool approxEqual(T)(const T lhs, const T rhs, const T maxRelDiff = T(0x1p-20f), const T maxAbsDiff = T(0x1p-20f))
{
    if (rhs == lhs) // infs
        return true;
    auto diff = fabs(lhs - rhs);
    if (diff <= maxAbsDiff)
        return true;
    diff /= fabs(rhs);
    return diff <= maxRelDiff;
}

///
@safe pure nothrow @nogc unittest
{
    assert(approxEqual(1.0, 1.0000001));
    assert(approxEqual(1.0f, 1.0000001f));
    assert(approxEqual(1.0L, 1.0000001L));

    assert(approxEqual(10000000.0, 10000001));
    assert(approxEqual(10000000f, 10000001f));
    assert(!approxEqual(100000.0L, 100001L));
}

/// ditto
bool approxEqual(T : cfloat)(const T lhs, const T rhs, float maxRelDiff = 0x1p-20f, float maxAbsDiff = 0x1p-20f)
{
    return approxEqual(lhs.re, rhs.re, maxRelDiff, maxAbsDiff)
        && approxEqual(lhs.im, rhs.im, maxRelDiff, maxAbsDiff);
}

/// ditto
bool approxEqual(T : cdouble)(const T lhs, const T rhs, double maxRelDiff = 0x1p-20f, double maxAbsDiff = 0x1p-20f)
{
    return approxEqual(lhs.re, rhs.re, maxRelDiff, maxAbsDiff)
        && approxEqual(lhs.im, rhs.im, maxRelDiff, maxAbsDiff);
}

/// ditto
bool approxEqual(T : creal)(const T lhs, const T rhs, real maxRelDiff = 0x1p-20f, real maxAbsDiff = 0x1p-20f)
{
    return approxEqual(lhs.re, rhs.re, maxRelDiff, maxAbsDiff)
        && approxEqual(lhs.im, rhs.im, maxRelDiff, maxAbsDiff);
}

/// Complex types works as `approxEqual(l.re, r.re) && approxEqual(l.im, r.im)`
@safe pure nothrow @nogc unittest
{
    assert(approxEqual(1.0 + 1i, 1.0000001 + 1.0000001i));
    assert(!approxEqual(100000.0L + 0i, 100001L + 0i));
}
