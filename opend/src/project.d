module project;

import std.algorithm : any, map;
import std.array : array;
import std.json;
import std.path : baseName;
import std.file : readText, write, exists, mkdir;

import exceptions;
import pack;
import platform;

private struct OpenDSettingsFile
{
    this(JSONValue file)
    {
        JSONValue packs = file["localPackages"];
        if(packs.type == JSONType.array)
        {
            JSONValue[] values = packs.array();
            if(values.length != 0)
            {
                if(values[0].type != JSONType.string)
                    throw new SettingsFileInvalidException("localPackages", "Expected array of strings");
                localPackages = new string[values.length];
                foreach(i; 0 .. values.length)
                    localPackages[i] = values[i].get!string();
            }
        }
    }

    JSONValue serialize()
    {
        JSONValue ret;
        if(localPackages.length != 0)
            ret["localPackages"] = localPackages;

        return ret;
    }

    string[] localPackages;
}

class OpenDProject
{
    /// Finds an OpenD project at `path`
    this(string path, Platform platform)
    {
        projectRootPath = path;
        this.platform = platform;
        if(!exists(projectRootPath ~ "/.opend"))
            mkdir(projectRootPath ~ "/.opend");
        loadSettings();
    }

    /// Project's name
    string name()
    {
        return baseName(projectRootPath);
    }

    string projectPath()
    {
        return projectRootPath;
    }

    void addLocalPacakge(string path)
    {
        if(settings.localPackages.any!(x => x == path))
            throw new LocalPackageAlreadyAddedException(path);

        settings.localPackages ~= path;
        saveSettings();
    }

    string[] getIs()
    {
        return settings.localPackages.map!(x => (new Package(x).getImportPath())).array;
    }

private:
    void loadSettings()
    {
        if(!exists(settingsFilePath))
            return;
        
        settings = OpenDSettingsFile(parseJSON(readText(settingsFilePath)));
    }

    void saveSettings()
    {
        auto json = settings.serialize();
        write(settingsFilePath, toJSON(json));
    }

    string settingsFilePath() const
    {
        return projectRootPath ~ "/.opend/settings.json";
    }

    Platform platform;
    string projectRootPath;
    OpenDSettingsFile settings;
}
