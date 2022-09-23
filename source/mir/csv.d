/++
DRAFT
+/
module mir.csv;

///
enum CsvKind
{
    ///
    matrix,
    ///
    transposedMatrix,
    ///
    objectOfColumns,
    ///
    indexedRaws,
    ///
    indexedObjects,
}

/++
+/
struct Csv
{
    ///
    const(char)[] text;
    ///
    CsvKind kind;
    ///
    bool stripUnquoted = true; 
    ///
    char separator = ',';
    ///
    char comment = '#';


    void serialize(S)(scope ref S serializer) scope const
    {
        // DRAFT
        // TODO: have to be @nogc
        // TODO: support only matrix for now, have to support all
        assert(kind == CsvKind.matrix, "not implemented");
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
            foreach (value; splitter(line, separator))
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

/// Matrix
unittest
{
    import mir.ndslice.slice: Slice;
    import mir.ion.conv: serde;

    auto text = "1,2\n3,4";
    auto matrix = text.Csv.serde!(Slice!(int*, 2));
    assert(matrix == [[1, 2], [3, 4]]);
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
