# This is for travis-ci to run doveralls only on dmd build.

if [ $DC = "dmd" ]; then
    wget -O doveralls "https://github.com/ColdenCullen/doveralls/releases/download/v1.1.6/doveralls_linux_travis"
    chmod +x doveralls
fi
