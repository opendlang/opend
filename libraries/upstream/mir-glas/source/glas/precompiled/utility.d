/++
Copyright: Copyright © 2016-, Ilya Yaroshenko.
License: $(HTTP boost.org/LICENSE_1_0.txt, Boost License 1.0).
Authors: Ilya Yaroshenko
+/
module glas.precompiled.utility;

import glas.ndslice;
import glas.fortran;
import ldc.attributes: weak;
import ldc.intrinsics: llvm_expect;
import mir.ndslice.slice: Structure;

extern(C) @system nothrow @nogc pragma(inline, false):


__gshared string[] _errors = [
    "undefinded error", // 0
    "unexpected flag", //1
    "constraint: asl.length!1 == bsl.length!0",//2
    "constraint: csl.length!0 == asl.length!0",//3
    "constraint: csl.length!1 == bsl.length!1",//4
    "constraint: abs(csl.stride!0) or abs(csl.stride!1) must be equal to 1",//5
    "constraint: asl.length!0 == asl.length!1",//6
    "constraint: abs(csl.stride!0) >= csl.length!0 || abs(csl.stride!1) >= csl.length!1",//7
];

string glas_error(int error_code)
{
    if (error_code < _errors.length)
        error_code = 0;
    return _errors[error_code];
}

int glas_validate_gemm_common(ref const Structure!2 as, ref const Structure!2 bs, ref const Structure!2 cs)
{
    if (llvm_expect(as.lengths[1] != bs.lengths[0], false))
        return 2;
    if (llvm_expect(cs.lengths[0] != as.lengths[0], false))
        return 3;
    if (llvm_expect(cs.lengths[1] != bs.lengths[1], false))
        return 4;
    auto s0 = cs.strides[0] >= 0 ? cs.strides[0] : -cs.strides[0];
    auto s1 = cs.strides[1] >= 0 ? cs.strides[1] : -cs.strides[1];
    if (llvm_expect(s0 != 1 && s1 != 1, false))        
        return 5;
    if (llvm_expect(s0 < cs.lengths[0] && s1 < cs.lengths[1], false))
        return 7;        
    return 0;
}

int glas_validate_gemm(Structure!2 as, Structure!2 bs, Structure!2 cs, ulong settings)
{
    if (llvm_expect(settings & ~(ConjA | ConjB), false))
        return 1;
    if (auto ret = glas_validate_gemm_common(as, bs, cs))
        return ret;
    return 0;
}

int glas_validate_symm(Structure!2 as, Structure!2 bs, Structure!2 cs, ulong settings)
{
    if (llvm_expect(settings & ~(ConjA | ConjB | Left | Right | Upper | Lower), false))
        return 1;
    if (llvm_expect(as.lengths[0] != as.lengths[1], false))
        return 6;
    if (auto ret = glas_validate_gemm_common(as, bs, cs))
        return ret;
    return 0;
}

/* -- LAPACK auxiliary routine (preliminary version) -- */
/* Univ. of Tennessee, Univ. of California Berkeley, NAG Ltd., */
/* Courant Institute, Argonne National Lab, and Rice University */
/* February 29, 1992 */
/* .. Scalar Arguments .. */
/* .. */
/* Purpose */
/* ======= */
/* XERBLA is an error handler for the LAPACK routines. */
/* It is called by an LAPACK routine if an input parameter has an */
/* invalid value. A message is printed and execution stops. */
/* Installers may consider modifying the STOP statement in order to */
/* call system-specific exception-handling facilities. */
/* Arguments */
/* ========= */
/* SRNAME (input) CHARACTER*6 */
/* The name of the routine which called XERBLA. */
/* INFO (input) INTEGER */
/* The position of the invalid parameter in the parameter list */
/* of the calling routine. */
@weak int xerbla_(in char* srname, ref FortranInt info)
{
    import core.stdc.stdio;
    static if (FortranInt.sizeof == 8)
        enum fmt = " ** On entry to %6s parameter number %2ld had an illegal value\n";
    else
        enum fmt = " ** On entry to %6s parameter number %2d had an illegal value\n";
    printf(fmt, srname, info);
    return 0;
}

version(Posix)
@weak extern (C) void _d_dso_registry() {}
