/++
+/
module mir.ion.deser.json;

public import mir.serde;

version(LDC) import ldc.attributes: optStrategy;
else private struct optStrategy { string opt; }

private template isSomeMap(T)
{
    import mir.algebraic: Algebraic;
    import mir.string_map: isStringMap;
    static if (__traits(hasMember, T, "_serdeRecursiveAlgebraic"))
        enum isSomeMap = true;
    else
    static if (is(T : K[V], K, V))
        enum isSomeMap = true;
    else
    static if (isStringMap!T)
        enum isSomeMap = true;
    else
    static if (is(T == Algebraic!Types, Types...))
    {
        import std.meta: anySatisfy;
        enum isSomeMap = anySatisfy!(.isSomeMap, T.AllowedTypes);
    }
    else
        enum isSomeMap = false;
}

private template deserializeJsonImpl(bool file)
{
    template deserializeJsonImpl(T)
    {
        static if (isSomeMap!T)
        {
            static if (file)
                static assert(0, "Can't deserialize a map-like type from a file");
            alias deserializeJsonImpl = deserializeDynamicJson!T;
        }
        else
        // @optStrategy("optsize")
        T deserializeJsonImpl(scope const(char)[] text)
        {
            import mir.ion.deser: deserializeValue, DeserializationParams, TableKind;
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
            static if (__traits(hasMember, T, "deserializeFromIon"))
                enum keys = string[].init;
            else
                enum keys = serdeGetDeserializationKeysRecurse!T;

            alias createTableChar = createTable!char;
            static immutable table = createTableChar!(keys, false);

            T value;

            // nMax * 4 is enough. We use larger multiplier to reduce memory allocation count
            auto tapeHolder = ionTapeHolder!(nMax * 8);
            tapeHolder.initialize;
            auto errorInfo = () @trusted { return algo!nMax(table, tapeHolder, text); } ();
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

            auto params = DeserializationParams!(TableKind.compiletime)(ionValue); 
            if (auto exception = deserializeValue!keys(params, value))
                throw exception;

            return value;
        }
    }
}

/++
Deserialize json string to a type trying to do perform less memort allocations.
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

// version(none):
// private template deserializeJsonDynamicImpl(bool file)
// {
//     // @optStrategy("optsize")
//     T deserializeJsonImpl(T)(scope const(char)[] text)
//     {
//         import mir.exception: MirException;
//         import mir.ion.deser: deserializeValue, DeserializationParams, TableKind;
//         import mir.ion.exception: ionErrorMsg;
//         import mir.ion.exception: IonException, ionException;
//         import mir.ion.internal.data_holder;
//         import mir.ion.internal.data_holder: ionPrefix, IonTapeHolder;
//         import mir.ion.internal.stage4_s;
//         import mir.ion.symbol_table: IonSymbolTable;
//         import mir.ion.value: IonDescribedValue, IonValue;
//         import mir.serde: serdeGetDeserializationKeysRecurse, SerdeMirException, SerdeException;
//         import mir.string_table: createTable;
//         import mir.utility: _expect;

//         static if (file)
//             alias algo = singleThreadJsonFile;
//         else
//             alias algo = singleThreadJsonText;

//         enum nMax = 4096u;
//         // enum nMax = 64u;

//         alias TapeHolder = IonTapeHolder!(nMax * 8);
//         TapeHolder tapeHolder = void;
//         tapeHolder.initialize;

//         IonSymbolTable!false table = void;
//         table.initialize;
//         table.startId = 0;

//         auto error = singleThreadJsonText!nMax(table, tapeHolder, text);
//         if (error.code)
//             throw new MirException(error.code.ionErrorMsg, ". location = ", error.location, ", last input key = ", error.key);

//         auto ionValue = IonDescribedValue(tapeHolder.tapeData);

//         import mir.ion.value: IonList, IonDescribedValue;

//         foreach (IonDescribedValue symbolValue; IonList(table.unfinilizedKeysData))
//         {
//             symbolTableBuffer.put(symbolValue.trustedGet(const(char)[]));
//         }


//         enum keys = serdeGetDeserializationKeysRecurse!T;
//         T value;

//         if (false)
//         {
//             if (auto exception = deserializeValue!(keys, true)(IonDescribedValue.init, symbolTable, null, value))
//                 throw exception;
//         }

//         () @trusted {
//             // nMax * 4 is enough. We use larger multiplier to reduce memory allocation count
//             IonTapeHolder!(nMax * 8) tapeHolder = void;
//             tapeHolder.initialize;
//             auto errorInfo = algo!nMax(table, tapeHolder, text);
//             if (errorInfo.code)
//             {
//                 static if (__traits(compiles, () @nogc { throw new Exception(""); }))
//                     throw new SerdeMirException(errorInfo.code.ionErrorMsg, ". location = ", errorInfo.location, ", last input key = ", errorInfo.key);
//                 else
//                     throw errorInfo.code.ionException;
//             }

//             IonDescribedValue ionValue;

//             if (auto error = IonValue(tapeHolder.tapeData).describe(ionValue))
//                 throw error.ionException;

//             ScopedBuffer!(uint, 1024) tableMapBuffer = void;
//             tableMapBuffer.initialize;

//             foreach (key; symbolTable)
//             {
//                 uint id;
//                 if (!table.get(key, id))
//                     id = uint.max;
//                 tableMapBuffer.put(id);
//             }

//             if (auto exception = deserializeValue!(keys, true)(ionValue, symbolTable, tableMapBuffer.data, value))
//                 throw exception;
//         } ();

//         return value;
//     }
// }

/++
Deserialize json string to a type
+/
T deserializeDynamicJson(T)(scope const(char)[] text)
{
    import mir.ion.conv: json2ion;
    import mir.ion.deser.ion: deserializeIon;
    return text.json2ion.deserializeIon!T;
}
