/++
$(H4 High level JSON deserialization API)

Macros:
IONREF = $(REF_ALTTEXT $(TT $2), $2, mir, ion, $1)$(NBSP)
+/
module mir.deser.json;

public import mir.serde;

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
        import mir.exception: MirException;
        import mir.ion.exception: ionException, ionErrorMsg;

        mir_json2ion(text, (error, data)
        {
            if (error.code)
            {
                static if (__traits(compiles, ()@nogc { throw new Exception(""); }))
                {
                    throw new MirException(error.code.ionErrorMsg, ". location = ", error.location);
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
