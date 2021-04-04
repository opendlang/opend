/++
$(H4 High level deserialization API)

Macros:
IONREF = $(REF_ALTTEXT $(TT $2), $2, mir, ion, $1)$(NBSP)
+/
module mir.ion.deser;

public import mir.serde;

import mir.bignum.decimal: Decimal;
import mir.bignum.integer: BigInt;
import mir.ion.deser.low_level;
import mir.ion.exception;
import mir.ion.symbol_table;
import mir.ion.type_code;
import mir.ion.value;
import mir.small_array;
import mir.small_string;
import mir.utility: _expect;

import std.traits:
    ForeachType,
    hasUDA,
    isAggregateType,
    Unqual;

private enum isUserAggregate(T) = isAggregateType!T
    && !is(T : BigInt!maxSize64, size_t maxSize64)
    && !is(T : Decimal!maxW64bitSize, size_t maxW64bitSize)
    && !is(T : SmallArray!(E, maxLength), E, size_t maxLength)
    && !is(T : SmallString!maxLength, size_t maxLength);

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
            return exc!member;
        }
        default:
            static immutable ret = "Wrong encoding of Ion type code";
            return ret;
    }
}

string deserializeScoped(T)(IonDescribedValue data, ref T value)
    if (isFirstOrderSerdeType!T)
{
    return deserializeScopedValueImpl(data, value).ionErrorMsg;
}

string deserializeScoped(T)(IonDescribedValue data, scope TableParams!true params, ref T value)
    if (isFirstOrderSerdeType!T)
{
    return deserializeScoped(data, value);
}

string deserializeValue_(T)(IonDescribedValue data, ref T value)
    if (isFirstOrderSerdeType!T)
{
    return deserializeValueImpl(data, value).ionErrorMsg;
}

string deserializeValue_(T)(IonDescribedValue data, scope TableParams!true params, ref T value)
    if (isFirstOrderSerdeType!T)
{
    return deserializeValue_(data, value);
}

template deserializeListToScopedBuffer(alias impl, bool exteneded)
{
    import mir.appender: ScopedBuffer;
    private string deserializeListToScopedBuffer(E, size_t bytes)(IonDescribedValue data, scope TableParams!exteneded params, ref ScopedBuffer!(E, bytes) buffer)
    {
        if (_expect(data.descriptor.type != IonTypeCode.list, false))
            return IonErrorCode.expectedListValue.ionErrorMsg;
        foreach (IonErrorCode error, IonDescribedValue ionElem; data.trustedGet!IonList)
        {
            if (_expect(error, false))
                return error.ionErrorMsg;
            E value;
            if (auto exc = impl(ionElem, params, value))
                return exc;
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

/++
Deserialize aggregate value using compile time symbol table
+/
template deserializeValue(string[] symbolTable, bool exteneded = false)
{
    /++
    Deserialize aggregate value
    Params:
        data = $(IONREF value, IonDescribedValue)
        value = value to deserialize
    Returns: `SerdeException`
    +/
    string deserializeValue(T)(IonDescribedValue data, scope TableParams!exteneded tableParams, ref T value)
        if (!isFirstOrderSerdeType!T)
    {
        import mir.rc.array: RCArray, RCI;
        import mir.ndslice.slice: Slice, SliceKind;

        static if (__traits(hasMember, value, "deserializeFromIon"))
        {
            static if (!exteneded)
                static immutable table = symbolTable;
            else
                alias table = tableParams[0];
            return value.deserializeFromIon!(symbolTable)(table, data);
        }
        else
        static if (is(T : SmallArray!(E, maxLength), E, size_t maxLength))
        {
            if (data.descriptor.type == IonTypeCode.list)
            {
                foreach (error, ionElem; data.trustedGet!IonList)
                {
                    if (_expect(error, false))
                        return error.ionErrorMsg;
                    if (value._length == maxLength)
                        return IonErrorCode.smallArrayOverflow.ionErrorMsg;
                    E elem;
                    if (auto exc = .deserializeValue!symbolTable(ionElem, tableParams, elem))
                        return exc;
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
            return IonErrorCode.expectedListValue.ionErrorMsg;
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
                    if (auto exc = deserializeListToScopedBuffer!(.deserializeValue!symbolTable, exteneded)(data, tableParams, buffer))
                        return exc;
                }

                return () @trusted {
                    import std.array: uninitializedArray;
                    ScopedBuffer!E buffer = void;
                    buffer.initialize;
                    if (auto exc = deserializeListToScopedBuffer!(.deserializeValue!symbolTable, exteneded)(data, tableParams, buffer))
                        return exc;
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
            return IonErrorCode.expectedListValue.ionErrorMsg;
        }
        else
        static if (is(T == K[V], K , V))
        {
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
                    if (auto exc = deserializeListToScopedBuffer!(.deserializeValue!symbolTable, exteneded)(data, tableParams, buffer))
                        return exc;
                }

                return ()@trusted @nogc {
                    ScopedBuffer!E buffer = void;
                    buffer.initialize;
                    if (auto exc = deserializeListToScopedBuffer!(.deserializeValue!symbolTable, exteneded)(data, tableParams, buffer))
                        return exc;
                    auto ar = RCArray!E(buffer.length, false);
                    buffer.moveDataAndEmplaceTo(ar[]);
                    static if (__traits(compiles, value = ar))
                        value = ar;
                    else
                        value = ar.opCast!T;
                    return null;
                } ();
            }
            else
            if (data.descriptor.type == IonTypeCode.null_)
            {
                value = null;
                return null;
            }
            return IonErrorCode.expectedListValue.ionErrorMsg;
        }
        else
        static if (isNullable!T)
        {
            // TODO: check that descriptor.type correspond underlaying type
            if (data.descriptor.L == 0xF)
            {
                value.nullify;
                return null;
            }

            typeof(value.get) payload;
            if (auto exc = .deserializeValue!symbolTable(data, tableParams, payload))
                return exc;
            value = payload;
            return null;
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
                    alias impl = .deserializeValue!symbolTable;
            else
                alias impl = .deserializeValue!symbolTable;

            if (auto exc = impl(data, tableParams, temporal))
                return exc;
            value = to!T(move(temporal));
            return null;
        }
        else
        {
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
                    static immutable exc = "Can't construct null value of type" ~ T.stringof;
                    return exc;
                }
            }

            if (data.descriptor.type != IonTypeCode.struct_)
            {
            WrongKindL:
                return unexpectedIonTypeCode!("Cann't desrialize " ~ T.stringof ~ ". Unexpected descriptor type:")(data.descriptor.type);
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
                        static immutable cantConstructObjectExc = T.stringof ~ " must be either not null or have a default constructor.";
                        return cantConstructObjectExc;
                    }
                }
            }

            IonStruct ionValue;
            if (auto error = data.get(ionValue))
            {
                return error.ionErrorMsg;
            }

            SerdeFlags!T requiredFlags;

            static if (hasUDA!(T, serdeOrderedIn))
            {
                SerdeOrderedDummy!T temporal;
                if (auto exc = .deserializeValue!symbolTable(data, tableParams, temporal))
                    return exc;
                temporal.serdeFinalizeTarget(value, requiredFlags);
            }
            else
            {
                alias impl = deserializeValueMember!(.deserializeValue!(symbolTable, exteneded), deserializeScoped, exteneded);

                static immutable exc(string member) = "mir.ion.deser: non-optional member '" ~ member ~ "' in " ~ T.stringof ~ " is missing.";
                
                enum hasUnexpectedKeyHandler = __traits(hasMember, T, "serdeUnexpectedKeyHandler");
                static if (!hasUnexpectedKeyHandler)
                    static immutable unexpectedKeyException = "Unexpected key when deserializing " ~ T.stringof;


                import std.meta: staticMap, aliasSeqOf;
                static if (hasUDA!(T, serdeRealOrderedIn))
                {
                    static assert (!hasUnexpectedKeyHandler, "serdeRealOrderedIn aggregate type attribute is not compatible with `serdeUnexpectedKeyHandler` method");
                    static foreach(member; serdeFinalProxyDeserializableMembers!T)
                    {{
                        enum keys = serdeGetKeysIn!(__traits(getMember, value, member));
                        static if (keys.length)
                        {
                            foreach (IonErrorCode error, size_t symbolID, IonDescribedValue elem; ionValue)
                            {
                                if (error)
                                    return error.ionErrorMsg;

                                static if (exteneded)
                                {
                                    auto originalID = symbolID;
                                    if (symbolID >= tableParams[1].length)
                                        goto Default;
                                    symbolID = tableParams[1][symbolID];
                                }
                                else
                                {
                                    alias originalID = symbolID;
                                }

                                switch(symbolID)
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
                                return exc!member;
                    }}
                }
                else
                {
                    foreach (IonErrorCode error, size_t symbolID, IonDescribedValue elem; ionValue)
                    {
                        if (error)
                        {
                            return error.ionErrorMsg;
                        }
                        static if (exteneded)
                        {
                            auto originalID = symbolID;
                            if (symbolID >= tableParams[1].length)
                                goto Default;
                            symbolID = tableParams[1][symbolID];
                        }
                        else
                        {
                            alias originalID = symbolID;
                        }
                        S: switch(symbolID)
                        {
                            static foreach(member; serdeFinalProxyDeserializableMembers!T)
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
                                static if (!exteneded)
                                    static immutable symbolTableInstance = symbolTable;
                                else
                                    alias symbolTableInstance = tableParams[0];
                                static if (hasUnexpectedKeyHandler)
                                    value.serdeUnexpectedKeyHandler(originalID == 0 || originalID > symbolTableInstance.length ? "<@unknown symbol@>" : symbolTableInstance[originalID]);
                                else
                                {
                                //     try debug {
                                //         import std.stdio;

                                // static if (!exteneded)
                                //     static immutable dd = symbolTable;
                                // else
                                //     alias dd = tableParams[0];

                                //         writeln(symbolTable, dd, dd[originalID]);
                                //     } catch(Exception e) {}
                                    // import core.stdc.stdio;
                                    // debug printf("ID = %d\n", symbolID);
                                    return unexpectedKeyException;
                                }
                        }
                    }

                    static foreach(member; __traits(allMembers, SerdeFlags!T))
                        static if (!hasUDA!(__traits(getMember, value, member), serdeOptional))
                            if (!__traits(getMember, requiredFlags, member))
                                return exc!member;
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

    ///
    alias deserializeValue = .deserializeValue_;
}

private template deserializeValueMember(alias deserializeValue, alias deserializeScoped, bool exteneded)
{
    ///
    string deserializeValueMember(string member, Data, T, Context...)(Data data, scope TableParams!exteneded tableParams, ref T value, ref SerdeFlags!T requiredFlags, ref Context context)
    {
        import core.lifetime: move;
        import mir.conv: to;
        import mir.reflection: isField;

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
                alias impl = deserializeValue;
            }
        }
        else
        {
            alias impl = deserializeValue;
        }

        static immutable excm(string member) = "mir.serde: multiple keys for member '" ~ member ~ "' in " ~ T.stringof ~ " are not allowed.";

        static if (!hasUDA!(__traits(getMember, value, member), serdeAllowMultiple))
            if (__traits(getMember, requiredFlags, member))
                return excm!member;

        __traits(getMember, requiredFlags, member) = true;

        static if (likeList)
        {
            if (data.descriptor.type == IonTypeCode.list)
            {
                foreach (error, ionElem; data.trustedGet!IonList)
                {
                    if (_expect(error, false))
                        return error.ionErrorMsg;
                    Temporal elem;
                    if (auto exc = impl(ionElem, tableParams, elem, context))
                        return exc;
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
                return IonErrorCode.expectedListValue.ionErrorMsg;
            }
            static if (hasTransform)
            {
                static if (isField!(T, member))
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
            foreach(v; data.byKeyValue(context))
            {
                Temporal temporal;
                if (auto exc = impl(v.value, tableParams, temporal, context))
                    return exc;
                __traits(getMember, value, member)[v.key.idup] = move(temporal);
            }
            static if (hasTransform)
            {
                static if (isField!(T, member))
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
            if (auto exc = impl(data, tableParams, proxy, context))
                return exc;
            auto temporal = to!(serdeDeserializationMemberType!(T, member))(move(proxy));
            static if (hasTransform)
                transform(temporal);
            __traits(getMember, value, member) = move(temporal);
            return null;
        }
        else
        static if (isField!(T, member))
        {
            if (auto exc = impl(data, tableParams, __traits(getMember, value, member), context))
                return exc;
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
                    if (auto exc = deserializeListToScopedBuffer!(deserializeValue, exteneded)(data, tableParams, buffer))
                        return exc;
                }
                return () @trusted {
                    ScopedBuffer!E buffer = void;
                    buffer.initialize;
                    if (auto exc = deserializeListToScopedBuffer!(deserializeValue, exteneded)(data, tableParams, buffer))
                        return exc;
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
                if (auto exc = impl(data, tableParams, temporal, context))
                    return exc;
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
    import mir.serde: SerdeException;
    import mir.small_array;
    import mir.small_string;
    import mir.bignum.decimal;

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
    if (auto msg = deserializeValue!(IonSystemSymbolTable_v1 ~ symbolTable)(data, book))
        throw new SerdeException(msg);

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
