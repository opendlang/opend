/++
Copyright: Copyright © 2016-, Ilya Yaroshenko.
License: $(HTTP boost.org/LICENSE_1_0.txt, Boost License 1.0).
Authors: Ilya Yaroshenko
+/
module glas.internal.l1_;

import mir.ndslice.slice: Slice, SliceKind;
import ldc.intrinsics: llvm_expect;
import glas.ndslice;
import glas.fortran;
import glas.internal.utility;

package(glas) enum L1(Type) =
q{
    pragma(LDC_no_moduleinfo);

    import glas.ndslice;
    import glas.fortran;
    import mir.ndslice.slice: Slice, SliceKind;
    import ldc.intrinsics: llvm_expect;
    import ldc.attributes: fastmath;
    import glas.internal.utility;
    import glas.precompiled.utility;
    import glas.internal.l1;

    private alias T = } ~ Type.stringof ~ q{;

    export extern(C) @system nothrow @nogc @fastmath pragma(inline, false):

    alias R = realType!T;

    static if (isComplex!T)
    {
        alias I = imaginaryType!T;
    }

    //////////// rotg
    void } ~ prefix!Type ~ q{rotg_(ref T a, ref T b, ref realType!T c, ref T s)
    {
        glas.internal.l1.rotg(a, b, c, s);
    }

    //////////// rotmg
    static if (!isComplex!T)
    void } ~ prefix!Type ~ q{rotmg_(ref T a, ref T b, ref T x, ref T y, ref T[5] params)
    {
        glas.internal.l1.rotmg(a, b, x, y, params);
    }

    //////////// copy
    void _glas_} ~ prefix!Type ~ q{copy(
        size_t n,
        ptrdiff_t incx,
        const(T)* x,
        ptrdiff_t incy,
        T* y,
        )
    {
        glas.internal.l1.copy(n, incx, x, incy, y);
    }

    void glas_} ~ prefix!Type ~ q{copy(
        Slice!(SliceKind.universal, [1], const(T)*) xsl,
        Slice!(SliceKind.universal, [1], T*) ysl,
        )
    {
        glas.ndslice.copy(xsl.length, xsl._stride, xsl._iterator, ysl._stride, ysl._iterator);
    }

    int } ~ prefix!Type ~ q{copy_(
        ref const FortranInt n,
        const(T)* x,
        ref const FortranInt incx,
        T* y,
        ref const FortranInt incy,
        )
    {
        if(incx < 0)
            x -= (n - 1) * incx;
        if(incy < 0)
            y -= (n - 1) * incy;

        glas.ndslice.copy(n, incx, x, incy, y);
        return 0;
    }

    //////////// swap
    void _glas_} ~ prefix!Type ~ q{swap(
        size_t n,
        ptrdiff_t incx,
        T* x,
        ptrdiff_t incy,
        T* y,
        )
    {
        glas.internal.l1.swap(n, incx, x, incy, y);
    }

    void glas_} ~ prefix!Type ~ q{swap(
        Slice!(SliceKind.universal, [1], T*) xsl,
        Slice!(SliceKind.universal, [1], T*) ysl,
        )
    {
        glas.ndslice.swap(xsl.length, xsl._stride, xsl._iterator, ysl._stride, ysl._iterator);
    }

    int } ~ prefix!Type ~ q{swap_(
        ref const FortranInt n,
        T* x,
        ref const FortranInt incx,
        T* y,
        ref const FortranInt incy,
        )
    {
        if(incx < 0)
            x -= (n - 1) * incx;
        if(incy < 0)
            y -= (n - 1) * incy;

        glas.ndslice.swap(n, incx, x, incy, y);
        return 0;
    }

    //////////// axpy
    void _glas_} ~ prefix!Type ~ q{axpy(
        T a,
        size_t n,
        ptrdiff_t incx,
        const(T)* x,
        ptrdiff_t incy,
        T* y,
        )
    {
        glas.internal.l1.axpy(a, n, incx, x, incy, y);
    }

    void glas_} ~ prefix!Type ~ q{axpy(
        T a,
        Slice!(SliceKind.universal, [1], const(T)*) xsl,
        Slice!(SliceKind.universal, [1], T*) ysl,
        )
    {
        glas.ndslice.axpy(a, xsl.length, xsl._stride, xsl._iterator, ysl._stride, ysl._iterator);
    }

    int } ~ prefix!Type ~ q{axpy_(
        ref const FortranInt n,
        ref const T a,
        const(T)* x,
        ref const FortranInt incx,
        T* y,
        ref const FortranInt incy,
        )
    {
        if(incx < 0)
            x -= (n - 1) * incx;
        if(incy < 0)
            y -= (n - 1) * incy;

        glas.ndslice.axpy(a, n, incx, x, incy, y);
        return 0;
    }

    //////////// rot
    void _glas_} ~ prefix2r!Type ~ q{rot(
        size_t n,
        ptrdiff_t incx,
        T* x,
        ptrdiff_t incy,
        T* y,
        realType!T c,
        realType!T s,
        )
    {
        glas.internal.l1.rot(n, incx, x, incy, y, c, s);
    }

    void glas_} ~ prefix2r!Type ~ q{rot(
        Slice!(SliceKind.universal, [1], T*) xsl,
        Slice!(SliceKind.universal, [1], T*) ysl,
        realType!T c,
        realType!T s,
        )
    {
        glas.ndslice.rot(xsl.length, xsl._stride, xsl._iterator, ysl._stride, ysl._iterator, c, s);
    }

    int } ~ prefix2r!Type ~ q{rot_(
        ref const FortranInt n,
        T* x,
        ref const FortranInt incx,
        T* y,
        ref const FortranInt incy,
        ref const realType!T c,
        ref const realType!T s,
        )
    {
        if(incx < 0)
            x -= (n - 1) * incx;
        if(incy < 0)
            y -= (n - 1) * incy;

        glas.ndslice.rot(n, incx, x, incy, y, c, s);
        return 0;
    }

    //////////// rotm
    static if (!isComplex!T)
    void _glas_} ~ prefix2r!Type ~ q{rotm(
        size_t n,
        ptrdiff_t incx,
        T* x,
        ptrdiff_t incy,
        T* y,
        ref const T[5] param,
        )
    {
        glas.internal.l1.rotm(n, incx, x, incy, y, param);
    }

    static if (!isComplex!T)
    void glas_} ~ prefix2r!Type ~ q{rotm(
        Slice!(SliceKind.universal, [1], T*) xsl,
        Slice!(SliceKind.universal, [1], T*) ysl,
        ref const T[5] param,
        )
    {
        glas.ndslice.rotm(xsl.length, xsl._stride, xsl._iterator, ysl._stride, ysl._iterator, param);
    }

    static if (!isComplex!T)
    int } ~ prefix2r!Type ~ q{rotm_(
        ref const FortranInt n,
        T* x,
        ref const FortranInt incx,
        T* y,
        ref const FortranInt incy,
        ref const T[5] param,
        )
    {
        if(incx < 0)
            x -= (n - 1) * incx;
        if(incy < 0)
            y -= (n - 1) * incy;

        glas.ndslice.rotm(n, incx, x, incy, y, param);
        return 0;
    }

    //////////// dot
    static if (is(T == float) || is(T == double))
    T _glas_} ~ prefix!Type ~ q{dot(
        size_t n,
        ptrdiff_t incx,
        const(T)* x,
        ptrdiff_t incy,
        const(T)* y,
        )
    {
        return glas.internal.l1.dot!T(n, incx, x, incy, y);
    }

    static if (is(T == float) || is(T == double))
    T glas_} ~ prefix!Type ~ q{dot(
        Slice!(SliceKind.universal, [1], const(T)*) xsl,
        Slice!(SliceKind.universal, [1], const(T)*) ysl,
        )
    {
        return glas.ndslice.dot(xsl.length, xsl._stride, xsl._iterator, ysl._stride, ysl._iterator);
    }

    static if (is(T == float) || is(T == double))
    T } ~ prefix!Type ~ q{dot_(
        ref const FortranInt n,
        const(T)* x,
        ref const FortranInt incx,
        const(T)* y,
        ref const FortranInt incy,
        )
    {
        if(incx < 0)
            x -= (n - 1) * incx;
        if(incy < 0)
            y -= (n - 1) * incy;

        return glas.ndslice.dot(n, incx, x, incy, y);
    }

    //////////// dotu
    static if (is(T == cfloat) || is(T == cdouble))
    T _glas_} ~ prefix!Type ~ q{dotu(
        size_t n,
        ptrdiff_t incx,
        const(T)* x,
        ptrdiff_t incy,
        const(T)* y,
        )
    {
        return glas.internal.l1.dotu!T(n, incx, x, incy, y);
    }

    static if (is(T == cfloat) || is(T == cdouble))
    T glas_} ~ prefix!Type ~ q{dotu(
        Slice!(SliceKind.universal, [1], const(T)*) xsl,
        Slice!(SliceKind.universal, [1], const(T)*) ysl,
        )
    {
        return glas.ndslice.dotu(xsl.length, xsl._stride, xsl._iterator, ysl._stride, ysl._iterator);
    }

    static if (is(T == cfloat) || is(T == cdouble))
    T } ~ prefix!Type ~ q{dotu_(
        ref const FortranInt n,
        const(T)* x,
        ref const FortranInt incx,
        const(T)* y,
        ref const FortranInt incy,
        )
    {
        if(incx < 0)
            x -= (n - 1) * incx;
        if(incy < 0)
            y -= (n - 1) * incy;

        return glas.ndslice.dotu(n, incx, x, incy, y);
    }


    //////////// dotc
    static if (is(T == cfloat) || is(T == cdouble))
    T _glas_} ~ prefix!Type ~ q{dotc(
        size_t n,
        ptrdiff_t incx,
        const(T)* x,
        ptrdiff_t incy,
        const(T)* y,
        )
    {
        return glas.internal.l1.dotc!T(n, incx, x, incy, y);
    }

    static if (is(T == cfloat) || is(T == cdouble))
    T glas_} ~ prefix!Type ~ q{dotc(
        Slice!(SliceKind.universal, [1], const(T)*) xsl,
        Slice!(SliceKind.universal, [1], const(T)*) ysl,
        )
    {
        return glas.ndslice.dotc(xsl.length, xsl._stride, xsl._iterator, ysl._stride, ysl._iterator);
    }

    static if (is(T == cfloat) || is(T == cdouble))
    T } ~ prefix!Type ~ q{dotc_(
        ref const FortranInt n,
        const(T)* x,
        ref const FortranInt incx,
        const(T)* y,
        ref const FortranInt incy,
        )
    {
        if(incx < 0)
            x -= (n - 1) * incx;
        if(incy < 0)
            y -= (n - 1) * incy;

        return glas.ndslice.dotc(n, incx, x, incy, y);
    }

    //////////// dsdot and sdsdot
    static if (is(T == float))
    double _glas_d} ~ prefix!Type ~ q{dot(
        size_t n,
        ptrdiff_t incx,
        const(float)* x,
        ptrdiff_t incy,
        const(float)* y,
        )
    {
        return glas.internal.l1.dot!double(n, incx, x, incy, y);
    }

    static if (is(T == float))
    double glas_dsdot(
        Slice!(SliceKind.universal, [1], const(float)*) xsl,
        Slice!(SliceKind.universal, [1], const(float)*) ysl,
        )
    {
        return glas.ndslice.dsdot(xsl.length, xsl._stride, xsl._iterator, ysl._stride, ysl._iterator);
    }

    static if (is(T == float))
    double dsdot_(
        ref const FortranInt n,
        const(float)* x,
        ref const FortranInt incx,
        const(float)* y,
        ref const FortranInt incy,
        )
    {
        if(incx < 0)
            x -= (n - 1) * incx;
        if(incy < 0)
            y -= (n - 1) * incy;

        return glas.ndslice.dsdot(n, incx, x, incy, y);
    }

    static if (is(T == float))
    float sdsdot_(
        ref const FortranInt n,
        ref const float sb,
        const(float)* x,
        ref const FortranInt incx,
        const(float)* y,
        ref const FortranInt incy,
        )
    {
        if(incx < 0)
            x -= (n - 1) * incx;
        if(incy < 0)
            y -= (n - 1) * incy;

        return sb + glas.ndslice.dsdot(n, incx, x, incy, y);
    }

    //////////// nrm2
    R _glas_} ~ prefix2!Type ~ q{nrm2(
        size_t n,
        ptrdiff_t incx,
        const(T)* x,
        )
    {
        return glas.internal.l1.nrm2(n, incx, x);
    }

    R glas_} ~ prefix2!Type ~ q{nrm2(
        Slice!(SliceKind.universal, [1], const(T)*) xsl,
        )
    {
        return glas.ndslice.nrm2(xsl.length, xsl._stride, xsl._iterator);
    }

    R } ~ prefix2!Type ~ q{nrm2_(
        ref const FortranInt n,
        const(T)* x,
        ref const FortranInt incx,
        )
    {
        if(incx < 0)
            x -= (n - 1) * incx;

        return glas.ndslice.nrm2(n, incx, x);
    }

    //////////// asum
    R _glas_} ~ prefix2!Type ~ q{asum(
        size_t n,
        ptrdiff_t incx,
        const(T)* x,
        )
    {
        return glas.internal.l1.asum(n, incx, x);
    }

    R glas_} ~ prefix2!Type ~ q{asum(
        Slice!(SliceKind.universal, [1], const(T)*) xsl,
        )
    {
        return glas.ndslice.asum(xsl.length, xsl._stride, xsl._iterator);
    }

    R } ~ prefix2!Type ~ q{asum_(
        ref const FortranInt n,
        const(T)* x,
        ref const FortranInt incx,
        )
    {
        if(incx < 0)
            x -= (n - 1) * incx;

        return glas.ndslice.asum(n, incx, x);
    }

    //////////// iamax
    ptrdiff_t _glas_i} ~ prefix!Type ~ q{amax(
        size_t n,
        ptrdiff_t incx,
        const(T)* x,
        )
    {
        return glas.internal.l1.iamax(n, incx, x);
    }

    ptrdiff_t glas_i} ~ prefix!Type ~ q{amax(
        Slice!(SliceKind.universal, [1], const(T)*) xsl,
        )
    {
        return glas.ndslice.iamax(xsl.length, xsl._stride, xsl._iterator);
    }

    FortranInt i} ~ prefix!Type ~ q{amax_(
        ref const FortranInt n,
        const(T)* x,
        ref const FortranInt incx,
        )
    {
        if(incx < 0)
            x -= (n - 1) * incx;

        return cast(FortranInt)(glas.ndslice.iamax(n, incx, x) + 1);
    }

    //////////// scal
    void _glas_} ~ prefix!Type ~ q{scal(
        T a,
        size_t length,
        ptrdiff_t stride,
        T* ptr,
        )
    {
        glas.internal.l1.scal(a, length, stride, ptr);
    }

    void glas_} ~ prefix!Type ~ q{scal(
        T a,
        Slice!(SliceKind.universal, [1], T*) xsl,
        )
    {
        glas.ndslice.scal(a, xsl.length, xsl._stride, xsl._iterator);
    }

    int } ~ prefix!Type ~ q{scal_(
        ref const FortranInt n,
        ref const T a,
            T* x,
        ref const FortranInt incx,
        )
    {
        if(incx < 0)
            x -= (n - 1) * incx;

        glas.ndslice.scal(a, n, incx, x);
        return 0;
    }

    static if (isComplex!T)
    void _glas_} ~ prefix!Type ~ prefix!(realType!Type) ~ q{scal(
        R a,
        size_t length,
        ptrdiff_t stride,
        T* ptr,
        )
    {
        glas.internal.l1.scal(a, length, stride, ptr);
    }

    static if (isComplex!T)
    void glas_} ~ prefix!Type ~ prefix!(realType!Type) ~ q{scal(
        R a,
        Slice!(SliceKind.universal, [1], T*) xsl,
        )
    {
        glas.ndslice.scal(a, xsl.length, xsl._stride, xsl._iterator);
    }

    static if (isComplex!T)
    int } ~ prefix!Type ~ prefix!(realType!Type) ~ q{scal_(
        ref const FortranInt n,
        ref const R a,
            T* x,
        ref const FortranInt incx,
        )
    {
        if(incx < 0)
            x -= (n - 1) * incx;

        glas.ndslice.scal(a, n, incx, x);
        return 0;
    }

    static if (isComplex!T)
    void _glas_} ~ prefix!Type ~ prefix!(realType!Type) ~ "I" ~ q{scal(
        I a,
        size_t length,
        ptrdiff_t stride,
        T* ptr,
        )
    {
        glas.internal.l1.scal(a, length, stride, ptr);
    }

    static if (isComplex!T)
    void glas_} ~ prefix!Type ~ prefix!(realType!Type) ~ "I" ~ q{scal(
        I a,
        Slice!(SliceKind.universal, [1], T*) xsl,
        )
    {
        glas.ndslice.scal(a, xsl.length, xsl._stride, xsl._iterator);
    }

    static if (isComplex!T)
    int } ~ prefix!Type ~ prefix!(realType!Type) ~ "I" ~ q{scal_(
        ref const FortranInt n,
        ref const I a,
            T* x,
        ref const FortranInt incx,
        )
    {
        if(incx < 0)
            x -= (n - 1) * incx;

        glas.ndslice.scal(a, n, incx, x);
        return 0;
    }
};
