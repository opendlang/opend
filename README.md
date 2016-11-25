# mir-random
Professional Random Number Generators

```d
import std.range, std.stdio;

import random;
import random.variable: NormalVariable;

auto rng = Random(unpredictableSeed);        // Engines are allocated on stack or global
auto sample = rng                            // Engines are passed by reference to algorithms
    .randomRange(NormalVariable!double(0, 1))// Random variables are passed by value
    .take(1000)                              // Fix sample length to 1000 elements (common Input Range API)
    .array;                                  // Allocates memory and performs computation

writeln(sample);                             
```

## Comparison with Phobos
 - Does not depend on DRuntime (Better C concept)

##### `random` (new implementation and API)
 - Mir Random `rand!float`/`rand!double`/`rand!real` generates saturated real random numbers in `(-1, 1)`. For example, `rand!real` can produce more then 2^78 unique numbers. In other hand, `std.random.uniform01!real` produces less then `2^31` unique numbers with default Engine.
 - Mir Random fixes Phobos integer underflow bugs.
 - Addition optization was added for enumerated types.

##### `ramdom.variable` (new)
 - Uniform
 - Exponential
 - Gamma
 - Normal
 - Cauchy
 - ...

##### `random.algorithm` (new)
 - Range API adaptors

##### `random.engine.*` (fixed, reworked)
 - `opCall` API instead of range interface is used (similar to C++)
 - No default and copy constructors are allowed for generators.
 - `@RandomEngine` UDA is used for for Engines instead of a enum flag.
 - `unpredictableSeed` has not state, returns `ulong`
 - Any unsigned generators are allowed.
 - `min` proporty was removed. Any integer generator can normalize its minimum down to zero.
 - 64-bit Mt19937 initialization is fixed
 - 64-bit Mt19937 is default for 64-bit targets
 - [WIP] additional Engines, see https://github.com/libmir/mir-random/pulls
