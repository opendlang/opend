module dcompute.driver.cuda.kernel;

import dcompute.driver.cuda;
struct Kernel(F) if (is(F==function)|| is(F==void))
{
    void* raw;
    
    static struct Attributes
    {
        @(0) int maxThreadsPerBlock;
        // in Bytes
        @(1) int sharedSize;
        @(2) int constSize;
        @(3) int localSize;
        
        @(4) int numRegs;
        @(5) int ptxVersion;
        @(6) int binaryVersion;
        @(7) int cacheModeCa;
    }

}
