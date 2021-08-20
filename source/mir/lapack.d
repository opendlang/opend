/++
Low level ndslice wrapper for LAPACK.

$(RED Attention: LAPACK and this module has column major API.)
ndslice rows correspond to LAPACK columns.

Functions with `*_wq` suffix are wrappers for workspace queries.

Authors: Ilya Yaroshenko
Copyright:  Copyright © 2017, Symmetry Investments & Kaleidic Associates
+/
module mir.lapack;

import mir.ndslice.slice;
import mir.ndslice.topology: retro;
import mir.ndslice.iterator;
import mir.utility: min, max;
import mir.internal.utility : realType, isComplex;

static import lapack;

public import lapack: lapackint;

import lapack.lapack: _cfloat, _cdouble;

@trusted pure nothrow @nogc:

///
lapackint ilaenv()(lapackint ispec, scope const(char)* name, scope const(char)* opts, lapackint n1, lapackint n2, lapackint n3, lapackint n4)
{
    return ilaenv_(ispec, name, opts, n1, n2, n3, n4);
}

///
lapackint ilaenv2stage()(lapackint ispec, scope const(char)* name, scope const(char)* opts, lapackint n1, lapackint n2, lapackint n3, lapackint n4)
{
    return ilaenv2stage_(ispec, name, opts, n1, n2, n3, n4);
}

/// `getri` work space query.
size_t getri_wq(T)(Slice!(T*, 2, Canonical) a)
in
{
    assert(a.length!0 == a.length!1, "getri: The input 'a' must be a square matrix.");
}
do
{
    lapackint n = cast(lapackint) a.length;
    lapackint lda = cast(lapackint) a._stride.max(1);
    T work;
    lapackint lwork = -1;
    lapackint info;

    lapack.getri_(n, null, lda, null, &work, lwork, info);

    assert(info == 0);
    return cast(size_t) work.re;
}

unittest
{
    alias s = getri_wq!float;
    alias d = getri_wq!double;
    alias c = getri_wq!_cfloat;
    alias z = getri_wq!_cdouble;
}

///
size_t getri(T)(
    Slice!(T*, 2, Canonical) a,
    Slice!(lapackint*) ipiv,
    Slice!(T*) work,
    )
in
{
    assert(a.length!0 == a.length!1, "getri: The input 'a' must be a square matrix.");
    assert(ipiv.length == a.length!0, "getri: The length of 'ipiv' must be equal to the number of rows of 'a'.");
    assert(work.length, "getri: work must have a non-zero length.");
}
do
{
    lapackint n = cast(lapackint) a.length;
    lapackint lda = cast(lapackint) a._stride.max(1);
    lapackint lwork = cast(lapackint) work.length;
    lapackint info;

    lapack.getri_(n, a.iterator, lda, ipiv.iterator, work.iterator, lwork, info);

    assert(info >= 0);
    return info;
}

unittest
{
    alias s = getri!float;
    alias d = getri!double;
    alias c = getri!_cfloat;
    alias z = getri!_cdouble;
}

///
size_t getrf(T)(
    Slice!(T*, 2, Canonical) a,
    Slice!(lapackint*) ipiv,
    )
in
{
    assert(ipiv.length >= min(a.length!0, a.length!1), "getrf: The length of 'ipiv' must be at least the smaller of 'a''s dimensions");
}
do
{
    lapackint m = cast(lapackint) a.length!1;
    lapackint n = cast(lapackint) a.length!0;
    lapackint lda = cast(lapackint) a._stride.max(1);
    lapackint info;

    lapack.getrf_(m, n, a.iterator, lda, ipiv.iterator, info);

    assert(info >= 0);
    return info;
}

unittest
{
    alias s = getrf!float;
    alias d = getrf!double;
    alias c = getrf!_cfloat;
    alias z = getrf!_cdouble;
}

///
template sptrf(T)
{
    /// `sptrf` for upper triangular input.
    size_t sptrf(
        Slice!(StairsIterator!(T*, "+")) ap,
        Slice!(lapackint*) ipiv,
        )
    in
    {
        assert(ipiv.length == ap.length, "sptrf: The length of 'ipiv' must be equal to the length 'ap'.");
    }
    do
    {
        char uplo = 'U';
        lapackint n = cast(lapackint) ap.length;
        lapackint info;

        lapack.sptrf_(uplo, n, &ap[0][0], ipiv.iterator, info);

        assert(info >= 0);
        return info;
    }

    /// `sptrf` for lower triangular input.
    size_t sptrf(
        Slice!(StairsIterator!(T*, "-")) ap,
        Slice!(lapackint*) ipiv,
        )
    in
    {
        assert(ipiv.length == ap.length, "sptrf: The length of 'ipiv' must be equal to the length 'ap'.");
    }
    do
    {
        char uplo = 'L';
        lapackint n = cast(lapackint) ap.length;
        lapackint info;

        lapack.sptrf_(uplo, n, &ap[0][0], ipiv.iterator, info);

        assert(info >= 0);
        return info;
    }
}

unittest
{
    alias s = sptrf!float;
    alias d = sptrf!double;
}

///
size_t gesv(T)(
    Slice!(T*, 2, Canonical) a,
    Slice!(lapackint*) ipiv,
    Slice!(T*, 2, Canonical) b,
    )
in
{
    assert(a.length!0 == a.length!1, "gesv: The input 'a' must be a square matrix.");
    assert(ipiv.length == a.length!0, "gesv: The length of 'ipiv' must be equal to the number of rows of 'a'.");
    assert(b.length!1 == a.length!0, "gesv: The number of columns of 'b' must equal the number of rows of 'a'");
}
do
{
    lapackint n = cast(lapackint) a.length;
    lapackint nrhs = cast(lapackint) b.length;
    lapackint lda = cast(lapackint) a._stride.max(1);
    lapackint ldb = cast(lapackint) b._stride.max(1);
    lapackint info;

    lapack.gesv_(n, nrhs, a.iterator, lda, ipiv.iterator, b.iterator, ldb, info);

    assert(info >= 0);
    return info;
}

unittest
{
    alias s = gesv!float;
    alias d = gesv!double;
}

/// `gelsd` work space query.
size_t gelsd_wq(T)(
    Slice!(T*, 2, Canonical) a,
    Slice!(T*, 2, Canonical) b,
    ref size_t liwork,
    )
    if(!isComplex!T)
in
{
    assert(b.length!1 == a.length!1, "gelsd_wq: The number of columns of 'b' must equal the number of columns of 'a'");
}
do
{
    lapackint m = cast(lapackint) a.length!1;
    lapackint n = cast(lapackint) a.length!0;
    lapackint nrhs = cast(lapackint) b.length;
    lapackint lda = cast(lapackint) a._stride.max(1);
    lapackint ldb = cast(lapackint) b._stride.max(1);
    T rcond;
    lapackint rank;
    T work;
    lapackint lwork = -1;
    lapackint iwork;
    lapackint info;

    lapack.gelsd_(m, n, nrhs, a.iterator, lda, b.iterator, ldb, null, rcond, rank, &work, lwork, &iwork, info);

    assert(info == 0);
    liwork = iwork;
    return cast(size_t) work.re;
}


/// ditto
size_t gelsd_wq(T)(
    Slice!(T*, 2, Canonical) a,
    Slice!(T*, 2, Canonical) b,
    ref size_t lrwork,
    ref size_t liwork,
    )
    if(isComplex!T)
in
{
    assert(b.length!1 == a.length!1, "gelsd_wq: The number of columns of 'b' must equal the number of columns of 'a'");
}
do
{
    lapackint m = cast(lapackint) a.length!1;
    lapackint n = cast(lapackint) a.length!0;
    lapackint nrhs = cast(lapackint) b.length;
    lapackint lda = cast(lapackint) a._stride.max(1);
    lapackint ldb = cast(lapackint) b._stride.max(1);
    realType!T rcond;
    lapackint rank;
    T work;
    lapackint lwork = -1;
    realType!T rwork;
    lapackint iwork;
    lapackint info;

    lapack.gelsd_(m, n, nrhs, a.iterator, lda, b.iterator, ldb, null, rcond, rank, &work, lwork, &rwork, &iwork, info);
    
    assert(info == 0);
    lrwork = cast(size_t)rwork;
    liwork = iwork;
    return cast(size_t) work.re;
}

unittest
{
    alias s = gelsd_wq!float;
    alias d = gelsd_wq!double;
    alias c = gelsd_wq!_cfloat;
    alias z = gelsd_wq!_cdouble;
}

///
size_t gelsd(T)(
    Slice!(T*, 2, Canonical) a,
    Slice!(T*, 2, Canonical) b,
    Slice!(T*) s,
    T rcond,
    ref size_t rank,
    Slice!(T*) work,
    Slice!(lapackint*) iwork,
    )
    if(!isComplex!T)
in
{
    assert(b.length!1 == a.length!1, "gelsd: The number of columns of 'b' must equal the number of columns of 'a'");
    assert(s.length == min(a.length!0, a.length!1), "gelsd: The length of 's' must equal the smaller of the dimensions of 'a'");
}
do
{
    lapackint m = cast(lapackint) a.length!1;
    lapackint n = cast(lapackint) a.length!0;
    lapackint nrhs = cast(lapackint) b.length;
    lapackint lda = cast(lapackint) a._stride.max(1);
    lapackint ldb = cast(lapackint) b._stride.max(1);
    lapackint rank_;
    lapackint lwork = cast(lapackint) work.length;
    lapackint info;

    lapack.gelsd_(m, n, nrhs, a.iterator, lda, b.iterator, ldb, s.iterator, rcond, rank_, work.iterator, lwork, iwork.iterator, info);

    assert(info >= 0);
    rank = rank_;
    return info;
}

/// ditto
size_t gelsd(T)(
    Slice!(T*, 2, Canonical) a,
    Slice!(T*, 2, Canonical) b,
    Slice!(realType!T*) s,
    realType!T rcond,
    ref size_t rank,
    Slice!(T*) work,
    Slice!(realType!T*) rwork,
    Slice!(lapackint*) iwork,
    )
    if(isComplex!T)
in
{
    assert(b.length!1 == a.length!1, "gelsd: The number of columns of 'b' must equal the number of columns of 'a'");
    assert(s.length == min(a.length!0, a.length!1), "gelsd: The length of 's' must equal the smaller of the dimensions of 'a'");
}
do
{
    lapackint m = cast(lapackint) a.length!1;
    lapackint n = cast(lapackint) a.length!0;
    lapackint nrhs = cast(lapackint) b.length;
    lapackint lda = cast(lapackint) a._stride.max(1);
    lapackint ldb = cast(lapackint) b._stride.max(1);
    lapackint rank_;
    lapackint lwork = cast(lapackint) work.length;
    lapackint info;

    lapack.gelsd_(m, n, nrhs, a.iterator, lda, b.iterator, ldb, s.iterator, rcond, rank_, work.iterator, lwork, rwork.iterator, iwork.iterator, info);

    assert(info >= 0);
    rank = rank_;
    return info;
}

unittest
{
    alias s = gelsd!float;
    alias d = gelsd!double;
    alias c = gelsd!_cfloat;
    alias z = gelsd!_cdouble;
}

/// `gesdd` work space query
size_t gesdd_wq(T)(
    char jobz,
    Slice!(T*, 2, Canonical) a,
    Slice!(T*, 2, Canonical) u,
    Slice!(T*, 2, Canonical) vt,
    )
{
    lapackint m = cast(lapackint) a.length!1;
    lapackint n = cast(lapackint) a.length!0;
    lapackint lda = cast(lapackint) a._stride.max(1);
    lapackint ldu = cast(lapackint) u._stride.max(1);
    lapackint ldvt = cast(lapackint) vt._stride.max(1);
    T work;
    lapackint lwork = -1;
    lapackint info;

    static if(!isComplex!T)
    {
        lapack.gesdd_(jobz, m, n, null, lda, null, null, ldu, null, ldvt, &work, lwork, null, info);
    }
    else
    {
        lapack.gesdd_(jobz, m, n, null, lda, null, null, ldu, null, ldvt, &work, lwork, null, null, info);
    }

    assert(info == 0);
    return cast(size_t) work.re;
}

unittest
{
    alias s = gesdd_wq!float;
    alias d = gesdd_wq!double;
    alias c = gesdd_wq!_cfloat;
    alias z = gesdd_wq!_cdouble;
}

///
size_t gesdd(T)(
    char jobz,
    Slice!(T*, 2, Canonical) a,
    Slice!(T*) s,
    Slice!(T*, 2, Canonical) u,
    Slice!(T*, 2, Canonical) vt,
    Slice!(T*) work,
    Slice!(lapackint*) iwork,
    )
    if(!isComplex!T)
{
    lapackint m = cast(lapackint) a.length!1;
    lapackint n = cast(lapackint) a.length!0;
    lapackint lda = cast(lapackint) a._stride.max(1);
    lapackint ldu = cast(lapackint) u._stride.max(1);
    lapackint ldvt = cast(lapackint) vt._stride.max(1);
    lapackint lwork = cast(lapackint) work.length;
    lapackint info;

    lapack.gesdd_(jobz, m, n, a.iterator, lda, s.iterator, u.iterator, ldu, vt.iterator, ldvt, work.iterator, lwork, iwork.iterator, info);

    assert(info >= 0);
    return info;
}

/// ditto
size_t gesdd(T)(
    char jobz,
    Slice!(T*, 2, Canonical) a,
    Slice!(realType!T*) s,
    Slice!(T*, 2, Canonical) u,
    Slice!(T*, 2, Canonical) vt,
    Slice!(T*) work,
    Slice!(realType!T*) rwork,
    Slice!(lapackint*) iwork,
    )
    if(isComplex!T)
{
    lapackint m = cast(lapackint) a.length!1;
    lapackint n = cast(lapackint) a.length!0;
    lapackint lda = cast(lapackint) a._stride.max(1);
    lapackint ldu = cast(lapackint) u._stride.max(1);
    lapackint ldvt = cast(lapackint) vt._stride.max(1);
    lapackint lwork = cast(lapackint) work.length;
    lapackint info;

    lapack.gesdd_(jobz, m, n, a.iterator, lda, s.iterator, u.iterator, ldu, vt.iterator, ldvt, work.iterator, lwork, rwork.iterator, iwork.iterator, info);

    assert(info >= 0);
    return info;
}

unittest
{
    alias s = gesdd!float;
    alias d = gesdd!double;
    alias c = gesdd!_cfloat;
    alias z = gesdd!_cdouble;
}

/// `gesvd` work space query
size_t gesvd_wq(T)(
    char jobu,
    char jobvt,
    Slice!(T*, 2, Canonical) a,
    Slice!(T*, 2, Canonical) u,
    Slice!(T*, 2, Canonical) vt,
    )
{
    lapackint m = cast(lapackint) a.length!1;
    lapackint n = cast(lapackint) a.length!0;
    lapackint lda = cast(lapackint) a._stride.max(1);
    lapackint ldu = cast(lapackint) u._stride.max(1);
    lapackint ldvt = cast(lapackint) vt._stride.max(1);
    T work;
    lapackint lwork = -1;
    lapackint info;

    static if(!isComplex!T)
    {
        lapack.gesvd_(jobu, jobvt, m, n, null, lda, null, null, ldu, null, ldvt, &work, lwork, info);
    }
    else
    {
        lapack.gesvd_(jobu, jobvt, m, n, null, lda, null, null, ldu, null, ldvt, &work, lwork, null, info);
    }

    assert(info == 0);
    return cast(size_t) work.re;
}

unittest
{
    alias s = gesvd_wq!float;
    alias d = gesvd_wq!double;
    alias c = gesvd_wq!_cfloat;
    alias z = gesvd_wq!_cdouble;
}

///
size_t gesvd(T)(
    char jobu,
    char jobvt,
    Slice!(T*, 2, Canonical) a,
    Slice!(T*) s,
    Slice!(T*, 2, Canonical) u,
    Slice!(T*, 2, Canonical) vt,
    Slice!(T*) work,
    )
    if(!isComplex!T)
{
    lapackint m = cast(lapackint) a.length!1;
    lapackint n = cast(lapackint) a.length!0;
    lapackint lda = cast(lapackint) a._stride.max(1);
    lapackint ldu = cast(lapackint) u._stride.max(1);
    lapackint ldvt = cast(lapackint) vt._stride.max(1);
    lapackint lwork = cast(lapackint) work.length;
    lapackint info;

    lapack.gesvd_(jobu, jobvt, m, n, a.iterator, lda, s.iterator, u.iterator, ldu, vt.iterator, ldvt, work.iterator, lwork, info);

    assert(info >= 0);
    return info;
}

/// ditto
size_t gesvd(T)(
    char jobu,
    char jobvt,
    Slice!(T*, 2, Canonical) a,
    Slice!(realType!T*) s,
    Slice!(T*, 2, Canonical) u,
    Slice!(T*, 2, Canonical) vt,
    Slice!(T*) work,
    Slice!(realType!T*) rwork,
    )
    if(isComplex!T)
{
    lapackint m = cast(lapackint) a.length!1;
    lapackint n = cast(lapackint) a.length!0;
    lapackint lda = cast(lapackint) a._stride.max(1);
    lapackint ldu = cast(lapackint) u._stride.max(1);
    lapackint ldvt = cast(lapackint) vt._stride.max(1);
    lapackint lwork = cast(lapackint) work.length;
    lapackint info;

    lapack.gesvd_(jobu, jobvt, m, n, a.iterator, lda, s.iterator, u.iterator, ldu, vt.iterator, ldvt, work.iterator, lwork, rwork.iterator, info);

    assert(info >= 0);
    return info;
}

unittest
{
    alias s = gesvd!float;
    alias d = gesvd!double;
    alias c = gesvd!_cfloat;
    alias z = gesvd!_cdouble;
}

///
template spev(T)
{
    ///
    size_t spev(
        char jobz,
        Slice!(StairsIterator!(T*, "+")) ap,
        Slice!(T*) w,
        Slice!(T*, 2, Canonical) z,
        Slice!(T*) work,
        )
    in
    {
        assert(work.length == 3 * ap.length, "spev: The length of 'work' must equal three times the length of 'ap'.");
        assert(w.length == ap.length, "spev: The length of 'w' must equal the length of 'ap'.");
    }
    do
    {
        char uplo = 'U';
        lapackint n = cast(lapackint) ap.length;
        lapackint ldz = cast(lapackint) z._stride.max(1);
        lapackint info;

        lapack.spev_(jobz, uplo, n, &ap[0][0], w.iterator, z.iterator, ldz, work.iterator, info);

        assert(info >= 0);
        return info;
    }

    ///
    size_t spev(
        char jobz,
        Slice!(StairsIterator!(T*, "-")) ap,
        Slice!(T*) w,
        Slice!(T*, 2, Canonical) z,
        Slice!(T*) work,
        )
    in
    {
        assert(work.length == 3 * ap.length, "spev: The length of 'work' must equal three times the length of 'ap'.");
        assert(w.length == ap.length, "spev: The length of 'w' must equal the length of 'ap'.");
    }
    do
    {
        char uplo = 'L';
        lapackint n = cast(lapackint) ap.length;
        lapackint ldz = cast(lapackint) z._stride.max(1);
        lapackint info;

        lapack.spev_(jobz, uplo, n, &ap[0][0], w.iterator, z.iterator, ldz, work.iterator, info);

        assert(info >= 0);
        return info;
    }
}

unittest
{
    alias s = spev!float;
    alias d = spev!double;
}

///
size_t sytrf(T)(
    char uplo,
    Slice!(T*, 2, Canonical) a,
    Slice!(lapackint*) ipiv,
    Slice!(T*) work,
    )
in
{
    assert(a.length!0 == a.length!1, "sytrf: The input 'a' must be a square matrix.");
}
do
{
    lapackint info;
    lapackint n = cast(lapackint) a.length;
    lapackint lda = cast(lapackint) a._stride.max(1);
    lapackint lwork = cast(lapackint) work.length;

    lapack.sytrf_(uplo, n, a.iterator, lda, ipiv.iterator, work.iterator, lwork, info);
    ///if info = 0: successful exit.
    ///if info > 0: if info = i, D(i, i) is exactly zero. The factorization has been
    ///completed, but the block diagonal matrix D is exactly singular, and division by
    ///zero will occur if it is used to solve a system of equations.
    ///if info < 0: if info == -i, the i-th argument had an illegal value.
    assert(info >= 0);
    return info;
}

unittest
{
    alias s = sytrf!float;
    alias d = sytrf!double;
    alias c = sytrf!_cfloat;
    alias z = sytrf!_cdouble;
}

///
size_t geqrf(T)(
    Slice!(T*, 2, Canonical) a,
    Slice!(T*) tau,
    Slice!(T*) work
    )
in
{
    assert(a.length!0 >= 0, "geqrf: The number of columns of 'a' must be " ~ 
        "greater than or equal to zero."); //n>=0
    assert(a.length!1 >= a.length!0, "geqrf: The number of columns of 'a' " ~ 
        "must be greater than or equal to the number of its rows."); //m>=n
    assert(tau.length >= 0, "geqrf: The input 'tau' must have length greater " ~ 
        "than or equal to zero."); //k>=0
    assert(a.length!0 >= tau.length, "geqrf: The number of columns of 'a' " ~ 
        "must be greater than or equal to the length of 'tau'."); //n>=k
    assert(work.length >= a.length!0, "geqrf: The length of 'work' must be " ~ 
        "greater than or equal to the number of rows of 'a'."); //lwork>=n
}
do
{
    lapackint m = cast(lapackint) a.length!1;
    lapackint n = cast(lapackint) a.length!0;
    lapackint lda = cast(lapackint) a._stride.max(1);
    lapackint lwork = cast(lapackint) work.length;
    lapackint info;

    lapack.geqrf_(m, n, a.iterator, lda, tau.iterator, work.iterator, lwork, info);

    ///if info == 0: successful exit;
    ///if info < 0: if info == -i, the i-th argument had an illegal value.
    assert(info >= 0);
    return info;
}

unittest
{
    alias s = geqrf!float;
    alias d = geqrf!double;
    alias c = geqrf!_cfloat;
    alias z = geqrf!_cdouble;
}

///
size_t getrs(T)(
    char trans,
    Slice!(T*, 2, Canonical) a,
    Slice!(T*, 2, Canonical) b,
    Slice!(lapackint*) ipiv,
    )
in
{
    assert(a.length!0 == a.length!1, "getrs: The input 'a' must be a square matrix.");
    assert(ipiv.length == a.length!0, "getrs: The length of 'ipiv' must be equal to the number of rows of 'a'.");
}
do
{
    lapackint n = cast(lapackint) a.length;
    lapackint nrhs = cast(lapackint) b.length;
    lapackint lda = cast(lapackint) a._stride.max(1);
    lapackint ldb = cast(lapackint) b._stride.max(1);
    lapackint info;

    lapack.getrs_(trans, n, nrhs, a.iterator, lda, ipiv.iterator, b.iterator, ldb, info);

    ///if info == 0: successful exit.
    ///if info < 0: if info == -i, the i-th argument had an illegal value.
    assert(info >= 0);
    return info;
}

unittest
{
    alias s = getrs!float;
    alias d = getrs!double;
    alias c = getrs!_cfloat;
    alias z = getrs!_cdouble;
}

///
size_t potrs(T)(
    char uplo,
    Slice!(T*, 2, Canonical) a,
    Slice!(T*, 2, Canonical) b,
    )
in
{
    assert(a.length!0 == a.length!1, "potrs: The input 'a' must be a square matrix.");
}
do
{
    lapackint n = cast(lapackint) a.length;
    lapackint nrhs = cast(lapackint) b.length;
    lapackint lda = cast(lapackint) a._stride.max(1);
    lapackint ldb = cast(lapackint) b._stride.max(1);
    lapackint info;

    lapack.potrs_(uplo, n, nrhs, a.iterator, lda, b.iterator, ldb, info);

    ///if info == 0: successful exit.
    ///if info < 0: if info == -i, the i-th argument had an illegal value.
    assert(info >= 0);
    return info;
}

unittest
{
    alias s = potrs!float;
    alias d = potrs!double;
    alias c = potrs!_cfloat;
    alias z = potrs!_cdouble;
}

///
size_t sytrs2(T)(
    Slice!(T*, 2, Canonical) a,
    Slice!(T*, 2, Canonical) b,
    Slice!(lapackint*) ipiv,
    Slice!(T*) work,
    char uplo,
    )
in
{
    assert(a.length!0 == a.length!1, "sytrs2: The input 'a' must be a square matrix.");
}
do
{
    lapackint n = cast(lapackint) a.length;
    lapackint nrhs = cast(lapackint) b.length;
    lapackint lda = cast(lapackint) a._stride.max(1);
    lapackint ldb = cast(lapackint) b._stride.max(1);
    lapackint info;

    lapack.sytrs2_(uplo, n, nrhs, a.iterator, lda, ipiv.iterator, b.iterator, ldb, work.iterator, info);

    ///if info == 0: successful exit.
    ///if info < 0: if info == -i, the i-th argument had an illegal value.
    assert(info >= 0);
    return info;
}

unittest
{
    alias s = sytrs2!float;
    alias d = sytrs2!double;
    alias c = sytrs2!_cfloat;
    alias z = sytrs2!_cdouble;
}

///
size_t geqrs(T)(
    Slice!(T*, 2, Canonical) a,
    Slice!(T*, 2, Canonical) b,
    Slice!(T*) tau,
    Slice!(T*) work
    )
in
{
    assert(a.length!0 >= 0, "geqrs: The number of columns of 'a' must be " ~ 
        "greater than or equal to zero."); //n>=0
    assert(a.length!1 >= a.length!0, "geqrs: The number of columns of 'a' " ~ 
        "must be greater than or equal to the number of its rows."); //m>=n
    assert(tau.length >= 0, "geqrs: The input 'tau' must have length greater " ~ 
        "than or equal to zero."); //k>=0
    assert(a.length!0 >= tau.length, "geqrs: The number of columns of 'a' " ~ 
        "must be greater than or equal to the length of 'tau'."); //n>=k
    assert(work.length >= a.length!0, "geqrs: The length of 'work' must be " ~ 
        "greater than or equal to the number of rows of 'a'."); //lwork>=n
}
do
{
    lapackint m = cast(lapackint) a.length!1;
    lapackint n = cast(lapackint) a.length!0;
    lapackint nrhs = cast(lapackint) b.length;
    lapackint lda = cast(lapackint) a._stride.max(1);
    lapackint ldb = cast(lapackint) b._stride.max(1);
    lapackint lwork = cast(lapackint) work.length;
    lapackint info;

    lapack.geqrs_(m, n, nrhs, a.iterator, lda, tau.iterator, b.iterator, ldb, work.iterator, lwork, info);

    ///if info == 0: successful exit.
    ///if info < 0: if info == -i, the i-th argument had an illegal value.
    assert(info >= 0);
    return info;
}

version(none)
unittest
{
    alias s = geqrs!float;
    alias d = geqrs!double;
    alias c = geqrs!_cfloat;
    alias z = geqrs!_cdouble;
}

///
size_t sysv_rook_wk(T)(
    char uplo,
    Slice!(T*, 2, Canonical) a,
    Slice!(T*, 2, Canonical) b,
    ) 
in
{
    assert(a.length!0 == a.length!1, "sysv_rook_wk: The input 'a' must be a square matrix.");
    assert(b.length!1 == a.length!0, "sysv_rook_wk: The number of columns of 'b' must equal the number of rows of 'a'.");
}
do
{
    lapackint n = cast(lapackint) a.length;
    lapackint nrhs = cast(lapackint) b.length;
    lapackint lda = cast(lapackint) a._stride.max(1);
    lapackint ldb = cast(lapackint) b._stride.max(1);
    T work;
    lapackint lwork = -1;
    lapackint info;

    lapack.sysv_rook_(uplo, n, nrhs, a._iterator, lda, null, b._iterator, ldb, &work, lwork, info);

    return cast(size_t) work.re;
}

unittest
{
    alias s = sysv_rook_wk!float;
    alias d = sysv_rook_wk!double;
    alias c = sysv_rook_wk!_cfloat;
    alias z = sysv_rook_wk!_cdouble;
}

///
size_t sysv_rook(T)(
    char uplo,
    Slice!(T*, 2, Canonical) a,
    Slice!(lapackint*) ipiv,
    Slice!(T*, 2, Canonical) b,
    Slice!(T*) work,
    )
in
{
    assert(a.length!0 == a.length!1, "sysv_rook: The input 'a' must be a square matrix.");
    assert(ipiv.length == a.length!0, "sysv_rook: The length of 'ipiv' must be equal to the number of rows of 'a'");
    assert(b.length!1 == a.length!0, "sysv_rook: The number of columns of 'b' must equal the number of rows of 'a'.");
}
do
{
    lapackint n = cast(lapackint) a.length;
    lapackint nrhs = cast(lapackint) b.length;
    lapackint lda = cast(lapackint) a._stride.max(1);
    lapackint ldb = cast(lapackint) b._stride.max(1);
    lapackint lwork = cast(lapackint) work.length;
    lapackint info;

    lapack.sysv_rook_(uplo, n, nrhs, a._iterator, lda, ipiv._iterator, b._iterator, ldb, work._iterator, lwork, info);

    assert(info >= 0);
    return info;
}

unittest
{
    alias s = sysv_rook!float;
    alias d = sysv_rook!double;
    alias c = sysv_rook!_cfloat;
    alias z = sysv_rook!_cdouble;
}

///
size_t syev_wk(T)(
    char jobz,
    char uplo,
    Slice!(T*, 2, Canonical) a,
    Slice!(T*) w,
    )
in
{
    assert(a.length!0 == a.length!1, "syev_wk: The input 'a' must be a square matrix.");
    assert(w.length == a.length!0, "syev_wk: The length of 'w' must equal the number of rows of 'a'.");
}
do
{
    lapackint n = cast(lapackint) a.length;
    lapackint lda = cast(lapackint) a._stride.max(1);
    T work;
    lapackint lwork = -1;
    lapackint info;

    lapack.syev_(jobz, uplo, n, a._iterator, lda, w._iterator, &work, lwork, info);

    return cast(size_t) work.re;
}

unittest
{
    alias s = syev_wk!float;
    alias d = syev_wk!double;
}

///
size_t syev(T)(
    char jobz,
    char uplo,
    Slice!(T*, 2, Canonical) a,
    Slice!(T*) w,
    Slice!(T*) work,
    )
in
{
    assert(a.length!0 == a.length!1, "syev: The input 'a' must be a square matrix.");
    assert(w.length == a.length!0, "syev: The length of 'w' must equal the number of rows of 'a'.");
}
do
{
    lapackint n = cast(lapackint) a.length;
    lapackint lda = cast(lapackint) a._stride.max(1);
    lapackint lwork = cast(lapackint) work.length;
    lapackint info;

    lapack.syev_(jobz, uplo, n, a._iterator, lda, w._iterator, work._iterator, lwork, info);

    assert(info >= 0);
    return info;
}

unittest
{
    alias s = syev!float;
    alias d = syev!double;
}

///
size_t syev_2stage_wk(T)(
    char jobz,
    char uplo,
    Slice!(T*, 2, Canonical) a,
    Slice!(T*) w,
    )
in
{
    assert(a.length!0 == a.length!1, "syev_2stage_wk: The input 'a' must be a square matrix.");
    assert(w.length == a.length, "syev_2stage_wk: The length of 'w' must equal the number of rows of 'a'.");
}
do
{
    lapackint n = cast(lapackint) a.length;
    lapackint lda = cast(lapackint) a._stride.max(1);
    T work;
    lapackint lwork = -1;
    lapackint info;

    lapack.syev_2stage_(jobz, uplo, n, a._iterator, lda, w._iterator, &work, lwork, info);

    return cast(size_t) work.re;
}

version(none)
unittest
{
    alias s = syev_2stage_wk!float;
    alias d = syev_2stage_wk!double;
}

///
size_t syev_2stage(T)(
    char jobz,
    char uplo,
    Slice!(T*, 2, Canonical) a,
    Slice!(T*) w,
    Slice!(T*) work,
    )
in
{
    assert(a.length!0 == a.length!1, "syev_2stage: The input 'a' must be a square matrix.");
    assert(w.length == a.length, "syev_2stage: The length of 'w' must equal the number of rows of 'a'.");
}
do
{
    lapackint n = cast(lapackint) a.length;
    lapackint lda = cast(lapackint) a._stride.max(1);
    lapackint lwork = cast(lapackint) work.length;
    lapackint info;

    lapack.syev_2stage_(jobz, uplo, n, a._iterator, lda, w._iterator, work._iterator, lwork, info);

    assert(info >= 0);
    return info;
}

version(none)
unittest
{
    alias s = syev_2stage!float;
    alias d = syev_2stage!double;
}

///
size_t potrf(T)(
       char uplo,
       Slice!(T*, 2, Canonical) a,
       )
in
{
    assert(a.length!0 == a.length!1, "potrf: The input 'a' must be a square matrix.");
}
do
{
    lapackint n = cast(lapackint) a.length;
    lapackint lda = cast(lapackint) a._stride.max(1);
    lapackint info;
    
    lapack.potrf_(uplo, n, a.iterator, lda, info);
    
    assert(info >= 0);
    
    return info;
}

unittest
{
    alias s = potrf!float;
    alias d = potrf!double;
    alias c = potrf!_cfloat;
    alias z = potrf!_cdouble;
}

///
size_t pptrf(T)(
    char uplo,
    Slice!(T*, 2, Canonical) ap,
    )
{
    lapackint n = cast(lapackint) ap.length;
    lapackint info;
    
    lapack.pptrf_(uplo, n, ap.iterator, info);
    
    assert(info >= 0);
    
    return info;
}

unittest
{
    alias s = pptrf!float;
    alias d = pptrf!double;
    alias c = pptrf!_cfloat;
    alias z = pptrf!_cdouble;
}

///
template sptri(T)
{
    /// `sptri` for upper triangular input.
    size_t sptri(
        Slice!(StairsIterator!(T*, "+")) ap,
        Slice!(lapackint*) ipiv,
        Slice!(T*) work
        )
    in
    {
        assert(ipiv.length == ap.length, "sptri: The length of 'ipiv' must be equal to the length of 'ap'.");
        assert(work.length == ap.length, "sptri: The length of 'work' must be equal to the length of 'ap'.");
    }
    do
    {
        lapackint n = cast(lapackint) ap.length;
        lapackint info;

        char uplo = 'U';
        lapack.sptri_(uplo, n, &ap[0][0], ipiv.iterator, work.iterator, info);

        assert(info >= 0);
        return info;
    }

    /// `sptri` for lower triangular input.
    size_t sptri(
        Slice!(StairsIterator!(T*, "-")) ap,
        Slice!(lapackint*) ipiv,
        Slice!(T*) work
        )
    in
    {
        assert(ipiv.length == ap.length, "sptri: The length of 'ipiv' must be equal to the length of 'ap'.");
        assert(work.length == ap.length, "sptri: The length of 'work' must be equal to the length of 'ap'.");
    }
    do
    {
        lapackint n = cast(lapackint) ap.length;
        lapackint info;

        char uplo = 'L';
        lapack.sptri_(uplo, n, &ap[0][0], ipiv.iterator, work.iterator, info);

        assert(info >= 0);
        return info;
    }
}

unittest
{
    alias s = sptri!float;
    alias d = sptri!double;
    alias c = sptri!_cfloat;
    alias z = sptri!_cdouble;
}

///
size_t potri(T)(
    char uplo,
    Slice!(T*, 2, Canonical) a,
    )
in
{
    assert(a.length!0 == a.length!1, "potri: The input 'a' must be a square matrix.");
}
do
{
    lapackint n = cast(lapackint) a.length;
    lapackint lda = cast(lapackint) a._stride.max(1);
    lapackint info;

    lapack.potri_(uplo, n, a.iterator, lda, info);

    assert(info >= 0);
    return info;
}

unittest
{
    alias s = potri!float;
    alias d = potri!double;
    alias c = potri!_cfloat;
    alias z = potri!_cdouble;
}

///
template pptri(T)
{
    /// `pptri` for upper triangular input.
    size_t pptri(
        Slice!(StairsIterator!(T*, "+")) ap
        )
    {
        lapackint n = cast(lapackint) ap.length;
        lapackint info;

        char uplo = 'U';
        lapack.pptri_(uplo, n, &ap[0][0], info);

        assert(info >= 0);
        return info;
    }

    /// `pptri` for lower triangular input.
    size_t pptri(
        Slice!(StairsIterator!(T*, "-")) ap
        )
    {
        lapackint n = cast(lapackint) ap.length;
        lapackint info;

        char uplo = 'L';
        lapack.pptri_(uplo, n, &ap[0][0], info);

        assert(info >= 0);
        return info;
    }
}

unittest
{
    alias s = pptri!float;
    alias d = pptri!double;
    alias c = pptri!_cfloat;
    alias z = pptri!_cdouble;
}

///
size_t trtri(T)(
    char uplo,
    char diag,
    Slice!(T*, 2, Canonical) a,
    )
in
{
    assert(a.length!0 == a.length!1, "trtri: The input 'a' must be a square matrix.");
}
do
{
    lapackint n = cast(lapackint) a.length;
    lapackint lda = cast(lapackint) a._stride.max(1);
    lapackint info;

    lapack.trtri_(uplo, diag, n, a.iterator, lda, info);

    assert(info >= 0);
    return info;
}

unittest
{
    alias s = trtri!float;
    alias d = trtri!double;
    alias c = trtri!_cfloat;
    alias z = trtri!_cdouble;
}

///
template tptri(T)
{
    /// `tptri` for upper triangular input.
    size_t tptri(
        char diag,
        Slice!(StairsIterator!(T*, "+")) ap,
        )
    {
        lapackint n = cast(lapackint) ap.length;
        lapackint info;

        char uplo = 'U';
        lapack.tptri_(uplo, diag, n, &ap[0][0], info);

        assert(info >= 0);
        return info;
    }

    /// `tptri` for lower triangular input.
    size_t tptri(
        char diag,
        Slice!(StairsIterator!(T*, "-")) ap,
        )
    {
        lapackint n = cast(lapackint) ap.length;
        lapackint info;

        char uplo = 'L';
        lapack.tptri_(uplo, diag, n, &ap[0][0], info);

        assert(info >= 0);
        return info;

    }
}

unittest
{
    alias s = tptri!float;
    alias d = tptri!double;
    alias c = tptri!_cfloat;
    alias z = tptri!_cdouble;
}

///
size_t ormqr(T)(
    char side,
    char trans,
    Slice!(T*, 2, Canonical) a,
    Slice!(T*) tau,
    Slice!(T*, 2, Canonical) c,
    Slice!(T*) work,
    )
{
    lapackint m = cast(lapackint) c.length!1;
    lapackint n = cast(lapackint) c.length!0;
    lapackint k = cast(lapackint) tau.length;
    lapackint lda = cast(lapackint) a._stride.max(1);
    lapackint ldc = cast(lapackint) c._stride.max(1);
    lapackint lwork = cast(lapackint) work.length;
    lapackint info;

    lapack.ormqr_(side, trans, m, n, k, a.iterator, lda, tau.iterator, c.iterator, ldc, work.iterator, lwork, info);

    ///if info == 0: successful exit.
    ///if info < 0: if info == -i, the i-th argument had an illegal value.
    assert(info >= 0);
    return info;
}

unittest
{
    alias s = ormqr!float;
    alias d = ormqr!double;
}

///
size_t unmqr(T)(
    char side,
    char trans,
    Slice!(T*, 2, Canonical) a,
    Slice!(T*) tau,
    Slice!(T*, 2, Canonical) c,
    Slice!(T*) work,
    )
{
    lapackint m = cast(lapackint) c.length!1;
    lapackint n = cast(lapackint) c.length!0;
    lapackint k = cast(lapackint) tau.length;
    lapackint lda = cast(lapackint) a._stride.max(1);
    lapackint ldc = cast(lapackint) c._stride.max(1);
    lapackint lwork = cast(lapackint) work.length;
    lapackint info;

    lapack.unmqr_(side, trans, m, n, k, a.iterator, lda, tau.iterator, c.iterator, ldc, work.iterator, lwork, info);

    ///if info == 0: successful exit.
    ///if info < 0: if info == -i, the i-th argument had an illegal value.
    assert(info >= 0);
    return info;
}

unittest
{
    alias s = unmqr!_cfloat;
    alias d = unmqr!_cdouble;
}

///
size_t orgqr(T)(
    Slice!(T*, 2, Canonical) a,
    Slice!(T*) tau,
    Slice!(T*) work,
    )
in
{
    assert(a.length!0 >= 0, "orgqr: The number of columns of 'a' must be " ~ 
        "greater than or equal to zero."); //n>=0
    assert(a.length!1 >= a.length!0, "orgqr: The number of columns of 'a' " ~ 
        "must be greater than or equal to the number of its rows."); //m>=n
    assert(tau.length >= 0, "orgqr: The input 'tau' must have length greater " ~ 
        "than or equal to zero."); //k>=0
    assert(a.length!0 >= tau.length, "orgqr: The number of columns of 'a' " ~ 
        "must be greater than or equal to the length of 'tau'."); //n>=k
    assert(work.length >= a.length!0, "orgqr: The length of 'work' must be " ~ 
        "greater than or equal to the number of rows of 'a'."); //lwork>=n
}
do
{
    lapackint m = cast(lapackint) a.length!1;
    lapackint n = cast(lapackint) a.length!0;
    lapackint k = cast(lapackint) tau.length;
    lapackint lda = cast(lapackint) a._stride.max(1);
    lapackint lwork = cast(lapackint) work.length;
    lapackint info;

    lapack.orgqr_(m, n, k, a.iterator, lda, tau.iterator, work.iterator, lwork, info);

    ///if info == 0: successful exit.
    ///if info < 0: if info == -i, the i-th argument had an illegal value.
    assert(info >= 0);
    return info;
}

unittest
{
    alias s = orgqr!float;
    alias d = orgqr!double;
}

///
size_t ungqr(T)(
    Slice!(T*, 2, Canonical) a,
    Slice!(T*) tau,
    Slice!(T*) work,
    )
in
{
    assert(a.length!1 >= a.length!0, "ungqr: The number of columns of 'a' must be greater than or equal to the number of its rows."); //m>=n
    assert(a.length!0 >= tau.length, "ungqr: The number of columns of 'a' must be greater than or equal to the length of 'tau'."); //n>=k
    assert(work.length >= a.length!0, "ungqr: The length of 'work' must be greater than or equal to the number of rows of 'a'."); //lwork>=n
}
do
{
    lapackint m = cast(lapackint) a.length!1;
    lapackint n = cast(lapackint) a.length!0;
    lapackint k = cast(lapackint) tau.length;
    lapackint lda = cast(lapackint) a._stride.max(1);
    lapackint lwork = cast(lapackint) work.length;
    lapackint info;

    lapack.ungqr_(m, n, k, a.iterator, lda, tau.iterator, work.iterator, lwork, info);

    ///if info == 0: successful exit.
    ///if info < 0: if info == -i, the i-th argument had an illegal value.
    assert(info >= 0);
    return info;
}

unittest
{
    alias s = ungqr!_cfloat;
    alias d = ungqr!_cdouble;
}

alias orghr = unghr; // this is the name for the real type vairant of ungqr

///
size_t unghr(T)(
    Slice!(T*, 2, Canonical) a,
    Slice!(T*) tau,
    Slice!(T*) work,
)
in
{
    assert(a.length!1 >= a.length!0); //m>=n
    assert(a.length!0 >= tau.length); //n>=k
    assert(work.length >= a.length!0); //lwork>=n
}
do
{
    lapackint m = cast(lapackint) a.length!1;
    lapackint n = cast(lapackint) a.length!0;
    lapackint k = cast(lapackint) tau.length;
    lapackint lda = cast(lapackint) a._stride.max(1);
    lapackint lwork = cast(lapackint) work.length;
    lapackint info;
    static if (isComplex!T){
        lapack.ungqr_(m, n, k, a.iterator, lda, tau.iterator, work.iterator, lwork, info);
    }
    else { 
        lapack.orgqr_(m, n, k, a.iterator, lda, tau.iterator, work.iterator, lwork, info);
    }

    ///if info == 0: successful exit.
    ///if info < 0: if info == -i, the i-th argument had an illegal value.
    assert(info >= 0);
    return cast(size_t)info;
}

unittest
{
    alias orghrf = orghr!float;
    alias orghrd = orghr!double;
    alias unghrf = unghr!float;
    alias unghrd = unghr!double;
    alias unghrcf = unghr!_cfloat;
    alias unghrcd = unghr!_cdouble;
}

///
size_t gehrd(T)(
    Slice!(T*, 2, Canonical) a,
    Slice!(T*) tau,
    Slice!(T*) work,
    lapackint ilo,
    lapackint ihi
)
in
{
    assert(a.length!1 >= a.length!0, "gehrd: The number of columns of 'a' must be greater than or equal to the number of its rows."); //m>=n
    assert(a.length!0 >= tau.length, "gehrd: The number of columns of 'a' must be greater than or equal to the length of 'tau'."); //n>=k
    assert(work.length >= a.length!0, "gehrd: The length of 'work' must be greater than or equal to the number of rows of 'a'."); //lwork>=n
}
do
{
    lapackint n = cast(lapackint) a.length!0;
    lapackint lda = cast(lapackint) a._stride.max(1);
    lapackint lwork = cast(lapackint) work.length;
    lapackint info;    
    lapack.gehrd_(n, ilo, ihi, a.iterator, lda, tau.iterator, work.iterator, lwork, info);
    ///if info == 0: successful exit.
    ///if info < 0: if info == -i, the i-th argument had an illegal value.
    assert(info >= 0);
    return cast(size_t)info;
}

unittest
{
    alias s = gehrd!_cfloat;
    alias d = gehrd!_cdouble;
}

size_t hsein(T)(
    char side,
    char eigsrc,
    char initv,
    ref lapackint select, //actually a logical bitset stored in here
    Slice!(T*, 2, Canonical) h,
    Slice!(T*) wr,
    Slice!(T*) wi,
    Slice!(T*, 2, Canonical) vl,
    Slice!(T*, 2, Canonical) vr,
    ref lapackint m,
    Slice!(T*) work,
    ref lapackint ifaill,
    ref lapackint ifailr,
)
    if (!isComplex!T)
in
{
    assert(h.length!1 >= h.length!0, "hsein: The number of columns of 'h' " ~ 
           "must be greater than or equal to the number of its rows."); //m>=n
    assert(wr.length >= 1, "hsein: The input 'wr' must have length greater " ~ 
           "than or equal to one.");
    assert(wr.length >= h.length!0, "hsein: The input 'wr' must have length greater " ~ 
           "than or equal to the number of rows of 'h'.");
    assert(wr.length >= 1.0, "hsein: The input 'wr' must have length greater " ~ 
           "than or equal to 1.");
    assert(wi.length >= 1, "hsein: The input 'wi' must have length greater " ~ 
           "than or equal to one.");
    assert(wi.length >= h.length!0, "hsein: The input 'wi' must have length greater " ~ 
           "than or equal to the number of rows of 'h'.");
    assert(wi.length >= 1.0, "hsein: The input 'wi' must have length greater " ~ 
           "than or equal to 1.");
    assert(work.length >= h.length!0 * (h.length!0 + 2), "hsein: The length of 'work' must be " ~ 
           "greater than or equal to the square of the number of rows of 'h' plus two additional rows for real types.");
    assert(side == 'R' || side == 'L' || side == 'B', "hsein: The char, 'side' must be " ~ 
           "one of 'R', 'L' or 'B'.");
    assert(eigsrc == 'Q' || eigsrc == 'N', "hsein: The char, 'eigsrc', must be " ~
           "one of 'Q' or 'R'.");
    assert(initv == 'N' || initv == 'U', "hsein: The char, 'initv', must be " ~
           "one of 'N' or 'U'.");
    assert(side != 'L' || side != 'B' || vl.length!1 >= 1, "hsein: Slice 'vl' must be" ~
           "at least the size of '1' when 'side' is set to 'L' or 'B'.");
    assert(side != 'R' || vl.length!1 >= 1, "hsein: Slice 'vl' must be" ~
           "length greater than 1 when 'side' is 'R'.");
    assert(side != 'R' || side != 'B' || vr.length!1 >= 1, "hsein: Slice 'vr' must be" ~
           "at least the size of '1' when 'side' is set to 'R' or 'B'.");
    assert(side != 'L' || vl.length!1 >= 1, "hsein: Slice 'vr' must be" ~
           "length greater than 1 when 'side' is 'L'.");
}
do 
{
    lapackint info;
    lapackint mm = cast(lapackint) vl.length!1;
    lapackint n = cast(lapackint) h.length!0;
    lapackint ldh = cast(lapackint) h._stride.max(1);
    lapackint ldvl = cast(lapackint) vl._stride.max(1);
    lapackint ldvr = cast(lapackint) vr._stride.max(1);
    //need to seperate these methods then probably provide a wrap which does this as that's the easiest way without bloating the base methods
    lapack.hsein_(side, eigsrc, initv, select, n, h.iterator, ldh, wr.iterator, wi.iterator, vl.iterator, ldvl, vr.iterator, ldvr, mm, m, work.iterator, ifaill, ifailr, info);
    assert(info >= 0);
    ///if any of ifaill or ifailr entries are non-zero then that has failed to converge.
    ///ifail?[i] = j > 0 if the eigenvector stored in the i-th column of v?, coresponding to the jth eigenvalue, fails to converge.
    assert(ifaill == 0);
    assert(ifailr == 0);
    return info;
}

size_t hsein(T, realT)(
    char side,
    char eigsrc,
    char initv,
    lapackint select, //actually a logical bitset stored in here
    Slice!(T*, 2, Canonical) h,
    Slice!(T*) w,
    Slice!(T*, 2, Canonical) vl,
    Slice!(T*, 2, Canonical) vr,
    lapackint* m,
    Slice!(T*) work,
    Slice!(realT*) rwork,
    lapackint ifaill,
    lapackint ifailr,
)
    if (isComplex!T && is(realType!T == realT))
in
{
    assert(h.length!1 >= h.length!0, "hsein: The number of columns of 'h' " ~ 
           "must be greater than or equal to the number of its rows."); //m>=n
    assert(w.length >= 1, "hsein: The input 'w' must have length greater " ~ 
           "than or equal to one.");
    assert(w.length >= h.length!0, "hsein: The input 'w' must have length greater " ~ 
           "than or equal to the number of rows of 'h'.");
    assert(w.length >= 1.0, "hsein: The input 'w' must have length greater " ~ 
           "than or equal to 1.");
    assert(work.length >= h.length!0 * h.length!0, "hsein: The length of 'work' must be " ~ 
           "greater than or equal to the square of the number of rows of 'h' for complex types.");
    assert(side == 'R' || side == 'L' || side == 'B', "hsein: The char, 'side' must be " ~ 
           "one of 'R', 'L' or 'B'.");
    assert(eigsrc == 'Q' || eigsrc == 'N', "hsein: The char, 'eigsrc', must be " ~
           "one of 'Q' or 'R'.");
    assert(initv == 'N' || initv == 'U', "hsein: The char, 'initv', must be " ~
           "one of 'N' or 'U'.");
    assert(side != 'L' || side != 'B' || vl.length!1 >= 1, "hsein: Slice 'vl' must be" ~
           "at least the size of '1' when 'side' is set to 'L' or 'B'.");
    assert(side != 'R' || vl.length!1 >= 1, "hsein: Slice 'vl' must be" ~
           "length greater than 1 when 'side' is 'R'.");
    assert(side != 'R' || side != 'B' || vr.length!1 >= 1, "hsein: Slice 'vr' must be" ~
           "at least the size of '1' when 'side' is set to 'R' or 'B'.");
    assert(side != 'L' || vl.length!1 >= 1, "hsein: Slice 'vr' must be" ~
           "length greater than 1 when 'side' is 'L'.");
}
do {
    lapackint n = cast(lapackint) h.length!0;
    lapackint ldh = cast(lapackint) h._stride.max(1);
    lapackint ldvl = cast(lapackint) vl._stride.max(1);
    lapackint ldvr = cast(lapackint) vr._stride.max(1);
    lapackint mm = cast(lapackint) vl.length!1;
    lapackint info;
    //could compute mm and m from vl and/or vr and T
    lapack.hsein_(side, eigsrc, initv, select, n, h.iterator, ldh, w.iterator, vl.iterator, ldvl, vr.iterator, ldvr, mm, *m, work.iterator, rwork.iterator, ifaill, ifailr, info);
    assert(info >= 0);
    ///if any of ifaill or ifailr entries are non-zero then that has failed to converge.
    ///ifail?[i] = j > 0 if the eigenvector stored in the i-th column of v?, coresponding to the jth eigenvalue, fails to converge.
    assert(ifaill == 0);
    assert(ifailr == 0);
    return info;
}


unittest
{
    alias f = hsein!(float);
    alias d = hsein!(double);
    alias s = hsein!(_cfloat, float);
    alias c = hsein!(_cdouble, double);
}

alias ormhr = unmhr;

///
size_t unmhr(T)(
    char side,
    char trans,
    Slice!(T*, 2, Canonical) a,
    Slice!(T*) tau,
    Slice!(T*, 2, Canonical) c,
    Slice!(T*) work,
    lapackint ilo,
    lapackint ihi
)
in
{
    assert(a.length!0 >= 0, "ormhr: The number of columns of 'a' must be " ~ 
           "greater than or equal to zero."); //n>=0
    assert(a.length!1 >= a.length!0, "ormhr: The number of columns of 'a' " ~ 
           "must be greater than or equal to the number of its rows."); //m>=n
    assert(c.length!0 >= 0, "ormhr: The number of columns of 'c' must be " ~ 
           "greater than or equal to zero."); //n>=0
    assert(c.length!1 >= c.length!0, "ormhr: The number of columns of 'c' " ~ 
           "must be greater than or equal to the number of its rows."); //m>=n
    assert(tau.length >= 0, "ormhr: The input 'tau' must have length greater " ~ 
           "than or equal to zero."); //k>=0
    assert(a.length!0 >= tau.length, "ormhr: The number of columns of 'a' " ~ 
           "must be greater than or equal to the length of 'tau'."); //n>=k
    assert(work.length >= a.length!0, "ormhr: The length of 'work' must be " ~ 
           "greater than or equal to the number of rows of 'a'."); //lwork>=n
    assert(side == 'L' || side == 'R', "ormhr: 'side' must be" ~
           "one of 'L' or 'R'.");
    assert(trans == 'N' || trans == 'T', "ormhr: 'trans' must be" ~
           "one of 'N' or 'T'.");
}
do
{
    lapackint m = cast(lapackint) a.length!0;
    lapackint n = cast(lapackint) a.length!1;
    lapackint lda = cast(lapackint) a._stride.max(1);
    lapackint ldc = cast(lapackint) c._stride.max(1);
    lapackint lwork = cast(lapackint) work.length;
    lapackint info;
    static if (!isComplex!T){
        lapack.ormhr_(side, trans, m, n, ilo, ihi, a.iterator, lda, tau.iterator, c.iterator, ldc, work.iterator, lwork, info);
    }
    else {
        lapack.unmhr_(side, trans, m, n, ilo, ihi, a.iterator, lda, tau.iterator, c.iterator, ldc, work.iterator, lwork, info);
    }
    ///if info == 0: successful exit.
    ///if info < 0: if info == -i, the i-th argument had an illegal value.
    assert(info >= 0);
    return cast(size_t)info;
}

unittest
{
    alias s = unmhr!_cfloat;
    alias d = unmhr!_cdouble;
    alias a = ormhr!double;
    alias b = ormhr!float;
}

///
size_t hseqr(T)(
    char job,
    char compz,
    Slice!(T*, 2, Canonical) h,
    Slice!(T*) w,
    Slice!(T*, 2, Canonical) z,
    Slice!(T*) work,
    lapackint ilo,
    lapackint ihi
)
    if (isComplex!T)
in
{
    assert(job == 'E' || job == 'S', "hseqr");
    assert(compz == 'N' || compz == 'I' || compz == 'V', "hseqr");
    assert(h.length!1 >= h.length!0, "hseqr");
    assert(h.length!1 >= 1, "hseqr");
    assert(compz != 'V' || compz != 'I' || (z.length!1 >= h.length!0 && z.length!1 >= 1), "hseqr");
    assert(compz != 'N' || z.length!1 >= 1);
    assert(work.length!0 >= 1, "hseqr");
    assert(work.length!0 >= h.length!0, "hseqr");
}
do
{
    lapackint n = cast(lapackint) h.length!0;
    lapackint ldh = cast(lapackint) h._stride.max(1);
    lapackint ldz = cast(lapackint) z._stride.max(1);
    lapackint lwork = cast(lapackint) work.length!0;
    lapackint info;
    lapack.hseqr_(job,compz,n,ilo,ihi,h.iterator, ldh, w.iterator, z.iterator, ldz, work.iterator, lwork, info);
    assert(info >= 0);
    return cast(size_t)info;
}

///
size_t hseqr(T)(
    char job,
    char compz,
    Slice!(T*, 2, Canonical) h,
    Slice!(T*) wr,
    Slice!(T*) wi,
    Slice!(T*, 2, Canonical) z,
    Slice!(T*) work,
    lapackint ilo,
    lapackint ihi
)
    if (!isComplex!T)
in
{
    assert(job == 'E' || job == 'S', "hseqr");
    assert(compz == 'N' || compz == 'I' || compz == 'V', "hseqr");
    assert(h.length!1 >= h.length!0, "hseqr");
    assert(h.length!1 >= 1, "hseqr");
    assert(compz != 'V' || compz != 'I' || (z.length!1 >= h.length!0 && z.length!1 >= 1), "hseqr");
    assert(compz != 'N' || z.length!1 >= 1);
    assert(work.length!0 >= 1, "hseqr");
    assert(work.length!0 >= h.length!0, "hseqr");
}
do
{
    lapackint n = cast(lapackint) h.length!0;
    lapackint ldh = cast(lapackint) h._stride.max(1);
    lapackint ldz = cast(lapackint) z._stride.max(1);
    lapackint lwork = cast(lapackint) work.length!0;
    lapackint info;
    lapack.hseqr_(job,compz,n,ilo,ihi,h.iterator, ldh, wr.iterator, wi.iterator, z.iterator, ldz, work.iterator, lwork, info);
    assert(info >= 0);
    return cast(size_t)info;
}

unittest
{
    alias f = hseqr!float;
    alias d = hseqr!double;
    alias s = hseqr!_cfloat;
    alias c = hseqr!_cdouble;
}

///
size_t trevc(T)(char side,
    char howmany,
    lapackint select,
    Slice!(T*, 2, Canonical) t,
    Slice!(T*, 2, Canonical) vl,
    Slice!(T*, 2, Canonical) vr,
    lapackint m,
    Slice!(T*) work
)
do
{
    lapackint n = cast(lapackint)t.length!0;
    lapackint ldt = cast(lapackint) t._stride.max(1);
    lapackint ldvl = cast(lapackint) vl._stride.max(1);
    lapackint ldvr = cast(lapackint) vr._stride.max(1);
    lapackint mm = cast(lapackint) vr.length!1;
    //select should be lapack_logical
    lapackint info;
    static if(!isComplex!T){
        lapack.trevc_(side, howmany, select, n, t.iterator, ldt, vl.iterator, ldvl, vr.iterator, ldvr, mm, m, work.iterator, info);
    }
    else {
        lapack.trevc_(side, howmany, select, n, t.iterator, ldt, vl.iterator, ldvl, vr.iterator, ldvr, mm, m, work.iterator, null, info);
    }
    assert(info >= 0);
    return cast(size_t)info;
}

unittest
{
    alias f = trevc!float;
    alias d = trevc!double;
    alias s = trevc!_cfloat;
    alias c = trevc!_cdouble;
}

///
size_t gebal(T, realT)(char job,
    Slice!(T*, 2, Canonical) a,
    lapackint ilo,
    lapackint ihi,
    Slice!(realT*) scale
)
    if (!isComplex!T || (isComplex!T && is(realType!T == realT)))
{
    lapackint n = cast(lapackint) a.length!0;
    lapackint lda = cast(lapackint) a._stride.max(1);
    lapackint info;
    lapack.gebal_(job, n, a.iterator, lda, ilo, ihi, scale.iterator, info);
    assert(info >= 0);
    return cast(size_t)info;
}

unittest
{
    alias a = gebal!(double, double);
    alias b = gebal!(_cdouble, double);
    alias c = gebal!(float, float);
    alias d = gebal!(_cfloat, float);
}

///
size_t gebak(T, realT)(
    char job,
    char side,
    lapackint ilo,
    lapackint ihi,
    Slice!(realT*) scale,
    Slice!(T*, 2, Canonical) v
)
    if (!isComplex!T || (isComplex!T && is(realType!T == realT)))
{
    lapackint n = cast(lapackint) scale.length!0;
    lapackint m = cast(lapackint) v.length!1;//num evects
    lapackint ldv = cast(lapackint) v._stride.max(1);
    lapackint info;
    lapack.gebak_(job, side, n, ilo, ihi, scale.iterator, m, v.iterator, ldv, info);
    assert(info >= 0);
    return cast(size_t)info;
}

unittest
{
    alias a = gebak!(double, double);
    alias b = gebak!(_cdouble, double);
    alias c = gebak!(float, float);
    alias d = gebak!(_cfloat, float);
}

///
size_t geev(T, realT)(
    char jobvl,
    char jobvr,
    Slice!(T*, 2, Canonical) a,
    Slice!(T*) w,
    Slice!(T*, 2, Canonical) vl,
    Slice!(T*, 2, Canonical) vr,
    Slice!(T*) work,
    Slice!(realT*) rwork
)
    if (isComplex!T && is(realType!T == realT))
{
    lapackint n = cast(lapackint) a.length!0;
    lapackint lda = cast(lapackint) a._stride.max(1);
    lapackint ldvr = cast(lapackint) vr._stride.max(1);
    lapackint ldvl = cast(lapackint) vl._stride.max(1);
    lapackint info;
    lapackint lwork = cast(lapackint)work.length!0;
    lapack.geev_(jobvl, jobvr, n, a.iterator, lda, w.iterator, vl.iterator, ldvl, vr.iterator, ldvr, work.iterator, lwork, rwork.iterator, info);
    assert(info >= 0);
    return info;
}

///
size_t geev(T)(
    char jobvl,
    char jobvr,
    Slice!(T*, 2, Canonical) a,
    Slice!(T*) wr,
    Slice!(T*) wi,
    Slice!(T*, 2, Canonical) vl,
    Slice!(T*, 2, Canonical) vr,
    Slice!(T*) work
)
    if (!isComplex!T)
{
    lapackint n = cast(lapackint) a.length!0;
    lapackint lda = cast(lapackint) a._stride.max(1);
    lapackint ldvr = cast(lapackint) vr._stride.max(1);
    lapackint ldvl = cast(lapackint) vl._stride.max(1);
    lapackint info;
    lapackint lwork = cast(lapackint)work.length!0;
    lapack.geev_(jobvl, jobvr, n, a.iterator, lda, wr.iterator, wi.iterator, vl.iterator, ldvl, vr.iterator, ldvr, work.iterator, lwork, info);
    assert(info >= 0);
    return info;
}

///
size_t steqr(T, realT = realType!T)(
    char compz,
    Slice!(realT*) d,
    Slice!(realT*) e,
    Slice!(T*, 2, Canonical) z,
    Slice!(realT*) work)
    if (is(realType!T == realT))
in {
    assert(d.length == e.length + 1);
    assert(work.length >= (e.length * 2).max(1u));
    assert(z.length!0 == d.length);
    assert(z.length!1 == d.length);
    assert(z._stride >= d.length);
}
do {
    lapackint n = cast(lapackint) d.length;
    lapackint ldz = cast(lapackint) z._stride.max(1);
    lapackint info;

    lapack.steqr_(compz, n, d.iterator, e.iterator, z.iterator, ldz, work.iterator, info);
    assert(info >= 0);
    return info;
}

unittest
{
    alias a = steqr!float;
    alias b = steqr!double;
    alias c = steqr!_cfloat;
    alias d = steqr!_cdouble;
}


///
@trusted
size_t sytrs_3(T)(
    char uplo,
    Slice!(const(T)*, 2, Canonical) a,
    Slice!(const(T)*) e,
    Slice!(const(lapackint)*) ipiv,
    Slice!(T*, 2, Canonical) b,
    )
in
{
    assert(a.length!0 == a.length!1, "sytrs_3: 'a' must be a square matrix.");
    assert(e.length == a.length, "sytrs_3: 'e' must have the same length as 'a'.");
    assert(b.length!1 == a.length, "sytrs_3: 'b.length!1' must must be equal to 'a.length'.");
}
do
{
    lapackint n = cast(lapackint) a.length;
    lapackint nrhs = cast(lapackint) b.length;
    lapackint lda = cast(lapackint) a._stride.max(1);
    lapackint ldb = cast(lapackint) b._stride.max(1);
    lapackint info;
// ref char uplo, ref lapackint n, ref lapackint nrhs, float *a, ref lapackint lda, float* e, lapackint *ipiv, float *b, ref lapackint ldb, ref lapackint info
    lapack.sytrs_3_(uplo, n, nrhs, a.iterator, lda, e.iterator, ipiv.iterator, b.iterator, ldb, info);
    assert(info >= 0);
    return info;
}

version(none)
unittest
{
    alias s = sytrs_3!float;
    alias d = sytrs_3!double;
    alias c = sytrs_3!_cfloat;
    alias z = sytrs_3!_cdouble;
}

///
@trusted
size_t sytrf_rk(T)(
    char uplo,
    Slice!(T*, 2, Canonical) a,
    Slice!(T*) e,
    Slice!(lapackint*) ipiv,
    Slice!(T*) work,
    )
in
{
    assert(a.length!0 == a.length!1, "sytrf_rk: 'a' must be a square matrix.");
    assert(e.length == a.length, "sytrf_rk: 'e' must have the same length as 'a'.");
}
do
{
    lapackint info;
    lapackint n = cast(lapackint) a.length;
    lapackint lda = cast(lapackint) a._stride.max(1);
    lapackint lwork = cast(lapackint) work.length;
    lapack.sytrf_rk_(uplo, n, a.iterator, lda, e.iterator, ipiv.iterator, work.iterator, lwork, info);
    assert(info >= 0);
    return info;
}

version(none)
unittest
{
    alias s = sytrf_rk!float;
    alias d = sytrf_rk!double;
    alias c = sytrf_rk!_cfloat;
    alias z = sytrf_rk!_cdouble;
}


///
size_t sytrf_rk_wk(T)(
    char uplo,
    Slice!(T*, 2, Canonical) a,
    )
in
{
    assert(a.length!0 == a.length!1, "sytrf_rk_wk: 'a' must be a square matrix.");
}
do
{

    lapackint info;
    lapackint n = cast(lapackint) a.length;
    lapackint lda = cast(lapackint) a._stride.max(1);
    lapackint lwork = -1;
    lapackint info;
    T e;
    T work;
    lapackint ipiv;

    lapack.sytrf_rk_(uplo, n, a.iterator, lda, &e, &ipiv, &work, lwork, info);

    return cast(size_t) work.re;
}

version(none)
unittest
{
    alias s = sytrf_rk!float;
    alias d = sytrf_rk!double;
}

///
template posvx(T)
    if (is(T == double) || is(T == float))
{
    @trusted
    size_t posvx(
        char fact,
        char uplo,
        Slice!(T*, 2, Canonical) a,
        Slice!(T*, 2, Canonical) af,
        char equed,
        Slice!(T*) s,
        Slice!(T*, 2, Canonical) b,
        Slice!(T*, 2, Canonical) x,
        out T rcond,
        Slice!(T*) ferr,
        Slice!(T*) berr,
        Slice!(T*) work,
        Slice!(lapackint*) iwork,
    )
    in {
        assert(fact == 'F' || fact == 'N' || fact == 'E');
        assert(uplo == 'U' || uplo == 'L');
        auto n = a.length!0;
        auto nrhs = x.length;
        assert(a.length!1 == n);
        assert(af.length!0 == n);
        assert(af.length!1 == n);
        assert(x.length!1 == n);
        assert(b.length!1 == n);
        assert(b.length!0 == nrhs);
        assert(ferr.length == nrhs);
        assert(berr.length == nrhs);
        assert(work.length == n * 3);
        assert(iwork.length == n);
    }
    do {
        lapackint n = cast(lapackint) a.length!0;
        lapackint nrhs = cast(lapackint) x.length;
        lapackint lda = cast(lapackint) a._stride.max(1);
        lapackint ldaf = cast(lapackint) af._stride.max(1);
        lapackint ldx = cast(lapackint) x._stride.max(1);
        lapackint ldb = cast(lapackint) b._stride.max(1);
        lapackint info;
        lapack.posvx_(fact, uplo, n, nrhs, a._iterator, lda, af._iterator, ldaf, equed, s._iterator, b._iterator, ldb, x._iterator, ldx, rcond, ferr._iterator, berr._iterator, work._iterator, iwork._iterator, info);
        assert(info >= 0);
        return info;
    }

    @trusted
    size_t posvx(
        char fact,
        char uplo,
        Slice!(T*, 2, Canonical) a,
        Slice!(T*, 2, Canonical) af,
        char equed,
        Slice!(T*) s,
        Slice!(T*) b,
        Slice!(T*) x,
        out T rcond,
        out T ferr,
        out T berr,
        Slice!(T*) work,
        Slice!(lapackint*) iwork,
    )
    in {
        assert(fact == 'F' || fact == 'N' || fact == 'E');
        assert(uplo == 'U' || uplo == 'L');
        auto n = a.length!0;
        assert(a.length!1 == n);
        assert(af.length!0 == n);
        assert(af.length!1 == n);
        assert(x.length == n);
        assert(b.length == n);
        assert(work.length == n * 3);
        assert(iwork.length == n);
    }
    do {
        import mir.ndslice.topology: canonical;
        return posvx(fact, uplo, a, af, equed, s, b.sliced(1, b.length).canonical, x.sliced(1, x.length).canonical, rcond, sliced(&ferr, 1), sliced(&berr, 1), work, iwork);
    }
}

version(none)
unittest
{
    alias s = posvx!float;
    alias d = posvx!double;
}

///
size_t sytrf_wk(T)(
    char uplo,
    Slice!(T*, 2, Canonical) a,
    )
in
{
    assert(a.length!0 == a.length!1, "sytrf_wk: 'a' must be a square matrix.");
}
do
{
    lapackint n = cast(lapackint) a.length;
    lapackint lda = cast(lapackint) a._stride.max(1);
    lapackint lwork = -1;
    lapackint info;
    T work;
    lapackint ipiv;

    lapack.sytrf_(uplo, n, a.iterator, lda, &ipiv, &work, lwork, info);

    return cast(size_t) work.re;
}

unittest
{
    alias s = sytrf_wk!float;
    alias d = sytrf_wk!double;
}
