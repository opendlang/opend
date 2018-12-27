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
 * Authors:   $(HTTP digitalmars.com, Walter Bright), Don Clugston, Ilya Yaroshenko (optimization)
 * Source: $(PHOBOSSRC std/math.d)
 */
module mir.math.ieee;

import mir.internal.utility: isFloatingPoint;

/*********************************
 * Return 1 if sign bit of e is set, 0 if not.
 */
int signbit(T)(const T x) @nogc @trusted pure nothrow
{
    alias F = floatTraits!T;

    static if (F.realFormat == RealFormat.ieeeSingle)
    {
        return ((*cast(uint*)&x) & 0x8000_0000) != 0;
    }
    else 
    static if (F.realFormat == RealFormat.ieeeDouble)
    {
        return ((*cast(ulong*)&x) & 0x8000_0000_0000_0000) != 0;
    }
    else 
    static if (F.realFormat == RealFormat.ieeeQuadruple)
    {
        return ((cast(ulong*)&x)[MANTISSA_MSB] & 0x8000_0000_0000_0000) != 0;
    }
    else
    {
        return ((cast(ubyte *)&x)[F.SIGNPOS_BYTE] & 0x80) != 0;
    }
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
    alias F = floatTraits!T;
    static if (F.realFormat == RealFormat.ieeeSingle
            || F.realFormat == RealFormat.ieeeDouble
            || F.realFormat == RealFormat.ieeeExtended
            || F.realFormat == RealFormat.ieeeQuadruple)
    {
        import mir.math.common: fabs;

        if (x == y)
            return T.mant_dig; // ensure diff != 0, cope with INF.

        auto diff = fabs(x - y);

        ushort *pa = cast(ushort *)(&x);
        ushort *pb = cast(ushort *)(&y);
        ushort *pd = cast(ushort *)(&diff);


        // The difference in abs(exponent) between x or y and abs(x-y)
        // is equal to the number of significand bits of x which are
        // equal to y. If negative, x and y have different exponents.
        // If positive, x and y are equal to 'bitsdiff' bits.
        // AND with 0x7FFF to form the absolute value.
        // To avoid out-by-1 errors, we subtract 1 so it rounds down
        // if the exponents were different. This means 'bitsdiff' is
        // always 1 lower than we want, except that if bitsdiff == 0,
        // they could have 0 or 1 bits in common.

        int bitsdiff = (((  (pa[F.EXPPOS_SHORT] & F.EXPMASK)
                          + (pb[F.EXPPOS_SHORT] & F.EXPMASK)
                          - (1 << F.EXPSHIFT)) >> 1)
                        - (pd[F.EXPPOS_SHORT] & F.EXPMASK)) >> F.EXPSHIFT;
        if ( (pd[F.EXPPOS_SHORT] & F.EXPMASK) == 0)
        {   // Difference is subnormal
            // For subnormals, we need to add the number of zeros that
            // lie at the start of diff's significand.
            // We do this by multiplying by 2^^real.mant_dig
            diff *= F.RECIP_EPSILON;
            return bitsdiff + T.mant_dig - ((pd[F.EXPPOS_SHORT] & F.EXPMASK) >> F.EXPSHIFT);
        }

        if (bitsdiff > 0)
            return bitsdiff + 1; // add the 1 we subtracted before

        // Avoid out-by-1 errors when factor is almost 2.
        if (bitsdiff == 0
            && ((pa[F.EXPPOS_SHORT] ^ pb[F.EXPPOS_SHORT]) & F.EXPMASK) == 0)
        {
            return 1;
        } else return 0;
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

    testFeqrel!(real)();
    testFeqrel!(double)();
    testFeqrel!(float)();
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
{
    alias F = floatTraits!T;
    static if (F.realFormat == RealFormat.ieeeSingle)
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
    else static if (F.realFormat == RealFormat.ieeeDouble)
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
    else static if (F.realFormat == RealFormat.ieeeQuadruple)
    {
        ushort e = F.EXPMASK & (cast(ushort *)&x)[F.EXPPOS_SHORT];
        if (e == F.EXPMASK)
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
    else static if (F.realFormat == RealFormat.ieeeExtended)
    {
        // For 80-bit reals, the "implied bit" is a nuisance...
        ushort *pe = cast(ushort *)&x;
        ulong  *ps = cast(ulong  *)&x;

        if ((pe[F.EXPPOS_SHORT] & F.EXPMASK) == F.EXPMASK)
        {
            // First, deal with NANs and infinity
            if (x == -real.infinity) return -real.max;
            return x; // +Inf and NaN are unchanged.
        }
        if (pe[F.EXPPOS_SHORT] & 0x8000)
        {
            // Negative number -- need to decrease the significand
            --*ps;
            // Need to mask with 0x7FFF... so subnormals are treated correctly.
            if ((*ps & 0x7FFF_FFFF_FFFF_FFFF) == 0x7FFF_FFFF_FFFF_FFFF)
            {
                if (pe[F.EXPPOS_SHORT] == 0x8000)   // it was negative zero
                {
                    *ps = 1;
                    pe[F.EXPPOS_SHORT] = 0; // smallest subnormal.
                    return x;
                }

                --pe[F.EXPPOS_SHORT];

                if (pe[F.EXPPOS_SHORT] == 0x8000)
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
                ++pe[F.EXPPOS_SHORT];
                *ps = 0x8000_0000_0000_0000; // set the high bit
            }
        }
        return x;
    }
    else // static if (F.realFormat == RealFormat.ibmExtended)
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

/** 
 * Return the value that lies halfway between x and y on the IEEE number line.
 *
 * Formally, the result is the arithmetic mean of the binary significands of x
 * and y, multiplied by the geometric mean of the binary exponents of x and y.
 * x and y must have the same sign, and must not be NaN.
 * Note: this function is useful for ensuring O(log n) behaviour in algorithms
 * involving a 'binary chop'.
 *
 * Special cases:
 * If x and y are within a factor of 2, (ie, feqrel(x, y) > 0), the return value
 * is the arithmetic mean (x + y) / 2.
 * If x and y are even powers of 2, the return value is the geometric mean,
 *   ieeeMean(x, y) = sqrt(x * y).
 *
 */
T ieeeMean(T)(const T x, const T y)  @trusted pure nothrow @nogc
in
{
    // both x and y must have the same sign, and must not be NaN.
    assert(signbit(x) == signbit(y));
    assert(x == x && y == y);
}
do
{
    // Runtime behaviour for contract violation:
    // If signs are opposite, or one is a NaN, return 0.
    if (!((x >= 0 && y >= 0) || (x <= 0 && y <= 0))) return 0.0;

    // The implementation is simple: cast x and y to integers,
    // average them (avoiding overflow), and cast the result back to a floating-point number.

    alias F = floatTraits!(T);
    T u;
    static if (F.realFormat == RealFormat.ieeeExtended)
    {
        // There's slight additional complexity because they are actually
        // 79-bit reals...
        ushort *ue = cast(ushort *)&u;
        ulong *ul = cast(ulong *)&u;
        ushort *xe = cast(ushort *)&x;
        ulong *xl = cast(ulong *)&x;
        ushort *ye = cast(ushort *)&y;
        ulong *yl = cast(ulong *)&y;

        // Ignore the useless implicit bit. (Bonus: this prevents overflows)
        ulong m = ((*xl) & 0x7FFF_FFFF_FFFF_FFFFL) + ((*yl) & 0x7FFF_FFFF_FFFF_FFFFL);

        // @@@ BUG? @@@
        // Cast shouldn't be here
        ushort e = cast(ushort) ((xe[F.EXPPOS_SHORT] & F.EXPMASK)
                                 + (ye[F.EXPPOS_SHORT] & F.EXPMASK));
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

        ue[4]= e | (xe[F.EXPPOS_SHORT]& 0x8000); // restore sign bit
    }
    else static if (F.realFormat == RealFormat.ieeeQuadruple)
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
    else static if (F.realFormat == RealFormat.ieeeDouble)
    {
        ulong *ul = cast(ulong *)&u;
        ulong *xl = cast(ulong *)&x;
        ulong *yl = cast(ulong *)&y;
        ulong m = (((*xl) & 0x7FFF_FFFF_FFFF_FFFFL)
                   + ((*yl) & 0x7FFF_FFFF_FFFF_FFFFL)) >>> 1;
        m |= ((*xl) & 0x8000_0000_0000_0000L);
        *ul = m;
    }
    else static if (F.realFormat == RealFormat.ieeeSingle)
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
    enum T RECIP_EPSILON = (1/T.epsilon);
    static if (T.mant_dig == 24)
    {
        // Single precision float
        enum ushort EXPMASK = 0x7F80;
        enum ushort EXPSHIFT = 7;
        enum ushort EXPBIAS = 0x3F00;
        enum uint EXPMASK_INT = 0x7F80_0000;
        enum uint MANTISSAMASK_INT = 0x007F_FFFF;
        enum realFormat = RealFormat.ieeeSingle;
        version (LittleEndian)
        {
            enum EXPPOS_SHORT = 1;
            enum SIGNPOS_BYTE = 3;
        }
        else
        {
            enum EXPPOS_SHORT = 0;
            enum SIGNPOS_BYTE = 0;
        }
    }
    else static if (T.mant_dig == 53)
    {
        static if (T.sizeof == 8)
        {
            // Double precision float, or real == double
            enum ushort EXPMASK = 0x7FF0;
            enum ushort EXPSHIFT = 4;
            enum ushort EXPBIAS = 0x3FE0;
            enum uint EXPMASK_INT = 0x7FF0_0000;
            enum uint MANTISSAMASK_INT = 0x000F_FFFF; // for the MSB only
            enum realFormat = RealFormat.ieeeDouble;
            version (LittleEndian)
            {
                enum EXPPOS_SHORT = 3;
                enum SIGNPOS_BYTE = 7;
            }
            else
            {
                enum EXPPOS_SHORT = 0;
                enum SIGNPOS_BYTE = 0;
            }
        }
        else static if (T.sizeof == 12)
        {
            // Intel extended real80 rounded to double
            enum ushort EXPMASK = 0x7FFF;
            enum ushort EXPSHIFT = 0;
            enum ushort EXPBIAS = 0x3FFE;
            enum realFormat = RealFormat.ieeeExtended53;
            version (LittleEndian)
            {
                enum EXPPOS_SHORT = 4;
                enum SIGNPOS_BYTE = 9;
            }
            else
            {
                enum EXPPOS_SHORT = 0;
                enum SIGNPOS_BYTE = 0;
            }
        }
        else
            static assert(false, "No traits support for " ~ T.stringof);
    }
    else static if (T.mant_dig == 64)
    {
        // Intel extended real80
        enum ushort EXPMASK = 0x7FFF;
        enum ushort EXPSHIFT = 0;
        enum ushort EXPBIAS = 0x3FFE;
        enum realFormat = RealFormat.ieeeExtended;
        version (LittleEndian)
        {
            enum EXPPOS_SHORT = 4;
            enum SIGNPOS_BYTE = 9;
        }
        else
        {
            enum EXPPOS_SHORT = 0;
            enum SIGNPOS_BYTE = 0;
        }
    }
    else static if (T.mant_dig == 113)
    {
        // Quadruple precision float
        enum ushort EXPMASK = 0x7FFF;
        enum ushort EXPSHIFT = 0;
        enum ushort EXPBIAS = 0x3FFE;
        enum realFormat = RealFormat.ieeeQuadruple;
        version (LittleEndian)
        {
            enum EXPPOS_SHORT = 7;
            enum SIGNPOS_BYTE = 15;
        }
        else
        {
            enum EXPPOS_SHORT = 0;
            enum SIGNPOS_BYTE = 0;
        }
    }
    else static if (T.mant_dig == 106)
    {
        // IBM Extended doubledouble
        enum ushort EXPMASK = 0x7FF0;
        enum ushort EXPSHIFT = 4;
        enum realFormat = RealFormat.ibmExtended;

        // For IBM doubledouble the larger magnitude double comes first.
        // It's really a double[2] and arrays don't index differently
        // between little and big-endian targets.
        enum DOUBLEPAIR_MSB = 0;
        enum DOUBLEPAIR_LSB = 1;

        // The exponent/sign byte is for most significant part.
        version (LittleEndian)
        {
            enum EXPPOS_SHORT = 3;
            enum SIGNPOS_BYTE = 7;
        }
        else
        {
            enum EXPPOS_SHORT = 0;
            enum SIGNPOS_BYTE = 0;
        }
    }
    else
        static assert(false, "No traits support for " ~ T.stringof);
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
