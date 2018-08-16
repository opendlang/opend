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

    E[] _elements;
}
