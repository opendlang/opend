// DerelictCL - a Derelict based dynamic binding for OpenCL
// written in the D programming language
//
// Copyright: MeinMein 2013-2014.
// License:   Boost License 1.0
//            (See accompanying file LICENSE_1_0.txt or copy at
//             http://www.boost.org/LICENSE_1_0.txt)
// Authors:   Gerbrand Kamphuis (meinmein.com),
//            Marvin Meeng (meinmein.com).
module derelict.opencl.functions;

private
{
    import derelict.opencl.types;
}

extern(System)
{
    // OpenCL 1.0
    alias @nogc nothrow cl_int function(cl_uint, cl_platform_id*, cl_uint*) da_clGetPlatformIDs;
    alias @nogc nothrow cl_int function(cl_platform_id, cl_platform_info, size_t, void*, size_t*) da_clGetPlatformInfo;
    alias @nogc nothrow cl_int function(cl_platform_id, cl_device_type, cl_uint, cl_device_id*, cl_uint*) da_clGetDeviceIDs;
    alias @nogc nothrow cl_int function(cl_device_id, cl_device_info, size_t, void*, size_t*) da_clGetDeviceInfo;
    alias @nogc nothrow cl_context function(const(cl_context_properties*), cl_uint, const(cl_device_id*), void function(const(char*),  const(void*),  size_t,  void*), void*, cl_int*) da_clCreateContext;
    alias @nogc nothrow cl_context function(const(cl_context_properties*), cl_device_type, void function(const(char*),  const(void*),  size_t,  void*), void*, cl_int*) da_clCreateContextFromType;
    alias @nogc nothrow cl_int function(cl_context) da_clRetainContext;
    alias @nogc nothrow cl_int function(cl_context) da_clReleaseContext;
    alias @nogc nothrow cl_int function(cl_context, cl_context_info, size_t, void*, size_t*) da_clGetContextInfo;
    alias @nogc nothrow cl_command_queue function(cl_context, cl_device_id, cl_command_queue_properties, cl_int*) da_clCreateCommandQueue;
    alias @nogc nothrow cl_int function(cl_command_queue) da_clRetainCommandQueue;
    alias @nogc nothrow cl_int function(cl_command_queue) da_clReleaseCommandQueue;
    alias @nogc nothrow cl_int function(cl_command_queue, cl_command_queue_info, size_t, void*, size_t*) da_clGetCommandQueueInfo;
    alias @nogc nothrow cl_mem function(cl_context, cl_mem_flags, size_t, void*, cl_int*) da_clCreateBuffer;
    alias @nogc nothrow cl_int function(cl_mem) da_clRetainMemObject;
    alias @nogc nothrow cl_int function(cl_mem) da_clReleaseMemObject;
    alias @nogc nothrow cl_int function(cl_context, cl_mem_flags, cl_mem_object_type, cl_uint, cl_image_format*, cl_uint*) da_clGetSupportedImageFormats;
    alias @nogc nothrow cl_int function(cl_mem, cl_mem_info, size_t, void*, size_t*) da_clGetMemObjectInfo;
    alias @nogc nothrow cl_int function(cl_mem, cl_image_info, size_t, void*, size_t*) da_clGetImageInfo;
    alias @nogc nothrow cl_sampler function(cl_context, cl_bool, cl_addressing_mode, cl_filter_mode, cl_int*) da_clCreateSampler;
    alias @nogc nothrow cl_int function(cl_sampler) da_clRetainSampler;
    alias @nogc nothrow cl_int function(cl_sampler) da_clReleaseSampler;
    alias @nogc nothrow cl_int function(cl_sampler, cl_sampler_info, size_t, void*, size_t*) da_clGetSamplerInfo;
    alias @nogc nothrow cl_program function(cl_context, cl_uint, const(char*)*, const(size_t*), cl_int*) da_clCreateProgramWithSource;
    alias @nogc nothrow cl_program function(cl_context, cl_uint, const(cl_device_id*), const(size_t*), const(ubyte*)*, cl_int*, cl_int*) da_clCreateProgramWithBinary;
    alias @nogc nothrow cl_program function(cl_context, cl_uint, const(cl_device_id*), const(char*), cl_int*) da_clCreateProgramWithBuiltInKernels;
    alias @nogc nothrow cl_int function(cl_program) da_clRetainProgram;
    alias @nogc nothrow cl_int function(cl_program) da_clReleaseProgram;
    alias @nogc nothrow cl_int function(cl_program, cl_uint, const(cl_device_id*), const(char*), void function(cl_program, void*), void*) da_clBuildProgram;
    alias @nogc nothrow cl_int function(cl_program, cl_program_info, size_t, void*, size_t*) da_clGetProgramInfo;
    alias @nogc nothrow cl_int function(cl_program, cl_device_id, cl_program_build_info, size_t, void*, size_t*) da_clGetProgramBuildInfo;
    alias @nogc nothrow cl_kernel function(cl_program, const(char*), cl_int*) da_clCreateKernel;
    alias @nogc nothrow cl_int function(cl_program, cl_uint, cl_kernel*, cl_uint*) da_clCreateKernelsInProgram;
    alias @nogc nothrow cl_int function(cl_kernel) da_clRetainKernel;
    alias @nogc nothrow cl_int function(cl_kernel) da_clReleaseKernel;
    alias @nogc nothrow cl_int function(cl_kernel, cl_uint, size_t, const(void*)) da_clSetKernelArg;
    alias @nogc nothrow cl_int function(cl_kernel, cl_kernel_info, size_t, void*, size_t*) da_clGetKernelInfo;
    alias @nogc nothrow cl_int function(cl_kernel, cl_uint, cl_kernel_arg_info, size_t, void*, size_t*) da_clGetKernelArgInfo;
    alias @nogc nothrow cl_int function(cl_kernel, cl_device_id, cl_kernel_work_group_info, size_t, void*, size_t*) da_clGetKernelWorkGroupInfo;
    alias @nogc nothrow cl_int function(cl_uint, const(cl_event*)) da_clWaitForEvents;
    alias @nogc nothrow cl_int function(cl_event, cl_event_info, size_t, void*, size_t*) da_clGetEventInfo;
    alias @nogc nothrow cl_int function(cl_event) da_clRetainEvent;
    alias @nogc nothrow cl_int function(cl_event) da_clReleaseEvent;
    alias @nogc nothrow cl_int function(cl_event, cl_profiling_info, size_t, void*, size_t*) da_clGetEventProfilingInfo;
    alias @nogc nothrow cl_int function(cl_command_queue) da_clFlush;
    alias @nogc nothrow cl_int function(cl_command_queue) da_clFinish;
    alias @nogc nothrow cl_int function(cl_command_queue, cl_mem, cl_bool, size_t, size_t, void*, cl_uint, const(cl_event*), cl_event*) da_clEnqueueReadBuffer;
    alias @nogc nothrow cl_int function(cl_command_queue, cl_mem, cl_bool, size_t, size_t, const(void*), cl_uint, const(cl_event*), cl_event*) da_clEnqueueWriteBuffer;
    alias @nogc nothrow cl_int function(cl_command_queue, cl_mem, cl_mem, size_t, size_t, size_t, cl_uint, const(cl_event*), cl_event*) da_clEnqueueCopyBuffer;
    alias @nogc nothrow cl_int function(cl_command_queue, cl_mem, cl_bool, const(size_t*), const(size_t*), size_t, size_t, void*, cl_uint, const(cl_event*), cl_event*) da_clEnqueueReadImage;
    alias @nogc nothrow cl_int function(cl_command_queue, cl_mem, cl_bool, const(size_t*), const(size_t*), size_t, size_t, const(void*), cl_uint, const(cl_event*), cl_event*) da_clEnqueueWriteImage;
    alias @nogc nothrow cl_int function(cl_command_queue, cl_mem, cl_mem, const(size_t*), const(size_t*), const(size_t*), cl_uint, const(cl_event*), cl_event*) da_clEnqueueCopyImage;
    alias @nogc nothrow cl_int function(cl_command_queue, cl_mem, cl_mem, const(size_t*), const(size_t*), size_t, cl_uint, const(cl_event*), cl_event*) da_clEnqueueCopyImageToBuffer;
    alias @nogc nothrow cl_int function(cl_command_queue, cl_mem, cl_mem, size_t, const(size_t*), const(size_t*), cl_uint, const(cl_event*), cl_event*) da_clEnqueueCopyBufferToImage;
    alias @nogc nothrow void* function(cl_command_queue, cl_mem, cl_bool, cl_map_flags, size_t, size_t, cl_uint, const(cl_event*), cl_event*, cl_int*) da_clEnqueueMapBuffer;
    alias @nogc nothrow void* function(cl_command_queue, cl_mem, cl_bool, cl_map_flags, const(size_t*), const(size_t*), size_t*, size_t*, cl_uint, const(cl_event*), cl_event*, cl_int*) da_clEnqueueMapImage;
    alias @nogc nothrow cl_int function(cl_command_queue, cl_mem, void*, cl_uint, const(cl_event*), cl_event*) da_clEnqueueUnmapMemObject;
    alias @nogc nothrow cl_int function(cl_command_queue, cl_kernel, cl_uint, const(size_t*), const(size_t*), const(size_t*), cl_uint, const(cl_event*), cl_event*) da_clEnqueueNDRangeKernel;
    alias @nogc nothrow cl_int function(cl_command_queue, cl_kernel, cl_uint, const(cl_event*), cl_event*) da_clEnqueueTask;
    alias @nogc nothrow cl_int function(cl_command_queue, void function(void*), void*, size_t, cl_uint, const(cl_mem*), const(void*)*, cl_uint, const(cl_event*), cl_event*) da_clEnqueueNativeKernel;
    // OpenCL 1.0 Deprecated in 1.1
    alias @nogc nothrow cl_int function(cl_command_queue, cl_command_queue_properties, cl_bool, cl_command_queue_properties*) da_clSetCommandQueueProperty;
    // OpenCL 1.1
    alias @nogc nothrow cl_mem function(cl_mem, cl_mem_flags, cl_buffer_create_type, const(void*), cl_int*) da_clCreateSubBuffer;
    alias @nogc nothrow cl_int function(cl_mem, void function(cl_mem, void*), void*) da_clSetMemObjectDestructorCallback;
    alias @nogc nothrow cl_event function(cl_context, cl_int*) da_clCreateUserEvent;
    alias @nogc nothrow cl_int function(cl_event, cl_int) da_clSetUserEventStatus;
    alias @nogc nothrow cl_int function( cl_event, cl_int, void function(cl_event,  cl_int,  void*), void*) da_clSetEventCallback;
    alias @nogc nothrow cl_int function(cl_command_queue, cl_mem, cl_bool, const(size_t*), const(size_t*), const(size_t*), size_t, size_t, size_t, size_t, void*, cl_uint, const(cl_event*), cl_event*) da_clEnqueueReadBufferRect;
    alias @nogc nothrow cl_int function(cl_command_queue, cl_mem, cl_bool, const(size_t*), const(size_t*), const(size_t*), size_t, size_t, size_t, size_t, const(void*), cl_uint, const(cl_event*), cl_event*) da_clEnqueueWriteBufferRect;
    alias @nogc nothrow cl_int function(cl_command_queue, cl_mem, cl_mem, const(size_t*), const(size_t*), const(size_t*), size_t, size_t, size_t, size_t, cl_uint, const(cl_event*), cl_event*) da_clEnqueueCopyBufferRect;
    // OpenCL 1.1 Deprecated in 1.2
    alias @nogc nothrow cl_mem function(cl_context, cl_mem_flags, const(cl_image_format*), size_t, size_t, size_t, void*, cl_int*) da_clCreateImage2D;
    alias @nogc nothrow cl_mem function(cl_context, cl_mem_flags, const(cl_image_format*), size_t, size_t, size_t, size_t, size_t, void*, cl_int*) da_clCreateImage3D;
    alias @nogc nothrow cl_int function(cl_command_queue, cl_event*) da_clEnqueueMarker;
    alias @nogc nothrow cl_int function(cl_command_queue, cl_uint, const(cl_event*)) da_clEnqueueWaitForEvents;
    alias @nogc nothrow cl_int function(cl_command_queue) da_clEnqueueBarrier;
    alias @nogc nothrow cl_int function() da_clUnloadCompiler;
    alias @nogc nothrow void* function(const(char*)) da_clGetExtensionFunctionAddress;
    // OpenCL 1.2
    alias @nogc nothrow cl_int function(cl_device_id, const(cl_device_partition_property*), cl_uint, cl_device_id*, cl_uint*) da_clCreateSubDevices;
    alias @nogc nothrow cl_int function(cl_device_id) da_clRetainDevice;
    alias @nogc nothrow cl_int function(cl_device_id) da_clReleaseDevice;
    alias @nogc nothrow cl_mem function(cl_context, cl_mem_flags, const(cl_image_format*), const(cl_image_desc*), void*, cl_int*) da_clCreateImage;
    alias @nogc nothrow cl_int function(cl_program, cl_uint, const(cl_device_id*), const(char*), cl_uint, const(cl_program*), const(char*)*, void function(cl_program, void*), void*) da_clCompileProgram;
    alias @nogc nothrow cl_program function(cl_context, cl_uint, const(cl_device_id*), const(char*), cl_uint, const(cl_program*), void function(cl_program, void*), void*, cl_int* ) da_clLinkProgram;
    alias @nogc nothrow cl_int function(cl_platform_id) da_clUnloadPlatformCompiler;
    alias @nogc nothrow cl_int function(cl_command_queue, cl_mem, const(void*), size_t, size_t, size_t, cl_uint, const(cl_event*), cl_event*) da_clEnqueueFillBuffer;
    alias @nogc nothrow cl_int function(cl_command_queue, cl_mem, const(void*), const(size_t*), const(size_t*), cl_uint, const(cl_event*), cl_event*) da_clEnqueueFillImage;
    alias @nogc nothrow cl_int function(cl_command_queue, cl_uint, const(cl_mem*), cl_mem_migration_flags, cl_uint, const(cl_event*), cl_event*) da_clEnqueueMigrateMemObjects;
    alias @nogc nothrow cl_int function(cl_command_queue, cl_uint, const(cl_event*), cl_event*) da_clEnqueueMarkerWithWaitList;
    alias @nogc nothrow cl_int function(cl_command_queue, cl_uint, const(cl_event*), cl_event*) da_clEnqueueBarrierWithWaitList;
    alias @nogc nothrow void* function(cl_platform_id, const(char*)) da_clGetExtensionFunctionAddressForPlatform;
    // OpenCL 2.0
    alias @nogc nothrow cl_command_queue function(cl_context, cl_device_id, const cl_queue_properties *, cl_int*) da_clCreateCommandQueueWithProperties;
    alias @nogc nothrow cl_mem function(cl_context, cl_mem_flags, cl_uint, cl_uint, const cl_pipe_properties*, cl_int*) da_clCreatePipe;
    alias @nogc nothrow cl_int function(cl_mem, cl_pipe_info, size_t, void*, size_t*) da_clGetPipeInfo;
    alias @nogc nothrow void* function(cl_context, cl_svm_mem_flags, size_t, cl_uint) da_clSVMAlloc;
    alias @nogc nothrow void function(cl_context, void*) da_clSVMFree;
    alias @nogc nothrow cl_sampler function(cl_context, const cl_sampler_properties*, cl_int*) da_clCreateSamplerWithProperties;
    alias @nogc nothrow cl_int function(cl_kernel, cl_uint, void*) da_clSetKernelArgSVMPointer;
    alias @nogc nothrow cl_int function(cl_kernel, cl_kernel_exec_info, size_t, const void *) da_clSetKernelExecInfo;
    alias @nogc nothrow cl_int function(cl_command_queue, cl_uint, void**, void function(cl_command_queue, cl_uint, void**, void*), void*, cl_uint, const cl_event*, cl_event*) da_clEnqueueSVMFree;
    alias @nogc nothrow cl_int function(cl_command_queue, cl_bool, void*, const void*, size_t, cl_uint, const cl_event*, cl_event*) da_clEnqueueSVMMemcpy;
	alias @nogc nothrow cl_int function(cl_command_queue,void*, const void*, size_t,size_t, cl_uint, const cl_event*, cl_event*) da_clEnqueueSVMMemFill;
    alias @nogc nothrow cl_int function(cl_command_queue, cl_bool, cl_map_flags, void*, size_t, cl_uint, const cl_event*, cl_event*) da_clEnqueueSVMMap;
    alias @nogc nothrow cl_int function(cl_command_queue, void *, cl_uint,const cl_event*, cl_event*) da_clEnqueueSVMUnmap;
    // OpenCL 2.1
    alias @nogc nothrow cl_int function(cl_context, cl_device_id, cl_command_queue) da_clSetDefaultDeviceCommandQueue;
    alias @nogc nothrow cl_int function(cl_device_id, cl_ulong*, cl_ulong*) da_clGetDeviceAndHostTimer;
    alias @nogc nothrow cl_int function(cl_device_id, cl_ulong*) da_clGetHostTimer;
    alias @nogc nothrow cl_program function(cl_context, const void*, size_t, cl_int*) da_clCreateProgramWithIL;
    alias @nogc nothrow cl_kernel function(cl_kernel, cl_int*) da_clCloneKernel;
    alias @nogc nothrow cl_int function(cl_kernel, cl_device_id, cl_kernel_sub_group_info, size_t, const void*, size_t, void*, size_t*) da_clGetKernelSubGroupInfo;
    alias @nogc nothrow cl_int function(cl_command_queue, cl_uint, const void**, const size_t*, cl_mem_migration_flags, cl_uint, const cl_event*, cl_event*) da_clEnqueueSVMMigrateMem;
    alias @nogc nothrow cl_int function(cl_program, void function(cl_program, void*), void*) da_clSetProgramReleaseCallback;
    alias @nogc nothrow cl_int function(cl_program, cl_uint, size_t, const void*) da_clSetProgramSpecializationConstant;
}
struct OpenCLFunc
{
    int added, dep, removed;
    this(int _added, int _dep = 0, int _rem = 0)
    {
        added   = _added;
        dep     = _dep;
        removed = _rem;
    }
}
__gshared
{
    @OpenCLFunc(10)
    {
    // OpenCL 1.0
        da_clGetPlatformIDs clGetPlatformIDs;
        da_clGetPlatformInfo clGetPlatformInfo;
        da_clGetDeviceIDs clGetDeviceIDs;
        da_clGetDeviceInfo clGetDeviceInfo;
        da_clCreateContext clCreateContext;
        da_clCreateContextFromType clCreateContextFromType;
        da_clRetainContext clRetainContext;
        da_clReleaseContext clReleaseContext;
        da_clGetContextInfo clGetContextInfo;
        //da_clCreateCommandQueue clCreateCommandQueue; // removed in 2.0
        da_clRetainCommandQueue clRetainCommandQueue;
        da_clReleaseCommandQueue clReleaseCommandQueue;
        da_clGetCommandQueueInfo clGetCommandQueueInfo;
        da_clCreateBuffer clCreateBuffer;
        da_clRetainMemObject clRetainMemObject;
        da_clReleaseMemObject clReleaseMemObject;
        da_clGetSupportedImageFormats clGetSupportedImageFormats;
        da_clGetMemObjectInfo clGetMemObjectInfo;
        da_clGetImageInfo clGetImageInfo;
        //da_clCreateSampler clCreateSampler;
        da_clRetainSampler clRetainSampler;
        da_clReleaseSampler clReleaseSampler;
        da_clGetSamplerInfo clGetSamplerInfo;
        da_clCreateProgramWithSource clCreateProgramWithSource;
        da_clCreateProgramWithBinary clCreateProgramWithBinary;
        da_clRetainProgram clRetainProgram;
        da_clReleaseProgram clReleaseProgram;
        da_clBuildProgram clBuildProgram;
        da_clGetProgramInfo clGetProgramInfo;
        da_clGetProgramBuildInfo clGetProgramBuildInfo;
        da_clCreateKernel clCreateKernel;
        da_clCreateKernelsInProgram clCreateKernelsInProgram;
        da_clRetainKernel clRetainKernel;
        da_clReleaseKernel clReleaseKernel;
        da_clSetKernelArg clSetKernelArg;
        da_clGetKernelInfo clGetKernelInfo;
        da_clGetKernelWorkGroupInfo clGetKernelWorkGroupInfo;
        da_clWaitForEvents clWaitForEvents;
        da_clGetEventInfo clGetEventInfo;
        da_clRetainEvent clRetainEvent;
        da_clReleaseEvent clReleaseEvent;
        da_clGetEventProfilingInfo clGetEventProfilingInfo;
        da_clFlush clFlush;
        da_clFinish clFinish;
        da_clEnqueueReadBuffer clEnqueueReadBuffer;
        da_clEnqueueWriteBuffer clEnqueueWriteBuffer;
        da_clEnqueueCopyBuffer clEnqueueCopyBuffer;
        da_clEnqueueReadImage clEnqueueReadImage;
        da_clEnqueueWriteImage clEnqueueWriteImage;
        da_clEnqueueCopyImage clEnqueueCopyImage;
        da_clEnqueueCopyImageToBuffer clEnqueueCopyImageToBuffer;
        da_clEnqueueCopyBufferToImage clEnqueueCopyBufferToImage;
        da_clEnqueueMapBuffer clEnqueueMapBuffer;
        da_clEnqueueMapImage clEnqueueMapImage;
        da_clEnqueueUnmapMemObject clEnqueueUnmapMemObject;
        da_clEnqueueNDRangeKernel clEnqueueNDRangeKernel;
        //da_clEnqueueTask clEnqueueTask;
        da_clEnqueueNativeKernel clEnqueueNativeKernel;
    }
    // OpenCL 1.0 Deprecated in 1.1
    @OpenCLFunc(10,11) da_clSetCommandQueueProperty clSetCommandQueueProperty;
    
    // OpenCL 1.0 Removed in 2.0
    @OpenCLFunc(10,20)
    {
        // Replaced by their .*WithProperties counterparts
        da_clCreateCommandQueue clCreateCommandQueue;
        da_clCreateSampler clCreateSampler;
        
        da_clEnqueueTask clEnqueueTask;
    }
    
    @OpenCLFunc(11)
    {
    // OpenCL 1.1
        da_clCreateSubBuffer clCreateSubBuffer;
        da_clSetMemObjectDestructorCallback clSetMemObjectDestructorCallback;
        da_clCreateUserEvent clCreateUserEvent;
        da_clSetUserEventStatus clSetUserEventStatus;
        da_clSetEventCallback clSetEventCallback;
        da_clEnqueueReadBufferRect clEnqueueReadBufferRect;
        da_clEnqueueWriteBufferRect clEnqueueWriteBufferRect;
        da_clEnqueueCopyBufferRect clEnqueueCopyBufferRect;
    }
    
    @OpenCLFunc(11,12)
    {
        // OpenCL 1.1 Deprecated in 1.2
        da_clCreateImage2D clCreateImage2D;
        da_clCreateImage3D clCreateImage3D;
        da_clEnqueueMarker clEnqueueMarker;
        da_clEnqueueWaitForEvents clEnqueueWaitForEvents;
        da_clEnqueueBarrier clEnqueueBarrier;
        da_clUnloadCompiler clUnloadCompiler;
        da_clGetExtensionFunctionAddress clGetExtensionFunctionAddress;
    }
    
    @OpenCLFunc(12)
    {
    // OpenCL 1.2
        da_clCreateSubDevices clCreateSubDevices;
        da_clRetainDevice clRetainDevice;
        da_clReleaseDevice clReleaseDevice;
        da_clCreateImage clCreateImage;
        da_clCreateProgramWithBuiltInKernels clCreateProgramWithBuiltInKernels;
        da_clCompileProgram clCompileProgram;
        da_clLinkProgram clLinkProgram;
        da_clUnloadPlatformCompiler clUnloadPlatformCompiler;
        da_clGetKernelArgInfo clGetKernelArgInfo;
        da_clEnqueueFillBuffer clEnqueueFillBuffer;
        da_clEnqueueFillImage clEnqueueFillImage;
        da_clEnqueueMigrateMemObjects clEnqueueMigrateMemObjects;
        da_clEnqueueMarkerWithWaitList clEnqueueMarkerWithWaitList;
        da_clEnqueueBarrierWithWaitList clEnqueueBarrierWithWaitList;
        da_clGetExtensionFunctionAddressForPlatform clGetExtensionFunctionAddressForPlatform;
    }
    
    @OpenCLFunc(20)
    {
        da_clCreateCommandQueueWithProperties clCreateCommandQueueWithProperties;
        da_clCreatePipe clCreatePipe;
        da_clGetPipeInfo clGetPipeInfo;
        da_clSVMAlloc clSVMAlloc;
        da_clSVMFree clSVMFree;
        da_clCreateSamplerWithProperties clCreateSamplerWithProperties;
        da_clSetKernelArgSVMPointer clSetKernelArgSVMPointer;
        da_clSetKernelExecInfo clSetKernelExecInfo;
        da_clEnqueueSVMFree clEnqueueSVMFree;
        da_clEnqueueSVMMemcpy clEnqueueSVMMemcpy;
        da_clEnqueueSVMMemFill clEnqueueSVMMemFill;
        da_clEnqueueSVMMap clEnqueueSVMMap;
        da_clEnqueueSVMUnmap clEnqueueSVMUnmap;
    }
    
    @OpenCLFunc(21)
    {
        da_clSetDefaultDeviceCommandQueue clSetDefaultDeviceCommandQueue;
        da_clGetDeviceAndHostTimer clGetDeviceAndHostTimer; // actually get timestamps
        da_clGetHostTimer clGetHostTimer; // ditto
        da_clCreateProgramWithIL clCreateProgramWithIL;
        da_clCloneKernel clCloneKernel;
        da_clGetKernelSubGroupInfo clGetKernelSubGroupInfo;
        da_clEnqueueSVMMigrateMem clEnqueueSVMMigrateMem;
    }
    @OpenCLFunc(22)
    {
        da_clSetProgramReleaseCallback clSetProgramReleaseCallback;
        da_clSetProgramSpecializationConstant clSetProgramSpecializationConstant;
    }
    
}
