/**
 * Functions for retrieving standard paths in cross-platform manner.
 * Authors: 
 *  $(LINK2 https://github.com/MyLittleRobo, Roman Chistokhodov)
 * License: 
 *  $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost License 1.0).
 * Copyright:
 *  Roman Chistokhodov 2015
 */

module standardpaths;

private {
    import std.process : environment;
    import std.array;
    import std.path;
    import std.file;
    import std.algorithm : splitter, canFind, filter;
    import std.exception;
    import std.range;
    
    import isfreedesktop;
    
    debug {
        import std.stdio : stderr;
    }
    
    static if( __VERSION__ < 2066 ) enum nogc = 1;
}

version(Windows) {
    private {
        static if (__VERSION__ < 2070) {
            import std.c.windows.windows;
        } else {
            import core.sys.windows.windows;
        }
        
        import std.utf;
        import std.uni : toLower, sicmp;
    }
} else version(Posix) {
    private {
        import std.stdio : File, StdioException;
        import std.conv : octal;
        import std.string : toStringz;
        
        static if (is(typeof({import std.string : fromStringz;}))) {
            import std.string : fromStringz;
        } else { //own fromStringz implementation for compatibility reasons
            import std.c.string : strlen;
            @system pure inout(char)[] fromStringz(inout(char)* cString) {
                return cString ? cString[0..strlen(cString)] : null;
            }
        }
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
    /**
     * General location of persisted application data. Every application should have its own subdirectory here.
     * Note: on Windows it's the same as $(B config) path.
     */
    data,
    /**
     * General location of configuration files. Every application should have its own subdirectory here.
     * Note: on Windows it's the same as $(B data) path. To distinguish config directory one may use roamingPath.
     */
    config,
    /**
     * Location of cached data.
     * Note: Windows does not provide specical directory for cache data. On Windows $(B data)/cache is used as cache folder.
     */
    cache,
    ///User's desktop directory.
    desktop,
    ///User's documents.
    documents,
    ///User's pictures.
    pictures,
    
    ///User's music.
    music,
    
    ///User's videos (movies).
    videos,
    
    ///Directory for user's downloaded files.
    downloads,
    
    /**
     * Location of file templates (e.g. office suite document templates).
     * Note: Not available on OS X.
     */
    templates,
    
    /** 
     * Public share folder.
     * Note: Not available on Windows.
     */
    publicShare,
    /**
     * Location of fonts files.
     * Note: don't rely on this on freedesktop, since it uses hardcoded paths there. Better consider using $(LINK2 http://www.freedesktop.org/wiki/Software/fontconfig/, fontconfig library)
     */
    fonts,
    ///User's applications.
    applications,
}

/**
 * Current user home directory.
 * Returns: Path to user home directory, or an empty string if could not determine home directory.
 * Relies on environment variables.
 * Note: This function does not cache its result.
 */
string homeDir() nothrow @safe
{
    try {
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
    catch (Exception e) {
        debug {
            @trusted void writeException(Exception e) nothrow {
                collectException(stderr.writefln("Error when getting home directory %s", e.msg));
            }
            writeException(e);
        }
        return null;
    }
}

/**
 * Getting writable paths for various locations.
 * Returns: Path where files of $(U type) should be written to by current user, or an empty string if could not determine path.
 * This function does not ensure if the returned path exists and appears to be accessible directory.
 * Note: This function does not cache its results.
 */
string writablePath(StandardPath type) nothrow @safe;

/**
 * Getting paths for various locations.
 * Returns: Array of paths where files of $(U type) belong including one returned by $(B writablePath), or an empty array if no paths are defined for $(U type).
 * This function does not ensure if all returned paths exist and appear to be accessible directories. Returned strings are not required to be unique.
 * Note: This function does cache its results. 
 * It may cause performance impact to call this function often since retrieving some paths can be relatively expensive operation.
 * See_Also:
 *  writablePath
 */
string[] standardPaths(StandardPath type) nothrow @safe;


version(StandardPathsDocs)
{
    /**
     * Path to runtime user directory on freedesktop platforms.
     * Returns: User's runtime directory determined by $(B XDG_RUNTIME_DIR) environment variable. 
     * If directory does not exist it tries to create one with appropriate permissions. On fail returns an empty string.
     * Note: Deprecated, use xdgRuntimeDir instead.
     */
    deprecated string runtimeDir() nothrow @trusted;
    
    /**
     * Path to $(B Roaming) data directory. 
     * Returns: User's Roaming directory. On fail returns an empty string.
     * Note: This function is Windows only.
     */
    string roamingPath() nothrow @safe;
    
    /**
     * Location where games may store their saves. 
     * This is common path for games. One should use subfolder for their game saves.
     * Returns: User's Saved Games directory. On fail returns an empty string.
     * Note: This function is Windows only.
     */
    string savedGames() nothrow @safe;
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
        private extern(Windows) @nogc @system BOOL dummy(HWND, wchar*, int, BOOL) nothrow { return 0; }
        alias typeof(&dummy) GetSpecialFolderPath;
        
        version(LinkedShell32) {
            extern(Windows) @nogc @system BOOL SHGetSpecialFolderPathW(HWND, wchar*, int, BOOL) nothrow;
            __gshared GetSpecialFolderPath ptrSHGetSpecialFolderPath = &SHGetSpecialFolderPathW;
        } else {
            __gshared GetSpecialFolderPath ptrSHGetSpecialFolderPath = null;
        }
        
        static if (__VERSION__ >= 2070) {
            import core.sys.windows.winreg;
        }
        
        alias typeof(&RegOpenKeyExW) func_RegOpenKeyEx;
        alias typeof(&RegQueryValueExW) func_RegQueryValueEx;
        alias typeof(&RegCloseKey) func_RegCloseKey;
        
        version(LinkedAdvApi) {
            __gshared func_RegOpenKeyEx ptrRegOpenKeyEx = &RegOpenKeyExW;
            __gshared func_RegQueryValueEx ptrRegQueryValueEx = &RegQueryValueExW;
            __gshared func_RegCloseKey ptrRegCloseKey = &RegCloseKey;
        } else {
            __gshared func_RegOpenKeyEx ptrRegOpenKeyEx = null;
            __gshared func_RegQueryValueEx ptrRegQueryValueEx = null;
            __gshared func_RegCloseKey ptrRegCloseKey = null;
        }
        
        @nogc @trusted bool hasSHGetSpecialFolderPath() nothrow {
            return ptrSHGetSpecialFolderPath != null;
        }
        
        @nogc @trusted bool isAdvApiLoaded() nothrow {
            return ptrRegOpenKeyEx != null && ptrRegQueryValueEx != null && ptrRegCloseKey != null;
        }
    }
    
    shared static this() 
    {
        version(LinkedShell32) {} else {
            HMODULE shellLib = LoadLibraryA("Shell32");
            if (shellLib) {
                ptrSHGetSpecialFolderPath = cast(GetSpecialFolderPath)GetProcAddress(shellLib, "SHGetSpecialFolderPathW");
            }
        }
        
        version(LinkedAdvApi) {} else {
            HMODULE advApi = LoadLibraryA("Advapi32.dll");
            if (advApi) {
                ptrRegOpenKeyEx = cast(func_RegOpenKeyEx)GetProcAddress(advApi, "RegOpenKeyExW");
                ptrRegQueryValueEx = cast(func_RegQueryValueEx)GetProcAddress(advApi, "RegQueryValueExW");
                ptrRegCloseKey = cast(func_RegCloseKey)GetProcAddress(advApi, "RegCloseKey");
            }
        }
    }
    
    private string getShellFolder(const(wchar)* key) nothrow @trusted
    {
        HKEY hKey;
        if (isAdvApiLoaded()) {    
            auto result = ptrRegOpenKeyEx(HKEY_CURRENT_USER, 
                "Software\\Microsoft\\Windows\\CurrentVersion\\Explorer\\Shell Folders\0"w.ptr,
                0,
                KEY_QUERY_VALUE,
                &hKey
            );
            scope(exit) ptrRegCloseKey(hKey);
            
            if (result == ERROR_SUCCESS) {
                DWORD type;
                BYTE[MAX_PATH*wchar.sizeof] buf = void;
                DWORD length = cast(DWORD)buf.length;
                result = ptrRegQueryValueEx(hKey, key, null, &type, buf.ptr, &length);
                if (result == ERROR_SUCCESS && type == REG_SZ && (length % 2 == 0)) {
                    auto str = cast(wstring)buf[0..length];
                    if (str.length && str[$-1] == '\0') {
                        str = str[0..$-1];
                    }
                    try {
                        return toUTF8(str);
                    } catch(Exception e) {
                        
                    }
                }
            }
        }
        
        return null;
    }
    
    
    private string getCSIDLFolder(int csidl) nothrow @trusted
    {
        import core.stdc.wchar_ : wcslen;
        
        wchar[MAX_PATH] path = void;
        if (hasSHGetSpecialFolderPath() && ptrSHGetSpecialFolderPath(null, path.ptr, csidl, FALSE)) {
            size_t len = wcslen(path.ptr);
            try {
                return toUTF8(path[0..len]);
            } catch(Exception e) {
                
            }
        }
        return null;
    }
    
    string roamingPath() nothrow @safe
    {
        return getCSIDLFolder(CSIDL_APPDATA);
    }
    
    string savedGames() nothrow @safe
    {
        return getShellFolder("{4C5C32FF-BB9D-43b0-B5B4-2D72E54EAAA4}\0"w.ptr);
    }
    
    string writablePath(StandardPath type) nothrow @safe
    {
        final switch(type) {
            case StandardPath.config:
            case StandardPath.data:
                return getCSIDLFolder(CSIDL_LOCAL_APPDATA);
            case StandardPath.cache:
            {
                string path = getCSIDLFolder(CSIDL_LOCAL_APPDATA);
                if (path.length) {
                    return buildPath(path, "cache");
                }
                return null;
            }
            case StandardPath.desktop:
                return getCSIDLFolder(CSIDL_DESKTOPDIRECTORY);
            case StandardPath.documents:
                return getCSIDLFolder(CSIDL_PERSONAL);
            case StandardPath.pictures:
                return getCSIDLFolder(CSIDL_MYPICTURES);
            case StandardPath.music:
                return getCSIDLFolder(CSIDL_MYMUSIC);
            case StandardPath.videos:
                return getCSIDLFolder(CSIDL_MYVIDEO);
            case StandardPath.downloads:
                return getShellFolder("{374DE290-123F-4565-9164-39C4925E467B}\0"w.ptr);
            case StandardPath.templates:
                return getCSIDLFolder(CSIDL_TEMPLATES);
            case StandardPath.publicShare:
                return null;
            case StandardPath.fonts:
                return null;
            case StandardPath.applications:
                return getCSIDLFolder(CSIDL_PROGRAMS);
        }
    }
    
    string[] standardPaths(StandardPath type) nothrow @safe
    {   
        string commonPath;
        
        switch(type) {
            case StandardPath.config:
            case StandardPath.data:
                commonPath = getCSIDLFolder(CSIDL_COMMON_APPDATA);
                break;
            case StandardPath.desktop:
                commonPath = getCSIDLFolder(CSIDL_COMMON_DESKTOPDIRECTORY);
                break;
            case StandardPath.documents:
                commonPath = getCSIDLFolder(CSIDL_COMMON_DOCUMENTS);
                break;
            case StandardPath.pictures:
                commonPath = getCSIDLFolder(CSIDL_COMMON_PICTURES);
                break;
            case StandardPath.music:
                commonPath = getCSIDLFolder(CSIDL_COMMON_MUSIC);
                break;
            case StandardPath.videos:
                commonPath = getCSIDLFolder(CSIDL_COMMON_VIDEO);
                break;
            case StandardPath.templates:
                commonPath = getCSIDLFolder(CSIDL_COMMON_TEMPLATES);
                break;
            case StandardPath.fonts:
                commonPath = getCSIDLFolder(CSIDL_FONTS);
                break;
            case StandardPath.applications:
                commonPath = getCSIDLFolder(CSIDL_COMMON_PROGRAMS);
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
    
    private const(string)[] executableExtensions() nothrow @trusted
    {
        static bool filenamesEqual(string first, string second) nothrow {
            try {
                return filenameCmp(first, second) == 0;
            } catch(Exception e) {
                return false;
            }
        }
        
        static string[] extensions;
        if (extensions.empty) {
            collectException(environment.get("PATHEXT").splitter(pathVarSeparator).array, extensions);
            if (canFind!(filenamesEqual)(extensions, ".exe") == false) {
                extensions = [".exe", ".com", ".bat", ".cmd"];
            }
        }
        
        return extensions;
    }
} else version(OSX) {
    
    private enum : short {
        kOnSystemDisk                 = -32768L, /* previously was 0x8000 but that is an unsigned value whereas vRefNum is signed*/
        kOnAppropriateDisk            = -32767, /* Generally, the same as kOnSystemDisk, but it's clearer that this isn't always the 'boot' disk.*/
                                                /* Folder Domains - Carbon only.  The constants above can continue to be used, but the folder/volume returned will*/
                                                /* be from one of the domains below.*/
        kSystemDomain                 = -32766, /* Read-only system hierarchy.*/
        kLocalDomain                  = -32765, /* All users of a single machine have access to these resources.*/
        kNetworkDomain                = -32764, /* All users configured to use a common network server has access to these resources.*/
        kUserDomain                   = -32763, /* Read/write. Resources that are private to the user.*/
        kClassicDomain                = -32762, /* Domain referring to the currently configured Classic System Folder.  Not supported in Mac OS X Leopard and later.*/
        kFolderManagerLastDomain      = -32760
    }

    private @nogc int k(string s) nothrow {
        return s[0] << 24 | s[1] << 16 | s[2] << 8 | s[3];
    }

    private enum {
        kDesktopFolderType            = k("desk"), /* the desktop folder; objects in this folder show on the desktop. */
        kTrashFolderType              = k("trsh"), /* the trash folder; objects in this folder show up in the trash */
        kWhereToEmptyTrashFolderType  = k("empt"), /* the "empty trash" folder; Finder starts empty from here down */
        kFontsFolderType              = k("font"), /* Fonts go here */
        kPreferencesFolderType        = k("pref"), /* preferences for applications go here */
        kSystemPreferencesFolderType  = k("sprf"), /* the PreferencePanes folder, where Mac OS X Preference Panes go */
        kTemporaryFolderType          = k("temp"), /*    On Mac OS X, each user has their own temporary items folder, and the Folder Manager attempts to set permissions of these*/
                                                /*    folders such that other users can not access the data inside.  On Mac OS X 10.4 and later the data inside the temporary*/
                                                /*    items folder is deleted at logout and at boot, but not otherwise.  Earlier version of Mac OS X would delete items inside*/
                                                /*    the temporary items folder after a period of inaccess.  You can ask for a temporary item in a specific domain or on a */
                                                /*    particular volume by FSVolumeRefNum.  If you want a location for temporary items for a short time, then use either*/
                                                /*    ( kUserDomain, kkTemporaryFolderType ) or ( kSystemDomain, kTemporaryFolderType ).  The kUserDomain varient will always be*/
                                                /*    on the same volume as the user's home folder, while the kSystemDomain version will be on the same volume as /var/tmp/ ( and*/
                                                /*    will probably be on the local hard drive in case the user's home is a network volume ).  If you want a location for a temporary*/
                                                /*    file or folder to use for saving a document, especially if you want to use FSpExchangeFile() to implement a safe-save, then*/
                                                /*    ask for the temporary items folder on the same volume as the file you are safe saving.*/
                                                /*    However, be prepared for a failure to find a temporary folder in any domain or on any volume.  Some volumes may not have*/
                                                /*    a location for a temporary folder, or the permissions of the volume may be such that the Folder Manager can not return*/
                                                /*    a temporary folder for the volume.*/
                                                /*    If your application creates an item in a temporary items older you should delete that item as soon as it is not needed,*/
                                                /*    and certainly before your application exits, since otherwise the item is consuming disk space until the user logs out or*/
                                                /*    restarts.  Any items left inside a temporary items folder should be moved into a folder inside the Trash folder on the disk*/
                                                /*    when the user logs in, inside a folder named "Recovered items", in case there is anything useful to the end user.*/
        kChewableItemsFolderType      = k("flnt"), /* similar to kTemporaryItemsFolderType, except items in this folder are deleted at boot or when the disk is unmounted */
        kTemporaryItemsInCacheDataFolderType = k("vtmp"), /* A folder inside the kCachedDataFolderType for the given domain which can be used for transient data*/
        kApplicationsFolderType       = k("apps"), /*    Applications on Mac OS X are typically put in this folder ( or a subfolder ).*/
        kVolumeRootFolderType         = k("root"), /* root folder of a volume or domain */
        kDomainTopLevelFolderType     = k("dtop"), /* The top-level of a Folder domain, e.g. "/System"*/
        kDomainLibraryFolderType      = k("dlib"), /* the Library subfolder of a particular domain*/
        kUsersFolderType              = k("usrs"), /* "Users" folder, usually contains one folder for each user. */
        kCurrentUserFolderType        = k("cusr"), /* The folder for the currently logged on user; domain passed in is ignored. */
        kSharedUserDataFolderType     = k("sdat"), /* A Shared folder, readable & writeable by all users */
        kCachedDataFolderType         = k("cach"), /* Contains various cache files for different clients*/
        kDownloadsFolderType          = k("down"), /* Refers to the ~/Downloads folder*/
        kApplicationSupportFolderType = k("asup"), /* third-party items and folders */


        kDocumentsFolderType          = k("docs"), /*    User documents are typically put in this folder ( or a subfolder ).*/
        kPictureDocumentsFolderType   = k("pdoc"), /* Refers to the "Pictures" folder in a users home directory*/
        kMovieDocumentsFolderType     = k("mdoc"), /* Refers to the "Movies" folder in a users home directory*/
        kMusicDocumentsFolderType     = 0xB5646F63/*'µdoc'*/, /* Refers to the "Music" folder in a users home directory*/
        kInternetSitesFolderType      = k("site"), /* Refers to the "Sites" folder in a users home directory*/
        kPublicFolderType             = k("pubb"), /* Refers to the "Public" folder in a users home directory*/

        kDropBoxFolderType            = k("drop") /* Refers to the "Drop Box" folder inside the user's home directory*/
    };

    private {
        struct FSRef {
          char[80] hidden;    /* private to File Manager*/
        };

        alias int Boolean;
        alias int OSType;
        alias int OSerr;
        
        extern(C) @nogc @system int dummy(short, int, int, FSRef*) nothrow { return 0; }
        extern(C) @nogc @system int dummy2(const(FSRef)*, char*, uint) nothrow { return 0; }

        alias da_FSFindFolder = typeof(&dummy);
        alias da_FSRefMakePath = typeof(&dummy2);

        __gshared da_FSFindFolder ptrFSFindFolder = null;
        __gshared da_FSRefMakePath ptrFSRefMakePath = null;
    }

    shared static this()
    {
        enum carbonPath = "/System/Library/Frameworks/CoreServices.framework/Versions/A/Frameworks/CarbonCore.framework/Versions/A/CarbonCore";

        import core.sys.posix.dlfcn;

        void* handle = dlopen(toStringz(carbonPath), RTLD_NOW | RTLD_LOCAL);
        if (handle) {
            ptrFSFindFolder = cast(da_FSFindFolder)dlsym(handle, "FSFindFolder");
            ptrFSRefMakePath = cast(da_FSRefMakePath)dlsym(handle, "FSRefMakePath");
        }
        if (ptrFSFindFolder == null || ptrFSRefMakePath == null) {
            debug collectException(stderr.writeln("Could not load carbon functions"));
        }
    }

    @nogc @trusted bool isCarbonLoaded() nothrow
    {
        return ptrFSFindFolder != null && ptrFSRefMakePath != null;
    }

    enum noErr = 0;

    string fsPath(short domain, OSType type) nothrow @trusted
    {
        import std.stdio;   
        FSRef fsref;
        if (isCarbonLoaded() && ptrFSFindFolder(domain, type, false, &fsref) == noErr) {

            char[2048] buf;
            char* path = buf.ptr;
            if (ptrFSRefMakePath(&fsref, path, buf.sizeof) == noErr) {
                try {

                    return fromStringz(path).idup;
                }
                catch(Exception e) {

                }
            }
        }
        return null;
    }
    
    string writablePath(StandardPath type) nothrow @safe
    {
        final switch(type) {
            case StandardPath.config:
                return fsPath(kUserDomain, kPreferencesFolderType);
            case StandardPath.cache:
                return fsPath(kUserDomain, kCachedDataFolderType);
            case StandardPath.data:
                return fsPath(kUserDomain, kApplicationSupportFolderType);
            case StandardPath.desktop:
                return fsPath(kUserDomain, kDesktopFolderType);
            case StandardPath.documents:
                return fsPath(kUserDomain, kDocumentsFolderType);
            case StandardPath.pictures:
                return fsPath(kUserDomain, kPictureDocumentsFolderType);
            case StandardPath.music:
                return fsPath(kUserDomain, kMusicDocumentsFolderType);
            case StandardPath.videos:
                return fsPath(kUserDomain, kMovieDocumentsFolderType);
            case StandardPath.downloads:
                return fsPath(kUserDomain, kDownloadsFolderType);
            case StandardPath.templates:
                return null;
            case StandardPath.publicShare:
                return fsPath(kUserDomain, kPublicFolderType );
            case StandardPath.fonts:
                return fsPath(kUserDomain, kFontsFolderType);
            case StandardPath.applications:
                return fsPath(kUserDomain, kApplicationsFolderType);
        }
    }
    
    string[] standardPaths(StandardPath type) nothrow @safe
    {
        string commonPath;
        
        switch(type) {
            case StandardPath.fonts:
                commonPath = fsPath(kOnAppropriateDisk, kFontsFolderType);
                break;
            case StandardPath.applications:
                commonPath = fsPath(kOnAppropriateDisk, kApplicationsFolderType);
                break;
            case StandardPath.data:
                commonPath = fsPath(kOnAppropriateDisk, kApplicationSupportFolderType);
                break;
            case StandardPath.cache:
                commonPath = fsPath(kOnAppropriateDisk, kCachedDataFolderType);
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
    
} else {
    
    static if (!isFreedesktop) {
        static assert(false, "Unsupported platform");
    } else {
        public import xdgpaths;
            
        //Concat two strings, but if the first one is empty, then null string is returned.
        private string maybeConcat(string start, string path) nothrow @safe
        {
            return start.empty ? null : start ~ path;
        }
        
        private string xdgUserDir(string key, string fallback = null) nothrow @trusted {
            import std.algorithm : startsWith;
            import std.string : strip;
            
            string fileName = maybeConcat(writablePath(StandardPath.config), "/user-dirs.dirs");
            string home = homeDir();
            try {
                auto f = File(fileName, "r");
                
                auto xdgdir = "XDG_" ~ key ~ "_DIR";
                
                char[] buf;
                while(f.readln(buf)) {
                    char[] line = strip(buf);
                    auto index = xdgdir.length;
                    if (line.startsWith(xdgdir) && line.length > index && line[index] == '=') {
                        line = line[index+1..$];
                        if (line.length > 2 && line[0] == '"' && line[$-1] == '"') 
                        {
                            line = line[1..$-1];
                        
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
                try {
                    auto f = File("/etc/xdg/user-dirs.defaults", "r");
                    char[] buf;
                    while(f.readln(buf)) {
                        char[] line = strip(buf);
                        auto index = key.length;
                        if (line.startsWith(key) && line.length > index && line[index] == '=') 
                        {
                            line = line[index+1..$];
                            return home ~ "/" ~ assumeUnique(line);
                        }
                    }
                } catch (Exception e) {
                    
                }
                if (fallback.length) {
                    return home ~ fallback;
                }
            }
            return null;
        }
        
        private string homeFontsPath() nothrow @trusted {
            return maybeConcat(homeDir(), "/.fonts");
        }
        
        private string[] fontPaths() nothrow @trusted
        {
            enum localShare = "/usr/local/share/fonts";
            enum share = "/usr/share/fonts";
            
            string homeFonts = homeFontsPath();
            if (homeFonts.length) {
                return [homeFonts, localShare, share];
            } else {
                return [localShare, share];
            }
        }
        
        deprecated("Use xdgRuntimeDir instead") string runtimeDir() nothrow @trusted
        {
            return xdgRuntimeDir();
        }
        
        string writablePath(StandardPath type) nothrow @safe
        {
            final switch(type) {
                case StandardPath.config:
                    return xdgConfigHome();
                case StandardPath.cache:
                    return xdgCacheHome();
                case StandardPath.data:
                    return xdgDataHome();
                case StandardPath.desktop:
                    return xdgUserDir("DESKTOP", "/Desktop");
                case StandardPath.documents:
                    return xdgUserDir("DOCUMENTS");
                case StandardPath.pictures:
                    return xdgUserDir("PICTURES");
                case StandardPath.music:
                    return xdgUserDir("MUSIC");
                case StandardPath.videos:
                    return xdgUserDir("VIDEOS");
                case StandardPath.downloads:
                    return xdgUserDir("DOWNLOAD");
                case StandardPath.templates:
                    return xdgUserDir("TEMPLATES", "/Templates");
                case StandardPath.publicShare:
                    return xdgUserDir("PUBLICSHARE", "/Public");
                case StandardPath.fonts:
                    return homeFontsPath();
                case StandardPath.applications:
                    return xdgDataHome("applications");
            }
        }
        
        string[] standardPaths(StandardPath type) nothrow @safe
        {
            string[] paths;
            
            switch(type) {
                case StandardPath.data:
                    return xdgAllDataDirs();
                case StandardPath.config:
                    return xdgAllConfigDirs();
                case StandardPath.applications:
                    return xdgAllDataDirs("applications");
                case StandardPath.fonts:
                    return fontPaths();
                default:
                    break;
            }
            
            string userPath = writablePath(type);
            if (userPath.length) {
                return [userPath];
            }
            return null;
        }
    }
}

private bool isExecutable(string filePath) nothrow @trusted {
    try {
        version(Posix) {
            import core.sys.posix.unistd;
            return access(toStringz(filePath), X_OK) == 0;
        } else version(Windows) {
            //Use GetEffectiveRightsFromAclW?
            
            string extension = filePath.extension;
            const(string)[] exeExtensions = executableExtensions();
            foreach(ext; exeExtensions) {
                if (sicmp(extension, ext) == 0)
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

private string checkExecutable(string filePath) nothrow @trusted {
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
 * System paths where executable files can be found.
 * Returns: Range of paths as determined by $(B PATH) environment variable.
 * Note: this function does not cache its result
 */
@trusted auto binPaths() nothrow
{
    string pathVar;
    collectException(environment.get("PATH"), pathVar);
    return splitter(pathVar, pathVarSeparator);
}

/**
 * Finds executable by $(B fileName) in the paths specified by $(B paths).
 * Returns: Absolute path to the existing executable file or an empty string if not found.
 * Params:
 *  fileName = Name of executable to search. If it's absolute path, this function only checks if the file is executable.
 *  paths = Range of directories where executable should be searched.
 * Note: On Windows when fileName extension is omitted, executable extensions will be automatically appended during search.
 */
@trusted nothrow string findExecutable(Range)(string fileName, Range paths) if (isInputRange!Range && is(ElementType!Range : string))
{   
    try {
        if (fileName.isAbsolute()) {
            return checkExecutable(fileName);
        } else if (fileName == fileName.baseName) {
            string toReturn;
            foreach(string path; paths) {
                if (path.empty) {
                    continue;
                }
                
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
        }
    } catch (Exception e) {
        
    }
    return null;
}

/**
 * ditto, but searches in system paths, determined by $(B PATH) environment variable.
 * See_Also: binPaths
 */
@safe string findExecutable(string fileName) nothrow {    
    return findExecutable(fileName, binPaths());
}
