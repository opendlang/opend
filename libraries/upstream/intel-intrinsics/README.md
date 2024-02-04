
# intel-intrinsics

[![Travis Status](https://api.travis-ci.com/AuburnSounds/intel-intrinsics.svg?branch=master)](https://travis-ci.com/AuburnSounds/intel-intrinsics)
![x86_64](https://github.com/AuburnSounds/intel-intrinsics/workflows/x86_64/badge.svg)
![x86](https://github.com/AuburnSounds/intel-intrinsics/workflows/x86/badge.svg)
![gdc 12+](https://github.com/AuburnSounds/intel-intrinsics/workflows/gdc/badge.svg)

`intel-intrinsics` is the SIMD library for D.

`intel-intrinsics` lets you use SIMD in D with support for LDC / DMD / GDC with a single syntax and API: the x86 Intel Intrinsics API that is also used within the C, C++, and Rust communities.

`intel-intrinsics` is most similar to [simd-everywhere](https://github.com/simd-everywhere/simde), it can target AArch64 for full-speed with Apple Silicon without code change.

```json
"dependencies":
{
    "intel-intrinsics": "~>1.0"
}
```

## Features

### SIMD intrinsics with `_mm_` prefix

|       | DMD x86/x86_64        | LDC x86/x86_64         | LDC arm64            | GDC x86_64              |
|-------|-----------------------|------------------------|----------------------|-------------------------|
| MMX   | Yes but slow ([#42](https://github.com/AuburnSounds/intel-intrinsics/issues/42)) | Yes                      | Yes    | Yes |
| SSE   | Yes | Yes                      | Yes    | Yes |
| SSE2  | Yes but slow ([#42](https://github.com/AuburnSounds/intel-intrinsics/issues/42)) | Yes                      | Yes    | Yes |
| SSE3  | Yes but slow ([#42](https://github.com/AuburnSounds/intel-intrinsics/issues/42)) | Yes (use `-mattr=+sse3`)   | Yes    | Yes (use `-msse3`) |
| SSSE3 | Yes (use `-mcpu`) | Yes (use `-mattr=+ssse3`)  | Yes    | Yes  (use `-mssse3`) |
| SSE4.1| Yes but slow ([#42](https://github.com/AuburnSounds/intel-intrinsics/issues/42)) | Yes (use `-mattr=+sse4.1`) | Yes    | Yes  (use `-msse4.1`) |
| SSE4.2| Yes but slow ([#42](https://github.com/AuburnSounds/intel-intrinsics/issues/42)) | Yes (use `-mattr=+sse4.2`) | Yes (use `-mattr=+crc`)   | Yes (use `-msse4.2`) |
| BMI2  | Yes but slow ([#42](https://github.com/AuburnSounds/intel-intrinsics/issues/42)) | Yes (use `-mattr=+bmi2`)   | Yes | Yes (use `-mbmi2`)  |
| AVX   | Yes but slow ([#42](https://github.com/AuburnSounds/intel-intrinsics/issues/42)) | Yes (use `-mattr=+avx`) | Yes | Yes (use `-mavx`) |
| AVX2  | Partly and slow ([#42](https://github.com/AuburnSounds/intel-intrinsics/issues/42)) | Partly (use `-mattr=+avx2`) | Partly | Partly (use `-mavx2`) |

The intrinsics implemented follow the syntax and semantics at: https://software.intel.com/sites/landingpage/IntrinsicsGuide/

The philosophy (and guarantee) of `intel-intrinsics` is:
 - `intel-intrinsics` generates optimal code else it's a bug.
 - **No promise that the exact instruction is generated**, because it's often not the fastest thing to do.
 - Guarantee that the **semantics** of the intrinsic is preserved, above all other consideration (even at the cost of speed). See image below.

### SIMD types

`intel-intrinsics` define the following types whatever the compiler and target:

`long1`, `int2`, `short4`, `byte8`, `float2`,  
`long2`, `int4`, `short8`, `byte16`, `float4`, `double2`  
`long4`, `int8`, `short16`, `byte32`, `float8`, `double4`

though most of the time you will deal with:
```d
alias __m128 = float4; 
alias __m128i = int4;
alias __m128d = double2;
alias __m64 = long1;
alias __m256 = float8; 
alias __m256i = long4;
alias __m256d = double4;
```

This type erasure of integers vectors is a defining point of the Intel API.


### Vector Operators for all

`intel-intrinsics` implements Vector Operators for compilers that don't have `__vector` support (DMD with 32-bit x86 target, 256-bit vectors with GDC without `-mavx`...). It doesn't provide unsigned vectors though.

**Example:**
```d
__m128 add_4x_floats(__m128 a, __m128 b)
{
    return a + b;
}
```
is the same as:
```d
__m128 add_4x_floats(__m128 a, __m128 b)
{
    return _mm_add_ps(a, b);
}
```

[See available operators...](https://dlang.org/spec/simd.html#vector_op_intrinsics)

> _One exception to this is `int4` * `int4`. Older GDC and current DMD do not have this operator. Instead, do use `_mm_mullo_epi32` from `inteli.smmintrin` module._


### Individual element access

It is recommended to do it in that way for maximum portability:
```d
__m128i A;

// recommended portable way to set a single SIMD element
A.ptr[0] = 42; 

// recommended portable way to get a single SIMD element
int elem = A.array[0];
```


## Why `intel-intrinsics`?

- **Portability** 
  It just works the same for DMD, LDC, and GDC.
  When using LDC, `intel-intrinsics` allows to target AArch64 and 32-bit ARM with the same semantics.

- **Capabilities**
  Some instructions just aren't accessible using `core.simd` and `ldc.simd` capabilities. For example: `pmaddwd` which is so important in digital video. Some instructions need an almost exact sequence of LLVM IR to get generated. `ldc.intrinsics` is a moving target and you need a layer on top of it.
  
- **Familiarity**
  Intel intrinsic syntax is more familiar to C and C++ programmers. 
The Intel intrinsics names  aren't good, but they are known identifiers.
The problem with introducing new names is that you need hundreds of new identifiers.

- **Documentation**
There is a convenient online guide provided by Intel:
https://software.intel.com/sites/landingpage/IntrinsicsGuide/
Without that Intel documentation, it's impractical to write sizeable SIMD code.


### Who is using it?

- `dg2d` is a very fast [2D renderer](https://github.com/cerjones/dg2d), twice as fast as Cairo
- [18x faster SHA-256 vs Phobos](https://github.com/AuburnSounds/intel-intrinsics/blob/master/examples/sha256/source/main.d) with `intel-intrinsics`
- [Auburn Sounds](https://www.auburnsounds.com/) audio products
- [Cut Through Recordings](https://www.cutthroughrecordings.com/) audio products
- [Punk Labs](https://punklabs.com/) audio products
- [PixelPerfectEngine](https://github.com/ZILtoid1991/pixelperfectengine)
- [SMAOLAB](https://smaolab.org/) audio products


### Notable differences between x86 and ARM targets

- AArch64 and 32-bit ARM respects floating-point rounding through MXCSR emulation.
  This works using FPCR as thread-local store for rounding mode.

  Some features of MXCSR are absent:
  - Getting floating-point exception status
  - Setting floating-point exception masks
  - Separate control for denormals-are-zero and flush-to-zero (ARM has one bit for both)

- 32-bit ARM has a different nearest rounding mode as compared to AArch64 and x86. Numbers with a 0.5 fractional part (such as `-4.5`) may not round in the same direction. This shouldn't affect you.

- Some ARM architecture do not represent the sign bit for NaN. Just writing `-float.nan` or `-double.nan` will loose the sign bit! This isn't related to `intel-intrinsics`.

### Notable differences between x86 instruction semantics and `intel-intrinsics` semantics

- Masked load/store MUST address fully addressable memory, even if their mask is zero. Pad your buffers.
- Some AVX float comparisons have an option to signal quiet NaN. This is not followed by intel-intrinsics.



### Video introduction

In this DConf 2019 talk, Auburn Sounds:
- introduces how `intel-intrinsics`came to be, 
- demonstrates a 3.5x speed-up for some particular loops,
- reminds that normal D code can be really fast and intrinsics might harm performance

[See the talk: intel-intrinsics: Not intrinsically about intrinsics](https://www.youtube.com/watch?v=cmswsx1_BUQ)

<img alt="Ben Franklin" src="https://raw.githubusercontent.com/AuburnSounds/intel-intrinsics/master/ben.jpg">

