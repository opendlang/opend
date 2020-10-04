## Mir-Ion vs [sajson](https://github.com/chadaustin/sajson) Benchmark

### Platform
Intel Haswell (AVX2),

### Mir-Ion
```
dub build --build=release-nobounds --compiler=ldmd2
```

#### sajson
```
// sources are in sajson GitHub repository
clang++ -O3 -march=native -std=c++14 benchmark/benchmark.cpp -Iinclude
```

### Results

| Test | sajson, avg μs | mir-ion, avg μs | Speedup |
|---|---|---|---|
| apache_builds | 142 | 93 | 53 % |
| github_events | 78 | 44 | 77 % |
| instruments | 272 | 182 | 49 % |
| mesh | 1844 | 733 | 152 % |
| mesh.pretty | 2728 | 1178 | 132 % |
| nested | 93 | 111 | -16 % |
| svg_menu | 2 | 1 | 100 % |
| truenull | 18 | 10 | 80 % |
| twitter | 919 | 461 | 99 % |
| update-center | 838 | 405 | 107 % |
| whitespace | 9 | 7 | 29 % |
