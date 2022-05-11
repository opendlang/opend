/**
 * Dlang vulkan function pointer prototypes, declarations and loader from vkGetInstanceProcAddr
 *
 * Copyright: Copyright 2015-2016 The Khronos Group Inc.; Copyright 2016 Alex Parrill, Peter Particle.
 * License:   $(https://opensource.org/licenses/MIT, MIT License).
 * Authors: Copyright 2016 Alex Parrill, Peter Particle
 */
module erupted.functions;

public import erupted.types;

nothrow @nogc:


/// function type aliases
extern( System ) {

    // VK_VERSION_1_0
    alias PFN_vkCreateInstance                                                  = VkResult  function( const( VkInstanceCreateInfo )* pCreateInfo, const( VkAllocationCallbacks )* pAllocator, VkInstance* pInstance );
    alias PFN_vkDestroyInstance                                                 = void      function( VkInstance instance, const( VkAllocationCallbacks )* pAllocator );
    alias PFN_vkEnumeratePhysicalDevices                                        = VkResult  function( VkInstance instance, uint32_t* pPhysicalDeviceCount, VkPhysicalDevice* pPhysicalDevices );
    alias PFN_vkGetPhysicalDeviceFeatures                                       = void      function( VkPhysicalDevice physicalDevice, VkPhysicalDeviceFeatures* pFeatures );
    alias PFN_vkGetPhysicalDeviceFormatProperties                               = void      function( VkPhysicalDevice physicalDevice, VkFormat format, VkFormatProperties* pFormatProperties );
    alias PFN_vkGetPhysicalDeviceImageFormatProperties                          = VkResult  function( VkPhysicalDevice physicalDevice, VkFormat format, VkImageType type, VkImageTiling tiling, VkImageUsageFlags usage, VkImageCreateFlags flags, VkImageFormatProperties* pImageFormatProperties );
    alias PFN_vkGetPhysicalDeviceProperties                                     = void      function( VkPhysicalDevice physicalDevice, VkPhysicalDeviceProperties* pProperties );
    alias PFN_vkGetPhysicalDeviceQueueFamilyProperties                          = void      function( VkPhysicalDevice physicalDevice, uint32_t* pQueueFamilyPropertyCount, VkQueueFamilyProperties* pQueueFamilyProperties );
    alias PFN_vkGetPhysicalDeviceMemoryProperties                               = void      function( VkPhysicalDevice physicalDevice, VkPhysicalDeviceMemoryProperties* pMemoryProperties );
    alias PFN_vkGetInstanceProcAddr                                             = PFN_vkVoidFunction  function( VkInstance instance, const( char )* pName );
    alias PFN_vkGetDeviceProcAddr                                               = PFN_vkVoidFunction  function( VkDevice device, const( char )* pName );
    alias PFN_vkCreateDevice                                                    = VkResult  function( VkPhysicalDevice physicalDevice, const( VkDeviceCreateInfo )* pCreateInfo, const( VkAllocationCallbacks )* pAllocator, VkDevice* pDevice );
    alias PFN_vkDestroyDevice                                                   = void      function( VkDevice device, const( VkAllocationCallbacks )* pAllocator );
    alias PFN_vkEnumerateInstanceExtensionProperties                            = VkResult  function( const( char )* pLayerName, uint32_t* pPropertyCount, VkExtensionProperties* pProperties );
    alias PFN_vkEnumerateDeviceExtensionProperties                              = VkResult  function( VkPhysicalDevice physicalDevice, const( char )* pLayerName, uint32_t* pPropertyCount, VkExtensionProperties* pProperties );
    alias PFN_vkEnumerateInstanceLayerProperties                                = VkResult  function( uint32_t* pPropertyCount, VkLayerProperties* pProperties );
    alias PFN_vkEnumerateDeviceLayerProperties                                  = VkResult  function( VkPhysicalDevice physicalDevice, uint32_t* pPropertyCount, VkLayerProperties* pProperties );
    alias PFN_vkGetDeviceQueue                                                  = void      function( VkDevice device, uint32_t queueFamilyIndex, uint32_t queueIndex, VkQueue* pQueue );
    alias PFN_vkQueueSubmit                                                     = VkResult  function( VkQueue queue, uint32_t submitCount, const( VkSubmitInfo )* pSubmits, VkFence fence );
    alias PFN_vkQueueWaitIdle                                                   = VkResult  function( VkQueue queue );
    alias PFN_vkDeviceWaitIdle                                                  = VkResult  function( VkDevice device );
    alias PFN_vkAllocateMemory                                                  = VkResult  function( VkDevice device, const( VkMemoryAllocateInfo )* pAllocateInfo, const( VkAllocationCallbacks )* pAllocator, VkDeviceMemory* pMemory );
    alias PFN_vkFreeMemory                                                      = void      function( VkDevice device, VkDeviceMemory memory, const( VkAllocationCallbacks )* pAllocator );
    alias PFN_vkMapMemory                                                       = VkResult  function( VkDevice device, VkDeviceMemory memory, VkDeviceSize offset, VkDeviceSize size, VkMemoryMapFlags flags, void** ppData );
    alias PFN_vkUnmapMemory                                                     = void      function( VkDevice device, VkDeviceMemory memory );
    alias PFN_vkFlushMappedMemoryRanges                                         = VkResult  function( VkDevice device, uint32_t memoryRangeCount, const( VkMappedMemoryRange )* pMemoryRanges );
    alias PFN_vkInvalidateMappedMemoryRanges                                    = VkResult  function( VkDevice device, uint32_t memoryRangeCount, const( VkMappedMemoryRange )* pMemoryRanges );
    alias PFN_vkGetDeviceMemoryCommitment                                       = void      function( VkDevice device, VkDeviceMemory memory, VkDeviceSize* pCommittedMemoryInBytes );
    alias PFN_vkBindBufferMemory                                                = VkResult  function( VkDevice device, VkBuffer buffer, VkDeviceMemory memory, VkDeviceSize memoryOffset );
    alias PFN_vkBindImageMemory                                                 = VkResult  function( VkDevice device, VkImage image, VkDeviceMemory memory, VkDeviceSize memoryOffset );
    alias PFN_vkGetBufferMemoryRequirements                                     = void      function( VkDevice device, VkBuffer buffer, VkMemoryRequirements* pMemoryRequirements );
    alias PFN_vkGetImageMemoryRequirements                                      = void      function( VkDevice device, VkImage image, VkMemoryRequirements* pMemoryRequirements );
    alias PFN_vkGetImageSparseMemoryRequirements                                = void      function( VkDevice device, VkImage image, uint32_t* pSparseMemoryRequirementCount, VkSparseImageMemoryRequirements* pSparseMemoryRequirements );
    alias PFN_vkGetPhysicalDeviceSparseImageFormatProperties                    = void      function( VkPhysicalDevice physicalDevice, VkFormat format, VkImageType type, VkSampleCountFlagBits samples, VkImageUsageFlags usage, VkImageTiling tiling, uint32_t* pPropertyCount, VkSparseImageFormatProperties* pProperties );
    alias PFN_vkQueueBindSparse                                                 = VkResult  function( VkQueue queue, uint32_t bindInfoCount, const( VkBindSparseInfo )* pBindInfo, VkFence fence );
    alias PFN_vkCreateFence                                                     = VkResult  function( VkDevice device, const( VkFenceCreateInfo )* pCreateInfo, const( VkAllocationCallbacks )* pAllocator, VkFence* pFence );
    alias PFN_vkDestroyFence                                                    = void      function( VkDevice device, VkFence fence, const( VkAllocationCallbacks )* pAllocator );
    alias PFN_vkResetFences                                                     = VkResult  function( VkDevice device, uint32_t fenceCount, const( VkFence )* pFences );
    alias PFN_vkGetFenceStatus                                                  = VkResult  function( VkDevice device, VkFence fence );
    alias PFN_vkWaitForFences                                                   = VkResult  function( VkDevice device, uint32_t fenceCount, const( VkFence )* pFences, VkBool32 waitAll, uint64_t timeout );
    alias PFN_vkCreateSemaphore                                                 = VkResult  function( VkDevice device, const( VkSemaphoreCreateInfo )* pCreateInfo, const( VkAllocationCallbacks )* pAllocator, VkSemaphore* pSemaphore );
    alias PFN_vkDestroySemaphore                                                = void      function( VkDevice device, VkSemaphore semaphore, const( VkAllocationCallbacks )* pAllocator );
    alias PFN_vkCreateEvent                                                     = VkResult  function( VkDevice device, const( VkEventCreateInfo )* pCreateInfo, const( VkAllocationCallbacks )* pAllocator, VkEvent* pEvent );
    alias PFN_vkDestroyEvent                                                    = void      function( VkDevice device, VkEvent event, const( VkAllocationCallbacks )* pAllocator );
    alias PFN_vkGetEventStatus                                                  = VkResult  function( VkDevice device, VkEvent event );
    alias PFN_vkSetEvent                                                        = VkResult  function( VkDevice device, VkEvent event );
    alias PFN_vkResetEvent                                                      = VkResult  function( VkDevice device, VkEvent event );
    alias PFN_vkCreateQueryPool                                                 = VkResult  function( VkDevice device, const( VkQueryPoolCreateInfo )* pCreateInfo, const( VkAllocationCallbacks )* pAllocator, VkQueryPool* pQueryPool );
    alias PFN_vkDestroyQueryPool                                                = void      function( VkDevice device, VkQueryPool queryPool, const( VkAllocationCallbacks )* pAllocator );
    alias PFN_vkGetQueryPoolResults                                             = VkResult  function( VkDevice device, VkQueryPool queryPool, uint32_t firstQuery, uint32_t queryCount, size_t dataSize, void* pData, VkDeviceSize stride, VkQueryResultFlags flags );
    alias PFN_vkCreateBuffer                                                    = VkResult  function( VkDevice device, const( VkBufferCreateInfo )* pCreateInfo, const( VkAllocationCallbacks )* pAllocator, VkBuffer* pBuffer );
    alias PFN_vkDestroyBuffer                                                   = void      function( VkDevice device, VkBuffer buffer, const( VkAllocationCallbacks )* pAllocator );
    alias PFN_vkCreateBufferView                                                = VkResult  function( VkDevice device, const( VkBufferViewCreateInfo )* pCreateInfo, const( VkAllocationCallbacks )* pAllocator, VkBufferView* pView );
    alias PFN_vkDestroyBufferView                                               = void      function( VkDevice device, VkBufferView bufferView, const( VkAllocationCallbacks )* pAllocator );
    alias PFN_vkCreateImage                                                     = VkResult  function( VkDevice device, const( VkImageCreateInfo )* pCreateInfo, const( VkAllocationCallbacks )* pAllocator, VkImage* pImage );
    alias PFN_vkDestroyImage                                                    = void      function( VkDevice device, VkImage image, const( VkAllocationCallbacks )* pAllocator );
    alias PFN_vkGetImageSubresourceLayout                                       = void      function( VkDevice device, VkImage image, const( VkImageSubresource )* pSubresource, VkSubresourceLayout* pLayout );
    alias PFN_vkCreateImageView                                                 = VkResult  function( VkDevice device, const( VkImageViewCreateInfo )* pCreateInfo, const( VkAllocationCallbacks )* pAllocator, VkImageView* pView );
    alias PFN_vkDestroyImageView                                                = void      function( VkDevice device, VkImageView imageView, const( VkAllocationCallbacks )* pAllocator );
    alias PFN_vkCreateShaderModule                                              = VkResult  function( VkDevice device, const( VkShaderModuleCreateInfo )* pCreateInfo, const( VkAllocationCallbacks )* pAllocator, VkShaderModule* pShaderModule );
    alias PFN_vkDestroyShaderModule                                             = void      function( VkDevice device, VkShaderModule shaderModule, const( VkAllocationCallbacks )* pAllocator );
    alias PFN_vkCreatePipelineCache                                             = VkResult  function( VkDevice device, const( VkPipelineCacheCreateInfo )* pCreateInfo, const( VkAllocationCallbacks )* pAllocator, VkPipelineCache* pPipelineCache );
    alias PFN_vkDestroyPipelineCache                                            = void      function( VkDevice device, VkPipelineCache pipelineCache, const( VkAllocationCallbacks )* pAllocator );
    alias PFN_vkGetPipelineCacheData                                            = VkResult  function( VkDevice device, VkPipelineCache pipelineCache, size_t* pDataSize, void* pData );
    alias PFN_vkMergePipelineCaches                                             = VkResult  function( VkDevice device, VkPipelineCache dstCache, uint32_t srcCacheCount, const( VkPipelineCache )* pSrcCaches );
    alias PFN_vkCreateGraphicsPipelines                                         = VkResult  function( VkDevice device, VkPipelineCache pipelineCache, uint32_t createInfoCount, const( VkGraphicsPipelineCreateInfo )* pCreateInfos, const( VkAllocationCallbacks )* pAllocator, VkPipeline* pPipelines );
    alias PFN_vkCreateComputePipelines                                          = VkResult  function( VkDevice device, VkPipelineCache pipelineCache, uint32_t createInfoCount, const( VkComputePipelineCreateInfo )* pCreateInfos, const( VkAllocationCallbacks )* pAllocator, VkPipeline* pPipelines );
    alias PFN_vkDestroyPipeline                                                 = void      function( VkDevice device, VkPipeline pipeline, const( VkAllocationCallbacks )* pAllocator );
    alias PFN_vkCreatePipelineLayout                                            = VkResult  function( VkDevice device, const( VkPipelineLayoutCreateInfo )* pCreateInfo, const( VkAllocationCallbacks )* pAllocator, VkPipelineLayout* pPipelineLayout );
    alias PFN_vkDestroyPipelineLayout                                           = void      function( VkDevice device, VkPipelineLayout pipelineLayout, const( VkAllocationCallbacks )* pAllocator );
    alias PFN_vkCreateSampler                                                   = VkResult  function( VkDevice device, const( VkSamplerCreateInfo )* pCreateInfo, const( VkAllocationCallbacks )* pAllocator, VkSampler* pSampler );
    alias PFN_vkDestroySampler                                                  = void      function( VkDevice device, VkSampler sampler, const( VkAllocationCallbacks )* pAllocator );
    alias PFN_vkCreateDescriptorSetLayout                                       = VkResult  function( VkDevice device, const( VkDescriptorSetLayoutCreateInfo )* pCreateInfo, const( VkAllocationCallbacks )* pAllocator, VkDescriptorSetLayout* pSetLayout );
    alias PFN_vkDestroyDescriptorSetLayout                                      = void      function( VkDevice device, VkDescriptorSetLayout descriptorSetLayout, const( VkAllocationCallbacks )* pAllocator );
    alias PFN_vkCreateDescriptorPool                                            = VkResult  function( VkDevice device, const( VkDescriptorPoolCreateInfo )* pCreateInfo, const( VkAllocationCallbacks )* pAllocator, VkDescriptorPool* pDescriptorPool );
    alias PFN_vkDestroyDescriptorPool                                           = void      function( VkDevice device, VkDescriptorPool descriptorPool, const( VkAllocationCallbacks )* pAllocator );
    alias PFN_vkResetDescriptorPool                                             = VkResult  function( VkDevice device, VkDescriptorPool descriptorPool, VkDescriptorPoolResetFlags flags );
    alias PFN_vkAllocateDescriptorSets                                          = VkResult  function( VkDevice device, const( VkDescriptorSetAllocateInfo )* pAllocateInfo, VkDescriptorSet* pDescriptorSets );
    alias PFN_vkFreeDescriptorSets                                              = VkResult  function( VkDevice device, VkDescriptorPool descriptorPool, uint32_t descriptorSetCount, const( VkDescriptorSet )* pDescriptorSets );
    alias PFN_vkUpdateDescriptorSets                                            = void      function( VkDevice device, uint32_t descriptorWriteCount, const( VkWriteDescriptorSet )* pDescriptorWrites, uint32_t descriptorCopyCount, const( VkCopyDescriptorSet )* pDescriptorCopies );
    alias PFN_vkCreateFramebuffer                                               = VkResult  function( VkDevice device, const( VkFramebufferCreateInfo )* pCreateInfo, const( VkAllocationCallbacks )* pAllocator, VkFramebuffer* pFramebuffer );
    alias PFN_vkDestroyFramebuffer                                              = void      function( VkDevice device, VkFramebuffer framebuffer, const( VkAllocationCallbacks )* pAllocator );
    alias PFN_vkCreateRenderPass                                                = VkResult  function( VkDevice device, const( VkRenderPassCreateInfo )* pCreateInfo, const( VkAllocationCallbacks )* pAllocator, VkRenderPass* pRenderPass );
    alias PFN_vkDestroyRenderPass                                               = void      function( VkDevice device, VkRenderPass renderPass, const( VkAllocationCallbacks )* pAllocator );
    alias PFN_vkGetRenderAreaGranularity                                        = void      function( VkDevice device, VkRenderPass renderPass, VkExtent2D* pGranularity );
    alias PFN_vkCreateCommandPool                                               = VkResult  function( VkDevice device, const( VkCommandPoolCreateInfo )* pCreateInfo, const( VkAllocationCallbacks )* pAllocator, VkCommandPool* pCommandPool );
    alias PFN_vkDestroyCommandPool                                              = void      function( VkDevice device, VkCommandPool commandPool, const( VkAllocationCallbacks )* pAllocator );
    alias PFN_vkResetCommandPool                                                = VkResult  function( VkDevice device, VkCommandPool commandPool, VkCommandPoolResetFlags flags );
    alias PFN_vkAllocateCommandBuffers                                          = VkResult  function( VkDevice device, const( VkCommandBufferAllocateInfo )* pAllocateInfo, VkCommandBuffer* pCommandBuffers );
    alias PFN_vkFreeCommandBuffers                                              = void      function( VkDevice device, VkCommandPool commandPool, uint32_t commandBufferCount, const( VkCommandBuffer )* pCommandBuffers );
    alias PFN_vkBeginCommandBuffer                                              = VkResult  function( VkCommandBuffer commandBuffer, const( VkCommandBufferBeginInfo )* pBeginInfo );
    alias PFN_vkEndCommandBuffer                                                = VkResult  function( VkCommandBuffer commandBuffer );
    alias PFN_vkResetCommandBuffer                                              = VkResult  function( VkCommandBuffer commandBuffer, VkCommandBufferResetFlags flags );
    alias PFN_vkCmdBindPipeline                                                 = void      function( VkCommandBuffer commandBuffer, VkPipelineBindPoint pipelineBindPoint, VkPipeline pipeline );
    alias PFN_vkCmdSetViewport                                                  = void      function( VkCommandBuffer commandBuffer, uint32_t firstViewport, uint32_t viewportCount, const( VkViewport )* pViewports );
    alias PFN_vkCmdSetScissor                                                   = void      function( VkCommandBuffer commandBuffer, uint32_t firstScissor, uint32_t scissorCount, const( VkRect2D )* pScissors );
    alias PFN_vkCmdSetLineWidth                                                 = void      function( VkCommandBuffer commandBuffer, float lineWidth );
    alias PFN_vkCmdSetDepthBias                                                 = void      function( VkCommandBuffer commandBuffer, float depthBiasConstantFactor, float depthBiasClamp, float depthBiasSlopeFactor );
    alias PFN_vkCmdSetBlendConstants                                            = void      function( VkCommandBuffer commandBuffer, const float[4] blendConstants );
    alias PFN_vkCmdSetDepthBounds                                               = void      function( VkCommandBuffer commandBuffer, float minDepthBounds, float maxDepthBounds );
    alias PFN_vkCmdSetStencilCompareMask                                        = void      function( VkCommandBuffer commandBuffer, VkStencilFaceFlags faceMask, uint32_t compareMask );
    alias PFN_vkCmdSetStencilWriteMask                                          = void      function( VkCommandBuffer commandBuffer, VkStencilFaceFlags faceMask, uint32_t writeMask );
    alias PFN_vkCmdSetStencilReference                                          = void      function( VkCommandBuffer commandBuffer, VkStencilFaceFlags faceMask, uint32_t reference );
    alias PFN_vkCmdBindDescriptorSets                                           = void      function( VkCommandBuffer commandBuffer, VkPipelineBindPoint pipelineBindPoint, VkPipelineLayout layout, uint32_t firstSet, uint32_t descriptorSetCount, const( VkDescriptorSet )* pDescriptorSets, uint32_t dynamicOffsetCount, const( uint32_t )* pDynamicOffsets );
    alias PFN_vkCmdBindIndexBuffer                                              = void      function( VkCommandBuffer commandBuffer, VkBuffer buffer, VkDeviceSize offset, VkIndexType indexType );
    alias PFN_vkCmdBindVertexBuffers                                            = void      function( VkCommandBuffer commandBuffer, uint32_t firstBinding, uint32_t bindingCount, const( VkBuffer )* pBuffers, const( VkDeviceSize )* pOffsets );
    alias PFN_vkCmdDraw                                                         = void      function( VkCommandBuffer commandBuffer, uint32_t vertexCount, uint32_t instanceCount, uint32_t firstVertex, uint32_t firstInstance );
    alias PFN_vkCmdDrawIndexed                                                  = void      function( VkCommandBuffer commandBuffer, uint32_t indexCount, uint32_t instanceCount, uint32_t firstIndex, int32_t vertexOffset, uint32_t firstInstance );
    alias PFN_vkCmdDrawIndirect                                                 = void      function( VkCommandBuffer commandBuffer, VkBuffer buffer, VkDeviceSize offset, uint32_t drawCount, uint32_t stride );
    alias PFN_vkCmdDrawIndexedIndirect                                          = void      function( VkCommandBuffer commandBuffer, VkBuffer buffer, VkDeviceSize offset, uint32_t drawCount, uint32_t stride );
    alias PFN_vkCmdDispatch                                                     = void      function( VkCommandBuffer commandBuffer, uint32_t groupCountX, uint32_t groupCountY, uint32_t groupCountZ );
    alias PFN_vkCmdDispatchIndirect                                             = void      function( VkCommandBuffer commandBuffer, VkBuffer buffer, VkDeviceSize offset );
    alias PFN_vkCmdCopyBuffer                                                   = void      function( VkCommandBuffer commandBuffer, VkBuffer srcBuffer, VkBuffer dstBuffer, uint32_t regionCount, const( VkBufferCopy )* pRegions );
    alias PFN_vkCmdCopyImage                                                    = void      function( VkCommandBuffer commandBuffer, VkImage srcImage, VkImageLayout srcImageLayout, VkImage dstImage, VkImageLayout dstImageLayout, uint32_t regionCount, const( VkImageCopy )* pRegions );
    alias PFN_vkCmdBlitImage                                                    = void      function( VkCommandBuffer commandBuffer, VkImage srcImage, VkImageLayout srcImageLayout, VkImage dstImage, VkImageLayout dstImageLayout, uint32_t regionCount, const( VkImageBlit )* pRegions, VkFilter filter );
    alias PFN_vkCmdCopyBufferToImage                                            = void      function( VkCommandBuffer commandBuffer, VkBuffer srcBuffer, VkImage dstImage, VkImageLayout dstImageLayout, uint32_t regionCount, const( VkBufferImageCopy )* pRegions );
    alias PFN_vkCmdCopyImageToBuffer                                            = void      function( VkCommandBuffer commandBuffer, VkImage srcImage, VkImageLayout srcImageLayout, VkBuffer dstBuffer, uint32_t regionCount, const( VkBufferImageCopy )* pRegions );
    alias PFN_vkCmdUpdateBuffer                                                 = void      function( VkCommandBuffer commandBuffer, VkBuffer dstBuffer, VkDeviceSize dstOffset, VkDeviceSize dataSize, const( void )* pData );
    alias PFN_vkCmdFillBuffer                                                   = void      function( VkCommandBuffer commandBuffer, VkBuffer dstBuffer, VkDeviceSize dstOffset, VkDeviceSize size, uint32_t data );
    alias PFN_vkCmdClearColorImage                                              = void      function( VkCommandBuffer commandBuffer, VkImage image, VkImageLayout imageLayout, const( VkClearColorValue )* pColor, uint32_t rangeCount, const( VkImageSubresourceRange )* pRanges );
    alias PFN_vkCmdClearDepthStencilImage                                       = void      function( VkCommandBuffer commandBuffer, VkImage image, VkImageLayout imageLayout, const( VkClearDepthStencilValue )* pDepthStencil, uint32_t rangeCount, const( VkImageSubresourceRange )* pRanges );
    alias PFN_vkCmdClearAttachments                                             = void      function( VkCommandBuffer commandBuffer, uint32_t attachmentCount, const( VkClearAttachment )* pAttachments, uint32_t rectCount, const( VkClearRect )* pRects );
    alias PFN_vkCmdResolveImage                                                 = void      function( VkCommandBuffer commandBuffer, VkImage srcImage, VkImageLayout srcImageLayout, VkImage dstImage, VkImageLayout dstImageLayout, uint32_t regionCount, const( VkImageResolve )* pRegions );
    alias PFN_vkCmdSetEvent                                                     = void      function( VkCommandBuffer commandBuffer, VkEvent event, VkPipelineStageFlags stageMask );
    alias PFN_vkCmdResetEvent                                                   = void      function( VkCommandBuffer commandBuffer, VkEvent event, VkPipelineStageFlags stageMask );
    alias PFN_vkCmdWaitEvents                                                   = void      function( VkCommandBuffer commandBuffer, uint32_t eventCount, const( VkEvent )* pEvents, VkPipelineStageFlags srcStageMask, VkPipelineStageFlags dstStageMask, uint32_t memoryBarrierCount, const( VkMemoryBarrier )* pMemoryBarriers, uint32_t bufferMemoryBarrierCount, const( VkBufferMemoryBarrier )* pBufferMemoryBarriers, uint32_t imageMemoryBarrierCount, const( VkImageMemoryBarrier )* pImageMemoryBarriers );
    alias PFN_vkCmdPipelineBarrier                                              = void      function( VkCommandBuffer commandBuffer, VkPipelineStageFlags srcStageMask, VkPipelineStageFlags dstStageMask, VkDependencyFlags dependencyFlags, uint32_t memoryBarrierCount, const( VkMemoryBarrier )* pMemoryBarriers, uint32_t bufferMemoryBarrierCount, const( VkBufferMemoryBarrier )* pBufferMemoryBarriers, uint32_t imageMemoryBarrierCount, const( VkImageMemoryBarrier )* pImageMemoryBarriers );
    alias PFN_vkCmdBeginQuery                                                   = void      function( VkCommandBuffer commandBuffer, VkQueryPool queryPool, uint32_t query, VkQueryControlFlags flags );
    alias PFN_vkCmdEndQuery                                                     = void      function( VkCommandBuffer commandBuffer, VkQueryPool queryPool, uint32_t query );
    alias PFN_vkCmdResetQueryPool                                               = void      function( VkCommandBuffer commandBuffer, VkQueryPool queryPool, uint32_t firstQuery, uint32_t queryCount );
    alias PFN_vkCmdWriteTimestamp                                               = void      function( VkCommandBuffer commandBuffer, VkPipelineStageFlagBits pipelineStage, VkQueryPool queryPool, uint32_t query );
    alias PFN_vkCmdCopyQueryPoolResults                                         = void      function( VkCommandBuffer commandBuffer, VkQueryPool queryPool, uint32_t firstQuery, uint32_t queryCount, VkBuffer dstBuffer, VkDeviceSize dstOffset, VkDeviceSize stride, VkQueryResultFlags flags );
    alias PFN_vkCmdPushConstants                                                = void      function( VkCommandBuffer commandBuffer, VkPipelineLayout layout, VkShaderStageFlags stageFlags, uint32_t offset, uint32_t size, const( void )* pValues );
    alias PFN_vkCmdBeginRenderPass                                              = void      function( VkCommandBuffer commandBuffer, const( VkRenderPassBeginInfo )* pRenderPassBegin, VkSubpassContents contents );
    alias PFN_vkCmdNextSubpass                                                  = void      function( VkCommandBuffer commandBuffer, VkSubpassContents contents );
    alias PFN_vkCmdEndRenderPass                                                = void      function( VkCommandBuffer commandBuffer );
    alias PFN_vkCmdExecuteCommands                                              = void      function( VkCommandBuffer commandBuffer, uint32_t commandBufferCount, const( VkCommandBuffer )* pCommandBuffers );

    // VK_VERSION_1_1
    alias PFN_vkEnumerateInstanceVersion                                        = VkResult  function( uint32_t* pApiVersion );
    alias PFN_vkBindBufferMemory2                                               = VkResult  function( VkDevice device, uint32_t bindInfoCount, const( VkBindBufferMemoryInfo )* pBindInfos );
    alias PFN_vkBindImageMemory2                                                = VkResult  function( VkDevice device, uint32_t bindInfoCount, const( VkBindImageMemoryInfo )* pBindInfos );
    alias PFN_vkGetDeviceGroupPeerMemoryFeatures                                = void      function( VkDevice device, uint32_t heapIndex, uint32_t localDeviceIndex, uint32_t remoteDeviceIndex, VkPeerMemoryFeatureFlags* pPeerMemoryFeatures );
    alias PFN_vkCmdSetDeviceMask                                                = void      function( VkCommandBuffer commandBuffer, uint32_t deviceMask );
    alias PFN_vkCmdDispatchBase                                                 = void      function( VkCommandBuffer commandBuffer, uint32_t baseGroupX, uint32_t baseGroupY, uint32_t baseGroupZ, uint32_t groupCountX, uint32_t groupCountY, uint32_t groupCountZ );
    alias PFN_vkEnumeratePhysicalDeviceGroups                                   = VkResult  function( VkInstance instance, uint32_t* pPhysicalDeviceGroupCount, VkPhysicalDeviceGroupProperties* pPhysicalDeviceGroupProperties );
    alias PFN_vkGetImageMemoryRequirements2                                     = void      function( VkDevice device, const( VkImageMemoryRequirementsInfo2 )* pInfo, VkMemoryRequirements2* pMemoryRequirements );
    alias PFN_vkGetBufferMemoryRequirements2                                    = void      function( VkDevice device, const( VkBufferMemoryRequirementsInfo2 )* pInfo, VkMemoryRequirements2* pMemoryRequirements );
    alias PFN_vkGetImageSparseMemoryRequirements2                               = void      function( VkDevice device, const( VkImageSparseMemoryRequirementsInfo2 )* pInfo, uint32_t* pSparseMemoryRequirementCount, VkSparseImageMemoryRequirements2* pSparseMemoryRequirements );
    alias PFN_vkGetPhysicalDeviceFeatures2                                      = void      function( VkPhysicalDevice physicalDevice, VkPhysicalDeviceFeatures2* pFeatures );
    alias PFN_vkGetPhysicalDeviceProperties2                                    = void      function( VkPhysicalDevice physicalDevice, VkPhysicalDeviceProperties2* pProperties );
    alias PFN_vkGetPhysicalDeviceFormatProperties2                              = void      function( VkPhysicalDevice physicalDevice, VkFormat format, VkFormatProperties2* pFormatProperties );
    alias PFN_vkGetPhysicalDeviceImageFormatProperties2                         = VkResult  function( VkPhysicalDevice physicalDevice, const( VkPhysicalDeviceImageFormatInfo2 )* pImageFormatInfo, VkImageFormatProperties2* pImageFormatProperties );
    alias PFN_vkGetPhysicalDeviceQueueFamilyProperties2                         = void      function( VkPhysicalDevice physicalDevice, uint32_t* pQueueFamilyPropertyCount, VkQueueFamilyProperties2* pQueueFamilyProperties );
    alias PFN_vkGetPhysicalDeviceMemoryProperties2                              = void      function( VkPhysicalDevice physicalDevice, VkPhysicalDeviceMemoryProperties2* pMemoryProperties );
    alias PFN_vkGetPhysicalDeviceSparseImageFormatProperties2                   = void      function( VkPhysicalDevice physicalDevice, const( VkPhysicalDeviceSparseImageFormatInfo2 )* pFormatInfo, uint32_t* pPropertyCount, VkSparseImageFormatProperties2* pProperties );
    alias PFN_vkTrimCommandPool                                                 = void      function( VkDevice device, VkCommandPool commandPool, VkCommandPoolTrimFlags flags );
    alias PFN_vkGetDeviceQueue2                                                 = void      function( VkDevice device, const( VkDeviceQueueInfo2 )* pQueueInfo, VkQueue* pQueue );
    alias PFN_vkCreateSamplerYcbcrConversion                                    = VkResult  function( VkDevice device, const( VkSamplerYcbcrConversionCreateInfo )* pCreateInfo, const( VkAllocationCallbacks )* pAllocator, VkSamplerYcbcrConversion* pYcbcrConversion );
    alias PFN_vkDestroySamplerYcbcrConversion                                   = void      function( VkDevice device, VkSamplerYcbcrConversion ycbcrConversion, const( VkAllocationCallbacks )* pAllocator );
    alias PFN_vkCreateDescriptorUpdateTemplate                                  = VkResult  function( VkDevice device, const( VkDescriptorUpdateTemplateCreateInfo )* pCreateInfo, const( VkAllocationCallbacks )* pAllocator, VkDescriptorUpdateTemplate* pDescriptorUpdateTemplate );
    alias PFN_vkDestroyDescriptorUpdateTemplate                                 = void      function( VkDevice device, VkDescriptorUpdateTemplate descriptorUpdateTemplate, const( VkAllocationCallbacks )* pAllocator );
    alias PFN_vkUpdateDescriptorSetWithTemplate                                 = void      function( VkDevice device, VkDescriptorSet descriptorSet, VkDescriptorUpdateTemplate descriptorUpdateTemplate, const( void )* pData );
    alias PFN_vkGetPhysicalDeviceExternalBufferProperties                       = void      function( VkPhysicalDevice physicalDevice, const( VkPhysicalDeviceExternalBufferInfo )* pExternalBufferInfo, VkExternalBufferProperties* pExternalBufferProperties );
    alias PFN_vkGetPhysicalDeviceExternalFenceProperties                        = void      function( VkPhysicalDevice physicalDevice, const( VkPhysicalDeviceExternalFenceInfo )* pExternalFenceInfo, VkExternalFenceProperties* pExternalFenceProperties );
    alias PFN_vkGetPhysicalDeviceExternalSemaphoreProperties                    = void      function( VkPhysicalDevice physicalDevice, const( VkPhysicalDeviceExternalSemaphoreInfo )* pExternalSemaphoreInfo, VkExternalSemaphoreProperties* pExternalSemaphoreProperties );
    alias PFN_vkGetDescriptorSetLayoutSupport                                   = void      function( VkDevice device, const( VkDescriptorSetLayoutCreateInfo )* pCreateInfo, VkDescriptorSetLayoutSupport* pSupport );

    // VK_VERSION_1_2
    alias PFN_vkCmdDrawIndirectCount                                            = void      function( VkCommandBuffer commandBuffer, VkBuffer buffer, VkDeviceSize offset, VkBuffer countBuffer, VkDeviceSize countBufferOffset, uint32_t maxDrawCount, uint32_t stride );
    alias PFN_vkCmdDrawIndexedIndirectCount                                     = void      function( VkCommandBuffer commandBuffer, VkBuffer buffer, VkDeviceSize offset, VkBuffer countBuffer, VkDeviceSize countBufferOffset, uint32_t maxDrawCount, uint32_t stride );
    alias PFN_vkCreateRenderPass2                                               = VkResult  function( VkDevice device, const( VkRenderPassCreateInfo2 )* pCreateInfo, const( VkAllocationCallbacks )* pAllocator, VkRenderPass* pRenderPass );
    alias PFN_vkCmdBeginRenderPass2                                             = void      function( VkCommandBuffer commandBuffer, const( VkRenderPassBeginInfo )* pRenderPassBegin, const( VkSubpassBeginInfo )* pSubpassBeginInfo );
    alias PFN_vkCmdNextSubpass2                                                 = void      function( VkCommandBuffer commandBuffer, const( VkSubpassBeginInfo )* pSubpassBeginInfo, const( VkSubpassEndInfo )* pSubpassEndInfo );
    alias PFN_vkCmdEndRenderPass2                                               = void      function( VkCommandBuffer commandBuffer, const( VkSubpassEndInfo )* pSubpassEndInfo );
    alias PFN_vkResetQueryPool                                                  = void      function( VkDevice device, VkQueryPool queryPool, uint32_t firstQuery, uint32_t queryCount );
    alias PFN_vkGetSemaphoreCounterValue                                        = VkResult  function( VkDevice device, VkSemaphore semaphore, uint64_t* pValue );
    alias PFN_vkWaitSemaphores                                                  = VkResult  function( VkDevice device, const( VkSemaphoreWaitInfo )* pWaitInfo, uint64_t timeout );
    alias PFN_vkSignalSemaphore                                                 = VkResult  function( VkDevice device, const( VkSemaphoreSignalInfo )* pSignalInfo );
    alias PFN_vkGetBufferDeviceAddress                                          = VkDeviceAddress  function( VkDevice device, const( VkBufferDeviceAddressInfo )* pInfo );
    alias PFN_vkGetBufferOpaqueCaptureAddress                                   = uint64_t  function( VkDevice device, const( VkBufferDeviceAddressInfo )* pInfo );
    alias PFN_vkGetDeviceMemoryOpaqueCaptureAddress                             = uint64_t  function( VkDevice device, const( VkDeviceMemoryOpaqueCaptureAddressInfo )* pInfo );

    // VK_VERSION_1_3
    alias PFN_vkGetPhysicalDeviceToolProperties                                 = VkResult  function( VkPhysicalDevice physicalDevice, uint32_t* pToolCount, VkPhysicalDeviceToolProperties* pToolProperties );
    alias PFN_vkCreatePrivateDataSlot                                           = VkResult  function( VkDevice device, const( VkPrivateDataSlotCreateInfo )* pCreateInfo, const( VkAllocationCallbacks )* pAllocator, VkPrivateDataSlot* pPrivateDataSlot );
    alias PFN_vkDestroyPrivateDataSlot                                          = void      function( VkDevice device, VkPrivateDataSlot privateDataSlot, const( VkAllocationCallbacks )* pAllocator );
    alias PFN_vkSetPrivateData                                                  = VkResult  function( VkDevice device, VkObjectType objectType, uint64_t objectHandle, VkPrivateDataSlot privateDataSlot, uint64_t data );
    alias PFN_vkGetPrivateData                                                  = void      function( VkDevice device, VkObjectType objectType, uint64_t objectHandle, VkPrivateDataSlot privateDataSlot, uint64_t* pData );
    alias PFN_vkCmdSetEvent2                                                    = void      function( VkCommandBuffer commandBuffer, VkEvent event, const( VkDependencyInfo )* pDependencyInfo );
    alias PFN_vkCmdResetEvent2                                                  = void      function( VkCommandBuffer commandBuffer, VkEvent event, VkPipelineStageFlags2 stageMask );
    alias PFN_vkCmdWaitEvents2                                                  = void      function( VkCommandBuffer commandBuffer, uint32_t eventCount, const( VkEvent )* pEvents, const( VkDependencyInfo )* pDependencyInfos );
    alias PFN_vkCmdPipelineBarrier2                                             = void      function( VkCommandBuffer commandBuffer, const( VkDependencyInfo )* pDependencyInfo );
    alias PFN_vkCmdWriteTimestamp2                                              = void      function( VkCommandBuffer commandBuffer, VkPipelineStageFlags2 stage, VkQueryPool queryPool, uint32_t query );
    alias PFN_vkQueueSubmit2                                                    = VkResult  function( VkQueue queue, uint32_t submitCount, const( VkSubmitInfo2 )* pSubmits, VkFence fence );
    alias PFN_vkCmdCopyBuffer2                                                  = void      function( VkCommandBuffer commandBuffer, const( VkCopyBufferInfo2 )* pCopyBufferInfo );
    alias PFN_vkCmdCopyImage2                                                   = void      function( VkCommandBuffer commandBuffer, const( VkCopyImageInfo2 )* pCopyImageInfo );
    alias PFN_vkCmdCopyBufferToImage2                                           = void      function( VkCommandBuffer commandBuffer, const( VkCopyBufferToImageInfo2 )* pCopyBufferToImageInfo );
    alias PFN_vkCmdCopyImageToBuffer2                                           = void      function( VkCommandBuffer commandBuffer, const( VkCopyImageToBufferInfo2 )* pCopyImageToBufferInfo );
    alias PFN_vkCmdBlitImage2                                                   = void      function( VkCommandBuffer commandBuffer, const( VkBlitImageInfo2 )* pBlitImageInfo );
    alias PFN_vkCmdResolveImage2                                                = void      function( VkCommandBuffer commandBuffer, const( VkResolveImageInfo2 )* pResolveImageInfo );
    alias PFN_vkCmdBeginRendering                                               = void      function( VkCommandBuffer commandBuffer, const( VkRenderingInfo )* pRenderingInfo );
    alias PFN_vkCmdEndRendering                                                 = void      function( VkCommandBuffer commandBuffer );
    alias PFN_vkCmdSetCullMode                                                  = void      function( VkCommandBuffer commandBuffer, VkCullModeFlags cullMode );
    alias PFN_vkCmdSetFrontFace                                                 = void      function( VkCommandBuffer commandBuffer, VkFrontFace frontFace );
    alias PFN_vkCmdSetPrimitiveTopology                                         = void      function( VkCommandBuffer commandBuffer, VkPrimitiveTopology primitiveTopology );
    alias PFN_vkCmdSetViewportWithCount                                         = void      function( VkCommandBuffer commandBuffer, uint32_t viewportCount, const( VkViewport )* pViewports );
    alias PFN_vkCmdSetScissorWithCount                                          = void      function( VkCommandBuffer commandBuffer, uint32_t scissorCount, const( VkRect2D )* pScissors );
    alias PFN_vkCmdBindVertexBuffers2                                           = void      function( VkCommandBuffer commandBuffer, uint32_t firstBinding, uint32_t bindingCount, const( VkBuffer )* pBuffers, const( VkDeviceSize )* pOffsets, const( VkDeviceSize )* pSizes, const( VkDeviceSize )* pStrides );
    alias PFN_vkCmdSetDepthTestEnable                                           = void      function( VkCommandBuffer commandBuffer, VkBool32 depthTestEnable );
    alias PFN_vkCmdSetDepthWriteEnable                                          = void      function( VkCommandBuffer commandBuffer, VkBool32 depthWriteEnable );
    alias PFN_vkCmdSetDepthCompareOp                                            = void      function( VkCommandBuffer commandBuffer, VkCompareOp depthCompareOp );
    alias PFN_vkCmdSetDepthBoundsTestEnable                                     = void      function( VkCommandBuffer commandBuffer, VkBool32 depthBoundsTestEnable );
    alias PFN_vkCmdSetStencilTestEnable                                         = void      function( VkCommandBuffer commandBuffer, VkBool32 stencilTestEnable );
    alias PFN_vkCmdSetStencilOp                                                 = void      function( VkCommandBuffer commandBuffer, VkStencilFaceFlags faceMask, VkStencilOp failOp, VkStencilOp passOp, VkStencilOp depthFailOp, VkCompareOp compareOp );
    alias PFN_vkCmdSetRasterizerDiscardEnable                                   = void      function( VkCommandBuffer commandBuffer, VkBool32 rasterizerDiscardEnable );
    alias PFN_vkCmdSetDepthBiasEnable                                           = void      function( VkCommandBuffer commandBuffer, VkBool32 depthBiasEnable );
    alias PFN_vkCmdSetPrimitiveRestartEnable                                    = void      function( VkCommandBuffer commandBuffer, VkBool32 primitiveRestartEnable );
    alias PFN_vkGetDeviceBufferMemoryRequirements                               = void      function( VkDevice device, const( VkDeviceBufferMemoryRequirements )* pInfo, VkMemoryRequirements2* pMemoryRequirements );
    alias PFN_vkGetDeviceImageMemoryRequirements                                = void      function( VkDevice device, const( VkDeviceImageMemoryRequirements )* pInfo, VkMemoryRequirements2* pMemoryRequirements );
    alias PFN_vkGetDeviceImageSparseMemoryRequirements                          = void      function( VkDevice device, const( VkDeviceImageMemoryRequirements )* pInfo, uint32_t* pSparseMemoryRequirementCount, VkSparseImageMemoryRequirements2* pSparseMemoryRequirements );

    // VK_KHR_surface
    alias PFN_vkDestroySurfaceKHR                                               = void      function( VkInstance instance, VkSurfaceKHR surface, const( VkAllocationCallbacks )* pAllocator );
    alias PFN_vkGetPhysicalDeviceSurfaceSupportKHR                              = VkResult  function( VkPhysicalDevice physicalDevice, uint32_t queueFamilyIndex, VkSurfaceKHR surface, VkBool32* pSupported );
    alias PFN_vkGetPhysicalDeviceSurfaceCapabilitiesKHR                         = VkResult  function( VkPhysicalDevice physicalDevice, VkSurfaceKHR surface, VkSurfaceCapabilitiesKHR* pSurfaceCapabilities );
    alias PFN_vkGetPhysicalDeviceSurfaceFormatsKHR                              = VkResult  function( VkPhysicalDevice physicalDevice, VkSurfaceKHR surface, uint32_t* pSurfaceFormatCount, VkSurfaceFormatKHR* pSurfaceFormats );
    alias PFN_vkGetPhysicalDeviceSurfacePresentModesKHR                         = VkResult  function( VkPhysicalDevice physicalDevice, VkSurfaceKHR surface, uint32_t* pPresentModeCount, VkPresentModeKHR* pPresentModes );

    // VK_KHR_swapchain
    alias PFN_vkCreateSwapchainKHR                                              = VkResult  function( VkDevice device, const( VkSwapchainCreateInfoKHR )* pCreateInfo, const( VkAllocationCallbacks )* pAllocator, VkSwapchainKHR* pSwapchain );
    alias PFN_vkDestroySwapchainKHR                                             = void      function( VkDevice device, VkSwapchainKHR swapchain, const( VkAllocationCallbacks )* pAllocator );
    alias PFN_vkGetSwapchainImagesKHR                                           = VkResult  function( VkDevice device, VkSwapchainKHR swapchain, uint32_t* pSwapchainImageCount, VkImage* pSwapchainImages );
    alias PFN_vkAcquireNextImageKHR                                             = VkResult  function( VkDevice device, VkSwapchainKHR swapchain, uint64_t timeout, VkSemaphore semaphore, VkFence fence, uint32_t* pImageIndex );
    alias PFN_vkQueuePresentKHR                                                 = VkResult  function( VkQueue queue, const( VkPresentInfoKHR )* pPresentInfo );
    alias PFN_vkGetDeviceGroupPresentCapabilitiesKHR                            = VkResult  function( VkDevice device, VkDeviceGroupPresentCapabilitiesKHR* pDeviceGroupPresentCapabilities );
    alias PFN_vkGetDeviceGroupSurfacePresentModesKHR                            = VkResult  function( VkDevice device, VkSurfaceKHR surface, VkDeviceGroupPresentModeFlagsKHR* pModes );
    alias PFN_vkGetPhysicalDevicePresentRectanglesKHR                           = VkResult  function( VkPhysicalDevice physicalDevice, VkSurfaceKHR surface, uint32_t* pRectCount, VkRect2D* pRects );
    alias PFN_vkAcquireNextImage2KHR                                            = VkResult  function( VkDevice device, const( VkAcquireNextImageInfoKHR )* pAcquireInfo, uint32_t* pImageIndex );

    // VK_KHR_display
    alias PFN_vkGetPhysicalDeviceDisplayPropertiesKHR                           = VkResult  function( VkPhysicalDevice physicalDevice, uint32_t* pPropertyCount, VkDisplayPropertiesKHR* pProperties );
    alias PFN_vkGetPhysicalDeviceDisplayPlanePropertiesKHR                      = VkResult  function( VkPhysicalDevice physicalDevice, uint32_t* pPropertyCount, VkDisplayPlanePropertiesKHR* pProperties );
    alias PFN_vkGetDisplayPlaneSupportedDisplaysKHR                             = VkResult  function( VkPhysicalDevice physicalDevice, uint32_t planeIndex, uint32_t* pDisplayCount, VkDisplayKHR* pDisplays );
    alias PFN_vkGetDisplayModePropertiesKHR                                     = VkResult  function( VkPhysicalDevice physicalDevice, VkDisplayKHR display, uint32_t* pPropertyCount, VkDisplayModePropertiesKHR* pProperties );
    alias PFN_vkCreateDisplayModeKHR                                            = VkResult  function( VkPhysicalDevice physicalDevice, VkDisplayKHR display, const( VkDisplayModeCreateInfoKHR )* pCreateInfo, const( VkAllocationCallbacks )* pAllocator, VkDisplayModeKHR* pMode );
    alias PFN_vkGetDisplayPlaneCapabilitiesKHR                                  = VkResult  function( VkPhysicalDevice physicalDevice, VkDisplayModeKHR mode, uint32_t planeIndex, VkDisplayPlaneCapabilitiesKHR* pCapabilities );
    alias PFN_vkCreateDisplayPlaneSurfaceKHR                                    = VkResult  function( VkInstance instance, const( VkDisplaySurfaceCreateInfoKHR )* pCreateInfo, const( VkAllocationCallbacks )* pAllocator, VkSurfaceKHR* pSurface );

    // VK_KHR_display_swapchain
    alias PFN_vkCreateSharedSwapchainsKHR                                       = VkResult  function( VkDevice device, uint32_t swapchainCount, const( VkSwapchainCreateInfoKHR )* pCreateInfos, const( VkAllocationCallbacks )* pAllocator, VkSwapchainKHR* pSwapchains );

    // VK_KHR_external_memory_fd
    alias PFN_vkGetMemoryFdKHR                                                  = VkResult  function( VkDevice device, const( VkMemoryGetFdInfoKHR )* pGetFdInfo, int* pFd );
    alias PFN_vkGetMemoryFdPropertiesKHR                                        = VkResult  function( VkDevice device, VkExternalMemoryHandleTypeFlagBits handleType, int fd, VkMemoryFdPropertiesKHR* pMemoryFdProperties );

    // VK_KHR_external_semaphore_fd
    alias PFN_vkImportSemaphoreFdKHR                                            = VkResult  function( VkDevice device, const( VkImportSemaphoreFdInfoKHR )* pImportSemaphoreFdInfo );
    alias PFN_vkGetSemaphoreFdKHR                                               = VkResult  function( VkDevice device, const( VkSemaphoreGetFdInfoKHR )* pGetFdInfo, int* pFd );

    // VK_KHR_push_descriptor
    alias PFN_vkCmdPushDescriptorSetKHR                                         = void      function( VkCommandBuffer commandBuffer, VkPipelineBindPoint pipelineBindPoint, VkPipelineLayout layout, uint32_t set, uint32_t descriptorWriteCount, const( VkWriteDescriptorSet )* pDescriptorWrites );
    alias PFN_vkCmdPushDescriptorSetWithTemplateKHR                             = void      function( VkCommandBuffer commandBuffer, VkDescriptorUpdateTemplate descriptorUpdateTemplate, VkPipelineLayout layout, uint32_t set, const( void )* pData );

    // VK_KHR_shared_presentable_image
    alias PFN_vkGetSwapchainStatusKHR                                           = VkResult  function( VkDevice device, VkSwapchainKHR swapchain );

    // VK_KHR_external_fence_fd
    alias PFN_vkImportFenceFdKHR                                                = VkResult  function( VkDevice device, const( VkImportFenceFdInfoKHR )* pImportFenceFdInfo );
    alias PFN_vkGetFenceFdKHR                                                   = VkResult  function( VkDevice device, const( VkFenceGetFdInfoKHR )* pGetFdInfo, int* pFd );

    // VK_KHR_performance_query
    alias PFN_vkEnumeratePhysicalDeviceQueueFamilyPerformanceQueryCountersKHR   = VkResult  function( VkPhysicalDevice physicalDevice, uint32_t queueFamilyIndex, uint32_t* pCounterCount, VkPerformanceCounterKHR* pCounters, VkPerformanceCounterDescriptionKHR* pCounterDescriptions );
    alias PFN_vkGetPhysicalDeviceQueueFamilyPerformanceQueryPassesKHR           = void      function( VkPhysicalDevice physicalDevice, const( VkQueryPoolPerformanceCreateInfoKHR )* pPerformanceQueryCreateInfo, uint32_t* pNumPasses );
    alias PFN_vkAcquireProfilingLockKHR                                         = VkResult  function( VkDevice device, const( VkAcquireProfilingLockInfoKHR )* pInfo );
    alias PFN_vkReleaseProfilingLockKHR                                         = void      function( VkDevice device );

    // VK_KHR_get_surface_capabilities2
    alias PFN_vkGetPhysicalDeviceSurfaceCapabilities2KHR                        = VkResult  function( VkPhysicalDevice physicalDevice, const( VkPhysicalDeviceSurfaceInfo2KHR )* pSurfaceInfo, VkSurfaceCapabilities2KHR* pSurfaceCapabilities );
    alias PFN_vkGetPhysicalDeviceSurfaceFormats2KHR                             = VkResult  function( VkPhysicalDevice physicalDevice, const( VkPhysicalDeviceSurfaceInfo2KHR )* pSurfaceInfo, uint32_t* pSurfaceFormatCount, VkSurfaceFormat2KHR* pSurfaceFormats );

    // VK_KHR_get_display_properties2
    alias PFN_vkGetPhysicalDeviceDisplayProperties2KHR                          = VkResult  function( VkPhysicalDevice physicalDevice, uint32_t* pPropertyCount, VkDisplayProperties2KHR* pProperties );
    alias PFN_vkGetPhysicalDeviceDisplayPlaneProperties2KHR                     = VkResult  function( VkPhysicalDevice physicalDevice, uint32_t* pPropertyCount, VkDisplayPlaneProperties2KHR* pProperties );
    alias PFN_vkGetDisplayModeProperties2KHR                                    = VkResult  function( VkPhysicalDevice physicalDevice, VkDisplayKHR display, uint32_t* pPropertyCount, VkDisplayModeProperties2KHR* pProperties );
    alias PFN_vkGetDisplayPlaneCapabilities2KHR                                 = VkResult  function( VkPhysicalDevice physicalDevice, const( VkDisplayPlaneInfo2KHR )* pDisplayPlaneInfo, VkDisplayPlaneCapabilities2KHR* pCapabilities );

    // VK_KHR_fragment_shading_rate
    alias PFN_vkGetPhysicalDeviceFragmentShadingRatesKHR                        = VkResult  function( VkPhysicalDevice physicalDevice, uint32_t* pFragmentShadingRateCount, VkPhysicalDeviceFragmentShadingRateKHR* pFragmentShadingRates );
    alias PFN_vkCmdSetFragmentShadingRateKHR                                    = void      function( VkCommandBuffer commandBuffer, const( VkExtent2D )* pFragmentSize, const VkFragmentShadingRateCombinerOpKHR[2] combinerOps );

    // VK_KHR_present_wait
    alias PFN_vkWaitForPresentKHR                                               = VkResult  function( VkDevice device, VkSwapchainKHR swapchain, uint64_t presentId, uint64_t timeout );

    // VK_KHR_deferred_host_operations
    alias PFN_vkCreateDeferredOperationKHR                                      = VkResult  function( VkDevice device, const( VkAllocationCallbacks )* pAllocator, VkDeferredOperationKHR* pDeferredOperation );
    alias PFN_vkDestroyDeferredOperationKHR                                     = void      function( VkDevice device, VkDeferredOperationKHR operation, const( VkAllocationCallbacks )* pAllocator );
    alias PFN_vkGetDeferredOperationMaxConcurrencyKHR                           = uint32_t  function( VkDevice device, VkDeferredOperationKHR operation );
    alias PFN_vkGetDeferredOperationResultKHR                                   = VkResult  function( VkDevice device, VkDeferredOperationKHR operation );
    alias PFN_vkDeferredOperationJoinKHR                                        = VkResult  function( VkDevice device, VkDeferredOperationKHR operation );

    // VK_KHR_pipeline_executable_properties
    alias PFN_vkGetPipelineExecutablePropertiesKHR                              = VkResult  function( VkDevice device, const( VkPipelineInfoKHR )* pPipelineInfo, uint32_t* pExecutableCount, VkPipelineExecutablePropertiesKHR* pProperties );
    alias PFN_vkGetPipelineExecutableStatisticsKHR                              = VkResult  function( VkDevice device, const( VkPipelineExecutableInfoKHR )* pExecutableInfo, uint32_t* pStatisticCount, VkPipelineExecutableStatisticKHR* pStatistics );
    alias PFN_vkGetPipelineExecutableInternalRepresentationsKHR                 = VkResult  function( VkDevice device, const( VkPipelineExecutableInfoKHR )* pExecutableInfo, uint32_t* pInternalRepresentationCount, VkPipelineExecutableInternalRepresentationKHR* pInternalRepresentations );

    // VK_KHR_synchronization2
    alias PFN_vkCmdWriteBufferMarker2AMD                                        = void      function( VkCommandBuffer commandBuffer, VkPipelineStageFlags2 stage, VkBuffer dstBuffer, VkDeviceSize dstOffset, uint32_t marker );
    alias PFN_vkGetQueueCheckpointData2NV                                       = void      function( VkQueue queue, uint32_t* pCheckpointDataCount, VkCheckpointData2NV* pCheckpointData );

    // VK_KHR_ray_tracing_maintenance1
    alias PFN_vkCmdTraceRaysIndirect2KHR                                        = void      function( VkCommandBuffer commandBuffer, VkDeviceAddress indirectDeviceAddress );

    // VK_EXT_debug_report
    alias PFN_vkCreateDebugReportCallbackEXT                                    = VkResult  function( VkInstance instance, const( VkDebugReportCallbackCreateInfoEXT )* pCreateInfo, const( VkAllocationCallbacks )* pAllocator, VkDebugReportCallbackEXT* pCallback );
    alias PFN_vkDestroyDebugReportCallbackEXT                                   = void      function( VkInstance instance, VkDebugReportCallbackEXT callback, const( VkAllocationCallbacks )* pAllocator );
    alias PFN_vkDebugReportMessageEXT                                           = void      function( VkInstance instance, VkDebugReportFlagsEXT flags, VkDebugReportObjectTypeEXT objectType, uint64_t object, size_t location, int32_t messageCode, const( char )* pLayerPrefix, const( char )* pMessage );

    // VK_EXT_debug_marker
    alias PFN_vkDebugMarkerSetObjectTagEXT                                      = VkResult  function( VkDevice device, const( VkDebugMarkerObjectTagInfoEXT )* pTagInfo );
    alias PFN_vkDebugMarkerSetObjectNameEXT                                     = VkResult  function( VkDevice device, const( VkDebugMarkerObjectNameInfoEXT )* pNameInfo );
    alias PFN_vkCmdDebugMarkerBeginEXT                                          = void      function( VkCommandBuffer commandBuffer, const( VkDebugMarkerMarkerInfoEXT )* pMarkerInfo );
    alias PFN_vkCmdDebugMarkerEndEXT                                            = void      function( VkCommandBuffer commandBuffer );
    alias PFN_vkCmdDebugMarkerInsertEXT                                         = void      function( VkCommandBuffer commandBuffer, const( VkDebugMarkerMarkerInfoEXT )* pMarkerInfo );

    // VK_EXT_transform_feedback
    alias PFN_vkCmdBindTransformFeedbackBuffersEXT                              = void      function( VkCommandBuffer commandBuffer, uint32_t firstBinding, uint32_t bindingCount, const( VkBuffer )* pBuffers, const( VkDeviceSize )* pOffsets, const( VkDeviceSize )* pSizes );
    alias PFN_vkCmdBeginTransformFeedbackEXT                                    = void      function( VkCommandBuffer commandBuffer, uint32_t firstCounterBuffer, uint32_t counterBufferCount, const( VkBuffer )* pCounterBuffers, const( VkDeviceSize )* pCounterBufferOffsets );
    alias PFN_vkCmdEndTransformFeedbackEXT                                      = void      function( VkCommandBuffer commandBuffer, uint32_t firstCounterBuffer, uint32_t counterBufferCount, const( VkBuffer )* pCounterBuffers, const( VkDeviceSize )* pCounterBufferOffsets );
    alias PFN_vkCmdBeginQueryIndexedEXT                                         = void      function( VkCommandBuffer commandBuffer, VkQueryPool queryPool, uint32_t query, VkQueryControlFlags flags, uint32_t index );
    alias PFN_vkCmdEndQueryIndexedEXT                                           = void      function( VkCommandBuffer commandBuffer, VkQueryPool queryPool, uint32_t query, uint32_t index );
    alias PFN_vkCmdDrawIndirectByteCountEXT                                     = void      function( VkCommandBuffer commandBuffer, uint32_t instanceCount, uint32_t firstInstance, VkBuffer counterBuffer, VkDeviceSize counterBufferOffset, uint32_t counterOffset, uint32_t vertexStride );

    // VK_NVX_binary_import
    alias PFN_vkCreateCuModuleNVX                                               = VkResult  function( VkDevice device, const( VkCuModuleCreateInfoNVX )* pCreateInfo, const( VkAllocationCallbacks )* pAllocator, VkCuModuleNVX* pModule );
    alias PFN_vkCreateCuFunctionNVX                                             = VkResult  function( VkDevice device, const( VkCuFunctionCreateInfoNVX )* pCreateInfo, const( VkAllocationCallbacks )* pAllocator, VkCuFunctionNVX* pFunction );
    alias PFN_vkDestroyCuModuleNVX                                              = void      function( VkDevice device, VkCuModuleNVX Module, const( VkAllocationCallbacks )* pAllocator );
    alias PFN_vkDestroyCuFunctionNVX                                            = void      function( VkDevice device, VkCuFunctionNVX Function, const( VkAllocationCallbacks )* pAllocator );
    alias PFN_vkCmdCuLaunchKernelNVX                                            = void      function( VkCommandBuffer commandBuffer, const( VkCuLaunchInfoNVX )* pLaunchInfo );

    // VK_NVX_image_view_handle
    alias PFN_vkGetImageViewHandleNVX                                           = uint32_t  function( VkDevice device, const( VkImageViewHandleInfoNVX )* pInfo );
    alias PFN_vkGetImageViewAddressNVX                                          = VkResult  function( VkDevice device, VkImageView imageView, VkImageViewAddressPropertiesNVX* pProperties );

    // VK_AMD_shader_info
    alias PFN_vkGetShaderInfoAMD                                                = VkResult  function( VkDevice device, VkPipeline pipeline, VkShaderStageFlagBits shaderStage, VkShaderInfoTypeAMD infoType, size_t* pInfoSize, void* pInfo );

    // VK_NV_external_memory_capabilities
    alias PFN_vkGetPhysicalDeviceExternalImageFormatPropertiesNV                = VkResult  function( VkPhysicalDevice physicalDevice, VkFormat format, VkImageType type, VkImageTiling tiling, VkImageUsageFlags usage, VkImageCreateFlags flags, VkExternalMemoryHandleTypeFlagsNV externalHandleType, VkExternalImageFormatPropertiesNV* pExternalImageFormatProperties );

    // VK_EXT_conditional_rendering
    alias PFN_vkCmdBeginConditionalRenderingEXT                                 = void      function( VkCommandBuffer commandBuffer, const( VkConditionalRenderingBeginInfoEXT )* pConditionalRenderingBegin );
    alias PFN_vkCmdEndConditionalRenderingEXT                                   = void      function( VkCommandBuffer commandBuffer );

    // VK_NV_clip_space_w_scaling
    alias PFN_vkCmdSetViewportWScalingNV                                        = void      function( VkCommandBuffer commandBuffer, uint32_t firstViewport, uint32_t viewportCount, const( VkViewportWScalingNV )* pViewportWScalings );

    // VK_EXT_direct_mode_display
    alias PFN_vkReleaseDisplayEXT                                               = VkResult  function( VkPhysicalDevice physicalDevice, VkDisplayKHR display );

    // VK_EXT_display_surface_counter
    alias PFN_vkGetPhysicalDeviceSurfaceCapabilities2EXT                        = VkResult  function( VkPhysicalDevice physicalDevice, VkSurfaceKHR surface, VkSurfaceCapabilities2EXT* pSurfaceCapabilities );

    // VK_EXT_display_control
    alias PFN_vkDisplayPowerControlEXT                                          = VkResult  function( VkDevice device, VkDisplayKHR display, const( VkDisplayPowerInfoEXT )* pDisplayPowerInfo );
    alias PFN_vkRegisterDeviceEventEXT                                          = VkResult  function( VkDevice device, const( VkDeviceEventInfoEXT )* pDeviceEventInfo, const( VkAllocationCallbacks )* pAllocator, VkFence* pFence );
    alias PFN_vkRegisterDisplayEventEXT                                         = VkResult  function( VkDevice device, VkDisplayKHR display, const( VkDisplayEventInfoEXT )* pDisplayEventInfo, const( VkAllocationCallbacks )* pAllocator, VkFence* pFence );
    alias PFN_vkGetSwapchainCounterEXT                                          = VkResult  function( VkDevice device, VkSwapchainKHR swapchain, VkSurfaceCounterFlagBitsEXT counter, uint64_t* pCounterValue );

    // VK_GOOGLE_display_timing
    alias PFN_vkGetRefreshCycleDurationGOOGLE                                   = VkResult  function( VkDevice device, VkSwapchainKHR swapchain, VkRefreshCycleDurationGOOGLE* pDisplayTimingProperties );
    alias PFN_vkGetPastPresentationTimingGOOGLE                                 = VkResult  function( VkDevice device, VkSwapchainKHR swapchain, uint32_t* pPresentationTimingCount, VkPastPresentationTimingGOOGLE* pPresentationTimings );

    // VK_EXT_discard_rectangles
    alias PFN_vkCmdSetDiscardRectangleEXT                                       = void      function( VkCommandBuffer commandBuffer, uint32_t firstDiscardRectangle, uint32_t discardRectangleCount, const( VkRect2D )* pDiscardRectangles );

    // VK_EXT_hdr_metadata
    alias PFN_vkSetHdrMetadataEXT                                               = void      function( VkDevice device, uint32_t swapchainCount, const( VkSwapchainKHR )* pSwapchains, const( VkHdrMetadataEXT )* pMetadata );

    // VK_EXT_debug_utils
    alias PFN_vkSetDebugUtilsObjectNameEXT                                      = VkResult  function( VkDevice device, const( VkDebugUtilsObjectNameInfoEXT )* pNameInfo );
    alias PFN_vkSetDebugUtilsObjectTagEXT                                       = VkResult  function( VkDevice device, const( VkDebugUtilsObjectTagInfoEXT )* pTagInfo );
    alias PFN_vkQueueBeginDebugUtilsLabelEXT                                    = void      function( VkQueue queue, const( VkDebugUtilsLabelEXT )* pLabelInfo );
    alias PFN_vkQueueEndDebugUtilsLabelEXT                                      = void      function( VkQueue queue );
    alias PFN_vkQueueInsertDebugUtilsLabelEXT                                   = void      function( VkQueue queue, const( VkDebugUtilsLabelEXT )* pLabelInfo );
    alias PFN_vkCmdBeginDebugUtilsLabelEXT                                      = void      function( VkCommandBuffer commandBuffer, const( VkDebugUtilsLabelEXT )* pLabelInfo );
    alias PFN_vkCmdEndDebugUtilsLabelEXT                                        = void      function( VkCommandBuffer commandBuffer );
    alias PFN_vkCmdInsertDebugUtilsLabelEXT                                     = void      function( VkCommandBuffer commandBuffer, const( VkDebugUtilsLabelEXT )* pLabelInfo );
    alias PFN_vkCreateDebugUtilsMessengerEXT                                    = VkResult  function( VkInstance instance, const( VkDebugUtilsMessengerCreateInfoEXT )* pCreateInfo, const( VkAllocationCallbacks )* pAllocator, VkDebugUtilsMessengerEXT* pMessenger );
    alias PFN_vkDestroyDebugUtilsMessengerEXT                                   = void      function( VkInstance instance, VkDebugUtilsMessengerEXT messenger, const( VkAllocationCallbacks )* pAllocator );
    alias PFN_vkSubmitDebugUtilsMessageEXT                                      = void      function( VkInstance instance, VkDebugUtilsMessageSeverityFlagBitsEXT messageSeverity, VkDebugUtilsMessageTypeFlagsEXT messageTypes, const( VkDebugUtilsMessengerCallbackDataEXT )* pCallbackData );

    // VK_EXT_sample_locations
    alias PFN_vkCmdSetSampleLocationsEXT                                        = void      function( VkCommandBuffer commandBuffer, const( VkSampleLocationsInfoEXT )* pSampleLocationsInfo );
    alias PFN_vkGetPhysicalDeviceMultisamplePropertiesEXT                       = void      function( VkPhysicalDevice physicalDevice, VkSampleCountFlagBits samples, VkMultisamplePropertiesEXT* pMultisampleProperties );

    // VK_EXT_image_drm_format_modifier
    alias PFN_vkGetImageDrmFormatModifierPropertiesEXT                          = VkResult  function( VkDevice device, VkImage image, VkImageDrmFormatModifierPropertiesEXT* pProperties );

    // VK_EXT_validation_cache
    alias PFN_vkCreateValidationCacheEXT                                        = VkResult  function( VkDevice device, const( VkValidationCacheCreateInfoEXT )* pCreateInfo, const( VkAllocationCallbacks )* pAllocator, VkValidationCacheEXT* pValidationCache );
    alias PFN_vkDestroyValidationCacheEXT                                       = void      function( VkDevice device, VkValidationCacheEXT validationCache, const( VkAllocationCallbacks )* pAllocator );
    alias PFN_vkMergeValidationCachesEXT                                        = VkResult  function( VkDevice device, VkValidationCacheEXT dstCache, uint32_t srcCacheCount, const( VkValidationCacheEXT )* pSrcCaches );
    alias PFN_vkGetValidationCacheDataEXT                                       = VkResult  function( VkDevice device, VkValidationCacheEXT validationCache, size_t* pDataSize, void* pData );

    // VK_NV_shading_rate_image
    alias PFN_vkCmdBindShadingRateImageNV                                       = void      function( VkCommandBuffer commandBuffer, VkImageView imageView, VkImageLayout imageLayout );
    alias PFN_vkCmdSetViewportShadingRatePaletteNV                              = void      function( VkCommandBuffer commandBuffer, uint32_t firstViewport, uint32_t viewportCount, const( VkShadingRatePaletteNV )* pShadingRatePalettes );
    alias PFN_vkCmdSetCoarseSampleOrderNV                                       = void      function( VkCommandBuffer commandBuffer, VkCoarseSampleOrderTypeNV sampleOrderType, uint32_t customSampleOrderCount, const( VkCoarseSampleOrderCustomNV )* pCustomSampleOrders );

    // VK_NV_ray_tracing
    alias PFN_vkCreateAccelerationStructureNV                                   = VkResult  function( VkDevice device, const( VkAccelerationStructureCreateInfoNV )* pCreateInfo, const( VkAllocationCallbacks )* pAllocator, VkAccelerationStructureNV* pAccelerationStructure );
    alias PFN_vkDestroyAccelerationStructureNV                                  = void      function( VkDevice device, VkAccelerationStructureNV accelerationStructure, const( VkAllocationCallbacks )* pAllocator );
    alias PFN_vkGetAccelerationStructureMemoryRequirementsNV                    = void      function( VkDevice device, const( VkAccelerationStructureMemoryRequirementsInfoNV )* pInfo, VkMemoryRequirements2KHR* pMemoryRequirements );
    alias PFN_vkBindAccelerationStructureMemoryNV                               = VkResult  function( VkDevice device, uint32_t bindInfoCount, const( VkBindAccelerationStructureMemoryInfoNV )* pBindInfos );
    alias PFN_vkCmdBuildAccelerationStructureNV                                 = void      function( VkCommandBuffer commandBuffer, const( VkAccelerationStructureInfoNV )* pInfo, VkBuffer instanceData, VkDeviceSize instanceOffset, VkBool32 update, VkAccelerationStructureNV dst, VkAccelerationStructureNV src, VkBuffer scratch, VkDeviceSize scratchOffset );
    alias PFN_vkCmdCopyAccelerationStructureNV                                  = void      function( VkCommandBuffer commandBuffer, VkAccelerationStructureNV dst, VkAccelerationStructureNV src, VkCopyAccelerationStructureModeKHR mode );
    alias PFN_vkCmdTraceRaysNV                                                  = void      function( VkCommandBuffer commandBuffer, VkBuffer raygenShaderBindingTableBuffer, VkDeviceSize raygenShaderBindingOffset, VkBuffer missShaderBindingTableBuffer, VkDeviceSize missShaderBindingOffset, VkDeviceSize missShaderBindingStride, VkBuffer hitShaderBindingTableBuffer, VkDeviceSize hitShaderBindingOffset, VkDeviceSize hitShaderBindingStride, VkBuffer callableShaderBindingTableBuffer, VkDeviceSize callableShaderBindingOffset, VkDeviceSize callableShaderBindingStride, uint32_t width, uint32_t height, uint32_t depth );
    alias PFN_vkCreateRayTracingPipelinesNV                                     = VkResult  function( VkDevice device, VkPipelineCache pipelineCache, uint32_t createInfoCount, const( VkRayTracingPipelineCreateInfoNV )* pCreateInfos, const( VkAllocationCallbacks )* pAllocator, VkPipeline* pPipelines );
    alias PFN_vkGetRayTracingShaderGroupHandlesKHR                              = VkResult  function( VkDevice device, VkPipeline pipeline, uint32_t firstGroup, uint32_t groupCount, size_t dataSize, void* pData );
    alias PFN_vkGetAccelerationStructureHandleNV                                = VkResult  function( VkDevice device, VkAccelerationStructureNV accelerationStructure, size_t dataSize, void* pData );
    alias PFN_vkCmdWriteAccelerationStructuresPropertiesNV                      = void      function( VkCommandBuffer commandBuffer, uint32_t accelerationStructureCount, const( VkAccelerationStructureNV )* pAccelerationStructures, VkQueryType queryType, VkQueryPool queryPool, uint32_t firstQuery );
    alias PFN_vkCompileDeferredNV                                               = VkResult  function( VkDevice device, VkPipeline pipeline, uint32_t shader );

    // VK_EXT_external_memory_host
    alias PFN_vkGetMemoryHostPointerPropertiesEXT                               = VkResult  function( VkDevice device, VkExternalMemoryHandleTypeFlagBits handleType, const( void )* pHostPointer, VkMemoryHostPointerPropertiesEXT* pMemoryHostPointerProperties );

    // VK_AMD_buffer_marker
    alias PFN_vkCmdWriteBufferMarkerAMD                                         = void      function( VkCommandBuffer commandBuffer, VkPipelineStageFlagBits pipelineStage, VkBuffer dstBuffer, VkDeviceSize dstOffset, uint32_t marker );

    // VK_EXT_calibrated_timestamps
    alias PFN_vkGetPhysicalDeviceCalibrateableTimeDomainsEXT                    = VkResult  function( VkPhysicalDevice physicalDevice, uint32_t* pTimeDomainCount, VkTimeDomainEXT* pTimeDomains );
    alias PFN_vkGetCalibratedTimestampsEXT                                      = VkResult  function( VkDevice device, uint32_t timestampCount, const( VkCalibratedTimestampInfoEXT )* pTimestampInfos, uint64_t* pTimestamps, uint64_t* pMaxDeviation );

    // VK_NV_mesh_shader
    alias PFN_vkCmdDrawMeshTasksNV                                              = void      function( VkCommandBuffer commandBuffer, uint32_t taskCount, uint32_t firstTask );
    alias PFN_vkCmdDrawMeshTasksIndirectNV                                      = void      function( VkCommandBuffer commandBuffer, VkBuffer buffer, VkDeviceSize offset, uint32_t drawCount, uint32_t stride );
    alias PFN_vkCmdDrawMeshTasksIndirectCountNV                                 = void      function( VkCommandBuffer commandBuffer, VkBuffer buffer, VkDeviceSize offset, VkBuffer countBuffer, VkDeviceSize countBufferOffset, uint32_t maxDrawCount, uint32_t stride );

    // VK_NV_scissor_exclusive
    alias PFN_vkCmdSetExclusiveScissorNV                                        = void      function( VkCommandBuffer commandBuffer, uint32_t firstExclusiveScissor, uint32_t exclusiveScissorCount, const( VkRect2D )* pExclusiveScissors );

    // VK_NV_device_diagnostic_checkpoints
    alias PFN_vkCmdSetCheckpointNV                                              = void      function( VkCommandBuffer commandBuffer, const( void )* pCheckpointMarker );
    alias PFN_vkGetQueueCheckpointDataNV                                        = void      function( VkQueue queue, uint32_t* pCheckpointDataCount, VkCheckpointDataNV* pCheckpointData );

    // VK_INTEL_performance_query
    alias PFN_vkInitializePerformanceApiINTEL                                   = VkResult  function( VkDevice device, const( VkInitializePerformanceApiInfoINTEL )* pInitializeInfo );
    alias PFN_vkUninitializePerformanceApiINTEL                                 = void      function( VkDevice device );
    alias PFN_vkCmdSetPerformanceMarkerINTEL                                    = VkResult  function( VkCommandBuffer commandBuffer, const( VkPerformanceMarkerInfoINTEL )* pMarkerInfo );
    alias PFN_vkCmdSetPerformanceStreamMarkerINTEL                              = VkResult  function( VkCommandBuffer commandBuffer, const( VkPerformanceStreamMarkerInfoINTEL )* pMarkerInfo );
    alias PFN_vkCmdSetPerformanceOverrideINTEL                                  = VkResult  function( VkCommandBuffer commandBuffer, const( VkPerformanceOverrideInfoINTEL )* pOverrideInfo );
    alias PFN_vkAcquirePerformanceConfigurationINTEL                            = VkResult  function( VkDevice device, const( VkPerformanceConfigurationAcquireInfoINTEL )* pAcquireInfo, VkPerformanceConfigurationINTEL* pConfiguration );
    alias PFN_vkReleasePerformanceConfigurationINTEL                            = VkResult  function( VkDevice device, VkPerformanceConfigurationINTEL configuration );
    alias PFN_vkQueueSetPerformanceConfigurationINTEL                           = VkResult  function( VkQueue queue, VkPerformanceConfigurationINTEL configuration );
    alias PFN_vkGetPerformanceParameterINTEL                                    = VkResult  function( VkDevice device, VkPerformanceParameterTypeINTEL parameter, VkPerformanceValueINTEL* pValue );

    // VK_AMD_display_native_hdr
    alias PFN_vkSetLocalDimmingAMD                                              = void      function( VkDevice device, VkSwapchainKHR swapChain, VkBool32 localDimmingEnable );

    // VK_NV_cooperative_matrix
    alias PFN_vkGetPhysicalDeviceCooperativeMatrixPropertiesNV                  = VkResult  function( VkPhysicalDevice physicalDevice, uint32_t* pPropertyCount, VkCooperativeMatrixPropertiesNV* pProperties );

    // VK_NV_coverage_reduction_mode
    alias PFN_vkGetPhysicalDeviceSupportedFramebufferMixedSamplesCombinationsNV = VkResult  function( VkPhysicalDevice physicalDevice, uint32_t* pCombinationCount, VkFramebufferMixedSamplesCombinationNV* pCombinations );

    // VK_EXT_headless_surface
    alias PFN_vkCreateHeadlessSurfaceEXT                                        = VkResult  function( VkInstance instance, const( VkHeadlessSurfaceCreateInfoEXT )* pCreateInfo, const( VkAllocationCallbacks )* pAllocator, VkSurfaceKHR* pSurface );

    // VK_EXT_line_rasterization
    alias PFN_vkCmdSetLineStippleEXT                                            = void      function( VkCommandBuffer commandBuffer, uint32_t lineStippleFactor, uint16_t lineStipplePattern );

    // VK_NV_device_generated_commands
    alias PFN_vkGetGeneratedCommandsMemoryRequirementsNV                        = void      function( VkDevice device, const( VkGeneratedCommandsMemoryRequirementsInfoNV )* pInfo, VkMemoryRequirements2* pMemoryRequirements );
    alias PFN_vkCmdPreprocessGeneratedCommandsNV                                = void      function( VkCommandBuffer commandBuffer, const( VkGeneratedCommandsInfoNV )* pGeneratedCommandsInfo );
    alias PFN_vkCmdExecuteGeneratedCommandsNV                                   = void      function( VkCommandBuffer commandBuffer, VkBool32 isPreprocessed, const( VkGeneratedCommandsInfoNV )* pGeneratedCommandsInfo );
    alias PFN_vkCmdBindPipelineShaderGroupNV                                    = void      function( VkCommandBuffer commandBuffer, VkPipelineBindPoint pipelineBindPoint, VkPipeline pipeline, uint32_t groupIndex );
    alias PFN_vkCreateIndirectCommandsLayoutNV                                  = VkResult  function( VkDevice device, const( VkIndirectCommandsLayoutCreateInfoNV )* pCreateInfo, const( VkAllocationCallbacks )* pAllocator, VkIndirectCommandsLayoutNV* pIndirectCommandsLayout );
    alias PFN_vkDestroyIndirectCommandsLayoutNV                                 = void      function( VkDevice device, VkIndirectCommandsLayoutNV indirectCommandsLayout, const( VkAllocationCallbacks )* pAllocator );

    // VK_EXT_acquire_drm_display
    alias PFN_vkAcquireDrmDisplayEXT                                            = VkResult  function( VkPhysicalDevice physicalDevice, int32_t drmFd, VkDisplayKHR display );
    alias PFN_vkGetDrmDisplayEXT                                                = VkResult  function( VkPhysicalDevice physicalDevice, int32_t drmFd, uint32_t connectorId, VkDisplayKHR* display );

    // VK_NV_fragment_shading_rate_enums
    alias PFN_vkCmdSetFragmentShadingRateEnumNV                                 = void      function( VkCommandBuffer commandBuffer, VkFragmentShadingRateNV shadingRate, const VkFragmentShadingRateCombinerOpKHR[2] combinerOps );

    // VK_EXT_image_compression_control
    alias PFN_vkGetImageSubresourceLayout2EXT                                   = void      function( VkDevice device, VkImage image, const( VkImageSubresource2EXT )* pSubresource, VkSubresourceLayout2EXT* pLayout );

    // VK_EXT_vertex_input_dynamic_state
    alias PFN_vkCmdSetVertexInputEXT                                            = void      function( VkCommandBuffer commandBuffer, uint32_t vertexBindingDescriptionCount, const( VkVertexInputBindingDescription2EXT )* pVertexBindingDescriptions, uint32_t vertexAttributeDescriptionCount, const( VkVertexInputAttributeDescription2EXT )* pVertexAttributeDescriptions );

    // VK_HUAWEI_subpass_shading
    alias PFN_vkGetDeviceSubpassShadingMaxWorkgroupSizeHUAWEI                   = VkResult  function( VkDevice device, VkRenderPass renderpass, VkExtent2D* pMaxWorkgroupSize );
    alias PFN_vkCmdSubpassShadingHUAWEI                                         = void      function( VkCommandBuffer commandBuffer );

    // VK_HUAWEI_invocation_mask
    alias PFN_vkCmdBindInvocationMaskHUAWEI                                     = void      function( VkCommandBuffer commandBuffer, VkImageView imageView, VkImageLayout imageLayout );

    // VK_NV_external_memory_rdma
    alias PFN_vkGetMemoryRemoteAddressNV                                        = VkResult  function( VkDevice device, const( VkMemoryGetRemoteAddressInfoNV )* pMemoryGetRemoteAddressInfo, VkRemoteAddressNV* pAddress );

    // VK_EXT_pipeline_properties
    alias PFN_vkGetPipelinePropertiesEXT                                        = VkResult  function( VkDevice device, const( VkPipelineInfoEXT )* pPipelineInfo, VkBaseOutStructure* pPipelineProperties );

    // VK_EXT_extended_dynamic_state2
    alias PFN_vkCmdSetPatchControlPointsEXT                                     = void      function( VkCommandBuffer commandBuffer, uint32_t patchControlPoints );
    alias PFN_vkCmdSetLogicOpEXT                                                = void      function( VkCommandBuffer commandBuffer, VkLogicOp logicOp );

    // VK_EXT_color_write_enable
    alias PFN_vkCmdSetColorWriteEnableEXT                                       = void      function( VkCommandBuffer commandBuffer, uint32_t attachmentCount, const( VkBool32 )* pColorWriteEnables );

    // VK_EXT_multi_draw
    alias PFN_vkCmdDrawMultiEXT                                                 = void      function( VkCommandBuffer commandBuffer, uint32_t drawCount, const( VkMultiDrawInfoEXT )* pVertexInfo, uint32_t instanceCount, uint32_t firstInstance, uint32_t stride );
    alias PFN_vkCmdDrawMultiIndexedEXT                                          = void      function( VkCommandBuffer commandBuffer, uint32_t drawCount, const( VkMultiDrawIndexedInfoEXT )* pIndexInfo, uint32_t instanceCount, uint32_t firstInstance, uint32_t stride, const( int32_t )* pVertexOffset );

    // VK_EXT_pageable_device_local_memory
    alias PFN_vkSetDeviceMemoryPriorityEXT                                      = void      function( VkDevice device, VkDeviceMemory memory, float priority );

    // VK_VALVE_descriptor_set_host_mapping
    alias PFN_vkGetDescriptorSetLayoutHostMappingInfoVALVE                      = void      function( VkDevice device, const( VkDescriptorSetBindingReferenceVALVE )* pBindingReference, VkDescriptorSetLayoutHostMappingInfoVALVE* pHostMapping );
    alias PFN_vkGetDescriptorSetHostMappingVALVE                                = void      function( VkDevice device, VkDescriptorSet descriptorSet, void** ppData );

    // VK_KHR_acceleration_structure
    alias PFN_vkCreateAccelerationStructureKHR                                  = VkResult  function( VkDevice device, const( VkAccelerationStructureCreateInfoKHR )* pCreateInfo, const( VkAllocationCallbacks )* pAllocator, VkAccelerationStructureKHR* pAccelerationStructure );
    alias PFN_vkDestroyAccelerationStructureKHR                                 = void      function( VkDevice device, VkAccelerationStructureKHR accelerationStructure, const( VkAllocationCallbacks )* pAllocator );
    alias PFN_vkCmdBuildAccelerationStructuresKHR                               = void      function( VkCommandBuffer commandBuffer, uint32_t infoCount, const( VkAccelerationStructureBuildGeometryInfoKHR )* pInfos, const( VkAccelerationStructureBuildRangeInfoKHR* )* ppBuildRangeInfos );
    alias PFN_vkCmdBuildAccelerationStructuresIndirectKHR                       = void      function( VkCommandBuffer commandBuffer, uint32_t infoCount, const( VkAccelerationStructureBuildGeometryInfoKHR )* pInfos, const( VkDeviceAddress )* pIndirectDeviceAddresses, const( uint32_t )* pIndirectStrides, const( uint32_t* )* ppMaxPrimitiveCounts );
    alias PFN_vkBuildAccelerationStructuresKHR                                  = VkResult  function( VkDevice device, VkDeferredOperationKHR deferredOperation, uint32_t infoCount, const( VkAccelerationStructureBuildGeometryInfoKHR )* pInfos, const( VkAccelerationStructureBuildRangeInfoKHR* )* ppBuildRangeInfos );
    alias PFN_vkCopyAccelerationStructureKHR                                    = VkResult  function( VkDevice device, VkDeferredOperationKHR deferredOperation, const( VkCopyAccelerationStructureInfoKHR )* pInfo );
    alias PFN_vkCopyAccelerationStructureToMemoryKHR                            = VkResult  function( VkDevice device, VkDeferredOperationKHR deferredOperation, const( VkCopyAccelerationStructureToMemoryInfoKHR )* pInfo );
    alias PFN_vkCopyMemoryToAccelerationStructureKHR                            = VkResult  function( VkDevice device, VkDeferredOperationKHR deferredOperation, const( VkCopyMemoryToAccelerationStructureInfoKHR )* pInfo );
    alias PFN_vkWriteAccelerationStructuresPropertiesKHR                        = VkResult  function( VkDevice device, uint32_t accelerationStructureCount, const( VkAccelerationStructureKHR )* pAccelerationStructures, VkQueryType queryType, size_t dataSize, void* pData, size_t stride );
    alias PFN_vkCmdCopyAccelerationStructureKHR                                 = void      function( VkCommandBuffer commandBuffer, const( VkCopyAccelerationStructureInfoKHR )* pInfo );
    alias PFN_vkCmdCopyAccelerationStructureToMemoryKHR                         = void      function( VkCommandBuffer commandBuffer, const( VkCopyAccelerationStructureToMemoryInfoKHR )* pInfo );
    alias PFN_vkCmdCopyMemoryToAccelerationStructureKHR                         = void      function( VkCommandBuffer commandBuffer, const( VkCopyMemoryToAccelerationStructureInfoKHR )* pInfo );
    alias PFN_vkGetAccelerationStructureDeviceAddressKHR                        = VkDeviceAddress  function( VkDevice device, const( VkAccelerationStructureDeviceAddressInfoKHR )* pInfo );
    alias PFN_vkCmdWriteAccelerationStructuresPropertiesKHR                     = void      function( VkCommandBuffer commandBuffer, uint32_t accelerationStructureCount, const( VkAccelerationStructureKHR )* pAccelerationStructures, VkQueryType queryType, VkQueryPool queryPool, uint32_t firstQuery );
    alias PFN_vkGetDeviceAccelerationStructureCompatibilityKHR                  = void      function( VkDevice device, const( VkAccelerationStructureVersionInfoKHR )* pVersionInfo, VkAccelerationStructureCompatibilityKHR* pCompatibility );
    alias PFN_vkGetAccelerationStructureBuildSizesKHR                           = void      function( VkDevice device, VkAccelerationStructureBuildTypeKHR buildType, const( VkAccelerationStructureBuildGeometryInfoKHR )* pBuildInfo, const( uint32_t )* pMaxPrimitiveCounts, VkAccelerationStructureBuildSizesInfoKHR* pSizeInfo );

    // VK_KHR_ray_tracing_pipeline
    alias PFN_vkCmdTraceRaysKHR                                                 = void      function( VkCommandBuffer commandBuffer, const( VkStridedDeviceAddressRegionKHR )* pRaygenShaderBindingTable, const( VkStridedDeviceAddressRegionKHR )* pMissShaderBindingTable, const( VkStridedDeviceAddressRegionKHR )* pHitShaderBindingTable, const( VkStridedDeviceAddressRegionKHR )* pCallableShaderBindingTable, uint32_t width, uint32_t height, uint32_t depth );
    alias PFN_vkCreateRayTracingPipelinesKHR                                    = VkResult  function( VkDevice device, VkDeferredOperationKHR deferredOperation, VkPipelineCache pipelineCache, uint32_t createInfoCount, const( VkRayTracingPipelineCreateInfoKHR )* pCreateInfos, const( VkAllocationCallbacks )* pAllocator, VkPipeline* pPipelines );
    alias PFN_vkGetRayTracingCaptureReplayShaderGroupHandlesKHR                 = VkResult  function( VkDevice device, VkPipeline pipeline, uint32_t firstGroup, uint32_t groupCount, size_t dataSize, void* pData );
    alias PFN_vkCmdTraceRaysIndirectKHR                                         = void      function( VkCommandBuffer commandBuffer, const( VkStridedDeviceAddressRegionKHR )* pRaygenShaderBindingTable, const( VkStridedDeviceAddressRegionKHR )* pMissShaderBindingTable, const( VkStridedDeviceAddressRegionKHR )* pHitShaderBindingTable, const( VkStridedDeviceAddressRegionKHR )* pCallableShaderBindingTable, VkDeviceAddress indirectDeviceAddress );
    alias PFN_vkGetRayTracingShaderGroupStackSizeKHR                            = VkDeviceSize  function( VkDevice device, VkPipeline pipeline, uint32_t group, VkShaderGroupShaderKHR groupShader );
    alias PFN_vkCmdSetRayTracingPipelineStackSizeKHR                            = void      function( VkCommandBuffer commandBuffer, uint32_t pipelineStackSize );
}


/// function declarations
__gshared {

    // VK_VERSION_1_0
    PFN_vkCreateInstance                                                  vkCreateInstance;
    PFN_vkDestroyInstance                                                 vkDestroyInstance;
    PFN_vkEnumeratePhysicalDevices                                        vkEnumeratePhysicalDevices;
    PFN_vkGetPhysicalDeviceFeatures                                       vkGetPhysicalDeviceFeatures;
    PFN_vkGetPhysicalDeviceFormatProperties                               vkGetPhysicalDeviceFormatProperties;
    PFN_vkGetPhysicalDeviceImageFormatProperties                          vkGetPhysicalDeviceImageFormatProperties;
    PFN_vkGetPhysicalDeviceProperties                                     vkGetPhysicalDeviceProperties;
    PFN_vkGetPhysicalDeviceQueueFamilyProperties                          vkGetPhysicalDeviceQueueFamilyProperties;
    PFN_vkGetPhysicalDeviceMemoryProperties                               vkGetPhysicalDeviceMemoryProperties;
    PFN_vkGetInstanceProcAddr                                             vkGetInstanceProcAddr;
    PFN_vkGetDeviceProcAddr                                               vkGetDeviceProcAddr;
    PFN_vkCreateDevice                                                    vkCreateDevice;
    PFN_vkDestroyDevice                                                   vkDestroyDevice;
    PFN_vkEnumerateInstanceExtensionProperties                            vkEnumerateInstanceExtensionProperties;
    PFN_vkEnumerateDeviceExtensionProperties                              vkEnumerateDeviceExtensionProperties;
    PFN_vkEnumerateInstanceLayerProperties                                vkEnumerateInstanceLayerProperties;
    PFN_vkEnumerateDeviceLayerProperties                                  vkEnumerateDeviceLayerProperties;
    PFN_vkGetDeviceQueue                                                  vkGetDeviceQueue;
    PFN_vkQueueSubmit                                                     vkQueueSubmit;
    PFN_vkQueueWaitIdle                                                   vkQueueWaitIdle;
    PFN_vkDeviceWaitIdle                                                  vkDeviceWaitIdle;
    PFN_vkAllocateMemory                                                  vkAllocateMemory;
    PFN_vkFreeMemory                                                      vkFreeMemory;
    PFN_vkMapMemory                                                       vkMapMemory;
    PFN_vkUnmapMemory                                                     vkUnmapMemory;
    PFN_vkFlushMappedMemoryRanges                                         vkFlushMappedMemoryRanges;
    PFN_vkInvalidateMappedMemoryRanges                                    vkInvalidateMappedMemoryRanges;
    PFN_vkGetDeviceMemoryCommitment                                       vkGetDeviceMemoryCommitment;
    PFN_vkBindBufferMemory                                                vkBindBufferMemory;
    PFN_vkBindImageMemory                                                 vkBindImageMemory;
    PFN_vkGetBufferMemoryRequirements                                     vkGetBufferMemoryRequirements;
    PFN_vkGetImageMemoryRequirements                                      vkGetImageMemoryRequirements;
    PFN_vkGetImageSparseMemoryRequirements                                vkGetImageSparseMemoryRequirements;
    PFN_vkGetPhysicalDeviceSparseImageFormatProperties                    vkGetPhysicalDeviceSparseImageFormatProperties;
    PFN_vkQueueBindSparse                                                 vkQueueBindSparse;
    PFN_vkCreateFence                                                     vkCreateFence;
    PFN_vkDestroyFence                                                    vkDestroyFence;
    PFN_vkResetFences                                                     vkResetFences;
    PFN_vkGetFenceStatus                                                  vkGetFenceStatus;
    PFN_vkWaitForFences                                                   vkWaitForFences;
    PFN_vkCreateSemaphore                                                 vkCreateSemaphore;
    PFN_vkDestroySemaphore                                                vkDestroySemaphore;
    PFN_vkCreateEvent                                                     vkCreateEvent;
    PFN_vkDestroyEvent                                                    vkDestroyEvent;
    PFN_vkGetEventStatus                                                  vkGetEventStatus;
    PFN_vkSetEvent                                                        vkSetEvent;
    PFN_vkResetEvent                                                      vkResetEvent;
    PFN_vkCreateQueryPool                                                 vkCreateQueryPool;
    PFN_vkDestroyQueryPool                                                vkDestroyQueryPool;
    PFN_vkGetQueryPoolResults                                             vkGetQueryPoolResults;
    PFN_vkCreateBuffer                                                    vkCreateBuffer;
    PFN_vkDestroyBuffer                                                   vkDestroyBuffer;
    PFN_vkCreateBufferView                                                vkCreateBufferView;
    PFN_vkDestroyBufferView                                               vkDestroyBufferView;
    PFN_vkCreateImage                                                     vkCreateImage;
    PFN_vkDestroyImage                                                    vkDestroyImage;
    PFN_vkGetImageSubresourceLayout                                       vkGetImageSubresourceLayout;
    PFN_vkCreateImageView                                                 vkCreateImageView;
    PFN_vkDestroyImageView                                                vkDestroyImageView;
    PFN_vkCreateShaderModule                                              vkCreateShaderModule;
    PFN_vkDestroyShaderModule                                             vkDestroyShaderModule;
    PFN_vkCreatePipelineCache                                             vkCreatePipelineCache;
    PFN_vkDestroyPipelineCache                                            vkDestroyPipelineCache;
    PFN_vkGetPipelineCacheData                                            vkGetPipelineCacheData;
    PFN_vkMergePipelineCaches                                             vkMergePipelineCaches;
    PFN_vkCreateGraphicsPipelines                                         vkCreateGraphicsPipelines;
    PFN_vkCreateComputePipelines                                          vkCreateComputePipelines;
    PFN_vkDestroyPipeline                                                 vkDestroyPipeline;
    PFN_vkCreatePipelineLayout                                            vkCreatePipelineLayout;
    PFN_vkDestroyPipelineLayout                                           vkDestroyPipelineLayout;
    PFN_vkCreateSampler                                                   vkCreateSampler;
    PFN_vkDestroySampler                                                  vkDestroySampler;
    PFN_vkCreateDescriptorSetLayout                                       vkCreateDescriptorSetLayout;
    PFN_vkDestroyDescriptorSetLayout                                      vkDestroyDescriptorSetLayout;
    PFN_vkCreateDescriptorPool                                            vkCreateDescriptorPool;
    PFN_vkDestroyDescriptorPool                                           vkDestroyDescriptorPool;
    PFN_vkResetDescriptorPool                                             vkResetDescriptorPool;
    PFN_vkAllocateDescriptorSets                                          vkAllocateDescriptorSets;
    PFN_vkFreeDescriptorSets                                              vkFreeDescriptorSets;
    PFN_vkUpdateDescriptorSets                                            vkUpdateDescriptorSets;
    PFN_vkCreateFramebuffer                                               vkCreateFramebuffer;
    PFN_vkDestroyFramebuffer                                              vkDestroyFramebuffer;
    PFN_vkCreateRenderPass                                                vkCreateRenderPass;
    PFN_vkDestroyRenderPass                                               vkDestroyRenderPass;
    PFN_vkGetRenderAreaGranularity                                        vkGetRenderAreaGranularity;
    PFN_vkCreateCommandPool                                               vkCreateCommandPool;
    PFN_vkDestroyCommandPool                                              vkDestroyCommandPool;
    PFN_vkResetCommandPool                                                vkResetCommandPool;
    PFN_vkAllocateCommandBuffers                                          vkAllocateCommandBuffers;
    PFN_vkFreeCommandBuffers                                              vkFreeCommandBuffers;
    PFN_vkBeginCommandBuffer                                              vkBeginCommandBuffer;
    PFN_vkEndCommandBuffer                                                vkEndCommandBuffer;
    PFN_vkResetCommandBuffer                                              vkResetCommandBuffer;
    PFN_vkCmdBindPipeline                                                 vkCmdBindPipeline;
    PFN_vkCmdSetViewport                                                  vkCmdSetViewport;
    PFN_vkCmdSetScissor                                                   vkCmdSetScissor;
    PFN_vkCmdSetLineWidth                                                 vkCmdSetLineWidth;
    PFN_vkCmdSetDepthBias                                                 vkCmdSetDepthBias;
    PFN_vkCmdSetBlendConstants                                            vkCmdSetBlendConstants;
    PFN_vkCmdSetDepthBounds                                               vkCmdSetDepthBounds;
    PFN_vkCmdSetStencilCompareMask                                        vkCmdSetStencilCompareMask;
    PFN_vkCmdSetStencilWriteMask                                          vkCmdSetStencilWriteMask;
    PFN_vkCmdSetStencilReference                                          vkCmdSetStencilReference;
    PFN_vkCmdBindDescriptorSets                                           vkCmdBindDescriptorSets;
    PFN_vkCmdBindIndexBuffer                                              vkCmdBindIndexBuffer;
    PFN_vkCmdBindVertexBuffers                                            vkCmdBindVertexBuffers;
    PFN_vkCmdDraw                                                         vkCmdDraw;
    PFN_vkCmdDrawIndexed                                                  vkCmdDrawIndexed;
    PFN_vkCmdDrawIndirect                                                 vkCmdDrawIndirect;
    PFN_vkCmdDrawIndexedIndirect                                          vkCmdDrawIndexedIndirect;
    PFN_vkCmdDispatch                                                     vkCmdDispatch;
    PFN_vkCmdDispatchIndirect                                             vkCmdDispatchIndirect;
    PFN_vkCmdCopyBuffer                                                   vkCmdCopyBuffer;
    PFN_vkCmdCopyImage                                                    vkCmdCopyImage;
    PFN_vkCmdBlitImage                                                    vkCmdBlitImage;
    PFN_vkCmdCopyBufferToImage                                            vkCmdCopyBufferToImage;
    PFN_vkCmdCopyImageToBuffer                                            vkCmdCopyImageToBuffer;
    PFN_vkCmdUpdateBuffer                                                 vkCmdUpdateBuffer;
    PFN_vkCmdFillBuffer                                                   vkCmdFillBuffer;
    PFN_vkCmdClearColorImage                                              vkCmdClearColorImage;
    PFN_vkCmdClearDepthStencilImage                                       vkCmdClearDepthStencilImage;
    PFN_vkCmdClearAttachments                                             vkCmdClearAttachments;
    PFN_vkCmdResolveImage                                                 vkCmdResolveImage;
    PFN_vkCmdSetEvent                                                     vkCmdSetEvent;
    PFN_vkCmdResetEvent                                                   vkCmdResetEvent;
    PFN_vkCmdWaitEvents                                                   vkCmdWaitEvents;
    PFN_vkCmdPipelineBarrier                                              vkCmdPipelineBarrier;
    PFN_vkCmdBeginQuery                                                   vkCmdBeginQuery;
    PFN_vkCmdEndQuery                                                     vkCmdEndQuery;
    PFN_vkCmdResetQueryPool                                               vkCmdResetQueryPool;
    PFN_vkCmdWriteTimestamp                                               vkCmdWriteTimestamp;
    PFN_vkCmdCopyQueryPoolResults                                         vkCmdCopyQueryPoolResults;
    PFN_vkCmdPushConstants                                                vkCmdPushConstants;
    PFN_vkCmdBeginRenderPass                                              vkCmdBeginRenderPass;
    PFN_vkCmdNextSubpass                                                  vkCmdNextSubpass;
    PFN_vkCmdEndRenderPass                                                vkCmdEndRenderPass;
    PFN_vkCmdExecuteCommands                                              vkCmdExecuteCommands;

    // VK_VERSION_1_1
    PFN_vkEnumerateInstanceVersion                                        vkEnumerateInstanceVersion;
    PFN_vkBindBufferMemory2                                               vkBindBufferMemory2;
    PFN_vkBindImageMemory2                                                vkBindImageMemory2;
    PFN_vkGetDeviceGroupPeerMemoryFeatures                                vkGetDeviceGroupPeerMemoryFeatures;
    PFN_vkCmdSetDeviceMask                                                vkCmdSetDeviceMask;
    PFN_vkCmdDispatchBase                                                 vkCmdDispatchBase;
    PFN_vkEnumeratePhysicalDeviceGroups                                   vkEnumeratePhysicalDeviceGroups;
    PFN_vkGetImageMemoryRequirements2                                     vkGetImageMemoryRequirements2;
    PFN_vkGetBufferMemoryRequirements2                                    vkGetBufferMemoryRequirements2;
    PFN_vkGetImageSparseMemoryRequirements2                               vkGetImageSparseMemoryRequirements2;
    PFN_vkGetPhysicalDeviceFeatures2                                      vkGetPhysicalDeviceFeatures2;
    PFN_vkGetPhysicalDeviceProperties2                                    vkGetPhysicalDeviceProperties2;
    PFN_vkGetPhysicalDeviceFormatProperties2                              vkGetPhysicalDeviceFormatProperties2;
    PFN_vkGetPhysicalDeviceImageFormatProperties2                         vkGetPhysicalDeviceImageFormatProperties2;
    PFN_vkGetPhysicalDeviceQueueFamilyProperties2                         vkGetPhysicalDeviceQueueFamilyProperties2;
    PFN_vkGetPhysicalDeviceMemoryProperties2                              vkGetPhysicalDeviceMemoryProperties2;
    PFN_vkGetPhysicalDeviceSparseImageFormatProperties2                   vkGetPhysicalDeviceSparseImageFormatProperties2;
    PFN_vkTrimCommandPool                                                 vkTrimCommandPool;
    PFN_vkGetDeviceQueue2                                                 vkGetDeviceQueue2;
    PFN_vkCreateSamplerYcbcrConversion                                    vkCreateSamplerYcbcrConversion;
    PFN_vkDestroySamplerYcbcrConversion                                   vkDestroySamplerYcbcrConversion;
    PFN_vkCreateDescriptorUpdateTemplate                                  vkCreateDescriptorUpdateTemplate;
    PFN_vkDestroyDescriptorUpdateTemplate                                 vkDestroyDescriptorUpdateTemplate;
    PFN_vkUpdateDescriptorSetWithTemplate                                 vkUpdateDescriptorSetWithTemplate;
    PFN_vkGetPhysicalDeviceExternalBufferProperties                       vkGetPhysicalDeviceExternalBufferProperties;
    PFN_vkGetPhysicalDeviceExternalFenceProperties                        vkGetPhysicalDeviceExternalFenceProperties;
    PFN_vkGetPhysicalDeviceExternalSemaphoreProperties                    vkGetPhysicalDeviceExternalSemaphoreProperties;
    PFN_vkGetDescriptorSetLayoutSupport                                   vkGetDescriptorSetLayoutSupport;

    // VK_VERSION_1_2
    PFN_vkCmdDrawIndirectCount                                            vkCmdDrawIndirectCount;
    PFN_vkCmdDrawIndexedIndirectCount                                     vkCmdDrawIndexedIndirectCount;
    PFN_vkCreateRenderPass2                                               vkCreateRenderPass2;
    PFN_vkCmdBeginRenderPass2                                             vkCmdBeginRenderPass2;
    PFN_vkCmdNextSubpass2                                                 vkCmdNextSubpass2;
    PFN_vkCmdEndRenderPass2                                               vkCmdEndRenderPass2;
    PFN_vkResetQueryPool                                                  vkResetQueryPool;
    PFN_vkGetSemaphoreCounterValue                                        vkGetSemaphoreCounterValue;
    PFN_vkWaitSemaphores                                                  vkWaitSemaphores;
    PFN_vkSignalSemaphore                                                 vkSignalSemaphore;
    PFN_vkGetBufferDeviceAddress                                          vkGetBufferDeviceAddress;
    PFN_vkGetBufferOpaqueCaptureAddress                                   vkGetBufferOpaqueCaptureAddress;
    PFN_vkGetDeviceMemoryOpaqueCaptureAddress                             vkGetDeviceMemoryOpaqueCaptureAddress;

    // VK_VERSION_1_3
    PFN_vkGetPhysicalDeviceToolProperties                                 vkGetPhysicalDeviceToolProperties;
    PFN_vkCreatePrivateDataSlot                                           vkCreatePrivateDataSlot;
    PFN_vkDestroyPrivateDataSlot                                          vkDestroyPrivateDataSlot;
    PFN_vkSetPrivateData                                                  vkSetPrivateData;
    PFN_vkGetPrivateData                                                  vkGetPrivateData;
    PFN_vkCmdSetEvent2                                                    vkCmdSetEvent2;
    PFN_vkCmdResetEvent2                                                  vkCmdResetEvent2;
    PFN_vkCmdWaitEvents2                                                  vkCmdWaitEvents2;
    PFN_vkCmdPipelineBarrier2                                             vkCmdPipelineBarrier2;
    PFN_vkCmdWriteTimestamp2                                              vkCmdWriteTimestamp2;
    PFN_vkQueueSubmit2                                                    vkQueueSubmit2;
    PFN_vkCmdCopyBuffer2                                                  vkCmdCopyBuffer2;
    PFN_vkCmdCopyImage2                                                   vkCmdCopyImage2;
    PFN_vkCmdCopyBufferToImage2                                           vkCmdCopyBufferToImage2;
    PFN_vkCmdCopyImageToBuffer2                                           vkCmdCopyImageToBuffer2;
    PFN_vkCmdBlitImage2                                                   vkCmdBlitImage2;
    PFN_vkCmdResolveImage2                                                vkCmdResolveImage2;
    PFN_vkCmdBeginRendering                                               vkCmdBeginRendering;
    PFN_vkCmdEndRendering                                                 vkCmdEndRendering;
    PFN_vkCmdSetCullMode                                                  vkCmdSetCullMode;
    PFN_vkCmdSetFrontFace                                                 vkCmdSetFrontFace;
    PFN_vkCmdSetPrimitiveTopology                                         vkCmdSetPrimitiveTopology;
    PFN_vkCmdSetViewportWithCount                                         vkCmdSetViewportWithCount;
    PFN_vkCmdSetScissorWithCount                                          vkCmdSetScissorWithCount;
    PFN_vkCmdBindVertexBuffers2                                           vkCmdBindVertexBuffers2;
    PFN_vkCmdSetDepthTestEnable                                           vkCmdSetDepthTestEnable;
    PFN_vkCmdSetDepthWriteEnable                                          vkCmdSetDepthWriteEnable;
    PFN_vkCmdSetDepthCompareOp                                            vkCmdSetDepthCompareOp;
    PFN_vkCmdSetDepthBoundsTestEnable                                     vkCmdSetDepthBoundsTestEnable;
    PFN_vkCmdSetStencilTestEnable                                         vkCmdSetStencilTestEnable;
    PFN_vkCmdSetStencilOp                                                 vkCmdSetStencilOp;
    PFN_vkCmdSetRasterizerDiscardEnable                                   vkCmdSetRasterizerDiscardEnable;
    PFN_vkCmdSetDepthBiasEnable                                           vkCmdSetDepthBiasEnable;
    PFN_vkCmdSetPrimitiveRestartEnable                                    vkCmdSetPrimitiveRestartEnable;
    PFN_vkGetDeviceBufferMemoryRequirements                               vkGetDeviceBufferMemoryRequirements;
    PFN_vkGetDeviceImageMemoryRequirements                                vkGetDeviceImageMemoryRequirements;
    PFN_vkGetDeviceImageSparseMemoryRequirements                          vkGetDeviceImageSparseMemoryRequirements;

    // VK_KHR_surface
    PFN_vkDestroySurfaceKHR                                               vkDestroySurfaceKHR;
    PFN_vkGetPhysicalDeviceSurfaceSupportKHR                              vkGetPhysicalDeviceSurfaceSupportKHR;
    PFN_vkGetPhysicalDeviceSurfaceCapabilitiesKHR                         vkGetPhysicalDeviceSurfaceCapabilitiesKHR;
    PFN_vkGetPhysicalDeviceSurfaceFormatsKHR                              vkGetPhysicalDeviceSurfaceFormatsKHR;
    PFN_vkGetPhysicalDeviceSurfacePresentModesKHR                         vkGetPhysicalDeviceSurfacePresentModesKHR;

    // VK_KHR_swapchain
    PFN_vkCreateSwapchainKHR                                              vkCreateSwapchainKHR;
    PFN_vkDestroySwapchainKHR                                             vkDestroySwapchainKHR;
    PFN_vkGetSwapchainImagesKHR                                           vkGetSwapchainImagesKHR;
    PFN_vkAcquireNextImageKHR                                             vkAcquireNextImageKHR;
    PFN_vkQueuePresentKHR                                                 vkQueuePresentKHR;
    PFN_vkGetDeviceGroupPresentCapabilitiesKHR                            vkGetDeviceGroupPresentCapabilitiesKHR;
    PFN_vkGetDeviceGroupSurfacePresentModesKHR                            vkGetDeviceGroupSurfacePresentModesKHR;
    PFN_vkGetPhysicalDevicePresentRectanglesKHR                           vkGetPhysicalDevicePresentRectanglesKHR;
    PFN_vkAcquireNextImage2KHR                                            vkAcquireNextImage2KHR;

    // VK_KHR_display
    PFN_vkGetPhysicalDeviceDisplayPropertiesKHR                           vkGetPhysicalDeviceDisplayPropertiesKHR;
    PFN_vkGetPhysicalDeviceDisplayPlanePropertiesKHR                      vkGetPhysicalDeviceDisplayPlanePropertiesKHR;
    PFN_vkGetDisplayPlaneSupportedDisplaysKHR                             vkGetDisplayPlaneSupportedDisplaysKHR;
    PFN_vkGetDisplayModePropertiesKHR                                     vkGetDisplayModePropertiesKHR;
    PFN_vkCreateDisplayModeKHR                                            vkCreateDisplayModeKHR;
    PFN_vkGetDisplayPlaneCapabilitiesKHR                                  vkGetDisplayPlaneCapabilitiesKHR;
    PFN_vkCreateDisplayPlaneSurfaceKHR                                    vkCreateDisplayPlaneSurfaceKHR;

    // VK_KHR_display_swapchain
    PFN_vkCreateSharedSwapchainsKHR                                       vkCreateSharedSwapchainsKHR;

    // VK_KHR_external_memory_fd
    PFN_vkGetMemoryFdKHR                                                  vkGetMemoryFdKHR;
    PFN_vkGetMemoryFdPropertiesKHR                                        vkGetMemoryFdPropertiesKHR;

    // VK_KHR_external_semaphore_fd
    PFN_vkImportSemaphoreFdKHR                                            vkImportSemaphoreFdKHR;
    PFN_vkGetSemaphoreFdKHR                                               vkGetSemaphoreFdKHR;

    // VK_KHR_push_descriptor
    PFN_vkCmdPushDescriptorSetKHR                                         vkCmdPushDescriptorSetKHR;
    PFN_vkCmdPushDescriptorSetWithTemplateKHR                             vkCmdPushDescriptorSetWithTemplateKHR;

    // VK_KHR_shared_presentable_image
    PFN_vkGetSwapchainStatusKHR                                           vkGetSwapchainStatusKHR;

    // VK_KHR_external_fence_fd
    PFN_vkImportFenceFdKHR                                                vkImportFenceFdKHR;
    PFN_vkGetFenceFdKHR                                                   vkGetFenceFdKHR;

    // VK_KHR_performance_query
    PFN_vkEnumeratePhysicalDeviceQueueFamilyPerformanceQueryCountersKHR   vkEnumeratePhysicalDeviceQueueFamilyPerformanceQueryCountersKHR;
    PFN_vkGetPhysicalDeviceQueueFamilyPerformanceQueryPassesKHR           vkGetPhysicalDeviceQueueFamilyPerformanceQueryPassesKHR;
    PFN_vkAcquireProfilingLockKHR                                         vkAcquireProfilingLockKHR;
    PFN_vkReleaseProfilingLockKHR                                         vkReleaseProfilingLockKHR;

    // VK_KHR_get_surface_capabilities2
    PFN_vkGetPhysicalDeviceSurfaceCapabilities2KHR                        vkGetPhysicalDeviceSurfaceCapabilities2KHR;
    PFN_vkGetPhysicalDeviceSurfaceFormats2KHR                             vkGetPhysicalDeviceSurfaceFormats2KHR;

    // VK_KHR_get_display_properties2
    PFN_vkGetPhysicalDeviceDisplayProperties2KHR                          vkGetPhysicalDeviceDisplayProperties2KHR;
    PFN_vkGetPhysicalDeviceDisplayPlaneProperties2KHR                     vkGetPhysicalDeviceDisplayPlaneProperties2KHR;
    PFN_vkGetDisplayModeProperties2KHR                                    vkGetDisplayModeProperties2KHR;
    PFN_vkGetDisplayPlaneCapabilities2KHR                                 vkGetDisplayPlaneCapabilities2KHR;

    // VK_KHR_fragment_shading_rate
    PFN_vkGetPhysicalDeviceFragmentShadingRatesKHR                        vkGetPhysicalDeviceFragmentShadingRatesKHR;
    PFN_vkCmdSetFragmentShadingRateKHR                                    vkCmdSetFragmentShadingRateKHR;

    // VK_KHR_present_wait
    PFN_vkWaitForPresentKHR                                               vkWaitForPresentKHR;

    // VK_KHR_deferred_host_operations
    PFN_vkCreateDeferredOperationKHR                                      vkCreateDeferredOperationKHR;
    PFN_vkDestroyDeferredOperationKHR                                     vkDestroyDeferredOperationKHR;
    PFN_vkGetDeferredOperationMaxConcurrencyKHR                           vkGetDeferredOperationMaxConcurrencyKHR;
    PFN_vkGetDeferredOperationResultKHR                                   vkGetDeferredOperationResultKHR;
    PFN_vkDeferredOperationJoinKHR                                        vkDeferredOperationJoinKHR;

    // VK_KHR_pipeline_executable_properties
    PFN_vkGetPipelineExecutablePropertiesKHR                              vkGetPipelineExecutablePropertiesKHR;
    PFN_vkGetPipelineExecutableStatisticsKHR                              vkGetPipelineExecutableStatisticsKHR;
    PFN_vkGetPipelineExecutableInternalRepresentationsKHR                 vkGetPipelineExecutableInternalRepresentationsKHR;

    // VK_KHR_synchronization2
    PFN_vkCmdWriteBufferMarker2AMD                                        vkCmdWriteBufferMarker2AMD;
    PFN_vkGetQueueCheckpointData2NV                                       vkGetQueueCheckpointData2NV;

    // VK_KHR_ray_tracing_maintenance1
    PFN_vkCmdTraceRaysIndirect2KHR                                        vkCmdTraceRaysIndirect2KHR;

    // VK_EXT_debug_report
    PFN_vkCreateDebugReportCallbackEXT                                    vkCreateDebugReportCallbackEXT;
    PFN_vkDestroyDebugReportCallbackEXT                                   vkDestroyDebugReportCallbackEXT;
    PFN_vkDebugReportMessageEXT                                           vkDebugReportMessageEXT;

    // VK_EXT_debug_marker
    PFN_vkDebugMarkerSetObjectTagEXT                                      vkDebugMarkerSetObjectTagEXT;
    PFN_vkDebugMarkerSetObjectNameEXT                                     vkDebugMarkerSetObjectNameEXT;
    PFN_vkCmdDebugMarkerBeginEXT                                          vkCmdDebugMarkerBeginEXT;
    PFN_vkCmdDebugMarkerEndEXT                                            vkCmdDebugMarkerEndEXT;
    PFN_vkCmdDebugMarkerInsertEXT                                         vkCmdDebugMarkerInsertEXT;

    // VK_EXT_transform_feedback
    PFN_vkCmdBindTransformFeedbackBuffersEXT                              vkCmdBindTransformFeedbackBuffersEXT;
    PFN_vkCmdBeginTransformFeedbackEXT                                    vkCmdBeginTransformFeedbackEXT;
    PFN_vkCmdEndTransformFeedbackEXT                                      vkCmdEndTransformFeedbackEXT;
    PFN_vkCmdBeginQueryIndexedEXT                                         vkCmdBeginQueryIndexedEXT;
    PFN_vkCmdEndQueryIndexedEXT                                           vkCmdEndQueryIndexedEXT;
    PFN_vkCmdDrawIndirectByteCountEXT                                     vkCmdDrawIndirectByteCountEXT;

    // VK_NVX_binary_import
    PFN_vkCreateCuModuleNVX                                               vkCreateCuModuleNVX;
    PFN_vkCreateCuFunctionNVX                                             vkCreateCuFunctionNVX;
    PFN_vkDestroyCuModuleNVX                                              vkDestroyCuModuleNVX;
    PFN_vkDestroyCuFunctionNVX                                            vkDestroyCuFunctionNVX;
    PFN_vkCmdCuLaunchKernelNVX                                            vkCmdCuLaunchKernelNVX;

    // VK_NVX_image_view_handle
    PFN_vkGetImageViewHandleNVX                                           vkGetImageViewHandleNVX;
    PFN_vkGetImageViewAddressNVX                                          vkGetImageViewAddressNVX;

    // VK_AMD_shader_info
    PFN_vkGetShaderInfoAMD                                                vkGetShaderInfoAMD;

    // VK_NV_external_memory_capabilities
    PFN_vkGetPhysicalDeviceExternalImageFormatPropertiesNV                vkGetPhysicalDeviceExternalImageFormatPropertiesNV;

    // VK_EXT_conditional_rendering
    PFN_vkCmdBeginConditionalRenderingEXT                                 vkCmdBeginConditionalRenderingEXT;
    PFN_vkCmdEndConditionalRenderingEXT                                   vkCmdEndConditionalRenderingEXT;

    // VK_NV_clip_space_w_scaling
    PFN_vkCmdSetViewportWScalingNV                                        vkCmdSetViewportWScalingNV;

    // VK_EXT_direct_mode_display
    PFN_vkReleaseDisplayEXT                                               vkReleaseDisplayEXT;

    // VK_EXT_display_surface_counter
    PFN_vkGetPhysicalDeviceSurfaceCapabilities2EXT                        vkGetPhysicalDeviceSurfaceCapabilities2EXT;

    // VK_EXT_display_control
    PFN_vkDisplayPowerControlEXT                                          vkDisplayPowerControlEXT;
    PFN_vkRegisterDeviceEventEXT                                          vkRegisterDeviceEventEXT;
    PFN_vkRegisterDisplayEventEXT                                         vkRegisterDisplayEventEXT;
    PFN_vkGetSwapchainCounterEXT                                          vkGetSwapchainCounterEXT;

    // VK_GOOGLE_display_timing
    PFN_vkGetRefreshCycleDurationGOOGLE                                   vkGetRefreshCycleDurationGOOGLE;
    PFN_vkGetPastPresentationTimingGOOGLE                                 vkGetPastPresentationTimingGOOGLE;

    // VK_EXT_discard_rectangles
    PFN_vkCmdSetDiscardRectangleEXT                                       vkCmdSetDiscardRectangleEXT;

    // VK_EXT_hdr_metadata
    PFN_vkSetHdrMetadataEXT                                               vkSetHdrMetadataEXT;

    // VK_EXT_debug_utils
    PFN_vkSetDebugUtilsObjectNameEXT                                      vkSetDebugUtilsObjectNameEXT;
    PFN_vkSetDebugUtilsObjectTagEXT                                       vkSetDebugUtilsObjectTagEXT;
    PFN_vkQueueBeginDebugUtilsLabelEXT                                    vkQueueBeginDebugUtilsLabelEXT;
    PFN_vkQueueEndDebugUtilsLabelEXT                                      vkQueueEndDebugUtilsLabelEXT;
    PFN_vkQueueInsertDebugUtilsLabelEXT                                   vkQueueInsertDebugUtilsLabelEXT;
    PFN_vkCmdBeginDebugUtilsLabelEXT                                      vkCmdBeginDebugUtilsLabelEXT;
    PFN_vkCmdEndDebugUtilsLabelEXT                                        vkCmdEndDebugUtilsLabelEXT;
    PFN_vkCmdInsertDebugUtilsLabelEXT                                     vkCmdInsertDebugUtilsLabelEXT;
    PFN_vkCreateDebugUtilsMessengerEXT                                    vkCreateDebugUtilsMessengerEXT;
    PFN_vkDestroyDebugUtilsMessengerEXT                                   vkDestroyDebugUtilsMessengerEXT;
    PFN_vkSubmitDebugUtilsMessageEXT                                      vkSubmitDebugUtilsMessageEXT;

    // VK_EXT_sample_locations
    PFN_vkCmdSetSampleLocationsEXT                                        vkCmdSetSampleLocationsEXT;
    PFN_vkGetPhysicalDeviceMultisamplePropertiesEXT                       vkGetPhysicalDeviceMultisamplePropertiesEXT;

    // VK_EXT_image_drm_format_modifier
    PFN_vkGetImageDrmFormatModifierPropertiesEXT                          vkGetImageDrmFormatModifierPropertiesEXT;

    // VK_EXT_validation_cache
    PFN_vkCreateValidationCacheEXT                                        vkCreateValidationCacheEXT;
    PFN_vkDestroyValidationCacheEXT                                       vkDestroyValidationCacheEXT;
    PFN_vkMergeValidationCachesEXT                                        vkMergeValidationCachesEXT;
    PFN_vkGetValidationCacheDataEXT                                       vkGetValidationCacheDataEXT;

    // VK_NV_shading_rate_image
    PFN_vkCmdBindShadingRateImageNV                                       vkCmdBindShadingRateImageNV;
    PFN_vkCmdSetViewportShadingRatePaletteNV                              vkCmdSetViewportShadingRatePaletteNV;
    PFN_vkCmdSetCoarseSampleOrderNV                                       vkCmdSetCoarseSampleOrderNV;

    // VK_NV_ray_tracing
    PFN_vkCreateAccelerationStructureNV                                   vkCreateAccelerationStructureNV;
    PFN_vkDestroyAccelerationStructureNV                                  vkDestroyAccelerationStructureNV;
    PFN_vkGetAccelerationStructureMemoryRequirementsNV                    vkGetAccelerationStructureMemoryRequirementsNV;
    PFN_vkBindAccelerationStructureMemoryNV                               vkBindAccelerationStructureMemoryNV;
    PFN_vkCmdBuildAccelerationStructureNV                                 vkCmdBuildAccelerationStructureNV;
    PFN_vkCmdCopyAccelerationStructureNV                                  vkCmdCopyAccelerationStructureNV;
    PFN_vkCmdTraceRaysNV                                                  vkCmdTraceRaysNV;
    PFN_vkCreateRayTracingPipelinesNV                                     vkCreateRayTracingPipelinesNV;
    PFN_vkGetRayTracingShaderGroupHandlesKHR                              vkGetRayTracingShaderGroupHandlesKHR;
    PFN_vkGetAccelerationStructureHandleNV                                vkGetAccelerationStructureHandleNV;
    PFN_vkCmdWriteAccelerationStructuresPropertiesNV                      vkCmdWriteAccelerationStructuresPropertiesNV;
    PFN_vkCompileDeferredNV                                               vkCompileDeferredNV;

    // VK_EXT_external_memory_host
    PFN_vkGetMemoryHostPointerPropertiesEXT                               vkGetMemoryHostPointerPropertiesEXT;

    // VK_AMD_buffer_marker
    PFN_vkCmdWriteBufferMarkerAMD                                         vkCmdWriteBufferMarkerAMD;

    // VK_EXT_calibrated_timestamps
    PFN_vkGetPhysicalDeviceCalibrateableTimeDomainsEXT                    vkGetPhysicalDeviceCalibrateableTimeDomainsEXT;
    PFN_vkGetCalibratedTimestampsEXT                                      vkGetCalibratedTimestampsEXT;

    // VK_NV_mesh_shader
    PFN_vkCmdDrawMeshTasksNV                                              vkCmdDrawMeshTasksNV;
    PFN_vkCmdDrawMeshTasksIndirectNV                                      vkCmdDrawMeshTasksIndirectNV;
    PFN_vkCmdDrawMeshTasksIndirectCountNV                                 vkCmdDrawMeshTasksIndirectCountNV;

    // VK_NV_scissor_exclusive
    PFN_vkCmdSetExclusiveScissorNV                                        vkCmdSetExclusiveScissorNV;

    // VK_NV_device_diagnostic_checkpoints
    PFN_vkCmdSetCheckpointNV                                              vkCmdSetCheckpointNV;
    PFN_vkGetQueueCheckpointDataNV                                        vkGetQueueCheckpointDataNV;

    // VK_INTEL_performance_query
    PFN_vkInitializePerformanceApiINTEL                                   vkInitializePerformanceApiINTEL;
    PFN_vkUninitializePerformanceApiINTEL                                 vkUninitializePerformanceApiINTEL;
    PFN_vkCmdSetPerformanceMarkerINTEL                                    vkCmdSetPerformanceMarkerINTEL;
    PFN_vkCmdSetPerformanceStreamMarkerINTEL                              vkCmdSetPerformanceStreamMarkerINTEL;
    PFN_vkCmdSetPerformanceOverrideINTEL                                  vkCmdSetPerformanceOverrideINTEL;
    PFN_vkAcquirePerformanceConfigurationINTEL                            vkAcquirePerformanceConfigurationINTEL;
    PFN_vkReleasePerformanceConfigurationINTEL                            vkReleasePerformanceConfigurationINTEL;
    PFN_vkQueueSetPerformanceConfigurationINTEL                           vkQueueSetPerformanceConfigurationINTEL;
    PFN_vkGetPerformanceParameterINTEL                                    vkGetPerformanceParameterINTEL;

    // VK_AMD_display_native_hdr
    PFN_vkSetLocalDimmingAMD                                              vkSetLocalDimmingAMD;

    // VK_NV_cooperative_matrix
    PFN_vkGetPhysicalDeviceCooperativeMatrixPropertiesNV                  vkGetPhysicalDeviceCooperativeMatrixPropertiesNV;

    // VK_NV_coverage_reduction_mode
    PFN_vkGetPhysicalDeviceSupportedFramebufferMixedSamplesCombinationsNV vkGetPhysicalDeviceSupportedFramebufferMixedSamplesCombinationsNV;

    // VK_EXT_headless_surface
    PFN_vkCreateHeadlessSurfaceEXT                                        vkCreateHeadlessSurfaceEXT;

    // VK_EXT_line_rasterization
    PFN_vkCmdSetLineStippleEXT                                            vkCmdSetLineStippleEXT;

    // VK_NV_device_generated_commands
    PFN_vkGetGeneratedCommandsMemoryRequirementsNV                        vkGetGeneratedCommandsMemoryRequirementsNV;
    PFN_vkCmdPreprocessGeneratedCommandsNV                                vkCmdPreprocessGeneratedCommandsNV;
    PFN_vkCmdExecuteGeneratedCommandsNV                                   vkCmdExecuteGeneratedCommandsNV;
    PFN_vkCmdBindPipelineShaderGroupNV                                    vkCmdBindPipelineShaderGroupNV;
    PFN_vkCreateIndirectCommandsLayoutNV                                  vkCreateIndirectCommandsLayoutNV;
    PFN_vkDestroyIndirectCommandsLayoutNV                                 vkDestroyIndirectCommandsLayoutNV;

    // VK_EXT_acquire_drm_display
    PFN_vkAcquireDrmDisplayEXT                                            vkAcquireDrmDisplayEXT;
    PFN_vkGetDrmDisplayEXT                                                vkGetDrmDisplayEXT;

    // VK_NV_fragment_shading_rate_enums
    PFN_vkCmdSetFragmentShadingRateEnumNV                                 vkCmdSetFragmentShadingRateEnumNV;

    // VK_EXT_image_compression_control
    PFN_vkGetImageSubresourceLayout2EXT                                   vkGetImageSubresourceLayout2EXT;

    // VK_EXT_vertex_input_dynamic_state
    PFN_vkCmdSetVertexInputEXT                                            vkCmdSetVertexInputEXT;

    // VK_HUAWEI_subpass_shading
    PFN_vkGetDeviceSubpassShadingMaxWorkgroupSizeHUAWEI                   vkGetDeviceSubpassShadingMaxWorkgroupSizeHUAWEI;
    PFN_vkCmdSubpassShadingHUAWEI                                         vkCmdSubpassShadingHUAWEI;

    // VK_HUAWEI_invocation_mask
    PFN_vkCmdBindInvocationMaskHUAWEI                                     vkCmdBindInvocationMaskHUAWEI;

    // VK_NV_external_memory_rdma
    PFN_vkGetMemoryRemoteAddressNV                                        vkGetMemoryRemoteAddressNV;

    // VK_EXT_pipeline_properties
    PFN_vkGetPipelinePropertiesEXT                                        vkGetPipelinePropertiesEXT;

    // VK_EXT_extended_dynamic_state2
    PFN_vkCmdSetPatchControlPointsEXT                                     vkCmdSetPatchControlPointsEXT;
    PFN_vkCmdSetLogicOpEXT                                                vkCmdSetLogicOpEXT;

    // VK_EXT_color_write_enable
    PFN_vkCmdSetColorWriteEnableEXT                                       vkCmdSetColorWriteEnableEXT;

    // VK_EXT_multi_draw
    PFN_vkCmdDrawMultiEXT                                                 vkCmdDrawMultiEXT;
    PFN_vkCmdDrawMultiIndexedEXT                                          vkCmdDrawMultiIndexedEXT;

    // VK_EXT_pageable_device_local_memory
    PFN_vkSetDeviceMemoryPriorityEXT                                      vkSetDeviceMemoryPriorityEXT;

    // VK_VALVE_descriptor_set_host_mapping
    PFN_vkGetDescriptorSetLayoutHostMappingInfoVALVE                      vkGetDescriptorSetLayoutHostMappingInfoVALVE;
    PFN_vkGetDescriptorSetHostMappingVALVE                                vkGetDescriptorSetHostMappingVALVE;

    // VK_KHR_acceleration_structure
    PFN_vkCreateAccelerationStructureKHR                                  vkCreateAccelerationStructureKHR;
    PFN_vkDestroyAccelerationStructureKHR                                 vkDestroyAccelerationStructureKHR;
    PFN_vkCmdBuildAccelerationStructuresKHR                               vkCmdBuildAccelerationStructuresKHR;
    PFN_vkCmdBuildAccelerationStructuresIndirectKHR                       vkCmdBuildAccelerationStructuresIndirectKHR;
    PFN_vkBuildAccelerationStructuresKHR                                  vkBuildAccelerationStructuresKHR;
    PFN_vkCopyAccelerationStructureKHR                                    vkCopyAccelerationStructureKHR;
    PFN_vkCopyAccelerationStructureToMemoryKHR                            vkCopyAccelerationStructureToMemoryKHR;
    PFN_vkCopyMemoryToAccelerationStructureKHR                            vkCopyMemoryToAccelerationStructureKHR;
    PFN_vkWriteAccelerationStructuresPropertiesKHR                        vkWriteAccelerationStructuresPropertiesKHR;
    PFN_vkCmdCopyAccelerationStructureKHR                                 vkCmdCopyAccelerationStructureKHR;
    PFN_vkCmdCopyAccelerationStructureToMemoryKHR                         vkCmdCopyAccelerationStructureToMemoryKHR;
    PFN_vkCmdCopyMemoryToAccelerationStructureKHR                         vkCmdCopyMemoryToAccelerationStructureKHR;
    PFN_vkGetAccelerationStructureDeviceAddressKHR                        vkGetAccelerationStructureDeviceAddressKHR;
    PFN_vkCmdWriteAccelerationStructuresPropertiesKHR                     vkCmdWriteAccelerationStructuresPropertiesKHR;
    PFN_vkGetDeviceAccelerationStructureCompatibilityKHR                  vkGetDeviceAccelerationStructureCompatibilityKHR;
    PFN_vkGetAccelerationStructureBuildSizesKHR                           vkGetAccelerationStructureBuildSizesKHR;

    // VK_KHR_ray_tracing_pipeline
    PFN_vkCmdTraceRaysKHR                                                 vkCmdTraceRaysKHR;
    PFN_vkCreateRayTracingPipelinesKHR                                    vkCreateRayTracingPipelinesKHR;
    PFN_vkGetRayTracingCaptureReplayShaderGroupHandlesKHR                 vkGetRayTracingCaptureReplayShaderGroupHandlesKHR;
    PFN_vkCmdTraceRaysIndirectKHR                                         vkCmdTraceRaysIndirectKHR;
    PFN_vkGetRayTracingShaderGroupStackSizeKHR                            vkGetRayTracingShaderGroupStackSizeKHR;
    PFN_vkCmdSetRayTracingPipelineStackSizeKHR                            vkCmdSetRayTracingPipelineStackSizeKHR;

    // VK_KHR_dynamic_rendering
    alias vkCmdBeginRenderingKHR                                                  = vkCmdBeginRendering;
    alias vkCmdEndRenderingKHR                                                    = vkCmdEndRendering;

    // VK_KHR_get_physical_device_properties2
    alias vkGetPhysicalDeviceFeatures2KHR                                         = vkGetPhysicalDeviceFeatures2;
    alias vkGetPhysicalDeviceProperties2KHR                                       = vkGetPhysicalDeviceProperties2;
    alias vkGetPhysicalDeviceFormatProperties2KHR                                 = vkGetPhysicalDeviceFormatProperties2;
    alias vkGetPhysicalDeviceImageFormatProperties2KHR                            = vkGetPhysicalDeviceImageFormatProperties2;
    alias vkGetPhysicalDeviceQueueFamilyProperties2KHR                            = vkGetPhysicalDeviceQueueFamilyProperties2;
    alias vkGetPhysicalDeviceMemoryProperties2KHR                                 = vkGetPhysicalDeviceMemoryProperties2;
    alias vkGetPhysicalDeviceSparseImageFormatProperties2KHR                      = vkGetPhysicalDeviceSparseImageFormatProperties2;

    // VK_KHR_device_group
    alias vkGetDeviceGroupPeerMemoryFeaturesKHR                                   = vkGetDeviceGroupPeerMemoryFeatures;
    alias vkCmdSetDeviceMaskKHR                                                   = vkCmdSetDeviceMask;
    alias vkCmdDispatchBaseKHR                                                    = vkCmdDispatchBase;

    // VK_KHR_maintenance1
    alias vkTrimCommandPoolKHR                                                    = vkTrimCommandPool;

    // VK_KHR_device_group_creation
    alias vkEnumeratePhysicalDeviceGroupsKHR                                      = vkEnumeratePhysicalDeviceGroups;

    // VK_KHR_external_memory_capabilities
    alias vkGetPhysicalDeviceExternalBufferPropertiesKHR                          = vkGetPhysicalDeviceExternalBufferProperties;

    // VK_KHR_external_semaphore_capabilities
    alias vkGetPhysicalDeviceExternalSemaphorePropertiesKHR                       = vkGetPhysicalDeviceExternalSemaphoreProperties;

    // VK_KHR_descriptor_update_template
    alias vkCreateDescriptorUpdateTemplateKHR                                     = vkCreateDescriptorUpdateTemplate;
    alias vkDestroyDescriptorUpdateTemplateKHR                                    = vkDestroyDescriptorUpdateTemplate;
    alias vkUpdateDescriptorSetWithTemplateKHR                                    = vkUpdateDescriptorSetWithTemplate;

    // VK_KHR_create_renderpass2
    alias vkCreateRenderPass2KHR                                                  = vkCreateRenderPass2;
    alias vkCmdBeginRenderPass2KHR                                                = vkCmdBeginRenderPass2;
    alias vkCmdNextSubpass2KHR                                                    = vkCmdNextSubpass2;
    alias vkCmdEndRenderPass2KHR                                                  = vkCmdEndRenderPass2;

    // VK_KHR_external_fence_capabilities
    alias vkGetPhysicalDeviceExternalFencePropertiesKHR                           = vkGetPhysicalDeviceExternalFenceProperties;

    // VK_KHR_get_memory_requirements2
    alias vkGetImageMemoryRequirements2KHR                                        = vkGetImageMemoryRequirements2;
    alias vkGetBufferMemoryRequirements2KHR                                       = vkGetBufferMemoryRequirements2;
    alias vkGetImageSparseMemoryRequirements2KHR                                  = vkGetImageSparseMemoryRequirements2;

    // VK_KHR_sampler_ycbcr_conversion
    alias vkCreateSamplerYcbcrConversionKHR                                       = vkCreateSamplerYcbcrConversion;
    alias vkDestroySamplerYcbcrConversionKHR                                      = vkDestroySamplerYcbcrConversion;

    // VK_KHR_bind_memory2
    alias vkBindBufferMemory2KHR                                                  = vkBindBufferMemory2;
    alias vkBindImageMemory2KHR                                                   = vkBindImageMemory2;

    // VK_KHR_maintenance3
    alias vkGetDescriptorSetLayoutSupportKHR                                      = vkGetDescriptorSetLayoutSupport;

    // VK_KHR_draw_indirect_count
    alias vkCmdDrawIndirectCountKHR                                               = vkCmdDrawIndirectCount;
    alias vkCmdDrawIndexedIndirectCountKHR                                        = vkCmdDrawIndexedIndirectCount;

    // VK_KHR_timeline_semaphore
    alias vkGetSemaphoreCounterValueKHR                                           = vkGetSemaphoreCounterValue;
    alias vkWaitSemaphoresKHR                                                     = vkWaitSemaphores;
    alias vkSignalSemaphoreKHR                                                    = vkSignalSemaphore;

    // VK_KHR_buffer_device_address
    alias vkGetBufferDeviceAddressKHR                                             = vkGetBufferDeviceAddress;
    alias vkGetBufferOpaqueCaptureAddressKHR                                      = vkGetBufferOpaqueCaptureAddress;
    alias vkGetDeviceMemoryOpaqueCaptureAddressKHR                                = vkGetDeviceMemoryOpaqueCaptureAddress;

    // VK_KHR_synchronization2
    alias vkCmdSetEvent2KHR                                                       = vkCmdSetEvent2;
    alias vkCmdResetEvent2KHR                                                     = vkCmdResetEvent2;
    alias vkCmdWaitEvents2KHR                                                     = vkCmdWaitEvents2;
    alias vkCmdPipelineBarrier2KHR                                                = vkCmdPipelineBarrier2;
    alias vkCmdWriteTimestamp2KHR                                                 = vkCmdWriteTimestamp2;
    alias vkQueueSubmit2KHR                                                       = vkQueueSubmit2;

    // VK_KHR_copy_commands2
    alias vkCmdCopyBuffer2KHR                                                     = vkCmdCopyBuffer2;
    alias vkCmdCopyImage2KHR                                                      = vkCmdCopyImage2;
    alias vkCmdCopyBufferToImage2KHR                                              = vkCmdCopyBufferToImage2;
    alias vkCmdCopyImageToBuffer2KHR                                              = vkCmdCopyImageToBuffer2;
    alias vkCmdBlitImage2KHR                                                      = vkCmdBlitImage2;
    alias vkCmdResolveImage2KHR                                                   = vkCmdResolveImage2;

    // VK_KHR_maintenance4
    alias vkGetDeviceBufferMemoryRequirementsKHR                                  = vkGetDeviceBufferMemoryRequirements;
    alias vkGetDeviceImageMemoryRequirementsKHR                                   = vkGetDeviceImageMemoryRequirements;
    alias vkGetDeviceImageSparseMemoryRequirementsKHR                             = vkGetDeviceImageSparseMemoryRequirements;

    // VK_AMD_draw_indirect_count
    alias vkCmdDrawIndirectCountAMD                                               = vkCmdDrawIndirectCount;
    alias vkCmdDrawIndexedIndirectCountAMD                                        = vkCmdDrawIndexedIndirectCount;

    // VK_NV_ray_tracing
    alias vkGetRayTracingShaderGroupHandlesNV                                     = vkGetRayTracingShaderGroupHandlesKHR;

    // VK_EXT_buffer_device_address
    alias vkGetBufferDeviceAddressEXT                                             = vkGetBufferDeviceAddress;

    // VK_EXT_tooling_info
    alias vkGetPhysicalDeviceToolPropertiesEXT                                    = vkGetPhysicalDeviceToolProperties;

    // VK_EXT_host_query_reset
    alias vkResetQueryPoolEXT                                                     = vkResetQueryPool;

    // VK_EXT_extended_dynamic_state
    alias vkCmdSetCullModeEXT                                                     = vkCmdSetCullMode;
    alias vkCmdSetFrontFaceEXT                                                    = vkCmdSetFrontFace;
    alias vkCmdSetPrimitiveTopologyEXT                                            = vkCmdSetPrimitiveTopology;
    alias vkCmdSetViewportWithCountEXT                                            = vkCmdSetViewportWithCount;
    alias vkCmdSetScissorWithCountEXT                                             = vkCmdSetScissorWithCount;
    alias vkCmdBindVertexBuffers2EXT                                              = vkCmdBindVertexBuffers2;
    alias vkCmdSetDepthTestEnableEXT                                              = vkCmdSetDepthTestEnable;
    alias vkCmdSetDepthWriteEnableEXT                                             = vkCmdSetDepthWriteEnable;
    alias vkCmdSetDepthCompareOpEXT                                               = vkCmdSetDepthCompareOp;
    alias vkCmdSetDepthBoundsTestEnableEXT                                        = vkCmdSetDepthBoundsTestEnable;
    alias vkCmdSetStencilTestEnableEXT                                            = vkCmdSetStencilTestEnable;
    alias vkCmdSetStencilOpEXT                                                    = vkCmdSetStencilOp;

    // VK_EXT_private_data
    alias vkCreatePrivateDataSlotEXT                                              = vkCreatePrivateDataSlot;
    alias vkDestroyPrivateDataSlotEXT                                             = vkDestroyPrivateDataSlot;
    alias vkSetPrivateDataEXT                                                     = vkSetPrivateData;
    alias vkGetPrivateDataEXT                                                     = vkGetPrivateData;

    // VK_EXT_extended_dynamic_state2
    alias vkCmdSetRasterizerDiscardEnableEXT                                      = vkCmdSetRasterizerDiscardEnable;
    alias vkCmdSetDepthBiasEnableEXT                                              = vkCmdSetDepthBiasEnable;
    alias vkCmdSetPrimitiveRestartEnableEXT                                       = vkCmdSetPrimitiveRestartEnable;
}


/// sets vkCreateInstance function pointer and acquires basic functions to retrieve information about the implementation
/// and create an instance: vkEnumerateInstanceExtensionProperties, vkEnumerateInstanceLayerProperties, vkCreateInstance
void loadGlobalLevelFunctions( PFN_vkGetInstanceProcAddr getInstanceProcAddr ) {
    vkGetInstanceProcAddr = getInstanceProcAddr;

    // VK_VERSION_1_0
    vkCreateInstance                       = cast( PFN_vkCreateInstance                       ) vkGetInstanceProcAddr( null, "vkCreateInstance" );
    vkEnumerateInstanceExtensionProperties = cast( PFN_vkEnumerateInstanceExtensionProperties ) vkGetInstanceProcAddr( null, "vkEnumerateInstanceExtensionProperties" );
    vkEnumerateInstanceLayerProperties     = cast( PFN_vkEnumerateInstanceLayerProperties     ) vkGetInstanceProcAddr( null, "vkEnumerateInstanceLayerProperties" );

    // VK_VERSION_1_1
    vkEnumerateInstanceVersion             = cast( PFN_vkEnumerateInstanceVersion             ) vkGetInstanceProcAddr( null, "vkEnumerateInstanceVersion" );
}


/// with a valid VkInstance call this function to retrieve additional VkInstance, VkPhysicalDevice, ... related functions
void loadInstanceLevelFunctions( VkInstance instance ) {
    assert( vkGetInstanceProcAddr !is null, "Function pointer vkGetInstanceProcAddr is null!\nCall loadGlobalLevelFunctions -> loadInstanceLevelFunctions" );

    // VK_VERSION_1_0
    vkDestroyInstance                                                 = cast( PFN_vkDestroyInstance                                                 ) vkGetInstanceProcAddr( instance, "vkDestroyInstance" );
    vkEnumeratePhysicalDevices                                        = cast( PFN_vkEnumeratePhysicalDevices                                        ) vkGetInstanceProcAddr( instance, "vkEnumeratePhysicalDevices" );
    vkGetPhysicalDeviceFeatures                                       = cast( PFN_vkGetPhysicalDeviceFeatures                                       ) vkGetInstanceProcAddr( instance, "vkGetPhysicalDeviceFeatures" );
    vkGetPhysicalDeviceFormatProperties                               = cast( PFN_vkGetPhysicalDeviceFormatProperties                               ) vkGetInstanceProcAddr( instance, "vkGetPhysicalDeviceFormatProperties" );
    vkGetPhysicalDeviceImageFormatProperties                          = cast( PFN_vkGetPhysicalDeviceImageFormatProperties                          ) vkGetInstanceProcAddr( instance, "vkGetPhysicalDeviceImageFormatProperties" );
    vkGetPhysicalDeviceProperties                                     = cast( PFN_vkGetPhysicalDeviceProperties                                     ) vkGetInstanceProcAddr( instance, "vkGetPhysicalDeviceProperties" );
    vkGetPhysicalDeviceQueueFamilyProperties                          = cast( PFN_vkGetPhysicalDeviceQueueFamilyProperties                          ) vkGetInstanceProcAddr( instance, "vkGetPhysicalDeviceQueueFamilyProperties" );
    vkGetPhysicalDeviceMemoryProperties                               = cast( PFN_vkGetPhysicalDeviceMemoryProperties                               ) vkGetInstanceProcAddr( instance, "vkGetPhysicalDeviceMemoryProperties" );
    vkGetDeviceProcAddr                                               = cast( PFN_vkGetDeviceProcAddr                                               ) vkGetInstanceProcAddr( instance, "vkGetDeviceProcAddr" );
    vkCreateDevice                                                    = cast( PFN_vkCreateDevice                                                    ) vkGetInstanceProcAddr( instance, "vkCreateDevice" );
    vkEnumerateDeviceExtensionProperties                              = cast( PFN_vkEnumerateDeviceExtensionProperties                              ) vkGetInstanceProcAddr( instance, "vkEnumerateDeviceExtensionProperties" );
    vkEnumerateDeviceLayerProperties                                  = cast( PFN_vkEnumerateDeviceLayerProperties                                  ) vkGetInstanceProcAddr( instance, "vkEnumerateDeviceLayerProperties" );
    vkGetPhysicalDeviceSparseImageFormatProperties                    = cast( PFN_vkGetPhysicalDeviceSparseImageFormatProperties                    ) vkGetInstanceProcAddr( instance, "vkGetPhysicalDeviceSparseImageFormatProperties" );

    // VK_VERSION_1_1
    vkEnumeratePhysicalDeviceGroups                                   = cast( PFN_vkEnumeratePhysicalDeviceGroups                                   ) vkGetInstanceProcAddr( instance, "vkEnumeratePhysicalDeviceGroups" );
    vkGetPhysicalDeviceFeatures2                                      = cast( PFN_vkGetPhysicalDeviceFeatures2                                      ) vkGetInstanceProcAddr( instance, "vkGetPhysicalDeviceFeatures2" );
    vkGetPhysicalDeviceProperties2                                    = cast( PFN_vkGetPhysicalDeviceProperties2                                    ) vkGetInstanceProcAddr( instance, "vkGetPhysicalDeviceProperties2" );
    vkGetPhysicalDeviceFormatProperties2                              = cast( PFN_vkGetPhysicalDeviceFormatProperties2                              ) vkGetInstanceProcAddr( instance, "vkGetPhysicalDeviceFormatProperties2" );
    vkGetPhysicalDeviceImageFormatProperties2                         = cast( PFN_vkGetPhysicalDeviceImageFormatProperties2                         ) vkGetInstanceProcAddr( instance, "vkGetPhysicalDeviceImageFormatProperties2" );
    vkGetPhysicalDeviceQueueFamilyProperties2                         = cast( PFN_vkGetPhysicalDeviceQueueFamilyProperties2                         ) vkGetInstanceProcAddr( instance, "vkGetPhysicalDeviceQueueFamilyProperties2" );
    vkGetPhysicalDeviceMemoryProperties2                              = cast( PFN_vkGetPhysicalDeviceMemoryProperties2                              ) vkGetInstanceProcAddr( instance, "vkGetPhysicalDeviceMemoryProperties2" );
    vkGetPhysicalDeviceSparseImageFormatProperties2                   = cast( PFN_vkGetPhysicalDeviceSparseImageFormatProperties2                   ) vkGetInstanceProcAddr( instance, "vkGetPhysicalDeviceSparseImageFormatProperties2" );
    vkGetPhysicalDeviceExternalBufferProperties                       = cast( PFN_vkGetPhysicalDeviceExternalBufferProperties                       ) vkGetInstanceProcAddr( instance, "vkGetPhysicalDeviceExternalBufferProperties" );
    vkGetPhysicalDeviceExternalFenceProperties                        = cast( PFN_vkGetPhysicalDeviceExternalFenceProperties                        ) vkGetInstanceProcAddr( instance, "vkGetPhysicalDeviceExternalFenceProperties" );
    vkGetPhysicalDeviceExternalSemaphoreProperties                    = cast( PFN_vkGetPhysicalDeviceExternalSemaphoreProperties                    ) vkGetInstanceProcAddr( instance, "vkGetPhysicalDeviceExternalSemaphoreProperties" );

    // VK_VERSION_1_3
    vkGetPhysicalDeviceToolProperties                                 = cast( PFN_vkGetPhysicalDeviceToolProperties                                 ) vkGetInstanceProcAddr( instance, "vkGetPhysicalDeviceToolProperties" );

    // VK_KHR_surface
    vkDestroySurfaceKHR                                               = cast( PFN_vkDestroySurfaceKHR                                               ) vkGetInstanceProcAddr( instance, "vkDestroySurfaceKHR" );
    vkGetPhysicalDeviceSurfaceSupportKHR                              = cast( PFN_vkGetPhysicalDeviceSurfaceSupportKHR                              ) vkGetInstanceProcAddr( instance, "vkGetPhysicalDeviceSurfaceSupportKHR" );
    vkGetPhysicalDeviceSurfaceCapabilitiesKHR                         = cast( PFN_vkGetPhysicalDeviceSurfaceCapabilitiesKHR                         ) vkGetInstanceProcAddr( instance, "vkGetPhysicalDeviceSurfaceCapabilitiesKHR" );
    vkGetPhysicalDeviceSurfaceFormatsKHR                              = cast( PFN_vkGetPhysicalDeviceSurfaceFormatsKHR                              ) vkGetInstanceProcAddr( instance, "vkGetPhysicalDeviceSurfaceFormatsKHR" );
    vkGetPhysicalDeviceSurfacePresentModesKHR                         = cast( PFN_vkGetPhysicalDeviceSurfacePresentModesKHR                         ) vkGetInstanceProcAddr( instance, "vkGetPhysicalDeviceSurfacePresentModesKHR" );

    // VK_KHR_swapchain
    vkGetPhysicalDevicePresentRectanglesKHR                           = cast( PFN_vkGetPhysicalDevicePresentRectanglesKHR                           ) vkGetInstanceProcAddr( instance, "vkGetPhysicalDevicePresentRectanglesKHR" );

    // VK_KHR_display
    vkGetPhysicalDeviceDisplayPropertiesKHR                           = cast( PFN_vkGetPhysicalDeviceDisplayPropertiesKHR                           ) vkGetInstanceProcAddr( instance, "vkGetPhysicalDeviceDisplayPropertiesKHR" );
    vkGetPhysicalDeviceDisplayPlanePropertiesKHR                      = cast( PFN_vkGetPhysicalDeviceDisplayPlanePropertiesKHR                      ) vkGetInstanceProcAddr( instance, "vkGetPhysicalDeviceDisplayPlanePropertiesKHR" );
    vkGetDisplayPlaneSupportedDisplaysKHR                             = cast( PFN_vkGetDisplayPlaneSupportedDisplaysKHR                             ) vkGetInstanceProcAddr( instance, "vkGetDisplayPlaneSupportedDisplaysKHR" );
    vkGetDisplayModePropertiesKHR                                     = cast( PFN_vkGetDisplayModePropertiesKHR                                     ) vkGetInstanceProcAddr( instance, "vkGetDisplayModePropertiesKHR" );
    vkCreateDisplayModeKHR                                            = cast( PFN_vkCreateDisplayModeKHR                                            ) vkGetInstanceProcAddr( instance, "vkCreateDisplayModeKHR" );
    vkGetDisplayPlaneCapabilitiesKHR                                  = cast( PFN_vkGetDisplayPlaneCapabilitiesKHR                                  ) vkGetInstanceProcAddr( instance, "vkGetDisplayPlaneCapabilitiesKHR" );
    vkCreateDisplayPlaneSurfaceKHR                                    = cast( PFN_vkCreateDisplayPlaneSurfaceKHR                                    ) vkGetInstanceProcAddr( instance, "vkCreateDisplayPlaneSurfaceKHR" );

    // VK_KHR_performance_query
    vkEnumeratePhysicalDeviceQueueFamilyPerformanceQueryCountersKHR   = cast( PFN_vkEnumeratePhysicalDeviceQueueFamilyPerformanceQueryCountersKHR   ) vkGetInstanceProcAddr( instance, "vkEnumeratePhysicalDeviceQueueFamilyPerformanceQueryCountersKHR" );
    vkGetPhysicalDeviceQueueFamilyPerformanceQueryPassesKHR           = cast( PFN_vkGetPhysicalDeviceQueueFamilyPerformanceQueryPassesKHR           ) vkGetInstanceProcAddr( instance, "vkGetPhysicalDeviceQueueFamilyPerformanceQueryPassesKHR" );

    // VK_KHR_get_surface_capabilities2
    vkGetPhysicalDeviceSurfaceCapabilities2KHR                        = cast( PFN_vkGetPhysicalDeviceSurfaceCapabilities2KHR                        ) vkGetInstanceProcAddr( instance, "vkGetPhysicalDeviceSurfaceCapabilities2KHR" );
    vkGetPhysicalDeviceSurfaceFormats2KHR                             = cast( PFN_vkGetPhysicalDeviceSurfaceFormats2KHR                             ) vkGetInstanceProcAddr( instance, "vkGetPhysicalDeviceSurfaceFormats2KHR" );

    // VK_KHR_get_display_properties2
    vkGetPhysicalDeviceDisplayProperties2KHR                          = cast( PFN_vkGetPhysicalDeviceDisplayProperties2KHR                          ) vkGetInstanceProcAddr( instance, "vkGetPhysicalDeviceDisplayProperties2KHR" );
    vkGetPhysicalDeviceDisplayPlaneProperties2KHR                     = cast( PFN_vkGetPhysicalDeviceDisplayPlaneProperties2KHR                     ) vkGetInstanceProcAddr( instance, "vkGetPhysicalDeviceDisplayPlaneProperties2KHR" );
    vkGetDisplayModeProperties2KHR                                    = cast( PFN_vkGetDisplayModeProperties2KHR                                    ) vkGetInstanceProcAddr( instance, "vkGetDisplayModeProperties2KHR" );
    vkGetDisplayPlaneCapabilities2KHR                                 = cast( PFN_vkGetDisplayPlaneCapabilities2KHR                                 ) vkGetInstanceProcAddr( instance, "vkGetDisplayPlaneCapabilities2KHR" );

    // VK_KHR_fragment_shading_rate
    vkGetPhysicalDeviceFragmentShadingRatesKHR                        = cast( PFN_vkGetPhysicalDeviceFragmentShadingRatesKHR                        ) vkGetInstanceProcAddr( instance, "vkGetPhysicalDeviceFragmentShadingRatesKHR" );

    // VK_EXT_debug_report
    vkCreateDebugReportCallbackEXT                                    = cast( PFN_vkCreateDebugReportCallbackEXT                                    ) vkGetInstanceProcAddr( instance, "vkCreateDebugReportCallbackEXT" );
    vkDestroyDebugReportCallbackEXT                                   = cast( PFN_vkDestroyDebugReportCallbackEXT                                   ) vkGetInstanceProcAddr( instance, "vkDestroyDebugReportCallbackEXT" );
    vkDebugReportMessageEXT                                           = cast( PFN_vkDebugReportMessageEXT                                           ) vkGetInstanceProcAddr( instance, "vkDebugReportMessageEXT" );

    // VK_NV_external_memory_capabilities
    vkGetPhysicalDeviceExternalImageFormatPropertiesNV                = cast( PFN_vkGetPhysicalDeviceExternalImageFormatPropertiesNV                ) vkGetInstanceProcAddr( instance, "vkGetPhysicalDeviceExternalImageFormatPropertiesNV" );

    // VK_EXT_direct_mode_display
    vkReleaseDisplayEXT                                               = cast( PFN_vkReleaseDisplayEXT                                               ) vkGetInstanceProcAddr( instance, "vkReleaseDisplayEXT" );

    // VK_EXT_display_surface_counter
    vkGetPhysicalDeviceSurfaceCapabilities2EXT                        = cast( PFN_vkGetPhysicalDeviceSurfaceCapabilities2EXT                        ) vkGetInstanceProcAddr( instance, "vkGetPhysicalDeviceSurfaceCapabilities2EXT" );

    // VK_EXT_debug_utils
    vkCreateDebugUtilsMessengerEXT                                    = cast( PFN_vkCreateDebugUtilsMessengerEXT                                    ) vkGetInstanceProcAddr( instance, "vkCreateDebugUtilsMessengerEXT" );
    vkDestroyDebugUtilsMessengerEXT                                   = cast( PFN_vkDestroyDebugUtilsMessengerEXT                                   ) vkGetInstanceProcAddr( instance, "vkDestroyDebugUtilsMessengerEXT" );
    vkSubmitDebugUtilsMessageEXT                                      = cast( PFN_vkSubmitDebugUtilsMessageEXT                                      ) vkGetInstanceProcAddr( instance, "vkSubmitDebugUtilsMessageEXT" );

    // VK_EXT_sample_locations
    vkGetPhysicalDeviceMultisamplePropertiesEXT                       = cast( PFN_vkGetPhysicalDeviceMultisamplePropertiesEXT                       ) vkGetInstanceProcAddr( instance, "vkGetPhysicalDeviceMultisamplePropertiesEXT" );

    // VK_EXT_calibrated_timestamps
    vkGetPhysicalDeviceCalibrateableTimeDomainsEXT                    = cast( PFN_vkGetPhysicalDeviceCalibrateableTimeDomainsEXT                    ) vkGetInstanceProcAddr( instance, "vkGetPhysicalDeviceCalibrateableTimeDomainsEXT" );

    // VK_NV_cooperative_matrix
    vkGetPhysicalDeviceCooperativeMatrixPropertiesNV                  = cast( PFN_vkGetPhysicalDeviceCooperativeMatrixPropertiesNV                  ) vkGetInstanceProcAddr( instance, "vkGetPhysicalDeviceCooperativeMatrixPropertiesNV" );

    // VK_NV_coverage_reduction_mode
    vkGetPhysicalDeviceSupportedFramebufferMixedSamplesCombinationsNV = cast( PFN_vkGetPhysicalDeviceSupportedFramebufferMixedSamplesCombinationsNV ) vkGetInstanceProcAddr( instance, "vkGetPhysicalDeviceSupportedFramebufferMixedSamplesCombinationsNV" );

    // VK_EXT_headless_surface
    vkCreateHeadlessSurfaceEXT                                        = cast( PFN_vkCreateHeadlessSurfaceEXT                                        ) vkGetInstanceProcAddr( instance, "vkCreateHeadlessSurfaceEXT" );

    // VK_EXT_acquire_drm_display
    vkAcquireDrmDisplayEXT                                            = cast( PFN_vkAcquireDrmDisplayEXT                                            ) vkGetInstanceProcAddr( instance, "vkAcquireDrmDisplayEXT" );
    vkGetDrmDisplayEXT                                                = cast( PFN_vkGetDrmDisplayEXT                                                ) vkGetInstanceProcAddr( instance, "vkGetDrmDisplayEXT" );
}


/// with a valid VkInstance call this function to retrieve VkDevice, VkQueue and VkCommandBuffer related functions
/// the functions call indirectly through the VkInstance and will be internally dispatched by the implementation
/// use loadDeviceLevelFunctions( VkDevice device ) bellow to avoid this indirection and get the pointers directly form a VkDevice
void loadDeviceLevelFunctions( VkInstance instance ) {
    assert( vkGetInstanceProcAddr !is null, "Function pointer vkGetInstanceProcAddr is null!\nCall loadGlobalLevelFunctions -> loadDeviceLevelFunctions( instance )" );

    // VK_VERSION_1_0
    vkDestroyDevice                                   = cast( PFN_vkDestroyDevice                                   ) vkGetInstanceProcAddr( instance, "vkDestroyDevice" );
    vkGetDeviceQueue                                  = cast( PFN_vkGetDeviceQueue                                  ) vkGetInstanceProcAddr( instance, "vkGetDeviceQueue" );
    vkQueueSubmit                                     = cast( PFN_vkQueueSubmit                                     ) vkGetInstanceProcAddr( instance, "vkQueueSubmit" );
    vkQueueWaitIdle                                   = cast( PFN_vkQueueWaitIdle                                   ) vkGetInstanceProcAddr( instance, "vkQueueWaitIdle" );
    vkDeviceWaitIdle                                  = cast( PFN_vkDeviceWaitIdle                                  ) vkGetInstanceProcAddr( instance, "vkDeviceWaitIdle" );
    vkAllocateMemory                                  = cast( PFN_vkAllocateMemory                                  ) vkGetInstanceProcAddr( instance, "vkAllocateMemory" );
    vkFreeMemory                                      = cast( PFN_vkFreeMemory                                      ) vkGetInstanceProcAddr( instance, "vkFreeMemory" );
    vkMapMemory                                       = cast( PFN_vkMapMemory                                       ) vkGetInstanceProcAddr( instance, "vkMapMemory" );
    vkUnmapMemory                                     = cast( PFN_vkUnmapMemory                                     ) vkGetInstanceProcAddr( instance, "vkUnmapMemory" );
    vkFlushMappedMemoryRanges                         = cast( PFN_vkFlushMappedMemoryRanges                         ) vkGetInstanceProcAddr( instance, "vkFlushMappedMemoryRanges" );
    vkInvalidateMappedMemoryRanges                    = cast( PFN_vkInvalidateMappedMemoryRanges                    ) vkGetInstanceProcAddr( instance, "vkInvalidateMappedMemoryRanges" );
    vkGetDeviceMemoryCommitment                       = cast( PFN_vkGetDeviceMemoryCommitment                       ) vkGetInstanceProcAddr( instance, "vkGetDeviceMemoryCommitment" );
    vkBindBufferMemory                                = cast( PFN_vkBindBufferMemory                                ) vkGetInstanceProcAddr( instance, "vkBindBufferMemory" );
    vkBindImageMemory                                 = cast( PFN_vkBindImageMemory                                 ) vkGetInstanceProcAddr( instance, "vkBindImageMemory" );
    vkGetBufferMemoryRequirements                     = cast( PFN_vkGetBufferMemoryRequirements                     ) vkGetInstanceProcAddr( instance, "vkGetBufferMemoryRequirements" );
    vkGetImageMemoryRequirements                      = cast( PFN_vkGetImageMemoryRequirements                      ) vkGetInstanceProcAddr( instance, "vkGetImageMemoryRequirements" );
    vkGetImageSparseMemoryRequirements                = cast( PFN_vkGetImageSparseMemoryRequirements                ) vkGetInstanceProcAddr( instance, "vkGetImageSparseMemoryRequirements" );
    vkQueueBindSparse                                 = cast( PFN_vkQueueBindSparse                                 ) vkGetInstanceProcAddr( instance, "vkQueueBindSparse" );
    vkCreateFence                                     = cast( PFN_vkCreateFence                                     ) vkGetInstanceProcAddr( instance, "vkCreateFence" );
    vkDestroyFence                                    = cast( PFN_vkDestroyFence                                    ) vkGetInstanceProcAddr( instance, "vkDestroyFence" );
    vkResetFences                                     = cast( PFN_vkResetFences                                     ) vkGetInstanceProcAddr( instance, "vkResetFences" );
    vkGetFenceStatus                                  = cast( PFN_vkGetFenceStatus                                  ) vkGetInstanceProcAddr( instance, "vkGetFenceStatus" );
    vkWaitForFences                                   = cast( PFN_vkWaitForFences                                   ) vkGetInstanceProcAddr( instance, "vkWaitForFences" );
    vkCreateSemaphore                                 = cast( PFN_vkCreateSemaphore                                 ) vkGetInstanceProcAddr( instance, "vkCreateSemaphore" );
    vkDestroySemaphore                                = cast( PFN_vkDestroySemaphore                                ) vkGetInstanceProcAddr( instance, "vkDestroySemaphore" );
    vkCreateEvent                                     = cast( PFN_vkCreateEvent                                     ) vkGetInstanceProcAddr( instance, "vkCreateEvent" );
    vkDestroyEvent                                    = cast( PFN_vkDestroyEvent                                    ) vkGetInstanceProcAddr( instance, "vkDestroyEvent" );
    vkGetEventStatus                                  = cast( PFN_vkGetEventStatus                                  ) vkGetInstanceProcAddr( instance, "vkGetEventStatus" );
    vkSetEvent                                        = cast( PFN_vkSetEvent                                        ) vkGetInstanceProcAddr( instance, "vkSetEvent" );
    vkResetEvent                                      = cast( PFN_vkResetEvent                                      ) vkGetInstanceProcAddr( instance, "vkResetEvent" );
    vkCreateQueryPool                                 = cast( PFN_vkCreateQueryPool                                 ) vkGetInstanceProcAddr( instance, "vkCreateQueryPool" );
    vkDestroyQueryPool                                = cast( PFN_vkDestroyQueryPool                                ) vkGetInstanceProcAddr( instance, "vkDestroyQueryPool" );
    vkGetQueryPoolResults                             = cast( PFN_vkGetQueryPoolResults                             ) vkGetInstanceProcAddr( instance, "vkGetQueryPoolResults" );
    vkCreateBuffer                                    = cast( PFN_vkCreateBuffer                                    ) vkGetInstanceProcAddr( instance, "vkCreateBuffer" );
    vkDestroyBuffer                                   = cast( PFN_vkDestroyBuffer                                   ) vkGetInstanceProcAddr( instance, "vkDestroyBuffer" );
    vkCreateBufferView                                = cast( PFN_vkCreateBufferView                                ) vkGetInstanceProcAddr( instance, "vkCreateBufferView" );
    vkDestroyBufferView                               = cast( PFN_vkDestroyBufferView                               ) vkGetInstanceProcAddr( instance, "vkDestroyBufferView" );
    vkCreateImage                                     = cast( PFN_vkCreateImage                                     ) vkGetInstanceProcAddr( instance, "vkCreateImage" );
    vkDestroyImage                                    = cast( PFN_vkDestroyImage                                    ) vkGetInstanceProcAddr( instance, "vkDestroyImage" );
    vkGetImageSubresourceLayout                       = cast( PFN_vkGetImageSubresourceLayout                       ) vkGetInstanceProcAddr( instance, "vkGetImageSubresourceLayout" );
    vkCreateImageView                                 = cast( PFN_vkCreateImageView                                 ) vkGetInstanceProcAddr( instance, "vkCreateImageView" );
    vkDestroyImageView                                = cast( PFN_vkDestroyImageView                                ) vkGetInstanceProcAddr( instance, "vkDestroyImageView" );
    vkCreateShaderModule                              = cast( PFN_vkCreateShaderModule                              ) vkGetInstanceProcAddr( instance, "vkCreateShaderModule" );
    vkDestroyShaderModule                             = cast( PFN_vkDestroyShaderModule                             ) vkGetInstanceProcAddr( instance, "vkDestroyShaderModule" );
    vkCreatePipelineCache                             = cast( PFN_vkCreatePipelineCache                             ) vkGetInstanceProcAddr( instance, "vkCreatePipelineCache" );
    vkDestroyPipelineCache                            = cast( PFN_vkDestroyPipelineCache                            ) vkGetInstanceProcAddr( instance, "vkDestroyPipelineCache" );
    vkGetPipelineCacheData                            = cast( PFN_vkGetPipelineCacheData                            ) vkGetInstanceProcAddr( instance, "vkGetPipelineCacheData" );
    vkMergePipelineCaches                             = cast( PFN_vkMergePipelineCaches                             ) vkGetInstanceProcAddr( instance, "vkMergePipelineCaches" );
    vkCreateGraphicsPipelines                         = cast( PFN_vkCreateGraphicsPipelines                         ) vkGetInstanceProcAddr( instance, "vkCreateGraphicsPipelines" );
    vkCreateComputePipelines                          = cast( PFN_vkCreateComputePipelines                          ) vkGetInstanceProcAddr( instance, "vkCreateComputePipelines" );
    vkDestroyPipeline                                 = cast( PFN_vkDestroyPipeline                                 ) vkGetInstanceProcAddr( instance, "vkDestroyPipeline" );
    vkCreatePipelineLayout                            = cast( PFN_vkCreatePipelineLayout                            ) vkGetInstanceProcAddr( instance, "vkCreatePipelineLayout" );
    vkDestroyPipelineLayout                           = cast( PFN_vkDestroyPipelineLayout                           ) vkGetInstanceProcAddr( instance, "vkDestroyPipelineLayout" );
    vkCreateSampler                                   = cast( PFN_vkCreateSampler                                   ) vkGetInstanceProcAddr( instance, "vkCreateSampler" );
    vkDestroySampler                                  = cast( PFN_vkDestroySampler                                  ) vkGetInstanceProcAddr( instance, "vkDestroySampler" );
    vkCreateDescriptorSetLayout                       = cast( PFN_vkCreateDescriptorSetLayout                       ) vkGetInstanceProcAddr( instance, "vkCreateDescriptorSetLayout" );
    vkDestroyDescriptorSetLayout                      = cast( PFN_vkDestroyDescriptorSetLayout                      ) vkGetInstanceProcAddr( instance, "vkDestroyDescriptorSetLayout" );
    vkCreateDescriptorPool                            = cast( PFN_vkCreateDescriptorPool                            ) vkGetInstanceProcAddr( instance, "vkCreateDescriptorPool" );
    vkDestroyDescriptorPool                           = cast( PFN_vkDestroyDescriptorPool                           ) vkGetInstanceProcAddr( instance, "vkDestroyDescriptorPool" );
    vkResetDescriptorPool                             = cast( PFN_vkResetDescriptorPool                             ) vkGetInstanceProcAddr( instance, "vkResetDescriptorPool" );
    vkAllocateDescriptorSets                          = cast( PFN_vkAllocateDescriptorSets                          ) vkGetInstanceProcAddr( instance, "vkAllocateDescriptorSets" );
    vkFreeDescriptorSets                              = cast( PFN_vkFreeDescriptorSets                              ) vkGetInstanceProcAddr( instance, "vkFreeDescriptorSets" );
    vkUpdateDescriptorSets                            = cast( PFN_vkUpdateDescriptorSets                            ) vkGetInstanceProcAddr( instance, "vkUpdateDescriptorSets" );
    vkCreateFramebuffer                               = cast( PFN_vkCreateFramebuffer                               ) vkGetInstanceProcAddr( instance, "vkCreateFramebuffer" );
    vkDestroyFramebuffer                              = cast( PFN_vkDestroyFramebuffer                              ) vkGetInstanceProcAddr( instance, "vkDestroyFramebuffer" );
    vkCreateRenderPass                                = cast( PFN_vkCreateRenderPass                                ) vkGetInstanceProcAddr( instance, "vkCreateRenderPass" );
    vkDestroyRenderPass                               = cast( PFN_vkDestroyRenderPass                               ) vkGetInstanceProcAddr( instance, "vkDestroyRenderPass" );
    vkGetRenderAreaGranularity                        = cast( PFN_vkGetRenderAreaGranularity                        ) vkGetInstanceProcAddr( instance, "vkGetRenderAreaGranularity" );
    vkCreateCommandPool                               = cast( PFN_vkCreateCommandPool                               ) vkGetInstanceProcAddr( instance, "vkCreateCommandPool" );
    vkDestroyCommandPool                              = cast( PFN_vkDestroyCommandPool                              ) vkGetInstanceProcAddr( instance, "vkDestroyCommandPool" );
    vkResetCommandPool                                = cast( PFN_vkResetCommandPool                                ) vkGetInstanceProcAddr( instance, "vkResetCommandPool" );
    vkAllocateCommandBuffers                          = cast( PFN_vkAllocateCommandBuffers                          ) vkGetInstanceProcAddr( instance, "vkAllocateCommandBuffers" );
    vkFreeCommandBuffers                              = cast( PFN_vkFreeCommandBuffers                              ) vkGetInstanceProcAddr( instance, "vkFreeCommandBuffers" );
    vkBeginCommandBuffer                              = cast( PFN_vkBeginCommandBuffer                              ) vkGetInstanceProcAddr( instance, "vkBeginCommandBuffer" );
    vkEndCommandBuffer                                = cast( PFN_vkEndCommandBuffer                                ) vkGetInstanceProcAddr( instance, "vkEndCommandBuffer" );
    vkResetCommandBuffer                              = cast( PFN_vkResetCommandBuffer                              ) vkGetInstanceProcAddr( instance, "vkResetCommandBuffer" );
    vkCmdBindPipeline                                 = cast( PFN_vkCmdBindPipeline                                 ) vkGetInstanceProcAddr( instance, "vkCmdBindPipeline" );
    vkCmdSetViewport                                  = cast( PFN_vkCmdSetViewport                                  ) vkGetInstanceProcAddr( instance, "vkCmdSetViewport" );
    vkCmdSetScissor                                   = cast( PFN_vkCmdSetScissor                                   ) vkGetInstanceProcAddr( instance, "vkCmdSetScissor" );
    vkCmdSetLineWidth                                 = cast( PFN_vkCmdSetLineWidth                                 ) vkGetInstanceProcAddr( instance, "vkCmdSetLineWidth" );
    vkCmdSetDepthBias                                 = cast( PFN_vkCmdSetDepthBias                                 ) vkGetInstanceProcAddr( instance, "vkCmdSetDepthBias" );
    vkCmdSetBlendConstants                            = cast( PFN_vkCmdSetBlendConstants                            ) vkGetInstanceProcAddr( instance, "vkCmdSetBlendConstants" );
    vkCmdSetDepthBounds                               = cast( PFN_vkCmdSetDepthBounds                               ) vkGetInstanceProcAddr( instance, "vkCmdSetDepthBounds" );
    vkCmdSetStencilCompareMask                        = cast( PFN_vkCmdSetStencilCompareMask                        ) vkGetInstanceProcAddr( instance, "vkCmdSetStencilCompareMask" );
    vkCmdSetStencilWriteMask                          = cast( PFN_vkCmdSetStencilWriteMask                          ) vkGetInstanceProcAddr( instance, "vkCmdSetStencilWriteMask" );
    vkCmdSetStencilReference                          = cast( PFN_vkCmdSetStencilReference                          ) vkGetInstanceProcAddr( instance, "vkCmdSetStencilReference" );
    vkCmdBindDescriptorSets                           = cast( PFN_vkCmdBindDescriptorSets                           ) vkGetInstanceProcAddr( instance, "vkCmdBindDescriptorSets" );
    vkCmdBindIndexBuffer                              = cast( PFN_vkCmdBindIndexBuffer                              ) vkGetInstanceProcAddr( instance, "vkCmdBindIndexBuffer" );
    vkCmdBindVertexBuffers                            = cast( PFN_vkCmdBindVertexBuffers                            ) vkGetInstanceProcAddr( instance, "vkCmdBindVertexBuffers" );
    vkCmdDraw                                         = cast( PFN_vkCmdDraw                                         ) vkGetInstanceProcAddr( instance, "vkCmdDraw" );
    vkCmdDrawIndexed                                  = cast( PFN_vkCmdDrawIndexed                                  ) vkGetInstanceProcAddr( instance, "vkCmdDrawIndexed" );
    vkCmdDrawIndirect                                 = cast( PFN_vkCmdDrawIndirect                                 ) vkGetInstanceProcAddr( instance, "vkCmdDrawIndirect" );
    vkCmdDrawIndexedIndirect                          = cast( PFN_vkCmdDrawIndexedIndirect                          ) vkGetInstanceProcAddr( instance, "vkCmdDrawIndexedIndirect" );
    vkCmdDispatch                                     = cast( PFN_vkCmdDispatch                                     ) vkGetInstanceProcAddr( instance, "vkCmdDispatch" );
    vkCmdDispatchIndirect                             = cast( PFN_vkCmdDispatchIndirect                             ) vkGetInstanceProcAddr( instance, "vkCmdDispatchIndirect" );
    vkCmdCopyBuffer                                   = cast( PFN_vkCmdCopyBuffer                                   ) vkGetInstanceProcAddr( instance, "vkCmdCopyBuffer" );
    vkCmdCopyImage                                    = cast( PFN_vkCmdCopyImage                                    ) vkGetInstanceProcAddr( instance, "vkCmdCopyImage" );
    vkCmdBlitImage                                    = cast( PFN_vkCmdBlitImage                                    ) vkGetInstanceProcAddr( instance, "vkCmdBlitImage" );
    vkCmdCopyBufferToImage                            = cast( PFN_vkCmdCopyBufferToImage                            ) vkGetInstanceProcAddr( instance, "vkCmdCopyBufferToImage" );
    vkCmdCopyImageToBuffer                            = cast( PFN_vkCmdCopyImageToBuffer                            ) vkGetInstanceProcAddr( instance, "vkCmdCopyImageToBuffer" );
    vkCmdUpdateBuffer                                 = cast( PFN_vkCmdUpdateBuffer                                 ) vkGetInstanceProcAddr( instance, "vkCmdUpdateBuffer" );
    vkCmdFillBuffer                                   = cast( PFN_vkCmdFillBuffer                                   ) vkGetInstanceProcAddr( instance, "vkCmdFillBuffer" );
    vkCmdClearColorImage                              = cast( PFN_vkCmdClearColorImage                              ) vkGetInstanceProcAddr( instance, "vkCmdClearColorImage" );
    vkCmdClearDepthStencilImage                       = cast( PFN_vkCmdClearDepthStencilImage                       ) vkGetInstanceProcAddr( instance, "vkCmdClearDepthStencilImage" );
    vkCmdClearAttachments                             = cast( PFN_vkCmdClearAttachments                             ) vkGetInstanceProcAddr( instance, "vkCmdClearAttachments" );
    vkCmdResolveImage                                 = cast( PFN_vkCmdResolveImage                                 ) vkGetInstanceProcAddr( instance, "vkCmdResolveImage" );
    vkCmdSetEvent                                     = cast( PFN_vkCmdSetEvent                                     ) vkGetInstanceProcAddr( instance, "vkCmdSetEvent" );
    vkCmdResetEvent                                   = cast( PFN_vkCmdResetEvent                                   ) vkGetInstanceProcAddr( instance, "vkCmdResetEvent" );
    vkCmdWaitEvents                                   = cast( PFN_vkCmdWaitEvents                                   ) vkGetInstanceProcAddr( instance, "vkCmdWaitEvents" );
    vkCmdPipelineBarrier                              = cast( PFN_vkCmdPipelineBarrier                              ) vkGetInstanceProcAddr( instance, "vkCmdPipelineBarrier" );
    vkCmdBeginQuery                                   = cast( PFN_vkCmdBeginQuery                                   ) vkGetInstanceProcAddr( instance, "vkCmdBeginQuery" );
    vkCmdEndQuery                                     = cast( PFN_vkCmdEndQuery                                     ) vkGetInstanceProcAddr( instance, "vkCmdEndQuery" );
    vkCmdResetQueryPool                               = cast( PFN_vkCmdResetQueryPool                               ) vkGetInstanceProcAddr( instance, "vkCmdResetQueryPool" );
    vkCmdWriteTimestamp                               = cast( PFN_vkCmdWriteTimestamp                               ) vkGetInstanceProcAddr( instance, "vkCmdWriteTimestamp" );
    vkCmdCopyQueryPoolResults                         = cast( PFN_vkCmdCopyQueryPoolResults                         ) vkGetInstanceProcAddr( instance, "vkCmdCopyQueryPoolResults" );
    vkCmdPushConstants                                = cast( PFN_vkCmdPushConstants                                ) vkGetInstanceProcAddr( instance, "vkCmdPushConstants" );
    vkCmdBeginRenderPass                              = cast( PFN_vkCmdBeginRenderPass                              ) vkGetInstanceProcAddr( instance, "vkCmdBeginRenderPass" );
    vkCmdNextSubpass                                  = cast( PFN_vkCmdNextSubpass                                  ) vkGetInstanceProcAddr( instance, "vkCmdNextSubpass" );
    vkCmdEndRenderPass                                = cast( PFN_vkCmdEndRenderPass                                ) vkGetInstanceProcAddr( instance, "vkCmdEndRenderPass" );
    vkCmdExecuteCommands                              = cast( PFN_vkCmdExecuteCommands                              ) vkGetInstanceProcAddr( instance, "vkCmdExecuteCommands" );

    // VK_VERSION_1_1
    vkBindBufferMemory2                               = cast( PFN_vkBindBufferMemory2                               ) vkGetInstanceProcAddr( instance, "vkBindBufferMemory2" );
    vkBindImageMemory2                                = cast( PFN_vkBindImageMemory2                                ) vkGetInstanceProcAddr( instance, "vkBindImageMemory2" );
    vkGetDeviceGroupPeerMemoryFeatures                = cast( PFN_vkGetDeviceGroupPeerMemoryFeatures                ) vkGetInstanceProcAddr( instance, "vkGetDeviceGroupPeerMemoryFeatures" );
    vkCmdSetDeviceMask                                = cast( PFN_vkCmdSetDeviceMask                                ) vkGetInstanceProcAddr( instance, "vkCmdSetDeviceMask" );
    vkCmdDispatchBase                                 = cast( PFN_vkCmdDispatchBase                                 ) vkGetInstanceProcAddr( instance, "vkCmdDispatchBase" );
    vkGetImageMemoryRequirements2                     = cast( PFN_vkGetImageMemoryRequirements2                     ) vkGetInstanceProcAddr( instance, "vkGetImageMemoryRequirements2" );
    vkGetBufferMemoryRequirements2                    = cast( PFN_vkGetBufferMemoryRequirements2                    ) vkGetInstanceProcAddr( instance, "vkGetBufferMemoryRequirements2" );
    vkGetImageSparseMemoryRequirements2               = cast( PFN_vkGetImageSparseMemoryRequirements2               ) vkGetInstanceProcAddr( instance, "vkGetImageSparseMemoryRequirements2" );
    vkTrimCommandPool                                 = cast( PFN_vkTrimCommandPool                                 ) vkGetInstanceProcAddr( instance, "vkTrimCommandPool" );
    vkGetDeviceQueue2                                 = cast( PFN_vkGetDeviceQueue2                                 ) vkGetInstanceProcAddr( instance, "vkGetDeviceQueue2" );
    vkCreateSamplerYcbcrConversion                    = cast( PFN_vkCreateSamplerYcbcrConversion                    ) vkGetInstanceProcAddr( instance, "vkCreateSamplerYcbcrConversion" );
    vkDestroySamplerYcbcrConversion                   = cast( PFN_vkDestroySamplerYcbcrConversion                   ) vkGetInstanceProcAddr( instance, "vkDestroySamplerYcbcrConversion" );
    vkCreateDescriptorUpdateTemplate                  = cast( PFN_vkCreateDescriptorUpdateTemplate                  ) vkGetInstanceProcAddr( instance, "vkCreateDescriptorUpdateTemplate" );
    vkDestroyDescriptorUpdateTemplate                 = cast( PFN_vkDestroyDescriptorUpdateTemplate                 ) vkGetInstanceProcAddr( instance, "vkDestroyDescriptorUpdateTemplate" );
    vkUpdateDescriptorSetWithTemplate                 = cast( PFN_vkUpdateDescriptorSetWithTemplate                 ) vkGetInstanceProcAddr( instance, "vkUpdateDescriptorSetWithTemplate" );
    vkGetDescriptorSetLayoutSupport                   = cast( PFN_vkGetDescriptorSetLayoutSupport                   ) vkGetInstanceProcAddr( instance, "vkGetDescriptorSetLayoutSupport" );

    // VK_VERSION_1_2
    vkCmdDrawIndirectCount                            = cast( PFN_vkCmdDrawIndirectCount                            ) vkGetInstanceProcAddr( instance, "vkCmdDrawIndirectCount" );
    vkCmdDrawIndexedIndirectCount                     = cast( PFN_vkCmdDrawIndexedIndirectCount                     ) vkGetInstanceProcAddr( instance, "vkCmdDrawIndexedIndirectCount" );
    vkCreateRenderPass2                               = cast( PFN_vkCreateRenderPass2                               ) vkGetInstanceProcAddr( instance, "vkCreateRenderPass2" );
    vkCmdBeginRenderPass2                             = cast( PFN_vkCmdBeginRenderPass2                             ) vkGetInstanceProcAddr( instance, "vkCmdBeginRenderPass2" );
    vkCmdNextSubpass2                                 = cast( PFN_vkCmdNextSubpass2                                 ) vkGetInstanceProcAddr( instance, "vkCmdNextSubpass2" );
    vkCmdEndRenderPass2                               = cast( PFN_vkCmdEndRenderPass2                               ) vkGetInstanceProcAddr( instance, "vkCmdEndRenderPass2" );
    vkResetQueryPool                                  = cast( PFN_vkResetQueryPool                                  ) vkGetInstanceProcAddr( instance, "vkResetQueryPool" );
    vkGetSemaphoreCounterValue                        = cast( PFN_vkGetSemaphoreCounterValue                        ) vkGetInstanceProcAddr( instance, "vkGetSemaphoreCounterValue" );
    vkWaitSemaphores                                  = cast( PFN_vkWaitSemaphores                                  ) vkGetInstanceProcAddr( instance, "vkWaitSemaphores" );
    vkSignalSemaphore                                 = cast( PFN_vkSignalSemaphore                                 ) vkGetInstanceProcAddr( instance, "vkSignalSemaphore" );
    vkGetBufferDeviceAddress                          = cast( PFN_vkGetBufferDeviceAddress                          ) vkGetInstanceProcAddr( instance, "vkGetBufferDeviceAddress" );
    vkGetBufferOpaqueCaptureAddress                   = cast( PFN_vkGetBufferOpaqueCaptureAddress                   ) vkGetInstanceProcAddr( instance, "vkGetBufferOpaqueCaptureAddress" );
    vkGetDeviceMemoryOpaqueCaptureAddress             = cast( PFN_vkGetDeviceMemoryOpaqueCaptureAddress             ) vkGetInstanceProcAddr( instance, "vkGetDeviceMemoryOpaqueCaptureAddress" );

    // VK_VERSION_1_3
    vkCreatePrivateDataSlot                           = cast( PFN_vkCreatePrivateDataSlot                           ) vkGetInstanceProcAddr( instance, "vkCreatePrivateDataSlot" );
    vkDestroyPrivateDataSlot                          = cast( PFN_vkDestroyPrivateDataSlot                          ) vkGetInstanceProcAddr( instance, "vkDestroyPrivateDataSlot" );
    vkSetPrivateData                                  = cast( PFN_vkSetPrivateData                                  ) vkGetInstanceProcAddr( instance, "vkSetPrivateData" );
    vkGetPrivateData                                  = cast( PFN_vkGetPrivateData                                  ) vkGetInstanceProcAddr( instance, "vkGetPrivateData" );
    vkCmdSetEvent2                                    = cast( PFN_vkCmdSetEvent2                                    ) vkGetInstanceProcAddr( instance, "vkCmdSetEvent2" );
    vkCmdResetEvent2                                  = cast( PFN_vkCmdResetEvent2                                  ) vkGetInstanceProcAddr( instance, "vkCmdResetEvent2" );
    vkCmdWaitEvents2                                  = cast( PFN_vkCmdWaitEvents2                                  ) vkGetInstanceProcAddr( instance, "vkCmdWaitEvents2" );
    vkCmdPipelineBarrier2                             = cast( PFN_vkCmdPipelineBarrier2                             ) vkGetInstanceProcAddr( instance, "vkCmdPipelineBarrier2" );
    vkCmdWriteTimestamp2                              = cast( PFN_vkCmdWriteTimestamp2                              ) vkGetInstanceProcAddr( instance, "vkCmdWriteTimestamp2" );
    vkQueueSubmit2                                    = cast( PFN_vkQueueSubmit2                                    ) vkGetInstanceProcAddr( instance, "vkQueueSubmit2" );
    vkCmdCopyBuffer2                                  = cast( PFN_vkCmdCopyBuffer2                                  ) vkGetInstanceProcAddr( instance, "vkCmdCopyBuffer2" );
    vkCmdCopyImage2                                   = cast( PFN_vkCmdCopyImage2                                   ) vkGetInstanceProcAddr( instance, "vkCmdCopyImage2" );
    vkCmdCopyBufferToImage2                           = cast( PFN_vkCmdCopyBufferToImage2                           ) vkGetInstanceProcAddr( instance, "vkCmdCopyBufferToImage2" );
    vkCmdCopyImageToBuffer2                           = cast( PFN_vkCmdCopyImageToBuffer2                           ) vkGetInstanceProcAddr( instance, "vkCmdCopyImageToBuffer2" );
    vkCmdBlitImage2                                   = cast( PFN_vkCmdBlitImage2                                   ) vkGetInstanceProcAddr( instance, "vkCmdBlitImage2" );
    vkCmdResolveImage2                                = cast( PFN_vkCmdResolveImage2                                ) vkGetInstanceProcAddr( instance, "vkCmdResolveImage2" );
    vkCmdBeginRendering                               = cast( PFN_vkCmdBeginRendering                               ) vkGetInstanceProcAddr( instance, "vkCmdBeginRendering" );
    vkCmdEndRendering                                 = cast( PFN_vkCmdEndRendering                                 ) vkGetInstanceProcAddr( instance, "vkCmdEndRendering" );
    vkCmdSetCullMode                                  = cast( PFN_vkCmdSetCullMode                                  ) vkGetInstanceProcAddr( instance, "vkCmdSetCullMode" );
    vkCmdSetFrontFace                                 = cast( PFN_vkCmdSetFrontFace                                 ) vkGetInstanceProcAddr( instance, "vkCmdSetFrontFace" );
    vkCmdSetPrimitiveTopology                         = cast( PFN_vkCmdSetPrimitiveTopology                         ) vkGetInstanceProcAddr( instance, "vkCmdSetPrimitiveTopology" );
    vkCmdSetViewportWithCount                         = cast( PFN_vkCmdSetViewportWithCount                         ) vkGetInstanceProcAddr( instance, "vkCmdSetViewportWithCount" );
    vkCmdSetScissorWithCount                          = cast( PFN_vkCmdSetScissorWithCount                          ) vkGetInstanceProcAddr( instance, "vkCmdSetScissorWithCount" );
    vkCmdBindVertexBuffers2                           = cast( PFN_vkCmdBindVertexBuffers2                           ) vkGetInstanceProcAddr( instance, "vkCmdBindVertexBuffers2" );
    vkCmdSetDepthTestEnable                           = cast( PFN_vkCmdSetDepthTestEnable                           ) vkGetInstanceProcAddr( instance, "vkCmdSetDepthTestEnable" );
    vkCmdSetDepthWriteEnable                          = cast( PFN_vkCmdSetDepthWriteEnable                          ) vkGetInstanceProcAddr( instance, "vkCmdSetDepthWriteEnable" );
    vkCmdSetDepthCompareOp                            = cast( PFN_vkCmdSetDepthCompareOp                            ) vkGetInstanceProcAddr( instance, "vkCmdSetDepthCompareOp" );
    vkCmdSetDepthBoundsTestEnable                     = cast( PFN_vkCmdSetDepthBoundsTestEnable                     ) vkGetInstanceProcAddr( instance, "vkCmdSetDepthBoundsTestEnable" );
    vkCmdSetStencilTestEnable                         = cast( PFN_vkCmdSetStencilTestEnable                         ) vkGetInstanceProcAddr( instance, "vkCmdSetStencilTestEnable" );
    vkCmdSetStencilOp                                 = cast( PFN_vkCmdSetStencilOp                                 ) vkGetInstanceProcAddr( instance, "vkCmdSetStencilOp" );
    vkCmdSetRasterizerDiscardEnable                   = cast( PFN_vkCmdSetRasterizerDiscardEnable                   ) vkGetInstanceProcAddr( instance, "vkCmdSetRasterizerDiscardEnable" );
    vkCmdSetDepthBiasEnable                           = cast( PFN_vkCmdSetDepthBiasEnable                           ) vkGetInstanceProcAddr( instance, "vkCmdSetDepthBiasEnable" );
    vkCmdSetPrimitiveRestartEnable                    = cast( PFN_vkCmdSetPrimitiveRestartEnable                    ) vkGetInstanceProcAddr( instance, "vkCmdSetPrimitiveRestartEnable" );
    vkGetDeviceBufferMemoryRequirements               = cast( PFN_vkGetDeviceBufferMemoryRequirements               ) vkGetInstanceProcAddr( instance, "vkGetDeviceBufferMemoryRequirements" );
    vkGetDeviceImageMemoryRequirements                = cast( PFN_vkGetDeviceImageMemoryRequirements                ) vkGetInstanceProcAddr( instance, "vkGetDeviceImageMemoryRequirements" );
    vkGetDeviceImageSparseMemoryRequirements          = cast( PFN_vkGetDeviceImageSparseMemoryRequirements          ) vkGetInstanceProcAddr( instance, "vkGetDeviceImageSparseMemoryRequirements" );

    // VK_KHR_swapchain
    vkCreateSwapchainKHR                              = cast( PFN_vkCreateSwapchainKHR                              ) vkGetInstanceProcAddr( instance, "vkCreateSwapchainKHR" );
    vkDestroySwapchainKHR                             = cast( PFN_vkDestroySwapchainKHR                             ) vkGetInstanceProcAddr( instance, "vkDestroySwapchainKHR" );
    vkGetSwapchainImagesKHR                           = cast( PFN_vkGetSwapchainImagesKHR                           ) vkGetInstanceProcAddr( instance, "vkGetSwapchainImagesKHR" );
    vkAcquireNextImageKHR                             = cast( PFN_vkAcquireNextImageKHR                             ) vkGetInstanceProcAddr( instance, "vkAcquireNextImageKHR" );
    vkQueuePresentKHR                                 = cast( PFN_vkQueuePresentKHR                                 ) vkGetInstanceProcAddr( instance, "vkQueuePresentKHR" );
    vkGetDeviceGroupPresentCapabilitiesKHR            = cast( PFN_vkGetDeviceGroupPresentCapabilitiesKHR            ) vkGetInstanceProcAddr( instance, "vkGetDeviceGroupPresentCapabilitiesKHR" );
    vkGetDeviceGroupSurfacePresentModesKHR            = cast( PFN_vkGetDeviceGroupSurfacePresentModesKHR            ) vkGetInstanceProcAddr( instance, "vkGetDeviceGroupSurfacePresentModesKHR" );
    vkAcquireNextImage2KHR                            = cast( PFN_vkAcquireNextImage2KHR                            ) vkGetInstanceProcAddr( instance, "vkAcquireNextImage2KHR" );

    // VK_KHR_display_swapchain
    vkCreateSharedSwapchainsKHR                       = cast( PFN_vkCreateSharedSwapchainsKHR                       ) vkGetInstanceProcAddr( instance, "vkCreateSharedSwapchainsKHR" );

    // VK_KHR_external_memory_fd
    vkGetMemoryFdKHR                                  = cast( PFN_vkGetMemoryFdKHR                                  ) vkGetInstanceProcAddr( instance, "vkGetMemoryFdKHR" );
    vkGetMemoryFdPropertiesKHR                        = cast( PFN_vkGetMemoryFdPropertiesKHR                        ) vkGetInstanceProcAddr( instance, "vkGetMemoryFdPropertiesKHR" );

    // VK_KHR_external_semaphore_fd
    vkImportSemaphoreFdKHR                            = cast( PFN_vkImportSemaphoreFdKHR                            ) vkGetInstanceProcAddr( instance, "vkImportSemaphoreFdKHR" );
    vkGetSemaphoreFdKHR                               = cast( PFN_vkGetSemaphoreFdKHR                               ) vkGetInstanceProcAddr( instance, "vkGetSemaphoreFdKHR" );

    // VK_KHR_push_descriptor
    vkCmdPushDescriptorSetKHR                         = cast( PFN_vkCmdPushDescriptorSetKHR                         ) vkGetInstanceProcAddr( instance, "vkCmdPushDescriptorSetKHR" );
    vkCmdPushDescriptorSetWithTemplateKHR             = cast( PFN_vkCmdPushDescriptorSetWithTemplateKHR             ) vkGetInstanceProcAddr( instance, "vkCmdPushDescriptorSetWithTemplateKHR" );

    // VK_KHR_shared_presentable_image
    vkGetSwapchainStatusKHR                           = cast( PFN_vkGetSwapchainStatusKHR                           ) vkGetInstanceProcAddr( instance, "vkGetSwapchainStatusKHR" );

    // VK_KHR_external_fence_fd
    vkImportFenceFdKHR                                = cast( PFN_vkImportFenceFdKHR                                ) vkGetInstanceProcAddr( instance, "vkImportFenceFdKHR" );
    vkGetFenceFdKHR                                   = cast( PFN_vkGetFenceFdKHR                                   ) vkGetInstanceProcAddr( instance, "vkGetFenceFdKHR" );

    // VK_KHR_performance_query
    vkAcquireProfilingLockKHR                         = cast( PFN_vkAcquireProfilingLockKHR                         ) vkGetInstanceProcAddr( instance, "vkAcquireProfilingLockKHR" );
    vkReleaseProfilingLockKHR                         = cast( PFN_vkReleaseProfilingLockKHR                         ) vkGetInstanceProcAddr( instance, "vkReleaseProfilingLockKHR" );

    // VK_KHR_fragment_shading_rate
    vkCmdSetFragmentShadingRateKHR                    = cast( PFN_vkCmdSetFragmentShadingRateKHR                    ) vkGetInstanceProcAddr( instance, "vkCmdSetFragmentShadingRateKHR" );

    // VK_KHR_present_wait
    vkWaitForPresentKHR                               = cast( PFN_vkWaitForPresentKHR                               ) vkGetInstanceProcAddr( instance, "vkWaitForPresentKHR" );

    // VK_KHR_deferred_host_operations
    vkCreateDeferredOperationKHR                      = cast( PFN_vkCreateDeferredOperationKHR                      ) vkGetInstanceProcAddr( instance, "vkCreateDeferredOperationKHR" );
    vkDestroyDeferredOperationKHR                     = cast( PFN_vkDestroyDeferredOperationKHR                     ) vkGetInstanceProcAddr( instance, "vkDestroyDeferredOperationKHR" );
    vkGetDeferredOperationMaxConcurrencyKHR           = cast( PFN_vkGetDeferredOperationMaxConcurrencyKHR           ) vkGetInstanceProcAddr( instance, "vkGetDeferredOperationMaxConcurrencyKHR" );
    vkGetDeferredOperationResultKHR                   = cast( PFN_vkGetDeferredOperationResultKHR                   ) vkGetInstanceProcAddr( instance, "vkGetDeferredOperationResultKHR" );
    vkDeferredOperationJoinKHR                        = cast( PFN_vkDeferredOperationJoinKHR                        ) vkGetInstanceProcAddr( instance, "vkDeferredOperationJoinKHR" );

    // VK_KHR_pipeline_executable_properties
    vkGetPipelineExecutablePropertiesKHR              = cast( PFN_vkGetPipelineExecutablePropertiesKHR              ) vkGetInstanceProcAddr( instance, "vkGetPipelineExecutablePropertiesKHR" );
    vkGetPipelineExecutableStatisticsKHR              = cast( PFN_vkGetPipelineExecutableStatisticsKHR              ) vkGetInstanceProcAddr( instance, "vkGetPipelineExecutableStatisticsKHR" );
    vkGetPipelineExecutableInternalRepresentationsKHR = cast( PFN_vkGetPipelineExecutableInternalRepresentationsKHR ) vkGetInstanceProcAddr( instance, "vkGetPipelineExecutableInternalRepresentationsKHR" );

    // VK_KHR_synchronization2
    vkCmdWriteBufferMarker2AMD                        = cast( PFN_vkCmdWriteBufferMarker2AMD                        ) vkGetInstanceProcAddr( instance, "vkCmdWriteBufferMarker2AMD" );
    vkGetQueueCheckpointData2NV                       = cast( PFN_vkGetQueueCheckpointData2NV                       ) vkGetInstanceProcAddr( instance, "vkGetQueueCheckpointData2NV" );

    // VK_KHR_ray_tracing_maintenance1
    vkCmdTraceRaysIndirect2KHR                        = cast( PFN_vkCmdTraceRaysIndirect2KHR                        ) vkGetInstanceProcAddr( instance, "vkCmdTraceRaysIndirect2KHR" );

    // VK_EXT_debug_marker
    vkDebugMarkerSetObjectTagEXT                      = cast( PFN_vkDebugMarkerSetObjectTagEXT                      ) vkGetInstanceProcAddr( instance, "vkDebugMarkerSetObjectTagEXT" );
    vkDebugMarkerSetObjectNameEXT                     = cast( PFN_vkDebugMarkerSetObjectNameEXT                     ) vkGetInstanceProcAddr( instance, "vkDebugMarkerSetObjectNameEXT" );
    vkCmdDebugMarkerBeginEXT                          = cast( PFN_vkCmdDebugMarkerBeginEXT                          ) vkGetInstanceProcAddr( instance, "vkCmdDebugMarkerBeginEXT" );
    vkCmdDebugMarkerEndEXT                            = cast( PFN_vkCmdDebugMarkerEndEXT                            ) vkGetInstanceProcAddr( instance, "vkCmdDebugMarkerEndEXT" );
    vkCmdDebugMarkerInsertEXT                         = cast( PFN_vkCmdDebugMarkerInsertEXT                         ) vkGetInstanceProcAddr( instance, "vkCmdDebugMarkerInsertEXT" );

    // VK_EXT_transform_feedback
    vkCmdBindTransformFeedbackBuffersEXT              = cast( PFN_vkCmdBindTransformFeedbackBuffersEXT              ) vkGetInstanceProcAddr( instance, "vkCmdBindTransformFeedbackBuffersEXT" );
    vkCmdBeginTransformFeedbackEXT                    = cast( PFN_vkCmdBeginTransformFeedbackEXT                    ) vkGetInstanceProcAddr( instance, "vkCmdBeginTransformFeedbackEXT" );
    vkCmdEndTransformFeedbackEXT                      = cast( PFN_vkCmdEndTransformFeedbackEXT                      ) vkGetInstanceProcAddr( instance, "vkCmdEndTransformFeedbackEXT" );
    vkCmdBeginQueryIndexedEXT                         = cast( PFN_vkCmdBeginQueryIndexedEXT                         ) vkGetInstanceProcAddr( instance, "vkCmdBeginQueryIndexedEXT" );
    vkCmdEndQueryIndexedEXT                           = cast( PFN_vkCmdEndQueryIndexedEXT                           ) vkGetInstanceProcAddr( instance, "vkCmdEndQueryIndexedEXT" );
    vkCmdDrawIndirectByteCountEXT                     = cast( PFN_vkCmdDrawIndirectByteCountEXT                     ) vkGetInstanceProcAddr( instance, "vkCmdDrawIndirectByteCountEXT" );

    // VK_NVX_binary_import
    vkCreateCuModuleNVX                               = cast( PFN_vkCreateCuModuleNVX                               ) vkGetInstanceProcAddr( instance, "vkCreateCuModuleNVX" );
    vkCreateCuFunctionNVX                             = cast( PFN_vkCreateCuFunctionNVX                             ) vkGetInstanceProcAddr( instance, "vkCreateCuFunctionNVX" );
    vkDestroyCuModuleNVX                              = cast( PFN_vkDestroyCuModuleNVX                              ) vkGetInstanceProcAddr( instance, "vkDestroyCuModuleNVX" );
    vkDestroyCuFunctionNVX                            = cast( PFN_vkDestroyCuFunctionNVX                            ) vkGetInstanceProcAddr( instance, "vkDestroyCuFunctionNVX" );
    vkCmdCuLaunchKernelNVX                            = cast( PFN_vkCmdCuLaunchKernelNVX                            ) vkGetInstanceProcAddr( instance, "vkCmdCuLaunchKernelNVX" );

    // VK_NVX_image_view_handle
    vkGetImageViewHandleNVX                           = cast( PFN_vkGetImageViewHandleNVX                           ) vkGetInstanceProcAddr( instance, "vkGetImageViewHandleNVX" );
    vkGetImageViewAddressNVX                          = cast( PFN_vkGetImageViewAddressNVX                          ) vkGetInstanceProcAddr( instance, "vkGetImageViewAddressNVX" );

    // VK_AMD_shader_info
    vkGetShaderInfoAMD                                = cast( PFN_vkGetShaderInfoAMD                                ) vkGetInstanceProcAddr( instance, "vkGetShaderInfoAMD" );

    // VK_EXT_conditional_rendering
    vkCmdBeginConditionalRenderingEXT                 = cast( PFN_vkCmdBeginConditionalRenderingEXT                 ) vkGetInstanceProcAddr( instance, "vkCmdBeginConditionalRenderingEXT" );
    vkCmdEndConditionalRenderingEXT                   = cast( PFN_vkCmdEndConditionalRenderingEXT                   ) vkGetInstanceProcAddr( instance, "vkCmdEndConditionalRenderingEXT" );

    // VK_NV_clip_space_w_scaling
    vkCmdSetViewportWScalingNV                        = cast( PFN_vkCmdSetViewportWScalingNV                        ) vkGetInstanceProcAddr( instance, "vkCmdSetViewportWScalingNV" );

    // VK_EXT_display_control
    vkDisplayPowerControlEXT                          = cast( PFN_vkDisplayPowerControlEXT                          ) vkGetInstanceProcAddr( instance, "vkDisplayPowerControlEXT" );
    vkRegisterDeviceEventEXT                          = cast( PFN_vkRegisterDeviceEventEXT                          ) vkGetInstanceProcAddr( instance, "vkRegisterDeviceEventEXT" );
    vkRegisterDisplayEventEXT                         = cast( PFN_vkRegisterDisplayEventEXT                         ) vkGetInstanceProcAddr( instance, "vkRegisterDisplayEventEXT" );
    vkGetSwapchainCounterEXT                          = cast( PFN_vkGetSwapchainCounterEXT                          ) vkGetInstanceProcAddr( instance, "vkGetSwapchainCounterEXT" );

    // VK_GOOGLE_display_timing
    vkGetRefreshCycleDurationGOOGLE                   = cast( PFN_vkGetRefreshCycleDurationGOOGLE                   ) vkGetInstanceProcAddr( instance, "vkGetRefreshCycleDurationGOOGLE" );
    vkGetPastPresentationTimingGOOGLE                 = cast( PFN_vkGetPastPresentationTimingGOOGLE                 ) vkGetInstanceProcAddr( instance, "vkGetPastPresentationTimingGOOGLE" );

    // VK_EXT_discard_rectangles
    vkCmdSetDiscardRectangleEXT                       = cast( PFN_vkCmdSetDiscardRectangleEXT                       ) vkGetInstanceProcAddr( instance, "vkCmdSetDiscardRectangleEXT" );

    // VK_EXT_hdr_metadata
    vkSetHdrMetadataEXT                               = cast( PFN_vkSetHdrMetadataEXT                               ) vkGetInstanceProcAddr( instance, "vkSetHdrMetadataEXT" );

    // VK_EXT_debug_utils
    vkSetDebugUtilsObjectNameEXT                      = cast( PFN_vkSetDebugUtilsObjectNameEXT                      ) vkGetInstanceProcAddr( instance, "vkSetDebugUtilsObjectNameEXT" );
    vkSetDebugUtilsObjectTagEXT                       = cast( PFN_vkSetDebugUtilsObjectTagEXT                       ) vkGetInstanceProcAddr( instance, "vkSetDebugUtilsObjectTagEXT" );
    vkQueueBeginDebugUtilsLabelEXT                    = cast( PFN_vkQueueBeginDebugUtilsLabelEXT                    ) vkGetInstanceProcAddr( instance, "vkQueueBeginDebugUtilsLabelEXT" );
    vkQueueEndDebugUtilsLabelEXT                      = cast( PFN_vkQueueEndDebugUtilsLabelEXT                      ) vkGetInstanceProcAddr( instance, "vkQueueEndDebugUtilsLabelEXT" );
    vkQueueInsertDebugUtilsLabelEXT                   = cast( PFN_vkQueueInsertDebugUtilsLabelEXT                   ) vkGetInstanceProcAddr( instance, "vkQueueInsertDebugUtilsLabelEXT" );
    vkCmdBeginDebugUtilsLabelEXT                      = cast( PFN_vkCmdBeginDebugUtilsLabelEXT                      ) vkGetInstanceProcAddr( instance, "vkCmdBeginDebugUtilsLabelEXT" );
    vkCmdEndDebugUtilsLabelEXT                        = cast( PFN_vkCmdEndDebugUtilsLabelEXT                        ) vkGetInstanceProcAddr( instance, "vkCmdEndDebugUtilsLabelEXT" );
    vkCmdInsertDebugUtilsLabelEXT                     = cast( PFN_vkCmdInsertDebugUtilsLabelEXT                     ) vkGetInstanceProcAddr( instance, "vkCmdInsertDebugUtilsLabelEXT" );

    // VK_EXT_sample_locations
    vkCmdSetSampleLocationsEXT                        = cast( PFN_vkCmdSetSampleLocationsEXT                        ) vkGetInstanceProcAddr( instance, "vkCmdSetSampleLocationsEXT" );

    // VK_EXT_image_drm_format_modifier
    vkGetImageDrmFormatModifierPropertiesEXT          = cast( PFN_vkGetImageDrmFormatModifierPropertiesEXT          ) vkGetInstanceProcAddr( instance, "vkGetImageDrmFormatModifierPropertiesEXT" );

    // VK_EXT_validation_cache
    vkCreateValidationCacheEXT                        = cast( PFN_vkCreateValidationCacheEXT                        ) vkGetInstanceProcAddr( instance, "vkCreateValidationCacheEXT" );
    vkDestroyValidationCacheEXT                       = cast( PFN_vkDestroyValidationCacheEXT                       ) vkGetInstanceProcAddr( instance, "vkDestroyValidationCacheEXT" );
    vkMergeValidationCachesEXT                        = cast( PFN_vkMergeValidationCachesEXT                        ) vkGetInstanceProcAddr( instance, "vkMergeValidationCachesEXT" );
    vkGetValidationCacheDataEXT                       = cast( PFN_vkGetValidationCacheDataEXT                       ) vkGetInstanceProcAddr( instance, "vkGetValidationCacheDataEXT" );

    // VK_NV_shading_rate_image
    vkCmdBindShadingRateImageNV                       = cast( PFN_vkCmdBindShadingRateImageNV                       ) vkGetInstanceProcAddr( instance, "vkCmdBindShadingRateImageNV" );
    vkCmdSetViewportShadingRatePaletteNV              = cast( PFN_vkCmdSetViewportShadingRatePaletteNV              ) vkGetInstanceProcAddr( instance, "vkCmdSetViewportShadingRatePaletteNV" );
    vkCmdSetCoarseSampleOrderNV                       = cast( PFN_vkCmdSetCoarseSampleOrderNV                       ) vkGetInstanceProcAddr( instance, "vkCmdSetCoarseSampleOrderNV" );

    // VK_NV_ray_tracing
    vkCreateAccelerationStructureNV                   = cast( PFN_vkCreateAccelerationStructureNV                   ) vkGetInstanceProcAddr( instance, "vkCreateAccelerationStructureNV" );
    vkDestroyAccelerationStructureNV                  = cast( PFN_vkDestroyAccelerationStructureNV                  ) vkGetInstanceProcAddr( instance, "vkDestroyAccelerationStructureNV" );
    vkGetAccelerationStructureMemoryRequirementsNV    = cast( PFN_vkGetAccelerationStructureMemoryRequirementsNV    ) vkGetInstanceProcAddr( instance, "vkGetAccelerationStructureMemoryRequirementsNV" );
    vkBindAccelerationStructureMemoryNV               = cast( PFN_vkBindAccelerationStructureMemoryNV               ) vkGetInstanceProcAddr( instance, "vkBindAccelerationStructureMemoryNV" );
    vkCmdBuildAccelerationStructureNV                 = cast( PFN_vkCmdBuildAccelerationStructureNV                 ) vkGetInstanceProcAddr( instance, "vkCmdBuildAccelerationStructureNV" );
    vkCmdCopyAccelerationStructureNV                  = cast( PFN_vkCmdCopyAccelerationStructureNV                  ) vkGetInstanceProcAddr( instance, "vkCmdCopyAccelerationStructureNV" );
    vkCmdTraceRaysNV                                  = cast( PFN_vkCmdTraceRaysNV                                  ) vkGetInstanceProcAddr( instance, "vkCmdTraceRaysNV" );
    vkCreateRayTracingPipelinesNV                     = cast( PFN_vkCreateRayTracingPipelinesNV                     ) vkGetInstanceProcAddr( instance, "vkCreateRayTracingPipelinesNV" );
    vkGetRayTracingShaderGroupHandlesKHR              = cast( PFN_vkGetRayTracingShaderGroupHandlesKHR              ) vkGetInstanceProcAddr( instance, "vkGetRayTracingShaderGroupHandlesKHR" );
    vkGetAccelerationStructureHandleNV                = cast( PFN_vkGetAccelerationStructureHandleNV                ) vkGetInstanceProcAddr( instance, "vkGetAccelerationStructureHandleNV" );
    vkCmdWriteAccelerationStructuresPropertiesNV      = cast( PFN_vkCmdWriteAccelerationStructuresPropertiesNV      ) vkGetInstanceProcAddr( instance, "vkCmdWriteAccelerationStructuresPropertiesNV" );
    vkCompileDeferredNV                               = cast( PFN_vkCompileDeferredNV                               ) vkGetInstanceProcAddr( instance, "vkCompileDeferredNV" );

    // VK_EXT_external_memory_host
    vkGetMemoryHostPointerPropertiesEXT               = cast( PFN_vkGetMemoryHostPointerPropertiesEXT               ) vkGetInstanceProcAddr( instance, "vkGetMemoryHostPointerPropertiesEXT" );

    // VK_AMD_buffer_marker
    vkCmdWriteBufferMarkerAMD                         = cast( PFN_vkCmdWriteBufferMarkerAMD                         ) vkGetInstanceProcAddr( instance, "vkCmdWriteBufferMarkerAMD" );

    // VK_EXT_calibrated_timestamps
    vkGetCalibratedTimestampsEXT                      = cast( PFN_vkGetCalibratedTimestampsEXT                      ) vkGetInstanceProcAddr( instance, "vkGetCalibratedTimestampsEXT" );

    // VK_NV_mesh_shader
    vkCmdDrawMeshTasksNV                              = cast( PFN_vkCmdDrawMeshTasksNV                              ) vkGetInstanceProcAddr( instance, "vkCmdDrawMeshTasksNV" );
    vkCmdDrawMeshTasksIndirectNV                      = cast( PFN_vkCmdDrawMeshTasksIndirectNV                      ) vkGetInstanceProcAddr( instance, "vkCmdDrawMeshTasksIndirectNV" );
    vkCmdDrawMeshTasksIndirectCountNV                 = cast( PFN_vkCmdDrawMeshTasksIndirectCountNV                 ) vkGetInstanceProcAddr( instance, "vkCmdDrawMeshTasksIndirectCountNV" );

    // VK_NV_scissor_exclusive
    vkCmdSetExclusiveScissorNV                        = cast( PFN_vkCmdSetExclusiveScissorNV                        ) vkGetInstanceProcAddr( instance, "vkCmdSetExclusiveScissorNV" );

    // VK_NV_device_diagnostic_checkpoints
    vkCmdSetCheckpointNV                              = cast( PFN_vkCmdSetCheckpointNV                              ) vkGetInstanceProcAddr( instance, "vkCmdSetCheckpointNV" );
    vkGetQueueCheckpointDataNV                        = cast( PFN_vkGetQueueCheckpointDataNV                        ) vkGetInstanceProcAddr( instance, "vkGetQueueCheckpointDataNV" );

    // VK_INTEL_performance_query
    vkInitializePerformanceApiINTEL                   = cast( PFN_vkInitializePerformanceApiINTEL                   ) vkGetInstanceProcAddr( instance, "vkInitializePerformanceApiINTEL" );
    vkUninitializePerformanceApiINTEL                 = cast( PFN_vkUninitializePerformanceApiINTEL                 ) vkGetInstanceProcAddr( instance, "vkUninitializePerformanceApiINTEL" );
    vkCmdSetPerformanceMarkerINTEL                    = cast( PFN_vkCmdSetPerformanceMarkerINTEL                    ) vkGetInstanceProcAddr( instance, "vkCmdSetPerformanceMarkerINTEL" );
    vkCmdSetPerformanceStreamMarkerINTEL              = cast( PFN_vkCmdSetPerformanceStreamMarkerINTEL              ) vkGetInstanceProcAddr( instance, "vkCmdSetPerformanceStreamMarkerINTEL" );
    vkCmdSetPerformanceOverrideINTEL                  = cast( PFN_vkCmdSetPerformanceOverrideINTEL                  ) vkGetInstanceProcAddr( instance, "vkCmdSetPerformanceOverrideINTEL" );
    vkAcquirePerformanceConfigurationINTEL            = cast( PFN_vkAcquirePerformanceConfigurationINTEL            ) vkGetInstanceProcAddr( instance, "vkAcquirePerformanceConfigurationINTEL" );
    vkReleasePerformanceConfigurationINTEL            = cast( PFN_vkReleasePerformanceConfigurationINTEL            ) vkGetInstanceProcAddr( instance, "vkReleasePerformanceConfigurationINTEL" );
    vkQueueSetPerformanceConfigurationINTEL           = cast( PFN_vkQueueSetPerformanceConfigurationINTEL           ) vkGetInstanceProcAddr( instance, "vkQueueSetPerformanceConfigurationINTEL" );
    vkGetPerformanceParameterINTEL                    = cast( PFN_vkGetPerformanceParameterINTEL                    ) vkGetInstanceProcAddr( instance, "vkGetPerformanceParameterINTEL" );

    // VK_AMD_display_native_hdr
    vkSetLocalDimmingAMD                              = cast( PFN_vkSetLocalDimmingAMD                              ) vkGetInstanceProcAddr( instance, "vkSetLocalDimmingAMD" );

    // VK_EXT_line_rasterization
    vkCmdSetLineStippleEXT                            = cast( PFN_vkCmdSetLineStippleEXT                            ) vkGetInstanceProcAddr( instance, "vkCmdSetLineStippleEXT" );

    // VK_NV_device_generated_commands
    vkGetGeneratedCommandsMemoryRequirementsNV        = cast( PFN_vkGetGeneratedCommandsMemoryRequirementsNV        ) vkGetInstanceProcAddr( instance, "vkGetGeneratedCommandsMemoryRequirementsNV" );
    vkCmdPreprocessGeneratedCommandsNV                = cast( PFN_vkCmdPreprocessGeneratedCommandsNV                ) vkGetInstanceProcAddr( instance, "vkCmdPreprocessGeneratedCommandsNV" );
    vkCmdExecuteGeneratedCommandsNV                   = cast( PFN_vkCmdExecuteGeneratedCommandsNV                   ) vkGetInstanceProcAddr( instance, "vkCmdExecuteGeneratedCommandsNV" );
    vkCmdBindPipelineShaderGroupNV                    = cast( PFN_vkCmdBindPipelineShaderGroupNV                    ) vkGetInstanceProcAddr( instance, "vkCmdBindPipelineShaderGroupNV" );
    vkCreateIndirectCommandsLayoutNV                  = cast( PFN_vkCreateIndirectCommandsLayoutNV                  ) vkGetInstanceProcAddr( instance, "vkCreateIndirectCommandsLayoutNV" );
    vkDestroyIndirectCommandsLayoutNV                 = cast( PFN_vkDestroyIndirectCommandsLayoutNV                 ) vkGetInstanceProcAddr( instance, "vkDestroyIndirectCommandsLayoutNV" );

    // VK_NV_fragment_shading_rate_enums
    vkCmdSetFragmentShadingRateEnumNV                 = cast( PFN_vkCmdSetFragmentShadingRateEnumNV                 ) vkGetInstanceProcAddr( instance, "vkCmdSetFragmentShadingRateEnumNV" );

    // VK_EXT_image_compression_control
    vkGetImageSubresourceLayout2EXT                   = cast( PFN_vkGetImageSubresourceLayout2EXT                   ) vkGetInstanceProcAddr( instance, "vkGetImageSubresourceLayout2EXT" );

    // VK_EXT_vertex_input_dynamic_state
    vkCmdSetVertexInputEXT                            = cast( PFN_vkCmdSetVertexInputEXT                            ) vkGetInstanceProcAddr( instance, "vkCmdSetVertexInputEXT" );

    // VK_HUAWEI_subpass_shading
    vkGetDeviceSubpassShadingMaxWorkgroupSizeHUAWEI   = cast( PFN_vkGetDeviceSubpassShadingMaxWorkgroupSizeHUAWEI   ) vkGetInstanceProcAddr( instance, "vkGetDeviceSubpassShadingMaxWorkgroupSizeHUAWEI" );
    vkCmdSubpassShadingHUAWEI                         = cast( PFN_vkCmdSubpassShadingHUAWEI                         ) vkGetInstanceProcAddr( instance, "vkCmdSubpassShadingHUAWEI" );

    // VK_HUAWEI_invocation_mask
    vkCmdBindInvocationMaskHUAWEI                     = cast( PFN_vkCmdBindInvocationMaskHUAWEI                     ) vkGetInstanceProcAddr( instance, "vkCmdBindInvocationMaskHUAWEI" );

    // VK_NV_external_memory_rdma
    vkGetMemoryRemoteAddressNV                        = cast( PFN_vkGetMemoryRemoteAddressNV                        ) vkGetInstanceProcAddr( instance, "vkGetMemoryRemoteAddressNV" );

    // VK_EXT_pipeline_properties
    vkGetPipelinePropertiesEXT                        = cast( PFN_vkGetPipelinePropertiesEXT                        ) vkGetInstanceProcAddr( instance, "vkGetPipelinePropertiesEXT" );

    // VK_EXT_extended_dynamic_state2
    vkCmdSetPatchControlPointsEXT                     = cast( PFN_vkCmdSetPatchControlPointsEXT                     ) vkGetInstanceProcAddr( instance, "vkCmdSetPatchControlPointsEXT" );
    vkCmdSetLogicOpEXT                                = cast( PFN_vkCmdSetLogicOpEXT                                ) vkGetInstanceProcAddr( instance, "vkCmdSetLogicOpEXT" );

    // VK_EXT_color_write_enable
    vkCmdSetColorWriteEnableEXT                       = cast( PFN_vkCmdSetColorWriteEnableEXT                       ) vkGetInstanceProcAddr( instance, "vkCmdSetColorWriteEnableEXT" );

    // VK_EXT_multi_draw
    vkCmdDrawMultiEXT                                 = cast( PFN_vkCmdDrawMultiEXT                                 ) vkGetInstanceProcAddr( instance, "vkCmdDrawMultiEXT" );
    vkCmdDrawMultiIndexedEXT                          = cast( PFN_vkCmdDrawMultiIndexedEXT                          ) vkGetInstanceProcAddr( instance, "vkCmdDrawMultiIndexedEXT" );

    // VK_EXT_pageable_device_local_memory
    vkSetDeviceMemoryPriorityEXT                      = cast( PFN_vkSetDeviceMemoryPriorityEXT                      ) vkGetInstanceProcAddr( instance, "vkSetDeviceMemoryPriorityEXT" );

    // VK_VALVE_descriptor_set_host_mapping
    vkGetDescriptorSetLayoutHostMappingInfoVALVE      = cast( PFN_vkGetDescriptorSetLayoutHostMappingInfoVALVE      ) vkGetInstanceProcAddr( instance, "vkGetDescriptorSetLayoutHostMappingInfoVALVE" );
    vkGetDescriptorSetHostMappingVALVE                = cast( PFN_vkGetDescriptorSetHostMappingVALVE                ) vkGetInstanceProcAddr( instance, "vkGetDescriptorSetHostMappingVALVE" );

    // VK_KHR_acceleration_structure
    vkCreateAccelerationStructureKHR                  = cast( PFN_vkCreateAccelerationStructureKHR                  ) vkGetInstanceProcAddr( instance, "vkCreateAccelerationStructureKHR" );
    vkDestroyAccelerationStructureKHR                 = cast( PFN_vkDestroyAccelerationStructureKHR                 ) vkGetInstanceProcAddr( instance, "vkDestroyAccelerationStructureKHR" );
    vkCmdBuildAccelerationStructuresKHR               = cast( PFN_vkCmdBuildAccelerationStructuresKHR               ) vkGetInstanceProcAddr( instance, "vkCmdBuildAccelerationStructuresKHR" );
    vkCmdBuildAccelerationStructuresIndirectKHR       = cast( PFN_vkCmdBuildAccelerationStructuresIndirectKHR       ) vkGetInstanceProcAddr( instance, "vkCmdBuildAccelerationStructuresIndirectKHR" );
    vkBuildAccelerationStructuresKHR                  = cast( PFN_vkBuildAccelerationStructuresKHR                  ) vkGetInstanceProcAddr( instance, "vkBuildAccelerationStructuresKHR" );
    vkCopyAccelerationStructureKHR                    = cast( PFN_vkCopyAccelerationStructureKHR                    ) vkGetInstanceProcAddr( instance, "vkCopyAccelerationStructureKHR" );
    vkCopyAccelerationStructureToMemoryKHR            = cast( PFN_vkCopyAccelerationStructureToMemoryKHR            ) vkGetInstanceProcAddr( instance, "vkCopyAccelerationStructureToMemoryKHR" );
    vkCopyMemoryToAccelerationStructureKHR            = cast( PFN_vkCopyMemoryToAccelerationStructureKHR            ) vkGetInstanceProcAddr( instance, "vkCopyMemoryToAccelerationStructureKHR" );
    vkWriteAccelerationStructuresPropertiesKHR        = cast( PFN_vkWriteAccelerationStructuresPropertiesKHR        ) vkGetInstanceProcAddr( instance, "vkWriteAccelerationStructuresPropertiesKHR" );
    vkCmdCopyAccelerationStructureKHR                 = cast( PFN_vkCmdCopyAccelerationStructureKHR                 ) vkGetInstanceProcAddr( instance, "vkCmdCopyAccelerationStructureKHR" );
    vkCmdCopyAccelerationStructureToMemoryKHR         = cast( PFN_vkCmdCopyAccelerationStructureToMemoryKHR         ) vkGetInstanceProcAddr( instance, "vkCmdCopyAccelerationStructureToMemoryKHR" );
    vkCmdCopyMemoryToAccelerationStructureKHR         = cast( PFN_vkCmdCopyMemoryToAccelerationStructureKHR         ) vkGetInstanceProcAddr( instance, "vkCmdCopyMemoryToAccelerationStructureKHR" );
    vkGetAccelerationStructureDeviceAddressKHR        = cast( PFN_vkGetAccelerationStructureDeviceAddressKHR        ) vkGetInstanceProcAddr( instance, "vkGetAccelerationStructureDeviceAddressKHR" );
    vkCmdWriteAccelerationStructuresPropertiesKHR     = cast( PFN_vkCmdWriteAccelerationStructuresPropertiesKHR     ) vkGetInstanceProcAddr( instance, "vkCmdWriteAccelerationStructuresPropertiesKHR" );
    vkGetDeviceAccelerationStructureCompatibilityKHR  = cast( PFN_vkGetDeviceAccelerationStructureCompatibilityKHR  ) vkGetInstanceProcAddr( instance, "vkGetDeviceAccelerationStructureCompatibilityKHR" );
    vkGetAccelerationStructureBuildSizesKHR           = cast( PFN_vkGetAccelerationStructureBuildSizesKHR           ) vkGetInstanceProcAddr( instance, "vkGetAccelerationStructureBuildSizesKHR" );

    // VK_KHR_ray_tracing_pipeline
    vkCmdTraceRaysKHR                                 = cast( PFN_vkCmdTraceRaysKHR                                 ) vkGetInstanceProcAddr( instance, "vkCmdTraceRaysKHR" );
    vkCreateRayTracingPipelinesKHR                    = cast( PFN_vkCreateRayTracingPipelinesKHR                    ) vkGetInstanceProcAddr( instance, "vkCreateRayTracingPipelinesKHR" );
    vkGetRayTracingCaptureReplayShaderGroupHandlesKHR = cast( PFN_vkGetRayTracingCaptureReplayShaderGroupHandlesKHR ) vkGetInstanceProcAddr( instance, "vkGetRayTracingCaptureReplayShaderGroupHandlesKHR" );
    vkCmdTraceRaysIndirectKHR                         = cast( PFN_vkCmdTraceRaysIndirectKHR                         ) vkGetInstanceProcAddr( instance, "vkCmdTraceRaysIndirectKHR" );
    vkGetRayTracingShaderGroupStackSizeKHR            = cast( PFN_vkGetRayTracingShaderGroupStackSizeKHR            ) vkGetInstanceProcAddr( instance, "vkGetRayTracingShaderGroupStackSizeKHR" );
    vkCmdSetRayTracingPipelineStackSizeKHR            = cast( PFN_vkCmdSetRayTracingPipelineStackSizeKHR            ) vkGetInstanceProcAddr( instance, "vkCmdSetRayTracingPipelineStackSizeKHR" );
}


/// with a valid VkDevice call this function to retrieve VkDevice, VkQueue and VkCommandBuffer related functions
/// the functions call directly VkDevice and related resources and can be retrieved for one and only one VkDevice
/// calling this function again with another VkDevices will overwrite the __gshared functions retrieved previously
/// see module erupted.dispatch_device if multiple VkDevices will be used
void loadDeviceLevelFunctions( VkDevice device ) {
    assert( vkGetDeviceProcAddr !is null, "Function pointer vkGetDeviceProcAddr is null!\nCall loadGlobalLevelFunctions -> loadInstanceLevelFunctions -> loadDeviceLevelFunctions( device )" );

    // VK_VERSION_1_0
    vkDestroyDevice                                   = cast( PFN_vkDestroyDevice                                   ) vkGetDeviceProcAddr( device, "vkDestroyDevice" );
    vkGetDeviceQueue                                  = cast( PFN_vkGetDeviceQueue                                  ) vkGetDeviceProcAddr( device, "vkGetDeviceQueue" );
    vkQueueSubmit                                     = cast( PFN_vkQueueSubmit                                     ) vkGetDeviceProcAddr( device, "vkQueueSubmit" );
    vkQueueWaitIdle                                   = cast( PFN_vkQueueWaitIdle                                   ) vkGetDeviceProcAddr( device, "vkQueueWaitIdle" );
    vkDeviceWaitIdle                                  = cast( PFN_vkDeviceWaitIdle                                  ) vkGetDeviceProcAddr( device, "vkDeviceWaitIdle" );
    vkAllocateMemory                                  = cast( PFN_vkAllocateMemory                                  ) vkGetDeviceProcAddr( device, "vkAllocateMemory" );
    vkFreeMemory                                      = cast( PFN_vkFreeMemory                                      ) vkGetDeviceProcAddr( device, "vkFreeMemory" );
    vkMapMemory                                       = cast( PFN_vkMapMemory                                       ) vkGetDeviceProcAddr( device, "vkMapMemory" );
    vkUnmapMemory                                     = cast( PFN_vkUnmapMemory                                     ) vkGetDeviceProcAddr( device, "vkUnmapMemory" );
    vkFlushMappedMemoryRanges                         = cast( PFN_vkFlushMappedMemoryRanges                         ) vkGetDeviceProcAddr( device, "vkFlushMappedMemoryRanges" );
    vkInvalidateMappedMemoryRanges                    = cast( PFN_vkInvalidateMappedMemoryRanges                    ) vkGetDeviceProcAddr( device, "vkInvalidateMappedMemoryRanges" );
    vkGetDeviceMemoryCommitment                       = cast( PFN_vkGetDeviceMemoryCommitment                       ) vkGetDeviceProcAddr( device, "vkGetDeviceMemoryCommitment" );
    vkBindBufferMemory                                = cast( PFN_vkBindBufferMemory                                ) vkGetDeviceProcAddr( device, "vkBindBufferMemory" );
    vkBindImageMemory                                 = cast( PFN_vkBindImageMemory                                 ) vkGetDeviceProcAddr( device, "vkBindImageMemory" );
    vkGetBufferMemoryRequirements                     = cast( PFN_vkGetBufferMemoryRequirements                     ) vkGetDeviceProcAddr( device, "vkGetBufferMemoryRequirements" );
    vkGetImageMemoryRequirements                      = cast( PFN_vkGetImageMemoryRequirements                      ) vkGetDeviceProcAddr( device, "vkGetImageMemoryRequirements" );
    vkGetImageSparseMemoryRequirements                = cast( PFN_vkGetImageSparseMemoryRequirements                ) vkGetDeviceProcAddr( device, "vkGetImageSparseMemoryRequirements" );
    vkQueueBindSparse                                 = cast( PFN_vkQueueBindSparse                                 ) vkGetDeviceProcAddr( device, "vkQueueBindSparse" );
    vkCreateFence                                     = cast( PFN_vkCreateFence                                     ) vkGetDeviceProcAddr( device, "vkCreateFence" );
    vkDestroyFence                                    = cast( PFN_vkDestroyFence                                    ) vkGetDeviceProcAddr( device, "vkDestroyFence" );
    vkResetFences                                     = cast( PFN_vkResetFences                                     ) vkGetDeviceProcAddr( device, "vkResetFences" );
    vkGetFenceStatus                                  = cast( PFN_vkGetFenceStatus                                  ) vkGetDeviceProcAddr( device, "vkGetFenceStatus" );
    vkWaitForFences                                   = cast( PFN_vkWaitForFences                                   ) vkGetDeviceProcAddr( device, "vkWaitForFences" );
    vkCreateSemaphore                                 = cast( PFN_vkCreateSemaphore                                 ) vkGetDeviceProcAddr( device, "vkCreateSemaphore" );
    vkDestroySemaphore                                = cast( PFN_vkDestroySemaphore                                ) vkGetDeviceProcAddr( device, "vkDestroySemaphore" );
    vkCreateEvent                                     = cast( PFN_vkCreateEvent                                     ) vkGetDeviceProcAddr( device, "vkCreateEvent" );
    vkDestroyEvent                                    = cast( PFN_vkDestroyEvent                                    ) vkGetDeviceProcAddr( device, "vkDestroyEvent" );
    vkGetEventStatus                                  = cast( PFN_vkGetEventStatus                                  ) vkGetDeviceProcAddr( device, "vkGetEventStatus" );
    vkSetEvent                                        = cast( PFN_vkSetEvent                                        ) vkGetDeviceProcAddr( device, "vkSetEvent" );
    vkResetEvent                                      = cast( PFN_vkResetEvent                                      ) vkGetDeviceProcAddr( device, "vkResetEvent" );
    vkCreateQueryPool                                 = cast( PFN_vkCreateQueryPool                                 ) vkGetDeviceProcAddr( device, "vkCreateQueryPool" );
    vkDestroyQueryPool                                = cast( PFN_vkDestroyQueryPool                                ) vkGetDeviceProcAddr( device, "vkDestroyQueryPool" );
    vkGetQueryPoolResults                             = cast( PFN_vkGetQueryPoolResults                             ) vkGetDeviceProcAddr( device, "vkGetQueryPoolResults" );
    vkCreateBuffer                                    = cast( PFN_vkCreateBuffer                                    ) vkGetDeviceProcAddr( device, "vkCreateBuffer" );
    vkDestroyBuffer                                   = cast( PFN_vkDestroyBuffer                                   ) vkGetDeviceProcAddr( device, "vkDestroyBuffer" );
    vkCreateBufferView                                = cast( PFN_vkCreateBufferView                                ) vkGetDeviceProcAddr( device, "vkCreateBufferView" );
    vkDestroyBufferView                               = cast( PFN_vkDestroyBufferView                               ) vkGetDeviceProcAddr( device, "vkDestroyBufferView" );
    vkCreateImage                                     = cast( PFN_vkCreateImage                                     ) vkGetDeviceProcAddr( device, "vkCreateImage" );
    vkDestroyImage                                    = cast( PFN_vkDestroyImage                                    ) vkGetDeviceProcAddr( device, "vkDestroyImage" );
    vkGetImageSubresourceLayout                       = cast( PFN_vkGetImageSubresourceLayout                       ) vkGetDeviceProcAddr( device, "vkGetImageSubresourceLayout" );
    vkCreateImageView                                 = cast( PFN_vkCreateImageView                                 ) vkGetDeviceProcAddr( device, "vkCreateImageView" );
    vkDestroyImageView                                = cast( PFN_vkDestroyImageView                                ) vkGetDeviceProcAddr( device, "vkDestroyImageView" );
    vkCreateShaderModule                              = cast( PFN_vkCreateShaderModule                              ) vkGetDeviceProcAddr( device, "vkCreateShaderModule" );
    vkDestroyShaderModule                             = cast( PFN_vkDestroyShaderModule                             ) vkGetDeviceProcAddr( device, "vkDestroyShaderModule" );
    vkCreatePipelineCache                             = cast( PFN_vkCreatePipelineCache                             ) vkGetDeviceProcAddr( device, "vkCreatePipelineCache" );
    vkDestroyPipelineCache                            = cast( PFN_vkDestroyPipelineCache                            ) vkGetDeviceProcAddr( device, "vkDestroyPipelineCache" );
    vkGetPipelineCacheData                            = cast( PFN_vkGetPipelineCacheData                            ) vkGetDeviceProcAddr( device, "vkGetPipelineCacheData" );
    vkMergePipelineCaches                             = cast( PFN_vkMergePipelineCaches                             ) vkGetDeviceProcAddr( device, "vkMergePipelineCaches" );
    vkCreateGraphicsPipelines                         = cast( PFN_vkCreateGraphicsPipelines                         ) vkGetDeviceProcAddr( device, "vkCreateGraphicsPipelines" );
    vkCreateComputePipelines                          = cast( PFN_vkCreateComputePipelines                          ) vkGetDeviceProcAddr( device, "vkCreateComputePipelines" );
    vkDestroyPipeline                                 = cast( PFN_vkDestroyPipeline                                 ) vkGetDeviceProcAddr( device, "vkDestroyPipeline" );
    vkCreatePipelineLayout                            = cast( PFN_vkCreatePipelineLayout                            ) vkGetDeviceProcAddr( device, "vkCreatePipelineLayout" );
    vkDestroyPipelineLayout                           = cast( PFN_vkDestroyPipelineLayout                           ) vkGetDeviceProcAddr( device, "vkDestroyPipelineLayout" );
    vkCreateSampler                                   = cast( PFN_vkCreateSampler                                   ) vkGetDeviceProcAddr( device, "vkCreateSampler" );
    vkDestroySampler                                  = cast( PFN_vkDestroySampler                                  ) vkGetDeviceProcAddr( device, "vkDestroySampler" );
    vkCreateDescriptorSetLayout                       = cast( PFN_vkCreateDescriptorSetLayout                       ) vkGetDeviceProcAddr( device, "vkCreateDescriptorSetLayout" );
    vkDestroyDescriptorSetLayout                      = cast( PFN_vkDestroyDescriptorSetLayout                      ) vkGetDeviceProcAddr( device, "vkDestroyDescriptorSetLayout" );
    vkCreateDescriptorPool                            = cast( PFN_vkCreateDescriptorPool                            ) vkGetDeviceProcAddr( device, "vkCreateDescriptorPool" );
    vkDestroyDescriptorPool                           = cast( PFN_vkDestroyDescriptorPool                           ) vkGetDeviceProcAddr( device, "vkDestroyDescriptorPool" );
    vkResetDescriptorPool                             = cast( PFN_vkResetDescriptorPool                             ) vkGetDeviceProcAddr( device, "vkResetDescriptorPool" );
    vkAllocateDescriptorSets                          = cast( PFN_vkAllocateDescriptorSets                          ) vkGetDeviceProcAddr( device, "vkAllocateDescriptorSets" );
    vkFreeDescriptorSets                              = cast( PFN_vkFreeDescriptorSets                              ) vkGetDeviceProcAddr( device, "vkFreeDescriptorSets" );
    vkUpdateDescriptorSets                            = cast( PFN_vkUpdateDescriptorSets                            ) vkGetDeviceProcAddr( device, "vkUpdateDescriptorSets" );
    vkCreateFramebuffer                               = cast( PFN_vkCreateFramebuffer                               ) vkGetDeviceProcAddr( device, "vkCreateFramebuffer" );
    vkDestroyFramebuffer                              = cast( PFN_vkDestroyFramebuffer                              ) vkGetDeviceProcAddr( device, "vkDestroyFramebuffer" );
    vkCreateRenderPass                                = cast( PFN_vkCreateRenderPass                                ) vkGetDeviceProcAddr( device, "vkCreateRenderPass" );
    vkDestroyRenderPass                               = cast( PFN_vkDestroyRenderPass                               ) vkGetDeviceProcAddr( device, "vkDestroyRenderPass" );
    vkGetRenderAreaGranularity                        = cast( PFN_vkGetRenderAreaGranularity                        ) vkGetDeviceProcAddr( device, "vkGetRenderAreaGranularity" );
    vkCreateCommandPool                               = cast( PFN_vkCreateCommandPool                               ) vkGetDeviceProcAddr( device, "vkCreateCommandPool" );
    vkDestroyCommandPool                              = cast( PFN_vkDestroyCommandPool                              ) vkGetDeviceProcAddr( device, "vkDestroyCommandPool" );
    vkResetCommandPool                                = cast( PFN_vkResetCommandPool                                ) vkGetDeviceProcAddr( device, "vkResetCommandPool" );
    vkAllocateCommandBuffers                          = cast( PFN_vkAllocateCommandBuffers                          ) vkGetDeviceProcAddr( device, "vkAllocateCommandBuffers" );
    vkFreeCommandBuffers                              = cast( PFN_vkFreeCommandBuffers                              ) vkGetDeviceProcAddr( device, "vkFreeCommandBuffers" );
    vkBeginCommandBuffer                              = cast( PFN_vkBeginCommandBuffer                              ) vkGetDeviceProcAddr( device, "vkBeginCommandBuffer" );
    vkEndCommandBuffer                                = cast( PFN_vkEndCommandBuffer                                ) vkGetDeviceProcAddr( device, "vkEndCommandBuffer" );
    vkResetCommandBuffer                              = cast( PFN_vkResetCommandBuffer                              ) vkGetDeviceProcAddr( device, "vkResetCommandBuffer" );
    vkCmdBindPipeline                                 = cast( PFN_vkCmdBindPipeline                                 ) vkGetDeviceProcAddr( device, "vkCmdBindPipeline" );
    vkCmdSetViewport                                  = cast( PFN_vkCmdSetViewport                                  ) vkGetDeviceProcAddr( device, "vkCmdSetViewport" );
    vkCmdSetScissor                                   = cast( PFN_vkCmdSetScissor                                   ) vkGetDeviceProcAddr( device, "vkCmdSetScissor" );
    vkCmdSetLineWidth                                 = cast( PFN_vkCmdSetLineWidth                                 ) vkGetDeviceProcAddr( device, "vkCmdSetLineWidth" );
    vkCmdSetDepthBias                                 = cast( PFN_vkCmdSetDepthBias                                 ) vkGetDeviceProcAddr( device, "vkCmdSetDepthBias" );
    vkCmdSetBlendConstants                            = cast( PFN_vkCmdSetBlendConstants                            ) vkGetDeviceProcAddr( device, "vkCmdSetBlendConstants" );
    vkCmdSetDepthBounds                               = cast( PFN_vkCmdSetDepthBounds                               ) vkGetDeviceProcAddr( device, "vkCmdSetDepthBounds" );
    vkCmdSetStencilCompareMask                        = cast( PFN_vkCmdSetStencilCompareMask                        ) vkGetDeviceProcAddr( device, "vkCmdSetStencilCompareMask" );
    vkCmdSetStencilWriteMask                          = cast( PFN_vkCmdSetStencilWriteMask                          ) vkGetDeviceProcAddr( device, "vkCmdSetStencilWriteMask" );
    vkCmdSetStencilReference                          = cast( PFN_vkCmdSetStencilReference                          ) vkGetDeviceProcAddr( device, "vkCmdSetStencilReference" );
    vkCmdBindDescriptorSets                           = cast( PFN_vkCmdBindDescriptorSets                           ) vkGetDeviceProcAddr( device, "vkCmdBindDescriptorSets" );
    vkCmdBindIndexBuffer                              = cast( PFN_vkCmdBindIndexBuffer                              ) vkGetDeviceProcAddr( device, "vkCmdBindIndexBuffer" );
    vkCmdBindVertexBuffers                            = cast( PFN_vkCmdBindVertexBuffers                            ) vkGetDeviceProcAddr( device, "vkCmdBindVertexBuffers" );
    vkCmdDraw                                         = cast( PFN_vkCmdDraw                                         ) vkGetDeviceProcAddr( device, "vkCmdDraw" );
    vkCmdDrawIndexed                                  = cast( PFN_vkCmdDrawIndexed                                  ) vkGetDeviceProcAddr( device, "vkCmdDrawIndexed" );
    vkCmdDrawIndirect                                 = cast( PFN_vkCmdDrawIndirect                                 ) vkGetDeviceProcAddr( device, "vkCmdDrawIndirect" );
    vkCmdDrawIndexedIndirect                          = cast( PFN_vkCmdDrawIndexedIndirect                          ) vkGetDeviceProcAddr( device, "vkCmdDrawIndexedIndirect" );
    vkCmdDispatch                                     = cast( PFN_vkCmdDispatch                                     ) vkGetDeviceProcAddr( device, "vkCmdDispatch" );
    vkCmdDispatchIndirect                             = cast( PFN_vkCmdDispatchIndirect                             ) vkGetDeviceProcAddr( device, "vkCmdDispatchIndirect" );
    vkCmdCopyBuffer                                   = cast( PFN_vkCmdCopyBuffer                                   ) vkGetDeviceProcAddr( device, "vkCmdCopyBuffer" );
    vkCmdCopyImage                                    = cast( PFN_vkCmdCopyImage                                    ) vkGetDeviceProcAddr( device, "vkCmdCopyImage" );
    vkCmdBlitImage                                    = cast( PFN_vkCmdBlitImage                                    ) vkGetDeviceProcAddr( device, "vkCmdBlitImage" );
    vkCmdCopyBufferToImage                            = cast( PFN_vkCmdCopyBufferToImage                            ) vkGetDeviceProcAddr( device, "vkCmdCopyBufferToImage" );
    vkCmdCopyImageToBuffer                            = cast( PFN_vkCmdCopyImageToBuffer                            ) vkGetDeviceProcAddr( device, "vkCmdCopyImageToBuffer" );
    vkCmdUpdateBuffer                                 = cast( PFN_vkCmdUpdateBuffer                                 ) vkGetDeviceProcAddr( device, "vkCmdUpdateBuffer" );
    vkCmdFillBuffer                                   = cast( PFN_vkCmdFillBuffer                                   ) vkGetDeviceProcAddr( device, "vkCmdFillBuffer" );
    vkCmdClearColorImage                              = cast( PFN_vkCmdClearColorImage                              ) vkGetDeviceProcAddr( device, "vkCmdClearColorImage" );
    vkCmdClearDepthStencilImage                       = cast( PFN_vkCmdClearDepthStencilImage                       ) vkGetDeviceProcAddr( device, "vkCmdClearDepthStencilImage" );
    vkCmdClearAttachments                             = cast( PFN_vkCmdClearAttachments                             ) vkGetDeviceProcAddr( device, "vkCmdClearAttachments" );
    vkCmdResolveImage                                 = cast( PFN_vkCmdResolveImage                                 ) vkGetDeviceProcAddr( device, "vkCmdResolveImage" );
    vkCmdSetEvent                                     = cast( PFN_vkCmdSetEvent                                     ) vkGetDeviceProcAddr( device, "vkCmdSetEvent" );
    vkCmdResetEvent                                   = cast( PFN_vkCmdResetEvent                                   ) vkGetDeviceProcAddr( device, "vkCmdResetEvent" );
    vkCmdWaitEvents                                   = cast( PFN_vkCmdWaitEvents                                   ) vkGetDeviceProcAddr( device, "vkCmdWaitEvents" );
    vkCmdPipelineBarrier                              = cast( PFN_vkCmdPipelineBarrier                              ) vkGetDeviceProcAddr( device, "vkCmdPipelineBarrier" );
    vkCmdBeginQuery                                   = cast( PFN_vkCmdBeginQuery                                   ) vkGetDeviceProcAddr( device, "vkCmdBeginQuery" );
    vkCmdEndQuery                                     = cast( PFN_vkCmdEndQuery                                     ) vkGetDeviceProcAddr( device, "vkCmdEndQuery" );
    vkCmdResetQueryPool                               = cast( PFN_vkCmdResetQueryPool                               ) vkGetDeviceProcAddr( device, "vkCmdResetQueryPool" );
    vkCmdWriteTimestamp                               = cast( PFN_vkCmdWriteTimestamp                               ) vkGetDeviceProcAddr( device, "vkCmdWriteTimestamp" );
    vkCmdCopyQueryPoolResults                         = cast( PFN_vkCmdCopyQueryPoolResults                         ) vkGetDeviceProcAddr( device, "vkCmdCopyQueryPoolResults" );
    vkCmdPushConstants                                = cast( PFN_vkCmdPushConstants                                ) vkGetDeviceProcAddr( device, "vkCmdPushConstants" );
    vkCmdBeginRenderPass                              = cast( PFN_vkCmdBeginRenderPass                              ) vkGetDeviceProcAddr( device, "vkCmdBeginRenderPass" );
    vkCmdNextSubpass                                  = cast( PFN_vkCmdNextSubpass                                  ) vkGetDeviceProcAddr( device, "vkCmdNextSubpass" );
    vkCmdEndRenderPass                                = cast( PFN_vkCmdEndRenderPass                                ) vkGetDeviceProcAddr( device, "vkCmdEndRenderPass" );
    vkCmdExecuteCommands                              = cast( PFN_vkCmdExecuteCommands                              ) vkGetDeviceProcAddr( device, "vkCmdExecuteCommands" );

    // VK_VERSION_1_1
    vkBindBufferMemory2                               = cast( PFN_vkBindBufferMemory2                               ) vkGetDeviceProcAddr( device, "vkBindBufferMemory2" );
    vkBindImageMemory2                                = cast( PFN_vkBindImageMemory2                                ) vkGetDeviceProcAddr( device, "vkBindImageMemory2" );
    vkGetDeviceGroupPeerMemoryFeatures                = cast( PFN_vkGetDeviceGroupPeerMemoryFeatures                ) vkGetDeviceProcAddr( device, "vkGetDeviceGroupPeerMemoryFeatures" );
    vkCmdSetDeviceMask                                = cast( PFN_vkCmdSetDeviceMask                                ) vkGetDeviceProcAddr( device, "vkCmdSetDeviceMask" );
    vkCmdDispatchBase                                 = cast( PFN_vkCmdDispatchBase                                 ) vkGetDeviceProcAddr( device, "vkCmdDispatchBase" );
    vkGetImageMemoryRequirements2                     = cast( PFN_vkGetImageMemoryRequirements2                     ) vkGetDeviceProcAddr( device, "vkGetImageMemoryRequirements2" );
    vkGetBufferMemoryRequirements2                    = cast( PFN_vkGetBufferMemoryRequirements2                    ) vkGetDeviceProcAddr( device, "vkGetBufferMemoryRequirements2" );
    vkGetImageSparseMemoryRequirements2               = cast( PFN_vkGetImageSparseMemoryRequirements2               ) vkGetDeviceProcAddr( device, "vkGetImageSparseMemoryRequirements2" );
    vkTrimCommandPool                                 = cast( PFN_vkTrimCommandPool                                 ) vkGetDeviceProcAddr( device, "vkTrimCommandPool" );
    vkGetDeviceQueue2                                 = cast( PFN_vkGetDeviceQueue2                                 ) vkGetDeviceProcAddr( device, "vkGetDeviceQueue2" );
    vkCreateSamplerYcbcrConversion                    = cast( PFN_vkCreateSamplerYcbcrConversion                    ) vkGetDeviceProcAddr( device, "vkCreateSamplerYcbcrConversion" );
    vkDestroySamplerYcbcrConversion                   = cast( PFN_vkDestroySamplerYcbcrConversion                   ) vkGetDeviceProcAddr( device, "vkDestroySamplerYcbcrConversion" );
    vkCreateDescriptorUpdateTemplate                  = cast( PFN_vkCreateDescriptorUpdateTemplate                  ) vkGetDeviceProcAddr( device, "vkCreateDescriptorUpdateTemplate" );
    vkDestroyDescriptorUpdateTemplate                 = cast( PFN_vkDestroyDescriptorUpdateTemplate                 ) vkGetDeviceProcAddr( device, "vkDestroyDescriptorUpdateTemplate" );
    vkUpdateDescriptorSetWithTemplate                 = cast( PFN_vkUpdateDescriptorSetWithTemplate                 ) vkGetDeviceProcAddr( device, "vkUpdateDescriptorSetWithTemplate" );
    vkGetDescriptorSetLayoutSupport                   = cast( PFN_vkGetDescriptorSetLayoutSupport                   ) vkGetDeviceProcAddr( device, "vkGetDescriptorSetLayoutSupport" );

    // VK_VERSION_1_2
    vkCmdDrawIndirectCount                            = cast( PFN_vkCmdDrawIndirectCount                            ) vkGetDeviceProcAddr( device, "vkCmdDrawIndirectCount" );
    vkCmdDrawIndexedIndirectCount                     = cast( PFN_vkCmdDrawIndexedIndirectCount                     ) vkGetDeviceProcAddr( device, "vkCmdDrawIndexedIndirectCount" );
    vkCreateRenderPass2                               = cast( PFN_vkCreateRenderPass2                               ) vkGetDeviceProcAddr( device, "vkCreateRenderPass2" );
    vkCmdBeginRenderPass2                             = cast( PFN_vkCmdBeginRenderPass2                             ) vkGetDeviceProcAddr( device, "vkCmdBeginRenderPass2" );
    vkCmdNextSubpass2                                 = cast( PFN_vkCmdNextSubpass2                                 ) vkGetDeviceProcAddr( device, "vkCmdNextSubpass2" );
    vkCmdEndRenderPass2                               = cast( PFN_vkCmdEndRenderPass2                               ) vkGetDeviceProcAddr( device, "vkCmdEndRenderPass2" );
    vkResetQueryPool                                  = cast( PFN_vkResetQueryPool                                  ) vkGetDeviceProcAddr( device, "vkResetQueryPool" );
    vkGetSemaphoreCounterValue                        = cast( PFN_vkGetSemaphoreCounterValue                        ) vkGetDeviceProcAddr( device, "vkGetSemaphoreCounterValue" );
    vkWaitSemaphores                                  = cast( PFN_vkWaitSemaphores                                  ) vkGetDeviceProcAddr( device, "vkWaitSemaphores" );
    vkSignalSemaphore                                 = cast( PFN_vkSignalSemaphore                                 ) vkGetDeviceProcAddr( device, "vkSignalSemaphore" );
    vkGetBufferDeviceAddress                          = cast( PFN_vkGetBufferDeviceAddress                          ) vkGetDeviceProcAddr( device, "vkGetBufferDeviceAddress" );
    vkGetBufferOpaqueCaptureAddress                   = cast( PFN_vkGetBufferOpaqueCaptureAddress                   ) vkGetDeviceProcAddr( device, "vkGetBufferOpaqueCaptureAddress" );
    vkGetDeviceMemoryOpaqueCaptureAddress             = cast( PFN_vkGetDeviceMemoryOpaqueCaptureAddress             ) vkGetDeviceProcAddr( device, "vkGetDeviceMemoryOpaqueCaptureAddress" );

    // VK_VERSION_1_3
    vkCreatePrivateDataSlot                           = cast( PFN_vkCreatePrivateDataSlot                           ) vkGetDeviceProcAddr( device, "vkCreatePrivateDataSlot" );
    vkDestroyPrivateDataSlot                          = cast( PFN_vkDestroyPrivateDataSlot                          ) vkGetDeviceProcAddr( device, "vkDestroyPrivateDataSlot" );
    vkSetPrivateData                                  = cast( PFN_vkSetPrivateData                                  ) vkGetDeviceProcAddr( device, "vkSetPrivateData" );
    vkGetPrivateData                                  = cast( PFN_vkGetPrivateData                                  ) vkGetDeviceProcAddr( device, "vkGetPrivateData" );
    vkCmdSetEvent2                                    = cast( PFN_vkCmdSetEvent2                                    ) vkGetDeviceProcAddr( device, "vkCmdSetEvent2" );
    vkCmdResetEvent2                                  = cast( PFN_vkCmdResetEvent2                                  ) vkGetDeviceProcAddr( device, "vkCmdResetEvent2" );
    vkCmdWaitEvents2                                  = cast( PFN_vkCmdWaitEvents2                                  ) vkGetDeviceProcAddr( device, "vkCmdWaitEvents2" );
    vkCmdPipelineBarrier2                             = cast( PFN_vkCmdPipelineBarrier2                             ) vkGetDeviceProcAddr( device, "vkCmdPipelineBarrier2" );
    vkCmdWriteTimestamp2                              = cast( PFN_vkCmdWriteTimestamp2                              ) vkGetDeviceProcAddr( device, "vkCmdWriteTimestamp2" );
    vkQueueSubmit2                                    = cast( PFN_vkQueueSubmit2                                    ) vkGetDeviceProcAddr( device, "vkQueueSubmit2" );
    vkCmdCopyBuffer2                                  = cast( PFN_vkCmdCopyBuffer2                                  ) vkGetDeviceProcAddr( device, "vkCmdCopyBuffer2" );
    vkCmdCopyImage2                                   = cast( PFN_vkCmdCopyImage2                                   ) vkGetDeviceProcAddr( device, "vkCmdCopyImage2" );
    vkCmdCopyBufferToImage2                           = cast( PFN_vkCmdCopyBufferToImage2                           ) vkGetDeviceProcAddr( device, "vkCmdCopyBufferToImage2" );
    vkCmdCopyImageToBuffer2                           = cast( PFN_vkCmdCopyImageToBuffer2                           ) vkGetDeviceProcAddr( device, "vkCmdCopyImageToBuffer2" );
    vkCmdBlitImage2                                   = cast( PFN_vkCmdBlitImage2                                   ) vkGetDeviceProcAddr( device, "vkCmdBlitImage2" );
    vkCmdResolveImage2                                = cast( PFN_vkCmdResolveImage2                                ) vkGetDeviceProcAddr( device, "vkCmdResolveImage2" );
    vkCmdBeginRendering                               = cast( PFN_vkCmdBeginRendering                               ) vkGetDeviceProcAddr( device, "vkCmdBeginRendering" );
    vkCmdEndRendering                                 = cast( PFN_vkCmdEndRendering                                 ) vkGetDeviceProcAddr( device, "vkCmdEndRendering" );
    vkCmdSetCullMode                                  = cast( PFN_vkCmdSetCullMode                                  ) vkGetDeviceProcAddr( device, "vkCmdSetCullMode" );
    vkCmdSetFrontFace                                 = cast( PFN_vkCmdSetFrontFace                                 ) vkGetDeviceProcAddr( device, "vkCmdSetFrontFace" );
    vkCmdSetPrimitiveTopology                         = cast( PFN_vkCmdSetPrimitiveTopology                         ) vkGetDeviceProcAddr( device, "vkCmdSetPrimitiveTopology" );
    vkCmdSetViewportWithCount                         = cast( PFN_vkCmdSetViewportWithCount                         ) vkGetDeviceProcAddr( device, "vkCmdSetViewportWithCount" );
    vkCmdSetScissorWithCount                          = cast( PFN_vkCmdSetScissorWithCount                          ) vkGetDeviceProcAddr( device, "vkCmdSetScissorWithCount" );
    vkCmdBindVertexBuffers2                           = cast( PFN_vkCmdBindVertexBuffers2                           ) vkGetDeviceProcAddr( device, "vkCmdBindVertexBuffers2" );
    vkCmdSetDepthTestEnable                           = cast( PFN_vkCmdSetDepthTestEnable                           ) vkGetDeviceProcAddr( device, "vkCmdSetDepthTestEnable" );
    vkCmdSetDepthWriteEnable                          = cast( PFN_vkCmdSetDepthWriteEnable                          ) vkGetDeviceProcAddr( device, "vkCmdSetDepthWriteEnable" );
    vkCmdSetDepthCompareOp                            = cast( PFN_vkCmdSetDepthCompareOp                            ) vkGetDeviceProcAddr( device, "vkCmdSetDepthCompareOp" );
    vkCmdSetDepthBoundsTestEnable                     = cast( PFN_vkCmdSetDepthBoundsTestEnable                     ) vkGetDeviceProcAddr( device, "vkCmdSetDepthBoundsTestEnable" );
    vkCmdSetStencilTestEnable                         = cast( PFN_vkCmdSetStencilTestEnable                         ) vkGetDeviceProcAddr( device, "vkCmdSetStencilTestEnable" );
    vkCmdSetStencilOp                                 = cast( PFN_vkCmdSetStencilOp                                 ) vkGetDeviceProcAddr( device, "vkCmdSetStencilOp" );
    vkCmdSetRasterizerDiscardEnable                   = cast( PFN_vkCmdSetRasterizerDiscardEnable                   ) vkGetDeviceProcAddr( device, "vkCmdSetRasterizerDiscardEnable" );
    vkCmdSetDepthBiasEnable                           = cast( PFN_vkCmdSetDepthBiasEnable                           ) vkGetDeviceProcAddr( device, "vkCmdSetDepthBiasEnable" );
    vkCmdSetPrimitiveRestartEnable                    = cast( PFN_vkCmdSetPrimitiveRestartEnable                    ) vkGetDeviceProcAddr( device, "vkCmdSetPrimitiveRestartEnable" );
    vkGetDeviceBufferMemoryRequirements               = cast( PFN_vkGetDeviceBufferMemoryRequirements               ) vkGetDeviceProcAddr( device, "vkGetDeviceBufferMemoryRequirements" );
    vkGetDeviceImageMemoryRequirements                = cast( PFN_vkGetDeviceImageMemoryRequirements                ) vkGetDeviceProcAddr( device, "vkGetDeviceImageMemoryRequirements" );
    vkGetDeviceImageSparseMemoryRequirements          = cast( PFN_vkGetDeviceImageSparseMemoryRequirements          ) vkGetDeviceProcAddr( device, "vkGetDeviceImageSparseMemoryRequirements" );

    // VK_KHR_swapchain
    vkCreateSwapchainKHR                              = cast( PFN_vkCreateSwapchainKHR                              ) vkGetDeviceProcAddr( device, "vkCreateSwapchainKHR" );
    vkDestroySwapchainKHR                             = cast( PFN_vkDestroySwapchainKHR                             ) vkGetDeviceProcAddr( device, "vkDestroySwapchainKHR" );
    vkGetSwapchainImagesKHR                           = cast( PFN_vkGetSwapchainImagesKHR                           ) vkGetDeviceProcAddr( device, "vkGetSwapchainImagesKHR" );
    vkAcquireNextImageKHR                             = cast( PFN_vkAcquireNextImageKHR                             ) vkGetDeviceProcAddr( device, "vkAcquireNextImageKHR" );
    vkQueuePresentKHR                                 = cast( PFN_vkQueuePresentKHR                                 ) vkGetDeviceProcAddr( device, "vkQueuePresentKHR" );
    vkGetDeviceGroupPresentCapabilitiesKHR            = cast( PFN_vkGetDeviceGroupPresentCapabilitiesKHR            ) vkGetDeviceProcAddr( device, "vkGetDeviceGroupPresentCapabilitiesKHR" );
    vkGetDeviceGroupSurfacePresentModesKHR            = cast( PFN_vkGetDeviceGroupSurfacePresentModesKHR            ) vkGetDeviceProcAddr( device, "vkGetDeviceGroupSurfacePresentModesKHR" );
    vkAcquireNextImage2KHR                            = cast( PFN_vkAcquireNextImage2KHR                            ) vkGetDeviceProcAddr( device, "vkAcquireNextImage2KHR" );

    // VK_KHR_display_swapchain
    vkCreateSharedSwapchainsKHR                       = cast( PFN_vkCreateSharedSwapchainsKHR                       ) vkGetDeviceProcAddr( device, "vkCreateSharedSwapchainsKHR" );

    // VK_KHR_external_memory_fd
    vkGetMemoryFdKHR                                  = cast( PFN_vkGetMemoryFdKHR                                  ) vkGetDeviceProcAddr( device, "vkGetMemoryFdKHR" );
    vkGetMemoryFdPropertiesKHR                        = cast( PFN_vkGetMemoryFdPropertiesKHR                        ) vkGetDeviceProcAddr( device, "vkGetMemoryFdPropertiesKHR" );

    // VK_KHR_external_semaphore_fd
    vkImportSemaphoreFdKHR                            = cast( PFN_vkImportSemaphoreFdKHR                            ) vkGetDeviceProcAddr( device, "vkImportSemaphoreFdKHR" );
    vkGetSemaphoreFdKHR                               = cast( PFN_vkGetSemaphoreFdKHR                               ) vkGetDeviceProcAddr( device, "vkGetSemaphoreFdKHR" );

    // VK_KHR_push_descriptor
    vkCmdPushDescriptorSetKHR                         = cast( PFN_vkCmdPushDescriptorSetKHR                         ) vkGetDeviceProcAddr( device, "vkCmdPushDescriptorSetKHR" );
    vkCmdPushDescriptorSetWithTemplateKHR             = cast( PFN_vkCmdPushDescriptorSetWithTemplateKHR             ) vkGetDeviceProcAddr( device, "vkCmdPushDescriptorSetWithTemplateKHR" );

    // VK_KHR_shared_presentable_image
    vkGetSwapchainStatusKHR                           = cast( PFN_vkGetSwapchainStatusKHR                           ) vkGetDeviceProcAddr( device, "vkGetSwapchainStatusKHR" );

    // VK_KHR_external_fence_fd
    vkImportFenceFdKHR                                = cast( PFN_vkImportFenceFdKHR                                ) vkGetDeviceProcAddr( device, "vkImportFenceFdKHR" );
    vkGetFenceFdKHR                                   = cast( PFN_vkGetFenceFdKHR                                   ) vkGetDeviceProcAddr( device, "vkGetFenceFdKHR" );

    // VK_KHR_performance_query
    vkAcquireProfilingLockKHR                         = cast( PFN_vkAcquireProfilingLockKHR                         ) vkGetDeviceProcAddr( device, "vkAcquireProfilingLockKHR" );
    vkReleaseProfilingLockKHR                         = cast( PFN_vkReleaseProfilingLockKHR                         ) vkGetDeviceProcAddr( device, "vkReleaseProfilingLockKHR" );

    // VK_KHR_fragment_shading_rate
    vkCmdSetFragmentShadingRateKHR                    = cast( PFN_vkCmdSetFragmentShadingRateKHR                    ) vkGetDeviceProcAddr( device, "vkCmdSetFragmentShadingRateKHR" );

    // VK_KHR_present_wait
    vkWaitForPresentKHR                               = cast( PFN_vkWaitForPresentKHR                               ) vkGetDeviceProcAddr( device, "vkWaitForPresentKHR" );

    // VK_KHR_deferred_host_operations
    vkCreateDeferredOperationKHR                      = cast( PFN_vkCreateDeferredOperationKHR                      ) vkGetDeviceProcAddr( device, "vkCreateDeferredOperationKHR" );
    vkDestroyDeferredOperationKHR                     = cast( PFN_vkDestroyDeferredOperationKHR                     ) vkGetDeviceProcAddr( device, "vkDestroyDeferredOperationKHR" );
    vkGetDeferredOperationMaxConcurrencyKHR           = cast( PFN_vkGetDeferredOperationMaxConcurrencyKHR           ) vkGetDeviceProcAddr( device, "vkGetDeferredOperationMaxConcurrencyKHR" );
    vkGetDeferredOperationResultKHR                   = cast( PFN_vkGetDeferredOperationResultKHR                   ) vkGetDeviceProcAddr( device, "vkGetDeferredOperationResultKHR" );
    vkDeferredOperationJoinKHR                        = cast( PFN_vkDeferredOperationJoinKHR                        ) vkGetDeviceProcAddr( device, "vkDeferredOperationJoinKHR" );

    // VK_KHR_pipeline_executable_properties
    vkGetPipelineExecutablePropertiesKHR              = cast( PFN_vkGetPipelineExecutablePropertiesKHR              ) vkGetDeviceProcAddr( device, "vkGetPipelineExecutablePropertiesKHR" );
    vkGetPipelineExecutableStatisticsKHR              = cast( PFN_vkGetPipelineExecutableStatisticsKHR              ) vkGetDeviceProcAddr( device, "vkGetPipelineExecutableStatisticsKHR" );
    vkGetPipelineExecutableInternalRepresentationsKHR = cast( PFN_vkGetPipelineExecutableInternalRepresentationsKHR ) vkGetDeviceProcAddr( device, "vkGetPipelineExecutableInternalRepresentationsKHR" );

    // VK_KHR_synchronization2
    vkCmdWriteBufferMarker2AMD                        = cast( PFN_vkCmdWriteBufferMarker2AMD                        ) vkGetDeviceProcAddr( device, "vkCmdWriteBufferMarker2AMD" );
    vkGetQueueCheckpointData2NV                       = cast( PFN_vkGetQueueCheckpointData2NV                       ) vkGetDeviceProcAddr( device, "vkGetQueueCheckpointData2NV" );

    // VK_KHR_ray_tracing_maintenance1
    vkCmdTraceRaysIndirect2KHR                        = cast( PFN_vkCmdTraceRaysIndirect2KHR                        ) vkGetDeviceProcAddr( device, "vkCmdTraceRaysIndirect2KHR" );

    // VK_EXT_debug_marker
    vkDebugMarkerSetObjectTagEXT                      = cast( PFN_vkDebugMarkerSetObjectTagEXT                      ) vkGetDeviceProcAddr( device, "vkDebugMarkerSetObjectTagEXT" );
    vkDebugMarkerSetObjectNameEXT                     = cast( PFN_vkDebugMarkerSetObjectNameEXT                     ) vkGetDeviceProcAddr( device, "vkDebugMarkerSetObjectNameEXT" );
    vkCmdDebugMarkerBeginEXT                          = cast( PFN_vkCmdDebugMarkerBeginEXT                          ) vkGetDeviceProcAddr( device, "vkCmdDebugMarkerBeginEXT" );
    vkCmdDebugMarkerEndEXT                            = cast( PFN_vkCmdDebugMarkerEndEXT                            ) vkGetDeviceProcAddr( device, "vkCmdDebugMarkerEndEXT" );
    vkCmdDebugMarkerInsertEXT                         = cast( PFN_vkCmdDebugMarkerInsertEXT                         ) vkGetDeviceProcAddr( device, "vkCmdDebugMarkerInsertEXT" );

    // VK_EXT_transform_feedback
    vkCmdBindTransformFeedbackBuffersEXT              = cast( PFN_vkCmdBindTransformFeedbackBuffersEXT              ) vkGetDeviceProcAddr( device, "vkCmdBindTransformFeedbackBuffersEXT" );
    vkCmdBeginTransformFeedbackEXT                    = cast( PFN_vkCmdBeginTransformFeedbackEXT                    ) vkGetDeviceProcAddr( device, "vkCmdBeginTransformFeedbackEXT" );
    vkCmdEndTransformFeedbackEXT                      = cast( PFN_vkCmdEndTransformFeedbackEXT                      ) vkGetDeviceProcAddr( device, "vkCmdEndTransformFeedbackEXT" );
    vkCmdBeginQueryIndexedEXT                         = cast( PFN_vkCmdBeginQueryIndexedEXT                         ) vkGetDeviceProcAddr( device, "vkCmdBeginQueryIndexedEXT" );
    vkCmdEndQueryIndexedEXT                           = cast( PFN_vkCmdEndQueryIndexedEXT                           ) vkGetDeviceProcAddr( device, "vkCmdEndQueryIndexedEXT" );
    vkCmdDrawIndirectByteCountEXT                     = cast( PFN_vkCmdDrawIndirectByteCountEXT                     ) vkGetDeviceProcAddr( device, "vkCmdDrawIndirectByteCountEXT" );

    // VK_NVX_binary_import
    vkCreateCuModuleNVX                               = cast( PFN_vkCreateCuModuleNVX                               ) vkGetDeviceProcAddr( device, "vkCreateCuModuleNVX" );
    vkCreateCuFunctionNVX                             = cast( PFN_vkCreateCuFunctionNVX                             ) vkGetDeviceProcAddr( device, "vkCreateCuFunctionNVX" );
    vkDestroyCuModuleNVX                              = cast( PFN_vkDestroyCuModuleNVX                              ) vkGetDeviceProcAddr( device, "vkDestroyCuModuleNVX" );
    vkDestroyCuFunctionNVX                            = cast( PFN_vkDestroyCuFunctionNVX                            ) vkGetDeviceProcAddr( device, "vkDestroyCuFunctionNVX" );
    vkCmdCuLaunchKernelNVX                            = cast( PFN_vkCmdCuLaunchKernelNVX                            ) vkGetDeviceProcAddr( device, "vkCmdCuLaunchKernelNVX" );

    // VK_NVX_image_view_handle
    vkGetImageViewHandleNVX                           = cast( PFN_vkGetImageViewHandleNVX                           ) vkGetDeviceProcAddr( device, "vkGetImageViewHandleNVX" );
    vkGetImageViewAddressNVX                          = cast( PFN_vkGetImageViewAddressNVX                          ) vkGetDeviceProcAddr( device, "vkGetImageViewAddressNVX" );

    // VK_AMD_shader_info
    vkGetShaderInfoAMD                                = cast( PFN_vkGetShaderInfoAMD                                ) vkGetDeviceProcAddr( device, "vkGetShaderInfoAMD" );

    // VK_EXT_conditional_rendering
    vkCmdBeginConditionalRenderingEXT                 = cast( PFN_vkCmdBeginConditionalRenderingEXT                 ) vkGetDeviceProcAddr( device, "vkCmdBeginConditionalRenderingEXT" );
    vkCmdEndConditionalRenderingEXT                   = cast( PFN_vkCmdEndConditionalRenderingEXT                   ) vkGetDeviceProcAddr( device, "vkCmdEndConditionalRenderingEXT" );

    // VK_NV_clip_space_w_scaling
    vkCmdSetViewportWScalingNV                        = cast( PFN_vkCmdSetViewportWScalingNV                        ) vkGetDeviceProcAddr( device, "vkCmdSetViewportWScalingNV" );

    // VK_EXT_display_control
    vkDisplayPowerControlEXT                          = cast( PFN_vkDisplayPowerControlEXT                          ) vkGetDeviceProcAddr( device, "vkDisplayPowerControlEXT" );
    vkRegisterDeviceEventEXT                          = cast( PFN_vkRegisterDeviceEventEXT                          ) vkGetDeviceProcAddr( device, "vkRegisterDeviceEventEXT" );
    vkRegisterDisplayEventEXT                         = cast( PFN_vkRegisterDisplayEventEXT                         ) vkGetDeviceProcAddr( device, "vkRegisterDisplayEventEXT" );
    vkGetSwapchainCounterEXT                          = cast( PFN_vkGetSwapchainCounterEXT                          ) vkGetDeviceProcAddr( device, "vkGetSwapchainCounterEXT" );

    // VK_GOOGLE_display_timing
    vkGetRefreshCycleDurationGOOGLE                   = cast( PFN_vkGetRefreshCycleDurationGOOGLE                   ) vkGetDeviceProcAddr( device, "vkGetRefreshCycleDurationGOOGLE" );
    vkGetPastPresentationTimingGOOGLE                 = cast( PFN_vkGetPastPresentationTimingGOOGLE                 ) vkGetDeviceProcAddr( device, "vkGetPastPresentationTimingGOOGLE" );

    // VK_EXT_discard_rectangles
    vkCmdSetDiscardRectangleEXT                       = cast( PFN_vkCmdSetDiscardRectangleEXT                       ) vkGetDeviceProcAddr( device, "vkCmdSetDiscardRectangleEXT" );

    // VK_EXT_hdr_metadata
    vkSetHdrMetadataEXT                               = cast( PFN_vkSetHdrMetadataEXT                               ) vkGetDeviceProcAddr( device, "vkSetHdrMetadataEXT" );

    // VK_EXT_debug_utils
    vkSetDebugUtilsObjectNameEXT                      = cast( PFN_vkSetDebugUtilsObjectNameEXT                      ) vkGetDeviceProcAddr( device, "vkSetDebugUtilsObjectNameEXT" );
    vkSetDebugUtilsObjectTagEXT                       = cast( PFN_vkSetDebugUtilsObjectTagEXT                       ) vkGetDeviceProcAddr( device, "vkSetDebugUtilsObjectTagEXT" );
    vkQueueBeginDebugUtilsLabelEXT                    = cast( PFN_vkQueueBeginDebugUtilsLabelEXT                    ) vkGetDeviceProcAddr( device, "vkQueueBeginDebugUtilsLabelEXT" );
    vkQueueEndDebugUtilsLabelEXT                      = cast( PFN_vkQueueEndDebugUtilsLabelEXT                      ) vkGetDeviceProcAddr( device, "vkQueueEndDebugUtilsLabelEXT" );
    vkQueueInsertDebugUtilsLabelEXT                   = cast( PFN_vkQueueInsertDebugUtilsLabelEXT                   ) vkGetDeviceProcAddr( device, "vkQueueInsertDebugUtilsLabelEXT" );
    vkCmdBeginDebugUtilsLabelEXT                      = cast( PFN_vkCmdBeginDebugUtilsLabelEXT                      ) vkGetDeviceProcAddr( device, "vkCmdBeginDebugUtilsLabelEXT" );
    vkCmdEndDebugUtilsLabelEXT                        = cast( PFN_vkCmdEndDebugUtilsLabelEXT                        ) vkGetDeviceProcAddr( device, "vkCmdEndDebugUtilsLabelEXT" );
    vkCmdInsertDebugUtilsLabelEXT                     = cast( PFN_vkCmdInsertDebugUtilsLabelEXT                     ) vkGetDeviceProcAddr( device, "vkCmdInsertDebugUtilsLabelEXT" );

    // VK_EXT_sample_locations
    vkCmdSetSampleLocationsEXT                        = cast( PFN_vkCmdSetSampleLocationsEXT                        ) vkGetDeviceProcAddr( device, "vkCmdSetSampleLocationsEXT" );

    // VK_EXT_image_drm_format_modifier
    vkGetImageDrmFormatModifierPropertiesEXT          = cast( PFN_vkGetImageDrmFormatModifierPropertiesEXT          ) vkGetDeviceProcAddr( device, "vkGetImageDrmFormatModifierPropertiesEXT" );

    // VK_EXT_validation_cache
    vkCreateValidationCacheEXT                        = cast( PFN_vkCreateValidationCacheEXT                        ) vkGetDeviceProcAddr( device, "vkCreateValidationCacheEXT" );
    vkDestroyValidationCacheEXT                       = cast( PFN_vkDestroyValidationCacheEXT                       ) vkGetDeviceProcAddr( device, "vkDestroyValidationCacheEXT" );
    vkMergeValidationCachesEXT                        = cast( PFN_vkMergeValidationCachesEXT                        ) vkGetDeviceProcAddr( device, "vkMergeValidationCachesEXT" );
    vkGetValidationCacheDataEXT                       = cast( PFN_vkGetValidationCacheDataEXT                       ) vkGetDeviceProcAddr( device, "vkGetValidationCacheDataEXT" );

    // VK_NV_shading_rate_image
    vkCmdBindShadingRateImageNV                       = cast( PFN_vkCmdBindShadingRateImageNV                       ) vkGetDeviceProcAddr( device, "vkCmdBindShadingRateImageNV" );
    vkCmdSetViewportShadingRatePaletteNV              = cast( PFN_vkCmdSetViewportShadingRatePaletteNV              ) vkGetDeviceProcAddr( device, "vkCmdSetViewportShadingRatePaletteNV" );
    vkCmdSetCoarseSampleOrderNV                       = cast( PFN_vkCmdSetCoarseSampleOrderNV                       ) vkGetDeviceProcAddr( device, "vkCmdSetCoarseSampleOrderNV" );

    // VK_NV_ray_tracing
    vkCreateAccelerationStructureNV                   = cast( PFN_vkCreateAccelerationStructureNV                   ) vkGetDeviceProcAddr( device, "vkCreateAccelerationStructureNV" );
    vkDestroyAccelerationStructureNV                  = cast( PFN_vkDestroyAccelerationStructureNV                  ) vkGetDeviceProcAddr( device, "vkDestroyAccelerationStructureNV" );
    vkGetAccelerationStructureMemoryRequirementsNV    = cast( PFN_vkGetAccelerationStructureMemoryRequirementsNV    ) vkGetDeviceProcAddr( device, "vkGetAccelerationStructureMemoryRequirementsNV" );
    vkBindAccelerationStructureMemoryNV               = cast( PFN_vkBindAccelerationStructureMemoryNV               ) vkGetDeviceProcAddr( device, "vkBindAccelerationStructureMemoryNV" );
    vkCmdBuildAccelerationStructureNV                 = cast( PFN_vkCmdBuildAccelerationStructureNV                 ) vkGetDeviceProcAddr( device, "vkCmdBuildAccelerationStructureNV" );
    vkCmdCopyAccelerationStructureNV                  = cast( PFN_vkCmdCopyAccelerationStructureNV                  ) vkGetDeviceProcAddr( device, "vkCmdCopyAccelerationStructureNV" );
    vkCmdTraceRaysNV                                  = cast( PFN_vkCmdTraceRaysNV                                  ) vkGetDeviceProcAddr( device, "vkCmdTraceRaysNV" );
    vkCreateRayTracingPipelinesNV                     = cast( PFN_vkCreateRayTracingPipelinesNV                     ) vkGetDeviceProcAddr( device, "vkCreateRayTracingPipelinesNV" );
    vkGetRayTracingShaderGroupHandlesKHR              = cast( PFN_vkGetRayTracingShaderGroupHandlesKHR              ) vkGetDeviceProcAddr( device, "vkGetRayTracingShaderGroupHandlesKHR" );
    vkGetAccelerationStructureHandleNV                = cast( PFN_vkGetAccelerationStructureHandleNV                ) vkGetDeviceProcAddr( device, "vkGetAccelerationStructureHandleNV" );
    vkCmdWriteAccelerationStructuresPropertiesNV      = cast( PFN_vkCmdWriteAccelerationStructuresPropertiesNV      ) vkGetDeviceProcAddr( device, "vkCmdWriteAccelerationStructuresPropertiesNV" );
    vkCompileDeferredNV                               = cast( PFN_vkCompileDeferredNV                               ) vkGetDeviceProcAddr( device, "vkCompileDeferredNV" );

    // VK_EXT_external_memory_host
    vkGetMemoryHostPointerPropertiesEXT               = cast( PFN_vkGetMemoryHostPointerPropertiesEXT               ) vkGetDeviceProcAddr( device, "vkGetMemoryHostPointerPropertiesEXT" );

    // VK_AMD_buffer_marker
    vkCmdWriteBufferMarkerAMD                         = cast( PFN_vkCmdWriteBufferMarkerAMD                         ) vkGetDeviceProcAddr( device, "vkCmdWriteBufferMarkerAMD" );

    // VK_EXT_calibrated_timestamps
    vkGetCalibratedTimestampsEXT                      = cast( PFN_vkGetCalibratedTimestampsEXT                      ) vkGetDeviceProcAddr( device, "vkGetCalibratedTimestampsEXT" );

    // VK_NV_mesh_shader
    vkCmdDrawMeshTasksNV                              = cast( PFN_vkCmdDrawMeshTasksNV                              ) vkGetDeviceProcAddr( device, "vkCmdDrawMeshTasksNV" );
    vkCmdDrawMeshTasksIndirectNV                      = cast( PFN_vkCmdDrawMeshTasksIndirectNV                      ) vkGetDeviceProcAddr( device, "vkCmdDrawMeshTasksIndirectNV" );
    vkCmdDrawMeshTasksIndirectCountNV                 = cast( PFN_vkCmdDrawMeshTasksIndirectCountNV                 ) vkGetDeviceProcAddr( device, "vkCmdDrawMeshTasksIndirectCountNV" );

    // VK_NV_scissor_exclusive
    vkCmdSetExclusiveScissorNV                        = cast( PFN_vkCmdSetExclusiveScissorNV                        ) vkGetDeviceProcAddr( device, "vkCmdSetExclusiveScissorNV" );

    // VK_NV_device_diagnostic_checkpoints
    vkCmdSetCheckpointNV                              = cast( PFN_vkCmdSetCheckpointNV                              ) vkGetDeviceProcAddr( device, "vkCmdSetCheckpointNV" );
    vkGetQueueCheckpointDataNV                        = cast( PFN_vkGetQueueCheckpointDataNV                        ) vkGetDeviceProcAddr( device, "vkGetQueueCheckpointDataNV" );

    // VK_INTEL_performance_query
    vkInitializePerformanceApiINTEL                   = cast( PFN_vkInitializePerformanceApiINTEL                   ) vkGetDeviceProcAddr( device, "vkInitializePerformanceApiINTEL" );
    vkUninitializePerformanceApiINTEL                 = cast( PFN_vkUninitializePerformanceApiINTEL                 ) vkGetDeviceProcAddr( device, "vkUninitializePerformanceApiINTEL" );
    vkCmdSetPerformanceMarkerINTEL                    = cast( PFN_vkCmdSetPerformanceMarkerINTEL                    ) vkGetDeviceProcAddr( device, "vkCmdSetPerformanceMarkerINTEL" );
    vkCmdSetPerformanceStreamMarkerINTEL              = cast( PFN_vkCmdSetPerformanceStreamMarkerINTEL              ) vkGetDeviceProcAddr( device, "vkCmdSetPerformanceStreamMarkerINTEL" );
    vkCmdSetPerformanceOverrideINTEL                  = cast( PFN_vkCmdSetPerformanceOverrideINTEL                  ) vkGetDeviceProcAddr( device, "vkCmdSetPerformanceOverrideINTEL" );
    vkAcquirePerformanceConfigurationINTEL            = cast( PFN_vkAcquirePerformanceConfigurationINTEL            ) vkGetDeviceProcAddr( device, "vkAcquirePerformanceConfigurationINTEL" );
    vkReleasePerformanceConfigurationINTEL            = cast( PFN_vkReleasePerformanceConfigurationINTEL            ) vkGetDeviceProcAddr( device, "vkReleasePerformanceConfigurationINTEL" );
    vkQueueSetPerformanceConfigurationINTEL           = cast( PFN_vkQueueSetPerformanceConfigurationINTEL           ) vkGetDeviceProcAddr( device, "vkQueueSetPerformanceConfigurationINTEL" );
    vkGetPerformanceParameterINTEL                    = cast( PFN_vkGetPerformanceParameterINTEL                    ) vkGetDeviceProcAddr( device, "vkGetPerformanceParameterINTEL" );

    // VK_AMD_display_native_hdr
    vkSetLocalDimmingAMD                              = cast( PFN_vkSetLocalDimmingAMD                              ) vkGetDeviceProcAddr( device, "vkSetLocalDimmingAMD" );

    // VK_EXT_line_rasterization
    vkCmdSetLineStippleEXT                            = cast( PFN_vkCmdSetLineStippleEXT                            ) vkGetDeviceProcAddr( device, "vkCmdSetLineStippleEXT" );

    // VK_NV_device_generated_commands
    vkGetGeneratedCommandsMemoryRequirementsNV        = cast( PFN_vkGetGeneratedCommandsMemoryRequirementsNV        ) vkGetDeviceProcAddr( device, "vkGetGeneratedCommandsMemoryRequirementsNV" );
    vkCmdPreprocessGeneratedCommandsNV                = cast( PFN_vkCmdPreprocessGeneratedCommandsNV                ) vkGetDeviceProcAddr( device, "vkCmdPreprocessGeneratedCommandsNV" );
    vkCmdExecuteGeneratedCommandsNV                   = cast( PFN_vkCmdExecuteGeneratedCommandsNV                   ) vkGetDeviceProcAddr( device, "vkCmdExecuteGeneratedCommandsNV" );
    vkCmdBindPipelineShaderGroupNV                    = cast( PFN_vkCmdBindPipelineShaderGroupNV                    ) vkGetDeviceProcAddr( device, "vkCmdBindPipelineShaderGroupNV" );
    vkCreateIndirectCommandsLayoutNV                  = cast( PFN_vkCreateIndirectCommandsLayoutNV                  ) vkGetDeviceProcAddr( device, "vkCreateIndirectCommandsLayoutNV" );
    vkDestroyIndirectCommandsLayoutNV                 = cast( PFN_vkDestroyIndirectCommandsLayoutNV                 ) vkGetDeviceProcAddr( device, "vkDestroyIndirectCommandsLayoutNV" );

    // VK_NV_fragment_shading_rate_enums
    vkCmdSetFragmentShadingRateEnumNV                 = cast( PFN_vkCmdSetFragmentShadingRateEnumNV                 ) vkGetDeviceProcAddr( device, "vkCmdSetFragmentShadingRateEnumNV" );

    // VK_EXT_image_compression_control
    vkGetImageSubresourceLayout2EXT                   = cast( PFN_vkGetImageSubresourceLayout2EXT                   ) vkGetDeviceProcAddr( device, "vkGetImageSubresourceLayout2EXT" );

    // VK_EXT_vertex_input_dynamic_state
    vkCmdSetVertexInputEXT                            = cast( PFN_vkCmdSetVertexInputEXT                            ) vkGetDeviceProcAddr( device, "vkCmdSetVertexInputEXT" );

    // VK_HUAWEI_subpass_shading
    vkGetDeviceSubpassShadingMaxWorkgroupSizeHUAWEI   = cast( PFN_vkGetDeviceSubpassShadingMaxWorkgroupSizeHUAWEI   ) vkGetDeviceProcAddr( device, "vkGetDeviceSubpassShadingMaxWorkgroupSizeHUAWEI" );
    vkCmdSubpassShadingHUAWEI                         = cast( PFN_vkCmdSubpassShadingHUAWEI                         ) vkGetDeviceProcAddr( device, "vkCmdSubpassShadingHUAWEI" );

    // VK_HUAWEI_invocation_mask
    vkCmdBindInvocationMaskHUAWEI                     = cast( PFN_vkCmdBindInvocationMaskHUAWEI                     ) vkGetDeviceProcAddr( device, "vkCmdBindInvocationMaskHUAWEI" );

    // VK_NV_external_memory_rdma
    vkGetMemoryRemoteAddressNV                        = cast( PFN_vkGetMemoryRemoteAddressNV                        ) vkGetDeviceProcAddr( device, "vkGetMemoryRemoteAddressNV" );

    // VK_EXT_pipeline_properties
    vkGetPipelinePropertiesEXT                        = cast( PFN_vkGetPipelinePropertiesEXT                        ) vkGetDeviceProcAddr( device, "vkGetPipelinePropertiesEXT" );

    // VK_EXT_extended_dynamic_state2
    vkCmdSetPatchControlPointsEXT                     = cast( PFN_vkCmdSetPatchControlPointsEXT                     ) vkGetDeviceProcAddr( device, "vkCmdSetPatchControlPointsEXT" );
    vkCmdSetLogicOpEXT                                = cast( PFN_vkCmdSetLogicOpEXT                                ) vkGetDeviceProcAddr( device, "vkCmdSetLogicOpEXT" );

    // VK_EXT_color_write_enable
    vkCmdSetColorWriteEnableEXT                       = cast( PFN_vkCmdSetColorWriteEnableEXT                       ) vkGetDeviceProcAddr( device, "vkCmdSetColorWriteEnableEXT" );

    // VK_EXT_multi_draw
    vkCmdDrawMultiEXT                                 = cast( PFN_vkCmdDrawMultiEXT                                 ) vkGetDeviceProcAddr( device, "vkCmdDrawMultiEXT" );
    vkCmdDrawMultiIndexedEXT                          = cast( PFN_vkCmdDrawMultiIndexedEXT                          ) vkGetDeviceProcAddr( device, "vkCmdDrawMultiIndexedEXT" );

    // VK_EXT_pageable_device_local_memory
    vkSetDeviceMemoryPriorityEXT                      = cast( PFN_vkSetDeviceMemoryPriorityEXT                      ) vkGetDeviceProcAddr( device, "vkSetDeviceMemoryPriorityEXT" );

    // VK_VALVE_descriptor_set_host_mapping
    vkGetDescriptorSetLayoutHostMappingInfoVALVE      = cast( PFN_vkGetDescriptorSetLayoutHostMappingInfoVALVE      ) vkGetDeviceProcAddr( device, "vkGetDescriptorSetLayoutHostMappingInfoVALVE" );
    vkGetDescriptorSetHostMappingVALVE                = cast( PFN_vkGetDescriptorSetHostMappingVALVE                ) vkGetDeviceProcAddr( device, "vkGetDescriptorSetHostMappingVALVE" );

    // VK_KHR_acceleration_structure
    vkCreateAccelerationStructureKHR                  = cast( PFN_vkCreateAccelerationStructureKHR                  ) vkGetDeviceProcAddr( device, "vkCreateAccelerationStructureKHR" );
    vkDestroyAccelerationStructureKHR                 = cast( PFN_vkDestroyAccelerationStructureKHR                 ) vkGetDeviceProcAddr( device, "vkDestroyAccelerationStructureKHR" );
    vkCmdBuildAccelerationStructuresKHR               = cast( PFN_vkCmdBuildAccelerationStructuresKHR               ) vkGetDeviceProcAddr( device, "vkCmdBuildAccelerationStructuresKHR" );
    vkCmdBuildAccelerationStructuresIndirectKHR       = cast( PFN_vkCmdBuildAccelerationStructuresIndirectKHR       ) vkGetDeviceProcAddr( device, "vkCmdBuildAccelerationStructuresIndirectKHR" );
    vkBuildAccelerationStructuresKHR                  = cast( PFN_vkBuildAccelerationStructuresKHR                  ) vkGetDeviceProcAddr( device, "vkBuildAccelerationStructuresKHR" );
    vkCopyAccelerationStructureKHR                    = cast( PFN_vkCopyAccelerationStructureKHR                    ) vkGetDeviceProcAddr( device, "vkCopyAccelerationStructureKHR" );
    vkCopyAccelerationStructureToMemoryKHR            = cast( PFN_vkCopyAccelerationStructureToMemoryKHR            ) vkGetDeviceProcAddr( device, "vkCopyAccelerationStructureToMemoryKHR" );
    vkCopyMemoryToAccelerationStructureKHR            = cast( PFN_vkCopyMemoryToAccelerationStructureKHR            ) vkGetDeviceProcAddr( device, "vkCopyMemoryToAccelerationStructureKHR" );
    vkWriteAccelerationStructuresPropertiesKHR        = cast( PFN_vkWriteAccelerationStructuresPropertiesKHR        ) vkGetDeviceProcAddr( device, "vkWriteAccelerationStructuresPropertiesKHR" );
    vkCmdCopyAccelerationStructureKHR                 = cast( PFN_vkCmdCopyAccelerationStructureKHR                 ) vkGetDeviceProcAddr( device, "vkCmdCopyAccelerationStructureKHR" );
    vkCmdCopyAccelerationStructureToMemoryKHR         = cast( PFN_vkCmdCopyAccelerationStructureToMemoryKHR         ) vkGetDeviceProcAddr( device, "vkCmdCopyAccelerationStructureToMemoryKHR" );
    vkCmdCopyMemoryToAccelerationStructureKHR         = cast( PFN_vkCmdCopyMemoryToAccelerationStructureKHR         ) vkGetDeviceProcAddr( device, "vkCmdCopyMemoryToAccelerationStructureKHR" );
    vkGetAccelerationStructureDeviceAddressKHR        = cast( PFN_vkGetAccelerationStructureDeviceAddressKHR        ) vkGetDeviceProcAddr( device, "vkGetAccelerationStructureDeviceAddressKHR" );
    vkCmdWriteAccelerationStructuresPropertiesKHR     = cast( PFN_vkCmdWriteAccelerationStructuresPropertiesKHR     ) vkGetDeviceProcAddr( device, "vkCmdWriteAccelerationStructuresPropertiesKHR" );
    vkGetDeviceAccelerationStructureCompatibilityKHR  = cast( PFN_vkGetDeviceAccelerationStructureCompatibilityKHR  ) vkGetDeviceProcAddr( device, "vkGetDeviceAccelerationStructureCompatibilityKHR" );
    vkGetAccelerationStructureBuildSizesKHR           = cast( PFN_vkGetAccelerationStructureBuildSizesKHR           ) vkGetDeviceProcAddr( device, "vkGetAccelerationStructureBuildSizesKHR" );

    // VK_KHR_ray_tracing_pipeline
    vkCmdTraceRaysKHR                                 = cast( PFN_vkCmdTraceRaysKHR                                 ) vkGetDeviceProcAddr( device, "vkCmdTraceRaysKHR" );
    vkCreateRayTracingPipelinesKHR                    = cast( PFN_vkCreateRayTracingPipelinesKHR                    ) vkGetDeviceProcAddr( device, "vkCreateRayTracingPipelinesKHR" );
    vkGetRayTracingCaptureReplayShaderGroupHandlesKHR = cast( PFN_vkGetRayTracingCaptureReplayShaderGroupHandlesKHR ) vkGetDeviceProcAddr( device, "vkGetRayTracingCaptureReplayShaderGroupHandlesKHR" );
    vkCmdTraceRaysIndirectKHR                         = cast( PFN_vkCmdTraceRaysIndirectKHR                         ) vkGetDeviceProcAddr( device, "vkCmdTraceRaysIndirectKHR" );
    vkGetRayTracingShaderGroupStackSizeKHR            = cast( PFN_vkGetRayTracingShaderGroupStackSizeKHR            ) vkGetDeviceProcAddr( device, "vkGetRayTracingShaderGroupStackSizeKHR" );
    vkCmdSetRayTracingPipelineStackSizeKHR            = cast( PFN_vkCmdSetRayTracingPipelineStackSizeKHR            ) vkGetDeviceProcAddr( device, "vkCmdSetRayTracingPipelineStackSizeKHR" );
}

