/++
Templates used to check primitives and 
range primitives for arrays with multi-dimensional like API support.

Note:
UTF strings behaves like common arrays in Mir.
`std.uni.byCodePoint` can be used to create a range of characters.

License: $(HTTP www.apache.org/licenses/LICENSE-2.0, Apache-2.0)
Authors: Ilia Ki, $(HTTP erdani.com, Andrei Alexandrescu), David Simcha, and
         $(HTTP jmdavisprog.com, Jonathan M Davis). Credit for some of the ideas
         in building this module goes to
         $(HTTP fantascienza.net/leonardo/so/, Leonardo Maffi)
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
(const R r, inout int = 0)
{
    size_t l = r.length;
}));

///
@safe version(mir_core_test) unittest
{
    static assert(hasLength!(char[]));
    static assert(hasLength!(int[]));
    static assert(hasLength!(inout(int)[]));

    struct B { size_t length() const { return 0; } }
    struct C { @property size_t length() const { return 0; } }
    static assert(hasLength!(B));
    static assert(hasLength!(C));
}

/++
Returns: `true` if `R` has a `shape` member that returns an static array type of size_t[N].
+/
enum bool hasShape(R) = is(typeof(
(const R r, inout int = 0)
{
    auto l = r.shape;
    alias F = typeof(l);
    import std.traits;
    static assert(isStaticArray!F);
    static assert(is(ForeachType!F == size_t));
}));

///
@safe version(mir_core_test) unittest
{
    static assert(hasShape!(char[]));
    static assert(hasShape!(int[]));
    static assert(hasShape!(inout(int)[]));

    struct B { size_t length() const { return 0; } }
    struct C { @property size_t length() const { return 0; } }
    static assert(hasShape!(B));
    static assert(hasShape!(C));
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
version(mir_core_test) unittest
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
bool anyEmpty(Range)(scope const auto ref Range range) @property
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
size_t elementCount(Range)(scope const auto ref Range range) @property
    if (hasShape!Range || __traits(hasMember, Range, "elementCount"))
{
    static if (__traits(hasMember, Range, "elementCount"))
    {
        return range.elementCount;
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
bool empty(size_t dim = 0, T)(scope const T[] ar)
    if (!dim)
{
    return !ar.length;
}

///
version(mir_core_test) unittest
{
   assert((int[]).init.empty);
   assert(![1].empty!0); // Slice-like API
}

///
ref inout(T) front(size_t dim = 0, T)(scope return inout(T)[] ar)
    if (!dim && !is(Unqual!T[] == void[]))
{
    assert(ar.length, "Accessing front of an empty array.");
    return ar[0];
}

///
version(mir_core_test) unittest
{
   assert(*&[3, 4].front == 3); // access be ref
   assert([3, 4].front!0 == 3); // Slice-like API
}


///
ref inout(T) back(size_t dim = 0, T)(scope return inout(T)[] ar)
    if (!dim && !is(Unqual!T[] == void[]))
{
    assert(ar.length, "Accessing back of an empty array.");
    return ar[$ - 1];
}

///
version(mir_core_test) unittest
{
   assert(*&[3, 4].back == 4); // access be ref
   assert([3, 4].back!0 == 4); // Slice-like API
}

///
void popFront(size_t dim = 0, T)(scope ref inout(T)[] ar)
    if (!dim && !is(Unqual!T[] == void[]))
{
    assert(ar.length, "Evaluating popFront() on an empty array.");
    ar = ar[1 .. $];
}

///
version(mir_core_test) unittest
{
    auto ar = [3, 4];
    ar.popFront;
    assert(ar == [4]);
    ar.popFront!0;  // Slice-like API
    assert(ar == []);
}

///
void popBack(size_t dim = 0, T)(scope ref inout(T)[] ar)
    if (!dim && !is(Unqual!T[] == void[]))
{
    assert(ar.length, "Evaluating popBack() on an empty array.");
    ar = ar[0 .. $ - 1];
}

///
version(mir_core_test) unittest
{
    auto ar = [3, 4];
    ar.popBack;
    assert(ar == [3]);
    ar.popBack!0;  // Slice-like API
    assert(ar == []);
}

///
size_t popFrontN(size_t dim = 0, T)(scope ref inout(T)[] ar, size_t n)
    if (!dim && !is(Unqual!T[] == void[]))
{
    n = ar.length < n ? ar.length : n;
    ar = ar[n .. $];
    return n;
}

///
version(mir_core_test) unittest
{
    auto ar = [3, 4];
    ar.popFrontN(1);
    assert(ar == [4]);
    ar.popFrontN!0(10);  // Slice-like API
    assert(ar == []);
}

///
size_t popBackN(size_t dim = 0, T)(scope ref inout(T)[] ar, size_t n)
    if (!dim && !is(Unqual!T[] == void[]))
{
    n = ar.length < n ? ar.length : n;
    ar = ar[0 .. $ - n];
    return n;
}

///
version(mir_core_test) unittest
{
    auto ar = [3, 4];
    ar.popBackN(1);
    assert(ar == [3]);
    ar.popBackN!0(10);  // Slice-like API
    assert(ar == []);
}

///
void popFrontExactly(size_t dim = 0, T)(scope ref inout(T)[] ar, size_t n)
    if (!dim && !is(Unqual!T[] == void[]))
{
    assert(ar.length >= n, "Evaluating *.popFrontExactly(n) on an array with length less then n.");
    ar = ar[n .. $];
}

///
version(mir_core_test) unittest
{
    auto ar = [3, 4, 5];
    ar.popFrontExactly(2);
    assert(ar == [5]);
    ar.popFrontExactly!0(1);  // Slice-like API
    assert(ar == []);
}

///
void popBackExactly(size_t dim = 0, T)(scope ref inout(T)[] ar, size_t n)
    if (!dim && !is(Unqual!T[] == void[]))
{
    assert(ar.length >= n, "Evaluating *.popBackExactly(n) on an array with length less then n.");
    ar = ar[0 .. $ - n];
}

///
version(mir_core_test) unittest
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
version(mir_core_test) unittest
{
    assert([1, 2].length!0 == 2);
    assert([1, 2].elementCount == 2);
}

///
inout(T)[] save(T)(scope return inout(T)[] array)
{
    return array;
}

///
version(mir_core_test) unittest
{
    auto a = [1, 2];
    assert(a is a.save);
}

/**
Returns `true` if `R` is an input range. An input range must
define the primitives `empty`, `popFront`, and `front`. The
following code should compile for any input range.
----
R r;              // can define a range object
if (r.empty) {}   // can test for empty
r.popFront();     // can invoke popFront()
auto h = r.front; // can get the front of the range of non-void type
----
The following are rules of input ranges are assumed to hold true in all
Phobos code. These rules are not checkable at compile-time, so not conforming
to these rules when writing ranges or range based code will result in
undefined behavior.
$(UL
    $(LI `r.empty` returns `false` if and only if there is more data
    available in the range.)
    $(LI `r.empty` evaluated multiple times, without calling
    `r.popFront`, or otherwise mutating the range object or the
    underlying data, yields the same result for every evaluation.)
    $(LI `r.front` returns the current element in the range.
    It may return by value or by reference.)
    $(LI `r.front` can be legally evaluated if and only if evaluating
    `r.empty` has, or would have, equaled `false`.)
    $(LI `r.front` evaluated multiple times, without calling
    `r.popFront`, or otherwise mutating the range object or the
    underlying data, yields the same result for every evaluation.)
    $(LI `r.popFront` advances to the next element in the range.)
    $(LI `r.popFront` can be called if and only if evaluating `r.empty`
    has, or would have, equaled `false`.)
)
Also, note that Phobos code assumes that the primitives `r.front` and
`r.empty` are $(BIGOH 1) time complexity wise or "cheap" in terms of
running time. $(BIGOH) statements in the documentation of range functions
are made with this assumption.
Params:
    R = type to be tested
Returns:
    `true` if R is an input range, `false` if not
 */
enum bool isInputRange(R) =
    is(typeof(R.init) == R)
    && is(ReturnType!((R r) => r.empty) == bool)
    && is(typeof((return ref R r) => r.front))
    && !is(ReturnType!((R r) => r.front) == void)
    && is(typeof((R r) => r.popFront));

/**
Returns `true` if `R` is an infinite input range. An
infinite input range is an input range that has a statically-defined
enumerated member called `empty` that is always `false`,
for example:
----
struct MyInfiniteRange
{
    enum bool empty = false;
    ...
}
----
 */

template isInfinite(R)
{
    static if (isInputRange!R && __traits(compiles, { enum e = R.empty; }))
        enum bool isInfinite = !R.empty;
    else
        enum bool isInfinite = false;
}


/**
The element type of `R`. `R` does not have to be a range. The
element type is determined as the type yielded by `r.front` for an
object `r` of type `R`. For example, `ElementType!(T[])` is
`T` if `T[]` isn't a narrow string; if it is, the element type is
`dchar`. If `R` doesn't have `front`, `ElementType!R` is
`void`.
 */
template ElementType(R)
{
    static if (is(typeof(R.init.front.init) T))
        alias ElementType = T;
    else
        alias ElementType = void;
}

/++
This is a best-effort implementation of `length` for any kind of
range.
If `hasLength!Range`, simply returns `range.length` without
checking `upTo` (when specified).
Otherwise, walks the range through its length and returns the number
of elements seen. Performes $(BIGOH n) evaluations of `range.empty`
and `range.popFront()`, where `n` is the effective length of $(D
range).
+/
auto walkLength(Range)(Range range)
if (isIterable!Range && !isInfinite!Range)
{
    static if (hasLength!Range)
        return range.length;
    else
    static if (__traits(hasMember, Range, "walkLength"))
        return range.walkLength;
    static if (isInputRange!Range)
    {
        size_t result;
        for ( ; !range.empty ; range.popFront() )
            ++result;
        return result;
    }
    else
    {
        size_t result;
        foreach (ref e; range)
            ++result;
        return result;
    }
}

/++
Returns `true` if `R` is an output range for elements of type
`E`. An output range is defined functionally as a range that
supports the operation $(D r.put(e)).
 +/
enum bool isOutputRange(R, E) =
    is(typeof(R.init.put(E.init)));
