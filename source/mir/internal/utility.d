///
module mir.internal.utility;

private alias AliasSeq(T...) = T;

///
alias Iota(size_t j) = Iota!(0, j);

///
template Iota(size_t i, size_t j)
{
    static assert(i <= j, "Iota: i should be less than or equal to j");
    static if (i == j)
        alias Iota = AliasSeq!();
    else
        alias Iota = AliasSeq!(i, Iota!(i + 1, j));
}

///
template realType(C)
    if (__traits(isFloating, C) || isComplex!C)
{
    import std.traits: Unqual;
    static if (isComplex!C)
        alias realType = typeof(Unqual!C.init.re);
    else
        alias realType = Unqual!C;
}

///
template isComplex(C)
{
    import std.traits: Unqual;
    alias U = Unqual!C;
    enum isComplex = is(C == cdouble) || is(C == cfloat) || is(C == creal);
}

///
template isFloatingPoint(C)
{
    import std.traits: Unqual;
    alias U = Unqual!C;
    enum isFloatingPoint = is(C == double) || is(C == float) || is(C == real);
}
