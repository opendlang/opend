
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

void destroyinst(VkInstance inst) {
	vkDestroyInstance(inst, null);
}

int main() {
	DVulkan.load();
	
	uint numLayerProps;
	enforceVK(vkEnumerateInstanceLayerProperties(&numLayerProps, null));
	auto layerProps = new VkLayerProperties[](numLayerProps);
	enforceVK(vkEnumerateInstanceLayerProperties(&numLayerProps, layerProps.ptr));
	
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
	
	VkApplicationInfo appInfo; with(appInfo) {
		sType = VkStructureType.VK_STRUCTURE_TYPE_APPLICATION_INFO;
		pApplicationName = "Vulkan Test";
		apiVersion = VK_MAKE_VERSION(1, 0, 2);
	}
	
	VkInstanceCreateInfo instInfo; with(instInfo) {
		sType = VkStructureType.VK_STRUCTURE_TYPE_INSTANCE_CREATE_INFO;
		pApplicationInfo = &appInfo;
	}
	
	VkInstance inst;
	enforceVK(vkCreateInstance(&instInfo, null, &inst));
	DVulkan.reload(inst);
	scope(exit) vkDestroyInstance(inst, null);
	
	uint numDevices;
	enforceVK(vkEnumeratePhysicalDevices(inst, &numDevices, null));
	auto devices = new VkPhysicalDevice[](numDevices);
	enforceVK(vkEnumeratePhysicalDevices(inst, &numDevices, devices.ptr));
	
	foreach(i, ref device; devices) {
		writeln("Device ", i+1, " layers");
		writeln("================");
		
		enforceVK(vkEnumerateDeviceLayerProperties(device, &numLayerProps, null));
		layerProps = new VkLayerProperties[](numLayerProps);
		enforceVK(vkEnumerateDeviceLayerProperties(device, &numLayerProps, layerProps.ptr));
		
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