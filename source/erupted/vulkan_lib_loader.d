/**
 * Dlang vulkan lib loader retrieving vkGetInstanceProcAddr for windows, macos and posix systems
 *
 * Copyright: Copyright 2015-2016 The Khronos Group Inc.; Copyright 2016 Alex Parrill, Peter Particle.
 * License:   $(https://opensource.org/licenses/MIT, MIT License).
 * Authors: Copyright 2016 Alex Parrill, Peter Particle
 */
module erupted.vulkan_lib_loader;

import erupted.functions;
import core.stdc.stdio : fprintf, stderr, FILE;

nothrow @nogc:


/// private helper functions for windows platform
version( Windows ) {
private:
    import core.sys.windows.windows;
    HMODULE         vulkan_lib  = null;
    auto loadLib()  { return LoadLibrary( "vulkan-1.dll" ); }
    bool freeLib()  { return FreeLibrary( vulkan_lib ) != 0; }
    auto loadSym()  { return cast( PFN_vkGetInstanceProcAddr )GetProcAddress( vulkan_lib, "vkGetInstanceProcAddr" ); }
    void logLibError( FILE* log_stream, const( char )* message ) {
        fprintf( log_stream, "%svulkan-1.dll! Error code: 0x%x\n", message, GetLastError());
    }
}


/// private helper functions for android platform
else version( Android ) {
private:
    import core.sys.posix.dlfcn : dlerror, dlopen, dlclose, dlsym, RTLD_NOW, RTLD_LOCAL;
    void*           vulkan_lib  = null;
    auto loadLib()  { return dlopen( "libvulkan.so", RTLD_NOW | RTLD_LOCAL ); }
    bool freeLib()  { return dlclose( vulkan_lib ) == 0; }
    auto loadSym()  { return cast( PFN_vkGetInstanceProcAddr )dlsym( vulkan_lib, "vkGetInstanceProcAddr" ); }
    void logLibError( FILE* log_stream, const( char )* message ) {
        fprintf( log_stream, "%slibvulkan.so.1! Error: %s\n", message, dlerror );
    }
}


/// private helper functions for macos platforms
else version( OSX ) {
private:
    import core.sys.posix.dlfcn : dlerror, dlopen, dlclose, dlsym, RTLD_LAZY, RTLD_LOCAL;
    void*           vulkan_lib  = null;
    auto loadLib()  { return dlopen( "libvulkan.1.dylib", RTLD_LAZY | RTLD_LOCAL ); }
    bool freeLib()  { return dlclose( vulkan_lib ) == 0; }
    auto loadSym()  { return cast( PFN_vkGetInstanceProcAddr )dlsym( vulkan_lib, "vkGetInstanceProcAddr" ); }
    void logLibError( FILE* log_stream, const( char )* message ) {
        fprintf( log_stream, "%slibvulkan.1.dylib! Error: %s\n", message, dlerror );
    }
}


/// private helper functions for posix platforms
else version( Posix ) {
private:
    import core.sys.posix.dlfcn : dlerror, dlopen, dlclose, dlsym, RTLD_LAZY, RTLD_LOCAL;
    void*           vulkan_lib  = null;
    auto loadLib()  { return dlopen( "libvulkan.so.1", RTLD_LAZY | RTLD_LOCAL ); }
    bool freeLib()  { return dlclose( vulkan_lib ) == 0; }
    auto loadSym()  { return cast( PFN_vkGetInstanceProcAddr )dlsym( vulkan_lib, "vkGetInstanceProcAddr" ); }
    void logLibError( FILE* log_stream, const( char )* message ) {
        fprintf( log_stream, "%slibvulkan.so.1! Error: %s\n", message, dlerror );
    }
}


/// tries to load the platform vulkan dynamic link library
/// the library handle / pointer is stored privately in this module
/// errors are reported to a specifiable stream which is standard error by default
/// Params:
///     log_stream = file stream to receive error messages, default stderr
/// Returns: true if the vulkan lib could be loaded, false otherwise
bool loadVulkanLib( FILE* log_stream = stderr ) {
    vulkan_lib = loadLib;
    if( !vulkan_lib ) {
        logLibError( log_stream, "Could not load " );
        return false;
    } else {
        return true;
    }
}


/// tries to load the vkGetInstanceProcAddr function from the module private lib handle / pointer
/// if the lib was not loaded so far loadVulkanLib is called
/// errors are reported to a specifiable stream which is standard error by default
/// Params:
///     log_stream = file stream to receive error messages, default stderr
/// Returns: vkGetInstanceProcAddr if it could be loaded from the lib, null otherwise
PFN_vkGetInstanceProcAddr loadGetInstanceProcAddr( FILE* log_stream = stderr ) {
    if( !vulkan_lib && !loadVulkanLib( log_stream )) {
        fprintf( log_stream, "Cannot not retrieve vkGetInstanceProcAddr as vulkan lib is not loaded!" );
        return null;
    }
    auto getInstanceProcAddr = loadSym;
    if( !getInstanceProcAddr )
        logLibError( log_stream, "Could not retrieve vkGetInstanceProcAddr from " );
    return getInstanceProcAddr;
}


/// tries to free / unload the previously loaded platform vulkan lib
/// errors are reported to a specifiable stream which is standard error by default
/// Params:
///     log_stream = file stream to receive error messages, default stderr
/// Returns: true if the vulkan lib could be freed, false otherwise
bool freeVulkanLib( FILE* log_stream = stderr ) {
    if( !vulkan_lib ) {
        fprintf( log_stream, "Cannot free vulkan lib as it is not loaded!" );
        return false;
    } else if( !freeLib() ) {
        logLibError( log_stream, "Could not unload " );
        return false;
    } else {
        return true;
    }
}


/// Combines loadVulkanLib, loadGetInstanceProcAddr and loadGlobalLevelFunctions( PFN_vkGetInstanceProcAddr )
/// from module erupted.functions. If this function succeeds the function vkGetInstanceProcAddr
/// from module erupted.functions can be used freely. Moreover the required functions to initialize a
/// vulkan instance a vkEnumerateInstanceExtensionProperties, vkEnumerateInstanceLayerProperties and vkCreateInstance
/// are available as well. To get all the other functions an vulkan instance must be created and with it
/// loadInstanceLevelFunctions be called from either erupted.functions or through a custom tailored module
/// with mixed in extensions through the erupted.platform.mixin_extensions mechanism.
/// Additional device based functions can then be loaded with loadDeviceLevelFunctions passing in the instance or
/// with creating a vulkan device beforehand and calling the same function with it.
///
/// Note: as this function indirectly calls loadVulkanLib loading the vulkan lib, freeVulkanLib should be called
///       at some point in the process to cleanly free / unload the lib
/// all errors during vulkan lib loading and vkGetInstanceProcAddr retrieving are reported to log_stream, default stderr
///     log_stream = file stream to receive error messages, default stderr
/// Returns: true if the vulkan lib could be freed, false otherwise
bool loadGlobalLevelFunctions( FILE* log_stream = stderr ) {
    auto getInstanceProcAddr = loadGetInstanceProcAddr( log_stream );
    if( !getInstanceProcAddr ) return false;
    erupted.functions.loadGlobalLevelFunctions( getInstanceProcAddr );
    return true;
}


