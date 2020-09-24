## This is performance tester for hash table ##

During set up phase two arrays of 1_000_000 random integers
('write array' and 'read array') were created. This arrays used in subsequent tests.

Results description:

Hash table - four options:
* std - dlang AA
* c.t - this package (cachetools) implementation (using Mallocator),
* c.t+GC - this package (cachetools) implementation(using GCAllocator),
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


### Tests 7-9 ###

Test performance for internal list implementations

### Test caches ###

Test 1024 entries caches (LRU and 2Q) for words stream from Shakespeare tests.


```
        Test inserts and lookups int[int]         
        =================================         
|std         | 310 ms, 181 μs, and 9 hnsecs    | GC memory Δ  41.64 MB|
|c.t.        | 141 ms, 438 μs, and 9 hnsecs    | GC memory Δ   0.00 MB|
|c.t.+GC     | 160 ms, 426 μs, and 2 hnsecs    | GC memory Δ  32.00 MB|
|emsi        | 584 ms, 974 μs, and 8 hnsecs    | GC memory Δ   0.00 MB|

                    Test scan                     
                    =========                     
|std         | 2 secs, 449 ms, 966 μs, and 7   | GC memory Δ  19.20 MB|
|c.t.        | 1 sec, 805 ms, 892 μs, and 7 h  | GC memory Δ   0.00 MB|

     Test insert, remove, lookup for int[int]     
     =======================================      
|std         | 317 ms, 1 μs, and 3 hnsecs      | GC memory Δ  17.64 MB|
|c.t.        | 192 ms, 266 μs, and 4 hnsecs    | GC memory Δ   0.00 MB|
|c.t.+GC     | 198 ms, 823 μs, and 9 hnsecs    | GC memory Δ  32.00 MB|
|emsi        | 651 ms, 775 μs, and 3 hnsecs    | GC memory Δ   0.00 MB|

     Test inserts and lookups for struct[int]     
     =======================================      
|std         | 320 ms, 833 μs, and 7 hnsecs    | GC memory Δ  70.57 MB|
|c.t.        | 310 ms, 241 μs, and 2 hnsecs    | GC memory Δ   0.00 MB|
|c.t.+GC     | 293 ms, 276 μs, and 5 hnsecs    | GC memory Δ 144.00 MB|
|emsi        | 732 ms, 26 μs, and 4 hnsecs     | GC memory Δ   0.00 MB|

     Test inserts and lookups for int[struct]     
     =======================================      
|std         | 307 ms, 243 μs, and 5 hnsecs    | GC memory Δ  70.57 MB|
|c.t.        | 351 ms, 146 μs, and 1 hnsec     | GC memory Δ   0.00 MB|
|c.t.+GC     | 340 ms, 391 μs, and 4 hnsecs    | GC memory Δ 144.00 MB|
|emsi        | 844 ms, 10 μs, and 2 hnsecs     | GC memory Δ   0.00 MB|

     Test inserts and lookups for int[class]      
     =======================================      
|std         | 1 sec, 195 ms, 451 μs, and 5 h  | GC memory Δ 267.50 MB|
|c.t.        | 567 ms, 681 μs, and 7 hnsecs    | GC memory Δ 244.14 MB|
|c.t.+GC     | 323 ms, 562 μs, and 4 hnsecs    | GC memory Δ 144.00 MB|

          Test word counting int[string]          
          =============================           
|std         | 67 ms, 304 μs, and 8 hnsecs     | GC memory Δ   4.06 MB|
|c.t.        | 67 ms, 187 μs, and 4 hnsecs     | GC memory Δ   0.00 MB|
|c.t.+GC     | 63 ms and 463 μs                | GC memory Δ   4.00 MB|
|correctness | 124 ms, 184 μs, and 5 hnsecs    | GC memory Δ   4.00 MB|

        Test double-linked list DList!int         
        =================================         
|std         | 68 ms, 460 μs, and 5 hnsecs     | GC memory Δ  30.52 MB|
|c.t.        | 139 ms and 402 μs               | GC memory Δ   0.00 MB|
|c.t.+GC     | 72 ms, 331 μs, and 6 hnsecs     | GC memory Δ  27.47 MB|
|c.t.unroll  | 18 ms, 400 μs, and 7 hnsecs     | GC memory Δ   0.00 MB|
|c.t.unr+GC  | 28 ms, 292 μs, and 3 hnsecs     | GC memory Δ  13.74 MB|
|emsiunroll  | 33 ms, 380 μs, and 8 hnsecs     | GC memory Δ   0.00 MB|

        Test single-linked list SList!int         
        =================================         
|std         | 57 ms, 288 μs, and 9 hnsecs     | GC memory Δ  15.26 MB|
|c.t.        | 114 ms, 937 μs, and 5 hnsecs    | GC memory Δ   0.00 MB|
|c.t.+GC     | 67 ms, 984 μs, and 8 hnsecs     | GC memory Δ  13.73 MB|
|emsi        | 113 ms, 373 μs, and 4 hnsecs    | GC memory Δ   0.00 MB|

        Test double-linked list of structs        
        ==================================        
|std         | 224 ms, 621 μs, and 4 hnsecs    | GC memory Δ 111.39 MB|
|c.t.        | 145 ms, 626 μs, and 9 hnsecs    | GC memory Δ   0.00 MB|
|c.t.+GC     | 123 ms, 904 μs, and 6 hnsecs    | GC memory Δ 109.88 MB|
|c.t.unr     | 71 ms, 41 μs, and 4 hnsecs      | GC memory Δ   0.00 MB|
|c.t.unr+GC  | 96 ms, 987 μs, and 6 hnsecs     | GC memory Δ 109.88 MB|
|emsi        | 169 ms, 431 μs, and 8 hnsecs    | GC memory Δ   0.00 MB|

   Test double-linked list of structs with ref    
   ===========================================    
|std         | 164 ms, 197 μs, and 4 hnsecs    | GC memory Δ 111.77 MB|
|c.t.        | 543 ms, 180 μs, and 9 hnsecs    | GC memory Δ   0.00 MB|
|c.t.+GC     | 126 ms, 170 μs, and 7 hnsecs    | GC memory Δ 109.88 MB|
|c.t.unr     | 143 ms, 300 μs, and 4 hnsecs    | GC memory Δ   0.00 MB|
|c.t.unr+GC  | 71 ms and 363 μs                | GC memory Δ  73.25 MB|
|emsi        | 446 ms, 323 μs, and 4 hnsecs    | GC memory Δ   0.00 MB|

                    Test cache                    
                    ==========                    
|lru         | 755 ms, 819 μs, and 2 hnsecs    | GC memory Δ   0.00 MB| hits 0.58|
|lru+GC      | 424 ms, 112 μs, and 8 hnsecs    | GC memory Δ   0.16 MB| hits 0.58|
|2Q          | 303 ms, 967 μs, and 1 hnsec     | GC memory Δ   0.00 MB| hits 0.69|
|2Q+GC       | 290 ms, 356 μs, and 9 hnsecs    | GC memory Δ   0.17 MB| hits 0.69|
```