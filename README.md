[![Gitter](https://img.shields.io/gitter/room/libmir/public.svg)](https://gitter.im/libmir/public)

[![Build Status](https://travis-ci.org/libmir/mir-cpuid.svg?branch=master)](https://travis-ci.org/libmir/mir-cpuid)
[![Build Status](https://ci.appveyor.com/api/projects/status/github/libmir/mir-cpuid?svg=true)](https://ci.appveyor.com/project/9il/mir-cpuid/branch/master)

[![Dub version](https://img.shields.io/dub/v/mir-cpuid.svg)](http://code.dlang.org/packages/mir-cpuid)
[![Dub downloads](https://img.shields.io/dub/dt/mir-cpuid.svg)](http://code.dlang.org/packages/mir-cpuid)
[![License](https://img.shields.io/dub/l/mir-cpuid.svg)](http://code.dlang.org/packages/mir-cpuid)

# CPU Information

```d
void main()
{
    import std.stdio;
    import cpuid.unified;

    enum fmt = "%14s: %s";

    fmt.writefln("cores", cores);
    fmt.writefln("threads", threads);

    fmt.writefln("data caches", dCache.length);
    fmt.writefln("code caches", iCache.length);
    fmt.writefln("unified caches", uCache.length);

    fmt.writefln("data TLBs", dTlb.length);
    fmt.writefln("code TLBs", iTlb.length);
    fmt.writefln("unified TLBs", uTlb.length);
}
```

This package also can be used as workaround for [core.cpuid Issue 16028](https://issues.dlang.org/show_bug.cgi?id=16028).

## Documentation

See http://docs.cpuid.dlang.io .

## Testing

See [all reports](https://github.com/libmir/mir-cpuid/issues?utf8=%E2%9C%93&q=is%3Aissue%20label%3AReports%20).

Run the following command from the project's directory to receive a report about your CPU

```
dub --single report.d
```

Please report dub log in a new GitHub issue!

See also [output example](https://gist.github.com/9il/66d2f824ca52e1293358b86604e7fb21).

## Building a betterC library

BetterC mode works when compiled with LDC only.

```
dub build --compiler=ldmd2 --build-mode=singleFile --parallel
```

## API Features

 - API was split to _unified_, _target_ specified, and _vendor_ specified parts.
 - Complex cache topology (number of cores per cache) is supported. This feature is required by ARM CPUs.
 - Translation lookaside buffers are supported. They are used in server and math software, for example cache optimized BLAS requires TLB information.
 - Caches and TLBs are split into three types:
 	- Data
 	- Instruction (code)
 	- Unified (data and code)
 - `_cpuid` function is available for x86/x86-64 targets.

## Implementation Features

 - The library was written completely from scratch.
 - Code is clean and simple.
 - Unions and `mir.bitmanip.bitfields` are used instead of bit operations.
 - Slim betterC library with `extern(C)` insterface.

## TODO

 - [x] Add information about recent features like AVX2, AVX512F.
 - [ ] Add information about ARM target and ARM vendors.
 - [x] Test a lot of different CPUs.
 - [ ] Extend testing infrastructure.
 - [ ] CPU(package) count identification.
 - [ ] Per CPU(package) CPUID information.
