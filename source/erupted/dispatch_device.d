/**
 * Dlang vulkan device related func loader as struct members
 *
 * Copyright: Copyright 2015-2016 The Khronos Group Inc.; Copyright 2016 Alex Parrill, Peter Particle.
 * License:   $(https://opensource.org/licenses/MIT, MIT License).
 * Authors: Copyright 2016 Alex Parrill, Peter Particle
 */
module erupted.dispatch_device;

public import erupted.types;
import erupted.functions;

nothrow @nogc:


/// struct to group per device device level functions into a custom namespace
/// keeps track of the device to which the functions are bound
/// additionally to the device related vulkan functions, convenience functions exist
/// with same name but omitting the vk prefix as well as the first (VkDevice) parameter
/// these functions forward to their vk counterparts using the VkDevice member of the DispatchDevice
/// Moreover the same convenience functions exist for vkCmd... functions. In this case the
/// first parameter is substituted with the public member VkCommandBuffer commandBuffer,
/// which must have been set to a valid command buffer before usage.
struct DispatchDevice {

    private VkDevice                           device          = VK_NULL_HANDLE;
    private const( VkAllocationCallbacks )*    allocator       = null;
    VkCommandBuffer                            commandBuffer   = VK_NULL_HANDLE;


    /// return copy of the internal VkDevice
    VkDevice vkDevice() {
        return device;
    }


    /// return const allocator address
    const( VkAllocationCallbacks )* pAllocator() {
        return allocator;
    }


    /// constructor forwards parameter 'device' to 'this.loadDeviceLevelFunctions'
    this( VkDevice device, const( VkAllocationCallbacks )* allocator = null ) {
        this.loadDeviceLevelFunctions( device );
    }


    /// load the device level member functions
    /// this also sets the private member 'device' to the passed in VkDevice
    /// as well as the otional host allocator
    /// if a custom allocator is required it must be specified here and cannot be changed throughout the liftime of the device
    /// now the DispatchDevice can be used e.g.:
    ///      auto dd = DispatchDevice( device );
    ///      dd.vkDestroyDevice( dd.vkDevice, pAllocator );
    /// convenience functions to omit the first arg and the allocator do exist, see bellow
    void loadDeviceLevelFunctions( VkDevice device, const( VkAllocationCallbacks )* allocator = null ) {
        assert( vkGetInstanceProcAddr !is null, "Function pointer vkGetInstanceProcAddr is null!\nCall loadGlobalLevelFunctions -> loadInstanceLevelFunctions -> DispatchDevice.loadDeviceLevelFunctions" );
        this.allocator = allocator;
        this.device = device;

        // VK_VERSION_1_0
        vkDestroyDevice                                = cast( PFN_vkDestroyDevice                                ) vkGetDeviceProcAddr( device, "vkDestroyDevice" );
        vkGetDeviceQueue                               = cast( PFN_vkGetDeviceQueue                               ) vkGetDeviceProcAddr( device, "vkGetDeviceQueue" );
        vkQueueSubmit                                  = cast( PFN_vkQueueSubmit                                  ) vkGetDeviceProcAddr( device, "vkQueueSubmit" );
        vkQueueWaitIdle                                = cast( PFN_vkQueueWaitIdle                                ) vkGetDeviceProcAddr( device, "vkQueueWaitIdle" );
        vkDeviceWaitIdle                               = cast( PFN_vkDeviceWaitIdle                               ) vkGetDeviceProcAddr( device, "vkDeviceWaitIdle" );
        vkAllocateMemory                               = cast( PFN_vkAllocateMemory                               ) vkGetDeviceProcAddr( device, "vkAllocateMemory" );
        vkFreeMemory                                   = cast( PFN_vkFreeMemory                                   ) vkGetDeviceProcAddr( device, "vkFreeMemory" );
        vkMapMemory                                    = cast( PFN_vkMapMemory                                    ) vkGetDeviceProcAddr( device, "vkMapMemory" );
        vkUnmapMemory                                  = cast( PFN_vkUnmapMemory                                  ) vkGetDeviceProcAddr( device, "vkUnmapMemory" );
        vkFlushMappedMemoryRanges                      = cast( PFN_vkFlushMappedMemoryRanges                      ) vkGetDeviceProcAddr( device, "vkFlushMappedMemoryRanges" );
        vkInvalidateMappedMemoryRanges                 = cast( PFN_vkInvalidateMappedMemoryRanges                 ) vkGetDeviceProcAddr( device, "vkInvalidateMappedMemoryRanges" );
        vkGetDeviceMemoryCommitment                    = cast( PFN_vkGetDeviceMemoryCommitment                    ) vkGetDeviceProcAddr( device, "vkGetDeviceMemoryCommitment" );
        vkBindBufferMemory                             = cast( PFN_vkBindBufferMemory                             ) vkGetDeviceProcAddr( device, "vkBindBufferMemory" );
        vkBindImageMemory                              = cast( PFN_vkBindImageMemory                              ) vkGetDeviceProcAddr( device, "vkBindImageMemory" );
        vkGetBufferMemoryRequirements                  = cast( PFN_vkGetBufferMemoryRequirements                  ) vkGetDeviceProcAddr( device, "vkGetBufferMemoryRequirements" );
        vkGetImageMemoryRequirements                   = cast( PFN_vkGetImageMemoryRequirements                   ) vkGetDeviceProcAddr( device, "vkGetImageMemoryRequirements" );
        vkGetImageSparseMemoryRequirements             = cast( PFN_vkGetImageSparseMemoryRequirements             ) vkGetDeviceProcAddr( device, "vkGetImageSparseMemoryRequirements" );
        vkQueueBindSparse                              = cast( PFN_vkQueueBindSparse                              ) vkGetDeviceProcAddr( device, "vkQueueBindSparse" );
        vkCreateFence                                  = cast( PFN_vkCreateFence                                  ) vkGetDeviceProcAddr( device, "vkCreateFence" );
        vkDestroyFence                                 = cast( PFN_vkDestroyFence                                 ) vkGetDeviceProcAddr( device, "vkDestroyFence" );
        vkResetFences                                  = cast( PFN_vkResetFences                                  ) vkGetDeviceProcAddr( device, "vkResetFences" );
        vkGetFenceStatus                               = cast( PFN_vkGetFenceStatus                               ) vkGetDeviceProcAddr( device, "vkGetFenceStatus" );
        vkWaitForFences                                = cast( PFN_vkWaitForFences                                ) vkGetDeviceProcAddr( device, "vkWaitForFences" );
        vkCreateSemaphore                              = cast( PFN_vkCreateSemaphore                              ) vkGetDeviceProcAddr( device, "vkCreateSemaphore" );
        vkDestroySemaphore                             = cast( PFN_vkDestroySemaphore                             ) vkGetDeviceProcAddr( device, "vkDestroySemaphore" );
        vkCreateEvent                                  = cast( PFN_vkCreateEvent                                  ) vkGetDeviceProcAddr( device, "vkCreateEvent" );
        vkDestroyEvent                                 = cast( PFN_vkDestroyEvent                                 ) vkGetDeviceProcAddr( device, "vkDestroyEvent" );
        vkGetEventStatus                               = cast( PFN_vkGetEventStatus                               ) vkGetDeviceProcAddr( device, "vkGetEventStatus" );
        vkSetEvent                                     = cast( PFN_vkSetEvent                                     ) vkGetDeviceProcAddr( device, "vkSetEvent" );
        vkResetEvent                                   = cast( PFN_vkResetEvent                                   ) vkGetDeviceProcAddr( device, "vkResetEvent" );
        vkCreateQueryPool                              = cast( PFN_vkCreateQueryPool                              ) vkGetDeviceProcAddr( device, "vkCreateQueryPool" );
        vkDestroyQueryPool                             = cast( PFN_vkDestroyQueryPool                             ) vkGetDeviceProcAddr( device, "vkDestroyQueryPool" );
        vkGetQueryPoolResults                          = cast( PFN_vkGetQueryPoolResults                          ) vkGetDeviceProcAddr( device, "vkGetQueryPoolResults" );
        vkCreateBuffer                                 = cast( PFN_vkCreateBuffer                                 ) vkGetDeviceProcAddr( device, "vkCreateBuffer" );
        vkDestroyBuffer                                = cast( PFN_vkDestroyBuffer                                ) vkGetDeviceProcAddr( device, "vkDestroyBuffer" );
        vkCreateBufferView                             = cast( PFN_vkCreateBufferView                             ) vkGetDeviceProcAddr( device, "vkCreateBufferView" );
        vkDestroyBufferView                            = cast( PFN_vkDestroyBufferView                            ) vkGetDeviceProcAddr( device, "vkDestroyBufferView" );
        vkCreateImage                                  = cast( PFN_vkCreateImage                                  ) vkGetDeviceProcAddr( device, "vkCreateImage" );
        vkDestroyImage                                 = cast( PFN_vkDestroyImage                                 ) vkGetDeviceProcAddr( device, "vkDestroyImage" );
        vkGetImageSubresourceLayout                    = cast( PFN_vkGetImageSubresourceLayout                    ) vkGetDeviceProcAddr( device, "vkGetImageSubresourceLayout" );
        vkCreateImageView                              = cast( PFN_vkCreateImageView                              ) vkGetDeviceProcAddr( device, "vkCreateImageView" );
        vkDestroyImageView                             = cast( PFN_vkDestroyImageView                             ) vkGetDeviceProcAddr( device, "vkDestroyImageView" );
        vkCreateShaderModule                           = cast( PFN_vkCreateShaderModule                           ) vkGetDeviceProcAddr( device, "vkCreateShaderModule" );
        vkDestroyShaderModule                          = cast( PFN_vkDestroyShaderModule                          ) vkGetDeviceProcAddr( device, "vkDestroyShaderModule" );
        vkCreatePipelineCache                          = cast( PFN_vkCreatePipelineCache                          ) vkGetDeviceProcAddr( device, "vkCreatePipelineCache" );
        vkDestroyPipelineCache                         = cast( PFN_vkDestroyPipelineCache                         ) vkGetDeviceProcAddr( device, "vkDestroyPipelineCache" );
        vkGetPipelineCacheData                         = cast( PFN_vkGetPipelineCacheData                         ) vkGetDeviceProcAddr( device, "vkGetPipelineCacheData" );
        vkMergePipelineCaches                          = cast( PFN_vkMergePipelineCaches                          ) vkGetDeviceProcAddr( device, "vkMergePipelineCaches" );
        vkCreateGraphicsPipelines                      = cast( PFN_vkCreateGraphicsPipelines                      ) vkGetDeviceProcAddr( device, "vkCreateGraphicsPipelines" );
        vkCreateComputePipelines                       = cast( PFN_vkCreateComputePipelines                       ) vkGetDeviceProcAddr( device, "vkCreateComputePipelines" );
        vkDestroyPipeline                              = cast( PFN_vkDestroyPipeline                              ) vkGetDeviceProcAddr( device, "vkDestroyPipeline" );
        vkCreatePipelineLayout                         = cast( PFN_vkCreatePipelineLayout                         ) vkGetDeviceProcAddr( device, "vkCreatePipelineLayout" );
        vkDestroyPipelineLayout                        = cast( PFN_vkDestroyPipelineLayout                        ) vkGetDeviceProcAddr( device, "vkDestroyPipelineLayout" );
        vkCreateSampler                                = cast( PFN_vkCreateSampler                                ) vkGetDeviceProcAddr( device, "vkCreateSampler" );
        vkDestroySampler                               = cast( PFN_vkDestroySampler                               ) vkGetDeviceProcAddr( device, "vkDestroySampler" );
        vkCreateDescriptorSetLayout                    = cast( PFN_vkCreateDescriptorSetLayout                    ) vkGetDeviceProcAddr( device, "vkCreateDescriptorSetLayout" );
        vkDestroyDescriptorSetLayout                   = cast( PFN_vkDestroyDescriptorSetLayout                   ) vkGetDeviceProcAddr( device, "vkDestroyDescriptorSetLayout" );
        vkCreateDescriptorPool                         = cast( PFN_vkCreateDescriptorPool                         ) vkGetDeviceProcAddr( device, "vkCreateDescriptorPool" );
        vkDestroyDescriptorPool                        = cast( PFN_vkDestroyDescriptorPool                        ) vkGetDeviceProcAddr( device, "vkDestroyDescriptorPool" );
        vkResetDescriptorPool                          = cast( PFN_vkResetDescriptorPool                          ) vkGetDeviceProcAddr( device, "vkResetDescriptorPool" );
        vkAllocateDescriptorSets                       = cast( PFN_vkAllocateDescriptorSets                       ) vkGetDeviceProcAddr( device, "vkAllocateDescriptorSets" );
        vkFreeDescriptorSets                           = cast( PFN_vkFreeDescriptorSets                           ) vkGetDeviceProcAddr( device, "vkFreeDescriptorSets" );
        vkUpdateDescriptorSets                         = cast( PFN_vkUpdateDescriptorSets                         ) vkGetDeviceProcAddr( device, "vkUpdateDescriptorSets" );
        vkCreateFramebuffer                            = cast( PFN_vkCreateFramebuffer                            ) vkGetDeviceProcAddr( device, "vkCreateFramebuffer" );
        vkDestroyFramebuffer                           = cast( PFN_vkDestroyFramebuffer                           ) vkGetDeviceProcAddr( device, "vkDestroyFramebuffer" );
        vkCreateRenderPass                             = cast( PFN_vkCreateRenderPass                             ) vkGetDeviceProcAddr( device, "vkCreateRenderPass" );
        vkDestroyRenderPass                            = cast( PFN_vkDestroyRenderPass                            ) vkGetDeviceProcAddr( device, "vkDestroyRenderPass" );
        vkGetRenderAreaGranularity                     = cast( PFN_vkGetRenderAreaGranularity                     ) vkGetDeviceProcAddr( device, "vkGetRenderAreaGranularity" );
        vkCreateCommandPool                            = cast( PFN_vkCreateCommandPool                            ) vkGetDeviceProcAddr( device, "vkCreateCommandPool" );
        vkDestroyCommandPool                           = cast( PFN_vkDestroyCommandPool                           ) vkGetDeviceProcAddr( device, "vkDestroyCommandPool" );
        vkResetCommandPool                             = cast( PFN_vkResetCommandPool                             ) vkGetDeviceProcAddr( device, "vkResetCommandPool" );
        vkAllocateCommandBuffers                       = cast( PFN_vkAllocateCommandBuffers                       ) vkGetDeviceProcAddr( device, "vkAllocateCommandBuffers" );
        vkFreeCommandBuffers                           = cast( PFN_vkFreeCommandBuffers                           ) vkGetDeviceProcAddr( device, "vkFreeCommandBuffers" );
        vkBeginCommandBuffer                           = cast( PFN_vkBeginCommandBuffer                           ) vkGetDeviceProcAddr( device, "vkBeginCommandBuffer" );
        vkEndCommandBuffer                             = cast( PFN_vkEndCommandBuffer                             ) vkGetDeviceProcAddr( device, "vkEndCommandBuffer" );
        vkResetCommandBuffer                           = cast( PFN_vkResetCommandBuffer                           ) vkGetDeviceProcAddr( device, "vkResetCommandBuffer" );
        vkCmdBindPipeline                              = cast( PFN_vkCmdBindPipeline                              ) vkGetDeviceProcAddr( device, "vkCmdBindPipeline" );
        vkCmdSetViewport                               = cast( PFN_vkCmdSetViewport                               ) vkGetDeviceProcAddr( device, "vkCmdSetViewport" );
        vkCmdSetScissor                                = cast( PFN_vkCmdSetScissor                                ) vkGetDeviceProcAddr( device, "vkCmdSetScissor" );
        vkCmdSetLineWidth                              = cast( PFN_vkCmdSetLineWidth                              ) vkGetDeviceProcAddr( device, "vkCmdSetLineWidth" );
        vkCmdSetDepthBias                              = cast( PFN_vkCmdSetDepthBias                              ) vkGetDeviceProcAddr( device, "vkCmdSetDepthBias" );
        vkCmdSetBlendConstants                         = cast( PFN_vkCmdSetBlendConstants                         ) vkGetDeviceProcAddr( device, "vkCmdSetBlendConstants" );
        vkCmdSetDepthBounds                            = cast( PFN_vkCmdSetDepthBounds                            ) vkGetDeviceProcAddr( device, "vkCmdSetDepthBounds" );
        vkCmdSetStencilCompareMask                     = cast( PFN_vkCmdSetStencilCompareMask                     ) vkGetDeviceProcAddr( device, "vkCmdSetStencilCompareMask" );
        vkCmdSetStencilWriteMask                       = cast( PFN_vkCmdSetStencilWriteMask                       ) vkGetDeviceProcAddr( device, "vkCmdSetStencilWriteMask" );
        vkCmdSetStencilReference                       = cast( PFN_vkCmdSetStencilReference                       ) vkGetDeviceProcAddr( device, "vkCmdSetStencilReference" );
        vkCmdBindDescriptorSets                        = cast( PFN_vkCmdBindDescriptorSets                        ) vkGetDeviceProcAddr( device, "vkCmdBindDescriptorSets" );
        vkCmdBindIndexBuffer                           = cast( PFN_vkCmdBindIndexBuffer                           ) vkGetDeviceProcAddr( device, "vkCmdBindIndexBuffer" );
        vkCmdBindVertexBuffers                         = cast( PFN_vkCmdBindVertexBuffers                         ) vkGetDeviceProcAddr( device, "vkCmdBindVertexBuffers" );
        vkCmdDraw                                      = cast( PFN_vkCmdDraw                                      ) vkGetDeviceProcAddr( device, "vkCmdDraw" );
        vkCmdDrawIndexed                               = cast( PFN_vkCmdDrawIndexed                               ) vkGetDeviceProcAddr( device, "vkCmdDrawIndexed" );
        vkCmdDrawIndirect                              = cast( PFN_vkCmdDrawIndirect                              ) vkGetDeviceProcAddr( device, "vkCmdDrawIndirect" );
        vkCmdDrawIndexedIndirect                       = cast( PFN_vkCmdDrawIndexedIndirect                       ) vkGetDeviceProcAddr( device, "vkCmdDrawIndexedIndirect" );
        vkCmdDispatch                                  = cast( PFN_vkCmdDispatch                                  ) vkGetDeviceProcAddr( device, "vkCmdDispatch" );
        vkCmdDispatchIndirect                          = cast( PFN_vkCmdDispatchIndirect                          ) vkGetDeviceProcAddr( device, "vkCmdDispatchIndirect" );
        vkCmdCopyBuffer                                = cast( PFN_vkCmdCopyBuffer                                ) vkGetDeviceProcAddr( device, "vkCmdCopyBuffer" );
        vkCmdCopyImage                                 = cast( PFN_vkCmdCopyImage                                 ) vkGetDeviceProcAddr( device, "vkCmdCopyImage" );
        vkCmdBlitImage                                 = cast( PFN_vkCmdBlitImage                                 ) vkGetDeviceProcAddr( device, "vkCmdBlitImage" );
        vkCmdCopyBufferToImage                         = cast( PFN_vkCmdCopyBufferToImage                         ) vkGetDeviceProcAddr( device, "vkCmdCopyBufferToImage" );
        vkCmdCopyImageToBuffer                         = cast( PFN_vkCmdCopyImageToBuffer                         ) vkGetDeviceProcAddr( device, "vkCmdCopyImageToBuffer" );
        vkCmdUpdateBuffer                              = cast( PFN_vkCmdUpdateBuffer                              ) vkGetDeviceProcAddr( device, "vkCmdUpdateBuffer" );
        vkCmdFillBuffer                                = cast( PFN_vkCmdFillBuffer                                ) vkGetDeviceProcAddr( device, "vkCmdFillBuffer" );
        vkCmdClearColorImage                           = cast( PFN_vkCmdClearColorImage                           ) vkGetDeviceProcAddr( device, "vkCmdClearColorImage" );
        vkCmdClearDepthStencilImage                    = cast( PFN_vkCmdClearDepthStencilImage                    ) vkGetDeviceProcAddr( device, "vkCmdClearDepthStencilImage" );
        vkCmdClearAttachments                          = cast( PFN_vkCmdClearAttachments                          ) vkGetDeviceProcAddr( device, "vkCmdClearAttachments" );
        vkCmdResolveImage                              = cast( PFN_vkCmdResolveImage                              ) vkGetDeviceProcAddr( device, "vkCmdResolveImage" );
        vkCmdSetEvent                                  = cast( PFN_vkCmdSetEvent                                  ) vkGetDeviceProcAddr( device, "vkCmdSetEvent" );
        vkCmdResetEvent                                = cast( PFN_vkCmdResetEvent                                ) vkGetDeviceProcAddr( device, "vkCmdResetEvent" );
        vkCmdWaitEvents                                = cast( PFN_vkCmdWaitEvents                                ) vkGetDeviceProcAddr( device, "vkCmdWaitEvents" );
        vkCmdPipelineBarrier                           = cast( PFN_vkCmdPipelineBarrier                           ) vkGetDeviceProcAddr( device, "vkCmdPipelineBarrier" );
        vkCmdBeginQuery                                = cast( PFN_vkCmdBeginQuery                                ) vkGetDeviceProcAddr( device, "vkCmdBeginQuery" );
        vkCmdEndQuery                                  = cast( PFN_vkCmdEndQuery                                  ) vkGetDeviceProcAddr( device, "vkCmdEndQuery" );
        vkCmdResetQueryPool                            = cast( PFN_vkCmdResetQueryPool                            ) vkGetDeviceProcAddr( device, "vkCmdResetQueryPool" );
        vkCmdWriteTimestamp                            = cast( PFN_vkCmdWriteTimestamp                            ) vkGetDeviceProcAddr( device, "vkCmdWriteTimestamp" );
        vkCmdCopyQueryPoolResults                      = cast( PFN_vkCmdCopyQueryPoolResults                      ) vkGetDeviceProcAddr( device, "vkCmdCopyQueryPoolResults" );
        vkCmdPushConstants                             = cast( PFN_vkCmdPushConstants                             ) vkGetDeviceProcAddr( device, "vkCmdPushConstants" );
        vkCmdBeginRenderPass                           = cast( PFN_vkCmdBeginRenderPass                           ) vkGetDeviceProcAddr( device, "vkCmdBeginRenderPass" );
        vkCmdNextSubpass                               = cast( PFN_vkCmdNextSubpass                               ) vkGetDeviceProcAddr( device, "vkCmdNextSubpass" );
        vkCmdEndRenderPass                             = cast( PFN_vkCmdEndRenderPass                             ) vkGetDeviceProcAddr( device, "vkCmdEndRenderPass" );
        vkCmdExecuteCommands                           = cast( PFN_vkCmdExecuteCommands                           ) vkGetDeviceProcAddr( device, "vkCmdExecuteCommands" );

        // VK_VERSION_1_1
        vkBindBufferMemory2                            = cast( PFN_vkBindBufferMemory2                            ) vkGetDeviceProcAddr( device, "vkBindBufferMemory2" );
        vkBindImageMemory2                             = cast( PFN_vkBindImageMemory2                             ) vkGetDeviceProcAddr( device, "vkBindImageMemory2" );
        vkGetDeviceGroupPeerMemoryFeatures             = cast( PFN_vkGetDeviceGroupPeerMemoryFeatures             ) vkGetDeviceProcAddr( device, "vkGetDeviceGroupPeerMemoryFeatures" );
        vkCmdSetDeviceMask                             = cast( PFN_vkCmdSetDeviceMask                             ) vkGetDeviceProcAddr( device, "vkCmdSetDeviceMask" );
        vkCmdDispatchBase                              = cast( PFN_vkCmdDispatchBase                              ) vkGetDeviceProcAddr( device, "vkCmdDispatchBase" );
        vkGetImageMemoryRequirements2                  = cast( PFN_vkGetImageMemoryRequirements2                  ) vkGetDeviceProcAddr( device, "vkGetImageMemoryRequirements2" );
        vkGetBufferMemoryRequirements2                 = cast( PFN_vkGetBufferMemoryRequirements2                 ) vkGetDeviceProcAddr( device, "vkGetBufferMemoryRequirements2" );
        vkGetImageSparseMemoryRequirements2            = cast( PFN_vkGetImageSparseMemoryRequirements2            ) vkGetDeviceProcAddr( device, "vkGetImageSparseMemoryRequirements2" );
        vkTrimCommandPool                              = cast( PFN_vkTrimCommandPool                              ) vkGetDeviceProcAddr( device, "vkTrimCommandPool" );
        vkGetDeviceQueue2                              = cast( PFN_vkGetDeviceQueue2                              ) vkGetDeviceProcAddr( device, "vkGetDeviceQueue2" );
        vkCreateSamplerYcbcrConversion                 = cast( PFN_vkCreateSamplerYcbcrConversion                 ) vkGetDeviceProcAddr( device, "vkCreateSamplerYcbcrConversion" );
        vkDestroySamplerYcbcrConversion                = cast( PFN_vkDestroySamplerYcbcrConversion                ) vkGetDeviceProcAddr( device, "vkDestroySamplerYcbcrConversion" );
        vkCreateDescriptorUpdateTemplate               = cast( PFN_vkCreateDescriptorUpdateTemplate               ) vkGetDeviceProcAddr( device, "vkCreateDescriptorUpdateTemplate" );
        vkDestroyDescriptorUpdateTemplate              = cast( PFN_vkDestroyDescriptorUpdateTemplate              ) vkGetDeviceProcAddr( device, "vkDestroyDescriptorUpdateTemplate" );
        vkUpdateDescriptorSetWithTemplate              = cast( PFN_vkUpdateDescriptorSetWithTemplate              ) vkGetDeviceProcAddr( device, "vkUpdateDescriptorSetWithTemplate" );
        vkGetDescriptorSetLayoutSupport                = cast( PFN_vkGetDescriptorSetLayoutSupport                ) vkGetDeviceProcAddr( device, "vkGetDescriptorSetLayoutSupport" );

        // VK_KHR_swapchain
        vkCreateSwapchainKHR                           = cast( PFN_vkCreateSwapchainKHR                           ) vkGetDeviceProcAddr( device, "vkCreateSwapchainKHR" );
        vkDestroySwapchainKHR                          = cast( PFN_vkDestroySwapchainKHR                          ) vkGetDeviceProcAddr( device, "vkDestroySwapchainKHR" );
        vkGetSwapchainImagesKHR                        = cast( PFN_vkGetSwapchainImagesKHR                        ) vkGetDeviceProcAddr( device, "vkGetSwapchainImagesKHR" );
        vkAcquireNextImageKHR                          = cast( PFN_vkAcquireNextImageKHR                          ) vkGetDeviceProcAddr( device, "vkAcquireNextImageKHR" );
        vkQueuePresentKHR                              = cast( PFN_vkQueuePresentKHR                              ) vkGetDeviceProcAddr( device, "vkQueuePresentKHR" );
        vkGetDeviceGroupPresentCapabilitiesKHR         = cast( PFN_vkGetDeviceGroupPresentCapabilitiesKHR         ) vkGetDeviceProcAddr( device, "vkGetDeviceGroupPresentCapabilitiesKHR" );
        vkGetDeviceGroupSurfacePresentModesKHR         = cast( PFN_vkGetDeviceGroupSurfacePresentModesKHR         ) vkGetDeviceProcAddr( device, "vkGetDeviceGroupSurfacePresentModesKHR" );
        vkAcquireNextImage2KHR                         = cast( PFN_vkAcquireNextImage2KHR                         ) vkGetDeviceProcAddr( device, "vkAcquireNextImage2KHR" );

        // VK_KHR_display_swapchain
        vkCreateSharedSwapchainsKHR                    = cast( PFN_vkCreateSharedSwapchainsKHR                    ) vkGetDeviceProcAddr( device, "vkCreateSharedSwapchainsKHR" );

        // VK_KHR_external_memory_fd
        vkGetMemoryFdKHR                               = cast( PFN_vkGetMemoryFdKHR                               ) vkGetDeviceProcAddr( device, "vkGetMemoryFdKHR" );
        vkGetMemoryFdPropertiesKHR                     = cast( PFN_vkGetMemoryFdPropertiesKHR                     ) vkGetDeviceProcAddr( device, "vkGetMemoryFdPropertiesKHR" );

        // VK_KHR_external_semaphore_fd
        vkImportSemaphoreFdKHR                         = cast( PFN_vkImportSemaphoreFdKHR                         ) vkGetDeviceProcAddr( device, "vkImportSemaphoreFdKHR" );
        vkGetSemaphoreFdKHR                            = cast( PFN_vkGetSemaphoreFdKHR                            ) vkGetDeviceProcAddr( device, "vkGetSemaphoreFdKHR" );

        // VK_KHR_push_descriptor
        vkCmdPushDescriptorSetKHR                      = cast( PFN_vkCmdPushDescriptorSetKHR                      ) vkGetDeviceProcAddr( device, "vkCmdPushDescriptorSetKHR" );
        vkCmdPushDescriptorSetWithTemplateKHR          = cast( PFN_vkCmdPushDescriptorSetWithTemplateKHR          ) vkGetDeviceProcAddr( device, "vkCmdPushDescriptorSetWithTemplateKHR" );

        // VK_KHR_create_renderpass2
        vkCreateRenderPass2KHR                         = cast( PFN_vkCreateRenderPass2KHR                         ) vkGetDeviceProcAddr( device, "vkCreateRenderPass2KHR" );
        vkCmdBeginRenderPass2KHR                       = cast( PFN_vkCmdBeginRenderPass2KHR                       ) vkGetDeviceProcAddr( device, "vkCmdBeginRenderPass2KHR" );
        vkCmdNextSubpass2KHR                           = cast( PFN_vkCmdNextSubpass2KHR                           ) vkGetDeviceProcAddr( device, "vkCmdNextSubpass2KHR" );
        vkCmdEndRenderPass2KHR                         = cast( PFN_vkCmdEndRenderPass2KHR                         ) vkGetDeviceProcAddr( device, "vkCmdEndRenderPass2KHR" );

        // VK_KHR_shared_presentable_image
        vkGetSwapchainStatusKHR                        = cast( PFN_vkGetSwapchainStatusKHR                        ) vkGetDeviceProcAddr( device, "vkGetSwapchainStatusKHR" );

        // VK_KHR_external_fence_fd
        vkImportFenceFdKHR                             = cast( PFN_vkImportFenceFdKHR                             ) vkGetDeviceProcAddr( device, "vkImportFenceFdKHR" );
        vkGetFenceFdKHR                                = cast( PFN_vkGetFenceFdKHR                                ) vkGetDeviceProcAddr( device, "vkGetFenceFdKHR" );

        // VK_KHR_draw_indirect_count
        vkCmdDrawIndirectCountKHR                      = cast( PFN_vkCmdDrawIndirectCountKHR                      ) vkGetDeviceProcAddr( device, "vkCmdDrawIndirectCountKHR" );
        vkCmdDrawIndexedIndirectCountKHR               = cast( PFN_vkCmdDrawIndexedIndirectCountKHR               ) vkGetDeviceProcAddr( device, "vkCmdDrawIndexedIndirectCountKHR" );

        // VK_EXT_debug_marker
        vkDebugMarkerSetObjectTagEXT                   = cast( PFN_vkDebugMarkerSetObjectTagEXT                   ) vkGetDeviceProcAddr( device, "vkDebugMarkerSetObjectTagEXT" );
        vkDebugMarkerSetObjectNameEXT                  = cast( PFN_vkDebugMarkerSetObjectNameEXT                  ) vkGetDeviceProcAddr( device, "vkDebugMarkerSetObjectNameEXT" );
        vkCmdDebugMarkerBeginEXT                       = cast( PFN_vkCmdDebugMarkerBeginEXT                       ) vkGetDeviceProcAddr( device, "vkCmdDebugMarkerBeginEXT" );
        vkCmdDebugMarkerEndEXT                         = cast( PFN_vkCmdDebugMarkerEndEXT                         ) vkGetDeviceProcAddr( device, "vkCmdDebugMarkerEndEXT" );
        vkCmdDebugMarkerInsertEXT                      = cast( PFN_vkCmdDebugMarkerInsertEXT                      ) vkGetDeviceProcAddr( device, "vkCmdDebugMarkerInsertEXT" );

        // VK_EXT_transform_feedback
        vkCmdBindTransformFeedbackBuffersEXT           = cast( PFN_vkCmdBindTransformFeedbackBuffersEXT           ) vkGetDeviceProcAddr( device, "vkCmdBindTransformFeedbackBuffersEXT" );
        vkCmdBeginTransformFeedbackEXT                 = cast( PFN_vkCmdBeginTransformFeedbackEXT                 ) vkGetDeviceProcAddr( device, "vkCmdBeginTransformFeedbackEXT" );
        vkCmdEndTransformFeedbackEXT                   = cast( PFN_vkCmdEndTransformFeedbackEXT                   ) vkGetDeviceProcAddr( device, "vkCmdEndTransformFeedbackEXT" );
        vkCmdBeginQueryIndexedEXT                      = cast( PFN_vkCmdBeginQueryIndexedEXT                      ) vkGetDeviceProcAddr( device, "vkCmdBeginQueryIndexedEXT" );
        vkCmdEndQueryIndexedEXT                        = cast( PFN_vkCmdEndQueryIndexedEXT                        ) vkGetDeviceProcAddr( device, "vkCmdEndQueryIndexedEXT" );
        vkCmdDrawIndirectByteCountEXT                  = cast( PFN_vkCmdDrawIndirectByteCountEXT                  ) vkGetDeviceProcAddr( device, "vkCmdDrawIndirectByteCountEXT" );

        // VK_NVX_image_view_handle
        vkGetImageViewHandleNVX                        = cast( PFN_vkGetImageViewHandleNVX                        ) vkGetDeviceProcAddr( device, "vkGetImageViewHandleNVX" );

        // VK_AMD_shader_info
        vkGetShaderInfoAMD                             = cast( PFN_vkGetShaderInfoAMD                             ) vkGetDeviceProcAddr( device, "vkGetShaderInfoAMD" );

        // VK_EXT_conditional_rendering
        vkCmdBeginConditionalRenderingEXT              = cast( PFN_vkCmdBeginConditionalRenderingEXT              ) vkGetDeviceProcAddr( device, "vkCmdBeginConditionalRenderingEXT" );
        vkCmdEndConditionalRenderingEXT                = cast( PFN_vkCmdEndConditionalRenderingEXT                ) vkGetDeviceProcAddr( device, "vkCmdEndConditionalRenderingEXT" );

        // VK_NVX_device_generated_commands
        vkCmdProcessCommandsNVX                        = cast( PFN_vkCmdProcessCommandsNVX                        ) vkGetDeviceProcAddr( device, "vkCmdProcessCommandsNVX" );
        vkCmdReserveSpaceForCommandsNVX                = cast( PFN_vkCmdReserveSpaceForCommandsNVX                ) vkGetDeviceProcAddr( device, "vkCmdReserveSpaceForCommandsNVX" );
        vkCreateIndirectCommandsLayoutNVX              = cast( PFN_vkCreateIndirectCommandsLayoutNVX              ) vkGetDeviceProcAddr( device, "vkCreateIndirectCommandsLayoutNVX" );
        vkDestroyIndirectCommandsLayoutNVX             = cast( PFN_vkDestroyIndirectCommandsLayoutNVX             ) vkGetDeviceProcAddr( device, "vkDestroyIndirectCommandsLayoutNVX" );
        vkCreateObjectTableNVX                         = cast( PFN_vkCreateObjectTableNVX                         ) vkGetDeviceProcAddr( device, "vkCreateObjectTableNVX" );
        vkDestroyObjectTableNVX                        = cast( PFN_vkDestroyObjectTableNVX                        ) vkGetDeviceProcAddr( device, "vkDestroyObjectTableNVX" );
        vkRegisterObjectsNVX                           = cast( PFN_vkRegisterObjectsNVX                           ) vkGetDeviceProcAddr( device, "vkRegisterObjectsNVX" );
        vkUnregisterObjectsNVX                         = cast( PFN_vkUnregisterObjectsNVX                         ) vkGetDeviceProcAddr( device, "vkUnregisterObjectsNVX" );

        // VK_NV_clip_space_w_scaling
        vkCmdSetViewportWScalingNV                     = cast( PFN_vkCmdSetViewportWScalingNV                     ) vkGetDeviceProcAddr( device, "vkCmdSetViewportWScalingNV" );

        // VK_EXT_display_control
        vkDisplayPowerControlEXT                       = cast( PFN_vkDisplayPowerControlEXT                       ) vkGetDeviceProcAddr( device, "vkDisplayPowerControlEXT" );
        vkRegisterDeviceEventEXT                       = cast( PFN_vkRegisterDeviceEventEXT                       ) vkGetDeviceProcAddr( device, "vkRegisterDeviceEventEXT" );
        vkRegisterDisplayEventEXT                      = cast( PFN_vkRegisterDisplayEventEXT                      ) vkGetDeviceProcAddr( device, "vkRegisterDisplayEventEXT" );
        vkGetSwapchainCounterEXT                       = cast( PFN_vkGetSwapchainCounterEXT                       ) vkGetDeviceProcAddr( device, "vkGetSwapchainCounterEXT" );

        // VK_GOOGLE_display_timing
        vkGetRefreshCycleDurationGOOGLE                = cast( PFN_vkGetRefreshCycleDurationGOOGLE                ) vkGetDeviceProcAddr( device, "vkGetRefreshCycleDurationGOOGLE" );
        vkGetPastPresentationTimingGOOGLE              = cast( PFN_vkGetPastPresentationTimingGOOGLE              ) vkGetDeviceProcAddr( device, "vkGetPastPresentationTimingGOOGLE" );

        // VK_EXT_discard_rectangles
        vkCmdSetDiscardRectangleEXT                    = cast( PFN_vkCmdSetDiscardRectangleEXT                    ) vkGetDeviceProcAddr( device, "vkCmdSetDiscardRectangleEXT" );

        // VK_EXT_hdr_metadata
        vkSetHdrMetadataEXT                            = cast( PFN_vkSetHdrMetadataEXT                            ) vkGetDeviceProcAddr( device, "vkSetHdrMetadataEXT" );

        // VK_EXT_debug_utils
        vkSetDebugUtilsObjectNameEXT                   = cast( PFN_vkSetDebugUtilsObjectNameEXT                   ) vkGetDeviceProcAddr( device, "vkSetDebugUtilsObjectNameEXT" );
        vkSetDebugUtilsObjectTagEXT                    = cast( PFN_vkSetDebugUtilsObjectTagEXT                    ) vkGetDeviceProcAddr( device, "vkSetDebugUtilsObjectTagEXT" );
        vkQueueBeginDebugUtilsLabelEXT                 = cast( PFN_vkQueueBeginDebugUtilsLabelEXT                 ) vkGetDeviceProcAddr( device, "vkQueueBeginDebugUtilsLabelEXT" );
        vkQueueEndDebugUtilsLabelEXT                   = cast( PFN_vkQueueEndDebugUtilsLabelEXT                   ) vkGetDeviceProcAddr( device, "vkQueueEndDebugUtilsLabelEXT" );
        vkQueueInsertDebugUtilsLabelEXT                = cast( PFN_vkQueueInsertDebugUtilsLabelEXT                ) vkGetDeviceProcAddr( device, "vkQueueInsertDebugUtilsLabelEXT" );
        vkCmdBeginDebugUtilsLabelEXT                   = cast( PFN_vkCmdBeginDebugUtilsLabelEXT                   ) vkGetDeviceProcAddr( device, "vkCmdBeginDebugUtilsLabelEXT" );
        vkCmdEndDebugUtilsLabelEXT                     = cast( PFN_vkCmdEndDebugUtilsLabelEXT                     ) vkGetDeviceProcAddr( device, "vkCmdEndDebugUtilsLabelEXT" );
        vkCmdInsertDebugUtilsLabelEXT                  = cast( PFN_vkCmdInsertDebugUtilsLabelEXT                  ) vkGetDeviceProcAddr( device, "vkCmdInsertDebugUtilsLabelEXT" );

        // VK_EXT_sample_locations
        vkCmdSetSampleLocationsEXT                     = cast( PFN_vkCmdSetSampleLocationsEXT                     ) vkGetDeviceProcAddr( device, "vkCmdSetSampleLocationsEXT" );

        // VK_EXT_image_drm_format_modifier
        vkGetImageDrmFormatModifierPropertiesEXT       = cast( PFN_vkGetImageDrmFormatModifierPropertiesEXT       ) vkGetDeviceProcAddr( device, "vkGetImageDrmFormatModifierPropertiesEXT" );

        // VK_EXT_validation_cache
        vkCreateValidationCacheEXT                     = cast( PFN_vkCreateValidationCacheEXT                     ) vkGetDeviceProcAddr( device, "vkCreateValidationCacheEXT" );
        vkDestroyValidationCacheEXT                    = cast( PFN_vkDestroyValidationCacheEXT                    ) vkGetDeviceProcAddr( device, "vkDestroyValidationCacheEXT" );
        vkMergeValidationCachesEXT                     = cast( PFN_vkMergeValidationCachesEXT                     ) vkGetDeviceProcAddr( device, "vkMergeValidationCachesEXT" );
        vkGetValidationCacheDataEXT                    = cast( PFN_vkGetValidationCacheDataEXT                    ) vkGetDeviceProcAddr( device, "vkGetValidationCacheDataEXT" );

        // VK_NV_shading_rate_image
        vkCmdBindShadingRateImageNV                    = cast( PFN_vkCmdBindShadingRateImageNV                    ) vkGetDeviceProcAddr( device, "vkCmdBindShadingRateImageNV" );
        vkCmdSetViewportShadingRatePaletteNV           = cast( PFN_vkCmdSetViewportShadingRatePaletteNV           ) vkGetDeviceProcAddr( device, "vkCmdSetViewportShadingRatePaletteNV" );
        vkCmdSetCoarseSampleOrderNV                    = cast( PFN_vkCmdSetCoarseSampleOrderNV                    ) vkGetDeviceProcAddr( device, "vkCmdSetCoarseSampleOrderNV" );

        // VK_NV_ray_tracing
        vkCreateAccelerationStructureNV                = cast( PFN_vkCreateAccelerationStructureNV                ) vkGetDeviceProcAddr( device, "vkCreateAccelerationStructureNV" );
        vkDestroyAccelerationStructureNV               = cast( PFN_vkDestroyAccelerationStructureNV               ) vkGetDeviceProcAddr( device, "vkDestroyAccelerationStructureNV" );
        vkGetAccelerationStructureMemoryRequirementsNV = cast( PFN_vkGetAccelerationStructureMemoryRequirementsNV ) vkGetDeviceProcAddr( device, "vkGetAccelerationStructureMemoryRequirementsNV" );
        vkBindAccelerationStructureMemoryNV            = cast( PFN_vkBindAccelerationStructureMemoryNV            ) vkGetDeviceProcAddr( device, "vkBindAccelerationStructureMemoryNV" );
        vkCmdBuildAccelerationStructureNV              = cast( PFN_vkCmdBuildAccelerationStructureNV              ) vkGetDeviceProcAddr( device, "vkCmdBuildAccelerationStructureNV" );
        vkCmdCopyAccelerationStructureNV               = cast( PFN_vkCmdCopyAccelerationStructureNV               ) vkGetDeviceProcAddr( device, "vkCmdCopyAccelerationStructureNV" );
        vkCmdTraceRaysNV                               = cast( PFN_vkCmdTraceRaysNV                               ) vkGetDeviceProcAddr( device, "vkCmdTraceRaysNV" );
        vkCreateRayTracingPipelinesNV                  = cast( PFN_vkCreateRayTracingPipelinesNV                  ) vkGetDeviceProcAddr( device, "vkCreateRayTracingPipelinesNV" );
        vkGetRayTracingShaderGroupHandlesNV            = cast( PFN_vkGetRayTracingShaderGroupHandlesNV            ) vkGetDeviceProcAddr( device, "vkGetRayTracingShaderGroupHandlesNV" );
        vkGetAccelerationStructureHandleNV             = cast( PFN_vkGetAccelerationStructureHandleNV             ) vkGetDeviceProcAddr( device, "vkGetAccelerationStructureHandleNV" );
        vkCmdWriteAccelerationStructuresPropertiesNV   = cast( PFN_vkCmdWriteAccelerationStructuresPropertiesNV   ) vkGetDeviceProcAddr( device, "vkCmdWriteAccelerationStructuresPropertiesNV" );
        vkCompileDeferredNV                            = cast( PFN_vkCompileDeferredNV                            ) vkGetDeviceProcAddr( device, "vkCompileDeferredNV" );

        // VK_EXT_external_memory_host
        vkGetMemoryHostPointerPropertiesEXT            = cast( PFN_vkGetMemoryHostPointerPropertiesEXT            ) vkGetDeviceProcAddr( device, "vkGetMemoryHostPointerPropertiesEXT" );

        // VK_AMD_buffer_marker
        vkCmdWriteBufferMarkerAMD                      = cast( PFN_vkCmdWriteBufferMarkerAMD                      ) vkGetDeviceProcAddr( device, "vkCmdWriteBufferMarkerAMD" );

        // VK_EXT_calibrated_timestamps
        vkGetCalibratedTimestampsEXT                   = cast( PFN_vkGetCalibratedTimestampsEXT                   ) vkGetDeviceProcAddr( device, "vkGetCalibratedTimestampsEXT" );

        // VK_NV_mesh_shader
        vkCmdDrawMeshTasksNV                           = cast( PFN_vkCmdDrawMeshTasksNV                           ) vkGetDeviceProcAddr( device, "vkCmdDrawMeshTasksNV" );
        vkCmdDrawMeshTasksIndirectNV                   = cast( PFN_vkCmdDrawMeshTasksIndirectNV                   ) vkGetDeviceProcAddr( device, "vkCmdDrawMeshTasksIndirectNV" );
        vkCmdDrawMeshTasksIndirectCountNV              = cast( PFN_vkCmdDrawMeshTasksIndirectCountNV              ) vkGetDeviceProcAddr( device, "vkCmdDrawMeshTasksIndirectCountNV" );

        // VK_NV_scissor_exclusive
        vkCmdSetExclusiveScissorNV                     = cast( PFN_vkCmdSetExclusiveScissorNV                     ) vkGetDeviceProcAddr( device, "vkCmdSetExclusiveScissorNV" );

        // VK_NV_device_diagnostic_checkpoints
        vkCmdSetCheckpointNV                           = cast( PFN_vkCmdSetCheckpointNV                           ) vkGetDeviceProcAddr( device, "vkCmdSetCheckpointNV" );
        vkGetQueueCheckpointDataNV                     = cast( PFN_vkGetQueueCheckpointDataNV                     ) vkGetDeviceProcAddr( device, "vkGetQueueCheckpointDataNV" );

        // VK_INTEL_performance_query
        vkInitializePerformanceApiINTEL                = cast( PFN_vkInitializePerformanceApiINTEL                ) vkGetDeviceProcAddr( device, "vkInitializePerformanceApiINTEL" );
        vkUninitializePerformanceApiINTEL              = cast( PFN_vkUninitializePerformanceApiINTEL              ) vkGetDeviceProcAddr( device, "vkUninitializePerformanceApiINTEL" );
        vkCmdSetPerformanceMarkerINTEL                 = cast( PFN_vkCmdSetPerformanceMarkerINTEL                 ) vkGetDeviceProcAddr( device, "vkCmdSetPerformanceMarkerINTEL" );
        vkCmdSetPerformanceStreamMarkerINTEL           = cast( PFN_vkCmdSetPerformanceStreamMarkerINTEL           ) vkGetDeviceProcAddr( device, "vkCmdSetPerformanceStreamMarkerINTEL" );
        vkCmdSetPerformanceOverrideINTEL               = cast( PFN_vkCmdSetPerformanceOverrideINTEL               ) vkGetDeviceProcAddr( device, "vkCmdSetPerformanceOverrideINTEL" );
        vkAcquirePerformanceConfigurationINTEL         = cast( PFN_vkAcquirePerformanceConfigurationINTEL         ) vkGetDeviceProcAddr( device, "vkAcquirePerformanceConfigurationINTEL" );
        vkReleasePerformanceConfigurationINTEL         = cast( PFN_vkReleasePerformanceConfigurationINTEL         ) vkGetDeviceProcAddr( device, "vkReleasePerformanceConfigurationINTEL" );
        vkQueueSetPerformanceConfigurationINTEL        = cast( PFN_vkQueueSetPerformanceConfigurationINTEL        ) vkGetDeviceProcAddr( device, "vkQueueSetPerformanceConfigurationINTEL" );
        vkGetPerformanceParameterINTEL                 = cast( PFN_vkGetPerformanceParameterINTEL                 ) vkGetDeviceProcAddr( device, "vkGetPerformanceParameterINTEL" );

        // VK_AMD_display_native_hdr
        vkSetLocalDimmingAMD                           = cast( PFN_vkSetLocalDimmingAMD                           ) vkGetDeviceProcAddr( device, "vkSetLocalDimmingAMD" );

        // VK_EXT_buffer_device_address
        vkGetBufferDeviceAddressEXT                    = cast( PFN_vkGetBufferDeviceAddressEXT                    ) vkGetDeviceProcAddr( device, "vkGetBufferDeviceAddressEXT" );

        // VK_EXT_host_query_reset
        vkResetQueryPoolEXT                            = cast( PFN_vkResetQueryPoolEXT                            ) vkGetDeviceProcAddr( device, "vkResetQueryPoolEXT" );
    }


    /// convenience member functions, forwarded to corresponding vulkan functions
    /// parameters of type VkDevice, const( VkAllocationCallbacks )* and VkCommandBuffer are omitted
    /// they will be supplied by the member properties vkDevice, pAllocator and the public member commandBuffer
    /// e.g.:
    ///      auto dd = DispatchDevice( device );
    ///      dd.DestroyDevice();       // instead of: dd.vkDestroyDevice( dd.vkDevice, pAllocator );
    ///
    /// Same mechanism works with functions which require a VkCommandBuffer as first arg
    /// In this case the public member 'commandBuffer' must be set beforehand
    /// e.g.:
    ///      dd.commandBuffer = some_command_buffer;
    ///      dd.BeginCommandBuffer( &beginInfo );
    ///      dd.CmdBindPipeline( VK_PIPELINE_BIND_POINT_GRAPHICS, some_pipeline );
    ///
    /// Does not work with queues, there are just too few queue related functions

    // VK_VERSION_1_0
    void      DestroyDevice() { vkDestroyDevice( vkDevice, pAllocator ); }
    void      GetDeviceQueue( uint32_t queueFamilyIndex, uint32_t queueIndex, VkQueue* pQueue ) { vkGetDeviceQueue( vkDevice, queueFamilyIndex, queueIndex, pQueue ); }
    VkResult  DeviceWaitIdle() { return vkDeviceWaitIdle( vkDevice ); }
    VkResult  AllocateMemory( const( VkMemoryAllocateInfo )* pAllocateInfo, VkDeviceMemory* pMemory ) { return vkAllocateMemory( vkDevice, pAllocateInfo, pAllocator, pMemory ); }
    void      FreeMemory( VkDeviceMemory memory ) { vkFreeMemory( vkDevice, memory, pAllocator ); }
    VkResult  MapMemory( VkDeviceMemory memory, VkDeviceSize offset, VkDeviceSize size, VkMemoryMapFlags flags, void** ppData ) { return vkMapMemory( vkDevice, memory, offset, size, flags, ppData ); }
    void      UnmapMemory( VkDeviceMemory memory ) { vkUnmapMemory( vkDevice, memory ); }
    VkResult  FlushMappedMemoryRanges( uint32_t memoryRangeCount, const( VkMappedMemoryRange )* pMemoryRanges ) { return vkFlushMappedMemoryRanges( vkDevice, memoryRangeCount, pMemoryRanges ); }
    VkResult  InvalidateMappedMemoryRanges( uint32_t memoryRangeCount, const( VkMappedMemoryRange )* pMemoryRanges ) { return vkInvalidateMappedMemoryRanges( vkDevice, memoryRangeCount, pMemoryRanges ); }
    void      GetDeviceMemoryCommitment( VkDeviceMemory memory, VkDeviceSize* pCommittedMemoryInBytes ) { vkGetDeviceMemoryCommitment( vkDevice, memory, pCommittedMemoryInBytes ); }
    VkResult  BindBufferMemory( VkBuffer buffer, VkDeviceMemory memory, VkDeviceSize memoryOffset ) { return vkBindBufferMemory( vkDevice, buffer, memory, memoryOffset ); }
    VkResult  BindImageMemory( VkImage image, VkDeviceMemory memory, VkDeviceSize memoryOffset ) { return vkBindImageMemory( vkDevice, image, memory, memoryOffset ); }
    void      GetBufferMemoryRequirements( VkBuffer buffer, VkMemoryRequirements* pMemoryRequirements ) { vkGetBufferMemoryRequirements( vkDevice, buffer, pMemoryRequirements ); }
    void      GetImageMemoryRequirements( VkImage image, VkMemoryRequirements* pMemoryRequirements ) { vkGetImageMemoryRequirements( vkDevice, image, pMemoryRequirements ); }
    void      GetImageSparseMemoryRequirements( VkImage image, uint32_t* pSparseMemoryRequirementCount, VkSparseImageMemoryRequirements* pSparseMemoryRequirements ) { vkGetImageSparseMemoryRequirements( vkDevice, image, pSparseMemoryRequirementCount, pSparseMemoryRequirements ); }
    VkResult  CreateFence( const( VkFenceCreateInfo )* pCreateInfo, VkFence* pFence ) { return vkCreateFence( vkDevice, pCreateInfo, pAllocator, pFence ); }
    void      DestroyFence( VkFence fence ) { vkDestroyFence( vkDevice, fence, pAllocator ); }
    VkResult  ResetFences( uint32_t fenceCount, const( VkFence )* pFences ) { return vkResetFences( vkDevice, fenceCount, pFences ); }
    VkResult  GetFenceStatus( VkFence fence ) { return vkGetFenceStatus( vkDevice, fence ); }
    VkResult  WaitForFences( uint32_t fenceCount, const( VkFence )* pFences, VkBool32 waitAll, uint64_t timeout ) { return vkWaitForFences( vkDevice, fenceCount, pFences, waitAll, timeout ); }
    VkResult  CreateSemaphore( const( VkSemaphoreCreateInfo )* pCreateInfo, VkSemaphore* pSemaphore ) { return vkCreateSemaphore( vkDevice, pCreateInfo, pAllocator, pSemaphore ); }
    void      DestroySemaphore( VkSemaphore semaphore ) { vkDestroySemaphore( vkDevice, semaphore, pAllocator ); }
    VkResult  CreateEvent( const( VkEventCreateInfo )* pCreateInfo, VkEvent* pEvent ) { return vkCreateEvent( vkDevice, pCreateInfo, pAllocator, pEvent ); }
    void      DestroyEvent( VkEvent event ) { vkDestroyEvent( vkDevice, event, pAllocator ); }
    VkResult  GetEventStatus( VkEvent event ) { return vkGetEventStatus( vkDevice, event ); }
    VkResult  SetEvent( VkEvent event ) { return vkSetEvent( vkDevice, event ); }
    VkResult  ResetEvent( VkEvent event ) { return vkResetEvent( vkDevice, event ); }
    VkResult  CreateQueryPool( const( VkQueryPoolCreateInfo )* pCreateInfo, VkQueryPool* pQueryPool ) { return vkCreateQueryPool( vkDevice, pCreateInfo, pAllocator, pQueryPool ); }
    void      DestroyQueryPool( VkQueryPool queryPool ) { vkDestroyQueryPool( vkDevice, queryPool, pAllocator ); }
    VkResult  GetQueryPoolResults( VkQueryPool queryPool, uint32_t firstQuery, uint32_t queryCount, size_t dataSize, void* pData, VkDeviceSize stride, VkQueryResultFlags flags ) { return vkGetQueryPoolResults( vkDevice, queryPool, firstQuery, queryCount, dataSize, pData, stride, flags ); }
    VkResult  CreateBuffer( const( VkBufferCreateInfo )* pCreateInfo, VkBuffer* pBuffer ) { return vkCreateBuffer( vkDevice, pCreateInfo, pAllocator, pBuffer ); }
    void      DestroyBuffer( VkBuffer buffer ) { vkDestroyBuffer( vkDevice, buffer, pAllocator ); }
    VkResult  CreateBufferView( const( VkBufferViewCreateInfo )* pCreateInfo, VkBufferView* pView ) { return vkCreateBufferView( vkDevice, pCreateInfo, pAllocator, pView ); }
    void      DestroyBufferView( VkBufferView bufferView ) { vkDestroyBufferView( vkDevice, bufferView, pAllocator ); }
    VkResult  CreateImage( const( VkImageCreateInfo )* pCreateInfo, VkImage* pImage ) { return vkCreateImage( vkDevice, pCreateInfo, pAllocator, pImage ); }
    void      DestroyImage( VkImage image ) { vkDestroyImage( vkDevice, image, pAllocator ); }
    void      GetImageSubresourceLayout( VkImage image, const( VkImageSubresource )* pSubresource, VkSubresourceLayout* pLayout ) { vkGetImageSubresourceLayout( vkDevice, image, pSubresource, pLayout ); }
    VkResult  CreateImageView( const( VkImageViewCreateInfo )* pCreateInfo, VkImageView* pView ) { return vkCreateImageView( vkDevice, pCreateInfo, pAllocator, pView ); }
    void      DestroyImageView( VkImageView imageView ) { vkDestroyImageView( vkDevice, imageView, pAllocator ); }
    VkResult  CreateShaderModule( const( VkShaderModuleCreateInfo )* pCreateInfo, VkShaderModule* pShaderModule ) { return vkCreateShaderModule( vkDevice, pCreateInfo, pAllocator, pShaderModule ); }
    void      DestroyShaderModule( VkShaderModule shaderModule ) { vkDestroyShaderModule( vkDevice, shaderModule, pAllocator ); }
    VkResult  CreatePipelineCache( const( VkPipelineCacheCreateInfo )* pCreateInfo, VkPipelineCache* pPipelineCache ) { return vkCreatePipelineCache( vkDevice, pCreateInfo, pAllocator, pPipelineCache ); }
    void      DestroyPipelineCache( VkPipelineCache pipelineCache ) { vkDestroyPipelineCache( vkDevice, pipelineCache, pAllocator ); }
    VkResult  GetPipelineCacheData( VkPipelineCache pipelineCache, size_t* pDataSize, void* pData ) { return vkGetPipelineCacheData( vkDevice, pipelineCache, pDataSize, pData ); }
    VkResult  MergePipelineCaches( VkPipelineCache dstCache, uint32_t srcCacheCount, const( VkPipelineCache )* pSrcCaches ) { return vkMergePipelineCaches( vkDevice, dstCache, srcCacheCount, pSrcCaches ); }
    VkResult  CreateGraphicsPipelines( VkPipelineCache pipelineCache, uint32_t createInfoCount, const( VkGraphicsPipelineCreateInfo )* pCreateInfos, VkPipeline* pPipelines ) { return vkCreateGraphicsPipelines( vkDevice, pipelineCache, createInfoCount, pCreateInfos, pAllocator, pPipelines ); }
    VkResult  CreateComputePipelines( VkPipelineCache pipelineCache, uint32_t createInfoCount, const( VkComputePipelineCreateInfo )* pCreateInfos, VkPipeline* pPipelines ) { return vkCreateComputePipelines( vkDevice, pipelineCache, createInfoCount, pCreateInfos, pAllocator, pPipelines ); }
    void      DestroyPipeline( VkPipeline pipeline ) { vkDestroyPipeline( vkDevice, pipeline, pAllocator ); }
    VkResult  CreatePipelineLayout( const( VkPipelineLayoutCreateInfo )* pCreateInfo, VkPipelineLayout* pPipelineLayout ) { return vkCreatePipelineLayout( vkDevice, pCreateInfo, pAllocator, pPipelineLayout ); }
    void      DestroyPipelineLayout( VkPipelineLayout pipelineLayout ) { vkDestroyPipelineLayout( vkDevice, pipelineLayout, pAllocator ); }
    VkResult  CreateSampler( const( VkSamplerCreateInfo )* pCreateInfo, VkSampler* pSampler ) { return vkCreateSampler( vkDevice, pCreateInfo, pAllocator, pSampler ); }
    void      DestroySampler( VkSampler sampler ) { vkDestroySampler( vkDevice, sampler, pAllocator ); }
    VkResult  CreateDescriptorSetLayout( const( VkDescriptorSetLayoutCreateInfo )* pCreateInfo, VkDescriptorSetLayout* pSetLayout ) { return vkCreateDescriptorSetLayout( vkDevice, pCreateInfo, pAllocator, pSetLayout ); }
    void      DestroyDescriptorSetLayout( VkDescriptorSetLayout descriptorSetLayout ) { vkDestroyDescriptorSetLayout( vkDevice, descriptorSetLayout, pAllocator ); }
    VkResult  CreateDescriptorPool( const( VkDescriptorPoolCreateInfo )* pCreateInfo, VkDescriptorPool* pDescriptorPool ) { return vkCreateDescriptorPool( vkDevice, pCreateInfo, pAllocator, pDescriptorPool ); }
    void      DestroyDescriptorPool( VkDescriptorPool descriptorPool ) { vkDestroyDescriptorPool( vkDevice, descriptorPool, pAllocator ); }
    VkResult  ResetDescriptorPool( VkDescriptorPool descriptorPool, VkDescriptorPoolResetFlags flags ) { return vkResetDescriptorPool( vkDevice, descriptorPool, flags ); }
    VkResult  AllocateDescriptorSets( const( VkDescriptorSetAllocateInfo )* pAllocateInfo, VkDescriptorSet* pDescriptorSets ) { return vkAllocateDescriptorSets( vkDevice, pAllocateInfo, pDescriptorSets ); }
    VkResult  FreeDescriptorSets( VkDescriptorPool descriptorPool, uint32_t descriptorSetCount, const( VkDescriptorSet )* pDescriptorSets ) { return vkFreeDescriptorSets( vkDevice, descriptorPool, descriptorSetCount, pDescriptorSets ); }
    void      UpdateDescriptorSets( uint32_t descriptorWriteCount, const( VkWriteDescriptorSet )* pDescriptorWrites, uint32_t descriptorCopyCount, const( VkCopyDescriptorSet )* pDescriptorCopies ) { vkUpdateDescriptorSets( vkDevice, descriptorWriteCount, pDescriptorWrites, descriptorCopyCount, pDescriptorCopies ); }
    VkResult  CreateFramebuffer( const( VkFramebufferCreateInfo )* pCreateInfo, VkFramebuffer* pFramebuffer ) { return vkCreateFramebuffer( vkDevice, pCreateInfo, pAllocator, pFramebuffer ); }
    void      DestroyFramebuffer( VkFramebuffer framebuffer ) { vkDestroyFramebuffer( vkDevice, framebuffer, pAllocator ); }
    VkResult  CreateRenderPass( const( VkRenderPassCreateInfo )* pCreateInfo, VkRenderPass* pRenderPass ) { return vkCreateRenderPass( vkDevice, pCreateInfo, pAllocator, pRenderPass ); }
    void      DestroyRenderPass( VkRenderPass renderPass ) { vkDestroyRenderPass( vkDevice, renderPass, pAllocator ); }
    void      GetRenderAreaGranularity( VkRenderPass renderPass, VkExtent2D* pGranularity ) { vkGetRenderAreaGranularity( vkDevice, renderPass, pGranularity ); }
    VkResult  CreateCommandPool( const( VkCommandPoolCreateInfo )* pCreateInfo, VkCommandPool* pCommandPool ) { return vkCreateCommandPool( vkDevice, pCreateInfo, pAllocator, pCommandPool ); }
    void      DestroyCommandPool( VkCommandPool commandPool ) { vkDestroyCommandPool( vkDevice, commandPool, pAllocator ); }
    VkResult  ResetCommandPool( VkCommandPool commandPool, VkCommandPoolResetFlags flags ) { return vkResetCommandPool( vkDevice, commandPool, flags ); }
    VkResult  AllocateCommandBuffers( const( VkCommandBufferAllocateInfo )* pAllocateInfo, VkCommandBuffer* pCommandBuffers ) { return vkAllocateCommandBuffers( vkDevice, pAllocateInfo, pCommandBuffers ); }
    void      FreeCommandBuffers( VkCommandPool commandPool, uint32_t commandBufferCount, const( VkCommandBuffer )* pCommandBuffers ) { vkFreeCommandBuffers( vkDevice, commandPool, commandBufferCount, pCommandBuffers ); }
    VkResult  BeginCommandBuffer( const( VkCommandBufferBeginInfo )* pBeginInfo ) { return vkBeginCommandBuffer( commandBuffer, pBeginInfo ); }
    VkResult  EndCommandBuffer() { return vkEndCommandBuffer( commandBuffer ); }
    VkResult  ResetCommandBuffer( VkCommandBufferResetFlags flags ) { return vkResetCommandBuffer( commandBuffer, flags ); }
    void      CmdBindPipeline( VkPipelineBindPoint pipelineBindPoint, VkPipeline pipeline ) { vkCmdBindPipeline( commandBuffer, pipelineBindPoint, pipeline ); }
    void      CmdSetViewport( uint32_t firstViewport, uint32_t viewportCount, const( VkViewport )* pViewports ) { vkCmdSetViewport( commandBuffer, firstViewport, viewportCount, pViewports ); }
    void      CmdSetScissor( uint32_t firstScissor, uint32_t scissorCount, const( VkRect2D )* pScissors ) { vkCmdSetScissor( commandBuffer, firstScissor, scissorCount, pScissors ); }
    void      CmdSetLineWidth( float lineWidth ) { vkCmdSetLineWidth( commandBuffer, lineWidth ); }
    void      CmdSetDepthBias( float depthBiasConstantFactor, float depthBiasClamp, float depthBiasSlopeFactor ) { vkCmdSetDepthBias( commandBuffer, depthBiasConstantFactor, depthBiasClamp, depthBiasSlopeFactor ); }
    void      CmdSetBlendConstants( const float[4] blendConstants ) { vkCmdSetBlendConstants( commandBuffer, blendConstants ); }
    void      CmdSetDepthBounds( float minDepthBounds, float maxDepthBounds ) { vkCmdSetDepthBounds( commandBuffer, minDepthBounds, maxDepthBounds ); }
    void      CmdSetStencilCompareMask( VkStencilFaceFlags faceMask, uint32_t compareMask ) { vkCmdSetStencilCompareMask( commandBuffer, faceMask, compareMask ); }
    void      CmdSetStencilWriteMask( VkStencilFaceFlags faceMask, uint32_t writeMask ) { vkCmdSetStencilWriteMask( commandBuffer, faceMask, writeMask ); }
    void      CmdSetStencilReference( VkStencilFaceFlags faceMask, uint32_t reference ) { vkCmdSetStencilReference( commandBuffer, faceMask, reference ); }
    void      CmdBindDescriptorSets( VkPipelineBindPoint pipelineBindPoint, VkPipelineLayout layout, uint32_t firstSet, uint32_t descriptorSetCount, const( VkDescriptorSet )* pDescriptorSets, uint32_t dynamicOffsetCount, const( uint32_t )* pDynamicOffsets ) { vkCmdBindDescriptorSets( commandBuffer, pipelineBindPoint, layout, firstSet, descriptorSetCount, pDescriptorSets, dynamicOffsetCount, pDynamicOffsets ); }
    void      CmdBindIndexBuffer( VkBuffer buffer, VkDeviceSize offset, VkIndexType indexType ) { vkCmdBindIndexBuffer( commandBuffer, buffer, offset, indexType ); }
    void      CmdBindVertexBuffers( uint32_t firstBinding, uint32_t bindingCount, const( VkBuffer )* pBuffers, const( VkDeviceSize )* pOffsets ) { vkCmdBindVertexBuffers( commandBuffer, firstBinding, bindingCount, pBuffers, pOffsets ); }
    void      CmdDraw( uint32_t vertexCount, uint32_t instanceCount, uint32_t firstVertex, uint32_t firstInstance ) { vkCmdDraw( commandBuffer, vertexCount, instanceCount, firstVertex, firstInstance ); }
    void      CmdDrawIndexed( uint32_t indexCount, uint32_t instanceCount, uint32_t firstIndex, int32_t vertexOffset, uint32_t firstInstance ) { vkCmdDrawIndexed( commandBuffer, indexCount, instanceCount, firstIndex, vertexOffset, firstInstance ); }
    void      CmdDrawIndirect( VkBuffer buffer, VkDeviceSize offset, uint32_t drawCount, uint32_t stride ) { vkCmdDrawIndirect( commandBuffer, buffer, offset, drawCount, stride ); }
    void      CmdDrawIndexedIndirect( VkBuffer buffer, VkDeviceSize offset, uint32_t drawCount, uint32_t stride ) { vkCmdDrawIndexedIndirect( commandBuffer, buffer, offset, drawCount, stride ); }
    void      CmdDispatch( uint32_t groupCountX, uint32_t groupCountY, uint32_t groupCountZ ) { vkCmdDispatch( commandBuffer, groupCountX, groupCountY, groupCountZ ); }
    void      CmdDispatchIndirect( VkBuffer buffer, VkDeviceSize offset ) { vkCmdDispatchIndirect( commandBuffer, buffer, offset ); }
    void      CmdCopyBuffer( VkBuffer srcBuffer, VkBuffer dstBuffer, uint32_t regionCount, const( VkBufferCopy )* pRegions ) { vkCmdCopyBuffer( commandBuffer, srcBuffer, dstBuffer, regionCount, pRegions ); }
    void      CmdCopyImage( VkImage srcImage, VkImageLayout srcImageLayout, VkImage dstImage, VkImageLayout dstImageLayout, uint32_t regionCount, const( VkImageCopy )* pRegions ) { vkCmdCopyImage( commandBuffer, srcImage, srcImageLayout, dstImage, dstImageLayout, regionCount, pRegions ); }
    void      CmdBlitImage( VkImage srcImage, VkImageLayout srcImageLayout, VkImage dstImage, VkImageLayout dstImageLayout, uint32_t regionCount, const( VkImageBlit )* pRegions, VkFilter filter ) { vkCmdBlitImage( commandBuffer, srcImage, srcImageLayout, dstImage, dstImageLayout, regionCount, pRegions, filter ); }
    void      CmdCopyBufferToImage( VkBuffer srcBuffer, VkImage dstImage, VkImageLayout dstImageLayout, uint32_t regionCount, const( VkBufferImageCopy )* pRegions ) { vkCmdCopyBufferToImage( commandBuffer, srcBuffer, dstImage, dstImageLayout, regionCount, pRegions ); }
    void      CmdCopyImageToBuffer( VkImage srcImage, VkImageLayout srcImageLayout, VkBuffer dstBuffer, uint32_t regionCount, const( VkBufferImageCopy )* pRegions ) { vkCmdCopyImageToBuffer( commandBuffer, srcImage, srcImageLayout, dstBuffer, regionCount, pRegions ); }
    void      CmdUpdateBuffer( VkBuffer dstBuffer, VkDeviceSize dstOffset, VkDeviceSize dataSize, const( void )* pData ) { vkCmdUpdateBuffer( commandBuffer, dstBuffer, dstOffset, dataSize, pData ); }
    void      CmdFillBuffer( VkBuffer dstBuffer, VkDeviceSize dstOffset, VkDeviceSize size, uint32_t data ) { vkCmdFillBuffer( commandBuffer, dstBuffer, dstOffset, size, data ); }
    void      CmdClearColorImage( VkImage image, VkImageLayout imageLayout, const( VkClearColorValue )* pColor, uint32_t rangeCount, const( VkImageSubresourceRange )* pRanges ) { vkCmdClearColorImage( commandBuffer, image, imageLayout, pColor, rangeCount, pRanges ); }
    void      CmdClearDepthStencilImage( VkImage image, VkImageLayout imageLayout, const( VkClearDepthStencilValue )* pDepthStencil, uint32_t rangeCount, const( VkImageSubresourceRange )* pRanges ) { vkCmdClearDepthStencilImage( commandBuffer, image, imageLayout, pDepthStencil, rangeCount, pRanges ); }
    void      CmdClearAttachments( uint32_t attachmentCount, const( VkClearAttachment )* pAttachments, uint32_t rectCount, const( VkClearRect )* pRects ) { vkCmdClearAttachments( commandBuffer, attachmentCount, pAttachments, rectCount, pRects ); }
    void      CmdResolveImage( VkImage srcImage, VkImageLayout srcImageLayout, VkImage dstImage, VkImageLayout dstImageLayout, uint32_t regionCount, const( VkImageResolve )* pRegions ) { vkCmdResolveImage( commandBuffer, srcImage, srcImageLayout, dstImage, dstImageLayout, regionCount, pRegions ); }
    void      CmdSetEvent( VkEvent event, VkPipelineStageFlags stageMask ) { vkCmdSetEvent( commandBuffer, event, stageMask ); }
    void      CmdResetEvent( VkEvent event, VkPipelineStageFlags stageMask ) { vkCmdResetEvent( commandBuffer, event, stageMask ); }
    void      CmdWaitEvents( uint32_t eventCount, const( VkEvent )* pEvents, VkPipelineStageFlags srcStageMask, VkPipelineStageFlags dstStageMask, uint32_t memoryBarrierCount, const( VkMemoryBarrier )* pMemoryBarriers, uint32_t bufferMemoryBarrierCount, const( VkBufferMemoryBarrier )* pBufferMemoryBarriers, uint32_t imageMemoryBarrierCount, const( VkImageMemoryBarrier )* pImageMemoryBarriers ) { vkCmdWaitEvents( commandBuffer, eventCount, pEvents, srcStageMask, dstStageMask, memoryBarrierCount, pMemoryBarriers, bufferMemoryBarrierCount, pBufferMemoryBarriers, imageMemoryBarrierCount, pImageMemoryBarriers ); }
    void      CmdPipelineBarrier( VkPipelineStageFlags srcStageMask, VkPipelineStageFlags dstStageMask, VkDependencyFlags dependencyFlags, uint32_t memoryBarrierCount, const( VkMemoryBarrier )* pMemoryBarriers, uint32_t bufferMemoryBarrierCount, const( VkBufferMemoryBarrier )* pBufferMemoryBarriers, uint32_t imageMemoryBarrierCount, const( VkImageMemoryBarrier )* pImageMemoryBarriers ) { vkCmdPipelineBarrier( commandBuffer, srcStageMask, dstStageMask, dependencyFlags, memoryBarrierCount, pMemoryBarriers, bufferMemoryBarrierCount, pBufferMemoryBarriers, imageMemoryBarrierCount, pImageMemoryBarriers ); }
    void      CmdBeginQuery( VkQueryPool queryPool, uint32_t query, VkQueryControlFlags flags ) { vkCmdBeginQuery( commandBuffer, queryPool, query, flags ); }
    void      CmdEndQuery( VkQueryPool queryPool, uint32_t query ) { vkCmdEndQuery( commandBuffer, queryPool, query ); }
    void      CmdResetQueryPool( VkQueryPool queryPool, uint32_t firstQuery, uint32_t queryCount ) { vkCmdResetQueryPool( commandBuffer, queryPool, firstQuery, queryCount ); }
    void      CmdWriteTimestamp( VkPipelineStageFlagBits pipelineStage, VkQueryPool queryPool, uint32_t query ) { vkCmdWriteTimestamp( commandBuffer, pipelineStage, queryPool, query ); }
    void      CmdCopyQueryPoolResults( VkQueryPool queryPool, uint32_t firstQuery, uint32_t queryCount, VkBuffer dstBuffer, VkDeviceSize dstOffset, VkDeviceSize stride, VkQueryResultFlags flags ) { vkCmdCopyQueryPoolResults( commandBuffer, queryPool, firstQuery, queryCount, dstBuffer, dstOffset, stride, flags ); }
    void      CmdPushConstants( VkPipelineLayout layout, VkShaderStageFlags stageFlags, uint32_t offset, uint32_t size, const( void )* pValues ) { vkCmdPushConstants( commandBuffer, layout, stageFlags, offset, size, pValues ); }
    void      CmdBeginRenderPass( const( VkRenderPassBeginInfo )* pRenderPassBegin, VkSubpassContents contents ) { vkCmdBeginRenderPass( commandBuffer, pRenderPassBegin, contents ); }
    void      CmdNextSubpass( VkSubpassContents contents ) { vkCmdNextSubpass( commandBuffer, contents ); }
    void      CmdEndRenderPass() { vkCmdEndRenderPass( commandBuffer ); }
    void      CmdExecuteCommands( uint32_t commandBufferCount, const( VkCommandBuffer )* pCommandBuffers ) { vkCmdExecuteCommands( commandBuffer, commandBufferCount, pCommandBuffers ); }

    // VK_VERSION_1_1
    VkResult  BindBufferMemory2( uint32_t bindInfoCount, const( VkBindBufferMemoryInfo )* pBindInfos ) { return vkBindBufferMemory2( vkDevice, bindInfoCount, pBindInfos ); }
    VkResult  BindImageMemory2( uint32_t bindInfoCount, const( VkBindImageMemoryInfo )* pBindInfos ) { return vkBindImageMemory2( vkDevice, bindInfoCount, pBindInfos ); }
    void      GetDeviceGroupPeerMemoryFeatures( uint32_t heapIndex, uint32_t localDeviceIndex, uint32_t remoteDeviceIndex, VkPeerMemoryFeatureFlags* pPeerMemoryFeatures ) { vkGetDeviceGroupPeerMemoryFeatures( vkDevice, heapIndex, localDeviceIndex, remoteDeviceIndex, pPeerMemoryFeatures ); }
    void      CmdSetDeviceMask( uint32_t deviceMask ) { vkCmdSetDeviceMask( commandBuffer, deviceMask ); }
    void      CmdDispatchBase( uint32_t baseGroupX, uint32_t baseGroupY, uint32_t baseGroupZ, uint32_t groupCountX, uint32_t groupCountY, uint32_t groupCountZ ) { vkCmdDispatchBase( commandBuffer, baseGroupX, baseGroupY, baseGroupZ, groupCountX, groupCountY, groupCountZ ); }
    void      GetImageMemoryRequirements2( const( VkImageMemoryRequirementsInfo2 )* pInfo, VkMemoryRequirements2* pMemoryRequirements ) { vkGetImageMemoryRequirements2( vkDevice, pInfo, pMemoryRequirements ); }
    void      GetBufferMemoryRequirements2( const( VkBufferMemoryRequirementsInfo2 )* pInfo, VkMemoryRequirements2* pMemoryRequirements ) { vkGetBufferMemoryRequirements2( vkDevice, pInfo, pMemoryRequirements ); }
    void      GetImageSparseMemoryRequirements2( const( VkImageSparseMemoryRequirementsInfo2 )* pInfo, uint32_t* pSparseMemoryRequirementCount, VkSparseImageMemoryRequirements2* pSparseMemoryRequirements ) { vkGetImageSparseMemoryRequirements2( vkDevice, pInfo, pSparseMemoryRequirementCount, pSparseMemoryRequirements ); }
    void      TrimCommandPool( VkCommandPool commandPool, VkCommandPoolTrimFlags flags ) { vkTrimCommandPool( vkDevice, commandPool, flags ); }
    void      GetDeviceQueue2( const( VkDeviceQueueInfo2 )* pQueueInfo, VkQueue* pQueue ) { vkGetDeviceQueue2( vkDevice, pQueueInfo, pQueue ); }
    VkResult  CreateSamplerYcbcrConversion( const( VkSamplerYcbcrConversionCreateInfo )* pCreateInfo, VkSamplerYcbcrConversion* pYcbcrConversion ) { return vkCreateSamplerYcbcrConversion( vkDevice, pCreateInfo, pAllocator, pYcbcrConversion ); }
    void      DestroySamplerYcbcrConversion( VkSamplerYcbcrConversion ycbcrConversion ) { vkDestroySamplerYcbcrConversion( vkDevice, ycbcrConversion, pAllocator ); }
    VkResult  CreateDescriptorUpdateTemplate( const( VkDescriptorUpdateTemplateCreateInfo )* pCreateInfo, VkDescriptorUpdateTemplate* pDescriptorUpdateTemplate ) { return vkCreateDescriptorUpdateTemplate( vkDevice, pCreateInfo, pAllocator, pDescriptorUpdateTemplate ); }
    void      DestroyDescriptorUpdateTemplate( VkDescriptorUpdateTemplate descriptorUpdateTemplate ) { vkDestroyDescriptorUpdateTemplate( vkDevice, descriptorUpdateTemplate, pAllocator ); }
    void      UpdateDescriptorSetWithTemplate( VkDescriptorSet descriptorSet, VkDescriptorUpdateTemplate descriptorUpdateTemplate, const( void )* pData ) { vkUpdateDescriptorSetWithTemplate( vkDevice, descriptorSet, descriptorUpdateTemplate, pData ); }
    void      GetDescriptorSetLayoutSupport( const( VkDescriptorSetLayoutCreateInfo )* pCreateInfo, VkDescriptorSetLayoutSupport* pSupport ) { vkGetDescriptorSetLayoutSupport( vkDevice, pCreateInfo, pSupport ); }

    // VK_KHR_swapchain
    VkResult  CreateSwapchainKHR( const( VkSwapchainCreateInfoKHR )* pCreateInfo, VkSwapchainKHR* pSwapchain ) { return vkCreateSwapchainKHR( vkDevice, pCreateInfo, pAllocator, pSwapchain ); }
    void      DestroySwapchainKHR( VkSwapchainKHR swapchain ) { vkDestroySwapchainKHR( vkDevice, swapchain, pAllocator ); }
    VkResult  GetSwapchainImagesKHR( VkSwapchainKHR swapchain, uint32_t* pSwapchainImageCount, VkImage* pSwapchainImages ) { return vkGetSwapchainImagesKHR( vkDevice, swapchain, pSwapchainImageCount, pSwapchainImages ); }
    VkResult  AcquireNextImageKHR( VkSwapchainKHR swapchain, uint64_t timeout, VkSemaphore semaphore, VkFence fence, uint32_t* pImageIndex ) { return vkAcquireNextImageKHR( vkDevice, swapchain, timeout, semaphore, fence, pImageIndex ); }
    VkResult  GetDeviceGroupPresentCapabilitiesKHR( VkDeviceGroupPresentCapabilitiesKHR* pDeviceGroupPresentCapabilities ) { return vkGetDeviceGroupPresentCapabilitiesKHR( vkDevice, pDeviceGroupPresentCapabilities ); }
    VkResult  GetDeviceGroupSurfacePresentModesKHR( VkSurfaceKHR surface, VkDeviceGroupPresentModeFlagsKHR* pModes ) { return vkGetDeviceGroupSurfacePresentModesKHR( vkDevice, surface, pModes ); }
    VkResult  AcquireNextImage2KHR( const( VkAcquireNextImageInfoKHR )* pAcquireInfo, uint32_t* pImageIndex ) { return vkAcquireNextImage2KHR( vkDevice, pAcquireInfo, pImageIndex ); }

    // VK_KHR_display_swapchain
    VkResult  CreateSharedSwapchainsKHR( uint32_t swapchainCount, const( VkSwapchainCreateInfoKHR )* pCreateInfos, VkSwapchainKHR* pSwapchains ) { return vkCreateSharedSwapchainsKHR( vkDevice, swapchainCount, pCreateInfos, pAllocator, pSwapchains ); }

    // VK_KHR_external_memory_fd
    VkResult  GetMemoryFdKHR( const( VkMemoryGetFdInfoKHR )* pGetFdInfo, int* pFd ) { return vkGetMemoryFdKHR( vkDevice, pGetFdInfo, pFd ); }
    VkResult  GetMemoryFdPropertiesKHR( VkExternalMemoryHandleTypeFlagBits handleType, int fd, VkMemoryFdPropertiesKHR* pMemoryFdProperties ) { return vkGetMemoryFdPropertiesKHR( vkDevice, handleType, fd, pMemoryFdProperties ); }

    // VK_KHR_external_semaphore_fd
    VkResult  ImportSemaphoreFdKHR( const( VkImportSemaphoreFdInfoKHR )* pImportSemaphoreFdInfo ) { return vkImportSemaphoreFdKHR( vkDevice, pImportSemaphoreFdInfo ); }
    VkResult  GetSemaphoreFdKHR( const( VkSemaphoreGetFdInfoKHR )* pGetFdInfo, int* pFd ) { return vkGetSemaphoreFdKHR( vkDevice, pGetFdInfo, pFd ); }

    // VK_KHR_push_descriptor
    void      CmdPushDescriptorSetKHR( VkPipelineBindPoint pipelineBindPoint, VkPipelineLayout layout, uint32_t set, uint32_t descriptorWriteCount, const( VkWriteDescriptorSet )* pDescriptorWrites ) { vkCmdPushDescriptorSetKHR( commandBuffer, pipelineBindPoint, layout, set, descriptorWriteCount, pDescriptorWrites ); }
    void      CmdPushDescriptorSetWithTemplateKHR( VkDescriptorUpdateTemplate descriptorUpdateTemplate, VkPipelineLayout layout, uint32_t set, const( void )* pData ) { vkCmdPushDescriptorSetWithTemplateKHR( commandBuffer, descriptorUpdateTemplate, layout, set, pData ); }

    // VK_KHR_create_renderpass2
    VkResult  CreateRenderPass2KHR( const( VkRenderPassCreateInfo2KHR )* pCreateInfo, VkRenderPass* pRenderPass ) { return vkCreateRenderPass2KHR( vkDevice, pCreateInfo, pAllocator, pRenderPass ); }
    void      CmdBeginRenderPass2KHR( const( VkRenderPassBeginInfo )* pRenderPassBegin, const( VkSubpassBeginInfoKHR )* pSubpassBeginInfo ) { vkCmdBeginRenderPass2KHR( commandBuffer, pRenderPassBegin, pSubpassBeginInfo ); }
    void      CmdNextSubpass2KHR( const( VkSubpassBeginInfoKHR )* pSubpassBeginInfo, const( VkSubpassEndInfoKHR )* pSubpassEndInfo ) { vkCmdNextSubpass2KHR( commandBuffer, pSubpassBeginInfo, pSubpassEndInfo ); }
    void      CmdEndRenderPass2KHR( const( VkSubpassEndInfoKHR )* pSubpassEndInfo ) { vkCmdEndRenderPass2KHR( commandBuffer, pSubpassEndInfo ); }

    // VK_KHR_shared_presentable_image
    VkResult  GetSwapchainStatusKHR( VkSwapchainKHR swapchain ) { return vkGetSwapchainStatusKHR( vkDevice, swapchain ); }

    // VK_KHR_external_fence_fd
    VkResult  ImportFenceFdKHR( const( VkImportFenceFdInfoKHR )* pImportFenceFdInfo ) { return vkImportFenceFdKHR( vkDevice, pImportFenceFdInfo ); }
    VkResult  GetFenceFdKHR( const( VkFenceGetFdInfoKHR )* pGetFdInfo, int* pFd ) { return vkGetFenceFdKHR( vkDevice, pGetFdInfo, pFd ); }

    // VK_KHR_draw_indirect_count
    void      CmdDrawIndirectCountKHR( VkBuffer buffer, VkDeviceSize offset, VkBuffer countBuffer, VkDeviceSize countBufferOffset, uint32_t maxDrawCount, uint32_t stride ) { vkCmdDrawIndirectCountKHR( commandBuffer, buffer, offset, countBuffer, countBufferOffset, maxDrawCount, stride ); }
    void      CmdDrawIndexedIndirectCountKHR( VkBuffer buffer, VkDeviceSize offset, VkBuffer countBuffer, VkDeviceSize countBufferOffset, uint32_t maxDrawCount, uint32_t stride ) { vkCmdDrawIndexedIndirectCountKHR( commandBuffer, buffer, offset, countBuffer, countBufferOffset, maxDrawCount, stride ); }

    // VK_EXT_debug_marker
    VkResult  DebugMarkerSetObjectTagEXT( const( VkDebugMarkerObjectTagInfoEXT )* pTagInfo ) { return vkDebugMarkerSetObjectTagEXT( vkDevice, pTagInfo ); }
    VkResult  DebugMarkerSetObjectNameEXT( const( VkDebugMarkerObjectNameInfoEXT )* pNameInfo ) { return vkDebugMarkerSetObjectNameEXT( vkDevice, pNameInfo ); }
    void      CmdDebugMarkerBeginEXT( const( VkDebugMarkerMarkerInfoEXT )* pMarkerInfo ) { vkCmdDebugMarkerBeginEXT( commandBuffer, pMarkerInfo ); }
    void      CmdDebugMarkerEndEXT() { vkCmdDebugMarkerEndEXT( commandBuffer ); }
    void      CmdDebugMarkerInsertEXT( const( VkDebugMarkerMarkerInfoEXT )* pMarkerInfo ) { vkCmdDebugMarkerInsertEXT( commandBuffer, pMarkerInfo ); }

    // VK_EXT_transform_feedback
    void      CmdBindTransformFeedbackBuffersEXT( uint32_t firstBinding, uint32_t bindingCount, const( VkBuffer )* pBuffers, const( VkDeviceSize )* pOffsets, const( VkDeviceSize )* pSizes ) { vkCmdBindTransformFeedbackBuffersEXT( commandBuffer, firstBinding, bindingCount, pBuffers, pOffsets, pSizes ); }
    void      CmdBeginTransformFeedbackEXT( uint32_t firstCounterBuffer, uint32_t counterBufferCount, const( VkBuffer )* pCounterBuffers, const( VkDeviceSize )* pCounterBufferOffsets ) { vkCmdBeginTransformFeedbackEXT( commandBuffer, firstCounterBuffer, counterBufferCount, pCounterBuffers, pCounterBufferOffsets ); }
    void      CmdEndTransformFeedbackEXT( uint32_t firstCounterBuffer, uint32_t counterBufferCount, const( VkBuffer )* pCounterBuffers, const( VkDeviceSize )* pCounterBufferOffsets ) { vkCmdEndTransformFeedbackEXT( commandBuffer, firstCounterBuffer, counterBufferCount, pCounterBuffers, pCounterBufferOffsets ); }
    void      CmdBeginQueryIndexedEXT( VkQueryPool queryPool, uint32_t query, VkQueryControlFlags flags, uint32_t index ) { vkCmdBeginQueryIndexedEXT( commandBuffer, queryPool, query, flags, index ); }
    void      CmdEndQueryIndexedEXT( VkQueryPool queryPool, uint32_t query, uint32_t index ) { vkCmdEndQueryIndexedEXT( commandBuffer, queryPool, query, index ); }
    void      CmdDrawIndirectByteCountEXT( uint32_t instanceCount, uint32_t firstInstance, VkBuffer counterBuffer, VkDeviceSize counterBufferOffset, uint32_t counterOffset, uint32_t vertexStride ) { vkCmdDrawIndirectByteCountEXT( commandBuffer, instanceCount, firstInstance, counterBuffer, counterBufferOffset, counterOffset, vertexStride ); }

    // VK_NVX_image_view_handle
    uint32_t  GetImageViewHandleNVX( const( VkImageViewHandleInfoNVX )* pInfo ) { return vkGetImageViewHandleNVX( vkDevice, pInfo ); }

    // VK_AMD_shader_info
    VkResult  GetShaderInfoAMD( VkPipeline pipeline, VkShaderStageFlagBits shaderStage, VkShaderInfoTypeAMD infoType, size_t* pInfoSize, void* pInfo ) { return vkGetShaderInfoAMD( vkDevice, pipeline, shaderStage, infoType, pInfoSize, pInfo ); }

    // VK_EXT_conditional_rendering
    void      CmdBeginConditionalRenderingEXT( const( VkConditionalRenderingBeginInfoEXT )* pConditionalRenderingBegin ) { vkCmdBeginConditionalRenderingEXT( commandBuffer, pConditionalRenderingBegin ); }
    void      CmdEndConditionalRenderingEXT() { vkCmdEndConditionalRenderingEXT( commandBuffer ); }

    // VK_NVX_device_generated_commands
    void      CmdProcessCommandsNVX( const( VkCmdProcessCommandsInfoNVX )* pProcessCommandsInfo ) { vkCmdProcessCommandsNVX( commandBuffer, pProcessCommandsInfo ); }
    void      CmdReserveSpaceForCommandsNVX( const( VkCmdReserveSpaceForCommandsInfoNVX )* pReserveSpaceInfo ) { vkCmdReserveSpaceForCommandsNVX( commandBuffer, pReserveSpaceInfo ); }
    VkResult  CreateIndirectCommandsLayoutNVX( const( VkIndirectCommandsLayoutCreateInfoNVX )* pCreateInfo, VkIndirectCommandsLayoutNVX* pIndirectCommandsLayout ) { return vkCreateIndirectCommandsLayoutNVX( vkDevice, pCreateInfo, pAllocator, pIndirectCommandsLayout ); }
    void      DestroyIndirectCommandsLayoutNVX( VkIndirectCommandsLayoutNVX indirectCommandsLayout ) { vkDestroyIndirectCommandsLayoutNVX( vkDevice, indirectCommandsLayout, pAllocator ); }
    VkResult  CreateObjectTableNVX( const( VkObjectTableCreateInfoNVX )* pCreateInfo, VkObjectTableNVX* pObjectTable ) { return vkCreateObjectTableNVX( vkDevice, pCreateInfo, pAllocator, pObjectTable ); }
    void      DestroyObjectTableNVX( VkObjectTableNVX objectTable ) { vkDestroyObjectTableNVX( vkDevice, objectTable, pAllocator ); }
    VkResult  RegisterObjectsNVX( VkObjectTableNVX objectTable, uint32_t objectCount, const( VkObjectTableEntryNVX* )* ppObjectTableEntries, const( uint32_t )* pObjectIndices ) { return vkRegisterObjectsNVX( vkDevice, objectTable, objectCount, ppObjectTableEntries, pObjectIndices ); }
    VkResult  UnregisterObjectsNVX( VkObjectTableNVX objectTable, uint32_t objectCount, const( VkObjectEntryTypeNVX )* pObjectEntryTypes, const( uint32_t )* pObjectIndices ) { return vkUnregisterObjectsNVX( vkDevice, objectTable, objectCount, pObjectEntryTypes, pObjectIndices ); }

    // VK_NV_clip_space_w_scaling
    void      CmdSetViewportWScalingNV( uint32_t firstViewport, uint32_t viewportCount, const( VkViewportWScalingNV )* pViewportWScalings ) { vkCmdSetViewportWScalingNV( commandBuffer, firstViewport, viewportCount, pViewportWScalings ); }

    // VK_EXT_display_control
    VkResult  DisplayPowerControlEXT( VkDisplayKHR display, const( VkDisplayPowerInfoEXT )* pDisplayPowerInfo ) { return vkDisplayPowerControlEXT( vkDevice, display, pDisplayPowerInfo ); }
    VkResult  RegisterDeviceEventEXT( const( VkDeviceEventInfoEXT )* pDeviceEventInfo, VkFence* pFence ) { return vkRegisterDeviceEventEXT( vkDevice, pDeviceEventInfo, pAllocator, pFence ); }
    VkResult  RegisterDisplayEventEXT( VkDisplayKHR display, const( VkDisplayEventInfoEXT )* pDisplayEventInfo, VkFence* pFence ) { return vkRegisterDisplayEventEXT( vkDevice, display, pDisplayEventInfo, pAllocator, pFence ); }
    VkResult  GetSwapchainCounterEXT( VkSwapchainKHR swapchain, VkSurfaceCounterFlagBitsEXT counter, uint64_t* pCounterValue ) { return vkGetSwapchainCounterEXT( vkDevice, swapchain, counter, pCounterValue ); }

    // VK_GOOGLE_display_timing
    VkResult  GetRefreshCycleDurationGOOGLE( VkSwapchainKHR swapchain, VkRefreshCycleDurationGOOGLE* pDisplayTimingProperties ) { return vkGetRefreshCycleDurationGOOGLE( vkDevice, swapchain, pDisplayTimingProperties ); }
    VkResult  GetPastPresentationTimingGOOGLE( VkSwapchainKHR swapchain, uint32_t* pPresentationTimingCount, VkPastPresentationTimingGOOGLE* pPresentationTimings ) { return vkGetPastPresentationTimingGOOGLE( vkDevice, swapchain, pPresentationTimingCount, pPresentationTimings ); }

    // VK_EXT_discard_rectangles
    void      CmdSetDiscardRectangleEXT( uint32_t firstDiscardRectangle, uint32_t discardRectangleCount, const( VkRect2D )* pDiscardRectangles ) { vkCmdSetDiscardRectangleEXT( commandBuffer, firstDiscardRectangle, discardRectangleCount, pDiscardRectangles ); }

    // VK_EXT_hdr_metadata
    void      SetHdrMetadataEXT( uint32_t swapchainCount, const( VkSwapchainKHR )* pSwapchains, const( VkHdrMetadataEXT )* pMetadata ) { vkSetHdrMetadataEXT( vkDevice, swapchainCount, pSwapchains, pMetadata ); }

    // VK_EXT_debug_utils
    VkResult  SetDebugUtilsObjectNameEXT( const( VkDebugUtilsObjectNameInfoEXT )* pNameInfo ) { return vkSetDebugUtilsObjectNameEXT( vkDevice, pNameInfo ); }
    VkResult  SetDebugUtilsObjectTagEXT( const( VkDebugUtilsObjectTagInfoEXT )* pTagInfo ) { return vkSetDebugUtilsObjectTagEXT( vkDevice, pTagInfo ); }
    void      CmdBeginDebugUtilsLabelEXT( const( VkDebugUtilsLabelEXT )* pLabelInfo ) { vkCmdBeginDebugUtilsLabelEXT( commandBuffer, pLabelInfo ); }
    void      CmdEndDebugUtilsLabelEXT() { vkCmdEndDebugUtilsLabelEXT( commandBuffer ); }
    void      CmdInsertDebugUtilsLabelEXT( const( VkDebugUtilsLabelEXT )* pLabelInfo ) { vkCmdInsertDebugUtilsLabelEXT( commandBuffer, pLabelInfo ); }

    // VK_EXT_sample_locations
    void      CmdSetSampleLocationsEXT( const( VkSampleLocationsInfoEXT )* pSampleLocationsInfo ) { vkCmdSetSampleLocationsEXT( commandBuffer, pSampleLocationsInfo ); }

    // VK_EXT_image_drm_format_modifier
    VkResult  GetImageDrmFormatModifierPropertiesEXT( VkImage image, VkImageDrmFormatModifierPropertiesEXT* pProperties ) { return vkGetImageDrmFormatModifierPropertiesEXT( vkDevice, image, pProperties ); }

    // VK_EXT_validation_cache
    VkResult  CreateValidationCacheEXT( const( VkValidationCacheCreateInfoEXT )* pCreateInfo, VkValidationCacheEXT* pValidationCache ) { return vkCreateValidationCacheEXT( vkDevice, pCreateInfo, pAllocator, pValidationCache ); }
    void      DestroyValidationCacheEXT( VkValidationCacheEXT validationCache ) { vkDestroyValidationCacheEXT( vkDevice, validationCache, pAllocator ); }
    VkResult  MergeValidationCachesEXT( VkValidationCacheEXT dstCache, uint32_t srcCacheCount, const( VkValidationCacheEXT )* pSrcCaches ) { return vkMergeValidationCachesEXT( vkDevice, dstCache, srcCacheCount, pSrcCaches ); }
    VkResult  GetValidationCacheDataEXT( VkValidationCacheEXT validationCache, size_t* pDataSize, void* pData ) { return vkGetValidationCacheDataEXT( vkDevice, validationCache, pDataSize, pData ); }

    // VK_NV_shading_rate_image
    void      CmdBindShadingRateImageNV( VkImageView imageView, VkImageLayout imageLayout ) { vkCmdBindShadingRateImageNV( commandBuffer, imageView, imageLayout ); }
    void      CmdSetViewportShadingRatePaletteNV( uint32_t firstViewport, uint32_t viewportCount, const( VkShadingRatePaletteNV )* pShadingRatePalettes ) { vkCmdSetViewportShadingRatePaletteNV( commandBuffer, firstViewport, viewportCount, pShadingRatePalettes ); }
    void      CmdSetCoarseSampleOrderNV( VkCoarseSampleOrderTypeNV sampleOrderType, uint32_t customSampleOrderCount, const( VkCoarseSampleOrderCustomNV )* pCustomSampleOrders ) { vkCmdSetCoarseSampleOrderNV( commandBuffer, sampleOrderType, customSampleOrderCount, pCustomSampleOrders ); }

    // VK_NV_ray_tracing
    VkResult  CreateAccelerationStructureNV( const( VkAccelerationStructureCreateInfoNV )* pCreateInfo, VkAccelerationStructureNV* pAccelerationStructure ) { return vkCreateAccelerationStructureNV( vkDevice, pCreateInfo, pAllocator, pAccelerationStructure ); }
    void      DestroyAccelerationStructureNV( VkAccelerationStructureNV accelerationStructure ) { vkDestroyAccelerationStructureNV( vkDevice, accelerationStructure, pAllocator ); }
    void      GetAccelerationStructureMemoryRequirementsNV( const( VkAccelerationStructureMemoryRequirementsInfoNV )* pInfo, VkMemoryRequirements2KHR* pMemoryRequirements ) { vkGetAccelerationStructureMemoryRequirementsNV( vkDevice, pInfo, pMemoryRequirements ); }
    VkResult  BindAccelerationStructureMemoryNV( uint32_t bindInfoCount, const( VkBindAccelerationStructureMemoryInfoNV )* pBindInfos ) { return vkBindAccelerationStructureMemoryNV( vkDevice, bindInfoCount, pBindInfos ); }
    void      CmdBuildAccelerationStructureNV( const( VkAccelerationStructureInfoNV )* pInfo, VkBuffer instanceData, VkDeviceSize instanceOffset, VkBool32 update, VkAccelerationStructureNV dst, VkAccelerationStructureNV src, VkBuffer scratch, VkDeviceSize scratchOffset ) { vkCmdBuildAccelerationStructureNV( commandBuffer, pInfo, instanceData, instanceOffset, update, dst, src, scratch, scratchOffset ); }
    void      CmdCopyAccelerationStructureNV( VkAccelerationStructureNV dst, VkAccelerationStructureNV src, VkCopyAccelerationStructureModeNV mode ) { vkCmdCopyAccelerationStructureNV( commandBuffer, dst, src, mode ); }
    void      CmdTraceRaysNV( VkBuffer raygenShaderBindingTableBuffer, VkDeviceSize raygenShaderBindingOffset, VkBuffer missShaderBindingTableBuffer, VkDeviceSize missShaderBindingOffset, VkDeviceSize missShaderBindingStride, VkBuffer hitShaderBindingTableBuffer, VkDeviceSize hitShaderBindingOffset, VkDeviceSize hitShaderBindingStride, VkBuffer callableShaderBindingTableBuffer, VkDeviceSize callableShaderBindingOffset, VkDeviceSize callableShaderBindingStride, uint32_t width, uint32_t height, uint32_t depth ) { vkCmdTraceRaysNV( commandBuffer, raygenShaderBindingTableBuffer, raygenShaderBindingOffset, missShaderBindingTableBuffer, missShaderBindingOffset, missShaderBindingStride, hitShaderBindingTableBuffer, hitShaderBindingOffset, hitShaderBindingStride, callableShaderBindingTableBuffer, callableShaderBindingOffset, callableShaderBindingStride, width, height, depth ); }
    VkResult  CreateRayTracingPipelinesNV( VkPipelineCache pipelineCache, uint32_t createInfoCount, const( VkRayTracingPipelineCreateInfoNV )* pCreateInfos, VkPipeline* pPipelines ) { return vkCreateRayTracingPipelinesNV( vkDevice, pipelineCache, createInfoCount, pCreateInfos, pAllocator, pPipelines ); }
    VkResult  GetRayTracingShaderGroupHandlesNV( VkPipeline pipeline, uint32_t firstGroup, uint32_t groupCount, size_t dataSize, void* pData ) { return vkGetRayTracingShaderGroupHandlesNV( vkDevice, pipeline, firstGroup, groupCount, dataSize, pData ); }
    VkResult  GetAccelerationStructureHandleNV( VkAccelerationStructureNV accelerationStructure, size_t dataSize, void* pData ) { return vkGetAccelerationStructureHandleNV( vkDevice, accelerationStructure, dataSize, pData ); }
    void      CmdWriteAccelerationStructuresPropertiesNV( uint32_t accelerationStructureCount, const( VkAccelerationStructureNV )* pAccelerationStructures, VkQueryType queryType, VkQueryPool queryPool, uint32_t firstQuery ) { vkCmdWriteAccelerationStructuresPropertiesNV( commandBuffer, accelerationStructureCount, pAccelerationStructures, queryType, queryPool, firstQuery ); }
    VkResult  CompileDeferredNV( VkPipeline pipeline, uint32_t shader ) { return vkCompileDeferredNV( vkDevice, pipeline, shader ); }

    // VK_EXT_external_memory_host
    VkResult  GetMemoryHostPointerPropertiesEXT( VkExternalMemoryHandleTypeFlagBits handleType, const( void )* pHostPointer, VkMemoryHostPointerPropertiesEXT* pMemoryHostPointerProperties ) { return vkGetMemoryHostPointerPropertiesEXT( vkDevice, handleType, pHostPointer, pMemoryHostPointerProperties ); }

    // VK_AMD_buffer_marker
    void      CmdWriteBufferMarkerAMD( VkPipelineStageFlagBits pipelineStage, VkBuffer dstBuffer, VkDeviceSize dstOffset, uint32_t marker ) { vkCmdWriteBufferMarkerAMD( commandBuffer, pipelineStage, dstBuffer, dstOffset, marker ); }

    // VK_EXT_calibrated_timestamps
    VkResult  GetCalibratedTimestampsEXT( uint32_t timestampCount, const( VkCalibratedTimestampInfoEXT )* pTimestampInfos, uint64_t* pTimestamps, uint64_t* pMaxDeviation ) { return vkGetCalibratedTimestampsEXT( vkDevice, timestampCount, pTimestampInfos, pTimestamps, pMaxDeviation ); }

    // VK_NV_mesh_shader
    void      CmdDrawMeshTasksNV( uint32_t taskCount, uint32_t firstTask ) { vkCmdDrawMeshTasksNV( commandBuffer, taskCount, firstTask ); }
    void      CmdDrawMeshTasksIndirectNV( VkBuffer buffer, VkDeviceSize offset, uint32_t drawCount, uint32_t stride ) { vkCmdDrawMeshTasksIndirectNV( commandBuffer, buffer, offset, drawCount, stride ); }
    void      CmdDrawMeshTasksIndirectCountNV( VkBuffer buffer, VkDeviceSize offset, VkBuffer countBuffer, VkDeviceSize countBufferOffset, uint32_t maxDrawCount, uint32_t stride ) { vkCmdDrawMeshTasksIndirectCountNV( commandBuffer, buffer, offset, countBuffer, countBufferOffset, maxDrawCount, stride ); }

    // VK_NV_scissor_exclusive
    void      CmdSetExclusiveScissorNV( uint32_t firstExclusiveScissor, uint32_t exclusiveScissorCount, const( VkRect2D )* pExclusiveScissors ) { vkCmdSetExclusiveScissorNV( commandBuffer, firstExclusiveScissor, exclusiveScissorCount, pExclusiveScissors ); }

    // VK_NV_device_diagnostic_checkpoints
    void      CmdSetCheckpointNV( const( void )* pCheckpointMarker ) { vkCmdSetCheckpointNV( commandBuffer, pCheckpointMarker ); }

    // VK_INTEL_performance_query
    VkResult  InitializePerformanceApiINTEL( const( VkInitializePerformanceApiInfoINTEL )* pInitializeInfo ) { return vkInitializePerformanceApiINTEL( vkDevice, pInitializeInfo ); }
    void      UninitializePerformanceApiINTEL() { vkUninitializePerformanceApiINTEL( vkDevice ); }
    VkResult  CmdSetPerformanceMarkerINTEL( const( VkPerformanceMarkerInfoINTEL )* pMarkerInfo ) { return vkCmdSetPerformanceMarkerINTEL( commandBuffer, pMarkerInfo ); }
    VkResult  CmdSetPerformanceStreamMarkerINTEL( const( VkPerformanceStreamMarkerInfoINTEL )* pMarkerInfo ) { return vkCmdSetPerformanceStreamMarkerINTEL( commandBuffer, pMarkerInfo ); }
    VkResult  CmdSetPerformanceOverrideINTEL( const( VkPerformanceOverrideInfoINTEL )* pOverrideInfo ) { return vkCmdSetPerformanceOverrideINTEL( commandBuffer, pOverrideInfo ); }
    VkResult  AcquirePerformanceConfigurationINTEL( const( VkPerformanceConfigurationAcquireInfoINTEL )* pAcquireInfo, VkPerformanceConfigurationINTEL* pConfiguration ) { return vkAcquirePerformanceConfigurationINTEL( vkDevice, pAcquireInfo, pConfiguration ); }
    VkResult  ReleasePerformanceConfigurationINTEL( VkPerformanceConfigurationINTEL configuration ) { return vkReleasePerformanceConfigurationINTEL( vkDevice, configuration ); }
    VkResult  GetPerformanceParameterINTEL( VkPerformanceParameterTypeINTEL parameter, VkPerformanceValueINTEL* pValue ) { return vkGetPerformanceParameterINTEL( vkDevice, parameter, pValue ); }

    // VK_AMD_display_native_hdr
    void      SetLocalDimmingAMD( VkSwapchainKHR swapChain, VkBool32 localDimmingEnable ) { vkSetLocalDimmingAMD( vkDevice, swapChain, localDimmingEnable ); }

    // VK_EXT_buffer_device_address
    VkDeviceAddress  GetBufferDeviceAddressEXT( const( VkBufferDeviceAddressInfoEXT )* pInfo ) { return vkGetBufferDeviceAddressEXT( vkDevice, pInfo ); }

    // VK_EXT_host_query_reset
    void      ResetQueryPoolEXT( VkQueryPool queryPool, uint32_t firstQuery, uint32_t queryCount ) { vkResetQueryPoolEXT( vkDevice, queryPool, firstQuery, queryCount ); }

    // VK_KHR_device_group
    alias GetDeviceGroupPeerMemoryFeaturesKHR                = GetDeviceGroupPeerMemoryFeatures;
    alias CmdSetDeviceMaskKHR                                = CmdSetDeviceMask;
    alias CmdDispatchBaseKHR                                 = CmdDispatchBase;

    // VK_KHR_maintenance1
    alias TrimCommandPoolKHR                                 = TrimCommandPool;

    // VK_KHR_descriptor_update_template
    alias CreateDescriptorUpdateTemplateKHR                  = CreateDescriptorUpdateTemplate;
    alias DestroyDescriptorUpdateTemplateKHR                 = DestroyDescriptorUpdateTemplate;
    alias UpdateDescriptorSetWithTemplateKHR                 = UpdateDescriptorSetWithTemplate;

    // VK_KHR_get_memory_requirements2
    alias GetImageMemoryRequirements2KHR                     = GetImageMemoryRequirements2;
    alias GetBufferMemoryRequirements2KHR                    = GetBufferMemoryRequirements2;
    alias GetImageSparseMemoryRequirements2KHR               = GetImageSparseMemoryRequirements2;

    // VK_KHR_sampler_ycbcr_conversion
    alias CreateSamplerYcbcrConversionKHR                    = CreateSamplerYcbcrConversion;
    alias DestroySamplerYcbcrConversionKHR                   = DestroySamplerYcbcrConversion;

    // VK_KHR_bind_memory2
    alias BindBufferMemory2KHR                               = BindBufferMemory2;
    alias BindImageMemory2KHR                                = BindImageMemory2;

    // VK_KHR_maintenance3
    alias GetDescriptorSetLayoutSupportKHR                   = GetDescriptorSetLayoutSupport;

    // VK_AMD_draw_indirect_count
    alias CmdDrawIndirectCountAMD                            = CmdDrawIndirectCountKHR;
    alias CmdDrawIndexedIndirectCountAMD                     = CmdDrawIndexedIndirectCountKHR;


    /// member function pointer decelerations

    // VK_VERSION_1_0
    PFN_vkDestroyDevice                                vkDestroyDevice;
    PFN_vkGetDeviceQueue                               vkGetDeviceQueue;
    PFN_vkQueueSubmit                                  vkQueueSubmit;
    PFN_vkQueueWaitIdle                                vkQueueWaitIdle;
    PFN_vkDeviceWaitIdle                               vkDeviceWaitIdle;
    PFN_vkAllocateMemory                               vkAllocateMemory;
    PFN_vkFreeMemory                                   vkFreeMemory;
    PFN_vkMapMemory                                    vkMapMemory;
    PFN_vkUnmapMemory                                  vkUnmapMemory;
    PFN_vkFlushMappedMemoryRanges                      vkFlushMappedMemoryRanges;
    PFN_vkInvalidateMappedMemoryRanges                 vkInvalidateMappedMemoryRanges;
    PFN_vkGetDeviceMemoryCommitment                    vkGetDeviceMemoryCommitment;
    PFN_vkBindBufferMemory                             vkBindBufferMemory;
    PFN_vkBindImageMemory                              vkBindImageMemory;
    PFN_vkGetBufferMemoryRequirements                  vkGetBufferMemoryRequirements;
    PFN_vkGetImageMemoryRequirements                   vkGetImageMemoryRequirements;
    PFN_vkGetImageSparseMemoryRequirements             vkGetImageSparseMemoryRequirements;
    PFN_vkQueueBindSparse                              vkQueueBindSparse;
    PFN_vkCreateFence                                  vkCreateFence;
    PFN_vkDestroyFence                                 vkDestroyFence;
    PFN_vkResetFences                                  vkResetFences;
    PFN_vkGetFenceStatus                               vkGetFenceStatus;
    PFN_vkWaitForFences                                vkWaitForFences;
    PFN_vkCreateSemaphore                              vkCreateSemaphore;
    PFN_vkDestroySemaphore                             vkDestroySemaphore;
    PFN_vkCreateEvent                                  vkCreateEvent;
    PFN_vkDestroyEvent                                 vkDestroyEvent;
    PFN_vkGetEventStatus                               vkGetEventStatus;
    PFN_vkSetEvent                                     vkSetEvent;
    PFN_vkResetEvent                                   vkResetEvent;
    PFN_vkCreateQueryPool                              vkCreateQueryPool;
    PFN_vkDestroyQueryPool                             vkDestroyQueryPool;
    PFN_vkGetQueryPoolResults                          vkGetQueryPoolResults;
    PFN_vkCreateBuffer                                 vkCreateBuffer;
    PFN_vkDestroyBuffer                                vkDestroyBuffer;
    PFN_vkCreateBufferView                             vkCreateBufferView;
    PFN_vkDestroyBufferView                            vkDestroyBufferView;
    PFN_vkCreateImage                                  vkCreateImage;
    PFN_vkDestroyImage                                 vkDestroyImage;
    PFN_vkGetImageSubresourceLayout                    vkGetImageSubresourceLayout;
    PFN_vkCreateImageView                              vkCreateImageView;
    PFN_vkDestroyImageView                             vkDestroyImageView;
    PFN_vkCreateShaderModule                           vkCreateShaderModule;
    PFN_vkDestroyShaderModule                          vkDestroyShaderModule;
    PFN_vkCreatePipelineCache                          vkCreatePipelineCache;
    PFN_vkDestroyPipelineCache                         vkDestroyPipelineCache;
    PFN_vkGetPipelineCacheData                         vkGetPipelineCacheData;
    PFN_vkMergePipelineCaches                          vkMergePipelineCaches;
    PFN_vkCreateGraphicsPipelines                      vkCreateGraphicsPipelines;
    PFN_vkCreateComputePipelines                       vkCreateComputePipelines;
    PFN_vkDestroyPipeline                              vkDestroyPipeline;
    PFN_vkCreatePipelineLayout                         vkCreatePipelineLayout;
    PFN_vkDestroyPipelineLayout                        vkDestroyPipelineLayout;
    PFN_vkCreateSampler                                vkCreateSampler;
    PFN_vkDestroySampler                               vkDestroySampler;
    PFN_vkCreateDescriptorSetLayout                    vkCreateDescriptorSetLayout;
    PFN_vkDestroyDescriptorSetLayout                   vkDestroyDescriptorSetLayout;
    PFN_vkCreateDescriptorPool                         vkCreateDescriptorPool;
    PFN_vkDestroyDescriptorPool                        vkDestroyDescriptorPool;
    PFN_vkResetDescriptorPool                          vkResetDescriptorPool;
    PFN_vkAllocateDescriptorSets                       vkAllocateDescriptorSets;
    PFN_vkFreeDescriptorSets                           vkFreeDescriptorSets;
    PFN_vkUpdateDescriptorSets                         vkUpdateDescriptorSets;
    PFN_vkCreateFramebuffer                            vkCreateFramebuffer;
    PFN_vkDestroyFramebuffer                           vkDestroyFramebuffer;
    PFN_vkCreateRenderPass                             vkCreateRenderPass;
    PFN_vkDestroyRenderPass                            vkDestroyRenderPass;
    PFN_vkGetRenderAreaGranularity                     vkGetRenderAreaGranularity;
    PFN_vkCreateCommandPool                            vkCreateCommandPool;
    PFN_vkDestroyCommandPool                           vkDestroyCommandPool;
    PFN_vkResetCommandPool                             vkResetCommandPool;
    PFN_vkAllocateCommandBuffers                       vkAllocateCommandBuffers;
    PFN_vkFreeCommandBuffers                           vkFreeCommandBuffers;
    PFN_vkBeginCommandBuffer                           vkBeginCommandBuffer;
    PFN_vkEndCommandBuffer                             vkEndCommandBuffer;
    PFN_vkResetCommandBuffer                           vkResetCommandBuffer;
    PFN_vkCmdBindPipeline                              vkCmdBindPipeline;
    PFN_vkCmdSetViewport                               vkCmdSetViewport;
    PFN_vkCmdSetScissor                                vkCmdSetScissor;
    PFN_vkCmdSetLineWidth                              vkCmdSetLineWidth;
    PFN_vkCmdSetDepthBias                              vkCmdSetDepthBias;
    PFN_vkCmdSetBlendConstants                         vkCmdSetBlendConstants;
    PFN_vkCmdSetDepthBounds                            vkCmdSetDepthBounds;
    PFN_vkCmdSetStencilCompareMask                     vkCmdSetStencilCompareMask;
    PFN_vkCmdSetStencilWriteMask                       vkCmdSetStencilWriteMask;
    PFN_vkCmdSetStencilReference                       vkCmdSetStencilReference;
    PFN_vkCmdBindDescriptorSets                        vkCmdBindDescriptorSets;
    PFN_vkCmdBindIndexBuffer                           vkCmdBindIndexBuffer;
    PFN_vkCmdBindVertexBuffers                         vkCmdBindVertexBuffers;
    PFN_vkCmdDraw                                      vkCmdDraw;
    PFN_vkCmdDrawIndexed                               vkCmdDrawIndexed;
    PFN_vkCmdDrawIndirect                              vkCmdDrawIndirect;
    PFN_vkCmdDrawIndexedIndirect                       vkCmdDrawIndexedIndirect;
    PFN_vkCmdDispatch                                  vkCmdDispatch;
    PFN_vkCmdDispatchIndirect                          vkCmdDispatchIndirect;
    PFN_vkCmdCopyBuffer                                vkCmdCopyBuffer;
    PFN_vkCmdCopyImage                                 vkCmdCopyImage;
    PFN_vkCmdBlitImage                                 vkCmdBlitImage;
    PFN_vkCmdCopyBufferToImage                         vkCmdCopyBufferToImage;
    PFN_vkCmdCopyImageToBuffer                         vkCmdCopyImageToBuffer;
    PFN_vkCmdUpdateBuffer                              vkCmdUpdateBuffer;
    PFN_vkCmdFillBuffer                                vkCmdFillBuffer;
    PFN_vkCmdClearColorImage                           vkCmdClearColorImage;
    PFN_vkCmdClearDepthStencilImage                    vkCmdClearDepthStencilImage;
    PFN_vkCmdClearAttachments                          vkCmdClearAttachments;
    PFN_vkCmdResolveImage                              vkCmdResolveImage;
    PFN_vkCmdSetEvent                                  vkCmdSetEvent;
    PFN_vkCmdResetEvent                                vkCmdResetEvent;
    PFN_vkCmdWaitEvents                                vkCmdWaitEvents;
    PFN_vkCmdPipelineBarrier                           vkCmdPipelineBarrier;
    PFN_vkCmdBeginQuery                                vkCmdBeginQuery;
    PFN_vkCmdEndQuery                                  vkCmdEndQuery;
    PFN_vkCmdResetQueryPool                            vkCmdResetQueryPool;
    PFN_vkCmdWriteTimestamp                            vkCmdWriteTimestamp;
    PFN_vkCmdCopyQueryPoolResults                      vkCmdCopyQueryPoolResults;
    PFN_vkCmdPushConstants                             vkCmdPushConstants;
    PFN_vkCmdBeginRenderPass                           vkCmdBeginRenderPass;
    PFN_vkCmdNextSubpass                               vkCmdNextSubpass;
    PFN_vkCmdEndRenderPass                             vkCmdEndRenderPass;
    PFN_vkCmdExecuteCommands                           vkCmdExecuteCommands;

    // VK_VERSION_1_1
    PFN_vkBindBufferMemory2                            vkBindBufferMemory2;
    PFN_vkBindImageMemory2                             vkBindImageMemory2;
    PFN_vkGetDeviceGroupPeerMemoryFeatures             vkGetDeviceGroupPeerMemoryFeatures;
    PFN_vkCmdSetDeviceMask                             vkCmdSetDeviceMask;
    PFN_vkCmdDispatchBase                              vkCmdDispatchBase;
    PFN_vkGetImageMemoryRequirements2                  vkGetImageMemoryRequirements2;
    PFN_vkGetBufferMemoryRequirements2                 vkGetBufferMemoryRequirements2;
    PFN_vkGetImageSparseMemoryRequirements2            vkGetImageSparseMemoryRequirements2;
    PFN_vkTrimCommandPool                              vkTrimCommandPool;
    PFN_vkGetDeviceQueue2                              vkGetDeviceQueue2;
    PFN_vkCreateSamplerYcbcrConversion                 vkCreateSamplerYcbcrConversion;
    PFN_vkDestroySamplerYcbcrConversion                vkDestroySamplerYcbcrConversion;
    PFN_vkCreateDescriptorUpdateTemplate               vkCreateDescriptorUpdateTemplate;
    PFN_vkDestroyDescriptorUpdateTemplate              vkDestroyDescriptorUpdateTemplate;
    PFN_vkUpdateDescriptorSetWithTemplate              vkUpdateDescriptorSetWithTemplate;
    PFN_vkGetDescriptorSetLayoutSupport                vkGetDescriptorSetLayoutSupport;

    // VK_KHR_swapchain
    PFN_vkCreateSwapchainKHR                           vkCreateSwapchainKHR;
    PFN_vkDestroySwapchainKHR                          vkDestroySwapchainKHR;
    PFN_vkGetSwapchainImagesKHR                        vkGetSwapchainImagesKHR;
    PFN_vkAcquireNextImageKHR                          vkAcquireNextImageKHR;
    PFN_vkQueuePresentKHR                              vkQueuePresentKHR;
    PFN_vkGetDeviceGroupPresentCapabilitiesKHR         vkGetDeviceGroupPresentCapabilitiesKHR;
    PFN_vkGetDeviceGroupSurfacePresentModesKHR         vkGetDeviceGroupSurfacePresentModesKHR;
    PFN_vkAcquireNextImage2KHR                         vkAcquireNextImage2KHR;

    // VK_KHR_display_swapchain
    PFN_vkCreateSharedSwapchainsKHR                    vkCreateSharedSwapchainsKHR;

    // VK_KHR_external_memory_fd
    PFN_vkGetMemoryFdKHR                               vkGetMemoryFdKHR;
    PFN_vkGetMemoryFdPropertiesKHR                     vkGetMemoryFdPropertiesKHR;

    // VK_KHR_external_semaphore_fd
    PFN_vkImportSemaphoreFdKHR                         vkImportSemaphoreFdKHR;
    PFN_vkGetSemaphoreFdKHR                            vkGetSemaphoreFdKHR;

    // VK_KHR_push_descriptor
    PFN_vkCmdPushDescriptorSetKHR                      vkCmdPushDescriptorSetKHR;
    PFN_vkCmdPushDescriptorSetWithTemplateKHR          vkCmdPushDescriptorSetWithTemplateKHR;

    // VK_KHR_create_renderpass2
    PFN_vkCreateRenderPass2KHR                         vkCreateRenderPass2KHR;
    PFN_vkCmdBeginRenderPass2KHR                       vkCmdBeginRenderPass2KHR;
    PFN_vkCmdNextSubpass2KHR                           vkCmdNextSubpass2KHR;
    PFN_vkCmdEndRenderPass2KHR                         vkCmdEndRenderPass2KHR;

    // VK_KHR_shared_presentable_image
    PFN_vkGetSwapchainStatusKHR                        vkGetSwapchainStatusKHR;

    // VK_KHR_external_fence_fd
    PFN_vkImportFenceFdKHR                             vkImportFenceFdKHR;
    PFN_vkGetFenceFdKHR                                vkGetFenceFdKHR;

    // VK_KHR_draw_indirect_count
    PFN_vkCmdDrawIndirectCountKHR                      vkCmdDrawIndirectCountKHR;
    PFN_vkCmdDrawIndexedIndirectCountKHR               vkCmdDrawIndexedIndirectCountKHR;

    // VK_EXT_debug_marker
    PFN_vkDebugMarkerSetObjectTagEXT                   vkDebugMarkerSetObjectTagEXT;
    PFN_vkDebugMarkerSetObjectNameEXT                  vkDebugMarkerSetObjectNameEXT;
    PFN_vkCmdDebugMarkerBeginEXT                       vkCmdDebugMarkerBeginEXT;
    PFN_vkCmdDebugMarkerEndEXT                         vkCmdDebugMarkerEndEXT;
    PFN_vkCmdDebugMarkerInsertEXT                      vkCmdDebugMarkerInsertEXT;

    // VK_EXT_transform_feedback
    PFN_vkCmdBindTransformFeedbackBuffersEXT           vkCmdBindTransformFeedbackBuffersEXT;
    PFN_vkCmdBeginTransformFeedbackEXT                 vkCmdBeginTransformFeedbackEXT;
    PFN_vkCmdEndTransformFeedbackEXT                   vkCmdEndTransformFeedbackEXT;
    PFN_vkCmdBeginQueryIndexedEXT                      vkCmdBeginQueryIndexedEXT;
    PFN_vkCmdEndQueryIndexedEXT                        vkCmdEndQueryIndexedEXT;
    PFN_vkCmdDrawIndirectByteCountEXT                  vkCmdDrawIndirectByteCountEXT;

    // VK_NVX_image_view_handle
    PFN_vkGetImageViewHandleNVX                        vkGetImageViewHandleNVX;

    // VK_AMD_shader_info
    PFN_vkGetShaderInfoAMD                             vkGetShaderInfoAMD;

    // VK_EXT_conditional_rendering
    PFN_vkCmdBeginConditionalRenderingEXT              vkCmdBeginConditionalRenderingEXT;
    PFN_vkCmdEndConditionalRenderingEXT                vkCmdEndConditionalRenderingEXT;

    // VK_NVX_device_generated_commands
    PFN_vkCmdProcessCommandsNVX                        vkCmdProcessCommandsNVX;
    PFN_vkCmdReserveSpaceForCommandsNVX                vkCmdReserveSpaceForCommandsNVX;
    PFN_vkCreateIndirectCommandsLayoutNVX              vkCreateIndirectCommandsLayoutNVX;
    PFN_vkDestroyIndirectCommandsLayoutNVX             vkDestroyIndirectCommandsLayoutNVX;
    PFN_vkCreateObjectTableNVX                         vkCreateObjectTableNVX;
    PFN_vkDestroyObjectTableNVX                        vkDestroyObjectTableNVX;
    PFN_vkRegisterObjectsNVX                           vkRegisterObjectsNVX;
    PFN_vkUnregisterObjectsNVX                         vkUnregisterObjectsNVX;

    // VK_NV_clip_space_w_scaling
    PFN_vkCmdSetViewportWScalingNV                     vkCmdSetViewportWScalingNV;

    // VK_EXT_display_control
    PFN_vkDisplayPowerControlEXT                       vkDisplayPowerControlEXT;
    PFN_vkRegisterDeviceEventEXT                       vkRegisterDeviceEventEXT;
    PFN_vkRegisterDisplayEventEXT                      vkRegisterDisplayEventEXT;
    PFN_vkGetSwapchainCounterEXT                       vkGetSwapchainCounterEXT;

    // VK_GOOGLE_display_timing
    PFN_vkGetRefreshCycleDurationGOOGLE                vkGetRefreshCycleDurationGOOGLE;
    PFN_vkGetPastPresentationTimingGOOGLE              vkGetPastPresentationTimingGOOGLE;

    // VK_EXT_discard_rectangles
    PFN_vkCmdSetDiscardRectangleEXT                    vkCmdSetDiscardRectangleEXT;

    // VK_EXT_hdr_metadata
    PFN_vkSetHdrMetadataEXT                            vkSetHdrMetadataEXT;

    // VK_EXT_debug_utils
    PFN_vkSetDebugUtilsObjectNameEXT                   vkSetDebugUtilsObjectNameEXT;
    PFN_vkSetDebugUtilsObjectTagEXT                    vkSetDebugUtilsObjectTagEXT;
    PFN_vkQueueBeginDebugUtilsLabelEXT                 vkQueueBeginDebugUtilsLabelEXT;
    PFN_vkQueueEndDebugUtilsLabelEXT                   vkQueueEndDebugUtilsLabelEXT;
    PFN_vkQueueInsertDebugUtilsLabelEXT                vkQueueInsertDebugUtilsLabelEXT;
    PFN_vkCmdBeginDebugUtilsLabelEXT                   vkCmdBeginDebugUtilsLabelEXT;
    PFN_vkCmdEndDebugUtilsLabelEXT                     vkCmdEndDebugUtilsLabelEXT;
    PFN_vkCmdInsertDebugUtilsLabelEXT                  vkCmdInsertDebugUtilsLabelEXT;

    // VK_EXT_sample_locations
    PFN_vkCmdSetSampleLocationsEXT                     vkCmdSetSampleLocationsEXT;

    // VK_EXT_image_drm_format_modifier
    PFN_vkGetImageDrmFormatModifierPropertiesEXT       vkGetImageDrmFormatModifierPropertiesEXT;

    // VK_EXT_validation_cache
    PFN_vkCreateValidationCacheEXT                     vkCreateValidationCacheEXT;
    PFN_vkDestroyValidationCacheEXT                    vkDestroyValidationCacheEXT;
    PFN_vkMergeValidationCachesEXT                     vkMergeValidationCachesEXT;
    PFN_vkGetValidationCacheDataEXT                    vkGetValidationCacheDataEXT;

    // VK_NV_shading_rate_image
    PFN_vkCmdBindShadingRateImageNV                    vkCmdBindShadingRateImageNV;
    PFN_vkCmdSetViewportShadingRatePaletteNV           vkCmdSetViewportShadingRatePaletteNV;
    PFN_vkCmdSetCoarseSampleOrderNV                    vkCmdSetCoarseSampleOrderNV;

    // VK_NV_ray_tracing
    PFN_vkCreateAccelerationStructureNV                vkCreateAccelerationStructureNV;
    PFN_vkDestroyAccelerationStructureNV               vkDestroyAccelerationStructureNV;
    PFN_vkGetAccelerationStructureMemoryRequirementsNV vkGetAccelerationStructureMemoryRequirementsNV;
    PFN_vkBindAccelerationStructureMemoryNV            vkBindAccelerationStructureMemoryNV;
    PFN_vkCmdBuildAccelerationStructureNV              vkCmdBuildAccelerationStructureNV;
    PFN_vkCmdCopyAccelerationStructureNV               vkCmdCopyAccelerationStructureNV;
    PFN_vkCmdTraceRaysNV                               vkCmdTraceRaysNV;
    PFN_vkCreateRayTracingPipelinesNV                  vkCreateRayTracingPipelinesNV;
    PFN_vkGetRayTracingShaderGroupHandlesNV            vkGetRayTracingShaderGroupHandlesNV;
    PFN_vkGetAccelerationStructureHandleNV             vkGetAccelerationStructureHandleNV;
    PFN_vkCmdWriteAccelerationStructuresPropertiesNV   vkCmdWriteAccelerationStructuresPropertiesNV;
    PFN_vkCompileDeferredNV                            vkCompileDeferredNV;

    // VK_EXT_external_memory_host
    PFN_vkGetMemoryHostPointerPropertiesEXT            vkGetMemoryHostPointerPropertiesEXT;

    // VK_AMD_buffer_marker
    PFN_vkCmdWriteBufferMarkerAMD                      vkCmdWriteBufferMarkerAMD;

    // VK_EXT_calibrated_timestamps
    PFN_vkGetCalibratedTimestampsEXT                   vkGetCalibratedTimestampsEXT;

    // VK_NV_mesh_shader
    PFN_vkCmdDrawMeshTasksNV                           vkCmdDrawMeshTasksNV;
    PFN_vkCmdDrawMeshTasksIndirectNV                   vkCmdDrawMeshTasksIndirectNV;
    PFN_vkCmdDrawMeshTasksIndirectCountNV              vkCmdDrawMeshTasksIndirectCountNV;

    // VK_NV_scissor_exclusive
    PFN_vkCmdSetExclusiveScissorNV                     vkCmdSetExclusiveScissorNV;

    // VK_NV_device_diagnostic_checkpoints
    PFN_vkCmdSetCheckpointNV                           vkCmdSetCheckpointNV;
    PFN_vkGetQueueCheckpointDataNV                     vkGetQueueCheckpointDataNV;

    // VK_INTEL_performance_query
    PFN_vkInitializePerformanceApiINTEL                vkInitializePerformanceApiINTEL;
    PFN_vkUninitializePerformanceApiINTEL              vkUninitializePerformanceApiINTEL;
    PFN_vkCmdSetPerformanceMarkerINTEL                 vkCmdSetPerformanceMarkerINTEL;
    PFN_vkCmdSetPerformanceStreamMarkerINTEL           vkCmdSetPerformanceStreamMarkerINTEL;
    PFN_vkCmdSetPerformanceOverrideINTEL               vkCmdSetPerformanceOverrideINTEL;
    PFN_vkAcquirePerformanceConfigurationINTEL         vkAcquirePerformanceConfigurationINTEL;
    PFN_vkReleasePerformanceConfigurationINTEL         vkReleasePerformanceConfigurationINTEL;
    PFN_vkQueueSetPerformanceConfigurationINTEL        vkQueueSetPerformanceConfigurationINTEL;
    PFN_vkGetPerformanceParameterINTEL                 vkGetPerformanceParameterINTEL;

    // VK_AMD_display_native_hdr
    PFN_vkSetLocalDimmingAMD                           vkSetLocalDimmingAMD;

    // VK_EXT_buffer_device_address
    PFN_vkGetBufferDeviceAddressEXT                    vkGetBufferDeviceAddressEXT;

    // VK_EXT_host_query_reset
    PFN_vkResetQueryPoolEXT                            vkResetQueryPoolEXT;

    // VK_KHR_device_group
    alias vkGetDeviceGroupPeerMemoryFeaturesKHR                = vkGetDeviceGroupPeerMemoryFeatures;
    alias vkCmdSetDeviceMaskKHR                                = vkCmdSetDeviceMask;
    alias vkCmdDispatchBaseKHR                                 = vkCmdDispatchBase;

    // VK_KHR_maintenance1
    alias vkTrimCommandPoolKHR                                 = vkTrimCommandPool;

    // VK_KHR_descriptor_update_template
    alias vkCreateDescriptorUpdateTemplateKHR                  = vkCreateDescriptorUpdateTemplate;
    alias vkDestroyDescriptorUpdateTemplateKHR                 = vkDestroyDescriptorUpdateTemplate;
    alias vkUpdateDescriptorSetWithTemplateKHR                 = vkUpdateDescriptorSetWithTemplate;

    // VK_KHR_get_memory_requirements2
    alias vkGetImageMemoryRequirements2KHR                     = vkGetImageMemoryRequirements2;
    alias vkGetBufferMemoryRequirements2KHR                    = vkGetBufferMemoryRequirements2;
    alias vkGetImageSparseMemoryRequirements2KHR               = vkGetImageSparseMemoryRequirements2;

    // VK_KHR_sampler_ycbcr_conversion
    alias vkCreateSamplerYcbcrConversionKHR                    = vkCreateSamplerYcbcrConversion;
    alias vkDestroySamplerYcbcrConversionKHR                   = vkDestroySamplerYcbcrConversion;

    // VK_KHR_bind_memory2
    alias vkBindBufferMemory2KHR                               = vkBindBufferMemory2;
    alias vkBindImageMemory2KHR                                = vkBindImageMemory2;

    // VK_KHR_maintenance3
    alias vkGetDescriptorSetLayoutSupportKHR                   = vkGetDescriptorSetLayoutSupport;

    // VK_AMD_draw_indirect_count
    alias vkCmdDrawIndirectCountAMD                            = vkCmdDrawIndirectCountKHR;
    alias vkCmdDrawIndexedIndirectCountAMD                     = vkCmdDrawIndexedIndirectCountKHR;
}

