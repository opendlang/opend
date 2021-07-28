/// Import everything needed for users of the library.
module gamut;

// This is the public API, guaranteed not to break inside a major SemVer version.

// `Image` definition.
public import gamut.image;


// Design decision: all function operating on images start with `imageXXX`: 
// prefer `imageLoad` to `loadImage`.