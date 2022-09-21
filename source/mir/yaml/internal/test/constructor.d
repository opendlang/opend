
//          Copyright Ferdinand Majerech 2011.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)

module mir.internal.yaml.test.constructor;


version(unittest)
{

import mir.timestamp;
import mir.conv;
import std.exception;
import std.path;
import std.string: representation;

import mir.algebraic_alias.yaml;
import mir.internal.yaml : Loader;
import mir.internal.yaml.representer: withTag;

///Expected results of loading test inputs.
YamlAlgebraic[][string] expected;

///Initialize expected.
shared static this() @safe
{
    expected["aliases-cdumper-bug"] = constructAliasesCDumperBug();
    expected["construct-binary"] = constructBinary();
    expected["construct-bool"] = constructBool();
    expected["construct-custom"] = constructCustom();
    expected["construct-float"] = constructFloat();
    expected["construct-int"] = constructInt();
    expected["construct-map"] = constructMap();
    expected["construct-merge"] = constructMerge();
    expected["construct-null"] = constructNull();
    expected["construct-omap"] = constructOMap();
    expected["construct-pairs"] = constructPairs();
    expected["construct-seq"] = constructSeq();
    expected["construct-set"] = constructSet();
    expected["construct-str-ascii"] = constructStrASCII();
    expected["construct-str"] = constructStr();
    expected["construct-str-utf8"] = constructStrUTF8();
    expected["construct-timestamp"] = constructTimestamp();
    expected["construct-value"] = constructValue();
    expected["duplicate-merge-key"] = duplicateMergeKey();
    expected["float-representer-2.3-bug"] = floatRepresenterBug();
    expected["invalid-single-quote-bug"] = noneSingleQuoteBug();
    expected["more-floats"] = moreFloats();
    expected["negative-float-bug"] = negativeFloatBug();
    expected["single-dot-is-not-float-bug"] = singleDotFloatBug();
    expected["timestamp-bugs"] = timestampBugs();
    expected["utf16be"] = utf16be();
    expected["utf16le"] = utf16le();
    expected["utf8"] = utf8();
    expected["utf8-implicit"] = utf8implicit();
}

///Test cases:

YamlAlgebraic[] constructAliasesCDumperBug() @safe
{
    return [
        YamlAlgebraic(
            [
                YamlAlgebraic("today").withTag("tag:yaml.org,2002:str"),
                YamlAlgebraic("today").withTag("tag:yaml.org,2002:str")
            ].dup).withTag("tag:yaml.org,2002:seq")
    ];
}

YamlAlgebraic[] constructBinary() @safe
{
    auto canonical = "GIF89a\x0c\x00\x0c\x00\x84\x00\x00\xff\xff\xf7\xf5\xf5\xee\xe9\xe9\xe5fff\x00\x00\x00\xe7\xe7\xe7^^^\xf3\xf3\xed\x8e\x8e\x8e\xe0\xe0\xe0\x9f\x9f\x9f\x93\x93\x93\xa7\xa7\xa7\x9e\x9e\x9eiiiccc\xa3\xa3\xa3\x84\x84\x84\xff\xfe\xf9\xff\xfe\xf9\xff\xfe\xf9\xff\xfe\xf9\xff\xfe\xf9\xff\xfe\xf9\xff\xfe\xf9\xff\xfe\xf9\xff\xfe\xf9\xff\xfe\xf9\xff\xfe\xf9\xff\xfe\xf9\xff\xfe\xf9\xff\xfe\xf9!\xfe\x0eMade with GIMP\x00,\x00\x00\x00\x00\x0c\x00\x0c\x00\x00\x05,  \x8e\x810\x9e\xe3@\x14\xe8i\x10\xc4\xd1\x8a\x08\x1c\xcf\x80M$z\xef\xff0\x85p\xb8\xb01f\r\x1b\xce\x01\xc3\x01\x1e\x10' \x82\n\x01\x00;".representation.dup;
    auto generic = "GIF89a\x0c\x00\x0c\x00\x84\x00\x00\xff\xff\xf7\xf5\xf5\xee\xe9\xe9\xe5fff\x00\x00\x00\xe7\xe7\xe7^^^\xf3\xf3\xed\x8e\x8e\x8e\xe0\xe0\xe0\x9f\x9f\x9f\x93\x93\x93\xa7\xa7\xa7\x9e\x9e\x9eiiiccc\xa3\xa3\xa3\x84\x84\x84\xff\xfe\xf9\xff\xfe\xf9\xff\xfe\xf9\xff\xfe\xf9\xff\xfe\xf9\xff\xfe\xf9\xff\xfe\xf9\xff\xfe\xf9\xff\xfe\xf9\xff\xfe\xf9\xff\xfe\xf9\xff\xfe\xf9\xff\xfe\xf9\xff\xfe\xf9!\xfe\x0eMade with GIMP\x00,\x00\x00\x00\x00\x0c\x00\x0c\x00\x00\x05,  \x8e\x810\x9e\xe3@\x14\xe8i\x10\xc4\xd1\x8a\x08\x1c\xcf\x80M$z\xef\xff0\x85p\xb8\xb01f\r\x1b\xce\x01\xc3\x01\x1e\x10' \x82\n\x01\x00;".representation.dup;
    auto description = "The binary value above is a tiny arrow encoded as a gif image.";

    return [
        YamlAlgebraic(
            [
                YamlPair(
                    YamlAlgebraic("canonical").withTag("tag:yaml.org,2002:str"),
                    YamlAlgebraic(canonical).withTag("tag:yaml.org,2002:binary")
                ),
                YamlPair(
                    YamlAlgebraic("generic").withTag("tag:yaml.org,2002:str"),
                    YamlAlgebraic(generic).withTag("tag:yaml.org,2002:binary")
                ),
                YamlPair(
                    YamlAlgebraic("description").withTag("tag:yaml.org,2002:str"),
                    YamlAlgebraic(description).withTag("tag:yaml.org,2002:str")
                )
            ].dup).withTag("tag:yaml.org,2002:map")
    ];
}

YamlAlgebraic[] constructBool() @safe
{
    const(bool) a = true;
    immutable(bool) b = true;
    const bool aa = true;
    immutable bool bb = true;
    return [
        YamlAlgebraic(
            [
                YamlPair(
                    YamlAlgebraic("canonical").withTag("tag:yaml.org,2002:str"),
                    YamlAlgebraic(true).withTag("tag:yaml.org,2002:bool")
                ),
                YamlPair(
                    YamlAlgebraic("answer").withTag("tag:yaml.org,2002:str"),
                    YamlAlgebraic(false).withTag("tag:yaml.org,2002:bool")
                ),
                YamlPair(
                    YamlAlgebraic("logical").withTag("tag:yaml.org,2002:str"),
                    YamlAlgebraic(true).withTag("tag:yaml.org,2002:bool")
                ),
                YamlPair(
                    YamlAlgebraic("option").withTag("tag:yaml.org,2002:str"),
                    YamlAlgebraic(true).withTag("tag:yaml.org,2002:bool")
                ),
                YamlPair(
                    YamlAlgebraic("constbool").withTag("tag:yaml.org,2002:str"),
                    YamlAlgebraic(a).withTag("tag:yaml.org,2002:bool")
                ),
                YamlPair(
                    YamlAlgebraic("imutbool").withTag("tag:yaml.org,2002:str"),
                    YamlAlgebraic(b).withTag("tag:yaml.org,2002:bool")
                ),
                YamlPair(
                    YamlAlgebraic("const_bool").withTag("tag:yaml.org,2002:str"),
                    YamlAlgebraic(aa).withTag("tag:yaml.org,2002:bool")
                ),
                YamlPair(
                    YamlAlgebraic("imut_bool").withTag("tag:yaml.org,2002:str"),
                    YamlAlgebraic(bb).withTag("tag:yaml.org,2002:bool")
                ),
                YamlPair(
                    YamlAlgebraic("but").withTag("tag:yaml.org,2002:str"),
                    YamlAlgebraic(
                            [
                            YamlPair(
                                YamlAlgebraic("y").withTag("tag:yaml.org,2002:str"),
                                YamlAlgebraic("is a string").withTag("tag:yaml.org,2002:str")
                            ),
                            YamlPair(
                                YamlAlgebraic("n").withTag("tag:yaml.org,2002:str"),
                                YamlAlgebraic("is a string").withTag("tag:yaml.org,2002:str")
                            )
                        ].dup).withTag("tag:yaml.org,2002:map")
                )
            ].dup).withTag("tag:yaml.org,2002:map")
    ];
}

YamlAlgebraic[] constructCustom() @safe
{
    return [
        YamlAlgebraic(
            [
                Annotated!YamlAlgebraic(["!tag1"], ([
                    YamlPair(
                        YamlAlgebraic("x").withTag("tag:yaml.org,2002:str"),
                        YamlAlgebraic(1).withTag("tag:yaml.org,2002:int")
                    ),
                    YamlPair(
                        YamlAlgebraic("y").withTag("tag:yaml.org,2002:str"),
                        YamlAlgebraic(2).withTag("tag:yaml.org,2002:int")
                    ),
                    YamlPair(
                        YamlAlgebraic("z").withTag("tag:yaml.org,2002:str"),
                        YamlAlgebraic(3).withTag("tag:yaml.org,2002:int")
                    )
                ].dup.YamlAlgebraic).withTag("!tag1")).YamlAlgebraic,
                Annotated!YamlAlgebraic(["!tag2"], YamlAlgebraic("10").withTag("!tag2")).YamlAlgebraic
            ].dup).withTag("tag:yaml.org,2002:seq")
    ];
}

YamlAlgebraic[] constructFloat() @safe
{
    return [
        YamlAlgebraic(
            [
                YamlPair(
                    YamlAlgebraic("canonical").withTag("tag:yaml.org,2002:str"),
                    YamlAlgebraic(685230.15L).withTag("tag:yaml.org,2002:float")
                ),
                YamlPair(
                    YamlAlgebraic("exponential").withTag("tag:yaml.org,2002:str"),
                    YamlAlgebraic(685230.15L).withTag("tag:yaml.org,2002:float")
                ),
                YamlPair(
                    YamlAlgebraic("fixed").withTag("tag:yaml.org,2002:str"),
                    YamlAlgebraic(685230.15L).withTag("tag:yaml.org,2002:float")
                ),
                YamlPair(
                    YamlAlgebraic("sexagesimal").withTag("tag:yaml.org,2002:str"),
                    YamlAlgebraic(685230.15L).withTag("tag:yaml.org,2002:float")
                ),
                YamlPair(
                    YamlAlgebraic("negative infinity").withTag("tag:yaml.org,2002:str"),
                    YamlAlgebraic(-double.infinity).withTag("tag:yaml.org,2002:float")
                ),
                YamlPair(
                    YamlAlgebraic("not a number").withTag("tag:yaml.org,2002:str"),
                    YamlAlgebraic(double.nan).withTag("tag:yaml.org,2002:float")
                )
            ].dup).withTag("tag:yaml.org,2002:map")
    ];
}

YamlAlgebraic[] constructInt() @safe
{
    return [
        YamlAlgebraic(
            [
                YamlPair(
                    YamlAlgebraic("canonical").withTag("tag:yaml.org,2002:str"),
                    YamlAlgebraic(685230L).withTag("tag:yaml.org,2002:int")
                ),
                YamlPair(
                    YamlAlgebraic("decimal").withTag("tag:yaml.org,2002:str"),
                    YamlAlgebraic(685230L).withTag("tag:yaml.org,2002:int")
                ),
                YamlPair(
                    YamlAlgebraic("octal").withTag("tag:yaml.org,2002:str"),
                    YamlAlgebraic(685230L).withTag("tag:yaml.org,2002:int")
                ),
                YamlPair(
                    YamlAlgebraic("hexadecimal").withTag("tag:yaml.org,2002:str"),
                    YamlAlgebraic(685230L).withTag("tag:yaml.org,2002:int")
                ),
                YamlPair(
                    YamlAlgebraic("binary").withTag("tag:yaml.org,2002:str"),
                    YamlAlgebraic(685230L).withTag("tag:yaml.org,2002:int")
                ),
                YamlPair(
                    YamlAlgebraic("sexagesimal").withTag("tag:yaml.org,2002:str"),
                    YamlAlgebraic(685230L).withTag("tag:yaml.org,2002:int")
                )
            ].dup).withTag("tag:yaml.org,2002:map")
    ];
}

YamlAlgebraic[] constructMap() @safe
{
    return [
        YamlAlgebraic(
            [
                YamlPair(
                    YamlAlgebraic("Block style").withTag("tag:yaml.org,2002:str"),
                    YamlAlgebraic(
                        [
                            YamlPair(
                                YamlAlgebraic("Clark").withTag("tag:yaml.org,2002:str"),
                                YamlAlgebraic("Evans").withTag("tag:yaml.org,2002:str")
                            ),
                            YamlPair(
                                YamlAlgebraic("Brian").withTag("tag:yaml.org,2002:str"),
                                YamlAlgebraic("Ingerson").withTag("tag:yaml.org,2002:str")
                            ),
                            YamlPair(
                                YamlAlgebraic("Oren").withTag("tag:yaml.org,2002:str"),
                                YamlAlgebraic("Ben-Kiki").withTag("tag:yaml.org,2002:str")
                            )
                        ].dup).withTag("tag:yaml.org,2002:map")
                ),
                YamlPair(
                    YamlAlgebraic("Flow style").withTag("tag:yaml.org,2002:str"),
                    YamlAlgebraic(
                        [
                            YamlPair(
                                YamlAlgebraic("Clark").withTag("tag:yaml.org,2002:str"),
                                YamlAlgebraic("Evans").withTag("tag:yaml.org,2002:str")
                            ),
                            YamlPair(
                                YamlAlgebraic("Brian").withTag("tag:yaml.org,2002:str"),
                                YamlAlgebraic("Ingerson").withTag("tag:yaml.org,2002:str")
                            ),
                            YamlPair(
                                YamlAlgebraic("Oren").withTag("tag:yaml.org,2002:str"),
                                YamlAlgebraic("Ben-Kiki").withTag("tag:yaml.org,2002:str")
                            )
                        ].dup).withTag("tag:yaml.org,2002:map")
                )
            ].dup).withTag("tag:yaml.org,2002:map")
    ];
}

YamlAlgebraic[] constructMerge() @safe
{
    return [
        YamlAlgebraic(
            [
                YamlAlgebraic(
                    [
                        YamlPair(
                            YamlAlgebraic("x").withTag("tag:yaml.org,2002:str"),
                            YamlAlgebraic(1L).withTag("tag:yaml.org,2002:int")
                        ),
                        YamlPair(
                            YamlAlgebraic("y").withTag("tag:yaml.org,2002:str"),
                            YamlAlgebraic(2L).withTag("tag:yaml.org,2002:int")
                        )
                    ].dup).withTag("tag:yaml.org,2002:map"),
                YamlAlgebraic(
                    [
                        YamlPair(
                            YamlAlgebraic("x").withTag("tag:yaml.org,2002:str"),
                            YamlAlgebraic(0L).withTag("tag:yaml.org,2002:int")
                        ),
                        YamlPair(
                            YamlAlgebraic("y").withTag("tag:yaml.org,2002:str"),
                            YamlAlgebraic(2L).withTag("tag:yaml.org,2002:int")
                        )
                    ].dup).withTag("tag:yaml.org,2002:map"),
                YamlAlgebraic(
                    [
                        YamlPair(
                            YamlAlgebraic("r").withTag("tag:yaml.org,2002:str"),
                            YamlAlgebraic(10L).withTag("tag:yaml.org,2002:int")
                        )
                    ].dup).withTag("tag:yaml.org,2002:map"),
                YamlAlgebraic(
                    [
                        YamlPair(
                            YamlAlgebraic("r").withTag("tag:yaml.org,2002:str"),
                            YamlAlgebraic(1L).withTag("tag:yaml.org,2002:int")
                        )
                    ].dup).withTag("tag:yaml.org,2002:map"),
                YamlAlgebraic(
                    [
                        YamlPair(
                            YamlAlgebraic("x").withTag("tag:yaml.org,2002:str"),
                            YamlAlgebraic(1L).withTag("tag:yaml.org,2002:int")
                        ),
                        YamlPair(
                            YamlAlgebraic("y").withTag("tag:yaml.org,2002:str"),
                            YamlAlgebraic(2L).withTag("tag:yaml.org,2002:int")
                        ),
                        YamlPair(
                            YamlAlgebraic("r").withTag("tag:yaml.org,2002:str"),
                            YamlAlgebraic(10L).withTag("tag:yaml.org,2002:int")
                        ),
                        YamlPair(
                            YamlAlgebraic("label").withTag("tag:yaml.org,2002:str"),
                            YamlAlgebraic("center/big").withTag("tag:yaml.org,2002:str")
                        )
                    ].dup).withTag("tag:yaml.org,2002:map"),
                YamlAlgebraic(
                    [
                        YamlPair(
                            YamlAlgebraic("r").withTag("tag:yaml.org,2002:str"),
                            YamlAlgebraic(10L).withTag("tag:yaml.org,2002:int")
                        ),
                        YamlPair(
                            YamlAlgebraic("label").withTag("tag:yaml.org,2002:str"),
                            YamlAlgebraic("center/big").withTag("tag:yaml.org,2002:str")
                        ),
                        YamlPair(
                            YamlAlgebraic("x").withTag("tag:yaml.org,2002:str"),
                            YamlAlgebraic(1L).withTag("tag:yaml.org,2002:int")
                        ),
                        YamlPair(
                            YamlAlgebraic("y").withTag("tag:yaml.org,2002:str"),
                            YamlAlgebraic(2L).withTag("tag:yaml.org,2002:int")
                        )
                    ].dup).withTag("tag:yaml.org,2002:map"),
                YamlAlgebraic(
                    [
                        YamlPair(
                            YamlAlgebraic("label").withTag("tag:yaml.org,2002:str"),
                            YamlAlgebraic("center/big").withTag("tag:yaml.org,2002:str")
                        ),
                        YamlPair(
                            YamlAlgebraic("x").withTag("tag:yaml.org,2002:str"),
                            YamlAlgebraic(1L).withTag("tag:yaml.org,2002:int")
                        ),
                        YamlPair(
                            YamlAlgebraic("y").withTag("tag:yaml.org,2002:str"),
                            YamlAlgebraic(2L).withTag("tag:yaml.org,2002:int")
                        ),
                        YamlPair(
                            YamlAlgebraic("r").withTag("tag:yaml.org,2002:str"),
                            YamlAlgebraic(10L).withTag("tag:yaml.org,2002:int")
                        )
                    ].dup).withTag("tag:yaml.org,2002:map"),
                YamlAlgebraic(
                    [
                        YamlPair(
                            YamlAlgebraic("x").withTag("tag:yaml.org,2002:str"),
                            YamlAlgebraic(1L).withTag("tag:yaml.org,2002:int")
                        ),
                        YamlPair(
                            YamlAlgebraic("label").withTag("tag:yaml.org,2002:str"),
                            YamlAlgebraic("center/big").withTag("tag:yaml.org,2002:str")
                        ),
                        YamlPair(
                            YamlAlgebraic("r").withTag("tag:yaml.org,2002:str"),
                            YamlAlgebraic(10L).withTag("tag:yaml.org,2002:int")
                        ),
                        YamlPair(
                            YamlAlgebraic("y").withTag("tag:yaml.org,2002:str"),
                            YamlAlgebraic(2L).withTag("tag:yaml.org,2002:int")
                        )
                    ].dup).withTag("tag:yaml.org,2002:map")
            ].dup).withTag("tag:yaml.org,2002:seq")
    ];
}

YamlAlgebraic[] constructNull() @safe
{
    return [
        YamlAlgebraic(null).withTag("tag:yaml.org,2002:null"),
        YamlAlgebraic(
            [
                YamlPair(
                    YamlAlgebraic("empty").withTag("tag:yaml.org,2002:str"),
                    YamlAlgebraic(null).withTag("tag:yaml.org,2002:null")
                ),
                YamlPair(
                    YamlAlgebraic("canonical").withTag("tag:yaml.org,2002:str"),
                    YamlAlgebraic(null).withTag("tag:yaml.org,2002:null")
                ),
                YamlPair(
                    YamlAlgebraic("english").withTag("tag:yaml.org,2002:str"),
                    YamlAlgebraic(null).withTag("tag:yaml.org,2002:null")
                ),
                YamlPair(
                    YamlAlgebraic(null).withTag("tag:yaml.org,2002:null"),
                    YamlAlgebraic("null key").withTag("tag:yaml.org,2002:str")
                )
            ].dup).withTag("tag:yaml.org,2002:map"),
        YamlAlgebraic(
            [
                YamlPair(
                    YamlAlgebraic("sparse").withTag("tag:yaml.org,2002:str"),
                    YamlAlgebraic(
                        [
                            YamlAlgebraic(null).withTag("tag:yaml.org,2002:null"),
                            YamlAlgebraic("2nd entry").withTag("tag:yaml.org,2002:str"),
                            YamlAlgebraic(null).withTag("tag:yaml.org,2002:null"),
                            YamlAlgebraic("4th entry").withTag("tag:yaml.org,2002:str"),
                            YamlAlgebraic(null).withTag("tag:yaml.org,2002:null")
                        ].dup).withTag("tag:yaml.org,2002:seq")
                )
            ].dup).withTag("tag:yaml.org,2002:map")
    ];
}

YamlAlgebraic[] constructOMap() @safe
{
    return [
        YamlAlgebraic(
            [
                YamlPair(
                    YamlAlgebraic("Bestiary").withTag("tag:yaml.org,2002:str"),
                    YamlAlgebraic(
                        [
                            YamlPair(
                                YamlAlgebraic("aardvark").withTag("tag:yaml.org,2002:str"),
                                YamlAlgebraic("African pig-like ant eater. Ugly.").withTag("tag:yaml.org,2002:str")
                            ),
                            YamlPair(
                                YamlAlgebraic("anteater").withTag("tag:yaml.org,2002:str"),
                                YamlAlgebraic("South-American ant eater. Two species.").withTag("tag:yaml.org,2002:str")
                            ),
                            YamlPair(
                                YamlAlgebraic("anaconda").withTag("tag:yaml.org,2002:str"),
                                YamlAlgebraic("South-American constrictor snake. Scaly.").withTag("tag:yaml.org,2002:str")
                            )
                        ].dup).withTag("tag:yaml.org,2002:omap")
                ),
                YamlPair(
                    YamlAlgebraic("Numbers").withTag("tag:yaml.org,2002:str"),
                    YamlAlgebraic(
                        [
                            YamlPair(
                                YamlAlgebraic("one").withTag("tag:yaml.org,2002:str"),
                                YamlAlgebraic(1L).withTag("tag:yaml.org,2002:int")
                            ),
                            YamlPair(
                                YamlAlgebraic("two").withTag("tag:yaml.org,2002:str"),
                                YamlAlgebraic(2L).withTag("tag:yaml.org,2002:int")
                            ),
                            YamlPair(
                                YamlAlgebraic("three").withTag("tag:yaml.org,2002:str"),
                                YamlAlgebraic(3L).withTag("tag:yaml.org,2002:int")
                            )
                        ].dup).withTag("tag:yaml.org,2002:omap")
                )
            ].dup).withTag("tag:yaml.org,2002:map")
    ];
}

YamlAlgebraic[] constructPairs() @safe
{
    return [
        YamlAlgebraic(
            [
                YamlPair(
                    YamlAlgebraic("Block tasks").withTag("tag:yaml.org,2002:str"),
                    YamlAlgebraic(
                        [
                            YamlPair(YamlAlgebraic("meeting").withTag("tag:yaml.org,2002:str"), YamlAlgebraic("with team.").withTag("tag:yaml.org,2002:str")),
                            YamlPair(YamlAlgebraic("meeting").withTag("tag:yaml.org,2002:str"), YamlAlgebraic("with boss.").withTag("tag:yaml.org,2002:str")),
                            YamlPair(YamlAlgebraic("break").withTag("tag:yaml.org,2002:str"), YamlAlgebraic("lunch.").withTag("tag:yaml.org,2002:str")),
                            YamlPair(YamlAlgebraic("meeting").withTag("tag:yaml.org,2002:str"), YamlAlgebraic("with client.").withTag("tag:yaml.org,2002:str"))
                        ].dup).withTag("tag:yaml.org,2002:pairs")
                ),
                YamlPair(
                    YamlAlgebraic("Flow tasks").withTag("tag:yaml.org,2002:str"),
                    YamlAlgebraic(
                        [
                            YamlPair(YamlAlgebraic("meeting").withTag("tag:yaml.org,2002:str"), YamlAlgebraic("with team").withTag("tag:yaml.org,2002:str")),
                            YamlPair(YamlAlgebraic("meeting").withTag("tag:yaml.org,2002:str"), YamlAlgebraic("with boss").withTag("tag:yaml.org,2002:str"))
                        ].dup).withTag("tag:yaml.org,2002:pairs")
                )
            ].dup).withTag("tag:yaml.org,2002:map")
    ];
}

YamlAlgebraic[] constructSeq() @safe
{
    return [
        YamlAlgebraic(
            [
                YamlPair(
                    YamlAlgebraic("Block style").withTag("tag:yaml.org,2002:str"),
                    YamlAlgebraic([
                          YamlAlgebraic("Mercury").withTag("tag:yaml.org,2002:str"),
                          YamlAlgebraic("Venus").withTag("tag:yaml.org,2002:str"),
                          YamlAlgebraic("Earth").withTag("tag:yaml.org,2002:str"),
                          YamlAlgebraic("Mars").withTag("tag:yaml.org,2002:str"),
                          YamlAlgebraic("Jupiter").withTag("tag:yaml.org,2002:str"),
                          YamlAlgebraic("Saturn").withTag("tag:yaml.org,2002:str"),
                          YamlAlgebraic("Uranus").withTag("tag:yaml.org,2002:str"),
                          YamlAlgebraic("Neptune").withTag("tag:yaml.org,2002:str"),
                          YamlAlgebraic("Pluto").withTag("tag:yaml.org,2002:str")
                    ].dup).withTag("tag:yaml.org,2002:seq")
                ),
                YamlPair(
                    YamlAlgebraic("Flow style").withTag("tag:yaml.org,2002:str"),
                    YamlAlgebraic([
                        YamlAlgebraic("Mercury").withTag("tag:yaml.org,2002:str"),
                        YamlAlgebraic("Venus").withTag("tag:yaml.org,2002:str"),
                        YamlAlgebraic("Earth").withTag("tag:yaml.org,2002:str"),
                        YamlAlgebraic("Mars").withTag("tag:yaml.org,2002:str"),
                        YamlAlgebraic("Jupiter").withTag("tag:yaml.org,2002:str"),
                        YamlAlgebraic("Saturn").withTag("tag:yaml.org,2002:str"),
                        YamlAlgebraic("Uranus").withTag("tag:yaml.org,2002:str"),
                        YamlAlgebraic("Neptune").withTag("tag:yaml.org,2002:str"),
                        YamlAlgebraic("Pluto").withTag("tag:yaml.org,2002:str")
                    ].dup).withTag("tag:yaml.org,2002:seq")
                )
            ].dup).withTag("tag:yaml.org,2002:map")
    ];
}

YamlAlgebraic[] constructSet() @safe
{
    return [
        YamlAlgebraic(
            [
                YamlPair(
                    YamlAlgebraic("baseball players").withTag("tag:yaml.org,2002:str"),
                    YamlAlgebraic(
                        [
                            YamlAlgebraic("Mark McGwire").withTag("tag:yaml.org,2002:str"),
                            YamlAlgebraic("Sammy Sosa").withTag("tag:yaml.org,2002:str"),
                            YamlAlgebraic("Ken Griffey").withTag("tag:yaml.org,2002:str")
                        ].dup).withTag("tag:yaml.org,2002:set")
                ),
                YamlPair(
                    YamlAlgebraic("baseball teams").withTag("tag:yaml.org,2002:str"),
                    YamlAlgebraic(
                            [
                            YamlAlgebraic("Boston Red Sox").withTag("tag:yaml.org,2002:str"),
                            YamlAlgebraic("Detroit Tigers").withTag("tag:yaml.org,2002:str"),
                            YamlAlgebraic("New York Yankees").withTag("tag:yaml.org,2002:str")
                        ].dup).withTag("tag:yaml.org,2002:set")
                )
            ].dup).withTag("tag:yaml.org,2002:map")
    ];
}

YamlAlgebraic[] constructStrASCII() @safe
{
    return [
        YamlAlgebraic("ascii string").withTag("tag:yaml.org,2002:str")
    ];
}

YamlAlgebraic[] constructStr() @safe
{
    return [
        YamlAlgebraic(
            [
                YamlPair(
                    YamlAlgebraic("string").withTag("tag:yaml.org,2002:str"),
                    YamlAlgebraic("abcd").withTag("tag:yaml.org,2002:str")
                )
            ].dup).withTag("tag:yaml.org,2002:map")
    ];
}

YamlAlgebraic[] constructStrUTF8() @safe
{
    return [
        YamlAlgebraic("\u042d\u0442\u043e \u0443\u043d\u0438\u043a\u043e\u0434\u043d\u0430\u044f \u0441\u0442\u0440\u043e\u043a\u0430").withTag("tag:yaml.org,2002:str")
    ];
}

// canonical:        2001-12-15T02:59:43.1Z
// valid iso8601:    2001-12-14t21:59:43.1-05:00
// space separated:  2001-12-14 21:59:43.1 -5
// no time zone (Z): 2001-12-15 2:59:43.1
// date (00:00:00Z): 2002-12-14

YamlAlgebraic[] constructTimestamp() @safe
{
    return [
        YamlAlgebraic(
            [
                YamlPair(
                    YamlAlgebraic("canonical").withTag("tag:yaml.org,2002:str"),
                    YamlAlgebraic(Timestamp(2001, 12, 15, 2, 59, 43, -1, 1)).withTag("tag:yaml.org,2002:timestamp")
                ),
                YamlPair(
                    YamlAlgebraic("valid iso8601").withTag("tag:yaml.org,2002:str"),
                    YamlAlgebraic(Timestamp(2001, 12, 15, 2, 59, 43, -1, 1).withOffset(-300)).withTag("tag:yaml.org,2002:timestamp")
                ),
                YamlPair(
                    YamlAlgebraic("space separated").withTag("tag:yaml.org,2002:str"),
                    YamlAlgebraic(Timestamp(2001, 12, 15, 2, 59, 43, -1, 1).withOffset(-300)).withTag("tag:yaml.org,2002:timestamp")
                ),
                YamlPair(
                    YamlAlgebraic("no time zone (Z)").withTag("tag:yaml.org,2002:str"),
                    YamlAlgebraic(Timestamp(2001, 12, 15, 2, 59, 43, -1, 1)).withTag("tag:yaml.org,2002:timestamp")
                ),
                YamlPair(
                    YamlAlgebraic("date (00:00:00Z)").withTag("tag:yaml.org,2002:str"),
                    YamlAlgebraic(Timestamp(2002, 12, 14)).withTag("tag:yaml.org,2002:timestamp")
                )
            ].dup).withTag("tag:yaml.org,2002:map")
    ];
}

YamlAlgebraic[] constructValue() @safe
{
    return [
        YamlAlgebraic(
            [
                YamlPair(
                    YamlAlgebraic("link with").withTag("tag:yaml.org,2002:str"),
                    YamlAlgebraic(
                        [
                            YamlAlgebraic("library1.dll").withTag("tag:yaml.org,2002:str"),
                            YamlAlgebraic("library2.dll").withTag("tag:yaml.org,2002:str")
                        ].dup).withTag("tag:yaml.org,2002:seq")
                )
            ].dup).withTag("tag:yaml.org,2002:map"),
        YamlAlgebraic(
            [
                YamlPair(
                    YamlAlgebraic("link with").withTag("tag:yaml.org,2002:str"),
                    YamlAlgebraic(
                        [
                            YamlAlgebraic(
                                [
                                    YamlPair(
                                        YamlAlgebraic("=").withTag("tag:yaml.org,2002:value"),
                                        YamlAlgebraic("library1.dll").withTag("tag:yaml.org,2002:str")
                                    ),
                                    YamlPair(
                                        YamlAlgebraic("version").withTag("tag:yaml.org,2002:str"),
                                        YamlAlgebraic(1.2L).withTag("tag:yaml.org,2002:float")
                                    )
                                ].dup).withTag("tag:yaml.org,2002:map"),
                            YamlAlgebraic(
                                [
                                    YamlPair(
                                        YamlAlgebraic("=").withTag("tag:yaml.org,2002:value"),
                                        YamlAlgebraic("library2.dll").withTag("tag:yaml.org,2002:str")
                                    ),
                                    YamlPair(
                                        YamlAlgebraic("version").withTag("tag:yaml.org,2002:str"),
                                        YamlAlgebraic(2.3L).withTag("tag:yaml.org,2002:float")
                                    )
                                ].dup).withTag("tag:yaml.org,2002:map")
                        ].dup).withTag("tag:yaml.org,2002:seq")
                )
            ].dup).withTag("tag:yaml.org,2002:map")
    ];
}

YamlAlgebraic[] duplicateMergeKey() @safe
{
    return [
        YamlAlgebraic(
            [
                YamlPair(
                    YamlAlgebraic("foo").withTag("tag:yaml.org,2002:str"),
                    YamlAlgebraic("bar").withTag("tag:yaml.org,2002:str")
                ),
                YamlPair(
                    YamlAlgebraic("x").withTag("tag:yaml.org,2002:str"),
                    YamlAlgebraic(1L).withTag("tag:yaml.org,2002:int")
                ),
                YamlPair(
                    YamlAlgebraic("y").withTag("tag:yaml.org,2002:str"),
                    YamlAlgebraic(2L).withTag("tag:yaml.org,2002:int")
                ),
                YamlPair(
                    YamlAlgebraic("z").withTag("tag:yaml.org,2002:str"),
                    YamlAlgebraic(3L).withTag("tag:yaml.org,2002:int")
                ),
                YamlPair(
                    YamlAlgebraic("t").withTag("tag:yaml.org,2002:str"),
                    YamlAlgebraic(4L).withTag("tag:yaml.org,2002:int")
                )
            ].dup).withTag("tag:yaml.org,2002:map")
    ];
}

YamlAlgebraic[] floatRepresenterBug() @safe
{
    return [
        YamlAlgebraic(
            [
                YamlPair(
                    YamlAlgebraic(1.0L).withTag("tag:yaml.org,2002:float"),
                    YamlAlgebraic(1L).withTag("tag:yaml.org,2002:int")
                ),
                YamlPair(
                    YamlAlgebraic(double.infinity).withTag("tag:yaml.org,2002:float"),
                    YamlAlgebraic(10L).withTag("tag:yaml.org,2002:int")
                ),
                YamlPair(
                    YamlAlgebraic(-double.infinity).withTag("tag:yaml.org,2002:float"),
                    YamlAlgebraic(-10L).withTag("tag:yaml.org,2002:int")
                ),
                YamlPair(
                    YamlAlgebraic(double.nan).withTag("tag:yaml.org,2002:float"),
                    YamlAlgebraic(100L).withTag("tag:yaml.org,2002:int")
                )
            ].dup).withTag("tag:yaml.org,2002:map")
    ];
}

YamlAlgebraic[] noneSingleQuoteBug() @safe
{
    return [
        YamlAlgebraic(
            [
                YamlAlgebraic("foo \'bar\'").withTag("tag:yaml.org,2002:str"),
                YamlAlgebraic("foo\n\'bar\'").withTag("tag:yaml.org,2002:str")
            ].dup).withTag("tag:yaml.org,2002:seq")
    ];
}

YamlAlgebraic[] moreFloats() @safe
{
    return [
        YamlAlgebraic(
            [
                YamlAlgebraic(0.0L).withTag("tag:yaml.org,2002:float"),
                YamlAlgebraic(1.0L).withTag("tag:yaml.org,2002:float"),
                YamlAlgebraic(-1.0L).withTag("tag:yaml.org,2002:float"),
                YamlAlgebraic(double.infinity).withTag("tag:yaml.org,2002:float"),
                YamlAlgebraic(-double.infinity).withTag("tag:yaml.org,2002:float"),
                YamlAlgebraic(double.nan).withTag("tag:yaml.org,2002:float"),
                YamlAlgebraic(double.nan).withTag("tag:yaml.org,2002:float")
            ].dup).withTag("tag:yaml.org,2002:seq")
    ];
}

YamlAlgebraic[] negativeFloatBug() @safe
{
    return [
        YamlAlgebraic(-1.0L).withTag("tag:yaml.org,2002:float")
    ];
}

YamlAlgebraic[] singleDotFloatBug() @safe
{
    return [
        YamlAlgebraic(".").withTag("tag:yaml.org,2002:str")
    ];
}

YamlAlgebraic[] timestampBugs() @safe
{
    return [
        YamlAlgebraic(
            [
                "2001-12-14T21:59:43.1-05:30".Timestamp.YamlAlgebraic.withTag("tag:yaml.org,2002:timestamp"),
                "2001-12-14T21:59:43.1+05:30".Timestamp.YamlAlgebraic.withTag("tag:yaml.org,2002:timestamp"),
                "2001-12-14T21:59:43.00101Z".Timestamp.YamlAlgebraic.withTag("tag:yaml.org,2002:timestamp"),
                "2001-12-14T21:59:43+01".Timestamp.YamlAlgebraic.withTag("tag:yaml.org,2002:timestamp"),
                "2001-12-14T21:59:43-01:30".Timestamp.YamlAlgebraic.withTag("tag:yaml.org,2002:timestamp"),
                "2005-07-08T17:35:04.517600Z".Timestamp.YamlAlgebraic.withTag("tag:yaml.org,2002:timestamp")
            ].dup).withTag("tag:yaml.org,2002:seq")
    ];
}

YamlAlgebraic[] utf16be() @safe
{
    return [
        YamlAlgebraic("UTF-16-BE").withTag("tag:yaml.org,2002:str")
    ];
}

YamlAlgebraic[] utf16le() @safe
{
    return [
        YamlAlgebraic("UTF-16-LE").withTag("tag:yaml.org,2002:str")
    ];
}

YamlAlgebraic[] utf8() @safe
{
    return [
        YamlAlgebraic("UTF-8").withTag("tag:yaml.org,2002:str")
    ];
}

YamlAlgebraic[] utf8implicit() @safe
{
    return [
        YamlAlgebraic("implicit UTF-8").withTag("tag:yaml.org,2002:str")
    ];
}
} // version(unittest)

@safe unittest
{
    import mir.internal.yaml.test.common : assertNodesEqual, run;
    /**
    Constructor unittest.

    Params:
        dataFilename = File name to read from.
        codeDummy = Dummy .code filename, used to determine that
            .data file with the same name should be used in this test.
    */
    static void testConstructor(string dataFilename, string codeDummy) @safe
    {
        string base = dataFilename.baseName.stripExtension;
        assert((base in expected) !is null, "Unimplemented constructor test: " ~ base);

        auto loader = Loader.fromFile(dataFilename);

        YamlAlgebraic[] exp = expected[base];

        //Compare with expected results document by document.
        size_t i;
        foreach (node; loader.loadAll)
        {
            assertNodesEqual(node, exp[i]);
            ++i;
        }
        assert(i == exp.length);
    }
    run(&testConstructor, ["data", "code"]);
}
