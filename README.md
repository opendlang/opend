DerelictOpenCL
==============

A dynamic binding to [OpenCL](http://www.khronos.org/opencl/) for the D Programming Language.

For information on how to build DerelictCL and link it with your programs, please see the post [Using Derelict][6] at The One With D.

For information on how to load the OpenCL library via DerelictCL, see the page [DerelictUtil for Users](https://github.com/DerelictOrg/DerelictUtil/wiki/DerelictUtil-for-Users) at the DerelictUtil Wiki. In the meantime, here's some sample code.

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
