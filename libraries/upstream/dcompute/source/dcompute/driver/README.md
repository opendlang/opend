dcompute.driver
===============

Contains the abstracted driver interface for dcompute. It contains a delegation 
layer to the OpenCL (`dcompute.driver.ocl`) and CUDA (`dcompute.driver.cuda`)
drivers, code to load the appropriate system drivers and "get up and running" in a
platform agnoasic manner. Unless you're doing something that absolutely needs 
specific driver functionality then you should use this API rather than the 
individual compute APIs.

The API objects and their equivalets in OpenCL and CUDA are listed in the table 
below.

| Dcompute | CUDA        | OpenCL           |
| -------- | ----        | ------           |
| Platform | N/A\*       | cl_platform_id   |
| Device   | CUdevice    | cl_device_id     |
| Context  | CUcontext   | cl_context       |
| Queue    | CUstream    | cl_command_queue |
| Memory   | CUdeviceptr | cl_mem \*\*      |
| Module   | CUmodule    | cl_program       |
| Kernel   | CUfunction  | cl_kernel        |
| Event    | cudaEvent_t | cl_event         |

In addition there are a few Allocator types that allocate device local and shared 
virtual memory.

\* We make CUDA a platform of its own.

\*\* includes buffers, images and pipes.


Platform
--------

Performs the loading of the driver and handles any global initialisation required (e.g. `cuInit(0)`). Gives access to its devices.


Device
------

Can query them for information. You create `Context`s from them.


Context
-------

Create `Queue`s, `Memory` objects, `Module`s from these. By default this stores a
single `Module` along with it, created for all devices that are part of this 
context.


Queue
-----

Submit `Kernel` invocations and `Memory` transfers/maps (returning `Event`s),
 set `Device` affinity.


Kernel
------

Extracted from `Module`s. You can choose to not use these directly if you wish and
let this library do all the API bashing for you striaght from the module.
However you can extract these from `Module`s if you wish to avoid the re-extraction 
costs.


Event
-----

Returned as a result of enqueuing something. You can set callback on these, or wait 
on them. Useful for synchronisation

