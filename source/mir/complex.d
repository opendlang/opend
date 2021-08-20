/++
Complex numbers

Authors: Ilya Yaroshenko
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
    import std.traits: isNumeric;

@safe pure nothrow @nogc @optmath:

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
    bool opEquals(R)(Complex!R rhs)
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
}

/// ditto
Complex!T complex(T)(const T re, const T im)
    if (is(T == float) || is(T == double) || is(T == real))
{
    return typeof(return)(re, im);
}

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
}
