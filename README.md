ErupteD
=======

Automatically-generated D bindings for Vulkan based on [D-Vulkan](https://github.com/ColonelThirtyTwo/dvulkan). Acquiring Vulkan functions is based on Intel [API without Secrets](https://software.intel.com/en-us/api-without-secrets-introduction-to-vulkan-part-1)

Usage
-----

The bindings have two configurations: the `default` configuration, where the bindings load few functions (see bellow) from the `vkGetInstanceProcAddr`, which you supply when loading and the `with-derelict-loader` configuration, which uses the Derelict library to load `vkGetInstanceProcAddr` for you.

To use in the `default` configuration:

1. Import via `import erupted;`.
2. Get a pointer to the `vkGetInstanceProcAddr`, through platform-specific means (e.g. loading the Vulkan shared library, or `glfwGetInstanceProcAddress` [if using GLFW](https://github.com/ColonelThirtyTwo/dvulkan/wiki/Using-d-vulkan-with-Derelict-GLFW)).
3. Call `loadGlobalLevelFunctions(getProcAddr)`, where `getProcAddr` is the address of the loaded `vkGetInstanceProcAddr` function, to load the following functions:
	* `vkGetInstanceProcAddr` (sets the global variable from the passed value)
	* `vkCreateInstance`
	* `vkEnumerateInstanceExtensionProperties`
	* `vkEnumerateInstanceLayerProperties`
4. Create a `VkInstance` using the above functions.
5. Call `loadInstanceLevelFunctions(VkInstance)` to load additional `VkInstance` related functions. Get information about available physical devices (e.g. GPU(s), APU(s), etc.) and physical device related resources (e.g. Queue Families, Queues per Family, etc. )
6. Now three options are available to acquire a logical device and device resource related functions (functions with first param of `VkDevice`, `VkQueue` or `VkCommandBuffer`):
	* Call `loadDeviceLevelFunctions(VkInstance)`, the acquired functions call indirectly through the `VkInstance` and will be internally dispatched by the implementation
	* Call `loadDeviceLevelFunctions(VkDevice)`, the acquired functions call directly the `VkDevice` and related resources. This path is faster, skips one indirection, but (in theory, not tested yet!) is useful only in a single physical deveice environment. Calling the same function with another `VkDevice` should overwrite (this is the not tested theory) all the previously fetched __gshared function
	* Call `createDispatchDeviceLevelFunctions(VkDevice)` and capture the result, which is a struct with all the device level fuction pointers kind of namespaced in that struct. This should avoid collisions.

To use in the `with-derelict-loader` configuration, follow the above steps, but call `EruptedDerelict.load()` instead of performing steps two and three.

Available configurations:
* `with-derelict-loader` fetches derelictUtil, gets a pointer to `vkGetInstanceProcAddr` and loads few additional global functions (see above)

The API is similar to the C Vulkan API, but with some differences:
* Named enums in D are not global but they are forwarded into global scope. Hence e.g. `VkResult.VK_SUCCESS` and `VK_SUCCESS` can both be used.
* All structures have their `sType` field set to the appropriate value upon initialization; explicit initialization is not needed.
* `VkPipelineShaderStageCreateInfo.module` has been renamed to `VkPipelineShaderStageCreateInfo._module`, since `module` is a D keyword.

Examples can be found in the `examples` directory, and ran with `dub run erupted:examplename`

Platform surface extensions
---------------------------

The usage of a third party library like glfw3 is highly recommended instead of vulkan platforms. Dlang has only one official platform binding in phobos which is for windows found in module `core.sys.windows.windows`. Other bindings to XCB, XLIB and Wayland can be found in the dub registry and are supported experimentally. 
However, if you wish to create vulkan surface(s) yourself you have three choices:
1. The dub way, this is experimental. Currently only three bindings are listed in the registry, dub fetches them and adds them to the erupted build dependency when you specify these sub configurations in your projects dub.json. Add `-derelict-loader` to the config name if you want to be able to laod `vkGetInstanceProcAddr` from derelict:
	* `XCB` specify `"subConfigurations" : { "erupted" : "dub-platform-xcb" }`
	* `XLIB` specify `"subConfigurations" : { "erupted" : "dub-platform-xlib" }`
	* `Wayland` specify `"subConfigurations" : { "erupted" : "dub-platform-wayland" }`

2. The symlink (or copy/move) way. If you like to play with bindings yourself this might be the way for you. Drawback is that you need to add the symlink into any erupted version you use and that your binding is not automatically tracked by dub.
    * Create a directory/module-path setup similar to those in `erupted/types.d` (I myself have these paths from the c header `vk_platform.h`) and symlink this the root under `ErupeD/sources` as sibling to `ErupeD/sources/erupted`.
    * You also need to specify the corresponding vulkan version in your projects dub.json versions block. E.g. to use `XCB` you need to specify `"versions" : [ "VK_USE_PLATFORM_XCB_KHR" ]`.
3. The source- and importPaths way. This is if you don't want to add stuff to the ErupteD project structure. Drawback here is that neither erupted nor the binding are automatically tracked by dub, you need to check yourself for any updates. In your project remove the erupted dependency and add:
	* `"sourcePaths" : [ "path/to/ErupteD/source", "path/to/binding/source" ]`
	* `"importPaths" : [ "path/to/ErupteD/source", "path/to/binding/source" ]`


Additional info:
* for windows platform, in your project specify:
`"versions" : [ "VK_USE_PLATFORM_WIN32_KHR" ]`.
The phobos windows modules will be used in that case.
* wayland-client.h cannot exist as module name. The maintainer of `wayland-client-d` choose `wayland.client` as module name and the name is used in `erupted/types` as well. 


Generating Bindings
-------------------

To erupt the vulkan-docs yourself (Requires Python 3 and lxml.etree) download the [Vulkan-Docs](https://github.com/KhronosGroup/Vulkan-Docs) repo and
call `erupt.py` passing `path/to/vulkan-docs` as first argument and an output folder for the D files as second argument.


Additions to D-Vulkan
---------------------

* Platform surface extensions
* ~~DerelictLoader for Posix Systems~~
* With respect to [API without Secrets](https://software.intel.com/en-us/api-without-secrets-introduction-to-vulkan-part-1) D-Vulkans function loading system is partially broken


