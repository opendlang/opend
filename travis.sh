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
    if [[ "$i" != "common" && "$i" != "win32" ]]; then
        echo ""
        echo "=> $i"
        cd $i
        # Insert a subConfigurations section before the configurations section
        if [[ "$MINIMAL" -ne 1 ]]; then
            sed -i 's/.*"configurations": \[.*/\t"subConfigurations": {\n\t\t"cairod": "stlib-minimal"\n\t},\n&/' dub.json
        fi
        # Freetype example needs an extra argument
        if [[ "$i" == "freetype" ]]; then
            # Skip: freetype version on travis-ci seems to be incompatible with derelict
            #dub build
            #./example /usr/share/fonts/truetype/dejavu/DejaVuSans.ttf
        # Do not run xlib tests, no GUI available
        elif [[ "$i" == "xlib" ]]; then
            dub build
        else
            dub run
        fi
        cd ../
    fi
done
