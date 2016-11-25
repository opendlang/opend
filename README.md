# mir-random
Dlang Random Number Generators

#### Comparison with Phobos
 - Does not depend on DRuntime (Better C concept)

##### Nonuniform generators (new)
 - Exponential
 - Gamma
 - Normal
 - Cauchy
 - ...

##### Real uniform generators (fixed, 100% new implementation)

Mir Random `rand!float`/`rand!double`/`rand!real` generates saturated real random numbers in `(-1, 1)`. For example, `rand!real` can produce more then 2^78 unique numbers. In other hand, `std.random.uniform01!real` produces less then `2^31` unique numbers with default Engine.

##### Integer uniform generators (fixed)

Mir Random fixes Phobos underflow bugs. Addition optization was added for enumerated types.

##### Generators (fixed, reworked)
 - `opCall` API instead of range interface is used (similar to C++)
 - No default and copy constructors are allowed for generators.
 - 64-bit Mt19937 initialization is fixed
 - 64-bit Mt19937 is default for 64-bit targets
 - `unpredictableSeed` has not state, returns `ulong`
 - `@URNG` UDA is used for for RNGs instead of a enum flag.
 - `min` proporty was removed. Any integer generator can normalize its minimum down to zero.
 - Any unsigned generators are allowed.
 - [WIP] additional Xorshift generators
