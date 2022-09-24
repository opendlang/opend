/++
$(H2 CSV/TSV library)

DRAFT

Macros:
    AlgorithmREF = $(GREF_ALTTEXT mir-algorithm, $(TT $2), $2, mir, $1)$(NBSP)
    AAREF = $(REF_ALTTEXT $(TT $2), $2, mir, algebraic_alias, $1)$(NBSP)
+/
module mir.csv;

///
public import mir.algebraic_alias.csv: CsvAlgebraic;

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
    private static immutable NA_default = [
        ``,
        `#N/A`,
        `#N/A N/A`,
        `#NA`,
        `<NA>`,
        `N/A`,
        `NA`,
        `n/a`,
    ];
        // "NULL",
        // "null",

        // "1.#IND",
        // "-1.#QNAN",
        // "-1.#IND",
        // "1.#QNAN",

        // "-NaN",
        // "-nan",
        // "nan",
        // "NaN",

    ///
    const(char)[] text;
    ///
    CsvKind kind;
    ///
    bool stripUnquoted = true; 
    ///
    char separator = ',';
    ///
    char comment = char.init;
    ///
    ubyte rowsToSkip;
    ///
    const(string)[] naStrings = NA_default;
    /++
    Conversion callback to finish conversion resolution
    Params:
        unquotedString = string after unquoting
        isQuoted = is the original data field is quoted
        columnIndex = column index starting from 0
        columnName = column name if any
    +/
    CsvAlgebraic delegate(
        return scope const(char)[] unquotedString,
        bool isQuoted,
        return scope CsvAlgebraic scalar,
        size_t columnIndex,
        scope const(char)[] columnName
    ) @safe pure @nogc conversionFinalizer;
    /// File name for berrer error messages
    string fileName = "<unknown>";

    void serialize(S)(scope ref S serializer) scope const @trusted
    {
        // DRAFT
        // TODO: have to be @nogc
        // import std.ascii;
        import mir.appender: scopedBuffer;
        import mir.bignum.decimal: Decimal, DecimalExponentKey;
        import mir.exception: MirException;
        import mir.ndslice.dynamic: transposed;
        import mir.ndslice.slice: sliced;
        import mir.parse: ParsePosition;
        import mir.ser: serializeValue;
        import mir.timestamp: Timestamp;
        import mir.utility: _expect;
        import std.algorithm.iteration: splitter;
        import std.algorithm.searching: canFind;
        import std.string: lineSplitter, strip;

        auto headerBuff = scopedBuffer!(const(char)[]);
        auto unquotedStringStringBuff = scopedBuffer!(const(char));
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
                    serializer.elemBegin;
                    if (hasHeader)
                        state = serializer.structBegin(nColumns);
                    else
                        state = serializer.listBegin(nColumns);
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

                    bool quoted;

                    if (value.canFind('"'))
                    {
                        quoted = true;
                        // TODO unqote
                        value = value.strip;
                    }
                    else
                    if (value.length && decimal.fromStringImpl!(
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
                    S: switch (value)
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
                            foreach (na; naStrings)
                                if (na == value)
                                    break S; // null
                            () @trusted {
                                scalar = cast(string) value;
                                bool quoted = false;
                            } ();
                    }

                    if (_expect(conversionFinalizer !is null, false))
                    {
                        scalar = conversionFinalizer(value, quoted, scalar, j - 1, hasHeader ? header[j - 1] : null);
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
                auto state = serializer.listBegin;
                process();
                serializer.listEnd(state);
                break;
            }            
            case CsvKind.indexedRows:
            case CsvKind.indexedObjects:
            {
                auto wrapperState = serializer.structBegin(2);
                {
                    serializer.putKey("data");
                    auto state = serializer.listBegin;
                    process();
                    serializer.listEnd(state);

                    serializer.putKey("index");
                    serializer.serializeValue(indexBuff.data);
                }
                serializer.structEnd(wrapperState);
                break;
            }            
            case CsvKind.transposedMatrix:
            {
                process();
                auto data = dataBuff.data.sliced(nColumns ? dataBuff.data.length / nColumns : 0, nColumns);
                auto transposedData = data.transposed;
                serializer.serializeValue(transposedData);
                break;
            }
            case CsvKind.objectOfColumns:
            {
                process();
                auto data = dataBuff.data.sliced(nColumns ? dataBuff.data.length / nColumns : 0, nColumns);
                auto transposedData = data.transposed;
                auto sate = serializer.structBegin(header.length);
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

/++
Type resolution is performed for types defined in $(MREF mir,algebraic_alias,csv):

$(UL 
    $(LI `typeof(null)` - used for N/A values)
    $(LI `bool`)
    $(LI `long`)
    $(LI `double`)
    $(LI `string`)
    $(LI $(AlgorithmREF timestamp, Timestamp))
)
+/
unittest
{
    import mir.ion.conv: serde;
    import mir.ndslice.slice: Slice;
    import mir.ser.text: serializeTextPretty;
    import mir.test: should;
    import std.string: join;

    // alias Matrix = Slice!(CsvAlgebraic*, 2);

    Csv csv = {
        conversionFinalizer : (
            unquotedString,
            isQuoted,
            scalar,
            columnIndex,
            columnName)
        {
            return !isQuoted && unquotedString == `Billion` ?
                1000000000.CsvAlgebraic :
                scalar;
        },
        text : join([
            // User-defined conversion
            `Billion`
            // `long` patterns
            , `100`, `+200`, `-200`
            // `double` pattern
            , `+1.0`, `-.2`, `3.`, `3e-10`, `3d20`,
            // also `double` pattern
            `inf`, `+Inf`, `-INF`, `+NaN`, `-nan`, `NAN`
            // `bool` patterns
            , `True`, `TRUE`, `true`, `False`, `FALSE`, `false`
            // `Timestamp` patterns
            , `2021-02-03` // iso8601 extended
            , `20210204T` // iso8601
            , `20210203T0506` // iso8601
            , `2001-12-15T02:59:43.1Z` //canonical
            , `2001-12-14t21:59:43.1-05:30` //with lower `t`
            , `2001-12-14 21:59:43.1 -5` //yaml space separated
            , `2001-12-15 2:59:43.10` //no time zone (Z):
            , `2002-12-14` //date (00:00:00Z):
            // Default NA patterns are converted to NaN when exposed to arrays
            // and skipped when exposed to objects
            , ``
            , `#N/A`
            , `#N/A N/A`
            , `#NA`
            , `<NA>`
            , `N/A`
            , `NA`
            , `n/a`
            // strings patterns (TODO)
            , `100_000`
            , `nAN`
            , `iNF`
            , `Infinity`
            , `+Infinity`
            , `.Infinity`
            // , `""`
            // , ` `
        ], `,`)
    };

    // Serializing Csv to Amazon Ion (text version)
    csv.serializeTextPretty!"    ".should ==
`[
    [
        1000000000,
        100,
        200,
        -200,
        1.0,
        -0.2,
        3.0,
        3e-10,
        3e+20,
        +inf,
        +inf,
        -inf,
        nan,
        nan,
        nan,
        true,
        true,
        true,
        false,
        false,
        false,
        2021-02-03,
        2021-02-04,
        2021-02-03T05:06Z,
        2001-12-15T02:59:43.1Z,
        2001-12-14T21:59:43.1-05:30,
        2001-12-14T21:59:43.1-05,
        2001-12-15T02:59:43.10Z,
        2002-12-14,
        null,
        null,
        null,
        null,
        null,
        null,
        null,
        null,
        "100_000",
        "nAN",
        "iNF",
        "Infinity",
        "+Infinity",
        ".Infinity"
    ]
]`;
}

/// Matrix & Transposed Matrix
unittest
{
    import mir.test: should;
    import mir.ndslice.slice: Slice;
    import mir.ion.conv: serde;

    alias Matrix = Slice!(double*, 2);

    auto text = "1,2\n3,4\r\n5,6\n";
    auto matrix = text.Csv.serde!Matrix;
    matrix.should == [[1, 2], [3, 4], [5, 6]];

    Csv csv = {
        text : text,
        kind : CsvKind.transposedMatrix
    };
    csv.serde!Matrix.should == [[1.0, 3, 5], [2.0, 4, 6]];
}

/++
Transposed Matrix & Tuple support
+/
unittest
{
    import mir.ion.conv: serde;
    import mir.date: Date; //also wotks with mir.timestamp and std.datetime
    import mir.functional: Tuple;
    import mir.ser.text: serializeText;
    import mir.test: should;

    Csv csv = {
        text : "str,2022-10-12,3.4\nb,2022-10-13,2\n",
        kind : CsvKind.transposedMatrix
    };

    csv.serializeText.should == `[["str","b"],[2022-10-12,2022-10-13],[3.4,2]]`;

    alias T = Tuple!(string[], Date[], double[]);

    csv.serde!T.should == T (
        ["str", "b"],
        [Date(2022, 10, 12), Date(2022, 10, 13)],
        [3.4, 2],
    );
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
