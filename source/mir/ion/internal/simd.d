module mir.ion.internal.simd;

import core.simd;
version (LDC) import ldc.llvmasm;

version (ARM)
    version = ARM_Any;

version (AArch64)
    version = ARM_Any;

version (X86)
    version = X86_Any;

version (X86_64)
    version = X86_Any;

@safe pure nothrow @nogc:

version(LDC) version(ARM_Any)
ulong[2] equalNotEqualMaskArm()(ubyte16[4][2] v, ubyte16[4][2] stringMasks)
    @trusted
{
    pragma(inline, true);
    import ldc.simd: extractelement, equalMask, notEqualMask;

    const ubyte16 mask = [
        0x01, 0x02, 0x04, 0x08, 0x10, 0x20, 0x40, 0x80, 0x01, 0x02, 0x04, 0x08, 0x10, 0x20, 0x40, 0x80,
    ];

    ubyte16[4][2] d;
    static foreach (j; 0 .. 4)
        d[0][j] = cast(ubyte16) equalMask!(ubyte16)(v[0][j], stringMasks[0][j]);
    static foreach (j; 0 .. 4)
        d[1][j] = cast(ubyte16) notEqualMask!(ubyte16)(v[1][j], stringMasks[1][j]);
    static foreach (i; 0 .. 2)
    static foreach (j; 0 .. 4)
        d[i][j] &= mask;
    version (AArch64)
    {
        version(all)
        {
        static foreach (_; 0 .. 3)
        static foreach (i; 0 .. 2)
        static foreach (j; 0 .. 4)
            d[i][j] = neon_addp_v16i8(d[i][j], d[i][j]);

        __vector(ushort[8]) result;
        static foreach (i; 0 .. 2)
        static foreach (j; 0 .. 4)
            result[i * 4 + j] = extractelement!(__vector(ushort[8]), i * 4 + j)(cast(__vector(ushort[8])) d[i][j]);
        }
        else
        {
        align(8) ubyte[2][4][2] result;
        static foreach (i; 0 .. 2)
        static foreach (j; 0 .. 4)
        {
            result[i][j][0] = (cast(__vector(ubyte[8])[2])d[i][j])[0].neon_uaddv_i8_v8i8;
            result[i][j][1] = (cast(__vector(ubyte[8])[2])d[i][j])[1].neon_uaddv_i8_v8i8;
        }
        }
    }
    else
    {
        align(8) ubyte[16] result;
        static foreach (i; 0 .. 2)
        static foreach (j; 0 .. 4)
        {
            d[i][j] = d[i][j]
                .__builtin_vpaddlq_u8
                .__builtin_vpaddlq_u16
                .__builtin_vpaddlq_u32;
            result[i * 8 + j * 2 + 0] = extractelement!(ubyte16, 0)(d[i][j]);
            result[i * 8 + j * 2 + 1] = extractelement!(ubyte16, 8)(d[i][j]);
        }
    }
    return cast(ulong[2]) result;
}

version(LDC) version(ARM_Any)
ulong[2] equalMaskArm(ref __vector(ubyte[64]) _v, ubyte16[2] stringMasks)
    @trusted
{
    pragma(inline, true);
    import ldc.simd: extractelement, equalMask;
 
    const ubyte16 mask = [
        0x01, 0x02, 0x04, 0x08, 0x10, 0x20, 0x40, 0x80, 0x01, 0x02, 0x04, 0x08, 0x10, 0x20, 0x40, 0x80,
    ];

    auto v = *cast(ubyte16[4]*)&_v;
    ubyte16[4][2] d;
    static foreach (i; 0 .. 2)
    static foreach (j; 0 .. 4)
        d[i][j] = cast(ubyte16) equalMask!(ubyte16)(v[j], stringMasks[i]);
    static foreach (i; 0 .. 2)
    static foreach (j; 0 .. 4)
        d[i][j] &= mask;
    version (AArch64)
    {
        version(all)
        {
        static foreach (_; 0 .. 3)
        static foreach (i; 0 .. 2)
        static foreach (j; 0 .. 4)
            d[i][j] = neon_addp_v16i8(d[i][j], d[i][j]);

        __vector(ushort[8]) result;
        static foreach (i; 0 .. 2)
        static foreach (j; 0 .. 4)
            result[i * 4 + j] = extractelement!(__vector(ushort[8]), i * 4 + j)(cast(__vector(ushort[8])) d[i][j]);
        }
        else
        {
        align(8) ubyte[2][4][2] result;
        static foreach (i; 0 .. 2)
        static foreach (j; 0 .. 4)
        {
            result[i][j][0] = (cast(__vector(ubyte[8])[2])d[i][j])[0].neon_uaddv_i8_v8i8;
            result[i][j][1] = (cast(__vector(ubyte[8])[2])d[i][j])[1].neon_uaddv_i8_v8i8;
        }
        }
    }
    else
    {
        align(8) ubyte[16] result;
        static foreach (i; 0 .. 2)
        static foreach (j; 0 .. 4)
        {
            d[i][j] = d[i][j]
                .__builtin_vpaddlq_u8
                .__builtin_vpaddlq_u16
                .__builtin_vpaddlq_u32;
            result[i * 8 + j * 2 + 0] = extractelement!(ubyte16, 0)(d[i][j]);
            result[i * 8 + j * 2 + 1] = extractelement!(ubyte16, 8)(d[i][j]);
        }
    }
    return cast(ulong[2]) result;
}

version (X86_Any)
{
    version (LDC)
    {
        pragma(LDC_intrinsic, "llvm.x86.ssse3.pshuf.b.128")
            __vector(ubyte[16]) ssse3_pshuf_b_128(__vector(ubyte[16]), __vector(ubyte[16]));
        pragma(LDC_intrinsic, "llvm.x86.avx2.pshuf.b")
            __vector(ubyte[32]) avx2_pshuf_b(__vector(ubyte[32]), __vector(ubyte[32]));
        pragma(LDC_intrinsic, "llvm.x86.avx512.pshuf.b.512")
            __vector(ubyte[64]) avx512_pshuf_b_512(__vector(ubyte[64]), __vector(ubyte[64]));
    }

    version (GDC)
    {
        public import gcc.builtins:
            ssse3_pshuf_b_128 = __builtin_ia32_pshufb,
            avx2_pshuf_b = __builtin_ia32_pshufb256,
            avx512_pshuf_b_512 = __builtin_ia32_pshufb512;
    }
}

version (AArch64)
{
    version (LDC)
    {
        public import mir.llvmint:
            neon_addp_v16i8,
            neon_tbl2_v16i8,
            neon_tbl1_v16i8,
            neon_tbx2_v16i8,
            neon_tbx1_v16i8,
            neon_uaddv_i8_v8i8;
    }

    version (GNU)
    {
        public import gcc.builtins: neon_addp_v16i8 = __builtin_vpadd_u32;
    }
}

version (ARM)
{
    version (LDC)
    {
        public import gcc.builtins:
            neon_vpaddlu_v8i16_v16i8,
            neon_vpaddlu_v4i32_v8i16,
            neon_vpaddlu_v2i64_v4i32;

        // vld1q
        // vandq
        // vdupq_n
        // vshlq
        // vaddv
        // vget_low
        // vget_high
    }

    version (GNU)
    {
        public import gcc.builtins:
            neon_vpaddlu_v8i16_v16i8 = __builtin_vpaddlq_u8,
            neon_vpaddlu_v4i32_v8i16 = __builtin_vpaddlq_u16,
            neon_vpaddlu_v2i64_v4i32 = __builtin_vpaddlq_u32;
    }
}


private template isFloatingPoint(T)
{
    enum isFloatingPoint =
        is(T == float) ||
        is(T == double) ||
        is(T == real);
}

private template isIntegral(T)
{
    enum isIntegral =
        is(T == byte) ||
        is(T == ubyte) ||
        is(T == short) ||
        is(T == ushort) ||
        is(T == int) ||
        is(T == uint) ||
        is(T == long) ||
        is(T == ulong);
}

private template isSigned(T)
{
    enum isSigned =
        is(T == byte) ||
        is(T == short) ||
        is(T == int) ||
        is(T == long);
}

private template IntOf(T)
if(isIntegral!T || isFloatingPoint!T)
{
    enum n = T.sizeof;
    static if(n == 1)
        alias byte IntOf;
    else static if(n == 2)
        alias short IntOf;
    else static if(n == 4)
        alias int IntOf;
    else static if(n == 8)
        alias long IntOf;
    else
        static assert(0, "Type not supported");
}

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
    static if(is(V == __vector(void[16])))
        enum llvmVecType =  "<16 x i8>";
    else static if(is(V == __vector(void[32])))
        enum llvmVecType =  "<32 x i8>";
    else
    {
        alias BaseType!V T;
        enum int n = numElements!V;
        enum llvmT = llvmType!T;
        enum llvmVecType = "<"~n.stringof~" x "~llvmT~">";
    }
}

enum Cond{ eq, ne, gt, ge }

template cmpMaskB(Cond cond)
{
    template cmpMaskB(V)
    if(is(IntOf!(BaseType!V)))
    {
        alias BaseType!V T;
        enum llvmT = llvmType!T;

        alias IntOf!T Relem;

        enum int n = numElements!V;

        static if (n <= 8)
            alias R = ubyte;
        else static if (n <= 16)
            alias R = ushort;
        else static if (n <= 32)
            alias R = uint;
        else static if (n <= 64)
            alias R = ulong;
        else static assert(0);

        enum int rN = R.sizeof * 8;

        enum llvmV = llvmVecType!V;
        enum sign =
            (cond == Cond.eq || cond == Cond.ne) ? "" :
            isSigned!T ? "s" : "u";
        enum condStr =
            cond == Cond.eq ? "eq" :
            cond == Cond.ne ? "ne" :
            cond == Cond.ge ? "ge" : "gt";
        enum op =
            isFloatingPoint!T ? "fcmp o"~condStr : "icmp "~sign~condStr;

        enum ir = `
            %cmp = `~op~` `~llvmV~` %0, %1
            %bc = bitcast <`~n.stringof~` x i1> %cmp to i`~rN.stringof~`
            ret i`~rN.stringof~` %bc`;
        alias __ir_pure!(ir, R, V, V) cmpMaskB;
    }
}

alias cmpMaskB!(Cond.eq) equalMaskB;
alias cmpMaskB!(Cond.ne) notEqualMaskB; /// Ditto
alias cmpMaskB!(Cond.gt) greaterMaskB; /// Ditto
alias cmpMaskB!(Cond.ge) greaterOrEqualMaskB; /// Ditto

version (LDC)
version(mir_ion_test) unittest
{
    __vector(ubyte[8]) vec;
    __vector(ubyte[8]) vec23 = 23;
    vec.array[4] = 23;
    auto b = equalMaskB!(__vector(ubyte[8]))(vec, vec23);
    assert(b == 16);
}
