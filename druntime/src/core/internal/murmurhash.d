/*
 * This file has been adapted from the previous core.internal.hash
 * implementation. The original CMI is reproduced below:
 *
 * Copyright: Copyright Igor Stepanov 2013-2013.
 * License:   $(HTTP www.boost.org/LICENSE_1_0.txt, Boost License 1.0).
 * Authors:   Igor Stepanov
 *
 * MurmurHash3 was written by Austin Appleby, and is placed in the public
 * domain. The author hereby disclaims copyright to this source code.
 *
 * END OF ORIGINAL CMI
 * 
 * Modifications and additions are provided under the following license:
 * 
 * SPDX-License-Identifier: BSL-1.0
 * Copyright (C) 2026 Indraj Gandham
 *
 * END OF MODIFICATIONS CMI
 */

module core.internal.murmurhash;

@trusted @nogc nothrow pure
pragma(inline, true)
private uint get32bits(const(ubyte)* x)
{
        version (BigEndian) {
                return ((cast(uint) x[0]) << 24) |
                       ((cast(uint) x[1]) << 16) |
                       ((cast(uint) x[2]) << 8) |
                        (cast(uint) x[3]);
        } else {
                return ((cast(uint) x[3]) << 24) |
                       ((cast(uint) x[2]) << 16) |
                       ((cast(uint) x[1]) << 8) |
                        (cast(uint) x[0]);
        }
}

@trusted @nogc nothrow pure
ulong murmurHash(const ulong seed, const(ubyte)[] data)
{
        auto len = data.length;

        if (len < 4) {
                ulong val = (cast(ulong) data[0] << 16) |
                            (cast(ulong) data[len >> 1] << 8) |
                             data[len - 1];

                enum ulong c1 = 0x87c37b91114253d5;
                enum ulong c2 = 0x4cf5ad432745937f;
                enum ulong c3 = 0x52dce729;
                enum uint r1 = 31;
                enum uint r2 = 27;
                size_t h = c1 * val;
                h = (h << r1) | (h >>> (size_t.sizeof * 8 - r1));
                h = (h * c2) ^ seed;
                h = (h << r2) | (h >>> (size_t.sizeof * 8 - r2));
                return h * 5 + c3;
        }

        auto d = data.ptr;
        auto nblocks = len / 4;

        uint h1 = cast(uint) seed;

        enum uint c1 = 0xcc9e2d51;
        enum uint c2 = 0x1b873593;
        enum uint c3 = 0xe6546b64;

        auto end_d = d + nblocks * uint.sizeof;

        for (; d != end_d; d += uint.sizeof) {
                uint k1 = get32bits(d);
                k1 *= c1;
                k1 = (k1 << 15) | (k1 >> (32 - 15));
                k1 *= c2;

                h1 ^= k1;
                h1 = (h1 << 13) | (h1 >> (32 - 13));
                h1 = h1*5+c3;
        }

        //----------
        // tail
        uint k1 = 0;

        switch (len & 3)
        {
                case 3: k1 ^= d[2] << 16; goto case;
                case 2: k1 ^= d[1] << 8;  goto case;
                case 1: k1 ^= d[0];
                                k1 *= c1; k1 = (k1 << 15) | (k1 >> (32 - 15)); k1 *= c2; h1 ^= k1;
                                goto default;
                default:
        }

        //----------
        // finalization
        h1 ^= len;
        // Force all bits of the hash block to avalanche.
        h1 = (h1 ^ (h1 >> 16)) * 0x85ebca6b;
        h1 = (h1 ^ (h1 >> 13)) * 0xc2b2ae35;
        h1 ^= h1 >> 16;
        return h1;
}
