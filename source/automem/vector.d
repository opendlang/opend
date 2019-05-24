/**
   Dynamic arrays with deterministic memory usage
   akin to C++'s std::vector or Rust's std::vec::Vec
 */
module automem.vector;


import automem.traits: isGlobal;
import std.range.primitives: isInputRange;
import std.experimental.allocator: theAllocator;
import std.experimental.allocator.mallocator: Mallocator;


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
    return Vector!(ElementType!R, A)(allocator, range);
}

/**
   A dynamic array with deterministic memory usage
   akin to C++'s std::vector or Rust's std::vec::Vec
 */
struct Vector(E, Allocator = typeof(theAllocator)) if(isAllocator!Allocator) {

    import automem.traits: isGlobal, isSingleton, isTheAllocator;
    import std.traits: Unqual, isCopyable;

    alias MutE = Unqual!E;
    enum isElementMutable = !is(E == immutable) && !is(E == const);

    static if(isGlobal!Allocator) {

        this(E[] elements...) {
            fromElements(elements);
        }

        this(R)(R range) if(isInputRangeOf!(R, E)) {
            // reallocating is ok if only allocating now
            () @trusted { this = range; }();
        }

    } else static if(isCopyable!Allocator) {

        this(Allocator allocator, E[] elements...) {
            _allocator = allocator;
            fromElements(elements);
        }

        this(R)(Allocator allocator, R range) if(isInputRangeOf!(R, E)) {
            _allocator = allocator;
            this = range;
        }
    } else {

        this(R)(R range) if(isInputRangeOf!(R, E)) {
            this = range;
        }

    }

    this(this) scope {

        auto oldElements = _elements;
        _elements = createVector(_elements.length);

        static if(isElementMutable)
            _elements[0 .. length.toSizeT] = oldElements[0 .. length.toSizeT];
        else
            () @trusted {
                cast(MutE[])(_elements)[0 .. length.toSizeT] = oldElements[0 .. length.toSizeT];
            }();
    }

    ~this() {
        free;
    }

    /// Frees the memory and returns to .init
    void free() scope {
        import std.experimental.allocator: dispose;

        // dispose is @system for theAllocator
        () @trusted {
            static if(is(E == immutable))
                auto elements = cast(MutE[]) _elements;
            else
                alias elements = _elements;

            _allocator.dispose(elements);
        }();

        clear;
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

        /**
           Shrink to fit the new length given. Returns if shrunk.
           Cannot be made @safe due to reallocation causing pointers
           to dangle.
        */
        bool shrink(long newLength) scope {
            import std.experimental.allocator: shrinkArray;

            const delta = capacity - newLength;
            const shrunk = _allocator.shrinkArray(_elements, delta.toSizeT);
            _length = newLength;

            return shrunk;
        }
    }

    /// Access the ith element. Can throw RangeError.
    ref inout(E) opIndex(long i) scope return inout {
        if(i < 0 || i >= length)
            mixin(throwBoundsException);
        return _elements[i.toSizeT];
    }

    /// Returns a new vector after appending to the given vector.
    Vector opBinary(string s, T)(auto ref T other) const
        if(s == "~" && is(Unqual!T == Vector))
    {
        import std.range: chain;
        // opSlice is @system , but it's ok here because we're not
        // returning the slice but concatenating.
        return Vector(chain(() @trusted { return this[]; }(),
                            () @trusted { return other[]; }()));
    }

    /// Assigns from a range.
    void opAssign(R)(R range) scope if(isForwardRangeOf!(R, E)) {
        import std.range.primitives: walkLength, save;

        expand(range.save.walkLength);

        long i = 0;
        foreach(element; range)
            _elements[toSizeT(i++)] = element;
    }

    // make it an output range


    /// Append to the vector
    void opOpAssign(string op)
                   (E other)
        scope
        if(op == "~")
    {
        put(other);
    }

    void put(E other) {

        expand(length + 1);

        const lastIndex = (length - 1).toSizeT;

        static if(isElementMutable)
            _elements[lastIndex] = other;
        else {
            assert(_elements[lastIndex] == E.init,
                   "Assigning to non default initialised non mutable member");

            () @trusted { mutableElements[lastIndex] = other; }();
        }
    }

    /// Append to the vector from a range
    void opOpAssign(string op, R)
                   (scope R range)
        scope
        if(op == "~" && isForwardRangeOf!(R, E))
    {
        put(range);
    }

    void put(R)(scope R range) if(isLengthRangeOf!(R, E)) {
        import std.range.primitives: walkLength, save;

        long index = length;

        static if(hasLength!R)
            const rangeLength = range.length;
        else
            const rangeLength = range.save.walkLength;

        expand(length + rangeLength);

        foreach(element; range) {
            const safeIndex = toSizeT(index++);
            static if(!isElementMutable) {
                assert(_elements[safeIndex] == E.init,
                       "Assigning to non default initialised non mutable member");
            }

            static if(isElementMutable)
                _elements[safeIndex] = element;
            else {
                assert(_elements[safeIndex] == E.init,
                       "Assigning to non default initialised non mutable member");
                () @trusted { mutableElements[safeIndex] = element; }();
            }
        }
    }

    /**
       Return a forward range of the vector contents.
       Negative `end` values work like in Python.
     */
    auto range(this This)(in long start = 0, long end = -1) return scope
        in(start >= 0)
        in(end <= length)
        do
    {
        import std.range.primitives: isForwardRange;

        static struct Range {
            private This* self;
            private long index;
            private long end;

            Range save() {
                return this;
            }

            auto front() {
                return (*self)[index];
            }

            void popFront() {
                ++index;
            }

            bool empty() const {
                const comp = end < 0 ? length + end + 1 : end;
                return index >= comp;
            }

            auto length() const {
                return self.length;
            }
        }

        static assert(isForwardRange!Range);

        // FIXME - why isn't &this @safe?
        return Range(() @trusted { return &this; }(),
                     start,
                     end);
    }

    /**
       Returns a slice.
       @system because the pointer in the slice might dangle.
     */
    auto opSlice(this This)() @system scope return {
        return _elements[0 .. length.toSizeT];
    }

    /**
       Returns a slice.
       @system because the pointer in the slice might dangle.
     */
    auto opSlice(this This)(long start, long end) @system scope return {
        if(start < 0 || start >= length)
            mixin(throwBoundsException);

        if(end < 0 || end >= length)
            mixin(throwBoundsException);

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
                mixin(throwBoundsException);

            if(end < 0 || end >= length)
                mixin(throwBoundsException);

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
                mixin(throwBoundsException);

            if(end < 0 || end >= length)
                mixin(throwBoundsException);

            foreach(ref elt; _elements[start.toSizeT .. end.toSizeT])
                mixin(`elt ` ~ op ~ `= value;`);
        }
    }

    bool opCast(U)() const scope if(is(U == bool)) {
        return length > 0;
    }

    static if(is(Unqual!E == char)) {

        /**
           Return a null-terminated C string
           @system since appending is not @safe.
         */
        auto stringz(this This)() return scope @system {
            if(capacity == length) reserve(length + 1);

            static if(isElementMutable) {
                _elements[length.toSizeT] = 0;
            } else {
                assert(_elements[length.toSizeT] == E.init || _elements[length.toSizeT] == 0,
                       "Assigning to non default initialised non mutable member");

                () @trusted { mutableElements[length.toSizeT] = 0; }();
            }

            return &_elements[0];
        }
    }

    auto ptr(this This)() return scope {
        return &_elements[0];
    }

    bool opEquals(R)(R range) scope const
        if(isInputRangeOf!(R, E))
    {
        import std.array: empty, popFront, front;

        if(length == 0 && range.empty) return true;

        foreach(i; 0 .. length) {
            if(range.empty) return false;
            if(range.front != this[i]) return false;
            range.popFront;
        }

        return range.empty;
    }

    bool opEquals(OtherAllocator)(auto ref scope const(Vector!(E, OtherAllocator)) other) const {
        return this == other.range;
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

    E[] createVector(long length) scope {
        import std.experimental.allocator: makeArray;
        // theAllocator.makeArray is @system
        return () @trusted { return _allocator.makeArray!E(length.toSizeT); }();
    }

    void fromElements(E[] elements) {

        _elements = createVector(elements.length);

        static if(isElementMutable)
            _elements[] = elements[];
        else
            () @trusted { (cast(MutE[]) _elements)[] = elements[]; }();

        _length = elements.length;
    }

    void expand(long newLength) scope {
        expandMemory(newLength);
        _length = newLength;
    }


    // @system since reallocating can cause pointers to dangle
    void expandMemory(long newLength) scope @system {
        import std.experimental.allocator: expandArray;

        if(newLength > capacity) {
            if(length == 0)
                _elements = createVector(newLength);
            else {
                const newCapacity = (newLength * 3) / 2;
                const delta = newCapacity - capacity;
                _allocator.expandArray(mutableElements, delta.toSizeT);
            }
        }
    }

    ref MutE[] mutableElements() scope return @system {
        auto ptr = &_elements;
        return *(cast(MutE[]*) ptr);
    }
}


static if (__VERSION__ >= 2082) { // version identifier D_Exceptions was added in 2.082
    version (D_Exceptions)
        private enum haveExceptions = true;
    else
        private enum haveExceptions = false;
} else {
    version (D_BetterC)
        private enum haveExceptions = false;
    else
        private enum haveExceptions = true;
}


static if (haveExceptions) {
    private static immutable boundsException = new BoundsException("Out of bounds index");
    private enum throwBoundsException = q{throw boundsException;};
    class BoundsException: Exception {
        import std.exception: basicExceptionCtors;

        mixin basicExceptionCtors;
    }
} else {
    private enum throwBoundsException = q{assert(0, "Out of bounds index");};
}


private template isInputRangeOf(R, E) {
    import std.range.primitives: isInputRange;
    enum isInputRangeOf = isInputRange!R && canAssignFrom!(R, E);
}

private template isForwardRangeOf(R, E) {
    import std.range.primitives: isForwardRange;
    enum isForwardRangeOf = isForwardRange!R && canAssignFrom!(R, E);
}


private enum hasLength(R) = is(typeof({
    import std.traits: isIntegral;
    auto length = R.init.length;
    static assert(isIntegral!(typeof(length)));
}));


private enum isLengthRangeOf(R, E) = isForwardRangeOf!(R, E) || hasLength!R;

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


void checkAllocator(T)() {
    import std.experimental.allocator: dispose, shrinkArray, makeArray, expandArray;
    import std.traits: hasMember;

    static if(hasMember!(T, "instance"))
        alias allocator = T.instance;
    else
        T allocator;

    void[] bytes;
    allocator.dispose(bytes);

    int[] ints = allocator.makeArray!int(42);

    allocator.shrinkArray(ints, size_t.init);
    allocator.expandArray(ints, size_t.init);
}
enum isAllocator(T) = is(typeof(checkAllocator!T));


@("isAllocator")
@safe @nogc pure unittest {
    import std.experimental.allocator.mallocator: Mallocator;
    import test_allocator: TestAllocator;

    static assert( isAllocator!Mallocator);
    static assert( isAllocator!TestAllocator);
    static assert(!isAllocator!int);
    static assert( isAllocator!(typeof(theAllocator)));
}
