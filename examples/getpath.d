/+dub.sdl:
name "printdirs"
dependency "standardpaths" path="../"
+/

import std.stdio;
import std.getopt;
import standardpaths;

void main(string[] args)
{
    import std.conv : to;
    import std.range : iota;
    StandardPath[string] stringToType;
    foreach(StandardPath i; StandardPath.min..StandardPath.max) {
        stringToType[to!string(i)] = i;
    }
    bool verify;
    bool create;
    string subfolder;
    auto helpInformation = getopt(args,
           "verify", "Verify if path exists", &verify,
           "create", "Create if does not exist", &create,
           "subfolder", "Subfolder path", &subfolder
          );

    if (helpInformation.helpWanted)
    {
        defaultGetoptPrinter("Usage: getpath [options...] <pathType>", helpInformation.options);
        return;
    }

    if (args.length < 2) {
        stderr.writeln("Path type must be specified");
        return;
    }

    FolderFlag flags;
    if (verify) {
        flags |= FolderFlag.verify;
    }
    if (create) {
        flags |= FolderFlag.create;
    }
    foreach(pathType; args[1..$]) {
        StandardPath* typePtr = pathType in stringToType;
        if (typePtr) {
            StandardPath type = *typePtr;
            string path;
            if (subfolder.length) {
                path = writablePath(type, subfolder, flags);
            } else {
                path = writablePath(type, flags);
            }

            if (path.length) {
                writefln("%s: %s", pathType, path);
            } else {
                if (create) {
                    stderr.writefln("%s: could not create path", pathType);
                } else if (verify) {
                    writefln("%s: path does not exist", pathType);
                } else {
                    writefln("%s: could not determine path", pathType);
                }
            }
        } else {
            stderr.writefln("Unknown type: %s", pathType);
            writefln("Available types: %s", iota(StandardPath.min, StandardPath.max));
        }
    }
}
