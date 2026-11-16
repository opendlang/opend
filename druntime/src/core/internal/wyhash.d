/*
 * This file has been adapted from Zig's WyHash implementation. The original
 * author has kindly relicensed his work for our use:
 *
 * SPDX-License-Identifier: BSL-1.0
 * Copyright (C) 2023 Marc Tiehuis
 *
 * END OF ORIGINAL CMI
 *
 * Permission for the relicense was granted via email on 14th November 2026.
 * 
 * Modifications and additions are provided under the following license:
 * 
 * SPDX-License-Identifier: BSL-1.0
 * Copyright (C) 2026 Indraj Gandham
 *
 * END OF MODIFICATIONS CMI
 */

module core.internal.wyhash;

import core.stdc.string;

private static immutable ulong[4] ctfeSecret = [
        0xa0761d6478bd642f,
        0xe7037ed1a0b428db,
        0x8ebc6af09c88c6e3,
        0x589965cc75374cc3,
];

private immutable ulong[4] rtSecret;

shared static this() @trusted
{
        ubyte[32] buf;

        static if (size_t.sizeof != 8) {
                static assert(0, "32-bit platforms are not supported");
        }

        version(linux) {
                // Linux 3.17+
                // note 1: getentropy() unavailable when using --target=compat
                // note 2: less than 256 bytes, getrandom() won't be interrupted
                import core.sys.linux.sys.syscall;
                import core.sys.linux.unistd;
                auto res = syscall(SYS_getrandom, buf.ptr, buf.length, 0);
                if (res != buf.length) assert(0);

        } else version(Windows) {
                // Windows Vista SP2+
                import core.sys.windows.bcrypt;
                import core.sys.windows.ntdef;

                auto res = BCryptGenRandom(null,
                                           buf.ptr,
                                           cast(uint) buf.length,
                                           BCRYPT_USE_SYSTEM_PREFERRED_RNG);

                if(!NT_SUCCESS(res)) assert(0);

        } else version(OSX) {
                // macOS 10.12+ (Sierra)
                import core.sys.posix.unistd;
                auto res = getentropy(buf.ptr, buf.length);
                if (res != 0) assert(0);

        } else {
                static assert(0, "platform not supported");
        }

        ulong[4] secret;
        foreach (i; 0 .. secret.length) {
                memcpy(&(secret[i]), buf.ptr + (8 * i), 8);
        }
        rtSecret = secret;
        version (unittest) rtSecret = ctfeSecret;
}

@trusted @nogc nothrow pure
pragma(inline, true)
private ulong read8(const(ubyte)[] p)
{
        ulong v = 0;
        foreach (i; 0 .. 8)
                v |= cast(ulong) p[i] << (8 * i);
        return v;
}

@trusted @nogc nothrow pure
pragma(inline, true)
private ulong read4(const(ubyte)[] p)
{
        ulong v = 0;
        foreach (i; 0 .. 4)
                v |= cast(ulong) p[i] << (8 * i);
        return v;
}

@trusted @nogc nothrow pure
pragma(inline, true)
private void mum(ref ulong a, ref ulong b)
{
        version (LDC) {
                if (!__ctfe) {
                        import ldc.llvmasm : __ir_pure;

                        ulong hi = __ir_pure!(`%a = zext i64 %0 to i128
                                               %b = zext i64 %1 to i128
                                               %m = mul i128 %a, %b
                                               %h = lshr i128 %m, 64
                                               %r = trunc i128 %h to i64
                                               ret i64 %r`,
                                               ulong)(a, b);

                        a = a * b;
                        b = hi;
                        return;
                }
        }

        ulong al = a & 0xffffffff;
        ulong ah = a >> 32;
        ulong bl = b & 0xffffffff;
        ulong bh = b >> 32;

        ulong ll = al * bl;
        ulong lh = al * bh;
        ulong hl = ah * bl;
        ulong hh = ah * bh;

        ulong mid = (ll >> 32) + (lh & 0xffffffff) + (hl & 0xffffffff);

        a = (mid << 32) | (ll & 0xffffffff);
        b = hh + (lh >> 32) + (hl >> 32) + (mid >> 32);
}

@trusted @nogc nothrow pure
pragma(inline, true)
private ulong mix(ulong a, ulong b)
{
        mum(a, b);
        return a ^ b;
}

@trusted @nogc nothrow pure
pragma(inline, true)
private void smallKey(const(ubyte)[] p, ref ulong a, ref ulong b)
{
        size_t n = p.length;

        if (n >= 4) {
                size_t end = n - 4;
                size_t q = (n >> 3) << 2;
                a = (read4(p[0 .. $]) << 32) | read4(p[q .. $]);
                b = (read4(p[end .. $]) << 32) | read4(p[end - q .. $]);
        } else if (n > 0) {
                a = (cast(ulong) p[0] << 16) |
                    (cast(ulong) p[n >> 1] << 8) |
                    p[n - 1];

                b = 0;
        } else {
                a = 0;
                b = 0;
        }
}

@trusted @nogc nothrow pure
ulong wyHash(const ulong seed, const(ubyte)[] data)
{
        ulong[4] secret;
        if (__ctfe) secret = ctfeSecret;
        else secret = rtSecret;

        ulong n = data.length;
        ulong a;
        ulong b;
        ulong s0 = seed ^ mix(seed ^ secret[0], secret[1]);

        if (n <= 16) {
                smallKey(data, a, b);
        } else {
                ulong i = 0;

                if (n >= 48) {
                        ulong s1 = s0;
                        ulong s2 = s0;

                        while (i + 48 < n) {
                                const(ubyte)[] p = data[i .. i + 48];

                                s0 = mix(read8(p[0 .. $]) ^ secret[1],
                                         read8(p[8 .. $]) ^ s0);
                                s1 = mix(read8(p[16 .. $]) ^ secret[2],
                                         read8(p[24 .. $]) ^ s1);
                                s2 = mix(read8(p[32 .. $]) ^ secret[3],
                                         read8(p[40 .. $]) ^ s2);

                                i += 48;
                        }

                        s0 ^= s1 ^ s2;
                }

                while (i + 16 < n) {
                        s0 = mix(read8(data[i .. $]) ^ secret[1],
                                 read8(data[i + 8 .. $]) ^ s0);

                        i += 16;
                }

                a = read8(data[n - 16 .. $]);
                b = read8(data[n - 8 .. $]);
        }

        a ^= secret[1];
        b ^= s0;
        mum(a, b);
        return mix(a ^ secret[0] ^ n, b ^ secret[1]);
}

unittest
{
        struct Vector
        {
                ulong seed;
                ulong expected;
                string input;
        }

        static immutable Vector[] vectors = [
                Vector(0, 0x0409638ee2bde459, ""),
                Vector(1, 0xa8412d091b5fe0a9, "a"),
                Vector(2, 0x32dd92e4b2915153, "abc"),
                Vector(3, 0x8619124089a3a16b, "message digest"),
                Vector(4, 0x7a43afb61d7f5f40, "abcdefghijklmnopqrstuvwxyz"),
                Vector(5, 0xff42329b90e50d58, "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789"),
                Vector(6, 0xc39cab13b115aad3, "12345678901234567890123456789012345678901234567890123456789012345678901234567890"),
        ];

        foreach (v; vectors)
                assert(wyHash(v.seed,
                              cast(const(ubyte)[]) v.input)
                              == v.expected);

        static foreach (v; vectors)
                static assert(wyHash(v.seed,
                                     cast(const(ubyte)[]) v.input)
                                     == v.expected);
}
