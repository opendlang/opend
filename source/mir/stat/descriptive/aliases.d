/++
This module contains aliases of common functions.

License: $(HTTP www.apache.org/licenses/LICENSE-2.0, Apache-2.0)

Authors: John Michael Hall

Copyright: 2023 Mir Stat Authors.

Macros:
SUBREF = $(REF_ALTTEXT $(TT $2), $2, mir, stat, $1)$(NBSP)
SUB2REF = $(REF_ALTTEXT $(TT $2), $2, mir, stat, descriptive, $1)$(NBSP)
MATHREF = $(GREF_ALTTEXT mir-algorithm, $(TT $2), $2, mir, math, $1)$(NBSP)
NDSLICEREF = $(GREF_ALTTEXT mir-algorithm, $(TT $2), $2, mir, ndslice, $1)$(NBSP)
T2=$(TR $(TDNW $(LREF $1)) $(TD $+))
T3=$(TR $(TDNW $(LREF $1)) $(TD $2) $(TD $+))
T4=$(TR $(TDNW $(LREF $1)) $(TD $2) $(TD $3) $(TD $4))

+/

module mir.stat.descriptive.aliases;

import mir.stat.descriptive.univariate: standardDeviation, variance, skewness,
                                        kurtosis, coefficientOfVariation,
                                        interquartileRange, medianAbsoluteDeviation;
import mir.stat.descriptive.multivariate: covariance, correlation;

// From univariate
///
alias sd = standardDeviation;
///
alias var = variance;
///
alias skew = skewness;
///
alias kurt = kurtosis;
///
alias cv = coefficientOfVariation;
///
alias iqr = interquartileRange;
///
alias mad = medianAbsoluteDeviation;


// From multivariate
///
alias cov = covariance;
///
alias cor = correlation;
