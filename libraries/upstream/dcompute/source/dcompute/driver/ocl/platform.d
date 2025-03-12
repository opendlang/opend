module dcompute.driver.ocl.platform;

import dcompute.driver.ocl;
import std.experimental.allocator.typed;

struct Platform
{
	static void initialise()
	{
		DerelictCL.load();
	}
    static struct Info
    {
        @(0x0900) immutable(char)* _profile;
        @(0x0901) immutable(char)* _version_;
        @(0x0902) immutable(char)* _name;
        @(0x0903) immutable(char)* _vendor;
        @(0x0904) immutable(char)* _extensions;
        StringzAccessor!(_profile) profile;
        StringzAccessor!(_version_) version_;
        StringzAccessor!(_name) name;
        StringzAccessor!(_vendor) vendor;
        StringzAccessor!(_extensions) extensions;
        // Extensions
        //@(0x0920) khrICDSuffix;

    }

    mixin(generateGetInfo!(Info,clGetPlatformInfo));

    cl_platform_id raw;
    static Platform[] getPlatforms(A)(A a)
    {
        auto allocator = TypedAllocator!(A)(a);
        cl_uint numPlatforms;
        status = cast(Status)clGetPlatformIDs(0,null,&numPlatforms);
        checkErrors();
        cl_platform_id[] ret = allocator.makeArray!(cl_platform_id)(numPlatforms);
        status = cast(Status)clGetPlatformIDs(numPlatforms,cast(cl_platform_id*)ret.ptr,null);
        checkErrors();
        return cast(Platform[])ret;
    }
    
    Device[] getDevices(A)(A a,Device.Type device_type = Device.Type.all)
    {
        auto allocator = TypedAllocator!(A)(a);
        uint numDevices;
        status = cast(Status)clGetDeviceIDs(
            raw,
            cast(cl_device_type)device_type,
            0,
            null,
            &numDevices);
        
        auto deviceIDs = allocator.makeArray!cl_device_id(numDevices);
        
        status = cast(Status)clGetDeviceIDs(
            raw,
            cast(cl_device_type)device_type,
            numDevices,
            deviceIDs.ptr,
            null);
        
        return cast(Device[])deviceIDs;
    }
    
    // clGetExtensionFunctionAddressForPlatform
}
