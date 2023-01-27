Ddoc

$(P Dlang Statistical Package.)

$(P The following table is a quick reference guide for which Mir Stat modules to
use for a given category of functionality.)


$(BOOKTABLE ,
    $(TR
        $(TH Modules)
        $(TH Description)
    )
    $(TR $(TDNW $(MREF mir,stat)) $(TD Publicly imports `mir.stat.*` modules ))
    $(LEADINGROW Descriptive Statistics)
    $(TR $(TDNW $(MREF mir,stat,descriptive)) $(TD Descriptive statistics ))
    $(TR $(TDNW $(MREF mir,stat,descriptive,univariate)★) $(TD Univariate Descriptive statistics ))
    $(TR $(TDNW $(MREF mir,stat,descriptive,weighted)) $(TD Descriptive statistics with weights ))
    $(LEADINGROW Other Statistical Algorithms)
    $(TR $(TDNW $(MREF mir,stat,transform)) $(TD Algorithms for transforming data ))
    $(TR $(TDNW $(MREF mir,stat,inference)) $(TD Algorithms for statistical inference ))
    $(LEADINGROW Probability Distributions)
    $(TR $(TDNW $(MREF mir,stat,distribution)★) $(TD Statistical Distributions ))
    $(TR $(TDNW $(MREF mir,stat,distribution,pdf)) $(TD Probability Density Functions ))
    $(TR $(TDNW $(MREF mir,stat,distribution,cdf)) $(TD Cumulative Distribution Functions ))
    $(TR $(TDNW $(MREF mir,stat,distribution,invcdf)) $(TD Inverse Cumulative Distribution Functions ))
)

Copyright: 2022-3 Mir Stat Authors.

Macros:
        TITLE=Mir Stat
        WIKI=Mir Stat
        DDOC_BLANKLINE=
        _=