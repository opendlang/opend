# Standard paths

D library for getting standard paths (e.g. Pictures, Music, Documents). Inspired by QStandardPaths from Qt.

[![Build Status](https://travis-ci.org/MyLittleRobo/standardpaths.svg?branch=master)](https://travis-ci.org/MyLittleRobo/standardpaths)

[Online documentation](http://mylittlerobo.github.io/standardpaths/standardpaths.html).

## Platform support

Currently works on Windows, Linux and FreeBSD. Mac OS X support is experimental.

## Running examples

### [Print directories](examples/printdirs/source/app.d)

Prints some standard paths to stdout.

    dub run standardpaths:printdirs --build=release

### [Find executable](examples/findexecutable/source/app.d)

Takes the name of executable as command line argument and searches PATH environment variable for retrieving absolute path to file. On Windows it also tries all known executable extensions.

    dub run standardpaths:findexecutable --build=release -- whoami
    
### [Get path](examples/getpath/source/app.d)

Get path of given type, verify it exists or create if it does not.

    dub run standardpaths:getpath -- --verify --create templates
    
## Use cases

Some code snippets showing how standardpaths library is supposed to be used.

### Building file dialogs

Let's say you have some fancy FileDialog class and you want to provide shortcuts to standard user directories to improve experience.
Your code may look like this:

```d
import standardpaths;
import std.file;
import std.stdio;

void showFileDialog()
{
    auto fileDialog = new FileDialog;
    string[] paths = [
        homeDir(),
        writablePath(StandardPath.desktop),
        writablePath(StandardPath.downloads),
        writablePath(StandardPath.documents),
        writablePath(StandardPath.pictures),
        writablePath(StandardPath.music),
        writablePath(StandardPath.videos),
        writablePath(StandardPath.templates),
        writablePath(StandardPath.publicShare)
    ];
    foreach(path; paths) {
        if (path.exists) {
            string label = path.baseName();
            fileDialog.addPath(label, path);
        }
    }
    fileDialog.show();
}
```

### Writing configuration files

Usually your application will have some configuration file (or files) to store user's preferences and settings. That's where you could use StandardPath.Config path.
While the library returns generic paths for configuration, data and cache, you want to have separate folders specially for your application, so you will not accidentally read or modify files used by other programs.
Usually these paths are built by concatenating of generic path, organization name and application name.

```d
//You may have these as constants somewhere in your code
enum organizationName = "MyLittleCompany";
enum applicationName = "MyLittleApplication";

import standardpaths;
import std.stdio;
import std.path;

void saveSettings(const Config config)
{
    string configDir = buildPath(writablePath(StandardPath.config), organizationName, applicationName);
    if (!configDir.exists) {
        mkdirRecurse(configDir);
    }
    string configFile = buildPath(configDir, "config.conf");
    
    auto f = File(configFile, "w"); 
    // write settings
    writeln("Settings saved!");
}
```

### Reading configuration files

Since one can save settings it also should be able to read them. Before the first start application does not have any user-specific settings, though it may provide some global default settings upon installing.
It's up to developer to decide how to read configs, e.g. whether to read the first found file only or to merge settings from all found config consequentially.

```d
Config readSettings()
{
    string[] configDirs = standardPaths(StandardPath.config).map!(s => buildPath(s, organizationName, applicationName).array;

    foreach(configDir; configDirs) {
        string configFile = buildPath(configDir, "config.conf");
        if (configFile.exists) {
            auto f = File(configFile, "r");
            Config config;
            //read settings...
            return config;//consider using of the first found file
        }
    }
}
```

## Implementation details   

### Freedesktop

On freedesktop systems (GNU/Linux, FreeBSD, etc.) library uses [XDG Base Directory Specification](http://standards.freedesktop.org/basedir-spec/latest/index.html#introduction) and also provides behavior similiar to [xdg-user-dirs](http://www.freedesktop.org/wiki/Software/xdg-user-dirs/).

### Windows

On Windows it utilizes [SHGetSpecialFolderPath](https://msdn.microsoft.com/en-us/library/windows/desktop/bb762204(v=vs.85).aspx).

### Mac OS X

Uses FSFindFolder from Carbon framework. It's deprecated now and should be replaced with Cocoa where possible. [See here](http://cocoadev.com/ApplicationSupportFolder).
