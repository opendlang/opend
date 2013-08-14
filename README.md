DerelictUtil
============

<b>NOTE</b> I am in the process of splitting [Derelict 3](https://github.com/aldacron/Derelict3/) into multiple repositories. This repository is not part of that effort and is not a part of Derelict 3.

Derelict is a group of D libraries which provide bindings to a number of C libraries. The bindings are dynamic, in that they load shared libraries at run time. <b>DerelictUtil</b> is the common code base used by all of those libraries. It provides a cross-platform mechanism for loading shared libraries, exceptions that indicate failure to load, and common declarations that are useful across multiple platforms.

This README first provides a description of Derelict's exceptions and the selective loading mechanism that users of any Derelict binding can make use of. Following that is information relevant to Derelict's loaders, some of which is useful for anyone using a Derelict binding, but much of which serves as a guide to creating Derelict-like bindings using DerelictUtil.

## Exceptions

Derelict's custom exceptions reside in the <tt>derelict.util.exception</tt> module. The root exception is <tt>DerelictException</tt>. When calling the <tt>load</tt> method of any loader derived from <tt>SharedLibLoader</tt>, this root exception can be caught to indicate that the library failed to load.

For more specific exception handling, there are two subclasses of <tt>DerelictException</tt>.

The first, <tt>SharedLibLoadException</tt> is thrown when a loader fails to load a shared library from the file system. This is usually due to one or two reasons. The most common reason is that the shared library is not on the system path. By default, the loaders search the default system path, which varies across operating systems. Loaders also allow users to specify an absolute path to a shared library. If this exception is thrown in this case, it means the library was not present at that path.

The second exception is <tt>SymbolLoadException</tt>. When this exception is thrown, it indicates that the shared library was successfully loaded into the application's address space, but an expected function symbol was not found in the library. This exception is commonly seen when attempting to load a shared library of a version that does not match that against which the binding was created. For example, a binding might be created for the library libFoo 1.2. Perhaps libFoo 1.1 is on the system, but that version of the library is missing or two functions that were added in 1.2. When the loader attempts to find one of those functions in the library, it discovers the function is missing and throws a <tt>SymbolLoadException</tt>. A similar case happens if a newer version of a library has been released that removes on or more functions.

Normally, it is not necessary to distinguish between <tt>SharedLibLoadExceptions</tt> and <tt>SymbolLoadExceptions</tt> in code. Often, it is enough to catch the generic <tt>Exception</tt>, but in cases where a distinction is necessary, then <tt>DerelictException</tt> should serve the purpose. The error messages contained in each type of exception provide enough detail to distinguish the difference. The two subclasses exist solely for those rate cases where it might be beneficial to catch them separately.

## Selective Symbol Loading

DerelictUtil also provides a mechanism that I call <i>selective symbol loading</i>. This allows a user to prevent a <tt>SymbolLoadException</tt> from being thrown in specific cases. For instance, in the <b>libFoo</b> example above, where the binding was made for 1.2, but the user might have 1.1 installed, selective symbol loading can be used to ignore the new 1.2 functions that are missing from the 1.1 version.

The module <tt>derelict.util.exception</tt> declares two type aliases, <tt>MissingSymbolCallbackFunc</tt> and <tt>MissingSymbolCallbackDg</tt>, each that take a single  <tt>string</tt> parameter that is the name of a missing symbol. The former is a function pointer, the latter a delegate. A missing symbol callback of either type can be set on any instance of <tt>SharedLibLoader</tt> via its <tt>missingSymbolCallbck</tt> property, passing either a function pointer or a delegate as the sole parameter. When a missing symbol is encountered, the loader will call the callback if one has been set. If the callback returns <tt>ShouldThrow.No</tt>, the symbol will be ignored and no exception will be thrown. Conversely, returning <tt>ShouldThrow.Yes</tt> causes the exception to be thrown. An example follows.

```D
ShouldThrow missingSymFunc( string symName ) {
    // Assume getBar is a function added in libFoo 1.2. Our application does not
    // use getBar, so libFoo 1.1 is acceptable. So if we find that getBar is missing,
    // don't throw. This will allow version 1.1 to load.
    if( symName == "getBar") {
        return ShouldThrow.No;
    }

    // Any other missing symbol should throw.
    return ShouldThrow.Yes;
}

void loadLibFoo() {
    // First, set the missing symbol callback.
    DerelictFoo.missingSymbolCallback = &missingSymFunc;

    // Load libFoo
    DerelictFoo.load();
}
```

## Loaders

Coming soon!

