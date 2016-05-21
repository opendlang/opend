module erupted.functions;

public import erupted.types;

extern(System) @nogc nothrow {

	// VK_VERSION_1_0
	alias PFN_vkCreateInstance = VkResult function(const(VkInstanceCreateInfo)* pCreateInfo, const(VkAllocationCallbacks)* pAllocator, VkInstance* pInstance);
	alias PFN_vkDestroyInstance = void function(VkInstance instance, const(VkAllocationCallbacks)* pAllocator);
	alias PFN_vkEnumeratePhysicalDevices = VkResult function(VkInstance instance, uint32_t* pPhysicalDeviceCount, VkPhysicalDevice* pPhysicalDevices);
	alias PFN_vkGetPhysicalDeviceFeatures = void function(VkPhysicalDevice physicalDevice, VkPhysicalDeviceFeatures* pFeatures);
	alias PFN_vkGetPhysicalDeviceFormatProperties = void function(VkPhysicalDevice physicalDevice, VkFormat format, VkFormatProperties* pFormatProperties);
	alias PFN_vkGetPhysicalDeviceImageFormatProperties = VkResult function(VkPhysicalDevice physicalDevice, VkFormat format, VkImageType type, VkImageTiling tiling, VkImageUsageFlags usage, VkImageCreateFlags flags, VkImageFormatProperties* pImageFormatProperties);
	alias PFN_vkGetPhysicalDeviceProperties = void function(VkPhysicalDevice physicalDevice, VkPhysicalDeviceProperties* pProperties);
	alias PFN_vkGetPhysicalDeviceQueueFamilyProperties = void function(VkPhysicalDevice physicalDevice, uint32_t* pQueueFamilyPropertyCount, VkQueueFamilyProperties* pQueueFamilyProperties);
	alias PFN_vkGetPhysicalDeviceMemoryProperties = void function(VkPhysicalDevice physicalDevice, VkPhysicalDeviceMemoryProperties* pMemoryProperties);
	alias PFN_vkGetInstanceProcAddr = PFN_vkVoidFunction function(VkInstance instance, const(char)* pName);
	alias PFN_vkGetDeviceProcAddr = PFN_vkVoidFunction function(VkDevice device, const(char)* pName);
	alias PFN_vkCreateDevice = VkResult function(VkPhysicalDevice physicalDevice, const(VkDeviceCreateInfo)* pCreateInfo, const(VkAllocationCallbacks)* pAllocator, VkDevice* pDevice);
	alias PFN_vkDestroyDevice = void function(VkDevice device, const(VkAllocationCallbacks)* pAllocator);
	alias PFN_vkEnumerateInstanceExtensionProperties = VkResult function(const(char)* pLayerName, uint32_t* pPropertyCount, VkExtensionProperties* pProperties);
	alias PFN_vkEnumerateDeviceExtensionProperties = VkResult function(VkPhysicalDevice physicalDevice, const(char)* pLayerName, uint32_t* pPropertyCount, VkExtensionProperties* pProperties);
	alias PFN_vkEnumerateInstanceLayerProperties = VkResult function(uint32_t* pPropertyCount, VkLayerProperties* pProperties);
	alias PFN_vkEnumerateDeviceLayerProperties = VkResult function(VkPhysicalDevice physicalDevice, uint32_t* pPropertyCount, VkLayerProperties* pProperties);
	alias PFN_vkGetDeviceQueue = void function(VkDevice device, uint32_t queueFamilyIndex, uint32_t queueIndex, VkQueue* pQueue);
	alias PFN_vkQueueSubmit = VkResult function(VkQueue queue, uint32_t submitCount, const(VkSubmitInfo)* pSubmits, VkFence fence);
	alias PFN_vkQueueWaitIdle = VkResult function(VkQueue queue);
	alias PFN_vkDeviceWaitIdle = VkResult function(VkDevice device);
	alias PFN_vkAllocateMemory = VkResult function(VkDevice device, const(VkMemoryAllocateInfo)* pAllocateInfo, const(VkAllocationCallbacks)* pAllocator, VkDeviceMemory* pMemory);
	alias PFN_vkFreeMemory = void function(VkDevice device, VkDeviceMemory memory, const(VkAllocationCallbacks)* pAllocator);
	alias PFN_vkMapMemory = VkResult function(VkDevice device, VkDeviceMemory memory, VkDeviceSize offset, VkDeviceSize size, VkMemoryMapFlags flags, void** ppData);
	alias PFN_vkUnmapMemory = void function(VkDevice device, VkDeviceMemory memory);
	alias PFN_vkFlushMappedMemoryRanges = VkResult function(VkDevice device, uint32_t memoryRangeCount, const(VkMappedMemoryRange)* pMemoryRanges);
	alias PFN_vkInvalidateMappedMemoryRanges = VkResult function(VkDevice device, uint32_t memoryRangeCount, const(VkMappedMemoryRange)* pMemoryRanges);
	alias PFN_vkGetDeviceMemoryCommitment = void function(VkDevice device, VkDeviceMemory memory, VkDeviceSize* pCommittedMemoryInBytes);
	alias PFN_vkBindBufferMemory = VkResult function(VkDevice device, VkBuffer buffer, VkDeviceMemory memory, VkDeviceSize memoryOffset);
	alias PFN_vkBindImageMemory = VkResult function(VkDevice device, VkImage image, VkDeviceMemory memory, VkDeviceSize memoryOffset);
	alias PFN_vkGetBufferMemoryRequirements = void function(VkDevice device, VkBuffer buffer, VkMemoryRequirements* pMemoryRequirements);
	alias PFN_vkGetImageMemoryRequirements = void function(VkDevice device, VkImage image, VkMemoryRequirements* pMemoryRequirements);
	alias PFN_vkGetImageSparseMemoryRequirements = void function(VkDevice device, VkImage image, uint32_t* pSparseMemoryRequirementCount, VkSparseImageMemoryRequirements* pSparseMemoryRequirements);
	alias PFN_vkGetPhysicalDeviceSparseImageFormatProperties = void function(VkPhysicalDevice physicalDevice, VkFormat format, VkImageType type, VkSampleCountFlagBits samples, VkImageUsageFlags usage, VkImageTiling tiling, uint32_t* pPropertyCount, VkSparseImageFormatProperties* pProperties);
	alias PFN_vkQueueBindSparse = VkResult function(VkQueue queue, uint32_t bindInfoCount, const(VkBindSparseInfo)* pBindInfo, VkFence fence);
	alias PFN_vkCreateFence = VkResult function(VkDevice device, const(VkFenceCreateInfo)* pCreateInfo, const(VkAllocationCallbacks)* pAllocator, VkFence* pFence);
	alias PFN_vkDestroyFence = void function(VkDevice device, VkFence fence, const(VkAllocationCallbacks)* pAllocator);
	alias PFN_vkResetFences = VkResult function(VkDevice device, uint32_t fenceCount, const(VkFence)* pFences);
	alias PFN_vkGetFenceStatus = VkResult function(VkDevice device, VkFence fence);
	alias PFN_vkWaitForFences = VkResult function(VkDevice device, uint32_t fenceCount, const(VkFence)* pFences, VkBool32 waitAll, uint64_t timeout);
	alias PFN_vkCreateSemaphore = VkResult function(VkDevice device, const(VkSemaphoreCreateInfo)* pCreateInfo, const(VkAllocationCallbacks)* pAllocator, VkSemaphore* pSemaphore);
	alias PFN_vkDestroySemaphore = void function(VkDevice device, VkSemaphore semaphore, const(VkAllocationCallbacks)* pAllocator);
	alias PFN_vkCreateEvent = VkResult function(VkDevice device, const(VkEventCreateInfo)* pCreateInfo, const(VkAllocationCallbacks)* pAllocator, VkEvent* pEvent);
	alias PFN_vkDestroyEvent = void function(VkDevice device, VkEvent event, const(VkAllocationCallbacks)* pAllocator);
	alias PFN_vkGetEventStatus = VkResult function(VkDevice device, VkEvent event);
	alias PFN_vkSetEvent = VkResult function(VkDevice device, VkEvent event);
	alias PFN_vkResetEvent = VkResult function(VkDevice device, VkEvent event);
	alias PFN_vkCreateQueryPool = VkResult function(VkDevice device, const(VkQueryPoolCreateInfo)* pCreateInfo, const(VkAllocationCallbacks)* pAllocator, VkQueryPool* pQueryPool);
	alias PFN_vkDestroyQueryPool = void function(VkDevice device, VkQueryPool queryPool, const(VkAllocationCallbacks)* pAllocator);
	alias PFN_vkGetQueryPoolResults = VkResult function(VkDevice device, VkQueryPool queryPool, uint32_t firstQuery, uint32_t queryCount, size_t dataSize, void* pData, VkDeviceSize stride, VkQueryResultFlags flags);
	alias PFN_vkCreateBuffer = VkResult function(VkDevice device, const(VkBufferCreateInfo)* pCreateInfo, const(VkAllocationCallbacks)* pAllocator, VkBuffer* pBuffer);
	alias PFN_vkDestroyBuffer = void function(VkDevice device, VkBuffer buffer, const(VkAllocationCallbacks)* pAllocator);
	alias PFN_vkCreateBufferView = VkResult function(VkDevice device, const(VkBufferViewCreateInfo)* pCreateInfo, const(VkAllocationCallbacks)* pAllocator, VkBufferView* pView);
	alias PFN_vkDestroyBufferView = void function(VkDevice device, VkBufferView bufferView, const(VkAllocationCallbacks)* pAllocator);
	alias PFN_vkCreateImage = VkResult function(VkDevice device, const(VkImageCreateInfo)* pCreateInfo, const(VkAllocationCallbacks)* pAllocator, VkImage* pImage);
	alias PFN_vkDestroyImage = void function(VkDevice device, VkImage image, const(VkAllocationCallbacks)* pAllocator);
	alias PFN_vkGetImageSubresourceLayout = void function(VkDevice device, VkImage image, const(VkImageSubresource)* pSubresource, VkSubresourceLayout* pLayout);
	alias PFN_vkCreateImageView = VkResult function(VkDevice device, const(VkImageViewCreateInfo)* pCreateInfo, const(VkAllocationCallbacks)* pAllocator, VkImageView* pView);
	alias PFN_vkDestroyImageView = void function(VkDevice device, VkImageView imageView, const(VkAllocationCallbacks)* pAllocator);
	alias PFN_vkCreateShaderModule = VkResult function(VkDevice device, const(VkShaderModuleCreateInfo)* pCreateInfo, const(VkAllocationCallbacks)* pAllocator, VkShaderModule* pShaderModule);
	alias PFN_vkDestroyShaderModule = void function(VkDevice device, VkShaderModule shaderModule, const(VkAllocationCallbacks)* pAllocator);
	alias PFN_vkCreatePipelineCache = VkResult function(VkDevice device, const(VkPipelineCacheCreateInfo)* pCreateInfo, const(VkAllocationCallbacks)* pAllocator, VkPipelineCache* pPipelineCache);
	alias PFN_vkDestroyPipelineCache = void function(VkDevice device, VkPipelineCache pipelineCache, const(VkAllocationCallbacks)* pAllocator);
	alias PFN_vkGetPipelineCacheData = VkResult function(VkDevice device, VkPipelineCache pipelineCache, size_t* pDataSize, void* pData);
	alias PFN_vkMergePipelineCaches = VkResult function(VkDevice device, VkPipelineCache dstCache, uint32_t srcCacheCount, const(VkPipelineCache)* pSrcCaches);
	alias PFN_vkCreateGraphicsPipelines = VkResult function(VkDevice device, VkPipelineCache pipelineCache, uint32_t createInfoCount, const(VkGraphicsPipelineCreateInfo)* pCreateInfos, const(VkAllocationCallbacks)* pAllocator, VkPipeline* pPipelines);
	alias PFN_vkCreateComputePipelines = VkResult function(VkDevice device, VkPipelineCache pipelineCache, uint32_t createInfoCount, const(VkComputePipelineCreateInfo)* pCreateInfos, const(VkAllocationCallbacks)* pAllocator, VkPipeline* pPipelines);
	alias PFN_vkDestroyPipeline = void function(VkDevice device, VkPipeline pipeline, const(VkAllocationCallbacks)* pAllocator);
	alias PFN_vkCreatePipelineLayout = VkResult function(VkDevice device, const(VkPipelineLayoutCreateInfo)* pCreateInfo, const(VkAllocationCallbacks)* pAllocator, VkPipelineLayout* pPipelineLayout);
	alias PFN_vkDestroyPipelineLayout = void function(VkDevice device, VkPipelineLayout pipelineLayout, const(VkAllocationCallbacks)* pAllocator);
	alias PFN_vkCreateSampler = VkResult function(VkDevice device, const(VkSamplerCreateInfo)* pCreateInfo, const(VkAllocationCallbacks)* pAllocator, VkSampler* pSampler);
	alias PFN_vkDestroySampler = void function(VkDevice device, VkSampler sampler, const(VkAllocationCallbacks)* pAllocator);
	alias PFN_vkCreateDescriptorSetLayout = VkResult function(VkDevice device, const(VkDescriptorSetLayoutCreateInfo)* pCreateInfo, const(VkAllocationCallbacks)* pAllocator, VkDescriptorSetLayout* pSetLayout);
	alias PFN_vkDestroyDescriptorSetLayout = void function(VkDevice device, VkDescriptorSetLayout descriptorSetLayout, const(VkAllocationCallbacks)* pAllocator);
	alias PFN_vkCreateDescriptorPool = VkResult function(VkDevice device, const(VkDescriptorPoolCreateInfo)* pCreateInfo, const(VkAllocationCallbacks)* pAllocator, VkDescriptorPool* pDescriptorPool);
	alias PFN_vkDestroyDescriptorPool = void function(VkDevice device, VkDescriptorPool descriptorPool, const(VkAllocationCallbacks)* pAllocator);
	alias PFN_vkResetDescriptorPool = VkResult function(VkDevice device, VkDescriptorPool descriptorPool, VkDescriptorPoolResetFlags flags);
	alias PFN_vkAllocateDescriptorSets = VkResult function(VkDevice device, const(VkDescriptorSetAllocateInfo)* pAllocateInfo, VkDescriptorSet* pDescriptorSets);
	alias PFN_vkFreeDescriptorSets = VkResult function(VkDevice device, VkDescriptorPool descriptorPool, uint32_t descriptorSetCount, const(VkDescriptorSet)* pDescriptorSets);
	alias PFN_vkUpdateDescriptorSets = void function(VkDevice device, uint32_t descriptorWriteCount, const(VkWriteDescriptorSet)* pDescriptorWrites, uint32_t descriptorCopyCount, const(VkCopyDescriptorSet)* pDescriptorCopies);
	alias PFN_vkCreateFramebuffer = VkResult function(VkDevice device, const(VkFramebufferCreateInfo)* pCreateInfo, const(VkAllocationCallbacks)* pAllocator, VkFramebuffer* pFramebuffer);
	alias PFN_vkDestroyFramebuffer = void function(VkDevice device, VkFramebuffer framebuffer, const(VkAllocationCallbacks)* pAllocator);
	alias PFN_vkCreateRenderPass = VkResult function(VkDevice device, const(VkRenderPassCreateInfo)* pCreateInfo, const(VkAllocationCallbacks)* pAllocator, VkRenderPass* pRenderPass);
	alias PFN_vkDestroyRenderPass = void function(VkDevice device, VkRenderPass renderPass, const(VkAllocationCallbacks)* pAllocator);
	alias PFN_vkGetRenderAreaGranularity = void function(VkDevice device, VkRenderPass renderPass, VkExtent2D* pGranularity);
	alias PFN_vkCreateCommandPool = VkResult function(VkDevice device, const(VkCommandPoolCreateInfo)* pCreateInfo, const(VkAllocationCallbacks)* pAllocator, VkCommandPool* pCommandPool);
	alias PFN_vkDestroyCommandPool = void function(VkDevice device, VkCommandPool commandPool, const(VkAllocationCallbacks)* pAllocator);
	alias PFN_vkResetCommandPool = VkResult function(VkDevice device, VkCommandPool commandPool, VkCommandPoolResetFlags flags);
	alias PFN_vkAllocateCommandBuffers = VkResult function(VkDevice device, const(VkCommandBufferAllocateInfo)* pAllocateInfo, VkCommandBuffer* pCommandBuffers);
	alias PFN_vkFreeCommandBuffers = void function(VkDevice device, VkCommandPool commandPool, uint32_t commandBufferCount, const(VkCommandBuffer)* pCommandBuffers);
	alias PFN_vkBeginCommandBuffer = VkResult function(VkCommandBuffer commandBuffer, const(VkCommandBufferBeginInfo)* pBeginInfo);
	alias PFN_vkEndCommandBuffer = VkResult function(VkCommandBuffer commandBuffer);
	alias PFN_vkResetCommandBuffer = VkResult function(VkCommandBuffer commandBuffer, VkCommandBufferResetFlags flags);
	alias PFN_vkCmdBindPipeline = void function(VkCommandBuffer commandBuffer, VkPipelineBindPoint pipelineBindPoint, VkPipeline pipeline);
	alias PFN_vkCmdSetViewport = void function(VkCommandBuffer commandBuffer, uint32_t firstViewport, uint32_t viewportCount, const(VkViewport)* pViewports);
	alias PFN_vkCmdSetScissor = void function(VkCommandBuffer commandBuffer, uint32_t firstScissor, uint32_t scissorCount, const(VkRect2D)* pScissors);
	alias PFN_vkCmdSetLineWidth = void function(VkCommandBuffer commandBuffer, float lineWidth);
	alias PFN_vkCmdSetDepthBias = void function(VkCommandBuffer commandBuffer, float depthBiasConstantFactor, float depthBiasClamp, float depthBiasSlopeFactor);
	alias PFN_vkCmdSetBlendConstants = void function(VkCommandBuffer commandBuffer, const float[4] blendConstants);
	alias PFN_vkCmdSetDepthBounds = void function(VkCommandBuffer commandBuffer, float minDepthBounds, float maxDepthBounds);
	alias PFN_vkCmdSetStencilCompareMask = void function(VkCommandBuffer commandBuffer, VkStencilFaceFlags faceMask, uint32_t compareMask);
	alias PFN_vkCmdSetStencilWriteMask = void function(VkCommandBuffer commandBuffer, VkStencilFaceFlags faceMask, uint32_t writeMask);
	alias PFN_vkCmdSetStencilReference = void function(VkCommandBuffer commandBuffer, VkStencilFaceFlags faceMask, uint32_t reference);
	alias PFN_vkCmdBindDescriptorSets = void function(VkCommandBuffer commandBuffer, VkPipelineBindPoint pipelineBindPoint, VkPipelineLayout layout, uint32_t firstSet, uint32_t descriptorSetCount, const(VkDescriptorSet)* pDescriptorSets, uint32_t dynamicOffsetCount, const(uint32_t)* pDynamicOffsets);
	alias PFN_vkCmdBindIndexBuffer = void function(VkCommandBuffer commandBuffer, VkBuffer buffer, VkDeviceSize offset, VkIndexType indexType);
	alias PFN_vkCmdBindVertexBuffers = void function(VkCommandBuffer commandBuffer, uint32_t firstBinding, uint32_t bindingCount, const(VkBuffer)* pBuffers, const(VkDeviceSize)* pOffsets);
	alias PFN_vkCmdDraw = void function(VkCommandBuffer commandBuffer, uint32_t vertexCount, uint32_t instanceCount, uint32_t firstVertex, uint32_t firstInstance);
	alias PFN_vkCmdDrawIndexed = void function(VkCommandBuffer commandBuffer, uint32_t indexCount, uint32_t instanceCount, uint32_t firstIndex, int32_t vertexOffset, uint32_t firstInstance);
	alias PFN_vkCmdDrawIndirect = void function(VkCommandBuffer commandBuffer, VkBuffer buffer, VkDeviceSize offset, uint32_t drawCount, uint32_t stride);
	alias PFN_vkCmdDrawIndexedIndirect = void function(VkCommandBuffer commandBuffer, VkBuffer buffer, VkDeviceSize offset, uint32_t drawCount, uint32_t stride);
	alias PFN_vkCmdDispatch = void function(VkCommandBuffer commandBuffer, uint32_t x, uint32_t y, uint32_t z);
	alias PFN_vkCmdDispatchIndirect = void function(VkCommandBuffer commandBuffer, VkBuffer buffer, VkDeviceSize offset);
	alias PFN_vkCmdCopyBuffer = void function(VkCommandBuffer commandBuffer, VkBuffer srcBuffer, VkBuffer dstBuffer, uint32_t regionCount, const(VkBufferCopy)* pRegions);
	alias PFN_vkCmdCopyImage = void function(VkCommandBuffer commandBuffer, VkImage srcImage, VkImageLayout srcImageLayout, VkImage dstImage, VkImageLayout dstImageLayout, uint32_t regionCount, const(VkImageCopy)* pRegions);
	alias PFN_vkCmdBlitImage = void function(VkCommandBuffer commandBuffer, VkImage srcImage, VkImageLayout srcImageLayout, VkImage dstImage, VkImageLayout dstImageLayout, uint32_t regionCount, const(VkImageBlit)* pRegions, VkFilter filter);
	alias PFN_vkCmdCopyBufferToImage = void function(VkCommandBuffer commandBuffer, VkBuffer srcBuffer, VkImage dstImage, VkImageLayout dstImageLayout, uint32_t regionCount, const(VkBufferImageCopy)* pRegions);
	alias PFN_vkCmdCopyImageToBuffer = void function(VkCommandBuffer commandBuffer, VkImage srcImage, VkImageLayout srcImageLayout, VkBuffer dstBuffer, uint32_t regionCount, const(VkBufferImageCopy)* pRegions);
	alias PFN_vkCmdUpdateBuffer = void function(VkCommandBuffer commandBuffer, VkBuffer dstBuffer, VkDeviceSize dstOffset, VkDeviceSize dataSize, const(uint32_t)* pData);
	alias PFN_vkCmdFillBuffer = void function(VkCommandBuffer commandBuffer, VkBuffer dstBuffer, VkDeviceSize dstOffset, VkDeviceSize size, uint32_t data);
	alias PFN_vkCmdClearColorImage = void function(VkCommandBuffer commandBuffer, VkImage image, VkImageLayout imageLayout, const(VkClearColorValue)* pColor, uint32_t rangeCount, const(VkImageSubresourceRange)* pRanges);
	alias PFN_vkCmdClearDepthStencilImage = void function(VkCommandBuffer commandBuffer, VkImage image, VkImageLayout imageLayout, const(VkClearDepthStencilValue)* pDepthStencil, uint32_t rangeCount, const(VkImageSubresourceRange)* pRanges);
	alias PFN_vkCmdClearAttachments = void function(VkCommandBuffer commandBuffer, uint32_t attachmentCount, const(VkClearAttachment)* pAttachments, uint32_t rectCount, const(VkClearRect)* pRects);
	alias PFN_vkCmdResolveImage = void function(VkCommandBuffer commandBuffer, VkImage srcImage, VkImageLayout srcImageLayout, VkImage dstImage, VkImageLayout dstImageLayout, uint32_t regionCount, const(VkImageResolve)* pRegions);
	alias PFN_vkCmdSetEvent = void function(VkCommandBuffer commandBuffer, VkEvent event, VkPipelineStageFlags stageMask);
	alias PFN_vkCmdResetEvent = void function(VkCommandBuffer commandBuffer, VkEvent event, VkPipelineStageFlags stageMask);
	alias PFN_vkCmdWaitEvents = void function(VkCommandBuffer commandBuffer, uint32_t eventCount, const(VkEvent)* pEvents, VkPipelineStageFlags srcStageMask, VkPipelineStageFlags dstStageMask, uint32_t memoryBarrierCount, const(VkMemoryBarrier)* pMemoryBarriers, uint32_t bufferMemoryBarrierCount, const(VkBufferMemoryBarrier)* pBufferMemoryBarriers, uint32_t imageMemoryBarrierCount, const(VkImageMemoryBarrier)* pImageMemoryBarriers);
	alias PFN_vkCmdPipelineBarrier = void function(VkCommandBuffer commandBuffer, VkPipelineStageFlags srcStageMask, VkPipelineStageFlags dstStageMask, VkDependencyFlags dependencyFlags, uint32_t memoryBarrierCount, const(VkMemoryBarrier)* pMemoryBarriers, uint32_t bufferMemoryBarrierCount, const(VkBufferMemoryBarrier)* pBufferMemoryBarriers, uint32_t imageMemoryBarrierCount, const(VkImageMemoryBarrier)* pImageMemoryBarriers);
	alias PFN_vkCmdBeginQuery = void function(VkCommandBuffer commandBuffer, VkQueryPool queryPool, uint32_t query, VkQueryControlFlags flags);
	alias PFN_vkCmdEndQuery = void function(VkCommandBuffer commandBuffer, VkQueryPool queryPool, uint32_t query);
	alias PFN_vkCmdResetQueryPool = void function(VkCommandBuffer commandBuffer, VkQueryPool queryPool, uint32_t firstQuery, uint32_t queryCount);
	alias PFN_vkCmdWriteTimestamp = void function(VkCommandBuffer commandBuffer, VkPipelineStageFlagBits pipelineStage, VkQueryPool queryPool, uint32_t query);
	alias PFN_vkCmdCopyQueryPoolResults = void function(VkCommandBuffer commandBuffer, VkQueryPool queryPool, uint32_t firstQuery, uint32_t queryCount, VkBuffer dstBuffer, VkDeviceSize dstOffset, VkDeviceSize stride, VkQueryResultFlags flags);
	alias PFN_vkCmdPushConstants = void function(VkCommandBuffer commandBuffer, VkPipelineLayout layout, VkShaderStageFlags stageFlags, uint32_t offset, uint32_t size, const(void)* pValues);
	alias PFN_vkCmdBeginRenderPass = void function(VkCommandBuffer commandBuffer, const(VkRenderPassBeginInfo)* pRenderPassBegin, VkSubpassContents contents);
	alias PFN_vkCmdNextSubpass = void function(VkCommandBuffer commandBuffer, VkSubpassContents contents);
	alias PFN_vkCmdEndRenderPass = void function(VkCommandBuffer commandBuffer);
	alias PFN_vkCmdExecuteCommands = void function(VkCommandBuffer commandBuffer, uint32_t commandBufferCount, const(VkCommandBuffer)* pCommandBuffers);

	// VK_KHR_surface
	alias PFN_vkDestroySurfaceKHR = void function(VkInstance instance, VkSurfaceKHR surface, const(VkAllocationCallbacks)* pAllocator);
	alias PFN_vkGetPhysicalDeviceSurfaceSupportKHR = VkResult function(VkPhysicalDevice physicalDevice, uint32_t queueFamilyIndex, VkSurfaceKHR surface, VkBool32* pSupported);
	alias PFN_vkGetPhysicalDeviceSurfaceCapabilitiesKHR = VkResult function(VkPhysicalDevice physicalDevice, VkSurfaceKHR surface, VkSurfaceCapabilitiesKHR* pSurfaceCapabilities);
	alias PFN_vkGetPhysicalDeviceSurfaceFormatsKHR = VkResult function(VkPhysicalDevice physicalDevice, VkSurfaceKHR surface, uint32_t* pSurfaceFormatCount, VkSurfaceFormatKHR* pSurfaceFormats);
	alias PFN_vkGetPhysicalDeviceSurfacePresentModesKHR = VkResult function(VkPhysicalDevice physicalDevice, VkSurfaceKHR surface, uint32_t* pPresentModeCount, VkPresentModeKHR* pPresentModes);

	// VK_KHR_swapchain
	alias PFN_vkCreateSwapchainKHR = VkResult function(VkDevice device, const(VkSwapchainCreateInfoKHR)* pCreateInfo, const(VkAllocationCallbacks)* pAllocator, VkSwapchainKHR* pSwapchain);
	alias PFN_vkDestroySwapchainKHR = void function(VkDevice device, VkSwapchainKHR swapchain, const(VkAllocationCallbacks)* pAllocator);
	alias PFN_vkGetSwapchainImagesKHR = VkResult function(VkDevice device, VkSwapchainKHR swapchain, uint32_t* pSwapchainImageCount, VkImage* pSwapchainImages);
	alias PFN_vkAcquireNextImageKHR = VkResult function(VkDevice device, VkSwapchainKHR swapchain, uint64_t timeout, VkSemaphore semaphore, VkFence fence, uint32_t* pImageIndex);
	alias PFN_vkQueuePresentKHR = VkResult function(VkQueue queue, const(VkPresentInfoKHR)* pPresentInfo);

	// VK_KHR_display
	alias PFN_vkGetPhysicalDeviceDisplayPropertiesKHR = VkResult function(VkPhysicalDevice physicalDevice, uint32_t* pPropertyCount, VkDisplayPropertiesKHR* pProperties);
	alias PFN_vkGetPhysicalDeviceDisplayPlanePropertiesKHR = VkResult function(VkPhysicalDevice physicalDevice, uint32_t* pPropertyCount, VkDisplayPlanePropertiesKHR* pProperties);
	alias PFN_vkGetDisplayPlaneSupportedDisplaysKHR = VkResult function(VkPhysicalDevice physicalDevice, uint32_t planeIndex, uint32_t* pDisplayCount, VkDisplayKHR* pDisplays);
	alias PFN_vkGetDisplayModePropertiesKHR = VkResult function(VkPhysicalDevice physicalDevice, VkDisplayKHR display, uint32_t* pPropertyCount, VkDisplayModePropertiesKHR* pProperties);
	alias PFN_vkCreateDisplayModeKHR = VkResult function(VkPhysicalDevice physicalDevice, VkDisplayKHR display, const(VkDisplayModeCreateInfoKHR)* pCreateInfo, const(VkAllocationCallbacks)* pAllocator, VkDisplayModeKHR* pMode);
	alias PFN_vkGetDisplayPlaneCapabilitiesKHR = VkResult function(VkPhysicalDevice physicalDevice, VkDisplayModeKHR mode, uint32_t planeIndex, VkDisplayPlaneCapabilitiesKHR* pCapabilities);
	alias PFN_vkCreateDisplayPlaneSurfaceKHR = VkResult function(VkInstance instance, const(VkDisplaySurfaceCreateInfoKHR)* pCreateInfo, const(VkAllocationCallbacks)* pAllocator, VkSurfaceKHR* pSurface);

	// VK_KHR_display_swapchain
	alias PFN_vkCreateSharedSwapchainsKHR = VkResult function(VkDevice device, uint32_t swapchainCount, const(VkSwapchainCreateInfoKHR)* pCreateInfos, const(VkAllocationCallbacks)* pAllocator, VkSwapchainKHR* pSwapchains);

	// VK_KHR_xlib_surface
	version(VK_USE_PLATFORM_XLIB_KHR) {
		alias PFN_vkCreateXlibSurfaceKHR = VkResult function(VkInstance instance, const(VkXlibSurfaceCreateInfoKHR)* pCreateInfo, const(VkAllocationCallbacks)* pAllocator, VkSurfaceKHR* pSurface);
		alias PFN_vkGetPhysicalDeviceXlibPresentationSupportKHR = VkBool32 function(VkPhysicalDevice physicalDevice, uint32_t queueFamilyIndex, Display* dpy, VisualID visualID);
	}

	// VK_KHR_xcb_surface
	version(VK_USE_PLATFORM_XCB_KHR) {
		alias PFN_vkCreateXcbSurfaceKHR = VkResult function(VkInstance instance, const(VkXcbSurfaceCreateInfoKHR)* pCreateInfo, const(VkAllocationCallbacks)* pAllocator, VkSurfaceKHR* pSurface);
		alias PFN_vkGetPhysicalDeviceXcbPresentationSupportKHR = VkBool32 function(VkPhysicalDevice physicalDevice, uint32_t queueFamilyIndex, xcb_connection_t* connection, xcb_visualid_t visual_id);
	}

	// VK_KHR_wayland_surface
	version(VK_USE_PLATFORM_WAYLAND_KHR) {
		alias PFN_vkCreateWaylandSurfaceKHR = VkResult function(VkInstance instance, const(VkWaylandSurfaceCreateInfoKHR)* pCreateInfo, const(VkAllocationCallbacks)* pAllocator, VkSurfaceKHR* pSurface);
		alias PFN_vkGetPhysicalDeviceWaylandPresentationSupportKHR = VkBool32 function(VkPhysicalDevice physicalDevice, uint32_t queueFamilyIndex, wl_display* display);
	}

	// VK_KHR_mir_surface
	version(VK_USE_PLATFORM_MIR_KHR) {
		alias PFN_vkCreateMirSurfaceKHR = VkResult function(VkInstance instance, const(VkMirSurfaceCreateInfoKHR)* pCreateInfo, const(VkAllocationCallbacks)* pAllocator, VkSurfaceKHR* pSurface);
		alias PFN_vkGetPhysicalDeviceMirPresentationSupportKHR = VkBool32 function(VkPhysicalDevice physicalDevice, uint32_t queueFamilyIndex, MirConnection* connection);
	}

	// VK_KHR_android_surface
	version(VK_USE_PLATFORM_ANDROID_KHR) {
		alias PFN_vkCreateAndroidSurfaceKHR = VkResult function(VkInstance instance, const(VkAndroidSurfaceCreateInfoKHR)* pCreateInfo, const(VkAllocationCallbacks)* pAllocator, VkSurfaceKHR* pSurface);
	}

	// VK_KHR_win32_surface
	version(VK_USE_PLATFORM_WIN32_KHR) {
		alias PFN_vkCreateWin32SurfaceKHR = VkResult function(VkInstance instance, const(VkWin32SurfaceCreateInfoKHR)* pCreateInfo, const(VkAllocationCallbacks)* pAllocator, VkSurfaceKHR* pSurface);
		alias PFN_vkGetPhysicalDeviceWin32PresentationSupportKHR = VkBool32 function(VkPhysicalDevice physicalDevice, uint32_t queueFamilyIndex);
	}

	// VK_EXT_debug_report
	alias PFN_vkCreateDebugReportCallbackEXT = VkResult function(VkInstance instance, const(VkDebugReportCallbackCreateInfoEXT)* pCreateInfo, const(VkAllocationCallbacks)* pAllocator, VkDebugReportCallbackEXT* pCallback);
	alias PFN_vkDestroyDebugReportCallbackEXT = void function(VkInstance instance, VkDebugReportCallbackEXT callback, const(VkAllocationCallbacks)* pAllocator);
	alias PFN_vkDebugReportMessageEXT = void function(VkInstance instance, VkDebugReportFlagsEXT flags, VkDebugReportObjectTypeEXT objectType, uint64_t object, size_t location, int32_t messageCode, const(char)* pLayerPrefix, const(char)* pMessage);

	// VK_EXT_debug_marker
	alias PFN_vkDebugMarkerSetObjectTagEXT = VkResult function(VkDevice device, VkDebugMarkerObjectTagInfoEXT* pTagInfo);
	alias PFN_vkDebugMarkerSetObjectNameEXT = VkResult function(VkDevice device, VkDebugMarkerObjectNameInfoEXT* pNameInfo);
	alias PFN_vkCmdDebugMarkerBeginEXT = void function(VkCommandBuffer commandBuffer, VkDebugMarkerMarkerInfoEXT* pMarkerInfo);
	alias PFN_vkCmdDebugMarkerEndEXT = void function(VkCommandBuffer commandBuffer);
	alias PFN_vkCmdDebugMarkerInsertEXT = void function(VkCommandBuffer commandBuffer, VkDebugMarkerMarkerInfoEXT* pMarkerInfo);
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
	version(VK_USE_PLATFORM_XLIB_KHR) {
		PFN_vkCreateXlibSurfaceKHR vkCreateXlibSurfaceKHR;
		PFN_vkGetPhysicalDeviceXlibPresentationSupportKHR vkGetPhysicalDeviceXlibPresentationSupportKHR;
	}

	// VK_KHR_xcb_surface
	version(VK_USE_PLATFORM_XCB_KHR) {
		PFN_vkCreateXcbSurfaceKHR vkCreateXcbSurfaceKHR;
		PFN_vkGetPhysicalDeviceXcbPresentationSupportKHR vkGetPhysicalDeviceXcbPresentationSupportKHR;
	}

	// VK_KHR_wayland_surface
	version(VK_USE_PLATFORM_WAYLAND_KHR) {
		PFN_vkCreateWaylandSurfaceKHR vkCreateWaylandSurfaceKHR;
		PFN_vkGetPhysicalDeviceWaylandPresentationSupportKHR vkGetPhysicalDeviceWaylandPresentationSupportKHR;
	}

	// VK_KHR_mir_surface
	version(VK_USE_PLATFORM_MIR_KHR) {
		PFN_vkCreateMirSurfaceKHR vkCreateMirSurfaceKHR;
		PFN_vkGetPhysicalDeviceMirPresentationSupportKHR vkGetPhysicalDeviceMirPresentationSupportKHR;
	}

	// VK_KHR_android_surface
	version(VK_USE_PLATFORM_ANDROID_KHR) {
		PFN_vkCreateAndroidSurfaceKHR vkCreateAndroidSurfaceKHR;
	}

	// VK_KHR_win32_surface
	version(VK_USE_PLATFORM_WIN32_KHR) {
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

/// if not using version "with-derelict-loader" this function must be called first
/// sets vkCreateInstance function pointer and acquires basic functions to retrieve information about the implementation
void loadGlobalLevelFunctions(typeof(vkGetInstanceProcAddr) getProcAddr) {
	vkGetInstanceProcAddr = getProcAddr;
	vkEnumerateInstanceExtensionProperties = cast(typeof(vkEnumerateInstanceExtensionProperties)) vkGetInstanceProcAddr(null, "vkEnumerateInstanceExtensionProperties");
	vkEnumerateInstanceLayerProperties = cast(typeof(vkEnumerateInstanceLayerProperties)) vkGetInstanceProcAddr(null, "vkEnumerateInstanceLayerProperties");
	vkCreateInstance = cast(typeof(vkCreateInstance)) vkGetInstanceProcAddr(null, "vkCreateInstance");
}

/// with a valid VkInstance call this function to retrieve additional VkInstance, VkPhysicalDevice, ... related functions
void loadInstanceLevelFunctions(VkInstance instance) {
	assert(vkGetInstanceProcAddr !is null, "Must call loadGlobalLevelFunctions before loadInstanceLevelFunctions");

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
	version(VK_USE_PLATFORM_XLIB_KHR) {
		vkCreateXlibSurfaceKHR = cast(typeof(vkCreateXlibSurfaceKHR)) vkGetInstanceProcAddr(instance, "vkCreateXlibSurfaceKHR");
		vkGetPhysicalDeviceXlibPresentationSupportKHR = cast(typeof(vkGetPhysicalDeviceXlibPresentationSupportKHR)) vkGetInstanceProcAddr(instance, "vkGetPhysicalDeviceXlibPresentationSupportKHR");
	}

	// VK_KHR_xcb_surface
	version(VK_USE_PLATFORM_XCB_KHR) {
		vkCreateXcbSurfaceKHR = cast(typeof(vkCreateXcbSurfaceKHR)) vkGetInstanceProcAddr(instance, "vkCreateXcbSurfaceKHR");
		vkGetPhysicalDeviceXcbPresentationSupportKHR = cast(typeof(vkGetPhysicalDeviceXcbPresentationSupportKHR)) vkGetInstanceProcAddr(instance, "vkGetPhysicalDeviceXcbPresentationSupportKHR");
	}

	// VK_KHR_wayland_surface
	version(VK_USE_PLATFORM_WAYLAND_KHR) {
		vkCreateWaylandSurfaceKHR = cast(typeof(vkCreateWaylandSurfaceKHR)) vkGetInstanceProcAddr(instance, "vkCreateWaylandSurfaceKHR");
		vkGetPhysicalDeviceWaylandPresentationSupportKHR = cast(typeof(vkGetPhysicalDeviceWaylandPresentationSupportKHR)) vkGetInstanceProcAddr(instance, "vkGetPhysicalDeviceWaylandPresentationSupportKHR");
	}

	// VK_KHR_mir_surface
	version(VK_USE_PLATFORM_MIR_KHR) {
		vkCreateMirSurfaceKHR = cast(typeof(vkCreateMirSurfaceKHR)) vkGetInstanceProcAddr(instance, "vkCreateMirSurfaceKHR");
		vkGetPhysicalDeviceMirPresentationSupportKHR = cast(typeof(vkGetPhysicalDeviceMirPresentationSupportKHR)) vkGetInstanceProcAddr(instance, "vkGetPhysicalDeviceMirPresentationSupportKHR");
	}

	// VK_KHR_android_surface
	version(VK_USE_PLATFORM_ANDROID_KHR) {
		vkCreateAndroidSurfaceKHR = cast(typeof(vkCreateAndroidSurfaceKHR)) vkGetInstanceProcAddr(instance, "vkCreateAndroidSurfaceKHR");
	}

	// VK_KHR_win32_surface
	version(VK_USE_PLATFORM_WIN32_KHR) {
		vkCreateWin32SurfaceKHR = cast(typeof(vkCreateWin32SurfaceKHR)) vkGetInstanceProcAddr(instance, "vkCreateWin32SurfaceKHR");
		vkGetPhysicalDeviceWin32PresentationSupportKHR = cast(typeof(vkGetPhysicalDeviceWin32PresentationSupportKHR)) vkGetInstanceProcAddr(instance, "vkGetPhysicalDeviceWin32PresentationSupportKHR");
	}

	// VK_EXT_debug_report
	vkCreateDebugReportCallbackEXT = cast(typeof(vkCreateDebugReportCallbackEXT)) vkGetInstanceProcAddr(instance, "vkCreateDebugReportCallbackEXT");
	vkDestroyDebugReportCallbackEXT = cast(typeof(vkDestroyDebugReportCallbackEXT)) vkGetInstanceProcAddr(instance, "vkDestroyDebugReportCallbackEXT");
	vkDebugReportMessageEXT = cast(typeof(vkDebugReportMessageEXT)) vkGetInstanceProcAddr(instance, "vkDebugReportMessageEXT");}

/// with a valid VkInstance call this function to retrieve VkDevice, VkQueue and VkCommandBuffer related functions
/// the functions call indirectly through the VkInstance and will be internally dispatched by the implementation
void loadDeviceLevelFunctions(VkInstance instance) {
	assert(vkGetInstanceProcAddr !is null, "Must call loadInstanceLevelFunctions before loadDeviceLevelFunctions");

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
	vkCmdDebugMarkerInsertEXT = cast(typeof(vkCmdDebugMarkerInsertEXT)) vkGetInstanceProcAddr(instance, "vkCmdDebugMarkerInsertEXT");}

/// with a valid VkDevice call this function to retrieve VkDevice, VkQueue and VkCommandBuffer related functions
/// the functions call directly VkDevice and related resources and can be retrieved for one and only one VkDevice
/// otherwise a call to with to VkDevices would overwrite the __gshared functions of another previously called VkDevice
/// use createGroupedDeviceLevelFunctions bellow if usage of multiple VkDevices is required
void loadDeviceLevelFunctions(VkDevice device) {
	assert(vkGetDeviceProcAddr !is null, "Must call loadInstanceLevelFunctions before loadDeviceLevelFunctions");

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
	vkCmdDebugMarkerInsertEXT = cast(typeof(vkCmdDebugMarkerInsertEXT)) vkGetDeviceProcAddr(device, "vkCmdDebugMarkerInsertEXT");}

/// with a valid VkDevice call this function to retrieve VkDevice, VkQueue and VkCommandBuffer related functions grouped in a DispatchDevice struct
/// the functions call directly VkDevice and related resources and can be retrieved for any VkDevice
DispatchDevice createDispatchDeviceLevelFunctions(VkDevice device) {
	assert(vkGetDeviceProcAddr !is null, "Must call loadInstanceLevelFunctions before loadDeviceLevelFunctions");
	
	DispatchDevice dispatchDevice;
	with(dispatchDevice) {

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
	vkCmdDebugMarkerInsertEXT = cast(typeof(vkCmdDebugMarkerInsertEXT)) vkGetDeviceProcAddr(device, "vkCmdDebugMarkerInsertEXT");	}

	return dispatchDevice;
}


// struct to group per device deviceLevelFunctions into a custom namespace
private struct DispatchDevice {
	PFN_vkDestroyDevice vkDestroyDevice;
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
	PFN_vkCreateSwapchainKHR vkCreateSwapchainKHR;
	PFN_vkDestroySwapchainKHR vkDestroySwapchainKHR;
	PFN_vkGetSwapchainImagesKHR vkGetSwapchainImagesKHR;
	PFN_vkAcquireNextImageKHR vkAcquireNextImageKHR;
	PFN_vkQueuePresentKHR vkQueuePresentKHR;
	PFN_vkCreateSharedSwapchainsKHR vkCreateSharedSwapchainsKHR;
	PFN_vkDebugMarkerSetObjectTagEXT vkDebugMarkerSetObjectTagEXT;
	PFN_vkDebugMarkerSetObjectNameEXT vkDebugMarkerSetObjectNameEXT;
	PFN_vkCmdDebugMarkerBeginEXT vkCmdDebugMarkerBeginEXT;
	PFN_vkCmdDebugMarkerEndEXT vkCmdDebugMarkerEndEXT;
	PFN_vkCmdDebugMarkerInsertEXT vkCmdDebugMarkerInsertEXT;
}

// Derelict loader to acquire entry point vkGetInstanceProcAddr
version(ERUPTED_FROM_DERELICT) {
	import derelict.util.loader;
	import derelict.util.system;
	
	private {
		version(Windows)
			enum libNames = "vulkan-1.dll";

		else version(Posix)
			enum libNames = "libvulkan.so.1";

		else
			static assert(0,"Need to implement Vulkan libNames for this operating system.");
	}
	
	class DerelictEruptedLoader : SharedLibLoader {
		this() {
			super(libNames);
		}
		
		protected override void loadSymbols() {
			typeof(vkGetInstanceProcAddr) getProcAddr;
			bindFunc(cast(void**)&getProcAddr, "vkGetInstanceProcAddr");
			loadGlobalLevelFunctions(getProcAddr);
		}
	}
	
	__gshared DerelictEruptedLoader DerelictErupted;

	shared static this() {
		DerelictErupted = new DerelictEruptedLoader();
	}
}


