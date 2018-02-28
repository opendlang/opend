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

//enum for errors.
private enum Error {
    squareM = "The matrix must be square"
};

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
    char uplo
    )
{
    assert(a.length!0 == a.length!1, Error.squareM);
    lapackint info = void;
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

///
size_t geqrf(T)(
    Slice!(Canonical, [2], T*) a,
    Slice!(Contiguous, [1], T*) tau,
    Slice!(Contiguous, [1], T*) work
    )
{
    lapackint m = cast(lapackint) a.length!0;
    lapackint n = cast(lapackint) a.length!1;
    lapackint lda = cast(lapackint) a._stride.max(1);
    lapackint lwork = cast(lapackint) work.length;
    lapackint info = void;

    lapack.geqrf_(m, n, a.iterator, lda, tau.iterator, work.iterator, lwork, info);

    ///if info == 0: successful exit;
    ///if info < 0: if info == -i, the i-th argument had an illegal value.
    assert(info >= 0);
    return info;
}

///
size_t getrs(T)(
    Slice!(Canonical, [2], T*) a,
    Slice!(Canonical, [2], T*) b,
    Slice!(Contiguous, [1], lapackint*) ipiv,
    char trans
    )
{
    assert(a.length!0 == a.length!1, Error.squareM);
    assert(ipiv.length == a.length, "size of ipiv must be equal to the number of rows a");

    lapackint n = cast(lapackint) a.length;
    lapackint nrhs = cast(lapackint) b.length;
    lapackint lda = cast(lapackint) a._stride.max(1);
    lapackint ldb = cast(lapackint) b._stride.max(1);
    lapackint info = void;

    lapack.getrs_(trans, n, nrhs, a.iterator, lda, ipiv.iterator, b.iterator, ldb, info);

    ///if info == 0: successful exit.
    ///if info < 0: if info == -i, the i-th argument had an illegal value.
    assert(info >= 0);
    return info;
}

///
size_t potrs(T)(
    Slice!(Canonical, [2], T*) a,
    Slice!(Canonical, [2], T*) b,
    char uplo
    )
{
    assert(a.length!0 == a.length!1, Error.squareM);

    lapackint n = cast(lapackint) a.length;
    lapackint nrhs = cast(lapackint) b.length;
    lapackint lda = cast(lapackint) a._stride.max(1);
    lapackint ldb = cast(lapackint) b._stride.max(1);
    lapackint info = void;

    lapack.potrs_(uplo, n, nrhs, a.iterator, lda, b.iterator, ldb, info);

    ///if info == 0: successful exit.
    ///if info < 0: if info == -i, the i-th argument had an illegal value.
    assert(info >= 0);
    return info;
}

///
size_t sytrs2(T)(
    Slice!(Canonical, [2], T*) a,
    Slice!(Canonical, [2], T*) b,
    Slice!(Contiguous, [1], lapackint*) ipiv,
    Slice!(Contiguous, [1], T*) work,
    char uplo,
    )
{
    assert(a.length!0 == a.length!1, Error.squareM);

    lapackint n = cast(lapackint) a.length;
    lapackint nrhs = cast(lapackint) b.length;
    lapackint lda = cast(lapackint) a._stride.max(1);
    lapackint ldb = cast(lapackint) b._stride.max(1);
    lapackint info = void;

    lapack.sytrs2_(uplo, n, nrhs, a.iterator, lda, ipiv.iterator, b.iterator, ldb, work.iterator, info);

    ///if info == 0: successful exit.
    ///if info < 0: if info == -i, the i-th argument had an illegal value.
    assert(info >= 0);
    return info;
}

///
size_t geqrs(T)(
    Slice!(Canonical, [2], T*) a,
    Slice!(Canonical, [2], T*) b,
    Slice!(Contiguous, [1], T*) tau,
    Slice!(Contiguous, [1], T*) work
    )
{
    lapackint m = cast(lapackint) a.length!0;
    lapackint n = cast(lapackint) a.length!1;
    lapackint nrhs = cast(lapackint) b.length;
    lapackint lda = cast(lapackint) a._stride.max(1);
    lapackint ldb = cast(lapackint) b._stride.max(1);
    lapackint lwork = cast(lapackint) work.length;
    lapackint info = void;

    lapack.geqrs_(m, n, nrhs, a.iterator, lda, tau.iterator, b.iterator, ldb, work.iterator, lwork, info);

    ///if info == 0: successful exit.
    ///if info < 0: if info == -i, the i-th argument had an illegal value.
    assert(info >= 0);
    return info;
}
  
size_t sysv_rook_wk(T)(
	char uplo,
	Slice!(Canonical, [2], T*) a,
	Slice!(Canonical, [2], T*) b,
	) 
{
	assert(a.length!0 == a.length!1, "sysv: a must be a square matrix.");
	assert(b.length!1 == a.length);

	lapackint n = cast(lapackint) a.length;
	lapackint nrhs = cast(lapackint) b.length;
	lapackint lda = cast(lapackint) a._stride.max(1);
	lapackint ldb = cast(lapackint) b._stride.max(1);
	T work = void;
	lapackint lwork = -1;
	lapackint info = void;

	lapack.sysv_rook_(uplo, n, nrhs, a._iterator, lda, null, b._iterator, ldb, &work, lwork, info);

	return cast(size_t) work;
}

///
size_t sysv_rook(T)(
	char uplo,
	Slice!(Canonical, [2], T*) a,
	Slice!(Contiguous, [1], lapackint*) ipiv,
	Slice!(Canonical, [2], T*) b,
	Slice!(Contiguous, [1], T*) work,
	)
{
	assert(a.length!0 == a.length!1, "sysv: a must be a square matrix.");
	assert(ipiv.length == a.length);
	assert(b.length!1 == a.length);

	lapackint n = cast(lapackint) a.length;
	lapackint nrhs = cast(lapackint) b.length;
	lapackint lda = cast(lapackint) a._stride.max(1);
	lapackint ldb = cast(lapackint) b._stride.max(1);
	lapackint lwork = cast(lapackint) work.length;
	lapackint info = void;

	lapack.sysv_rook_(uplo, n, nrhs, a._iterator, lda, ipiv._iterator, b._iterator, ldb, work._iterator, lwork, info);

	assert(info >= 0);
	return info;
}


size_t potrf(T)(
       Slice!(Canonical, [2], T*) a,
       char uplo
       )
{
    assert(a.length!0 == a.length!1, "potrf: a must be a square matrix.");
    
    lapackint n = cast(lapackint) a.length;
    lapackint lda = cast(lapackint) a._stride.max(1);
    lapackint info = void;
    
    lapack.potrf_(uplo, n, a.iterator, lda, info);
    
    assert(info >= 0);
    
    return info;
}

size_t pptrf(T)(
       Slice!(Contiguous, [1], StairsIterator!(T*)) ap
       )
{
    lapackint n = cast(lapackint) ap.length;
    lapackint info = void;
    
    lapack.pptrf_('U', n, ap.iterator, info);
    
    assert(info >= 0);
    
    return info;
}

size_t pptrf(T)(
       Slice!(Contiguous, [1], RetroIterator!(MapIterator!(StairsIterator!(RetroIterator!(T*)), retro))) ap
       )
{
    lapackint n = cast(lapackint) ap.length;
    lapackint info = void;
    
    lapack.pptrf_('L', n, ap.iterator, info);
    
    assert(info >= 0);
    
    return info;
}

/// `sptri` for upper triangular input.
size_t sptri(T)(
	Slice!(Contiguous, [1], StairsIterator!(T*)) ap,
	Slice!(Contiguous, [1], lapackint*) ipiv,
    Slice!(Contiguous, [1], T*) work
	)
{
	assert(ipiv.length == ap.length);
    assert(work.length == ap.length);

	lapackint n = cast(lapackint) ap.length;
	lapackint info = void;

	lapack.sptri_('U', n, &ap[0][0], ipiv.iterator, info, work);

	assert(info >= 0);
	return info;
}

/// `sptri` for lower triangular input.
size_t sptri(T)(
	Slice!(Contiguous, [1], RetroIterator!(MapIterator!(StairsIterator!(RetroIterator!(T*)), retro))) ap,
	Slice!(Contiguous, [1], lapackint*) ipiv,
    Slice!(Contiguous, [1], T*) work
	)
{
	assert(ipiv.length == ap.length);
    assert(work.length == ap.length);

	lapackint n = cast(lapackint) ap.length;
	lapackint info = void;

	lapack.sptri_('L', n, &ap[0][0], ipiv.iterator, info, work);

	assert(info >= 0);
	return info;
}

///
size_t sptri(T)(
	Slice!(Canonical, [2], T*) a,
    char uplo = 'U',
	)
{
	assert(a.length!0 == a.length!1, "trtri: a must be a square matrix.");

	lapackint n = cast(lapackint) a.length;
	lapackint lda = cast(lapackint) a._stride.max(1);
	lapackint info = void;

	lapack.potri_(uplo, diag, n, a.iterator, lda, info);

	assert(info >= 0);
	return info;
}

///
size_t potri(T)(
	Slice!(Canonical, [2], T*) a,
    char uplo = 'U',
	)
{
	assert(a.length!0 == a.length!1, "trtri: a must be a square matrix.");

	lapackint n = cast(lapackint) a.length;
	lapackint lda = cast(lapackint) a._stride.max(1);
	lapackint info = void;

	lapack.potri_(uplo, diag, n, a.iterator, lda, info);

	assert(info >= 0);
	return info;
}

/// `pptri` for upper triangular input.
size_t pptri(T)(
	Slice!(Contiguous, [1], StairsIterator!(T*)) ap
	)
{
	lapackint n = cast(lapackint) ap.length;
	lapackint info = void;

	lapack.pptri_('U', n, &ap[0][0], info);

	assert(info >= 0);
	return info;
}

/// `pptri` for lower triangular input.
size_t pptri(T)(
	Slice!(Contiguous, [1], RetroIterator!(MapIterator!(StairsIterator!(RetroIterator!(T*)), retro))) ap
	)
{
	lapackint n = cast(lapackint) ap.length;
	lapackint info = void;

	lapack.pptri_('L', n, &ap[0][0], info);

	assert(info >= 0);
	return info;
}

///
size_t trtri(T)(
	Slice!(Canonical, [2], T*) a,
    char uplo = 'U',
    char diag = 'N'
	)
{
	assert(a.length!0 == a.length!1, "trtri: a must be a square matrix.");

	lapackint n = cast(lapackint) a.length;
	lapackint lda = cast(lapackint) a._stride.max(1);
	lapackint info = void;

	lapack.trtri_(uplo, diag, n, a.iterator, lda, info);

	assert(info >= 0);
	return info;
}

/// `tptri` for upper triangular input.
size_t tptri(T)(
	Slice!(Contiguous, [1], StairsIterator!(T*)) ap,
    char diag = 'N'
	)
{
	lapackint n = cast(lapackint) ap.length;
	lapackint info = void;

	lapack.tptri_('U', diag, n, &ap[0][0], info);

	assert(info >= 0);
	return info;
}

/// `tptri` for lower triangular input.
size_t tptri(T)(
	Slice!(Contiguous, [1], RetroIterator!(MapIterator!(StairsIterator!(RetroIterator!(T*)), retro))) ap,
    char diag = 'N'
	)
{
	lapackint n = cast(lapackint) ap.length;
	lapackint info = void;

	lapack.tptri_('L', diag, n, &ap[0][0], info);

	assert(info >= 0);
	return info;

}

///
size_t ormqr(T)(
    Slice!(Canonical, [2], T*) a,
    Slice!(Contiguous, [1], T*) tau,
    Slice!(Canonical, [2], T*) c,
    Slice!(Contiguous, [1], T*) work,
    char side,
    char trans
    )
{
    lapackint m = cast(lapackint) c.length!1;
    lapackint n = cast(lapackint) c.length!0;
    lapackint k = cast(lapackint) tau.length;
    lapackint lda = cast(lapackint) a._stride.max(1);
    lapackint ldc = cast(lapackint) c._stride.max(1);
    lapackint lwork = cast(lapackint) work.length;
    lapackint info = void;

    lapack.ormqr_(side, trans, m, n, k, a.iterator, lda, tau.iterator, c.iterator, ldc, work.iterator, lwork, info);

    ///if info == 0: successful exit.
    ///if info < 0: if info == -i, the i-th argument had an illegal value.
    assert(info >= 0);
    return info;
}

///
size_t unmqr(T)(
    Slice!(Canonical, [2], T*) a,
    Slice!(Contiguous, [1], T*) tau,
    Slice!(Canonical, [2], T*) c,
    Slice!(Contiguous, [1], T*) work,
    char side,
    char trans
    )
{
    lapackint m = cast(lapackint) c.length!1;
    lapackint n = cast(lapackint) c.length!0;
    lapackint k = cast(lapackint) tau.length;
    lapackint lda = cast(lapackint) a._stride.max(1);
    lapackint ldc = cast(lapackint) c._stride.max(1);
    lapackint lwork = cast(lapackint) work.length;
    lapackint info = void;

    lapack.unmqr_(side, trans, m, n, k, a.iterator, lda, tau.iterator, c.iterator, ldc, work.iterator, lwork, info);

    ///if info == 0: successful exit.
    ///if info < 0: if info == -i, the i-th argument had an illegal value.
    assert(info >= 0);
    return info;
}
