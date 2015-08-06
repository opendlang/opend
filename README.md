DerelictOpenCL
==============

A dynamic binding to [OpenCL](http://www.khronos.org/opencl/) for the D Programming Language.

Please see the pages [Building and Linking Derelict](http://derelictorg.github.io/compiling.html) and [Using Derelict](http://derelictorg.github.io/using.html), or information on how to build DerelictCL and load the OpenCL library at run time. In the meantime, here's some sample code.

```D
import derelict.opencl.cl;

void main() {
    // Load the OpenCL library.
    DerelictCL.load();

    // Query platforms and devices
    ...

    // Reload the OpenCL library.
    DerelictCL.reload(<chosen_version>);

    // Load OpenCL official extensions.
    DerelictCL.loadEXT(<chosen_platform>);

    // Now OpenCL functions can be called.
    ...
}
```
