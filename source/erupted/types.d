/**
 * Dlang vulkan type definitions
 *
 * Copyright: Copyright 2015-2016 The Khronos Group Inc.; Copyright 2016 Alex Parrill, Peter Particle.
 * License:   $(https://opensource.org/licenses/MIT, MIT License).
 * Authors: Copyright 2016 Alex Parrill, Peter Particle
 */
module erupted.types;

nothrow @nogc:


// defined in vk_platform.h
alias uint8_t   = ubyte;
alias uint16_t  = ushort;
alias uint32_t  = uint;
alias uint64_t  = ulong;
alias int8_t    = byte;
alias int16_t   = short;
alias int32_t   = int;
alias int64_t   = long;


// version functions / macros
pure {
    uint VK_MAKE_VERSION( uint major, uint minor, uint patch ) { return ( major << 22 ) | ( minor << 12 ) | ( patch ); }
    uint VK_VERSION_MAJOR( uint ver ) { return ver >> 22; }
    uint VK_VERSION_MINOR( uint ver ) { return ( ver >> 12 ) & 0x3ff; }
    uint VK_VERSION_PATCH( uint ver ) { return ver & 0xfff; }
}

// Linkage of debug and allocation callbacks
extern( System ):

// Version of corresponding c header file
enum VK_HEADER_VERSION = 110;

enum VK_NULL_HANDLE = null;

enum VK_DEFINE_HANDLE( string name ) = "struct " ~ name ~ "_handle; alias " ~ name ~ " = " ~ name ~ "_handle*;";

version( X86_64 ) {
    alias VK_DEFINE_NON_DISPATCHABLE_HANDLE( string name ) = VK_DEFINE_HANDLE!name;
    enum VK_NULL_ND_HANDLE = null;
} else {
    enum VK_DEFINE_NON_DISPATCHABLE_HANDLE( string name ) = "alias " ~ name ~ " = ulong;";
    enum VK_NULL_ND_HANDLE = 0uL;
}

// - VK_VERSION_1_0 -
enum VK_VERSION_1_0 = 1;

// Vulkan 1.0 version number
enum VK_API_VERSION_1_0 = VK_MAKE_VERSION( 1, 0, 0 );  // Patch version should always be set to 0

alias VkFlags = uint32_t;
alias VkBool32 = uint32_t;
alias VkDeviceSize = uint64_t;
alias VkSampleMask = uint32_t;

mixin( VK_DEFINE_HANDLE!q{VkInstance} );
mixin( VK_DEFINE_HANDLE!q{VkPhysicalDevice} );
mixin( VK_DEFINE_HANDLE!q{VkDevice} );
mixin( VK_DEFINE_HANDLE!q{VkQueue} );
mixin( VK_DEFINE_NON_DISPATCHABLE_HANDLE!q{VkSemaphore} );
mixin( VK_DEFINE_HANDLE!q{VkCommandBuffer} );
mixin( VK_DEFINE_NON_DISPATCHABLE_HANDLE!q{VkFence} );
mixin( VK_DEFINE_NON_DISPATCHABLE_HANDLE!q{VkDeviceMemory} );
mixin( VK_DEFINE_NON_DISPATCHABLE_HANDLE!q{VkBuffer} );
mixin( VK_DEFINE_NON_DISPATCHABLE_HANDLE!q{VkImage} );
mixin( VK_DEFINE_NON_DISPATCHABLE_HANDLE!q{VkEvent} );
mixin( VK_DEFINE_NON_DISPATCHABLE_HANDLE!q{VkQueryPool} );
mixin( VK_DEFINE_NON_DISPATCHABLE_HANDLE!q{VkBufferView} );
mixin( VK_DEFINE_NON_DISPATCHABLE_HANDLE!q{VkImageView} );
mixin( VK_DEFINE_NON_DISPATCHABLE_HANDLE!q{VkShaderModule} );
mixin( VK_DEFINE_NON_DISPATCHABLE_HANDLE!q{VkPipelineCache} );
mixin( VK_DEFINE_NON_DISPATCHABLE_HANDLE!q{VkPipelineLayout} );
mixin( VK_DEFINE_NON_DISPATCHABLE_HANDLE!q{VkRenderPass} );
mixin( VK_DEFINE_NON_DISPATCHABLE_HANDLE!q{VkPipeline} );
mixin( VK_DEFINE_NON_DISPATCHABLE_HANDLE!q{VkDescriptorSetLayout} );
mixin( VK_DEFINE_NON_DISPATCHABLE_HANDLE!q{VkSampler} );
mixin( VK_DEFINE_NON_DISPATCHABLE_HANDLE!q{VkDescriptorPool} );
mixin( VK_DEFINE_NON_DISPATCHABLE_HANDLE!q{VkDescriptorSet} );
mixin( VK_DEFINE_NON_DISPATCHABLE_HANDLE!q{VkFramebuffer} );
mixin( VK_DEFINE_NON_DISPATCHABLE_HANDLE!q{VkCommandPool} );

enum VK_LOD_CLAMP_NONE = 1000.0f;
enum VK_REMAINING_MIP_LEVELS = (~0U);
enum VK_REMAINING_ARRAY_LAYERS = (~0U);
enum VK_WHOLE_SIZE = (~0UL);
enum VK_ATTACHMENT_UNUSED = (~0U);
enum VK_TRUE = 1;
enum VK_FALSE = 0;
enum VK_QUEUE_FAMILY_IGNORED = (~0U);
enum VK_SUBPASS_EXTERNAL = (~0U);
enum VK_MAX_PHYSICAL_DEVICE_NAME_SIZE = 256;
enum VK_UUID_SIZE = 16;
enum VK_MAX_MEMORY_TYPES = 32;
enum VK_MAX_MEMORY_HEAPS = 16;
enum VK_MAX_EXTENSION_NAME_SIZE = 256;
enum VK_MAX_DESCRIPTION_SIZE = 256;

enum VkPipelineCacheHeaderVersion {
    VK_PIPELINE_CACHE_HEADER_VERSION_ONE                 = 1,
    VK_PIPELINE_CACHE_HEADER_VERSION_BEGIN_RANGE         = VK_PIPELINE_CACHE_HEADER_VERSION_ONE,
    VK_PIPELINE_CACHE_HEADER_VERSION_END_RANGE           = VK_PIPELINE_CACHE_HEADER_VERSION_ONE,
    VK_PIPELINE_CACHE_HEADER_VERSION_RANGE_SIZE          = VK_PIPELINE_CACHE_HEADER_VERSION_ONE - VK_PIPELINE_CACHE_HEADER_VERSION_ONE + 1,
    VK_PIPELINE_CACHE_HEADER_VERSION_MAX_ENUM            = 0x7FFFFFFF
}

enum VK_PIPELINE_CACHE_HEADER_VERSION_ONE                = VkPipelineCacheHeaderVersion.VK_PIPELINE_CACHE_HEADER_VERSION_ONE;
enum VK_PIPELINE_CACHE_HEADER_VERSION_BEGIN_RANGE        = VkPipelineCacheHeaderVersion.VK_PIPELINE_CACHE_HEADER_VERSION_BEGIN_RANGE;
enum VK_PIPELINE_CACHE_HEADER_VERSION_END_RANGE          = VkPipelineCacheHeaderVersion.VK_PIPELINE_CACHE_HEADER_VERSION_END_RANGE;
enum VK_PIPELINE_CACHE_HEADER_VERSION_RANGE_SIZE         = VkPipelineCacheHeaderVersion.VK_PIPELINE_CACHE_HEADER_VERSION_RANGE_SIZE;
enum VK_PIPELINE_CACHE_HEADER_VERSION_MAX_ENUM           = VkPipelineCacheHeaderVersion.VK_PIPELINE_CACHE_HEADER_VERSION_MAX_ENUM;

enum VkResult {
    VK_SUCCESS                                                   = 0,
    VK_NOT_READY                                                 = 1,
    VK_TIMEOUT                                                   = 2,
    VK_EVENT_SET                                                 = 3,
    VK_EVENT_RESET                                               = 4,
    VK_INCOMPLETE                                                = 5,
    VK_ERROR_OUT_OF_HOST_MEMORY                                  = -1,
    VK_ERROR_OUT_OF_DEVICE_MEMORY                                = -2,
    VK_ERROR_INITIALIZATION_FAILED                               = -3,
    VK_ERROR_DEVICE_LOST                                         = -4,
    VK_ERROR_MEMORY_MAP_FAILED                                   = -5,
    VK_ERROR_LAYER_NOT_PRESENT                                   = -6,
    VK_ERROR_EXTENSION_NOT_PRESENT                               = -7,
    VK_ERROR_FEATURE_NOT_PRESENT                                 = -8,
    VK_ERROR_INCOMPATIBLE_DRIVER                                 = -9,
    VK_ERROR_TOO_MANY_OBJECTS                                    = -10,
    VK_ERROR_FORMAT_NOT_SUPPORTED                                = -11,
    VK_ERROR_FRAGMENTED_POOL                                     = -12,
    VK_ERROR_OUT_OF_POOL_MEMORY                                  = -1000069000,
    VK_ERROR_INVALID_EXTERNAL_HANDLE                             = -1000072003,
    VK_ERROR_SURFACE_LOST_KHR                                    = -1000000000,
    VK_ERROR_NATIVE_WINDOW_IN_USE_KHR                            = -1000000001,
    VK_SUBOPTIMAL_KHR                                            = 1000001003,
    VK_ERROR_OUT_OF_DATE_KHR                                     = -1000001004,
    VK_ERROR_INCOMPATIBLE_DISPLAY_KHR                            = -1000003001,
    VK_ERROR_VALIDATION_FAILED_EXT                               = -1000011001,
    VK_ERROR_INVALID_SHADER_NV                                   = -1000012000,
    VK_ERROR_INVALID_DRM_FORMAT_MODIFIER_PLANE_LAYOUT_EXT        = -1000158000,
    VK_ERROR_FRAGMENTATION_EXT                                   = -1000161000,
    VK_ERROR_NOT_PERMITTED_EXT                                   = -1000174001,
    VK_ERROR_INVALID_DEVICE_ADDRESS_EXT                          = -1000244000,
    VK_ERROR_FULL_SCREEN_EXCLUSIVE_MODE_LOST_EXT                 = -1000255000,
    VK_ERROR_OUT_OF_POOL_MEMORY_KHR                              = VK_ERROR_OUT_OF_POOL_MEMORY,
    VK_ERROR_INVALID_EXTERNAL_HANDLE_KHR                         = VK_ERROR_INVALID_EXTERNAL_HANDLE,
    VK_RESULT_BEGIN_RANGE                                        = VK_ERROR_FRAGMENTED_POOL,
    VK_RESULT_END_RANGE                                          = VK_INCOMPLETE,
    VK_RESULT_RANGE_SIZE                                         = VK_INCOMPLETE - VK_ERROR_FRAGMENTED_POOL + 1,
    VK_RESULT_MAX_ENUM                                           = 0x7FFFFFFF
}

enum VK_SUCCESS                                                  = VkResult.VK_SUCCESS;
enum VK_NOT_READY                                                = VkResult.VK_NOT_READY;
enum VK_TIMEOUT                                                  = VkResult.VK_TIMEOUT;
enum VK_EVENT_SET                                                = VkResult.VK_EVENT_SET;
enum VK_EVENT_RESET                                              = VkResult.VK_EVENT_RESET;
enum VK_INCOMPLETE                                               = VkResult.VK_INCOMPLETE;
enum VK_ERROR_OUT_OF_HOST_MEMORY                                 = VkResult.VK_ERROR_OUT_OF_HOST_MEMORY;
enum VK_ERROR_OUT_OF_DEVICE_MEMORY                               = VkResult.VK_ERROR_OUT_OF_DEVICE_MEMORY;
enum VK_ERROR_INITIALIZATION_FAILED                              = VkResult.VK_ERROR_INITIALIZATION_FAILED;
enum VK_ERROR_DEVICE_LOST                                        = VkResult.VK_ERROR_DEVICE_LOST;
enum VK_ERROR_MEMORY_MAP_FAILED                                  = VkResult.VK_ERROR_MEMORY_MAP_FAILED;
enum VK_ERROR_LAYER_NOT_PRESENT                                  = VkResult.VK_ERROR_LAYER_NOT_PRESENT;
enum VK_ERROR_EXTENSION_NOT_PRESENT                              = VkResult.VK_ERROR_EXTENSION_NOT_PRESENT;
enum VK_ERROR_FEATURE_NOT_PRESENT                                = VkResult.VK_ERROR_FEATURE_NOT_PRESENT;
enum VK_ERROR_INCOMPATIBLE_DRIVER                                = VkResult.VK_ERROR_INCOMPATIBLE_DRIVER;
enum VK_ERROR_TOO_MANY_OBJECTS                                   = VkResult.VK_ERROR_TOO_MANY_OBJECTS;
enum VK_ERROR_FORMAT_NOT_SUPPORTED                               = VkResult.VK_ERROR_FORMAT_NOT_SUPPORTED;
enum VK_ERROR_FRAGMENTED_POOL                                    = VkResult.VK_ERROR_FRAGMENTED_POOL;
enum VK_ERROR_OUT_OF_POOL_MEMORY                                 = VkResult.VK_ERROR_OUT_OF_POOL_MEMORY;
enum VK_ERROR_INVALID_EXTERNAL_HANDLE                            = VkResult.VK_ERROR_INVALID_EXTERNAL_HANDLE;
enum VK_ERROR_SURFACE_LOST_KHR                                   = VkResult.VK_ERROR_SURFACE_LOST_KHR;
enum VK_ERROR_NATIVE_WINDOW_IN_USE_KHR                           = VkResult.VK_ERROR_NATIVE_WINDOW_IN_USE_KHR;
enum VK_SUBOPTIMAL_KHR                                           = VkResult.VK_SUBOPTIMAL_KHR;
enum VK_ERROR_OUT_OF_DATE_KHR                                    = VkResult.VK_ERROR_OUT_OF_DATE_KHR;
enum VK_ERROR_INCOMPATIBLE_DISPLAY_KHR                           = VkResult.VK_ERROR_INCOMPATIBLE_DISPLAY_KHR;
enum VK_ERROR_VALIDATION_FAILED_EXT                              = VkResult.VK_ERROR_VALIDATION_FAILED_EXT;
enum VK_ERROR_INVALID_SHADER_NV                                  = VkResult.VK_ERROR_INVALID_SHADER_NV;
enum VK_ERROR_INVALID_DRM_FORMAT_MODIFIER_PLANE_LAYOUT_EXT       = VkResult.VK_ERROR_INVALID_DRM_FORMAT_MODIFIER_PLANE_LAYOUT_EXT;
enum VK_ERROR_FRAGMENTATION_EXT                                  = VkResult.VK_ERROR_FRAGMENTATION_EXT;
enum VK_ERROR_NOT_PERMITTED_EXT                                  = VkResult.VK_ERROR_NOT_PERMITTED_EXT;
enum VK_ERROR_INVALID_DEVICE_ADDRESS_EXT                         = VkResult.VK_ERROR_INVALID_DEVICE_ADDRESS_EXT;
enum VK_ERROR_FULL_SCREEN_EXCLUSIVE_MODE_LOST_EXT                = VkResult.VK_ERROR_FULL_SCREEN_EXCLUSIVE_MODE_LOST_EXT;
enum VK_ERROR_OUT_OF_POOL_MEMORY_KHR                             = VkResult.VK_ERROR_OUT_OF_POOL_MEMORY_KHR;
enum VK_ERROR_INVALID_EXTERNAL_HANDLE_KHR                        = VkResult.VK_ERROR_INVALID_EXTERNAL_HANDLE_KHR;
enum VK_RESULT_BEGIN_RANGE                                       = VkResult.VK_RESULT_BEGIN_RANGE;
enum VK_RESULT_END_RANGE                                         = VkResult.VK_RESULT_END_RANGE;
enum VK_RESULT_RANGE_SIZE                                        = VkResult.VK_RESULT_RANGE_SIZE;
enum VK_RESULT_MAX_ENUM                                          = VkResult.VK_RESULT_MAX_ENUM;

enum VkStructureType {
    VK_STRUCTURE_TYPE_APPLICATION_INFO                                                   = 0,
    VK_STRUCTURE_TYPE_INSTANCE_CREATE_INFO                                               = 1,
    VK_STRUCTURE_TYPE_DEVICE_QUEUE_CREATE_INFO                                           = 2,
    VK_STRUCTURE_TYPE_DEVICE_CREATE_INFO                                                 = 3,
    VK_STRUCTURE_TYPE_SUBMIT_INFO                                                        = 4,
    VK_STRUCTURE_TYPE_MEMORY_ALLOCATE_INFO                                               = 5,
    VK_STRUCTURE_TYPE_MAPPED_MEMORY_RANGE                                                = 6,
    VK_STRUCTURE_TYPE_BIND_SPARSE_INFO                                                   = 7,
    VK_STRUCTURE_TYPE_FENCE_CREATE_INFO                                                  = 8,
    VK_STRUCTURE_TYPE_SEMAPHORE_CREATE_INFO                                              = 9,
    VK_STRUCTURE_TYPE_EVENT_CREATE_INFO                                                  = 10,
    VK_STRUCTURE_TYPE_QUERY_POOL_CREATE_INFO                                             = 11,
    VK_STRUCTURE_TYPE_BUFFER_CREATE_INFO                                                 = 12,
    VK_STRUCTURE_TYPE_BUFFER_VIEW_CREATE_INFO                                            = 13,
    VK_STRUCTURE_TYPE_IMAGE_CREATE_INFO                                                  = 14,
    VK_STRUCTURE_TYPE_IMAGE_VIEW_CREATE_INFO                                             = 15,
    VK_STRUCTURE_TYPE_SHADER_MODULE_CREATE_INFO                                          = 16,
    VK_STRUCTURE_TYPE_PIPELINE_CACHE_CREATE_INFO                                         = 17,
    VK_STRUCTURE_TYPE_PIPELINE_SHADER_STAGE_CREATE_INFO                                  = 18,
    VK_STRUCTURE_TYPE_PIPELINE_VERTEX_INPUT_STATE_CREATE_INFO                            = 19,
    VK_STRUCTURE_TYPE_PIPELINE_INPUT_ASSEMBLY_STATE_CREATE_INFO                          = 20,
    VK_STRUCTURE_TYPE_PIPELINE_TESSELLATION_STATE_CREATE_INFO                            = 21,
    VK_STRUCTURE_TYPE_PIPELINE_VIEWPORT_STATE_CREATE_INFO                                = 22,
    VK_STRUCTURE_TYPE_PIPELINE_RASTERIZATION_STATE_CREATE_INFO                           = 23,
    VK_STRUCTURE_TYPE_PIPELINE_MULTISAMPLE_STATE_CREATE_INFO                             = 24,
    VK_STRUCTURE_TYPE_PIPELINE_DEPTH_STENCIL_STATE_CREATE_INFO                           = 25,
    VK_STRUCTURE_TYPE_PIPELINE_COLOR_BLEND_STATE_CREATE_INFO                             = 26,
    VK_STRUCTURE_TYPE_PIPELINE_DYNAMIC_STATE_CREATE_INFO                                 = 27,
    VK_STRUCTURE_TYPE_GRAPHICS_PIPELINE_CREATE_INFO                                      = 28,
    VK_STRUCTURE_TYPE_COMPUTE_PIPELINE_CREATE_INFO                                       = 29,
    VK_STRUCTURE_TYPE_PIPELINE_LAYOUT_CREATE_INFO                                        = 30,
    VK_STRUCTURE_TYPE_SAMPLER_CREATE_INFO                                                = 31,
    VK_STRUCTURE_TYPE_DESCRIPTOR_SET_LAYOUT_CREATE_INFO                                  = 32,
    VK_STRUCTURE_TYPE_DESCRIPTOR_POOL_CREATE_INFO                                        = 33,
    VK_STRUCTURE_TYPE_DESCRIPTOR_SET_ALLOCATE_INFO                                       = 34,
    VK_STRUCTURE_TYPE_WRITE_DESCRIPTOR_SET                                               = 35,
    VK_STRUCTURE_TYPE_COPY_DESCRIPTOR_SET                                                = 36,
    VK_STRUCTURE_TYPE_FRAMEBUFFER_CREATE_INFO                                            = 37,
    VK_STRUCTURE_TYPE_RENDER_PASS_CREATE_INFO                                            = 38,
    VK_STRUCTURE_TYPE_COMMAND_POOL_CREATE_INFO                                           = 39,
    VK_STRUCTURE_TYPE_COMMAND_BUFFER_ALLOCATE_INFO                                       = 40,
    VK_STRUCTURE_TYPE_COMMAND_BUFFER_INHERITANCE_INFO                                    = 41,
    VK_STRUCTURE_TYPE_COMMAND_BUFFER_BEGIN_INFO                                          = 42,
    VK_STRUCTURE_TYPE_RENDER_PASS_BEGIN_INFO                                             = 43,
    VK_STRUCTURE_TYPE_BUFFER_MEMORY_BARRIER                                              = 44,
    VK_STRUCTURE_TYPE_IMAGE_MEMORY_BARRIER                                               = 45,
    VK_STRUCTURE_TYPE_MEMORY_BARRIER                                                     = 46,
    VK_STRUCTURE_TYPE_LOADER_INSTANCE_CREATE_INFO                                        = 47,
    VK_STRUCTURE_TYPE_LOADER_DEVICE_CREATE_INFO                                          = 48,
    VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_SUBGROUP_PROPERTIES                                = 1000094000,
    VK_STRUCTURE_TYPE_BIND_BUFFER_MEMORY_INFO                                            = 1000157000,
    VK_STRUCTURE_TYPE_BIND_IMAGE_MEMORY_INFO                                             = 1000157001,
    VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_16BIT_STORAGE_FEATURES                             = 1000083000,
    VK_STRUCTURE_TYPE_MEMORY_DEDICATED_REQUIREMENTS                                      = 1000127000,
    VK_STRUCTURE_TYPE_MEMORY_DEDICATED_ALLOCATE_INFO                                     = 1000127001,
    VK_STRUCTURE_TYPE_MEMORY_ALLOCATE_FLAGS_INFO                                         = 1000060000,
    VK_STRUCTURE_TYPE_DEVICE_GROUP_RENDER_PASS_BEGIN_INFO                                = 1000060003,
    VK_STRUCTURE_TYPE_DEVICE_GROUP_COMMAND_BUFFER_BEGIN_INFO                             = 1000060004,
    VK_STRUCTURE_TYPE_DEVICE_GROUP_SUBMIT_INFO                                           = 1000060005,
    VK_STRUCTURE_TYPE_DEVICE_GROUP_BIND_SPARSE_INFO                                      = 1000060006,
    VK_STRUCTURE_TYPE_BIND_BUFFER_MEMORY_DEVICE_GROUP_INFO                               = 1000060013,
    VK_STRUCTURE_TYPE_BIND_IMAGE_MEMORY_DEVICE_GROUP_INFO                                = 1000060014,
    VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_GROUP_PROPERTIES                                   = 1000070000,
    VK_STRUCTURE_TYPE_DEVICE_GROUP_DEVICE_CREATE_INFO                                    = 1000070001,
    VK_STRUCTURE_TYPE_BUFFER_MEMORY_REQUIREMENTS_INFO_2                                  = 1000146000,
    VK_STRUCTURE_TYPE_IMAGE_MEMORY_REQUIREMENTS_INFO_2                                   = 1000146001,
    VK_STRUCTURE_TYPE_IMAGE_SPARSE_MEMORY_REQUIREMENTS_INFO_2                            = 1000146002,
    VK_STRUCTURE_TYPE_MEMORY_REQUIREMENTS_2                                              = 1000146003,
    VK_STRUCTURE_TYPE_SPARSE_IMAGE_MEMORY_REQUIREMENTS_2                                 = 1000146004,
    VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_FEATURES_2                                         = 1000059000,
    VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_PROPERTIES_2                                       = 1000059001,
    VK_STRUCTURE_TYPE_FORMAT_PROPERTIES_2                                                = 1000059002,
    VK_STRUCTURE_TYPE_IMAGE_FORMAT_PROPERTIES_2                                          = 1000059003,
    VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_IMAGE_FORMAT_INFO_2                                = 1000059004,
    VK_STRUCTURE_TYPE_QUEUE_FAMILY_PROPERTIES_2                                          = 1000059005,
    VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_MEMORY_PROPERTIES_2                                = 1000059006,
    VK_STRUCTURE_TYPE_SPARSE_IMAGE_FORMAT_PROPERTIES_2                                   = 1000059007,
    VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_SPARSE_IMAGE_FORMAT_INFO_2                         = 1000059008,
    VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_POINT_CLIPPING_PROPERTIES                          = 1000117000,
    VK_STRUCTURE_TYPE_RENDER_PASS_INPUT_ATTACHMENT_ASPECT_CREATE_INFO                    = 1000117001,
    VK_STRUCTURE_TYPE_IMAGE_VIEW_USAGE_CREATE_INFO                                       = 1000117002,
    VK_STRUCTURE_TYPE_PIPELINE_TESSELLATION_DOMAIN_ORIGIN_STATE_CREATE_INFO              = 1000117003,
    VK_STRUCTURE_TYPE_RENDER_PASS_MULTIVIEW_CREATE_INFO                                  = 1000053000,
    VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_MULTIVIEW_FEATURES                                 = 1000053001,
    VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_MULTIVIEW_PROPERTIES                               = 1000053002,
    VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_VARIABLE_POINTERS_FEATURES                         = 1000120000,
    VK_STRUCTURE_TYPE_PROTECTED_SUBMIT_INFO                                              = 1000145000,
    VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_PROTECTED_MEMORY_FEATURES                          = 1000145001,
    VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_PROTECTED_MEMORY_PROPERTIES                        = 1000145002,
    VK_STRUCTURE_TYPE_DEVICE_QUEUE_INFO_2                                                = 1000145003,
    VK_STRUCTURE_TYPE_SAMPLER_YCBCR_CONVERSION_CREATE_INFO                               = 1000156000,
    VK_STRUCTURE_TYPE_SAMPLER_YCBCR_CONVERSION_INFO                                      = 1000156001,
    VK_STRUCTURE_TYPE_BIND_IMAGE_PLANE_MEMORY_INFO                                       = 1000156002,
    VK_STRUCTURE_TYPE_IMAGE_PLANE_MEMORY_REQUIREMENTS_INFO                               = 1000156003,
    VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_SAMPLER_YCBCR_CONVERSION_FEATURES                  = 1000156004,
    VK_STRUCTURE_TYPE_SAMPLER_YCBCR_CONVERSION_IMAGE_FORMAT_PROPERTIES                   = 1000156005,
    VK_STRUCTURE_TYPE_DESCRIPTOR_UPDATE_TEMPLATE_CREATE_INFO                             = 1000085000,
    VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_EXTERNAL_IMAGE_FORMAT_INFO                         = 1000071000,
    VK_STRUCTURE_TYPE_EXTERNAL_IMAGE_FORMAT_PROPERTIES                                   = 1000071001,
    VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_EXTERNAL_BUFFER_INFO                               = 1000071002,
    VK_STRUCTURE_TYPE_EXTERNAL_BUFFER_PROPERTIES                                         = 1000071003,
    VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_ID_PROPERTIES                                      = 1000071004,
    VK_STRUCTURE_TYPE_EXTERNAL_MEMORY_BUFFER_CREATE_INFO                                 = 1000072000,
    VK_STRUCTURE_TYPE_EXTERNAL_MEMORY_IMAGE_CREATE_INFO                                  = 1000072001,
    VK_STRUCTURE_TYPE_EXPORT_MEMORY_ALLOCATE_INFO                                        = 1000072002,
    VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_EXTERNAL_FENCE_INFO                                = 1000112000,
    VK_STRUCTURE_TYPE_EXTERNAL_FENCE_PROPERTIES                                          = 1000112001,
    VK_STRUCTURE_TYPE_EXPORT_FENCE_CREATE_INFO                                           = 1000113000,
    VK_STRUCTURE_TYPE_EXPORT_SEMAPHORE_CREATE_INFO                                       = 1000077000,
    VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_EXTERNAL_SEMAPHORE_INFO                            = 1000076000,
    VK_STRUCTURE_TYPE_EXTERNAL_SEMAPHORE_PROPERTIES                                      = 1000076001,
    VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_MAINTENANCE_3_PROPERTIES                           = 1000168000,
    VK_STRUCTURE_TYPE_DESCRIPTOR_SET_LAYOUT_SUPPORT                                      = 1000168001,
    VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_SHADER_DRAW_PARAMETERS_FEATURES                    = 1000063000,
    VK_STRUCTURE_TYPE_SWAPCHAIN_CREATE_INFO_KHR                                          = 1000001000,
    VK_STRUCTURE_TYPE_PRESENT_INFO_KHR                                                   = 1000001001,
    VK_STRUCTURE_TYPE_DEVICE_GROUP_PRESENT_CAPABILITIES_KHR                              = 1000060007,
    VK_STRUCTURE_TYPE_IMAGE_SWAPCHAIN_CREATE_INFO_KHR                                    = 1000060008,
    VK_STRUCTURE_TYPE_BIND_IMAGE_MEMORY_SWAPCHAIN_INFO_KHR                               = 1000060009,
    VK_STRUCTURE_TYPE_ACQUIRE_NEXT_IMAGE_INFO_KHR                                        = 1000060010,
    VK_STRUCTURE_TYPE_DEVICE_GROUP_PRESENT_INFO_KHR                                      = 1000060011,
    VK_STRUCTURE_TYPE_DEVICE_GROUP_SWAPCHAIN_CREATE_INFO_KHR                             = 1000060012,
    VK_STRUCTURE_TYPE_DISPLAY_MODE_CREATE_INFO_KHR                                       = 1000002000,
    VK_STRUCTURE_TYPE_DISPLAY_SURFACE_CREATE_INFO_KHR                                    = 1000002001,
    VK_STRUCTURE_TYPE_DISPLAY_PRESENT_INFO_KHR                                           = 1000003000,
    VK_STRUCTURE_TYPE_XLIB_SURFACE_CREATE_INFO_KHR                                       = 1000004000,
    VK_STRUCTURE_TYPE_XCB_SURFACE_CREATE_INFO_KHR                                        = 1000005000,
    VK_STRUCTURE_TYPE_WAYLAND_SURFACE_CREATE_INFO_KHR                                    = 1000006000,
    VK_STRUCTURE_TYPE_ANDROID_SURFACE_CREATE_INFO_KHR                                    = 1000008000,
    VK_STRUCTURE_TYPE_WIN32_SURFACE_CREATE_INFO_KHR                                      = 1000009000,
    VK_STRUCTURE_TYPE_DEBUG_REPORT_CALLBACK_CREATE_INFO_EXT                              = 1000011000,
    VK_STRUCTURE_TYPE_PIPELINE_RASTERIZATION_STATE_RASTERIZATION_ORDER_AMD               = 1000018000,
    VK_STRUCTURE_TYPE_DEBUG_MARKER_OBJECT_NAME_INFO_EXT                                  = 1000022000,
    VK_STRUCTURE_TYPE_DEBUG_MARKER_OBJECT_TAG_INFO_EXT                                   = 1000022001,
    VK_STRUCTURE_TYPE_DEBUG_MARKER_MARKER_INFO_EXT                                       = 1000022002,
    VK_STRUCTURE_TYPE_DEDICATED_ALLOCATION_IMAGE_CREATE_INFO_NV                          = 1000026000,
    VK_STRUCTURE_TYPE_DEDICATED_ALLOCATION_BUFFER_CREATE_INFO_NV                         = 1000026001,
    VK_STRUCTURE_TYPE_DEDICATED_ALLOCATION_MEMORY_ALLOCATE_INFO_NV                       = 1000026002,
    VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_TRANSFORM_FEEDBACK_FEATURES_EXT                    = 1000028000,
    VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_TRANSFORM_FEEDBACK_PROPERTIES_EXT                  = 1000028001,
    VK_STRUCTURE_TYPE_PIPELINE_RASTERIZATION_STATE_STREAM_CREATE_INFO_EXT                = 1000028002,
    VK_STRUCTURE_TYPE_IMAGE_VIEW_HANDLE_INFO_NVX                                         = 1000030000,
    VK_STRUCTURE_TYPE_TEXTURE_LOD_GATHER_FORMAT_PROPERTIES_AMD                           = 1000041000,
    VK_STRUCTURE_TYPE_STREAM_DESCRIPTOR_SURFACE_CREATE_INFO_GGP                          = 1000049000,
    VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_CORNER_SAMPLED_IMAGE_FEATURES_NV                   = 1000050000,
    VK_STRUCTURE_TYPE_EXTERNAL_MEMORY_IMAGE_CREATE_INFO_NV                               = 1000056000,
    VK_STRUCTURE_TYPE_EXPORT_MEMORY_ALLOCATE_INFO_NV                                     = 1000056001,
    VK_STRUCTURE_TYPE_IMPORT_MEMORY_WIN32_HANDLE_INFO_NV                                 = 1000057000,
    VK_STRUCTURE_TYPE_EXPORT_MEMORY_WIN32_HANDLE_INFO_NV                                 = 1000057001,
    VK_STRUCTURE_TYPE_WIN32_KEYED_MUTEX_ACQUIRE_RELEASE_INFO_NV                          = 1000058000,
    VK_STRUCTURE_TYPE_VALIDATION_FLAGS_EXT                                               = 1000061000,
    VK_STRUCTURE_TYPE_VI_SURFACE_CREATE_INFO_NN                                          = 1000062000,
    VK_STRUCTURE_TYPE_IMAGE_VIEW_ASTC_DECODE_MODE_EXT                                    = 1000067000,
    VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_ASTC_DECODE_FEATURES_EXT                           = 1000067001,
    VK_STRUCTURE_TYPE_IMPORT_MEMORY_WIN32_HANDLE_INFO_KHR                                = 1000073000,
    VK_STRUCTURE_TYPE_EXPORT_MEMORY_WIN32_HANDLE_INFO_KHR                                = 1000073001,
    VK_STRUCTURE_TYPE_MEMORY_WIN32_HANDLE_PROPERTIES_KHR                                 = 1000073002,
    VK_STRUCTURE_TYPE_MEMORY_GET_WIN32_HANDLE_INFO_KHR                                   = 1000073003,
    VK_STRUCTURE_TYPE_IMPORT_MEMORY_FD_INFO_KHR                                          = 1000074000,
    VK_STRUCTURE_TYPE_MEMORY_FD_PROPERTIES_KHR                                           = 1000074001,
    VK_STRUCTURE_TYPE_MEMORY_GET_FD_INFO_KHR                                             = 1000074002,
    VK_STRUCTURE_TYPE_WIN32_KEYED_MUTEX_ACQUIRE_RELEASE_INFO_KHR                         = 1000075000,
    VK_STRUCTURE_TYPE_IMPORT_SEMAPHORE_WIN32_HANDLE_INFO_KHR                             = 1000078000,
    VK_STRUCTURE_TYPE_EXPORT_SEMAPHORE_WIN32_HANDLE_INFO_KHR                             = 1000078001,
    VK_STRUCTURE_TYPE_D3D12_FENCE_SUBMIT_INFO_KHR                                        = 1000078002,
    VK_STRUCTURE_TYPE_SEMAPHORE_GET_WIN32_HANDLE_INFO_KHR                                = 1000078003,
    VK_STRUCTURE_TYPE_IMPORT_SEMAPHORE_FD_INFO_KHR                                       = 1000079000,
    VK_STRUCTURE_TYPE_SEMAPHORE_GET_FD_INFO_KHR                                          = 1000079001,
    VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_PUSH_DESCRIPTOR_PROPERTIES_KHR                     = 1000080000,
    VK_STRUCTURE_TYPE_COMMAND_BUFFER_INHERITANCE_CONDITIONAL_RENDERING_INFO_EXT          = 1000081000,
    VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_CONDITIONAL_RENDERING_FEATURES_EXT                 = 1000081001,
    VK_STRUCTURE_TYPE_CONDITIONAL_RENDERING_BEGIN_INFO_EXT                               = 1000081002,
    VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_FLOAT16_INT8_FEATURES_KHR                          = 1000082000,
    VK_STRUCTURE_TYPE_PRESENT_REGIONS_KHR                                                = 1000084000,
    VK_STRUCTURE_TYPE_OBJECT_TABLE_CREATE_INFO_NVX                                       = 1000086000,
    VK_STRUCTURE_TYPE_INDIRECT_COMMANDS_LAYOUT_CREATE_INFO_NVX                           = 1000086001,
    VK_STRUCTURE_TYPE_CMD_PROCESS_COMMANDS_INFO_NVX                                      = 1000086002,
    VK_STRUCTURE_TYPE_CMD_RESERVE_SPACE_FOR_COMMANDS_INFO_NVX                            = 1000086003,
    VK_STRUCTURE_TYPE_DEVICE_GENERATED_COMMANDS_LIMITS_NVX                               = 1000086004,
    VK_STRUCTURE_TYPE_DEVICE_GENERATED_COMMANDS_FEATURES_NVX                             = 1000086005,
    VK_STRUCTURE_TYPE_PIPELINE_VIEWPORT_W_SCALING_STATE_CREATE_INFO_NV                   = 1000087000,
    VK_STRUCTURE_TYPE_SURFACE_CAPABILITIES_2_EXT                                         = 1000090000,
    VK_STRUCTURE_TYPE_DISPLAY_POWER_INFO_EXT                                             = 1000091000,
    VK_STRUCTURE_TYPE_DEVICE_EVENT_INFO_EXT                                              = 1000091001,
    VK_STRUCTURE_TYPE_DISPLAY_EVENT_INFO_EXT                                             = 1000091002,
    VK_STRUCTURE_TYPE_SWAPCHAIN_COUNTER_CREATE_INFO_EXT                                  = 1000091003,
    VK_STRUCTURE_TYPE_PRESENT_TIMES_INFO_GOOGLE                                          = 1000092000,
    VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_MULTIVIEW_PER_VIEW_ATTRIBUTES_PROPERTIES_NVX       = 1000097000,
    VK_STRUCTURE_TYPE_PIPELINE_VIEWPORT_SWIZZLE_STATE_CREATE_INFO_NV                     = 1000098000,
    VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_DISCARD_RECTANGLE_PROPERTIES_EXT                   = 1000099000,
    VK_STRUCTURE_TYPE_PIPELINE_DISCARD_RECTANGLE_STATE_CREATE_INFO_EXT                   = 1000099001,
    VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_CONSERVATIVE_RASTERIZATION_PROPERTIES_EXT          = 1000101000,
    VK_STRUCTURE_TYPE_PIPELINE_RASTERIZATION_CONSERVATIVE_STATE_CREATE_INFO_EXT          = 1000101001,
    VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_DEPTH_CLIP_ENABLE_FEATURES_EXT                     = 1000102000,
    VK_STRUCTURE_TYPE_PIPELINE_RASTERIZATION_DEPTH_CLIP_STATE_CREATE_INFO_EXT            = 1000102001,
    VK_STRUCTURE_TYPE_HDR_METADATA_EXT                                                   = 1000105000,
    VK_STRUCTURE_TYPE_ATTACHMENT_DESCRIPTION_2_KHR                                       = 1000109000,
    VK_STRUCTURE_TYPE_ATTACHMENT_REFERENCE_2_KHR                                         = 1000109001,
    VK_STRUCTURE_TYPE_SUBPASS_DESCRIPTION_2_KHR                                          = 1000109002,
    VK_STRUCTURE_TYPE_SUBPASS_DEPENDENCY_2_KHR                                           = 1000109003,
    VK_STRUCTURE_TYPE_RENDER_PASS_CREATE_INFO_2_KHR                                      = 1000109004,
    VK_STRUCTURE_TYPE_SUBPASS_BEGIN_INFO_KHR                                             = 1000109005,
    VK_STRUCTURE_TYPE_SUBPASS_END_INFO_KHR                                               = 1000109006,
    VK_STRUCTURE_TYPE_SHARED_PRESENT_SURFACE_CAPABILITIES_KHR                            = 1000111000,
    VK_STRUCTURE_TYPE_IMPORT_FENCE_WIN32_HANDLE_INFO_KHR                                 = 1000114000,
    VK_STRUCTURE_TYPE_EXPORT_FENCE_WIN32_HANDLE_INFO_KHR                                 = 1000114001,
    VK_STRUCTURE_TYPE_FENCE_GET_WIN32_HANDLE_INFO_KHR                                    = 1000114002,
    VK_STRUCTURE_TYPE_IMPORT_FENCE_FD_INFO_KHR                                           = 1000115000,
    VK_STRUCTURE_TYPE_FENCE_GET_FD_INFO_KHR                                              = 1000115001,
    VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_SURFACE_INFO_2_KHR                                 = 1000119000,
    VK_STRUCTURE_TYPE_SURFACE_CAPABILITIES_2_KHR                                         = 1000119001,
    VK_STRUCTURE_TYPE_SURFACE_FORMAT_2_KHR                                               = 1000119002,
    VK_STRUCTURE_TYPE_DISPLAY_PROPERTIES_2_KHR                                           = 1000121000,
    VK_STRUCTURE_TYPE_DISPLAY_PLANE_PROPERTIES_2_KHR                                     = 1000121001,
    VK_STRUCTURE_TYPE_DISPLAY_MODE_PROPERTIES_2_KHR                                      = 1000121002,
    VK_STRUCTURE_TYPE_DISPLAY_PLANE_INFO_2_KHR                                           = 1000121003,
    VK_STRUCTURE_TYPE_DISPLAY_PLANE_CAPABILITIES_2_KHR                                   = 1000121004,
    VK_STRUCTURE_TYPE_IOS_SURFACE_CREATE_INFO_MVK                                        = 1000122000,
    VK_STRUCTURE_TYPE_MACOS_SURFACE_CREATE_INFO_MVK                                      = 1000123000,
    VK_STRUCTURE_TYPE_DEBUG_UTILS_OBJECT_NAME_INFO_EXT                                   = 1000128000,
    VK_STRUCTURE_TYPE_DEBUG_UTILS_OBJECT_TAG_INFO_EXT                                    = 1000128001,
    VK_STRUCTURE_TYPE_DEBUG_UTILS_LABEL_EXT                                              = 1000128002,
    VK_STRUCTURE_TYPE_DEBUG_UTILS_MESSENGER_CALLBACK_DATA_EXT                            = 1000128003,
    VK_STRUCTURE_TYPE_DEBUG_UTILS_MESSENGER_CREATE_INFO_EXT                              = 1000128004,
    VK_STRUCTURE_TYPE_ANDROID_HARDWARE_BUFFER_USAGE_ANDROID                              = 1000129000,
    VK_STRUCTURE_TYPE_ANDROID_HARDWARE_BUFFER_PROPERTIES_ANDROID                         = 1000129001,
    VK_STRUCTURE_TYPE_ANDROID_HARDWARE_BUFFER_FORMAT_PROPERTIES_ANDROID                  = 1000129002,
    VK_STRUCTURE_TYPE_IMPORT_ANDROID_HARDWARE_BUFFER_INFO_ANDROID                        = 1000129003,
    VK_STRUCTURE_TYPE_MEMORY_GET_ANDROID_HARDWARE_BUFFER_INFO_ANDROID                    = 1000129004,
    VK_STRUCTURE_TYPE_EXTERNAL_FORMAT_ANDROID                                            = 1000129005,
    VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_SAMPLER_FILTER_MINMAX_PROPERTIES_EXT               = 1000130000,
    VK_STRUCTURE_TYPE_SAMPLER_REDUCTION_MODE_CREATE_INFO_EXT                             = 1000130001,
    VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_INLINE_UNIFORM_BLOCK_FEATURES_EXT                  = 1000138000,
    VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_INLINE_UNIFORM_BLOCK_PROPERTIES_EXT                = 1000138001,
    VK_STRUCTURE_TYPE_WRITE_DESCRIPTOR_SET_INLINE_UNIFORM_BLOCK_EXT                      = 1000138002,
    VK_STRUCTURE_TYPE_DESCRIPTOR_POOL_INLINE_UNIFORM_BLOCK_CREATE_INFO_EXT               = 1000138003,
    VK_STRUCTURE_TYPE_SAMPLE_LOCATIONS_INFO_EXT                                          = 1000143000,
    VK_STRUCTURE_TYPE_RENDER_PASS_SAMPLE_LOCATIONS_BEGIN_INFO_EXT                        = 1000143001,
    VK_STRUCTURE_TYPE_PIPELINE_SAMPLE_LOCATIONS_STATE_CREATE_INFO_EXT                    = 1000143002,
    VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_SAMPLE_LOCATIONS_PROPERTIES_EXT                    = 1000143003,
    VK_STRUCTURE_TYPE_MULTISAMPLE_PROPERTIES_EXT                                         = 1000143004,
    VK_STRUCTURE_TYPE_IMAGE_FORMAT_LIST_CREATE_INFO_KHR                                  = 1000147000,
    VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_BLEND_OPERATION_ADVANCED_FEATURES_EXT              = 1000148000,
    VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_BLEND_OPERATION_ADVANCED_PROPERTIES_EXT            = 1000148001,
    VK_STRUCTURE_TYPE_PIPELINE_COLOR_BLEND_ADVANCED_STATE_CREATE_INFO_EXT                = 1000148002,
    VK_STRUCTURE_TYPE_PIPELINE_COVERAGE_TO_COLOR_STATE_CREATE_INFO_NV                    = 1000149000,
    VK_STRUCTURE_TYPE_PIPELINE_COVERAGE_MODULATION_STATE_CREATE_INFO_NV                  = 1000152000,
    VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_SHADER_SM_BUILTINS_FEATURES_NV                     = 1000154000,
    VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_SHADER_SM_BUILTINS_PROPERTIES_NV                   = 1000154001,
    VK_STRUCTURE_TYPE_DRM_FORMAT_MODIFIER_PROPERTIES_LIST_EXT                            = 1000158000,
    VK_STRUCTURE_TYPE_DRM_FORMAT_MODIFIER_PROPERTIES_EXT                                 = 1000158001,
    VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_IMAGE_DRM_FORMAT_MODIFIER_INFO_EXT                 = 1000158002,
    VK_STRUCTURE_TYPE_IMAGE_DRM_FORMAT_MODIFIER_LIST_CREATE_INFO_EXT                     = 1000158003,
    VK_STRUCTURE_TYPE_IMAGE_DRM_FORMAT_MODIFIER_EXPLICIT_CREATE_INFO_EXT                 = 1000158004,
    VK_STRUCTURE_TYPE_IMAGE_DRM_FORMAT_MODIFIER_PROPERTIES_EXT                           = 1000158005,
    VK_STRUCTURE_TYPE_VALIDATION_CACHE_CREATE_INFO_EXT                                   = 1000160000,
    VK_STRUCTURE_TYPE_SHADER_MODULE_VALIDATION_CACHE_CREATE_INFO_EXT                     = 1000160001,
    VK_STRUCTURE_TYPE_DESCRIPTOR_SET_LAYOUT_BINDING_FLAGS_CREATE_INFO_EXT                = 1000161000,
    VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_DESCRIPTOR_INDEXING_FEATURES_EXT                   = 1000161001,
    VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_DESCRIPTOR_INDEXING_PROPERTIES_EXT                 = 1000161002,
    VK_STRUCTURE_TYPE_DESCRIPTOR_SET_VARIABLE_DESCRIPTOR_COUNT_ALLOCATE_INFO_EXT         = 1000161003,
    VK_STRUCTURE_TYPE_DESCRIPTOR_SET_VARIABLE_DESCRIPTOR_COUNT_LAYOUT_SUPPORT_EXT        = 1000161004,
    VK_STRUCTURE_TYPE_PIPELINE_VIEWPORT_SHADING_RATE_IMAGE_STATE_CREATE_INFO_NV          = 1000164000,
    VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_SHADING_RATE_IMAGE_FEATURES_NV                     = 1000164001,
    VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_SHADING_RATE_IMAGE_PROPERTIES_NV                   = 1000164002,
    VK_STRUCTURE_TYPE_PIPELINE_VIEWPORT_COARSE_SAMPLE_ORDER_STATE_CREATE_INFO_NV         = 1000164005,
    VK_STRUCTURE_TYPE_RAY_TRACING_PIPELINE_CREATE_INFO_NV                                = 1000165000,
    VK_STRUCTURE_TYPE_ACCELERATION_STRUCTURE_CREATE_INFO_NV                              = 1000165001,
    VK_STRUCTURE_TYPE_GEOMETRY_NV                                                        = 1000165003,
    VK_STRUCTURE_TYPE_GEOMETRY_TRIANGLES_NV                                              = 1000165004,
    VK_STRUCTURE_TYPE_GEOMETRY_AABB_NV                                                   = 1000165005,
    VK_STRUCTURE_TYPE_BIND_ACCELERATION_STRUCTURE_MEMORY_INFO_NV                         = 1000165006,
    VK_STRUCTURE_TYPE_WRITE_DESCRIPTOR_SET_ACCELERATION_STRUCTURE_NV                     = 1000165007,
    VK_STRUCTURE_TYPE_ACCELERATION_STRUCTURE_MEMORY_REQUIREMENTS_INFO_NV                 = 1000165008,
    VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_RAY_TRACING_PROPERTIES_NV                          = 1000165009,
    VK_STRUCTURE_TYPE_RAY_TRACING_SHADER_GROUP_CREATE_INFO_NV                            = 1000165011,
    VK_STRUCTURE_TYPE_ACCELERATION_STRUCTURE_INFO_NV                                     = 1000165012,
    VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_REPRESENTATIVE_FRAGMENT_TEST_FEATURES_NV           = 1000166000,
    VK_STRUCTURE_TYPE_PIPELINE_REPRESENTATIVE_FRAGMENT_TEST_STATE_CREATE_INFO_NV         = 1000166001,
    VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_IMAGE_VIEW_IMAGE_FORMAT_INFO_EXT                   = 1000170000,
    VK_STRUCTURE_TYPE_FILTER_CUBIC_IMAGE_VIEW_IMAGE_FORMAT_PROPERTIES_EXT                = 1000170001,
    VK_STRUCTURE_TYPE_DEVICE_QUEUE_GLOBAL_PRIORITY_CREATE_INFO_EXT                       = 1000174000,
    VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_8BIT_STORAGE_FEATURES_KHR                          = 1000177000,
    VK_STRUCTURE_TYPE_IMPORT_MEMORY_HOST_POINTER_INFO_EXT                                = 1000178000,
    VK_STRUCTURE_TYPE_MEMORY_HOST_POINTER_PROPERTIES_EXT                                 = 1000178001,
    VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_EXTERNAL_MEMORY_HOST_PROPERTIES_EXT                = 1000178002,
    VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_SHADER_ATOMIC_INT64_FEATURES_KHR                   = 1000180000,
    VK_STRUCTURE_TYPE_CALIBRATED_TIMESTAMP_INFO_EXT                                      = 1000184000,
    VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_SHADER_CORE_PROPERTIES_AMD                         = 1000185000,
    VK_STRUCTURE_TYPE_DEVICE_MEMORY_OVERALLOCATION_CREATE_INFO_AMD                       = 1000189000,
    VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_VERTEX_ATTRIBUTE_DIVISOR_PROPERTIES_EXT            = 1000190000,
    VK_STRUCTURE_TYPE_PIPELINE_VERTEX_INPUT_DIVISOR_STATE_CREATE_INFO_EXT                = 1000190001,
    VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_VERTEX_ATTRIBUTE_DIVISOR_FEATURES_EXT              = 1000190002,
    VK_STRUCTURE_TYPE_PRESENT_FRAME_TOKEN_GGP                                            = 1000191000,
    VK_STRUCTURE_TYPE_PIPELINE_CREATION_FEEDBACK_CREATE_INFO_EXT                         = 1000192000,
    VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_DRIVER_PROPERTIES_KHR                              = 1000196000,
    VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_FLOAT_CONTROLS_PROPERTIES_KHR                      = 1000197000,
    VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_DEPTH_STENCIL_RESOLVE_PROPERTIES_KHR               = 1000199000,
    VK_STRUCTURE_TYPE_SUBPASS_DESCRIPTION_DEPTH_STENCIL_RESOLVE_KHR                      = 1000199001,
    VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_COMPUTE_SHADER_DERIVATIVES_FEATURES_NV             = 1000201000,
    VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_MESH_SHADER_FEATURES_NV                            = 1000202000,
    VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_MESH_SHADER_PROPERTIES_NV                          = 1000202001,
    VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_FRAGMENT_SHADER_BARYCENTRIC_FEATURES_NV            = 1000203000,
    VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_SHADER_IMAGE_FOOTPRINT_FEATURES_NV                 = 1000204000,
    VK_STRUCTURE_TYPE_PIPELINE_VIEWPORT_EXCLUSIVE_SCISSOR_STATE_CREATE_INFO_NV           = 1000205000,
    VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_EXCLUSIVE_SCISSOR_FEATURES_NV                      = 1000205002,
    VK_STRUCTURE_TYPE_CHECKPOINT_DATA_NV                                                 = 1000206000,
    VK_STRUCTURE_TYPE_QUEUE_FAMILY_CHECKPOINT_PROPERTIES_NV                              = 1000206001,
    VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_SHADER_INTEGER_FUNCTIONS2_FEATURES_INTEL           = 1000209000,
    VK_STRUCTURE_TYPE_QUERY_POOL_CREATE_INFO_INTEL                                       = 1000210000,
    VK_STRUCTURE_TYPE_INITIALIZE_PERFORMANCE_API_INFO_INTEL                              = 1000210001,
    VK_STRUCTURE_TYPE_PERFORMANCE_MARKER_INFO_INTEL                                      = 1000210002,
    VK_STRUCTURE_TYPE_PERFORMANCE_STREAM_MARKER_INFO_INTEL                               = 1000210003,
    VK_STRUCTURE_TYPE_PERFORMANCE_OVERRIDE_INFO_INTEL                                    = 1000210004,
    VK_STRUCTURE_TYPE_PERFORMANCE_CONFIGURATION_ACQUIRE_INFO_INTEL                       = 1000210005,
    VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_VULKAN_MEMORY_MODEL_FEATURES_KHR                   = 1000211000,
    VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_PCI_BUS_INFO_PROPERTIES_EXT                        = 1000212000,
    VK_STRUCTURE_TYPE_DISPLAY_NATIVE_HDR_SURFACE_CAPABILITIES_AMD                        = 1000213000,
    VK_STRUCTURE_TYPE_SWAPCHAIN_DISPLAY_NATIVE_HDR_CREATE_INFO_AMD                       = 1000213001,
    VK_STRUCTURE_TYPE_IMAGEPIPE_SURFACE_CREATE_INFO_FUCHSIA                              = 1000214000,
    VK_STRUCTURE_TYPE_METAL_SURFACE_CREATE_INFO_EXT                                      = 1000217000,
    VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_FRAGMENT_DENSITY_MAP_FEATURES_EXT                  = 1000218000,
    VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_FRAGMENT_DENSITY_MAP_PROPERTIES_EXT                = 1000218001,
    VK_STRUCTURE_TYPE_RENDER_PASS_FRAGMENT_DENSITY_MAP_CREATE_INFO_EXT                   = 1000218002,
    VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_SCALAR_BLOCK_LAYOUT_FEATURES_EXT                   = 1000221000,
    VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_MEMORY_BUDGET_PROPERTIES_EXT                       = 1000237000,
    VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_MEMORY_PRIORITY_FEATURES_EXT                       = 1000238000,
    VK_STRUCTURE_TYPE_MEMORY_PRIORITY_ALLOCATE_INFO_EXT                                  = 1000238001,
    VK_STRUCTURE_TYPE_SURFACE_PROTECTED_CAPABILITIES_KHR                                 = 1000239000,
    VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_DEDICATED_ALLOCATION_IMAGE_ALIASING_FEATURES_NV    = 1000240000,
    VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_BUFFER_DEVICE_ADDRESS_FEATURES_EXT                 = 1000244000,
    VK_STRUCTURE_TYPE_BUFFER_DEVICE_ADDRESS_INFO_EXT                                     = 1000244001,
    VK_STRUCTURE_TYPE_BUFFER_DEVICE_ADDRESS_CREATE_INFO_EXT                              = 1000244002,
    VK_STRUCTURE_TYPE_IMAGE_STENCIL_USAGE_CREATE_INFO_EXT                                = 1000246000,
    VK_STRUCTURE_TYPE_VALIDATION_FEATURES_EXT                                            = 1000247000,
    VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_COOPERATIVE_MATRIX_FEATURES_NV                     = 1000249000,
    VK_STRUCTURE_TYPE_COOPERATIVE_MATRIX_PROPERTIES_NV                                   = 1000249001,
    VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_COOPERATIVE_MATRIX_PROPERTIES_NV                   = 1000249002,
    VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_COVERAGE_REDUCTION_MODE_FEATURES_NV                = 1000250000,
    VK_STRUCTURE_TYPE_PIPELINE_COVERAGE_REDUCTION_STATE_CREATE_INFO_NV                   = 1000250001,
    VK_STRUCTURE_TYPE_FRAMEBUFFER_MIXED_SAMPLES_COMBINATION_NV                           = 1000250002,
    VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_FRAGMENT_SHADER_INTERLOCK_FEATURES_EXT             = 1000251000,
    VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_YCBCR_IMAGE_ARRAYS_FEATURES_EXT                    = 1000252000,
    VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_UNIFORM_BUFFER_STANDARD_LAYOUT_FEATURES_KHR        = 1000253000,
    VK_STRUCTURE_TYPE_SURFACE_FULL_SCREEN_EXCLUSIVE_INFO_EXT                             = 1000255000,
    VK_STRUCTURE_TYPE_SURFACE_CAPABILITIES_FULL_SCREEN_EXCLUSIVE_EXT                     = 1000255002,
    VK_STRUCTURE_TYPE_SURFACE_FULL_SCREEN_EXCLUSIVE_WIN32_INFO_EXT                       = 1000255001,
    VK_STRUCTURE_TYPE_HEADLESS_SURFACE_CREATE_INFO_EXT                                   = 1000256000,
    VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_HOST_QUERY_RESET_FEATURES_EXT                      = 1000261000,
    VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_VARIABLE_POINTER_FEATURES                          = VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_VARIABLE_POINTERS_FEATURES,
    VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_SHADER_DRAW_PARAMETER_FEATURES                     = VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_SHADER_DRAW_PARAMETERS_FEATURES,
    VK_STRUCTURE_TYPE_DEBUG_REPORT_CREATE_INFO_EXT                                       = VK_STRUCTURE_TYPE_DEBUG_REPORT_CALLBACK_CREATE_INFO_EXT,
    VK_STRUCTURE_TYPE_RENDER_PASS_MULTIVIEW_CREATE_INFO_KHR                              = VK_STRUCTURE_TYPE_RENDER_PASS_MULTIVIEW_CREATE_INFO,
    VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_MULTIVIEW_FEATURES_KHR                             = VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_MULTIVIEW_FEATURES,
    VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_MULTIVIEW_PROPERTIES_KHR                           = VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_MULTIVIEW_PROPERTIES,
    VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_FEATURES_2_KHR                                     = VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_FEATURES_2,
    VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_PROPERTIES_2_KHR                                   = VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_PROPERTIES_2,
    VK_STRUCTURE_TYPE_FORMAT_PROPERTIES_2_KHR                                            = VK_STRUCTURE_TYPE_FORMAT_PROPERTIES_2,
    VK_STRUCTURE_TYPE_IMAGE_FORMAT_PROPERTIES_2_KHR                                      = VK_STRUCTURE_TYPE_IMAGE_FORMAT_PROPERTIES_2,
    VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_IMAGE_FORMAT_INFO_2_KHR                            = VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_IMAGE_FORMAT_INFO_2,
    VK_STRUCTURE_TYPE_QUEUE_FAMILY_PROPERTIES_2_KHR                                      = VK_STRUCTURE_TYPE_QUEUE_FAMILY_PROPERTIES_2,
    VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_MEMORY_PROPERTIES_2_KHR                            = VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_MEMORY_PROPERTIES_2,
    VK_STRUCTURE_TYPE_SPARSE_IMAGE_FORMAT_PROPERTIES_2_KHR                               = VK_STRUCTURE_TYPE_SPARSE_IMAGE_FORMAT_PROPERTIES_2,
    VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_SPARSE_IMAGE_FORMAT_INFO_2_KHR                     = VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_SPARSE_IMAGE_FORMAT_INFO_2,
    VK_STRUCTURE_TYPE_MEMORY_ALLOCATE_FLAGS_INFO_KHR                                     = VK_STRUCTURE_TYPE_MEMORY_ALLOCATE_FLAGS_INFO,
    VK_STRUCTURE_TYPE_DEVICE_GROUP_RENDER_PASS_BEGIN_INFO_KHR                            = VK_STRUCTURE_TYPE_DEVICE_GROUP_RENDER_PASS_BEGIN_INFO,
    VK_STRUCTURE_TYPE_DEVICE_GROUP_COMMAND_BUFFER_BEGIN_INFO_KHR                         = VK_STRUCTURE_TYPE_DEVICE_GROUP_COMMAND_BUFFER_BEGIN_INFO,
    VK_STRUCTURE_TYPE_DEVICE_GROUP_SUBMIT_INFO_KHR                                       = VK_STRUCTURE_TYPE_DEVICE_GROUP_SUBMIT_INFO,
    VK_STRUCTURE_TYPE_DEVICE_GROUP_BIND_SPARSE_INFO_KHR                                  = VK_STRUCTURE_TYPE_DEVICE_GROUP_BIND_SPARSE_INFO,
    VK_STRUCTURE_TYPE_BIND_BUFFER_MEMORY_DEVICE_GROUP_INFO_KHR                           = VK_STRUCTURE_TYPE_BIND_BUFFER_MEMORY_DEVICE_GROUP_INFO,
    VK_STRUCTURE_TYPE_BIND_IMAGE_MEMORY_DEVICE_GROUP_INFO_KHR                            = VK_STRUCTURE_TYPE_BIND_IMAGE_MEMORY_DEVICE_GROUP_INFO,
    VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_GROUP_PROPERTIES_KHR                               = VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_GROUP_PROPERTIES,
    VK_STRUCTURE_TYPE_DEVICE_GROUP_DEVICE_CREATE_INFO_KHR                                = VK_STRUCTURE_TYPE_DEVICE_GROUP_DEVICE_CREATE_INFO,
    VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_EXTERNAL_IMAGE_FORMAT_INFO_KHR                     = VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_EXTERNAL_IMAGE_FORMAT_INFO,
    VK_STRUCTURE_TYPE_EXTERNAL_IMAGE_FORMAT_PROPERTIES_KHR                               = VK_STRUCTURE_TYPE_EXTERNAL_IMAGE_FORMAT_PROPERTIES,
    VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_EXTERNAL_BUFFER_INFO_KHR                           = VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_EXTERNAL_BUFFER_INFO,
    VK_STRUCTURE_TYPE_EXTERNAL_BUFFER_PROPERTIES_KHR                                     = VK_STRUCTURE_TYPE_EXTERNAL_BUFFER_PROPERTIES,
    VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_ID_PROPERTIES_KHR                                  = VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_ID_PROPERTIES,
    VK_STRUCTURE_TYPE_EXTERNAL_MEMORY_BUFFER_CREATE_INFO_KHR                             = VK_STRUCTURE_TYPE_EXTERNAL_MEMORY_BUFFER_CREATE_INFO,
    VK_STRUCTURE_TYPE_EXTERNAL_MEMORY_IMAGE_CREATE_INFO_KHR                              = VK_STRUCTURE_TYPE_EXTERNAL_MEMORY_IMAGE_CREATE_INFO,
    VK_STRUCTURE_TYPE_EXPORT_MEMORY_ALLOCATE_INFO_KHR                                    = VK_STRUCTURE_TYPE_EXPORT_MEMORY_ALLOCATE_INFO,
    VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_EXTERNAL_SEMAPHORE_INFO_KHR                        = VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_EXTERNAL_SEMAPHORE_INFO,
    VK_STRUCTURE_TYPE_EXTERNAL_SEMAPHORE_PROPERTIES_KHR                                  = VK_STRUCTURE_TYPE_EXTERNAL_SEMAPHORE_PROPERTIES,
    VK_STRUCTURE_TYPE_EXPORT_SEMAPHORE_CREATE_INFO_KHR                                   = VK_STRUCTURE_TYPE_EXPORT_SEMAPHORE_CREATE_INFO,
    VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_16BIT_STORAGE_FEATURES_KHR                         = VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_16BIT_STORAGE_FEATURES,
    VK_STRUCTURE_TYPE_DESCRIPTOR_UPDATE_TEMPLATE_CREATE_INFO_KHR                         = VK_STRUCTURE_TYPE_DESCRIPTOR_UPDATE_TEMPLATE_CREATE_INFO,
    VK_STRUCTURE_TYPE_SURFACE_CAPABILITIES2_EXT                                          = VK_STRUCTURE_TYPE_SURFACE_CAPABILITIES_2_EXT,
    VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_EXTERNAL_FENCE_INFO_KHR                            = VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_EXTERNAL_FENCE_INFO,
    VK_STRUCTURE_TYPE_EXTERNAL_FENCE_PROPERTIES_KHR                                      = VK_STRUCTURE_TYPE_EXTERNAL_FENCE_PROPERTIES,
    VK_STRUCTURE_TYPE_EXPORT_FENCE_CREATE_INFO_KHR                                       = VK_STRUCTURE_TYPE_EXPORT_FENCE_CREATE_INFO,
    VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_POINT_CLIPPING_PROPERTIES_KHR                      = VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_POINT_CLIPPING_PROPERTIES,
    VK_STRUCTURE_TYPE_RENDER_PASS_INPUT_ATTACHMENT_ASPECT_CREATE_INFO_KHR                = VK_STRUCTURE_TYPE_RENDER_PASS_INPUT_ATTACHMENT_ASPECT_CREATE_INFO,
    VK_STRUCTURE_TYPE_IMAGE_VIEW_USAGE_CREATE_INFO_KHR                                   = VK_STRUCTURE_TYPE_IMAGE_VIEW_USAGE_CREATE_INFO,
    VK_STRUCTURE_TYPE_PIPELINE_TESSELLATION_DOMAIN_ORIGIN_STATE_CREATE_INFO_KHR          = VK_STRUCTURE_TYPE_PIPELINE_TESSELLATION_DOMAIN_ORIGIN_STATE_CREATE_INFO,
    VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_VARIABLE_POINTER_FEATURES_KHR                      = VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_VARIABLE_POINTER_FEATURES,
    VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_VARIABLE_POINTERS_FEATURES_KHR                     = VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_VARIABLE_POINTER_FEATURES,
    VK_STRUCTURE_TYPE_MEMORY_DEDICATED_REQUIREMENTS_KHR                                  = VK_STRUCTURE_TYPE_MEMORY_DEDICATED_REQUIREMENTS,
    VK_STRUCTURE_TYPE_MEMORY_DEDICATED_ALLOCATE_INFO_KHR                                 = VK_STRUCTURE_TYPE_MEMORY_DEDICATED_ALLOCATE_INFO,
    VK_STRUCTURE_TYPE_BUFFER_MEMORY_REQUIREMENTS_INFO_2_KHR                              = VK_STRUCTURE_TYPE_BUFFER_MEMORY_REQUIREMENTS_INFO_2,
    VK_STRUCTURE_TYPE_IMAGE_MEMORY_REQUIREMENTS_INFO_2_KHR                               = VK_STRUCTURE_TYPE_IMAGE_MEMORY_REQUIREMENTS_INFO_2,
    VK_STRUCTURE_TYPE_IMAGE_SPARSE_MEMORY_REQUIREMENTS_INFO_2_KHR                        = VK_STRUCTURE_TYPE_IMAGE_SPARSE_MEMORY_REQUIREMENTS_INFO_2,
    VK_STRUCTURE_TYPE_MEMORY_REQUIREMENTS_2_KHR                                          = VK_STRUCTURE_TYPE_MEMORY_REQUIREMENTS_2,
    VK_STRUCTURE_TYPE_SPARSE_IMAGE_MEMORY_REQUIREMENTS_2_KHR                             = VK_STRUCTURE_TYPE_SPARSE_IMAGE_MEMORY_REQUIREMENTS_2,
    VK_STRUCTURE_TYPE_SAMPLER_YCBCR_CONVERSION_CREATE_INFO_KHR                           = VK_STRUCTURE_TYPE_SAMPLER_YCBCR_CONVERSION_CREATE_INFO,
    VK_STRUCTURE_TYPE_SAMPLER_YCBCR_CONVERSION_INFO_KHR                                  = VK_STRUCTURE_TYPE_SAMPLER_YCBCR_CONVERSION_INFO,
    VK_STRUCTURE_TYPE_BIND_IMAGE_PLANE_MEMORY_INFO_KHR                                   = VK_STRUCTURE_TYPE_BIND_IMAGE_PLANE_MEMORY_INFO,
    VK_STRUCTURE_TYPE_IMAGE_PLANE_MEMORY_REQUIREMENTS_INFO_KHR                           = VK_STRUCTURE_TYPE_IMAGE_PLANE_MEMORY_REQUIREMENTS_INFO,
    VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_SAMPLER_YCBCR_CONVERSION_FEATURES_KHR              = VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_SAMPLER_YCBCR_CONVERSION_FEATURES,
    VK_STRUCTURE_TYPE_SAMPLER_YCBCR_CONVERSION_IMAGE_FORMAT_PROPERTIES_KHR               = VK_STRUCTURE_TYPE_SAMPLER_YCBCR_CONVERSION_IMAGE_FORMAT_PROPERTIES,
    VK_STRUCTURE_TYPE_BIND_BUFFER_MEMORY_INFO_KHR                                        = VK_STRUCTURE_TYPE_BIND_BUFFER_MEMORY_INFO,
    VK_STRUCTURE_TYPE_BIND_IMAGE_MEMORY_INFO_KHR                                         = VK_STRUCTURE_TYPE_BIND_IMAGE_MEMORY_INFO,
    VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_MAINTENANCE_3_PROPERTIES_KHR                       = VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_MAINTENANCE_3_PROPERTIES,
    VK_STRUCTURE_TYPE_DESCRIPTOR_SET_LAYOUT_SUPPORT_KHR                                  = VK_STRUCTURE_TYPE_DESCRIPTOR_SET_LAYOUT_SUPPORT,
    VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_BUFFER_ADDRESS_FEATURES_EXT                        = VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_BUFFER_DEVICE_ADDRESS_FEATURES_EXT,
    VK_STRUCTURE_TYPE_BEGIN_RANGE                                                        = VK_STRUCTURE_TYPE_APPLICATION_INFO,
    VK_STRUCTURE_TYPE_END_RANGE                                                          = VK_STRUCTURE_TYPE_LOADER_DEVICE_CREATE_INFO,
    VK_STRUCTURE_TYPE_RANGE_SIZE                                                         = VK_STRUCTURE_TYPE_LOADER_DEVICE_CREATE_INFO - VK_STRUCTURE_TYPE_APPLICATION_INFO + 1,
    VK_STRUCTURE_TYPE_MAX_ENUM                                                           = 0x7FFFFFFF
}

enum VK_STRUCTURE_TYPE_APPLICATION_INFO                                                  = VkStructureType.VK_STRUCTURE_TYPE_APPLICATION_INFO;
enum VK_STRUCTURE_TYPE_INSTANCE_CREATE_INFO                                              = VkStructureType.VK_STRUCTURE_TYPE_INSTANCE_CREATE_INFO;
enum VK_STRUCTURE_TYPE_DEVICE_QUEUE_CREATE_INFO                                          = VkStructureType.VK_STRUCTURE_TYPE_DEVICE_QUEUE_CREATE_INFO;
enum VK_STRUCTURE_TYPE_DEVICE_CREATE_INFO                                                = VkStructureType.VK_STRUCTURE_TYPE_DEVICE_CREATE_INFO;
enum VK_STRUCTURE_TYPE_SUBMIT_INFO                                                       = VkStructureType.VK_STRUCTURE_TYPE_SUBMIT_INFO;
enum VK_STRUCTURE_TYPE_MEMORY_ALLOCATE_INFO                                              = VkStructureType.VK_STRUCTURE_TYPE_MEMORY_ALLOCATE_INFO;
enum VK_STRUCTURE_TYPE_MAPPED_MEMORY_RANGE                                               = VkStructureType.VK_STRUCTURE_TYPE_MAPPED_MEMORY_RANGE;
enum VK_STRUCTURE_TYPE_BIND_SPARSE_INFO                                                  = VkStructureType.VK_STRUCTURE_TYPE_BIND_SPARSE_INFO;
enum VK_STRUCTURE_TYPE_FENCE_CREATE_INFO                                                 = VkStructureType.VK_STRUCTURE_TYPE_FENCE_CREATE_INFO;
enum VK_STRUCTURE_TYPE_SEMAPHORE_CREATE_INFO                                             = VkStructureType.VK_STRUCTURE_TYPE_SEMAPHORE_CREATE_INFO;
enum VK_STRUCTURE_TYPE_EVENT_CREATE_INFO                                                 = VkStructureType.VK_STRUCTURE_TYPE_EVENT_CREATE_INFO;
enum VK_STRUCTURE_TYPE_QUERY_POOL_CREATE_INFO                                            = VkStructureType.VK_STRUCTURE_TYPE_QUERY_POOL_CREATE_INFO;
enum VK_STRUCTURE_TYPE_BUFFER_CREATE_INFO                                                = VkStructureType.VK_STRUCTURE_TYPE_BUFFER_CREATE_INFO;
enum VK_STRUCTURE_TYPE_BUFFER_VIEW_CREATE_INFO                                           = VkStructureType.VK_STRUCTURE_TYPE_BUFFER_VIEW_CREATE_INFO;
enum VK_STRUCTURE_TYPE_IMAGE_CREATE_INFO                                                 = VkStructureType.VK_STRUCTURE_TYPE_IMAGE_CREATE_INFO;
enum VK_STRUCTURE_TYPE_IMAGE_VIEW_CREATE_INFO                                            = VkStructureType.VK_STRUCTURE_TYPE_IMAGE_VIEW_CREATE_INFO;
enum VK_STRUCTURE_TYPE_SHADER_MODULE_CREATE_INFO                                         = VkStructureType.VK_STRUCTURE_TYPE_SHADER_MODULE_CREATE_INFO;
enum VK_STRUCTURE_TYPE_PIPELINE_CACHE_CREATE_INFO                                        = VkStructureType.VK_STRUCTURE_TYPE_PIPELINE_CACHE_CREATE_INFO;
enum VK_STRUCTURE_TYPE_PIPELINE_SHADER_STAGE_CREATE_INFO                                 = VkStructureType.VK_STRUCTURE_TYPE_PIPELINE_SHADER_STAGE_CREATE_INFO;
enum VK_STRUCTURE_TYPE_PIPELINE_VERTEX_INPUT_STATE_CREATE_INFO                           = VkStructureType.VK_STRUCTURE_TYPE_PIPELINE_VERTEX_INPUT_STATE_CREATE_INFO;
enum VK_STRUCTURE_TYPE_PIPELINE_INPUT_ASSEMBLY_STATE_CREATE_INFO                         = VkStructureType.VK_STRUCTURE_TYPE_PIPELINE_INPUT_ASSEMBLY_STATE_CREATE_INFO;
enum VK_STRUCTURE_TYPE_PIPELINE_TESSELLATION_STATE_CREATE_INFO                           = VkStructureType.VK_STRUCTURE_TYPE_PIPELINE_TESSELLATION_STATE_CREATE_INFO;
enum VK_STRUCTURE_TYPE_PIPELINE_VIEWPORT_STATE_CREATE_INFO                               = VkStructureType.VK_STRUCTURE_TYPE_PIPELINE_VIEWPORT_STATE_CREATE_INFO;
enum VK_STRUCTURE_TYPE_PIPELINE_RASTERIZATION_STATE_CREATE_INFO                          = VkStructureType.VK_STRUCTURE_TYPE_PIPELINE_RASTERIZATION_STATE_CREATE_INFO;
enum VK_STRUCTURE_TYPE_PIPELINE_MULTISAMPLE_STATE_CREATE_INFO                            = VkStructureType.VK_STRUCTURE_TYPE_PIPELINE_MULTISAMPLE_STATE_CREATE_INFO;
enum VK_STRUCTURE_TYPE_PIPELINE_DEPTH_STENCIL_STATE_CREATE_INFO                          = VkStructureType.VK_STRUCTURE_TYPE_PIPELINE_DEPTH_STENCIL_STATE_CREATE_INFO;
enum VK_STRUCTURE_TYPE_PIPELINE_COLOR_BLEND_STATE_CREATE_INFO                            = VkStructureType.VK_STRUCTURE_TYPE_PIPELINE_COLOR_BLEND_STATE_CREATE_INFO;
enum VK_STRUCTURE_TYPE_PIPELINE_DYNAMIC_STATE_CREATE_INFO                                = VkStructureType.VK_STRUCTURE_TYPE_PIPELINE_DYNAMIC_STATE_CREATE_INFO;
enum VK_STRUCTURE_TYPE_GRAPHICS_PIPELINE_CREATE_INFO                                     = VkStructureType.VK_STRUCTURE_TYPE_GRAPHICS_PIPELINE_CREATE_INFO;
enum VK_STRUCTURE_TYPE_COMPUTE_PIPELINE_CREATE_INFO                                      = VkStructureType.VK_STRUCTURE_TYPE_COMPUTE_PIPELINE_CREATE_INFO;
enum VK_STRUCTURE_TYPE_PIPELINE_LAYOUT_CREATE_INFO                                       = VkStructureType.VK_STRUCTURE_TYPE_PIPELINE_LAYOUT_CREATE_INFO;
enum VK_STRUCTURE_TYPE_SAMPLER_CREATE_INFO                                               = VkStructureType.VK_STRUCTURE_TYPE_SAMPLER_CREATE_INFO;
enum VK_STRUCTURE_TYPE_DESCRIPTOR_SET_LAYOUT_CREATE_INFO                                 = VkStructureType.VK_STRUCTURE_TYPE_DESCRIPTOR_SET_LAYOUT_CREATE_INFO;
enum VK_STRUCTURE_TYPE_DESCRIPTOR_POOL_CREATE_INFO                                       = VkStructureType.VK_STRUCTURE_TYPE_DESCRIPTOR_POOL_CREATE_INFO;
enum VK_STRUCTURE_TYPE_DESCRIPTOR_SET_ALLOCATE_INFO                                      = VkStructureType.VK_STRUCTURE_TYPE_DESCRIPTOR_SET_ALLOCATE_INFO;
enum VK_STRUCTURE_TYPE_WRITE_DESCRIPTOR_SET                                              = VkStructureType.VK_STRUCTURE_TYPE_WRITE_DESCRIPTOR_SET;
enum VK_STRUCTURE_TYPE_COPY_DESCRIPTOR_SET                                               = VkStructureType.VK_STRUCTURE_TYPE_COPY_DESCRIPTOR_SET;
enum VK_STRUCTURE_TYPE_FRAMEBUFFER_CREATE_INFO                                           = VkStructureType.VK_STRUCTURE_TYPE_FRAMEBUFFER_CREATE_INFO;
enum VK_STRUCTURE_TYPE_RENDER_PASS_CREATE_INFO                                           = VkStructureType.VK_STRUCTURE_TYPE_RENDER_PASS_CREATE_INFO;
enum VK_STRUCTURE_TYPE_COMMAND_POOL_CREATE_INFO                                          = VkStructureType.VK_STRUCTURE_TYPE_COMMAND_POOL_CREATE_INFO;
enum VK_STRUCTURE_TYPE_COMMAND_BUFFER_ALLOCATE_INFO                                      = VkStructureType.VK_STRUCTURE_TYPE_COMMAND_BUFFER_ALLOCATE_INFO;
enum VK_STRUCTURE_TYPE_COMMAND_BUFFER_INHERITANCE_INFO                                   = VkStructureType.VK_STRUCTURE_TYPE_COMMAND_BUFFER_INHERITANCE_INFO;
enum VK_STRUCTURE_TYPE_COMMAND_BUFFER_BEGIN_INFO                                         = VkStructureType.VK_STRUCTURE_TYPE_COMMAND_BUFFER_BEGIN_INFO;
enum VK_STRUCTURE_TYPE_RENDER_PASS_BEGIN_INFO                                            = VkStructureType.VK_STRUCTURE_TYPE_RENDER_PASS_BEGIN_INFO;
enum VK_STRUCTURE_TYPE_BUFFER_MEMORY_BARRIER                                             = VkStructureType.VK_STRUCTURE_TYPE_BUFFER_MEMORY_BARRIER;
enum VK_STRUCTURE_TYPE_IMAGE_MEMORY_BARRIER                                              = VkStructureType.VK_STRUCTURE_TYPE_IMAGE_MEMORY_BARRIER;
enum VK_STRUCTURE_TYPE_MEMORY_BARRIER                                                    = VkStructureType.VK_STRUCTURE_TYPE_MEMORY_BARRIER;
enum VK_STRUCTURE_TYPE_LOADER_INSTANCE_CREATE_INFO                                       = VkStructureType.VK_STRUCTURE_TYPE_LOADER_INSTANCE_CREATE_INFO;
enum VK_STRUCTURE_TYPE_LOADER_DEVICE_CREATE_INFO                                         = VkStructureType.VK_STRUCTURE_TYPE_LOADER_DEVICE_CREATE_INFO;
enum VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_SUBGROUP_PROPERTIES                               = VkStructureType.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_SUBGROUP_PROPERTIES;
enum VK_STRUCTURE_TYPE_BIND_BUFFER_MEMORY_INFO                                           = VkStructureType.VK_STRUCTURE_TYPE_BIND_BUFFER_MEMORY_INFO;
enum VK_STRUCTURE_TYPE_BIND_IMAGE_MEMORY_INFO                                            = VkStructureType.VK_STRUCTURE_TYPE_BIND_IMAGE_MEMORY_INFO;
enum VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_16BIT_STORAGE_FEATURES                            = VkStructureType.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_16BIT_STORAGE_FEATURES;
enum VK_STRUCTURE_TYPE_MEMORY_DEDICATED_REQUIREMENTS                                     = VkStructureType.VK_STRUCTURE_TYPE_MEMORY_DEDICATED_REQUIREMENTS;
enum VK_STRUCTURE_TYPE_MEMORY_DEDICATED_ALLOCATE_INFO                                    = VkStructureType.VK_STRUCTURE_TYPE_MEMORY_DEDICATED_ALLOCATE_INFO;
enum VK_STRUCTURE_TYPE_MEMORY_ALLOCATE_FLAGS_INFO                                        = VkStructureType.VK_STRUCTURE_TYPE_MEMORY_ALLOCATE_FLAGS_INFO;
enum VK_STRUCTURE_TYPE_DEVICE_GROUP_RENDER_PASS_BEGIN_INFO                               = VkStructureType.VK_STRUCTURE_TYPE_DEVICE_GROUP_RENDER_PASS_BEGIN_INFO;
enum VK_STRUCTURE_TYPE_DEVICE_GROUP_COMMAND_BUFFER_BEGIN_INFO                            = VkStructureType.VK_STRUCTURE_TYPE_DEVICE_GROUP_COMMAND_BUFFER_BEGIN_INFO;
enum VK_STRUCTURE_TYPE_DEVICE_GROUP_SUBMIT_INFO                                          = VkStructureType.VK_STRUCTURE_TYPE_DEVICE_GROUP_SUBMIT_INFO;
enum VK_STRUCTURE_TYPE_DEVICE_GROUP_BIND_SPARSE_INFO                                     = VkStructureType.VK_STRUCTURE_TYPE_DEVICE_GROUP_BIND_SPARSE_INFO;
enum VK_STRUCTURE_TYPE_BIND_BUFFER_MEMORY_DEVICE_GROUP_INFO                              = VkStructureType.VK_STRUCTURE_TYPE_BIND_BUFFER_MEMORY_DEVICE_GROUP_INFO;
enum VK_STRUCTURE_TYPE_BIND_IMAGE_MEMORY_DEVICE_GROUP_INFO                               = VkStructureType.VK_STRUCTURE_TYPE_BIND_IMAGE_MEMORY_DEVICE_GROUP_INFO;
enum VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_GROUP_PROPERTIES                                  = VkStructureType.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_GROUP_PROPERTIES;
enum VK_STRUCTURE_TYPE_DEVICE_GROUP_DEVICE_CREATE_INFO                                   = VkStructureType.VK_STRUCTURE_TYPE_DEVICE_GROUP_DEVICE_CREATE_INFO;
enum VK_STRUCTURE_TYPE_BUFFER_MEMORY_REQUIREMENTS_INFO_2                                 = VkStructureType.VK_STRUCTURE_TYPE_BUFFER_MEMORY_REQUIREMENTS_INFO_2;
enum VK_STRUCTURE_TYPE_IMAGE_MEMORY_REQUIREMENTS_INFO_2                                  = VkStructureType.VK_STRUCTURE_TYPE_IMAGE_MEMORY_REQUIREMENTS_INFO_2;
enum VK_STRUCTURE_TYPE_IMAGE_SPARSE_MEMORY_REQUIREMENTS_INFO_2                           = VkStructureType.VK_STRUCTURE_TYPE_IMAGE_SPARSE_MEMORY_REQUIREMENTS_INFO_2;
enum VK_STRUCTURE_TYPE_MEMORY_REQUIREMENTS_2                                             = VkStructureType.VK_STRUCTURE_TYPE_MEMORY_REQUIREMENTS_2;
enum VK_STRUCTURE_TYPE_SPARSE_IMAGE_MEMORY_REQUIREMENTS_2                                = VkStructureType.VK_STRUCTURE_TYPE_SPARSE_IMAGE_MEMORY_REQUIREMENTS_2;
enum VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_FEATURES_2                                        = VkStructureType.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_FEATURES_2;
enum VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_PROPERTIES_2                                      = VkStructureType.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_PROPERTIES_2;
enum VK_STRUCTURE_TYPE_FORMAT_PROPERTIES_2                                               = VkStructureType.VK_STRUCTURE_TYPE_FORMAT_PROPERTIES_2;
enum VK_STRUCTURE_TYPE_IMAGE_FORMAT_PROPERTIES_2                                         = VkStructureType.VK_STRUCTURE_TYPE_IMAGE_FORMAT_PROPERTIES_2;
enum VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_IMAGE_FORMAT_INFO_2                               = VkStructureType.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_IMAGE_FORMAT_INFO_2;
enum VK_STRUCTURE_TYPE_QUEUE_FAMILY_PROPERTIES_2                                         = VkStructureType.VK_STRUCTURE_TYPE_QUEUE_FAMILY_PROPERTIES_2;
enum VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_MEMORY_PROPERTIES_2                               = VkStructureType.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_MEMORY_PROPERTIES_2;
enum VK_STRUCTURE_TYPE_SPARSE_IMAGE_FORMAT_PROPERTIES_2                                  = VkStructureType.VK_STRUCTURE_TYPE_SPARSE_IMAGE_FORMAT_PROPERTIES_2;
enum VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_SPARSE_IMAGE_FORMAT_INFO_2                        = VkStructureType.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_SPARSE_IMAGE_FORMAT_INFO_2;
enum VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_POINT_CLIPPING_PROPERTIES                         = VkStructureType.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_POINT_CLIPPING_PROPERTIES;
enum VK_STRUCTURE_TYPE_RENDER_PASS_INPUT_ATTACHMENT_ASPECT_CREATE_INFO                   = VkStructureType.VK_STRUCTURE_TYPE_RENDER_PASS_INPUT_ATTACHMENT_ASPECT_CREATE_INFO;
enum VK_STRUCTURE_TYPE_IMAGE_VIEW_USAGE_CREATE_INFO                                      = VkStructureType.VK_STRUCTURE_TYPE_IMAGE_VIEW_USAGE_CREATE_INFO;
enum VK_STRUCTURE_TYPE_PIPELINE_TESSELLATION_DOMAIN_ORIGIN_STATE_CREATE_INFO             = VkStructureType.VK_STRUCTURE_TYPE_PIPELINE_TESSELLATION_DOMAIN_ORIGIN_STATE_CREATE_INFO;
enum VK_STRUCTURE_TYPE_RENDER_PASS_MULTIVIEW_CREATE_INFO                                 = VkStructureType.VK_STRUCTURE_TYPE_RENDER_PASS_MULTIVIEW_CREATE_INFO;
enum VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_MULTIVIEW_FEATURES                                = VkStructureType.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_MULTIVIEW_FEATURES;
enum VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_MULTIVIEW_PROPERTIES                              = VkStructureType.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_MULTIVIEW_PROPERTIES;
enum VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_VARIABLE_POINTERS_FEATURES                        = VkStructureType.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_VARIABLE_POINTERS_FEATURES;
enum VK_STRUCTURE_TYPE_PROTECTED_SUBMIT_INFO                                             = VkStructureType.VK_STRUCTURE_TYPE_PROTECTED_SUBMIT_INFO;
enum VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_PROTECTED_MEMORY_FEATURES                         = VkStructureType.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_PROTECTED_MEMORY_FEATURES;
enum VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_PROTECTED_MEMORY_PROPERTIES                       = VkStructureType.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_PROTECTED_MEMORY_PROPERTIES;
enum VK_STRUCTURE_TYPE_DEVICE_QUEUE_INFO_2                                               = VkStructureType.VK_STRUCTURE_TYPE_DEVICE_QUEUE_INFO_2;
enum VK_STRUCTURE_TYPE_SAMPLER_YCBCR_CONVERSION_CREATE_INFO                              = VkStructureType.VK_STRUCTURE_TYPE_SAMPLER_YCBCR_CONVERSION_CREATE_INFO;
enum VK_STRUCTURE_TYPE_SAMPLER_YCBCR_CONVERSION_INFO                                     = VkStructureType.VK_STRUCTURE_TYPE_SAMPLER_YCBCR_CONVERSION_INFO;
enum VK_STRUCTURE_TYPE_BIND_IMAGE_PLANE_MEMORY_INFO                                      = VkStructureType.VK_STRUCTURE_TYPE_BIND_IMAGE_PLANE_MEMORY_INFO;
enum VK_STRUCTURE_TYPE_IMAGE_PLANE_MEMORY_REQUIREMENTS_INFO                              = VkStructureType.VK_STRUCTURE_TYPE_IMAGE_PLANE_MEMORY_REQUIREMENTS_INFO;
enum VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_SAMPLER_YCBCR_CONVERSION_FEATURES                 = VkStructureType.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_SAMPLER_YCBCR_CONVERSION_FEATURES;
enum VK_STRUCTURE_TYPE_SAMPLER_YCBCR_CONVERSION_IMAGE_FORMAT_PROPERTIES                  = VkStructureType.VK_STRUCTURE_TYPE_SAMPLER_YCBCR_CONVERSION_IMAGE_FORMAT_PROPERTIES;
enum VK_STRUCTURE_TYPE_DESCRIPTOR_UPDATE_TEMPLATE_CREATE_INFO                            = VkStructureType.VK_STRUCTURE_TYPE_DESCRIPTOR_UPDATE_TEMPLATE_CREATE_INFO;
enum VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_EXTERNAL_IMAGE_FORMAT_INFO                        = VkStructureType.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_EXTERNAL_IMAGE_FORMAT_INFO;
enum VK_STRUCTURE_TYPE_EXTERNAL_IMAGE_FORMAT_PROPERTIES                                  = VkStructureType.VK_STRUCTURE_TYPE_EXTERNAL_IMAGE_FORMAT_PROPERTIES;
enum VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_EXTERNAL_BUFFER_INFO                              = VkStructureType.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_EXTERNAL_BUFFER_INFO;
enum VK_STRUCTURE_TYPE_EXTERNAL_BUFFER_PROPERTIES                                        = VkStructureType.VK_STRUCTURE_TYPE_EXTERNAL_BUFFER_PROPERTIES;
enum VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_ID_PROPERTIES                                     = VkStructureType.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_ID_PROPERTIES;
enum VK_STRUCTURE_TYPE_EXTERNAL_MEMORY_BUFFER_CREATE_INFO                                = VkStructureType.VK_STRUCTURE_TYPE_EXTERNAL_MEMORY_BUFFER_CREATE_INFO;
enum VK_STRUCTURE_TYPE_EXTERNAL_MEMORY_IMAGE_CREATE_INFO                                 = VkStructureType.VK_STRUCTURE_TYPE_EXTERNAL_MEMORY_IMAGE_CREATE_INFO;
enum VK_STRUCTURE_TYPE_EXPORT_MEMORY_ALLOCATE_INFO                                       = VkStructureType.VK_STRUCTURE_TYPE_EXPORT_MEMORY_ALLOCATE_INFO;
enum VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_EXTERNAL_FENCE_INFO                               = VkStructureType.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_EXTERNAL_FENCE_INFO;
enum VK_STRUCTURE_TYPE_EXTERNAL_FENCE_PROPERTIES                                         = VkStructureType.VK_STRUCTURE_TYPE_EXTERNAL_FENCE_PROPERTIES;
enum VK_STRUCTURE_TYPE_EXPORT_FENCE_CREATE_INFO                                          = VkStructureType.VK_STRUCTURE_TYPE_EXPORT_FENCE_CREATE_INFO;
enum VK_STRUCTURE_TYPE_EXPORT_SEMAPHORE_CREATE_INFO                                      = VkStructureType.VK_STRUCTURE_TYPE_EXPORT_SEMAPHORE_CREATE_INFO;
enum VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_EXTERNAL_SEMAPHORE_INFO                           = VkStructureType.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_EXTERNAL_SEMAPHORE_INFO;
enum VK_STRUCTURE_TYPE_EXTERNAL_SEMAPHORE_PROPERTIES                                     = VkStructureType.VK_STRUCTURE_TYPE_EXTERNAL_SEMAPHORE_PROPERTIES;
enum VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_MAINTENANCE_3_PROPERTIES                          = VkStructureType.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_MAINTENANCE_3_PROPERTIES;
enum VK_STRUCTURE_TYPE_DESCRIPTOR_SET_LAYOUT_SUPPORT                                     = VkStructureType.VK_STRUCTURE_TYPE_DESCRIPTOR_SET_LAYOUT_SUPPORT;
enum VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_SHADER_DRAW_PARAMETERS_FEATURES                   = VkStructureType.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_SHADER_DRAW_PARAMETERS_FEATURES;
enum VK_STRUCTURE_TYPE_SWAPCHAIN_CREATE_INFO_KHR                                         = VkStructureType.VK_STRUCTURE_TYPE_SWAPCHAIN_CREATE_INFO_KHR;
enum VK_STRUCTURE_TYPE_PRESENT_INFO_KHR                                                  = VkStructureType.VK_STRUCTURE_TYPE_PRESENT_INFO_KHR;
enum VK_STRUCTURE_TYPE_DEVICE_GROUP_PRESENT_CAPABILITIES_KHR                             = VkStructureType.VK_STRUCTURE_TYPE_DEVICE_GROUP_PRESENT_CAPABILITIES_KHR;
enum VK_STRUCTURE_TYPE_IMAGE_SWAPCHAIN_CREATE_INFO_KHR                                   = VkStructureType.VK_STRUCTURE_TYPE_IMAGE_SWAPCHAIN_CREATE_INFO_KHR;
enum VK_STRUCTURE_TYPE_BIND_IMAGE_MEMORY_SWAPCHAIN_INFO_KHR                              = VkStructureType.VK_STRUCTURE_TYPE_BIND_IMAGE_MEMORY_SWAPCHAIN_INFO_KHR;
enum VK_STRUCTURE_TYPE_ACQUIRE_NEXT_IMAGE_INFO_KHR                                       = VkStructureType.VK_STRUCTURE_TYPE_ACQUIRE_NEXT_IMAGE_INFO_KHR;
enum VK_STRUCTURE_TYPE_DEVICE_GROUP_PRESENT_INFO_KHR                                     = VkStructureType.VK_STRUCTURE_TYPE_DEVICE_GROUP_PRESENT_INFO_KHR;
enum VK_STRUCTURE_TYPE_DEVICE_GROUP_SWAPCHAIN_CREATE_INFO_KHR                            = VkStructureType.VK_STRUCTURE_TYPE_DEVICE_GROUP_SWAPCHAIN_CREATE_INFO_KHR;
enum VK_STRUCTURE_TYPE_DISPLAY_MODE_CREATE_INFO_KHR                                      = VkStructureType.VK_STRUCTURE_TYPE_DISPLAY_MODE_CREATE_INFO_KHR;
enum VK_STRUCTURE_TYPE_DISPLAY_SURFACE_CREATE_INFO_KHR                                   = VkStructureType.VK_STRUCTURE_TYPE_DISPLAY_SURFACE_CREATE_INFO_KHR;
enum VK_STRUCTURE_TYPE_DISPLAY_PRESENT_INFO_KHR                                          = VkStructureType.VK_STRUCTURE_TYPE_DISPLAY_PRESENT_INFO_KHR;
enum VK_STRUCTURE_TYPE_XLIB_SURFACE_CREATE_INFO_KHR                                      = VkStructureType.VK_STRUCTURE_TYPE_XLIB_SURFACE_CREATE_INFO_KHR;
enum VK_STRUCTURE_TYPE_XCB_SURFACE_CREATE_INFO_KHR                                       = VkStructureType.VK_STRUCTURE_TYPE_XCB_SURFACE_CREATE_INFO_KHR;
enum VK_STRUCTURE_TYPE_WAYLAND_SURFACE_CREATE_INFO_KHR                                   = VkStructureType.VK_STRUCTURE_TYPE_WAYLAND_SURFACE_CREATE_INFO_KHR;
enum VK_STRUCTURE_TYPE_ANDROID_SURFACE_CREATE_INFO_KHR                                   = VkStructureType.VK_STRUCTURE_TYPE_ANDROID_SURFACE_CREATE_INFO_KHR;
enum VK_STRUCTURE_TYPE_WIN32_SURFACE_CREATE_INFO_KHR                                     = VkStructureType.VK_STRUCTURE_TYPE_WIN32_SURFACE_CREATE_INFO_KHR;
enum VK_STRUCTURE_TYPE_DEBUG_REPORT_CALLBACK_CREATE_INFO_EXT                             = VkStructureType.VK_STRUCTURE_TYPE_DEBUG_REPORT_CALLBACK_CREATE_INFO_EXT;
enum VK_STRUCTURE_TYPE_PIPELINE_RASTERIZATION_STATE_RASTERIZATION_ORDER_AMD              = VkStructureType.VK_STRUCTURE_TYPE_PIPELINE_RASTERIZATION_STATE_RASTERIZATION_ORDER_AMD;
enum VK_STRUCTURE_TYPE_DEBUG_MARKER_OBJECT_NAME_INFO_EXT                                 = VkStructureType.VK_STRUCTURE_TYPE_DEBUG_MARKER_OBJECT_NAME_INFO_EXT;
enum VK_STRUCTURE_TYPE_DEBUG_MARKER_OBJECT_TAG_INFO_EXT                                  = VkStructureType.VK_STRUCTURE_TYPE_DEBUG_MARKER_OBJECT_TAG_INFO_EXT;
enum VK_STRUCTURE_TYPE_DEBUG_MARKER_MARKER_INFO_EXT                                      = VkStructureType.VK_STRUCTURE_TYPE_DEBUG_MARKER_MARKER_INFO_EXT;
enum VK_STRUCTURE_TYPE_DEDICATED_ALLOCATION_IMAGE_CREATE_INFO_NV                         = VkStructureType.VK_STRUCTURE_TYPE_DEDICATED_ALLOCATION_IMAGE_CREATE_INFO_NV;
enum VK_STRUCTURE_TYPE_DEDICATED_ALLOCATION_BUFFER_CREATE_INFO_NV                        = VkStructureType.VK_STRUCTURE_TYPE_DEDICATED_ALLOCATION_BUFFER_CREATE_INFO_NV;
enum VK_STRUCTURE_TYPE_DEDICATED_ALLOCATION_MEMORY_ALLOCATE_INFO_NV                      = VkStructureType.VK_STRUCTURE_TYPE_DEDICATED_ALLOCATION_MEMORY_ALLOCATE_INFO_NV;
enum VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_TRANSFORM_FEEDBACK_FEATURES_EXT                   = VkStructureType.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_TRANSFORM_FEEDBACK_FEATURES_EXT;
enum VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_TRANSFORM_FEEDBACK_PROPERTIES_EXT                 = VkStructureType.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_TRANSFORM_FEEDBACK_PROPERTIES_EXT;
enum VK_STRUCTURE_TYPE_PIPELINE_RASTERIZATION_STATE_STREAM_CREATE_INFO_EXT               = VkStructureType.VK_STRUCTURE_TYPE_PIPELINE_RASTERIZATION_STATE_STREAM_CREATE_INFO_EXT;
enum VK_STRUCTURE_TYPE_IMAGE_VIEW_HANDLE_INFO_NVX                                        = VkStructureType.VK_STRUCTURE_TYPE_IMAGE_VIEW_HANDLE_INFO_NVX;
enum VK_STRUCTURE_TYPE_TEXTURE_LOD_GATHER_FORMAT_PROPERTIES_AMD                          = VkStructureType.VK_STRUCTURE_TYPE_TEXTURE_LOD_GATHER_FORMAT_PROPERTIES_AMD;
enum VK_STRUCTURE_TYPE_STREAM_DESCRIPTOR_SURFACE_CREATE_INFO_GGP                         = VkStructureType.VK_STRUCTURE_TYPE_STREAM_DESCRIPTOR_SURFACE_CREATE_INFO_GGP;
enum VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_CORNER_SAMPLED_IMAGE_FEATURES_NV                  = VkStructureType.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_CORNER_SAMPLED_IMAGE_FEATURES_NV;
enum VK_STRUCTURE_TYPE_EXTERNAL_MEMORY_IMAGE_CREATE_INFO_NV                              = VkStructureType.VK_STRUCTURE_TYPE_EXTERNAL_MEMORY_IMAGE_CREATE_INFO_NV;
enum VK_STRUCTURE_TYPE_EXPORT_MEMORY_ALLOCATE_INFO_NV                                    = VkStructureType.VK_STRUCTURE_TYPE_EXPORT_MEMORY_ALLOCATE_INFO_NV;
enum VK_STRUCTURE_TYPE_IMPORT_MEMORY_WIN32_HANDLE_INFO_NV                                = VkStructureType.VK_STRUCTURE_TYPE_IMPORT_MEMORY_WIN32_HANDLE_INFO_NV;
enum VK_STRUCTURE_TYPE_EXPORT_MEMORY_WIN32_HANDLE_INFO_NV                                = VkStructureType.VK_STRUCTURE_TYPE_EXPORT_MEMORY_WIN32_HANDLE_INFO_NV;
enum VK_STRUCTURE_TYPE_WIN32_KEYED_MUTEX_ACQUIRE_RELEASE_INFO_NV                         = VkStructureType.VK_STRUCTURE_TYPE_WIN32_KEYED_MUTEX_ACQUIRE_RELEASE_INFO_NV;
enum VK_STRUCTURE_TYPE_VALIDATION_FLAGS_EXT                                              = VkStructureType.VK_STRUCTURE_TYPE_VALIDATION_FLAGS_EXT;
enum VK_STRUCTURE_TYPE_VI_SURFACE_CREATE_INFO_NN                                         = VkStructureType.VK_STRUCTURE_TYPE_VI_SURFACE_CREATE_INFO_NN;
enum VK_STRUCTURE_TYPE_IMAGE_VIEW_ASTC_DECODE_MODE_EXT                                   = VkStructureType.VK_STRUCTURE_TYPE_IMAGE_VIEW_ASTC_DECODE_MODE_EXT;
enum VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_ASTC_DECODE_FEATURES_EXT                          = VkStructureType.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_ASTC_DECODE_FEATURES_EXT;
enum VK_STRUCTURE_TYPE_IMPORT_MEMORY_WIN32_HANDLE_INFO_KHR                               = VkStructureType.VK_STRUCTURE_TYPE_IMPORT_MEMORY_WIN32_HANDLE_INFO_KHR;
enum VK_STRUCTURE_TYPE_EXPORT_MEMORY_WIN32_HANDLE_INFO_KHR                               = VkStructureType.VK_STRUCTURE_TYPE_EXPORT_MEMORY_WIN32_HANDLE_INFO_KHR;
enum VK_STRUCTURE_TYPE_MEMORY_WIN32_HANDLE_PROPERTIES_KHR                                = VkStructureType.VK_STRUCTURE_TYPE_MEMORY_WIN32_HANDLE_PROPERTIES_KHR;
enum VK_STRUCTURE_TYPE_MEMORY_GET_WIN32_HANDLE_INFO_KHR                                  = VkStructureType.VK_STRUCTURE_TYPE_MEMORY_GET_WIN32_HANDLE_INFO_KHR;
enum VK_STRUCTURE_TYPE_IMPORT_MEMORY_FD_INFO_KHR                                         = VkStructureType.VK_STRUCTURE_TYPE_IMPORT_MEMORY_FD_INFO_KHR;
enum VK_STRUCTURE_TYPE_MEMORY_FD_PROPERTIES_KHR                                          = VkStructureType.VK_STRUCTURE_TYPE_MEMORY_FD_PROPERTIES_KHR;
enum VK_STRUCTURE_TYPE_MEMORY_GET_FD_INFO_KHR                                            = VkStructureType.VK_STRUCTURE_TYPE_MEMORY_GET_FD_INFO_KHR;
enum VK_STRUCTURE_TYPE_WIN32_KEYED_MUTEX_ACQUIRE_RELEASE_INFO_KHR                        = VkStructureType.VK_STRUCTURE_TYPE_WIN32_KEYED_MUTEX_ACQUIRE_RELEASE_INFO_KHR;
enum VK_STRUCTURE_TYPE_IMPORT_SEMAPHORE_WIN32_HANDLE_INFO_KHR                            = VkStructureType.VK_STRUCTURE_TYPE_IMPORT_SEMAPHORE_WIN32_HANDLE_INFO_KHR;
enum VK_STRUCTURE_TYPE_EXPORT_SEMAPHORE_WIN32_HANDLE_INFO_KHR                            = VkStructureType.VK_STRUCTURE_TYPE_EXPORT_SEMAPHORE_WIN32_HANDLE_INFO_KHR;
enum VK_STRUCTURE_TYPE_D3D12_FENCE_SUBMIT_INFO_KHR                                       = VkStructureType.VK_STRUCTURE_TYPE_D3D12_FENCE_SUBMIT_INFO_KHR;
enum VK_STRUCTURE_TYPE_SEMAPHORE_GET_WIN32_HANDLE_INFO_KHR                               = VkStructureType.VK_STRUCTURE_TYPE_SEMAPHORE_GET_WIN32_HANDLE_INFO_KHR;
enum VK_STRUCTURE_TYPE_IMPORT_SEMAPHORE_FD_INFO_KHR                                      = VkStructureType.VK_STRUCTURE_TYPE_IMPORT_SEMAPHORE_FD_INFO_KHR;
enum VK_STRUCTURE_TYPE_SEMAPHORE_GET_FD_INFO_KHR                                         = VkStructureType.VK_STRUCTURE_TYPE_SEMAPHORE_GET_FD_INFO_KHR;
enum VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_PUSH_DESCRIPTOR_PROPERTIES_KHR                    = VkStructureType.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_PUSH_DESCRIPTOR_PROPERTIES_KHR;
enum VK_STRUCTURE_TYPE_COMMAND_BUFFER_INHERITANCE_CONDITIONAL_RENDERING_INFO_EXT         = VkStructureType.VK_STRUCTURE_TYPE_COMMAND_BUFFER_INHERITANCE_CONDITIONAL_RENDERING_INFO_EXT;
enum VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_CONDITIONAL_RENDERING_FEATURES_EXT                = VkStructureType.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_CONDITIONAL_RENDERING_FEATURES_EXT;
enum VK_STRUCTURE_TYPE_CONDITIONAL_RENDERING_BEGIN_INFO_EXT                              = VkStructureType.VK_STRUCTURE_TYPE_CONDITIONAL_RENDERING_BEGIN_INFO_EXT;
enum VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_FLOAT16_INT8_FEATURES_KHR                         = VkStructureType.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_FLOAT16_INT8_FEATURES_KHR;
enum VK_STRUCTURE_TYPE_PRESENT_REGIONS_KHR                                               = VkStructureType.VK_STRUCTURE_TYPE_PRESENT_REGIONS_KHR;
enum VK_STRUCTURE_TYPE_OBJECT_TABLE_CREATE_INFO_NVX                                      = VkStructureType.VK_STRUCTURE_TYPE_OBJECT_TABLE_CREATE_INFO_NVX;
enum VK_STRUCTURE_TYPE_INDIRECT_COMMANDS_LAYOUT_CREATE_INFO_NVX                          = VkStructureType.VK_STRUCTURE_TYPE_INDIRECT_COMMANDS_LAYOUT_CREATE_INFO_NVX;
enum VK_STRUCTURE_TYPE_CMD_PROCESS_COMMANDS_INFO_NVX                                     = VkStructureType.VK_STRUCTURE_TYPE_CMD_PROCESS_COMMANDS_INFO_NVX;
enum VK_STRUCTURE_TYPE_CMD_RESERVE_SPACE_FOR_COMMANDS_INFO_NVX                           = VkStructureType.VK_STRUCTURE_TYPE_CMD_RESERVE_SPACE_FOR_COMMANDS_INFO_NVX;
enum VK_STRUCTURE_TYPE_DEVICE_GENERATED_COMMANDS_LIMITS_NVX                              = VkStructureType.VK_STRUCTURE_TYPE_DEVICE_GENERATED_COMMANDS_LIMITS_NVX;
enum VK_STRUCTURE_TYPE_DEVICE_GENERATED_COMMANDS_FEATURES_NVX                            = VkStructureType.VK_STRUCTURE_TYPE_DEVICE_GENERATED_COMMANDS_FEATURES_NVX;
enum VK_STRUCTURE_TYPE_PIPELINE_VIEWPORT_W_SCALING_STATE_CREATE_INFO_NV                  = VkStructureType.VK_STRUCTURE_TYPE_PIPELINE_VIEWPORT_W_SCALING_STATE_CREATE_INFO_NV;
enum VK_STRUCTURE_TYPE_SURFACE_CAPABILITIES_2_EXT                                        = VkStructureType.VK_STRUCTURE_TYPE_SURFACE_CAPABILITIES_2_EXT;
enum VK_STRUCTURE_TYPE_DISPLAY_POWER_INFO_EXT                                            = VkStructureType.VK_STRUCTURE_TYPE_DISPLAY_POWER_INFO_EXT;
enum VK_STRUCTURE_TYPE_DEVICE_EVENT_INFO_EXT                                             = VkStructureType.VK_STRUCTURE_TYPE_DEVICE_EVENT_INFO_EXT;
enum VK_STRUCTURE_TYPE_DISPLAY_EVENT_INFO_EXT                                            = VkStructureType.VK_STRUCTURE_TYPE_DISPLAY_EVENT_INFO_EXT;
enum VK_STRUCTURE_TYPE_SWAPCHAIN_COUNTER_CREATE_INFO_EXT                                 = VkStructureType.VK_STRUCTURE_TYPE_SWAPCHAIN_COUNTER_CREATE_INFO_EXT;
enum VK_STRUCTURE_TYPE_PRESENT_TIMES_INFO_GOOGLE                                         = VkStructureType.VK_STRUCTURE_TYPE_PRESENT_TIMES_INFO_GOOGLE;
enum VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_MULTIVIEW_PER_VIEW_ATTRIBUTES_PROPERTIES_NVX      = VkStructureType.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_MULTIVIEW_PER_VIEW_ATTRIBUTES_PROPERTIES_NVX;
enum VK_STRUCTURE_TYPE_PIPELINE_VIEWPORT_SWIZZLE_STATE_CREATE_INFO_NV                    = VkStructureType.VK_STRUCTURE_TYPE_PIPELINE_VIEWPORT_SWIZZLE_STATE_CREATE_INFO_NV;
enum VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_DISCARD_RECTANGLE_PROPERTIES_EXT                  = VkStructureType.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_DISCARD_RECTANGLE_PROPERTIES_EXT;
enum VK_STRUCTURE_TYPE_PIPELINE_DISCARD_RECTANGLE_STATE_CREATE_INFO_EXT                  = VkStructureType.VK_STRUCTURE_TYPE_PIPELINE_DISCARD_RECTANGLE_STATE_CREATE_INFO_EXT;
enum VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_CONSERVATIVE_RASTERIZATION_PROPERTIES_EXT         = VkStructureType.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_CONSERVATIVE_RASTERIZATION_PROPERTIES_EXT;
enum VK_STRUCTURE_TYPE_PIPELINE_RASTERIZATION_CONSERVATIVE_STATE_CREATE_INFO_EXT         = VkStructureType.VK_STRUCTURE_TYPE_PIPELINE_RASTERIZATION_CONSERVATIVE_STATE_CREATE_INFO_EXT;
enum VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_DEPTH_CLIP_ENABLE_FEATURES_EXT                    = VkStructureType.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_DEPTH_CLIP_ENABLE_FEATURES_EXT;
enum VK_STRUCTURE_TYPE_PIPELINE_RASTERIZATION_DEPTH_CLIP_STATE_CREATE_INFO_EXT           = VkStructureType.VK_STRUCTURE_TYPE_PIPELINE_RASTERIZATION_DEPTH_CLIP_STATE_CREATE_INFO_EXT;
enum VK_STRUCTURE_TYPE_HDR_METADATA_EXT                                                  = VkStructureType.VK_STRUCTURE_TYPE_HDR_METADATA_EXT;
enum VK_STRUCTURE_TYPE_ATTACHMENT_DESCRIPTION_2_KHR                                      = VkStructureType.VK_STRUCTURE_TYPE_ATTACHMENT_DESCRIPTION_2_KHR;
enum VK_STRUCTURE_TYPE_ATTACHMENT_REFERENCE_2_KHR                                        = VkStructureType.VK_STRUCTURE_TYPE_ATTACHMENT_REFERENCE_2_KHR;
enum VK_STRUCTURE_TYPE_SUBPASS_DESCRIPTION_2_KHR                                         = VkStructureType.VK_STRUCTURE_TYPE_SUBPASS_DESCRIPTION_2_KHR;
enum VK_STRUCTURE_TYPE_SUBPASS_DEPENDENCY_2_KHR                                          = VkStructureType.VK_STRUCTURE_TYPE_SUBPASS_DEPENDENCY_2_KHR;
enum VK_STRUCTURE_TYPE_RENDER_PASS_CREATE_INFO_2_KHR                                     = VkStructureType.VK_STRUCTURE_TYPE_RENDER_PASS_CREATE_INFO_2_KHR;
enum VK_STRUCTURE_TYPE_SUBPASS_BEGIN_INFO_KHR                                            = VkStructureType.VK_STRUCTURE_TYPE_SUBPASS_BEGIN_INFO_KHR;
enum VK_STRUCTURE_TYPE_SUBPASS_END_INFO_KHR                                              = VkStructureType.VK_STRUCTURE_TYPE_SUBPASS_END_INFO_KHR;
enum VK_STRUCTURE_TYPE_SHARED_PRESENT_SURFACE_CAPABILITIES_KHR                           = VkStructureType.VK_STRUCTURE_TYPE_SHARED_PRESENT_SURFACE_CAPABILITIES_KHR;
enum VK_STRUCTURE_TYPE_IMPORT_FENCE_WIN32_HANDLE_INFO_KHR                                = VkStructureType.VK_STRUCTURE_TYPE_IMPORT_FENCE_WIN32_HANDLE_INFO_KHR;
enum VK_STRUCTURE_TYPE_EXPORT_FENCE_WIN32_HANDLE_INFO_KHR                                = VkStructureType.VK_STRUCTURE_TYPE_EXPORT_FENCE_WIN32_HANDLE_INFO_KHR;
enum VK_STRUCTURE_TYPE_FENCE_GET_WIN32_HANDLE_INFO_KHR                                   = VkStructureType.VK_STRUCTURE_TYPE_FENCE_GET_WIN32_HANDLE_INFO_KHR;
enum VK_STRUCTURE_TYPE_IMPORT_FENCE_FD_INFO_KHR                                          = VkStructureType.VK_STRUCTURE_TYPE_IMPORT_FENCE_FD_INFO_KHR;
enum VK_STRUCTURE_TYPE_FENCE_GET_FD_INFO_KHR                                             = VkStructureType.VK_STRUCTURE_TYPE_FENCE_GET_FD_INFO_KHR;
enum VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_SURFACE_INFO_2_KHR                                = VkStructureType.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_SURFACE_INFO_2_KHR;
enum VK_STRUCTURE_TYPE_SURFACE_CAPABILITIES_2_KHR                                        = VkStructureType.VK_STRUCTURE_TYPE_SURFACE_CAPABILITIES_2_KHR;
enum VK_STRUCTURE_TYPE_SURFACE_FORMAT_2_KHR                                              = VkStructureType.VK_STRUCTURE_TYPE_SURFACE_FORMAT_2_KHR;
enum VK_STRUCTURE_TYPE_DISPLAY_PROPERTIES_2_KHR                                          = VkStructureType.VK_STRUCTURE_TYPE_DISPLAY_PROPERTIES_2_KHR;
enum VK_STRUCTURE_TYPE_DISPLAY_PLANE_PROPERTIES_2_KHR                                    = VkStructureType.VK_STRUCTURE_TYPE_DISPLAY_PLANE_PROPERTIES_2_KHR;
enum VK_STRUCTURE_TYPE_DISPLAY_MODE_PROPERTIES_2_KHR                                     = VkStructureType.VK_STRUCTURE_TYPE_DISPLAY_MODE_PROPERTIES_2_KHR;
enum VK_STRUCTURE_TYPE_DISPLAY_PLANE_INFO_2_KHR                                          = VkStructureType.VK_STRUCTURE_TYPE_DISPLAY_PLANE_INFO_2_KHR;
enum VK_STRUCTURE_TYPE_DISPLAY_PLANE_CAPABILITIES_2_KHR                                  = VkStructureType.VK_STRUCTURE_TYPE_DISPLAY_PLANE_CAPABILITIES_2_KHR;
enum VK_STRUCTURE_TYPE_IOS_SURFACE_CREATE_INFO_MVK                                       = VkStructureType.VK_STRUCTURE_TYPE_IOS_SURFACE_CREATE_INFO_MVK;
enum VK_STRUCTURE_TYPE_MACOS_SURFACE_CREATE_INFO_MVK                                     = VkStructureType.VK_STRUCTURE_TYPE_MACOS_SURFACE_CREATE_INFO_MVK;
enum VK_STRUCTURE_TYPE_DEBUG_UTILS_OBJECT_NAME_INFO_EXT                                  = VkStructureType.VK_STRUCTURE_TYPE_DEBUG_UTILS_OBJECT_NAME_INFO_EXT;
enum VK_STRUCTURE_TYPE_DEBUG_UTILS_OBJECT_TAG_INFO_EXT                                   = VkStructureType.VK_STRUCTURE_TYPE_DEBUG_UTILS_OBJECT_TAG_INFO_EXT;
enum VK_STRUCTURE_TYPE_DEBUG_UTILS_LABEL_EXT                                             = VkStructureType.VK_STRUCTURE_TYPE_DEBUG_UTILS_LABEL_EXT;
enum VK_STRUCTURE_TYPE_DEBUG_UTILS_MESSENGER_CALLBACK_DATA_EXT                           = VkStructureType.VK_STRUCTURE_TYPE_DEBUG_UTILS_MESSENGER_CALLBACK_DATA_EXT;
enum VK_STRUCTURE_TYPE_DEBUG_UTILS_MESSENGER_CREATE_INFO_EXT                             = VkStructureType.VK_STRUCTURE_TYPE_DEBUG_UTILS_MESSENGER_CREATE_INFO_EXT;
enum VK_STRUCTURE_TYPE_ANDROID_HARDWARE_BUFFER_USAGE_ANDROID                             = VkStructureType.VK_STRUCTURE_TYPE_ANDROID_HARDWARE_BUFFER_USAGE_ANDROID;
enum VK_STRUCTURE_TYPE_ANDROID_HARDWARE_BUFFER_PROPERTIES_ANDROID                        = VkStructureType.VK_STRUCTURE_TYPE_ANDROID_HARDWARE_BUFFER_PROPERTIES_ANDROID;
enum VK_STRUCTURE_TYPE_ANDROID_HARDWARE_BUFFER_FORMAT_PROPERTIES_ANDROID                 = VkStructureType.VK_STRUCTURE_TYPE_ANDROID_HARDWARE_BUFFER_FORMAT_PROPERTIES_ANDROID;
enum VK_STRUCTURE_TYPE_IMPORT_ANDROID_HARDWARE_BUFFER_INFO_ANDROID                       = VkStructureType.VK_STRUCTURE_TYPE_IMPORT_ANDROID_HARDWARE_BUFFER_INFO_ANDROID;
enum VK_STRUCTURE_TYPE_MEMORY_GET_ANDROID_HARDWARE_BUFFER_INFO_ANDROID                   = VkStructureType.VK_STRUCTURE_TYPE_MEMORY_GET_ANDROID_HARDWARE_BUFFER_INFO_ANDROID;
enum VK_STRUCTURE_TYPE_EXTERNAL_FORMAT_ANDROID                                           = VkStructureType.VK_STRUCTURE_TYPE_EXTERNAL_FORMAT_ANDROID;
enum VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_SAMPLER_FILTER_MINMAX_PROPERTIES_EXT              = VkStructureType.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_SAMPLER_FILTER_MINMAX_PROPERTIES_EXT;
enum VK_STRUCTURE_TYPE_SAMPLER_REDUCTION_MODE_CREATE_INFO_EXT                            = VkStructureType.VK_STRUCTURE_TYPE_SAMPLER_REDUCTION_MODE_CREATE_INFO_EXT;
enum VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_INLINE_UNIFORM_BLOCK_FEATURES_EXT                 = VkStructureType.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_INLINE_UNIFORM_BLOCK_FEATURES_EXT;
enum VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_INLINE_UNIFORM_BLOCK_PROPERTIES_EXT               = VkStructureType.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_INLINE_UNIFORM_BLOCK_PROPERTIES_EXT;
enum VK_STRUCTURE_TYPE_WRITE_DESCRIPTOR_SET_INLINE_UNIFORM_BLOCK_EXT                     = VkStructureType.VK_STRUCTURE_TYPE_WRITE_DESCRIPTOR_SET_INLINE_UNIFORM_BLOCK_EXT;
enum VK_STRUCTURE_TYPE_DESCRIPTOR_POOL_INLINE_UNIFORM_BLOCK_CREATE_INFO_EXT              = VkStructureType.VK_STRUCTURE_TYPE_DESCRIPTOR_POOL_INLINE_UNIFORM_BLOCK_CREATE_INFO_EXT;
enum VK_STRUCTURE_TYPE_SAMPLE_LOCATIONS_INFO_EXT                                         = VkStructureType.VK_STRUCTURE_TYPE_SAMPLE_LOCATIONS_INFO_EXT;
enum VK_STRUCTURE_TYPE_RENDER_PASS_SAMPLE_LOCATIONS_BEGIN_INFO_EXT                       = VkStructureType.VK_STRUCTURE_TYPE_RENDER_PASS_SAMPLE_LOCATIONS_BEGIN_INFO_EXT;
enum VK_STRUCTURE_TYPE_PIPELINE_SAMPLE_LOCATIONS_STATE_CREATE_INFO_EXT                   = VkStructureType.VK_STRUCTURE_TYPE_PIPELINE_SAMPLE_LOCATIONS_STATE_CREATE_INFO_EXT;
enum VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_SAMPLE_LOCATIONS_PROPERTIES_EXT                   = VkStructureType.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_SAMPLE_LOCATIONS_PROPERTIES_EXT;
enum VK_STRUCTURE_TYPE_MULTISAMPLE_PROPERTIES_EXT                                        = VkStructureType.VK_STRUCTURE_TYPE_MULTISAMPLE_PROPERTIES_EXT;
enum VK_STRUCTURE_TYPE_IMAGE_FORMAT_LIST_CREATE_INFO_KHR                                 = VkStructureType.VK_STRUCTURE_TYPE_IMAGE_FORMAT_LIST_CREATE_INFO_KHR;
enum VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_BLEND_OPERATION_ADVANCED_FEATURES_EXT             = VkStructureType.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_BLEND_OPERATION_ADVANCED_FEATURES_EXT;
enum VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_BLEND_OPERATION_ADVANCED_PROPERTIES_EXT           = VkStructureType.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_BLEND_OPERATION_ADVANCED_PROPERTIES_EXT;
enum VK_STRUCTURE_TYPE_PIPELINE_COLOR_BLEND_ADVANCED_STATE_CREATE_INFO_EXT               = VkStructureType.VK_STRUCTURE_TYPE_PIPELINE_COLOR_BLEND_ADVANCED_STATE_CREATE_INFO_EXT;
enum VK_STRUCTURE_TYPE_PIPELINE_COVERAGE_TO_COLOR_STATE_CREATE_INFO_NV                   = VkStructureType.VK_STRUCTURE_TYPE_PIPELINE_COVERAGE_TO_COLOR_STATE_CREATE_INFO_NV;
enum VK_STRUCTURE_TYPE_PIPELINE_COVERAGE_MODULATION_STATE_CREATE_INFO_NV                 = VkStructureType.VK_STRUCTURE_TYPE_PIPELINE_COVERAGE_MODULATION_STATE_CREATE_INFO_NV;
enum VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_SHADER_SM_BUILTINS_FEATURES_NV                    = VkStructureType.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_SHADER_SM_BUILTINS_FEATURES_NV;
enum VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_SHADER_SM_BUILTINS_PROPERTIES_NV                  = VkStructureType.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_SHADER_SM_BUILTINS_PROPERTIES_NV;
enum VK_STRUCTURE_TYPE_DRM_FORMAT_MODIFIER_PROPERTIES_LIST_EXT                           = VkStructureType.VK_STRUCTURE_TYPE_DRM_FORMAT_MODIFIER_PROPERTIES_LIST_EXT;
enum VK_STRUCTURE_TYPE_DRM_FORMAT_MODIFIER_PROPERTIES_EXT                                = VkStructureType.VK_STRUCTURE_TYPE_DRM_FORMAT_MODIFIER_PROPERTIES_EXT;
enum VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_IMAGE_DRM_FORMAT_MODIFIER_INFO_EXT                = VkStructureType.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_IMAGE_DRM_FORMAT_MODIFIER_INFO_EXT;
enum VK_STRUCTURE_TYPE_IMAGE_DRM_FORMAT_MODIFIER_LIST_CREATE_INFO_EXT                    = VkStructureType.VK_STRUCTURE_TYPE_IMAGE_DRM_FORMAT_MODIFIER_LIST_CREATE_INFO_EXT;
enum VK_STRUCTURE_TYPE_IMAGE_DRM_FORMAT_MODIFIER_EXPLICIT_CREATE_INFO_EXT                = VkStructureType.VK_STRUCTURE_TYPE_IMAGE_DRM_FORMAT_MODIFIER_EXPLICIT_CREATE_INFO_EXT;
enum VK_STRUCTURE_TYPE_IMAGE_DRM_FORMAT_MODIFIER_PROPERTIES_EXT                          = VkStructureType.VK_STRUCTURE_TYPE_IMAGE_DRM_FORMAT_MODIFIER_PROPERTIES_EXT;
enum VK_STRUCTURE_TYPE_VALIDATION_CACHE_CREATE_INFO_EXT                                  = VkStructureType.VK_STRUCTURE_TYPE_VALIDATION_CACHE_CREATE_INFO_EXT;
enum VK_STRUCTURE_TYPE_SHADER_MODULE_VALIDATION_CACHE_CREATE_INFO_EXT                    = VkStructureType.VK_STRUCTURE_TYPE_SHADER_MODULE_VALIDATION_CACHE_CREATE_INFO_EXT;
enum VK_STRUCTURE_TYPE_DESCRIPTOR_SET_LAYOUT_BINDING_FLAGS_CREATE_INFO_EXT               = VkStructureType.VK_STRUCTURE_TYPE_DESCRIPTOR_SET_LAYOUT_BINDING_FLAGS_CREATE_INFO_EXT;
enum VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_DESCRIPTOR_INDEXING_FEATURES_EXT                  = VkStructureType.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_DESCRIPTOR_INDEXING_FEATURES_EXT;
enum VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_DESCRIPTOR_INDEXING_PROPERTIES_EXT                = VkStructureType.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_DESCRIPTOR_INDEXING_PROPERTIES_EXT;
enum VK_STRUCTURE_TYPE_DESCRIPTOR_SET_VARIABLE_DESCRIPTOR_COUNT_ALLOCATE_INFO_EXT        = VkStructureType.VK_STRUCTURE_TYPE_DESCRIPTOR_SET_VARIABLE_DESCRIPTOR_COUNT_ALLOCATE_INFO_EXT;
enum VK_STRUCTURE_TYPE_DESCRIPTOR_SET_VARIABLE_DESCRIPTOR_COUNT_LAYOUT_SUPPORT_EXT       = VkStructureType.VK_STRUCTURE_TYPE_DESCRIPTOR_SET_VARIABLE_DESCRIPTOR_COUNT_LAYOUT_SUPPORT_EXT;
enum VK_STRUCTURE_TYPE_PIPELINE_VIEWPORT_SHADING_RATE_IMAGE_STATE_CREATE_INFO_NV         = VkStructureType.VK_STRUCTURE_TYPE_PIPELINE_VIEWPORT_SHADING_RATE_IMAGE_STATE_CREATE_INFO_NV;
enum VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_SHADING_RATE_IMAGE_FEATURES_NV                    = VkStructureType.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_SHADING_RATE_IMAGE_FEATURES_NV;
enum VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_SHADING_RATE_IMAGE_PROPERTIES_NV                  = VkStructureType.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_SHADING_RATE_IMAGE_PROPERTIES_NV;
enum VK_STRUCTURE_TYPE_PIPELINE_VIEWPORT_COARSE_SAMPLE_ORDER_STATE_CREATE_INFO_NV        = VkStructureType.VK_STRUCTURE_TYPE_PIPELINE_VIEWPORT_COARSE_SAMPLE_ORDER_STATE_CREATE_INFO_NV;
enum VK_STRUCTURE_TYPE_RAY_TRACING_PIPELINE_CREATE_INFO_NV                               = VkStructureType.VK_STRUCTURE_TYPE_RAY_TRACING_PIPELINE_CREATE_INFO_NV;
enum VK_STRUCTURE_TYPE_ACCELERATION_STRUCTURE_CREATE_INFO_NV                             = VkStructureType.VK_STRUCTURE_TYPE_ACCELERATION_STRUCTURE_CREATE_INFO_NV;
enum VK_STRUCTURE_TYPE_GEOMETRY_NV                                                       = VkStructureType.VK_STRUCTURE_TYPE_GEOMETRY_NV;
enum VK_STRUCTURE_TYPE_GEOMETRY_TRIANGLES_NV                                             = VkStructureType.VK_STRUCTURE_TYPE_GEOMETRY_TRIANGLES_NV;
enum VK_STRUCTURE_TYPE_GEOMETRY_AABB_NV                                                  = VkStructureType.VK_STRUCTURE_TYPE_GEOMETRY_AABB_NV;
enum VK_STRUCTURE_TYPE_BIND_ACCELERATION_STRUCTURE_MEMORY_INFO_NV                        = VkStructureType.VK_STRUCTURE_TYPE_BIND_ACCELERATION_STRUCTURE_MEMORY_INFO_NV;
enum VK_STRUCTURE_TYPE_WRITE_DESCRIPTOR_SET_ACCELERATION_STRUCTURE_NV                    = VkStructureType.VK_STRUCTURE_TYPE_WRITE_DESCRIPTOR_SET_ACCELERATION_STRUCTURE_NV;
enum VK_STRUCTURE_TYPE_ACCELERATION_STRUCTURE_MEMORY_REQUIREMENTS_INFO_NV                = VkStructureType.VK_STRUCTURE_TYPE_ACCELERATION_STRUCTURE_MEMORY_REQUIREMENTS_INFO_NV;
enum VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_RAY_TRACING_PROPERTIES_NV                         = VkStructureType.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_RAY_TRACING_PROPERTIES_NV;
enum VK_STRUCTURE_TYPE_RAY_TRACING_SHADER_GROUP_CREATE_INFO_NV                           = VkStructureType.VK_STRUCTURE_TYPE_RAY_TRACING_SHADER_GROUP_CREATE_INFO_NV;
enum VK_STRUCTURE_TYPE_ACCELERATION_STRUCTURE_INFO_NV                                    = VkStructureType.VK_STRUCTURE_TYPE_ACCELERATION_STRUCTURE_INFO_NV;
enum VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_REPRESENTATIVE_FRAGMENT_TEST_FEATURES_NV          = VkStructureType.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_REPRESENTATIVE_FRAGMENT_TEST_FEATURES_NV;
enum VK_STRUCTURE_TYPE_PIPELINE_REPRESENTATIVE_FRAGMENT_TEST_STATE_CREATE_INFO_NV        = VkStructureType.VK_STRUCTURE_TYPE_PIPELINE_REPRESENTATIVE_FRAGMENT_TEST_STATE_CREATE_INFO_NV;
enum VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_IMAGE_VIEW_IMAGE_FORMAT_INFO_EXT                  = VkStructureType.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_IMAGE_VIEW_IMAGE_FORMAT_INFO_EXT;
enum VK_STRUCTURE_TYPE_FILTER_CUBIC_IMAGE_VIEW_IMAGE_FORMAT_PROPERTIES_EXT               = VkStructureType.VK_STRUCTURE_TYPE_FILTER_CUBIC_IMAGE_VIEW_IMAGE_FORMAT_PROPERTIES_EXT;
enum VK_STRUCTURE_TYPE_DEVICE_QUEUE_GLOBAL_PRIORITY_CREATE_INFO_EXT                      = VkStructureType.VK_STRUCTURE_TYPE_DEVICE_QUEUE_GLOBAL_PRIORITY_CREATE_INFO_EXT;
enum VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_8BIT_STORAGE_FEATURES_KHR                         = VkStructureType.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_8BIT_STORAGE_FEATURES_KHR;
enum VK_STRUCTURE_TYPE_IMPORT_MEMORY_HOST_POINTER_INFO_EXT                               = VkStructureType.VK_STRUCTURE_TYPE_IMPORT_MEMORY_HOST_POINTER_INFO_EXT;
enum VK_STRUCTURE_TYPE_MEMORY_HOST_POINTER_PROPERTIES_EXT                                = VkStructureType.VK_STRUCTURE_TYPE_MEMORY_HOST_POINTER_PROPERTIES_EXT;
enum VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_EXTERNAL_MEMORY_HOST_PROPERTIES_EXT               = VkStructureType.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_EXTERNAL_MEMORY_HOST_PROPERTIES_EXT;
enum VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_SHADER_ATOMIC_INT64_FEATURES_KHR                  = VkStructureType.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_SHADER_ATOMIC_INT64_FEATURES_KHR;
enum VK_STRUCTURE_TYPE_CALIBRATED_TIMESTAMP_INFO_EXT                                     = VkStructureType.VK_STRUCTURE_TYPE_CALIBRATED_TIMESTAMP_INFO_EXT;
enum VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_SHADER_CORE_PROPERTIES_AMD                        = VkStructureType.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_SHADER_CORE_PROPERTIES_AMD;
enum VK_STRUCTURE_TYPE_DEVICE_MEMORY_OVERALLOCATION_CREATE_INFO_AMD                      = VkStructureType.VK_STRUCTURE_TYPE_DEVICE_MEMORY_OVERALLOCATION_CREATE_INFO_AMD;
enum VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_VERTEX_ATTRIBUTE_DIVISOR_PROPERTIES_EXT           = VkStructureType.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_VERTEX_ATTRIBUTE_DIVISOR_PROPERTIES_EXT;
enum VK_STRUCTURE_TYPE_PIPELINE_VERTEX_INPUT_DIVISOR_STATE_CREATE_INFO_EXT               = VkStructureType.VK_STRUCTURE_TYPE_PIPELINE_VERTEX_INPUT_DIVISOR_STATE_CREATE_INFO_EXT;
enum VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_VERTEX_ATTRIBUTE_DIVISOR_FEATURES_EXT             = VkStructureType.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_VERTEX_ATTRIBUTE_DIVISOR_FEATURES_EXT;
enum VK_STRUCTURE_TYPE_PRESENT_FRAME_TOKEN_GGP                                           = VkStructureType.VK_STRUCTURE_TYPE_PRESENT_FRAME_TOKEN_GGP;
enum VK_STRUCTURE_TYPE_PIPELINE_CREATION_FEEDBACK_CREATE_INFO_EXT                        = VkStructureType.VK_STRUCTURE_TYPE_PIPELINE_CREATION_FEEDBACK_CREATE_INFO_EXT;
enum VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_DRIVER_PROPERTIES_KHR                             = VkStructureType.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_DRIVER_PROPERTIES_KHR;
enum VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_FLOAT_CONTROLS_PROPERTIES_KHR                     = VkStructureType.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_FLOAT_CONTROLS_PROPERTIES_KHR;
enum VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_DEPTH_STENCIL_RESOLVE_PROPERTIES_KHR              = VkStructureType.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_DEPTH_STENCIL_RESOLVE_PROPERTIES_KHR;
enum VK_STRUCTURE_TYPE_SUBPASS_DESCRIPTION_DEPTH_STENCIL_RESOLVE_KHR                     = VkStructureType.VK_STRUCTURE_TYPE_SUBPASS_DESCRIPTION_DEPTH_STENCIL_RESOLVE_KHR;
enum VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_COMPUTE_SHADER_DERIVATIVES_FEATURES_NV            = VkStructureType.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_COMPUTE_SHADER_DERIVATIVES_FEATURES_NV;
enum VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_MESH_SHADER_FEATURES_NV                           = VkStructureType.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_MESH_SHADER_FEATURES_NV;
enum VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_MESH_SHADER_PROPERTIES_NV                         = VkStructureType.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_MESH_SHADER_PROPERTIES_NV;
enum VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_FRAGMENT_SHADER_BARYCENTRIC_FEATURES_NV           = VkStructureType.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_FRAGMENT_SHADER_BARYCENTRIC_FEATURES_NV;
enum VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_SHADER_IMAGE_FOOTPRINT_FEATURES_NV                = VkStructureType.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_SHADER_IMAGE_FOOTPRINT_FEATURES_NV;
enum VK_STRUCTURE_TYPE_PIPELINE_VIEWPORT_EXCLUSIVE_SCISSOR_STATE_CREATE_INFO_NV          = VkStructureType.VK_STRUCTURE_TYPE_PIPELINE_VIEWPORT_EXCLUSIVE_SCISSOR_STATE_CREATE_INFO_NV;
enum VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_EXCLUSIVE_SCISSOR_FEATURES_NV                     = VkStructureType.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_EXCLUSIVE_SCISSOR_FEATURES_NV;
enum VK_STRUCTURE_TYPE_CHECKPOINT_DATA_NV                                                = VkStructureType.VK_STRUCTURE_TYPE_CHECKPOINT_DATA_NV;
enum VK_STRUCTURE_TYPE_QUEUE_FAMILY_CHECKPOINT_PROPERTIES_NV                             = VkStructureType.VK_STRUCTURE_TYPE_QUEUE_FAMILY_CHECKPOINT_PROPERTIES_NV;
enum VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_SHADER_INTEGER_FUNCTIONS2_FEATURES_INTEL          = VkStructureType.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_SHADER_INTEGER_FUNCTIONS2_FEATURES_INTEL;
enum VK_STRUCTURE_TYPE_QUERY_POOL_CREATE_INFO_INTEL                                      = VkStructureType.VK_STRUCTURE_TYPE_QUERY_POOL_CREATE_INFO_INTEL;
enum VK_STRUCTURE_TYPE_INITIALIZE_PERFORMANCE_API_INFO_INTEL                             = VkStructureType.VK_STRUCTURE_TYPE_INITIALIZE_PERFORMANCE_API_INFO_INTEL;
enum VK_STRUCTURE_TYPE_PERFORMANCE_MARKER_INFO_INTEL                                     = VkStructureType.VK_STRUCTURE_TYPE_PERFORMANCE_MARKER_INFO_INTEL;
enum VK_STRUCTURE_TYPE_PERFORMANCE_STREAM_MARKER_INFO_INTEL                              = VkStructureType.VK_STRUCTURE_TYPE_PERFORMANCE_STREAM_MARKER_INFO_INTEL;
enum VK_STRUCTURE_TYPE_PERFORMANCE_OVERRIDE_INFO_INTEL                                   = VkStructureType.VK_STRUCTURE_TYPE_PERFORMANCE_OVERRIDE_INFO_INTEL;
enum VK_STRUCTURE_TYPE_PERFORMANCE_CONFIGURATION_ACQUIRE_INFO_INTEL                      = VkStructureType.VK_STRUCTURE_TYPE_PERFORMANCE_CONFIGURATION_ACQUIRE_INFO_INTEL;
enum VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_VULKAN_MEMORY_MODEL_FEATURES_KHR                  = VkStructureType.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_VULKAN_MEMORY_MODEL_FEATURES_KHR;
enum VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_PCI_BUS_INFO_PROPERTIES_EXT                       = VkStructureType.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_PCI_BUS_INFO_PROPERTIES_EXT;
enum VK_STRUCTURE_TYPE_DISPLAY_NATIVE_HDR_SURFACE_CAPABILITIES_AMD                       = VkStructureType.VK_STRUCTURE_TYPE_DISPLAY_NATIVE_HDR_SURFACE_CAPABILITIES_AMD;
enum VK_STRUCTURE_TYPE_SWAPCHAIN_DISPLAY_NATIVE_HDR_CREATE_INFO_AMD                      = VkStructureType.VK_STRUCTURE_TYPE_SWAPCHAIN_DISPLAY_NATIVE_HDR_CREATE_INFO_AMD;
enum VK_STRUCTURE_TYPE_IMAGEPIPE_SURFACE_CREATE_INFO_FUCHSIA                             = VkStructureType.VK_STRUCTURE_TYPE_IMAGEPIPE_SURFACE_CREATE_INFO_FUCHSIA;
enum VK_STRUCTURE_TYPE_METAL_SURFACE_CREATE_INFO_EXT                                     = VkStructureType.VK_STRUCTURE_TYPE_METAL_SURFACE_CREATE_INFO_EXT;
enum VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_FRAGMENT_DENSITY_MAP_FEATURES_EXT                 = VkStructureType.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_FRAGMENT_DENSITY_MAP_FEATURES_EXT;
enum VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_FRAGMENT_DENSITY_MAP_PROPERTIES_EXT               = VkStructureType.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_FRAGMENT_DENSITY_MAP_PROPERTIES_EXT;
enum VK_STRUCTURE_TYPE_RENDER_PASS_FRAGMENT_DENSITY_MAP_CREATE_INFO_EXT                  = VkStructureType.VK_STRUCTURE_TYPE_RENDER_PASS_FRAGMENT_DENSITY_MAP_CREATE_INFO_EXT;
enum VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_SCALAR_BLOCK_LAYOUT_FEATURES_EXT                  = VkStructureType.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_SCALAR_BLOCK_LAYOUT_FEATURES_EXT;
enum VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_MEMORY_BUDGET_PROPERTIES_EXT                      = VkStructureType.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_MEMORY_BUDGET_PROPERTIES_EXT;
enum VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_MEMORY_PRIORITY_FEATURES_EXT                      = VkStructureType.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_MEMORY_PRIORITY_FEATURES_EXT;
enum VK_STRUCTURE_TYPE_MEMORY_PRIORITY_ALLOCATE_INFO_EXT                                 = VkStructureType.VK_STRUCTURE_TYPE_MEMORY_PRIORITY_ALLOCATE_INFO_EXT;
enum VK_STRUCTURE_TYPE_SURFACE_PROTECTED_CAPABILITIES_KHR                                = VkStructureType.VK_STRUCTURE_TYPE_SURFACE_PROTECTED_CAPABILITIES_KHR;
enum VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_DEDICATED_ALLOCATION_IMAGE_ALIASING_FEATURES_NV   = VkStructureType.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_DEDICATED_ALLOCATION_IMAGE_ALIASING_FEATURES_NV;
enum VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_BUFFER_DEVICE_ADDRESS_FEATURES_EXT                = VkStructureType.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_BUFFER_DEVICE_ADDRESS_FEATURES_EXT;
enum VK_STRUCTURE_TYPE_BUFFER_DEVICE_ADDRESS_INFO_EXT                                    = VkStructureType.VK_STRUCTURE_TYPE_BUFFER_DEVICE_ADDRESS_INFO_EXT;
enum VK_STRUCTURE_TYPE_BUFFER_DEVICE_ADDRESS_CREATE_INFO_EXT                             = VkStructureType.VK_STRUCTURE_TYPE_BUFFER_DEVICE_ADDRESS_CREATE_INFO_EXT;
enum VK_STRUCTURE_TYPE_IMAGE_STENCIL_USAGE_CREATE_INFO_EXT                               = VkStructureType.VK_STRUCTURE_TYPE_IMAGE_STENCIL_USAGE_CREATE_INFO_EXT;
enum VK_STRUCTURE_TYPE_VALIDATION_FEATURES_EXT                                           = VkStructureType.VK_STRUCTURE_TYPE_VALIDATION_FEATURES_EXT;
enum VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_COOPERATIVE_MATRIX_FEATURES_NV                    = VkStructureType.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_COOPERATIVE_MATRIX_FEATURES_NV;
enum VK_STRUCTURE_TYPE_COOPERATIVE_MATRIX_PROPERTIES_NV                                  = VkStructureType.VK_STRUCTURE_TYPE_COOPERATIVE_MATRIX_PROPERTIES_NV;
enum VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_COOPERATIVE_MATRIX_PROPERTIES_NV                  = VkStructureType.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_COOPERATIVE_MATRIX_PROPERTIES_NV;
enum VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_COVERAGE_REDUCTION_MODE_FEATURES_NV               = VkStructureType.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_COVERAGE_REDUCTION_MODE_FEATURES_NV;
enum VK_STRUCTURE_TYPE_PIPELINE_COVERAGE_REDUCTION_STATE_CREATE_INFO_NV                  = VkStructureType.VK_STRUCTURE_TYPE_PIPELINE_COVERAGE_REDUCTION_STATE_CREATE_INFO_NV;
enum VK_STRUCTURE_TYPE_FRAMEBUFFER_MIXED_SAMPLES_COMBINATION_NV                          = VkStructureType.VK_STRUCTURE_TYPE_FRAMEBUFFER_MIXED_SAMPLES_COMBINATION_NV;
enum VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_FRAGMENT_SHADER_INTERLOCK_FEATURES_EXT            = VkStructureType.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_FRAGMENT_SHADER_INTERLOCK_FEATURES_EXT;
enum VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_YCBCR_IMAGE_ARRAYS_FEATURES_EXT                   = VkStructureType.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_YCBCR_IMAGE_ARRAYS_FEATURES_EXT;
enum VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_UNIFORM_BUFFER_STANDARD_LAYOUT_FEATURES_KHR       = VkStructureType.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_UNIFORM_BUFFER_STANDARD_LAYOUT_FEATURES_KHR;
enum VK_STRUCTURE_TYPE_SURFACE_FULL_SCREEN_EXCLUSIVE_INFO_EXT                            = VkStructureType.VK_STRUCTURE_TYPE_SURFACE_FULL_SCREEN_EXCLUSIVE_INFO_EXT;
enum VK_STRUCTURE_TYPE_SURFACE_CAPABILITIES_FULL_SCREEN_EXCLUSIVE_EXT                    = VkStructureType.VK_STRUCTURE_TYPE_SURFACE_CAPABILITIES_FULL_SCREEN_EXCLUSIVE_EXT;
enum VK_STRUCTURE_TYPE_SURFACE_FULL_SCREEN_EXCLUSIVE_WIN32_INFO_EXT                      = VkStructureType.VK_STRUCTURE_TYPE_SURFACE_FULL_SCREEN_EXCLUSIVE_WIN32_INFO_EXT;
enum VK_STRUCTURE_TYPE_HEADLESS_SURFACE_CREATE_INFO_EXT                                  = VkStructureType.VK_STRUCTURE_TYPE_HEADLESS_SURFACE_CREATE_INFO_EXT;
enum VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_HOST_QUERY_RESET_FEATURES_EXT                     = VkStructureType.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_HOST_QUERY_RESET_FEATURES_EXT;
enum VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_VARIABLE_POINTER_FEATURES                         = VkStructureType.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_VARIABLE_POINTER_FEATURES;
enum VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_SHADER_DRAW_PARAMETER_FEATURES                    = VkStructureType.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_SHADER_DRAW_PARAMETER_FEATURES;
enum VK_STRUCTURE_TYPE_DEBUG_REPORT_CREATE_INFO_EXT                                      = VkStructureType.VK_STRUCTURE_TYPE_DEBUG_REPORT_CREATE_INFO_EXT;
enum VK_STRUCTURE_TYPE_RENDER_PASS_MULTIVIEW_CREATE_INFO_KHR                             = VkStructureType.VK_STRUCTURE_TYPE_RENDER_PASS_MULTIVIEW_CREATE_INFO_KHR;
enum VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_MULTIVIEW_FEATURES_KHR                            = VkStructureType.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_MULTIVIEW_FEATURES_KHR;
enum VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_MULTIVIEW_PROPERTIES_KHR                          = VkStructureType.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_MULTIVIEW_PROPERTIES_KHR;
enum VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_FEATURES_2_KHR                                    = VkStructureType.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_FEATURES_2_KHR;
enum VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_PROPERTIES_2_KHR                                  = VkStructureType.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_PROPERTIES_2_KHR;
enum VK_STRUCTURE_TYPE_FORMAT_PROPERTIES_2_KHR                                           = VkStructureType.VK_STRUCTURE_TYPE_FORMAT_PROPERTIES_2_KHR;
enum VK_STRUCTURE_TYPE_IMAGE_FORMAT_PROPERTIES_2_KHR                                     = VkStructureType.VK_STRUCTURE_TYPE_IMAGE_FORMAT_PROPERTIES_2_KHR;
enum VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_IMAGE_FORMAT_INFO_2_KHR                           = VkStructureType.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_IMAGE_FORMAT_INFO_2_KHR;
enum VK_STRUCTURE_TYPE_QUEUE_FAMILY_PROPERTIES_2_KHR                                     = VkStructureType.VK_STRUCTURE_TYPE_QUEUE_FAMILY_PROPERTIES_2_KHR;
enum VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_MEMORY_PROPERTIES_2_KHR                           = VkStructureType.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_MEMORY_PROPERTIES_2_KHR;
enum VK_STRUCTURE_TYPE_SPARSE_IMAGE_FORMAT_PROPERTIES_2_KHR                              = VkStructureType.VK_STRUCTURE_TYPE_SPARSE_IMAGE_FORMAT_PROPERTIES_2_KHR;
enum VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_SPARSE_IMAGE_FORMAT_INFO_2_KHR                    = VkStructureType.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_SPARSE_IMAGE_FORMAT_INFO_2_KHR;
enum VK_STRUCTURE_TYPE_MEMORY_ALLOCATE_FLAGS_INFO_KHR                                    = VkStructureType.VK_STRUCTURE_TYPE_MEMORY_ALLOCATE_FLAGS_INFO_KHR;
enum VK_STRUCTURE_TYPE_DEVICE_GROUP_RENDER_PASS_BEGIN_INFO_KHR                           = VkStructureType.VK_STRUCTURE_TYPE_DEVICE_GROUP_RENDER_PASS_BEGIN_INFO_KHR;
enum VK_STRUCTURE_TYPE_DEVICE_GROUP_COMMAND_BUFFER_BEGIN_INFO_KHR                        = VkStructureType.VK_STRUCTURE_TYPE_DEVICE_GROUP_COMMAND_BUFFER_BEGIN_INFO_KHR;
enum VK_STRUCTURE_TYPE_DEVICE_GROUP_SUBMIT_INFO_KHR                                      = VkStructureType.VK_STRUCTURE_TYPE_DEVICE_GROUP_SUBMIT_INFO_KHR;
enum VK_STRUCTURE_TYPE_DEVICE_GROUP_BIND_SPARSE_INFO_KHR                                 = VkStructureType.VK_STRUCTURE_TYPE_DEVICE_GROUP_BIND_SPARSE_INFO_KHR;
enum VK_STRUCTURE_TYPE_BIND_BUFFER_MEMORY_DEVICE_GROUP_INFO_KHR                          = VkStructureType.VK_STRUCTURE_TYPE_BIND_BUFFER_MEMORY_DEVICE_GROUP_INFO_KHR;
enum VK_STRUCTURE_TYPE_BIND_IMAGE_MEMORY_DEVICE_GROUP_INFO_KHR                           = VkStructureType.VK_STRUCTURE_TYPE_BIND_IMAGE_MEMORY_DEVICE_GROUP_INFO_KHR;
enum VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_GROUP_PROPERTIES_KHR                              = VkStructureType.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_GROUP_PROPERTIES_KHR;
enum VK_STRUCTURE_TYPE_DEVICE_GROUP_DEVICE_CREATE_INFO_KHR                               = VkStructureType.VK_STRUCTURE_TYPE_DEVICE_GROUP_DEVICE_CREATE_INFO_KHR;
enum VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_EXTERNAL_IMAGE_FORMAT_INFO_KHR                    = VkStructureType.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_EXTERNAL_IMAGE_FORMAT_INFO_KHR;
enum VK_STRUCTURE_TYPE_EXTERNAL_IMAGE_FORMAT_PROPERTIES_KHR                              = VkStructureType.VK_STRUCTURE_TYPE_EXTERNAL_IMAGE_FORMAT_PROPERTIES_KHR;
enum VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_EXTERNAL_BUFFER_INFO_KHR                          = VkStructureType.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_EXTERNAL_BUFFER_INFO_KHR;
enum VK_STRUCTURE_TYPE_EXTERNAL_BUFFER_PROPERTIES_KHR                                    = VkStructureType.VK_STRUCTURE_TYPE_EXTERNAL_BUFFER_PROPERTIES_KHR;
enum VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_ID_PROPERTIES_KHR                                 = VkStructureType.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_ID_PROPERTIES_KHR;
enum VK_STRUCTURE_TYPE_EXTERNAL_MEMORY_BUFFER_CREATE_INFO_KHR                            = VkStructureType.VK_STRUCTURE_TYPE_EXTERNAL_MEMORY_BUFFER_CREATE_INFO_KHR;
enum VK_STRUCTURE_TYPE_EXTERNAL_MEMORY_IMAGE_CREATE_INFO_KHR                             = VkStructureType.VK_STRUCTURE_TYPE_EXTERNAL_MEMORY_IMAGE_CREATE_INFO_KHR;
enum VK_STRUCTURE_TYPE_EXPORT_MEMORY_ALLOCATE_INFO_KHR                                   = VkStructureType.VK_STRUCTURE_TYPE_EXPORT_MEMORY_ALLOCATE_INFO_KHR;
enum VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_EXTERNAL_SEMAPHORE_INFO_KHR                       = VkStructureType.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_EXTERNAL_SEMAPHORE_INFO_KHR;
enum VK_STRUCTURE_TYPE_EXTERNAL_SEMAPHORE_PROPERTIES_KHR                                 = VkStructureType.VK_STRUCTURE_TYPE_EXTERNAL_SEMAPHORE_PROPERTIES_KHR;
enum VK_STRUCTURE_TYPE_EXPORT_SEMAPHORE_CREATE_INFO_KHR                                  = VkStructureType.VK_STRUCTURE_TYPE_EXPORT_SEMAPHORE_CREATE_INFO_KHR;
enum VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_16BIT_STORAGE_FEATURES_KHR                        = VkStructureType.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_16BIT_STORAGE_FEATURES_KHR;
enum VK_STRUCTURE_TYPE_DESCRIPTOR_UPDATE_TEMPLATE_CREATE_INFO_KHR                        = VkStructureType.VK_STRUCTURE_TYPE_DESCRIPTOR_UPDATE_TEMPLATE_CREATE_INFO_KHR;
enum VK_STRUCTURE_TYPE_SURFACE_CAPABILITIES2_EXT                                         = VkStructureType.VK_STRUCTURE_TYPE_SURFACE_CAPABILITIES2_EXT;
enum VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_EXTERNAL_FENCE_INFO_KHR                           = VkStructureType.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_EXTERNAL_FENCE_INFO_KHR;
enum VK_STRUCTURE_TYPE_EXTERNAL_FENCE_PROPERTIES_KHR                                     = VkStructureType.VK_STRUCTURE_TYPE_EXTERNAL_FENCE_PROPERTIES_KHR;
enum VK_STRUCTURE_TYPE_EXPORT_FENCE_CREATE_INFO_KHR                                      = VkStructureType.VK_STRUCTURE_TYPE_EXPORT_FENCE_CREATE_INFO_KHR;
enum VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_POINT_CLIPPING_PROPERTIES_KHR                     = VkStructureType.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_POINT_CLIPPING_PROPERTIES_KHR;
enum VK_STRUCTURE_TYPE_RENDER_PASS_INPUT_ATTACHMENT_ASPECT_CREATE_INFO_KHR               = VkStructureType.VK_STRUCTURE_TYPE_RENDER_PASS_INPUT_ATTACHMENT_ASPECT_CREATE_INFO_KHR;
enum VK_STRUCTURE_TYPE_IMAGE_VIEW_USAGE_CREATE_INFO_KHR                                  = VkStructureType.VK_STRUCTURE_TYPE_IMAGE_VIEW_USAGE_CREATE_INFO_KHR;
enum VK_STRUCTURE_TYPE_PIPELINE_TESSELLATION_DOMAIN_ORIGIN_STATE_CREATE_INFO_KHR         = VkStructureType.VK_STRUCTURE_TYPE_PIPELINE_TESSELLATION_DOMAIN_ORIGIN_STATE_CREATE_INFO_KHR;
enum VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_VARIABLE_POINTER_FEATURES_KHR                     = VkStructureType.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_VARIABLE_POINTER_FEATURES_KHR;
enum VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_VARIABLE_POINTERS_FEATURES_KHR                    = VkStructureType.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_VARIABLE_POINTERS_FEATURES_KHR;
enum VK_STRUCTURE_TYPE_MEMORY_DEDICATED_REQUIREMENTS_KHR                                 = VkStructureType.VK_STRUCTURE_TYPE_MEMORY_DEDICATED_REQUIREMENTS_KHR;
enum VK_STRUCTURE_TYPE_MEMORY_DEDICATED_ALLOCATE_INFO_KHR                                = VkStructureType.VK_STRUCTURE_TYPE_MEMORY_DEDICATED_ALLOCATE_INFO_KHR;
enum VK_STRUCTURE_TYPE_BUFFER_MEMORY_REQUIREMENTS_INFO_2_KHR                             = VkStructureType.VK_STRUCTURE_TYPE_BUFFER_MEMORY_REQUIREMENTS_INFO_2_KHR;
enum VK_STRUCTURE_TYPE_IMAGE_MEMORY_REQUIREMENTS_INFO_2_KHR                              = VkStructureType.VK_STRUCTURE_TYPE_IMAGE_MEMORY_REQUIREMENTS_INFO_2_KHR;
enum VK_STRUCTURE_TYPE_IMAGE_SPARSE_MEMORY_REQUIREMENTS_INFO_2_KHR                       = VkStructureType.VK_STRUCTURE_TYPE_IMAGE_SPARSE_MEMORY_REQUIREMENTS_INFO_2_KHR;
enum VK_STRUCTURE_TYPE_MEMORY_REQUIREMENTS_2_KHR                                         = VkStructureType.VK_STRUCTURE_TYPE_MEMORY_REQUIREMENTS_2_KHR;
enum VK_STRUCTURE_TYPE_SPARSE_IMAGE_MEMORY_REQUIREMENTS_2_KHR                            = VkStructureType.VK_STRUCTURE_TYPE_SPARSE_IMAGE_MEMORY_REQUIREMENTS_2_KHR;
enum VK_STRUCTURE_TYPE_SAMPLER_YCBCR_CONVERSION_CREATE_INFO_KHR                          = VkStructureType.VK_STRUCTURE_TYPE_SAMPLER_YCBCR_CONVERSION_CREATE_INFO_KHR;
enum VK_STRUCTURE_TYPE_SAMPLER_YCBCR_CONVERSION_INFO_KHR                                 = VkStructureType.VK_STRUCTURE_TYPE_SAMPLER_YCBCR_CONVERSION_INFO_KHR;
enum VK_STRUCTURE_TYPE_BIND_IMAGE_PLANE_MEMORY_INFO_KHR                                  = VkStructureType.VK_STRUCTURE_TYPE_BIND_IMAGE_PLANE_MEMORY_INFO_KHR;
enum VK_STRUCTURE_TYPE_IMAGE_PLANE_MEMORY_REQUIREMENTS_INFO_KHR                          = VkStructureType.VK_STRUCTURE_TYPE_IMAGE_PLANE_MEMORY_REQUIREMENTS_INFO_KHR;
enum VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_SAMPLER_YCBCR_CONVERSION_FEATURES_KHR             = VkStructureType.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_SAMPLER_YCBCR_CONVERSION_FEATURES_KHR;
enum VK_STRUCTURE_TYPE_SAMPLER_YCBCR_CONVERSION_IMAGE_FORMAT_PROPERTIES_KHR              = VkStructureType.VK_STRUCTURE_TYPE_SAMPLER_YCBCR_CONVERSION_IMAGE_FORMAT_PROPERTIES_KHR;
enum VK_STRUCTURE_TYPE_BIND_BUFFER_MEMORY_INFO_KHR                                       = VkStructureType.VK_STRUCTURE_TYPE_BIND_BUFFER_MEMORY_INFO_KHR;
enum VK_STRUCTURE_TYPE_BIND_IMAGE_MEMORY_INFO_KHR                                        = VkStructureType.VK_STRUCTURE_TYPE_BIND_IMAGE_MEMORY_INFO_KHR;
enum VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_MAINTENANCE_3_PROPERTIES_KHR                      = VkStructureType.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_MAINTENANCE_3_PROPERTIES_KHR;
enum VK_STRUCTURE_TYPE_DESCRIPTOR_SET_LAYOUT_SUPPORT_KHR                                 = VkStructureType.VK_STRUCTURE_TYPE_DESCRIPTOR_SET_LAYOUT_SUPPORT_KHR;
enum VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_BUFFER_ADDRESS_FEATURES_EXT                       = VkStructureType.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_BUFFER_ADDRESS_FEATURES_EXT;
enum VK_STRUCTURE_TYPE_BEGIN_RANGE                                                       = VkStructureType.VK_STRUCTURE_TYPE_BEGIN_RANGE;
enum VK_STRUCTURE_TYPE_END_RANGE                                                         = VkStructureType.VK_STRUCTURE_TYPE_END_RANGE;
enum VK_STRUCTURE_TYPE_RANGE_SIZE                                                        = VkStructureType.VK_STRUCTURE_TYPE_RANGE_SIZE;
enum VK_STRUCTURE_TYPE_MAX_ENUM                                                          = VkStructureType.VK_STRUCTURE_TYPE_MAX_ENUM;

enum VkSystemAllocationScope {
    VK_SYSTEM_ALLOCATION_SCOPE_COMMAND           = 0,
    VK_SYSTEM_ALLOCATION_SCOPE_OBJECT            = 1,
    VK_SYSTEM_ALLOCATION_SCOPE_CACHE             = 2,
    VK_SYSTEM_ALLOCATION_SCOPE_DEVICE            = 3,
    VK_SYSTEM_ALLOCATION_SCOPE_INSTANCE          = 4,
    VK_SYSTEM_ALLOCATION_SCOPE_BEGIN_RANGE       = VK_SYSTEM_ALLOCATION_SCOPE_COMMAND,
    VK_SYSTEM_ALLOCATION_SCOPE_END_RANGE         = VK_SYSTEM_ALLOCATION_SCOPE_INSTANCE,
    VK_SYSTEM_ALLOCATION_SCOPE_RANGE_SIZE        = VK_SYSTEM_ALLOCATION_SCOPE_INSTANCE - VK_SYSTEM_ALLOCATION_SCOPE_COMMAND + 1,
    VK_SYSTEM_ALLOCATION_SCOPE_MAX_ENUM          = 0x7FFFFFFF
}

enum VK_SYSTEM_ALLOCATION_SCOPE_COMMAND          = VkSystemAllocationScope.VK_SYSTEM_ALLOCATION_SCOPE_COMMAND;
enum VK_SYSTEM_ALLOCATION_SCOPE_OBJECT           = VkSystemAllocationScope.VK_SYSTEM_ALLOCATION_SCOPE_OBJECT;
enum VK_SYSTEM_ALLOCATION_SCOPE_CACHE            = VkSystemAllocationScope.VK_SYSTEM_ALLOCATION_SCOPE_CACHE;
enum VK_SYSTEM_ALLOCATION_SCOPE_DEVICE           = VkSystemAllocationScope.VK_SYSTEM_ALLOCATION_SCOPE_DEVICE;
enum VK_SYSTEM_ALLOCATION_SCOPE_INSTANCE         = VkSystemAllocationScope.VK_SYSTEM_ALLOCATION_SCOPE_INSTANCE;
enum VK_SYSTEM_ALLOCATION_SCOPE_BEGIN_RANGE      = VkSystemAllocationScope.VK_SYSTEM_ALLOCATION_SCOPE_BEGIN_RANGE;
enum VK_SYSTEM_ALLOCATION_SCOPE_END_RANGE        = VkSystemAllocationScope.VK_SYSTEM_ALLOCATION_SCOPE_END_RANGE;
enum VK_SYSTEM_ALLOCATION_SCOPE_RANGE_SIZE       = VkSystemAllocationScope.VK_SYSTEM_ALLOCATION_SCOPE_RANGE_SIZE;
enum VK_SYSTEM_ALLOCATION_SCOPE_MAX_ENUM         = VkSystemAllocationScope.VK_SYSTEM_ALLOCATION_SCOPE_MAX_ENUM;

enum VkInternalAllocationType {
    VK_INTERNAL_ALLOCATION_TYPE_EXECUTABLE       = 0,
    VK_INTERNAL_ALLOCATION_TYPE_BEGIN_RANGE      = VK_INTERNAL_ALLOCATION_TYPE_EXECUTABLE,
    VK_INTERNAL_ALLOCATION_TYPE_END_RANGE        = VK_INTERNAL_ALLOCATION_TYPE_EXECUTABLE,
    VK_INTERNAL_ALLOCATION_TYPE_RANGE_SIZE       = VK_INTERNAL_ALLOCATION_TYPE_EXECUTABLE - VK_INTERNAL_ALLOCATION_TYPE_EXECUTABLE + 1,
    VK_INTERNAL_ALLOCATION_TYPE_MAX_ENUM         = 0x7FFFFFFF
}

enum VK_INTERNAL_ALLOCATION_TYPE_EXECUTABLE      = VkInternalAllocationType.VK_INTERNAL_ALLOCATION_TYPE_EXECUTABLE;
enum VK_INTERNAL_ALLOCATION_TYPE_BEGIN_RANGE     = VkInternalAllocationType.VK_INTERNAL_ALLOCATION_TYPE_BEGIN_RANGE;
enum VK_INTERNAL_ALLOCATION_TYPE_END_RANGE       = VkInternalAllocationType.VK_INTERNAL_ALLOCATION_TYPE_END_RANGE;
enum VK_INTERNAL_ALLOCATION_TYPE_RANGE_SIZE      = VkInternalAllocationType.VK_INTERNAL_ALLOCATION_TYPE_RANGE_SIZE;
enum VK_INTERNAL_ALLOCATION_TYPE_MAX_ENUM        = VkInternalAllocationType.VK_INTERNAL_ALLOCATION_TYPE_MAX_ENUM;

enum VkFormat {
    VK_FORMAT_UNDEFINED                                          = 0,
    VK_FORMAT_R4G4_UNORM_PACK8                                   = 1,
    VK_FORMAT_R4G4B4A4_UNORM_PACK16                              = 2,
    VK_FORMAT_B4G4R4A4_UNORM_PACK16                              = 3,
    VK_FORMAT_R5G6B5_UNORM_PACK16                                = 4,
    VK_FORMAT_B5G6R5_UNORM_PACK16                                = 5,
    VK_FORMAT_R5G5B5A1_UNORM_PACK16                              = 6,
    VK_FORMAT_B5G5R5A1_UNORM_PACK16                              = 7,
    VK_FORMAT_A1R5G5B5_UNORM_PACK16                              = 8,
    VK_FORMAT_R8_UNORM                                           = 9,
    VK_FORMAT_R8_SNORM                                           = 10,
    VK_FORMAT_R8_USCALED                                         = 11,
    VK_FORMAT_R8_SSCALED                                         = 12,
    VK_FORMAT_R8_UINT                                            = 13,
    VK_FORMAT_R8_SINT                                            = 14,
    VK_FORMAT_R8_SRGB                                            = 15,
    VK_FORMAT_R8G8_UNORM                                         = 16,
    VK_FORMAT_R8G8_SNORM                                         = 17,
    VK_FORMAT_R8G8_USCALED                                       = 18,
    VK_FORMAT_R8G8_SSCALED                                       = 19,
    VK_FORMAT_R8G8_UINT                                          = 20,
    VK_FORMAT_R8G8_SINT                                          = 21,
    VK_FORMAT_R8G8_SRGB                                          = 22,
    VK_FORMAT_R8G8B8_UNORM                                       = 23,
    VK_FORMAT_R8G8B8_SNORM                                       = 24,
    VK_FORMAT_R8G8B8_USCALED                                     = 25,
    VK_FORMAT_R8G8B8_SSCALED                                     = 26,
    VK_FORMAT_R8G8B8_UINT                                        = 27,
    VK_FORMAT_R8G8B8_SINT                                        = 28,
    VK_FORMAT_R8G8B8_SRGB                                        = 29,
    VK_FORMAT_B8G8R8_UNORM                                       = 30,
    VK_FORMAT_B8G8R8_SNORM                                       = 31,
    VK_FORMAT_B8G8R8_USCALED                                     = 32,
    VK_FORMAT_B8G8R8_SSCALED                                     = 33,
    VK_FORMAT_B8G8R8_UINT                                        = 34,
    VK_FORMAT_B8G8R8_SINT                                        = 35,
    VK_FORMAT_B8G8R8_SRGB                                        = 36,
    VK_FORMAT_R8G8B8A8_UNORM                                     = 37,
    VK_FORMAT_R8G8B8A8_SNORM                                     = 38,
    VK_FORMAT_R8G8B8A8_USCALED                                   = 39,
    VK_FORMAT_R8G8B8A8_SSCALED                                   = 40,
    VK_FORMAT_R8G8B8A8_UINT                                      = 41,
    VK_FORMAT_R8G8B8A8_SINT                                      = 42,
    VK_FORMAT_R8G8B8A8_SRGB                                      = 43,
    VK_FORMAT_B8G8R8A8_UNORM                                     = 44,
    VK_FORMAT_B8G8R8A8_SNORM                                     = 45,
    VK_FORMAT_B8G8R8A8_USCALED                                   = 46,
    VK_FORMAT_B8G8R8A8_SSCALED                                   = 47,
    VK_FORMAT_B8G8R8A8_UINT                                      = 48,
    VK_FORMAT_B8G8R8A8_SINT                                      = 49,
    VK_FORMAT_B8G8R8A8_SRGB                                      = 50,
    VK_FORMAT_A8B8G8R8_UNORM_PACK32                              = 51,
    VK_FORMAT_A8B8G8R8_SNORM_PACK32                              = 52,
    VK_FORMAT_A8B8G8R8_USCALED_PACK32                            = 53,
    VK_FORMAT_A8B8G8R8_SSCALED_PACK32                            = 54,
    VK_FORMAT_A8B8G8R8_UINT_PACK32                               = 55,
    VK_FORMAT_A8B8G8R8_SINT_PACK32                               = 56,
    VK_FORMAT_A8B8G8R8_SRGB_PACK32                               = 57,
    VK_FORMAT_A2R10G10B10_UNORM_PACK32                           = 58,
    VK_FORMAT_A2R10G10B10_SNORM_PACK32                           = 59,
    VK_FORMAT_A2R10G10B10_USCALED_PACK32                         = 60,
    VK_FORMAT_A2R10G10B10_SSCALED_PACK32                         = 61,
    VK_FORMAT_A2R10G10B10_UINT_PACK32                            = 62,
    VK_FORMAT_A2R10G10B10_SINT_PACK32                            = 63,
    VK_FORMAT_A2B10G10R10_UNORM_PACK32                           = 64,
    VK_FORMAT_A2B10G10R10_SNORM_PACK32                           = 65,
    VK_FORMAT_A2B10G10R10_USCALED_PACK32                         = 66,
    VK_FORMAT_A2B10G10R10_SSCALED_PACK32                         = 67,
    VK_FORMAT_A2B10G10R10_UINT_PACK32                            = 68,
    VK_FORMAT_A2B10G10R10_SINT_PACK32                            = 69,
    VK_FORMAT_R16_UNORM                                          = 70,
    VK_FORMAT_R16_SNORM                                          = 71,
    VK_FORMAT_R16_USCALED                                        = 72,
    VK_FORMAT_R16_SSCALED                                        = 73,
    VK_FORMAT_R16_UINT                                           = 74,
    VK_FORMAT_R16_SINT                                           = 75,
    VK_FORMAT_R16_SFLOAT                                         = 76,
    VK_FORMAT_R16G16_UNORM                                       = 77,
    VK_FORMAT_R16G16_SNORM                                       = 78,
    VK_FORMAT_R16G16_USCALED                                     = 79,
    VK_FORMAT_R16G16_SSCALED                                     = 80,
    VK_FORMAT_R16G16_UINT                                        = 81,
    VK_FORMAT_R16G16_SINT                                        = 82,
    VK_FORMAT_R16G16_SFLOAT                                      = 83,
    VK_FORMAT_R16G16B16_UNORM                                    = 84,
    VK_FORMAT_R16G16B16_SNORM                                    = 85,
    VK_FORMAT_R16G16B16_USCALED                                  = 86,
    VK_FORMAT_R16G16B16_SSCALED                                  = 87,
    VK_FORMAT_R16G16B16_UINT                                     = 88,
    VK_FORMAT_R16G16B16_SINT                                     = 89,
    VK_FORMAT_R16G16B16_SFLOAT                                   = 90,
    VK_FORMAT_R16G16B16A16_UNORM                                 = 91,
    VK_FORMAT_R16G16B16A16_SNORM                                 = 92,
    VK_FORMAT_R16G16B16A16_USCALED                               = 93,
    VK_FORMAT_R16G16B16A16_SSCALED                               = 94,
    VK_FORMAT_R16G16B16A16_UINT                                  = 95,
    VK_FORMAT_R16G16B16A16_SINT                                  = 96,
    VK_FORMAT_R16G16B16A16_SFLOAT                                = 97,
    VK_FORMAT_R32_UINT                                           = 98,
    VK_FORMAT_R32_SINT                                           = 99,
    VK_FORMAT_R32_SFLOAT                                         = 100,
    VK_FORMAT_R32G32_UINT                                        = 101,
    VK_FORMAT_R32G32_SINT                                        = 102,
    VK_FORMAT_R32G32_SFLOAT                                      = 103,
    VK_FORMAT_R32G32B32_UINT                                     = 104,
    VK_FORMAT_R32G32B32_SINT                                     = 105,
    VK_FORMAT_R32G32B32_SFLOAT                                   = 106,
    VK_FORMAT_R32G32B32A32_UINT                                  = 107,
    VK_FORMAT_R32G32B32A32_SINT                                  = 108,
    VK_FORMAT_R32G32B32A32_SFLOAT                                = 109,
    VK_FORMAT_R64_UINT                                           = 110,
    VK_FORMAT_R64_SINT                                           = 111,
    VK_FORMAT_R64_SFLOAT                                         = 112,
    VK_FORMAT_R64G64_UINT                                        = 113,
    VK_FORMAT_R64G64_SINT                                        = 114,
    VK_FORMAT_R64G64_SFLOAT                                      = 115,
    VK_FORMAT_R64G64B64_UINT                                     = 116,
    VK_FORMAT_R64G64B64_SINT                                     = 117,
    VK_FORMAT_R64G64B64_SFLOAT                                   = 118,
    VK_FORMAT_R64G64B64A64_UINT                                  = 119,
    VK_FORMAT_R64G64B64A64_SINT                                  = 120,
    VK_FORMAT_R64G64B64A64_SFLOAT                                = 121,
    VK_FORMAT_B10G11R11_UFLOAT_PACK32                            = 122,
    VK_FORMAT_E5B9G9R9_UFLOAT_PACK32                             = 123,
    VK_FORMAT_D16_UNORM                                          = 124,
    VK_FORMAT_X8_D24_UNORM_PACK32                                = 125,
    VK_FORMAT_D32_SFLOAT                                         = 126,
    VK_FORMAT_S8_UINT                                            = 127,
    VK_FORMAT_D16_UNORM_S8_UINT                                  = 128,
    VK_FORMAT_D24_UNORM_S8_UINT                                  = 129,
    VK_FORMAT_D32_SFLOAT_S8_UINT                                 = 130,
    VK_FORMAT_BC1_RGB_UNORM_BLOCK                                = 131,
    VK_FORMAT_BC1_RGB_SRGB_BLOCK                                 = 132,
    VK_FORMAT_BC1_RGBA_UNORM_BLOCK                               = 133,
    VK_FORMAT_BC1_RGBA_SRGB_BLOCK                                = 134,
    VK_FORMAT_BC2_UNORM_BLOCK                                    = 135,
    VK_FORMAT_BC2_SRGB_BLOCK                                     = 136,
    VK_FORMAT_BC3_UNORM_BLOCK                                    = 137,
    VK_FORMAT_BC3_SRGB_BLOCK                                     = 138,
    VK_FORMAT_BC4_UNORM_BLOCK                                    = 139,
    VK_FORMAT_BC4_SNORM_BLOCK                                    = 140,
    VK_FORMAT_BC5_UNORM_BLOCK                                    = 141,
    VK_FORMAT_BC5_SNORM_BLOCK                                    = 142,
    VK_FORMAT_BC6H_UFLOAT_BLOCK                                  = 143,
    VK_FORMAT_BC6H_SFLOAT_BLOCK                                  = 144,
    VK_FORMAT_BC7_UNORM_BLOCK                                    = 145,
    VK_FORMAT_BC7_SRGB_BLOCK                                     = 146,
    VK_FORMAT_ETC2_R8G8B8_UNORM_BLOCK                            = 147,
    VK_FORMAT_ETC2_R8G8B8_SRGB_BLOCK                             = 148,
    VK_FORMAT_ETC2_R8G8B8A1_UNORM_BLOCK                          = 149,
    VK_FORMAT_ETC2_R8G8B8A1_SRGB_BLOCK                           = 150,
    VK_FORMAT_ETC2_R8G8B8A8_UNORM_BLOCK                          = 151,
    VK_FORMAT_ETC2_R8G8B8A8_SRGB_BLOCK                           = 152,
    VK_FORMAT_EAC_R11_UNORM_BLOCK                                = 153,
    VK_FORMAT_EAC_R11_SNORM_BLOCK                                = 154,
    VK_FORMAT_EAC_R11G11_UNORM_BLOCK                             = 155,
    VK_FORMAT_EAC_R11G11_SNORM_BLOCK                             = 156,
    VK_FORMAT_ASTC_4x4_UNORM_BLOCK                               = 157,
    VK_FORMAT_ASTC_4x4_SRGB_BLOCK                                = 158,
    VK_FORMAT_ASTC_5x4_UNORM_BLOCK                               = 159,
    VK_FORMAT_ASTC_5x4_SRGB_BLOCK                                = 160,
    VK_FORMAT_ASTC_5x5_UNORM_BLOCK                               = 161,
    VK_FORMAT_ASTC_5x5_SRGB_BLOCK                                = 162,
    VK_FORMAT_ASTC_6x5_UNORM_BLOCK                               = 163,
    VK_FORMAT_ASTC_6x5_SRGB_BLOCK                                = 164,
    VK_FORMAT_ASTC_6x6_UNORM_BLOCK                               = 165,
    VK_FORMAT_ASTC_6x6_SRGB_BLOCK                                = 166,
    VK_FORMAT_ASTC_8x5_UNORM_BLOCK                               = 167,
    VK_FORMAT_ASTC_8x5_SRGB_BLOCK                                = 168,
    VK_FORMAT_ASTC_8x6_UNORM_BLOCK                               = 169,
    VK_FORMAT_ASTC_8x6_SRGB_BLOCK                                = 170,
    VK_FORMAT_ASTC_8x8_UNORM_BLOCK                               = 171,
    VK_FORMAT_ASTC_8x8_SRGB_BLOCK                                = 172,
    VK_FORMAT_ASTC_10x5_UNORM_BLOCK                              = 173,
    VK_FORMAT_ASTC_10x5_SRGB_BLOCK                               = 174,
    VK_FORMAT_ASTC_10x6_UNORM_BLOCK                              = 175,
    VK_FORMAT_ASTC_10x6_SRGB_BLOCK                               = 176,
    VK_FORMAT_ASTC_10x8_UNORM_BLOCK                              = 177,
    VK_FORMAT_ASTC_10x8_SRGB_BLOCK                               = 178,
    VK_FORMAT_ASTC_10x10_UNORM_BLOCK                             = 179,
    VK_FORMAT_ASTC_10x10_SRGB_BLOCK                              = 180,
    VK_FORMAT_ASTC_12x10_UNORM_BLOCK                             = 181,
    VK_FORMAT_ASTC_12x10_SRGB_BLOCK                              = 182,
    VK_FORMAT_ASTC_12x12_UNORM_BLOCK                             = 183,
    VK_FORMAT_ASTC_12x12_SRGB_BLOCK                              = 184,
    VK_FORMAT_G8B8G8R8_422_UNORM                                 = 1000156000,
    VK_FORMAT_B8G8R8G8_422_UNORM                                 = 1000156001,
    VK_FORMAT_G8_B8_R8_3PLANE_420_UNORM                          = 1000156002,
    VK_FORMAT_G8_B8R8_2PLANE_420_UNORM                           = 1000156003,
    VK_FORMAT_G8_B8_R8_3PLANE_422_UNORM                          = 1000156004,
    VK_FORMAT_G8_B8R8_2PLANE_422_UNORM                           = 1000156005,
    VK_FORMAT_G8_B8_R8_3PLANE_444_UNORM                          = 1000156006,
    VK_FORMAT_R10X6_UNORM_PACK16                                 = 1000156007,
    VK_FORMAT_R10X6G10X6_UNORM_2PACK16                           = 1000156008,
    VK_FORMAT_R10X6G10X6B10X6A10X6_UNORM_4PACK16                 = 1000156009,
    VK_FORMAT_G10X6B10X6G10X6R10X6_422_UNORM_4PACK16             = 1000156010,
    VK_FORMAT_B10X6G10X6R10X6G10X6_422_UNORM_4PACK16             = 1000156011,
    VK_FORMAT_G10X6_B10X6_R10X6_3PLANE_420_UNORM_3PACK16         = 1000156012,
    VK_FORMAT_G10X6_B10X6R10X6_2PLANE_420_UNORM_3PACK16          = 1000156013,
    VK_FORMAT_G10X6_B10X6_R10X6_3PLANE_422_UNORM_3PACK16         = 1000156014,
    VK_FORMAT_G10X6_B10X6R10X6_2PLANE_422_UNORM_3PACK16          = 1000156015,
    VK_FORMAT_G10X6_B10X6_R10X6_3PLANE_444_UNORM_3PACK16         = 1000156016,
    VK_FORMAT_R12X4_UNORM_PACK16                                 = 1000156017,
    VK_FORMAT_R12X4G12X4_UNORM_2PACK16                           = 1000156018,
    VK_FORMAT_R12X4G12X4B12X4A12X4_UNORM_4PACK16                 = 1000156019,
    VK_FORMAT_G12X4B12X4G12X4R12X4_422_UNORM_4PACK16             = 1000156020,
    VK_FORMAT_B12X4G12X4R12X4G12X4_422_UNORM_4PACK16             = 1000156021,
    VK_FORMAT_G12X4_B12X4_R12X4_3PLANE_420_UNORM_3PACK16         = 1000156022,
    VK_FORMAT_G12X4_B12X4R12X4_2PLANE_420_UNORM_3PACK16          = 1000156023,
    VK_FORMAT_G12X4_B12X4_R12X4_3PLANE_422_UNORM_3PACK16         = 1000156024,
    VK_FORMAT_G12X4_B12X4R12X4_2PLANE_422_UNORM_3PACK16          = 1000156025,
    VK_FORMAT_G12X4_B12X4_R12X4_3PLANE_444_UNORM_3PACK16         = 1000156026,
    VK_FORMAT_G16B16G16R16_422_UNORM                             = 1000156027,
    VK_FORMAT_B16G16R16G16_422_UNORM                             = 1000156028,
    VK_FORMAT_G16_B16_R16_3PLANE_420_UNORM                       = 1000156029,
    VK_FORMAT_G16_B16R16_2PLANE_420_UNORM                        = 1000156030,
    VK_FORMAT_G16_B16_R16_3PLANE_422_UNORM                       = 1000156031,
    VK_FORMAT_G16_B16R16_2PLANE_422_UNORM                        = 1000156032,
    VK_FORMAT_G16_B16_R16_3PLANE_444_UNORM                       = 1000156033,
    VK_FORMAT_PVRTC1_2BPP_UNORM_BLOCK_IMG                        = 1000054000,
    VK_FORMAT_PVRTC1_4BPP_UNORM_BLOCK_IMG                        = 1000054001,
    VK_FORMAT_PVRTC2_2BPP_UNORM_BLOCK_IMG                        = 1000054002,
    VK_FORMAT_PVRTC2_4BPP_UNORM_BLOCK_IMG                        = 1000054003,
    VK_FORMAT_PVRTC1_2BPP_SRGB_BLOCK_IMG                         = 1000054004,
    VK_FORMAT_PVRTC1_4BPP_SRGB_BLOCK_IMG                         = 1000054005,
    VK_FORMAT_PVRTC2_2BPP_SRGB_BLOCK_IMG                         = 1000054006,
    VK_FORMAT_PVRTC2_4BPP_SRGB_BLOCK_IMG                         = 1000054007,
    VK_FORMAT_G8B8G8R8_422_UNORM_KHR                             = VK_FORMAT_G8B8G8R8_422_UNORM,
    VK_FORMAT_B8G8R8G8_422_UNORM_KHR                             = VK_FORMAT_B8G8R8G8_422_UNORM,
    VK_FORMAT_G8_B8_R8_3PLANE_420_UNORM_KHR                      = VK_FORMAT_G8_B8_R8_3PLANE_420_UNORM,
    VK_FORMAT_G8_B8R8_2PLANE_420_UNORM_KHR                       = VK_FORMAT_G8_B8R8_2PLANE_420_UNORM,
    VK_FORMAT_G8_B8_R8_3PLANE_422_UNORM_KHR                      = VK_FORMAT_G8_B8_R8_3PLANE_422_UNORM,
    VK_FORMAT_G8_B8R8_2PLANE_422_UNORM_KHR                       = VK_FORMAT_G8_B8R8_2PLANE_422_UNORM,
    VK_FORMAT_G8_B8_R8_3PLANE_444_UNORM_KHR                      = VK_FORMAT_G8_B8_R8_3PLANE_444_UNORM,
    VK_FORMAT_R10X6_UNORM_PACK16_KHR                             = VK_FORMAT_R10X6_UNORM_PACK16,
    VK_FORMAT_R10X6G10X6_UNORM_2PACK16_KHR                       = VK_FORMAT_R10X6G10X6_UNORM_2PACK16,
    VK_FORMAT_R10X6G10X6B10X6A10X6_UNORM_4PACK16_KHR             = VK_FORMAT_R10X6G10X6B10X6A10X6_UNORM_4PACK16,
    VK_FORMAT_G10X6B10X6G10X6R10X6_422_UNORM_4PACK16_KHR         = VK_FORMAT_G10X6B10X6G10X6R10X6_422_UNORM_4PACK16,
    VK_FORMAT_B10X6G10X6R10X6G10X6_422_UNORM_4PACK16_KHR         = VK_FORMAT_B10X6G10X6R10X6G10X6_422_UNORM_4PACK16,
    VK_FORMAT_G10X6_B10X6_R10X6_3PLANE_420_UNORM_3PACK16_KHR     = VK_FORMAT_G10X6_B10X6_R10X6_3PLANE_420_UNORM_3PACK16,
    VK_FORMAT_G10X6_B10X6R10X6_2PLANE_420_UNORM_3PACK16_KHR      = VK_FORMAT_G10X6_B10X6R10X6_2PLANE_420_UNORM_3PACK16,
    VK_FORMAT_G10X6_B10X6_R10X6_3PLANE_422_UNORM_3PACK16_KHR     = VK_FORMAT_G10X6_B10X6_R10X6_3PLANE_422_UNORM_3PACK16,
    VK_FORMAT_G10X6_B10X6R10X6_2PLANE_422_UNORM_3PACK16_KHR      = VK_FORMAT_G10X6_B10X6R10X6_2PLANE_422_UNORM_3PACK16,
    VK_FORMAT_G10X6_B10X6_R10X6_3PLANE_444_UNORM_3PACK16_KHR     = VK_FORMAT_G10X6_B10X6_R10X6_3PLANE_444_UNORM_3PACK16,
    VK_FORMAT_R12X4_UNORM_PACK16_KHR                             = VK_FORMAT_R12X4_UNORM_PACK16,
    VK_FORMAT_R12X4G12X4_UNORM_2PACK16_KHR                       = VK_FORMAT_R12X4G12X4_UNORM_2PACK16,
    VK_FORMAT_R12X4G12X4B12X4A12X4_UNORM_4PACK16_KHR             = VK_FORMAT_R12X4G12X4B12X4A12X4_UNORM_4PACK16,
    VK_FORMAT_G12X4B12X4G12X4R12X4_422_UNORM_4PACK16_KHR         = VK_FORMAT_G12X4B12X4G12X4R12X4_422_UNORM_4PACK16,
    VK_FORMAT_B12X4G12X4R12X4G12X4_422_UNORM_4PACK16_KHR         = VK_FORMAT_B12X4G12X4R12X4G12X4_422_UNORM_4PACK16,
    VK_FORMAT_G12X4_B12X4_R12X4_3PLANE_420_UNORM_3PACK16_KHR     = VK_FORMAT_G12X4_B12X4_R12X4_3PLANE_420_UNORM_3PACK16,
    VK_FORMAT_G12X4_B12X4R12X4_2PLANE_420_UNORM_3PACK16_KHR      = VK_FORMAT_G12X4_B12X4R12X4_2PLANE_420_UNORM_3PACK16,
    VK_FORMAT_G12X4_B12X4_R12X4_3PLANE_422_UNORM_3PACK16_KHR     = VK_FORMAT_G12X4_B12X4_R12X4_3PLANE_422_UNORM_3PACK16,
    VK_FORMAT_G12X4_B12X4R12X4_2PLANE_422_UNORM_3PACK16_KHR      = VK_FORMAT_G12X4_B12X4R12X4_2PLANE_422_UNORM_3PACK16,
    VK_FORMAT_G12X4_B12X4_R12X4_3PLANE_444_UNORM_3PACK16_KHR     = VK_FORMAT_G12X4_B12X4_R12X4_3PLANE_444_UNORM_3PACK16,
    VK_FORMAT_G16B16G16R16_422_UNORM_KHR                         = VK_FORMAT_G16B16G16R16_422_UNORM,
    VK_FORMAT_B16G16R16G16_422_UNORM_KHR                         = VK_FORMAT_B16G16R16G16_422_UNORM,
    VK_FORMAT_G16_B16_R16_3PLANE_420_UNORM_KHR                   = VK_FORMAT_G16_B16_R16_3PLANE_420_UNORM,
    VK_FORMAT_G16_B16R16_2PLANE_420_UNORM_KHR                    = VK_FORMAT_G16_B16R16_2PLANE_420_UNORM,
    VK_FORMAT_G16_B16_R16_3PLANE_422_UNORM_KHR                   = VK_FORMAT_G16_B16_R16_3PLANE_422_UNORM,
    VK_FORMAT_G16_B16R16_2PLANE_422_UNORM_KHR                    = VK_FORMAT_G16_B16R16_2PLANE_422_UNORM,
    VK_FORMAT_G16_B16_R16_3PLANE_444_UNORM_KHR                   = VK_FORMAT_G16_B16_R16_3PLANE_444_UNORM,
    VK_FORMAT_BEGIN_RANGE                                        = VK_FORMAT_UNDEFINED,
    VK_FORMAT_END_RANGE                                          = VK_FORMAT_ASTC_12x12_SRGB_BLOCK,
    VK_FORMAT_RANGE_SIZE                                         = VK_FORMAT_ASTC_12x12_SRGB_BLOCK - VK_FORMAT_UNDEFINED + 1,
    VK_FORMAT_MAX_ENUM                                           = 0x7FFFFFFF
}

enum VK_FORMAT_UNDEFINED                                         = VkFormat.VK_FORMAT_UNDEFINED;
enum VK_FORMAT_R4G4_UNORM_PACK8                                  = VkFormat.VK_FORMAT_R4G4_UNORM_PACK8;
enum VK_FORMAT_R4G4B4A4_UNORM_PACK16                             = VkFormat.VK_FORMAT_R4G4B4A4_UNORM_PACK16;
enum VK_FORMAT_B4G4R4A4_UNORM_PACK16                             = VkFormat.VK_FORMAT_B4G4R4A4_UNORM_PACK16;
enum VK_FORMAT_R5G6B5_UNORM_PACK16                               = VkFormat.VK_FORMAT_R5G6B5_UNORM_PACK16;
enum VK_FORMAT_B5G6R5_UNORM_PACK16                               = VkFormat.VK_FORMAT_B5G6R5_UNORM_PACK16;
enum VK_FORMAT_R5G5B5A1_UNORM_PACK16                             = VkFormat.VK_FORMAT_R5G5B5A1_UNORM_PACK16;
enum VK_FORMAT_B5G5R5A1_UNORM_PACK16                             = VkFormat.VK_FORMAT_B5G5R5A1_UNORM_PACK16;
enum VK_FORMAT_A1R5G5B5_UNORM_PACK16                             = VkFormat.VK_FORMAT_A1R5G5B5_UNORM_PACK16;
enum VK_FORMAT_R8_UNORM                                          = VkFormat.VK_FORMAT_R8_UNORM;
enum VK_FORMAT_R8_SNORM                                          = VkFormat.VK_FORMAT_R8_SNORM;
enum VK_FORMAT_R8_USCALED                                        = VkFormat.VK_FORMAT_R8_USCALED;
enum VK_FORMAT_R8_SSCALED                                        = VkFormat.VK_FORMAT_R8_SSCALED;
enum VK_FORMAT_R8_UINT                                           = VkFormat.VK_FORMAT_R8_UINT;
enum VK_FORMAT_R8_SINT                                           = VkFormat.VK_FORMAT_R8_SINT;
enum VK_FORMAT_R8_SRGB                                           = VkFormat.VK_FORMAT_R8_SRGB;
enum VK_FORMAT_R8G8_UNORM                                        = VkFormat.VK_FORMAT_R8G8_UNORM;
enum VK_FORMAT_R8G8_SNORM                                        = VkFormat.VK_FORMAT_R8G8_SNORM;
enum VK_FORMAT_R8G8_USCALED                                      = VkFormat.VK_FORMAT_R8G8_USCALED;
enum VK_FORMAT_R8G8_SSCALED                                      = VkFormat.VK_FORMAT_R8G8_SSCALED;
enum VK_FORMAT_R8G8_UINT                                         = VkFormat.VK_FORMAT_R8G8_UINT;
enum VK_FORMAT_R8G8_SINT                                         = VkFormat.VK_FORMAT_R8G8_SINT;
enum VK_FORMAT_R8G8_SRGB                                         = VkFormat.VK_FORMAT_R8G8_SRGB;
enum VK_FORMAT_R8G8B8_UNORM                                      = VkFormat.VK_FORMAT_R8G8B8_UNORM;
enum VK_FORMAT_R8G8B8_SNORM                                      = VkFormat.VK_FORMAT_R8G8B8_SNORM;
enum VK_FORMAT_R8G8B8_USCALED                                    = VkFormat.VK_FORMAT_R8G8B8_USCALED;
enum VK_FORMAT_R8G8B8_SSCALED                                    = VkFormat.VK_FORMAT_R8G8B8_SSCALED;
enum VK_FORMAT_R8G8B8_UINT                                       = VkFormat.VK_FORMAT_R8G8B8_UINT;
enum VK_FORMAT_R8G8B8_SINT                                       = VkFormat.VK_FORMAT_R8G8B8_SINT;
enum VK_FORMAT_R8G8B8_SRGB                                       = VkFormat.VK_FORMAT_R8G8B8_SRGB;
enum VK_FORMAT_B8G8R8_UNORM                                      = VkFormat.VK_FORMAT_B8G8R8_UNORM;
enum VK_FORMAT_B8G8R8_SNORM                                      = VkFormat.VK_FORMAT_B8G8R8_SNORM;
enum VK_FORMAT_B8G8R8_USCALED                                    = VkFormat.VK_FORMAT_B8G8R8_USCALED;
enum VK_FORMAT_B8G8R8_SSCALED                                    = VkFormat.VK_FORMAT_B8G8R8_SSCALED;
enum VK_FORMAT_B8G8R8_UINT                                       = VkFormat.VK_FORMAT_B8G8R8_UINT;
enum VK_FORMAT_B8G8R8_SINT                                       = VkFormat.VK_FORMAT_B8G8R8_SINT;
enum VK_FORMAT_B8G8R8_SRGB                                       = VkFormat.VK_FORMAT_B8G8R8_SRGB;
enum VK_FORMAT_R8G8B8A8_UNORM                                    = VkFormat.VK_FORMAT_R8G8B8A8_UNORM;
enum VK_FORMAT_R8G8B8A8_SNORM                                    = VkFormat.VK_FORMAT_R8G8B8A8_SNORM;
enum VK_FORMAT_R8G8B8A8_USCALED                                  = VkFormat.VK_FORMAT_R8G8B8A8_USCALED;
enum VK_FORMAT_R8G8B8A8_SSCALED                                  = VkFormat.VK_FORMAT_R8G8B8A8_SSCALED;
enum VK_FORMAT_R8G8B8A8_UINT                                     = VkFormat.VK_FORMAT_R8G8B8A8_UINT;
enum VK_FORMAT_R8G8B8A8_SINT                                     = VkFormat.VK_FORMAT_R8G8B8A8_SINT;
enum VK_FORMAT_R8G8B8A8_SRGB                                     = VkFormat.VK_FORMAT_R8G8B8A8_SRGB;
enum VK_FORMAT_B8G8R8A8_UNORM                                    = VkFormat.VK_FORMAT_B8G8R8A8_UNORM;
enum VK_FORMAT_B8G8R8A8_SNORM                                    = VkFormat.VK_FORMAT_B8G8R8A8_SNORM;
enum VK_FORMAT_B8G8R8A8_USCALED                                  = VkFormat.VK_FORMAT_B8G8R8A8_USCALED;
enum VK_FORMAT_B8G8R8A8_SSCALED                                  = VkFormat.VK_FORMAT_B8G8R8A8_SSCALED;
enum VK_FORMAT_B8G8R8A8_UINT                                     = VkFormat.VK_FORMAT_B8G8R8A8_UINT;
enum VK_FORMAT_B8G8R8A8_SINT                                     = VkFormat.VK_FORMAT_B8G8R8A8_SINT;
enum VK_FORMAT_B8G8R8A8_SRGB                                     = VkFormat.VK_FORMAT_B8G8R8A8_SRGB;
enum VK_FORMAT_A8B8G8R8_UNORM_PACK32                             = VkFormat.VK_FORMAT_A8B8G8R8_UNORM_PACK32;
enum VK_FORMAT_A8B8G8R8_SNORM_PACK32                             = VkFormat.VK_FORMAT_A8B8G8R8_SNORM_PACK32;
enum VK_FORMAT_A8B8G8R8_USCALED_PACK32                           = VkFormat.VK_FORMAT_A8B8G8R8_USCALED_PACK32;
enum VK_FORMAT_A8B8G8R8_SSCALED_PACK32                           = VkFormat.VK_FORMAT_A8B8G8R8_SSCALED_PACK32;
enum VK_FORMAT_A8B8G8R8_UINT_PACK32                              = VkFormat.VK_FORMAT_A8B8G8R8_UINT_PACK32;
enum VK_FORMAT_A8B8G8R8_SINT_PACK32                              = VkFormat.VK_FORMAT_A8B8G8R8_SINT_PACK32;
enum VK_FORMAT_A8B8G8R8_SRGB_PACK32                              = VkFormat.VK_FORMAT_A8B8G8R8_SRGB_PACK32;
enum VK_FORMAT_A2R10G10B10_UNORM_PACK32                          = VkFormat.VK_FORMAT_A2R10G10B10_UNORM_PACK32;
enum VK_FORMAT_A2R10G10B10_SNORM_PACK32                          = VkFormat.VK_FORMAT_A2R10G10B10_SNORM_PACK32;
enum VK_FORMAT_A2R10G10B10_USCALED_PACK32                        = VkFormat.VK_FORMAT_A2R10G10B10_USCALED_PACK32;
enum VK_FORMAT_A2R10G10B10_SSCALED_PACK32                        = VkFormat.VK_FORMAT_A2R10G10B10_SSCALED_PACK32;
enum VK_FORMAT_A2R10G10B10_UINT_PACK32                           = VkFormat.VK_FORMAT_A2R10G10B10_UINT_PACK32;
enum VK_FORMAT_A2R10G10B10_SINT_PACK32                           = VkFormat.VK_FORMAT_A2R10G10B10_SINT_PACK32;
enum VK_FORMAT_A2B10G10R10_UNORM_PACK32                          = VkFormat.VK_FORMAT_A2B10G10R10_UNORM_PACK32;
enum VK_FORMAT_A2B10G10R10_SNORM_PACK32                          = VkFormat.VK_FORMAT_A2B10G10R10_SNORM_PACK32;
enum VK_FORMAT_A2B10G10R10_USCALED_PACK32                        = VkFormat.VK_FORMAT_A2B10G10R10_USCALED_PACK32;
enum VK_FORMAT_A2B10G10R10_SSCALED_PACK32                        = VkFormat.VK_FORMAT_A2B10G10R10_SSCALED_PACK32;
enum VK_FORMAT_A2B10G10R10_UINT_PACK32                           = VkFormat.VK_FORMAT_A2B10G10R10_UINT_PACK32;
enum VK_FORMAT_A2B10G10R10_SINT_PACK32                           = VkFormat.VK_FORMAT_A2B10G10R10_SINT_PACK32;
enum VK_FORMAT_R16_UNORM                                         = VkFormat.VK_FORMAT_R16_UNORM;
enum VK_FORMAT_R16_SNORM                                         = VkFormat.VK_FORMAT_R16_SNORM;
enum VK_FORMAT_R16_USCALED                                       = VkFormat.VK_FORMAT_R16_USCALED;
enum VK_FORMAT_R16_SSCALED                                       = VkFormat.VK_FORMAT_R16_SSCALED;
enum VK_FORMAT_R16_UINT                                          = VkFormat.VK_FORMAT_R16_UINT;
enum VK_FORMAT_R16_SINT                                          = VkFormat.VK_FORMAT_R16_SINT;
enum VK_FORMAT_R16_SFLOAT                                        = VkFormat.VK_FORMAT_R16_SFLOAT;
enum VK_FORMAT_R16G16_UNORM                                      = VkFormat.VK_FORMAT_R16G16_UNORM;
enum VK_FORMAT_R16G16_SNORM                                      = VkFormat.VK_FORMAT_R16G16_SNORM;
enum VK_FORMAT_R16G16_USCALED                                    = VkFormat.VK_FORMAT_R16G16_USCALED;
enum VK_FORMAT_R16G16_SSCALED                                    = VkFormat.VK_FORMAT_R16G16_SSCALED;
enum VK_FORMAT_R16G16_UINT                                       = VkFormat.VK_FORMAT_R16G16_UINT;
enum VK_FORMAT_R16G16_SINT                                       = VkFormat.VK_FORMAT_R16G16_SINT;
enum VK_FORMAT_R16G16_SFLOAT                                     = VkFormat.VK_FORMAT_R16G16_SFLOAT;
enum VK_FORMAT_R16G16B16_UNORM                                   = VkFormat.VK_FORMAT_R16G16B16_UNORM;
enum VK_FORMAT_R16G16B16_SNORM                                   = VkFormat.VK_FORMAT_R16G16B16_SNORM;
enum VK_FORMAT_R16G16B16_USCALED                                 = VkFormat.VK_FORMAT_R16G16B16_USCALED;
enum VK_FORMAT_R16G16B16_SSCALED                                 = VkFormat.VK_FORMAT_R16G16B16_SSCALED;
enum VK_FORMAT_R16G16B16_UINT                                    = VkFormat.VK_FORMAT_R16G16B16_UINT;
enum VK_FORMAT_R16G16B16_SINT                                    = VkFormat.VK_FORMAT_R16G16B16_SINT;
enum VK_FORMAT_R16G16B16_SFLOAT                                  = VkFormat.VK_FORMAT_R16G16B16_SFLOAT;
enum VK_FORMAT_R16G16B16A16_UNORM                                = VkFormat.VK_FORMAT_R16G16B16A16_UNORM;
enum VK_FORMAT_R16G16B16A16_SNORM                                = VkFormat.VK_FORMAT_R16G16B16A16_SNORM;
enum VK_FORMAT_R16G16B16A16_USCALED                              = VkFormat.VK_FORMAT_R16G16B16A16_USCALED;
enum VK_FORMAT_R16G16B16A16_SSCALED                              = VkFormat.VK_FORMAT_R16G16B16A16_SSCALED;
enum VK_FORMAT_R16G16B16A16_UINT                                 = VkFormat.VK_FORMAT_R16G16B16A16_UINT;
enum VK_FORMAT_R16G16B16A16_SINT                                 = VkFormat.VK_FORMAT_R16G16B16A16_SINT;
enum VK_FORMAT_R16G16B16A16_SFLOAT                               = VkFormat.VK_FORMAT_R16G16B16A16_SFLOAT;
enum VK_FORMAT_R32_UINT                                          = VkFormat.VK_FORMAT_R32_UINT;
enum VK_FORMAT_R32_SINT                                          = VkFormat.VK_FORMAT_R32_SINT;
enum VK_FORMAT_R32_SFLOAT                                        = VkFormat.VK_FORMAT_R32_SFLOAT;
enum VK_FORMAT_R32G32_UINT                                       = VkFormat.VK_FORMAT_R32G32_UINT;
enum VK_FORMAT_R32G32_SINT                                       = VkFormat.VK_FORMAT_R32G32_SINT;
enum VK_FORMAT_R32G32_SFLOAT                                     = VkFormat.VK_FORMAT_R32G32_SFLOAT;
enum VK_FORMAT_R32G32B32_UINT                                    = VkFormat.VK_FORMAT_R32G32B32_UINT;
enum VK_FORMAT_R32G32B32_SINT                                    = VkFormat.VK_FORMAT_R32G32B32_SINT;
enum VK_FORMAT_R32G32B32_SFLOAT                                  = VkFormat.VK_FORMAT_R32G32B32_SFLOAT;
enum VK_FORMAT_R32G32B32A32_UINT                                 = VkFormat.VK_FORMAT_R32G32B32A32_UINT;
enum VK_FORMAT_R32G32B32A32_SINT                                 = VkFormat.VK_FORMAT_R32G32B32A32_SINT;
enum VK_FORMAT_R32G32B32A32_SFLOAT                               = VkFormat.VK_FORMAT_R32G32B32A32_SFLOAT;
enum VK_FORMAT_R64_UINT                                          = VkFormat.VK_FORMAT_R64_UINT;
enum VK_FORMAT_R64_SINT                                          = VkFormat.VK_FORMAT_R64_SINT;
enum VK_FORMAT_R64_SFLOAT                                        = VkFormat.VK_FORMAT_R64_SFLOAT;
enum VK_FORMAT_R64G64_UINT                                       = VkFormat.VK_FORMAT_R64G64_UINT;
enum VK_FORMAT_R64G64_SINT                                       = VkFormat.VK_FORMAT_R64G64_SINT;
enum VK_FORMAT_R64G64_SFLOAT                                     = VkFormat.VK_FORMAT_R64G64_SFLOAT;
enum VK_FORMAT_R64G64B64_UINT                                    = VkFormat.VK_FORMAT_R64G64B64_UINT;
enum VK_FORMAT_R64G64B64_SINT                                    = VkFormat.VK_FORMAT_R64G64B64_SINT;
enum VK_FORMAT_R64G64B64_SFLOAT                                  = VkFormat.VK_FORMAT_R64G64B64_SFLOAT;
enum VK_FORMAT_R64G64B64A64_UINT                                 = VkFormat.VK_FORMAT_R64G64B64A64_UINT;
enum VK_FORMAT_R64G64B64A64_SINT                                 = VkFormat.VK_FORMAT_R64G64B64A64_SINT;
enum VK_FORMAT_R64G64B64A64_SFLOAT                               = VkFormat.VK_FORMAT_R64G64B64A64_SFLOAT;
enum VK_FORMAT_B10G11R11_UFLOAT_PACK32                           = VkFormat.VK_FORMAT_B10G11R11_UFLOAT_PACK32;
enum VK_FORMAT_E5B9G9R9_UFLOAT_PACK32                            = VkFormat.VK_FORMAT_E5B9G9R9_UFLOAT_PACK32;
enum VK_FORMAT_D16_UNORM                                         = VkFormat.VK_FORMAT_D16_UNORM;
enum VK_FORMAT_X8_D24_UNORM_PACK32                               = VkFormat.VK_FORMAT_X8_D24_UNORM_PACK32;
enum VK_FORMAT_D32_SFLOAT                                        = VkFormat.VK_FORMAT_D32_SFLOAT;
enum VK_FORMAT_S8_UINT                                           = VkFormat.VK_FORMAT_S8_UINT;
enum VK_FORMAT_D16_UNORM_S8_UINT                                 = VkFormat.VK_FORMAT_D16_UNORM_S8_UINT;
enum VK_FORMAT_D24_UNORM_S8_UINT                                 = VkFormat.VK_FORMAT_D24_UNORM_S8_UINT;
enum VK_FORMAT_D32_SFLOAT_S8_UINT                                = VkFormat.VK_FORMAT_D32_SFLOAT_S8_UINT;
enum VK_FORMAT_BC1_RGB_UNORM_BLOCK                               = VkFormat.VK_FORMAT_BC1_RGB_UNORM_BLOCK;
enum VK_FORMAT_BC1_RGB_SRGB_BLOCK                                = VkFormat.VK_FORMAT_BC1_RGB_SRGB_BLOCK;
enum VK_FORMAT_BC1_RGBA_UNORM_BLOCK                              = VkFormat.VK_FORMAT_BC1_RGBA_UNORM_BLOCK;
enum VK_FORMAT_BC1_RGBA_SRGB_BLOCK                               = VkFormat.VK_FORMAT_BC1_RGBA_SRGB_BLOCK;
enum VK_FORMAT_BC2_UNORM_BLOCK                                   = VkFormat.VK_FORMAT_BC2_UNORM_BLOCK;
enum VK_FORMAT_BC2_SRGB_BLOCK                                    = VkFormat.VK_FORMAT_BC2_SRGB_BLOCK;
enum VK_FORMAT_BC3_UNORM_BLOCK                                   = VkFormat.VK_FORMAT_BC3_UNORM_BLOCK;
enum VK_FORMAT_BC3_SRGB_BLOCK                                    = VkFormat.VK_FORMAT_BC3_SRGB_BLOCK;
enum VK_FORMAT_BC4_UNORM_BLOCK                                   = VkFormat.VK_FORMAT_BC4_UNORM_BLOCK;
enum VK_FORMAT_BC4_SNORM_BLOCK                                   = VkFormat.VK_FORMAT_BC4_SNORM_BLOCK;
enum VK_FORMAT_BC5_UNORM_BLOCK                                   = VkFormat.VK_FORMAT_BC5_UNORM_BLOCK;
enum VK_FORMAT_BC5_SNORM_BLOCK                                   = VkFormat.VK_FORMAT_BC5_SNORM_BLOCK;
enum VK_FORMAT_BC6H_UFLOAT_BLOCK                                 = VkFormat.VK_FORMAT_BC6H_UFLOAT_BLOCK;
enum VK_FORMAT_BC6H_SFLOAT_BLOCK                                 = VkFormat.VK_FORMAT_BC6H_SFLOAT_BLOCK;
enum VK_FORMAT_BC7_UNORM_BLOCK                                   = VkFormat.VK_FORMAT_BC7_UNORM_BLOCK;
enum VK_FORMAT_BC7_SRGB_BLOCK                                    = VkFormat.VK_FORMAT_BC7_SRGB_BLOCK;
enum VK_FORMAT_ETC2_R8G8B8_UNORM_BLOCK                           = VkFormat.VK_FORMAT_ETC2_R8G8B8_UNORM_BLOCK;
enum VK_FORMAT_ETC2_R8G8B8_SRGB_BLOCK                            = VkFormat.VK_FORMAT_ETC2_R8G8B8_SRGB_BLOCK;
enum VK_FORMAT_ETC2_R8G8B8A1_UNORM_BLOCK                         = VkFormat.VK_FORMAT_ETC2_R8G8B8A1_UNORM_BLOCK;
enum VK_FORMAT_ETC2_R8G8B8A1_SRGB_BLOCK                          = VkFormat.VK_FORMAT_ETC2_R8G8B8A1_SRGB_BLOCK;
enum VK_FORMAT_ETC2_R8G8B8A8_UNORM_BLOCK                         = VkFormat.VK_FORMAT_ETC2_R8G8B8A8_UNORM_BLOCK;
enum VK_FORMAT_ETC2_R8G8B8A8_SRGB_BLOCK                          = VkFormat.VK_FORMAT_ETC2_R8G8B8A8_SRGB_BLOCK;
enum VK_FORMAT_EAC_R11_UNORM_BLOCK                               = VkFormat.VK_FORMAT_EAC_R11_UNORM_BLOCK;
enum VK_FORMAT_EAC_R11_SNORM_BLOCK                               = VkFormat.VK_FORMAT_EAC_R11_SNORM_BLOCK;
enum VK_FORMAT_EAC_R11G11_UNORM_BLOCK                            = VkFormat.VK_FORMAT_EAC_R11G11_UNORM_BLOCK;
enum VK_FORMAT_EAC_R11G11_SNORM_BLOCK                            = VkFormat.VK_FORMAT_EAC_R11G11_SNORM_BLOCK;
enum VK_FORMAT_ASTC_4x4_UNORM_BLOCK                              = VkFormat.VK_FORMAT_ASTC_4x4_UNORM_BLOCK;
enum VK_FORMAT_ASTC_4x4_SRGB_BLOCK                               = VkFormat.VK_FORMAT_ASTC_4x4_SRGB_BLOCK;
enum VK_FORMAT_ASTC_5x4_UNORM_BLOCK                              = VkFormat.VK_FORMAT_ASTC_5x4_UNORM_BLOCK;
enum VK_FORMAT_ASTC_5x4_SRGB_BLOCK                               = VkFormat.VK_FORMAT_ASTC_5x4_SRGB_BLOCK;
enum VK_FORMAT_ASTC_5x5_UNORM_BLOCK                              = VkFormat.VK_FORMAT_ASTC_5x5_UNORM_BLOCK;
enum VK_FORMAT_ASTC_5x5_SRGB_BLOCK                               = VkFormat.VK_FORMAT_ASTC_5x5_SRGB_BLOCK;
enum VK_FORMAT_ASTC_6x5_UNORM_BLOCK                              = VkFormat.VK_FORMAT_ASTC_6x5_UNORM_BLOCK;
enum VK_FORMAT_ASTC_6x5_SRGB_BLOCK                               = VkFormat.VK_FORMAT_ASTC_6x5_SRGB_BLOCK;
enum VK_FORMAT_ASTC_6x6_UNORM_BLOCK                              = VkFormat.VK_FORMAT_ASTC_6x6_UNORM_BLOCK;
enum VK_FORMAT_ASTC_6x6_SRGB_BLOCK                               = VkFormat.VK_FORMAT_ASTC_6x6_SRGB_BLOCK;
enum VK_FORMAT_ASTC_8x5_UNORM_BLOCK                              = VkFormat.VK_FORMAT_ASTC_8x5_UNORM_BLOCK;
enum VK_FORMAT_ASTC_8x5_SRGB_BLOCK                               = VkFormat.VK_FORMAT_ASTC_8x5_SRGB_BLOCK;
enum VK_FORMAT_ASTC_8x6_UNORM_BLOCK                              = VkFormat.VK_FORMAT_ASTC_8x6_UNORM_BLOCK;
enum VK_FORMAT_ASTC_8x6_SRGB_BLOCK                               = VkFormat.VK_FORMAT_ASTC_8x6_SRGB_BLOCK;
enum VK_FORMAT_ASTC_8x8_UNORM_BLOCK                              = VkFormat.VK_FORMAT_ASTC_8x8_UNORM_BLOCK;
enum VK_FORMAT_ASTC_8x8_SRGB_BLOCK                               = VkFormat.VK_FORMAT_ASTC_8x8_SRGB_BLOCK;
enum VK_FORMAT_ASTC_10x5_UNORM_BLOCK                             = VkFormat.VK_FORMAT_ASTC_10x5_UNORM_BLOCK;
enum VK_FORMAT_ASTC_10x5_SRGB_BLOCK                              = VkFormat.VK_FORMAT_ASTC_10x5_SRGB_BLOCK;
enum VK_FORMAT_ASTC_10x6_UNORM_BLOCK                             = VkFormat.VK_FORMAT_ASTC_10x6_UNORM_BLOCK;
enum VK_FORMAT_ASTC_10x6_SRGB_BLOCK                              = VkFormat.VK_FORMAT_ASTC_10x6_SRGB_BLOCK;
enum VK_FORMAT_ASTC_10x8_UNORM_BLOCK                             = VkFormat.VK_FORMAT_ASTC_10x8_UNORM_BLOCK;
enum VK_FORMAT_ASTC_10x8_SRGB_BLOCK                              = VkFormat.VK_FORMAT_ASTC_10x8_SRGB_BLOCK;
enum VK_FORMAT_ASTC_10x10_UNORM_BLOCK                            = VkFormat.VK_FORMAT_ASTC_10x10_UNORM_BLOCK;
enum VK_FORMAT_ASTC_10x10_SRGB_BLOCK                             = VkFormat.VK_FORMAT_ASTC_10x10_SRGB_BLOCK;
enum VK_FORMAT_ASTC_12x10_UNORM_BLOCK                            = VkFormat.VK_FORMAT_ASTC_12x10_UNORM_BLOCK;
enum VK_FORMAT_ASTC_12x10_SRGB_BLOCK                             = VkFormat.VK_FORMAT_ASTC_12x10_SRGB_BLOCK;
enum VK_FORMAT_ASTC_12x12_UNORM_BLOCK                            = VkFormat.VK_FORMAT_ASTC_12x12_UNORM_BLOCK;
enum VK_FORMAT_ASTC_12x12_SRGB_BLOCK                             = VkFormat.VK_FORMAT_ASTC_12x12_SRGB_BLOCK;
enum VK_FORMAT_G8B8G8R8_422_UNORM                                = VkFormat.VK_FORMAT_G8B8G8R8_422_UNORM;
enum VK_FORMAT_B8G8R8G8_422_UNORM                                = VkFormat.VK_FORMAT_B8G8R8G8_422_UNORM;
enum VK_FORMAT_G8_B8_R8_3PLANE_420_UNORM                         = VkFormat.VK_FORMAT_G8_B8_R8_3PLANE_420_UNORM;
enum VK_FORMAT_G8_B8R8_2PLANE_420_UNORM                          = VkFormat.VK_FORMAT_G8_B8R8_2PLANE_420_UNORM;
enum VK_FORMAT_G8_B8_R8_3PLANE_422_UNORM                         = VkFormat.VK_FORMAT_G8_B8_R8_3PLANE_422_UNORM;
enum VK_FORMAT_G8_B8R8_2PLANE_422_UNORM                          = VkFormat.VK_FORMAT_G8_B8R8_2PLANE_422_UNORM;
enum VK_FORMAT_G8_B8_R8_3PLANE_444_UNORM                         = VkFormat.VK_FORMAT_G8_B8_R8_3PLANE_444_UNORM;
enum VK_FORMAT_R10X6_UNORM_PACK16                                = VkFormat.VK_FORMAT_R10X6_UNORM_PACK16;
enum VK_FORMAT_R10X6G10X6_UNORM_2PACK16                          = VkFormat.VK_FORMAT_R10X6G10X6_UNORM_2PACK16;
enum VK_FORMAT_R10X6G10X6B10X6A10X6_UNORM_4PACK16                = VkFormat.VK_FORMAT_R10X6G10X6B10X6A10X6_UNORM_4PACK16;
enum VK_FORMAT_G10X6B10X6G10X6R10X6_422_UNORM_4PACK16            = VkFormat.VK_FORMAT_G10X6B10X6G10X6R10X6_422_UNORM_4PACK16;
enum VK_FORMAT_B10X6G10X6R10X6G10X6_422_UNORM_4PACK16            = VkFormat.VK_FORMAT_B10X6G10X6R10X6G10X6_422_UNORM_4PACK16;
enum VK_FORMAT_G10X6_B10X6_R10X6_3PLANE_420_UNORM_3PACK16        = VkFormat.VK_FORMAT_G10X6_B10X6_R10X6_3PLANE_420_UNORM_3PACK16;
enum VK_FORMAT_G10X6_B10X6R10X6_2PLANE_420_UNORM_3PACK16         = VkFormat.VK_FORMAT_G10X6_B10X6R10X6_2PLANE_420_UNORM_3PACK16;
enum VK_FORMAT_G10X6_B10X6_R10X6_3PLANE_422_UNORM_3PACK16        = VkFormat.VK_FORMAT_G10X6_B10X6_R10X6_3PLANE_422_UNORM_3PACK16;
enum VK_FORMAT_G10X6_B10X6R10X6_2PLANE_422_UNORM_3PACK16         = VkFormat.VK_FORMAT_G10X6_B10X6R10X6_2PLANE_422_UNORM_3PACK16;
enum VK_FORMAT_G10X6_B10X6_R10X6_3PLANE_444_UNORM_3PACK16        = VkFormat.VK_FORMAT_G10X6_B10X6_R10X6_3PLANE_444_UNORM_3PACK16;
enum VK_FORMAT_R12X4_UNORM_PACK16                                = VkFormat.VK_FORMAT_R12X4_UNORM_PACK16;
enum VK_FORMAT_R12X4G12X4_UNORM_2PACK16                          = VkFormat.VK_FORMAT_R12X4G12X4_UNORM_2PACK16;
enum VK_FORMAT_R12X4G12X4B12X4A12X4_UNORM_4PACK16                = VkFormat.VK_FORMAT_R12X4G12X4B12X4A12X4_UNORM_4PACK16;
enum VK_FORMAT_G12X4B12X4G12X4R12X4_422_UNORM_4PACK16            = VkFormat.VK_FORMAT_G12X4B12X4G12X4R12X4_422_UNORM_4PACK16;
enum VK_FORMAT_B12X4G12X4R12X4G12X4_422_UNORM_4PACK16            = VkFormat.VK_FORMAT_B12X4G12X4R12X4G12X4_422_UNORM_4PACK16;
enum VK_FORMAT_G12X4_B12X4_R12X4_3PLANE_420_UNORM_3PACK16        = VkFormat.VK_FORMAT_G12X4_B12X4_R12X4_3PLANE_420_UNORM_3PACK16;
enum VK_FORMAT_G12X4_B12X4R12X4_2PLANE_420_UNORM_3PACK16         = VkFormat.VK_FORMAT_G12X4_B12X4R12X4_2PLANE_420_UNORM_3PACK16;
enum VK_FORMAT_G12X4_B12X4_R12X4_3PLANE_422_UNORM_3PACK16        = VkFormat.VK_FORMAT_G12X4_B12X4_R12X4_3PLANE_422_UNORM_3PACK16;
enum VK_FORMAT_G12X4_B12X4R12X4_2PLANE_422_UNORM_3PACK16         = VkFormat.VK_FORMAT_G12X4_B12X4R12X4_2PLANE_422_UNORM_3PACK16;
enum VK_FORMAT_G12X4_B12X4_R12X4_3PLANE_444_UNORM_3PACK16        = VkFormat.VK_FORMAT_G12X4_B12X4_R12X4_3PLANE_444_UNORM_3PACK16;
enum VK_FORMAT_G16B16G16R16_422_UNORM                            = VkFormat.VK_FORMAT_G16B16G16R16_422_UNORM;
enum VK_FORMAT_B16G16R16G16_422_UNORM                            = VkFormat.VK_FORMAT_B16G16R16G16_422_UNORM;
enum VK_FORMAT_G16_B16_R16_3PLANE_420_UNORM                      = VkFormat.VK_FORMAT_G16_B16_R16_3PLANE_420_UNORM;
enum VK_FORMAT_G16_B16R16_2PLANE_420_UNORM                       = VkFormat.VK_FORMAT_G16_B16R16_2PLANE_420_UNORM;
enum VK_FORMAT_G16_B16_R16_3PLANE_422_UNORM                      = VkFormat.VK_FORMAT_G16_B16_R16_3PLANE_422_UNORM;
enum VK_FORMAT_G16_B16R16_2PLANE_422_UNORM                       = VkFormat.VK_FORMAT_G16_B16R16_2PLANE_422_UNORM;
enum VK_FORMAT_G16_B16_R16_3PLANE_444_UNORM                      = VkFormat.VK_FORMAT_G16_B16_R16_3PLANE_444_UNORM;
enum VK_FORMAT_PVRTC1_2BPP_UNORM_BLOCK_IMG                       = VkFormat.VK_FORMAT_PVRTC1_2BPP_UNORM_BLOCK_IMG;
enum VK_FORMAT_PVRTC1_4BPP_UNORM_BLOCK_IMG                       = VkFormat.VK_FORMAT_PVRTC1_4BPP_UNORM_BLOCK_IMG;
enum VK_FORMAT_PVRTC2_2BPP_UNORM_BLOCK_IMG                       = VkFormat.VK_FORMAT_PVRTC2_2BPP_UNORM_BLOCK_IMG;
enum VK_FORMAT_PVRTC2_4BPP_UNORM_BLOCK_IMG                       = VkFormat.VK_FORMAT_PVRTC2_4BPP_UNORM_BLOCK_IMG;
enum VK_FORMAT_PVRTC1_2BPP_SRGB_BLOCK_IMG                        = VkFormat.VK_FORMAT_PVRTC1_2BPP_SRGB_BLOCK_IMG;
enum VK_FORMAT_PVRTC1_4BPP_SRGB_BLOCK_IMG                        = VkFormat.VK_FORMAT_PVRTC1_4BPP_SRGB_BLOCK_IMG;
enum VK_FORMAT_PVRTC2_2BPP_SRGB_BLOCK_IMG                        = VkFormat.VK_FORMAT_PVRTC2_2BPP_SRGB_BLOCK_IMG;
enum VK_FORMAT_PVRTC2_4BPP_SRGB_BLOCK_IMG                        = VkFormat.VK_FORMAT_PVRTC2_4BPP_SRGB_BLOCK_IMG;
enum VK_FORMAT_G8B8G8R8_422_UNORM_KHR                            = VkFormat.VK_FORMAT_G8B8G8R8_422_UNORM_KHR;
enum VK_FORMAT_B8G8R8G8_422_UNORM_KHR                            = VkFormat.VK_FORMAT_B8G8R8G8_422_UNORM_KHR;
enum VK_FORMAT_G8_B8_R8_3PLANE_420_UNORM_KHR                     = VkFormat.VK_FORMAT_G8_B8_R8_3PLANE_420_UNORM_KHR;
enum VK_FORMAT_G8_B8R8_2PLANE_420_UNORM_KHR                      = VkFormat.VK_FORMAT_G8_B8R8_2PLANE_420_UNORM_KHR;
enum VK_FORMAT_G8_B8_R8_3PLANE_422_UNORM_KHR                     = VkFormat.VK_FORMAT_G8_B8_R8_3PLANE_422_UNORM_KHR;
enum VK_FORMAT_G8_B8R8_2PLANE_422_UNORM_KHR                      = VkFormat.VK_FORMAT_G8_B8R8_2PLANE_422_UNORM_KHR;
enum VK_FORMAT_G8_B8_R8_3PLANE_444_UNORM_KHR                     = VkFormat.VK_FORMAT_G8_B8_R8_3PLANE_444_UNORM_KHR;
enum VK_FORMAT_R10X6_UNORM_PACK16_KHR                            = VkFormat.VK_FORMAT_R10X6_UNORM_PACK16_KHR;
enum VK_FORMAT_R10X6G10X6_UNORM_2PACK16_KHR                      = VkFormat.VK_FORMAT_R10X6G10X6_UNORM_2PACK16_KHR;
enum VK_FORMAT_R10X6G10X6B10X6A10X6_UNORM_4PACK16_KHR            = VkFormat.VK_FORMAT_R10X6G10X6B10X6A10X6_UNORM_4PACK16_KHR;
enum VK_FORMAT_G10X6B10X6G10X6R10X6_422_UNORM_4PACK16_KHR        = VkFormat.VK_FORMAT_G10X6B10X6G10X6R10X6_422_UNORM_4PACK16_KHR;
enum VK_FORMAT_B10X6G10X6R10X6G10X6_422_UNORM_4PACK16_KHR        = VkFormat.VK_FORMAT_B10X6G10X6R10X6G10X6_422_UNORM_4PACK16_KHR;
enum VK_FORMAT_G10X6_B10X6_R10X6_3PLANE_420_UNORM_3PACK16_KHR    = VkFormat.VK_FORMAT_G10X6_B10X6_R10X6_3PLANE_420_UNORM_3PACK16_KHR;
enum VK_FORMAT_G10X6_B10X6R10X6_2PLANE_420_UNORM_3PACK16_KHR     = VkFormat.VK_FORMAT_G10X6_B10X6R10X6_2PLANE_420_UNORM_3PACK16_KHR;
enum VK_FORMAT_G10X6_B10X6_R10X6_3PLANE_422_UNORM_3PACK16_KHR    = VkFormat.VK_FORMAT_G10X6_B10X6_R10X6_3PLANE_422_UNORM_3PACK16_KHR;
enum VK_FORMAT_G10X6_B10X6R10X6_2PLANE_422_UNORM_3PACK16_KHR     = VkFormat.VK_FORMAT_G10X6_B10X6R10X6_2PLANE_422_UNORM_3PACK16_KHR;
enum VK_FORMAT_G10X6_B10X6_R10X6_3PLANE_444_UNORM_3PACK16_KHR    = VkFormat.VK_FORMAT_G10X6_B10X6_R10X6_3PLANE_444_UNORM_3PACK16_KHR;
enum VK_FORMAT_R12X4_UNORM_PACK16_KHR                            = VkFormat.VK_FORMAT_R12X4_UNORM_PACK16_KHR;
enum VK_FORMAT_R12X4G12X4_UNORM_2PACK16_KHR                      = VkFormat.VK_FORMAT_R12X4G12X4_UNORM_2PACK16_KHR;
enum VK_FORMAT_R12X4G12X4B12X4A12X4_UNORM_4PACK16_KHR            = VkFormat.VK_FORMAT_R12X4G12X4B12X4A12X4_UNORM_4PACK16_KHR;
enum VK_FORMAT_G12X4B12X4G12X4R12X4_422_UNORM_4PACK16_KHR        = VkFormat.VK_FORMAT_G12X4B12X4G12X4R12X4_422_UNORM_4PACK16_KHR;
enum VK_FORMAT_B12X4G12X4R12X4G12X4_422_UNORM_4PACK16_KHR        = VkFormat.VK_FORMAT_B12X4G12X4R12X4G12X4_422_UNORM_4PACK16_KHR;
enum VK_FORMAT_G12X4_B12X4_R12X4_3PLANE_420_UNORM_3PACK16_KHR    = VkFormat.VK_FORMAT_G12X4_B12X4_R12X4_3PLANE_420_UNORM_3PACK16_KHR;
enum VK_FORMAT_G12X4_B12X4R12X4_2PLANE_420_UNORM_3PACK16_KHR     = VkFormat.VK_FORMAT_G12X4_B12X4R12X4_2PLANE_420_UNORM_3PACK16_KHR;
enum VK_FORMAT_G12X4_B12X4_R12X4_3PLANE_422_UNORM_3PACK16_KHR    = VkFormat.VK_FORMAT_G12X4_B12X4_R12X4_3PLANE_422_UNORM_3PACK16_KHR;
enum VK_FORMAT_G12X4_B12X4R12X4_2PLANE_422_UNORM_3PACK16_KHR     = VkFormat.VK_FORMAT_G12X4_B12X4R12X4_2PLANE_422_UNORM_3PACK16_KHR;
enum VK_FORMAT_G12X4_B12X4_R12X4_3PLANE_444_UNORM_3PACK16_KHR    = VkFormat.VK_FORMAT_G12X4_B12X4_R12X4_3PLANE_444_UNORM_3PACK16_KHR;
enum VK_FORMAT_G16B16G16R16_422_UNORM_KHR                        = VkFormat.VK_FORMAT_G16B16G16R16_422_UNORM_KHR;
enum VK_FORMAT_B16G16R16G16_422_UNORM_KHR                        = VkFormat.VK_FORMAT_B16G16R16G16_422_UNORM_KHR;
enum VK_FORMAT_G16_B16_R16_3PLANE_420_UNORM_KHR                  = VkFormat.VK_FORMAT_G16_B16_R16_3PLANE_420_UNORM_KHR;
enum VK_FORMAT_G16_B16R16_2PLANE_420_UNORM_KHR                   = VkFormat.VK_FORMAT_G16_B16R16_2PLANE_420_UNORM_KHR;
enum VK_FORMAT_G16_B16_R16_3PLANE_422_UNORM_KHR                  = VkFormat.VK_FORMAT_G16_B16_R16_3PLANE_422_UNORM_KHR;
enum VK_FORMAT_G16_B16R16_2PLANE_422_UNORM_KHR                   = VkFormat.VK_FORMAT_G16_B16R16_2PLANE_422_UNORM_KHR;
enum VK_FORMAT_G16_B16_R16_3PLANE_444_UNORM_KHR                  = VkFormat.VK_FORMAT_G16_B16_R16_3PLANE_444_UNORM_KHR;
enum VK_FORMAT_BEGIN_RANGE                                       = VkFormat.VK_FORMAT_BEGIN_RANGE;
enum VK_FORMAT_END_RANGE                                         = VkFormat.VK_FORMAT_END_RANGE;
enum VK_FORMAT_RANGE_SIZE                                        = VkFormat.VK_FORMAT_RANGE_SIZE;
enum VK_FORMAT_MAX_ENUM                                          = VkFormat.VK_FORMAT_MAX_ENUM;

enum VkImageType {
    VK_IMAGE_TYPE_1D             = 0,
    VK_IMAGE_TYPE_2D             = 1,
    VK_IMAGE_TYPE_3D             = 2,
    VK_IMAGE_TYPE_BEGIN_RANGE    = VK_IMAGE_TYPE_1D,
    VK_IMAGE_TYPE_END_RANGE      = VK_IMAGE_TYPE_3D,
    VK_IMAGE_TYPE_RANGE_SIZE     = VK_IMAGE_TYPE_3D - VK_IMAGE_TYPE_1D + 1,
    VK_IMAGE_TYPE_MAX_ENUM       = 0x7FFFFFFF
}

enum VK_IMAGE_TYPE_1D            = VkImageType.VK_IMAGE_TYPE_1D;
enum VK_IMAGE_TYPE_2D            = VkImageType.VK_IMAGE_TYPE_2D;
enum VK_IMAGE_TYPE_3D            = VkImageType.VK_IMAGE_TYPE_3D;
enum VK_IMAGE_TYPE_BEGIN_RANGE   = VkImageType.VK_IMAGE_TYPE_BEGIN_RANGE;
enum VK_IMAGE_TYPE_END_RANGE     = VkImageType.VK_IMAGE_TYPE_END_RANGE;
enum VK_IMAGE_TYPE_RANGE_SIZE    = VkImageType.VK_IMAGE_TYPE_RANGE_SIZE;
enum VK_IMAGE_TYPE_MAX_ENUM      = VkImageType.VK_IMAGE_TYPE_MAX_ENUM;

enum VkImageTiling {
    VK_IMAGE_TILING_OPTIMAL                      = 0,
    VK_IMAGE_TILING_LINEAR                       = 1,
    VK_IMAGE_TILING_DRM_FORMAT_MODIFIER_EXT      = 1000158000,
    VK_IMAGE_TILING_BEGIN_RANGE                  = VK_IMAGE_TILING_OPTIMAL,
    VK_IMAGE_TILING_END_RANGE                    = VK_IMAGE_TILING_LINEAR,
    VK_IMAGE_TILING_RANGE_SIZE                   = VK_IMAGE_TILING_LINEAR - VK_IMAGE_TILING_OPTIMAL + 1,
    VK_IMAGE_TILING_MAX_ENUM                     = 0x7FFFFFFF
}

enum VK_IMAGE_TILING_OPTIMAL                     = VkImageTiling.VK_IMAGE_TILING_OPTIMAL;
enum VK_IMAGE_TILING_LINEAR                      = VkImageTiling.VK_IMAGE_TILING_LINEAR;
enum VK_IMAGE_TILING_DRM_FORMAT_MODIFIER_EXT     = VkImageTiling.VK_IMAGE_TILING_DRM_FORMAT_MODIFIER_EXT;
enum VK_IMAGE_TILING_BEGIN_RANGE                 = VkImageTiling.VK_IMAGE_TILING_BEGIN_RANGE;
enum VK_IMAGE_TILING_END_RANGE                   = VkImageTiling.VK_IMAGE_TILING_END_RANGE;
enum VK_IMAGE_TILING_RANGE_SIZE                  = VkImageTiling.VK_IMAGE_TILING_RANGE_SIZE;
enum VK_IMAGE_TILING_MAX_ENUM                    = VkImageTiling.VK_IMAGE_TILING_MAX_ENUM;

enum VkPhysicalDeviceType {
    VK_PHYSICAL_DEVICE_TYPE_OTHER                = 0,
    VK_PHYSICAL_DEVICE_TYPE_INTEGRATED_GPU       = 1,
    VK_PHYSICAL_DEVICE_TYPE_DISCRETE_GPU         = 2,
    VK_PHYSICAL_DEVICE_TYPE_VIRTUAL_GPU          = 3,
    VK_PHYSICAL_DEVICE_TYPE_CPU                  = 4,
    VK_PHYSICAL_DEVICE_TYPE_BEGIN_RANGE          = VK_PHYSICAL_DEVICE_TYPE_OTHER,
    VK_PHYSICAL_DEVICE_TYPE_END_RANGE            = VK_PHYSICAL_DEVICE_TYPE_CPU,
    VK_PHYSICAL_DEVICE_TYPE_RANGE_SIZE           = VK_PHYSICAL_DEVICE_TYPE_CPU - VK_PHYSICAL_DEVICE_TYPE_OTHER + 1,
    VK_PHYSICAL_DEVICE_TYPE_MAX_ENUM             = 0x7FFFFFFF
}

enum VK_PHYSICAL_DEVICE_TYPE_OTHER               = VkPhysicalDeviceType.VK_PHYSICAL_DEVICE_TYPE_OTHER;
enum VK_PHYSICAL_DEVICE_TYPE_INTEGRATED_GPU      = VkPhysicalDeviceType.VK_PHYSICAL_DEVICE_TYPE_INTEGRATED_GPU;
enum VK_PHYSICAL_DEVICE_TYPE_DISCRETE_GPU        = VkPhysicalDeviceType.VK_PHYSICAL_DEVICE_TYPE_DISCRETE_GPU;
enum VK_PHYSICAL_DEVICE_TYPE_VIRTUAL_GPU         = VkPhysicalDeviceType.VK_PHYSICAL_DEVICE_TYPE_VIRTUAL_GPU;
enum VK_PHYSICAL_DEVICE_TYPE_CPU                 = VkPhysicalDeviceType.VK_PHYSICAL_DEVICE_TYPE_CPU;
enum VK_PHYSICAL_DEVICE_TYPE_BEGIN_RANGE         = VkPhysicalDeviceType.VK_PHYSICAL_DEVICE_TYPE_BEGIN_RANGE;
enum VK_PHYSICAL_DEVICE_TYPE_END_RANGE           = VkPhysicalDeviceType.VK_PHYSICAL_DEVICE_TYPE_END_RANGE;
enum VK_PHYSICAL_DEVICE_TYPE_RANGE_SIZE          = VkPhysicalDeviceType.VK_PHYSICAL_DEVICE_TYPE_RANGE_SIZE;
enum VK_PHYSICAL_DEVICE_TYPE_MAX_ENUM            = VkPhysicalDeviceType.VK_PHYSICAL_DEVICE_TYPE_MAX_ENUM;

enum VkQueryType {
    VK_QUERY_TYPE_OCCLUSION                                      = 0,
    VK_QUERY_TYPE_PIPELINE_STATISTICS                            = 1,
    VK_QUERY_TYPE_TIMESTAMP                                      = 2,
    VK_QUERY_TYPE_TRANSFORM_FEEDBACK_STREAM_EXT                  = 1000028004,
    VK_QUERY_TYPE_ACCELERATION_STRUCTURE_COMPACTED_SIZE_NV       = 1000165000,
    VK_QUERY_TYPE_PERFORMANCE_QUERY_INTEL                        = 1000210000,
    VK_QUERY_TYPE_BEGIN_RANGE                                    = VK_QUERY_TYPE_OCCLUSION,
    VK_QUERY_TYPE_END_RANGE                                      = VK_QUERY_TYPE_TIMESTAMP,
    VK_QUERY_TYPE_RANGE_SIZE                                     = VK_QUERY_TYPE_TIMESTAMP - VK_QUERY_TYPE_OCCLUSION + 1,
    VK_QUERY_TYPE_MAX_ENUM                                       = 0x7FFFFFFF
}

enum VK_QUERY_TYPE_OCCLUSION                                     = VkQueryType.VK_QUERY_TYPE_OCCLUSION;
enum VK_QUERY_TYPE_PIPELINE_STATISTICS                           = VkQueryType.VK_QUERY_TYPE_PIPELINE_STATISTICS;
enum VK_QUERY_TYPE_TIMESTAMP                                     = VkQueryType.VK_QUERY_TYPE_TIMESTAMP;
enum VK_QUERY_TYPE_TRANSFORM_FEEDBACK_STREAM_EXT                 = VkQueryType.VK_QUERY_TYPE_TRANSFORM_FEEDBACK_STREAM_EXT;
enum VK_QUERY_TYPE_ACCELERATION_STRUCTURE_COMPACTED_SIZE_NV      = VkQueryType.VK_QUERY_TYPE_ACCELERATION_STRUCTURE_COMPACTED_SIZE_NV;
enum VK_QUERY_TYPE_PERFORMANCE_QUERY_INTEL                       = VkQueryType.VK_QUERY_TYPE_PERFORMANCE_QUERY_INTEL;
enum VK_QUERY_TYPE_BEGIN_RANGE                                   = VkQueryType.VK_QUERY_TYPE_BEGIN_RANGE;
enum VK_QUERY_TYPE_END_RANGE                                     = VkQueryType.VK_QUERY_TYPE_END_RANGE;
enum VK_QUERY_TYPE_RANGE_SIZE                                    = VkQueryType.VK_QUERY_TYPE_RANGE_SIZE;
enum VK_QUERY_TYPE_MAX_ENUM                                      = VkQueryType.VK_QUERY_TYPE_MAX_ENUM;

enum VkSharingMode {
    VK_SHARING_MODE_EXCLUSIVE    = 0,
    VK_SHARING_MODE_CONCURRENT   = 1,
    VK_SHARING_MODE_BEGIN_RANGE  = VK_SHARING_MODE_EXCLUSIVE,
    VK_SHARING_MODE_END_RANGE    = VK_SHARING_MODE_CONCURRENT,
    VK_SHARING_MODE_RANGE_SIZE   = VK_SHARING_MODE_CONCURRENT - VK_SHARING_MODE_EXCLUSIVE + 1,
    VK_SHARING_MODE_MAX_ENUM     = 0x7FFFFFFF
}

enum VK_SHARING_MODE_EXCLUSIVE   = VkSharingMode.VK_SHARING_MODE_EXCLUSIVE;
enum VK_SHARING_MODE_CONCURRENT  = VkSharingMode.VK_SHARING_MODE_CONCURRENT;
enum VK_SHARING_MODE_BEGIN_RANGE = VkSharingMode.VK_SHARING_MODE_BEGIN_RANGE;
enum VK_SHARING_MODE_END_RANGE   = VkSharingMode.VK_SHARING_MODE_END_RANGE;
enum VK_SHARING_MODE_RANGE_SIZE  = VkSharingMode.VK_SHARING_MODE_RANGE_SIZE;
enum VK_SHARING_MODE_MAX_ENUM    = VkSharingMode.VK_SHARING_MODE_MAX_ENUM;

enum VkImageLayout {
    VK_IMAGE_LAYOUT_UNDEFINED                                            = 0,
    VK_IMAGE_LAYOUT_GENERAL                                              = 1,
    VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL                             = 2,
    VK_IMAGE_LAYOUT_DEPTH_STENCIL_ATTACHMENT_OPTIMAL                     = 3,
    VK_IMAGE_LAYOUT_DEPTH_STENCIL_READ_ONLY_OPTIMAL                      = 4,
    VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL                             = 5,
    VK_IMAGE_LAYOUT_TRANSFER_SRC_OPTIMAL                                 = 6,
    VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL                                 = 7,
    VK_IMAGE_LAYOUT_PREINITIALIZED                                       = 8,
    VK_IMAGE_LAYOUT_DEPTH_READ_ONLY_STENCIL_ATTACHMENT_OPTIMAL           = 1000117000,
    VK_IMAGE_LAYOUT_DEPTH_ATTACHMENT_STENCIL_READ_ONLY_OPTIMAL           = 1000117001,
    VK_IMAGE_LAYOUT_PRESENT_SRC_KHR                                      = 1000001002,
    VK_IMAGE_LAYOUT_SHARED_PRESENT_KHR                                   = 1000111000,
    VK_IMAGE_LAYOUT_SHADING_RATE_OPTIMAL_NV                              = 1000164003,
    VK_IMAGE_LAYOUT_FRAGMENT_DENSITY_MAP_OPTIMAL_EXT                     = 1000218000,
    VK_IMAGE_LAYOUT_DEPTH_READ_ONLY_STENCIL_ATTACHMENT_OPTIMAL_KHR       = VK_IMAGE_LAYOUT_DEPTH_READ_ONLY_STENCIL_ATTACHMENT_OPTIMAL,
    VK_IMAGE_LAYOUT_DEPTH_ATTACHMENT_STENCIL_READ_ONLY_OPTIMAL_KHR       = VK_IMAGE_LAYOUT_DEPTH_ATTACHMENT_STENCIL_READ_ONLY_OPTIMAL,
    VK_IMAGE_LAYOUT_BEGIN_RANGE                                          = VK_IMAGE_LAYOUT_UNDEFINED,
    VK_IMAGE_LAYOUT_END_RANGE                                            = VK_IMAGE_LAYOUT_PREINITIALIZED,
    VK_IMAGE_LAYOUT_RANGE_SIZE                                           = VK_IMAGE_LAYOUT_PREINITIALIZED - VK_IMAGE_LAYOUT_UNDEFINED + 1,
    VK_IMAGE_LAYOUT_MAX_ENUM                                             = 0x7FFFFFFF
}

enum VK_IMAGE_LAYOUT_UNDEFINED                                           = VkImageLayout.VK_IMAGE_LAYOUT_UNDEFINED;
enum VK_IMAGE_LAYOUT_GENERAL                                             = VkImageLayout.VK_IMAGE_LAYOUT_GENERAL;
enum VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL                            = VkImageLayout.VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL;
enum VK_IMAGE_LAYOUT_DEPTH_STENCIL_ATTACHMENT_OPTIMAL                    = VkImageLayout.VK_IMAGE_LAYOUT_DEPTH_STENCIL_ATTACHMENT_OPTIMAL;
enum VK_IMAGE_LAYOUT_DEPTH_STENCIL_READ_ONLY_OPTIMAL                     = VkImageLayout.VK_IMAGE_LAYOUT_DEPTH_STENCIL_READ_ONLY_OPTIMAL;
enum VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL                            = VkImageLayout.VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL;
enum VK_IMAGE_LAYOUT_TRANSFER_SRC_OPTIMAL                                = VkImageLayout.VK_IMAGE_LAYOUT_TRANSFER_SRC_OPTIMAL;
enum VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL                                = VkImageLayout.VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL;
enum VK_IMAGE_LAYOUT_PREINITIALIZED                                      = VkImageLayout.VK_IMAGE_LAYOUT_PREINITIALIZED;
enum VK_IMAGE_LAYOUT_DEPTH_READ_ONLY_STENCIL_ATTACHMENT_OPTIMAL          = VkImageLayout.VK_IMAGE_LAYOUT_DEPTH_READ_ONLY_STENCIL_ATTACHMENT_OPTIMAL;
enum VK_IMAGE_LAYOUT_DEPTH_ATTACHMENT_STENCIL_READ_ONLY_OPTIMAL          = VkImageLayout.VK_IMAGE_LAYOUT_DEPTH_ATTACHMENT_STENCIL_READ_ONLY_OPTIMAL;
enum VK_IMAGE_LAYOUT_PRESENT_SRC_KHR                                     = VkImageLayout.VK_IMAGE_LAYOUT_PRESENT_SRC_KHR;
enum VK_IMAGE_LAYOUT_SHARED_PRESENT_KHR                                  = VkImageLayout.VK_IMAGE_LAYOUT_SHARED_PRESENT_KHR;
enum VK_IMAGE_LAYOUT_SHADING_RATE_OPTIMAL_NV                             = VkImageLayout.VK_IMAGE_LAYOUT_SHADING_RATE_OPTIMAL_NV;
enum VK_IMAGE_LAYOUT_FRAGMENT_DENSITY_MAP_OPTIMAL_EXT                    = VkImageLayout.VK_IMAGE_LAYOUT_FRAGMENT_DENSITY_MAP_OPTIMAL_EXT;
enum VK_IMAGE_LAYOUT_DEPTH_READ_ONLY_STENCIL_ATTACHMENT_OPTIMAL_KHR      = VkImageLayout.VK_IMAGE_LAYOUT_DEPTH_READ_ONLY_STENCIL_ATTACHMENT_OPTIMAL_KHR;
enum VK_IMAGE_LAYOUT_DEPTH_ATTACHMENT_STENCIL_READ_ONLY_OPTIMAL_KHR      = VkImageLayout.VK_IMAGE_LAYOUT_DEPTH_ATTACHMENT_STENCIL_READ_ONLY_OPTIMAL_KHR;
enum VK_IMAGE_LAYOUT_BEGIN_RANGE                                         = VkImageLayout.VK_IMAGE_LAYOUT_BEGIN_RANGE;
enum VK_IMAGE_LAYOUT_END_RANGE                                           = VkImageLayout.VK_IMAGE_LAYOUT_END_RANGE;
enum VK_IMAGE_LAYOUT_RANGE_SIZE                                          = VkImageLayout.VK_IMAGE_LAYOUT_RANGE_SIZE;
enum VK_IMAGE_LAYOUT_MAX_ENUM                                            = VkImageLayout.VK_IMAGE_LAYOUT_MAX_ENUM;

enum VkImageViewType {
    VK_IMAGE_VIEW_TYPE_1D                = 0,
    VK_IMAGE_VIEW_TYPE_2D                = 1,
    VK_IMAGE_VIEW_TYPE_3D                = 2,
    VK_IMAGE_VIEW_TYPE_CUBE              = 3,
    VK_IMAGE_VIEW_TYPE_1D_ARRAY          = 4,
    VK_IMAGE_VIEW_TYPE_2D_ARRAY          = 5,
    VK_IMAGE_VIEW_TYPE_CUBE_ARRAY        = 6,
    VK_IMAGE_VIEW_TYPE_BEGIN_RANGE       = VK_IMAGE_VIEW_TYPE_1D,
    VK_IMAGE_VIEW_TYPE_END_RANGE         = VK_IMAGE_VIEW_TYPE_CUBE_ARRAY,
    VK_IMAGE_VIEW_TYPE_RANGE_SIZE        = VK_IMAGE_VIEW_TYPE_CUBE_ARRAY - VK_IMAGE_VIEW_TYPE_1D + 1,
    VK_IMAGE_VIEW_TYPE_MAX_ENUM          = 0x7FFFFFFF
}

enum VK_IMAGE_VIEW_TYPE_1D               = VkImageViewType.VK_IMAGE_VIEW_TYPE_1D;
enum VK_IMAGE_VIEW_TYPE_2D               = VkImageViewType.VK_IMAGE_VIEW_TYPE_2D;
enum VK_IMAGE_VIEW_TYPE_3D               = VkImageViewType.VK_IMAGE_VIEW_TYPE_3D;
enum VK_IMAGE_VIEW_TYPE_CUBE             = VkImageViewType.VK_IMAGE_VIEW_TYPE_CUBE;
enum VK_IMAGE_VIEW_TYPE_1D_ARRAY         = VkImageViewType.VK_IMAGE_VIEW_TYPE_1D_ARRAY;
enum VK_IMAGE_VIEW_TYPE_2D_ARRAY         = VkImageViewType.VK_IMAGE_VIEW_TYPE_2D_ARRAY;
enum VK_IMAGE_VIEW_TYPE_CUBE_ARRAY       = VkImageViewType.VK_IMAGE_VIEW_TYPE_CUBE_ARRAY;
enum VK_IMAGE_VIEW_TYPE_BEGIN_RANGE      = VkImageViewType.VK_IMAGE_VIEW_TYPE_BEGIN_RANGE;
enum VK_IMAGE_VIEW_TYPE_END_RANGE        = VkImageViewType.VK_IMAGE_VIEW_TYPE_END_RANGE;
enum VK_IMAGE_VIEW_TYPE_RANGE_SIZE       = VkImageViewType.VK_IMAGE_VIEW_TYPE_RANGE_SIZE;
enum VK_IMAGE_VIEW_TYPE_MAX_ENUM         = VkImageViewType.VK_IMAGE_VIEW_TYPE_MAX_ENUM;

enum VkComponentSwizzle {
    VK_COMPONENT_SWIZZLE_IDENTITY        = 0,
    VK_COMPONENT_SWIZZLE_ZERO            = 1,
    VK_COMPONENT_SWIZZLE_ONE             = 2,
    VK_COMPONENT_SWIZZLE_R               = 3,
    VK_COMPONENT_SWIZZLE_G               = 4,
    VK_COMPONENT_SWIZZLE_B               = 5,
    VK_COMPONENT_SWIZZLE_A               = 6,
    VK_COMPONENT_SWIZZLE_BEGIN_RANGE     = VK_COMPONENT_SWIZZLE_IDENTITY,
    VK_COMPONENT_SWIZZLE_END_RANGE       = VK_COMPONENT_SWIZZLE_A,
    VK_COMPONENT_SWIZZLE_RANGE_SIZE      = VK_COMPONENT_SWIZZLE_A - VK_COMPONENT_SWIZZLE_IDENTITY + 1,
    VK_COMPONENT_SWIZZLE_MAX_ENUM        = 0x7FFFFFFF
}

enum VK_COMPONENT_SWIZZLE_IDENTITY       = VkComponentSwizzle.VK_COMPONENT_SWIZZLE_IDENTITY;
enum VK_COMPONENT_SWIZZLE_ZERO           = VkComponentSwizzle.VK_COMPONENT_SWIZZLE_ZERO;
enum VK_COMPONENT_SWIZZLE_ONE            = VkComponentSwizzle.VK_COMPONENT_SWIZZLE_ONE;
enum VK_COMPONENT_SWIZZLE_R              = VkComponentSwizzle.VK_COMPONENT_SWIZZLE_R;
enum VK_COMPONENT_SWIZZLE_G              = VkComponentSwizzle.VK_COMPONENT_SWIZZLE_G;
enum VK_COMPONENT_SWIZZLE_B              = VkComponentSwizzle.VK_COMPONENT_SWIZZLE_B;
enum VK_COMPONENT_SWIZZLE_A              = VkComponentSwizzle.VK_COMPONENT_SWIZZLE_A;
enum VK_COMPONENT_SWIZZLE_BEGIN_RANGE    = VkComponentSwizzle.VK_COMPONENT_SWIZZLE_BEGIN_RANGE;
enum VK_COMPONENT_SWIZZLE_END_RANGE      = VkComponentSwizzle.VK_COMPONENT_SWIZZLE_END_RANGE;
enum VK_COMPONENT_SWIZZLE_RANGE_SIZE     = VkComponentSwizzle.VK_COMPONENT_SWIZZLE_RANGE_SIZE;
enum VK_COMPONENT_SWIZZLE_MAX_ENUM       = VkComponentSwizzle.VK_COMPONENT_SWIZZLE_MAX_ENUM;

enum VkVertexInputRate {
    VK_VERTEX_INPUT_RATE_VERTEX          = 0,
    VK_VERTEX_INPUT_RATE_INSTANCE        = 1,
    VK_VERTEX_INPUT_RATE_BEGIN_RANGE     = VK_VERTEX_INPUT_RATE_VERTEX,
    VK_VERTEX_INPUT_RATE_END_RANGE       = VK_VERTEX_INPUT_RATE_INSTANCE,
    VK_VERTEX_INPUT_RATE_RANGE_SIZE      = VK_VERTEX_INPUT_RATE_INSTANCE - VK_VERTEX_INPUT_RATE_VERTEX + 1,
    VK_VERTEX_INPUT_RATE_MAX_ENUM        = 0x7FFFFFFF
}

enum VK_VERTEX_INPUT_RATE_VERTEX         = VkVertexInputRate.VK_VERTEX_INPUT_RATE_VERTEX;
enum VK_VERTEX_INPUT_RATE_INSTANCE       = VkVertexInputRate.VK_VERTEX_INPUT_RATE_INSTANCE;
enum VK_VERTEX_INPUT_RATE_BEGIN_RANGE    = VkVertexInputRate.VK_VERTEX_INPUT_RATE_BEGIN_RANGE;
enum VK_VERTEX_INPUT_RATE_END_RANGE      = VkVertexInputRate.VK_VERTEX_INPUT_RATE_END_RANGE;
enum VK_VERTEX_INPUT_RATE_RANGE_SIZE     = VkVertexInputRate.VK_VERTEX_INPUT_RATE_RANGE_SIZE;
enum VK_VERTEX_INPUT_RATE_MAX_ENUM       = VkVertexInputRate.VK_VERTEX_INPUT_RATE_MAX_ENUM;

enum VkPrimitiveTopology {
    VK_PRIMITIVE_TOPOLOGY_POINT_LIST                     = 0,
    VK_PRIMITIVE_TOPOLOGY_LINE_LIST                      = 1,
    VK_PRIMITIVE_TOPOLOGY_LINE_STRIP                     = 2,
    VK_PRIMITIVE_TOPOLOGY_TRIANGLE_LIST                  = 3,
    VK_PRIMITIVE_TOPOLOGY_TRIANGLE_STRIP                 = 4,
    VK_PRIMITIVE_TOPOLOGY_TRIANGLE_FAN                   = 5,
    VK_PRIMITIVE_TOPOLOGY_LINE_LIST_WITH_ADJACENCY       = 6,
    VK_PRIMITIVE_TOPOLOGY_LINE_STRIP_WITH_ADJACENCY      = 7,
    VK_PRIMITIVE_TOPOLOGY_TRIANGLE_LIST_WITH_ADJACENCY   = 8,
    VK_PRIMITIVE_TOPOLOGY_TRIANGLE_STRIP_WITH_ADJACENCY  = 9,
    VK_PRIMITIVE_TOPOLOGY_PATCH_LIST                     = 10,
    VK_PRIMITIVE_TOPOLOGY_BEGIN_RANGE                    = VK_PRIMITIVE_TOPOLOGY_POINT_LIST,
    VK_PRIMITIVE_TOPOLOGY_END_RANGE                      = VK_PRIMITIVE_TOPOLOGY_PATCH_LIST,
    VK_PRIMITIVE_TOPOLOGY_RANGE_SIZE                     = VK_PRIMITIVE_TOPOLOGY_PATCH_LIST - VK_PRIMITIVE_TOPOLOGY_POINT_LIST + 1,
    VK_PRIMITIVE_TOPOLOGY_MAX_ENUM                       = 0x7FFFFFFF
}

enum VK_PRIMITIVE_TOPOLOGY_POINT_LIST                    = VkPrimitiveTopology.VK_PRIMITIVE_TOPOLOGY_POINT_LIST;
enum VK_PRIMITIVE_TOPOLOGY_LINE_LIST                     = VkPrimitiveTopology.VK_PRIMITIVE_TOPOLOGY_LINE_LIST;
enum VK_PRIMITIVE_TOPOLOGY_LINE_STRIP                    = VkPrimitiveTopology.VK_PRIMITIVE_TOPOLOGY_LINE_STRIP;
enum VK_PRIMITIVE_TOPOLOGY_TRIANGLE_LIST                 = VkPrimitiveTopology.VK_PRIMITIVE_TOPOLOGY_TRIANGLE_LIST;
enum VK_PRIMITIVE_TOPOLOGY_TRIANGLE_STRIP                = VkPrimitiveTopology.VK_PRIMITIVE_TOPOLOGY_TRIANGLE_STRIP;
enum VK_PRIMITIVE_TOPOLOGY_TRIANGLE_FAN                  = VkPrimitiveTopology.VK_PRIMITIVE_TOPOLOGY_TRIANGLE_FAN;
enum VK_PRIMITIVE_TOPOLOGY_LINE_LIST_WITH_ADJACENCY      = VkPrimitiveTopology.VK_PRIMITIVE_TOPOLOGY_LINE_LIST_WITH_ADJACENCY;
enum VK_PRIMITIVE_TOPOLOGY_LINE_STRIP_WITH_ADJACENCY     = VkPrimitiveTopology.VK_PRIMITIVE_TOPOLOGY_LINE_STRIP_WITH_ADJACENCY;
enum VK_PRIMITIVE_TOPOLOGY_TRIANGLE_LIST_WITH_ADJACENCY  = VkPrimitiveTopology.VK_PRIMITIVE_TOPOLOGY_TRIANGLE_LIST_WITH_ADJACENCY;
enum VK_PRIMITIVE_TOPOLOGY_TRIANGLE_STRIP_WITH_ADJACENCY = VkPrimitiveTopology.VK_PRIMITIVE_TOPOLOGY_TRIANGLE_STRIP_WITH_ADJACENCY;
enum VK_PRIMITIVE_TOPOLOGY_PATCH_LIST                    = VkPrimitiveTopology.VK_PRIMITIVE_TOPOLOGY_PATCH_LIST;
enum VK_PRIMITIVE_TOPOLOGY_BEGIN_RANGE                   = VkPrimitiveTopology.VK_PRIMITIVE_TOPOLOGY_BEGIN_RANGE;
enum VK_PRIMITIVE_TOPOLOGY_END_RANGE                     = VkPrimitiveTopology.VK_PRIMITIVE_TOPOLOGY_END_RANGE;
enum VK_PRIMITIVE_TOPOLOGY_RANGE_SIZE                    = VkPrimitiveTopology.VK_PRIMITIVE_TOPOLOGY_RANGE_SIZE;
enum VK_PRIMITIVE_TOPOLOGY_MAX_ENUM                      = VkPrimitiveTopology.VK_PRIMITIVE_TOPOLOGY_MAX_ENUM;

enum VkPolygonMode {
    VK_POLYGON_MODE_FILL                 = 0,
    VK_POLYGON_MODE_LINE                 = 1,
    VK_POLYGON_MODE_POINT                = 2,
    VK_POLYGON_MODE_FILL_RECTANGLE_NV    = 1000153000,
    VK_POLYGON_MODE_BEGIN_RANGE          = VK_POLYGON_MODE_FILL,
    VK_POLYGON_MODE_END_RANGE            = VK_POLYGON_MODE_POINT,
    VK_POLYGON_MODE_RANGE_SIZE           = VK_POLYGON_MODE_POINT - VK_POLYGON_MODE_FILL + 1,
    VK_POLYGON_MODE_MAX_ENUM             = 0x7FFFFFFF
}

enum VK_POLYGON_MODE_FILL                = VkPolygonMode.VK_POLYGON_MODE_FILL;
enum VK_POLYGON_MODE_LINE                = VkPolygonMode.VK_POLYGON_MODE_LINE;
enum VK_POLYGON_MODE_POINT               = VkPolygonMode.VK_POLYGON_MODE_POINT;
enum VK_POLYGON_MODE_FILL_RECTANGLE_NV   = VkPolygonMode.VK_POLYGON_MODE_FILL_RECTANGLE_NV;
enum VK_POLYGON_MODE_BEGIN_RANGE         = VkPolygonMode.VK_POLYGON_MODE_BEGIN_RANGE;
enum VK_POLYGON_MODE_END_RANGE           = VkPolygonMode.VK_POLYGON_MODE_END_RANGE;
enum VK_POLYGON_MODE_RANGE_SIZE          = VkPolygonMode.VK_POLYGON_MODE_RANGE_SIZE;
enum VK_POLYGON_MODE_MAX_ENUM            = VkPolygonMode.VK_POLYGON_MODE_MAX_ENUM;

enum VkFrontFace {
    VK_FRONT_FACE_COUNTER_CLOCKWISE      = 0,
    VK_FRONT_FACE_CLOCKWISE              = 1,
    VK_FRONT_FACE_BEGIN_RANGE            = VK_FRONT_FACE_COUNTER_CLOCKWISE,
    VK_FRONT_FACE_END_RANGE              = VK_FRONT_FACE_CLOCKWISE,
    VK_FRONT_FACE_RANGE_SIZE             = VK_FRONT_FACE_CLOCKWISE - VK_FRONT_FACE_COUNTER_CLOCKWISE + 1,
    VK_FRONT_FACE_MAX_ENUM               = 0x7FFFFFFF
}

enum VK_FRONT_FACE_COUNTER_CLOCKWISE     = VkFrontFace.VK_FRONT_FACE_COUNTER_CLOCKWISE;
enum VK_FRONT_FACE_CLOCKWISE             = VkFrontFace.VK_FRONT_FACE_CLOCKWISE;
enum VK_FRONT_FACE_BEGIN_RANGE           = VkFrontFace.VK_FRONT_FACE_BEGIN_RANGE;
enum VK_FRONT_FACE_END_RANGE             = VkFrontFace.VK_FRONT_FACE_END_RANGE;
enum VK_FRONT_FACE_RANGE_SIZE            = VkFrontFace.VK_FRONT_FACE_RANGE_SIZE;
enum VK_FRONT_FACE_MAX_ENUM              = VkFrontFace.VK_FRONT_FACE_MAX_ENUM;

enum VkCompareOp {
    VK_COMPARE_OP_NEVER                  = 0,
    VK_COMPARE_OP_LESS                   = 1,
    VK_COMPARE_OP_EQUAL                  = 2,
    VK_COMPARE_OP_LESS_OR_EQUAL          = 3,
    VK_COMPARE_OP_GREATER                = 4,
    VK_COMPARE_OP_NOT_EQUAL              = 5,
    VK_COMPARE_OP_GREATER_OR_EQUAL       = 6,
    VK_COMPARE_OP_ALWAYS                 = 7,
    VK_COMPARE_OP_BEGIN_RANGE            = VK_COMPARE_OP_NEVER,
    VK_COMPARE_OP_END_RANGE              = VK_COMPARE_OP_ALWAYS,
    VK_COMPARE_OP_RANGE_SIZE             = VK_COMPARE_OP_ALWAYS - VK_COMPARE_OP_NEVER + 1,
    VK_COMPARE_OP_MAX_ENUM               = 0x7FFFFFFF
}

enum VK_COMPARE_OP_NEVER                 = VkCompareOp.VK_COMPARE_OP_NEVER;
enum VK_COMPARE_OP_LESS                  = VkCompareOp.VK_COMPARE_OP_LESS;
enum VK_COMPARE_OP_EQUAL                 = VkCompareOp.VK_COMPARE_OP_EQUAL;
enum VK_COMPARE_OP_LESS_OR_EQUAL         = VkCompareOp.VK_COMPARE_OP_LESS_OR_EQUAL;
enum VK_COMPARE_OP_GREATER               = VkCompareOp.VK_COMPARE_OP_GREATER;
enum VK_COMPARE_OP_NOT_EQUAL             = VkCompareOp.VK_COMPARE_OP_NOT_EQUAL;
enum VK_COMPARE_OP_GREATER_OR_EQUAL      = VkCompareOp.VK_COMPARE_OP_GREATER_OR_EQUAL;
enum VK_COMPARE_OP_ALWAYS                = VkCompareOp.VK_COMPARE_OP_ALWAYS;
enum VK_COMPARE_OP_BEGIN_RANGE           = VkCompareOp.VK_COMPARE_OP_BEGIN_RANGE;
enum VK_COMPARE_OP_END_RANGE             = VkCompareOp.VK_COMPARE_OP_END_RANGE;
enum VK_COMPARE_OP_RANGE_SIZE            = VkCompareOp.VK_COMPARE_OP_RANGE_SIZE;
enum VK_COMPARE_OP_MAX_ENUM              = VkCompareOp.VK_COMPARE_OP_MAX_ENUM;

enum VkStencilOp {
    VK_STENCIL_OP_KEEP                   = 0,
    VK_STENCIL_OP_ZERO                   = 1,
    VK_STENCIL_OP_REPLACE                = 2,
    VK_STENCIL_OP_INCREMENT_AND_CLAMP    = 3,
    VK_STENCIL_OP_DECREMENT_AND_CLAMP    = 4,
    VK_STENCIL_OP_INVERT                 = 5,
    VK_STENCIL_OP_INCREMENT_AND_WRAP     = 6,
    VK_STENCIL_OP_DECREMENT_AND_WRAP     = 7,
    VK_STENCIL_OP_BEGIN_RANGE            = VK_STENCIL_OP_KEEP,
    VK_STENCIL_OP_END_RANGE              = VK_STENCIL_OP_DECREMENT_AND_WRAP,
    VK_STENCIL_OP_RANGE_SIZE             = VK_STENCIL_OP_DECREMENT_AND_WRAP - VK_STENCIL_OP_KEEP + 1,
    VK_STENCIL_OP_MAX_ENUM               = 0x7FFFFFFF
}

enum VK_STENCIL_OP_KEEP                  = VkStencilOp.VK_STENCIL_OP_KEEP;
enum VK_STENCIL_OP_ZERO                  = VkStencilOp.VK_STENCIL_OP_ZERO;
enum VK_STENCIL_OP_REPLACE               = VkStencilOp.VK_STENCIL_OP_REPLACE;
enum VK_STENCIL_OP_INCREMENT_AND_CLAMP   = VkStencilOp.VK_STENCIL_OP_INCREMENT_AND_CLAMP;
enum VK_STENCIL_OP_DECREMENT_AND_CLAMP   = VkStencilOp.VK_STENCIL_OP_DECREMENT_AND_CLAMP;
enum VK_STENCIL_OP_INVERT                = VkStencilOp.VK_STENCIL_OP_INVERT;
enum VK_STENCIL_OP_INCREMENT_AND_WRAP    = VkStencilOp.VK_STENCIL_OP_INCREMENT_AND_WRAP;
enum VK_STENCIL_OP_DECREMENT_AND_WRAP    = VkStencilOp.VK_STENCIL_OP_DECREMENT_AND_WRAP;
enum VK_STENCIL_OP_BEGIN_RANGE           = VkStencilOp.VK_STENCIL_OP_BEGIN_RANGE;
enum VK_STENCIL_OP_END_RANGE             = VkStencilOp.VK_STENCIL_OP_END_RANGE;
enum VK_STENCIL_OP_RANGE_SIZE            = VkStencilOp.VK_STENCIL_OP_RANGE_SIZE;
enum VK_STENCIL_OP_MAX_ENUM              = VkStencilOp.VK_STENCIL_OP_MAX_ENUM;

enum VkLogicOp {
    VK_LOGIC_OP_CLEAR            = 0,
    VK_LOGIC_OP_AND              = 1,
    VK_LOGIC_OP_AND_REVERSE      = 2,
    VK_LOGIC_OP_COPY             = 3,
    VK_LOGIC_OP_AND_INVERTED     = 4,
    VK_LOGIC_OP_NO_OP            = 5,
    VK_LOGIC_OP_XOR              = 6,
    VK_LOGIC_OP_OR               = 7,
    VK_LOGIC_OP_NOR              = 8,
    VK_LOGIC_OP_EQUIVALENT       = 9,
    VK_LOGIC_OP_INVERT           = 10,
    VK_LOGIC_OP_OR_REVERSE       = 11,
    VK_LOGIC_OP_COPY_INVERTED    = 12,
    VK_LOGIC_OP_OR_INVERTED      = 13,
    VK_LOGIC_OP_NAND             = 14,
    VK_LOGIC_OP_SET              = 15,
    VK_LOGIC_OP_BEGIN_RANGE      = VK_LOGIC_OP_CLEAR,
    VK_LOGIC_OP_END_RANGE        = VK_LOGIC_OP_SET,
    VK_LOGIC_OP_RANGE_SIZE       = VK_LOGIC_OP_SET - VK_LOGIC_OP_CLEAR + 1,
    VK_LOGIC_OP_MAX_ENUM         = 0x7FFFFFFF
}

enum VK_LOGIC_OP_CLEAR           = VkLogicOp.VK_LOGIC_OP_CLEAR;
enum VK_LOGIC_OP_AND             = VkLogicOp.VK_LOGIC_OP_AND;
enum VK_LOGIC_OP_AND_REVERSE     = VkLogicOp.VK_LOGIC_OP_AND_REVERSE;
enum VK_LOGIC_OP_COPY            = VkLogicOp.VK_LOGIC_OP_COPY;
enum VK_LOGIC_OP_AND_INVERTED    = VkLogicOp.VK_LOGIC_OP_AND_INVERTED;
enum VK_LOGIC_OP_NO_OP           = VkLogicOp.VK_LOGIC_OP_NO_OP;
enum VK_LOGIC_OP_XOR             = VkLogicOp.VK_LOGIC_OP_XOR;
enum VK_LOGIC_OP_OR              = VkLogicOp.VK_LOGIC_OP_OR;
enum VK_LOGIC_OP_NOR             = VkLogicOp.VK_LOGIC_OP_NOR;
enum VK_LOGIC_OP_EQUIVALENT      = VkLogicOp.VK_LOGIC_OP_EQUIVALENT;
enum VK_LOGIC_OP_INVERT          = VkLogicOp.VK_LOGIC_OP_INVERT;
enum VK_LOGIC_OP_OR_REVERSE      = VkLogicOp.VK_LOGIC_OP_OR_REVERSE;
enum VK_LOGIC_OP_COPY_INVERTED   = VkLogicOp.VK_LOGIC_OP_COPY_INVERTED;
enum VK_LOGIC_OP_OR_INVERTED     = VkLogicOp.VK_LOGIC_OP_OR_INVERTED;
enum VK_LOGIC_OP_NAND            = VkLogicOp.VK_LOGIC_OP_NAND;
enum VK_LOGIC_OP_SET             = VkLogicOp.VK_LOGIC_OP_SET;
enum VK_LOGIC_OP_BEGIN_RANGE     = VkLogicOp.VK_LOGIC_OP_BEGIN_RANGE;
enum VK_LOGIC_OP_END_RANGE       = VkLogicOp.VK_LOGIC_OP_END_RANGE;
enum VK_LOGIC_OP_RANGE_SIZE      = VkLogicOp.VK_LOGIC_OP_RANGE_SIZE;
enum VK_LOGIC_OP_MAX_ENUM        = VkLogicOp.VK_LOGIC_OP_MAX_ENUM;

enum VkBlendFactor {
    VK_BLEND_FACTOR_ZERO                         = 0,
    VK_BLEND_FACTOR_ONE                          = 1,
    VK_BLEND_FACTOR_SRC_COLOR                    = 2,
    VK_BLEND_FACTOR_ONE_MINUS_SRC_COLOR          = 3,
    VK_BLEND_FACTOR_DST_COLOR                    = 4,
    VK_BLEND_FACTOR_ONE_MINUS_DST_COLOR          = 5,
    VK_BLEND_FACTOR_SRC_ALPHA                    = 6,
    VK_BLEND_FACTOR_ONE_MINUS_SRC_ALPHA          = 7,
    VK_BLEND_FACTOR_DST_ALPHA                    = 8,
    VK_BLEND_FACTOR_ONE_MINUS_DST_ALPHA          = 9,
    VK_BLEND_FACTOR_CONSTANT_COLOR               = 10,
    VK_BLEND_FACTOR_ONE_MINUS_CONSTANT_COLOR     = 11,
    VK_BLEND_FACTOR_CONSTANT_ALPHA               = 12,
    VK_BLEND_FACTOR_ONE_MINUS_CONSTANT_ALPHA     = 13,
    VK_BLEND_FACTOR_SRC_ALPHA_SATURATE           = 14,
    VK_BLEND_FACTOR_SRC1_COLOR                   = 15,
    VK_BLEND_FACTOR_ONE_MINUS_SRC1_COLOR         = 16,
    VK_BLEND_FACTOR_SRC1_ALPHA                   = 17,
    VK_BLEND_FACTOR_ONE_MINUS_SRC1_ALPHA         = 18,
    VK_BLEND_FACTOR_BEGIN_RANGE                  = VK_BLEND_FACTOR_ZERO,
    VK_BLEND_FACTOR_END_RANGE                    = VK_BLEND_FACTOR_ONE_MINUS_SRC1_ALPHA,
    VK_BLEND_FACTOR_RANGE_SIZE                   = VK_BLEND_FACTOR_ONE_MINUS_SRC1_ALPHA - VK_BLEND_FACTOR_ZERO + 1,
    VK_BLEND_FACTOR_MAX_ENUM                     = 0x7FFFFFFF
}

enum VK_BLEND_FACTOR_ZERO                        = VkBlendFactor.VK_BLEND_FACTOR_ZERO;
enum VK_BLEND_FACTOR_ONE                         = VkBlendFactor.VK_BLEND_FACTOR_ONE;
enum VK_BLEND_FACTOR_SRC_COLOR                   = VkBlendFactor.VK_BLEND_FACTOR_SRC_COLOR;
enum VK_BLEND_FACTOR_ONE_MINUS_SRC_COLOR         = VkBlendFactor.VK_BLEND_FACTOR_ONE_MINUS_SRC_COLOR;
enum VK_BLEND_FACTOR_DST_COLOR                   = VkBlendFactor.VK_BLEND_FACTOR_DST_COLOR;
enum VK_BLEND_FACTOR_ONE_MINUS_DST_COLOR         = VkBlendFactor.VK_BLEND_FACTOR_ONE_MINUS_DST_COLOR;
enum VK_BLEND_FACTOR_SRC_ALPHA                   = VkBlendFactor.VK_BLEND_FACTOR_SRC_ALPHA;
enum VK_BLEND_FACTOR_ONE_MINUS_SRC_ALPHA         = VkBlendFactor.VK_BLEND_FACTOR_ONE_MINUS_SRC_ALPHA;
enum VK_BLEND_FACTOR_DST_ALPHA                   = VkBlendFactor.VK_BLEND_FACTOR_DST_ALPHA;
enum VK_BLEND_FACTOR_ONE_MINUS_DST_ALPHA         = VkBlendFactor.VK_BLEND_FACTOR_ONE_MINUS_DST_ALPHA;
enum VK_BLEND_FACTOR_CONSTANT_COLOR              = VkBlendFactor.VK_BLEND_FACTOR_CONSTANT_COLOR;
enum VK_BLEND_FACTOR_ONE_MINUS_CONSTANT_COLOR    = VkBlendFactor.VK_BLEND_FACTOR_ONE_MINUS_CONSTANT_COLOR;
enum VK_BLEND_FACTOR_CONSTANT_ALPHA              = VkBlendFactor.VK_BLEND_FACTOR_CONSTANT_ALPHA;
enum VK_BLEND_FACTOR_ONE_MINUS_CONSTANT_ALPHA    = VkBlendFactor.VK_BLEND_FACTOR_ONE_MINUS_CONSTANT_ALPHA;
enum VK_BLEND_FACTOR_SRC_ALPHA_SATURATE          = VkBlendFactor.VK_BLEND_FACTOR_SRC_ALPHA_SATURATE;
enum VK_BLEND_FACTOR_SRC1_COLOR                  = VkBlendFactor.VK_BLEND_FACTOR_SRC1_COLOR;
enum VK_BLEND_FACTOR_ONE_MINUS_SRC1_COLOR        = VkBlendFactor.VK_BLEND_FACTOR_ONE_MINUS_SRC1_COLOR;
enum VK_BLEND_FACTOR_SRC1_ALPHA                  = VkBlendFactor.VK_BLEND_FACTOR_SRC1_ALPHA;
enum VK_BLEND_FACTOR_ONE_MINUS_SRC1_ALPHA        = VkBlendFactor.VK_BLEND_FACTOR_ONE_MINUS_SRC1_ALPHA;
enum VK_BLEND_FACTOR_BEGIN_RANGE                 = VkBlendFactor.VK_BLEND_FACTOR_BEGIN_RANGE;
enum VK_BLEND_FACTOR_END_RANGE                   = VkBlendFactor.VK_BLEND_FACTOR_END_RANGE;
enum VK_BLEND_FACTOR_RANGE_SIZE                  = VkBlendFactor.VK_BLEND_FACTOR_RANGE_SIZE;
enum VK_BLEND_FACTOR_MAX_ENUM                    = VkBlendFactor.VK_BLEND_FACTOR_MAX_ENUM;

enum VkBlendOp {
    VK_BLEND_OP_ADD                      = 0,
    VK_BLEND_OP_SUBTRACT                 = 1,
    VK_BLEND_OP_REVERSE_SUBTRACT         = 2,
    VK_BLEND_OP_MIN                      = 3,
    VK_BLEND_OP_MAX                      = 4,
    VK_BLEND_OP_ZERO_EXT                 = 1000148000,
    VK_BLEND_OP_SRC_EXT                  = 1000148001,
    VK_BLEND_OP_DST_EXT                  = 1000148002,
    VK_BLEND_OP_SRC_OVER_EXT             = 1000148003,
    VK_BLEND_OP_DST_OVER_EXT             = 1000148004,
    VK_BLEND_OP_SRC_IN_EXT               = 1000148005,
    VK_BLEND_OP_DST_IN_EXT               = 1000148006,
    VK_BLEND_OP_SRC_OUT_EXT              = 1000148007,
    VK_BLEND_OP_DST_OUT_EXT              = 1000148008,
    VK_BLEND_OP_SRC_ATOP_EXT             = 1000148009,
    VK_BLEND_OP_DST_ATOP_EXT             = 1000148010,
    VK_BLEND_OP_XOR_EXT                  = 1000148011,
    VK_BLEND_OP_MULTIPLY_EXT             = 1000148012,
    VK_BLEND_OP_SCREEN_EXT               = 1000148013,
    VK_BLEND_OP_OVERLAY_EXT              = 1000148014,
    VK_BLEND_OP_DARKEN_EXT               = 1000148015,
    VK_BLEND_OP_LIGHTEN_EXT              = 1000148016,
    VK_BLEND_OP_COLORDODGE_EXT           = 1000148017,
    VK_BLEND_OP_COLORBURN_EXT            = 1000148018,
    VK_BLEND_OP_HARDLIGHT_EXT            = 1000148019,
    VK_BLEND_OP_SOFTLIGHT_EXT            = 1000148020,
    VK_BLEND_OP_DIFFERENCE_EXT           = 1000148021,
    VK_BLEND_OP_EXCLUSION_EXT            = 1000148022,
    VK_BLEND_OP_INVERT_EXT               = 1000148023,
    VK_BLEND_OP_INVERT_RGB_EXT           = 1000148024,
    VK_BLEND_OP_LINEARDODGE_EXT          = 1000148025,
    VK_BLEND_OP_LINEARBURN_EXT           = 1000148026,
    VK_BLEND_OP_VIVIDLIGHT_EXT           = 1000148027,
    VK_BLEND_OP_LINEARLIGHT_EXT          = 1000148028,
    VK_BLEND_OP_PINLIGHT_EXT             = 1000148029,
    VK_BLEND_OP_HARDMIX_EXT              = 1000148030,
    VK_BLEND_OP_HSL_HUE_EXT              = 1000148031,
    VK_BLEND_OP_HSL_SATURATION_EXT       = 1000148032,
    VK_BLEND_OP_HSL_COLOR_EXT            = 1000148033,
    VK_BLEND_OP_HSL_LUMINOSITY_EXT       = 1000148034,
    VK_BLEND_OP_PLUS_EXT                 = 1000148035,
    VK_BLEND_OP_PLUS_CLAMPED_EXT         = 1000148036,
    VK_BLEND_OP_PLUS_CLAMPED_ALPHA_EXT   = 1000148037,
    VK_BLEND_OP_PLUS_DARKER_EXT          = 1000148038,
    VK_BLEND_OP_MINUS_EXT                = 1000148039,
    VK_BLEND_OP_MINUS_CLAMPED_EXT        = 1000148040,
    VK_BLEND_OP_CONTRAST_EXT             = 1000148041,
    VK_BLEND_OP_INVERT_OVG_EXT           = 1000148042,
    VK_BLEND_OP_RED_EXT                  = 1000148043,
    VK_BLEND_OP_GREEN_EXT                = 1000148044,
    VK_BLEND_OP_BLUE_EXT                 = 1000148045,
    VK_BLEND_OP_BEGIN_RANGE              = VK_BLEND_OP_ADD,
    VK_BLEND_OP_END_RANGE                = VK_BLEND_OP_MAX,
    VK_BLEND_OP_RANGE_SIZE               = VK_BLEND_OP_MAX - VK_BLEND_OP_ADD + 1,
    VK_BLEND_OP_MAX_ENUM                 = 0x7FFFFFFF
}

enum VK_BLEND_OP_ADD                     = VkBlendOp.VK_BLEND_OP_ADD;
enum VK_BLEND_OP_SUBTRACT                = VkBlendOp.VK_BLEND_OP_SUBTRACT;
enum VK_BLEND_OP_REVERSE_SUBTRACT        = VkBlendOp.VK_BLEND_OP_REVERSE_SUBTRACT;
enum VK_BLEND_OP_MIN                     = VkBlendOp.VK_BLEND_OP_MIN;
enum VK_BLEND_OP_MAX                     = VkBlendOp.VK_BLEND_OP_MAX;
enum VK_BLEND_OP_ZERO_EXT                = VkBlendOp.VK_BLEND_OP_ZERO_EXT;
enum VK_BLEND_OP_SRC_EXT                 = VkBlendOp.VK_BLEND_OP_SRC_EXT;
enum VK_BLEND_OP_DST_EXT                 = VkBlendOp.VK_BLEND_OP_DST_EXT;
enum VK_BLEND_OP_SRC_OVER_EXT            = VkBlendOp.VK_BLEND_OP_SRC_OVER_EXT;
enum VK_BLEND_OP_DST_OVER_EXT            = VkBlendOp.VK_BLEND_OP_DST_OVER_EXT;
enum VK_BLEND_OP_SRC_IN_EXT              = VkBlendOp.VK_BLEND_OP_SRC_IN_EXT;
enum VK_BLEND_OP_DST_IN_EXT              = VkBlendOp.VK_BLEND_OP_DST_IN_EXT;
enum VK_BLEND_OP_SRC_OUT_EXT             = VkBlendOp.VK_BLEND_OP_SRC_OUT_EXT;
enum VK_BLEND_OP_DST_OUT_EXT             = VkBlendOp.VK_BLEND_OP_DST_OUT_EXT;
enum VK_BLEND_OP_SRC_ATOP_EXT            = VkBlendOp.VK_BLEND_OP_SRC_ATOP_EXT;
enum VK_BLEND_OP_DST_ATOP_EXT            = VkBlendOp.VK_BLEND_OP_DST_ATOP_EXT;
enum VK_BLEND_OP_XOR_EXT                 = VkBlendOp.VK_BLEND_OP_XOR_EXT;
enum VK_BLEND_OP_MULTIPLY_EXT            = VkBlendOp.VK_BLEND_OP_MULTIPLY_EXT;
enum VK_BLEND_OP_SCREEN_EXT              = VkBlendOp.VK_BLEND_OP_SCREEN_EXT;
enum VK_BLEND_OP_OVERLAY_EXT             = VkBlendOp.VK_BLEND_OP_OVERLAY_EXT;
enum VK_BLEND_OP_DARKEN_EXT              = VkBlendOp.VK_BLEND_OP_DARKEN_EXT;
enum VK_BLEND_OP_LIGHTEN_EXT             = VkBlendOp.VK_BLEND_OP_LIGHTEN_EXT;
enum VK_BLEND_OP_COLORDODGE_EXT          = VkBlendOp.VK_BLEND_OP_COLORDODGE_EXT;
enum VK_BLEND_OP_COLORBURN_EXT           = VkBlendOp.VK_BLEND_OP_COLORBURN_EXT;
enum VK_BLEND_OP_HARDLIGHT_EXT           = VkBlendOp.VK_BLEND_OP_HARDLIGHT_EXT;
enum VK_BLEND_OP_SOFTLIGHT_EXT           = VkBlendOp.VK_BLEND_OP_SOFTLIGHT_EXT;
enum VK_BLEND_OP_DIFFERENCE_EXT          = VkBlendOp.VK_BLEND_OP_DIFFERENCE_EXT;
enum VK_BLEND_OP_EXCLUSION_EXT           = VkBlendOp.VK_BLEND_OP_EXCLUSION_EXT;
enum VK_BLEND_OP_INVERT_EXT              = VkBlendOp.VK_BLEND_OP_INVERT_EXT;
enum VK_BLEND_OP_INVERT_RGB_EXT          = VkBlendOp.VK_BLEND_OP_INVERT_RGB_EXT;
enum VK_BLEND_OP_LINEARDODGE_EXT         = VkBlendOp.VK_BLEND_OP_LINEARDODGE_EXT;
enum VK_BLEND_OP_LINEARBURN_EXT          = VkBlendOp.VK_BLEND_OP_LINEARBURN_EXT;
enum VK_BLEND_OP_VIVIDLIGHT_EXT          = VkBlendOp.VK_BLEND_OP_VIVIDLIGHT_EXT;
enum VK_BLEND_OP_LINEARLIGHT_EXT         = VkBlendOp.VK_BLEND_OP_LINEARLIGHT_EXT;
enum VK_BLEND_OP_PINLIGHT_EXT            = VkBlendOp.VK_BLEND_OP_PINLIGHT_EXT;
enum VK_BLEND_OP_HARDMIX_EXT             = VkBlendOp.VK_BLEND_OP_HARDMIX_EXT;
enum VK_BLEND_OP_HSL_HUE_EXT             = VkBlendOp.VK_BLEND_OP_HSL_HUE_EXT;
enum VK_BLEND_OP_HSL_SATURATION_EXT      = VkBlendOp.VK_BLEND_OP_HSL_SATURATION_EXT;
enum VK_BLEND_OP_HSL_COLOR_EXT           = VkBlendOp.VK_BLEND_OP_HSL_COLOR_EXT;
enum VK_BLEND_OP_HSL_LUMINOSITY_EXT      = VkBlendOp.VK_BLEND_OP_HSL_LUMINOSITY_EXT;
enum VK_BLEND_OP_PLUS_EXT                = VkBlendOp.VK_BLEND_OP_PLUS_EXT;
enum VK_BLEND_OP_PLUS_CLAMPED_EXT        = VkBlendOp.VK_BLEND_OP_PLUS_CLAMPED_EXT;
enum VK_BLEND_OP_PLUS_CLAMPED_ALPHA_EXT  = VkBlendOp.VK_BLEND_OP_PLUS_CLAMPED_ALPHA_EXT;
enum VK_BLEND_OP_PLUS_DARKER_EXT         = VkBlendOp.VK_BLEND_OP_PLUS_DARKER_EXT;
enum VK_BLEND_OP_MINUS_EXT               = VkBlendOp.VK_BLEND_OP_MINUS_EXT;
enum VK_BLEND_OP_MINUS_CLAMPED_EXT       = VkBlendOp.VK_BLEND_OP_MINUS_CLAMPED_EXT;
enum VK_BLEND_OP_CONTRAST_EXT            = VkBlendOp.VK_BLEND_OP_CONTRAST_EXT;
enum VK_BLEND_OP_INVERT_OVG_EXT          = VkBlendOp.VK_BLEND_OP_INVERT_OVG_EXT;
enum VK_BLEND_OP_RED_EXT                 = VkBlendOp.VK_BLEND_OP_RED_EXT;
enum VK_BLEND_OP_GREEN_EXT               = VkBlendOp.VK_BLEND_OP_GREEN_EXT;
enum VK_BLEND_OP_BLUE_EXT                = VkBlendOp.VK_BLEND_OP_BLUE_EXT;
enum VK_BLEND_OP_BEGIN_RANGE             = VkBlendOp.VK_BLEND_OP_BEGIN_RANGE;
enum VK_BLEND_OP_END_RANGE               = VkBlendOp.VK_BLEND_OP_END_RANGE;
enum VK_BLEND_OP_RANGE_SIZE              = VkBlendOp.VK_BLEND_OP_RANGE_SIZE;
enum VK_BLEND_OP_MAX_ENUM                = VkBlendOp.VK_BLEND_OP_MAX_ENUM;

enum VkDynamicState {
    VK_DYNAMIC_STATE_VIEWPORT                            = 0,
    VK_DYNAMIC_STATE_SCISSOR                             = 1,
    VK_DYNAMIC_STATE_LINE_WIDTH                          = 2,
    VK_DYNAMIC_STATE_DEPTH_BIAS                          = 3,
    VK_DYNAMIC_STATE_BLEND_CONSTANTS                     = 4,
    VK_DYNAMIC_STATE_DEPTH_BOUNDS                        = 5,
    VK_DYNAMIC_STATE_STENCIL_COMPARE_MASK                = 6,
    VK_DYNAMIC_STATE_STENCIL_WRITE_MASK                  = 7,
    VK_DYNAMIC_STATE_STENCIL_REFERENCE                   = 8,
    VK_DYNAMIC_STATE_VIEWPORT_W_SCALING_NV               = 1000087000,
    VK_DYNAMIC_STATE_DISCARD_RECTANGLE_EXT               = 1000099000,
    VK_DYNAMIC_STATE_SAMPLE_LOCATIONS_EXT                = 1000143000,
    VK_DYNAMIC_STATE_VIEWPORT_SHADING_RATE_PALETTE_NV    = 1000164004,
    VK_DYNAMIC_STATE_VIEWPORT_COARSE_SAMPLE_ORDER_NV     = 1000164006,
    VK_DYNAMIC_STATE_EXCLUSIVE_SCISSOR_NV                = 1000205001,
    VK_DYNAMIC_STATE_BEGIN_RANGE                         = VK_DYNAMIC_STATE_VIEWPORT,
    VK_DYNAMIC_STATE_END_RANGE                           = VK_DYNAMIC_STATE_STENCIL_REFERENCE,
    VK_DYNAMIC_STATE_RANGE_SIZE                          = VK_DYNAMIC_STATE_STENCIL_REFERENCE - VK_DYNAMIC_STATE_VIEWPORT + 1,
    VK_DYNAMIC_STATE_MAX_ENUM                            = 0x7FFFFFFF
}

enum VK_DYNAMIC_STATE_VIEWPORT                           = VkDynamicState.VK_DYNAMIC_STATE_VIEWPORT;
enum VK_DYNAMIC_STATE_SCISSOR                            = VkDynamicState.VK_DYNAMIC_STATE_SCISSOR;
enum VK_DYNAMIC_STATE_LINE_WIDTH                         = VkDynamicState.VK_DYNAMIC_STATE_LINE_WIDTH;
enum VK_DYNAMIC_STATE_DEPTH_BIAS                         = VkDynamicState.VK_DYNAMIC_STATE_DEPTH_BIAS;
enum VK_DYNAMIC_STATE_BLEND_CONSTANTS                    = VkDynamicState.VK_DYNAMIC_STATE_BLEND_CONSTANTS;
enum VK_DYNAMIC_STATE_DEPTH_BOUNDS                       = VkDynamicState.VK_DYNAMIC_STATE_DEPTH_BOUNDS;
enum VK_DYNAMIC_STATE_STENCIL_COMPARE_MASK               = VkDynamicState.VK_DYNAMIC_STATE_STENCIL_COMPARE_MASK;
enum VK_DYNAMIC_STATE_STENCIL_WRITE_MASK                 = VkDynamicState.VK_DYNAMIC_STATE_STENCIL_WRITE_MASK;
enum VK_DYNAMIC_STATE_STENCIL_REFERENCE                  = VkDynamicState.VK_DYNAMIC_STATE_STENCIL_REFERENCE;
enum VK_DYNAMIC_STATE_VIEWPORT_W_SCALING_NV              = VkDynamicState.VK_DYNAMIC_STATE_VIEWPORT_W_SCALING_NV;
enum VK_DYNAMIC_STATE_DISCARD_RECTANGLE_EXT              = VkDynamicState.VK_DYNAMIC_STATE_DISCARD_RECTANGLE_EXT;
enum VK_DYNAMIC_STATE_SAMPLE_LOCATIONS_EXT               = VkDynamicState.VK_DYNAMIC_STATE_SAMPLE_LOCATIONS_EXT;
enum VK_DYNAMIC_STATE_VIEWPORT_SHADING_RATE_PALETTE_NV   = VkDynamicState.VK_DYNAMIC_STATE_VIEWPORT_SHADING_RATE_PALETTE_NV;
enum VK_DYNAMIC_STATE_VIEWPORT_COARSE_SAMPLE_ORDER_NV    = VkDynamicState.VK_DYNAMIC_STATE_VIEWPORT_COARSE_SAMPLE_ORDER_NV;
enum VK_DYNAMIC_STATE_EXCLUSIVE_SCISSOR_NV               = VkDynamicState.VK_DYNAMIC_STATE_EXCLUSIVE_SCISSOR_NV;
enum VK_DYNAMIC_STATE_BEGIN_RANGE                        = VkDynamicState.VK_DYNAMIC_STATE_BEGIN_RANGE;
enum VK_DYNAMIC_STATE_END_RANGE                          = VkDynamicState.VK_DYNAMIC_STATE_END_RANGE;
enum VK_DYNAMIC_STATE_RANGE_SIZE                         = VkDynamicState.VK_DYNAMIC_STATE_RANGE_SIZE;
enum VK_DYNAMIC_STATE_MAX_ENUM                           = VkDynamicState.VK_DYNAMIC_STATE_MAX_ENUM;

enum VkFilter {
    VK_FILTER_NEAREST            = 0,
    VK_FILTER_LINEAR             = 1,
    VK_FILTER_CUBIC_IMG          = 1000015000,
    VK_FILTER_CUBIC_EXT          = VK_FILTER_CUBIC_IMG,
    VK_FILTER_BEGIN_RANGE        = VK_FILTER_NEAREST,
    VK_FILTER_END_RANGE          = VK_FILTER_LINEAR,
    VK_FILTER_RANGE_SIZE         = VK_FILTER_LINEAR - VK_FILTER_NEAREST + 1,
    VK_FILTER_MAX_ENUM           = 0x7FFFFFFF
}

enum VK_FILTER_NEAREST           = VkFilter.VK_FILTER_NEAREST;
enum VK_FILTER_LINEAR            = VkFilter.VK_FILTER_LINEAR;
enum VK_FILTER_CUBIC_IMG         = VkFilter.VK_FILTER_CUBIC_IMG;
enum VK_FILTER_CUBIC_EXT         = VkFilter.VK_FILTER_CUBIC_EXT;
enum VK_FILTER_BEGIN_RANGE       = VkFilter.VK_FILTER_BEGIN_RANGE;
enum VK_FILTER_END_RANGE         = VkFilter.VK_FILTER_END_RANGE;
enum VK_FILTER_RANGE_SIZE        = VkFilter.VK_FILTER_RANGE_SIZE;
enum VK_FILTER_MAX_ENUM          = VkFilter.VK_FILTER_MAX_ENUM;

enum VkSamplerMipmapMode {
    VK_SAMPLER_MIPMAP_MODE_NEAREST       = 0,
    VK_SAMPLER_MIPMAP_MODE_LINEAR        = 1,
    VK_SAMPLER_MIPMAP_MODE_BEGIN_RANGE   = VK_SAMPLER_MIPMAP_MODE_NEAREST,
    VK_SAMPLER_MIPMAP_MODE_END_RANGE     = VK_SAMPLER_MIPMAP_MODE_LINEAR,
    VK_SAMPLER_MIPMAP_MODE_RANGE_SIZE    = VK_SAMPLER_MIPMAP_MODE_LINEAR - VK_SAMPLER_MIPMAP_MODE_NEAREST + 1,
    VK_SAMPLER_MIPMAP_MODE_MAX_ENUM      = 0x7FFFFFFF
}

enum VK_SAMPLER_MIPMAP_MODE_NEAREST      = VkSamplerMipmapMode.VK_SAMPLER_MIPMAP_MODE_NEAREST;
enum VK_SAMPLER_MIPMAP_MODE_LINEAR       = VkSamplerMipmapMode.VK_SAMPLER_MIPMAP_MODE_LINEAR;
enum VK_SAMPLER_MIPMAP_MODE_BEGIN_RANGE  = VkSamplerMipmapMode.VK_SAMPLER_MIPMAP_MODE_BEGIN_RANGE;
enum VK_SAMPLER_MIPMAP_MODE_END_RANGE    = VkSamplerMipmapMode.VK_SAMPLER_MIPMAP_MODE_END_RANGE;
enum VK_SAMPLER_MIPMAP_MODE_RANGE_SIZE   = VkSamplerMipmapMode.VK_SAMPLER_MIPMAP_MODE_RANGE_SIZE;
enum VK_SAMPLER_MIPMAP_MODE_MAX_ENUM     = VkSamplerMipmapMode.VK_SAMPLER_MIPMAP_MODE_MAX_ENUM;

enum VkSamplerAddressMode {
    VK_SAMPLER_ADDRESS_MODE_REPEAT                       = 0,
    VK_SAMPLER_ADDRESS_MODE_MIRRORED_REPEAT              = 1,
    VK_SAMPLER_ADDRESS_MODE_CLAMP_TO_EDGE                = 2,
    VK_SAMPLER_ADDRESS_MODE_CLAMP_TO_BORDER              = 3,
    VK_SAMPLER_ADDRESS_MODE_MIRROR_CLAMP_TO_EDGE         = 4,
    VK_SAMPLER_ADDRESS_MODE_BEGIN_RANGE                  = VK_SAMPLER_ADDRESS_MODE_REPEAT,
    VK_SAMPLER_ADDRESS_MODE_END_RANGE                    = VK_SAMPLER_ADDRESS_MODE_CLAMP_TO_BORDER,
    VK_SAMPLER_ADDRESS_MODE_RANGE_SIZE                   = VK_SAMPLER_ADDRESS_MODE_CLAMP_TO_BORDER - VK_SAMPLER_ADDRESS_MODE_REPEAT + 1,
    VK_SAMPLER_ADDRESS_MODE_MAX_ENUM                     = 0x7FFFFFFF
}

enum VK_SAMPLER_ADDRESS_MODE_REPEAT                      = VkSamplerAddressMode.VK_SAMPLER_ADDRESS_MODE_REPEAT;
enum VK_SAMPLER_ADDRESS_MODE_MIRRORED_REPEAT             = VkSamplerAddressMode.VK_SAMPLER_ADDRESS_MODE_MIRRORED_REPEAT;
enum VK_SAMPLER_ADDRESS_MODE_CLAMP_TO_EDGE               = VkSamplerAddressMode.VK_SAMPLER_ADDRESS_MODE_CLAMP_TO_EDGE;
enum VK_SAMPLER_ADDRESS_MODE_CLAMP_TO_BORDER             = VkSamplerAddressMode.VK_SAMPLER_ADDRESS_MODE_CLAMP_TO_BORDER;
enum VK_SAMPLER_ADDRESS_MODE_MIRROR_CLAMP_TO_EDGE        = VkSamplerAddressMode.VK_SAMPLER_ADDRESS_MODE_MIRROR_CLAMP_TO_EDGE;
enum VK_SAMPLER_ADDRESS_MODE_BEGIN_RANGE                 = VkSamplerAddressMode.VK_SAMPLER_ADDRESS_MODE_BEGIN_RANGE;
enum VK_SAMPLER_ADDRESS_MODE_END_RANGE                   = VkSamplerAddressMode.VK_SAMPLER_ADDRESS_MODE_END_RANGE;
enum VK_SAMPLER_ADDRESS_MODE_RANGE_SIZE                  = VkSamplerAddressMode.VK_SAMPLER_ADDRESS_MODE_RANGE_SIZE;
enum VK_SAMPLER_ADDRESS_MODE_MAX_ENUM                    = VkSamplerAddressMode.VK_SAMPLER_ADDRESS_MODE_MAX_ENUM;

enum VkBorderColor {
    VK_BORDER_COLOR_FLOAT_TRANSPARENT_BLACK      = 0,
    VK_BORDER_COLOR_INT_TRANSPARENT_BLACK        = 1,
    VK_BORDER_COLOR_FLOAT_OPAQUE_BLACK           = 2,
    VK_BORDER_COLOR_INT_OPAQUE_BLACK             = 3,
    VK_BORDER_COLOR_FLOAT_OPAQUE_WHITE           = 4,
    VK_BORDER_COLOR_INT_OPAQUE_WHITE             = 5,
    VK_BORDER_COLOR_BEGIN_RANGE                  = VK_BORDER_COLOR_FLOAT_TRANSPARENT_BLACK,
    VK_BORDER_COLOR_END_RANGE                    = VK_BORDER_COLOR_INT_OPAQUE_WHITE,
    VK_BORDER_COLOR_RANGE_SIZE                   = VK_BORDER_COLOR_INT_OPAQUE_WHITE - VK_BORDER_COLOR_FLOAT_TRANSPARENT_BLACK + 1,
    VK_BORDER_COLOR_MAX_ENUM                     = 0x7FFFFFFF
}

enum VK_BORDER_COLOR_FLOAT_TRANSPARENT_BLACK     = VkBorderColor.VK_BORDER_COLOR_FLOAT_TRANSPARENT_BLACK;
enum VK_BORDER_COLOR_INT_TRANSPARENT_BLACK       = VkBorderColor.VK_BORDER_COLOR_INT_TRANSPARENT_BLACK;
enum VK_BORDER_COLOR_FLOAT_OPAQUE_BLACK          = VkBorderColor.VK_BORDER_COLOR_FLOAT_OPAQUE_BLACK;
enum VK_BORDER_COLOR_INT_OPAQUE_BLACK            = VkBorderColor.VK_BORDER_COLOR_INT_OPAQUE_BLACK;
enum VK_BORDER_COLOR_FLOAT_OPAQUE_WHITE          = VkBorderColor.VK_BORDER_COLOR_FLOAT_OPAQUE_WHITE;
enum VK_BORDER_COLOR_INT_OPAQUE_WHITE            = VkBorderColor.VK_BORDER_COLOR_INT_OPAQUE_WHITE;
enum VK_BORDER_COLOR_BEGIN_RANGE                 = VkBorderColor.VK_BORDER_COLOR_BEGIN_RANGE;
enum VK_BORDER_COLOR_END_RANGE                   = VkBorderColor.VK_BORDER_COLOR_END_RANGE;
enum VK_BORDER_COLOR_RANGE_SIZE                  = VkBorderColor.VK_BORDER_COLOR_RANGE_SIZE;
enum VK_BORDER_COLOR_MAX_ENUM                    = VkBorderColor.VK_BORDER_COLOR_MAX_ENUM;

enum VkDescriptorType {
    VK_DESCRIPTOR_TYPE_SAMPLER                           = 0,
    VK_DESCRIPTOR_TYPE_COMBINED_IMAGE_SAMPLER            = 1,
    VK_DESCRIPTOR_TYPE_SAMPLED_IMAGE                     = 2,
    VK_DESCRIPTOR_TYPE_STORAGE_IMAGE                     = 3,
    VK_DESCRIPTOR_TYPE_UNIFORM_TEXEL_BUFFER              = 4,
    VK_DESCRIPTOR_TYPE_STORAGE_TEXEL_BUFFER              = 5,
    VK_DESCRIPTOR_TYPE_UNIFORM_BUFFER                    = 6,
    VK_DESCRIPTOR_TYPE_STORAGE_BUFFER                    = 7,
    VK_DESCRIPTOR_TYPE_UNIFORM_BUFFER_DYNAMIC            = 8,
    VK_DESCRIPTOR_TYPE_STORAGE_BUFFER_DYNAMIC            = 9,
    VK_DESCRIPTOR_TYPE_INPUT_ATTACHMENT                  = 10,
    VK_DESCRIPTOR_TYPE_INLINE_UNIFORM_BLOCK_EXT          = 1000138000,
    VK_DESCRIPTOR_TYPE_ACCELERATION_STRUCTURE_NV         = 1000165000,
    VK_DESCRIPTOR_TYPE_BEGIN_RANGE                       = VK_DESCRIPTOR_TYPE_SAMPLER,
    VK_DESCRIPTOR_TYPE_END_RANGE                         = VK_DESCRIPTOR_TYPE_INPUT_ATTACHMENT,
    VK_DESCRIPTOR_TYPE_RANGE_SIZE                        = VK_DESCRIPTOR_TYPE_INPUT_ATTACHMENT - VK_DESCRIPTOR_TYPE_SAMPLER + 1,
    VK_DESCRIPTOR_TYPE_MAX_ENUM                          = 0x7FFFFFFF
}

enum VK_DESCRIPTOR_TYPE_SAMPLER                          = VkDescriptorType.VK_DESCRIPTOR_TYPE_SAMPLER;
enum VK_DESCRIPTOR_TYPE_COMBINED_IMAGE_SAMPLER           = VkDescriptorType.VK_DESCRIPTOR_TYPE_COMBINED_IMAGE_SAMPLER;
enum VK_DESCRIPTOR_TYPE_SAMPLED_IMAGE                    = VkDescriptorType.VK_DESCRIPTOR_TYPE_SAMPLED_IMAGE;
enum VK_DESCRIPTOR_TYPE_STORAGE_IMAGE                    = VkDescriptorType.VK_DESCRIPTOR_TYPE_STORAGE_IMAGE;
enum VK_DESCRIPTOR_TYPE_UNIFORM_TEXEL_BUFFER             = VkDescriptorType.VK_DESCRIPTOR_TYPE_UNIFORM_TEXEL_BUFFER;
enum VK_DESCRIPTOR_TYPE_STORAGE_TEXEL_BUFFER             = VkDescriptorType.VK_DESCRIPTOR_TYPE_STORAGE_TEXEL_BUFFER;
enum VK_DESCRIPTOR_TYPE_UNIFORM_BUFFER                   = VkDescriptorType.VK_DESCRIPTOR_TYPE_UNIFORM_BUFFER;
enum VK_DESCRIPTOR_TYPE_STORAGE_BUFFER                   = VkDescriptorType.VK_DESCRIPTOR_TYPE_STORAGE_BUFFER;
enum VK_DESCRIPTOR_TYPE_UNIFORM_BUFFER_DYNAMIC           = VkDescriptorType.VK_DESCRIPTOR_TYPE_UNIFORM_BUFFER_DYNAMIC;
enum VK_DESCRIPTOR_TYPE_STORAGE_BUFFER_DYNAMIC           = VkDescriptorType.VK_DESCRIPTOR_TYPE_STORAGE_BUFFER_DYNAMIC;
enum VK_DESCRIPTOR_TYPE_INPUT_ATTACHMENT                 = VkDescriptorType.VK_DESCRIPTOR_TYPE_INPUT_ATTACHMENT;
enum VK_DESCRIPTOR_TYPE_INLINE_UNIFORM_BLOCK_EXT         = VkDescriptorType.VK_DESCRIPTOR_TYPE_INLINE_UNIFORM_BLOCK_EXT;
enum VK_DESCRIPTOR_TYPE_ACCELERATION_STRUCTURE_NV        = VkDescriptorType.VK_DESCRIPTOR_TYPE_ACCELERATION_STRUCTURE_NV;
enum VK_DESCRIPTOR_TYPE_BEGIN_RANGE                      = VkDescriptorType.VK_DESCRIPTOR_TYPE_BEGIN_RANGE;
enum VK_DESCRIPTOR_TYPE_END_RANGE                        = VkDescriptorType.VK_DESCRIPTOR_TYPE_END_RANGE;
enum VK_DESCRIPTOR_TYPE_RANGE_SIZE                       = VkDescriptorType.VK_DESCRIPTOR_TYPE_RANGE_SIZE;
enum VK_DESCRIPTOR_TYPE_MAX_ENUM                         = VkDescriptorType.VK_DESCRIPTOR_TYPE_MAX_ENUM;

enum VkAttachmentLoadOp {
    VK_ATTACHMENT_LOAD_OP_LOAD           = 0,
    VK_ATTACHMENT_LOAD_OP_CLEAR          = 1,
    VK_ATTACHMENT_LOAD_OP_DONT_CARE      = 2,
    VK_ATTACHMENT_LOAD_OP_BEGIN_RANGE    = VK_ATTACHMENT_LOAD_OP_LOAD,
    VK_ATTACHMENT_LOAD_OP_END_RANGE      = VK_ATTACHMENT_LOAD_OP_DONT_CARE,
    VK_ATTACHMENT_LOAD_OP_RANGE_SIZE     = VK_ATTACHMENT_LOAD_OP_DONT_CARE - VK_ATTACHMENT_LOAD_OP_LOAD + 1,
    VK_ATTACHMENT_LOAD_OP_MAX_ENUM       = 0x7FFFFFFF
}

enum VK_ATTACHMENT_LOAD_OP_LOAD          = VkAttachmentLoadOp.VK_ATTACHMENT_LOAD_OP_LOAD;
enum VK_ATTACHMENT_LOAD_OP_CLEAR         = VkAttachmentLoadOp.VK_ATTACHMENT_LOAD_OP_CLEAR;
enum VK_ATTACHMENT_LOAD_OP_DONT_CARE     = VkAttachmentLoadOp.VK_ATTACHMENT_LOAD_OP_DONT_CARE;
enum VK_ATTACHMENT_LOAD_OP_BEGIN_RANGE   = VkAttachmentLoadOp.VK_ATTACHMENT_LOAD_OP_BEGIN_RANGE;
enum VK_ATTACHMENT_LOAD_OP_END_RANGE     = VkAttachmentLoadOp.VK_ATTACHMENT_LOAD_OP_END_RANGE;
enum VK_ATTACHMENT_LOAD_OP_RANGE_SIZE    = VkAttachmentLoadOp.VK_ATTACHMENT_LOAD_OP_RANGE_SIZE;
enum VK_ATTACHMENT_LOAD_OP_MAX_ENUM      = VkAttachmentLoadOp.VK_ATTACHMENT_LOAD_OP_MAX_ENUM;

enum VkAttachmentStoreOp {
    VK_ATTACHMENT_STORE_OP_STORE         = 0,
    VK_ATTACHMENT_STORE_OP_DONT_CARE     = 1,
    VK_ATTACHMENT_STORE_OP_BEGIN_RANGE   = VK_ATTACHMENT_STORE_OP_STORE,
    VK_ATTACHMENT_STORE_OP_END_RANGE     = VK_ATTACHMENT_STORE_OP_DONT_CARE,
    VK_ATTACHMENT_STORE_OP_RANGE_SIZE    = VK_ATTACHMENT_STORE_OP_DONT_CARE - VK_ATTACHMENT_STORE_OP_STORE + 1,
    VK_ATTACHMENT_STORE_OP_MAX_ENUM      = 0x7FFFFFFF
}

enum VK_ATTACHMENT_STORE_OP_STORE        = VkAttachmentStoreOp.VK_ATTACHMENT_STORE_OP_STORE;
enum VK_ATTACHMENT_STORE_OP_DONT_CARE    = VkAttachmentStoreOp.VK_ATTACHMENT_STORE_OP_DONT_CARE;
enum VK_ATTACHMENT_STORE_OP_BEGIN_RANGE  = VkAttachmentStoreOp.VK_ATTACHMENT_STORE_OP_BEGIN_RANGE;
enum VK_ATTACHMENT_STORE_OP_END_RANGE    = VkAttachmentStoreOp.VK_ATTACHMENT_STORE_OP_END_RANGE;
enum VK_ATTACHMENT_STORE_OP_RANGE_SIZE   = VkAttachmentStoreOp.VK_ATTACHMENT_STORE_OP_RANGE_SIZE;
enum VK_ATTACHMENT_STORE_OP_MAX_ENUM     = VkAttachmentStoreOp.VK_ATTACHMENT_STORE_OP_MAX_ENUM;

enum VkPipelineBindPoint {
    VK_PIPELINE_BIND_POINT_GRAPHICS              = 0,
    VK_PIPELINE_BIND_POINT_COMPUTE               = 1,
    VK_PIPELINE_BIND_POINT_RAY_TRACING_NV        = 1000165000,
    VK_PIPELINE_BIND_POINT_BEGIN_RANGE           = VK_PIPELINE_BIND_POINT_GRAPHICS,
    VK_PIPELINE_BIND_POINT_END_RANGE             = VK_PIPELINE_BIND_POINT_COMPUTE,
    VK_PIPELINE_BIND_POINT_RANGE_SIZE            = VK_PIPELINE_BIND_POINT_COMPUTE - VK_PIPELINE_BIND_POINT_GRAPHICS + 1,
    VK_PIPELINE_BIND_POINT_MAX_ENUM              = 0x7FFFFFFF
}

enum VK_PIPELINE_BIND_POINT_GRAPHICS             = VkPipelineBindPoint.VK_PIPELINE_BIND_POINT_GRAPHICS;
enum VK_PIPELINE_BIND_POINT_COMPUTE              = VkPipelineBindPoint.VK_PIPELINE_BIND_POINT_COMPUTE;
enum VK_PIPELINE_BIND_POINT_RAY_TRACING_NV       = VkPipelineBindPoint.VK_PIPELINE_BIND_POINT_RAY_TRACING_NV;
enum VK_PIPELINE_BIND_POINT_BEGIN_RANGE          = VkPipelineBindPoint.VK_PIPELINE_BIND_POINT_BEGIN_RANGE;
enum VK_PIPELINE_BIND_POINT_END_RANGE            = VkPipelineBindPoint.VK_PIPELINE_BIND_POINT_END_RANGE;
enum VK_PIPELINE_BIND_POINT_RANGE_SIZE           = VkPipelineBindPoint.VK_PIPELINE_BIND_POINT_RANGE_SIZE;
enum VK_PIPELINE_BIND_POINT_MAX_ENUM             = VkPipelineBindPoint.VK_PIPELINE_BIND_POINT_MAX_ENUM;

enum VkCommandBufferLevel {
    VK_COMMAND_BUFFER_LEVEL_PRIMARY      = 0,
    VK_COMMAND_BUFFER_LEVEL_SECONDARY    = 1,
    VK_COMMAND_BUFFER_LEVEL_BEGIN_RANGE  = VK_COMMAND_BUFFER_LEVEL_PRIMARY,
    VK_COMMAND_BUFFER_LEVEL_END_RANGE    = VK_COMMAND_BUFFER_LEVEL_SECONDARY,
    VK_COMMAND_BUFFER_LEVEL_RANGE_SIZE   = VK_COMMAND_BUFFER_LEVEL_SECONDARY - VK_COMMAND_BUFFER_LEVEL_PRIMARY + 1,
    VK_COMMAND_BUFFER_LEVEL_MAX_ENUM     = 0x7FFFFFFF
}

enum VK_COMMAND_BUFFER_LEVEL_PRIMARY     = VkCommandBufferLevel.VK_COMMAND_BUFFER_LEVEL_PRIMARY;
enum VK_COMMAND_BUFFER_LEVEL_SECONDARY   = VkCommandBufferLevel.VK_COMMAND_BUFFER_LEVEL_SECONDARY;
enum VK_COMMAND_BUFFER_LEVEL_BEGIN_RANGE = VkCommandBufferLevel.VK_COMMAND_BUFFER_LEVEL_BEGIN_RANGE;
enum VK_COMMAND_BUFFER_LEVEL_END_RANGE   = VkCommandBufferLevel.VK_COMMAND_BUFFER_LEVEL_END_RANGE;
enum VK_COMMAND_BUFFER_LEVEL_RANGE_SIZE  = VkCommandBufferLevel.VK_COMMAND_BUFFER_LEVEL_RANGE_SIZE;
enum VK_COMMAND_BUFFER_LEVEL_MAX_ENUM    = VkCommandBufferLevel.VK_COMMAND_BUFFER_LEVEL_MAX_ENUM;

enum VkIndexType {
    VK_INDEX_TYPE_UINT16         = 0,
    VK_INDEX_TYPE_UINT32         = 1,
    VK_INDEX_TYPE_NONE_NV        = 1000165000,
    VK_INDEX_TYPE_BEGIN_RANGE    = VK_INDEX_TYPE_UINT16,
    VK_INDEX_TYPE_END_RANGE      = VK_INDEX_TYPE_UINT32,
    VK_INDEX_TYPE_RANGE_SIZE     = VK_INDEX_TYPE_UINT32 - VK_INDEX_TYPE_UINT16 + 1,
    VK_INDEX_TYPE_MAX_ENUM       = 0x7FFFFFFF
}

enum VK_INDEX_TYPE_UINT16        = VkIndexType.VK_INDEX_TYPE_UINT16;
enum VK_INDEX_TYPE_UINT32        = VkIndexType.VK_INDEX_TYPE_UINT32;
enum VK_INDEX_TYPE_NONE_NV       = VkIndexType.VK_INDEX_TYPE_NONE_NV;
enum VK_INDEX_TYPE_BEGIN_RANGE   = VkIndexType.VK_INDEX_TYPE_BEGIN_RANGE;
enum VK_INDEX_TYPE_END_RANGE     = VkIndexType.VK_INDEX_TYPE_END_RANGE;
enum VK_INDEX_TYPE_RANGE_SIZE    = VkIndexType.VK_INDEX_TYPE_RANGE_SIZE;
enum VK_INDEX_TYPE_MAX_ENUM      = VkIndexType.VK_INDEX_TYPE_MAX_ENUM;

enum VkSubpassContents {
    VK_SUBPASS_CONTENTS_INLINE                           = 0,
    VK_SUBPASS_CONTENTS_SECONDARY_COMMAND_BUFFERS        = 1,
    VK_SUBPASS_CONTENTS_BEGIN_RANGE                      = VK_SUBPASS_CONTENTS_INLINE,
    VK_SUBPASS_CONTENTS_END_RANGE                        = VK_SUBPASS_CONTENTS_SECONDARY_COMMAND_BUFFERS,
    VK_SUBPASS_CONTENTS_RANGE_SIZE                       = VK_SUBPASS_CONTENTS_SECONDARY_COMMAND_BUFFERS - VK_SUBPASS_CONTENTS_INLINE + 1,
    VK_SUBPASS_CONTENTS_MAX_ENUM                         = 0x7FFFFFFF
}

enum VK_SUBPASS_CONTENTS_INLINE                          = VkSubpassContents.VK_SUBPASS_CONTENTS_INLINE;
enum VK_SUBPASS_CONTENTS_SECONDARY_COMMAND_BUFFERS       = VkSubpassContents.VK_SUBPASS_CONTENTS_SECONDARY_COMMAND_BUFFERS;
enum VK_SUBPASS_CONTENTS_BEGIN_RANGE                     = VkSubpassContents.VK_SUBPASS_CONTENTS_BEGIN_RANGE;
enum VK_SUBPASS_CONTENTS_END_RANGE                       = VkSubpassContents.VK_SUBPASS_CONTENTS_END_RANGE;
enum VK_SUBPASS_CONTENTS_RANGE_SIZE                      = VkSubpassContents.VK_SUBPASS_CONTENTS_RANGE_SIZE;
enum VK_SUBPASS_CONTENTS_MAX_ENUM                        = VkSubpassContents.VK_SUBPASS_CONTENTS_MAX_ENUM;

enum VkObjectType {
    VK_OBJECT_TYPE_UNKNOWN                               = 0,
    VK_OBJECT_TYPE_INSTANCE                              = 1,
    VK_OBJECT_TYPE_PHYSICAL_DEVICE                       = 2,
    VK_OBJECT_TYPE_DEVICE                                = 3,
    VK_OBJECT_TYPE_QUEUE                                 = 4,
    VK_OBJECT_TYPE_SEMAPHORE                             = 5,
    VK_OBJECT_TYPE_COMMAND_BUFFER                        = 6,
    VK_OBJECT_TYPE_FENCE                                 = 7,
    VK_OBJECT_TYPE_DEVICE_MEMORY                         = 8,
    VK_OBJECT_TYPE_BUFFER                                = 9,
    VK_OBJECT_TYPE_IMAGE                                 = 10,
    VK_OBJECT_TYPE_EVENT                                 = 11,
    VK_OBJECT_TYPE_QUERY_POOL                            = 12,
    VK_OBJECT_TYPE_BUFFER_VIEW                           = 13,
    VK_OBJECT_TYPE_IMAGE_VIEW                            = 14,
    VK_OBJECT_TYPE_SHADER_MODULE                         = 15,
    VK_OBJECT_TYPE_PIPELINE_CACHE                        = 16,
    VK_OBJECT_TYPE_PIPELINE_LAYOUT                       = 17,
    VK_OBJECT_TYPE_RENDER_PASS                           = 18,
    VK_OBJECT_TYPE_PIPELINE                              = 19,
    VK_OBJECT_TYPE_DESCRIPTOR_SET_LAYOUT                 = 20,
    VK_OBJECT_TYPE_SAMPLER                               = 21,
    VK_OBJECT_TYPE_DESCRIPTOR_POOL                       = 22,
    VK_OBJECT_TYPE_DESCRIPTOR_SET                        = 23,
    VK_OBJECT_TYPE_FRAMEBUFFER                           = 24,
    VK_OBJECT_TYPE_COMMAND_POOL                          = 25,
    VK_OBJECT_TYPE_SAMPLER_YCBCR_CONVERSION              = 1000156000,
    VK_OBJECT_TYPE_DESCRIPTOR_UPDATE_TEMPLATE            = 1000085000,
    VK_OBJECT_TYPE_SURFACE_KHR                           = 1000000000,
    VK_OBJECT_TYPE_SWAPCHAIN_KHR                         = 1000001000,
    VK_OBJECT_TYPE_DISPLAY_KHR                           = 1000002000,
    VK_OBJECT_TYPE_DISPLAY_MODE_KHR                      = 1000002001,
    VK_OBJECT_TYPE_DEBUG_REPORT_CALLBACK_EXT             = 1000011000,
    VK_OBJECT_TYPE_OBJECT_TABLE_NVX                      = 1000086000,
    VK_OBJECT_TYPE_INDIRECT_COMMANDS_LAYOUT_NVX          = 1000086001,
    VK_OBJECT_TYPE_DEBUG_UTILS_MESSENGER_EXT             = 1000128000,
    VK_OBJECT_TYPE_VALIDATION_CACHE_EXT                  = 1000160000,
    VK_OBJECT_TYPE_ACCELERATION_STRUCTURE_NV             = 1000165000,
    VK_OBJECT_TYPE_PERFORMANCE_CONFIGURATION_INTEL       = 1000210000,
    VK_OBJECT_TYPE_DESCRIPTOR_UPDATE_TEMPLATE_KHR        = VK_OBJECT_TYPE_DESCRIPTOR_UPDATE_TEMPLATE,
    VK_OBJECT_TYPE_SAMPLER_YCBCR_CONVERSION_KHR          = VK_OBJECT_TYPE_SAMPLER_YCBCR_CONVERSION,
    VK_OBJECT_TYPE_BEGIN_RANGE                           = VK_OBJECT_TYPE_UNKNOWN,
    VK_OBJECT_TYPE_END_RANGE                             = VK_OBJECT_TYPE_COMMAND_POOL,
    VK_OBJECT_TYPE_RANGE_SIZE                            = VK_OBJECT_TYPE_COMMAND_POOL - VK_OBJECT_TYPE_UNKNOWN + 1,
    VK_OBJECT_TYPE_MAX_ENUM                              = 0x7FFFFFFF
}

enum VK_OBJECT_TYPE_UNKNOWN                              = VkObjectType.VK_OBJECT_TYPE_UNKNOWN;
enum VK_OBJECT_TYPE_INSTANCE                             = VkObjectType.VK_OBJECT_TYPE_INSTANCE;
enum VK_OBJECT_TYPE_PHYSICAL_DEVICE                      = VkObjectType.VK_OBJECT_TYPE_PHYSICAL_DEVICE;
enum VK_OBJECT_TYPE_DEVICE                               = VkObjectType.VK_OBJECT_TYPE_DEVICE;
enum VK_OBJECT_TYPE_QUEUE                                = VkObjectType.VK_OBJECT_TYPE_QUEUE;
enum VK_OBJECT_TYPE_SEMAPHORE                            = VkObjectType.VK_OBJECT_TYPE_SEMAPHORE;
enum VK_OBJECT_TYPE_COMMAND_BUFFER                       = VkObjectType.VK_OBJECT_TYPE_COMMAND_BUFFER;
enum VK_OBJECT_TYPE_FENCE                                = VkObjectType.VK_OBJECT_TYPE_FENCE;
enum VK_OBJECT_TYPE_DEVICE_MEMORY                        = VkObjectType.VK_OBJECT_TYPE_DEVICE_MEMORY;
enum VK_OBJECT_TYPE_BUFFER                               = VkObjectType.VK_OBJECT_TYPE_BUFFER;
enum VK_OBJECT_TYPE_IMAGE                                = VkObjectType.VK_OBJECT_TYPE_IMAGE;
enum VK_OBJECT_TYPE_EVENT                                = VkObjectType.VK_OBJECT_TYPE_EVENT;
enum VK_OBJECT_TYPE_QUERY_POOL                           = VkObjectType.VK_OBJECT_TYPE_QUERY_POOL;
enum VK_OBJECT_TYPE_BUFFER_VIEW                          = VkObjectType.VK_OBJECT_TYPE_BUFFER_VIEW;
enum VK_OBJECT_TYPE_IMAGE_VIEW                           = VkObjectType.VK_OBJECT_TYPE_IMAGE_VIEW;
enum VK_OBJECT_TYPE_SHADER_MODULE                        = VkObjectType.VK_OBJECT_TYPE_SHADER_MODULE;
enum VK_OBJECT_TYPE_PIPELINE_CACHE                       = VkObjectType.VK_OBJECT_TYPE_PIPELINE_CACHE;
enum VK_OBJECT_TYPE_PIPELINE_LAYOUT                      = VkObjectType.VK_OBJECT_TYPE_PIPELINE_LAYOUT;
enum VK_OBJECT_TYPE_RENDER_PASS                          = VkObjectType.VK_OBJECT_TYPE_RENDER_PASS;
enum VK_OBJECT_TYPE_PIPELINE                             = VkObjectType.VK_OBJECT_TYPE_PIPELINE;
enum VK_OBJECT_TYPE_DESCRIPTOR_SET_LAYOUT                = VkObjectType.VK_OBJECT_TYPE_DESCRIPTOR_SET_LAYOUT;
enum VK_OBJECT_TYPE_SAMPLER                              = VkObjectType.VK_OBJECT_TYPE_SAMPLER;
enum VK_OBJECT_TYPE_DESCRIPTOR_POOL                      = VkObjectType.VK_OBJECT_TYPE_DESCRIPTOR_POOL;
enum VK_OBJECT_TYPE_DESCRIPTOR_SET                       = VkObjectType.VK_OBJECT_TYPE_DESCRIPTOR_SET;
enum VK_OBJECT_TYPE_FRAMEBUFFER                          = VkObjectType.VK_OBJECT_TYPE_FRAMEBUFFER;
enum VK_OBJECT_TYPE_COMMAND_POOL                         = VkObjectType.VK_OBJECT_TYPE_COMMAND_POOL;
enum VK_OBJECT_TYPE_SAMPLER_YCBCR_CONVERSION             = VkObjectType.VK_OBJECT_TYPE_SAMPLER_YCBCR_CONVERSION;
enum VK_OBJECT_TYPE_DESCRIPTOR_UPDATE_TEMPLATE           = VkObjectType.VK_OBJECT_TYPE_DESCRIPTOR_UPDATE_TEMPLATE;
enum VK_OBJECT_TYPE_SURFACE_KHR                          = VkObjectType.VK_OBJECT_TYPE_SURFACE_KHR;
enum VK_OBJECT_TYPE_SWAPCHAIN_KHR                        = VkObjectType.VK_OBJECT_TYPE_SWAPCHAIN_KHR;
enum VK_OBJECT_TYPE_DISPLAY_KHR                          = VkObjectType.VK_OBJECT_TYPE_DISPLAY_KHR;
enum VK_OBJECT_TYPE_DISPLAY_MODE_KHR                     = VkObjectType.VK_OBJECT_TYPE_DISPLAY_MODE_KHR;
enum VK_OBJECT_TYPE_DEBUG_REPORT_CALLBACK_EXT            = VkObjectType.VK_OBJECT_TYPE_DEBUG_REPORT_CALLBACK_EXT;
enum VK_OBJECT_TYPE_OBJECT_TABLE_NVX                     = VkObjectType.VK_OBJECT_TYPE_OBJECT_TABLE_NVX;
enum VK_OBJECT_TYPE_INDIRECT_COMMANDS_LAYOUT_NVX         = VkObjectType.VK_OBJECT_TYPE_INDIRECT_COMMANDS_LAYOUT_NVX;
enum VK_OBJECT_TYPE_DEBUG_UTILS_MESSENGER_EXT            = VkObjectType.VK_OBJECT_TYPE_DEBUG_UTILS_MESSENGER_EXT;
enum VK_OBJECT_TYPE_VALIDATION_CACHE_EXT                 = VkObjectType.VK_OBJECT_TYPE_VALIDATION_CACHE_EXT;
enum VK_OBJECT_TYPE_ACCELERATION_STRUCTURE_NV            = VkObjectType.VK_OBJECT_TYPE_ACCELERATION_STRUCTURE_NV;
enum VK_OBJECT_TYPE_PERFORMANCE_CONFIGURATION_INTEL      = VkObjectType.VK_OBJECT_TYPE_PERFORMANCE_CONFIGURATION_INTEL;
enum VK_OBJECT_TYPE_DESCRIPTOR_UPDATE_TEMPLATE_KHR       = VkObjectType.VK_OBJECT_TYPE_DESCRIPTOR_UPDATE_TEMPLATE_KHR;
enum VK_OBJECT_TYPE_SAMPLER_YCBCR_CONVERSION_KHR         = VkObjectType.VK_OBJECT_TYPE_SAMPLER_YCBCR_CONVERSION_KHR;
enum VK_OBJECT_TYPE_BEGIN_RANGE                          = VkObjectType.VK_OBJECT_TYPE_BEGIN_RANGE;
enum VK_OBJECT_TYPE_END_RANGE                            = VkObjectType.VK_OBJECT_TYPE_END_RANGE;
enum VK_OBJECT_TYPE_RANGE_SIZE                           = VkObjectType.VK_OBJECT_TYPE_RANGE_SIZE;
enum VK_OBJECT_TYPE_MAX_ENUM                             = VkObjectType.VK_OBJECT_TYPE_MAX_ENUM;

enum VkVendorId {
    VK_VENDOR_ID_VIV             = 0x10001,
    VK_VENDOR_ID_VSI             = 0x10002,
    VK_VENDOR_ID_KAZAN           = 0x10003,
    VK_VENDOR_ID_BEGIN_RANGE     = VK_VENDOR_ID_VIV,
    VK_VENDOR_ID_END_RANGE       = VK_VENDOR_ID_KAZAN,
    VK_VENDOR_ID_RANGE_SIZE      = VK_VENDOR_ID_KAZAN - VK_VENDOR_ID_VIV + 1,
    VK_VENDOR_ID_MAX_ENUM        = 0x7FFFFFFF
}

enum VK_VENDOR_ID_VIV            = VkVendorId.VK_VENDOR_ID_VIV;
enum VK_VENDOR_ID_VSI            = VkVendorId.VK_VENDOR_ID_VSI;
enum VK_VENDOR_ID_KAZAN          = VkVendorId.VK_VENDOR_ID_KAZAN;
enum VK_VENDOR_ID_BEGIN_RANGE    = VkVendorId.VK_VENDOR_ID_BEGIN_RANGE;
enum VK_VENDOR_ID_END_RANGE      = VkVendorId.VK_VENDOR_ID_END_RANGE;
enum VK_VENDOR_ID_RANGE_SIZE     = VkVendorId.VK_VENDOR_ID_RANGE_SIZE;
enum VK_VENDOR_ID_MAX_ENUM       = VkVendorId.VK_VENDOR_ID_MAX_ENUM;

alias VkInstanceCreateFlags = VkFlags;

enum VkFormatFeatureFlagBits {
    VK_FORMAT_FEATURE_SAMPLED_IMAGE_BIT                                                                  = 0x00000001,
    VK_FORMAT_FEATURE_STORAGE_IMAGE_BIT                                                                  = 0x00000002,
    VK_FORMAT_FEATURE_STORAGE_IMAGE_ATOMIC_BIT                                                           = 0x00000004,
    VK_FORMAT_FEATURE_UNIFORM_TEXEL_BUFFER_BIT                                                           = 0x00000008,
    VK_FORMAT_FEATURE_STORAGE_TEXEL_BUFFER_BIT                                                           = 0x00000010,
    VK_FORMAT_FEATURE_STORAGE_TEXEL_BUFFER_ATOMIC_BIT                                                    = 0x00000020,
    VK_FORMAT_FEATURE_VERTEX_BUFFER_BIT                                                                  = 0x00000040,
    VK_FORMAT_FEATURE_COLOR_ATTACHMENT_BIT                                                               = 0x00000080,
    VK_FORMAT_FEATURE_COLOR_ATTACHMENT_BLEND_BIT                                                         = 0x00000100,
    VK_FORMAT_FEATURE_DEPTH_STENCIL_ATTACHMENT_BIT                                                       = 0x00000200,
    VK_FORMAT_FEATURE_BLIT_SRC_BIT                                                                       = 0x00000400,
    VK_FORMAT_FEATURE_BLIT_DST_BIT                                                                       = 0x00000800,
    VK_FORMAT_FEATURE_SAMPLED_IMAGE_FILTER_LINEAR_BIT                                                    = 0x00001000,
    VK_FORMAT_FEATURE_TRANSFER_SRC_BIT                                                                   = 0x00004000,
    VK_FORMAT_FEATURE_TRANSFER_DST_BIT                                                                   = 0x00008000,
    VK_FORMAT_FEATURE_MIDPOINT_CHROMA_SAMPLES_BIT                                                        = 0x00020000,
    VK_FORMAT_FEATURE_SAMPLED_IMAGE_YCBCR_CONVERSION_LINEAR_FILTER_BIT                                   = 0x00040000,
    VK_FORMAT_FEATURE_SAMPLED_IMAGE_YCBCR_CONVERSION_SEPARATE_RECONSTRUCTION_FILTER_BIT                  = 0x00080000,
    VK_FORMAT_FEATURE_SAMPLED_IMAGE_YCBCR_CONVERSION_CHROMA_RECONSTRUCTION_EXPLICIT_BIT                  = 0x00100000,
    VK_FORMAT_FEATURE_SAMPLED_IMAGE_YCBCR_CONVERSION_CHROMA_RECONSTRUCTION_EXPLICIT_FORCEABLE_BIT        = 0x00200000,
    VK_FORMAT_FEATURE_DISJOINT_BIT                                                                       = 0x00400000,
    VK_FORMAT_FEATURE_COSITED_CHROMA_SAMPLES_BIT                                                         = 0x00800000,
    VK_FORMAT_FEATURE_SAMPLED_IMAGE_FILTER_CUBIC_BIT_IMG                                                 = 0x00002000,
    VK_FORMAT_FEATURE_SAMPLED_IMAGE_FILTER_MINMAX_BIT_EXT                                                = 0x00010000,
    VK_FORMAT_FEATURE_FRAGMENT_DENSITY_MAP_BIT_EXT                                                       = 0x01000000,
    VK_FORMAT_FEATURE_TRANSFER_SRC_BIT_KHR                                                               = VK_FORMAT_FEATURE_TRANSFER_SRC_BIT,
    VK_FORMAT_FEATURE_TRANSFER_DST_BIT_KHR                                                               = VK_FORMAT_FEATURE_TRANSFER_DST_BIT,
    VK_FORMAT_FEATURE_MIDPOINT_CHROMA_SAMPLES_BIT_KHR                                                    = VK_FORMAT_FEATURE_MIDPOINT_CHROMA_SAMPLES_BIT,
    VK_FORMAT_FEATURE_SAMPLED_IMAGE_YCBCR_CONVERSION_LINEAR_FILTER_BIT_KHR                               = VK_FORMAT_FEATURE_SAMPLED_IMAGE_YCBCR_CONVERSION_LINEAR_FILTER_BIT,
    VK_FORMAT_FEATURE_SAMPLED_IMAGE_YCBCR_CONVERSION_SEPARATE_RECONSTRUCTION_FILTER_BIT_KHR              = VK_FORMAT_FEATURE_SAMPLED_IMAGE_YCBCR_CONVERSION_SEPARATE_RECONSTRUCTION_FILTER_BIT,
    VK_FORMAT_FEATURE_SAMPLED_IMAGE_YCBCR_CONVERSION_CHROMA_RECONSTRUCTION_EXPLICIT_BIT_KHR              = VK_FORMAT_FEATURE_SAMPLED_IMAGE_YCBCR_CONVERSION_CHROMA_RECONSTRUCTION_EXPLICIT_BIT,
    VK_FORMAT_FEATURE_SAMPLED_IMAGE_YCBCR_CONVERSION_CHROMA_RECONSTRUCTION_EXPLICIT_FORCEABLE_BIT_KHR    = VK_FORMAT_FEATURE_SAMPLED_IMAGE_YCBCR_CONVERSION_CHROMA_RECONSTRUCTION_EXPLICIT_FORCEABLE_BIT,
    VK_FORMAT_FEATURE_DISJOINT_BIT_KHR                                                                   = VK_FORMAT_FEATURE_DISJOINT_BIT,
    VK_FORMAT_FEATURE_COSITED_CHROMA_SAMPLES_BIT_KHR                                                     = VK_FORMAT_FEATURE_COSITED_CHROMA_SAMPLES_BIT,
    VK_FORMAT_FEATURE_SAMPLED_IMAGE_FILTER_CUBIC_BIT_EXT                                                 = VK_FORMAT_FEATURE_SAMPLED_IMAGE_FILTER_CUBIC_BIT_IMG,
    VK_FORMAT_FEATURE_FLAG_BITS_MAX_ENUM                                                                 = 0x7FFFFFFF
}

enum VK_FORMAT_FEATURE_SAMPLED_IMAGE_BIT                                                                 = VkFormatFeatureFlagBits.VK_FORMAT_FEATURE_SAMPLED_IMAGE_BIT;
enum VK_FORMAT_FEATURE_STORAGE_IMAGE_BIT                                                                 = VkFormatFeatureFlagBits.VK_FORMAT_FEATURE_STORAGE_IMAGE_BIT;
enum VK_FORMAT_FEATURE_STORAGE_IMAGE_ATOMIC_BIT                                                          = VkFormatFeatureFlagBits.VK_FORMAT_FEATURE_STORAGE_IMAGE_ATOMIC_BIT;
enum VK_FORMAT_FEATURE_UNIFORM_TEXEL_BUFFER_BIT                                                          = VkFormatFeatureFlagBits.VK_FORMAT_FEATURE_UNIFORM_TEXEL_BUFFER_BIT;
enum VK_FORMAT_FEATURE_STORAGE_TEXEL_BUFFER_BIT                                                          = VkFormatFeatureFlagBits.VK_FORMAT_FEATURE_STORAGE_TEXEL_BUFFER_BIT;
enum VK_FORMAT_FEATURE_STORAGE_TEXEL_BUFFER_ATOMIC_BIT                                                   = VkFormatFeatureFlagBits.VK_FORMAT_FEATURE_STORAGE_TEXEL_BUFFER_ATOMIC_BIT;
enum VK_FORMAT_FEATURE_VERTEX_BUFFER_BIT                                                                 = VkFormatFeatureFlagBits.VK_FORMAT_FEATURE_VERTEX_BUFFER_BIT;
enum VK_FORMAT_FEATURE_COLOR_ATTACHMENT_BIT                                                              = VkFormatFeatureFlagBits.VK_FORMAT_FEATURE_COLOR_ATTACHMENT_BIT;
enum VK_FORMAT_FEATURE_COLOR_ATTACHMENT_BLEND_BIT                                                        = VkFormatFeatureFlagBits.VK_FORMAT_FEATURE_COLOR_ATTACHMENT_BLEND_BIT;
enum VK_FORMAT_FEATURE_DEPTH_STENCIL_ATTACHMENT_BIT                                                      = VkFormatFeatureFlagBits.VK_FORMAT_FEATURE_DEPTH_STENCIL_ATTACHMENT_BIT;
enum VK_FORMAT_FEATURE_BLIT_SRC_BIT                                                                      = VkFormatFeatureFlagBits.VK_FORMAT_FEATURE_BLIT_SRC_BIT;
enum VK_FORMAT_FEATURE_BLIT_DST_BIT                                                                      = VkFormatFeatureFlagBits.VK_FORMAT_FEATURE_BLIT_DST_BIT;
enum VK_FORMAT_FEATURE_SAMPLED_IMAGE_FILTER_LINEAR_BIT                                                   = VkFormatFeatureFlagBits.VK_FORMAT_FEATURE_SAMPLED_IMAGE_FILTER_LINEAR_BIT;
enum VK_FORMAT_FEATURE_TRANSFER_SRC_BIT                                                                  = VkFormatFeatureFlagBits.VK_FORMAT_FEATURE_TRANSFER_SRC_BIT;
enum VK_FORMAT_FEATURE_TRANSFER_DST_BIT                                                                  = VkFormatFeatureFlagBits.VK_FORMAT_FEATURE_TRANSFER_DST_BIT;
enum VK_FORMAT_FEATURE_MIDPOINT_CHROMA_SAMPLES_BIT                                                       = VkFormatFeatureFlagBits.VK_FORMAT_FEATURE_MIDPOINT_CHROMA_SAMPLES_BIT;
enum VK_FORMAT_FEATURE_SAMPLED_IMAGE_YCBCR_CONVERSION_LINEAR_FILTER_BIT                                  = VkFormatFeatureFlagBits.VK_FORMAT_FEATURE_SAMPLED_IMAGE_YCBCR_CONVERSION_LINEAR_FILTER_BIT;
enum VK_FORMAT_FEATURE_SAMPLED_IMAGE_YCBCR_CONVERSION_SEPARATE_RECONSTRUCTION_FILTER_BIT                 = VkFormatFeatureFlagBits.VK_FORMAT_FEATURE_SAMPLED_IMAGE_YCBCR_CONVERSION_SEPARATE_RECONSTRUCTION_FILTER_BIT;
enum VK_FORMAT_FEATURE_SAMPLED_IMAGE_YCBCR_CONVERSION_CHROMA_RECONSTRUCTION_EXPLICIT_BIT                 = VkFormatFeatureFlagBits.VK_FORMAT_FEATURE_SAMPLED_IMAGE_YCBCR_CONVERSION_CHROMA_RECONSTRUCTION_EXPLICIT_BIT;
enum VK_FORMAT_FEATURE_SAMPLED_IMAGE_YCBCR_CONVERSION_CHROMA_RECONSTRUCTION_EXPLICIT_FORCEABLE_BIT       = VkFormatFeatureFlagBits.VK_FORMAT_FEATURE_SAMPLED_IMAGE_YCBCR_CONVERSION_CHROMA_RECONSTRUCTION_EXPLICIT_FORCEABLE_BIT;
enum VK_FORMAT_FEATURE_DISJOINT_BIT                                                                      = VkFormatFeatureFlagBits.VK_FORMAT_FEATURE_DISJOINT_BIT;
enum VK_FORMAT_FEATURE_COSITED_CHROMA_SAMPLES_BIT                                                        = VkFormatFeatureFlagBits.VK_FORMAT_FEATURE_COSITED_CHROMA_SAMPLES_BIT;
enum VK_FORMAT_FEATURE_SAMPLED_IMAGE_FILTER_CUBIC_BIT_IMG                                                = VkFormatFeatureFlagBits.VK_FORMAT_FEATURE_SAMPLED_IMAGE_FILTER_CUBIC_BIT_IMG;
enum VK_FORMAT_FEATURE_SAMPLED_IMAGE_FILTER_MINMAX_BIT_EXT                                               = VkFormatFeatureFlagBits.VK_FORMAT_FEATURE_SAMPLED_IMAGE_FILTER_MINMAX_BIT_EXT;
enum VK_FORMAT_FEATURE_FRAGMENT_DENSITY_MAP_BIT_EXT                                                      = VkFormatFeatureFlagBits.VK_FORMAT_FEATURE_FRAGMENT_DENSITY_MAP_BIT_EXT;
enum VK_FORMAT_FEATURE_TRANSFER_SRC_BIT_KHR                                                              = VkFormatFeatureFlagBits.VK_FORMAT_FEATURE_TRANSFER_SRC_BIT_KHR;
enum VK_FORMAT_FEATURE_TRANSFER_DST_BIT_KHR                                                              = VkFormatFeatureFlagBits.VK_FORMAT_FEATURE_TRANSFER_DST_BIT_KHR;
enum VK_FORMAT_FEATURE_MIDPOINT_CHROMA_SAMPLES_BIT_KHR                                                   = VkFormatFeatureFlagBits.VK_FORMAT_FEATURE_MIDPOINT_CHROMA_SAMPLES_BIT_KHR;
enum VK_FORMAT_FEATURE_SAMPLED_IMAGE_YCBCR_CONVERSION_LINEAR_FILTER_BIT_KHR                              = VkFormatFeatureFlagBits.VK_FORMAT_FEATURE_SAMPLED_IMAGE_YCBCR_CONVERSION_LINEAR_FILTER_BIT_KHR;
enum VK_FORMAT_FEATURE_SAMPLED_IMAGE_YCBCR_CONVERSION_SEPARATE_RECONSTRUCTION_FILTER_BIT_KHR             = VkFormatFeatureFlagBits.VK_FORMAT_FEATURE_SAMPLED_IMAGE_YCBCR_CONVERSION_SEPARATE_RECONSTRUCTION_FILTER_BIT_KHR;
enum VK_FORMAT_FEATURE_SAMPLED_IMAGE_YCBCR_CONVERSION_CHROMA_RECONSTRUCTION_EXPLICIT_BIT_KHR             = VkFormatFeatureFlagBits.VK_FORMAT_FEATURE_SAMPLED_IMAGE_YCBCR_CONVERSION_CHROMA_RECONSTRUCTION_EXPLICIT_BIT_KHR;
enum VK_FORMAT_FEATURE_SAMPLED_IMAGE_YCBCR_CONVERSION_CHROMA_RECONSTRUCTION_EXPLICIT_FORCEABLE_BIT_KHR   = VkFormatFeatureFlagBits.VK_FORMAT_FEATURE_SAMPLED_IMAGE_YCBCR_CONVERSION_CHROMA_RECONSTRUCTION_EXPLICIT_FORCEABLE_BIT_KHR;
enum VK_FORMAT_FEATURE_DISJOINT_BIT_KHR                                                                  = VkFormatFeatureFlagBits.VK_FORMAT_FEATURE_DISJOINT_BIT_KHR;
enum VK_FORMAT_FEATURE_COSITED_CHROMA_SAMPLES_BIT_KHR                                                    = VkFormatFeatureFlagBits.VK_FORMAT_FEATURE_COSITED_CHROMA_SAMPLES_BIT_KHR;
enum VK_FORMAT_FEATURE_SAMPLED_IMAGE_FILTER_CUBIC_BIT_EXT                                                = VkFormatFeatureFlagBits.VK_FORMAT_FEATURE_SAMPLED_IMAGE_FILTER_CUBIC_BIT_EXT;
enum VK_FORMAT_FEATURE_FLAG_BITS_MAX_ENUM                                                                = VkFormatFeatureFlagBits.VK_FORMAT_FEATURE_FLAG_BITS_MAX_ENUM;
alias VkFormatFeatureFlags = VkFlags;

enum VkImageUsageFlagBits {
    VK_IMAGE_USAGE_TRANSFER_SRC_BIT              = 0x00000001,
    VK_IMAGE_USAGE_TRANSFER_DST_BIT              = 0x00000002,
    VK_IMAGE_USAGE_SAMPLED_BIT                   = 0x00000004,
    VK_IMAGE_USAGE_STORAGE_BIT                   = 0x00000008,
    VK_IMAGE_USAGE_COLOR_ATTACHMENT_BIT          = 0x00000010,
    VK_IMAGE_USAGE_DEPTH_STENCIL_ATTACHMENT_BIT  = 0x00000020,
    VK_IMAGE_USAGE_TRANSIENT_ATTACHMENT_BIT      = 0x00000040,
    VK_IMAGE_USAGE_INPUT_ATTACHMENT_BIT          = 0x00000080,
    VK_IMAGE_USAGE_SHADING_RATE_IMAGE_BIT_NV     = 0x00000100,
    VK_IMAGE_USAGE_FRAGMENT_DENSITY_MAP_BIT_EXT  = 0x00000200,
    VK_IMAGE_USAGE_FLAG_BITS_MAX_ENUM            = 0x7FFFFFFF
}

enum VK_IMAGE_USAGE_TRANSFER_SRC_BIT             = VkImageUsageFlagBits.VK_IMAGE_USAGE_TRANSFER_SRC_BIT;
enum VK_IMAGE_USAGE_TRANSFER_DST_BIT             = VkImageUsageFlagBits.VK_IMAGE_USAGE_TRANSFER_DST_BIT;
enum VK_IMAGE_USAGE_SAMPLED_BIT                  = VkImageUsageFlagBits.VK_IMAGE_USAGE_SAMPLED_BIT;
enum VK_IMAGE_USAGE_STORAGE_BIT                  = VkImageUsageFlagBits.VK_IMAGE_USAGE_STORAGE_BIT;
enum VK_IMAGE_USAGE_COLOR_ATTACHMENT_BIT         = VkImageUsageFlagBits.VK_IMAGE_USAGE_COLOR_ATTACHMENT_BIT;
enum VK_IMAGE_USAGE_DEPTH_STENCIL_ATTACHMENT_BIT = VkImageUsageFlagBits.VK_IMAGE_USAGE_DEPTH_STENCIL_ATTACHMENT_BIT;
enum VK_IMAGE_USAGE_TRANSIENT_ATTACHMENT_BIT     = VkImageUsageFlagBits.VK_IMAGE_USAGE_TRANSIENT_ATTACHMENT_BIT;
enum VK_IMAGE_USAGE_INPUT_ATTACHMENT_BIT         = VkImageUsageFlagBits.VK_IMAGE_USAGE_INPUT_ATTACHMENT_BIT;
enum VK_IMAGE_USAGE_SHADING_RATE_IMAGE_BIT_NV    = VkImageUsageFlagBits.VK_IMAGE_USAGE_SHADING_RATE_IMAGE_BIT_NV;
enum VK_IMAGE_USAGE_FRAGMENT_DENSITY_MAP_BIT_EXT = VkImageUsageFlagBits.VK_IMAGE_USAGE_FRAGMENT_DENSITY_MAP_BIT_EXT;
enum VK_IMAGE_USAGE_FLAG_BITS_MAX_ENUM           = VkImageUsageFlagBits.VK_IMAGE_USAGE_FLAG_BITS_MAX_ENUM;
alias VkImageUsageFlags = VkFlags;

enum VkImageCreateFlagBits {
    VK_IMAGE_CREATE_SPARSE_BINDING_BIT                           = 0x00000001,
    VK_IMAGE_CREATE_SPARSE_RESIDENCY_BIT                         = 0x00000002,
    VK_IMAGE_CREATE_SPARSE_ALIASED_BIT                           = 0x00000004,
    VK_IMAGE_CREATE_MUTABLE_FORMAT_BIT                           = 0x00000008,
    VK_IMAGE_CREATE_CUBE_COMPATIBLE_BIT                          = 0x00000010,
    VK_IMAGE_CREATE_ALIAS_BIT                                    = 0x00000400,
    VK_IMAGE_CREATE_SPLIT_INSTANCE_BIND_REGIONS_BIT              = 0x00000040,
    VK_IMAGE_CREATE_2D_ARRAY_COMPATIBLE_BIT                      = 0x00000020,
    VK_IMAGE_CREATE_BLOCK_TEXEL_VIEW_COMPATIBLE_BIT              = 0x00000080,
    VK_IMAGE_CREATE_EXTENDED_USAGE_BIT                           = 0x00000100,
    VK_IMAGE_CREATE_PROTECTED_BIT                                = 0x00000800,
    VK_IMAGE_CREATE_DISJOINT_BIT                                 = 0x00000200,
    VK_IMAGE_CREATE_CORNER_SAMPLED_BIT_NV                        = 0x00002000,
    VK_IMAGE_CREATE_SAMPLE_LOCATIONS_COMPATIBLE_DEPTH_BIT_EXT    = 0x00001000,
    VK_IMAGE_CREATE_SUBSAMPLED_BIT_EXT                           = 0x00004000,
    VK_IMAGE_CREATE_SPLIT_INSTANCE_BIND_REGIONS_BIT_KHR          = VK_IMAGE_CREATE_SPLIT_INSTANCE_BIND_REGIONS_BIT,
    VK_IMAGE_CREATE_2D_ARRAY_COMPATIBLE_BIT_KHR                  = VK_IMAGE_CREATE_2D_ARRAY_COMPATIBLE_BIT,
    VK_IMAGE_CREATE_BLOCK_TEXEL_VIEW_COMPATIBLE_BIT_KHR          = VK_IMAGE_CREATE_BLOCK_TEXEL_VIEW_COMPATIBLE_BIT,
    VK_IMAGE_CREATE_EXTENDED_USAGE_BIT_KHR                       = VK_IMAGE_CREATE_EXTENDED_USAGE_BIT,
    VK_IMAGE_CREATE_DISJOINT_BIT_KHR                             = VK_IMAGE_CREATE_DISJOINT_BIT,
    VK_IMAGE_CREATE_ALIAS_BIT_KHR                                = VK_IMAGE_CREATE_ALIAS_BIT,
    VK_IMAGE_CREATE_FLAG_BITS_MAX_ENUM                           = 0x7FFFFFFF
}

enum VK_IMAGE_CREATE_SPARSE_BINDING_BIT                          = VkImageCreateFlagBits.VK_IMAGE_CREATE_SPARSE_BINDING_BIT;
enum VK_IMAGE_CREATE_SPARSE_RESIDENCY_BIT                        = VkImageCreateFlagBits.VK_IMAGE_CREATE_SPARSE_RESIDENCY_BIT;
enum VK_IMAGE_CREATE_SPARSE_ALIASED_BIT                          = VkImageCreateFlagBits.VK_IMAGE_CREATE_SPARSE_ALIASED_BIT;
enum VK_IMAGE_CREATE_MUTABLE_FORMAT_BIT                          = VkImageCreateFlagBits.VK_IMAGE_CREATE_MUTABLE_FORMAT_BIT;
enum VK_IMAGE_CREATE_CUBE_COMPATIBLE_BIT                         = VkImageCreateFlagBits.VK_IMAGE_CREATE_CUBE_COMPATIBLE_BIT;
enum VK_IMAGE_CREATE_ALIAS_BIT                                   = VkImageCreateFlagBits.VK_IMAGE_CREATE_ALIAS_BIT;
enum VK_IMAGE_CREATE_SPLIT_INSTANCE_BIND_REGIONS_BIT             = VkImageCreateFlagBits.VK_IMAGE_CREATE_SPLIT_INSTANCE_BIND_REGIONS_BIT;
enum VK_IMAGE_CREATE_2D_ARRAY_COMPATIBLE_BIT                     = VkImageCreateFlagBits.VK_IMAGE_CREATE_2D_ARRAY_COMPATIBLE_BIT;
enum VK_IMAGE_CREATE_BLOCK_TEXEL_VIEW_COMPATIBLE_BIT             = VkImageCreateFlagBits.VK_IMAGE_CREATE_BLOCK_TEXEL_VIEW_COMPATIBLE_BIT;
enum VK_IMAGE_CREATE_EXTENDED_USAGE_BIT                          = VkImageCreateFlagBits.VK_IMAGE_CREATE_EXTENDED_USAGE_BIT;
enum VK_IMAGE_CREATE_PROTECTED_BIT                               = VkImageCreateFlagBits.VK_IMAGE_CREATE_PROTECTED_BIT;
enum VK_IMAGE_CREATE_DISJOINT_BIT                                = VkImageCreateFlagBits.VK_IMAGE_CREATE_DISJOINT_BIT;
enum VK_IMAGE_CREATE_CORNER_SAMPLED_BIT_NV                       = VkImageCreateFlagBits.VK_IMAGE_CREATE_CORNER_SAMPLED_BIT_NV;
enum VK_IMAGE_CREATE_SAMPLE_LOCATIONS_COMPATIBLE_DEPTH_BIT_EXT   = VkImageCreateFlagBits.VK_IMAGE_CREATE_SAMPLE_LOCATIONS_COMPATIBLE_DEPTH_BIT_EXT;
enum VK_IMAGE_CREATE_SUBSAMPLED_BIT_EXT                          = VkImageCreateFlagBits.VK_IMAGE_CREATE_SUBSAMPLED_BIT_EXT;
enum VK_IMAGE_CREATE_SPLIT_INSTANCE_BIND_REGIONS_BIT_KHR         = VkImageCreateFlagBits.VK_IMAGE_CREATE_SPLIT_INSTANCE_BIND_REGIONS_BIT_KHR;
enum VK_IMAGE_CREATE_2D_ARRAY_COMPATIBLE_BIT_KHR                 = VkImageCreateFlagBits.VK_IMAGE_CREATE_2D_ARRAY_COMPATIBLE_BIT_KHR;
enum VK_IMAGE_CREATE_BLOCK_TEXEL_VIEW_COMPATIBLE_BIT_KHR         = VkImageCreateFlagBits.VK_IMAGE_CREATE_BLOCK_TEXEL_VIEW_COMPATIBLE_BIT_KHR;
enum VK_IMAGE_CREATE_EXTENDED_USAGE_BIT_KHR                      = VkImageCreateFlagBits.VK_IMAGE_CREATE_EXTENDED_USAGE_BIT_KHR;
enum VK_IMAGE_CREATE_DISJOINT_BIT_KHR                            = VkImageCreateFlagBits.VK_IMAGE_CREATE_DISJOINT_BIT_KHR;
enum VK_IMAGE_CREATE_ALIAS_BIT_KHR                               = VkImageCreateFlagBits.VK_IMAGE_CREATE_ALIAS_BIT_KHR;
enum VK_IMAGE_CREATE_FLAG_BITS_MAX_ENUM                          = VkImageCreateFlagBits.VK_IMAGE_CREATE_FLAG_BITS_MAX_ENUM;
alias VkImageCreateFlags = VkFlags;

enum VkSampleCountFlagBits {
    VK_SAMPLE_COUNT_1_BIT                        = 0x00000001,
    VK_SAMPLE_COUNT_2_BIT                        = 0x00000002,
    VK_SAMPLE_COUNT_4_BIT                        = 0x00000004,
    VK_SAMPLE_COUNT_8_BIT                        = 0x00000008,
    VK_SAMPLE_COUNT_16_BIT                       = 0x00000010,
    VK_SAMPLE_COUNT_32_BIT                       = 0x00000020,
    VK_SAMPLE_COUNT_64_BIT                       = 0x00000040,
    VK_SAMPLE_COUNT_FLAG_BITS_MAX_ENUM           = 0x7FFFFFFF
}

enum VK_SAMPLE_COUNT_1_BIT                       = VkSampleCountFlagBits.VK_SAMPLE_COUNT_1_BIT;
enum VK_SAMPLE_COUNT_2_BIT                       = VkSampleCountFlagBits.VK_SAMPLE_COUNT_2_BIT;
enum VK_SAMPLE_COUNT_4_BIT                       = VkSampleCountFlagBits.VK_SAMPLE_COUNT_4_BIT;
enum VK_SAMPLE_COUNT_8_BIT                       = VkSampleCountFlagBits.VK_SAMPLE_COUNT_8_BIT;
enum VK_SAMPLE_COUNT_16_BIT                      = VkSampleCountFlagBits.VK_SAMPLE_COUNT_16_BIT;
enum VK_SAMPLE_COUNT_32_BIT                      = VkSampleCountFlagBits.VK_SAMPLE_COUNT_32_BIT;
enum VK_SAMPLE_COUNT_64_BIT                      = VkSampleCountFlagBits.VK_SAMPLE_COUNT_64_BIT;
enum VK_SAMPLE_COUNT_FLAG_BITS_MAX_ENUM          = VkSampleCountFlagBits.VK_SAMPLE_COUNT_FLAG_BITS_MAX_ENUM;
alias VkSampleCountFlags = VkFlags;

enum VkQueueFlagBits {
    VK_QUEUE_GRAPHICS_BIT                = 0x00000001,
    VK_QUEUE_COMPUTE_BIT                 = 0x00000002,
    VK_QUEUE_TRANSFER_BIT                = 0x00000004,
    VK_QUEUE_SPARSE_BINDING_BIT          = 0x00000008,
    VK_QUEUE_PROTECTED_BIT               = 0x00000010,
    VK_QUEUE_FLAG_BITS_MAX_ENUM          = 0x7FFFFFFF
}

enum VK_QUEUE_GRAPHICS_BIT               = VkQueueFlagBits.VK_QUEUE_GRAPHICS_BIT;
enum VK_QUEUE_COMPUTE_BIT                = VkQueueFlagBits.VK_QUEUE_COMPUTE_BIT;
enum VK_QUEUE_TRANSFER_BIT               = VkQueueFlagBits.VK_QUEUE_TRANSFER_BIT;
enum VK_QUEUE_SPARSE_BINDING_BIT         = VkQueueFlagBits.VK_QUEUE_SPARSE_BINDING_BIT;
enum VK_QUEUE_PROTECTED_BIT              = VkQueueFlagBits.VK_QUEUE_PROTECTED_BIT;
enum VK_QUEUE_FLAG_BITS_MAX_ENUM         = VkQueueFlagBits.VK_QUEUE_FLAG_BITS_MAX_ENUM;
alias VkQueueFlags = VkFlags;

enum VkMemoryPropertyFlagBits {
    VK_MEMORY_PROPERTY_DEVICE_LOCAL_BIT          = 0x00000001,
    VK_MEMORY_PROPERTY_HOST_VISIBLE_BIT          = 0x00000002,
    VK_MEMORY_PROPERTY_HOST_COHERENT_BIT         = 0x00000004,
    VK_MEMORY_PROPERTY_HOST_CACHED_BIT           = 0x00000008,
    VK_MEMORY_PROPERTY_LAZILY_ALLOCATED_BIT      = 0x00000010,
    VK_MEMORY_PROPERTY_PROTECTED_BIT             = 0x00000020,
    VK_MEMORY_PROPERTY_FLAG_BITS_MAX_ENUM        = 0x7FFFFFFF
}

enum VK_MEMORY_PROPERTY_DEVICE_LOCAL_BIT         = VkMemoryPropertyFlagBits.VK_MEMORY_PROPERTY_DEVICE_LOCAL_BIT;
enum VK_MEMORY_PROPERTY_HOST_VISIBLE_BIT         = VkMemoryPropertyFlagBits.VK_MEMORY_PROPERTY_HOST_VISIBLE_BIT;
enum VK_MEMORY_PROPERTY_HOST_COHERENT_BIT        = VkMemoryPropertyFlagBits.VK_MEMORY_PROPERTY_HOST_COHERENT_BIT;
enum VK_MEMORY_PROPERTY_HOST_CACHED_BIT          = VkMemoryPropertyFlagBits.VK_MEMORY_PROPERTY_HOST_CACHED_BIT;
enum VK_MEMORY_PROPERTY_LAZILY_ALLOCATED_BIT     = VkMemoryPropertyFlagBits.VK_MEMORY_PROPERTY_LAZILY_ALLOCATED_BIT;
enum VK_MEMORY_PROPERTY_PROTECTED_BIT            = VkMemoryPropertyFlagBits.VK_MEMORY_PROPERTY_PROTECTED_BIT;
enum VK_MEMORY_PROPERTY_FLAG_BITS_MAX_ENUM       = VkMemoryPropertyFlagBits.VK_MEMORY_PROPERTY_FLAG_BITS_MAX_ENUM;
alias VkMemoryPropertyFlags = VkFlags;

enum VkMemoryHeapFlagBits {
    VK_MEMORY_HEAP_DEVICE_LOCAL_BIT              = 0x00000001,
    VK_MEMORY_HEAP_MULTI_INSTANCE_BIT            = 0x00000002,
    VK_MEMORY_HEAP_MULTI_INSTANCE_BIT_KHR        = VK_MEMORY_HEAP_MULTI_INSTANCE_BIT,
    VK_MEMORY_HEAP_FLAG_BITS_MAX_ENUM            = 0x7FFFFFFF
}

enum VK_MEMORY_HEAP_DEVICE_LOCAL_BIT             = VkMemoryHeapFlagBits.VK_MEMORY_HEAP_DEVICE_LOCAL_BIT;
enum VK_MEMORY_HEAP_MULTI_INSTANCE_BIT           = VkMemoryHeapFlagBits.VK_MEMORY_HEAP_MULTI_INSTANCE_BIT;
enum VK_MEMORY_HEAP_MULTI_INSTANCE_BIT_KHR       = VkMemoryHeapFlagBits.VK_MEMORY_HEAP_MULTI_INSTANCE_BIT_KHR;
enum VK_MEMORY_HEAP_FLAG_BITS_MAX_ENUM           = VkMemoryHeapFlagBits.VK_MEMORY_HEAP_FLAG_BITS_MAX_ENUM;
alias VkMemoryHeapFlags = VkFlags;
alias VkDeviceCreateFlags = VkFlags;

enum VkDeviceQueueCreateFlagBits {
    VK_DEVICE_QUEUE_CREATE_PROTECTED_BIT                 = 0x00000001,
    VK_DEVICE_QUEUE_CREATE_FLAG_BITS_MAX_ENUM            = 0x7FFFFFFF
}

enum VK_DEVICE_QUEUE_CREATE_PROTECTED_BIT                = VkDeviceQueueCreateFlagBits.VK_DEVICE_QUEUE_CREATE_PROTECTED_BIT;
enum VK_DEVICE_QUEUE_CREATE_FLAG_BITS_MAX_ENUM           = VkDeviceQueueCreateFlagBits.VK_DEVICE_QUEUE_CREATE_FLAG_BITS_MAX_ENUM;
alias VkDeviceQueueCreateFlags = VkFlags;

enum VkPipelineStageFlagBits {
    VK_PIPELINE_STAGE_TOP_OF_PIPE_BIT                            = 0x00000001,
    VK_PIPELINE_STAGE_DRAW_INDIRECT_BIT                          = 0x00000002,
    VK_PIPELINE_STAGE_VERTEX_INPUT_BIT                           = 0x00000004,
    VK_PIPELINE_STAGE_VERTEX_SHADER_BIT                          = 0x00000008,
    VK_PIPELINE_STAGE_TESSELLATION_CONTROL_SHADER_BIT            = 0x00000010,
    VK_PIPELINE_STAGE_TESSELLATION_EVALUATION_SHADER_BIT         = 0x00000020,
    VK_PIPELINE_STAGE_GEOMETRY_SHADER_BIT                        = 0x00000040,
    VK_PIPELINE_STAGE_FRAGMENT_SHADER_BIT                        = 0x00000080,
    VK_PIPELINE_STAGE_EARLY_FRAGMENT_TESTS_BIT                   = 0x00000100,
    VK_PIPELINE_STAGE_LATE_FRAGMENT_TESTS_BIT                    = 0x00000200,
    VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT                = 0x00000400,
    VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT                         = 0x00000800,
    VK_PIPELINE_STAGE_TRANSFER_BIT                               = 0x00001000,
    VK_PIPELINE_STAGE_BOTTOM_OF_PIPE_BIT                         = 0x00002000,
    VK_PIPELINE_STAGE_HOST_BIT                                   = 0x00004000,
    VK_PIPELINE_STAGE_ALL_GRAPHICS_BIT                           = 0x00008000,
    VK_PIPELINE_STAGE_ALL_COMMANDS_BIT                           = 0x00010000,
    VK_PIPELINE_STAGE_TRANSFORM_FEEDBACK_BIT_EXT                 = 0x01000000,
    VK_PIPELINE_STAGE_CONDITIONAL_RENDERING_BIT_EXT              = 0x00040000,
    VK_PIPELINE_STAGE_COMMAND_PROCESS_BIT_NVX                    = 0x00020000,
    VK_PIPELINE_STAGE_SHADING_RATE_IMAGE_BIT_NV                  = 0x00400000,
    VK_PIPELINE_STAGE_RAY_TRACING_SHADER_BIT_NV                  = 0x00200000,
    VK_PIPELINE_STAGE_ACCELERATION_STRUCTURE_BUILD_BIT_NV        = 0x02000000,
    VK_PIPELINE_STAGE_TASK_SHADER_BIT_NV                         = 0x00080000,
    VK_PIPELINE_STAGE_MESH_SHADER_BIT_NV                         = 0x00100000,
    VK_PIPELINE_STAGE_FRAGMENT_DENSITY_PROCESS_BIT_EXT           = 0x00800000,
    VK_PIPELINE_STAGE_FLAG_BITS_MAX_ENUM                         = 0x7FFFFFFF
}

enum VK_PIPELINE_STAGE_TOP_OF_PIPE_BIT                           = VkPipelineStageFlagBits.VK_PIPELINE_STAGE_TOP_OF_PIPE_BIT;
enum VK_PIPELINE_STAGE_DRAW_INDIRECT_BIT                         = VkPipelineStageFlagBits.VK_PIPELINE_STAGE_DRAW_INDIRECT_BIT;
enum VK_PIPELINE_STAGE_VERTEX_INPUT_BIT                          = VkPipelineStageFlagBits.VK_PIPELINE_STAGE_VERTEX_INPUT_BIT;
enum VK_PIPELINE_STAGE_VERTEX_SHADER_BIT                         = VkPipelineStageFlagBits.VK_PIPELINE_STAGE_VERTEX_SHADER_BIT;
enum VK_PIPELINE_STAGE_TESSELLATION_CONTROL_SHADER_BIT           = VkPipelineStageFlagBits.VK_PIPELINE_STAGE_TESSELLATION_CONTROL_SHADER_BIT;
enum VK_PIPELINE_STAGE_TESSELLATION_EVALUATION_SHADER_BIT        = VkPipelineStageFlagBits.VK_PIPELINE_STAGE_TESSELLATION_EVALUATION_SHADER_BIT;
enum VK_PIPELINE_STAGE_GEOMETRY_SHADER_BIT                       = VkPipelineStageFlagBits.VK_PIPELINE_STAGE_GEOMETRY_SHADER_BIT;
enum VK_PIPELINE_STAGE_FRAGMENT_SHADER_BIT                       = VkPipelineStageFlagBits.VK_PIPELINE_STAGE_FRAGMENT_SHADER_BIT;
enum VK_PIPELINE_STAGE_EARLY_FRAGMENT_TESTS_BIT                  = VkPipelineStageFlagBits.VK_PIPELINE_STAGE_EARLY_FRAGMENT_TESTS_BIT;
enum VK_PIPELINE_STAGE_LATE_FRAGMENT_TESTS_BIT                   = VkPipelineStageFlagBits.VK_PIPELINE_STAGE_LATE_FRAGMENT_TESTS_BIT;
enum VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT               = VkPipelineStageFlagBits.VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT;
enum VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT                        = VkPipelineStageFlagBits.VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT;
enum VK_PIPELINE_STAGE_TRANSFER_BIT                              = VkPipelineStageFlagBits.VK_PIPELINE_STAGE_TRANSFER_BIT;
enum VK_PIPELINE_STAGE_BOTTOM_OF_PIPE_BIT                        = VkPipelineStageFlagBits.VK_PIPELINE_STAGE_BOTTOM_OF_PIPE_BIT;
enum VK_PIPELINE_STAGE_HOST_BIT                                  = VkPipelineStageFlagBits.VK_PIPELINE_STAGE_HOST_BIT;
enum VK_PIPELINE_STAGE_ALL_GRAPHICS_BIT                          = VkPipelineStageFlagBits.VK_PIPELINE_STAGE_ALL_GRAPHICS_BIT;
enum VK_PIPELINE_STAGE_ALL_COMMANDS_BIT                          = VkPipelineStageFlagBits.VK_PIPELINE_STAGE_ALL_COMMANDS_BIT;
enum VK_PIPELINE_STAGE_TRANSFORM_FEEDBACK_BIT_EXT                = VkPipelineStageFlagBits.VK_PIPELINE_STAGE_TRANSFORM_FEEDBACK_BIT_EXT;
enum VK_PIPELINE_STAGE_CONDITIONAL_RENDERING_BIT_EXT             = VkPipelineStageFlagBits.VK_PIPELINE_STAGE_CONDITIONAL_RENDERING_BIT_EXT;
enum VK_PIPELINE_STAGE_COMMAND_PROCESS_BIT_NVX                   = VkPipelineStageFlagBits.VK_PIPELINE_STAGE_COMMAND_PROCESS_BIT_NVX;
enum VK_PIPELINE_STAGE_SHADING_RATE_IMAGE_BIT_NV                 = VkPipelineStageFlagBits.VK_PIPELINE_STAGE_SHADING_RATE_IMAGE_BIT_NV;
enum VK_PIPELINE_STAGE_RAY_TRACING_SHADER_BIT_NV                 = VkPipelineStageFlagBits.VK_PIPELINE_STAGE_RAY_TRACING_SHADER_BIT_NV;
enum VK_PIPELINE_STAGE_ACCELERATION_STRUCTURE_BUILD_BIT_NV       = VkPipelineStageFlagBits.VK_PIPELINE_STAGE_ACCELERATION_STRUCTURE_BUILD_BIT_NV;
enum VK_PIPELINE_STAGE_TASK_SHADER_BIT_NV                        = VkPipelineStageFlagBits.VK_PIPELINE_STAGE_TASK_SHADER_BIT_NV;
enum VK_PIPELINE_STAGE_MESH_SHADER_BIT_NV                        = VkPipelineStageFlagBits.VK_PIPELINE_STAGE_MESH_SHADER_BIT_NV;
enum VK_PIPELINE_STAGE_FRAGMENT_DENSITY_PROCESS_BIT_EXT          = VkPipelineStageFlagBits.VK_PIPELINE_STAGE_FRAGMENT_DENSITY_PROCESS_BIT_EXT;
enum VK_PIPELINE_STAGE_FLAG_BITS_MAX_ENUM                        = VkPipelineStageFlagBits.VK_PIPELINE_STAGE_FLAG_BITS_MAX_ENUM;
alias VkPipelineStageFlags = VkFlags;
alias VkMemoryMapFlags = VkFlags;

enum VkImageAspectFlagBits {
    VK_IMAGE_ASPECT_COLOR_BIT                    = 0x00000001,
    VK_IMAGE_ASPECT_DEPTH_BIT                    = 0x00000002,
    VK_IMAGE_ASPECT_STENCIL_BIT                  = 0x00000004,
    VK_IMAGE_ASPECT_METADATA_BIT                 = 0x00000008,
    VK_IMAGE_ASPECT_PLANE_0_BIT                  = 0x00000010,
    VK_IMAGE_ASPECT_PLANE_1_BIT                  = 0x00000020,
    VK_IMAGE_ASPECT_PLANE_2_BIT                  = 0x00000040,
    VK_IMAGE_ASPECT_MEMORY_PLANE_0_BIT_EXT       = 0x00000080,
    VK_IMAGE_ASPECT_MEMORY_PLANE_1_BIT_EXT       = 0x00000100,
    VK_IMAGE_ASPECT_MEMORY_PLANE_2_BIT_EXT       = 0x00000200,
    VK_IMAGE_ASPECT_MEMORY_PLANE_3_BIT_EXT       = 0x00000400,
    VK_IMAGE_ASPECT_PLANE_0_BIT_KHR              = VK_IMAGE_ASPECT_PLANE_0_BIT,
    VK_IMAGE_ASPECT_PLANE_1_BIT_KHR              = VK_IMAGE_ASPECT_PLANE_1_BIT,
    VK_IMAGE_ASPECT_PLANE_2_BIT_KHR              = VK_IMAGE_ASPECT_PLANE_2_BIT,
    VK_IMAGE_ASPECT_FLAG_BITS_MAX_ENUM           = 0x7FFFFFFF
}

enum VK_IMAGE_ASPECT_COLOR_BIT                   = VkImageAspectFlagBits.VK_IMAGE_ASPECT_COLOR_BIT;
enum VK_IMAGE_ASPECT_DEPTH_BIT                   = VkImageAspectFlagBits.VK_IMAGE_ASPECT_DEPTH_BIT;
enum VK_IMAGE_ASPECT_STENCIL_BIT                 = VkImageAspectFlagBits.VK_IMAGE_ASPECT_STENCIL_BIT;
enum VK_IMAGE_ASPECT_METADATA_BIT                = VkImageAspectFlagBits.VK_IMAGE_ASPECT_METADATA_BIT;
enum VK_IMAGE_ASPECT_PLANE_0_BIT                 = VkImageAspectFlagBits.VK_IMAGE_ASPECT_PLANE_0_BIT;
enum VK_IMAGE_ASPECT_PLANE_1_BIT                 = VkImageAspectFlagBits.VK_IMAGE_ASPECT_PLANE_1_BIT;
enum VK_IMAGE_ASPECT_PLANE_2_BIT                 = VkImageAspectFlagBits.VK_IMAGE_ASPECT_PLANE_2_BIT;
enum VK_IMAGE_ASPECT_MEMORY_PLANE_0_BIT_EXT      = VkImageAspectFlagBits.VK_IMAGE_ASPECT_MEMORY_PLANE_0_BIT_EXT;
enum VK_IMAGE_ASPECT_MEMORY_PLANE_1_BIT_EXT      = VkImageAspectFlagBits.VK_IMAGE_ASPECT_MEMORY_PLANE_1_BIT_EXT;
enum VK_IMAGE_ASPECT_MEMORY_PLANE_2_BIT_EXT      = VkImageAspectFlagBits.VK_IMAGE_ASPECT_MEMORY_PLANE_2_BIT_EXT;
enum VK_IMAGE_ASPECT_MEMORY_PLANE_3_BIT_EXT      = VkImageAspectFlagBits.VK_IMAGE_ASPECT_MEMORY_PLANE_3_BIT_EXT;
enum VK_IMAGE_ASPECT_PLANE_0_BIT_KHR             = VkImageAspectFlagBits.VK_IMAGE_ASPECT_PLANE_0_BIT_KHR;
enum VK_IMAGE_ASPECT_PLANE_1_BIT_KHR             = VkImageAspectFlagBits.VK_IMAGE_ASPECT_PLANE_1_BIT_KHR;
enum VK_IMAGE_ASPECT_PLANE_2_BIT_KHR             = VkImageAspectFlagBits.VK_IMAGE_ASPECT_PLANE_2_BIT_KHR;
enum VK_IMAGE_ASPECT_FLAG_BITS_MAX_ENUM          = VkImageAspectFlagBits.VK_IMAGE_ASPECT_FLAG_BITS_MAX_ENUM;
alias VkImageAspectFlags = VkFlags;

enum VkSparseImageFormatFlagBits {
    VK_SPARSE_IMAGE_FORMAT_SINGLE_MIPTAIL_BIT            = 0x00000001,
    VK_SPARSE_IMAGE_FORMAT_ALIGNED_MIP_SIZE_BIT          = 0x00000002,
    VK_SPARSE_IMAGE_FORMAT_NONSTANDARD_BLOCK_SIZE_BIT    = 0x00000004,
    VK_SPARSE_IMAGE_FORMAT_FLAG_BITS_MAX_ENUM            = 0x7FFFFFFF
}

enum VK_SPARSE_IMAGE_FORMAT_SINGLE_MIPTAIL_BIT           = VkSparseImageFormatFlagBits.VK_SPARSE_IMAGE_FORMAT_SINGLE_MIPTAIL_BIT;
enum VK_SPARSE_IMAGE_FORMAT_ALIGNED_MIP_SIZE_BIT         = VkSparseImageFormatFlagBits.VK_SPARSE_IMAGE_FORMAT_ALIGNED_MIP_SIZE_BIT;
enum VK_SPARSE_IMAGE_FORMAT_NONSTANDARD_BLOCK_SIZE_BIT   = VkSparseImageFormatFlagBits.VK_SPARSE_IMAGE_FORMAT_NONSTANDARD_BLOCK_SIZE_BIT;
enum VK_SPARSE_IMAGE_FORMAT_FLAG_BITS_MAX_ENUM           = VkSparseImageFormatFlagBits.VK_SPARSE_IMAGE_FORMAT_FLAG_BITS_MAX_ENUM;
alias VkSparseImageFormatFlags = VkFlags;

enum VkSparseMemoryBindFlagBits {
    VK_SPARSE_MEMORY_BIND_METADATA_BIT           = 0x00000001,
    VK_SPARSE_MEMORY_BIND_FLAG_BITS_MAX_ENUM     = 0x7FFFFFFF
}

enum VK_SPARSE_MEMORY_BIND_METADATA_BIT          = VkSparseMemoryBindFlagBits.VK_SPARSE_MEMORY_BIND_METADATA_BIT;
enum VK_SPARSE_MEMORY_BIND_FLAG_BITS_MAX_ENUM    = VkSparseMemoryBindFlagBits.VK_SPARSE_MEMORY_BIND_FLAG_BITS_MAX_ENUM;
alias VkSparseMemoryBindFlags = VkFlags;

enum VkFenceCreateFlagBits {
    VK_FENCE_CREATE_SIGNALED_BIT                 = 0x00000001,
    VK_FENCE_CREATE_FLAG_BITS_MAX_ENUM           = 0x7FFFFFFF
}

enum VK_FENCE_CREATE_SIGNALED_BIT                = VkFenceCreateFlagBits.VK_FENCE_CREATE_SIGNALED_BIT;
enum VK_FENCE_CREATE_FLAG_BITS_MAX_ENUM          = VkFenceCreateFlagBits.VK_FENCE_CREATE_FLAG_BITS_MAX_ENUM;
alias VkFenceCreateFlags = VkFlags;
alias VkSemaphoreCreateFlags = VkFlags;
alias VkEventCreateFlags = VkFlags;
alias VkQueryPoolCreateFlags = VkFlags;

enum VkQueryPipelineStatisticFlagBits {
    VK_QUERY_PIPELINE_STATISTIC_INPUT_ASSEMBLY_VERTICES_BIT                      = 0x00000001,
    VK_QUERY_PIPELINE_STATISTIC_INPUT_ASSEMBLY_PRIMITIVES_BIT                    = 0x00000002,
    VK_QUERY_PIPELINE_STATISTIC_VERTEX_SHADER_INVOCATIONS_BIT                    = 0x00000004,
    VK_QUERY_PIPELINE_STATISTIC_GEOMETRY_SHADER_INVOCATIONS_BIT                  = 0x00000008,
    VK_QUERY_PIPELINE_STATISTIC_GEOMETRY_SHADER_PRIMITIVES_BIT                   = 0x00000010,
    VK_QUERY_PIPELINE_STATISTIC_CLIPPING_INVOCATIONS_BIT                         = 0x00000020,
    VK_QUERY_PIPELINE_STATISTIC_CLIPPING_PRIMITIVES_BIT                          = 0x00000040,
    VK_QUERY_PIPELINE_STATISTIC_FRAGMENT_SHADER_INVOCATIONS_BIT                  = 0x00000080,
    VK_QUERY_PIPELINE_STATISTIC_TESSELLATION_CONTROL_SHADER_PATCHES_BIT          = 0x00000100,
    VK_QUERY_PIPELINE_STATISTIC_TESSELLATION_EVALUATION_SHADER_INVOCATIONS_BIT   = 0x00000200,
    VK_QUERY_PIPELINE_STATISTIC_COMPUTE_SHADER_INVOCATIONS_BIT                   = 0x00000400,
    VK_QUERY_PIPELINE_STATISTIC_FLAG_BITS_MAX_ENUM                               = 0x7FFFFFFF
}

enum VK_QUERY_PIPELINE_STATISTIC_INPUT_ASSEMBLY_VERTICES_BIT                     = VkQueryPipelineStatisticFlagBits.VK_QUERY_PIPELINE_STATISTIC_INPUT_ASSEMBLY_VERTICES_BIT;
enum VK_QUERY_PIPELINE_STATISTIC_INPUT_ASSEMBLY_PRIMITIVES_BIT                   = VkQueryPipelineStatisticFlagBits.VK_QUERY_PIPELINE_STATISTIC_INPUT_ASSEMBLY_PRIMITIVES_BIT;
enum VK_QUERY_PIPELINE_STATISTIC_VERTEX_SHADER_INVOCATIONS_BIT                   = VkQueryPipelineStatisticFlagBits.VK_QUERY_PIPELINE_STATISTIC_VERTEX_SHADER_INVOCATIONS_BIT;
enum VK_QUERY_PIPELINE_STATISTIC_GEOMETRY_SHADER_INVOCATIONS_BIT                 = VkQueryPipelineStatisticFlagBits.VK_QUERY_PIPELINE_STATISTIC_GEOMETRY_SHADER_INVOCATIONS_BIT;
enum VK_QUERY_PIPELINE_STATISTIC_GEOMETRY_SHADER_PRIMITIVES_BIT                  = VkQueryPipelineStatisticFlagBits.VK_QUERY_PIPELINE_STATISTIC_GEOMETRY_SHADER_PRIMITIVES_BIT;
enum VK_QUERY_PIPELINE_STATISTIC_CLIPPING_INVOCATIONS_BIT                        = VkQueryPipelineStatisticFlagBits.VK_QUERY_PIPELINE_STATISTIC_CLIPPING_INVOCATIONS_BIT;
enum VK_QUERY_PIPELINE_STATISTIC_CLIPPING_PRIMITIVES_BIT                         = VkQueryPipelineStatisticFlagBits.VK_QUERY_PIPELINE_STATISTIC_CLIPPING_PRIMITIVES_BIT;
enum VK_QUERY_PIPELINE_STATISTIC_FRAGMENT_SHADER_INVOCATIONS_BIT                 = VkQueryPipelineStatisticFlagBits.VK_QUERY_PIPELINE_STATISTIC_FRAGMENT_SHADER_INVOCATIONS_BIT;
enum VK_QUERY_PIPELINE_STATISTIC_TESSELLATION_CONTROL_SHADER_PATCHES_BIT         = VkQueryPipelineStatisticFlagBits.VK_QUERY_PIPELINE_STATISTIC_TESSELLATION_CONTROL_SHADER_PATCHES_BIT;
enum VK_QUERY_PIPELINE_STATISTIC_TESSELLATION_EVALUATION_SHADER_INVOCATIONS_BIT  = VkQueryPipelineStatisticFlagBits.VK_QUERY_PIPELINE_STATISTIC_TESSELLATION_EVALUATION_SHADER_INVOCATIONS_BIT;
enum VK_QUERY_PIPELINE_STATISTIC_COMPUTE_SHADER_INVOCATIONS_BIT                  = VkQueryPipelineStatisticFlagBits.VK_QUERY_PIPELINE_STATISTIC_COMPUTE_SHADER_INVOCATIONS_BIT;
enum VK_QUERY_PIPELINE_STATISTIC_FLAG_BITS_MAX_ENUM                              = VkQueryPipelineStatisticFlagBits.VK_QUERY_PIPELINE_STATISTIC_FLAG_BITS_MAX_ENUM;
alias VkQueryPipelineStatisticFlags = VkFlags;

enum VkQueryResultFlagBits {
    VK_QUERY_RESULT_64_BIT                       = 0x00000001,
    VK_QUERY_RESULT_WAIT_BIT                     = 0x00000002,
    VK_QUERY_RESULT_WITH_AVAILABILITY_BIT        = 0x00000004,
    VK_QUERY_RESULT_PARTIAL_BIT                  = 0x00000008,
    VK_QUERY_RESULT_FLAG_BITS_MAX_ENUM           = 0x7FFFFFFF
}

enum VK_QUERY_RESULT_64_BIT                      = VkQueryResultFlagBits.VK_QUERY_RESULT_64_BIT;
enum VK_QUERY_RESULT_WAIT_BIT                    = VkQueryResultFlagBits.VK_QUERY_RESULT_WAIT_BIT;
enum VK_QUERY_RESULT_WITH_AVAILABILITY_BIT       = VkQueryResultFlagBits.VK_QUERY_RESULT_WITH_AVAILABILITY_BIT;
enum VK_QUERY_RESULT_PARTIAL_BIT                 = VkQueryResultFlagBits.VK_QUERY_RESULT_PARTIAL_BIT;
enum VK_QUERY_RESULT_FLAG_BITS_MAX_ENUM          = VkQueryResultFlagBits.VK_QUERY_RESULT_FLAG_BITS_MAX_ENUM;
alias VkQueryResultFlags = VkFlags;

enum VkBufferCreateFlagBits {
    VK_BUFFER_CREATE_SPARSE_BINDING_BIT                          = 0x00000001,
    VK_BUFFER_CREATE_SPARSE_RESIDENCY_BIT                        = 0x00000002,
    VK_BUFFER_CREATE_SPARSE_ALIASED_BIT                          = 0x00000004,
    VK_BUFFER_CREATE_PROTECTED_BIT                               = 0x00000008,
    VK_BUFFER_CREATE_DEVICE_ADDRESS_CAPTURE_REPLAY_BIT_EXT       = 0x00000010,
    VK_BUFFER_CREATE_FLAG_BITS_MAX_ENUM                          = 0x7FFFFFFF
}

enum VK_BUFFER_CREATE_SPARSE_BINDING_BIT                         = VkBufferCreateFlagBits.VK_BUFFER_CREATE_SPARSE_BINDING_BIT;
enum VK_BUFFER_CREATE_SPARSE_RESIDENCY_BIT                       = VkBufferCreateFlagBits.VK_BUFFER_CREATE_SPARSE_RESIDENCY_BIT;
enum VK_BUFFER_CREATE_SPARSE_ALIASED_BIT                         = VkBufferCreateFlagBits.VK_BUFFER_CREATE_SPARSE_ALIASED_BIT;
enum VK_BUFFER_CREATE_PROTECTED_BIT                              = VkBufferCreateFlagBits.VK_BUFFER_CREATE_PROTECTED_BIT;
enum VK_BUFFER_CREATE_DEVICE_ADDRESS_CAPTURE_REPLAY_BIT_EXT      = VkBufferCreateFlagBits.VK_BUFFER_CREATE_DEVICE_ADDRESS_CAPTURE_REPLAY_BIT_EXT;
enum VK_BUFFER_CREATE_FLAG_BITS_MAX_ENUM                         = VkBufferCreateFlagBits.VK_BUFFER_CREATE_FLAG_BITS_MAX_ENUM;
alias VkBufferCreateFlags = VkFlags;

enum VkBufferUsageFlagBits {
    VK_BUFFER_USAGE_TRANSFER_SRC_BIT                             = 0x00000001,
    VK_BUFFER_USAGE_TRANSFER_DST_BIT                             = 0x00000002,
    VK_BUFFER_USAGE_UNIFORM_TEXEL_BUFFER_BIT                     = 0x00000004,
    VK_BUFFER_USAGE_STORAGE_TEXEL_BUFFER_BIT                     = 0x00000008,
    VK_BUFFER_USAGE_UNIFORM_BUFFER_BIT                           = 0x00000010,
    VK_BUFFER_USAGE_STORAGE_BUFFER_BIT                           = 0x00000020,
    VK_BUFFER_USAGE_INDEX_BUFFER_BIT                             = 0x00000040,
    VK_BUFFER_USAGE_VERTEX_BUFFER_BIT                            = 0x00000080,
    VK_BUFFER_USAGE_INDIRECT_BUFFER_BIT                          = 0x00000100,
    VK_BUFFER_USAGE_TRANSFORM_FEEDBACK_BUFFER_BIT_EXT            = 0x00000800,
    VK_BUFFER_USAGE_TRANSFORM_FEEDBACK_COUNTER_BUFFER_BIT_EXT    = 0x00001000,
    VK_BUFFER_USAGE_CONDITIONAL_RENDERING_BIT_EXT                = 0x00000200,
    VK_BUFFER_USAGE_RAY_TRACING_BIT_NV                           = 0x00000400,
    VK_BUFFER_USAGE_SHADER_DEVICE_ADDRESS_BIT_EXT                = 0x00020000,
    VK_BUFFER_USAGE_FLAG_BITS_MAX_ENUM                           = 0x7FFFFFFF
}

enum VK_BUFFER_USAGE_TRANSFER_SRC_BIT                            = VkBufferUsageFlagBits.VK_BUFFER_USAGE_TRANSFER_SRC_BIT;
enum VK_BUFFER_USAGE_TRANSFER_DST_BIT                            = VkBufferUsageFlagBits.VK_BUFFER_USAGE_TRANSFER_DST_BIT;
enum VK_BUFFER_USAGE_UNIFORM_TEXEL_BUFFER_BIT                    = VkBufferUsageFlagBits.VK_BUFFER_USAGE_UNIFORM_TEXEL_BUFFER_BIT;
enum VK_BUFFER_USAGE_STORAGE_TEXEL_BUFFER_BIT                    = VkBufferUsageFlagBits.VK_BUFFER_USAGE_STORAGE_TEXEL_BUFFER_BIT;
enum VK_BUFFER_USAGE_UNIFORM_BUFFER_BIT                          = VkBufferUsageFlagBits.VK_BUFFER_USAGE_UNIFORM_BUFFER_BIT;
enum VK_BUFFER_USAGE_STORAGE_BUFFER_BIT                          = VkBufferUsageFlagBits.VK_BUFFER_USAGE_STORAGE_BUFFER_BIT;
enum VK_BUFFER_USAGE_INDEX_BUFFER_BIT                            = VkBufferUsageFlagBits.VK_BUFFER_USAGE_INDEX_BUFFER_BIT;
enum VK_BUFFER_USAGE_VERTEX_BUFFER_BIT                           = VkBufferUsageFlagBits.VK_BUFFER_USAGE_VERTEX_BUFFER_BIT;
enum VK_BUFFER_USAGE_INDIRECT_BUFFER_BIT                         = VkBufferUsageFlagBits.VK_BUFFER_USAGE_INDIRECT_BUFFER_BIT;
enum VK_BUFFER_USAGE_TRANSFORM_FEEDBACK_BUFFER_BIT_EXT           = VkBufferUsageFlagBits.VK_BUFFER_USAGE_TRANSFORM_FEEDBACK_BUFFER_BIT_EXT;
enum VK_BUFFER_USAGE_TRANSFORM_FEEDBACK_COUNTER_BUFFER_BIT_EXT   = VkBufferUsageFlagBits.VK_BUFFER_USAGE_TRANSFORM_FEEDBACK_COUNTER_BUFFER_BIT_EXT;
enum VK_BUFFER_USAGE_CONDITIONAL_RENDERING_BIT_EXT               = VkBufferUsageFlagBits.VK_BUFFER_USAGE_CONDITIONAL_RENDERING_BIT_EXT;
enum VK_BUFFER_USAGE_RAY_TRACING_BIT_NV                          = VkBufferUsageFlagBits.VK_BUFFER_USAGE_RAY_TRACING_BIT_NV;
enum VK_BUFFER_USAGE_SHADER_DEVICE_ADDRESS_BIT_EXT               = VkBufferUsageFlagBits.VK_BUFFER_USAGE_SHADER_DEVICE_ADDRESS_BIT_EXT;
enum VK_BUFFER_USAGE_FLAG_BITS_MAX_ENUM                          = VkBufferUsageFlagBits.VK_BUFFER_USAGE_FLAG_BITS_MAX_ENUM;
alias VkBufferUsageFlags = VkFlags;
alias VkBufferViewCreateFlags = VkFlags;

enum VkImageViewCreateFlagBits {
    VK_IMAGE_VIEW_CREATE_FRAGMENT_DENSITY_MAP_DYNAMIC_BIT_EXT    = 0x00000001,
    VK_IMAGE_VIEW_CREATE_FLAG_BITS_MAX_ENUM                      = 0x7FFFFFFF
}

enum VK_IMAGE_VIEW_CREATE_FRAGMENT_DENSITY_MAP_DYNAMIC_BIT_EXT   = VkImageViewCreateFlagBits.VK_IMAGE_VIEW_CREATE_FRAGMENT_DENSITY_MAP_DYNAMIC_BIT_EXT;
enum VK_IMAGE_VIEW_CREATE_FLAG_BITS_MAX_ENUM                     = VkImageViewCreateFlagBits.VK_IMAGE_VIEW_CREATE_FLAG_BITS_MAX_ENUM;
alias VkImageViewCreateFlags = VkFlags;
alias VkShaderModuleCreateFlags = VkFlags;
alias VkPipelineCacheCreateFlags = VkFlags;

enum VkPipelineCreateFlagBits {
    VK_PIPELINE_CREATE_DISABLE_OPTIMIZATION_BIT                  = 0x00000001,
    VK_PIPELINE_CREATE_ALLOW_DERIVATIVES_BIT                     = 0x00000002,
    VK_PIPELINE_CREATE_DERIVATIVE_BIT                            = 0x00000004,
    VK_PIPELINE_CREATE_VIEW_INDEX_FROM_DEVICE_INDEX_BIT          = 0x00000008,
    VK_PIPELINE_CREATE_DISPATCH_BASE                             = 0x00000010,
    VK_PIPELINE_CREATE_DEFER_COMPILE_BIT_NV                      = 0x00000020,
    VK_PIPELINE_CREATE_VIEW_INDEX_FROM_DEVICE_INDEX_BIT_KHR      = VK_PIPELINE_CREATE_VIEW_INDEX_FROM_DEVICE_INDEX_BIT,
    VK_PIPELINE_CREATE_DISPATCH_BASE_KHR                         = VK_PIPELINE_CREATE_DISPATCH_BASE,
    VK_PIPELINE_CREATE_FLAG_BITS_MAX_ENUM                        = 0x7FFFFFFF
}

enum VK_PIPELINE_CREATE_DISABLE_OPTIMIZATION_BIT                 = VkPipelineCreateFlagBits.VK_PIPELINE_CREATE_DISABLE_OPTIMIZATION_BIT;
enum VK_PIPELINE_CREATE_ALLOW_DERIVATIVES_BIT                    = VkPipelineCreateFlagBits.VK_PIPELINE_CREATE_ALLOW_DERIVATIVES_BIT;
enum VK_PIPELINE_CREATE_DERIVATIVE_BIT                           = VkPipelineCreateFlagBits.VK_PIPELINE_CREATE_DERIVATIVE_BIT;
enum VK_PIPELINE_CREATE_VIEW_INDEX_FROM_DEVICE_INDEX_BIT         = VkPipelineCreateFlagBits.VK_PIPELINE_CREATE_VIEW_INDEX_FROM_DEVICE_INDEX_BIT;
enum VK_PIPELINE_CREATE_DISPATCH_BASE                            = VkPipelineCreateFlagBits.VK_PIPELINE_CREATE_DISPATCH_BASE;
enum VK_PIPELINE_CREATE_DEFER_COMPILE_BIT_NV                     = VkPipelineCreateFlagBits.VK_PIPELINE_CREATE_DEFER_COMPILE_BIT_NV;
enum VK_PIPELINE_CREATE_VIEW_INDEX_FROM_DEVICE_INDEX_BIT_KHR     = VkPipelineCreateFlagBits.VK_PIPELINE_CREATE_VIEW_INDEX_FROM_DEVICE_INDEX_BIT_KHR;
enum VK_PIPELINE_CREATE_DISPATCH_BASE_KHR                        = VkPipelineCreateFlagBits.VK_PIPELINE_CREATE_DISPATCH_BASE_KHR;
enum VK_PIPELINE_CREATE_FLAG_BITS_MAX_ENUM                       = VkPipelineCreateFlagBits.VK_PIPELINE_CREATE_FLAG_BITS_MAX_ENUM;
alias VkPipelineCreateFlags = VkFlags;
alias VkPipelineShaderStageCreateFlags = VkFlags;

enum VkShaderStageFlagBits {
    VK_SHADER_STAGE_VERTEX_BIT                   = 0x00000001,
    VK_SHADER_STAGE_TESSELLATION_CONTROL_BIT     = 0x00000002,
    VK_SHADER_STAGE_TESSELLATION_EVALUATION_BIT  = 0x00000004,
    VK_SHADER_STAGE_GEOMETRY_BIT                 = 0x00000008,
    VK_SHADER_STAGE_FRAGMENT_BIT                 = 0x00000010,
    VK_SHADER_STAGE_COMPUTE_BIT                  = 0x00000020,
    VK_SHADER_STAGE_ALL_GRAPHICS                 = 0x0000001F,
    VK_SHADER_STAGE_ALL                          = 0x7FFFFFFF,
    VK_SHADER_STAGE_RAYGEN_BIT_NV                = 0x00000100,
    VK_SHADER_STAGE_ANY_HIT_BIT_NV               = 0x00000200,
    VK_SHADER_STAGE_CLOSEST_HIT_BIT_NV           = 0x00000400,
    VK_SHADER_STAGE_MISS_BIT_NV                  = 0x00000800,
    VK_SHADER_STAGE_INTERSECTION_BIT_NV          = 0x00001000,
    VK_SHADER_STAGE_CALLABLE_BIT_NV              = 0x00002000,
    VK_SHADER_STAGE_TASK_BIT_NV                  = 0x00000040,
    VK_SHADER_STAGE_MESH_BIT_NV                  = 0x00000080,
    VK_SHADER_STAGE_FLAG_BITS_MAX_ENUM           = 0x7FFFFFFF
}

enum VK_SHADER_STAGE_VERTEX_BIT                  = VkShaderStageFlagBits.VK_SHADER_STAGE_VERTEX_BIT;
enum VK_SHADER_STAGE_TESSELLATION_CONTROL_BIT    = VkShaderStageFlagBits.VK_SHADER_STAGE_TESSELLATION_CONTROL_BIT;
enum VK_SHADER_STAGE_TESSELLATION_EVALUATION_BIT = VkShaderStageFlagBits.VK_SHADER_STAGE_TESSELLATION_EVALUATION_BIT;
enum VK_SHADER_STAGE_GEOMETRY_BIT                = VkShaderStageFlagBits.VK_SHADER_STAGE_GEOMETRY_BIT;
enum VK_SHADER_STAGE_FRAGMENT_BIT                = VkShaderStageFlagBits.VK_SHADER_STAGE_FRAGMENT_BIT;
enum VK_SHADER_STAGE_COMPUTE_BIT                 = VkShaderStageFlagBits.VK_SHADER_STAGE_COMPUTE_BIT;
enum VK_SHADER_STAGE_ALL_GRAPHICS                = VkShaderStageFlagBits.VK_SHADER_STAGE_ALL_GRAPHICS;
enum VK_SHADER_STAGE_ALL                         = VkShaderStageFlagBits.VK_SHADER_STAGE_ALL;
enum VK_SHADER_STAGE_RAYGEN_BIT_NV               = VkShaderStageFlagBits.VK_SHADER_STAGE_RAYGEN_BIT_NV;
enum VK_SHADER_STAGE_ANY_HIT_BIT_NV              = VkShaderStageFlagBits.VK_SHADER_STAGE_ANY_HIT_BIT_NV;
enum VK_SHADER_STAGE_CLOSEST_HIT_BIT_NV          = VkShaderStageFlagBits.VK_SHADER_STAGE_CLOSEST_HIT_BIT_NV;
enum VK_SHADER_STAGE_MISS_BIT_NV                 = VkShaderStageFlagBits.VK_SHADER_STAGE_MISS_BIT_NV;
enum VK_SHADER_STAGE_INTERSECTION_BIT_NV         = VkShaderStageFlagBits.VK_SHADER_STAGE_INTERSECTION_BIT_NV;
enum VK_SHADER_STAGE_CALLABLE_BIT_NV             = VkShaderStageFlagBits.VK_SHADER_STAGE_CALLABLE_BIT_NV;
enum VK_SHADER_STAGE_TASK_BIT_NV                 = VkShaderStageFlagBits.VK_SHADER_STAGE_TASK_BIT_NV;
enum VK_SHADER_STAGE_MESH_BIT_NV                 = VkShaderStageFlagBits.VK_SHADER_STAGE_MESH_BIT_NV;
enum VK_SHADER_STAGE_FLAG_BITS_MAX_ENUM          = VkShaderStageFlagBits.VK_SHADER_STAGE_FLAG_BITS_MAX_ENUM;
alias VkPipelineVertexInputStateCreateFlags = VkFlags;
alias VkPipelineInputAssemblyStateCreateFlags = VkFlags;
alias VkPipelineTessellationStateCreateFlags = VkFlags;
alias VkPipelineViewportStateCreateFlags = VkFlags;
alias VkPipelineRasterizationStateCreateFlags = VkFlags;

enum VkCullModeFlagBits {
    VK_CULL_MODE_NONE                    = 0,
    VK_CULL_MODE_FRONT_BIT               = 0x00000001,
    VK_CULL_MODE_BACK_BIT                = 0x00000002,
    VK_CULL_MODE_FRONT_AND_BACK          = 0x00000003,
    VK_CULL_MODE_FLAG_BITS_MAX_ENUM      = 0x7FFFFFFF
}

enum VK_CULL_MODE_NONE                   = VkCullModeFlagBits.VK_CULL_MODE_NONE;
enum VK_CULL_MODE_FRONT_BIT              = VkCullModeFlagBits.VK_CULL_MODE_FRONT_BIT;
enum VK_CULL_MODE_BACK_BIT               = VkCullModeFlagBits.VK_CULL_MODE_BACK_BIT;
enum VK_CULL_MODE_FRONT_AND_BACK         = VkCullModeFlagBits.VK_CULL_MODE_FRONT_AND_BACK;
enum VK_CULL_MODE_FLAG_BITS_MAX_ENUM     = VkCullModeFlagBits.VK_CULL_MODE_FLAG_BITS_MAX_ENUM;
alias VkCullModeFlags = VkFlags;
alias VkPipelineMultisampleStateCreateFlags = VkFlags;
alias VkPipelineDepthStencilStateCreateFlags = VkFlags;
alias VkPipelineColorBlendStateCreateFlags = VkFlags;

enum VkColorComponentFlagBits {
    VK_COLOR_COMPONENT_R_BIT                     = 0x00000001,
    VK_COLOR_COMPONENT_G_BIT                     = 0x00000002,
    VK_COLOR_COMPONENT_B_BIT                     = 0x00000004,
    VK_COLOR_COMPONENT_A_BIT                     = 0x00000008,
    VK_COLOR_COMPONENT_FLAG_BITS_MAX_ENUM        = 0x7FFFFFFF
}

enum VK_COLOR_COMPONENT_R_BIT                    = VkColorComponentFlagBits.VK_COLOR_COMPONENT_R_BIT;
enum VK_COLOR_COMPONENT_G_BIT                    = VkColorComponentFlagBits.VK_COLOR_COMPONENT_G_BIT;
enum VK_COLOR_COMPONENT_B_BIT                    = VkColorComponentFlagBits.VK_COLOR_COMPONENT_B_BIT;
enum VK_COLOR_COMPONENT_A_BIT                    = VkColorComponentFlagBits.VK_COLOR_COMPONENT_A_BIT;
enum VK_COLOR_COMPONENT_FLAG_BITS_MAX_ENUM       = VkColorComponentFlagBits.VK_COLOR_COMPONENT_FLAG_BITS_MAX_ENUM;
alias VkColorComponentFlags = VkFlags;
alias VkPipelineDynamicStateCreateFlags = VkFlags;
alias VkPipelineLayoutCreateFlags = VkFlags;
alias VkShaderStageFlags = VkFlags;

enum VkSamplerCreateFlagBits {
    VK_SAMPLER_CREATE_SUBSAMPLED_BIT_EXT                         = 0x00000001,
    VK_SAMPLER_CREATE_SUBSAMPLED_COARSE_RECONSTRUCTION_BIT_EXT   = 0x00000002,
    VK_SAMPLER_CREATE_FLAG_BITS_MAX_ENUM                         = 0x7FFFFFFF
}

enum VK_SAMPLER_CREATE_SUBSAMPLED_BIT_EXT                        = VkSamplerCreateFlagBits.VK_SAMPLER_CREATE_SUBSAMPLED_BIT_EXT;
enum VK_SAMPLER_CREATE_SUBSAMPLED_COARSE_RECONSTRUCTION_BIT_EXT  = VkSamplerCreateFlagBits.VK_SAMPLER_CREATE_SUBSAMPLED_COARSE_RECONSTRUCTION_BIT_EXT;
enum VK_SAMPLER_CREATE_FLAG_BITS_MAX_ENUM                        = VkSamplerCreateFlagBits.VK_SAMPLER_CREATE_FLAG_BITS_MAX_ENUM;
alias VkSamplerCreateFlags = VkFlags;

enum VkDescriptorSetLayoutCreateFlagBits {
    VK_DESCRIPTOR_SET_LAYOUT_CREATE_PUSH_DESCRIPTOR_BIT_KHR              = 0x00000001,
    VK_DESCRIPTOR_SET_LAYOUT_CREATE_UPDATE_AFTER_BIND_POOL_BIT_EXT       = 0x00000002,
    VK_DESCRIPTOR_SET_LAYOUT_CREATE_FLAG_BITS_MAX_ENUM                   = 0x7FFFFFFF
}

enum VK_DESCRIPTOR_SET_LAYOUT_CREATE_PUSH_DESCRIPTOR_BIT_KHR             = VkDescriptorSetLayoutCreateFlagBits.VK_DESCRIPTOR_SET_LAYOUT_CREATE_PUSH_DESCRIPTOR_BIT_KHR;
enum VK_DESCRIPTOR_SET_LAYOUT_CREATE_UPDATE_AFTER_BIND_POOL_BIT_EXT      = VkDescriptorSetLayoutCreateFlagBits.VK_DESCRIPTOR_SET_LAYOUT_CREATE_UPDATE_AFTER_BIND_POOL_BIT_EXT;
enum VK_DESCRIPTOR_SET_LAYOUT_CREATE_FLAG_BITS_MAX_ENUM                  = VkDescriptorSetLayoutCreateFlagBits.VK_DESCRIPTOR_SET_LAYOUT_CREATE_FLAG_BITS_MAX_ENUM;
alias VkDescriptorSetLayoutCreateFlags = VkFlags;

enum VkDescriptorPoolCreateFlagBits {
    VK_DESCRIPTOR_POOL_CREATE_FREE_DESCRIPTOR_SET_BIT    = 0x00000001,
    VK_DESCRIPTOR_POOL_CREATE_UPDATE_AFTER_BIND_BIT_EXT  = 0x00000002,
    VK_DESCRIPTOR_POOL_CREATE_FLAG_BITS_MAX_ENUM         = 0x7FFFFFFF
}

enum VK_DESCRIPTOR_POOL_CREATE_FREE_DESCRIPTOR_SET_BIT   = VkDescriptorPoolCreateFlagBits.VK_DESCRIPTOR_POOL_CREATE_FREE_DESCRIPTOR_SET_BIT;
enum VK_DESCRIPTOR_POOL_CREATE_UPDATE_AFTER_BIND_BIT_EXT = VkDescriptorPoolCreateFlagBits.VK_DESCRIPTOR_POOL_CREATE_UPDATE_AFTER_BIND_BIT_EXT;
enum VK_DESCRIPTOR_POOL_CREATE_FLAG_BITS_MAX_ENUM        = VkDescriptorPoolCreateFlagBits.VK_DESCRIPTOR_POOL_CREATE_FLAG_BITS_MAX_ENUM;
alias VkDescriptorPoolCreateFlags = VkFlags;
alias VkDescriptorPoolResetFlags = VkFlags;
alias VkFramebufferCreateFlags = VkFlags;
alias VkRenderPassCreateFlags = VkFlags;

enum VkAttachmentDescriptionFlagBits {
    VK_ATTACHMENT_DESCRIPTION_MAY_ALIAS_BIT              = 0x00000001,
    VK_ATTACHMENT_DESCRIPTION_FLAG_BITS_MAX_ENUM         = 0x7FFFFFFF
}

enum VK_ATTACHMENT_DESCRIPTION_MAY_ALIAS_BIT             = VkAttachmentDescriptionFlagBits.VK_ATTACHMENT_DESCRIPTION_MAY_ALIAS_BIT;
enum VK_ATTACHMENT_DESCRIPTION_FLAG_BITS_MAX_ENUM        = VkAttachmentDescriptionFlagBits.VK_ATTACHMENT_DESCRIPTION_FLAG_BITS_MAX_ENUM;
alias VkAttachmentDescriptionFlags = VkFlags;

enum VkSubpassDescriptionFlagBits {
    VK_SUBPASS_DESCRIPTION_PER_VIEW_ATTRIBUTES_BIT_NVX           = 0x00000001,
    VK_SUBPASS_DESCRIPTION_PER_VIEW_POSITION_X_ONLY_BIT_NVX      = 0x00000002,
    VK_SUBPASS_DESCRIPTION_FLAG_BITS_MAX_ENUM                    = 0x7FFFFFFF
}

enum VK_SUBPASS_DESCRIPTION_PER_VIEW_ATTRIBUTES_BIT_NVX          = VkSubpassDescriptionFlagBits.VK_SUBPASS_DESCRIPTION_PER_VIEW_ATTRIBUTES_BIT_NVX;
enum VK_SUBPASS_DESCRIPTION_PER_VIEW_POSITION_X_ONLY_BIT_NVX     = VkSubpassDescriptionFlagBits.VK_SUBPASS_DESCRIPTION_PER_VIEW_POSITION_X_ONLY_BIT_NVX;
enum VK_SUBPASS_DESCRIPTION_FLAG_BITS_MAX_ENUM                   = VkSubpassDescriptionFlagBits.VK_SUBPASS_DESCRIPTION_FLAG_BITS_MAX_ENUM;
alias VkSubpassDescriptionFlags = VkFlags;

enum VkAccessFlagBits {
    VK_ACCESS_INDIRECT_COMMAND_READ_BIT                  = 0x00000001,
    VK_ACCESS_INDEX_READ_BIT                             = 0x00000002,
    VK_ACCESS_VERTEX_ATTRIBUTE_READ_BIT                  = 0x00000004,
    VK_ACCESS_UNIFORM_READ_BIT                           = 0x00000008,
    VK_ACCESS_INPUT_ATTACHMENT_READ_BIT                  = 0x00000010,
    VK_ACCESS_SHADER_READ_BIT                            = 0x00000020,
    VK_ACCESS_SHADER_WRITE_BIT                           = 0x00000040,
    VK_ACCESS_COLOR_ATTACHMENT_READ_BIT                  = 0x00000080,
    VK_ACCESS_COLOR_ATTACHMENT_WRITE_BIT                 = 0x00000100,
    VK_ACCESS_DEPTH_STENCIL_ATTACHMENT_READ_BIT          = 0x00000200,
    VK_ACCESS_DEPTH_STENCIL_ATTACHMENT_WRITE_BIT         = 0x00000400,
    VK_ACCESS_TRANSFER_READ_BIT                          = 0x00000800,
    VK_ACCESS_TRANSFER_WRITE_BIT                         = 0x00001000,
    VK_ACCESS_HOST_READ_BIT                              = 0x00002000,
    VK_ACCESS_HOST_WRITE_BIT                             = 0x00004000,
    VK_ACCESS_MEMORY_READ_BIT                            = 0x00008000,
    VK_ACCESS_MEMORY_WRITE_BIT                           = 0x00010000,
    VK_ACCESS_TRANSFORM_FEEDBACK_WRITE_BIT_EXT           = 0x02000000,
    VK_ACCESS_TRANSFORM_FEEDBACK_COUNTER_READ_BIT_EXT    = 0x04000000,
    VK_ACCESS_TRANSFORM_FEEDBACK_COUNTER_WRITE_BIT_EXT   = 0x08000000,
    VK_ACCESS_CONDITIONAL_RENDERING_READ_BIT_EXT         = 0x00100000,
    VK_ACCESS_COMMAND_PROCESS_READ_BIT_NVX               = 0x00020000,
    VK_ACCESS_COMMAND_PROCESS_WRITE_BIT_NVX              = 0x00040000,
    VK_ACCESS_COLOR_ATTACHMENT_READ_NONCOHERENT_BIT_EXT  = 0x00080000,
    VK_ACCESS_SHADING_RATE_IMAGE_READ_BIT_NV             = 0x00800000,
    VK_ACCESS_ACCELERATION_STRUCTURE_READ_BIT_NV         = 0x00200000,
    VK_ACCESS_ACCELERATION_STRUCTURE_WRITE_BIT_NV        = 0x00400000,
    VK_ACCESS_FRAGMENT_DENSITY_MAP_READ_BIT_EXT          = 0x01000000,
    VK_ACCESS_FLAG_BITS_MAX_ENUM                         = 0x7FFFFFFF
}

enum VK_ACCESS_INDIRECT_COMMAND_READ_BIT                 = VkAccessFlagBits.VK_ACCESS_INDIRECT_COMMAND_READ_BIT;
enum VK_ACCESS_INDEX_READ_BIT                            = VkAccessFlagBits.VK_ACCESS_INDEX_READ_BIT;
enum VK_ACCESS_VERTEX_ATTRIBUTE_READ_BIT                 = VkAccessFlagBits.VK_ACCESS_VERTEX_ATTRIBUTE_READ_BIT;
enum VK_ACCESS_UNIFORM_READ_BIT                          = VkAccessFlagBits.VK_ACCESS_UNIFORM_READ_BIT;
enum VK_ACCESS_INPUT_ATTACHMENT_READ_BIT                 = VkAccessFlagBits.VK_ACCESS_INPUT_ATTACHMENT_READ_BIT;
enum VK_ACCESS_SHADER_READ_BIT                           = VkAccessFlagBits.VK_ACCESS_SHADER_READ_BIT;
enum VK_ACCESS_SHADER_WRITE_BIT                          = VkAccessFlagBits.VK_ACCESS_SHADER_WRITE_BIT;
enum VK_ACCESS_COLOR_ATTACHMENT_READ_BIT                 = VkAccessFlagBits.VK_ACCESS_COLOR_ATTACHMENT_READ_BIT;
enum VK_ACCESS_COLOR_ATTACHMENT_WRITE_BIT                = VkAccessFlagBits.VK_ACCESS_COLOR_ATTACHMENT_WRITE_BIT;
enum VK_ACCESS_DEPTH_STENCIL_ATTACHMENT_READ_BIT         = VkAccessFlagBits.VK_ACCESS_DEPTH_STENCIL_ATTACHMENT_READ_BIT;
enum VK_ACCESS_DEPTH_STENCIL_ATTACHMENT_WRITE_BIT        = VkAccessFlagBits.VK_ACCESS_DEPTH_STENCIL_ATTACHMENT_WRITE_BIT;
enum VK_ACCESS_TRANSFER_READ_BIT                         = VkAccessFlagBits.VK_ACCESS_TRANSFER_READ_BIT;
enum VK_ACCESS_TRANSFER_WRITE_BIT                        = VkAccessFlagBits.VK_ACCESS_TRANSFER_WRITE_BIT;
enum VK_ACCESS_HOST_READ_BIT                             = VkAccessFlagBits.VK_ACCESS_HOST_READ_BIT;
enum VK_ACCESS_HOST_WRITE_BIT                            = VkAccessFlagBits.VK_ACCESS_HOST_WRITE_BIT;
enum VK_ACCESS_MEMORY_READ_BIT                           = VkAccessFlagBits.VK_ACCESS_MEMORY_READ_BIT;
enum VK_ACCESS_MEMORY_WRITE_BIT                          = VkAccessFlagBits.VK_ACCESS_MEMORY_WRITE_BIT;
enum VK_ACCESS_TRANSFORM_FEEDBACK_WRITE_BIT_EXT          = VkAccessFlagBits.VK_ACCESS_TRANSFORM_FEEDBACK_WRITE_BIT_EXT;
enum VK_ACCESS_TRANSFORM_FEEDBACK_COUNTER_READ_BIT_EXT   = VkAccessFlagBits.VK_ACCESS_TRANSFORM_FEEDBACK_COUNTER_READ_BIT_EXT;
enum VK_ACCESS_TRANSFORM_FEEDBACK_COUNTER_WRITE_BIT_EXT  = VkAccessFlagBits.VK_ACCESS_TRANSFORM_FEEDBACK_COUNTER_WRITE_BIT_EXT;
enum VK_ACCESS_CONDITIONAL_RENDERING_READ_BIT_EXT        = VkAccessFlagBits.VK_ACCESS_CONDITIONAL_RENDERING_READ_BIT_EXT;
enum VK_ACCESS_COMMAND_PROCESS_READ_BIT_NVX              = VkAccessFlagBits.VK_ACCESS_COMMAND_PROCESS_READ_BIT_NVX;
enum VK_ACCESS_COMMAND_PROCESS_WRITE_BIT_NVX             = VkAccessFlagBits.VK_ACCESS_COMMAND_PROCESS_WRITE_BIT_NVX;
enum VK_ACCESS_COLOR_ATTACHMENT_READ_NONCOHERENT_BIT_EXT = VkAccessFlagBits.VK_ACCESS_COLOR_ATTACHMENT_READ_NONCOHERENT_BIT_EXT;
enum VK_ACCESS_SHADING_RATE_IMAGE_READ_BIT_NV            = VkAccessFlagBits.VK_ACCESS_SHADING_RATE_IMAGE_READ_BIT_NV;
enum VK_ACCESS_ACCELERATION_STRUCTURE_READ_BIT_NV        = VkAccessFlagBits.VK_ACCESS_ACCELERATION_STRUCTURE_READ_BIT_NV;
enum VK_ACCESS_ACCELERATION_STRUCTURE_WRITE_BIT_NV       = VkAccessFlagBits.VK_ACCESS_ACCELERATION_STRUCTURE_WRITE_BIT_NV;
enum VK_ACCESS_FRAGMENT_DENSITY_MAP_READ_BIT_EXT         = VkAccessFlagBits.VK_ACCESS_FRAGMENT_DENSITY_MAP_READ_BIT_EXT;
enum VK_ACCESS_FLAG_BITS_MAX_ENUM                        = VkAccessFlagBits.VK_ACCESS_FLAG_BITS_MAX_ENUM;
alias VkAccessFlags = VkFlags;

enum VkDependencyFlagBits {
    VK_DEPENDENCY_BY_REGION_BIT          = 0x00000001,
    VK_DEPENDENCY_DEVICE_GROUP_BIT       = 0x00000004,
    VK_DEPENDENCY_VIEW_LOCAL_BIT         = 0x00000002,
    VK_DEPENDENCY_VIEW_LOCAL_BIT_KHR     = VK_DEPENDENCY_VIEW_LOCAL_BIT,
    VK_DEPENDENCY_DEVICE_GROUP_BIT_KHR   = VK_DEPENDENCY_DEVICE_GROUP_BIT,
    VK_DEPENDENCY_FLAG_BITS_MAX_ENUM     = 0x7FFFFFFF
}

enum VK_DEPENDENCY_BY_REGION_BIT         = VkDependencyFlagBits.VK_DEPENDENCY_BY_REGION_BIT;
enum VK_DEPENDENCY_DEVICE_GROUP_BIT      = VkDependencyFlagBits.VK_DEPENDENCY_DEVICE_GROUP_BIT;
enum VK_DEPENDENCY_VIEW_LOCAL_BIT        = VkDependencyFlagBits.VK_DEPENDENCY_VIEW_LOCAL_BIT;
enum VK_DEPENDENCY_VIEW_LOCAL_BIT_KHR    = VkDependencyFlagBits.VK_DEPENDENCY_VIEW_LOCAL_BIT_KHR;
enum VK_DEPENDENCY_DEVICE_GROUP_BIT_KHR  = VkDependencyFlagBits.VK_DEPENDENCY_DEVICE_GROUP_BIT_KHR;
enum VK_DEPENDENCY_FLAG_BITS_MAX_ENUM    = VkDependencyFlagBits.VK_DEPENDENCY_FLAG_BITS_MAX_ENUM;
alias VkDependencyFlags = VkFlags;

enum VkCommandPoolCreateFlagBits {
    VK_COMMAND_POOL_CREATE_TRANSIENT_BIT                 = 0x00000001,
    VK_COMMAND_POOL_CREATE_RESET_COMMAND_BUFFER_BIT      = 0x00000002,
    VK_COMMAND_POOL_CREATE_PROTECTED_BIT                 = 0x00000004,
    VK_COMMAND_POOL_CREATE_FLAG_BITS_MAX_ENUM            = 0x7FFFFFFF
}

enum VK_COMMAND_POOL_CREATE_TRANSIENT_BIT                = VkCommandPoolCreateFlagBits.VK_COMMAND_POOL_CREATE_TRANSIENT_BIT;
enum VK_COMMAND_POOL_CREATE_RESET_COMMAND_BUFFER_BIT     = VkCommandPoolCreateFlagBits.VK_COMMAND_POOL_CREATE_RESET_COMMAND_BUFFER_BIT;
enum VK_COMMAND_POOL_CREATE_PROTECTED_BIT                = VkCommandPoolCreateFlagBits.VK_COMMAND_POOL_CREATE_PROTECTED_BIT;
enum VK_COMMAND_POOL_CREATE_FLAG_BITS_MAX_ENUM           = VkCommandPoolCreateFlagBits.VK_COMMAND_POOL_CREATE_FLAG_BITS_MAX_ENUM;
alias VkCommandPoolCreateFlags = VkFlags;

enum VkCommandPoolResetFlagBits {
    VK_COMMAND_POOL_RESET_RELEASE_RESOURCES_BIT  = 0x00000001,
    VK_COMMAND_POOL_RESET_FLAG_BITS_MAX_ENUM     = 0x7FFFFFFF
}

enum VK_COMMAND_POOL_RESET_RELEASE_RESOURCES_BIT = VkCommandPoolResetFlagBits.VK_COMMAND_POOL_RESET_RELEASE_RESOURCES_BIT;
enum VK_COMMAND_POOL_RESET_FLAG_BITS_MAX_ENUM    = VkCommandPoolResetFlagBits.VK_COMMAND_POOL_RESET_FLAG_BITS_MAX_ENUM;
alias VkCommandPoolResetFlags = VkFlags;

enum VkCommandBufferUsageFlagBits {
    VK_COMMAND_BUFFER_USAGE_ONE_TIME_SUBMIT_BIT          = 0x00000001,
    VK_COMMAND_BUFFER_USAGE_RENDER_PASS_CONTINUE_BIT     = 0x00000002,
    VK_COMMAND_BUFFER_USAGE_SIMULTANEOUS_USE_BIT         = 0x00000004,
    VK_COMMAND_BUFFER_USAGE_FLAG_BITS_MAX_ENUM           = 0x7FFFFFFF
}

enum VK_COMMAND_BUFFER_USAGE_ONE_TIME_SUBMIT_BIT         = VkCommandBufferUsageFlagBits.VK_COMMAND_BUFFER_USAGE_ONE_TIME_SUBMIT_BIT;
enum VK_COMMAND_BUFFER_USAGE_RENDER_PASS_CONTINUE_BIT    = VkCommandBufferUsageFlagBits.VK_COMMAND_BUFFER_USAGE_RENDER_PASS_CONTINUE_BIT;
enum VK_COMMAND_BUFFER_USAGE_SIMULTANEOUS_USE_BIT        = VkCommandBufferUsageFlagBits.VK_COMMAND_BUFFER_USAGE_SIMULTANEOUS_USE_BIT;
enum VK_COMMAND_BUFFER_USAGE_FLAG_BITS_MAX_ENUM          = VkCommandBufferUsageFlagBits.VK_COMMAND_BUFFER_USAGE_FLAG_BITS_MAX_ENUM;
alias VkCommandBufferUsageFlags = VkFlags;

enum VkQueryControlFlagBits {
    VK_QUERY_CONTROL_PRECISE_BIT                 = 0x00000001,
    VK_QUERY_CONTROL_FLAG_BITS_MAX_ENUM          = 0x7FFFFFFF
}

enum VK_QUERY_CONTROL_PRECISE_BIT                = VkQueryControlFlagBits.VK_QUERY_CONTROL_PRECISE_BIT;
enum VK_QUERY_CONTROL_FLAG_BITS_MAX_ENUM         = VkQueryControlFlagBits.VK_QUERY_CONTROL_FLAG_BITS_MAX_ENUM;
alias VkQueryControlFlags = VkFlags;

enum VkCommandBufferResetFlagBits {
    VK_COMMAND_BUFFER_RESET_RELEASE_RESOURCES_BIT        = 0x00000001,
    VK_COMMAND_BUFFER_RESET_FLAG_BITS_MAX_ENUM           = 0x7FFFFFFF
}

enum VK_COMMAND_BUFFER_RESET_RELEASE_RESOURCES_BIT       = VkCommandBufferResetFlagBits.VK_COMMAND_BUFFER_RESET_RELEASE_RESOURCES_BIT;
enum VK_COMMAND_BUFFER_RESET_FLAG_BITS_MAX_ENUM          = VkCommandBufferResetFlagBits.VK_COMMAND_BUFFER_RESET_FLAG_BITS_MAX_ENUM;
alias VkCommandBufferResetFlags = VkFlags;

enum VkStencilFaceFlagBits {
    VK_STENCIL_FACE_FRONT_BIT                    = 0x00000001,
    VK_STENCIL_FACE_BACK_BIT                     = 0x00000002,
    VK_STENCIL_FRONT_AND_BACK                    = 0x00000003,
    VK_STENCIL_FACE_FLAG_BITS_MAX_ENUM           = 0x7FFFFFFF
}

enum VK_STENCIL_FACE_FRONT_BIT                   = VkStencilFaceFlagBits.VK_STENCIL_FACE_FRONT_BIT;
enum VK_STENCIL_FACE_BACK_BIT                    = VkStencilFaceFlagBits.VK_STENCIL_FACE_BACK_BIT;
enum VK_STENCIL_FRONT_AND_BACK                   = VkStencilFaceFlagBits.VK_STENCIL_FRONT_AND_BACK;
enum VK_STENCIL_FACE_FLAG_BITS_MAX_ENUM          = VkStencilFaceFlagBits.VK_STENCIL_FACE_FLAG_BITS_MAX_ENUM;
alias VkStencilFaceFlags = VkFlags;

alias PFN_vkAllocationFunction = void* function(
    void*                       pUserData,
    size_t                      size,
    size_t                      alignment,
    VkSystemAllocationScope     allocationScope
);

alias PFN_vkReallocationFunction = void* function(
    void*                       pUserData,
    void*                       pOriginal,
    size_t                      size,
    size_t                      alignment,
    VkSystemAllocationScope     allocationScope
);

alias PFN_vkFreeFunction = void function(
    void*                       pUserData,
    void*                       pMemory
);

alias PFN_vkInternalAllocationNotification = void function(
    void*                       pUserData,
    size_t                      size,
    VkInternalAllocationType    allocationType,
    VkSystemAllocationScope     allocationScope
);

alias PFN_vkInternalFreeNotification = void function(
    void*                       pUserData,
    size_t                      size,
    VkInternalAllocationType    allocationType,
    VkSystemAllocationScope     allocationScope
);

alias PFN_vkVoidFunction = void function();

struct VkApplicationInfo {
    VkStructureType  sType = VK_STRUCTURE_TYPE_APPLICATION_INFO;
    const( void )*   pNext;
    const( char )*   pApplicationName;
    uint32_t         applicationVersion;
    const( char )*   pEngineName;
    uint32_t         engineVersion;
    uint32_t         apiVersion;
}

struct VkInstanceCreateInfo {
    VkStructureType              sType = VK_STRUCTURE_TYPE_INSTANCE_CREATE_INFO;
    const( void )*               pNext;
    VkInstanceCreateFlags        flags;
    const( VkApplicationInfo )*  pApplicationInfo;
    uint32_t                     enabledLayerCount;
    const( char* )*              ppEnabledLayerNames;
    uint32_t                     enabledExtensionCount;
    const( char* )*              ppEnabledExtensionNames;
}

struct VkAllocationCallbacks {
    void*                                 pUserData;
    PFN_vkAllocationFunction              pfnAllocation;
    PFN_vkReallocationFunction            pfnReallocation;
    PFN_vkFreeFunction                    pfnFree;
    PFN_vkInternalAllocationNotification  pfnInternalAllocation;
    PFN_vkInternalFreeNotification        pfnInternalFree;
}

struct VkPhysicalDeviceFeatures {
    VkBool32  robustBufferAccess;
    VkBool32  fullDrawIndexUint32;
    VkBool32  imageCubeArray;
    VkBool32  independentBlend;
    VkBool32  geometryShader;
    VkBool32  tessellationShader;
    VkBool32  sampleRateShading;
    VkBool32  dualSrcBlend;
    VkBool32  logicOp;
    VkBool32  multiDrawIndirect;
    VkBool32  drawIndirectFirstInstance;
    VkBool32  depthClamp;
    VkBool32  depthBiasClamp;
    VkBool32  fillModeNonSolid;
    VkBool32  depthBounds;
    VkBool32  wideLines;
    VkBool32  largePoints;
    VkBool32  alphaToOne;
    VkBool32  multiViewport;
    VkBool32  samplerAnisotropy;
    VkBool32  textureCompressionETC2;
    VkBool32  textureCompressionASTC_LDR;
    VkBool32  textureCompressionBC;
    VkBool32  occlusionQueryPrecise;
    VkBool32  pipelineStatisticsQuery;
    VkBool32  vertexPipelineStoresAndAtomics;
    VkBool32  fragmentStoresAndAtomics;
    VkBool32  shaderTessellationAndGeometryPointSize;
    VkBool32  shaderImageGatherExtended;
    VkBool32  shaderStorageImageExtendedFormats;
    VkBool32  shaderStorageImageMultisample;
    VkBool32  shaderStorageImageReadWithoutFormat;
    VkBool32  shaderStorageImageWriteWithoutFormat;
    VkBool32  shaderUniformBufferArrayDynamicIndexing;
    VkBool32  shaderSampledImageArrayDynamicIndexing;
    VkBool32  shaderStorageBufferArrayDynamicIndexing;
    VkBool32  shaderStorageImageArrayDynamicIndexing;
    VkBool32  shaderClipDistance;
    VkBool32  shaderCullDistance;
    VkBool32  shaderFloat64;
    VkBool32  shaderInt64;
    VkBool32  shaderInt16;
    VkBool32  shaderResourceResidency;
    VkBool32  shaderResourceMinLod;
    VkBool32  sparseBinding;
    VkBool32  sparseResidencyBuffer;
    VkBool32  sparseResidencyImage2D;
    VkBool32  sparseResidencyImage3D;
    VkBool32  sparseResidency2Samples;
    VkBool32  sparseResidency4Samples;
    VkBool32  sparseResidency8Samples;
    VkBool32  sparseResidency16Samples;
    VkBool32  sparseResidencyAliased;
    VkBool32  variableMultisampleRate;
    VkBool32  inheritedQueries;
}

struct VkFormatProperties {
    VkFormatFeatureFlags  linearTilingFeatures;
    VkFormatFeatureFlags  optimalTilingFeatures;
    VkFormatFeatureFlags  bufferFeatures;
}

struct VkExtent3D {
    uint32_t  width;
    uint32_t  height;
    uint32_t  depth;
}

struct VkImageFormatProperties {
    VkExtent3D          maxExtent;
    uint32_t            maxMipLevels;
    uint32_t            maxArrayLayers;
    VkSampleCountFlags  sampleCounts;
    VkDeviceSize        maxResourceSize;
}

struct VkPhysicalDeviceLimits {
    uint32_t            maxImageDimension1D;
    uint32_t            maxImageDimension2D;
    uint32_t            maxImageDimension3D;
    uint32_t            maxImageDimensionCube;
    uint32_t            maxImageArrayLayers;
    uint32_t            maxTexelBufferElements;
    uint32_t            maxUniformBufferRange;
    uint32_t            maxStorageBufferRange;
    uint32_t            maxPushConstantsSize;
    uint32_t            maxMemoryAllocationCount;
    uint32_t            maxSamplerAllocationCount;
    VkDeviceSize        bufferImageGranularity;
    VkDeviceSize        sparseAddressSpaceSize;
    uint32_t            maxBoundDescriptorSets;
    uint32_t            maxPerStageDescriptorSamplers;
    uint32_t            maxPerStageDescriptorUniformBuffers;
    uint32_t            maxPerStageDescriptorStorageBuffers;
    uint32_t            maxPerStageDescriptorSampledImages;
    uint32_t            maxPerStageDescriptorStorageImages;
    uint32_t            maxPerStageDescriptorInputAttachments;
    uint32_t            maxPerStageResources;
    uint32_t            maxDescriptorSetSamplers;
    uint32_t            maxDescriptorSetUniformBuffers;
    uint32_t            maxDescriptorSetUniformBuffersDynamic;
    uint32_t            maxDescriptorSetStorageBuffers;
    uint32_t            maxDescriptorSetStorageBuffersDynamic;
    uint32_t            maxDescriptorSetSampledImages;
    uint32_t            maxDescriptorSetStorageImages;
    uint32_t            maxDescriptorSetInputAttachments;
    uint32_t            maxVertexInputAttributes;
    uint32_t            maxVertexInputBindings;
    uint32_t            maxVertexInputAttributeOffset;
    uint32_t            maxVertexInputBindingStride;
    uint32_t            maxVertexOutputComponents;
    uint32_t            maxTessellationGenerationLevel;
    uint32_t            maxTessellationPatchSize;
    uint32_t            maxTessellationControlPerVertexInputComponents;
    uint32_t            maxTessellationControlPerVertexOutputComponents;
    uint32_t            maxTessellationControlPerPatchOutputComponents;
    uint32_t            maxTessellationControlTotalOutputComponents;
    uint32_t            maxTessellationEvaluationInputComponents;
    uint32_t            maxTessellationEvaluationOutputComponents;
    uint32_t            maxGeometryShaderInvocations;
    uint32_t            maxGeometryInputComponents;
    uint32_t            maxGeometryOutputComponents;
    uint32_t            maxGeometryOutputVertices;
    uint32_t            maxGeometryTotalOutputComponents;
    uint32_t            maxFragmentInputComponents;
    uint32_t            maxFragmentOutputAttachments;
    uint32_t            maxFragmentDualSrcAttachments;
    uint32_t            maxFragmentCombinedOutputResources;
    uint32_t            maxComputeSharedMemorySize;
    uint32_t[3]         maxComputeWorkGroupCount;
    uint32_t            maxComputeWorkGroupInvocations;
    uint32_t[3]         maxComputeWorkGroupSize;
    uint32_t            subPixelPrecisionBits;
    uint32_t            subTexelPrecisionBits;
    uint32_t            mipmapPrecisionBits;
    uint32_t            maxDrawIndexedIndexValue;
    uint32_t            maxDrawIndirectCount;
    float               maxSamplerLodBias;
    float               maxSamplerAnisotropy;
    uint32_t            maxViewports;
    uint32_t[2]         maxViewportDimensions;
    float[2]            viewportBoundsRange;
    uint32_t            viewportSubPixelBits;
    size_t              minMemoryMapAlignment;
    VkDeviceSize        minTexelBufferOffsetAlignment;
    VkDeviceSize        minUniformBufferOffsetAlignment;
    VkDeviceSize        minStorageBufferOffsetAlignment;
    int32_t             minTexelOffset;
    uint32_t            maxTexelOffset;
    int32_t             minTexelGatherOffset;
    uint32_t            maxTexelGatherOffset;
    float               minInterpolationOffset;
    float               maxInterpolationOffset;
    uint32_t            subPixelInterpolationOffsetBits;
    uint32_t            maxFramebufferWidth;
    uint32_t            maxFramebufferHeight;
    uint32_t            maxFramebufferLayers;
    VkSampleCountFlags  framebufferColorSampleCounts;
    VkSampleCountFlags  framebufferDepthSampleCounts;
    VkSampleCountFlags  framebufferStencilSampleCounts;
    VkSampleCountFlags  framebufferNoAttachmentsSampleCounts;
    uint32_t            maxColorAttachments;
    VkSampleCountFlags  sampledImageColorSampleCounts;
    VkSampleCountFlags  sampledImageIntegerSampleCounts;
    VkSampleCountFlags  sampledImageDepthSampleCounts;
    VkSampleCountFlags  sampledImageStencilSampleCounts;
    VkSampleCountFlags  storageImageSampleCounts;
    uint32_t            maxSampleMaskWords;
    VkBool32            timestampComputeAndGraphics;
    float               timestampPeriod;
    uint32_t            maxClipDistances;
    uint32_t            maxCullDistances;
    uint32_t            maxCombinedClipAndCullDistances;
    uint32_t            discreteQueuePriorities;
    float[2]            pointSizeRange;
    float[2]            lineWidthRange;
    float               pointSizeGranularity;
    float               lineWidthGranularity;
    VkBool32            strictLines;
    VkBool32            standardSampleLocations;
    VkDeviceSize        optimalBufferCopyOffsetAlignment;
    VkDeviceSize        optimalBufferCopyRowPitchAlignment;
    VkDeviceSize        nonCoherentAtomSize;
}

struct VkPhysicalDeviceSparseProperties {
    VkBool32  residencyStandard2DBlockShape;
    VkBool32  residencyStandard2DMultisampleBlockShape;
    VkBool32  residencyStandard3DBlockShape;
    VkBool32  residencyAlignedMipSize;
    VkBool32  residencyNonResidentStrict;
}

struct VkPhysicalDeviceProperties {
    uint32_t                                  apiVersion;
    uint32_t                                  driverVersion;
    uint32_t                                  vendorID;
    uint32_t                                  deviceID;
    VkPhysicalDeviceType                      deviceType;
    char[ VK_MAX_PHYSICAL_DEVICE_NAME_SIZE ]  deviceName;
    uint8_t[ VK_UUID_SIZE ]                   pipelineCacheUUID;
    VkPhysicalDeviceLimits                    limits;
    VkPhysicalDeviceSparseProperties          sparseProperties;
}

struct VkQueueFamilyProperties {
    VkQueueFlags  queueFlags;
    uint32_t      queueCount;
    uint32_t      timestampValidBits;
    VkExtent3D    minImageTransferGranularity;
}

struct VkMemoryType {
    VkMemoryPropertyFlags  propertyFlags;
    uint32_t               heapIndex;
}

struct VkMemoryHeap {
    VkDeviceSize       size;
    VkMemoryHeapFlags  flags;
}

struct VkPhysicalDeviceMemoryProperties {
    uint32_t                             memoryTypeCount;
    VkMemoryType[ VK_MAX_MEMORY_TYPES ]  memoryTypes;
    uint32_t                             memoryHeapCount;
    VkMemoryHeap[ VK_MAX_MEMORY_HEAPS ]  memoryHeaps;
}

struct VkDeviceQueueCreateInfo {
    VkStructureType           sType = VK_STRUCTURE_TYPE_DEVICE_QUEUE_CREATE_INFO;
    const( void )*            pNext;
    VkDeviceQueueCreateFlags  flags;
    uint32_t                  queueFamilyIndex;
    uint32_t                  queueCount;
    const( float )*           pQueuePriorities;
}

struct VkDeviceCreateInfo {
    VkStructureType                     sType = VK_STRUCTURE_TYPE_DEVICE_CREATE_INFO;
    const( void )*                      pNext;
    VkDeviceCreateFlags                 flags;
    uint32_t                            queueCreateInfoCount;
    const( VkDeviceQueueCreateInfo )*   pQueueCreateInfos;
    uint32_t                            enabledLayerCount;
    const( char* )*                     ppEnabledLayerNames;
    uint32_t                            enabledExtensionCount;
    const( char* )*                     ppEnabledExtensionNames;
    const( VkPhysicalDeviceFeatures )*  pEnabledFeatures;
}

struct VkExtensionProperties {
    char[ VK_MAX_EXTENSION_NAME_SIZE ]  extensionName;
    uint32_t                            specVersion;
}

struct VkLayerProperties {
    char[ VK_MAX_EXTENSION_NAME_SIZE ]  layerName;
    uint32_t                            specVersion;
    uint32_t                            implementationVersion;
    char[ VK_MAX_DESCRIPTION_SIZE ]     description;
}

struct VkSubmitInfo {
    VkStructureType                 sType = VK_STRUCTURE_TYPE_SUBMIT_INFO;
    const( void )*                  pNext;
    uint32_t                        waitSemaphoreCount;
    const( VkSemaphore )*           pWaitSemaphores;
    const( VkPipelineStageFlags )*  pWaitDstStageMask;
    uint32_t                        commandBufferCount;
    const( VkCommandBuffer )*       pCommandBuffers;
    uint32_t                        signalSemaphoreCount;
    const( VkSemaphore )*           pSignalSemaphores;
}

struct VkMemoryAllocateInfo {
    VkStructureType  sType = VK_STRUCTURE_TYPE_MEMORY_ALLOCATE_INFO;
    const( void )*   pNext;
    VkDeviceSize     allocationSize;
    uint32_t         memoryTypeIndex;
}

struct VkMappedMemoryRange {
    VkStructureType  sType = VK_STRUCTURE_TYPE_MAPPED_MEMORY_RANGE;
    const( void )*   pNext;
    VkDeviceMemory   memory;
    VkDeviceSize     offset;
    VkDeviceSize     size;
}

struct VkMemoryRequirements {
    VkDeviceSize  size;
    VkDeviceSize  alignment;
    uint32_t      memoryTypeBits;
}

struct VkSparseImageFormatProperties {
    VkImageAspectFlags        aspectMask;
    VkExtent3D                imageGranularity;
    VkSparseImageFormatFlags  flags;
}

struct VkSparseImageMemoryRequirements {
    VkSparseImageFormatProperties  formatProperties;
    uint32_t                       imageMipTailFirstLod;
    VkDeviceSize                   imageMipTailSize;
    VkDeviceSize                   imageMipTailOffset;
    VkDeviceSize                   imageMipTailStride;
}

struct VkSparseMemoryBind {
    VkDeviceSize             resourceOffset;
    VkDeviceSize             size;
    VkDeviceMemory           memory;
    VkDeviceSize             memoryOffset;
    VkSparseMemoryBindFlags  flags;
}

struct VkSparseBufferMemoryBindInfo {
    VkBuffer                      buffer;
    uint32_t                      bindCount;
    const( VkSparseMemoryBind )*  pBinds;
}

struct VkSparseImageOpaqueMemoryBindInfo {
    VkImage                       image;
    uint32_t                      bindCount;
    const( VkSparseMemoryBind )*  pBinds;
}

struct VkImageSubresource {
    VkImageAspectFlags  aspectMask;
    uint32_t            mipLevel;
    uint32_t            arrayLayer;
}

struct VkOffset3D {
    int32_t  x;
    int32_t  y;
    int32_t  z;
}

struct VkSparseImageMemoryBind {
    VkImageSubresource       subresource;
    VkOffset3D               offset;
    VkExtent3D               extent;
    VkDeviceMemory           memory;
    VkDeviceSize             memoryOffset;
    VkSparseMemoryBindFlags  flags;
}

struct VkSparseImageMemoryBindInfo {
    VkImage                            image;
    uint32_t                           bindCount;
    const( VkSparseImageMemoryBind )*  pBinds;
}

struct VkBindSparseInfo {
    VkStructureType                              sType = VK_STRUCTURE_TYPE_BIND_SPARSE_INFO;
    const( void )*                               pNext;
    uint32_t                                     waitSemaphoreCount;
    const( VkSemaphore )*                        pWaitSemaphores;
    uint32_t                                     bufferBindCount;
    const( VkSparseBufferMemoryBindInfo )*       pBufferBinds;
    uint32_t                                     imageOpaqueBindCount;
    const( VkSparseImageOpaqueMemoryBindInfo )*  pImageOpaqueBinds;
    uint32_t                                     imageBindCount;
    const( VkSparseImageMemoryBindInfo )*        pImageBinds;
    uint32_t                                     signalSemaphoreCount;
    const( VkSemaphore )*                        pSignalSemaphores;
}

struct VkFenceCreateInfo {
    VkStructureType     sType = VK_STRUCTURE_TYPE_FENCE_CREATE_INFO;
    const( void )*      pNext;
    VkFenceCreateFlags  flags;
}

struct VkSemaphoreCreateInfo {
    VkStructureType         sType = VK_STRUCTURE_TYPE_SEMAPHORE_CREATE_INFO;
    const( void )*          pNext;
    VkSemaphoreCreateFlags  flags;
}

struct VkEventCreateInfo {
    VkStructureType     sType = VK_STRUCTURE_TYPE_EVENT_CREATE_INFO;
    const( void )*      pNext;
    VkEventCreateFlags  flags;
}

struct VkQueryPoolCreateInfo {
    VkStructureType                sType = VK_STRUCTURE_TYPE_QUERY_POOL_CREATE_INFO;
    const( void )*                 pNext;
    VkQueryPoolCreateFlags         flags;
    VkQueryType                    queryType;
    uint32_t                       queryCount;
    VkQueryPipelineStatisticFlags  pipelineStatistics;
}

struct VkBufferCreateInfo {
    VkStructureType      sType = VK_STRUCTURE_TYPE_BUFFER_CREATE_INFO;
    const( void )*       pNext;
    VkBufferCreateFlags  flags;
    VkDeviceSize         size;
    VkBufferUsageFlags   usage;
    VkSharingMode        sharingMode;
    uint32_t             queueFamilyIndexCount;
    const( uint32_t )*   pQueueFamilyIndices;
}

struct VkBufferViewCreateInfo {
    VkStructureType          sType = VK_STRUCTURE_TYPE_BUFFER_VIEW_CREATE_INFO;
    const( void )*           pNext;
    VkBufferViewCreateFlags  flags;
    VkBuffer                 buffer;
    VkFormat                 format;
    VkDeviceSize             offset;
    VkDeviceSize             range;
}

struct VkImageCreateInfo {
    VkStructureType        sType = VK_STRUCTURE_TYPE_IMAGE_CREATE_INFO;
    const( void )*         pNext;
    VkImageCreateFlags     flags;
    VkImageType            imageType;
    VkFormat               format;
    VkExtent3D             extent;
    uint32_t               mipLevels;
    uint32_t               arrayLayers;
    VkSampleCountFlagBits  samples;
    VkImageTiling          tiling;
    VkImageUsageFlags      usage;
    VkSharingMode          sharingMode;
    uint32_t               queueFamilyIndexCount;
    const( uint32_t )*     pQueueFamilyIndices;
    VkImageLayout          initialLayout;
}

struct VkSubresourceLayout {
    VkDeviceSize  offset;
    VkDeviceSize  size;
    VkDeviceSize  rowPitch;
    VkDeviceSize  arrayPitch;
    VkDeviceSize  depthPitch;
}

struct VkComponentMapping {
    VkComponentSwizzle  r;
    VkComponentSwizzle  g;
    VkComponentSwizzle  b;
    VkComponentSwizzle  a;
}

struct VkImageSubresourceRange {
    VkImageAspectFlags  aspectMask;
    uint32_t            baseMipLevel;
    uint32_t            levelCount;
    uint32_t            baseArrayLayer;
    uint32_t            layerCount;
}

struct VkImageViewCreateInfo {
    VkStructureType          sType = VK_STRUCTURE_TYPE_IMAGE_VIEW_CREATE_INFO;
    const( void )*           pNext;
    VkImageViewCreateFlags   flags;
    VkImage                  image;
    VkImageViewType          viewType;
    VkFormat                 format;
    VkComponentMapping       components;
    VkImageSubresourceRange  subresourceRange;
}

struct VkShaderModuleCreateInfo {
    VkStructureType            sType = VK_STRUCTURE_TYPE_SHADER_MODULE_CREATE_INFO;
    const( void )*             pNext;
    VkShaderModuleCreateFlags  flags;
    size_t                     codeSize;
    const( uint32_t )*         pCode;
}

struct VkPipelineCacheCreateInfo {
    VkStructureType             sType = VK_STRUCTURE_TYPE_PIPELINE_CACHE_CREATE_INFO;
    const( void )*              pNext;
    VkPipelineCacheCreateFlags  flags;
    size_t                      initialDataSize;
    const( void )*              pInitialData;
}

struct VkSpecializationMapEntry {
    uint32_t  constantID;
    uint32_t  offset;
    size_t    size;
}

struct VkSpecializationInfo {
    uint32_t                            mapEntryCount;
    const( VkSpecializationMapEntry )*  pMapEntries;
    size_t                              dataSize;
    const( void )*                      pData;
}

struct VkPipelineShaderStageCreateInfo {
    VkStructureType                   sType = VK_STRUCTURE_TYPE_PIPELINE_SHADER_STAGE_CREATE_INFO;
    const( void )*                    pNext;
    VkPipelineShaderStageCreateFlags  flags;
    VkShaderStageFlagBits             stage;
    VkShaderModule                    _module;
    const( char )*                    pName;
    const( VkSpecializationInfo )*    pSpecializationInfo;
}

struct VkVertexInputBindingDescription {
    uint32_t           binding;
    uint32_t           stride;
    VkVertexInputRate  inputRate;
}

struct VkVertexInputAttributeDescription {
    uint32_t  location;
    uint32_t  binding;
    VkFormat  format;
    uint32_t  offset;
}

struct VkPipelineVertexInputStateCreateInfo {
    VkStructureType                              sType = VK_STRUCTURE_TYPE_PIPELINE_VERTEX_INPUT_STATE_CREATE_INFO;
    const( void )*                               pNext;
    VkPipelineVertexInputStateCreateFlags        flags;
    uint32_t                                     vertexBindingDescriptionCount;
    const( VkVertexInputBindingDescription )*    pVertexBindingDescriptions;
    uint32_t                                     vertexAttributeDescriptionCount;
    const( VkVertexInputAttributeDescription )*  pVertexAttributeDescriptions;
}

struct VkPipelineInputAssemblyStateCreateInfo {
    VkStructureType                          sType = VK_STRUCTURE_TYPE_PIPELINE_INPUT_ASSEMBLY_STATE_CREATE_INFO;
    const( void )*                           pNext;
    VkPipelineInputAssemblyStateCreateFlags  flags;
    VkPrimitiveTopology                      topology;
    VkBool32                                 primitiveRestartEnable;
}

struct VkPipelineTessellationStateCreateInfo {
    VkStructureType                         sType = VK_STRUCTURE_TYPE_PIPELINE_TESSELLATION_STATE_CREATE_INFO;
    const( void )*                          pNext;
    VkPipelineTessellationStateCreateFlags  flags;
    uint32_t                                patchControlPoints;
}

struct VkViewport {
    float  x;
    float  y;
    float  width;
    float  height;
    float  minDepth;
    float  maxDepth;
}

struct VkOffset2D {
    int32_t  x;
    int32_t  y;
}

struct VkExtent2D {
    uint32_t  width;
    uint32_t  height;
}

struct VkRect2D {
    VkOffset2D  offset;
    VkExtent2D  extent;
}

struct VkPipelineViewportStateCreateInfo {
    VkStructureType                     sType = VK_STRUCTURE_TYPE_PIPELINE_VIEWPORT_STATE_CREATE_INFO;
    const( void )*                      pNext;
    VkPipelineViewportStateCreateFlags  flags;
    uint32_t                            viewportCount;
    const( VkViewport )*                pViewports;
    uint32_t                            scissorCount;
    const( VkRect2D )*                  pScissors;
}

struct VkPipelineRasterizationStateCreateInfo {
    VkStructureType                          sType = VK_STRUCTURE_TYPE_PIPELINE_RASTERIZATION_STATE_CREATE_INFO;
    const( void )*                           pNext;
    VkPipelineRasterizationStateCreateFlags  flags;
    VkBool32                                 depthClampEnable;
    VkBool32                                 rasterizerDiscardEnable;
    VkPolygonMode                            polygonMode;
    VkCullModeFlags                          cullMode;
    VkFrontFace                              frontFace;
    VkBool32                                 depthBiasEnable;
    float                                    depthBiasConstantFactor;
    float                                    depthBiasClamp;
    float                                    depthBiasSlopeFactor;
    float                                    lineWidth;
}

struct VkPipelineMultisampleStateCreateInfo {
    VkStructureType                        sType = VK_STRUCTURE_TYPE_PIPELINE_MULTISAMPLE_STATE_CREATE_INFO;
    const( void )*                         pNext;
    VkPipelineMultisampleStateCreateFlags  flags;
    VkSampleCountFlagBits                  rasterizationSamples;
    VkBool32                               sampleShadingEnable;
    float                                  minSampleShading;
    const( VkSampleMask )*                 pSampleMask;
    VkBool32                               alphaToCoverageEnable;
    VkBool32                               alphaToOneEnable;
}

struct VkStencilOpState {
    VkStencilOp  failOp;
    VkStencilOp  passOp;
    VkStencilOp  depthFailOp;
    VkCompareOp  compareOp;
    uint32_t     compareMask;
    uint32_t     writeMask;
    uint32_t     reference;
}

struct VkPipelineDepthStencilStateCreateInfo {
    VkStructureType                         sType = VK_STRUCTURE_TYPE_PIPELINE_DEPTH_STENCIL_STATE_CREATE_INFO;
    const( void )*                          pNext;
    VkPipelineDepthStencilStateCreateFlags  flags;
    VkBool32                                depthTestEnable;
    VkBool32                                depthWriteEnable;
    VkCompareOp                             depthCompareOp;
    VkBool32                                depthBoundsTestEnable;
    VkBool32                                stencilTestEnable;
    VkStencilOpState                        front;
    VkStencilOpState                        back;
    float                                   minDepthBounds;
    float                                   maxDepthBounds;
}

struct VkPipelineColorBlendAttachmentState {
    VkBool32               blendEnable;
    VkBlendFactor          srcColorBlendFactor;
    VkBlendFactor          dstColorBlendFactor;
    VkBlendOp              colorBlendOp;
    VkBlendFactor          srcAlphaBlendFactor;
    VkBlendFactor          dstAlphaBlendFactor;
    VkBlendOp              alphaBlendOp;
    VkColorComponentFlags  colorWriteMask;
}

struct VkPipelineColorBlendStateCreateInfo {
    VkStructureType                                sType = VK_STRUCTURE_TYPE_PIPELINE_COLOR_BLEND_STATE_CREATE_INFO;
    const( void )*                                 pNext;
    VkPipelineColorBlendStateCreateFlags           flags;
    VkBool32                                       logicOpEnable;
    VkLogicOp                                      logicOp;
    uint32_t                                       attachmentCount;
    const( VkPipelineColorBlendAttachmentState )*  pAttachments;
    float[4]                                       blendConstants;
}

struct VkPipelineDynamicStateCreateInfo {
    VkStructureType                    sType = VK_STRUCTURE_TYPE_PIPELINE_DYNAMIC_STATE_CREATE_INFO;
    const( void )*                     pNext;
    VkPipelineDynamicStateCreateFlags  flags;
    uint32_t                           dynamicStateCount;
    const( VkDynamicState )*           pDynamicStates;
}

struct VkGraphicsPipelineCreateInfo {
    VkStructureType                                   sType = VK_STRUCTURE_TYPE_GRAPHICS_PIPELINE_CREATE_INFO;
    const( void )*                                    pNext;
    VkPipelineCreateFlags                             flags;
    uint32_t                                          stageCount;
    const( VkPipelineShaderStageCreateInfo )*         pStages;
    const( VkPipelineVertexInputStateCreateInfo )*    pVertexInputState;
    const( VkPipelineInputAssemblyStateCreateInfo )*  pInputAssemblyState;
    const( VkPipelineTessellationStateCreateInfo )*   pTessellationState;
    const( VkPipelineViewportStateCreateInfo )*       pViewportState;
    const( VkPipelineRasterizationStateCreateInfo )*  pRasterizationState;
    const( VkPipelineMultisampleStateCreateInfo )*    pMultisampleState;
    const( VkPipelineDepthStencilStateCreateInfo )*   pDepthStencilState;
    const( VkPipelineColorBlendStateCreateInfo )*     pColorBlendState;
    const( VkPipelineDynamicStateCreateInfo )*        pDynamicState;
    VkPipelineLayout                                  layout;
    VkRenderPass                                      renderPass;
    uint32_t                                          subpass;
    VkPipeline                                        basePipelineHandle;
    int32_t                                           basePipelineIndex;
}

struct VkComputePipelineCreateInfo {
    VkStructureType                  sType = VK_STRUCTURE_TYPE_COMPUTE_PIPELINE_CREATE_INFO;
    const( void )*                   pNext;
    VkPipelineCreateFlags            flags;
    VkPipelineShaderStageCreateInfo  stage;
    VkPipelineLayout                 layout;
    VkPipeline                       basePipelineHandle;
    int32_t                          basePipelineIndex;
}

struct VkPushConstantRange {
    VkShaderStageFlags  stageFlags;
    uint32_t            offset;
    uint32_t            size;
}

struct VkPipelineLayoutCreateInfo {
    VkStructureType                  sType = VK_STRUCTURE_TYPE_PIPELINE_LAYOUT_CREATE_INFO;
    const( void )*                   pNext;
    VkPipelineLayoutCreateFlags      flags;
    uint32_t                         setLayoutCount;
    const( VkDescriptorSetLayout )*  pSetLayouts;
    uint32_t                         pushConstantRangeCount;
    const( VkPushConstantRange )*    pPushConstantRanges;
}

struct VkSamplerCreateInfo {
    VkStructureType       sType = VK_STRUCTURE_TYPE_SAMPLER_CREATE_INFO;
    const( void )*        pNext;
    VkSamplerCreateFlags  flags;
    VkFilter              magFilter;
    VkFilter              minFilter;
    VkSamplerMipmapMode   mipmapMode;
    VkSamplerAddressMode  addressModeU;
    VkSamplerAddressMode  addressModeV;
    VkSamplerAddressMode  addressModeW;
    float                 mipLodBias;
    VkBool32              anisotropyEnable;
    float                 maxAnisotropy;
    VkBool32              compareEnable;
    VkCompareOp           compareOp;
    float                 minLod;
    float                 maxLod;
    VkBorderColor         borderColor;
    VkBool32              unnormalizedCoordinates;
}

struct VkDescriptorSetLayoutBinding {
    uint32_t             binding;
    VkDescriptorType     descriptorType;
    uint32_t             descriptorCount;
    VkShaderStageFlags   stageFlags;
    const( VkSampler )*  pImmutableSamplers;
}

struct VkDescriptorSetLayoutCreateInfo {
    VkStructureType                         sType = VK_STRUCTURE_TYPE_DESCRIPTOR_SET_LAYOUT_CREATE_INFO;
    const( void )*                          pNext;
    VkDescriptorSetLayoutCreateFlags        flags;
    uint32_t                                bindingCount;
    const( VkDescriptorSetLayoutBinding )*  pBindings;
}

struct VkDescriptorPoolSize {
    VkDescriptorType  type;
    uint32_t          descriptorCount;
}

struct VkDescriptorPoolCreateInfo {
    VkStructureType                 sType = VK_STRUCTURE_TYPE_DESCRIPTOR_POOL_CREATE_INFO;
    const( void )*                  pNext;
    VkDescriptorPoolCreateFlags     flags;
    uint32_t                        maxSets;
    uint32_t                        poolSizeCount;
    const( VkDescriptorPoolSize )*  pPoolSizes;
}

struct VkDescriptorSetAllocateInfo {
    VkStructureType                  sType = VK_STRUCTURE_TYPE_DESCRIPTOR_SET_ALLOCATE_INFO;
    const( void )*                   pNext;
    VkDescriptorPool                 descriptorPool;
    uint32_t                         descriptorSetCount;
    const( VkDescriptorSetLayout )*  pSetLayouts;
}

struct VkDescriptorImageInfo {
    VkSampler      sampler;
    VkImageView    imageView;
    VkImageLayout  imageLayout;
}

struct VkDescriptorBufferInfo {
    VkBuffer      buffer;
    VkDeviceSize  offset;
    VkDeviceSize  range;
}

struct VkWriteDescriptorSet {
    VkStructureType                   sType = VK_STRUCTURE_TYPE_WRITE_DESCRIPTOR_SET;
    const( void )*                    pNext;
    VkDescriptorSet                   dstSet;
    uint32_t                          dstBinding;
    uint32_t                          dstArrayElement;
    uint32_t                          descriptorCount;
    VkDescriptorType                  descriptorType;
    const( VkDescriptorImageInfo )*   pImageInfo;
    const( VkDescriptorBufferInfo )*  pBufferInfo;
    const( VkBufferView )*            pTexelBufferView;
}

struct VkCopyDescriptorSet {
    VkStructureType  sType = VK_STRUCTURE_TYPE_COPY_DESCRIPTOR_SET;
    const( void )*   pNext;
    VkDescriptorSet  srcSet;
    uint32_t         srcBinding;
    uint32_t         srcArrayElement;
    VkDescriptorSet  dstSet;
    uint32_t         dstBinding;
    uint32_t         dstArrayElement;
    uint32_t         descriptorCount;
}

struct VkFramebufferCreateInfo {
    VkStructureType           sType = VK_STRUCTURE_TYPE_FRAMEBUFFER_CREATE_INFO;
    const( void )*            pNext;
    VkFramebufferCreateFlags  flags;
    VkRenderPass              renderPass;
    uint32_t                  attachmentCount;
    const( VkImageView )*     pAttachments;
    uint32_t                  width;
    uint32_t                  height;
    uint32_t                  layers;
}

struct VkAttachmentDescription {
    VkAttachmentDescriptionFlags  flags;
    VkFormat                      format;
    VkSampleCountFlagBits         samples;
    VkAttachmentLoadOp            loadOp;
    VkAttachmentStoreOp           storeOp;
    VkAttachmentLoadOp            stencilLoadOp;
    VkAttachmentStoreOp           stencilStoreOp;
    VkImageLayout                 initialLayout;
    VkImageLayout                 finalLayout;
}

struct VkAttachmentReference {
    uint32_t       attachment;
    VkImageLayout  layout;
}

struct VkSubpassDescription {
    VkSubpassDescriptionFlags        flags;
    VkPipelineBindPoint              pipelineBindPoint;
    uint32_t                         inputAttachmentCount;
    const( VkAttachmentReference )*  pInputAttachments;
    uint32_t                         colorAttachmentCount;
    const( VkAttachmentReference )*  pColorAttachments;
    const( VkAttachmentReference )*  pResolveAttachments;
    const( VkAttachmentReference )*  pDepthStencilAttachment;
    uint32_t                         preserveAttachmentCount;
    const( uint32_t )*               pPreserveAttachments;
}

struct VkSubpassDependency {
    uint32_t              srcSubpass;
    uint32_t              dstSubpass;
    VkPipelineStageFlags  srcStageMask;
    VkPipelineStageFlags  dstStageMask;
    VkAccessFlags         srcAccessMask;
    VkAccessFlags         dstAccessMask;
    VkDependencyFlags     dependencyFlags;
}

struct VkRenderPassCreateInfo {
    VkStructureType                    sType = VK_STRUCTURE_TYPE_RENDER_PASS_CREATE_INFO;
    const( void )*                     pNext;
    VkRenderPassCreateFlags            flags;
    uint32_t                           attachmentCount;
    const( VkAttachmentDescription )*  pAttachments;
    uint32_t                           subpassCount;
    const( VkSubpassDescription )*     pSubpasses;
    uint32_t                           dependencyCount;
    const( VkSubpassDependency )*      pDependencies;
}

struct VkCommandPoolCreateInfo {
    VkStructureType           sType = VK_STRUCTURE_TYPE_COMMAND_POOL_CREATE_INFO;
    const( void )*            pNext;
    VkCommandPoolCreateFlags  flags;
    uint32_t                  queueFamilyIndex;
}

struct VkCommandBufferAllocateInfo {
    VkStructureType       sType = VK_STRUCTURE_TYPE_COMMAND_BUFFER_ALLOCATE_INFO;
    const( void )*        pNext;
    VkCommandPool         commandPool;
    VkCommandBufferLevel  level;
    uint32_t              commandBufferCount;
}

struct VkCommandBufferInheritanceInfo {
    VkStructureType                sType = VK_STRUCTURE_TYPE_COMMAND_BUFFER_INHERITANCE_INFO;
    const( void )*                 pNext;
    VkRenderPass                   renderPass;
    uint32_t                       subpass;
    VkFramebuffer                  framebuffer;
    VkBool32                       occlusionQueryEnable;
    VkQueryControlFlags            queryFlags;
    VkQueryPipelineStatisticFlags  pipelineStatistics;
}

struct VkCommandBufferBeginInfo {
    VkStructureType                           sType = VK_STRUCTURE_TYPE_COMMAND_BUFFER_BEGIN_INFO;
    const( void )*                            pNext;
    VkCommandBufferUsageFlags                 flags;
    const( VkCommandBufferInheritanceInfo )*  pInheritanceInfo;
}

struct VkBufferCopy {
    VkDeviceSize  srcOffset;
    VkDeviceSize  dstOffset;
    VkDeviceSize  size;
}

struct VkImageSubresourceLayers {
    VkImageAspectFlags  aspectMask;
    uint32_t            mipLevel;
    uint32_t            baseArrayLayer;
    uint32_t            layerCount;
}

struct VkImageCopy {
    VkImageSubresourceLayers  srcSubresource;
    VkOffset3D                srcOffset;
    VkImageSubresourceLayers  dstSubresource;
    VkOffset3D                dstOffset;
    VkExtent3D                extent;
}

struct VkImageBlit {
    VkImageSubresourceLayers  srcSubresource;
    VkOffset3D[2]             srcOffsets;
    VkImageSubresourceLayers  dstSubresource;
    VkOffset3D[2]             dstOffsets;
}

struct VkBufferImageCopy {
    VkDeviceSize              bufferOffset;
    uint32_t                  bufferRowLength;
    uint32_t                  bufferImageHeight;
    VkImageSubresourceLayers  imageSubresource;
    VkOffset3D                imageOffset;
    VkExtent3D                imageExtent;
}

union VkClearColorValue {
    float[4]     float32;
    int32_t[4]   int32;
    uint32_t[4]  uint32;
}

struct VkClearDepthStencilValue {
    float     depth;
    uint32_t  stencil;
}

union VkClearValue {
    VkClearColorValue         color;
    VkClearDepthStencilValue  depthStencil;
}

struct VkClearAttachment {
    VkImageAspectFlags  aspectMask;
    uint32_t            colorAttachment;
    VkClearValue        clearValue;
}

struct VkClearRect {
    VkRect2D  rect;
    uint32_t  baseArrayLayer;
    uint32_t  layerCount;
}

struct VkImageResolve {
    VkImageSubresourceLayers  srcSubresource;
    VkOffset3D                srcOffset;
    VkImageSubresourceLayers  dstSubresource;
    VkOffset3D                dstOffset;
    VkExtent3D                extent;
}

struct VkMemoryBarrier {
    VkStructureType  sType = VK_STRUCTURE_TYPE_MEMORY_BARRIER;
    const( void )*   pNext;
    VkAccessFlags    srcAccessMask;
    VkAccessFlags    dstAccessMask;
}

struct VkBufferMemoryBarrier {
    VkStructureType  sType = VK_STRUCTURE_TYPE_BUFFER_MEMORY_BARRIER;
    const( void )*   pNext;
    VkAccessFlags    srcAccessMask;
    VkAccessFlags    dstAccessMask;
    uint32_t         srcQueueFamilyIndex;
    uint32_t         dstQueueFamilyIndex;
    VkBuffer         buffer;
    VkDeviceSize     offset;
    VkDeviceSize     size;
}

struct VkImageMemoryBarrier {
    VkStructureType          sType = VK_STRUCTURE_TYPE_IMAGE_MEMORY_BARRIER;
    const( void )*           pNext;
    VkAccessFlags            srcAccessMask;
    VkAccessFlags            dstAccessMask;
    VkImageLayout            oldLayout;
    VkImageLayout            newLayout;
    uint32_t                 srcQueueFamilyIndex;
    uint32_t                 dstQueueFamilyIndex;
    VkImage                  image;
    VkImageSubresourceRange  subresourceRange;
}

struct VkRenderPassBeginInfo {
    VkStructureType         sType = VK_STRUCTURE_TYPE_RENDER_PASS_BEGIN_INFO;
    const( void )*          pNext;
    VkRenderPass            renderPass;
    VkFramebuffer           framebuffer;
    VkRect2D                renderArea;
    uint32_t                clearValueCount;
    const( VkClearValue )*  pClearValues;
}

struct VkDispatchIndirectCommand {
    uint32_t  x;
    uint32_t  y;
    uint32_t  z;
}

struct VkDrawIndexedIndirectCommand {
    uint32_t  indexCount;
    uint32_t  instanceCount;
    uint32_t  firstIndex;
    int32_t   vertexOffset;
    uint32_t  firstInstance;
}

struct VkDrawIndirectCommand {
    uint32_t  vertexCount;
    uint32_t  instanceCount;
    uint32_t  firstVertex;
    uint32_t  firstInstance;
}

struct VkBaseOutStructure {
    VkStructureType               sType;
    const( VkBaseOutStructure )*  pNext;
}

struct VkBaseInStructure {
    VkStructureType              sType;
    const( VkBaseInStructure )*  pNext;
}


// - VK_VERSION_1_1 -
enum VK_VERSION_1_1 = 1;

// Vulkan 1.1 version number
enum VK_API_VERSION_1_1 = VK_MAKE_VERSION( 1, 1, 0 );  // Patch version should always be set to 0

mixin( VK_DEFINE_NON_DISPATCHABLE_HANDLE!q{VkSamplerYcbcrConversion} );
mixin( VK_DEFINE_NON_DISPATCHABLE_HANDLE!q{VkDescriptorUpdateTemplate} );

enum VK_MAX_DEVICE_GROUP_SIZE = 32;
enum VK_LUID_SIZE = 8;
enum VK_QUEUE_FAMILY_EXTERNAL = (~0U-1);

enum VkPointClippingBehavior {
    VK_POINT_CLIPPING_BEHAVIOR_ALL_CLIP_PLANES                   = 0,
    VK_POINT_CLIPPING_BEHAVIOR_USER_CLIP_PLANES_ONLY             = 1,
    VK_POINT_CLIPPING_BEHAVIOR_ALL_CLIP_PLANES_KHR               = VK_POINT_CLIPPING_BEHAVIOR_ALL_CLIP_PLANES,
    VK_POINT_CLIPPING_BEHAVIOR_USER_CLIP_PLANES_ONLY_KHR         = VK_POINT_CLIPPING_BEHAVIOR_USER_CLIP_PLANES_ONLY,
    VK_POINT_CLIPPING_BEHAVIOR_BEGIN_RANGE                       = VK_POINT_CLIPPING_BEHAVIOR_ALL_CLIP_PLANES,
    VK_POINT_CLIPPING_BEHAVIOR_END_RANGE                         = VK_POINT_CLIPPING_BEHAVIOR_USER_CLIP_PLANES_ONLY,
    VK_POINT_CLIPPING_BEHAVIOR_RANGE_SIZE                        = VK_POINT_CLIPPING_BEHAVIOR_USER_CLIP_PLANES_ONLY - VK_POINT_CLIPPING_BEHAVIOR_ALL_CLIP_PLANES + 1,
    VK_POINT_CLIPPING_BEHAVIOR_MAX_ENUM                          = 0x7FFFFFFF
}

enum VK_POINT_CLIPPING_BEHAVIOR_ALL_CLIP_PLANES                  = VkPointClippingBehavior.VK_POINT_CLIPPING_BEHAVIOR_ALL_CLIP_PLANES;
enum VK_POINT_CLIPPING_BEHAVIOR_USER_CLIP_PLANES_ONLY            = VkPointClippingBehavior.VK_POINT_CLIPPING_BEHAVIOR_USER_CLIP_PLANES_ONLY;
enum VK_POINT_CLIPPING_BEHAVIOR_ALL_CLIP_PLANES_KHR              = VkPointClippingBehavior.VK_POINT_CLIPPING_BEHAVIOR_ALL_CLIP_PLANES_KHR;
enum VK_POINT_CLIPPING_BEHAVIOR_USER_CLIP_PLANES_ONLY_KHR        = VkPointClippingBehavior.VK_POINT_CLIPPING_BEHAVIOR_USER_CLIP_PLANES_ONLY_KHR;
enum VK_POINT_CLIPPING_BEHAVIOR_BEGIN_RANGE                      = VkPointClippingBehavior.VK_POINT_CLIPPING_BEHAVIOR_BEGIN_RANGE;
enum VK_POINT_CLIPPING_BEHAVIOR_END_RANGE                        = VkPointClippingBehavior.VK_POINT_CLIPPING_BEHAVIOR_END_RANGE;
enum VK_POINT_CLIPPING_BEHAVIOR_RANGE_SIZE                       = VkPointClippingBehavior.VK_POINT_CLIPPING_BEHAVIOR_RANGE_SIZE;
enum VK_POINT_CLIPPING_BEHAVIOR_MAX_ENUM                         = VkPointClippingBehavior.VK_POINT_CLIPPING_BEHAVIOR_MAX_ENUM;

enum VkTessellationDomainOrigin {
    VK_TESSELLATION_DOMAIN_ORIGIN_UPPER_LEFT             = 0,
    VK_TESSELLATION_DOMAIN_ORIGIN_LOWER_LEFT             = 1,
    VK_TESSELLATION_DOMAIN_ORIGIN_UPPER_LEFT_KHR         = VK_TESSELLATION_DOMAIN_ORIGIN_UPPER_LEFT,
    VK_TESSELLATION_DOMAIN_ORIGIN_LOWER_LEFT_KHR         = VK_TESSELLATION_DOMAIN_ORIGIN_LOWER_LEFT,
    VK_TESSELLATION_DOMAIN_ORIGIN_BEGIN_RANGE            = VK_TESSELLATION_DOMAIN_ORIGIN_UPPER_LEFT,
    VK_TESSELLATION_DOMAIN_ORIGIN_END_RANGE              = VK_TESSELLATION_DOMAIN_ORIGIN_LOWER_LEFT,
    VK_TESSELLATION_DOMAIN_ORIGIN_RANGE_SIZE             = VK_TESSELLATION_DOMAIN_ORIGIN_LOWER_LEFT - VK_TESSELLATION_DOMAIN_ORIGIN_UPPER_LEFT + 1,
    VK_TESSELLATION_DOMAIN_ORIGIN_MAX_ENUM               = 0x7FFFFFFF
}

enum VK_TESSELLATION_DOMAIN_ORIGIN_UPPER_LEFT            = VkTessellationDomainOrigin.VK_TESSELLATION_DOMAIN_ORIGIN_UPPER_LEFT;
enum VK_TESSELLATION_DOMAIN_ORIGIN_LOWER_LEFT            = VkTessellationDomainOrigin.VK_TESSELLATION_DOMAIN_ORIGIN_LOWER_LEFT;
enum VK_TESSELLATION_DOMAIN_ORIGIN_UPPER_LEFT_KHR        = VkTessellationDomainOrigin.VK_TESSELLATION_DOMAIN_ORIGIN_UPPER_LEFT_KHR;
enum VK_TESSELLATION_DOMAIN_ORIGIN_LOWER_LEFT_KHR        = VkTessellationDomainOrigin.VK_TESSELLATION_DOMAIN_ORIGIN_LOWER_LEFT_KHR;
enum VK_TESSELLATION_DOMAIN_ORIGIN_BEGIN_RANGE           = VkTessellationDomainOrigin.VK_TESSELLATION_DOMAIN_ORIGIN_BEGIN_RANGE;
enum VK_TESSELLATION_DOMAIN_ORIGIN_END_RANGE             = VkTessellationDomainOrigin.VK_TESSELLATION_DOMAIN_ORIGIN_END_RANGE;
enum VK_TESSELLATION_DOMAIN_ORIGIN_RANGE_SIZE            = VkTessellationDomainOrigin.VK_TESSELLATION_DOMAIN_ORIGIN_RANGE_SIZE;
enum VK_TESSELLATION_DOMAIN_ORIGIN_MAX_ENUM              = VkTessellationDomainOrigin.VK_TESSELLATION_DOMAIN_ORIGIN_MAX_ENUM;

enum VkSamplerYcbcrModelConversion {
    VK_SAMPLER_YCBCR_MODEL_CONVERSION_RGB_IDENTITY               = 0,
    VK_SAMPLER_YCBCR_MODEL_CONVERSION_YCBCR_IDENTITY             = 1,
    VK_SAMPLER_YCBCR_MODEL_CONVERSION_YCBCR_709                  = 2,
    VK_SAMPLER_YCBCR_MODEL_CONVERSION_YCBCR_601                  = 3,
    VK_SAMPLER_YCBCR_MODEL_CONVERSION_YCBCR_2020                 = 4,
    VK_SAMPLER_YCBCR_MODEL_CONVERSION_RGB_IDENTITY_KHR           = VK_SAMPLER_YCBCR_MODEL_CONVERSION_RGB_IDENTITY,
    VK_SAMPLER_YCBCR_MODEL_CONVERSION_YCBCR_IDENTITY_KHR         = VK_SAMPLER_YCBCR_MODEL_CONVERSION_YCBCR_IDENTITY,
    VK_SAMPLER_YCBCR_MODEL_CONVERSION_YCBCR_709_KHR              = VK_SAMPLER_YCBCR_MODEL_CONVERSION_YCBCR_709,
    VK_SAMPLER_YCBCR_MODEL_CONVERSION_YCBCR_601_KHR              = VK_SAMPLER_YCBCR_MODEL_CONVERSION_YCBCR_601,
    VK_SAMPLER_YCBCR_MODEL_CONVERSION_YCBCR_2020_KHR             = VK_SAMPLER_YCBCR_MODEL_CONVERSION_YCBCR_2020,
    VK_SAMPLER_YCBCR_MODEL_CONVERSION_BEGIN_RANGE                = VK_SAMPLER_YCBCR_MODEL_CONVERSION_RGB_IDENTITY,
    VK_SAMPLER_YCBCR_MODEL_CONVERSION_END_RANGE                  = VK_SAMPLER_YCBCR_MODEL_CONVERSION_YCBCR_2020,
    VK_SAMPLER_YCBCR_MODEL_CONVERSION_RANGE_SIZE                 = VK_SAMPLER_YCBCR_MODEL_CONVERSION_YCBCR_2020 - VK_SAMPLER_YCBCR_MODEL_CONVERSION_RGB_IDENTITY + 1,
    VK_SAMPLER_YCBCR_MODEL_CONVERSION_MAX_ENUM                   = 0x7FFFFFFF
}

enum VK_SAMPLER_YCBCR_MODEL_CONVERSION_RGB_IDENTITY              = VkSamplerYcbcrModelConversion.VK_SAMPLER_YCBCR_MODEL_CONVERSION_RGB_IDENTITY;
enum VK_SAMPLER_YCBCR_MODEL_CONVERSION_YCBCR_IDENTITY            = VkSamplerYcbcrModelConversion.VK_SAMPLER_YCBCR_MODEL_CONVERSION_YCBCR_IDENTITY;
enum VK_SAMPLER_YCBCR_MODEL_CONVERSION_YCBCR_709                 = VkSamplerYcbcrModelConversion.VK_SAMPLER_YCBCR_MODEL_CONVERSION_YCBCR_709;
enum VK_SAMPLER_YCBCR_MODEL_CONVERSION_YCBCR_601                 = VkSamplerYcbcrModelConversion.VK_SAMPLER_YCBCR_MODEL_CONVERSION_YCBCR_601;
enum VK_SAMPLER_YCBCR_MODEL_CONVERSION_YCBCR_2020                = VkSamplerYcbcrModelConversion.VK_SAMPLER_YCBCR_MODEL_CONVERSION_YCBCR_2020;
enum VK_SAMPLER_YCBCR_MODEL_CONVERSION_RGB_IDENTITY_KHR          = VkSamplerYcbcrModelConversion.VK_SAMPLER_YCBCR_MODEL_CONVERSION_RGB_IDENTITY_KHR;
enum VK_SAMPLER_YCBCR_MODEL_CONVERSION_YCBCR_IDENTITY_KHR        = VkSamplerYcbcrModelConversion.VK_SAMPLER_YCBCR_MODEL_CONVERSION_YCBCR_IDENTITY_KHR;
enum VK_SAMPLER_YCBCR_MODEL_CONVERSION_YCBCR_709_KHR             = VkSamplerYcbcrModelConversion.VK_SAMPLER_YCBCR_MODEL_CONVERSION_YCBCR_709_KHR;
enum VK_SAMPLER_YCBCR_MODEL_CONVERSION_YCBCR_601_KHR             = VkSamplerYcbcrModelConversion.VK_SAMPLER_YCBCR_MODEL_CONVERSION_YCBCR_601_KHR;
enum VK_SAMPLER_YCBCR_MODEL_CONVERSION_YCBCR_2020_KHR            = VkSamplerYcbcrModelConversion.VK_SAMPLER_YCBCR_MODEL_CONVERSION_YCBCR_2020_KHR;
enum VK_SAMPLER_YCBCR_MODEL_CONVERSION_BEGIN_RANGE               = VkSamplerYcbcrModelConversion.VK_SAMPLER_YCBCR_MODEL_CONVERSION_BEGIN_RANGE;
enum VK_SAMPLER_YCBCR_MODEL_CONVERSION_END_RANGE                 = VkSamplerYcbcrModelConversion.VK_SAMPLER_YCBCR_MODEL_CONVERSION_END_RANGE;
enum VK_SAMPLER_YCBCR_MODEL_CONVERSION_RANGE_SIZE                = VkSamplerYcbcrModelConversion.VK_SAMPLER_YCBCR_MODEL_CONVERSION_RANGE_SIZE;
enum VK_SAMPLER_YCBCR_MODEL_CONVERSION_MAX_ENUM                  = VkSamplerYcbcrModelConversion.VK_SAMPLER_YCBCR_MODEL_CONVERSION_MAX_ENUM;

enum VkSamplerYcbcrRange {
    VK_SAMPLER_YCBCR_RANGE_ITU_FULL              = 0,
    VK_SAMPLER_YCBCR_RANGE_ITU_NARROW            = 1,
    VK_SAMPLER_YCBCR_RANGE_ITU_FULL_KHR          = VK_SAMPLER_YCBCR_RANGE_ITU_FULL,
    VK_SAMPLER_YCBCR_RANGE_ITU_NARROW_KHR        = VK_SAMPLER_YCBCR_RANGE_ITU_NARROW,
    VK_SAMPLER_YCBCR_RANGE_BEGIN_RANGE           = VK_SAMPLER_YCBCR_RANGE_ITU_FULL,
    VK_SAMPLER_YCBCR_RANGE_END_RANGE             = VK_SAMPLER_YCBCR_RANGE_ITU_NARROW,
    VK_SAMPLER_YCBCR_RANGE_RANGE_SIZE            = VK_SAMPLER_YCBCR_RANGE_ITU_NARROW - VK_SAMPLER_YCBCR_RANGE_ITU_FULL + 1,
    VK_SAMPLER_YCBCR_RANGE_MAX_ENUM              = 0x7FFFFFFF
}

enum VK_SAMPLER_YCBCR_RANGE_ITU_FULL             = VkSamplerYcbcrRange.VK_SAMPLER_YCBCR_RANGE_ITU_FULL;
enum VK_SAMPLER_YCBCR_RANGE_ITU_NARROW           = VkSamplerYcbcrRange.VK_SAMPLER_YCBCR_RANGE_ITU_NARROW;
enum VK_SAMPLER_YCBCR_RANGE_ITU_FULL_KHR         = VkSamplerYcbcrRange.VK_SAMPLER_YCBCR_RANGE_ITU_FULL_KHR;
enum VK_SAMPLER_YCBCR_RANGE_ITU_NARROW_KHR       = VkSamplerYcbcrRange.VK_SAMPLER_YCBCR_RANGE_ITU_NARROW_KHR;
enum VK_SAMPLER_YCBCR_RANGE_BEGIN_RANGE          = VkSamplerYcbcrRange.VK_SAMPLER_YCBCR_RANGE_BEGIN_RANGE;
enum VK_SAMPLER_YCBCR_RANGE_END_RANGE            = VkSamplerYcbcrRange.VK_SAMPLER_YCBCR_RANGE_END_RANGE;
enum VK_SAMPLER_YCBCR_RANGE_RANGE_SIZE           = VkSamplerYcbcrRange.VK_SAMPLER_YCBCR_RANGE_RANGE_SIZE;
enum VK_SAMPLER_YCBCR_RANGE_MAX_ENUM             = VkSamplerYcbcrRange.VK_SAMPLER_YCBCR_RANGE_MAX_ENUM;

enum VkChromaLocation {
    VK_CHROMA_LOCATION_COSITED_EVEN      = 0,
    VK_CHROMA_LOCATION_MIDPOINT          = 1,
    VK_CHROMA_LOCATION_COSITED_EVEN_KHR  = VK_CHROMA_LOCATION_COSITED_EVEN,
    VK_CHROMA_LOCATION_MIDPOINT_KHR      = VK_CHROMA_LOCATION_MIDPOINT,
    VK_CHROMA_LOCATION_BEGIN_RANGE       = VK_CHROMA_LOCATION_COSITED_EVEN,
    VK_CHROMA_LOCATION_END_RANGE         = VK_CHROMA_LOCATION_MIDPOINT,
    VK_CHROMA_LOCATION_RANGE_SIZE        = VK_CHROMA_LOCATION_MIDPOINT - VK_CHROMA_LOCATION_COSITED_EVEN + 1,
    VK_CHROMA_LOCATION_MAX_ENUM          = 0x7FFFFFFF
}

enum VK_CHROMA_LOCATION_COSITED_EVEN     = VkChromaLocation.VK_CHROMA_LOCATION_COSITED_EVEN;
enum VK_CHROMA_LOCATION_MIDPOINT         = VkChromaLocation.VK_CHROMA_LOCATION_MIDPOINT;
enum VK_CHROMA_LOCATION_COSITED_EVEN_KHR = VkChromaLocation.VK_CHROMA_LOCATION_COSITED_EVEN_KHR;
enum VK_CHROMA_LOCATION_MIDPOINT_KHR     = VkChromaLocation.VK_CHROMA_LOCATION_MIDPOINT_KHR;
enum VK_CHROMA_LOCATION_BEGIN_RANGE      = VkChromaLocation.VK_CHROMA_LOCATION_BEGIN_RANGE;
enum VK_CHROMA_LOCATION_END_RANGE        = VkChromaLocation.VK_CHROMA_LOCATION_END_RANGE;
enum VK_CHROMA_LOCATION_RANGE_SIZE       = VkChromaLocation.VK_CHROMA_LOCATION_RANGE_SIZE;
enum VK_CHROMA_LOCATION_MAX_ENUM         = VkChromaLocation.VK_CHROMA_LOCATION_MAX_ENUM;

enum VkDescriptorUpdateTemplateType {
    VK_DESCRIPTOR_UPDATE_TEMPLATE_TYPE_DESCRIPTOR_SET            = 0,
    VK_DESCRIPTOR_UPDATE_TEMPLATE_TYPE_PUSH_DESCRIPTORS_KHR      = 1,
    VK_DESCRIPTOR_UPDATE_TEMPLATE_TYPE_DESCRIPTOR_SET_KHR        = VK_DESCRIPTOR_UPDATE_TEMPLATE_TYPE_DESCRIPTOR_SET,
    VK_DESCRIPTOR_UPDATE_TEMPLATE_TYPE_BEGIN_RANGE               = VK_DESCRIPTOR_UPDATE_TEMPLATE_TYPE_DESCRIPTOR_SET,
    VK_DESCRIPTOR_UPDATE_TEMPLATE_TYPE_END_RANGE                 = VK_DESCRIPTOR_UPDATE_TEMPLATE_TYPE_DESCRIPTOR_SET,
    VK_DESCRIPTOR_UPDATE_TEMPLATE_TYPE_RANGE_SIZE                = VK_DESCRIPTOR_UPDATE_TEMPLATE_TYPE_DESCRIPTOR_SET - VK_DESCRIPTOR_UPDATE_TEMPLATE_TYPE_DESCRIPTOR_SET + 1,
    VK_DESCRIPTOR_UPDATE_TEMPLATE_TYPE_MAX_ENUM                  = 0x7FFFFFFF
}

enum VK_DESCRIPTOR_UPDATE_TEMPLATE_TYPE_DESCRIPTOR_SET           = VkDescriptorUpdateTemplateType.VK_DESCRIPTOR_UPDATE_TEMPLATE_TYPE_DESCRIPTOR_SET;
enum VK_DESCRIPTOR_UPDATE_TEMPLATE_TYPE_PUSH_DESCRIPTORS_KHR     = VkDescriptorUpdateTemplateType.VK_DESCRIPTOR_UPDATE_TEMPLATE_TYPE_PUSH_DESCRIPTORS_KHR;
enum VK_DESCRIPTOR_UPDATE_TEMPLATE_TYPE_DESCRIPTOR_SET_KHR       = VkDescriptorUpdateTemplateType.VK_DESCRIPTOR_UPDATE_TEMPLATE_TYPE_DESCRIPTOR_SET_KHR;
enum VK_DESCRIPTOR_UPDATE_TEMPLATE_TYPE_BEGIN_RANGE              = VkDescriptorUpdateTemplateType.VK_DESCRIPTOR_UPDATE_TEMPLATE_TYPE_BEGIN_RANGE;
enum VK_DESCRIPTOR_UPDATE_TEMPLATE_TYPE_END_RANGE                = VkDescriptorUpdateTemplateType.VK_DESCRIPTOR_UPDATE_TEMPLATE_TYPE_END_RANGE;
enum VK_DESCRIPTOR_UPDATE_TEMPLATE_TYPE_RANGE_SIZE               = VkDescriptorUpdateTemplateType.VK_DESCRIPTOR_UPDATE_TEMPLATE_TYPE_RANGE_SIZE;
enum VK_DESCRIPTOR_UPDATE_TEMPLATE_TYPE_MAX_ENUM                 = VkDescriptorUpdateTemplateType.VK_DESCRIPTOR_UPDATE_TEMPLATE_TYPE_MAX_ENUM;

enum VkSubgroupFeatureFlagBits {
    VK_SUBGROUP_FEATURE_BASIC_BIT                = 0x00000001,
    VK_SUBGROUP_FEATURE_VOTE_BIT                 = 0x00000002,
    VK_SUBGROUP_FEATURE_ARITHMETIC_BIT           = 0x00000004,
    VK_SUBGROUP_FEATURE_BALLOT_BIT               = 0x00000008,
    VK_SUBGROUP_FEATURE_SHUFFLE_BIT              = 0x00000010,
    VK_SUBGROUP_FEATURE_SHUFFLE_RELATIVE_BIT     = 0x00000020,
    VK_SUBGROUP_FEATURE_CLUSTERED_BIT            = 0x00000040,
    VK_SUBGROUP_FEATURE_QUAD_BIT                 = 0x00000080,
    VK_SUBGROUP_FEATURE_PARTITIONED_BIT_NV       = 0x00000100,
    VK_SUBGROUP_FEATURE_FLAG_BITS_MAX_ENUM       = 0x7FFFFFFF
}

enum VK_SUBGROUP_FEATURE_BASIC_BIT               = VkSubgroupFeatureFlagBits.VK_SUBGROUP_FEATURE_BASIC_BIT;
enum VK_SUBGROUP_FEATURE_VOTE_BIT                = VkSubgroupFeatureFlagBits.VK_SUBGROUP_FEATURE_VOTE_BIT;
enum VK_SUBGROUP_FEATURE_ARITHMETIC_BIT          = VkSubgroupFeatureFlagBits.VK_SUBGROUP_FEATURE_ARITHMETIC_BIT;
enum VK_SUBGROUP_FEATURE_BALLOT_BIT              = VkSubgroupFeatureFlagBits.VK_SUBGROUP_FEATURE_BALLOT_BIT;
enum VK_SUBGROUP_FEATURE_SHUFFLE_BIT             = VkSubgroupFeatureFlagBits.VK_SUBGROUP_FEATURE_SHUFFLE_BIT;
enum VK_SUBGROUP_FEATURE_SHUFFLE_RELATIVE_BIT    = VkSubgroupFeatureFlagBits.VK_SUBGROUP_FEATURE_SHUFFLE_RELATIVE_BIT;
enum VK_SUBGROUP_FEATURE_CLUSTERED_BIT           = VkSubgroupFeatureFlagBits.VK_SUBGROUP_FEATURE_CLUSTERED_BIT;
enum VK_SUBGROUP_FEATURE_QUAD_BIT                = VkSubgroupFeatureFlagBits.VK_SUBGROUP_FEATURE_QUAD_BIT;
enum VK_SUBGROUP_FEATURE_PARTITIONED_BIT_NV      = VkSubgroupFeatureFlagBits.VK_SUBGROUP_FEATURE_PARTITIONED_BIT_NV;
enum VK_SUBGROUP_FEATURE_FLAG_BITS_MAX_ENUM      = VkSubgroupFeatureFlagBits.VK_SUBGROUP_FEATURE_FLAG_BITS_MAX_ENUM;
alias VkSubgroupFeatureFlags = VkFlags;

enum VkPeerMemoryFeatureFlagBits {
    VK_PEER_MEMORY_FEATURE_COPY_SRC_BIT                  = 0x00000001,
    VK_PEER_MEMORY_FEATURE_COPY_DST_BIT                  = 0x00000002,
    VK_PEER_MEMORY_FEATURE_GENERIC_SRC_BIT               = 0x00000004,
    VK_PEER_MEMORY_FEATURE_GENERIC_DST_BIT               = 0x00000008,
    VK_PEER_MEMORY_FEATURE_COPY_SRC_BIT_KHR              = VK_PEER_MEMORY_FEATURE_COPY_SRC_BIT,
    VK_PEER_MEMORY_FEATURE_COPY_DST_BIT_KHR              = VK_PEER_MEMORY_FEATURE_COPY_DST_BIT,
    VK_PEER_MEMORY_FEATURE_GENERIC_SRC_BIT_KHR           = VK_PEER_MEMORY_FEATURE_GENERIC_SRC_BIT,
    VK_PEER_MEMORY_FEATURE_GENERIC_DST_BIT_KHR           = VK_PEER_MEMORY_FEATURE_GENERIC_DST_BIT,
    VK_PEER_MEMORY_FEATURE_FLAG_BITS_MAX_ENUM            = 0x7FFFFFFF
}

enum VK_PEER_MEMORY_FEATURE_COPY_SRC_BIT                 = VkPeerMemoryFeatureFlagBits.VK_PEER_MEMORY_FEATURE_COPY_SRC_BIT;
enum VK_PEER_MEMORY_FEATURE_COPY_DST_BIT                 = VkPeerMemoryFeatureFlagBits.VK_PEER_MEMORY_FEATURE_COPY_DST_BIT;
enum VK_PEER_MEMORY_FEATURE_GENERIC_SRC_BIT              = VkPeerMemoryFeatureFlagBits.VK_PEER_MEMORY_FEATURE_GENERIC_SRC_BIT;
enum VK_PEER_MEMORY_FEATURE_GENERIC_DST_BIT              = VkPeerMemoryFeatureFlagBits.VK_PEER_MEMORY_FEATURE_GENERIC_DST_BIT;
enum VK_PEER_MEMORY_FEATURE_COPY_SRC_BIT_KHR             = VkPeerMemoryFeatureFlagBits.VK_PEER_MEMORY_FEATURE_COPY_SRC_BIT_KHR;
enum VK_PEER_MEMORY_FEATURE_COPY_DST_BIT_KHR             = VkPeerMemoryFeatureFlagBits.VK_PEER_MEMORY_FEATURE_COPY_DST_BIT_KHR;
enum VK_PEER_MEMORY_FEATURE_GENERIC_SRC_BIT_KHR          = VkPeerMemoryFeatureFlagBits.VK_PEER_MEMORY_FEATURE_GENERIC_SRC_BIT_KHR;
enum VK_PEER_MEMORY_FEATURE_GENERIC_DST_BIT_KHR          = VkPeerMemoryFeatureFlagBits.VK_PEER_MEMORY_FEATURE_GENERIC_DST_BIT_KHR;
enum VK_PEER_MEMORY_FEATURE_FLAG_BITS_MAX_ENUM           = VkPeerMemoryFeatureFlagBits.VK_PEER_MEMORY_FEATURE_FLAG_BITS_MAX_ENUM;
alias VkPeerMemoryFeatureFlags = VkFlags;

enum VkMemoryAllocateFlagBits {
    VK_MEMORY_ALLOCATE_DEVICE_MASK_BIT           = 0x00000001,
    VK_MEMORY_ALLOCATE_DEVICE_MASK_BIT_KHR       = VK_MEMORY_ALLOCATE_DEVICE_MASK_BIT,
    VK_MEMORY_ALLOCATE_FLAG_BITS_MAX_ENUM        = 0x7FFFFFFF
}

enum VK_MEMORY_ALLOCATE_DEVICE_MASK_BIT          = VkMemoryAllocateFlagBits.VK_MEMORY_ALLOCATE_DEVICE_MASK_BIT;
enum VK_MEMORY_ALLOCATE_DEVICE_MASK_BIT_KHR      = VkMemoryAllocateFlagBits.VK_MEMORY_ALLOCATE_DEVICE_MASK_BIT_KHR;
enum VK_MEMORY_ALLOCATE_FLAG_BITS_MAX_ENUM       = VkMemoryAllocateFlagBits.VK_MEMORY_ALLOCATE_FLAG_BITS_MAX_ENUM;
alias VkMemoryAllocateFlags = VkFlags;
alias VkCommandPoolTrimFlags = VkFlags;
alias VkDescriptorUpdateTemplateCreateFlags = VkFlags;

enum VkExternalMemoryHandleTypeFlagBits {
    VK_EXTERNAL_MEMORY_HANDLE_TYPE_OPAQUE_FD_BIT                         = 0x00000001,
    VK_EXTERNAL_MEMORY_HANDLE_TYPE_OPAQUE_WIN32_BIT                      = 0x00000002,
    VK_EXTERNAL_MEMORY_HANDLE_TYPE_OPAQUE_WIN32_KMT_BIT                  = 0x00000004,
    VK_EXTERNAL_MEMORY_HANDLE_TYPE_D3D11_TEXTURE_BIT                     = 0x00000008,
    VK_EXTERNAL_MEMORY_HANDLE_TYPE_D3D11_TEXTURE_KMT_BIT                 = 0x00000010,
    VK_EXTERNAL_MEMORY_HANDLE_TYPE_D3D12_HEAP_BIT                        = 0x00000020,
    VK_EXTERNAL_MEMORY_HANDLE_TYPE_D3D12_RESOURCE_BIT                    = 0x00000040,
    VK_EXTERNAL_MEMORY_HANDLE_TYPE_DMA_BUF_BIT_EXT                       = 0x00000200,
    VK_EXTERNAL_MEMORY_HANDLE_TYPE_ANDROID_HARDWARE_BUFFER_BIT_ANDROID   = 0x00000400,
    VK_EXTERNAL_MEMORY_HANDLE_TYPE_HOST_ALLOCATION_BIT_EXT               = 0x00000080,
    VK_EXTERNAL_MEMORY_HANDLE_TYPE_HOST_MAPPED_FOREIGN_MEMORY_BIT_EXT    = 0x00000100,
    VK_EXTERNAL_MEMORY_HANDLE_TYPE_OPAQUE_FD_BIT_KHR                     = VK_EXTERNAL_MEMORY_HANDLE_TYPE_OPAQUE_FD_BIT,
    VK_EXTERNAL_MEMORY_HANDLE_TYPE_OPAQUE_WIN32_BIT_KHR                  = VK_EXTERNAL_MEMORY_HANDLE_TYPE_OPAQUE_WIN32_BIT,
    VK_EXTERNAL_MEMORY_HANDLE_TYPE_OPAQUE_WIN32_KMT_BIT_KHR              = VK_EXTERNAL_MEMORY_HANDLE_TYPE_OPAQUE_WIN32_KMT_BIT,
    VK_EXTERNAL_MEMORY_HANDLE_TYPE_D3D11_TEXTURE_BIT_KHR                 = VK_EXTERNAL_MEMORY_HANDLE_TYPE_D3D11_TEXTURE_BIT,
    VK_EXTERNAL_MEMORY_HANDLE_TYPE_D3D11_TEXTURE_KMT_BIT_KHR             = VK_EXTERNAL_MEMORY_HANDLE_TYPE_D3D11_TEXTURE_KMT_BIT,
    VK_EXTERNAL_MEMORY_HANDLE_TYPE_D3D12_HEAP_BIT_KHR                    = VK_EXTERNAL_MEMORY_HANDLE_TYPE_D3D12_HEAP_BIT,
    VK_EXTERNAL_MEMORY_HANDLE_TYPE_D3D12_RESOURCE_BIT_KHR                = VK_EXTERNAL_MEMORY_HANDLE_TYPE_D3D12_RESOURCE_BIT,
    VK_EXTERNAL_MEMORY_HANDLE_TYPE_FLAG_BITS_MAX_ENUM                    = 0x7FFFFFFF
}

enum VK_EXTERNAL_MEMORY_HANDLE_TYPE_OPAQUE_FD_BIT                        = VkExternalMemoryHandleTypeFlagBits.VK_EXTERNAL_MEMORY_HANDLE_TYPE_OPAQUE_FD_BIT;
enum VK_EXTERNAL_MEMORY_HANDLE_TYPE_OPAQUE_WIN32_BIT                     = VkExternalMemoryHandleTypeFlagBits.VK_EXTERNAL_MEMORY_HANDLE_TYPE_OPAQUE_WIN32_BIT;
enum VK_EXTERNAL_MEMORY_HANDLE_TYPE_OPAQUE_WIN32_KMT_BIT                 = VkExternalMemoryHandleTypeFlagBits.VK_EXTERNAL_MEMORY_HANDLE_TYPE_OPAQUE_WIN32_KMT_BIT;
enum VK_EXTERNAL_MEMORY_HANDLE_TYPE_D3D11_TEXTURE_BIT                    = VkExternalMemoryHandleTypeFlagBits.VK_EXTERNAL_MEMORY_HANDLE_TYPE_D3D11_TEXTURE_BIT;
enum VK_EXTERNAL_MEMORY_HANDLE_TYPE_D3D11_TEXTURE_KMT_BIT                = VkExternalMemoryHandleTypeFlagBits.VK_EXTERNAL_MEMORY_HANDLE_TYPE_D3D11_TEXTURE_KMT_BIT;
enum VK_EXTERNAL_MEMORY_HANDLE_TYPE_D3D12_HEAP_BIT                       = VkExternalMemoryHandleTypeFlagBits.VK_EXTERNAL_MEMORY_HANDLE_TYPE_D3D12_HEAP_BIT;
enum VK_EXTERNAL_MEMORY_HANDLE_TYPE_D3D12_RESOURCE_BIT                   = VkExternalMemoryHandleTypeFlagBits.VK_EXTERNAL_MEMORY_HANDLE_TYPE_D3D12_RESOURCE_BIT;
enum VK_EXTERNAL_MEMORY_HANDLE_TYPE_DMA_BUF_BIT_EXT                      = VkExternalMemoryHandleTypeFlagBits.VK_EXTERNAL_MEMORY_HANDLE_TYPE_DMA_BUF_BIT_EXT;
enum VK_EXTERNAL_MEMORY_HANDLE_TYPE_ANDROID_HARDWARE_BUFFER_BIT_ANDROID  = VkExternalMemoryHandleTypeFlagBits.VK_EXTERNAL_MEMORY_HANDLE_TYPE_ANDROID_HARDWARE_BUFFER_BIT_ANDROID;
enum VK_EXTERNAL_MEMORY_HANDLE_TYPE_HOST_ALLOCATION_BIT_EXT              = VkExternalMemoryHandleTypeFlagBits.VK_EXTERNAL_MEMORY_HANDLE_TYPE_HOST_ALLOCATION_BIT_EXT;
enum VK_EXTERNAL_MEMORY_HANDLE_TYPE_HOST_MAPPED_FOREIGN_MEMORY_BIT_EXT   = VkExternalMemoryHandleTypeFlagBits.VK_EXTERNAL_MEMORY_HANDLE_TYPE_HOST_MAPPED_FOREIGN_MEMORY_BIT_EXT;
enum VK_EXTERNAL_MEMORY_HANDLE_TYPE_OPAQUE_FD_BIT_KHR                    = VkExternalMemoryHandleTypeFlagBits.VK_EXTERNAL_MEMORY_HANDLE_TYPE_OPAQUE_FD_BIT_KHR;
enum VK_EXTERNAL_MEMORY_HANDLE_TYPE_OPAQUE_WIN32_BIT_KHR                 = VkExternalMemoryHandleTypeFlagBits.VK_EXTERNAL_MEMORY_HANDLE_TYPE_OPAQUE_WIN32_BIT_KHR;
enum VK_EXTERNAL_MEMORY_HANDLE_TYPE_OPAQUE_WIN32_KMT_BIT_KHR             = VkExternalMemoryHandleTypeFlagBits.VK_EXTERNAL_MEMORY_HANDLE_TYPE_OPAQUE_WIN32_KMT_BIT_KHR;
enum VK_EXTERNAL_MEMORY_HANDLE_TYPE_D3D11_TEXTURE_BIT_KHR                = VkExternalMemoryHandleTypeFlagBits.VK_EXTERNAL_MEMORY_HANDLE_TYPE_D3D11_TEXTURE_BIT_KHR;
enum VK_EXTERNAL_MEMORY_HANDLE_TYPE_D3D11_TEXTURE_KMT_BIT_KHR            = VkExternalMemoryHandleTypeFlagBits.VK_EXTERNAL_MEMORY_HANDLE_TYPE_D3D11_TEXTURE_KMT_BIT_KHR;
enum VK_EXTERNAL_MEMORY_HANDLE_TYPE_D3D12_HEAP_BIT_KHR                   = VkExternalMemoryHandleTypeFlagBits.VK_EXTERNAL_MEMORY_HANDLE_TYPE_D3D12_HEAP_BIT_KHR;
enum VK_EXTERNAL_MEMORY_HANDLE_TYPE_D3D12_RESOURCE_BIT_KHR               = VkExternalMemoryHandleTypeFlagBits.VK_EXTERNAL_MEMORY_HANDLE_TYPE_D3D12_RESOURCE_BIT_KHR;
enum VK_EXTERNAL_MEMORY_HANDLE_TYPE_FLAG_BITS_MAX_ENUM                   = VkExternalMemoryHandleTypeFlagBits.VK_EXTERNAL_MEMORY_HANDLE_TYPE_FLAG_BITS_MAX_ENUM;
alias VkExternalMemoryHandleTypeFlags = VkFlags;

enum VkExternalMemoryFeatureFlagBits {
    VK_EXTERNAL_MEMORY_FEATURE_DEDICATED_ONLY_BIT        = 0x00000001,
    VK_EXTERNAL_MEMORY_FEATURE_EXPORTABLE_BIT            = 0x00000002,
    VK_EXTERNAL_MEMORY_FEATURE_IMPORTABLE_BIT            = 0x00000004,
    VK_EXTERNAL_MEMORY_FEATURE_DEDICATED_ONLY_BIT_KHR    = VK_EXTERNAL_MEMORY_FEATURE_DEDICATED_ONLY_BIT,
    VK_EXTERNAL_MEMORY_FEATURE_EXPORTABLE_BIT_KHR        = VK_EXTERNAL_MEMORY_FEATURE_EXPORTABLE_BIT,
    VK_EXTERNAL_MEMORY_FEATURE_IMPORTABLE_BIT_KHR        = VK_EXTERNAL_MEMORY_FEATURE_IMPORTABLE_BIT,
    VK_EXTERNAL_MEMORY_FEATURE_FLAG_BITS_MAX_ENUM        = 0x7FFFFFFF
}

enum VK_EXTERNAL_MEMORY_FEATURE_DEDICATED_ONLY_BIT       = VkExternalMemoryFeatureFlagBits.VK_EXTERNAL_MEMORY_FEATURE_DEDICATED_ONLY_BIT;
enum VK_EXTERNAL_MEMORY_FEATURE_EXPORTABLE_BIT           = VkExternalMemoryFeatureFlagBits.VK_EXTERNAL_MEMORY_FEATURE_EXPORTABLE_BIT;
enum VK_EXTERNAL_MEMORY_FEATURE_IMPORTABLE_BIT           = VkExternalMemoryFeatureFlagBits.VK_EXTERNAL_MEMORY_FEATURE_IMPORTABLE_BIT;
enum VK_EXTERNAL_MEMORY_FEATURE_DEDICATED_ONLY_BIT_KHR   = VkExternalMemoryFeatureFlagBits.VK_EXTERNAL_MEMORY_FEATURE_DEDICATED_ONLY_BIT_KHR;
enum VK_EXTERNAL_MEMORY_FEATURE_EXPORTABLE_BIT_KHR       = VkExternalMemoryFeatureFlagBits.VK_EXTERNAL_MEMORY_FEATURE_EXPORTABLE_BIT_KHR;
enum VK_EXTERNAL_MEMORY_FEATURE_IMPORTABLE_BIT_KHR       = VkExternalMemoryFeatureFlagBits.VK_EXTERNAL_MEMORY_FEATURE_IMPORTABLE_BIT_KHR;
enum VK_EXTERNAL_MEMORY_FEATURE_FLAG_BITS_MAX_ENUM       = VkExternalMemoryFeatureFlagBits.VK_EXTERNAL_MEMORY_FEATURE_FLAG_BITS_MAX_ENUM;
alias VkExternalMemoryFeatureFlags = VkFlags;

enum VkExternalFenceHandleTypeFlagBits {
    VK_EXTERNAL_FENCE_HANDLE_TYPE_OPAQUE_FD_BIT                  = 0x00000001,
    VK_EXTERNAL_FENCE_HANDLE_TYPE_OPAQUE_WIN32_BIT               = 0x00000002,
    VK_EXTERNAL_FENCE_HANDLE_TYPE_OPAQUE_WIN32_KMT_BIT           = 0x00000004,
    VK_EXTERNAL_FENCE_HANDLE_TYPE_SYNC_FD_BIT                    = 0x00000008,
    VK_EXTERNAL_FENCE_HANDLE_TYPE_OPAQUE_FD_BIT_KHR              = VK_EXTERNAL_FENCE_HANDLE_TYPE_OPAQUE_FD_BIT,
    VK_EXTERNAL_FENCE_HANDLE_TYPE_OPAQUE_WIN32_BIT_KHR           = VK_EXTERNAL_FENCE_HANDLE_TYPE_OPAQUE_WIN32_BIT,
    VK_EXTERNAL_FENCE_HANDLE_TYPE_OPAQUE_WIN32_KMT_BIT_KHR       = VK_EXTERNAL_FENCE_HANDLE_TYPE_OPAQUE_WIN32_KMT_BIT,
    VK_EXTERNAL_FENCE_HANDLE_TYPE_SYNC_FD_BIT_KHR                = VK_EXTERNAL_FENCE_HANDLE_TYPE_SYNC_FD_BIT,
    VK_EXTERNAL_FENCE_HANDLE_TYPE_FLAG_BITS_MAX_ENUM             = 0x7FFFFFFF
}

enum VK_EXTERNAL_FENCE_HANDLE_TYPE_OPAQUE_FD_BIT                 = VkExternalFenceHandleTypeFlagBits.VK_EXTERNAL_FENCE_HANDLE_TYPE_OPAQUE_FD_BIT;
enum VK_EXTERNAL_FENCE_HANDLE_TYPE_OPAQUE_WIN32_BIT              = VkExternalFenceHandleTypeFlagBits.VK_EXTERNAL_FENCE_HANDLE_TYPE_OPAQUE_WIN32_BIT;
enum VK_EXTERNAL_FENCE_HANDLE_TYPE_OPAQUE_WIN32_KMT_BIT          = VkExternalFenceHandleTypeFlagBits.VK_EXTERNAL_FENCE_HANDLE_TYPE_OPAQUE_WIN32_KMT_BIT;
enum VK_EXTERNAL_FENCE_HANDLE_TYPE_SYNC_FD_BIT                   = VkExternalFenceHandleTypeFlagBits.VK_EXTERNAL_FENCE_HANDLE_TYPE_SYNC_FD_BIT;
enum VK_EXTERNAL_FENCE_HANDLE_TYPE_OPAQUE_FD_BIT_KHR             = VkExternalFenceHandleTypeFlagBits.VK_EXTERNAL_FENCE_HANDLE_TYPE_OPAQUE_FD_BIT_KHR;
enum VK_EXTERNAL_FENCE_HANDLE_TYPE_OPAQUE_WIN32_BIT_KHR          = VkExternalFenceHandleTypeFlagBits.VK_EXTERNAL_FENCE_HANDLE_TYPE_OPAQUE_WIN32_BIT_KHR;
enum VK_EXTERNAL_FENCE_HANDLE_TYPE_OPAQUE_WIN32_KMT_BIT_KHR      = VkExternalFenceHandleTypeFlagBits.VK_EXTERNAL_FENCE_HANDLE_TYPE_OPAQUE_WIN32_KMT_BIT_KHR;
enum VK_EXTERNAL_FENCE_HANDLE_TYPE_SYNC_FD_BIT_KHR               = VkExternalFenceHandleTypeFlagBits.VK_EXTERNAL_FENCE_HANDLE_TYPE_SYNC_FD_BIT_KHR;
enum VK_EXTERNAL_FENCE_HANDLE_TYPE_FLAG_BITS_MAX_ENUM            = VkExternalFenceHandleTypeFlagBits.VK_EXTERNAL_FENCE_HANDLE_TYPE_FLAG_BITS_MAX_ENUM;
alias VkExternalFenceHandleTypeFlags = VkFlags;

enum VkExternalFenceFeatureFlagBits {
    VK_EXTERNAL_FENCE_FEATURE_EXPORTABLE_BIT             = 0x00000001,
    VK_EXTERNAL_FENCE_FEATURE_IMPORTABLE_BIT             = 0x00000002,
    VK_EXTERNAL_FENCE_FEATURE_EXPORTABLE_BIT_KHR         = VK_EXTERNAL_FENCE_FEATURE_EXPORTABLE_BIT,
    VK_EXTERNAL_FENCE_FEATURE_IMPORTABLE_BIT_KHR         = VK_EXTERNAL_FENCE_FEATURE_IMPORTABLE_BIT,
    VK_EXTERNAL_FENCE_FEATURE_FLAG_BITS_MAX_ENUM         = 0x7FFFFFFF
}

enum VK_EXTERNAL_FENCE_FEATURE_EXPORTABLE_BIT            = VkExternalFenceFeatureFlagBits.VK_EXTERNAL_FENCE_FEATURE_EXPORTABLE_BIT;
enum VK_EXTERNAL_FENCE_FEATURE_IMPORTABLE_BIT            = VkExternalFenceFeatureFlagBits.VK_EXTERNAL_FENCE_FEATURE_IMPORTABLE_BIT;
enum VK_EXTERNAL_FENCE_FEATURE_EXPORTABLE_BIT_KHR        = VkExternalFenceFeatureFlagBits.VK_EXTERNAL_FENCE_FEATURE_EXPORTABLE_BIT_KHR;
enum VK_EXTERNAL_FENCE_FEATURE_IMPORTABLE_BIT_KHR        = VkExternalFenceFeatureFlagBits.VK_EXTERNAL_FENCE_FEATURE_IMPORTABLE_BIT_KHR;
enum VK_EXTERNAL_FENCE_FEATURE_FLAG_BITS_MAX_ENUM        = VkExternalFenceFeatureFlagBits.VK_EXTERNAL_FENCE_FEATURE_FLAG_BITS_MAX_ENUM;
alias VkExternalFenceFeatureFlags = VkFlags;

enum VkFenceImportFlagBits {
    VK_FENCE_IMPORT_TEMPORARY_BIT                = 0x00000001,
    VK_FENCE_IMPORT_TEMPORARY_BIT_KHR            = VK_FENCE_IMPORT_TEMPORARY_BIT,
    VK_FENCE_IMPORT_FLAG_BITS_MAX_ENUM           = 0x7FFFFFFF
}

enum VK_FENCE_IMPORT_TEMPORARY_BIT               = VkFenceImportFlagBits.VK_FENCE_IMPORT_TEMPORARY_BIT;
enum VK_FENCE_IMPORT_TEMPORARY_BIT_KHR           = VkFenceImportFlagBits.VK_FENCE_IMPORT_TEMPORARY_BIT_KHR;
enum VK_FENCE_IMPORT_FLAG_BITS_MAX_ENUM          = VkFenceImportFlagBits.VK_FENCE_IMPORT_FLAG_BITS_MAX_ENUM;
alias VkFenceImportFlags = VkFlags;

enum VkSemaphoreImportFlagBits {
    VK_SEMAPHORE_IMPORT_TEMPORARY_BIT            = 0x00000001,
    VK_SEMAPHORE_IMPORT_TEMPORARY_BIT_KHR        = VK_SEMAPHORE_IMPORT_TEMPORARY_BIT,
    VK_SEMAPHORE_IMPORT_FLAG_BITS_MAX_ENUM       = 0x7FFFFFFF
}

enum VK_SEMAPHORE_IMPORT_TEMPORARY_BIT           = VkSemaphoreImportFlagBits.VK_SEMAPHORE_IMPORT_TEMPORARY_BIT;
enum VK_SEMAPHORE_IMPORT_TEMPORARY_BIT_KHR       = VkSemaphoreImportFlagBits.VK_SEMAPHORE_IMPORT_TEMPORARY_BIT_KHR;
enum VK_SEMAPHORE_IMPORT_FLAG_BITS_MAX_ENUM      = VkSemaphoreImportFlagBits.VK_SEMAPHORE_IMPORT_FLAG_BITS_MAX_ENUM;
alias VkSemaphoreImportFlags = VkFlags;

enum VkExternalSemaphoreHandleTypeFlagBits {
    VK_EXTERNAL_SEMAPHORE_HANDLE_TYPE_OPAQUE_FD_BIT              = 0x00000001,
    VK_EXTERNAL_SEMAPHORE_HANDLE_TYPE_OPAQUE_WIN32_BIT           = 0x00000002,
    VK_EXTERNAL_SEMAPHORE_HANDLE_TYPE_OPAQUE_WIN32_KMT_BIT       = 0x00000004,
    VK_EXTERNAL_SEMAPHORE_HANDLE_TYPE_D3D12_FENCE_BIT            = 0x00000008,
    VK_EXTERNAL_SEMAPHORE_HANDLE_TYPE_SYNC_FD_BIT                = 0x00000010,
    VK_EXTERNAL_SEMAPHORE_HANDLE_TYPE_OPAQUE_FD_BIT_KHR          = VK_EXTERNAL_SEMAPHORE_HANDLE_TYPE_OPAQUE_FD_BIT,
    VK_EXTERNAL_SEMAPHORE_HANDLE_TYPE_OPAQUE_WIN32_BIT_KHR       = VK_EXTERNAL_SEMAPHORE_HANDLE_TYPE_OPAQUE_WIN32_BIT,
    VK_EXTERNAL_SEMAPHORE_HANDLE_TYPE_OPAQUE_WIN32_KMT_BIT_KHR   = VK_EXTERNAL_SEMAPHORE_HANDLE_TYPE_OPAQUE_WIN32_KMT_BIT,
    VK_EXTERNAL_SEMAPHORE_HANDLE_TYPE_D3D12_FENCE_BIT_KHR        = VK_EXTERNAL_SEMAPHORE_HANDLE_TYPE_D3D12_FENCE_BIT,
    VK_EXTERNAL_SEMAPHORE_HANDLE_TYPE_SYNC_FD_BIT_KHR            = VK_EXTERNAL_SEMAPHORE_HANDLE_TYPE_SYNC_FD_BIT,
    VK_EXTERNAL_SEMAPHORE_HANDLE_TYPE_FLAG_BITS_MAX_ENUM         = 0x7FFFFFFF
}

enum VK_EXTERNAL_SEMAPHORE_HANDLE_TYPE_OPAQUE_FD_BIT             = VkExternalSemaphoreHandleTypeFlagBits.VK_EXTERNAL_SEMAPHORE_HANDLE_TYPE_OPAQUE_FD_BIT;
enum VK_EXTERNAL_SEMAPHORE_HANDLE_TYPE_OPAQUE_WIN32_BIT          = VkExternalSemaphoreHandleTypeFlagBits.VK_EXTERNAL_SEMAPHORE_HANDLE_TYPE_OPAQUE_WIN32_BIT;
enum VK_EXTERNAL_SEMAPHORE_HANDLE_TYPE_OPAQUE_WIN32_KMT_BIT      = VkExternalSemaphoreHandleTypeFlagBits.VK_EXTERNAL_SEMAPHORE_HANDLE_TYPE_OPAQUE_WIN32_KMT_BIT;
enum VK_EXTERNAL_SEMAPHORE_HANDLE_TYPE_D3D12_FENCE_BIT           = VkExternalSemaphoreHandleTypeFlagBits.VK_EXTERNAL_SEMAPHORE_HANDLE_TYPE_D3D12_FENCE_BIT;
enum VK_EXTERNAL_SEMAPHORE_HANDLE_TYPE_SYNC_FD_BIT               = VkExternalSemaphoreHandleTypeFlagBits.VK_EXTERNAL_SEMAPHORE_HANDLE_TYPE_SYNC_FD_BIT;
enum VK_EXTERNAL_SEMAPHORE_HANDLE_TYPE_OPAQUE_FD_BIT_KHR         = VkExternalSemaphoreHandleTypeFlagBits.VK_EXTERNAL_SEMAPHORE_HANDLE_TYPE_OPAQUE_FD_BIT_KHR;
enum VK_EXTERNAL_SEMAPHORE_HANDLE_TYPE_OPAQUE_WIN32_BIT_KHR      = VkExternalSemaphoreHandleTypeFlagBits.VK_EXTERNAL_SEMAPHORE_HANDLE_TYPE_OPAQUE_WIN32_BIT_KHR;
enum VK_EXTERNAL_SEMAPHORE_HANDLE_TYPE_OPAQUE_WIN32_KMT_BIT_KHR  = VkExternalSemaphoreHandleTypeFlagBits.VK_EXTERNAL_SEMAPHORE_HANDLE_TYPE_OPAQUE_WIN32_KMT_BIT_KHR;
enum VK_EXTERNAL_SEMAPHORE_HANDLE_TYPE_D3D12_FENCE_BIT_KHR       = VkExternalSemaphoreHandleTypeFlagBits.VK_EXTERNAL_SEMAPHORE_HANDLE_TYPE_D3D12_FENCE_BIT_KHR;
enum VK_EXTERNAL_SEMAPHORE_HANDLE_TYPE_SYNC_FD_BIT_KHR           = VkExternalSemaphoreHandleTypeFlagBits.VK_EXTERNAL_SEMAPHORE_HANDLE_TYPE_SYNC_FD_BIT_KHR;
enum VK_EXTERNAL_SEMAPHORE_HANDLE_TYPE_FLAG_BITS_MAX_ENUM        = VkExternalSemaphoreHandleTypeFlagBits.VK_EXTERNAL_SEMAPHORE_HANDLE_TYPE_FLAG_BITS_MAX_ENUM;
alias VkExternalSemaphoreHandleTypeFlags = VkFlags;

enum VkExternalSemaphoreFeatureFlagBits {
    VK_EXTERNAL_SEMAPHORE_FEATURE_EXPORTABLE_BIT         = 0x00000001,
    VK_EXTERNAL_SEMAPHORE_FEATURE_IMPORTABLE_BIT         = 0x00000002,
    VK_EXTERNAL_SEMAPHORE_FEATURE_EXPORTABLE_BIT_KHR     = VK_EXTERNAL_SEMAPHORE_FEATURE_EXPORTABLE_BIT,
    VK_EXTERNAL_SEMAPHORE_FEATURE_IMPORTABLE_BIT_KHR     = VK_EXTERNAL_SEMAPHORE_FEATURE_IMPORTABLE_BIT,
    VK_EXTERNAL_SEMAPHORE_FEATURE_FLAG_BITS_MAX_ENUM     = 0x7FFFFFFF
}

enum VK_EXTERNAL_SEMAPHORE_FEATURE_EXPORTABLE_BIT        = VkExternalSemaphoreFeatureFlagBits.VK_EXTERNAL_SEMAPHORE_FEATURE_EXPORTABLE_BIT;
enum VK_EXTERNAL_SEMAPHORE_FEATURE_IMPORTABLE_BIT        = VkExternalSemaphoreFeatureFlagBits.VK_EXTERNAL_SEMAPHORE_FEATURE_IMPORTABLE_BIT;
enum VK_EXTERNAL_SEMAPHORE_FEATURE_EXPORTABLE_BIT_KHR    = VkExternalSemaphoreFeatureFlagBits.VK_EXTERNAL_SEMAPHORE_FEATURE_EXPORTABLE_BIT_KHR;
enum VK_EXTERNAL_SEMAPHORE_FEATURE_IMPORTABLE_BIT_KHR    = VkExternalSemaphoreFeatureFlagBits.VK_EXTERNAL_SEMAPHORE_FEATURE_IMPORTABLE_BIT_KHR;
enum VK_EXTERNAL_SEMAPHORE_FEATURE_FLAG_BITS_MAX_ENUM    = VkExternalSemaphoreFeatureFlagBits.VK_EXTERNAL_SEMAPHORE_FEATURE_FLAG_BITS_MAX_ENUM;
alias VkExternalSemaphoreFeatureFlags = VkFlags;

struct VkPhysicalDeviceSubgroupProperties {
    VkStructureType         sType = VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_SUBGROUP_PROPERTIES;
    void*                   pNext;
    uint32_t                subgroupSize;
    VkShaderStageFlags      supportedStages;
    VkSubgroupFeatureFlags  supportedOperations;
    VkBool32                quadOperationsInAllStages;
}

struct VkBindBufferMemoryInfo {
    VkStructureType  sType = VK_STRUCTURE_TYPE_BIND_BUFFER_MEMORY_INFO;
    const( void )*   pNext;
    VkBuffer         buffer;
    VkDeviceMemory   memory;
    VkDeviceSize     memoryOffset;
}

struct VkBindImageMemoryInfo {
    VkStructureType  sType = VK_STRUCTURE_TYPE_BIND_IMAGE_MEMORY_INFO;
    const( void )*   pNext;
    VkImage          image;
    VkDeviceMemory   memory;
    VkDeviceSize     memoryOffset;
}

struct VkPhysicalDevice16BitStorageFeatures {
    VkStructureType  sType = VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_16BIT_STORAGE_FEATURES;
    void*            pNext;
    VkBool32         storageBuffer16BitAccess;
    VkBool32         uniformAndStorageBuffer16BitAccess;
    VkBool32         storagePushConstant16;
    VkBool32         storageInputOutput16;
}

struct VkMemoryDedicatedRequirements {
    VkStructureType  sType = VK_STRUCTURE_TYPE_MEMORY_DEDICATED_REQUIREMENTS;
    void*            pNext;
    VkBool32         prefersDedicatedAllocation;
    VkBool32         requiresDedicatedAllocation;
}

struct VkMemoryDedicatedAllocateInfo {
    VkStructureType  sType = VK_STRUCTURE_TYPE_MEMORY_DEDICATED_ALLOCATE_INFO;
    const( void )*   pNext;
    VkImage          image;
    VkBuffer         buffer;
}

struct VkMemoryAllocateFlagsInfo {
    VkStructureType        sType = VK_STRUCTURE_TYPE_MEMORY_ALLOCATE_FLAGS_INFO;
    const( void )*         pNext;
    VkMemoryAllocateFlags  flags;
    uint32_t               deviceMask;
}

struct VkDeviceGroupRenderPassBeginInfo {
    VkStructureType     sType = VK_STRUCTURE_TYPE_DEVICE_GROUP_RENDER_PASS_BEGIN_INFO;
    const( void )*      pNext;
    uint32_t            deviceMask;
    uint32_t            deviceRenderAreaCount;
    const( VkRect2D )*  pDeviceRenderAreas;
}

struct VkDeviceGroupCommandBufferBeginInfo {
    VkStructureType  sType = VK_STRUCTURE_TYPE_DEVICE_GROUP_COMMAND_BUFFER_BEGIN_INFO;
    const( void )*   pNext;
    uint32_t         deviceMask;
}

struct VkDeviceGroupSubmitInfo {
    VkStructureType     sType = VK_STRUCTURE_TYPE_DEVICE_GROUP_SUBMIT_INFO;
    const( void )*      pNext;
    uint32_t            waitSemaphoreCount;
    const( uint32_t )*  pWaitSemaphoreDeviceIndices;
    uint32_t            commandBufferCount;
    const( uint32_t )*  pCommandBufferDeviceMasks;
    uint32_t            signalSemaphoreCount;
    const( uint32_t )*  pSignalSemaphoreDeviceIndices;
}

struct VkDeviceGroupBindSparseInfo {
    VkStructureType  sType = VK_STRUCTURE_TYPE_DEVICE_GROUP_BIND_SPARSE_INFO;
    const( void )*   pNext;
    uint32_t         resourceDeviceIndex;
    uint32_t         memoryDeviceIndex;
}

struct VkBindBufferMemoryDeviceGroupInfo {
    VkStructureType     sType = VK_STRUCTURE_TYPE_BIND_BUFFER_MEMORY_DEVICE_GROUP_INFO;
    const( void )*      pNext;
    uint32_t            deviceIndexCount;
    const( uint32_t )*  pDeviceIndices;
}

struct VkBindImageMemoryDeviceGroupInfo {
    VkStructureType     sType = VK_STRUCTURE_TYPE_BIND_IMAGE_MEMORY_DEVICE_GROUP_INFO;
    const( void )*      pNext;
    uint32_t            deviceIndexCount;
    const( uint32_t )*  pDeviceIndices;
    uint32_t            splitInstanceBindRegionCount;
    const( VkRect2D )*  pSplitInstanceBindRegions;
}

struct VkPhysicalDeviceGroupProperties {
    VkStructureType                               sType = VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_GROUP_PROPERTIES;
    void*                                         pNext;
    uint32_t                                      physicalDeviceCount;
    VkPhysicalDevice[ VK_MAX_DEVICE_GROUP_SIZE ]  physicalDevices;
    VkBool32                                      subsetAllocation;
}

struct VkDeviceGroupDeviceCreateInfo {
    VkStructureType             sType = VK_STRUCTURE_TYPE_DEVICE_GROUP_DEVICE_CREATE_INFO;
    const( void )*              pNext;
    uint32_t                    physicalDeviceCount;
    const( VkPhysicalDevice )*  pPhysicalDevices;
}

struct VkBufferMemoryRequirementsInfo2 {
    VkStructureType  sType = VK_STRUCTURE_TYPE_BUFFER_MEMORY_REQUIREMENTS_INFO_2;
    const( void )*   pNext;
    VkBuffer         buffer;
}

struct VkImageMemoryRequirementsInfo2 {
    VkStructureType  sType = VK_STRUCTURE_TYPE_IMAGE_MEMORY_REQUIREMENTS_INFO_2;
    const( void )*   pNext;
    VkImage          image;
}

struct VkImageSparseMemoryRequirementsInfo2 {
    VkStructureType  sType = VK_STRUCTURE_TYPE_IMAGE_SPARSE_MEMORY_REQUIREMENTS_INFO_2;
    const( void )*   pNext;
    VkImage          image;
}

struct VkMemoryRequirements2 {
    VkStructureType       sType = VK_STRUCTURE_TYPE_MEMORY_REQUIREMENTS_2;
    void*                 pNext;
    VkMemoryRequirements  memoryRequirements;
}
alias VkMemoryRequirements2KHR = VkMemoryRequirements2;

struct VkSparseImageMemoryRequirements2 {
    VkStructureType                  sType = VK_STRUCTURE_TYPE_SPARSE_IMAGE_MEMORY_REQUIREMENTS_2;
    void*                            pNext;
    VkSparseImageMemoryRequirements  memoryRequirements;
}

struct VkPhysicalDeviceFeatures2 {
    VkStructureType           sType = VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_FEATURES_2;
    void*                     pNext;
    VkPhysicalDeviceFeatures  features;
}

struct VkPhysicalDeviceProperties2 {
    VkStructureType             sType = VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_PROPERTIES_2;
    void*                       pNext;
    VkPhysicalDeviceProperties  properties;
}

struct VkFormatProperties2 {
    VkStructureType     sType = VK_STRUCTURE_TYPE_FORMAT_PROPERTIES_2;
    void*               pNext;
    VkFormatProperties  formatProperties;
}

struct VkImageFormatProperties2 {
    VkStructureType          sType = VK_STRUCTURE_TYPE_IMAGE_FORMAT_PROPERTIES_2;
    void*                    pNext;
    VkImageFormatProperties  imageFormatProperties;
}

struct VkPhysicalDeviceImageFormatInfo2 {
    VkStructureType     sType = VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_IMAGE_FORMAT_INFO_2;
    const( void )*      pNext;
    VkFormat            format;
    VkImageType         type;
    VkImageTiling       tiling;
    VkImageUsageFlags   usage;
    VkImageCreateFlags  flags;
}

struct VkQueueFamilyProperties2 {
    VkStructureType          sType = VK_STRUCTURE_TYPE_QUEUE_FAMILY_PROPERTIES_2;
    void*                    pNext;
    VkQueueFamilyProperties  queueFamilyProperties;
}

struct VkPhysicalDeviceMemoryProperties2 {
    VkStructureType                   sType = VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_MEMORY_PROPERTIES_2;
    void*                             pNext;
    VkPhysicalDeviceMemoryProperties  memoryProperties;
}

struct VkSparseImageFormatProperties2 {
    VkStructureType                sType = VK_STRUCTURE_TYPE_SPARSE_IMAGE_FORMAT_PROPERTIES_2;
    void*                          pNext;
    VkSparseImageFormatProperties  properties;
}

struct VkPhysicalDeviceSparseImageFormatInfo2 {
    VkStructureType        sType = VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_SPARSE_IMAGE_FORMAT_INFO_2;
    const( void )*         pNext;
    VkFormat               format;
    VkImageType            type;
    VkSampleCountFlagBits  samples;
    VkImageUsageFlags      usage;
    VkImageTiling          tiling;
}

struct VkPhysicalDevicePointClippingProperties {
    VkStructureType          sType = VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_POINT_CLIPPING_PROPERTIES;
    void*                    pNext;
    VkPointClippingBehavior  pointClippingBehavior;
}

struct VkInputAttachmentAspectReference {
    uint32_t            subpass;
    uint32_t            inputAttachmentIndex;
    VkImageAspectFlags  aspectMask;
}

struct VkRenderPassInputAttachmentAspectCreateInfo {
    VkStructureType                             sType = VK_STRUCTURE_TYPE_RENDER_PASS_INPUT_ATTACHMENT_ASPECT_CREATE_INFO;
    const( void )*                              pNext;
    uint32_t                                    aspectReferenceCount;
    const( VkInputAttachmentAspectReference )*  pAspectReferences;
}

struct VkImageViewUsageCreateInfo {
    VkStructureType    sType = VK_STRUCTURE_TYPE_IMAGE_VIEW_USAGE_CREATE_INFO;
    const( void )*     pNext;
    VkImageUsageFlags  usage;
}

struct VkPipelineTessellationDomainOriginStateCreateInfo {
    VkStructureType             sType = VK_STRUCTURE_TYPE_PIPELINE_TESSELLATION_DOMAIN_ORIGIN_STATE_CREATE_INFO;
    const( void )*              pNext;
    VkTessellationDomainOrigin  domainOrigin;
}

struct VkRenderPassMultiviewCreateInfo {
    VkStructureType     sType = VK_STRUCTURE_TYPE_RENDER_PASS_MULTIVIEW_CREATE_INFO;
    const( void )*      pNext;
    uint32_t            subpassCount;
    const( uint32_t )*  pViewMasks;
    uint32_t            dependencyCount;
    const( int32_t )*   pViewOffsets;
    uint32_t            correlationMaskCount;
    const( uint32_t )*  pCorrelationMasks;
}

struct VkPhysicalDeviceMultiviewFeatures {
    VkStructureType  sType = VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_MULTIVIEW_FEATURES;
    void*            pNext;
    VkBool32         multiview;
    VkBool32         multiviewGeometryShader;
    VkBool32         multiviewTessellationShader;
}

struct VkPhysicalDeviceMultiviewProperties {
    VkStructureType  sType = VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_MULTIVIEW_PROPERTIES;
    void*            pNext;
    uint32_t         maxMultiviewViewCount;
    uint32_t         maxMultiviewInstanceIndex;
}

struct VkPhysicalDeviceVariablePointersFeatures {
    VkStructureType  sType = VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_VARIABLE_POINTERS_FEATURES;
    void*            pNext;
    VkBool32         variablePointersStorageBuffer;
    VkBool32         variablePointers;
}
alias VkPhysicalDeviceVariablePointerFeatures = VkPhysicalDeviceVariablePointersFeatures;

struct VkPhysicalDeviceProtectedMemoryFeatures {
    VkStructureType  sType = VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_PROTECTED_MEMORY_FEATURES;
    void*            pNext;
    VkBool32         protectedMemory;
}

struct VkPhysicalDeviceProtectedMemoryProperties {
    VkStructureType  sType = VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_PROTECTED_MEMORY_PROPERTIES;
    void*            pNext;
    VkBool32         protectedNoFault;
}

struct VkDeviceQueueInfo2 {
    VkStructureType           sType = VK_STRUCTURE_TYPE_DEVICE_QUEUE_INFO_2;
    const( void )*            pNext;
    VkDeviceQueueCreateFlags  flags;
    uint32_t                  queueFamilyIndex;
    uint32_t                  queueIndex;
}

struct VkProtectedSubmitInfo {
    VkStructureType  sType = VK_STRUCTURE_TYPE_PROTECTED_SUBMIT_INFO;
    const( void )*   pNext;
    VkBool32         protectedSubmit;
}

struct VkSamplerYcbcrConversionCreateInfo {
    VkStructureType                sType = VK_STRUCTURE_TYPE_SAMPLER_YCBCR_CONVERSION_CREATE_INFO;
    const( void )*                 pNext;
    VkFormat                       format;
    VkSamplerYcbcrModelConversion  ycbcrModel;
    VkSamplerYcbcrRange            ycbcrRange;
    VkComponentMapping             components;
    VkChromaLocation               xChromaOffset;
    VkChromaLocation               yChromaOffset;
    VkFilter                       chromaFilter;
    VkBool32                       forceExplicitReconstruction;
}

struct VkSamplerYcbcrConversionInfo {
    VkStructureType           sType = VK_STRUCTURE_TYPE_SAMPLER_YCBCR_CONVERSION_INFO;
    const( void )*            pNext;
    VkSamplerYcbcrConversion  conversion;
}

struct VkBindImagePlaneMemoryInfo {
    VkStructureType        sType = VK_STRUCTURE_TYPE_BIND_IMAGE_PLANE_MEMORY_INFO;
    const( void )*         pNext;
    VkImageAspectFlagBits  planeAspect;
}

struct VkImagePlaneMemoryRequirementsInfo {
    VkStructureType        sType = VK_STRUCTURE_TYPE_IMAGE_PLANE_MEMORY_REQUIREMENTS_INFO;
    const( void )*         pNext;
    VkImageAspectFlagBits  planeAspect;
}

struct VkPhysicalDeviceSamplerYcbcrConversionFeatures {
    VkStructureType  sType = VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_SAMPLER_YCBCR_CONVERSION_FEATURES;
    void*            pNext;
    VkBool32         samplerYcbcrConversion;
}

struct VkSamplerYcbcrConversionImageFormatProperties {
    VkStructureType  sType = VK_STRUCTURE_TYPE_SAMPLER_YCBCR_CONVERSION_IMAGE_FORMAT_PROPERTIES;
    void*            pNext;
    uint32_t         combinedImageSamplerDescriptorCount;
}

struct VkDescriptorUpdateTemplateEntry {
    uint32_t          dstBinding;
    uint32_t          dstArrayElement;
    uint32_t          descriptorCount;
    VkDescriptorType  descriptorType;
    size_t            offset;
    size_t            stride;
}

struct VkDescriptorUpdateTemplateCreateInfo {
    VkStructureType                            sType = VK_STRUCTURE_TYPE_DESCRIPTOR_UPDATE_TEMPLATE_CREATE_INFO;
    const( void )*                             pNext;
    VkDescriptorUpdateTemplateCreateFlags      flags;
    uint32_t                                   descriptorUpdateEntryCount;
    const( VkDescriptorUpdateTemplateEntry )*  pDescriptorUpdateEntries;
    VkDescriptorUpdateTemplateType             templateType;
    VkDescriptorSetLayout                      descriptorSetLayout;
    VkPipelineBindPoint                        pipelineBindPoint;
    VkPipelineLayout                           pipelineLayout;
    uint32_t                                   set;
}

struct VkExternalMemoryProperties {
    VkExternalMemoryFeatureFlags     externalMemoryFeatures;
    VkExternalMemoryHandleTypeFlags  exportFromImportedHandleTypes;
    VkExternalMemoryHandleTypeFlags  compatibleHandleTypes;
}

struct VkPhysicalDeviceExternalImageFormatInfo {
    VkStructureType                     sType = VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_EXTERNAL_IMAGE_FORMAT_INFO;
    const( void )*                      pNext;
    VkExternalMemoryHandleTypeFlagBits  handleType;
}

struct VkExternalImageFormatProperties {
    VkStructureType             sType = VK_STRUCTURE_TYPE_EXTERNAL_IMAGE_FORMAT_PROPERTIES;
    void*                       pNext;
    VkExternalMemoryProperties  externalMemoryProperties;
}

struct VkPhysicalDeviceExternalBufferInfo {
    VkStructureType                     sType = VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_EXTERNAL_BUFFER_INFO;
    const( void )*                      pNext;
    VkBufferCreateFlags                 flags;
    VkBufferUsageFlags                  usage;
    VkExternalMemoryHandleTypeFlagBits  handleType;
}

struct VkExternalBufferProperties {
    VkStructureType             sType = VK_STRUCTURE_TYPE_EXTERNAL_BUFFER_PROPERTIES;
    void*                       pNext;
    VkExternalMemoryProperties  externalMemoryProperties;
}

struct VkPhysicalDeviceIDProperties {
    VkStructureType          sType = VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_ID_PROPERTIES;
    void*                    pNext;
    uint8_t[ VK_UUID_SIZE ]  deviceUUID;
    uint8_t[ VK_UUID_SIZE ]  driverUUID;
    uint8_t[ VK_LUID_SIZE ]  deviceLUID;
    uint32_t                 deviceNodeMask;
    VkBool32                 deviceLUIDValid;
}

struct VkExternalMemoryImageCreateInfo {
    VkStructureType                  sType = VK_STRUCTURE_TYPE_EXTERNAL_MEMORY_IMAGE_CREATE_INFO;
    const( void )*                   pNext;
    VkExternalMemoryHandleTypeFlags  handleTypes;
}

struct VkExternalMemoryBufferCreateInfo {
    VkStructureType                  sType = VK_STRUCTURE_TYPE_EXTERNAL_MEMORY_BUFFER_CREATE_INFO;
    const( void )*                   pNext;
    VkExternalMemoryHandleTypeFlags  handleTypes;
}

struct VkExportMemoryAllocateInfo {
    VkStructureType                  sType = VK_STRUCTURE_TYPE_EXPORT_MEMORY_ALLOCATE_INFO;
    const( void )*                   pNext;
    VkExternalMemoryHandleTypeFlags  handleTypes;
}

struct VkPhysicalDeviceExternalFenceInfo {
    VkStructureType                    sType = VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_EXTERNAL_FENCE_INFO;
    const( void )*                     pNext;
    VkExternalFenceHandleTypeFlagBits  handleType;
}

struct VkExternalFenceProperties {
    VkStructureType                 sType = VK_STRUCTURE_TYPE_EXTERNAL_FENCE_PROPERTIES;
    void*                           pNext;
    VkExternalFenceHandleTypeFlags  exportFromImportedHandleTypes;
    VkExternalFenceHandleTypeFlags  compatibleHandleTypes;
    VkExternalFenceFeatureFlags     externalFenceFeatures;
}

struct VkExportFenceCreateInfo {
    VkStructureType                 sType = VK_STRUCTURE_TYPE_EXPORT_FENCE_CREATE_INFO;
    const( void )*                  pNext;
    VkExternalFenceHandleTypeFlags  handleTypes;
}

struct VkExportSemaphoreCreateInfo {
    VkStructureType                     sType = VK_STRUCTURE_TYPE_EXPORT_SEMAPHORE_CREATE_INFO;
    const( void )*                      pNext;
    VkExternalSemaphoreHandleTypeFlags  handleTypes;
}

struct VkPhysicalDeviceExternalSemaphoreInfo {
    VkStructureType                        sType = VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_EXTERNAL_SEMAPHORE_INFO;
    const( void )*                         pNext;
    VkExternalSemaphoreHandleTypeFlagBits  handleType;
}

struct VkExternalSemaphoreProperties {
    VkStructureType                     sType = VK_STRUCTURE_TYPE_EXTERNAL_SEMAPHORE_PROPERTIES;
    void*                               pNext;
    VkExternalSemaphoreHandleTypeFlags  exportFromImportedHandleTypes;
    VkExternalSemaphoreHandleTypeFlags  compatibleHandleTypes;
    VkExternalSemaphoreFeatureFlags     externalSemaphoreFeatures;
}

struct VkPhysicalDeviceMaintenance3Properties {
    VkStructureType  sType = VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_MAINTENANCE_3_PROPERTIES;
    void*            pNext;
    uint32_t         maxPerSetDescriptors;
    VkDeviceSize     maxMemoryAllocationSize;
}

struct VkDescriptorSetLayoutSupport {
    VkStructureType  sType = VK_STRUCTURE_TYPE_DESCRIPTOR_SET_LAYOUT_SUPPORT;
    void*            pNext;
    VkBool32         supported;
}

struct VkPhysicalDeviceShaderDrawParametersFeatures {
    VkStructureType  sType = VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_SHADER_DRAW_PARAMETERS_FEATURES;
    void*            pNext;
    VkBool32         shaderDrawParameters;
}
alias VkPhysicalDeviceShaderDrawParameterFeatures = VkPhysicalDeviceShaderDrawParametersFeatures;


// - VK_KHR_surface -
enum VK_KHR_surface = 1;

mixin( VK_DEFINE_NON_DISPATCHABLE_HANDLE!q{VkSurfaceKHR} );

enum VK_KHR_SURFACE_SPEC_VERSION = 25;
enum VK_KHR_SURFACE_EXTENSION_NAME = "VK_KHR_surface";

enum VkColorSpaceKHR {
    VK_COLOR_SPACE_SRGB_NONLINEAR_KHR            = 0,
    VK_COLOR_SPACE_DISPLAY_P3_NONLINEAR_EXT      = 1000104001,
    VK_COLOR_SPACE_EXTENDED_SRGB_LINEAR_EXT      = 1000104002,
    VK_COLOR_SPACE_DISPLAY_P3_LINEAR_EXT         = 1000104003,
    VK_COLOR_SPACE_DCI_P3_NONLINEAR_EXT          = 1000104004,
    VK_COLOR_SPACE_BT709_LINEAR_EXT              = 1000104005,
    VK_COLOR_SPACE_BT709_NONLINEAR_EXT           = 1000104006,
    VK_COLOR_SPACE_BT2020_LINEAR_EXT             = 1000104007,
    VK_COLOR_SPACE_HDR10_ST2084_EXT              = 1000104008,
    VK_COLOR_SPACE_DOLBYVISION_EXT               = 1000104009,
    VK_COLOR_SPACE_HDR10_HLG_EXT                 = 1000104010,
    VK_COLOR_SPACE_ADOBERGB_LINEAR_EXT           = 1000104011,
    VK_COLOR_SPACE_ADOBERGB_NONLINEAR_EXT        = 1000104012,
    VK_COLOR_SPACE_PASS_THROUGH_EXT              = 1000104013,
    VK_COLOR_SPACE_EXTENDED_SRGB_NONLINEAR_EXT   = 1000104014,
    VK_COLOR_SPACE_DISPLAY_NATIVE_AMD            = 1000213000,
    VK_COLORSPACE_SRGB_NONLINEAR_KHR             = VK_COLOR_SPACE_SRGB_NONLINEAR_KHR,
    VK_COLOR_SPACE_DCI_P3_LINEAR_EXT             = VK_COLOR_SPACE_DISPLAY_P3_LINEAR_EXT,
    VK_COLOR_SPACE_BEGIN_RANGE_KHR               = VK_COLOR_SPACE_SRGB_NONLINEAR_KHR,
    VK_COLOR_SPACE_END_RANGE_KHR                 = VK_COLOR_SPACE_SRGB_NONLINEAR_KHR,
    VK_COLOR_SPACE_RANGE_SIZE_KHR                = VK_COLOR_SPACE_SRGB_NONLINEAR_KHR - VK_COLOR_SPACE_SRGB_NONLINEAR_KHR + 1,
    VK_COLOR_SPACE_MAX_ENUM_KHR                  = 0x7FFFFFFF
}

enum VK_COLOR_SPACE_SRGB_NONLINEAR_KHR           = VkColorSpaceKHR.VK_COLOR_SPACE_SRGB_NONLINEAR_KHR;
enum VK_COLOR_SPACE_DISPLAY_P3_NONLINEAR_EXT     = VkColorSpaceKHR.VK_COLOR_SPACE_DISPLAY_P3_NONLINEAR_EXT;
enum VK_COLOR_SPACE_EXTENDED_SRGB_LINEAR_EXT     = VkColorSpaceKHR.VK_COLOR_SPACE_EXTENDED_SRGB_LINEAR_EXT;
enum VK_COLOR_SPACE_DISPLAY_P3_LINEAR_EXT        = VkColorSpaceKHR.VK_COLOR_SPACE_DISPLAY_P3_LINEAR_EXT;
enum VK_COLOR_SPACE_DCI_P3_NONLINEAR_EXT         = VkColorSpaceKHR.VK_COLOR_SPACE_DCI_P3_NONLINEAR_EXT;
enum VK_COLOR_SPACE_BT709_LINEAR_EXT             = VkColorSpaceKHR.VK_COLOR_SPACE_BT709_LINEAR_EXT;
enum VK_COLOR_SPACE_BT709_NONLINEAR_EXT          = VkColorSpaceKHR.VK_COLOR_SPACE_BT709_NONLINEAR_EXT;
enum VK_COLOR_SPACE_BT2020_LINEAR_EXT            = VkColorSpaceKHR.VK_COLOR_SPACE_BT2020_LINEAR_EXT;
enum VK_COLOR_SPACE_HDR10_ST2084_EXT             = VkColorSpaceKHR.VK_COLOR_SPACE_HDR10_ST2084_EXT;
enum VK_COLOR_SPACE_DOLBYVISION_EXT              = VkColorSpaceKHR.VK_COLOR_SPACE_DOLBYVISION_EXT;
enum VK_COLOR_SPACE_HDR10_HLG_EXT                = VkColorSpaceKHR.VK_COLOR_SPACE_HDR10_HLG_EXT;
enum VK_COLOR_SPACE_ADOBERGB_LINEAR_EXT          = VkColorSpaceKHR.VK_COLOR_SPACE_ADOBERGB_LINEAR_EXT;
enum VK_COLOR_SPACE_ADOBERGB_NONLINEAR_EXT       = VkColorSpaceKHR.VK_COLOR_SPACE_ADOBERGB_NONLINEAR_EXT;
enum VK_COLOR_SPACE_PASS_THROUGH_EXT             = VkColorSpaceKHR.VK_COLOR_SPACE_PASS_THROUGH_EXT;
enum VK_COLOR_SPACE_EXTENDED_SRGB_NONLINEAR_EXT  = VkColorSpaceKHR.VK_COLOR_SPACE_EXTENDED_SRGB_NONLINEAR_EXT;
enum VK_COLOR_SPACE_DISPLAY_NATIVE_AMD           = VkColorSpaceKHR.VK_COLOR_SPACE_DISPLAY_NATIVE_AMD;
enum VK_COLORSPACE_SRGB_NONLINEAR_KHR            = VkColorSpaceKHR.VK_COLORSPACE_SRGB_NONLINEAR_KHR;
enum VK_COLOR_SPACE_DCI_P3_LINEAR_EXT            = VkColorSpaceKHR.VK_COLOR_SPACE_DCI_P3_LINEAR_EXT;
enum VK_COLOR_SPACE_BEGIN_RANGE_KHR              = VkColorSpaceKHR.VK_COLOR_SPACE_BEGIN_RANGE_KHR;
enum VK_COLOR_SPACE_END_RANGE_KHR                = VkColorSpaceKHR.VK_COLOR_SPACE_END_RANGE_KHR;
enum VK_COLOR_SPACE_RANGE_SIZE_KHR               = VkColorSpaceKHR.VK_COLOR_SPACE_RANGE_SIZE_KHR;
enum VK_COLOR_SPACE_MAX_ENUM_KHR                 = VkColorSpaceKHR.VK_COLOR_SPACE_MAX_ENUM_KHR;

enum VkPresentModeKHR {
    VK_PRESENT_MODE_IMMEDIATE_KHR                        = 0,
    VK_PRESENT_MODE_MAILBOX_KHR                          = 1,
    VK_PRESENT_MODE_FIFO_KHR                             = 2,
    VK_PRESENT_MODE_FIFO_RELAXED_KHR                     = 3,
    VK_PRESENT_MODE_SHARED_DEMAND_REFRESH_KHR            = 1000111000,
    VK_PRESENT_MODE_SHARED_CONTINUOUS_REFRESH_KHR        = 1000111001,
    VK_PRESENT_MODE_BEGIN_RANGE_KHR                      = VK_PRESENT_MODE_IMMEDIATE_KHR,
    VK_PRESENT_MODE_END_RANGE_KHR                        = VK_PRESENT_MODE_FIFO_RELAXED_KHR,
    VK_PRESENT_MODE_RANGE_SIZE_KHR                       = VK_PRESENT_MODE_FIFO_RELAXED_KHR - VK_PRESENT_MODE_IMMEDIATE_KHR + 1,
    VK_PRESENT_MODE_MAX_ENUM_KHR                         = 0x7FFFFFFF
}

enum VK_PRESENT_MODE_IMMEDIATE_KHR                       = VkPresentModeKHR.VK_PRESENT_MODE_IMMEDIATE_KHR;
enum VK_PRESENT_MODE_MAILBOX_KHR                         = VkPresentModeKHR.VK_PRESENT_MODE_MAILBOX_KHR;
enum VK_PRESENT_MODE_FIFO_KHR                            = VkPresentModeKHR.VK_PRESENT_MODE_FIFO_KHR;
enum VK_PRESENT_MODE_FIFO_RELAXED_KHR                    = VkPresentModeKHR.VK_PRESENT_MODE_FIFO_RELAXED_KHR;
enum VK_PRESENT_MODE_SHARED_DEMAND_REFRESH_KHR           = VkPresentModeKHR.VK_PRESENT_MODE_SHARED_DEMAND_REFRESH_KHR;
enum VK_PRESENT_MODE_SHARED_CONTINUOUS_REFRESH_KHR       = VkPresentModeKHR.VK_PRESENT_MODE_SHARED_CONTINUOUS_REFRESH_KHR;
enum VK_PRESENT_MODE_BEGIN_RANGE_KHR                     = VkPresentModeKHR.VK_PRESENT_MODE_BEGIN_RANGE_KHR;
enum VK_PRESENT_MODE_END_RANGE_KHR                       = VkPresentModeKHR.VK_PRESENT_MODE_END_RANGE_KHR;
enum VK_PRESENT_MODE_RANGE_SIZE_KHR                      = VkPresentModeKHR.VK_PRESENT_MODE_RANGE_SIZE_KHR;
enum VK_PRESENT_MODE_MAX_ENUM_KHR                        = VkPresentModeKHR.VK_PRESENT_MODE_MAX_ENUM_KHR;

enum VkSurfaceTransformFlagBitsKHR {
    VK_SURFACE_TRANSFORM_IDENTITY_BIT_KHR                        = 0x00000001,
    VK_SURFACE_TRANSFORM_ROTATE_90_BIT_KHR                       = 0x00000002,
    VK_SURFACE_TRANSFORM_ROTATE_180_BIT_KHR                      = 0x00000004,
    VK_SURFACE_TRANSFORM_ROTATE_270_BIT_KHR                      = 0x00000008,
    VK_SURFACE_TRANSFORM_HORIZONTAL_MIRROR_BIT_KHR               = 0x00000010,
    VK_SURFACE_TRANSFORM_HORIZONTAL_MIRROR_ROTATE_90_BIT_KHR     = 0x00000020,
    VK_SURFACE_TRANSFORM_HORIZONTAL_MIRROR_ROTATE_180_BIT_KHR    = 0x00000040,
    VK_SURFACE_TRANSFORM_HORIZONTAL_MIRROR_ROTATE_270_BIT_KHR    = 0x00000080,
    VK_SURFACE_TRANSFORM_INHERIT_BIT_KHR                         = 0x00000100,
    VK_SURFACE_TRANSFORM_FLAG_BITS_MAX_ENUM_KHR                  = 0x7FFFFFFF
}

enum VK_SURFACE_TRANSFORM_IDENTITY_BIT_KHR                       = VkSurfaceTransformFlagBitsKHR.VK_SURFACE_TRANSFORM_IDENTITY_BIT_KHR;
enum VK_SURFACE_TRANSFORM_ROTATE_90_BIT_KHR                      = VkSurfaceTransformFlagBitsKHR.VK_SURFACE_TRANSFORM_ROTATE_90_BIT_KHR;
enum VK_SURFACE_TRANSFORM_ROTATE_180_BIT_KHR                     = VkSurfaceTransformFlagBitsKHR.VK_SURFACE_TRANSFORM_ROTATE_180_BIT_KHR;
enum VK_SURFACE_TRANSFORM_ROTATE_270_BIT_KHR                     = VkSurfaceTransformFlagBitsKHR.VK_SURFACE_TRANSFORM_ROTATE_270_BIT_KHR;
enum VK_SURFACE_TRANSFORM_HORIZONTAL_MIRROR_BIT_KHR              = VkSurfaceTransformFlagBitsKHR.VK_SURFACE_TRANSFORM_HORIZONTAL_MIRROR_BIT_KHR;
enum VK_SURFACE_TRANSFORM_HORIZONTAL_MIRROR_ROTATE_90_BIT_KHR    = VkSurfaceTransformFlagBitsKHR.VK_SURFACE_TRANSFORM_HORIZONTAL_MIRROR_ROTATE_90_BIT_KHR;
enum VK_SURFACE_TRANSFORM_HORIZONTAL_MIRROR_ROTATE_180_BIT_KHR   = VkSurfaceTransformFlagBitsKHR.VK_SURFACE_TRANSFORM_HORIZONTAL_MIRROR_ROTATE_180_BIT_KHR;
enum VK_SURFACE_TRANSFORM_HORIZONTAL_MIRROR_ROTATE_270_BIT_KHR   = VkSurfaceTransformFlagBitsKHR.VK_SURFACE_TRANSFORM_HORIZONTAL_MIRROR_ROTATE_270_BIT_KHR;
enum VK_SURFACE_TRANSFORM_INHERIT_BIT_KHR                        = VkSurfaceTransformFlagBitsKHR.VK_SURFACE_TRANSFORM_INHERIT_BIT_KHR;
enum VK_SURFACE_TRANSFORM_FLAG_BITS_MAX_ENUM_KHR                 = VkSurfaceTransformFlagBitsKHR.VK_SURFACE_TRANSFORM_FLAG_BITS_MAX_ENUM_KHR;
alias VkSurfaceTransformFlagsKHR = VkFlags;

enum VkCompositeAlphaFlagBitsKHR {
    VK_COMPOSITE_ALPHA_OPAQUE_BIT_KHR            = 0x00000001,
    VK_COMPOSITE_ALPHA_PRE_MULTIPLIED_BIT_KHR    = 0x00000002,
    VK_COMPOSITE_ALPHA_POST_MULTIPLIED_BIT_KHR   = 0x00000004,
    VK_COMPOSITE_ALPHA_INHERIT_BIT_KHR           = 0x00000008,
    VK_COMPOSITE_ALPHA_FLAG_BITS_MAX_ENUM_KHR    = 0x7FFFFFFF
}

enum VK_COMPOSITE_ALPHA_OPAQUE_BIT_KHR           = VkCompositeAlphaFlagBitsKHR.VK_COMPOSITE_ALPHA_OPAQUE_BIT_KHR;
enum VK_COMPOSITE_ALPHA_PRE_MULTIPLIED_BIT_KHR   = VkCompositeAlphaFlagBitsKHR.VK_COMPOSITE_ALPHA_PRE_MULTIPLIED_BIT_KHR;
enum VK_COMPOSITE_ALPHA_POST_MULTIPLIED_BIT_KHR  = VkCompositeAlphaFlagBitsKHR.VK_COMPOSITE_ALPHA_POST_MULTIPLIED_BIT_KHR;
enum VK_COMPOSITE_ALPHA_INHERIT_BIT_KHR          = VkCompositeAlphaFlagBitsKHR.VK_COMPOSITE_ALPHA_INHERIT_BIT_KHR;
enum VK_COMPOSITE_ALPHA_FLAG_BITS_MAX_ENUM_KHR   = VkCompositeAlphaFlagBitsKHR.VK_COMPOSITE_ALPHA_FLAG_BITS_MAX_ENUM_KHR;
alias VkCompositeAlphaFlagsKHR = VkFlags;

struct VkSurfaceCapabilitiesKHR {
    uint32_t                       minImageCount;
    uint32_t                       maxImageCount;
    VkExtent2D                     currentExtent;
    VkExtent2D                     minImageExtent;
    VkExtent2D                     maxImageExtent;
    uint32_t                       maxImageArrayLayers;
    VkSurfaceTransformFlagsKHR     supportedTransforms;
    VkSurfaceTransformFlagBitsKHR  currentTransform;
    VkCompositeAlphaFlagsKHR       supportedCompositeAlpha;
    VkImageUsageFlags              supportedUsageFlags;
}

struct VkSurfaceFormatKHR {
    VkFormat         format;
    VkColorSpaceKHR  colorSpace;
}


// - VK_KHR_swapchain -
enum VK_KHR_swapchain = 1;

mixin( VK_DEFINE_NON_DISPATCHABLE_HANDLE!q{VkSwapchainKHR} );

enum VK_KHR_SWAPCHAIN_SPEC_VERSION = 70;
enum VK_KHR_SWAPCHAIN_EXTENSION_NAME = "VK_KHR_swapchain";

enum VkSwapchainCreateFlagBitsKHR {
    VK_SWAPCHAIN_CREATE_SPLIT_INSTANCE_BIND_REGIONS_BIT_KHR      = 0x00000001,
    VK_SWAPCHAIN_CREATE_PROTECTED_BIT_KHR                        = 0x00000002,
    VK_SWAPCHAIN_CREATE_MUTABLE_FORMAT_BIT_KHR                   = 0x00000004,
    VK_SWAPCHAIN_CREATE_FLAG_BITS_MAX_ENUM_KHR                   = 0x7FFFFFFF
}

enum VK_SWAPCHAIN_CREATE_SPLIT_INSTANCE_BIND_REGIONS_BIT_KHR     = VkSwapchainCreateFlagBitsKHR.VK_SWAPCHAIN_CREATE_SPLIT_INSTANCE_BIND_REGIONS_BIT_KHR;
enum VK_SWAPCHAIN_CREATE_PROTECTED_BIT_KHR                       = VkSwapchainCreateFlagBitsKHR.VK_SWAPCHAIN_CREATE_PROTECTED_BIT_KHR;
enum VK_SWAPCHAIN_CREATE_MUTABLE_FORMAT_BIT_KHR                  = VkSwapchainCreateFlagBitsKHR.VK_SWAPCHAIN_CREATE_MUTABLE_FORMAT_BIT_KHR;
enum VK_SWAPCHAIN_CREATE_FLAG_BITS_MAX_ENUM_KHR                  = VkSwapchainCreateFlagBitsKHR.VK_SWAPCHAIN_CREATE_FLAG_BITS_MAX_ENUM_KHR;
alias VkSwapchainCreateFlagsKHR = VkFlags;

enum VkDeviceGroupPresentModeFlagBitsKHR {
    VK_DEVICE_GROUP_PRESENT_MODE_LOCAL_BIT_KHR                   = 0x00000001,
    VK_DEVICE_GROUP_PRESENT_MODE_REMOTE_BIT_KHR                  = 0x00000002,
    VK_DEVICE_GROUP_PRESENT_MODE_SUM_BIT_KHR                     = 0x00000004,
    VK_DEVICE_GROUP_PRESENT_MODE_LOCAL_MULTI_DEVICE_BIT_KHR      = 0x00000008,
    VK_DEVICE_GROUP_PRESENT_MODE_FLAG_BITS_MAX_ENUM_KHR          = 0x7FFFFFFF
}

enum VK_DEVICE_GROUP_PRESENT_MODE_LOCAL_BIT_KHR                  = VkDeviceGroupPresentModeFlagBitsKHR.VK_DEVICE_GROUP_PRESENT_MODE_LOCAL_BIT_KHR;
enum VK_DEVICE_GROUP_PRESENT_MODE_REMOTE_BIT_KHR                 = VkDeviceGroupPresentModeFlagBitsKHR.VK_DEVICE_GROUP_PRESENT_MODE_REMOTE_BIT_KHR;
enum VK_DEVICE_GROUP_PRESENT_MODE_SUM_BIT_KHR                    = VkDeviceGroupPresentModeFlagBitsKHR.VK_DEVICE_GROUP_PRESENT_MODE_SUM_BIT_KHR;
enum VK_DEVICE_GROUP_PRESENT_MODE_LOCAL_MULTI_DEVICE_BIT_KHR     = VkDeviceGroupPresentModeFlagBitsKHR.VK_DEVICE_GROUP_PRESENT_MODE_LOCAL_MULTI_DEVICE_BIT_KHR;
enum VK_DEVICE_GROUP_PRESENT_MODE_FLAG_BITS_MAX_ENUM_KHR         = VkDeviceGroupPresentModeFlagBitsKHR.VK_DEVICE_GROUP_PRESENT_MODE_FLAG_BITS_MAX_ENUM_KHR;
alias VkDeviceGroupPresentModeFlagsKHR = VkFlags;

struct VkSwapchainCreateInfoKHR {
    VkStructureType                sType = VK_STRUCTURE_TYPE_SWAPCHAIN_CREATE_INFO_KHR;
    const( void )*                 pNext;
    VkSwapchainCreateFlagsKHR      flags;
    VkSurfaceKHR                   surface;
    uint32_t                       minImageCount;
    VkFormat                       imageFormat;
    VkColorSpaceKHR                imageColorSpace;
    VkExtent2D                     imageExtent;
    uint32_t                       imageArrayLayers;
    VkImageUsageFlags              imageUsage;
    VkSharingMode                  imageSharingMode;
    uint32_t                       queueFamilyIndexCount;
    const( uint32_t )*             pQueueFamilyIndices;
    VkSurfaceTransformFlagBitsKHR  preTransform;
    VkCompositeAlphaFlagBitsKHR    compositeAlpha;
    VkPresentModeKHR               presentMode;
    VkBool32                       clipped;
    VkSwapchainKHR                 oldSwapchain;
}

struct VkPresentInfoKHR {
    VkStructureType           sType = VK_STRUCTURE_TYPE_PRESENT_INFO_KHR;
    const( void )*            pNext;
    uint32_t                  waitSemaphoreCount;
    const( VkSemaphore )*     pWaitSemaphores;
    uint32_t                  swapchainCount;
    const( VkSwapchainKHR )*  pSwapchains;
    const( uint32_t )*        pImageIndices;
    VkResult*                 pResults;
}

struct VkImageSwapchainCreateInfoKHR {
    VkStructureType  sType = VK_STRUCTURE_TYPE_IMAGE_SWAPCHAIN_CREATE_INFO_KHR;
    const( void )*   pNext;
    VkSwapchainKHR   swapchain;
}

struct VkBindImageMemorySwapchainInfoKHR {
    VkStructureType  sType = VK_STRUCTURE_TYPE_BIND_IMAGE_MEMORY_SWAPCHAIN_INFO_KHR;
    const( void )*   pNext;
    VkSwapchainKHR   swapchain;
    uint32_t         imageIndex;
}

struct VkAcquireNextImageInfoKHR {
    VkStructureType  sType = VK_STRUCTURE_TYPE_ACQUIRE_NEXT_IMAGE_INFO_KHR;
    const( void )*   pNext;
    VkSwapchainKHR   swapchain;
    uint64_t         timeout;
    VkSemaphore      semaphore;
    VkFence          fence;
    uint32_t         deviceMask;
}

struct VkDeviceGroupPresentCapabilitiesKHR {
    VkStructureType                       sType = VK_STRUCTURE_TYPE_DEVICE_GROUP_PRESENT_CAPABILITIES_KHR;
    const( void )*                        pNext;
    uint32_t[ VK_MAX_DEVICE_GROUP_SIZE ]  presentMask;
    VkDeviceGroupPresentModeFlagsKHR      modes;
}

struct VkDeviceGroupPresentInfoKHR {
    VkStructureType                      sType = VK_STRUCTURE_TYPE_DEVICE_GROUP_PRESENT_INFO_KHR;
    const( void )*                       pNext;
    uint32_t                             swapchainCount;
    const( uint32_t )*                   pDeviceMasks;
    VkDeviceGroupPresentModeFlagBitsKHR  mode;
}

struct VkDeviceGroupSwapchainCreateInfoKHR {
    VkStructureType                   sType = VK_STRUCTURE_TYPE_DEVICE_GROUP_SWAPCHAIN_CREATE_INFO_KHR;
    const( void )*                    pNext;
    VkDeviceGroupPresentModeFlagsKHR  modes;
}


// - VK_KHR_display -
enum VK_KHR_display = 1;

mixin( VK_DEFINE_NON_DISPATCHABLE_HANDLE!q{VkDisplayKHR} );
mixin( VK_DEFINE_NON_DISPATCHABLE_HANDLE!q{VkDisplayModeKHR} );

enum VK_KHR_DISPLAY_SPEC_VERSION = 21;
enum VK_KHR_DISPLAY_EXTENSION_NAME = "VK_KHR_display";

enum VkDisplayPlaneAlphaFlagBitsKHR {
    VK_DISPLAY_PLANE_ALPHA_OPAQUE_BIT_KHR                        = 0x00000001,
    VK_DISPLAY_PLANE_ALPHA_GLOBAL_BIT_KHR                        = 0x00000002,
    VK_DISPLAY_PLANE_ALPHA_PER_PIXEL_BIT_KHR                     = 0x00000004,
    VK_DISPLAY_PLANE_ALPHA_PER_PIXEL_PREMULTIPLIED_BIT_KHR       = 0x00000008,
    VK_DISPLAY_PLANE_ALPHA_FLAG_BITS_MAX_ENUM_KHR                = 0x7FFFFFFF
}

enum VK_DISPLAY_PLANE_ALPHA_OPAQUE_BIT_KHR                       = VkDisplayPlaneAlphaFlagBitsKHR.VK_DISPLAY_PLANE_ALPHA_OPAQUE_BIT_KHR;
enum VK_DISPLAY_PLANE_ALPHA_GLOBAL_BIT_KHR                       = VkDisplayPlaneAlphaFlagBitsKHR.VK_DISPLAY_PLANE_ALPHA_GLOBAL_BIT_KHR;
enum VK_DISPLAY_PLANE_ALPHA_PER_PIXEL_BIT_KHR                    = VkDisplayPlaneAlphaFlagBitsKHR.VK_DISPLAY_PLANE_ALPHA_PER_PIXEL_BIT_KHR;
enum VK_DISPLAY_PLANE_ALPHA_PER_PIXEL_PREMULTIPLIED_BIT_KHR      = VkDisplayPlaneAlphaFlagBitsKHR.VK_DISPLAY_PLANE_ALPHA_PER_PIXEL_PREMULTIPLIED_BIT_KHR;
enum VK_DISPLAY_PLANE_ALPHA_FLAG_BITS_MAX_ENUM_KHR               = VkDisplayPlaneAlphaFlagBitsKHR.VK_DISPLAY_PLANE_ALPHA_FLAG_BITS_MAX_ENUM_KHR;
alias VkDisplayPlaneAlphaFlagsKHR = VkFlags;
alias VkDisplayModeCreateFlagsKHR = VkFlags;
alias VkDisplaySurfaceCreateFlagsKHR = VkFlags;

struct VkDisplayPropertiesKHR {
    VkDisplayKHR                display;
    const( char )*              displayName;
    VkExtent2D                  physicalDimensions;
    VkExtent2D                  physicalResolution;
    VkSurfaceTransformFlagsKHR  supportedTransforms;
    VkBool32                    planeReorderPossible;
    VkBool32                    persistentContent;
}

struct VkDisplayModeParametersKHR {
    VkExtent2D  visibleRegion;
    uint32_t    refreshRate;
}

struct VkDisplayModePropertiesKHR {
    VkDisplayModeKHR            displayMode;
    VkDisplayModeParametersKHR  parameters;
}

struct VkDisplayModeCreateInfoKHR {
    VkStructureType              sType = VK_STRUCTURE_TYPE_DISPLAY_MODE_CREATE_INFO_KHR;
    const( void )*               pNext;
    VkDisplayModeCreateFlagsKHR  flags;
    VkDisplayModeParametersKHR   parameters;
}

struct VkDisplayPlaneCapabilitiesKHR {
    VkDisplayPlaneAlphaFlagsKHR  supportedAlpha;
    VkOffset2D                   minSrcPosition;
    VkOffset2D                   maxSrcPosition;
    VkExtent2D                   minSrcExtent;
    VkExtent2D                   maxSrcExtent;
    VkOffset2D                   minDstPosition;
    VkOffset2D                   maxDstPosition;
    VkExtent2D                   minDstExtent;
    VkExtent2D                   maxDstExtent;
}

struct VkDisplayPlanePropertiesKHR {
    VkDisplayKHR  currentDisplay;
    uint32_t      currentStackIndex;
}

struct VkDisplaySurfaceCreateInfoKHR {
    VkStructureType                 sType = VK_STRUCTURE_TYPE_DISPLAY_SURFACE_CREATE_INFO_KHR;
    const( void )*                  pNext;
    VkDisplaySurfaceCreateFlagsKHR  flags;
    VkDisplayModeKHR                displayMode;
    uint32_t                        planeIndex;
    uint32_t                        planeStackIndex;
    VkSurfaceTransformFlagBitsKHR   transform;
    float                           globalAlpha;
    VkDisplayPlaneAlphaFlagBitsKHR  alphaMode;
    VkExtent2D                      imageExtent;
}


// - VK_KHR_display_swapchain -
enum VK_KHR_display_swapchain = 1;

enum VK_KHR_DISPLAY_SWAPCHAIN_SPEC_VERSION = 9;
enum VK_KHR_DISPLAY_SWAPCHAIN_EXTENSION_NAME = "VK_KHR_display_swapchain";

struct VkDisplayPresentInfoKHR {
    VkStructureType  sType = VK_STRUCTURE_TYPE_DISPLAY_PRESENT_INFO_KHR;
    const( void )*   pNext;
    VkRect2D         srcRect;
    VkRect2D         dstRect;
    VkBool32         persistent;
}


// - VK_KHR_sampler_mirror_clamp_to_edge -
enum VK_KHR_sampler_mirror_clamp_to_edge = 1;

enum VK_KHR_SAMPLER_MIRROR_CLAMP_TO_EDGE_SPEC_VERSION = 1;
enum VK_KHR_SAMPLER_MIRROR_CLAMP_TO_EDGE_EXTENSION_NAME = "VK_KHR_sampler_mirror_clamp_to_edge";


// - VK_KHR_multiview -
enum VK_KHR_multiview = 1;

enum VK_KHR_MULTIVIEW_SPEC_VERSION = 1;
enum VK_KHR_MULTIVIEW_EXTENSION_NAME = "VK_KHR_multiview";

alias VkRenderPassMultiviewCreateInfoKHR = VkRenderPassMultiviewCreateInfo;
alias VkPhysicalDeviceMultiviewFeaturesKHR = VkPhysicalDeviceMultiviewFeatures;
alias VkPhysicalDeviceMultiviewPropertiesKHR = VkPhysicalDeviceMultiviewProperties;


// - VK_KHR_get_physical_device_properties2 -
enum VK_KHR_get_physical_device_properties2 = 1;

enum VK_KHR_GET_PHYSICAL_DEVICE_PROPERTIES_2_SPEC_VERSION = 1;
enum VK_KHR_GET_PHYSICAL_DEVICE_PROPERTIES_2_EXTENSION_NAME = "VK_KHR_get_physical_device_properties2";

alias VkPhysicalDeviceFeatures2KHR = VkPhysicalDeviceFeatures2;
alias VkPhysicalDeviceProperties2KHR = VkPhysicalDeviceProperties2;
alias VkFormatProperties2KHR = VkFormatProperties2;
alias VkImageFormatProperties2KHR = VkImageFormatProperties2;
alias VkPhysicalDeviceImageFormatInfo2KHR = VkPhysicalDeviceImageFormatInfo2;
alias VkQueueFamilyProperties2KHR = VkQueueFamilyProperties2;
alias VkPhysicalDeviceMemoryProperties2KHR = VkPhysicalDeviceMemoryProperties2;
alias VkSparseImageFormatProperties2KHR = VkSparseImageFormatProperties2;
alias VkPhysicalDeviceSparseImageFormatInfo2KHR = VkPhysicalDeviceSparseImageFormatInfo2;


// - VK_KHR_device_group -
enum VK_KHR_device_group = 1;

enum VK_KHR_DEVICE_GROUP_SPEC_VERSION = 3;
enum VK_KHR_DEVICE_GROUP_EXTENSION_NAME = "VK_KHR_device_group";

alias VkPeerMemoryFeatureFlagsKHR = VkPeerMemoryFeatureFlags;
alias VkPeerMemoryFeatureFlagBitsKHR = VkPeerMemoryFeatureFlagBits;
alias VkMemoryAllocateFlagsKHR = VkMemoryAllocateFlags;
alias VkMemoryAllocateFlagBitsKHR = VkMemoryAllocateFlagBits;

alias VkMemoryAllocateFlagsInfoKHR = VkMemoryAllocateFlagsInfo;
alias VkDeviceGroupRenderPassBeginInfoKHR = VkDeviceGroupRenderPassBeginInfo;
alias VkDeviceGroupCommandBufferBeginInfoKHR = VkDeviceGroupCommandBufferBeginInfo;
alias VkDeviceGroupSubmitInfoKHR = VkDeviceGroupSubmitInfo;
alias VkDeviceGroupBindSparseInfoKHR = VkDeviceGroupBindSparseInfo;
alias VkBindBufferMemoryDeviceGroupInfoKHR = VkBindBufferMemoryDeviceGroupInfo;
alias VkBindImageMemoryDeviceGroupInfoKHR = VkBindImageMemoryDeviceGroupInfo;


// - VK_KHR_shader_draw_parameters -
enum VK_KHR_shader_draw_parameters = 1;

enum VK_KHR_SHADER_DRAW_PARAMETERS_SPEC_VERSION = 1;
enum VK_KHR_SHADER_DRAW_PARAMETERS_EXTENSION_NAME = "VK_KHR_shader_draw_parameters";


// - VK_KHR_maintenance1 -
enum VK_KHR_maintenance1 = 1;

enum VK_KHR_MAINTENANCE1_SPEC_VERSION = 2;
enum VK_KHR_MAINTENANCE1_EXTENSION_NAME = "VK_KHR_maintenance1";

alias VkCommandPoolTrimFlagsKHR = VkCommandPoolTrimFlags;


// - VK_KHR_device_group_creation -
enum VK_KHR_device_group_creation = 1;

enum VK_KHR_DEVICE_GROUP_CREATION_SPEC_VERSION = 1;
enum VK_KHR_DEVICE_GROUP_CREATION_EXTENSION_NAME = "VK_KHR_device_group_creation";
alias VK_MAX_DEVICE_GROUP_SIZE_KHR = VK_MAX_DEVICE_GROUP_SIZE;

alias VkPhysicalDeviceGroupPropertiesKHR = VkPhysicalDeviceGroupProperties;
alias VkDeviceGroupDeviceCreateInfoKHR = VkDeviceGroupDeviceCreateInfo;


// - VK_KHR_external_memory_capabilities -
enum VK_KHR_external_memory_capabilities = 1;

enum VK_KHR_EXTERNAL_MEMORY_CAPABILITIES_SPEC_VERSION = 1;
enum VK_KHR_EXTERNAL_MEMORY_CAPABILITIES_EXTENSION_NAME = "VK_KHR_external_memory_capabilities";
alias VK_LUID_SIZE_KHR = VK_LUID_SIZE;

alias VkExternalMemoryHandleTypeFlagsKHR = VkExternalMemoryHandleTypeFlags;
alias VkExternalMemoryHandleTypeFlagBitsKHR = VkExternalMemoryHandleTypeFlagBits;
alias VkExternalMemoryFeatureFlagsKHR = VkExternalMemoryFeatureFlags;
alias VkExternalMemoryFeatureFlagBitsKHR = VkExternalMemoryFeatureFlagBits;

alias VkExternalMemoryPropertiesKHR = VkExternalMemoryProperties;
alias VkPhysicalDeviceExternalImageFormatInfoKHR = VkPhysicalDeviceExternalImageFormatInfo;
alias VkExternalImageFormatPropertiesKHR = VkExternalImageFormatProperties;
alias VkPhysicalDeviceExternalBufferInfoKHR = VkPhysicalDeviceExternalBufferInfo;
alias VkExternalBufferPropertiesKHR = VkExternalBufferProperties;
alias VkPhysicalDeviceIDPropertiesKHR = VkPhysicalDeviceIDProperties;


// - VK_KHR_external_memory -
enum VK_KHR_external_memory = 1;

enum VK_KHR_EXTERNAL_MEMORY_SPEC_VERSION = 1;
enum VK_KHR_EXTERNAL_MEMORY_EXTENSION_NAME = "VK_KHR_external_memory";
alias VK_QUEUE_FAMILY_EXTERNAL_KHR = VK_QUEUE_FAMILY_EXTERNAL;

alias VkExternalMemoryImageCreateInfoKHR = VkExternalMemoryImageCreateInfo;
alias VkExternalMemoryBufferCreateInfoKHR = VkExternalMemoryBufferCreateInfo;
alias VkExportMemoryAllocateInfoKHR = VkExportMemoryAllocateInfo;


// - VK_KHR_external_memory_fd -
enum VK_KHR_external_memory_fd = 1;

enum VK_KHR_EXTERNAL_MEMORY_FD_SPEC_VERSION = 1;
enum VK_KHR_EXTERNAL_MEMORY_FD_EXTENSION_NAME = "VK_KHR_external_memory_fd";

struct VkImportMemoryFdInfoKHR {
    VkStructureType                     sType = VK_STRUCTURE_TYPE_IMPORT_MEMORY_FD_INFO_KHR;
    const( void )*                      pNext;
    VkExternalMemoryHandleTypeFlagBits  handleType;
    int                                 fd;
}

struct VkMemoryFdPropertiesKHR {
    VkStructureType  sType = VK_STRUCTURE_TYPE_MEMORY_FD_PROPERTIES_KHR;
    void*            pNext;
    uint32_t         memoryTypeBits;
}

struct VkMemoryGetFdInfoKHR {
    VkStructureType                     sType = VK_STRUCTURE_TYPE_MEMORY_GET_FD_INFO_KHR;
    const( void )*                      pNext;
    VkDeviceMemory                      memory;
    VkExternalMemoryHandleTypeFlagBits  handleType;
}


// - VK_KHR_external_semaphore_capabilities -
enum VK_KHR_external_semaphore_capabilities = 1;

enum VK_KHR_EXTERNAL_SEMAPHORE_CAPABILITIES_SPEC_VERSION = 1;
enum VK_KHR_EXTERNAL_SEMAPHORE_CAPABILITIES_EXTENSION_NAME = "VK_KHR_external_semaphore_capabilities";

alias VkExternalSemaphoreHandleTypeFlagsKHR = VkExternalSemaphoreHandleTypeFlags;
alias VkExternalSemaphoreHandleTypeFlagBitsKHR = VkExternalSemaphoreHandleTypeFlagBits;
alias VkExternalSemaphoreFeatureFlagsKHR = VkExternalSemaphoreFeatureFlags;
alias VkExternalSemaphoreFeatureFlagBitsKHR = VkExternalSemaphoreFeatureFlagBits;

alias VkPhysicalDeviceExternalSemaphoreInfoKHR = VkPhysicalDeviceExternalSemaphoreInfo;
alias VkExternalSemaphorePropertiesKHR = VkExternalSemaphoreProperties;


// - VK_KHR_external_semaphore -
enum VK_KHR_external_semaphore = 1;

enum VK_KHR_EXTERNAL_SEMAPHORE_SPEC_VERSION = 1;
enum VK_KHR_EXTERNAL_SEMAPHORE_EXTENSION_NAME = "VK_KHR_external_semaphore";

alias VkSemaphoreImportFlagsKHR = VkSemaphoreImportFlags;
alias VkSemaphoreImportFlagBitsKHR = VkSemaphoreImportFlagBits;

alias VkExportSemaphoreCreateInfoKHR = VkExportSemaphoreCreateInfo;


// - VK_KHR_external_semaphore_fd -
enum VK_KHR_external_semaphore_fd = 1;

enum VK_KHR_EXTERNAL_SEMAPHORE_FD_SPEC_VERSION = 1;
enum VK_KHR_EXTERNAL_SEMAPHORE_FD_EXTENSION_NAME = "VK_KHR_external_semaphore_fd";

struct VkImportSemaphoreFdInfoKHR {
    VkStructureType                        sType = VK_STRUCTURE_TYPE_IMPORT_SEMAPHORE_FD_INFO_KHR;
    const( void )*                         pNext;
    VkSemaphore                            semaphore;
    VkSemaphoreImportFlags                 flags;
    VkExternalSemaphoreHandleTypeFlagBits  handleType;
    int                                    fd;
}

struct VkSemaphoreGetFdInfoKHR {
    VkStructureType                        sType = VK_STRUCTURE_TYPE_SEMAPHORE_GET_FD_INFO_KHR;
    const( void )*                         pNext;
    VkSemaphore                            semaphore;
    VkExternalSemaphoreHandleTypeFlagBits  handleType;
}


// - VK_KHR_push_descriptor -
enum VK_KHR_push_descriptor = 1;

enum VK_KHR_PUSH_DESCRIPTOR_SPEC_VERSION = 2;
enum VK_KHR_PUSH_DESCRIPTOR_EXTENSION_NAME = "VK_KHR_push_descriptor";

struct VkPhysicalDevicePushDescriptorPropertiesKHR {
    VkStructureType  sType = VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_PUSH_DESCRIPTOR_PROPERTIES_KHR;
    void*            pNext;
    uint32_t         maxPushDescriptors;
}


// - VK_KHR_shader_float16_int8 -
enum VK_KHR_shader_float16_int8 = 1;

enum VK_KHR_SHADER_FLOAT16_INT8_SPEC_VERSION = 1;
enum VK_KHR_SHADER_FLOAT16_INT8_EXTENSION_NAME = "VK_KHR_shader_float16_int8";

struct VkPhysicalDeviceFloat16Int8FeaturesKHR {
    VkStructureType  sType = VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_FLOAT16_INT8_FEATURES_KHR;
    void*            pNext;
    VkBool32         shaderFloat16;
    VkBool32         shaderInt8;
}


// - VK_KHR_16bit_storage -
enum VK_KHR_16bit_storage = 1;

enum VK_KHR_16BIT_STORAGE_SPEC_VERSION = 1;
enum VK_KHR_16BIT_STORAGE_EXTENSION_NAME = "VK_KHR_16bit_storage";

alias VkPhysicalDevice16BitStorageFeaturesKHR = VkPhysicalDevice16BitStorageFeatures;


// - VK_KHR_incremental_present -
enum VK_KHR_incremental_present = 1;

enum VK_KHR_INCREMENTAL_PRESENT_SPEC_VERSION = 1;
enum VK_KHR_INCREMENTAL_PRESENT_EXTENSION_NAME = "VK_KHR_incremental_present";

struct VkRectLayerKHR {
    VkOffset2D  offset;
    VkExtent2D  extent;
    uint32_t    layer;
}

struct VkPresentRegionKHR {
    uint32_t                  rectangleCount;
    const( VkRectLayerKHR )*  pRectangles;
}

struct VkPresentRegionsKHR {
    VkStructureType               sType = VK_STRUCTURE_TYPE_PRESENT_REGIONS_KHR;
    const( void )*                pNext;
    uint32_t                      swapchainCount;
    const( VkPresentRegionKHR )*  pRegions;
}


// - VK_KHR_descriptor_update_template -
enum VK_KHR_descriptor_update_template = 1;

alias VkDescriptorUpdateTemplateKHR = VkDescriptorUpdateTemplate;

alias VkDescriptorUpdateTemplateTypeKHR = VkDescriptorUpdateTemplateType;
enum VK_KHR_DESCRIPTOR_UPDATE_TEMPLATE_SPEC_VERSION = 1;
enum VK_KHR_DESCRIPTOR_UPDATE_TEMPLATE_EXTENSION_NAME = "VK_KHR_descriptor_update_template";

alias VkDescriptorUpdateTemplateCreateFlagsKHR = VkDescriptorUpdateTemplateCreateFlags;

alias VkDescriptorUpdateTemplateEntryKHR = VkDescriptorUpdateTemplateEntry;
alias VkDescriptorUpdateTemplateCreateInfoKHR = VkDescriptorUpdateTemplateCreateInfo;


// - VK_KHR_create_renderpass2 -
enum VK_KHR_create_renderpass2 = 1;

enum VK_KHR_CREATE_RENDERPASS_2_SPEC_VERSION = 1;
enum VK_KHR_CREATE_RENDERPASS_2_EXTENSION_NAME = "VK_KHR_create_renderpass2";

struct VkAttachmentDescription2KHR {
    VkStructureType               sType = VK_STRUCTURE_TYPE_ATTACHMENT_DESCRIPTION_2_KHR;
    const( void )*                pNext;
    VkAttachmentDescriptionFlags  flags;
    VkFormat                      format;
    VkSampleCountFlagBits         samples;
    VkAttachmentLoadOp            loadOp;
    VkAttachmentStoreOp           storeOp;
    VkAttachmentLoadOp            stencilLoadOp;
    VkAttachmentStoreOp           stencilStoreOp;
    VkImageLayout                 initialLayout;
    VkImageLayout                 finalLayout;
}

struct VkAttachmentReference2KHR {
    VkStructureType     sType = VK_STRUCTURE_TYPE_ATTACHMENT_REFERENCE_2_KHR;
    const( void )*      pNext;
    uint32_t            attachment;
    VkImageLayout       layout;
    VkImageAspectFlags  aspectMask;
}

struct VkSubpassDescription2KHR {
    VkStructureType                      sType = VK_STRUCTURE_TYPE_SUBPASS_DESCRIPTION_2_KHR;
    const( void )*                       pNext;
    VkSubpassDescriptionFlags            flags;
    VkPipelineBindPoint                  pipelineBindPoint;
    uint32_t                             viewMask;
    uint32_t                             inputAttachmentCount;
    const( VkAttachmentReference2KHR )*  pInputAttachments;
    uint32_t                             colorAttachmentCount;
    const( VkAttachmentReference2KHR )*  pColorAttachments;
    const( VkAttachmentReference2KHR )*  pResolveAttachments;
    const( VkAttachmentReference2KHR )*  pDepthStencilAttachment;
    uint32_t                             preserveAttachmentCount;
    const( uint32_t )*                   pPreserveAttachments;
}

struct VkSubpassDependency2KHR {
    VkStructureType       sType = VK_STRUCTURE_TYPE_SUBPASS_DEPENDENCY_2_KHR;
    const( void )*        pNext;
    uint32_t              srcSubpass;
    uint32_t              dstSubpass;
    VkPipelineStageFlags  srcStageMask;
    VkPipelineStageFlags  dstStageMask;
    VkAccessFlags         srcAccessMask;
    VkAccessFlags         dstAccessMask;
    VkDependencyFlags     dependencyFlags;
    int32_t               viewOffset;
}

struct VkRenderPassCreateInfo2KHR {
    VkStructureType                        sType = VK_STRUCTURE_TYPE_RENDER_PASS_CREATE_INFO_2_KHR;
    const( void )*                         pNext;
    VkRenderPassCreateFlags                flags;
    uint32_t                               attachmentCount;
    const( VkAttachmentDescription2KHR )*  pAttachments;
    uint32_t                               subpassCount;
    const( VkSubpassDescription2KHR )*     pSubpasses;
    uint32_t                               dependencyCount;
    const( VkSubpassDependency2KHR )*      pDependencies;
    uint32_t                               correlatedViewMaskCount;
    const( uint32_t )*                     pCorrelatedViewMasks;
}

struct VkSubpassBeginInfoKHR {
    VkStructureType    sType = VK_STRUCTURE_TYPE_SUBPASS_BEGIN_INFO_KHR;
    const( void )*     pNext;
    VkSubpassContents  contents;
}

struct VkSubpassEndInfoKHR {
    VkStructureType  sType = VK_STRUCTURE_TYPE_SUBPASS_END_INFO_KHR;
    const( void )*   pNext;
}


// - VK_KHR_shared_presentable_image -
enum VK_KHR_shared_presentable_image = 1;

enum VK_KHR_SHARED_PRESENTABLE_IMAGE_SPEC_VERSION = 1;
enum VK_KHR_SHARED_PRESENTABLE_IMAGE_EXTENSION_NAME = "VK_KHR_shared_presentable_image";

struct VkSharedPresentSurfaceCapabilitiesKHR {
    VkStructureType    sType = VK_STRUCTURE_TYPE_SHARED_PRESENT_SURFACE_CAPABILITIES_KHR;
    void*              pNext;
    VkImageUsageFlags  sharedPresentSupportedUsageFlags;
}


// - VK_KHR_external_fence_capabilities -
enum VK_KHR_external_fence_capabilities = 1;

enum VK_KHR_EXTERNAL_FENCE_CAPABILITIES_SPEC_VERSION = 1;
enum VK_KHR_EXTERNAL_FENCE_CAPABILITIES_EXTENSION_NAME = "VK_KHR_external_fence_capabilities";

alias VkExternalFenceHandleTypeFlagsKHR = VkExternalFenceHandleTypeFlags;
alias VkExternalFenceHandleTypeFlagBitsKHR = VkExternalFenceHandleTypeFlagBits;
alias VkExternalFenceFeatureFlagsKHR = VkExternalFenceFeatureFlags;
alias VkExternalFenceFeatureFlagBitsKHR = VkExternalFenceFeatureFlagBits;

alias VkPhysicalDeviceExternalFenceInfoKHR = VkPhysicalDeviceExternalFenceInfo;
alias VkExternalFencePropertiesKHR = VkExternalFenceProperties;


// - VK_KHR_external_fence -
enum VK_KHR_external_fence = 1;

enum VK_KHR_EXTERNAL_FENCE_SPEC_VERSION = 1;
enum VK_KHR_EXTERNAL_FENCE_EXTENSION_NAME = "VK_KHR_external_fence";

alias VkFenceImportFlagsKHR = VkFenceImportFlags;
alias VkFenceImportFlagBitsKHR = VkFenceImportFlagBits;

alias VkExportFenceCreateInfoKHR = VkExportFenceCreateInfo;


// - VK_KHR_external_fence_fd -
enum VK_KHR_external_fence_fd = 1;

enum VK_KHR_EXTERNAL_FENCE_FD_SPEC_VERSION = 1;
enum VK_KHR_EXTERNAL_FENCE_FD_EXTENSION_NAME = "VK_KHR_external_fence_fd";

struct VkImportFenceFdInfoKHR {
    VkStructureType                    sType = VK_STRUCTURE_TYPE_IMPORT_FENCE_FD_INFO_KHR;
    const( void )*                     pNext;
    VkFence                            fence;
    VkFenceImportFlags                 flags;
    VkExternalFenceHandleTypeFlagBits  handleType;
    int                                fd;
}

struct VkFenceGetFdInfoKHR {
    VkStructureType                    sType = VK_STRUCTURE_TYPE_FENCE_GET_FD_INFO_KHR;
    const( void )*                     pNext;
    VkFence                            fence;
    VkExternalFenceHandleTypeFlagBits  handleType;
}


// - VK_KHR_maintenance2 -
enum VK_KHR_maintenance2 = 1;

alias VkPointClippingBehaviorKHR = VkPointClippingBehavior;
alias VkTessellationDomainOriginKHR = VkTessellationDomainOrigin;
enum VK_KHR_MAINTENANCE2_SPEC_VERSION = 1;
enum VK_KHR_MAINTENANCE2_EXTENSION_NAME = "VK_KHR_maintenance2";

alias VkPhysicalDevicePointClippingPropertiesKHR = VkPhysicalDevicePointClippingProperties;
alias VkRenderPassInputAttachmentAspectCreateInfoKHR = VkRenderPassInputAttachmentAspectCreateInfo;
alias VkInputAttachmentAspectReferenceKHR = VkInputAttachmentAspectReference;
alias VkImageViewUsageCreateInfoKHR = VkImageViewUsageCreateInfo;
alias VkPipelineTessellationDomainOriginStateCreateInfoKHR = VkPipelineTessellationDomainOriginStateCreateInfo;


// - VK_KHR_get_surface_capabilities2 -
enum VK_KHR_get_surface_capabilities2 = 1;

enum VK_KHR_GET_SURFACE_CAPABILITIES_2_SPEC_VERSION = 1;
enum VK_KHR_GET_SURFACE_CAPABILITIES_2_EXTENSION_NAME = "VK_KHR_get_surface_capabilities2";

struct VkPhysicalDeviceSurfaceInfo2KHR {
    VkStructureType  sType = VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_SURFACE_INFO_2_KHR;
    const( void )*   pNext;
    VkSurfaceKHR     surface;
}

struct VkSurfaceCapabilities2KHR {
    VkStructureType           sType = VK_STRUCTURE_TYPE_SURFACE_CAPABILITIES_2_KHR;
    void*                     pNext;
    VkSurfaceCapabilitiesKHR  surfaceCapabilities;
}

struct VkSurfaceFormat2KHR {
    VkStructureType     sType = VK_STRUCTURE_TYPE_SURFACE_FORMAT_2_KHR;
    void*               pNext;
    VkSurfaceFormatKHR  surfaceFormat;
}


// - VK_KHR_variable_pointers -
enum VK_KHR_variable_pointers = 1;

enum VK_KHR_VARIABLE_POINTERS_SPEC_VERSION = 1;
enum VK_KHR_VARIABLE_POINTERS_EXTENSION_NAME = "VK_KHR_variable_pointers";

alias VkPhysicalDeviceVariablePointerFeaturesKHR = VkPhysicalDeviceVariablePointersFeatures;
alias VkPhysicalDeviceVariablePointersFeaturesKHR = VkPhysicalDeviceVariablePointersFeatures;


// - VK_KHR_get_display_properties2 -
enum VK_KHR_get_display_properties2 = 1;

enum VK_KHR_GET_DISPLAY_PROPERTIES_2_SPEC_VERSION = 1;
enum VK_KHR_GET_DISPLAY_PROPERTIES_2_EXTENSION_NAME = "VK_KHR_get_display_properties2";

struct VkDisplayProperties2KHR {
    VkStructureType         sType = VK_STRUCTURE_TYPE_DISPLAY_PROPERTIES_2_KHR;
    void*                   pNext;
    VkDisplayPropertiesKHR  displayProperties;
}

struct VkDisplayPlaneProperties2KHR {
    VkStructureType              sType = VK_STRUCTURE_TYPE_DISPLAY_PLANE_PROPERTIES_2_KHR;
    void*                        pNext;
    VkDisplayPlanePropertiesKHR  displayPlaneProperties;
}

struct VkDisplayModeProperties2KHR {
    VkStructureType             sType = VK_STRUCTURE_TYPE_DISPLAY_MODE_PROPERTIES_2_KHR;
    void*                       pNext;
    VkDisplayModePropertiesKHR  displayModeProperties;
}

struct VkDisplayPlaneInfo2KHR {
    VkStructureType   sType = VK_STRUCTURE_TYPE_DISPLAY_PLANE_INFO_2_KHR;
    const( void )*    pNext;
    VkDisplayModeKHR  mode;
    uint32_t          planeIndex;
}

struct VkDisplayPlaneCapabilities2KHR {
    VkStructureType                sType = VK_STRUCTURE_TYPE_DISPLAY_PLANE_CAPABILITIES_2_KHR;
    void*                          pNext;
    VkDisplayPlaneCapabilitiesKHR  capabilities;
}


// - VK_KHR_dedicated_allocation -
enum VK_KHR_dedicated_allocation = 1;

enum VK_KHR_DEDICATED_ALLOCATION_SPEC_VERSION = 3;
enum VK_KHR_DEDICATED_ALLOCATION_EXTENSION_NAME = "VK_KHR_dedicated_allocation";

alias VkMemoryDedicatedRequirementsKHR = VkMemoryDedicatedRequirements;
alias VkMemoryDedicatedAllocateInfoKHR = VkMemoryDedicatedAllocateInfo;


// - VK_KHR_storage_buffer_storage_class -
enum VK_KHR_storage_buffer_storage_class = 1;

enum VK_KHR_STORAGE_BUFFER_STORAGE_CLASS_SPEC_VERSION = 1;
enum VK_KHR_STORAGE_BUFFER_STORAGE_CLASS_EXTENSION_NAME = "VK_KHR_storage_buffer_storage_class";


// - VK_KHR_relaxed_block_layout -
enum VK_KHR_relaxed_block_layout = 1;

enum VK_KHR_RELAXED_BLOCK_LAYOUT_SPEC_VERSION = 1;
enum VK_KHR_RELAXED_BLOCK_LAYOUT_EXTENSION_NAME = "VK_KHR_relaxed_block_layout";


// - VK_KHR_get_memory_requirements2 -
enum VK_KHR_get_memory_requirements2 = 1;

enum VK_KHR_GET_MEMORY_REQUIREMENTS_2_SPEC_VERSION = 1;
enum VK_KHR_GET_MEMORY_REQUIREMENTS_2_EXTENSION_NAME = "VK_KHR_get_memory_requirements2";

alias VkBufferMemoryRequirementsInfo2KHR = VkBufferMemoryRequirementsInfo2;
alias VkImageMemoryRequirementsInfo2KHR = VkImageMemoryRequirementsInfo2;
alias VkImageSparseMemoryRequirementsInfo2KHR = VkImageSparseMemoryRequirementsInfo2;
alias VkSparseImageMemoryRequirements2KHR = VkSparseImageMemoryRequirements2;


// - VK_KHR_image_format_list -
enum VK_KHR_image_format_list = 1;

enum VK_KHR_IMAGE_FORMAT_LIST_SPEC_VERSION = 1;
enum VK_KHR_IMAGE_FORMAT_LIST_EXTENSION_NAME = "VK_KHR_image_format_list";

struct VkImageFormatListCreateInfoKHR {
    VkStructureType     sType = VK_STRUCTURE_TYPE_IMAGE_FORMAT_LIST_CREATE_INFO_KHR;
    const( void )*      pNext;
    uint32_t            viewFormatCount;
    const( VkFormat )*  pViewFormats;
}


// - VK_KHR_sampler_ycbcr_conversion -
enum VK_KHR_sampler_ycbcr_conversion = 1;

alias VkSamplerYcbcrConversionKHR = VkSamplerYcbcrConversion;

alias VkSamplerYcbcrModelConversionKHR = VkSamplerYcbcrModelConversion;
alias VkSamplerYcbcrRangeKHR = VkSamplerYcbcrRange;
alias VkChromaLocationKHR = VkChromaLocation;
enum VK_KHR_SAMPLER_YCBCR_CONVERSION_SPEC_VERSION = 1;
enum VK_KHR_SAMPLER_YCBCR_CONVERSION_EXTENSION_NAME = "VK_KHR_sampler_ycbcr_conversion";

alias VkSamplerYcbcrConversionCreateInfoKHR = VkSamplerYcbcrConversionCreateInfo;
alias VkSamplerYcbcrConversionInfoKHR = VkSamplerYcbcrConversionInfo;
alias VkBindImagePlaneMemoryInfoKHR = VkBindImagePlaneMemoryInfo;
alias VkImagePlaneMemoryRequirementsInfoKHR = VkImagePlaneMemoryRequirementsInfo;
alias VkPhysicalDeviceSamplerYcbcrConversionFeaturesKHR = VkPhysicalDeviceSamplerYcbcrConversionFeatures;
alias VkSamplerYcbcrConversionImageFormatPropertiesKHR = VkSamplerYcbcrConversionImageFormatProperties;


// - VK_KHR_bind_memory2 -
enum VK_KHR_bind_memory2 = 1;

enum VK_KHR_BIND_MEMORY_2_SPEC_VERSION = 1;
enum VK_KHR_BIND_MEMORY_2_EXTENSION_NAME = "VK_KHR_bind_memory2";

alias VkBindBufferMemoryInfoKHR = VkBindBufferMemoryInfo;
alias VkBindImageMemoryInfoKHR = VkBindImageMemoryInfo;


// - VK_KHR_maintenance3 -
enum VK_KHR_maintenance3 = 1;

enum VK_KHR_MAINTENANCE3_SPEC_VERSION = 1;
enum VK_KHR_MAINTENANCE3_EXTENSION_NAME = "VK_KHR_maintenance3";

alias VkPhysicalDeviceMaintenance3PropertiesKHR = VkPhysicalDeviceMaintenance3Properties;
alias VkDescriptorSetLayoutSupportKHR = VkDescriptorSetLayoutSupport;


// - VK_KHR_draw_indirect_count -
enum VK_KHR_draw_indirect_count = 1;

enum VK_KHR_DRAW_INDIRECT_COUNT_SPEC_VERSION = 1;
enum VK_KHR_DRAW_INDIRECT_COUNT_EXTENSION_NAME = "VK_KHR_draw_indirect_count";


// - VK_KHR_8bit_storage -
enum VK_KHR_8bit_storage = 1;

enum VK_KHR_8BIT_STORAGE_SPEC_VERSION = 1;
enum VK_KHR_8BIT_STORAGE_EXTENSION_NAME = "VK_KHR_8bit_storage";

struct VkPhysicalDevice8BitStorageFeaturesKHR {
    VkStructureType  sType = VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_8BIT_STORAGE_FEATURES_KHR;
    void*            pNext;
    VkBool32         storageBuffer8BitAccess;
    VkBool32         uniformAndStorageBuffer8BitAccess;
    VkBool32         storagePushConstant8;
}


// - VK_KHR_shader_atomic_int64 -
enum VK_KHR_shader_atomic_int64 = 1;

enum VK_KHR_SHADER_ATOMIC_INT64_SPEC_VERSION = 1;
enum VK_KHR_SHADER_ATOMIC_INT64_EXTENSION_NAME = "VK_KHR_shader_atomic_int64";

struct VkPhysicalDeviceShaderAtomicInt64FeaturesKHR {
    VkStructureType  sType = VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_SHADER_ATOMIC_INT64_FEATURES_KHR;
    void*            pNext;
    VkBool32         shaderBufferInt64Atomics;
    VkBool32         shaderSharedInt64Atomics;
}


// - VK_KHR_driver_properties -
enum VK_KHR_driver_properties = 1;

enum VK_MAX_DRIVER_NAME_SIZE_KHR = 256;
enum VK_MAX_DRIVER_INFO_SIZE_KHR = 256;
enum VK_KHR_DRIVER_PROPERTIES_SPEC_VERSION = 1;
enum VK_KHR_DRIVER_PROPERTIES_EXTENSION_NAME = "VK_KHR_driver_properties";

enum VkDriverIdKHR {
    VK_DRIVER_ID_AMD_PROPRIETARY_KHR             = 1,
    VK_DRIVER_ID_AMD_OPEN_SOURCE_KHR             = 2,
    VK_DRIVER_ID_MESA_RADV_KHR                   = 3,
    VK_DRIVER_ID_NVIDIA_PROPRIETARY_KHR          = 4,
    VK_DRIVER_ID_INTEL_PROPRIETARY_WINDOWS_KHR   = 5,
    VK_DRIVER_ID_INTEL_OPEN_SOURCE_MESA_KHR      = 6,
    VK_DRIVER_ID_IMAGINATION_PROPRIETARY_KHR     = 7,
    VK_DRIVER_ID_QUALCOMM_PROPRIETARY_KHR        = 8,
    VK_DRIVER_ID_ARM_PROPRIETARY_KHR             = 9,
    VK_DRIVER_ID_GOOGLE_SWIFTSHADER_KHR          = 10,
    VK_DRIVER_ID_GGP_PROPRIETARY_KHR             = 11,
    VK_DRIVER_IDKHR_BEGIN_RANGE_KHR              = VK_DRIVER_ID_AMD_PROPRIETARY_KHR,
    VK_DRIVER_IDKHR_END_RANGE_KHR                = VK_DRIVER_ID_GGP_PROPRIETARY_KHR,
    VK_DRIVER_IDKHR_RANGE_SIZE_KHR               = VK_DRIVER_ID_GGP_PROPRIETARY_KHR - VK_DRIVER_ID_AMD_PROPRIETARY_KHR + 1,
    VK_DRIVER_IDKHR_MAX_ENUM_KHR                 = 0x7FFFFFFF
}

enum VK_DRIVER_ID_AMD_PROPRIETARY_KHR            = VkDriverIdKHR.VK_DRIVER_ID_AMD_PROPRIETARY_KHR;
enum VK_DRIVER_ID_AMD_OPEN_SOURCE_KHR            = VkDriverIdKHR.VK_DRIVER_ID_AMD_OPEN_SOURCE_KHR;
enum VK_DRIVER_ID_MESA_RADV_KHR                  = VkDriverIdKHR.VK_DRIVER_ID_MESA_RADV_KHR;
enum VK_DRIVER_ID_NVIDIA_PROPRIETARY_KHR         = VkDriverIdKHR.VK_DRIVER_ID_NVIDIA_PROPRIETARY_KHR;
enum VK_DRIVER_ID_INTEL_PROPRIETARY_WINDOWS_KHR  = VkDriverIdKHR.VK_DRIVER_ID_INTEL_PROPRIETARY_WINDOWS_KHR;
enum VK_DRIVER_ID_INTEL_OPEN_SOURCE_MESA_KHR     = VkDriverIdKHR.VK_DRIVER_ID_INTEL_OPEN_SOURCE_MESA_KHR;
enum VK_DRIVER_ID_IMAGINATION_PROPRIETARY_KHR    = VkDriverIdKHR.VK_DRIVER_ID_IMAGINATION_PROPRIETARY_KHR;
enum VK_DRIVER_ID_QUALCOMM_PROPRIETARY_KHR       = VkDriverIdKHR.VK_DRIVER_ID_QUALCOMM_PROPRIETARY_KHR;
enum VK_DRIVER_ID_ARM_PROPRIETARY_KHR            = VkDriverIdKHR.VK_DRIVER_ID_ARM_PROPRIETARY_KHR;
enum VK_DRIVER_ID_GOOGLE_SWIFTSHADER_KHR         = VkDriverIdKHR.VK_DRIVER_ID_GOOGLE_SWIFTSHADER_KHR;
enum VK_DRIVER_ID_GGP_PROPRIETARY_KHR            = VkDriverIdKHR.VK_DRIVER_ID_GGP_PROPRIETARY_KHR;
enum VK_DRIVER_IDKHR_BEGIN_RANGE_KHR             = VkDriverIdKHR.VK_DRIVER_IDKHR_BEGIN_RANGE_KHR;
enum VK_DRIVER_IDKHR_END_RANGE_KHR               = VkDriverIdKHR.VK_DRIVER_IDKHR_END_RANGE_KHR;
enum VK_DRIVER_IDKHR_RANGE_SIZE_KHR              = VkDriverIdKHR.VK_DRIVER_IDKHR_RANGE_SIZE_KHR;
enum VK_DRIVER_IDKHR_MAX_ENUM_KHR                = VkDriverIdKHR.VK_DRIVER_IDKHR_MAX_ENUM_KHR;

struct VkConformanceVersionKHR {
    uint8_t  major;
    uint8_t  minor;
    uint8_t  subminor;
    uint8_t  patch;
}

struct VkPhysicalDeviceDriverPropertiesKHR {
    VkStructureType                      sType = VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_DRIVER_PROPERTIES_KHR;
    void*                                pNext;
    VkDriverIdKHR                        driverID;
    char[ VK_MAX_DRIVER_NAME_SIZE_KHR ]  driverName;
    char[ VK_MAX_DRIVER_INFO_SIZE_KHR ]  driverInfo;
    VkConformanceVersionKHR              conformanceVersion;
}


// - VK_KHR_shader_float_controls -
enum VK_KHR_shader_float_controls = 1;

enum VK_KHR_SHADER_FLOAT_CONTROLS_SPEC_VERSION = 1;
enum VK_KHR_SHADER_FLOAT_CONTROLS_EXTENSION_NAME = "VK_KHR_shader_float_controls";

struct VkPhysicalDeviceFloatControlsPropertiesKHR {
    VkStructureType  sType = VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_FLOAT_CONTROLS_PROPERTIES_KHR;
    void*            pNext;
    VkBool32         separateDenormSettings;
    VkBool32         separateRoundingModeSettings;
    VkBool32         shaderSignedZeroInfNanPreserveFloat16;
    VkBool32         shaderSignedZeroInfNanPreserveFloat32;
    VkBool32         shaderSignedZeroInfNanPreserveFloat64;
    VkBool32         shaderDenormPreserveFloat16;
    VkBool32         shaderDenormPreserveFloat32;
    VkBool32         shaderDenormPreserveFloat64;
    VkBool32         shaderDenormFlushToZeroFloat16;
    VkBool32         shaderDenormFlushToZeroFloat32;
    VkBool32         shaderDenormFlushToZeroFloat64;
    VkBool32         shaderRoundingModeRTEFloat16;
    VkBool32         shaderRoundingModeRTEFloat32;
    VkBool32         shaderRoundingModeRTEFloat64;
    VkBool32         shaderRoundingModeRTZFloat16;
    VkBool32         shaderRoundingModeRTZFloat32;
    VkBool32         shaderRoundingModeRTZFloat64;
}


// - VK_KHR_depth_stencil_resolve -
enum VK_KHR_depth_stencil_resolve = 1;

enum VK_KHR_DEPTH_STENCIL_RESOLVE_SPEC_VERSION = 1;
enum VK_KHR_DEPTH_STENCIL_RESOLVE_EXTENSION_NAME = "VK_KHR_depth_stencil_resolve";

enum VkResolveModeFlagBitsKHR {
    VK_RESOLVE_MODE_NONE_KHR                     = 0,
    VK_RESOLVE_MODE_SAMPLE_ZERO_BIT_KHR          = 0x00000001,
    VK_RESOLVE_MODE_AVERAGE_BIT_KHR              = 0x00000002,
    VK_RESOLVE_MODE_MIN_BIT_KHR                  = 0x00000004,
    VK_RESOLVE_MODE_MAX_BIT_KHR                  = 0x00000008,
    VK_RESOLVE_MODE_FLAG_BITS_MAX_ENUM_KHR       = 0x7FFFFFFF
}

enum VK_RESOLVE_MODE_NONE_KHR                    = VkResolveModeFlagBitsKHR.VK_RESOLVE_MODE_NONE_KHR;
enum VK_RESOLVE_MODE_SAMPLE_ZERO_BIT_KHR         = VkResolveModeFlagBitsKHR.VK_RESOLVE_MODE_SAMPLE_ZERO_BIT_KHR;
enum VK_RESOLVE_MODE_AVERAGE_BIT_KHR             = VkResolveModeFlagBitsKHR.VK_RESOLVE_MODE_AVERAGE_BIT_KHR;
enum VK_RESOLVE_MODE_MIN_BIT_KHR                 = VkResolveModeFlagBitsKHR.VK_RESOLVE_MODE_MIN_BIT_KHR;
enum VK_RESOLVE_MODE_MAX_BIT_KHR                 = VkResolveModeFlagBitsKHR.VK_RESOLVE_MODE_MAX_BIT_KHR;
enum VK_RESOLVE_MODE_FLAG_BITS_MAX_ENUM_KHR      = VkResolveModeFlagBitsKHR.VK_RESOLVE_MODE_FLAG_BITS_MAX_ENUM_KHR;
alias VkResolveModeFlagsKHR = VkFlags;

struct VkSubpassDescriptionDepthStencilResolveKHR {
    VkStructureType                      sType = VK_STRUCTURE_TYPE_SUBPASS_DESCRIPTION_DEPTH_STENCIL_RESOLVE_KHR;
    const( void )*                       pNext;
    VkResolveModeFlagBitsKHR             depthResolveMode;
    VkResolveModeFlagBitsKHR             stencilResolveMode;
    const( VkAttachmentReference2KHR )*  pDepthStencilResolveAttachment;
}

struct VkPhysicalDeviceDepthStencilResolvePropertiesKHR {
    VkStructureType        sType = VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_DEPTH_STENCIL_RESOLVE_PROPERTIES_KHR;
    void*                  pNext;
    VkResolveModeFlagsKHR  supportedDepthResolveModes;
    VkResolveModeFlagsKHR  supportedStencilResolveModes;
    VkBool32               independentResolveNone;
    VkBool32               independentResolve;
}


// - VK_KHR_swapchain_mutable_format -
enum VK_KHR_swapchain_mutable_format = 1;

enum VK_KHR_SWAPCHAIN_MUTABLE_FORMAT_SPEC_VERSION = 1;
enum VK_KHR_SWAPCHAIN_MUTABLE_FORMAT_EXTENSION_NAME = "VK_KHR_swapchain_mutable_format";


// - VK_KHR_vulkan_memory_model -
enum VK_KHR_vulkan_memory_model = 1;

enum VK_KHR_VULKAN_MEMORY_MODEL_SPEC_VERSION = 3;
enum VK_KHR_VULKAN_MEMORY_MODEL_EXTENSION_NAME = "VK_KHR_vulkan_memory_model";

struct VkPhysicalDeviceVulkanMemoryModelFeaturesKHR {
    VkStructureType  sType = VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_VULKAN_MEMORY_MODEL_FEATURES_KHR;
    void*            pNext;
    VkBool32         vulkanMemoryModel;
    VkBool32         vulkanMemoryModelDeviceScope;
    VkBool32         vulkanMemoryModelAvailabilityVisibilityChains;
}


// - VK_KHR_surface_protected_capabilities -
enum VK_KHR_surface_protected_capabilities = 1;

enum VK_KHR_SURFACE_PROTECTED_CAPABILITIES_SPEC_VERSION = 1;
enum VK_KHR_SURFACE_PROTECTED_CAPABILITIES_EXTENSION_NAME = "VK_KHR_surface_protected_capabilities";

struct VkSurfaceProtectedCapabilitiesKHR {
    VkStructureType  sType = VK_STRUCTURE_TYPE_SURFACE_PROTECTED_CAPABILITIES_KHR;
    const( void )*   pNext;
    VkBool32         supportsProtected;
}


// - VK_KHR_uniform_buffer_standard_layout -
enum VK_KHR_uniform_buffer_standard_layout = 1;

enum VK_KHR_UNIFORM_BUFFER_STANDARD_LAYOUT_SPEC_VERSION = 1;
enum VK_KHR_UNIFORM_BUFFER_STANDARD_LAYOUT_EXTENSION_NAME = "VK_KHR_uniform_buffer_standard_layout";

struct VkPhysicalDeviceUniformBufferStandardLayoutFeaturesKHR {
    VkStructureType  sType = VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_UNIFORM_BUFFER_STANDARD_LAYOUT_FEATURES_KHR;
    void*            pNext;
    VkBool32         uniformBufferStandardLayout;
}


// - VK_EXT_debug_report -
enum VK_EXT_debug_report = 1;

mixin( VK_DEFINE_NON_DISPATCHABLE_HANDLE!q{VkDebugReportCallbackEXT} );

enum VK_EXT_DEBUG_REPORT_SPEC_VERSION = 9;
enum VK_EXT_DEBUG_REPORT_EXTENSION_NAME = "VK_EXT_debug_report";

enum VkDebugReportObjectTypeEXT {
    VK_DEBUG_REPORT_OBJECT_TYPE_UNKNOWN_EXT                              = 0,
    VK_DEBUG_REPORT_OBJECT_TYPE_INSTANCE_EXT                             = 1,
    VK_DEBUG_REPORT_OBJECT_TYPE_PHYSICAL_DEVICE_EXT                      = 2,
    VK_DEBUG_REPORT_OBJECT_TYPE_DEVICE_EXT                               = 3,
    VK_DEBUG_REPORT_OBJECT_TYPE_QUEUE_EXT                                = 4,
    VK_DEBUG_REPORT_OBJECT_TYPE_SEMAPHORE_EXT                            = 5,
    VK_DEBUG_REPORT_OBJECT_TYPE_COMMAND_BUFFER_EXT                       = 6,
    VK_DEBUG_REPORT_OBJECT_TYPE_FENCE_EXT                                = 7,
    VK_DEBUG_REPORT_OBJECT_TYPE_DEVICE_MEMORY_EXT                        = 8,
    VK_DEBUG_REPORT_OBJECT_TYPE_BUFFER_EXT                               = 9,
    VK_DEBUG_REPORT_OBJECT_TYPE_IMAGE_EXT                                = 10,
    VK_DEBUG_REPORT_OBJECT_TYPE_EVENT_EXT                                = 11,
    VK_DEBUG_REPORT_OBJECT_TYPE_QUERY_POOL_EXT                           = 12,
    VK_DEBUG_REPORT_OBJECT_TYPE_BUFFER_VIEW_EXT                          = 13,
    VK_DEBUG_REPORT_OBJECT_TYPE_IMAGE_VIEW_EXT                           = 14,
    VK_DEBUG_REPORT_OBJECT_TYPE_SHADER_MODULE_EXT                        = 15,
    VK_DEBUG_REPORT_OBJECT_TYPE_PIPELINE_CACHE_EXT                       = 16,
    VK_DEBUG_REPORT_OBJECT_TYPE_PIPELINE_LAYOUT_EXT                      = 17,
    VK_DEBUG_REPORT_OBJECT_TYPE_RENDER_PASS_EXT                          = 18,
    VK_DEBUG_REPORT_OBJECT_TYPE_PIPELINE_EXT                             = 19,
    VK_DEBUG_REPORT_OBJECT_TYPE_DESCRIPTOR_SET_LAYOUT_EXT                = 20,
    VK_DEBUG_REPORT_OBJECT_TYPE_SAMPLER_EXT                              = 21,
    VK_DEBUG_REPORT_OBJECT_TYPE_DESCRIPTOR_POOL_EXT                      = 22,
    VK_DEBUG_REPORT_OBJECT_TYPE_DESCRIPTOR_SET_EXT                       = 23,
    VK_DEBUG_REPORT_OBJECT_TYPE_FRAMEBUFFER_EXT                          = 24,
    VK_DEBUG_REPORT_OBJECT_TYPE_COMMAND_POOL_EXT                         = 25,
    VK_DEBUG_REPORT_OBJECT_TYPE_SURFACE_KHR_EXT                          = 26,
    VK_DEBUG_REPORT_OBJECT_TYPE_SWAPCHAIN_KHR_EXT                        = 27,
    VK_DEBUG_REPORT_OBJECT_TYPE_DEBUG_REPORT_CALLBACK_EXT_EXT            = 28,
    VK_DEBUG_REPORT_OBJECT_TYPE_DISPLAY_KHR_EXT                          = 29,
    VK_DEBUG_REPORT_OBJECT_TYPE_DISPLAY_MODE_KHR_EXT                     = 30,
    VK_DEBUG_REPORT_OBJECT_TYPE_OBJECT_TABLE_NVX_EXT                     = 31,
    VK_DEBUG_REPORT_OBJECT_TYPE_INDIRECT_COMMANDS_LAYOUT_NVX_EXT         = 32,
    VK_DEBUG_REPORT_OBJECT_TYPE_VALIDATION_CACHE_EXT_EXT                 = 33,
    VK_DEBUG_REPORT_OBJECT_TYPE_SAMPLER_YCBCR_CONVERSION_EXT             = 1000156000,
    VK_DEBUG_REPORT_OBJECT_TYPE_DESCRIPTOR_UPDATE_TEMPLATE_EXT           = 1000085000,
    VK_DEBUG_REPORT_OBJECT_TYPE_ACCELERATION_STRUCTURE_NV_EXT            = 1000165000,
    VK_DEBUG_REPORT_OBJECT_TYPE_DEBUG_REPORT_EXT                         = VK_DEBUG_REPORT_OBJECT_TYPE_DEBUG_REPORT_CALLBACK_EXT_EXT,
    VK_DEBUG_REPORT_OBJECT_TYPE_VALIDATION_CACHE_EXT                     = VK_DEBUG_REPORT_OBJECT_TYPE_VALIDATION_CACHE_EXT_EXT,
    VK_DEBUG_REPORT_OBJECT_TYPE_DESCRIPTOR_UPDATE_TEMPLATE_KHR_EXT       = VK_DEBUG_REPORT_OBJECT_TYPE_DESCRIPTOR_UPDATE_TEMPLATE_EXT,
    VK_DEBUG_REPORT_OBJECT_TYPE_SAMPLER_YCBCR_CONVERSION_KHR_EXT         = VK_DEBUG_REPORT_OBJECT_TYPE_SAMPLER_YCBCR_CONVERSION_EXT,
    VK_DEBUG_REPORT_OBJECT_TYPE_BEGIN_RANGE_EXT                          = VK_DEBUG_REPORT_OBJECT_TYPE_UNKNOWN_EXT,
    VK_DEBUG_REPORT_OBJECT_TYPE_END_RANGE_EXT                            = VK_DEBUG_REPORT_OBJECT_TYPE_VALIDATION_CACHE_EXT_EXT,
    VK_DEBUG_REPORT_OBJECT_TYPE_RANGE_SIZE_EXT                           = VK_DEBUG_REPORT_OBJECT_TYPE_VALIDATION_CACHE_EXT_EXT - VK_DEBUG_REPORT_OBJECT_TYPE_UNKNOWN_EXT + 1,
    VK_DEBUG_REPORT_OBJECT_TYPE_MAX_ENUM_EXT                             = 0x7FFFFFFF
}

enum VK_DEBUG_REPORT_OBJECT_TYPE_UNKNOWN_EXT                             = VkDebugReportObjectTypeEXT.VK_DEBUG_REPORT_OBJECT_TYPE_UNKNOWN_EXT;
enum VK_DEBUG_REPORT_OBJECT_TYPE_INSTANCE_EXT                            = VkDebugReportObjectTypeEXT.VK_DEBUG_REPORT_OBJECT_TYPE_INSTANCE_EXT;
enum VK_DEBUG_REPORT_OBJECT_TYPE_PHYSICAL_DEVICE_EXT                     = VkDebugReportObjectTypeEXT.VK_DEBUG_REPORT_OBJECT_TYPE_PHYSICAL_DEVICE_EXT;
enum VK_DEBUG_REPORT_OBJECT_TYPE_DEVICE_EXT                              = VkDebugReportObjectTypeEXT.VK_DEBUG_REPORT_OBJECT_TYPE_DEVICE_EXT;
enum VK_DEBUG_REPORT_OBJECT_TYPE_QUEUE_EXT                               = VkDebugReportObjectTypeEXT.VK_DEBUG_REPORT_OBJECT_TYPE_QUEUE_EXT;
enum VK_DEBUG_REPORT_OBJECT_TYPE_SEMAPHORE_EXT                           = VkDebugReportObjectTypeEXT.VK_DEBUG_REPORT_OBJECT_TYPE_SEMAPHORE_EXT;
enum VK_DEBUG_REPORT_OBJECT_TYPE_COMMAND_BUFFER_EXT                      = VkDebugReportObjectTypeEXT.VK_DEBUG_REPORT_OBJECT_TYPE_COMMAND_BUFFER_EXT;
enum VK_DEBUG_REPORT_OBJECT_TYPE_FENCE_EXT                               = VkDebugReportObjectTypeEXT.VK_DEBUG_REPORT_OBJECT_TYPE_FENCE_EXT;
enum VK_DEBUG_REPORT_OBJECT_TYPE_DEVICE_MEMORY_EXT                       = VkDebugReportObjectTypeEXT.VK_DEBUG_REPORT_OBJECT_TYPE_DEVICE_MEMORY_EXT;
enum VK_DEBUG_REPORT_OBJECT_TYPE_BUFFER_EXT                              = VkDebugReportObjectTypeEXT.VK_DEBUG_REPORT_OBJECT_TYPE_BUFFER_EXT;
enum VK_DEBUG_REPORT_OBJECT_TYPE_IMAGE_EXT                               = VkDebugReportObjectTypeEXT.VK_DEBUG_REPORT_OBJECT_TYPE_IMAGE_EXT;
enum VK_DEBUG_REPORT_OBJECT_TYPE_EVENT_EXT                               = VkDebugReportObjectTypeEXT.VK_DEBUG_REPORT_OBJECT_TYPE_EVENT_EXT;
enum VK_DEBUG_REPORT_OBJECT_TYPE_QUERY_POOL_EXT                          = VkDebugReportObjectTypeEXT.VK_DEBUG_REPORT_OBJECT_TYPE_QUERY_POOL_EXT;
enum VK_DEBUG_REPORT_OBJECT_TYPE_BUFFER_VIEW_EXT                         = VkDebugReportObjectTypeEXT.VK_DEBUG_REPORT_OBJECT_TYPE_BUFFER_VIEW_EXT;
enum VK_DEBUG_REPORT_OBJECT_TYPE_IMAGE_VIEW_EXT                          = VkDebugReportObjectTypeEXT.VK_DEBUG_REPORT_OBJECT_TYPE_IMAGE_VIEW_EXT;
enum VK_DEBUG_REPORT_OBJECT_TYPE_SHADER_MODULE_EXT                       = VkDebugReportObjectTypeEXT.VK_DEBUG_REPORT_OBJECT_TYPE_SHADER_MODULE_EXT;
enum VK_DEBUG_REPORT_OBJECT_TYPE_PIPELINE_CACHE_EXT                      = VkDebugReportObjectTypeEXT.VK_DEBUG_REPORT_OBJECT_TYPE_PIPELINE_CACHE_EXT;
enum VK_DEBUG_REPORT_OBJECT_TYPE_PIPELINE_LAYOUT_EXT                     = VkDebugReportObjectTypeEXT.VK_DEBUG_REPORT_OBJECT_TYPE_PIPELINE_LAYOUT_EXT;
enum VK_DEBUG_REPORT_OBJECT_TYPE_RENDER_PASS_EXT                         = VkDebugReportObjectTypeEXT.VK_DEBUG_REPORT_OBJECT_TYPE_RENDER_PASS_EXT;
enum VK_DEBUG_REPORT_OBJECT_TYPE_PIPELINE_EXT                            = VkDebugReportObjectTypeEXT.VK_DEBUG_REPORT_OBJECT_TYPE_PIPELINE_EXT;
enum VK_DEBUG_REPORT_OBJECT_TYPE_DESCRIPTOR_SET_LAYOUT_EXT               = VkDebugReportObjectTypeEXT.VK_DEBUG_REPORT_OBJECT_TYPE_DESCRIPTOR_SET_LAYOUT_EXT;
enum VK_DEBUG_REPORT_OBJECT_TYPE_SAMPLER_EXT                             = VkDebugReportObjectTypeEXT.VK_DEBUG_REPORT_OBJECT_TYPE_SAMPLER_EXT;
enum VK_DEBUG_REPORT_OBJECT_TYPE_DESCRIPTOR_POOL_EXT                     = VkDebugReportObjectTypeEXT.VK_DEBUG_REPORT_OBJECT_TYPE_DESCRIPTOR_POOL_EXT;
enum VK_DEBUG_REPORT_OBJECT_TYPE_DESCRIPTOR_SET_EXT                      = VkDebugReportObjectTypeEXT.VK_DEBUG_REPORT_OBJECT_TYPE_DESCRIPTOR_SET_EXT;
enum VK_DEBUG_REPORT_OBJECT_TYPE_FRAMEBUFFER_EXT                         = VkDebugReportObjectTypeEXT.VK_DEBUG_REPORT_OBJECT_TYPE_FRAMEBUFFER_EXT;
enum VK_DEBUG_REPORT_OBJECT_TYPE_COMMAND_POOL_EXT                        = VkDebugReportObjectTypeEXT.VK_DEBUG_REPORT_OBJECT_TYPE_COMMAND_POOL_EXT;
enum VK_DEBUG_REPORT_OBJECT_TYPE_SURFACE_KHR_EXT                         = VkDebugReportObjectTypeEXT.VK_DEBUG_REPORT_OBJECT_TYPE_SURFACE_KHR_EXT;
enum VK_DEBUG_REPORT_OBJECT_TYPE_SWAPCHAIN_KHR_EXT                       = VkDebugReportObjectTypeEXT.VK_DEBUG_REPORT_OBJECT_TYPE_SWAPCHAIN_KHR_EXT;
enum VK_DEBUG_REPORT_OBJECT_TYPE_DEBUG_REPORT_CALLBACK_EXT_EXT           = VkDebugReportObjectTypeEXT.VK_DEBUG_REPORT_OBJECT_TYPE_DEBUG_REPORT_CALLBACK_EXT_EXT;
enum VK_DEBUG_REPORT_OBJECT_TYPE_DISPLAY_KHR_EXT                         = VkDebugReportObjectTypeEXT.VK_DEBUG_REPORT_OBJECT_TYPE_DISPLAY_KHR_EXT;
enum VK_DEBUG_REPORT_OBJECT_TYPE_DISPLAY_MODE_KHR_EXT                    = VkDebugReportObjectTypeEXT.VK_DEBUG_REPORT_OBJECT_TYPE_DISPLAY_MODE_KHR_EXT;
enum VK_DEBUG_REPORT_OBJECT_TYPE_OBJECT_TABLE_NVX_EXT                    = VkDebugReportObjectTypeEXT.VK_DEBUG_REPORT_OBJECT_TYPE_OBJECT_TABLE_NVX_EXT;
enum VK_DEBUG_REPORT_OBJECT_TYPE_INDIRECT_COMMANDS_LAYOUT_NVX_EXT        = VkDebugReportObjectTypeEXT.VK_DEBUG_REPORT_OBJECT_TYPE_INDIRECT_COMMANDS_LAYOUT_NVX_EXT;
enum VK_DEBUG_REPORT_OBJECT_TYPE_VALIDATION_CACHE_EXT_EXT                = VkDebugReportObjectTypeEXT.VK_DEBUG_REPORT_OBJECT_TYPE_VALIDATION_CACHE_EXT_EXT;
enum VK_DEBUG_REPORT_OBJECT_TYPE_SAMPLER_YCBCR_CONVERSION_EXT            = VkDebugReportObjectTypeEXT.VK_DEBUG_REPORT_OBJECT_TYPE_SAMPLER_YCBCR_CONVERSION_EXT;
enum VK_DEBUG_REPORT_OBJECT_TYPE_DESCRIPTOR_UPDATE_TEMPLATE_EXT          = VkDebugReportObjectTypeEXT.VK_DEBUG_REPORT_OBJECT_TYPE_DESCRIPTOR_UPDATE_TEMPLATE_EXT;
enum VK_DEBUG_REPORT_OBJECT_TYPE_ACCELERATION_STRUCTURE_NV_EXT           = VkDebugReportObjectTypeEXT.VK_DEBUG_REPORT_OBJECT_TYPE_ACCELERATION_STRUCTURE_NV_EXT;
enum VK_DEBUG_REPORT_OBJECT_TYPE_DEBUG_REPORT_EXT                        = VkDebugReportObjectTypeEXT.VK_DEBUG_REPORT_OBJECT_TYPE_DEBUG_REPORT_EXT;
enum VK_DEBUG_REPORT_OBJECT_TYPE_VALIDATION_CACHE_EXT                    = VkDebugReportObjectTypeEXT.VK_DEBUG_REPORT_OBJECT_TYPE_VALIDATION_CACHE_EXT;
enum VK_DEBUG_REPORT_OBJECT_TYPE_DESCRIPTOR_UPDATE_TEMPLATE_KHR_EXT      = VkDebugReportObjectTypeEXT.VK_DEBUG_REPORT_OBJECT_TYPE_DESCRIPTOR_UPDATE_TEMPLATE_KHR_EXT;
enum VK_DEBUG_REPORT_OBJECT_TYPE_SAMPLER_YCBCR_CONVERSION_KHR_EXT        = VkDebugReportObjectTypeEXT.VK_DEBUG_REPORT_OBJECT_TYPE_SAMPLER_YCBCR_CONVERSION_KHR_EXT;
enum VK_DEBUG_REPORT_OBJECT_TYPE_BEGIN_RANGE_EXT                         = VkDebugReportObjectTypeEXT.VK_DEBUG_REPORT_OBJECT_TYPE_BEGIN_RANGE_EXT;
enum VK_DEBUG_REPORT_OBJECT_TYPE_END_RANGE_EXT                           = VkDebugReportObjectTypeEXT.VK_DEBUG_REPORT_OBJECT_TYPE_END_RANGE_EXT;
enum VK_DEBUG_REPORT_OBJECT_TYPE_RANGE_SIZE_EXT                          = VkDebugReportObjectTypeEXT.VK_DEBUG_REPORT_OBJECT_TYPE_RANGE_SIZE_EXT;
enum VK_DEBUG_REPORT_OBJECT_TYPE_MAX_ENUM_EXT                            = VkDebugReportObjectTypeEXT.VK_DEBUG_REPORT_OBJECT_TYPE_MAX_ENUM_EXT;

enum VkDebugReportFlagBitsEXT {
    VK_DEBUG_REPORT_INFORMATION_BIT_EXT          = 0x00000001,
    VK_DEBUG_REPORT_WARNING_BIT_EXT              = 0x00000002,
    VK_DEBUG_REPORT_PERFORMANCE_WARNING_BIT_EXT  = 0x00000004,
    VK_DEBUG_REPORT_ERROR_BIT_EXT                = 0x00000008,
    VK_DEBUG_REPORT_DEBUG_BIT_EXT                = 0x00000010,
    VK_DEBUG_REPORT_FLAG_BITS_MAX_ENUM_EXT       = 0x7FFFFFFF
}

enum VK_DEBUG_REPORT_INFORMATION_BIT_EXT         = VkDebugReportFlagBitsEXT.VK_DEBUG_REPORT_INFORMATION_BIT_EXT;
enum VK_DEBUG_REPORT_WARNING_BIT_EXT             = VkDebugReportFlagBitsEXT.VK_DEBUG_REPORT_WARNING_BIT_EXT;
enum VK_DEBUG_REPORT_PERFORMANCE_WARNING_BIT_EXT = VkDebugReportFlagBitsEXT.VK_DEBUG_REPORT_PERFORMANCE_WARNING_BIT_EXT;
enum VK_DEBUG_REPORT_ERROR_BIT_EXT               = VkDebugReportFlagBitsEXT.VK_DEBUG_REPORT_ERROR_BIT_EXT;
enum VK_DEBUG_REPORT_DEBUG_BIT_EXT               = VkDebugReportFlagBitsEXT.VK_DEBUG_REPORT_DEBUG_BIT_EXT;
enum VK_DEBUG_REPORT_FLAG_BITS_MAX_ENUM_EXT      = VkDebugReportFlagBitsEXT.VK_DEBUG_REPORT_FLAG_BITS_MAX_ENUM_EXT;
alias VkDebugReportFlagsEXT = VkFlags;

alias PFN_vkDebugReportCallbackEXT = VkBool32 function(
    VkDebugReportFlagsEXT       flags,
    VkDebugReportObjectTypeEXT  objectType,
    uint64_t                    object,
    size_t                      location,
    int32_t                     messageCode,
    const( char )*              pLayerPrefix,
    const( char )*              pMessage,
    void*                       pUserData
);

struct VkDebugReportCallbackCreateInfoEXT {
    VkStructureType               sType = VK_STRUCTURE_TYPE_DEBUG_REPORT_CALLBACK_CREATE_INFO_EXT;
    const( void )*                pNext;
    VkDebugReportFlagsEXT         flags;
    PFN_vkDebugReportCallbackEXT  pfnCallback;
    void*                         pUserData;
}


// - VK_NV_glsl_shader -
enum VK_NV_glsl_shader = 1;

enum VK_NV_GLSL_SHADER_SPEC_VERSION = 1;
enum VK_NV_GLSL_SHADER_EXTENSION_NAME = "VK_NV_glsl_shader";


// - VK_EXT_depth_range_unrestricted -
enum VK_EXT_depth_range_unrestricted = 1;

enum VK_EXT_DEPTH_RANGE_UNRESTRICTED_SPEC_VERSION = 1;
enum VK_EXT_DEPTH_RANGE_UNRESTRICTED_EXTENSION_NAME = "VK_EXT_depth_range_unrestricted";


// - VK_IMG_filter_cubic -
enum VK_IMG_filter_cubic = 1;

enum VK_IMG_FILTER_CUBIC_SPEC_VERSION = 1;
enum VK_IMG_FILTER_CUBIC_EXTENSION_NAME = "VK_IMG_filter_cubic";


// - VK_AMD_rasterization_order -
enum VK_AMD_rasterization_order = 1;

enum VK_AMD_RASTERIZATION_ORDER_SPEC_VERSION = 1;
enum VK_AMD_RASTERIZATION_ORDER_EXTENSION_NAME = "VK_AMD_rasterization_order";

enum VkRasterizationOrderAMD {
    VK_RASTERIZATION_ORDER_STRICT_AMD    = 0,
    VK_RASTERIZATION_ORDER_RELAXED_AMD   = 1,
    VK_RASTERIZATION_ORDER_BEGIN_RANGE_AMD = VK_RASTERIZATION_ORDER_STRICT_AMD,
    VK_RASTERIZATION_ORDER_END_RANGE_AMD = VK_RASTERIZATION_ORDER_RELAXED_AMD,
    VK_RASTERIZATION_ORDER_RANGE_SIZE_AMD = VK_RASTERIZATION_ORDER_RELAXED_AMD - VK_RASTERIZATION_ORDER_STRICT_AMD + 1,
    VK_RASTERIZATION_ORDER_MAX_ENUM_AMD  = 0x7FFFFFFF
}

enum VK_RASTERIZATION_ORDER_STRICT_AMD   = VkRasterizationOrderAMD.VK_RASTERIZATION_ORDER_STRICT_AMD;
enum VK_RASTERIZATION_ORDER_RELAXED_AMD  = VkRasterizationOrderAMD.VK_RASTERIZATION_ORDER_RELAXED_AMD;
enum VK_RASTERIZATION_ORDER_BEGIN_RANGE_AMD = VkRasterizationOrderAMD.VK_RASTERIZATION_ORDER_BEGIN_RANGE_AMD;
enum VK_RASTERIZATION_ORDER_END_RANGE_AMD = VkRasterizationOrderAMD.VK_RASTERIZATION_ORDER_END_RANGE_AMD;
enum VK_RASTERIZATION_ORDER_RANGE_SIZE_AMD = VkRasterizationOrderAMD.VK_RASTERIZATION_ORDER_RANGE_SIZE_AMD;
enum VK_RASTERIZATION_ORDER_MAX_ENUM_AMD = VkRasterizationOrderAMD.VK_RASTERIZATION_ORDER_MAX_ENUM_AMD;

struct VkPipelineRasterizationStateRasterizationOrderAMD {
    VkStructureType          sType = VK_STRUCTURE_TYPE_PIPELINE_RASTERIZATION_STATE_RASTERIZATION_ORDER_AMD;
    const( void )*           pNext;
    VkRasterizationOrderAMD  rasterizationOrder;
}


// - VK_AMD_shader_trinary_minmax -
enum VK_AMD_shader_trinary_minmax = 1;

enum VK_AMD_SHADER_TRINARY_MINMAX_SPEC_VERSION = 1;
enum VK_AMD_SHADER_TRINARY_MINMAX_EXTENSION_NAME = "VK_AMD_shader_trinary_minmax";


// - VK_AMD_shader_explicit_vertex_parameter -
enum VK_AMD_shader_explicit_vertex_parameter = 1;

enum VK_AMD_SHADER_EXPLICIT_VERTEX_PARAMETER_SPEC_VERSION = 1;
enum VK_AMD_SHADER_EXPLICIT_VERTEX_PARAMETER_EXTENSION_NAME = "VK_AMD_shader_explicit_vertex_parameter";


// - VK_EXT_debug_marker -
enum VK_EXT_debug_marker = 1;

enum VK_EXT_DEBUG_MARKER_SPEC_VERSION = 4;
enum VK_EXT_DEBUG_MARKER_EXTENSION_NAME = "VK_EXT_debug_marker";

struct VkDebugMarkerObjectNameInfoEXT {
    VkStructureType             sType = VK_STRUCTURE_TYPE_DEBUG_MARKER_OBJECT_NAME_INFO_EXT;
    const( void )*              pNext;
    VkDebugReportObjectTypeEXT  objectType;
    uint64_t                    object;
    const( char )*              pObjectName;
}

struct VkDebugMarkerObjectTagInfoEXT {
    VkStructureType             sType = VK_STRUCTURE_TYPE_DEBUG_MARKER_OBJECT_TAG_INFO_EXT;
    const( void )*              pNext;
    VkDebugReportObjectTypeEXT  objectType;
    uint64_t                    object;
    uint64_t                    tagName;
    size_t                      tagSize;
    const( void )*              pTag;
}

struct VkDebugMarkerMarkerInfoEXT {
    VkStructureType  sType = VK_STRUCTURE_TYPE_DEBUG_MARKER_MARKER_INFO_EXT;
    const( void )*   pNext;
    const( char )*   pMarkerName;
    float[4]         color;
}


// - VK_AMD_gcn_shader -
enum VK_AMD_gcn_shader = 1;

enum VK_AMD_GCN_SHADER_SPEC_VERSION = 1;
enum VK_AMD_GCN_SHADER_EXTENSION_NAME = "VK_AMD_gcn_shader";


// - VK_NV_dedicated_allocation -
enum VK_NV_dedicated_allocation = 1;

enum VK_NV_DEDICATED_ALLOCATION_SPEC_VERSION = 1;
enum VK_NV_DEDICATED_ALLOCATION_EXTENSION_NAME = "VK_NV_dedicated_allocation";

struct VkDedicatedAllocationImageCreateInfoNV {
    VkStructureType  sType = VK_STRUCTURE_TYPE_DEDICATED_ALLOCATION_IMAGE_CREATE_INFO_NV;
    const( void )*   pNext;
    VkBool32         dedicatedAllocation;
}

struct VkDedicatedAllocationBufferCreateInfoNV {
    VkStructureType  sType = VK_STRUCTURE_TYPE_DEDICATED_ALLOCATION_BUFFER_CREATE_INFO_NV;
    const( void )*   pNext;
    VkBool32         dedicatedAllocation;
}

struct VkDedicatedAllocationMemoryAllocateInfoNV {
    VkStructureType  sType = VK_STRUCTURE_TYPE_DEDICATED_ALLOCATION_MEMORY_ALLOCATE_INFO_NV;
    const( void )*   pNext;
    VkImage          image;
    VkBuffer         buffer;
}


// - VK_EXT_transform_feedback -
enum VK_EXT_transform_feedback = 1;

enum VK_EXT_TRANSFORM_FEEDBACK_SPEC_VERSION = 1;
enum VK_EXT_TRANSFORM_FEEDBACK_EXTENSION_NAME = "VK_EXT_transform_feedback";

alias VkPipelineRasterizationStateStreamCreateFlagsEXT = VkFlags;

struct VkPhysicalDeviceTransformFeedbackFeaturesEXT {
    VkStructureType  sType = VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_TRANSFORM_FEEDBACK_FEATURES_EXT;
    void*            pNext;
    VkBool32         transformFeedback;
    VkBool32         geometryStreams;
}

struct VkPhysicalDeviceTransformFeedbackPropertiesEXT {
    VkStructureType  sType = VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_TRANSFORM_FEEDBACK_PROPERTIES_EXT;
    void*            pNext;
    uint32_t         maxTransformFeedbackStreams;
    uint32_t         maxTransformFeedbackBuffers;
    VkDeviceSize     maxTransformFeedbackBufferSize;
    uint32_t         maxTransformFeedbackStreamDataSize;
    uint32_t         maxTransformFeedbackBufferDataSize;
    uint32_t         maxTransformFeedbackBufferDataStride;
    VkBool32         transformFeedbackQueries;
    VkBool32         transformFeedbackStreamsLinesTriangles;
    VkBool32         transformFeedbackRasterizationStreamSelect;
    VkBool32         transformFeedbackDraw;
}

struct VkPipelineRasterizationStateStreamCreateInfoEXT {
    VkStructureType                                   sType = VK_STRUCTURE_TYPE_PIPELINE_RASTERIZATION_STATE_STREAM_CREATE_INFO_EXT;
    const( void )*                                    pNext;
    VkPipelineRasterizationStateStreamCreateFlagsEXT  flags;
    uint32_t                                          rasterizationStream;
}


// - VK_NVX_image_view_handle -
enum VK_NVX_image_view_handle = 1;

enum VK_NVX_IMAGE_VIEW_HANDLE_SPEC_VERSION = 1;
enum VK_NVX_IMAGE_VIEW_HANDLE_EXTENSION_NAME = "VK_NVX_image_view_handle";

struct VkImageViewHandleInfoNVX {
    VkStructureType   sType = VK_STRUCTURE_TYPE_IMAGE_VIEW_HANDLE_INFO_NVX;
    const( void )*    pNext;
    VkImageView       imageView;
    VkDescriptorType  descriptorType;
    VkSampler         sampler;
}


// - VK_AMD_draw_indirect_count -
enum VK_AMD_draw_indirect_count = 1;

enum VK_AMD_DRAW_INDIRECT_COUNT_SPEC_VERSION = 1;
enum VK_AMD_DRAW_INDIRECT_COUNT_EXTENSION_NAME = "VK_AMD_draw_indirect_count";


// - VK_AMD_negative_viewport_height -
enum VK_AMD_negative_viewport_height = 1;

enum VK_AMD_NEGATIVE_VIEWPORT_HEIGHT_SPEC_VERSION = 1;
enum VK_AMD_NEGATIVE_VIEWPORT_HEIGHT_EXTENSION_NAME = "VK_AMD_negative_viewport_height";


// - VK_AMD_gpu_shader_half_float -
enum VK_AMD_gpu_shader_half_float = 1;

enum VK_AMD_GPU_SHADER_HALF_FLOAT_SPEC_VERSION = 2;
enum VK_AMD_GPU_SHADER_HALF_FLOAT_EXTENSION_NAME = "VK_AMD_gpu_shader_half_float";


// - VK_AMD_shader_ballot -
enum VK_AMD_shader_ballot = 1;

enum VK_AMD_SHADER_BALLOT_SPEC_VERSION = 1;
enum VK_AMD_SHADER_BALLOT_EXTENSION_NAME = "VK_AMD_shader_ballot";


// - VK_AMD_texture_gather_bias_lod -
enum VK_AMD_texture_gather_bias_lod = 1;

enum VK_AMD_TEXTURE_GATHER_BIAS_LOD_SPEC_VERSION = 1;
enum VK_AMD_TEXTURE_GATHER_BIAS_LOD_EXTENSION_NAME = "VK_AMD_texture_gather_bias_lod";

struct VkTextureLODGatherFormatPropertiesAMD {
    VkStructureType  sType = VK_STRUCTURE_TYPE_TEXTURE_LOD_GATHER_FORMAT_PROPERTIES_AMD;
    void*            pNext;
    VkBool32         supportsTextureGatherLODBiasAMD;
}


// - VK_AMD_shader_info -
enum VK_AMD_shader_info = 1;

enum VK_AMD_SHADER_INFO_SPEC_VERSION = 1;
enum VK_AMD_SHADER_INFO_EXTENSION_NAME = "VK_AMD_shader_info";

enum VkShaderInfoTypeAMD {
    VK_SHADER_INFO_TYPE_STATISTICS_AMD   = 0,
    VK_SHADER_INFO_TYPE_BINARY_AMD       = 1,
    VK_SHADER_INFO_TYPE_DISASSEMBLY_AMD  = 2,
    VK_SHADER_INFO_TYPE_BEGIN_RANGE_AMD  = VK_SHADER_INFO_TYPE_STATISTICS_AMD,
    VK_SHADER_INFO_TYPE_END_RANGE_AMD    = VK_SHADER_INFO_TYPE_DISASSEMBLY_AMD,
    VK_SHADER_INFO_TYPE_RANGE_SIZE_AMD   = VK_SHADER_INFO_TYPE_DISASSEMBLY_AMD - VK_SHADER_INFO_TYPE_STATISTICS_AMD + 1,
    VK_SHADER_INFO_TYPE_MAX_ENUM_AMD     = 0x7FFFFFFF
}

enum VK_SHADER_INFO_TYPE_STATISTICS_AMD  = VkShaderInfoTypeAMD.VK_SHADER_INFO_TYPE_STATISTICS_AMD;
enum VK_SHADER_INFO_TYPE_BINARY_AMD      = VkShaderInfoTypeAMD.VK_SHADER_INFO_TYPE_BINARY_AMD;
enum VK_SHADER_INFO_TYPE_DISASSEMBLY_AMD = VkShaderInfoTypeAMD.VK_SHADER_INFO_TYPE_DISASSEMBLY_AMD;
enum VK_SHADER_INFO_TYPE_BEGIN_RANGE_AMD = VkShaderInfoTypeAMD.VK_SHADER_INFO_TYPE_BEGIN_RANGE_AMD;
enum VK_SHADER_INFO_TYPE_END_RANGE_AMD   = VkShaderInfoTypeAMD.VK_SHADER_INFO_TYPE_END_RANGE_AMD;
enum VK_SHADER_INFO_TYPE_RANGE_SIZE_AMD  = VkShaderInfoTypeAMD.VK_SHADER_INFO_TYPE_RANGE_SIZE_AMD;
enum VK_SHADER_INFO_TYPE_MAX_ENUM_AMD    = VkShaderInfoTypeAMD.VK_SHADER_INFO_TYPE_MAX_ENUM_AMD;

struct VkShaderResourceUsageAMD {
    uint32_t  numUsedVgprs;
    uint32_t  numUsedSgprs;
    uint32_t  ldsSizePerLocalWorkGroup;
    size_t    ldsUsageSizeInBytes;
    size_t    scratchMemUsageInBytes;
}

struct VkShaderStatisticsInfoAMD {
    VkShaderStageFlags        shaderStageMask;
    VkShaderResourceUsageAMD  resourceUsage;
    uint32_t                  numPhysicalVgprs;
    uint32_t                  numPhysicalSgprs;
    uint32_t                  numAvailableVgprs;
    uint32_t                  numAvailableSgprs;
    uint32_t[3]               computeWorkGroupSize;
}


// - VK_AMD_shader_image_load_store_lod -
enum VK_AMD_shader_image_load_store_lod = 1;

enum VK_AMD_SHADER_IMAGE_LOAD_STORE_LOD_SPEC_VERSION = 1;
enum VK_AMD_SHADER_IMAGE_LOAD_STORE_LOD_EXTENSION_NAME = "VK_AMD_shader_image_load_store_lod";


// - VK_NV_corner_sampled_image -
enum VK_NV_corner_sampled_image = 1;

enum VK_NV_CORNER_SAMPLED_IMAGE_SPEC_VERSION = 2;
enum VK_NV_CORNER_SAMPLED_IMAGE_EXTENSION_NAME = "VK_NV_corner_sampled_image";

struct VkPhysicalDeviceCornerSampledImageFeaturesNV {
    VkStructureType  sType = VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_CORNER_SAMPLED_IMAGE_FEATURES_NV;
    void*            pNext;
    VkBool32         cornerSampledImage;
}


// - VK_IMG_format_pvrtc -
enum VK_IMG_format_pvrtc = 1;

enum VK_IMG_FORMAT_PVRTC_SPEC_VERSION = 1;
enum VK_IMG_FORMAT_PVRTC_EXTENSION_NAME = "VK_IMG_format_pvrtc";


// - VK_NV_external_memory_capabilities -
enum VK_NV_external_memory_capabilities = 1;

enum VK_NV_EXTERNAL_MEMORY_CAPABILITIES_SPEC_VERSION = 1;
enum VK_NV_EXTERNAL_MEMORY_CAPABILITIES_EXTENSION_NAME = "VK_NV_external_memory_capabilities";

enum VkExternalMemoryHandleTypeFlagBitsNV {
    VK_EXTERNAL_MEMORY_HANDLE_TYPE_OPAQUE_WIN32_BIT_NV           = 0x00000001,
    VK_EXTERNAL_MEMORY_HANDLE_TYPE_OPAQUE_WIN32_KMT_BIT_NV       = 0x00000002,
    VK_EXTERNAL_MEMORY_HANDLE_TYPE_D3D11_IMAGE_BIT_NV            = 0x00000004,
    VK_EXTERNAL_MEMORY_HANDLE_TYPE_D3D11_IMAGE_KMT_BIT_NV        = 0x00000008,
    VK_EXTERNAL_MEMORY_HANDLE_TYPE_FLAG_BITS_MAX_ENUM_NV         = 0x7FFFFFFF
}

enum VK_EXTERNAL_MEMORY_HANDLE_TYPE_OPAQUE_WIN32_BIT_NV          = VkExternalMemoryHandleTypeFlagBitsNV.VK_EXTERNAL_MEMORY_HANDLE_TYPE_OPAQUE_WIN32_BIT_NV;
enum VK_EXTERNAL_MEMORY_HANDLE_TYPE_OPAQUE_WIN32_KMT_BIT_NV      = VkExternalMemoryHandleTypeFlagBitsNV.VK_EXTERNAL_MEMORY_HANDLE_TYPE_OPAQUE_WIN32_KMT_BIT_NV;
enum VK_EXTERNAL_MEMORY_HANDLE_TYPE_D3D11_IMAGE_BIT_NV           = VkExternalMemoryHandleTypeFlagBitsNV.VK_EXTERNAL_MEMORY_HANDLE_TYPE_D3D11_IMAGE_BIT_NV;
enum VK_EXTERNAL_MEMORY_HANDLE_TYPE_D3D11_IMAGE_KMT_BIT_NV       = VkExternalMemoryHandleTypeFlagBitsNV.VK_EXTERNAL_MEMORY_HANDLE_TYPE_D3D11_IMAGE_KMT_BIT_NV;
enum VK_EXTERNAL_MEMORY_HANDLE_TYPE_FLAG_BITS_MAX_ENUM_NV        = VkExternalMemoryHandleTypeFlagBitsNV.VK_EXTERNAL_MEMORY_HANDLE_TYPE_FLAG_BITS_MAX_ENUM_NV;
alias VkExternalMemoryHandleTypeFlagsNV = VkFlags;

enum VkExternalMemoryFeatureFlagBitsNV {
    VK_EXTERNAL_MEMORY_FEATURE_DEDICATED_ONLY_BIT_NV     = 0x00000001,
    VK_EXTERNAL_MEMORY_FEATURE_EXPORTABLE_BIT_NV         = 0x00000002,
    VK_EXTERNAL_MEMORY_FEATURE_IMPORTABLE_BIT_NV         = 0x00000004,
    VK_EXTERNAL_MEMORY_FEATURE_FLAG_BITS_MAX_ENUM_NV     = 0x7FFFFFFF
}

enum VK_EXTERNAL_MEMORY_FEATURE_DEDICATED_ONLY_BIT_NV    = VkExternalMemoryFeatureFlagBitsNV.VK_EXTERNAL_MEMORY_FEATURE_DEDICATED_ONLY_BIT_NV;
enum VK_EXTERNAL_MEMORY_FEATURE_EXPORTABLE_BIT_NV        = VkExternalMemoryFeatureFlagBitsNV.VK_EXTERNAL_MEMORY_FEATURE_EXPORTABLE_BIT_NV;
enum VK_EXTERNAL_MEMORY_FEATURE_IMPORTABLE_BIT_NV        = VkExternalMemoryFeatureFlagBitsNV.VK_EXTERNAL_MEMORY_FEATURE_IMPORTABLE_BIT_NV;
enum VK_EXTERNAL_MEMORY_FEATURE_FLAG_BITS_MAX_ENUM_NV    = VkExternalMemoryFeatureFlagBitsNV.VK_EXTERNAL_MEMORY_FEATURE_FLAG_BITS_MAX_ENUM_NV;
alias VkExternalMemoryFeatureFlagsNV = VkFlags;

struct VkExternalImageFormatPropertiesNV {
    VkImageFormatProperties            imageFormatProperties;
    VkExternalMemoryFeatureFlagsNV     externalMemoryFeatures;
    VkExternalMemoryHandleTypeFlagsNV  exportFromImportedHandleTypes;
    VkExternalMemoryHandleTypeFlagsNV  compatibleHandleTypes;
}


// - VK_NV_external_memory -
enum VK_NV_external_memory = 1;

enum VK_NV_EXTERNAL_MEMORY_SPEC_VERSION = 1;
enum VK_NV_EXTERNAL_MEMORY_EXTENSION_NAME = "VK_NV_external_memory";

struct VkExternalMemoryImageCreateInfoNV {
    VkStructureType                    sType = VK_STRUCTURE_TYPE_EXTERNAL_MEMORY_IMAGE_CREATE_INFO_NV;
    const( void )*                     pNext;
    VkExternalMemoryHandleTypeFlagsNV  handleTypes;
}

struct VkExportMemoryAllocateInfoNV {
    VkStructureType                    sType = VK_STRUCTURE_TYPE_EXPORT_MEMORY_ALLOCATE_INFO_NV;
    const( void )*                     pNext;
    VkExternalMemoryHandleTypeFlagsNV  handleTypes;
}


// - VK_EXT_validation_flags -
enum VK_EXT_validation_flags = 1;

enum VK_EXT_VALIDATION_FLAGS_SPEC_VERSION = 1;
enum VK_EXT_VALIDATION_FLAGS_EXTENSION_NAME = "VK_EXT_validation_flags";

enum VkValidationCheckEXT {
    VK_VALIDATION_CHECK_ALL_EXT          = 0,
    VK_VALIDATION_CHECK_SHADERS_EXT      = 1,
    VK_VALIDATION_CHECK_BEGIN_RANGE_EXT  = VK_VALIDATION_CHECK_ALL_EXT,
    VK_VALIDATION_CHECK_END_RANGE_EXT    = VK_VALIDATION_CHECK_SHADERS_EXT,
    VK_VALIDATION_CHECK_RANGE_SIZE_EXT   = VK_VALIDATION_CHECK_SHADERS_EXT - VK_VALIDATION_CHECK_ALL_EXT + 1,
    VK_VALIDATION_CHECK_MAX_ENUM_EXT     = 0x7FFFFFFF
}

enum VK_VALIDATION_CHECK_ALL_EXT         = VkValidationCheckEXT.VK_VALIDATION_CHECK_ALL_EXT;
enum VK_VALIDATION_CHECK_SHADERS_EXT     = VkValidationCheckEXT.VK_VALIDATION_CHECK_SHADERS_EXT;
enum VK_VALIDATION_CHECK_BEGIN_RANGE_EXT = VkValidationCheckEXT.VK_VALIDATION_CHECK_BEGIN_RANGE_EXT;
enum VK_VALIDATION_CHECK_END_RANGE_EXT   = VkValidationCheckEXT.VK_VALIDATION_CHECK_END_RANGE_EXT;
enum VK_VALIDATION_CHECK_RANGE_SIZE_EXT  = VkValidationCheckEXT.VK_VALIDATION_CHECK_RANGE_SIZE_EXT;
enum VK_VALIDATION_CHECK_MAX_ENUM_EXT    = VkValidationCheckEXT.VK_VALIDATION_CHECK_MAX_ENUM_EXT;

struct VkValidationFlagsEXT {
    VkStructureType                 sType = VK_STRUCTURE_TYPE_VALIDATION_FLAGS_EXT;
    const( void )*                  pNext;
    uint32_t                        disabledValidationCheckCount;
    const( VkValidationCheckEXT )*  pDisabledValidationChecks;
}


// - VK_EXT_shader_subgroup_ballot -
enum VK_EXT_shader_subgroup_ballot = 1;

enum VK_EXT_SHADER_SUBGROUP_BALLOT_SPEC_VERSION = 1;
enum VK_EXT_SHADER_SUBGROUP_BALLOT_EXTENSION_NAME = "VK_EXT_shader_subgroup_ballot";


// - VK_EXT_shader_subgroup_vote -
enum VK_EXT_shader_subgroup_vote = 1;

enum VK_EXT_SHADER_SUBGROUP_VOTE_SPEC_VERSION = 1;
enum VK_EXT_SHADER_SUBGROUP_VOTE_EXTENSION_NAME = "VK_EXT_shader_subgroup_vote";


// - VK_EXT_astc_decode_mode -
enum VK_EXT_astc_decode_mode = 1;

enum VK_EXT_ASTC_DECODE_MODE_SPEC_VERSION = 1;
enum VK_EXT_ASTC_DECODE_MODE_EXTENSION_NAME = "VK_EXT_astc_decode_mode";

struct VkImageViewASTCDecodeModeEXT {
    VkStructureType  sType = VK_STRUCTURE_TYPE_IMAGE_VIEW_ASTC_DECODE_MODE_EXT;
    const( void )*   pNext;
    VkFormat         decodeMode;
}

struct VkPhysicalDeviceASTCDecodeFeaturesEXT {
    VkStructureType  sType = VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_ASTC_DECODE_FEATURES_EXT;
    void*            pNext;
    VkBool32         decodeModeSharedExponent;
}


// - VK_EXT_conditional_rendering -
enum VK_EXT_conditional_rendering = 1;

enum VK_EXT_CONDITIONAL_RENDERING_SPEC_VERSION = 1;
enum VK_EXT_CONDITIONAL_RENDERING_EXTENSION_NAME = "VK_EXT_conditional_rendering";

enum VkConditionalRenderingFlagBitsEXT {
    VK_CONDITIONAL_RENDERING_INVERTED_BIT_EXT            = 0x00000001,
    VK_CONDITIONAL_RENDERING_FLAG_BITS_MAX_ENUM_EXT      = 0x7FFFFFFF
}

enum VK_CONDITIONAL_RENDERING_INVERTED_BIT_EXT           = VkConditionalRenderingFlagBitsEXT.VK_CONDITIONAL_RENDERING_INVERTED_BIT_EXT;
enum VK_CONDITIONAL_RENDERING_FLAG_BITS_MAX_ENUM_EXT     = VkConditionalRenderingFlagBitsEXT.VK_CONDITIONAL_RENDERING_FLAG_BITS_MAX_ENUM_EXT;
alias VkConditionalRenderingFlagsEXT = VkFlags;

struct VkConditionalRenderingBeginInfoEXT {
    VkStructureType                 sType = VK_STRUCTURE_TYPE_CONDITIONAL_RENDERING_BEGIN_INFO_EXT;
    const( void )*                  pNext;
    VkBuffer                        buffer;
    VkDeviceSize                    offset;
    VkConditionalRenderingFlagsEXT  flags;
}

struct VkPhysicalDeviceConditionalRenderingFeaturesEXT {
    VkStructureType  sType = VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_CONDITIONAL_RENDERING_FEATURES_EXT;
    void*            pNext;
    VkBool32         conditionalRendering;
    VkBool32         inheritedConditionalRendering;
}

struct VkCommandBufferInheritanceConditionalRenderingInfoEXT {
    VkStructureType  sType = VK_STRUCTURE_TYPE_COMMAND_BUFFER_INHERITANCE_CONDITIONAL_RENDERING_INFO_EXT;
    const( void )*   pNext;
    VkBool32         conditionalRenderingEnable;
}


// - VK_NVX_device_generated_commands -
enum VK_NVX_device_generated_commands = 1;

mixin( VK_DEFINE_NON_DISPATCHABLE_HANDLE!q{VkObjectTableNVX} );
mixin( VK_DEFINE_NON_DISPATCHABLE_HANDLE!q{VkIndirectCommandsLayoutNVX} );

enum VK_NVX_DEVICE_GENERATED_COMMANDS_SPEC_VERSION = 3;
enum VK_NVX_DEVICE_GENERATED_COMMANDS_EXTENSION_NAME = "VK_NVX_device_generated_commands";

enum VkIndirectCommandsTokenTypeNVX {
    VK_INDIRECT_COMMANDS_TOKEN_TYPE_PIPELINE_NVX         = 0,
    VK_INDIRECT_COMMANDS_TOKEN_TYPE_DESCRIPTOR_SET_NVX   = 1,
    VK_INDIRECT_COMMANDS_TOKEN_TYPE_INDEX_BUFFER_NVX     = 2,
    VK_INDIRECT_COMMANDS_TOKEN_TYPE_VERTEX_BUFFER_NVX    = 3,
    VK_INDIRECT_COMMANDS_TOKEN_TYPE_PUSH_CONSTANT_NVX    = 4,
    VK_INDIRECT_COMMANDS_TOKEN_TYPE_DRAW_INDEXED_NVX     = 5,
    VK_INDIRECT_COMMANDS_TOKEN_TYPE_DRAW_NVX             = 6,
    VK_INDIRECT_COMMANDS_TOKEN_TYPE_DISPATCH_NVX         = 7,
    VK_INDIRECT_COMMANDS_TOKEN_TYPE_BEGIN_RANGE_NVX      = VK_INDIRECT_COMMANDS_TOKEN_TYPE_PIPELINE_NVX,
    VK_INDIRECT_COMMANDS_TOKEN_TYPE_END_RANGE_NVX        = VK_INDIRECT_COMMANDS_TOKEN_TYPE_DISPATCH_NVX,
    VK_INDIRECT_COMMANDS_TOKEN_TYPE_RANGE_SIZE_NVX       = VK_INDIRECT_COMMANDS_TOKEN_TYPE_DISPATCH_NVX - VK_INDIRECT_COMMANDS_TOKEN_TYPE_PIPELINE_NVX + 1,
    VK_INDIRECT_COMMANDS_TOKEN_TYPE_MAX_ENUM_NVX         = 0x7FFFFFFF
}

enum VK_INDIRECT_COMMANDS_TOKEN_TYPE_PIPELINE_NVX        = VkIndirectCommandsTokenTypeNVX.VK_INDIRECT_COMMANDS_TOKEN_TYPE_PIPELINE_NVX;
enum VK_INDIRECT_COMMANDS_TOKEN_TYPE_DESCRIPTOR_SET_NVX  = VkIndirectCommandsTokenTypeNVX.VK_INDIRECT_COMMANDS_TOKEN_TYPE_DESCRIPTOR_SET_NVX;
enum VK_INDIRECT_COMMANDS_TOKEN_TYPE_INDEX_BUFFER_NVX    = VkIndirectCommandsTokenTypeNVX.VK_INDIRECT_COMMANDS_TOKEN_TYPE_INDEX_BUFFER_NVX;
enum VK_INDIRECT_COMMANDS_TOKEN_TYPE_VERTEX_BUFFER_NVX   = VkIndirectCommandsTokenTypeNVX.VK_INDIRECT_COMMANDS_TOKEN_TYPE_VERTEX_BUFFER_NVX;
enum VK_INDIRECT_COMMANDS_TOKEN_TYPE_PUSH_CONSTANT_NVX   = VkIndirectCommandsTokenTypeNVX.VK_INDIRECT_COMMANDS_TOKEN_TYPE_PUSH_CONSTANT_NVX;
enum VK_INDIRECT_COMMANDS_TOKEN_TYPE_DRAW_INDEXED_NVX    = VkIndirectCommandsTokenTypeNVX.VK_INDIRECT_COMMANDS_TOKEN_TYPE_DRAW_INDEXED_NVX;
enum VK_INDIRECT_COMMANDS_TOKEN_TYPE_DRAW_NVX            = VkIndirectCommandsTokenTypeNVX.VK_INDIRECT_COMMANDS_TOKEN_TYPE_DRAW_NVX;
enum VK_INDIRECT_COMMANDS_TOKEN_TYPE_DISPATCH_NVX        = VkIndirectCommandsTokenTypeNVX.VK_INDIRECT_COMMANDS_TOKEN_TYPE_DISPATCH_NVX;
enum VK_INDIRECT_COMMANDS_TOKEN_TYPE_BEGIN_RANGE_NVX     = VkIndirectCommandsTokenTypeNVX.VK_INDIRECT_COMMANDS_TOKEN_TYPE_BEGIN_RANGE_NVX;
enum VK_INDIRECT_COMMANDS_TOKEN_TYPE_END_RANGE_NVX       = VkIndirectCommandsTokenTypeNVX.VK_INDIRECT_COMMANDS_TOKEN_TYPE_END_RANGE_NVX;
enum VK_INDIRECT_COMMANDS_TOKEN_TYPE_RANGE_SIZE_NVX      = VkIndirectCommandsTokenTypeNVX.VK_INDIRECT_COMMANDS_TOKEN_TYPE_RANGE_SIZE_NVX;
enum VK_INDIRECT_COMMANDS_TOKEN_TYPE_MAX_ENUM_NVX        = VkIndirectCommandsTokenTypeNVX.VK_INDIRECT_COMMANDS_TOKEN_TYPE_MAX_ENUM_NVX;

enum VkObjectEntryTypeNVX {
    VK_OBJECT_ENTRY_TYPE_DESCRIPTOR_SET_NVX      = 0,
    VK_OBJECT_ENTRY_TYPE_PIPELINE_NVX            = 1,
    VK_OBJECT_ENTRY_TYPE_INDEX_BUFFER_NVX        = 2,
    VK_OBJECT_ENTRY_TYPE_VERTEX_BUFFER_NVX       = 3,
    VK_OBJECT_ENTRY_TYPE_PUSH_CONSTANT_NVX       = 4,
    VK_OBJECT_ENTRY_TYPE_BEGIN_RANGE_NVX         = VK_OBJECT_ENTRY_TYPE_DESCRIPTOR_SET_NVX,
    VK_OBJECT_ENTRY_TYPE_END_RANGE_NVX           = VK_OBJECT_ENTRY_TYPE_PUSH_CONSTANT_NVX,
    VK_OBJECT_ENTRY_TYPE_RANGE_SIZE_NVX          = VK_OBJECT_ENTRY_TYPE_PUSH_CONSTANT_NVX - VK_OBJECT_ENTRY_TYPE_DESCRIPTOR_SET_NVX + 1,
    VK_OBJECT_ENTRY_TYPE_MAX_ENUM_NVX            = 0x7FFFFFFF
}

enum VK_OBJECT_ENTRY_TYPE_DESCRIPTOR_SET_NVX     = VkObjectEntryTypeNVX.VK_OBJECT_ENTRY_TYPE_DESCRIPTOR_SET_NVX;
enum VK_OBJECT_ENTRY_TYPE_PIPELINE_NVX           = VkObjectEntryTypeNVX.VK_OBJECT_ENTRY_TYPE_PIPELINE_NVX;
enum VK_OBJECT_ENTRY_TYPE_INDEX_BUFFER_NVX       = VkObjectEntryTypeNVX.VK_OBJECT_ENTRY_TYPE_INDEX_BUFFER_NVX;
enum VK_OBJECT_ENTRY_TYPE_VERTEX_BUFFER_NVX      = VkObjectEntryTypeNVX.VK_OBJECT_ENTRY_TYPE_VERTEX_BUFFER_NVX;
enum VK_OBJECT_ENTRY_TYPE_PUSH_CONSTANT_NVX      = VkObjectEntryTypeNVX.VK_OBJECT_ENTRY_TYPE_PUSH_CONSTANT_NVX;
enum VK_OBJECT_ENTRY_TYPE_BEGIN_RANGE_NVX        = VkObjectEntryTypeNVX.VK_OBJECT_ENTRY_TYPE_BEGIN_RANGE_NVX;
enum VK_OBJECT_ENTRY_TYPE_END_RANGE_NVX          = VkObjectEntryTypeNVX.VK_OBJECT_ENTRY_TYPE_END_RANGE_NVX;
enum VK_OBJECT_ENTRY_TYPE_RANGE_SIZE_NVX         = VkObjectEntryTypeNVX.VK_OBJECT_ENTRY_TYPE_RANGE_SIZE_NVX;
enum VK_OBJECT_ENTRY_TYPE_MAX_ENUM_NVX           = VkObjectEntryTypeNVX.VK_OBJECT_ENTRY_TYPE_MAX_ENUM_NVX;

enum VkIndirectCommandsLayoutUsageFlagBitsNVX {
    VK_INDIRECT_COMMANDS_LAYOUT_USAGE_UNORDERED_SEQUENCES_BIT_NVX        = 0x00000001,
    VK_INDIRECT_COMMANDS_LAYOUT_USAGE_SPARSE_SEQUENCES_BIT_NVX           = 0x00000002,
    VK_INDIRECT_COMMANDS_LAYOUT_USAGE_EMPTY_EXECUTIONS_BIT_NVX           = 0x00000004,
    VK_INDIRECT_COMMANDS_LAYOUT_USAGE_INDEXED_SEQUENCES_BIT_NVX          = 0x00000008,
    VK_INDIRECT_COMMANDS_LAYOUT_USAGE_FLAG_BITS_MAX_ENUM_NVX             = 0x7FFFFFFF
}

enum VK_INDIRECT_COMMANDS_LAYOUT_USAGE_UNORDERED_SEQUENCES_BIT_NVX       = VkIndirectCommandsLayoutUsageFlagBitsNVX.VK_INDIRECT_COMMANDS_LAYOUT_USAGE_UNORDERED_SEQUENCES_BIT_NVX;
enum VK_INDIRECT_COMMANDS_LAYOUT_USAGE_SPARSE_SEQUENCES_BIT_NVX          = VkIndirectCommandsLayoutUsageFlagBitsNVX.VK_INDIRECT_COMMANDS_LAYOUT_USAGE_SPARSE_SEQUENCES_BIT_NVX;
enum VK_INDIRECT_COMMANDS_LAYOUT_USAGE_EMPTY_EXECUTIONS_BIT_NVX          = VkIndirectCommandsLayoutUsageFlagBitsNVX.VK_INDIRECT_COMMANDS_LAYOUT_USAGE_EMPTY_EXECUTIONS_BIT_NVX;
enum VK_INDIRECT_COMMANDS_LAYOUT_USAGE_INDEXED_SEQUENCES_BIT_NVX         = VkIndirectCommandsLayoutUsageFlagBitsNVX.VK_INDIRECT_COMMANDS_LAYOUT_USAGE_INDEXED_SEQUENCES_BIT_NVX;
enum VK_INDIRECT_COMMANDS_LAYOUT_USAGE_FLAG_BITS_MAX_ENUM_NVX            = VkIndirectCommandsLayoutUsageFlagBitsNVX.VK_INDIRECT_COMMANDS_LAYOUT_USAGE_FLAG_BITS_MAX_ENUM_NVX;
alias VkIndirectCommandsLayoutUsageFlagsNVX = VkFlags;

enum VkObjectEntryUsageFlagBitsNVX {
    VK_OBJECT_ENTRY_USAGE_GRAPHICS_BIT_NVX       = 0x00000001,
    VK_OBJECT_ENTRY_USAGE_COMPUTE_BIT_NVX        = 0x00000002,
    VK_OBJECT_ENTRY_USAGE_FLAG_BITS_MAX_ENUM_NVX = 0x7FFFFFFF
}

enum VK_OBJECT_ENTRY_USAGE_GRAPHICS_BIT_NVX      = VkObjectEntryUsageFlagBitsNVX.VK_OBJECT_ENTRY_USAGE_GRAPHICS_BIT_NVX;
enum VK_OBJECT_ENTRY_USAGE_COMPUTE_BIT_NVX       = VkObjectEntryUsageFlagBitsNVX.VK_OBJECT_ENTRY_USAGE_COMPUTE_BIT_NVX;
enum VK_OBJECT_ENTRY_USAGE_FLAG_BITS_MAX_ENUM_NVX = VkObjectEntryUsageFlagBitsNVX.VK_OBJECT_ENTRY_USAGE_FLAG_BITS_MAX_ENUM_NVX;
alias VkObjectEntryUsageFlagsNVX = VkFlags;

struct VkDeviceGeneratedCommandsFeaturesNVX {
    VkStructureType  sType = VK_STRUCTURE_TYPE_DEVICE_GENERATED_COMMANDS_FEATURES_NVX;
    const( void )*   pNext;
    VkBool32         computeBindingPointSupport;
}

struct VkDeviceGeneratedCommandsLimitsNVX {
    VkStructureType  sType = VK_STRUCTURE_TYPE_DEVICE_GENERATED_COMMANDS_LIMITS_NVX;
    const( void )*   pNext;
    uint32_t         maxIndirectCommandsLayoutTokenCount;
    uint32_t         maxObjectEntryCounts;
    uint32_t         minSequenceCountBufferOffsetAlignment;
    uint32_t         minSequenceIndexBufferOffsetAlignment;
    uint32_t         minCommandsTokenBufferOffsetAlignment;
}

struct VkIndirectCommandsTokenNVX {
    VkIndirectCommandsTokenTypeNVX  tokenType;
    VkBuffer                        buffer;
    VkDeviceSize                    offset;
}

struct VkIndirectCommandsLayoutTokenNVX {
    VkIndirectCommandsTokenTypeNVX  tokenType;
    uint32_t                        bindingUnit;
    uint32_t                        dynamicCount;
    uint32_t                        divisor;
}

struct VkIndirectCommandsLayoutCreateInfoNVX {
    VkStructureType                             sType = VK_STRUCTURE_TYPE_INDIRECT_COMMANDS_LAYOUT_CREATE_INFO_NVX;
    const( void )*                              pNext;
    VkPipelineBindPoint                         pipelineBindPoint;
    VkIndirectCommandsLayoutUsageFlagsNVX       flags;
    uint32_t                                    tokenCount;
    const( VkIndirectCommandsLayoutTokenNVX )*  pTokens;
}

struct VkCmdProcessCommandsInfoNVX {
    VkStructureType                       sType = VK_STRUCTURE_TYPE_CMD_PROCESS_COMMANDS_INFO_NVX;
    const( void )*                        pNext;
    VkObjectTableNVX                      objectTable;
    VkIndirectCommandsLayoutNVX           indirectCommandsLayout;
    uint32_t                              indirectCommandsTokenCount;
    const( VkIndirectCommandsTokenNVX )*  pIndirectCommandsTokens;
    uint32_t                              maxSequencesCount;
    VkCommandBuffer                       targetCommandBuffer;
    VkBuffer                              sequencesCountBuffer;
    VkDeviceSize                          sequencesCountOffset;
    VkBuffer                              sequencesIndexBuffer;
    VkDeviceSize                          sequencesIndexOffset;
}

struct VkCmdReserveSpaceForCommandsInfoNVX {
    VkStructureType              sType = VK_STRUCTURE_TYPE_CMD_RESERVE_SPACE_FOR_COMMANDS_INFO_NVX;
    const( void )*               pNext;
    VkObjectTableNVX             objectTable;
    VkIndirectCommandsLayoutNVX  indirectCommandsLayout;
    uint32_t                     maxSequencesCount;
}

struct VkObjectTableCreateInfoNVX {
    VkStructureType                       sType = VK_STRUCTURE_TYPE_OBJECT_TABLE_CREATE_INFO_NVX;
    const( void )*                        pNext;
    uint32_t                              objectCount;
    const( VkObjectEntryTypeNVX )*        pObjectEntryTypes;
    const( uint32_t )*                    pObjectEntryCounts;
    const( VkObjectEntryUsageFlagsNVX )*  pObjectEntryUsageFlags;
    uint32_t                              maxUniformBuffersPerDescriptor;
    uint32_t                              maxStorageBuffersPerDescriptor;
    uint32_t                              maxStorageImagesPerDescriptor;
    uint32_t                              maxSampledImagesPerDescriptor;
    uint32_t                              maxPipelineLayouts;
}

struct VkObjectTableEntryNVX {
    VkObjectEntryTypeNVX        type;
    VkObjectEntryUsageFlagsNVX  flags;
}

struct VkObjectTablePipelineEntryNVX {
    VkObjectEntryTypeNVX        type;
    VkObjectEntryUsageFlagsNVX  flags;
    VkPipeline                  pipeline;
}

struct VkObjectTableDescriptorSetEntryNVX {
    VkObjectEntryTypeNVX        type;
    VkObjectEntryUsageFlagsNVX  flags;
    VkPipelineLayout            pipelineLayout;
    VkDescriptorSet             descriptorSet;
}

struct VkObjectTableVertexBufferEntryNVX {
    VkObjectEntryTypeNVX        type;
    VkObjectEntryUsageFlagsNVX  flags;
    VkBuffer                    buffer;
}

struct VkObjectTableIndexBufferEntryNVX {
    VkObjectEntryTypeNVX        type;
    VkObjectEntryUsageFlagsNVX  flags;
    VkBuffer                    buffer;
    VkIndexType                 indexType;
}

struct VkObjectTablePushConstantEntryNVX {
    VkObjectEntryTypeNVX        type;
    VkObjectEntryUsageFlagsNVX  flags;
    VkPipelineLayout            pipelineLayout;
    VkShaderStageFlags          stageFlags;
}


// - VK_NV_clip_space_w_scaling -
enum VK_NV_clip_space_w_scaling = 1;

enum VK_NV_CLIP_SPACE_W_SCALING_SPEC_VERSION = 1;
enum VK_NV_CLIP_SPACE_W_SCALING_EXTENSION_NAME = "VK_NV_clip_space_w_scaling";

struct VkViewportWScalingNV {
    float  xcoeff;
    float  ycoeff;
}

struct VkPipelineViewportWScalingStateCreateInfoNV {
    VkStructureType                 sType = VK_STRUCTURE_TYPE_PIPELINE_VIEWPORT_W_SCALING_STATE_CREATE_INFO_NV;
    const( void )*                  pNext;
    VkBool32                        viewportWScalingEnable;
    uint32_t                        viewportCount;
    const( VkViewportWScalingNV )*  pViewportWScalings;
}


// - VK_EXT_direct_mode_display -
enum VK_EXT_direct_mode_display = 1;

enum VK_EXT_DIRECT_MODE_DISPLAY_SPEC_VERSION = 1;
enum VK_EXT_DIRECT_MODE_DISPLAY_EXTENSION_NAME = "VK_EXT_direct_mode_display";


// - VK_EXT_display_surface_counter -
enum VK_EXT_display_surface_counter = 1;

enum VK_EXT_DISPLAY_SURFACE_COUNTER_SPEC_VERSION = 1;
enum VK_EXT_DISPLAY_SURFACE_COUNTER_EXTENSION_NAME = "VK_EXT_display_surface_counter";

enum VkSurfaceCounterFlagBitsEXT {
    VK_SURFACE_COUNTER_VBLANK_EXT                = 0x00000001,
    VK_SURFACE_COUNTER_FLAG_BITS_MAX_ENUM_EXT    = 0x7FFFFFFF
}

enum VK_SURFACE_COUNTER_VBLANK_EXT               = VkSurfaceCounterFlagBitsEXT.VK_SURFACE_COUNTER_VBLANK_EXT;
enum VK_SURFACE_COUNTER_FLAG_BITS_MAX_ENUM_EXT   = VkSurfaceCounterFlagBitsEXT.VK_SURFACE_COUNTER_FLAG_BITS_MAX_ENUM_EXT;
alias VkSurfaceCounterFlagsEXT = VkFlags;

struct VkSurfaceCapabilities2EXT {
    VkStructureType                sType = VK_STRUCTURE_TYPE_SURFACE_CAPABILITIES_2_EXT;
    void*                          pNext;
    uint32_t                       minImageCount;
    uint32_t                       maxImageCount;
    VkExtent2D                     currentExtent;
    VkExtent2D                     minImageExtent;
    VkExtent2D                     maxImageExtent;
    uint32_t                       maxImageArrayLayers;
    VkSurfaceTransformFlagsKHR     supportedTransforms;
    VkSurfaceTransformFlagBitsKHR  currentTransform;
    VkCompositeAlphaFlagsKHR       supportedCompositeAlpha;
    VkImageUsageFlags              supportedUsageFlags;
    VkSurfaceCounterFlagsEXT       supportedSurfaceCounters;
}


// - VK_EXT_display_control -
enum VK_EXT_display_control = 1;

enum VK_EXT_DISPLAY_CONTROL_SPEC_VERSION = 1;
enum VK_EXT_DISPLAY_CONTROL_EXTENSION_NAME = "VK_EXT_display_control";

enum VkDisplayPowerStateEXT {
    VK_DISPLAY_POWER_STATE_OFF_EXT       = 0,
    VK_DISPLAY_POWER_STATE_SUSPEND_EXT   = 1,
    VK_DISPLAY_POWER_STATE_ON_EXT        = 2,
    VK_DISPLAY_POWER_STATE_BEGIN_RANGE_EXT = VK_DISPLAY_POWER_STATE_OFF_EXT,
    VK_DISPLAY_POWER_STATE_END_RANGE_EXT = VK_DISPLAY_POWER_STATE_ON_EXT,
    VK_DISPLAY_POWER_STATE_RANGE_SIZE_EXT = VK_DISPLAY_POWER_STATE_ON_EXT - VK_DISPLAY_POWER_STATE_OFF_EXT + 1,
    VK_DISPLAY_POWER_STATE_MAX_ENUM_EXT  = 0x7FFFFFFF
}

enum VK_DISPLAY_POWER_STATE_OFF_EXT      = VkDisplayPowerStateEXT.VK_DISPLAY_POWER_STATE_OFF_EXT;
enum VK_DISPLAY_POWER_STATE_SUSPEND_EXT  = VkDisplayPowerStateEXT.VK_DISPLAY_POWER_STATE_SUSPEND_EXT;
enum VK_DISPLAY_POWER_STATE_ON_EXT       = VkDisplayPowerStateEXT.VK_DISPLAY_POWER_STATE_ON_EXT;
enum VK_DISPLAY_POWER_STATE_BEGIN_RANGE_EXT = VkDisplayPowerStateEXT.VK_DISPLAY_POWER_STATE_BEGIN_RANGE_EXT;
enum VK_DISPLAY_POWER_STATE_END_RANGE_EXT = VkDisplayPowerStateEXT.VK_DISPLAY_POWER_STATE_END_RANGE_EXT;
enum VK_DISPLAY_POWER_STATE_RANGE_SIZE_EXT = VkDisplayPowerStateEXT.VK_DISPLAY_POWER_STATE_RANGE_SIZE_EXT;
enum VK_DISPLAY_POWER_STATE_MAX_ENUM_EXT = VkDisplayPowerStateEXT.VK_DISPLAY_POWER_STATE_MAX_ENUM_EXT;

enum VkDeviceEventTypeEXT {
    VK_DEVICE_EVENT_TYPE_DISPLAY_HOTPLUG_EXT     = 0,
    VK_DEVICE_EVENT_TYPE_BEGIN_RANGE_EXT         = VK_DEVICE_EVENT_TYPE_DISPLAY_HOTPLUG_EXT,
    VK_DEVICE_EVENT_TYPE_END_RANGE_EXT           = VK_DEVICE_EVENT_TYPE_DISPLAY_HOTPLUG_EXT,
    VK_DEVICE_EVENT_TYPE_RANGE_SIZE_EXT          = VK_DEVICE_EVENT_TYPE_DISPLAY_HOTPLUG_EXT - VK_DEVICE_EVENT_TYPE_DISPLAY_HOTPLUG_EXT + 1,
    VK_DEVICE_EVENT_TYPE_MAX_ENUM_EXT            = 0x7FFFFFFF
}

enum VK_DEVICE_EVENT_TYPE_DISPLAY_HOTPLUG_EXT    = VkDeviceEventTypeEXT.VK_DEVICE_EVENT_TYPE_DISPLAY_HOTPLUG_EXT;
enum VK_DEVICE_EVENT_TYPE_BEGIN_RANGE_EXT        = VkDeviceEventTypeEXT.VK_DEVICE_EVENT_TYPE_BEGIN_RANGE_EXT;
enum VK_DEVICE_EVENT_TYPE_END_RANGE_EXT          = VkDeviceEventTypeEXT.VK_DEVICE_EVENT_TYPE_END_RANGE_EXT;
enum VK_DEVICE_EVENT_TYPE_RANGE_SIZE_EXT         = VkDeviceEventTypeEXT.VK_DEVICE_EVENT_TYPE_RANGE_SIZE_EXT;
enum VK_DEVICE_EVENT_TYPE_MAX_ENUM_EXT           = VkDeviceEventTypeEXT.VK_DEVICE_EVENT_TYPE_MAX_ENUM_EXT;

enum VkDisplayEventTypeEXT {
    VK_DISPLAY_EVENT_TYPE_FIRST_PIXEL_OUT_EXT    = 0,
    VK_DISPLAY_EVENT_TYPE_BEGIN_RANGE_EXT        = VK_DISPLAY_EVENT_TYPE_FIRST_PIXEL_OUT_EXT,
    VK_DISPLAY_EVENT_TYPE_END_RANGE_EXT          = VK_DISPLAY_EVENT_TYPE_FIRST_PIXEL_OUT_EXT,
    VK_DISPLAY_EVENT_TYPE_RANGE_SIZE_EXT         = VK_DISPLAY_EVENT_TYPE_FIRST_PIXEL_OUT_EXT - VK_DISPLAY_EVENT_TYPE_FIRST_PIXEL_OUT_EXT + 1,
    VK_DISPLAY_EVENT_TYPE_MAX_ENUM_EXT           = 0x7FFFFFFF
}

enum VK_DISPLAY_EVENT_TYPE_FIRST_PIXEL_OUT_EXT   = VkDisplayEventTypeEXT.VK_DISPLAY_EVENT_TYPE_FIRST_PIXEL_OUT_EXT;
enum VK_DISPLAY_EVENT_TYPE_BEGIN_RANGE_EXT       = VkDisplayEventTypeEXT.VK_DISPLAY_EVENT_TYPE_BEGIN_RANGE_EXT;
enum VK_DISPLAY_EVENT_TYPE_END_RANGE_EXT         = VkDisplayEventTypeEXT.VK_DISPLAY_EVENT_TYPE_END_RANGE_EXT;
enum VK_DISPLAY_EVENT_TYPE_RANGE_SIZE_EXT        = VkDisplayEventTypeEXT.VK_DISPLAY_EVENT_TYPE_RANGE_SIZE_EXT;
enum VK_DISPLAY_EVENT_TYPE_MAX_ENUM_EXT          = VkDisplayEventTypeEXT.VK_DISPLAY_EVENT_TYPE_MAX_ENUM_EXT;

struct VkDisplayPowerInfoEXT {
    VkStructureType         sType = VK_STRUCTURE_TYPE_DISPLAY_POWER_INFO_EXT;
    const( void )*          pNext;
    VkDisplayPowerStateEXT  powerState;
}

struct VkDeviceEventInfoEXT {
    VkStructureType       sType = VK_STRUCTURE_TYPE_DEVICE_EVENT_INFO_EXT;
    const( void )*        pNext;
    VkDeviceEventTypeEXT  deviceEvent;
}

struct VkDisplayEventInfoEXT {
    VkStructureType        sType = VK_STRUCTURE_TYPE_DISPLAY_EVENT_INFO_EXT;
    const( void )*         pNext;
    VkDisplayEventTypeEXT  displayEvent;
}

struct VkSwapchainCounterCreateInfoEXT {
    VkStructureType           sType = VK_STRUCTURE_TYPE_SWAPCHAIN_COUNTER_CREATE_INFO_EXT;
    const( void )*            pNext;
    VkSurfaceCounterFlagsEXT  surfaceCounters;
}


// - VK_GOOGLE_display_timing -
enum VK_GOOGLE_display_timing = 1;

enum VK_GOOGLE_DISPLAY_TIMING_SPEC_VERSION = 1;
enum VK_GOOGLE_DISPLAY_TIMING_EXTENSION_NAME = "VK_GOOGLE_display_timing";

struct VkRefreshCycleDurationGOOGLE {
    uint64_t  refreshDuration;
}

struct VkPastPresentationTimingGOOGLE {
    uint32_t  presentID;
    uint64_t  desiredPresentTime;
    uint64_t  actualPresentTime;
    uint64_t  earliestPresentTime;
    uint64_t  presentMargin;
}

struct VkPresentTimeGOOGLE {
    uint32_t  presentID;
    uint64_t  desiredPresentTime;
}

struct VkPresentTimesInfoGOOGLE {
    VkStructureType                sType = VK_STRUCTURE_TYPE_PRESENT_TIMES_INFO_GOOGLE;
    const( void )*                 pNext;
    uint32_t                       swapchainCount;
    const( VkPresentTimeGOOGLE )*  pTimes;
}


// - VK_NV_sample_mask_override_coverage -
enum VK_NV_sample_mask_override_coverage = 1;

enum VK_NV_SAMPLE_MASK_OVERRIDE_COVERAGE_SPEC_VERSION = 1;
enum VK_NV_SAMPLE_MASK_OVERRIDE_COVERAGE_EXTENSION_NAME = "VK_NV_sample_mask_override_coverage";


// - VK_NV_geometry_shader_passthrough -
enum VK_NV_geometry_shader_passthrough = 1;

enum VK_NV_GEOMETRY_SHADER_PASSTHROUGH_SPEC_VERSION = 1;
enum VK_NV_GEOMETRY_SHADER_PASSTHROUGH_EXTENSION_NAME = "VK_NV_geometry_shader_passthrough";


// - VK_NV_viewport_array2 -
enum VK_NV_viewport_array2 = 1;

enum VK_NV_VIEWPORT_ARRAY2_SPEC_VERSION = 1;
enum VK_NV_VIEWPORT_ARRAY2_EXTENSION_NAME = "VK_NV_viewport_array2";


// - VK_NVX_multiview_per_view_attributes -
enum VK_NVX_multiview_per_view_attributes = 1;

enum VK_NVX_MULTIVIEW_PER_VIEW_ATTRIBUTES_SPEC_VERSION = 1;
enum VK_NVX_MULTIVIEW_PER_VIEW_ATTRIBUTES_EXTENSION_NAME = "VK_NVX_multiview_per_view_attributes";

struct VkPhysicalDeviceMultiviewPerViewAttributesPropertiesNVX {
    VkStructureType  sType = VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_MULTIVIEW_PER_VIEW_ATTRIBUTES_PROPERTIES_NVX;
    void*            pNext;
    VkBool32         perViewPositionAllComponents;
}


// - VK_NV_viewport_swizzle -
enum VK_NV_viewport_swizzle = 1;

enum VK_NV_VIEWPORT_SWIZZLE_SPEC_VERSION = 1;
enum VK_NV_VIEWPORT_SWIZZLE_EXTENSION_NAME = "VK_NV_viewport_swizzle";

enum VkViewportCoordinateSwizzleNV {
    VK_VIEWPORT_COORDINATE_SWIZZLE_POSITIVE_X_NV         = 0,
    VK_VIEWPORT_COORDINATE_SWIZZLE_NEGATIVE_X_NV         = 1,
    VK_VIEWPORT_COORDINATE_SWIZZLE_POSITIVE_Y_NV         = 2,
    VK_VIEWPORT_COORDINATE_SWIZZLE_NEGATIVE_Y_NV         = 3,
    VK_VIEWPORT_COORDINATE_SWIZZLE_POSITIVE_Z_NV         = 4,
    VK_VIEWPORT_COORDINATE_SWIZZLE_NEGATIVE_Z_NV         = 5,
    VK_VIEWPORT_COORDINATE_SWIZZLE_POSITIVE_W_NV         = 6,
    VK_VIEWPORT_COORDINATE_SWIZZLE_NEGATIVE_W_NV         = 7,
    VK_VIEWPORT_COORDINATE_SWIZZLE_BEGIN_RANGE_NV        = VK_VIEWPORT_COORDINATE_SWIZZLE_POSITIVE_X_NV,
    VK_VIEWPORT_COORDINATE_SWIZZLE_END_RANGE_NV          = VK_VIEWPORT_COORDINATE_SWIZZLE_NEGATIVE_W_NV,
    VK_VIEWPORT_COORDINATE_SWIZZLE_RANGE_SIZE_NV         = VK_VIEWPORT_COORDINATE_SWIZZLE_NEGATIVE_W_NV - VK_VIEWPORT_COORDINATE_SWIZZLE_POSITIVE_X_NV + 1,
    VK_VIEWPORT_COORDINATE_SWIZZLE_MAX_ENUM_NV           = 0x7FFFFFFF
}

enum VK_VIEWPORT_COORDINATE_SWIZZLE_POSITIVE_X_NV        = VkViewportCoordinateSwizzleNV.VK_VIEWPORT_COORDINATE_SWIZZLE_POSITIVE_X_NV;
enum VK_VIEWPORT_COORDINATE_SWIZZLE_NEGATIVE_X_NV        = VkViewportCoordinateSwizzleNV.VK_VIEWPORT_COORDINATE_SWIZZLE_NEGATIVE_X_NV;
enum VK_VIEWPORT_COORDINATE_SWIZZLE_POSITIVE_Y_NV        = VkViewportCoordinateSwizzleNV.VK_VIEWPORT_COORDINATE_SWIZZLE_POSITIVE_Y_NV;
enum VK_VIEWPORT_COORDINATE_SWIZZLE_NEGATIVE_Y_NV        = VkViewportCoordinateSwizzleNV.VK_VIEWPORT_COORDINATE_SWIZZLE_NEGATIVE_Y_NV;
enum VK_VIEWPORT_COORDINATE_SWIZZLE_POSITIVE_Z_NV        = VkViewportCoordinateSwizzleNV.VK_VIEWPORT_COORDINATE_SWIZZLE_POSITIVE_Z_NV;
enum VK_VIEWPORT_COORDINATE_SWIZZLE_NEGATIVE_Z_NV        = VkViewportCoordinateSwizzleNV.VK_VIEWPORT_COORDINATE_SWIZZLE_NEGATIVE_Z_NV;
enum VK_VIEWPORT_COORDINATE_SWIZZLE_POSITIVE_W_NV        = VkViewportCoordinateSwizzleNV.VK_VIEWPORT_COORDINATE_SWIZZLE_POSITIVE_W_NV;
enum VK_VIEWPORT_COORDINATE_SWIZZLE_NEGATIVE_W_NV        = VkViewportCoordinateSwizzleNV.VK_VIEWPORT_COORDINATE_SWIZZLE_NEGATIVE_W_NV;
enum VK_VIEWPORT_COORDINATE_SWIZZLE_BEGIN_RANGE_NV       = VkViewportCoordinateSwizzleNV.VK_VIEWPORT_COORDINATE_SWIZZLE_BEGIN_RANGE_NV;
enum VK_VIEWPORT_COORDINATE_SWIZZLE_END_RANGE_NV         = VkViewportCoordinateSwizzleNV.VK_VIEWPORT_COORDINATE_SWIZZLE_END_RANGE_NV;
enum VK_VIEWPORT_COORDINATE_SWIZZLE_RANGE_SIZE_NV        = VkViewportCoordinateSwizzleNV.VK_VIEWPORT_COORDINATE_SWIZZLE_RANGE_SIZE_NV;
enum VK_VIEWPORT_COORDINATE_SWIZZLE_MAX_ENUM_NV          = VkViewportCoordinateSwizzleNV.VK_VIEWPORT_COORDINATE_SWIZZLE_MAX_ENUM_NV;

alias VkPipelineViewportSwizzleStateCreateFlagsNV = VkFlags;

struct VkViewportSwizzleNV {
    VkViewportCoordinateSwizzleNV  x;
    VkViewportCoordinateSwizzleNV  y;
    VkViewportCoordinateSwizzleNV  z;
    VkViewportCoordinateSwizzleNV  w;
}

struct VkPipelineViewportSwizzleStateCreateInfoNV {
    VkStructureType                              sType = VK_STRUCTURE_TYPE_PIPELINE_VIEWPORT_SWIZZLE_STATE_CREATE_INFO_NV;
    const( void )*                               pNext;
    VkPipelineViewportSwizzleStateCreateFlagsNV  flags;
    uint32_t                                     viewportCount;
    const( VkViewportSwizzleNV )*                pViewportSwizzles;
}


// - VK_EXT_discard_rectangles -
enum VK_EXT_discard_rectangles = 1;

enum VK_EXT_DISCARD_RECTANGLES_SPEC_VERSION = 1;
enum VK_EXT_DISCARD_RECTANGLES_EXTENSION_NAME = "VK_EXT_discard_rectangles";

enum VkDiscardRectangleModeEXT {
    VK_DISCARD_RECTANGLE_MODE_INCLUSIVE_EXT      = 0,
    VK_DISCARD_RECTANGLE_MODE_EXCLUSIVE_EXT      = 1,
    VK_DISCARD_RECTANGLE_MODE_BEGIN_RANGE_EXT    = VK_DISCARD_RECTANGLE_MODE_INCLUSIVE_EXT,
    VK_DISCARD_RECTANGLE_MODE_END_RANGE_EXT      = VK_DISCARD_RECTANGLE_MODE_EXCLUSIVE_EXT,
    VK_DISCARD_RECTANGLE_MODE_RANGE_SIZE_EXT     = VK_DISCARD_RECTANGLE_MODE_EXCLUSIVE_EXT - VK_DISCARD_RECTANGLE_MODE_INCLUSIVE_EXT + 1,
    VK_DISCARD_RECTANGLE_MODE_MAX_ENUM_EXT       = 0x7FFFFFFF
}

enum VK_DISCARD_RECTANGLE_MODE_INCLUSIVE_EXT     = VkDiscardRectangleModeEXT.VK_DISCARD_RECTANGLE_MODE_INCLUSIVE_EXT;
enum VK_DISCARD_RECTANGLE_MODE_EXCLUSIVE_EXT     = VkDiscardRectangleModeEXT.VK_DISCARD_RECTANGLE_MODE_EXCLUSIVE_EXT;
enum VK_DISCARD_RECTANGLE_MODE_BEGIN_RANGE_EXT   = VkDiscardRectangleModeEXT.VK_DISCARD_RECTANGLE_MODE_BEGIN_RANGE_EXT;
enum VK_DISCARD_RECTANGLE_MODE_END_RANGE_EXT     = VkDiscardRectangleModeEXT.VK_DISCARD_RECTANGLE_MODE_END_RANGE_EXT;
enum VK_DISCARD_RECTANGLE_MODE_RANGE_SIZE_EXT    = VkDiscardRectangleModeEXT.VK_DISCARD_RECTANGLE_MODE_RANGE_SIZE_EXT;
enum VK_DISCARD_RECTANGLE_MODE_MAX_ENUM_EXT      = VkDiscardRectangleModeEXT.VK_DISCARD_RECTANGLE_MODE_MAX_ENUM_EXT;

alias VkPipelineDiscardRectangleStateCreateFlagsEXT = VkFlags;

struct VkPhysicalDeviceDiscardRectanglePropertiesEXT {
    VkStructureType  sType = VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_DISCARD_RECTANGLE_PROPERTIES_EXT;
    void*            pNext;
    uint32_t         maxDiscardRectangles;
}

struct VkPipelineDiscardRectangleStateCreateInfoEXT {
    VkStructureType                                sType = VK_STRUCTURE_TYPE_PIPELINE_DISCARD_RECTANGLE_STATE_CREATE_INFO_EXT;
    const( void )*                                 pNext;
    VkPipelineDiscardRectangleStateCreateFlagsEXT  flags;
    VkDiscardRectangleModeEXT                      discardRectangleMode;
    uint32_t                                       discardRectangleCount;
    const( VkRect2D )*                             pDiscardRectangles;
}


// - VK_EXT_conservative_rasterization -
enum VK_EXT_conservative_rasterization = 1;

enum VK_EXT_CONSERVATIVE_RASTERIZATION_SPEC_VERSION = 1;
enum VK_EXT_CONSERVATIVE_RASTERIZATION_EXTENSION_NAME = "VK_EXT_conservative_rasterization";

enum VkConservativeRasterizationModeEXT {
    VK_CONSERVATIVE_RASTERIZATION_MODE_DISABLED_EXT              = 0,
    VK_CONSERVATIVE_RASTERIZATION_MODE_OVERESTIMATE_EXT          = 1,
    VK_CONSERVATIVE_RASTERIZATION_MODE_UNDERESTIMATE_EXT         = 2,
    VK_CONSERVATIVE_RASTERIZATION_MODE_BEGIN_RANGE_EXT           = VK_CONSERVATIVE_RASTERIZATION_MODE_DISABLED_EXT,
    VK_CONSERVATIVE_RASTERIZATION_MODE_END_RANGE_EXT             = VK_CONSERVATIVE_RASTERIZATION_MODE_UNDERESTIMATE_EXT,
    VK_CONSERVATIVE_RASTERIZATION_MODE_RANGE_SIZE_EXT            = VK_CONSERVATIVE_RASTERIZATION_MODE_UNDERESTIMATE_EXT - VK_CONSERVATIVE_RASTERIZATION_MODE_DISABLED_EXT + 1,
    VK_CONSERVATIVE_RASTERIZATION_MODE_MAX_ENUM_EXT              = 0x7FFFFFFF
}

enum VK_CONSERVATIVE_RASTERIZATION_MODE_DISABLED_EXT             = VkConservativeRasterizationModeEXT.VK_CONSERVATIVE_RASTERIZATION_MODE_DISABLED_EXT;
enum VK_CONSERVATIVE_RASTERIZATION_MODE_OVERESTIMATE_EXT         = VkConservativeRasterizationModeEXT.VK_CONSERVATIVE_RASTERIZATION_MODE_OVERESTIMATE_EXT;
enum VK_CONSERVATIVE_RASTERIZATION_MODE_UNDERESTIMATE_EXT        = VkConservativeRasterizationModeEXT.VK_CONSERVATIVE_RASTERIZATION_MODE_UNDERESTIMATE_EXT;
enum VK_CONSERVATIVE_RASTERIZATION_MODE_BEGIN_RANGE_EXT          = VkConservativeRasterizationModeEXT.VK_CONSERVATIVE_RASTERIZATION_MODE_BEGIN_RANGE_EXT;
enum VK_CONSERVATIVE_RASTERIZATION_MODE_END_RANGE_EXT            = VkConservativeRasterizationModeEXT.VK_CONSERVATIVE_RASTERIZATION_MODE_END_RANGE_EXT;
enum VK_CONSERVATIVE_RASTERIZATION_MODE_RANGE_SIZE_EXT           = VkConservativeRasterizationModeEXT.VK_CONSERVATIVE_RASTERIZATION_MODE_RANGE_SIZE_EXT;
enum VK_CONSERVATIVE_RASTERIZATION_MODE_MAX_ENUM_EXT             = VkConservativeRasterizationModeEXT.VK_CONSERVATIVE_RASTERIZATION_MODE_MAX_ENUM_EXT;

alias VkPipelineRasterizationConservativeStateCreateFlagsEXT = VkFlags;

struct VkPhysicalDeviceConservativeRasterizationPropertiesEXT {
    VkStructureType  sType = VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_CONSERVATIVE_RASTERIZATION_PROPERTIES_EXT;
    void*            pNext;
    float            primitiveOverestimationSize;
    float            maxExtraPrimitiveOverestimationSize;
    float            extraPrimitiveOverestimationSizeGranularity;
    VkBool32         primitiveUnderestimation;
    VkBool32         conservativePointAndLineRasterization;
    VkBool32         degenerateTrianglesRasterized;
    VkBool32         degenerateLinesRasterized;
    VkBool32         fullyCoveredFragmentShaderInputVariable;
    VkBool32         conservativeRasterizationPostDepthCoverage;
}

struct VkPipelineRasterizationConservativeStateCreateInfoEXT {
    VkStructureType                                         sType = VK_STRUCTURE_TYPE_PIPELINE_RASTERIZATION_CONSERVATIVE_STATE_CREATE_INFO_EXT;
    const( void )*                                          pNext;
    VkPipelineRasterizationConservativeStateCreateFlagsEXT  flags;
    VkConservativeRasterizationModeEXT                      conservativeRasterizationMode;
    float                                                   extraPrimitiveOverestimationSize;
}


// - VK_EXT_depth_clip_enable -
enum VK_EXT_depth_clip_enable = 1;

enum VK_EXT_DEPTH_CLIP_ENABLE_SPEC_VERSION = 1;
enum VK_EXT_DEPTH_CLIP_ENABLE_EXTENSION_NAME = "VK_EXT_depth_clip_enable";

alias VkPipelineRasterizationDepthClipStateCreateFlagsEXT = VkFlags;

struct VkPhysicalDeviceDepthClipEnableFeaturesEXT {
    VkStructureType  sType = VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_DEPTH_CLIP_ENABLE_FEATURES_EXT;
    void*            pNext;
    VkBool32         depthClipEnable;
}

struct VkPipelineRasterizationDepthClipStateCreateInfoEXT {
    VkStructureType                                      sType = VK_STRUCTURE_TYPE_PIPELINE_RASTERIZATION_DEPTH_CLIP_STATE_CREATE_INFO_EXT;
    const( void )*                                       pNext;
    VkPipelineRasterizationDepthClipStateCreateFlagsEXT  flags;
    VkBool32                                             depthClipEnable;
}


// - VK_EXT_swapchain_colorspace -
enum VK_EXT_swapchain_colorspace = 1;

enum VK_EXT_SWAPCHAIN_COLOR_SPACE_SPEC_VERSION = 4;
enum VK_EXT_SWAPCHAIN_COLOR_SPACE_EXTENSION_NAME = "VK_EXT_swapchain_colorspace";


// - VK_EXT_hdr_metadata -
enum VK_EXT_hdr_metadata = 1;

enum VK_EXT_HDR_METADATA_SPEC_VERSION = 1;
enum VK_EXT_HDR_METADATA_EXTENSION_NAME = "VK_EXT_hdr_metadata";

struct VkXYColorEXT {
    float  x;
    float  y;
}

struct VkHdrMetadataEXT {
    VkStructureType  sType = VK_STRUCTURE_TYPE_HDR_METADATA_EXT;
    const( void )*   pNext;
    VkXYColorEXT     displayPrimaryRed;
    VkXYColorEXT     displayPrimaryGreen;
    VkXYColorEXT     displayPrimaryBlue;
    VkXYColorEXT     whitePoint;
    float            maxLuminance;
    float            minLuminance;
    float            maxContentLightLevel;
    float            maxFrameAverageLightLevel;
}


// - VK_EXT_external_memory_dma_buf -
enum VK_EXT_external_memory_dma_buf = 1;

enum VK_EXT_EXTERNAL_MEMORY_DMA_BUF_SPEC_VERSION = 1;
enum VK_EXT_EXTERNAL_MEMORY_DMA_BUF_EXTENSION_NAME = "VK_EXT_external_memory_dma_buf";


// - VK_EXT_queue_family_foreign -
enum VK_EXT_queue_family_foreign = 1;

enum VK_EXT_QUEUE_FAMILY_FOREIGN_SPEC_VERSION = 1;
enum VK_EXT_QUEUE_FAMILY_FOREIGN_EXTENSION_NAME = "VK_EXT_queue_family_foreign";
enum VK_QUEUE_FAMILY_FOREIGN_EXT = (~0U-2);


// - VK_EXT_debug_utils -
enum VK_EXT_debug_utils = 1;

mixin( VK_DEFINE_NON_DISPATCHABLE_HANDLE!q{VkDebugUtilsMessengerEXT} );

enum VK_EXT_DEBUG_UTILS_SPEC_VERSION = 1;
enum VK_EXT_DEBUG_UTILS_EXTENSION_NAME = "VK_EXT_debug_utils";

alias VkDebugUtilsMessengerCallbackDataFlagsEXT = VkFlags;
alias VkDebugUtilsMessengerCreateFlagsEXT = VkFlags;

enum VkDebugUtilsMessageSeverityFlagBitsEXT {
    VK_DEBUG_UTILS_MESSAGE_SEVERITY_VERBOSE_BIT_EXT              = 0x00000001,
    VK_DEBUG_UTILS_MESSAGE_SEVERITY_INFO_BIT_EXT                 = 0x00000010,
    VK_DEBUG_UTILS_MESSAGE_SEVERITY_WARNING_BIT_EXT              = 0x00000100,
    VK_DEBUG_UTILS_MESSAGE_SEVERITY_ERROR_BIT_EXT                = 0x00001000,
    VK_DEBUG_UTILS_MESSAGE_SEVERITY_FLAG_BITS_MAX_ENUM_EXT       = 0x7FFFFFFF
}

enum VK_DEBUG_UTILS_MESSAGE_SEVERITY_VERBOSE_BIT_EXT             = VkDebugUtilsMessageSeverityFlagBitsEXT.VK_DEBUG_UTILS_MESSAGE_SEVERITY_VERBOSE_BIT_EXT;
enum VK_DEBUG_UTILS_MESSAGE_SEVERITY_INFO_BIT_EXT                = VkDebugUtilsMessageSeverityFlagBitsEXT.VK_DEBUG_UTILS_MESSAGE_SEVERITY_INFO_BIT_EXT;
enum VK_DEBUG_UTILS_MESSAGE_SEVERITY_WARNING_BIT_EXT             = VkDebugUtilsMessageSeverityFlagBitsEXT.VK_DEBUG_UTILS_MESSAGE_SEVERITY_WARNING_BIT_EXT;
enum VK_DEBUG_UTILS_MESSAGE_SEVERITY_ERROR_BIT_EXT               = VkDebugUtilsMessageSeverityFlagBitsEXT.VK_DEBUG_UTILS_MESSAGE_SEVERITY_ERROR_BIT_EXT;
enum VK_DEBUG_UTILS_MESSAGE_SEVERITY_FLAG_BITS_MAX_ENUM_EXT      = VkDebugUtilsMessageSeverityFlagBitsEXT.VK_DEBUG_UTILS_MESSAGE_SEVERITY_FLAG_BITS_MAX_ENUM_EXT;
alias VkDebugUtilsMessageSeverityFlagsEXT = VkFlags;

enum VkDebugUtilsMessageTypeFlagBitsEXT {
    VK_DEBUG_UTILS_MESSAGE_TYPE_GENERAL_BIT_EXT          = 0x00000001,
    VK_DEBUG_UTILS_MESSAGE_TYPE_VALIDATION_BIT_EXT       = 0x00000002,
    VK_DEBUG_UTILS_MESSAGE_TYPE_PERFORMANCE_BIT_EXT      = 0x00000004,
    VK_DEBUG_UTILS_MESSAGE_TYPE_FLAG_BITS_MAX_ENUM_EXT   = 0x7FFFFFFF
}

enum VK_DEBUG_UTILS_MESSAGE_TYPE_GENERAL_BIT_EXT         = VkDebugUtilsMessageTypeFlagBitsEXT.VK_DEBUG_UTILS_MESSAGE_TYPE_GENERAL_BIT_EXT;
enum VK_DEBUG_UTILS_MESSAGE_TYPE_VALIDATION_BIT_EXT      = VkDebugUtilsMessageTypeFlagBitsEXT.VK_DEBUG_UTILS_MESSAGE_TYPE_VALIDATION_BIT_EXT;
enum VK_DEBUG_UTILS_MESSAGE_TYPE_PERFORMANCE_BIT_EXT     = VkDebugUtilsMessageTypeFlagBitsEXT.VK_DEBUG_UTILS_MESSAGE_TYPE_PERFORMANCE_BIT_EXT;
enum VK_DEBUG_UTILS_MESSAGE_TYPE_FLAG_BITS_MAX_ENUM_EXT  = VkDebugUtilsMessageTypeFlagBitsEXT.VK_DEBUG_UTILS_MESSAGE_TYPE_FLAG_BITS_MAX_ENUM_EXT;
alias VkDebugUtilsMessageTypeFlagsEXT = VkFlags;

alias PFN_vkDebugUtilsMessengerCallbackEXT = VkBool32 function(
    VkDebugUtilsMessageSeverityFlagBitsEXT           messageSeverity,
    VkDebugUtilsMessageTypeFlagsEXT                  messageTypes,
    const( VkDebugUtilsMessengerCallbackDataEXT )*   pCallbackData,
    void*                                            pUserData
);

struct VkDebugUtilsObjectNameInfoEXT {
    VkStructureType  sType = VK_STRUCTURE_TYPE_DEBUG_UTILS_OBJECT_NAME_INFO_EXT;
    const( void )*   pNext;
    VkObjectType     objectType;
    uint64_t         objectHandle;
    const( char )*   pObjectName;
}

struct VkDebugUtilsObjectTagInfoEXT {
    VkStructureType  sType = VK_STRUCTURE_TYPE_DEBUG_UTILS_OBJECT_TAG_INFO_EXT;
    const( void )*   pNext;
    VkObjectType     objectType;
    uint64_t         objectHandle;
    uint64_t         tagName;
    size_t           tagSize;
    const( void )*   pTag;
}

struct VkDebugUtilsLabelEXT {
    VkStructureType  sType = VK_STRUCTURE_TYPE_DEBUG_UTILS_LABEL_EXT;
    const( void )*   pNext;
    const( char )*   pLabelName;
    float[4]         color;
}

struct VkDebugUtilsMessengerCallbackDataEXT {
    VkStructureType                            sType = VK_STRUCTURE_TYPE_DEBUG_UTILS_MESSENGER_CALLBACK_DATA_EXT;
    const( void )*                             pNext;
    VkDebugUtilsMessengerCallbackDataFlagsEXT  flags;
    const( char )*                             pMessageIdName;
    int32_t                                    messageIdNumber;
    const( char )*                             pMessage;
    uint32_t                                   queueLabelCount;
    const( VkDebugUtilsLabelEXT )*             pQueueLabels;
    uint32_t                                   cmdBufLabelCount;
    const( VkDebugUtilsLabelEXT )*             pCmdBufLabels;
    uint32_t                                   objectCount;
    const( VkDebugUtilsObjectNameInfoEXT )*    pObjects;
}

struct VkDebugUtilsMessengerCreateInfoEXT {
    VkStructureType                       sType = VK_STRUCTURE_TYPE_DEBUG_UTILS_MESSENGER_CREATE_INFO_EXT;
    const( void )*                        pNext;
    VkDebugUtilsMessengerCreateFlagsEXT   flags;
    VkDebugUtilsMessageSeverityFlagsEXT   messageSeverity;
    VkDebugUtilsMessageTypeFlagsEXT       messageType;
    PFN_vkDebugUtilsMessengerCallbackEXT  pfnUserCallback;
    void*                                 pUserData;
}


// - VK_EXT_sampler_filter_minmax -
enum VK_EXT_sampler_filter_minmax = 1;

enum VK_EXT_SAMPLER_FILTER_MINMAX_SPEC_VERSION = 1;
enum VK_EXT_SAMPLER_FILTER_MINMAX_EXTENSION_NAME = "VK_EXT_sampler_filter_minmax";

enum VkSamplerReductionModeEXT {
    VK_SAMPLER_REDUCTION_MODE_WEIGHTED_AVERAGE_EXT       = 0,
    VK_SAMPLER_REDUCTION_MODE_MIN_EXT                    = 1,
    VK_SAMPLER_REDUCTION_MODE_MAX_EXT                    = 2,
    VK_SAMPLER_REDUCTION_MODE_BEGIN_RANGE_EXT            = VK_SAMPLER_REDUCTION_MODE_WEIGHTED_AVERAGE_EXT,
    VK_SAMPLER_REDUCTION_MODE_END_RANGE_EXT              = VK_SAMPLER_REDUCTION_MODE_MAX_EXT,
    VK_SAMPLER_REDUCTION_MODE_RANGE_SIZE_EXT             = VK_SAMPLER_REDUCTION_MODE_MAX_EXT - VK_SAMPLER_REDUCTION_MODE_WEIGHTED_AVERAGE_EXT + 1,
    VK_SAMPLER_REDUCTION_MODE_MAX_ENUM_EXT               = 0x7FFFFFFF
}

enum VK_SAMPLER_REDUCTION_MODE_WEIGHTED_AVERAGE_EXT      = VkSamplerReductionModeEXT.VK_SAMPLER_REDUCTION_MODE_WEIGHTED_AVERAGE_EXT;
enum VK_SAMPLER_REDUCTION_MODE_MIN_EXT                   = VkSamplerReductionModeEXT.VK_SAMPLER_REDUCTION_MODE_MIN_EXT;
enum VK_SAMPLER_REDUCTION_MODE_MAX_EXT                   = VkSamplerReductionModeEXT.VK_SAMPLER_REDUCTION_MODE_MAX_EXT;
enum VK_SAMPLER_REDUCTION_MODE_BEGIN_RANGE_EXT           = VkSamplerReductionModeEXT.VK_SAMPLER_REDUCTION_MODE_BEGIN_RANGE_EXT;
enum VK_SAMPLER_REDUCTION_MODE_END_RANGE_EXT             = VkSamplerReductionModeEXT.VK_SAMPLER_REDUCTION_MODE_END_RANGE_EXT;
enum VK_SAMPLER_REDUCTION_MODE_RANGE_SIZE_EXT            = VkSamplerReductionModeEXT.VK_SAMPLER_REDUCTION_MODE_RANGE_SIZE_EXT;
enum VK_SAMPLER_REDUCTION_MODE_MAX_ENUM_EXT              = VkSamplerReductionModeEXT.VK_SAMPLER_REDUCTION_MODE_MAX_ENUM_EXT;

struct VkSamplerReductionModeCreateInfoEXT {
    VkStructureType            sType = VK_STRUCTURE_TYPE_SAMPLER_REDUCTION_MODE_CREATE_INFO_EXT;
    const( void )*             pNext;
    VkSamplerReductionModeEXT  reductionMode;
}

struct VkPhysicalDeviceSamplerFilterMinmaxPropertiesEXT {
    VkStructureType  sType = VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_SAMPLER_FILTER_MINMAX_PROPERTIES_EXT;
    void*            pNext;
    VkBool32         filterMinmaxSingleComponentFormats;
    VkBool32         filterMinmaxImageComponentMapping;
}


// - VK_AMD_gpu_shader_int16 -
enum VK_AMD_gpu_shader_int16 = 1;

enum VK_AMD_GPU_SHADER_INT16_SPEC_VERSION = 2;
enum VK_AMD_GPU_SHADER_INT16_EXTENSION_NAME = "VK_AMD_gpu_shader_int16";


// - VK_AMD_mixed_attachment_samples -
enum VK_AMD_mixed_attachment_samples = 1;

enum VK_AMD_MIXED_ATTACHMENT_SAMPLES_SPEC_VERSION = 1;
enum VK_AMD_MIXED_ATTACHMENT_SAMPLES_EXTENSION_NAME = "VK_AMD_mixed_attachment_samples";


// - VK_AMD_shader_fragment_mask -
enum VK_AMD_shader_fragment_mask = 1;

enum VK_AMD_SHADER_FRAGMENT_MASK_SPEC_VERSION = 1;
enum VK_AMD_SHADER_FRAGMENT_MASK_EXTENSION_NAME = "VK_AMD_shader_fragment_mask";


// - VK_EXT_inline_uniform_block -
enum VK_EXT_inline_uniform_block = 1;

enum VK_EXT_INLINE_UNIFORM_BLOCK_SPEC_VERSION = 1;
enum VK_EXT_INLINE_UNIFORM_BLOCK_EXTENSION_NAME = "VK_EXT_inline_uniform_block";

struct VkPhysicalDeviceInlineUniformBlockFeaturesEXT {
    VkStructureType  sType = VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_INLINE_UNIFORM_BLOCK_FEATURES_EXT;
    void*            pNext;
    VkBool32         inlineUniformBlock;
    VkBool32         descriptorBindingInlineUniformBlockUpdateAfterBind;
}

struct VkPhysicalDeviceInlineUniformBlockPropertiesEXT {
    VkStructureType  sType = VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_INLINE_UNIFORM_BLOCK_PROPERTIES_EXT;
    void*            pNext;
    uint32_t         maxInlineUniformBlockSize;
    uint32_t         maxPerStageDescriptorInlineUniformBlocks;
    uint32_t         maxPerStageDescriptorUpdateAfterBindInlineUniformBlocks;
    uint32_t         maxDescriptorSetInlineUniformBlocks;
    uint32_t         maxDescriptorSetUpdateAfterBindInlineUniformBlocks;
}

struct VkWriteDescriptorSetInlineUniformBlockEXT {
    VkStructureType  sType = VK_STRUCTURE_TYPE_WRITE_DESCRIPTOR_SET_INLINE_UNIFORM_BLOCK_EXT;
    const( void )*   pNext;
    uint32_t         dataSize;
    const( void )*   pData;
}

struct VkDescriptorPoolInlineUniformBlockCreateInfoEXT {
    VkStructureType  sType = VK_STRUCTURE_TYPE_DESCRIPTOR_POOL_INLINE_UNIFORM_BLOCK_CREATE_INFO_EXT;
    const( void )*   pNext;
    uint32_t         maxInlineUniformBlockBindings;
}


// - VK_EXT_shader_stencil_export -
enum VK_EXT_shader_stencil_export = 1;

enum VK_EXT_SHADER_STENCIL_EXPORT_SPEC_VERSION = 1;
enum VK_EXT_SHADER_STENCIL_EXPORT_EXTENSION_NAME = "VK_EXT_shader_stencil_export";


// - VK_EXT_sample_locations -
enum VK_EXT_sample_locations = 1;

enum VK_EXT_SAMPLE_LOCATIONS_SPEC_VERSION = 1;
enum VK_EXT_SAMPLE_LOCATIONS_EXTENSION_NAME = "VK_EXT_sample_locations";

struct VkSampleLocationEXT {
    float  x;
    float  y;
}

struct VkSampleLocationsInfoEXT {
    VkStructureType                sType = VK_STRUCTURE_TYPE_SAMPLE_LOCATIONS_INFO_EXT;
    const( void )*                 pNext;
    VkSampleCountFlagBits          sampleLocationsPerPixel;
    VkExtent2D                     sampleLocationGridSize;
    uint32_t                       sampleLocationsCount;
    const( VkSampleLocationEXT )*  pSampleLocations;
}

struct VkAttachmentSampleLocationsEXT {
    uint32_t                  attachmentIndex;
    VkSampleLocationsInfoEXT  sampleLocationsInfo;
}

struct VkSubpassSampleLocationsEXT {
    uint32_t                  subpassIndex;
    VkSampleLocationsInfoEXT  sampleLocationsInfo;
}

struct VkRenderPassSampleLocationsBeginInfoEXT {
    VkStructureType                           sType = VK_STRUCTURE_TYPE_RENDER_PASS_SAMPLE_LOCATIONS_BEGIN_INFO_EXT;
    const( void )*                            pNext;
    uint32_t                                  attachmentInitialSampleLocationsCount;
    const( VkAttachmentSampleLocationsEXT )*  pAttachmentInitialSampleLocations;
    uint32_t                                  postSubpassSampleLocationsCount;
    const( VkSubpassSampleLocationsEXT )*     pPostSubpassSampleLocations;
}

struct VkPipelineSampleLocationsStateCreateInfoEXT {
    VkStructureType           sType = VK_STRUCTURE_TYPE_PIPELINE_SAMPLE_LOCATIONS_STATE_CREATE_INFO_EXT;
    const( void )*            pNext;
    VkBool32                  sampleLocationsEnable;
    VkSampleLocationsInfoEXT  sampleLocationsInfo;
}

struct VkPhysicalDeviceSampleLocationsPropertiesEXT {
    VkStructureType     sType = VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_SAMPLE_LOCATIONS_PROPERTIES_EXT;
    void*               pNext;
    VkSampleCountFlags  sampleLocationSampleCounts;
    VkExtent2D          maxSampleLocationGridSize;
    float[2]            sampleLocationCoordinateRange;
    uint32_t            sampleLocationSubPixelBits;
    VkBool32            variableSampleLocations;
}

struct VkMultisamplePropertiesEXT {
    VkStructureType  sType = VK_STRUCTURE_TYPE_MULTISAMPLE_PROPERTIES_EXT;
    void*            pNext;
    VkExtent2D       maxSampleLocationGridSize;
}


// - VK_EXT_blend_operation_advanced -
enum VK_EXT_blend_operation_advanced = 1;

enum VK_EXT_BLEND_OPERATION_ADVANCED_SPEC_VERSION = 2;
enum VK_EXT_BLEND_OPERATION_ADVANCED_EXTENSION_NAME = "VK_EXT_blend_operation_advanced";

enum VkBlendOverlapEXT {
    VK_BLEND_OVERLAP_UNCORRELATED_EXT    = 0,
    VK_BLEND_OVERLAP_DISJOINT_EXT        = 1,
    VK_BLEND_OVERLAP_CONJOINT_EXT        = 2,
    VK_BLEND_OVERLAP_BEGIN_RANGE_EXT     = VK_BLEND_OVERLAP_UNCORRELATED_EXT,
    VK_BLEND_OVERLAP_END_RANGE_EXT       = VK_BLEND_OVERLAP_CONJOINT_EXT,
    VK_BLEND_OVERLAP_RANGE_SIZE_EXT      = VK_BLEND_OVERLAP_CONJOINT_EXT - VK_BLEND_OVERLAP_UNCORRELATED_EXT + 1,
    VK_BLEND_OVERLAP_MAX_ENUM_EXT        = 0x7FFFFFFF
}

enum VK_BLEND_OVERLAP_UNCORRELATED_EXT   = VkBlendOverlapEXT.VK_BLEND_OVERLAP_UNCORRELATED_EXT;
enum VK_BLEND_OVERLAP_DISJOINT_EXT       = VkBlendOverlapEXT.VK_BLEND_OVERLAP_DISJOINT_EXT;
enum VK_BLEND_OVERLAP_CONJOINT_EXT       = VkBlendOverlapEXT.VK_BLEND_OVERLAP_CONJOINT_EXT;
enum VK_BLEND_OVERLAP_BEGIN_RANGE_EXT    = VkBlendOverlapEXT.VK_BLEND_OVERLAP_BEGIN_RANGE_EXT;
enum VK_BLEND_OVERLAP_END_RANGE_EXT      = VkBlendOverlapEXT.VK_BLEND_OVERLAP_END_RANGE_EXT;
enum VK_BLEND_OVERLAP_RANGE_SIZE_EXT     = VkBlendOverlapEXT.VK_BLEND_OVERLAP_RANGE_SIZE_EXT;
enum VK_BLEND_OVERLAP_MAX_ENUM_EXT       = VkBlendOverlapEXT.VK_BLEND_OVERLAP_MAX_ENUM_EXT;

struct VkPhysicalDeviceBlendOperationAdvancedFeaturesEXT {
    VkStructureType  sType = VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_BLEND_OPERATION_ADVANCED_FEATURES_EXT;
    void*            pNext;
    VkBool32         advancedBlendCoherentOperations;
}

struct VkPhysicalDeviceBlendOperationAdvancedPropertiesEXT {
    VkStructureType  sType = VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_BLEND_OPERATION_ADVANCED_PROPERTIES_EXT;
    void*            pNext;
    uint32_t         advancedBlendMaxColorAttachments;
    VkBool32         advancedBlendIndependentBlend;
    VkBool32         advancedBlendNonPremultipliedSrcColor;
    VkBool32         advancedBlendNonPremultipliedDstColor;
    VkBool32         advancedBlendCorrelatedOverlap;
    VkBool32         advancedBlendAllOperations;
}

struct VkPipelineColorBlendAdvancedStateCreateInfoEXT {
    VkStructureType    sType = VK_STRUCTURE_TYPE_PIPELINE_COLOR_BLEND_ADVANCED_STATE_CREATE_INFO_EXT;
    const( void )*     pNext;
    VkBool32           srcPremultiplied;
    VkBool32           dstPremultiplied;
    VkBlendOverlapEXT  blendOverlap;
}


// - VK_NV_fragment_coverage_to_color -
enum VK_NV_fragment_coverage_to_color = 1;

enum VK_NV_FRAGMENT_COVERAGE_TO_COLOR_SPEC_VERSION = 1;
enum VK_NV_FRAGMENT_COVERAGE_TO_COLOR_EXTENSION_NAME = "VK_NV_fragment_coverage_to_color";

alias VkPipelineCoverageToColorStateCreateFlagsNV = VkFlags;

struct VkPipelineCoverageToColorStateCreateInfoNV {
    VkStructureType                              sType = VK_STRUCTURE_TYPE_PIPELINE_COVERAGE_TO_COLOR_STATE_CREATE_INFO_NV;
    const( void )*                               pNext;
    VkPipelineCoverageToColorStateCreateFlagsNV  flags;
    VkBool32                                     coverageToColorEnable;
    uint32_t                                     coverageToColorLocation;
}


// - VK_NV_framebuffer_mixed_samples -
enum VK_NV_framebuffer_mixed_samples = 1;

enum VK_NV_FRAMEBUFFER_MIXED_SAMPLES_SPEC_VERSION = 1;
enum VK_NV_FRAMEBUFFER_MIXED_SAMPLES_EXTENSION_NAME = "VK_NV_framebuffer_mixed_samples";

enum VkCoverageModulationModeNV {
    VK_COVERAGE_MODULATION_MODE_NONE_NV          = 0,
    VK_COVERAGE_MODULATION_MODE_RGB_NV           = 1,
    VK_COVERAGE_MODULATION_MODE_ALPHA_NV         = 2,
    VK_COVERAGE_MODULATION_MODE_RGBA_NV          = 3,
    VK_COVERAGE_MODULATION_MODE_BEGIN_RANGE_NV   = VK_COVERAGE_MODULATION_MODE_NONE_NV,
    VK_COVERAGE_MODULATION_MODE_END_RANGE_NV     = VK_COVERAGE_MODULATION_MODE_RGBA_NV,
    VK_COVERAGE_MODULATION_MODE_RANGE_SIZE_NV    = VK_COVERAGE_MODULATION_MODE_RGBA_NV - VK_COVERAGE_MODULATION_MODE_NONE_NV + 1,
    VK_COVERAGE_MODULATION_MODE_MAX_ENUM_NV      = 0x7FFFFFFF
}

enum VK_COVERAGE_MODULATION_MODE_NONE_NV         = VkCoverageModulationModeNV.VK_COVERAGE_MODULATION_MODE_NONE_NV;
enum VK_COVERAGE_MODULATION_MODE_RGB_NV          = VkCoverageModulationModeNV.VK_COVERAGE_MODULATION_MODE_RGB_NV;
enum VK_COVERAGE_MODULATION_MODE_ALPHA_NV        = VkCoverageModulationModeNV.VK_COVERAGE_MODULATION_MODE_ALPHA_NV;
enum VK_COVERAGE_MODULATION_MODE_RGBA_NV         = VkCoverageModulationModeNV.VK_COVERAGE_MODULATION_MODE_RGBA_NV;
enum VK_COVERAGE_MODULATION_MODE_BEGIN_RANGE_NV  = VkCoverageModulationModeNV.VK_COVERAGE_MODULATION_MODE_BEGIN_RANGE_NV;
enum VK_COVERAGE_MODULATION_MODE_END_RANGE_NV    = VkCoverageModulationModeNV.VK_COVERAGE_MODULATION_MODE_END_RANGE_NV;
enum VK_COVERAGE_MODULATION_MODE_RANGE_SIZE_NV   = VkCoverageModulationModeNV.VK_COVERAGE_MODULATION_MODE_RANGE_SIZE_NV;
enum VK_COVERAGE_MODULATION_MODE_MAX_ENUM_NV     = VkCoverageModulationModeNV.VK_COVERAGE_MODULATION_MODE_MAX_ENUM_NV;

alias VkPipelineCoverageModulationStateCreateFlagsNV = VkFlags;

struct VkPipelineCoverageModulationStateCreateInfoNV {
    VkStructureType                                 sType = VK_STRUCTURE_TYPE_PIPELINE_COVERAGE_MODULATION_STATE_CREATE_INFO_NV;
    const( void )*                                  pNext;
    VkPipelineCoverageModulationStateCreateFlagsNV  flags;
    VkCoverageModulationModeNV                      coverageModulationMode;
    VkBool32                                        coverageModulationTableEnable;
    uint32_t                                        coverageModulationTableCount;
    const( float )*                                 pCoverageModulationTable;
}


// - VK_NV_fill_rectangle -
enum VK_NV_fill_rectangle = 1;

enum VK_NV_FILL_RECTANGLE_SPEC_VERSION = 1;
enum VK_NV_FILL_RECTANGLE_EXTENSION_NAME = "VK_NV_fill_rectangle";


// - VK_NV_shader_sm_builtins -
enum VK_NV_shader_sm_builtins = 1;

enum VK_NV_SHADER_SM_BUILTINS_SPEC_VERSION = 1;
enum VK_NV_SHADER_SM_BUILTINS_EXTENSION_NAME = "VK_NV_shader_sm_builtins";

struct VkPhysicalDeviceShaderSMBuiltinsPropertiesNV {
    VkStructureType  sType = VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_SHADER_SM_BUILTINS_PROPERTIES_NV;
    void*            pNext;
    uint32_t         shaderSMCount;
    uint32_t         shaderWarpsPerSM;
}

struct VkPhysicalDeviceShaderSMBuiltinsFeaturesNV {
    VkStructureType  sType = VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_SHADER_SM_BUILTINS_FEATURES_NV;
    void*            pNext;
    VkBool32         shaderSMBuiltins;
}


// - VK_EXT_post_depth_coverage -
enum VK_EXT_post_depth_coverage = 1;

enum VK_EXT_POST_DEPTH_COVERAGE_SPEC_VERSION = 1;
enum VK_EXT_POST_DEPTH_COVERAGE_EXTENSION_NAME = "VK_EXT_post_depth_coverage";


// - VK_EXT_image_drm_format_modifier -
enum VK_EXT_image_drm_format_modifier = 1;

enum VK_EXT_IMAGE_DRM_FORMAT_MODIFIER_SPEC_VERSION = 1;
enum VK_EXT_IMAGE_DRM_FORMAT_MODIFIER_EXTENSION_NAME = "VK_EXT_image_drm_format_modifier";

struct VkDrmFormatModifierPropertiesEXT {
    uint64_t              drmFormatModifier;
    uint32_t              drmFormatModifierPlaneCount;
    VkFormatFeatureFlags  drmFormatModifierTilingFeatures;
}

struct VkDrmFormatModifierPropertiesListEXT {
    VkStructureType                    sType = VK_STRUCTURE_TYPE_DRM_FORMAT_MODIFIER_PROPERTIES_LIST_EXT;
    void*                              pNext;
    uint32_t                           drmFormatModifierCount;
    VkDrmFormatModifierPropertiesEXT*  pDrmFormatModifierProperties;
}

struct VkPhysicalDeviceImageDrmFormatModifierInfoEXT {
    VkStructureType     sType = VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_IMAGE_DRM_FORMAT_MODIFIER_INFO_EXT;
    const( void )*      pNext;
    uint64_t            drmFormatModifier;
    VkSharingMode       sharingMode;
    uint32_t            queueFamilyIndexCount;
    const( uint32_t )*  pQueueFamilyIndices;
}

struct VkImageDrmFormatModifierListCreateInfoEXT {
    VkStructureType     sType = VK_STRUCTURE_TYPE_IMAGE_DRM_FORMAT_MODIFIER_LIST_CREATE_INFO_EXT;
    const( void )*      pNext;
    uint32_t            drmFormatModifierCount;
    const( uint64_t )*  pDrmFormatModifiers;
}

struct VkImageDrmFormatModifierExplicitCreateInfoEXT {
    VkStructureType                sType = VK_STRUCTURE_TYPE_IMAGE_DRM_FORMAT_MODIFIER_EXPLICIT_CREATE_INFO_EXT;
    const( void )*                 pNext;
    uint64_t                       drmFormatModifier;
    uint32_t                       drmFormatModifierPlaneCount;
    const( VkSubresourceLayout )*  pPlaneLayouts;
}

struct VkImageDrmFormatModifierPropertiesEXT {
    VkStructureType  sType = VK_STRUCTURE_TYPE_IMAGE_DRM_FORMAT_MODIFIER_PROPERTIES_EXT;
    void*            pNext;
    uint64_t         drmFormatModifier;
}


// - VK_EXT_validation_cache -
enum VK_EXT_validation_cache = 1;

mixin( VK_DEFINE_NON_DISPATCHABLE_HANDLE!q{VkValidationCacheEXT} );

enum VK_EXT_VALIDATION_CACHE_SPEC_VERSION = 1;
enum VK_EXT_VALIDATION_CACHE_EXTENSION_NAME = "VK_EXT_validation_cache";

enum VkValidationCacheHeaderVersionEXT {
    VK_VALIDATION_CACHE_HEADER_VERSION_ONE_EXT           = 1,
    VK_VALIDATION_CACHE_HEADER_VERSION_BEGIN_RANGE_EXT   = VK_VALIDATION_CACHE_HEADER_VERSION_ONE_EXT,
    VK_VALIDATION_CACHE_HEADER_VERSION_END_RANGE_EXT     = VK_VALIDATION_CACHE_HEADER_VERSION_ONE_EXT,
    VK_VALIDATION_CACHE_HEADER_VERSION_RANGE_SIZE_EXT    = VK_VALIDATION_CACHE_HEADER_VERSION_ONE_EXT - VK_VALIDATION_CACHE_HEADER_VERSION_ONE_EXT + 1,
    VK_VALIDATION_CACHE_HEADER_VERSION_MAX_ENUM_EXT      = 0x7FFFFFFF
}

enum VK_VALIDATION_CACHE_HEADER_VERSION_ONE_EXT          = VkValidationCacheHeaderVersionEXT.VK_VALIDATION_CACHE_HEADER_VERSION_ONE_EXT;
enum VK_VALIDATION_CACHE_HEADER_VERSION_BEGIN_RANGE_EXT  = VkValidationCacheHeaderVersionEXT.VK_VALIDATION_CACHE_HEADER_VERSION_BEGIN_RANGE_EXT;
enum VK_VALIDATION_CACHE_HEADER_VERSION_END_RANGE_EXT    = VkValidationCacheHeaderVersionEXT.VK_VALIDATION_CACHE_HEADER_VERSION_END_RANGE_EXT;
enum VK_VALIDATION_CACHE_HEADER_VERSION_RANGE_SIZE_EXT   = VkValidationCacheHeaderVersionEXT.VK_VALIDATION_CACHE_HEADER_VERSION_RANGE_SIZE_EXT;
enum VK_VALIDATION_CACHE_HEADER_VERSION_MAX_ENUM_EXT     = VkValidationCacheHeaderVersionEXT.VK_VALIDATION_CACHE_HEADER_VERSION_MAX_ENUM_EXT;

alias VkValidationCacheCreateFlagsEXT = VkFlags;

struct VkValidationCacheCreateInfoEXT {
    VkStructureType                  sType = VK_STRUCTURE_TYPE_VALIDATION_CACHE_CREATE_INFO_EXT;
    const( void )*                   pNext;
    VkValidationCacheCreateFlagsEXT  flags;
    size_t                           initialDataSize;
    const( void )*                   pInitialData;
}

struct VkShaderModuleValidationCacheCreateInfoEXT {
    VkStructureType       sType = VK_STRUCTURE_TYPE_SHADER_MODULE_VALIDATION_CACHE_CREATE_INFO_EXT;
    const( void )*        pNext;
    VkValidationCacheEXT  validationCache;
}


// - VK_EXT_descriptor_indexing -
enum VK_EXT_descriptor_indexing = 1;

enum VK_EXT_DESCRIPTOR_INDEXING_SPEC_VERSION = 2;
enum VK_EXT_DESCRIPTOR_INDEXING_EXTENSION_NAME = "VK_EXT_descriptor_indexing";

enum VkDescriptorBindingFlagBitsEXT {
    VK_DESCRIPTOR_BINDING_UPDATE_AFTER_BIND_BIT_EXT              = 0x00000001,
    VK_DESCRIPTOR_BINDING_UPDATE_UNUSED_WHILE_PENDING_BIT_EXT    = 0x00000002,
    VK_DESCRIPTOR_BINDING_PARTIALLY_BOUND_BIT_EXT                = 0x00000004,
    VK_DESCRIPTOR_BINDING_VARIABLE_DESCRIPTOR_COUNT_BIT_EXT      = 0x00000008,
    VK_DESCRIPTOR_BINDING_FLAG_BITS_MAX_ENUM_EXT                 = 0x7FFFFFFF
}

enum VK_DESCRIPTOR_BINDING_UPDATE_AFTER_BIND_BIT_EXT             = VkDescriptorBindingFlagBitsEXT.VK_DESCRIPTOR_BINDING_UPDATE_AFTER_BIND_BIT_EXT;
enum VK_DESCRIPTOR_BINDING_UPDATE_UNUSED_WHILE_PENDING_BIT_EXT   = VkDescriptorBindingFlagBitsEXT.VK_DESCRIPTOR_BINDING_UPDATE_UNUSED_WHILE_PENDING_BIT_EXT;
enum VK_DESCRIPTOR_BINDING_PARTIALLY_BOUND_BIT_EXT               = VkDescriptorBindingFlagBitsEXT.VK_DESCRIPTOR_BINDING_PARTIALLY_BOUND_BIT_EXT;
enum VK_DESCRIPTOR_BINDING_VARIABLE_DESCRIPTOR_COUNT_BIT_EXT     = VkDescriptorBindingFlagBitsEXT.VK_DESCRIPTOR_BINDING_VARIABLE_DESCRIPTOR_COUNT_BIT_EXT;
enum VK_DESCRIPTOR_BINDING_FLAG_BITS_MAX_ENUM_EXT                = VkDescriptorBindingFlagBitsEXT.VK_DESCRIPTOR_BINDING_FLAG_BITS_MAX_ENUM_EXT;
alias VkDescriptorBindingFlagsEXT = VkFlags;

struct VkDescriptorSetLayoutBindingFlagsCreateInfoEXT {
    VkStructureType                        sType = VK_STRUCTURE_TYPE_DESCRIPTOR_SET_LAYOUT_BINDING_FLAGS_CREATE_INFO_EXT;
    const( void )*                         pNext;
    uint32_t                               bindingCount;
    const( VkDescriptorBindingFlagsEXT )*  pBindingFlags;
}

struct VkPhysicalDeviceDescriptorIndexingFeaturesEXT {
    VkStructureType  sType = VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_DESCRIPTOR_INDEXING_FEATURES_EXT;
    void*            pNext;
    VkBool32         shaderInputAttachmentArrayDynamicIndexing;
    VkBool32         shaderUniformTexelBufferArrayDynamicIndexing;
    VkBool32         shaderStorageTexelBufferArrayDynamicIndexing;
    VkBool32         shaderUniformBufferArrayNonUniformIndexing;
    VkBool32         shaderSampledImageArrayNonUniformIndexing;
    VkBool32         shaderStorageBufferArrayNonUniformIndexing;
    VkBool32         shaderStorageImageArrayNonUniformIndexing;
    VkBool32         shaderInputAttachmentArrayNonUniformIndexing;
    VkBool32         shaderUniformTexelBufferArrayNonUniformIndexing;
    VkBool32         shaderStorageTexelBufferArrayNonUniformIndexing;
    VkBool32         descriptorBindingUniformBufferUpdateAfterBind;
    VkBool32         descriptorBindingSampledImageUpdateAfterBind;
    VkBool32         descriptorBindingStorageImageUpdateAfterBind;
    VkBool32         descriptorBindingStorageBufferUpdateAfterBind;
    VkBool32         descriptorBindingUniformTexelBufferUpdateAfterBind;
    VkBool32         descriptorBindingStorageTexelBufferUpdateAfterBind;
    VkBool32         descriptorBindingUpdateUnusedWhilePending;
    VkBool32         descriptorBindingPartiallyBound;
    VkBool32         descriptorBindingVariableDescriptorCount;
    VkBool32         runtimeDescriptorArray;
}

struct VkPhysicalDeviceDescriptorIndexingPropertiesEXT {
    VkStructureType  sType = VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_DESCRIPTOR_INDEXING_PROPERTIES_EXT;
    void*            pNext;
    uint32_t         maxUpdateAfterBindDescriptorsInAllPools;
    VkBool32         shaderUniformBufferArrayNonUniformIndexingNative;
    VkBool32         shaderSampledImageArrayNonUniformIndexingNative;
    VkBool32         shaderStorageBufferArrayNonUniformIndexingNative;
    VkBool32         shaderStorageImageArrayNonUniformIndexingNative;
    VkBool32         shaderInputAttachmentArrayNonUniformIndexingNative;
    VkBool32         robustBufferAccessUpdateAfterBind;
    VkBool32         quadDivergentImplicitLod;
    uint32_t         maxPerStageDescriptorUpdateAfterBindSamplers;
    uint32_t         maxPerStageDescriptorUpdateAfterBindUniformBuffers;
    uint32_t         maxPerStageDescriptorUpdateAfterBindStorageBuffers;
    uint32_t         maxPerStageDescriptorUpdateAfterBindSampledImages;
    uint32_t         maxPerStageDescriptorUpdateAfterBindStorageImages;
    uint32_t         maxPerStageDescriptorUpdateAfterBindInputAttachments;
    uint32_t         maxPerStageUpdateAfterBindResources;
    uint32_t         maxDescriptorSetUpdateAfterBindSamplers;
    uint32_t         maxDescriptorSetUpdateAfterBindUniformBuffers;
    uint32_t         maxDescriptorSetUpdateAfterBindUniformBuffersDynamic;
    uint32_t         maxDescriptorSetUpdateAfterBindStorageBuffers;
    uint32_t         maxDescriptorSetUpdateAfterBindStorageBuffersDynamic;
    uint32_t         maxDescriptorSetUpdateAfterBindSampledImages;
    uint32_t         maxDescriptorSetUpdateAfterBindStorageImages;
    uint32_t         maxDescriptorSetUpdateAfterBindInputAttachments;
}

struct VkDescriptorSetVariableDescriptorCountAllocateInfoEXT {
    VkStructureType     sType = VK_STRUCTURE_TYPE_DESCRIPTOR_SET_VARIABLE_DESCRIPTOR_COUNT_ALLOCATE_INFO_EXT;
    const( void )*      pNext;
    uint32_t            descriptorSetCount;
    const( uint32_t )*  pDescriptorCounts;
}

struct VkDescriptorSetVariableDescriptorCountLayoutSupportEXT {
    VkStructureType  sType = VK_STRUCTURE_TYPE_DESCRIPTOR_SET_VARIABLE_DESCRIPTOR_COUNT_LAYOUT_SUPPORT_EXT;
    void*            pNext;
    uint32_t         maxVariableDescriptorCount;
}


// - VK_EXT_shader_viewport_index_layer -
enum VK_EXT_shader_viewport_index_layer = 1;

enum VK_EXT_SHADER_VIEWPORT_INDEX_LAYER_SPEC_VERSION = 1;
enum VK_EXT_SHADER_VIEWPORT_INDEX_LAYER_EXTENSION_NAME = "VK_EXT_shader_viewport_index_layer";


// - VK_NV_shading_rate_image -
enum VK_NV_shading_rate_image = 1;

enum VK_NV_SHADING_RATE_IMAGE_SPEC_VERSION = 3;
enum VK_NV_SHADING_RATE_IMAGE_EXTENSION_NAME = "VK_NV_shading_rate_image";

enum VkShadingRatePaletteEntryNV {
    VK_SHADING_RATE_PALETTE_ENTRY_NO_INVOCATIONS_NV                      = 0,
    VK_SHADING_RATE_PALETTE_ENTRY_16_INVOCATIONS_PER_PIXEL_NV            = 1,
    VK_SHADING_RATE_PALETTE_ENTRY_8_INVOCATIONS_PER_PIXEL_NV             = 2,
    VK_SHADING_RATE_PALETTE_ENTRY_4_INVOCATIONS_PER_PIXEL_NV             = 3,
    VK_SHADING_RATE_PALETTE_ENTRY_2_INVOCATIONS_PER_PIXEL_NV             = 4,
    VK_SHADING_RATE_PALETTE_ENTRY_1_INVOCATION_PER_PIXEL_NV              = 5,
    VK_SHADING_RATE_PALETTE_ENTRY_1_INVOCATION_PER_2X1_PIXELS_NV         = 6,
    VK_SHADING_RATE_PALETTE_ENTRY_1_INVOCATION_PER_1X2_PIXELS_NV         = 7,
    VK_SHADING_RATE_PALETTE_ENTRY_1_INVOCATION_PER_2X2_PIXELS_NV         = 8,
    VK_SHADING_RATE_PALETTE_ENTRY_1_INVOCATION_PER_4X2_PIXELS_NV         = 9,
    VK_SHADING_RATE_PALETTE_ENTRY_1_INVOCATION_PER_2X4_PIXELS_NV         = 10,
    VK_SHADING_RATE_PALETTE_ENTRY_1_INVOCATION_PER_4X4_PIXELS_NV         = 11,
    VK_SHADING_RATE_PALETTE_ENTRY_BEGIN_RANGE_NV                         = VK_SHADING_RATE_PALETTE_ENTRY_NO_INVOCATIONS_NV,
    VK_SHADING_RATE_PALETTE_ENTRY_END_RANGE_NV                           = VK_SHADING_RATE_PALETTE_ENTRY_1_INVOCATION_PER_4X4_PIXELS_NV,
    VK_SHADING_RATE_PALETTE_ENTRY_RANGE_SIZE_NV                          = VK_SHADING_RATE_PALETTE_ENTRY_1_INVOCATION_PER_4X4_PIXELS_NV - VK_SHADING_RATE_PALETTE_ENTRY_NO_INVOCATIONS_NV + 1,
    VK_SHADING_RATE_PALETTE_ENTRY_MAX_ENUM_NV                            = 0x7FFFFFFF
}

enum VK_SHADING_RATE_PALETTE_ENTRY_NO_INVOCATIONS_NV                     = VkShadingRatePaletteEntryNV.VK_SHADING_RATE_PALETTE_ENTRY_NO_INVOCATIONS_NV;
enum VK_SHADING_RATE_PALETTE_ENTRY_16_INVOCATIONS_PER_PIXEL_NV           = VkShadingRatePaletteEntryNV.VK_SHADING_RATE_PALETTE_ENTRY_16_INVOCATIONS_PER_PIXEL_NV;
enum VK_SHADING_RATE_PALETTE_ENTRY_8_INVOCATIONS_PER_PIXEL_NV            = VkShadingRatePaletteEntryNV.VK_SHADING_RATE_PALETTE_ENTRY_8_INVOCATIONS_PER_PIXEL_NV;
enum VK_SHADING_RATE_PALETTE_ENTRY_4_INVOCATIONS_PER_PIXEL_NV            = VkShadingRatePaletteEntryNV.VK_SHADING_RATE_PALETTE_ENTRY_4_INVOCATIONS_PER_PIXEL_NV;
enum VK_SHADING_RATE_PALETTE_ENTRY_2_INVOCATIONS_PER_PIXEL_NV            = VkShadingRatePaletteEntryNV.VK_SHADING_RATE_PALETTE_ENTRY_2_INVOCATIONS_PER_PIXEL_NV;
enum VK_SHADING_RATE_PALETTE_ENTRY_1_INVOCATION_PER_PIXEL_NV             = VkShadingRatePaletteEntryNV.VK_SHADING_RATE_PALETTE_ENTRY_1_INVOCATION_PER_PIXEL_NV;
enum VK_SHADING_RATE_PALETTE_ENTRY_1_INVOCATION_PER_2X1_PIXELS_NV        = VkShadingRatePaletteEntryNV.VK_SHADING_RATE_PALETTE_ENTRY_1_INVOCATION_PER_2X1_PIXELS_NV;
enum VK_SHADING_RATE_PALETTE_ENTRY_1_INVOCATION_PER_1X2_PIXELS_NV        = VkShadingRatePaletteEntryNV.VK_SHADING_RATE_PALETTE_ENTRY_1_INVOCATION_PER_1X2_PIXELS_NV;
enum VK_SHADING_RATE_PALETTE_ENTRY_1_INVOCATION_PER_2X2_PIXELS_NV        = VkShadingRatePaletteEntryNV.VK_SHADING_RATE_PALETTE_ENTRY_1_INVOCATION_PER_2X2_PIXELS_NV;
enum VK_SHADING_RATE_PALETTE_ENTRY_1_INVOCATION_PER_4X2_PIXELS_NV        = VkShadingRatePaletteEntryNV.VK_SHADING_RATE_PALETTE_ENTRY_1_INVOCATION_PER_4X2_PIXELS_NV;
enum VK_SHADING_RATE_PALETTE_ENTRY_1_INVOCATION_PER_2X4_PIXELS_NV        = VkShadingRatePaletteEntryNV.VK_SHADING_RATE_PALETTE_ENTRY_1_INVOCATION_PER_2X4_PIXELS_NV;
enum VK_SHADING_RATE_PALETTE_ENTRY_1_INVOCATION_PER_4X4_PIXELS_NV        = VkShadingRatePaletteEntryNV.VK_SHADING_RATE_PALETTE_ENTRY_1_INVOCATION_PER_4X4_PIXELS_NV;
enum VK_SHADING_RATE_PALETTE_ENTRY_BEGIN_RANGE_NV                        = VkShadingRatePaletteEntryNV.VK_SHADING_RATE_PALETTE_ENTRY_BEGIN_RANGE_NV;
enum VK_SHADING_RATE_PALETTE_ENTRY_END_RANGE_NV                          = VkShadingRatePaletteEntryNV.VK_SHADING_RATE_PALETTE_ENTRY_END_RANGE_NV;
enum VK_SHADING_RATE_PALETTE_ENTRY_RANGE_SIZE_NV                         = VkShadingRatePaletteEntryNV.VK_SHADING_RATE_PALETTE_ENTRY_RANGE_SIZE_NV;
enum VK_SHADING_RATE_PALETTE_ENTRY_MAX_ENUM_NV                           = VkShadingRatePaletteEntryNV.VK_SHADING_RATE_PALETTE_ENTRY_MAX_ENUM_NV;

enum VkCoarseSampleOrderTypeNV {
    VK_COARSE_SAMPLE_ORDER_TYPE_DEFAULT_NV       = 0,
    VK_COARSE_SAMPLE_ORDER_TYPE_CUSTOM_NV        = 1,
    VK_COARSE_SAMPLE_ORDER_TYPE_PIXEL_MAJOR_NV   = 2,
    VK_COARSE_SAMPLE_ORDER_TYPE_SAMPLE_MAJOR_NV  = 3,
    VK_COARSE_SAMPLE_ORDER_TYPE_BEGIN_RANGE_NV   = VK_COARSE_SAMPLE_ORDER_TYPE_DEFAULT_NV,
    VK_COARSE_SAMPLE_ORDER_TYPE_END_RANGE_NV     = VK_COARSE_SAMPLE_ORDER_TYPE_SAMPLE_MAJOR_NV,
    VK_COARSE_SAMPLE_ORDER_TYPE_RANGE_SIZE_NV    = VK_COARSE_SAMPLE_ORDER_TYPE_SAMPLE_MAJOR_NV - VK_COARSE_SAMPLE_ORDER_TYPE_DEFAULT_NV + 1,
    VK_COARSE_SAMPLE_ORDER_TYPE_MAX_ENUM_NV      = 0x7FFFFFFF
}

enum VK_COARSE_SAMPLE_ORDER_TYPE_DEFAULT_NV      = VkCoarseSampleOrderTypeNV.VK_COARSE_SAMPLE_ORDER_TYPE_DEFAULT_NV;
enum VK_COARSE_SAMPLE_ORDER_TYPE_CUSTOM_NV       = VkCoarseSampleOrderTypeNV.VK_COARSE_SAMPLE_ORDER_TYPE_CUSTOM_NV;
enum VK_COARSE_SAMPLE_ORDER_TYPE_PIXEL_MAJOR_NV  = VkCoarseSampleOrderTypeNV.VK_COARSE_SAMPLE_ORDER_TYPE_PIXEL_MAJOR_NV;
enum VK_COARSE_SAMPLE_ORDER_TYPE_SAMPLE_MAJOR_NV = VkCoarseSampleOrderTypeNV.VK_COARSE_SAMPLE_ORDER_TYPE_SAMPLE_MAJOR_NV;
enum VK_COARSE_SAMPLE_ORDER_TYPE_BEGIN_RANGE_NV  = VkCoarseSampleOrderTypeNV.VK_COARSE_SAMPLE_ORDER_TYPE_BEGIN_RANGE_NV;
enum VK_COARSE_SAMPLE_ORDER_TYPE_END_RANGE_NV    = VkCoarseSampleOrderTypeNV.VK_COARSE_SAMPLE_ORDER_TYPE_END_RANGE_NV;
enum VK_COARSE_SAMPLE_ORDER_TYPE_RANGE_SIZE_NV   = VkCoarseSampleOrderTypeNV.VK_COARSE_SAMPLE_ORDER_TYPE_RANGE_SIZE_NV;
enum VK_COARSE_SAMPLE_ORDER_TYPE_MAX_ENUM_NV     = VkCoarseSampleOrderTypeNV.VK_COARSE_SAMPLE_ORDER_TYPE_MAX_ENUM_NV;

struct VkShadingRatePaletteNV {
    uint32_t                               shadingRatePaletteEntryCount;
    const( VkShadingRatePaletteEntryNV )*  pShadingRatePaletteEntries;
}

struct VkPipelineViewportShadingRateImageStateCreateInfoNV {
    VkStructureType                   sType = VK_STRUCTURE_TYPE_PIPELINE_VIEWPORT_SHADING_RATE_IMAGE_STATE_CREATE_INFO_NV;
    const( void )*                    pNext;
    VkBool32                          shadingRateImageEnable;
    uint32_t                          viewportCount;
    const( VkShadingRatePaletteNV )*  pShadingRatePalettes;
}

struct VkPhysicalDeviceShadingRateImageFeaturesNV {
    VkStructureType  sType = VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_SHADING_RATE_IMAGE_FEATURES_NV;
    void*            pNext;
    VkBool32         shadingRateImage;
    VkBool32         shadingRateCoarseSampleOrder;
}

struct VkPhysicalDeviceShadingRateImagePropertiesNV {
    VkStructureType  sType = VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_SHADING_RATE_IMAGE_PROPERTIES_NV;
    void*            pNext;
    VkExtent2D       shadingRateTexelSize;
    uint32_t         shadingRatePaletteSize;
    uint32_t         shadingRateMaxCoarseSamples;
}

struct VkCoarseSampleLocationNV {
    uint32_t  pixelX;
    uint32_t  pixelY;
    uint32_t  sample;
}

struct VkCoarseSampleOrderCustomNV {
    VkShadingRatePaletteEntryNV         shadingRate;
    uint32_t                            sampleCount;
    uint32_t                            sampleLocationCount;
    const( VkCoarseSampleLocationNV )*  pSampleLocations;
}

struct VkPipelineViewportCoarseSampleOrderStateCreateInfoNV {
    VkStructureType                        sType = VK_STRUCTURE_TYPE_PIPELINE_VIEWPORT_COARSE_SAMPLE_ORDER_STATE_CREATE_INFO_NV;
    const( void )*                         pNext;
    VkCoarseSampleOrderTypeNV              sampleOrderType;
    uint32_t                               customSampleOrderCount;
    const( VkCoarseSampleOrderCustomNV )*  pCustomSampleOrders;
}


// - VK_NV_ray_tracing -
enum VK_NV_ray_tracing = 1;

mixin( VK_DEFINE_NON_DISPATCHABLE_HANDLE!q{VkAccelerationStructureNV} );

enum VK_NV_RAY_TRACING_SPEC_VERSION = 3;
enum VK_NV_RAY_TRACING_EXTENSION_NAME = "VK_NV_ray_tracing";
enum VK_SHADER_UNUSED_NV = (~0U);

enum VkRayTracingShaderGroupTypeNV {
    VK_RAY_TRACING_SHADER_GROUP_TYPE_GENERAL_NV                  = 0,
    VK_RAY_TRACING_SHADER_GROUP_TYPE_TRIANGLES_HIT_GROUP_NV      = 1,
    VK_RAY_TRACING_SHADER_GROUP_TYPE_PROCEDURAL_HIT_GROUP_NV     = 2,
    VK_RAY_TRACING_SHADER_GROUP_TYPE_BEGIN_RANGE_NV              = VK_RAY_TRACING_SHADER_GROUP_TYPE_GENERAL_NV,
    VK_RAY_TRACING_SHADER_GROUP_TYPE_END_RANGE_NV                = VK_RAY_TRACING_SHADER_GROUP_TYPE_PROCEDURAL_HIT_GROUP_NV,
    VK_RAY_TRACING_SHADER_GROUP_TYPE_RANGE_SIZE_NV               = VK_RAY_TRACING_SHADER_GROUP_TYPE_PROCEDURAL_HIT_GROUP_NV - VK_RAY_TRACING_SHADER_GROUP_TYPE_GENERAL_NV + 1,
    VK_RAY_TRACING_SHADER_GROUP_TYPE_MAX_ENUM_NV                 = 0x7FFFFFFF
}

enum VK_RAY_TRACING_SHADER_GROUP_TYPE_GENERAL_NV                 = VkRayTracingShaderGroupTypeNV.VK_RAY_TRACING_SHADER_GROUP_TYPE_GENERAL_NV;
enum VK_RAY_TRACING_SHADER_GROUP_TYPE_TRIANGLES_HIT_GROUP_NV     = VkRayTracingShaderGroupTypeNV.VK_RAY_TRACING_SHADER_GROUP_TYPE_TRIANGLES_HIT_GROUP_NV;
enum VK_RAY_TRACING_SHADER_GROUP_TYPE_PROCEDURAL_HIT_GROUP_NV    = VkRayTracingShaderGroupTypeNV.VK_RAY_TRACING_SHADER_GROUP_TYPE_PROCEDURAL_HIT_GROUP_NV;
enum VK_RAY_TRACING_SHADER_GROUP_TYPE_BEGIN_RANGE_NV             = VkRayTracingShaderGroupTypeNV.VK_RAY_TRACING_SHADER_GROUP_TYPE_BEGIN_RANGE_NV;
enum VK_RAY_TRACING_SHADER_GROUP_TYPE_END_RANGE_NV               = VkRayTracingShaderGroupTypeNV.VK_RAY_TRACING_SHADER_GROUP_TYPE_END_RANGE_NV;
enum VK_RAY_TRACING_SHADER_GROUP_TYPE_RANGE_SIZE_NV              = VkRayTracingShaderGroupTypeNV.VK_RAY_TRACING_SHADER_GROUP_TYPE_RANGE_SIZE_NV;
enum VK_RAY_TRACING_SHADER_GROUP_TYPE_MAX_ENUM_NV                = VkRayTracingShaderGroupTypeNV.VK_RAY_TRACING_SHADER_GROUP_TYPE_MAX_ENUM_NV;

enum VkGeometryTypeNV {
    VK_GEOMETRY_TYPE_TRIANGLES_NV        = 0,
    VK_GEOMETRY_TYPE_AABBS_NV            = 1,
    VK_GEOMETRY_TYPE_BEGIN_RANGE_NV      = VK_GEOMETRY_TYPE_TRIANGLES_NV,
    VK_GEOMETRY_TYPE_END_RANGE_NV        = VK_GEOMETRY_TYPE_AABBS_NV,
    VK_GEOMETRY_TYPE_RANGE_SIZE_NV       = VK_GEOMETRY_TYPE_AABBS_NV - VK_GEOMETRY_TYPE_TRIANGLES_NV + 1,
    VK_GEOMETRY_TYPE_MAX_ENUM_NV         = 0x7FFFFFFF
}

enum VK_GEOMETRY_TYPE_TRIANGLES_NV       = VkGeometryTypeNV.VK_GEOMETRY_TYPE_TRIANGLES_NV;
enum VK_GEOMETRY_TYPE_AABBS_NV           = VkGeometryTypeNV.VK_GEOMETRY_TYPE_AABBS_NV;
enum VK_GEOMETRY_TYPE_BEGIN_RANGE_NV     = VkGeometryTypeNV.VK_GEOMETRY_TYPE_BEGIN_RANGE_NV;
enum VK_GEOMETRY_TYPE_END_RANGE_NV       = VkGeometryTypeNV.VK_GEOMETRY_TYPE_END_RANGE_NV;
enum VK_GEOMETRY_TYPE_RANGE_SIZE_NV      = VkGeometryTypeNV.VK_GEOMETRY_TYPE_RANGE_SIZE_NV;
enum VK_GEOMETRY_TYPE_MAX_ENUM_NV        = VkGeometryTypeNV.VK_GEOMETRY_TYPE_MAX_ENUM_NV;

enum VkAccelerationStructureTypeNV {
    VK_ACCELERATION_STRUCTURE_TYPE_TOP_LEVEL_NV          = 0,
    VK_ACCELERATION_STRUCTURE_TYPE_BOTTOM_LEVEL_NV       = 1,
    VK_ACCELERATION_STRUCTURE_TYPE_BEGIN_RANGE_NV        = VK_ACCELERATION_STRUCTURE_TYPE_TOP_LEVEL_NV,
    VK_ACCELERATION_STRUCTURE_TYPE_END_RANGE_NV          = VK_ACCELERATION_STRUCTURE_TYPE_BOTTOM_LEVEL_NV,
    VK_ACCELERATION_STRUCTURE_TYPE_RANGE_SIZE_NV         = VK_ACCELERATION_STRUCTURE_TYPE_BOTTOM_LEVEL_NV - VK_ACCELERATION_STRUCTURE_TYPE_TOP_LEVEL_NV + 1,
    VK_ACCELERATION_STRUCTURE_TYPE_MAX_ENUM_NV           = 0x7FFFFFFF
}

enum VK_ACCELERATION_STRUCTURE_TYPE_TOP_LEVEL_NV         = VkAccelerationStructureTypeNV.VK_ACCELERATION_STRUCTURE_TYPE_TOP_LEVEL_NV;
enum VK_ACCELERATION_STRUCTURE_TYPE_BOTTOM_LEVEL_NV      = VkAccelerationStructureTypeNV.VK_ACCELERATION_STRUCTURE_TYPE_BOTTOM_LEVEL_NV;
enum VK_ACCELERATION_STRUCTURE_TYPE_BEGIN_RANGE_NV       = VkAccelerationStructureTypeNV.VK_ACCELERATION_STRUCTURE_TYPE_BEGIN_RANGE_NV;
enum VK_ACCELERATION_STRUCTURE_TYPE_END_RANGE_NV         = VkAccelerationStructureTypeNV.VK_ACCELERATION_STRUCTURE_TYPE_END_RANGE_NV;
enum VK_ACCELERATION_STRUCTURE_TYPE_RANGE_SIZE_NV        = VkAccelerationStructureTypeNV.VK_ACCELERATION_STRUCTURE_TYPE_RANGE_SIZE_NV;
enum VK_ACCELERATION_STRUCTURE_TYPE_MAX_ENUM_NV          = VkAccelerationStructureTypeNV.VK_ACCELERATION_STRUCTURE_TYPE_MAX_ENUM_NV;

enum VkCopyAccelerationStructureModeNV {
    VK_COPY_ACCELERATION_STRUCTURE_MODE_CLONE_NV         = 0,
    VK_COPY_ACCELERATION_STRUCTURE_MODE_COMPACT_NV       = 1,
    VK_COPY_ACCELERATION_STRUCTURE_MODE_BEGIN_RANGE_NV   = VK_COPY_ACCELERATION_STRUCTURE_MODE_CLONE_NV,
    VK_COPY_ACCELERATION_STRUCTURE_MODE_END_RANGE_NV     = VK_COPY_ACCELERATION_STRUCTURE_MODE_COMPACT_NV,
    VK_COPY_ACCELERATION_STRUCTURE_MODE_RANGE_SIZE_NV    = VK_COPY_ACCELERATION_STRUCTURE_MODE_COMPACT_NV - VK_COPY_ACCELERATION_STRUCTURE_MODE_CLONE_NV + 1,
    VK_COPY_ACCELERATION_STRUCTURE_MODE_MAX_ENUM_NV      = 0x7FFFFFFF
}

enum VK_COPY_ACCELERATION_STRUCTURE_MODE_CLONE_NV        = VkCopyAccelerationStructureModeNV.VK_COPY_ACCELERATION_STRUCTURE_MODE_CLONE_NV;
enum VK_COPY_ACCELERATION_STRUCTURE_MODE_COMPACT_NV      = VkCopyAccelerationStructureModeNV.VK_COPY_ACCELERATION_STRUCTURE_MODE_COMPACT_NV;
enum VK_COPY_ACCELERATION_STRUCTURE_MODE_BEGIN_RANGE_NV  = VkCopyAccelerationStructureModeNV.VK_COPY_ACCELERATION_STRUCTURE_MODE_BEGIN_RANGE_NV;
enum VK_COPY_ACCELERATION_STRUCTURE_MODE_END_RANGE_NV    = VkCopyAccelerationStructureModeNV.VK_COPY_ACCELERATION_STRUCTURE_MODE_END_RANGE_NV;
enum VK_COPY_ACCELERATION_STRUCTURE_MODE_RANGE_SIZE_NV   = VkCopyAccelerationStructureModeNV.VK_COPY_ACCELERATION_STRUCTURE_MODE_RANGE_SIZE_NV;
enum VK_COPY_ACCELERATION_STRUCTURE_MODE_MAX_ENUM_NV     = VkCopyAccelerationStructureModeNV.VK_COPY_ACCELERATION_STRUCTURE_MODE_MAX_ENUM_NV;

enum VkAccelerationStructureMemoryRequirementsTypeNV {
    VK_ACCELERATION_STRUCTURE_MEMORY_REQUIREMENTS_TYPE_OBJECT_NV                 = 0,
    VK_ACCELERATION_STRUCTURE_MEMORY_REQUIREMENTS_TYPE_BUILD_SCRATCH_NV          = 1,
    VK_ACCELERATION_STRUCTURE_MEMORY_REQUIREMENTS_TYPE_UPDATE_SCRATCH_NV         = 2,
    VK_ACCELERATION_STRUCTURE_MEMORY_REQUIREMENTS_TYPE_BEGIN_RANGE_NV            = VK_ACCELERATION_STRUCTURE_MEMORY_REQUIREMENTS_TYPE_OBJECT_NV,
    VK_ACCELERATION_STRUCTURE_MEMORY_REQUIREMENTS_TYPE_END_RANGE_NV              = VK_ACCELERATION_STRUCTURE_MEMORY_REQUIREMENTS_TYPE_UPDATE_SCRATCH_NV,
    VK_ACCELERATION_STRUCTURE_MEMORY_REQUIREMENTS_TYPE_RANGE_SIZE_NV             = VK_ACCELERATION_STRUCTURE_MEMORY_REQUIREMENTS_TYPE_UPDATE_SCRATCH_NV - VK_ACCELERATION_STRUCTURE_MEMORY_REQUIREMENTS_TYPE_OBJECT_NV + 1,
    VK_ACCELERATION_STRUCTURE_MEMORY_REQUIREMENTS_TYPE_MAX_ENUM_NV               = 0x7FFFFFFF
}

enum VK_ACCELERATION_STRUCTURE_MEMORY_REQUIREMENTS_TYPE_OBJECT_NV                = VkAccelerationStructureMemoryRequirementsTypeNV.VK_ACCELERATION_STRUCTURE_MEMORY_REQUIREMENTS_TYPE_OBJECT_NV;
enum VK_ACCELERATION_STRUCTURE_MEMORY_REQUIREMENTS_TYPE_BUILD_SCRATCH_NV         = VkAccelerationStructureMemoryRequirementsTypeNV.VK_ACCELERATION_STRUCTURE_MEMORY_REQUIREMENTS_TYPE_BUILD_SCRATCH_NV;
enum VK_ACCELERATION_STRUCTURE_MEMORY_REQUIREMENTS_TYPE_UPDATE_SCRATCH_NV        = VkAccelerationStructureMemoryRequirementsTypeNV.VK_ACCELERATION_STRUCTURE_MEMORY_REQUIREMENTS_TYPE_UPDATE_SCRATCH_NV;
enum VK_ACCELERATION_STRUCTURE_MEMORY_REQUIREMENTS_TYPE_BEGIN_RANGE_NV           = VkAccelerationStructureMemoryRequirementsTypeNV.VK_ACCELERATION_STRUCTURE_MEMORY_REQUIREMENTS_TYPE_BEGIN_RANGE_NV;
enum VK_ACCELERATION_STRUCTURE_MEMORY_REQUIREMENTS_TYPE_END_RANGE_NV             = VkAccelerationStructureMemoryRequirementsTypeNV.VK_ACCELERATION_STRUCTURE_MEMORY_REQUIREMENTS_TYPE_END_RANGE_NV;
enum VK_ACCELERATION_STRUCTURE_MEMORY_REQUIREMENTS_TYPE_RANGE_SIZE_NV            = VkAccelerationStructureMemoryRequirementsTypeNV.VK_ACCELERATION_STRUCTURE_MEMORY_REQUIREMENTS_TYPE_RANGE_SIZE_NV;
enum VK_ACCELERATION_STRUCTURE_MEMORY_REQUIREMENTS_TYPE_MAX_ENUM_NV              = VkAccelerationStructureMemoryRequirementsTypeNV.VK_ACCELERATION_STRUCTURE_MEMORY_REQUIREMENTS_TYPE_MAX_ENUM_NV;

enum VkGeometryFlagBitsNV {
    VK_GEOMETRY_OPAQUE_BIT_NV                            = 0x00000001,
    VK_GEOMETRY_NO_DUPLICATE_ANY_HIT_INVOCATION_BIT_NV   = 0x00000002,
    VK_GEOMETRY_FLAG_BITS_MAX_ENUM_NV                    = 0x7FFFFFFF
}

enum VK_GEOMETRY_OPAQUE_BIT_NV                           = VkGeometryFlagBitsNV.VK_GEOMETRY_OPAQUE_BIT_NV;
enum VK_GEOMETRY_NO_DUPLICATE_ANY_HIT_INVOCATION_BIT_NV  = VkGeometryFlagBitsNV.VK_GEOMETRY_NO_DUPLICATE_ANY_HIT_INVOCATION_BIT_NV;
enum VK_GEOMETRY_FLAG_BITS_MAX_ENUM_NV                   = VkGeometryFlagBitsNV.VK_GEOMETRY_FLAG_BITS_MAX_ENUM_NV;
alias VkGeometryFlagsNV = VkFlags;

enum VkGeometryInstanceFlagBitsNV {
    VK_GEOMETRY_INSTANCE_TRIANGLE_CULL_DISABLE_BIT_NV            = 0x00000001,
    VK_GEOMETRY_INSTANCE_TRIANGLE_FRONT_COUNTERCLOCKWISE_BIT_NV  = 0x00000002,
    VK_GEOMETRY_INSTANCE_FORCE_OPAQUE_BIT_NV                     = 0x00000004,
    VK_GEOMETRY_INSTANCE_FORCE_NO_OPAQUE_BIT_NV                  = 0x00000008,
    VK_GEOMETRY_INSTANCE_FLAG_BITS_MAX_ENUM_NV                   = 0x7FFFFFFF
}

enum VK_GEOMETRY_INSTANCE_TRIANGLE_CULL_DISABLE_BIT_NV           = VkGeometryInstanceFlagBitsNV.VK_GEOMETRY_INSTANCE_TRIANGLE_CULL_DISABLE_BIT_NV;
enum VK_GEOMETRY_INSTANCE_TRIANGLE_FRONT_COUNTERCLOCKWISE_BIT_NV = VkGeometryInstanceFlagBitsNV.VK_GEOMETRY_INSTANCE_TRIANGLE_FRONT_COUNTERCLOCKWISE_BIT_NV;
enum VK_GEOMETRY_INSTANCE_FORCE_OPAQUE_BIT_NV                    = VkGeometryInstanceFlagBitsNV.VK_GEOMETRY_INSTANCE_FORCE_OPAQUE_BIT_NV;
enum VK_GEOMETRY_INSTANCE_FORCE_NO_OPAQUE_BIT_NV                 = VkGeometryInstanceFlagBitsNV.VK_GEOMETRY_INSTANCE_FORCE_NO_OPAQUE_BIT_NV;
enum VK_GEOMETRY_INSTANCE_FLAG_BITS_MAX_ENUM_NV                  = VkGeometryInstanceFlagBitsNV.VK_GEOMETRY_INSTANCE_FLAG_BITS_MAX_ENUM_NV;
alias VkGeometryInstanceFlagsNV = VkFlags;

enum VkBuildAccelerationStructureFlagBitsNV {
    VK_BUILD_ACCELERATION_STRUCTURE_ALLOW_UPDATE_BIT_NV          = 0x00000001,
    VK_BUILD_ACCELERATION_STRUCTURE_ALLOW_COMPACTION_BIT_NV      = 0x00000002,
    VK_BUILD_ACCELERATION_STRUCTURE_PREFER_FAST_TRACE_BIT_NV     = 0x00000004,
    VK_BUILD_ACCELERATION_STRUCTURE_PREFER_FAST_BUILD_BIT_NV     = 0x00000008,
    VK_BUILD_ACCELERATION_STRUCTURE_LOW_MEMORY_BIT_NV            = 0x00000010,
    VK_BUILD_ACCELERATION_STRUCTURE_FLAG_BITS_MAX_ENUM_NV        = 0x7FFFFFFF
}

enum VK_BUILD_ACCELERATION_STRUCTURE_ALLOW_UPDATE_BIT_NV         = VkBuildAccelerationStructureFlagBitsNV.VK_BUILD_ACCELERATION_STRUCTURE_ALLOW_UPDATE_BIT_NV;
enum VK_BUILD_ACCELERATION_STRUCTURE_ALLOW_COMPACTION_BIT_NV     = VkBuildAccelerationStructureFlagBitsNV.VK_BUILD_ACCELERATION_STRUCTURE_ALLOW_COMPACTION_BIT_NV;
enum VK_BUILD_ACCELERATION_STRUCTURE_PREFER_FAST_TRACE_BIT_NV    = VkBuildAccelerationStructureFlagBitsNV.VK_BUILD_ACCELERATION_STRUCTURE_PREFER_FAST_TRACE_BIT_NV;
enum VK_BUILD_ACCELERATION_STRUCTURE_PREFER_FAST_BUILD_BIT_NV    = VkBuildAccelerationStructureFlagBitsNV.VK_BUILD_ACCELERATION_STRUCTURE_PREFER_FAST_BUILD_BIT_NV;
enum VK_BUILD_ACCELERATION_STRUCTURE_LOW_MEMORY_BIT_NV           = VkBuildAccelerationStructureFlagBitsNV.VK_BUILD_ACCELERATION_STRUCTURE_LOW_MEMORY_BIT_NV;
enum VK_BUILD_ACCELERATION_STRUCTURE_FLAG_BITS_MAX_ENUM_NV       = VkBuildAccelerationStructureFlagBitsNV.VK_BUILD_ACCELERATION_STRUCTURE_FLAG_BITS_MAX_ENUM_NV;
alias VkBuildAccelerationStructureFlagsNV = VkFlags;

struct VkRayTracingShaderGroupCreateInfoNV {
    VkStructureType                sType = VK_STRUCTURE_TYPE_RAY_TRACING_SHADER_GROUP_CREATE_INFO_NV;
    const( void )*                 pNext;
    VkRayTracingShaderGroupTypeNV  type;
    uint32_t                       generalShader;
    uint32_t                       closestHitShader;
    uint32_t                       anyHitShader;
    uint32_t                       intersectionShader;
}

struct VkRayTracingPipelineCreateInfoNV {
    VkStructureType                                sType = VK_STRUCTURE_TYPE_RAY_TRACING_PIPELINE_CREATE_INFO_NV;
    const( void )*                                 pNext;
    VkPipelineCreateFlags                          flags;
    uint32_t                                       stageCount;
    const( VkPipelineShaderStageCreateInfo )*      pStages;
    uint32_t                                       groupCount;
    const( VkRayTracingShaderGroupCreateInfoNV )*  pGroups;
    uint32_t                                       maxRecursionDepth;
    VkPipelineLayout                               layout;
    VkPipeline                                     basePipelineHandle;
    int32_t                                        basePipelineIndex;
}

struct VkGeometryTrianglesNV {
    VkStructureType  sType = VK_STRUCTURE_TYPE_GEOMETRY_TRIANGLES_NV;
    const( void )*   pNext;
    VkBuffer         vertexData;
    VkDeviceSize     vertexOffset;
    uint32_t         vertexCount;
    VkDeviceSize     vertexStride;
    VkFormat         vertexFormat;
    VkBuffer         indexData;
    VkDeviceSize     indexOffset;
    uint32_t         indexCount;
    VkIndexType      indexType;
    VkBuffer         transformData;
    VkDeviceSize     transformOffset;
}

struct VkGeometryAABBNV {
    VkStructureType  sType = VK_STRUCTURE_TYPE_GEOMETRY_AABB_NV;
    const( void )*   pNext;
    VkBuffer         aabbData;
    uint32_t         numAABBs;
    uint32_t         stride;
    VkDeviceSize     offset;
}

struct VkGeometryDataNV {
    VkGeometryTrianglesNV  triangles;
    VkGeometryAABBNV       aabbs;
}

struct VkGeometryNV {
    VkStructureType    sType = VK_STRUCTURE_TYPE_GEOMETRY_NV;
    const( void )*     pNext;
    VkGeometryTypeNV   geometryType;
    VkGeometryDataNV   geometry;
    VkGeometryFlagsNV  flags;
}

struct VkAccelerationStructureInfoNV {
    VkStructureType                      sType = VK_STRUCTURE_TYPE_ACCELERATION_STRUCTURE_INFO_NV;
    const( void )*                       pNext;
    VkAccelerationStructureTypeNV        type;
    VkBuildAccelerationStructureFlagsNV  flags;
    uint32_t                             instanceCount;
    uint32_t                             geometryCount;
    const( VkGeometryNV )*               pGeometries;
}

struct VkAccelerationStructureCreateInfoNV {
    VkStructureType                sType = VK_STRUCTURE_TYPE_ACCELERATION_STRUCTURE_CREATE_INFO_NV;
    const( void )*                 pNext;
    VkDeviceSize                   compactedSize;
    VkAccelerationStructureInfoNV  info;
}

struct VkBindAccelerationStructureMemoryInfoNV {
    VkStructureType            sType = VK_STRUCTURE_TYPE_BIND_ACCELERATION_STRUCTURE_MEMORY_INFO_NV;
    const( void )*             pNext;
    VkAccelerationStructureNV  accelerationStructure;
    VkDeviceMemory             memory;
    VkDeviceSize               memoryOffset;
    uint32_t                   deviceIndexCount;
    const( uint32_t )*         pDeviceIndices;
}

struct VkWriteDescriptorSetAccelerationStructureNV {
    VkStructureType                      sType = VK_STRUCTURE_TYPE_WRITE_DESCRIPTOR_SET_ACCELERATION_STRUCTURE_NV;
    const( void )*                       pNext;
    uint32_t                             accelerationStructureCount;
    const( VkAccelerationStructureNV )*  pAccelerationStructures;
}

struct VkAccelerationStructureMemoryRequirementsInfoNV {
    VkStructureType                                  sType = VK_STRUCTURE_TYPE_ACCELERATION_STRUCTURE_MEMORY_REQUIREMENTS_INFO_NV;
    const( void )*                                   pNext;
    VkAccelerationStructureMemoryRequirementsTypeNV  type;
    VkAccelerationStructureNV                        accelerationStructure;
}

struct VkPhysicalDeviceRayTracingPropertiesNV {
    VkStructureType  sType = VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_RAY_TRACING_PROPERTIES_NV;
    void*            pNext;
    uint32_t         shaderGroupHandleSize;
    uint32_t         maxRecursionDepth;
    uint32_t         maxShaderGroupStride;
    uint32_t         shaderGroupBaseAlignment;
    uint64_t         maxGeometryCount;
    uint64_t         maxInstanceCount;
    uint64_t         maxTriangleCount;
    uint32_t         maxDescriptorSetAccelerationStructures;
}


// - VK_NV_representative_fragment_test -
enum VK_NV_representative_fragment_test = 1;

enum VK_NV_REPRESENTATIVE_FRAGMENT_TEST_SPEC_VERSION = 1;
enum VK_NV_REPRESENTATIVE_FRAGMENT_TEST_EXTENSION_NAME = "VK_NV_representative_fragment_test";

struct VkPhysicalDeviceRepresentativeFragmentTestFeaturesNV {
    VkStructureType  sType = VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_REPRESENTATIVE_FRAGMENT_TEST_FEATURES_NV;
    void*            pNext;
    VkBool32         representativeFragmentTest;
}

struct VkPipelineRepresentativeFragmentTestStateCreateInfoNV {
    VkStructureType  sType = VK_STRUCTURE_TYPE_PIPELINE_REPRESENTATIVE_FRAGMENT_TEST_STATE_CREATE_INFO_NV;
    const( void )*   pNext;
    VkBool32         representativeFragmentTestEnable;
}


// - VK_EXT_filter_cubic -
enum VK_EXT_filter_cubic = 1;

enum VK_EXT_FILTER_CUBIC_SPEC_VERSION = 1;
enum VK_EXT_FILTER_CUBIC_EXTENSION_NAME = "VK_EXT_filter_cubic";

struct VkPhysicalDeviceImageViewImageFormatInfoEXT {
    VkStructureType  sType = VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_IMAGE_VIEW_IMAGE_FORMAT_INFO_EXT;
    void*            pNext;
    VkImageViewType  imageViewType;
}

struct VkFilterCubicImageViewImageFormatPropertiesEXT {
    VkStructureType  sType = VK_STRUCTURE_TYPE_FILTER_CUBIC_IMAGE_VIEW_IMAGE_FORMAT_PROPERTIES_EXT;
    void*            pNext;
    VkBool32         filterCubic;
    VkBool32         filterCubicMinmax;
}


// - VK_EXT_global_priority -
enum VK_EXT_global_priority = 1;

enum VK_EXT_GLOBAL_PRIORITY_SPEC_VERSION = 2;
enum VK_EXT_GLOBAL_PRIORITY_EXTENSION_NAME = "VK_EXT_global_priority";

enum VkQueueGlobalPriorityEXT {
    VK_QUEUE_GLOBAL_PRIORITY_LOW_EXT             = 128,
    VK_QUEUE_GLOBAL_PRIORITY_MEDIUM_EXT          = 256,
    VK_QUEUE_GLOBAL_PRIORITY_HIGH_EXT            = 512,
    VK_QUEUE_GLOBAL_PRIORITY_REALTIME_EXT        = 1024,
    VK_QUEUE_GLOBAL_PRIORITY_BEGIN_RANGE_EXT     = VK_QUEUE_GLOBAL_PRIORITY_LOW_EXT,
    VK_QUEUE_GLOBAL_PRIORITY_END_RANGE_EXT       = VK_QUEUE_GLOBAL_PRIORITY_REALTIME_EXT,
    VK_QUEUE_GLOBAL_PRIORITY_RANGE_SIZE_EXT      = VK_QUEUE_GLOBAL_PRIORITY_REALTIME_EXT - VK_QUEUE_GLOBAL_PRIORITY_LOW_EXT + 1,
    VK_QUEUE_GLOBAL_PRIORITY_MAX_ENUM_EXT        = 0x7FFFFFFF
}

enum VK_QUEUE_GLOBAL_PRIORITY_LOW_EXT            = VkQueueGlobalPriorityEXT.VK_QUEUE_GLOBAL_PRIORITY_LOW_EXT;
enum VK_QUEUE_GLOBAL_PRIORITY_MEDIUM_EXT         = VkQueueGlobalPriorityEXT.VK_QUEUE_GLOBAL_PRIORITY_MEDIUM_EXT;
enum VK_QUEUE_GLOBAL_PRIORITY_HIGH_EXT           = VkQueueGlobalPriorityEXT.VK_QUEUE_GLOBAL_PRIORITY_HIGH_EXT;
enum VK_QUEUE_GLOBAL_PRIORITY_REALTIME_EXT       = VkQueueGlobalPriorityEXT.VK_QUEUE_GLOBAL_PRIORITY_REALTIME_EXT;
enum VK_QUEUE_GLOBAL_PRIORITY_BEGIN_RANGE_EXT    = VkQueueGlobalPriorityEXT.VK_QUEUE_GLOBAL_PRIORITY_BEGIN_RANGE_EXT;
enum VK_QUEUE_GLOBAL_PRIORITY_END_RANGE_EXT      = VkQueueGlobalPriorityEXT.VK_QUEUE_GLOBAL_PRIORITY_END_RANGE_EXT;
enum VK_QUEUE_GLOBAL_PRIORITY_RANGE_SIZE_EXT     = VkQueueGlobalPriorityEXT.VK_QUEUE_GLOBAL_PRIORITY_RANGE_SIZE_EXT;
enum VK_QUEUE_GLOBAL_PRIORITY_MAX_ENUM_EXT       = VkQueueGlobalPriorityEXT.VK_QUEUE_GLOBAL_PRIORITY_MAX_ENUM_EXT;

struct VkDeviceQueueGlobalPriorityCreateInfoEXT {
    VkStructureType           sType = VK_STRUCTURE_TYPE_DEVICE_QUEUE_GLOBAL_PRIORITY_CREATE_INFO_EXT;
    const( void )*            pNext;
    VkQueueGlobalPriorityEXT  globalPriority;
}


// - VK_EXT_external_memory_host -
enum VK_EXT_external_memory_host = 1;

enum VK_EXT_EXTERNAL_MEMORY_HOST_SPEC_VERSION = 1;
enum VK_EXT_EXTERNAL_MEMORY_HOST_EXTENSION_NAME = "VK_EXT_external_memory_host";

struct VkImportMemoryHostPointerInfoEXT {
    VkStructureType                     sType = VK_STRUCTURE_TYPE_IMPORT_MEMORY_HOST_POINTER_INFO_EXT;
    const( void )*                      pNext;
    VkExternalMemoryHandleTypeFlagBits  handleType;
    void*                               pHostPointer;
}

struct VkMemoryHostPointerPropertiesEXT {
    VkStructureType  sType = VK_STRUCTURE_TYPE_MEMORY_HOST_POINTER_PROPERTIES_EXT;
    void*            pNext;
    uint32_t         memoryTypeBits;
}

struct VkPhysicalDeviceExternalMemoryHostPropertiesEXT {
    VkStructureType  sType = VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_EXTERNAL_MEMORY_HOST_PROPERTIES_EXT;
    void*            pNext;
    VkDeviceSize     minImportedHostPointerAlignment;
}


// - VK_AMD_buffer_marker -
enum VK_AMD_buffer_marker = 1;

enum VK_AMD_BUFFER_MARKER_SPEC_VERSION = 1;
enum VK_AMD_BUFFER_MARKER_EXTENSION_NAME = "VK_AMD_buffer_marker";


// - VK_EXT_calibrated_timestamps -
enum VK_EXT_calibrated_timestamps = 1;

enum VK_EXT_CALIBRATED_TIMESTAMPS_SPEC_VERSION = 1;
enum VK_EXT_CALIBRATED_TIMESTAMPS_EXTENSION_NAME = "VK_EXT_calibrated_timestamps";

enum VkTimeDomainEXT {
    VK_TIME_DOMAIN_DEVICE_EXT                            = 0,
    VK_TIME_DOMAIN_CLOCK_MONOTONIC_EXT                   = 1,
    VK_TIME_DOMAIN_CLOCK_MONOTONIC_RAW_EXT               = 2,
    VK_TIME_DOMAIN_QUERY_PERFORMANCE_COUNTER_EXT         = 3,
    VK_TIME_DOMAIN_BEGIN_RANGE_EXT                       = VK_TIME_DOMAIN_DEVICE_EXT,
    VK_TIME_DOMAIN_END_RANGE_EXT                         = VK_TIME_DOMAIN_QUERY_PERFORMANCE_COUNTER_EXT,
    VK_TIME_DOMAIN_RANGE_SIZE_EXT                        = VK_TIME_DOMAIN_QUERY_PERFORMANCE_COUNTER_EXT - VK_TIME_DOMAIN_DEVICE_EXT + 1,
    VK_TIME_DOMAIN_MAX_ENUM_EXT                          = 0x7FFFFFFF
}

enum VK_TIME_DOMAIN_DEVICE_EXT                           = VkTimeDomainEXT.VK_TIME_DOMAIN_DEVICE_EXT;
enum VK_TIME_DOMAIN_CLOCK_MONOTONIC_EXT                  = VkTimeDomainEXT.VK_TIME_DOMAIN_CLOCK_MONOTONIC_EXT;
enum VK_TIME_DOMAIN_CLOCK_MONOTONIC_RAW_EXT              = VkTimeDomainEXT.VK_TIME_DOMAIN_CLOCK_MONOTONIC_RAW_EXT;
enum VK_TIME_DOMAIN_QUERY_PERFORMANCE_COUNTER_EXT        = VkTimeDomainEXT.VK_TIME_DOMAIN_QUERY_PERFORMANCE_COUNTER_EXT;
enum VK_TIME_DOMAIN_BEGIN_RANGE_EXT                      = VkTimeDomainEXT.VK_TIME_DOMAIN_BEGIN_RANGE_EXT;
enum VK_TIME_DOMAIN_END_RANGE_EXT                        = VkTimeDomainEXT.VK_TIME_DOMAIN_END_RANGE_EXT;
enum VK_TIME_DOMAIN_RANGE_SIZE_EXT                       = VkTimeDomainEXT.VK_TIME_DOMAIN_RANGE_SIZE_EXT;
enum VK_TIME_DOMAIN_MAX_ENUM_EXT                         = VkTimeDomainEXT.VK_TIME_DOMAIN_MAX_ENUM_EXT;

struct VkCalibratedTimestampInfoEXT {
    VkStructureType  sType = VK_STRUCTURE_TYPE_CALIBRATED_TIMESTAMP_INFO_EXT;
    const( void )*   pNext;
    VkTimeDomainEXT  timeDomain;
}


// - VK_AMD_shader_core_properties -
enum VK_AMD_shader_core_properties = 1;

enum VK_AMD_SHADER_CORE_PROPERTIES_SPEC_VERSION = 1;
enum VK_AMD_SHADER_CORE_PROPERTIES_EXTENSION_NAME = "VK_AMD_shader_core_properties";

struct VkPhysicalDeviceShaderCorePropertiesAMD {
    VkStructureType  sType = VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_SHADER_CORE_PROPERTIES_AMD;
    void*            pNext;
    uint32_t         shaderEngineCount;
    uint32_t         shaderArraysPerEngineCount;
    uint32_t         computeUnitsPerShaderArray;
    uint32_t         simdPerComputeUnit;
    uint32_t         wavefrontsPerSimd;
    uint32_t         wavefrontSize;
    uint32_t         sgprsPerSimd;
    uint32_t         minSgprAllocation;
    uint32_t         maxSgprAllocation;
    uint32_t         sgprAllocationGranularity;
    uint32_t         vgprsPerSimd;
    uint32_t         minVgprAllocation;
    uint32_t         maxVgprAllocation;
    uint32_t         vgprAllocationGranularity;
}


// - VK_AMD_memory_overallocation_behavior -
enum VK_AMD_memory_overallocation_behavior = 1;

enum VK_AMD_MEMORY_OVERALLOCATION_BEHAVIOR_SPEC_VERSION = 1;
enum VK_AMD_MEMORY_OVERALLOCATION_BEHAVIOR_EXTENSION_NAME = "VK_AMD_memory_overallocation_behavior";

enum VkMemoryOverallocationBehaviorAMD {
    VK_MEMORY_OVERALLOCATION_BEHAVIOR_DEFAULT_AMD        = 0,
    VK_MEMORY_OVERALLOCATION_BEHAVIOR_ALLOWED_AMD        = 1,
    VK_MEMORY_OVERALLOCATION_BEHAVIOR_DISALLOWED_AMD     = 2,
    VK_MEMORY_OVERALLOCATION_BEHAVIOR_BEGIN_RANGE_AMD    = VK_MEMORY_OVERALLOCATION_BEHAVIOR_DEFAULT_AMD,
    VK_MEMORY_OVERALLOCATION_BEHAVIOR_END_RANGE_AMD      = VK_MEMORY_OVERALLOCATION_BEHAVIOR_DISALLOWED_AMD,
    VK_MEMORY_OVERALLOCATION_BEHAVIOR_RANGE_SIZE_AMD     = VK_MEMORY_OVERALLOCATION_BEHAVIOR_DISALLOWED_AMD - VK_MEMORY_OVERALLOCATION_BEHAVIOR_DEFAULT_AMD + 1,
    VK_MEMORY_OVERALLOCATION_BEHAVIOR_MAX_ENUM_AMD       = 0x7FFFFFFF
}

enum VK_MEMORY_OVERALLOCATION_BEHAVIOR_DEFAULT_AMD       = VkMemoryOverallocationBehaviorAMD.VK_MEMORY_OVERALLOCATION_BEHAVIOR_DEFAULT_AMD;
enum VK_MEMORY_OVERALLOCATION_BEHAVIOR_ALLOWED_AMD       = VkMemoryOverallocationBehaviorAMD.VK_MEMORY_OVERALLOCATION_BEHAVIOR_ALLOWED_AMD;
enum VK_MEMORY_OVERALLOCATION_BEHAVIOR_DISALLOWED_AMD    = VkMemoryOverallocationBehaviorAMD.VK_MEMORY_OVERALLOCATION_BEHAVIOR_DISALLOWED_AMD;
enum VK_MEMORY_OVERALLOCATION_BEHAVIOR_BEGIN_RANGE_AMD   = VkMemoryOverallocationBehaviorAMD.VK_MEMORY_OVERALLOCATION_BEHAVIOR_BEGIN_RANGE_AMD;
enum VK_MEMORY_OVERALLOCATION_BEHAVIOR_END_RANGE_AMD     = VkMemoryOverallocationBehaviorAMD.VK_MEMORY_OVERALLOCATION_BEHAVIOR_END_RANGE_AMD;
enum VK_MEMORY_OVERALLOCATION_BEHAVIOR_RANGE_SIZE_AMD    = VkMemoryOverallocationBehaviorAMD.VK_MEMORY_OVERALLOCATION_BEHAVIOR_RANGE_SIZE_AMD;
enum VK_MEMORY_OVERALLOCATION_BEHAVIOR_MAX_ENUM_AMD      = VkMemoryOverallocationBehaviorAMD.VK_MEMORY_OVERALLOCATION_BEHAVIOR_MAX_ENUM_AMD;

struct VkDeviceMemoryOverallocationCreateInfoAMD {
    VkStructureType                    sType = VK_STRUCTURE_TYPE_DEVICE_MEMORY_OVERALLOCATION_CREATE_INFO_AMD;
    const( void )*                     pNext;
    VkMemoryOverallocationBehaviorAMD  overallocationBehavior;
}


// - VK_EXT_vertex_attribute_divisor -
enum VK_EXT_vertex_attribute_divisor = 1;

enum VK_EXT_VERTEX_ATTRIBUTE_DIVISOR_SPEC_VERSION = 3;
enum VK_EXT_VERTEX_ATTRIBUTE_DIVISOR_EXTENSION_NAME = "VK_EXT_vertex_attribute_divisor";

struct VkPhysicalDeviceVertexAttributeDivisorPropertiesEXT {
    VkStructureType  sType = VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_VERTEX_ATTRIBUTE_DIVISOR_PROPERTIES_EXT;
    void*            pNext;
    uint32_t         maxVertexAttribDivisor;
}

struct VkVertexInputBindingDivisorDescriptionEXT {
    uint32_t  binding;
    uint32_t  divisor;
}

struct VkPipelineVertexInputDivisorStateCreateInfoEXT {
    VkStructureType                                      sType = VK_STRUCTURE_TYPE_PIPELINE_VERTEX_INPUT_DIVISOR_STATE_CREATE_INFO_EXT;
    const( void )*                                       pNext;
    uint32_t                                             vertexBindingDivisorCount;
    const( VkVertexInputBindingDivisorDescriptionEXT )*  pVertexBindingDivisors;
}

struct VkPhysicalDeviceVertexAttributeDivisorFeaturesEXT {
    VkStructureType  sType = VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_VERTEX_ATTRIBUTE_DIVISOR_FEATURES_EXT;
    void*            pNext;
    VkBool32         vertexAttributeInstanceRateDivisor;
    VkBool32         vertexAttributeInstanceRateZeroDivisor;
}


// - VK_EXT_pipeline_creation_feedback -
enum VK_EXT_pipeline_creation_feedback = 1;

enum VK_EXT_PIPELINE_CREATION_FEEDBACK_SPEC_VERSION = 1;
enum VK_EXT_PIPELINE_CREATION_FEEDBACK_EXTENSION_NAME = "VK_EXT_pipeline_creation_feedback";

enum VkPipelineCreationFeedbackFlagBitsEXT {
    VK_PIPELINE_CREATION_FEEDBACK_VALID_BIT_EXT                                  = 0x00000001,
    VK_PIPELINE_CREATION_FEEDBACK_APPLICATION_PIPELINE_CACHE_HIT_BIT_EXT         = 0x00000002,
    VK_PIPELINE_CREATION_FEEDBACK_BASE_PIPELINE_ACCELERATION_BIT_EXT             = 0x00000004,
    VK_PIPELINE_CREATION_FEEDBACK_FLAG_BITS_MAX_ENUM_EXT                         = 0x7FFFFFFF
}

enum VK_PIPELINE_CREATION_FEEDBACK_VALID_BIT_EXT                                 = VkPipelineCreationFeedbackFlagBitsEXT.VK_PIPELINE_CREATION_FEEDBACK_VALID_BIT_EXT;
enum VK_PIPELINE_CREATION_FEEDBACK_APPLICATION_PIPELINE_CACHE_HIT_BIT_EXT        = VkPipelineCreationFeedbackFlagBitsEXT.VK_PIPELINE_CREATION_FEEDBACK_APPLICATION_PIPELINE_CACHE_HIT_BIT_EXT;
enum VK_PIPELINE_CREATION_FEEDBACK_BASE_PIPELINE_ACCELERATION_BIT_EXT            = VkPipelineCreationFeedbackFlagBitsEXT.VK_PIPELINE_CREATION_FEEDBACK_BASE_PIPELINE_ACCELERATION_BIT_EXT;
enum VK_PIPELINE_CREATION_FEEDBACK_FLAG_BITS_MAX_ENUM_EXT                        = VkPipelineCreationFeedbackFlagBitsEXT.VK_PIPELINE_CREATION_FEEDBACK_FLAG_BITS_MAX_ENUM_EXT;
alias VkPipelineCreationFeedbackFlagsEXT = VkFlags;

struct VkPipelineCreationFeedbackEXT {
    VkPipelineCreationFeedbackFlagsEXT  flags;
    uint64_t                            duration;
}

struct VkPipelineCreationFeedbackCreateInfoEXT {
    VkStructureType                 sType = VK_STRUCTURE_TYPE_PIPELINE_CREATION_FEEDBACK_CREATE_INFO_EXT;
    const( void )*                  pNext;
    VkPipelineCreationFeedbackEXT*  pPipelineCreationFeedback;
    uint32_t                        pipelineStageCreationFeedbackCount;
    VkPipelineCreationFeedbackEXT*  pPipelineStageCreationFeedbacks;
}


// - VK_NV_shader_subgroup_partitioned -
enum VK_NV_shader_subgroup_partitioned = 1;

enum VK_NV_SHADER_SUBGROUP_PARTITIONED_SPEC_VERSION = 1;
enum VK_NV_SHADER_SUBGROUP_PARTITIONED_EXTENSION_NAME = "VK_NV_shader_subgroup_partitioned";


// - VK_NV_compute_shader_derivatives -
enum VK_NV_compute_shader_derivatives = 1;

enum VK_NV_COMPUTE_SHADER_DERIVATIVES_SPEC_VERSION = 1;
enum VK_NV_COMPUTE_SHADER_DERIVATIVES_EXTENSION_NAME = "VK_NV_compute_shader_derivatives";

struct VkPhysicalDeviceComputeShaderDerivativesFeaturesNV {
    VkStructureType  sType = VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_COMPUTE_SHADER_DERIVATIVES_FEATURES_NV;
    void*            pNext;
    VkBool32         computeDerivativeGroupQuads;
    VkBool32         computeDerivativeGroupLinear;
}


// - VK_NV_mesh_shader -
enum VK_NV_mesh_shader = 1;

enum VK_NV_MESH_SHADER_SPEC_VERSION = 1;
enum VK_NV_MESH_SHADER_EXTENSION_NAME = "VK_NV_mesh_shader";

struct VkPhysicalDeviceMeshShaderFeaturesNV {
    VkStructureType  sType = VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_MESH_SHADER_FEATURES_NV;
    void*            pNext;
    VkBool32         taskShader;
    VkBool32         meshShader;
}

struct VkPhysicalDeviceMeshShaderPropertiesNV {
    VkStructureType  sType = VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_MESH_SHADER_PROPERTIES_NV;
    void*            pNext;
    uint32_t         maxDrawMeshTasksCount;
    uint32_t         maxTaskWorkGroupInvocations;
    uint32_t[3]      maxTaskWorkGroupSize;
    uint32_t         maxTaskTotalMemorySize;
    uint32_t         maxTaskOutputCount;
    uint32_t         maxMeshWorkGroupInvocations;
    uint32_t[3]      maxMeshWorkGroupSize;
    uint32_t         maxMeshTotalMemorySize;
    uint32_t         maxMeshOutputVertices;
    uint32_t         maxMeshOutputPrimitives;
    uint32_t         maxMeshMultiviewViewCount;
    uint32_t         meshOutputPerVertexGranularity;
    uint32_t         meshOutputPerPrimitiveGranularity;
}

struct VkDrawMeshTasksIndirectCommandNV {
    uint32_t  taskCount;
    uint32_t  firstTask;
}


// - VK_NV_fragment_shader_barycentric -
enum VK_NV_fragment_shader_barycentric = 1;

enum VK_NV_FRAGMENT_SHADER_BARYCENTRIC_SPEC_VERSION = 1;
enum VK_NV_FRAGMENT_SHADER_BARYCENTRIC_EXTENSION_NAME = "VK_NV_fragment_shader_barycentric";

struct VkPhysicalDeviceFragmentShaderBarycentricFeaturesNV {
    VkStructureType  sType = VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_FRAGMENT_SHADER_BARYCENTRIC_FEATURES_NV;
    void*            pNext;
    VkBool32         fragmentShaderBarycentric;
}


// - VK_NV_shader_image_footprint -
enum VK_NV_shader_image_footprint = 1;

enum VK_NV_SHADER_IMAGE_FOOTPRINT_SPEC_VERSION = 1;
enum VK_NV_SHADER_IMAGE_FOOTPRINT_EXTENSION_NAME = "VK_NV_shader_image_footprint";

struct VkPhysicalDeviceShaderImageFootprintFeaturesNV {
    VkStructureType  sType = VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_SHADER_IMAGE_FOOTPRINT_FEATURES_NV;
    void*            pNext;
    VkBool32         imageFootprint;
}


// - VK_NV_scissor_exclusive -
enum VK_NV_scissor_exclusive = 1;

enum VK_NV_SCISSOR_EXCLUSIVE_SPEC_VERSION = 1;
enum VK_NV_SCISSOR_EXCLUSIVE_EXTENSION_NAME = "VK_NV_scissor_exclusive";

struct VkPipelineViewportExclusiveScissorStateCreateInfoNV {
    VkStructureType     sType = VK_STRUCTURE_TYPE_PIPELINE_VIEWPORT_EXCLUSIVE_SCISSOR_STATE_CREATE_INFO_NV;
    const( void )*      pNext;
    uint32_t            exclusiveScissorCount;
    const( VkRect2D )*  pExclusiveScissors;
}

struct VkPhysicalDeviceExclusiveScissorFeaturesNV {
    VkStructureType  sType = VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_EXCLUSIVE_SCISSOR_FEATURES_NV;
    void*            pNext;
    VkBool32         exclusiveScissor;
}


// - VK_NV_device_diagnostic_checkpoints -
enum VK_NV_device_diagnostic_checkpoints = 1;

enum VK_NV_DEVICE_DIAGNOSTIC_CHECKPOINTS_SPEC_VERSION = 2;
enum VK_NV_DEVICE_DIAGNOSTIC_CHECKPOINTS_EXTENSION_NAME = "VK_NV_device_diagnostic_checkpoints";

struct VkQueueFamilyCheckpointPropertiesNV {
    VkStructureType       sType = VK_STRUCTURE_TYPE_QUEUE_FAMILY_CHECKPOINT_PROPERTIES_NV;
    void*                 pNext;
    VkPipelineStageFlags  checkpointExecutionStageMask;
}

struct VkCheckpointDataNV {
    VkStructureType          sType = VK_STRUCTURE_TYPE_CHECKPOINT_DATA_NV;
    void*                    pNext;
    VkPipelineStageFlagBits  stage;
    void*                    pCheckpointMarker;
}


// - VK_INTEL_shader_integer_functions2 -
enum VK_INTEL_shader_integer_functions2 = 1;

enum VK_INTEL_SHADER_INTEGER_FUNCTIONS2_SPEC_VERSION = 1;
enum VK_INTEL_SHADER_INTEGER_FUNCTIONS2_EXTENSION_NAME = "VK_INTEL_shader_integer_functions2";

struct VkPhysicalDeviceShaderIntegerFunctions2INTEL {
    VkStructureType  sType = VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_SHADER_INTEGER_FUNCTIONS2_FEATURES_INTEL;
    void*            pNext;
    VkBool32         shaderIntegerFunctions2;
}


// - VK_INTEL_performance_query -
enum VK_INTEL_performance_query = 1;

mixin( VK_DEFINE_NON_DISPATCHABLE_HANDLE!q{VkPerformanceConfigurationINTEL} );

enum VK_INTEL_PERFORMANCE_QUERY_SPEC_VERSION = 1;
enum VK_INTEL_PERFORMANCE_QUERY_EXTENSION_NAME = "VK_INTEL_performance_query";

enum VkPerformanceConfigurationTypeINTEL {
    VK_PERFORMANCE_CONFIGURATION_TYPE_COMMAND_QUEUE_METRICS_DISCOVERY_ACTIVATED_INTEL    = 0,
    VK_PERFORMANCE_CONFIGURATION_TYPE_BEGIN_RANGE_INTEL                                  = VK_PERFORMANCE_CONFIGURATION_TYPE_COMMAND_QUEUE_METRICS_DISCOVERY_ACTIVATED_INTEL,
    VK_PERFORMANCE_CONFIGURATION_TYPE_END_RANGE_INTEL                                    = VK_PERFORMANCE_CONFIGURATION_TYPE_COMMAND_QUEUE_METRICS_DISCOVERY_ACTIVATED_INTEL,
    VK_PERFORMANCE_CONFIGURATION_TYPE_RANGE_SIZE_INTEL                                   = VK_PERFORMANCE_CONFIGURATION_TYPE_COMMAND_QUEUE_METRICS_DISCOVERY_ACTIVATED_INTEL - VK_PERFORMANCE_CONFIGURATION_TYPE_COMMAND_QUEUE_METRICS_DISCOVERY_ACTIVATED_INTEL + 1,
    VK_PERFORMANCE_CONFIGURATION_TYPE_MAX_ENUM_INTEL                                     = 0x7FFFFFFF
}

enum VK_PERFORMANCE_CONFIGURATION_TYPE_COMMAND_QUEUE_METRICS_DISCOVERY_ACTIVATED_INTEL   = VkPerformanceConfigurationTypeINTEL.VK_PERFORMANCE_CONFIGURATION_TYPE_COMMAND_QUEUE_METRICS_DISCOVERY_ACTIVATED_INTEL;
enum VK_PERFORMANCE_CONFIGURATION_TYPE_BEGIN_RANGE_INTEL                                 = VkPerformanceConfigurationTypeINTEL.VK_PERFORMANCE_CONFIGURATION_TYPE_BEGIN_RANGE_INTEL;
enum VK_PERFORMANCE_CONFIGURATION_TYPE_END_RANGE_INTEL                                   = VkPerformanceConfigurationTypeINTEL.VK_PERFORMANCE_CONFIGURATION_TYPE_END_RANGE_INTEL;
enum VK_PERFORMANCE_CONFIGURATION_TYPE_RANGE_SIZE_INTEL                                  = VkPerformanceConfigurationTypeINTEL.VK_PERFORMANCE_CONFIGURATION_TYPE_RANGE_SIZE_INTEL;
enum VK_PERFORMANCE_CONFIGURATION_TYPE_MAX_ENUM_INTEL                                    = VkPerformanceConfigurationTypeINTEL.VK_PERFORMANCE_CONFIGURATION_TYPE_MAX_ENUM_INTEL;

enum VkQueryPoolSamplingModeINTEL {
    VK_QUERY_POOL_SAMPLING_MODE_MANUAL_INTEL     = 0,
    VK_QUERY_POOL_SAMPLING_MODE_BEGIN_RANGE_INTEL = VK_QUERY_POOL_SAMPLING_MODE_MANUAL_INTEL,
    VK_QUERY_POOL_SAMPLING_MODE_END_RANGE_INTEL  = VK_QUERY_POOL_SAMPLING_MODE_MANUAL_INTEL,
    VK_QUERY_POOL_SAMPLING_MODE_RANGE_SIZE_INTEL = VK_QUERY_POOL_SAMPLING_MODE_MANUAL_INTEL - VK_QUERY_POOL_SAMPLING_MODE_MANUAL_INTEL + 1,
    VK_QUERY_POOL_SAMPLING_MODE_MAX_ENUM_INTEL   = 0x7FFFFFFF
}

enum VK_QUERY_POOL_SAMPLING_MODE_MANUAL_INTEL    = VkQueryPoolSamplingModeINTEL.VK_QUERY_POOL_SAMPLING_MODE_MANUAL_INTEL;
enum VK_QUERY_POOL_SAMPLING_MODE_BEGIN_RANGE_INTEL = VkQueryPoolSamplingModeINTEL.VK_QUERY_POOL_SAMPLING_MODE_BEGIN_RANGE_INTEL;
enum VK_QUERY_POOL_SAMPLING_MODE_END_RANGE_INTEL = VkQueryPoolSamplingModeINTEL.VK_QUERY_POOL_SAMPLING_MODE_END_RANGE_INTEL;
enum VK_QUERY_POOL_SAMPLING_MODE_RANGE_SIZE_INTEL = VkQueryPoolSamplingModeINTEL.VK_QUERY_POOL_SAMPLING_MODE_RANGE_SIZE_INTEL;
enum VK_QUERY_POOL_SAMPLING_MODE_MAX_ENUM_INTEL  = VkQueryPoolSamplingModeINTEL.VK_QUERY_POOL_SAMPLING_MODE_MAX_ENUM_INTEL;

enum VkPerformanceOverrideTypeINTEL {
    VK_PERFORMANCE_OVERRIDE_TYPE_NULL_HARDWARE_INTEL     = 0,
    VK_PERFORMANCE_OVERRIDE_TYPE_FLUSH_GPU_CACHES_INTEL  = 1,
    VK_PERFORMANCE_OVERRIDE_TYPE_BEGIN_RANGE_INTEL       = VK_PERFORMANCE_OVERRIDE_TYPE_NULL_HARDWARE_INTEL,
    VK_PERFORMANCE_OVERRIDE_TYPE_END_RANGE_INTEL         = VK_PERFORMANCE_OVERRIDE_TYPE_FLUSH_GPU_CACHES_INTEL,
    VK_PERFORMANCE_OVERRIDE_TYPE_RANGE_SIZE_INTEL        = VK_PERFORMANCE_OVERRIDE_TYPE_FLUSH_GPU_CACHES_INTEL - VK_PERFORMANCE_OVERRIDE_TYPE_NULL_HARDWARE_INTEL + 1,
    VK_PERFORMANCE_OVERRIDE_TYPE_MAX_ENUM_INTEL          = 0x7FFFFFFF
}

enum VK_PERFORMANCE_OVERRIDE_TYPE_NULL_HARDWARE_INTEL    = VkPerformanceOverrideTypeINTEL.VK_PERFORMANCE_OVERRIDE_TYPE_NULL_HARDWARE_INTEL;
enum VK_PERFORMANCE_OVERRIDE_TYPE_FLUSH_GPU_CACHES_INTEL = VkPerformanceOverrideTypeINTEL.VK_PERFORMANCE_OVERRIDE_TYPE_FLUSH_GPU_CACHES_INTEL;
enum VK_PERFORMANCE_OVERRIDE_TYPE_BEGIN_RANGE_INTEL      = VkPerformanceOverrideTypeINTEL.VK_PERFORMANCE_OVERRIDE_TYPE_BEGIN_RANGE_INTEL;
enum VK_PERFORMANCE_OVERRIDE_TYPE_END_RANGE_INTEL        = VkPerformanceOverrideTypeINTEL.VK_PERFORMANCE_OVERRIDE_TYPE_END_RANGE_INTEL;
enum VK_PERFORMANCE_OVERRIDE_TYPE_RANGE_SIZE_INTEL       = VkPerformanceOverrideTypeINTEL.VK_PERFORMANCE_OVERRIDE_TYPE_RANGE_SIZE_INTEL;
enum VK_PERFORMANCE_OVERRIDE_TYPE_MAX_ENUM_INTEL         = VkPerformanceOverrideTypeINTEL.VK_PERFORMANCE_OVERRIDE_TYPE_MAX_ENUM_INTEL;

enum VkPerformanceParameterTypeINTEL {
    VK_PERFORMANCE_PARAMETER_TYPE_HW_COUNTERS_SUPPORTED_INTEL            = 0,
    VK_PERFORMANCE_PARAMETER_TYPE_STREAM_MARKER_VALID_BITS_INTEL         = 1,
    VK_PERFORMANCE_PARAMETER_TYPE_BEGIN_RANGE_INTEL                      = VK_PERFORMANCE_PARAMETER_TYPE_HW_COUNTERS_SUPPORTED_INTEL,
    VK_PERFORMANCE_PARAMETER_TYPE_END_RANGE_INTEL                        = VK_PERFORMANCE_PARAMETER_TYPE_STREAM_MARKER_VALID_BITS_INTEL,
    VK_PERFORMANCE_PARAMETER_TYPE_RANGE_SIZE_INTEL                       = VK_PERFORMANCE_PARAMETER_TYPE_STREAM_MARKER_VALID_BITS_INTEL - VK_PERFORMANCE_PARAMETER_TYPE_HW_COUNTERS_SUPPORTED_INTEL + 1,
    VK_PERFORMANCE_PARAMETER_TYPE_MAX_ENUM_INTEL                         = 0x7FFFFFFF
}

enum VK_PERFORMANCE_PARAMETER_TYPE_HW_COUNTERS_SUPPORTED_INTEL           = VkPerformanceParameterTypeINTEL.VK_PERFORMANCE_PARAMETER_TYPE_HW_COUNTERS_SUPPORTED_INTEL;
enum VK_PERFORMANCE_PARAMETER_TYPE_STREAM_MARKER_VALID_BITS_INTEL        = VkPerformanceParameterTypeINTEL.VK_PERFORMANCE_PARAMETER_TYPE_STREAM_MARKER_VALID_BITS_INTEL;
enum VK_PERFORMANCE_PARAMETER_TYPE_BEGIN_RANGE_INTEL                     = VkPerformanceParameterTypeINTEL.VK_PERFORMANCE_PARAMETER_TYPE_BEGIN_RANGE_INTEL;
enum VK_PERFORMANCE_PARAMETER_TYPE_END_RANGE_INTEL                       = VkPerformanceParameterTypeINTEL.VK_PERFORMANCE_PARAMETER_TYPE_END_RANGE_INTEL;
enum VK_PERFORMANCE_PARAMETER_TYPE_RANGE_SIZE_INTEL                      = VkPerformanceParameterTypeINTEL.VK_PERFORMANCE_PARAMETER_TYPE_RANGE_SIZE_INTEL;
enum VK_PERFORMANCE_PARAMETER_TYPE_MAX_ENUM_INTEL                        = VkPerformanceParameterTypeINTEL.VK_PERFORMANCE_PARAMETER_TYPE_MAX_ENUM_INTEL;

enum VkPerformanceValueTypeINTEL {
    VK_PERFORMANCE_VALUE_TYPE_UINT32_INTEL       = 0,
    VK_PERFORMANCE_VALUE_TYPE_UINT64_INTEL       = 1,
    VK_PERFORMANCE_VALUE_TYPE_FLOAT_INTEL        = 2,
    VK_PERFORMANCE_VALUE_TYPE_BOOL_INTEL         = 3,
    VK_PERFORMANCE_VALUE_TYPE_STRING_INTEL       = 4,
    VK_PERFORMANCE_VALUE_TYPE_BEGIN_RANGE_INTEL  = VK_PERFORMANCE_VALUE_TYPE_UINT32_INTEL,
    VK_PERFORMANCE_VALUE_TYPE_END_RANGE_INTEL    = VK_PERFORMANCE_VALUE_TYPE_STRING_INTEL,
    VK_PERFORMANCE_VALUE_TYPE_RANGE_SIZE_INTEL   = VK_PERFORMANCE_VALUE_TYPE_STRING_INTEL - VK_PERFORMANCE_VALUE_TYPE_UINT32_INTEL + 1,
    VK_PERFORMANCE_VALUE_TYPE_MAX_ENUM_INTEL     = 0x7FFFFFFF
}

enum VK_PERFORMANCE_VALUE_TYPE_UINT32_INTEL      = VkPerformanceValueTypeINTEL.VK_PERFORMANCE_VALUE_TYPE_UINT32_INTEL;
enum VK_PERFORMANCE_VALUE_TYPE_UINT64_INTEL      = VkPerformanceValueTypeINTEL.VK_PERFORMANCE_VALUE_TYPE_UINT64_INTEL;
enum VK_PERFORMANCE_VALUE_TYPE_FLOAT_INTEL       = VkPerformanceValueTypeINTEL.VK_PERFORMANCE_VALUE_TYPE_FLOAT_INTEL;
enum VK_PERFORMANCE_VALUE_TYPE_BOOL_INTEL        = VkPerformanceValueTypeINTEL.VK_PERFORMANCE_VALUE_TYPE_BOOL_INTEL;
enum VK_PERFORMANCE_VALUE_TYPE_STRING_INTEL      = VkPerformanceValueTypeINTEL.VK_PERFORMANCE_VALUE_TYPE_STRING_INTEL;
enum VK_PERFORMANCE_VALUE_TYPE_BEGIN_RANGE_INTEL = VkPerformanceValueTypeINTEL.VK_PERFORMANCE_VALUE_TYPE_BEGIN_RANGE_INTEL;
enum VK_PERFORMANCE_VALUE_TYPE_END_RANGE_INTEL   = VkPerformanceValueTypeINTEL.VK_PERFORMANCE_VALUE_TYPE_END_RANGE_INTEL;
enum VK_PERFORMANCE_VALUE_TYPE_RANGE_SIZE_INTEL  = VkPerformanceValueTypeINTEL.VK_PERFORMANCE_VALUE_TYPE_RANGE_SIZE_INTEL;
enum VK_PERFORMANCE_VALUE_TYPE_MAX_ENUM_INTEL    = VkPerformanceValueTypeINTEL.VK_PERFORMANCE_VALUE_TYPE_MAX_ENUM_INTEL;

union VkPerformanceValueDataINTEL {
    uint32_t        value32;
    uint64_t        value64;
    float           valueFloat;
    VkBool32        valueBool;
    const( char )*  valueString;
}

struct VkPerformanceValueINTEL {
    VkPerformanceValueTypeINTEL  type;
    VkPerformanceValueDataINTEL  data;
}

struct VkInitializePerformanceApiInfoINTEL {
    VkStructureType  sType = VK_STRUCTURE_TYPE_INITIALIZE_PERFORMANCE_API_INFO_INTEL;
    const( void )*   pNext;
    void*            pUserData;
}

struct VkQueryPoolCreateInfoINTEL {
    VkStructureType               sType = VK_STRUCTURE_TYPE_QUERY_POOL_CREATE_INFO_INTEL;
    const( void )*                pNext;
    VkQueryPoolSamplingModeINTEL  performanceCountersSampling;
}

struct VkPerformanceMarkerInfoINTEL {
    VkStructureType  sType = VK_STRUCTURE_TYPE_PERFORMANCE_MARKER_INFO_INTEL;
    const( void )*   pNext;
    uint64_t         marker;
}

struct VkPerformanceStreamMarkerInfoINTEL {
    VkStructureType  sType = VK_STRUCTURE_TYPE_PERFORMANCE_STREAM_MARKER_INFO_INTEL;
    const( void )*   pNext;
    uint32_t         marker;
}

struct VkPerformanceOverrideInfoINTEL {
    VkStructureType                 sType = VK_STRUCTURE_TYPE_PERFORMANCE_OVERRIDE_INFO_INTEL;
    const( void )*                  pNext;
    VkPerformanceOverrideTypeINTEL  type;
    VkBool32                        enable;
    uint64_t                        parameter;
}

struct VkPerformanceConfigurationAcquireInfoINTEL {
    VkStructureType                      sType = VK_STRUCTURE_TYPE_PERFORMANCE_CONFIGURATION_ACQUIRE_INFO_INTEL;
    const( void )*                       pNext;
    VkPerformanceConfigurationTypeINTEL  type;
}


// - VK_EXT_pci_bus_info -
enum VK_EXT_pci_bus_info = 1;

enum VK_EXT_PCI_BUS_INFO_SPEC_VERSION = 2;
enum VK_EXT_PCI_BUS_INFO_EXTENSION_NAME = "VK_EXT_pci_bus_info";

struct VkPhysicalDevicePCIBusInfoPropertiesEXT {
    VkStructureType  sType = VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_PCI_BUS_INFO_PROPERTIES_EXT;
    void*            pNext;
    uint32_t         pciDomain;
    uint32_t         pciBus;
    uint32_t         pciDevice;
    uint32_t         pciFunction;
}


// - VK_AMD_display_native_hdr -
enum VK_AMD_display_native_hdr = 1;

enum VK_AMD_DISPLAY_NATIVE_HDR_SPEC_VERSION = 1;
enum VK_AMD_DISPLAY_NATIVE_HDR_EXTENSION_NAME = "VK_AMD_display_native_hdr";

struct VkDisplayNativeHdrSurfaceCapabilitiesAMD {
    VkStructureType  sType = VK_STRUCTURE_TYPE_DISPLAY_NATIVE_HDR_SURFACE_CAPABILITIES_AMD;
    void*            pNext;
    VkBool32         localDimmingSupport;
}

struct VkSwapchainDisplayNativeHdrCreateInfoAMD {
    VkStructureType  sType = VK_STRUCTURE_TYPE_SWAPCHAIN_DISPLAY_NATIVE_HDR_CREATE_INFO_AMD;
    const( void )*   pNext;
    VkBool32         localDimmingEnable;
}


// - VK_EXT_fragment_density_map -
enum VK_EXT_fragment_density_map = 1;

enum VK_EXT_FRAGMENT_DENSITY_MAP_SPEC_VERSION = 1;
enum VK_EXT_FRAGMENT_DENSITY_MAP_EXTENSION_NAME = "VK_EXT_fragment_density_map";

struct VkPhysicalDeviceFragmentDensityMapFeaturesEXT {
    VkStructureType  sType = VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_FRAGMENT_DENSITY_MAP_FEATURES_EXT;
    void*            pNext;
    VkBool32         fragmentDensityMap;
    VkBool32         fragmentDensityMapDynamic;
    VkBool32         fragmentDensityMapNonSubsampledImages;
}

struct VkPhysicalDeviceFragmentDensityMapPropertiesEXT {
    VkStructureType  sType = VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_FRAGMENT_DENSITY_MAP_PROPERTIES_EXT;
    void*            pNext;
    VkExtent2D       minFragmentDensityTexelSize;
    VkExtent2D       maxFragmentDensityTexelSize;
    VkBool32         fragmentDensityInvocations;
}

struct VkRenderPassFragmentDensityMapCreateInfoEXT {
    VkStructureType        sType = VK_STRUCTURE_TYPE_RENDER_PASS_FRAGMENT_DENSITY_MAP_CREATE_INFO_EXT;
    const( void )*         pNext;
    VkAttachmentReference  fragmentDensityMapAttachment;
}


// - VK_EXT_scalar_block_layout -
enum VK_EXT_scalar_block_layout = 1;

enum VK_EXT_SCALAR_BLOCK_LAYOUT_SPEC_VERSION = 1;
enum VK_EXT_SCALAR_BLOCK_LAYOUT_EXTENSION_NAME = "VK_EXT_scalar_block_layout";

struct VkPhysicalDeviceScalarBlockLayoutFeaturesEXT {
    VkStructureType  sType = VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_SCALAR_BLOCK_LAYOUT_FEATURES_EXT;
    void*            pNext;
    VkBool32         scalarBlockLayout;
}


// - VK_GOOGLE_hlsl_functionality1 -
enum VK_GOOGLE_hlsl_functionality1 = 1;

enum VK_GOOGLE_HLSL_FUNCTIONALITY1_SPEC_VERSION = 1;
enum VK_GOOGLE_HLSL_FUNCTIONALITY1_EXTENSION_NAME = "VK_GOOGLE_hlsl_functionality1";


// - VK_GOOGLE_decorate_string -
enum VK_GOOGLE_decorate_string = 1;

enum VK_GOOGLE_DECORATE_STRING_SPEC_VERSION = 1;
enum VK_GOOGLE_DECORATE_STRING_EXTENSION_NAME = "VK_GOOGLE_decorate_string";


// - VK_EXT_memory_budget -
enum VK_EXT_memory_budget = 1;

enum VK_EXT_MEMORY_BUDGET_SPEC_VERSION = 1;
enum VK_EXT_MEMORY_BUDGET_EXTENSION_NAME = "VK_EXT_memory_budget";

struct VkPhysicalDeviceMemoryBudgetPropertiesEXT {
    VkStructureType                      sType = VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_MEMORY_BUDGET_PROPERTIES_EXT;
    void*                                pNext;
    VkDeviceSize[ VK_MAX_MEMORY_HEAPS ]  heapBudget;
    VkDeviceSize[ VK_MAX_MEMORY_HEAPS ]  heapUsage;
}


// - VK_EXT_memory_priority -
enum VK_EXT_memory_priority = 1;

enum VK_EXT_MEMORY_PRIORITY_SPEC_VERSION = 1;
enum VK_EXT_MEMORY_PRIORITY_EXTENSION_NAME = "VK_EXT_memory_priority";

struct VkPhysicalDeviceMemoryPriorityFeaturesEXT {
    VkStructureType  sType = VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_MEMORY_PRIORITY_FEATURES_EXT;
    void*            pNext;
    VkBool32         memoryPriority;
}

struct VkMemoryPriorityAllocateInfoEXT {
    VkStructureType  sType = VK_STRUCTURE_TYPE_MEMORY_PRIORITY_ALLOCATE_INFO_EXT;
    const( void )*   pNext;
    float            priority;
}


// - VK_NV_dedicated_allocation_image_aliasing -
enum VK_NV_dedicated_allocation_image_aliasing = 1;

enum VK_NV_DEDICATED_ALLOCATION_IMAGE_ALIASING_SPEC_VERSION = 1;
enum VK_NV_DEDICATED_ALLOCATION_IMAGE_ALIASING_EXTENSION_NAME = "VK_NV_dedicated_allocation_image_aliasing";

struct VkPhysicalDeviceDedicatedAllocationImageAliasingFeaturesNV {
    VkStructureType  sType = VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_DEDICATED_ALLOCATION_IMAGE_ALIASING_FEATURES_NV;
    void*            pNext;
    VkBool32         dedicatedAllocationImageAliasing;
}


// - VK_EXT_buffer_device_address -
enum VK_EXT_buffer_device_address = 1;

alias VkDeviceAddress = uint64_t;

enum VK_EXT_BUFFER_DEVICE_ADDRESS_SPEC_VERSION = 2;
enum VK_EXT_BUFFER_DEVICE_ADDRESS_EXTENSION_NAME = "VK_EXT_buffer_device_address";

struct VkPhysicalDeviceBufferDeviceAddressFeaturesEXT {
    VkStructureType  sType = VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_BUFFER_DEVICE_ADDRESS_FEATURES_EXT;
    void*            pNext;
    VkBool32         bufferDeviceAddress;
    VkBool32         bufferDeviceAddressCaptureReplay;
    VkBool32         bufferDeviceAddressMultiDevice;
}
alias VkPhysicalDeviceBufferAddressFeaturesEXT = VkPhysicalDeviceBufferDeviceAddressFeaturesEXT;

struct VkBufferDeviceAddressInfoEXT {
    VkStructureType  sType = VK_STRUCTURE_TYPE_BUFFER_DEVICE_ADDRESS_INFO_EXT;
    const( void )*   pNext;
    VkBuffer         buffer;
}

struct VkBufferDeviceAddressCreateInfoEXT {
    VkStructureType  sType = VK_STRUCTURE_TYPE_BUFFER_DEVICE_ADDRESS_CREATE_INFO_EXT;
    const( void )*   pNext;
    VkDeviceAddress  deviceAddress;
}


// - VK_EXT_separate_stencil_usage -
enum VK_EXT_separate_stencil_usage = 1;

enum VK_EXT_SEPARATE_STENCIL_USAGE_SPEC_VERSION = 1;
enum VK_EXT_SEPARATE_STENCIL_USAGE_EXTENSION_NAME = "VK_EXT_separate_stencil_usage";

struct VkImageStencilUsageCreateInfoEXT {
    VkStructureType    sType = VK_STRUCTURE_TYPE_IMAGE_STENCIL_USAGE_CREATE_INFO_EXT;
    const( void )*     pNext;
    VkImageUsageFlags  stencilUsage;
}


// - VK_EXT_validation_features -
enum VK_EXT_validation_features = 1;

enum VK_EXT_VALIDATION_FEATURES_SPEC_VERSION = 1;
enum VK_EXT_VALIDATION_FEATURES_EXTENSION_NAME = "VK_EXT_validation_features";

enum VkValidationFeatureEnableEXT {
    VK_VALIDATION_FEATURE_ENABLE_GPU_ASSISTED_EXT                        = 0,
    VK_VALIDATION_FEATURE_ENABLE_GPU_ASSISTED_RESERVE_BINDING_SLOT_EXT   = 1,
    VK_VALIDATION_FEATURE_ENABLE_BEGIN_RANGE_EXT                         = VK_VALIDATION_FEATURE_ENABLE_GPU_ASSISTED_EXT,
    VK_VALIDATION_FEATURE_ENABLE_END_RANGE_EXT                           = VK_VALIDATION_FEATURE_ENABLE_GPU_ASSISTED_RESERVE_BINDING_SLOT_EXT,
    VK_VALIDATION_FEATURE_ENABLE_RANGE_SIZE_EXT                          = VK_VALIDATION_FEATURE_ENABLE_GPU_ASSISTED_RESERVE_BINDING_SLOT_EXT - VK_VALIDATION_FEATURE_ENABLE_GPU_ASSISTED_EXT + 1,
    VK_VALIDATION_FEATURE_ENABLE_MAX_ENUM_EXT                            = 0x7FFFFFFF
}

enum VK_VALIDATION_FEATURE_ENABLE_GPU_ASSISTED_EXT                       = VkValidationFeatureEnableEXT.VK_VALIDATION_FEATURE_ENABLE_GPU_ASSISTED_EXT;
enum VK_VALIDATION_FEATURE_ENABLE_GPU_ASSISTED_RESERVE_BINDING_SLOT_EXT  = VkValidationFeatureEnableEXT.VK_VALIDATION_FEATURE_ENABLE_GPU_ASSISTED_RESERVE_BINDING_SLOT_EXT;
enum VK_VALIDATION_FEATURE_ENABLE_BEGIN_RANGE_EXT                        = VkValidationFeatureEnableEXT.VK_VALIDATION_FEATURE_ENABLE_BEGIN_RANGE_EXT;
enum VK_VALIDATION_FEATURE_ENABLE_END_RANGE_EXT                          = VkValidationFeatureEnableEXT.VK_VALIDATION_FEATURE_ENABLE_END_RANGE_EXT;
enum VK_VALIDATION_FEATURE_ENABLE_RANGE_SIZE_EXT                         = VkValidationFeatureEnableEXT.VK_VALIDATION_FEATURE_ENABLE_RANGE_SIZE_EXT;
enum VK_VALIDATION_FEATURE_ENABLE_MAX_ENUM_EXT                           = VkValidationFeatureEnableEXT.VK_VALIDATION_FEATURE_ENABLE_MAX_ENUM_EXT;

enum VkValidationFeatureDisableEXT {
    VK_VALIDATION_FEATURE_DISABLE_ALL_EXT                = 0,
    VK_VALIDATION_FEATURE_DISABLE_SHADERS_EXT            = 1,
    VK_VALIDATION_FEATURE_DISABLE_THREAD_SAFETY_EXT      = 2,
    VK_VALIDATION_FEATURE_DISABLE_API_PARAMETERS_EXT     = 3,
    VK_VALIDATION_FEATURE_DISABLE_OBJECT_LIFETIMES_EXT   = 4,
    VK_VALIDATION_FEATURE_DISABLE_CORE_CHECKS_EXT        = 5,
    VK_VALIDATION_FEATURE_DISABLE_UNIQUE_HANDLES_EXT     = 6,
    VK_VALIDATION_FEATURE_DISABLE_BEGIN_RANGE_EXT        = VK_VALIDATION_FEATURE_DISABLE_ALL_EXT,
    VK_VALIDATION_FEATURE_DISABLE_END_RANGE_EXT          = VK_VALIDATION_FEATURE_DISABLE_UNIQUE_HANDLES_EXT,
    VK_VALIDATION_FEATURE_DISABLE_RANGE_SIZE_EXT         = VK_VALIDATION_FEATURE_DISABLE_UNIQUE_HANDLES_EXT - VK_VALIDATION_FEATURE_DISABLE_ALL_EXT + 1,
    VK_VALIDATION_FEATURE_DISABLE_MAX_ENUM_EXT           = 0x7FFFFFFF
}

enum VK_VALIDATION_FEATURE_DISABLE_ALL_EXT               = VkValidationFeatureDisableEXT.VK_VALIDATION_FEATURE_DISABLE_ALL_EXT;
enum VK_VALIDATION_FEATURE_DISABLE_SHADERS_EXT           = VkValidationFeatureDisableEXT.VK_VALIDATION_FEATURE_DISABLE_SHADERS_EXT;
enum VK_VALIDATION_FEATURE_DISABLE_THREAD_SAFETY_EXT     = VkValidationFeatureDisableEXT.VK_VALIDATION_FEATURE_DISABLE_THREAD_SAFETY_EXT;
enum VK_VALIDATION_FEATURE_DISABLE_API_PARAMETERS_EXT    = VkValidationFeatureDisableEXT.VK_VALIDATION_FEATURE_DISABLE_API_PARAMETERS_EXT;
enum VK_VALIDATION_FEATURE_DISABLE_OBJECT_LIFETIMES_EXT  = VkValidationFeatureDisableEXT.VK_VALIDATION_FEATURE_DISABLE_OBJECT_LIFETIMES_EXT;
enum VK_VALIDATION_FEATURE_DISABLE_CORE_CHECKS_EXT       = VkValidationFeatureDisableEXT.VK_VALIDATION_FEATURE_DISABLE_CORE_CHECKS_EXT;
enum VK_VALIDATION_FEATURE_DISABLE_UNIQUE_HANDLES_EXT    = VkValidationFeatureDisableEXT.VK_VALIDATION_FEATURE_DISABLE_UNIQUE_HANDLES_EXT;
enum VK_VALIDATION_FEATURE_DISABLE_BEGIN_RANGE_EXT       = VkValidationFeatureDisableEXT.VK_VALIDATION_FEATURE_DISABLE_BEGIN_RANGE_EXT;
enum VK_VALIDATION_FEATURE_DISABLE_END_RANGE_EXT         = VkValidationFeatureDisableEXT.VK_VALIDATION_FEATURE_DISABLE_END_RANGE_EXT;
enum VK_VALIDATION_FEATURE_DISABLE_RANGE_SIZE_EXT        = VkValidationFeatureDisableEXT.VK_VALIDATION_FEATURE_DISABLE_RANGE_SIZE_EXT;
enum VK_VALIDATION_FEATURE_DISABLE_MAX_ENUM_EXT          = VkValidationFeatureDisableEXT.VK_VALIDATION_FEATURE_DISABLE_MAX_ENUM_EXT;

struct VkValidationFeaturesEXT {
    VkStructureType                          sType = VK_STRUCTURE_TYPE_VALIDATION_FEATURES_EXT;
    const( void )*                           pNext;
    uint32_t                                 enabledValidationFeatureCount;
    const( VkValidationFeatureEnableEXT )*   pEnabledValidationFeatures;
    uint32_t                                 disabledValidationFeatureCount;
    const( VkValidationFeatureDisableEXT )*  pDisabledValidationFeatures;
}


// - VK_NV_cooperative_matrix -
enum VK_NV_cooperative_matrix = 1;

enum VK_NV_COOPERATIVE_MATRIX_SPEC_VERSION = 1;
enum VK_NV_COOPERATIVE_MATRIX_EXTENSION_NAME = "VK_NV_cooperative_matrix";

enum VkComponentTypeNV {
    VK_COMPONENT_TYPE_FLOAT16_NV         = 0,
    VK_COMPONENT_TYPE_FLOAT32_NV         = 1,
    VK_COMPONENT_TYPE_FLOAT64_NV         = 2,
    VK_COMPONENT_TYPE_SINT8_NV           = 3,
    VK_COMPONENT_TYPE_SINT16_NV          = 4,
    VK_COMPONENT_TYPE_SINT32_NV          = 5,
    VK_COMPONENT_TYPE_SINT64_NV          = 6,
    VK_COMPONENT_TYPE_UINT8_NV           = 7,
    VK_COMPONENT_TYPE_UINT16_NV          = 8,
    VK_COMPONENT_TYPE_UINT32_NV          = 9,
    VK_COMPONENT_TYPE_UINT64_NV          = 10,
    VK_COMPONENT_TYPE_BEGIN_RANGE_NV     = VK_COMPONENT_TYPE_FLOAT16_NV,
    VK_COMPONENT_TYPE_END_RANGE_NV       = VK_COMPONENT_TYPE_UINT64_NV,
    VK_COMPONENT_TYPE_RANGE_SIZE_NV      = VK_COMPONENT_TYPE_UINT64_NV - VK_COMPONENT_TYPE_FLOAT16_NV + 1,
    VK_COMPONENT_TYPE_MAX_ENUM_NV        = 0x7FFFFFFF
}

enum VK_COMPONENT_TYPE_FLOAT16_NV        = VkComponentTypeNV.VK_COMPONENT_TYPE_FLOAT16_NV;
enum VK_COMPONENT_TYPE_FLOAT32_NV        = VkComponentTypeNV.VK_COMPONENT_TYPE_FLOAT32_NV;
enum VK_COMPONENT_TYPE_FLOAT64_NV        = VkComponentTypeNV.VK_COMPONENT_TYPE_FLOAT64_NV;
enum VK_COMPONENT_TYPE_SINT8_NV          = VkComponentTypeNV.VK_COMPONENT_TYPE_SINT8_NV;
enum VK_COMPONENT_TYPE_SINT16_NV         = VkComponentTypeNV.VK_COMPONENT_TYPE_SINT16_NV;
enum VK_COMPONENT_TYPE_SINT32_NV         = VkComponentTypeNV.VK_COMPONENT_TYPE_SINT32_NV;
enum VK_COMPONENT_TYPE_SINT64_NV         = VkComponentTypeNV.VK_COMPONENT_TYPE_SINT64_NV;
enum VK_COMPONENT_TYPE_UINT8_NV          = VkComponentTypeNV.VK_COMPONENT_TYPE_UINT8_NV;
enum VK_COMPONENT_TYPE_UINT16_NV         = VkComponentTypeNV.VK_COMPONENT_TYPE_UINT16_NV;
enum VK_COMPONENT_TYPE_UINT32_NV         = VkComponentTypeNV.VK_COMPONENT_TYPE_UINT32_NV;
enum VK_COMPONENT_TYPE_UINT64_NV         = VkComponentTypeNV.VK_COMPONENT_TYPE_UINT64_NV;
enum VK_COMPONENT_TYPE_BEGIN_RANGE_NV    = VkComponentTypeNV.VK_COMPONENT_TYPE_BEGIN_RANGE_NV;
enum VK_COMPONENT_TYPE_END_RANGE_NV      = VkComponentTypeNV.VK_COMPONENT_TYPE_END_RANGE_NV;
enum VK_COMPONENT_TYPE_RANGE_SIZE_NV     = VkComponentTypeNV.VK_COMPONENT_TYPE_RANGE_SIZE_NV;
enum VK_COMPONENT_TYPE_MAX_ENUM_NV       = VkComponentTypeNV.VK_COMPONENT_TYPE_MAX_ENUM_NV;

enum VkScopeNV {
    VK_SCOPE_DEVICE_NV           = 1,
    VK_SCOPE_WORKGROUP_NV        = 2,
    VK_SCOPE_SUBGROUP_NV         = 3,
    VK_SCOPE_QUEUE_FAMILY_NV     = 5,
    VK_SCOPE_BEGIN_RANGE_NV      = VK_SCOPE_DEVICE_NV,
    VK_SCOPE_END_RANGE_NV        = VK_SCOPE_QUEUE_FAMILY_NV,
    VK_SCOPE_RANGE_SIZE_NV       = VK_SCOPE_QUEUE_FAMILY_NV - VK_SCOPE_DEVICE_NV + 1,
    VK_SCOPE_MAX_ENUM_NV         = 0x7FFFFFFF
}

enum VK_SCOPE_DEVICE_NV          = VkScopeNV.VK_SCOPE_DEVICE_NV;
enum VK_SCOPE_WORKGROUP_NV       = VkScopeNV.VK_SCOPE_WORKGROUP_NV;
enum VK_SCOPE_SUBGROUP_NV        = VkScopeNV.VK_SCOPE_SUBGROUP_NV;
enum VK_SCOPE_QUEUE_FAMILY_NV    = VkScopeNV.VK_SCOPE_QUEUE_FAMILY_NV;
enum VK_SCOPE_BEGIN_RANGE_NV     = VkScopeNV.VK_SCOPE_BEGIN_RANGE_NV;
enum VK_SCOPE_END_RANGE_NV       = VkScopeNV.VK_SCOPE_END_RANGE_NV;
enum VK_SCOPE_RANGE_SIZE_NV      = VkScopeNV.VK_SCOPE_RANGE_SIZE_NV;
enum VK_SCOPE_MAX_ENUM_NV        = VkScopeNV.VK_SCOPE_MAX_ENUM_NV;

struct VkCooperativeMatrixPropertiesNV {
    VkStructureType    sType = VK_STRUCTURE_TYPE_COOPERATIVE_MATRIX_PROPERTIES_NV;
    void*              pNext;
    uint32_t           MSize;
    uint32_t           NSize;
    uint32_t           KSize;
    VkComponentTypeNV  AType;
    VkComponentTypeNV  BType;
    VkComponentTypeNV  CType;
    VkComponentTypeNV  DType;
    VkScopeNV          _scope;
}

struct VkPhysicalDeviceCooperativeMatrixFeaturesNV {
    VkStructureType  sType = VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_COOPERATIVE_MATRIX_FEATURES_NV;
    void*            pNext;
    VkBool32         cooperativeMatrix;
    VkBool32         cooperativeMatrixRobustBufferAccess;
}

struct VkPhysicalDeviceCooperativeMatrixPropertiesNV {
    VkStructureType     sType = VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_COOPERATIVE_MATRIX_PROPERTIES_NV;
    void*               pNext;
    VkShaderStageFlags  cooperativeMatrixSupportedStages;
}


// - VK_NV_coverage_reduction_mode -
enum VK_NV_coverage_reduction_mode = 1;

enum VK_NV_COVERAGE_REDUCTION_MODE_SPEC_VERSION = 1;
enum VK_NV_COVERAGE_REDUCTION_MODE_EXTENSION_NAME = "VK_NV_coverage_reduction_mode";

enum VkCoverageReductionModeNV {
    VK_COVERAGE_REDUCTION_MODE_MERGE_NV          = 0,
    VK_COVERAGE_REDUCTION_MODE_TRUNCATE_NV       = 1,
    VK_COVERAGE_REDUCTION_MODE_BEGIN_RANGE_NV    = VK_COVERAGE_REDUCTION_MODE_MERGE_NV,
    VK_COVERAGE_REDUCTION_MODE_END_RANGE_NV      = VK_COVERAGE_REDUCTION_MODE_TRUNCATE_NV,
    VK_COVERAGE_REDUCTION_MODE_RANGE_SIZE_NV     = VK_COVERAGE_REDUCTION_MODE_TRUNCATE_NV - VK_COVERAGE_REDUCTION_MODE_MERGE_NV + 1,
    VK_COVERAGE_REDUCTION_MODE_MAX_ENUM_NV       = 0x7FFFFFFF
}

enum VK_COVERAGE_REDUCTION_MODE_MERGE_NV         = VkCoverageReductionModeNV.VK_COVERAGE_REDUCTION_MODE_MERGE_NV;
enum VK_COVERAGE_REDUCTION_MODE_TRUNCATE_NV      = VkCoverageReductionModeNV.VK_COVERAGE_REDUCTION_MODE_TRUNCATE_NV;
enum VK_COVERAGE_REDUCTION_MODE_BEGIN_RANGE_NV   = VkCoverageReductionModeNV.VK_COVERAGE_REDUCTION_MODE_BEGIN_RANGE_NV;
enum VK_COVERAGE_REDUCTION_MODE_END_RANGE_NV     = VkCoverageReductionModeNV.VK_COVERAGE_REDUCTION_MODE_END_RANGE_NV;
enum VK_COVERAGE_REDUCTION_MODE_RANGE_SIZE_NV    = VkCoverageReductionModeNV.VK_COVERAGE_REDUCTION_MODE_RANGE_SIZE_NV;
enum VK_COVERAGE_REDUCTION_MODE_MAX_ENUM_NV      = VkCoverageReductionModeNV.VK_COVERAGE_REDUCTION_MODE_MAX_ENUM_NV;

alias VkPipelineCoverageReductionStateCreateFlagsNV = VkFlags;

struct VkPhysicalDeviceCoverageReductionModeFeaturesNV {
    VkStructureType  sType = VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_COVERAGE_REDUCTION_MODE_FEATURES_NV;
    void*            pNext;
    VkBool32         coverageReductionMode;
}

struct VkPipelineCoverageReductionStateCreateInfoNV {
    VkStructureType                                sType = VK_STRUCTURE_TYPE_PIPELINE_COVERAGE_REDUCTION_STATE_CREATE_INFO_NV;
    const( void )*                                 pNext;
    VkPipelineCoverageReductionStateCreateFlagsNV  flags;
    VkCoverageReductionModeNV                      coverageReductionMode;
}

struct VkFramebufferMixedSamplesCombinationNV {
    VkStructureType            sType = VK_STRUCTURE_TYPE_FRAMEBUFFER_MIXED_SAMPLES_COMBINATION_NV;
    void*                      pNext;
    VkCoverageReductionModeNV  coverageReductionMode;
    VkSampleCountFlagBits      rasterizationSamples;
    VkSampleCountFlags         depthStencilSamples;
    VkSampleCountFlags         colorSamples;
}


// - VK_EXT_fragment_shader_interlock -
enum VK_EXT_fragment_shader_interlock = 1;

enum VK_EXT_FRAGMENT_SHADER_INTERLOCK_SPEC_VERSION = 1;
enum VK_EXT_FRAGMENT_SHADER_INTERLOCK_EXTENSION_NAME = "VK_EXT_fragment_shader_interlock";

struct VkPhysicalDeviceFragmentShaderInterlockFeaturesEXT {
    VkStructureType  sType = VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_FRAGMENT_SHADER_INTERLOCK_FEATURES_EXT;
    void*            pNext;
    VkBool32         fragmentShaderSampleInterlock;
    VkBool32         fragmentShaderPixelInterlock;
    VkBool32         fragmentShaderShadingRateInterlock;
}


// - VK_EXT_ycbcr_image_arrays -
enum VK_EXT_ycbcr_image_arrays = 1;

enum VK_EXT_YCBCR_IMAGE_ARRAYS_SPEC_VERSION = 1;
enum VK_EXT_YCBCR_IMAGE_ARRAYS_EXTENSION_NAME = "VK_EXT_ycbcr_image_arrays";

struct VkPhysicalDeviceYcbcrImageArraysFeaturesEXT {
    VkStructureType  sType = VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_YCBCR_IMAGE_ARRAYS_FEATURES_EXT;
    void*            pNext;
    VkBool32         ycbcrImageArrays;
}


// - VK_EXT_headless_surface -
enum VK_EXT_headless_surface = 1;

enum VK_EXT_HEADLESS_SURFACE_SPEC_VERSION = 0;
enum VK_EXT_HEADLESS_SURFACE_EXTENSION_NAME = "VK_EXT_headless_surface";

alias VkHeadlessSurfaceCreateFlagsEXT = VkFlags;

struct VkHeadlessSurfaceCreateInfoEXT {
    VkStructureType                  sType = VK_STRUCTURE_TYPE_HEADLESS_SURFACE_CREATE_INFO_EXT;
    const( void )*                   pNext;
    VkHeadlessSurfaceCreateFlagsEXT  flags;
}


// - VK_EXT_host_query_reset -
enum VK_EXT_host_query_reset = 1;

enum VK_EXT_HOST_QUERY_RESET_SPEC_VERSION = 1;
enum VK_EXT_HOST_QUERY_RESET_EXTENSION_NAME = "VK_EXT_host_query_reset";

struct VkPhysicalDeviceHostQueryResetFeaturesEXT {
    VkStructureType  sType = VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_HOST_QUERY_RESET_FEATURES_EXT;
    void*            pNext;
    VkBool32         hostQueryReset;
}


