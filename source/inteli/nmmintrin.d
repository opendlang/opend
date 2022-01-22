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
// generate SSE4.2 instruction (they are often enabled with -O1 or greater).



// <Data size and signedness>

/// String contains unsigned 8-bit characters (default).
enum int _SIDD_UBYTE_OPS = 0;

/// String contains unsigned 16-bit characters.
enum int _SIDD_UWORD_OPS = 1;

/// String contains signed 8-bit characters.
enum int _SIDD_SBYTE_OPS = 2;

/// String contains signed 16-bit characters.
enum int _SIDD_SWORD_OPS = 3;

// </Data size and signedness>


// <Comparison options>

/// For each character in `b`, find if it is in `a` (default)
/// The resulting mask has bit set at b positions that were found in a.
enum int _SIDD_CMP_EQUAL_ANY = 0;

/// For each character in `b`, determine if
/// `a[0] <= c <= a[1] or a[1] <= c <= a[2]...`
/// Contrarily to false documentation on the Internet, pairs must be in `a`!
enum int _SIDD_CMP_RANGES = 4;

/// The strings defined by `a` and `b` are equal
enum int _SIDD_CMP_EQUAL_EACH = 8;

/// Search for the defined substring in the target
enum int _SIDD_CMP_EQUAL_ORDERED = 12;

// </Comparison options>

// <Result polarity>

/// Do not negate results (default, no effect)
enum int _SIDD_POSITIVE_POLARITY = 0;

/// Negates results
enum int _SIDD_NEGATIVE_POLARITY = 16;

/// No effect. Do not negate results before the end of the string. (default when using `_SIDD_NEGATIVE_POLARITY`)
/// You basically never want this.
enum int _SIDD_MASKED_POSITIVE_POLARITY = 32;

/// Negates results only before the end of the string
enum int _SIDD_MASKED_NEGATIVE_POLARITY = 48;

// </Result polarity>

// <Bit returned>

/// **Index only**: return the least significant bit (default).
enum int _SIDD_LEAST_SIGNIFICANT = 0;

/// **Index only**: return the most significant bit.
enum int _SIDD_MOST_SIGNIFICANT = 64;

// </Bit returned>

/// **Mask only**: return the bit mask (default).
enum int _SIDD_BIT_MASK = 0;

/// **Mask only**: return the byte/word mask.
enum int _SIDD_UNIT_MASK = 64;

/// So SSE4.2 has a lot of hard-to-understand instructions. Here is another explanations.
///
/// Alternative explanation of imm8
///
/// imm8 is an 8-bit immediate operand specifying whether the characters are bytes or
///    words and the type of comparison to perform.
///
///    Bits [1:0]: Determine source data format.
///      00: 16 unsigned bytes
///      01: 8 unsigned words
///      10: 16 signed bytes
///      11: 8 signed words
///
///    Bits [3:2]: Determine comparison type and aggregation method.
///      00: Subset: Each character in B is compared for equality with all
///          the characters in A.
///      01: Ranges: Each character in B is compared to A pairs. The comparison
///          basis is greater than or equal for even-indexed elements in A,
///          and less than or equal for odd-indexed elements in A.
///      10: Match: Compare each pair of corresponding characters in A and
///          B for equality.
///      11: Substring: Search B for substring matches of A.
///
///    Bits [5:4]: Determine whether to perform a one's complement on the bit
///                mask of the comparison results. \n
///      00: No effect. \n
///      01: Negate the bit mask. \n
///      10: No effect. \n
///      11: Negate the bit mask only for bits with an index less than or equal
///          to the size of \a A or \a B.
///



/// Compare packed strings in `a` and `b` with lengths `la` and `lb` using 
/// the control in `imm8`, and returns 1 if `b` "does not contain a null character"
/// and the resulting mask was zero, and 0 otherwise.
/// Warning: actually it seems the instruction does accept \0 in input, just the length must be >= count.
///          It's not clear for what purpose.
int _mm_cmpestra(int imm8)(__m128i a, int la, __m128i b, int lb)
{
    static if (GDC_with_SSE42)
    {
        return cast(int) __builtin_ia32_pcmpestria128(cast(ubyte16)a, la, cast(ubyte16)b, lb, imm8);
    }
    else static if (LDC_with_SSE42)
    {
        return __builtin_ia32_pcmpestria128(cast(byte16)a, la, cast(byte16)b, lb, imm8);
    }
    else
    {
        // saturates lengths (the Intrinsics Guide doesn't tell this)
        if (la < 0) la = -la;
        if (lb < 0) lb = -lb;
        if (la > 16) la = 16;
        if (lb > 16) lb = 16;

        int r;
        cmpStr!imm8(a, la, b, lb, r);
        enum int Count = (imm8 & 1) ? 8 : 16;
        return (r == 0) && (lb >= Count);
    }
}
unittest
{
    char[16] A = "Maximum\x00length!!";
    char[16] B = "Mbximum\x00length!!";
    __m128i mmA = _mm_loadu_si128(cast(__m128i*)A.ptr);
    __m128i mmB = _mm_loadu_si128(cast(__m128i*)B.ptr);

    // string matching a-la strcmp, for 16-bytes of data
    // Use _SIDD_NEGATIVE_POLARITY since mask must be null, and all match must be one
    assert(1 == _mm_cmpestra!(_SIDD_UBYTE_OPS 
                            | _SIDD_CMP_EQUAL_EACH
                            | _SIDD_NEGATIVE_POLARITY)(mmA, 16, mmA, 16));
    assert(0 == _mm_cmpestra!(_SIDD_UBYTE_OPS 
                            | _SIDD_CMP_EQUAL_EACH
                            | _SIDD_NEGATIVE_POLARITY)(mmA, 16, mmB, 16));

    // test negative length, this will be clamped to 16
    assert(1 == _mm_cmpestra!(_SIDD_UBYTE_OPS 
                            | _SIDD_CMP_EQUAL_EACH
                            | _SIDD_NEGATIVE_POLARITY)(mmA, -160, mmA, -17));

    // it seems you can't compare shorter strings for equality using _mm_cmpestra (!)

    // Test 16-bit format
    assert(1 == _mm_cmpestra!(_SIDD_SWORD_OPS 
                            | _SIDD_CMP_EQUAL_EACH
                            | _SIDD_NEGATIVE_POLARITY)(mmA, 8, mmA, 8));
}

/// Compare packed strings in `a` and `b` with lengths `la` and `lb` using 
/// the control in `imm8`, and returns 1 if the resulting mask was non-zero,
/// and 0 otherwise.
int _mm_cmpestrc(int imm8)(__m128i a, int la, __m128i b, int lb)
{
    static if (GDC_with_SSE42)
    {
        return cast(int) __builtin_ia32_pcmpestric128(cast(ubyte16)a, la, cast(ubyte16)b, lb, imm8);
    }
    else static if (LDC_with_SSE42)
    {
        return cast(int) __builtin_ia32_pcmpestric128(cast(byte16)a, la, cast(byte16)b, lb, imm8);
    }
    else
    {
        // saturates lengths (the Intrinsics Guide doesn't tell this)
        if (la < 0) la = -la;
        if (lb < 0) lb = -lb;
        if (la > 16) la = 16;
        if (lb > 16) lb = 16;

        int r;
        cmpStr!imm8(a, la, b, lb, r);
        return (r != 0);
    }
}
unittest
{
    // Compare two shorter strings
    {
        char[16] A = "Hello world";
        char[16] B = "Hello moon";
        __m128i mmA = _mm_loadu_si128(cast(__m128i*)A.ptr);
        __m128i mmB = _mm_loadu_si128(cast(__m128i*)B.ptr);
        assert(0 == _mm_cmpestrc!(_SIDD_UBYTE_OPS  // match gives 0 like strcmp
                                | _SIDD_CMP_EQUAL_EACH
                                | _SIDD_NEGATIVE_POLARITY)(mmA, 6, mmB, 6));
        assert(1 == _mm_cmpestrc!(_SIDD_UBYTE_OPS 
                                | _SIDD_CMP_EQUAL_EACH
                                | _SIDD_NEGATIVE_POLARITY)(mmA, 7, mmB, 7));
    }
}

/// Compare packed strings in `a` and `b` with lengths `la` and `lb` using
/// the control in `imm8`, and return the generated index.
/// Note: if the mask is all zeroes, the returned index is always `Count` 
/// (8 or 16 depending on size).
int _mm_cmpestri(int imm8)(__m128i a, int la, __m128i b, int lb)
{
    static if (GDC_with_SSE42)
    {
        return __builtin_ia32_pcmpestri128(cast(ubyte16)a, la, cast(ubyte16)b, lb, imm8);
    }
    else static if (LDC_with_SSE42)
    {
        return __builtin_ia32_pcmpestri128(cast(byte16)a, la, cast(byte16)b, lb, imm8);
    }
    else
    {
        // saturates lengths (the Intrinsics Guide doesn't tell this)
        if (la < 0) la = -la;
        if (lb < 0) lb = -lb;
        if (la > 16) la = 16;
        if (lb > 16) lb = 16;

        int mask;
        cmpStr!imm8(a, la, b, lb, mask);

        enum int Count = (imm8 & 1) ? 8 : 16;
        static if (imm8 & _SIDD_MOST_SIGNIFICANT)
        {
            // PERF: this is awful, use bit find instructions
            int tmp = Count-1;
            while ((tmp >= 0))
            {
                if (mask & (1 << tmp))
                    return tmp;
                tmp = tmp - 1;
            }
            return Count; // Count if not found
        }
        else
        {
            // least significant bit (default)
            // PERF: this is awful, use bit find instructions
            int tmp = 0;
            while ( (tmp < Count) && !(mask & (1 << tmp)) )
            {
                tmp = tmp + 1;
            }
            return tmp; // Count if not found
        }
    }
}
unittest
{
    // Find the index of the first difference (at index 6)
    //                  v 
    char[16] A = "Hello sun";
    char[16] B = "Hello moon";

    __m128i mmA = _mm_loadu_si128(cast(__m128i*)A.ptr);
    __m128i mmB = _mm_loadu_si128(cast(__m128i*)B.ptr);

    int index = _mm_cmpestri!(_SIDD_UBYTE_OPS
                            | _SIDD_CMP_EQUAL_EACH
                            | _SIDD_NEGATIVE_POLARITY
                            | _SIDD_LEAST_SIGNIFICANT)(mmA, 9, mmB, 10);
    assert(index == 6);

    // Those string must compare equal, regardless of what happens after their length.
    index = _mm_cmpestri!(_SIDD_UBYTE_OPS
                        | _SIDD_CMP_EQUAL_EACH
                        | _SIDD_NEGATIVE_POLARITY
                        | _SIDD_LEAST_SIGNIFICANT)(mmA, 6, mmB, 6); // only look first six chars
    assert(index == 16);

    index = _mm_cmpestri!(_SIDD_UBYTE_OPS
                        | _SIDD_CMP_EQUAL_EACH
                        | _SIDD_NEGATIVE_POLARITY
                        | _SIDD_MOST_SIGNIFICANT)(mmA, 6, mmB, 6); // only look first six chars
    assert(index == 16);
}
unittest
{
    // Identify the last character that isn't an identifier character.
    //                   v (at index 7)
    char[16] A = "my_i(en)ifie";
    char[16] identRanges = "__azAz09";
    __m128i mmA = _mm_loadu_si128(cast(__m128i*)A.ptr);
    __m128i mmI = _mm_loadu_si128(cast(__m128i*)identRanges.ptr);
    byte16 mask = cast(byte16)_mm_cmpestrm!(_SIDD_UBYTE_OPS
                                            | _SIDD_CMP_RANGES
                                            | _SIDD_MASKED_NEGATIVE_POLARITY
                                            | _SIDD_UNIT_MASK)(mmI, 8, mmA, 12);
    byte[16] correctM = [0, 0, 0, 0, -1, 0, 0, -1, 0, 0, 0, 0, 0, 0, 0, 0];
    assert(mask.array == correctM);

    int index = _mm_cmpestri!(_SIDD_UBYTE_OPS
                            | _SIDD_CMP_RANGES
                            | _SIDD_MASKED_NEGATIVE_POLARITY
                            | _SIDD_MOST_SIGNIFICANT)(mmI, 8, mmA, 12);
    assert(index == 7); // ')' is the last char not to be in [__azAz09]
}
unittest
{
    // testing _SIDD_CMP_RANGES but with signed shorts comparison instead (this only makes sense for _SIDD_CMP_RANGES)
    short[8] ranges  = [0,  -1,  1000, 2000,    0,    0,    0, 0];
    short[8] numbers = [-32768, -1000, -1, -0, 0, 1, 1000, 32767];
    __m128i mmRanges = _mm_loadu_si128(cast(__m128i*)ranges.ptr);
    __m128i mmNumbers = _mm_loadu_si128(cast(__m128i*)numbers.ptr);

    short8 mask = cast(short8)_mm_cmpestrm!(_SIDD_UWORD_OPS
                                          | _SIDD_CMP_RANGES
                                          | _SIDD_UNIT_MASK)(mmRanges, 4, mmNumbers, 8);
    short[8] correctM = [ -1, -1, -1, -1, -1, -1, -1, -1];
    mask = cast(short8)_mm_cmpestrm!(_SIDD_SWORD_OPS
                                   | _SIDD_CMP_RANGES
                                   | _SIDD_UNIT_MASK)(mmRanges, 4, mmNumbers, 8);
    short[8] correctZ = [ 0, 0, 0, 0, 0, 0, -1, 0];
    assert(mask.array == correctZ);
}
unittest
{
    // Find a substring
    char[16] A = "def";
    char[16] B = "abcdefghdefff";
    char[16] C = "no substring";
    __m128i mmA = _mm_loadu_si128(cast(__m128i*)A.ptr);
    __m128i mmB = _mm_loadu_si128(cast(__m128i*)B.ptr);
    __m128i mmC = _mm_loadu_si128(cast(__m128i*)C.ptr);

    byte16 mask = cast(byte16)_mm_cmpestrm!(_SIDD_UBYTE_OPS
                                            | _SIDD_CMP_EQUAL_ORDERED
                                            | _SIDD_UNIT_MASK)(mmA, 3, mmB, 13);
    byte[16] correctM = [0, 0, 0, -1, 0, 0, 0, 0, -1, 0, 0, 0, 0, 0, 0, 0];
    assert(mask.array == correctM);

    int firstMatch = _mm_cmpestri!(_SIDD_UBYTE_OPS
                                 | _SIDD_CMP_EQUAL_ORDERED)(mmA, 3, mmB, 13);
    assert(firstMatch == 3);

    int lastMatch = _mm_cmpestri!(_SIDD_UBYTE_OPS
                                 | _SIDD_CMP_EQUAL_ORDERED
                                 | _SIDD_MOST_SIGNIFICANT)(mmA, 3, mmB, 13);
    assert(lastMatch == 8);
    firstMatch = _mm_cmpestri!(_SIDD_UBYTE_OPS
                                 | _SIDD_CMP_EQUAL_ORDERED)(mmA, -3, mmC, -12);
    assert(firstMatch == 16); // no substring found
}

/// Compare packed strings in `a` and `b` with lengths `la` and `lb` using 
/// the control in `imm8`, and return the generated mask.
__m128i _mm_cmpestrm(int imm8)(__m128i a, int la, __m128i b, int lb)
{
    static if (GDC_with_SSE42)
    {
        return cast(__m128i) __builtin_ia32_pcmpestrm128(cast(ubyte16)a, la, cast(ubyte16)b, lb, imm8);
    }
    else static if (LDC_with_SSE42)
    {
        return cast(__m128i) __builtin_ia32_pcmpestrm128(cast(byte16)a, la, cast(byte16)b, lb, imm8);
    }
    else
    {
        // saturates lengths (the Intrinsics don't tell this)
        if (la < 0) la = -la;
        if (lb < 0) lb = -lb;
        if (la > 16) la = 16;
        if (lb > 16) lb = 16;

        int mask;
        cmpStr!imm8(a, la, b, lb, mask);

        static if (imm8 & _SIDD_UNIT_MASK)
        {
            static if (imm8 & 1)
            {
                // short (PERF: this is bad)
                short8 r;
                foreach(i; 0..8)
                {
                    if (mask & (1 << i))
                        r.ptr[i] = -1;
                    else
                        r.ptr[i] = 0;
                }
                return cast(__m128i)r;
            }
            else
            {
                byte16 r;
                // byte (PERF: this is bad)
                foreach(i; 0..16)
                {
                    if (mask & (1 << i))
                        r.ptr[i] = -1;
                    else
                        r.ptr[i] = 0;
                }
                return cast(__m128i)r;
            }
        }
        else
        {
            // _SIDD_BIT_MASK
            return _mm_cvtsi32_si128(mask);
        }
    }
}
unittest
{
    char[16] A = "Hello world!";
    char[16] B = "aeiou!";
    __m128i mmA = _mm_loadu_si128(cast(__m128i*)A.ptr);
    __m128i mmB = _mm_loadu_si128(cast(__m128i*)B.ptr);

    // Find which letters from B where found in A.
    byte16 R = cast(byte16)_mm_cmpestrm!(_SIDD_UBYTE_OPS 
                                       | _SIDD_CMP_EQUAL_ANY
                                       | _SIDD_BIT_MASK)(mmA, -12, mmB, -6);
    // because 'e', 'o', and '!' were found
    byte[16] correctR = [42, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
    assert(R.array == correctR);
    byte16 M = cast(byte16) _mm_cmpestrm!(_SIDD_UBYTE_OPS 
                                        | _SIDD_CMP_EQUAL_ANY
                                        | _SIDD_UNIT_MASK)(mmA, 12, mmB, 6);
    byte[16] correctM = [0, -1, 0, -1, 0, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
    assert(M.array == correctM);
}

/// Compare packed strings in `a` and `b` with lengths `la` and `lb` using 
/// the control in `imm8`, and returns bit 0 of the resulting bit mask.
int _mm_cmpestro(int imm8)(__m128i a, int la, __m128i b, int lb)
{
    static if (GDC_with_SSE42)
    {
        return __builtin_ia32_pcmpestrio128(cast(ubyte16)a, la, cast(ubyte16)b, lb, imm8);
    }
    else static if (LDC_with_SSE42)
    {
        return __builtin_ia32_pcmpestrio128(cast(byte16)a, la, cast(byte16)b, lb, imm8);
    }
    else
    {
        int4 mask = cast(int4) _mm_cmpestrm!imm8(a, la, b, lb);
        return mask.array[0] & 1;
    }
}
unittest
{
    char[16] A = "Hallo world!";
    char[16] B = "aeiou!";
    __m128i mmA = _mm_loadu_si128(cast(__m128i*)A.ptr);
    __m128i mmB = _mm_loadu_si128(cast(__m128i*)B.ptr);

    // Find which letters from B where found in A.
    int res = _mm_cmpestro!(_SIDD_UBYTE_OPS 
                          | _SIDD_CMP_EQUAL_ANY
                          | _SIDD_BIT_MASK)(mmA, 12, mmB, -6);
    // because 'a' was found in "Hallo world!"
    assert(res == 1);
}

/// Returns 1 if "any character in a was null", and 0 otherwise.
/// Warning: what they mean is it returns 1 if the given length `la` is < Count.
int _mm_cmpestrs(int imm8)(__m128i a, int la, __m128i b, int lb)
{
    static if (GDC_with_SSE42)
    {
        return __builtin_ia32_pcmpestris128(cast(ubyte16)a, la, cast(ubyte16)b, lb, imm8);
    }
    else static if (LDC_with_SSE42)
    {
        return __builtin_ia32_pcmpestris128(cast(byte16)a, la, cast(byte16)b, lb, imm8);
    }
    else
    {
        // Yes, this intrinsic is there for symmetrical reasons and probably useless.
        // saturates lengths (the Intrinsics Guide doesn't tell this)
        if (la < 0) la = -la;
        if (la > 16) la = 16;
        enum int Count = (imm8 & 1) ? 8 : 16;
        return (la < Count);
    }
}
unittest
{
    __m128i a;
    a = 0;
    assert(_mm_cmpestrs!_SIDD_UBYTE_OPS(a, 15, a, 8) == 1);
    assert(_mm_cmpestrs!_SIDD_UBYTE_OPS(a, 16, a, 8) == 0);
    assert(_mm_cmpestrs!_SIDD_UBYTE_OPS(a, -15, a, 8) == 1);
    assert(_mm_cmpestrs!_SIDD_UBYTE_OPS(a, -16, a, 8) == 0);
}

/// Returns 1 if "any character in b was null", and 0 otherwise.
/// Warning: what they mean is it returns 1 if the given length `lb` is < Count.
int _mm_cmpestrz(int imm8)(__m128i a, int la, __m128i b, int lb)
{
    static if (GDC_with_SSE42)
    {
        return __builtin_ia32_pcmpestriz128(cast(ubyte16)a, la, cast(ubyte16)b, lb, imm8);
    }
    else static if (LDC_with_SSE42)
    {
        return __builtin_ia32_pcmpestriz128(cast(byte16)a, la, cast(byte16)b, lb, imm8);
    }
    else
    {
        // Yes, this intrinsic is there for symmetrical reasons and probably useless.
        // saturates lengths (the Intrinsics Guide doesn't tell this)
        if (lb < 0) lb = -lb;
        if (lb > 16) lb = 16;
        enum int Count = (imm8 & 1) ? 8 : 16;
        return (lb < Count);
    }
}
unittest
{
    __m128i b;
    b = 0;
    assert(_mm_cmpestrs!_SIDD_UBYTE_OPS(b, 15, b, 15) == 1);
    assert(_mm_cmpestrs!_SIDD_UBYTE_OPS(b, 16, b, 16) == 0);
    assert(_mm_cmpestrs!_SIDD_UBYTE_OPS(b, -15, b, -15) == 1);
    assert(_mm_cmpestrs!_SIDD_UBYTE_OPS(b, -16, b, -16) == 0);
}

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

/// Starting with the initial value in `crc`, accumulates a CRC32 value 
/// for unsigned 16-bit integer `v`.
/// Warning: this is computing CRC-32C (Castagnoli), not CRC-32.
uint _mm_crc32_u16 (uint crc, ushort v) @safe
{
    static if (GDC_with_SSE42)
    {
        return __builtin_ia32_crc32hi(crc, v);
    }
    else static if (LDC_with_SSE42)
    {
        return __builtin_ia32_crc32hi(crc, v);
    }
    else static if (LDC_with_ARM64_CRC)
    {
        return __crc32ch(crc, v);
    }
    else
    {
        crc = _mm_crc32_u8(crc, v & 0xff);
        crc = _mm_crc32_u8(crc, v >> 8);
        return crc;
    }
}
unittest
{
    uint A = _mm_crc32_u16(0x12345678, 0x4512);
    uint B = _mm_crc32_u16(0x76543210, 0xf50f);
    uint C = _mm_crc32_u16(0xDEADBEEF, 0x0017);
    assert(A == 0x39c3f0ff);
    assert(B == 0xcffbcf07);
    assert(C == 0xc7e3fe85);
}

/// Starting with the initial value in `crc`, accumulates a CRC32 value 
/// for unsigned 32-bit integer `v`.
/// Warning: this is computing CRC-32C (Castagnoli), not CRC-32.
uint _mm_crc32_u32 (uint crc, uint v) @safe
{
    static if (GDC_with_SSE42)
    {
        return __builtin_ia32_crc32si(crc, v);
    }
    else static if (LDC_with_SSE42)
    {
        return __builtin_ia32_crc32si(crc, v);
    }
    else static if (LDC_with_ARM64_CRC)
    {
        return __crc32cw(crc, v);
    }
    else
    {
        crc = _mm_crc32_u8(crc, v & 0xff);
        crc = _mm_crc32_u8(crc, (v >> 8) & 0xff);
        crc = _mm_crc32_u8(crc, (v >> 16) & 0xff);
        crc = _mm_crc32_u8(crc, (v >> 24) & 0xff);
        return crc;
    }
}
unittest
{
    uint A = _mm_crc32_u32(0x12345678, 0x45123563);
    uint B = _mm_crc32_u32(0x76543210, 0xf50f9993);
    uint C = _mm_crc32_u32(0xDEADBEEF, 0x00170017);
    assert(A == 0x22a6ec54);
    assert(B == 0x7019a6cf);
    assert(C == 0xbc552c27);
}

/// Starting with the initial value in `crc`, accumulates a CRC32 
/// value for unsigned 64-bit integer `v`.
/// Warning: this is computing CRC-32C (Castagnoli), not CRC-32.
ulong _mm_crc32_u64 (ulong crc, ulong v)
{
    version(X86_64)
        enum bool hasX86Intrin = GDC_with_SSE42 || LDC_with_SSE42;
    else
        enum bool hasX86Intrin = false; // intrinsics not available in 32-bit

    static if (hasX86Intrin)
    {
        return __builtin_ia32_crc32di(crc, v);
    }
    else static if (LDC_with_ARM64_CRC)
    {
        return __crc32cd(cast(uint)crc, v);
    }
    else
    {
        // PERF: is there actually a better algorithm? Intel pseudocode
        // looks shorter.
        uint crc32 = cast(uint)crc;
        crc32 = _mm_crc32_u8(crc32, (v >> 0) & 0xff);
        crc32 = _mm_crc32_u8(crc32, (v >> 8) & 0xff);
        crc32 = _mm_crc32_u8(crc32, (v >> 16) & 0xff);
        crc32 = _mm_crc32_u8(crc32, (v >> 24) & 0xff);
        crc32 = _mm_crc32_u8(crc32, (v >> 32) & 0xff);
        crc32 = _mm_crc32_u8(crc32, (v >> 40) & 0xff);
        crc32 = _mm_crc32_u8(crc32, (v >> 48) & 0xff);
        crc32 = _mm_crc32_u8(crc32, (v >> 56) & 0xff);
        return crc32;
    }
}
unittest
{
    ulong A = _mm_crc32_u64(0x1234567812345678, 0x39C3F0FFCFFBCF07);
    ulong B = _mm_crc32_u64(0x7654321001234567, 0xFACEFEED);
    ulong C = _mm_crc32_u64(0xDEADBEEFCAFEBABE, 0x0017C7E3FE850017);
    assert(A == 0xd66b1074);
    assert(B == 0xac12f9c6);
    assert(C == 0xa2d13dd8);
}

/// Starting with the initial value in `crc`, accumulates a CRC32 value 
/// for unsigned 8-bit integer `v`.
/// Warning: this is computing CRC-32C (Castagnoli), not CRC-32.
uint _mm_crc32_u8 (uint crc, ubyte v) @safe
{
    static if (GDC_with_SSE42)
    {
        return __builtin_ia32_crc32qi(crc, v);
    }
    else static if (LDC_with_SSE42)
    {
        return __builtin_ia32_crc32qi(crc, v);
    }
    else static if (LDC_with_ARM64_CRC)
    {
        return __crc32cb(crc, v);
    }
    else
    {
        return CRC32cTable[(crc ^ v) & 0xFF] ^ (crc >> 8); 
    }
}
unittest
{
    uint A = _mm_crc32_u8(0x12345678, 0x45);
    uint B = _mm_crc32_u8(0x76543210, 0xf5);
    uint C = _mm_crc32_u8(0xDEADBEEF, 0x00);
    assert(A == 0x8fd93134);
    assert(B == 0xd6b7e834);
    assert(C == 0xbdfd3980);
}


// Utilities for this file

private:

static if (GDC_with_SSE42)
{
    version(X86_64)
        enum bool NeedCRC32CTable = false;
    else
        enum bool NeedCRC32CTable = true;
}
else static if (LDC_with_SSE42)
{
    version(X86_64)
        enum bool NeedCRC32CTable = false;
    else
        enum bool NeedCRC32CTable = true;
}
else static if (LDC_with_ARM64_CRC)
{
    enum bool NeedCRC32CTable = false;
}
else
{
    enum bool NeedCRC32CTable = true;
}

static if (NeedCRC32CTable)
{
    static immutable uint[256] CRC32cTable =
    [
        0x0, 0xf26b8303, 0xe13b70f7, 0x1350f3f4, 0xc79a971f, 0x35f1141c, 0x26a1e7e8, 0xd4ca64eb,
        0x8ad958cf, 0x78b2dbcc, 0x6be22838, 0x9989ab3b, 0x4d43cfd0, 0xbf284cd3, 0xac78bf27, 0x5e133c24,
        0x105ec76f, 0xe235446c, 0xf165b798, 0x30e349b, 0xd7c45070, 0x25afd373, 0x36ff2087, 0xc494a384,
        0x9a879fa0, 0x68ec1ca3, 0x7bbcef57, 0x89d76c54, 0x5d1d08bf, 0xaf768bbc, 0xbc267848, 0x4e4dfb4b,
        0x20bd8ede, 0xd2d60ddd, 0xc186fe29, 0x33ed7d2a, 0xe72719c1, 0x154c9ac2, 0x61c6936, 0xf477ea35,
        0xaa64d611, 0x580f5512, 0x4b5fa6e6, 0xb93425e5, 0x6dfe410e, 0x9f95c20d, 0x8cc531f9, 0x7eaeb2fa,
        0x30e349b1, 0xc288cab2, 0xd1d83946, 0x23b3ba45, 0xf779deae, 0x5125dad, 0x1642ae59, 0xe4292d5a,
        0xba3a117e, 0x4851927d, 0x5b016189, 0xa96ae28a, 0x7da08661, 0x8fcb0562, 0x9c9bf696, 0x6ef07595,
        0x417b1dbc, 0xb3109ebf, 0xa0406d4b, 0x522bee48, 0x86e18aa3, 0x748a09a0, 0x67dafa54, 0x95b17957,
        0xcba24573, 0x39c9c670, 0x2a993584, 0xd8f2b687, 0xc38d26c, 0xfe53516f, 0xed03a29b, 0x1f682198,
        0x5125dad3, 0xa34e59d0, 0xb01eaa24, 0x42752927, 0x96bf4dcc, 0x64d4cecf, 0x77843d3b, 0x85efbe38,
        0xdbfc821c, 0x2997011f, 0x3ac7f2eb, 0xc8ac71e8, 0x1c661503, 0xee0d9600, 0xfd5d65f4, 0xf36e6f7,
        0x61c69362, 0x93ad1061, 0x80fde395, 0x72966096, 0xa65c047d, 0x5437877e, 0x4767748a, 0xb50cf789,
        0xeb1fcbad, 0x197448ae, 0xa24bb5a, 0xf84f3859, 0x2c855cb2, 0xdeeedfb1, 0xcdbe2c45, 0x3fd5af46,
        0x7198540d, 0x83f3d70e, 0x90a324fa, 0x62c8a7f9, 0xb602c312, 0x44694011, 0x5739b3e5, 0xa55230e6,
        0xfb410cc2, 0x92a8fc1, 0x1a7a7c35, 0xe811ff36, 0x3cdb9bdd, 0xceb018de, 0xdde0eb2a, 0x2f8b6829,
        0x82f63b78, 0x709db87b, 0x63cd4b8f, 0x91a6c88c, 0x456cac67, 0xb7072f64, 0xa457dc90, 0x563c5f93,
        0x82f63b7, 0xfa44e0b4, 0xe9141340, 0x1b7f9043, 0xcfb5f4a8, 0x3dde77ab, 0x2e8e845f, 0xdce5075c,
        0x92a8fc17, 0x60c37f14, 0x73938ce0, 0x81f80fe3, 0x55326b08, 0xa759e80b, 0xb4091bff, 0x466298fc,
        0x1871a4d8, 0xea1a27db, 0xf94ad42f, 0xb21572c, 0xdfeb33c7, 0x2d80b0c4, 0x3ed04330, 0xccbbc033,
        0xa24bb5a6, 0x502036a5, 0x4370c551, 0xb11b4652, 0x65d122b9, 0x97baa1ba, 0x84ea524e, 0x7681d14d,
        0x2892ed69, 0xdaf96e6a, 0xc9a99d9e, 0x3bc21e9d, 0xef087a76, 0x1d63f975, 0xe330a81, 0xfc588982,
        0xb21572c9, 0x407ef1ca, 0x532e023e, 0xa145813d, 0x758fe5d6, 0x87e466d5, 0x94b49521, 0x66df1622,
        0x38cc2a06, 0xcaa7a905, 0xd9f75af1, 0x2b9cd9f2, 0xff56bd19, 0xd3d3e1a, 0x1e6dcdee, 0xec064eed,
        0xc38d26c4, 0x31e6a5c7, 0x22b65633, 0xd0ddd530, 0x417b1db, 0xf67c32d8, 0xe52cc12c, 0x1747422f,
        0x49547e0b, 0xbb3ffd08, 0xa86f0efc, 0x5a048dff, 0x8ecee914, 0x7ca56a17, 0x6ff599e3, 0x9d9e1ae0,
        0xd3d3e1ab, 0x21b862a8, 0x32e8915c, 0xc083125f, 0x144976b4, 0xe622f5b7, 0xf5720643, 0x7198540,
        0x590ab964, 0xab613a67, 0xb831c993, 0x4a5a4a90, 0x9e902e7b, 0x6cfbad78, 0x7fab5e8c, 0x8dc0dd8f,
        0xe330a81a, 0x115b2b19, 0x20bd8ed, 0xf0605bee, 0x24aa3f05, 0xd6c1bc06, 0xc5914ff2, 0x37faccf1,
        0x69e9f0d5, 0x9b8273d6, 0x88d28022, 0x7ab90321, 0xae7367ca, 0x5c18e4c9, 0x4f48173d, 0xbd23943e,
        0xf36e6f75, 0x105ec76, 0x12551f82, 0xe03e9c81, 0x34f4f86a, 0xc69f7b69, 0xd5cf889d, 0x27a40b9e,
        0x79b737ba, 0x8bdcb4b9, 0x988c474d, 0x6ae7c44e, 0xbe2da0a5, 0x4c4623a6, 0x5f16d052, 0xad7d5351,
    ];
}

// Implementation of all the weird SSE4.2 string instructions
// PERF: This is a slow emulation for now.
void cmpStr(int imm8)(__m128i a, int la, __m128i b, int lb, out int intResult)
{
    enum int Mode = (imm8 >> 2) & 3;

    // 8 or 16-bit characters
    static if (imm8 & 1)
    {
        enum int size = 16;
        enum UpperBound = 8;
        alias Vec = short8;
        alias ResType = ubyte;
        alias UnsignedVecType = ushort;
    }
    else
    {
        enum int size = 8;
        enum UpperBound = 16; // Note: our "UpperBound" is one more than in Intel pseudocode
        alias Vec = byte16;
        alias ResType = ushort;
        alias UnsignedVecType = ubyte;
    }
    enum ResType SizeMask = cast(ResType)-1;

    bool[UpperBound][UpperBound] BoolRes;
    bool aInvalid = false;

    Vec va = cast(Vec)a;
    Vec vb = cast(Vec)b;

    // compare characters in all pairs
    for (int i = 0; i < UpperBound; ++i)
    {
        bool bInvalid = false;
        for (int j = 0; j < UpperBound; ++j)
        {
            static if (Mode == 1) // ranges mode must do >= and <= instead of ==
            {
                enum bool signed = (imm8 & 2) != 0;
                static if (!signed)
                {
                    bool equal = (i & 1) ? (cast(UnsignedVecType)vb.array[j] <= cast(UnsignedVecType)va.array[i]) 
                                         : (cast(UnsignedVecType)vb.array[j] >= cast(UnsignedVecType)va.array[i]);
                }
                else
                {
                    bool equal = (i & 1) ? (vb.array[j] <= va.array[i]) 
                                         : (vb.array[j] >= va.array[i]);
                }
            }
            else
            {
                bool equal = va.array[i] == vb.array[j];
            }

            if (i == la)
                aInvalid = true;

            if (j == lb)
                bInvalid = true;

            bool anyInvalid = aInvalid || bInvalid;

            // Override comparisons for invalid characters.
            static if (Mode == 0 || Mode == 1)
            {
                if (anyInvalid) equal = false;
            }
            else static if (Mode == 2)
            {
                if (!aInvalid && bInvalid)
                    equal = false;
                else if (aInvalid && !bInvalid)
                    equal = false;
                else if (aInvalid && bInvalid)
                    equal = true;
            }
            else static if (Mode == 3)
            {
                if (!aInvalid && bInvalid)
                    equal = false;
                else if (aInvalid && !bInvalid)
                    equal = true;
                else if (aInvalid && bInvalid)
                    equal = true;
            }
            BoolRes[i][j] = equal;
        }
    }

    static if (Mode == 0) // equal any
    {
        ResType IntRes1 = 0;
        for (int i = 0; i < UpperBound; ++i)
        {
            for (int j = 0; j < UpperBound; ++j)
            {
                if (BoolRes[i][j])
                    IntRes1 |= (1 << j);
            }
        }
    }
    else static if (Mode == 1) // ranges
    {
        ResType IntRes1 = 0;
        for (int i = 0; i < UpperBound; i += 2)
        {
            for (int j = 0; j < UpperBound; ++j)
            {
                if (BoolRes[i][j] && BoolRes[i+1][j])
                    IntRes1 |= (1 << j);
            }
        }
    }
    else static if (Mode == 2) // equal each
    {
        ResType IntRes1 = 0;
        for (int i = 0; i < UpperBound; ++i)
        {   
            if (BoolRes[i][i])
                IntRes1 |= (1 << i);
        }
    }
    else static if (Mode == 3) // equal ordered (substring search)
    {
        ResType IntRes1 = SizeMask;
        for (int j = 0; j < UpperBound; ++j)
        {
            for (int i = 0; i < UpperBound - j; ++i)
            {
                int k = i + j;
                if (!BoolRes[i][k])
                    IntRes1 &= ~(1 << j);
            }
        }
    }

    static if (imm8 & 16)
    {
        static if (imm8 & _SIDD_MASKED_POSITIVE_POLARITY) // only negate valid
        {
            ResType IntRes2 = IntRes1;
            for (int i = 0; i < UpperBound; ++i)
            {
                if (i < lb)
                    IntRes2 ^= (1 << i);
            }
        }
        else
        {
            // negate all
            ResType IntRes2 = cast(ResType)(~cast(int)IntRes1);
        }
    }
    else
    {
        // don't negate
        ResType IntRes2 = IntRes1;
    }
    intResult = IntRes2;
}
