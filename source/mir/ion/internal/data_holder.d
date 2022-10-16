module mir.ion.internal.data_holder;

static immutable ubyte[] ionPrefix = [0xe0, 0x01, 0x00, 0xea];

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
    ubyte[] allData;

    ///
    size_t currentTapePosition;
    alias _currentLength = currentTapePosition;

    private align(16) ubyte[stackAllocatedLength] stackData = void;

    
    // for stack overflow validation
    version(assert) ubyte[32] ctrlStack;

    ///
    inout(ubyte)[] data() inout @property
    {
        version(LDC) pragma(inline, true);
        version(assert) assert(ctrlStack == ctrlStack.init);
        return allData[0 .. currentTapePosition];
    }

    ///
    void adjustPosition(size_t length)
    {
        version(LDC) pragma(inline, true);
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
        version(LDC) pragma(inline, true);
        version(assert) assert(ctrlStack == ctrlStack.init);
        import mir.internal.memory: free;
        static if (!useGC)
            if (allData.ptr != stackData.ptr)
                free(allData.ptr);
    }

    ///
    void put(scope const(ubyte)[] data)
    {
        version(LDC) pragma(inline, true);
        import core.stdc.string;
        auto target = reserve(data.length).ptr;
        if (__ctfe)
            target[0 ..data.length] = data;
        else
            memcpy(target, data.ptr, data.length);
        currentTapePosition += data.length;
    }

    ///
    void initialize() scope @trusted
    {
        version(LDC) pragma(inline, true);
        allData = stackData;
        currentTapePosition = 0;
        version(assert) ctrlStack = 0;
    }

    ///
    void extend(size_t newSize)
        @trusted pure nothrow
    {
        version(LDC) pragma(inline, true);
        version(assert) assert(ctrlStack == ctrlStack.init);
        import mir.internal.memory: malloc, realloc;
        import core.stdc.string: memcpy;

        if (newSize > allData.length)
        {
            import mir.utility: max;
            newSize = max(newSize, allData.length * 2);
            sizediff_t shift;
            if (allData.ptr != stackData.ptr)
            {
                static if (useGC)
                    allData.length = newSize;
                else
                    allData = cast(ubyte[]) realloc(allData.ptr, newSize).validatePtr[0 .. newSize];
            }
            else
            {
                static if (useGC)
                {
                    auto ptr = new ubyte[newSize];
                    ptr[0 .. allData.length] = allData;
                    allData = ptr;
                }
                else
                {
                    auto ptr = cast(ubyte*) malloc(newSize).validatePtr;
                    memcpy(ptr, stackData.ptr, stackData.length);
                    allData = ptr[0 .. newSize];
                }
            }
        }
    }

    ///
    auto reserve(size_t size)
    {
        version(LDC) pragma(inline, true);
        version(assert) assert(ctrlStack == ctrlStack.init);
        assert(currentTapePosition <= allData.length);

        import mir.utility: max;

        import mir.internal.memory: malloc, realloc;
        import core.stdc.string: memcpy;

        if (currentTapePosition + size > allData.length)
        {
            auto newSize = allData.length + max(size, allData.length);
            if (allData.ptr != stackData.ptr)
            {
                static if (useGC)
                    allData.length = newSize;
                else
                    allData = cast(ubyte[]) realloc(allData.ptr, newSize).validatePtr[0 .. newSize];
            }
            else
            {
                static if (useGC)
                {
                    auto ptr = new ubyte[newSize];
                    ptr[0 .. allData.length] = allData;
                    allData = ptr;
                }
                else
                {
                    auto ptr = malloc(newSize).validatePtr;
                    memcpy(ptr, stackData.ptr, stackData.length);
                    allData = cast(ubyte[])ptr[0 .. newSize];
                }
            }
        }
        return allData[currentTapePosition .. currentTapePosition + size];
    }
}

IonTapeHolder!(stackAllocatedLength, useGC) ionTapeHolder(size_t stackAllocatedLength, bool useGC = false)()
    @trusted
{
    version(LDC) pragma(inline, true);
    typeof(return) ret = void;
    ret.allData = null;
    ret.currentTapePosition = 0;
    version(assert) ret.ctrlStack = 0;
    return ret;
}
