/++
This package publicly imports `mir.stat.distribution.*` modules.

Each individual distribution module contains - when feasible - functions for:
- Probability density/mass functions (e.g. `distributionPDF`/`distributionPMF`)
- Cumulative distriution functions (e.g. `distributionCDF`)
- Complementary cumulative distribution functions (e.g. `distributionCCDF`)
- Inverse cumulative distribution functions (e.g. `distributionInvCDF`)
- Log probaiity density/mass functions (e.g. `distributionLPDF`/`distributionLPMF`)

In addition, convenience modules are provided (`mir.stat.distribution.pdf`, 
`mir.stat.distribution.cdf`, `mir.stat.distribution.invcdf`) that publicly
import only the respective functions from each individual distribution module 
(note: the pdf module also contains pmfs). 

Some (discrete) distributions include multiple algorithms for calculating the
included functions. The default is a direct calculation with others being
approximations. As a convention, these modules leave it to te user to determine
when to switch between the different approximations. Care should be taken if
more extreme parameters are used as it can have an impact on speed.

$(BOOKTABLE ,
    $(TR
        $(TH Modules)
        $(TH Description)
    )
    $(LEADINGROW Convenience Modules (with public imports))
    $(TR $(TDNW $(MREF mir,stat,distribution)) $(TD Statistical Distributions ))
    $(TR $(TDNW $(MREF mir,stat,distribution,pdf)) $(TD Probability Density Functions ))
    $(TR $(TDNW $(MREF mir,stat,distribution,cdf)) $(TD Cumulative Distribution Functions ))
    $(TR $(TDNW $(MREF mir,stat,distribution,invcdf)) $(TD Inverse Cumulative Distribution Functions ))
    $(LEADINGROW Univariate Discrete Distributions)
    $(TR $(TDNW $(MREF mir,stat,distribution,bernoulli)) $(TD Bernoulli Distribution ))
    $(TR $(TDNW $(MREF mir,stat,distribution,binomial)) $(TD Binomial Distribution ))
    $(TR $(TDNW $(MREF mir,stat,distribution,geometric)) $(TD Geometric Distribution ))
    $(TR $(TDNW $(MREF mir,stat,distribution,hypergeometric)) $(TD Hypergeometric Distribution ))
    $(TR $(TDNW $(MREF mir,stat,distribution,negative_binomial)) $(TD Negative Binomial Distribution ))
    $(TR $(TDNW $(MREF mir,stat,distribution,uniform_discrete)) $(TD Discrete Uniform Distribution ))
    $(LEADINGROW Univariate Continuous Distributions)
    $(TR $(TDNW $(MREF mir,stat,distribution,beta)) $(TD Beta Distribution ))
    $(TR $(TDNW $(MREF mir,stat,distribution,beta_proportion)) $(TD Beta Proportion Distribution ))
    $(TR $(TDNW $(MREF mir,stat,distribution,cauchy)) $(TD Cauchy Distribution ))
    $(TR $(TDNW $(MREF mir,stat,distribution,chi2)) $(TD Chi-squared Distribution ))
    $(TR $(TDNW $(MREF mir,stat,distribution,cornisher_fisher)) $(TD Cornish-Fisher Expansion ))
    $(TR $(TDNW $(MREF mir,stat,distribution,exponential)) $(TD Exponential Distribution ))
    $(TR $(TDNW $(MREF mir,stat,distribution,f)) $(TD F Distribution ))
    $(TR $(TDNW $(MREF mir,stat,distribution,gamma)) $(TD Gamma Distribution ))
    $(TR $(TDNW $(MREF mir,stat,distribution,generalized_pareto)) $(TD Generalized Pareto Distribution ))
    $(TR $(TDNW $(MREF mir,stat,distribution,gev)) $(TD Generalized Extreme Value (GEV) Distribution ))
    $(TR $(TDNW $(MREF mir,stat,distribution,laplace)) $(TD Laplace Distribution ))
    $(TR $(TDNW $(MREF mir,stat,distribution,log_normal)) $(TD Log-normal Distribution ))
    $(TR $(TDNW $(MREF mir,stat,distribution,logistic)) $(TD Logistic Distribution ))
    $(TR $(TDNW $(MREF mir,stat,distribution,normal)) $(TD Normal Distribution ))
    $(TR $(TDNW $(MREF mir,stat,distribution,pareto)) $(TD Pareto Distribution ))
    $(TR $(TDNW $(MREF mir,stat,distribution,poisson)) $(TD Poisson Distribution ))
    $(TR $(TDNW $(MREF mir,stat,distribution,rayleigh)) $(TD Rayleigh Distribution ))
    $(TR $(TDNW $(MREF mir,stat,distribution,students_t)) $(TD Student's t Distribution ))
    $(TR $(TDNW $(MREF mir,stat,distribution,uniform)) $(TD Continuous Uniform Distribution ))
    $(TR $(TDNW $(MREF mir,stat,distribution,weibull)) $(TD Weibull Distribution ))
    $(LEADINGROW Multivariate Distributions)
    $(TR $(TDNW $(MREF mir,stat,distribution,categorical)) $(TD Categorical Distribution ))
)

License: $(HTTP www.apache.org/licenses/LICENSE-2.0, Apache-2.0)

Authors: John Michael Hall, Ilya Yaroshenko

Copyright: 2022-3 Mir Stat Authors.

+/

module mir.stat.distribution;

///
public import mir.stat.distribution.bernoulli;
///
public import mir.stat.distribution.beta;
///
public import mir.stat.distribution.beta_proportion;
///
public import mir.stat.distribution.binomial;
///
public import mir.stat.distribution.cauchy;
///
public import mir.stat.distribution.chi2;
///
public import mir.stat.distribution.cornish_fisher;
///
public import mir.stat.distribution.exponential;
///
public import mir.stat.distribution.f;
///
public import mir.stat.distribution.gamma;
///
public import mir.stat.distribution.generalized_pareto;
///
public import mir.stat.distribution.geometric;
///
public import mir.stat.distribution.gev;
///
public import mir.stat.distribution.hypergeometric;
///
public import mir.stat.distribution.laplace;
///
public import mir.stat.distribution.log_normal;
///
public import mir.stat.distribution.logistic;
///
public import mir.stat.distribution.negative_binomial;
///
public import mir.stat.distribution.normal;
///
public import mir.stat.distribution.pareto;
///
public import mir.stat.distribution.poisson;
///
public import mir.stat.distribution.rayleigh;
///
public import mir.stat.distribution.students_t;
///
public import mir.stat.distribution.uniform;
///
public import mir.stat.distribution.uniform_discrete;
///
public import mir.stat.distribution.weibull;
