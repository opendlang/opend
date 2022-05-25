/++
$(H4 High level deserialization API)

Macros:
IONREF = $(REF_ALTTEXT $(TT $2), $2, mir, ion, $1)$(NBSP)
+/
module mir.deser;

import mir.deser.low_level;
import mir.ion.exception;
import mir.ion.symbol_table;
import mir.ion.type_code;
import mir.ion.value;
import mir.serde: serdeGetFinalProxy;
import mir.small_array;
import mir.small_string;
import mir.utility: _expect;
import std.traits: ForeachType, hasUDA, Unqual, isSomeChar, EnumMembers, TemplateArgsOf, getUDAs;

private alias AliasSeq(T...) = T;

public import mir.serde;

private enum isSmallString(T) = is(T == SmallString!N, size_t N);

package template hasScoped(T)
{
    import std.traits: isAggregateType;
    import mir.serde: serdeScoped;
    static if (is(T == enum) || isAggregateType!T)
        enum hasScoped = hasUDA!(T, serdeScoped);
    else
        enum hasScoped = false;
}

IonException deserializeValue_(T)(IonDescribedValue data, scope ref T value)
    if (isFirstOrderSerdeType!T)
{
    return deserializeValueImpl(data, value).ionException;
}

IonException deserializeValue_(T, TableKind tableKind, bool annotated)(DeserializationParams!(tableKind, annotated) params, scope ref T value)
    if (isFirstOrderSerdeType!T)
{
    return deserializeValue_!T(params.data, value);
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

///
enum TableKind
{
    ///
    compiletime,
    ///
    scopeRuntime,
    ///
    immutableRuntime,
}

///
struct DeserializationParams(TableKind tableKind, bool annotated = false)
{
    ///
    IonDescribedValue data;

    ///
    DeserializationParams!tableKind withData(IonDescribedValue data) const 
    {
        auto ret = typeof(return)(data);
        static if (tableKind)
        {
            ret.compiletimeIndex = compiletimeIndex;
            ret.runtimeSymbolTable = runtimeSymbolTable;
        }
        return ret;
    }

    static if (annotated)
    {
        ///
        IonAnnotations annotations;
    }
    else
    {
        ///
        DeserializationParams!(tableKind, true) withAnnotations(IonAnnotations annotations) const
        {
            auto ret = typeof(return)(data);
            ret.annotations = annotations;
            static if (tableKind)
            {
                ret.compiletimeIndex = compiletimeIndex;
                ret.runtimeSymbolTable = runtimeSymbolTable;
            }
            return ret;
        }

        ///
        DeserializationParams!(tableKind, false) withAnnotations() const
        {
            auto ret = typeof(return)(data);
            static if (tableKind)
            {
                ret.compiletimeIndex = compiletimeIndex;
                ret.runtimeSymbolTable = runtimeSymbolTable;
            }
            return ret;
        }
    }

    ///
    DeserializationParams!tableKind withoutAnnotations() const
    {
        auto ret = typeof(return)(data);
        static if (tableKind)
        {
            ret.compiletimeIndex = compiletimeIndex;
            ret.runtimeSymbolTable = runtimeSymbolTable;
        }
        return ret;
    }

    static if (tableKind)
    {
        static if (tableKind == TableKind.scopeRuntime)
            ///
            const(char[])[] runtimeSymbolTable;
        else
            ///
            const(string)[] runtimeSymbolTable;
        ///
        const(uint)[] compiletimeIndex;
    }
}

package static immutable tableInsance(string[] symbolTable) = symbolTable;

package template hasDeserializeFromIon(T)
{
    import std.traits: isAggregateType;
    import std.meta: staticIndexOf;
    static if (isAggregateType!T)
        enum hasDeserializeFromIon = staticIndexOf!("deserializeFromIon", __traits(allMembers, T)) >= 0;
    else
        enum hasDeserializeFromIon = false;
}

/++
Deserialize aggregate value using compile time symbol table
+/
template deserializeValue(string[] symbolTable)
{
    import mir.appender: scopedBuffer, ScopedBuffer;

    @safe pure nothrow @nogc
    private bool prepareSymbolId(TableKind tableKind, bool annotated)(DeserializationParams!(tableKind, annotated) params, ref size_t symbolId)
    {
        static if (tableKind)
        {
            if (symbolId >= params.compiletimeIndex.length)
                return false;
            symbolId = params.compiletimeIndex[symbolId];
        }
        return symbolId < symbolTable.length;
    }

    @trusted pure nothrow @nogc private IonException deserializeScoped(C, TableKind tableKind, bool annotated)(DeserializationParams!(tableKind, annotated) params, ref C[] value)
        if (is(immutable C == immutable char))
    {with(params){

        import std.traits: Select;
        import mir.serde: serdeGetProxy, serdeScoped, serdeScoped;
        import mir.conv: to;

        static if (tableKind)
            auto table = runtimeSymbolTable;
        else
            alias table = tableInsance!symbolTable;

        if (data.descriptor.type == IonTypeCode.symbol)
        {
            size_t id;
            if (auto exc = data.trustedGet!IonSymbolID.get(id))
                return exc.ionException;
            if (id >= table.length)
                return IonErrorCode.symbolIdIsTooLargeForTheCurrentSymbolTable.ionException;
            value = cast(C[])table[id];
            return null;
        }
        else
        {
            if (_expect(data.descriptor.type != IonTypeCode.string && data.descriptor.type != IonTypeCode.null_, false))
                return IonErrorCode.expectedStringValue.ionException;
            auto ionValue = data.trustedGet!(const(char)[]);
            value = cast(C[])ionValue;
            return null;
        }
    }}

    private IonException deserializeListToScopedBuffer(TableKind tableKind, bool annotated, Buffer)(
        DeserializationParams!(tableKind, annotated) params,
        ref Buffer buffer)
    {with(params){
        if (_expect(data.descriptor.type != IonTypeCode.list, false))
            return IonErrorCode.expectedListValue.ionException;
        foreach (IonErrorCode error, IonDescribedValue ionElem; data.trustedGet!IonList)
        {
            import std.traits: Unqual;
            if (_expect(error, false))
                return error.ionException;
            Unqual!(typeof(buffer.data[0])) value;
            if (auto exception = deserializeValue(params.withData(ionElem), value))
                return exception;
            import core.lifetime: move;
            buffer.put(move(value));
        }
        return null;
    }}

    private IonException deserializeValueMember(string member, T, TableKind tableKind, bool annotated)(DeserializationParams!(tableKind, annotated) params, scope ref T value, scope ref SerdeFlags!T requiredFlags)
    {with(params){
        import core.lifetime: move;
        import mir.conv: to;
        import mir.reflection: hasField;

        enum likeList = hasUDA!(__traits(getMember, T, member), serdeLikeList);
        enum likeStruct  = hasUDA!(__traits(getMember, T, member), serdeLikeStruct);
        enum hasProxy = hasUDA!(__traits(getMember, T, member), serdeProxy);

        alias Member = serdeDeserializationMemberType!(T, member);

        static if (hasProxy)
            alias Temporal = serdeGetProxy!(__traits(getMember, value, member));
        else
            alias Temporal = Member;

        enum hasScoped = hasUDA!(__traits(getMember, T, member), serdeScoped) || hasScoped!Temporal;

        enum hasTransform = hasUDA!(__traits(getMember, T, member), serdeTransformIn);

        static if (hasTransform)
            alias transform = serdeGetTransformIn!(__traits(getMember, value, member));

        static assert (likeList + likeStruct <= 1, T.stringof ~ "." ~ member ~ " can't have both @serdeLikeStruct and @serdeLikeList attributes");
        static assert (hasProxy >= likeStruct, T.stringof ~ "." ~ member ~ " should have a Proxy type for deserialization");
        static assert (hasProxy >= likeList, T.stringof ~ "." ~ member ~ " should have a Proxy type for deserialization");

        static if (hasScoped)
        {
            static if (is(immutable Temporal == immutable char[]))
            {
                alias impl = deserializeScoped;
            }
            else
            {
                alias impl = deserializeValue;
            }
        }
        else
        {
            alias impl = deserializeValue;
        }

        static if (!hasUDA!(__traits(getMember, T, member), serdeAllowMultiple))
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
                    auto elemParams = params.withData(ionElem);
                    Temporal elem;
                    if (auto exception = impl(elemParams, elem))
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
                    if (auto exception = impl(params.withData(ionElem), elem))
                        return exception;
                    import core.lifetime: move;

                    static if (tableKind)
                        auto table = runtimeSymbolTable;
                    else
                        alias table = tableInsance!symbolTable;

                    if (symbolId >= table.length)
                        return unqualException(unexpectedSymbolIdWhenDeserializing!T);

                    static if (__traits(compiles, __traits(getMember, value, member)[table[symbolId]] = move(elem)))
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
            if (auto exception = impl(params, proxy))
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
            if (auto exception = impl(params, __traits(getMember, value, member)))
                return exception;
            static if (hasTransform)
                transform(__traits(getMember, value, member));
            return null;
        }
        else
        {
            static if (hasScoped && is(Member == D[], D) && !is(Unqual!D == char))
            {
                import std.traits: hasIndirections;
                static if (!hasIndirections!D)
                {
                    alias E = Unqual!D;
                    auto buffer = scopedBuffer!E;
                }
                else
                {
                    import std.array: std_appender = appender;
                    auto buffer = std_appender!(D[]);
                }
                if (auto exception = deserializeListToScopedBuffer(params, buffer))
                    return exception;
                auto temporal = (() @trusted => cast(Member)buffer.data)();
                static if (hasTransform)
                    transform(temporal);
                __traits(getMember, value, member) = move(temporal);
                return null;
            }
            else
            {
                Member temporal;
                if (auto exception = impl(params, temporal))
                    return exception;
                static if (hasTransform)
                    transform(temporal);
                __traits(getMember, value, member) = move(temporal);
                return null;
            }
        }
    }}

    /++
    Deserialize aggregate value
    Params:
        params = $(LREF DeserializationParams)
        value = value to deserialize
    Returns: `IonException`
    +/
    IonException deserializeValue(T, TableKind tableKind, bool annotated)(DeserializationParams!(tableKind, annotated) params, scope ref T value)
        if (!isFirstOrderSerdeType!T)
    {with(params){
        import mir.algebraic: isVariant, isNullable;
        import mir.internal.meta: Contains;
        import mir.ndslice.slice: Slice, SliceKind;
        import mir.rc.array: RCArray, RCI;
        import mir.reflection: isStdNullable;
        import mir.string_map : isStringMap;
        import std.meta: anySatisfy, Filter, templateAnd, templateNot, templateOr, ApplyRight;
        import std.traits: isArray, isSomeString, isAssociativeArray;

        static if (tableKind)
            auto table = runtimeSymbolTable;
        else
            alias table = tableInsance!symbolTable;

        static if (hasDeserializeFromIon!T)
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
                    auto elemParams = params.withData(ionElem);
                    E elem;
                    if (auto exception = deserializeValue(elemParams, elem))
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
        static if (is(T == string) || is(T == const(char)[]) || is(T == char[]))
        {
            if (data.descriptor.type == IonTypeCode.symbol)
            {
                size_t id;
                if (auto exc = data.trustedGet!IonSymbolID.get(id))
                    return exc.ionException;
                if (id >= table.length)
                    return IonErrorCode.symbolIdIsTooLargeForTheCurrentSymbolTable.ionException;
                import mir.conv: to;
                if (tableKind == TableKind.scopeRuntime && !is(T == string))
                    value = table[id].dup;
                else
                    value = table[id].to!T;
                return null;
            }
            if (_expect(data.descriptor.type != IonTypeCode.string && data.descriptor.type != IonTypeCode.null_, false))
                return IonErrorCode.expectedStringValue.ionException;
            auto ionValue = data.trustedGet!(const(char)[]);
            static if (is(T == string))
                value = ionValue.idup;
            else
                value = ionValue.dup;
            return null; 
        }
        else
        static if (is(T : SmallString!maxLength, size_t maxLength))
        {
            if (data.descriptor.type == IonTypeCode.symbol)
            {
                size_t id;
                if (auto exc = data.trustedGet!IonSymbolID.get(id))
                    return exc.ionException;
                if (id >= table.length)
                    return IonErrorCode.symbolIdIsTooLargeForTheCurrentSymbolTable.ionException;
                value = table[id];
                return null;
            }
            if (_expect(data.descriptor.type != IonTypeCode.string && data.descriptor.type != IonTypeCode.null_, false))
                return IonErrorCode.expectedStringValue.ionException;
            auto ionValue = data.trustedGet!(const(char)[]);
            if (ionValue.length > maxLength)
                return IonErrorCode.smallStringOverflow.ionException;
            value.trustedAssign(ionValue);
            return null; 
        }
        else
        static if (is(T == RCArray!RC, RC) && isSomeChar!RC)
        {
            import mir.rc.array: rcarray;
            if (data.descriptor.type == IonTypeCode.symbol)
            {
                size_t id;
                if (auto exc = data.trustedGet!IonSymbolID.get(id))
                    return exc.ionException;
                if (id >= table.length)
                    return IonErrorCode.symbolIdIsTooLargeForTheCurrentSymbolTable.ionException;
                value = table[id].rcarray!(TemplateArgsOf!T);
                return null;
            }
            import std.traits: TemplateArgsOf;
            if (_expect(data.descriptor.type != IonTypeCode.string && data.descriptor.type != IonTypeCode.null_, false))
                return IonErrorCode.expectedStringValue.ionException;
            auto ionValue = data.trustedGet!(const(char)[]);
            value = ionValue.rcarray!(TemplateArgsOf!T);
            return null; 
        }
        else
        static if (is(T == D[], D))
        {
            if (data.descriptor.type == IonTypeCode.list)
            {
                import std.array: std_appender = appender;
                auto buffer = std_appender!(D[]);
                if (auto exception = deserializeListToScopedBuffer(params, buffer))
                    return exception;
                value = buffer.data;
                return null;
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
                auto elemParams = params.withData(ionElem);
                if (auto exception = deserializeValue(elemParams, value[i++]))
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
                auto elemParams = params.withData(elem);
                if (auto errorMsg = deserializeValue(elemParams, ref () @trusted {return value.require(table[symbolId].to!K);} ()))
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
                if (auto errorMsg = deserializeValue(params.withData(elem), value.require(table[symbolId].to!string)))
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
                if (auto ret = deserializeValue(params, array))
                    return ret;
                value = array.sliced.asKindOf!kind;
                return null;
            }
            // TODO: create a single allocation algorithm
            else
            {
                import mir.ndslice.fuse: fuse;

                Slice!(D*, N - 1)[] array;
                if (auto ret = deserializeValue(params, array))
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
                if (auto ret = deserializeValue(params, array))
                    return ret;
                value = array.moveToSlice.asKindOf!kind;
                return null;
            }
            // TODO: create a single allocation algorithm
            else
            {
                import mir.ndslice.fuse: rcfuse;

                RCArray!(Slice!(RCI!D, N - 1)) array;
                if (auto ret = deserializeValue(params, array))
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
                auto buffer = scopedBuffer!E;
                if (auto exception = deserializeListToScopedBuffer(params, buffer))
                    return exception;
                auto ar = RCArray!E(buffer.length, false);
                () @trusted {
                    buffer.moveDataAndEmplaceTo(ar[]);
                } ();
                static if (__traits(compiles, value = move(ar)))
                    value = move(ar);
                else () @trusted {
                    value = ar.opCast!T;
                } ();
                return null;
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
            static if (hasUDA!(T, serdeScoped))
                static if (is(serdeGetProxy!T == C[], C) && is(immutable C == immutable char))
                    alias impl = deserializeScoped;
                else
                    alias impl = deserializeValue;
            else
                alias impl = deserializeValue;

            static if (hasUDA!(T, serdeLikeStruct))
            {
                import mir.conv;
                if (data.descriptor.type != IonTypeCode.null_ && data.descriptor.type != IonTypeCode.struct_)
                    return IonErrorCode.expectedIonStructForAnAssociativeArrayDeserialization.ionException;
                if (data.descriptor.L != 0xF) foreach (IonErrorCode error, size_t symbolId, IonDescribedValue elem; data.trustedGet!IonStruct)
                {
                    if (error)
                        return error.ionException;
                    if (symbolId >= table.length)
                        return IonErrorCode.symbolIdIsTooLargeForTheCurrentSymbolTable.ionException;
                    import mir.conv: to;
                    auto elemParams = params.withData(elem);
                    serdeGetProxy!T temporal;
                    if (auto exception = impl(elemParams, temporal))
                        return exception;
                    static if (__traits(compiles, {value[table[symbolId]] = move(temporal);}))
                    {
                        value[table[symbolId]] = move(temporal);
                    }
                    else
                    {
                        value[table[symbolId].idup] = move(temporal);
                    }
                }
            }
            else
            static if (hasUDA!(T, serdeLikeList))
            {
                import mir.conv;
                if (data.descriptor.type != IonTypeCode.null_ && data.descriptor.type != IonTypeCode.list)
                    return IonErrorCode.expectedListValue.ionException;
                if (data.descriptor.L != 0xF) foreach (IonErrorCode error, IonDescribedValue elem; data.trustedGet!IonList)
                {
                    if (error)
                        return error.ionException;
                    import mir.conv: to;
                    auto elemParams = params.withData(elem);
                    serdeGetProxy!T temporal;
                    if (auto exception = impl(elemParams, temporal))
                        return exception;
                    value.put(move(temporal));
                }
            }
            else
            {
                serdeGetProxy!T temporal;
                if (auto exception = impl(params, temporal))
                    return exception;

                value = to!T(move(temporal));
            }
            static if(__traits(hasMember, T, "serdeFinalize"))
            {
                value.serdeFinalize();
            }
            return null;
        }
        else
        static if (is(T == enum))
        {
            scope const(char)[] ionValue;
            if (data.descriptor.type == IonTypeCode.symbol)
            {
                size_t id;
                if (auto exc = data.trustedGet!IonSymbolID.get(id))
                    return exc.ionException;
                if (id >= table.length)
                    return IonErrorCode.symbolIdIsTooLargeForTheCurrentSymbolTable.ionException;

                auto originalId = id;
                if (!prepareSymbolId(params, id))
                    return IonErrorCode.symbolIdIsTooLargeForTheCurrentSymbolTable.ionException;

                switch (id)
                {
                    import std.meta: NoDuplicates;
                    alias Members = NoDuplicates!(EnumMembers!T);
                    foreach(i, member; Members)
                    {{
                        enum keys = serdeGetKeysIn(Members[i]);
                        static assert (keys.length, "At least one input enum key is required");
                        static foreach (key; keys)
                        {
                            case findKey(symbolTable, key):
                            value = member;
                            return null;
                        }
                    }}
                    default:
                        static if (hasUDA!(T, serdeIgnoreCase))
                            ionValue = table[id];
                        else
                            return IonErrorCode.expectedEnumValue.ionException;
                }
            }
            import mir.serde: serdeParseEnum;
            if (auto error = data.get(ionValue))
                return error.ionException;
            if (serdeParseEnum(ionValue, value))
                return null;
            return IonErrorCode.expectedEnumValue.ionException;
        }
        else
        static if (isVariant!T)
        {
            import mir.lob: Blob, Clob;
            import mir.timestamp: Timestamp;

            static if (getAlgebraicAnnotationsOfVariant!T.length)
            {
                static if (!annotated)
                {
                    auto annotatedParams = params.withAnnotations(IonAnnotations.init);
                    if (data.descriptor.type == IonTypeCode.annotations)
                    {
                        if (auto error = data.trustedGet!IonAnnotationWrapper.unwrap(annotatedParams.annotations, annotatedParams.data))
                        {
                            return error.ionException;
                        }
                        data = annotatedParams.data;
                    }
                    
                }
                else
                    alias annotatedParams = params;

                IonException retNull() @property
                {
                    return annotatedParams.annotations.empty ? null : IonErrorCode.unusedAnnotations.ionException;
                }
            }
            else
            {
                IonException retNull;
            }

            alias Types = T.AllowedTypes;
            alias contains = Contains!Types;

            static if (getAlgebraicAnnotationsOfVariant!T.length)
            {
                if (!annotatedParams.annotations.empty)
                {
                    size_t symbolId;
                    if (auto error = annotatedParams.annotations.pick(symbolId))
                        return error.ionException;

                    auto originalId = symbolId;
                    if (!prepareSymbolId(params, symbolId))
                        goto Default;

                    switch (symbolId)
                    {
                        static foreach (VT; Types)
                        static if (serdeHasAlgebraicAnnotation!VT)
                        {
                            case findKey(symbolTable, serdeGetAlgebraicAnnotation!VT):
                            {
                                VT object;
                                if (auto exception = deserializeValue(annotatedParams, object))
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
                else
                if (data.descriptor.type == IonTypeCode.struct_)
                {
                    auto dataStruct = data.trustedGet!IonStruct;
                    if (dataStruct.walkLength == 1)
                    {
                        foreach (IonErrorCode error, size_t symbolId, IonDescribedValue elem; dataStruct)
                        {
                            if (error)
                                return error.ionException;
                            auto originalId = symbolId;
                            if (prepareSymbolId(params, symbolId)) switch (symbolId)
                            {
                                static foreach (VT; Types)
                                static if (serdeHasAlgebraicAnnotation!VT)
                                {
                                    case findKey(symbolTable, serdeGetAlgebraicAnnotation!VT):
                                    {
                                        VT object;
                                        annotatedParams.data = elem;
                                        if (auto exception = deserializeValue(annotatedParams, object))
                                            return exception;
                                        import core.lifetime: move;
                                        value = move(object);
                                        return null;
                                    }
                                }
                                default:
                            }
                        }
                    }
                }
            }
            static if (contains!IonNull)
            {
                // TODO: check that descriptor.type correspond underlaying type
                if (data.descriptor.L == 0xF)
                {
                    value = IonNull(data.descriptor.type);
                    return retNull;
                }
            }
            else
            static if (contains!(typeof(null)))
            {
                // TODO: check that descriptor.type correspond underlaying type
                if (data.descriptor.L == 0xF)
                {
                    value = null;
                    return retNull;
                }
            }
            static if ((contains!(typeof(null)) || contains!IonNull) && T.AllowedTypes.length == 2)
            {
                T.AllowedTypes[1] payload;
                if (auto exception = deserializeValue(params, payload))
                    return exception;
                value = payload;
                return retNull;
            }
            else
            switch (data.descriptor.type)
            {
                // static if (contains!(typeof(null)))
                // {
                //     case IonTypeCode.null_:
                //     {
                //         value = null;
                //         return retNull;
                //     }
                // }

                static if (contains!bool)
                {
                    case IonTypeCode.bool_:
                    {
                        bool boolean;
                        if (auto errorCode = data.get!bool(boolean))
                            return errorCode.ionException;
                        value = boolean;
                        return retNull;
                    }
                }

                static if (contains!string)
                {
                    case IonTypeCode.symbol:
                    case IonTypeCode.string:
                    {
                        string str;
                        if (auto exception = deserializeValue(params, str))
                            return exception;
                        value = str;
                        return retNull;
                    }
                }
                else
                static if (Filter!(isSmallString, Types).length)
                {
                    case IonTypeCode.symbol:
                    case IonTypeCode.string:
                    {
                        Filter!(isSmallString, Types)[$ - 1] str; // pick the largest one
                        if (auto exception = deserializeValue(params, str))
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

                static if (contains!Timestamp)
                {
                    case IonTypeCode.timestamp:
                    {
                        Timestamp timestamp;
                        if (auto error = data.trustedGet!IonTimestamp.get(timestamp))
                            return error.ionException;
                        value = timestamp;
                        return retNull;
                    }
                }

                static if (contains!Blob)
                {
                    case IonTypeCode.blob:
                    {
                        auto blob = data.trustedGet!Blob;
                        value = Blob(blob.data.dup);
                        return retNull;
                    }
                }

                static if (contains!Clob)
                {
                    case IonTypeCode.clob:
                    {
                        auto clob = data.trustedGet!Clob;
                        value = Clob(clob.data.dup);
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
                        if (auto exception = deserializeValue(params, array))
                            return exception;
                        import core.lifetime: move;
                        value = move(array);
                        return retNull;
                    }
                }

                static if (anySatisfy!(templateOr!(isStringMap, isAssociativeArray, hasLikeStruct, hasFallbackStruct, hasDiscriminatedField), Types))
                {
                    case IonTypeCode.struct_:
                    {                        
                        static if (anySatisfy!(isStringMap, Types))
                        {
                            alias isMapType = isStringMap;
                        }
                        else
                        static if (anySatisfy!(isAssociativeArray, Types))
                        {
                            alias isMapType = isAssociativeArray;
                        }
                        else
                        static if (anySatisfy!(hasLikeStruct, Types))
                        {
                            alias isMapType = hasLikeStruct;
                        }
                        else
                        static if (anySatisfy!(hasFallbackStruct, Types))
                        {
                            alias isMapType = hasFallbackStruct;
                        }
                        else
                        static if (anySatisfy!(hasDiscriminatedField, Types))
                        {
                            alias isMapType = hasDiscriminatedField;
                        }
                        else
                        {
                            static assert(0);
                        }

                        alias DiscriminatedFieldTypes = Filter!(hasDiscriminatedField, Types);
                        static if (DiscriminatedFieldTypes.length)
                        {
                            enum discriminatedField = getUDAs!(DiscriminatedFieldTypes[0], serdeDiscriminatedField)[0].field;
                            foreach (DFT; DiscriminatedFieldTypes[1 .. $])
                            {{
                                enum df = getUDAs!(DFT, serdeDiscriminatedField)[0].field;
                                static assert (df == discriminatedField, "Discriminated field doesn't match: " ~ discriminatedField ~ " and " ~ df);
                            }}

                            foreach (IonErrorCode error, size_t symbolId, IonDescribedValue elem; data.trustedGet!IonStruct)
                            {
                                if (error)
                                    return error.ionException;
                                if (symbolId >= table.length)
                                    return IonErrorCode.symbolIdIsTooLargeForTheCurrentSymbolTable.ionException;
                                if (table[symbolId] == discriminatedField)
                                {
                                    const(char)[] tag;
                                    if (auto exception = deserializeScoped(params.withData(elem), tag))
                                        return exception;
                                    switch (tag)
                                    {
                                        foreach (DFT; DiscriminatedFieldTypes)
                                        {
                                            case getUDAs!(DFT, serdeDiscriminatedField)[0].tag: {
                                                DFT object;
                                                if (auto exception = deserializeValue(params, object))
                                                    return exception;
                                                import core.lifetime: move;
                                                value = move(object);
                                                return retNull;
                                            }
                                        }
                                        default:
                                    }
                                }
                            }
                        }

                        static if (__traits(isSame, isMapType, hasDiscriminatedField))
                        {
                            goto default;
                        }
                        else
                        {
                            alias AATypes = Filter!(isMapType, Types);
                            static assert(AATypes.length == 1, AATypes.stringof);
                            AATypes[0] object;
                            if (auto exception = deserializeValue(params, object))
                                return exception;
                            import core.lifetime: move;
                            value = move(object);
                            return retNull;
                        }
                    }
                }

                static if (anySatisfy!(isAnnotated, Types))
                {
                    case IonTypeCode.annotations:
                    {
                        alias ATypes = Filter!(isAnnotated, Types);
                        static assert(ATypes.length == 1, ATypes.stringof);
                        ATypes[0] object;
                        if (auto exception = deserializeValue(params, object))
                            return exception;
                        import core.lifetime: move;
                        value = move(object);
                        return retNull;
                    }
                }

                default:
                    return unqualException(unexpectedIonTypeCodeFor!T);
            }
        }
        else
        static if (isStdNullable!T && !isAlgebraicAliasThis!T)
        {
            // TODO: check that descriptor.type correspond underlaying type
            if (data.descriptor.L == 0xF)
            {
                value.nullify;
                return null;
            }

            typeof(value.get) payload;
            if (auto exception = deserializeValue(params, payload))
                return exception;
            value = payload;
            return null;
        }
        else
        {
            static if (serdeGetAnnotationMembersIn!T.length || annotated)
            {
                static if (!annotated)
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

                static foreach (member; serdeGetAnnotationMembersIn!T)
                {{
                    if (annotations.empty)
                        return IonErrorCode.missingAnnotation.ionException;
                    for(;;)
                    {
                        size_t symbolId;
                        if (auto error = annotations.pick(symbolId))
                            return error.ionException;
                        if (symbolId >= table.length)
                            return IonErrorCode.symbolIdIsTooLargeForTheCurrentSymbolTable.ionException;
                        static if (is(typeof(__traits(getMember, value, member)) == enum))
                        {
                            import mir.serde: serdeParseEnum;
                            typeof(__traits(getMember, value, member)) memberValue;
                            if (!serdeParseEnum(table[symbolId], memberValue))
                                return IonErrorCode.cantConvertAnnotationToEnum.ionException;
                            __traits(getMember, value, member) = memberValue;
                            break;
                        }
                        else
                        static if (__traits(compiles, __traits(getMember, value, member) = table[symbolId]))
                        {
                            __traits(getMember, value, member) = table[symbolId];
                            break;
                        }
                        else
                        static if (__traits(compiles, __traits(getMember, value, member) = table[symbolId].idup))
                        {
                            __traits(getMember, value, member) = table[symbolId].idup;
                            break;
                        }
                        else
                        {
                            alias AT = typeof(__traits(getMember, value, member));
                            static if (!isSomeChar!(ForeachType!AT))
                            {
                                import mir.conv : to;
                                __traits(getMember, value, member) ~= table[symbolId].to!(ForeachType!AT);
                                if (annotations.empty)
                                    break;
                            }
                            else
                            static assert(0, "Can't deserialize annotation member " ~ member ~ " of " ~ T.stringof);
                        }
                    }
                }}
            }

            static if (serdeGetAnnotationMembersIn!T.length && !annotated)
                auto annotatedParams = params.withAnnotations(annotations);
            else
                alias annotatedParams = params;

            static if (isAlgebraicAliasThis!T || isAnnotated!T)
            {
                import mir.reflection: hasField;
                static if (__traits(getAliasThis, T).length == 1)
                    enum aliasMember = __traits(getAliasThis, T);
                else
                    enum aliasMember = "value";
                static if (hasField!(T, aliasMember))
                    return deserializeValue(annotatedParams, __traits(getMember, value, aliasMember));
                else {
                    typeof(__traits(getMember, value, aliasMember)) temporal;
                    if (auto exception = deserializeValue(annotatedParams, temporal))
                        return exception;
                    import core.lifetime: move;
                    __traits(getMember, value, aliasMember) = move(temporal);
                    return null;
                }
            }
            else
            {
                static if (serdeGetAnnotationMembersIn!T.length || annotated)
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
                            return unqualException(cantConstructObjectExc!T);
                        }
                    }
                }

                auto ionValue = data.trustedGet!IonStruct;

                SerdeFlags!T requiredFlags;

                static if (hasUDA!(T, serdeOrderedIn))
                {
                    SerdeOrderedDummy!T temporal;
                    if (auto exception = deserializeValue(params.withoutAnnotations, temporal))
                        return exception;
                    temporal.serdeFinalizeTarget(value, requiredFlags);
                }
                else
                {
                    enum hasUnexpectedKeyHandler = __traits(hasMember, T, "serdeUnexpectedKeyHandler");
                    enum hasSerdeIgnoreUnexpectedKeys = hasUDA!(T, serdeIgnoreUnexpectedKeys);

                    import std.meta: staticMap, aliasSeqOf;
                    static if (hasUDA!(T, serdeRealOrderedIn))
                    {
                        static assert (!hasUnexpectedKeyHandler, "@serdeRealOrderedIn aggregate type attribute is not compatible with `serdeUnexpectedKeyHandler` method");
                        static assert (!hasSerdeIgnoreUnexpectedKeys, "@serdeRealOrderedIn aggregate type attribute is not compatible with @hasSerdeIgnoreUnexpectedKeys");
                        static foreach (member; serdeFinalProxyDeserializableMembers!T)
                        {{
                            enum keys = serdeGetKeysIn!(__traits(getMember, value, member));
                            static if (keys.length)
                            {
                                foreach (IonErrorCode error, size_t symbolId, IonDescribedValue elem; ionValue)
                                {
                                    if (error)
                                        return error.ionException;
                                    prepareSymbolId(params, symbolId);

                                    switch(symbolId)
                                    {
                                        static foreach (key; keys)
                                        {
                                        case findKey(symbolTable, key):
                                        }

                                            static if(hasUDA!(__traits(getMember, T, member), serdeIgnoreIfAggregate))
                                            {
                                                alias pred = serdeGetIgnoreIfAggregate!(__traits(getMember, value, member));
                                                if (pred(value))
                                                {
                                                    __traits(getMember, requiredFlags, member) = true;
                                                    goto default;
                                                }
                                            }

                                            static if(hasUDA!(__traits(getMember, T, member), serdeIgnoreInIfAggregate))
                                            {
                                                alias pred = serdeGetIgnoreInIfAggregate!(__traits(getMember, value, member));
                                                if (pred(value))
                                                {
                                                    __traits(getMember, requiredFlags, member) = true;
                                                    goto default;
                                                }
                                            }

                                            if (auto mexp = deserializeValueMember!member(params.withData(elem), value, requiredFlags))
                                                return mexp;
                                            break;
                                        default:
                                    }
                                }
                            }

                            static if (!hasUDA!(__traits(getMember, T, member), serdeOptional))
                            {
                                static if(hasUDA!(__traits(getMember, T, member), serdeIgnoreIfAggregate))
                                {
                                    alias pred = serdeGetIgnoreIfAggregate!(__traits(getMember, value, member));
                                    if (!__traits(getMember, requiredFlags, member) && !pred(value))
                                        return unqualException(exc!(T, member));
                                }
                                else
                                static if(hasUDA!(__traits(getMember, T, member), serdeIgnoreInIfAggregate))
                                {
                                    alias pred = serdeGetIgnoreInIfAggregate!(__traits(getMember, value, member));
                                    if (!__traits(getMember, requiredFlags, member) && !pred(value))
                                        return unqualException(exc!(T, member));
                                }
                                else
                                {
                                    if (!__traits(getMember, requiredFlags, member))
                                        return unqualException(exc!(T, member));
                                }
                            }
                        }}
                    }
                    else
                    {
                        foreach (IonErrorCode error, size_t symbolId, IonDescribedValue elem; ionValue)
                        {
                            if (error)
                                return error.ionException;
                            auto originalId = symbolId;
                            if (!prepareSymbolId(params, symbolId))
                                goto Default;
                            S: switch(symbolId)
                            {
                                static foreach (member; serdeFinalProxyDeserializableMembers!T)
                                {{
                                    enum keys = serdeGetKeysIn!(__traits(getMember, T, member));
                                    static if (keys.length)
                                    {
                                        static foreach (key; keys)
                                        {
                                case findKey(symbolTable, key):
                                        }
                                    static if(hasUDA!(__traits(getMember, T, member), serdeIgnoreInIfAggregate))
                                    {
                                        alias pred = serdeGetIgnoreInIfAggregate!(__traits(getMember, value, member));
                                        if (pred(value))
                                        {
                                            static if (hasUnexpectedKeyHandler && !hasUDA!(__traits(getMember, T, member), serdeOptional))
                                                __traits(getMember, requiredFlags, member) = true;
                                            goto default;
                                        }
                                    }
                                    static if(hasUDA!(__traits(getMember, T, member), serdeIgnoreIfAggregate))
                                    {
                                        alias pred = serdeGetIgnoreIfAggregate!(__traits(getMember, value, member));
                                        if (pred(value))
                                        {
                                            static if (hasUnexpectedKeyHandler && !hasUDA!(__traits(getMember, T, member), serdeOptional))
                                                __traits(getMember, requiredFlags, member) = true;
                                            goto default;
                                        }
                                    }
                                    auto elemParams = params.withData(elem);
                                    if (auto mexp = deserializeValueMember!member(elemParams, value, requiredFlags))
                                        return mexp;
                                    break S;
                                    }
                                }}
                                Default:
                                default:
                                    static if (hasDiscriminatedField!T)
                                    {
                                        if (originalId < table.length && table[originalId] == getUDAs!(T, serdeDiscriminatedField)[0].field)
                                        {
                                            break;
                                        }
                                    }

                                    static if (hasUnexpectedKeyHandler)
                                        value.serdeUnexpectedKeyHandler(originalId < table.length ? table[originalId] : "<@unknown symbol@>");
                                    else
                                    static if (!hasSerdeIgnoreUnexpectedKeys)
                                        return unqualException(unexpectedKeyWhenDeserializing!T);
                            }
                        }

                        static foreach (member; __traits(allMembers, SerdeFlags!T))
                            static if (!hasUDA!(__traits(getMember, T, member), serdeOptional))
                            {
                                static if(hasUDA!(__traits(getMember, T, member), serdeIgnoreIfAggregate))
                                {
                                    alias pred = serdeGetIgnoreIfAggregate!(__traits(getMember, value, member));
                                    if (!__traits(getMember, requiredFlags, member) && !pred(value))
                                        return unqualException(exc!(T, member));
                                }
                                else
                                static if(hasUDA!(__traits(getMember, T, member), serdeIgnoreInIfAggregate))
                                {
                                    alias pred = serdeGetIgnoreInIfAggregate!(__traits(getMember, value, member));
                                    if (!__traits(getMember, requiredFlags, member) && !pred(value))
                                        return unqualException(exc!(T, member));
                                }
                                else
                                {
                                    if (!__traits(getMember, requiredFlags, member))
                                        return unqualException(exc!(T, member));
                                }
                            }
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
    }}

    ///
    alias deserializeValue = .deserializeValue_;
}

version(mir_ion_test)
unittest
{
    import mir.algebraic_alias.json : JsonAlgebraic;
    import mir.deser.json : deserializeJson;
    auto v = deserializeJson!JsonAlgebraic(`{"a":[1,"world",false,null]}`);
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

    auto params = DeserializationParams!(TableKind.compiletime)(data); 
    if (auto exception = deserializeValue!(IonSystemSymbolTable_v1 ~ symbolTable)(params, book))
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
version(mir_ion_test) unittest
{
    import mir.deser.json;
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
version(mir_ion_test) unittest
{
    import mir.bignum.integer;
    import mir.date;
    import mir.deser.json: deserializeJson;
    assert(`"2021-04-24"`.deserializeJson!Date == Date(2021, 4, 24));
    assert(`123`.deserializeJson!(BigInt!2) == BigInt!2(123));
}

/// Mir types
@safe pure @nogc
version(mir_ion_test) unittest
{
    static struct S
    {
        @serdeIgnoreIn
        bool set;
        @serdeScoped
        @property auto a(scope int[] a) @safe
        {
            static immutable d = [1, 2, 3];
            set = a == d;
        }
    }
    import mir.deser.json: deserializeJson;
    auto s = `{"a":[1, 2, 3]}`.deserializeJson!S;
    assert(s.set);
}

///
@safe pure //@nogc
version(mir_ion_test) unittest
{
    enum Kind { request, cancel }

    @serdeRealOrderedIn
    static struct S
    {
        Kind kind;

        @serdeIgnoreInIfAggregate!((ref a) => a.kind == Kind.cancel)
        @serdeIgnoreOutIfAggregate!((ref a) => a.kind == Kind.cancel)
        int number;
    }

    import mir.deser.json: deserializeJson;
    import mir.ser.json: serializeJson;
    assert(`{"number":3, "kind":"cancel"}`.deserializeJson!S.kind == Kind.cancel);
    assert(`{"number":3, "kind":"cancel"}`.deserializeJson!S.number == 0);
    assert(`{"number":3, "kind":"request"}`.deserializeJson!S.number == 3);
    assert(`{"kind":"request","number":3}`.deserializeJson!S.number == 3);
    assert(S(Kind.cancel, 4).serializeJson == `{"kind":"cancel"}`);
    assert(S(Kind.request, 4).serializeJson == `{"kind":"request","number":4}`);
}

///
@safe pure //@nogc
version(mir_ion_test) unittest
{
    enum Kind { request, cancel }

    @serdeRealOrderedIn
    static struct S
    {
        Kind kind;

        @serdeIgnoreIfAggregate!((ref a) => a.kind == Kind.cancel)
        int number;
    }

    import mir.deser.json: deserializeJson;
    import mir.ser.json: serializeJson;
    assert(`{"kind":"cancel"}`.deserializeJson!S.kind == Kind.cancel);
    assert(`{"kind":"cancel","number":3}`.deserializeJson!S.number == 0); // ignores number
    assert(`{"kind":"request","number":3}`.deserializeJson!S.number == 3);
    assert(S(Kind.cancel, 4).serializeJson == `{"kind":"cancel"}`);
    assert(S(Kind.request, 4).serializeJson == `{"kind":"request","number":4}`);
}

version(mir_ion_test) unittest
{
    import mir.deser.json;
    import mir.algebraic : Nullable;
    import mir.ion.value : IonDescribedValue;
    import mir.ion.exception : IonException;
    import mir.deser.ion : deserializeIon;

    static struct Q
    {
        int i;
        IonException deserializeFromIon(scope const char[][] symbolTable, IonDescribedValue value) scope @safe pure @nogc
        {
            i = deserializeIon!int(symbolTable, value);
            return null;
        }
    }

    // works
    // Q s = deserializeJson!Q(`5`);

    static struct T
    {
        Nullable!Q test;
    }

    // does not work
    // ../subprojects/mir-core/source/mir/algebraic.d(2883): [unittest] Null Algebraic!(typeof(null), S)
    // core.exception.AssertError@../subprojects/mir-core/source/mir/algebraic.d(2883): Null Algebraic!(typeof(null), S)
    T t = `{ "test": 5 }`.deserializeJson!T;
    assert (!t.test.isNull);
}
