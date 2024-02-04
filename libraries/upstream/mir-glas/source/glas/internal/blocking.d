/++
Copyright: Copyright © 2016-, Ilya Yaroshenko.
License: $(HTTP boost.org/LICENSE_1_0.txt, Boost License 1.0).
Authors: Ilya Yaroshenko
+/
module glas.internal.blocking;

import std.meta;
import std.traits;
import glas.internal.config;
import glas.precompiled.context;

enum prefetchShift = 512;

struct BlockInfo(T)
{
    sizediff_t mc;
    sizediff_t kc;
    T* a;
    T* b;
}

pragma(inline, false)
BlockInfo!T blocking(size_t P, T)(size_t m, size_t n, size_t k)
{
    glas_init();
    mixin RegisterConfig!(P, T);
    BlockInfo!T ret = void;
    sizediff_t l2 = c2 * 3 / 5; // half cache
    ret.kc = (l2 - m * T[P][main_nr].sizeof) / (m * T[P].sizeof + T[P][main_nr].sizeof);
    ret.mc = m;
    enum minKc = 320 / P;
    auto a = 2 * (T[P][main_nr][main_mr].sizeof + main_nr * line) + 512;
    if (ret.kc < minKc || ret.kc * (T[P][main_mr].sizeof + T[P][main_nr].sizeof) + a  > c1)
    {
        ret.kc = (c1 - a) / (T[P][main_mr].sizeof + T[P][main_nr].sizeof);
        assert(c1 > main_mr);
        assert(ret.kc > main_mr);
        ret.kc.normalizeChunkSize!main_mr(k);
        assert(ret.kc > 0);
        auto df = T[P][main_nr].sizeof + T[P].sizeof * ret.kc;
        ret.mc = (l2 - ret.kc * T[P][main_nr].sizeof) / df;
        ret.mc.normalizeChunkSize!main_nr(m);
    }
    else
    {
        ret.kc.normalizeChunkSize!main_mr(k);
    }
    auto a_length = ret.kc * ret.mc * T[P].sizeof;
    auto b_length = ret.kc * T[P].sizeof * (ret.mc == m && false ? main_nr : n);
    auto buffLength = a_length + b_length;
    auto _mem = memory(a_length + b_length + prefetchShift);
    ret.a = cast(T*) _mem.ptr;
    ret.b = cast(T*) (_mem.ptr + a_length);
    return ret;
}

version(none)
BlockInfo!T blocking_triangular(P, T)(size_t m, size_t n)
{
    mixin RegisterConfig!(P, T);
    BlockInfo!T ret = void;

    sizediff_t l2 = c2; // half matrix
    //ret.kc = (c1 - 2 * (T[P][main_nr][main_mr].sizeof + main_nr * line) - 512) / (T[P][main_nr].sizeof + T[P][main_mr].sizeof);

    if (l2 >= (m * ((m + main_nr) + main_mr * 2)) * T[p].sizeof)
    {
        //ret.kc = ret.mc = ret.kc > m ? m : ret.kc;
        ret.kc = ret.mc = m;
    }
    else
    {
        sizediff_t x = l2 / T.sizeof - P * (main_nr + main_mr * 2);
        assert(x > 1);
        import ldc.intrinsics: sqrt = llvm_sqrt;
        x = cast(size_t) sqrt(double(x));
        assert(x > 1);
        x.normalizeChunkSize!main_nr(m);
        ret.kc = ret.mc = x;
    }

    auto a_length = ret.kc * ret.mc * T[P].sizeof;
    auto b_length = ret.kc * T[P].sizeof * (ret.mc == m && false ? main_mr : n);
    auto buffLength = a_length + b_length;
    auto _mem = memory(a_length + b_length + prefetchShift);
    ret.b = cast(T*) _mem.ptr;
    ret.a = cast(T*) (_mem.ptr + b_length);

    return ret;
}

void normalizeChunkSize(size_t subChunk)(ref sizediff_t chunk, size_t length)
{
    assert(length);
    assert(chunk > 0);
    auto ch = chunk;
    if (ch >= length)
    {
        chunk = length;
        return;
    }
    auto count = length / ch + (length % ch != 0);
    auto new_ch = length / count + (length % count != 0);
    if (auto r = new_ch % subChunk)
    {
        auto new_new_ch = new_ch + subChunk - r;
        if (new_new_ch <= ch)
        {
            chunk = new_new_ch;
            return;
        }
    }
    chunk = new_ch;
}
