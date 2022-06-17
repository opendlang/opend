/**
Public API for gamut.

Copyright: Copyright Guillaume Piolat 2022
License:   $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost License 1.0)

Note: This library is re-implemented in D from FreeImage documentation (FreeImage3180.pdf).
See the differences in DIFFERENCES.md
*/
module gamut;

/// This is the public API, guaranteed not to break inside a major SemVer version.
///
/// It is entirely modelled upon the FreeImage API, so that the documentation and API can be reused.
/// Reference: https://freeimage.sourceforge.io/fip/classfipImage.html
///            FreeImagePlus = https://freeimage.sourceforge.io/fip/annotated.html
///
/// Gamut is a clean-room implementation: no software code from FreeImage was ever looked at, only
/// documentation.
public import gamut.image;
public import gamut.types;
public import gamut.io;
