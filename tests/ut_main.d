import unit_threaded;

int main(string[] args) {
    return args.runTests!(
        "automem",         // example tests
        "automem.unique",  // has some tests that can't be moved out
        "automem.traits",  // static asserts
        "automem.utils",   // static asserts
        "ut.allocator",
        "ut.ref_counted",
        "ut.unique",
        "ut.unique_array",
    );
}
