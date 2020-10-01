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
|std         | 269 ms, 203 μs, and 9 hnsecs    | GC memory Δ  41.67 MB|
|i.c.        | 114 ms, 293 μs, and 6 hnsecs    | GC memory Δ   0.00 MB|
|i.c.+GC     | 121 ms, 307 μs, and 5 hnsecs    | GC memory Δ  32.01 MB|
|emsi        | 430 ms, 282 μs, and 4 hnsecs    | GC memory Δ   0.00 MB|

                    Test scan                     
                    =========                     
|std         | 1 sec, 807 ms, 698 μs, and 2 h  | GC memory Δ  19.45 MB|
|i.c.        | 1 sec, 237 ms, 596 μs, and 5 h  | GC memory Δ   0.00 MB|
|emsi        | 2 secs, 262 ms, 60 μs, and 9 h  | GC memory Δ   0.00 MB|

     Test insert, remove, lookup for int[int]     
     =======================================      
|std         | 312 ms and 651 μs               | GC memory Δ  17.65 MB|
|i.c.        | 178 ms, 508 μs, and 3 hnsecs    | GC memory Δ   0.00 MB|
|i.c.+GC     | 189 ms, 777 μs, and 1 hnsec     | GC memory Δ  32.00 MB|
|emsi        | 534 ms, 811 μs, and 3 hnsecs    | GC memory Δ   0.00 MB|

     Test inserts and lookups for struct[int]     
     =======================================      
|std         | 315 ms, 114 μs, and 7 hnsecs    | GC memory Δ  70.61 MB|
|i.c.        | 274 ms, 415 μs, and 5 hnsecs    | GC memory Δ   0.00 MB|
|i.c.+GC     | 258 ms, 321 μs, and 4 hnsecs    | GC memory Δ 144.00 MB|
|emsi        | 824 ms, 766 μs, and 6 hnsecs    | GC memory Δ   0.00 MB|

     Test inserts and lookups for int[struct]     
     =======================================      
|std         | 330 ms, 7 μs, and 8 hnsecs      | GC memory Δ  70.59 MB|
|i.c.        | 345 ms, 12 μs, and 7 hnsecs     | GC memory Δ   0.00 MB|
|i.c.+GC     | 337 ms, 555 μs, and 3 hnsecs    | GC memory Δ 144.00 MB|
|emsi        | 859 ms, 981 μs, and 4 hnsecs    | GC memory Δ   0.00 MB|

     Test inserts and lookups for int[class]      
     =======================================      
|std         | 1 sec, 118 ms, 719 μs, and 4 h  | GC memory Δ 208.44 MB|
|i.c.        | 619 ms, 602 μs, and 2 hnsecs    | GC memory Δ 186.01 MB|
|i.c.+GC     | 327 ms, 334 μs, and 7 hnsecs    | GC memory Δ 144.00 MB|
|emsi        | can't compile                   | GC memory Δ   0.00 MB|

          Test word counting int[string]          
          =============================           
|std         | 57 ms, 414 μs, and 7 hnsecs     | GC memory Δ   4.06 MB|
|i.c.        | 60 ms, 961 μs, and 9 hnsecs     | GC memory Δ   0.00 MB|
|i.c.+GC     | 61 ms, 437 μs, and 7 hnsecs     | GC memory Δ   4.00 MB|
|emsi        | 160 ms, 462 μs, and 7 hnsecs    | GC memory Δ   0.00 MB|
|correctness | 108 ms and 530 μs               | GC memory Δ   0.00 MB|

        Test double-linked list of int's         
        =================================         
|std         | 39 ms, 625 μs, and 5 hnsecs     | GC memory Δ  30.52 MB|
|i.c.unroll  | 6 ms, 963 μs, and 7 hnsecs      | GC memory Δ   0.00 MB|
|i.c.unr+GC  | 6 ms, 951 μs, and 5 hnsecs      | GC memory Δ   4.78 MB|
|emsiunroll  | 12 ms, 593 μs, and 4 hnsecs     | GC memory Δ   0.00 MB|

        Test double-linked list of structs        
        ==================================        
|std         | 76 ms, 821 μs, and 2 hnsecs     | GC memory Δ  85.50 MB|
|i.c.        | 16 ms, 329 μs, and 4 hnsecs     | GC memory Δ   0.00 MB|
|i.c.+GC     | 13 ms, 768 μs, and 2 hnsecs     | GC memory Δ  54.93 MB|

```