/++
DRAFT

Then CSV should have the following options to be converted to Ion:
 - matrix
 - an array of records with inner keys in the first raw
 - a record of arrays with outer keys in the first column
 - a record of records with inner keys in the first raw and outer keys in the first column

These four kinds of conversion kinds allow converting CSV to Ion on the fly.

Also, a simple transposition with full memory allocation will allow other four conversions:
 - transposed matrix
 - an array of records with inner keys in the first column
 - a record of arrays with outer keys in the first raw
 - a record of records with inner keys in the first column and outer keys in the first raw
+/
module mir.csv;

/++
+/
struct Csv
{
    ///
    const(char)[] text;
    ///
    bool header = false;
    ///
    bool columnIndex = false;
    ///
    bool stripUnquoted = true; 
    ///
    char sep = ',';
    ///
    char comment = '#';

    void serialize(S)(scope ref S serializer) scope const
    {
        // DRAFT
        // TODO: have to be @nogc
        // TODO: support only matrix for now, have to support all
        assert(!header, "not implemented");
        assert(!columnIndex, "not implemented");
        import std.string;
        import std.algorithm.iteration: splitter;
        import std.algorithm.searching: canFind;
        import std.ascii;
        auto rawState = serializer.listBegin;
        foreach (line; text.splitLines)
        {
            if (line.length && line[0] == comment)
                continue;
            auto state = serializer.listBegin;
            foreach (value; splitter(line, sep))
            {
                if (stripUnquoted)
                    value = value.strip;
                if (value.length == 0)
                {
                    serializer.putValue(null);
                    continue;
                }
                // TODO Timestamp

                import mir.bignum.decimal: Decimal, DecimalExponentKey;
                import mir.utility: _expect;

                Decimal!128 decimal = void;
                DecimalExponentKey key;
                if (decimal.fromStringImpl(value, key))
                {
                    if (key)
                        serializer.putValue(decimal);
                    else
                        serializer.putValue(decimal.coefficient);
                    continue;
                }
                if (value.canFind('"'))
                    value = value.strip;
                // TODO unqote
                serializer.putValue(value);
            }
            serializer.listEnd(state);

        }
        serializer.listEnd(rawState);
    }
}

/++
+/
struct TranposedCsv
{
    ///
    Csv csv;

    ///
    void serialize(S)(scope ref S serializer) scope const
    {
        import mir.algebraic_alias.csv: CsvAlgebraic;
        import mir.ndslice.slice: Slice;
        import mir.rc.array: RCI;
        import mir.ion.conv: serde;
        import mir.ser: serializeValue;

        alias CsvMatrix = Slice!(RCI!CsvAlgebraic, 2);
        auto matrix = csv.serde!CsvMatrix;
        auto scopeMatrix = matrix.lightScope;
        serializer.serializeValue(scopeMatrix);
    }
}

/// Matrix
unittest
{
    import mir.ndslice.slice: Slice;
    import mir.ion.conv: serde;

    auto text = "1,2\n3,4";
    auto matrix = text.Csv.serde!(Slice!(int*, 2));
    assert(matrix == [[1, 2], [3, 4]]);

    matrix = text.Csv.TranposedCsv.serde!(Slice!(int*, 2));
    assert(matrix == [[1, 3], [2, 4]]);
}

/++
With header
+/
unittest
{
    // TODO
}

/++
With column index
+/
unittest
{
    // TODO
}

/++
With header and column index
+/
unittest
{
    // TODO
}
