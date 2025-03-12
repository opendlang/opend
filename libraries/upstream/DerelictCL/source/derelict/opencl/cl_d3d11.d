// DerelictCL - a Derelict based dynamic binding for OpenCL
// written in the D programming language
//
// Copyright: MeinMein 2013-2014.
// License:   Boost License 1.0
//            (See accompanying file LICENSE_1_0.txt or copy at
//             http://www.boost.org/LICENSE_1_0.txt)
// Authors:   Gerbrand Kamphuis (meinmein.com),
//            Marvin Meeng (meinmein.com).
module derelict.opencl.cl_d3d11;

import derelict.opencl.loader;
import derelict.opencl.types;

extern (System)
{
    // OpenCL 1.2
    alias nothrow cl_int function(cl_platform_id platform, cl_d3d11_device_source_khr d3d_device_source, void* d3d_object, cl_d3d11_device_set_khr d3d_device_set, cl_uint num_entries, cl_device_id* devices, cl_uint* num_devices) da_clGetDeviceIDsFromD3D11KHR;
    alias nothrow cl_mem function(cl_context context, cl_mem_flags flags, ID3D11Buffer* resource, cl_int* errcode_ret) da_clCreateFromD3D11BufferKHR;
    alias nothrow cl_mem function(cl_context context, cl_mem_flags flags, ID3D11Texture2D* resource, uint subresource, cl_int* errcode_ret) da_clCreateFromD3D11Texture2DKHR;
    alias nothrow cl_mem function(cl_context context, cl_mem_flags flags, ID3D11Texture3D* resource, uint subresource, cl_int* errcode_ret) da_clCreateFromD3D11Texture3DKHR;
    alias nothrow cl_int function(cl_command_queue command_queue, cl_uint num_objects, const(cl_mem*) mem_objects, cl_uint num_events_in_wait_list, const(cl_event*) event_wait_list, cl_event* event) da_clEnqueueAcquireD3D11ObjectsKHR;
    alias nothrow cl_int function(cl_command_queue command_queue, cl_uint num_objects, const(cl_mem*) mem_objects, cl_uint num_events_in_wait_list, const(cl_event*) event_wait_list, cl_event* event) da_clEnqueueReleaseD3D11ObjectsKHR;
}

__gshared
{
    // OpenCL 1.2
    da_clGetDeviceIDsFromD3D11KHR clGetDeviceIDsFromD3D11KHR;
    da_clCreateFromD3D11BufferKHR clCreateFromD3D11BufferKHR;
    da_clCreateFromD3D11Texture2DKHR clCreateFromD3D11Texture2DKHR;
    da_clCreateFromD3D11Texture3DKHR clCreateFromD3D11Texture3DKHR;
    da_clEnqueueAcquireD3D11ObjectsKHR clEnqueueAcquireD3D11ObjectsKHR;
    da_clEnqueueReleaseD3D11ObjectsKHR clEnqueueReleaseD3D11ObjectsKHR;
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

    private __gshared bool _EXT_cl_khr_d3d11_sharing;
    public bool EXT_cl_khr_d3d11_sharing() @property { return _EXT_cl_khr_d3d11_sharing; }
    private void load_cl_khr_d3d11_sharing(CLVersion clVer, cl_platform_id platform)
    {
        try
        {
            loadExtensionFunction(cast(void**)&clGetDeviceIDsFromD3D11KHR, "clGetDeviceIDsFromD3D11KHR", clVer, platform);
            loadExtensionFunction(cast(void**)&clCreateFromD3D11BufferKHR, "clCreateFromD3D11BufferKHR", clVer, platform);
            loadExtensionFunction(cast(void**)&clCreateFromD3D11Texture2DKHR, "clCreateFromD3D11Texture2DKHR", clVer, platform);
            loadExtensionFunction(cast(void**)&clCreateFromD3D11Texture3DKHR, "clCreateFromD3D11Texture3DKHR", clVer, platform);
            loadExtensionFunction(cast(void**)&clEnqueueAcquireD3D11ObjectsKHR, "clEnqueueAcquireD3D11ObjectsKHR", clVer, platform);
            loadExtensionFunction(cast(void**)&clEnqueueReleaseD3D11ObjectsKHR, "clEnqueueReleaseD3D11ObjectsKHR", clVer, platform);

            _EXT_cl_khr_d3d11_sharing = clGetDeviceIDsFromD3D11KHR !is null &&
                                        clCreateFromD3D11BufferKHR !is null &&
                                        clCreateFromD3D11Texture2DKHR !is null &&
                                        clCreateFromD3D11Texture3DKHR !is null &&
                                        clEnqueueAcquireD3D11ObjectsKHR !is null &&
                                        clEnqueueReleaseD3D11ObjectsKHR !is null;
        }
        catch(Exception e)
        {
            _EXT_cl_khr_d3d11_sharing = false;
        }
    }

    void loadEXT(CLVersion clVer, cl_platform_id platform)
    {
        if(clVer >= CLVersion.CL12)
        {
            // OpenCL 1.2
            load_cl_khr_d3d11_sharing(clVer, platform);
        }
    }
}
