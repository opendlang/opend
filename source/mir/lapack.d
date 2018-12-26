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

@trusted pure nothrow @nogc:

/// `getri` work space query.
size_t getri_wq(T)(Slice!(T*, 2, Canonical) a)
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

unittest
{
	alias s = getri_wq!float;
	alias d = getri_wq!double;
}

///
size_t getri(T)(
	Slice!(T*, 2, Canonical) a,
	Slice!(lapackint*) ipiv,
	Slice!(T*) work,
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

unittest
{
	alias s = getri!float;
	alias d = getri!double;
}

///
size_t getrf(T)(
	Slice!(T*, 2, Canonical) a,
	Slice!(lapackint*) ipiv,
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

unittest
{
	alias s = getrf!float;
	alias d = getrf!double;
}

///
template sptrf(T)
{
	/// `sptrf` for upper triangular input.
	size_t sptrf(
		Slice!(StairsIterator!(T*, "+")) ap,
		Slice!(lapackint*) ipiv,
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
	size_t sptrf(
		Slice!(StairsIterator!(T*, "-")) ap,
		Slice!(lapackint*) ipiv,
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

unittest
{
	alias s = gelsd_wq!float;
	alias d = gelsd_wq!double;
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

unittest
{
	alias s = gelsd!float;
	alias d = gelsd!double;
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
	T work = void;
	lapackint lwork = -1;
	lapackint info = void;

	lapack.gesdd_(jobz, m, n, null, lda, null, null, ldu, null, ldvt, &work, lwork, null, info);

	assert(info == 0);
	return cast(size_t) work;
}

unittest
{
	alias s = gesdd_wq!float;
	alias d = gesdd_wq!double;
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

unittest
{
	alias s = gesdd!float;
	alias d = gesdd!double;
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
	T work = void;
	lapackint lwork = -1;
	lapackint info = void;

	lapack.gesvd_(jobu, jobvt, m, n, null, lda, null, null, ldu, null, ldvt, &work, lwork, info);

	assert(info == 0);
	return cast(size_t) work;
}

unittest
{
	alias s = gesvd_wq!float;
	alias d = gesvd_wq!double;
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

unittest
{
	alias s = gesvd!float;
	alias d = gesvd!double;
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
	size_t spev(
		char jobz,
		Slice!(StairsIterator!(T*, "-")) ap,
		Slice!(T*) w,
		Slice!(T*, 2, Canonical) z,
		Slice!(T*) work,
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

unittest
{
	alias s = sytrf!float;
	alias d = sytrf!double;
}

///
size_t geqrf(T)(
    Slice!(T*, 2, Canonical) a,
    Slice!(T*) tau,
    Slice!(T*) work
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

unittest
{
	alias s = geqrf!float;
	alias d = geqrf!double;
}

///
size_t getrs(T)(
    char trans,
    Slice!(T*, 2, Canonical) a,
    Slice!(T*, 2, Canonical) b,
    Slice!(lapackint*) ipiv,
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

unittest
{
	alias s = getrs!float;
	alias d = getrs!double;
}

///
size_t potrs(T)(
    char uplo,
    Slice!(T*, 2, Canonical) a,
    Slice!(T*, 2, Canonical) b,
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

unittest
{
	alias s = potrs!float;
	alias d = potrs!double;
}

///
size_t sytrs2(T)(
    Slice!(T*, 2, Canonical) a,
    Slice!(T*, 2, Canonical) b,
    Slice!(lapackint*) ipiv,
    Slice!(T*) work,
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

unittest
{
	alias s = sytrs2!float;
	alias d = sytrs2!double;
}

///
size_t geqrs(T)(
    Slice!(T*, 2, Canonical) a,
    Slice!(T*, 2, Canonical) b,
    Slice!(T*) tau,
    Slice!(T*) work
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

version(none) unittest
{
	alias s = geqrs!float;
	alias d = geqrs!double;
}

///
size_t sysv_rook_wk(T)(
	char uplo,
	Slice!(T*, 2, Canonical) a,
	Slice!(T*, 2, Canonical) b,
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

unittest
{
	alias s = sysv_rook_wk!float;
	alias d = sysv_rook_wk!double;
}

///
size_t sysv_rook(T)(
	char uplo,
	Slice!(T*, 2, Canonical) a,
	Slice!(lapackint*) ipiv,
	Slice!(T*, 2, Canonical) b,
	Slice!(T*) work,
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

unittest
{
	alias s = sysv_rook!float;
	alias d = sysv_rook!double;
}

///
size_t syev_wk(T)(
	char jobz,
	char uplo,
	Slice!(T*, 2, Canonical) a,
	Slice!(T*) w,
	) 
{
	assert(a.length!0 == a.length!1, "sysv: a must be a square matrix.");
	assert(w.length == a.length);

	lapackint n = cast(lapackint) a.length;
	lapackint lda = cast(lapackint) a._stride.max(1);
	T work = void;
	lapackint lwork = -1;
	lapackint info = void;

	lapack.syev_(jobz, uplo, n, a._iterator, lda, w._iterator, &work, lwork, info);

	return cast(size_t) work;
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
{
	assert(a.length!0 == a.length!1, "sysv: a must be a square matrix.");
	assert(w.length == a.length);

	lapackint n = cast(lapackint) a.length;
	lapackint lda = cast(lapackint) a._stride.max(1);
	lapackint lwork = cast(lapackint) work.length;
	lapackint info = void;

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
{
	assert(a.length!0 == a.length!1, "sysv: a must be a square matrix.");
	assert(w.length == a.length);

	lapackint n = cast(lapackint) a.length;
	lapackint lda = cast(lapackint) a._stride.max(1);
	T work = void;
	lapackint lwork = -1;
	lapackint info = void;

	lapack.syev_2stage_(jobz, uplo, n, a._iterator, lda, w._iterator, &work, lwork, info);

	return cast(size_t) work;
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
{
	assert(a.length!0 == a.length!1, "sysv: a must be a square matrix.");
	assert(w.length == a.length);

	lapackint n = cast(lapackint) a.length;
	lapackint lda = cast(lapackint) a._stride.max(1);
	lapackint lwork = cast(lapackint) work.length;
	lapackint info = void;

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
{
    assert(a.length!0 == a.length!1, "potrf: a must be a square matrix.");
    
    lapackint n = cast(lapackint) a.length;
    lapackint lda = cast(lapackint) a._stride.max(1);
    lapackint info = void;
    
    lapack.potrf_(uplo, n, a.iterator, lda, info);
    
    assert(info >= 0);
    
    return info;
}

unittest
{
	alias s = potrf!float;
	alias d = potrf!double;
}

///
size_t pptrf(T)(
	char uplo,
	Slice!(T*, 2, Canonical) ap,
	)
{
	lapackint n = cast(lapackint) ap.length;
	lapackint info = void;
	
	lapack.pptrf_(uplo, n, ap.iterator, info);
	
	assert(info >= 0);
	
	return info;
}

unittest
{
	alias s = pptrf!float;
	alias d = pptrf!double;
	alias c = pptrf!cfloat;
	alias z = pptrf!cdouble;
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
	{
		assert(ipiv.length == ap.length);
		assert(work.length == ap.length);

		lapackint n = cast(lapackint) ap.length;
		lapackint info = void;

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
	{
		assert(ipiv.length == ap.length);
		assert(work.length == ap.length);

		lapackint n = cast(lapackint) ap.length;
		lapackint info = void;

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
}

///
size_t potri(T)(
    char uplo,
	Slice!(T*, 2, Canonical) a,
	)
{
	assert(a.length!0 == a.length!1, "potri: a must be a square matrix.");

	lapackint n = cast(lapackint) a.length;
	lapackint lda = cast(lapackint) a._stride.max(1);
	lapackint info = void;

	lapack.potri_(uplo, n, a.iterator, lda, info);

	assert(info >= 0);
	return info;
}

unittest
{
	alias s = potri!float;
	alias d = potri!double;
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
		lapackint info = void;

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
		lapackint info = void;

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
}

///
size_t trtri(T)(
    char uplo,
    char diag,
	Slice!(T*, 2, Canonical) a,
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

unittest
{
	alias s = trtri!float;
	alias d = trtri!double;
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
		lapackint info = void;

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
		lapackint info = void;

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
    lapackint info = void;

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
    lapackint info = void;

    lapack.unmqr_(side, trans, m, n, k, a.iterator, lda, tau.iterator, c.iterator, ldc, work.iterator, lwork, info);

    ///if info == 0: successful exit.
    ///if info < 0: if info == -i, the i-th argument had an illegal value.
    assert(info >= 0);
    return info;
}

unittest
{
    alias s = unmqr!cfloat;
    alias d = unmqr!cdouble;
}

///
size_t orgqr(T)(
    Slice!(T*, 2, Canonical) a,
    Slice!(T*) tau,
    Slice!(T*) work,
    )
in
{
    assert(a.length!1 >= 0); //n>=0
    assert(a.length!0 >= a.length!1); //m>=n
    assert(tau.length >= 0); //k>=0
    assert(a.length!1 >= tau.length); //n>=k
    assert(work.length >= a.length!1); //lwork>=n
}
do
{
    lapackint m = cast(lapackint) a.length!0;
    lapackint n = cast(lapackint) a.length!1;
    lapackint k = cast(lapackint) tau.length;
    lapackint lda = cast(lapackint) a._stride.max(1);
    lapackint lwork = cast(lapackint) work.length;
    lapackint info = void;

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
    assert(a.length!1 >= 0); //n>=0
    assert(a.length!0 >= a.length!1); //m>=n
    assert(tau.length >= 0); //k>=0
    assert(a.length!1 >= tau.length); //n>=k
    assert(work.length >= a.length!1); //lwork>=n
}
do
{
    lapackint m = cast(lapackint) a.length!0;
    lapackint n = cast(lapackint) a.length!1;
    lapackint k = cast(lapackint) tau.length;
    lapackint lda = cast(lapackint) a._stride.max(1);
    lapackint lwork = cast(lapackint) work.length;
    lapackint info = void;

    lapack.ungqr_(m, n, k, a.iterator, lda, tau.iterator, work.iterator, lwork, info);

    ///if info == 0: successful exit.
    ///if info < 0: if info == -i, the i-th argument had an illegal value.
    assert(info >= 0);
    return info;
}

unittest
{
    alias s = ungqr!cfloat;
    alias d = ungqr!cdouble;
}
