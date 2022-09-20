
//          Copyright Ferdinand Majerech 2011.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)

///Exceptions thrown by `mir-yaml` and _exception related code.
module mir.internal.yaml.exception;


import std.algorithm;
import std.array;
import std.string;
import std.conv;


/// Base class for all exceptions thrown by `mir-yaml`.
class YamlException : Exception
{
    /// Construct a YamlException with specified message and position where it was thrown.
    public this(string msg, string file = __FILE__, size_t line = __LINE__)
        @safe pure nothrow @nogc
    {
        super(msg, file, line);
    }
}

/// Position in a YAML stream, used for error messages.
public import mir.algebraic_alias.yaml: ParsePosition;


package:
// A struct storing parameters to the MarkedYamlException constructor.
struct MarkedYamlExceptionData
{
    // Context of the error.
    string context;
    // Position of the context in a YAML buffer.
    ParsePosition contextMark;
    // The error itself.
    string problem;
    // Position if the error.
    ParsePosition problemMark;
}

// Base class of YAML exceptions with marked positions of the problem.
abstract class MarkedYamlException : YamlException
{
    // Construct a MarkedYamlException with specified context and problem.
    this(string context, const ParsePosition contextMark, string problem, const ParsePosition problemMark,
         string file = __FILE__, size_t line = __LINE__) @safe pure nothrow
    {
        import mir.format: text;
        const msg = context ~ '\n' ~
                    (contextMark != problemMark ? contextMark.text ~ '\n' : "") ~
                    problem ~ '\n' ~ problemMark.text ~ '\n';
        super(msg, file, line);
    }

    // Construct a MarkedYamlException with specified problem.
    this(string problem, const ParsePosition problemMark,
         string file = __FILE__, size_t line = __LINE__)
        @safe pure nothrow
    {
        import mir.format: text;
        super(problem ~ '\n' ~ problemMark.text, file, line);
    }

    /// Construct a MarkedYamlException from a struct storing constructor parameters.
    this(ref const(MarkedYamlExceptionData) data) @safe pure nothrow
    {
        with(data) this(context, contextMark, problem, problemMark);
    }
}

// Constructors of YAML exceptions are mostly the same, so we use a mixin.
//
// See_Also: YamlException
template ExceptionCtors()
{
    public this(string msg, string file = __FILE__, size_t line = __LINE__)
        @safe pure nothrow
    {
        super(msg, file, line);
    }
}

// Constructors of marked YAML exceptions are mostly the same, so we use a mixin.
//
// See_Also: MarkedYamlException
template MarkedExceptionCtors()
{
    public:
        this(string context, const ParsePosition contextMark, string problem,
             const ParsePosition problemMark, string file = __FILE__, size_t line = __LINE__)
            @safe pure nothrow
        {
            super(context, contextMark, problem, problemMark,
                  file, line);
        }

        this(string problem, const ParsePosition problemMark,
             string file = __FILE__, size_t line = __LINE__)
            @safe pure nothrow
        {
            super(problem, problemMark, file, line);
        }

        this(ref const(MarkedYamlExceptionData) data) @safe pure nothrow
        {
            super(data);
        }
}
