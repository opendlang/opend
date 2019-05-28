/**
   A reference-counted smart pointer.
 */
module automem.ref_counted;

import automem.traits: isAllocator;
import automem.unique: Unique;
import std.experimental.allocator: theAllocator, processAllocator;
import std.typecons: Flag;


alias RC = RefCounted;

version (D_BetterC)
    enum gcExists = false;
else
    enum gcExists = true;

/**
   A reference-counted smart pointer similar to C++'s std::shared_ptr.
 */
struct RefCounted(Type,
                  Allocator = typeof(theAllocator),
                  Flag!"supportGC" supportGC = gcExists ? Flag!"supportGC".yes : Flag!"supportGC".no)
    if(isAllocator!Allocator)
{

    import std.traits: hasMember;

    enum isSingleton = hasMember!(Allocator, "instance");
    enum isTheAllocator = is(Allocator == typeof(theAllocator));
    enum isGlobal = isSingleton || isTheAllocator;

    static if(isGlobal)
        /**
           The allocator is a singleton, so no need to pass it in to the
           constructor
        */
        this(Args...)(auto ref Args args) {
            this.makeObject!args();
        }
    else
        /**
           Non-singleton allocator, must be passed in
        */
        this(Args...)(Allocator allocator, auto ref Args args) {
            _allocator = allocator;
            this.makeObject!args();
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
                ret.makeObject!()();
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
    this(this) {
        if(_impl !is null) inc;
    }

    ///
    ~this() {
        release;
    }

    /**
       Assign to an lvalue RefCounted
    */
    void opAssign(ref RefCounted other) {

        if (_impl == other._impl) return;

        if(_impl !is null) release;

        static if(!isGlobal)
            _allocator = other._allocator;

        _impl = other._impl;

        if(_impl !is null) inc;
    }

    /**
       Assign to an rvalue RefCounted
     */
    void opAssign(RefCounted other) {
        import std.algorithm: swap;
        swap(_impl, other._impl);
        static if(!isGlobal)
            swap(_allocator, other._allocator);
    }

    /**
       Dereference the smart pointer and yield a reference
       to the contained type.
     */
    ref auto opUnary(string s)() inout if (s == "*") {
        return _impl._get;
    }

    /**
        Prevent opSlice and opIndex from being hidden by Impl*.
        This comment is deliberately not DDOC.
    */
    auto ref opSlice(A...)(auto ref A args)
    if (__traits(compiles, Type.init.opSlice(args)))
    {
        return _impl._get.opSlice(args);
    }
    /// ditto
    auto ref opIndex(A...)(auto ref A args)
    if (__traits(compiles, Type.init.opIndex(args)))
    {
        return _impl._get.opIndex(args);
    }
    /// ditto
    auto ref opIndexAssign(A...)(auto ref A args)
    if (__traits(compiles, Type.init.opIndexAssign(args)))
    {
        return _impl._get.opIndexAssign(args);
    }

    alias _impl this;

private:

    static struct Impl {

        static if(is(Type == class)) {

            align ((void*).alignof)
            void[__traits(classInstanceSize, Type)] _rawMemory;

        } else
            Type _object;

        static if(is(Type == shared))
            shared size_t _count;
        else
            size_t _count;

        static if (is(Type == class)) {
            inout(Type) _get() inout {
                return cast(inout(Type)) &_rawMemory[0];
            }

            inout(shared(Type)) _get() inout shared {
                return cast(inout(shared(Type))) &_rawMemory[0];
            }
        } else {
            ref inout(Type) _get() inout {
                return _object;
            }

            ref inout(shared(Type)) _get() inout shared {
                return _object;
            }
        }

        alias _get this;
    }

    static if(isSingleton)
        alias _allocator = Allocator.instance;
    else static if(isTheAllocator) {
        static if (is(Type == shared))
            // 'processAllocator' should be used for allocating
            // memory shared across threads
            alias _allocator = processAllocator;
        else
            alias _allocator = theAllocator;
    }
    else
        Allocator _allocator;

    static if(is(Type == shared))
        alias ImplType = shared Impl;
    else
        alias ImplType = Impl;

    public ImplType* _impl; // public or alias this doesn't work

    void allocateImpl() {
        import std.traits: hasIndirections;

        _impl = cast(typeof(_impl)) _allocator.allocate(Impl.sizeof);
        _impl._count = 1;

        static if (is(Type == class)) {
            // class representation:
            // void* classInfoPtr
            // void* monitorPtr
            // []    interfaces
            // T...  members
            import core.memory: GC;
            if (supportGC && !(typeid(Type).m_flags & TypeInfo_Class.ClassFlags.noPointers))
                // members have pointers: we have to watch the monitor
                // and all members; skip the classInfoPtr
                GC.addRange(&_impl._rawMemory[(void*).sizeof],
                        __traits(classInstanceSize, Type) - (void*).sizeof);
            else
                // representation doesn't have pointers, just watch the
                // monitor pointer; skip the classInfoPtr
                // need to watch the monitor pointer even if supportGC is false.
                GC.addRange(&_impl._rawMemory[(void*).sizeof], (void*).sizeof);
        } else static if (supportGC && hasIndirections!Type) {
            import core.memory: GC;
            GC.addRange(cast(void*) &_impl._object, Type.sizeof);
        }
    }

    void release() {
        import std.traits : hasIndirections;
        import core.memory : GC;
        import automem.utils : destruct;

        if(_impl is null) return;
        assert(_impl._count > 0, "Trying to release a RefCounted but ref count is 0 or less");

        dec;

        if(_impl._count == 0) {
            () @trusted { destruct(_impl._get); }();
            static if (is(Type == class)) {
                // need to watch the monitor pointer even if supportGC is false.
                () @trusted { GC.removeRange(&_impl._rawMemory[(void*).sizeof]); }();
            } else static if (supportGC && hasIndirections!Type) {
                () @trusted { GC.removeRange(cast(void*) &_impl._object); }();
            }
            auto mem = () @trusted { return cast(void*) _impl; }();
            () @trusted { _allocator.deallocate(mem[0 .. Impl.sizeof]); }();
        }
    }

    void inc() {
        static if(is(Type == shared)) {
            import core.atomic: atomicOp;
            _impl._count.atomicOp!"+="(1);
        } else
            ++_impl._count;
    }

    void dec() {
        static if(is(Type == shared)) {
            import core.atomic: atomicOp;
            _impl._count.atomicOp!"-="(1);
        } else
            --_impl._count;
    }

}

private template makeObject(args...)
{
    void makeObject(Type, A)(ref RefCounted!(Type, A) rc) @trusted {
        import std.conv: emplace;
        import std.functional : forward;

        rc.allocateImpl;

        static if(is(Type == class))
            emplace!Type(rc._impl._rawMemory, forward!args);
        else
            emplace(&rc._impl._object, forward!args);
    }
}



auto refCounted(Type, Allocator)(Unique!(Type, Allocator) ptr) {

    RefCounted!(Type, Allocator) ret;

    static if(!ptr.isGlobal)
        ret._allocator = ptr.allocator;

    ret.allocateImpl;
    *ret = *ptr;

    return ret;
}
