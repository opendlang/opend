/**
  Some helper functions for ranges
*/
module ggplotd.range;

version(unittest) {
    import dunit.toolkit;
}

private struct HashSet(E) {
    // TODO switch to proper implementation (not using AA)
    bool put( E el )
    {
        if ( el in set )
            return false;
        set[el] = set.length;
        return true;
    }
    size_t[E] set;
}

/**
  Lazily iterate over range and returning only uniques
  */
auto uniquer(R)(R range)
{
    struct Unique(Range)
    {
        import std.range : ElementType;

        Range range;
        HashSet!(ElementType!Range) set;

        this( Range _range )
        {
            import std.range : front;
            range = _range;
            this.popFront;
        }

        @property auto front()
        {
            import std.range : front;
            return range.front;
        }

        void popFront()
        {
            import std.range : front, popFront, empty;
            while( !range.empty )
            {
                // TODO: Currently this causes an unnecessary "initial" check, because we now that previous value was already added. I think the only way to solve this would be to keep currentValue and possible future value around.
                if (set.put(range.front))
                {
                    currentFront = range.front;
                    break;
                }
                range.popFront;
            }
        }

        @property bool empty()
        {
            import std.range : empty;
            return range.empty;
        }

        ElementType!Range currentFront;
    }
    return Unique!R(range);
}

///
unittest
{
    import std.array : array;
    assertEqual( [1,1,1,1].uniquer.array, [1] );
    assertEqual( [1].uniquer.array, [1] );
    assertEqual( "".uniquer.array, [] );
    assertEqual( [1,2,1,3].uniquer.array, [1,2,3] );
    assertEqual( [1,2,1,3,1,2].uniquer.array, [1,2,3] );
    assertEqual( [1,2,3].uniquer.array, [1,2,3] );
    assertEqual( ["a","b","a","c","a","c"].uniquer.array, ["a","b","c"] );

    import std.typecons : tuple;
    assertEqual( [tuple(1,"a"),tuple(1,"b"),tuple(2,"b"),tuple(1,"b")]
            .uniquer.array, [tuple(1,"a"),tuple(1,"b"),tuple(2,"b")] );
}

/++
    Group an (unsorted) range by the result of the function applied to each element
+/
private import std.range : isInputRange;

auto groupBy(alias func = function(a) { return a; }, R)(R values)
    if (isInputRange!R)
{
    import std.range : front, ElementType;
    alias K = typeof(func(values.front));
    alias V = ElementType!R[];
    V[K] grouped;
    foreach(value; values) 
        grouped[func(value)] ~= value;
    return grouped;
}

///
unittest {
    import std.stdio : writeln;
    import std.algorithm : sort;
    import std.typecons : tuple;
    auto xs = [
        tuple("a", 1.0),
        tuple("b", 3.0),
        tuple("a", 2.0),
        tuple("b", 4.0)];
    auto grouped = xs.groupBy!((a) => a[0]);
    assertEqual( grouped.keys.length, 2 );
    assertEqual( grouped.keys.sort(), ["a","b"].sort() );
}
