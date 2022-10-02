/++
$(H4 High level serialization API)

Macros:
IONREF = $(REF_ALTTEXT $(TT $2), $2, mir, ion, $1)$(NBSP)
Authros: Ilia Ki
+/
module mir.ser;

import mir.conv;
import mir.deser;
import mir.ion.internal.basic_types;
import mir.ion.type_code;
import mir.reflection;
import std.meta;
import std.traits;

public import mir.serde;

static immutable cannotSerializeVoidMsg = "Can't serialize none (void) value of the algebraic type";
version (D_Exceptions)
    private static immutable cannotSerializeVoid = new Exception(cannotSerializeVoidMsg);

private noreturn serializeVoidHandler() @safe pure @nogc
{
    version (D_Exceptions)
        throw cannotSerializeVoid;
    else
        assert(0, cannotSerializeVoidMsg);
}

private noreturn serializeVoidHandlerWithSerializer(S)(scope ref S serializer) @safe pure @nogc
{
    version (D_Exceptions)
        throw cannotSerializeVoid;
    else
        assert(0, cannotSerializeVoidMsg);
}

private noreturn serializeVoidHandlerWithSerializerAndState(S)(scope ref S serializer, size_t state) @safe pure @nogc
{
    version (D_Exceptions)
        throw cannotSerializeVoid;
    else
        assert(0, cannotSerializeVoidMsg);
}

/// `null` value serialization
void serializeValue(S)(scope ref S serializer, typeof(null))
{
    serializer.putValue(null);
}

///
version(mir_ion_test)
unittest
{
    import mir.ser.json: serializeJson;
    assert(serializeJson(null) == `null`, serializeJson(null));
}

/// Number serialization
void serializeValue(S, V)(scope ref S serializer, const V value)
    if (isNumeric!V && !is(V == enum))
{
    serializer.putValue(value);
}

///
version(mir_ion_test)
unittest
{
    import mir.ser.json: serializeJson;

    assert(serializeJson(2.40f) == `2.4`);
    assert(serializeJson(float.nan) == `"nan"`);
    assert(serializeJson(float.infinity) == `"+inf"`);
    assert(serializeJson(-float.infinity) == `"-inf"`);
}

/// Boolean serialization
void serializeValue(S, V)(scope ref S serializer, scope const V value)
    if (is(V == bool) && !is(V == enum))
{
    serializer.putValue(value);
}

/// Char serialization
void serializeValue(S, V : char)(scope ref S serializer, scope const V value)
    if (is(V == char) && !is(V == enum))
{
    char[1] v = value;
    serializer.putValue(v[]);
}

///
version(mir_ion_test)
unittest
{
    import mir.ser.json: serializeJson;
    assert(serializeJson(true) == `true`);
}

/// Enum serialization
void serializeValue(S, V)(scope ref S serializer, scope const V value)
    if(is(V == enum))
{
    static if (hasUDA!(V, serdeProxy))
    {
        serializeProxyCastImpl!(S, V)(serializer, value);
    }
    else
    {
        serializer.putSymbol(serdeGetKeyOut(value));
    }
}

///
version(mir_ion_test)
unittest
{
    import mir.ser.json: serializeJson;
    import mir.ser.ion: serializeIon;
    import mir.ser.text: serializeText;
    import mir.deser.ion: deserializeIon;
    import mir.small_string;
    import mir.rc.array;
    enum Key { bar, @serdeKeys("FOO", "foo") foo }
    assert(serializeJson(Key.foo) == `"FOO"`);
    assert(serializeText(Key.foo) == `FOO`);
    assert(serializeIon(Key.foo).deserializeIon!Key == Key.foo);
    assert(serializeIon(Key.foo).deserializeIon!string == "FOO");
    assert(serializeIon(Key.foo).deserializeIon!(SmallString!32) == "FOO");
    auto rcstring = serializeIon(Key.foo).deserializeIon!(RCArray!char);
    assert(rcstring[] == "FOO");
}

private static void serializeProxyCastImpl(S, alias U, V)(scope ref S serializer, scope const V value)
{
    static if (hasUDA!(U, serdeProxyCast))
    {
        scope casted = cast(serdeGetProxy!U)value;
        serializeValue(serializer, casted);
    }
    else
        serializer.serializeWithProxy!(serdeGetProxy!U)(value);
}

/// String serialization
void serializeValue(S)(scope ref S serializer, scope const(char)[] value)
{
    if(value is null)
    {
        serializer.putNull(IonTypeCode.string);
        return;
    }
    serializer.putValue(value);
}

///
version(mir_ion_test)
unittest
{
    import mir.ser.json: serializeJson;
    assert(serializeJson("\t \" \\") == `"\t \" \\"`, serializeJson("\t \" \\"));
}

/// Array serialization
void serializeValue(S, T)(scope ref S serializer, scope const T[] value) @safe
    if(!isSomeChar!T)
{
    if (value is null)
    {
        serializer.putNull(IonTypeCode.list);
        return;
    }
    auto state = serializer.beginList(value);
    foreach (ref elem; value)
    {
        serializer.elemBegin;
        serializer.serializeValue(elem);
    }
    serializer.listEnd(state);
}

private enum isRefIterable(T) = __traits(compiles, (ref T value) { foreach (ref elem; value) {}  });

version(mir_ion_test)
unittest
{
    static assert(isRefIterable!(double[]));
}

package template hasLikeList(T)
{
    import mir.serde: serdeLikeList;
    static if (is(T == enum) || isAggregateType!T)
        enum hasLikeList = hasUDA!(T, serdeLikeList);
    else
        enum hasLikeList = false;
}

package template hasProxy(T)
{
    import mir.serde: serdeProxy;
    static if (is(T == enum) || isAggregateType!T)
        enum hasProxy = hasUDA!(T, serdeProxy);
    else
        enum hasProxy = false;
}

package template hasFields(T)
{
    import mir.serde: serdeFields;
    static if (is(T == enum) || isAggregateType!T)
        enum hasFields = hasUDA!(T, serdeFields);
    else
        enum hasFields = false;
}


/// input range serialization
version(mir_ion_test)
unittest
{
    import mir.algorithm.iteration : filter;

    static struct Foo
    {
        int i;
    }

    auto ar = [Foo(1), Foo(3), Foo(4), Foo(17)];

    auto filtered1 = ar.filter!"a.i & 1";
    auto filtered2 = ar.filter!"!(a.i & 1)";

    import mir.ser.json: serializeJson;
    assert(serializeJson(filtered1) == `[{"i":1},{"i":3},{"i":17}]`);
    assert(serializeJson(filtered2) == `[{"i":4}]`);
}

///
unittest
{
    import mir.ser.json: serializeJson;
    uint[2] ar = [1, 2];
    assert(serializeJson(ar) == `[1,2]`);
    assert(serializeJson(ar[]) == `[1,2]`);
    assert(serializeJson(ar[0 .. 0]) == `[]`);
    assert(serializeJson((uint[]).init) == `[]`);
}

/// String-value associative array serialization
void serializeValue(S, T)(scope ref S serializer, scope const T[string] value)
{
    if(value is null)
    {
        serializer.putNull(IonTypeCode.struct_);
        return;
    }
    auto state = serializer.beginStruct(value);
    foreach (key, ref const val; (()@trusted => cast()value)())
    {
        serializer.putKey(key);
        serializer.serializeValue(val);
    }
    serializer.structEnd(state);
}

///
version(mir_ion_test)
unittest
{
    import mir.ser.json: serializeJson;
    import mir.ser.text: serializeText;
    uint[string] ar = ["a" : 1];
    auto car = cast(const)ar;
    assert(serializeJson(car) == `{"a":1}`);
    assert(serializeText(ar) == `{a:1}`);
    ar.remove("a");
    assert(serializeJson(ar) == `{}`);
    assert(serializeJson((uint[string]).init) == `{}`);
}

/// Enumeration-value associative array serialization
void serializeValue(S, V : const T[K], T, K)(scope ref S serializer, scope const V value)
    if(is(K == enum))
{
    if(value is null)
    {
        serializer.putNull(IonTypeCode.struct_);
        return;
    }
    auto state = serializer.beginStruct(value);
    foreach (key, ref val; value)
    {
        serializer.putKey(serdeGetKeyOut(key));
        serializer.serializeValue(val);
    }
    serializer.structEnd(state);
}

///
version(mir_ion_test)
unittest
{
    import mir.ser.json: serializeJson;
    enum E { a, b }
    uint[E] ar = [E.a : 1];
    auto car = cast(const)ar;
    assert(serializeJson(car) == `{"a":1}`);
    ar.remove(E.a);
    assert(serializeJson(ar) == `{}`);
    assert(serializeJson((uint[string]).init) == `{}`);
}

/// integral typed value associative array serialization
void serializeValue(S,  V : const T[K], T, K)(scope ref S serializer, scope const V value)
    if (isIntegral!K && !is(K == enum))
{
    if(value is null)
    {
        serializer.putNull(IonTypeCode.struct_);
        return;
    }
    auto state = serializer.beginStruct(value);
    foreach (key, ref val; value)
    {
        import mir.format: print, stringBuf;
        import mir.small_string : SmallString;
        auto buffer = stringBuf;
        print(buffer, key);
        serializer.putKey(buffer.data);
        .serializeValue(serializer, val);
    }
    serializer.structEnd(state);
}

///
version(mir_ion_test)
unittest
{
    import mir.ser.json: serializeJson;
    uint[short] ar = [256 : 1];
    assert(serializeJson(ar) == `{"256":1}`);
    ar.remove(256);
    assert(serializeJson(ar) == `{}`);
    assert(serializeJson((uint[string]).init) == `{}`);
    // assert(deserializeJson!(uint[short])(`{"256":1}`) == cast(uint[short]) [256 : 1]);
}


private IonTypeCode nullTypeCodeOf(T)()
{
    import mir.algebraic: isVariant;
    import mir.serde: serdeGetFinalProxy;
    import std.traits: Unqual;

    IonTypeCode code;

    alias U = Unqual!T;

    static if (is(U == bool))
        code = IonTypeCode.bool_;
    else
    static if (isUnsigned!U)
        code = IonTypeCode.uInt;
    else
    static if (isIntegral!U || isBigInt!U)
        code = IonTypeCode.nInt;
    else
    static if (isFloatingPoint!U)
        code = IonTypeCode.float_;
    else
    static if (isDecimal!U)
        code = IonTypeCode.decimal;
    else
    static if (isTuple!U)
        code = IonTypeCode.list;
    else
    static if (isClob!U)
        code = IonTypeCode.clob;
    else
    static if (isBlob!U)
        code = IonTypeCode.blob;
    else
    static if (isSomeString!U)
        code = IonTypeCode.string;
    else
    static if (!isVariant!U && isAggregateType!U)
    {
        static if (hasUDA!(U, serdeProxy))
            code = .nullTypeCodeOf!(serdeGetFinalProxy!U);
        else
        static if (isIterable!U && !hasFields!U)
            code = IonTypeCode.list;
        else
            code = IonTypeCode.struct_;
    }
    else
    static if (isIterable!U && !hasFields!U)
        code = IonTypeCode.list;

    return code;
}

version(mir_ion_test)
unittest
{
    static assert(nullTypeCodeOf!long == IonTypeCode.nInt);
}

@safe
private void serializeAnnotatedValue(S, V)(scope ref S serializer, scope ref const V value, size_t wrapperState)
{
    import mir.algebraic: Algebraic;
    static if (serdeGetAnnotationMembersOut!V.length)
    {
        static foreach (annotationMember; serdeGetAnnotationMembersOut!V)
        {
            static if (is(typeof(__traits(getMember, value, annotationMember)) == enum))
                serializer.putAnnotation(serdeGetKeyOut(__traits(getMember, value, annotationMember)));
            else
            static if (__traits(compiles, serializer.putAnnotation(__traits(getMember, value, annotationMember)[])))
                serializer.putAnnotation(__traits(getMember, value, annotationMember)[]);
            else
                foreach (annotation; __traits(getMember, value, annotationMember))
                    serializer.putAnnotation(annotation);
        }
    }

    static if (isAlgebraicAliasThis!V || isAnnotated!V)
    {
        static if (__traits(getAliasThis, V).length == 1)
            enum aliasThisMember = __traits(getAliasThis, V)[0];
        else
            enum aliasThisMember = "value";
        return serializeAnnotatedValue(serializer, __traits(getMember, value, aliasThisMember), wrapperState);
    }
    else
    static if (is(V == Algebraic!TypeSet, TypeSet...) && (!isStdNullable!V || Algebraic!TypeSet.AllowedTypes.length != 2))
    {
        import mir.algebraic: match;
        match!(
            serializeVoidHandlerWithSerializerAndState,
            staticMap!(serializeAlgebraicAnnotationContinue!S, Filter!(serdeHasAlgebraicAnnotation, V.AllowedTypes)),
            serializeAnnotatedValue,
        )(serializer, value, wrapperState);
    }
    else
    {
        auto annotationsState = serializer.annotationsEnd(wrapperState);
        static if (serdeGetAnnotationMembersOut!V.length)
            serializeValueImpl(serializer, value);
        else
            serializeValue(serializer, value);
        serializer.annotationWrapperEnd(annotationsState, wrapperState);
    }
}

/// Struct and class type serialization
private void serializeValueImpl(S, V)(scope ref S serializer, scope ref const V value)
    if (isAggregateType!V && (!isIterable!V || hasFields!V || hasUDA!(V, serdeProxy) && !hasUDA!(V, serdeLikeList)))
{
    import mir.algebraic;
    auto state = serializer.structBegin;

    static if (hasUDA!(V, serdeDiscriminatedField))
    {{
        enum udas = getUDAs!(V, serdeDiscriminatedField);
        static assert (udas.length == 1);
        enum key = udas[0].field;

        static if (__traits(hasMember, S, "putCompiletimeKey"))
        {
            serializer.putCompiletimeKey!key;
        }
        else
        static if (__traits(hasMember, S, "putKeyPtr"))
        {
            serializer.putKeyPtr(key.ptr);
        }
        else
        {
            serializer.putKey(key);
        }

        serializer.putSymbol(udas[0].tag);
    }}

    foreach(member; aliasSeqOf!(SerializableMembers!V))
    {{
        enum key = serdeGetKeyOut!(__traits(getMember, value, member));

        static if (key !is null)
        {
            static if (hasUDA!(__traits(getMember, value, member), serdeIgnoreDefault))
            {
                if (__traits(getMember, value, member) == __traits(getMember, V.init, member))
                    continue;
            }

            static if(hasUDA!(__traits(getMember, value, member), serdeIgnoreOutIf))
            {
                alias pred = serdeGetIgnoreOutIf!(__traits(getMember, value, member));
                if (pred(__traits(getMember, value, member)))
                    continue;
            }

            static if(hasUDA!(__traits(getMember, value, member), serdeIgnoreIfAggregate))
            {
                alias pred = serdeGetIgnoreIfAggregate!(__traits(getMember, value, member));
                if (pred(value))
                    continue;
            }

            static if(hasUDA!(__traits(getMember, value, member), serdeIgnoreOutIfAggregate))
            {
                alias pred = serdeGetIgnoreOutIfAggregate!(__traits(getMember, value, member));
                if (pred(value))
                    continue;
            }

            static if(__traits(hasMember, typeof(__traits(getMember, value, member)), "serdeIgnoreOut"))
            {
                if (__traits(getMember, __traits(getMember, value, member), "serdeIgnoreOut"))
                    continue;
            }

            static if(__traits(hasMember, typeof(__traits(getMember, value, member)), "_void"))
            {
                if (__traits(getMember, value, member)._is!void)
                    continue;
            }

            static if(hasUDA!(__traits(getMember, value, member), serdeTransformOut))
            {
                alias f = serdeGetTransformOut!(__traits(getMember, value, member));
                auto val = f(__traits(getMember, value, member));
                alias W  = typeof(val);
            }
            else
            static if (hasField!(V, member))
            {
                scope valPtr = (()@trusted => &__traits(getMember, value, member))();
                alias W  = typeof(*valPtr);
                ref W val() @trusted pure @property { return *valPtr; }
            }
            else
            {
                auto val = __traits(getMember, value, member);
                alias W  = typeof(val);
            }

            static if (__traits(hasMember, S, "putCompiletimeKey"))
            {
                serializer.putCompiletimeKey!key;
            }
            else
            static if (__traits(hasMember, S, "putKeyPtr"))
            {
                serializer.putKeyPtr(key.ptr);
            }
            else
            {
                serializer.putKey(key);
            }

            static if(hasUDA!(__traits(getMember, value, member), serdeLikeList))
            {
                static assert(0);
            }
            else
            static if(hasUDA!(__traits(getMember, value, member), serdeLikeStruct))
            {
                static if(is(W == interface) || is(W == class) || is(W : E[T], E, T))
                {
                    if(val is null)
                    {
                        serializer.putNull(IonTypeCode.struct_);
                        continue F;
                    }
                }
                auto valState = serializer.beginStruct(val);
                static if (__traits(hasMember, val, "byKeyValue"))
                {
                    foreach (keyElem; val.byKeyValue)
                    {
                        serializer.putKey(keyElem.key);
                        serializer.serializeValue(keyElem.value);
                    }
                }
                else
                {
                    foreach (key, ref elem; val)
                    {
                        serializer.putKey(key);
                        serializer.serializeValue(elem);
                    }
                }
                serializer.structEnd(valState);
            }
            else
            static if(hasUDA!(__traits(getMember, value, member), serdeProxy))
            {
                serializeProxyCastImpl!(S, __traits(getMember, value, member))(serializer, val);
            }
            else
            {
                serializer.serializeValue(val);
            }
        }
    }}
    static if(__traits(hasMember, V, "finalizeSerialization"))
    {
        value.finalizeSerialization(serializer);
    }

    serializer.structEnd(state);
}

private template serializeWithProxy(Proxy)
{
    @safe
    void serializeWithProxy(S, V)(scope ref S serializer, scope ref const V value)
    {
        static if (is(Proxy == const(char)[]) || is(Proxy == string) || is(Proxy == char[]))
        {
            import mir.format: stringBuf, print, getData;
            static if (__traits(compiles, serializeValue(serializer, stringBuf() << value << getData)))
                serializeValue(serializer, stringBuf() << value << getData);
            else
            {
                serializeValue(serializer, to!Proxy(value));
            }
        }
        else
        {
            static if (isImplicitlyConvertible!(const V, const Proxy))
            {
                scope const Proxy proxy = value;
                serializeValue(serializer, proxy);
            }
            else
            {
                static if (is(typeof(()@safe{return to!(const Proxy)(value);})))
                    auto proxy = to!(const Proxy)(value);
                else
                {
                    pragma(msg, "Mir warning: can't safely cast from ", (const V).stringof, " to ", (const Proxy).stringof
                    );
                    auto proxy = ()@trusted{return to!(const Proxy)(value);}();
                }
                serializeValue(serializer, proxy);
            }
        }
    }
}

private template serializeAlgebraicAnnotation(S)
{
    @safe
    void serializeAlgebraicAnnotation(V)(scope ref S serializer, scope ref const V value)
        if (serdeHasAlgebraicAnnotation!V)
    {
        auto wrapperState = serializer.annotationWrapperBegin;
        alias continueThis = serializeAlgebraicAnnotationContinue!S;
        return continueThis(serializer, value, wrapperState);
    }
}

private template serializeAlgebraicAnnotationContinue(S)
{
    void serializeAlgebraicAnnotationContinue(V)(scope ref S serializer, scope ref const V value, size_t wrapperState)
        if (serdeHasAlgebraicAnnotation!V)
    {
        static if (__traits(hasMember, S, "putCompiletimeAnnotation"))
            serializer.putCompiletimeAnnotation!(serdeGetAlgebraicAnnotation!V);
        else
        static if (__traits(hasMember, S, "putAnnotationPtr"))
            serializer.putAnnotationPtr(serdeGetAlgebraicAnnotation!V.ptr);
        else
            serializer.putAnnotation(serdeGetAlgebraicAnnotation!V);
        serializeAnnotatedValue(serializer, value, wrapperState);
    }
}

/// Struct and class type serialization
void serializeValue(S, V)(scope ref S serializer, scope ref const V value) @safe
    if (isAggregateType!V)
{
    import mir.algebraic: Algebraic, isVariant, isNullable;
    import mir.string_map: isStringMap;
    import mir.timestamp: Timestamp;

    static if(is(V == class) || is(V == interface))
    {
        if(value is null)
        {
            serializer.putNull(nullTypeCodeOf!V);
            return;
        }
    }

    static if (isBigInt!V || isDecimal!V || isTimestamp!V || isBlob!V || isClob!V)
    {
        serializer.putValue(value);
        return;
    }
    else
    static if (isTuple!V)
    {
        auto state = serializer.listBegin(value.expand.length);
        foreach (ref v; value.expand)
        {
            serializer.elemBegin;
            .serializeValue(serializer, v);
        }
        serializer.listEnd(state);
    }
    else
    static if (isStringMap!V)
    {
        auto state = serializer.beginStruct(value);
        auto keys = value.keys;
        foreach (i, ref v; value.values)
        {
            serializer.putKey(keys[i]);
            .serializeValue(serializer, v);
        }
        serializer.structEnd(state);
    }
    else
    static if (serdeGetAnnotationMembersOut!V.length || isAnnotated!V)
    {
        auto wrapperState = serializer.annotationWrapperBegin;
        return serializeAnnotatedValue(serializer, value, wrapperState);
    }
    else
    static if ((isIterable!V || isRefIterable!V) &&
        (!hasProxy!V || hasLikeList!V) &&
        !hasFields!V &&
        !isStdNullable!V)
    {
        static if(is(V : E[], E) && !is(V : D[N], D, size_t N))
        {
            if (value is null)
            {
                serializer.putNull(nullTypeCodeOf!V);
                return;
            }
        }
        static if (isSomeChar!(ForeachType!V))
        {
            import mir.format: stringBuf;
            auto buf = stringBuf;
            static if (isIterable!(const V))
            {
                static if (is(typeof(()@safe{foreach (elem; value){}})))
                    foreach (elem; value) buf.put(elem);
                else () @trusted
                {
                    pragma(msg, "Mir warning: can't @safely iterate ", (const V).stringof);
                    foreach (elem; value) buf.put(elem);
                }();
            }
            else
            {
                pragma(msg, "Mir warning: removing const qualifier to iterate. Implement `auto opIndex() @safe scope const` for ", (V).stringof);
                static if (!is(typeof(()@safe{foreach (elem; (()@trusted => cast() value)()){}})))
                    pragma(msg, "Mir warning: can't @safely iterate ", (V).stringof);
                () @trusted
                {
                    foreach (elem; cast() value) buf.put(elem);
                }();
            }
            serializer.putValue(buf.data);
        }
        else
        {
            auto state = serializer.beginList(value);
            static if (isRefIterable!V)
            {
                static if (__traits(hasMember, V, "lightScope"))
                {
                    foreach (ref elem; value.lightScope)
                    {
                        serializer.elemBegin;
                        serializer.serializeValue(elem);
                    }
                }
                else
                static if (isRefIterable!(const V))
                {
                    static if (is(typeof(()@safe{foreach (ref elem; value){}})))
                    foreach (ref elem; value)
                    {
                        serializer.elemBegin;
                        serializer.serializeValue(elem);
                    }
                    else ()@trusted
                    {
                        pragma(msg, "Mir warning: can't @safely iterate ", (const V).stringof);
                    foreach (ref elem; value)
                    {
                        serializer.elemBegin;
                        serializer.serializeValue(elem);
                    }
                    } ();
                }
                else
                {
                    pragma(msg, "Mir warning: removing const qualifier to iterate. Implement `auto opIndex() @safe scope const` for ", (V).stringof);
                    foreach (ref elem; (()@trusted => cast() value)())
                    {
                        serializer.elemBegin;
                        serializer.serializeValue(elem);
                    }
                }
            }
            else
            {
                static if (__traits(hasMember, V, "lightScope"))
                {
                    foreach (elem; value.lightScope)
                    {
                        serializer.elemBegin;
                        serializer.serializeValue(elem);
                    }
                }
                else
                static if (isIterable!(const V))
                {
                    foreach (elem; value)
                    {
                        serializer.elemBegin;
                        serializer.serializeValue(elem);
                    }
                }
                else
                {
                    pragma(msg, "Mir warning: removing const qualifier to iterate. Implement `auto opIndex() @safe scope const` for ", (V).stringof);
                    static if (is(typeof(()@safe{foreach (elem; (()@trusted => cast() value)()){}})))
                    foreach (elem; (()@trusted => cast() value)())
                    {
                        serializer.elemBegin;
                        serializer.serializeValue(elem);
                    }
                    else ()@trusted
                    {
                        pragma(msg, "Mir warning: can't @safely iterate ", (V).stringof);
                    foreach (elem; cast() value)
                    {
                        serializer.elemBegin;
                        serializer.serializeValue(elem);
                    }
                    } ();
                }
            }
            serializer.listEnd(state);
        }
    }
    else
    static if(hasUDA!(V, serdeLikeList))
    {
        static assert(0);
    }
    else
    static if(hasUDA!(V, serdeLikeStruct))
    {
        static if (is(V : E[T], E, T))
        {
            if (value is null)
            {
                serializer.putNull(nullTypeCodeOf!V);
                continue F;
            }
        }
        auto valState = serializer.beginStruct(value);

        import mir.algebraic: isVariant, visit;
        static if (__traits(hasMember, value, "byKeyValue"))
        {
            static if (is(typeof(()@safe {foreach (keyElem; value.byKeyValue){}})))
            foreach (keyElem; value.byKeyValue)
            {
                static if (!isVariant!(typeof(keyElem.key)))
                    serializer.putKey(keyElem.key);
                else
                {
                    if (keyElem.key._is!string)
                        serializer.putKey(keyElem.key.trustedGet!string);
                    else
                    if (keyElem.key._is!long)
                        serializer.putKey(keyElem.key.trustedGet!long.to!string);
                    else
                    if (keyElem.key._is!double)
                        serializer.putKey(keyElem.key.trustedGet!double.to!string);
                    else
                    if (keyElem.key._is!Timestamp)
                        serializer.putKey(keyElem.key.trustedGet!Timestamp.to!string);
                }
                serializer.serializeValue(keyElem.value);
            }
            else
            {
                pragma(msg, "Mir warning: can't safely iterate ", typeof(value));
                () @trusted {
            foreach (keyElem; (cast() value).byKeyValue)
            {
                static if (!isVariant!(typeof(keyElem.key)))
                    serializer.putKey(keyElem.key);
                else
                {
                    if (keyElem.key._is!string)
                        serializer.putKey(keyElem.key.trustedGet!string);
                    else
                    if (keyElem.key._is!long)
                        serializer.putKey(keyElem.key.trustedGet!long.to!string);
                    else
                    if (keyElem.key._is!double)
                        serializer.putKey(keyElem.key.trustedGet!double.to!string);
                    else
                    if (keyElem.key._is!Timestamp)
                        serializer.putKey(keyElem.key.trustedGet!Timestamp.to!string);
                }
                serializer.serializeValue(keyElem.value);
            }
            }();}
        }
        else
        {
            foreach (key, ref elem; value)
            {
                static if (!isVariant!(typeof(key)))
                    serializer.putKey(key);
                else
                {
                    if (key._is!string)
                        serializer.putKey(key.trustedGet!string);
                    else
                    if (key._is!long)
                        serializer.putKey(key.trustedGet!long.to!string);
                    else
                    if (key._is!double)
                        serializer.putKey(key.trustedGet!double.to!string);
                    else
                    if (key._is!Timestamp)
                        serializer.putKey(key.trustedGet!Timestamp.to!string);
                }
                serializer.serializeValue(elem);
            }
        }
        serializer.structEnd(valState);
    }
    else
    static if (isAlgebraicAliasThis!V)
    {
        serializeValue(serializer, __traits(getMember, value, __traits(getAliasThis, V)));
    }
    else
    static if (is(V == Algebraic!TypeSet, TypeSet...) && (!isStdNullable!V || Algebraic!TypeSet.AllowedTypes.length != 2))
    {
        import mir.algebraic: match;
        match!(
            serializeVoidHandlerWithSerializer,
            staticMap!(serializeAlgebraicAnnotation!S, Filter!(serdeHasAlgebraicAnnotation, V.AllowedTypes)),
            serializeValue,
        )(serializer, value);
    }
    else
    static if(staticIndexOf!("serialize", __traits(allMembers, V)) >= 0)
    {
        alias soverloads = getSerializeOverloads!(S, V);
        static if (__traits(hasMember, soverloads, "best") || !__traits(hasMember, soverloads, "script"))
        {
            static if (__traits(compiles, value.serialize(serializer)) || !hasUDA!(V, serdeProxy))
                value.serialize(serializer);
            else
                serializeValue(serializer, to!(serdeGetProxy!V)(value));

        }
        else
        static if (__traits(hasMember, soverloads, "script"))
        {
            import mir.ser.interfaces: SerializerWrapper;
            scope wserializer = new SerializerWrapper!S(serializer);
            auto iserializer = wserializer.ISerializer;
            value.serialize(iserializer);
        }
        return;
    }
    else
    static if (hasUDA!(V, serdeProxy))
    {
        serializeProxyCastImpl!(S, V)(serializer, value);
        return;
    }
    else
    static if (isStdNullable!V || isNullable!V)
    {
        if(value.isNull)
        {
            serializer.putNull(nullTypeCodeOf!(typeof(V.init.get())));
            return;
        }
        return serializeValue(serializer, value.get);
    }
    else
    static if (is(typeof(Timestamp(V.init))))
    {
        serializer.putValue(Timestamp(value));
        return;
    }
    else
    {
        return serializeValueImpl(serializer, value);
    }
}

private template getSerializeOverloads(S, alias value)
{
    import mir.ser.interfaces: ISerializer;
    static foreach (i, so; __traits(getOverloads, value, "serialize"))
    {
        static if (!__traits(isTemplate, value.serialize))
        {
            static if (is(Parameters!so[0] == S))
            {
                enum best = i;
            }
            else
            {
                static if (is(Parameters!so[0] == ISerializer))
                {
                    enum script = i;
                }
            }
        }
    }
}

private struct UntrustDummy
{
    long[] a;
    double b;
    bool c;
    string[] d;
}

import std.traits: isFunctionPointer, isDelegate;

auto assumePure(T)(T t) @trusted
if (isFunctionPointer!T || isDelegate!T)
{
    pragma(inline, false);
    enum attrs = functionAttributes!T | FunctionAttribute.pure_ | FunctionAttribute.nogc | FunctionAttribute.nothrow_;
    return cast(SetFunctionAttributes!(T, functionLinkage!T, attrs)) t;
}


/// Mir types
version(mir_ion_test)
unittest
{
    import mir.bignum.integer;
    import mir.date;
    import mir.ser.json: serializeJson;
    import mir.ser.text: serializeText;
    assert(Date(2021, 4, 24).serializeJson == `"2021-04-24"`);
    assert(BigInt!2(123).serializeJson == `123`);
    assert(Date(2021, 4, 24).serializeText == `2021-04-24`);
    assert(BigInt!2(123).serializeText == `123`);
}

/// Alias this support
version(mir_ion_test)
unittest
{
    struct S
    {
        int u;
    }

    struct C
    {
        int b;
        S s;
        alias s this; 
    }

    import mir.ser.json: serializeJson;
    assert(C(4, S(3)).serializeJson == `{"u":3,"b":4}`);
}

/// Custom `serialize`
version(mir_ion_test)
unittest
{
    struct S
    {
        void serialize(S)(scope ref S serializer) scope const @safe
        {
            auto state = serializer.structBegin(1);
            serializer.putKey("foo");
            serializer.putValue("bar");
            serializer.structEnd(state);
        }
    }

    import mir.ser.json: serializeJson;
    assert(serializeJson(S()) == `{"foo":"bar"}`);
}

/// Nullable type serialization
version(mir_ion_test)
unittest
{
    import mir.ser.json: serializeJson;
    import mir.algebraic: Nullable;

    struct Nested
    {
        float f;
    }

    struct T
    {
        string str;
        Nullable!Nested nested;
    }

    T t;
    assert(t.serializeJson == `{"str":"","nested":{}}`);
    t.str = "txt";
    t.nested = Nested(123);
    assert(t.serializeJson == `{"str":"txt","nested":{"f":123.0}}`);
}

///
version(mir_ion_test)
unittest
{
    import mir.algebraic;
    import mir.small_string;

    @serdeAlgebraicAnnotation("$B")
    static struct B
    {
        double number;
    }

    @serdeAlgebraicAnnotation("$A")
    static struct A
    {
        @serdeAnnotation
        SmallString!32 id1;

        @serdeAnnotation
        string[] id2;

        B c;
        alias c this;

        string s;
    }


    static assert(serdeHasAlgebraicAnnotation!B);
    static assert(serdeGetAlgebraicAnnotation!B == "$B");
    static assert(serdeHasAlgebraicAnnotation!A);
    static assert(serdeGetAlgebraicAnnotation!A == "$A");

    @serdeAlgebraicAnnotation("$c")
    static struct C
    {
    }

    @serdeAlgebraicAnnotation("$E")
    enum E { e1, e2 }

    @serdeAlgebraicAnnotation("$S")
    static struct S
    {
        @serdeAnnotation
        string sid;

        @serdeAnnotation
        string sid2;

        alias Data = Nullable!(A, C, long, E);

        alias data this;

        Data data;
    }


    @serdeAlgebraicAnnotation("$Y")
    static struct Y
    {
        alias Data = Nullable!(A, C, long);

        alias data this;

        Data data;
    }


    import mir.ion.conv: ion2text;
    import mir.ser.ion: serializeIon;
    import mir.ser.text: serializeText;
    import mir.test;

    () {
        Nullable!S value = S("LIBOR", "S", S.Data(A("Rate".SmallString!32, ["USD", "GBP"])));
        static immutable text = `LIBOR::S::$A::Rate::USD::GBP::{number:nan,s:null.string}`;
        value.serializeText.should == text;
        auto binary = value.serializeIon;
        binary.ion2text.should == text;
        import mir.deser.ion: deserializeIon;
        binary.deserializeIon!S.serializeText.should == text;
    } ();

    () {
        S value = S("LIBOR", "S", S.Data(E.e2));
        static immutable text = `LIBOR::S::$E::e2`;
        value.serializeText.should == text;
        auto binary = value.serializeIon;
        binary.ion2text.should == text;
        import mir.deser.ion: deserializeIon;
        binary.deserializeIon!S.serializeText.should == text;
    } ();

    () {
        auto value = Y(Y.Data(A("Rate".SmallString!32, ["USD", "GBP"])));
        static immutable text = `$A::Rate::USD::GBP::{number:nan,s:null.string}`;
        auto binary = value.serializeIon;
        binary.ion2text.should == text;
        import mir.deser.ion: deserializeIon;
        binary.deserializeIon!Y.serializeText.should == text;
    } ();

    () {
        auto value = S("USD", "S", S.Data(3));
        static immutable text = `USD::S::3`;
        auto binary = value.serializeIon;
        binary.ion2text.should == text;
        import mir.deser.ion: deserializeIon;
        binary.deserializeIon!S.serializeText.should == text;
    } ();
}

/++
+/
auto beginList(S, V)(scope ref S serializer, scope ref V value)
{
    static if (__traits(compiles, serializer.listBegin))
    {
        return serializer.listBegin;
    }
    else
    {
        import mir.primitives: walkLength;
        return serializer.listBegin(value.walkLength);
    }
}

/++
+/
auto beginSexp(S, V)(scope ref S serializer, scope ref V value)
{
    static if (__traits(compiles, serializer.sexpBegin))
    {
        return serializer.sexpBegin;
    }
    else
    {
        import mir.primitives: walkLength;
        return serializer.sexpBegin(value.walkLength);
    }
}

/++
+/
auto beginStruct(S, V)(scope ref S serializer, scope ref V value)
{
    static if (__traits(compiles, serializer.structBegin))
    {
        return serializer.structBegin;
    }
    else
    {
        import mir.primitives: walkLength;
        return serializer.structBegin(value.walkLength);
    }
}

version (Have_mir_bloomberg)
{
    import mir.ser.bloomberg : BloombergElement;
    ///
    void serializeValue(S)(scope ref S serializer, scope const(BloombergElement)* value)
    {
        import mir.ser.bloomberg : impl = serializeValue;
        return impl(serializer, value);
    }
}
