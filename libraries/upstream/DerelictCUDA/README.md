DerelictCUDA
============

A dynamic binding to [CUDA][1] for the D Programming Language.

Only the Driver and Runtime API are provided for now.

Please see the pages [Building and Linking Derelict][2] and [Using Derelict][3], in the Derelict documentation, for information on how to build DerelictCUDA and load the CUDA library at run time. In the meantime, here's some sample code.

```D
import derelict.cuda;

void main() {

    DerelictCUDADriver.load();
    // Now CUDA Driver API functions can be called.

    // Alternatively:
    DerelictCUDARuntime.load();
    // Now CUDA Runtime API functions can be called. Driver and Runtime API are exclusive.
    ...
}
```

[1] http://www.nvidia.com/object/cuda_home_new.html
[2]: http://derelictorg.github.io/compiling.html
[3]: http://derelictorg.github.io/using.html