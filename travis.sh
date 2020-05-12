#!/usr/bin/env bash

set -ueo pipefail

if [ ! -z "${COVERAGE:-}" ]; then
    dub build --build=docs

    dub test -b unittest-cov
    wget https://codecov.io/bash -O codecov.sh
    bash codecov.sh
else
    dub test

    if [ "x${TEST_MESON:-}" = "xtrue" ] && [ "x$(dmd --version | head -n1)" != "xDMD64 D Compiler v2.085.1" ]; then
        meson build && ninja -C build
    fi
fi
