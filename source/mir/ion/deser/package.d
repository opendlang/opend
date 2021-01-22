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

private SerdeException unexpectedIonTypeCode(string msg = "Unexpected Ion type code")(IonTypeCode code)
    @safe pure nothrow @nogc
{
    import std.traits: EnumMembers;
    import mir.conv: to;
    static immutable exc(IonTypeCode code) = new SerdeException(msg ~ " " ~ code.to!string);

    switch (code)
    {
        foreach (member; EnumMembers!IonTypeCode)
        {case member:
            return exc!member;
        }
        default:
            static immutable ret = new SerdeException("Wrong encoding of Ion type code");
            return ret;
    }
}

SerdeException deserializeScoped(T)(IonDescribedValue data, ref T value)
    if (isFirstOrderSerdeType!T)
{
    return deserializeScopedValueImpl(data, value).ionException;
}

SerdeException deserializeValue_(T)(IonDescribedValue data, ref T value)
    if (isFirstOrderSerdeType!T)
{
    return deserializeValueImpl(data, value).ionException;
}

template deserializeListToScopedBuffer(alias impl)
{
    import mir.appender: ScopedBuffer;
    private SerdeException deserializeListToScopedBuffer(E, size_t bytes)(IonDescribedValue data, ref ScopedBuffer!(E, bytes) buffer)
    {
        if (_expect(data.descriptor.type != IonTypeCode.list, false))
            return IonErrorCode.expectedListValue.ionException;
        foreach (error, ionElem; data.trustedGet!IonList)
        {
            if (_expect(error, false))
                return error.ionException;
            E value;
            if (auto exc = impl(ionElem, value))
                return exc;
            import core.lifetime: move;
            buffer.put(move(value));
        }
        return null;
    }
}

/++
Deserialize aggregate value using compile time symbol table
+/
template deserializeValue(string[] symbolTable)
{
    /++
    Deserialize aggregate value
    Params:
        data = $(IONREF value, IonDescribedValue)
        value = value to deserialize
    Returns: `SerdeException`
    +/
    SerdeException deserializeValue(T)(IonDescribedValue data, ref T value)
        if (!isFirstOrderSerdeType!T)
    {
        import mir.rc.array: RCArray;

        static if (__traits(hasMember, value, "deserializeFromIon"))
        {
            return __traits(getMember, value, "deserializeFromIon")(data);
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
                    if (auto exc = .deserializeValue!symbolTable(ionElem, elem))
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
            return IonErrorCode.expectedListValue.ionException;
        }
        else
        static if (is(T == D[], D))
        {
            alias E = Unqual!D;
            if (data.descriptor.type == IonTypeCode.list)
            {
                import mir.appender: ScopedBuffer;
                ScopedBuffer!E buffer;
                if (auto exc = deserializeListToScopedBuffer!(.deserializeValue!symbolTable)(data, buffer))
                    return exc;

                import std.array: uninitializedArray;
                (()@trusted {
                    auto ar = uninitializedArray!(E[])(buffer.length);
                    buffer.moveDataAndEmplaceTo(ar);
                    value = cast(T) ar;
                })();
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
        static if (is(T == RCArray!D, D))
        {
            alias E = Unqual!D;
            if (data.descriptor.type == IonTypeCode.list)
            {
                import mir.appender: ScopedBuffer;
                ScopedBuffer!E buffer;
                if (auto exc = deserializeListToScopedBuffer!(.deserializeValue!symbolTable)(data, buffer))
                    return exc;

                (()@trusted @nogc {
                    auto ar = RCArray!E(buffer.length, false);
                    buffer.moveDataAndEmplaceTo(ar[]);
                    static if (__traits(compiles, value = ar))
                        value = ar;
                    else
                        value = ar.opCast!T;
                })();
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
        static if (isNullable!T)
        {
            // TODO: check that descriptor.type correspond underlaying type
            if (data.descriptor.L == 0xF)
            {
                value.nullify;
                return null;
            }

            typeof(value.get) payload;
            if (auto exc = .deserializeValueImpl!symbolTable(data, payload))
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

            if (auto exc = impl(data, temporal))
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
                    static immutable exc = new SerdeException("Can't construct null value of type" ~ T.stringof);
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
                        static immutable cantConstructObjectExc = new SerdeException(T.stringof ~ " must be either not null or have a default constructor.");
                        return cantConstructObjectExc;
                    }
                }
            }

            IonStruct ionValue;
            if (auto error = data.get(ionValue))
            {
                return error.ionException;
            }

            SerdeFlags!T requiredFlags;

            static if (hasUDA!(T, serdeOrderedIn))
            {
                SerdeOrderedDummy!T temporal;
                if (auto exc = .deserializeValue!symbolTable(data, temporal))
                    return exc;
                temporal.serdeFinalizeTarget(value, requiredFlags);
            }
            else
            {
                alias impl = deserializeValueMember!(.deserializeValue!symbolTable, deserializeScoped);

                static immutable exc(string member) = new SerdeException("mir.ion.deser: non-optional member '" ~ member ~ "' in " ~ T.stringof ~ " is missing.");
                
                enum hasUnexpectedKeyHandler = __traits(hasMember, T, "serdeUnexpectedKeyHandler");
                static if (!hasUnexpectedKeyHandler)
                    static immutable unexpectedKeyException = new SerdeException("Unexpected key when deserializing " ~ T.stringof);


                import std.meta: staticMap, aliasSeqOf;
                static if (hasUDA!(T, serdeRealOrderedIn))
                {
                    static assert (!hasUnexpectedKeyHandler, "serdeRealOrderedIn aggregate type attribute is not compatible with `serdeUnexpectedKeyHandler` method");
                    static foreach(member; serdeFinalProxyDeserializableMembers!T)
                    {{
                        enum keys = serdeGetKeysIn!(__traits(getMember, value, member));
                        static if (keys.length)
                        {
                            foreach (symbolID, elem; ionValue)
                            {
                                switch(symbolID)
                                {
                                    static foreach (key; keys)
                                    {
                                    case findKey(symbolTable, key):
                                    }
                                        if (auto mexp = impl!member(elem, value, requiredFlags))
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
                    foreach (symbolID, elem; ionValue)
                    {
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
                                if (auto mexp = impl!member(elem, value, requiredFlags))
                                    return mexp;
                                break S;
                                }
                            }}
                            default:
                                static immutable symbolTableInstance = symbolTable;
                                static if (hasUnexpectedKeyHandler)
                                    value.serdeUnexpectedKeyHandler(symbolID == 0 || symbolID > symbolTable.length ? "<@unknown key@>" : symbolTableInstance[symbolID - 1]);
                                else
                                    return unexpectedKeyException;
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

private template deserializeValueMember(alias deserializeValue, alias deserializeScoped)
{
    ///
    SerdeException deserializeValueMember(string member, Data, T, Context...)(Data data, ref T value, ref SerdeFlags!T requiredFlags, ref Context context)
    {
        import core.lifetime: move;
        import mir.conv: to;
        import mir.reflection: isField;

        enum likeList = hasUDA!(__traits(getMember, value, member), serdeLikeList);
        enum likeStruct  = hasUDA!(__traits(getMember, value, member), serdeLikeStruct);
        enum hasProxy = hasUDA!(__traits(getMember, value, member), serdeProxy);
        enum hasScoped = hasUDA!(__traits(getMember, value, member), serdeScoped);
        enum hasTransform = hasUDA!(__traits(getMember, value, member), serdeTransformIn);

        static if (hasTransform)
            alias transform = serdeGetTransformIn!(__traits(getMember, value, member));

        static assert (likeList + likeStruct <= 1, T.stringof ~ "." ~ member ~ " can't have both @serdeLikeStruct and @serdeLikeList attributes");
        static assert (hasProxy >= likeStruct, T.stringof ~ "." ~ member ~ " should have a Proxy type for deserialization");
        static assert (hasProxy >= likeList, T.stringof ~ "." ~ member ~ " should have a Proxy type for deserialization");

        alias Member = serdeDeserializationMemberType!(T, member);

        static if (hasProxy)
            alias Temporal = serdeGetProxy!(__traits(getMember, value, member));
        else
            alias Temporal = Member;

        static if (hasScoped)
            static if (__traits(compiles, { Temporal temporal; deserializeScoped(data, temporal); }))
                alias impl = deserializeScoped;
            else
                alias impl = deserializeValue;
        else
            alias impl = deserializeValue;

        static immutable excm(string member) = new SerdeException("mir.serde: multiple keys for member '" ~ member ~ "' in " ~ T.stringof ~ " are not allowed.");

        static if (!hasUDA!(__traits(getMember, value, member), serdeAllowMultiple))
            if (__traits(getMember, requiredFlags, member))
                return excm!member;

        __traits(getMember, requiredFlags, member) = true;

        static if (likeList)
        {
            foreach(elem; data.byElement(context))
            {
                Temporal temporal;
                if (auto exc = impl(elem, temporal, context))
                    return exc;
                __traits(getMember, value, member).put(move(temporal));
            }
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
        else
        static if (likeStruct)
        {
            foreach(v; data.byKeyValue(context))
            {
                Temporal temporal;
                if (auto exc = impl(v.value, temporal, context))
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
        }
        else
        static if (hasProxy)
        {
            Temporal proxy;
            if (auto exc = impl(data, proxy, context))
                return exc;
            auto temporal = to!(serdeDeserializationMemberType!(T, member))(move(proxy));
            static if (hasTransform)
                transform(temporal);
            __traits(getMember, value, member) = move(temporal);
        }
        else
        static if (isField!(T, member))
        {
            if (auto exc = impl(data, __traits(getMember, value, member), context))
                return exc;
            static if (hasTransform)
                transform(__traits(getMember, value, member));
        }
        else
        {
            static if (hasScoped && is(Member == D[], D) && !is(Unqual!D == char))
            {
                import mir.appender: ScopedBuffer;
                alias E = Unqual!D;
                ScopedBuffer!E buffer;
                if (auto exc = deserializeListToScopedBuffer!deserializeValue(data, buffer))
                    return exc;
                auto temporal = (()@trusted => cast(Member)buffer.data)();
            }
            else
            {
                Member temporal;
                if (auto exc = impl(data, temporal, context))
                    return exc;
            }
            static if (hasTransform)
                transform(temporal);
            __traits(getMember, value, member) = move(temporal);
        }

        return null;
    }
}

///
@safe pure
version(mir_ion_test) unittest
{
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
    if (auto serdeException = deserializeValue!(IonSystemSymbolTable_v1 ~ symbolTable)(data, book))
        throw serdeException;

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
