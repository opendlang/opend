#!/bin/bash

# Always run at least once
dub test

# This script depends on inotify-hookable
inotify-hookable -w source -c "dub test"
