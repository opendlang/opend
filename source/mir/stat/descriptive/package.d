/++
This package publicly imports `mir.stat.descriptive.*` modules.

$(BOOKTABLE ,
    $(TR
        $(TH Modules)
        $(TH Description)
    )
    $(TR $(TDNW $(MREF mir,stat,descriptive,aliases)) $(TD Aliases for common functions ))
    $(TR $(TDNW $(MREF mir,stat,descriptive,multivariate)) $(TD Multivariate Descriptive statistics ))
    $(TR $(TDNW $(MREF mir,stat,descriptive,univariate)) $(TD Univariate Descriptive statistics ))
    $(TR $(TDNW $(MREF mir,stat,descriptive,weighted)) $(TD Descriptive statistics with weights ))
)

License: $(HTTP www.apache.org/licenses/LICENSE-2.0, Apache-2.0)

Authors: John Michael Hall, Ilya Yaroshenko

Copyright: 2022-3 Mir Stat Authors.

Macros:
SUBREF = $(REF_ALTTEXT $(TT $2), $2, mir, stat, $1)$(NBSP)
MATHREF = $(GREF_ALTTEXT mir-algorithm, $(TT $2), $2, mir, math, $1)$(NBSP)
NDSLICEREF = $(GREF_ALTTEXT mir-algorithm, $(TT $2), $2, mir, ndslice, $1)$(NBSP)
T2=$(TR $(TDNW $(LREF $1)) $(TD $+))
T4=$(TR $(TDNW $(LREF $1)) $(TD $2) $(TD $3) $(TD $4))

+/

module mir.stat.descriptive;

///
public import mir.stat.descriptive.aliases;
///
public import mir.stat.descriptive.multivariate;
///
public import mir.stat.descriptive.univariate;
///
public import mir.stat.descriptive.weighted;
