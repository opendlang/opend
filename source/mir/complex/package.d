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


/**
Params: z = A complex number.
Returns: The absolute value (or modulus) of `z`.
*/
T cabs(T)(Complex!T z) @safe pure nothrow @nogc
{
    import std.math.algebraic : hypot;
    return hypot(z.re, z.im);
}

///
@safe pure nothrow version(mir_core_test) unittest
{
    import mir.math.common: sqrt;
    assert(cabs(complex(1.0)) == 1.0);
    assert(cabs(complex(0.0, 1.0)) == 1.0);
    assert(cabs(complex(1.0L, -2.0L)) == sqrt(5.0L));
}

@safe pure nothrow @nogc version(mir_core_test) unittest
{
    import mir.math.common: sqrt;
    assert(cabs(complex(0.0L, -3.2L)) == 3.2L);
    assert(cabs(complex(0.0L, 71.6L)) == 71.6L);
    assert(cabs(complex(-1.0L, 1.0L)) == sqrt(2.0L));
}
