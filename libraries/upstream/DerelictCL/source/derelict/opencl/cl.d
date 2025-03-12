// DerelictCL - a Derelict based dynamic binding for OpenCL
// written in the D programming language
//
// Copyright: MeinMein 2013-2014.
// License:   Boost License 1.0
//            (See accompanying file LICENSE_1_0.txt or copy at
//             http://www.boost.org/LICENSE_1_0.txt)
// Authors:   Gerbrand Kamphuis (meinmein.com),
//            Marvin Meeng (meinmein.com).
module derelict.opencl.cl;

public
{
    import derelict.util.exception;

    import derelict.opencl.types;
    import derelict.opencl.constants;
    import derelict.opencl.functions;

    import derelict.opencl.cl_ext;
    import derelict.opencl.cl_egl;
    import derelict.opencl.cl_gl;
    import derelict.opencl.cl_gl_ext;
    import derelict.opencl.cl_d3d10;
    import derelict.opencl.cl_d3d11;
    import derelict.opencl.cl_dx9_media_sharing;
}

private
{
    import std.algorithm;
    import std.conv;

    import derelict.util.loader;
    import derelict.util.system;

    static if(Derelict_OS_Windows)
    {
        enum libNames = "opencl.dll";
    }
    else static if(Derelict_OS_Mac)
    {
        enum libNames = "../Frameworks/OpenCL.framework/OpenCL, /Library/Frameworks/OpenCL.framework/OpenCL, /System/Library/Frameworks/OpenCL.framework/OpenCL";
    }
    else static if(Derelict_OS_Posix)
    {
        enum libNames = "libOpenCL.so.1,libOpenCL.so";
    }
    else
        static assert(0, "Need to implement OpenCL libNames for this operating system.");
}

class DerelictCLLoader : SharedLibLoader
{
    public
    {
        CLVersion loadedVersion() @property
        {
            return _loadedVersion;
        }

        CLVersion reload(CLVersion clVer)
        {
            // CLVersion depends on chosen platform & device.
            // Here we assume this is handled by the developer.

            // (Alternatively, a CLContext could be passed as argument,
            // and then the lowest found CLVersion in its devices could be used.)

            if(clVer <= CLVersion.CL10)
            {
                // OpenCL 1.0 Deprecated in 1.1
                bindFunc(cast(void**)&clSetCommandQueueProperty, "clSetCommandQueueProperty");
            }

            if(clVer >= CLVersion.CL11)
            {
                // OpenCL 1.1
                bindFunc(cast(void**)&clCreateSubBuffer, "clCreateSubBuffer");
                bindFunc(cast(void**)&clSetMemObjectDestructorCallback, "clSetMemObjectDestructorCallback");
                bindFunc(cast(void**)&clCreateUserEvent, "clCreateUserEvent");
                bindFunc(cast(void**)&clSetUserEventStatus, "clSetUserEventStatus");
                bindFunc(cast(void**)&clSetEventCallback, "clSetEventCallback");
                bindFunc(cast(void**)&clEnqueueReadBufferRect, "clEnqueueReadBufferRect");
                bindFunc(cast(void**)&clEnqueueWriteBufferRect, "clEnqueueWriteBufferRect");
                bindFunc(cast(void**)&clEnqueueCopyBufferRect, "clEnqueueCopyBufferRect");
            }

            if(clVer <= CLVersion.CL11)
            {
                // OpenCL 1.1 Deprecated in 1.2
                bindFunc(cast(void**)&clCreateImage2D, "clCreateImage2D");
                bindFunc(cast(void**)&clCreateImage3D, "clCreateImage3D");
                bindFunc(cast(void**)&clEnqueueMarker, "clEnqueueMarker");
                bindFunc(cast(void**)&clEnqueueWaitForEvents, "clEnqueueWaitForEvents");
                bindFunc(cast(void**)&clEnqueueBarrier, "clEnqueueBarrier");
                bindFunc(cast(void**)&clUnloadCompiler, "clUnloadCompiler");
                bindFunc(cast(void**)&clGetExtensionFunctionAddress, "clGetExtensionFunctionAddress");
            }

            if(clVer >= CLVersion.CL12)
            {
                // OpenCL 1.2
                bindFunc(cast(void**)&clCreateSubDevices, "clCreateSubDevices");
                bindFunc(cast(void**)&clRetainDevice, "clRetainDevice");
                bindFunc(cast(void**)&clReleaseDevice, "clReleaseDevice");
                bindFunc(cast(void**)&clCreateImage, "clCreateImage");
                bindFunc(cast(void**)&clCreateProgramWithBuiltInKernels, "clCreateProgramWithBuiltInKernels");
                bindFunc(cast(void**)&clCompileProgram, "clCompileProgram");
                bindFunc(cast(void**)&clLinkProgram, "clLinkProgram");
                bindFunc(cast(void**)&clUnloadPlatformCompiler, "clUnloadPlatformCompiler");
                bindFunc(cast(void**)&clGetKernelArgInfo, "clGetKernelArgInfo");
                bindFunc(cast(void**)&clEnqueueFillBuffer, "clEnqueueFillBuffer");
                bindFunc(cast(void**)&clEnqueueFillImage, "clEnqueueFillImage");
                bindFunc(cast(void**)&clEnqueueMigrateMemObjects, "clEnqueueMigrateMemObjects");
                bindFunc(cast(void**)&clEnqueueMarkerWithWaitList, "clEnqueueMarkerWithWaitList");
                bindFunc(cast(void**)&clEnqueueBarrierWithWaitList, "clEnqueueBarrierWithWaitList");
                bindFunc(cast(void**)&clGetExtensionFunctionAddressForPlatform, "clGetExtensionFunctionAddressForPlatform");
            }

			if(clVer >= CLVersion.CL20)
            {
                bindFunc(cast(void**)&clCreateCommandQueueWithProperties, "clCreateCommandQueueWithProperties");
                bindFunc(cast(void**)&clCreatePipe, "clCreatePipe");
                bindFunc(cast(void**)&clGetPipeInfo, "clGetPipeInfo");
                bindFunc(cast(void**)&clSVMAlloc, "clSVMAlloc");
                bindFunc(cast(void**)&clSVMFree, "clSVMFree");
                bindFunc(cast(void**)&clCreateSamplerWithProperties, "clCreateSamplerWithProperties");
                bindFunc(cast(void**)&clSetKernelArgSVMPointer, "clSetKernelArgSVMPointer");
                bindFunc(cast(void**)&clSetKernelExecInfo, "clSetKernelExecInfo");
                bindFunc(cast(void**)&clEnqueueSVMFree, "clEnqueueSVMFree");
                bindFunc(cast(void**)&clEnqueueSVMMemcpy, "clEnqueueSVMMemcpy");
                bindFunc(cast(void**)&clEnqueueSVMMemFill, "clEnqueueSVMMemFill");
                bindFunc(cast(void**)&clEnqueueSVMMap, "clEnqueueSVMMap");
                bindFunc(cast(void**)&clEnqueueSVMUnmap, "clEnqueueSVMUnmap");
            }

            if(clVer >= CLVersion.CL21)
            {
			    bindFunc(cast(void**)&clSetDefaultDeviceCommandQueue, "clSetDefaultDeviceCommandQueue");
			    bindFunc(cast(void**)&clGetDeviceAndHostTimer, "clGetDeviceAndHostTimer");
			    bindFunc(cast(void**)&clGetHostTimer, "clGetHostTimer");
			    bindFunc(cast(void**)&clCreateProgramWithIL, "clCreateProgramWithIL");
			    bindFunc(cast(void**)&clCloneKernel, "clCloneKernel");
			    bindFunc(cast(void**)&clGetKernelSubGroupInfo, "clGetKernelSubGroupInfo");
            }

            if(clVer >= CLVersion.CL22)
            {
                bindFunc(cast(void**)&clSetProgramReleaseCallback, "clSetProgramReleaseCallback");
                bindFunc(cast(void**)&clSetProgramSpecializationConstant, "clSetProgramSpecializationConstant");
            }

            derelict.opencl.cl_ext.reload(&bindFunc, clVer);
            derelict.opencl.cl_gl_ext.reload(&bindFunc, clVer);
            derelict.opencl.cl_gl.reload(&bindFunc, clVer);
            
            if(Derelict_OS_Windows)
            {
                derelict.opencl.cl_d3d10.reload(&bindFunc, clVer);
                derelict.opencl.cl_d3d11.reload(&bindFunc, clVer);
                derelict.opencl.cl_dx9_media_sharing.reload(&bindFunc, clVer);
            }

            _loadedVersion = clVer;
            return clVer;
        }

        // Load official extensions
        // In OpenCL 1.2 this is cl_platform dependent
        void loadEXT(cl_platform_id platform = null)
        {
            if(_loadedVersion >= CLVersion.CL12 && platform is null)
                throw new DerelictException(`OpenCL 1.2 requires a cl_platform_id to load official extension functions`);

            derelict.opencl.cl_ext.loadEXT(_loadedVersion, platform);
            derelict.opencl.cl_egl.loadEXT(_loadedVersion, platform);
            derelict.opencl.cl_gl_ext.loadEXT(_loadedVersion, platform);
            derelict.opencl.cl_gl.loadEXT(_loadedVersion, platform);
            
            if(Derelict_OS_Windows)
            {
                derelict.opencl.cl_d3d10.loadEXT(_loadedVersion, platform);
                derelict.opencl.cl_d3d11.loadEXT(_loadedVersion, platform);
                derelict.opencl.cl_dx9_media_sharing.loadEXT(_loadedVersion, platform);
            }
        }
    }

    protected
    {
        this()
        {
            super(libNames);
        }

        override void loadSymbols()
        {
            // OpenCL 1.0
            bindFunc(cast(void**)&clGetPlatformIDs, "clGetPlatformIDs");
            bindFunc(cast(void**)&clGetPlatformInfo, "clGetPlatformInfo");
            bindFunc(cast(void**)&clGetDeviceIDs, "clGetDeviceIDs");
            bindFunc(cast(void**)&clGetDeviceInfo, "clGetDeviceInfo");
            bindFunc(cast(void**)&clCreateContext, "clCreateContext");
            bindFunc(cast(void**)&clCreateContextFromType, "clCreateContextFromType");
            bindFunc(cast(void**)&clRetainContext, "clRetainContext");
            bindFunc(cast(void**)&clReleaseContext, "clReleaseContext");
            bindFunc(cast(void**)&clGetContextInfo, "clGetContextInfo");
            bindFunc(cast(void**)&clCreateCommandQueue, "clCreateCommandQueue");
            bindFunc(cast(void**)&clRetainCommandQueue, "clRetainCommandQueue");
            bindFunc(cast(void**)&clReleaseCommandQueue, "clReleaseCommandQueue");
            bindFunc(cast(void**)&clGetCommandQueueInfo, "clGetCommandQueueInfo");
            bindFunc(cast(void**)&clCreateBuffer, "clCreateBuffer");
            bindFunc(cast(void**)&clRetainMemObject, "clRetainMemObject");
            bindFunc(cast(void**)&clReleaseMemObject, "clReleaseMemObject");
            bindFunc(cast(void**)&clGetSupportedImageFormats, "clGetSupportedImageFormats");
            bindFunc(cast(void**)&clGetMemObjectInfo, "clGetMemObjectInfo");
            bindFunc(cast(void**)&clGetImageInfo, "clGetImageInfo");
            bindFunc(cast(void**)&clCreateSampler, "clCreateSampler");
            bindFunc(cast(void**)&clRetainSampler, "clRetainSampler");
            bindFunc(cast(void**)&clReleaseSampler, "clReleaseSampler");
            bindFunc(cast(void**)&clGetSamplerInfo, "clGetSamplerInfo");
            bindFunc(cast(void**)&clCreateProgramWithSource, "clCreateProgramWithSource");
            bindFunc(cast(void**)&clCreateProgramWithBinary, "clCreateProgramWithBinary");
            bindFunc(cast(void**)&clRetainProgram, "clRetainProgram");
            bindFunc(cast(void**)&clReleaseProgram, "clReleaseProgram");
            bindFunc(cast(void**)&clBuildProgram, "clBuildProgram");
            bindFunc(cast(void**)&clGetProgramInfo, "clGetProgramInfo");
            bindFunc(cast(void**)&clGetProgramBuildInfo, "clGetProgramBuildInfo");
            bindFunc(cast(void**)&clCreateKernel, "clCreateKernel");
            bindFunc(cast(void**)&clCreateKernelsInProgram, "clCreateKernelsInProgram");
            bindFunc(cast(void**)&clRetainKernel, "clRetainKernel");
            bindFunc(cast(void**)&clReleaseKernel, "clReleaseKernel");
            bindFunc(cast(void**)&clSetKernelArg, "clSetKernelArg");
            bindFunc(cast(void**)&clGetKernelInfo, "clGetKernelInfo");
            bindFunc(cast(void**)&clGetKernelWorkGroupInfo, "clGetKernelWorkGroupInfo");
            bindFunc(cast(void**)&clWaitForEvents, "clWaitForEvents");
            bindFunc(cast(void**)&clGetEventInfo, "clGetEventInfo");
            bindFunc(cast(void**)&clRetainEvent, "clRetainEvent");
            bindFunc(cast(void**)&clReleaseEvent, "clReleaseEvent");
            bindFunc(cast(void**)&clGetEventProfilingInfo, "clGetEventProfilingInfo");
            bindFunc(cast(void**)&clFlush, "clFlush");
            bindFunc(cast(void**)&clFinish, "clFinish");
            bindFunc(cast(void**)&clEnqueueReadBuffer, "clEnqueueReadBuffer");
            bindFunc(cast(void**)&clEnqueueWriteBuffer, "clEnqueueWriteBuffer");
            bindFunc(cast(void**)&clEnqueueCopyBuffer, "clEnqueueCopyBuffer");
            bindFunc(cast(void**)&clEnqueueReadImage, "clEnqueueReadImage");
            bindFunc(cast(void**)&clEnqueueWriteImage, "clEnqueueWriteImage");
            bindFunc(cast(void**)&clEnqueueCopyImage, "clEnqueueCopyImage");
            bindFunc(cast(void**)&clEnqueueCopyImageToBuffer, "clEnqueueCopyImageToBuffer");
            bindFunc(cast(void**)&clEnqueueCopyBufferToImage, "clEnqueueCopyBufferToImage");
            bindFunc(cast(void**)&clEnqueueMapBuffer, "clEnqueueMapBuffer");
            bindFunc(cast(void**)&clEnqueueMapImage, "clEnqueueMapImage");
            bindFunc(cast(void**)&clEnqueueUnmapMemObject, "clEnqueueUnmapMemObject");
            bindFunc(cast(void**)&clEnqueueNDRangeKernel, "clEnqueueNDRangeKernel");
            bindFunc(cast(void**)&clEnqueueTask, "clEnqueueTask");
            bindFunc(cast(void**)&clEnqueueNativeKernel, "clEnqueueNativeKernel");

            derelict.opencl.cl_ext.loadSymbols(&bindFunc);
            derelict.opencl.cl_gl_ext.loadSymbols(&bindFunc);
            derelict.opencl.cl_gl.loadSymbols(&bindFunc);

            if(Derelict_OS_Windows)
            {
                derelict.opencl.cl_d3d10.loadSymbols(&bindFunc);
                derelict.opencl.cl_d3d11.loadSymbols(&bindFunc);
                derelict.opencl.cl_dx9_media_sharing.loadSymbols(&bindFunc);
            }

            _loadedVersion = CLVersion.CL10;
        }
    }

    private
    {
        CLVersion _loadedVersion;
    }
}

__gshared DerelictCLLoader DerelictCL;

shared static this()
{
    DerelictCL = new DerelictCLLoader;
}
