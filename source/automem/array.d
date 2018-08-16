/**
   Dynamic arrays with deterministic memory usage
   akin to C++'s std::vector or Rust's std::vec::Vec
 */
module automem.array;


auto array(T)(T[] elements...) {
    return elements.dup;
}
