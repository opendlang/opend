/**
   A unique pointer.
 */
module automem.unique;

import automem.traits: isAllocator;
import std.experimental.allocator: theAllocator;
import std.typecons: Flag;

version(AutomemTesting) {
    import ut;
    mixin TestUtils;
}

version (D_BetterC)
    enum gcExists = false;
else
    enum gcExists = true;

/**
   A unique pointer similar to C++'s std::unique_ptr.
 */
struct Unique(
    UniqueType,
    Allocator = typeof(theAllocator()),
    Flag!"supportGC" supportGC = gcExists ? Flag!"supportGC".yes : Flag!"supportGC".no
)
    if(isAllocator!Allocator)
{

    import std.traits: hasMember;
    import std.typecons: Proxy;

    enum isSingleton = hasMember!(Allocator, "instance");
    enum isTheAllocator = is(Allocator == typeof(theAllocator));
    enum isGlobal = isSingleton || isTheAllocator;

    alias Type = UniqueType;

    static if(is(Type == class) || is(Type == interface))
        alias Pointer = Type;
    else
        alias Pointer = Type*;

    static if(isGlobal) {

        /**
           The allocator is global, so no need to pass it in to the constructor
        */
        this(Args...)(auto ref Args args) {
            this.makeObject!(supportGC, args)();
        }

    } else {

        /**
           Non-singleton allocator, must be passed in
         */
        this(Args...)(Allocator allocator, auto ref Args args) {
            _allocator = allocator;
            this.makeObject!(supportGC, args)();
        }
    }


    static if(isGlobal)
        /**
            Factory method so can construct with zero args.
        */
        static typeof(this) construct(Args...)(auto ref Args args) {
            static if (Args.length != 0)
                return typeof(return)(args);
            else {
                typeof(return) ret;
                ret.makeObject!(supportGC)();
                return ret;
            }
        }
    else
        /**
            Factory method. Not necessary with non-global allocator
            but included for symmetry.
        */
        static typeof(this) construct(Args...)(auto ref Allocator allocator, auto ref Args args) {
            return typeof(return)(allocator, args);
        }

    ///
    this(T)(Unique!(T, Allocator) other) if(is(T: Type)) {
        moveFrom(other);
    }

    ///
    @disable this(this);

    ///
    ~this() {
        deleteObject;
    }

    /**
       Borrow the owned pointer.
       Can be @safe with DIP1000 and if used in a scope fashion.
     */
    auto borrow() inout {
        return _object;
    }

    alias get = borrow; // backwards compatibility

    /**
       Releases ownership and transfers it to the returned
       Unique object.
     */
    Unique unique() {
        import std.algorithm: move;
        Unique u;
        move(this, u);
        assert(_object is null);
        return u;
    }

    /// release ownership
    package Pointer release() {
        auto ret = _object;
        _object = null;
        return ret;
    }

    ///
    package Allocator allocator() {
        return _allocator;
    }

    /**
       "Truthiness" cast
     */
    bool opCast(T)() const if(is(T == bool)) {
        return _object !is null;
    }

    /// Move from another smart pointer
    void opAssign(T)(Unique!(T, Allocator) other) if(is(T: Type)) {
        deleteObject;
        moveFrom(other);
    }

    mixin Proxy!_object;

private:

    Pointer _object;

    static if(isSingleton)
        alias _allocator = Allocator.instance;
    else static if(isTheAllocator)
        alias _allocator = theAllocator;
    else
        Allocator _allocator;

    void deleteObject() @safe {
        import automem.allocator: dispose;
        import std.traits: isPointer;
        import std.traits : hasIndirections;
        import core.memory : GC;

        static if(isPointer!Allocator)
            assert(_object is null || _allocator !is null);

        if(_object !is null) () @trusted { _allocator.dispose(_object); }();
        static if (is(Type == class)) {
            // need to watch the monitor pointer even if supportGC is false.
            () @trusted {
                auto repr = (cast(void*)_object)[0..__traits(classInstanceSize, Type)];
                GC.removeRange(&repr[(void*).sizeof]);
            }();
        } else static if (supportGC && hasIndirections!Type && !is(Type == interface)) {
            () @trusted {
                GC.removeRange(_object);
            }();
        }
    }

    void moveFrom(T)(ref Unique!(T, Allocator) other) if(is(T: Type)) {
        _object = other._object;
        other._object = null;

        static if(!isGlobal) {
            import std.algorithm: move;
            _allocator = other._allocator.move;
        }
    }
}


///
@("Construct Unique using global allocator for struct with zero-args ctor")
@system unittest {
    struct S {
        private ulong zeroArgsCtorTest = 3;
    }
    auto s = Unique!S.construct();
    static assert(is(typeof(s) == Unique!S));
    assert(s._object !is null);
    assert(s.zeroArgsCtorTest == 3);
}


///
@("release")
@system unittest {
    import std.experimental.allocator: dispose;
    import core.exception: AssertError;

    try {
        auto allocator = TestAllocator();
        auto ptr = Unique!(Struct, TestAllocator*)(&allocator, 42);
        ptr.release;
        assert(Struct.numStructs == 1);
    } catch(AssertError e) { // TestAllocator should throw due to memory leak
        version(unitThreadedLight) {}
        else
            "Memory leak in TestAllocator".should.be in e.msg;
        return;
    }

    assert(0); // should throw above
}


private template makeObject(Flag!"supportGC" supportGC, args...)
{
    void makeObject(Type,A)(ref Unique!(Type, A) u) {
        import std.experimental.allocator: make;
        import std.functional : forward;
        import std.traits : hasIndirections;
        import core.memory : GC;

        u._object = () @trusted { return u._allocator.make!Type(forward!args); }();

        static if (is(Type == class) || is(Type == interface)) {
            () @trusted {
                auto repr = (cast(void*)u._object)[0..__traits(classInstanceSize, Type)];
                if (supportGC && !(typeid(Type).m_flags & TypeInfo_Class.ClassFlags.noPointers)) {
                    GC.addRange(&repr[(void*).sizeof],
                            __traits(classInstanceSize, Type) - (void*).sizeof);
                } else {
                    // need to watch the monitor pointer even if supportGC is false.
                    GC.addRange(&repr[(void*).sizeof], (void*).sizeof);
                }
            }();
        } else static if (supportGC && hasIndirections!Type) {
            () @trusted {
                GC.addRange(u._object, Type.sizeof);
            }();
        }
    }
}
