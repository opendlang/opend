/++
$(H2 CSV/TSV parsing)

DRAFT

$(LREF CsvProxy) can be serialized to Ion, JSON, MsgPack, or YAML
and then deserialized to a specified type.
That approachs allows to use the same mir deserialization
pattern like for other data types.
$(IONREF conv, serde) unifies this two steps throught binary Ion format,
which serves as an efficient DOM representation for all other formats.

Macros:
    IONREF = $(REF_ALTTEXT $(TT $2), $2, mir, ion, $1)$(NBSP)
    AlgorithmREF = $(GREF_ALTTEXT mir-algorithm, $(TT $2), $2, mir, $1)$(NBSP)
    NDSLICEREF = $(GREF_ALTTEXT mir-algorithm, $(TT $2), $2, mir, ndslice, $1)$(NBSP)
    AAREF = $(REF_ALTTEXT $(TT $2), $2, mir, algebraic_alias, $1)$(NBSP)
+/

module mir.csv;

import mir.primitives: isOutputRange;
import mir.serde: SerdeTarget;
import mir.ndslice.slice: Slice, SliceKind;
import mir.string_map: StringMap;

///
public import mir.algebraic_alias.csv: CsvAlgebraic;

/++
A proxy that allows to converty CSV to a table in another data format.
+/
struct CsvProxy
{
    import mir.algebraic_alias.csv: CsvAlgebraic;
    import mir.ion.exception: IonMirException;
    /// An input CSV text. BOM isn't supported.
    const(char)[] text;
    /// If true the elements in the first row are symbolised.
    bool hasHeader;
    /// Scalar separator
    char separator = ',';
    /// Symbol to quote scalars
    char quote = '"';
    /// Skips rows the first consequent lines, which starts with this character.
    char comment = '\0';
    /// Skips a number of rows
    ubyte skipRows;
    /// If true the parser tries to recognsise and parse numbers.
    bool parseNumbers = true;
    /// If true the parser tries to recognsise and parse
    // ISO timestamps in the extended form.
    bool parseTimestamps = true;

    /// A number of conversion conventions.
    struct Conversion
    {
        ///
        string from;
        ///
        CsvAlgebraic to;
    }

    /++
    The conversion map represented as array of `from->to` pairs.

    Note:
    automated number recognition works with values like `NaN` and `+Inf` already.
    +/
    const(Conversion)[] conversions = [
        Conversion("", null.CsvAlgebraic),
        Conversion("TRUE", true.CsvAlgebraic),
        Conversion("FALSE", false.CsvAlgebraic),
    ];

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
        import mir.bignum.decimal: Decimal, DecimalExponentKey;
        import mir.exception: MirException;
        import mir.ser: serializeValue;
        import mir.timestamp: Timestamp;
        import mir.utility: _expect;

        auto table = CsvReader(
            text,
            separator,
            quote,
            comment,
            skipRows,
        );

        if (hasHeader && table.empty)
        {
            serializer.putValue(null);
            return;
        }

        bool quoted;
        DecimalExponentKey decimalKey;
        Decimal!128 decimal = void;
        Timestamp timestamp;

        size_t outerState = serializer.listBegin;

        if (hasHeader)
        {
            serializer.elemBegin;
            auto state = serializer.listBegin;
            foreach (elem; table.front)
            {
                assert(!elem.error);
                serializer.elemBegin;
                serializer.putSymbol(elem.value);
            }
            serializer.listEnd(state);
            table.popFront;
        }

        do
        {
            serializer.elemBegin;
            auto state = serializer.listBegin;
            auto row = table.front;
            do
            {
                auto elem = row.front;

                if (_expect(elem.error, false)) 
                    row.validateCsvError(elem.error);

                CsvAlgebraic scalar;

                enum bool allowSpecialValues = true;
                enum bool allowDotOnBounds = true;
                enum bool allowDExponent = true;
                enum bool allowStartingPlus = true;
                enum bool allowUnderscores = false;
                enum bool allowLeadingZeros = false;
                enum bool allowExponent = true;
                enum bool checkEmpty = true;

                if (_expect(elem.wasQuoted, false))
                {
                    scalar = cast(string) elem.value;
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
                    (elem.value, decimalKey))
                {
                    if (decimalKey)
                        scalar = cast(double) decimal;
                    else
                        scalar = cast(long) decimal.coefficient;
                }
                else
                if (parseTimestamps && Timestamp.fromISOExtString(elem.value, timestamp))
                {
                    scalar = timestamp;
                }
                else
                {
                    foreach(ref target; conversions)
                    {
                        if (elem.value == target.from)
                        {
                            scalar = target.to;
                            goto Finalizer;
                        }
                    }
                    scalar = cast(string) elem.value;
                }

            Finalizer:
                if (_expect(conversionFinalizer !is null, false))
                {
                    scalar = conversionFinalizer(elem.value, scalar, quoted, row.columnIndex);
                }
                serializer.elemBegin;
                serializer.serializeValue(scalar);                
                row.popFront;
            }
            while(!row.empty);
            serializer.listEnd(state);
            table.popFront;
        }
        while (!table.empty);
        serializer.listEnd(outerState);
    }
}

/++
Rapid CSV reader represented as a range of rows.

The structure isn't copyable. Please use it's pointer with range modifiers.

Exactly one call of `empty` has to be preciding each call of `front`.
Exactly one call of `popFront` has to be following each call of `front`.
Some Phobos functions doesn't follow this rule.

All elements of the each row have to be accessed exactly once before
the next row can be processed.
+/
struct CsvReader
{
    import mir.appender: ScopedBuffer, scopedBuffer;
    import mir.utility: _expect;
    import mir.string: scanLeftAny;

    /// An input CSV text. BOM isn't supported.
    const(char)[] text;
    ///
    uint rowLength;
    ///
    uint rowIndex;
    /// Scalar separator
    char separator = ',';
    /// Symbol to quote scalars
    char quote = '"';

    private ScopedBuffer!(char, 128) buffer;

    /++
    +/
    enum Error
    {
        ///
        none,
        // ///
        // missingLeftQuote,
        ///
        unexpectedSeparator,
        ///
        unexpectedRowEnd,
    }

    /++
    CSV cell element
    +/
    struct Scalar
    {
        /++
        Unquoted string.

        $(LREF .CsvReader.Scalar.wasQuoted) is set, then the value refers
        $(LREF .CsvRow.buffer) and valid only until the next quoted string is produced.
        +/
        const(char)[] value;

        bool wasQuoted;
        /++
        If the flag is true the $(LREF .CsvReader.Scalar.value) member refers the $(LREF .CsvRow.buffer) the original text,
        otherwise it .
        +/
        bool isScopeAllocated;

        /++
        +/
        Error error;
    }

    /++
    CSV Row Input Range

    Exactly one call of `empty` has to be preciding each call of `front`.
    Exactly one call of `popFront` has to be following each call of `front`.
    Some Phobos functions doesn't follow this rule.
    +/
    struct Row
    {
        private CsvReader* root;
        ///
        uint length;

        /++
        Throws: MirIonException if the $(LREF CsvReader.Error) is set.
        Returns: `void`
        +/
        auto validateCsvError(CsvReader.Error error)
            scope const @safe pure
        {
            import mir.ion.exception: IonMirException;

            final switch (error)
            {
                case CsvReader.Error.none: break;
                // case CsvReader.Error.missingLeftQuote: throw new IonMirException("mir.csv: missing left quote when parsing element at index [", root.rowIndex, ", ", columnIndex, "]");
                case CsvReader.Error.unexpectedSeparator: throw new IonMirException("mir.csv: unexpected separator when parsing element at index [", root.rowIndex, ", ", columnIndex, "]");
                case CsvReader.Error.unexpectedRowEnd: throw new IonMirException("mir.csv: unexpected row end when parsing element at index [", root.rowIndex, ", ", columnIndex, "]");
            }
        }

        ///
        bool empty()() scope const pure nothrow @nogc @property
            in (root)
        {
            return length == 0;
        }

        /++
        The function has be called after the front value is precessed.
        +/
        void popFront()() scope pure nothrow @nogc
            in (root)
        {
            length--;
        }

        ///
        Scalar front()() return scope pure nothrow @nogc @property
            in (root)
            in (length)
            in (length == 1 || root.text.length)
        {
            auto scalar = root.readCell();
            // if (_expect(!scalar.error, true))
            with (root)
            {
                if (text.length && text[0] == separator)
                {
                    text = text.ptr[1 .. text.length];
                    if (_expect(length == 1, false))
                        scalar.error = Error.unexpectedSeparator;
                }
                else
                {
                    if (text.length)
                        text = text.ptr[1 + (text.length > 1 && text[0] == '\r' && text[1] == '\n') .. text.length];
                    if (_expect(length != 1, false))
                        scalar.error = Error.unexpectedRowEnd;
                }
            }
            return scalar;
        }

        uint columnIndex()() scope const @safe pure nothrow @nogc
            in (root)
        {
            return root.rowLength - length;
        }
    }

    ///
    bool empty()() scope const pure nothrow @nogc @property
    {
        return text.length == 0;
    }

    /++
    The function has be called after the all row cell values have been precessed.
    +/
    void popFront()() scope pure nothrow @nogc
    {
        rowIndex++;
    }

    ///
    Row front()() scope return pure nothrow @nogc @property
    {
        return typeof(return)(&this, rowLength);
    }

    /++
    Throws: throws an exception if the first row is exists and invalid.
    +/
    this(
        return scope const(char)[] text,
        char separator = ',',
        char quote = '"',
        char comment = '\0',
        sizediff_t skipRows = 0,
    ) @safe pure @nogc
    {
        pragma(inline, false);

        while (text.length && (skipRows-- || text[0] == comment))
        {
            auto next = text.scanLeftAny('\r', '\n');
            text = text[$ - next.length + (next.length >= 1) + (next.length > 1 && next[0] == '\r' && next[1] == '\n') .. $];
        }

        this.text = text;
        this.separator = separator;
        this.quote = quote;

        if (this.text.length == 0)
            return;

        for (;;)
        {
            this.rowLength++;
            auto scalar = readCell();
            if (scalar.error)
            {
                import mir.ion.exception: IonException;
                static immutable exc = new IonException("mir.csv: left double quote is missing in the first row");
                throw exc;

            }
            if (this.text.length && this.text[0] == separator)
            {
                this.text = this.text[1 .. $];
                continue;
            }
            if (this.text.length)
                this.text = this.text[1 + (this.text.length > 1 && this.text[0] == '\r' && this.text[1] == '\n') .. $];
            break;
        }

        this.text = text;
    }

    private Scalar readCell()() scope return @trusted pure nothrow @nogc
    {
        // if skipLeftSpaces// TODO then stripLeft csv
        auto quoted = text.length && text[0] == quote;
        if (!quoted)
        {
            auto next = text.scanLeftAny(separator, '\r', '\n');
            auto ret = text[0 .. text.length - next.length];
            text = text.ptr[text.length - next.length .. text.length];
            return Scalar(ret);
        }
        buffer.reset;

        assert(text.length);
        assert(text[0] == quote);
        text = text.ptr[1 .. text.length];

        for (;;)
        {
            auto next = text.scanLeftAny(quote);

            auto isQuote = next.length > 1 && next[1] == quote;
            auto ret = text[0 .. text.length - next.length + isQuote];
            text = text.ptr[text.length - next.length + isQuote + (next.length != 0) .. text.length];

            if (!isQuote && buffer.data.length == 0)
                return Scalar(ret, true);

            buffer.put(ret);

            if (!isQuote)
                return Scalar(buffer.data, true, true);
        }
    }
}

/++
Returns: $(NDSLICEREF slice, Slice)`!(string*, 2)`.
See_also: $(LREF stringMatrixToStringMap)
+/
Slice!(string*, 2) csvToStringMatrix(
    return scope string text,
    char separator = ',',
    char quote = '"',
    char comment = '\0',
    ubyte skipRows = 0,
) @trusted pure
{
    pragma(inline, false);

    import mir.ndslice.slice: Slice;
    import mir.utility: _expect;
    import std.array: appender;

    auto app = appender!(string[]);
    app.reserve(text.length / 32);

    auto table = CsvReader(
        text,
        separator,
        quote,
        comment,
        skipRows,
    );

    auto wip = new string[table.rowLength];

    while (!table.empty)
    {
        auto row = table.front;
        do
        {
            auto elem = row.front;
            if (_expect(elem.error, false)) 
                row.validateCsvError(elem.error);

            auto value = cast(string) elem.value;
            if (_expect(elem.isScopeAllocated, false))
                value = value.idup;

            wip[row.columnIndex] = value;
            row.popFront;
        }
        while(!row.empty);
        app.put(wip);
        table.popFront;
    }

    import mir.ndslice: sliced;
    assert (app.data.length == table.rowIndex * table.rowLength);
    return app.data.sliced(table.rowIndex, table.rowLength);
}

///
version (mir_ion_test)
@safe pure
unittest
{
    auto data = `012,abc,"mno pqr",0` ~ "\n" ~ `982,def,"stuv wx",1`
        ~ "\n" ~ `78,ghijk,"yx",2`;

    auto matrix = data.csvToStringMatrix();

    import mir.ndslice.slice: Slice, SliceKind;

    static assert(is(typeof(matrix) == Slice!(string*, 2)));

    import mir.test: should;
    matrix.should ==
    [[`012`, `abc`, `mno pqr`, `0`], [`982`, `def`, `stuv wx`, `1`], [`78`, `ghijk`, `yx`, `2`]];

    import mir.ndslice.dynamic: transposed;
    auto transp = matrix.transposed;
    static assert(is(typeof(transp) == Slice!(string*, 2, SliceKind.universal)));

    transp.should ==
    [[`012`, `982`, `78`], [`abc`, `def`, `ghijk`], [`mno pqr`, `stuv wx`, `yx`], [`0`, `1`, `2`]];
}

version (mir_ion_test)
@safe pure
unittest
{
    // Optional parameters to csvToStringMatrix
    auto data = `012;abc;"mno pqr";0` ~ "\n" ~ `982;def;"stuv wx";1`
        ~ "\n" ~ `78;ghijk;"yx";2`;

    import mir.test: should;
    data.csvToStringMatrix(';', '"').should ==
    [["012", "abc", "mno pqr", "0"], ["982", "def", "stuv wx", "1"], ["78", "ghijk", "yx", "2"]];
}

version (mir_ion_test)
@safe pure
unittest
{
    auto data = `012,aa,bb,cc` ~ "\r\n" ~ `982,dd,ee,ff` ~ "\r\n"
        ~ `789,gg,hh,ii` ~ "\r\n";

    import mir.test: should;
    data.csvToStringMatrix.should ==
    [["012", "aa", "bb", "cc"], ["982", "dd", "ee", "ff"], ["789", "gg", "hh", "ii"]];
}

version (mir_ion_test)
@safe pure
unittest
{
    // Optional parameters here too
    auto data = `012;aa;bb;cc` ~ "\r\n" ~ `982;dd;ee;ff` ~ "\r\n"
        ~ `789;gg;hh;ii` ~ "\r\n";

    import mir.test: should;
    data.csvToStringMatrix(';', '"').should ==
    [["012", "aa", "bb", "cc"], ["982", "dd", "ee", "ff"], ["789", "gg", "hh", "ii"]];
}

version (mir_ion_test)
@safe pure
unittest
{
    // Quoted fields that contains newlines and delimiters
    auto data = `012,abc,"ha ha ` ~ "\n" ~ `ha this is a split value",567`
        ~ "\n" ~ `321,"a,comma,b",def,111` ~ "\n";

    import mir.test: should;
    data.csvToStringMatrix.should ==
    [["012", "abc", "ha ha \nha this is a split value", "567"], ["321", "a,comma,b", "def", "111"]];
}

version (mir_ion_test)
@safe pure
unittest
{
    // Quoted fields that contains newlines and delimiters, optional parameters for csvToStringMatrix
    auto data = `012;abc;"ha ha ` ~ "\n" ~ `ha this is a split value";567`
        ~ "\n" ~ `321;"a,comma,b";def;111` ~ "\n";

    import mir.test: should;
    data.csvToStringMatrix(';', '"').should ==
    [["012", "abc", "ha ha \nha this is a split value", "567"], ["321", "a,comma,b", "def", "111"]];
}

version (mir_ion_test)
@safe pure
unittest
{
    // Quoted fields that contain quotes
    // (Note: RFC-4180 does not allow doubled quotes in unquoted fields)
    auto data = `012,"a b ""haha"" c",982` ~ "\n";

    import mir.test: should;
    data.csvToStringMatrix.should == [["012", `a b "haha" c`, "982"]];
}

version (mir_ion_test)
@safe pure
unittest
{
    // Quoted fields that contain quotes, optional parameters for csvToStringMatrix
    // (Note: RFC-4180 does not allow doubled quotes in unquoted fields)
    auto data = `012;"a b ""haha"" c";982` ~ "\n";

    import mir.test: should;
    data.csvToStringMatrix(';', '"').should == [["012", `a b "haha" c`, "982"]];
}

version (mir_ion_test)
@safe pure
unittest
{
    // Trailing empty fields (bug#1522)
    import mir.test: should;

    auto data = `,` ~ "\n";
    data.csvToStringMatrix.should == [["", ""]];

    data = `,,` ~ "\n";
    data.csvToStringMatrix.should == [["", "", ""]];

    data = "a,b,c,d" ~ "\n" ~ ",,," ~ "\n" ~ ",,," ~ "\n";
    data.csvToStringMatrix.should == 
    [["a", "b", "c", "d"], ["", "", "", ""], ["", "", "", ""]];

    data = "\"a\",b,c,\"d\",";
    data.csvToStringMatrix.should == [["a", "b", "c", "d", ""]];

    data = "\"\",\"\",";
    data.csvToStringMatrix.should == [["", "", ""]];
}

// Boundary condition checks
version (mir_ion_test)
@safe pure
unittest
{
    import mir.test: should;

    auto data = `012,792,"def""`;
    data.csvToStringMatrix.should == [[`012`, `792`, `def"`]];

    data = `012,792,"def""012`;
    data.csvToStringMatrix.should == [[`012`, `792`, `def"012`]];

    data = `012,792,"a"`;
    data.csvToStringMatrix.should == [[`012`, `792`, `a`]];

    data = `012,792,"`;
    data.csvToStringMatrix.should == [[`012`, `792`, ``]];

    data = `012;;311`;
    data.csvToStringMatrix(';').should == [[`012`, ``, `311`]];
}

/++
Represent CSV data as dictionary of columns.
Uses the first row as header.
Returns: a string map that refers the same header and the same data.
+/
StringMap!(Slice!(string*, 1, SliceKind.universal))
    stringMatrixToStringMap(return scope Slice!(string*, 2) matrix)
    @trusted pure
{
    import mir.array.allocation: array;
    import mir.ion.exception: IonException;
    import mir.ndslice.topology: byDim;
    if (matrix.length == 0)
        throw new IonException("mir.csv: Matrix should have at least a single row to get the header");
    return typeof(return)(matrix[0].field, matrix[1 .. $].byDim!1.array);
}

///
version (mir_ion_test)
@safe pure
unittest
{
    import mir.test: should;

    auto data = "a,b,c\n1,2,3\n4,5,6\n7,8,9\n10,11,12";

    import mir.ndslice.topology: as, map;
    auto table = data
        .csvToStringMatrix
        .stringMatrixToStringMap;

    
    table["a"].should == ["1", "4", "7", "10"];

    table.keys.should == ["a", "b", "c"];
    table.values
        .map!(column => column[].as!double)
        .should == [
        [1, 4, 7, 10], // first column
        [2, 5, 8, 11], // ...
        [3, 6, 9, 12]];
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

    /// Scalar separator
    char separator = ',';
    /// Symbol to quote scalars
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
    import mir.ser.text;

    alias Matrix = Slice!(double*, 2);

    auto text = "1,2\n3,4\r\n5,6\n";

    auto matrix = text.CsvProxy.serde!Matrix;
    matrix.should == [[1, 2], [3, 4], [5, 6]];
}

// First draft
version(none):

///
unittest
{
    import mir.csv;
    import mir.ion.conv: serde; // to convert CsvProxy to D types
    import mir.serde: serdeKeys, serdeIgnoreUnexpectedKeys, serdeOptional;
    // mir.date and std.datetime are supported as well
    import mir.timestamp: Timestamp;//mir-algorithm package
    import mir.test: should;

    auto text =
`Date,Open,High,Low,Close,Volume
2021-01-21 09:30:00,133.8,134.43,133.59,134.0,9166695
2021-01-21 09:35:00,134.25,135.0,134.19,134.5,4632863`;

    CsvProxy csv = {
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

    CsvProxy csv = {
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

    // Serializing CsvProxy to Amazon Ion (text version)
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
    import mir.ion.conv: serde; // to convert CsvProxy to DataFrame
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

    CsvProxy csv = {
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
    auto matrix = text.CsvProxy.serde!Matrix;
    matrix.should == [[1, 2], [3, 4], [5, 6]];

    CsvProxy csv = {
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

    CsvProxy csv = {
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
        .CsvProxy
        .serde!(Slice!(Nullable!double*, 2))
        .map!(visit!((double x) => x, (_) => double.nan))
        .slice;

    matrix.serializeText.should == q{[[1.0,2.0],[3.0,4.0],[5.0,nan]]};
}
