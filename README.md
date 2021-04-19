[![Dub version](https://img.shields.io/dub/v/mir-ion.svg)](http://code.dlang.org/packages/mir-ion)
[![Dub downloads](https://img.shields.io/dub/dt/mir-ion.svg)](http://code.dlang.org/packages/mir-ion)
[![License](https://img.shields.io/dub/l/mir-ion.svg)](http://code.dlang.org/packages/mir-ion)
[![codecov](https://codecov.io/gh/libmir/mir-ion/branch/master/graph/badge.svg?token=MF9yMpCZbO)](https://codecov.io/gh/libmir/mir-ion)
[![Build Status](https://travis-ci.org/libmir/mir-ion.svg?branch=master)](https://travis-ci.org/libmir/mir-ion)
[![CircleCI](https://circleci.com/gh/libmir/mir-ion.svg?style=svg)](https://circleci.com/gh/libmir/mir-ion)

# Mir Ion
This library seeks to implement the [Ion file format](http://amzn.github.io/ion-docs). We aim to support both versions of Ion (text & binary), as well as providing an implementation of the format that is performant and easy-to-use.

## Documentation
You can find the documentation for this library [here](http://mir-ion.libmir.org/). 
Additionally, for examples of the Ion format, you can check the [Ion Cookbook](https://amzn.github.io/ion-docs/guides/cookbook.html)

## Status
This package is considered experimental, under active/early development, and the API is subject to change.

As such, please look towards using [asdf](https://github.com/libmir/asdf) until further notice.

## Feature Status

 - [x] Binary Ion Value parsing and skip-scan iteration.
 - [x] Binary Ion conversions to D types.
 - [x] Binary Ion conversions from D types.
 - [x] Fast hash table for Ion Symbol Tables
 - [x] Fast CTFE Symbol Table for deserialization
 - [x] Ion Symbol Tables
 - [x] JSON to Ion
 - [x] Ion to JSON
 - [ ] Text Ion to Ion
 - [ ] Ion to Text Ion
 - [x] Serialization API
 - [x] Deserialization API
 - [x] Precise decimal to floating conversion (except subnormals)
 - [x] Precise floating to decimal conversion.
 - [x] Local Symbol Tables
 - [ ] Shared Symbol Tables
 - [x] Chunked JSON reader
 - [x] Chunked binary Ion Value Stream reader
 - [ ] MessagePack parsing
 - [ ] Ion to MessagePack
