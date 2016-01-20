#!/bin/bash

set -eo pipefail

dub build
dub test

echo ""
echo "================================================================================"
echo "Running examples"
echo ""

# Test examples
cd examples
for i in *; do
    # Can't run win32 tests, common directory does not contain tests
    # freetype version on travis-ci seems to be incompatible with derelict
    if [[ "$i" != "common" && "$i" != "win32" && "$i" != "freetype" ]]; then
        echo ""
        echo "=> $i"
        cd $i

        # Do not run xlib tests, no GUI available
        if [[ "$i" == "xlib" ]]; then
            dub build
        else
            dub run
        fi
        cd ../
    fi
done
