
//          Copyright Ferdinand Majerech 2011.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)

module mir.yaml.internal.test.compare;

@safe unittest
{
    import mir.yaml.internal : Loader;
    import mir.yaml.internal.test.common : assertNodesEqual, compareEvents, run;

    /**
    Test parser by comparing output from parsing two equivalent YAML files.

    Params:
        dataFilename = YAML file to parse.
        canonicalFilename = Another file to parse, in canonical YAML format.
    */
    static void testParser(string dataFilename, string canonicalFilename) @safe
    {
        auto dataEvents = Loader.fromFile(dataFilename).parse();
        auto canonicalEvents = Loader.fromFile(canonicalFilename).parse();

        //BUG: the return value isn't checked! This test currently fails...
        compareEvents(dataEvents, canonicalEvents);
    }

    /**
    Test loader by comparing output from loading two equivalent YAML files.

    Params:
        dataFilename = YAML file to load.
        canonicalFilename = Another file to load, in canonical YAML format.
    */
    static void testLoader(string dataFilename, string canonicalFilename) @safe
    {
        import mir.array.allocation : array;
        auto data = Loader.fromFile(dataFilename).loadAll;
        auto canonical = Loader.fromFile(canonicalFilename).loadAll;

        assert(data.length == canonical.length, "Unequal node count");
        foreach (n; 0 .. data.length)
        {
            assertNodesEqual(data[n], canonical[n]);
        }
    }
    run(&testParser, ["data", "canonical"]);
    run(&testLoader, ["data", "canonical"], ["test_loader_skip"]);
}
