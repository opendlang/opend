@compute(CompileFor.deviceOnly)
module dcompute.tests.dummykernels;
pragma(LDC_no_moduleinfo);

import ldc.dcompute;
import dcompute.std.index;

@kernel void saxpy(GlobalPointer!(float) res,
                   float alpha,GlobalPointer!(float) x,
                   GlobalPointer!(float) y, 
                   size_t N)
{
    auto i = GlobalIndex.x;
    if (i >= N) return;
    res[i] = alpha*x[i] + y[i];
}

alias aagf = AutoIndexed!(GlobalPointer!(float));

@kernel void auto_index_test(aagf a,
                             aagf b,
                             aagf c)
{
    a = b + c;
}
