/++
Authros: Ilya Yaroshenko
+/
module mir.ion.ser.bloomberg;

version(bloomberg):

static import blpapi = mir.bloomberg.blpapi;
private alias validate = blpapi.validateBloombergErroCode;
public import mir.bloomberg.blpapi : BloombergElement = Element;
// version(none):

/++
Ion serialization back-end
+/
struct BloombergSerializer
{
    import mir.format: stringBuf, getData;
    import mir.bignum.decimal: Decimal;
    import mir.bignum.low_level_view: WordEndian;
    import mir.bignum.integer: BigInt;
    import mir.ion.type_code;
    import mir.lob;
    import mir.timestamp;
    import mir.serde: SerdeTarget;
    import std.traits: isNumeric;
    import mir.ion.exception: IonException;

    private static immutable bloombergClobSerializationIsntImplemented = new IonException("Bloomberg CLOB serialization isn't implemented.");
    private static immutable bloombergBlobSerializationIsntImplemented = new IonException("Bloomberg BLOB serialization isn't implemented.");

    ///
    BloombergElement* nextValue;

    ///
    BloombergElement* aggregateValue;

    ///
    stringBuf currentPartString;

    /// Mutable value used to choose format specidied or user-defined serialization specializations
    int serdeTarget = SerdeTarget.bloomberg;

@safe pure @nogc:

    private const(char)* toScopeStringz(scope const(char)[] value) @trusted return scope nothrow
    {
        currentPartString.reset;
        currentPartString.put(value);
        currentPartString.put('\0');
        return currentPartString.data.ptr;
    }

    private void pushState(BloombergElement* state)
    {
        aggregateValue = state;
        nextValue = null;
    }

    private BloombergElement* popState()
    {
        auto state = aggregateValue;
        aggregateValue = nextValue;
        nextValue = null;
        return state;
    }

    ///
    BloombergElement* stringBegin()
    {
        currentPartString.reset;
        return null;
    }

    /++
    Puts string part. The implementation allows to split string unicode points.
    +/
    void putStringPart(scope const char[] value)
    {
        import mir.format: printEscaped, EscapeFormat;
        currentPartString.put(value);
    }

    ///
    void stringEnd(BloombergElement*) @trusted
    {
        if (currentPartString.length == 1)
        {
            blpapi.setValueChar(nextValue, *currentPartString.data.ptr, 0).validate;
        }
        else
        {
            currentPartString.put('\0');
            blpapi.setValueString(nextValue, currentPartString.data.ptr, 0).validate;
        }
        nextValue = null;
    }

    private blpapi.Name* getName(scope const char* str)
    {
        if (auto name = blpapi.nameFindName(str))
            return name;
        return blpapi.nameCreate(str);
    }

    private blpapi.Name* getName(scope const char[] str)
    {
        return getName(toScopeStringz(str));
    }

    ///
    void putSymbolPtr(scope const char* value)
    {
        auto name = getName(value);
        blpapi.setValueFromName(nextValue, name, 0).validate;
        blpapi.nameDestroy(name);
        nextValue = null;
    }

    ///
    void putSymbol(scope const char[] value)
    {
        return putSymbolPtr(toScopeStringz(value));
    }

    ///
    BloombergElement* structBegin(size_t length = 0)
    {
        return popState;
    }

    ///
    void structEnd(BloombergElement* state)
    {
        pushState(state);
    }

    ///
    alias listBegin = structBegin;

    ///
    alias listEnd = structEnd;

    ///
    alias sexpBegin = listBegin;

    ///
    alias sexpEnd = listEnd;

    ///
    BloombergElement* annotationsBegin()
    {
        return aggregateValue;
    }

    ///
    void putAnnotationPtr(scope const char* value)
    {
        aggregateValue = nextValue;
        auto name = getName(value);
        blpapi.setChoice(nextValue, nextValue, null, name, 0).validate;
        blpapi.nameDestroy(name);
    }

    ///
    void putAnnotation(scope const char[] value) @trusted
    {
        putAnnotationPtr(toScopeStringz(value));
    }

    ///
    void annotationsEnd(BloombergElement* state)
    {
        aggregateValue = state;
    }

    ///
    BloombergElement* annotationWrapperBegin()
    {
        return null;
    }

    ///
    void annotationWrapperEnd(BloombergElement*)
    {
    }

    ///
    void nextTopLevelValue()
    {
        static immutable exc = new IonException("Can't serialize to multiple Bloomberg Elements at once.");
        throw exc;
    }

    ///
    void putKeyPtr(scope const char* key)
    {
        assert(nextValue is null);
        auto name = getName(key);
        blpapi.getElement(aggregateValue, nextValue, null, name).validate;
        blpapi.nameDestroy(name);
        assert(nextValue !is null);
    }

    ///
    void putKey(scope const char[] key)
    {
        putKeyPtr(toScopeStringz(key));
    }

    ///
    void putValue(Num)(const Num value)
        if (isNumeric!Num && !is(Num == enum))
    {
        import mir.internal.utility: isFloatingPoint;

        assert(nextValue);
        static if (isFloatingPoint!Num)
        {
            if (float(value) is value)
            {
                blpapi.setValueFloat32(nextValue, value, 0).validate;
            }
            else
            {
                blpapi.setValueFloat64(nextValue, value, 0).validate;
            }
        }
        else
        static if (is(Num == int) || Num.sizeof <= 2)
        {
            static if (is(Num == ulong))
            {
                if (value > long.max)
                {
                    static immutable exc = new SerdeException("BloombergSerializer: integer overflow");
                    throw exc;
                }
            }

            (cast(int) value == cast(long) value
                 ? blpapi.setValueInt32(nextValue, value, 0)
                 : blpapi.setValueInt64(nextValue, value, 0))
                 .validate;
        }
        nextValue = null;
    }

    ///
    void putValue(W, WordEndian endian)(BigIntView!(W, endian) view)
    {
        auto i = cast(long) view;
        if (view != i)
        {
            static immutable exc = new SerdeException("BloombergSerializer: integer overflow");
            throw exc;
        }
        putValue(num);
    }

    ///
    void putValue(size_t size)(auto ref const BigInt!size num)
    {
        putValue(num.view);
    }

    ///
    void putValue(size_t size)(auto ref const Decimal!size num)
    {
        putValue(cast(double)num);
    }

    ///
    void putValue(typeof(null))
    {
        assert(nextValue);
        nextValue = null;
    }

    /// ditto 
    void putNull(IonTypeCode code)
    {
        putValue(null);
    }

    ///
    void putValue(bool b)
    {
        assert(nextValue);
        blpapi.setValueBool(nextValue, b, 0).validate;
        nextValue = null;
    }

    ///
    void putValue(scope const char[] value)
    {
        auto state = stringBegin;
        putStringPart(value);
        stringEnd(state);
    }

    ///
    void putValue(Clob value)
    {
        throw bloombergClobSerializationIsntImplemented;
    }

    ///
    void putValue(Blob value)
    {
        throw bloombergBlobSerializationIsntImplemented;
    }

    ///
    void putValue(Timestamp value)
    {
        blpapi.HighPrecisionDatetime dt = value;
        blpapi.setValueHighPrecisionDatetime(nextValue, dt, 0).validate;
        nextValue = null;
    }

    ///
    void elemBegin()
    {
        assert(nextValue is null);
        blpapi.appendElement(aggregateValue, nextValue).validate;
    }

    ///
    alias sexpElemBegin = elemBegin;
}
