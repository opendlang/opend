# mir-random
Dlang Random Number Generators

#### Comparison with Phobos
 - Does not depend on DRuntime (Better C concept)

##### Generators
 - `opCall` API instead of range interface is used (similar to C++)
 - No default and copy constructors are allowed for generators.
 - 64-bit Mt19937 initialization is fixed
 - 64-bit Mt19937 is default for 64-bit targets
 - `unpredictableSeed` has not state, returns `ulong`
 - `@URNG` UDA is used for for RNGs instead of a enum flag.
 - `min` and `max` proporties was removed. Generators must always generate uniformly all set of bits.
 - Any unsigned generators are allowed.
 - `LinearCongruentialEngine` was removed.
 - [WIP] additional Xorshift generators

##### Integer uniform generators
 - Mir Random fixes underflow bugs.

##### Real uniform generators
 - Mir Random `rand!float`/`rand!double`/`rand!real` generates saturated real random numbers in `(-1, 1)`. For example, `rand!real` can produce more then 2^78 unique numbers. In other hand, `std.random.uniform01!real` produces less then `2^32` unique numbers with default Engine.

##### Nonuniform generators
 - Exponential
 - Gamma
 - Normal
 - Cauchy
 - ...
