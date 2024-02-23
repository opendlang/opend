/++
Copyright: Copyright © 2016-, Ilya Yaroshenko.
License: $(HTTP boost.org/LICENSE_1_0.txt, Boost License 1.0).
Authors: Ilya Yaroshenko
+/
module glas.internal.copy;

import std.traits;
import std.meta;
import mir.ndslice.slice : Slice, SliceKind;
import ldc.attributes : fastmath, optStrategy;
import ldc.intrinsics : llvm_expect;
import glas.internal.utility;
import glas.internal.config;

@fastmath:

pragma(inline, true)
@property T[] toDense(T)(Slice!(SliceKind.universal, [1], T*) slice)
{
    return (&(slice.front()))[0 .. slice.length];
}

alias PackKernel(F, T) =
    pure nothrow @nogc
    T* function(
        size_t length,
        sizediff_t str0,
        sizediff_t str1,
        const(F)* from,
        T* to,
    );

alias PackKernelTri(F, T) =
    pure nothrow @nogc
    T* function(
        const(F)* from,
        sizediff_t str0,
        sizediff_t str1,
        T* to,
        size_t length,
        size_t start,
        size_t n,
    );

pragma(inline, false)
T* pack_b_nano(size_t n, size_t P, bool conj = false, F, T)(size_t length, sizediff_t stride, sizediff_t elemStride, const(F)* from, T* to)
{
    enum s = n * P;
    if (elemStride == 1)
    {
        do
        {
            static if (conj == false && s > 1 && !is(T == real))
            {
                import ldc.simd;
                alias V = __vector(T[s]);
                storeUnaligned!V(loadUnaligned!V(cast(T*)from), to);
            }
            else
            {
                foreach (i; Iota!n)
                {
                    static if (P == 2)
                    {
                        to[2 * i + 0] = from[i].re;
                        static if (conj == false)
                            to[2 * i + 1] =  from[i].im;
                        else
                            to[2 * i + 1] = -from[i].im;
                    }
                    else
                    {
                        to[i] = from[i];
                    }
                }
            }
            from += stride;
            to += s;
        }
        while (--length);
        return to;
    }
    else
    {
        do
        {
            foreach (i; Iota!n)
            {
                static if (P == 2)
                {
                    to[2 * i + 0] = from[elemStride * i].re;
                    static if (conj == false)
                        to[2 * i + 1] = from[elemStride * i].im;
                    else
                        to[2 * i + 1] = -from[elemStride * i].im;
                }
                else
                {
                    to[i] = from[elemStride * i];
                }
            }
            from += stride;
            to += s;
        }
        while (--length);
        return to;
    }
}

pragma(inline, false)
T* pack_a_tri(size_t P, F, T, int hem)(const(F)* from, sizediff_t str0, sizediff_t str1, T* to, size_t u, size_t length, size_t n)
{
    static if (P == 1)
    {
        pragma(inline, true);
        return pack_b_tri!(P, F, T, hem)(from, str1, str0, to, u, length, n);
    }
    else
    {
        do
        {
            auto pfrom = from;
            size_t v;
            while (v < u)
            {
                to[0] = pfrom[0].re;
                static if (hem > 0)
                    to[n] = -pfrom[0].im;
                else
                    to[n] =  pfrom[0].im;
                to++;
                pfrom += str1;
                v++;
            }
            static if (hem)
            if (v < n)
            {
                to[0] = pfrom[0].re;
                to[n] = 0;
                to++;
                pfrom += str0;
                v++;
            }
            while (v < n)
            {
                to[0] = pfrom[0].re;
                static if (hem < 0)
                    to[n] = -pfrom[0].im;
                else
                    to[n] =  pfrom[0].im;
                to++;
                pfrom += str0;
                v++;
            }
            to += n;
            from += str0;
            u++;
            length--;
        }
        while(length);        
        return to;
    }
}

pragma(inline, false)
T* pack_b_tri(size_t P, F, T, int hem)(const(F)* from, sizediff_t str0, sizediff_t str1, T* to, size_t u, size_t length, size_t n)
{
    do
    {
        auto pfrom = from;
        size_t v;
        while (v < u)
        {
            to[0] = pfrom[0].re;
            static if (P == 2)
            {
                static if (hem > 0)
                    to[1] = -pfrom[0].im;
                else
                    to[1] =  pfrom[0].im;
            }
            to += P;
            pfrom += str0;
            v++;
        }
        static if (hem)
        if (v < n)
        {
            to[0] = pfrom[0].re;
            to[1] = 0;
            to += P;
            pfrom += str1;
            v++;
        }
        while (v < n)
        {
            to[0] = pfrom[0].re;
            static if (P == 2)
            {
                static if (hem < 0)
                    to[1] = -pfrom[0].im;
                else
                    to[1] =  pfrom[0].im;
            }
            to += P;
            pfrom += str1;
            v++;
        }
        from += str1;
        u++;
        length--;
    }
    while(length);
    return to;
}

pragma(inline, false)
T* pack_a_nano(size_t n, size_t P, bool conj = false, F, T)(size_t length, sizediff_t stride, sizediff_t elemStride, const(F)* from, T* to)
{
    enum s = n * P;
    if (elemStride == 1)
    {
        do
        {
            static if (n > 1 && !is(T == real))
            {
                import ldc.simd;
                alias V = __vector(T[n]);
                static if (P == 1)
                {
                    auto rv = loadUnaligned!V(cast(T*)from);
                    *cast(V*)to = rv;
                }
                else
                {
                    auto r0 = loadUnaligned!V(cast(T*)from);
                    auto r1 = loadUnaligned!V(cast(T*)((cast(V*)from) + 1));
                    auto re = _re!V(r0, r1);
                    auto im = _im!V(r0, r1);
                    *cast(V*)to = re;
                    static if (conj == false)
                        *((cast(V*)to) + 1) =  im;
                    else
                        *((cast(V*)to) + 1) = -im;
                }
            }
            else
            foreach (j; Iota!n)
            {
                to[j] = from[j].re;
                static if (P == 2)
                {
                    static if (conj == false)
                        to[n + j] =  from[j].im;
                    else
                        to[n + j] = -from[j].im;
                }
            }
            from += stride;
            to += s;
        }
        while (--length);
        return to;
    }
    else
    {
        static if (P == 1)
        {
            return pack_b_nano!(n, P, false, F, T)(length, stride, elemStride, from, to);
        }
        else
        {
            do
            {
                foreach (i; Iota!n)
                {
                    to[i + 0] = from[elemStride * i].re;
                    static if (conj == false)
                        to[i + n] =  from[elemStride * i].im;
                    else
                        to[i + n] = -from[elemStride * i].im;
                }
                from += stride;
                to += s;
            }
            while (--length);
            return to;
        }
    }
}


pragma(inline, true)
void pack_a(size_t P, C, T)(Slice!(SliceKind.universal, [2], const(C)*) sl, T* a, PackKernel!(C, T)* kernels)
{
    mixin RegisterConfig!(P, T);
    foreach (mri, mr; mr_chain)
    if (sl.length >= mr) do
    {
        a = kernels[mri](sl.length!1, sl._stride!1, sl._stride!0, sl._iterator, a);
        sl.popFrontExactly(mr);
    }
    while (!mri && sl.length >= mr);
    return;
}

pragma(inline, true)
void pack_a_sym(size_t P, F, T)(scope const(F)* ptr, sizediff_t str0, sizediff_t str1, size_t i, size_t t, size_t mc, size_t kc, scope T* to, PackKernel!(F, T)[P]* kernels, PackKernelTri!(F, T) tri_kernel, size_t mr)
{
    do
    {
        if (mc >= mr) do
        {
            size_t j = t;
            size_t length = kc;
            {
                sizediff_t diff = i - j;
                static if(P == 1)
                    diff++;
                if (diff > 0)
                {
                    if (diff > length)
                        diff = length;
                    to = kernels[0][0](diff, str1, str0, ptr + i * str0 + j * str1, to);
                    j += diff;
                    length -= diff;
                    if (length == 0)
                    {
                        mc -= mr;
                        i += mr;
                        continue;
                    }
                }
            }
            {
                sizediff_t start = j - i;
                sizediff_t len = mr - start;
                static if (P == 1)
                    len--;
                if (len > length)
                    len = length;
                if (len > 0)
                {
                    to = tri_kernel(ptr + j * str0 + i * str1, str0, str1, to, start, len, mr);
                    length -= len;
                    j += len;
                }
            }
            if (length)
            {
                to = kernels[0][$-1](length, str0, str1, ptr + j * str0 + i * str1, to);
            }
            mc -= mr;
            i += mr;
        }
        while (mc >= mr);
        kernels++;
        mr /= 2;
    }
    while(mr);
}

version(none)
pragma(inline, false)
void pack_b_triangular(bool upper, bool inverseDiagonal, size_t P, T, C)(Slice!(SliceKind.universal, [2], const(C)*) sl, T* b)
{
    assert(sl.length!0 == sl.length!1);

    mixin RegisterConfig!(P, T);
    static if (!upper)
        size_t length;
    foreach (nri, nr; nr_chain)
    if (sl.length >= nr) do
    {
        static if (!upper)
            length += nr;
        else
            size_t length = sl.length;
        if (sl._stride!0 == 1)
            b = pack_b_dense_nano!(nr, P)(length, sl._stride!1, sl._iterator, b);
        else
            b = pack_b_strided_nano!(nr, P)(length, sl._stride!1, sl._stride!0, sl._iterator, b);
        static if (inverseDiagonal)
        {
            auto a = cast(T[P]*) b;
            foreach (i; Iota!nr)
            {
                enum sizediff_t j = i + i * nr - sizediff_t(nr * nr);
                static if (P == 1)
                {
                    a[j][0] = 1 / a[j][0];
                }
                else
                {
                    auto re = a[j][0];
                    auto im = a[j][1];
                    auto d = re * re + im * im;
                    re /= d;
                    im /= d;
                    im = -im;
                    a[j][0] = re;
                    a[j][1] = im;
                }
            }
        }
        sl.popFrontExactly(nr);
        static if (uplo)
            sl.popFrontExactly!1(nr);
    }
    while (!nri && sl.length >= nr);
}

pragma(inline, true)
void load_simd(size_t mr, size_t P, T)(T* to, const(T[P])* from)
{
    static if (mr > 1 && !is(T == real))
    {
        import ldc.simd;
        alias V = __vector(T[mr]);
        static if (P == 1)
        {
            auto rv = loadUnaligned!V(cast(T*)from);
            *cast(V*)to = rv;
        }
        else
        {
            auto r0 = loadUnaligned!V(cast(T*)from);
            auto r1 = loadUnaligned!V(cast(T*)((cast(V*)from) + 1));
            auto re = _re!V(r0, r1);
            auto im = _im!V(r0, r1);
            *cast(V*)to = re;
            *((cast(V*)to) + 1) = im;
        }
    }
    else
    foreach (j; Iota!mr)
    foreach (p; Iota!P)
        to[mr * p + j] = from[j * P][p].re;
}

pragma(inline, true)
void save_nano(size_t P, size_t N, size_t M, V, T)
    (ref V[N][P][M] reg, T[P]* c, sizediff_t ldc)
{
    foreach (m; Iota!M)
    {
        save_nano_impl(reg[m], c + ldc * m);
    }
}

pragma(inline, true)
void save_nano_kernel(size_t P, size_t N, size_t M, V, T)
    (ref V[N][P][M] reg, T[P]* c)
{
    foreach (m; Iota!M)
    {
        save_nano_impl(reg[m], c + m * V[N].sizeof / T.sizeof);
    }
}

pragma(inline, true);
void save_nano_impl(size_t P, size_t N, V, T)(ref V[N][P] reg, T[P]* c)
{
    import ldc.simd;
    foreach (j; Iota!(N))
    {
        static if (P == 1)
        {
            static if (isSIMDVector!V)
            {
                storeUnaligned!V(reg[0][j], cast(T*)(c + j * V.length));
            }
            else
            {
                c[j][0] = reg[0][j];
            }
        }
        else
        {
            static if (isSIMDVector!V)
            {
                auto re = reg[0][j];
                auto im = reg[1][j];
                auto r0 = _mix0!V(re, im);
                auto r1 = _mix1!V(re, im);
                storeUnaligned!V(r0, cast(T*)(c + j * V.length));
                storeUnaligned!V(r1, cast(T*)((cast(V*)(c + j * V.length)) + 1));
            }
            else
            {
                c[j][0] = reg[0][j];
                c[j][1] = reg[1][j];
            }
        }
    }
}

pragma(inline, true)
void save_add_nano(size_t P, size_t N, size_t M, V, T)
    (ref V[N][P][M] reg, T[P]* c, sizediff_t ldc)
{
    foreach (m; Iota!M)
    {
        save_add_nano_impl(reg[m], c + ldc * m);
    }
}

pragma(inline, true)
void save_add_nano_kernel(size_t P, size_t N, size_t M, V, T)
    (ref V[N][P][M] reg, T[P]* c)
{
    foreach (m; Iota!M)
    {
        save_add_nano_impl(reg[m], c + m * V[N].sizeof / T.sizeof);
    }
}

pragma(inline, true)
void save_add_nano_impl(size_t P, size_t N, V, T)(ref V[N][P] reg, T[P]* c)
{
    import ldc.simd;
    foreach (j; Iota!(N))
    {
        static if (P == 1)
        {
            static if (isSIMDVector!V)
            {
                auto cj = loadUnaligned!V(cast(T*)(c + j * V.length));
                cj += reg[0][j];
                storeUnaligned!V(cj, cast(T*)(c + j * V.length));
            }
            else
            {
                c[j][0] += reg[0][j];
            }
        }
        else
        {
            static if (isSIMDVector!V)
            {
                auto cj0 = loadUnaligned!V(cast(T*)(c + j * V.length));
                auto cj1 = loadUnaligned!V(cast(T*)((cast(V*)(c + j * V.length)) + 1));
                auto re = reg[0][j];
                auto im = reg[1][j];
                auto r0 = _mix0!V(re, im);
                auto r1 = _mix1!V(re, im);
                cj0 += r0;
                cj1 += r1;
                storeUnaligned!V(cj0, cast(T*)(c + j * V.length));
                storeUnaligned!V(cj1, cast(T*)((cast(V*)(c + j * V.length)) + 1));
            }
            else
            {
                c[j][0] += reg[0][j];
                c[j][1] += reg[1][j];
            }
        }
    }
}

pragma(inline, true)
void save_madd_nano(size_t P, size_t N, size_t M, V, T)(ref V[N][P][M] reg, ref const T[P] beta, T[P]* c_, sizediff_t ldc)
{
    V[P] s = void;
    s.load_nano(beta);
    foreach (m; Iota!M)
    {
        auto c = c_ + m * ldc;
        import ldc.simd;
        foreach (j; Iota!(N))
        {
            static if (P == 1)
            {
                static if (isSIMDVector!V)
                {
                    auto cj = loadUnaligned!V(cast(T*)(c + j * V.length));
                    cj = reg[m][0][j] + s[0] * cj;
                    storeUnaligned!V(cj, cast(T*)(c + j * V.length));
                }
                else
                {
                    c[j][0] = reg[m][0][j] + s[0] * c[j][0];
                }
            }
            else
            {
                static if (isSIMDVector!V)
                {
                    auto cj0 = loadUnaligned!V(cast(T*)(c + j * V.length));
                    auto cj1 = loadUnaligned!V(cast(T*)((cast(V*)(c + j * V.length)) + 1));

                    auto cre = _re!V(cj0, cj1);
                    auto cim = _im!V(cj0, cj1);

                    auto re = reg[m][0][j] + cre * s[0];
                    auto im = reg[m][1][j] + cim * s[0];

                    re -= cim * s[1];
                    im += cre * s[1];

                    auto r0 = _mix0!V(re, im);
                    auto r1 = _mix1!V(re, im);

                    storeUnaligned!V(r0, cast(T*)(c + j * V.length));
                    storeUnaligned!V(r1, cast(T*)((cast(V*)(c + j * V.length)) + 1));
                }
                else
                {
                    auto cre = c[j][0];
                    auto cim = c[j][1];

                    auto re = reg[m][0][j] + cre * s[0];
                    auto im = reg[m][1][j] + cim * s[0];

                    re -= cim * s[1];
                    im += cre * s[1];

                    c[j][0] = re;
                    c[j][1] = im;
                }
            }
        }
    }
}

template _mix0(V)
{
    import ldc.simd;
    enum _pred(size_t a) = (a & 1) == 0 ? a / 2 : a / 2 + V.length;
    alias _mix0 = shufflevector!(V, staticMap!(_pred, Iota!(V.length)));
}

template _mix1(V)
{
    import ldc.simd;
    enum _pred(size_t a) = ((a & 1) == 0 ? a / 2 : a / 2 + V.length) + V.length / 2;
    alias _mix1 = shufflevector!(V, staticMap!(_pred, Iota!(V.length)));
}

template _re(V)
{
    import ldc.simd;
    enum _pred(size_t a) = (a & 1) == 0;
    alias _re = shufflevector!(V, Filter!(_pred, Iota!(V.length * 2)));
}

template _im(V)
{
    import ldc.simd;
    enum _pred(size_t a) = (a & 1) != 0;
    alias _im = shufflevector!(V, Filter!(_pred, Iota!(V.length * 2)));
}

void load_nano(size_t M, size_t P, size_t N, V, W)(ref V[M][P][N] to, ref W[M][P][N] from)
{
    foreach (n; Iota!N)
    foreach (p; Iota!P)
    foreach (m; Iota!M)
        to[n][p][m] = from[n][p][m];
}

pragma(inline, true)
void load_nano(size_t A, V, F)
(ref V[A] to, ref const F[A] from)
    if (!isStaticArray!F)
{
    foreach (p; Iota!A)
        to[p] = from[p];
}
