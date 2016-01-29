#!/bin/sh

dub fetch doveralls
dub test -b unittest-cov
dub run doveralls
