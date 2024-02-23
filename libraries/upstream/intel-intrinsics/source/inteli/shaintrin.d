/**
* SHA intrinsics.
* https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#othertechs=SHA
* 
* Copyright: Guillaume Piolat 2021.
*            Johan Engelen 2021.
* License:   $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost License 1.0)
*/
module inteli.shaintrin;

// SHA instructions
// https://software.intel.com/sites/landingpage/IntrinsicsGuide/#othertechs=SHA
// Note: this header will work whether you have SHA enabled or not.
// With LDC, use "dflags-ldc": ["-mattr=+sha"] or equivalent to actively
// generate SHA instructions.
// With GDC, use "dflags-gdc": ["-msha"] or equivalent to generate SHA instructions.

public import inteli.types;
import inteli.internals;



nothrow @nogc:

/+
/// Perform an intermediate calculation for the next four SHA1 message values (unsigned 32-bit integers) using previous message values from a and b, and store the result in dst.
__m128i _mm_sha1nexte_epu32(__m128i a, __m128i b) @trusted
{
    static if (SHA_builtins)
    {
        return __builtin_ia32_sha1nexte(cast(int4) a, cast(int4) b);
    }
    else
    {
        assert(0);
    }
}
unittest
{
}
+/

/+
/// Perform the final calculation for the next four SHA1 message values (unsigned 32-bit integers) using the intermediate result in a and the previous message values in b, and store the result in dst.
__m128i _mm_sha1msg1_epu32(__m128i a, __m128i b) @trusted
{
    static if (SHA_builtins)
    {
        return __builtin_ia32_sha1msg1(cast(int4) a, cast(int4) b);
    }
    else
    {
        assert(0);
    }
}
unittest
{
}
+/

/+
/// Calculate SHA1 state variable E after four rounds of operation from the current SHA1 state variable a, add that value to the scheduled values (unsigned 32-bit integers) in b, and store the result in dst.
__m128i _mm_sha1msg2_epu32(__m128i a, __m128i b) @trusted
{
    static if (SHA_builtins)
    {
        return __builtin_ia32_sha1msg2(cast(int4) a, cast(int4) b);
    }
    else
    {
        assert(0);
    }
}
unittest
{
}
+/

/+
/// Perform four rounds of SHA1 operation using an initial SHA1 state (A,B,C,D) from a and some pre-computed sum of the next 4 round message values (unsigned 32-bit integers), and state variable E from b, and store the updated SHA1 state (A,B,C,D) in dst. func contains the logic functions and round constants.
__m128i _mm_sha1rnds4_epu32(__m128i a, __m128i b, const int func) @trusted
{
    static if (SHA_builtins)
    {
        return __builtin_ia32_sha1rnds4(cast(int4) a, cast(int4) b, func);
    }
    else
    {
        assert(0);
    }

}
+/

/// Perform the final calculation for the next four SHA256 message values (unsigned 32-bit integers) using previous message values from `a` and `b`, and return the result.
__m128i _mm_sha256msg1_epu32(__m128i a, __m128i b) @trusted
{
    static if (GDC_or_LDC_with_SHA)
    {
        return __builtin_ia32_sha256msg1(cast(int4) a, cast(int4) b);
    }
    else
    {
        static uint sigma0(uint x) nothrow @nogc @safe
        { 
            return bitwiseRotateRight_uint(x, 7) ^ bitwiseRotateRight_uint(x, 18) ^ x >> 3;
        }

        int4 dst;
        int4 a4 = cast(int4) a;
        int4 b4 = cast(int4) b;
        uint W4 = b4.array[0];
        uint W3 = a4.array[3];
        uint W2 = a4.array[2];
        uint W1 = a4.array[1];
        uint W0 = a4.array[0];
        dst.ptr[3] = W3 + sigma0(W4);
        dst.ptr[2] = W2 + sigma0(W3);
        dst.ptr[1] = W1 + sigma0(W2);
        dst.ptr[0] = W0 + sigma0(W1);
        return cast(__m128i) dst;
    }
}
unittest
{
    __m128i a = [15, 20, 130, 12345];
    __m128i b = [15, 20, 130, 12345];
    __m128i result = _mm_sha256msg1_epu32(a, b);
    assert(result.array == [671416337, 69238821, 2114864873, 503574586]);
}

/// Perform 2 rounds of SHA256 operation using an initial SHA256 state (C,D,G,H) from `a`, an initial SHA256 state (A,B,E,F) from `b`, and a pre-computed sum of the next 2 round message values (unsigned 32-bit integers) and the corresponding round constants from k, and return the updated SHA256 state (A,B,E,F).
__m128i _mm_sha256msg2_epu32(__m128i a, __m128i b) @trusted
{
    static if (GDC_or_LDC_with_SHA)
    {
        return __builtin_ia32_sha256msg2(cast(int4) a, cast(int4) b);
    }
    else
    {
        static uint sigma1(uint x) nothrow @nogc @safe
        { 
            return bitwiseRotateRight_uint(x, 17) ^ bitwiseRotateRight_uint(x, 19) ^ x >> 10; 
        }

        int4 dst;
        int4 a4 = cast(int4) a;
        int4 b4 = cast(int4) b;
        uint W14 = b4.array[2];
        uint W15 = b4.array[3];
        uint W16 = a4.array[0] + sigma1(W14);
        uint W17 = a4.array[1] + sigma1(W15);
        uint W18 = a4.array[2] + sigma1(W16);
        uint W19 = a4.array[3] + sigma1(W17);
        dst.ptr[3] = W19;
        dst.ptr[2] = W18;
        dst.ptr[1] = W17;
        dst.ptr[0] = W16;
        return cast(__m128i) dst;
    }
}
unittest
{
    __m128i a = [15, 20, 130, 12345];
    __m128i b = [15, 20, 130, 12345];
    __m128i result = _mm_sha256msg2_epu32(a, b);
    assert(result.array == [5324815, 505126944, -2012842764, -1542210977]);
}

/// Perform an intermediate calculation for the next four SHA256 message values (unsigned 32-bit integers) using previous message values from `a` and `b`, and return the result.
__m128i _mm_sha256rnds2_epu32(__m128i a, __m128i b, __m128i k) @trusted
{
    // TODO: the pragma(inline) false prevent a DMD 1.100
    //       regression in Linux + x86_64 + -b release-unittest, report that

    version(DigitalMars)
    {
        enum bool workaround = true;
    }
    else
    {
        enum bool workaround = false;
    }

    static if (GDC_or_LDC_with_SHA)
    {
        return __builtin_ia32_sha256rnds2(cast(int4) a, cast(int4) b, cast(int4) k);
    }
    else
    {
        static uint Ch(uint x, uint y, uint z) nothrow @nogc @safe
        { 
            static if (workaround) pragma (inline, false);
            return z ^ (x & (y ^ z)); 
        }
        
        static uint Maj(uint x, uint y, uint z) nothrow @nogc @safe
        { 
            static if (workaround) pragma (inline, false);
            return (x & y) | (z & (x ^ y)); 
        }

        static uint sum0(uint x) nothrow @nogc @safe
        { 
            static if (workaround) pragma (inline, false);
            return bitwiseRotateRight_uint(x, 2) ^ bitwiseRotateRight_uint(x, 13) ^ bitwiseRotateRight_uint(x, 22); 
        }

        static uint sum1(uint x) nothrow @nogc @safe
        { 
            static if (workaround) pragma (inline, false);
            return bitwiseRotateRight_uint(x, 6) ^ bitwiseRotateRight_uint(x, 11) ^ bitwiseRotateRight_uint(x, 25); 
        }

        int4 dst;
        int4 a4 = cast(int4) a;
        int4 b4 = cast(int4) b;
        int4 k4 = cast(int4) k;

        const A0 = b4.array[3];
        const B0 = b4.array[2];
        const C0 = a4.array[3];
        const D0 = a4.array[2];
        const E0 = b4.array[1];
        const F0 = b4.array[0];
        const G0 = a4.array[1];
        const H0 = a4.array[0];
        const W_K0 = k4.array[0];
        const W_K1 = k4.array[1];
        const A1 = Ch(E0, F0, G0) + sum1(E0) + W_K0 + H0 + Maj(A0, B0, C0) + sum0(A0);
        const B1 = A0;
        const C1 = B0;
        const D1 = C0;
        const E1 = Ch(E0, F0, G0) + sum1(E0) + W_K0 + H0 + D0;
        const F1 = E0;
        const G1 = F0;
        const H1 = G0;
        const A2 = Ch(E1, F1, G1) + sum1(E1) + W_K1 + H1 + Maj(A1, B1, C1) + sum0(A1);
        const B2 = A1;
        const C2 = B1;
        const D2 = C1;
        const E2 = Ch(E1, F1, G1) + sum1(E1) + W_K1 + H1 + D1;
        const F2 = E1;
        const G2 = F1;
        const H2 = G1;

        dst.ptr[3] = A2;
        dst.ptr[2] = B2;
        dst.ptr[1] = E2;
        dst.ptr[0] = F2;

        return cast(__m128i) dst;
    }
}
unittest
{
    __m128i a = [15, 20, 130, 12345];
    __m128i b = [15, 20, 130, 12345];
    __m128i k = [15, 20, 130, 12345];
    __m128i result = _mm_sha256rnds2_epu32(a, b, k);
    assert(result.array == [1384123044, -2050674062, 327754346, 956342016]);
}

private uint bitwiseRotateRight_uint(const uint value, const uint count) @safe
{
    assert(count < 8 * uint.sizeof);
    return cast(uint) ((value >> count) | (value << (uint.sizeof * 8 - count)));
}