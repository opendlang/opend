/++
+/
module mir.ion.deser.json;

public import mir.serde;

/++
+/
T deserializeJson(T)(scope const(char)[] text)
{
    import mir.ion.deser: deserializeValue;
    import mir.ion.exception: ionErrorMsg;
    import mir.ion.internal.data_holder;
    import mir.ion.internal.stage4_s;
    import mir.ion.value: IonDescribedValue, IonValue;
    import mir.serde: serdeGetDeserializationKeysRecurse, SerdeMirException, SerdeException;
    import mir.string_table: createTable;

    enum nMax = 4096u;
    // enum nMax = 128u;
    enum keys = serdeGetDeserializationKeysRecurse!T;
    alias createTableChar = createTable!char;
    static immutable table = createTableChar!(keys, false);
    T value;

    // nMax * 4 is enough. We use larger multiplier to reduce memory allocation count
    auto tapeHolder = IonTapeHolder!(nMax * 8)(nMax * 8);
    auto errorInfo = singleThreadJsonImpl!nMax(text, table, tapeHolder);
    if (errorInfo.code)
        throw new SerdeMirException(errorInfo.code.ionErrorMsg, ". location = ", errorInfo.location, ", last input key = ", errorInfo.key);

    IonDescribedValue ionValue;

    if (auto error = IonValue(tapeHolder.tapeData).describe(ionValue))
        throw new SerdeException(error.ionErrorMsg);

    if (auto msg = deserializeValue!(keys, false)(ionValue, value))
        throw new SerdeException(msg);
    return value;
}

/// Test @nogc deserialization
@safe pure @nogc
unittest
{
    import mir.serde: serdeIgnoreIn, serdeIgnore, serdeScoped;
    import mir.bignum.decimal;
    import mir.rc.array;
    import mir.small_array;
    import mir.small_string;

    static struct Book
    {
        SmallString!64 title;
        bool wouldRecommend;
        SmallString!128 description; // common `string` and array can be used as well (with GC)
        uint numberOfNovellas;
        Decimal!1 price;
        double weight;

        // nogc small-array tags
        SmallArray!(SmallString!16, 10) smallArrayTags;

        // nogc rc-array tags
        RCArray!(SmallString!16) rcArrayTags;

        // nogc scope array tags
        // when used with `@property` and `@serdeScoped`
        @serdeIgnore bool tagsSet; // control flag for test

        @serdeScoped
        void tags(scope SmallString!16[] tags) @property @safe pure nothrow @nogc
        {
            assert(tags.length == 3);
            assert(tags[0] == "one");
            assert(tags[1] == "two");
            assert(tags[2] == "three");
            tagsSet = true;
        }
    }

    static immutable text = q{{
        "title": "A Hero of Our Time",
        "wouldRecommend": true,
        "description": null,
        "numberOfNovellas": 5,
        "price": 7.99,
        "weight": 6.88,
        "tags": [
            "one",
            "two",
            "three"
        ],
        "rcArrayTags": [
            "russian",
            "novel",
            "19th century"
        ],
        "smallArrayTags": [
            "4",
            "5",
            "6"
        ]
    }};

    import mir.conv: to;

    // enum sbook = text.deserializeJson!Book;

    auto book = text.deserializeJson!Book;

    assert(book.description.length == 0);
    assert(book.numberOfNovellas == 5);
    assert(book.price.to!double == 7.99);
    assert(book.tagsSet);
    assert(book.rcArrayTags.length == 3);
    assert(book.rcArrayTags[0] == "russian");
    assert(book.rcArrayTags[1] == "novel");
    assert(book.rcArrayTags[2] == "19th century");
    assert(book.smallArrayTags.length == 3);
    assert(book.smallArrayTags[0] == "4");
    assert(book.smallArrayTags[1] == "5");
    assert(book.smallArrayTags[2] == "6");
    assert(book.title == "A Hero of Our Time");
    assert(book.weight == 6.88);
    assert(book.wouldRecommend);
}
