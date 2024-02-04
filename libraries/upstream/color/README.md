std.experimental.color
======================

Development of std.exerpimental.color, intended for inclusion in the D standard library.

Currently supported colorspaces:
 - XYZ, xyY
 - RGB (sRGB, gamma, linear, custom colourspace; primaries, whitepoint, compression ramp)
 - HSV, HSL, HSI, HCY, HWB, HCG
 - Lab, LCh

Implements comprehensive conversion between supported colourspaces.
Flexible design supports addition of user-supplied colourspaces, with full conversion and interoperability.
