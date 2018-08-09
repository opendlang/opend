/**
   RAII arrays
 */
module automem.unique_array;

import automem.traits: isAllocator;
import stdx.allocator: theAllocator;



/**
   A unique array similar to C++'s std::unique_ptr<T> when T is an array
 */
struct UniqueArray(Type, Allocator = typeof(theAllocator)) if(isAllocator!Allocator) {

    import std.traits: hasMember, isScalarType;
    import std.range: isInputRange;

    enum isSingleton = hasMember!(Allocator, "instance");
    enum isTheAllocator = is(Allocator == typeof(theAllocator));
    enum isGlobal = isSingleton || isTheAllocator;

    static if(isGlobal) {

        /**
           The allocator is global, so no need to pass it in to the
           constructor
        */

        this(size_t size) {
            makeObjects(size);
        }

        this(size_t size, Type init) {
            makeObjects(size, init);
        }

        this(R)(R range) if(isInputRange!R) {
            makeObjects(range);
        }


    } else {

        /**
           Non-singleton allocator, must be passed in
         */

        this(Allocator allocator) {
            _allocator = allocator;
        }

        this(Allocator allocator, size_t size) {
            _allocator = allocator;
            makeObjects(size);
        }

        this(Allocator allocator, size_t size, Type init) {
            _allocator = allocator;
            makeObjects(size, init);
        }

        this(R)(Allocator allocator, R range) if(isInputRange!R) {
            _allocator = allocator;
            makeObjects(range);
        }
    }


    this(T)(UniqueArray!(T, Allocator) other) if(is(T: Type[])) {
        moveFrom(other);
    }

    @disable this(this);

    ~this() {
        deleteObjects;
    }

    /**
       Releases ownership and transfers it to the returned
       Unique object.
     */
    UniqueArray unique() {
        import std.algorithm: move;
        UniqueArray u;
        move(this, u);
        assert(_objects.length == 0 && _objects.ptr is null);
        return u;
    }
    alias move = unique;

    /**
       "Truthiness" cast
     */
    bool opCast(T)() const if(is(T == bool)) {
        return _objects.ptr !is null;
    }

    void opAssign(T)(UniqueArray!(T, Allocator) other) if(is(T: Type[])) {
        deleteObject;
        moveFrom(other);
    }

    ref inout(Type) opIndex(long i) inout nothrow {
        return _objects[i];
    }

    const(Type)[] opSlice(long i, long j) const nothrow {
        return _objects[i .. j];
    }

    const(Type)[] opSlice() const nothrow {
        return _objects[0 .. length];
    }

    long opDollar() const nothrow {
        return length;
    }

    @property long length() nothrow const {
        return _length;
    }

    @property void length(long size) {

        import stdx.allocator: expandArray, shrinkArray;

        if(_objects is null) {
            makeObjects(size);
        } else if(size == length) {
            return;
        } else if(size <= _capacity && size > length) {
            foreach(ref obj; _objects[_length .. size])
                obj = obj.init;
            _length = size;
        } else if(size < length) {
            _length = size;
        } else {
            if(size > length) {
                () @trusted { _allocator.expandArray(_objects, size - length); }();
                setLength;
            } else
                assert(0);
        }
    }

    /**
       Dereference. const  since this otherwise could be used to try
       and append to the array, which would not be nice
     */
    const(Type[]) opUnary(string s)() const if(s == "*") {
        return this[];
    }

    /**
       Append to the array
     */
    UniqueArray opBinary(string s)(UniqueArray other) if(s == "~") {
        this ~= other.unique;
        return this.unique;
    }

    /// Append to the array
    void opOpAssign(string op)(Type other) if(op == "~") {
        length(length + 1);
        _objects[$ - 1] = other;
    }

    /// Append to the array
    void opOpAssign(string op)(Type[] other) if(op == "~") {
        const originalLength = length;
        length(originalLength + other.length);
        _objects[originalLength .. length] = other[];
    }

    /// Append to the array
    void opOpAssign(string op)(UniqueArray other) if(op == "~") {
        this ~= other._objects;
    }

    /// Assign from a slice.
    void opAssign(Type[] other) {
        length = other.length;
        _objects[0 .. length] = other[0 .. length];
    }

    /**
       Reserves memory to prevent too many allocations
     */
    void reserve(in long size) {
        import stdx.allocator: expandArray;

        if(_objects is null) {
            const oldLength = length;
            makeObjects(size); // length = capacity here
            _length = oldLength;
            return;
        }

        if(size < _capacity) {
            if(size < _length) _length = size;
            return;
        }

        _capacity = size;
        _allocator.expandArray(_objects, _capacity);
    }

    /**
       Returns a pointer to the underlying data. @system
     */
    inout(Type)* ptr() inout {
        return _objects.ptr;
    }

    static if(isGlobal) {
        UniqueArray dup() const {
            return UniqueArray(_objects);
        }
    } else static if(isScalarType!Allocator && is(typeof(() { auto a = Allocator.init; auto b = a; }))) {
        UniqueArray dup() const {
            return UniqueArray(_allocator, _objects);
        }
    } else {
        UniqueArray dup() {
            return UniqueArray(_allocator, _objects);
        }
    }

private:

    Type[] _objects;
    long _length;
    long _capacity;

    static if(isSingleton)
        alias _allocator = Allocator.instance;
    else static if(isTheAllocator)
        alias _allocator = theAllocator;
    else
        Allocator _allocator;

    void makeObjects(size_t size) {
        import stdx.allocator: makeArray;
        _objects = _allocator.makeArray!Type(size);
        setLength;
    }

    void makeObjects(size_t size, Type init) {
        import stdx.allocator: makeArray;
        _objects = _allocator.makeArray!Type(size, init);
        setLength;

    }

    void makeObjects(R)(R range) if(isInputRange!R) {
        import stdx.allocator: makeArray;
        _objects = _allocator.makeArray!Type(range);
        setLength;
    }

    void setLength() {
        _capacity = _length = _objects.length;
    }

    void deleteObjects() {
        import stdx.allocator: dispose;
        import std.traits: isPointer;

        static if(isPointer!Allocator)
            assert((_objects.length == 0 && _objects.ptr is null) || _allocator !is null);

        if(_objects.ptr !is null) _allocator.dispose(_objects);
        _length = 0;
    }

    void moveFrom(T)(ref UniqueArray!(T, Allocator) other) if(is(T: Type[])) {
        import std.algorithm: swap;
        _object = other._object;
        other._object = null;

        swap(_length, other._length);
        swap(_capacity, other._capacity);

        static if(!isGlobal) {
            import std.algorithm: move;
            _allocator = other._allocator.move;
        }
    }
}
