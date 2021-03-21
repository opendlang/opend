/++
+/
module mir.ion.ser.unwrap_ids;

private static immutable UnwrapSymbolIdsSerializerExceptionMsg = "Symbol ID exceed symbol table";

version (D_Exceptions)
{
    private static immutable UnwrapSymbolIdsSerializerException = new Exception(UnwrapSymbolIdsSerializerExceptionMsg);
}

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
                throw UnwrapSymbolIdsSerializerException;
            else
                assert(0, UnwrapSymbolIdsSerializerExceptionMsg);
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
    void putValueId(size_t id)
    {
        checkId(id);
        serializer.putValue(symbolMap[id]);
    }

    static if (__traits(hasMember, *serializer, "putAnnotation"))
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
