import unit_threaded;

int main(string[] args) {
    return args.runTests!(
        "automem",
        "automem.test_utils",
        "automem.traits",
        "automem.unique",
        "automem.unique_array",
        "automem.utils",
        "ut.allocator",
        "ut.ref_counted",
    );
}
