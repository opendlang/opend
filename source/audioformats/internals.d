/**
This is helpful to break dependency upon dplug:core.

Copyright: Guillaume Piolats 2022.
License:   $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost License 1.0)
*/
module audioformats.internals;


import core.stdc.stdlib: malloc, free, realloc;
import core.stdc.string: memcpy;
import core.exception: onOutOfMemoryErrorNoGC;
import std.conv: emplace;
import std.traits;

/// The only kind of exception thrown by audio-formats.
/// Those must be catch and destroyed with `destroyAudioFormatException`.
class AudioFormatsException : Exception
{
    public nothrow @nogc
    {
        @safe pure this(string message,
                        string file =__FILE__,
                        size_t line = __LINE__,
                        Throwable next = null)
        {
            super(message, file, line, next);
        }

        ~this()
        {}
    }
}


//
// Constructing and destroying without the GC.
//

/// Allocates and construct a struct or class object.
/// Returns: Newly allocated object.
auto mallocNew(T, Args...)(Args args)
{
    static if (is(T == class))
        immutable size_t allocSize = __traits(classInstanceSize, T);
    else
        immutable size_t allocSize = T.sizeof;

    void* rawMemory = malloc(allocSize);
    if (!rawMemory)
        onOutOfMemoryErrorNoGC();

    static if (is(T == class))
    {
        T obj = emplace!T(rawMemory[0 .. allocSize], args);
    }
    else
    {
        T* obj = cast(T*)rawMemory;
        emplace!T(obj, args);
    }

    return obj;
}

/// Destroys and frees a class object created with $(D mallocEmplace).
void destroyFree(T)(T p) if (is(T == class))
{
    if (p !is null)
    {
        destroyNoGC(p);
        free(cast(void*)p);
    }
}

/// Destroys and frees an interface object created with $(D mallocEmplace).
void destroyFree(T)(T p) if (is(T == interface))
{
    if (p !is null)
    {
        void* here = cast(void*)(cast(Object)p);
        destroyNoGC(p);
        free(cast(void*)here);
    }
}

/// Destroys and frees a non-class object created with $(D mallocEmplace).
void destroyFree(T)(T* p) if (!is(T == class))
{
    if (p !is null)
    {
        destroyNoGC(p);
        free(cast(void*)p);
    }
}


unittest
{
    class A
    {
        int _i;
        this(int i)
        {
            _i = i;
        }
    }

    struct B
    {
        int i;
    }

    void testMallocEmplace()
    {
        A a = mallocNew!A(4);
        destroyFree(a);

        B* b = mallocNew!B(5);
        destroyFree(b);
    }

    testMallocEmplace();
}


//
// Optimistic .destroy, which is @nogc nothrow by breaking the type-system
//

// for classes
void destroyNoGC(T)(T x) nothrow @nogc if (is(T == class) || is(T == interface))
{
    assumeNothrowNoGC(
                      (T x)
                      {
                        return destroy(x);
                      })(x);
}

// for struct
void destroyNoGC(T)(ref T obj) nothrow @nogc if (is(T == struct))
{
    assumeNothrowNoGC(
                      (ref T x)
                      {
                        return destroy(x);
                      })(obj);
}

void destroyNoGC(T)(ref T obj) nothrow @nogc
if (!is(T == struct) && !is(T == class) && !is(T == interface))
{
    assumeNothrowNoGC(
                      (ref T x)
                      {
                        return destroy(x);
                      })(obj);
}


auto assumeNothrowNoGC(T) (T t)
{
    static if (isFunctionPointer!T || isDelegate!T)
    {
        enum attrs = functionAttributes!T | FunctionAttribute.nogc | FunctionAttribute.nothrow_;
        return cast(SetFunctionAttributes!(T, functionLinkage!T, attrs)) t;
    }
    else
        static assert(false);
}


void reallocBuffer(T)(ref T[] buffer, size_t length) nothrow @nogc
{
    static if (is(T == struct) && hasElaborateDestructor!T)
    {
        static assert(false); // struct with destructors not supported
    }

    /// Size 0 is special-case to free the slice.
    if (length == 0)
    {
        free(buffer.ptr);
        buffer = null;
        return;
    }

    T* pointer = cast(T*) realloc(buffer.ptr, T.sizeof * length);
    if (pointer is null)
        buffer = null; // alignment 1 can still return null
    else
        buffer = pointer[0..length];
}


alias CString = CStringImpl!char;
alias CString16 = CStringImpl!wchar;

/// Zero-terminated C string, to replace toStringz and toUTF16z
struct CStringImpl(CharType) if (is(CharType: char) || is(CharType: wchar))
{
public:
nothrow:
@nogc:

    const(CharType)* storage = null;
    alias storage this;


    this(const(CharType)[] s)
    {
        // Always copy. We can't assume anything about the input.
        size_t len = s.length;
        CharType* buffer = cast(CharType*) malloc((len + 1) * CharType.sizeof);
        buffer[0..len] = s[0..len];
        buffer[len] = '\0';
        storage = buffer;
        wasAllocated = true;
    }

    // The constructor taking immutable can safely assume that such memory
    // has been allocated by the GC or malloc, or an allocator that align
    // pointer on at least 4 bytes.
    this(immutable(CharType)[] s)
    {
        // Same optimizations that for toStringz
        if (s.length == 0)
        {
            enum emptyString = cast(CharType[])"";
            storage = emptyString.ptr;
            return;
        }

        /* Peek past end of s[], if it's 0, no conversion necessary.
        * Note that the compiler will put a 0 past the end of static
        * strings, and the storage allocator will put a 0 past the end
        * of newly allocated char[]'s.
        */
        const(CharType)* p = s.ptr + s.length;
        // Is p dereferenceable? A simple test: if the p points to an
        // address multiple of 4, then conservatively assume the pointer
        // might be pointing to another block of memory, which might be
        // unreadable. Otherwise, it's definitely pointing to valid
        // memory.
        if ((cast(size_t) p & 3) && *p == 0)
        {
            storage = s.ptr;
            return;
        }

        size_t len = s.length;
        CharType* buffer = cast(CharType*) malloc((len + 1) * CharType.sizeof);
        buffer[0..len] = s[0..len];
        buffer[len] = '\0';
        storage = buffer;
        wasAllocated = true;
    }

    ~this()
    {
        if (wasAllocated)
            free(cast(void*)storage);
    }

    @disable this(this);

private:
    bool wasAllocated = false;
}


/// Duplicates a slice with `malloc`. Equivalent to `.dup`
/// Has to be cleaned-up with `free(slice.ptr)` or `freeSlice(slice)`.
T[] mallocDup(T)(const(T)[] slice) nothrow @nogc if (!is(T == struct))
{
    T[] copy = mallocSliceNoInit!T(slice.length);
    memcpy(copy.ptr, slice.ptr, slice.length * T.sizeof);
    return copy;
}

/// Allocates a slice with `malloc`, but does not initialize the content.
T[] mallocSliceNoInit(T)(size_t count) nothrow @nogc
{
    T* p = cast(T*) malloc(count * T.sizeof);
    return p[0..count];
}


/// Kind of a std::vector replacement.
/// Grow-only array, points to a (optionally aligned) memory location.
/// This can also work as an output range.
/// `Vec` is designed to work even when uninitialized, without `makeVec`.
struct Vec(T)
{
nothrow:
@nogc:
    public
    {
        /// Creates an aligned buffer with given initial size.
        this(size_t initialSize)
        {
            _size = 0;
            _allocated = 0;
            _data = null;
            resize(initialSize);
        }

        ~this()
        {
            if (_data !is null)
            {
                free(_data);
                _data = null;
                _allocated = 0;
            }
        }

        @disable this(this);

        /// Returns: Length of buffer in elements.
        size_t length() pure const
        {
            return _size;
        }

        /// Returns: Length of buffer in elements.
        alias opDollar = length;

        /// Resizes a buffer to hold $(D askedSize) elements.
        void resize(size_t askedSize)
        {
            // grow only
            if (_allocated < askedSize)
            {
                size_t numBytes = askedSize * 2 * T.sizeof; // gives 2x what is asked to make room for growth
                _data = cast(T*)(realloc(_data, numBytes));
                _allocated = askedSize * 2;
            }
            _size = askedSize;
        }

        /// Pop last element
        T popBack()
        {
            assert(_size > 0);
            _size = _size - 1;
            return _data[_size];
        }

        /// Append an element to this buffer.
        void pushBack(T x)
        {
            size_t i = _size;
            resize(_size + 1);
            _data[i] = x;
        }

        // DMD 2.088 deprecates the old D1-operators
        static if (__VERSION__ >= 2088)
        {
            ///ditto
            void opOpAssign(string op)(T x) if (op == "~")
            {
                pushBack(x);
            }
        }
        else
        {
            ///ditto
            void opCatAssign(T x)
            {
                pushBack(x);
            }
        }

        // Output range support
        alias put = pushBack;

        /// Finds an item, returns -1 if not found
        int indexOf(T x)
        {
            foreach(int i; 0..cast(int)_size)
                if (_data[i] is x)
                    return i;
            return -1;
        }

        /// Removes an item and replaces it by the last item.
        /// Warning: this reorders the array.
        void removeAndReplaceByLastElement(size_t index)
        {
            assert(index < _size);
            _data[index] = _data[--_size];
        }

        /// Removes an item and shift the rest of the array to front by 1.
        /// Warning: O(N) complexity.
        void removeAndShiftRestOfArray(size_t index)
        {
            assert(index < _size);
            for (; index + 1 < _size; ++index)
                _data[index] = _data[index+1];
        }

        /// Appends another buffer to this buffer.
        void pushBack(ref Vec other)
        {
            size_t oldSize = _size;
            resize(_size + other._size);
            memcpy(_data + oldSize, other._data, T.sizeof * other._size);
        }

        /// Appends a slice to this buffer.
        /// `slice` should not belong to the same buffer _data.
        void pushBack(T[] slice)
        {
            size_t oldSize = _size;
            size_t newSize = _size + slice.length;
            resize(newSize);
            for (size_t n = 0; n < slice.length; ++n)
                _data[oldSize + n] = slice[n];
        }

        /// Returns: Raw pointer to data.
        @property inout(T)* ptr() inout
        {
            return _data;
        }

        /// Returns: n-th element.
        ref inout(T) opIndex(size_t i) pure inout
        {
            return _data[i];
        }

        T opIndexAssign(T x, size_t i)
        {
            return _data[i] = x;
        }

        /// Sets size to zero, but keeps allocated buffers.
        void clearContents()
        {
            _size = 0;
        }

        /// Returns: Whole content of the array in one slice.
        inout(T)[] opSlice() inout
        {
            return opSlice(0, length());
        }

        /// Returns: A slice of the array.
        inout(T)[] opSlice(size_t i1, size_t i2) inout
        {
            return _data[i1 .. i2];
        }

        /// Fills the buffer with the same value.
        void fill(T x)
        {
            _data[0.._size] = x;
        }

        /// Move. Give up owner ship of the data.
        T[] releaseData()
        {
            T[] data = _data[0.._size];
            this._data = null;
            this._size = 0;
            this._allocated = 0;
            return data;
        }
    }

    private
    {
        size_t _size = 0;
        T* _data = null;
        size_t _allocated = 0;
    }
}