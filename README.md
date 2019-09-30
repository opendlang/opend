# commonmark-d

`commonmark-d` is a D translation of [MD4C](https://github.com/mity/md4c), a fast SAX-like Markdown parser.
MD4C achieves remarkable parsing speed through the lack of AST and careful memory usage.


## Usage

```d

// Parse CommonMark, generate HTML
import commonmarkd;
string html = convertMarkdownToHTML(markdown);

// Parse Github Flavoured Markdown, generate HTML
string html = convertMarkdownToHTML(markdown, MarkdownFlag.dialectGitHub);

// Parse CommonMark without HTML support, generate HTML
import commonmarkd;
string html = convertMarkdownToHTML(markdown, MarkdownFlag.noHTML);


```

# Performance

## Compile speed

In debug builds, `commonmark-d` is compiled 3x faster than alternatives.

Timing debug build of various Markdown parsers in D:
```



commonmark-d:
$ time /mnt/c/d/ldc2-1.17.0-windows-multilib/bin/dub.exe -f
real    0m1.144s
user    0m0.000s
sys     0m0.016s

dmarkdown:
$ time /mnt/c/d/ldc2-1.17.0-windows-multilib/bin/dub.exe -f
real    0m3.186s
user    0m0.000s
sys     0m0.000s

hunt-markdown:
real    0m39.960s
user    0m0.000s
sys     0m0.016s
```


## Runtime speed

At runtime `commonmark-d` is 2x faster than dmarkdown and 15x faster than hunt-markdown (see Benchmark below).

It also builds faster than both.


## Speed Benchmark

commonmark-d is benched against dmarkdown and hunt-markdown, on a selection of Markdown blog posts.
Using LDC 1.0.17, dub -b release-nobounds --combined -a x86_64 ---

Output:

```

*** Parsing file content\2015-04-07_Auburn Sounds website is now live!.md
time dmarkdown     = 108 us, HTML length = 620
time hunt-markdown = 1057 us, HTML length = 522
time commonmark-d  = 101 us, HTML length = 522

*** Parsing file content\2015-11-17_First plugin Graillon in open beta!.md
time dmarkdown     = 58 us, HTML length = 865
time hunt-markdown = 2753 us, HTML length = 779
time commonmark-d  = 48 us, HTML length = 778

*** Parsing file content\2015-11-26_Graillon 1.0 released.md
time dmarkdown     = 118 us, HTML length = 1840
time hunt-markdown = 546 us, HTML length = 1577
time commonmark-d  = 35 us, HTML length = 1577

*** Parsing file content\2016-02-04_Interested in shaping our future plugins&#63;.md
time dmarkdown     = 85 us, HTML length = 913
time hunt-markdown = 487 us, HTML length = 872
time commonmark-d  = 32 us, HTML length = 872

*** Parsing file content\2016-02-08_Making a Windows VST plugin with D.md
time dmarkdown     = 284 us, HTML length = 9849
time hunt-markdown = 4393 us, HTML length = 8787
time commonmark-d  = 126 us, HTML length = 8775

*** Parsing file content\2016-06-22_Introducing Panagement.md
time dmarkdown     = 85 us, HTML length = 2063
time hunt-markdown = 747 us, HTML length = 1944
time commonmark-d  = 35 us, HTML length = 1944

*** Parsing file content\2016-08-22_Why AAX is not supported right now.md
time dmarkdown     = 82 us, HTML length = 1779
time hunt-markdown = 225 us, HTML length = 1691
time commonmark-d  = 49 us, HTML length = 1691

*** Parsing file content\2016-09-08_Panagement and Graillon 1.1 release.md
time dmarkdown     = 137 us, HTML length = 2016
time hunt-markdown = 914 us, HTML length = 1783
time commonmark-d  = 36 us, HTML length = 1783

*** Parsing file content\2016-09-16_PBR for Audio Software Interfaces.md
time dmarkdown     = 340 us, HTML length = 9637
time hunt-markdown = 2012 us, HTML length = 8929
time commonmark-d  = 134 us, HTML length = 8929

*** Parsing file content\2016-11-07_Panagement and Graillon 1.2 release.md
time dmarkdown     = 68 us, HTML length = 1091
time hunt-markdown = 670 us, HTML length = 980
time commonmark-d  = 41 us, HTML length = 980

*** Parsing file content\2016-11-10_Running D without its runtime.md
time dmarkdown     = 550 us, HTML length = 10362
time hunt-markdown = 4572 us, HTML length = 9056
time commonmark-d  = 157 us, HTML length = 9047

*** Parsing file content\2016-12-14_We are in Computer Music!.md
time dmarkdown     = 76 us, HTML length = 883
time hunt-markdown = 395 us, HTML length = 820
time commonmark-d  = 40 us, HTML length = 820

*** Parsing file content\2017-02-13_Vibrant 2.0 released, free demo.md
time dmarkdown     = 68 us, HTML length = 1001
time hunt-markdown = 417 us, HTML length = 943
time commonmark-d  = 44 us, HTML length = 943

*** Parsing file content\2017-07-27_Graillon 2 A New Effect for Live Voice Changing.md
time dmarkdown     = 95 us, HTML length = 1721
time hunt-markdown = 892 us, HTML length = 1574
time commonmark-d  = 38 us, HTML length = 1574

*** Parsing file content\2017-10-14_The History Of Vibrant.md
time dmarkdown     = 268 us, HTML length = 5620
time hunt-markdown = 1606 us, HTML length = 5402
time commonmark-d  = 86 us, HTML length = 5402

*** Parsing file content\2018-01-18_Bringing AAX to you.md
time dmarkdown     = 82 us, HTML length = 1841
time hunt-markdown = 1008 us, HTML length = 1576
time commonmark-d  = 56 us, HTML length = 1576

*** Parsing file content\2018-08-16_Introducing our new plug-in Couture.md
time dmarkdown     = 130 us, HTML length = 3250
time hunt-markdown = 1476 us, HTML length = 3039
time commonmark-d  = 68 us, HTML length = 3039

*** Parsing file content\2019-03-01_A Consequential Update.md
time dmarkdown     = 262 us, HTML length = 9008
time hunt-markdown = 2831 us, HTML length = 7940
time commonmark-d  = 130 us, HTML length = 7940

*** Parsing file content\2019-08-14_Introducing Panagement 2.md
time dmarkdown     = 131 us, HTML length = 3951
time hunt-markdown = 1204 us, HTML length = 3680
time commonmark-d  = 65 us, HTML length = 3680

```

## Changes versus original parser

- Only UTF-8 input is supported
- (future) `malloc` and `realloc` failures will not be considered, because in Out Of Memory situations crashing is a reasonable solution.
