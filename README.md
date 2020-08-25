![](https://github.com/ikod/ikod-containers/workflows/CI/badge.svg)
# ikod-containers

## HashMap ##

Main differences from language AA:
1. HashMap itself is value(not reference), so any `assign` from one map to another copy all data. If you need performance - use reference or pointer.
1. HashMap have no "in" operator.
1. Any `get` get method returns value stored in table, and never - pointer. This is safe. AA can return pointer as it allocates on each insertion.

Main advantages:
1. It is fast, as it do not allocate on every insert and has optimized storage layout.
1. It inherit @nogc and @safe properties from key and value types (but opIndex can throw exception so it is not @nogc in any case - use fetch or get with default value)
1. Provide stable iteration over container (you can modify/delete items from table while iterating over it)

### code sample ###

```d
import std.range;
import std.algorithm;
import ikod.containers.hashmap;

void main()
{
    HashMap!(string, int) counter;
    string[] words = [
        "hello", "this", "simple", "example", "should", "succeed", "or", "it",
        "should", "fail"
    ];
    // count words, simplest and fastest way
    foreach (word; words) {
        counter[word] = counter.getOrAdd(word, 0) + 1; // getOrAdd() return value from table or add it to table
    }
    assert(counter.fetch("hello").ok);          // fetch() is replacement to "in": you get "ok" if key in table
    assert(counter.fetch("hello").value == 1);  // and value itself 
    assert(counter["hello"] == 1);
    assert(counter["should"] == 2);
    assert(counter.contains("hello"));          // contains check presence
    assert(counter.length == words.length - 1); // because "should" counts only once
    // iterators
    assert(counter.byKey.count == counter.byValue.count);
    assert(words.all!(w => counter.contains(w))); // all words in table
    assert(counter.byValue.sum == words.length); // sum of counters must equals to number of words
}
```