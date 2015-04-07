import std.stdio;
import standardpaths;

int main()
{
    writeln("Home: ", homeDir());
    
    writeln("\nUser directories");
    writeln("Config: ", writablePath(StandardPath.Config));
    writeln("Cache: ", writablePath(StandardPath.Cache));
    writeln("Data: ", writablePath(StandardPath.Data));
    
    writeln("Desktop: ", writablePath(StandardPath.Desktop));
    writeln("Documents: ", writablePath(StandardPath.Documents));
    writeln("Pictures: ", writablePath(StandardPath.Pictures));
    writeln("Music: ", writablePath(StandardPath.Music));
    writeln("Videos: ", writablePath(StandardPath.Videos));
    writeln("Downloads: ", writablePath(StandardPath.Download));
    
    writeln("Templates: ", writablePath(StandardPath.Templates));
    writeln("Public: ", writablePath(StandardPath.PublicShare));
    
    writeln("Fonts: ", writablePath(StandardPath.Fonts));
    writeln("Applications: ", writablePath(StandardPath.Applications));
    
    version(Windows) {
        writeln("\nSpecific functions for Windows:");
        writeln("Roaming data: ", roamingPath());
    }
    
    writeln("\nSystem directories");
    writefln("Config dirs: %-(%s, %)", standardPaths(StandardPath.Config));
    writefln("Cache dirs: %-(%s, %)", standardPaths(StandardPath.Cache));
    writefln("Data dirs: %-(%s, %)", standardPaths(StandardPath.Data));
    writefln("Font dirs: %-(%s, %)", standardPaths(StandardPath.Fonts));
    writefln("Applications dirs: %-(%s, %)", standardPaths(StandardPath.Applications));
    
    version(Windows) {
        writefln("Desktop dirs: %-(%s, %)", standardPaths(StandardPath.Desktop));
        writefln("Documents dirs: %-(%s, %)", standardPaths(StandardPath.Documents));
        writefln("Pictures dirs: %-(%s, %)", standardPaths(StandardPath.Pictures));
        writefln("Music dirs: %-(%s, %)", standardPaths(StandardPath.Music));
        writefln("Videos dirs: %-(%s, %)", standardPaths(StandardPath.Videos));
        
        writefln("Templates dirs: %-(%s, %)", standardPaths(StandardPath.Templates));
    } else version(OSX) {
        
    } else version(linux) {
        writeln("\nSpecific functions for Linux:");
        writeln("Runtime: ", runtimeDir());
    }
    
    return 0;
}
