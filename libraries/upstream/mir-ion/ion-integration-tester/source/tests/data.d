// This file is licensed under the Boost License, with code adopted from Silly (https://gitlab.com/AntonMeep/silly),
// which is licensed under the ISC license:
// Copyright (c) 2019, Anton Fediushin
//
// Permission to use, copy, modify, and/or distribute this software for any
// purpose with or without fee is hereby granted, provided that the above
// copyright notice and this permission notice appear in all copies.
//
// THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
// WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
// MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
// ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
// WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
// ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
// OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.

module tests.data;
import tests.utils;
import std.path : buildPath;

__gshared string testDataLocation = "../ion-tests/iontestdata";

enum IonTestData {
    good,
    goodTypecodes,
    goodTimestamp,
    bad,
    badTypecodes,
    badTimestamp,
    equivs,
    nonequivs,
    roundtrip
};

// iontestdata/good
enum ION_GOOD_TEST_DATA = "good";
// iontestdata/good/typecodes
enum ION_GOOD_TYPECODES_TEST_DATA = buildPath(ION_GOOD_TEST_DATA, "typecodes");
// iontestdata/good/timestamp
enum ION_GOOD_TIMESTAMP_TEST_DATA = buildPath(ION_GOOD_TEST_DATA, "timestamp");
// iontestdata/bad
enum ION_BAD_TEST_DATA = "bad";
// iontestdata/bad/typecodes
enum ION_BAD_TYPECODES_TEST_DATA = buildPath(ION_BAD_TEST_DATA, "typecodes");
// iontestdata/bad/timestamp
enum ION_BAD_TIMESTAMP_TEST_DATA = buildPath(ION_BAD_TEST_DATA, "timestamp");
// iontestdata/good/equivs
enum ION_EQUIVS_TEST_DATA = buildPath(ION_GOOD_TEST_DATA, "equivs");
// iontestdata/good/non-equivs
enum ION_NONEQUIVS_TEST_DATA = buildPath(ION_GOOD_TEST_DATA, "non-equivs");
enum ION_ROUNDTRIP_TEST_DATA = "good";

static immutable const(char)[][] ION_TEST_DATA = [
    ION_GOOD_TEST_DATA,
    ION_GOOD_TYPECODES_TEST_DATA,
    ION_GOOD_TIMESTAMP_TEST_DATA,
    ION_BAD_TEST_DATA,
    ION_BAD_TYPECODES_TEST_DATA,
    ION_BAD_TIMESTAMP_TEST_DATA,
    ION_EQUIVS_TEST_DATA,
    ION_NONEQUIVS_TEST_DATA,
    ION_ROUNDTRIP_TEST_DATA
];

static immutable ION_GOOD_TEST_DATA_SKIP = [
    // upstream implementations can't parse these files, don't bother
    "good/subfieldVarUInt32bit.ion",
    "good/utf16.ion",
    "good/utf32.ion",
    "good/whitespace.ion",
    "good/item1.10n",
    "good/testfile26.ion",
    "good/localSymbolTableImportZeroMaxId.ion",
    // Shared symbol tables support is TBD
    "good/subfieldVarUInt.ion",
    "good/subfieldVarUInt15bit.ion",
    "good/testfile35.ion",
    "good/subfieldVarUInt16bit.ion",
    // We shouldn't have a IonValueStream that's fully empty in real data
    "good/empty.ion",
    "good/blank.ion",
    // Mir supports up to 1024 bytes big integers/decimal for coefficient.
    // This test requires 1201 bytes for coefficient.
    "good/intBigSize1201.10n",
];

static immutable ION_GOOD_TYPECODES_TEST_DATA_SKIP = [];

static immutable ION_GOOD_TIMESTAMP_TEST_DATA_SKIP = [];

static immutable ION_BAD_TEST_DATA_SKIP = [
    "bad/clobWithNullCharacter.ion"
];

static immutable ION_BAD_TYPECODES_TEST_DATA_SKIP = [
    "bad/typecodes/type_6_length_0.10n"
];

static immutable ION_BAD_TIMESTAMP_TEST_DATA_SKIP = [];

static immutable ION_EQUIVS_TEST_DATA_SKIP = [
    "good/equivs/clobNewlines.ion",
];

static immutable ION_NONEQUIVS_TEST_DATA_SKIP = [];

static immutable ION_ROUNDTRIP_TEST_DATA_SKIP = ION_GOOD_TEST_DATA_SKIP ~ [
    "good/testfile37.ion",
    "good/testfile23.ion",
];

static immutable const(char)[][][] ION_TEST_DATA_SKIP = [
    ION_GOOD_TEST_DATA_SKIP,
    ION_GOOD_TYPECODES_TEST_DATA_SKIP,
    ION_GOOD_TIMESTAMP_TEST_DATA_SKIP,
    ION_BAD_TEST_DATA_SKIP,
    ION_BAD_TYPECODES_TEST_DATA_SKIP,
    ION_BAD_TIMESTAMP_TEST_DATA_SKIP,
    ION_EQUIVS_TEST_DATA_SKIP,
    ION_NONEQUIVS_TEST_DATA_SKIP,
    ION_ROUNDTRIP_TEST_DATA_SKIP,
];

bool isSkippedFile(IonTestData testData, string path) {
    import std.algorithm.searching : any, canFind;
    return ION_TEST_DATA_SKIP[testData].any!(e => path.canFind(e));
}

enum IonDataType {
    binary,
    text,
    all
};

struct Test {
    string filePath;
    string name;
    bool verbose;
    bool expectedFail;
    IonDataType type;
    ubyte[] data;

    void run(alias m)(out TestResult result, bool failFast, bool verbose) {
        result.test = this;
        this.verbose = verbose;

        try {
            m(this);

            if (!expectedFail) {
                result.passed = true;
            }
        } catch (Throwable t) {
            if (expectedFail) {
                result.passed = true;
            }

            import core.exception : AssertError;
            foreach(th; t) {
                Thrown thrown;

                foreach(exc; th.info) {
                    thrown.info ~= exc.idup;
                }
                thrown.type = typeid(th).name;
                thrown.file = th.file;
                thrown.message = th.message.idup;
                thrown.line = th.line;

                result.thrown ~= thrown; 
            }

            if (!(cast(Exception) t || cast(AssertError) t)) {
                throw t;
            } else if (failFast && !expectedFail) {
                throw t;
            }
        }
    }
}

struct Thrown {
	string type;
    string message;
	string file;
	size_t line;
	immutable(string)[] info;
}

struct TestResult {
    Test test;
    bool passed;
    immutable(Thrown)[] thrown;

    void print(bool failuresOnly = false, bool verbose = false) {
        import std.format : formattedWrite;
        import std.stdio : stdout;
        if (failuresOnly && passed)
            return;

        auto writer = stdout.lockingTextWriter;
        writer.formattedWrite("[%s] %s\n",
                passed ? "✓".okayText 
                       : "✗".failText,
                test.name.emphasizeText,
                test.filePath);

        // If this is an expected failure test case AND we want verbose messaging,
        // or if this is just a plain test case, then print it out
        if (test.expectedFail && !passed) {
            writer.formattedWrite("    expectedFail: Test did not throw when it was expected to.\n");
        }
        else if ((test.expectedFail && verbose) || (!test.expectedFail)) {
            foreach(th; thrown) {
                writer.formattedWrite("    %s: %s (file: %s:%d)\n", 
                        th.type,
                        th.message,
                        th.file,
                        th.line);

                if (verbose) { 
                    writer.formattedWrite("    ------ STACK TRACE -----\n");
                    foreach(line; th.info) {
                        writer.formattedWrite("    %s\n", line);
                    }
                }
            }
        }
    }
}

Test[] loadIonTestData(string root, IonTestData dataType, bool expectedFail, IonDataType wantedType) {
    import std.array : array, join;
    import std.file : read, dirEntries, SpanMode, DirEntry;
    import std.path : buildPath, relativePath, extension;
    string path = buildPath(root, ION_TEST_DATA[dataType]);
    Test[] testCases;
    string searchPattern = "*{.ion,.10n}";
    if (wantedType == IonDataType.binary)
        searchPattern = "*{.10n}";
    else if (wantedType == IonDataType.text)
        searchPattern = "*{.ion}";

    foreach (DirEntry e; dirEntries(path, searchPattern, SpanMode.shallow)) {
        if (dataType.isSkippedFile(e.name)) {
            continue;
        }

        Test testCase;
        testCase.filePath = e.name;
        testCase.name = relativePath(e.name, testDataLocation);
        testCase.data = cast(ubyte[])read(e.name);
        testCase.type = e.name.extension == ".10n" ? IonDataType.binary : IonDataType.text;
        testCase.expectedFail = expectedFail;

        testCases ~= testCase;
    }

    return testCases;
}