// DerelictCL - a Derelict based dynamic binding for OpenCL
// written in the D programming language
//
// Copyright: MeinMein 2013-2014.
// License:   Boost License 1.0
//            (See accompanying file LICENSE_1_0.txt or copy at
//             http://www.boost.org/LICENSE_1_0.txt)
// Authors:   Gerbrand Kamphuis (meinmein.com),
//            Marvin Meeng (meinmein.com).
module derelict.opencl.loader;

import std.string;

import derelict.opencl.cl;

// All functions tagged at the end by KHR, EXT or vendor-specific (ie. APPLE)
// need to be queried using this function.
//
// From: http://www.khronos.org/registry/cl/sdk/1.1/docs/man/xhtml/clGetExtensionFunctionAddress.html
// A return value of NULL indicates that the specified function does not exist for the implementation.
// A non-NULL return value for clGetExtensionFunctionAddress does not guarantee that
// an extension function is actually supported. The application must also make a corresponding query
// using clGetPlatformInfo(platform, CL_PLATFORM_EXTENSIONS, ... ) or clGetDeviceInfo(device, CL_DEVICE_EXTENSIONS, ... )
// to determine if an extension is supported by the OpenCL implementation. 
//
// Note: In OpenCL 1.2 a cl_platform-id is required to retrieve the function adresses.
void loadExtensionFunction(void** ptr, string funcName, CLVersion clVer, cl_platform_id platform = null)
{
    // OpenCL 1.1 Deprecated in 1.2
    if(clVer <= CLVersion.CL11)
        *ptr = clGetExtensionFunctionAddress(funcName.toStringz());
    // OpenCL 1.2
    else
        *ptr = clGetExtensionFunctionAddressForPlatform(platform, funcName.toStringz());
}
