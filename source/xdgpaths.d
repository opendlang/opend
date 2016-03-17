/**
 * Getting XDG base directories.
 * Note: these functions are defined only on freedesktop systems.
 * Authors: 
 *  $(LINK2 https://github.com/MyLittleRobo, Roman Chistokhodov)
 * Copyright:
 *  Roman Chistokhodov, 2016
 * License: 
 *  $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost License 1.0).
 * See_Also:
 *  $(LINK2 https://specifications.freedesktop.org/basedir-spec/latest/index.html, XDG Base Directory Specification)
 */

module xdgpaths;

import isfreedesktop;

version(XdgPathsDocs)
{
    /**
     * Path to runtime user directory.
     * Returns: User's runtime directory determined by $(B XDG_RUNTIME_DIR) environment variable. 
     * If directory does not exist it tries to create one with appropriate permissions. On fail returns an empty string.
     */
    @trusted string xdgRuntimeDir() nothrow;
    
    /**
     * The ordered set of non-empty base paths to search for data files, in descending order of preference.
     * Params:
     *  subfolder = Subfolder which is appended to every path if not null.
     * Returns: data directories, without user's one.
     * Note: This function does not check if paths actually exist and appear to be directories.
     */
    @trusted string[] xdgDataDirs(string subfolder = null) nothrow;
    
    /**
     * The ordered set of non-empty base paths to search for data files, in descending order of preference.
     * Params:
     *  subfolder = Subfolder which is appended to every path if not null.
     * Returns: data directories, including user's one if could be evaluated.
     * Note: This function does not check if paths actually exist and appear to be directories.
     */
    @trusted string[] xdgAllDataDirs(string subfolder = null) nothrow;
    
    /**
     * The ordered set of non-empty base paths to search for configuration files, in descending order of preference.
     * Params:
     *  subfolder = Subfolder which is appended to every path if not null.
     * Returns: config directories, without user's one.
     * Note: This function does not check if paths actually exist and appear to be directories.
     */
    @trusted string[] xdgConfigDirs(string subfolder = null) nothrow;
    
    /**
     * The ordered set of non-empty base paths to search for configuration files, in descending order of preference.
     * Params:
     *  subfolder = Subfolder which is appended to every path if not null.
     * Returns: config directories, including user's one if could be evaluated.
     * Note: This function does not check if paths actually exist and appear to be directories.
     */
    @trusted string[] xdgAllConfigDirs(string subfolder = null) nothrow;
    
    /**
     * The base directory relative to which user-specific data files should be stored.
     * Returns: Path to user-specific data directory or empty string if could not be evaluated.
     * Note: This function does not check if returned path actually exists and appears to be directory.
     * If such directory does not exist, it's recommended to create it using 0700 permissions restricting any access to user data for anyone else.
     */
    @trusted string xdgDataHome(string subfolder = null) nothrow;
    
    /**
     * The base directory relative to which user-specific configuration files should be stored.
     * Returns: Path to user-specific configuration directory or empty string if could not be evaluated.
     * Note: This function does not check if returned path actually exists and appears to be directory.
     * If such directory does not exist, it's recommended to create it using 0700 permissions restricting any access to user preferences for anyone else.
     */
    @trusted string xdgConfigHome(string subfolder = null) nothrow;
    
    /**
     * The base directory relative to which user-specific non-essential files should be stored.
     * Returns: Path to user-specific cache directory or empty string if could not be evaluated.
     * Note: This function does not check if returned path actually exists and appears to be directory.
     */
    @trusted string xdgCacheHome(string subfolder = null) nothrow {
        return xdgBaseDir("XDG_CACHE_HOME", ".cache", subfolder);
    }
}

static if (isFreedesktop) 
{
    private {
        import std.algorithm : splitter, map, filter;
        import std.array;
        import std.path : buildPath;
        import std.process : environment;
        import std.exception : collectException;
    }
    
    version(unittest) {
        import std.stdio;
        import std.algorithm : joiner, equal;
        
        struct EnvGuard
        {
            this(string env) {
                envVar = env;
                envValue = environment.get(env);
            }
            
            ~this() {
                if (envValue is null) {
                    environment.remove(envVar);
                } else {
                    environment[envVar] = envValue;
                }
            }
            
            string envVar;
            string envValue;
        }
    }
    
    private string[] pathsFromEnv(string envVar, string subfolder) nothrow {
        string[] result;
        collectException(splitter(environment.get(envVar), ':').filter!(p => !p.empty).map!(p => buildPath(p, subfolder)).array, result);
        return result;
    }

    private string xdgBaseDir(string envvar, string fallback, string subfolder = null) nothrow {
        string dir;
        collectException(environment.get(envvar), dir);
        if (dir.length) {
            return buildPath(dir, subfolder);
        } else {
            string home;
            collectException(environment.get("HOME"), home);
            return home.length ? buildPath(home, fallback, subfolder) : null;
        }
    }
    
    version(unittest) {
        void testXdgBaseDir(string envVar, string fallback) {
            auto homeGuard = EnvGuard("HOME");
            auto dataHomeGuard = EnvGuard(envVar);
            
            auto newHome = "/home/myuser";
            auto newDataHome = "/home/myuser/data";
            
            environment[envVar] = newDataHome;
            assert(xdgBaseDir(envVar, fallback) == newDataHome);
            assert(xdgBaseDir(envVar, fallback, "applications") == buildPath(newDataHome, "applications"));
            
            environment.remove(envVar);
            environment["HOME"] = newHome;
            assert(xdgBaseDir(envVar, fallback) == buildPath(newHome, fallback));
            assert(xdgBaseDir(envVar, fallback, "icons") == buildPath(newHome, fallback, "icons"));
            
            environment.remove("HOME");
            assert(xdgBaseDir(envVar, fallback).empty);
            assert(xdgBaseDir(envVar, fallback, "mime").empty);
        }
    }
    
    @trusted string[] xdgDataDirs(string subfolder = null) nothrow
    {
        auto result = pathsFromEnv("XDG_DATA_DIRS", subfolder);
        if (result.length) {
            return result;
        } else {
            return [buildPath("/usr/local/share", subfolder), buildPath("/usr/share", subfolder)];
        }
    }
    
    unittest
    {
        auto dataDirsGuard = EnvGuard("XDG_DATA_DIRS");
        
        auto newDataDirs = ["/usr/local/data", "/usr/data"];
        
        environment["XDG_DATA_DIRS"] = "/usr/local/data:/usr/data";
        assert(xdgDataDirs() == newDataDirs);
        assert(equal(xdgDataDirs("applications"), newDataDirs.map!(p => buildPath(p, "applications"))));
        
        environment.remove("XDG_DATA_DIRS");
        assert(xdgDataDirs() == ["/usr/local/share", "/usr/share"]);
        assert(equal(xdgDataDirs("icons"), ["/usr/local/share", "/usr/share"].map!(p => buildPath(p, "icons"))));
    }
    
    @trusted string[] xdgAllDataDirs(string subfolder = null) nothrow
    {
        string dataHome = xdgDataHome(subfolder);
        string[] dataDirs = xdgDataDirs(subfolder);
        if (dataHome.length) {
            return dataHome ~ dataDirs;
        } else {
            return dataDirs;
        }
    }
    
    unittest
    {
        auto homeGuard = EnvGuard("HOME");
        auto dataHomeGuard = EnvGuard("XDG_DATA_HOME");
        auto dataDirsGuard = EnvGuard("XDG_DATA_DIRS");
        
        auto newDataHome = "/home/myuser/data";
        auto newDataDirs = ["/usr/local/data", "/usr/data"];
        environment["XDG_DATA_HOME"] = newDataHome;
        environment["XDG_DATA_DIRS"] = "/usr/local/data:/usr/data";
        
        assert(xdgAllDataDirs() == newDataHome ~ newDataDirs);
        
        environment.remove("XDG_DATA_HOME");
        environment.remove("HOME");
        
        assert(xdgAllDataDirs() == newDataDirs);
    }
    
    @trusted string[] xdgConfigDirs(string subfolder = null) nothrow
    {
        auto result = pathsFromEnv("XDG_CONFIG_DIRS", subfolder);
        if (result.length) {
            return result;
        } else {
            return [buildPath("/etc/xdg", subfolder)];
        }
    }
    
    unittest
    {
        auto dataConfigGuard = EnvGuard("XDG_CONFIG_DIRS");
        
        auto newConfigDirs = ["/usr/local/config", "/usr/config"];
        
        environment["XDG_CONFIG_DIRS"] = "/usr/local/config:/usr/config";
        assert(xdgConfigDirs() == newConfigDirs);
        assert(equal(xdgConfigDirs("menus"), newConfigDirs.map!(p => buildPath(p, "menus"))));
        
        environment.remove("XDG_CONFIG_DIRS");
        assert(xdgConfigDirs() == ["/etc/xdg"]);
        assert(equal(xdgConfigDirs("autostart"), ["/etc/xdg"].map!(p => buildPath(p, "autostart"))));
    }
    
    @trusted string[] xdgAllConfigDirs(string subfolder = null) nothrow
    {
        string configHome = xdgConfigHome(subfolder);
        string[] configDirs = xdgConfigDirs(subfolder);
        if (configHome.length) {
            return configHome ~ configDirs;
        } else {
            return configDirs;
        }
    }
    
    unittest
    {
        auto homeGuard = EnvGuard("HOME");
        auto configHomeGuard = EnvGuard("XDG_CONFIG_HOME");
        auto configDirsGuard = EnvGuard("XDG_CONFIG_DIRS");
        
        auto newConfigHome = "/home/myuser/data";
        environment["XDG_CONFIG_HOME"] = newConfigHome;
        auto newConfigDirs = ["/usr/local/data", "/usr/data"];
        environment["XDG_CONFIG_DIRS"] = "/usr/local/data:/usr/data";
        
        assert(xdgAllConfigDirs() == newConfigHome ~ newConfigDirs);
        
        environment.remove("XDG_CONFIG_HOME");
        environment.remove("HOME");
        
        assert(xdgAllConfigDirs() == newConfigDirs);
    }
    
    @trusted string xdgDataHome(string subfolder = null) nothrow {
        return xdgBaseDir("XDG_DATA_HOME", ".local/share", subfolder);
    }
    
    unittest
    {
        testXdgBaseDir("XDG_DATA_HOME", ".local/share");
    }
    
    @trusted string xdgConfigHome(string subfolder = null) nothrow {
        return xdgBaseDir("XDG_CONFIG_HOME", ".config", subfolder);
    }
    
    unittest
    {
        testXdgBaseDir("XDG_CONFIG_HOME", ".config");
    }
    
    @trusted string xdgCacheHome(string subfolder = null) nothrow {
        return xdgBaseDir("XDG_CACHE_HOME", ".cache", subfolder);
    }
    
    unittest
    {
        testXdgBaseDir("XDG_CACHE_HOME", ".cache");
    }
    
    
    string xdgRuntimeDir() nothrow @trusted // Do we need it on BSD systems?
    {
        import std.conv : octal;
        import std.string : toStringz;
        import std.exception : assumeUnique;
        import std.file : isDir, exists, tempDir;
        import std.stdio;
        
        static if (is(typeof({import std.string : fromStringz;}))) {
            import std.string : fromStringz;
        } else { //own fromStringz implementation for compatibility reasons
            import std.c.string : strlen;
            @system static pure inout(char)[] fromStringz(inout(char)* cString) {
                return cString ? cString[0..strlen(cString)] : null;
            }
        }
        import core.sys.posix.pwd;
        import core.sys.posix.unistd;
        import core.sys.posix.sys.stat;
        import core.sys.posix.sys.types;
        import core.stdc.errno;
        import core.stdc.string;
        
        try { //one try to rule them all and for compatibility reasons
            const uid_t uid = getuid();
            string runtime;
            collectException(environment.get("XDG_RUNTIME_DIR"), runtime);
            
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
                                debug stderr.writefln("Failed to create runtime directory %s: %s", runtime, fromStringz(strerror(errno)));
                                return null;
                            }
                        }
                    } else {
                        debug stderr.writeln("Failed to get user name to create runtime directory");
                        return null;
                    }
                } catch(Exception e) {
                    debug collectException(stderr.writefln("Error when creating runtime directory: %s", e.msg));
                    return null;
                }
            }
            stat_t statbuf;
            stat(runtime.toStringz, &statbuf);
            if (statbuf.st_uid != uid) {
                debug collectException(stderr.writeln("Wrong ownership of runtime directory %s, %d instead of %d", runtime, statbuf.st_uid, uid));
                return null;
            }
            if ((statbuf.st_mode & octal!777) != runtimeMode) {
                debug collectException(stderr.writefln("Wrong permissions on runtime directory %s, %o instead of %o", runtime, statbuf.st_mode, runtimeMode));
                return null;
            }
            
            return runtime;
        } catch (Exception e) {
            debug collectException(stderr.writeln("Error when getting runtime directory: %s", e.msg));
            return null;
        }
    }
}
