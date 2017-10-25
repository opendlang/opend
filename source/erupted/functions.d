module erupted.functions;

public import erupted.types;

extern( System ) @nogc nothrow {

	// VK_VERSION_1_0
	alias PFN_vkCreateInstance = VkResult function( const( VkInstanceCreateInfo )* pCreateInfo, const( VkAllocationCallbacks )* pAllocator, VkInstance* pInstance );
	alias PFN_vkDestroyInstance = void function( VkInstance instance, const( VkAllocationCallbacks )* pAllocator );
	alias PFN_vkEnumeratePhysicalDevices = VkResult function( VkInstance instance, uint32_t* pPhysicalDeviceCount, VkPhysicalDevice* pPhysicalDevices );
	alias PFN_vkGetPhysicalDeviceFeatures = void function( VkPhysicalDevice physicalDevice, VkPhysicalDeviceFeatures* pFeatures );
	alias PFN_vkGetPhysicalDeviceFormatProperties = void function( VkPhysicalDevice physicalDevice, VkFormat format, VkFormatProperties* pFormatProperties );
	alias PFN_vkGetPhysicalDeviceImageFormatProperties = VkResult function( VkPhysicalDevice physicalDevice, VkFormat format, VkImageType type, VkImageTiling tiling, VkImageUsageFlags usage, VkImageCreateFlags flags, VkImageFormatProperties* pImageFormatProperties );
	alias PFN_vkGetPhysicalDeviceProperties = void function( VkPhysicalDevice physicalDevice, VkPhysicalDeviceProperties* pProperties );
	alias PFN_vkGetPhysicalDeviceQueueFamilyProperties = void function( VkPhysicalDevice physicalDevice, uint32_t* pQueueFamilyPropertyCount, VkQueueFamilyProperties* pQueueFamilyProperties );
	alias PFN_vkGetPhysicalDeviceMemoryProperties = void function( VkPhysicalDevice physicalDevice, VkPhysicalDeviceMemoryProperties* pMemoryProperties );
	alias PFN_vkGetInstanceProcAddr = PFN_vkVoidFunction function( VkInstance instance, const( char )* pName );
	alias PFN_vkGetDeviceProcAddr = PFN_vkVoidFunction function( VkDevice device, const( char )* pName );
	alias PFN_vkCreateDevice = VkResult function( VkPhysicalDevice physicalDevice, const( VkDeviceCreateInfo )* pCreateInfo, const( VkAllocationCallbacks )* pAllocator, VkDevice* pDevice );
	alias PFN_vkDestroyDevice = void function( VkDevice device, const( VkAllocationCallbacks )* pAllocator );
	alias PFN_vkEnumerateInstanceExtensionProperties = VkResult function( const( char )* pLayerName, uint32_t* pPropertyCount, VkExtensionProperties* pProperties );
	alias PFN_vkEnumerateDeviceExtensionProperties = VkResult function( VkPhysicalDevice physicalDevice, const( char )* pLayerName, uint32_t* pPropertyCount, VkExtensionProperties* pProperties );
	alias PFN_vkEnumerateInstanceLayerProperties = VkResult function( uint32_t* pPropertyCount, VkLayerProperties* pProperties );
	alias PFN_vkEnumerateDeviceLayerProperties = VkResult function( VkPhysicalDevice physicalDevice, uint32_t* pPropertyCount, VkLayerProperties* pProperties );
	alias PFN_vkGetDeviceQueue = void function( VkDevice device, uint32_t queueFamilyIndex, uint32_t queueIndex, VkQueue* pQueue );
	alias PFN_vkQueueSubmit = VkResult function( VkQueue queue, uint32_t submitCount, const( VkSubmitInfo )* pSubmits, VkFence fence );
	alias PFN_vkQueueWaitIdle = VkResult function( VkQueue queue );
	alias PFN_vkDeviceWaitIdle = VkResult function( VkDevice device );
	alias PFN_vkAllocateMemory = VkResult function( VkDevice device, const( VkMemoryAllocateInfo )* pAllocateInfo, const( VkAllocationCallbacks )* pAllocator, VkDeviceMemory* pMemory );
	alias PFN_vkFreeMemory = void function( VkDevice device, VkDeviceMemory memory, const( VkAllocationCallbacks )* pAllocator );
	alias PFN_vkMapMemory = VkResult function( VkDevice device, VkDeviceMemory memory, VkDeviceSize offset, VkDeviceSize size, VkMemoryMapFlags flags, void** ppData );
	alias PFN_vkUnmapMemory = void function( VkDevice device, VkDeviceMemory memory );
	alias PFN_vkFlushMappedMemoryRanges = VkResult function( VkDevice device, uint32_t memoryRangeCount, const( VkMappedMemoryRange )* pMemoryRanges );
	alias PFN_vkInvalidateMappedMemoryRanges = VkResult function( VkDevice device, uint32_t memoryRangeCount, const( VkMappedMemoryRange )* pMemoryRanges );
	alias PFN_vkGetDeviceMemoryCommitment = void function( VkDevice device, VkDeviceMemory memory, VkDeviceSize* pCommittedMemoryInBytes );
	alias PFN_vkBindBufferMemory = VkResult function( VkDevice device, VkBuffer buffer, VkDeviceMemory memory, VkDeviceSize memoryOffset );
	alias PFN_vkBindImageMemory = VkResult function( VkDevice device, VkImage image, VkDeviceMemory memory, VkDeviceSize memoryOffset );
	alias PFN_vkGetBufferMemoryRequirements = void function( VkDevice device, VkBuffer buffer, VkMemoryRequirements* pMemoryRequirements );
	alias PFN_vkGetImageMemoryRequirements = void function( VkDevice device, VkImage image, VkMemoryRequirements* pMemoryRequirements );
	alias PFN_vkGetImageSparseMemoryRequirements = void function( VkDevice device, VkImage image, uint32_t* pSparseMemoryRequirementCount, VkSparseImageMemoryRequirements* pSparseMemoryRequirements );
	alias PFN_vkGetPhysicalDeviceSparseImageFormatProperties = void function( VkPhysicalDevice physicalDevice, VkFormat format, VkImageType type, VkSampleCountFlagBits samples, VkImageUsageFlags usage, VkImageTiling tiling, uint32_t* pPropertyCount, VkSparseImageFormatProperties* pProperties );
	alias PFN_vkQueueBindSparse = VkResult function( VkQueue queue, uint32_t bindInfoCount, const( VkBindSparseInfo )* pBindInfo, VkFence fence );
	alias PFN_vkCreateFence = VkResult function( VkDevice device, const( VkFenceCreateInfo )* pCreateInfo, const( VkAllocationCallbacks )* pAllocator, VkFence* pFence );
	alias PFN_vkDestroyFence = void function( VkDevice device, VkFence fence, const( VkAllocationCallbacks )* pAllocator );
	alias PFN_vkResetFences = VkResult function( VkDevice device, uint32_t fenceCount, const( VkFence )* pFences );
	alias PFN_vkGetFenceStatus = VkResult function( VkDevice device, VkFence fence );
	alias PFN_vkWaitForFences = VkResult function( VkDevice device, uint32_t fenceCount, const( VkFence )* pFences, VkBool32 waitAll, uint64_t timeout );
	alias PFN_vkCreateSemaphore = VkResult function( VkDevice device, const( VkSemaphoreCreateInfo )* pCreateInfo, const( VkAllocationCallbacks )* pAllocator, VkSemaphore* pSemaphore );
	alias PFN_vkDestroySemaphore = void function( VkDevice device, VkSemaphore semaphore, const( VkAllocationCallbacks )* pAllocator );
	alias PFN_vkCreateEvent = VkResult function( VkDevice device, const( VkEventCreateInfo )* pCreateInfo, const( VkAllocationCallbacks )* pAllocator, VkEvent* pEvent );
	alias PFN_vkDestroyEvent = void function( VkDevice device, VkEvent event, const( VkAllocationCallbacks )* pAllocator );
	alias PFN_vkGetEventStatus = VkResult function( VkDevice device, VkEvent event );
	alias PFN_vkSetEvent = VkResult function( VkDevice device, VkEvent event );
	alias PFN_vkResetEvent = VkResult function( VkDevice device, VkEvent event );
	alias PFN_vkCreateQueryPool = VkResult function( VkDevice device, const( VkQueryPoolCreateInfo )* pCreateInfo, const( VkAllocationCallbacks )* pAllocator, VkQueryPool* pQueryPool );
	alias PFN_vkDestroyQueryPool = void function( VkDevice device, VkQueryPool queryPool, const( VkAllocationCallbacks )* pAllocator );
	alias PFN_vkGetQueryPoolResults = VkResult function( VkDevice device, VkQueryPool queryPool, uint32_t firstQuery, uint32_t queryCount, size_t dataSize, void* pData, VkDeviceSize stride, VkQueryResultFlags flags );
	alias PFN_vkCreateBuffer = VkResult function( VkDevice device, const( VkBufferCreateInfo )* pCreateInfo, const( VkAllocationCallbacks )* pAllocator, VkBuffer* pBuffer );
	alias PFN_vkDestroyBuffer = void function( VkDevice device, VkBuffer buffer, const( VkAllocationCallbacks )* pAllocator );
	alias PFN_vkCreateBufferView = VkResult function( VkDevice device, const( VkBufferViewCreateInfo )* pCreateInfo, const( VkAllocationCallbacks )* pAllocator, VkBufferView* pView );
	alias PFN_vkDestroyBufferView = void function( VkDevice device, VkBufferView bufferView, const( VkAllocationCallbacks )* pAllocator );
	alias PFN_vkCreateImage = VkResult function( VkDevice device, const( VkImageCreateInfo )* pCreateInfo, const( VkAllocationCallbacks )* pAllocator, VkImage* pImage );
	alias PFN_vkDestroyImage = void function( VkDevice device, VkImage image, const( VkAllocationCallbacks )* pAllocator );
	alias PFN_vkGetImageSubresourceLayout = void function( VkDevice device, VkImage image, const( VkImageSubresource )* pSubresource, VkSubresourceLayout* pLayout );
	alias PFN_vkCreateImageView = VkResult function( VkDevice device, const( VkImageViewCreateInfo )* pCreateInfo, const( VkAllocationCallbacks )* pAllocator, VkImageView* pView );
	alias PFN_vkDestroyImageView = void function( VkDevice device, VkImageView imageView, const( VkAllocationCallbacks )* pAllocator );
	alias PFN_vkCreateShaderModule = VkResult function( VkDevice device, const( VkShaderModuleCreateInfo )* pCreateInfo, const( VkAllocationCallbacks )* pAllocator, VkShaderModule* pShaderModule );
	alias PFN_vkDestroyShaderModule = void function( VkDevice device, VkShaderModule shaderModule, const( VkAllocationCallbacks )* pAllocator );
	alias PFN_vkCreatePipelineCache = VkResult function( VkDevice device, const( VkPipelineCacheCreateInfo )* pCreateInfo, const( VkAllocationCallbacks )* pAllocator, VkPipelineCache* pPipelineCache );
	alias PFN_vkDestroyPipelineCache = void function( VkDevice device, VkPipelineCache pipelineCache, const( VkAllocationCallbacks )* pAllocator );
	alias PFN_vkGetPipelineCacheData = VkResult function( VkDevice device, VkPipelineCache pipelineCache, size_t* pDataSize, void* pData );
	alias PFN_vkMergePipelineCaches = VkResult function( VkDevice device, VkPipelineCache dstCache, uint32_t srcCacheCount, const( VkPipelineCache )* pSrcCaches );
	alias PFN_vkCreateGraphicsPipelines = VkResult function( VkDevice device, VkPipelineCache pipelineCache, uint32_t createInfoCount, const( VkGraphicsPipelineCreateInfo )* pCreateInfos, const( VkAllocationCallbacks )* pAllocator, VkPipeline* pPipelines );
	alias PFN_vkCreateComputePipelines = VkResult function( VkDevice device, VkPipelineCache pipelineCache, uint32_t createInfoCount, const( VkComputePipelineCreateInfo )* pCreateInfos, const( VkAllocationCallbacks )* pAllocator, VkPipeline* pPipelines );
	alias PFN_vkDestroyPipeline = void function( VkDevice device, VkPipeline pipeline, const( VkAllocationCallbacks )* pAllocator );
	alias PFN_vkCreatePipelineLayout = VkResult function( VkDevice device, const( VkPipelineLayoutCreateInfo )* pCreateInfo, const( VkAllocationCallbacks )* pAllocator, VkPipelineLayout* pPipelineLayout );
	alias PFN_vkDestroyPipelineLayout = void function( VkDevice device, VkPipelineLayout pipelineLayout, const( VkAllocationCallbacks )* pAllocator );
	alias PFN_vkCreateSampler = VkResult function( VkDevice device, const( VkSamplerCreateInfo )* pCreateInfo, const( VkAllocationCallbacks )* pAllocator, VkSampler* pSampler );
	alias PFN_vkDestroySampler = void function( VkDevice device, VkSampler sampler, const( VkAllocationCallbacks )* pAllocator );
	alias PFN_vkCreateDescriptorSetLayout = VkResult function( VkDevice device, const( VkDescriptorSetLayoutCreateInfo )* pCreateInfo, const( VkAllocationCallbacks )* pAllocator, VkDescriptorSetLayout* pSetLayout );
	alias PFN_vkDestroyDescriptorSetLayout = void function( VkDevice device, VkDescriptorSetLayout descriptorSetLayout, const( VkAllocationCallbacks )* pAllocator );
	alias PFN_vkCreateDescriptorPool = VkResult function( VkDevice device, const( VkDescriptorPoolCreateInfo )* pCreateInfo, const( VkAllocationCallbacks )* pAllocator, VkDescriptorPool* pDescriptorPool );
	alias PFN_vkDestroyDescriptorPool = void function( VkDevice device, VkDescriptorPool descriptorPool, const( VkAllocationCallbacks )* pAllocator );
	alias PFN_vkResetDescriptorPool = VkResult function( VkDevice device, VkDescriptorPool descriptorPool, VkDescriptorPoolResetFlags flags );
	alias PFN_vkAllocateDescriptorSets = VkResult function( VkDevice device, const( VkDescriptorSetAllocateInfo )* pAllocateInfo, VkDescriptorSet* pDescriptorSets );
	alias PFN_vkFreeDescriptorSets = VkResult function( VkDevice device, VkDescriptorPool descriptorPool, uint32_t descriptorSetCount, const( VkDescriptorSet )* pDescriptorSets );
	alias PFN_vkUpdateDescriptorSets = void function( VkDevice device, uint32_t descriptorWriteCount, const( VkWriteDescriptorSet )* pDescriptorWrites, uint32_t descriptorCopyCount, const( VkCopyDescriptorSet )* pDescriptorCopies );
	alias PFN_vkCreateFramebuffer = VkResult function( VkDevice device, const( VkFramebufferCreateInfo )* pCreateInfo, const( VkAllocationCallbacks )* pAllocator, VkFramebuffer* pFramebuffer );
	alias PFN_vkDestroyFramebuffer = void function( VkDevice device, VkFramebuffer framebuffer, const( VkAllocationCallbacks )* pAllocator );
	alias PFN_vkCreateRenderPass = VkResult function( VkDevice device, const( VkRenderPassCreateInfo )* pCreateInfo, const( VkAllocationCallbacks )* pAllocator, VkRenderPass* pRenderPass );
	alias PFN_vkDestroyRenderPass = void function( VkDevice device, VkRenderPass renderPass, const( VkAllocationCallbacks )* pAllocator );
	alias PFN_vkGetRenderAreaGranularity = void function( VkDevice device, VkRenderPass renderPass, VkExtent2D* pGranularity );
	alias PFN_vkCreateCommandPool = VkResult function( VkDevice device, const( VkCommandPoolCreateInfo )* pCreateInfo, const( VkAllocationCallbacks )* pAllocator, VkCommandPool* pCommandPool );
	alias PFN_vkDestroyCommandPool = void function( VkDevice device, VkCommandPool commandPool, const( VkAllocationCallbacks )* pAllocator );
	alias PFN_vkResetCommandPool = VkResult function( VkDevice device, VkCommandPool commandPool, VkCommandPoolResetFlags flags );
	alias PFN_vkAllocateCommandBuffers = VkResult function( VkDevice device, const( VkCommandBufferAllocateInfo )* pAllocateInfo, VkCommandBuffer* pCommandBuffers );
	alias PFN_vkFreeCommandBuffers = void function( VkDevice device, VkCommandPool commandPool, uint32_t commandBufferCount, const( VkCommandBuffer )* pCommandBuffers );
	alias PFN_vkBeginCommandBuffer = VkResult function( VkCommandBuffer commandBuffer, const( VkCommandBufferBeginInfo )* pBeginInfo );
	alias PFN_vkEndCommandBuffer = VkResult function( VkCommandBuffer commandBuffer );
	alias PFN_vkResetCommandBuffer = VkResult function( VkCommandBuffer commandBuffer, VkCommandBufferResetFlags flags );
	alias PFN_vkCmdBindPipeline = void function( VkCommandBuffer commandBuffer, VkPipelineBindPoint pipelineBindPoint, VkPipeline pipeline );
	alias PFN_vkCmdSetViewport = void function( VkCommandBuffer commandBuffer, uint32_t firstViewport, uint32_t viewportCount, const( VkViewport )* pViewports );
	alias PFN_vkCmdSetScissor = void function( VkCommandBuffer commandBuffer, uint32_t firstScissor, uint32_t scissorCount, const( VkRect2D )* pScissors );
	alias PFN_vkCmdSetLineWidth = void function( VkCommandBuffer commandBuffer, float lineWidth );
	alias PFN_vkCmdSetDepthBias = void function( VkCommandBuffer commandBuffer, float depthBiasConstantFactor, float depthBiasClamp, float depthBiasSlopeFactor );
	alias PFN_vkCmdSetBlendConstants = void function( VkCommandBuffer commandBuffer, const float[4] blendConstants );
	alias PFN_vkCmdSetDepthBounds = void function( VkCommandBuffer commandBuffer, float minDepthBounds, float maxDepthBounds );
	alias PFN_vkCmdSetStencilCompareMask = void function( VkCommandBuffer commandBuffer, VkStencilFaceFlags faceMask, uint32_t compareMask );
	alias PFN_vkCmdSetStencilWriteMask = void function( VkCommandBuffer commandBuffer, VkStencilFaceFlags faceMask, uint32_t writeMask );
	alias PFN_vkCmdSetStencilReference = void function( VkCommandBuffer commandBuffer, VkStencilFaceFlags faceMask, uint32_t reference );
	alias PFN_vkCmdBindDescriptorSets = void function( VkCommandBuffer commandBuffer, VkPipelineBindPoint pipelineBindPoint, VkPipelineLayout layout, uint32_t firstSet, uint32_t descriptorSetCount, const( VkDescriptorSet )* pDescriptorSets, uint32_t dynamicOffsetCount, const( uint32_t )* pDynamicOffsets );
	alias PFN_vkCmdBindIndexBuffer = void function( VkCommandBuffer commandBuffer, VkBuffer buffer, VkDeviceSize offset, VkIndexType indexType );
	alias PFN_vkCmdBindVertexBuffers = void function( VkCommandBuffer commandBuffer, uint32_t firstBinding, uint32_t bindingCount, const( VkBuffer )* pBuffers, const( VkDeviceSize )* pOffsets );
	alias PFN_vkCmdDraw = void function( VkCommandBuffer commandBuffer, uint32_t vertexCount, uint32_t instanceCount, uint32_t firstVertex, uint32_t firstInstance );
	alias PFN_vkCmdDrawIndexed = void function( VkCommandBuffer commandBuffer, uint32_t indexCount, uint32_t instanceCount, uint32_t firstIndex, int32_t vertexOffset, uint32_t firstInstance );
	alias PFN_vkCmdDrawIndirect = void function( VkCommandBuffer commandBuffer, VkBuffer buffer, VkDeviceSize offset, uint32_t drawCount, uint32_t stride );
	alias PFN_vkCmdDrawIndexedIndirect = void function( VkCommandBuffer commandBuffer, VkBuffer buffer, VkDeviceSize offset, uint32_t drawCount, uint32_t stride );
	alias PFN_vkCmdDispatch = void function( VkCommandBuffer commandBuffer, uint32_t groupCountX, uint32_t groupCountY, uint32_t groupCountZ );
	alias PFN_vkCmdDispatchIndirect = void function( VkCommandBuffer commandBuffer, VkBuffer buffer, VkDeviceSize offset );
	alias PFN_vkCmdCopyBuffer = void function( VkCommandBuffer commandBuffer, VkBuffer srcBuffer, VkBuffer dstBuffer, uint32_t regionCount, const( VkBufferCopy )* pRegions );
	alias PFN_vkCmdCopyImage = void function( VkCommandBuffer commandBuffer, VkImage srcImage, VkImageLayout srcImageLayout, VkImage dstImage, VkImageLayout dstImageLayout, uint32_t regionCount, const( VkImageCopy )* pRegions );
	alias PFN_vkCmdBlitImage = void function( VkCommandBuffer commandBuffer, VkImage srcImage, VkImageLayout srcImageLayout, VkImage dstImage, VkImageLayout dstImageLayout, uint32_t regionCount, const( VkImageBlit )* pRegions, VkFilter filter );
	alias PFN_vkCmdCopyBufferToImage = void function( VkCommandBuffer commandBuffer, VkBuffer srcBuffer, VkImage dstImage, VkImageLayout dstImageLayout, uint32_t regionCount, const( VkBufferImageCopy )* pRegions );
	alias PFN_vkCmdCopyImageToBuffer = void function( VkCommandBuffer commandBuffer, VkImage srcImage, VkImageLayout srcImageLayout, VkBuffer dstBuffer, uint32_t regionCount, const( VkBufferImageCopy )* pRegions );
	alias PFN_vkCmdUpdateBuffer = void function( VkCommandBuffer commandBuffer, VkBuffer dstBuffer, VkDeviceSize dstOffset, VkDeviceSize dataSize, const( void )* pData );
	alias PFN_vkCmdFillBuffer = void function( VkCommandBuffer commandBuffer, VkBuffer dstBuffer, VkDeviceSize dstOffset, VkDeviceSize size, uint32_t data );
	alias PFN_vkCmdClearColorImage = void function( VkCommandBuffer commandBuffer, VkImage image, VkImageLayout imageLayout, const( VkClearColorValue )* pColor, uint32_t rangeCount, const( VkImageSubresourceRange )* pRanges );
	alias PFN_vkCmdClearDepthStencilImage = void function( VkCommandBuffer commandBuffer, VkImage image, VkImageLayout imageLayout, const( VkClearDepthStencilValue )* pDepthStencil, uint32_t rangeCount, const( VkImageSubresourceRange )* pRanges );
	alias PFN_vkCmdClearAttachments = void function( VkCommandBuffer commandBuffer, uint32_t attachmentCount, const( VkClearAttachment )* pAttachments, uint32_t rectCount, const( VkClearRect )* pRects );
	alias PFN_vkCmdResolveImage = void function( VkCommandBuffer commandBuffer, VkImage srcImage, VkImageLayout srcImageLayout, VkImage dstImage, VkImageLayout dstImageLayout, uint32_t regionCount, const( VkImageResolve )* pRegions );
	alias PFN_vkCmdSetEvent = void function( VkCommandBuffer commandBuffer, VkEvent event, VkPipelineStageFlags stageMask );
	alias PFN_vkCmdResetEvent = void function( VkCommandBuffer commandBuffer, VkEvent event, VkPipelineStageFlags stageMask );
	alias PFN_vkCmdWaitEvents = void function( VkCommandBuffer commandBuffer, uint32_t eventCount, const( VkEvent )* pEvents, VkPipelineStageFlags srcStageMask, VkPipelineStageFlags dstStageMask, uint32_t memoryBarrierCount, const( VkMemoryBarrier )* pMemoryBarriers, uint32_t bufferMemoryBarrierCount, const( VkBufferMemoryBarrier )* pBufferMemoryBarriers, uint32_t imageMemoryBarrierCount, const( VkImageMemoryBarrier )* pImageMemoryBarriers );
	alias PFN_vkCmdPipelineBarrier = void function( VkCommandBuffer commandBuffer, VkPipelineStageFlags srcStageMask, VkPipelineStageFlags dstStageMask, VkDependencyFlags dependencyFlags, uint32_t memoryBarrierCount, const( VkMemoryBarrier )* pMemoryBarriers, uint32_t bufferMemoryBarrierCount, const( VkBufferMemoryBarrier )* pBufferMemoryBarriers, uint32_t imageMemoryBarrierCount, const( VkImageMemoryBarrier )* pImageMemoryBarriers );
	alias PFN_vkCmdBeginQuery = void function( VkCommandBuffer commandBuffer, VkQueryPool queryPool, uint32_t query, VkQueryControlFlags flags );
	alias PFN_vkCmdEndQuery = void function( VkCommandBuffer commandBuffer, VkQueryPool queryPool, uint32_t query );
	alias PFN_vkCmdResetQueryPool = void function( VkCommandBuffer commandBuffer, VkQueryPool queryPool, uint32_t firstQuery, uint32_t queryCount );
	alias PFN_vkCmdWriteTimestamp = void function( VkCommandBuffer commandBuffer, VkPipelineStageFlagBits pipelineStage, VkQueryPool queryPool, uint32_t query );
	alias PFN_vkCmdCopyQueryPoolResults = void function( VkCommandBuffer commandBuffer, VkQueryPool queryPool, uint32_t firstQuery, uint32_t queryCount, VkBuffer dstBuffer, VkDeviceSize dstOffset, VkDeviceSize stride, VkQueryResultFlags flags );
	alias PFN_vkCmdPushConstants = void function( VkCommandBuffer commandBuffer, VkPipelineLayout layout, VkShaderStageFlags stageFlags, uint32_t offset, uint32_t size, const( void )* pValues );
	alias PFN_vkCmdBeginRenderPass = void function( VkCommandBuffer commandBuffer, const( VkRenderPassBeginInfo )* pRenderPassBegin, VkSubpassContents contents );
	alias PFN_vkCmdNextSubpass = void function( VkCommandBuffer commandBuffer, VkSubpassContents contents );
	alias PFN_vkCmdEndRenderPass = void function( VkCommandBuffer commandBuffer );
	alias PFN_vkCmdExecuteCommands = void function( VkCommandBuffer commandBuffer, uint32_t commandBufferCount, const( VkCommandBuffer )* pCommandBuffers );

	// VK_KHR_surface
	alias PFN_vkDestroySurfaceKHR = void function( VkInstance instance, VkSurfaceKHR surface, const( VkAllocationCallbacks )* pAllocator );
	alias PFN_vkGetPhysicalDeviceSurfaceSupportKHR = VkResult function( VkPhysicalDevice physicalDevice, uint32_t queueFamilyIndex, VkSurfaceKHR surface, VkBool32* pSupported );
	alias PFN_vkGetPhysicalDeviceSurfaceCapabilitiesKHR = VkResult function( VkPhysicalDevice physicalDevice, VkSurfaceKHR surface, VkSurfaceCapabilitiesKHR* pSurfaceCapabilities );
	alias PFN_vkGetPhysicalDeviceSurfaceFormatsKHR = VkResult function( VkPhysicalDevice physicalDevice, VkSurfaceKHR surface, uint32_t* pSurfaceFormatCount, VkSurfaceFormatKHR* pSurfaceFormats );
	alias PFN_vkGetPhysicalDeviceSurfacePresentModesKHR = VkResult function( VkPhysicalDevice physicalDevice, VkSurfaceKHR surface, uint32_t* pPresentModeCount, VkPresentModeKHR* pPresentModes );

	// VK_KHR_swapchain
	alias PFN_vkCreateSwapchainKHR = VkResult function( VkDevice device, const( VkSwapchainCreateInfoKHR )* pCreateInfo, const( VkAllocationCallbacks )* pAllocator, VkSwapchainKHR* pSwapchain );
	alias PFN_vkDestroySwapchainKHR = void function( VkDevice device, VkSwapchainKHR swapchain, const( VkAllocationCallbacks )* pAllocator );
	alias PFN_vkGetSwapchainImagesKHR = VkResult function( VkDevice device, VkSwapchainKHR swapchain, uint32_t* pSwapchainImageCount, VkImage* pSwapchainImages );
	alias PFN_vkAcquireNextImageKHR = VkResult function( VkDevice device, VkSwapchainKHR swapchain, uint64_t timeout, VkSemaphore semaphore, VkFence fence, uint32_t* pImageIndex );
	alias PFN_vkQueuePresentKHR = VkResult function( VkQueue queue, const( VkPresentInfoKHR )* pPresentInfo );

	// VK_KHR_display
	alias PFN_vkGetPhysicalDeviceDisplayPropertiesKHR = VkResult function( VkPhysicalDevice physicalDevice, uint32_t* pPropertyCount, VkDisplayPropertiesKHR* pProperties );
	alias PFN_vkGetPhysicalDeviceDisplayPlanePropertiesKHR = VkResult function( VkPhysicalDevice physicalDevice, uint32_t* pPropertyCount, VkDisplayPlanePropertiesKHR* pProperties );
	alias PFN_vkGetDisplayPlaneSupportedDisplaysKHR = VkResult function( VkPhysicalDevice physicalDevice, uint32_t planeIndex, uint32_t* pDisplayCount, VkDisplayKHR* pDisplays );
	alias PFN_vkGetDisplayModePropertiesKHR = VkResult function( VkPhysicalDevice physicalDevice, VkDisplayKHR display, uint32_t* pPropertyCount, VkDisplayModePropertiesKHR* pProperties );
	alias PFN_vkCreateDisplayModeKHR = VkResult function( VkPhysicalDevice physicalDevice, VkDisplayKHR display, const( VkDisplayModeCreateInfoKHR )* pCreateInfo, const( VkAllocationCallbacks )* pAllocator, VkDisplayModeKHR* pMode );
	alias PFN_vkGetDisplayPlaneCapabilitiesKHR = VkResult function( VkPhysicalDevice physicalDevice, VkDisplayModeKHR mode, uint32_t planeIndex, VkDisplayPlaneCapabilitiesKHR* pCapabilities );
	alias PFN_vkCreateDisplayPlaneSurfaceKHR = VkResult function( VkInstance instance, const( VkDisplaySurfaceCreateInfoKHR )* pCreateInfo, const( VkAllocationCallbacks )* pAllocator, VkSurfaceKHR* pSurface );

	// VK_KHR_display_swapchain
	alias PFN_vkCreateSharedSwapchainsKHR = VkResult function( VkDevice device, uint32_t swapchainCount, const( VkSwapchainCreateInfoKHR )* pCreateInfos, const( VkAllocationCallbacks )* pAllocator, VkSwapchainKHR* pSwapchains );

	// VK_KHR_xlib_surface
	version( VK_USE_PLATFORM_XLIB_KHR ) {
		alias PFN_vkCreateXlibSurfaceKHR = VkResult function( VkInstance instance, const( VkXlibSurfaceCreateInfoKHR )* pCreateInfo, const( VkAllocationCallbacks )* pAllocator, VkSurfaceKHR* pSurface );
		alias PFN_vkGetPhysicalDeviceXlibPresentationSupportKHR = VkBool32 function( VkPhysicalDevice physicalDevice, uint32_t queueFamilyIndex, Display* dpy, VisualID visualID );
	}

	// VK_KHR_xcb_surface
	version( VK_USE_PLATFORM_XCB_KHR ) {
		alias PFN_vkCreateXcbSurfaceKHR = VkResult function( VkInstance instance, const( VkXcbSurfaceCreateInfoKHR )* pCreateInfo, const( VkAllocationCallbacks )* pAllocator, VkSurfaceKHR* pSurface );
		alias PFN_vkGetPhysicalDeviceXcbPresentationSupportKHR = VkBool32 function( VkPhysicalDevice physicalDevice, uint32_t queueFamilyIndex, xcb_connection_t* connection, xcb_visualid_t visual_id );
	}

	// VK_KHR_wayland_surface
	version( VK_USE_PLATFORM_WAYLAND_KHR ) {
		alias PFN_vkCreateWaylandSurfaceKHR = VkResult function( VkInstance instance, const( VkWaylandSurfaceCreateInfoKHR )* pCreateInfo, const( VkAllocationCallbacks )* pAllocator, VkSurfaceKHR* pSurface );
		alias PFN_vkGetPhysicalDeviceWaylandPresentationSupportKHR = VkBool32 function( VkPhysicalDevice physicalDevice, uint32_t queueFamilyIndex, wl_display* display );
	}

	// VK_KHR_mir_surface
	version( VK_USE_PLATFORM_MIR_KHR ) {
		alias PFN_vkCreateMirSurfaceKHR = VkResult function( VkInstance instance, const( VkMirSurfaceCreateInfoKHR )* pCreateInfo, const( VkAllocationCallbacks )* pAllocator, VkSurfaceKHR* pSurface );
		alias PFN_vkGetPhysicalDeviceMirPresentationSupportKHR = VkBool32 function( VkPhysicalDevice physicalDevice, uint32_t queueFamilyIndex, MirConnection* connection );
	}

	// VK_KHR_android_surface
	version( VK_USE_PLATFORM_ANDROID_KHR ) {
		alias PFN_vkCreateAndroidSurfaceKHR = VkResult function( VkInstance instance, const( VkAndroidSurfaceCreateInfoKHR )* pCreateInfo, const( VkAllocationCallbacks )* pAllocator, VkSurfaceKHR* pSurface );
	}

	// VK_KHR_win32_surface
	version( VK_USE_PLATFORM_WIN32_KHR ) {
		alias PFN_vkCreateWin32SurfaceKHR = VkResult function( VkInstance instance, const( VkWin32SurfaceCreateInfoKHR )* pCreateInfo, const( VkAllocationCallbacks )* pAllocator, VkSurfaceKHR* pSurface );
		alias PFN_vkGetPhysicalDeviceWin32PresentationSupportKHR = VkBool32 function( VkPhysicalDevice physicalDevice, uint32_t queueFamilyIndex );
	}

	// VK_KHR_get_physical_device_properties2
	alias PFN_vkGetPhysicalDeviceFeatures2KHR = void function( VkPhysicalDevice physicalDevice, VkPhysicalDeviceFeatures2KHR* pFeatures );
	alias PFN_vkGetPhysicalDeviceProperties2KHR = void function( VkPhysicalDevice physicalDevice, VkPhysicalDeviceProperties2KHR* pProperties );
	alias PFN_vkGetPhysicalDeviceFormatProperties2KHR = void function( VkPhysicalDevice physicalDevice, VkFormat format, VkFormatProperties2KHR* pFormatProperties );
	alias PFN_vkGetPhysicalDeviceImageFormatProperties2KHR = VkResult function( VkPhysicalDevice physicalDevice, const( VkPhysicalDeviceImageFormatInfo2KHR )* pImageFormatInfo, VkImageFormatProperties2KHR* pImageFormatProperties );
	alias PFN_vkGetPhysicalDeviceQueueFamilyProperties2KHR = void function( VkPhysicalDevice physicalDevice, uint32_t* pQueueFamilyPropertyCount, VkQueueFamilyProperties2KHR* pQueueFamilyProperties );
	alias PFN_vkGetPhysicalDeviceMemoryProperties2KHR = void function( VkPhysicalDevice physicalDevice, VkPhysicalDeviceMemoryProperties2KHR* pMemoryProperties );
	alias PFN_vkGetPhysicalDeviceSparseImageFormatProperties2KHR = void function( VkPhysicalDevice physicalDevice, const( VkPhysicalDeviceSparseImageFormatInfo2KHR )* pFormatInfo, uint32_t* pPropertyCount, VkSparseImageFormatProperties2KHR* pProperties );

	// VK_KHR_maintenance1
	alias PFN_vkTrimCommandPoolKHR = void function( VkDevice device, VkCommandPool commandPool, VkCommandPoolTrimFlagsKHR flags );

	// VK_KHR_external_memory_capabilities
	alias PFN_vkGetPhysicalDeviceExternalBufferPropertiesKHR = void function( VkPhysicalDevice physicalDevice, const( VkPhysicalDeviceExternalBufferInfoKHR )* pExternalBufferInfo, VkExternalBufferPropertiesKHR* pExternalBufferProperties );

	// VK_KHR_external_memory_win32
	version( VK_USE_PLATFORM_WIN32_KHR ) {
		alias PFN_vkGetMemoryWin32HandleKHR = VkResult function( VkDevice device, const( VkMemoryGetWin32HandleInfoKHR )* pGetWin32HandleInfo, HANDLE* pHandle );
		alias PFN_vkGetMemoryWin32HandlePropertiesKHR = VkResult function( VkDevice device, VkExternalMemoryHandleTypeFlagBitsKHR handleType, HANDLE handle, VkMemoryWin32HandlePropertiesKHR* pMemoryWin32HandleProperties );
	}

	// VK_KHR_external_memory_fd
	alias PFN_vkGetMemoryFdKHR = VkResult function( VkDevice device, const( VkMemoryGetFdInfoKHR )* pGetFdInfo, int* pFd );
	alias PFN_vkGetMemoryFdPropertiesKHR = VkResult function( VkDevice device, VkExternalMemoryHandleTypeFlagBitsKHR handleType, int fd, VkMemoryFdPropertiesKHR* pMemoryFdProperties );

	// VK_KHR_external_semaphore_capabilities
	alias PFN_vkGetPhysicalDeviceExternalSemaphorePropertiesKHR = void function( VkPhysicalDevice physicalDevice, const( VkPhysicalDeviceExternalSemaphoreInfoKHR )* pExternalSemaphoreInfo, VkExternalSemaphorePropertiesKHR* pExternalSemaphoreProperties );

	// VK_KHR_external_semaphore_win32
	version( VK_USE_PLATFORM_WIN32_KHR ) {
		alias PFN_vkImportSemaphoreWin32HandleKHR = VkResult function( VkDevice device, const( VkImportSemaphoreWin32HandleInfoKHR )* pImportSemaphoreWin32HandleInfo );
		alias PFN_vkGetSemaphoreWin32HandleKHR = VkResult function( VkDevice device, const( VkSemaphoreGetWin32HandleInfoKHR )* pGetWin32HandleInfo, HANDLE* pHandle );
	}

	// VK_KHR_external_semaphore_fd
	alias PFN_vkImportSemaphoreFdKHR = VkResult function( VkDevice device, const( VkImportSemaphoreFdInfoKHR )* pImportSemaphoreFdInfo );
	alias PFN_vkGetSemaphoreFdKHR = VkResult function( VkDevice device, const( VkSemaphoreGetFdInfoKHR )* pGetFdInfo, int* pFd );

	// VK_KHR_push_descriptor
	alias PFN_vkCmdPushDescriptorSetKHR = void function( VkCommandBuffer commandBuffer, VkPipelineBindPoint pipelineBindPoint, VkPipelineLayout layout, uint32_t set, uint32_t descriptorWriteCount, const( VkWriteDescriptorSet )* pDescriptorWrites );

	// VK_KHR_descriptor_update_template
	alias PFN_vkCreateDescriptorUpdateTemplateKHR = VkResult function( VkDevice device, const( VkDescriptorUpdateTemplateCreateInfoKHR )* pCreateInfo, const( VkAllocationCallbacks )* pAllocator, VkDescriptorUpdateTemplateKHR* pDescriptorUpdateTemplate );
	alias PFN_vkDestroyDescriptorUpdateTemplateKHR = void function( VkDevice device, VkDescriptorUpdateTemplateKHR descriptorUpdateTemplate, const( VkAllocationCallbacks )* pAllocator );
	alias PFN_vkUpdateDescriptorSetWithTemplateKHR = void function( VkDevice device, VkDescriptorSet descriptorSet, VkDescriptorUpdateTemplateKHR descriptorUpdateTemplate, const( void )* pData );
	alias PFN_vkCmdPushDescriptorSetWithTemplateKHR = void function( VkCommandBuffer commandBuffer, VkDescriptorUpdateTemplateKHR descriptorUpdateTemplate, VkPipelineLayout layout, uint32_t set, const( void )* pData );

	// VK_KHR_shared_presentable_image
	alias PFN_vkGetSwapchainStatusKHR = VkResult function( VkDevice device, VkSwapchainKHR swapchain );

	// VK_KHR_external_fence_capabilities
	alias PFN_vkGetPhysicalDeviceExternalFencePropertiesKHR = void function( VkPhysicalDevice physicalDevice, const( VkPhysicalDeviceExternalFenceInfoKHR )* pExternalFenceInfo, VkExternalFencePropertiesKHR* pExternalFenceProperties );

	// VK_KHR_external_fence_win32
	version( VK_USE_PLATFORM_WIN32_KHR ) {
		alias PFN_vkImportFenceWin32HandleKHR = VkResult function( VkDevice device, const( VkImportFenceWin32HandleInfoKHR )* pImportFenceWin32HandleInfo );
		alias PFN_vkGetFenceWin32HandleKHR = VkResult function( VkDevice device, const( VkFenceGetWin32HandleInfoKHR )* pGetWin32HandleInfo, HANDLE* pHandle );
	}

	// VK_KHR_external_fence_fd
	alias PFN_vkImportFenceFdKHR = VkResult function( VkDevice device, const( VkImportFenceFdInfoKHR )* pImportFenceFdInfo );
	alias PFN_vkGetFenceFdKHR = VkResult function( VkDevice device, const( VkFenceGetFdInfoKHR )* pGetFdInfo, int* pFd );

	// VK_KHR_get_surface_capabilities2
	alias PFN_vkGetPhysicalDeviceSurfaceCapabilities2KHR = VkResult function( VkPhysicalDevice physicalDevice, const( VkPhysicalDeviceSurfaceInfo2KHR )* pSurfaceInfo, VkSurfaceCapabilities2KHR* pSurfaceCapabilities );
	alias PFN_vkGetPhysicalDeviceSurfaceFormats2KHR = VkResult function( VkPhysicalDevice physicalDevice, const( VkPhysicalDeviceSurfaceInfo2KHR )* pSurfaceInfo, uint32_t* pSurfaceFormatCount, VkSurfaceFormat2KHR* pSurfaceFormats );

	// VK_KHR_get_memory_requirements2
	alias PFN_vkGetImageMemoryRequirements2KHR = void function( VkDevice device, const( VkImageMemoryRequirementsInfo2KHR )* pInfo, VkMemoryRequirements2KHR* pMemoryRequirements );
	alias PFN_vkGetBufferMemoryRequirements2KHR = void function( VkDevice device, const( VkBufferMemoryRequirementsInfo2KHR )* pInfo, VkMemoryRequirements2KHR* pMemoryRequirements );
	alias PFN_vkGetImageSparseMemoryRequirements2KHR = void function( VkDevice device, const( VkImageSparseMemoryRequirementsInfo2KHR )* pInfo, uint32_t* pSparseMemoryRequirementCount, VkSparseImageMemoryRequirements2KHR* pSparseMemoryRequirements );

	// VK_KHR_sampler_ycbcr_conversion
	alias PFN_vkCreateSamplerYcbcrConversionKHR = VkResult function( VkDevice device, const( VkSamplerYcbcrConversionCreateInfoKHR )* pCreateInfo, const( VkAllocationCallbacks )* pAllocator, VkSamplerYcbcrConversionKHR* pYcbcrConversion );
	alias PFN_vkDestroySamplerYcbcrConversionKHR = void function( VkDevice device, VkSamplerYcbcrConversionKHR ycbcrConversion, const( VkAllocationCallbacks )* pAllocator );

	// VK_KHR_bind_memory2
	alias PFN_vkBindBufferMemory2KHR = VkResult function( VkDevice device, uint32_t bindInfoCount, const( VkBindBufferMemoryInfoKHR )* pBindInfos );
	alias PFN_vkBindImageMemory2KHR = VkResult function( VkDevice device, uint32_t bindInfoCount, const( VkBindImageMemoryInfoKHR )* pBindInfos );

	// VK_ANDROID_native_buffer
	alias PFN_vkGetSwapchainGrallocUsageANDROID = VkResult function( VkDevice device, VkFormat format, VkImageUsageFlags imageUsage, int* grallocUsage );
	alias PFN_vkAcquireImageANDROID = VkResult function( VkDevice device, VkImage image, int nativeFenceFd, VkSemaphore semaphore, VkFence fence );
	alias PFN_vkQueueSignalReleaseImageANDROID = VkResult function( VkQueue queue, uint32_t waitSemaphoreCount, const( VkSemaphore )* pWaitSemaphores, VkImage image, int* pNativeFenceFd );

	// VK_EXT_debug_report
	alias PFN_vkCreateDebugReportCallbackEXT = VkResult function( VkInstance instance, const( VkDebugReportCallbackCreateInfoEXT )* pCreateInfo, const( VkAllocationCallbacks )* pAllocator, VkDebugReportCallbackEXT* pCallback );
	alias PFN_vkDestroyDebugReportCallbackEXT = void function( VkInstance instance, VkDebugReportCallbackEXT callback, const( VkAllocationCallbacks )* pAllocator );
	alias PFN_vkDebugReportMessageEXT = void function( VkInstance instance, VkDebugReportFlagsEXT flags, VkDebugReportObjectTypeEXT objectType, uint64_t object, size_t location, int32_t messageCode, const( char )* pLayerPrefix, const( char )* pMessage );

	// VK_EXT_debug_marker
	alias PFN_vkDebugMarkerSetObjectTagEXT = VkResult function( VkDevice device, const( VkDebugMarkerObjectTagInfoEXT )* pTagInfo );
	alias PFN_vkDebugMarkerSetObjectNameEXT = VkResult function( VkDevice device, const( VkDebugMarkerObjectNameInfoEXT )* pNameInfo );
	alias PFN_vkCmdDebugMarkerBeginEXT = void function( VkCommandBuffer commandBuffer, const( VkDebugMarkerMarkerInfoEXT )* pMarkerInfo );
	alias PFN_vkCmdDebugMarkerEndEXT = void function( VkCommandBuffer commandBuffer );
	alias PFN_vkCmdDebugMarkerInsertEXT = void function( VkCommandBuffer commandBuffer, const( VkDebugMarkerMarkerInfoEXT )* pMarkerInfo );

	// VK_AMD_draw_indirect_count
	alias PFN_vkCmdDrawIndirectCountAMD = void function( VkCommandBuffer commandBuffer, VkBuffer buffer, VkDeviceSize offset, VkBuffer countBuffer, VkDeviceSize countBufferOffset, uint32_t maxDrawCount, uint32_t stride );
	alias PFN_vkCmdDrawIndexedIndirectCountAMD = void function( VkCommandBuffer commandBuffer, VkBuffer buffer, VkDeviceSize offset, VkBuffer countBuffer, VkDeviceSize countBufferOffset, uint32_t maxDrawCount, uint32_t stride );

	// VK_AMD_shader_info
	alias PFN_vkGetShaderInfoAMD = VkResult function( VkDevice device, VkPipeline pipeline, VkShaderStageFlagBits shaderStage, VkShaderInfoTypeAMD infoType, size_t* pInfoSize, void* pInfo );

	// VK_NV_external_memory_capabilities
	alias PFN_vkGetPhysicalDeviceExternalImageFormatPropertiesNV = VkResult function( VkPhysicalDevice physicalDevice, VkFormat format, VkImageType type, VkImageTiling tiling, VkImageUsageFlags usage, VkImageCreateFlags flags, VkExternalMemoryHandleTypeFlagsNV externalHandleType, VkExternalImageFormatPropertiesNV* pExternalImageFormatProperties );

	// VK_NV_external_memory_win32
	version( VK_USE_PLATFORM_WIN32_KHR ) {
		alias PFN_vkGetMemoryWin32HandleNV = VkResult function( VkDevice device, VkDeviceMemory memory, VkExternalMemoryHandleTypeFlagsNV handleType, HANDLE* pHandle );
	}

	// VK_KHX_device_group
	alias PFN_vkGetDeviceGroupPeerMemoryFeaturesKHX = void function( VkDevice device, uint32_t heapIndex, uint32_t localDeviceIndex, uint32_t remoteDeviceIndex, VkPeerMemoryFeatureFlagsKHX* pPeerMemoryFeatures );
	alias PFN_vkCmdSetDeviceMaskKHX = void function( VkCommandBuffer commandBuffer, uint32_t deviceMask );
	alias PFN_vkCmdDispatchBaseKHX = void function( VkCommandBuffer commandBuffer, uint32_t baseGroupX, uint32_t baseGroupY, uint32_t baseGroupZ, uint32_t groupCountX, uint32_t groupCountY, uint32_t groupCountZ );
	alias PFN_vkGetDeviceGroupPresentCapabilitiesKHX = VkResult function( VkDevice device, VkDeviceGroupPresentCapabilitiesKHX* pDeviceGroupPresentCapabilities );
	alias PFN_vkGetDeviceGroupSurfacePresentModesKHX = VkResult function( VkDevice device, VkSurfaceKHR surface, VkDeviceGroupPresentModeFlagsKHX* pModes );
	alias PFN_vkGetPhysicalDevicePresentRectanglesKHX = VkResult function( VkPhysicalDevice physicalDevice, VkSurfaceKHR surface, uint32_t* pRectCount, VkRect2D* pRects );
	alias PFN_vkAcquireNextImage2KHX = VkResult function( VkDevice device, const( VkAcquireNextImageInfoKHX )* pAcquireInfo, uint32_t* pImageIndex );

	// VK_NN_vi_surface
	alias PFN_vkCreateViSurfaceNN = VkResult function( VkInstance instance, const( VkViSurfaceCreateInfoNN )* pCreateInfo, const( VkAllocationCallbacks )* pAllocator, VkSurfaceKHR* pSurface );

	// VK_KHX_device_group_creation
	alias PFN_vkEnumeratePhysicalDeviceGroupsKHX = VkResult function( VkInstance instance, uint32_t* pPhysicalDeviceGroupCount, VkPhysicalDeviceGroupPropertiesKHX* pPhysicalDeviceGroupProperties );

	// VK_NVX_device_generated_commands
	alias PFN_vkCmdProcessCommandsNVX = void function( VkCommandBuffer commandBuffer, const( VkCmdProcessCommandsInfoNVX )* pProcessCommandsInfo );
	alias PFN_vkCmdReserveSpaceForCommandsNVX = void function( VkCommandBuffer commandBuffer, const( VkCmdReserveSpaceForCommandsInfoNVX )* pReserveSpaceInfo );
	alias PFN_vkCreateIndirectCommandsLayoutNVX = VkResult function( VkDevice device, const( VkIndirectCommandsLayoutCreateInfoNVX )* pCreateInfo, const( VkAllocationCallbacks )* pAllocator, VkIndirectCommandsLayoutNVX* pIndirectCommandsLayout );
	alias PFN_vkDestroyIndirectCommandsLayoutNVX = void function( VkDevice device, VkIndirectCommandsLayoutNVX indirectCommandsLayout, const( VkAllocationCallbacks )* pAllocator );
	alias PFN_vkCreateObjectTableNVX = VkResult function( VkDevice device, const( VkObjectTableCreateInfoNVX )* pCreateInfo, const( VkAllocationCallbacks )* pAllocator, VkObjectTableNVX* pObjectTable );
	alias PFN_vkDestroyObjectTableNVX = void function( VkDevice device, VkObjectTableNVX objectTable, const( VkAllocationCallbacks )* pAllocator );
	alias PFN_vkRegisterObjectsNVX = VkResult function( VkDevice device, VkObjectTableNVX objectTable, uint32_t objectCount, const( VkObjectTableEntryNVX* )* ppObjectTableEntries, const( uint32_t )* pObjectIndices );
	alias PFN_vkUnregisterObjectsNVX = VkResult function( VkDevice device, VkObjectTableNVX objectTable, uint32_t objectCount, const( VkObjectEntryTypeNVX )* pObjectEntryTypes, const( uint32_t )* pObjectIndices );
	alias PFN_vkGetPhysicalDeviceGeneratedCommandsPropertiesNVX = void function( VkPhysicalDevice physicalDevice, VkDeviceGeneratedCommandsFeaturesNVX* pFeatures, VkDeviceGeneratedCommandsLimitsNVX* pLimits );

	// VK_NV_clip_space_w_scaling
	alias PFN_vkCmdSetViewportWScalingNV = void function( VkCommandBuffer commandBuffer, uint32_t firstViewport, uint32_t viewportCount, const( VkViewportWScalingNV )* pViewportWScalings );

	// VK_EXT_direct_mode_display
	alias PFN_vkReleaseDisplayEXT = VkResult function( VkPhysicalDevice physicalDevice, VkDisplayKHR display );

	// VK_EXT_acquire_xlib_display
	version( VK_USE_PLATFORM_XLIB_KHR ) {
		alias PFN_vkAcquireXlibDisplayEXT = VkResult function( VkPhysicalDevice physicalDevice, Display* dpy, VkDisplayKHR display );
		alias PFN_vkGetRandROutputDisplayEXT = VkResult function( VkPhysicalDevice physicalDevice, Display* dpy, RROutput rrOutput, VkDisplayKHR* pDisplay );
	}

	// VK_EXT_display_surface_counter
	alias PFN_vkGetPhysicalDeviceSurfaceCapabilities2EXT = VkResult function( VkPhysicalDevice physicalDevice, VkSurfaceKHR surface, VkSurfaceCapabilities2EXT* pSurfaceCapabilities );

	// VK_EXT_display_control
	alias PFN_vkDisplayPowerControlEXT = VkResult function( VkDevice device, VkDisplayKHR display, const( VkDisplayPowerInfoEXT )* pDisplayPowerInfo );
	alias PFN_vkRegisterDeviceEventEXT = VkResult function( VkDevice device, const( VkDeviceEventInfoEXT )* pDeviceEventInfo, const( VkAllocationCallbacks )* pAllocator, VkFence* pFence );
	alias PFN_vkRegisterDisplayEventEXT = VkResult function( VkDevice device, VkDisplayKHR display, const( VkDisplayEventInfoEXT )* pDisplayEventInfo, const( VkAllocationCallbacks )* pAllocator, VkFence* pFence );
	alias PFN_vkGetSwapchainCounterEXT = VkResult function( VkDevice device, VkSwapchainKHR swapchain, VkSurfaceCounterFlagBitsEXT counter, uint64_t* pCounterValue );

	// VK_GOOGLE_display_timing
	alias PFN_vkGetRefreshCycleDurationGOOGLE = VkResult function( VkDevice device, VkSwapchainKHR swapchain, VkRefreshCycleDurationGOOGLE* pDisplayTimingProperties );
	alias PFN_vkGetPastPresentationTimingGOOGLE = VkResult function( VkDevice device, VkSwapchainKHR swapchain, uint32_t* pPresentationTimingCount, VkPastPresentationTimingGOOGLE* pPresentationTimings );

	// VK_EXT_discard_rectangles
	alias PFN_vkCmdSetDiscardRectangleEXT = void function( VkCommandBuffer commandBuffer, uint32_t firstDiscardRectangle, uint32_t discardRectangleCount, const( VkRect2D )* pDiscardRectangles );

	// VK_EXT_hdr_metadata
	alias PFN_vkSetHdrMetadataEXT = void function( VkDevice device, uint32_t swapchainCount, const( VkSwapchainKHR )* pSwapchains, const( VkHdrMetadataEXT )* pMetadata );

	// VK_MVK_ios_surface
	alias PFN_vkCreateIOSSurfaceMVK = VkResult function( VkInstance instance, const( VkIOSSurfaceCreateInfoMVK )* pCreateInfo, const( VkAllocationCallbacks )* pAllocator, VkSurfaceKHR* pSurface );

	// VK_MVK_macos_surface
	alias PFN_vkCreateMacOSSurfaceMVK = VkResult function( VkInstance instance, const( VkMacOSSurfaceCreateInfoMVK )* pCreateInfo, const( VkAllocationCallbacks )* pAllocator, VkSurfaceKHR* pSurface );

	// VK_EXT_sample_locations
	alias PFN_vkCmdSetSampleLocationsEXT = void function( VkCommandBuffer commandBuffer, const( VkSampleLocationsInfoEXT )* pSampleLocationsInfo );
	alias PFN_vkGetPhysicalDeviceMultisamplePropertiesEXT = void function( VkPhysicalDevice physicalDevice, VkSampleCountFlagBits samples, VkMultisamplePropertiesEXT* pMultisampleProperties );

	// VK_EXT_validation_cache
	alias PFN_vkCreateValidationCacheEXT = VkResult function( VkDevice device, const( VkValidationCacheCreateInfoEXT )* pCreateInfo, const( VkAllocationCallbacks )* pAllocator, VkValidationCacheEXT* pValidationCache );
	alias PFN_vkDestroyValidationCacheEXT = void function( VkDevice device, VkValidationCacheEXT validationCache, const( VkAllocationCallbacks )* pAllocator );
	alias PFN_vkMergeValidationCachesEXT = VkResult function( VkDevice device, VkValidationCacheEXT dstCache, uint32_t srcCacheCount, const( VkValidationCacheEXT )* pSrcCaches );
	alias PFN_vkGetValidationCacheDataEXT = VkResult function( VkDevice device, VkValidationCacheEXT validationCache, size_t* pDataSize, void* pData );
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

	// VK_KHR_get_physical_device_properties2
	PFN_vkGetPhysicalDeviceFeatures2KHR vkGetPhysicalDeviceFeatures2KHR;
	PFN_vkGetPhysicalDeviceProperties2KHR vkGetPhysicalDeviceProperties2KHR;
	PFN_vkGetPhysicalDeviceFormatProperties2KHR vkGetPhysicalDeviceFormatProperties2KHR;
	PFN_vkGetPhysicalDeviceImageFormatProperties2KHR vkGetPhysicalDeviceImageFormatProperties2KHR;
	PFN_vkGetPhysicalDeviceQueueFamilyProperties2KHR vkGetPhysicalDeviceQueueFamilyProperties2KHR;
	PFN_vkGetPhysicalDeviceMemoryProperties2KHR vkGetPhysicalDeviceMemoryProperties2KHR;
	PFN_vkGetPhysicalDeviceSparseImageFormatProperties2KHR vkGetPhysicalDeviceSparseImageFormatProperties2KHR;

	// VK_KHR_maintenance1
	PFN_vkTrimCommandPoolKHR vkTrimCommandPoolKHR;

	// VK_KHR_external_memory_capabilities
	PFN_vkGetPhysicalDeviceExternalBufferPropertiesKHR vkGetPhysicalDeviceExternalBufferPropertiesKHR;

	// VK_KHR_external_memory_win32
	version( VK_USE_PLATFORM_WIN32_KHR ) {
		PFN_vkGetMemoryWin32HandleKHR vkGetMemoryWin32HandleKHR;
		PFN_vkGetMemoryWin32HandlePropertiesKHR vkGetMemoryWin32HandlePropertiesKHR;
	}

	// VK_KHR_external_memory_fd
	PFN_vkGetMemoryFdKHR vkGetMemoryFdKHR;
	PFN_vkGetMemoryFdPropertiesKHR vkGetMemoryFdPropertiesKHR;

	// VK_KHR_external_semaphore_capabilities
	PFN_vkGetPhysicalDeviceExternalSemaphorePropertiesKHR vkGetPhysicalDeviceExternalSemaphorePropertiesKHR;

	// VK_KHR_external_semaphore_win32
	version( VK_USE_PLATFORM_WIN32_KHR ) {
		PFN_vkImportSemaphoreWin32HandleKHR vkImportSemaphoreWin32HandleKHR;
		PFN_vkGetSemaphoreWin32HandleKHR vkGetSemaphoreWin32HandleKHR;
	}

	// VK_KHR_external_semaphore_fd
	PFN_vkImportSemaphoreFdKHR vkImportSemaphoreFdKHR;
	PFN_vkGetSemaphoreFdKHR vkGetSemaphoreFdKHR;

	// VK_KHR_push_descriptor
	PFN_vkCmdPushDescriptorSetKHR vkCmdPushDescriptorSetKHR;

	// VK_KHR_descriptor_update_template
	PFN_vkCreateDescriptorUpdateTemplateKHR vkCreateDescriptorUpdateTemplateKHR;
	PFN_vkDestroyDescriptorUpdateTemplateKHR vkDestroyDescriptorUpdateTemplateKHR;
	PFN_vkUpdateDescriptorSetWithTemplateKHR vkUpdateDescriptorSetWithTemplateKHR;
	PFN_vkCmdPushDescriptorSetWithTemplateKHR vkCmdPushDescriptorSetWithTemplateKHR;

	// VK_KHR_shared_presentable_image
	PFN_vkGetSwapchainStatusKHR vkGetSwapchainStatusKHR;

	// VK_KHR_external_fence_capabilities
	PFN_vkGetPhysicalDeviceExternalFencePropertiesKHR vkGetPhysicalDeviceExternalFencePropertiesKHR;

	// VK_KHR_external_fence_win32
	version( VK_USE_PLATFORM_WIN32_KHR ) {
		PFN_vkImportFenceWin32HandleKHR vkImportFenceWin32HandleKHR;
		PFN_vkGetFenceWin32HandleKHR vkGetFenceWin32HandleKHR;
	}

	// VK_KHR_external_fence_fd
	PFN_vkImportFenceFdKHR vkImportFenceFdKHR;
	PFN_vkGetFenceFdKHR vkGetFenceFdKHR;

	// VK_KHR_get_surface_capabilities2
	PFN_vkGetPhysicalDeviceSurfaceCapabilities2KHR vkGetPhysicalDeviceSurfaceCapabilities2KHR;
	PFN_vkGetPhysicalDeviceSurfaceFormats2KHR vkGetPhysicalDeviceSurfaceFormats2KHR;

	// VK_KHR_get_memory_requirements2
	PFN_vkGetImageMemoryRequirements2KHR vkGetImageMemoryRequirements2KHR;
	PFN_vkGetBufferMemoryRequirements2KHR vkGetBufferMemoryRequirements2KHR;
	PFN_vkGetImageSparseMemoryRequirements2KHR vkGetImageSparseMemoryRequirements2KHR;

	// VK_KHR_sampler_ycbcr_conversion
	PFN_vkCreateSamplerYcbcrConversionKHR vkCreateSamplerYcbcrConversionKHR;
	PFN_vkDestroySamplerYcbcrConversionKHR vkDestroySamplerYcbcrConversionKHR;

	// VK_KHR_bind_memory2
	PFN_vkBindBufferMemory2KHR vkBindBufferMemory2KHR;
	PFN_vkBindImageMemory2KHR vkBindImageMemory2KHR;

	// VK_ANDROID_native_buffer
	PFN_vkGetSwapchainGrallocUsageANDROID vkGetSwapchainGrallocUsageANDROID;
	PFN_vkAcquireImageANDROID vkAcquireImageANDROID;
	PFN_vkQueueSignalReleaseImageANDROID vkQueueSignalReleaseImageANDROID;

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

	// VK_AMD_draw_indirect_count
	PFN_vkCmdDrawIndirectCountAMD vkCmdDrawIndirectCountAMD;
	PFN_vkCmdDrawIndexedIndirectCountAMD vkCmdDrawIndexedIndirectCountAMD;

	// VK_AMD_shader_info
	PFN_vkGetShaderInfoAMD vkGetShaderInfoAMD;

	// VK_NV_external_memory_capabilities
	PFN_vkGetPhysicalDeviceExternalImageFormatPropertiesNV vkGetPhysicalDeviceExternalImageFormatPropertiesNV;

	// VK_NV_external_memory_win32
	version( VK_USE_PLATFORM_WIN32_KHR ) {
		PFN_vkGetMemoryWin32HandleNV vkGetMemoryWin32HandleNV;
	}

	// VK_KHX_device_group
	PFN_vkGetDeviceGroupPeerMemoryFeaturesKHX vkGetDeviceGroupPeerMemoryFeaturesKHX;
	PFN_vkCmdSetDeviceMaskKHX vkCmdSetDeviceMaskKHX;
	PFN_vkCmdDispatchBaseKHX vkCmdDispatchBaseKHX;
	PFN_vkGetDeviceGroupPresentCapabilitiesKHX vkGetDeviceGroupPresentCapabilitiesKHX;
	PFN_vkGetDeviceGroupSurfacePresentModesKHX vkGetDeviceGroupSurfacePresentModesKHX;
	PFN_vkGetPhysicalDevicePresentRectanglesKHX vkGetPhysicalDevicePresentRectanglesKHX;
	PFN_vkAcquireNextImage2KHX vkAcquireNextImage2KHX;

	// VK_NN_vi_surface
	PFN_vkCreateViSurfaceNN vkCreateViSurfaceNN;

	// VK_KHX_device_group_creation
	PFN_vkEnumeratePhysicalDeviceGroupsKHX vkEnumeratePhysicalDeviceGroupsKHX;

	// VK_NVX_device_generated_commands
	PFN_vkCmdProcessCommandsNVX vkCmdProcessCommandsNVX;
	PFN_vkCmdReserveSpaceForCommandsNVX vkCmdReserveSpaceForCommandsNVX;
	PFN_vkCreateIndirectCommandsLayoutNVX vkCreateIndirectCommandsLayoutNVX;
	PFN_vkDestroyIndirectCommandsLayoutNVX vkDestroyIndirectCommandsLayoutNVX;
	PFN_vkCreateObjectTableNVX vkCreateObjectTableNVX;
	PFN_vkDestroyObjectTableNVX vkDestroyObjectTableNVX;
	PFN_vkRegisterObjectsNVX vkRegisterObjectsNVX;
	PFN_vkUnregisterObjectsNVX vkUnregisterObjectsNVX;
	PFN_vkGetPhysicalDeviceGeneratedCommandsPropertiesNVX vkGetPhysicalDeviceGeneratedCommandsPropertiesNVX;

	// VK_NV_clip_space_w_scaling
	PFN_vkCmdSetViewportWScalingNV vkCmdSetViewportWScalingNV;

	// VK_EXT_direct_mode_display
	PFN_vkReleaseDisplayEXT vkReleaseDisplayEXT;

	// VK_EXT_acquire_xlib_display
	version( VK_USE_PLATFORM_XLIB_KHR ) {
		PFN_vkAcquireXlibDisplayEXT vkAcquireXlibDisplayEXT;
		PFN_vkGetRandROutputDisplayEXT vkGetRandROutputDisplayEXT;
	}

	// VK_EXT_display_surface_counter
	PFN_vkGetPhysicalDeviceSurfaceCapabilities2EXT vkGetPhysicalDeviceSurfaceCapabilities2EXT;

	// VK_EXT_display_control
	PFN_vkDisplayPowerControlEXT vkDisplayPowerControlEXT;
	PFN_vkRegisterDeviceEventEXT vkRegisterDeviceEventEXT;
	PFN_vkRegisterDisplayEventEXT vkRegisterDisplayEventEXT;
	PFN_vkGetSwapchainCounterEXT vkGetSwapchainCounterEXT;

	// VK_GOOGLE_display_timing
	PFN_vkGetRefreshCycleDurationGOOGLE vkGetRefreshCycleDurationGOOGLE;
	PFN_vkGetPastPresentationTimingGOOGLE vkGetPastPresentationTimingGOOGLE;

	// VK_EXT_discard_rectangles
	PFN_vkCmdSetDiscardRectangleEXT vkCmdSetDiscardRectangleEXT;

	// VK_EXT_hdr_metadata
	PFN_vkSetHdrMetadataEXT vkSetHdrMetadataEXT;

	// VK_MVK_ios_surface
	PFN_vkCreateIOSSurfaceMVK vkCreateIOSSurfaceMVK;

	// VK_MVK_macos_surface
	PFN_vkCreateMacOSSurfaceMVK vkCreateMacOSSurfaceMVK;

	// VK_EXT_sample_locations
	PFN_vkCmdSetSampleLocationsEXT vkCmdSetSampleLocationsEXT;
	PFN_vkGetPhysicalDeviceMultisamplePropertiesEXT vkGetPhysicalDeviceMultisamplePropertiesEXT;

	// VK_EXT_validation_cache
	PFN_vkCreateValidationCacheEXT vkCreateValidationCacheEXT;
	PFN_vkDestroyValidationCacheEXT vkDestroyValidationCacheEXT;
	PFN_vkMergeValidationCachesEXT vkMergeValidationCachesEXT;
	PFN_vkGetValidationCacheDataEXT vkGetValidationCacheDataEXT;
}

/// if not using version "with-derelict-loader" this function must be called first
/// sets vkCreateInstance function pointer and acquires basic functions to retrieve information about the implementation
void loadGlobalLevelFunctions( typeof( vkGetInstanceProcAddr ) getProcAddr ) {
	vkGetInstanceProcAddr = getProcAddr;
	vkEnumerateInstanceExtensionProperties = cast( typeof( vkEnumerateInstanceExtensionProperties )) vkGetInstanceProcAddr( null, "vkEnumerateInstanceExtensionProperties" );
	vkEnumerateInstanceLayerProperties = cast( typeof( vkEnumerateInstanceLayerProperties )) vkGetInstanceProcAddr( null, "vkEnumerateInstanceLayerProperties" );
	vkCreateInstance = cast( typeof( vkCreateInstance )) vkGetInstanceProcAddr( null, "vkCreateInstance" );
}

/// with a valid VkInstance call this function to retrieve additional VkInstance, VkPhysicalDevice, ... related functions
void loadInstanceLevelFunctions( VkInstance instance ) {
	assert( vkGetInstanceProcAddr !is null, "Must call loadGlobalLevelFunctions before loadInstanceLevelFunctions" );

	// VK_VERSION_1_0
	vkDestroyInstance = cast( typeof( vkDestroyInstance )) vkGetInstanceProcAddr( instance, "vkDestroyInstance" );
	vkEnumeratePhysicalDevices = cast( typeof( vkEnumeratePhysicalDevices )) vkGetInstanceProcAddr( instance, "vkEnumeratePhysicalDevices" );
	vkGetPhysicalDeviceFeatures = cast( typeof( vkGetPhysicalDeviceFeatures )) vkGetInstanceProcAddr( instance, "vkGetPhysicalDeviceFeatures" );
	vkGetPhysicalDeviceFormatProperties = cast( typeof( vkGetPhysicalDeviceFormatProperties )) vkGetInstanceProcAddr( instance, "vkGetPhysicalDeviceFormatProperties" );
	vkGetPhysicalDeviceImageFormatProperties = cast( typeof( vkGetPhysicalDeviceImageFormatProperties )) vkGetInstanceProcAddr( instance, "vkGetPhysicalDeviceImageFormatProperties" );
	vkGetPhysicalDeviceProperties = cast( typeof( vkGetPhysicalDeviceProperties )) vkGetInstanceProcAddr( instance, "vkGetPhysicalDeviceProperties" );
	vkGetPhysicalDeviceQueueFamilyProperties = cast( typeof( vkGetPhysicalDeviceQueueFamilyProperties )) vkGetInstanceProcAddr( instance, "vkGetPhysicalDeviceQueueFamilyProperties" );
	vkGetPhysicalDeviceMemoryProperties = cast( typeof( vkGetPhysicalDeviceMemoryProperties )) vkGetInstanceProcAddr( instance, "vkGetPhysicalDeviceMemoryProperties" );
	vkGetDeviceProcAddr = cast( typeof( vkGetDeviceProcAddr )) vkGetInstanceProcAddr( instance, "vkGetDeviceProcAddr" );
	vkCreateDevice = cast( typeof( vkCreateDevice )) vkGetInstanceProcAddr( instance, "vkCreateDevice" );
	vkEnumerateDeviceExtensionProperties = cast( typeof( vkEnumerateDeviceExtensionProperties )) vkGetInstanceProcAddr( instance, "vkEnumerateDeviceExtensionProperties" );
	vkEnumerateDeviceLayerProperties = cast( typeof( vkEnumerateDeviceLayerProperties )) vkGetInstanceProcAddr( instance, "vkEnumerateDeviceLayerProperties" );
	vkGetPhysicalDeviceSparseImageFormatProperties = cast( typeof( vkGetPhysicalDeviceSparseImageFormatProperties )) vkGetInstanceProcAddr( instance, "vkGetPhysicalDeviceSparseImageFormatProperties" );

	// VK_KHR_surface
	vkDestroySurfaceKHR = cast( typeof( vkDestroySurfaceKHR )) vkGetInstanceProcAddr( instance, "vkDestroySurfaceKHR" );
	vkGetPhysicalDeviceSurfaceSupportKHR = cast( typeof( vkGetPhysicalDeviceSurfaceSupportKHR )) vkGetInstanceProcAddr( instance, "vkGetPhysicalDeviceSurfaceSupportKHR" );
	vkGetPhysicalDeviceSurfaceCapabilitiesKHR = cast( typeof( vkGetPhysicalDeviceSurfaceCapabilitiesKHR )) vkGetInstanceProcAddr( instance, "vkGetPhysicalDeviceSurfaceCapabilitiesKHR" );
	vkGetPhysicalDeviceSurfaceFormatsKHR = cast( typeof( vkGetPhysicalDeviceSurfaceFormatsKHR )) vkGetInstanceProcAddr( instance, "vkGetPhysicalDeviceSurfaceFormatsKHR" );
	vkGetPhysicalDeviceSurfacePresentModesKHR = cast( typeof( vkGetPhysicalDeviceSurfacePresentModesKHR )) vkGetInstanceProcAddr( instance, "vkGetPhysicalDeviceSurfacePresentModesKHR" );

	// VK_KHR_display
	vkGetPhysicalDeviceDisplayPropertiesKHR = cast( typeof( vkGetPhysicalDeviceDisplayPropertiesKHR )) vkGetInstanceProcAddr( instance, "vkGetPhysicalDeviceDisplayPropertiesKHR" );
	vkGetPhysicalDeviceDisplayPlanePropertiesKHR = cast( typeof( vkGetPhysicalDeviceDisplayPlanePropertiesKHR )) vkGetInstanceProcAddr( instance, "vkGetPhysicalDeviceDisplayPlanePropertiesKHR" );
	vkGetDisplayPlaneSupportedDisplaysKHR = cast( typeof( vkGetDisplayPlaneSupportedDisplaysKHR )) vkGetInstanceProcAddr( instance, "vkGetDisplayPlaneSupportedDisplaysKHR" );
	vkGetDisplayModePropertiesKHR = cast( typeof( vkGetDisplayModePropertiesKHR )) vkGetInstanceProcAddr( instance, "vkGetDisplayModePropertiesKHR" );
	vkCreateDisplayModeKHR = cast( typeof( vkCreateDisplayModeKHR )) vkGetInstanceProcAddr( instance, "vkCreateDisplayModeKHR" );
	vkGetDisplayPlaneCapabilitiesKHR = cast( typeof( vkGetDisplayPlaneCapabilitiesKHR )) vkGetInstanceProcAddr( instance, "vkGetDisplayPlaneCapabilitiesKHR" );
	vkCreateDisplayPlaneSurfaceKHR = cast( typeof( vkCreateDisplayPlaneSurfaceKHR )) vkGetInstanceProcAddr( instance, "vkCreateDisplayPlaneSurfaceKHR" );

	// VK_KHR_xlib_surface
	version( VK_USE_PLATFORM_XLIB_KHR ) {
		vkCreateXlibSurfaceKHR = cast( typeof( vkCreateXlibSurfaceKHR )) vkGetInstanceProcAddr( instance, "vkCreateXlibSurfaceKHR" );
		vkGetPhysicalDeviceXlibPresentationSupportKHR = cast( typeof( vkGetPhysicalDeviceXlibPresentationSupportKHR )) vkGetInstanceProcAddr( instance, "vkGetPhysicalDeviceXlibPresentationSupportKHR" );
	}

	// VK_KHR_xcb_surface
	version( VK_USE_PLATFORM_XCB_KHR ) {
		vkCreateXcbSurfaceKHR = cast( typeof( vkCreateXcbSurfaceKHR )) vkGetInstanceProcAddr( instance, "vkCreateXcbSurfaceKHR" );
		vkGetPhysicalDeviceXcbPresentationSupportKHR = cast( typeof( vkGetPhysicalDeviceXcbPresentationSupportKHR )) vkGetInstanceProcAddr( instance, "vkGetPhysicalDeviceXcbPresentationSupportKHR" );
	}

	// VK_KHR_wayland_surface
	version( VK_USE_PLATFORM_WAYLAND_KHR ) {
		vkCreateWaylandSurfaceKHR = cast( typeof( vkCreateWaylandSurfaceKHR )) vkGetInstanceProcAddr( instance, "vkCreateWaylandSurfaceKHR" );
		vkGetPhysicalDeviceWaylandPresentationSupportKHR = cast( typeof( vkGetPhysicalDeviceWaylandPresentationSupportKHR )) vkGetInstanceProcAddr( instance, "vkGetPhysicalDeviceWaylandPresentationSupportKHR" );
	}

	// VK_KHR_mir_surface
	version( VK_USE_PLATFORM_MIR_KHR ) {
		vkCreateMirSurfaceKHR = cast( typeof( vkCreateMirSurfaceKHR )) vkGetInstanceProcAddr( instance, "vkCreateMirSurfaceKHR" );
		vkGetPhysicalDeviceMirPresentationSupportKHR = cast( typeof( vkGetPhysicalDeviceMirPresentationSupportKHR )) vkGetInstanceProcAddr( instance, "vkGetPhysicalDeviceMirPresentationSupportKHR" );
	}

	// VK_KHR_android_surface
	version( VK_USE_PLATFORM_ANDROID_KHR ) {
		vkCreateAndroidSurfaceKHR = cast( typeof( vkCreateAndroidSurfaceKHR )) vkGetInstanceProcAddr( instance, "vkCreateAndroidSurfaceKHR" );
	}

	// VK_KHR_win32_surface
	version( VK_USE_PLATFORM_WIN32_KHR ) {
		vkCreateWin32SurfaceKHR = cast( typeof( vkCreateWin32SurfaceKHR )) vkGetInstanceProcAddr( instance, "vkCreateWin32SurfaceKHR" );
		vkGetPhysicalDeviceWin32PresentationSupportKHR = cast( typeof( vkGetPhysicalDeviceWin32PresentationSupportKHR )) vkGetInstanceProcAddr( instance, "vkGetPhysicalDeviceWin32PresentationSupportKHR" );
	}

	// VK_KHR_get_physical_device_properties2
	vkGetPhysicalDeviceFeatures2KHR = cast( typeof( vkGetPhysicalDeviceFeatures2KHR )) vkGetInstanceProcAddr( instance, "vkGetPhysicalDeviceFeatures2KHR" );
	vkGetPhysicalDeviceProperties2KHR = cast( typeof( vkGetPhysicalDeviceProperties2KHR )) vkGetInstanceProcAddr( instance, "vkGetPhysicalDeviceProperties2KHR" );
	vkGetPhysicalDeviceFormatProperties2KHR = cast( typeof( vkGetPhysicalDeviceFormatProperties2KHR )) vkGetInstanceProcAddr( instance, "vkGetPhysicalDeviceFormatProperties2KHR" );
	vkGetPhysicalDeviceImageFormatProperties2KHR = cast( typeof( vkGetPhysicalDeviceImageFormatProperties2KHR )) vkGetInstanceProcAddr( instance, "vkGetPhysicalDeviceImageFormatProperties2KHR" );
	vkGetPhysicalDeviceQueueFamilyProperties2KHR = cast( typeof( vkGetPhysicalDeviceQueueFamilyProperties2KHR )) vkGetInstanceProcAddr( instance, "vkGetPhysicalDeviceQueueFamilyProperties2KHR" );
	vkGetPhysicalDeviceMemoryProperties2KHR = cast( typeof( vkGetPhysicalDeviceMemoryProperties2KHR )) vkGetInstanceProcAddr( instance, "vkGetPhysicalDeviceMemoryProperties2KHR" );
	vkGetPhysicalDeviceSparseImageFormatProperties2KHR = cast( typeof( vkGetPhysicalDeviceSparseImageFormatProperties2KHR )) vkGetInstanceProcAddr( instance, "vkGetPhysicalDeviceSparseImageFormatProperties2KHR" );

	// VK_KHR_external_memory_capabilities
	vkGetPhysicalDeviceExternalBufferPropertiesKHR = cast( typeof( vkGetPhysicalDeviceExternalBufferPropertiesKHR )) vkGetInstanceProcAddr( instance, "vkGetPhysicalDeviceExternalBufferPropertiesKHR" );

	// VK_KHR_external_semaphore_capabilities
	vkGetPhysicalDeviceExternalSemaphorePropertiesKHR = cast( typeof( vkGetPhysicalDeviceExternalSemaphorePropertiesKHR )) vkGetInstanceProcAddr( instance, "vkGetPhysicalDeviceExternalSemaphorePropertiesKHR" );

	// VK_KHR_external_fence_capabilities
	vkGetPhysicalDeviceExternalFencePropertiesKHR = cast( typeof( vkGetPhysicalDeviceExternalFencePropertiesKHR )) vkGetInstanceProcAddr( instance, "vkGetPhysicalDeviceExternalFencePropertiesKHR" );

	// VK_KHR_get_surface_capabilities2
	vkGetPhysicalDeviceSurfaceCapabilities2KHR = cast( typeof( vkGetPhysicalDeviceSurfaceCapabilities2KHR )) vkGetInstanceProcAddr( instance, "vkGetPhysicalDeviceSurfaceCapabilities2KHR" );
	vkGetPhysicalDeviceSurfaceFormats2KHR = cast( typeof( vkGetPhysicalDeviceSurfaceFormats2KHR )) vkGetInstanceProcAddr( instance, "vkGetPhysicalDeviceSurfaceFormats2KHR" );

	// VK_EXT_debug_report
	vkCreateDebugReportCallbackEXT = cast( typeof( vkCreateDebugReportCallbackEXT )) vkGetInstanceProcAddr( instance, "vkCreateDebugReportCallbackEXT" );
	vkDestroyDebugReportCallbackEXT = cast( typeof( vkDestroyDebugReportCallbackEXT )) vkGetInstanceProcAddr( instance, "vkDestroyDebugReportCallbackEXT" );
	vkDebugReportMessageEXT = cast( typeof( vkDebugReportMessageEXT )) vkGetInstanceProcAddr( instance, "vkDebugReportMessageEXT" );

	// VK_NV_external_memory_capabilities
	vkGetPhysicalDeviceExternalImageFormatPropertiesNV = cast( typeof( vkGetPhysicalDeviceExternalImageFormatPropertiesNV )) vkGetInstanceProcAddr( instance, "vkGetPhysicalDeviceExternalImageFormatPropertiesNV" );

	// VK_KHX_device_group
	vkGetPhysicalDevicePresentRectanglesKHX = cast( typeof( vkGetPhysicalDevicePresentRectanglesKHX )) vkGetInstanceProcAddr( instance, "vkGetPhysicalDevicePresentRectanglesKHX" );

	// VK_NN_vi_surface
	vkCreateViSurfaceNN = cast( typeof( vkCreateViSurfaceNN )) vkGetInstanceProcAddr( instance, "vkCreateViSurfaceNN" );

	// VK_KHX_device_group_creation
	vkEnumeratePhysicalDeviceGroupsKHX = cast( typeof( vkEnumeratePhysicalDeviceGroupsKHX )) vkGetInstanceProcAddr( instance, "vkEnumeratePhysicalDeviceGroupsKHX" );

	// VK_NVX_device_generated_commands
	vkGetPhysicalDeviceGeneratedCommandsPropertiesNVX = cast( typeof( vkGetPhysicalDeviceGeneratedCommandsPropertiesNVX )) vkGetInstanceProcAddr( instance, "vkGetPhysicalDeviceGeneratedCommandsPropertiesNVX" );

	// VK_EXT_direct_mode_display
	vkReleaseDisplayEXT = cast( typeof( vkReleaseDisplayEXT )) vkGetInstanceProcAddr( instance, "vkReleaseDisplayEXT" );

	// VK_EXT_acquire_xlib_display
	version( VK_USE_PLATFORM_XLIB_KHR ) {
		vkAcquireXlibDisplayEXT = cast( typeof( vkAcquireXlibDisplayEXT )) vkGetInstanceProcAddr( instance, "vkAcquireXlibDisplayEXT" );
		vkGetRandROutputDisplayEXT = cast( typeof( vkGetRandROutputDisplayEXT )) vkGetInstanceProcAddr( instance, "vkGetRandROutputDisplayEXT" );
	}

	// VK_EXT_display_surface_counter
	vkGetPhysicalDeviceSurfaceCapabilities2EXT = cast( typeof( vkGetPhysicalDeviceSurfaceCapabilities2EXT )) vkGetInstanceProcAddr( instance, "vkGetPhysicalDeviceSurfaceCapabilities2EXT" );

	// VK_MVK_ios_surface
	vkCreateIOSSurfaceMVK = cast( typeof( vkCreateIOSSurfaceMVK )) vkGetInstanceProcAddr( instance, "vkCreateIOSSurfaceMVK" );

	// VK_MVK_macos_surface
	vkCreateMacOSSurfaceMVK = cast( typeof( vkCreateMacOSSurfaceMVK )) vkGetInstanceProcAddr( instance, "vkCreateMacOSSurfaceMVK" );

	// VK_EXT_sample_locations
	vkGetPhysicalDeviceMultisamplePropertiesEXT = cast( typeof( vkGetPhysicalDeviceMultisamplePropertiesEXT )) vkGetInstanceProcAddr( instance, "vkGetPhysicalDeviceMultisamplePropertiesEXT" );
}

/// with a valid VkInstance call this function to retrieve VkDevice, VkQueue and VkCommandBuffer related functions
/// the functions call indirectly through the VkInstance and will be internally dispatched by the implementation
/// use loadDeviceLevelFunctions( VkDevice device ) bellow to avoid this indirection and get the pointers directly form a VkDevice
void loadDeviceLevelFunctions( VkInstance instance ) {
	assert( vkGetInstanceProcAddr !is null, "Must call loadInstanceLevelFunctions before loadDeviceLevelFunctions" );

	// VK_VERSION_1_0
	vkDestroyDevice = cast( typeof( vkDestroyDevice )) vkGetInstanceProcAddr( instance, "vkDestroyDevice" );
	vkGetDeviceQueue = cast( typeof( vkGetDeviceQueue )) vkGetInstanceProcAddr( instance, "vkGetDeviceQueue" );
	vkQueueSubmit = cast( typeof( vkQueueSubmit )) vkGetInstanceProcAddr( instance, "vkQueueSubmit" );
	vkQueueWaitIdle = cast( typeof( vkQueueWaitIdle )) vkGetInstanceProcAddr( instance, "vkQueueWaitIdle" );
	vkDeviceWaitIdle = cast( typeof( vkDeviceWaitIdle )) vkGetInstanceProcAddr( instance, "vkDeviceWaitIdle" );
	vkAllocateMemory = cast( typeof( vkAllocateMemory )) vkGetInstanceProcAddr( instance, "vkAllocateMemory" );
	vkFreeMemory = cast( typeof( vkFreeMemory )) vkGetInstanceProcAddr( instance, "vkFreeMemory" );
	vkMapMemory = cast( typeof( vkMapMemory )) vkGetInstanceProcAddr( instance, "vkMapMemory" );
	vkUnmapMemory = cast( typeof( vkUnmapMemory )) vkGetInstanceProcAddr( instance, "vkUnmapMemory" );
	vkFlushMappedMemoryRanges = cast( typeof( vkFlushMappedMemoryRanges )) vkGetInstanceProcAddr( instance, "vkFlushMappedMemoryRanges" );
	vkInvalidateMappedMemoryRanges = cast( typeof( vkInvalidateMappedMemoryRanges )) vkGetInstanceProcAddr( instance, "vkInvalidateMappedMemoryRanges" );
	vkGetDeviceMemoryCommitment = cast( typeof( vkGetDeviceMemoryCommitment )) vkGetInstanceProcAddr( instance, "vkGetDeviceMemoryCommitment" );
	vkBindBufferMemory = cast( typeof( vkBindBufferMemory )) vkGetInstanceProcAddr( instance, "vkBindBufferMemory" );
	vkBindImageMemory = cast( typeof( vkBindImageMemory )) vkGetInstanceProcAddr( instance, "vkBindImageMemory" );
	vkGetBufferMemoryRequirements = cast( typeof( vkGetBufferMemoryRequirements )) vkGetInstanceProcAddr( instance, "vkGetBufferMemoryRequirements" );
	vkGetImageMemoryRequirements = cast( typeof( vkGetImageMemoryRequirements )) vkGetInstanceProcAddr( instance, "vkGetImageMemoryRequirements" );
	vkGetImageSparseMemoryRequirements = cast( typeof( vkGetImageSparseMemoryRequirements )) vkGetInstanceProcAddr( instance, "vkGetImageSparseMemoryRequirements" );
	vkQueueBindSparse = cast( typeof( vkQueueBindSparse )) vkGetInstanceProcAddr( instance, "vkQueueBindSparse" );
	vkCreateFence = cast( typeof( vkCreateFence )) vkGetInstanceProcAddr( instance, "vkCreateFence" );
	vkDestroyFence = cast( typeof( vkDestroyFence )) vkGetInstanceProcAddr( instance, "vkDestroyFence" );
	vkResetFences = cast( typeof( vkResetFences )) vkGetInstanceProcAddr( instance, "vkResetFences" );
	vkGetFenceStatus = cast( typeof( vkGetFenceStatus )) vkGetInstanceProcAddr( instance, "vkGetFenceStatus" );
	vkWaitForFences = cast( typeof( vkWaitForFences )) vkGetInstanceProcAddr( instance, "vkWaitForFences" );
	vkCreateSemaphore = cast( typeof( vkCreateSemaphore )) vkGetInstanceProcAddr( instance, "vkCreateSemaphore" );
	vkDestroySemaphore = cast( typeof( vkDestroySemaphore )) vkGetInstanceProcAddr( instance, "vkDestroySemaphore" );
	vkCreateEvent = cast( typeof( vkCreateEvent )) vkGetInstanceProcAddr( instance, "vkCreateEvent" );
	vkDestroyEvent = cast( typeof( vkDestroyEvent )) vkGetInstanceProcAddr( instance, "vkDestroyEvent" );
	vkGetEventStatus = cast( typeof( vkGetEventStatus )) vkGetInstanceProcAddr( instance, "vkGetEventStatus" );
	vkSetEvent = cast( typeof( vkSetEvent )) vkGetInstanceProcAddr( instance, "vkSetEvent" );
	vkResetEvent = cast( typeof( vkResetEvent )) vkGetInstanceProcAddr( instance, "vkResetEvent" );
	vkCreateQueryPool = cast( typeof( vkCreateQueryPool )) vkGetInstanceProcAddr( instance, "vkCreateQueryPool" );
	vkDestroyQueryPool = cast( typeof( vkDestroyQueryPool )) vkGetInstanceProcAddr( instance, "vkDestroyQueryPool" );
	vkGetQueryPoolResults = cast( typeof( vkGetQueryPoolResults )) vkGetInstanceProcAddr( instance, "vkGetQueryPoolResults" );
	vkCreateBuffer = cast( typeof( vkCreateBuffer )) vkGetInstanceProcAddr( instance, "vkCreateBuffer" );
	vkDestroyBuffer = cast( typeof( vkDestroyBuffer )) vkGetInstanceProcAddr( instance, "vkDestroyBuffer" );
	vkCreateBufferView = cast( typeof( vkCreateBufferView )) vkGetInstanceProcAddr( instance, "vkCreateBufferView" );
	vkDestroyBufferView = cast( typeof( vkDestroyBufferView )) vkGetInstanceProcAddr( instance, "vkDestroyBufferView" );
	vkCreateImage = cast( typeof( vkCreateImage )) vkGetInstanceProcAddr( instance, "vkCreateImage" );
	vkDestroyImage = cast( typeof( vkDestroyImage )) vkGetInstanceProcAddr( instance, "vkDestroyImage" );
	vkGetImageSubresourceLayout = cast( typeof( vkGetImageSubresourceLayout )) vkGetInstanceProcAddr( instance, "vkGetImageSubresourceLayout" );
	vkCreateImageView = cast( typeof( vkCreateImageView )) vkGetInstanceProcAddr( instance, "vkCreateImageView" );
	vkDestroyImageView = cast( typeof( vkDestroyImageView )) vkGetInstanceProcAddr( instance, "vkDestroyImageView" );
	vkCreateShaderModule = cast( typeof( vkCreateShaderModule )) vkGetInstanceProcAddr( instance, "vkCreateShaderModule" );
	vkDestroyShaderModule = cast( typeof( vkDestroyShaderModule )) vkGetInstanceProcAddr( instance, "vkDestroyShaderModule" );
	vkCreatePipelineCache = cast( typeof( vkCreatePipelineCache )) vkGetInstanceProcAddr( instance, "vkCreatePipelineCache" );
	vkDestroyPipelineCache = cast( typeof( vkDestroyPipelineCache )) vkGetInstanceProcAddr( instance, "vkDestroyPipelineCache" );
	vkGetPipelineCacheData = cast( typeof( vkGetPipelineCacheData )) vkGetInstanceProcAddr( instance, "vkGetPipelineCacheData" );
	vkMergePipelineCaches = cast( typeof( vkMergePipelineCaches )) vkGetInstanceProcAddr( instance, "vkMergePipelineCaches" );
	vkCreateGraphicsPipelines = cast( typeof( vkCreateGraphicsPipelines )) vkGetInstanceProcAddr( instance, "vkCreateGraphicsPipelines" );
	vkCreateComputePipelines = cast( typeof( vkCreateComputePipelines )) vkGetInstanceProcAddr( instance, "vkCreateComputePipelines" );
	vkDestroyPipeline = cast( typeof( vkDestroyPipeline )) vkGetInstanceProcAddr( instance, "vkDestroyPipeline" );
	vkCreatePipelineLayout = cast( typeof( vkCreatePipelineLayout )) vkGetInstanceProcAddr( instance, "vkCreatePipelineLayout" );
	vkDestroyPipelineLayout = cast( typeof( vkDestroyPipelineLayout )) vkGetInstanceProcAddr( instance, "vkDestroyPipelineLayout" );
	vkCreateSampler = cast( typeof( vkCreateSampler )) vkGetInstanceProcAddr( instance, "vkCreateSampler" );
	vkDestroySampler = cast( typeof( vkDestroySampler )) vkGetInstanceProcAddr( instance, "vkDestroySampler" );
	vkCreateDescriptorSetLayout = cast( typeof( vkCreateDescriptorSetLayout )) vkGetInstanceProcAddr( instance, "vkCreateDescriptorSetLayout" );
	vkDestroyDescriptorSetLayout = cast( typeof( vkDestroyDescriptorSetLayout )) vkGetInstanceProcAddr( instance, "vkDestroyDescriptorSetLayout" );
	vkCreateDescriptorPool = cast( typeof( vkCreateDescriptorPool )) vkGetInstanceProcAddr( instance, "vkCreateDescriptorPool" );
	vkDestroyDescriptorPool = cast( typeof( vkDestroyDescriptorPool )) vkGetInstanceProcAddr( instance, "vkDestroyDescriptorPool" );
	vkResetDescriptorPool = cast( typeof( vkResetDescriptorPool )) vkGetInstanceProcAddr( instance, "vkResetDescriptorPool" );
	vkAllocateDescriptorSets = cast( typeof( vkAllocateDescriptorSets )) vkGetInstanceProcAddr( instance, "vkAllocateDescriptorSets" );
	vkFreeDescriptorSets = cast( typeof( vkFreeDescriptorSets )) vkGetInstanceProcAddr( instance, "vkFreeDescriptorSets" );
	vkUpdateDescriptorSets = cast( typeof( vkUpdateDescriptorSets )) vkGetInstanceProcAddr( instance, "vkUpdateDescriptorSets" );
	vkCreateFramebuffer = cast( typeof( vkCreateFramebuffer )) vkGetInstanceProcAddr( instance, "vkCreateFramebuffer" );
	vkDestroyFramebuffer = cast( typeof( vkDestroyFramebuffer )) vkGetInstanceProcAddr( instance, "vkDestroyFramebuffer" );
	vkCreateRenderPass = cast( typeof( vkCreateRenderPass )) vkGetInstanceProcAddr( instance, "vkCreateRenderPass" );
	vkDestroyRenderPass = cast( typeof( vkDestroyRenderPass )) vkGetInstanceProcAddr( instance, "vkDestroyRenderPass" );
	vkGetRenderAreaGranularity = cast( typeof( vkGetRenderAreaGranularity )) vkGetInstanceProcAddr( instance, "vkGetRenderAreaGranularity" );
	vkCreateCommandPool = cast( typeof( vkCreateCommandPool )) vkGetInstanceProcAddr( instance, "vkCreateCommandPool" );
	vkDestroyCommandPool = cast( typeof( vkDestroyCommandPool )) vkGetInstanceProcAddr( instance, "vkDestroyCommandPool" );
	vkResetCommandPool = cast( typeof( vkResetCommandPool )) vkGetInstanceProcAddr( instance, "vkResetCommandPool" );
	vkAllocateCommandBuffers = cast( typeof( vkAllocateCommandBuffers )) vkGetInstanceProcAddr( instance, "vkAllocateCommandBuffers" );
	vkFreeCommandBuffers = cast( typeof( vkFreeCommandBuffers )) vkGetInstanceProcAddr( instance, "vkFreeCommandBuffers" );
	vkBeginCommandBuffer = cast( typeof( vkBeginCommandBuffer )) vkGetInstanceProcAddr( instance, "vkBeginCommandBuffer" );
	vkEndCommandBuffer = cast( typeof( vkEndCommandBuffer )) vkGetInstanceProcAddr( instance, "vkEndCommandBuffer" );
	vkResetCommandBuffer = cast( typeof( vkResetCommandBuffer )) vkGetInstanceProcAddr( instance, "vkResetCommandBuffer" );
	vkCmdBindPipeline = cast( typeof( vkCmdBindPipeline )) vkGetInstanceProcAddr( instance, "vkCmdBindPipeline" );
	vkCmdSetViewport = cast( typeof( vkCmdSetViewport )) vkGetInstanceProcAddr( instance, "vkCmdSetViewport" );
	vkCmdSetScissor = cast( typeof( vkCmdSetScissor )) vkGetInstanceProcAddr( instance, "vkCmdSetScissor" );
	vkCmdSetLineWidth = cast( typeof( vkCmdSetLineWidth )) vkGetInstanceProcAddr( instance, "vkCmdSetLineWidth" );
	vkCmdSetDepthBias = cast( typeof( vkCmdSetDepthBias )) vkGetInstanceProcAddr( instance, "vkCmdSetDepthBias" );
	vkCmdSetBlendConstants = cast( typeof( vkCmdSetBlendConstants )) vkGetInstanceProcAddr( instance, "vkCmdSetBlendConstants" );
	vkCmdSetDepthBounds = cast( typeof( vkCmdSetDepthBounds )) vkGetInstanceProcAddr( instance, "vkCmdSetDepthBounds" );
	vkCmdSetStencilCompareMask = cast( typeof( vkCmdSetStencilCompareMask )) vkGetInstanceProcAddr( instance, "vkCmdSetStencilCompareMask" );
	vkCmdSetStencilWriteMask = cast( typeof( vkCmdSetStencilWriteMask )) vkGetInstanceProcAddr( instance, "vkCmdSetStencilWriteMask" );
	vkCmdSetStencilReference = cast( typeof( vkCmdSetStencilReference )) vkGetInstanceProcAddr( instance, "vkCmdSetStencilReference" );
	vkCmdBindDescriptorSets = cast( typeof( vkCmdBindDescriptorSets )) vkGetInstanceProcAddr( instance, "vkCmdBindDescriptorSets" );
	vkCmdBindIndexBuffer = cast( typeof( vkCmdBindIndexBuffer )) vkGetInstanceProcAddr( instance, "vkCmdBindIndexBuffer" );
	vkCmdBindVertexBuffers = cast( typeof( vkCmdBindVertexBuffers )) vkGetInstanceProcAddr( instance, "vkCmdBindVertexBuffers" );
	vkCmdDraw = cast( typeof( vkCmdDraw )) vkGetInstanceProcAddr( instance, "vkCmdDraw" );
	vkCmdDrawIndexed = cast( typeof( vkCmdDrawIndexed )) vkGetInstanceProcAddr( instance, "vkCmdDrawIndexed" );
	vkCmdDrawIndirect = cast( typeof( vkCmdDrawIndirect )) vkGetInstanceProcAddr( instance, "vkCmdDrawIndirect" );
	vkCmdDrawIndexedIndirect = cast( typeof( vkCmdDrawIndexedIndirect )) vkGetInstanceProcAddr( instance, "vkCmdDrawIndexedIndirect" );
	vkCmdDispatch = cast( typeof( vkCmdDispatch )) vkGetInstanceProcAddr( instance, "vkCmdDispatch" );
	vkCmdDispatchIndirect = cast( typeof( vkCmdDispatchIndirect )) vkGetInstanceProcAddr( instance, "vkCmdDispatchIndirect" );
	vkCmdCopyBuffer = cast( typeof( vkCmdCopyBuffer )) vkGetInstanceProcAddr( instance, "vkCmdCopyBuffer" );
	vkCmdCopyImage = cast( typeof( vkCmdCopyImage )) vkGetInstanceProcAddr( instance, "vkCmdCopyImage" );
	vkCmdBlitImage = cast( typeof( vkCmdBlitImage )) vkGetInstanceProcAddr( instance, "vkCmdBlitImage" );
	vkCmdCopyBufferToImage = cast( typeof( vkCmdCopyBufferToImage )) vkGetInstanceProcAddr( instance, "vkCmdCopyBufferToImage" );
	vkCmdCopyImageToBuffer = cast( typeof( vkCmdCopyImageToBuffer )) vkGetInstanceProcAddr( instance, "vkCmdCopyImageToBuffer" );
	vkCmdUpdateBuffer = cast( typeof( vkCmdUpdateBuffer )) vkGetInstanceProcAddr( instance, "vkCmdUpdateBuffer" );
	vkCmdFillBuffer = cast( typeof( vkCmdFillBuffer )) vkGetInstanceProcAddr( instance, "vkCmdFillBuffer" );
	vkCmdClearColorImage = cast( typeof( vkCmdClearColorImage )) vkGetInstanceProcAddr( instance, "vkCmdClearColorImage" );
	vkCmdClearDepthStencilImage = cast( typeof( vkCmdClearDepthStencilImage )) vkGetInstanceProcAddr( instance, "vkCmdClearDepthStencilImage" );
	vkCmdClearAttachments = cast( typeof( vkCmdClearAttachments )) vkGetInstanceProcAddr( instance, "vkCmdClearAttachments" );
	vkCmdResolveImage = cast( typeof( vkCmdResolveImage )) vkGetInstanceProcAddr( instance, "vkCmdResolveImage" );
	vkCmdSetEvent = cast( typeof( vkCmdSetEvent )) vkGetInstanceProcAddr( instance, "vkCmdSetEvent" );
	vkCmdResetEvent = cast( typeof( vkCmdResetEvent )) vkGetInstanceProcAddr( instance, "vkCmdResetEvent" );
	vkCmdWaitEvents = cast( typeof( vkCmdWaitEvents )) vkGetInstanceProcAddr( instance, "vkCmdWaitEvents" );
	vkCmdPipelineBarrier = cast( typeof( vkCmdPipelineBarrier )) vkGetInstanceProcAddr( instance, "vkCmdPipelineBarrier" );
	vkCmdBeginQuery = cast( typeof( vkCmdBeginQuery )) vkGetInstanceProcAddr( instance, "vkCmdBeginQuery" );
	vkCmdEndQuery = cast( typeof( vkCmdEndQuery )) vkGetInstanceProcAddr( instance, "vkCmdEndQuery" );
	vkCmdResetQueryPool = cast( typeof( vkCmdResetQueryPool )) vkGetInstanceProcAddr( instance, "vkCmdResetQueryPool" );
	vkCmdWriteTimestamp = cast( typeof( vkCmdWriteTimestamp )) vkGetInstanceProcAddr( instance, "vkCmdWriteTimestamp" );
	vkCmdCopyQueryPoolResults = cast( typeof( vkCmdCopyQueryPoolResults )) vkGetInstanceProcAddr( instance, "vkCmdCopyQueryPoolResults" );
	vkCmdPushConstants = cast( typeof( vkCmdPushConstants )) vkGetInstanceProcAddr( instance, "vkCmdPushConstants" );
	vkCmdBeginRenderPass = cast( typeof( vkCmdBeginRenderPass )) vkGetInstanceProcAddr( instance, "vkCmdBeginRenderPass" );
	vkCmdNextSubpass = cast( typeof( vkCmdNextSubpass )) vkGetInstanceProcAddr( instance, "vkCmdNextSubpass" );
	vkCmdEndRenderPass = cast( typeof( vkCmdEndRenderPass )) vkGetInstanceProcAddr( instance, "vkCmdEndRenderPass" );
	vkCmdExecuteCommands = cast( typeof( vkCmdExecuteCommands )) vkGetInstanceProcAddr( instance, "vkCmdExecuteCommands" );

	// VK_KHR_swapchain
	vkCreateSwapchainKHR = cast( typeof( vkCreateSwapchainKHR )) vkGetInstanceProcAddr( instance, "vkCreateSwapchainKHR" );
	vkDestroySwapchainKHR = cast( typeof( vkDestroySwapchainKHR )) vkGetInstanceProcAddr( instance, "vkDestroySwapchainKHR" );
	vkGetSwapchainImagesKHR = cast( typeof( vkGetSwapchainImagesKHR )) vkGetInstanceProcAddr( instance, "vkGetSwapchainImagesKHR" );
	vkAcquireNextImageKHR = cast( typeof( vkAcquireNextImageKHR )) vkGetInstanceProcAddr( instance, "vkAcquireNextImageKHR" );
	vkQueuePresentKHR = cast( typeof( vkQueuePresentKHR )) vkGetInstanceProcAddr( instance, "vkQueuePresentKHR" );

	// VK_KHR_display_swapchain
	vkCreateSharedSwapchainsKHR = cast( typeof( vkCreateSharedSwapchainsKHR )) vkGetInstanceProcAddr( instance, "vkCreateSharedSwapchainsKHR" );

	// VK_KHR_maintenance1
	vkTrimCommandPoolKHR = cast( typeof( vkTrimCommandPoolKHR )) vkGetInstanceProcAddr( instance, "vkTrimCommandPoolKHR" );

	// VK_KHR_external_memory_win32
	version( VK_USE_PLATFORM_WIN32_KHR ) {
		vkGetMemoryWin32HandleKHR = cast( typeof( vkGetMemoryWin32HandleKHR )) vkGetInstanceProcAddr( instance, "vkGetMemoryWin32HandleKHR" );
		vkGetMemoryWin32HandlePropertiesKHR = cast( typeof( vkGetMemoryWin32HandlePropertiesKHR )) vkGetInstanceProcAddr( instance, "vkGetMemoryWin32HandlePropertiesKHR" );
	}

	// VK_KHR_external_memory_fd
	vkGetMemoryFdKHR = cast( typeof( vkGetMemoryFdKHR )) vkGetInstanceProcAddr( instance, "vkGetMemoryFdKHR" );
	vkGetMemoryFdPropertiesKHR = cast( typeof( vkGetMemoryFdPropertiesKHR )) vkGetInstanceProcAddr( instance, "vkGetMemoryFdPropertiesKHR" );

	// VK_KHR_external_semaphore_win32
	version( VK_USE_PLATFORM_WIN32_KHR ) {
		vkImportSemaphoreWin32HandleKHR = cast( typeof( vkImportSemaphoreWin32HandleKHR )) vkGetInstanceProcAddr( instance, "vkImportSemaphoreWin32HandleKHR" );
		vkGetSemaphoreWin32HandleKHR = cast( typeof( vkGetSemaphoreWin32HandleKHR )) vkGetInstanceProcAddr( instance, "vkGetSemaphoreWin32HandleKHR" );
	}

	// VK_KHR_external_semaphore_fd
	vkImportSemaphoreFdKHR = cast( typeof( vkImportSemaphoreFdKHR )) vkGetInstanceProcAddr( instance, "vkImportSemaphoreFdKHR" );
	vkGetSemaphoreFdKHR = cast( typeof( vkGetSemaphoreFdKHR )) vkGetInstanceProcAddr( instance, "vkGetSemaphoreFdKHR" );

	// VK_KHR_push_descriptor
	vkCmdPushDescriptorSetKHR = cast( typeof( vkCmdPushDescriptorSetKHR )) vkGetInstanceProcAddr( instance, "vkCmdPushDescriptorSetKHR" );

	// VK_KHR_descriptor_update_template
	vkCreateDescriptorUpdateTemplateKHR = cast( typeof( vkCreateDescriptorUpdateTemplateKHR )) vkGetInstanceProcAddr( instance, "vkCreateDescriptorUpdateTemplateKHR" );
	vkDestroyDescriptorUpdateTemplateKHR = cast( typeof( vkDestroyDescriptorUpdateTemplateKHR )) vkGetInstanceProcAddr( instance, "vkDestroyDescriptorUpdateTemplateKHR" );
	vkUpdateDescriptorSetWithTemplateKHR = cast( typeof( vkUpdateDescriptorSetWithTemplateKHR )) vkGetInstanceProcAddr( instance, "vkUpdateDescriptorSetWithTemplateKHR" );
	vkCmdPushDescriptorSetWithTemplateKHR = cast( typeof( vkCmdPushDescriptorSetWithTemplateKHR )) vkGetInstanceProcAddr( instance, "vkCmdPushDescriptorSetWithTemplateKHR" );

	// VK_KHR_shared_presentable_image
	vkGetSwapchainStatusKHR = cast( typeof( vkGetSwapchainStatusKHR )) vkGetInstanceProcAddr( instance, "vkGetSwapchainStatusKHR" );

	// VK_KHR_external_fence_win32
	version( VK_USE_PLATFORM_WIN32_KHR ) {
		vkImportFenceWin32HandleKHR = cast( typeof( vkImportFenceWin32HandleKHR )) vkGetInstanceProcAddr( instance, "vkImportFenceWin32HandleKHR" );
		vkGetFenceWin32HandleKHR = cast( typeof( vkGetFenceWin32HandleKHR )) vkGetInstanceProcAddr( instance, "vkGetFenceWin32HandleKHR" );
	}

	// VK_KHR_external_fence_fd
	vkImportFenceFdKHR = cast( typeof( vkImportFenceFdKHR )) vkGetInstanceProcAddr( instance, "vkImportFenceFdKHR" );
	vkGetFenceFdKHR = cast( typeof( vkGetFenceFdKHR )) vkGetInstanceProcAddr( instance, "vkGetFenceFdKHR" );

	// VK_KHR_get_memory_requirements2
	vkGetImageMemoryRequirements2KHR = cast( typeof( vkGetImageMemoryRequirements2KHR )) vkGetInstanceProcAddr( instance, "vkGetImageMemoryRequirements2KHR" );
	vkGetBufferMemoryRequirements2KHR = cast( typeof( vkGetBufferMemoryRequirements2KHR )) vkGetInstanceProcAddr( instance, "vkGetBufferMemoryRequirements2KHR" );
	vkGetImageSparseMemoryRequirements2KHR = cast( typeof( vkGetImageSparseMemoryRequirements2KHR )) vkGetInstanceProcAddr( instance, "vkGetImageSparseMemoryRequirements2KHR" );

	// VK_KHR_sampler_ycbcr_conversion
	vkCreateSamplerYcbcrConversionKHR = cast( typeof( vkCreateSamplerYcbcrConversionKHR )) vkGetInstanceProcAddr( instance, "vkCreateSamplerYcbcrConversionKHR" );
	vkDestroySamplerYcbcrConversionKHR = cast( typeof( vkDestroySamplerYcbcrConversionKHR )) vkGetInstanceProcAddr( instance, "vkDestroySamplerYcbcrConversionKHR" );

	// VK_KHR_bind_memory2
	vkBindBufferMemory2KHR = cast( typeof( vkBindBufferMemory2KHR )) vkGetInstanceProcAddr( instance, "vkBindBufferMemory2KHR" );
	vkBindImageMemory2KHR = cast( typeof( vkBindImageMemory2KHR )) vkGetInstanceProcAddr( instance, "vkBindImageMemory2KHR" );

	// VK_ANDROID_native_buffer
	vkGetSwapchainGrallocUsageANDROID = cast( typeof( vkGetSwapchainGrallocUsageANDROID )) vkGetInstanceProcAddr( instance, "vkGetSwapchainGrallocUsageANDROID" );
	vkAcquireImageANDROID = cast( typeof( vkAcquireImageANDROID )) vkGetInstanceProcAddr( instance, "vkAcquireImageANDROID" );
	vkQueueSignalReleaseImageANDROID = cast( typeof( vkQueueSignalReleaseImageANDROID )) vkGetInstanceProcAddr( instance, "vkQueueSignalReleaseImageANDROID" );

	// VK_EXT_debug_marker
	vkDebugMarkerSetObjectTagEXT = cast( typeof( vkDebugMarkerSetObjectTagEXT )) vkGetInstanceProcAddr( instance, "vkDebugMarkerSetObjectTagEXT" );
	vkDebugMarkerSetObjectNameEXT = cast( typeof( vkDebugMarkerSetObjectNameEXT )) vkGetInstanceProcAddr( instance, "vkDebugMarkerSetObjectNameEXT" );
	vkCmdDebugMarkerBeginEXT = cast( typeof( vkCmdDebugMarkerBeginEXT )) vkGetInstanceProcAddr( instance, "vkCmdDebugMarkerBeginEXT" );
	vkCmdDebugMarkerEndEXT = cast( typeof( vkCmdDebugMarkerEndEXT )) vkGetInstanceProcAddr( instance, "vkCmdDebugMarkerEndEXT" );
	vkCmdDebugMarkerInsertEXT = cast( typeof( vkCmdDebugMarkerInsertEXT )) vkGetInstanceProcAddr( instance, "vkCmdDebugMarkerInsertEXT" );

	// VK_AMD_draw_indirect_count
	vkCmdDrawIndirectCountAMD = cast( typeof( vkCmdDrawIndirectCountAMD )) vkGetInstanceProcAddr( instance, "vkCmdDrawIndirectCountAMD" );
	vkCmdDrawIndexedIndirectCountAMD = cast( typeof( vkCmdDrawIndexedIndirectCountAMD )) vkGetInstanceProcAddr( instance, "vkCmdDrawIndexedIndirectCountAMD" );

	// VK_AMD_shader_info
	vkGetShaderInfoAMD = cast( typeof( vkGetShaderInfoAMD )) vkGetInstanceProcAddr( instance, "vkGetShaderInfoAMD" );

	// VK_NV_external_memory_win32
	version( VK_USE_PLATFORM_WIN32_KHR ) {
		vkGetMemoryWin32HandleNV = cast( typeof( vkGetMemoryWin32HandleNV )) vkGetInstanceProcAddr( instance, "vkGetMemoryWin32HandleNV" );
	}

	// VK_KHX_device_group
	vkGetDeviceGroupPeerMemoryFeaturesKHX = cast( typeof( vkGetDeviceGroupPeerMemoryFeaturesKHX )) vkGetInstanceProcAddr( instance, "vkGetDeviceGroupPeerMemoryFeaturesKHX" );
	vkCmdSetDeviceMaskKHX = cast( typeof( vkCmdSetDeviceMaskKHX )) vkGetInstanceProcAddr( instance, "vkCmdSetDeviceMaskKHX" );
	vkCmdDispatchBaseKHX = cast( typeof( vkCmdDispatchBaseKHX )) vkGetInstanceProcAddr( instance, "vkCmdDispatchBaseKHX" );
	vkGetDeviceGroupPresentCapabilitiesKHX = cast( typeof( vkGetDeviceGroupPresentCapabilitiesKHX )) vkGetInstanceProcAddr( instance, "vkGetDeviceGroupPresentCapabilitiesKHX" );
	vkGetDeviceGroupSurfacePresentModesKHX = cast( typeof( vkGetDeviceGroupSurfacePresentModesKHX )) vkGetInstanceProcAddr( instance, "vkGetDeviceGroupSurfacePresentModesKHX" );
	vkAcquireNextImage2KHX = cast( typeof( vkAcquireNextImage2KHX )) vkGetInstanceProcAddr( instance, "vkAcquireNextImage2KHX" );

	// VK_NVX_device_generated_commands
	vkCmdProcessCommandsNVX = cast( typeof( vkCmdProcessCommandsNVX )) vkGetInstanceProcAddr( instance, "vkCmdProcessCommandsNVX" );
	vkCmdReserveSpaceForCommandsNVX = cast( typeof( vkCmdReserveSpaceForCommandsNVX )) vkGetInstanceProcAddr( instance, "vkCmdReserveSpaceForCommandsNVX" );
	vkCreateIndirectCommandsLayoutNVX = cast( typeof( vkCreateIndirectCommandsLayoutNVX )) vkGetInstanceProcAddr( instance, "vkCreateIndirectCommandsLayoutNVX" );
	vkDestroyIndirectCommandsLayoutNVX = cast( typeof( vkDestroyIndirectCommandsLayoutNVX )) vkGetInstanceProcAddr( instance, "vkDestroyIndirectCommandsLayoutNVX" );
	vkCreateObjectTableNVX = cast( typeof( vkCreateObjectTableNVX )) vkGetInstanceProcAddr( instance, "vkCreateObjectTableNVX" );
	vkDestroyObjectTableNVX = cast( typeof( vkDestroyObjectTableNVX )) vkGetInstanceProcAddr( instance, "vkDestroyObjectTableNVX" );
	vkRegisterObjectsNVX = cast( typeof( vkRegisterObjectsNVX )) vkGetInstanceProcAddr( instance, "vkRegisterObjectsNVX" );
	vkUnregisterObjectsNVX = cast( typeof( vkUnregisterObjectsNVX )) vkGetInstanceProcAddr( instance, "vkUnregisterObjectsNVX" );

	// VK_NV_clip_space_w_scaling
	vkCmdSetViewportWScalingNV = cast( typeof( vkCmdSetViewportWScalingNV )) vkGetInstanceProcAddr( instance, "vkCmdSetViewportWScalingNV" );

	// VK_EXT_display_control
	vkDisplayPowerControlEXT = cast( typeof( vkDisplayPowerControlEXT )) vkGetInstanceProcAddr( instance, "vkDisplayPowerControlEXT" );
	vkRegisterDeviceEventEXT = cast( typeof( vkRegisterDeviceEventEXT )) vkGetInstanceProcAddr( instance, "vkRegisterDeviceEventEXT" );
	vkRegisterDisplayEventEXT = cast( typeof( vkRegisterDisplayEventEXT )) vkGetInstanceProcAddr( instance, "vkRegisterDisplayEventEXT" );
	vkGetSwapchainCounterEXT = cast( typeof( vkGetSwapchainCounterEXT )) vkGetInstanceProcAddr( instance, "vkGetSwapchainCounterEXT" );

	// VK_GOOGLE_display_timing
	vkGetRefreshCycleDurationGOOGLE = cast( typeof( vkGetRefreshCycleDurationGOOGLE )) vkGetInstanceProcAddr( instance, "vkGetRefreshCycleDurationGOOGLE" );
	vkGetPastPresentationTimingGOOGLE = cast( typeof( vkGetPastPresentationTimingGOOGLE )) vkGetInstanceProcAddr( instance, "vkGetPastPresentationTimingGOOGLE" );

	// VK_EXT_discard_rectangles
	vkCmdSetDiscardRectangleEXT = cast( typeof( vkCmdSetDiscardRectangleEXT )) vkGetInstanceProcAddr( instance, "vkCmdSetDiscardRectangleEXT" );

	// VK_EXT_hdr_metadata
	vkSetHdrMetadataEXT = cast( typeof( vkSetHdrMetadataEXT )) vkGetInstanceProcAddr( instance, "vkSetHdrMetadataEXT" );

	// VK_EXT_sample_locations
	vkCmdSetSampleLocationsEXT = cast( typeof( vkCmdSetSampleLocationsEXT )) vkGetInstanceProcAddr( instance, "vkCmdSetSampleLocationsEXT" );

	// VK_EXT_validation_cache
	vkCreateValidationCacheEXT = cast( typeof( vkCreateValidationCacheEXT )) vkGetInstanceProcAddr( instance, "vkCreateValidationCacheEXT" );
	vkDestroyValidationCacheEXT = cast( typeof( vkDestroyValidationCacheEXT )) vkGetInstanceProcAddr( instance, "vkDestroyValidationCacheEXT" );
	vkMergeValidationCachesEXT = cast( typeof( vkMergeValidationCachesEXT )) vkGetInstanceProcAddr( instance, "vkMergeValidationCachesEXT" );
	vkGetValidationCacheDataEXT = cast( typeof( vkGetValidationCacheDataEXT )) vkGetInstanceProcAddr( instance, "vkGetValidationCacheDataEXT" );
}

/// with a valid VkDevice call this function to retrieve VkDevice, VkQueue and VkCommandBuffer related functions
/// the functions call directly VkDevice and related resources and can be retrieved for one and only one VkDevice
/// calling this function again with another VkDevices will overwrite the __gshared functions retrieved previously
/// use createGroupedDeviceLevelFunctions bellow if usage of multiple VkDevices is required
void loadDeviceLevelFunctions( VkDevice device ) {
	assert( vkGetDeviceProcAddr !is null, "Must call loadInstanceLevelFunctions before loadDeviceLevelFunctions" );

	// VK_VERSION_1_0
	vkDestroyDevice = cast( typeof( vkDestroyDevice )) vkGetDeviceProcAddr( device, "vkDestroyDevice" );
	vkGetDeviceQueue = cast( typeof( vkGetDeviceQueue )) vkGetDeviceProcAddr( device, "vkGetDeviceQueue" );
	vkQueueSubmit = cast( typeof( vkQueueSubmit )) vkGetDeviceProcAddr( device, "vkQueueSubmit" );
	vkQueueWaitIdle = cast( typeof( vkQueueWaitIdle )) vkGetDeviceProcAddr( device, "vkQueueWaitIdle" );
	vkDeviceWaitIdle = cast( typeof( vkDeviceWaitIdle )) vkGetDeviceProcAddr( device, "vkDeviceWaitIdle" );
	vkAllocateMemory = cast( typeof( vkAllocateMemory )) vkGetDeviceProcAddr( device, "vkAllocateMemory" );
	vkFreeMemory = cast( typeof( vkFreeMemory )) vkGetDeviceProcAddr( device, "vkFreeMemory" );
	vkMapMemory = cast( typeof( vkMapMemory )) vkGetDeviceProcAddr( device, "vkMapMemory" );
	vkUnmapMemory = cast( typeof( vkUnmapMemory )) vkGetDeviceProcAddr( device, "vkUnmapMemory" );
	vkFlushMappedMemoryRanges = cast( typeof( vkFlushMappedMemoryRanges )) vkGetDeviceProcAddr( device, "vkFlushMappedMemoryRanges" );
	vkInvalidateMappedMemoryRanges = cast( typeof( vkInvalidateMappedMemoryRanges )) vkGetDeviceProcAddr( device, "vkInvalidateMappedMemoryRanges" );
	vkGetDeviceMemoryCommitment = cast( typeof( vkGetDeviceMemoryCommitment )) vkGetDeviceProcAddr( device, "vkGetDeviceMemoryCommitment" );
	vkBindBufferMemory = cast( typeof( vkBindBufferMemory )) vkGetDeviceProcAddr( device, "vkBindBufferMemory" );
	vkBindImageMemory = cast( typeof( vkBindImageMemory )) vkGetDeviceProcAddr( device, "vkBindImageMemory" );
	vkGetBufferMemoryRequirements = cast( typeof( vkGetBufferMemoryRequirements )) vkGetDeviceProcAddr( device, "vkGetBufferMemoryRequirements" );
	vkGetImageMemoryRequirements = cast( typeof( vkGetImageMemoryRequirements )) vkGetDeviceProcAddr( device, "vkGetImageMemoryRequirements" );
	vkGetImageSparseMemoryRequirements = cast( typeof( vkGetImageSparseMemoryRequirements )) vkGetDeviceProcAddr( device, "vkGetImageSparseMemoryRequirements" );
	vkQueueBindSparse = cast( typeof( vkQueueBindSparse )) vkGetDeviceProcAddr( device, "vkQueueBindSparse" );
	vkCreateFence = cast( typeof( vkCreateFence )) vkGetDeviceProcAddr( device, "vkCreateFence" );
	vkDestroyFence = cast( typeof( vkDestroyFence )) vkGetDeviceProcAddr( device, "vkDestroyFence" );
	vkResetFences = cast( typeof( vkResetFences )) vkGetDeviceProcAddr( device, "vkResetFences" );
	vkGetFenceStatus = cast( typeof( vkGetFenceStatus )) vkGetDeviceProcAddr( device, "vkGetFenceStatus" );
	vkWaitForFences = cast( typeof( vkWaitForFences )) vkGetDeviceProcAddr( device, "vkWaitForFences" );
	vkCreateSemaphore = cast( typeof( vkCreateSemaphore )) vkGetDeviceProcAddr( device, "vkCreateSemaphore" );
	vkDestroySemaphore = cast( typeof( vkDestroySemaphore )) vkGetDeviceProcAddr( device, "vkDestroySemaphore" );
	vkCreateEvent = cast( typeof( vkCreateEvent )) vkGetDeviceProcAddr( device, "vkCreateEvent" );
	vkDestroyEvent = cast( typeof( vkDestroyEvent )) vkGetDeviceProcAddr( device, "vkDestroyEvent" );
	vkGetEventStatus = cast( typeof( vkGetEventStatus )) vkGetDeviceProcAddr( device, "vkGetEventStatus" );
	vkSetEvent = cast( typeof( vkSetEvent )) vkGetDeviceProcAddr( device, "vkSetEvent" );
	vkResetEvent = cast( typeof( vkResetEvent )) vkGetDeviceProcAddr( device, "vkResetEvent" );
	vkCreateQueryPool = cast( typeof( vkCreateQueryPool )) vkGetDeviceProcAddr( device, "vkCreateQueryPool" );
	vkDestroyQueryPool = cast( typeof( vkDestroyQueryPool )) vkGetDeviceProcAddr( device, "vkDestroyQueryPool" );
	vkGetQueryPoolResults = cast( typeof( vkGetQueryPoolResults )) vkGetDeviceProcAddr( device, "vkGetQueryPoolResults" );
	vkCreateBuffer = cast( typeof( vkCreateBuffer )) vkGetDeviceProcAddr( device, "vkCreateBuffer" );
	vkDestroyBuffer = cast( typeof( vkDestroyBuffer )) vkGetDeviceProcAddr( device, "vkDestroyBuffer" );
	vkCreateBufferView = cast( typeof( vkCreateBufferView )) vkGetDeviceProcAddr( device, "vkCreateBufferView" );
	vkDestroyBufferView = cast( typeof( vkDestroyBufferView )) vkGetDeviceProcAddr( device, "vkDestroyBufferView" );
	vkCreateImage = cast( typeof( vkCreateImage )) vkGetDeviceProcAddr( device, "vkCreateImage" );
	vkDestroyImage = cast( typeof( vkDestroyImage )) vkGetDeviceProcAddr( device, "vkDestroyImage" );
	vkGetImageSubresourceLayout = cast( typeof( vkGetImageSubresourceLayout )) vkGetDeviceProcAddr( device, "vkGetImageSubresourceLayout" );
	vkCreateImageView = cast( typeof( vkCreateImageView )) vkGetDeviceProcAddr( device, "vkCreateImageView" );
	vkDestroyImageView = cast( typeof( vkDestroyImageView )) vkGetDeviceProcAddr( device, "vkDestroyImageView" );
	vkCreateShaderModule = cast( typeof( vkCreateShaderModule )) vkGetDeviceProcAddr( device, "vkCreateShaderModule" );
	vkDestroyShaderModule = cast( typeof( vkDestroyShaderModule )) vkGetDeviceProcAddr( device, "vkDestroyShaderModule" );
	vkCreatePipelineCache = cast( typeof( vkCreatePipelineCache )) vkGetDeviceProcAddr( device, "vkCreatePipelineCache" );
	vkDestroyPipelineCache = cast( typeof( vkDestroyPipelineCache )) vkGetDeviceProcAddr( device, "vkDestroyPipelineCache" );
	vkGetPipelineCacheData = cast( typeof( vkGetPipelineCacheData )) vkGetDeviceProcAddr( device, "vkGetPipelineCacheData" );
	vkMergePipelineCaches = cast( typeof( vkMergePipelineCaches )) vkGetDeviceProcAddr( device, "vkMergePipelineCaches" );
	vkCreateGraphicsPipelines = cast( typeof( vkCreateGraphicsPipelines )) vkGetDeviceProcAddr( device, "vkCreateGraphicsPipelines" );
	vkCreateComputePipelines = cast( typeof( vkCreateComputePipelines )) vkGetDeviceProcAddr( device, "vkCreateComputePipelines" );
	vkDestroyPipeline = cast( typeof( vkDestroyPipeline )) vkGetDeviceProcAddr( device, "vkDestroyPipeline" );
	vkCreatePipelineLayout = cast( typeof( vkCreatePipelineLayout )) vkGetDeviceProcAddr( device, "vkCreatePipelineLayout" );
	vkDestroyPipelineLayout = cast( typeof( vkDestroyPipelineLayout )) vkGetDeviceProcAddr( device, "vkDestroyPipelineLayout" );
	vkCreateSampler = cast( typeof( vkCreateSampler )) vkGetDeviceProcAddr( device, "vkCreateSampler" );
	vkDestroySampler = cast( typeof( vkDestroySampler )) vkGetDeviceProcAddr( device, "vkDestroySampler" );
	vkCreateDescriptorSetLayout = cast( typeof( vkCreateDescriptorSetLayout )) vkGetDeviceProcAddr( device, "vkCreateDescriptorSetLayout" );
	vkDestroyDescriptorSetLayout = cast( typeof( vkDestroyDescriptorSetLayout )) vkGetDeviceProcAddr( device, "vkDestroyDescriptorSetLayout" );
	vkCreateDescriptorPool = cast( typeof( vkCreateDescriptorPool )) vkGetDeviceProcAddr( device, "vkCreateDescriptorPool" );
	vkDestroyDescriptorPool = cast( typeof( vkDestroyDescriptorPool )) vkGetDeviceProcAddr( device, "vkDestroyDescriptorPool" );
	vkResetDescriptorPool = cast( typeof( vkResetDescriptorPool )) vkGetDeviceProcAddr( device, "vkResetDescriptorPool" );
	vkAllocateDescriptorSets = cast( typeof( vkAllocateDescriptorSets )) vkGetDeviceProcAddr( device, "vkAllocateDescriptorSets" );
	vkFreeDescriptorSets = cast( typeof( vkFreeDescriptorSets )) vkGetDeviceProcAddr( device, "vkFreeDescriptorSets" );
	vkUpdateDescriptorSets = cast( typeof( vkUpdateDescriptorSets )) vkGetDeviceProcAddr( device, "vkUpdateDescriptorSets" );
	vkCreateFramebuffer = cast( typeof( vkCreateFramebuffer )) vkGetDeviceProcAddr( device, "vkCreateFramebuffer" );
	vkDestroyFramebuffer = cast( typeof( vkDestroyFramebuffer )) vkGetDeviceProcAddr( device, "vkDestroyFramebuffer" );
	vkCreateRenderPass = cast( typeof( vkCreateRenderPass )) vkGetDeviceProcAddr( device, "vkCreateRenderPass" );
	vkDestroyRenderPass = cast( typeof( vkDestroyRenderPass )) vkGetDeviceProcAddr( device, "vkDestroyRenderPass" );
	vkGetRenderAreaGranularity = cast( typeof( vkGetRenderAreaGranularity )) vkGetDeviceProcAddr( device, "vkGetRenderAreaGranularity" );
	vkCreateCommandPool = cast( typeof( vkCreateCommandPool )) vkGetDeviceProcAddr( device, "vkCreateCommandPool" );
	vkDestroyCommandPool = cast( typeof( vkDestroyCommandPool )) vkGetDeviceProcAddr( device, "vkDestroyCommandPool" );
	vkResetCommandPool = cast( typeof( vkResetCommandPool )) vkGetDeviceProcAddr( device, "vkResetCommandPool" );
	vkAllocateCommandBuffers = cast( typeof( vkAllocateCommandBuffers )) vkGetDeviceProcAddr( device, "vkAllocateCommandBuffers" );
	vkFreeCommandBuffers = cast( typeof( vkFreeCommandBuffers )) vkGetDeviceProcAddr( device, "vkFreeCommandBuffers" );
	vkBeginCommandBuffer = cast( typeof( vkBeginCommandBuffer )) vkGetDeviceProcAddr( device, "vkBeginCommandBuffer" );
	vkEndCommandBuffer = cast( typeof( vkEndCommandBuffer )) vkGetDeviceProcAddr( device, "vkEndCommandBuffer" );
	vkResetCommandBuffer = cast( typeof( vkResetCommandBuffer )) vkGetDeviceProcAddr( device, "vkResetCommandBuffer" );
	vkCmdBindPipeline = cast( typeof( vkCmdBindPipeline )) vkGetDeviceProcAddr( device, "vkCmdBindPipeline" );
	vkCmdSetViewport = cast( typeof( vkCmdSetViewport )) vkGetDeviceProcAddr( device, "vkCmdSetViewport" );
	vkCmdSetScissor = cast( typeof( vkCmdSetScissor )) vkGetDeviceProcAddr( device, "vkCmdSetScissor" );
	vkCmdSetLineWidth = cast( typeof( vkCmdSetLineWidth )) vkGetDeviceProcAddr( device, "vkCmdSetLineWidth" );
	vkCmdSetDepthBias = cast( typeof( vkCmdSetDepthBias )) vkGetDeviceProcAddr( device, "vkCmdSetDepthBias" );
	vkCmdSetBlendConstants = cast( typeof( vkCmdSetBlendConstants )) vkGetDeviceProcAddr( device, "vkCmdSetBlendConstants" );
	vkCmdSetDepthBounds = cast( typeof( vkCmdSetDepthBounds )) vkGetDeviceProcAddr( device, "vkCmdSetDepthBounds" );
	vkCmdSetStencilCompareMask = cast( typeof( vkCmdSetStencilCompareMask )) vkGetDeviceProcAddr( device, "vkCmdSetStencilCompareMask" );
	vkCmdSetStencilWriteMask = cast( typeof( vkCmdSetStencilWriteMask )) vkGetDeviceProcAddr( device, "vkCmdSetStencilWriteMask" );
	vkCmdSetStencilReference = cast( typeof( vkCmdSetStencilReference )) vkGetDeviceProcAddr( device, "vkCmdSetStencilReference" );
	vkCmdBindDescriptorSets = cast( typeof( vkCmdBindDescriptorSets )) vkGetDeviceProcAddr( device, "vkCmdBindDescriptorSets" );
	vkCmdBindIndexBuffer = cast( typeof( vkCmdBindIndexBuffer )) vkGetDeviceProcAddr( device, "vkCmdBindIndexBuffer" );
	vkCmdBindVertexBuffers = cast( typeof( vkCmdBindVertexBuffers )) vkGetDeviceProcAddr( device, "vkCmdBindVertexBuffers" );
	vkCmdDraw = cast( typeof( vkCmdDraw )) vkGetDeviceProcAddr( device, "vkCmdDraw" );
	vkCmdDrawIndexed = cast( typeof( vkCmdDrawIndexed )) vkGetDeviceProcAddr( device, "vkCmdDrawIndexed" );
	vkCmdDrawIndirect = cast( typeof( vkCmdDrawIndirect )) vkGetDeviceProcAddr( device, "vkCmdDrawIndirect" );
	vkCmdDrawIndexedIndirect = cast( typeof( vkCmdDrawIndexedIndirect )) vkGetDeviceProcAddr( device, "vkCmdDrawIndexedIndirect" );
	vkCmdDispatch = cast( typeof( vkCmdDispatch )) vkGetDeviceProcAddr( device, "vkCmdDispatch" );
	vkCmdDispatchIndirect = cast( typeof( vkCmdDispatchIndirect )) vkGetDeviceProcAddr( device, "vkCmdDispatchIndirect" );
	vkCmdCopyBuffer = cast( typeof( vkCmdCopyBuffer )) vkGetDeviceProcAddr( device, "vkCmdCopyBuffer" );
	vkCmdCopyImage = cast( typeof( vkCmdCopyImage )) vkGetDeviceProcAddr( device, "vkCmdCopyImage" );
	vkCmdBlitImage = cast( typeof( vkCmdBlitImage )) vkGetDeviceProcAddr( device, "vkCmdBlitImage" );
	vkCmdCopyBufferToImage = cast( typeof( vkCmdCopyBufferToImage )) vkGetDeviceProcAddr( device, "vkCmdCopyBufferToImage" );
	vkCmdCopyImageToBuffer = cast( typeof( vkCmdCopyImageToBuffer )) vkGetDeviceProcAddr( device, "vkCmdCopyImageToBuffer" );
	vkCmdUpdateBuffer = cast( typeof( vkCmdUpdateBuffer )) vkGetDeviceProcAddr( device, "vkCmdUpdateBuffer" );
	vkCmdFillBuffer = cast( typeof( vkCmdFillBuffer )) vkGetDeviceProcAddr( device, "vkCmdFillBuffer" );
	vkCmdClearColorImage = cast( typeof( vkCmdClearColorImage )) vkGetDeviceProcAddr( device, "vkCmdClearColorImage" );
	vkCmdClearDepthStencilImage = cast( typeof( vkCmdClearDepthStencilImage )) vkGetDeviceProcAddr( device, "vkCmdClearDepthStencilImage" );
	vkCmdClearAttachments = cast( typeof( vkCmdClearAttachments )) vkGetDeviceProcAddr( device, "vkCmdClearAttachments" );
	vkCmdResolveImage = cast( typeof( vkCmdResolveImage )) vkGetDeviceProcAddr( device, "vkCmdResolveImage" );
	vkCmdSetEvent = cast( typeof( vkCmdSetEvent )) vkGetDeviceProcAddr( device, "vkCmdSetEvent" );
	vkCmdResetEvent = cast( typeof( vkCmdResetEvent )) vkGetDeviceProcAddr( device, "vkCmdResetEvent" );
	vkCmdWaitEvents = cast( typeof( vkCmdWaitEvents )) vkGetDeviceProcAddr( device, "vkCmdWaitEvents" );
	vkCmdPipelineBarrier = cast( typeof( vkCmdPipelineBarrier )) vkGetDeviceProcAddr( device, "vkCmdPipelineBarrier" );
	vkCmdBeginQuery = cast( typeof( vkCmdBeginQuery )) vkGetDeviceProcAddr( device, "vkCmdBeginQuery" );
	vkCmdEndQuery = cast( typeof( vkCmdEndQuery )) vkGetDeviceProcAddr( device, "vkCmdEndQuery" );
	vkCmdResetQueryPool = cast( typeof( vkCmdResetQueryPool )) vkGetDeviceProcAddr( device, "vkCmdResetQueryPool" );
	vkCmdWriteTimestamp = cast( typeof( vkCmdWriteTimestamp )) vkGetDeviceProcAddr( device, "vkCmdWriteTimestamp" );
	vkCmdCopyQueryPoolResults = cast( typeof( vkCmdCopyQueryPoolResults )) vkGetDeviceProcAddr( device, "vkCmdCopyQueryPoolResults" );
	vkCmdPushConstants = cast( typeof( vkCmdPushConstants )) vkGetDeviceProcAddr( device, "vkCmdPushConstants" );
	vkCmdBeginRenderPass = cast( typeof( vkCmdBeginRenderPass )) vkGetDeviceProcAddr( device, "vkCmdBeginRenderPass" );
	vkCmdNextSubpass = cast( typeof( vkCmdNextSubpass )) vkGetDeviceProcAddr( device, "vkCmdNextSubpass" );
	vkCmdEndRenderPass = cast( typeof( vkCmdEndRenderPass )) vkGetDeviceProcAddr( device, "vkCmdEndRenderPass" );
	vkCmdExecuteCommands = cast( typeof( vkCmdExecuteCommands )) vkGetDeviceProcAddr( device, "vkCmdExecuteCommands" );

	// VK_KHR_swapchain
	vkCreateSwapchainKHR = cast( typeof( vkCreateSwapchainKHR )) vkGetDeviceProcAddr( device, "vkCreateSwapchainKHR" );
	vkDestroySwapchainKHR = cast( typeof( vkDestroySwapchainKHR )) vkGetDeviceProcAddr( device, "vkDestroySwapchainKHR" );
	vkGetSwapchainImagesKHR = cast( typeof( vkGetSwapchainImagesKHR )) vkGetDeviceProcAddr( device, "vkGetSwapchainImagesKHR" );
	vkAcquireNextImageKHR = cast( typeof( vkAcquireNextImageKHR )) vkGetDeviceProcAddr( device, "vkAcquireNextImageKHR" );
	vkQueuePresentKHR = cast( typeof( vkQueuePresentKHR )) vkGetDeviceProcAddr( device, "vkQueuePresentKHR" );

	// VK_KHR_display_swapchain
	vkCreateSharedSwapchainsKHR = cast( typeof( vkCreateSharedSwapchainsKHR )) vkGetDeviceProcAddr( device, "vkCreateSharedSwapchainsKHR" );

	// VK_KHR_maintenance1
	vkTrimCommandPoolKHR = cast( typeof( vkTrimCommandPoolKHR )) vkGetDeviceProcAddr( device, "vkTrimCommandPoolKHR" );

	// VK_KHR_external_memory_win32
	version( VK_USE_PLATFORM_WIN32_KHR ) {
		vkGetMemoryWin32HandleKHR = cast( typeof( vkGetMemoryWin32HandleKHR )) vkGetDeviceProcAddr( device, "vkGetMemoryWin32HandleKHR" );
		vkGetMemoryWin32HandlePropertiesKHR = cast( typeof( vkGetMemoryWin32HandlePropertiesKHR )) vkGetDeviceProcAddr( device, "vkGetMemoryWin32HandlePropertiesKHR" );
	}

	// VK_KHR_external_memory_fd
	vkGetMemoryFdKHR = cast( typeof( vkGetMemoryFdKHR )) vkGetDeviceProcAddr( device, "vkGetMemoryFdKHR" );
	vkGetMemoryFdPropertiesKHR = cast( typeof( vkGetMemoryFdPropertiesKHR )) vkGetDeviceProcAddr( device, "vkGetMemoryFdPropertiesKHR" );

	// VK_KHR_external_semaphore_win32
	version( VK_USE_PLATFORM_WIN32_KHR ) {
		vkImportSemaphoreWin32HandleKHR = cast( typeof( vkImportSemaphoreWin32HandleKHR )) vkGetDeviceProcAddr( device, "vkImportSemaphoreWin32HandleKHR" );
		vkGetSemaphoreWin32HandleKHR = cast( typeof( vkGetSemaphoreWin32HandleKHR )) vkGetDeviceProcAddr( device, "vkGetSemaphoreWin32HandleKHR" );
	}

	// VK_KHR_external_semaphore_fd
	vkImportSemaphoreFdKHR = cast( typeof( vkImportSemaphoreFdKHR )) vkGetDeviceProcAddr( device, "vkImportSemaphoreFdKHR" );
	vkGetSemaphoreFdKHR = cast( typeof( vkGetSemaphoreFdKHR )) vkGetDeviceProcAddr( device, "vkGetSemaphoreFdKHR" );

	// VK_KHR_push_descriptor
	vkCmdPushDescriptorSetKHR = cast( typeof( vkCmdPushDescriptorSetKHR )) vkGetDeviceProcAddr( device, "vkCmdPushDescriptorSetKHR" );

	// VK_KHR_descriptor_update_template
	vkCreateDescriptorUpdateTemplateKHR = cast( typeof( vkCreateDescriptorUpdateTemplateKHR )) vkGetDeviceProcAddr( device, "vkCreateDescriptorUpdateTemplateKHR" );
	vkDestroyDescriptorUpdateTemplateKHR = cast( typeof( vkDestroyDescriptorUpdateTemplateKHR )) vkGetDeviceProcAddr( device, "vkDestroyDescriptorUpdateTemplateKHR" );
	vkUpdateDescriptorSetWithTemplateKHR = cast( typeof( vkUpdateDescriptorSetWithTemplateKHR )) vkGetDeviceProcAddr( device, "vkUpdateDescriptorSetWithTemplateKHR" );
	vkCmdPushDescriptorSetWithTemplateKHR = cast( typeof( vkCmdPushDescriptorSetWithTemplateKHR )) vkGetDeviceProcAddr( device, "vkCmdPushDescriptorSetWithTemplateKHR" );

	// VK_KHR_shared_presentable_image
	vkGetSwapchainStatusKHR = cast( typeof( vkGetSwapchainStatusKHR )) vkGetDeviceProcAddr( device, "vkGetSwapchainStatusKHR" );

	// VK_KHR_external_fence_win32
	version( VK_USE_PLATFORM_WIN32_KHR ) {
		vkImportFenceWin32HandleKHR = cast( typeof( vkImportFenceWin32HandleKHR )) vkGetDeviceProcAddr( device, "vkImportFenceWin32HandleKHR" );
		vkGetFenceWin32HandleKHR = cast( typeof( vkGetFenceWin32HandleKHR )) vkGetDeviceProcAddr( device, "vkGetFenceWin32HandleKHR" );
	}

	// VK_KHR_external_fence_fd
	vkImportFenceFdKHR = cast( typeof( vkImportFenceFdKHR )) vkGetDeviceProcAddr( device, "vkImportFenceFdKHR" );
	vkGetFenceFdKHR = cast( typeof( vkGetFenceFdKHR )) vkGetDeviceProcAddr( device, "vkGetFenceFdKHR" );

	// VK_KHR_get_memory_requirements2
	vkGetImageMemoryRequirements2KHR = cast( typeof( vkGetImageMemoryRequirements2KHR )) vkGetDeviceProcAddr( device, "vkGetImageMemoryRequirements2KHR" );
	vkGetBufferMemoryRequirements2KHR = cast( typeof( vkGetBufferMemoryRequirements2KHR )) vkGetDeviceProcAddr( device, "vkGetBufferMemoryRequirements2KHR" );
	vkGetImageSparseMemoryRequirements2KHR = cast( typeof( vkGetImageSparseMemoryRequirements2KHR )) vkGetDeviceProcAddr( device, "vkGetImageSparseMemoryRequirements2KHR" );

	// VK_KHR_sampler_ycbcr_conversion
	vkCreateSamplerYcbcrConversionKHR = cast( typeof( vkCreateSamplerYcbcrConversionKHR )) vkGetDeviceProcAddr( device, "vkCreateSamplerYcbcrConversionKHR" );
	vkDestroySamplerYcbcrConversionKHR = cast( typeof( vkDestroySamplerYcbcrConversionKHR )) vkGetDeviceProcAddr( device, "vkDestroySamplerYcbcrConversionKHR" );

	// VK_KHR_bind_memory2
	vkBindBufferMemory2KHR = cast( typeof( vkBindBufferMemory2KHR )) vkGetDeviceProcAddr( device, "vkBindBufferMemory2KHR" );
	vkBindImageMemory2KHR = cast( typeof( vkBindImageMemory2KHR )) vkGetDeviceProcAddr( device, "vkBindImageMemory2KHR" );

	// VK_ANDROID_native_buffer
	vkGetSwapchainGrallocUsageANDROID = cast( typeof( vkGetSwapchainGrallocUsageANDROID )) vkGetDeviceProcAddr( device, "vkGetSwapchainGrallocUsageANDROID" );
	vkAcquireImageANDROID = cast( typeof( vkAcquireImageANDROID )) vkGetDeviceProcAddr( device, "vkAcquireImageANDROID" );
	vkQueueSignalReleaseImageANDROID = cast( typeof( vkQueueSignalReleaseImageANDROID )) vkGetDeviceProcAddr( device, "vkQueueSignalReleaseImageANDROID" );

	// VK_EXT_debug_marker
	vkDebugMarkerSetObjectTagEXT = cast( typeof( vkDebugMarkerSetObjectTagEXT )) vkGetDeviceProcAddr( device, "vkDebugMarkerSetObjectTagEXT" );
	vkDebugMarkerSetObjectNameEXT = cast( typeof( vkDebugMarkerSetObjectNameEXT )) vkGetDeviceProcAddr( device, "vkDebugMarkerSetObjectNameEXT" );
	vkCmdDebugMarkerBeginEXT = cast( typeof( vkCmdDebugMarkerBeginEXT )) vkGetDeviceProcAddr( device, "vkCmdDebugMarkerBeginEXT" );
	vkCmdDebugMarkerEndEXT = cast( typeof( vkCmdDebugMarkerEndEXT )) vkGetDeviceProcAddr( device, "vkCmdDebugMarkerEndEXT" );
	vkCmdDebugMarkerInsertEXT = cast( typeof( vkCmdDebugMarkerInsertEXT )) vkGetDeviceProcAddr( device, "vkCmdDebugMarkerInsertEXT" );

	// VK_AMD_draw_indirect_count
	vkCmdDrawIndirectCountAMD = cast( typeof( vkCmdDrawIndirectCountAMD )) vkGetDeviceProcAddr( device, "vkCmdDrawIndirectCountAMD" );
	vkCmdDrawIndexedIndirectCountAMD = cast( typeof( vkCmdDrawIndexedIndirectCountAMD )) vkGetDeviceProcAddr( device, "vkCmdDrawIndexedIndirectCountAMD" );

	// VK_AMD_shader_info
	vkGetShaderInfoAMD = cast( typeof( vkGetShaderInfoAMD )) vkGetDeviceProcAddr( device, "vkGetShaderInfoAMD" );

	// VK_NV_external_memory_win32
	version( VK_USE_PLATFORM_WIN32_KHR ) {
		vkGetMemoryWin32HandleNV = cast( typeof( vkGetMemoryWin32HandleNV )) vkGetDeviceProcAddr( device, "vkGetMemoryWin32HandleNV" );
	}

	// VK_KHX_device_group
	vkGetDeviceGroupPeerMemoryFeaturesKHX = cast( typeof( vkGetDeviceGroupPeerMemoryFeaturesKHX )) vkGetDeviceProcAddr( device, "vkGetDeviceGroupPeerMemoryFeaturesKHX" );
	vkCmdSetDeviceMaskKHX = cast( typeof( vkCmdSetDeviceMaskKHX )) vkGetDeviceProcAddr( device, "vkCmdSetDeviceMaskKHX" );
	vkCmdDispatchBaseKHX = cast( typeof( vkCmdDispatchBaseKHX )) vkGetDeviceProcAddr( device, "vkCmdDispatchBaseKHX" );
	vkGetDeviceGroupPresentCapabilitiesKHX = cast( typeof( vkGetDeviceGroupPresentCapabilitiesKHX )) vkGetDeviceProcAddr( device, "vkGetDeviceGroupPresentCapabilitiesKHX" );
	vkGetDeviceGroupSurfacePresentModesKHX = cast( typeof( vkGetDeviceGroupSurfacePresentModesKHX )) vkGetDeviceProcAddr( device, "vkGetDeviceGroupSurfacePresentModesKHX" );
	vkAcquireNextImage2KHX = cast( typeof( vkAcquireNextImage2KHX )) vkGetDeviceProcAddr( device, "vkAcquireNextImage2KHX" );

	// VK_NVX_device_generated_commands
	vkCmdProcessCommandsNVX = cast( typeof( vkCmdProcessCommandsNVX )) vkGetDeviceProcAddr( device, "vkCmdProcessCommandsNVX" );
	vkCmdReserveSpaceForCommandsNVX = cast( typeof( vkCmdReserveSpaceForCommandsNVX )) vkGetDeviceProcAddr( device, "vkCmdReserveSpaceForCommandsNVX" );
	vkCreateIndirectCommandsLayoutNVX = cast( typeof( vkCreateIndirectCommandsLayoutNVX )) vkGetDeviceProcAddr( device, "vkCreateIndirectCommandsLayoutNVX" );
	vkDestroyIndirectCommandsLayoutNVX = cast( typeof( vkDestroyIndirectCommandsLayoutNVX )) vkGetDeviceProcAddr( device, "vkDestroyIndirectCommandsLayoutNVX" );
	vkCreateObjectTableNVX = cast( typeof( vkCreateObjectTableNVX )) vkGetDeviceProcAddr( device, "vkCreateObjectTableNVX" );
	vkDestroyObjectTableNVX = cast( typeof( vkDestroyObjectTableNVX )) vkGetDeviceProcAddr( device, "vkDestroyObjectTableNVX" );
	vkRegisterObjectsNVX = cast( typeof( vkRegisterObjectsNVX )) vkGetDeviceProcAddr( device, "vkRegisterObjectsNVX" );
	vkUnregisterObjectsNVX = cast( typeof( vkUnregisterObjectsNVX )) vkGetDeviceProcAddr( device, "vkUnregisterObjectsNVX" );

	// VK_NV_clip_space_w_scaling
	vkCmdSetViewportWScalingNV = cast( typeof( vkCmdSetViewportWScalingNV )) vkGetDeviceProcAddr( device, "vkCmdSetViewportWScalingNV" );

	// VK_EXT_display_control
	vkDisplayPowerControlEXT = cast( typeof( vkDisplayPowerControlEXT )) vkGetDeviceProcAddr( device, "vkDisplayPowerControlEXT" );
	vkRegisterDeviceEventEXT = cast( typeof( vkRegisterDeviceEventEXT )) vkGetDeviceProcAddr( device, "vkRegisterDeviceEventEXT" );
	vkRegisterDisplayEventEXT = cast( typeof( vkRegisterDisplayEventEXT )) vkGetDeviceProcAddr( device, "vkRegisterDisplayEventEXT" );
	vkGetSwapchainCounterEXT = cast( typeof( vkGetSwapchainCounterEXT )) vkGetDeviceProcAddr( device, "vkGetSwapchainCounterEXT" );

	// VK_GOOGLE_display_timing
	vkGetRefreshCycleDurationGOOGLE = cast( typeof( vkGetRefreshCycleDurationGOOGLE )) vkGetDeviceProcAddr( device, "vkGetRefreshCycleDurationGOOGLE" );
	vkGetPastPresentationTimingGOOGLE = cast( typeof( vkGetPastPresentationTimingGOOGLE )) vkGetDeviceProcAddr( device, "vkGetPastPresentationTimingGOOGLE" );

	// VK_EXT_discard_rectangles
	vkCmdSetDiscardRectangleEXT = cast( typeof( vkCmdSetDiscardRectangleEXT )) vkGetDeviceProcAddr( device, "vkCmdSetDiscardRectangleEXT" );

	// VK_EXT_hdr_metadata
	vkSetHdrMetadataEXT = cast( typeof( vkSetHdrMetadataEXT )) vkGetDeviceProcAddr( device, "vkSetHdrMetadataEXT" );

	// VK_EXT_sample_locations
	vkCmdSetSampleLocationsEXT = cast( typeof( vkCmdSetSampleLocationsEXT )) vkGetDeviceProcAddr( device, "vkCmdSetSampleLocationsEXT" );

	// VK_EXT_validation_cache
	vkCreateValidationCacheEXT = cast( typeof( vkCreateValidationCacheEXT )) vkGetDeviceProcAddr( device, "vkCreateValidationCacheEXT" );
	vkDestroyValidationCacheEXT = cast( typeof( vkDestroyValidationCacheEXT )) vkGetDeviceProcAddr( device, "vkDestroyValidationCacheEXT" );
	vkMergeValidationCachesEXT = cast( typeof( vkMergeValidationCachesEXT )) vkGetDeviceProcAddr( device, "vkMergeValidationCachesEXT" );
	vkGetValidationCacheDataEXT = cast( typeof( vkGetValidationCacheDataEXT )) vkGetDeviceProcAddr( device, "vkGetValidationCacheDataEXT" );
}

/// with a valid VkDevice call this function to retrieve VkDevice, VkQueue and VkCommandBuffer related functions grouped in a DispatchDevice struct
/// the functions call directly VkDevice and related resources and can be retrieved for any VkDevice
deprecated( "Use DispatchDevice( VkDevice ) or DispatchDevice.loadDeviceLevelFunctions( VkDevice ) instead" )
DispatchDevice createDispatchDeviceLevelFunctions( VkDevice device ) {
	return DispatchDevice( device );
}


// struct to group per device deviceLevelFunctions into a custom namespace
// keeps track of the device to which the functions are bound
struct DispatchDevice {
	private VkDevice device = VK_NULL_HANDLE;
	VkCommandBuffer commandBuffer;

	// return copy of the internal VkDevice
	VkDevice vkDevice() {
		return device;
	}

	// Constructor forwards parameter 'device' to 'this.loadDeviceLevelFunctions'
	this( VkDevice device ) {
		this.loadDeviceLevelFunctions( device );
	}

	// load the device level member functions
	// this also sets the private member 'device' to the passed in VkDevice
	// now the DispatchDevice can be used e.g.:
	//		auto dd = DispatchDevice( device );
	//		dd.vkDestroyDevice( dd.vkDevice, pAllocator );
	// convenience functions to omit the first arg do exist, see bellow
	void loadDeviceLevelFunctions( VkDevice device ) {
		assert( vkGetDeviceProcAddr !is null, "Must call loadInstanceLevelFunctions before loadDeviceLevelFunctions" );
		this.device = device;

		// VK_VERSION_1_0
		vkDestroyDevice = cast( typeof( vkDestroyDevice )) vkGetDeviceProcAddr( device, "vkDestroyDevice" );
		vkGetDeviceQueue = cast( typeof( vkGetDeviceQueue )) vkGetDeviceProcAddr( device, "vkGetDeviceQueue" );
		vkQueueSubmit = cast( typeof( vkQueueSubmit )) vkGetDeviceProcAddr( device, "vkQueueSubmit" );
		vkQueueWaitIdle = cast( typeof( vkQueueWaitIdle )) vkGetDeviceProcAddr( device, "vkQueueWaitIdle" );
		vkDeviceWaitIdle = cast( typeof( vkDeviceWaitIdle )) vkGetDeviceProcAddr( device, "vkDeviceWaitIdle" );
		vkAllocateMemory = cast( typeof( vkAllocateMemory )) vkGetDeviceProcAddr( device, "vkAllocateMemory" );
		vkFreeMemory = cast( typeof( vkFreeMemory )) vkGetDeviceProcAddr( device, "vkFreeMemory" );
		vkMapMemory = cast( typeof( vkMapMemory )) vkGetDeviceProcAddr( device, "vkMapMemory" );
		vkUnmapMemory = cast( typeof( vkUnmapMemory )) vkGetDeviceProcAddr( device, "vkUnmapMemory" );
		vkFlushMappedMemoryRanges = cast( typeof( vkFlushMappedMemoryRanges )) vkGetDeviceProcAddr( device, "vkFlushMappedMemoryRanges" );
		vkInvalidateMappedMemoryRanges = cast( typeof( vkInvalidateMappedMemoryRanges )) vkGetDeviceProcAddr( device, "vkInvalidateMappedMemoryRanges" );
		vkGetDeviceMemoryCommitment = cast( typeof( vkGetDeviceMemoryCommitment )) vkGetDeviceProcAddr( device, "vkGetDeviceMemoryCommitment" );
		vkBindBufferMemory = cast( typeof( vkBindBufferMemory )) vkGetDeviceProcAddr( device, "vkBindBufferMemory" );
		vkBindImageMemory = cast( typeof( vkBindImageMemory )) vkGetDeviceProcAddr( device, "vkBindImageMemory" );
		vkGetBufferMemoryRequirements = cast( typeof( vkGetBufferMemoryRequirements )) vkGetDeviceProcAddr( device, "vkGetBufferMemoryRequirements" );
		vkGetImageMemoryRequirements = cast( typeof( vkGetImageMemoryRequirements )) vkGetDeviceProcAddr( device, "vkGetImageMemoryRequirements" );
		vkGetImageSparseMemoryRequirements = cast( typeof( vkGetImageSparseMemoryRequirements )) vkGetDeviceProcAddr( device, "vkGetImageSparseMemoryRequirements" );
		vkQueueBindSparse = cast( typeof( vkQueueBindSparse )) vkGetDeviceProcAddr( device, "vkQueueBindSparse" );
		vkCreateFence = cast( typeof( vkCreateFence )) vkGetDeviceProcAddr( device, "vkCreateFence" );
		vkDestroyFence = cast( typeof( vkDestroyFence )) vkGetDeviceProcAddr( device, "vkDestroyFence" );
		vkResetFences = cast( typeof( vkResetFences )) vkGetDeviceProcAddr( device, "vkResetFences" );
		vkGetFenceStatus = cast( typeof( vkGetFenceStatus )) vkGetDeviceProcAddr( device, "vkGetFenceStatus" );
		vkWaitForFences = cast( typeof( vkWaitForFences )) vkGetDeviceProcAddr( device, "vkWaitForFences" );
		vkCreateSemaphore = cast( typeof( vkCreateSemaphore )) vkGetDeviceProcAddr( device, "vkCreateSemaphore" );
		vkDestroySemaphore = cast( typeof( vkDestroySemaphore )) vkGetDeviceProcAddr( device, "vkDestroySemaphore" );
		vkCreateEvent = cast( typeof( vkCreateEvent )) vkGetDeviceProcAddr( device, "vkCreateEvent" );
		vkDestroyEvent = cast( typeof( vkDestroyEvent )) vkGetDeviceProcAddr( device, "vkDestroyEvent" );
		vkGetEventStatus = cast( typeof( vkGetEventStatus )) vkGetDeviceProcAddr( device, "vkGetEventStatus" );
		vkSetEvent = cast( typeof( vkSetEvent )) vkGetDeviceProcAddr( device, "vkSetEvent" );
		vkResetEvent = cast( typeof( vkResetEvent )) vkGetDeviceProcAddr( device, "vkResetEvent" );
		vkCreateQueryPool = cast( typeof( vkCreateQueryPool )) vkGetDeviceProcAddr( device, "vkCreateQueryPool" );
		vkDestroyQueryPool = cast( typeof( vkDestroyQueryPool )) vkGetDeviceProcAddr( device, "vkDestroyQueryPool" );
		vkGetQueryPoolResults = cast( typeof( vkGetQueryPoolResults )) vkGetDeviceProcAddr( device, "vkGetQueryPoolResults" );
		vkCreateBuffer = cast( typeof( vkCreateBuffer )) vkGetDeviceProcAddr( device, "vkCreateBuffer" );
		vkDestroyBuffer = cast( typeof( vkDestroyBuffer )) vkGetDeviceProcAddr( device, "vkDestroyBuffer" );
		vkCreateBufferView = cast( typeof( vkCreateBufferView )) vkGetDeviceProcAddr( device, "vkCreateBufferView" );
		vkDestroyBufferView = cast( typeof( vkDestroyBufferView )) vkGetDeviceProcAddr( device, "vkDestroyBufferView" );
		vkCreateImage = cast( typeof( vkCreateImage )) vkGetDeviceProcAddr( device, "vkCreateImage" );
		vkDestroyImage = cast( typeof( vkDestroyImage )) vkGetDeviceProcAddr( device, "vkDestroyImage" );
		vkGetImageSubresourceLayout = cast( typeof( vkGetImageSubresourceLayout )) vkGetDeviceProcAddr( device, "vkGetImageSubresourceLayout" );
		vkCreateImageView = cast( typeof( vkCreateImageView )) vkGetDeviceProcAddr( device, "vkCreateImageView" );
		vkDestroyImageView = cast( typeof( vkDestroyImageView )) vkGetDeviceProcAddr( device, "vkDestroyImageView" );
		vkCreateShaderModule = cast( typeof( vkCreateShaderModule )) vkGetDeviceProcAddr( device, "vkCreateShaderModule" );
		vkDestroyShaderModule = cast( typeof( vkDestroyShaderModule )) vkGetDeviceProcAddr( device, "vkDestroyShaderModule" );
		vkCreatePipelineCache = cast( typeof( vkCreatePipelineCache )) vkGetDeviceProcAddr( device, "vkCreatePipelineCache" );
		vkDestroyPipelineCache = cast( typeof( vkDestroyPipelineCache )) vkGetDeviceProcAddr( device, "vkDestroyPipelineCache" );
		vkGetPipelineCacheData = cast( typeof( vkGetPipelineCacheData )) vkGetDeviceProcAddr( device, "vkGetPipelineCacheData" );
		vkMergePipelineCaches = cast( typeof( vkMergePipelineCaches )) vkGetDeviceProcAddr( device, "vkMergePipelineCaches" );
		vkCreateGraphicsPipelines = cast( typeof( vkCreateGraphicsPipelines )) vkGetDeviceProcAddr( device, "vkCreateGraphicsPipelines" );
		vkCreateComputePipelines = cast( typeof( vkCreateComputePipelines )) vkGetDeviceProcAddr( device, "vkCreateComputePipelines" );
		vkDestroyPipeline = cast( typeof( vkDestroyPipeline )) vkGetDeviceProcAddr( device, "vkDestroyPipeline" );
		vkCreatePipelineLayout = cast( typeof( vkCreatePipelineLayout )) vkGetDeviceProcAddr( device, "vkCreatePipelineLayout" );
		vkDestroyPipelineLayout = cast( typeof( vkDestroyPipelineLayout )) vkGetDeviceProcAddr( device, "vkDestroyPipelineLayout" );
		vkCreateSampler = cast( typeof( vkCreateSampler )) vkGetDeviceProcAddr( device, "vkCreateSampler" );
		vkDestroySampler = cast( typeof( vkDestroySampler )) vkGetDeviceProcAddr( device, "vkDestroySampler" );
		vkCreateDescriptorSetLayout = cast( typeof( vkCreateDescriptorSetLayout )) vkGetDeviceProcAddr( device, "vkCreateDescriptorSetLayout" );
		vkDestroyDescriptorSetLayout = cast( typeof( vkDestroyDescriptorSetLayout )) vkGetDeviceProcAddr( device, "vkDestroyDescriptorSetLayout" );
		vkCreateDescriptorPool = cast( typeof( vkCreateDescriptorPool )) vkGetDeviceProcAddr( device, "vkCreateDescriptorPool" );
		vkDestroyDescriptorPool = cast( typeof( vkDestroyDescriptorPool )) vkGetDeviceProcAddr( device, "vkDestroyDescriptorPool" );
		vkResetDescriptorPool = cast( typeof( vkResetDescriptorPool )) vkGetDeviceProcAddr( device, "vkResetDescriptorPool" );
		vkAllocateDescriptorSets = cast( typeof( vkAllocateDescriptorSets )) vkGetDeviceProcAddr( device, "vkAllocateDescriptorSets" );
		vkFreeDescriptorSets = cast( typeof( vkFreeDescriptorSets )) vkGetDeviceProcAddr( device, "vkFreeDescriptorSets" );
		vkUpdateDescriptorSets = cast( typeof( vkUpdateDescriptorSets )) vkGetDeviceProcAddr( device, "vkUpdateDescriptorSets" );
		vkCreateFramebuffer = cast( typeof( vkCreateFramebuffer )) vkGetDeviceProcAddr( device, "vkCreateFramebuffer" );
		vkDestroyFramebuffer = cast( typeof( vkDestroyFramebuffer )) vkGetDeviceProcAddr( device, "vkDestroyFramebuffer" );
		vkCreateRenderPass = cast( typeof( vkCreateRenderPass )) vkGetDeviceProcAddr( device, "vkCreateRenderPass" );
		vkDestroyRenderPass = cast( typeof( vkDestroyRenderPass )) vkGetDeviceProcAddr( device, "vkDestroyRenderPass" );
		vkGetRenderAreaGranularity = cast( typeof( vkGetRenderAreaGranularity )) vkGetDeviceProcAddr( device, "vkGetRenderAreaGranularity" );
		vkCreateCommandPool = cast( typeof( vkCreateCommandPool )) vkGetDeviceProcAddr( device, "vkCreateCommandPool" );
		vkDestroyCommandPool = cast( typeof( vkDestroyCommandPool )) vkGetDeviceProcAddr( device, "vkDestroyCommandPool" );
		vkResetCommandPool = cast( typeof( vkResetCommandPool )) vkGetDeviceProcAddr( device, "vkResetCommandPool" );
		vkAllocateCommandBuffers = cast( typeof( vkAllocateCommandBuffers )) vkGetDeviceProcAddr( device, "vkAllocateCommandBuffers" );
		vkFreeCommandBuffers = cast( typeof( vkFreeCommandBuffers )) vkGetDeviceProcAddr( device, "vkFreeCommandBuffers" );
		vkBeginCommandBuffer = cast( typeof( vkBeginCommandBuffer )) vkGetDeviceProcAddr( device, "vkBeginCommandBuffer" );
		vkEndCommandBuffer = cast( typeof( vkEndCommandBuffer )) vkGetDeviceProcAddr( device, "vkEndCommandBuffer" );
		vkResetCommandBuffer = cast( typeof( vkResetCommandBuffer )) vkGetDeviceProcAddr( device, "vkResetCommandBuffer" );
		vkCmdBindPipeline = cast( typeof( vkCmdBindPipeline )) vkGetDeviceProcAddr( device, "vkCmdBindPipeline" );
		vkCmdSetViewport = cast( typeof( vkCmdSetViewport )) vkGetDeviceProcAddr( device, "vkCmdSetViewport" );
		vkCmdSetScissor = cast( typeof( vkCmdSetScissor )) vkGetDeviceProcAddr( device, "vkCmdSetScissor" );
		vkCmdSetLineWidth = cast( typeof( vkCmdSetLineWidth )) vkGetDeviceProcAddr( device, "vkCmdSetLineWidth" );
		vkCmdSetDepthBias = cast( typeof( vkCmdSetDepthBias )) vkGetDeviceProcAddr( device, "vkCmdSetDepthBias" );
		vkCmdSetBlendConstants = cast( typeof( vkCmdSetBlendConstants )) vkGetDeviceProcAddr( device, "vkCmdSetBlendConstants" );
		vkCmdSetDepthBounds = cast( typeof( vkCmdSetDepthBounds )) vkGetDeviceProcAddr( device, "vkCmdSetDepthBounds" );
		vkCmdSetStencilCompareMask = cast( typeof( vkCmdSetStencilCompareMask )) vkGetDeviceProcAddr( device, "vkCmdSetStencilCompareMask" );
		vkCmdSetStencilWriteMask = cast( typeof( vkCmdSetStencilWriteMask )) vkGetDeviceProcAddr( device, "vkCmdSetStencilWriteMask" );
		vkCmdSetStencilReference = cast( typeof( vkCmdSetStencilReference )) vkGetDeviceProcAddr( device, "vkCmdSetStencilReference" );
		vkCmdBindDescriptorSets = cast( typeof( vkCmdBindDescriptorSets )) vkGetDeviceProcAddr( device, "vkCmdBindDescriptorSets" );
		vkCmdBindIndexBuffer = cast( typeof( vkCmdBindIndexBuffer )) vkGetDeviceProcAddr( device, "vkCmdBindIndexBuffer" );
		vkCmdBindVertexBuffers = cast( typeof( vkCmdBindVertexBuffers )) vkGetDeviceProcAddr( device, "vkCmdBindVertexBuffers" );
		vkCmdDraw = cast( typeof( vkCmdDraw )) vkGetDeviceProcAddr( device, "vkCmdDraw" );
		vkCmdDrawIndexed = cast( typeof( vkCmdDrawIndexed )) vkGetDeviceProcAddr( device, "vkCmdDrawIndexed" );
		vkCmdDrawIndirect = cast( typeof( vkCmdDrawIndirect )) vkGetDeviceProcAddr( device, "vkCmdDrawIndirect" );
		vkCmdDrawIndexedIndirect = cast( typeof( vkCmdDrawIndexedIndirect )) vkGetDeviceProcAddr( device, "vkCmdDrawIndexedIndirect" );
		vkCmdDispatch = cast( typeof( vkCmdDispatch )) vkGetDeviceProcAddr( device, "vkCmdDispatch" );
		vkCmdDispatchIndirect = cast( typeof( vkCmdDispatchIndirect )) vkGetDeviceProcAddr( device, "vkCmdDispatchIndirect" );
		vkCmdCopyBuffer = cast( typeof( vkCmdCopyBuffer )) vkGetDeviceProcAddr( device, "vkCmdCopyBuffer" );
		vkCmdCopyImage = cast( typeof( vkCmdCopyImage )) vkGetDeviceProcAddr( device, "vkCmdCopyImage" );
		vkCmdBlitImage = cast( typeof( vkCmdBlitImage )) vkGetDeviceProcAddr( device, "vkCmdBlitImage" );
		vkCmdCopyBufferToImage = cast( typeof( vkCmdCopyBufferToImage )) vkGetDeviceProcAddr( device, "vkCmdCopyBufferToImage" );
		vkCmdCopyImageToBuffer = cast( typeof( vkCmdCopyImageToBuffer )) vkGetDeviceProcAddr( device, "vkCmdCopyImageToBuffer" );
		vkCmdUpdateBuffer = cast( typeof( vkCmdUpdateBuffer )) vkGetDeviceProcAddr( device, "vkCmdUpdateBuffer" );
		vkCmdFillBuffer = cast( typeof( vkCmdFillBuffer )) vkGetDeviceProcAddr( device, "vkCmdFillBuffer" );
		vkCmdClearColorImage = cast( typeof( vkCmdClearColorImage )) vkGetDeviceProcAddr( device, "vkCmdClearColorImage" );
		vkCmdClearDepthStencilImage = cast( typeof( vkCmdClearDepthStencilImage )) vkGetDeviceProcAddr( device, "vkCmdClearDepthStencilImage" );
		vkCmdClearAttachments = cast( typeof( vkCmdClearAttachments )) vkGetDeviceProcAddr( device, "vkCmdClearAttachments" );
		vkCmdResolveImage = cast( typeof( vkCmdResolveImage )) vkGetDeviceProcAddr( device, "vkCmdResolveImage" );
		vkCmdSetEvent = cast( typeof( vkCmdSetEvent )) vkGetDeviceProcAddr( device, "vkCmdSetEvent" );
		vkCmdResetEvent = cast( typeof( vkCmdResetEvent )) vkGetDeviceProcAddr( device, "vkCmdResetEvent" );
		vkCmdWaitEvents = cast( typeof( vkCmdWaitEvents )) vkGetDeviceProcAddr( device, "vkCmdWaitEvents" );
		vkCmdPipelineBarrier = cast( typeof( vkCmdPipelineBarrier )) vkGetDeviceProcAddr( device, "vkCmdPipelineBarrier" );
		vkCmdBeginQuery = cast( typeof( vkCmdBeginQuery )) vkGetDeviceProcAddr( device, "vkCmdBeginQuery" );
		vkCmdEndQuery = cast( typeof( vkCmdEndQuery )) vkGetDeviceProcAddr( device, "vkCmdEndQuery" );
		vkCmdResetQueryPool = cast( typeof( vkCmdResetQueryPool )) vkGetDeviceProcAddr( device, "vkCmdResetQueryPool" );
		vkCmdWriteTimestamp = cast( typeof( vkCmdWriteTimestamp )) vkGetDeviceProcAddr( device, "vkCmdWriteTimestamp" );
		vkCmdCopyQueryPoolResults = cast( typeof( vkCmdCopyQueryPoolResults )) vkGetDeviceProcAddr( device, "vkCmdCopyQueryPoolResults" );
		vkCmdPushConstants = cast( typeof( vkCmdPushConstants )) vkGetDeviceProcAddr( device, "vkCmdPushConstants" );
		vkCmdBeginRenderPass = cast( typeof( vkCmdBeginRenderPass )) vkGetDeviceProcAddr( device, "vkCmdBeginRenderPass" );
		vkCmdNextSubpass = cast( typeof( vkCmdNextSubpass )) vkGetDeviceProcAddr( device, "vkCmdNextSubpass" );
		vkCmdEndRenderPass = cast( typeof( vkCmdEndRenderPass )) vkGetDeviceProcAddr( device, "vkCmdEndRenderPass" );
		vkCmdExecuteCommands = cast( typeof( vkCmdExecuteCommands )) vkGetDeviceProcAddr( device, "vkCmdExecuteCommands" );

		// VK_KHR_swapchain
		vkCreateSwapchainKHR = cast( typeof( vkCreateSwapchainKHR )) vkGetDeviceProcAddr( device, "vkCreateSwapchainKHR" );
		vkDestroySwapchainKHR = cast( typeof( vkDestroySwapchainKHR )) vkGetDeviceProcAddr( device, "vkDestroySwapchainKHR" );
		vkGetSwapchainImagesKHR = cast( typeof( vkGetSwapchainImagesKHR )) vkGetDeviceProcAddr( device, "vkGetSwapchainImagesKHR" );
		vkAcquireNextImageKHR = cast( typeof( vkAcquireNextImageKHR )) vkGetDeviceProcAddr( device, "vkAcquireNextImageKHR" );
		vkQueuePresentKHR = cast( typeof( vkQueuePresentKHR )) vkGetDeviceProcAddr( device, "vkQueuePresentKHR" );

		// VK_KHR_display_swapchain
		vkCreateSharedSwapchainsKHR = cast( typeof( vkCreateSharedSwapchainsKHR )) vkGetDeviceProcAddr( device, "vkCreateSharedSwapchainsKHR" );

		// VK_KHR_maintenance1
		vkTrimCommandPoolKHR = cast( typeof( vkTrimCommandPoolKHR )) vkGetDeviceProcAddr( device, "vkTrimCommandPoolKHR" );

		// VK_KHR_external_memory_win32
		version( VK_USE_PLATFORM_WIN32_KHR ) {
			vkGetMemoryWin32HandleKHR = cast( typeof( vkGetMemoryWin32HandleKHR )) vkGetDeviceProcAddr( device, "vkGetMemoryWin32HandleKHR" );
			vkGetMemoryWin32HandlePropertiesKHR = cast( typeof( vkGetMemoryWin32HandlePropertiesKHR )) vkGetDeviceProcAddr( device, "vkGetMemoryWin32HandlePropertiesKHR" );
		}

		// VK_KHR_external_memory_fd
		vkGetMemoryFdKHR = cast( typeof( vkGetMemoryFdKHR )) vkGetDeviceProcAddr( device, "vkGetMemoryFdKHR" );
		vkGetMemoryFdPropertiesKHR = cast( typeof( vkGetMemoryFdPropertiesKHR )) vkGetDeviceProcAddr( device, "vkGetMemoryFdPropertiesKHR" );

		// VK_KHR_external_semaphore_win32
		version( VK_USE_PLATFORM_WIN32_KHR ) {
			vkImportSemaphoreWin32HandleKHR = cast( typeof( vkImportSemaphoreWin32HandleKHR )) vkGetDeviceProcAddr( device, "vkImportSemaphoreWin32HandleKHR" );
			vkGetSemaphoreWin32HandleKHR = cast( typeof( vkGetSemaphoreWin32HandleKHR )) vkGetDeviceProcAddr( device, "vkGetSemaphoreWin32HandleKHR" );
		}

		// VK_KHR_external_semaphore_fd
		vkImportSemaphoreFdKHR = cast( typeof( vkImportSemaphoreFdKHR )) vkGetDeviceProcAddr( device, "vkImportSemaphoreFdKHR" );
		vkGetSemaphoreFdKHR = cast( typeof( vkGetSemaphoreFdKHR )) vkGetDeviceProcAddr( device, "vkGetSemaphoreFdKHR" );

		// VK_KHR_push_descriptor
		vkCmdPushDescriptorSetKHR = cast( typeof( vkCmdPushDescriptorSetKHR )) vkGetDeviceProcAddr( device, "vkCmdPushDescriptorSetKHR" );

		// VK_KHR_descriptor_update_template
		vkCreateDescriptorUpdateTemplateKHR = cast( typeof( vkCreateDescriptorUpdateTemplateKHR )) vkGetDeviceProcAddr( device, "vkCreateDescriptorUpdateTemplateKHR" );
		vkDestroyDescriptorUpdateTemplateKHR = cast( typeof( vkDestroyDescriptorUpdateTemplateKHR )) vkGetDeviceProcAddr( device, "vkDestroyDescriptorUpdateTemplateKHR" );
		vkUpdateDescriptorSetWithTemplateKHR = cast( typeof( vkUpdateDescriptorSetWithTemplateKHR )) vkGetDeviceProcAddr( device, "vkUpdateDescriptorSetWithTemplateKHR" );
		vkCmdPushDescriptorSetWithTemplateKHR = cast( typeof( vkCmdPushDescriptorSetWithTemplateKHR )) vkGetDeviceProcAddr( device, "vkCmdPushDescriptorSetWithTemplateKHR" );

		// VK_KHR_shared_presentable_image
		vkGetSwapchainStatusKHR = cast( typeof( vkGetSwapchainStatusKHR )) vkGetDeviceProcAddr( device, "vkGetSwapchainStatusKHR" );

		// VK_KHR_external_fence_win32
		version( VK_USE_PLATFORM_WIN32_KHR ) {
			vkImportFenceWin32HandleKHR = cast( typeof( vkImportFenceWin32HandleKHR )) vkGetDeviceProcAddr( device, "vkImportFenceWin32HandleKHR" );
			vkGetFenceWin32HandleKHR = cast( typeof( vkGetFenceWin32HandleKHR )) vkGetDeviceProcAddr( device, "vkGetFenceWin32HandleKHR" );
		}

		// VK_KHR_external_fence_fd
		vkImportFenceFdKHR = cast( typeof( vkImportFenceFdKHR )) vkGetDeviceProcAddr( device, "vkImportFenceFdKHR" );
		vkGetFenceFdKHR = cast( typeof( vkGetFenceFdKHR )) vkGetDeviceProcAddr( device, "vkGetFenceFdKHR" );

		// VK_KHR_get_memory_requirements2
		vkGetImageMemoryRequirements2KHR = cast( typeof( vkGetImageMemoryRequirements2KHR )) vkGetDeviceProcAddr( device, "vkGetImageMemoryRequirements2KHR" );
		vkGetBufferMemoryRequirements2KHR = cast( typeof( vkGetBufferMemoryRequirements2KHR )) vkGetDeviceProcAddr( device, "vkGetBufferMemoryRequirements2KHR" );
		vkGetImageSparseMemoryRequirements2KHR = cast( typeof( vkGetImageSparseMemoryRequirements2KHR )) vkGetDeviceProcAddr( device, "vkGetImageSparseMemoryRequirements2KHR" );

		// VK_KHR_sampler_ycbcr_conversion
		vkCreateSamplerYcbcrConversionKHR = cast( typeof( vkCreateSamplerYcbcrConversionKHR )) vkGetDeviceProcAddr( device, "vkCreateSamplerYcbcrConversionKHR" );
		vkDestroySamplerYcbcrConversionKHR = cast( typeof( vkDestroySamplerYcbcrConversionKHR )) vkGetDeviceProcAddr( device, "vkDestroySamplerYcbcrConversionKHR" );

		// VK_KHR_bind_memory2
		vkBindBufferMemory2KHR = cast( typeof( vkBindBufferMemory2KHR )) vkGetDeviceProcAddr( device, "vkBindBufferMemory2KHR" );
		vkBindImageMemory2KHR = cast( typeof( vkBindImageMemory2KHR )) vkGetDeviceProcAddr( device, "vkBindImageMemory2KHR" );

		// VK_ANDROID_native_buffer
		vkGetSwapchainGrallocUsageANDROID = cast( typeof( vkGetSwapchainGrallocUsageANDROID )) vkGetDeviceProcAddr( device, "vkGetSwapchainGrallocUsageANDROID" );
		vkAcquireImageANDROID = cast( typeof( vkAcquireImageANDROID )) vkGetDeviceProcAddr( device, "vkAcquireImageANDROID" );
		vkQueueSignalReleaseImageANDROID = cast( typeof( vkQueueSignalReleaseImageANDROID )) vkGetDeviceProcAddr( device, "vkQueueSignalReleaseImageANDROID" );

		// VK_EXT_debug_marker
		vkDebugMarkerSetObjectTagEXT = cast( typeof( vkDebugMarkerSetObjectTagEXT )) vkGetDeviceProcAddr( device, "vkDebugMarkerSetObjectTagEXT" );
		vkDebugMarkerSetObjectNameEXT = cast( typeof( vkDebugMarkerSetObjectNameEXT )) vkGetDeviceProcAddr( device, "vkDebugMarkerSetObjectNameEXT" );
		vkCmdDebugMarkerBeginEXT = cast( typeof( vkCmdDebugMarkerBeginEXT )) vkGetDeviceProcAddr( device, "vkCmdDebugMarkerBeginEXT" );
		vkCmdDebugMarkerEndEXT = cast( typeof( vkCmdDebugMarkerEndEXT )) vkGetDeviceProcAddr( device, "vkCmdDebugMarkerEndEXT" );
		vkCmdDebugMarkerInsertEXT = cast( typeof( vkCmdDebugMarkerInsertEXT )) vkGetDeviceProcAddr( device, "vkCmdDebugMarkerInsertEXT" );

		// VK_AMD_draw_indirect_count
		vkCmdDrawIndirectCountAMD = cast( typeof( vkCmdDrawIndirectCountAMD )) vkGetDeviceProcAddr( device, "vkCmdDrawIndirectCountAMD" );
		vkCmdDrawIndexedIndirectCountAMD = cast( typeof( vkCmdDrawIndexedIndirectCountAMD )) vkGetDeviceProcAddr( device, "vkCmdDrawIndexedIndirectCountAMD" );

		// VK_AMD_shader_info
		vkGetShaderInfoAMD = cast( typeof( vkGetShaderInfoAMD )) vkGetDeviceProcAddr( device, "vkGetShaderInfoAMD" );

		// VK_NV_external_memory_win32
		version( VK_USE_PLATFORM_WIN32_KHR ) {
			vkGetMemoryWin32HandleNV = cast( typeof( vkGetMemoryWin32HandleNV )) vkGetDeviceProcAddr( device, "vkGetMemoryWin32HandleNV" );
		}

		// VK_KHX_device_group
		vkGetDeviceGroupPeerMemoryFeaturesKHX = cast( typeof( vkGetDeviceGroupPeerMemoryFeaturesKHX )) vkGetDeviceProcAddr( device, "vkGetDeviceGroupPeerMemoryFeaturesKHX" );
		vkCmdSetDeviceMaskKHX = cast( typeof( vkCmdSetDeviceMaskKHX )) vkGetDeviceProcAddr( device, "vkCmdSetDeviceMaskKHX" );
		vkCmdDispatchBaseKHX = cast( typeof( vkCmdDispatchBaseKHX )) vkGetDeviceProcAddr( device, "vkCmdDispatchBaseKHX" );
		vkGetDeviceGroupPresentCapabilitiesKHX = cast( typeof( vkGetDeviceGroupPresentCapabilitiesKHX )) vkGetDeviceProcAddr( device, "vkGetDeviceGroupPresentCapabilitiesKHX" );
		vkGetDeviceGroupSurfacePresentModesKHX = cast( typeof( vkGetDeviceGroupSurfacePresentModesKHX )) vkGetDeviceProcAddr( device, "vkGetDeviceGroupSurfacePresentModesKHX" );
		vkAcquireNextImage2KHX = cast( typeof( vkAcquireNextImage2KHX )) vkGetDeviceProcAddr( device, "vkAcquireNextImage2KHX" );

		// VK_NVX_device_generated_commands
		vkCmdProcessCommandsNVX = cast( typeof( vkCmdProcessCommandsNVX )) vkGetDeviceProcAddr( device, "vkCmdProcessCommandsNVX" );
		vkCmdReserveSpaceForCommandsNVX = cast( typeof( vkCmdReserveSpaceForCommandsNVX )) vkGetDeviceProcAddr( device, "vkCmdReserveSpaceForCommandsNVX" );
		vkCreateIndirectCommandsLayoutNVX = cast( typeof( vkCreateIndirectCommandsLayoutNVX )) vkGetDeviceProcAddr( device, "vkCreateIndirectCommandsLayoutNVX" );
		vkDestroyIndirectCommandsLayoutNVX = cast( typeof( vkDestroyIndirectCommandsLayoutNVX )) vkGetDeviceProcAddr( device, "vkDestroyIndirectCommandsLayoutNVX" );
		vkCreateObjectTableNVX = cast( typeof( vkCreateObjectTableNVX )) vkGetDeviceProcAddr( device, "vkCreateObjectTableNVX" );
		vkDestroyObjectTableNVX = cast( typeof( vkDestroyObjectTableNVX )) vkGetDeviceProcAddr( device, "vkDestroyObjectTableNVX" );
		vkRegisterObjectsNVX = cast( typeof( vkRegisterObjectsNVX )) vkGetDeviceProcAddr( device, "vkRegisterObjectsNVX" );
		vkUnregisterObjectsNVX = cast( typeof( vkUnregisterObjectsNVX )) vkGetDeviceProcAddr( device, "vkUnregisterObjectsNVX" );

		// VK_NV_clip_space_w_scaling
		vkCmdSetViewportWScalingNV = cast( typeof( vkCmdSetViewportWScalingNV )) vkGetDeviceProcAddr( device, "vkCmdSetViewportWScalingNV" );

		// VK_EXT_display_control
		vkDisplayPowerControlEXT = cast( typeof( vkDisplayPowerControlEXT )) vkGetDeviceProcAddr( device, "vkDisplayPowerControlEXT" );
		vkRegisterDeviceEventEXT = cast( typeof( vkRegisterDeviceEventEXT )) vkGetDeviceProcAddr( device, "vkRegisterDeviceEventEXT" );
		vkRegisterDisplayEventEXT = cast( typeof( vkRegisterDisplayEventEXT )) vkGetDeviceProcAddr( device, "vkRegisterDisplayEventEXT" );
		vkGetSwapchainCounterEXT = cast( typeof( vkGetSwapchainCounterEXT )) vkGetDeviceProcAddr( device, "vkGetSwapchainCounterEXT" );

		// VK_GOOGLE_display_timing
		vkGetRefreshCycleDurationGOOGLE = cast( typeof( vkGetRefreshCycleDurationGOOGLE )) vkGetDeviceProcAddr( device, "vkGetRefreshCycleDurationGOOGLE" );
		vkGetPastPresentationTimingGOOGLE = cast( typeof( vkGetPastPresentationTimingGOOGLE )) vkGetDeviceProcAddr( device, "vkGetPastPresentationTimingGOOGLE" );

		// VK_EXT_discard_rectangles
		vkCmdSetDiscardRectangleEXT = cast( typeof( vkCmdSetDiscardRectangleEXT )) vkGetDeviceProcAddr( device, "vkCmdSetDiscardRectangleEXT" );

		// VK_EXT_hdr_metadata
		vkSetHdrMetadataEXT = cast( typeof( vkSetHdrMetadataEXT )) vkGetDeviceProcAddr( device, "vkSetHdrMetadataEXT" );

		// VK_EXT_sample_locations
		vkCmdSetSampleLocationsEXT = cast( typeof( vkCmdSetSampleLocationsEXT )) vkGetDeviceProcAddr( device, "vkCmdSetSampleLocationsEXT" );

		// VK_EXT_validation_cache
		vkCreateValidationCacheEXT = cast( typeof( vkCreateValidationCacheEXT )) vkGetDeviceProcAddr( device, "vkCreateValidationCacheEXT" );
		vkDestroyValidationCacheEXT = cast( typeof( vkDestroyValidationCacheEXT )) vkGetDeviceProcAddr( device, "vkDestroyValidationCacheEXT" );
		vkMergeValidationCachesEXT = cast( typeof( vkMergeValidationCachesEXT )) vkGetDeviceProcAddr( device, "vkMergeValidationCachesEXT" );
		vkGetValidationCacheDataEXT = cast( typeof( vkGetValidationCacheDataEXT )) vkGetDeviceProcAddr( device, "vkGetValidationCacheDataEXT" );
	}

	// Convenience member functions, forwarded to corresponding vulkan functions
	// If the first arg of the vulkan function is VkDevice it can be omitted
	// private 'DipatchDevice' member 'device' will be passed to the forwarded vulkan functions
	// the crux is that function pointers can't be overloaded with regular functions
	// hence the vk prefix is ditched for the convenience variants
	// e.g.:
	//		auto dd = DispatchDevice( device );
	//		dd.DestroyDevice( pAllocator );		// instead of: dd.vkDestroyDevice( dd.vkDevice, pAllocator );
	//
	// Same mechanism works with functions which require a VkCommandBuffer as first arg
	// In this case the public member 'commandBuffer' must be set beforehand
	// e.g.:
	//		dd.commandBuffer = some_command_buffer;
	//		dd.BeginCommandBuffer( &beginInfo );
	//		dd.CmdBindPipeline( VK_PIPELINE_BIND_POINT_GRAPHICS, some_pipeline );
	//
	// Does not work with queues, there are just too few queue related functions

	// VK_VERSION_1_0
	void DestroyDevice( const( VkAllocationCallbacks )* pAllocator ) {
		vkDestroyDevice( this.device, pAllocator );
	}
	void GetDeviceQueue( uint32_t queueFamilyIndex, uint32_t queueIndex, VkQueue* pQueue ) {
		vkGetDeviceQueue( this.device, queueFamilyIndex, queueIndex, pQueue );
	}
	VkResult DeviceWaitIdle() {
		return vkDeviceWaitIdle( this.device );
	}
	VkResult AllocateMemory( const( VkMemoryAllocateInfo )* pAllocateInfo, const( VkAllocationCallbacks )* pAllocator, VkDeviceMemory* pMemory ) {
		return vkAllocateMemory( this.device, pAllocateInfo, pAllocator, pMemory );
	}
	void FreeMemory( VkDeviceMemory memory, const( VkAllocationCallbacks )* pAllocator ) {
		vkFreeMemory( this.device, memory, pAllocator );
	}
	VkResult MapMemory( VkDeviceMemory memory, VkDeviceSize offset, VkDeviceSize size, VkMemoryMapFlags flags, void** ppData ) {
		return vkMapMemory( this.device, memory, offset, size, flags, ppData );
	}
	void UnmapMemory( VkDeviceMemory memory ) {
		vkUnmapMemory( this.device, memory );
	}
	VkResult FlushMappedMemoryRanges( uint32_t memoryRangeCount, const( VkMappedMemoryRange )* pMemoryRanges ) {
		return vkFlushMappedMemoryRanges( this.device, memoryRangeCount, pMemoryRanges );
	}
	VkResult InvalidateMappedMemoryRanges( uint32_t memoryRangeCount, const( VkMappedMemoryRange )* pMemoryRanges ) {
		return vkInvalidateMappedMemoryRanges( this.device, memoryRangeCount, pMemoryRanges );
	}
	void GetDeviceMemoryCommitment( VkDeviceMemory memory, VkDeviceSize* pCommittedMemoryInBytes ) {
		vkGetDeviceMemoryCommitment( this.device, memory, pCommittedMemoryInBytes );
	}
	VkResult BindBufferMemory( VkBuffer buffer, VkDeviceMemory memory, VkDeviceSize memoryOffset ) {
		return vkBindBufferMemory( this.device, buffer, memory, memoryOffset );
	}
	VkResult BindImageMemory( VkImage image, VkDeviceMemory memory, VkDeviceSize memoryOffset ) {
		return vkBindImageMemory( this.device, image, memory, memoryOffset );
	}
	void GetBufferMemoryRequirements( VkBuffer buffer, VkMemoryRequirements* pMemoryRequirements ) {
		vkGetBufferMemoryRequirements( this.device, buffer, pMemoryRequirements );
	}
	void GetImageMemoryRequirements( VkImage image, VkMemoryRequirements* pMemoryRequirements ) {
		vkGetImageMemoryRequirements( this.device, image, pMemoryRequirements );
	}
	void GetImageSparseMemoryRequirements( VkImage image, uint32_t* pSparseMemoryRequirementCount, VkSparseImageMemoryRequirements* pSparseMemoryRequirements ) {
		vkGetImageSparseMemoryRequirements( this.device, image, pSparseMemoryRequirementCount, pSparseMemoryRequirements );
	}
	VkResult CreateFence( const( VkFenceCreateInfo )* pCreateInfo, const( VkAllocationCallbacks )* pAllocator, VkFence* pFence ) {
		return vkCreateFence( this.device, pCreateInfo, pAllocator, pFence );
	}
	void DestroyFence( VkFence fence, const( VkAllocationCallbacks )* pAllocator ) {
		vkDestroyFence( this.device, fence, pAllocator );
	}
	VkResult ResetFences( uint32_t fenceCount, const( VkFence )* pFences ) {
		return vkResetFences( this.device, fenceCount, pFences );
	}
	VkResult GetFenceStatus( VkFence fence ) {
		return vkGetFenceStatus( this.device, fence );
	}
	VkResult WaitForFences( uint32_t fenceCount, const( VkFence )* pFences, VkBool32 waitAll, uint64_t timeout ) {
		return vkWaitForFences( this.device, fenceCount, pFences, waitAll, timeout );
	}
	VkResult CreateSemaphore( const( VkSemaphoreCreateInfo )* pCreateInfo, const( VkAllocationCallbacks )* pAllocator, VkSemaphore* pSemaphore ) {
		return vkCreateSemaphore( this.device, pCreateInfo, pAllocator, pSemaphore );
	}
	void DestroySemaphore( VkSemaphore semaphore, const( VkAllocationCallbacks )* pAllocator ) {
		vkDestroySemaphore( this.device, semaphore, pAllocator );
	}
	VkResult CreateEvent( const( VkEventCreateInfo )* pCreateInfo, const( VkAllocationCallbacks )* pAllocator, VkEvent* pEvent ) {
		return vkCreateEvent( this.device, pCreateInfo, pAllocator, pEvent );
	}
	void DestroyEvent( VkEvent event, const( VkAllocationCallbacks )* pAllocator ) {
		vkDestroyEvent( this.device, event, pAllocator );
	}
	VkResult GetEventStatus( VkEvent event ) {
		return vkGetEventStatus( this.device, event );
	}
	VkResult SetEvent( VkEvent event ) {
		return vkSetEvent( this.device, event );
	}
	VkResult ResetEvent( VkEvent event ) {
		return vkResetEvent( this.device, event );
	}
	VkResult CreateQueryPool( const( VkQueryPoolCreateInfo )* pCreateInfo, const( VkAllocationCallbacks )* pAllocator, VkQueryPool* pQueryPool ) {
		return vkCreateQueryPool( this.device, pCreateInfo, pAllocator, pQueryPool );
	}
	void DestroyQueryPool( VkQueryPool queryPool, const( VkAllocationCallbacks )* pAllocator ) {
		vkDestroyQueryPool( this.device, queryPool, pAllocator );
	}
	VkResult GetQueryPoolResults( VkQueryPool queryPool, uint32_t firstQuery, uint32_t queryCount, size_t dataSize, void* pData, VkDeviceSize stride, VkQueryResultFlags flags ) {
		return vkGetQueryPoolResults( this.device, queryPool, firstQuery, queryCount, dataSize, pData, stride, flags );
	}
	VkResult CreateBuffer( const( VkBufferCreateInfo )* pCreateInfo, const( VkAllocationCallbacks )* pAllocator, VkBuffer* pBuffer ) {
		return vkCreateBuffer( this.device, pCreateInfo, pAllocator, pBuffer );
	}
	void DestroyBuffer( VkBuffer buffer, const( VkAllocationCallbacks )* pAllocator ) {
		vkDestroyBuffer( this.device, buffer, pAllocator );
	}
	VkResult CreateBufferView( const( VkBufferViewCreateInfo )* pCreateInfo, const( VkAllocationCallbacks )* pAllocator, VkBufferView* pView ) {
		return vkCreateBufferView( this.device, pCreateInfo, pAllocator, pView );
	}
	void DestroyBufferView( VkBufferView bufferView, const( VkAllocationCallbacks )* pAllocator ) {
		vkDestroyBufferView( this.device, bufferView, pAllocator );
	}
	VkResult CreateImage( const( VkImageCreateInfo )* pCreateInfo, const( VkAllocationCallbacks )* pAllocator, VkImage* pImage ) {
		return vkCreateImage( this.device, pCreateInfo, pAllocator, pImage );
	}
	void DestroyImage( VkImage image, const( VkAllocationCallbacks )* pAllocator ) {
		vkDestroyImage( this.device, image, pAllocator );
	}
	void GetImageSubresourceLayout( VkImage image, const( VkImageSubresource )* pSubresource, VkSubresourceLayout* pLayout ) {
		vkGetImageSubresourceLayout( this.device, image, pSubresource, pLayout );
	}
	VkResult CreateImageView( const( VkImageViewCreateInfo )* pCreateInfo, const( VkAllocationCallbacks )* pAllocator, VkImageView* pView ) {
		return vkCreateImageView( this.device, pCreateInfo, pAllocator, pView );
	}
	void DestroyImageView( VkImageView imageView, const( VkAllocationCallbacks )* pAllocator ) {
		vkDestroyImageView( this.device, imageView, pAllocator );
	}
	VkResult CreateShaderModule( const( VkShaderModuleCreateInfo )* pCreateInfo, const( VkAllocationCallbacks )* pAllocator, VkShaderModule* pShaderModule ) {
		return vkCreateShaderModule( this.device, pCreateInfo, pAllocator, pShaderModule );
	}
	void DestroyShaderModule( VkShaderModule shaderModule, const( VkAllocationCallbacks )* pAllocator ) {
		vkDestroyShaderModule( this.device, shaderModule, pAllocator );
	}
	VkResult CreatePipelineCache( const( VkPipelineCacheCreateInfo )* pCreateInfo, const( VkAllocationCallbacks )* pAllocator, VkPipelineCache* pPipelineCache ) {
		return vkCreatePipelineCache( this.device, pCreateInfo, pAllocator, pPipelineCache );
	}
	void DestroyPipelineCache( VkPipelineCache pipelineCache, const( VkAllocationCallbacks )* pAllocator ) {
		vkDestroyPipelineCache( this.device, pipelineCache, pAllocator );
	}
	VkResult GetPipelineCacheData( VkPipelineCache pipelineCache, size_t* pDataSize, void* pData ) {
		return vkGetPipelineCacheData( this.device, pipelineCache, pDataSize, pData );
	}
	VkResult MergePipelineCaches( VkPipelineCache dstCache, uint32_t srcCacheCount, const( VkPipelineCache )* pSrcCaches ) {
		return vkMergePipelineCaches( this.device, dstCache, srcCacheCount, pSrcCaches );
	}
	VkResult CreateGraphicsPipelines( VkPipelineCache pipelineCache, uint32_t createInfoCount, const( VkGraphicsPipelineCreateInfo )* pCreateInfos, const( VkAllocationCallbacks )* pAllocator, VkPipeline* pPipelines ) {
		return vkCreateGraphicsPipelines( this.device, pipelineCache, createInfoCount, pCreateInfos, pAllocator, pPipelines );
	}
	VkResult CreateComputePipelines( VkPipelineCache pipelineCache, uint32_t createInfoCount, const( VkComputePipelineCreateInfo )* pCreateInfos, const( VkAllocationCallbacks )* pAllocator, VkPipeline* pPipelines ) {
		return vkCreateComputePipelines( this.device, pipelineCache, createInfoCount, pCreateInfos, pAllocator, pPipelines );
	}
	void DestroyPipeline( VkPipeline pipeline, const( VkAllocationCallbacks )* pAllocator ) {
		vkDestroyPipeline( this.device, pipeline, pAllocator );
	}
	VkResult CreatePipelineLayout( const( VkPipelineLayoutCreateInfo )* pCreateInfo, const( VkAllocationCallbacks )* pAllocator, VkPipelineLayout* pPipelineLayout ) {
		return vkCreatePipelineLayout( this.device, pCreateInfo, pAllocator, pPipelineLayout );
	}
	void DestroyPipelineLayout( VkPipelineLayout pipelineLayout, const( VkAllocationCallbacks )* pAllocator ) {
		vkDestroyPipelineLayout( this.device, pipelineLayout, pAllocator );
	}
	VkResult CreateSampler( const( VkSamplerCreateInfo )* pCreateInfo, const( VkAllocationCallbacks )* pAllocator, VkSampler* pSampler ) {
		return vkCreateSampler( this.device, pCreateInfo, pAllocator, pSampler );
	}
	void DestroySampler( VkSampler sampler, const( VkAllocationCallbacks )* pAllocator ) {
		vkDestroySampler( this.device, sampler, pAllocator );
	}
	VkResult CreateDescriptorSetLayout( const( VkDescriptorSetLayoutCreateInfo )* pCreateInfo, const( VkAllocationCallbacks )* pAllocator, VkDescriptorSetLayout* pSetLayout ) {
		return vkCreateDescriptorSetLayout( this.device, pCreateInfo, pAllocator, pSetLayout );
	}
	void DestroyDescriptorSetLayout( VkDescriptorSetLayout descriptorSetLayout, const( VkAllocationCallbacks )* pAllocator ) {
		vkDestroyDescriptorSetLayout( this.device, descriptorSetLayout, pAllocator );
	}
	VkResult CreateDescriptorPool( const( VkDescriptorPoolCreateInfo )* pCreateInfo, const( VkAllocationCallbacks )* pAllocator, VkDescriptorPool* pDescriptorPool ) {
		return vkCreateDescriptorPool( this.device, pCreateInfo, pAllocator, pDescriptorPool );
	}
	void DestroyDescriptorPool( VkDescriptorPool descriptorPool, const( VkAllocationCallbacks )* pAllocator ) {
		vkDestroyDescriptorPool( this.device, descriptorPool, pAllocator );
	}
	VkResult ResetDescriptorPool( VkDescriptorPool descriptorPool, VkDescriptorPoolResetFlags flags ) {
		return vkResetDescriptorPool( this.device, descriptorPool, flags );
	}
	VkResult AllocateDescriptorSets( const( VkDescriptorSetAllocateInfo )* pAllocateInfo, VkDescriptorSet* pDescriptorSets ) {
		return vkAllocateDescriptorSets( this.device, pAllocateInfo, pDescriptorSets );
	}
	VkResult FreeDescriptorSets( VkDescriptorPool descriptorPool, uint32_t descriptorSetCount, const( VkDescriptorSet )* pDescriptorSets ) {
		return vkFreeDescriptorSets( this.device, descriptorPool, descriptorSetCount, pDescriptorSets );
	}
	void UpdateDescriptorSets( uint32_t descriptorWriteCount, const( VkWriteDescriptorSet )* pDescriptorWrites, uint32_t descriptorCopyCount, const( VkCopyDescriptorSet )* pDescriptorCopies ) {
		vkUpdateDescriptorSets( this.device, descriptorWriteCount, pDescriptorWrites, descriptorCopyCount, pDescriptorCopies );
	}
	VkResult CreateFramebuffer( const( VkFramebufferCreateInfo )* pCreateInfo, const( VkAllocationCallbacks )* pAllocator, VkFramebuffer* pFramebuffer ) {
		return vkCreateFramebuffer( this.device, pCreateInfo, pAllocator, pFramebuffer );
	}
	void DestroyFramebuffer( VkFramebuffer framebuffer, const( VkAllocationCallbacks )* pAllocator ) {
		vkDestroyFramebuffer( this.device, framebuffer, pAllocator );
	}
	VkResult CreateRenderPass( const( VkRenderPassCreateInfo )* pCreateInfo, const( VkAllocationCallbacks )* pAllocator, VkRenderPass* pRenderPass ) {
		return vkCreateRenderPass( this.device, pCreateInfo, pAllocator, pRenderPass );
	}
	void DestroyRenderPass( VkRenderPass renderPass, const( VkAllocationCallbacks )* pAllocator ) {
		vkDestroyRenderPass( this.device, renderPass, pAllocator );
	}
	void GetRenderAreaGranularity( VkRenderPass renderPass, VkExtent2D* pGranularity ) {
		vkGetRenderAreaGranularity( this.device, renderPass, pGranularity );
	}
	VkResult CreateCommandPool( const( VkCommandPoolCreateInfo )* pCreateInfo, const( VkAllocationCallbacks )* pAllocator, VkCommandPool* pCommandPool ) {
		return vkCreateCommandPool( this.device, pCreateInfo, pAllocator, pCommandPool );
	}
	void DestroyCommandPool( VkCommandPool commandPool, const( VkAllocationCallbacks )* pAllocator ) {
		vkDestroyCommandPool( this.device, commandPool, pAllocator );
	}
	VkResult ResetCommandPool( VkCommandPool commandPool, VkCommandPoolResetFlags flags ) {
		return vkResetCommandPool( this.device, commandPool, flags );
	}
	VkResult AllocateCommandBuffers( const( VkCommandBufferAllocateInfo )* pAllocateInfo, VkCommandBuffer* pCommandBuffers ) {
		return vkAllocateCommandBuffers( this.device, pAllocateInfo, pCommandBuffers );
	}
	void FreeCommandBuffers( VkCommandPool commandPool, uint32_t commandBufferCount, const( VkCommandBuffer )* pCommandBuffers ) {
		vkFreeCommandBuffers( this.device, commandPool, commandBufferCount, pCommandBuffers );
	}
	VkResult BeginCommandBuffer( const( VkCommandBufferBeginInfo )* pBeginInfo ) {
		return vkBeginCommandBuffer( this.commandBuffer, pBeginInfo );
	}
	VkResult EndCommandBuffer() {
		return vkEndCommandBuffer( this.commandBuffer );
	}
	VkResult ResetCommandBuffer( VkCommandBufferResetFlags flags ) {
		return vkResetCommandBuffer( this.commandBuffer, flags );
	}
	void CmdBindPipeline( VkPipelineBindPoint pipelineBindPoint, VkPipeline pipeline ) {
		vkCmdBindPipeline( this.commandBuffer, pipelineBindPoint, pipeline );
	}
	void CmdSetViewport( uint32_t firstViewport, uint32_t viewportCount, const( VkViewport )* pViewports ) {
		vkCmdSetViewport( this.commandBuffer, firstViewport, viewportCount, pViewports );
	}
	void CmdSetScissor( uint32_t firstScissor, uint32_t scissorCount, const( VkRect2D )* pScissors ) {
		vkCmdSetScissor( this.commandBuffer, firstScissor, scissorCount, pScissors );
	}
	void CmdSetLineWidth( float lineWidth ) {
		vkCmdSetLineWidth( this.commandBuffer, lineWidth );
	}
	void CmdSetDepthBias( float depthBiasConstantFactor, float depthBiasClamp, float depthBiasSlopeFactor ) {
		vkCmdSetDepthBias( this.commandBuffer, depthBiasConstantFactor, depthBiasClamp, depthBiasSlopeFactor );
	}
	void CmdSetBlendConstants( const float[4] blendConstants ) {
		vkCmdSetBlendConstants( this.commandBuffer, blendConstants );
	}
	void CmdSetDepthBounds( float minDepthBounds, float maxDepthBounds ) {
		vkCmdSetDepthBounds( this.commandBuffer, minDepthBounds, maxDepthBounds );
	}
	void CmdSetStencilCompareMask( VkStencilFaceFlags faceMask, uint32_t compareMask ) {
		vkCmdSetStencilCompareMask( this.commandBuffer, faceMask, compareMask );
	}
	void CmdSetStencilWriteMask( VkStencilFaceFlags faceMask, uint32_t writeMask ) {
		vkCmdSetStencilWriteMask( this.commandBuffer, faceMask, writeMask );
	}
	void CmdSetStencilReference( VkStencilFaceFlags faceMask, uint32_t reference ) {
		vkCmdSetStencilReference( this.commandBuffer, faceMask, reference );
	}
	void CmdBindDescriptorSets( VkPipelineBindPoint pipelineBindPoint, VkPipelineLayout layout, uint32_t firstSet, uint32_t descriptorSetCount, const( VkDescriptorSet )* pDescriptorSets, uint32_t dynamicOffsetCount, const( uint32_t )* pDynamicOffsets ) {
		vkCmdBindDescriptorSets( this.commandBuffer, pipelineBindPoint, layout, firstSet, descriptorSetCount, pDescriptorSets, dynamicOffsetCount, pDynamicOffsets );
	}
	void CmdBindIndexBuffer( VkBuffer buffer, VkDeviceSize offset, VkIndexType indexType ) {
		vkCmdBindIndexBuffer( this.commandBuffer, buffer, offset, indexType );
	}
	void CmdBindVertexBuffers( uint32_t firstBinding, uint32_t bindingCount, const( VkBuffer )* pBuffers, const( VkDeviceSize )* pOffsets ) {
		vkCmdBindVertexBuffers( this.commandBuffer, firstBinding, bindingCount, pBuffers, pOffsets );
	}
	void CmdDraw( uint32_t vertexCount, uint32_t instanceCount, uint32_t firstVertex, uint32_t firstInstance ) {
		vkCmdDraw( this.commandBuffer, vertexCount, instanceCount, firstVertex, firstInstance );
	}
	void CmdDrawIndexed( uint32_t indexCount, uint32_t instanceCount, uint32_t firstIndex, int32_t vertexOffset, uint32_t firstInstance ) {
		vkCmdDrawIndexed( this.commandBuffer, indexCount, instanceCount, firstIndex, vertexOffset, firstInstance );
	}
	void CmdDrawIndirect( VkBuffer buffer, VkDeviceSize offset, uint32_t drawCount, uint32_t stride ) {
		vkCmdDrawIndirect( this.commandBuffer, buffer, offset, drawCount, stride );
	}
	void CmdDrawIndexedIndirect( VkBuffer buffer, VkDeviceSize offset, uint32_t drawCount, uint32_t stride ) {
		vkCmdDrawIndexedIndirect( this.commandBuffer, buffer, offset, drawCount, stride );
	}
	void CmdDispatch( uint32_t groupCountX, uint32_t groupCountY, uint32_t groupCountZ ) {
		vkCmdDispatch( this.commandBuffer, groupCountX, groupCountY, groupCountZ );
	}
	void CmdDispatchIndirect( VkBuffer buffer, VkDeviceSize offset ) {
		vkCmdDispatchIndirect( this.commandBuffer, buffer, offset );
	}
	void CmdCopyBuffer( VkBuffer srcBuffer, VkBuffer dstBuffer, uint32_t regionCount, const( VkBufferCopy )* pRegions ) {
		vkCmdCopyBuffer( this.commandBuffer, srcBuffer, dstBuffer, regionCount, pRegions );
	}
	void CmdCopyImage( VkImage srcImage, VkImageLayout srcImageLayout, VkImage dstImage, VkImageLayout dstImageLayout, uint32_t regionCount, const( VkImageCopy )* pRegions ) {
		vkCmdCopyImage( this.commandBuffer, srcImage, srcImageLayout, dstImage, dstImageLayout, regionCount, pRegions );
	}
	void CmdBlitImage( VkImage srcImage, VkImageLayout srcImageLayout, VkImage dstImage, VkImageLayout dstImageLayout, uint32_t regionCount, const( VkImageBlit )* pRegions, VkFilter filter ) {
		vkCmdBlitImage( this.commandBuffer, srcImage, srcImageLayout, dstImage, dstImageLayout, regionCount, pRegions, filter );
	}
	void CmdCopyBufferToImage( VkBuffer srcBuffer, VkImage dstImage, VkImageLayout dstImageLayout, uint32_t regionCount, const( VkBufferImageCopy )* pRegions ) {
		vkCmdCopyBufferToImage( this.commandBuffer, srcBuffer, dstImage, dstImageLayout, regionCount, pRegions );
	}
	void CmdCopyImageToBuffer( VkImage srcImage, VkImageLayout srcImageLayout, VkBuffer dstBuffer, uint32_t regionCount, const( VkBufferImageCopy )* pRegions ) {
		vkCmdCopyImageToBuffer( this.commandBuffer, srcImage, srcImageLayout, dstBuffer, regionCount, pRegions );
	}
	void CmdUpdateBuffer( VkBuffer dstBuffer, VkDeviceSize dstOffset, VkDeviceSize dataSize, const( void )* pData ) {
		vkCmdUpdateBuffer( this.commandBuffer, dstBuffer, dstOffset, dataSize, pData );
	}
	void CmdFillBuffer( VkBuffer dstBuffer, VkDeviceSize dstOffset, VkDeviceSize size, uint32_t data ) {
		vkCmdFillBuffer( this.commandBuffer, dstBuffer, dstOffset, size, data );
	}
	void CmdClearColorImage( VkImage image, VkImageLayout imageLayout, const( VkClearColorValue )* pColor, uint32_t rangeCount, const( VkImageSubresourceRange )* pRanges ) {
		vkCmdClearColorImage( this.commandBuffer, image, imageLayout, pColor, rangeCount, pRanges );
	}
	void CmdClearDepthStencilImage( VkImage image, VkImageLayout imageLayout, const( VkClearDepthStencilValue )* pDepthStencil, uint32_t rangeCount, const( VkImageSubresourceRange )* pRanges ) {
		vkCmdClearDepthStencilImage( this.commandBuffer, image, imageLayout, pDepthStencil, rangeCount, pRanges );
	}
	void CmdClearAttachments( uint32_t attachmentCount, const( VkClearAttachment )* pAttachments, uint32_t rectCount, const( VkClearRect )* pRects ) {
		vkCmdClearAttachments( this.commandBuffer, attachmentCount, pAttachments, rectCount, pRects );
	}
	void CmdResolveImage( VkImage srcImage, VkImageLayout srcImageLayout, VkImage dstImage, VkImageLayout dstImageLayout, uint32_t regionCount, const( VkImageResolve )* pRegions ) {
		vkCmdResolveImage( this.commandBuffer, srcImage, srcImageLayout, dstImage, dstImageLayout, regionCount, pRegions );
	}
	void CmdSetEvent( VkEvent event, VkPipelineStageFlags stageMask ) {
		vkCmdSetEvent( this.commandBuffer, event, stageMask );
	}
	void CmdResetEvent( VkEvent event, VkPipelineStageFlags stageMask ) {
		vkCmdResetEvent( this.commandBuffer, event, stageMask );
	}
	void CmdWaitEvents( uint32_t eventCount, const( VkEvent )* pEvents, VkPipelineStageFlags srcStageMask, VkPipelineStageFlags dstStageMask, uint32_t memoryBarrierCount, const( VkMemoryBarrier )* pMemoryBarriers, uint32_t bufferMemoryBarrierCount, const( VkBufferMemoryBarrier )* pBufferMemoryBarriers, uint32_t imageMemoryBarrierCount, const( VkImageMemoryBarrier )* pImageMemoryBarriers ) {
		vkCmdWaitEvents( this.commandBuffer, eventCount, pEvents, srcStageMask, dstStageMask, memoryBarrierCount, pMemoryBarriers, bufferMemoryBarrierCount, pBufferMemoryBarriers, imageMemoryBarrierCount, pImageMemoryBarriers );
	}
	void CmdPipelineBarrier( VkPipelineStageFlags srcStageMask, VkPipelineStageFlags dstStageMask, VkDependencyFlags dependencyFlags, uint32_t memoryBarrierCount, const( VkMemoryBarrier )* pMemoryBarriers, uint32_t bufferMemoryBarrierCount, const( VkBufferMemoryBarrier )* pBufferMemoryBarriers, uint32_t imageMemoryBarrierCount, const( VkImageMemoryBarrier )* pImageMemoryBarriers ) {
		vkCmdPipelineBarrier( this.commandBuffer, srcStageMask, dstStageMask, dependencyFlags, memoryBarrierCount, pMemoryBarriers, bufferMemoryBarrierCount, pBufferMemoryBarriers, imageMemoryBarrierCount, pImageMemoryBarriers );
	}
	void CmdBeginQuery( VkQueryPool queryPool, uint32_t query, VkQueryControlFlags flags ) {
		vkCmdBeginQuery( this.commandBuffer, queryPool, query, flags );
	}
	void CmdEndQuery( VkQueryPool queryPool, uint32_t query ) {
		vkCmdEndQuery( this.commandBuffer, queryPool, query );
	}
	void CmdResetQueryPool( VkQueryPool queryPool, uint32_t firstQuery, uint32_t queryCount ) {
		vkCmdResetQueryPool( this.commandBuffer, queryPool, firstQuery, queryCount );
	}
	void CmdWriteTimestamp( VkPipelineStageFlagBits pipelineStage, VkQueryPool queryPool, uint32_t query ) {
		vkCmdWriteTimestamp( this.commandBuffer, pipelineStage, queryPool, query );
	}
	void CmdCopyQueryPoolResults( VkQueryPool queryPool, uint32_t firstQuery, uint32_t queryCount, VkBuffer dstBuffer, VkDeviceSize dstOffset, VkDeviceSize stride, VkQueryResultFlags flags ) {
		vkCmdCopyQueryPoolResults( this.commandBuffer, queryPool, firstQuery, queryCount, dstBuffer, dstOffset, stride, flags );
	}
	void CmdPushConstants( VkPipelineLayout layout, VkShaderStageFlags stageFlags, uint32_t offset, uint32_t size, const( void )* pValues ) {
		vkCmdPushConstants( this.commandBuffer, layout, stageFlags, offset, size, pValues );
	}
	void CmdBeginRenderPass( const( VkRenderPassBeginInfo )* pRenderPassBegin, VkSubpassContents contents ) {
		vkCmdBeginRenderPass( this.commandBuffer, pRenderPassBegin, contents );
	}
	void CmdNextSubpass( VkSubpassContents contents ) {
		vkCmdNextSubpass( this.commandBuffer, contents );
	}
	void CmdEndRenderPass() {
		vkCmdEndRenderPass( this.commandBuffer );
	}
	void CmdExecuteCommands( uint32_t commandBufferCount, const( VkCommandBuffer )* pCommandBuffers ) {
		vkCmdExecuteCommands( this.commandBuffer, commandBufferCount, pCommandBuffers );
	}

	// VK_KHR_display_swapchain
	VkResult CreateSharedSwapchainsKHR( uint32_t swapchainCount, const( VkSwapchainCreateInfoKHR )* pCreateInfos, const( VkAllocationCallbacks )* pAllocator, VkSwapchainKHR* pSwapchains ) {
		return vkCreateSharedSwapchainsKHR( this.device, swapchainCount, pCreateInfos, pAllocator, pSwapchains );
	}

	// VK_KHR_maintenance1
	void TrimCommandPoolKHR( VkCommandPool commandPool, VkCommandPoolTrimFlagsKHR flags ) {
		vkTrimCommandPoolKHR( this.device, commandPool, flags );
	}

	// VK_KHR_external_memory_win32
	version( VK_USE_PLATFORM_WIN32_KHR ) {
		VkResult GetMemoryWin32HandleKHR( const( VkMemoryGetWin32HandleInfoKHR )* pGetWin32HandleInfo, HANDLE* pHandle ) {
			return vkGetMemoryWin32HandleKHR( this.device, pGetWin32HandleInfo, pHandle );
		}
		VkResult GetMemoryWin32HandlePropertiesKHR( VkExternalMemoryHandleTypeFlagBitsKHR handleType, HANDLE handle, VkMemoryWin32HandlePropertiesKHR* pMemoryWin32HandleProperties ) {
			return vkGetMemoryWin32HandlePropertiesKHR( this.device, handleType, handle, pMemoryWin32HandleProperties );
		}
	}

	// VK_KHR_external_memory_fd
	VkResult GetMemoryFdKHR( const( VkMemoryGetFdInfoKHR )* pGetFdInfo, int* pFd ) {
		return vkGetMemoryFdKHR( this.device, pGetFdInfo, pFd );
	}
	VkResult GetMemoryFdPropertiesKHR( VkExternalMemoryHandleTypeFlagBitsKHR handleType, int fd, VkMemoryFdPropertiesKHR* pMemoryFdProperties ) {
		return vkGetMemoryFdPropertiesKHR( this.device, handleType, fd, pMemoryFdProperties );
	}

	// VK_KHR_external_semaphore_win32
	version( VK_USE_PLATFORM_WIN32_KHR ) {
		VkResult ImportSemaphoreWin32HandleKHR( const( VkImportSemaphoreWin32HandleInfoKHR )* pImportSemaphoreWin32HandleInfo ) {
			return vkImportSemaphoreWin32HandleKHR( this.device, pImportSemaphoreWin32HandleInfo );
		}
		VkResult GetSemaphoreWin32HandleKHR( const( VkSemaphoreGetWin32HandleInfoKHR )* pGetWin32HandleInfo, HANDLE* pHandle ) {
			return vkGetSemaphoreWin32HandleKHR( this.device, pGetWin32HandleInfo, pHandle );
		}
	}

	// VK_KHR_external_semaphore_fd
	VkResult ImportSemaphoreFdKHR( const( VkImportSemaphoreFdInfoKHR )* pImportSemaphoreFdInfo ) {
		return vkImportSemaphoreFdKHR( this.device, pImportSemaphoreFdInfo );
	}
	VkResult GetSemaphoreFdKHR( const( VkSemaphoreGetFdInfoKHR )* pGetFdInfo, int* pFd ) {
		return vkGetSemaphoreFdKHR( this.device, pGetFdInfo, pFd );
	}

	// VK_KHR_push_descriptor
	void CmdPushDescriptorSetKHR( VkPipelineBindPoint pipelineBindPoint, VkPipelineLayout layout, uint32_t set, uint32_t descriptorWriteCount, const( VkWriteDescriptorSet )* pDescriptorWrites ) {
		vkCmdPushDescriptorSetKHR( this.commandBuffer, pipelineBindPoint, layout, set, descriptorWriteCount, pDescriptorWrites );
	}

	// VK_KHR_descriptor_update_template
	VkResult CreateDescriptorUpdateTemplateKHR( const( VkDescriptorUpdateTemplateCreateInfoKHR )* pCreateInfo, const( VkAllocationCallbacks )* pAllocator, VkDescriptorUpdateTemplateKHR* pDescriptorUpdateTemplate ) {
		return vkCreateDescriptorUpdateTemplateKHR( this.device, pCreateInfo, pAllocator, pDescriptorUpdateTemplate );
	}
	void DestroyDescriptorUpdateTemplateKHR( VkDescriptorUpdateTemplateKHR descriptorUpdateTemplate, const( VkAllocationCallbacks )* pAllocator ) {
		vkDestroyDescriptorUpdateTemplateKHR( this.device, descriptorUpdateTemplate, pAllocator );
	}
	void UpdateDescriptorSetWithTemplateKHR( VkDescriptorSet descriptorSet, VkDescriptorUpdateTemplateKHR descriptorUpdateTemplate, const( void )* pData ) {
		vkUpdateDescriptorSetWithTemplateKHR( this.device, descriptorSet, descriptorUpdateTemplate, pData );
	}
	void CmdPushDescriptorSetWithTemplateKHR( VkDescriptorUpdateTemplateKHR descriptorUpdateTemplate, VkPipelineLayout layout, uint32_t set, const( void )* pData ) {
		vkCmdPushDescriptorSetWithTemplateKHR( this.commandBuffer, descriptorUpdateTemplate, layout, set, pData );
	}

	// VK_KHR_shared_presentable_image
	VkResult GetSwapchainStatusKHR( VkSwapchainKHR swapchain ) {
		return vkGetSwapchainStatusKHR( this.device, swapchain );
	}

	// VK_KHR_external_fence_win32
	version( VK_USE_PLATFORM_WIN32_KHR ) {
		VkResult ImportFenceWin32HandleKHR( const( VkImportFenceWin32HandleInfoKHR )* pImportFenceWin32HandleInfo ) {
			return vkImportFenceWin32HandleKHR( this.device, pImportFenceWin32HandleInfo );
		}
		VkResult GetFenceWin32HandleKHR( const( VkFenceGetWin32HandleInfoKHR )* pGetWin32HandleInfo, HANDLE* pHandle ) {
			return vkGetFenceWin32HandleKHR( this.device, pGetWin32HandleInfo, pHandle );
		}
	}

	// VK_KHR_external_fence_fd
	VkResult ImportFenceFdKHR( const( VkImportFenceFdInfoKHR )* pImportFenceFdInfo ) {
		return vkImportFenceFdKHR( this.device, pImportFenceFdInfo );
	}
	VkResult GetFenceFdKHR( const( VkFenceGetFdInfoKHR )* pGetFdInfo, int* pFd ) {
		return vkGetFenceFdKHR( this.device, pGetFdInfo, pFd );
	}

	// VK_KHR_get_memory_requirements2
	void GetImageMemoryRequirements2KHR( const( VkImageMemoryRequirementsInfo2KHR )* pInfo, VkMemoryRequirements2KHR* pMemoryRequirements ) {
		vkGetImageMemoryRequirements2KHR( this.device, pInfo, pMemoryRequirements );
	}
	void GetBufferMemoryRequirements2KHR( const( VkBufferMemoryRequirementsInfo2KHR )* pInfo, VkMemoryRequirements2KHR* pMemoryRequirements ) {
		vkGetBufferMemoryRequirements2KHR( this.device, pInfo, pMemoryRequirements );
	}
	void GetImageSparseMemoryRequirements2KHR( const( VkImageSparseMemoryRequirementsInfo2KHR )* pInfo, uint32_t* pSparseMemoryRequirementCount, VkSparseImageMemoryRequirements2KHR* pSparseMemoryRequirements ) {
		vkGetImageSparseMemoryRequirements2KHR( this.device, pInfo, pSparseMemoryRequirementCount, pSparseMemoryRequirements );
	}

	// VK_KHR_sampler_ycbcr_conversion
	VkResult CreateSamplerYcbcrConversionKHR( const( VkSamplerYcbcrConversionCreateInfoKHR )* pCreateInfo, const( VkAllocationCallbacks )* pAllocator, VkSamplerYcbcrConversionKHR* pYcbcrConversion ) {
		return vkCreateSamplerYcbcrConversionKHR( this.device, pCreateInfo, pAllocator, pYcbcrConversion );
	}
	void DestroySamplerYcbcrConversionKHR( VkSamplerYcbcrConversionKHR ycbcrConversion, const( VkAllocationCallbacks )* pAllocator ) {
		vkDestroySamplerYcbcrConversionKHR( this.device, ycbcrConversion, pAllocator );
	}

	// VK_KHR_bind_memory2
	VkResult BindBufferMemory2KHR( uint32_t bindInfoCount, const( VkBindBufferMemoryInfoKHR )* pBindInfos ) {
		return vkBindBufferMemory2KHR( this.device, bindInfoCount, pBindInfos );
	}
	VkResult BindImageMemory2KHR( uint32_t bindInfoCount, const( VkBindImageMemoryInfoKHR )* pBindInfos ) {
		return vkBindImageMemory2KHR( this.device, bindInfoCount, pBindInfos );
	}

	// VK_EXT_debug_marker
	VkResult DebugMarkerSetObjectTagEXT( const( VkDebugMarkerObjectTagInfoEXT )* pTagInfo ) {
		return vkDebugMarkerSetObjectTagEXT( this.device, pTagInfo );
	}
	VkResult DebugMarkerSetObjectNameEXT( const( VkDebugMarkerObjectNameInfoEXT )* pNameInfo ) {
		return vkDebugMarkerSetObjectNameEXT( this.device, pNameInfo );
	}
	void CmdDebugMarkerBeginEXT( const( VkDebugMarkerMarkerInfoEXT )* pMarkerInfo ) {
		vkCmdDebugMarkerBeginEXT( this.commandBuffer, pMarkerInfo );
	}
	void CmdDebugMarkerEndEXT() {
		vkCmdDebugMarkerEndEXT( this.commandBuffer );
	}
	void CmdDebugMarkerInsertEXT( const( VkDebugMarkerMarkerInfoEXT )* pMarkerInfo ) {
		vkCmdDebugMarkerInsertEXT( this.commandBuffer, pMarkerInfo );
	}

	// VK_AMD_draw_indirect_count
	void CmdDrawIndirectCountAMD( VkBuffer buffer, VkDeviceSize offset, VkBuffer countBuffer, VkDeviceSize countBufferOffset, uint32_t maxDrawCount, uint32_t stride ) {
		vkCmdDrawIndirectCountAMD( this.commandBuffer, buffer, offset, countBuffer, countBufferOffset, maxDrawCount, stride );
	}
	void CmdDrawIndexedIndirectCountAMD( VkBuffer buffer, VkDeviceSize offset, VkBuffer countBuffer, VkDeviceSize countBufferOffset, uint32_t maxDrawCount, uint32_t stride ) {
		vkCmdDrawIndexedIndirectCountAMD( this.commandBuffer, buffer, offset, countBuffer, countBufferOffset, maxDrawCount, stride );
	}

	// VK_AMD_shader_info
	VkResult GetShaderInfoAMD( VkPipeline pipeline, VkShaderStageFlagBits shaderStage, VkShaderInfoTypeAMD infoType, size_t* pInfoSize, void* pInfo ) {
		return vkGetShaderInfoAMD( this.device, pipeline, shaderStage, infoType, pInfoSize, pInfo );
	}

	// VK_NV_external_memory_win32
	version( VK_USE_PLATFORM_WIN32_KHR ) {
		VkResult GetMemoryWin32HandleNV( VkDeviceMemory memory, VkExternalMemoryHandleTypeFlagsNV handleType, HANDLE* pHandle ) {
			return vkGetMemoryWin32HandleNV( this.device, memory, handleType, pHandle );
		}
	}

	// VK_KHX_device_group
	void GetDeviceGroupPeerMemoryFeaturesKHX( uint32_t heapIndex, uint32_t localDeviceIndex, uint32_t remoteDeviceIndex, VkPeerMemoryFeatureFlagsKHX* pPeerMemoryFeatures ) {
		vkGetDeviceGroupPeerMemoryFeaturesKHX( this.device, heapIndex, localDeviceIndex, remoteDeviceIndex, pPeerMemoryFeatures );
	}
	void CmdSetDeviceMaskKHX( uint32_t deviceMask ) {
		vkCmdSetDeviceMaskKHX( this.commandBuffer, deviceMask );
	}
	void CmdDispatchBaseKHX( uint32_t baseGroupX, uint32_t baseGroupY, uint32_t baseGroupZ, uint32_t groupCountX, uint32_t groupCountY, uint32_t groupCountZ ) {
		vkCmdDispatchBaseKHX( this.commandBuffer, baseGroupX, baseGroupY, baseGroupZ, groupCountX, groupCountY, groupCountZ );
	}
	VkResult GetDeviceGroupPresentCapabilitiesKHX( VkDeviceGroupPresentCapabilitiesKHX* pDeviceGroupPresentCapabilities ) {
		return vkGetDeviceGroupPresentCapabilitiesKHX( this.device, pDeviceGroupPresentCapabilities );
	}
	VkResult GetDeviceGroupSurfacePresentModesKHX( VkSurfaceKHR surface, VkDeviceGroupPresentModeFlagsKHX* pModes ) {
		return vkGetDeviceGroupSurfacePresentModesKHX( this.device, surface, pModes );
	}
	VkResult AcquireNextImage2KHX( const( VkAcquireNextImageInfoKHX )* pAcquireInfo, uint32_t* pImageIndex ) {
		return vkAcquireNextImage2KHX( this.device, pAcquireInfo, pImageIndex );
	}

	// VK_NV_clip_space_w_scaling
	void CmdSetViewportWScalingNV( uint32_t firstViewport, uint32_t viewportCount, const( VkViewportWScalingNV )* pViewportWScalings ) {
		vkCmdSetViewportWScalingNV( this.commandBuffer, firstViewport, viewportCount, pViewportWScalings );
	}

	// VK_EXT_display_control
	VkResult DisplayPowerControlEXT( VkDisplayKHR display, const( VkDisplayPowerInfoEXT )* pDisplayPowerInfo ) {
		return vkDisplayPowerControlEXT( this.device, display, pDisplayPowerInfo );
	}
	VkResult RegisterDeviceEventEXT( const( VkDeviceEventInfoEXT )* pDeviceEventInfo, const( VkAllocationCallbacks )* pAllocator, VkFence* pFence ) {
		return vkRegisterDeviceEventEXT( this.device, pDeviceEventInfo, pAllocator, pFence );
	}
	VkResult RegisterDisplayEventEXT( VkDisplayKHR display, const( VkDisplayEventInfoEXT )* pDisplayEventInfo, const( VkAllocationCallbacks )* pAllocator, VkFence* pFence ) {
		return vkRegisterDisplayEventEXT( this.device, display, pDisplayEventInfo, pAllocator, pFence );
	}
	VkResult GetSwapchainCounterEXT( VkSwapchainKHR swapchain, VkSurfaceCounterFlagBitsEXT counter, uint64_t* pCounterValue ) {
		return vkGetSwapchainCounterEXT( this.device, swapchain, counter, pCounterValue );
	}

	// VK_GOOGLE_display_timing
	VkResult GetRefreshCycleDurationGOOGLE( VkSwapchainKHR swapchain, VkRefreshCycleDurationGOOGLE* pDisplayTimingProperties ) {
		return vkGetRefreshCycleDurationGOOGLE( this.device, swapchain, pDisplayTimingProperties );
	}
	VkResult GetPastPresentationTimingGOOGLE( VkSwapchainKHR swapchain, uint32_t* pPresentationTimingCount, VkPastPresentationTimingGOOGLE* pPresentationTimings ) {
		return vkGetPastPresentationTimingGOOGLE( this.device, swapchain, pPresentationTimingCount, pPresentationTimings );
	}

	// VK_EXT_discard_rectangles
	void CmdSetDiscardRectangleEXT( uint32_t firstDiscardRectangle, uint32_t discardRectangleCount, const( VkRect2D )* pDiscardRectangles ) {
		vkCmdSetDiscardRectangleEXT( this.commandBuffer, firstDiscardRectangle, discardRectangleCount, pDiscardRectangles );
	}

	// VK_EXT_hdr_metadata
	void SetHdrMetadataEXT( uint32_t swapchainCount, const( VkSwapchainKHR )* pSwapchains, const( VkHdrMetadataEXT )* pMetadata ) {
		vkSetHdrMetadataEXT( this.device, swapchainCount, pSwapchains, pMetadata );
	}

	// VK_EXT_validation_cache
	VkResult CreateValidationCacheEXT( const( VkValidationCacheCreateInfoEXT )* pCreateInfo, const( VkAllocationCallbacks )* pAllocator, VkValidationCacheEXT* pValidationCache ) {
		return vkCreateValidationCacheEXT( this.device, pCreateInfo, pAllocator, pValidationCache );
	}
	void DestroyValidationCacheEXT( VkValidationCacheEXT validationCache, const( VkAllocationCallbacks )* pAllocator ) {
		vkDestroyValidationCacheEXT( this.device, validationCache, pAllocator );
	}
	VkResult MergeValidationCachesEXT( VkValidationCacheEXT dstCache, uint32_t srcCacheCount, const( VkValidationCacheEXT )* pSrcCaches ) {
		return vkMergeValidationCachesEXT( this.device, dstCache, srcCacheCount, pSrcCaches );
	}
	VkResult GetValidationCacheDataEXT( VkValidationCacheEXT validationCache, size_t* pDataSize, void* pData ) {
		return vkGetValidationCacheDataEXT( this.device, validationCache, pDataSize, pData );
	}

	// Member vulkan function decelerations
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
	PFN_vkTrimCommandPoolKHR vkTrimCommandPoolKHR;
	version( VK_USE_PLATFORM_WIN32_KHR ) {
		PFN_vkGetMemoryWin32HandleKHR vkGetMemoryWin32HandleKHR;
		PFN_vkGetMemoryWin32HandlePropertiesKHR vkGetMemoryWin32HandlePropertiesKHR;
	}
	PFN_vkGetMemoryFdKHR vkGetMemoryFdKHR;
	PFN_vkGetMemoryFdPropertiesKHR vkGetMemoryFdPropertiesKHR;
	version( VK_USE_PLATFORM_WIN32_KHR ) {
		PFN_vkImportSemaphoreWin32HandleKHR vkImportSemaphoreWin32HandleKHR;
		PFN_vkGetSemaphoreWin32HandleKHR vkGetSemaphoreWin32HandleKHR;
	}
	PFN_vkImportSemaphoreFdKHR vkImportSemaphoreFdKHR;
	PFN_vkGetSemaphoreFdKHR vkGetSemaphoreFdKHR;
	PFN_vkCmdPushDescriptorSetKHR vkCmdPushDescriptorSetKHR;
	PFN_vkCreateDescriptorUpdateTemplateKHR vkCreateDescriptorUpdateTemplateKHR;
	PFN_vkDestroyDescriptorUpdateTemplateKHR vkDestroyDescriptorUpdateTemplateKHR;
	PFN_vkUpdateDescriptorSetWithTemplateKHR vkUpdateDescriptorSetWithTemplateKHR;
	PFN_vkCmdPushDescriptorSetWithTemplateKHR vkCmdPushDescriptorSetWithTemplateKHR;
	PFN_vkGetSwapchainStatusKHR vkGetSwapchainStatusKHR;
	version( VK_USE_PLATFORM_WIN32_KHR ) {
		PFN_vkImportFenceWin32HandleKHR vkImportFenceWin32HandleKHR;
		PFN_vkGetFenceWin32HandleKHR vkGetFenceWin32HandleKHR;
	}
	PFN_vkImportFenceFdKHR vkImportFenceFdKHR;
	PFN_vkGetFenceFdKHR vkGetFenceFdKHR;
	PFN_vkGetImageMemoryRequirements2KHR vkGetImageMemoryRequirements2KHR;
	PFN_vkGetBufferMemoryRequirements2KHR vkGetBufferMemoryRequirements2KHR;
	PFN_vkGetImageSparseMemoryRequirements2KHR vkGetImageSparseMemoryRequirements2KHR;
	PFN_vkCreateSamplerYcbcrConversionKHR vkCreateSamplerYcbcrConversionKHR;
	PFN_vkDestroySamplerYcbcrConversionKHR vkDestroySamplerYcbcrConversionKHR;
	PFN_vkBindBufferMemory2KHR vkBindBufferMemory2KHR;
	PFN_vkBindImageMemory2KHR vkBindImageMemory2KHR;
	PFN_vkGetSwapchainGrallocUsageANDROID vkGetSwapchainGrallocUsageANDROID;
	PFN_vkAcquireImageANDROID vkAcquireImageANDROID;
	PFN_vkQueueSignalReleaseImageANDROID vkQueueSignalReleaseImageANDROID;
	PFN_vkDebugMarkerSetObjectTagEXT vkDebugMarkerSetObjectTagEXT;
	PFN_vkDebugMarkerSetObjectNameEXT vkDebugMarkerSetObjectNameEXT;
	PFN_vkCmdDebugMarkerBeginEXT vkCmdDebugMarkerBeginEXT;
	PFN_vkCmdDebugMarkerEndEXT vkCmdDebugMarkerEndEXT;
	PFN_vkCmdDebugMarkerInsertEXT vkCmdDebugMarkerInsertEXT;
	PFN_vkCmdDrawIndirectCountAMD vkCmdDrawIndirectCountAMD;
	PFN_vkCmdDrawIndexedIndirectCountAMD vkCmdDrawIndexedIndirectCountAMD;
	PFN_vkGetShaderInfoAMD vkGetShaderInfoAMD;
	version( VK_USE_PLATFORM_WIN32_KHR ) {
		PFN_vkGetMemoryWin32HandleNV vkGetMemoryWin32HandleNV;
	}
	PFN_vkGetDeviceGroupPeerMemoryFeaturesKHX vkGetDeviceGroupPeerMemoryFeaturesKHX;
	PFN_vkCmdSetDeviceMaskKHX vkCmdSetDeviceMaskKHX;
	PFN_vkCmdDispatchBaseKHX vkCmdDispatchBaseKHX;
	PFN_vkGetDeviceGroupPresentCapabilitiesKHX vkGetDeviceGroupPresentCapabilitiesKHX;
	PFN_vkGetDeviceGroupSurfacePresentModesKHX vkGetDeviceGroupSurfacePresentModesKHX;
	PFN_vkAcquireNextImage2KHX vkAcquireNextImage2KHX;
	PFN_vkCmdProcessCommandsNVX vkCmdProcessCommandsNVX;
	PFN_vkCmdReserveSpaceForCommandsNVX vkCmdReserveSpaceForCommandsNVX;
	PFN_vkCreateIndirectCommandsLayoutNVX vkCreateIndirectCommandsLayoutNVX;
	PFN_vkDestroyIndirectCommandsLayoutNVX vkDestroyIndirectCommandsLayoutNVX;
	PFN_vkCreateObjectTableNVX vkCreateObjectTableNVX;
	PFN_vkDestroyObjectTableNVX vkDestroyObjectTableNVX;
	PFN_vkRegisterObjectsNVX vkRegisterObjectsNVX;
	PFN_vkUnregisterObjectsNVX vkUnregisterObjectsNVX;
	PFN_vkCmdSetViewportWScalingNV vkCmdSetViewportWScalingNV;
	PFN_vkDisplayPowerControlEXT vkDisplayPowerControlEXT;
	PFN_vkRegisterDeviceEventEXT vkRegisterDeviceEventEXT;
	PFN_vkRegisterDisplayEventEXT vkRegisterDisplayEventEXT;
	PFN_vkGetSwapchainCounterEXT vkGetSwapchainCounterEXT;
	PFN_vkGetRefreshCycleDurationGOOGLE vkGetRefreshCycleDurationGOOGLE;
	PFN_vkGetPastPresentationTimingGOOGLE vkGetPastPresentationTimingGOOGLE;
	PFN_vkCmdSetDiscardRectangleEXT vkCmdSetDiscardRectangleEXT;
	PFN_vkSetHdrMetadataEXT vkSetHdrMetadataEXT;
	PFN_vkCmdSetSampleLocationsEXT vkCmdSetSampleLocationsEXT;
	PFN_vkCreateValidationCacheEXT vkCreateValidationCacheEXT;
	PFN_vkDestroyValidationCacheEXT vkDestroyValidationCacheEXT;
	PFN_vkMergeValidationCachesEXT vkMergeValidationCachesEXT;
	PFN_vkGetValidationCacheDataEXT vkGetValidationCacheDataEXT;
}

// Derelict loader to acquire entry point vkGetInstanceProcAddr
version( ERUPTED_FROM_DERELICT ) {
	import derelict.util.loader;
	import derelict.util.system;

	private {
		version( Windows )
			enum libNames = "vulkan-1.dll";

		else version( Posix )
			enum libNames = "libvulkan.so.1";

		else
			static assert( 0,"Need to implement Vulkan libNames for this operating system." );
	}

	class DerelictEruptedLoader : SharedLibLoader {
		this() {
			super( libNames );
		}

		protected override void loadSymbols() {
			typeof( vkGetInstanceProcAddr ) getProcAddr;
			bindFunc( cast( void** )&getProcAddr, "vkGetInstanceProcAddr" );
			loadGlobalLevelFunctions( getProcAddr );
		}
	}

	__gshared DerelictEruptedLoader DerelictErupted;

	shared static this() {
		DerelictErupted = new DerelictEruptedLoader();
	}
}


