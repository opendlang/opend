/++
$(H4 High level JSON deserialization API)

Macros:
IONREF = $(REF_ALTTEXT $(TT $2), $2, mir, ion, $1)$(NBSP)
+/
module mir.deser.json;

public import mir.serde;

private enum dip1000 = __traits(compiles, ()@nogc { throw new Exception(""); });

/++
Deserialize JSON string to a type trying to do perform less memort allocations.
+/
template deserializeJson(T)
{
    T deserializeJson()(scope const(char)[] text)
    {
        version (LDC) pragma(inline, true);
        T value;
        deserializeJson(value, text);
        return value;
    }

    void deserializeJson(scope ref T value, scope const(char)[] text)
    {
        version (LDC) pragma(inline, true);
        import mir.ion.internal.stage3;
        import mir.deser.ion: deserializeIon;
        import mir.ion.exception: ionException, ionErrorMsg, IonParserMirException;

        mir_json2ion(text, (error, data)
        {
            enum nogc = __traits(compiles, (scope ref T value, const(ubyte)[] data)@nogc { deserializeIon!T(value, data); });
            if (error.code)
            {
                static if (!nogc || dip1000)
                {
                    throw new IonParserMirException(error.code.ionErrorMsg, error.location);
                }
                else
                {
                    throw error.code.ionException;
                }
            }
            deserializeIon!T(value, data);
        });
    }
}

deprecated ("Use deserializeJson instead")
alias deserializeDynamicJson = deserializeJson;
