Ddoc

$(P JSON Parsing and Serialization library.)

$(P The following table is a quick reference guide for which Mir Core modules to
use for a given category of functionality.)

$(BOOKTABLE ,
    $(TR
        $(TH Modules)
        $(TH Description)
    )
    $(TR $(TDNW $(MREF mir,algebraic)) $(TD Generic variant and nullable types ))
    $(TR $(TDNW $(MREF mir,exception)) $(TD @nogc MirException with formatting))
    $(TR $(TDNW $(MREF mir,reflection)) $(TD Compile time reflection utilities ))
    $(TR
        $(TDNW $(MREF mir,bitmanip))
        $(TD Bit-level manipulation facilities)
    )
    $(TR
        $(TDNW $(MREF mir,conv))
        $(TD Conversion utilities)
    )
    $(TR
        $(TDNW $(MREF mir,functional))
        $(TD Functions that manipulate other functions)
    )
    $(TR
        $(TDNW $(MREF mir,primitives))
        $(TD Templates used to check primitives and 
range primitives for arrays with multi-dimensional like API support)
    )
    $(TR
        $(TDNW $(MREF mir,qualifier))
        $(TD Const and Immutable qualifiers helpers for Mir Type System.)
    )
    $(TR
        $(TDNW $(MREF mir,utility))
        $(TD Utilities)
    )
    $(TR
        $(TDNW $(MREF mir,enums))
        $(TD Utilities to work with enums)
    )
    $(TR
        $(TDNW $(MREF mir,string_table))
        $(TD Mir String Table designed for fast deserialization routines)
    )
    $(LEADINGROW Integer Routines)
    $(TR
        $(TDNW $(MREF mir,bitop))
        $(TD A collection of bit-level operations)
    )
    $(TR
    $(TDNW $(MREF mir,checkedint))
        $(TD Integral arithmetic primitives that check for out-of-range results)
    )
    $(LEADINGROW Basic Math)
    $(TR
        $(TDNW $(MREF mir,math))
        $(TD Publicly imports
            $(MREF mir,math,common),
            $(MREF mir,math,constant),
            $(MREF mir,math,ieee).
        )
    )
    $(TR
        $(TDNW $(MREF mir,math,common))
        $(TD Common floating point math functions)
    )
    $(TR
        $(TDNW $(MREF mir,complex))
        $(TD Generic complex type)
    )
    $(TR
        $(TDNW $(MREF mir,complex,math))
        $(TD Basic complex math)
    )
    $(TR
        $(TDNW $(MREF mir,math,constant))
        $(TD Math constants)
    )
    $(TR
        $(TDNW $(MREF mir,math,ieee))
        $(TD Base floating point routines)
    )
)

Copyright: Copyright © 2020-, Ilia Ki.

Macros:
        TITLE=Mir Core
        WIKI=Mir Core
        DDOC_BLANKLINE=
        _=
