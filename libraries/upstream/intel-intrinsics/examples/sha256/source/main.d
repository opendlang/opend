// By Johan Engelen, 2021, placed in public domain.
// D source based on the C++ code written and placed in the public
// domain by Jeffrey Walton, Uri Blumenthal and Marcel Raad:
// https://cryptopp.com/docs/ref820/sha__simd_8cpp_source.html

import core.bitop: bswap;

import std.digest.sha;
import std.conv;
import std.stdio;
import std.datetime.stopwatch;

import inteli.smmintrin; // Import SSE4.1, SSSE3, SSE3, SSE2, SSE and MMX intrinsics
import inteli.shaintrin; // Import SHA instructions 

void main()
{
    getCurrentThreadHandle();
    ubyte[] onemilliona = new ubyte[512 * 2000];
    onemilliona[] = 'a';
    {
        ulong before = getTickUs();
        ubyte[32] digest256;
        foreach(N; 0..1000)
            digest256 = sha256Of(onemilliona);
        ulong after = getTickUs();
        writeln("Phobos: ", after - before, " => ", digest256.toHexString);
    }
    {
        ulong before = getTickUs();
        ubyte[32] digest256;
        foreach(N; 0..1000)
            digest256 = sha256Of_intrin(onemilliona);
        ulong after = getTickUs();
        writeln("Intrinsics: ", after - before, " => ", digest256.toHexString);
    }
}

ubyte[32] sha256Of_intrin(scope const(ubyte)[] data) nothrow @nogc
{
    uint[8] state = 
    [
        0x6a09e667, 0xbb67ae85, 0x3c6ef372, 0xa54ff53a,
        0x510e527f, 0x9b05688c, 0x1f83d9ab, 0x5be0cd19,
    ];
  
    const remainder = SHA256_HashMultipleBlocks_SHANI(state, data);
    assert(remainder < SHA256_BLOCKSIZE);
    
    // Hash remainder and final block
    ubyte[2 * SHA256_BLOCKSIZE] msg_end_data;
    const msg_end_length = (remainder < 56) ? SHA256_BLOCKSIZE : 2 * SHA256_BLOCKSIZE;
    msg_end_data[0 .. remainder] = data[$-remainder .. $];
    enum SHA256_MSG_END = 0x80;
    msg_end_data[remainder] = SHA256_MSG_END;
    
    // Encode the length in bits
    ulong bswap_len = bswap(8 * cast(ulong)data.length);
    msg_end_data[msg_end_length - 8] = cast(ubyte)(bswap_len >>  0);
    msg_end_data[msg_end_length - 7] = cast(ubyte)(bswap_len >>  8);
    msg_end_data[msg_end_length - 6] = cast(ubyte)(bswap_len >> 16);
    msg_end_data[msg_end_length - 5] = cast(ubyte)(bswap_len >> 24);
    msg_end_data[msg_end_length - 4] = cast(ubyte)(bswap_len >> 32);
    msg_end_data[msg_end_length - 3] = cast(ubyte)(bswap_len >> 40);
    msg_end_data[msg_end_length - 2] = cast(ubyte)(bswap_len >> 48);
    msg_end_data[msg_end_length - 1] = cast(ubyte)(bswap_len >> 56);
    
    SHA256_HashMultipleBlocks_SHANI(state, msg_end_data[0 .. msg_end_length]);
    
    // X86-SHA runs on a Little endian machine.
    state[0] = bswap(state[0]);
    state[1] = bswap(state[1]);
    state[2] = bswap(state[2]);
    state[3] = bswap(state[3]);
    state[4] = bswap(state[4]);
    state[5] = bswap(state[5]);
    state[6] = bswap(state[6]);
    state[7] = bswap(state[7]);

    return cast(ubyte[32])state;
}


// ***************** Intel x86 SHA ********************

enum SHA256_BLOCKSIZE = 512/8;


// Based on http://software.intel.com/en-us/articles/intel-sha-extensions and code by Sean Gulley.
size_t SHA256_HashMultipleBlocks_SHANI(ref uint[8] state, scope const(ubyte)[] data_arr) nothrow @nogc
{
    assert(data_arr);

    size_t length = data_arr.length;
    const(ubyte)* data = data_arr.ptr;

    __m128i MSG;
    __m128i TMSG0, TMSG1, TMSG2, TMSG3;
    __m128i ABEF_SAVE, CDGH_SAVE;
    // Load initial values
    __m128i TMP = _mm_loadu_si128(cast(__m128i*) &state[0]);
    __m128i STATE1 = _mm_loadu_si128(cast(__m128i*) &state[4]);

    __m128i MASK = _mm_set_epi64x(ulong(0x0c0d0e0f08090a0b), ulong(0x0405060700010203));

    TMP = _mm_shuffle_epi32!0xB1(TMP );          // CDAB
    STATE1 = _mm_shuffle_epi32!0x1B(STATE1);    // EFGH
    __m128i STATE0 = _mm_alignr_epi8!8(TMP, STATE1);    // ABEF
    STATE1 = _mm_blend_epi16!0xf0(STATE1, TMP); // CDGH   //_mm_blend_epi16

    while (length >= SHA256_BLOCKSIZE)
    {
        // Save current hash
        ABEF_SAVE = STATE0;
        CDGH_SAVE = STATE1;

        // Rounds 0-3
        MSG = _mm_loadu_si128(cast(const(__m128i)*) (data+0));
        TMSG0 = _mm_shuffle_epi8(MSG, MASK);
        MSG = _mm_add_epi32(TMSG0, _mm_set_epi64x(ulong(0xE9B5DBA5B5C0FBCF), ulong(0x71374491428A2F98)));
        STATE1 = _mm_sha256rnds2_epu32(STATE1, STATE0, MSG);
        MSG = _mm_shuffle_epi32!0x0E(MSG);
        STATE0 = _mm_sha256rnds2_epu32(STATE0, STATE1, MSG);

        // Rounds 4-7
        TMSG1 = _mm_loadu_si128(cast(const(__m128i)*) (data+16));
        TMSG1 = _mm_shuffle_epi8(TMSG1, MASK);
        MSG = _mm_add_epi32(TMSG1, _mm_set_epi64x(ulong(0xAB1C5ED5923F82A4), ulong(0x59F111F13956C25B)));
        STATE1 = _mm_sha256rnds2_epu32(STATE1, STATE0, MSG);
        MSG = _mm_shuffle_epi32!0x0E(MSG);
        STATE0 = _mm_sha256rnds2_epu32(STATE0, STATE1, MSG);
        TMSG0 = _mm_sha256msg1_epu32(TMSG0, TMSG1);


        // Rounds 8-11
        TMSG2 = _mm_loadu_si128(cast(const(__m128i)*) (data+32));
        TMSG2 = _mm_shuffle_epi8(TMSG2, MASK);
        MSG = _mm_add_epi32(TMSG2, _mm_set_epi64x(ulong(0x550C7DC3243185BE), ulong(0x12835B01D807AA98)));
        STATE1 = _mm_sha256rnds2_epu32(STATE1, STATE0, MSG);
        MSG = _mm_shuffle_epi32!0x0E(MSG);
        STATE0 = _mm_sha256rnds2_epu32(STATE0, STATE1, MSG);
        TMSG1 = _mm_sha256msg1_epu32(TMSG1, TMSG2);

        // Rounds 12-15
        TMSG3 = _mm_loadu_si128(cast(const(__m128i)*) (data+48));
        TMSG3 = _mm_shuffle_epi8(TMSG3, MASK);
        MSG = _mm_add_epi32(TMSG3, _mm_set_epi64x(ulong(0xC19BF1749BDC06A7), ulong(0x80DEB1FE72BE5D74)));
        STATE1 = _mm_sha256rnds2_epu32(STATE1, STATE0, MSG);
        TMP = _mm_alignr_epi8!4(TMSG3, TMSG2);
        TMSG0 = _mm_add_epi32(TMSG0, TMP);
        TMSG0 = _mm_sha256msg2_epu32(TMSG0, TMSG3);
        MSG = _mm_shuffle_epi32!0x0E(MSG);
        STATE0 = _mm_sha256rnds2_epu32(STATE0, STATE1, MSG);
        TMSG2 = _mm_sha256msg1_epu32(TMSG2, TMSG3);

        // Rounds 16-19
        MSG = _mm_add_epi32(TMSG0, _mm_set_epi64x(ulong(0x240CA1CC0FC19DC6), ulong(0xEFBE4786E49B69C1)));
        STATE1 = _mm_sha256rnds2_epu32(STATE1, STATE0, MSG);
        TMP = _mm_alignr_epi8!4(TMSG0, TMSG3);
        TMSG1 = _mm_add_epi32(TMSG1, TMP);
        TMSG1 = _mm_sha256msg2_epu32(TMSG1, TMSG0);
        MSG = _mm_shuffle_epi32!0x0E(MSG);
        STATE0 = _mm_sha256rnds2_epu32(STATE0, STATE1, MSG);
        TMSG3 = _mm_sha256msg1_epu32(TMSG3, TMSG0);

        // Rounds 20-23
        MSG = _mm_add_epi32(TMSG1, _mm_set_epi64x(ulong(0x76F988DA5CB0A9DC), ulong(0x4A7484AA2DE92C6F)));
        STATE1 = _mm_sha256rnds2_epu32(STATE1, STATE0, MSG);
        TMP = _mm_alignr_epi8!4(TMSG1, TMSG0);
        TMSG2 = _mm_add_epi32(TMSG2, TMP);
        TMSG2 = _mm_sha256msg2_epu32(TMSG2, TMSG1);
        MSG = _mm_shuffle_epi32!0x0E(MSG);
        STATE0 = _mm_sha256rnds2_epu32(STATE0, STATE1, MSG);
        TMSG0 = _mm_sha256msg1_epu32(TMSG0, TMSG1);

        // Rounds 24-27
        MSG = _mm_add_epi32(TMSG2, _mm_set_epi64x(ulong(0xBF597FC7B00327C8), ulong(0xA831C66D983E5152)));
        STATE1 = _mm_sha256rnds2_epu32(STATE1, STATE0, MSG);
        TMP = _mm_alignr_epi8!4(TMSG2, TMSG1);
        TMSG3 = _mm_add_epi32(TMSG3, TMP);
        TMSG3 = _mm_sha256msg2_epu32(TMSG3, TMSG2);
        MSG = _mm_shuffle_epi32!0x0E(MSG);
        STATE0 = _mm_sha256rnds2_epu32(STATE0, STATE1, MSG);
        TMSG1 = _mm_sha256msg1_epu32(TMSG1, TMSG2);

        // Rounds 28-31
        MSG = _mm_add_epi32(TMSG3, _mm_set_epi64x(ulong(0x1429296706CA6351), ulong(0xD5A79147C6E00BF3)));
        STATE1 = _mm_sha256rnds2_epu32(STATE1, STATE0, MSG);
        TMP = _mm_alignr_epi8!4(TMSG3, TMSG2);
        TMSG0 = _mm_add_epi32(TMSG0, TMP);
        TMSG0 = _mm_sha256msg2_epu32(TMSG0, TMSG3);
        MSG = _mm_shuffle_epi32!0x0E(MSG);
        STATE0 = _mm_sha256rnds2_epu32(STATE0, STATE1, MSG);
        TMSG2 = _mm_sha256msg1_epu32(TMSG2, TMSG3);

        // Rounds 32-35
        MSG = _mm_add_epi32(TMSG0, _mm_set_epi64x(ulong(0x53380D134D2C6DFC), ulong(0x2E1B213827B70A85)));
        STATE1 = _mm_sha256rnds2_epu32(STATE1, STATE0, MSG);
        TMP = _mm_alignr_epi8!4(TMSG0, TMSG3);
        TMSG1 = _mm_add_epi32(TMSG1, TMP);
        TMSG1 = _mm_sha256msg2_epu32(TMSG1, TMSG0);
        MSG = _mm_shuffle_epi32!0x0E(MSG);
        STATE0 = _mm_sha256rnds2_epu32(STATE0, STATE1, MSG);
        TMSG3 = _mm_sha256msg1_epu32(TMSG3, TMSG0);

        // Rounds 36-39
        MSG = _mm_add_epi32(TMSG1, _mm_set_epi64x(ulong(0x92722C8581C2C92E), ulong(0x766A0ABB650A7354)));
        STATE1 = _mm_sha256rnds2_epu32(STATE1, STATE0, MSG);
        TMP = _mm_alignr_epi8!4(TMSG1, TMSG0);
        TMSG2 = _mm_add_epi32(TMSG2, TMP);
        TMSG2 = _mm_sha256msg2_epu32(TMSG2, TMSG1);
        MSG = _mm_shuffle_epi32!0x0E(MSG);
        STATE0 = _mm_sha256rnds2_epu32(STATE0, STATE1, MSG);
        TMSG0 = _mm_sha256msg1_epu32(TMSG0, TMSG1);

        // Rounds 40-43
        MSG = _mm_add_epi32(TMSG2, _mm_set_epi64x(ulong(0xC76C51A3C24B8B70), ulong(0xA81A664BA2BFE8A1)));
        STATE1 = _mm_sha256rnds2_epu32(STATE1, STATE0, MSG);
        TMP = _mm_alignr_epi8!4(TMSG2, TMSG1);
        TMSG3 = _mm_add_epi32(TMSG3, TMP);
        TMSG3 = _mm_sha256msg2_epu32(TMSG3, TMSG2);
        MSG = _mm_shuffle_epi32!0x0E(MSG);
        STATE0 = _mm_sha256rnds2_epu32(STATE0, STATE1, MSG);
        TMSG1 = _mm_sha256msg1_epu32(TMSG1, TMSG2);

        // Rounds 44-47
        MSG = _mm_add_epi32(TMSG3, _mm_set_epi64x(ulong(0x106AA070F40E3585), ulong(0xD6990624D192E819)));
        STATE1 = _mm_sha256rnds2_epu32(STATE1, STATE0, MSG);
        TMP = _mm_alignr_epi8!4(TMSG3, TMSG2);
        TMSG0 = _mm_add_epi32(TMSG0, TMP);
        TMSG0 = _mm_sha256msg2_epu32(TMSG0, TMSG3);
        MSG = _mm_shuffle_epi32!0x0E(MSG);
        STATE0 = _mm_sha256rnds2_epu32(STATE0, STATE1, MSG);
        TMSG2 = _mm_sha256msg1_epu32(TMSG2, TMSG3);

        // Rounds 48-51
        MSG = _mm_add_epi32(TMSG0, _mm_set_epi64x(ulong(0x34B0BCB52748774C), ulong(0x1E376C0819A4C116)));
        STATE1 = _mm_sha256rnds2_epu32(STATE1, STATE0, MSG);
        TMP = _mm_alignr_epi8!4(TMSG0, TMSG3);
        TMSG1 = _mm_add_epi32(TMSG1, TMP);
        TMSG1 = _mm_sha256msg2_epu32(TMSG1, TMSG0);
        MSG = _mm_shuffle_epi32!0x0E(MSG);
        STATE0 = _mm_sha256rnds2_epu32(STATE0, STATE1, MSG);
        TMSG3 = _mm_sha256msg1_epu32(TMSG3, TMSG0);

        // Rounds 52-55
        MSG = _mm_add_epi32(TMSG1, _mm_set_epi64x(ulong(0x682E6FF35B9CCA4F), ulong(0x4ED8AA4A391C0CB3)));
        STATE1 = _mm_sha256rnds2_epu32(STATE1, STATE0, MSG);
        TMP = _mm_alignr_epi8!4(TMSG1, TMSG0);
        TMSG2 = _mm_add_epi32(TMSG2, TMP);
        TMSG2 = _mm_sha256msg2_epu32(TMSG2, TMSG1);
        MSG = _mm_shuffle_epi32!0x0E(MSG);
        STATE0 = _mm_sha256rnds2_epu32(STATE0, STATE1, MSG);

        // Rounds 56-59
        MSG = _mm_add_epi32(TMSG2, _mm_set_epi64x(ulong(0x8CC7020884C87814), ulong(0x78A5636F748F82EE)));
        STATE1 = _mm_sha256rnds2_epu32(STATE1, STATE0, MSG);
        TMP = _mm_alignr_epi8!4(TMSG2, TMSG1);
        TMSG3 = _mm_add_epi32(TMSG3, TMP);
        TMSG3 = _mm_sha256msg2_epu32(TMSG3, TMSG2);
        MSG = _mm_shuffle_epi32!0x0E(MSG);
        STATE0 = _mm_sha256rnds2_epu32(STATE0, STATE1, MSG);

        // Rounds 60-63
        MSG = _mm_add_epi32(TMSG3, _mm_set_epi64x(ulong(0xC67178F2BEF9A3F7), ulong(0xA4506CEB90BEFFFA)));
        STATE1 = _mm_sha256rnds2_epu32(STATE1, STATE0, MSG);
        MSG = _mm_shuffle_epi32!0x0E(MSG);
        STATE0 = _mm_sha256rnds2_epu32(STATE0, STATE1, MSG);

        // Add values back to state
        STATE0 = _mm_add_epi32(STATE0, ABEF_SAVE);
        STATE1 = _mm_add_epi32(STATE1, CDGH_SAVE);

        data += SHA256_BLOCKSIZE;
        length -= SHA256_BLOCKSIZE;
    }

    TMP = _mm_shuffle_epi32!0x1B(STATE0);       // FEBA
    STATE1 = _mm_shuffle_epi32!0xB1(STATE1);    // DCHG
    STATE0 = _mm_blend_epi16!0xF0(TMP, STATE1); // DCBA
    STATE1 = _mm_alignr_epi8!8(STATE1, TMP);    // ABEF

    // Save state
    _mm_storeu_si128(cast(__m128i*) &state[0], STATE0);
    _mm_storeu_si128(cast(__m128i*) &state[4], STATE1);

    // Return the remainder
    return length;
}



unittest
{
    assert( sha256Of("a") == cast(ubyte[]) hexString!"ca978112ca1bbdcafac231b39a23dc4da786eff8147c4e72b9807785afee48bb");
    assert( sha256Of("abc") == cast(ubyte[]) hexString!"ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad");  
    assert( sha256Of_intrin(cast(ubyte[]) "a") == cast(ubyte[]) hexString!"ca978112ca1bbdcafac231b39a23dc4da786eff8147c4e72b9807785afee48bb");
    assert( sha256Of_intrin(cast(ubyte[]) "abc") == cast(ubyte[]) hexString!"ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad");
}



version(Windows)
{
    import core.sys.windows.windows;
    __gshared HANDLE hThread;

    extern(Windows) BOOL QueryThreadCycleTime(HANDLE   ThreadHandle, PULONG64 CycleTime) nothrow @nogc;
    long qpcFrequency;
    void getCurrentThreadHandle()
    {
        hThread = GetCurrentThread();    
        QueryPerformanceFrequency(&qpcFrequency);
    }
}
else
{
    void getCurrentThreadHandle()
    {
    }
}

static long getTickUs(bool precise = true) nothrow @nogc
{
    version(Windows)
    {
        if (precise)
        {
            // Note about -precise measurement
            // We use the undocumented fact that QueryThreadCycleTime
            // seem to return a counter in QPC units.
            // That may not be the case everywhere, so -precise is not reliable and should
            // never be the default.
            import core.sys.windows.windows;
            ulong cycles;
            BOOL res = QueryThreadCycleTime(hThread, &cycles);
            assert(res != 0);
            real us = 1000.0 * cast(real)(cycles) / cast(real)(qpcFrequency);
            return cast(long)(0.5 + us);
        }
        else
        {
            import core.time;
            return convClockFreq(MonoTime.currTime.ticks, MonoTime.ticksPerSecond, 1_000_000);
        }
    }
    else
    {
        import core.time;
        return convClockFreq(MonoTime.currTime.ticks, MonoTime.ticksPerSecond, 1_000_000);
    }
}