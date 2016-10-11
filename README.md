[![Gitter](https://img.shields.io/gitter/room/libmir/public.svg)](https://gitter.im/libmir/public)

[![Circle CI](https://circleci.com/gh/libmir/cpuid.svg?style=svg)](https://circleci.com/gh/libmir/cpuid)
[![Build Status](https://travis-ci.org/libmir/cpuid.svg?branch=master)](https://travis-ci.org/libmir/cpuid)
[![Build status](https://ci.appveyor.com/api/projects/status/f2n4dih5s4c32q7u/branch/master?svg=true)](https://ci.appveyor.com/project/9il/cpuid/branch/master)

[![Dub version](https://img.shields.io/dub/v/cpuid.svg)](http://code.dlang.org/packages/cpuid)
[![Dub downloads](https://img.shields.io/dub/dt/cpuid.svg)](http://code.dlang.org/packages/cpuid)
[![License](https://img.shields.io/dub/l/cpuid.svg)](http://code.dlang.org/packages/cpuid)

# CPU Information

```d
void main()
{
    import std.stdio;
    import cpuid.unified;

    cpuid_init();

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

See [all reports](https://github.com/libmir/cpuid/issues?utf8=%E2%9C%93&q=is%3Aissue%20label%3AReports%20).

To receive a report about your CPU, run

```
dub fetch cpuid
dub test cpuid
```

Please report dub log in a new GitHub issue!

See also [output example](https://gist.github.com/9il/66d2f824ca52e1293358b86604e7fb21).

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
 - Unions and `std.bitmanip.bitfields` are used instead of bit operations.

## TODO

 - Add information about recent features like AVX2, AVX512F.
 - Add information about ARM target and ARM vendors.
 - Test a lot of different CPUs.
 - Extend testing infrastructure.
