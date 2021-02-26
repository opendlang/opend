module mir.ion.internal.stage4_s;

import mir.ion.exception: IonErrorCode;

///
IonErrorCode singleThreadJsonImpl(size_t nMax, SymbolTable, TapeHolder)(
    scope const(char)[] text,
    ref SymbolTable table,
    ref TapeHolder tapeHolder,
    )
    if (nMax % 64 == 0 && nMax)
{
    import mir.utility: min;
    import mir.ion.internal.stage3;
    import core.stdc.string: memcpy;

    enum k = nMax / 64;

    align(64) ubyte[64][k + 2] vector = void;
    if (__ctfe)
        foreach (ref v; vector)
            v[] = 0;
    ulong[2][k + 2] pairedMask1 = void;
    ulong[2][k + 2] pairedMask2 = void;

    bool backwardEscapeBit;

    vector[$ - 1] = ' ';
    pairedMask1[$ - 1] = [0UL,  0UL];
    pairedMask1[$ - 1] = [0UL,  ulong.max];

    return stage3(
        table,
        (ref Stage3Stage stage) @trusted
        {
            tapeHolder.extend(stage.tape.length + nMax * 4);
            if (stage.tape !is null)
            {
                assert(stage.n - stage.n < 64);
                vector[0] = vector[$ - 2];
                pairedMask1[0] = pairedMask1[$ - 2];
                pairedMask2[0] = pairedMask2[$ - 2];
                stage.index -= stage.n;
            }
            else
            {
                stage.strPtr = cast(const(ubyte)*)(vector.ptr.ptr + 64);
                stage.pairedMask1 = pairedMask1.ptr + 1;
                stage.pairedMask2 = pairedMask2.ptr + 1;
            }
            stage.tape = tapeHolder.data;
            stage.n = min(nMax, text.length);
            if (stage.n == 0)
                assert(0);

            vector[1 + stage.n / 64] = ' ';

            if (__ctfe)
                for (size_t i; i < stage.n; i += 64)
                    vector[i / 64 + 1][0 .. i + 64 <= stage.n ? $ : stage.n % 64] = cast(const(ubyte)[]) text[i .. i + 64 <= stage.n ? i + 64 : $];
            else
                memcpy(vector.ptr.ptr + 64, text.ptr, stage.n);

            text = text[stage.n .. $];

            auto vlen = stage.n / 64 + (stage.n % 64 != 0);
            import mir.ion.internal.stage1;
            import mir.ion.internal.stage2;
            stage1(vlen, vector.ptr + 1, pairedMask1.ptr + 1, backwardEscapeBit);
            stage2(vlen, vector.ptr + 1, pairedMask2.ptr + 1);
            return text.length == 0;
        },
        tapeHolder.currentTapePosition,
    );
}

///
version(mir_ion_test) unittest
{
    static ubyte[] jsonToIonTest(scope const(char)[] text)
    @trusted pure
    {
        import mir.ion.exception: ionException;
        import mir.ion.internal.data_holder;
        import mir.ion.symbol_table;

        enum nMax = 128u;

        IonSymbolTable!false table;
        table.initialize;
        auto tapeHolder = IonTapeHolder!(nMax * 4)(nMax * 4);

        if (auto error = singleThreadJsonImpl!nMax(text, table, tapeHolder))
            throw error.ionException;

        return tapeHolder.tapeData.dup;
    }

    import mir.ion.value;
    import mir.ion.type_code;

    assert(IonValue(jsonToIonTest("12345")).describe.get!IonUInt.get!ulong == 12345);
    assert(IonValue(jsonToIonTest("-12345")).describe.get!IonNInt.get!long == -12345);
    assert(IonValue(jsonToIonTest("-12.345")).describe.get!IonDecimal.get!double == -12.345);
    assert(IonValue(jsonToIonTest("\t \r\n-12345e-3 text_after_whitespaces \t\r\n")).describe.get!IonFloat.get!double == -12.345);
    assert(IonValue(jsonToIonTest(" -12345e-3 ")).describe.get!IonFloat.get!double == -12.345);
    assert(IonValue(jsonToIonTest("   null{text_after_operators:{},[]")).describe.get!IonNull == IonNull(IonTypeCode.null_));
    assert(IonValue(jsonToIonTest("true ")).describe.get!bool == true);
    assert(IonValue(jsonToIonTest("  false")).describe.get!bool == false);
    assert(IonValue(jsonToIonTest(` "string"{text_after_operators:{},[]`)).describe.get!(const(char)[]) == "string");

    enum str = "iwfpwqocbpwoewouivhqpeobvnqeon wlekdnfw;lefqoeifhq[woifhdq[owifhq[owiehfq[woiehf[  oiehwfoqwewefiqweopurefhqweoifhqweofihqeporifhq3eufh38hfoidf";
    auto data = jsonToIonTest(`"` ~ str ~ `"`);
    assert(IonValue(jsonToIonTest(`"` ~ str ~ `"`)).describe.get!(const(char)[]) == str);

    assert(IonValue(jsonToIonTest(`"hey \uD801\uDC37tee"`)).describe.get!(const(char)[]) == "hey 𐐷tee");
    assert(IonValue(jsonToIonTest(`[]`)).describe.get!IonList.data.length == 0);
    assert(IonValue(jsonToIonTest(`{}`)).describe.get!IonStruct.data.length == 0);

    assert(jsonToIonTest(" [ {}, true , \t\r\nfalse, null, \"string\", 12.3 ]") ==
        cast(ubyte[])"\xbe\x8e\xd0\x11\x10\x0f\x86\x73\x74\x72\x69\x6e\x67\x52\xc1\x7b");

    data = jsonToIonTest(` { "a": "b",  "key": ["array", {"a": "c" } ] } `);
    assert(data == cast(ubyte[])"\xde\x8f\x8a\x81b\x8b\xba\x85array\xd3\x8a\x81c");

    data = jsonToIonTest(
    `{
        "tags":[
            "russian",
            "novel",
            "19th century"
        ]
    }`);

}
