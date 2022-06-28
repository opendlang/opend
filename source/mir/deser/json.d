/++
+/
module mir.deser.json;

public import mir.serde;
import mir.algebraic: Algebraic;
import mir.deser.low_level: hasDiscriminatedField;
import mir.string_map: isStringMap;
import std.traits: hasUDA, isAggregateType;

version(LDC) import ldc.attributes: optStrategy;
else private struct optStrategy { string opt; }

/++
Deserialize json string to a type trying to do perform less memort allocations.
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

    // @optStrategy("optsize")
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
