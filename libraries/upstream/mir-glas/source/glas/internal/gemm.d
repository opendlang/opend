/++
Copyright: Copyright © 2016-, Ilya Yaroshenko.
License: $(HTTP boost.org/LICENSE_1_0.txt, Boost License 1.0).
Authors: Ilya Yaroshenko
+/
module glas.internal.gemm;

import std.traits;
import std.meta;
import mir.ndslice.slice : Slice, SliceKind;

import ldc.attributes;
import ldc.intrinsics;

import glas.ndslice;
import glas.internal.blocking;
import glas.internal.copy;
import glas.internal.config;
import glas.internal.utility;

@fastmath:

version = GLAS_PREFETCH;

pragma(inline, true)
//@optStrategy("optsize")
nothrow @nogc
void gemm_impl(C)
(
    C alpha,
    Slice!(SliceKind.universal, [2], const(C)*) asl,
    Slice!(SliceKind.universal, [2], const(C)*) bsl,
    C beta,
    Slice!(SliceKind.universal, [2], C*) _csl,
    ulong settings,
)
{
    mixin prefix3;
    mixin RegisterConfig!(P, T);
    import mir.ndslice.dynamic: reversed, transposed;
    //#########################################################
    if (llvm_expect(_csl.anyEmpty, false))
        return;
    if (llvm_expect(_csl._stride!0 < 0, false))
    {
        _csl = _csl.reversed!0;
        asl = asl.reversed!0;
    }
    if (llvm_expect(_csl._stride!1 < 0, false))
    {
        _csl = _csl.reversed!1;
        bsl = bsl.reversed!1;
    }
    // change row based to column based
    if (_csl._stride!0 != 1)
    {
        auto ca = settings & ConjA;
        auto cb = settings & ConjB;
        settings &= ~(ConjA | ConjB);
        if(ca)
            settings ^= ConjB;
        if(cb)
            settings ^= ConjA;
            auto tsl = asl;
        asl = bsl.transposed;
        bsl = tsl.transposed;
        _csl = _csl.transposed;
    }
    assert(_csl._stride!0 == 1);
    import mir.ndslice.topology: assumeCanonical;
    auto csl = _csl.transposed.assumeCanonical;
    if (llvm_expect(asl.empty!1 || alpha == 0, false))
    {
        gemm_fast_path(beta, csl.length!0, csl._stride!0, csl.length!1, csl._iterator);
        return;
    }
    //#########################################################
    PackKernel!(C, T)[mr_chain.length] pack_a_kernels = void;
    PackKernel!(C, T)[nr_chain.length] pack_b_kernels = void;
    Kernel!(P, T)    [nr_chain.length]   beta_kernels = void;
    Kernel!(P, T)    [nr_chain.length]    one_kernels = void;
    Kernel!(P, T)*                            kernels = void;

    static if (P == 2)
    {
        if (settings & ConjA)
        foreach (mri, mr; mr_chain)
            pack_a_kernels[mri] = &pack_a_nano!(mr, P, 1, C, T);
        else
        foreach (mri, mr; mr_chain)
            pack_a_kernels[mri] = &pack_a_nano!(mr, P, 0, C, T);
    }
    else
    {
        foreach (mri, mr; mr_chain)
            pack_a_kernels[mri] = &pack_a_nano!(mr, P, 0, C, T);
    }
    static if (P == 2)
    {
        if (settings & ConjB)
        foreach (nri, nr; nr_chain)
            pack_b_kernels[nri] = &pack_b_nano!(nr, P, 1, C, T);
        else
        foreach (nri, nr; nr_chain)
            pack_b_kernels[nri] = &pack_b_nano!(nr, P, 0, C, T);
    }
    else
    {
        foreach (nri, nr; nr_chain)
            pack_b_kernels[nri] = &pack_b_nano!(nr, P, 0, C, T);
    }
    foreach (nri, nr; nr_chain)
    {
        one_kernels[nri] = &gemv_reg!(BetaType.one, P, nr, T);
    }
    kernels = one_kernels.ptr;
    if (beta == 0)
    {
        foreach (nri, nr; nr_chain)
            beta_kernels[nri] = &gemv_reg!(BetaType.zero, P, nr, T);
        kernels = beta_kernels.ptr;
    }
    else
    if (beta != 1)
    {
        foreach (nri, nr; nr_chain)
            beta_kernels[nri] = &gemv_reg!(BetaType.beta, P, nr, T);
        kernels = beta_kernels.ptr;
    }
    C[2] alpha_beta = [alpha, beta];
    //#########################################################
    with(blocking!(P, T)(asl.length!0, bsl.length!1, asl.length!1))
    {
        sizediff_t incb;
        if (mc < asl.length!0)
            incb = kc;
        do
        {
            if (asl.length!1 < kc)
                kc = asl.length!1;
            ////////////////////////
            auto aslp = asl[0 .. $, 0 .. kc];
            auto bsl_ptr = bsl._iterator;
            auto cslm = csl;
            auto mc = mc;
            //======================
            do
            {
                if (aslp.length!0 < mc)
                    mc = aslp.length!0;
                ////////////////////////
                pack_a!(P, C, T)(aslp[0 .. mc], a, pack_a_kernels.ptr);
                //======================
                gebp!(P, T, C)(
                    mc,
                    bsl.length!1,
                    kc,
                    a,
                    b,
                    incb,
                    bsl_ptr,
                    bsl._stride!0,
                    bsl._stride!1,
                    cast(T*) cslm._iterator,
                    cslm._stride!0,
                    *cast(T[P][2]*)&alpha_beta,
                    pack_b_kernels.ptr,
                    kernels,
                    );
                ////////////////////////
                bsl_ptr = null;
                cslm.popFrontExactly!1(mc);
                aslp.popFrontExactly!0(mc);
            }
            while (aslp.length!0);
            ////////////////////////
            kernels = one_kernels.ptr;
            bsl.popFrontExactly!0(kc);
            asl.popFrontExactly!1(kc);
        }
        while (asl.length!1);
    }
}

pragma(inline, true)
void gebp(size_t P, T, C)(
    size_t mc,
    size_t nc,
    size_t kc,
    const(T)* a,
    T* b,
    sizediff_t incb,
    const(C)* ptrb,
    sizediff_t ldb,
    sizediff_t ldbe,
    T* c,
    sizediff_t ldc,
    ref const T[P][2] alpha_beta,
    PackKernel!(C, T)* pack_b_kernels,
    Kernel!(P, T)* kernels,
    )
{
    mixin RegisterConfig!(P, T);
    foreach (nri, nr; nr_chain)
    if (nc >= nr) do
    {
        if (ptrb)
        {
            pack_b_kernels[nri](kc, ldb, ldbe, ptrb, b);
            ptrb += nr * ldbe;
        }
        kernels[nri](mc, kc, a, b, c, ldc, alpha_beta);
        b +=  nr * P * incb;
        nc -= nr;
        c += nr * P * ldc;
    }
    while (!nri && nc >= nr);
}

alias Kernel(size_t P, T) =
    pure nothrow @nogc
    void function(
        size_t mc,
        size_t kc,
        const(T)* a,
        const(T)* b,
        T* c,
        sizediff_t ldc,
        ref const T[P][2] alpha_beta,
    );

pragma(inline, false)
@optStrategy("minsize")
void gemm_fast_path(C)(C beta, size_t length, sizediff_t stride, size_t n,  C* ptr)
{
    if (llvm_expect(beta == 0, true))
    do {
        import core.stdc.string: memset;
        memset(
            ptr, 0, n * C.sizeof);
        ptr += stride;
        length--;
    }
    while (length);
    else
    if (llvm_expect(beta == 1, true))
    {}
    else
    {
        do{
            import glas.ndslice: scal;
            scal(beta, n, 1, ptr);
            ptr += stride;
            length--;
        }
        while (length);
    }
}

pragma(inline, false)
pure nothrow @nogc
void gemv_reg (
    BetaType beta_type,
    size_t P,
    size_t N,
    F,
)
(
    size_t mc,
    size_t kc,
    const(F)* a,
    const(F)* b,
    F* c,
    sizediff_t ldc,
    ref const F[P][2] alpha_beta,
)
{
    mixin RegisterConfig!(P, F);
    foreach (mri, mr; mr_chain)
    if (mc >= mr) do
    {
        enum M = Mi!(mri);
        alias V = Vi!(mri);
        auto as = a;
        a = cast(typeof(a)) dot_reg!beta_type(cast(const(V[M][P])*)a, cast(const(F[P][N])*)b, kc, cast(F[P]*)c, ldc, alpha_beta);
        mc -= mr;
        c += mr * P;
    }
    while (!mri && mc >= mr);
}

mixin template prefix3()
{
    import glas.internal.utility: isComplex, realType;
    enum CA = isComplex!C;

    enum P = isComplex!C ? 2 : 1;

    alias T = realType!C;
    static assert(!isComplex!T);
}

enum msgWrongType = "result slice must be not qualified (const/immutable/shared)";

enum BetaType
{
    zero,
    one,
    beta,
}

pragma(inline, true)
pure nothrow @nogc
const(V[M][P])* dot_reg (
    BetaType beta_type,
    size_t P,
    size_t M,
    size_t N,
    V,
    F,
)
(
    const(V[M][P])* a,
    const(F[P][N])* b,
    size_t length,
    F[P]* c,
    sizediff_t ldc,
    ref const F[P][2] alpha_beta,
)
{
    prefetch_w!(V[M][P].sizeof, N, 1)(c, ldc * c[0].sizeof);
    V[M][P][N] reg = void;
    a = dot_reg_basic(a, b, length, reg);
    scale_nano(alpha_beta[0], reg);
    static if (beta_type == BetaType.zero)
        save_nano(reg, c, ldc);
    else
    static if (beta_type == BetaType.one)
        save_add_nano(reg, c, ldc);
    else
        save_madd_nano(reg, alpha_beta[1], c, ldc);
    return a;
}

pragma(inline, true)
nothrow @nogc
const(V[M][P])*
dot_reg_basic (

    size_t P,
    size_t M,
    size_t N,
    V,
    F,
)
(
    const(V[M][P])* a,
    const(F[P][N])* b,
    size_t length,
    ref V[M][P][N] c,
)
    if (is(V == F) || isSIMDVector!V)
{
    V[M][P][N] reg = void;

    foreach (n; Iota!N)
    foreach (p; Iota!P)
    foreach (m; Iota!M)
        reg[n][p][m] = 0;
    do
    {
        V[M][P] ai = void;
        V[P][N] bi = void;

        prefetch_r!(V[M][P].sizeof, 1, 8, prefetchShift)(cast(void*)a, 0);

        foreach (p; Iota!P)
        foreach (m; Iota!M)
            ai[p][m] = a[0][p][m];

        static if (P == 1)
        //foreach (n; Iota!N)
        //{
        //    foreach (p; Iota!P)
        //        bi[n][p] = b[0][n][p];
        //    foreach (m; Iota!M)
        //    {
        //        reg[n][0][m] += ai[0][m] * bi[n][0];
        //    }
        //}
        //else
        foreach (u; Iota!(N/2 + N%2))
        {
            alias um = Iota!(2*u, 2*u + 2 > N ? 2*u + 1 : 2*u + 2);
            foreach (n; um)
            foreach (p; Iota!P)
                bi[n][p] = b[0][n][p];
            foreach (n; um)
            foreach (m; Iota!M)
            {
                reg[n][0][m] += ai[0][m] * bi[n][0];
            }
        }
        else
        foreach (n; Iota!N)
        {
            foreach (p; Iota!P)
                bi[n][p] = b[0][n][p];
            foreach (m; Iota!M)
            {
                reg[n][1][m] += ai[1][m] * bi[n][0];
                reg[n][0][m] += ai[0][m] * bi[n][0];
                reg[n][1][m] += ai[0][m] * bi[n][1];
                reg[n][0][m] -= ai[1][m] * bi[n][1];
            }
        }
        a++;
        b++;
        length--;
    }
    while (length);

    foreach (n; Iota!N)
    foreach (p; Iota!P)
    foreach (m; Iota!M)
        c[n][p][m] = reg[n][p][m];

    return a;
}

pragma(LDC_intrinsic, "llvm.prefetch")
    pure nothrow @nogc
    void llvm_prefetch(void* ptr, uint rw, uint locality, uint cachetype);

pragma(inline, true)
pure
void prefetch_w(size_t M, size_t N, size_t rem = 1)(void* ptr, sizediff_t ld)
{
    version(GLAS_PREFETCH)
    {
        foreach (n; Iota!N)
        {
            foreach (m; Iota!(M / 64 + bool(M % 64 >= rem)))
                llvm_prefetch(ptr + m * 64, 1, 3, 1);
            ptr += ld;
        }
    }
}

pragma(inline, true)
pure
void prefetch_r(size_t M, size_t N, size_t rem, size_t shift)(void* ptr, sizediff_t ld)
{
    version(GLAS_PREFETCH)
    {
        foreach (n; Iota!N)
        {
            foreach (m; Iota!(M / 64 + bool(M % 64 >= rem)))
            {
                llvm_prefetch(ptr + m * 64 + shift + ld * n, 0, 3, 1);
            }
        }
    }
}

pragma(inline, true)
void scale_nano(size_t M, size_t P, size_t N, V, F)(ref const F[P] alpha, ref V[M][P][N] c)
{
    V[P] s = void;
    V[M][P][N] reg = void;
    load_nano(s, alpha);
    load_nano(reg, c);
    foreach (n; Iota!N)
    foreach (m; Iota!M)
    {
        static if (P == 1)
        {
            reg[n][0][m] *= s[0];
        }
        else
        {
            auto re = s[0] * reg[n][0][m];
            auto im = s[0] * reg[n][1][m];
            re -= s[1] * reg[n][1][m];
            im += s[1] * reg[n][0][m];
            reg[n][0][m] = re;
            reg[n][1][m] = im;
        }
    }
    load_nano(c, reg);
}

pragma(inline, true)
ref auto castByRef(C)(return ref C val)
{
    static if (isComplex!C)
        alias R = typeof(val.re)[2];
    else
        alias R = C[1];
    return *cast(R*) &val;
}
