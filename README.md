![](https://github.com/ikod/ikod-containers/workflows/CI/badge.svg)
# ikod-containers

You can find generated docs for containers on [githubio](https://ikod.github.io/ikod-containers/ikod.containers.html) or on [dpldocs](https://ikod-containers.dpldocs.info/ikod.containers.html).


## HashMap ##

Differences from D associated arrays:
1. HashMap itself is a struct and a value (not a reference), so any assignment `map2 = map1` will copy all the data from `map1` to `map2`.
1. HashMap has a deprecated "in" operator. Since a pointer to the value in a table is highly unsafe (as the location of the stored value can change upon mutation), use [`fetch`]() to test the key existence and fetch its value in a single API call intead of `in`.
1. Any method from `get` family returns a value stored in a table, and never - a pointer. It is safe.

Advantages:
1. Faster speed, as it does not allocate on every insert and has optimized storage layout.
1. It inherits `@nogc` and `@safe` properties from key and value types, so it can be used in `@safe` and `@nogc` code. Note: `opIndex` can throw exception so it's not `@nogc` in any case (use `fetch` or `get` with default value if you need `@nogc`)
1. Provides a stable iteration over the container (you can modify/delete table items while iterating over it).

You cah find HashMap API docs [here](https://ikod-containers.dpldocs.info/ikod.containers.hashmap.HashMap.html)
### code sample ###

```d
import std.range;
import std.algorithm;
import ikod.containers.hashmap;

static string[] words =
[
        "hello", "this", "simple", "example", "should", "succeed", "or", "it",
        "should", "fail"
];

void main() @safe @nogc
{
    HashMap!(string, int) counter;
    // count words, simplest and fastest way
    foreach (word; words) {
        counter[word] = counter.getOrAdd(word, 0) + 1; // getOrAdd() return the value from the table or add it to the table
    }
    assert(counter.fetch("hello").ok);          // fetch() is a replacement to "in": you get "ok" if the key exists in the table
    assert(counter.fetch("hello").value == 1);  // and the value itself
    debug assert(counter["hello"] == 1);        // opIndex is not @nogc
    debug assert(counter["should"] == 2);       // opIndex is not @nogc
    assert(counter.contains("hello"));          // checks the key existence
    assert(counter.length == words.length - 1); // because "should" counts only once
    // iterators
    assert(counter.byKey.count == counter.byValue.count);
    assert(words.all!(w => counter.contains(w))); // all words in table
    assert(counter.byValue.sum == words.length); // sum of counters must equal to the number of words
}
```

## UnrolledList ##

From Wikipedia, the free encyclopedia [[*](https://en.wikipedia.org/wiki/Unrolled_linked_list)]

> In computer programming, an unrolled linked list is a variation on the linked list which stores multiple elements in each node. It can dramatically increase cache performance, while decreasing the memory overhead associated with storing list metadata such as references. It is related to the B-tree.

Advantages:
* Fast, cache-friendly.
* @nogc, @safe.
* Sane iterators (unstable and stable iterators are supported).

See docs [here](https://ikod.github.io/ikod-containers/ikod.containers.unrolledlist.UnrolledList.html)

### code sample ###
```d
import std.algorithm: equal;
import std.range: iota;

import ikod.containers.unrolledlist: UnrolledList;

void main() @safe @nogc
{
    UnrolledList!int l;
    // add items
    foreach(i; 2..50)
    {
        l.pushBack(i); // push back
    }
    l.pushFront(0); // push front
    l.insert(1,1);  // insert value at arbitrary position
    // get items
    assert(l.front == 0);
    assert(l.back == 49);
    auto v = l.get(25); // get value at some position. Same as l[25] but @nogc
    assert(v.ok);
    assert(v.value == 25);
    // iterators/ranges
    auto r = l.unstableRange();
    assert(equal(r, iota(50)));
}
```
