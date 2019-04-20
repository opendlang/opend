# mir-lapack
NDSLICE wrapper for LAPACK

mir-lapack assumes that matrixes are passed in the transposed form.
Each (contiguous) row in a mir's matrix should store a (contiguous) column of a Fortran matrix.

## Required system libraries

See [wiki: Link with CBLAS & LAPACK](https://github.com/libmir/mir-lapack/wiki/Link-with-CBLAS-&-LAPACK).

## Wrapped API

 - gelsd
 - geqrf
 - geqrs
 - gesdd
 - gesv
 - gesvd
 - getrf
 - getri
 - getrs
 - ormqr
 - potrf
 - potri
 - potrs
 - pptrf
 - pptri
 - spev
 - sptrf
 - sptri
 - syev
 - syev_2stage
 - sysv_rook
 - sytrf
 - sytrs2
 - tptri
 - trtri
 - unmqr

---------------

This work has been sponsored by [Symmetry Investments](http://symmetryinvestments.com) and [Kaleidic Associates](https://github.com/kaleidicassociates).
 
