# XDG paths

D library for retrieving XDG base directories as described by [XDG Base Directory Specification](https://specifications.freedesktop.org/basedir-spec/latest/index.html).

[![Build Status](https://github.com/FreeSlave/xdgpaths/actions/workflows/ci.yml/badge.svg?branch=master)](https://github.com/FreeSlave/xdgpaths/actions/workflows/ci.yml) [![Coverage Status](https://coveralls.io/repos/github/FreeSlave/xdgpaths/badge.svg?branch=master)](https://coveralls.io/github/FreeSlave/xdgpaths?branch=master)

[Online documentation](https://freeslave.github.io/d-freedesktop/docs/xdgpaths.html)

## Run [example](examples/test.d)

    XDG_CONFIG_HOME=$HOME/config-test dub examples/test.d --path=config --shouldCreate --subfolder=Company/Product

    XDG_DATA_HOME=$HOME/data-test dub examples/test.d --path=data --shouldCreate --subfolder=Company/Product

    XDG_CACHE_HOME=$HOME/cache-test dub examples/test.d --path=cache --shouldCreate --subfolder=Company/Product
