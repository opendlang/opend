module tests.cases;
import tests.data;
import mir.ser.text;
import mir.ion.stream;
import mir.ion.conv;

struct IonTestCase {
    string name;
    IonTestData data;
    bool expectedFail;
    IonDataType wantedData;
}

@IonTestCase("Known-good Ion data", IonTestData.good, false, IonDataType.all)
@IonTestCase("Known-good Ion typecodes", IonTestData.goodTypecodes, false, IonDataType.all)
@IonTestCase("Known-good Ion timestamps", IonTestData.goodTimestamp, false, IonDataType.all)
@IonTestCase("Known-bad Ion data", IonTestData.bad, true, IonDataType.all)
@IonTestCase("Known-bad Ion typecodes", IonTestData.badTypecodes, true, IonDataType.all)
@IonTestCase("Known-bad Ion timestamps", IonTestData.badTimestamp, true, IonDataType.all)
void testBasicData(Test test) {
    if (test.type == IonDataType.binary) {
        auto v = test.data.ion2text;
    } else {
        const(char)[] text = cast(const(char)[])test.data;
        auto v = text.text2ion.ion2text;
    }
}

@IonTestCase("Binary round-trip testing", IonTestData.roundtrip, false, IonDataType.binary)
void testBinaryRoundTrip(Test test) {
    const(char)[] text = test.data.ion2text;
    const(char)[] roundtrip = text.text2ion.ion2text;
    assert(text == roundtrip, "\nexcpected: " ~ text ~ "\n      got: " ~ roundtrip ~ "\n");
}

@IonTestCase("Text round-trip testing", IonTestData.roundtrip, false, IonDataType.text)
void testTextRoundTrip(Test test) {
    const(char)[] text = cast(const(char)[])test.data;
    auto input = text.text2ion.IonValueStream;
    if (test.verbose) {
        debug import std.stdio;
        debug writefln("ser: %s", input.serializeText);
    }
    auto roundTrip = input.serializeText.text2ion.IonValueStream;
    if (test.verbose) {
        if (input.serializeText != roundTrip.serializeText) {
            debug import std.stdio;
            debug writefln("input: %s", text);
            debug writefln("stage 1: %s", input.serializeText);
            debug writefln("stage 2: %s", roundTrip.serializeText);

            debug writefln("== DUMPING ION VALUE STREAM ==");
            foreach(symbolTable, ionValue; input) {
                debug writefln("%s", ionValue);
            }
            debug writefln("== DUMPING RT VALUE STREAM ==");
            foreach(symbolTable, ionValue; roundTrip) {
                debug writefln("%s", ionValue);
            }
        }
    }
    assert(input.serializeText == roundTrip.serializeText);
}

@IonTestCase("Equivalence testing", IonTestData.equivs, false, IonDataType.all)
void testEquivs(Test test) {
    import mir.ion.type_code;
    import mir.ion.value;
    IonValueStream input;
    if (test.type == IonDataType.binary) {
        input = test.data.ion2text.text2ion.IonValueStream;
    } else {
        const(char)[] text = cast(const(char)[])test.data;
        input = text.text2ion.IonValueStream;
    }

    foreach(const(char[])[] symbolTable, IonDescribedValue ionValue; input) {
        if (ionValue.descriptor.type == IonTypeCode.sexp) {
            IonSexp sexp = ionValue.get!(IonSexp);
            IonDescribedValue first;
            int i = 0;
            foreach(scope IonDescribedValue value; sexp) {
                if (i++ == 0) {
                    first = value;
                }
                else {
                    assert(first == value);
                }
            }
        }
        else if (ionValue.descriptor.type == IonTypeCode.struct_) {
            // TODO: fill these in when the text reader doesn't throw when trying to read
        }
        else if (ionValue.descriptor.type == IonTypeCode.list) {
            IonList list = ionValue.get!(IonList);
            IonDescribedValue first;
            int i = 0;
            foreach(scope IonDescribedValue value; list) {
                if (i++ == 0) {
                    first = value;
                } else {
                    assert(value == first);
                }
            }
        }
    }
}

@IonTestCase("Non-equivalence testing", IonTestData.nonequivs, false, IonDataType.all)
void testNonEquivs(Test test) {
    import mir.ion.type_code;
    import mir.ion.value;
    IonValueStream input;
    if (test.type == IonDataType.binary) {
        input = test.data.ion2text.text2ion.IonValueStream;
    } else {
        const(char)[] text = cast(const(char)[])test.data;
        input = text.text2ion.IonValueStream;
    }

    foreach(const(char[])[] symbolTable, IonDescribedValue ionValue; input) {
        if (ionValue.descriptor.type == IonTypeCode.sexp) {
            IonSexp sexp = ionValue.get!(IonSexp);
            IonDescribedValue first;
            int i = 0;
            foreach(scope IonDescribedValue value; sexp) {
                if (i++ == 0) {
                    first = value;
                }
                else {
                    assert(value != first);
                }
            }
        }
        else if (ionValue.descriptor.type == IonTypeCode.struct_) {
            // TODO: fill these in when the text reader doesn't throw when trying to read
        }
        else if (ionValue.descriptor.type == IonTypeCode.list) {
            IonList list = ionValue.get!(IonList);
            IonDescribedValue first;
            int i = 0;
            foreach(scope IonDescribedValue value; list) {
                if (i++ == 0) {
                    first = value;
                } else {
                    assert(value != first, );
                }
            }
        }
    }
}