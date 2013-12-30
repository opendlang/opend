// DerelictCL - a Derelict based dynamic binding for OpenCL
// written in the D programming language
//
// Copyright: MeinMein 2013-2014.
// License:   Boost License 1.0
//            (See accompanying file LICENSE_1_0.txt or copy at
//             http://www.boost.org/LICENSE_1_0.txt)
// Authors:   Gerbrand Kamphuis (meinmein.com),
//            Marvin Meeng (meinmein.com).
module derelict.opencl.cl_egl;

import derelict.opencl.loader;
import derelict.opencl.types;

extern (System)
{
    // OpenCL 1.0
    alias nothrow cl_mem function(cl_context, CLeglDisplayKHR, CLeglImageKHR, cl_mem_flags, const(cl_egl_image_properties_khr), cl_int*) da_clCreateFromEGLImageKHR;
    alias nothrow cl_mem function(cl_command_queue, cl_uint, const(cl_mem*), cl_uint, const(cl_event*), cl_event*) da_clEnqueueAcquireEGLObjectsKHR;
    alias nothrow cl_int function(cl_command_queue, cl_uint, const(cl_mem*), cl_uint, const(cl_event*), cl_event*) da_clEnqueueReleaseEGLObjectsKHR;
    alias nothrow cl_event function(cl_context, void*, void*, cl_int*) da_clCreateEventFromEGLSyncKHR;
}

__gshared
{
    // OpenCL 1.0
    da_clCreateFromEGLImageKHR clCreateFromEGLImageKHR;
    da_clEnqueueAcquireEGLObjectsKHR clEnqueueAcquireEGLObjectsKHR;
    da_clEnqueueReleaseEGLObjectsKHR clEnqueueReleaseEGLObjectsKHR;
    da_clCreateEventFromEGLSyncKHR clCreateEventFromEGLSyncKHR;
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

    private __gshared bool _EXT_cl_khr_egl_image;
    public bool EXT_cl_khr_egl_image() @property { return _EXT_cl_khr_egl_image; }
    private void load_cl_khr_egl_image(CLVersion clVer, cl_platform_id platform)
    {
        try
        {
            loadExtensionFunction(cast(void**)&clCreateFromEGLImageKHR, "clCreateFromEGLImageKHR", clVer, platform);
            loadExtensionFunction(cast(void**)&clEnqueueAcquireEGLObjectsKHR, "clEnqueueAcquireEGLObjectsKHR", clVer, platform);
            loadExtensionFunction(cast(void**)&clEnqueueReleaseEGLObjectsKHR, "clEnqueueReleaseEGLObjectsKHR", clVer, platform);

            _EXT_cl_khr_egl_image = clCreateFromEGLImageKHR !is null &&
                                    clEnqueueAcquireEGLObjectsKHR !is null &&
                                    clEnqueueReleaseEGLObjectsKHR !is null;
        }
        catch(Exception e)
        {
            _EXT_cl_khr_egl_image = false;
        }
    }

    private __gshared bool _EXT_cl_khr_egl_event;
    public bool EXT_cl_khr_egl_event() @property { return _EXT_cl_khr_egl_event; }
    private void load_cl_khr_egl_event(CLVersion clVer, cl_platform_id platform)
    {
        try
        {
            loadExtensionFunction(cast(void**)&clCreateEventFromEGLSyncKHR, "clCreateEventFromEGLSyncKHR", clVer, platform);

            _EXT_cl_khr_egl_event = clCreateEventFromEGLSyncKHR !is null;
        }
        catch(Exception e)
        {
            _EXT_cl_khr_egl_event = false;
        }
    }

    void loadEXT(CLVersion clVer, cl_platform_id platform)
    {
        if(clVer >= CLVersion.CL10)
        {
            // OpenCL 1.0
            load_cl_khr_egl_image(clVer, platform);
            load_cl_khr_egl_event(clVer, platform);
        }
    }
}
