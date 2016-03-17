D-Vulkan
========

Derelict-style, automatically-generated D bindings for Vulkan.

Usage
-----

* Import via `import dvulkan;`.
* Call `DVulkan.load()` to load the following functions:
	* `vkGetInstanceProcAddr`
	* `vkCreateInstance`
	* `vkEnumerateInstanceExtensionProperties`
	* `vkEnumerateInstanceLayerProperties`
* Create a `VkInstance` using the above functions.
* Call `DVulkan.reload(instance)` to load the rest of the functions.
* (Optional) Call `DVulkan.reload(device)` once you have a `VkDevice` to load specific functions for a device.

The API is similar to the C Vulkan API, but with some differences:
* Since enums in D are not global, you need to specify the enum type. Ex: `VkResult.VK_SUCCESS` instead of just `VK_SUCCESS`.
* All structures have their `sType` field set to the appropriate value upon initialization; explicit initialization is not needed.
* `VkPipelineShaderStageCreateInfo.module` has been renamed to `VkPipelineShaderStageCreateInfo._module`, since `module` is a D keyword.

Examples can be found in the `examples` directory, and ran with `dub run dvulkan:examplename`.

Bindings for all extensions are available, except for the `VK_KHR_*_surface` extensions, which require types from external libraries (X11, XCB, ...). They can be manually loaded with `vkGetInstanceProcAddr` if needed.

Generating Bindings
-------------------

To generate bindings, download the [Vulkan-Docs](https://github.com/KhronosGroup/Vulkan-Docs) repo, copy/move/symlink `vkdgen.py` into `src/spec/`, `cd` there, and execute it, passing in an output folder to place the D files. Requires Python 3.
