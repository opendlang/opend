
ErupteD-V1
==========

**Developement Information:**
Project [ErupteD](https://github.com/ParticlePeter/Erupted) has been deprecated, ErupteD-V1 represents its state before deprecation. Neither will be further developed, vulkan v1.0.69 is the last supported version. Purpose of forking and renaming is to get a fresh start with ErupteD version scheme.  
Breaking changes and further development happens on project [ErupteD-V2](https://github.com/ParticlePeter/Erupted-V2), which eventually will be renamed to ErupteD. Additional details can be found in ErupteD-V2 - [Deprecation and Upgrade Process](https://github.com/ParticlePeter/Erupted-V2#erupted-deprecation-and-upgrade-process).

**Original Introduction:**
Automatically-generated D bindings for Vulkan based on [D-Vulkan](https://github.com/ColonelThirtyTwo/dvulkan). Acquiring Vulkan functions is based on Intel [API without Secrets](https://software.intel.com/en-us/api-without-secrets-introduction-to-vulkan-part-1)

Usage
-----

The bindings have several configurations. The easiest to use is the `"with-derelict-loader"` configuration. The `DerelictUtil` mechanism will be used to dynamically load `vkGetInstanceProcAddr` from `vulkan-1.dll` or `libvulkan.so.1`. Otherwise you need to load `vkGetInstanceProcAddr` with either platform specific means or through some mechanism like [glfw3](http://www.glfw.org/docs/3.2/vulkan.html) as shown [here](https://github.com/ParticlePeter/ErupteD-GLFW). Additional configurations enable the usage of platform specific vulkan functionality (see [Platform surface extensions](https://github.com/ParticlePeter/ErupteD-V1#platform-surface-extensions)).

To use without configuration:

1. Import via `import erupted;`.
2. Get a pointer to the `vkGetInstanceProcAddr`, through platform-specific means (e.g. loading the Vulkan shared library manually, or `glfwGetInstanceProcAddress` [if using GLFW3 >= v3.2 with DerelictGLFW3 >= v3.1.0](https://github.com/ParticlePeter/ErupteD-GLFW)).
3. Call `loadGlobalLevelFunctions(getProcAddr)`, where `getProcAddr` is the address of the loaded `vkGetInstanceProcAddr` function, to load the following functions:
	* `vkGetInstanceProcAddr` (sets the global variable from the passed value)
	* `vkCreateInstance`
	* `vkEnumerateInstanceExtensionProperties`
	* `vkEnumerateInstanceLayerProperties`
4. Create a `VkInstance` using the above functions.
5. Call `loadInstanceLevelFunctions(VkInstance)` to load additional `VkInstance` related functions. Get information about available physical devices (e.g. GPU(s), APU(s), etc.) and physical device related resources (e.g. Queue Families, Queues per Family, etc. )
6. Now three options are available to acquire a logical device and device resource related functions (functions with first param of `VkDevice`, `VkQueue` or `VkCommandBuffer`):
	* Call `loadDeviceLevelFunctions(VkInstance);`, the acquired functions call indirectly through the `VkInstance` and will be internally dispatched by the implementation
	* Call `loadDeviceLevelFunctions(VkDevice);`, the acquired functions call directly the `VkDevice` and related resources. This path is faster, skips one indirection, but (in theory, not tested yet!) is useful only in a single physical device environment. Calling the same function with another `VkDevice` should overwrite (this is the not tested theory) all the previously fetched __gshared function
	* Create a DispatchDevice with vulkan functions as members kind of namespaced, see [DispatchDevice](https://github.com/ParticlePeter/ErupteD-V1#dispatchdevice)

To use with the `with-derelict-loader` configuration, follow the above steps, but call `EruptedDerelict.load()` instead of performing steps two and three.

Available configurations:
* `with-derelict-loader` fetches derelictUtil, gets a pointer to `vkGetInstanceProcAddr` and loads few additional global functions (see above)
* `dub-platform-xcb`, `dub-platform-xlib`, `dub-platform-wayland` fetches corresponding dub packages `xcb-d`, `xlib-d`, `wayland:client`, see [Platform surface extensions](https://github.com/ParticlePeter/ErupteD-V1#platform-surface-extensions)
* `dub-platform-???-derelict-loader` combines the platforms above with the derelict loader

The API is similar to the C Vulkan API, but with some differences:
* `VK_NULL_HANDLE` is defined as `0` and can be used as `uint64_t` type and `pointer` type argument in C world. D's `null` can be used only as a pointer argument. This is an issue when compiling for 32 bit, as dispatchable handles (`VkInstance`, `VkPhysicalDevice`, `VkDevice`, `VkQueue`) are pointer types while non dispatchable handles (e.g. `VkSemaphore`) are `uint64_t` types. Hence erupted `VK_NULL_HANDLE` can only be used as dispatchable null handle (on 32 Bit!). For non dispatchable handles another ErupteD-V1 symbol exist `VK_NULL_ND_HANDLE`. On 64 bit all handles are pointer types and `VK_NULL_HANDLE` can be used at any place. However `VK_NULL_ND_HANDLE` is still defined for sake of completeness and ease of use. The issue might be solved when `multiple alias this` is released, hence I recommend building 64 Bit apps and ignore `VK_NULL_ND_HANDLE`.
	* If exclusively building a 32 Bit app or switching forth and back between 32 and 64 Bit use `VK_NULL_ND_HANDLE` for non dispatchable handles
	* If exclusively building a 64 Bit app `VK_NULL_HANDLE` can be used as any of the two vk handle types
* Named enums in D are not global but they are forwarded into global scope. Hence e.g. `VkResult.VK_SUCCESS` and `VK_SUCCESS` can both be used.
* All structures have their `sType` field set to the appropriate value upon initialization; explicit initialization is not needed.
* `VkPipelineShaderStageCreateInfo.module` has been renamed to `VkPipelineShaderStageCreateInfo._module`, since `module` is a D keyword.

Examples can be found in the `examples` directory, and run with `dub run erupted:examplename`


DispatchDevice
--------------

The DispatchDevice holds a VkDevice and the vulkan functions loaded from that device collision protected.
Before usage the device must be initialize, either immediately:
```
	auto dd = DispatchDevice( device );
```
or delayed:
```
	DispatchDevice dd;
	dd.loadDeviceLevelFunctions( device );
```
The VkMember is private, it should never change as the functions can be used only with this device.
It can be accessed with the getter `vkDevice()` e.g.:
```
	auto dd = DispatchDevice( device );
	dd.vkDestroyDevice( dd.vkDevice, pAllocator );
```
The `DispatchDevice` has also convenience functions such that the `device` argument can be omitted.
They forward to the corresponding vulkan function and the `device` argument is supplied by the private `VkDevice` member. The crux is that function pointers can't be overloaded with regular functions hence the `vk` prefix is ditched for the convenience variants:
```
	auto dd = DispatchDevice( device );
	dd.DestroyDevice( pAllocator );		// instead of: dd.vkDestroyDevice( dd.vkDevice, pAllocator );
```
Same mechanism works with functions which require a VkCommandBuffer as first arg, but before using them the public member 'commandBuffer' must be set with the target VkCommandBuffer:
```
	dd.commandBuffer = some_command_buffer;
	dd.BeginCommandBuffer( &beginInfo );
	dd.CmdBindPipeline( VK_PIPELINE_BIND_POINT_GRAPHICS, some_pipeline );
```
Needless to say that `some_command_buffer` must have been acquired from the private device member, or some other handle to that device.
The Mechanism does NOT work with queues, there are about four queue related functions which most probably won't be used in bulk.


Platform surface extensions
---------------------------

The usage of a third party library like glfw3 is highly recommended instead of vulkan platforms surfaces. Dlang has only one official platform binding in phobos which is for windows, found in module `core.sys.windows.windows`. Other bindings to XCB, XLIB and Wayland can be found in the dub registry and are supported experimentally.
However, if you wish to create vulkan surface(s) yourself you have three choices:

1. The dub way, this is experimental, currently only three bindings are listed in the registry. Dub fetches them and adds them to erupted build dependency when you specify any of these sub configurations in your projects dub.json (add `-derelict-loader` to the config name if you want to be able to laod `vkGetInstanceProcAddr` from derelict):
	* `XCB` specify `"subConfigurations" : { "erupted" : "dub-platform-xcb" }`
	* `XLIB` specify `"subConfigurations" : { "erupted" : "dub-platform-xlib" }`
	* `Wayland` specify `"subConfigurations" : { "erupted" : "dub-platform-wayland" }`

2. The symlink (or copy/move) way. If you like to play with bindings yourself this might be the way for you. Drawback is that you need to add the symlink into any erupted version you use and that your binding is not automatically tracked by dub.
    * Create a directory/module-path similar to those in `erupted/types.d` (I myself have these paths from the C header `vk_platform.h`) and symlink it under `ErupeD/sources` as sibling to `ErupeD/sources/erupted`.
    * You also need to specify the corresponding vulkan version in your projects dub.json versions block. E.g. to use `XCB` you need to specify `"versions" : [ "VK_USE_PLATFORM_XCB_KHR" ]`.

3. The source- and importPaths way. This is if you don't want to add stuff to the ErupteD-V1 project structure. Drawback here is that neither erupted nor the binding are automatically tracked by dub, you need to check yourself for any updates. In your project REMOVE the erupted dependency and add:
	* `"sourcePaths" : [ "path/to/ErupteD-V1/source", "path/to/binding/source" ]`
	* `"importPaths" : [ "path/to/ErupteD-V1/source", "path/to/binding/source" ]`


Additional info:
* there is no need for platform extensions if glfw3 (or similar technique) is used, as shown [here](https://github.com/ParticlePeter/ErupteD-GLFW).
* for windows platform, in your project specify:
`"versions" : [ "VK_USE_PLATFORM_WIN32_KHR" ]`.
The phobos windows modules will be used in that case.
* wayland-client.h cannot exist as module name. The maintainer of `wayland:client` choose `wayland.client` as module name and the name is used in `erupted/types` as well.
* for android platform, I have not a single clue how this is supposed to work. If you are interested in android and have an idea how it should work feel free to open up an issue.


Platform extensions
-------------------

First time non-surface platform (windows) specific extensions were released by NVidia in Vulkan-Docs-v1.0.25, `VK_NV_external_memory_win32` and `VK_NV_win32_keyed_mutex`. To use these extensions specify `"versions" : [ "VK_USE_PLATFORM_WIN32_KHR" ]`) in your projects dub.json. This will also make `VK_KHR_win32_surface` available and vice versa, even if it is not required when using e.g. `GLFW`. A more flexible platform extension mechanism is WIP.


Generating Bindings
-------------------

To erupt the vulkan-docs yourself (Requires Python 3 and lxml.etree) download the [Vulkan-Docs](https://github.com/KhronosGroup/Vulkan-Docs) repo and
call `erupt.py` passing `path/to/vulkan-docs` as first argument and an output folder for the D files as second argument.


Differences to D-Vulkan
----------------------

* Platform surface extensions
* ErupteD-V1 follows [API without Secrets](https://software.intel.com/en-us/api-without-secrets-introduction-to-vulkan-part-1) in terms of function loading naming and stages (three stages contrary to d-vulkan two stages)


Known Issues
------------
Dub error: `Could not find a valid dependency tree configuration:`

Solution: Confirm that in YOUR projects `dub.selections` the `xcb-d` version is at least `2.1.0+1.11.1` or `2.1.0`

Explanation: This is a dub issue with fetching dependencies, in particular with `xcb-d` and `xlib-d`. It happens on windows systems as well, even though these dependencies will never be used. Problem is that `xlib-d` depends on `xcb-d ~>1.11.1` while erupted depends on the newer `xcb-d ~>2.1.0+1.11.1`. This should be O.K. as both `xcb-d` dependencies can coexist BUT `dub.selections` of YOUR project has only one entry for the `xcb-d` dependency. If these dependencies are fetched for the first time dub.selections is created in YOUR project and `xcb-d` version might have been set to version `1.11.1`.
