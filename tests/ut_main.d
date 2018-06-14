import unit_threaded;

int main(string[] args) {
    return args.runTests!(
        "automem",
        "automem.unique",
        "automem.test_utils",
        "automem.traits",
        "automem.utils",
        "ut.allocator",
        "ut.ref_counted",
        "ut.unique",
        "ut.unique_array",
    );
}
