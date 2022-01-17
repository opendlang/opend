/**
* SSE4.2 intrinsics.
* https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#techs=SSSE3
*
* Copyright: Guillaume Piolat 2022.
* License:   $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost License 1.0)
*/
module inteli.nmmintrin;

public import inteli.types;
import inteli.internals;
public import inteli.smmintrin;

// Note: this header will work whether you have SSE4.2 enabled or not.
// With LDC, use "dflags-ldc": ["-mattr=+sse4.2"] or equivalent to actively 
// generate SSE3 instruction (they are often enabled with -O1 or greater).

/// Compare packed signed 64-bit integers in a and b for greater-than.
__m128i _mm_cmpgt_epi64 (__m128i a, __m128i b) @trusted
{
    // PERF: ARM32 not good
    long2 la = cast(long2)a;
    long2 lb = cast(long2)b;
    static if (GDC_with_SSE42)
    {
        return cast(__m128i) __builtin_ia32_pcmpgtq(la, lb);
    }
    else version(LDC)
    {
        // LDC x86: Optimized since LDC 1.1.0 -O1
        //     arm64: Optimized since LDC 1.8.0 -O1
        // When SSE4.2 is disabled, this gives same sequence than below.
        return cast(__m128i)( greaterMask!long2(la, lb));
    }
    else
    {        
        long2 r;
        r.ptr[0] = (la.array[0] > lb.array[0]) ? 0xffffffff_ffffffff : 0;
        r.ptr[1] = (la.array[1] > lb.array[1]) ? 0xffffffff_ffffffff : 0;
        return cast(__m128i)r;  
    }
}
unittest
{
    __m128i A = _mm_setr_epi64(-3,  2);
    __m128i B = _mm_setr_epi64(4, -2);
    long[2] correct = [ 0, -1 ];
    long2 R = cast(long2)(_mm_cmpgt_epi32(A, B));
    assert(R.array == correct);
}