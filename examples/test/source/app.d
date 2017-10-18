import std.stdio;
import std.getopt;

import xdgpaths;

void main(string[] args)
{
    bool shouldCreate;
    string subfolder;
    string pathType;
    string[] paths;

    getopt(args,
        "path", "Path type to request. Possible values: config, data, cache", &pathType,
        "shouldCreate", "Create directory if does not exist", &shouldCreate,
        "subfolder", "Subfolder of requested path", &subfolder
    );

    string path;
    switch(pathType) {
        case "config":
        {
            path = xdgConfigHome(subfolder, shouldCreate);
            paths = xdgConfigDirs(subfolder);
        }
        break;
        case "data":
        {
            path = xdgDataHome(subfolder, shouldCreate);
            paths = xdgDataDirs(subfolder);
        }
        break;
        case "cache":
        {
            path = xdgCacheHome(subfolder, shouldCreate);
        }
        break;
        default:
        {
            stderr.writeln("Wrong path type. Must be config, data or cache");
            return;
        }
    }

    writeln("Requested path: ", path);
    if (paths.length) {
        writefln("Other paths: %s", paths);
    }
}
