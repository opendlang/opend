/++
+/
module mir.ion.stream;

import mir.ion.exception;
import mir.ion.type_code;
import mir.ion.value;
import mir.utility: _expect;

/++
Ion Value Stream

Note: this implementation of value stream doesn't support shared symbol tables.
+/
struct IonValueStream
{
    /// data view.
    const(ubyte)[] data;

    private alias DG = int delegate(IonErrorCode error, const(char[])[] symbolTable, IonDescribedValue value) @safe pure nothrow @nogc;
    private alias EDG = int delegate(const(char[])[] symbolTable, IonDescribedValue value) @safe pure @nogc;

const:

    //
    void toString(W)(scope ref W w) scope
    {
        import mir.ion.ser.json: serializeJson;
        return serializeJson(w, this);
    }

    version (D_Exceptions)
    {
        /++
        +/
        @safe pure @nogc
        int opApply(scope int delegate(const(char[])[] symbolTable, IonDescribedValue value) @safe pure @nogc dg)
        {
            return opApply((IonErrorCode error, const(char[])[] symbolTable, IonDescribedValue value) {
                if (_expect(error, false))
                    throw error.ionException;
                return dg(symbolTable, value);
            });
        }

        /// ditto
        @trusted @nogc
        int opApply(scope int delegate(const(char[])[] symbolTable, IonDescribedValue value)
        @safe @nogc dg) { return opApply(cast(EDG) dg); }

        /// ditto
        @trusted pure
        int opApply(scope int delegate(const(char[])[] symbolTable, IonDescribedValue value)
        @safe pure dg) { return opApply(cast(EDG) dg); }

        /// ditto
        @trusted
        int opApply(scope int delegate(const(char[])[] symbolTable, IonDescribedValue value)
        @safe dg) { return opApply(cast(EDG) dg); }

        /// ditto
        @system pure @nogc
        int opApply(scope int delegate(const(char[])[] symbolTable, IonDescribedValue value)
        @system pure @nogc dg) { return opApply(cast(EDG) dg); }

        /// ditto
        @system @nogc
        int opApply(scope int delegate(const(char[])[] symbolTable, IonDescribedValue value)
        @system @nogc dg) { return opApply(cast(EDG) dg); }

        /// ditto
        @system pure
        int opApply(scope int delegate(const(char[])[] symbolTable, IonDescribedValue value)
        @system pure dg) { return opApply(cast(EDG) dg); }

        /// ditto
        @system
        int opApply(scope int delegate(const(char[])[] symbolTable, IonDescribedValue value)
        @system dg) { return opApply(cast(EDG) dg); }
    }

    /++
    +/
    @safe pure nothrow @nogc
    int opApply(scope int delegate(IonErrorCode error, const(char[])[] symbolTable, IonDescribedValue value) @safe pure nothrow @nogc dg)
    {
        import mir.appender: ScopedBuffer;
        import mir.ion.symbol_table;

        ScopedBuffer!(const(char)[]) symbolTableBuffer;
        const(ubyte)[] d = data;

        void resetSymbolTable()
        {
            symbolTableBuffer.reset;
            symbolTableBuffer.put(IonSystemSymbolTable_v1);
        }

        while (d.length)
        {
            import std.stdio;
            IonErrorCode error;
            IonVersionMarker versionMarker;
            IonDescribedValue describedValue;
            error = d.parseVersion(versionMarker);
            if (!error)
            {
                if (versionMarker != IonVersionMarker(1, 0))
                {
                    error = IonErrorCode.unexpectedVersionMarker;
                    goto C;
                }
                resetSymbolTable();
            }
            error = d.parseValue(describedValue);
            // check if describedValue is symbol table
            if (describedValue.descriptor.type == IonTypeCode.annotations)
            {
                auto annotationWrapper = describedValue.trustedGet!IonAnnotationWrapper;
                IonAnnotations annotations;
                IonDescribedValue symbolTableValue;
                error = annotationWrapper.unwrap(annotations, symbolTableValue);
                if (!error && !annotations.empty)
                {
                    // check first annotation is $ion_symbol_table
                    {
                        bool nextAnnotation;
                        foreach (IonErrorCode annotationError, size_t annotationId; annotations)
                        {
                            error = annotationError;
                            if (error)
                                goto C;
                            if (nextAnnotation)
                                continue;
                            nextAnnotation = true;
                            if (annotationId != IonSystemSymbol.ion_symbol_table)
                                goto C;
                        }
                    }
                    IonStruct symbolTableStruct;
                    if (symbolTableValue.descriptor.type != IonTypeCode.struct_)
                    {
                        error = IonErrorCode.expectedStructValue;
                        goto C;
                    }
                    if (symbolTableValue != null)
                    {
                        symbolTableStruct = symbolTableValue.trustedGet!IonStruct;
                    }

                    {
                        bool preserveCurrentSymbols;
                        IonList symbols;

                        foreach (IonErrorCode symbolTableError, size_t symbolTableKeyId, IonDescribedValue elementValue; symbolTableStruct)
                        {
                            error = symbolTableError;
                            if (error)
                                goto C;
                            switch (symbolTableKeyId)
                            {
                                case IonSystemSymbol.imports:
                                {
                                    if (preserveCurrentSymbols || (elementValue.descriptor.type != IonTypeCode.symbol && elementValue.descriptor.type != IonTypeCode.list))
                                    {
                                        error = IonErrorCode.invalidLocalSymbolTable;
                                        goto C;
                                    }
                                    if (elementValue.descriptor.type == IonTypeCode.list)
                                    {
                                        error = IonErrorCode.sharedSymbolTablesAreUnsupported;
                                        goto C;
                                    }
                                    size_t id;
                                    error = elementValue.trustedGet!IonSymbolID.get(id);
                                    if (error)
                                        goto C;
                                    if (id != IonSystemSymbol.ion_symbol_table)
                                    {
                                        error = IonErrorCode.invalidLocalSymbolTable;
                                        goto C;
                                    }
                                    preserveCurrentSymbols = true;
                                    break;
                                }
                                case IonSystemSymbol.symbols:
                                {
                                    if (symbols != symbols.init || elementValue.descriptor.type != IonTypeCode.list)
                                    {
                                        error = IonErrorCode.invalidLocalSymbolTable;
                                        goto C;
                                    }
                                    if (elementValue != null)
                                    {
                                        symbols = elementValue.trustedGet!IonList;
                                    }
                                    if (error)
                                        goto C;
                                    break;
                                }
                                default:
                                {
                                    //CHECK: should other symbols be ignored?
                                    continue;
                                }
                            }
                        }

                        if (!preserveCurrentSymbols)
                        {
                            resetSymbolTable();
                        }

                        foreach (IonErrorCode symbolsError, IonDescribedValue symbolValue; symbols)
                        {
                            error = symbolsError;
                            if (error)
                                goto C;
                            const(char)[] symbol;
                            error = symbolValue.get(symbol);
                            if (error)
                                goto C;
                            symbolTableBuffer.put(symbol);
                        }
                        continue;
                    }
                }
                // TODO: continue work
            }
        C:
            if (auto ret = dg(error, symbolTableBuffer.data, describedValue))
                return ret;
        }
        return 0;
    }

    /// ditto
    @trusted nothrow @nogc
    int opApply(scope int delegate(IonErrorCode error, const(char[])[] symbolTable, IonDescribedValue value)
    @safe nothrow @nogc dg) { return opApply(cast(DG) dg); }

    /// ditto
    @trusted pure @nogc
    int opApply(scope int delegate(IonErrorCode error, const(char[])[] symbolTable, IonDescribedValue value)
    @safe pure @nogc dg) { return opApply(cast(DG) dg); }

    /// ditto
    @trusted pure nothrow
    int opApply(scope int delegate(IonErrorCode error, const(char[])[] symbolTable, IonDescribedValue value)
    @safe pure nothrow dg) { return opApply(cast(DG) dg); }

    /// ditto
    @trusted @nogc
    int opApply(scope int delegate(IonErrorCode error, const(char[])[] symbolTable, IonDescribedValue value)
    @safe @nogc dg) { return opApply(cast(DG) dg); }

    /// ditto
    @trusted pure
    int opApply(scope int delegate(IonErrorCode error, const(char[])[] symbolTable, IonDescribedValue value)
    @safe pure dg) { return opApply(cast(DG) dg); }

    /// ditto
    @trusted nothrow
    int opApply(scope int delegate(IonErrorCode error, const(char[])[] symbolTable, IonDescribedValue value)
    @safe nothrow dg) { return opApply(cast(DG) dg); }

    /// ditto
    @trusted
    int opApply(scope int delegate(IonErrorCode error, const(char[])[] symbolTable, IonDescribedValue value)
    @safe dg) { return opApply(cast(DG) dg); }

    /// ditto
    @system pure nothrow @nogc
    int opApply(scope int delegate(IonErrorCode error, const(char[])[] symbolTable, IonDescribedValue value)
    @system pure nothrow @nogc dg) { return opApply(cast(DG) dg); }

    /// ditto
    @system nothrow @nogc
    int opApply(scope int delegate(IonErrorCode error, const(char[])[] symbolTable, IonDescribedValue value)
    @system nothrow @nogc dg) { return opApply(cast(DG) dg); }

    /// ditto
    @system pure @nogc
    int opApply(scope int delegate(IonErrorCode error, const(char[])[] symbolTable, IonDescribedValue value)
    @system pure @nogc dg) { return opApply(cast(DG) dg); }

    /// ditto
    @system pure nothrow
    int opApply(scope int delegate(IonErrorCode error, const(char[])[] symbolTable, IonDescribedValue value)
    @system pure nothrow dg) { return opApply(cast(DG) dg); }

    /// ditto
    @system @nogc
    int opApply(scope int delegate(IonErrorCode error, const(char[])[] symbolTable, IonDescribedValue value)
    @system @nogc dg) { return opApply(cast(DG) dg); }

    /// ditto
    @system pure
    int opApply(scope int delegate(IonErrorCode error, const(char[])[] symbolTable, IonDescribedValue value)
    @system pure dg) { return opApply(cast(DG) dg); }

    /// ditto
    @system nothrow
    int opApply(scope int delegate(IonErrorCode error, const(char[])[] symbolTable, IonDescribedValue value)
    @system nothrow dg) { return opApply(cast(DG) dg); }

    /// ditto
    @system
    int opApply(scope int delegate(IonErrorCode error, const(char[])[] symbolTable, IonDescribedValue value)
    @system dg) { return opApply(cast(DG) dg); }

    /++
    Params:
        serializer = serializer
    +/
    void serialize(S)(ref S serializer) const
    {
        bool following;
        foreach (symbolTable, value; this)
        {
            if (following)
                serializer.nextTopLevelValue;
            following = true;
            static if (__traits(hasMember, serializer, "putKeyId"))
            {
                alias unwrappedSerializer = serializer;
            }
            else
            {
                import mir.ion.ser.unwrap_ids;
                auto unwrappedSerializer = unwrapSymbolIds(serializer, symbolTable);
            }
            value.serialize(unwrappedSerializer);
        }
    }

    ///
    @safe pure
    unittest
    {
        import mir.ion.ser.json;
        const ubyte[] data = [0xe0, 0x01, 0x00, 0xea, 0xe9, 0x81, 0x83, 0xd6, 0x87, 0xb4, 0x81, 0x61, 0x81, 0x62, 0xd6, 0x8a, 0x21, 0x01, 0x8b, 0x21, 0x02];
        auto json = IonValueStream(data).serializeJson;
        assert(json == `{"a":1,"b":2}`);
    }
}
