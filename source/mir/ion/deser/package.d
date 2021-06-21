/++
$(H4 High level deserialization API)

Macros:
IONREF = $(REF_ALTTEXT $(TT $2), $2, mir, ion, $1)$(NBSP)
+/
module mir.ion.deser;

import mir.ion.deser.low_level;
import mir.ion.exception;
import mir.ion.symbol_table;
import mir.ion.type_code;
import mir.ion.value;
import mir.small_array;
import mir.small_string;
import mir.utility: _expect;
import std.traits: ForeachType, hasUDA, Unqual;

public import mir.serde;

private enum isSmallString(T) = is(T == SmallString!N, size_t N);

private string unexpectedIonTypeCode(string msg = "Unexpected Ion type code")(IonTypeCode code)
    @safe pure nothrow @nogc
{
    import std.traits: EnumMembers;
    import mir.conv: to;
    static immutable exc(IonTypeCode code) = msg ~ " " ~ code.to!string;

    switch (code)
    {
        foreach (member; EnumMembers!IonTypeCode)
        {case member:
            return unqualException(exc!(T, member));
        }
        default:
            static immutable ret = "Wrong encoding of Ion type code";
            return ret;
    }
}

IonException deserializeScoped(T)(IonDescribedValue data, ref T value)
    if (isFirstOrderSerdeType!T)
{
    return deserializeScopedValueImpl(data, value).ionException;
}

IonException deserializeScoped(T)(IonDescribedValue data, scope TableParams!true params, ref T value)
    if (isFirstOrderSerdeType!T)
{
    return deserializeScoped(data, value);
}

IonException deserializeValue_(T)(IonDescribedValue data, ref T value)
    if (isFirstOrderSerdeType!T)
{
    return deserializeValueImpl(data, value).ionException;
}

IonException deserializeValue_(T)(IonDescribedValue data, scope TableParams!true params, ref T value)
    if (isFirstOrderSerdeType!T)
{
    return deserializeValue_(data, value);
}

template deserializeListToScopedBuffer(alias impl, bool exteneded)
{
    import mir.appender: ScopedBuffer;
    private IonException deserializeListToScopedBuffer(E, size_t bytes)(IonDescribedValue data, scope TableParams!exteneded params, ref ScopedBuffer!(E, bytes) buffer)
    {
        if (_expect(data.descriptor.type != IonTypeCode.list, false))
            return IonErrorCode.expectedListValue.ionException;
        foreach (IonErrorCode error, IonDescribedValue ionElem; data.trustedGet!IonList)
        {
            if (_expect(error, false))
                return error.ionException;
            E value;
            if (auto exception = impl(ionElem, params, value))
                return exception;
            import core.lifetime: move;
            buffer.put(move(value));
        }
        return null;
    }
}
private alias AliasSeq(T...) = T;

template TableParams(bool exteneded)
{
    static if (exteneded)
    {
        // realSymbolTable, dynamicIndex
        alias TableParams = AliasSeq!(const char[][] , const uint[]);
    }
    else
    {
        alias TableParams = AliasSeq!();
    }
}

private template prepareSymbolId(string[] symbolTable, bool exteneded)
{
    static if (!exteneded)
        static immutable table = symbolTable;

    @safe pure nothrow @nogc
    private bool prepareSymbolId(scope TableParams!exteneded tableParams, ref size_t symbolId)
    {
        static if (exteneded)
        {
            alias table = tableParams[0];
            if (symbolId >= tableParams[1].length)
                return false;
            symbolId = tableParams[1][symbolId];
        }
        return symbolId < table.length;
    }
}

static immutable exc(T, string member, int line = __LINE__) = new IonException("mir.ion: non-optional member '" ~ member ~ "' in " ~ T.stringof ~ " is missing.", __FILE__, line);
static immutable excm(T, string member, int line = __LINE__) = new IonException("mir.ion: multiple keys for member '" ~ member ~ "' in " ~ T.stringof ~ " are not allowed.", __FILE__, line);

static immutable cantConstructNullValueOfType(T, int line = __LINE__) = new IonException("Can't construct null value of type" ~ T.stringof, __FILE__, line);
static immutable cantConstructObjectExc(T, int line = __LINE__) = new IonException(T.stringof ~ " must be either not null or have a default constructor.", __FILE__, line);
static immutable cantDeserilizeTFromIonStruct(T, int line = __LINE__) = new IonException("Can't deserilize " ~ T.stringof ~ " from IonStruct", __FILE__, line);
static immutable cantDesrializeUnexpectedDescriptorType(T, int line = __LINE__) = new IonException("Can't desrialize " ~ T.stringof ~ ". Unexpected descriptor type.", __FILE__, line);
static immutable unexpectedAnnotationWhenDeserializing(T, int line = __LINE__) = new IonException("Unexpected annotation when deserializing " ~ T.stringof, __FILE__, line);
static immutable unexpectedIonTypeCodeFor(T, int line = __LINE__) = new IonException("Unexpected IonTypeCode for " ~ T.stringof, __FILE__, line);
static immutable unexpectedKeyWhenDeserializing(T, int line = __LINE__) = new IonException("Unexpected key when deserializing " ~ T.stringof, __FILE__, line);
static immutable unexpectedSymbolIdWhenDeserializing(T, int line = __LINE__) = new IonException("Unexpected symbol ID when deserializing " ~ T.stringof, __FILE__, line);
static immutable unusedAnnotation(T, int line = __LINE__) = new IonException("Unused annotation for " ~ T.stringof, __FILE__, line);

/++
Deserialize aggregate value using compile time symbol table
+/
template deserializeValue(string[] symbolTable, bool exteneded = false)
{
    static if (!exteneded)
        static immutable table = symbolTable;

    private IonException deserializeAnnotations(T)(
        ref IonAnnotations annotations,
        scope TableParams!exteneded tableParams,
        ref T value)
    {
        static if (exteneded)
            alias table = tableParams[0];
        static foreach (member; serdeGetAnnotationMembersIn!T)
        {{
            if (annotations.empty)
                return IonErrorCode.missingAnnotation.ionException;
            size_t symbolId;
            if (auto error = annotations.pick(symbolId))
                return error.ionException;
            if (symbolId >= table.length)
                return IonErrorCode.symbolIdIsTooLargeForTheCurrentSymbolTable.ionException;
            static if (__traits(compiles, {__traits(getMember, value, member) = table[id];}))
            {
                __traits(getMember, value, member) = table[symbolId];
            }
            else
            {
                __traits(getMember, value, member) = table[symbolId].idup;
            }
        }}
        return null;
    }

    /++
    Deserialize aggregate value
    Params:
        data = $(IONREF value, IonDescribedValue)
        tableParams = symbol $(LREF TableParams) 
        value = value to deserialize
        optAnnotations = (optional) $(MREF mir,ion,value, IonAnnotations)
    Returns: `IonException`
    +/
    IonException deserializeValue(T, Annotations...)(IonDescribedValue data, scope TableParams!exteneded tableParams, ref T value, Annotations optAnnotations)
        if (!isFirstOrderSerdeType!T && (is(Annotations == AliasSeq!()) || is(Annotations == AliasSeq!IonAnnotations)))
    {
        import mir.algebraic: isVariant;
        import mir.internal.meta: Contains;
        import mir.ndslice.slice: Slice, SliceKind;
        import mir.rc.array: RCArray, RCI;
        import mir.string_map : isStringMap;
        import std.meta: anySatisfy, Filter, templateAnd, templateNot, templateOr;
        import std.traits: isArray, isSomeString, isAssociativeArray;

        static if (exteneded)
            alias table = tableParams[0];

        static if (__traits(hasMember, value, "deserializeFromIon"))
        {
            return value.deserializeFromIon(table, data);
        }
        else
        static if (is(T : SmallArray!(E, maxLength), E, size_t maxLength))
        {
            if (data.descriptor.type == IonTypeCode.list)
            {
                foreach (error, ionElem; data.trustedGet!IonList)
                {
                    if (_expect(error, false))
                        return error.ionException;
                    if (value._length == maxLength)
                        return IonErrorCode.smallArrayOverflow.ionException;
                    E elem;
                    if (auto exception = .deserializeValue!(symbolTable, exteneded)(ionElem, tableParams, elem))
                        return exception;
                    import core.lifetime: move;
                    value.trustedAppend(move(elem));
                }
                return null;
            }
            else
            if (data.descriptor.type == IonTypeCode.null_)
            {
                return null;
            }
            return IonErrorCode.expectedListValue.ionException;
        }
        else
        static if (is(T == D[], D))
        {
            alias E = Unqual!D;
            if (data.descriptor.type == IonTypeCode.list)
            {
                import mir.appender: ScopedBuffer;

                if (false)
                {
                    ScopedBuffer!E buffer;
                    if (auto exception = deserializeListToScopedBuffer!(.deserializeValue!(symbolTable, exteneded), exteneded)(data, tableParams, buffer))
                        return exception;
                }

                return () @trusted {
                    import std.array: uninitializedArray;
                    ScopedBuffer!E buffer = void;
                    buffer.initialize;
                    if (auto exception = deserializeListToScopedBuffer!(.deserializeValue!(symbolTable, exteneded), exteneded)(data, tableParams, buffer))
                        return exception;
                    auto ar = uninitializedArray!(E[])(buffer.length);
                    buffer.moveDataAndEmplaceTo(ar);
                    value = cast(T) ar;
                    return null;
                }();
            }
            else
            if (data.descriptor.type == IonTypeCode.null_)
            {
                value = null;
                return null;
            }
            return IonErrorCode.expectedListValue.ionException;
        }
        else
        static if (is(T == D[N], D, size_t N))
        {
            if (data.descriptor.type != IonTypeCode.list)
                return IonErrorCode.expectedListValue.ionException;
            size_t i;
            foreach (IonErrorCode error, IonDescribedValue ionElem; data.trustedGet!IonList)
            {
                if (_expect(error, false))
                    return error.ionException;
                if (i >= N)
                    return IonErrorCode.tooManyElementsForStaticArray.ionException;
                if (auto exception = .deserializeValue!(symbolTable, exteneded)(ionElem, tableParams, value[i++]))
                    return exception;
            }
            if (i < N)
                return IonErrorCode.notEnoughElementsForStaticArray.ionException;
            return null;
        }
        else
        static if (is(T == V[K], K, V))
        {
            import mir.conv;
            if (data.descriptor.type != IonTypeCode.null_ && data.descriptor.type != IonTypeCode.struct_)
                return IonErrorCode.expectedIonStructForAnAssociativeArrayDeserialization.ionException;
            if (data.descriptor.L == 0xF)
            {
                value = null;
                return null;
            }
            auto ionValue = data.trustedGet!IonStruct;

            foreach (IonErrorCode error, size_t symbolId, IonDescribedValue elem; ionValue)
            {
                if (error)
                    return error.ionException;
                if (symbolId >= table.length)
                    return IonErrorCode.symbolIdIsTooLargeForTheCurrentSymbolTable.ionException;
                import mir.conv: to;
                if (auto errorMsg = .deserializeValue!(symbolTable, exteneded)(elem, tableParams, value.require(table[symbolId].to!K)))
                    return errorMsg;
            }
            return null;
        }
        else
        static if (isStringMap!T)
        {
            import mir.conv;
            if (data.descriptor.type != IonTypeCode.null_ && data.descriptor.type != IonTypeCode.struct_)
                return IonErrorCode.expectedIonStructForAnAssociativeArrayDeserialization.ionException;
            if (data.descriptor.L == 0xF)
            {
                value = null;
                return null;
            }
            auto ionValue = data.trustedGet!IonStruct;

            foreach (IonErrorCode error, size_t symbolId, IonDescribedValue elem; ionValue)
            {
                if (error)
                    return error.ionException;
                if (symbolId >= table.length)
                    return IonErrorCode.symbolIdIsTooLargeForTheCurrentSymbolTable.ionException;
                import mir.conv: to;
                if (auto errorMsg = .deserializeValue!(symbolTable, exteneded)(elem, tableParams, value.require(table[symbolId].to!string)))
                    return errorMsg;
            }
            return null;
        }
        else
        static if (is(T == Slice!(D*, N, kind), D, size_t N, SliceKind kind))
        {
            import mir.ndslice.topology: asKindOf;

            static if (N == 1)
            {
                import mir.ndslice.slice: sliced;

                D[] array;
                if (auto ret = deserializeValue(data, tableParams, array))
                    return ret;
                value = array.sliced.asKindOf!kind;
                return null;
            }
            // TODO: create a single allocation algorithm
            else
            {
                import mir.ndslice.fuse: fuse;

                Slice!(D*, N - 1)[] array;
                if (auto ret = deserializeValue(data, tableParams, array))
                    return ret;
                value = array.fuse.asKindOf!kind;
                return null;
            }
        }
        else
        static if (is(T == Slice!(RCI!D, N, kind), D, size_t N, SliceKind kind))
        {
            import mir.ndslice.topology: asKindOf;

            static if (N == 1)
            {
                RCArray!D array;
                if (auto ret = deserializeValue(data, tableParams, array))
                    return ret;
                value = array.moveToSlice.asKindOf!kind;
                return null;
            }
            // TODO: create a single allocation algorithm
            else
            {
                import mir.ndslice.fuse: rcfuse;

                RCArray!(Slice!(RCI!D, N - 1)) array;
                if (auto ret = deserializeValue(data, tableParams, array))
                    return ret;
                value = array.moveToSlice.rcfuse.asKindOf!kind;
                return null;
            }
        }
        else
        static if (is(T == RCArray!D, D))
        {
            alias E = Unqual!D;
            if (data.descriptor.type == IonTypeCode.list)
            {
                import mir.appender: ScopedBuffer;

                if (false)
                {
                    ScopedBuffer!E buffer;
                    if (auto exception = deserializeListToScopedBuffer!(.deserializeValue!(symbolTable, exteneded), exteneded)(data, tableParams, buffer))
                        return exception;
                }

                return ()@trusted @nogc {
                    ScopedBuffer!E buffer = void;
                    buffer.initialize;
                    if (auto exception = deserializeListToScopedBuffer!(.deserializeValue!(symbolTable, exteneded), exteneded)(data, tableParams, buffer))
                        return exception;
                    auto ar = RCArray!E(buffer.length, false);
                    buffer.moveDataAndEmplaceTo(ar[]);
                    static if (__traits(compiles, value = move(ar)))
                        value = move(ar);
                    else () @trusted {
                        value = ar.opCast!T;
                    } ();
                    return null;
                } ();
            }
            else
            if (data.descriptor.type == IonTypeCode.null_)
            {
                value = null;
                return null;
            }
            return IonErrorCode.expectedListValue.ionException;
        }
        else
        static if (hasUDA!(T, serdeProxy))
        {
            import mir.conv: to;
            import core.lifetime: move;
            serdeGetProxy!T temporal;
            static if (hasUDA!(T, serdeScoped))
                static if (__traits(compiles, .deserializeScoped(data, temporal)))
                    alias impl = .deserializeScoped;
                else
                    alias impl = .deserializeValue!(symbolTable, exteneded);
            else
                alias impl = .deserializeValue!(symbolTable, exteneded);

            if (auto exception = impl(data, tableParams, temporal, optAnnotations))
                return exception;

            value = to!T(move(temporal));
            return null;
        }
        else
        static if (isVariant!T)
        {
            static if (getAlgebraicAnnotationsOfVariant!T.length)
            {
                static if (Annotations.length)
                {
                    alias annotations = optAnnotations[0];
                }
                else
                {
                    IonAnnotations annotations;
                    if (data.descriptor.type == IonTypeCode.annotations)
                    {
                        if (auto error = data.trustedGet!IonAnnotationWrapper.unwrap(annotations, data))
                        {
                            return error.ionException;
                        }
                    }
                    
                }

                IonException retNull() @property
                {
                    return annotations.empty ? null : IonErrorCode.unusedAnnotations.ionException;
                }
            }
            else
            {
                IonException retNull;
            }

            alias Types = T.AllowedTypes;
            alias contains = Contains!Types;

            switch (data.descriptor.type)
            {
                static if (contains!(typeof(null)))
                {
                    case IonTypeCode.null_:
                    {
                        value = null;
                        return retNull;
                    }
                }

                static if (contains!bool)
                {
                    case IonTypeCode.bool_:
                    {
                        value = data.trustedGet!bool;
                        return retNull;
                    }
                }

                static if (contains!string)
                {
                    case IonTypeCode.string:
                    {
                        string str;
                        if (auto exception = .deserializeValue!(symbolTable, exteneded)(data, str))
                            return exception;
                        value = str;
                        return retNull;
                    }
                }
                else
                static if (Filter!(isSmallString, Types).length == 1)
                {
                    case IonTypeCode.string:
                    {
                        Filter!(isSmallString, Types)[0] str;
                        if (auto exception = .deserializeValue!(symbolTable, exteneded)(data, str))
                            return exception;
                        value = str;
                        return retNull;
                    }
                }

                static if (contains!long)
                {
                    case IonTypeCode.nInt:
                    case IonTypeCode.uInt:
                    {
                        long number;
                        if (auto exception = deserializeValue_(data, number))
                            return exception;
                        value = number;
                        return retNull;
                    }
                }

                static if (contains!double)
                {
                    static if (!contains!long)
                    {
                        case IonTypeCode.nInt:
                        case IonTypeCode.uInt:
                    }
                    case IonTypeCode.float_:
                    case IonTypeCode.decimal:
                    {
                        double number;
                        if (auto exception = deserializeValue_(data, number))
                            return exception;
                        value = number;
                        return retNull;
                    }
                }

                static if (anySatisfy!(templateAnd!(isArray, templateNot!isSomeString), Types))
                {
                    case IonTypeCode.list:
                    {
                        alias ArrayTypes = Filter!(templateAnd!(isArray, templateNot!isSomeString), Types);
                        static assert(ArrayTypes.length == 1, ArrayTypes.stringof);
                        ArrayTypes[0] array;
                        if (auto exception = .deserializeValue!(symbolTable, exteneded)(data, array))
                            return exception;
                        import core.lifetime: move;
                        value = move(array);
                        return retNull;
                    }
                }

                static if (getAlgebraicAnnotationsOfVariant!T.length || anySatisfy!(templateOr!(isStringMap, isAssociativeArray), Types))
                {
                    case IonTypeCode.struct_:
                    {
                        static if (getAlgebraicAnnotationsOfVariant!T.length)
                        {
                            if (!annotations.empty)
                            {
                                size_t symbolId;
                                if (auto error = annotations.pick(symbolId))
                                    return error.ionException;

                                auto originalId = symbolId;
                                if (!prepareSymbolId!(symbolTable, exteneded)(tableParams, symbolId))
                                    goto Default;

                                switch (symbolId)
                                {
                                    static foreach (VT; Types)
                                    static if (serdeHasAlgebraicAnnotation!VT)
                                    {
                                        case findKey(symbolTable, serdeGetAlgebraicAnnotation!VT):
                                        {
                                            VT object;
                                            if (auto exception = .deserializeValue!(symbolTable, exteneded)(data, tableParams, object, annotations))
                                                return exception;
                                            import core.lifetime: move;
                                            value = move(object);
                                            return null;
                                        }
                                    }
                                    Default:
                                    default:
                                        static if (__traits(hasMember, T, "serdeUnexpectedAnnotationHandler"))
                                            value.serdeUnexpectedAnnotationHandler(originalId < table.length ? table[originalId] : "<@unknown symbol@>");
                                        else
                                            return unqualException(unexpectedAnnotationWhenDeserializing!T);
                                }
                            }
                        }
                        
                        static if (anySatisfy!(templateOr!(isStringMap, isAssociativeArray), Types))
                        {
                            static if (anySatisfy!(isStringMap, Types))
                            {
                                alias isMapType = isStringMap;
                            }
                            else
                            {
                                alias isMapType = isAssociativeArray;
                            }

                            alias AATypes = Filter!(isMapType, Types);
                            static assert(AATypes.length == 1, AATypes.stringof);
                            AATypes[0] object;
                            if (auto exception = .deserializeValue!(symbolTable, exteneded)(data, tableParams, object))
                                return exception;
                            value = object;
                            return retNull;
                        }
                        else
                        {
                            return unqualException(cantDeserilizeTFromIonStruct!T);
                        }
                    }
                }

                default:
                    return unqualException(unexpectedIonTypeCodeFor!T);
            }

            // return visit!((auto ref v) => deserializeValue!(symbolTable, exteneded)(data, tableParams, annotations));
        }
        else
        static if (isNullable!T && !isAlgebraicAliasThis!T)
        {
            // TODO: check that descriptor.type correspond underlaying type
            if (data.descriptor.L == 0xF)
            {
                value.nullify;
                return null;
            }

            typeof(value.get) payload;
            if (auto exception = .deserializeValue!(symbolTable, exteneded)(data, tableParams, payload))
                return exception;
            value = payload;
            return null;
        }
        else
        {
            static if (serdeGetAnnotationMembersIn!T.length || Annotations.length)
            {
                static if (Annotations.length)
                {
                    alias annotations = optAnnotations[0];
                }
                else
                {
                    if (data.descriptor.type != IonTypeCode.annotations)
                    {
                        return unqualException(cantDesrializeUnexpectedDescriptorType!T);
                    }
                    
                    IonAnnotations annotations;
                    if (auto error = data.trustedGet!IonAnnotationWrapper.unwrap(annotations, data))
                    {
                        return error.ionException;
                    }
                }

                if (auto error = deserializeAnnotations(annotations, tableParams, value))
                {
                    return error;
                }
            }
            else
            {
                alias annotations = AliasSeq!();
            }

            static if (isAlgebraicAliasThis!T)
            {
                return .deserializeValue!(symbolTable, exteneded)(data, tableParams, __traits(getMember, value, __traits(getAliasThis, T)), annotations);
            }
            else
            {
                static if (serdeGetAnnotationMembersIn!T.length || Annotations.length)
                {
                    if (!annotations.empty)
                    {
                        return unqualException(unusedAnnotation!T);
                    }
                }

                if (data.descriptor.L == 0xF)
                {
                    if (data.descriptor.type != IonTypeCode.struct_ && data.descriptor.type != IonTypeCode.null_)
                        goto WrongKindL;
                    static if (__traits(compiles, value = null))
                    {
                        value = null;
                        return null; 
                    }
                    else
                    {
                        return unqualException(cantConstructNullValueOfType!T);
                    }
                }

                if (data.descriptor.type != IonTypeCode.struct_)
                {
                WrongKindL:
                    return unqualException(cantDesrializeUnexpectedDescriptorType!T);
                }

                static if (is(T == interface) || is(T == class))
                {
                    if (value is null)
                    {
                        static if (is(T == class))
                        {
                            static if (__traits(compiles, new T()))
                            {
                                value == new T();
                            }
                        }
                        else
                        {
                            return cantConstructObjectExc!T;
                        }
                    }
                }

                auto ionValue = data.trustedGet!IonStruct;

                SerdeFlags!T requiredFlags;

                static if (hasUDA!(T, serdeOrderedIn))
                {
                    SerdeOrderedDummy!T temporal;
                    if (auto exception = .deserializeValue!(symbolTable, exteneded)(data, tableParams, temporal))
                        return exception;
                    temporal.serdeFinalizeTarget(value, requiredFlags);
                }
                else
                {
                    alias impl = deserializeValueMember!(symbolTable, exteneded);
                    
                    enum hasUnexpectedKeyHandler = __traits(hasMember, T, "serdeUnexpectedKeyHandler");

                    import std.meta: staticMap, aliasSeqOf;
                    static if (hasUDA!(T, serdeRealOrderedIn))
                    {
                        static assert (!hasUnexpectedKeyHandler, "serdeRealOrderedIn aggregate type attribute is not compatible with `serdeUnexpectedKeyHandler` method");
                        static foreach (member; serdeFinalProxyDeserializableMembers!T)
                        {{
                            enum keys = serdeGetKeysIn!(__traits(getMember, value, member));
                            static if (keys.length)
                            {
                                foreach (IonErrorCode error, size_t symbolId, IonDescribedValue elem; ionValue)
                                {
                                    if (error)
                                        return error.ionException;
                                    prepareSymbolId!(symbolTable, exteneded)(tableParams, symbolId);

                                    switch(symbolId)
                                    {
                                        static foreach (key; keys)
                                        {
                                        case findKey(symbolTable, key):
                                        }
                                            if (auto mexp = impl!member(elem, tableParams, value, requiredFlags))
                                                return mexp;
                                            break;
                                        default:
                                    }
                                }
                            }

                            static if (!hasUDA!(__traits(getMember, value, member), serdeOptional))
                                if (!__traits(getMember, requiredFlags, member))
                                    return unqualException(exc!(T, member));
                        }}
                    }
                    else
                    {
                        foreach (IonErrorCode error, size_t symbolId, IonDescribedValue elem; ionValue)
                        {
                            if (error)
                                return error.ionException;
                            auto originalId = symbolId;
                            if (!prepareSymbolId!(symbolTable, exteneded)(tableParams, symbolId))
                                goto Default;
                            S: switch(symbolId)
                            {
                                static foreach (member; serdeFinalProxyDeserializableMembers!T)
                                {{
                                    enum keys = serdeGetKeysIn!(__traits(getMember, value, member));
                                    static if (keys.length)
                                    {
                                        static foreach (key; keys)
                                        {
                                case findKey(symbolTable, key):
                                        }
                                    if (auto mexp = impl!member(elem, tableParams, value, requiredFlags))
                                        return mexp;
                                    break S;
                                    }
                                }}
                                Default:
                                default:
                                    static if (hasUnexpectedKeyHandler)
                                        value.serdeUnexpectedKeyHandler(originalId < table.length ? table[originalId] : "<@unknown symbol@>");
                                    else
                                        return unqualException(unexpectedKeyWhenDeserializing!T);
                            }
                        }

                        static foreach (member; __traits(allMembers, SerdeFlags!T))
                            static if (!hasUDA!(__traits(getMember, value, member), serdeOptional))
                                if (!__traits(getMember, requiredFlags, member))
                                    return unqualException(exc!(T, member));
                    }
                }

                static if(__traits(hasMember, T, "serdeFinalizeWithFlags"))
                {
                    value.serdeFinalizeWithFlags(requiredFlags);
                }
                static if(__traits(hasMember, T, "serdeFinalize"))
                {
                    value.serdeFinalize();
                }
                return null;
            }
        }
    }

    ///
    alias deserializeValue = .deserializeValue_;
}

private template deserializeValueMember(string[] symbolTable, bool exteneded)
{

    static if (!exteneded)
        static immutable table = symbolTable;

    ///
    IonException deserializeValueMember(string member, Data, T, Context...)(Data data, scope TableParams!exteneded tableParams, ref T value, ref SerdeFlags!T requiredFlags, ref Context context)
    {
        import core.lifetime: move;
        import mir.conv: to;
        import mir.reflection: hasField;

        enum likeList = hasUDA!(__traits(getMember, value, member), serdeLikeList);
        enum likeStruct  = hasUDA!(__traits(getMember, value, member), serdeLikeStruct);
        enum hasProxy = hasUDA!(__traits(getMember, value, member), serdeProxy);

        alias Member = serdeDeserializationMemberType!(T, member);

        static if (hasProxy)
            alias Temporal = serdeGetProxy!(__traits(getMember, value, member));
        else
            alias Temporal = Member;

        enum hasScoped = hasUDA!(__traits(getMember, value, member), serdeScoped) || hasScoped!Temporal;

        enum hasTransform = hasUDA!(__traits(getMember, value, member), serdeTransformIn);

        static if (hasTransform)
            alias transform = serdeGetTransformIn!(__traits(getMember, value, member));

        static assert (likeList + likeStruct <= 1, T.stringof ~ "." ~ member ~ " can't have both @serdeLikeStruct and @serdeLikeList attributes");
        static assert (hasProxy >= likeStruct, T.stringof ~ "." ~ member ~ " should have a Proxy type for deserialization");
        static assert (hasProxy >= likeList, T.stringof ~ "." ~ member ~ " should have a Proxy type for deserialization");

        static if (hasScoped)
        {
            static if (__traits(compiles, { Temporal temporal; deserializeScoped(data, temporal); }))
            {
                alias impl = deserializeScoped;
            }
            else
            {
                alias impl = .deserializeValue!(symbolTable, exteneded);
            }
        }
        else
        {
            alias impl = .deserializeValue!(symbolTable, exteneded);
        }

        static if (!hasUDA!(__traits(getMember, value, member), serdeAllowMultiple))
            if (__traits(getMember, requiredFlags, member))
                return unqualException(excm!(T, member));

        __traits(getMember, requiredFlags, member) = true;

        static if (likeList)
        {
            if (data.descriptor.type == IonTypeCode.list)
            {
                foreach (error, ionElem; data.trustedGet!IonList)
                {
                    if (_expect(error, false))
                        return error.ionException;
                    Temporal elem;
                    if (auto exception = impl(ionElem, tableParams, elem, context))
                        return exception;
                    import core.lifetime: move;
                    __traits(getMember, value, member).put(move(elem));
                }
            }
            else
            if (data.descriptor.type == IonTypeCode.null_)
            {
            }
            else
            {
                return IonErrorCode.expectedListValue.ionException;
            }
            static if (hasTransform)
            {
                static if (hasField!(T, member))
                {
                    transform(__traits(getMember, value, member));
                }
                else
                {
                    auto temporal = __traits(getMember, value, member);
                    transform(temporal);
                    __traits(getMember, value, member) = move(temporal);
                }
            }
            return null;
        }
        else
        static if (likeStruct)
        {
            if (data.descriptor.type == IonTypeCode.struct_)
            {
                foreach (error, symbolId, ionElem; data.trustedGet!IonStruct)
                {
                    if (_expect(error, false))
                        return error.ionException;

                    Temporal elem;
                    if (auto exception = impl(ionElem, tableParams, elem, context))
                        return exception;
                    import core.lifetime: move;

                    static if (exteneded)
                        alias table = tableParams[0];

                    if (symbolId >= table.length)
                        return unqualException(unexpectedSymbolIdWhenDeserializing!T);

                    static if (__traits(compiles, {__traits(getMember, value, member)[table[symbolId]] = move(elem);}))
                    {
                        __traits(getMember, value, member)[table[symbolId]] = move(elem);
                    }
                    else
                    {
                        __traits(getMember, value, member)[table[symbolId].idup] = move(elem);
                    }
                }
            }
            else
            if (data.descriptor.type == IonTypeCode.null_)
            {
            }
            else
            {
                return IonErrorCode.expectedStructValue.ionException;
            }
            static if (hasTransform)
            {
                static if (hasField!(T, member))
                {
                    transform(__traits(getMember, value, member));
                }
                else
                {
                    auto temporal2 = __traits(getMember, value, member);
                    transform(temporal2);
                    __traits(getMember, value, member) = move(temporal2);
                }
            }
            return null;
        }
        else
        static if (hasProxy)
        {
            Temporal proxy;
            if (auto exception = impl(data, tableParams, proxy, context))
                return exception;
            auto temporal = to!(serdeDeserializationMemberType!(T, member))(move(proxy));
            static if (hasTransform)
                transform(temporal);
            __traits(getMember, value, member) = move(temporal);
            return null;
        }
        else
        static if (hasField!(T, member))
        {
            if (auto exception = impl(data, tableParams, __traits(getMember, value, member), context))
                return exception;
            static if (hasTransform)
                transform(__traits(getMember, value, member));
            return null;
        }
        else
        {
            static if (hasScoped && is(Member == D[], D) && !is(Unqual!D == char))
            {
                import mir.appender: ScopedBuffer;
                alias E = Unqual!D;
                if (false)
                {
                    ScopedBuffer!E buffer;
                    if (auto exception = deserializeListToScopedBuffer!(deserializeValue!(symbolTable, exteneded), exteneded)(data, tableParams, buffer))
                        return exception;
                }
                return () @trusted {
                    ScopedBuffer!E buffer = void;
                    buffer.initialize;
                    if (auto exception = deserializeListToScopedBuffer!(deserializeValue!(symbolTable, exteneded), exteneded)(data, tableParams, buffer))
                        return exception;
                    auto temporal = cast(Member)buffer.data;
                    static if (hasTransform)
                        transform(temporal);
                    __traits(getMember, value, member) = move(temporal);
                    return null;
                } ();
            }
            else
            {
                Member temporal;
                if (auto exception = impl(data, tableParams, temporal, context))
                    return exception;
                static if (hasTransform)
                    transform(temporal);
                __traits(getMember, value, member) = move(temporal);
                return null;
            }
        }
    }
}

///
@safe pure
version(mir_ion_test) unittest
{
    import mir.ion.symbol_table;
    import mir.ion.value;
    import mir.ion.exception;
    import mir.small_array;
    import mir.small_string;

    static struct Book
    {
        string title;
        bool wouldRecommend;
        string description;
        uint numberOfNovellas;
        double price;
        float weight;
        string[] tags;
    }

    static immutable symbolTable = ["title", "wouldRecommend", "description", "numberOfNovellas", "price", "weight", "tags"];
    static immutable binaryData = cast(immutable ubyte[]) "\xde\xc9\x8a\x8e\x92A Hero of Our Time\x8b\x11\x8c\x0f\x8d!\x05\x8eS\xc2\x03\x1f\x8fH@\x1b\x85\x1e\xb8Q\xeb\x85\x90\xbe\x9b\x87russian\x85novel\x8c19th century";

    auto data = IonValue(binaryData).describe;
    
    Book book;
    if (auto exception = deserializeValue!(IonSystemSymbolTable_v1 ~ symbolTable)(data, book))
        throw exception;

    assert(book.description.length == 0);
    assert(book.numberOfNovellas == 5);
    assert(book.price == 7.99);
    assert(book.tags.length == 3);
    assert(book.tags[0] == "russian");
    assert(book.tags[1] == "novel");
    assert(book.tags[2] == "19th century");
    assert(book.title == "A Hero of Our Time");
    assert(book.weight == 6.88f);
    assert(book.wouldRecommend);
}

///
unittest
{
    import mir.ion.deser.json;
    import std.uuid;

    static struct S
    {
        @serdeScoped
        @serdeProxy!string
        UUID id;
    }
    assert(`{"id":"8AB3060E-2cba-4f23-b74c-b52db3bdfb46"}`.deserializeJson!S.id
                == UUID("8AB3060E-2cba-4f23-b74c-b52db3bdfb46"));
}

/// Mir types
unittest
{
    import mir.bignum.integer;
    import mir.date;
    import mir.ion.deser.json: deserializeJson;
    assert(`"2021-04-24"`.deserializeJson!Date == Date(2021, 4, 24));
    assert(`123`.deserializeJson!(BigInt!2) == BigInt!2(123));
}

/// Mir types
@safe pure @nogc
unittest
{
    static struct S
    {
        @serdeIgnoreIn
        bool set;
        @serdeScoped
        @property auto a(int[] a)
        {
            static immutable d = [1, 2, 3];
            set = a == d;
        }
    }
    import mir.ion.deser.json: deserializeJson;
    auto s = `{"a":[1, 2, 3]}`.deserializeJson!S;
    assert(s.set);
}
