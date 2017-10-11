import std.stdio;
import std.getopt;
import standardpaths;

bool stringToType(string typeStr, out StandardPath type)
{
    switch(typeStr) {
        case "config":
            type = StandardPath.config;
            return true;
        case "cache":
            type = StandardPath.cache;
            return true;
        case "data":
            type = StandardPath.data;
            return true;
        case "desktop":
            type = StandardPath.desktop;
            return true;
        case "documents" :
            type = StandardPath.documents;
            return true;
        case "pictures":
            type = StandardPath.pictures;
            return true;
        case "music":
            type = StandardPath.music;
            return true;
        case "videos":
            type = StandardPath.videos;
            return true;
        case "downloads" :
            type = StandardPath.downloads;
            return true;
        case "templates" :
            type = StandardPath.templates;
            return true;
        case "publicShare" :
            type = StandardPath.publicShare;
            return true;
        case "applications" :
            type = StandardPath.applications;
            return true;
        case "startup" :
            type = StandardPath.startup;
            return true;
        case "roaming":
            type = StandardPath.roaming;
            return true;
        case "savedGames":
            type = StandardPath.savedGames;
            return true;
        default:
            break;
    }
    return false;
}

void main(string[] args)
{
    bool verify;
    bool create;
    string subfolder;
    getopt(args, 
           "verify", "Verify if path exists", &verify,
           "create", "Create if does not exist", &create,
           "subfolder", "Subfolder path", &subfolder
          );
    
    if (args.length < 2) {
        stderr.writeln("Path type must be specified");
        return;
    }
    
    foreach(pathType; args[1..$]) {
        StandardPath type;
        if (stringToType(pathType, type)) {
            FolderFlag flags;
            if (verify) {
                flags |= FolderFlag.verify;
            }
            if (create) {
                flags |= FolderFlag.create;
            }
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
            stderr.writeln("Unknown type: %s", pathType);
        }
    }
    
    
}
