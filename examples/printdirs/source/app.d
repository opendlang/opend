import std.stdio;
import standardpaths;

int main()
{
    writeln("Home: ", homeDir());
    
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
    
    writefln("Config dirs: %-(%s, %)", standardPaths(StandardPath.Config));
    writefln("Data dirs: %-(%s, %)", standardPaths(StandardPath.Data));
    writefln("Font dirs: %-(%s, %)", standardPaths(StandardPath.Fonts));
    
    version(Windows) {
        
    } else version(OSX) {
        
    } else version(Posix) {
        writeln("Runtime: ", runtimeDir());
    }
    
    return 0;
}
