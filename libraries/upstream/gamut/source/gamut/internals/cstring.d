/**
D string to C string.

Copyright: Copyright Guillaume Piolat 2022
License:   $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost License 1.0)
*/
module gamut.internals.cstring;

import core.stdc.stdlib: malloc, free;

//
// Low-cost C string conversions
//
alias CString = CStringImpl!char;
alias CString16 = CStringImpl!wchar;

/// Zero-terminated C string, to replace toStringz and toUTF16z
struct CStringImpl(CharType) if (is(CharType: char) || is(CharType: wchar))
{
public:
nothrow:
@nogc:

    const(CharType)* storage = null;
    alias storage this;


    this(const(CharType)[] s)
    {
        // Always copy. We can't assume anything about the input.
        size_t len = s.length;
        CharType* buffer = cast(CharType*) malloc((len + 1) * CharType.sizeof);
        buffer[0..len] = s[0..len];
        buffer[len] = '\0';
        storage = buffer;
        wasAllocated = true;
    }

    // The constructor taking immutable can safely assume that such memory
    // has been allocated by the GC or malloc, or an allocator that align
    // pointer on at least 4 bytes.
    this(immutable(CharType)[] s)
    {
        // Same optimizations that for toStringz
        if (s.length == 0)
        {
            enum emptyString = cast(CharType[])"";
            storage = emptyString.ptr;
            return;
        }

        /* Peek past end of s[], if it's 0, no conversion necessary.
        * Note that the compiler will put a 0 past the end of static
        * strings, and the storage allocator will put a 0 past the end
        * of newly allocated char[]'s.
        */
        const(CharType)* p = s.ptr + s.length;
        // Is p dereferenceable? A simple test: if the p points to an
        // address multiple of 4, then conservatively assume the pointer
        // might be pointing to another block of memory, which might be
        // unreadable. Otherwise, it's definitely pointing to valid
        // memory.
        if ((cast(size_t) p & 3) && *p == 0)
        {
            storage = s.ptr;
            return;
        }

        size_t len = s.length;
        CharType* buffer = cast(CharType*) malloc((len + 1) * CharType.sizeof);
        buffer[0..len] = s[0..len];
        buffer[len] = '\0';
        storage = buffer;
        wasAllocated = true;
    }

    ~this()
    {
        if (wasAllocated)
            free(cast(void*)storage);
    }

    @disable this(this);

private:
    bool wasAllocated = false;
}

/// Semantic function to check that a D string implicitely conveys a
/// termination byte after the slice.
/// (typically those comes from string literals or `stringDup`/`stringIDup`)
const(char)* assumeZeroTerminated(const(char)[] input) pure nothrow @nogc @trusted
{
    assert (input.ptr !is null);

    // Check that the null character is there
    assert(input.ptr[input.length] == '\0');
    return input.ptr;
}