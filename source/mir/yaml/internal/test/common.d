
//          Copyright Ferdinand Majerech 2011.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)

module mir.internal.yaml.test.common;

version(unittest)
{

import std.algorithm.searching: canFind;
import std.algorithm.comparison: among;
import mir.algebraic_alias.yaml;
import mir.internal.yaml.event;
import mir.primitives;
import mir.array.allocation: array;
import mir.conv;
import mir.format;
import std.file;
import std.path;
import std.traits;

package:

/**
Run a test.

Params:
    testFunction = Unittest function.
    unittestExt = Extensions of data files needed for the unittest.
    skipExt = Extensions that must not be used for the unittest.
 */
void run(D)(D testFunction, string[] unittestExt, string[] skipExt = [])
{
    immutable string dataDir = __FILE_FULL_PATH__.dirName ~  "/../../../../../test/data";
    auto testFilenames = findTestFilenames(dataDir);

    if (unittestExt.length > 0)
    {
        outer: foreach (base, extensions; testFilenames)
        {
            string[] filenames;
            foreach (ext; unittestExt)
            {
                if (!extensions.canFind(ext))
                {
                    continue outer;
                }
                filenames ~= base ~ '.' ~ ext;
            }
            foreach (ext; skipExt)
            {
                if (extensions.canFind(ext))
                {
                    continue outer;
                }
            }

            execute(testFunction, filenames);
        }
    }
    else
    {
        execute(testFunction, string[].init);
    }
}

// TODO: remove when a @safe ubyte[] file read can be done.
/**
Reads a file as an array of bytes.

Params:
    filename = Full path to file to read.

Returns: The file's data.
*/
const(char)[] readData(string filename) @trusted
{
    import std.file : read;
    return readText(filename);
}
void assertNodesEqual(const scope YamlAlgebraic gotNode, const scope YamlAlgebraic expectedNode, string file = __FILE__, int line = __LINE__) @trusted
{
    import mir.test;
    import mir.ser.text;
    gotNode.serializeTextPretty.should == expectedNode.serializeTextPretty;
}

/**
Determine if events in events1 are equivalent to events in events2.

Params:
    events1 = A range of events to compare with.
    events2 = A second range of events to compare.

Returns: true if the events are equivalent, false otherwise.
*/
bool compareEvents(T, U)(T events1, U events2)
if (isInputRange!T && isInputRange!U && is(ElementType!T == Event) && is(ElementType!U == Event))
{
    import mir.ndslice.topology: zip;
    foreach (e1, e2; zip(events1, events2))
    {
        //Different event types.
        if (e1.id != e2.id)
        {
            return false;
        }
        //Different anchor (if applicable).
        if (e1.id.among!(EventID.sequenceStart, EventID.mappingStart, EventID.alias_, EventID.scalar)
            && e1.anchor != e2.anchor)
        {
            return false;
        }
        //Different collection tag (if applicable).
        if (e1.id.among!(EventID.sequenceStart, EventID.mappingStart) && e1.tag != e2.tag)
        {
            return false;
        }
        if (e1.id == EventID.scalar)
        {
            //Different scalar tag (if applicable).
            if (!(e1.implicit || e2.implicit) && e1.tag != e2.tag)
            {
                return false;
            }
            //Different scalar value.
            if (e1.value != e2.value)
            {
                return false;
            }
        }
    }
    return true;
}
/**
Throw an Error if events in events1 aren't equivalent to events in events2.

Params:
    events1 = First event array to compare.
    events2 = Second event array to compare.
*/
void assertEventsEqual(T, U)(T events1, U events2)
if (isInputRange!T && isInputRange!U && is(ElementType!T == Event) && is(ElementType!U == Event))
{
    auto events1Copy = events1.array;
    auto events2Copy = events2.array;
    assert(compareEvents(events1Copy, events2Copy), text("Got '", events1Copy, "', expected '", events2Copy, "'"));
}

private:

/**
Find unittest input filenames.

Params:  dir = Directory to look in.

Returns: Test input base filenames and their extensions.
*/
 //@trusted due to dirEntries
string[][string] findTestFilenames(const string dir) @trusted
{
    //Groups of extensions indexed by base names.
    string[][string] names;
    foreach (string name; dirEntries(dir, SpanMode.shallow))
    {
        if (isFile(name))
        {
            string base = name.stripExtension();
            string ext = name.extension();
            if (ext is null)
            {
                ext = "";
            }
            if (ext[0] == '.')
            {
                ext = ext[1 .. $];
            }

            //If the base name doesn't exist yet, add it; otherwise add new extension.
            names[base] = ((base in names) is null) ? [ext] : names[base] ~ ext;
        }
    }
    return names;
}

/**
Recursively copy an array of strings to a tuple to use for unittest function input.

Params:
    index = Current index in the array/tuple.
    tuple = Tuple to copy to.
    strings = Strings to copy.
*/
void stringsToTuple(uint index, F ...)(ref F tuple, const string[] strings)
in(F.length == strings.length)
do
{
    tuple[index] = strings[index];
    static if (index > 0)
    {
        stringsToTuple!(index - 1, F)(tuple, strings);
    }
}

/**
Execute an unittest on specified files.

Params:
    testName = Name of the unittest.
    testFunction = Unittest function.
    filenames = Names of input files to test with.
 */
void execute(D)(D testFunction, string[] filenames)
{
    //Convert filenames to parameters tuple and call the test function.
    alias F = Parameters!D[0..$];
    F parameters;
    stringsToTuple!(F.length - 1, F)(parameters, filenames);
    testFunction(parameters);
}

} // version(unittest)
