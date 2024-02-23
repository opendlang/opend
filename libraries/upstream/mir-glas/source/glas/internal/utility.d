/++
Copyright: Copyright © 2016-, Ilya Yaroshenko.
License: $(HTTP boost.org/LICENSE_1_0.txt, Boost License 1.0).
Authors: Ilya Yaroshenko
+/
module glas.internal.utility;

import std.traits: Unqual;
import std.meta: AliasSeq;
import glas.ndslice;

enum bool isComplex(C)
     = is(Unqual!C == creal)
    || is(Unqual!C == cdouble)
    || is(Unqual!C == cfloat);

enum bool isReal(C)
     = is(Unqual!C == real)
    || is(Unqual!C == double)
    || is(Unqual!C == float);

enum bool isImaginary(C)
     = is(Unqual!C == ireal)
    || is(Unqual!C == idouble)
    || is(Unqual!C == ifloat);


template realType(C)
{
    static if (isComplex!C)
        alias realType = typeof(Unqual!C.init.re);
    else
    static if (isImaginary!C)
        alias realType = typeof(Unqual!C.init.im);
    else
        alias realType = Unqual!C;
}

template imaginaryType(C)
{
    static if (isComplex!C)
        alias imaginaryType = typeof(Unqual!C.init.re * 1fi);
    else
    static if (isImaginary!C)
        alias imaginaryType = Unqual!C;
    else
        alias imaginaryType = typeof(Unqual!C.init * 1fi);
}

alias Iota(size_t j) = Iota!(0, j);

template Iota(size_t i, size_t j)
{
    static assert(i <= j, "Iota: i should be less than or equal to j");
    static if (i == j)
        alias Iota = AliasSeq!();
    else
        alias Iota = AliasSeq!(i, Iota!(i + 1, j));
}

template prefix(T)
{
    static if (is(T == float))
        enum prefix = "s";
    else
    static if (is(T == double))
        enum prefix = "d";
    else
    static if (is(T == cfloat))
        enum prefix = "c";
    else
    static if (is(T == cdouble))
        enum prefix = "z";
    else static assert(0);
}

template prefix2(T)
{
    static if (is(T == float))
        enum prefix2 = "s";
    else
    static if (is(T == double))
        enum prefix2 = "d";
    else
    static if (is(T == cfloat))
        enum prefix2 = "sc";
    else
    static if (is(T == cdouble))
        enum prefix2 = "dz";
    else static assert(0);
}

template prefix2r(T)
{
    static if (is(T == float))
        enum prefix2r = "s";
    else
    static if (is(T == double))
        enum prefix2r = "d";
    else
    static if (is(T == cfloat))
        enum prefix2r = "cs";
    else
    static if (is(T == cdouble))
        enum prefix2r = "zd";
    else static assert(0);
}

// string upper()(string str)
// {
//     auto ret = new char[str.length];
//     foreach(i, char c; str)
//         if ('a' <= c && c <= 'z')
//             ret[i] = cast(char)(c - 'a' + 'A');
//         else
//             ret[i] = c;
//     return cast(string) ret;
// }
