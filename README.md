# Standard paths

D library for getting standard paths (e.g. Pictures, Music, Documents and also generic configuration and data paths). 
Inspired by QStandardPaths from Qt.

[![Build Status](https://github.com/FreeSlave/standardpaths/actions/workflows/ci.yml/badge.svg?branch=master)](https://github.com/FreeSlave/standardpaths/actions/workflows/ci.yml) [![Windows Build Status](https://ci.appveyor.com/api/projects/status/github/FreeSlave/standardpaths?branch=master&svg=true)](https://ci.appveyor.com/project/FreeSlave/standardpaths)

[Online documentation](http://freeslave.github.io/standardpaths/standardpaths.html)

## Platform support

Works on Freedesktop (GNU/Linux, FreeBSD, etc.), Windows and OS X.

## Running examples

### [Print directories](examples/printdirs.d)

Prints some standard paths to stdout.

    dub examples/printdirs.d

On OSX it also can be built to use Cocoa instead of Carbon:

    dub --single examples/printdirs.d --override-config=standardpaths/cocoa

### [Get path](examples/getpath.d)

Get path of given type, verify it exists or create if it does not.

    dub examples/getpath.d --verify --create templates

Use Cocoa instead of Carbon on OSX:

    dub --single examples/getpath.d --override-config=standardpaths/cocoa -- --create music

With subfolder:

    dub examples/getpath.d --subfolder=MyLittleCompany/MyLittleApplication data

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
    auto folderFlag = FolderFlag.verify;

    string[] paths = [
        homeDir(),
        writablePath(StandardPath.desktop, folderFlag),
        writablePath(StandardPath.downloads, folderFlag),
        writablePath(StandardPath.documents, folderFlag),
        writablePath(StandardPath.pictures, folderFlag),
        writablePath(StandardPath.music, folderFlag),
        writablePath(StandardPath.videos, folderFlag),
        writablePath(StandardPath.templates, folderFlag),
        writablePath(StandardPath.publicShare, folderFlag)
    ];
    foreach(path; paths) {
        if (path.length) {
            string label = path.baseName();
            fileDialog.addPath(label, path);
        }
    }
    fileDialog.show();
}
```

### Writing configuration files

Usually your application will have some configuration file (or files) to store user's preferences and settings. That's where you could use StandardPath.config path.
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
    string configDir = writablePath(StandardPath.config, buildPath(organizationName, applicationName), FolderFlag.create);
    if (!configDir.length) {
        throw new Exception("Could not create config directory");
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
    string[] configDirs = standardPaths(StandardPath.config, buildPath(organizationName, applicationName));

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

On freedesktop systems (GNU/Linux, FreeBSD, etc.) library follows [XDG Base Directory Specification](http://standards.freedesktop.org/basedir-spec/latest/index.html#introduction) and also provides behavior similiar to [xdg-user-dirs](http://www.freedesktop.org/wiki/Software/xdg-user-dirs/).

### Windows

On Windows it utilizes [SHGetKnownFolderPath](https://msdn.microsoft.com/en-us/library/windows/desktop/bb762188(v=vs.85).aspx) or  [SHGetSpecialFolderPath](https://msdn.microsoft.com/en-us/library/windows/desktop/bb762204(v=vs.85).aspx) as fallback.

### Mac OS X

Depending on configuration the library uses FSFindFolder from Carbon framework or URLForDirectory from Cocoa. 
[See here](http://cocoadev.com/ApplicationSupportFolder).
