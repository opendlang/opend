/++
The module can be used for scripting languages to register type deserializer in the type system.
+/
module mir.ion.deser.script;

import mir.algebraic: Variant, visit;
import mir.ion.value: IonDescribedValue, IonList, IonStruct;
import mir.string_table: MirStringTable;
import mir.string_map;

/++
The type should be used as the cast target for $(LREF of scriptDeserializerHandle) instance.
+/
struct ScriptDeserializer(R)
{
    ///
    alias Handler = R function(const string[] symbolTable, scope const uint[] dynamicIndex, IonDescribedValue data) @safe pure;
    ///
    Handler handler;

    /// Compile-time deserilization symbol table
    immutable(MirStringTable!uint)* table;
}

/++
+/
ScriptDeserializer!R getScriptDeserializer(R)() @safe pure nothrow @nogc
{
    static if (__traits(hasMember, T, "deserializeFromIon"))
        static immutable keys = string[].init;
    else
        static immutable keys = serdeGetDeserializationKeysRecurse!T;

    static immutable table = MirStringTable!uint(keys);

    return typeof(return)(&scriptDeserializerHandle, table);
}

private R scriptDeserializerHandle(T, R = T)(const string[] symbolTable, scope const uint[] dynamicIndex, IonDescribedValue ionValue)
    if (isMutable!T && (is(T == R) || isMutable!R && __traits(compiles, R(T.init))))
{
    import mir.ion.deser: deserializeValue, DeserializationParams, TableKind;

    assert(symbolTable.length == dynamicIndex.length);

    T value;

    static if (__traits(hasMember, T, "deserializeFromIon"))
        enum keys = string[].init;
    else
        enum keys = serdeGetDeserializationKeysRecurse!T;

    auto params = DeserializationParams!(TableKind.immutableRuntime)(ionValue, symbolTable, dynamicIndex); 
    if (auto exception = deserializeValue!keys(params, value))
        throw exception;
    

    static if (is(T == R))
    {
        return value;
    }
    else
    {
        import core.lifetime: move;
        return R(move(value));
    }
}

/++
+/
struct ScriptTypedArray(R, ValueTypeInfo)
{
    /// Must not be null
    ScriptTypeInfo!(R, ValueTypeInfo)* next;
}

/// ditto
struct ScriptTypedArray(R)
{
    /// Must not be null
    ScriptTypeInfo!R* next;
}


/++
+/
struct ScriptTypedStruct(R, ValueTypeInfo)
{
    /// Must not be null
    ScriptTypeInfo!(R, ValueTypeInfo)* next;
}

///ditto
struct ScriptTypedStruct(R)
{
    /// Must not be null
    ScriptTypeInfo!R* next;
}

/++
+/
struct ScriptTypeInfo(R, ValueTypeInfo)
{
    ///
    alias Array = ScriptTypeInfo[];
    ///
    alias Struct = StringMap!ScriptTypeInfo;
    ///
    Variant!(
            ScriptTypedArray!(R, ValueTypeInfo),
            ScriptTypedStruct!(R, ValueTypeInfo),
            ValueTypeInfo,
            Array,
            Struct,
        ) typeInfoTree;
}


/++
+/
struct ScriptTypeInfo(R)
{
    ///
    alias Array = ScriptTypeInfo[];
    ///
    alias Struct = StringMap!ScriptTypeInfo;
    ///
    Variant!(
            ScriptTypedArray!R,
            ScriptTypedStruct!R,
            ScriptDeserializer!R,
            Array,
            Struct,
    ) typeInfoTree;

    ///
    this(TypeInfo)(ref const .ScriptTypeInfo!(R, TypeInfo) typeInfo, const ScriptDeserializer!R[ValueTypeInfo] typeInfoStruct)
    {
        alias Source = .ScriptTypeInfo!(R, TypeInfo);

        Array mapArray(const Source.Array)
        {
            import mir.array.allocation: array;
            import mir.ndslice.topology: map;
            return value.map!(((ref const elem) => typeof(this)(elem, typeInfoStruct))).array;
        }

        typeInfoTree = typeInfo.typeInfoTree.visit!(
            (ref const ScriptTypedArray!(R, ValueTypeInfo) value)
                => ScriptTypedArray!R(new typeof(this)(*value.next, typeInfoStruct)),

            (ref const ScriptTypedStruct!(R, ValueTypeInfo) value)
                => ScriptTypedStruct!R(new typeof(this)(*value.next, typeInfoStruct)),

            (ref const ValueTypeInfo value)
                => typeInfoStruct[value],

            (ref const Source.Array value)
                => mapArray(value),

            (ref const Source.Struct value)
                => Struct(value.keys, mapArray(value.values)),

        );
    }
}

/++
Params:
    R = script varialble type, should be constructable from `R[]` and `StringMap!R`
    RStruct = script associative array type, should be constructable from `(string[] keys, R[] values)`
    typeInfo =  type info
    symbolTable = ion symbol table
    ionValue = ion described value
+/
R scriptDeserializeIon(R, RStruct = StringMap!R)(const ScriptTypeInfo!R typeInfo, const string[] symbolTable, IonDescribedValue ionValue)
{
    import mir.array.allocation: array;
    import mir.ndslice.topology: map;
    import mir.ion.exception;

    const(uint)[][ScriptDeserializer!R.Handler] dynamicIndexCache;

    R rec(const ScriptTypeInfo!R typeInfo, IonDescribedValue ionValue)
    {
        return typeInfo.typeInfoTree.visit!(
            (ref const ScriptTypedArray!R value)
            {
                auto ionList = ionValue.get!IonList;
                auto length = ionList.walkLength;
                auto values = new R[length];
                size_t i;
 
                foreach (IonDescribedValue elem; ionList)
                {
                    values[i] = rec(*value.next, elem);
                    i++;
                }

                return R(values);
            },
            (ref const ScriptTypedStruct!R value)
            {
                auto ionStruct = ionValue.get!IonStruct;
                auto length = ionStruct.walkLength;
                auto keys = new string[length];
                auto values = new R[length];
                size_t i;
 
                foreach (size_t symbolId, IonDescribedValue elem; ionStruct)
                {
                    if (symbolId >= symbolTable.length)
                        throw IonErrorCode.symbolIdIsTooLargeForTheCurrentSymbolTable.ionException;
                    keys[i] = symbolTable[symbolId];
                    values[i] = rec(*value.next, elem);
                    i++;
                }

                return R(RStruct(keys, values));
            },
            (ref const ScriptDeserializer!R value) @trusted
            {
                const(uint)[] dynamicIndex;
                if (auto dynamicIndexPtr = value.handler in dynamicIndexCache)
                {
                    dynamicIndex = *dynamicIndexPtr;
                }
                else
                {
                    dynamicIndex = symbolTable.map!((key) {
                        uint id;
                        if (!value.table.get(key, id))
                            id = uint.max;
                        return id;
                    }).array;
                    dynamicIndexCache[value.handler] = dynamicIndex;
                }
                return value.handler(symbolTable, dynamicIndex, ionValue);
            },
            (ref const ScriptTypeInfo!R.Array value)
            {
                auto ionList = ionValue.get!IonList;
                auto length = value.length;
                auto values = new R[length];
                size_t i;
 
                foreach (IonDescribedValue elem; ionList)
                {
                    if (i >= length)
                        throw new Exception("scriptDeserializeIon: too many elements");

                    values[i] = rec(value[i], elem);
                    i++;
                }

                if (i < length)
                    throw new Exception("scriptDeserializeIon: not enough elements");

                return R(values);
            },
            (ref const ScriptTypeInfo!R.Struct value)
            {
                auto ionStruct = ionValue.get!IonStruct;
                auto length = value.length;
                auto keys = new string[length];
                auto values = new R[length];
                size_t i;
 
                foreach (size_t symbolId, IonDescribedValue elem; ionStruct)
                {
                    if (i >= length)
                        throw new Exception("scriptDeserializeIon: too many elements");

                    if (symbolId >= symbolTable.length)
                        throw IonErrorCode.symbolIdIsTooLargeForTheCurrentSymbolTable.ionException;

                    keys[i] = symbolTable[symbolId];
                    values[i] = rec(value.values[i], elem);
                    i++;
                }

                if (i < length)
                    throw new Exception("scriptDeserializeIon: not enough elements");

                return R(RStruct(keys, values));
            },
        );
    }

    return rec(typeInfo,ionValue);
}

unittest
{
    import mir.string_map;

    static struct R
    {
        this(R[])
        {
        }

        this(StringMap!R)
        {
        }
    }

    alias deser = scriptDeserializeIon!R;
}
