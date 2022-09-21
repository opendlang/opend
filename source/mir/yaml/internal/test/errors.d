
//          Copyright Ferdinand Majerech 2011-2014
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)

module mir.internal.yaml.test.errors;

@safe unittest
{
    import mir.array.allocation : array;
    import std.exception : assertThrown;

    import mir.internal.yaml : Loader;
    import mir.internal.yaml.test.common : run;

    /**
    Loader error unittest from file stream.

    Params:  errorFilename = File name to read from.
    */
    static void testLoaderError(string errorFilename) @safe
    {
        assertThrown(Loader.fromFile(errorFilename).loadAll,
            __FUNCTION__ ~ "(" ~ errorFilename ~ ") Expected an exception");
    }

    /**
    Loader error unittest from string.

    Params:  errorFilename = File name to read from.
    */
    static void testLoaderErrorString(string errorFilename) @safe
    {
        assertThrown(Loader.fromFile(errorFilename).loadAll,
            __FUNCTION__ ~ "(" ~ errorFilename ~ ") Expected an exception");
    }

    /**
    Loader error unittest from filename.

    Params:  errorFilename = File name to read from.
    */
    static void testLoaderErrorFilename(string errorFilename) @safe
    {
        assertThrown(Loader.fromFile(errorFilename).loadAll,
            __FUNCTION__ ~ "(" ~ errorFilename ~ ") Expected an exception");
    }

    /**
    Loader error unittest loading a single document from a file.

    Params:  errorFilename = File name to read from.
    */
    static void testLoaderErrorSingle(string errorFilename) @safe
    {
        assertThrown(Loader.fromFile(errorFilename).load(),
            __FUNCTION__ ~ "(" ~ errorFilename ~ ") Expected an exception");
    }
    run(&testLoaderError, ["loader-error"]);
    run(&testLoaderErrorString, ["loader-error"]);
    run(&testLoaderErrorFilename, ["loader-error"]);
    run(&testLoaderErrorSingle, ["single-loader-error"]);
}
