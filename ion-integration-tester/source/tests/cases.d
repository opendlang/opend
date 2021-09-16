module tests.cases;
import tests.data;
import mir.ion.ser.text;
import mir.ion.stream;
import mir.ion.conv;


struct IonTestCase {
    string name;
    string directory;
    bool expectedFail;
    IonDataType wantedData;
}

@IonTestCase("Known-good Ion data", ION_GOOD_TEST_DATA, false, IonDataType.all)
@IonTestCase("Known-good Ion typecodes", ION_GOOD_TYPECODES_TEST_DATA, false, IonDataType.all)
@IonTestCase("Known-good Ion timestamps", ION_GOOD_TIMESTAMP_TEST_DATA, false, IonDataType.all)
@IonTestCase("Known-bad Ion data", ION_BAD_TEST_DATA, true, IonDataType.all)
@IonTestCase("Known-bad Ion typecodes", ION_BAD_TYPECODES_TEST_DATA, true, IonDataType.all)
@IonTestCase("Known-bad Ion timestamps", ION_BAD_TIMESTAMP_TEST_DATA, true, IonDataType.all)
void testBasicData(Test test) {
    if (test.type == IonDataType.binary) {
        auto v = test.data.IonValueStream.serializeText;
    } else {
        const(char)[] text = cast(const(char)[])test.data;
        auto v = text.text2ion.IonValueStream.serializeText;
    }
}

@IonTestCase("Binary round-trip testing", ION_GOOD_TEST_DATA, false, IonDataType.binary)
void testBinaryRoundTrip(Test test) {
    IonValueStream input = test.data.IonValueStream;
    const(char)[] text = input.serializeText;
    const(char)[] roundtrip = text.text2ion.IonValueStream.serializeText;
    assert(text == roundtrip);
}

@IonTestCase("Text round-trip testing", ION_GOOD_TEST_DATA, false, IonDataType.text)
void testTextRoundTrip(Test test) {
    const(char)[] text = cast(const(char)[])test.data;
    const(char)[] input = text.text2ion.IonValueStream.serializeText;
    const(char)[] roundTrip = input.serializeText.text2ion.IonValueStream.serializeText;
    assert(input == roundTrip);
}

@IonTestCase("Equivalence testing", ION_EQUIVS_TEST_DATA, false, IonDataType.all)
void testEquivs(Test test) {
    import mir.ion.type_code;
    import mir.ion.value;
    IonValueStream input;
    if (test.type == IonDataType.binary) {
        input = test.data.IonValueStream.serializeText.text2ion.IonValueStream;
    } else {
        const(char)[] text = cast(const(char)[])test.data;
        input = text.text2ion.IonValueStream;
    }

    foreach(const(char[])[] symbolTable, IonDescribedValue ionValue; input) {
        if (ionValue.descriptor.type == IonTypeCode.sexp) {
            IonSexp sexp = ionValue.get!(IonSexp);
            IonDescribedValue first;
            int i = 0;
            foreach(IonDescribedValue value; sexp) {
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
            foreach(IonDescribedValue value; list) {
                if (i++ == 0) {
                    first = value;
                } else {
                    assert(value == first);
                }
            }
        }
    }
}

@IonTestCase("Non-equivalence testing", ION_EQUIVS_TEST_DATA, false, IonDataType.all)
void testNonEquivs(Test test) {
    import mir.ion.type_code;
    import mir.ion.value;
    IonValueStream input;
    if (test.type == IonDataType.binary) {
        input = test.data.IonValueStream.serializeText.text2ion.IonValueStream;
    } else {
        const(char)[] text = cast(const(char)[])test.data;
        input = text.text2ion.IonValueStream;
    }

    foreach(const(char[])[] symbolTable, IonDescribedValue ionValue; input) {
        if (ionValue.descriptor.type == IonTypeCode.sexp) {
            IonSexp sexp = ionValue.get!(IonSexp);
            IonDescribedValue first;
            int i = 0;
            foreach(IonDescribedValue value; sexp) {
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
            foreach(IonDescribedValue value; list) {
                if (i++ == 0) {
                    first = value;
                } else {
                    assert(value != first);
                }
            }
        }
    }
}