/**
 * Functions for retrieving standard paths in cross-platform manner.
 * 
 */

module standardpaths;

private {
    import std.process : environment;
    import std.array;
    import std.path;
    import std.file;
    import std.algorithm : splitter;
    
    debug(standardpaths) {
        import std.stdio : stderr;
    }
}

version(Windows) {
    private {
        import std.c.windows.windows;
        import std.utf;
        import std.algorithm : canFind;
        import std.uni : toLower, sicmp;
    }
} else version(OSX) {
    private {
        //what to import?
    }
} else version(Posix) {
    private {
        import std.stdio : File, StdioException;
        import std.exception : assumeUnique, assumeWontThrow;
        import std.conv : octal;
    }
} else {
    static assert(false, "Unsupported platform");
}

/** 
 * Locations that can be passed to writablePath and standardPaths functions.
 * See_Also:
 *  writablePath, standardPaths
 */
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

/**
 * Returns: path to user home directory, or an empty string if could not determine home directory.
 * Note: this function does not provide caching of its results.
 */
string homeDir() nothrow
{
    version(Windows) {
        try { //environment.get may throw on Windows
            
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
        }
        catch(Exception e) {
            debug(standardpaths) stderr.writeln(e.msg);
            return null;
        }
    } else {
        string home = assumeWontThrow(environment.get("HOME"));
        return home;
    }
    
}

/**
 * Returns: path where files of $(U type) should be written to by current user, or an empty string if could not determine path.
 * This function does not ensure if the returned path exists and appears to be accessible directory.
 * Note: this function does not provide caching of its results.
 */
string writablePath(StandardPath type) nothrow;

/**
 * Returns: array of paths where files of $(U type) belong including one returned by $(B writablePath), or an empty array if no paths are defined for $(U type).
 * This function does not ensure if all returned paths exist and appear to be accessible directories.
 * Note: this function does not provide caching of its results. Also returned strings are not required to be unique.
 * It may cause performance impact to call this function often since retrieving some paths can be expensive operation.
 * See_Also:
 *  writablePath
 */
string[] standardPaths(StandardPath type) nothrow;

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
        alias GetSpecialFolderPath = extern(Windows) BOOL function (HWND, wchar*, int, BOOL) nothrow;
        
        version(LinkedShell32) {
            extern(Windows) BOOL SHGetSpecialFolderPathW(HWND, wchar*, int, BOOL) nothrow;
            __gshared GetSpecialFolderPath ptrSHGetSpecialFolderPath = &SHGetSpecialFolderPathW;
        } else {
            __gshared GetSpecialFolderPath ptrSHGetSpecialFolderPath = null;
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
    
    
    private string getCSIDLFolder(wchar* path, int csidl) nothrow
    {
        import core.stdc.wchar_ : wcslen;
        if (ptrSHGetSpecialFolderPath(null, path, csidl, FALSE)) {
            size_t len = wcslen(path);
            try {
                return toUTF8(path[0..len]);
            } catch(Exception e) {
                
            }
        }
        return null;
    }
    
    string writablePath(StandardPath type) nothrow
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
    
    string[] standardPaths(StandardPath type) nothrow
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
    
    private string[] executableExtensions() nothrow
    {
        static bool filenamesEqual(string first, string second) nothrow {
            try {
                return filenameCmp(first, second) == 0;
            } catch(Exception e) {
                return false;
            }
        }
        
        string[] extensions;
        try {
            extensions = environment.get("PATHEXT").splitter(pathVarSeparator).array;
            if (canFind!(filenamesEqual)(extensions, ".exe") == false) {
                extensions = [];
            }
        } catch (Exception e) {
            
        }
        if (extensions.empty) {
            extensions = [".exe", ".com", ".bat", ".cmd"];
        }
        return extensions;
    }
} else version(OSX) {
    
    string fsPath(short domain, OSType type) nothrow @trusted
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
                auto cpath = cast(const(char)*)path;
                return fromStringz(cpath).idup;
            } else {
                return null;
            }
        }
    }
    
    string writablePath(StandardPath type) nothrow
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
    
    string[] standardPaths(StandardPath type) nothrow
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
    
    //Concat two strings, but if the first one is empty, then null string is returned.
    private string maybeConcat(string start, string path) nothrow
    {
        return start.empty ? null : start ~ path;
    }
    
    private string xdgBaseDir(in char[] envvar, string fallback) nothrow {
        string dir = assumeWontThrow(environment.get(envvar));
        if (!dir.length) {
            dir = maybeConcat(homeDir(), fallback);
        }
        return dir;
    }
    
    private string xdgUserDir(in char[] key, string fallback = null) nothrow {
        import std.algorithm : startsWith, countUntil;
        
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
                            return maybeConcat(home, assumeUnique(line[5..$]));
                        }
                        if (line.length == 0 || line[0] != '/') {
                            continue;
                        }
                        return assumeUnique(line);
                    }
                }
            }
        } catch(Exception e) {
            
        }
        
        if (home.length) {
            if (fallback.length) {
                return home ~ fallback;
            }
            try {
                auto f = File("/etc/xdg/user-dirs.defaults", "r");
                char[] buf;
                while(f.readln(buf)) {
                    char[] line = buf[0..$-1];
                    if (line.startsWith(key)) {
                        ptrdiff_t index = line.countUntil('=');
                        if (index != -1) {
                            line = line[index+1..$];
                            return home ~ "/" ~ assumeUnique(line);
                        }
                    }
                }
            } catch (Exception e) {
                
            }
        }
        return null;
    }
    
    private string[] xdgConfigDirs() nothrow {
        string configDirs = assumeWontThrow(environment.get("XDG_CONFIG_DIRS"));
        try {
            if (configDirs.length) {
                return splitter(configDirs, pathVarSeparator).array;
            }
        }
        catch(Exception e) {
            
        }
        return ["/etc/xdg"];
    }
    
    private string[] xdgDataDirs() nothrow {
        string dataDirs = assumeWontThrow(environment.get("XDG_DATA_DIRS"));
        try {
            if (dataDirs.length) {
                return splitter(dataDirs, pathVarSeparator).array;
            }
        } catch(Exception e) {
            
        }
        return ["/usr/local/share", "/usr/share"];
    }
    
    private string[] readFontsConfig(string configFile) nothrow
    {
        //Should be changed in future since std.xml is deprecated
        import std.xml;
        
        string[] paths;
        try {
            string contents = cast(string)read(configFile);
            check(contents);
            auto parser = new DocumentParser(contents);
            parser.onEndTag["dir"] = (in Element xml)
            {
                string path = xml.text;
                
                if (path.length && path[0] == '~') {
                    path = maybeConcat(homeDir(), path[1..$]);
                } else {
                    const(string)* prefix = "prefix" in xml.tag.attr;
                    if (prefix && *prefix == "xdg") {
                        string dataPath = writablePath(StandardPath.Data);
                        if (dataPath.length) {
                            path = buildPath(dataPath, path);
                        }
                    }
                }
                if (path.length) {
                    paths ~= path;
                }
            };
            parser.parse();
        }
        catch(Exception e) {
            
        }
        return paths;
    }
    
    private string[] fontPaths() nothrow
    {
        string[] paths;
        
        string homeConfig = homeFontsConfig();
        if (homeConfig.length) {
            paths ~= readFontsConfig(homeConfig);
        }
        
        enum configs = ["/etc/fonts/fonts.conf", //path on linux
                        "/usr/local/etc/fonts/fonts.conf"]; //path on freebsd
        foreach(config; configs) {
            paths ~= readFontsConfig(config);
        }
        return paths;
    }
    
    private string homeFontsConfig() nothrow {
        return maybeConcat(writablePath(StandardPath.Config), "/fontconfig/fonts.conf");
    }
    
    /**
     * Returns user's runtime directory determined by $(B XDG_RUNTIME_DIR) environment variable. 
     * If directory does not exist it tries to create one with appropriate permissions. On fail returns an empty string.
     * Note: this function is defined only on $(B Posix) systems (except for OS X)
     */
    string runtimeDir() nothrow
    {
        // Do we need it on BSD systems?
        
        import core.sys.posix.pwd;
        import core.sys.posix.unistd;
        import core.sys.posix.sys.stat;
        import core.sys.posix.sys.types;
        import core.stdc.errno;
        import core.stdc.string;
        
        import std.string : fromStringz, toStringz;
        
        const uid_t uid = getuid();
        string runtime = assumeWontThrow(environment.get("XDG_RUNTIME_DIR"));
        
        mode_t runtimeMode = octal!700;
        
        if (!runtime.length) {
            setpwent();
            passwd* pw = getpwuid(uid);
            endpwent();
            
            try {
                if (pw && pw.pw_name) {
                    runtime = tempDir() ~ "/runtime-" ~ assumeUnique(fromStringz(pw.pw_name));
                    
                    if (!(runtime.exists && runtime.isDir)) {
                        if (mkdir(runtime.toStringz, runtimeMode) != 0) {
                            debug(standardpaths) stderr.writefln("Failed to create runtime directory %s: %s", runtime, fromStringz(strerror(errno)));
                            return null;
                        }
                    }
                } else {
                    debug(standardpaths) stderr.writefln("Failed to get user name to create runtime directory");
                    return null;
                }
            } catch(Exception e) {
                debug(standardpaths) stderr.writeln(e.msg);
                return null;
            }
        }
        stat_t statbuf;
        stat(runtime.toStringz, &statbuf);
        if (statbuf.st_uid != uid) {
            debug(standardpaths) stderr.writefln("Wrong ownership of runtime directory %s, %d instead of %d", runtime, statbuf.st_uid, uid);
            return null;
        }
        if ((statbuf.st_mode & octal!777) != runtimeMode) {
            debug(standardpaths) stderr.writefln("Wrong permissions on runtime directory %s, %o instead of %o", runtime, statbuf.st_mode, runtimeMode);
            return null;
        }
        
        return runtime;
    }
    
    string writablePath(StandardPath type) nothrow
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
                return xdgUserDir("DOCUMENTS");
            case StandardPath.Pictures:
                return xdgUserDir("PICTURES");
            case StandardPath.Music:
                return xdgUserDir("MUSIC");
            case StandardPath.Videos:
                return xdgUserDir("VIDEOS");
            case StandardPath.Download:
                return xdgUserDir("DOWNLOAD");
            case StandardPath.Templates:
                return xdgUserDir("TEMPLATES", "/Templates");
            case StandardPath.PublicShare:
                return xdgUserDir("PUBLICSHARE", "/Public");
            case StandardPath.Fonts:
            {
                string[] paths = readFontsConfig(homeFontsConfig());
                if (paths.length)
                    return paths[0];
                return null;
            }
                
            case StandardPath.Applications:
                return null;
        }
    }
    
    string[] standardPaths(StandardPath type) nothrow
    {
        string[] paths;
        
        if (type == StandardPath.Data) {
            paths = xdgDataDirs();
        } else if (type == StandardPath.Config) {
            paths = xdgConfigDirs();
        } else if (type == StandardPath.Fonts) {
            return fontPaths();
        }
        
        string userPath = writablePath(type);
        if (userPath.length) {
            paths = userPath ~ paths;
        }
        return paths;
    }
}

private bool isExecutable(string filePath) nothrow {
    try {
        version(Posix) {
            return (getAttributes(filePath) & octal!100) != 0;
        } else version(Windows) {
            //Use GetEffectiveRightsFromAclW?
            
            const(string)[] exeExtensions = executableExtensions();
            foreach(ext; exeExtensions) {
                if (sicmp(filePath.extension, ext) == 0)
                    return true;
            }
            return false;
            
        } else {
            static assert(false, "Unsupported platform");
        }
    } catch(Exception e) {
        return false;
    }
}

private string checkExecutable(string filePath) nothrow {
    try {
        if (filePath.isFile && filePath.isExecutable) {
            return buildNormalizedPath(filePath);
        } else {
            return null;
        }
    }
    catch(Exception e) {
        return null;
    }
}

/**
 * Finds executable by $(B fileName) in the paths specified by $(B paths).
 * Returns: absolute path to the existing executable file or an empty string if not found.
 * Params:
 *  fileName = name of executable to search
 *  paths = array of directories where executable should be searched. If not set, search in system paths, usually determined by PATH environment variable
 * Note: on Windows when fileName extension is omitted, executable extensions will be automatically appended during search.
 */
string findExecutable(string fileName, in string[] paths = []) nothrow
{
    try {
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
                        toReturn = checkExecutable(setExtension(candidate, exeExtension.toLower()));
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
    } catch (Exception e) {
        
    }
    return null;
}


