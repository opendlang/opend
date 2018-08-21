/**
   Dynamic arrays with deterministic memory usage
   akin to C++'s std::vector or Rust's std::vec::Vec
 */
module automem.array;


import automem.traits: isAllocator, isGlobal;
import std.range.primitives: isInputRange;
import stdx.allocator: theAllocator;
import stdx.allocator.mallocator: Mallocator;


auto array(A = typeof(theAllocator), E)
          (E[] elements...)
    if(isAllocator!A && isGlobal!A)
{
    return Array!(A, E)(elements);
}

auto array(A = typeof(theAllocator), E)
          (A allocator, E[] elements...)
    if(isAllocator!A && !isGlobal!A)
{
    return Array!(A, E)(allocator, elements);
}

auto array(A = typeof(theAllocator), R)
          (R range)
    if(isAllocator!A && isGlobal!A && isInputRange!R)
{
    import std.range.primitives: ElementType;
    return Array!(A, ElementType!R)(range);
}


auto array(A = typeof(theAllocator), R)
          (A allocator, R range)
    if(isAllocator!A && !isGlobal!A && isInputRange!R)
{
    import std.range.primitives: ElementType;
    return Array!(A, ElementType!R)(range);
}


struct Array(Allocator, E) if(isAllocator!Allocator) {

    import automem.traits: isGlobal, isSingleton, isTheAllocator;

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
        _elements = createArray(_elements.length);
        _elements[] = oldElements[];
    }

    ~this() scope {
        import stdx.allocator: dispose;
        () @trusted { _allocator.dispose(_elements); }();
    }

    inout(E) front() inout {
        return _elements[0];
    }

    inout(E) back() inout {
        return _elements[length - 1];
    }

    void popFront() {
        throw new Exception("Not implemented yet");
    }

    void popBack() {
        --_length;
    }

    bool empty() const {
        return _elements.length == 0;
    }

    long length() const {
        return _length;
    }

    void clear() {
        _length = 0;
    }

    ref inout(E) opIndex(long i) inout {
        return _elements[i];
    }

    Array opBinary(string s)(Array other) if(s == "~") {
        import std.range: chain;
        return Array(chain(_elements, other._elements));
    }

    void opAssign(R)(R range) scope if(isForwardRangeOf!(R, E)) {
        import std.range.primitives: walkLength, save;

        expandMemory(range.save.walkLength);

        long i = 0;
        foreach(element; range)
            _elements[i++] = element;
    }

    /// Append to the array
    void opOpAssign(string op)
                   (E other)
        scope
        if(op == "~")
    {
        expandMemory(length + 1);
        _elements[length - 1] = other;
    }

    /// Append to the array
    void opOpAssign(string op, R)
                   (R range)
        scope
        if(op == "~" && isForwardRangeOf!(R, E))
    {
        import std.range.primitives: walkLength, save;

        long index = length;
        expandMemory(length + range.save.walkLength);

        foreach(element; range)
            _elements[index++] = element;
    }

    scope auto opSlice(this This)() {
        return _elements[0 .. length];
    }

    scope auto opSlice(this This)(long start, long end) {
        return _elements[start .. end];
    }

    long opDollar() const {
        return _elements.length;
    }

    void opSliceAssign(E value) {
        _elements[] = value;
    }

    void opSliceAssign(E value, long start, long end) {
        _elements[start .. end] = value;
    }

    void opSliceOpAssign(string op)(E value) scope {
        foreach(ref elt; _elements)
            mixin(`elt ` ~ op ~ `= value;`);
    }

    void opSliceOpAssign(string op)(E value, long start, long end) scope {
        foreach(ref elt; _elements[start .. end])
            mixin(`elt ` ~ op ~ `= value;`);
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

    E[] createArray(long length) {
        import stdx.allocator: makeArray;
        _length = length;
        return () @trusted { return _allocator.makeArray!E(length); }();
    }

    void fromElements(E[] elements) {
        _elements = createArray(elements.length);
        _elements[] = elements[];
    }

    void expandMemory(long newLength) scope {
        import stdx.allocator: expandArray;

        if(newLength > capacity) {
            if(length == 0)
                _elements = createArray(newLength);
            else {
                const newCapacity = (newLength * 3) / 2;
                const delta = newCapacity - capacity;
                () @trusted { _allocator.expandArray(_elements, delta); }();
            }
        }

        _length = newLength;
    }

    long capacity() const {
        return _elements.length;
    }
}


private template isInputRangeOf(R, E) {
    import std.range.primitives: isInputRange, ElementType;
    import std.traits: Unqual;

    enum isInputRangeOf = isInputRange!R && is(Unqual!(ElementType!R) == E);
}

private template isForwardRangeOf(R, E) {
    import std.range.primitives: isForwardRange, ElementType;
    import std.traits: Unqual;

    enum isForwardRangeOf = isForwardRange!R && is(Unqual!(ElementType!R) == E);
}
