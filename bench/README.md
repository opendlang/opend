## This is performance tester for hash table ##

During set up phase two arrays of 1_000_000 random integers
(`write array` and `read array`) were created. This arrays used in subsequent tests.

Results description:

Hash table - four options:
* std - dlang AA
* i.c - this package (cachetools) implementation (using Mallocator),
* i.c+GC - this package (cachetools) implementation(using GCAllocator),
* emsi - emsi_containers hash map.

Lists:
* unr - unrolled lists

Time - time required for test. Less is better.

Memory - diff between GC.stat.used after and before test.

to run tests use: `dub run -b release --compiler ldc2`

setup: ldc2 1.11.0, OSX, MacBook Pro 2015

### Test #1: ###

1. place 'write' array into hash table
1. lookup integers from 'read array' in the table.

### Test #2 ###

Test performance on entry removal.

1. place 'write' array into hash table.
1. remove keys (list of keys for deletion formed from the 'read array') from the table.
1. lookup integers from 'write array' in the table.


### Test #3 ###

Use structure with some mix of fields instead of `int` as `value` type.
This is test for both performance and memory management.

1. for each key from 'write array' create instance of the struct, place it in table.
1. lookup integers from 'read array' in the table.

### Test #4 ###

Use structure with some mix of fields instead of `int` as `key` type.
This is test for both performance and memory management.

1. for each key from 'write array' create instance of the struct, place it in table.
1. lookup structs built from 'read array' in the table.

### Test #5 ###

Use class with some mix of fields instead of `int` as `key` type.
This is test for both performance and memory management.

1. for each key from 'write array' create instance of the class, place it in table.
1. lookup class built from 'read array' in the table.

### Test #6 ###

Count words in Shakespeare texts (5M file).


### Tests 7- ###

Test performance for internal list implementations



```

        Test inserts and lookups int[int]         
        =================================         
|std         | 278 ms, 512 μs, and 7 hnsecs    | GC memory Δ  41.67 MB|
|i.c.        | 122 ms and 344 μs               | GC memory Δ   0.00 MB|
|i.c.+GC     | 130 ms, 8 μs, and 8 hnsecs      | GC memory Δ  32.01 MB|
|emsi        | 467 ms, 10 μs, and 9 hnsecs     | GC memory Δ   0.00 MB|

                    Test scan                     
                    =========                     
|std         | 1 sec, 906 ms, 507 μs, and 2 h  | GC memory Δ  19.45 MB|
|i.c.        | 1 sec, 265 ms, 423 μs, and 6 h  | GC memory Δ   0.00 MB|
|emsi        | 2 secs, 107 ms, 383 μs, and 3   | GC memory Δ   0.00 MB|

     Test insert, remove, lookup for int[int]     
     =======================================      
|std         | 303 ms, 50 μs, and 7 hnsecs     | GC memory Δ  17.65 MB|
|i.c.        | 179 ms, 889 μs, and 1 hnsec     | GC memory Δ   0.00 MB|
|i.c.+GC     | 179 ms, 446 μs, and 3 hnsecs    | GC memory Δ  32.00 MB|
|emsi        | 542 ms, 40 μs, and 4 hnsecs     | GC memory Δ   0.00 MB|

     Test inserts and lookups for struct[int]     
     =======================================      
|std         | 309 ms, 368 μs, and 3 hnsecs    | GC memory Δ  70.61 MB|
|i.c.        | 278 ms, 765 μs, and 2 hnsecs    | GC memory Δ   0.00 MB|
|i.c.+GC     | 251 ms, 963 μs, and 4 hnsecs    | GC memory Δ 144.00 MB|
|emsi        | 820 ms, 177 μs, and 5 hnsecs    | GC memory Δ   0.00 MB|

     Test inserts and lookups for int[struct]     
     =======================================      
|std         | 319 ms and 579 μs               | GC memory Δ  70.59 MB|
|i.c.        | 338 ms, 903 μs, and 9 hnsecs    | GC memory Δ   0.00 MB|
|i.c.+GC     | 328 ms, 262 μs, and 5 hnsecs    | GC memory Δ 144.00 MB|
|emsi        | 837 ms, 391 μs, and 9 hnsecs    | GC memory Δ   0.00 MB|

     Test inserts and lookups for int[class]      
     =======================================      
|std         | 1 sec, 67 ms, 723 μs, and 8 hn  | GC memory Δ 208.44 MB|
|i.c.        | 602 ms, 308 μs, and 5 hnsecs    | GC memory Δ 186.01 MB|
|i.c.+GC     | 321 ms, 417 μs, and 9 hnsecs    | GC memory Δ 144.00 MB|
|emsi        | can't compile                   | GC memory Δ   0.00 MB|

          Test word counting int[string]          
          =============================           
|std         | 54 ms, 23 μs, and 5 hnsecs      | GC memory Δ   4.06 MB|
|i.c.        | 59 ms, 466 μs, and 9 hnsecs     | GC memory Δ   0.00 MB|
|i.c.+GC     | 59 ms, 580 μs, and 1 hnsec      | GC memory Δ   4.00 MB|
|emsi        | 158 ms, 30 μs, and 1 hnsec      | GC memory Δ   0.00 MB|
|correctness | 118 ms, 958 μs, and 3 hnsecs    | GC memory Δ   0.00 MB|

        Test double-linked list DList!int         
        =================================         
|std         | 38 ms, 658 μs, and 7 hnsecs     | GC memory Δ  30.52 MB|
|i.c.unroll  | 13 ms, 392 μs, and 6 hnsecs     | GC memory Δ   0.00 MB|
|i.c.unr+GC  | 14 ms, 189 μs, and 5 hnsecs     | GC memory Δ  10.99 MB|
|emsiunroll  | 9 ms, 289 μs, and 1 hnsec       | GC memory Δ   0.00 MB|
```