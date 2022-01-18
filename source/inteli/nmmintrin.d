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

/*
pragma(LDC_intrinsic, "llvm.x86.sse42.crc32.32.16")
    int __builtin_ia32_crc32hi(int, short) pure @safe;

pragma(LDC_intrinsic, "llvm.x86.sse42.crc32.32.32")
    int __builtin_ia32_crc32si(int, int) pure @safe;

pragma(LDC_intrinsic, "llvm.x86.sse42.crc32.32.8")
    int __builtin_ia32_crc32qi(int, byte) pure @safe;

pragma(LDC_intrinsic, "llvm.x86.sse42.crc32.64.64")
    long __builtin_ia32_crc32di(long, long) pure @safe;
*/


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
    //import core.stdc.stdio;
    //printf("A = %x, B = %x, C = %x\n", A, B, C);
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


static if (LDC_with_SSE42)
{}
else static if (LDC_with_ARM64_CRC)
{}
else private static immutable uint[256] CRC32cTable =
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