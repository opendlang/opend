module mir.ion.internal.data_holder;

package(mir) static immutable ubyte[] ionPrefix = [0xe0, 0x01, 0x00, 0xea];

private static immutable memoryOverflowMessage = "Can not allocate enough memory";

version(D_Exceptions)
{
    private static immutable memoryOverflowException = new Error(memoryOverflowMessage);
}

private static void* validatePtr()(return void* ptr)
    @safe pure @nogc
{
    import mir.utility: _expect;
    if (_expect(ptr is null, false))
    {
        version(D_Exceptions)
            throw memoryOverflowException;
        else
            assert(0, memoryOverflowMessage);
    }
    else
    {
        return ptr;
    }
}

/++
+/
struct IonTapeHolder(size_t stackAllocatedLength, bool useGC = false)
{
    ///
    ubyte[] data;

    ///
    size_t currentTapePosition;

    private align(16) ubyte[stackAllocatedLength] stackData = void;

    
    // for stack overflow validation
    version(assert) ubyte[32] ctrlStack;

    ///
    inout(ubyte)[] tapeData() inout @property
    {
        version(assert) assert(ctrlStack == ctrlStack.init);
        return data[0 .. currentTapePosition];
    }

    ///
    void adjustPosition(size_t length)
    {
        reserve(length);
        currentTapePosition += length;
    }

    ///
    @disable this(this);
    ///
    // @disable this();

    ///
    ~this()
        @trusted pure nothrow @nogc
    {
        version(assert) assert(ctrlStack == ctrlStack.init);
        import mir.internal.memory: free;
        static if (!useGC)
            if (data.ptr != stackData.ptr)
                free(data.ptr);
    }

    ///
    void initialize() @trusted
    {
        data = stackData;
        currentTapePosition = 0;
        version(assert) ctrlStack = 0;
    }

    ///
    void extend(size_t newSize)
        @trusted pure nothrow
    {
        version(assert) assert(ctrlStack == ctrlStack.init);
        import mir.internal.memory: malloc, realloc;
        import core.stdc.string: memcpy;

        if (newSize > data.length)
        {
            import mir.utility: max;
            newSize = max(newSize, data.length * 2);
            sizediff_t shift;
            if (data.ptr != stackData.ptr)
            {
                static if (useGC)
                    data.length = newSize;
                else
                    data = cast(ubyte[]) realloc(data.ptr, newSize).validatePtr[0 .. newSize];
            }
            else
            {
                static if (useGC)
                {
                    auto ptr = new ubyte[newSize];
                    ptr[0 .. data.length] = data;
                    data = ptr;
                }
                else
                {
                    auto ptr = cast(ubyte*) malloc(newSize).validatePtr;
                    memcpy(ptr, stackData.ptr, stackData.length);
                    data = ptr[0 .. newSize];
                }
            }
        }
    }

    ///
    void reserve(size_t size)
    {
        version(assert) assert(ctrlStack == ctrlStack.init);
        assert(currentTapePosition <= data.length);

        import mir.utility: max;

        import mir.internal.memory: malloc, realloc;
        import core.stdc.string: memcpy;

        if (currentTapePosition + size > data.length)
        {
            auto newSize = data.length + max(size, data.length);
            if (data.ptr != stackData.ptr)
            {
                static if (useGC)
                    data.length = newSize;
                else
                    data = cast(ubyte[]) realloc(data.ptr, newSize).validatePtr[0 .. newSize];
            }
            else
            {
                static if (useGC)
                {
                    auto ptr = new ubyte[newSize];
                    ptr[0 .. data.length] = data;
                    data = ptr;
                }
                else
                {
                    auto ptr = malloc(newSize).validatePtr;
                    memcpy(ptr, stackData.ptr, stackData.length);
                    data = cast(ubyte[])ptr[0 .. newSize];
                }
            }
        }
    }
}

IonTapeHolder!(stackAllocatedLength, useGC) ionTapeHolder(size_t stackAllocatedLength, bool useGC = false)()
    @trusted
{
    typeof(return) ret = void;
    ret.data = null;
    ret.currentTapePosition = 0;
    version(assert) ret.ctrlStack = 0;
    return ret;
}
