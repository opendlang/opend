DerelictUtil
============

<b>NOTE</b> I am in the process of splitting [Derelict 3](https://github.com/aldacron/Derelict3/) into multiple repositories under the DerelictOrg umbrella. This repository is part of that effort and is not a part of Derelict 3.

Derelict is a group of D libraries which provide bindings to a number of C libraries. The bindings are dynamic, in that they load shared libraries at run time. <b>DerelictUtil</b> is the common code base used by all of those libraries. It provides a cross-platform mechanism for loading shared libraries, exceptions that indicate failure to load, and common declarations that are useful across multiple platforms.

For more information on how to use DerelictUtil, either as the user of a dynamic binding based on DerelictUtil or as the implementor of a custom binding, see the [DerelictUtil wiki](https://github.com/DerelictOrg/util/wiki).