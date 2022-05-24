/++
The module can be used for scripting languages to register a universal type serializer in the type system.
+/
module mir.ser.interfaces;

/++
Unified serializer interface.

ISerializer can be used in `serialize` method instead of generic serilizer.

-----
struct S
{
    void serialize(ISerializer serializer) const @safe
    ...
-----
+/
interface ISerializer
{
    import mir.bignum.decimal: Decimal;
    import mir.bignum.low_level_view: BigIntView, WordEndian;
    import mir.ion.type_code: IonTypeCode;
    import mir.lob: Blob, Clob;
    import mir.timestamp : Timestamp;

@safe pure scope:

    /++
    Puts string part. The implementation allows to split string unicode points.
    +/
    void putStringPart(scope const(char)[] value);

    ///
    void stringEnd(size_t state);

    ///
    size_t structBegin(size_t length = size_t.max);

    ///
    void structEnd(size_t state);

    ///
    size_t listBegin(size_t length = size_t.max);

    ///
    void listEnd(size_t state);

    ///
    size_t sexpBegin(size_t length = size_t.max);

    ///
    void sexpEnd(size_t state);

    ///
    void putSymbol(scope const char[] symbol);

    ///
    size_t annotationsBegin();

    ///
    void putAnnotation(scope const(char)[] annotation);

    ///
    void annotationsEnd(size_t state);

    ///
    size_t annotationWrapperBegin();

    ///
    void annotationWrapperEnd(size_t state);

    ///
    void nextTopLevelValue();

    ///
    void putKey(scope const char[] key);

    ///
    final void putValue(ubyte value)
    {
        putValue(ulong(value));
    }

    ///
    final void putValue(ushort value)
    {
        putValue(ulong(value));
    }

    ///
    final void putValue(uint value)
    {
        putValue(ulong(value));
    }

    ///
    final void putValue(byte value)
    {
        putValue(long(value));
    }

    ///
    final void putValue(short value)
    {
        putValue(long(value));
    }

    ///
    final void putValue(int value)
    {
        putValue(long(value));
    }

    ///
    void putValue(long value);

    ///
    void putValue(ulong value);

    ///
    void putValue(float value);

    ///
    void putValue(double value);

    ///
    void putValue(real value);

    ///
    void putValue(BigIntView!(const ubyte, WordEndian.big) value);

    ///
    void putValue(ref const Decimal!256 value);

    ///
    void putValue(typeof(null));

    /// ditto 
    void putNull(IonTypeCode code);

    ///
    void putValue(bool b);

    ///
    void putValue(scope const char[] value);

    ///
    void putValue(Clob value);

    ///
    void putValue(Blob value);

    ///
    void putValue(Timestamp value);

    ///
    void elemBegin();

    ///
    void sexpElemBegin();

    ///
    int serdeTarget() nothrow const @property;
}

/++
Serializer interface wrapper for common serializers.
+/
final class SerializerWrapper(S) : ISerializer
{
    private S* serializer;

    ///
    this(return scope ref S serializer) @trusted pure nothrow @nogc
    {
        this.serializer = &serializer;
    }

@safe pure scope:

    void putStringPart(scope const(char)[] value)
    {
        return serializer.putStringPart(value);
    }

    void stringEnd(size_t state)
    {
        return serializer.stringEnd(state);
    }

    size_t structBegin(size_t length = size_t.max)
    {
        return serializer.structBegin(length);
    }

    void structEnd(size_t state)
    {
        return serializer.structEnd(state);
    }

    size_t listBegin(size_t length = size_t.max)
    {
        return serializer.listBegin(length);
    }

    void listEnd(size_t state)
    {
        return serializer.listEnd(state);
    }

    size_t sexpBegin(size_t length = size_t.max)
    {
        return serializer.sexpBegin(length);
    }

    void sexpEnd(size_t state)
    {
        return serializer.sexpEnd(state);
    }

    void putSymbol(scope const char[] symbol)
    {
        return serializer.putSymbol(symbol);
    }

    size_t annotationsBegin()
    {
        return serializer.annotationsBegin();
    }

    void putAnnotation(scope const(char)[] annotation)
    {
        return serializer.putAnnotation(annotation);
    }

    void annotationsEnd(size_t state)
    {
        return serializer.annotationsEnd(state);
    }

    size_t annotationWrapperBegin()
    {
        return serializer.annotationWrapperBegin();
    }

    void annotationWrapperEnd(size_t state)
    {
        return serializer.annotationWrapperEnd(state);
    }

    void nextTopLevelValue()
    {
        return serializer.nextTopLevelValue();
    }

    void putKey(scope const char[] key)
    {
        return serializer.putKey(key);
    }

    void putValue(long value)
    {
        return serializer.putValue(value);
    }

    void putValue(ulong value)
    {
        return serializer.putValue(value);
    }

    void putValue(float value)
    {
        return serializer.putValue(value);
    }

    void putValue(double value)
    {
        return serializer.putValue(value);
    }

    void putValue(real value)
    {
        return serializer.putValue(value);
    }

    void putValue(BigIntView!(const ubyte, WordEndian.big) value)
    {
        return serializer.putValue(value);
    }

    void putValue(ref const Decimal!256 value)
    {
        return serializer.putValue(value);
    }

    void putValue(typeof(null))
    {
        return serializer.putValue(null);
    }

    void putNull(IonTypeCode code)
    {
        return serializer.putNull(code);
    }

    void putValue(bool value)
    {
        return serializer.putValue(value);
    }

    void putValue(scope const char[] value)
    {
        return serializer.putValue(value);
    }

    void putValue(Clob value)
    {
        return serializer.putValue(value);
    }

    void putValue(Blob value)
    {
        return serializer.putValue(value);
    }

    void putValue(Timestamp value)
    {
        return serializer.putValue(value);
    }

    void elemBegin()
    {
        return serializer.elemBegin();
    }

    void sexpElemBegin()
    {
        return serializer.sexpElemBegin();
    }

    int serdeTarget() nothrow const @property
    {
        return serializer.serdeTarget;
    }
}

unittest
{
    static struct Wrapper(T)
    {
        T value;

        void serialize(S)(scope ref S serializer) const @safe
        {
            import mir.ser: serializeValue;
            import mir.ser.interfaces: SerializerWrapper;
            scope wserializer = new SerializerWrapper!S(serializer);
            auto iserializer = wserializer.ISerializer;
            serializeValue(iserializer, value);
        }
    }

    static auto wrap(T)(T value)
    {
        return Wrapper!T(value);
    }

    import mir.ion.conv;
    import mir.ser.ion;
    import mir.ser.json;
    import mir.ser.text;
    import mir.ion.stream;
    import std.datetime.date;

    assert(wrap(Date(1234, 5, 6)).serializeJson == `"1234-05-06"`);
    assert(wrap(Date(1234, 5, 6)).serializeText == `1234-05-06`);
    assert(wrap(Date(1234, 5, 6)).serializeIon.ion2text == `1234-05-06`);
    immutable(ushort)[] imdata = [10, 20, 30];
    assert(wrap(imdata).serializeIon.ion2text == `[10,20,30]`);

    const ubyte[] data = [0xe0, 0x01, 0x00, 0xea, 0xe9, 0x81, 0x83, 0xd6, 0x87, 0xb4, 0x81, 0x61, 0x81, 0x62, 0xd6, 0x8a, 0x21, 0x01, 0x8b, 0x21, 0x02];
    auto json = wrap(data.IonValueStream).serializeJson;
    assert(json == `{"a":1,"b":2}`);
}

///
unittest
{
    static struct Wrapper(T)
    {
        T value;

        void serialize(ISerializer serializer) const @safe
        {
            import mir.ser: serializeValue;
            serializeValue(serializer, value);
        }
    }

    static auto wrap(T)(T value)
    {
        return Wrapper!T(value);
    }

    import mir.ion.conv;
    import mir.ser.ion;
    import mir.ser.json;
    import mir.ser.text;
    import mir.ion.stream;
    import std.datetime.date;

    assert(wrap(Date(1234, 5, 6)).serializeJson == `"1234-05-06"`);
    assert(wrap(Date(1234, 5, 6)).serializeText == `1234-05-06`);
    assert(wrap(Date(1234, 5, 6)).serializeIon.ion2text == `1234-05-06`);
    immutable(ushort)[] imdata = [10, 20, 30];
    assert(wrap(imdata).serializeIon.ion2text == `[10,20,30]`);

    const ubyte[] data = [0xe0, 0x01, 0x00, 0xea, 0xe9, 0x81, 0x83, 0xd6, 0x87, 0xb4, 0x81, 0x61, 0x81, 0x62, 0xd6, 0x8a, 0x21, 0x01, 0x8b, 0x21, 0x02];
    auto json = wrap(data.IonValueStream).serializeJson;
    assert(json == `{"a":1,"b":2}`);
}
