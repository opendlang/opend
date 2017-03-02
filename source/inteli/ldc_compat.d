module inteli.ldc_compat;

version(LDC)
{
    public import core.simd;

    // To support LDC 1.0
    // Taken from ldc.simd from LDC 1.1
    
    static if (__VERSION__ <= 2070) 
    {
        // Note for LDC 1.0: loadAligned is broken so we replace it.
        //                   storeAligned so we provide it.
        public import ldc.simd: extractelement, 
                                insertelement,
                                shufflevector,
                                inlineIR;

        private template BaseType(V)
        {
            alias typeof(V.array[0]) BaseType;
        }

        private template numElements(V)
        {
            enum numElements = V.sizeof / BaseType!(V).sizeof;
        }

        private template llvmType(T)
        {
            static if(is(T == float))
                enum llvmType = "float";
            else static if(is(T == double))
                enum llvmType = "double";
            else static if(is(T == byte) || is(T == ubyte) || is(T == void))
                enum llvmType = "i8";
            else static if(is(T == short) || is(T == ushort))
                enum llvmType = "i16";
            else static if(is(T == int) || is(T == uint))
                enum llvmType = "i32";
            else static if(is(T == long) || is(T == ulong))
                enum llvmType = "i64";
            else
                static assert(0,
                    "Can't determine llvm type for D type " ~ T.stringof);
        }

        private template llvmVecType(V)
        {
            static if(is(V == void16))
                enum llvmVecType =  "<16 x i8>";
            else static if(is(V == void32))
                enum llvmVecType =  "<32 x i8>";
            else
            {
                alias BaseType!V T;
                enum int n = numElements!V;
                enum llvmT = llvmType!T;
                enum llvmVecType = "<"~n.stringof~" x "~llvmT~">";
            }
        }

        /**
        loadUnaligned: Loads a vector from an unaligned pointer.
        Example:
        ---
        int[4] a = [0, 10, 20, 30];
        int4 v = loadUnaligned!int4(a.ptr);
        assert(v.array == a);
        ---
        */
        template loadUnaligned(V)
        if(is(typeof(llvmVecType!V)))
        {
            alias BaseType!V T;
            enum llvmT = llvmType!T;
            enum llvmV = llvmVecType!V;
            version (LDC_LLVM_PRE307)
            {
                enum ir = `
                    %p = bitcast `~llvmT~`* %0 to `~llvmV~`*
                    %r = load `~llvmV~`* %p, align 1
                    ret `~llvmV~` %r`;
            }
            else
            {
                enum ir = `
                    %p = bitcast `~llvmT~`* %0 to `~llvmV~`*
                    %r = load `~llvmV~`, `~llvmV~`* %p, align 1
                    ret `~llvmV~` %r`;
            }

            alias inlineIR!(ir, V, const(T)*) loadUnaligned;
        }

        /**
        storeUnaligned: Stores a vector to an unaligned pointer.
        Example:
        ---
        int[4] a;
        int4 v = [0, 10, 20, 30];
        storeUnaligned!int4(v, a.ptr);
        assert(v.array == a);
        ---
        */
        template storeUnaligned(V)
       // if(is(typeof(llvmVecType!V)))
        {
          alias BaseType!V T;
          enum llvmT = llvmType!T;
          enum llvmV = llvmVecType!V;
          enum ir = `
              %p = bitcast `~llvmT~`* %1 to `~llvmV~`*
              store `~llvmV~` %0, `~llvmV~`* %p, align 1`;
          alias inlineIR!(ir, void, V, T*) storeUnaligned;
        }


    }
    else
    {
        public import ldc.simd;
    }
}