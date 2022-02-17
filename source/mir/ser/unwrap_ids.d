/++
+/
module mir.ser.unwrap_ids;

import mir.ion.exception;

/++
+/
struct UnwrapSymbolIdsSerializer(Serializer, SymbolMap)
{
    ///
    Serializer* serializer;
    ///
    SymbolMap symbolMap;

    ///
    alias serializer this;

    private void checkId(size_t id) const
    {
        if (id >= symbolMap.length)
        {
            version (D_Exceptions)
                throw IonErrorCode.symbolIdIsTooLargeForTheCurrentSymbolTable.ionException;
            else
                assert(0, IonErrorCode.symbolIdIsTooLargeForTheCurrentSymbolTable.ionErrorMsg);
        }
    }

    /++
    Performs `putKey(symbolMap[id])`
    +/
    void putKeyId(size_t id)
    {
        checkId(id);
        serializer.putKey(symbolMap[id]);
    }

    /++
    Performs `putValue(symbolMap[id])`
    +/
    void putSymbolId(size_t id)
    {
        checkId(id);
        putSymbol(symbolMap[id]);
    }

    static if (!__traits(hasMember, serializer, "putSymbol"))
    void putSymbol(scope const(char)[] str)
    {
        putValue(str);
    }

    /++
    Performs `putAnnotation(symbolMap[id])`
    +/
    void putAnnotationId(size_t id)
    {
        checkId(id);
        serializer.putAnnotation(symbolMap[id]);
    }
}

/++
+/
UnwrapSymbolIdsSerializer!(Serializer, SymbolMap)
    unwrapSymbolIds(Serializer, SymbolMap)
    (return ref Serializer serializer, SymbolMap symbolMap)
    @trusted
{
    return typeof(return)(&serializer, symbolMap);
}
