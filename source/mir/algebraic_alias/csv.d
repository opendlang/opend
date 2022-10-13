/++
$(H1 Mutable CSV scalar value)

This module contains a single alias definition and doesn't provide CSV serialization API.

License: $(HTTP www.apache.org/licenses/LICENSE-2.0, Apache-2.0)
Authors: Ilia Ki 
Macros:
+/
module mir.algebraic_alias.csv;
/++
Definition union for $(LREF JsonAlgebraic).
+/
import mir.algebraic: Variant;

import mir.algebraic: Algebraic;

public import mir.timestamp: Timestamp;

/++
CSV tagged algebraic alias.
+/
alias CsvAlgebraic = Algebraic!Csv_;

///
union Csv_
{
    /// Used for empty CSV scalar like one between two separators: `,,`
    typeof(null) null_;
    /// Used for false, true, False, True, and friends. Follows YAML conversion
    bool boolean;
    ///
    long integer;
    ///
    double float_;
    ///
    Timestamp timestamp;
    ///
    immutable(char)[] string;
}

///
version(mir_ion_test)
unittest
{
    CsvAlgebraic value;

    // Default
    assert(value.isNull);
    assert(value.kind == CsvAlgebraic.Kind.null_);

    // Boolean
    value = true;

    assert(!value.isNull);
    assert(value == true);
    assert(value.kind == CsvAlgebraic.Kind.boolean);
    assert(value.boolean == true);
    assert(value.get!bool == true);
    assert(value.get!(CsvAlgebraic.Kind.boolean) == true);

    // Null
    value = null;
    assert(value.isNull);
    assert(value == null);
    assert(value.kind == CsvAlgebraic.Kind.null_);
    assert(value.null_ == null);
    assert(value.get!(typeof(null)) == null);
    assert(value.get!(CsvAlgebraic.Kind.null_) == null);

    // String
    value = "s";
    assert(value.kind == CsvAlgebraic.Kind.string);
    assert(value == "s");
    assert(value.string == "s");
    assert(value.get!string == "s");
    assert(value.get!(CsvAlgebraic.Kind.string) == "s");

    // Integer
    value = 4;
    assert(value.kind == CsvAlgebraic.Kind.integer);
    assert(value == 4);
    assert(value != 4.0);
    assert(value.integer == 4);

    // Float
    value = 3.0;
    assert(value.kind == CsvAlgebraic.Kind.float_);
    assert(value != 3);
    assert(value == 3.0);
    assert(value.float_ == 3.0);
    assert(value.get!double == 3.0);
    assert(value.get!(CsvAlgebraic.Kind.float_) == 3.0);
}
