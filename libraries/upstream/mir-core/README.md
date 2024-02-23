[![Build Status](https://travis-ci.org/libmir/mir-core.svg?branch=master)](https://travis-ci.org/libmir/mir-core)

Mir Core
==============

Base software building blocks: Algebraic types (aka sumtype/tagged union/variant), universal reflection API, basic math, and more.

#### Code Constraints

1. generic code only
2. no runtime dependency : betterC compatible when compiled with LDC in release mode. Exceptions: `@nogc` `mir.exception`.
3. no complex algorithms
