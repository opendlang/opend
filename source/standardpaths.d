module standardpaths;

private {
    import std.process : environment;
    import std.array;
    import std.path;
    import std.file;
    import std.algorithm : splitter;
}

version(Windows) {
    private {
        import std.c.windows.windows;
        import std.utf;
        import std.algorithm : canFind;
    }
} else version(OSX) {
    private {
        //what to import?
    }
} else version(Posix) {
    private {
        import std.stdio : File, StdioException;
        import std.exception : assumeUnique;
        import std.conv : octal;
    }
} else {
    static assert(false, "Unsupported platform");
}

///Locations that can be used in writablePath and standardPaths functions
enum StandardPath {
    Data,   ///Location of persisted application data
    Config, ///Location of configuration files
    Cache,  ///Location of cached data
    Desktop, ///User's desktop directory
    Documents, ///User's documents
    Pictures, ///User's pictures
    Music, ///User's music
    Videos, ///User's videos (movies)
    Download, ///Directory for user's downloaded files
    Templates, ///Location of templates
    PublicShare, ///Public share folder
    Fonts, ///Location of fonts files
    Applications, ///User's applications
}

string homeDir()
{
    version(Windows) {
        //Use GetUserProfileDirectoryW from Userenv.dll?
        string home = environment.get("USERPROFILE");
        if (home.empty) {
            string homeDrive = environment.get("HOMEDRIVE");
            string homePath = environment.get("HOMEPATH");
            if (homeDrive.length && homePath.length) {
                home = homeDrive ~ homePath;
            }
        }
        return home;
    } else {
        string home = environment.get("HOME");
        return home;
    }
}

version(Windows) {
    private enum pathVarSeparator = ';';
} else version(Posix) {
    private enum pathVarSeparator = ':';
}

version(Windows) {
    
    private {
        enum {
            CSIDL_DESKTOP            =  0,
            CSIDL_INTERNET,
            CSIDL_PROGRAMS,
            CSIDL_CONTROLS,
            CSIDL_PRINTERS,
            CSIDL_PERSONAL,
            CSIDL_FAVORITES,
            CSIDL_STARTUP,
            CSIDL_RECENT,
            CSIDL_SENDTO,
            CSIDL_BITBUCKET,
            CSIDL_STARTMENU,      // = 11
            CSIDL_MYMUSIC            = 13,
            CSIDL_MYVIDEO,        // = 14
            CSIDL_DESKTOPDIRECTORY   = 16,
            CSIDL_DRIVES,
            CSIDL_NETWORK,
            CSIDL_NETHOOD,
            CSIDL_FONTS,
            CSIDL_TEMPLATES,
            CSIDL_COMMON_STARTMENU,
            CSIDL_COMMON_PROGRAMS,
            CSIDL_COMMON_STARTUP,
            CSIDL_COMMON_DESKTOPDIRECTORY,
            CSIDL_APPDATA,
            CSIDL_PRINTHOOD,
            CSIDL_LOCAL_APPDATA,
            CSIDL_ALTSTARTUP,
            CSIDL_COMMON_ALTSTARTUP,
            CSIDL_COMMON_FAVORITES,
            CSIDL_INTERNET_CACHE,
            CSIDL_COOKIES,
            CSIDL_HISTORY,
            CSIDL_COMMON_APPDATA,
            CSIDL_WINDOWS,
            CSIDL_SYSTEM,
            CSIDL_PROGRAM_FILES,
            CSIDL_MYPICTURES,
            CSIDL_PROFILE,
            CSIDL_SYSTEMX86,
            CSIDL_PROGRAM_FILESX86,
            CSIDL_PROGRAM_FILES_COMMON,
            CSIDL_PROGRAM_FILES_COMMONX86,
            CSIDL_COMMON_TEMPLATES,
            CSIDL_COMMON_DOCUMENTS,
            CSIDL_COMMON_ADMINTOOLS,
            CSIDL_ADMINTOOLS,
            CSIDL_CONNECTIONS,  // = 49
            CSIDL_COMMON_MUSIC     = 53,
            CSIDL_COMMON_PICTURES,
            CSIDL_COMMON_VIDEO,
            CSIDL_RESOURCES,
            CSIDL_RESOURCES_LOCALIZED,
            CSIDL_COMMON_OEM_LINKS,
            CSIDL_CDBURN_AREA,  // = 59
            CSIDL_COMPUTERSNEARME  = 61,
            CSIDL_FLAG_DONT_VERIFY = 0x4000,
            CSIDL_FLAG_CREATE      = 0x8000,
            CSIDL_FLAG_MASK        = 0xFF00
        }
    }
    
    private  {
        alias GetSpecialFolderPath = extern(Windows) BOOL function (HWND, wchar*, int, BOOL);
        
        version(LinkedShell32) {
            extern(Windows) BOOL SHGetSpecialFolderPathW(HWND, wchar*, int, BOOL);
            GetSpecialFolderPath ptrSHGetSpecialFolderPath = &SHGetSpecialFolderPathW;
        } else {
            GetSpecialFolderPath ptrSHGetSpecialFolderPath = null;
        }
    }
    
    version(LinkedShell32) {} else {
        shared static this() 
        {
            HMODULE lib = LoadLibraryA("Shell32");
            if (lib) {
                ptrSHGetSpecialFolderPath = cast(GetSpecialFolderPath)GetProcAddress(lib, "SHGetSpecialFolderPathW");
            }
        }
    }
    
    
    private string getCSIDLFolder(wchar* path, int csidl)
    {
        import core.stdc.wchar_ : wcslen;
        if (ptrSHGetSpecialFolderPath(null, path, csidl, FALSE)) {
            size_t len = wcslen(path);
            return toUTF8(path[0..len]);
        }
        return null;
    }
    
    string writablePath(StandardPath type)
    {
        if (!ptrSHGetSpecialFolderPath) {
            return null;
        }
        
        wchar[MAX_PATH] buf;
        wchar* path = buf.ptr;
        
        final switch(type) {
            case StandardPath.Config:
            case StandardPath.Data:
                return getCSIDLFolder(path, CSIDL_LOCAL_APPDATA);
            case StandardPath.Cache:
                return buildPath(getCSIDLFolder(path, CSIDL_LOCAL_APPDATA), "cache");
            case StandardPath.Desktop:
                return getCSIDLFolder(path, CSIDL_DESKTOPDIRECTORY);
            case StandardPath.Documents:
                return getCSIDLFolder(path, CSIDL_PERSONAL);
            case StandardPath.Pictures:
                return getCSIDLFolder(path, CSIDL_MYPICTURES);
            case StandardPath.Music:
                return getCSIDLFolder(path, CSIDL_MYMUSIC);
            case StandardPath.Videos:
                return getCSIDLFolder(path, CSIDL_MYVIDEO);
            case StandardPath.Download:
                return null;
            case StandardPath.Templates:
                return getCSIDLFolder(path, CSIDL_TEMPLATES);
            case StandardPath.PublicShare:
                return null;
            case StandardPath.Fonts:
                return null;
            case StandardPath.Applications:
                return getCSIDLFolder(path, CSIDL_PROGRAMS);
        }
    }
    
    string[] standardPaths(StandardPath type)
    {
        if (!ptrSHGetSpecialFolderPath) {
            return null;
        }
        
        string commonPath;
        wchar[MAX_PATH] buf;
        wchar* path = buf.ptr;
        
        switch(type) {
            case StandardPath.Config:
            case StandardPath.Data:
                commonPath = getCSIDLFolder(path, CSIDL_COMMON_APPDATA);
                break;
            case StandardPath.Desktop:
                commonPath = getCSIDLFolder(path, CSIDL_COMMON_DESKTOPDIRECTORY);
                break;
            case StandardPath.Documents:
                commonPath = getCSIDLFolder(path, CSIDL_COMMON_DOCUMENTS);
                break;
            case StandardPath.Pictures:
                commonPath = getCSIDLFolder(path, CSIDL_COMMON_PICTURES);
                break;
            case StandardPath.Music:
                commonPath = getCSIDLFolder(path, CSIDL_COMMON_MUSIC);
                break;
            case StandardPath.Videos:
                commonPath = getCSIDLFolder(path, CSIDL_COMMON_VIDEO);
                break;
            case StandardPath.Templates:
                commonPath = getCSIDLFolder(path, CSIDL_COMMON_TEMPLATES);
                break;
            case StandardPath.Fonts:
                commonPath = getCSIDLFolder(path, CSIDL_FONTS);
                break;
            case StandardPath.Applications:
                commonPath = getCSIDLFolder(path, CSIDL_COMMON_PROGRAMS);
                break;
            default:
                break;
        }
        
        string[] paths;
        string userPath = writablePath(type);
        if (userPath.length) 
            paths ~= userPath;
        if (commonPath.length)
            paths ~= commonPath;
        return paths;
    }
    
    string[] executableExtensions() 
    {
        static bool filenamesEqual(string first, string second) {
            return filenameCmp(first, second) == 0;
        }
    
        string[] extensions = environment.get("PATHEXT").splitter(pathVarSeparator).array;
        if (canFind!(filenamesEqual)(extensions, ".exe") == false) {
            extensions = [".exe", ".com", ".bat", ".cmd"];
        }
        return extensions;
    }
} else version(OSX) {
    
    string fsPath(short domain, OSType type) 
    {
        import std.string : fromStringz;
        
        FSRef fsref;
        OSErr err = FSFindFolder(domain, type, false, &fsref);
        if (err) {
            return null;
        } else {
            ubyte[2048] buf;
            ubyte* path = buf.ptr;
            if (FSRefMakePath(&fsref, path, path.sizeof) == noErr) {
                const(char)* cpath = cast(const(char)*)path;
                return fromStringz(cpath).idup;
            } else {
                return null;
            }
        }
    }
    
    string writablePath(StandardPath type)
    {
        final switch(type) {
            case StandardPath.Config:
                return fsPath(kUserDomain, kPreferencesFolderType);
            case StandardPath.Cache:
                return fsPath(kUserDomain, kCachedDataFolderType);
            case StandardPath.Data:
                return fsPath(kUserDomain, kApplicationSupportFolderType);
            case StandardPath.Desktop:
                return fsPath(kUserDomain, kDesktopFolderType);
            case StandardPath.Documents:
                return fsPath(kUserDomain, kDocumentsFolderType);
            case StandardPath.Pictures:
                return fsPath(kUserDomain, kPictureDocumentsFolderType);
            case StandardPath.Music:
                return fsPath(kUserDomain, kMusicDocumentsFolderType);
            case StandardPath.Videos:
                return fsPath(kUserDomain, kMovieDocumentsFolderType);
            case StandardPath.Download:
                return null;
            case StandardPath.Templates:
                return null;
            case StandardPath.PublicShare:
                return fsPath(kUserDomain, kPublicFolderType );
            case StandardPath.Fonts:
                return fsPath(kUserDomain, kFontsFolderType);
            case StandardPath.Applications:
                return fsPath(kUserDomain, kApplicationsFolderType);
        }
    }
    
    string[] standardPaths(StandardPath type)
    {
        string commonPath;
        
        switch(type) {
            case StandardPath.Fonts:
                commonPath = fsPath(kOnAppropriateDisk, kFontsFolderType);
            case StandardPath.Applications:
                commonPath = fsPath(kOnAppropriateDisk, kApplicationsFolderType);
            case StandardPath.Data:
                commonPath = fsPath(kOnAppropriateDisk, kApplicationSupportFolderType);
            case StandardPath.Cache:
                commonPath = fsPath(kOnAppropriateDisk, kCachedDataFolderType);
        }
        
        string[] paths;
        string userPath = writablePath(type);
        if (userPath.length)
            paths ~= userPath;
        if (commonPath.length)
            paths ~= commonPath;
        return paths;
    }
    
} else {
    
    //Concat two paths, but if the first one is empty, then null string is returned.
    private string homeConcat(string home, string path) {
        return home.empty ? null : home ~ path;
    }
    
    private string xdgBaseDir(in char[] envvar, string fallback) {
        string dir = environment.get(envvar);
        if (!dir.length) {
            dir = homeConcat(homeDir(), fallback);
        }
        return dir;
    }
    
    private string xdgUserDir(in char[] key, string fallback) {
        import std.algorithm : startsWith, countUntil;
        
        //Read /etc/xdg/user-dirs.defaults for fallbacks?
        
        string configDir = writablePath(StandardPath.Config);
        string fileName = configDir ~ "/user-dirs.dirs";
        string home = homeDir();
        try {
            auto f = File(fileName, "r");
            
            auto xdgdir = "XDG_" ~ key ~ "_DIR";
            
            char[] buf;
            while(f.readln(buf)) {
                char[] line = buf[0..$-1]; //remove line terminator
                if (line.startsWith(xdgdir)) {
                    ptrdiff_t index = line.countUntil('=');
                    if (index != -1) {
                        line = line[index+1..$];
                        if (line.length > 2 && 
                            line[0] == '"' && 
                            line[$-1] == '"') {
                            line = line[1..$-1];
                        }
                        
                        if (line.startsWith("$HOME")) {
                            return homeConcat(home, assumeUnique(line[5..$]));
                        }
                        if (line.length == 0 || line[0] != '/') {
                            continue;
                        }
                        return assumeUnique(line);
                    }
                }
            }
        }
        catch(Exception e) {
            
        }
        
        return homeConcat(home, fallback);
    }
    
    private string[] xdgConfigDirs() {
        string configDirs = environment.get("XDG_CONFIG_DIRS");
        if (configDirs.length) {
            return splitter(configDirs, pathVarSeparator).array;
        } else {
            return ["/etc/xdg"];
        }
    }
    
    private string[] xdgDataDirs() {
        string dataDirs = environment.get("XDG_DATA_DIRS");
        if (dataDirs.length) {
            return splitter(dataDirs, pathVarSeparator).array;
        } else {
            return ["/usr/local/share/", "/usr/share/"];
        }
    }
    
    private string[] fontPaths() {
        //Should be changed in future since std.xml is deprecated
        import std.xml;
        
        string[] paths;
        
        string[] configs = [homeDir() ~ "/.fonts.conf", "/etc/fonts/fonts.conf"];
        
        foreach(config; configs) {
            try {
                string contents = cast(string)read(config);
                check(contents);
                auto parser = new DocumentParser(contents);
                parser.onEndTag["dir"] = (in Element xml)
                {
                    string path = xml.text;
                    
                    if (path.length && path[0] == '~') {
                        path = homeDir() ~ path[1..$];
                    } else {
                        const(string)* prefix = "prefix" in xml.tag.attr;
                        if (prefix && *prefix == "xdg") {
                            path = buildPath(writablePath(StandardPath.Data), path);
                        }
                    }
                    paths ~= path;
                };
                parser.parse();
            }
            catch(Exception e) {
                
            }
        }
        return paths;
    }
    
    string runtimeDir() 
    {
        import core.sys.posix.pwd;
        import core.sys.posix.unistd;
        import core.sys.posix.sys.stat;
        import core.sys.posix.sys.types;
        import core.stdc.errno;
        import core.stdc.string;
        
        import std.string : fromStringz, toStringz;
        import std.stdio : stderr;
        
        const uid_t uid = getuid();
        string runtime = environment.get("XDG_RUNTIME_DIR");
        
        mode_t runtimeMode = octal!700;
        
        if (!runtime.length) {
            setpwent();
            passwd* pw = getpwuid(uid);
            endpwent();
            
            if (pw && pw.pw_name) {
                runtime = tempDir() ~ "/runtime-" ~ assumeUnique(fromStringz(pw.pw_name));
                
                if (!(runtime.exists && runtime.isDir)) {
                    if (mkdir(runtime.toStringz, runtimeMode) != 0) {
                        stderr.writefln("Failed to create runtime directory %s: %s", runtime, fromStringz(strerror(errno)));
                        return null;
                    }
                }
            } else {
                stderr.writefln("Failed to get user name to create runtime directory");
                return null;
            }
        }
        stat_t statbuf;
        stat(runtime.toStringz, &statbuf);
        if (statbuf.st_uid != uid) {
            stderr.writefln("Wrong ownership of runtime directory %s, %d instead of %d", runtime, statbuf.st_uid, uid);
            return null;
        }
        if ((statbuf.st_mode & octal!777) != runtimeMode) {
            stderr.writefln("Wrong permissions on runtime directory %s, %o instead of %o", runtime, statbuf.st_mode, runtimeMode);
            return null;
        }
        
        return runtime;
    }
    
    string writablePath(StandardPath type)
    {
        final switch(type) {
            case StandardPath.Config:
                return xdgBaseDir("XDG_CONFIG_HOME", "/.config");
            case StandardPath.Cache:
                return xdgBaseDir("XDG_CACHE_HOME", "/.cache");
            case StandardPath.Data:
                return xdgBaseDir("XDG_DATA_HOME", "/.local/share");
            case StandardPath.Desktop:
                return xdgUserDir("DESKTOP", "/Desktop");
            case StandardPath.Documents:
                return xdgUserDir("DOCUMENTS", "/Documents");
            case StandardPath.Pictures:
                return xdgUserDir("PICTURES", "/Pictures");
            case StandardPath.Music:
                return xdgUserDir("MUSIC", "/Music");
            case StandardPath.Videos:
                return xdgUserDir("VIDEOS", "/Videos");
            case StandardPath.Download:
                return xdgUserDir("DOWNLOAD", "/Downloads");
            case StandardPath.Templates:
                return xdgUserDir("TEMPLATES", "/Templates");
            case StandardPath.PublicShare:
                return xdgUserDir("PUBLICSHARE", "/Public");
            case StandardPath.Fonts:
            {
                string[] paths = fontPaths();
                if (paths.length)
                    return paths[0];
                return null;
            }
            case StandardPath.Applications:
                return null;
        }
    }
    
    string[] standardPaths(StandardPath type)
    {
        string[] paths;
        
        if (type == StandardPath.Data) {
            paths = xdgDataDirs();
        } else if (type == StandardPath.Config) {
            paths = xdgConfigDirs();
        } else if (type == StandardPath.Fonts) {
            return fontPaths();
        }
        
        return writablePath(type) ~ paths;
    }
}

private bool isExecutable(string filePath) {
    version(Posix) {
        return (getAttributes(filePath) & octal!100) != 0;
    } else version(Windows) {
        //Use GetEffectiveRightsFromAclW?
        
        const(string)[] exeExtensions = executableExtensions();
        foreach(ext; exeExtensions) {
            if (filePath.extension == ext)
                return true;
        }
        return false;
        
    } else {
        static assert(false, "Unsupported platform");
    }
}

private string checkExecutable(string filePath) {
    try {
        if (filePath.isFile && filePath.isExecutable) {
            return buildNormalizedPath(filePath);
        } else {
            return null;
        }
    }
    catch(FileException e) {
        return null;
    }
}

string findExecutable(string fileName, in string[] paths = [])
{
    if (fileName.isAbsolute()) {
        return checkExecutable(fileName);
    }
    
    const(string)[] searchPaths = paths;
    if (searchPaths.empty) {
        string pathVar = environment.get("PATH");
        if (pathVar.length) {
            searchPaths = splitter(pathVar, pathVarSeparator).array;
        }
    }
    
    if (searchPaths.empty) {
        return null;
    }
    
    string toReturn;
    foreach(string path; searchPaths) {
        string candidate = buildPath(absolutePath(path), fileName);
        
        version(Windows) {
            if (candidate.extension.empty) {
                foreach(exeExtension; executableExtensions()) {
                    toReturn = checkExecutable(setExtension(candidate, exeExtension));
                    if (toReturn.length) {
                        return toReturn;
                    }
                }
            }
        }
        
        toReturn = checkExecutable(candidate);
        if (toReturn.length) {
            return toReturn;
        }
    }
    return null;
}


