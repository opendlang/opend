/**
   Dynamic arrays with deterministic memory usage
   akin to C++'s std::vector or Rust's std::vec::Vec
 */
module automem.vector;


import automem.traits: isAllocator, isGlobal;
import std.range.primitives: isInputRange;
import stdx.allocator: theAllocator;
import stdx.allocator.mallocator: Mallocator;


alias String = StringA!(typeof(theAllocator));
alias StringM = StringA!Mallocator;


template StringA(A = typeof(theAllocator)) if(isAllocator!A) {
    alias StringA = Vector!(immutable char, A);
}

/**
   Create a vector from a variadic list of elements, inferring the type of
   the elements and the allocator
 */
auto vector(A = typeof(theAllocator), E)
           (E[] elements...)
    if(isAllocator!A && isGlobal!A)
{
    return Vector!(E, A)(elements);
}

/// ditto
auto vector(A = typeof(theAllocator), E)
           (A allocator, E[] elements...)
    if(isAllocator!A && !isGlobal!A)
{
    return Vector!(E, A)(allocator, elements);
}

/**
   Create a vector from an input range, inferring the type of the elements
   and the allocator.
 */
auto vector(A = typeof(theAllocator), R)
           (R range)
    if(isAllocator!A && isGlobal!A && isInputRange!R)
{
    import automem.vector: ElementType;
    return Vector!(ElementType!R, A)(range);
}


/// ditto
auto vector(A = typeof(theAllocator), R)
           (A allocator, R range)
    if(isAllocator!A && !isGlobal!A && isInputRange!R)
{
    import automem.vector: ElementType;
    return Vector!(ElementType!R, A)(range);
}

/**
   A dynamic array with deterministic memory usage
   akin to C++'s std::vector or Rust's std::vec::Vec
 */
struct Vector(E, Allocator = typeof(theAllocator)) if(isAllocator!Allocator) {

    import automem.traits: isGlobal, isSingleton, isTheAllocator;
    import std.traits: Unqual;

    alias MutE = Unqual!E;
    enum isElementMutable = !is(E == immutable) && !is(E == const);

    static if(isGlobal!Allocator) {

        this(E[] elements...) {
            fromElements(elements);
        }

        this(R)(R range) if(isInputRangeOf!(R, E)) {
            this = range;
        }

    } else {

        this(Allocator allocator, E[] elements...) {
            _allocator = allocator;
            fromElements(elements);
        }

        this(R)(Allocator allocator, R range) if(isInputRangeOf!(R, E)) {
            _allocator = allocator;
            this = range;
        }
    }

    this(this) scope {
        auto oldElements = _elements;
        _elements = createVector(_elements.length);
        () @trusted {
            cast(MutE[])(_elements)[0 .. length.toSizeT] = oldElements[0 .. length.toSizeT];
        }();
    }

    ~this() scope {
        import stdx.allocator: dispose;
        () @trusted { _allocator.dispose(cast(void[]) _elements); }();
    }

    /// Returns the first element
    inout(E) front() inout {
        return _elements[0];
    }

    /// Returns the last element
    inout(E) back() inout {
        return _elements[(length - 1).toSizeT];
    }

    static if(isElementMutable) {
        /// Pops the front element off
        void popFront() {
            foreach(i; 0 .. length - 1)
                _elements[i.toSizeT] = _elements[i.toSizeT + 1];

            popBack;
        }
    }

    /// Pops the last element off
    void popBack() {
        --_length;
    }

    /// If the vector is empty
    bool empty() const {
        return length == 0;
    }

    /// The current length of the vector
    @property long length() const {
        return _length;
    }

    /// Set the length of the vector
    @property void length(long newLength) {
        if(capacity < newLength) reserve(newLength);
        _length = newLength;
    }

    /// The current memory capacity of the vector
    long capacity() const {
        return _elements.length;
    }

    /// Clears the vector, resulting in an empty one
    void clear() {
        _length = 0;
    }

    /// Reserve memory to avoid allocations when appending
    void reserve(long newLength) {
        expandMemory(newLength);
    }

    static if(isElementMutable) {

        /// Shrink to fit the current length. Returns if shrunk.
        bool shrink() scope {
            return shrink(length);
        }

        /// Shrink to fit the new length given. Returns if shrunk.
        bool shrink(long newLength) scope @trusted {
            import stdx.allocator: shrinkArray;

            const delta = capacity - newLength;
            const shrunk = _allocator.shrinkArray(_elements, delta.toSizeT);
            _length = newLength;

            return shrunk;
        }
    }

    /// Access the ith element. Can throw RangeError.
    ref inout(E) opIndex(long i) inout {
        if(i < 0 || i >= length)
            throw boundsException;
        return _elements[i.toSizeT];
    }

    /// Returns a new vector after appending to the given vector.
    Vector opBinary(string s, T)(auto ref T other) const if(s == "~" && is(Unqual!T == Vector)) {
        import std.range: chain;
        return Vector(chain(this[], other[]));
    }

    /// Assigns from a range.
    void opAssign(R)(R range) scope if(isForwardRangeOf!(R, E)) {
        import std.range.primitives: walkLength, save;

        expand(range.save.walkLength);

        long i = 0;
        foreach(element; range)
            _elements[toSizeT(i++)] = element;
    }

    /// Append to the vector
    void opOpAssign(string op)
                   (E other)
        scope
        if(op == "~")
    {
        expand(length + 1);

        const lastIndex = (length - 1).toSizeT;
        static if(!isElementMutable) {
            assert(_elements[lastIndex] == E.init,
                   "Assigning to non default initialised non mutable member");
        }

        () @trusted { mutableElements[lastIndex] = other; }();
    }

    /// Append to the vector from a range
    void opOpAssign(string op, R)
                   (R range)
        scope
        if(op == "~" && isForwardRangeOf!(R, E))
    {
        import std.range.primitives: walkLength, save;

        long index = length;
        expand(length + range.save.walkLength);

        foreach(element; range) {
            const safeIndex = toSizeT(index++);
            static if(!isElementMutable) {
                assert(_elements[safeIndex] == E.init,
                       "Assigning to non default initialised non mutable member");
            }
            () @trusted { mutableElements[safeIndex] = element; }();
        }
    }

    /// Returns a slice
    auto opSlice(this This)() scope return {
        return _elements[0 .. length.toSizeT];
    }

    /// Returns a slice
    auto opSlice(this This)(long start, long end) scope return {
        if(start < 0 || start >= length)
            throw boundsException;

        if(end < 0 || end >= length)
            throw boundsException;

        return _elements[start.toSizeT .. end.toSizeT];
    }

    long opDollar() const {
        return length;
    }

    static if(isElementMutable) {
        /// Assign all elements to the given value
        void opSliceAssign(E value) {
            _elements[] = value;
        }
    }


    static if(isElementMutable) {
        /// Assign all elements in the given range to the given value
        void opSliceAssign(E value, long start, long end) {
            if(start < 0 || start >= length)
                throw boundsException;

            if(end < 0 || end >= length)
                throw boundsException;

            _elements[start.toSizeT .. end.toSizeT] = value;
        }
    }

    static if(isElementMutable) {
        /// Assign all elements using the given operation and the given value
        void opSliceOpAssign(string op)(E value) scope {
            foreach(ref elt; _elements)
                mixin(`elt ` ~ op ~ `= value;`);
        }
    }

    static if(isElementMutable) {
        /// Assign all elements in the given range  using the given operation and the given value
        void opSliceOpAssign(string op)(E value, long start, long end) scope {
            if(start < 0 || start >= length)
                throw boundsException;

            if(end < 0 || end >= length)
                throw boundsException;

            foreach(ref elt; _elements[start.toSizeT .. end.toSizeT])
                mixin(`elt ` ~ op ~ `= value;`);
        }
    }

    bool opCast(U)() const scope if(is(U == bool)) {
        return length > 0;
    }

private:

    E[] _elements;
    long _length;

    static if(isSingleton!Allocator)
        alias _allocator = Allocator.instance;
    else static if(isTheAllocator!Allocator)
        alias _allocator = theAllocator;
    else
        Allocator _allocator;

    E[] createVector(long length) {
        import stdx.allocator: makeArray;
        return () @trusted { return _allocator.makeArray!E(length.toSizeT); }();
    }

    void fromElements(E[] elements) {

        _elements = createVector(elements.length);
        () @trusted { (cast(MutE[]) _elements)[] = elements[]; }();
        _length = elements.length;
    }

    void expand(long newLength) scope {
        expandMemory(newLength);
        _length = newLength;
    }

    void expandMemory(long newLength) scope {
        import stdx.allocator: expandArray;

        if(newLength > capacity) {
            if(length == 0)
                _elements = createVector(newLength);
            else {
                const newCapacity = (newLength * 3) / 2;
                const delta = newCapacity - capacity;
                () @trusted { _allocator.expandArray(mutableElements, delta.toSizeT); }();
            }
        }
    }

    ref MutE[] mutableElements() scope return @system {
        auto ptr = &_elements;
        return *(cast(MutE[]*) ptr);
    }
}

private static immutable boundsException = new BoundsException("Out of bounds index");

class BoundsException: Exception {
    import std.exception: basicExceptionCtors;

    mixin basicExceptionCtors;
}

private template isInputRangeOf(R, E) {
    import std.range.primitives: isInputRange;
    enum isInputRangeOf = isInputRange!R && canAssignFrom!(R, E);
}

private template isForwardRangeOf(R, E) {
    import std.range.primitives: isForwardRange;
    enum isForwardRangeOf = isForwardRange!R && canAssignFrom!(R, E);
}


private template canAssignFrom(R, E) {
    enum canAssignFrom = is(typeof({
        import automem.vector: frontNoAutoDecode;
        E element = R.init.frontNoAutoDecode;
    }));
}
private size_t toSizeT(long length) @safe @nogc pure nothrow {
    static if(size_t.sizeof < long.sizeof)
        assert(length < cast(long) size_t.max);
    return cast(size_t) length;
}

// Because autodecoding is fun
private template ElementType(R) {
    import std.traits: isSomeString;

    static if(isSomeString!R) {
        alias ElementType = typeof(R.init[0]);
    } else {
        import std.range.primitives: ElementType_ = ElementType;
        alias ElementType = ElementType_!R;
    }
}

@("ElementType")
@safe pure unittest {
    import automem.vector: ElementType;
    static assert(is(ElementType!(int[]) == int));
    static assert(is(ElementType!(char[]) == char));
    static assert(is(ElementType!(wchar[]) == wchar));
    static assert(is(ElementType!(dchar[]) == dchar));
}


// More fun with autodecoding
private auto frontNoAutoDecode(R)(R range) {
    import std.traits: isSomeString;

    static if(isSomeString!R)
        return range[0];
    else {
        import std.range.primitives: front;
        return range.front;
    }
}
