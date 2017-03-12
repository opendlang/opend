module automem;


version(unittest) {
    import unit_threaded;
    import test_allocator;
}


struct UniquePointer(Type, Allocator) {
    import std.traits: hasMember;

    enum hasInstance = hasMember!(Allocator, "instance");
    alias Pointer = Type*;

    static if(hasInstance)
        static assert(false);
    else
        /**
           Non-singleton allocator, must be passed in
         */
        this(Args...)(Allocator allocator, Args args) {
            import std.experimental.allocator: make;

            _allocator = allocator;
            _object = _allocator.make!Type(args);
        }

    ~this() {
        import std.experimental.allocator: dispose;
        _allocator.dispose(_object);
    }

    auto opDispatch(string func, A...)(A args) inout {
        mixin(`return _object.` ~ func ~ `(args);`);
    }

private:

    Pointer _object;

    static if(hasInstance)
        alias _allocator = Allocator.instance;
    else
        Allocator _allocator;
}


@("UniquePointer with struct and test allocator")
@system unittest {


    auto allocator = TestAllocator();
    {
        const foo = UniquePointer!(Struct, TestAllocator*)(&allocator, 5);
        foo.twice.shouldEqual(10);
        allocator.numAllocations.shouldEqual(1);
        Struct.numStructs.shouldEqual(1);
    }

    Struct.numStructs.shouldEqual(0);
}


version(unittest) {
    private struct Struct {
        int i;
        static int numStructs = 0;

        this(int i) @safe nothrow {
            this.i = i;
            ++numStructs;
        }

        ~this() @safe nothrow {
            --numStructs;
        }

        int twice() @safe pure const nothrow {
            return i * 2;
        }

    }

}
