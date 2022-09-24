/++
Ion Type enumeration and encoding.

Macros:
AlgorithmREF = $(GREF_ALTTEXT mir-algorithm, $(TT $2), $2, mir, $1)$(NBSP)
SUBREF = $(REF_ALTTEXT $(TT $2), $2, mir, ion, $1)$(NBSP)
+/
module mir.ion.type_code;

/++
Codes for $(HTTP amzn.github.io/ion-docs/docs/binary.html#typed-value-formats, Typed Value Formats)
+/
enum IonTypeCode
{
    /++
    Spec: $(HTTP http://amzn.github.io/ion-docs/docs/binary.html#0-null, 0: null)
    D_type: $(SUBREF value, IonNull).
    +/
    null_,

    /++
    Spec: $(HTTP http://amzn.github.io/ion-docs/docs/binary.html#1-bool, 1: bool)
    D_type: `bool`
    +/
    bool_,

    /++
    Spec: $(HTTP http://amzn.github.io/ion-docs/docs/binary.html#2-and-3-int, 2 and 3: int)
    D_type: $(SUBREF value, IonUInt) and $(SUBREF value, IonNInt)
    +/
    uInt,
    /// ditto
    nInt,

    /++
    Spec: $(HTTP http://amzn.github.io/ion-docs/docs/binary.html#4-float, 4: float)
    D_type: $(SUBREF value, IonFloat)
    +/
    float_,

    /++
    Spec: $(HTTP http://amzn.github.io/ion-docs/docs/binary.html#5-decimal, 5: decimal)
    D_type: $(SUBREF value, IonDecimal)
    +/
    decimal,

    /++
    Spec: $(HTTP http://amzn.github.io/ion-docs/docs/binary.html#6-timestamp, 6: timestamp)
    D_type: $(SUBREF value, IonTimestamp)
    +/
    timestamp,

    /++
    Spec: $(HTTP http://amzn.github.io/ion-docs/docs/binary.html#7-symbol, 7: symbol)
    D_type: $(SUBREF value, IonSymbolID)
    +/
    symbol,

    /++
    Spec: $(HTTP http://amzn.github.io/ion-docs/docs/binary.html#8-string, 8: string)
    D_type: `const(char)[]`
    +/
    string,

    /++
    Spec: $(HTTP http://amzn.github.io/ion-docs/docs/binary.html#9-clob, 9: clob)
    D_type: $(AlgorithmREF lob, Clob)
    +/
    clob,

    /++
    Spec: $(HTTP 1http://amzn.github.io/ion-docs/docs/binary.html#0-blob, 10: blob)
    D_type: $(AlgorithmREF lob, Blob)
    +/
    blob,

    /++
    Spec: $(HTTP 1http://amzn.github.io/ion-docs/docs/binary.html#1-list, 11: list)
    D_type: $(SUBREF value, IonList)
    +/
    list,

    /++
    Spec: $(HTTP 1http://amzn.github.io/ion-docs/docs/binary.html#2-sexp, 12: sexp)
    D_type: $(SUBREF value, IonSexp)
    +/
    sexp,

    /++
    Spec: $(HTTP 1http://amzn.github.io/ion-docs/docs/binary.html#3-struct, 13: struct)
    D_type: $(SUBREF value, IonStruct)
    +/
    struct_,

    /++
    Spec: $(HTTP 1http://amzn.github.io/ion-docs/docs/binary.html#4-annotations, 14: Annotations)
    D_type: $(SUBREF value, IonAnnotationWrapper)
    +/
    annotations,
}

/++
Returns: text Ion representation of null type code.
+/
string nullStringOf()(IonTypeCode code) @safe pure nothrow @nogc
{
    final switch(code)
    {
        case IonTypeCode.null_:
            return "null";
        case IonTypeCode.bool_:
            return "null.bool";
        case IonTypeCode.uInt:
        case IonTypeCode.nInt:
            return "null.int";
        case IonTypeCode.float_:
            return "null.float";
        case IonTypeCode.decimal:
            return "null.decimal";
        case IonTypeCode.timestamp:
            return "null.timestamp";
        case IonTypeCode.symbol:
            return "null.symbol";
        case IonTypeCode.string:
            return "null.string";
        case IonTypeCode.clob:
            return "null.clob";
        case IonTypeCode.blob:
            return "null.blob";
        case IonTypeCode.list:
            return "null.list";
        case IonTypeCode.sexp:
            return "null.sexp";
        case IonTypeCode.struct_:
            return "null.struct";
        case IonTypeCode.annotations:
            return "null.annotations"; // invalid
    }
}

/++
Returns: JSON representation of null value that can be deserialized to an algebraic types.
Empty strings, structs, and lists are used instead of `null` value for the corresponding codes.
+/
string nullStringJsonAlternative()(IonTypeCode code) @safe pure nothrow @nogc
{
    switch(code)
    {
        case IonTypeCode.symbol:
        case IonTypeCode.string:
        case IonTypeCode.clob:
            return `""`;
        case IonTypeCode.list:
        case IonTypeCode.sexp:
            return `[]`;
        case IonTypeCode.struct_:
            return `{}`;
        default:
            return `null`;
    }
}
