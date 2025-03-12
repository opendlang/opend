## Welcome to the DCompute documentation!

DCompute is a library that together with LDC is able to make D compile on GPU.

Dcompute is split into three sections, a driver, a standard library and a set of prewritten kernels.

The driver is intended to abstract the (rather unwieldy) compute API of CUDA and OpenCL.
But you can still pull all the leavers yourself if you feel the need.

The standard library contains the set of primitive operations exposed by the compute environment as well as other common operations.

These docs are designed to help getting started installing & using DCompute. 

## Table of Contents

0. Prerequisites to using DCompute
1. Installing DCompute
2. Understanding the hardware that DCompute runs on
3. Writing kernels
4. The device standard library
4.1 index
5. The compute API driver

## D

This guide assumes that the reader is familiar with the basics of D, although anyone 
familiar with the C family of languages should be able to understand most of it.

Some of the main differences are listed below:

The template instansiation operator is binary `!` in contrast to paired angle brackets
as in C++/C# et el. If `Foo` is a templated struct that takes one type parameter then 
`Foo!int foo;` declares a variable 

There is a third class of template parameters: aliases (the other two being types and values).
`alias` template parameters can, in addition to holding types and values, can hold _symbols_.
These include variables, functions and lambdas. `alias` when used outside of a template parameter 
list is the equivalent to `using`, in C++.

`~` is the concatenation operator, used unsurprisingly to concatenate arrays. 
Used widely in string manipulation.

Uniform Function Call Syntax (UFCS) allows you to call a free function as if it were a 
method of the type of its first argument (e.g. f(x,y) can be called as x.f(y)).
This together with optional parentheses,`x.f()` where `f` is a method or UFCS function of `x`
may be written as `x.f`, allows you to write chains of call `h(g(f(x)))` as `x.f.g.h`.

`class`es as are polymorphic reference types. `struct`s are value types. Idomatic D code 
tends to use structs over classes. Classes are not used at all in DCompute.

The `.` operator will implicity follow any pointers, although it will not dereference the last
one in a chain of `.`s. There is no operator `->` or `::`, these are both handled by `.`.

`static if` is D's conditional compilation construct. Code inside a taken branch is compiled 
into the object file, code inside a taken branch _not_ taken must be syntactically correct, but 
need not be semantically correct.

For more information see the [D Wiki](https://wiki.dlang.org/Coming_From).
