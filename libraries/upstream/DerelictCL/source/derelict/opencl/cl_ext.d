// DerelictCL - a Derelict based dynamic binding for OpenCL
// written in the D programming language
//
// Copyright: MeinMein 2013-2014.
// License:   Boost License 1.0
//            (See accompanying file LICENSE_1_0.txt or copy at
//             http://www.boost.org/LICENSE_1_0.txt)
// Authors:   Gerbrand Kamphuis (meinmein.com),
//            Marvin Meeng (meinmein.com).
module derelict.opencl.cl_ext;

import derelict.opencl.loader;
import derelict.opencl.types;

extern (System)
{
    // OpenCL 1.0
    alias nothrow cl_int function(cl_mem, void function(cl_mem, void*), void*) da_clSetMemObjectDestructorAPPLE;
    alias nothrow void function(const(char*), const(void*), size_t, void*) da_clLogMessagesToSystemLogAPPLE;
    alias nothrow void function(const(char*), const(void*), size_t, void*) da_clLogMessagesToStdoutAPPLE;
    alias nothrow void function(const(char*), const(void*), size_t, void*) da_clLogMessagesToStderrAPPLE;
    alias nothrow cl_int function(cl_uint, cl_platform_id*, cl_uint*) da_clIcdGetPlatformIDsKHR;
    // OpenCL 1.1
    alias nothrow cl_int function(cl_device_id) da_clReleaseDeviceEXT;
    alias nothrow cl_int function(cl_device_id) da_clRetainDeviceEXT;
    alias nothrow cl_int function(cl_device_id, const(cl_device_partition_property_ext*), cl_uint, cl_device_id*, cl_uint*) da_clCreateSubDevicesEXT;
    // OpenCL 1.2
    alias nothrow cl_int function(cl_context) da_clTerminateContextKHR;
}

__gshared
{
    // OpenCL 1.0
    da_clSetMemObjectDestructorAPPLE clSetMemObjectDestructorAPPLE;
    da_clLogMessagesToSystemLogAPPLE clLogMessagesToSystemLogAPPLE;
    da_clLogMessagesToStdoutAPPLE clLogMessagesToStdoutAPPLE;
    da_clLogMessagesToStderrAPPLE clLogMessagesToStderrAPPLE;
    da_clIcdGetPlatformIDsKHR clIcdGetPlatformIDsKHR;
    // OpenCL 1.1
    da_clReleaseDeviceEXT clReleaseDeviceEXT;
    da_clRetainDeviceEXT clRetainDeviceEXT;
    da_clCreateSubDevicesEXT clCreateSubDevicesEXT;
    // OpenCL 1.2
    da_clTerminateContextKHR clTerminateContextKHR;
}

package
{
    void loadSymbols(void delegate(void**, string, bool doThrow) bindFunc)
    {

    }

    CLVersion reload(void delegate(void**, string, bool doThrow) bindFunc, CLVersion clVer)
    {
        return clVer;
    }

    private __gshared bool _EXT_cl_APPLE_SetMemObjectDestructor;
    public bool EXT_cl_APPLE_SetMemObjectDestructor() @property { return _EXT_cl_APPLE_SetMemObjectDestructor; }
    private void load_cl_APPLE_SetMemObjectDestructor(CLVersion clVer, cl_platform_id platform)
    {
        try
        {
            loadExtensionFunction(cast(void**)&clSetMemObjectDestructorAPPLE, "clSetMemObjectDestructorAPPLE", clVer, platform);

            _EXT_cl_APPLE_SetMemObjectDestructor = clSetMemObjectDestructorAPPLE !is null;
        }
        catch(Exception e)
        {
            _EXT_cl_APPLE_SetMemObjectDestructor = false;
        }
    }

    private __gshared bool _EXT_cl_APPLE_ContextLoggingFunctions;
    public bool EXT_cl_APPLE_ContextLoggingFunctions() @property { return _EXT_cl_APPLE_ContextLoggingFunctions; }
    private void load_cl_APPLE_ContextLoggingFunctions(CLVersion clVer, cl_platform_id platform)
    {
        try
        {
            loadExtensionFunction(cast(void**)&clLogMessagesToSystemLogAPPLE, "clLogMessagesToSystemLogAPPLE", clVer, platform);
            loadExtensionFunction(cast(void**)&clLogMessagesToStdoutAPPLE, "clLogMessagesToStdoutAPPLE", clVer, platform);
            loadExtensionFunction(cast(void**)&clLogMessagesToStderrAPPLE, "clLogMessagesToStderrAPPLE", clVer, platform);

            _EXT_cl_APPLE_ContextLoggingFunctions = clLogMessagesToSystemLogAPPLE !is null &&
                                                    clLogMessagesToStdoutAPPLE !is null &&
                                                    clLogMessagesToStderrAPPLE !is null;
        }
        catch(Exception e)
        {
            _EXT_cl_APPLE_ContextLoggingFunctions = false;
        }
    }

    private __gshared bool _EXT_cl_khr_icd;
    public bool EXT_cl_khr_icd() @property { return _EXT_cl_khr_icd; }
    private void load_cl_khr_icd(CLVersion clVer, cl_platform_id platform)
    {
        try
        {
            loadExtensionFunction(cast(void**)&clIcdGetPlatformIDsKHR, "clIcdGetPlatformIDsKHR", clVer, platform);

            _EXT_cl_khr_icd = clIcdGetPlatformIDsKHR !is null;
        }
        catch(Exception e)
        {
            _EXT_cl_khr_icd = false;
        }
    }

    private __gshared bool _EXT_cl_ext_device_fission;
    public bool EXT_cl_ext_device_fission() @property { return _EXT_cl_ext_device_fission; }
    private void load_cl_ext_device_fission(CLVersion clVer, cl_platform_id platform)
    {
        try
        {
            loadExtensionFunction(cast(void**)&clReleaseDeviceEXT, "clReleaseDeviceEXT", clVer, platform);
            loadExtensionFunction(cast(void**)&clRetainDeviceEXT, "clRetainDeviceEXT", clVer, platform);
            loadExtensionFunction(cast(void**)&clCreateSubDevicesEXT, "clCreateSubDevicesEXT", clVer, platform);

            _EXT_cl_ext_device_fission = clReleaseDeviceEXT !is null &&
                                         clRetainDeviceEXT !is null &&
                                         clCreateSubDevicesEXT !is null;
        }
        catch(Exception e)
        {
            _EXT_cl_ext_device_fission = false;
        }
    }

    private __gshared bool _EXT_cl_khr_terminate_context;
    public bool EXT_cl_khr_terminate_context() @property { return _EXT_cl_khr_terminate_context; }
    private void load_cl_khr_terminate_context(CLVersion clVer, cl_platform_id platform)
    {
        try
        {
            loadExtensionFunction(cast(void**)&clTerminateContextKHR, "clTerminateContextKHR", clVer, platform);

            _EXT_cl_khr_terminate_context = clTerminateContextKHR !is null;
        }
        catch(Exception e)
        {
            _EXT_cl_khr_terminate_context = false;
        }
    }


    void loadEXT(CLVersion clVer, cl_platform_id platform)
    {
        if(clVer >= CLVersion.CL10)
        {
            // OpenCL 1.0
            load_cl_APPLE_SetMemObjectDestructor(clVer, platform);
            load_cl_APPLE_ContextLoggingFunctions(clVer, platform);
            load_cl_khr_icd(clVer, platform);
        }

        if(clVer >= CLVersion.CL11)
        {
            // OpenCL 1.1
            load_cl_ext_device_fission(clVer, platform);
        }

        if(clVer >= CLVersion.CL12)
        {
            // OpenCL 1.2
            load_cl_khr_terminate_context(clVer, platform);
        }
    }
}
