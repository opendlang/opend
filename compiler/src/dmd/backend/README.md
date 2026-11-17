Files in the Back End
=====================

:warning: When contributing to the backend, make sure you don't break DMC :warning:

The backend is shared with DMC, the DigitalMars C/C++ compiler.

To ensure compatibility, [check its source tree here](https://github.com/DigitalMars/Compiler/tree/master/dm/src/dmc).

Data Structures
---------------
* **aarray.d**        hash table
* **barray.d**        generic resizable array
* **dlist.d**         linked list
* **dvec.d**          simple bit vector
* **dt.d**            intermediate representation for static data
* **dtype.d**         backend type operations, including size, alignment, and parameter layout
* **el.d**            expression trees (intermediate representation)
* **symtab.d**        symbol table array

Optimisations
-------------

* **blockopt.d**      manage and simple optimizations on graphs of basic blocks
* **gdag.d**          Directed acyclic graphs and global optimizer common subexpressions
* **gflow.d**         global data flow analysis
* **global.d**        declarations for back end
* **glocal.d**        local optimizations
* **gloop.d**         global loop optimizations
* **go.d**            global optimizer main loop
* **goh.d**           global optimizer declarations
* **gother.d**        other global optimizations
* **gsroa.d**         SROA structured replacement of aggregate optimization
* **evalu8.d**        constant folding
* **divcoeff.d**      convert divisions to multiplications
* **inliner.d**       inline functions from optimized intermediate code

Debug Information
-----------------

* **cv4.d**           CodeView 4 symbolic debug info declarations
* **cv8.d**           CodeView 8 symbolic debug info generation
* **dcgcv.d**         CodeView 4 symbolic debug info generation
* **dwarf.d**         interface to DWARF generation
* **dwarf2.d**        DWARF specification declarations
* **dwarfdbginf.d**   generate DWARF debug info
* **dwarfeh.d**       DWARF Exception handling tables
* **ee.d**            DMC++ IDDE debugger expression evaluation
* **dvarstats.d**     track local-variable lifetimes and lexical scopes for debug information

Object File Generation
----------------------

* **melf.d**          declarations for ELF file format
* **elfobj.d**        generate ELF object files
* **machobj.d**       generate Mach-O object files
* **mach.d**          declarations for Mach-O object file format
* **cgobj.d**         generate OMF object files
* **mscoff.d**        declarations for the Microsoft COFF object file format
* **mscoffobj.d**     generate Microsoft COFF object files
* **obj.d**           interface to *obj.d files

Exception Handling
------------------

* **nteh.d**          Windows structured exception handling support
* **eh.d**            generate exception-handling tables for EH_DM and EH_WIN32
* **pdata.d**         generate Win64 .pdata and .xdata sections

Miscellaneous
-------------

* **backend.d**       internal header file for the backend
* **bcomplex.d**      our own complex number implementation
* **md5.d**           implementation of MD5 message digest
* **cc.d**            common definitions
* **cdef.d**          configuration
* **backconfig.d**    transfer configuration from front end to back end
* **compress.d**      identifier compression
* **debugprint.d**    pretty print data structures
* **disasm86.d**      disassemble 16-, 32-, and 64-bit x86 code
* **elem.d**          routines for manipulating expression-tree elements
* **filespec.d**      filename comparison and path-related routines
* **fp.d**            floating-point status, exception, and modulo helpers
* **iasm.d**          declarations for inline assembler
* **mem.d**           memory allocation and deallocation wrappers
* **ptrntab.d**       instruction tables for inline assembler
* **oper.d**          operators for expression tree
* **rtlsym.d**        compiler runtime function symbol identifiers
* **ty.d**            type masks
* **symbol.d**        symbols for the back end
* **type.d**          types for the back end
* **util2.d**         utility subroutines used only by DMD
* **var.d**           global variables

Code Generation
---------------

* **cg.d**            global variables for code generator
* **cg87.d**          x87 FPU code generation
* **cgcod.d**         main loop for code generator
* **cgcs.d**          compute common subexpressions for non-optimized code generation
* **cgcse.d**         manage temporaries used to save CSEs in
* **cgcv.d**          interface for CodeView symbol debug info generation
* **cgelem.d**        local optimizations of elem trees
* **cgen.d**          generate/manage linked list of code instructions
* **cgreg.d**         register allocator
* **cgsched.d**       instruction scheduler
* **cgxmm.d**         xmm specific code generation
* **cod1.d**          code gen
* **cod2.d**          code gen
* **cod3.d**          code gen
* **cod4.d**          code gen
* **cod5.d**          code gen
* **code.d**          define registers, register masks, and the CPU instruction linked list
* **codebuilder.d**   construct linked list of generated code
* **code_x86.d**      x86 specific declarations
* **dcode.d**         allocate and free code blocks
* **drtlsym.d**       compiler runtime function symbols
* **dout.d**           transition from intermediate representation to code generator
* **elpicpie.d**      generate expression-tree elements for fixed, PIC, and PIE code
* **xmm.d**           xmm opcodes
