


ErupteD
=======

Automatically-generated D bindings for the [Vulkan API](https://www.khronos.org/Vulkan/) based on [D-Vulkan](https://github.com/ColonelThirtyTwo/dvulkan). Acquiring Vulkan functions is based on Intel [API without Secrets](https://software.intel.com/en-us/api-without-secrets-introduction-to-vulkan-part-1).  



Release note v2.x.x
-------------------
This release has breaking changes regarding the treatment of [Platform Extensions](https://github.com/ParticlePeter/ErupteD#platform-extensions). All dependency requirements have been removed, including derelict-util to load `vkGetInstanceProcAddr`. This functionality has been replaced through the new module `vulkan_lib_loader`.
Additionally, DispatchDevice and the python generator have been extracted. The former into its own module `erupted.dispatch_device`, and the later into its own github project [V-Erupt](https://github.com/ParticlePeter/V-Erupt).



Usage
-----
The easiest way to start is calling `loadGlobalLevelFunctions()` from module `erupted.vulkan_lib_loader`.This function automatically loads the Vulkan dynamic link library `Vulkan-1.dll` (Windows) or `libvulkan.so.1` (Posix), retrieves `vkGetInstanceProcAddr` from the lib and loads global functions from Vulkan implementation.  

Steps to follow:

1. import vulkan lib loader via `import erupted.vulkan_lib_loader;`
2. call `loadGlobalLevelFunctions()` (and check the result!) to load the following functions:
    * `vkGetInstanceProcAddr`
    * `vkCreateInstance`
    * `vkEnumerateInstanceExtensionProperties`
    * `vkEnumerateInstanceLayerProperties`

    if the call was successful (returns true), skip to 5.
3. on failure, get a pointer to the `vkGetInstanceProcAddr` through platform-specific means (e.g. loading the Vulkan shared library manually, or `glfwGetInstanceProcAddress` [if using GLFW3 >= v3.2 with DerelictGLFW3 >= v3.1.0](https://github.com/ParticlePeter/ErupteD-GLFW))
4. call `loadGlobalLevelFunctions(getInstanceProcAddr)`, where `getInstanceProcAddr` is the address of the loaded `vkGetInstanceProcAddr` function. This loads the same functions as described in step 2.
5. create a `VkInstance` using the above functions
6. call `loadInstanceLevelFunctions(VkInstance)` to load additional `VkInstance` related functions. Get information about available physical devices (e.g. GPU(s), APU(s), etc.) and physical device related resources (e.g. Queue Families, Queues per Family, etc.)
7. three options are available to acquire a logical device and device resource related functions:
    * call `loadDeviceLevelFunctions(VkInstance)`, the acquired functions call indirectly through the `VkInstance` and will be internally dispatched to various devices by the implementation
    * call `loadDeviceLevelFunctions(VkDevice)`, the acquired functions call directly the `VkDevice` and related resources. This path is faster, skips one indirection, but is useful only in a single physical device environment. Calling the same function with another `VkDevice` will overwrite all the previously fetched function
    * create a DispatchDevice with Vulkan functions as members kind of namespaced, see [DispatchDevice](https://github.com/ParticlePeter/ErupteD#dispatchdevice)

Examples for checking instance and device layers as well as device creation can be found in the `examples` directory, and run with `dub run erupted:examplename`. Examples found in 'examples/platform' directory are just explanatory and cannot be build or run (see [Platform Extensions](https://github.com/ParticlePeter/Erupted-V2#platform-extensions))



C vs D API
----------
* `VK_NULL_HANDLE` is defined as `0` and can be used as `uint64_t` type and `pointer` type argument in C world. D's `null` can be used only as a pointer argument. This is an issue when compiling for 32 bit, as dispatchable handles (`VkInstance`, `VkPhysicalDevice`, `VkDevice`, `VkQueue`) are pointer types while non dispatchable handles (e.g. `VkSemaphore`) are `uint64_t` types. Hence ErupteD `VK_NULL_HANDLE` can only be used as dispatchable null handle (on 32 Bit!). For non dispatchable handles another ErupteD symbol exist `VK_NULL_ND_HANDLE`. On 64 bit all handles are pointer types and `VK_NULL_HANDLE` can be used at any place. However `VK_NULL_ND_HANDLE` is still defined for sake of completeness and ease of use. The issue might be solved when `multiple alias this` is released, hence I recommend building 64 Bit apps and ignore `VK_NULL_ND_HANDLE`.<br/>

    Best practice summary:
    * if exclusively building a 32 Bit app or switching forth and back between 32 and 64 Bit use `VK_NULL_ND_HANDLE` for non dispatchable handles
    * if exclusively building a 64 Bit app `VK_NULL_HANDLE` can be used as any of the two vk handle types

* named enums in D are not global but they are forwarded into global scope. Hence e.g. `VkResult.VK_SUCCESS` and `VK_SUCCESS` can both be used
* all structures have their `sType` field set to the appropriate value upon initialization; explicit initialization is not needed
* struct members which are d keywords ( so far `module`, `scope`, `version` ) are renamed to their title case counterparts ( `Module`, `Scope`, `Version` ) and additional alias have been added ( `_module`, `module_`, `_scope`, `scope_` , `_version`, `version_` )



DispatchDevice
--------------
The `DispatchDevice` holds a `VkDevice`, a pointer to `const VkAllocationCallbacks` and the Vulkan functions loaded from that device, collision protected. The allocator is optional for Vulkan as well as for the DispatchDevice and the same rules apply: if not specified, the default allocator will be used. An allocator is locked to the device throughout its lifetime. Before usage, the `DispatchDevice` must be initialize, either immediately:
```
    auto dd = DispatchDevice( device, allocator );      // allocator default = null
```
or delayed:
```
    DispatchDevice dd;
    dd.loadDeviceLevelFunctions( device, allocator );   // allocator can be omitted
```
`VkDevice` and  `VkAllocationCallbacks` are private and must NOT change. The member vkFunctions can only be used with this device and, when required, this allocator. It can be accessed with the properties `vkDevice` and `pAllocator`:
```
    auto dd = DispatchDevice( device );
    dd.vkDestroyDevice( dd.vkDevice, dd.pAllocator );
```
The `DispatchDevice` has also convenience functions. With these the device and allocator arguments can be omitted. They forward to the corresponding Vulkan function, the device and allocator argument are supplied by the private `VkDevice` and `VkAllocationCallbacks` members. The crux is that function pointers can't be overloaded with regular functions hence the `vk` prefix is ditched for the convenience variants:
```
    auto dd = DispatchDevice( device );
    dd.DestroyDevice:       // instead of: dd.vkDestroyDevice( dd.vkDevice, dd.pAllocator );
```
Same mechanism works with functions which require a VkCommandBuffer as first arg, but before using them the public member 'commandBuffer' must be set with the target VkCommandBuffer:
```
    dd.commandBuffer = some_command_buffer;
    dd.BeginCommandBuffer( &beginInfo );
    dd.CmdBindPipeline( VK_PIPELINE_BIND_POINT_GRAPHICS, some_pipeline );
```
Needless to say that `some_command_buffer` must have been acquired from the private device member, or some other handle to that device.  
The Mechanism does NOT work with queues, there are about four queue related functions which most probably won't be used in bulk.



Platform Extensions
-------------------
Platform extensions, found in module `erupted.platform_extensions`, exist in form of the configurable `mixin template Platform_Extensions( extensions... )`. With this template you can mixin extension related code into your project, but you need to take care of the dependencies yourself. Please note the dropped VK_ prefix, more to that bellow:
```
// platform extension example with xlib-d
// xlib-d must be specified as dependency in your projects dub file
module spocks_logic;
public import X11.Xlib;                                 // publicly import required API
import erupted.platform.mixin_extensions;               // import the template mixin
mixin Platform_Extensions!USE_PLATFORM_XLIB_KHR;        // mixin all xlib related extensions
```
The template publicly imports `erupted.types` and `erupted.functions`. This is necessary as some functions from the latter module are overwritten/extended to also load related Vulkan extension functions.  `DispatchDevice` from module `erupted.dispatch_device` is also extended/overwritten with the corresponding extension functions. If you would include both, your module and `erupted.functions` in another module, `loadInstanceLevelFunctions`, `loadDeviceLevelFunctions` and `DispatchDevice` would collide.<br/>
If you still encounter collisions, or extended functionality not working, you can try `loadInstanceLevelFunctionsExt`, `loadDeviceLevelFunctionsExt`, `DispatchDeviceExt` and `DispatchDeviceExt.loadDeviceLevelFunctionsExt`. These are are unique function and struct names as well as, in case of `loadDeviceLevelFunctionsExt`, aliases to corresponding (`VkInstance` and `VkDevice` based) unique functions.

Module `erupted.platform_extensions` defines enums corresponding to extension names, and alias sequences corresponding to C Vulkan platform protection `#define` definitions. In both cases the `VK_` prefix has been dropped. Since vulkan 1.1 all feature names (core 1.0, 1.1 and extensions) are #define(d) to 1. This is reflected in ErupteD with `enum feature_name = 1;` and these enums would collide with those defined in module `Platform_Extensions`. Hence the dropped prefixes. Alias sequences of feature names have their prefix dropped as well, this is not necessary but might change in future. The template accepts combinations of any each enum and alias sequence in any order.

You'll find example modules in `examples/platform` for wayland, xcb and xlib. Copy the whole module or its content into your project and possibly edit its name and imported platform module. On windows `core.sys.windows.windows` from druntime is publicly imported, no need for any other dependency. As of writing windows is also the only platform with multiple extensions in place of `USE_PLATFORM_WIN32_KHR` alias sequence/macro, which are all instantiated.  If you figure out which dependencies are available for other platform extensions, please notify me through an issue or send me a PR.

Reasoning for the redesign:
Platform extensions work with types, and possibly functions, defined in platform specific C headers like `windows.h` or `X11/Xlib.h`. Most important use case of these extensions is arguably platform surface mechanics. The third party library `glfw3` is a solid way to deal with Vulkan platform surfaces in a platform agnostic way. However, by design, `glfw3` does not support surface unrelated platform extensions (e.g. `VK_KHR_external_memory_win32`).<br/>
The only official platform API (as in being part of the dlang standard lib/runtime) is the windows API, but luckily ports of other platform APIs do exist in the dub registry. However, ErupteD should not rely on unofficial dependencies, as they may brake or become deprecated. Furthermore, specifying several different platform dependencies in `dub.sdl` or `dub.json` does pollute the local dub cache with foreign platform projects, even if they are not usable on the current platform (e.g. `xlib-d` on windows platform).



Beta Extensions
---------------
Beta Extensins were introduced in vulkan v1.2.135 with the first three of them being `KHR_deferred_host_operations`, `KHR_pipeline_library`, `KHR_ray_tracing`. They are marked with the special token `VK_ENABLE_BETA_EXTENSIONS` and are curiously treated as platform extensions (see [vk.xml](https://github.com/KhronosGroup/Vulkan-Docs/blob/master/xml/vk.xml)). This means that, if you want to use them, you need to follow the same steps as detailed in [Platform Extensions](https://github.com/ParticlePeter/ErupteD#platform-extensions), mixing them in individually or all of them at once, e.g.:
```
mixin Platform_Extensions!ENABLE_BETA_EXTENSIONS;       // mixin all beta extensions
```



Generating Bindings
-------------------
The generator for Erupted-V2 was split off into its own github project [V-Erupt](https://github.com/ParticlePeter/V-Erupt). 
Additionally, you'll need the [Vulkan-Docs](https://github.com/KhronosGroup/Vulkan-Docs) repo (Requires Python 3 and lxml.etree).  
Finally, to erupt the dlang bindings, call `erupt_dlang.py` passing `path/to/Vulkan-docs` as first argument and an output folder for the D files as second argument. You will still need to manually the directory tree corresponding to the the module paths.
