#!/bin/bash

set -eo pipefail

# Test minimal configuration
if [[ $MINIMAL -eq 1 ]]; then
    dub build --config=stlib-minimal
    dub test --config=unittest-minimal
# Test with configure script
else
    dub build
    dub test
fi

echo ""
echo "================================================================================"
echo "Running examples"
echo ""

# Test examples
cd example
for i in *; do
    # Can't run win32 tests, common directory does not contain tests
    # freetype version on travis-ci seems to be incompatible with derelict
    if [[ "$i" != "common" && "$i" != "win32" && "$i" != "freetype" ]]; then
        echo ""
        echo "=> $i"
        cd $i
        # Insert a subConfigurations section before the configurations section
        if [[ "$MINIMAL" -ne 1 ]]; then
            sed -i 's/.*"configurations": \[.*/\t"subConfigurations": {\n\t\t"cairod": "stlib-minimal"\n\t},\n&/' dub.json
        fi
        # Do not run xlib tests, no GUI available
        if [[ "$i" == "xlib" ]]; then
            dub build
        else
            dub run
        fi
        cd ../
    fi
done
