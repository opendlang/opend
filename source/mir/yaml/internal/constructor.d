
//          Copyright Ferdinand Majerech 2011.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)

/**
 * Class that processes YAML mappings, sequences and scalars into nodes.
 * This can be used to add custom data types. A tutorial can be found
 * $(LINK2 https://dlang-community.github.io/D-YAML/, here).
 */
module mir.yaml.internal.constructor;

import mir.timestamp;
import mir.algorithm.iteration: filter;
import std.algorithm.searching: canFind, startsWith;
import std.algorithm.comparison: among;
import mir.array.allocation: array;
import mir.base64;
import mir.conv;
import std.exception;
import mir.exception: MirException;
import std.string: representation, empty, split, replace, toLower;

import mir.algebraic_alias.yaml;
import mir.yaml.internal.exception;

package:

// Exception thrown at constructor errors.
class ConstructorException : YamlException
{
    /// Construct a ConstructorException.
    ///
    /// Params:  msg   = Error message.
    ///          start = Start position of the error context.
    ///          end   = End position of the error context.
    this(string msg, ParsePosition start, ParsePosition end, string file = __FILE__, size_t line = __LINE__)
        @safe pure nothrow
    {
        import mir.format: text;
        super(text(msg, "\nstart: ", start, "\nend: ", end), file, line);
    }
}

@safe pure:

/** Constructs YAML values.
 *
 * Each YAML scalar, sequence or mapping has a tag specifying its data type.
 * Constructor uses user-specifyable functions to create a node of desired
 * data type from a scalar, sequence or mapping.
 *
 *
 * Each of these functions is associated with a tag, and can process either
 * a scalar, a sequence, or a mapping. The constructor passes each value to
 * the function with corresponding tag, which then returns the resulting value
 * that can be stored in a node.
 *
 * If a tag is detected with no known constructor function, it is considered an error.
 */
/*
 * Construct a node.
 *
 * Params:  start = Start position of the node.
 *          end   = End position of the node.
 *          tag   = Tag (data type) of the node.
 *          value = Value to construct node from (string, nodes or pairs).
 *          style = Style of the node (scalar or collection style).
 *
 * Returns: Constructed node.
 */
YamlAlgebraic constructNode(T)(const ParsePosition start, const ParsePosition end, return string tag,
                T value) @safe
    if((is(T : string) || is(T == YamlAlgebraic[]) || is(T == YamlPair[])))
{
    YamlAlgebraic newNode;
    try
    {
        switch(tag)
        {
            case "tag:yaml.org,2002:null":
                newNode = YamlAlgebraic(null);
                newNode.tag = tag;
                break;
            case "tag:yaml.org,2002:bool":
                static if(is(T == string))
                {
                    newNode = YamlAlgebraic(constructBool(value));
                    newNode.tag = tag;
                    break;
                }
                else throw new Exception("Only scalars can be bools");
            case "tag:yaml.org,2002:int":
                static if(is(T == string))
                {
                    newNode = YamlAlgebraic(constructLong(value));
                    newNode.tag = tag;
                    break;
                }
                else throw new Exception("Only scalars can be ints");
            case "tag:yaml.org,2002:float":
                static if(is(T == string))
                {
                    newNode = YamlAlgebraic(constructReal(value));
                    newNode.tag = tag;
                    break;
                }
                else throw new Exception("Only scalars can be floats");
            case "tag:yaml.org,2002:binary":
                static if(is(T == string))
                {
                    newNode = YamlAlgebraic(constructBinary(value));
                    newNode.tag = tag;
                    break;
                }
                else throw new Exception("Only scalars can be binary data");
            case "tag:yaml.org,2002:timestamp":
                static if(is(T == string))
                {
                    newNode = YamlAlgebraic(constructTimestamp(value));
                    newNode.tag = tag;
                    break;
                }
                else throw new Exception("Only scalars can be timestamps");
            case "tag:yaml.org,2002:str":
                static if(is(T == string))
                {
                    newNode = YamlAlgebraic(constructString(value));
                    newNode.tag = tag;
                    break;
                }
                else throw new Exception("Only scalars can be strings");
            case "tag:yaml.org,2002:value":
                static if(is(T == string))
                {
                    newNode = YamlAlgebraic(constructString(value));
                    newNode.tag = tag;
                    break;
                }
                else throw new Exception("Only scalars can be values");
            case "tag:yaml.org,2002:omap":
                static if(is(T == YamlAlgebraic[]))
                {
                    newNode = YamlAlgebraic(constructOrderedMap(value));
                    newNode.tag = tag;
                    break;
                }
                else throw new Exception("Only sequences can be ordered maps");
            case "tag:yaml.org,2002:pairs":
                static if(is(T == YamlAlgebraic[]))
                {
                    newNode = YamlAlgebraic(constructPairs(value));
                    newNode.tag = tag;
                    break;
                }
                else throw new Exception("Only sequences can be pairs");
            case "tag:yaml.org,2002:set":
                static if(is(T == YamlPair[]))
                {
                    newNode = YamlAlgebraic(constructSet(value));
                    newNode.tag = tag;
                    break;
                }
                else throw new Exception("Only mappings can be sets");
            case "tag:yaml.org,2002:seq":
                static if(is(T == YamlAlgebraic[]))
                {
                    newNode = YamlAlgebraic(constructSequence(value));
                    newNode.tag = tag;
                    break;
                }
                else throw new Exception("Only sequences can be sequences");
            case "tag:yaml.org,2002:map":
                static if(is(T == YamlPair[]))
                {
                    newNode = YamlAlgebraic(constructMap(value));
                    newNode.tag = tag;
                    break;
                }
                else throw new Exception("Only mappings can be maps");
            // case "tag:yaml.org,2002:merge":
            //     newNode = YamlAlgebraic(YAMLMerge());
            //     newNode.tag = tag;
            //     break;
            default:
                newNode = YamlAlgebraic(value);
                newNode.tag = tag;
                if (!tag.startsWith("tag:yaml.org"))
                {
                    newNode.startMark = start;
                    newNode = Annotated!YamlAlgebraic(tag.split("::"), newNode);
                }
                break;
        }
    }
    catch(Exception e)
    {
        throw new ConstructorException("Error constructing " ~ T.stringof ~ ":\n" ~ e.msg, start, end);
    }

    newNode.startMark = start;

    return newNode;
}

private:
// Construct a boolean _node.
bool constructBool(string str) @trusted
{
    auto value = str.toLower();
    if(value.among!("yes", "true", "on")){return true;}
    if(value.among!("no", "false", "off")){return false;}
    throw new MirException("Unable to parse boolean value: ", value);
}

// Construct an integer (long) _node.
long constructLong(string str) @safe
{
    auto value = str.replace("_", "");
    const char c = value[0];
    const long sign = c != '-' ? 1 : -1;
    if(c == '-' || c == '+')
    {
        value = value[1 .. $];
    }

    if (value == "")
        throw new MirException("Unable to parse float value: ", value);

    long result;

        import std.conv: stdTo = to;
        //Zero.
        if(value == "0")               {result = cast(long)0;}
        //Binary.
        else if(value.startsWith("0b")){result = sign * stdTo!int(value[2 .. $], 2);}
        //Hexadecimal.
        else if(value.startsWith("0x")){result = sign * stdTo!int(value[2 .. $], 16);}
        //Octal.
        else if(value[0] == '0')       {result = sign * stdTo!int(value, 8);}
        //Sexagesimal.
        else if(value.canFind(":"))
        {
            long val;
            long base = 1;
            foreach_reverse(digit; value.split(":"))
            {
                val += to!long(digit) * base;
                base *= 60;
            }
            result = sign * val;
        }
        //Decimal.
        else{result = sign * to!long(value);}

    return result;
}
@safe unittest
{
    string canonical   = "685230";
    string decimal     = "+685_230";
    string octal       = "02472256";
    string hexadecimal = "0x_0A_74_AE";
    string binary      = "0b1010_0111_0100_1010_1110";
    string sexagesimal = "190:20:30";

    assert(685230 == constructLong(canonical));
    assert(685230 == constructLong(decimal));
    assert(685230 == constructLong(octal));
    assert(685230 == constructLong(hexadecimal));
    assert(685230 == constructLong(binary));
    assert(685230 == constructLong(sexagesimal));
}

// Construct a floating point (double) _node.
double constructReal(string str) @safe
{
    import mir.conv: to;
    auto value = str.replace("_", "").toLower();
    const char c = value[0];
    const double sign = c != '-' ? 1.0 : -1.0;
    if(c == '-' || c == '+')
    {
        value = value[1 .. $];
    }

    if (value == "" || value == "nan" || value == "inf" || value == "-inf")
        throw new MirException("Unable to parse float value: ", value);

    double result;
        //Infinity.
        if     (value == ".inf"){result = sign * double.infinity;}
        //Not a Number.
        else if(value == ".nan"){result = double.nan;}
        //Sexagesimal.
        else if(value.canFind(":"))
        {
            double val = 0.0;
            double base = 1.0;
            foreach_reverse(digit; value.split(":"))
            {
                val += to!double(digit) * base;
                base *= 60.0;
            }
            result = sign * val;
        }
        //Plain floating point.
        else{result = sign * to!double(value);}

    return result;
}
@safe unittest
{
    bool eq(double a, double b, double epsilon = 0.2) @safe
    {
        return a >= (b - epsilon) && a <= (b + epsilon);
    }

    string canonical   = "6.8523015e+5";
    string exponential = "685.230_15e+03";
    string fixed       = "685_230.15";
    string sexagesimal = "190:20:30.15";
    string negativeInf = "-.inf";
    string NaN         = ".NaN";

    assert(eq(685230.15, constructReal(canonical)));
    assert(eq(685230.15, constructReal(exponential)));
    assert(eq(685230.15, constructReal(fixed)));
    assert(eq(685230.15, constructReal(sexagesimal)));
    assert(eq(-double.infinity, constructReal(negativeInf)));
    assert(to!string(constructReal(NaN)) == "nan");
}

// Construct a binary (base64) _node.
import mir.lob: Blob;
Blob constructBinary(string value) @trusted
{
    import std.ascii : newline;
    import mir.array.allocation : array;

    // For an unknown reason, this must be nested to work (compiler bug?).
    return decodeBase64(cast(string)value.representation.filter!(c => !newline.canFind(c)).array).Blob;
}

@safe unittest
{
    auto test = "The Answer: 42".representation;
    string input = encodeBase64(test);
    const value = constructBinary(input);
    assert(value.data == test);
    assert(value.data == [84, 104, 101, 32, 65, 110, 115, 119, 101, 114, 58, 32, 52, 50]);
}

// Construct a timestamp _node.
Timestamp constructTimestamp(string value) @safe
{
    try
    {
        return Timestamp.fromYamlString(value);
    }
    catch(Exception e)
    {
        throw new Exception("Unable to parse timestamp value " ~ value ~ " : " ~ e.msg);
    }
}
@safe unittest
{
    string timestamp(string value)
    {
        return constructTimestamp(value).toISOString();
    }

    string canonical      = "2001-12-15T02:59:43.1Z";
    string iso8601        = "2001-12-14t21:59:43.10-05:00";
    string spaceSeparated = "2001-12-14 21:59:43.10 -5";
    string noTZ           = "2001-12-15 2:59:43.10";
    string noFraction     = "2001-12-15 2:59:43";
    string ymd            = "2002-12-14";

    assert(timestamp(canonical)      == "20011215T025943.1Z", timestamp(canonical));
    //avoiding float conversion errors
    assert(timestamp(iso8601)        == "20011214T215943.10-05", timestamp(iso8601));
    assert(timestamp(spaceSeparated) == "20011214T215943.10-05", timestamp(spaceSeparated));
    assert(timestamp(noTZ)           == "20011215T025943.10Z", timestamp(noTZ));
    assert(timestamp(noFraction)     == "20011215T025943Z", timestamp(noFraction));
    assert(timestamp(ymd)            == "20021214", timestamp(ymd));
}

// Construct a string _node.
string constructString(string str) @safe
{
    return str;
}

// Convert a sequence of single-element mappings into a sequence of pairs.
YamlPair[] getPairs(string type, const YamlAlgebraic[] nodes) @safe
{
    YamlPair[] pairs;
    pairs.reserve(nodes.length);
    foreach(node; nodes)
    {
        enforce(node.kind == YamlAlgebraic.Kind.object && node.get!"object".length == 1,
                new Exception("While constructing " ~ type ~
                              ", expected a mapping with single element"));

        pairs ~= node.get!"object".pairs;
    }

    return pairs;
}

// Construct an ordered map (ordered sequence of key:value pairs without duplicates) _node.
YamlPair[] constructOrderedMap(const YamlAlgebraic[] nodes) @safe
{
    auto pairs = getPairs("ordered map", nodes);
    import mir.yaml.internal.representer: hasDuplicates;
    if (pairs.hasDuplicates)
        throw new Exception("Duplicate entry in an ordered map");
    return pairs;
}

@safe unittest
{
    YamlAlgebraic[] alternateTypes(uint length) @safe
    {
        YamlAlgebraic[] pairs;
        foreach(long i; 0 .. length)
        {
            auto pair = (i % 2) ? YamlPair(i.to!string, i) : YamlPair(i, i.to!string);
            pairs ~= YamlAlgebraic([pair].dup);
        }
        return pairs;
    }

    static auto sameType(uint length) @safe
    {
        YamlAlgebraic[] pairs;
        foreach(long i; 0 .. length)
        {
            auto pair = YamlPair(i.to!string, i);
            pairs ~= YamlAlgebraic([pair].dup);
        }
        return pairs;
    }

    assertThrown(constructOrderedMap(alternateTypes(8) ~ alternateTypes(2)));
    assertNotThrown(constructOrderedMap(alternateTypes(8)));
    assertThrown(constructOrderedMap(sameType(64) ~ sameType(16)));
    assertThrown(constructOrderedMap(alternateTypes(64) ~ alternateTypes(16)));
    assertNotThrown(constructOrderedMap(sameType(64)));
    assertNotThrown(constructOrderedMap(alternateTypes(64)));
}

// Construct a pairs (ordered sequence of key: value pairs allowing duplicates) _node.
YamlPair[] constructPairs(const YamlAlgebraic[] nodes) @safe
{
    return getPairs("pairs", nodes);
}

// Construct a set _node.
YamlAlgebraic[] constructSet(const YamlPair[] pairs) @safe
{
    // In future, the map here should be replaced with something with deterministic
    // memory allocation if possible.
    // Detect duplicates.
    ubyte[YamlAlgebraic] map;
    YamlAlgebraic[] nodes;
    nodes.reserve(pairs.length);
    foreach(pair; pairs)
    {
        enforce((pair.key in map) is null, new Exception("Duplicate entry in a set"));
        map[pair.key] = 0;
        nodes ~= pair.key;
    }

    return nodes;
}
@safe unittest
{
    YamlPair[] set(uint length) @safe
    {
        YamlPair[] pairs;
        foreach(long i; 0 .. length)
        {
            pairs ~= YamlPair(i.to!string, null);
        }

        return pairs;
    }

    auto DuplicatesShort   = set(8) ~ set(2);
    auto noDuplicatesShort = set(8);
    auto DuplicatesLong    = set(64) ~ set(4);
    auto noDuplicatesLong  = set(64);

    bool eq(YamlPair[] a, YamlAlgebraic[] b)
    {
        if(a.length != b.length){return false;}
        foreach(i; 0 .. a.length)
        {
            if(a[i].key != b[i])
            {
                return false;
            }
        }
        return true;
    }

    auto nodeDuplicatesShort   = DuplicatesShort.dup;
    auto nodeNoDuplicatesShort = noDuplicatesShort.dup;
    auto nodeDuplicatesLong    = DuplicatesLong.dup;
    auto nodeNoDuplicatesLong  = noDuplicatesLong.dup;

    assertThrown(constructSet(nodeDuplicatesShort));
    assertNotThrown(constructSet(nodeNoDuplicatesShort));
    assertThrown(constructSet(nodeDuplicatesLong));
    assertNotThrown(constructSet(nodeNoDuplicatesLong));
}

// Construct a sequence (array) _node.
YamlAlgebraic[] constructSequence(YamlAlgebraic[] nodes) @safe
{
    return nodes;
}

// Construct an unordered map (unordered set of key:value _pairs without duplicates) _node.
YamlPair[] constructMap(YamlPair[] pairs) @safe
{
    //Detect duplicates.
    //TODO this should be replaced by something with deterministic memory allocation.
    import mir.yaml.internal.representer: hasDuplicates;
    if (pairs.hasDuplicates)
        throw new Exception("Duplicate entry in a map");
    return pairs;
}
