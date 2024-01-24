module platform;

import std.process;
import std.path;

abstract class Platform
{
    abstract string tmpPath();

    static Platform create()
    {
        version(Windows)
        {
            import platform.windows : WindowsPlatform;
            return new WindowsPlatform();
        }
        version(linux)
        {
            // Stub
        }
    }

    string buildFile(string file)
    {
        immutable exeName = getExeFileNameForFile(file);
        immutable dstFile = tmpPath ~ getExeFileNameForFile(file);
        auto pid = spawnProcess([compilerPath, file, "-of=" ~ dstFile]);
        int res = wait(pid);
        if(res != 0)
            throw new Exception("DMD Exited with non-zero");

        return dstFile;
    }

    void compilerPath(string path) { _compilerPath = path; }
    string compilerPath() { return _compilerPath; }
protected:
    abstract string getExeFileNameForFile(string file);

private:

    string _compilerPath;
}
