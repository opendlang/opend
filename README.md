# XDG paths

D library for retrieving XDG base directories as described by [XDG Base Directory Specification](https://specifications.freedesktop.org/basedir-spec/latest/index.html).

[![Build Status](https://travis-ci.org/MyLittleRobo/xdgpaths.svg?branch=master)](https://travis-ci.org/MyLittleRobo/xdgpaths) [![Coverage Status](https://coveralls.io/repos/github/MyLittleRobo/xdgpaths/badge.svg?branch=master)](https://coveralls.io/github/MyLittleRobo/xdgpaths?branch=master)

## Run [example](examples/xdgpathstest/source/app.d)

    export XDG_CONFIG_HOME=$HOME/config-test
    dub run xdgpaths:xdgpathstest -- --path=config --shouldCreate --subfolder=Company/Product
    
    export XDG_DATA_HOME=$HOME/data-test
    dub run xdgpaths:xdgpathstest -- --path=data --shouldCreate --subfolder=Company/Product
    
    export XDG_CACHE_HOME=$HOME/cache-test
    dub run xdgpaths:xdgpathstest -- --path=cache --shouldCreate --subfolder=Company/Product

