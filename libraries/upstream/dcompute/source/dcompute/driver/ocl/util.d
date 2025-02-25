module dcompute.driver.ocl.util;

import std.range;
import std.meta;
import std.traits;

//deal with arrays seperately, in part to avoid any
//narrow-string idiocy
@property auto memSize(R)(R r)
if (is(R : T[], T))
{
    static if (is(R : T[], T))
        return r.length * T.sizeof;
    else
        static assert(false);
}

@property auto memSize(R)(R r)
if(isInputRange!R && hasLength!R && !is(R : T[], T))
{
    return r.length * (ElementType!R).sizeof;
}

T[Args.length + 1] propertyList(T,Args...)(Args args)
{
    T[Args.length + 1] props;
    foreach(i, arg; args)
        props[i] = *cast(T*)(&arg);
    props[$-1] = cast(T)0;
    return props;
}

struct ArrayAccesssor(alias ptr, alias len) {}

struct StringzAccessor(alias ptr) {}

struct ZeroTerminatedArrayAccessor(alias ptr) {}

struct ArrayAccesssor2D(alias ptr, alias lens, alias len) {}

// Returned by ArrayAccesssor2D
struct RangeOfArray(T)
{
    T**     ptr;
    size_t* lengths;
    size_t  length;
    size_t  index;

    bool empty()
    {
        return index == length;
    }

    @property T[] front()
    {
        return ptr[index][0 .. lengths[index]];
    }

    T[] opIndex(size_t i)
    {
        return ptr[i][0 .. lengths[i]];
    }
    void popFront()
    {
        ++index;
    }
    
    @property size_t opDollar() { return length; }
}

string generateGetInfo(Info,alias func,string args = "raw")()
{
    import std.string;
    return helper!(Info.tupleof).format(func.stringof,args);
}

// A substitute for fullyQualifiedName to speed up compile time
private template isModule(alias a) {
    static if (is(a) || is(typeof(a)) || a.stringof.length < 7) {
        enum isModule = false;
    } else {
        enum isModule = a.stringof[0..7] == "module ";
    }
}

private template partiallyQualifiedName(alias a) {
    static if (isModule!a) {
        enum partiallyQualifiedName = "";
    } else {
        static if (!isModule!(__traits(parent, a))) {
            enum prefix = partiallyQualifiedName!(__traits(parent, a)) ~ ".";
        } else {
            enum prefix = "";
        }
        enum partiallyQualifiedName = prefix ~ __traits(identifier, a);
    }
}

private template helper(Fields...)
{
    static if (Fields.length == 0)
        enum helper = "";

    else static if (is(typeof(Fields[0]) : ArrayAccesssor!(ptr,len),alias ptr,alias len))
    {
        enum helper = "@property " ~ typeof(*ptr).stringof ~ "[] " ~ Fields[0].stringof ~ "()\n" ~
            "{\n" ~
            "    return " ~ ptr.stringof ~ "[0 .. " ~ len.stringof ~"];"~
            "}\n" ~ helper!(Fields[1 .. $]);
    }
    else static if (is(typeof(Fields[0]) : StringzAccessor!ptr,alias ptr))
    {
        enum helper = "@property char[] " ~ Fields[0].stringof ~ "()\n" ~
            "{\n" ~
            "    import std.typecons; char[] ret;" ~
            "    size_t len;" ~
            "    %1$s(%2$s," ~ __traits(getAttributes, ptr).stringof ~ "[0], 0, null, &len);" ~
            "    ret.length = len;" ~
            "    %1$s(%2$s," ~ __traits(getAttributes, ptr).stringof ~ "[0], memSize(ret), ret.ptr, null);" ~
            "    return ret;" ~
            "}\n" ~ helper!(Fields[1 .. $]);
    }
    else static if (is(typeof(Fields[0]) : ArrayAccesssor2D!(ptr,lens,len) , alias ptr, alias lens, alias len))
    {
        enum helper = "@property RangeOfArray!(" ~ typeof(**ptr).stringof ~ ") " ~ Fields[0].stringof ~ "()\n" ~
            "{\n" ~
            "   import std.typecons; size_t length; size_t* lengths; " ~ typeof(ptr).stringof ~ " ptr;" ~
            "   %1$s(%2$s," ~ __traits(getAttributes, len).stringof ~ "[0],length.sizeof, &length,null);" ~
            "   lengths = (new size_t[length]).ptr; ptr = (new " ~ typeof(*ptr).stringof ~ "[length]).ptr;" ~
            "   %1$s(%2$s," ~ __traits(getAttributes, lens).stringof ~ "[0],lengths.sizeof, lengths,null);" ~
            "   if (lengths[length - 1] == 0) length--;" ~
            "   foreach(i; 0 .. length) \n{" ~
            "       ptr[i] = (new " ~ typeof(**ptr).stringof ~ "[lengths[i]]).ptr;" ~
            "   }\n" ~
            "   %1$s(%2$s," ~ __traits(getAttributes, ptr).stringof ~ "[0], ptr.sizeof, ptr, null);" ~
            "   return typeof(return)(ptr,lengths,length,0);" ~
            "}\n" ~ helper!(Fields[1 .. $]);
    }
    else
    {
        static if (is(typeof(Fields[0]) == enum))
        {
            enum helper = "@property " ~ partiallyQualifiedName!(typeof(Fields[0])) ~ " " ~ Fields[0].stringof ~ "()\n" ~
                "{\n" ~
                "    import std.typecons; typeof(return) ret;" ~
                "%1$s(%2$s,"~ __traits(getAttributes, Fields[0]).stringof ~ "[0], ret.sizeof, &ret, null);" ~
                "return ret; " ~ 
                "}\n" ~ helper!(Fields[1 .. $]);
    
        }
        else 
        {
            enum helper = "@property " ~ typeof(Fields[0]).stringof ~ " " ~ Fields[0].stringof ~ "()\n" ~
                "{\n" ~
                "    import std.typecons; typeof(return) ret;" ~
                "%1$s(%2$s,"~ __traits(getAttributes, Fields[0]).stringof ~ "[0], ret.sizeof, &ret, null);" ~
                "return ret; " ~ 
                "}\n" ~ helper!(Fields[1 .. $]);
        }
    }
}
