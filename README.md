# mir-random
Dlang Random Number Generators

#### Difference with Phobos
 - `opCall` API instead of range interface is used (similar to C++)
 - No default and copy constructors are allowed for generators.
 - 64-bit Mt19937 initialization is fixed
 - 64-bit Mt19937 is deafault for 64 bit-platforms
 - `unpredictableSeed` has not state
 - Does not depend on Druntime (Better C concept)
