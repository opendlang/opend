## This is performance tester for hash table ##

During set up phase two arrays of 1_000_000 random integers
(`write array` and `read array`) were created. This arrays used in subsequent tests.

Results description:

Hash table - four options:
* std - dlang AA
* i.c - ikod.containers (using Mallocator),
* i.c+GC - ikod.containers (using GCAllocator),
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
|std         | 273 ms, 127 μs, and 4 hnsecs    | GC memory Δ  41.65 MB|
|i.c.        | 120 ms, 649 μs, and 5 hnsecs    | GC memory Δ   0.00 MB|
|i.c.+GC     | 127 ms, 88 μs, and 7 hnsecs     | GC memory Δ  32.00 MB|
|emsi        | 466 ms, 349 μs, and 5 hnsecs    | GC memory Δ   0.00 MB|

                    Test scan                     
                    =========                     
|std         | 1 sec, 988 ms, 987 μs, and 5 h  | GC memory Δ  19.25 MB|
|i.c.        | 1 sec, 324 ms, 710 μs, and 7 h  | GC memory Δ   0.00 MB|
|emsi        | 2 secs, 75 ms, 34 μs, and 2 hn  | GC memory Δ   0.00 MB|

     Test insert, remove, lookup for int[int]     
     =======================================      
|std         | 298 ms, 355 μs, and 4 hnsecs    | GC memory Δ  17.65 MB|
|i.c.        | 172 ms, 756 μs, and 1 hnsec     | GC memory Δ   0.00 MB|
|i.c.+GC     | 173 ms, 123 μs, and 6 hnsecs    | GC memory Δ  32.00 MB|
|emsi        | 522 ms and 677 μs               | GC memory Δ   0.00 MB|

     Test inserts and lookups for struct[int]     
     =======================================      
|std         | 307 ms, 55 μs, and 7 hnsecs     | GC memory Δ  70.58 MB|
|i.c.        | 259 ms, 863 μs, and 4 hnsecs    | GC memory Δ   0.00 MB|
|i.c.+GC     | 255 ms, 498 μs, and 3 hnsecs    | GC memory Δ 144.00 MB|
|emsi        | 812 ms, 205 μs, and 8 hnsecs    | GC memory Δ   0.00 MB|

     Test inserts and lookups for int[struct]     
     =======================================      
|std         | 307 ms, 155 μs, and 9 hnsecs    | GC memory Δ  70.58 MB|
|i.c.        | 328 ms and 431 μs               | GC memory Δ   0.00 MB|
|i.c.+GC     | 322 ms, 474 μs, and 2 hnsecs    | GC memory Δ 144.00 MB|
|emsi        | 864 ms, 321 μs, and 5 hnsecs    | GC memory Δ   0.00 MB|

     Test inserts and lookups for int[class]      
     =======================================      
|std         | 1 sec, 200 ms, 867 μs, and 6 h  | GC memory Δ 177.32 MB|
|i.c.        | 599 ms, 255 μs, and 7 hnsecs    | GC memory Δ 186.01 MB|
|i.c.+GC     | 315 ms, 448 μs, and 6 hnsecs    | GC memory Δ 144.00 MB|
|emsi        | can't compile                   | GC memory Δ   0.00 MB|

          Test word counting int[string]          
          =============================           
|std         | 56 ms, 747 μs, and 6 hnsecs     | GC memory Δ   4.06 MB|
|i.c.        | 63 ms, 747 μs, and 4 hnsecs     | GC memory Δ   0.00 MB|
|i.c.+GC     | 67 ms, 168 μs, and 1 hnsec      | GC memory Δ   4.00 MB|
|emsi        | 146 ms, 172 μs, and 5 hnsecs    | GC memory Δ   0.00 MB|
|correctness | 111 ms, 801 μs, and 7 hnsecs    | GC memory Δ   0.00 MB|

        Test double-linked list DList!int         
        =================================         
|std         | 38 ms, 909 μs, and 9 hnsecs     | GC memory Δ  30.52 MB|
|i.c.unroll  | 8 ms, 23 μs, and 6 hnsecs       | GC memory Δ   0.00 MB|
|i.c.unr+GC  | 7 ms, 983 μs, and 5 hnsecs      | GC memory Δ   4.78 MB|
|emsiunroll  | 10 ms, 616 μs, and 8 hnsecs     | GC memory Δ   0.00 MB|

               Test list iterators                
        =================================         
|i.c.compr   | 5 ms, 423 μs, and 3 hnsecs      | GC memory Δ   0.00 MB|
|i.c.unroll  | 4 ms, 139 μs, and 9 hnsecs      | GC memory Δ   0.00 MB|

        Test double-linked list of int's
        ==================================
|std         | 40 ms, 763 μs, and 5 hnsecs     | GC memory Δ  30.52 MB|
|i.c.        | 7 ms, 957 μs, and 3 hnsecs      | GC memory Δ   0.00 MB|
|i.c.+GC     | 8 ms, 794 μs, and 9 hnsecs      | GC memory Δ   4.72 MB|

        Test double-linked list of structs        
        ==================================        
|std         | 81 ms, 862 μs, and 7 hnsecs     | GC memory Δ  89.14 MB|
|i.c.        | 19 ms, 762 μs, and 7 hnsecs     | GC memory Δ   0.00 MB|
|i.c.+GC     | 25 ms, 34 μs, and 2 hnsecs      | GC memory Δ  54.90 MB|

```