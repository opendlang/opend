module dcompute.std;

version(LDC_DCompute) {}
else
{
    static assert(false, "Need to use a DCompute enabled compiler.");
}


public import dcompute.std.index;
