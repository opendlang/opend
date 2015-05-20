[![Build Status](https://travis-ci.org/DlangScience/dstats.svg?branch=master)](https://travis-ci.org/DlangScience/dstats)
dstats
======

A statistics library for D, emphasising a middle ground between performance and ease 
of use. This repository is a fork of David Simcha's https://github.com/dsimcha/dstats
created to bring the library up to date and enable dub support.


Building
--------

###dub
Simply add dstats as a dependency in your projects dub.json

The SciD version of dstats is not currently supported in dub.

###manual

This library has no mandatory dependencies other than the latest versions of Phobos 
and DMD.
To build, simply unpack all the files into an empty directory and do a:

dmd -O -inline -release -lib -ofdstats.lib *.d

SciD is an optional dependency, as Dstats is slowly being integrated into it.
If used, it enables a few extra features and faster implementations of some 
algorithms.
To build with this enabled, make sure your SciD directory is in your import path and 
do:

dmd -O -inline -release -lib -ofdstats.lib -version=scid *.d

You'll then need to link in your SciD library and Blas and Lapack libraries when 
compiling
an application that uses Dstats.

Conventions
-----------

1.  A delicate balance between ease of use, flexibility and performance should be maintained.  
There are tons of good libraries for hardcore numerics programmers that emphasize performance above 
all else.  There are also tons of good statistics packages for people who are basically 
non-programmers and aren't doing large-scale analyses or analyses in the context of larger programs.  
The distribution seems very bimodal.  This library tries to target the middle ground and recognize
the principles of tradeoffs and diminishing returns with regard to performance, flexibility 
and ease of use.

2.  Everything should work with the lowest common denominator generic range possible.  It's 
frustrating to have to write tons of boilerplate code just to translate data from one format into 
another.  Also, oftentimes even if the data is in the form of an array it needs to be copied so it 
can be reordered without the reordering being visible to the caller.  In these cases, it can be 
copied just as easily whether the input data is in the form of an array or some other range.

3.  Throwing exceptions vs. returning NaN:  The convention here is that an exception should be
thrown if a primitive parameter (i.e. an int or a float) is not in the acceptable range.  This is
because such things can trivially be checked upfront and should not occur by accident in most cases,
except for the case of bugs internal to dstats.  If the errant function parameter is the dataset, 
i.e. a range of some kind, then a NaN should be returned, because when doing large-scale analyses, 
a few pieces of data are expected to be defective in ways that are not easy to check upfront and 
should not halt the whole analysis.

In general, this means that dstats.distrib should throw on invalid parameters,
and all other modules should return a NaN.  Any other result is most likely a bug.  
Cases where dstats.tests calls into dstats.distrib, resulting in thrown exceptions, are 
unfortunately too common and need to be fixed.

4.  License:  Each file contains a license header.  All modules that are exclusively written by
the main author (David Simcha) are licensed under the Boost license, so that pieces of them may
freely be incorporated into Phobos and attribution is not required for binaries.  Some modules
consist of code borrowed from other places and are thus required to conform to the terms of these
licenses.  All are under permissive (i.e. non-copyleft) open source licenses, but some may require 
binary attribution.  

Known Problems
--------------

https://issues.dlang.org/show_bug.cgi?id=9449 causes a segfault in ```dstats.tests.friedmanTest``` on the line ```Mean[len] colMeans;```. This is a backend bug and does not affect ldc or gdc.
