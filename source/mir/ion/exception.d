/++
Mir Ion error codes, messages, and exceptions.
+/
module mir.ion.exception;

import mir.serde: SerdeException;

/++
Ion Error Codes
+/
enum IonErrorCode
{
    ///
    none,
    ///
    nop,
    ///
    jsonUnexpectedValue,
    ///
    jsonUnexpectedEnd,
    ///
    symbolTableCantInsertKey,
    ///
    illegalTypeDescriptor,
    ///
    unexpectedEndOfData,
    ///
    unexpectedIonType,
    ///
    overflowInParseVarUInt,
    ///
    overflowInParseVarInt,
    ///
    overflowInIntegerValue,
    ///
    overflowInDecimalValue,
    ///
    overflowInSymbolId,
    ///
    zeroAnnotations,
    ///
    illegalBinaryData,
    ///
    illegalTimeStamp,
    ///
    wrongBoolDescriptor,
    ///
    wrongIntDescriptor,
    ///
    wrongFloatDescriptor,
    ///
    nullBool,
    ///
    nullInt,
    ///
    nullFloat,
    ///
    nullTimestamp,
    ///
    expectedNullValue,
    ///
    expectedBoolValue,
    ///
    expectedIntegerValue,
    ///
    expectedFloatingValue,
    ///
    expectedEnumValue,
    ///
    expectedStringValue,
    ///
    expectedCharValue,
    ///
    expectedStructValue,
    ///
    expectedListValue,
    ///
    expectedTimestampValue,
    ///
    requiredDefaultClassConstructor,
    ///
    integerOverflow,
    ///
    smallStringOverflow,
    ///
    smallArrayOverflow,
    ///
    unexpectedVersionMarker,
    ///
    cantParseValueStream,
    ///
    symbolIdIsTooLargeForTheCurrentSymbolTable,
    ///
    invalidLocalSymbolTable,
    ///
    sharedSymbolTablesAreUnsupported,
    ///
    unableToOpenFile,
    ///
    eof,
    ///
    errorReadingFile,
    ///
    errorReadingStream,
    ///
    tooManyElementsForStaticArray,
    ///
    notEnoughElementsForStaticArray,
    ///
    unusedAnnotations,
    ///
    missingAnnotation,
    ///
    expectedIonStructForAnAssociativeArrayDeserialization,
}

///
version(mir_ion_test) unittest
{
    static assert(!IonErrorCode.none);
    static assert(IonErrorCode.none == IonErrorCode.init);
    static assert(IonErrorCode.nop > 0);
}

/++
Params:
    code = $(LREF IonErrorCode)
Returns:
    corresponding error message
+/
string ionErrorMsg()(IonErrorCode code) @property
@safe pure nothrow @nogc
{
    static immutable string[] msgs = [
        null,
        "unexpected NOP Padding",
        "unexpected JSON value",
        "unexpected JSON end",
        "symbol table can't insert key",
        "illegal type descriptor",
        "unexpected end of data",
        "unexpected Ion type",
        "overflow in parseVarUInt",
        "overflow in parseVarInt",
        "overflow in integer value",
        "overflow in decimal value",
        "overflow in symbol id",
        "at least one annotation is required",
        "illegal binary data",
        "illegal timestamp",
        "wrong bool descriptor",
        "wrong int descriptor",
        "wrong float descriptor",
        "null bool",
        "null int",
        "null float",
        "null timestamp",
        "expected null value",
        "expected boolean value",
        "expected integer point value",
        "expected floating value",
        "expected enum value",
        "expected string value",
        "expected char value",
        "expected struct value",
        "expected list value",
        "expected timestamp value",
        "required default class constructor",
        "integer overflow",
        "small string overflow",
        "small array overflow",
        "unexpected version marker",
        "can't parse value stream",
        "symbol id is too large for the current symbol table",
        "invalid local symbol table",
        "shared symbol tables are unsupported",
        "unable to open file",
        "end of file",
        "error reading file",
        "error reading stream",
        "too many elements for static array",
        "not enough elements for static array",
        "unused annotations",
        "missing annotation",
        "expected IonStruct for an associative array deserialization",
    ];
    return msgs[code - IonErrorCode.min];
}

///
@safe pure nothrow @nogc
version(mir_ion_test) unittest
{
    static assert(IonErrorCode.nop.ionErrorMsg == "unexpected NOP Padding", IonErrorCode.nop.ionErrorMsg);
    static assert(IonErrorCode.none.ionErrorMsg is null);
}

version (D_Exceptions):

/++
Mir Ion Exception Class
+/
class IonException : SerdeException
{
    ///
    this(
        string msg,
        string file = __FILE__,
        size_t line = __LINE__,
        Throwable next = null) pure nothrow @nogc @safe 
    {
        super(msg, file, line, next);
    }

    ///
    this(
        string msg,
        Throwable next,
        string file = __FILE__,
        size_t line = __LINE__,
        ) pure nothrow @nogc @safe 
    {
        this(msg, file, line, next);
    }
}

/++
Mir Ion Exception Class
+/
class IonMirException : IonException
{
    import mir.exception: MirThrowableImpl, mirExceptionInitilizePayloadImpl;
    private enum maxMsgLen = 447;
    ///
    mixin MirThrowableImpl;
}

/++
Mir Ion Parser Exception Class

The exception is used for JSON parsing.
+/
class IonParserMirException : IonMirException
{
    ///
    size_t location;

    ///
    this(
        scope const(char)[] msg,
        size_t location,
        string file = __FILE__,
        size_t line = __LINE__,
        Throwable next = null) pure nothrow @nogc @safe 
    {
        this.location = location;
        super(msg, file, line, next);
    }

    ///
    this(
        scope const(char)[] msg,
        size_t location,
        Throwable next,
        string file = __FILE__,
        size_t line = __LINE__,
        ) pure nothrow @nogc @safe 
    {
        this(msg, location, file, line, next);
    }
}

/++
Params:
    code = $(LREF IonErrorCode)
Returns:
    $(LREF IonException)
+/
IonException ionException()(IonErrorCode code) @property
@trusted pure nothrow @nogc
{
    import mir.array.allocation: array;
    import mir.ndslice.topology: map;
    import std.traits: EnumMembers;

    static immutable IonException[] exceptions =
        [EnumMembers!IonErrorCode]
        .map!(code => code ? new IonException("IonException: " ~ code.ionErrorMsg) : null)
        .array;
    return cast(IonException) exceptions[code - IonErrorCode.min];
}

///
@safe pure nothrow @nogc
version(mir_ion_test) unittest
{
    static assert(IonErrorCode.nop.ionException.msg == "IonException: unexpected NOP Padding", IonErrorCode.nop.ionException.msg);
    static assert(IonErrorCode.none.ionException is null);
}

package auto unqualException(T)(T exception) @trusted pure nothrow @nogc
    // if (is(T : const Exception))
{
    return cast() exception;
}
