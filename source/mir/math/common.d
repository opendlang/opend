/++
Common floating point math functions.

This module has generic LLVM-oriented API compatible with all D compilers.

License:   $(HTTP boost.org/LICENSE_1_0.txt, Boost License 1.0).
Copyright: Copyright © 2016-, Ilya Yaroshenko
Authors:   Ilya Yaroshenko
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
else
{
    static import std.math;
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
    alias fabs = std.math.fabs;
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
    T pow(T)(in T x, in T power) if (isFloatingPoint!T) { return std.math.pow(x, power); }
    ///
    T powi(T)(in T x, int power) if (isFloatingPoint!T) { return std.math.pow(x, power); }
    ///
    T exp(T)(in T x) if (isFloatingPoint!T) { return std.math.exp(x); }
    ///
    T log(T)(in T x) if (isFloatingPoint!T) { return std.math.log(x); }
    ///
    T fabs(T)(in T x) if (isFloatingPoint!T) { return std.math.fabs(x); }
    ///
    T floor(T)(in T x) if (isFloatingPoint!T) { return std.math.floor(x); }
    ///
    T exp2(T)(in T x) if (isFloatingPoint!T) { return std.math.exp2(x); }
    ///
    T log10(T)(in T x) if (isFloatingPoint!T) { return std.math.log10(x); }
    ///
    T log2(T)(in T x) if (isFloatingPoint!T) { return std.math.log2(x); }
    ///
    T ceil(T)(in T x) if (isFloatingPoint!T) { return std.math.ceil(x); }
    ///
    T trunc(T)(in T x) if (isFloatingPoint!T) { return std.math.trunc(x); }
    ///
    T rint(T)(in T x) if (isFloatingPoint!T) { return std.math.rint(x); }
    ///
    T nearbyint(T)(in T x) if (isFloatingPoint!T) { return std.math.nearbyint(x); }
    ///
    T copysign(T)(in T mag, in T sgn) if (isFloatingPoint!T) { return std.math.copysign(mag, sgn); }
    ///
    T round(T)(in T x) if (isFloatingPoint!T) { return std.math.round(x); }
    ///
    T fmuladd(T)(in T a, in T b, in T c) if (isFloatingPoint!T) { return a * b + c; }
    version(mir_test)
    unittest { assert(fmuladd!double(2, 3, 4) == 2 * 3 + 4); }
    ///
    T fmin(T)(in T x, in T y) if (isFloatingPoint!T) { return std.math.fmin(x, y); }
    ///
    T fmax(T)(in T x, in T y) if (isFloatingPoint!T) { return std.math.fmax(x, y); }

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
    }
}

version (mir_test)
@nogc nothrow pure @safe unittest
{
    import std.math: PI, feqrel;
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
