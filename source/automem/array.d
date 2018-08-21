/**
   Dynamic arrays with deterministic memory usage
   akin to C++'s std::vector or Rust's std::vec::Vec
 */
module automem.array;


import std.range.primitives: isInputRange;
import stdx.allocator.mallocator: Mallocator;


auto array(A = Mallocator, E)(E[] elements...) {
    return Array!(A, E)(elements);
}


auto array(A = Mallocator, R)(R range) if(isInputRange!R) {
    import std.range.primitives: ElementType;
    return Array!(A, ElementType!R)(range);
}


struct Array(A, E) {

    alias Allocator = A;
    private alias _allocator = Allocator.instance;

    this(E[] elements...) {
        import stdx.allocator: makeArray;
        _elements = () @trusted { return _allocator.makeArray!E(elements.length); }();
        _elements[] = elements[];
    }

    this(R)(R range) if(isInputRangeOf!(R, E)) {
        this = range;
    }

    this(this) scope {
        import stdx.allocator: makeArray;
        auto oldElements = _elements;
        _elements = () @trusted { return _allocator.makeArray!E(_elements.length); }();
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
        return _elements[$ - 1];
    }

    void popFront() {
        _elements = _elements[1 .. $];
    }

    void popBack() {
        _elements = _elements[0 .. $ - 1];
    }

    bool empty() const {
        return _elements.length == 0;
    }

    long length() const {
        return _elements.length;
    }

    void clear() {
        _elements.length = 0;
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
        import stdx.allocator: makeArray, expandArray;

        const rangeLength = range.save.walkLength;
        const oldLength = length;

        // FIXME - what if it's smaller?
        if(rangeLength > length) {
            if(length == 0)
                _elements = () @trusted { return _allocator.makeArray!E(rangeLength); }();
            else
                () @trusted { _allocator.expandArray(_elements, rangeLength - length); }();
        }

        long index = 0;

        foreach(element; range)
            _elements[index++] = element;
    }

    /// Append to the array
    void opOpAssign(string op)
                   (E other)
        scope
        if(op == "~")
    {
        import stdx.allocator: expandArray;
        () @trusted { _allocator.expandArray(_elements, 1); }();
        _elements[$-1] = other;
    }

    /// Append to the array
    void opOpAssign(string op, R)
                   (R range)
        scope
        if(op == "~" && isForwardRangeOf!(R, E))
    {
        import std.range.primitives: walkLength, save;
        import stdx.allocator: expandArray;

        const rangeLength = range.save.walkLength;
        long index = length;

        () @trusted { _allocator.expandArray(_elements, rangeLength); }();

        foreach(element; range)
            _elements[index++] = element;
    }

    scope auto opSlice(this This)() {
        return _elements;
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

    private E[] _elements;
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
