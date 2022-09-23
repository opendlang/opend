/++
DRAFT
+/
module mir.csv;

/++
CSV representation kind.
+/
enum CsvKind
{
    /++
    Array of rows.
    +/
    matrix,
    /++
    Arrays of objects with object field names from the header.
    +/
    objects,
    /++
    Indexed array of rows with index from the first column.
    +/
    indexedRows,
    /++
    Indexed arrays of objects with index from the first column and object field names from the header.
    +/
    indexedObjects,
    /++
    Array of columns.
    +/
    transposedMatrix,
    /++
    Object of columns with object field names from the header.
    +/
    objectOfColumns,
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
    ///
    ubyte rowsToSkip;
    /// File name for berrer error messages
    string fileName = "<unknown>";


    void serialize(S)(scope ref S serializer) scope const
    {
        // DRAFT
        // TODO: have to be @nogc
        // TODO: support only matrix for now, have to support all
        assert(kind == CsvKind.matrix, "not implemented");

        import mir.algebraic_alias.csv: CsvAlgebraic;
        import mir.appender: scopedBuffer;
        import mir.bignum.decimal: Decimal, DecimalExponentKey;
        import mir.exception: MirException;
        import mir.ndslice.dynamic: transposed;
        import mir.ndslice.slice: sliced;
        import mir.parse: ParsePosition;
        import mir.ser: serializeValue;
        import mir.timestamp: Timestamp;
        import std.algorithm.iteration: splitter;
        import std.algorithm.searching: canFind;
        // import std.ascii;
        import std.string: lineSplitter, strip;

        auto headerBuff = scopedBuffer!(const(char)[]);
        auto unquotedStringBuff = scopedBuffer!(const(char));
        auto indexBuff = scopedBuffer!CsvAlgebraic;
        auto dataBuff = scopedBuffer!CsvAlgebraic;
        scope const(char)[][] header;
        auto nColumns = size_t.max;

        void process()
        {
            Decimal!128 decimal = void;
            DecimalExponentKey decimalKey;

            Timestamp timestamp;

            bool transp =
                kind == CsvKind.transposedMatrix || 
                kind == CsvKind.objectOfColumns;

            bool hasHeader =
                kind == CsvKind.objects ||
                kind == CsvKind.indexedObjects ||
                kind == CsvKind.objectOfColumns;

            size_t i;
            foreach (line; text.lineSplitter)
            {
                i++;
                if (i <= rowsToSkip)
                    continue;
                if (line.length && line[0] == comment)
                    continue;
                size_t j;
                if (header is null && hasHeader)
                {
                    foreach (value; line.splitter(separator))
                    {
                        j++;
                        if (stripUnquoted)
                            value = value.strip;
                        if (value.canFind('"'))
                        {
                            // TODO unqote
                            value = value.strip;
                        }
                        () @trusted {
                            headerBuff.put(value);
                        } ();
                    }
                    header = headerBuff.data;
                    nColumns = j;
                    continue;
                }
                size_t state;
                if (!transp)
                {
                    if (hasHeader)
                        state = serializer.structBegin;
                    else
                        state = serializer.listBegin();
                }
                foreach (value; splitter(line, separator))
                {
                    // The same like Mir deserializatin from string to floating
                    enum bool allowSpecialValues = true;
                    enum bool allowDotOnBounds = true;
                    enum bool allowDExponent = true;
                    enum bool allowStartingPlus = true;
                    enum bool allowUnderscores = false;
                    enum bool allowLeadingZeros = true;
                    enum bool allowExponent = true;
                    enum bool checkEmpty = false;

                    j++;
                    if (j > nColumns)
                        break;

                    if (stripUnquoted)
                        value = value.strip;

                    CsvAlgebraic scalar;

                    if (value.length == 0)
                    {
                        // null
                    }
                    else
                    if (decimal.fromStringImpl!(
                        char,
                        allowSpecialValues,
                        allowDotOnBounds,
                        allowDExponent,
                        allowStartingPlus,
                        allowUnderscores,
                        allowLeadingZeros,
                        allowExponent,
                        checkEmpty,
                    )(value, decimalKey))
                    {
                        if (decimalKey)
                            scalar = cast(double) decimal;
                        else
                            scalar = cast(long) decimal.coefficient;
                    }
                    else
                    if (Timestamp.fromString(value, timestamp))
                    {
                        scalar = timestamp;
                    }
                    else
                    switch (value)
                    {
                        case "true":
                        case "True":
                        case "TRUE":
                            scalar = true;
                            break;
                        case "false":
                        case "False":
                        case "FALSE":
                            scalar = false;
                            break;
                        default:
                            if (value.canFind('"'))
                            {
                                // TODO unqote
                                value = value.strip;
                            }
                            () @trusted {
                                scalar = cast(string) value;
                            } ();
                    }

                    if (j == 1 && (kind == CsvKind.indexedRows || kind == CsvKind.indexedObjects))
                    {
                        indexBuff.put(scalar);
                    }
                    else
                    if (!transp)
                    {
                        if (hasHeader)
                            serializer.putKey(header[j - 1]);
                        else
                            serializer.elemBegin();
                        serializer.serializeValue(scalar);
                    }
                    else
                    {
                        dataBuff.put(scalar);
                    }
                }
                if (j != nColumns && nColumns != nColumns.max)
                {
                    throw new MirException("CSV: Expected ", nColumns, ", got ", j, " at:\n", ParsePosition(fileName, cast(uint)i, 0));
                }
                nColumns = j;

                if (!transp)
                {
                    if (hasHeader)
                        serializer.structEnd(state);
                    else
                        serializer.listEnd(state);
                }
            }
        }

        final switch (kind)
        {
            case CsvKind.matrix:
            case CsvKind.objects:
            {
                auto state = serializer.listBegin();
                process();
                serializer.listEnd(state);
                break;
            }            
            case CsvKind.indexedRows:
            case CsvKind.indexedObjects:
            {
                auto wrapperState = serializer.structBegin;
                {
                    serializer.putKey("data");
                    {
                        auto state = serializer.listBegin();
                        process();
                        serializer.listEnd(state);
                    }
                    serializer.putKey("index");
                    {
                        serializer.serializeValue(indexBuff.data);
                    }
                }
                serializer.structEnd(wrapperState);
                break;
            }            
            case CsvKind.transposedMatrix:
            {
                auto data = dataBuff.data.sliced(nColumns, nColumns ? dataBuff.data.length / nColumns : 0);
                auto transposedData = data.transposed;
                serializer.serializeValue(transposedData);
                break;
            }
            case CsvKind.objectOfColumns:
            {
                auto data = dataBuff.data.sliced(nColumns, nColumns ? dataBuff.data.length / nColumns : 0);
                auto transposedData = data.transposed;
                auto sate = serializer.structBegin();
                foreach (j, key; header)
                {
                    serializer.putKey(key);
                    auto column = transposedData[j];
                    serializer.serializeValue(column);
                }
                serializer.structEnd(sate);
                break;
            }
        }
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
