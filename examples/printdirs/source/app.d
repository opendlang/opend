import std.stdio;
import standardpaths;

int main()
{
    writeln("Home: ", homeDir());
    
    writeln("\nUser directories");
    writeln("Config: ", writablePath(StandardPath.config));
    writeln("Cache: ", writablePath(StandardPath.cache));
    writeln("Data: ", writablePath(StandardPath.data));
    
    writeln("Desktop: ", writablePath(StandardPath.desktop));
    writeln("Documents: ", writablePath(StandardPath.documents));
    writeln("Pictures: ", writablePath(StandardPath.pictures));
    writeln("Music: ", writablePath(StandardPath.music));
    writeln("Videos: ", writablePath(StandardPath.videos));
    writeln("Downloads: ", writablePath(StandardPath.downloads));
    
    writeln("Templates: ", writablePath(StandardPath.templates));
    writeln("Public: ", writablePath(StandardPath.publicShare));
    
    writeln("Fonts: ", writablePath(StandardPath.fonts));
    writeln("Applications: ", writablePath(StandardPath.applications));
    writeln("Startup: ", writablePath(StandardPath.startup));
    
    version(Windows) {
        writeln("\nSpecific functions for Windows:");
        writeln("Roaming data: ", writablePath(StandardPath.roaming));
        writeln("Saved games: ", writablePath(StandardPath.savedGames));
    } else version(linux) {
        writeln("\nSpecific functions for Linux:");
        writeln("Runtime: ", xdgRuntimeDir());
    }
    
    writeln("\nSystem directories");
    writefln("Config dirs: %-(%s, %)", standardPaths(StandardPath.config));
    writefln("Cache dirs: %-(%s, %)", standardPaths(StandardPath.cache));
    writefln("Data dirs: %-(%s, %)", standardPaths(StandardPath.data));
    writefln("Font dirs: %-(%s, %)", standardPaths(StandardPath.fonts));
    writefln("Applications dirs: %-(%s, %)", standardPaths(StandardPath.applications));
    writefln("Startup dirs: %-(%s, %)", standardPaths(StandardPath.startup));
    
    version(Windows) {
        writefln("Desktop dirs: %-(%s, %)", standardPaths(StandardPath.desktop));
        writefln("Documents dirs: %-(%s, %)", standardPaths(StandardPath.documents));
        writefln("Downloads dirs: %-(%s, %)", standardPaths(StandardPath.downloads));
        writefln("Pictures dirs: %-(%s, %)", standardPaths(StandardPath.pictures));
        writefln("Music dirs: %-(%s, %)", standardPaths(StandardPath.music));
        writefln("Videos dirs: %-(%s, %)", standardPaths(StandardPath.videos));
        
        writefln("Templates dirs: %-(%s, %)", standardPaths(StandardPath.templates));
    }
    
    return 0;
}
