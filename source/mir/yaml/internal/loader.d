
//          Copyright Ferdinand Majerech 2011.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)

/// Class used to load YAML documents.
module mir.internal.yaml.loader;


import std.exception;
import std.file;
import std.stdio : File;

import mir.internal.yaml.composer;
import mir.internal.yaml.constructor;
import mir.internal.yaml.event;
import mir.internal.yaml.exception;
import mir.algebraic_alias.yaml;
import mir.internal.yaml.parser;
import mir.internal.yaml.reader;
import mir.internal.yaml.resolver;
import mir.internal.yaml.scanner;
import mir.internal.yaml.token;


/** Loads YAML documents from files or string.
 *
 * User specified Constructor and/or Resolver can be used to support new
 * tags / data types.
 */
struct Loader
{
    private:
        // Processes tokens to YAML events.
        Composer composer_;
        // Are we done loading?
        bool done_;
        // Last node read from stream
        YamlAlgebraic currentNode;
        // Has the range interface been initialized yet?
        bool rangeInitialized;

    public:
        @disable this();
        @disable int opCmp(ref Loader);
        @disable bool opEquals(ref Loader);

        /** Construct a Loader to load YAML from a file.
         *
         * Params:  filename = Name of the file to load from.
         *          file = Already-opened file to load from.
         *
         * Throws:  YamlException if the file could not be opened or read.
         */
         static Loader fromFile(string filename) @trusted
         {
            try
            {
                auto loader = Loader(cast(string)std.file.read(filename), filename);
                return loader;
            }
            catch(FileException e)
            {
                throw new YamlException("Unable to open file " ~ filename ~ " for YAML loading: " ~ e.msg, e.file, e.line);
            }
         }

        /** Construct a Loader to load YAML from a string.
         *
         * Params:
         *   data = String to load YAML from.
         *   filename = The filename to give to the Loader, defaults to `"<unknown>"`
         *
         * Returns: Loader loading YAML from given string.
         *
         * Throws:
         *
         * YamlException if data could not be read (e.g. a decoding error)
         */
        static Loader fromString(string data, string filename = "<unknown>") @safe
        {
            return Loader(data, filename);
        }
        /// Load  a string.
        @safe unittest
        {
            assert(Loader.fromString("42".dup).load().get!long == 42);
        }
        /// Load a string.
        @safe unittest
        {
            assert(Loader.fromString("42").load().get!long == 42);
        }

        /** Construct a Loader to load YAML from a buffer.
         *
         * Params: yamlData = Buffer with YAML data to load. This may be e.g. a file
         *                    loaded to memory or a string with YAML data. Note that
         *                    buffer $(B will) be overwritten, as `mir-yaml` minimizes
         *                    memory allocations by reusing the input _buffer.
         *                    $(B Must not be deleted or modified by the user  as long
         *                    as nodes loaded by this Loader are in use!) - Nodes may
         *                    refer to data in this buffer.
         *
         * Note that `mir-yaml` looks for byte-order-marks YAML files encoded in
         * UTF-16/UTF-32 (and sometimes UTF-8) use to specify the encoding and
         * endianness, so it should be enough to load an entire file to a buffer and
         * pass it to `mir-yaml`, regardless of Unicode encoding.
         *
         * Throws:  YamlException if yamlData contains data illegal in YAML.
         */
        static Loader fromBuffer(string yamlData) @safe
        {
            return Loader(yamlData);
        }
        /// Ditto
        private this(string yamlData, string name = "<unknown>") @safe
        {
            composer_ = yamlData.Reader(name).Scanner.Parser.Composer(Resolver.withDefaultResolvers);
        }

        /** Load single YAML document.
         *
         * If none or more than one YAML document is found, this throws a YamlException.
         *
         * This can only be called once; this is enforced by contract.
         *
         * Returns: Root node of the document.
         *
         * Throws:  YamlException if there wasn't exactly one document
         *          or on a YAML parsing error.
         */
        YamlAlgebraic load() @safe
        {
            enforce!YamlException(!empty, "Zero documents in stream");
            auto output = front;
            popFront();
            enforce!YamlException(empty, "More than one document in stream");
            return output;
        }

        YamlAlgebraic[] loadAll() @safe
        {
            typeof(return) ret;
            while (!empty)
            {
                ret ~= front;
                popFront;
            }
            return ret;
        }

        /** Implements the empty range primitive.
        *
        * If there's no more documents left in the stream, this will be true.
        *
        * Returns: `true` if no more documents left, `false` otherwise.
        */
        bool empty() @safe
        {
            // currentNode and done_ are both invalid until popFront is called once
            if (!rangeInitialized)
            {
                popFront();
            }
            return done_;
        }
        /** Implements the popFront range primitive.
        *
        * Reads the next document from the stream, if possible.
        */
        void popFront() @safe
        {
            // Composer initialization is done here in case the constructor is
            // modified, which is a pretty common case.
            if (!rangeInitialized)
            {
                rangeInitialized = true;
            }
            assert(!done_, "Loader.popFront called on empty range");
            if (composer_.checkNode())
            {
                currentNode = composer_.getNode();
            }
            else
            {
                done_ = true;
            }
        }
        /** Implements the front range primitive.
        *
        * Returns: the current document as a YamlAlgebraic.
        */
        YamlAlgebraic front() @safe
        {
            // currentNode and done_ are both invalid until popFront is called once
            if (!rangeInitialized)
            {
                popFront();
            }
            return currentNode;
        }

        // Parse and return all events. Used for debugging.
        auto parse() @trusted
        {
            import mir.array.allocation: array;
            return array(&composer_.parser_);
        }
}
/// Load single YAML document from a file:
@safe unittest
{
    write("example.yaml", "Hello world!");
    auto rootNode = Loader.fromFile("example.yaml").load();
    assert(rootNode == "Hello world!");
}
/// Load all YAML documents from a file:
@safe unittest
{
    import mir.array.allocation : array;
    import std.file : write;
    write("example.yaml",
        "---\n"~
        "Hello world!\n"~
        "...\n"~
        "---\n"~
        "Hello world 2!\n"~
        "...\n"
    );
    auto nodes = Loader.fromFile("example.yaml").loadAll;
    assert(nodes.length == 2);
}
/// Iterate over YAML documents in a file, lazily loading them:
@safe unittest
{
    import std.file : write;
    write("example.yaml",
        "---\n"~
        "Hello world!\n"~
        "...\n"~
        "---\n"~
        "Hello world 2!\n"~
        "...\n"
    );
    auto loader = Loader.fromFile("example.yaml").loadAll;
}
/// Load YAML from a string:
@safe unittest
{
    string yaml_input = ("red:   '#ff0000'\n" ~
                        "green: '#00ff00'\n" ~
                        "blue:  '#0000ff'");

    auto colors = Loader.fromString(yaml_input).load();

    foreach(pair; colors.get!"object".pairs) with(pair)
    {
        // Do something with the color key and its value...
    }
}

/// Load a file into a buffer in memory and then load YAML from that buffer:
@safe unittest
{
    import std.file : read, write;
    import std.stdio : writeln;
    // Create a yaml document
    write("example.yaml",
        "---\n"~
        "Hello world!\n"~
        "...\n"~
        "---\n"~
        "Hello world 2!\n"~
        "...\n"
    );
    try
    {
        string buffer = readText("example.yaml");
        auto yamlNode = Loader.fromString(buffer);

        // Read data from yamlNode here...
    }
    catch(FileException e)
    {
        writeln("Failed to read file 'example.yaml'");
    }
}
/// Use a custom resolver to support custom data types and/or implicit tags:
@safe unittest
{
    import std.file : write;
    // Create a yaml document
    write("example.yaml",
        "---\n"~
        "Hello world!\n"~
        "...\n"
    );

    auto loader = Loader.fromFile("example.yaml");

    // Add resolver expressions here...
    // loader.resolver.addImplicitResolver(...);

    auto rootNode = loader.load();
}

//Issue #258 - https://github.com/dlang-community/D-YAML/issues/258
@safe unittest
{
    auto yaml = "{\n\"root\": {\n\t\"key\": \"value\"\n    }\n}";
    auto doc = Loader.fromString(yaml).load();
    assert(doc._is!YamlMap);
}

@safe unittest
{
    import mir.test;
    import std.exception : collectException;

    auto yaml = q"EOS
    value: invalid: string
EOS";
    auto filename = "invalid.yml";

    YamlAlgebraic unused;
    auto e = Loader.fromString(yaml, filename).load().collectException!ScannerException(unused);
    e.msg.should == `Mapping values are not allowed here
invalid.yml(1,19)`;
}
