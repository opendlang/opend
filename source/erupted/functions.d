module erupted.functions;

public import erupted.types;

extern(System) @nogc nothrow {
}

__gshared {

	// VK_VERSION_1_0
	PFN_vkCreateInstance vkCreateInstance;
	PFN_vkDestroyInstance vkDestroyInstance;
	PFN_vkEnumeratePhysicalDevices vkEnumeratePhysicalDevices;
	PFN_vkGetPhysicalDeviceFeatures vkGetPhysicalDeviceFeatures;
	PFN_vkGetPhysicalDeviceFormatProperties vkGetPhysicalDeviceFormatProperties;
	PFN_vkGetPhysicalDeviceImageFormatProperties vkGetPhysicalDeviceImageFormatProperties;
	PFN_vkGetPhysicalDeviceProperties vkGetPhysicalDeviceProperties;
	PFN_vkGetPhysicalDeviceQueueFamilyProperties vkGetPhysicalDeviceQueueFamilyProperties;
	PFN_vkGetPhysicalDeviceMemoryProperties vkGetPhysicalDeviceMemoryProperties;
	PFN_vkGetInstanceProcAddr vkGetInstanceProcAddr;
	PFN_vkGetDeviceProcAddr vkGetDeviceProcAddr;
	PFN_vkCreateDevice vkCreateDevice;
	PFN_vkDestroyDevice vkDestroyDevice;
	PFN_vkEnumerateInstanceExtensionProperties vkEnumerateInstanceExtensionProperties;
	PFN_vkEnumerateDeviceExtensionProperties vkEnumerateDeviceExtensionProperties;
	PFN_vkEnumerateInstanceLayerProperties vkEnumerateInstanceLayerProperties;
	PFN_vkEnumerateDeviceLayerProperties vkEnumerateDeviceLayerProperties;
	PFN_vkGetDeviceQueue vkGetDeviceQueue;
	PFN_vkQueueSubmit vkQueueSubmit;
	PFN_vkQueueWaitIdle vkQueueWaitIdle;
	PFN_vkDeviceWaitIdle vkDeviceWaitIdle;
	PFN_vkAllocateMemory vkAllocateMemory;
	PFN_vkFreeMemory vkFreeMemory;
	PFN_vkMapMemory vkMapMemory;
	PFN_vkUnmapMemory vkUnmapMemory;
	PFN_vkFlushMappedMemoryRanges vkFlushMappedMemoryRanges;
	PFN_vkInvalidateMappedMemoryRanges vkInvalidateMappedMemoryRanges;
	PFN_vkGetDeviceMemoryCommitment vkGetDeviceMemoryCommitment;
	PFN_vkBindBufferMemory vkBindBufferMemory;
	PFN_vkBindImageMemory vkBindImageMemory;
	PFN_vkGetBufferMemoryRequirements vkGetBufferMemoryRequirements;
	PFN_vkGetImageMemoryRequirements vkGetImageMemoryRequirements;
	PFN_vkGetImageSparseMemoryRequirements vkGetImageSparseMemoryRequirements;
	PFN_vkGetPhysicalDeviceSparseImageFormatProperties vkGetPhysicalDeviceSparseImageFormatProperties;
	PFN_vkQueueBindSparse vkQueueBindSparse;
	PFN_vkCreateFence vkCreateFence;
	PFN_vkDestroyFence vkDestroyFence;
	PFN_vkResetFences vkResetFences;
	PFN_vkGetFenceStatus vkGetFenceStatus;
	PFN_vkWaitForFences vkWaitForFences;
	PFN_vkCreateSemaphore vkCreateSemaphore;
	PFN_vkDestroySemaphore vkDestroySemaphore;
	PFN_vkCreateEvent vkCreateEvent;
	PFN_vkDestroyEvent vkDestroyEvent;
	PFN_vkGetEventStatus vkGetEventStatus;
	PFN_vkSetEvent vkSetEvent;
	PFN_vkResetEvent vkResetEvent;
	PFN_vkCreateQueryPool vkCreateQueryPool;
	PFN_vkDestroyQueryPool vkDestroyQueryPool;
	PFN_vkGetQueryPoolResults vkGetQueryPoolResults;
	PFN_vkCreateBuffer vkCreateBuffer;
	PFN_vkDestroyBuffer vkDestroyBuffer;
	PFN_vkCreateBufferView vkCreateBufferView;
	PFN_vkDestroyBufferView vkDestroyBufferView;
	PFN_vkCreateImage vkCreateImage;
	PFN_vkDestroyImage vkDestroyImage;
	PFN_vkGetImageSubresourceLayout vkGetImageSubresourceLayout;
	PFN_vkCreateImageView vkCreateImageView;
	PFN_vkDestroyImageView vkDestroyImageView;
	PFN_vkCreateShaderModule vkCreateShaderModule;
	PFN_vkDestroyShaderModule vkDestroyShaderModule;
	PFN_vkCreatePipelineCache vkCreatePipelineCache;
	PFN_vkDestroyPipelineCache vkDestroyPipelineCache;
	PFN_vkGetPipelineCacheData vkGetPipelineCacheData;
	PFN_vkMergePipelineCaches vkMergePipelineCaches;
	PFN_vkCreateGraphicsPipelines vkCreateGraphicsPipelines;
	PFN_vkCreateComputePipelines vkCreateComputePipelines;
	PFN_vkDestroyPipeline vkDestroyPipeline;
	PFN_vkCreatePipelineLayout vkCreatePipelineLayout;
	PFN_vkDestroyPipelineLayout vkDestroyPipelineLayout;
	PFN_vkCreateSampler vkCreateSampler;
	PFN_vkDestroySampler vkDestroySampler;
	PFN_vkCreateDescriptorSetLayout vkCreateDescriptorSetLayout;
	PFN_vkDestroyDescriptorSetLayout vkDestroyDescriptorSetLayout;
	PFN_vkCreateDescriptorPool vkCreateDescriptorPool;
	PFN_vkDestroyDescriptorPool vkDestroyDescriptorPool;
	PFN_vkResetDescriptorPool vkResetDescriptorPool;
	PFN_vkAllocateDescriptorSets vkAllocateDescriptorSets;
	PFN_vkFreeDescriptorSets vkFreeDescriptorSets;
	PFN_vkUpdateDescriptorSets vkUpdateDescriptorSets;
	PFN_vkCreateFramebuffer vkCreateFramebuffer;
	PFN_vkDestroyFramebuffer vkDestroyFramebuffer;
	PFN_vkCreateRenderPass vkCreateRenderPass;
	PFN_vkDestroyRenderPass vkDestroyRenderPass;
	PFN_vkGetRenderAreaGranularity vkGetRenderAreaGranularity;
	PFN_vkCreateCommandPool vkCreateCommandPool;
	PFN_vkDestroyCommandPool vkDestroyCommandPool;
	PFN_vkResetCommandPool vkResetCommandPool;
	PFN_vkAllocateCommandBuffers vkAllocateCommandBuffers;
	PFN_vkFreeCommandBuffers vkFreeCommandBuffers;
	PFN_vkBeginCommandBuffer vkBeginCommandBuffer;
	PFN_vkEndCommandBuffer vkEndCommandBuffer;
	PFN_vkResetCommandBuffer vkResetCommandBuffer;
	PFN_vkCmdBindPipeline vkCmdBindPipeline;
	PFN_vkCmdSetViewport vkCmdSetViewport;
	PFN_vkCmdSetScissor vkCmdSetScissor;
	PFN_vkCmdSetLineWidth vkCmdSetLineWidth;
	PFN_vkCmdSetDepthBias vkCmdSetDepthBias;
	PFN_vkCmdSetBlendConstants vkCmdSetBlendConstants;
	PFN_vkCmdSetDepthBounds vkCmdSetDepthBounds;
	PFN_vkCmdSetStencilCompareMask vkCmdSetStencilCompareMask;
	PFN_vkCmdSetStencilWriteMask vkCmdSetStencilWriteMask;
	PFN_vkCmdSetStencilReference vkCmdSetStencilReference;
	PFN_vkCmdBindDescriptorSets vkCmdBindDescriptorSets;
	PFN_vkCmdBindIndexBuffer vkCmdBindIndexBuffer;
	PFN_vkCmdBindVertexBuffers vkCmdBindVertexBuffers;
	PFN_vkCmdDraw vkCmdDraw;
	PFN_vkCmdDrawIndexed vkCmdDrawIndexed;
	PFN_vkCmdDrawIndirect vkCmdDrawIndirect;
	PFN_vkCmdDrawIndexedIndirect vkCmdDrawIndexedIndirect;
	PFN_vkCmdDispatch vkCmdDispatch;
	PFN_vkCmdDispatchIndirect vkCmdDispatchIndirect;
	PFN_vkCmdCopyBuffer vkCmdCopyBuffer;
	PFN_vkCmdCopyImage vkCmdCopyImage;
	PFN_vkCmdBlitImage vkCmdBlitImage;
	PFN_vkCmdCopyBufferToImage vkCmdCopyBufferToImage;
	PFN_vkCmdCopyImageToBuffer vkCmdCopyImageToBuffer;
	PFN_vkCmdUpdateBuffer vkCmdUpdateBuffer;
	PFN_vkCmdFillBuffer vkCmdFillBuffer;
	PFN_vkCmdClearColorImage vkCmdClearColorImage;
	PFN_vkCmdClearDepthStencilImage vkCmdClearDepthStencilImage;
	PFN_vkCmdClearAttachments vkCmdClearAttachments;
	PFN_vkCmdResolveImage vkCmdResolveImage;
	PFN_vkCmdSetEvent vkCmdSetEvent;
	PFN_vkCmdResetEvent vkCmdResetEvent;
	PFN_vkCmdWaitEvents vkCmdWaitEvents;
	PFN_vkCmdPipelineBarrier vkCmdPipelineBarrier;
	PFN_vkCmdBeginQuery vkCmdBeginQuery;
	PFN_vkCmdEndQuery vkCmdEndQuery;
	PFN_vkCmdResetQueryPool vkCmdResetQueryPool;
	PFN_vkCmdWriteTimestamp vkCmdWriteTimestamp;
	PFN_vkCmdCopyQueryPoolResults vkCmdCopyQueryPoolResults;
	PFN_vkCmdPushConstants vkCmdPushConstants;
	PFN_vkCmdBeginRenderPass vkCmdBeginRenderPass;
	PFN_vkCmdNextSubpass vkCmdNextSubpass;
	PFN_vkCmdEndRenderPass vkCmdEndRenderPass;
	PFN_vkCmdExecuteCommands vkCmdExecuteCommands;

	// VK_KHR_surface
	PFN_vkDestroySurfaceKHR vkDestroySurfaceKHR;
	PFN_vkGetPhysicalDeviceSurfaceSupportKHR vkGetPhysicalDeviceSurfaceSupportKHR;
	PFN_vkGetPhysicalDeviceSurfaceCapabilitiesKHR vkGetPhysicalDeviceSurfaceCapabilitiesKHR;
	PFN_vkGetPhysicalDeviceSurfaceFormatsKHR vkGetPhysicalDeviceSurfaceFormatsKHR;
	PFN_vkGetPhysicalDeviceSurfacePresentModesKHR vkGetPhysicalDeviceSurfacePresentModesKHR;

	// VK_KHR_swapchain
	PFN_vkCreateSwapchainKHR vkCreateSwapchainKHR;
	PFN_vkDestroySwapchainKHR vkDestroySwapchainKHR;
	PFN_vkGetSwapchainImagesKHR vkGetSwapchainImagesKHR;
	PFN_vkAcquireNextImageKHR vkAcquireNextImageKHR;
	PFN_vkQueuePresentKHR vkQueuePresentKHR;

	// VK_KHR_display
	PFN_vkGetPhysicalDeviceDisplayPropertiesKHR vkGetPhysicalDeviceDisplayPropertiesKHR;
	PFN_vkGetPhysicalDeviceDisplayPlanePropertiesKHR vkGetPhysicalDeviceDisplayPlanePropertiesKHR;
	PFN_vkGetDisplayPlaneSupportedDisplaysKHR vkGetDisplayPlaneSupportedDisplaysKHR;
	PFN_vkGetDisplayModePropertiesKHR vkGetDisplayModePropertiesKHR;
	PFN_vkCreateDisplayModeKHR vkCreateDisplayModeKHR;
	PFN_vkGetDisplayPlaneCapabilitiesKHR vkGetDisplayPlaneCapabilitiesKHR;
	PFN_vkCreateDisplayPlaneSurfaceKHR vkCreateDisplayPlaneSurfaceKHR;

	// VK_KHR_display_swapchain
	PFN_vkCreateSharedSwapchainsKHR vkCreateSharedSwapchainsKHR;

	// VK_KHR_xlib_surface
	version( VK_USE_PLATFORM_XLIB_KHR ) {
		PFN_vkCreateXlibSurfaceKHR vkCreateXlibSurfaceKHR;
		PFN_vkGetPhysicalDeviceXlibPresentationSupportKHR vkGetPhysicalDeviceXlibPresentationSupportKHR;
	}

	// VK_KHR_xcb_surface
	version( VK_USE_PLATFORM_XCB_KHR ) {
		PFN_vkCreateXcbSurfaceKHR vkCreateXcbSurfaceKHR;
		PFN_vkGetPhysicalDeviceXcbPresentationSupportKHR vkGetPhysicalDeviceXcbPresentationSupportKHR;
	}

	// VK_KHR_wayland_surface
	version( VK_USE_PLATFORM_WAYLAND_KHR ) {
		PFN_vkCreateWaylandSurfaceKHR vkCreateWaylandSurfaceKHR;
		PFN_vkGetPhysicalDeviceWaylandPresentationSupportKHR vkGetPhysicalDeviceWaylandPresentationSupportKHR;
	}

	// VK_KHR_mir_surface
	version( VK_USE_PLATFORM_MIR_KHR ) {
		PFN_vkCreateMirSurfaceKHR vkCreateMirSurfaceKHR;
		PFN_vkGetPhysicalDeviceMirPresentationSupportKHR vkGetPhysicalDeviceMirPresentationSupportKHR;
	}

	// VK_KHR_android_surface
	version( VK_USE_PLATFORM_ANDROID_KHR ) {
		PFN_vkCreateAndroidSurfaceKHR vkCreateAndroidSurfaceKHR;
	}

	// VK_KHR_win32_surface
	version( VK_USE_PLATFORM_WIN32_KHR ) {
		PFN_vkCreateWin32SurfaceKHR vkCreateWin32SurfaceKHR;
		PFN_vkGetPhysicalDeviceWin32PresentationSupportKHR vkGetPhysicalDeviceWin32PresentationSupportKHR;
	}

	// VK_EXT_debug_report
	PFN_vkCreateDebugReportCallbackEXT vkCreateDebugReportCallbackEXT;
	PFN_vkDestroyDebugReportCallbackEXT vkDestroyDebugReportCallbackEXT;
	PFN_vkDebugReportMessageEXT vkDebugReportMessageEXT;

	// VK_EXT_debug_marker
	PFN_vkDebugMarkerSetObjectTagEXT vkDebugMarkerSetObjectTagEXT;
	PFN_vkDebugMarkerSetObjectNameEXT vkDebugMarkerSetObjectNameEXT;
	PFN_vkCmdDebugMarkerBeginEXT vkCmdDebugMarkerBeginEXT;
	PFN_vkCmdDebugMarkerEndEXT vkCmdDebugMarkerEndEXT;
	PFN_vkCmdDebugMarkerInsertEXT vkCmdDebugMarkerInsertEXT;
}

struct EruptedLoader {
	@disable this();
	@disable this(this);

	/// if not using version "with-derelict-loader" this function must be called first
	/// sets vkCreateInstance function pointer and acquires basic functions to retrieve information about the implementation
	static void loadGlobalLevelFunctions(typeof(vkGetInstanceProcAddr) getProcAddr) {
		vkGetInstanceProcAddr = getProcAddr;
		vkEnumerateInstanceExtensionProperties = cast(typeof(vkEnumerateInstanceExtensionProperties)) vkGetInstanceProcAddr(null, "vkEnumerateInstanceExtensionProperties");
		vkEnumerateInstanceLayerProperties = cast(typeof(vkEnumerateInstanceLayerProperties)) vkGetInstanceProcAddr(null, "vkEnumerateInstanceLayerProperties");
		vkCreateInstance = cast(typeof(vkCreateInstance)) vkGetInstanceProcAddr(null, "vkCreateInstance");
	}

	/// with a valid VkInstance call this function to retrieve additional VkInstance, VkPhysicalDevice, ... related functions
	static void loadInstanceLevelFunctions(VkInstance instance) {
		assert(vkGetInstanceProcAddr !is null, "Must call EruptedLoader.loadGlobalLevelFunctions before EruptedLoader.loadInstanceLevelFunctions");

		// VK_VERSION_1_0
		vkDestroyInstance = cast(typeof(vkDestroyInstance)) vkGetInstanceProcAddr(instance, "vkDestroyInstance");
		vkEnumeratePhysicalDevices = cast(typeof(vkEnumeratePhysicalDevices)) vkGetInstanceProcAddr(instance, "vkEnumeratePhysicalDevices");
		vkGetPhysicalDeviceFeatures = cast(typeof(vkGetPhysicalDeviceFeatures)) vkGetInstanceProcAddr(instance, "vkGetPhysicalDeviceFeatures");
		vkGetPhysicalDeviceFormatProperties = cast(typeof(vkGetPhysicalDeviceFormatProperties)) vkGetInstanceProcAddr(instance, "vkGetPhysicalDeviceFormatProperties");
		vkGetPhysicalDeviceImageFormatProperties = cast(typeof(vkGetPhysicalDeviceImageFormatProperties)) vkGetInstanceProcAddr(instance, "vkGetPhysicalDeviceImageFormatProperties");
		vkGetPhysicalDeviceProperties = cast(typeof(vkGetPhysicalDeviceProperties)) vkGetInstanceProcAddr(instance, "vkGetPhysicalDeviceProperties");
		vkGetPhysicalDeviceQueueFamilyProperties = cast(typeof(vkGetPhysicalDeviceQueueFamilyProperties)) vkGetInstanceProcAddr(instance, "vkGetPhysicalDeviceQueueFamilyProperties");
		vkGetPhysicalDeviceMemoryProperties = cast(typeof(vkGetPhysicalDeviceMemoryProperties)) vkGetInstanceProcAddr(instance, "vkGetPhysicalDeviceMemoryProperties");
		vkGetDeviceProcAddr = cast(typeof(vkGetDeviceProcAddr)) vkGetInstanceProcAddr(instance, "vkGetDeviceProcAddr");
		vkCreateDevice = cast(typeof(vkCreateDevice)) vkGetInstanceProcAddr(instance, "vkCreateDevice");
		vkEnumerateDeviceExtensionProperties = cast(typeof(vkEnumerateDeviceExtensionProperties)) vkGetInstanceProcAddr(instance, "vkEnumerateDeviceExtensionProperties");
		vkEnumerateDeviceLayerProperties = cast(typeof(vkEnumerateDeviceLayerProperties)) vkGetInstanceProcAddr(instance, "vkEnumerateDeviceLayerProperties");
		vkGetPhysicalDeviceSparseImageFormatProperties = cast(typeof(vkGetPhysicalDeviceSparseImageFormatProperties)) vkGetInstanceProcAddr(instance, "vkGetPhysicalDeviceSparseImageFormatProperties");

		// VK_KHR_surface
		vkDestroySurfaceKHR = cast(typeof(vkDestroySurfaceKHR)) vkGetInstanceProcAddr(instance, "vkDestroySurfaceKHR");
		vkGetPhysicalDeviceSurfaceSupportKHR = cast(typeof(vkGetPhysicalDeviceSurfaceSupportKHR)) vkGetInstanceProcAddr(instance, "vkGetPhysicalDeviceSurfaceSupportKHR");
		vkGetPhysicalDeviceSurfaceCapabilitiesKHR = cast(typeof(vkGetPhysicalDeviceSurfaceCapabilitiesKHR)) vkGetInstanceProcAddr(instance, "vkGetPhysicalDeviceSurfaceCapabilitiesKHR");
		vkGetPhysicalDeviceSurfaceFormatsKHR = cast(typeof(vkGetPhysicalDeviceSurfaceFormatsKHR)) vkGetInstanceProcAddr(instance, "vkGetPhysicalDeviceSurfaceFormatsKHR");
		vkGetPhysicalDeviceSurfacePresentModesKHR = cast(typeof(vkGetPhysicalDeviceSurfacePresentModesKHR)) vkGetInstanceProcAddr(instance, "vkGetPhysicalDeviceSurfacePresentModesKHR");

		// VK_KHR_display
		vkGetPhysicalDeviceDisplayPropertiesKHR = cast(typeof(vkGetPhysicalDeviceDisplayPropertiesKHR)) vkGetInstanceProcAddr(instance, "vkGetPhysicalDeviceDisplayPropertiesKHR");
		vkGetPhysicalDeviceDisplayPlanePropertiesKHR = cast(typeof(vkGetPhysicalDeviceDisplayPlanePropertiesKHR)) vkGetInstanceProcAddr(instance, "vkGetPhysicalDeviceDisplayPlanePropertiesKHR");
		vkGetDisplayPlaneSupportedDisplaysKHR = cast(typeof(vkGetDisplayPlaneSupportedDisplaysKHR)) vkGetInstanceProcAddr(instance, "vkGetDisplayPlaneSupportedDisplaysKHR");
		vkGetDisplayModePropertiesKHR = cast(typeof(vkGetDisplayModePropertiesKHR)) vkGetInstanceProcAddr(instance, "vkGetDisplayModePropertiesKHR");
		vkCreateDisplayModeKHR = cast(typeof(vkCreateDisplayModeKHR)) vkGetInstanceProcAddr(instance, "vkCreateDisplayModeKHR");
		vkGetDisplayPlaneCapabilitiesKHR = cast(typeof(vkGetDisplayPlaneCapabilitiesKHR)) vkGetInstanceProcAddr(instance, "vkGetDisplayPlaneCapabilitiesKHR");
		vkCreateDisplayPlaneSurfaceKHR = cast(typeof(vkCreateDisplayPlaneSurfaceKHR)) vkGetInstanceProcAddr(instance, "vkCreateDisplayPlaneSurfaceKHR");

		// VK_KHR_xlib_surface
		version( VK_USE_PLATFORM_XLIB_KHR ) {
			vkCreateXlibSurfaceKHR = cast(typeof(vkCreateXlibSurfaceKHR)) vkGetInstanceProcAddr(instance, "vkCreateXlibSurfaceKHR");
			vkGetPhysicalDeviceXlibPresentationSupportKHR = cast(typeof(vkGetPhysicalDeviceXlibPresentationSupportKHR)) vkGetInstanceProcAddr(instance, "vkGetPhysicalDeviceXlibPresentationSupportKHR");
		}

		// VK_KHR_xcb_surface
		version( VK_USE_PLATFORM_XCB_KHR ) {
			vkCreateXcbSurfaceKHR = cast(typeof(vkCreateXcbSurfaceKHR)) vkGetInstanceProcAddr(instance, "vkCreateXcbSurfaceKHR");
			vkGetPhysicalDeviceXcbPresentationSupportKHR = cast(typeof(vkGetPhysicalDeviceXcbPresentationSupportKHR)) vkGetInstanceProcAddr(instance, "vkGetPhysicalDeviceXcbPresentationSupportKHR");
		}

		// VK_KHR_wayland_surface
		version( VK_USE_PLATFORM_WAYLAND_KHR ) {
			vkCreateWaylandSurfaceKHR = cast(typeof(vkCreateWaylandSurfaceKHR)) vkGetInstanceProcAddr(instance, "vkCreateWaylandSurfaceKHR");
			vkGetPhysicalDeviceWaylandPresentationSupportKHR = cast(typeof(vkGetPhysicalDeviceWaylandPresentationSupportKHR)) vkGetInstanceProcAddr(instance, "vkGetPhysicalDeviceWaylandPresentationSupportKHR");
		}

		// VK_KHR_mir_surface
		version( VK_USE_PLATFORM_MIR_KHR ) {
			vkCreateMirSurfaceKHR = cast(typeof(vkCreateMirSurfaceKHR)) vkGetInstanceProcAddr(instance, "vkCreateMirSurfaceKHR");
			vkGetPhysicalDeviceMirPresentationSupportKHR = cast(typeof(vkGetPhysicalDeviceMirPresentationSupportKHR)) vkGetInstanceProcAddr(instance, "vkGetPhysicalDeviceMirPresentationSupportKHR");
		}

		// VK_KHR_android_surface
		version( VK_USE_PLATFORM_ANDROID_KHR ) {
			vkCreateAndroidSurfaceKHR = cast(typeof(vkCreateAndroidSurfaceKHR)) vkGetInstanceProcAddr(instance, "vkCreateAndroidSurfaceKHR");
		}

		// VK_KHR_win32_surface
		version( VK_USE_PLATFORM_WIN32_KHR ) {
			vkCreateWin32SurfaceKHR = cast(typeof(vkCreateWin32SurfaceKHR)) vkGetInstanceProcAddr(instance, "vkCreateWin32SurfaceKHR");
			vkGetPhysicalDeviceWin32PresentationSupportKHR = cast(typeof(vkGetPhysicalDeviceWin32PresentationSupportKHR)) vkGetInstanceProcAddr(instance, "vkGetPhysicalDeviceWin32PresentationSupportKHR");
		}

		// VK_EXT_debug_report
		vkCreateDebugReportCallbackEXT = cast(typeof(vkCreateDebugReportCallbackEXT)) vkGetInstanceProcAddr(instance, "vkCreateDebugReportCallbackEXT");
		vkDestroyDebugReportCallbackEXT = cast(typeof(vkDestroyDebugReportCallbackEXT)) vkGetInstanceProcAddr(instance, "vkDestroyDebugReportCallbackEXT");
		vkDebugReportMessageEXT = cast(typeof(vkDebugReportMessageEXT)) vkGetInstanceProcAddr(instance, "vkDebugReportMessageEXT");
	}

	/// with a valid VkInstance call this function to retrieve VkDevice, VkQueue and VkCommandBuffer related functions
	/// the functions call indirectly through the VkInstance and will be internally dispatched by the implementation
	static void loadDeviceLevelFunctions(VkInstance instance) {
		assert(vkGetInstanceProcAddr !is null, "Must call EruptedLoader.loadInstanceLevelFunctions before EruptedLoader.loadDeviceLevelFunctions");

		// VK_VERSION_1_0
		vkDestroyDevice = cast(typeof(vkDestroyDevice)) vkGetInstanceProcAddr(instance, "vkDestroyDevice");
		vkGetDeviceQueue = cast(typeof(vkGetDeviceQueue)) vkGetInstanceProcAddr(instance, "vkGetDeviceQueue");
		vkQueueSubmit = cast(typeof(vkQueueSubmit)) vkGetInstanceProcAddr(instance, "vkQueueSubmit");
		vkQueueWaitIdle = cast(typeof(vkQueueWaitIdle)) vkGetInstanceProcAddr(instance, "vkQueueWaitIdle");
		vkDeviceWaitIdle = cast(typeof(vkDeviceWaitIdle)) vkGetInstanceProcAddr(instance, "vkDeviceWaitIdle");
		vkAllocateMemory = cast(typeof(vkAllocateMemory)) vkGetInstanceProcAddr(instance, "vkAllocateMemory");
		vkFreeMemory = cast(typeof(vkFreeMemory)) vkGetInstanceProcAddr(instance, "vkFreeMemory");
		vkMapMemory = cast(typeof(vkMapMemory)) vkGetInstanceProcAddr(instance, "vkMapMemory");
		vkUnmapMemory = cast(typeof(vkUnmapMemory)) vkGetInstanceProcAddr(instance, "vkUnmapMemory");
		vkFlushMappedMemoryRanges = cast(typeof(vkFlushMappedMemoryRanges)) vkGetInstanceProcAddr(instance, "vkFlushMappedMemoryRanges");
		vkInvalidateMappedMemoryRanges = cast(typeof(vkInvalidateMappedMemoryRanges)) vkGetInstanceProcAddr(instance, "vkInvalidateMappedMemoryRanges");
		vkGetDeviceMemoryCommitment = cast(typeof(vkGetDeviceMemoryCommitment)) vkGetInstanceProcAddr(instance, "vkGetDeviceMemoryCommitment");
		vkBindBufferMemory = cast(typeof(vkBindBufferMemory)) vkGetInstanceProcAddr(instance, "vkBindBufferMemory");
		vkBindImageMemory = cast(typeof(vkBindImageMemory)) vkGetInstanceProcAddr(instance, "vkBindImageMemory");
		vkGetBufferMemoryRequirements = cast(typeof(vkGetBufferMemoryRequirements)) vkGetInstanceProcAddr(instance, "vkGetBufferMemoryRequirements");
		vkGetImageMemoryRequirements = cast(typeof(vkGetImageMemoryRequirements)) vkGetInstanceProcAddr(instance, "vkGetImageMemoryRequirements");
		vkGetImageSparseMemoryRequirements = cast(typeof(vkGetImageSparseMemoryRequirements)) vkGetInstanceProcAddr(instance, "vkGetImageSparseMemoryRequirements");
		vkQueueBindSparse = cast(typeof(vkQueueBindSparse)) vkGetInstanceProcAddr(instance, "vkQueueBindSparse");
		vkCreateFence = cast(typeof(vkCreateFence)) vkGetInstanceProcAddr(instance, "vkCreateFence");
		vkDestroyFence = cast(typeof(vkDestroyFence)) vkGetInstanceProcAddr(instance, "vkDestroyFence");
		vkResetFences = cast(typeof(vkResetFences)) vkGetInstanceProcAddr(instance, "vkResetFences");
		vkGetFenceStatus = cast(typeof(vkGetFenceStatus)) vkGetInstanceProcAddr(instance, "vkGetFenceStatus");
		vkWaitForFences = cast(typeof(vkWaitForFences)) vkGetInstanceProcAddr(instance, "vkWaitForFences");
		vkCreateSemaphore = cast(typeof(vkCreateSemaphore)) vkGetInstanceProcAddr(instance, "vkCreateSemaphore");
		vkDestroySemaphore = cast(typeof(vkDestroySemaphore)) vkGetInstanceProcAddr(instance, "vkDestroySemaphore");
		vkCreateEvent = cast(typeof(vkCreateEvent)) vkGetInstanceProcAddr(instance, "vkCreateEvent");
		vkDestroyEvent = cast(typeof(vkDestroyEvent)) vkGetInstanceProcAddr(instance, "vkDestroyEvent");
		vkGetEventStatus = cast(typeof(vkGetEventStatus)) vkGetInstanceProcAddr(instance, "vkGetEventStatus");
		vkSetEvent = cast(typeof(vkSetEvent)) vkGetInstanceProcAddr(instance, "vkSetEvent");
		vkResetEvent = cast(typeof(vkResetEvent)) vkGetInstanceProcAddr(instance, "vkResetEvent");
		vkCreateQueryPool = cast(typeof(vkCreateQueryPool)) vkGetInstanceProcAddr(instance, "vkCreateQueryPool");
		vkDestroyQueryPool = cast(typeof(vkDestroyQueryPool)) vkGetInstanceProcAddr(instance, "vkDestroyQueryPool");
		vkGetQueryPoolResults = cast(typeof(vkGetQueryPoolResults)) vkGetInstanceProcAddr(instance, "vkGetQueryPoolResults");
		vkCreateBuffer = cast(typeof(vkCreateBuffer)) vkGetInstanceProcAddr(instance, "vkCreateBuffer");
		vkDestroyBuffer = cast(typeof(vkDestroyBuffer)) vkGetInstanceProcAddr(instance, "vkDestroyBuffer");
		vkCreateBufferView = cast(typeof(vkCreateBufferView)) vkGetInstanceProcAddr(instance, "vkCreateBufferView");
		vkDestroyBufferView = cast(typeof(vkDestroyBufferView)) vkGetInstanceProcAddr(instance, "vkDestroyBufferView");
		vkCreateImage = cast(typeof(vkCreateImage)) vkGetInstanceProcAddr(instance, "vkCreateImage");
		vkDestroyImage = cast(typeof(vkDestroyImage)) vkGetInstanceProcAddr(instance, "vkDestroyImage");
		vkGetImageSubresourceLayout = cast(typeof(vkGetImageSubresourceLayout)) vkGetInstanceProcAddr(instance, "vkGetImageSubresourceLayout");
		vkCreateImageView = cast(typeof(vkCreateImageView)) vkGetInstanceProcAddr(instance, "vkCreateImageView");
		vkDestroyImageView = cast(typeof(vkDestroyImageView)) vkGetInstanceProcAddr(instance, "vkDestroyImageView");
		vkCreateShaderModule = cast(typeof(vkCreateShaderModule)) vkGetInstanceProcAddr(instance, "vkCreateShaderModule");
		vkDestroyShaderModule = cast(typeof(vkDestroyShaderModule)) vkGetInstanceProcAddr(instance, "vkDestroyShaderModule");
		vkCreatePipelineCache = cast(typeof(vkCreatePipelineCache)) vkGetInstanceProcAddr(instance, "vkCreatePipelineCache");
		vkDestroyPipelineCache = cast(typeof(vkDestroyPipelineCache)) vkGetInstanceProcAddr(instance, "vkDestroyPipelineCache");
		vkGetPipelineCacheData = cast(typeof(vkGetPipelineCacheData)) vkGetInstanceProcAddr(instance, "vkGetPipelineCacheData");
		vkMergePipelineCaches = cast(typeof(vkMergePipelineCaches)) vkGetInstanceProcAddr(instance, "vkMergePipelineCaches");
		vkCreateGraphicsPipelines = cast(typeof(vkCreateGraphicsPipelines)) vkGetInstanceProcAddr(instance, "vkCreateGraphicsPipelines");
		vkCreateComputePipelines = cast(typeof(vkCreateComputePipelines)) vkGetInstanceProcAddr(instance, "vkCreateComputePipelines");
		vkDestroyPipeline = cast(typeof(vkDestroyPipeline)) vkGetInstanceProcAddr(instance, "vkDestroyPipeline");
		vkCreatePipelineLayout = cast(typeof(vkCreatePipelineLayout)) vkGetInstanceProcAddr(instance, "vkCreatePipelineLayout");
		vkDestroyPipelineLayout = cast(typeof(vkDestroyPipelineLayout)) vkGetInstanceProcAddr(instance, "vkDestroyPipelineLayout");
		vkCreateSampler = cast(typeof(vkCreateSampler)) vkGetInstanceProcAddr(instance, "vkCreateSampler");
		vkDestroySampler = cast(typeof(vkDestroySampler)) vkGetInstanceProcAddr(instance, "vkDestroySampler");
		vkCreateDescriptorSetLayout = cast(typeof(vkCreateDescriptorSetLayout)) vkGetInstanceProcAddr(instance, "vkCreateDescriptorSetLayout");
		vkDestroyDescriptorSetLayout = cast(typeof(vkDestroyDescriptorSetLayout)) vkGetInstanceProcAddr(instance, "vkDestroyDescriptorSetLayout");
		vkCreateDescriptorPool = cast(typeof(vkCreateDescriptorPool)) vkGetInstanceProcAddr(instance, "vkCreateDescriptorPool");
		vkDestroyDescriptorPool = cast(typeof(vkDestroyDescriptorPool)) vkGetInstanceProcAddr(instance, "vkDestroyDescriptorPool");
		vkResetDescriptorPool = cast(typeof(vkResetDescriptorPool)) vkGetInstanceProcAddr(instance, "vkResetDescriptorPool");
		vkAllocateDescriptorSets = cast(typeof(vkAllocateDescriptorSets)) vkGetInstanceProcAddr(instance, "vkAllocateDescriptorSets");
		vkFreeDescriptorSets = cast(typeof(vkFreeDescriptorSets)) vkGetInstanceProcAddr(instance, "vkFreeDescriptorSets");
		vkUpdateDescriptorSets = cast(typeof(vkUpdateDescriptorSets)) vkGetInstanceProcAddr(instance, "vkUpdateDescriptorSets");
		vkCreateFramebuffer = cast(typeof(vkCreateFramebuffer)) vkGetInstanceProcAddr(instance, "vkCreateFramebuffer");
		vkDestroyFramebuffer = cast(typeof(vkDestroyFramebuffer)) vkGetInstanceProcAddr(instance, "vkDestroyFramebuffer");
		vkCreateRenderPass = cast(typeof(vkCreateRenderPass)) vkGetInstanceProcAddr(instance, "vkCreateRenderPass");
		vkDestroyRenderPass = cast(typeof(vkDestroyRenderPass)) vkGetInstanceProcAddr(instance, "vkDestroyRenderPass");
		vkGetRenderAreaGranularity = cast(typeof(vkGetRenderAreaGranularity)) vkGetInstanceProcAddr(instance, "vkGetRenderAreaGranularity");
		vkCreateCommandPool = cast(typeof(vkCreateCommandPool)) vkGetInstanceProcAddr(instance, "vkCreateCommandPool");
		vkDestroyCommandPool = cast(typeof(vkDestroyCommandPool)) vkGetInstanceProcAddr(instance, "vkDestroyCommandPool");
		vkResetCommandPool = cast(typeof(vkResetCommandPool)) vkGetInstanceProcAddr(instance, "vkResetCommandPool");
		vkAllocateCommandBuffers = cast(typeof(vkAllocateCommandBuffers)) vkGetInstanceProcAddr(instance, "vkAllocateCommandBuffers");
		vkFreeCommandBuffers = cast(typeof(vkFreeCommandBuffers)) vkGetInstanceProcAddr(instance, "vkFreeCommandBuffers");
		vkBeginCommandBuffer = cast(typeof(vkBeginCommandBuffer)) vkGetInstanceProcAddr(instance, "vkBeginCommandBuffer");
		vkEndCommandBuffer = cast(typeof(vkEndCommandBuffer)) vkGetInstanceProcAddr(instance, "vkEndCommandBuffer");
		vkResetCommandBuffer = cast(typeof(vkResetCommandBuffer)) vkGetInstanceProcAddr(instance, "vkResetCommandBuffer");
		vkCmdBindPipeline = cast(typeof(vkCmdBindPipeline)) vkGetInstanceProcAddr(instance, "vkCmdBindPipeline");
		vkCmdSetViewport = cast(typeof(vkCmdSetViewport)) vkGetInstanceProcAddr(instance, "vkCmdSetViewport");
		vkCmdSetScissor = cast(typeof(vkCmdSetScissor)) vkGetInstanceProcAddr(instance, "vkCmdSetScissor");
		vkCmdSetLineWidth = cast(typeof(vkCmdSetLineWidth)) vkGetInstanceProcAddr(instance, "vkCmdSetLineWidth");
		vkCmdSetDepthBias = cast(typeof(vkCmdSetDepthBias)) vkGetInstanceProcAddr(instance, "vkCmdSetDepthBias");
		vkCmdSetBlendConstants = cast(typeof(vkCmdSetBlendConstants)) vkGetInstanceProcAddr(instance, "vkCmdSetBlendConstants");
		vkCmdSetDepthBounds = cast(typeof(vkCmdSetDepthBounds)) vkGetInstanceProcAddr(instance, "vkCmdSetDepthBounds");
		vkCmdSetStencilCompareMask = cast(typeof(vkCmdSetStencilCompareMask)) vkGetInstanceProcAddr(instance, "vkCmdSetStencilCompareMask");
		vkCmdSetStencilWriteMask = cast(typeof(vkCmdSetStencilWriteMask)) vkGetInstanceProcAddr(instance, "vkCmdSetStencilWriteMask");
		vkCmdSetStencilReference = cast(typeof(vkCmdSetStencilReference)) vkGetInstanceProcAddr(instance, "vkCmdSetStencilReference");
		vkCmdBindDescriptorSets = cast(typeof(vkCmdBindDescriptorSets)) vkGetInstanceProcAddr(instance, "vkCmdBindDescriptorSets");
		vkCmdBindIndexBuffer = cast(typeof(vkCmdBindIndexBuffer)) vkGetInstanceProcAddr(instance, "vkCmdBindIndexBuffer");
		vkCmdBindVertexBuffers = cast(typeof(vkCmdBindVertexBuffers)) vkGetInstanceProcAddr(instance, "vkCmdBindVertexBuffers");
		vkCmdDraw = cast(typeof(vkCmdDraw)) vkGetInstanceProcAddr(instance, "vkCmdDraw");
		vkCmdDrawIndexed = cast(typeof(vkCmdDrawIndexed)) vkGetInstanceProcAddr(instance, "vkCmdDrawIndexed");
		vkCmdDrawIndirect = cast(typeof(vkCmdDrawIndirect)) vkGetInstanceProcAddr(instance, "vkCmdDrawIndirect");
		vkCmdDrawIndexedIndirect = cast(typeof(vkCmdDrawIndexedIndirect)) vkGetInstanceProcAddr(instance, "vkCmdDrawIndexedIndirect");
		vkCmdDispatch = cast(typeof(vkCmdDispatch)) vkGetInstanceProcAddr(instance, "vkCmdDispatch");
		vkCmdDispatchIndirect = cast(typeof(vkCmdDispatchIndirect)) vkGetInstanceProcAddr(instance, "vkCmdDispatchIndirect");
		vkCmdCopyBuffer = cast(typeof(vkCmdCopyBuffer)) vkGetInstanceProcAddr(instance, "vkCmdCopyBuffer");
		vkCmdCopyImage = cast(typeof(vkCmdCopyImage)) vkGetInstanceProcAddr(instance, "vkCmdCopyImage");
		vkCmdBlitImage = cast(typeof(vkCmdBlitImage)) vkGetInstanceProcAddr(instance, "vkCmdBlitImage");
		vkCmdCopyBufferToImage = cast(typeof(vkCmdCopyBufferToImage)) vkGetInstanceProcAddr(instance, "vkCmdCopyBufferToImage");
		vkCmdCopyImageToBuffer = cast(typeof(vkCmdCopyImageToBuffer)) vkGetInstanceProcAddr(instance, "vkCmdCopyImageToBuffer");
		vkCmdUpdateBuffer = cast(typeof(vkCmdUpdateBuffer)) vkGetInstanceProcAddr(instance, "vkCmdUpdateBuffer");
		vkCmdFillBuffer = cast(typeof(vkCmdFillBuffer)) vkGetInstanceProcAddr(instance, "vkCmdFillBuffer");
		vkCmdClearColorImage = cast(typeof(vkCmdClearColorImage)) vkGetInstanceProcAddr(instance, "vkCmdClearColorImage");
		vkCmdClearDepthStencilImage = cast(typeof(vkCmdClearDepthStencilImage)) vkGetInstanceProcAddr(instance, "vkCmdClearDepthStencilImage");
		vkCmdClearAttachments = cast(typeof(vkCmdClearAttachments)) vkGetInstanceProcAddr(instance, "vkCmdClearAttachments");
		vkCmdResolveImage = cast(typeof(vkCmdResolveImage)) vkGetInstanceProcAddr(instance, "vkCmdResolveImage");
		vkCmdSetEvent = cast(typeof(vkCmdSetEvent)) vkGetInstanceProcAddr(instance, "vkCmdSetEvent");
		vkCmdResetEvent = cast(typeof(vkCmdResetEvent)) vkGetInstanceProcAddr(instance, "vkCmdResetEvent");
		vkCmdWaitEvents = cast(typeof(vkCmdWaitEvents)) vkGetInstanceProcAddr(instance, "vkCmdWaitEvents");
		vkCmdPipelineBarrier = cast(typeof(vkCmdPipelineBarrier)) vkGetInstanceProcAddr(instance, "vkCmdPipelineBarrier");
		vkCmdBeginQuery = cast(typeof(vkCmdBeginQuery)) vkGetInstanceProcAddr(instance, "vkCmdBeginQuery");
		vkCmdEndQuery = cast(typeof(vkCmdEndQuery)) vkGetInstanceProcAddr(instance, "vkCmdEndQuery");
		vkCmdResetQueryPool = cast(typeof(vkCmdResetQueryPool)) vkGetInstanceProcAddr(instance, "vkCmdResetQueryPool");
		vkCmdWriteTimestamp = cast(typeof(vkCmdWriteTimestamp)) vkGetInstanceProcAddr(instance, "vkCmdWriteTimestamp");
		vkCmdCopyQueryPoolResults = cast(typeof(vkCmdCopyQueryPoolResults)) vkGetInstanceProcAddr(instance, "vkCmdCopyQueryPoolResults");
		vkCmdPushConstants = cast(typeof(vkCmdPushConstants)) vkGetInstanceProcAddr(instance, "vkCmdPushConstants");
		vkCmdBeginRenderPass = cast(typeof(vkCmdBeginRenderPass)) vkGetInstanceProcAddr(instance, "vkCmdBeginRenderPass");
		vkCmdNextSubpass = cast(typeof(vkCmdNextSubpass)) vkGetInstanceProcAddr(instance, "vkCmdNextSubpass");
		vkCmdEndRenderPass = cast(typeof(vkCmdEndRenderPass)) vkGetInstanceProcAddr(instance, "vkCmdEndRenderPass");
		vkCmdExecuteCommands = cast(typeof(vkCmdExecuteCommands)) vkGetInstanceProcAddr(instance, "vkCmdExecuteCommands");

		// VK_KHR_swapchain
		vkCreateSwapchainKHR = cast(typeof(vkCreateSwapchainKHR)) vkGetInstanceProcAddr(instance, "vkCreateSwapchainKHR");
		vkDestroySwapchainKHR = cast(typeof(vkDestroySwapchainKHR)) vkGetInstanceProcAddr(instance, "vkDestroySwapchainKHR");
		vkGetSwapchainImagesKHR = cast(typeof(vkGetSwapchainImagesKHR)) vkGetInstanceProcAddr(instance, "vkGetSwapchainImagesKHR");
		vkAcquireNextImageKHR = cast(typeof(vkAcquireNextImageKHR)) vkGetInstanceProcAddr(instance, "vkAcquireNextImageKHR");
		vkQueuePresentKHR = cast(typeof(vkQueuePresentKHR)) vkGetInstanceProcAddr(instance, "vkQueuePresentKHR");

		// VK_KHR_display_swapchain
		vkCreateSharedSwapchainsKHR = cast(typeof(vkCreateSharedSwapchainsKHR)) vkGetInstanceProcAddr(instance, "vkCreateSharedSwapchainsKHR");

		// VK_EXT_debug_marker
		vkDebugMarkerSetObjectTagEXT = cast(typeof(vkDebugMarkerSetObjectTagEXT)) vkGetInstanceProcAddr(instance, "vkDebugMarkerSetObjectTagEXT");
		vkDebugMarkerSetObjectNameEXT = cast(typeof(vkDebugMarkerSetObjectNameEXT)) vkGetInstanceProcAddr(instance, "vkDebugMarkerSetObjectNameEXT");
		vkCmdDebugMarkerBeginEXT = cast(typeof(vkCmdDebugMarkerBeginEXT)) vkGetInstanceProcAddr(instance, "vkCmdDebugMarkerBeginEXT");
		vkCmdDebugMarkerEndEXT = cast(typeof(vkCmdDebugMarkerEndEXT)) vkGetInstanceProcAddr(instance, "vkCmdDebugMarkerEndEXT");
		vkCmdDebugMarkerInsertEXT = cast(typeof(vkCmdDebugMarkerInsertEXT)) vkGetInstanceProcAddr(instance, "vkCmdDebugMarkerInsertEXT");
	}

	/// with a valid VkDevice call this function to retrieve VkDevice, VkQueue and VkCommandBuffer related functions
	/// the functions call directly VkDevice and related resources and must be retrieved once per logical VkDevice
	static void loadDeviceLevelFunctions(VkDevice device) {
		assert(vkGetDeviceProcAddr !is null, "Must call EruptedLoader.loadInstanceLevelFunctions before EruptedLoader.loadDeviceLevelFunctions");

		// VK_VERSION_1_0
		vkDestroyDevice = cast(typeof(vkDestroyDevice)) vkGetDeviceProcAddr(device, "vkDestroyDevice");
		vkGetDeviceQueue = cast(typeof(vkGetDeviceQueue)) vkGetDeviceProcAddr(device, "vkGetDeviceQueue");
		vkQueueSubmit = cast(typeof(vkQueueSubmit)) vkGetDeviceProcAddr(device, "vkQueueSubmit");
		vkQueueWaitIdle = cast(typeof(vkQueueWaitIdle)) vkGetDeviceProcAddr(device, "vkQueueWaitIdle");
		vkDeviceWaitIdle = cast(typeof(vkDeviceWaitIdle)) vkGetDeviceProcAddr(device, "vkDeviceWaitIdle");
		vkAllocateMemory = cast(typeof(vkAllocateMemory)) vkGetDeviceProcAddr(device, "vkAllocateMemory");
		vkFreeMemory = cast(typeof(vkFreeMemory)) vkGetDeviceProcAddr(device, "vkFreeMemory");
		vkMapMemory = cast(typeof(vkMapMemory)) vkGetDeviceProcAddr(device, "vkMapMemory");
		vkUnmapMemory = cast(typeof(vkUnmapMemory)) vkGetDeviceProcAddr(device, "vkUnmapMemory");
		vkFlushMappedMemoryRanges = cast(typeof(vkFlushMappedMemoryRanges)) vkGetDeviceProcAddr(device, "vkFlushMappedMemoryRanges");
		vkInvalidateMappedMemoryRanges = cast(typeof(vkInvalidateMappedMemoryRanges)) vkGetDeviceProcAddr(device, "vkInvalidateMappedMemoryRanges");
		vkGetDeviceMemoryCommitment = cast(typeof(vkGetDeviceMemoryCommitment)) vkGetDeviceProcAddr(device, "vkGetDeviceMemoryCommitment");
		vkBindBufferMemory = cast(typeof(vkBindBufferMemory)) vkGetDeviceProcAddr(device, "vkBindBufferMemory");
		vkBindImageMemory = cast(typeof(vkBindImageMemory)) vkGetDeviceProcAddr(device, "vkBindImageMemory");
		vkGetBufferMemoryRequirements = cast(typeof(vkGetBufferMemoryRequirements)) vkGetDeviceProcAddr(device, "vkGetBufferMemoryRequirements");
		vkGetImageMemoryRequirements = cast(typeof(vkGetImageMemoryRequirements)) vkGetDeviceProcAddr(device, "vkGetImageMemoryRequirements");
		vkGetImageSparseMemoryRequirements = cast(typeof(vkGetImageSparseMemoryRequirements)) vkGetDeviceProcAddr(device, "vkGetImageSparseMemoryRequirements");
		vkQueueBindSparse = cast(typeof(vkQueueBindSparse)) vkGetDeviceProcAddr(device, "vkQueueBindSparse");
		vkCreateFence = cast(typeof(vkCreateFence)) vkGetDeviceProcAddr(device, "vkCreateFence");
		vkDestroyFence = cast(typeof(vkDestroyFence)) vkGetDeviceProcAddr(device, "vkDestroyFence");
		vkResetFences = cast(typeof(vkResetFences)) vkGetDeviceProcAddr(device, "vkResetFences");
		vkGetFenceStatus = cast(typeof(vkGetFenceStatus)) vkGetDeviceProcAddr(device, "vkGetFenceStatus");
		vkWaitForFences = cast(typeof(vkWaitForFences)) vkGetDeviceProcAddr(device, "vkWaitForFences");
		vkCreateSemaphore = cast(typeof(vkCreateSemaphore)) vkGetDeviceProcAddr(device, "vkCreateSemaphore");
		vkDestroySemaphore = cast(typeof(vkDestroySemaphore)) vkGetDeviceProcAddr(device, "vkDestroySemaphore");
		vkCreateEvent = cast(typeof(vkCreateEvent)) vkGetDeviceProcAddr(device, "vkCreateEvent");
		vkDestroyEvent = cast(typeof(vkDestroyEvent)) vkGetDeviceProcAddr(device, "vkDestroyEvent");
		vkGetEventStatus = cast(typeof(vkGetEventStatus)) vkGetDeviceProcAddr(device, "vkGetEventStatus");
		vkSetEvent = cast(typeof(vkSetEvent)) vkGetDeviceProcAddr(device, "vkSetEvent");
		vkResetEvent = cast(typeof(vkResetEvent)) vkGetDeviceProcAddr(device, "vkResetEvent");
		vkCreateQueryPool = cast(typeof(vkCreateQueryPool)) vkGetDeviceProcAddr(device, "vkCreateQueryPool");
		vkDestroyQueryPool = cast(typeof(vkDestroyQueryPool)) vkGetDeviceProcAddr(device, "vkDestroyQueryPool");
		vkGetQueryPoolResults = cast(typeof(vkGetQueryPoolResults)) vkGetDeviceProcAddr(device, "vkGetQueryPoolResults");
		vkCreateBuffer = cast(typeof(vkCreateBuffer)) vkGetDeviceProcAddr(device, "vkCreateBuffer");
		vkDestroyBuffer = cast(typeof(vkDestroyBuffer)) vkGetDeviceProcAddr(device, "vkDestroyBuffer");
		vkCreateBufferView = cast(typeof(vkCreateBufferView)) vkGetDeviceProcAddr(device, "vkCreateBufferView");
		vkDestroyBufferView = cast(typeof(vkDestroyBufferView)) vkGetDeviceProcAddr(device, "vkDestroyBufferView");
		vkCreateImage = cast(typeof(vkCreateImage)) vkGetDeviceProcAddr(device, "vkCreateImage");
		vkDestroyImage = cast(typeof(vkDestroyImage)) vkGetDeviceProcAddr(device, "vkDestroyImage");
		vkGetImageSubresourceLayout = cast(typeof(vkGetImageSubresourceLayout)) vkGetDeviceProcAddr(device, "vkGetImageSubresourceLayout");
		vkCreateImageView = cast(typeof(vkCreateImageView)) vkGetDeviceProcAddr(device, "vkCreateImageView");
		vkDestroyImageView = cast(typeof(vkDestroyImageView)) vkGetDeviceProcAddr(device, "vkDestroyImageView");
		vkCreateShaderModule = cast(typeof(vkCreateShaderModule)) vkGetDeviceProcAddr(device, "vkCreateShaderModule");
		vkDestroyShaderModule = cast(typeof(vkDestroyShaderModule)) vkGetDeviceProcAddr(device, "vkDestroyShaderModule");
		vkCreatePipelineCache = cast(typeof(vkCreatePipelineCache)) vkGetDeviceProcAddr(device, "vkCreatePipelineCache");
		vkDestroyPipelineCache = cast(typeof(vkDestroyPipelineCache)) vkGetDeviceProcAddr(device, "vkDestroyPipelineCache");
		vkGetPipelineCacheData = cast(typeof(vkGetPipelineCacheData)) vkGetDeviceProcAddr(device, "vkGetPipelineCacheData");
		vkMergePipelineCaches = cast(typeof(vkMergePipelineCaches)) vkGetDeviceProcAddr(device, "vkMergePipelineCaches");
		vkCreateGraphicsPipelines = cast(typeof(vkCreateGraphicsPipelines)) vkGetDeviceProcAddr(device, "vkCreateGraphicsPipelines");
		vkCreateComputePipelines = cast(typeof(vkCreateComputePipelines)) vkGetDeviceProcAddr(device, "vkCreateComputePipelines");
		vkDestroyPipeline = cast(typeof(vkDestroyPipeline)) vkGetDeviceProcAddr(device, "vkDestroyPipeline");
		vkCreatePipelineLayout = cast(typeof(vkCreatePipelineLayout)) vkGetDeviceProcAddr(device, "vkCreatePipelineLayout");
		vkDestroyPipelineLayout = cast(typeof(vkDestroyPipelineLayout)) vkGetDeviceProcAddr(device, "vkDestroyPipelineLayout");
		vkCreateSampler = cast(typeof(vkCreateSampler)) vkGetDeviceProcAddr(device, "vkCreateSampler");
		vkDestroySampler = cast(typeof(vkDestroySampler)) vkGetDeviceProcAddr(device, "vkDestroySampler");
		vkCreateDescriptorSetLayout = cast(typeof(vkCreateDescriptorSetLayout)) vkGetDeviceProcAddr(device, "vkCreateDescriptorSetLayout");
		vkDestroyDescriptorSetLayout = cast(typeof(vkDestroyDescriptorSetLayout)) vkGetDeviceProcAddr(device, "vkDestroyDescriptorSetLayout");
		vkCreateDescriptorPool = cast(typeof(vkCreateDescriptorPool)) vkGetDeviceProcAddr(device, "vkCreateDescriptorPool");
		vkDestroyDescriptorPool = cast(typeof(vkDestroyDescriptorPool)) vkGetDeviceProcAddr(device, "vkDestroyDescriptorPool");
		vkResetDescriptorPool = cast(typeof(vkResetDescriptorPool)) vkGetDeviceProcAddr(device, "vkResetDescriptorPool");
		vkAllocateDescriptorSets = cast(typeof(vkAllocateDescriptorSets)) vkGetDeviceProcAddr(device, "vkAllocateDescriptorSets");
		vkFreeDescriptorSets = cast(typeof(vkFreeDescriptorSets)) vkGetDeviceProcAddr(device, "vkFreeDescriptorSets");
		vkUpdateDescriptorSets = cast(typeof(vkUpdateDescriptorSets)) vkGetDeviceProcAddr(device, "vkUpdateDescriptorSets");
		vkCreateFramebuffer = cast(typeof(vkCreateFramebuffer)) vkGetDeviceProcAddr(device, "vkCreateFramebuffer");
		vkDestroyFramebuffer = cast(typeof(vkDestroyFramebuffer)) vkGetDeviceProcAddr(device, "vkDestroyFramebuffer");
		vkCreateRenderPass = cast(typeof(vkCreateRenderPass)) vkGetDeviceProcAddr(device, "vkCreateRenderPass");
		vkDestroyRenderPass = cast(typeof(vkDestroyRenderPass)) vkGetDeviceProcAddr(device, "vkDestroyRenderPass");
		vkGetRenderAreaGranularity = cast(typeof(vkGetRenderAreaGranularity)) vkGetDeviceProcAddr(device, "vkGetRenderAreaGranularity");
		vkCreateCommandPool = cast(typeof(vkCreateCommandPool)) vkGetDeviceProcAddr(device, "vkCreateCommandPool");
		vkDestroyCommandPool = cast(typeof(vkDestroyCommandPool)) vkGetDeviceProcAddr(device, "vkDestroyCommandPool");
		vkResetCommandPool = cast(typeof(vkResetCommandPool)) vkGetDeviceProcAddr(device, "vkResetCommandPool");
		vkAllocateCommandBuffers = cast(typeof(vkAllocateCommandBuffers)) vkGetDeviceProcAddr(device, "vkAllocateCommandBuffers");
		vkFreeCommandBuffers = cast(typeof(vkFreeCommandBuffers)) vkGetDeviceProcAddr(device, "vkFreeCommandBuffers");
		vkBeginCommandBuffer = cast(typeof(vkBeginCommandBuffer)) vkGetDeviceProcAddr(device, "vkBeginCommandBuffer");
		vkEndCommandBuffer = cast(typeof(vkEndCommandBuffer)) vkGetDeviceProcAddr(device, "vkEndCommandBuffer");
		vkResetCommandBuffer = cast(typeof(vkResetCommandBuffer)) vkGetDeviceProcAddr(device, "vkResetCommandBuffer");
		vkCmdBindPipeline = cast(typeof(vkCmdBindPipeline)) vkGetDeviceProcAddr(device, "vkCmdBindPipeline");
		vkCmdSetViewport = cast(typeof(vkCmdSetViewport)) vkGetDeviceProcAddr(device, "vkCmdSetViewport");
		vkCmdSetScissor = cast(typeof(vkCmdSetScissor)) vkGetDeviceProcAddr(device, "vkCmdSetScissor");
		vkCmdSetLineWidth = cast(typeof(vkCmdSetLineWidth)) vkGetDeviceProcAddr(device, "vkCmdSetLineWidth");
		vkCmdSetDepthBias = cast(typeof(vkCmdSetDepthBias)) vkGetDeviceProcAddr(device, "vkCmdSetDepthBias");
		vkCmdSetBlendConstants = cast(typeof(vkCmdSetBlendConstants)) vkGetDeviceProcAddr(device, "vkCmdSetBlendConstants");
		vkCmdSetDepthBounds = cast(typeof(vkCmdSetDepthBounds)) vkGetDeviceProcAddr(device, "vkCmdSetDepthBounds");
		vkCmdSetStencilCompareMask = cast(typeof(vkCmdSetStencilCompareMask)) vkGetDeviceProcAddr(device, "vkCmdSetStencilCompareMask");
		vkCmdSetStencilWriteMask = cast(typeof(vkCmdSetStencilWriteMask)) vkGetDeviceProcAddr(device, "vkCmdSetStencilWriteMask");
		vkCmdSetStencilReference = cast(typeof(vkCmdSetStencilReference)) vkGetDeviceProcAddr(device, "vkCmdSetStencilReference");
		vkCmdBindDescriptorSets = cast(typeof(vkCmdBindDescriptorSets)) vkGetDeviceProcAddr(device, "vkCmdBindDescriptorSets");
		vkCmdBindIndexBuffer = cast(typeof(vkCmdBindIndexBuffer)) vkGetDeviceProcAddr(device, "vkCmdBindIndexBuffer");
		vkCmdBindVertexBuffers = cast(typeof(vkCmdBindVertexBuffers)) vkGetDeviceProcAddr(device, "vkCmdBindVertexBuffers");
		vkCmdDraw = cast(typeof(vkCmdDraw)) vkGetDeviceProcAddr(device, "vkCmdDraw");
		vkCmdDrawIndexed = cast(typeof(vkCmdDrawIndexed)) vkGetDeviceProcAddr(device, "vkCmdDrawIndexed");
		vkCmdDrawIndirect = cast(typeof(vkCmdDrawIndirect)) vkGetDeviceProcAddr(device, "vkCmdDrawIndirect");
		vkCmdDrawIndexedIndirect = cast(typeof(vkCmdDrawIndexedIndirect)) vkGetDeviceProcAddr(device, "vkCmdDrawIndexedIndirect");
		vkCmdDispatch = cast(typeof(vkCmdDispatch)) vkGetDeviceProcAddr(device, "vkCmdDispatch");
		vkCmdDispatchIndirect = cast(typeof(vkCmdDispatchIndirect)) vkGetDeviceProcAddr(device, "vkCmdDispatchIndirect");
		vkCmdCopyBuffer = cast(typeof(vkCmdCopyBuffer)) vkGetDeviceProcAddr(device, "vkCmdCopyBuffer");
		vkCmdCopyImage = cast(typeof(vkCmdCopyImage)) vkGetDeviceProcAddr(device, "vkCmdCopyImage");
		vkCmdBlitImage = cast(typeof(vkCmdBlitImage)) vkGetDeviceProcAddr(device, "vkCmdBlitImage");
		vkCmdCopyBufferToImage = cast(typeof(vkCmdCopyBufferToImage)) vkGetDeviceProcAddr(device, "vkCmdCopyBufferToImage");
		vkCmdCopyImageToBuffer = cast(typeof(vkCmdCopyImageToBuffer)) vkGetDeviceProcAddr(device, "vkCmdCopyImageToBuffer");
		vkCmdUpdateBuffer = cast(typeof(vkCmdUpdateBuffer)) vkGetDeviceProcAddr(device, "vkCmdUpdateBuffer");
		vkCmdFillBuffer = cast(typeof(vkCmdFillBuffer)) vkGetDeviceProcAddr(device, "vkCmdFillBuffer");
		vkCmdClearColorImage = cast(typeof(vkCmdClearColorImage)) vkGetDeviceProcAddr(device, "vkCmdClearColorImage");
		vkCmdClearDepthStencilImage = cast(typeof(vkCmdClearDepthStencilImage)) vkGetDeviceProcAddr(device, "vkCmdClearDepthStencilImage");
		vkCmdClearAttachments = cast(typeof(vkCmdClearAttachments)) vkGetDeviceProcAddr(device, "vkCmdClearAttachments");
		vkCmdResolveImage = cast(typeof(vkCmdResolveImage)) vkGetDeviceProcAddr(device, "vkCmdResolveImage");
		vkCmdSetEvent = cast(typeof(vkCmdSetEvent)) vkGetDeviceProcAddr(device, "vkCmdSetEvent");
		vkCmdResetEvent = cast(typeof(vkCmdResetEvent)) vkGetDeviceProcAddr(device, "vkCmdResetEvent");
		vkCmdWaitEvents = cast(typeof(vkCmdWaitEvents)) vkGetDeviceProcAddr(device, "vkCmdWaitEvents");
		vkCmdPipelineBarrier = cast(typeof(vkCmdPipelineBarrier)) vkGetDeviceProcAddr(device, "vkCmdPipelineBarrier");
		vkCmdBeginQuery = cast(typeof(vkCmdBeginQuery)) vkGetDeviceProcAddr(device, "vkCmdBeginQuery");
		vkCmdEndQuery = cast(typeof(vkCmdEndQuery)) vkGetDeviceProcAddr(device, "vkCmdEndQuery");
		vkCmdResetQueryPool = cast(typeof(vkCmdResetQueryPool)) vkGetDeviceProcAddr(device, "vkCmdResetQueryPool");
		vkCmdWriteTimestamp = cast(typeof(vkCmdWriteTimestamp)) vkGetDeviceProcAddr(device, "vkCmdWriteTimestamp");
		vkCmdCopyQueryPoolResults = cast(typeof(vkCmdCopyQueryPoolResults)) vkGetDeviceProcAddr(device, "vkCmdCopyQueryPoolResults");
		vkCmdPushConstants = cast(typeof(vkCmdPushConstants)) vkGetDeviceProcAddr(device, "vkCmdPushConstants");
		vkCmdBeginRenderPass = cast(typeof(vkCmdBeginRenderPass)) vkGetDeviceProcAddr(device, "vkCmdBeginRenderPass");
		vkCmdNextSubpass = cast(typeof(vkCmdNextSubpass)) vkGetDeviceProcAddr(device, "vkCmdNextSubpass");
		vkCmdEndRenderPass = cast(typeof(vkCmdEndRenderPass)) vkGetDeviceProcAddr(device, "vkCmdEndRenderPass");
		vkCmdExecuteCommands = cast(typeof(vkCmdExecuteCommands)) vkGetDeviceProcAddr(device, "vkCmdExecuteCommands");

		// VK_KHR_swapchain
		vkCreateSwapchainKHR = cast(typeof(vkCreateSwapchainKHR)) vkGetDeviceProcAddr(device, "vkCreateSwapchainKHR");
		vkDestroySwapchainKHR = cast(typeof(vkDestroySwapchainKHR)) vkGetDeviceProcAddr(device, "vkDestroySwapchainKHR");
		vkGetSwapchainImagesKHR = cast(typeof(vkGetSwapchainImagesKHR)) vkGetDeviceProcAddr(device, "vkGetSwapchainImagesKHR");
		vkAcquireNextImageKHR = cast(typeof(vkAcquireNextImageKHR)) vkGetDeviceProcAddr(device, "vkAcquireNextImageKHR");
		vkQueuePresentKHR = cast(typeof(vkQueuePresentKHR)) vkGetDeviceProcAddr(device, "vkQueuePresentKHR");

		// VK_KHR_display_swapchain
		vkCreateSharedSwapchainsKHR = cast(typeof(vkCreateSharedSwapchainsKHR)) vkGetDeviceProcAddr(device, "vkCreateSharedSwapchainsKHR");

		// VK_EXT_debug_marker
		vkDebugMarkerSetObjectTagEXT = cast(typeof(vkDebugMarkerSetObjectTagEXT)) vkGetDeviceProcAddr(device, "vkDebugMarkerSetObjectTagEXT");
		vkDebugMarkerSetObjectNameEXT = cast(typeof(vkDebugMarkerSetObjectNameEXT)) vkGetDeviceProcAddr(device, "vkDebugMarkerSetObjectNameEXT");
		vkCmdDebugMarkerBeginEXT = cast(typeof(vkCmdDebugMarkerBeginEXT)) vkGetDeviceProcAddr(device, "vkCmdDebugMarkerBeginEXT");
		vkCmdDebugMarkerEndEXT = cast(typeof(vkCmdDebugMarkerEndEXT)) vkGetDeviceProcAddr(device, "vkCmdDebugMarkerEndEXT");
		vkCmdDebugMarkerInsertEXT = cast(typeof(vkCmdDebugMarkerInsertEXT)) vkGetDeviceProcAddr(device, "vkCmdDebugMarkerInsertEXT");
	}
}

version(EruptedLoadFromDerelict) {
	import derelict.util.loader;
	import derelict.util.system;
	
	private {
		version(Windows)
			enum libNames = "vulkan-1.dll";
		else
			static assert(0,"Need to implement Vulkan libNames for this operating system.");
	}
	
	class EruptedDerelictLoader : SharedLibLoader {
		this() {
			super(libNames);
		}
		
		protected override void loadSymbols() {
			typeof(vkGetInstanceProcAddr) getProcAddr;
			bindFunc(cast(void**)&getProcAddr, "vkGetInstanceProcAddr");
			EruptedLoader.loadGlobalLevelFunctions(getProcAddr);
		}
	}
	
	__gshared EruptedDerelictLoader EruptedDerelict;

	shared static this() {
		EruptedDerelict = new EruptedDerelictLoader();
	}
}


