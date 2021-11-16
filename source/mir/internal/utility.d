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
    static if (is(C == struct) || is(C == enum))
    {
        static if (hasField!(C, "re") && hasField!(C, "im") && C.init.tupleof.length == 2)
            enum isComplex = isFloatingPoint!(typeof(C.init.tupleof[0]));
        else
        static if (__traits(getAliasThis, C).length == 1)
            enum isComplex = .isComplex!(typeof(__traits(getMember, C, __traits(getAliasThis, C)[0]))); 
        else
            enum isComplex = false;
    }
    else
    {
        // for backward compatability with cfloat, cdouble and creal
        enum isComplex = __traits(isFloating, C) && !isFloatingPoint!C && !is(C : __vector(F[N]), F, size_t N);
    }
}

///
version(mir_core_test)
unittest
{
    static assert(!isComplex!double);
    import mir.complex: Complex;
    static assert(isComplex!(Complex!double));
    import std.complex: PhobosComplex = Complex;
    static assert(isComplex!(PhobosComplex!double));

    static struct C
    {
        Complex!double value;
        alias value this;
    }

    static assert(isComplex!C);
}

///
version(LDC)
version(mir_core_test)
unittest
{
    static assert(!isComplex!(__vector(double[2])));
}

///
template isComplexOf(C, F)
    if (isFloatingPoint!F)
{
    static if (isComplex!C)
        enum isComplexOf = is(typeof(C.init.re) == F);
    else
        enum isComplexOf = false;
}

///
template isFloatingPoint(C)
{
    import std.traits: Unqual;
    alias U = Unqual!C;
    enum isFloatingPoint = is(U == double) || is(U == float) || is(U == real);
}

// copy to reduce imports
enum bool hasField(T, string member) = __traits(compiles, (ref T aggregate) { return __traits(getMember, aggregate, member).offsetof; });
