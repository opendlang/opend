# This is for travis-ci to run doveralls only on dmd build.

if [ $DC = "dmd" ]; then
    ./doveralls
fi
