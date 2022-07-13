/++
This package publicly imports `mir.stat.distribution.*InvCDF` modules.

License: $(HTTP www.apache.org/licenses/LICENSE-2.0, Apache-2.0)

Authors: John Michael Hall, Ilya Yaroshenko

Copyright: 2022 Mir Stat Authors.

+/

module mir.stat.distribution.invcdf;

///
public import mir.stat.distribution.bernoulli: bernoulliInvCDF;
///
public import mir.stat.distribution.beta: betaInvCDF;
///
public import mir.stat.distribution.beta_proportion: betaProportionInvCDF;
///
public import mir.stat.distribution.binomial: binomialInvCDF;
///
public import mir.stat.distribution.exponential: exponentialInvCDF;
///
public import mir.stat.distribution.gamma: gammaInvCDF;
///
public import mir.stat.distribution.gev: gevInvCDF;
///
public import mir.stat.distribution.normal: normalInvCDF;
///
public import mir.stat.distribution.poisson: poissonInvCDF;
///
public import mir.stat.distribution.uniform: uniformInvCDF;

