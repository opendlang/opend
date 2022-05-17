/++
This package publicly imports `mir.stat.distribution.*PDF` modules.

License: $(HTTP www.apache.org/licenses/LICENSE-2.0, Apache-2.0)

Authors: John Michael Hall, Ilya Yaroshenko

Copyright: 2022 Mir Stat Authors.

+/

module mir.stat.distribution.pdf;

///
public import mir.stat.distribution.beta: betaPDF;
///
public import mir.stat.distribution.betaProportion: betaProportionPDF;
///
public import mir.stat.distribution.normal: normalPDF;
///
public import mir.stat.distribution.uniform: uniformPDF;
