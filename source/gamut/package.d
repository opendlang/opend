/// Import everything needed for users of the library.
module gamut;

/// This is the public API, guaranteed not to break inside a major SemVer version.
///
/// It is entirely modelled upon the FreeImage API, so that the documentation and API can be reused.
/// Reference: https://freeimage.sourceforge.io/fip/classfipImage.html
///            FreeImagePlus = https://freeimage.sourceforge.io/fip/annotated.html
///
/// Gamut is a clean-room implementation: no software code from FreeImage was ever looked at, only
/// documentation.


public import gamut.types;
public import gamut.general;
public import gamut.bitmap;
