# Running D without its runtime

_In this article, we'll disable the D programming language runtime. Expected audience: software developers interested in D. Reading time = 8 min._

Our products [Panagement](../products/Panagement.html) and [Graillon](../products/Graillon.html) now run with the D language runtime disabled. This post is both a post-mortem and tutorial on how to live without the D runtime.


## 1. What does the D language runtime do?

Upon entry into a normal D program, `druntime` is initialized.

What does `druntime` do?
- Running global constructors,
- Allocating space for thread-local variables (TLS),
- Enabling the Garbage Collector to function properly (GC).

A lot of the runtime machinery exists for the sole usage of the GC. `druntime` maintains a list of _registered_ threads, whose stack segments have to be scanned by the GC, in case they would hold pointers to managed memory blocks.



## 2. The D runtime is optional

As a system language, D is able to operate without its runtime. A program without `druntime` will instead rely on the C runtime only. This doesn't come without effort.

Two different solutions here:

- **"Runtime-less": Not linking with the runtime.** This has the benefit of turning every runtime use into a linking error. Some language features depend on data structures provided by the runtime source code. Hence the need to rewrite a minimal `druntime`. This is involved and more fit for [writing an OS](https://github.com/Vild/PowerNex) than for making consumer software.

- **"Runtime-free": Linking with the runtime, and then not enabling it.** `Runtime.initialize()` is just not called. GC allocations, global constructors/destructors, and thread-local variables have to be avoided. And that's about it.

We went with "runtime-free" because it's easier.

## 3. Why did we disable druntime for audio plugins?

This was more of a logical next step than an absolute necessity.

Advantages:

- Support unloading D shared libraries on macOS with existing D compilers. This was previously working with a hack, but that hack broke with macOS Sierra.

- Avoids to register and unregister threads constantly. When called from an audio host, the only clean way is to register the incoming thread, and unregister it as it goes. _"This causes some overhead"_, we thought.

- Most of our code was already avoiding the GC and TLS,

- We were expecting performance improvements.


Disadvantages:

- Disabling the runtime includes (but is not limited to) disabling the GC,

- Inability to use parts of the standard library,

- Inability to use most of the [library ecosystem](http://code.dlang.org/).


So we set ourselves on a task to mainly remove all outstanding GC allocations.
Fortunately, D has an attribute called `@nogc`.


## 4. Going fully `@nogc`

`@nogc` ensures zero GC allocation in functions it annotates. `@nogc` is essential to reach runtime freedom.

### Step 1. Assuming `@nogc` with casting

Ironically, one of the first thing we need is an escape-hatch from `nothrow @nogc` (these attributes often travel together in practice, so let's group them).

```
/// Assumes a function to be nothrow and @nogc
auto assumeNothrowNoGC(T) (T t) if (isFunctionPointer!T || isDelegate!T)
{
    enum attrs = functionAttributes!T
               | FunctionAttribute.nogc
               | FunctionAttribute.nothrow_;
    return cast(SetFunctionAttributes!(T, functionLinkage!T, attrs)) t;
}
```

This breaks the type-system and allows to conveniently shoot oneself in the foot. So why do this?

The reason is: `Object.~this()`, base destructor of every class object, is virtual and neither `nothrow` nor `@nogc`. Because of covariance, **every class object's destructor is assumed to throw exceptions and use the GC by default.**

So `assumeNothrowNoGC!T` is an important building block to call carefully choosen class destructors in `nothrow @nogc` contexts. Let's see how.

### Step 2. An optimistic `object.destroy()`-like

We can use our brand new foot-shooting device in the following way:

```
// For classes
void destroyNoGC(T)(T x) nothrow @nogc
    if (is(T == class) || is(T == interface))
{
    assumeNothrowNoGC(
        (T x)
        {
            return destroy(x);
        })(x);
}

// For structs
void destroyNoGC(T)(ref T obj) nothrow @nogc
    if (is(T == struct))
{
    assumeNothrowNoGC(
        (ref T x)
        {
            return destroy(x);
        })(obj);
}
```

For our purpose, `object.destroy()` has the fatal flaw of not being `nothrow @nogc` (because it may call `Object.~this()`). `assumeNothrowNoGC` makes `object.destroy()` work for `nothrow @nogc` code.


### Step 3. Objects on the `malloc` heap

Going forward with our trail of casts and unsafety, let's make a template function like C++'s `new`:

```
/// Allocates and construct a class or struct object.
/// Returns: Newly allocated object.
auto mallocEmplace(T, Args...)(Args args)
{
    static if (is(T == class))
        immutable size_t allocSize = __traits(classInstanceSize, T);
    else
        immutable size_t allocSize = T.sizeof;

    void* rawMemory = malloc(allocSize);
    if (!rawMemory)
        onOutOfMemoryErrorNoGC();

    static if (is(T == class))
    {
        T obj = emplace!T(rawMemory[0 .. allocSize], args);
    }
    else
    {
        T* obj = cast(T*)rawMemory;
        emplace!T(obj, args);
    }

    return obj;
}
```

Then a function like C++'s `delete`:

```
/// Destroys and frees an object created with `mallocEmplace`.
void destroyFree(T)(T p) if (is(T == class) || is(T == interface))
{
    if (p !is null)
    {
        static if (is(T == class))
        {
            destroyNoGC(p);
            free(cast(void*)p);
        }
        else
        {
            // A bit different with interfaces,
            // because they don't point to the object itself
            void* here = cast(void*)(cast(Object)p);
            destroyNoGC(p);
            free(cast(void*)here);)
        }
   }
}

/// Destroys and frees a non-class object created with `mallocEmplace`.
void destroyFree(T)(T* p) if (!is(T == class) && !is(T == interface))
{
    if (p !is null)
    {
        destroyNoGC(p);
        free(cast(void*)p);
    }
}
```

_(Note: If the GC were enabled, one would maintain GC roots for the allocated memory chunk.)_

It turns out this `mallocEmplace` / `destroyFree` duo is an adequate replacement for class objects allocated with `new`, including exceptions.


### Step 4. Throwing exceptions despite `@nogc`

How do we throw and catch exceptions in `@nogc` code?

One can construct an `Exception` with manual memory management and `throw` it:

```
// Instead of:
//    throw new Exception("Message")
throw mallocEmplace!Exception("Message");
```

At the call site, such manual exceptions would have to be released when caught:

```
try
{
    doSomethingThatMightThrow(userInputData);
    return true;
}
catch(Exception e)
{
    e.destroyFree(); // release e manually
    return false;
}
```

Using exceptions in `@nogc` code can be easy, provided both caller and callee agree on manual exceptions.


## 5. Results

Long story short, we brute-forced our way into having fully `@nogc` programs, with the runtime left uninitialized.

As expected this fixed macOS Sierra compatibility. As a bonus [Panagement](../products/Panagement.html) and [Graillon](../products/Graillon.html) are now using **2x less memory**, which is nice, but hardly life-changing.

We found no magical speed enhancement. **Speed-wise nothing changed**. Not registering threads in callbacks did not bring any meaningful gain. GC pauses were already never happening so disabling the GC did not help.

In conclusion, it is still our opinion that outside niche requirements, there isn't enough reasons to depart from the D runtime and its GC.

[Learn more about Dplug, our audio plugin framework...](https://github.com/AuburnSounds/dplug)