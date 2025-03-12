Driver
======

Now that you've successfully written your kernel, how do you execute it?
That's the job of the driver.

The driver (`dcompute.driver`) manages the interactions with the compute APIs
(OpenCL and CUDA). This doesn't stop you interacting with them directly, it
just provides you with a consistent and (as much as is possible) a boiler-plate 
free interface.

API objects
-----------

There are a number of driver API objects that wrap the underlying compute API 
objects. They are summarised briefly below. More in depth information is available
in the corresponding subsection of this chapter.

**Platform:** Represents one implementation of a compute API. You can query object for the
devices that are available though it.

**Device:** Represents a unit of execution (e.g. a GPU). Group devices together to form a
context. You can query a large number of properties about performance characteristics
and available memory.

**Context:** A key API object. You create queues, buffers/images, samplers and programs from it.

**Memory:** Represents a region of memory. An abstract base class of buffers & images.

**Buffers:** Represents a 1,2 or 3D (possibly strided) linear view of memory.

**Images:**  Represents a 1,2 or 3D view of memory whose layout is determined by the format of the
image (number and datatype of the channels).

**Programs:** Represents a hunk of code for a context. You can create Kernels from a linked 
program (i.e. all external dependencies resolved).

**Queue:** Represents a list of work (data transfers & kernel launches) and the graph of their
dependencies.

**Kernel:** Represents a callable function from a Program and associated function parameters.
Submit kernels with supplied parameters to a queue to execute them on the queue's 
context's devices.

**Event:** Represents a future return value from executing an asynchronous operation, such 
as a data transfer or kernel launch.
