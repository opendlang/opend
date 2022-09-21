
//          Copyright Ferdinand Majerech 2011.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)

module mir.internal.yaml.test.reader;

@safe unittest
{
    import std.exception :assertThrown;

    import mir.internal.yaml.test.common : readData, run;
    import mir.internal.yaml.reader : Reader, ReaderException;

    /**
    Try reading entire file through Reader, expecting an error (the file is none).

    Params:  data    = Stream to read.
    */
    static void runReader(scope const(char)[] fileData) @safe
    {
        auto reader = Reader(fileData);
        while(reader.peek() != '\0') { reader.forward(); }
    }

    /**
    Stream error unittest. Tries to read none input files, expecting errors.

    Params:  errorFilename = File name to read from.
    */
    static void testStreamError(string errorFilename) @safe
    {
        import std.utf: UTFException;
        assertThrown!UTFException(runReader(readData(errorFilename)));
    }
    run(&testStreamError, ["stream-error"]);
}
