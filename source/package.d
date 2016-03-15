
module dvulkan;
public import dvulkan.types;
version(DVulkanStatic)
	public import dvulkan.statfun;
else
	public import dvulkan.dynload;

