module meson_test;

import mir.deser.json;
import mir.rc.array;
import mir.serde;
import mir.small_string;

struct S
{
    SmallString!32 id;
    RCArray!(immutable char) data;
}

struct C
{
    double a, b;
}

@safe pure @nogc:

export S deserializeS(scope const(char)[] json)
{
    return json.deserializeJson!S;
}

export extern(C) double deserializeC(scope const(char)* json, size_t len) @trusted
{
    with(json[0 .. len].deserializeJson!C) return a + b;
}
