/++
Low level ndslice wrapper for LAPACK.

Attention: LAPACK and this module has column major API.

Authors: Ilya Yaroshenko
Copyright:  Copyright © 2017, Symmetry Investments & Kaleidic Associates
+/
module mir.lapack;

import mir.ndslice.slice;
import mir.ndslice.topology: retro;
import mir.ndslice.iterator;
import mir.utility: min, max;

static import lapack;

public import lapack: lapackint;

/// `getri` work space query.
size_t getri_wq(T)(Slice!(Canonical, [2], T*) a)
{
	assert(a.length!0 == a.length!1, "getri: a must be a square matrix.");

	lapackint n = cast(lapackint) a.length;
	lapackint lda = cast(lapackint) a._stride.max(1);
	T work = void;
	lapackint lwork = -1;
	lapackint info = void;

	lapack.getri_(n, null, lda, null, &work, lwork, info);

	assert(info == 0);
	return cast(size_t) work;
}

///
size_t getri(T)(
	Slice!(Canonical, [2], T*) a,
	Slice!(Contiguous, [1], lapackint*) ipiv,
	Slice!(Contiguous, [1], T*) work,
	)
{
	assert(a.length!0 == a.length!1, "getri: a must be a square matrix.");
	assert(ipiv.length == a.length);
	assert(work.length);

	lapackint n = cast(lapackint) a.length;
	lapackint lda = cast(lapackint) a._stride.max(1);
	lapackint lwork = cast(lapackint) work.length;
	lapackint info = void;

	lapack.getri_(n, a.iterator, lda, ipiv.iterator, work.iterator, lwork, info);

	assert(info >= 0);
	return info;
}

///
size_t getrf(T)(
	Slice!(Canonical, [2], T*) a,
	Slice!(Contiguous, [1], lapackint*) ipiv,
	)
{
	assert(ipiv.length == min(a.length!0, a.length!1));

	lapackint m = cast(lapackint) a.length!1;
	lapackint n = cast(lapackint) a.length!0;
	lapackint lda = cast(lapackint) a._stride.max(1);
	lapackint info = void;

	lapack.getrf_(m, n, a.iterator, lda, ipiv.iterator, info);

	assert(info >= 0);
	return info;
}

/// `sptrf` for upper triangular input.
size_t sptrf(T)(
	Slice!(Contiguous, [1], StairsIterator!(T*)) ap,
	Slice!(Contiguous, [1], lapackint*) ipiv,
	)
{
	assert(ipiv.length == ap.length);

	char uplo = 'U';
	lapackint n = cast(lapackint) ap.length;
	lapackint info = void;

	lapack.sptrf_(uplo, n, &ap[0][0], ipiv.iterator, info);

	assert(info >= 0);
	return info;
}

/// `sptrf` for lower triangular input.
size_t sptrf(T)(
	Slice!(Contiguous, [1], RetroIterator!(MapIterator!(StairsIterator!(RetroIterator!(T*)), retro))) ap,
	Slice!(Contiguous, [1], lapackint*) ipiv,
	)
{
	assert(ipiv.length == ap.length);

	char uplo = 'L';
	lapackint n = cast(lapackint) ap.length;
	lapackint info = void;

	lapack.sptrf_(uplo, n, &ap[0][0], ipiv.iterator, info);

	assert(info >= 0);
	return info;
}

///
size_t gesv(T)(
	Slice!(Canonical, [2], T*) a,
	Slice!(Contiguous, [1], lapackint*) ipiv,
	Slice!(Canonical, [2], T*) b,
	)
{
	assert(a.length!0 == a.length!1, "gesv: a must be a square matrix.");
	assert(ipiv.length == a.length);
	assert(b.length!1 == a.length);

	lapackint n = cast(lapackint) a.length;
	lapackint nrhs = cast(lapackint) b.length;
	lapackint lda = cast(lapackint) a._stride.max(1);
	lapackint ldb = cast(lapackint) b._stride.max(1);
	lapackint info = void;

	lapack.gesv_(n, nrhs, a.iterator, lda, ipiv.iterator, b.iterator, ldb, info);

	assert(info >= 0);
	return info;
}

/// `gelsd` work space query.
size_t gelsd_wq(T)(
	Slice!(Canonical, [2], T*) a,
	Slice!(Canonical, [2], T*) b,
	ref size_t liwork,
	)
{
	assert(b.length!1 == a.length!1);

	lapackint m = cast(lapackint) a.length!1;
	lapackint n = cast(lapackint) a.length!0;
	lapackint nrhs = cast(lapackint) b.length;
	lapackint lda = cast(lapackint) a._stride.max(1);
	lapackint ldb = cast(lapackint) b._stride.max(1);
	T rcond = void;
	lapackint rank = void;
	T work = void;
	lapackint lwork = -1;
	lapackint iwork = void;
	lapackint info = void;

	lapack.gelsd_(m, n, nrhs, a.iterator, lda, b.iterator, ldb, null, rcond, rank, &work, lwork, &iwork, info);

	assert(info == 0);
	liwork = iwork;
	return cast(size_t) work;
}

///
size_t gelsd(T)(
	Slice!(Canonical, [2], T*) a,
	Slice!(Canonical, [2], T*) b,
	Slice!(Contiguous, [1], T*) s,
	T rcond,
	ref size_t rank,
	Slice!(Contiguous, [1], T*) work,
	Slice!(Contiguous, [1], lapackint*) iwork,
	)
{
	assert(b.length!1 == a.length!1);
	assert(s.length == min(a.length!0, a.length!1));

	lapackint m = cast(lapackint) a.length!1;
	lapackint n = cast(lapackint) a.length!0;
	lapackint nrhs = cast(lapackint) b.length;
	lapackint lda = cast(lapackint) a._stride.max(1);
	lapackint ldb = cast(lapackint) b._stride.max(1);
	lapackint rank_ = void;
	lapackint lwork = cast(lapackint) work.length;
	lapackint info = void;

	lapack.gelsd_(m, n, nrhs, a.iterator, lda, b.iterator, ldb, s.iterator, rcond, rank_, work.iterator, lwork, iwork.iterator, info);

	assert(info >= 0);
	rank = rank_;
	return info;
}

/// `gesdd` work space query
size_t gesdd_wq(T)(
	char jobz,
	Slice!(Canonical, [2], T*) a,
	Slice!(Canonical, [2], T*) u,
	Slice!(Canonical, [2], T*) vt,
	)
{
	lapackint m = cast(lapackint) a.length!1;
	lapackint n = cast(lapackint) a.length!0;
	lapackint lda = cast(lapackint) a._stride.max(1);
	lapackint ldu = cast(lapackint) u._stride.max(1);
	lapackint ldvt = cast(lapackint) vt._stride.max(1);
	T work = void;
	lapackint lwork = -1;
	lapackint info = void;

	lapack.gesdd_(jobz, m, n, null, lda, null, null, ldu, null, ldvt, &work, lwork, null, info);

	assert(info == 0);
	return cast(size_t) work;
}

///
size_t gesdd(T)(
	char jobz,
	Slice!(Canonical, [2], T*) a,
	Slice!(Contiguous, [1], T*) s,
	Slice!(Canonical, [2], T*) u,
	Slice!(Canonical, [2], T*) vt,
	Slice!(Contiguous, [1], T*) work,
	Slice!(Contiguous, [1], lapackint*) iwork,
	)
{
	lapackint m = cast(lapackint) a.length!1;
	lapackint n = cast(lapackint) a.length!0;
	lapackint lda = cast(lapackint) a._stride.max(1);
	lapackint ldu = cast(lapackint) u._stride.max(1);
	lapackint ldvt = cast(lapackint) vt._stride.max(1);
	lapackint lwork = cast(lapackint) work.length;
	lapackint info = void;

	lapack.gesdd_(jobz, m, n, a.iterator, lda, s.iterator, u.iterator, ldu, vt.iterator, ldvt, work.iterator, lwork, iwork.iterator, info);

	assert(info >= 0);
	return info;
}

/// `gesvd` work space query
size_t gesvd_wq(T)(
	char jobu,
	char jobvt,
	Slice!(Canonical, [2], T*) a,
	Slice!(Canonical, [2], T*) u,
	Slice!(Canonical, [2], T*) vt,
	)
{
	lapackint m = cast(lapackint) a.length!1;
	lapackint n = cast(lapackint) a.length!0;
	lapackint lda = cast(lapackint) a._stride.max(1);
	lapackint ldu = cast(lapackint) u._stride.max(1);
	lapackint ldvt = cast(lapackint) vt._stride.max(1);
	T work = void;
	lapackint lwork = -1;
	lapackint info = void;

	lapack.gesvd_(jobu, jobvt, m, n, null, lda, null, null, ldu, null, ldvt, &work, lwork, info);

	assert(info == 0);
	return cast(size_t) work;
}

///
size_t gesvd(T)(
	char jobu,
	char jobvt,
	Slice!(Canonical, [2], T*) a,
	Slice!(Contiguous, [1], T*) s,
	Slice!(Canonical, [2], T*) u,
	Slice!(Canonical, [2], T*) vt,
	Slice!(Contiguous, [1], T*) work,
	)
{
	lapackint m = cast(lapackint) a.length!1;
	lapackint n = cast(lapackint) a.length!0;
	lapackint lda = cast(lapackint) a._stride.max(1);
	lapackint ldu = cast(lapackint) u._stride.max(1);
	lapackint ldvt = cast(lapackint) vt._stride.max(1);
	lapackint lwork = cast(lapackint) work.length;
	lapackint info = void;

	lapack.gesvd_(jobu, jobvt, m, n, a.iterator, lda, s.iterator, u.iterator, ldu, vt.iterator, ldvt, work.iterator, lwork, info);

	assert(info >= 0);
	return info;
}

///
size_t spev(T)(
	char jobz,
	Slice!(Contiguous, [1], StairsIterator!(T*)) ap,
	Slice!(Contiguous, [1], T*) w,
	Slice!(Canonical, [2], T*) z,
	Slice!(Contiguous, [1], T*) work,
	)
{
	assert(work.length == 3 * ap.length);
	assert(w.length == ap.length);

	char uplo = 'U';
	lapackint n = cast(lapackint) ap.length;
	lapackint ldz = cast(lapackint) z._stride.max(1);
	lapackint info = void;

	lapack.spev_(jobz, uplo, n, &ap[0][0], w.iterator, z.iterator, ldz, work.iterator, info);

	assert(info >= 0);
	return info;
}

///
size_t spev(T)(
	char jobz,
	Slice!(Contiguous, [1], RetroIterator!(MapIterator!(StairsIterator!(RetroIterator!(T*)), retro))) ap,
	Slice!(Contiguous, [1], T*) w,
	Slice!(Canonical, [2], T*) z,
	Slice!(Contiguous, [1], T*) work,
	)
{
	assert(work.length == 3 * ap.length);
	assert(w.length == ap.length);

	char uplo = 'L';
	lapackint n = cast(lapackint) ap.length;
	lapackint ldz = cast(lapackint) z._stride.max(1);
	lapackint info = void;

	lapack.spev_(jobz, uplo, n, &ap[0][0], w.iterator, z.iterator, ldz, work.iterator, info);

	assert(info >= 0);
	return info;
}

///
size_t sytrf(T)(
    Slice!(Canonical, [2], T*) a,
    Slice!(Contiguous, [1], lapackint*) ipiv,
    Slice!(Contiguous, [1], T*) work,
    Uplo uplo
    )
{
    char c_uplo = 'L';
    if(uplo == Uplo.Upper)
        c_uplo = 'U';
    lapackint info = void;
    lapackint n = cast(lapackint) a.length;
    lapackint lda = n;
    lapackint lwork = cast(lapackint) work.length;
    lapack.sytrf_(c_uplo, n, a.iterator, lda, ipiv.iterator, work.iterator, lwork, info);
    assert(info >= 0);
    return info;
}

///
size_t geqrf(T)(
    Slice!(Canonical, [2], T*) a,
    Slice!(Contiguous, [1], T*) tau,
    Slice!(Contiguous, [1], T*) work
    )
{
    lapackint m = cast(lapackint) a.length!0;
    lapackint n = cast(lapackint) a.length!1;
    lapackint lda = m;
    lapackint lwork = cast(lapackint) work.length;
    lapackint info = void;
    lapack.geqrf_(m, n, a.iterator, lda, tau.iterator, work.iterator, lwork, info);
    assert(info == 0);
    return info;
}

///
size_t orgqr(T)(
    Slice!(Canonical, [2], T*) a,
    Slice!(Contiguous, [1], T*) tau,
    Slice!(Contiguous, [1], T*) work
    )
{
    lapackint info = void;
    lapackint m = cast(lapackint) a.length!0;
    lapackint n = cast(lapackint) a.length!1;
    lapackint k = cast(lapackint) tau.length;
    lapackint lda = cast(lapackint) a.length!0;
    lapackint lwork = cast(lapackint) work.length;
    lapack.orgqr_(m, n, k, a.iterator, lda, tau.iterator, work.iterator, lwork, info);
    assert(info == 0);
    return info;
}

///
size_t potrf(T)(
    Slice!(Canonical, [2], T*) a,
    Uplo uplo
    )
{
    lapackint n = cast(lapackint) a.length;
    lapackint lda = cast(lapackint) a.length;
    lapackint info = void;
    char c_uplo = 'U';
    if(uplo == Uplo.Upper)
        c_uplo = 'L';
    lapack.potrf_(c_uplo, n, a.iterator, lda, info);
    assert(info >= 0);
    return info;
}

size_t getrs(T)(
    Slice!(Canonical, [2], T*) a,
    Slice!(Canonical, [2], T*) b,
    Slice!(Contiguous, [1], lapackint*) ipiv,
    char trans
    )
{
    assert(a.length!0 == a.length!1, "matrix must be squared");
    assert(ipiv.length == a.length, "size ipiv must be equally num rows a");
    assert(a.length == b.length!0, "num rows b must be equally num columns a");

    lapackint n = cast(lapackint) a.length;
    lapackint nrhs = cast(lapackint) b.length!1;
    lapackint lda = cast(lapackint) a._stride.max(1);
    lapackint ldb = cast(lapackint) b._stride.max(1);
    lapackint info = void;

    lapack.getrs_(trans, n, nrhs, a.iterator, lda, ipiv.iterator, b.iterator, ldb, info);

    assert(info == 0);
    return info;
}
