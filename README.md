# Standard paths

D library for getting standard paths (e.g. Pictures, Music, Documents). Inspired by QStandardPaths from Qt.

The library is in early development. API may change in future.

Currently works on Windows and Linux (and probably FreeBSD).

## Examples

### Print directories

Prints some standard paths to stdout.

    dub run standardpaths:printdirs --build=release

### Find executable

Take name of executable as command line argument and search PATH environment variable for retrieving absolute path to file.

    dub build standardpaths:findexecutable --build=release
    examples\findexecutable\bin\findexecutable cmd # on Windows
    ./examples/findexecutable/bin/findexecutable chmod # on Linux

## Implementation details   

### Posix

On Posix systems library uses [XDG Base Directory Specification](http://standards.freedesktop.org/basedir-spec/latest/index.html#introduction) and [xdg-user-dirs](http://www.freedesktop.org/wiki/Software/xdg-user-dirs/).

### Windows

On Windows it utilizes [SHGetSpecialFolderPath](https://msdn.microsoft.com/en-us/library/windows/desktop/bb762204(v=vs.85).aspx).
