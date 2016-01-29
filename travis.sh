#!/usr/bin/env bash

set -ueo pipefail

if [ ! -z "${COVERAGE:-}" ]; then
    dub fetch doveralls
    dub test -b unittest-cov
    dub run doveralls
else
	dub test
fi
