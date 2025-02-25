Index
=====

To do anything useful with DCompute a thread needs to know it's index, it's position.
If you take a look at `dcompute.std.index` you'll see there are quite a few to choose from.
Most of the indices are three dimensional and represent offsets in a "3D" view of memory.
Of course not all problems are 3D so the y and z values are not always useful.

If you come from OpenCL or CUDA the table below should help you familiarise yourself with the different indices available.

Index Terminology:

| DCompute           | CUDA                        | OpenCL
|--------------------|-----------------------------|--------
| GlobalDimension    | `gridDim*blockDim`            | get_global_size()
| GlobalIndex        | `blockDim*blockIdx+threadIdx` | get_global_id()
|                    |                             |
| GroupDimension     | gridDim                     | get_num_groups()
| GroupIndex         | blockIdx                    | get_group_id()
|                    |                             |
| SharedDimension    | blockDim                    | get_local_size()
| SharedIndex        | threadIdx                   | get_local_id()
|                    |                             |
| GlobalIndex.linear | A nasty calculation         | get_global_linear_id()
| SharedIndex.linear | Ditto                       | get_local_linear_id()

Note:
\*Index.{x,y,z} are bounded by \*Dimension.{x,y,z}

Use SharedIndex's to index Shared Memory and GlobalIndex's to index Global Memory

A Group is the ratio of Global to Shared. GroupDimension is NOT the size of a single
group, (thats SharedDimension) rather it is the number of groups along a given dimension.
Similarly GroupIndex is how many units of the SharedDimension along a given dimension.

Extending the previous example to add a constant to an array and assign it to another 
(we could have also used `GlobalIndex.linear`). We have:

```d
@compute(CompileFor.deviceOnly) module mykernels;
import ldc.attributes;
import ldc.dcomputetypes;
import dcompute.std.index;
alias gf = GlobalPointer!float;
@kernel void mykernel(gf a, gf b, float c)
{
auto i = GlobalIndex.x;
a[i] = b[i] + c;
}
```  

With the same command line as before.

Autoindex
---------

`AutoIndexed` is a type that automatically indexes a `GlobalPointer` or `SharedPointer` 
for making kernel lambda nicer to use.
