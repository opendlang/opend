module exceptions.cmdexception;

import std.exception;

class CommandException : Exception
{
    this(string msg)
    {
        super(msg);
    }
}
