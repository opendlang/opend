/++
$(H4 High level Ion deserialization API)

Macros:
IONREF = $(REF_ALTTEXT $(TT $2), $2, mir, ion, $1)$(NBSP)
+/
module mir.deser.ion;

private alias AliasSeq(T...) = T;

/++
+/
template deserializeIon(T, bool annotated = false)
{
@safe:
    import mir.ion.value: IonDescribedValue, IonAnnotations;

    static if (annotated)
        alias OptIonAnnotations = IonAnnotations;
    else
        alias OptIonAnnotations = AliasSeq!();

    /++
    +/
    T deserializeIon()(scope const char[][] symbolTable, scope IonDescribedValue ionValue, OptIonAnnotations optionalAnnotations)
    {
        T value;
        deserializeIon(value, symbolTable, ionValue, optionalAnnotations);
        return value;
    }

    /// ditto
    void deserializeIon()(
        scope ref T value, scope const char[][] symbolTable,
        scope IonDescribedValue ionValue,
        OptIonAnnotations optionalAnnotations)
    {
        import mir.appender: scopedBuffer;
        import mir.deser: hasDeserializeFromIon, deserializeValue, DeserializationParams, TableKind;
        import mir.serde: serdeGetDeserializationKeysRecurse, SerdeException;
        import mir.string_table: createTable;

        static if (hasDeserializeFromIon!T)
            enum keys = string[].init;
        else
            enum keys = serdeGetDeserializationKeysRecurse!T;

        alias createTableChar = createTable!char;
        static immutable table = createTableChar!(keys, false);

        auto tableMapBuffer = scopedBuffer!(uint, 1024);
        foreach (key; symbolTable)
        {
            uint id;
            if (!table.get(key, id))
                id = uint.max;
            tableMapBuffer.put(id);
        }
        alias DP = DeserializationParams!(TableKind.scopeRuntime, annotated);
        DP params = (()@trusted => DP(optionalAnnotations, symbolTable, tableMapBuffer.data))();
        if (auto exception = deserializeValue!keys(ionValue, params, value))
            throw exception;
    }

    /// ditto
    // the same code with GC allocated symbol table
    T deserializeIon(const string[] symbolTable, scope IonDescribedValue ionValue, OptIonAnnotations optionalAnnotations)
    {
        T value;
        deserializeIon(value, symbolTable, ionValue, optionalAnnotations);
        return value;
    }

    /// ditto
    void deserializeIon()(scope ref T value, const string[] symbolTable, scope IonDescribedValue ionValue, OptIonAnnotations optionalAnnotations)
    {
        import mir.appender: scopedBuffer;
        import mir.deser: hasDeserializeFromIon, deserializeValue, DeserializationParams, TableKind;
        import mir.serde: serdeGetDeserializationKeysRecurse, SerdeException;
        import mir.string_table: MirStringTable;

        static if (hasDeserializeFromIon!T)
            static immutable keys = string[].init;
        else
            static immutable keys = serdeGetDeserializationKeysRecurse!T;

        alias Table = MirStringTable!(keys.length, keys.length ? keys[$ - 1].length : 0);

        static if (keys.length)
            static immutable table = Table(keys[0 .. keys.length]);
        else
            static immutable table = Table.init;

        auto tableMapBuffer = scopedBuffer!(uint, 1024);

        foreach (key; symbolTable)
        {
            uint id;
            if (!table.get(key, id))
                id = uint.max;
            tableMapBuffer.put(id);
        }

        alias DP = DeserializationParams!(TableKind.immutableRuntime, annotated);
        DP params = (()@trusted => DP(optionalAnnotations, symbolTable, tableMapBuffer.data))();
        if (auto exception = deserializeValue!keys(ionValue, params, value))
            throw exception;            
    }

    static if (!annotated)
    {
        /++
        +/
        T deserializeIon()(scope const(ubyte)[] data)
        {
            T value;
            deserializeIon(value, data);
            return value;
        }

        /// ditto
        void deserializeIon()(scope ref T value, scope const(ubyte)[] data)
        {
            import mir.ion.stream: IonValueStream;
            import mir.ion.exception: IonErrorCode, ionException;

            foreach (symbolTable, scope ionValue; data.IonValueStream)
            {
                return .deserializeIon!T(value, symbolTable, ionValue);
            }

            throw IonErrorCode.emptyIonInput.ionException;
        }
    }
}

version(mir_ion_test)
unittest
{
    alias d = deserializeIon!(int[string]);
    import mir.ion.value;
    enum EEE { a, b }
    alias deserNull = deserializeIon!EEE;
}
