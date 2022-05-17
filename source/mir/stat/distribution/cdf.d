/++
This package publicly imports `mir.stat.distribution.*CDF` modules.

License: $(HTTP www.apache.org/licenses/LICENSE-2.0, Apache-2.0)

Authors: John Michael Hall, Ilya Yaroshenko

Copyright: 2022 Mir Stat Authors.

+/

module mir.stat.distribution.cdf;

///
public import mir.stat.distribution.beta: betaCDF;
///
public import mir.stat.distribution.betaProportion: betaProportionCDF;
///
public import mir.stat.distribution.normal: normalCDF;
///
public import mir.stat.distribution.uniform: uniformCDF;
