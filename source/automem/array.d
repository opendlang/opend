/**
   Dynamic arrays with deterministic memory usage
   akin to C++'s std::vector or Rust's std::vec::Vec
 */
module automem.array;


auto array(E)(E[] elements...) {
    return Array!E(elements.dup);
}


struct Array(E) {

    this(this) {
        _elements = _elements.dup;
    }

    E front() {
        return _elements[0];
    }

    void popFront() {
        _elements = _elements[1 .. $];
    }

    bool empty() {
        return _elements.length == 0;
    }

    ref E opIndex(long i) {
        return _elements[i];
    }

    /// Append to the array
    void opOpAssign(string op)
                   (E other)
        if(op == "~")
    {
        _elements ~= other;
    }

    /// Append to the array
    void opOpAssign(string op, R)
                   (R other)
        if(op == "~" && isInputRangeOf!(R, E))
    {
        import std.array: array;
        _elements ~= other.array;
    }

    inout(E)[] opSlice() inout {
        return _elements[];
    }

    inout(E)[] opSlice(long start, long end) inout {
        return _elements[start .. end];
    }

    long opDollar() const {
        return _elements.length;
    }

    E[] _elements;
}


private template isInputRangeOf(R, E) {
    import std.range.primitives: isInputRange, ElementType;
    import std.traits: Unqual;

    enum isInputRangeOf = isInputRange!R && is(Unqual!(ElementType!R) == E);
}
