ErupteD
=======

Automatically-generated D bindings for Vulkan based on [D-Vulkan](https://github.com/ColonelThirtyTwo/dvulkan). Acquiring Vulkan functions is based on Intel [API without Secrets](https://software.intel.com/en-us/api-without-secrets-introduction-to-vulkan-part-1)

Usage
-----

The bindings have two configurations: the `default` configuration, where the bindings load few functions (see bellow) from the `vkGetInstanceProcAddr`, which you supply when loading and the `with-derelict-loader` configuration, which uses the Derelict library to load `vkGetInstanceProcAddr` for you.

To use in the `default` configuration:

1. Import via `import erupted;`.
2. Get a pointer to the `vkGetInstanceProcAddr`, through platform-specific means (e.g. loading the Vulkan shared library, or `glfwGetInstanceProcAddress` [if using GLFW](https://github.com/ColonelThirtyTwo/dvulkan/wiki/Using-d-vulkan-with-Derelict-GLFW)).
3. Call `EruptedLoader.loadGlobalLevelFunctions(getProcAddr)`, where `getProcAddr` is the address of the loaded `vkGetInstanceProcAddr` function, to load the following functions:
	* `vkGetInstanceProcAddr` (sets the global variable from the passed value)
	* `vkCreateInstance`
	* `vkEnumerateInstanceExtensionProperties`
	* `vkEnumerateInstanceLayerProperties`
4. Create a `VkInstance` using the above functions.
5. Call `EruptedLoader.loadInstanceLevelFunctions(VkInstance)` to load additional `VkInstance` related functions. Get information about available physical devices (e.g. GPU(s), APU(s), etc.) and physical device related resources (e.g. Queue Families, Queues per Family, etc. )
6. Now three options are available to acquire a logical device and device resource related functions (functions with first param of `VkDevice`, `VkQueue` or `VkCommandBuffer`):
	* Call `EruptedLoader.loadDeviceLevelFunctions(VkInstance)`, the acquired functions call indirectly through the `VkInstance` and will be internally dispatched by the implementation
	* Call `EruptedLoader.loadDeviceLevelFunctions(VkDevice)`, the acquired functions call directly the `VkDevice` and related resources. This path is faster, skips one indirection, but (in theory, not tested yet!) is useful only in a single physical deveice environment. Calling the same function with another `VkDevice` should overwrite (this is the not tested theory) all the previously fetched __gshared function
	* Call `createDispatchDeviceLevelFunctions(VkDevice)` and capture the result, which is a struct with all the device level fuction pointers kind of namespaced in that struct. This should avoid collisions.

To use in the `with-derelict-loader` configuration, follow the above steps, but call `EruptedDerelict.load()` instead of performing steps two and three.

Available configurations:
* `with-derelict-loader` fetches derelictUtil, gets a pointer to `vkGetInstanceProcAddr` and loads few additional global functions (see above)

The API is similar to the C Vulkan API, but with some differences:
* Named enums in D are not global but they are forwarded into global scope. Hence e.g. `VkResult.VK_SUCCESS` and `VK_SUCCESS` can both be used.
* All structures have their `sType` field set to the appropriate value upon initialization; explicit initialization is not needed.
* `VkPipelineShaderStageCreateInfo.module` has been renamed to `VkPipelineShaderStageCreateInfo._module`, since `module` is a D keyword.


Platform surface extensions
---------------------------

If you wish to create vulkan surface(s) yourself (instead of using e.g. glfw) you need to specify the required platform as compiler version flag. The available platform specifiers are the same as those found in `vk_platform.h`. In such a case a platform specific d module will be publicly imported into types.d so that required platform specific types and functions become available.
A twist is that the only API included in phobos is the Windows API hence the module `core.sys.windows.windows` is publicly imported in case of `VK_USE_PLATFORM_WIN32_KHR`. In all other cases the imported module names are the same as the corresponding includes in the `vk_platform.h`, only exception is `wayland_client` instead of `wayland-client.h`. You need to instruct dmd/dub with the proper path to such a module and/or edit the respective line in types.d file.


Generating Bindings
-------------------

To erupt the vulkan-docs yourself (Requires Python 3 and lxml.etree) download the [Vulkan-Docs](https://github.com/KhronosGroup/Vulkan-Docs) repo and
call `erupt.py` passing `path/to/vulkan-docs` as first argument and an output folder for the D files as second argument.


Additions to D-Vulkan
---------------------

* Platform surface extensions
* DerelictLoader for Posix Systems
* With respect to [API without Secrets](https://software.intel.com/en-us/api-without-secrets-introduction-to-vulkan-part-1) D-Vulkans function loading system is partially broken


