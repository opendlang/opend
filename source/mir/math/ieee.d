/**
 * Base floating point routines.
 * 
 * Macros:
 *      TABLE_SV = <table border="1" cellpadding="4" cellspacing="0">
 *              <caption>Special Values</caption>
 *              $0</table>
 *      SVH = $(TR $(TH $1) $(TH $2))
 *      SV  = $(TR $(TD $1) $(TD $2))
 *      TH3 = $(TR $(TH $1) $(TH $2) $(TH $3))
 *      TD3 = $(TR $(TD $1) $(TD $2) $(TD $3))
 *      TABLE_DOMRG = <table border="1" cellpadding="4" cellspacing="0">
 *              $(SVH Domain X, Range Y)
                $(SV $1, $2)
 *              </table>
 *      DOMAIN=$1
 *      RANGE=$1
 *      NAN = $(RED NAN)
 *      SUP = <span style="vertical-align:super;font-size:smaller">$0</span>
 *      GAMMA = &#915;
 *      THETA = &theta;
 *      INTEGRAL = &#8747;
 *      INTEGRATE = $(BIG &#8747;<sub>$(SMALL $1)</sub><sup>$2</sup>)
 *      POWER = $1<sup>$2</sup>
 *      SUB = $1<sub>$2</sub>
 *      BIGSUM = $(BIG &Sigma; <sup>$2</sup><sub>$(SMALL $1)</sub>)
 *      CHOOSE = $(BIG &#40;) <sup>$(SMALL $1)</sup><sub>$(SMALL $2)</sub> $(BIG &#41;)
 *      PLUSMN = &plusmn;
 *      INFIN = &infin;
 *      PLUSMNINF = &plusmn;&infin;
 *      PI = &pi;
 *      LT = &lt;
 *      GT = &gt;
 *      SQRT = &radic;
 *      HALF = &frac12;
 *
 * Copyright: Copyright The D Language Foundation 2000 - 2011.
 * License:   $(HTTP www.boost.org/LICENSE_1_0.txt, Boost License 1.0).
 * Authors:   $(HTTP digitalmars.com, Walter Bright), Don Clugston, Ilya Yaroshenko
 */
module mir.math.ieee;

import mir.internal.utility: isFloatingPoint;

/*********************************
 * Return 1 if sign bit of e is set, 0 if not.
 */
int signbit(T)(const T x) @nogc @trusted pure nothrow
{
    mixin floatTraits!T;
    static if (realFormat == RealFormat.ieeeSingle)
    {
        return ((*cast(uint*)&x) & 0x8000_0000) != 0;
    }
    else 
    static if (realFormat == RealFormat.ieeeDouble)
    {
        return ((*cast(ulong*)&x) & 0x8000_0000_0000_0000) != 0;
    }
    else 
    static if (realFormat == RealFormat.ieeeQuadruple)
    {
        return ((cast(ulong*)&x)[MANTISSA_MSB] & 0x8000_0000_0000_0000) != 0;
    }
    else static if (realFormat == RealFormat.ieeeExtended)
    {
        version (LittleEndian)
            auto mp = cast(ubyte*)&x + 9;
        else
            auto mp = cast(ubyte*)&x;

        return (*mp & 0x80) != 0;
    }
    else static assert(0, "signbit is not implemented.");
}

///
@nogc @safe pure nothrow unittest
{
    assert(!signbit(float.nan));
    assert(signbit(-float.nan));
    assert(!signbit(168.1234f));
    assert(signbit(-168.1234f));
    assert(!signbit(0.0f));
    assert(signbit(-0.0f));
    assert(signbit(-float.max));
    assert(!signbit(float.max));

    assert(!signbit(double.nan));
    assert(signbit(-double.nan));
    assert(!signbit(168.1234));
    assert(signbit(-168.1234));
    assert(!signbit(0.0));
    assert(signbit(-0.0));
    assert(signbit(-double.max));
    assert(!signbit(double.max));

    assert(!signbit(real.nan));
    assert(signbit(-real.nan));
    assert(!signbit(168.1234L));
    assert(signbit(-168.1234L));
    assert(!signbit(0.0L));
    assert(signbit(-0.0L));
    assert(signbit(-real.max));
    assert(!signbit(real.max));
}

/**************************************
 * To what precision is x equal to y?
 *
 * Returns: the number of mantissa bits which are equal in x and y.
 * eg, 0x1.F8p+60 and 0x1.F1p+60 are equal to 5 bits of precision.
 *
 *      $(TABLE_SV
 *      $(TR $(TH x)      $(TH y)          $(TH feqrel(x, y)))
 *      $(TR $(TD x)      $(TD x)          $(TD real.mant_dig))
 *      $(TR $(TD x)      $(TD $(GT)= 2*x) $(TD 0))
 *      $(TR $(TD x)      $(TD $(LT)= x/2) $(TD 0))
 *      $(TR $(TD $(NAN)) $(TD any)        $(TD 0))
 *      $(TR $(TD any)    $(TD $(NAN))     $(TD 0))
 *      )
 */
int feqrel(T)(const T x, const T y) @trusted pure nothrow @nogc
    if (isFloatingPoint!T)
{
    /* Public Domain. Author: Don Clugston, 18 Aug 2005.
     */
    mixin floatTraits!T;
    static if (realFormat == RealFormat.ieeeSingle
            || realFormat == RealFormat.ieeeDouble
            || realFormat == RealFormat.ieeeExtended
            || realFormat == RealFormat.ieeeQuadruple)
    {
        import mir.math.common: fabs;

        if (x == y)
            return T.mant_dig; // ensure diff != 0, cope with IN

        auto diff = fabs(x - y);

        int a = ((cast(U*)&   x)[idx] & exp_mask) >>> exp_shft;
        int b = ((cast(U*)&   y)[idx] & exp_mask) >>> exp_shft;
        int d = ((cast(U*)&diff)[idx] & exp_mask) >>> exp_shft;


        // The difference in abs(exponent) between x or y and abs(x-y)
        // is equal to the number of significand bits of x which are
        // equal to y. If negative, x and y have different exponents.
        // If positive, x and y are equal to 'bitsdiff' bits.
        // AND with 0x7FFF to form the absolute value.
        // To avoid out-by-1 errors, we subtract 1 so it rounds down
        // if the exponents were different. This means 'bitsdiff' is
        // always 1 lower than we want, except that if bitsdiff == 0,
        // they could have 0 or 1 bits in common.

        int bitsdiff = ((a + b - 1) >> 1) - d;
        if (d == 0)
        {   // Difference is subnormal
            // For subnormals, we need to add the number of zeros that
            // lie at the start of diff's significand.
            // We do this by multiplying by 2^^real.mant_dig
            diff *= norm_factor;
            return bitsdiff + T.mant_dig - int(((cast(U*)&diff)[idx] & exp_mask) >>> exp_shft);
        }

        if (bitsdiff > 0)
            return bitsdiff + 1; // add the 1 we subtracted before

        // Avoid out-by-1 errors when factor is almost 2.
        if (bitsdiff == 0 && (a ^ b) == 0)
            return 1;
        else
            return 0;
    }
    else
    {
        static assert(false, "Not implemented for this architecture");
    }
}

///
@safe pure unittest
{
    assert(feqrel(2.0, 2.0) == 53);
    assert(feqrel(2.0f, 2.0f) == 24);
    assert(feqrel(2.0, double.nan) == 0);

    // Test that numbers are within n digits of each
    // other by testing if feqrel > n * log2(10)

    // five digits
    assert(feqrel(2.0, 2.00001) > 16);
    // ten digits
    assert(feqrel(2.0, 2.00000000001) > 33);
}

@safe pure nothrow @nogc unittest
{
    void testFeqrel(F)()
    {
       // Exact equality
       assert(feqrel(F.max, F.max) == F.mant_dig);
       assert(feqrel!(F)(0.0, 0.0) == F.mant_dig);
       assert(feqrel(F.infinity, F.infinity) == F.mant_dig);

       // a few bits away from exact equality
       F w=1;
       for (int i = 1; i < F.mant_dig - 1; ++i)
       {
          assert(feqrel!(F)(1.0 + w * F.epsilon, 1.0) == F.mant_dig-i);
          assert(feqrel!(F)(1.0 - w * F.epsilon, 1.0) == F.mant_dig-i);
          assert(feqrel!(F)(1.0, 1 + (w-1) * F.epsilon) == F.mant_dig - i + 1);
          w*=2;
       }

       assert(feqrel!(F)(1.5+F.epsilon, 1.5) == F.mant_dig-1);
       assert(feqrel!(F)(1.5-F.epsilon, 1.5) == F.mant_dig-1);
       assert(feqrel!(F)(1.5-F.epsilon, 1.5+F.epsilon) == F.mant_dig-2);


       // Numbers that are close
       assert(feqrel!(F)(0x1.Bp+84, 0x1.B8p+84) == 5);
       assert(feqrel!(F)(0x1.8p+10, 0x1.Cp+10) == 2);
       assert(feqrel!(F)(1.5 * (1 - F.epsilon), 1.0L) == 2);
       assert(feqrel!(F)(1.5, 1.0) == 1);
       assert(feqrel!(F)(2 * (1 - F.epsilon), 1.0L) == 1);

       // Factors of 2
       assert(feqrel(F.max, F.infinity) == 0);
       assert(feqrel!(F)(2 * (1 - F.epsilon), 1.0L) == 1);
       assert(feqrel!(F)(1.0, 2.0) == 0);
       assert(feqrel!(F)(4.0, 1.0) == 0);

       // Extreme inequality
       assert(feqrel(F.nan, F.nan) == 0);
       assert(feqrel!(F)(0.0L, -F.nan) == 0);
       assert(feqrel(F.nan, F.infinity) == 0);
       assert(feqrel(F.infinity, -F.infinity) == 0);
       assert(feqrel(F.max, -F.max) == 0);

       assert(feqrel(F.min_normal / 8, F.min_normal / 17) == 3);

       const F Const = 2;
       immutable F Immutable = 2;
       auto Compiles = feqrel(Const, Immutable);
    }

    assert(feqrel(7.1824L, 7.1824L) == real.mant_dig);

    testFeqrel!(float)();
    testFeqrel!(double)();
    testFeqrel!(real)();
}

/++
+/
enum RealFormat
{
    ///
    ieeeHalf,
    ///
    ieeeSingle,
    ///
    ieeeDouble,
    /// x87 80-bit real
    ieeeExtended,
    /// x87 real rounded to precision of double.
    ieeeExtended53,
    /// IBM 128-bit extended
    ibmExtended,
    ///
    ieeeQuadruple,
}

/**
 * Calculate the next largest floating point value after x.
 *
 * Return the least number greater than x that is representable as a real;
 * thus, it gives the next point on the IEEE number line.
 *
 *  $(TABLE_SV
 *    $(SVH x,            nextUp(x)   )
 *    $(SV  -$(INFIN),    -real.max   )
 *    $(SV  $(PLUSMN)0.0, real.min_normal*real.epsilon )
 *    $(SV  real.max,     $(INFIN) )
 *    $(SV  $(INFIN),     $(INFIN) )
 *    $(SV  $(NAN),       $(NAN)   )
 * )
 */
T nextUp(T)(const T x) @trusted pure nothrow @nogc
    if (isFloatingPoint!T)
{
    mixin floatTraits!T;
    static if (realFormat == RealFormat.ieeeSingle)
    {
        uint s = *cast(uint*)&x;
        if ((s & 0x7F80_0000) == 0x7F80_0000)
        {
            // First, deal with NANs and infinity
            if (x == -x.infinity) return -x.max;

            return x; // +INF and NAN are unchanged.
        }
        if (s > 0x8000_0000)   // Negative number
        {
            --s;
        }
        else
        if (s == 0x8000_0000) // it was negative zero
        {
            s = 0x0000_0001; // change to smallest subnormal
        }
        else
        {
            // Positive number
            ++s;
        }
    R:
        return *cast(T*)&s;
    }
    else static if (realFormat == RealFormat.ieeeDouble)
    {
        ulong s = *cast(ulong*)&x;

        if ((s & 0x7FF0_0000_0000_0000) == 0x7FF0_0000_0000_0000)
        {
            // First, deal with NANs and infinity
            if (x == -x.infinity) return -x.max;
            return x; // +INF and NAN are unchanged.
        }
        if (s > 0x8000_0000_0000_0000)   // Negative number
        {
            --s;
        }
        else
        if (s == 0x8000_0000_0000_0000) // it was negative zero
        {
            s = 0x0000_0000_0000_0001; // change to smallest subnormal
        }
        else
        {
            // Positive number
            ++s;
        }
    R:
        return *cast(T*)&s;
    }
    else static if (realFormat == RealFormat.ieeeQuadruple)
    {
        auto e = exp_mask & (cast(U *)&x)[idx];
        if (e == exp_mask)
        {
            // NaN or Infinity
            if (x == -real.infinity) return -real.max;
            return x; // +Inf and NaN are unchanged.
        }

        auto ps = cast(ulong *)&x;
        if (ps[MANTISSA_MSB] & 0x8000_0000_0000_0000)
        {
            // Negative number
            if (ps[MANTISSA_LSB] == 0 && ps[MANTISSA_MSB] == 0x8000_0000_0000_0000)
            {
                // it was negative zero, change to smallest subnormal
                ps[MANTISSA_LSB] = 1;
                ps[MANTISSA_MSB] = 0;
                return x;
            }
            if (ps[MANTISSA_LSB] == 0) --ps[MANTISSA_MSB];
            --ps[MANTISSA_LSB];
        }
        else
        {
            // Positive number
            ++ps[MANTISSA_LSB];
            if (ps[MANTISSA_LSB] == 0) ++ps[MANTISSA_MSB];
        }
        return x;
    }
    else static if (realFormat == RealFormat.ieeeExtended)
    {
        // For 80-bit reals, the "implied bit" is a nuisance...
        auto pe = cast(U*)&x + idx;
        version (LittleEndian)
            auto ps = cast(ulong*)&x;
        else
            auto ps = cast(ulong*)((cast(ushort*)&x) + 1);

        if ((*pe & exp_mask) == exp_mask)
        {
            // First, deal with NANs and infinity
            if (x == -real.infinity) return -real.max;
            return x; // +Inf and NaN are unchanged.
        }
        if (*pe & 0x8000)
        {
            // Negative number -- need to decrease the significand
            --*ps;
            // Need to mask with 0x7FF.. so subnormals are treated correctly.
            if ((*ps & 0x7FFF_FFFF_FFFF_FFFF) == 0x7FFF_FFFF_FFFF_FFFF)
            {
                if (*pe == 0x8000)   // it was negative zero
                {
                    *ps = 1;
                    *pe = 0; // smallest subnormal.
                    return x;
                }

                --*pe;

                if (*pe == 0x8000)
                    return x; // it's become a subnormal, implied bit stays low.

                *ps = 0xFFFF_FFFF_FFFF_FFFF; // set the implied bit
                return x;
            }
            return x;
        }
        else
        {
            // Positive number -- need to increase the significand.
            // Works automatically for positive zero.
            ++*ps;
            if ((*ps & 0x7FFF_FFFF_FFFF_FFFF) == 0)
            {
                // change in exponent
                ++*pe;
                *ps = 0x8000_0000_0000_0000; // set the high bit
            }
        }
        return x;
    }
    else // static if (realFormat == RealFormat.ibmExtended)
    {
        assert(0, "nextUp not implemented");
    }
}

///
@safe @nogc pure nothrow unittest
{
    assert(nextUp(1.0 - 1.0e-6).feqrel(0.999999) > 16);
    assert(nextUp(1.0 - real.epsilon).feqrel(1.0) > 16);
}

/**
 * Calculate the next smallest floating point value before x.
 *
 * Return the greatest number less than x that is representable as a real;
 * thus, it gives the previous point on the IEEE number line.
 *
 *  $(TABLE_SV
 *    $(SVH x,            nextDown(x)   )
 *    $(SV  $(INFIN),     real.max  )
 *    $(SV  $(PLUSMN)0.0, -real.min_normal*real.epsilon )
 *    $(SV  -real.max,    -$(INFIN) )
 *    $(SV  -$(INFIN),    -$(INFIN) )
 *    $(SV  $(NAN),       $(NAN)    )
 * )
 */
T nextDown(T)(const T x) @safe pure nothrow @nogc
{
    return -nextUp(-x);
}

///
@safe pure nothrow @nogc unittest
{
    assert( nextDown(1.0 + real.epsilon) == 1.0);
}

@safe pure nothrow @nogc unittest
{
    import std.math: NaN, isIdentical;

    static if (floatTraits!(real).realFormat == RealFormat.ieeeExtended)
    {

        // Tests for 80-bit reals
        assert(isIdentical(nextUp(NaN(0xABC)), NaN(0xABC)));
        // negative numbers
        assert( nextUp(-real.infinity) == -real.max );
        assert( nextUp(-1.0L-real.epsilon) == -1.0 );
        assert( nextUp(-2.0L) == -2.0 + real.epsilon);
        // subnormals and zero
        assert( nextUp(-real.min_normal) == -real.min_normal*(1-real.epsilon) );
        assert( nextUp(-real.min_normal*(1-real.epsilon)) == -real.min_normal*(1-2*real.epsilon) );
        assert( isIdentical(-0.0L, nextUp(-real.min_normal*real.epsilon)) );
        assert( nextUp(-0.0L) == real.min_normal*real.epsilon );
        assert( nextUp(0.0L) == real.min_normal*real.epsilon );
        assert( nextUp(real.min_normal*(1-real.epsilon)) == real.min_normal );
        assert( nextUp(real.min_normal) == real.min_normal*(1+real.epsilon) );
        // positive numbers
        assert( nextUp(1.0L) == 1.0 + real.epsilon );
        assert( nextUp(2.0L-real.epsilon) == 2.0 );
        assert( nextUp(real.max) == real.infinity );
        assert( nextUp(real.infinity)==real.infinity );
    }

    double n = NaN(0xABC);
    assert(isIdentical(nextUp(n), n));
    // negative numbers
    assert( nextUp(-double.infinity) == -double.max );
    assert( nextUp(-1-double.epsilon) == -1.0 );
    assert( nextUp(-2.0) == -2.0 + double.epsilon);
    // subnormals and zero

    assert( nextUp(-double.min_normal) == -double.min_normal*(1-double.epsilon) );
    assert( nextUp(-double.min_normal*(1-double.epsilon)) == -double.min_normal*(1-2*double.epsilon) );
    assert( isIdentical(-0.0, nextUp(-double.min_normal*double.epsilon)) );
    assert( nextUp(0.0) == double.min_normal*double.epsilon );
    assert( nextUp(-0.0) == double.min_normal*double.epsilon );
    assert( nextUp(double.min_normal*(1-double.epsilon)) == double.min_normal );
    assert( nextUp(double.min_normal) == double.min_normal*(1+double.epsilon) );
    // positive numbers
    assert( nextUp(1.0) == 1.0 + double.epsilon );
    assert( nextUp(2.0-double.epsilon) == 2.0 );
    assert( nextUp(double.max) == double.infinity );

    float fn = NaN(0xABC);
    assert(isIdentical(nextUp(fn), fn));
    float f = -float.min_normal*(1-float.epsilon);
    float f1 = -float.min_normal;
    assert( nextUp(f1) ==  f);
    f = 1.0f+float.epsilon;
    f1 = 1.0f;
    assert( nextUp(f1) == f );
    f1 = -0.0f;
    assert( nextUp(f1) == float.min_normal*float.epsilon);
    assert( nextUp(float.infinity)==float.infinity );

    assert(nextDown(1.0L+real.epsilon)==1.0);
    assert(nextDown(1.0+double.epsilon)==1.0);
    f = 1.0f+float.epsilon;
    assert(nextDown(f)==1.0);
}

/++
Return the value that lies halfway between x and y on the IEEE number line.

Formally, the result is the arithmetic mean of the binary significands of x
and y, multiplied by the geometric mean of the binary exponents of x and y.
x and y must not be NaN.
Note: this function is useful for ensuring O(log n) behaviour in algorithms
involving a 'binary chop'.

Params:
    xx = x value
    yy = y value

Special cases:
If x and y not null and have opposite sign bits, then `copysign(T(0), y)` is returned.
If x and y are within a factor of 2 and have the same sign, (ie, feqrel(x, y) > 0), the return value
is the arithmetic mean (x + y) / 2.
If x and y are even powers of 2 and have the same sign, the return value is the geometric mean,
ieeeMean(x, y) = sgn(x) * sqrt(fabs(x * y)).
+/
T ieeeMean(T)(const T xx, const T yy) @trusted pure nothrow @nogc
in
{
    assert(xx == xx && yy == yy);
}
do
{
    import mir.math.common: copysign;
    T x = xx;
    T y = yy;

    if (x == 0)
    {
        x = copysign(T(0), y);
    }
    else
    if (y == 0)
    {
        y = copysign(T(0), x);
    }
    else
    if (signbit(x) != signbit(y))
    {
        return copysign(T(0), y);
    }

    // The implementation is simple: cast x and y to integers,
    // average them (avoiding overflow), and cast the result back to a floating-point number.

    mixin floatTraits!(T);
    T u = 0;
    static if (realFormat == RealFormat.ieeeExtended)
    {
        // There's slight additional complexity because they are actually
        // 79-bit reals...
        ushort *ue = cast(ushort *)&u + idx;
        int ye = (cast(ushort *)&y)[idx];
        int xe = (cast(ushort *)&x)[idx];

        version (LittleEndian)
        {
            ulong *ul = cast(ulong *)&u;
            ulong xl = *cast(ulong *)&x;
            ulong yl = *cast(ulong *)&y;
        }
        else
        {
            ulong *ul = cast(ulong *)(cast(short *)&u + 1);
            ulong xl = *cast(ulong *)(cast(short *)&x + 1);
            ulong yl = *cast(ulong *)(cast(short *)&y + 1);
        }

        // Ignore the useless implicit bit. (Bonus: this prevents overflows)
        ulong m = (xl & 0x7FFF_FFFF_FFFF_FFFFL) + (yl & 0x7FFF_FFFF_FFFF_FFFFL);

        int e = ((xe & exp_mask) + (ye & exp_mask));
        if (m & 0x8000_0000_0000_0000L)
        {
            ++e;
            m &= 0x7FFF_FFFF_FFFF_FFFFL;
        }
        // Now do a multi-byte right shift
        const uint c = e & 1; // carry
        e >>= 1;
        m >>>= 1;
        if (c)
            m |= 0x4000_0000_0000_0000L; // shift carry into significand
        if (e)
            *ul = m | 0x8000_0000_0000_0000L; // set implicit bit...
        else
            *ul = m; // ... unless exponent is 0 (subnormal or zero).

        *ue = cast(ushort) (e | (xe & 0x8000)); // restore sign bit
    }
    else static if (realFormat == RealFormat.ieeeQuadruple)
    {
        // This would be trivial if 'ucent' were implemented...
        ulong *ul = cast(ulong *)&u;
        ulong *xl = cast(ulong *)&x;
        ulong *yl = cast(ulong *)&y;

        // Multi-byte add, then multi-byte right shift.
        import core.checkedint: addu;
        bool carry;
        ulong ml = addu(xl[MANTISSA_LSB], yl[MANTISSA_LSB], carry);

        ulong mh = carry + (xl[MANTISSA_MSB] & 0x7FFF_FFFF_FFFF_FFFFL) +
            (yl[MANTISSA_MSB] & 0x7FFF_FFFF_FFFF_FFFFL);

        ul[MANTISSA_MSB] = (mh >>> 1) | (xl[MANTISSA_MSB] & 0x8000_0000_0000_0000);
        ul[MANTISSA_LSB] = (ml >>> 1) | (mh & 1) << 63;
    }
    else static if (realFormat == RealFormat.ieeeDouble)
    {
        ulong *ul = cast(ulong *)&u;
        ulong *xl = cast(ulong *)&x;
        ulong *yl = cast(ulong *)&y;
        ulong m = (((*xl) & 0x7FFF_FFFF_FFFF_FFFFL)
                   + ((*yl) & 0x7FFF_FFFF_FFFF_FFFFL)) >>> 1;
        m |= ((*xl) & 0x8000_0000_0000_0000L);
        *ul = m;
    }
    else static if (realFormat == RealFormat.ieeeSingle)
    {
        uint *ul = cast(uint *)&u;
        uint *xl = cast(uint *)&x;
        uint *yl = cast(uint *)&y;
        uint m = (((*xl) & 0x7FFF_FFFF) + ((*yl) & 0x7FFF_FFFF)) >>> 1;
        m |= ((*xl) & 0x8000_0000);
        *ul = m;
    }
    else
    {
        assert(0, "Not implemented");
    }
    return u;
}

@safe pure nothrow @nogc unittest
{
    assert(ieeeMean(-0.0,-1e-20)<0);
    assert(ieeeMean(0.0,1e-20)>0);

    assert(ieeeMean(1.0L,4.0L)==2L);
    assert(ieeeMean(2.0*1.013,8.0*1.013)==4*1.013);
    assert(ieeeMean(-1.0L,-4.0L)==-2L);
    assert(ieeeMean(-1.0,-4.0)==-2);
    assert(ieeeMean(-1.0f,-4.0f)==-2f);
    assert(ieeeMean(-1.0,-2.0)==-1.5);
    assert(ieeeMean(-1*(1+8*real.epsilon),-2*(1+8*real.epsilon))
                 ==-1.5*(1+5*real.epsilon));
    assert(ieeeMean(0x1p60,0x1p-10)==0x1p25);

    static if (floatTraits!(real).realFormat == RealFormat.ieeeExtended)
    {
      assert(ieeeMean(1.0L,real.infinity)==0x1p8192L);
      assert(ieeeMean(0.0L,real.infinity)==1.5);
    }
    assert(ieeeMean(0.5*real.min_normal*(1-4*real.epsilon),0.5*real.min_normal)
           == 0.5*real.min_normal*(1-2*real.epsilon));
}

/*********************************************************************
 * Separate floating point value into significand and exponent.
 *
 * Returns:
 *      Calculate and return $(I x) and $(I exp) such that
 *      value =$(I x)*2$(SUPERSCRIPT exp) and
 *      .5 $(LT)= |$(I x)| $(LT) 1.0
 *
 *      $(I x) has same sign as value.
 *
 *      $(TABLE_SV
 *      $(TR $(TH value)           $(TH returns)         $(TH exp))
 *      $(TR $(TD $(PLUSMN)0.0)    $(TD $(PLUSMN)0.0)    $(TD 0))
 *      $(TR $(TD +$(INFIN))       $(TD +$(INFIN))       $(TD int.max))
 *      $(TR $(TD -$(INFIN))       $(TD -$(INFIN))       $(TD int.min))
 *      $(TR $(TD $(PLUSMN)$(NAN)) $(TD $(PLUSMN)$(NAN)) $(TD int.min))
 *      )
 */
T frexp(T)(const T value, ref int exp) @trusted pure nothrow @nogc
if (isFloatingPoint!T)
{
    import mir.utility: _expect;

    with(floatTraits!T) static if (
        realFormat == RealFormat.ieeeExtended
     || realFormat == RealFormat.ieeeQuadruple
     || realFormat == RealFormat.ieeeDouble
     || realFormat == RealFormat.ieeeSingle)
    {
        T vf = value;
        S u = (cast(U*)&vf)[idx];
        int e = (u & exp_mask) >>> exp_shft;
        if (_expect(e, true)) // If exponent is non-zero
        {
            if (_expect(e == exp_msh, false))
                goto R;
            exp = e + (T.min_exp - 1);
        }
        else
        {
            static if (realFormat == RealFormat.ieeeExtended)
            {
                version (LittleEndian)
                    auto mp = cast(ulong*)&vf;
                else
                    auto mp = cast(ulong*)((cast(ushort*)&vf) + 1);
                auto m = u & man_mask | *mp;
            }
            else
            {
                auto m = u & man_mask;
                static if (T.sizeof > U.sizeof)
                    m |= (cast(U*)&vf)[MANTISSA_LSB];
            }
            if (!m)
            {
                exp = 0;
                goto R;
            }
            vf *= norm_factor;
            u = (cast(U*)&vf)[idx];
            e = (u & exp_mask) >>> exp_shft;
            exp = e + (T.min_exp - T.mant_dig);
        }
        u &= ~exp_mask;
        u ^= exp_nrm;
        (cast(U*)&vf)[idx] = cast(U)u;
    R:
        return vf;
    }
    else // static if (realFormat == RealFormat.ibmExtended)
    {
        static assert(0, "frexp not implemented");
    }
}

///
@safe unittest
{
    import mir.math.common: pow, approxEqual;
    alias isNaN = x => x != x;
    int exp;
    real mantissa = frexp(123.456L, exp);

    assert(approxEqual(mantissa * pow(2.0L, cast(real) exp), 123.456L));

    exp = 1234; // random number
    assert(isNaN(frexp(-real.nan, exp)) && exp == 1234);
    assert(isNaN(frexp(real.nan, exp)) && exp == 1234);
    assert(frexp(-real.infinity, exp) == -real.infinity && exp == 1234);
    assert(frexp(real.infinity, exp) == real.infinity && exp == 1234);

    assert(frexp(-0.0, exp) == -0.0 && exp == 0);
    assert(frexp(0.0, exp) == 0.0 && exp == 0);
}

@safe @nogc nothrow unittest
{
    import mir.math.common: pow;
    int exp;
    real mantissa = frexp(123.456L, exp);

    assert(mantissa * pow(2.0L, cast(real) exp) == 123.456L);
}

@safe unittest
{
    import std.meta : AliasSeq;
    import std.typecons : tuple, Tuple;

    static foreach (T; AliasSeq!(float, double, real))
    {{
        enum randomNumber = 12345;
        Tuple!(T, T, int)[] vals =     // x,frexp,exp
            [
             tuple(T(0.0),  T( 0.0 ), 0),
             tuple(T(-0.0), T( -0.0), 0),
             tuple(T(1.0),  T( .5  ), 1),
             tuple(T(-1.0), T( -.5 ), 1),
             tuple(T(2.0),  T( .5  ), 2),
             tuple(T(float.min_normal/2.0f), T(.5), -126),
             tuple(T.infinity, T.infinity, randomNumber),
             tuple(-T.infinity, -T.infinity, randomNumber),
             tuple(T.nan, T.nan, randomNumber),
             tuple(-T.nan, -T.nan, randomNumber),

             // Phobos issue #16026:
             tuple(3 * (T.min_normal * T.epsilon), T( .75), (T.min_exp - T.mant_dig) + 2)
             ];

        foreach (i, elem; vals)
        {
            T x = elem[0];
            T e = elem[1];
            int exp = elem[2];
            int eptr = randomNumber;
            T v = frexp(x, eptr);
            assert(e == v || (e != e && v != v));
            assert(exp == eptr);

        }

        static if (floatTraits!(T).realFormat == RealFormat.ieeeExtended)
        {
            static T[3][] extendedvals = [ // x,frexp,exp
                [0x1.a5f1c2eb3fe4efp+73L,    0x1.A5F1C2EB3FE4EFp-1L,     74],    // normal
                [0x1.fa01712e8f0471ap-1064L, 0x1.fa01712e8f0471ap-1L, -1063],
                [T.min_normal,      .5, -16381],
                [T.min_normal/2.0L, .5, -16382]    // subnormal
            ];
            foreach (elem; extendedvals)
            {
                T x = elem[0];
                T e = elem[1];
                int exp = cast(int) elem[2];
                int eptr;
                T v = frexp(x, eptr);
                assert(e == v);
                assert(exp == eptr);

            }
        }
    }}
}

@safe unittest
{
    import std.meta : AliasSeq;
    void foo() {
        static foreach (T; AliasSeq!(real, double, float))
        {{
            int exp;
            const T a = 1;
            immutable T b = 2;
            auto c = frexp(a, exp);
            auto d = frexp(b, exp);
        }}
    }
}

/*******************************************
 * Returns: n * 2$(SUPERSCRIPT exp)
 * See_Also: $(LERF frexp)
 */
T ldexp(T)(const T n, int exp) @nogc @trusted pure nothrow
    if (isFloatingPoint!T)
{
    import mir.math.common: copysign;
    import mir.checkedint: adds, subs;
    import mir.utility: _expect;
    enum norm_factor = 1 / T.epsilon;
    T vf = n;
    mixin floatTraits!T;

    version(LDC)
    {
        static if (realFormat == RealFormat.ieeeExtended)
        {
            if (!__ctfe)
            {
                import core.math: ldexp;
                return ldexp(n, exp);
            }
        }
    }

    static if (realFormat == RealFormat.ieeeExtended || realFormat == RealFormat.ieeeQuadruple || realFormat == RealFormat.ieeeDouble || realFormat == RealFormat.ieeeSingle)
    {
        auto u = (cast(U*)&vf)[idx];
        int e = (u & exp_mask) >> exp_shft;
        if (_expect(e != exp_msh, true))
        {
            if (_expect(e == 0, false)) // subnormals input
            {
                bool overflow;
                vf *= norm_factor;
                u = (cast(U*)&vf)[idx];
                e = int((u & exp_mask) >> exp_shft) - (T.mant_dig - 1);
            }
            bool overflow;
            exp = adds(exp, e, overflow);
            if (_expect(overflow || exp >= exp_msh, false)) // infs
            {
                static if (realFormat == RealFormat.ieeeExtended)
                {
                    return vf * T.infinity;
                }
                else
                {
                    u &= sig_mask;
                    u ^= exp_mask;
                    static if (realFormat == RealFormat.ieeeExtended)
                    {
                        version (LittleEndian)
                            auto mp = cast(ulong*)&vf;
                        else
                            auto mp = cast(ulong*)((cast(ushort*)&vf) + 1);
                        *mp = 0;
                    }
                    else
                    static if (T.sizeof > U.sizeof)
                    {
                        (cast(U*)&vf)[MANTISSA_LSB] = 0;
                    }
                }
            }
            else
            if (_expect(exp > 0, true)) // normal
            {
                u = cast(U)((u & ~exp_mask) ^ (cast(typeof(U.init + 0))exp << exp_shft));
            }
            else // subnornmal output
            {
                exp = 1 - exp;
                static if (realFormat != RealFormat.ieeeExtended)
                {                    
                    auto m = u & man_mask;
                    if (exp > T.mant_dig)
                    {
                        exp = T.mant_dig;
                        static if (T.sizeof > U.sizeof)
                            (cast(U*)&vf)[MANTISSA_LSB] = 0;
                    }
                }
                u &= sig_mask;
                static if (realFormat == RealFormat.ieeeExtended)
                {
                    version (LittleEndian)
                        auto mp = cast(ulong*)&vf;
                    else
                        auto mp = cast(ulong*)((cast(ushort*)&vf) + 1);
                    if (exp >= ulong.sizeof * 8)
                        *mp = 0;
                    else
                        *mp >>>= exp;
                }
                else
                {
                    m ^= intPartMask;
                    static if (T.sizeof > U.sizeof)
                    {
                        int exp2 = exp - U.sizeof * 8;
                        if (exp2 < 0)
                        {
                            (cast(U*)&vf)[MANTISSA_LSB] = ((cast(U*)&vf)[MANTISSA_LSB] >> exp) ^ (m << (U.sizeof * 8 - exp));
                            m >>>= exp;
                            u ^= cast(U) m;
                        }
                        else
                        {
                            exp = exp2;
                            (cast(U*)&vf)[MANTISSA_LSB] = (exp < U.sizeof * 8) ? m >> exp : 0;
                        }
                    }
                    else
                    {
                        m >>>= exp;
                        u ^= cast(U) m;
                    }
                }
            }
            (cast(U*)&vf)[idx] = u;
        }
        return vf;
    }
    else
    {
        static assert(0, "ldexp not implemented");
    }
}

///
@nogc @safe pure nothrow unittest
{
    import std.meta : AliasSeq;
    static foreach (T; AliasSeq!(float, double, real))
    {{
        T r = ldexp(cast(T) 3.0, cast(int) 3);
        assert(r == 24);

        T n = 3.0;
        int exp = 3;
        r = ldexp(n, exp);
        assert(r == 24);
    }}
}

@safe pure nothrow @nogc unittest
{
    import mir.math.common;
    {
        assert(ldexp(1.0, -1024) == 0x1p-1024);
        assert(ldexp(1.0, -1022) == 0x1p-1022);
        int x;
        double n = frexp(0x1p-1024L, x);
        assert(n == 0.5);
        assert(x==-1023);
        assert(ldexp(n, x)==0x1p-1024);
    }
    static if (floatTraits!(real).realFormat == RealFormat.ieeeExtended ||
               floatTraits!(real).realFormat == RealFormat.ieeeQuadruple)
    {
        assert(ldexp(1.0L, -16384) == 0x1p-16384L);
        assert(ldexp(1.0L, -16382) == 0x1p-16382L);
        int x;
        real n = frexp(0x1p-16384L, x);
        assert(n == 0.5L);
        assert(x==-16383);
        assert(ldexp(n, x)==0x1p-16384L);
    }
}

/* workaround Issue 14718, float parsing depends on platform strtold
@safe pure nothrow @nogc unittest
{
    assert(ldexp(1.0, -1024) == 0x1p-1024);
    assert(ldexp(1.0, -1022) == 0x1p-1022);
    int x;
    double n = frexp(0x1p-1024, x);
    assert(n == 0.5);
    assert(x==-1023);
    assert(ldexp(n, x)==0x1p-1024);
}
@safe pure nothrow @nogc unittest
{
    assert(ldexp(1.0f, -128) == 0x1p-128f);
    assert(ldexp(1.0f, -126) == 0x1p-126f);
    int x;
    float n = frexp(0x1p-128f, x);
    assert(n == 0.5f);
    assert(x==-127);
    assert(ldexp(n, x)==0x1p-128f);
}
*/

@safe @nogc nothrow unittest
{
    import std.meta: AliasSeq;
    static F[3][] vals(F) =    // value,exp,ldexp
    [
    [    0,    0,    0],
    [    1,    0,    1],
    [    -1,    0,    -1],
    [    1,    1,    2],
    [    123,    10,    125952],
    [    F.max,    int.max,    F.infinity],
    [    F.max,    -int.max,    0],
    [    F.min_normal,    -int.max,    0],
    ];
    static foreach(F; AliasSeq!(double, real))
    {{
        int i;

        for (i = 0; i < vals!F.length; i++)
        {
            F x = vals!F[i][0];
            int exp = cast(int) vals!F[i][1];
            F z = vals!F[i][2];
            F l = ldexp(x, exp);
            assert(feqrel(z, l) >= 23);
        }
    }}
}

package(mir):

// Constants used for extracting the components of the representation.
// They supplement the built-in floating point properties.
template floatTraits(T)
{
    // EXPMASK is a ushort mask to select the exponent portion (without sign)
    // EXPSHIFT is the number of bits the exponent is left-shifted by in its ushort
    // EXPBIAS is the exponent bias - 1 (exp == EXPBIAS yields ×2^-1).
    // EXPPOS_SHORT is the index of the exponent when represented as a ushort array.
    // SIGNPOS_BYTE is the index of the sign when represented as a ubyte array.
    // RECIP_EPSILON is the value such that (smallest_subnormal) * RECIP_EPSILON == T.min_normal
    enum norm_factor = 1 / T.epsilon;
    static if (T.mant_dig == 24)
    {
        enum realFormat = RealFormat.ieeeSingle;
    }
    else static if (T.mant_dig == 53)
    {
        static if (T.sizeof == 8)
        {
            enum realFormat = RealFormat.ieeeDouble;
        }
        else
            static assert(false, "No traits support for " ~ T.stringof);
    }
    else static if (T.mant_dig == 64)
    {
        enum realFormat = RealFormat.ieeeExtended;
    }
    else static if (T.mant_dig == 113)
    {
        enum realFormat = RealFormat.ieeeQuadruple;
    }
    else
        static assert(false, "No traits support for " ~ T.stringof);

    static if (realFormat == RealFormat.ieeeExtended)
    {
        alias S = int;
        alias U = ushort;
        enum sig_mask = U(1) << (U.sizeof * 8 - 1);
        enum exp_shft = 0;
        enum man_mask = 0;
        version (LittleEndian)
            enum idx = 4;
        else
            enum idx = 0;
    }
    else
    {
        static if (realFormat == RealFormat.ieeeQuadruple || realFormat == RealFormat.ieeeDouble && double.sizeof == size_t.sizeof)
        {
            alias S = long;
            alias U = ulong;
        }
        else
        {
            alias S = int;
            alias U = uint;
        }
        static if (realFormat == RealFormat.ieeeQuadruple)
            alias M = ulong;
        else
            alias M = U;
        enum sig_mask = U(1) << (U.sizeof * 8 - 1);
        enum uint exp_shft = T.mant_dig - 1 - (T.sizeof > U.sizeof ? U.sizeof * 8 : 0);
        enum man_mask = (U(1) << exp_shft) - 1;
        enum idx = T.sizeof > U.sizeof ? MANTISSA_MSB : 0;
    }
    enum exp_mask = (U.max >> (exp_shft + 1)) << exp_shft;
    enum int exp_msh = exp_mask >> exp_shft;
    enum intPartMask = man_mask + 1;
    enum exp_nrm = S(exp_msh - T.max_exp - 1) << exp_shft;
}

// These apply to all floating-point types
version (LittleEndian)
{
    enum MANTISSA_LSB = 0;
    enum MANTISSA_MSB = 1;
}
else
{
    enum MANTISSA_LSB = 1;
    enum MANTISSA_MSB = 0;
}
