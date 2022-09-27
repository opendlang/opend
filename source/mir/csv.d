/++
$(H2 CSV/TSV parsing)

DRAFT

$(LREF Csv) can be serialized to Ion, JSON, MsgPack, or YAML
and then deserialized to a specified type.
That approachs allows to use the same mir deserialization
pattern like for other data types.
$(IONREF conv, serde) unifies this two steps throught binary Ion format,
which serves as an efficient DOM representation for all other formats.

Macros:
    IONREF = $(REF_ALTTEXT $(TT $2), $2, mir, ion, $1)$(NBSP)
    AlgorithmREF = $(GREF_ALTTEXT mir-algorithm, $(TT $2), $2, mir, $1)$(NBSP)
    AAREF = $(REF_ALTTEXT $(TT $2), $2, mir, algebraic_alias, $1)$(NBSP)
+/

module mir.csv;

import mir.primitives: isOutputRange;
import mir.serde: SerdeTarget;

///
public import mir.algebraic_alias.csv: CsvAlgebraic;

/++
+/
struct Csv
{
    ///
    const(char)[] text;
    ///
    bool hasHeader = true;
    ///
    char separator = ',';
    ///
    char quote = '"';
    ///
    char comment = '\0';
    ///
    bool stripSpace = false; 
    ///
    ubyte skipRows;
    ///
    bool parseNumbers = true;
    ///
    bool parseTimestamps = true;

    /++
    N/A and NULL patterns are converted to Ion `null` when exposed to arrays
    and skipped when exposed to objects
    +/
    const(string)[] naStrings = [
        ``,
    ];

    const(string)[] trueStrings = [
        `TRUE`,
    ];

    const(string)[] falseStrings = [
        `FALSE`,
    ];

    /// File name for berrer error messages
    string fileName = "<unknown>";

    // /++
    // +/
    // bool delegate(size_t columnIndex, scope const(char)[] columnName) useColumn;

    /++
    Conversion callback to finish conversion resolution
    Params:
        unquotedString = string after unquoting
        kind = currently recognized path
        columnIndex = column index starting from 0
    +/
    CsvAlgebraic delegate(
        return scope const(char)[] unquotedString,
        CsvAlgebraic scalar,
        bool quoted,
        size_t columnIndex
    ) @safe pure @nogc conversionFinalizer;

    /++
    +/
    static bool defaultIsSymbolHandler(scope const(char)[] symbol, bool quoted) @safe pure @nogc nothrow
    {
        import mir.algorithm.iteration: all;
        return !quoted && symbol.length && symbol.all!(
            c =>
                'a' <= c && c <= 'z' ||
                'A' <= c && c <= 'Z' ||
                c == '_'
        );
    }

    /++
    A function used to determine if a string should be passed
    to a serializer as a symbol instead of strings.
    That may help to reduce memory allocation for data with
    a huge amount of equal cell values.``
    The default pattern follows regular expression `[a-zA-Z_]+`
    and requires symbol to be presented without double quotes.
    +/
    bool function(scope const(char)[] symbol, bool quoted) @safe pure @nogc isSymbolHandler = &defaultIsSymbolHandler;

    void serialize(S)(scope ref S serializer) scope const @trusted
    {
        // DRAFT
        // TODO: have to be @nogc
        // import std.ascii;
        import mir.bignum.decimal: Decimal, DecimalExponentKey;
        import mir.exception: MirException;
        import mir.ndslice.dynamic: transposed;
        import mir.ndslice.slice: sliced;
        import mir.parse: ParsePosition;
        import mir.ser: serializeValue;
        import mir.timestamp: Timestamp;
        import mir.utility: _expect;
        import mir.format: stringBuf;
        import std.algorithm.iteration: splitter;
        import std.algorithm.searching: canFind;
        import std.string: lineSplitter, strip;

        auto csv = text[];
        if (csv.length)
        {
            LS: foreach (i; 0 .. skipRows)
            {
                do
                {
                    csv = csv[1 .. $];
                    if (csv.length == 0)
                        break LS;
                }
                while(csv[0] != '\n');
            }
        }
        if (comment && csv.length)
        {
            LC: while (csv[0] == comment)
            {
                do
                {
                    csv = csv[1 .. $];
                    if (csv.length == 0)
                        break LC;
                }
                while(csv[0] != '\n');
                csv = csv[1 .. $];
                if (csv.length == 0)
                    break LC;
            }
        }

        bool initLoop;
        auto strBuf = stringBuf;
        const(char)[] readQuoted() scope return
        {
            strBuf.reset;
            // fill buf here
            // ...
            return strBuf.data;
        }

            // if (i == 0 && hasHeader)
        { // first line lookup to count columns
            // if header?
            // put symbol!
        }
        size_t i;
        auto nColumns = size_t.max;
        size_t wrapperState;
        size_t outerState;


        foreach (line; csv.lineSplitter)
        {
            if (!initLoop)
            {
                initLoop = true;
                outerState = serializer.listBegin;
            }
            size_t j;
            size_t state;
            serializer.elemBegin;
            state = serializer.listBegin(nColumns);
            foreach (value; splitter(line, separator))
            {
                j++;
                if (j > nColumns)
                    break;

                if (_expect(stripSpace, false))
                {
                    if (separator == '\t')
                    {
                        while (value.length && value[0] == ' ')
                            value = value[1 .. $];
                        while (value.length && value[$ - 1] == ' ')
                            value = value[0 .. $ - 1];

                    }
                    else
                    {
                        while (value.length && (value[0] == ' ' || value[0] == '\t'))
                            value = value[1 .. $];
                        while (value.length && (value[$ - 1] == ' ' || value[$ - 1] == '\t'))
                            value = value[0 .. $ - 1];
                    }
                }

                CsvAlgebraic scalar;
                bool quoted;
                DecimalExponentKey decimalKey;
                Decimal!128 decimal = void;
                    Timestamp timestamp;

                enum bool allowSpecialValues = true;
                enum bool allowDotOnBounds = true;
                enum bool allowDExponent = true;
                enum bool allowStartingPlus = true;
                enum bool allowUnderscores = false;
                enum bool allowLeadingZeros = false;
                enum bool allowExponent = true;
                enum bool checkEmpty = true;

                quoted = value.length && value[0] == quote;
                if (_expect(quoted, false))
                {
                    scalar = cast(string) readQuoted;
                }
                else
                if (parseNumbers && decimal.fromStringImpl!(
                    char,
                    allowSpecialValues,
                    allowDotOnBounds,
                    allowDExponent,
                    allowStartingPlus,
                    allowUnderscores,
                    allowLeadingZeros,
                    allowExponent,
                    checkEmpty)
                    (value, decimalKey))
                {
                    if (decimalKey)
                        scalar = cast(double) decimal;
                    else
                        scalar = cast(long) decimal.coefficient;
                }
                else
                if (parseTimestamps && Timestamp.fromISOExtString(value, timestamp))
                {
                    scalar = timestamp;
                }
                else
                if (naStrings.canFind(value))
                {
                }
                else
                if (trueStrings.canFind(value))
                {
                    scalar = true;
                }
                else
                if (falseStrings.canFind(value))
                {
                    scalar = false;
                }
                else
                {
                    scalar = cast(string) value;
                }

                if (_expect(conversionFinalizer !is null, false))
                {
                    scalar = conversionFinalizer(value, scalar, quoted, j - 1);
                }
                serializer.elemBegin();
                serializer.serializeValue(scalar);
            }
            if (j != nColumns && nColumns != nColumns.max)
            {
                throw new MirException("CSV: Expected ", nColumns, ", got ", j, " at:\n", ParsePosition(fileName, cast(uint)i, 0));
            }
            nColumns = j;

            serializer.listEnd(state);
        }
        if (!initLoop)
            outerState = serializer.listBegin(0);
        serializer.listEnd(outerState);
    }
}

/++
Ion serialization function with pretty formatting.
+/
string serializeCsv(V)(
    auto scope ref const V value,
    char separator = ',',
    char quote = '"',
    bool quoteAll = false,
    string naValue = "",
    string trueValue = "TRUE",
    string falseValue = "FALSE",
    int serdeTarget = SerdeTarget.csv)
{
    import std.array: appender;
    auto app = appender!(char[]);
    .serializeCsv!(typeof(app), V)(app, value,
    separator,
    quote,
    quoteAll,
    naValue,
    trueValue,
    falseValue,
    serdeTarget);
    return (()@trusted => cast(string) app.data)();
}

///
version(mir_ion_test) unittest
{
    import mir.timestamp: Timestamp;
    import mir.format: stringBuf;
    import mir.test;
    auto someMatrix = [
        [3.0.CsvAlgebraic, 2.CsvAlgebraic, true.CsvAlgebraic, ],
        ["str".CsvAlgebraic, "2022-12-12".Timestamp.CsvAlgebraic, "".CsvAlgebraic, null.CsvAlgebraic],
        [double.nan.CsvAlgebraic, double.infinity.CsvAlgebraic, 0.0.CsvAlgebraic]
    ];

    someMatrix.serializeCsv.should == "3.0,2,TRUE\nstr,2022-12-12,\"\",\nNAN,+INF,0.0\n";
}

/++
Ion serialization for custom outputt range.
+/
void serializeCsv(Appender, V)(
    scope ref Appender appender,
    auto scope ref const V value,
    char separator = ',',
    char quote = '"',
    bool quoteAll = false,
    string naValue = "",
    string trueValue = "TRUE",
    string falseValue = "FALSE",
    int serdeTarget = SerdeTarget.csv)
    if (isOutputRange!(Appender, const(char)[]) && isOutputRange!(Appender, char))
{
    auto serializer = CsvSerializer!Appender((()@trusted => &appender)());
    serializer.serdeTarget = serdeTarget;
    serializer.separator = separator;
    serializer.quote = quote;
    serializer.quoteAll = quoteAll;
    serializer.naValue = naValue;
    serializer.trueValue = trueValue;
    serializer.falseValue = falseValue;
    import mir.ser: serializeValue;
    serializeValue(serializer, value);
}

///
@safe pure // nothrow @nogc
unittest
{
    import mir.timestamp: Timestamp;
    import mir.format: stringBuf;
    import mir.test;

    auto someMatrix = [
        ["str".CsvAlgebraic, 2.CsvAlgebraic, true.CsvAlgebraic],
        [3.0.CsvAlgebraic, "2022-12-12".Timestamp.CsvAlgebraic, null.CsvAlgebraic]
    ];

    auto buffer = stringBuf;
    buffer.serializeCsv(someMatrix);
    buffer.data.should == "str,2,TRUE\n3.0,2022-12-12,\n";
}

struct CsvSerializer(Appender)
{
    import mir.bignum.decimal: Decimal;
    import mir.bignum.integer: BigInt;
    import mir.format: print, stringBuf, printReplaced;
    import mir.internal.utility: isFloatingPoint;
    import mir.ion.type_code;
    import mir.lob;
    import mir.string: containsAny;
    import mir.timestamp;
    import std.traits: isNumeric;

    /++
    CSV string buffer
    +/
    Appender* appender;

    ///
    char separator = ',';
    ///
    char quote = '"';
    ///
    bool quoteAll;

    ///
    string naValue = "";
    ///
    string trueValue = "TRUE";
    ///
    string falseValue = "FALSE";

    /// Mutable value used to choose format specidied or user-defined serialization specializations
    int serdeTarget = SerdeTarget.csv;

    private uint level, row, column;


@safe scope:

    ///
    size_t stringBegin()
    {
        appender.put('"');
        return 0;
    }

    /++
    Puts string part. The implementation allows to split string unicode points.
    +/
    void putStringPart(scope const(char)[] value)
    {
        printReplaced(appender, value, '"', `""`);
    }

    ///
    void stringEnd(size_t)
    {
        appender.put('"');
    }

    ///
    size_t structBegin(size_t length = size_t.max)
    {
        throw new Exception("mir.csv: structure serialization isn't supported: ");
    }

    ///
    void structEnd(size_t state)
    {
        throw new Exception("mir.csv: structure serialization isn't supported");
    }

    ///
    size_t listBegin(size_t length = size_t.max)
    {
        assert(level <= 2);
        if (level++ >= 2)
            throw new Exception("mir.csv: arrays can't be serialized as scalar values");
        return 0;
    }

    ///
    void listEnd(size_t state)
    {
        if (level-- == 2)
        {
            column = 0;
            appender.put('\n');
        }
        else
        {
            row = 0;
        }
    }

    ///
    alias sexpBegin = listBegin;

    ///
    alias sexpEnd = listEnd;

    ///
    void putSymbol(scope const char[] symbol)
    {
        putValue(symbol);
    }

    ///
    void putAnnotation(scope const(char)[] annotation)
    {
        assert(0);
    }

    ///
    auto annotationsEnd(size_t state)
    {
        assert(0);
    }

    ///
    size_t annotationWrapperBegin(size_t length = size_t.max)
    {
        throw new Exception("mir.csv: annotation serialization isn't supported");
    }

    ///
    void annotationWrapperEnd(size_t annotationsState, size_t state)
    {
        assert(0);
    }

    ///
    void nextTopLevelValue()
    {
        appender.put('\n');
    }

    ///
    void putKey(scope const char[] key)
    {
        assert(0);
    }

    ///
    void putValue(Num)(const Num value)
        if (isNumeric!Num && !is(Num == enum))
    {
        auto buf = stringBuf;
        static if (isFloatingPoint!Num)
        {
            import mir.math.common: fabs;

            if (value.fabs < value.infinity)
                print(buf, value);
            else if (value == Num.infinity)
                buf.put(`+INF`);
            else if (value == -Num.infinity)
                buf.put(`-INF`);
            else
                buf.put(`NAN`);
        }
        else
            print(buf, value);
        putValue(buf.data);
    }

    ///
    void putValue(size_t size)(auto ref const BigInt!size num)
    {
        auto buf = stringBuf;
        num.toString(buf);
        putValue(buf.data);
    }

    ///
    void putValue(size_t size)(auto ref const Decimal!size num)
    {
        auto buf = stringBuf;
        num.toString(buf);
        putValue(buf.data);
    }

    ///
    void putValue(typeof(null))
    {
        putValue(naValue, true);
    }

    /// ditto 
    void putNull(IonTypeCode code)
    {
        putValue(null);
    }

    ///
    void putValue(bool b)
    {
        putValue(b ? trueValue : falseValue, true);
    }

    ///
    void putValue(scope const char[] value, bool noQuote = false)
    {
        import mir.exception: MirException;
        import mir.utility: _expect;

        if (_expect(level != 2, false))
            throw new MirException(
                "mir.csv: expected ",
                level ? "row" : "table",
                " value, got scalar value '", value, "'");

        if (!quoteAll
         && (noQuote || !value.containsAny(separator, quote, '\n'))
         && ((value == naValue || value == trueValue || value == falseValue) == noQuote)
        )
        {
            appender.put(value);
        }
        else
        {
            auto state = stringBegin;
            putStringPart(value);
            stringEnd(state);
        }
    }

    ///
    void putValue(scope Clob value)
    {
        import mir.format: printEscaped, EscapeFormat;

        auto buf = stringBuf;

        buf.put(`{{"`);

        printEscaped!(char, EscapeFormat.ionClob)(buf, value.data);

        buf.put(`"}}`);

        putValue(buf.data);
    }

    ///
    void putValue(scope Blob value)
    {
        import mir.base64 : encodeBase64;

        auto buf = stringBuf;

        buf.put("{{");

        encodeBase64(value.data, buf);

        buf.put("}}");

        putValue(buf.data);
    }

    ///
    void putValue(Timestamp value)
    {
        auto buf = stringBuf;
        value.toISOExtString(buf);
        putValue(buf.data);
    }

    ///
    void elemBegin()
    {
        if (level == 2)
        {
            if (column++)
                appender.put(separator);
        }
        else
        {
            row++;
        }
    }

    ///
    alias sexpElemBegin = elemBegin;
}

/// Matrix
unittest
{
    import mir.test: should;
    import mir.ndslice.slice: Slice;
    import mir.ion.conv: serde;

    alias Matrix = Slice!(double*, 2);

    auto text = "1,2\n3,4\r\n5,6\n";

    auto matrix = text.Csv.serde!Matrix;
    matrix.should == [[1, 2], [3, 4], [5, 6]];
}

// First draft
version(none):

///
unittest
{
    import mir.csv;
    import mir.ion.conv: serde; // to convert Csv to D types
    import mir.serde: serdeKeys, serdeIgnoreUnexpectedKeys, serdeOptional;
    // mir.date and std.datetime are supported as well
    import mir.timestamp: Timestamp;//mir-algorithm package
    import mir.test: should;

    auto text =
`Date,Open,High,Low,Close,Volume
2021-01-21 09:30:00,133.8,134.43,133.59,134.0,9166695
2021-01-21 09:35:00,134.25,135.0,134.19,134.5,4632863`;

    Csv csv = {
        text: text,
        // We allow 7 CSV payloads!
        kind: CsvKind.dataFrame
    };

    // If you don't have a header,
    // `mir.functional.Tuple` instead of MyDataFrame.
    @serdeIgnoreUnexpectedKeys //ignore all other columns
    static struct MyDataFrame
    {
        // Few keys are allowed
        @serdeKeys(`Date`, `date`, `timestamp`)
        Timestamp[] timestamp;

        @serdeKeys(`Open`)  double[]    open;
        @serdeKeys(`High`)  double[]    high;
        @serdeKeys(`Low`)   double[]    low;
        @serdeKeys(`Close`) double[]    close;

        @serdeOptional // if we don't have Volume
        @serdeKeys(`Volume`)
        long[]volume;
    }

    MyDataFrame testValue = {
        timestamp:  [`2021-01-21 09:30:00`.Timestamp, `2021-01-21 09:35:00`.Timestamp],
        volume:     [9166695, 4632863],
        open:       [133.8,  134.25],
        high:       [134.43, 135],
        low:        [133.59, 134.19],
        close:      [134.0,  134.5],
    };

    csv.serde!MyDataFrame.should == testValue;

    ///////////////////////////////////////////////
    /// More flexible Data Frame

    import mir.algebraic_alias.csv: CsvAlgebraic;
    alias DataFrame = CsvAlgebraic[][string];
    auto flex = csv.serde!DataFrame;

    flex["Volume"][1].should == 4632863;
}

/++
CSV representation kind.
+/
enum CsvKind
{
    /++
    Array of rows.

    Ion_Payload:
    ```
    [
        [cell_0_0, cell_0_1, cell_0_2, ...],
        [cell_1_0, cell_1_1, cell_1_2, ...],
        [cell_2_0, cell_2_1, cell_2_2, ...],
        ...
    ]
    ```
    +/
    matrix,
    /++
    Arrays of objects with object field names from the header.

    Ion_Payload:
    ```
    [
        {
            cell_0_0: cell_1_0,
            cell_0_1: cell_1_1,
            cell_0_2: cell_1_2,
            ...
        },
        {
            cell_0_0: cell_2_0,
            cell_0_1: cell_2_1,
            cell_0_2: cell_2_2,
            ...
        },
        ...
    ]
    ```
    +/
    objects,
    /++
    Indexed array of rows with index from the first column.

    Ion_Payload:
    ```
    {
        data: [
            [cell_0_1, cell_0_2, ...],
            [cell_1_1, cell_1_2, ...],
            [cell_2_1, cell_2_2, ...],
            ...
        ],
        index: [cell_0_0, cell_1_0, cell_2_0, ...]
    }
    ```
    +/
    series,
    /++
    DataFrame representation.

    Ion_Payload:
    ```
    {
        indexName: cell_0_0,
        columnNames: [cell_0_1, cell_0_2, ...],
        data: [
            [cell_1_1, cell_1_2, ...],
            [cell_2_1, cell_2_2, ...],
            ...
        ],
        index: [cell_1_0, cell_2_0, ...]
    }
    ```
    +/
    seriesWithHeader,
    /++
    Indexed arrays of objects with index from the first column and object field names from the header.

    Ion_Payload:
    ```
    {
        data: [
            {
                cell_0_1: cell_1_1,
                cell_0_2: cell_1_2,
                ...
            },
            {
                cell_0_1: cell_2_1,
                cell_0_2: cell_2_2,
                ...
            },
            ...
        ],
        index: [cell_1_0, cell_2_0, ...]
    }
    ```
    +/
    seriesOfObjects,
    /++
    Array of columns.

    Ion_Payload:
    ```
    [
        [cell_0_0, cell_1_0, cell_2_0, ...],
        [cell_0_1, cell_1_1, cell_2_1, ...],
        [cell_0_2, cell_1_2, cell_2_2, ...],
        ...
    ]
    ```
    +/
    transposedMatrix,
    /++
    Object of columns with object field names from the header.

    Ion_Payload:
    ```
    {
        cell_0_0: [cell_1_0, cell_2_0, ...],
        cell_0_1: [cell_1_1, cell_2_1, ...],
        cell_0_2: [cell_1_2, cell_2_2, ...],
        ...
    }
    ```
    +/
    dataFrame,
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
    char separator = ',';
    ///
    bool stripUnquoted = false; 
    ///
    char comment = char.init;
    ///
    ubyte rowsToSkip;
    /++
    NA patterns are converted to Ion `null` when exposed to arrays
    and skipped when exposed to objects
    +/
    const(string)[] naStrings = NA_default;
    /// File name for berrer error messages
    string fileName = "<unknown>";

    // /++
    // +/
    // bool delegate(size_t columnIndex, scope const(char)[] columnName) useColumn;

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
        return scope CsvAlgebraic scalar,
        size_t columnIndex,
        scope const(char)[] columnName
    ) @safe pure @nogc conversionFinalizer;

    /++
    +/
    static bool defaultIsSymbolHandler(scope const(char)[] symbol, bool quoted) @safe pure @nogc nothrow
    {
        import mir.algorithm.iteration: all;
        return !quoted && symbol.length && symbol.all!(
            c =>
                'a' <= c && c <= 'z' ||
                'A' <= c && c <= 'Z' ||
                c == '_'
        );
    }

    /++
    A function used to determine if a string should be passed
    to a serializer as a symbol instead of strings.
    That may help to reduce memory allocation for data with
    a huge amount of equal cell values.``
    The default pattern follows regular expression `[a-zA-Z_]+`
    and requires symbol to be presented without double quotes.
    +/
    bool function(scope const(char)[] symbol, bool quoted) @safe pure @nogc isSymbolHandler = &defaultIsSymbolHandler;

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

        Decimal!128 decimal = void;
        DecimalExponentKey decimalKey;

        Timestamp timestamp;

        const transp =
            kind == CsvKind.transposedMatrix || 
            kind == CsvKind.dataFrame;

        const hasInternalHeader =
            kind == CsvKind.objects ||
            kind == CsvKind.seriesOfObjects;

        const hasHeader = hasInternalHeader ||
            kind == CsvKind.dataFrame ||
            kind == CsvKind.seriesWithHeader;

        const hasIndex =
            kind == CsvKind.series ||
            kind == CsvKind.seriesOfObjects ||
            kind == CsvKind.seriesWithHeader;
        
        bool initLoop;

        size_t wrapperState;
        size_t outerState;

        auto csv = text[];
        if (csv.length)
        {
            LS: foreach (i; 0 .. rowsToSkip)
            {
                do
                {
                    csv = csv[1 .. $];
                    if (csv.length == 0)
                        break LS;
                }
                while(csv[0] != '\n');
            }
        }
        if (comment && csv.length)
        {
            LC: while (csv[0] == comment)
            {
                do
                {
                    csv = csv[1 .. $];
                    if (csv.length == 0)
                        break LC;
                }
                while(csv[0] != '\n');
                csv = csv[1 .. $];
                if (csv.length == 0)
                    break LC;
            }
        }

        size_t i;
        foreach (line; csv.lineSplitter)
        {
            size_t j;
            if (header is null && hasHeader)
            {
                foreach (value; line.splitter(separator))
                {
                    j++;
                    if (stripUnquoted)
                        value = value.strip;
                    if (value.containsAny('"'))
                    {
                        // TODO unqote
                        value = value.strip;
                    }
                    () @trusted {
                        headerBuff.put(value);
                    } ();
                }
                header = headerBuff.data;
                assert(header.length);
                assert(j == header.length);
                nColumns = j;
                continue;
            }
            if (!initLoop)
            {
                initLoop = true;
                if (!transp)
                {
                    if (hasIndex)
                    {
                        wrapperState = serializer.structBegin(kind == CsvKind.seriesWithHeader ? 4 : 2);
                        if (kind == CsvKind.seriesWithHeader)
                        {
                            serializer.putKey("indexName");
                            serializer.putSymbol(header[0]);
                            serializer.putKey("columnNames");
                            auto state = serializer.listBegin(header.length - 1);
                            foreach (name; header[1 .. $])
                            {
                                serializer.elemBegin;
                                serializer.putSymbol(name);
                            }
                            serializer.listEnd(state);
                        }
                        serializer.putKey("data");
                    }
                    outerState = serializer.listBegin;
                }
            }
            size_t state;
            if (!transp)
            {
                serializer.elemBegin;
                if (hasInternalHeader)
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

                if (value.containsAny('"'))
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
                    scalar.isQuoted = quoted;
                    scalar = conversionFinalizer(value, scalar, j - 1, hasHeader ? header[j - 1] : null);
                }

                if (j == 1 && hasIndex)
                {
                    indexBuff.put(scalar);
                }
                else
                if (!transp)
                {
                    if (!hasInternalHeader)
                        serializer.elemBegin();
                    else
                    if (scalar.isNull)
                        goto Skip;
                    else
                        serializer.putKey(header[j - 1]);

                    if (scalar._is!string && isSymbolHandler(scalar.trustedGet!string, scalar.isQuoted))
                        serializer.putSymbol(scalar.trustedGet!string);
                    else
                        serializer.serializeValue(scalar);
                Skip:
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
                if (hasInternalHeader)
                    serializer.structEnd(state);
                else
                    serializer.listEnd(state);
            }
        }
        if (!transp)
        {
            if (!initLoop)
                outerState = serializer.listBegin(0);
            serializer.listEnd(outerState);

            if (hasIndex)
            {
                serializer.putKey("index");
                serializer.serializeValue(indexBuff.data);
                serializer.structEnd(wrapperState);
            }
        }

        if (transp)
        {
            // auto data = dataBuff.data.sliced(nColumns ? dataBuff.data.length / nColumns : 0, nColumns);
            // auto transposedData = data.transposed;
            auto data = dataBuff.data;

            auto nRows = nColumns ? data.length / nColumns : 0;
            assert(nRows * nColumns == data.length);

            auto state = hasHeader ? serializer.structBegin(nColumns) : serializer.listBegin(nColumns);
            foreach (j; 0 .. nColumns)
            {
                hasHeader ? serializer.putKey(header[j]) : serializer.elemBegin;
                auto listState = serializer.listBegin(nRows);
                foreach (ii; 0 .. nRows)
                {
                    serializer.elemBegin;

                    auto scalar = data[ii * nColumns + j];
                    if (scalar._is!string && isSymbolHandler(scalar.trustedGet!string, scalar.isQuoted))
                        serializer.putSymbol(scalar.trustedGet!string);
                    else
                        serializer.serializeValue(scalar);
                }
                serializer.listEnd(listState);
            }
            hasHeader ? serializer.structEnd(state) : serializer.listEnd(state);
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
            scalar,
            columnIndex,
            columnName)
        {
            // Do we want to symbolize the data?
            return !scalar.isQuoted && unquotedString == `Billion` ?
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
            // Default NA patterns are converted to Ion `null` when exposed to arrays
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
            , `_ab0`
            , `_abc`     // match default pattern for symbols
            , `Str`      // match default pattern for symbols
            , `Value100` // match default pattern for symbols
            , `iNF`      // match default pattern for symbols
            , `Infinity` // match default pattern for symbols
            , `+Infinity`
            , `.Infinity`
            // , `""`
            // , ` `
        ], `,`)
    };

    // Serializing Csv to Amazon Ion (text version)
    csv.serializeTextPretty!"    ".should ==
q{[
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
        "_ab0",
        _abc,
        Str,
        "Value100",
        iNF,
        Infinity,
        "+Infinity",
        ".Infinity"
    ]
]};
}

///
unittest
{
    import mir.csv;
    import mir.date: Date; // Phobos std.datetime supported as well
    import mir.ion.conv: serde; // to convert Csv to DataFrame
    import mir.ndslice.slice: Slice;//ditto
    import mir.timestamp: Timestamp;//mir-algorithm package
    // for testing
    import mir.ndslice.fuse: fuse;
    import mir.ser.text: serializeTextPretty;
    import mir.test: should;

    auto text =
`Date,Open,High,Low,Close,Volume
2021-01-21 09:30:00,133.8,134.43,133.59,134.0,9166695
2021-01-21 09:35:00,134.25,135.0,134.19,134.5,4632863`;

    Csv csv = {
        text: text,
        // We allow 7 CSV payloads!
        kind: CsvKind.seriesWithHeader
    };

    // Can be of any scalar type including `CsvAlgebraic`
    alias Elem = double;
    // `Elem[][]` matrix are supported as well.
    // But we like `Slice` because we can easily access columns
    alias Matrix = Slice!(Elem*, 2);

    static struct MySeriesWithHeader
    {
        string indexName;
        string[] columnNames;
        Matrix data;
        // Can be an array of any type that can be deserialized
        // like a string or `CsvAlgebraic`, `Date`, `DateTime`, or whatever.
        Timestamp[] index;
    }

    MySeriesWithHeader testSeries = {
        indexName: `Date`,
        columnNames: [`Open`, `High`, `Low`, `Close`, `Volume`],
        data: [
            [133.8, 134.43, 133.59, 134.0, 9166695],
            [134.25, 135.0, 134.19, 134.5, 4632863],
        ].fuse,
        index: [
            `2021-01-21T09:30:00Z`.Timestamp,
            `2021-01-21T09:35:00Z`.Timestamp,
        ],
    };

    // Check how Ion payload looks like
    csv.serializeTextPretty!"    ".should == `{
    indexName: Date,
    columnNames: [
        Open,
        High,
        Low,
        Close,
        Volume
    ],
    data: [
        [
            133.8,
            134.43,
            133.59,
            134.0,
            9166695
        ],
        [
            134.25,
            135.0,
            134.19,
            134.5,
            4632863
        ]
    ],
    index: [
        2021-01-21T09:30:00Z,
        2021-01-21T09:35:00Z
    ]
}`;
}

/++
How $(LREF CsvKind) are represented.
+/
unittest
{
    auto text = 
`Date,Open,High,Low,Close,Volume
2021-01-21 09:30:00,133.8,134.43,133.59,134.0,9166695
2021-01-21 09:35:00,134.25,135.0,134.19,134.5,4632863`;
        
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

    csv.serializeText.should == q{[[str,b],[2022-10-12,2022-10-13],[3.4,2]]};

    alias T = Tuple!(string[], Date[], double[]);

    csv.serde!T.should == T (
        [`str`, `b`],
        [Date(2022, 10, 12), Date(2022, 10, 13)],
        [3.4, 2],
    );
}

/// Converting NA to NaN
unittest
{
    import mir.csv;
    import mir.algebraic: Nullable, visit;
    import mir.ion.conv: serde;
    import mir.ndslice: Slice, map, slice;
    import mir.ser.text: serializeText;
    import mir.test: should;

    auto text = "1,2\n3,4\n5,#N/A\n";
    auto matrix = text
        .Csv
        .serde!(Slice!(Nullable!double*, 2))
        .map!(visit!((double x) => x, (_) => double.nan))
        .slice;

    matrix.serializeText.should == q{[[1.0,2.0],[3.0,4.0],[5.0,nan]]};
}
