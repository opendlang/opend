#!/bin/sh

dub test --compiler ldc2 -a x86_64 -b unittest-release-below-avx -f
dub test --compiler ldc2 -a x86_64 -b unittest-below-avx -f
dub test --compiler ldc2 -a arm64-apple-macos -f
dub test --compiler ldc2 -a x86_64 -f
dub test --compiler ldc2 -a arm64-apple-macos -b unittest-inst -f
dub test --compiler ldc2 -a arm64-apple-macos -b unittest-release -f
dub test --compiler ldc2 -a x86_64 -b unittest-release -f
dub test --compiler ldc2 -a arm64-apple-macos -b unittest-release-inst -f

# Note: not sure why, LLVM error when using "inst" configurations in Rosetta (-mcpu=native)
# hence the below-avx configurations