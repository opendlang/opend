
//          Copyright Ferdinand Majerech 2011.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)

/**
 * YAML node _representer. Prepares YAML nodes for output. A tutorial can be
 * found $(LINK2 ../tutorials/custom_types.html, here).
 *
 * Code based on $(LINK2 http://www.pyyaml.org, PyYAML).
 */
module mir.internal.yaml.representer;


import mir.conv;
import mir.math;
import mir.timestamp;
import mir.array.allocation: array;
import mir.base64;

import mir.internal.yaml.exception;
import mir.algebraic_alias.yaml;
import mir.internal.yaml.serializer;

package:

auto withTag(YamlAlgebraic node, string tag)
{
    node.tag = tag;
    return node;
}

bool hasDuplicates(const YamlPair[] pairs) @safe
{
    import mir.ndslice.sorting: sort;
    import mir.ndslice.topology: member, pairwise;
    import mir.algorithm.iteration: any;
    return pairs.member!"key".dup.sort.pairwise!"a == b".any;
}

///Exception thrown on Representer errors.
class RepresenterException : YamlException
{
    mixin ExceptionCtors;
}

/**
 * Represents YAML nodes as scalar, sequence and mapping nodes ready for output.
 */
YamlAlgebraic representData(const YamlAlgebraic data, YamlScalarStyle defaultScalarStyle, YamlCollectionStyle defaultCollectionStyle) @safe
{
    YamlAlgebraic result;
    final switch(data.kind)
    {
        case YamlAlgebraic.Kind.null_:
            result = representNull();
            break;
        case YamlAlgebraic.Kind.boolean:
            result = representBool(data);
            break;
        case YamlAlgebraic.Kind.integer:
            result = representLong(data);
            break;
        case YamlAlgebraic.Kind.float_:
            result = representReal(data);
            break;
        case YamlAlgebraic.Kind.blob:
            result = representBytes(data);
            break;
        case YamlAlgebraic.Kind.timestamp:
            result = representTimestamp(data);
            break;
        case YamlAlgebraic.Kind.string:
            result = representString(data);
            break;
        case YamlAlgebraic.Kind.object:
            result = representPairs(data, defaultScalarStyle, defaultCollectionStyle);
            break;
        case YamlAlgebraic.Kind.array:
            result = representNodes(data, defaultScalarStyle, defaultCollectionStyle);
            break;
    }

    switch (result.kind)
    {
        default:
            if (result.scalarStyle == YamlScalarStyle.none)
            {
                result.scalarStyle = defaultScalarStyle;
            }
            break;
        case YamlAlgebraic.Kind.array, YamlAlgebraic.Kind.object:
            if (defaultCollectionStyle != YamlCollectionStyle.none)
            {
                result.collectionStyle = defaultCollectionStyle;
            }
            break;
    }


    //Override tag if specified.
    if(data.tag !is null){result.tag = data.tag;}

    //Remember style if this was loaded before.
    if(data.scalarStyle != YamlScalarStyle.none)
    {
        result.scalarStyle = data.scalarStyle;
    }
    if(data.collectionStyle != YamlCollectionStyle.none)
    {
        result.collectionStyle = data.collectionStyle;
    }
    return result;
}

@safe unittest
{
    // We don't emit yaml merge nodes.
    // assert(representData(YamlAlgebraic(YAMLMerge()), YamlScalarStyle.none, YamlCollectionStyle.none) == YamlAlgebraic.init);
}

@safe unittest
{
    assert(representData(YamlAlgebraic(null), YamlScalarStyle.none, YamlCollectionStyle.none) == YamlAlgebraic("null").withTag("tag:yaml.org,2002:null"));
}

@safe unittest
{
    assert(representData(YamlAlgebraic(cast(string)null), YamlScalarStyle.none, YamlCollectionStyle.none) == YamlAlgebraic("null").withTag("tag:yaml.org,2002:null"));
    assert(representData(YamlAlgebraic("Hello world!"), YamlScalarStyle.none, YamlCollectionStyle.none) == YamlAlgebraic("Hello world!").withTag("tag:yaml.org,2002:str"));
}

@safe unittest
{
    assert(representData(YamlAlgebraic(64), YamlScalarStyle.none, YamlCollectionStyle.none) == YamlAlgebraic("64").withTag("tag:yaml.org,2002:int"));
}

@safe unittest
{
    assert(representData(YamlAlgebraic(true), YamlScalarStyle.none, YamlCollectionStyle.none) == YamlAlgebraic("true").withTag("tag:yaml.org,2002:bool"));
    assert(representData(YamlAlgebraic(false), YamlScalarStyle.none, YamlCollectionStyle.none) == YamlAlgebraic("false").withTag("tag:yaml.org,2002:bool"));
}

@safe unittest
{
    // Float comparison is pretty unreliable...
    auto result = representData(YamlAlgebraic(1.0), YamlScalarStyle.none, YamlCollectionStyle.none);
    assert(approxEqual(result.get!string.to!double, 1.0));
    assert(result.tag == "tag:yaml.org,2002:float");

    assert(representData(YamlAlgebraic(double.nan), YamlScalarStyle.none, YamlCollectionStyle.none) == YamlAlgebraic(".nan").withTag("tag:yaml.org,2002:float"));
    assert(representData(YamlAlgebraic(double.infinity), YamlScalarStyle.none, YamlCollectionStyle.none) == YamlAlgebraic(".inf").withTag("tag:yaml.org,2002:float"));
    assert(representData(YamlAlgebraic(-double.infinity), YamlScalarStyle.none, YamlCollectionStyle.none) == YamlAlgebraic("-.inf").withTag("tag:yaml.org,2002:float"));
}

unittest
{
    import mir.conv;
    assert(representData(YamlAlgebraic(Timestamp(2000, 3, 14, 12, 34, 56)), YamlScalarStyle.none, YamlCollectionStyle.none) == YamlAlgebraic("2000-03-14T12:34:56Z").withTag("tag:yaml.org,2002:timestamp"));
}

@safe unittest
{
    assert(representData(YamlAlgebraic(YamlAlgebraic[].init).withTag("tag:yaml.org,2002:set"), YamlScalarStyle.none, YamlCollectionStyle.none) == YamlAlgebraic(YamlPair[].init).withTag("tag:yaml.org,2002:set"));
    assert(representData(YamlAlgebraic(YamlAlgebraic[].init).withTag("tag:yaml.org,2002:seq"), YamlScalarStyle.none, YamlCollectionStyle.none) == YamlAlgebraic(YamlAlgebraic[].init).withTag("tag:yaml.org,2002:seq"));
    {
        auto nodes = [
            YamlAlgebraic("a"),
            YamlAlgebraic("b"),
            YamlAlgebraic("c"),
        ];
        assert(representData(YamlAlgebraic(nodes).withTag("tag:yaml.org,2002:set"), YamlScalarStyle.none, YamlCollectionStyle.none) ==
            YamlAlgebraic([
                YamlPair(
                    YamlAlgebraic("a").withTag("tag:yaml.org,2002:str"),
                    YamlAlgebraic("null").withTag("tag:yaml.org,2002:null")
                ),
                YamlPair(
                    YamlAlgebraic("b").withTag("tag:yaml.org,2002:str"),
                    YamlAlgebraic("null").withTag("tag:yaml.org,2002:null")
                ),
                YamlPair(
                    YamlAlgebraic("c").withTag("tag:yaml.org,2002:str"),
                    YamlAlgebraic("null").withTag("tag:yaml.org,2002:null")
                )
            ].dup).withTag("tag:yaml.org,2002:set"));
    }
    {
        auto nodes = [
            YamlAlgebraic("a"),
            YamlAlgebraic("b"),
            YamlAlgebraic("c"),
        ];
        assert(representData(YamlAlgebraic(nodes).withTag("tag:yaml.org,2002:seq"), YamlScalarStyle.none, YamlCollectionStyle.none) ==
            YamlAlgebraic([
                YamlAlgebraic("a").withTag("tag:yaml.org,2002:str"),
                YamlAlgebraic("b").withTag("tag:yaml.org,2002:str"),
                YamlAlgebraic("c").withTag("tag:yaml.org,2002:str")
            ].dup).withTag("tag:yaml.org,2002:seq"));
    }
}

@safe unittest
{
    import std.exception: assertThrown;
    import mir.test;
    assert(representData(YamlAlgebraic(YamlPair[].init).withTag("tag:yaml.org,2002:omap"), YamlScalarStyle.none, YamlCollectionStyle.none) == YamlAlgebraic(YamlAlgebraic[].init).withTag("tag:yaml.org,2002:omap"));
    assert(representData(YamlAlgebraic(YamlPair[].init).withTag("tag:yaml.org,2002:pairs"), YamlScalarStyle.none, YamlCollectionStyle.none) == YamlAlgebraic(YamlAlgebraic[].init).withTag("tag:yaml.org,2002:pairs"));
    assert(representData(YamlAlgebraic(YamlPair[].init).withTag("tag:yaml.org,2002:map"), YamlScalarStyle.none, YamlCollectionStyle.none) == YamlAlgebraic(YamlPair[].init).withTag("tag:yaml.org,2002:map"));
    {
        auto nodes = [
            YamlPair("a", "b"),
            YamlPair("a", "c")
        ];
        assertThrown(representData(YamlAlgebraic(nodes).withTag("tag:yaml.org,2002:omap"), YamlScalarStyle.none, YamlCollectionStyle.none));
    }
    // Yeah, this gets ugly really fast.
    {
        auto nodes = [
            YamlPair("a", "b"),
            YamlPair("a", "c")
        ];
        representData(YamlAlgebraic(nodes).withTag("tag:yaml.org,2002:pairs"), YamlScalarStyle.none, YamlCollectionStyle.none).should ==
            YamlAlgebraic([
                YamlAlgebraic(
                    [YamlPair(
                        YamlAlgebraic("a").withTag("tag:yaml.org,2002:str"),
                        YamlAlgebraic("b").withTag("tag:yaml.org,2002:str")
                    )].dup).withTag("tag:yaml.org,2002:map"),
                YamlAlgebraic(
                    [YamlPair(
                        YamlAlgebraic("a").withTag("tag:yaml.org,2002:str"),
                        YamlAlgebraic("c").withTag("tag:yaml.org,2002:str")
                    )].dup).withTag("tag:yaml.org,2002:map"),
        ].dup).withTag("tag:yaml.org,2002:pairs");
    }
    {
        auto nodes = [
            YamlPair("a", "b"),
            YamlPair("a", "c")
        ];
        assertThrown(representData(YamlAlgebraic(nodes).withTag("tag:yaml.org,2002:map"), YamlScalarStyle.none, YamlCollectionStyle.none));
    }
    {
        auto nodes = [
            YamlPair("a", "b"),
            YamlPair("c", "d")
        ];
        assert(representData(YamlAlgebraic(nodes).withTag("tag:yaml.org,2002:omap"), YamlScalarStyle.none, YamlCollectionStyle.none) ==
            YamlAlgebraic([
                YamlAlgebraic([
                    YamlPair(
                        YamlAlgebraic("a").withTag("tag:yaml.org,2002:str"),
                        YamlAlgebraic("b").withTag("tag:yaml.org,2002:str")
                    )
                ].dup).withTag("tag:yaml.org,2002:map"),
                YamlAlgebraic([
                    YamlPair(
                        YamlAlgebraic("c").withTag("tag:yaml.org,2002:str"),
                        YamlAlgebraic("d").withTag("tag:yaml.org,2002:str")
                    )
                ].dup).withTag("tag:yaml.org,2002:map"
            )].dup).withTag("tag:yaml.org,2002:omap"));
    }
    {
        auto nodes = [
            YamlPair("a", "b"),
            YamlPair("c", "d")
        ];
        assert(representData(YamlAlgebraic(nodes).withTag("tag:yaml.org,2002:map"), YamlScalarStyle.none, YamlCollectionStyle.none) ==
            YamlAlgebraic([
                YamlPair(
                    YamlAlgebraic("a").withTag("tag:yaml.org,2002:str"),
                    YamlAlgebraic("b").withTag("tag:yaml.org,2002:str")
                ),
                YamlPair(
                    YamlAlgebraic("c").withTag("tag:yaml.org,2002:str"),
                    YamlAlgebraic("d").withTag("tag:yaml.org,2002:str")
                ),
            ].dup).withTag("tag:yaml.org,2002:map"));
    }
}

private:

//Represent a _null _node as a _null YAML value.
YamlAlgebraic representNull() @safe
{
    return YamlAlgebraic("null").withTag("tag:yaml.org,2002:null");
}

//Represent a string _node as a string scalar.
YamlAlgebraic representString(const YamlAlgebraic node) @safe
{
    string value = node.get!string;
    return value is null
           ? YamlAlgebraic("null").withTag("tag:yaml.org,2002:null")
           : YamlAlgebraic(value).withTag("tag:yaml.org,2002:str");
}

//Represent a bytes _node as a binary scalar.
YamlAlgebraic representBytes(const YamlAlgebraic node) @safe
{
    const ubyte[] value = node.get!"blob".data;
    if(value is null){return YamlAlgebraic("null").withTag("tag:yaml.org,2002:null");}

    auto newNode = YamlAlgebraic(encodeBase64(value)).withTag("tag:yaml.org,2002:binary");
    newNode.scalarStyle = YamlScalarStyle.literal;
    return newNode;
}

//Represent a bool _node as a bool scalar.
YamlAlgebraic representBool(const YamlAlgebraic node) @safe
{
    return YamlAlgebraic(node.get!bool ? "true" : "false").withTag("tag:yaml.org,2002:bool");
}

//Represent a long _node as an integer scalar.
YamlAlgebraic representLong(const YamlAlgebraic node) @safe
{
    return YamlAlgebraic(node.get!long.to!string).withTag("tag:yaml.org,2002:int");
}

//Represent a double _node as a floating point scalar.
YamlAlgebraic representReal(const YamlAlgebraic node) @safe
{
    import mir.conv: to;
    double f = node.get!double;
    string value = f != f                    ? ".nan":
                   f == double.infinity        ? ".inf":
                   f == -1.0 * double.infinity ? "-.inf":
                   f.to!string;
    return YamlAlgebraic(value).withTag("tag:yaml.org,2002:float");
}

//Represent a _node as a timestamp.
YamlAlgebraic representTimestamp(const YamlAlgebraic node) @safe
{
    return YamlAlgebraic(node.get!Timestamp.toISOExtString()).withTag("tag:yaml.org,2002:timestamp");
}

//Represent a sequence _node as sequence/set.
YamlAlgebraic representNodes(const YamlAlgebraic node, YamlScalarStyle defaultScalarStyle, YamlCollectionStyle defaultCollectionStyle) @safe
{
    auto nodes = node.get!(YamlAlgebraic[]);
    if(node.tag == "tag:yaml.org,2002:set")
    {
        //YAML sets are mapping with null values.
        YamlPair[] pairs;
        pairs.length = nodes.length;

        foreach(idx, key; nodes)
        {
            pairs[idx] = YamlPair(key, YamlAlgebraic("null").withTag("tag:yaml.org,2002:null"));
        }
        YamlPair[] value;
        value.length = pairs.length;

        auto bestStyle = YamlCollectionStyle.flow;
        foreach(idx, pair; pairs)
        {
            value[idx] = YamlPair(representData(pair.key, defaultScalarStyle, defaultCollectionStyle), representData(pair.value, defaultScalarStyle, defaultCollectionStyle));
            if(value[idx].shouldUseBlockStyle)
            {
                bestStyle = YamlCollectionStyle.block;
            }
        }

        auto newNode = YamlAlgebraic(value).withTag(node.tag);
        newNode.collectionStyle = bestStyle;
        return newNode;
    }
    else
    {
        YamlAlgebraic[] value;
        value.length = nodes.length;

        auto bestStyle = YamlCollectionStyle.flow;
        foreach(idx, item; nodes)
        {
            value[idx] = representData(item, defaultScalarStyle, defaultCollectionStyle);
            const isScalar = value[idx].isScalar;
            const s = value[idx].scalarStyle;
            if(!isScalar || (s != YamlScalarStyle.none && s != YamlScalarStyle.plain))
            {
                bestStyle = YamlCollectionStyle.block;
            }
        }

        auto newNode = YamlAlgebraic(value).withTag("tag:yaml.org,2002:seq");
        newNode.collectionStyle = bestStyle;
        return newNode;
    }
}

bool shouldUseBlockStyle(const YamlAlgebraic value) @safe
{
    const isScalar = value.isScalar;
    const s = value.scalarStyle;
    return (!isScalar || (s != YamlScalarStyle.none && s != YamlScalarStyle.plain));
}
bool shouldUseBlockStyle(const YamlPair value) @safe
{
    const keyScalar = value.key.isScalar;
    const valScalar = value.value.isScalar;
    const keyStyle = value.key.scalarStyle;
    const valStyle = value.value.scalarStyle;
    if(!keyScalar ||
       (keyStyle != YamlScalarStyle.none && keyStyle != YamlScalarStyle.plain))
    {
        return true;
    }
    if(!valScalar ||
       (valStyle != YamlScalarStyle.none && valStyle != YamlScalarStyle.plain))
    {
        return true;
    }
    return false;
}

//Represent a mapping _node as map/ordered map/pairs.
YamlAlgebraic representPairs(const YamlAlgebraic node, YamlScalarStyle defaultScalarStyle, YamlCollectionStyle defaultCollectionStyle) @safe
{
    import mir.ndslice.sorting: sort;
    auto pairs = node.get!"object".pairs;

    YamlAlgebraic[] mapToSequence(const YamlPair[] pairs) @safe
    {
        YamlAlgebraic[] nodes;
        nodes.length = pairs.length;
        foreach(idx, pair; pairs)
        {
            YamlPair value;

            auto bestStyle = value.shouldUseBlockStyle ? YamlCollectionStyle.block : YamlCollectionStyle.flow;
            value = YamlPair(representData(pair.key, defaultScalarStyle, defaultCollectionStyle), representData(pair.value, defaultScalarStyle, defaultCollectionStyle));

            auto newNode = YamlAlgebraic([value].dup).withTag("tag:yaml.org,2002:map");
            newNode.collectionStyle = bestStyle;
            nodes[idx] = newNode;
        }
        return nodes;
    }

    if(node.tag == "tag:yaml.org,2002:omap")
    {
        if (hasDuplicates(pairs))
                throw new RepresenterException("Duplicate entry in an ordered map");
        auto sequence = mapToSequence(pairs);
        YamlAlgebraic[] value;
        value.length = sequence.length;

        auto bestStyle = YamlCollectionStyle.flow;
        foreach(idx, item; sequence)
        {
            value[idx] = representData(item, defaultScalarStyle, defaultCollectionStyle);
            if(value[idx].shouldUseBlockStyle)
            {
                bestStyle = YamlCollectionStyle.block;
            }
        }

        auto newNode = YamlAlgebraic(value).withTag(node.tag);
        newNode.collectionStyle = bestStyle;
        return newNode;
    }
    else if(node.tag == "tag:yaml.org,2002:pairs")
    {
        auto sequence = mapToSequence(pairs);
        YamlAlgebraic[] value;
        value.length = sequence.length;

        auto bestStyle = YamlCollectionStyle.flow;
        foreach(idx, item; sequence)
        {
            value[idx] = representData(item, defaultScalarStyle, defaultCollectionStyle);
            if(value[idx].shouldUseBlockStyle)
            {
                bestStyle = YamlCollectionStyle.block;
            }
        }

        auto newNode = YamlAlgebraic(value).withTag(node.tag);
        newNode.collectionStyle = bestStyle;
        return newNode;
    }
    else
    {
        if (hasDuplicates(pairs))
                throw new RepresenterException("Duplicate entry in an unordered map");
        YamlPair[] value;
        value.length = pairs.length;

        auto bestStyle = YamlCollectionStyle.flow;
        foreach(idx, pair; pairs)
        {
            value[idx] = YamlPair(representData(pair.key, defaultScalarStyle, defaultCollectionStyle), representData(pair.value, defaultScalarStyle, defaultCollectionStyle));
            if(value[idx].shouldUseBlockStyle)
            {
                bestStyle = YamlCollectionStyle.block;
            }
        }

        auto newNode = YamlAlgebraic(value).withTag("tag:yaml.org,2002:map");
        newNode.collectionStyle = bestStyle;
        return newNode;
    }
}

private auto isScalar(const YamlAlgebraic node)
{
    return node.kind != YamlAlgebraic.Kind.array && node.kind != YamlAlgebraic.Kind.object;
}
