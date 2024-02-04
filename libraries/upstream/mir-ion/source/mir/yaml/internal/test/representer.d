
//          Copyright Ferdinand Majerech 2011.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)

module mir.yaml.internal.test.representer;

@safe unittest
{
    import std.array : appender, array;
    import std.meta : AliasSeq;
    import std.path : baseName, stripExtension;

    import mir.yaml.internal : dumper, Loader, YamlAlgebraic;
    import mir.yaml.internal.test.common : assertNodesEqual, run;
    import mir.yaml.internal.test.constructor : expected;

    /**
    Representer unittest. Dumps nodes, then loads them again.

    Params:
        baseName = Nodes in mir.yaml.internal.test.constructor.expected for roundtripping.
    */
    static void testRepresenterTypes(string baseName) @safe
    {
        assert((baseName in expected) !is null, "Unimplemented representer test: " ~ baseName);

        YamlAlgebraic[] expectedNodes = expected[baseName];
        auto emitStream = appender!string;
        auto dumper = dumper();
        dumper.dump(emitStream, expectedNodes);

        immutable output = emitStream.data;

        auto loader = Loader(emitStream.data, "TEST");
        const readNodes = loader.loadAll;

        assert(expectedNodes.length == readNodes.length);
        foreach (n; 0 .. expectedNodes.length)
        {
            assertNodesEqual(expectedNodes[n], readNodes[n]);
        }
    }
    foreach (key, _; expected)
    {
        testRepresenterTypes(key);
    }
}
