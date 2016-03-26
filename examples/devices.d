
import std.stdio;
import std.range;
import std.array;
import std.algorithm;
import std.exception;
import std.conv;
import std.string;

import dvulkan;

private void enforceVK(VkResult res) {
	enforce(res == VkResult.VK_SUCCESS, res.to!string);
}

int main() {
	DVulkanDerelict.load();
	
	VkApplicationInfo appInfo = {
		pApplicationName: "Vulkan Test",
		apiVersion: VK_MAKE_VERSION(1, 0, 2),
	};
	
	VkInstanceCreateInfo instInfo = {
		pApplicationInfo: &appInfo,
	};
	
	VkInstance inst;
	enforceVK(vkCreateInstance(&instInfo, null, &inst));
	DVulkanLoader.loadAllFunctions(inst);
	scope(exit) vkDestroyInstance(inst, null);
	
	uint numDevices;
	enforceVK(vkEnumeratePhysicalDevices(inst, &numDevices, null));
	if(numDevices == 0) {
		stderr.writeln("No devices.");
		return 1;
	}
	
	writeln(numDevices, " device(s)\n============");
	
	auto devices = new VkPhysicalDevice[](numDevices);
	enforceVK(vkEnumeratePhysicalDevices(inst, &numDevices, devices.ptr));
	
	foreach(i, device; devices) {
		VkPhysicalDeviceProperties props;
		vkGetPhysicalDeviceProperties(device, &props);
		writeln("Device ", i, ": ", props.deviceName.ptr.fromStringz);
		writeln("--------------------");
		writeln("API Version: ", VK_VERSION_MAJOR(props.apiVersion), ".", VK_VERSION_MINOR(props.apiVersion), ".", VK_VERSION_PATCH(props.apiVersion));
		writeln("Driver Version: ", props.driverVersion);
		writeln("Device type: ", props.deviceType);
	}
	
	return 0;
}
