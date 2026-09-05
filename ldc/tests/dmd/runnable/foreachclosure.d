// REQUIRED_ARGS: -preview=dip1000

import std.algorithm.iteration : splitter;
import std.conv : to;
import std.path : chainPath;
import std.typecons : Tuple, tuple;

alias Getter = int delegate();

void check(Getter[] getters, int[] expected)
{
    assert(getters.length == expected.length);
    foreach (i, getter; getters)
        assert(getter() == expected[i]);
}

struct Range
{
    int value;
    @property bool empty() const { return value == 4; }
    @property int front() const { return value; }
    void popFront() { ++value; }
}

struct Apply
{
    int opApply(scope int delegate(int) dg)
    {
        foreach (i; 0 .. 4)
            if (auto result = dg(i))
                return result;
        return 0;
    }
}

struct PairRange
{
    int value;
    @property bool empty() const { return value == 3; }
    @property Tuple!(int, int) front() { return tuple(value, value + 10); }
    void popFront() { ++value; }
}

struct Noncopyable
{
    @disable this(this);
}

struct AliasTuple(T...)
{
    T fields;
    alias fields this;
}

class NoncopyablePairRange
{
    AliasTuple!(int, Noncopyable[2]) pair;
    int value;

    @property bool empty() const { return value == 2; }
    @property ref typeof(pair) front() return
    {
        pair.fields[0] = value;
        return pair;
    }
    void popFront() { ++value; }
}

mixin template CaptureLoopVariable()
{
    auto getter = () => i;
}

int ctfeSwitchGoto()
{
    switch (0)
    {
    case 0:
        foreach (i; 0 .. 2)
        {
            auto getter = () => i;
            if (getter() == 1)
                goto default;
        }
        assert(0);
    default:
        return 1;
    }
}

static assert(ctfeSwitchGoto() == 1);

void testSwitchGotos()
{
    int reached;
    switch (0)
    {
    case 0:
        foreach (i; 0 .. 2)
        {
            auto getter = () => i;
            if (getter() == 1)
                goto default;
        }
        assert(0);
    default:
        reached = 1;
        break;
    }
    assert(reached == 1);

    switch (0)
    {
    case 0:
        foreach (i; 0 .. 2)
        {
            enum target = 2;
            auto getter = () => i;
            if (getter() == 1)
                goto case target;
        }
        assert(0);
    case 1:
        assert(0);
    case 2:
        reached = 2;
        break;
    default:
        assert(0);
    }
    assert(reached == 2);

    switch (0)
    {
    case 0:
        foreach (i; 0 .. 2)
        {
            auto getter = () => i;
            if (getter() == 1)
                goto case;
        }
        assert(0);
    case 1:
        reached = 3;
        break;
    default:
        assert(0);
    }
    assert(reached == 3);

    switch (0)
    {
    case 0:
        foreach (i; 0 .. 2)
        {
            auto outerGetter = () => i;
            foreach (j; 0 .. 2)
            {
                auto innerGetter = () => j;
                if (outerGetter() == 1 && innerGetter() == 1)
                    goto default;
            }
        }
        assert(0);
    default:
        reached = 4;
        break;
    }
    assert(reached == 4);
}

int returnFromBody(ref Getter[] getters)
{
    foreach (i; 0 .. 4)
    {
        getters ~= () => i;
        if (i == 2)
            return i;
    }
    return -1;
}

int immediateClosures() @safe pure nothrow @nogc
{
    int result;
    foreach (i; 0 .. 4)
        result += (() @safe pure nothrow @nogc => i)();
    return result;
}

static assert(immediateClosures() == 6);

string lifetimeSensitive(scope string path) @safe
{
    string result;
    foreach (part; splitter(path, ":"))
    {
        auto length = () @safe => part.length;
        result = chainPath(part, "child").to!string;
        assert(length() == part.length);
    }
    return result;
}

void main()
{
    assert(lifetimeSensitive("first:second").length);

    Getter[] getters;
    foreach (i; 0 .. 4)
        getters ~= () => i;
    check(getters, [0, 1, 2, 3]);

    getters = null;
    foreach_reverse (i; 0 .. 4)
        getters ~= () => i;
    check(getters, [3, 2, 1, 0]);

    getters = null;
    int[] values = [10, 20, 30, 40];
    foreach (i, value; values)
        getters ~= () => cast(int) i * 100 + value;
    check(getters, [10, 120, 230, 340]);

    getters = null;
    foreach (value; Range())
        getters ~= () => value;
    check(getters, [0, 1, 2, 3]);

    getters = null;
    foreach (left, right; PairRange())
        getters ~= () => left * 100 + right;
    check(getters, [10, 111, 212]);

    getters = null;
    foreach (number, item; new NoncopyablePairRange())
        getters ~= () => number;
    check(getters, [0, 1]);

    getters = null;
    foreach (i; 0 .. 4)
        getters ~= mixin("() => i");
    check(getters, [0, 1, 2, 3]);

    getters = null;
    foreach (i; 0 .. 4)
    {
        mixin CaptureLoopVariable;
        getters ~= getter;
    }
    check(getters, [0, 1, 2, 3]);

    getters = null;
    foreach (value; Apply())
        getters ~= () => value;
    check(getters, [0, 1, 2, 3]);

    getters = null;
    for (int i; i < 4; ++i)
        getters ~= () => i;
    check(getters, [4, 4, 4, 4]);

    testSwitchGotos();

    getters = null;
    int outer;
    foreach (i; 0 .. 4)
    {
        int local = i * 2;
        getters ~= () => outer + i + local;
    }
    outer = 100;
    check(getters, [100, 103, 106, 109]);

    getters = null;
    foreach (i; 0 .. 6)
    {
        if (i == 1)
            continue;
        getters ~= () => i;
        if (i == 3)
            break;
    }
    check(getters, [0, 2, 3]);

    getters = null;
    assert(returnFromBody(getters) == 2);
    check(getters, [0, 1, 2]);

    getters = null;
    foreach (i; 0 .. 4)
    {
        getters ~= () => i;
        if (i == 2)
            goto done;
    }
    assert(0);
done:
    check(getters, [0, 1, 2]);

    getters = null;
outer:
    foreach (i; 0 .. 4)
    {
        getters ~= () => i * 10;
        foreach (j; 0 .. 4)
        {
            getters ~= () => i * 10 + j;
            if (i == 1 && j == 1)
                break outer;
        }
    }
    check(getters, [0, 0, 1, 2, 3, 10, 10, 11]);

    int[] referenced = [1, 2, 3, 4];
    getters = null;
    foreach (ref value; referenced)
        getters ~= () => value;
    referenced[] += 10;
    check(getters, [11, 12, 13, 14]);
}
