/++
$(H4 High level deserialization API)

IONREF = $(REF_ALTTEXT $(TT $2), $2, mir, ion, $1)$(NBSP)
+/
module mir.ion.deser;

import mir.bignum.decimal: Decimal;
import mir.bignum.integer: BigInt;
import mir.ion.deser.low_level;
import mir.ion.exception;
import mir.ion.symbol_table;
import mir.ion.type_code;
import mir.ion.value;
import mir.serde;
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

/++
+/
T deserializeJson(T)(scope const(char)[] text)
{
    T value;    
    if (auto exception = deserializeValueFromJson(text, value))
        throw exception;
    return value;
}

///
// @safe pure @nogc
version(mir_ion_test) unittest
{
    static struct Book
    {
        SmallString!64 title;
        bool wouldRecommend;
        const(char)[] description;
        uint numberOfNovellas;
        Decimal!1 price;
        double weight;
        SmallArray!(SmallString!16, 10) tags;
    }

    auto book = q{{
        "title": "A Hero of Our Time",
        "wouldRecommend": true,
        "description": null,
        "numberOfNovellas": 5,
        "price": 7.99,
        "weight": 6.88,
        "tags": [
            "russian",
            "novel",
            "19th century"
        ]
        }}
        .deserializeJson!Book;

    import mir.conv: to;

    assert(book.description.length == 0);
    assert(book.numberOfNovellas == 5);
    assert(book.price.to!double == 7.99);
    assert(book.tags.length == 3);
    assert(book.tags[0] == "russian");
    assert(book.tags[1] == "novel");
    assert(book.tags[2] == "19th century");
    assert(book.title == "A Hero of Our Time");
    assert(book.weight == 6.88);
    assert(book.wouldRecommend);
}

/++
+/
SerdeException deserializeValueFromJson(T)(scope const(char)[] text, ref T value)
{
    import mir.ion.exception: ionException;
    import mir.ion.internal.data_holder;
    import mir.ion.internal.stage4_s;
    import mir.ion.symbol_table: CTFE_IonSymbolTable;

    enum nMax = 8192u;

    static immutable table = CTFE_IonSymbolTable(serdeGetDeserializatinKeysRecurse!T);
    auto tapeHolder = IonDataHolder!(nMax * 8)(nMax * 8);
    size_t tapeLength;

    if (auto error = singleThreadJsonImpl!nMax(text, table, tapeHolder, tapeLength))
        return error.ionException;

    IonDescribedValue ionValue;

    if (auto error = IonValue(tapeHolder.data[0 .. tapeLength]).describe(ionValue))
        return error.ionException;

    return deserializeValue!(serdeGetDeserializatinKeysRecurse!T)(ionValue, value);
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
                    if (auto exception = .deserializeValue!symbolTable(ionElem, elem))
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
                import mir.appender;
                ScopedBuffer!E buffer;
                foreach (error, ionElem; data.trustedGet!IonList)
                {
                    if (_expect(error, false))
                        return error.ionException;
                    E elem;
                    if (auto exception = .deserializeValue!symbolTable(ionElem, elem))
                        return exception;
                    import core.lifetime: move;
                    buffer.put(move(elem));
                }

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
            static if (hasUDA!(value, serdeScoped))
                static if (__traits(compiles, { .deserializeScoped!symbolTable(data, temporal); }))
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
                alias impl = deserializeValueMemberImpl!(.deserializeValue!symbolTable, deserializeScoped);

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

///
@safe pure @nogc
version(mir_ion_test) unittest
{
    static struct Book
    {
        SmallString!64 title;
        bool wouldRecommend;
        SmallString!64 description;
        uint numberOfNovellas;
        Decimal!1 price;
        double weight;
        SmallArray!(SmallString!16, 10) tags;
    }

    static immutable symbolTable = ["title", "wouldRecommend", "description", "numberOfNovellas", "price", "weight", "tags"];
    static immutable binaryData = cast(immutable ubyte[]) "\xde\xc9\x8a\x8e\x92A Hero of Our Time\x8b\x11\x8c\x0f\x8d!\x05\x8eS\xc2\x03\x1f\x8fH@\x1b\x85\x1e\xb8Q\xeb\x85\x90\xbe\x9b\x87russian\x85novel\x8c19th century";

    auto data = IonValue(binaryData).describe;
    
    Book book;
    if (auto serdeException = deserializeValue!(IonSystemSymbolTable_v1 ~ symbolTable)(data, book))
        throw serdeException;

    import mir.conv: to;

    assert(book.description.length == 0);
    assert(book.numberOfNovellas == 5);
    assert(book.price.to!double == 7.99);
    assert(book.tags.length == 3);
    assert(book.tags[0] == "russian");
    assert(book.tags[1] == "novel");
    assert(book.tags[2] == "19th century");
    assert(book.title == "A Hero of Our Time");
    assert(book.weight == 6.88);
    assert(book.wouldRecommend);
}

private auto findKey()(string[] symbolTable, string key)
{
    import mir.algorithm.iteration: findIndex;
    auto ret = symbolTable.findIndex!(a => a == key);
    assert(ret != size_t.max, key);
    return ret + 1;
}
