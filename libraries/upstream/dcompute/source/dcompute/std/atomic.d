@compute(CompileFor.hostAndDevice) module dcompute.std.atomic;

import ldc.dcompute;

/*
 *Atomic:
 * T add (GenericPointer!T addr,T val)
 * T sub (GenericPointer!T addr,T val)
 * T xchg(GenericPointer!T addr,T val)
 * T min (GenericPointer!T addr,T val)
 * T max (GenericPointer!T addr,T val)
 * T cas (GenericPointer!T addr,T val)
 * I and (GenericPointer!I addr,I val)
 * I or  (GenericPointer!I addr,I val)
 * I xor (GenericPointer!I addr,I val)
 * I inc (GenericPointer!I addr,I val)
 * I dec (GenericPointer!I addr,I val)
 */
