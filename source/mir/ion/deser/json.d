/++
+/
module mir.ion.deser.json;

public import mir.serde;

version(LDC) import ldc.attributes: optStrategy;
else private struct optStrategy { string opt; }

private template deserializeJsonImpl(bool file)
{
    // @optStrategy("optsize")
    T deserializeJsonImpl(T)(scope const(char)[] text)
    {
        import mir.ion.deser: deserializeValue;
        import mir.ion.exception: IonException, ionException;
        import mir.ion.exception: ionErrorMsg;
        import mir.ion.internal.data_holder;
        import mir.ion.internal.stage4_s;
        import mir.ion.value: IonDescribedValue, IonValue;
        import mir.serde: serdeGetDeserializationKeysRecurse, SerdeMirException, SerdeException;
        import mir.string_table: createTable;

        static if (file)
            alias algo = singleThreadJsonFile;
        else
            alias algo = singleThreadJsonText;

        enum nMax = 4096u;
        // enum nMax = 64u;
        enum keys = serdeGetDeserializationKeysRecurse!T;
        alias createTableChar = createTable!char;
        static immutable table = createTableChar!(keys, false);
        T value;

        if (false)
        {
            if (auto exception = deserializeValue!(keys, false)(IonDescribedValue.init, value))
                throw exception;
        }

        () @trusted {
            // nMax * 4 is enough. We use larger multiplier to reduce memory allocation count
            IonTapeHolder!(nMax * 8) tapeHolder = void;
            tapeHolder.initialize;
            auto errorInfo = algo!nMax(table, tapeHolder, text);
            if (errorInfo.code)
            {
                static if (__traits(compiles, () @nogc { throw new Exception(""); }))
                    throw new SerdeMirException(errorInfo.code.ionErrorMsg, ". location = ", errorInfo.location, ", last input key = ", errorInfo.key);
                else
                    throw errorInfo.code.ionException;
            }

            IonDescribedValue ionValue;

            if (auto error = IonValue(tapeHolder.tapeData).describe(ionValue))
                throw error.ionException;

            if (auto exception = deserializeValue!(keys, false)(ionValue, value))
                throw exception;
        } ();

        return value;
    }
}

/++
+/
alias deserializeJson = deserializeJsonImpl!false;

/// Test @nogc deserialization
// @safe pure @nogc
// version(none)
// unittest
// {
//     import mir.serde: serdeIgnoreIn, serdeIgnore, serdeScoped;
//     import mir.bignum.decimal;
//     import mir.rc.array;
//     import mir.small_array;
//     import mir.small_string;

//     static struct Book
//     {
//         SmallString!64 title;
//         bool wouldRecommend;
//         SmallString!128 description; // common `string` and array can be used as well (with GC)
//         uint numberOfNovellas;
//         Decimal!1 price;
//         double weight;

//         // nogc small-array tags
//         SmallArray!(SmallString!16, 10) smallArrayTags;

//         // nogc rc-array tags
//         RCArray!(SmallString!16) rcArrayTags;

//         // nogc scope array tags
//         // when used with `@property` and `@serdeScoped`
//         @serdeIgnore bool tagsSet; // control flag for test

//         @serdeScoped
//         void tags(scope SmallString!16[] tags) @property @safe pure nothrow @nogc
//         {
//             assert(tags.length == 3);
//             assert(tags[0] == "one");
//             assert(tags[1] == "two");
//             assert(tags[2] == "three");
//             tagsSet = true;
//         }
//     }

//     static immutable text = q{{
//         "title": "A Hero of Our Time",
//         "wouldRecommend": true,
//         "description": null,
//         "numberOfNovellas": 5,
//         "price": 7.99,
//         "weight": 6.88,
//         "tags": [
//             "one",
//             "two",
//             "three"
//         ],
//         "rcArrayTags": [
//             "russian",
//             "novel",
//             "19th century"
//         ],
//         "smallArrayTags": [
//             "4",
//             "5",
//             "6"
//         ]
//     }};

//     import mir.conv: to;

//     // enum sbook = text.deserializeJson!Book;

//     auto book = text.deserializeJson!Book;

//     assert(book.description.length == 0);
//     assert(book.numberOfNovellas == 5);
//     assert(book.price.to!double == 7.99);
//     assert(book.tagsSet);
//     assert(book.rcArrayTags.length == 3);
//     assert(book.rcArrayTags[0] == "russian");
//     assert(book.rcArrayTags[1] == "novel");
//     assert(book.rcArrayTags[2] == "19th century");
//     assert(book.smallArrayTags.length == 3);
//     assert(book.smallArrayTags[0] == "4");
//     assert(book.smallArrayTags[1] == "5");
//     assert(book.smallArrayTags[2] == "6");
//     assert(book.title == "A Hero of Our Time");
//     assert(book.weight == 6.88);
//     assert(book.wouldRecommend);
// }

/++
Params: JSON file nam
+/
alias deserializeJsonFile = deserializeJsonImpl!true;

/// Test @nogc deserialization
// version(none)
// @nogc
// unittest
// {
//     import mir.serde: serdeIgnoreIn, serdeIgnore, serdeScoped;
//     import mir.bignum.decimal;
//     import mir.rc.array;
//     import mir.small_array;
//     import mir.small_string;

//     static struct Book
//     {
//         SmallString!64 title;
//         bool wouldRecommend;
//         SmallString!128 description; // common `string` and array can be used as well (with GC)
//         uint numberOfNovellas;
//         Decimal!1 price;
//         double weight;

//         // nogc small-array tags
//         SmallArray!(SmallString!16, 10) smallArrayTags;

//         // nogc rc-array tags
//         RCArray!(SmallString!16) rcArrayTags;

//         // nogc scope array tags
//         // when used with `@property` and `@serdeScoped`
//         @serdeIgnore bool tagsSet; // control flag for test

//         @serdeScoped
//         void tags(scope SmallString!16[] tags) @property @safe pure nothrow @nogc
//         {
//             assert(tags.length == 3);
//             assert(tags[0] == "one");
//             assert(tags[1] == "two");
//             assert(tags[2] == "three");
//             tagsSet = true;
//         }
//     }

//     static immutable text = q{{
//         "title": "A Hero of Our Time",
//         "wouldRecommend": true,
//         "description": null,
//         "numberOfNovellas": 5,
//         "price": 7.99,
//         "weight": 6.88,
//         "tags": [
//             "one",
//             "two",
//             "three"
//         ],
//         "rcArrayTags": [
//             "russian",
//             "novel",
//             "19th century"
//         ],
//         "smallArrayTags": [
//             "4",
//             "5",
//             "6"
//         ]
//     }};

//     import mir.conv: to;

//     // enum sbook = text.deserializeJson!Book;

//     import core.stdc.stdio;
//     enum fileName = "ion_temp.json";
//     auto file = fopen(fileName, "w");
//     assert(file);
//     fputs(text.ptr, file);
//     fclose(file);

//     auto book = fileName.deserializeJsonFile!Book;

//     assert(book.description.length == 0);
//     assert(book.numberOfNovellas == 5);
//     assert(book.price.to!double == 7.99);
//     assert(book.tagsSet);
//     assert(book.rcArrayTags.length == 3);
//     assert(book.rcArrayTags[0] == "russian");
//     assert(book.rcArrayTags[1] == "novel");
//     assert(book.rcArrayTags[2] == "19th century");
//     assert(book.smallArrayTags.length == 3);
//     assert(book.smallArrayTags[0] == "4");
//     assert(book.smallArrayTags[1] == "5");
//     assert(book.smallArrayTags[2] == "6");
//     assert(book.title == "A Hero of Our Time");
//     assert(book.weight == 6.88);
//     assert(book.wouldRecommend);
// }
