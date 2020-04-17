#!/usr/bin/env bash

set -ueo pipefail

if [ ! -z "${COVERAGE:-}" ]; then
    dub build --build=docs

    dub test -b unittest-cov
    wget https://codecov.io/bash -O codecov.sh
    bash codecov.sh
else
    dub test

    if [ "x$TEST_MESON" = "xtrue" ] && ! [ "x$TRAVIS_COMPILER" = "xdmd"  && $(dmd --version | head -n1) = "DMD64 D Compiler v2.085.1"]; then
        meson build && ninja -C build
    fi
fi
