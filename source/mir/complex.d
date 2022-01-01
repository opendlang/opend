/++
Complex numbers

Copyright: Ilya Yaroshenko; 2010, Lars T. Kyllingstad (original Phobos code)
Authors: Ilya Yaroshenko, Lars Tandle Kyllingstad, Don Clugston
+/
module mir.complex;

import mir.math.common: optmath;

private alias CommonType(A, B) = typeof(A.init + B.init);

@optmath:

/++
Generic complex number type
+/
struct Complex(T)
    if (is(T == float) || is(T == double) || is(T == real))
{
    import mir.internal.utility: isComplex;
    import std.traits: isNumeric;

@optmath:

    /++
    Real part. Default value is zero.
    +/
    T re = 0;
    /++
    Imaginary part. Default value is zero.
    +/
    T im = 0;

    ///
    ref Complex opAssign(R)(Complex!R rhs)
        if (!is(R == T))
    {
        this.re = rhs.re;
        this.im = rhs.im;
        return this;
    }

    ///
    ref Complex opAssign(F)(const F rhs)
        if (isNumeric!F)
    {
        this.re = rhs;
        this.im = 0;
        return this;
    }

    ///
    ref Complex opOpAssign(string op : "+", R)(Complex!R rhs) return
    {
        re += rhs.re;
        im += rhs.im;
        return this;
    }

    ///
    ref Complex opOpAssign(string op : "-", R)(Complex!R rhs) return
    {
        re -= rhs.re;
        im -= rhs.im;
        return this;
    }

    ///
    ref Complex opOpAssign(string op, R)(Complex!R rhs) return
        if (op == "*" || op == "/")
    {
        return this = this.opBinary!op(rhs);
    }

    ///
    ref Complex opOpAssign(string op : "+", R)(const R rhs) return
        if (isNumeric!R)
    {
        re += rhs;
        return this;
    }

    ///
    ref Complex opOpAssign(string op : "-", R)(const R rhs) return
        if (isNumeric!R)
    {
        re -= rhs;
        return this;
    }

    ///
    ref Complex opOpAssign(string op : "*", R)(const R rhs) return
        if (isNumeric!R)
    {
        re *= rhs;
        return this;
    }

    ///
    ref Complex opOpAssign(string op : "/", R)(const R rhs) return
        if (isNumeric!R)
    {
        re /= rhs;
        return this;
    }

const:

    ///
    bool opEquals(const Complex rhs)
    {
        return re == rhs.re && im == rhs.im;
    }

    ///
    size_t toHash()
    {
        T[2] val = [re, im];
        return hashOf(val) ;
    }

scope:

    ///
    bool opEquals(R)(Complex!R rhs)
        if (!is(R == T))
    {
        return re == rhs.re && im == rhs.im;
    }

    ///
    bool opEquals(F)(const F rhs)
        if (isNumeric!F)
    {
        return re == rhs && im == 0;
    }

    ///
    Complex opUnary(string op : "+")()
    {
        return this;
    }

    ///
    Complex opUnary(string op : "-")()
    {
        return typeof(return)(-re, -im);
    }

    ///
    Complex!(CommonType!(T, R)) opBinary(string op : "+", R)(Complex!R rhs)
    {
        return typeof(return)(re + rhs.re, im + rhs.im);
    }

    ///
    Complex!(CommonType!(T, R)) opBinary(string op : "-", R)(Complex!R rhs)
    {
        return typeof(return)(re - rhs.re, im - rhs.im);
    }

    ///
    Complex!(CommonType!(T, R)) opBinary(string op : "*", R)(Complex!R rhs)
    {
        return typeof(return)(re * rhs.re - im * rhs.im, re * rhs.im + im * rhs.re);
    }

    ///
    Complex!(CommonType!(T, R)) opBinary(string op : "/", R)(Complex!R rhs)
    {
        // TODO: use more precise algorithm
        auto norm = rhs.re * rhs.re + rhs.im * rhs.im;
        return typeof(return)(
            (re * rhs.re + im * rhs.im) / norm,
            (im * rhs.re - re * rhs.im) / norm,
        );
    }

    ///
    Complex!(CommonType!(T, R)) opBinary(string op : "+", R)(const R rhs)
        if (isNumeric!R)
    {
        return typeof(return)(re + rhs, im);
    }

    ///
    Complex!(CommonType!(T, R)) opBinary(string op : "-", R)(const R rhs)
        if (isNumeric!R)
    {
        return typeof(return)(re - rhs, im);
    }

    ///
    Complex!(CommonType!(T, R)) opBinary(string op : "*", R)(const R rhs)
        if (isNumeric!R)
    {
        return typeof(return)(re * rhs, im * rhs);
    }

    ///
    Complex!(CommonType!(T, R)) opBinary(string op : "/", R)(const R rhs)
        if (isNumeric!R)
    {
        return typeof(return)(re / rhs, im / rhs);
    }


    ///
    Complex!(CommonType!(T, R)) opBinaryRight(string op : "+", R)(const R rhs)
        if (isNumeric!R)
    {
        return typeof(return)(rhs + re, im);
    }

    ///
    Complex!(CommonType!(T, R)) opBinaryRight(string op : "-", R)(const R rhs)
        if (isNumeric!R)
    {
        return typeof(return)(rhs - re, -im);
    }

    ///
    Complex!(CommonType!(T, R)) opBinaryRight(string op : "*", R)(const R rhs)
        if (isNumeric!R)
    {
        return typeof(return)(rhs * re, rhs * im);
    }

    ///
    Complex!(CommonType!(T, R)) opBinaryRight(string op : "/", R)(const R rhs)
        if (isNumeric!R)
    {
        // TODO: use more precise algorithm
        auto norm = this.re * this.re + this.im * this.im;
        return typeof(return)(
            rhs * (this.re / norm),
            -rhs * (this.im / norm),
        );
    }

    ///
    R opCast(R)()
        if (isNumeric!R || isComplex!R)
    {
        static if (isNumeric!R)
            return cast(R) re;
        else
            return R(re, im);
    }
}

/// ditto
Complex!T complex(T)(const T re, const T im = 0)
    if (is(T == float) || is(T == double) || is(T == real))
{
    return typeof(return)(re, im);
}

private alias _cdouble_ = Complex!double;
private alias _cfloat_ = Complex!float;
private alias _creal_ = Complex!real;

///
unittest
{
    auto a = complex(1.0, 3);
    auto b = a;
    b.re += 3;
    a = b;
    assert(a == b);

    a = Complex!float(5, 6);
    assert(a == Complex!real(5, 6));

    a += b;
    a -= b;
    a *= b;
    a /= b;

    a = a + b;
    a = a - b;
    a = a * b;
    a = a / b;

    a += 2;
    a -= 2;
    a *= 2;
    a /= 2;

    a = a + 2;
    a = a - 2;
    a = a * 2;
    a = a / 2;

    a = 2 + a;
    a = 2 - a;
    a = 2 * a;
    a = 2 / a;

    a = -a;
    a = +a;

    assert(a != 4.0);
    a = 4;
    assert(a == 4);
    assert(cast(int)a == 4);
    assert(cast(Complex!float)a == 4);

    import std.complex : StdComplex = Complex;
    assert(cast(StdComplex!double)a == StdComplex!double(4, 0));
}

/++
Params: z = A complex number.
Returns: The square root of `z`.
+/
Complex!T sqrt(T)(Complex!T z)  @safe pure nothrow @nogc
{
    import mir.math.common: fabs, fmin, fmax, sqrt;

    if (z == 0)
        return typeof(return)(0, 0);
    auto x = fabs(z.re);
    auto y = fabs(z.im);
    auto n = fmin(x, y);
    auto m = fmax(x, y);
    auto r = n / m;
    auto w = sqrt(m) * sqrt(0.5f * ((x >= y ? 1 : r) + sqrt(1 + r * r)));
    auto s = typeof(return)(w, z.im / (w + w));
    if (z.re < 0)
    {
        s = typeof(return)(s.im, s.re);
        if (z.im < 0)
            s = -s;
    }
    return s;
}

///
@safe pure nothrow unittest
{
    assert(sqrt(complex(0.0)) == 0.0);
    assert(sqrt(complex(1.0, 0)) == 1.0);
    assert(sqrt(complex(-1.0, 0)) == complex(0, 1.0));
    assert(sqrt(complex(-8.0, -6.0)) == complex(1.0, -3.0));
}

@safe pure nothrow unittest
{
    assert(complex(1.0, 1.0).sqrt.approxEqual(complex(1.098684113467809966, 0.455089860562227341)));
    assert(complex(0.5, 2.0).sqrt.approxEqual(complex(1.131713924277869410, 0.883615530875513265)));
}

/**
 * Calculate the natural logarithm of x.
 * The branch cut is along the negative axis.
 * Params:
 *      x = A complex number
 * Returns:
 *      The complex natural logarithm of `x`
 *
 *      $(TABLE_SV
 *      $(TR $(TH x)                           $(TH log(x)))
 *      $(TR $(TD (-0, +0))                    $(TD (-$(INFIN), $(PI))))
 *      $(TR $(TD (+0, +0))                    $(TD (-$(INFIN), +0)))
 *      $(TR $(TD (any, +$(INFIN)))            $(TD (+$(INFIN), $(PI)/2)))
 *      $(TR $(TD (any, $(NAN)))               $(TD ($(NAN), $(NAN))))
 *      $(TR $(TD (-$(INFIN), any))            $(TD (+$(INFIN), $(PI))))
 *      $(TR $(TD (+$(INFIN), any))            $(TD (+$(INFIN), +0)))
 *      $(TR $(TD (-$(INFIN), +$(INFIN)))      $(TD (+$(INFIN), 3$(PI)/4)))
 *      $(TR $(TD (+$(INFIN), +$(INFIN)))      $(TD (+$(INFIN), $(PI)/4)))
 *      $(TR $(TD ($(PLUSMN)$(INFIN), $(NAN))) $(TD (+$(INFIN), $(NAN))))
 *      $(TR $(TD ($(NAN), any))               $(TD ($(NAN), $(NAN))))
 *      $(TR $(TD ($(NAN), +$(INFIN)))         $(TD (+$(INFIN), $(NAN))))
 *      $(TR $(TD ($(NAN), $(NAN)))            $(TD ($(NAN), $(NAN))))
 *      )
 */
Complex!T log(T)(Complex!T x) @safe pure nothrow @nogc
{
    import mir.math.constant: PI, PI_4, PI_2;
    import mir.math.common: log, fabs, copysign;
    alias isNaN = x => x != x;
    alias isInfinity = x => x.fabs == T.infinity;

    // Handle special cases explicitly here for better accuracy.
    // The order here is important, so that the correct path is chosen.
    if (isNaN(x.re))
    {
        if (isInfinity(x.im))
            return Complex!T(T.infinity, T.nan);
        else
            return Complex!T(T.nan, T.nan);
    }
    if (isInfinity(x.re))
    {
        if (isNaN(x.im))
            return Complex!T(T.infinity, T.nan);
        else if (isInfinity(x.im))
        {
            if (copysign(1, x.re) < 0)
                return Complex!T(T.infinity, copysign(3.0 * PI_4, x.im));
            else
                return Complex!T(T.infinity, copysign(PI_4, x.im));
        }
        else
        {
            if (copysign(1, x.re) < 0)
                return Complex!T(T.infinity, copysign(PI, x.im));
            else
                return Complex!T(T.infinity, copysign(0.0, x.im));
        }
    }
    if (isNaN(x.im))
        return Complex!T(T.nan, T.nan);
    if (isInfinity(x.im))
        return Complex!T(T.infinity, copysign(PI_2, x.im));
    if (x.re == 0.0 && x.im == 0.0)
    {
        if (copysign(1, x.re) < 0)
            return Complex!T(-T.infinity, copysign(PI, x.im));
        else
            return Complex!T(-T.infinity, copysign(0.0, x.im));
    }

    return Complex!T(log(.fabs(x)), arg(x));
}

///
@safe pure nothrow @nogc version(mir_core_test) unittest
{
    import mir.math.common: sqrt;
    import mir.math.constant: PI;
    import mir.math.common: approxEqual;

    auto a = complex(2.0, 1.0);
    assert(log(conj(a)) == conj(log(a)));

    assert(log(complex(-1.0L, 0.0L)) == complex(0.0L, PI));
    assert(log(complex(-1.0L, -0.0L)) == complex(0.0L, -PI));
}

@safe pure nothrow @nogc version(mir_core_test) unittest
{
    import mir.math.common: fabs;
    import mir.math.constant: PI, PI_2, PI_4;
    alias isNaN = x => x != x;
    alias isInfinity = x => x.fabs == x.infinity;

    auto a = log(complex(-0.0L, 0.0L));
    assert(a == complex(-real.infinity, PI));
    auto b = log(complex(0.0L, 0.0L));
    assert(b == complex(-real.infinity, +0.0L));
    auto c = log(complex(1.0L, real.infinity));
    assert(c == complex(real.infinity, PI_2));
    auto d = log(complex(1.0L, real.nan));
    assert(isNaN(d.re) && isNaN(d.im));

    auto e = log(complex(-real.infinity, 1.0L));
    assert(e == complex(real.infinity, PI));
    auto f = log(complex(real.infinity, 1.0L));
    assert(f == complex(real.infinity, 0.0L));
    auto g = log(complex(-real.infinity, real.infinity));
    assert(g == complex(real.infinity, 3.0 * PI_4));
    auto h = log(complex(real.infinity, real.infinity));
    assert(h == complex(real.infinity, PI_4));
    auto i = log(complex(real.infinity, real.nan));
    assert(isInfinity(i.re) && isNaN(i.im));

    auto j = log(complex(real.nan, 1.0L));
    assert(isNaN(j.re) && isNaN(j.im));
    auto k = log(complex(real.nan, real.infinity));
    assert(isInfinity(k.re) && isNaN(k.im));
    auto l = log(complex(real.nan, real.nan));
    assert(isNaN(l.re) && isNaN(l.im));
}

@safe pure nothrow @nogc version(mir_core_test) unittest
{
    import mir.math.constant: PI;

    auto a = log(fromPolar(1.0, PI / 6.0));
    assert(approxEqual(a, complex(0.0L, 0.523598775598298873077L), 0.0, 1e-15));

    auto b = log(fromPolar(1.0, PI / 3.0));
    assert(approxEqual(b, complex(0.0L, 1.04719755119659774615L), 0.0, 1e-15));

    auto c = log(fromPolar(1.0, PI / 2.0));
    assert(approxEqual(c, complex(0.0L, 1.57079632679489661923L), 0.0, 1e-15));

    auto d = log(fromPolar(1.0, 2.0 * PI / 3.0));
    assert(approxEqual(d, complex(0.0L, 2.09439510239319549230L), 0.0, 1e-15));

    auto e = log(fromPolar(1.0, 5.0 * PI / 6.0));
    assert(approxEqual(e, complex(0.0L, 2.61799387799149436538L), 0.0, 1e-15));

    auto f = log(complex(-1.0L, 0.0L));
    assert(approxEqual(f, complex(0.0L, PI), 0.0, 1e-15));
}

/++
Calculates e$(SUPERSCRIPT x).
Params:
     x = A complex number
Returns:
     The complex base e exponential of `x`
     $(TABLE_SV
     $(TR $(TH x)                           $(TH exp(x)))
     $(TR $(TD ($(PLUSMN)0, +0))            $(TD (1, +0)))
     $(TR $(TD (any, +$(INFIN)))            $(TD ($(NAN), $(NAN))))
     $(TR $(TD (any, $(NAN))                $(TD ($(NAN), $(NAN)))))
     $(TR $(TD (+$(INFIN), +0))             $(TD (+$(INFIN), +0)))
     $(TR $(TD (-$(INFIN), any))            $(TD ($(PLUSMN)0, cis(x.im))))
     $(TR $(TD (+$(INFIN), any))            $(TD ($(PLUSMN)$(INFIN), cis(x.im))))
     $(TR $(TD (-$(INFIN), +$(INFIN)))      $(TD ($(PLUSMN)0, $(PLUSMN)0)))
     $(TR $(TD (+$(INFIN), +$(INFIN)))      $(TD ($(PLUSMN)$(INFIN), $(NAN))))
     $(TR $(TD (-$(INFIN), $(NAN)))         $(TD ($(PLUSMN)0, $(PLUSMN)0)))
     $(TR $(TD (+$(INFIN), $(NAN)))         $(TD ($(PLUSMN)$(INFIN), $(NAN))))
     $(TR $(TD ($(NAN), +0))                $(TD ($(NAN), +0)))
     $(TR $(TD ($(NAN), any))               $(TD ($(NAN), $(NAN))))
     $(TR $(TD ($(NAN), $(NAN)))            $(TD ($(NAN), $(NAN))))
     )
+/
Complex!T exp(T)(Complex!T x) @trusted pure nothrow @nogc // TODO: @safe
{
    import mir.math.common: exp, fabs, copysign;
    alias isNaN = x => x != x;
    alias isInfinity = x => x.fabs == T.infinity;

    // Handle special cases explicitly here, as fromPolar will otherwise
    // cause them to return Complex!T(NaN, NaN), or with the wrong sign.
    if (isInfinity(x.re))
    {
        if (isNaN(x.im))
        {
            if (copysign(1, x.re) < 0)
                return Complex!T(0, copysign(0, x.im));
            else
                return x;
        }
        if (isInfinity(x.im))
        {
            if (copysign(1, x.re) < 0)
                return Complex!T(0, copysign(0, x.im));
            else
                return Complex!T(T.infinity, -T.nan);
        }
        if (x.im == 0)
        {
            if (copysign(1, x.re) < 0)
                return Complex!T(0);
            else
                return Complex!T(T.infinity);
        }
    }
    if (isNaN(x.re))
    {
        if (isNaN(x.im) || isInfinity(x.im))
            return Complex!T(T.nan, T.nan);
        if (x.im == 0)
            return x;
    }
    if (x.re == 0)
    {
        if (isNaN(x.im) || isInfinity(x.im))
            return Complex!T(T.nan, T.nan);
        if (x.im == 0)
            return Complex!T(1, 0);
    }

    return fromPolar!T(exp(x.re), x.im);
}

///
@safe pure nothrow @nogc version(mir_core_test) unittest
{
    import mir.math.constant: PI;

    assert(exp(complex(0.0, 0.0)) == complex(1.0, 0.0));

    auto a = complex(2.0, 1.0);
    assert(exp(conj(a)) == conj(exp(a)));

    auto b = exp(complex(0.0, 1.0) * double(PI));
    assert(approxEqual(b, complex(-1.0), 0.0, 1e-15));
}

@safe pure nothrow @nogc version(mir_core_test) unittest
{
    import mir.math.common: fabs;

    alias isNaN = x => x != x;
    alias isInfinity = x => x.fabs == x.infinity;

    auto a = exp(complex(0.0, double.infinity));
    assert(isNaN(a.re) && isNaN(a.im));
    auto b = exp(complex(0.0, double.infinity));
    assert(isNaN(b.re) && isNaN(b.im));
    auto c = exp(complex(0.0, double.nan));
    assert(isNaN(c.re) && isNaN(c.im));

    auto d = exp(complex(+double.infinity, 0.0));
    assert(d == complex(double.infinity, 0.0));
    auto e = exp(complex(-double.infinity, 0.0));
    assert(e == complex(0.0));
    auto f = exp(complex(-double.infinity, 1.0));
    assert(f == complex(0.0));
    auto g = exp(complex(+double.infinity, 1.0));
    assert(g == complex(double.infinity, double.infinity));
    auto h = exp(complex(-double.infinity, +double.infinity));
    assert(h == complex(0.0));
    auto i = exp(complex(+double.infinity, +double.infinity));
    assert(isInfinity(i.re) && isNaN(i.im));
    auto j = exp(complex(-double.infinity, double.nan));
    assert(j == complex(0.0));
    auto k = exp(complex(+double.infinity, double.nan));
    assert(isInfinity(k.re) && isNaN(k.im));

    auto l = exp(complex(double.nan, 0));
    assert(isNaN(l.re) && l.im == 0.0);
    auto m = exp(complex(double.nan, 1));
    assert(isNaN(m.re) && isNaN(m.im));
    auto n = exp(complex(double.nan, double.nan));
    assert(isNaN(n.re) && isNaN(n.im));
}

@safe pure nothrow @nogc version(mir_core_test) unittest
{
    import mir.math.constant : PI;

    auto a = exp(complex(0.0, -PI));
    assert(approxEqual(a, complex(-1.0L), 0.0, 1e-15));

    auto b = exp(complex(0.0, -2.0 * PI / 3.0));
    assert(approxEqual(b, complex(-0.5L, -0.866025403784438646763L)));

    auto c = exp(complex(0.0, PI / 3.0));
    assert(approxEqual(c, complex(0.5L, 0.866025403784438646763L)));

    auto d = exp(complex(0.0, 2.0 * PI / 3.0));
    assert(approxEqual(d, complex(-0.5L, 0.866025403784438646763L)));

    auto e = exp(complex(0.0, PI));
    assert(approxEqual(e, complex(-1.0L), 0.0, 1e-15));
}

/**
  Constructs a complex number given its absolute value and argument.
  Params:
    modulus = The modulus
    argument = The argument
  Returns: The complex number with the given modulus and argument.
*/
Complex!T fromPolar(T)(const T modulus, const T argument)
    @safe pure nothrow @nogc
    if (__traits(isFloating, T))
{
    import mir.math.common: sin, cos;
    return typeof(return)(modulus * cos(argument), modulus * sin(argument));
}

///
@safe pure nothrow version(mir_core_test) unittest
{
    import mir.math : approxEqual, PI, sqrt;
    auto z = fromPolar(sqrt(2.0), double(PI / 4));
    assert(approxEqual(z.re, 1.0));
    assert(approxEqual(z.im, 1.0));
}

/++
Params: z = A complex number.
Returns: The complex conjugate of `z`.
+/
Complex!T conj(T)(Complex!T z) @safe pure nothrow @nogc
{
    return Complex!T(z.re, -z.im);
}

///
@safe pure nothrow version(mir_core_test) unittest
{
    assert(conj(complex(1.0)) == complex(1.0));
    assert(conj(complex(1.0, 2.0)) == complex(1.0, -2.0));
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
bool approxEqual(T)(Complex!T lhs, Complex!T rhs, const T maxRelDiff = 0x1p-20f, const T maxAbsDiff = 0x1p-20f)
{
    import mir.math.common: approxEqual;
    return approxEqual(lhs.re, rhs.re, maxRelDiff, maxAbsDiff)
        && approxEqual(lhs.im, rhs.im, maxRelDiff, maxAbsDiff);
}

/// Complex types works as `approxEqual(l.re, r.re) && approxEqual(l.im, r.im)`
@safe pure nothrow @nogc version(mir_core_test) unittest
{
    assert(approxEqual(complex(1.0, 1), complex(1.0000001, 1), 1.0000001));
    assert(!approxEqual(complex(100000.0, 0), complex(100001.0, 0)));
}

/**
Params: z = A complex number.
Returns: The absolute value (or modulus) of `z`.
*/
T fabs(T)(Complex!T z) @safe pure nothrow @nogc
{
    import std.math.algebraic : hypot;
    return hypot(z.re, z.im);
}

///
@safe pure nothrow version(mir_core_test) unittest
{
    import mir.math.common: sqrt;
    assert(fabs(complex(1.0)) == 1.0);
    assert(fabs(complex(0.0, 1.0)) == 1.0);
    assert(fabs(complex(1.0L, -2.0L)) == sqrt(5.0L));
}

@safe pure nothrow @nogc version(mir_core_test) unittest
{
    import mir.math.common: sqrt;
    assert(fabs(complex(0.0L, -3.2L)) == 3.2L);
    assert(fabs(complex(0.0L, 71.6L)) == 71.6L);
    assert(fabs(complex(-1.0L, 1.0L)) == sqrt(2.0L));
}

/++
Params: z = A complex number.
Returns: The argument (or phase) of `z`.
+/
T arg(T)(Complex!T z) @safe pure nothrow @nogc
{
    import std.math.trigonometry : atan2;
    return atan2(z.im, z.re);
}

///
@safe pure nothrow version(mir_core_test) unittest
{
    import mir.math.constant: PI_2, PI_4;
    assert(arg(complex(1.0)) == 0.0);
    assert(arg(complex(0.0L, 1.0L)) == PI_2);
    assert(arg(complex(1.0L, 1.0L)) == PI_4);
}
