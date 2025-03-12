module dcompute.driver.util;

import std.traits;
import std.meta;
import ldc.dcompute : Pointer;
import dcompute.driver.ocl.buffer : Buffer;
template HostArgsOf(F)
{
    import std.traits;
    // TODO substitute Pointer!(n,T) with Buffer!T, Image etc.
    template toBuffer(T)
    {
        static if(is(T : Pointer!(n,U), uint n,U))
            alias toBuffer = Buffer!U;
        else
            alias toBuffer = T;
    }
    alias HostArgsOf = staticMap!(toBuffer,Parameters!F);
}
