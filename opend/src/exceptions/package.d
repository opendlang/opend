module exceptions;

public import exceptions.cmdexception;

import std.conv : text;

class LocalPackageAlreadyAddedException : Exception
{
    this(string path)
    {
        super(i"Package at `$(path)` already added".text);
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
        super(i"OpenD Settings file is broken at filed $(fieldName). $(message)".text);
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
        super(i"No OpenD package is found at `$(path)`.".text);
        _path = path;
    }

    string path() const { return _path; }

private:
    string _path;
}
