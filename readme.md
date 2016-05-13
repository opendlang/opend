ErupteD
=======

Automatically-generated D bindings for Vulkan. Acquiring Vulkan functions is based on Intel [API without Secrets](https://software.intel.com/en-us/api-without-secrets-introduction-to-vulkan-part-1)

Usage
-----

The bindings have two configurations: the `default` configuration, where the bindings load all functions from the `vkGetInstanceProcAddr`, which you supply when loading; and the `with-derelict-loader` configuration, which uses the Derelict library to load `vkGetInstanceProcAddr` for you.

To use in the `default` configuration:

1. Import via `import erupted;`.
2. Get a pointer to the `vkGetInstanceProcAddr`, through platform-specific means (ex. loading the Vulkan shared library, or `glfwGetInstanceProcAddress` if using GLFW).
3. Call `EruptedLoader.loadGlobalLevelFunctions(getProcAddr)`, where `getProcAddr` is the address of the loaded `vkGetInstanceProcAddr` function, to load the following functions:
	* `vkGetInstanceProcAddr` (sets the global variable from the passed value)
	* `vkCreateInstance`
	* `vkEnumerateInstanceExtensionProperties`
	* `vkEnumerateInstanceLayerProperties`
4. Create a `VkInstance` using the above functions.
5. Call `EruptedLoader.loadInstanceLevelFunctions(instance)` to load additional `VkInstance` related functions. Get information about available physical devices (e.g. GPU(s), APU(s), etc.) and physical device related resources (e.g. Queue Families, Queues per Family, etc. )
6. Now two options are available to acquire device and device resource related functions (functions with first param of `VkDevice`, `VkQueue` or `VkCommandBuffer`):
	* Call `EruptedLoader.loadDeviceLevelFunctions(instance)`, the acquired functions call indirectly through the `VkInstance` and will be internally dispatched by the implementation
	* Call `EruptedLoader.loadDeviceLevelFunctions(device)`, the acquired functions call directly the logical `VkDevice` and related resources. In a multi physical device environment this function must be called once per required physical device. 

To use in the `with-derelict-loader` configuration, follow the above steps, but call `EruptedDerelict.load()` instead of performing steps two and three.

Available configurations:
* `with-derelict-loader` fetches derelictUtil, gets a pointer to  `vkGetInstanceProcAddr` and loads few additional global functions
* `with-global-enums` forwards named enums into global scope
* `with-derelict-loader-and-global-enums` combines the two above 

The API is similar to the C Vulkan API, but with some differences:
* Named enums in D are not global, you need to specify the enum type. Ex: `VkResult.VK_SUCCESS` instead of just `VK_SUCCESS`.
Optionally you can use the configuration `with-global-enums` so that all enum definitions are forwarded into global scope.
* All structures have their `sType` field set to the appropriate value upon initialization; explicit initialization is not needed.
* `VkPipelineShaderStageCreateInfo.module` has been renamed to `VkPipelineShaderStageCreateInfo._module`, since `module` is a D keyword.

Examples can be found in the `examples` directory, and ran with `dub run d-vulkan:examplename`.


Platform surface extensions
---------------------------

If you wish to create vulkan surface(s) yourself (instead of using e.g. glfw) you need to specify the required platform as compiler version flag. The available platform specifiers are the same as those found in `vk_platform.h`. In such a case a platform specific d module will be publicly imported into types.d so that required platform specific types and functions become available.
A twist is that the only API included in phobos is the windows API hence the module `core.sys.windows.windows` is publicly imported in the case of `VK_USE_PLATFORM_WIN32_KHR`. In all other cases the imported module names are the same as the corresponding includes in the `vk_platform.h`, only exception is `wayland_client` in case of `wayland-client.h`. You need to instruct dmd/dub with the proper path to such a module and/or edit the respective line in versions.d


Generating Bindings
-------------------

To generate bindings (Requires Python 3 and lxml.etree) download the [Vulkan-Docs](https://github.com/KhronosGroup/Vulkan-Docs) repo and do one of two things:
* run `vkdgen.py` passing `path/to/vulkan-docs` as first argument and an output folder for the D files as second argument
* copy/move/symlink `vkdgen.py` into `src/spec/`, `cd` there, and execute it, passing in an output folder to place the D files as the only argument.

