// DerelictCL - a Derelict based dynamic binding for OpenCL
// written in the D programming language
//
// Copyright: MeinMein 2013-2014.
// License:   Boost License 1.0
//            (See accompanying file LICENSE_1_0.txt or copy at
//             http://www.boost.org/LICENSE_1_0.txt)
// Authors:   Gerbrand Kamphuis (meinmein.com),
//            Marvin Meeng (meinmein.com).
module derelict.opencl.cl_gl_ext;

import derelict.opencl.loader;
import derelict.opencl.types;

extern (System)
{
    // OpenCL 1.1
    alias nothrow cl_event function(cl_context, cl_GLsync, cl_int*) da_clCreateEventFromGLsyncKHR;
}

__gshared
{
    // OpenCL 1.1
    da_clCreateEventFromGLsyncKHR clCreateEventFromGLsyncKHR;
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

    private __gshared bool _EXT_cl_khr_gl_event;
    public bool EXT_cl_khr_gl_event() @property { return _EXT_cl_khr_gl_event; }
    private void load_cl_khr_gl_event(CLVersion clVer, cl_platform_id platform)
    {
        try
        {
            loadExtensionFunction(cast(void**)&clCreateEventFromGLsyncKHR, "clCreateEventFromGLsyncKHR", clVer, platform);

            _EXT_cl_khr_gl_event = clCreateEventFromGLsyncKHR !is null;
        }
        catch(Exception e)
        {
            _EXT_cl_khr_gl_event = false;
        }
    }

    void loadEXT(CLVersion clVer, cl_platform_id platform)
    {
        if(clVer >= CLVersion.CL11)
        {
            // OpenCL 1.1
            load_cl_khr_gl_event(clVer, platform);
        }
    }
}
