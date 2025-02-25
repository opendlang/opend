@compute(CompileFor.hostAndDevice) module dcompute.std.index;

import ldc.dcompute;

private import ocl  = dcompute.std.opencl.index;
private import cuda = dcompute.std.cuda.index;

/*
 Index Terminology
 
 DCompute               CUDA                        OpenCL
 GlobalDimension.xyz    gridDim*blockDim            get_global_size()
 GlobalIndex.xyz        blockDim*blockIdx+threadIdx get_global_id()
 
 
 GroupDimension.xyz     gridDim                     get_num_groups()
 GroupIndex.xyz         blockIdx                    get_group_id()
 
 SharedDimension.xyz    blockDim                    get_local_size()
 SharedIndex.xyz        threadIdx                   get_local_id()
 
 GlobalIndex.linear     A nasty calcualion          get_global_linear_id()
 SharedIndex.linear     Ditto                       get_local_linear_id()
 
 Notes:
    *Index.{x,y,z} are bounded by *Dimension.{x,y,z}
 
    Use SharedIndex's to index Shared Memory and GlobalIndex's to index Global Memory
 
    A Group is the ratio of Global to Shared. GroupDimension is NOT the size of a single
    group, (thats SharedDimension) rather it is the number of groups along e.g 
    the x dimension. Similarly GroupIndex is how many units of the SharedDimension along
    a given dimension is.
 
    By default *Index.linear is the linearisation of 3D memory. Use *Index.linear!N where
    N is 1, 2 or 3 to use a linearisation of ND memory (for e.g. efficiency/documentation).
 */
pure: nothrow: @nogc:

struct GlobalDimension
{
    pragma(inline,true);
    @property static size_t x()()
    {
        if(__dcompute_reflect(ReflectTarget.OpenCL,0))
            return ocl.get_global_size(0);
        else if(__dcompute_reflect(ReflectTarget.CUDA,0))
            return cuda.ntid_x()*cuda.nctaid_x();
        else
            assert(0);
    }
    pragma(inline,true);
    @property static size_t y()()
    {
        if(__dcompute_reflect(ReflectTarget.OpenCL,0))
            return ocl.get_global_size(1);
        else if(__dcompute_reflect(ReflectTarget.CUDA,0))
            return cuda.ntid_y()*cuda.nctaid_y();
        else
            assert(0);
    }
    pragma(inline,true);
    @property static size_t z()()
    {
        if(__dcompute_reflect(ReflectTarget.OpenCL,0))
            return ocl.get_global_size(2);
        else if(__dcompute_reflect(ReflectTarget.CUDA,0))
            return cuda.ntid_z()*cuda.nctaid_z();
        else
            assert(0);
    }
}

struct GlobalIndex
{
    pragma(inline,true);
    @property static size_t x()()
    {
        if(__dcompute_reflect(ReflectTarget.OpenCL,0))
            return ocl.get_global_id(0);
        else if(__dcompute_reflect(ReflectTarget.CUDA,0))
            return cuda.ctaid_x()*cuda.ntid_x() + cuda.tid_x();
        else
            assert(0);
    }
    pragma(inline,true);
    @property static size_t y()()
    {
        if(__dcompute_reflect(ReflectTarget.OpenCL,0))
            return ocl.get_global_id(1);
        else if(__dcompute_reflect(ReflectTarget.CUDA,0))
            return cuda.ctaid_y()*cuda.ntid_y() + cuda.tid_y();
        else
            assert(0);
    }
    pragma(inline,true);
    @property static size_t z()()
    {
        if(__dcompute_reflect(ReflectTarget.OpenCL,0))
            return ocl.get_global_id(2);
        else if(__dcompute_reflect(ReflectTarget.CUDA,0))
            return cuda.ctaid_z()*cuda.ntid_z() + cuda.tid_z();
        else
            assert(0);
    }
    pragma(inline,true);
    @property static size_t linearImpl(int dim = 3)()
    if(dim >= 1 && dim <= 3)
    {
        static if (dim == 3)
            return  (z * GlobalDimension.y * GlobalDimension.x) +
                    (y * GlobalDimension.x) + x;
        else static if (dim == 2)
            return (y * GlobalDimension.x) + x;
        else
            return x;
    }
    pragma(inline,true);
    @property static size_t linear(int dim = 3)() if(dim >= 1 && dim <= 3)
    {
        //Foward to the intrinsic to help memoisation for the comsumer.
        if(__dcompute_reflect(ReflectTarget.OpenCL,200))
            return ocl.get_global_linear_id();
        else if(__dcompute_reflect(ReflectTarget.OpenCL,210))
            return ocl.get_global_linear_id();
        else if(__dcompute_reflect(ReflectTarget.OpenCL,220))
            return ocl.get_global_linear_id();
        else
            return linearImpl!dim;
    }
}

struct GroupDimension
{
    pragma(inline,true);
    @property static size_t x()()
    {
        if(__dcompute_reflect(ReflectTarget.OpenCL,0))
            return ocl.get_num_groups(0);
        else if(__dcompute_reflect(ReflectTarget.CUDA,0))
            return cuda.nctaid_x();
        else
            assert(0);
    }
    pragma(inline,true);
    @property static size_t y()()
    {
        if(__dcompute_reflect(ReflectTarget.OpenCL,0))
            return ocl.get_num_groups(1);
        else if(__dcompute_reflect(ReflectTarget.CUDA,0))
            return cuda.nctaid_y();
        else
            assert(0);
    }
    pragma(inline,true);
    @property static size_t z()()
    {
        if(__dcompute_reflect(ReflectTarget.OpenCL,0))
            return ocl.get_num_groups(2);
        else if(__dcompute_reflect(ReflectTarget.CUDA,0))
            return cuda.nctaid_z();
        else
            assert(0);
    }
}

struct GroupIndex
{
    pragma(inline,true);
    @property static size_t x()()
    {
        if(__dcompute_reflect(ReflectTarget.OpenCL,0))
            return ocl.get_group_id(0);
        else if(__dcompute_reflect(ReflectTarget.CUDA,0))
            return cuda.ctaid_x();
        else
            assert(0);
    }
    pragma(inline,true);
    @property static size_t y()()
    {
        if(__dcompute_reflect(ReflectTarget.OpenCL,0))
            return ocl.get_group_id(1);
        else if(__dcompute_reflect(ReflectTarget.CUDA,0))
            return cuda.ctaid_y();
        else
            assert(0);
    }
    pragma(inline,true);
    @property static size_t z()()
    {
        if(__dcompute_reflect(ReflectTarget.OpenCL,0))
            return ocl.get_group_id(2);
        else if(__dcompute_reflect(ReflectTarget.CUDA,0))
            return cuda.ctaid_z();
        else
            assert(0);
    }
}

struct SharedDimension
{
    pragma(inline,true);
    @property static size_t x()()
    {
        if(__dcompute_reflect(ReflectTarget.OpenCL,0))
            return ocl.get_local_size(0);
        else if(__dcompute_reflect(ReflectTarget.CUDA,0))
            return cuda.ntid_x();
        else
            assert(0);
    }
    pragma(inline,true);
    @property static size_t y()()
    {
        if(__dcompute_reflect(ReflectTarget.OpenCL,0))
            return ocl.get_local_size(1);
        else if(__dcompute_reflect(ReflectTarget.CUDA,0))
            return cuda.ntid_y();
        else
            assert(0);

    }
    pragma(inline,true);
    @property static size_t z()()
    {
        if(__dcompute_reflect(ReflectTarget.OpenCL,0))
            return ocl.get_local_size(2);
        else if(__dcompute_reflect(ReflectTarget.CUDA,0))
            return cuda.ntid_z();
        else
            assert(0);
    }
}

struct SharedIndex
{
    pragma(inline,true);
    @property static size_t x()()
    {
        if(__dcompute_reflect(ReflectTarget.OpenCL,0))
            return ocl.get_local_id(0);
        else if(__dcompute_reflect(ReflectTarget.CUDA,0))
            return cuda.tid_x();
        else
            assert(0);
    }
    pragma(inline,true);
    @property static size_t y()()
    {
        if(__dcompute_reflect(ReflectTarget.OpenCL,0))
            return ocl.get_local_id(1);
        else if(__dcompute_reflect(ReflectTarget.CUDA,0))
            return cuda.tid_y();
        else
            assert(0);
    }
    pragma(inline,true);
    @property static size_t z()()
    {
        if(__dcompute_reflect(ReflectTarget.OpenCL,0))
            return ocl.get_local_id(2);
        else if(__dcompute_reflect(ReflectTarget.CUDA,0))
            return cuda.tid_z();
        else
            assert(0);
    }
    pragma(inline,true);
    @property static size_t linearImpl(int dim = 3)()
    if(dim >= 1 && dim <= 3)
    {
        static if (dim == 3)
            return  (z * SharedDimension.y * SharedDimension.x) +
                    (y * SharedDimension.x) + x;
        else static if (dim == 2)
                return (y * SharedDimension.x) + x;
        else
            return x;

    }
    pragma(inline,true);
    @property static size_t linear(int dim = 3)() if(dim >= 1 && dim <= 3)
    {
        //Foward to the intrinsic to help memoisation for the comsumer.
        if(__dcompute_reflect(ReflectTarget.OpenCL,200))
            return ocl.get_local_linear_id();
        else if(__dcompute_reflect(ReflectTarget.OpenCL,210))
            return ocl.get_local_linear_id();
        else if(__dcompute_reflect(ReflectTarget.OpenCL,220))
            return ocl.get_local_linear_id();
        else
            return linearImpl!dim;
        
    }
}

private import std.traits;
struct AutoIndexed(T) //if (isInstanceOf(T,Pointer))
{
    T p = void;
    enum  n = TemplateArgsOf!(T)[0];
    alias U = TemplateArgsOf!(T)[1];
    static assert(n == AddrSpace.Global || n == AddrSpace.Shared);
    
    @property U index()
    {
        static if (n == AddrSpace.Global)
            return p[GlobalIndex.linear];
        else static if (n == AddrSpace.Shared)
            return p[SharedIndex.linear];

    }
    
    @property void index(U t)
    {
        static if (n == AddrSpace.Global)
            p[GlobalIndex.linear] = t;
        else static if (n == AddrSpace.Shared)
            p[SharedIndex.linear] = t;
    }
    @disable this();
    alias index this;
}
