Hardware
========

Writing code for DCompute kernels is a bit different from regular CPU programming.

Most noticable is that you write the kernel as the body of a for loop that is then
vectorised and run in parallel by the `device`. As a consequence of this, there are
no sequencing guaruntees and branching is done as vector mask operations. This
includes `while` style loops, they will continue until every lane of the vector has
completed the loop.

Virtual function and function pointers are infeasable and therefore not supported,
this includes classes and delegates. Alias template parameters still work.

Due to the large number of concurrent threads, it is very easy to end up with a
data race, not help by the fact that any synchronisation (fences, atomics) must
be done manually. Fences and atomics can be quite expensive.

CPUs
----
Caches are present and reasonable in size. Vectors are relatively short. Branch
prediction is good.

GPUs
----

Caches may be present but are much smaller relative to the number of threads.
Vectors are generally wider than CPUs. Branch prediction is absent. Top level
dcache is small, you really dont want to spill your stack. Texture fetch means
you can load from nearby in 2D or 3D efficiently.

FPGAs
-----

Instructions are in hardware, each and every one of them counts: shrinking your
instruction count can increase your vector width as vector width is determined
by the available datapaths. Execution speed is determined by dataflow.
Timing is very important. You tell a CPU what to do, while you tell an FPGA what to be

