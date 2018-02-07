import unit_threaded;

int main(string[] args)
{
    return args.runTests!(
                          "automem",
                          "automem.allocator",
                          "automem.ref_counted",
                          "automem.test_utils",
                          "automem.traits",
                          "automem.unique",
                          "automem.unique_array",
                          "automem.utils"
                          );
}
