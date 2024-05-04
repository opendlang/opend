/* TEST_OUTPUT:
---
fail_compilation/explicit_gc.d(25): Error: function `explicit_gc.fun1_bad` allocates closure for `fun1_bad()` with the GC under `pragma(explicit_gc)`
fail_compilation/explicit_gc.d(25):        delegate `explicit_gc.fun1_bad.__lambda2` closes over variable `x`
fail_compilation/explicit_gc.d(25):        `x` declared here
fail_compilation/explicit_gc.d(31): Error: cannot use operator `~=` in `pragma(explicit_gc)` function `explicit_gc.foo0`
fail_compilation/explicit_gc.d(32): Error: cannot use operator `~=` in `pragma(explicit_gc)` function `explicit_gc.foo0.bar`
fail_compilation/explicit_gc.d(62): Error: assigning an associative array element in `pragma(explicit_gc)` function `explicit_gc.foo4` may cause a GC allocation
fail_compilation/explicit_gc.d(69): Error: setting `length` in `pragma(explicit_gc)` function `explicit_gc.foo5` may cause a GC allocation
fail_compilation/explicit_gc.d(70): Error: array literal in `pragma(explicit_gc)` function `explicit_gc.foo5` may cause a GC allocation
fail_compilation/explicit_gc.d(72): Error: the `delete` keyword is obsolete
fail_compilation/explicit_gc.d(72):        use `object.destroy()` (and `core.memory.GC.free()` if applicable) instead
fail_compilation/explicit_gc.d(74): Error: assigning an associative array element in `pragma(explicit_gc)` function `explicit_gc.foo5` may cause a GC allocation
fail_compilation/explicit_gc.d(75): Error: cannot use operator `~=` in `pragma(explicit_gc)` function `explicit_gc.foo5`
fail_compilation/explicit_gc.d(76): Error: cannot use operator `~` in `pragma(explicit_gc)` function `explicit_gc.foo5`
---
*/

pragma(explicit_gc)
auto fun0() => new int; // ok

auto fun1_good(int x) => (int y) => x + y;

pragma(explicit_gc)
auto fun1_bad(int x) => (int y) => x+y; // error

pragma(explicit_gc, true)
void foo0()
{
    int[] x;
    x~=1; // error
    void bar(){ x~=2; } // error
}

pragma(explicit_gc, true)
void foo1()
{
    int[] x;
    pragma(explicit_gc, false) x~=1; // ok
    pragma(explicit_gc, false)
    void bar(){ x~=2; } // ok
}

pragma(explicit_gc, true)
auto foo2()
{
    int[int] x;
    pragma(explicit_gc, false) auto r=x[2]=3;
    return r;
}

pragma(explicit_gc)
auto foo3()
{
    int[int] x;
    pragma(explicit_gc, false) return x[2]=3;
}

auto foo4()
{
    int[int] x;
    pragma(explicit_gc) return x[2]=3; // error
}

pragma(explicit_gc)
auto foo5()
{
    int[] a;
    a.length = 5; // error
    auto b = [1, 2, 3]; // error
    auto c = new int[](3); // ok
    delete c; // error
    int[int] d;
    d[2] = 3; // error
    a ~= 3; // error
    auto e = b ~ b; // error
}
