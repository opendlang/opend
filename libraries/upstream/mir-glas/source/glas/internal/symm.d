
/++
Copyright: Copyright © 2016-, Ilya Yaroshenko.
License: $(HTTP boost.org/LICENSE_1_0.txt, Boost License 1.0).
Authors: Ilya Yaroshenko
+/
module glas.internal.symm;

import std.traits;
import std.meta;
import mir.ndslice.slice : Slice, SliceKind;

import ldc.attributes;
import ldc.intrinsics;

import glas.ndslice;
import glas.internal.blocking;
import glas.internal.copy;
import glas.internal.config;
import glas.internal.gemm;
import glas.internal.utility;

@fastmath:

pragma(inline, true)
@optStrategy("optsize")
nothrow @nogc
void symm_impl(C)
(
    C alpha,
    Slice!(SliceKind.universal, [2], const(C)*) asl,
    Slice!(SliceKind.universal, [2], const(C)*) bsl,
    C beta,
    Slice!(SliceKind.universal, [2], C*) _csl,
    ulong settings,
)
{
    assert(asl.length!0 == asl.length!1, "constraint: asl.length!0 == asl.length!1");
    assert(asl.length!1 == bsl.length!0, "constraint: asl.length!1 == bsl.length!0");
    assert(_csl.length!0 == asl.length!0, "constraint: _csl.length!0 == asl.length!0");
    assert(_csl.length!1 == bsl.length!1, "constraint: _csl.length!1 == bsl.length!1");
    assert(_csl._stride!0 == +1
        || _csl._stride!0 == -1
        || _csl._stride!1 == +1
        || _csl._stride!1 == -1, "constraint: _csl._stride!0 or _csl._stride!1 must be equal to +/-1");

    mixin prefix3;
    import mir.ndslice.dynamic: reversed, transposed;
    mixin RegisterConfig!(P, T);
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
    if (_csl._stride!0 != 1)
    {
        asl = asl.transposed;
        bsl = bsl.transposed;
        _csl = _csl.transposed;
        settings ^= Upper | Right;
    }
    static if (P == 2)
    {
        int hem = settings & ConjA;
    }
    if (!(settings & Upper) != !(settings & Right))
    {
        asl = asl.transposed;
        static if (P == 2)
        {
            hem = -hem;
        }
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
    Kernel!(P, T)[nr_chain.length] beta_kernels = void;
    Kernel!(P, T)[nr_chain.length] one_kernels  = void;
    Kernel!(P, T)* kernels                      = void;

    foreach (nri, nr; nr_chain)
        one_kernels [nri] = &gemv_reg!(BetaType.one, P, nr, T);

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
    if (!(settings & Right))
    {
        //#########################################################
        PackKernel!(C, T)[P][mr_chain.length] pack_a_kernels = void;
        PackKernel!(C, T)    [nr_chain.length] pack_b_kernels = void;
        PackKernelTri!(C, T) pack_a_tri_kernel = void;

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
        static if (P == 2)
        {
            if (hem == 0)
            {
                foreach (mri, mr; mr_chain)
                {
                    pack_a_kernels[mri][0] = &pack_a_nano!(mr, P, 0, C, T);
                    pack_a_kernels[mri][1] = &pack_a_nano!(mr, P, 0, C, T);
                }
                pack_a_tri_kernel = &pack_a_tri!(P, C, T, 0);
            }
            else
            if (hem < 0)
            {
                foreach (mri, mr; mr_chain)
                {
                    pack_a_kernels[mri][0] = &pack_a_nano!(mr, P, 1, C, T);
                    pack_a_kernels[mri][1] = &pack_a_nano!(mr, P, 0, C, T);
                }
                pack_a_tri_kernel = &pack_a_tri!(P, C, T, -1);
            }
            else
            {
                foreach (mri, mr; mr_chain)
                {
                    pack_a_kernels[mri][0] = &pack_a_nano!(mr, P, 0, C, T);
                    pack_a_kernels[mri][1] = &pack_a_nano!(mr, P, 1, C, T);
                }
                pack_a_tri_kernel = &pack_a_tri!(P, C, T, +1);
            }
        }
        else
        {
            foreach (mri, mr; mr_chain)
                pack_a_kernels[mri][0] = &pack_a_nano!(mr, P, 0, C, T);
            pack_a_tri_kernel = &pack_a_tri!(P, C, T, 0);
        }
        //#########################################################
        with(blocking!(P, T)(asl.length!0, bsl.length!1, asl.length!0))
        {
            size_t j;
            sizediff_t incb;
            if (mc  < asl.length!0)
                incb = kc;
            do
            {
                if (asl.length!0 - j < kc)
                    kc = asl.length!0 - j;
                ////////////////////////
                size_t i;
                auto bsl_ptr = bsl._iterator;
                auto cslm = csl;
                auto mc = mc;
                //======================
                do
                {
                    if (asl.length!0 - i < mc)
                        mc = asl.length!0 - i;
                    pack_a_sym!(P, C, T)(asl._iterator, asl._stride!0, asl._stride!1, i, j, mc, kc, a, pack_a_kernels.ptr, pack_a_tri_kernel, main_mr);
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
                    i += mc;
                }
                while (i < asl.length!0);
                ////////////////////////
                kernels = one_kernels.ptr;
                bsl.popFrontExactly!0(kc);
                j += kc;
            }
            while (j < asl.length!0);
        }
    }
    else
    {
        //#########################################################
        PackKernel!(C, T)    [mr_chain.length] pack_a_kernels = void;
        PackKernel!(C, T)[P][nr_chain.length] pack_b_kernels = void;
        PackKernelTri!(C, T) pack_b_tri_kernel = void;
        static if (P == 2)
        {
            if (settings & ConjB)
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
            if (hem == 0)
            {
                foreach (nri, nr; nr_chain)
                {
                    pack_b_kernels[nri][0] = &pack_b_nano!(nr, P, 0, C, T);
                    pack_b_kernels[nri][1] = &pack_b_nano!(nr, P, 0, C, T);
                }
                pack_b_tri_kernel = &pack_b_tri!(P, C, T, 0);
            }
            else
            if (hem < 0)
            {
                foreach (nri, nr; nr_chain)
                {
                    pack_b_kernels[nri][0] = &pack_b_nano!(nr, P, 1, C, T);
                    pack_b_kernels[nri][1] = &pack_b_nano!(nr, P, 0, C, T);
                }
                pack_b_tri_kernel = &pack_b_tri!(P, C, T, -1);
            }
            else
            {
                foreach (nri, nr; nr_chain)
                {
                    pack_b_kernels[nri][0] = &pack_b_nano!(nr, P, 0, C, T);
                    pack_b_kernels[nri][1] = &pack_b_nano!(nr, P, 1, C, T);
                }
                pack_b_tri_kernel = &pack_b_tri!(P, C, T, +1);
            }
        }
        else
        {
            foreach (nri, nr; nr_chain)
                pack_b_kernels[nri][0] = &pack_b_nano!(nr, P, 0, C, T);
            pack_b_tri_kernel = &pack_b_tri!(P, C, T, 0);
        }
        //#########################################################
        with(blocking!(P, T)(bsl.length!0, asl.length!0, bsl.length!1))
        {
            sizediff_t incb;
            if (mc < bsl.length!0)
                incb = kc;
            size_t j;
            do
            {
                if (bsl.length!1 < kc)
                    kc = bsl.length!1;
                ////////////////////////
                auto bslp = bsl[0 .. $, 0 .. kc];
                auto asl_ptr = asl._iterator;
                auto cslm = csl;
                auto mc = mc;
                //======================
                do
                {
                    if (bslp.length!0 < mc)
                        mc = bslp.length!0;
                    ////////////////////////
                    pack_a!(P, C, T)(bslp[0 .. mc], a, pack_a_kernels.ptr);
                    //======================
                    sybp!(P, T, C)(
                        mc,
                        asl.length!0,
                        kc,
                        a,
                        b,
                        incb,
                        asl_ptr,
                        asl._stride!0,
                        asl._stride!1,
                        j,
                        cast(T*) cslm._iterator,
                        cslm._stride!0,
                        *cast(T[P][2]*)&alpha_beta,
                        pack_b_tri_kernel,
                        pack_b_kernels.ptr,
                        kernels,
                        main_nr,
                        );
                    ////////////////////////
                    asl_ptr = null;
                    cslm.popFrontExactly!1(mc);
                    bslp.popFrontExactly!0(mc);
                }
                while (bslp.length!0);
                ////////////////////////
                j += kc;
                kernels = one_kernels.ptr;
                bsl.popFrontExactly!1(kc);
            }
            while (bsl.length!1);
        }
    }
}

pragma(inline, true)
void sybp(size_t P, T, C)(
    size_t mc,
    size_t nc,
    size_t kc,
    scope const(T)* a,
    scope T* b,
    sizediff_t incb,
    const(C)* ptrb,
    sizediff_t str0b,
    sizediff_t str1b,
    size_t js,
    scope T* c,
    sizediff_t ldc,
    ref const T[P][2] alpha_beta,
    PackKernelTri!(C, T) pack_b_tri_kernel,
    PackKernel!(C, T)[P]* pack_b_kernels,
    Kernel!(P, T)* kernels,
    size_t nr,
    )
{
    mixin RegisterConfig!(P, T);
    size_t i;
    do
    {
        if (nc >= nr) do
        {
            if (ptrb)
            {
                size_t j = js;
                size_t length = kc;
                auto to = b;
                {
                    sizediff_t len = i - j;
                    static if (P == 1)
                        len++;
                    if (len > 0)
                    {
                        if (len > length)
                            len = length;
                        to = pack_b_kernels[0][0](len, str0b, str1b, ptrb + j * str0b + i * str1b, to);
                        j += len;
                        length -= len;
                    }
                }
                {
                    sizediff_t start = j - i;
                    sizediff_t len = nr - start;
                    static if (P == 1)
                        len--;
                    if (len > length)
                        len = length;
                    if (len > 0)
                    {
                        to = pack_b_tri_kernel(ptrb + i * str0b + j * str1b, str0b, str1b, to, start, len, nr);
                        length -= len;
                        j += len;
                    }
                }
                if(length)
                {
                    pack_b_kernels[0][$-1](length, str1b, str0b, ptrb + i * str0b + j * str1b, to);
                }
                i += nr;
            }
            kernels[0](mc, kc, a, b, c, ldc, alpha_beta);
            b +=  nr * P * incb;
            nc -= nr;
            c += nr * P * ldc;
        }
        while (nc >= nr);
        pack_b_kernels++;
        kernels++;
        import ldc.intrinsics: llvm_ctlz;
        auto newNr = size_t(1) << (size_t.sizeof * 8 - 1 - llvm_ctlz(nr, true));
        nr = nr == newNr ? newNr / 2 : newNr;
    }
    while(nr);
}
