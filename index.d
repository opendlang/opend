Ddoc

$(P Professional Random Number Generators.)

$(P The following table is a quick reference guide for which Mir Random modules to
use for a given category of functionality.)

$(BOOKTABLE ,
    $(TR
        $(TH Modules)
        $(TH Description)
    )
    $(LEADINGROW Basic API)
    $(TR
        $(TDNW $(MREF mir,random))
        $(TD Basic API to generate random numbers. Contains generic
            $(REF_ALTTEXT $(TT rand), rand, mir, random)
            function that generates real, integral, boolean, and enumerated uniformly distributed values.
            Publicly includes $(MREF mir,random,engine).)
    )
    $(LEADINGROW Random Variables)
    $(TR
        $(TDNW $(MREF mir,random,variable))
        $(TD
            Random variables for uniform, exponential, gamma, normal, and other distributions.
        )
    )
    $(LEADINGROW Integration with Phobos)
    $(TR
        $(TDNW $(MREF mir,random,algorithm))
        $(TD
            $(REF_ALTTEXT $(TT Random ndslices and ranges), RandomRange, mir, random, algorithm).
        )
    )
    $(LEADINGROW Entropy Generators)
    $(TR
        $(TDNW $(MREF mir,random,engine))
        $(TD
            $(REF_ALTTEXT $(TT unpredictableSeed), unpredictableSeed, mir, random, engine),
            $(REF_ALTTEXT $(TT Random), Random, mir, random, engine) alias, common engine API.
        )
    )
    $(TR
        $(TDNW $(MREF mir,random,engine,linear_congruential))
        $(TD $(HTTP en.wikipedia.org/wiki/Linear_congruential_generator, Linear Congruential) generator.)
    )
    $(TR
        $(TDNW $(MREF mir,random,engine,mersenne_twister))
        $(TD $(HTTP en.wikipedia.org/wiki/Mersenne_Twister, Mersenne Twister)  generator.)
    )
    $(TR
        $(TDNW $(MREF mir,random,engine,xorshift))
        $(TD $(HTTP en.wikipedia.org/wiki/Xorshift, Xorshift) generator.)
    )
)

Copyright: Copyright © 2016-, Ilya Yaroshenko.

Macros:
        TITLE=Mir Random
        WIKI=Mir Random
        DDOC_BLANKLINE=
        _=