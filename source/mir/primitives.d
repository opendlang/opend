/++
Templates used to check primitives and 
range primitives for arrays with multi-dimensional like API support.

Note:
UTF strings behaves like common arrays in Mir.
`std.uni.byCodePoint` can be used to create a range of characters.

License:   $(HTTP boost.org/LICENSE_1_0.txt, Boost License 1.0).
Copyright: Copyright © 2017-, Ilya Yaroshenko
Authors:   Ilya Yaroshenko
+/
module mir.primitives;

import mir.internal.utility;
import mir.math.common: optmath;
import std.traits;

@optmath:

/++
Returns: `true` if `R` has a `length` member that returns an
integral type implicitly convertible to `size_t`.

`R` does not have to be a range.
+/
enum bool hasLength(R) = is(typeof(
(R r, inout int = 0)
{
    size_t l = r.length;
}));

///
@safe version(mir_test) unittest
{
    static assert(hasLength!(char[]));
    static assert(hasLength!(int[]));
    static assert(hasLength!(inout(int)[]));

    struct B { size_t length() { return 0; } }
    struct C { @property size_t length() { return 0; } }
    static assert(hasLength!(B));
    static assert(hasLength!(C));
}

/++
Returns: `true` if `R` has a `shape` member that returns an static array type of size_t[N].
+/
enum bool hasShape(R) = is(typeof(
(R r, inout int = 0)
{
    auto l = r.shape;
    alias F = typeof(l);
    import std.traits;
    static assert(isStaticArray!F);
    static assert(is(ForeachType!F == size_t));
}));

///
@safe version(mir_test) unittest
{
    static assert(hasLength!(char[]));
    static assert(hasLength!(int[]));
    static assert(hasLength!(inout(int)[]));

    struct B { size_t length() { return 0; } }
    struct C { @property size_t length() { return 0; } }
    static assert(hasLength!(B));
    static assert(hasLength!(C));
}

///
auto shape(Range)(scope const auto ref Range range) @property
    if (hasLength!Range || hasShape!Range)
{
    static if (__traits(hasMember, Range, "shape"))
    {
        return range.shape;
    }
    else
    {
        size_t[1] ret;
        ret[0] = range.length;
        return ret;
    }
}

///
version(mir_test) unittest
{
    static assert([2, 2, 2].shape == [3]);
}

///
template DimensionCount(T)
{
    import mir.ndslice.slice: Slice, SliceKind;
    /// Extracts dimension count from a $(LREF Slice). Alias for $(LREF isSlice).
    static if(is(T : Slice!(Iterator, N, kind), Iterator, size_t N, SliceKind kind))
      enum size_t DimensionCount = N;
    else
    static if (hasShape!T)
        enum size_t DimensionCount = typeof(T.init.shape).length;
    else
        enum size_t DimensionCount = 1;
}

package(mir) bool anyEmptyShape(size_t N)(scope const auto ref size_t[N] shape) @property
{
    foreach (i; Iota!N)
        if (shape[i] == 0)
            return true;
    return false;
}

///
bool anyEmpty(Range)(Range range) @property
    if (hasShape!Range || __traits(hasMember, Range, "anyEmpty"))
{
    static if (__traits(hasMember, Range, "anyEmpty"))
    {
        return range.anyEmpty;
    }
    else
    static if (__traits(hasMember, Range, "shape"))
    {
        return anyEmptyShape(range.shape);
    }
    else
    {
        return range.empty;
    }
}

///
size_t elementCount(Range)(Range range) @property
    if (hasShape!Range || __traits(hasMember, Range, "elementCount"))
{
    static if (__traits(hasMember, Range, "elementCount"))
    {
        return range;
    }
    else
    {
        auto sh = range.shape;
        size_t ret = sh[0];
        foreach(i; Iota!(1, sh.length))
        {
            ret *= sh[i];
        }
        return ret;
    }
}

deprecated("use elementCount instead")
alias elementsCount = elementCount;


/++
Returns the element type of a struct with `.DeepElement` inner alias or a type of common array.
Returns `ForeachType` if struct does not have `.DeepElement` member.
+/
template DeepElementType(S)
    if (is(S == struct) || is(S == class) || is(S == interface))
{
    static if (__traits(hasMember, S, "DeepElement"))
        alias DeepElementType = S.DeepElement;
    else
        alias DeepElementType = ForeachType!S;
}

/// ditto
alias DeepElementType(S : T[], T) = T;

/+ ARRAY PRIMITIVES +/
pragma(inline, true):

///
bool empty(size_t dim = 0, T)(in T[] ar)
    if (!dim)
{
    return !ar.length;
}

///
version(mir_test)
unittest
{
   assert((int[]).init.empty);
   assert(![1].empty!0); // Slice-like API
}

///
ref front(size_t dim = 0, T)(T[] ar)
    if (!dim && !is(Unqual!T[] == void[]))
{
    assert(ar.length, "Accessing front of an empty array.");
    return ar[0];
}

///
version(mir_test)
unittest
{
   assert(*&[3, 4].front == 3); // access be ref
   assert([3, 4].front!0 == 3); // Slice-like API
}


///
ref back(size_t dim = 0, T)(T[] ar)
    if (!dim && !is(Unqual!T[] == void[]))
{
    assert(ar.length, "Accessing back of an empty array.");
    return ar[$ - 1];
}

///
version(mir_test)
unittest
{
   assert(*&[3, 4].back == 4); // access be ref
   assert([3, 4].back!0 == 4); // Slice-like API
}

///
void popFront(size_t dim = 0, T)(ref T[] ar)
    if (!dim && !is(Unqual!T[] == void[]))
{
    assert(ar.length, "Evaluating popFront() on an empty array.");
    ar = ar[1 .. $];
}

///
version(mir_test)
unittest
{
    auto ar = [3, 4];
    ar.popFront;
    assert(ar == [4]);
    ar.popFront!0;  // Slice-like API
    assert(ar == []);
}

///
void popBack(size_t dim = 0, T)(ref T[] ar)
    if (!dim && !is(Unqual!T[] == void[]))
{
    assert(ar.length, "Evaluating popBack() on an empty array.");
    ar = ar[0 .. $ - 1];
}

///
version(mir_test)
unittest
{
    auto ar = [3, 4];
    ar.popBack;
    assert(ar == [3]);
    ar.popBack!0;  // Slice-like API
    assert(ar == []);
}

///
size_t popFrontN(size_t dim = 0, T)(ref T[] ar, size_t n)
    if (!dim && !is(Unqual!T[] == void[]))
{
    n = ar.length < n ? ar.length : n;
    ar = ar[n .. $];
    return n;
}

///
version(mir_test)
unittest
{
    auto ar = [3, 4];
    ar.popFrontN(1);
    assert(ar == [4]);
    ar.popFrontN!0(10);  // Slice-like API
    assert(ar == []);
}

///
size_t popBackN(size_t dim = 0, T)(ref T[] ar, size_t n)
    if (!dim && !is(Unqual!T[] == void[]))
{
    n = ar.length < n ? ar.length : n;
    ar = ar[0 .. $ - n];
    return n;
}

///
version(mir_test)
unittest
{
    auto ar = [3, 4];
    ar.popBackN(1);
    assert(ar == [3]);
    ar.popBackN!0(10);  // Slice-like API
    assert(ar == []);
}

///
void popFrontExactly(size_t dim = 0, T)(ref T[] ar, size_t n)
    if (!dim && !is(Unqual!T[] == void[]))
{
    assert(ar.length >= n, "Evaluating *.popFrontExactly(n) on an array with length less then n.");
    ar = ar[n .. $];
}

///
version(mir_test)
unittest
{
    auto ar = [3, 4, 5];
    ar.popFrontExactly(2);
    assert(ar == [5]);
    ar.popFrontExactly!0(1);  // Slice-like API
    assert(ar == []);
}

///
void popBackExactly(size_t dim = 0, T)(ref T[] ar, size_t n)
    if (!dim && !is(Unqual!T[] == void[]))
{
    assert(ar.length >= n, "Evaluating *.popBackExactly(n) on an array with length less then n.");
    ar = ar[0 .. $ - n];
}

///
version(mir_test)
unittest
{
    auto ar = [3, 4, 5];
    ar.popBackExactly(2);
    assert(ar == [3]);
    ar.popBackExactly!0(1);  // Slice-like API
    assert(ar == []);
}

///
size_t length(size_t d : 0, T)(in T[] array)
    if (d == 0)
{
    return array.length;
}

///
version(mir_test)
unittest
{
    assert([1, 2].length!0 == 2);
    assert([1, 2].elementCount == 2);
}
