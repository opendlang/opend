#!/bin/sh

set -ex

if [ "$USE_DOVERALLS" = "true" ]; then
    wget -O doveralls "https://github.com/ColdenCullen/doveralls/releases/download/v1.2.0/doveralls_linux_travis"
    chmod +x doveralls
    dub test -b unittest-cov --compiler=${DC}
    ./doveralls
else
    dub test --compiler=${DC}
fi
