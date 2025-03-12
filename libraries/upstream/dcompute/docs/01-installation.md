Installation
============

LDC
---

As mentioned previously DCompute requires the use of LDC as the D compiler.
All [recent releases of LDC](https://github.com/ldc-developers/ldc/releases)
have the NVPTX backend enabled for targetting NVidia hardware via CUDA.

DCompute
--------

If you are using dub (highly recommended) then all you need to do is add 
`"dcompute": "~>0.1.0"` to your dub.json or 
`dependency "dcompute" version="~>0.0.1"` to your dub.sdl 
dependencies and you should be good to go and can ignore the rest of this section.

If you are not using dub DCompute has a few of depenancies that you need to 
include:

* [derelict-cl](https://github.com/DerelictOrg/DerelictCL) for OpenCL bindings
* [derelict-cuda](https://github.com/DerelictOrg/DerelictCUDA) for CUDA bindings
* [derelict-util](https://github.com/DerelictOrg/DerelictUtil) shared library loading utilities used by the above

Drivers
-------

To utilise the hardware you need drivers that implement OpenCL 2.1 or higher or CUDA.
Please consult your hardware vendors website for drivers.

TODO: add a list.
