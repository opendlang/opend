import std.stdio;
import standardpaths;

int main(string[] args)
{
    if (args.length > 1) {
        string fileName = findExecutable(args[1]);
        if (fileName.length) {
            writeln(fileName);
            return 0;
        } else {
            writefln("Could not find %s", fileName);
            return -1;
        }
    } else {
        writefln("Usage: %s <name>", args[0]);
        return 0;
    }
}
