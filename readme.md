D-Vulkan
========

Automatically-generated D bindings for Vulkan.

Usage
-----

The bindings have two configurations: the `default` configuration, where the bindings load all functions from the `vkGetInstanceProcAddr`, which you supply when loading; and the `with-derelict-loader` configuration, which uses the Derelict library to load `vkGetInstanceProcAddr` for you.

To use in the `default` configuration:

1. Import via `import dvulkan;`.
2. Get a pointer to the `vkGetInstanceProcAddr`, through platform-specific means (ex. loading the Vulkan shared library, or `glfwGetInstanceProcAddress` if using GLFW).
3. Call `DVulkanLoader.loadInstanceFunctions(getProcAddr)`, where `getProcAddr` is the address of the loaded `vkGetInstanceProcAddr` function, to load the following functions:
	* `vkGetInstanceProcAddr` (sets the global variable from the passed value)
	* `vkCreateInstance`
	* `vkEnumerateInstanceExtensionProperties`
	* `vkEnumerateInstanceLayerProperties`
4. Create a `VkInstance` using the above functions.
5. Call `DVulkanLoader.loadAllFunctions(instance)` to load the rest of the functions.
6. (Optional) Call `DVulkanLoader.loadAllFunctions(device)` once you have a `VkDevice` to load specific functions for a device.

To use in the `with-derelict-loader` configuration, follow the above steps, but call `DVulkanDerelict.load()` instead of performing steps two and three.

The API is similar to the C Vulkan API, but with some differences:
* Since enums in D are not global, you need to specify the enum type. Ex: `VkResult.VK_SUCCESS` instead of just `VK_SUCCESS`.
* All structures have their `sType` field set to the appropriate value upon initialization; explicit initialization is not needed.
* `VkPipelineShaderStageCreateInfo.module` has been renamed to `VkPipelineShaderStageCreateInfo._module`, since `module` is a D keyword.

Examples can be found in the `examples` directory, and ran with `dub run dvulkan:examplename`.

Bindings for all extensions are available, except for the `VK_KHR_*_surface` extensions, which require types from external libraries (X11, XCB, ...). They can be manually loaded with `vkGetInstanceProcAddr` if needed.

Generating Bindings
-------------------

To generate bindings, download the [Vulkan-Docs](https://github.com/KhronosGroup/Vulkan-Docs) repo, copy/move/symlink `vkdgen.py` into `src/spec/`, `cd` there, and execute it, passing in an output folder to place the D files. Requires Python 3.
