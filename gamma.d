/**
 * Implementation of the gamma and beta functions, and their integrals.
 * Adapted from tango.math.GammaFunction to fit the conventions of this library
 * and b/c I did not want to create a dependency on Tango.  Obviously, if anyone
 * is trying to integrate the rest of this library into Tango,
 * tango.math.GammaFunction would be a drop-in replacement.
 **/
 /* Copyright: Based on the CEPHES math library, which is
 *            Copyright (C) 1994 Stephen L. Moshier (moshier@world.std.com).
 * Authors:   Stephen L. Moshier (original C code). Conversion to D by Don Clugston
 *            A few minor adaptations made by David Simcha
  Copyright (c) 2004-2008, Tango contributors All rights reserved.

    * Redistribution and use in source and binary forms, with or without
	  modification, are permitted provided that the following conditions are met:

Redistributions of source code must retain the above copyright notice, this
list of conditions and the following disclaimer.

    * Redistributions in binary form must reproduce the above copyright notice,
	  this list of conditions and the following disclaimer in the documentation
	  and/or other materials provided with the distribution.
    * Neither the name of the Tango project nor the names of its contributors
	  may be used to endorse or promote products derived from this software without
	  specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT
OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY
WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH
DAMAGE.
 *
 *
Macros:
 *  TABLE_SV = <table border=1 cellpadding=4 cellspacing=0>
 *      <caption>Special Values</caption>
 *      $0</table>
 *  SVH = $(TR $(TH $1) $(TH $2))
 *  SV  = $(TR $(TD $1) $(TD $2))
 *  GAMMA =  &#915;
 *  INTEGRATE = $(BIG &#8747;<sub>$(SMALL $1)</sub><sup>$2</sup>)
 *  POWER = $1<sup>$2</sup>
 *  NAN = $(RED NAN)
 */
module dstats.gamma;

import std.math;

import dstats.distrib;

alias std.math.tgamma gamma;

version(Windows) { // Some tests only pass on DMD Windows
    version(DigitalMars) {
    version = FailsOnLinux;
}
}

version(unittest) {
    import std.stdio;

    void main() {}
}

//------------------------------------------------------------------

/// The maximum value of x for which gamma(x) < real.infinity.
enum real MAXGAMMA = 1755.5483429L;

real logGamma(real a) {
    // This is a cheap speed hack.  When doing high-level analyses, this
    // function very frequently ends up getting called multiple times in a
    // row with the same value of a.  Cache the last result in TLS to make
    // these calls fast.
    static real lastRet, lastA;
    if(isIdentical(a, lastA)) {
        return lastRet;
    } else {
        lastA = a;
        return lastRet = std.math.lgamma(a);
    }
}

/****************
 * The sign of $(GAMMA)(x).
 *
 * Returns -1 if $(GAMMA)(x) < 0,  +1 if $(GAMMA)(x) > 0,
 * $(NAN) if sign is indeterminate.
 */
real sgnGamma(real x) pure nothrow
{
    /* Author: Don Clugston. */
    if (isNaN(x)) return x;
    if (x > 0) return 1.0;
    if (x < -1/real.epsilon) {
        // Large negatives lose all precision
        return real.nan;
    }
//  if (remquo(x, -1.0, n) == 0) {
    int n = cast(int)(x);
    if (x == n) {
        return x == 0 ?  copysign(1, x) : real.nan;
    }
    return n & 1 ? 1.0 : -1.0;
}

unittest {
    assert(sgnGamma(5.0) == 1.0);
    assert(isNaN(sgnGamma(-3.0)));
    assert(sgnGamma(-0.1) == -1.0);
    assert(sgnGamma(-55.1) == 1.0);
    assert(isNaN(sgnGamma(-real.infinity)));
}

private {
enum real MAXLOG = 0x1.62e42fefa39ef358p+13L;  // log(real.max)
enum real MINLOG = -0x1.6436716d5406e6d8p+13L; // log(real.min*real.epsilon) = log(smallest denormal)
enum real BETA_BIG = 9.223372036854775808e18L;
enum real BETA_BIGINV = 1.084202172485504434007e-19L;
}

/** Beta function
 *
 * The beta function is defined as
 *
 * beta(x, y) = (&Gamma;(x) &Gamma;(y))/&Gamma;(x + y)
 */
real beta(real x, real y)
{
    if ((x+y)> MAXGAMMA) {
        return exp(logGamma(x) + logGamma(y) - logGamma(x+y));
    } else return gamma(x)*gamma(y)/gamma(x+y);
}

/** Incomplete beta integral
 *
 * Returns incomplete beta integral of the arguments, evaluated
 * from zero to x. The regularized incomplete beta function is defined as
 *
 * betaIncomplete(a, b, x) = &Gamma;(a+b)/(&Gamma;(a) &Gamma;(b)) *
 * $(INTEGRATE 0, x) $(POWER t, a-1)$(POWER (1-t),b-1) dt
 *
 * and is the same as the the cumulative distribution function.
 *
 * The domain of definition is 0 <= x <= 1.  In this
 * implementation a and b are restricted to positive values.
 * The integral from x to 1 may be obtained by the symmetry
 * relation
 *
 *    betaIncompleteCompl(a, b, x )  =  betaIncomplete( b, a, 1-x )
 *
 * The integral is evaluated by a continued fraction expansion
 * or, when b*x is small, by a power series.
 */
real betaIncomplete(real aa, real bb, real xx)
{
    if (!(aa>0 && bb>0)) {
         if (isNaN(aa)) return aa;
         if (isNaN(bb)) return bb;
         return real.nan; // domain error
    }
    if (!(xx>0 && xx<1.0)) {
        if (isNaN(xx)) return xx;
        if ( xx == 0.0L ) return 0.0;
        if ( xx == 1.0L )  return 1.0;
        return real.nan; // domain error
    }
    if ( (bb * xx) <= 1.0L && xx <= 0.95L)   {
        return betaDistPowerSeries(aa, bb, xx);
    }
    real x;
    real xc; // = 1 - x

    real a, b;
    int flag = 0;

    /* Reverse a and b if x is greater than the mean. */
    if( xx > (aa/(aa+bb)) ) {
        // here x > aa/(aa+bb) and (bb*x>1 or x>0.95)
        flag = 1;
        a = bb;
        b = aa;
        xc = xx;
        x = 1.0L - xx;
    } else {
        a = aa;
        b = bb;
        xc = 1.0L - xx;
        x = xx;
    }

    if( flag == 1 && (b * x) <= 1.0L && x <= 0.95L) {
        // here xx > aa/(aa+bb) and  ((bb*xx>1) or xx>0.95) and (aa*(1-xx)<=1) and xx > 0.05
        return 1.0 - betaDistPowerSeries(a, b, x); // note loss of precision
    }

    real w;

    // Choose expansion for optimal convergence
    // One is for x * (a+b+2) < (a+1),
    // the other is for x * (a+b+2) > (a+1).
    real y = x * (a+b-2.0L) - (a-1.0L);
    if( y < 0.0L ) {
        w = betaDistExpansion1( a, b, x );
    } else {
        w = betaDistExpansion2( a, b, x ) / xc;
    }

    /* Multiply w by the factor
         a      b
        x  (1-x)   Gamma(a+b) / ( a Gamma(a) Gamma(b) ) .   */

    y = a * log(x);
    real t = b * log(xc);
    if ( (a+b) < MAXGAMMA && fabs(y) < MAXLOG && fabs(t) < MAXLOG ) {
        t = pow(xc,b);
        t *= pow(x,a);
        t /= a;
        t *= w;
        t *= gamma(a+b) / (gamma(a) * gamma(b));
    } else {
        /* Resort to logarithms.  */
        y += t + logGamma(a+b) - logGamma(a) - logGamma(b);
        y += log(w/a);

        t = exp(y);
/+
        // There seems to be a bug in Cephes at this point.
        // Problems occur for y > MAXLOG, not y < MINLOG.
        if( y < MINLOG ) {
            t = 0.0L;
        } else {
            t = exp(y);
        }
+/
    }
    if( flag == 1 ) {
/+   // CEPHES includes this code, but I think it is erroneous.
        if( t <= real.epsilon ) {
            t = 1.0L - real.epsilon;
        } else
+/
        t = 1.0L - t;
    }
    return t;
}

/** Inverse of incomplete beta integral
 *
 * Given y, the function finds x such that
 *
 *  betaIncomplete(a, b, x) == y
 *
 *  Newton iterations or interval halving is used.
 */
real betaIncompleteInv(real aa, real bb, real yy0 )
{
    real a, b, y0, d, y, x, x0, x1, lgm, yp, di, dithresh, yl, yh, xt;
    int i, rflg, dir, nflg;

    if (isNaN(yy0)) return yy0;
    if (isNaN(aa)) return aa;
    if (isNaN(bb)) return bb;
    if( yy0 <= 0.0L )
        return 0.0L;
    if( yy0 >= 1.0L )
        return 1.0L;
    x0 = 0.0L;
    yl = 0.0L;
    x1 = 1.0L;
    yh = 1.0L;
    if( aa <= 1.0L || bb <= 1.0L ) {
        dithresh = 1.0e-7L;
        rflg = 0;
        a = aa;
        b = bb;
        y0 = yy0;
        x = a/(a+b);
        y = betaIncomplete( a, b, x );
        nflg = 0;
        goto ihalve;
    } else {
        nflg = 0;
        dithresh = 1.0e-4L;
    }

    /* approximation to inverse function */

    yp = -invNormalCDF( yy0 );

    if( yy0 > 0.5L ) {
        rflg = 1;
        a = bb;
        b = aa;
        y0 = 1.0L - yy0;
        yp = -yp;
    } else {
        rflg = 0;
        a = aa;
        b = bb;
        y0 = yy0;
    }

    lgm = (yp * yp - 3.0L)/6.0L;
    x = 2.0L/( 1.0L/(2.0L * a-1.0L)  +  1.0L/(2.0L * b - 1.0L) );
    d = yp * sqrt( x + lgm ) / x
        - ( 1.0L/(2.0L * b - 1.0L) - 1.0L/(2.0L * a - 1.0L) )
        * (lgm + (5.0L/6.0L) - 2.0L/(3.0L * x));
    d = 2.0L * d;
    if( d < MINLOG ) {
        x = 1.0L;
        goto under;
    }
    x = a/( a + b * exp(d) );
    y = betaIncomplete( a, b, x );
    yp = (y - y0)/y0;
    if( fabs(yp) < 0.2 )
        goto newt;

    /* Resort to interval halving if not close enough. */
ihalve:

    dir = 0;
    di = 0.5L;
    for( i=0; i<400; i++ ) {
        if( i != 0 ) {
            x = x0  +  di * (x1 - x0);
            if( x == 1.0L ) {
                x = 1.0L - real.epsilon;
            }
            if( x == 0.0L ) {
                di = 0.5;
                x = x0  +  di * (x1 - x0);
                if( x == 0.0 )
                    goto under;
            }
            y = betaIncomplete( a, b, x );
            yp = (x1 - x0)/(x1 + x0);
            if( fabs(yp) < dithresh )
                goto newt;
            yp = (y-y0)/y0;
            if( fabs(yp) < dithresh )
                goto newt;
        }
        if( y < y0 ) {
            x0 = x;
            yl = y;
            if( dir < 0 ) {
                dir = 0;
                di = 0.5L;
            } else if( dir > 3 )
                di = 1.0L - (1.0L - di) * (1.0L - di);
            else if( dir > 1 )
                di = 0.5L * di + 0.5L;
            else
                di = (y0 - y)/(yh - yl);
            dir += 1;
            if( x0 > 0.95L ) {
                if( rflg == 1 ) {
                    rflg = 0;
                    a = aa;
                    b = bb;
                    y0 = yy0;
                } else {
                    rflg = 1;
                    a = bb;
                    b = aa;
                    y0 = 1.0 - yy0;
                }
                x = 1.0L - x;
                y = betaIncomplete( a, b, x );
                x0 = 0.0;
                yl = 0.0;
                x1 = 1.0;
                yh = 1.0;
                goto ihalve;
            }
        } else {
            x1 = x;
            if( rflg == 1 && x1 < real.epsilon ) {
                x = 0.0L;
                goto done;
            }
            yh = y;
            if( dir > 0 ) {
                dir = 0;
                di = 0.5L;
            }
            else if( dir < -3 )
                di = di * di;
            else if( dir < -1 )
                di = 0.5L * di;
            else
                di = (y - y0)/(yh - yl);
            dir -= 1;
            }
        }
    // loss of precision has occurred

    //mtherr( "incbil", PLOSS );
    if( x0 >= 1.0L ) {
        x = 1.0L - real.epsilon;
        goto done;
    }
    if( x <= 0.0L ) {
under:
        // underflow has occurred
        //mtherr( "incbil", UNDERFLOW );
        x = 0.0L;
        goto done;
    }

newt:

    if ( nflg ) {
        goto done;
    }
    nflg = 1;
    lgm = logGamma(a+b) - logGamma(a) - logGamma(b);

    for( i=0; i<15; i++ ) {
        /* Compute the function at this point. */
        if ( i != 0 )
            y = betaIncomplete(a,b,x);
        if ( y < yl ) {
            x = x0;
            y = yl;
        } else if( y > yh ) {
            x = x1;
            y = yh;
        } else if( y < y0 ) {
            x0 = x;
            yl = y;
        } else {
            x1 = x;
            yh = y;
        }
        if( x == 1.0L || x == 0.0L )
            break;
        /* Compute the derivative of the function at this point. */
        d = (a - 1.0L) * log(x) + (b - 1.0L) * log(1.0L - x) + lgm;
        if ( d < MINLOG ) {
            goto done;
        }
        if ( d > MAXLOG ) {
            break;
        }
        d = exp(d);
        /* Compute the step to the next approximation of x. */
        d = (y - y0)/d;
        xt = x - d;
        if ( xt <= x0 ) {
            y = (x - x0) / (x1 - x0);
            xt = x0 + 0.5L * y * (x - x0);
            if( xt <= 0.0L )
                break;
        }
        if ( xt >= x1 ) {
            y = (x1 - x) / (x1 - x0);
            xt = x1 - 0.5L * y * (x1 - x);
            if ( xt >= 1.0L )
                break;
        }
        x = xt;
        if ( fabs(d/x) < (128.0L * real.epsilon) )
            goto done;
        }
    /* Did not converge.  */
    dithresh = 256.0L * real.epsilon;
    goto ihalve;

done:
    if ( rflg ) {
        if( x <= real.epsilon )
            x = 1.0L - real.epsilon;
        else
            x = 1.0L - x;
    }
    return x;
}

unittest { // also tested by the normal distribution
  assert(isNaN(betaIncomplete(-1, 2, 3)));

  assert(betaIncomplete(1, 2, 0)==0);
  assert(betaIncomplete(1, 2, 1)==1);
  assert(isNaN(betaIncomplete(1, 2, 3)));
  assert(betaIncompleteInv(1, 1, 0)==0);
  assert(betaIncompleteInv(1, 1, 1)==1);

  // Test some values against Microsoft Excel 2003.

  assert(fabs(betaIncomplete(8, 10, 0.2) - 0.010_934_315_236_957_2L) < 0.000_000_000_5);
  assert(fabs(betaIncomplete(2, 2.5, 0.9) - 0.989_722_597_604_107L) < 0.000_000_000_000_5);
  assert(fabs(betaIncomplete(1000, 800, 0.5) - 1.17914088832798E-06L) < 0.000_000_05e-6);

  assert(fabs(betaIncomplete(0.0001, 10000, 0.0001) - 0.999978059369989L) < 0.000_000_000_05);

  assert(fabs(betaIncompleteInv(5, 10, 0.2) - 0.229121208190918L) < 0.000_000_5L);
  assert(fabs(betaIncompleteInv(4, 7, 0.8) - 0.483657360076904L) < 0.000_000_5L);

    // Coverage tests. I don't have correct values for these tests, but
    // these values cover most of the code, so they are useful for
    // regression testing.
    // Extensive testing failed to increase the coverage. It seems likely that about
    // half the code in this function is unnecessary; there is potential for
    // significant improvement over the original CEPHES code.

// Excel 2003 gives clearly erroneous results (betadist>1) when a and x are tiny and b is huge.
// The correct results are for these next tests are unknown.

//    real testpoint1 = betaIncomplete(1e-10, 5e20, 8e-21);
//    assert(testpoint1 == 0x1.ffff_ffff_c906_404cp-1L);

    assert(betaIncomplete(0.01, 327726.7, 0.545113) == 1.0);
    
    // These don't work on Linux, probably due to some weird corner
    // case bugs in Linux's C math functions.
    version(linux) {} else {
        assert(betaIncompleteInv(0.01, 8e-48, 5.45464e-20) ==1-real.epsilon);
        assert(betaIncompleteInv(0.01, 8e-48, 9e-26)==1-real.epsilon);
    }

    assert(betaIncomplete(0.01, 498.437, 0.0121433) == 0x1.ffff_8f72_19197402p-1);
    assert(1- betaIncomplete(0.01, 328222, 4.0375e-5) == 0x1.5f62926b4p-30);
    version(FailsOnLinux)  assert(betaIncompleteInv(0x1.b3d151fbba0eb18p+1, 1.2265e-19, 2.44859e-18)==0x1.c0110c8531d0952cp-1);
    real a1;
    a1 = 3.40483;
    version(FailsOnLinux)  assert(betaIncompleteInv(a1, 4.0640301659679627772e19L, 0.545113)== 0x1.ba8c08108aaf5d14p-109);
    real b1;
    b1= 2.82847e-25;

    // --- Problematic cases ---
    // This is a situation where the series expansion fails to converge
    assert( isNaN(betaIncompleteInv(0.12167, 4.0640301659679627772e19L, 0.0813601)));
    // This next result is almost certainly erroneous.
    assert(betaIncomplete(1.16251e20, 2.18e39, 5.45e-20)==-real.infinity);
}

private {
// Implementation functions

// Continued fraction expansion #1 for incomplete beta integral
// Use when x < (a+1)/(a+b+2)
real betaDistExpansion1(real a, real b, real x ) pure nothrow
{
    real xk, pk, pkm1, pkm2, qk, qkm1, qkm2;
    real k1, k2, k3, k4, k5, k6, k7, k8;
    real r, t, ans;
    int n;

    k1 = a;
    k2 = a + b;
    k3 = a;
    k4 = a + 1.0L;
    k5 = 1.0L;
    k6 = b - 1.0L;
    k7 = k4;
    k8 = a + 2.0L;

    pkm2 = 0.0L;
    qkm2 = 1.0L;
    pkm1 = 1.0L;
    qkm1 = 1.0L;
    ans = 1.0L;
    r = 1.0L;
    n = 0;
    enum real thresh = 3.0L * real.epsilon;
    do  {
        xk = -( x * k1 * k2 )/( k3 * k4 );
        pk = pkm1 +  pkm2 * xk;
        qk = qkm1 +  qkm2 * xk;
        pkm2 = pkm1;
        pkm1 = pk;
        qkm2 = qkm1;
        qkm1 = qk;

        xk = ( x * k5 * k6 )/( k7 * k8 );
        pk = pkm1 +  pkm2 * xk;
        qk = qkm1 +  qkm2 * xk;
        pkm2 = pkm1;
        pkm1 = pk;
        qkm2 = qkm1;
        qkm1 = qk;

        if( qk != 0.0L )
            r = pk/qk;
        if( r != 0.0L ) {
            t = fabs( (ans - r)/r );
            ans = r;
        } else {
           t = 1.0L;
        }

        if( t < thresh )
            return ans;

        k1 += 1.0L;
        k2 += 1.0L;
        k3 += 2.0L;
        k4 += 2.0L;
        k5 += 1.0L;
        k6 -= 1.0L;
        k7 += 2.0L;
        k8 += 2.0L;

        if( (fabs(qk) + fabs(pk)) > BETA_BIG ) {
            pkm2 *= BETA_BIGINV;
            pkm1 *= BETA_BIGINV;
            qkm2 *= BETA_BIGINV;
            qkm1 *= BETA_BIGINV;
            }
        if( (fabs(qk) < BETA_BIGINV) || (fabs(pk) < BETA_BIGINV) ) {
            pkm2 *= BETA_BIG;
            pkm1 *= BETA_BIG;
            qkm2 *= BETA_BIG;
            qkm1 *= BETA_BIG;
            }
        }
    while( ++n < 400 );
// loss of precision has occurred
// mtherr( "incbetl", PLOSS );
    return ans;
}

// Continued fraction expansion #2 for incomplete beta integral
// Use when x > (a+1)/(a+b+2)
real betaDistExpansion2(real a, real b, real x ) pure nothrow
{
    real  xk, pk, pkm1, pkm2, qk, qkm1, qkm2;
    real k1, k2, k3, k4, k5, k6, k7, k8;
    real r, t, ans, z;

    k1 = a;
    k2 = b - 1.0L;
    k3 = a;
    k4 = a + 1.0L;
    k5 = 1.0L;
    k6 = a + b;
    k7 = a + 1.0L;
    k8 = a + 2.0L;

    pkm2 = 0.0L;
    qkm2 = 1.0L;
    pkm1 = 1.0L;
    qkm1 = 1.0L;
    z = x / (1.0L-x);
    ans = 1.0L;
    r = 1.0L;
    int n = 0;
    enum real thresh = 3.0L * real.epsilon;
    do {

        xk = -( z * k1 * k2 )/( k3 * k4 );
        pk = pkm1 +  pkm2 * xk;
        qk = qkm1 +  qkm2 * xk;
        pkm2 = pkm1;
        pkm1 = pk;
        qkm2 = qkm1;
        qkm1 = qk;

        xk = ( z * k5 * k6 )/( k7 * k8 );
        pk = pkm1 +  pkm2 * xk;
        qk = qkm1 +  qkm2 * xk;
        pkm2 = pkm1;
        pkm1 = pk;
        qkm2 = qkm1;
        qkm1 = qk;

        if( qk != 0.0L )
            r = pk/qk;
        if( r != 0.0L ) {
            t = fabs( (ans - r)/r );
            ans = r;
        } else
            t = 1.0L;

        if( t < thresh )
            return ans;
        k1 += 1.0L;
        k2 -= 1.0L;
        k3 += 2.0L;
        k4 += 2.0L;
        k5 += 1.0L;
        k6 += 1.0L;
        k7 += 2.0L;
        k8 += 2.0L;

        if( (fabs(qk) + fabs(pk)) > BETA_BIG ) {
            pkm2 *= BETA_BIGINV;
            pkm1 *= BETA_BIGINV;
            qkm2 *= BETA_BIGINV;
            qkm1 *= BETA_BIGINV;
        }
        if( (fabs(qk) < BETA_BIGINV) || (fabs(pk) < BETA_BIGINV) ) {
            pkm2 *= BETA_BIG;
            pkm1 *= BETA_BIG;
            qkm2 *= BETA_BIG;
            qkm1 *= BETA_BIG;
        }
    } while( ++n < 400 );
// loss of precision has occurred
//mtherr( "incbetl", PLOSS );
    return ans;
}

/* Power series for incomplete gamma integral.
   Use when b*x is small.  */
real betaDistPowerSeries(real a, real b, real x )
{
    real ai = 1.0L / a;
    real u = (1.0L - b) * x;
    real v = u / (a + 1.0L);
    real t1 = v;
    real t = u;
    real n = 2.0L;
    real s = 0.0L;
    real z = real.epsilon * ai;
    while( fabs(v) > z ) {
        u = (n - b) * x / n;
        t *= u;
        v = t / (a + n);
        s += v;
        n += 1.0L;
    }
    s += t1;
    s += ai;

    u = a * log(x);
    if ( (a+b) < MAXGAMMA && fabs(u) < MAXLOG ) {
        t = gamma(a+b)/(gamma(a)*gamma(b));
        s = s * t * pow(x,a);
    } else {
        t = logGamma(a+b) - logGamma(a) - logGamma(b) + u + log(s);

        if( t < MINLOG ) {
            s = 0.0L;
        } else
            s = exp(t);
    }
    return s;
}

}

/***************************************
 *  Incomplete gamma integral and its complement
 *
 * These functions are defined by
 *
 *   gammaIncomplete = ( $(INTEGRATE 0, x) $(POWER e, -t) $(POWER t, a-1) dt )/ $(GAMMA)(a)
 *
 *  gammaIncompleteCompl(a,x)   =   1 - gammaIncomplete(a,x)
 * = ($(INTEGRATE x, &infin;) $(POWER e, -t) $(POWER t, a-1) dt )/ $(GAMMA)(a)
 *
 * In this implementation both arguments must be positive.
 * The integral is evaluated by either a power series or
 * continued fraction expansion, depending on the relative
 * values of a and x.
 */
real gammaIncomplete(real a, real x )
in {
   assert(x >= 0);
   assert(a > 0);
}
body {
    /* left tail of incomplete gamma function:
     *
     *          inf.      k
     *   a  -x   -       x
     *  x  e     >   ----------
     *           -     -
     *          k=0   | (a+k+1)
     *
     */
    if (x==0)
       return 0.0L;

    if ( (x > 1.0L) && (x > a ) )
        return 1.0L - gammaIncompleteCompl(a,x);

    real ax = a * log(x) - x - logGamma(a);
/+
    if( ax < MINLOGL ) return 0; // underflow
    //  { mtherr( "igaml", UNDERFLOW ); return( 0.0L ); }
+/
    ax = exp(ax);

    /* power series */
    real r = a;
    real c = 1.0L;
    real ans = 1.0L;

    do  {
        r++;
        c *= x/r;
        ans += c;
    } while( c/ans > real.epsilon );

    return ans * ax/a;
}

/** ditto */
real gammaIncompleteCompl(real a, real x )
in {
   assert(x >= 0);
   assert(a > 0);
}
body {
    if (x==0)
       return 1.0L;
    if ( (x < 1.0L) || (x < a) )
        return 1.0L - gammaIncomplete(a,x);

   // DAC (Cephes bug fix): This is necessary to avoid
   // spurious nans, eg
   // log(x)-x = NaN when x = real.infinity
   enum real MAXLOGL =  1.1356523406294143949492E4L;
   if (x > MAXLOGL) return 0; // underflow

   real ax = a * log(x) - x - logGamma(a);
//const real MINLOGL = -1.1355137111933024058873E4L;
//  if ( ax < MINLOGL ) return 0; // underflow;
    ax = exp(ax);


    /* continued fraction */
    real y = 1.0L - a;
    real z = x + y + 1.0L;
    real c = 0.0L;

    real pk, qk, t;

    real pkm2 = 1.0L;
    real qkm2 = x;
    real pkm1 = x + 1.0L;
    real qkm1 = z * x;
    real ans = pkm1/qkm1;

    do  {
        c++;
        y++;
        z += 2;
        real yc = y * c;
        pk = pkm1 * z  -  pkm2 * yc;
        qk = qkm1 * z  -  qkm2 * yc;
        if(qk != 0) {
            real r = pk/qk;
            t = fabs( (ans - r)/r );
            ans = r;
        } else {
            t = 1;
        }
        pkm2 = pkm1;
        pkm1 = pk;
        qkm2 = qkm1;
        qkm1 = qk;

        enum real BIG = 9.223372036854775808e18L;

        if ( fabs(pk) > BIG ) {
            pkm2 /= BIG;
            pkm1 /= BIG;
            qkm2 /= BIG;
            qkm1 /= BIG;
        }
    } while ( t > real.epsilon );

    return ans * ax;
}

/** Inverse of complemented incomplete gamma integral
 *
 * Given a and y, the function finds x such that
 *
 *  gammaIncompleteCompl( a, x ) = p.
 *
 * Starting with the approximate value x = a $(POWER t, 3), where
 * t = 1 - d - normalDistributionInv(p) sqrt(d),
 * and d = 1/9a,
 * the routine performs up to 10 Newton iterations to find the
 * root of incompleteGammaCompl(a,x) - p = 0.
 */
real gammaIncompleteComplInv(real a, real p)
in {
  assert(p>=0 && p<= 1);
  assert(a>0);
}
body {
    if (p==0) return real.infinity;

    real y0 = p;
    enum real MAXLOGL =  1.1356523406294143949492E4L;
    int i, dir;

    /* bound the solution */
    real x0 = real.max;
    real yl = 0;
    real x1 = 0;
    real yh = 1;
    real dithresh = 4 * real.epsilon;

    /* approximation to inverse function */
    real d = 1.0L/(9.0L*a);
    real y = 1.0L - d - invNormalCDF(y0) * sqrt(d);
    real x = a * y * y * y;

    real lgm = logGamma(a);

    for( i=0; i<10; i++ ) {
        if( x > x0 || x < x1 )
            goto ihalve;
        y = gammaIncompleteCompl(a,x);
        if ( y < yl || y > yh )
            goto ihalve;
        if ( y < y0 ) {
            x0 = x;
            yl = y;
        } else {
            x1 = x;
            yh = y;
        }
    /* compute the derivative of the function at this point */
        d = (a - 1.0L) * log(x0) - x0 - lgm;
        if ( d < -MAXLOGL )
            goto ihalve;
        d = -exp(d);
    /* compute the step to the next approximation of x */
        d = (y - y0)/d;
        x = x - d;
        if ( i < 3 ) continue;
        if ( fabs(d/x) < dithresh ) return x;
    }

    /* Resort to interval halving if Newton iteration did not converge. */
ihalve:
    d = 0.0625L;
    if ( x0 == real.max ) {
        if( x <= 0.0L )
            x = 1.0L;
        while( x0 == real.max ) {
            x = (1.0L + d) * x;
            y = gammaIncompleteCompl( a, x );
            if ( y < y0 ) {
                x0 = x;
                yl = y;
                break;
            }
            d = d + d;
        }
    }
    d = 0.5L;
    dir = 0;

    for( i=0; i<400; i++ ) {
        x = x1  +  d * (x0 - x1);
        y = gammaIncompleteCompl( a, x );
        lgm = (x0 - x1)/(x1 + x0);
        if ( fabs(lgm) < dithresh )
            break;
        lgm = (y - y0)/y0;
        if ( fabs(lgm) < dithresh )
            break;
        if ( x <= 0.0L )
            break;
        if ( y > y0 ) {
            x1 = x;
            yh = y;
            if ( dir < 0 ) {
                dir = 0;
                d = 0.5L;
            } else if ( dir > 1 )
                d = 0.5L * d + 0.5L;
            else
                d = (y0 - yl)/(yh - yl);
            dir += 1;
        } else {
            x0 = x;
            yl = y;
            if ( dir > 0 ) {
                dir = 0;
                d = 0.5L;
            } else if ( dir < -1 )
                d = 0.5L * d;
            else
                d = (y0 - yl)/(yh - yl);
            dir -= 1;
        }
    }
    /+
    if( x == 0.0L )
        mtherr( "igamil", UNDERFLOW );
    +/
    return x;
}

unittest {
//Values from Excel's GammaInv(1-p, x, 1)
assert(fabs(gammaIncompleteComplInv(1, 0.5) - 0.693147188044814) < 0.00000005);
assert(fabs(gammaIncompleteComplInv(12, 0.99) - 5.42818075054289) < 0.00000005);
assert(fabs(gammaIncompleteComplInv(100, 0.8) - 91.5013985848288L) < 0.000005);

assert(gammaIncomplete(1, 0)==0);
assert(gammaIncompleteCompl(1, 0)==1);
assert(gammaIncomplete(4545, real.infinity)==1);

// Values from Excel's (1-GammaDist(x, alpha, 1, TRUE))

assert(fabs(1.0L-gammaIncompleteCompl(0.5, 2) - 0.954499729507309L) < 0.00000005);
assert(fabs(gammaIncomplete(0.5, 2) - 0.954499729507309L) < 0.00000005);
// Fixed Cephes bug:
assert(gammaIncompleteCompl(384, real.infinity)==0);
assert(gammaIncompleteComplInv(3, 0)==real.infinity);

//writefln("%.20g",gammaIncompleteCompl(100, 0));
//assert(gammaIncompleteComplInv(8, 0));

// BUG: infinite loop if p == 0!
//writefln(gammaIncompleteComplInv(8, 0));

//writefln(gammaIncompleteComplInv(8, 1e-50));
//writefln(gammaIncompleteComplInv(12, 0.99));
}
