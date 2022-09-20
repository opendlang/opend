/++
$(H1 Mutable Ion value with IonNull support)

This module contains a single alias definition and doesn't provide Ion serialization API.

License: $(HTTP www.apache.org/licenses/LICENSE-2.0, Apache-2.0)
Authors: Ilya Yaroshenko 
Macros:
+/
module mir.algebraic_alias.ion_ext;

import mir.algebraic: Algebraic, This;
public import mir.annotated: Annotated;
public import mir.ion.value: IonNull;
public import mir.ion.type_code: IonTypeCode;
public import mir.lob: Clob, Blob;
public import mir.string_map: StringMap;
public import mir.timestamp: Timestamp;


/++
Definition union for $(LREF IonExtAlgebraic).
+/
union IonExt_
{
    ///
    IonNull null_;
    ///
    bool boolean;
    ///
    long integer;
    ///
    double float_;
    ///
    immutable(char)[] string;
    ///
    Blob blob;
    ///
    Clob clob;
    ///
    Timestamp timestamp;
    /// Self alias in array.
    This[] array;
    /// Self alias in $(MREF mir,string_map).
    StringMap!This object;
    /// Self alias in $(MREF mir,annotated).
    Annotated!This annotated;
}

/++
Ion tagged algebraic alias.

The example below shows only the basic features. Advanced API to work with algebraic types can be found at $(GMREF mir-core, mir,algebraic).
See also $(MREF mir,string_map) - ordered string-value associative array.
+/
alias IonExtAlgebraic = Algebraic!IonExt_;

///
unittest
{
    import mir.ndslice.topology: map;
    import mir.array.allocation: array;

    IonExtAlgebraic value;

    StringMap!IonExtAlgebraic object;

    // Default
    assert(value._is!IonNull);
    assert(value.get!IonNull == IonTypeCode.null_.IonNull);
    assert(value.kind == IonExtAlgebraic.Kind.null_);

    // Boolean
    value = object["bool"] = true;
    assert(value == true);
    assert(value.kind == IonExtAlgebraic.Kind.boolean);
    // access
    assert(value.boolean == true);
    assert(value.get!bool == true);
    assert(value.get!"boolean" == true);
    assert(value.get!(IonExtAlgebraic.Kind.boolean) == true);
    // nothrow access
    assert(value.trustedGet!bool == true);
    assert(value.trustedGet!"boolean" == true);
    assert(value.trustedGet!(IonExtAlgebraic.Kind.boolean) == true);
    // checks
    assert(!value._is!string);
    assert(value._is!bool);
    assert(value._is!"boolean");
    assert(value._is!(IonExtAlgebraic.Kind.boolean));

    // Null
    value = object["null"] = IonTypeCode.string.IonNull;
    assert(value._is!IonNull);
    assert(value == IonTypeCode.string.IonNull);
    assert(value.kind == IonExtAlgebraic.Kind.null_);
    assert(value.null_ == IonTypeCode.string.IonNull);
    assert(value.get!IonNull == IonTypeCode.string.IonNull);
    assert(value.get!(IonExtAlgebraic.Kind.null_) == IonTypeCode.string.IonNull);

    // String
    value = object["string"] = "s";
    assert(value.kind == IonExtAlgebraic.Kind.string);
    assert(value == "s");
    // access
    // Yep, `string` here is an alias to `get!(immutable(char)[])` method
    assert(value.string == "s");
    // `string` here is an alias of type `immutable(char)[]`
    assert(value.get!string == "s");
    assert(value.get!"string" == "s");
    // finally, `string` here is an enum meber
    assert(value.get!(IonExtAlgebraic.Kind.string) == "s");

    // Integer
    value = object["integer"] = 4;
    assert(value.kind == IonExtAlgebraic.Kind.integer);
    assert(value == 4);
    assert(value != 4.0);
    assert(value.integer == 4);

    // Float
    value = object["float"] = 3.0;
    assert(value.kind == IonExtAlgebraic.Kind.float_);
    assert(value != 3);
    assert(value == 3.0);
    assert(value.float_ == 3.0);

    // Array
    IonExtAlgebraic[] arr = [0, 1, 2, 3, 4].map!IonExtAlgebraic.array;

    value = object["array"] = arr;
    assert(value.kind == IonExtAlgebraic.Kind.array);
    assert(value == arr);
    assert(value.array[3] == 3);

    // Object
    assert(object.keys == ["bool", "null", "string", "integer", "float", "array"]);
    object.values[0] = "false";
    assert(object["bool"] == "false"); // it is a string now
    object.remove("bool"); // remove the member

    value = object["array"] = object;
    assert(value.kind == IonExtAlgebraic.Kind.object);
    assert(value.object.keys is object.keys);

    IonExtAlgebraic[string] aa = object.toAA;
    object = aa.StringMap!IonExtAlgebraic;

    IonExtAlgebraic fromAA = ["a" : IonExtAlgebraic(3), "b" : IonExtAlgebraic("b")];
    assert(fromAA.object["a"] == 3);
    assert(fromAA.object["b"] == "b");

    auto annotated = Annotated!IonExtAlgebraic(["birthday"], Timestamp("2001-01-01"));
    value = annotated;
    assert(value == annotated);
    value = annotated.IonExtAlgebraic;
    assert(value == annotated);
}
