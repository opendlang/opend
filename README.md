DerelictCUDA
============

A dynamic binding to [CUDA](http://www.nvidia.com/object/cuda_home_new.html) for the D Programming Language.

Only the Driver API is provided for now.

For information on how to build DerelictCUDA and link it with your programs, please see the post [Using Derelict](http://dblog.aldacron.net/derelict-help/using-derelict/) at The One With D.

For information on how to load the CUDA library via DerelictCUDA, see the page [DerelictUtil for Users](https://github.com/DerelictOrg/DerelictUtil/wiki/DerelictUtil-for-Users) at the DerelictUtil Wiki. In the meantime, here's some sample code.

```D
import derelict.cuda.cuda;

void main() {
    // Load the CUDA library.
    DerelictCUDA.load();
    
    // Now CUDA Driver API functions can be called.
    ...
}
```
