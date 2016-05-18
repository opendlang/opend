
import std.stdio;
import std.range;
import std.array;
import std.algorithm;
import std.exception;
import std.conv;
import std.string;

import erupted;

private void enforceVK(VkResult res) {
	enforce(res == VK_SUCCESS, res.to!string);
}

int main() {
	DerelictErupted.load();
	
	uint numLayerProps;
	enforceVK(vkEnumerateInstanceLayerProperties(&numLayerProps, null));
	auto layerProps = new VkLayerProperties[](numLayerProps);
	enforceVK(vkEnumerateInstanceLayerProperties(&numLayerProps, layerProps.ptr));
	
	writeln;
	writeln("Instance Layers:");
	writeln("================");
	foreach(i, const ref layer; layerProps) {
		if(i != 0)
			writeln("\t----------------------");
		writeln("\t", layer.layerName.ptr.fromStringz);
		writeln("\tVulkan Version: ", VK_VERSION_MAJOR(layer.specVersion), ".", VK_VERSION_MINOR(layer.specVersion), ".", VK_VERSION_PATCH(layer.specVersion));
		writeln("\tLayer Version: ", layer.implementationVersion);
		writeln("\t", layer.description.ptr.fromStringz);
	}

	writeln;
	
	VkApplicationInfo appInfo = {
		pApplicationName: "Vulkan Test",
		apiVersion: VK_MAKE_VERSION(1, 0, 2),
	};
	
	VkInstanceCreateInfo instInfo = {
		pApplicationInfo: &appInfo,
	};
	
	VkInstance instance;
	enforceVK(vkCreateInstance(&instInfo, null, &instance));
	loadInstanceLevelFunctions(instance);
	scope(exit) vkDestroyInstance(instance, null);
	
	uint numDevices;
	enforceVK(vkEnumeratePhysicalDevices(instance, &numDevices, null));
	auto physDevices = new VkPhysicalDevice[](numDevices);
	enforceVK(vkEnumeratePhysicalDevices(instance, &numDevices, physDevices.ptr));
	
	foreach(i, ref physDevice; physDevices) {
		writeln("Device ", i+1, " layers:");
		writeln("================");
		
		enforceVK(vkEnumerateDeviceLayerProperties(physDevice, &numLayerProps, null));
		layerProps = new VkLayerProperties[](numLayerProps);
		enforceVK(vkEnumerateDeviceLayerProperties(physDevice, &numLayerProps, layerProps.ptr));
		
		foreach(j, const ref layer; layerProps) {
			if(j != 0)
				writeln("\t----------------------");
			writeln("\t", layer.layerName.ptr.fromStringz);
			writeln("\tVulkan Version: ", VK_VERSION_MAJOR(layer.specVersion), ".", VK_VERSION_MINOR(layer.specVersion), ".", VK_VERSION_PATCH(layer.specVersion));
			writeln("\tLayer Version: ", layer.implementationVersion);
			writeln("\t", layer.description.ptr.fromStringz);
		}
	}
	
	return 0;
}