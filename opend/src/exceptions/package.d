module exceptions;

public import exceptions.cmdexception;

import std.conv : text;

class LocalPackageAlreadyAddedException : Exception
{
    this(string path)
    {
        super(text("Package at `", path, "` already added"));
        _path = path;
    }

    string path() const
    {
        return _path;
    }

private:
    string _path;
}

class SettingsFileInvalidException : Exception
{
    this(string fieldName, string message)
    {
        super(text("OpenD Settings file is broken at filed ", fieldName," . ", message));
        _fieldName = fieldName;
    }

    string fieldName() const { return _fieldName; }

private:
    string _fieldName;
}

class NotAnOpenDPackageException : Exception
{
    this(string path)
    {
        super(text("No OpenD package is found at `", path, "`."));
        _path = path;
    }

    string path() const { return _path; }

private:
    string _path;
}
