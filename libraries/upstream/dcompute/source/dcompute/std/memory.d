@compute(CompileFor.hostAndDevice) module dcompute.std.memory;

import ldc.dcompute;

/*
 *Pointer conversions:
 * *Pointer!T genericPtrTo*(GenericPointer!T ptr)
 * GenericPointer!T *toGenericPtr(*Pointer!T ptr)
 *
 *Shared memory:
 * SharedPointer!T sharedStaticReserve!(T[N])
 * SharedPointer!void sharedDynamicBase();
 * auto sharedIndices!(Ts...) if(isSharedIndex!(Ts...) // (T, alias length) pairs
       see http://stackoverflow.com/questions/15435559/use-dynamic-shared-memory-allocation-for-two-different-vectors
       for what this emulates any why. Memory aligned to A = reduce!max(T.alignof)
       Returns a tuple of {SharedPointer!(align(A) T), length} "arrays"
 */
