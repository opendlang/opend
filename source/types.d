
module dvulkan.types;

alias uint8_t = ubyte;
alias uint16_t = ushort;
alias uint32_t = uint;
alias uint64_t = ulong;
alias int8_t = byte;
alias int16_t = short;
alias int32_t = int;
alias int64_t = long;

uint VK_MAKE_VERSION(uint major, uint minor, uint patch) {
	return (major << 22) | (minor << 12) | (patch);
}
uint VK_VERSION_MAJOR(uint ver) {
	return ver >> 22;
}
uint VK_VERSION_MINOR(uint ver) {
	return (ver >> 12) & 0x3ff;
}
uint VK_VERSION_PATCH(uint ver) {
	return ver & 0xfff;
}

enum VK_NULL_HANDLE = 0;

enum VK_DEFINE_HANDLE(string name) = "struct "~name~"_handle; alias "~name~" = "~name~"_handle*;";

version(X86_64) {
	alias VK_DEFINE_NON_DISPATCHABLE_HANDLE(string name) = VK_DEFINE_HANDLE!name;
} else {
	enum VK_DEFINE_NON_DISPATCHABLE_HANDLE(string name) = "alias "~name~" = ulong;";
}

enum VkPipelineCacheHeaderVersion {
	VK_PIPELINE_CACHE_HEADER_VERSION_ONE = 1,
	VK_PIPELINE_CACHE_HEADER_VERSION_BEGIN_RANGE = VK_PIPELINE_CACHE_HEADER_VERSION_ONE,
	VK_PIPELINE_CACHE_HEADER_VERSION_END_RANGE = VK_PIPELINE_CACHE_HEADER_VERSION_ONE,
	VK_PIPELINE_CACHE_HEADER_VERSION_RANGE_SIZE = (VK_PIPELINE_CACHE_HEADER_VERSION_ONE - VK_PIPELINE_CACHE_HEADER_VERSION_ONE + 1),
	VK_PIPELINE_CACHE_HEADER_VERSION_MAX_ENUM = 0x7FFFFFFF,
}
enum VK_LOD_CLAMP_NONE = 1000.0f;
enum VK_REMAINING_MIP_LEVELS = (~0U);
enum VK_REMAINING_ARRAY_LAYERS = (~0U);
enum VK_WHOLE_SIZE = (~0UL);
enum VK_ATTACHMENT_UNUSED = (~0U);
enum VK_TRUE = 1;
enum VK_FALSE = 0;
enum VK_QUEUE_FAMILY_IGNORED = (~0U);
enum VK_SUBPASS_EXTERNAL = (~0U);
enum VkResult {
	VK_SUCCESS = 0,
	VK_NOT_READY = 1,
	VK_TIMEOUT = 2,
	VK_EVENT_SET = 3,
	VK_EVENT_RESET = 4,
	VK_INCOMPLETE = 5,
	VK_ERROR_OUT_OF_HOST_MEMORY = -1,
	VK_ERROR_OUT_OF_DEVICE_MEMORY = -2,
	VK_ERROR_INITIALIZATION_FAILED = -3,
	VK_ERROR_DEVICE_LOST = -4,
	VK_ERROR_MEMORY_MAP_FAILED = -5,
	VK_ERROR_LAYER_NOT_PRESENT = -6,
	VK_ERROR_EXTENSION_NOT_PRESENT = -7,
	VK_ERROR_FEATURE_NOT_PRESENT = -8,
	VK_ERROR_INCOMPATIBLE_DRIVER = -9,
	VK_ERROR_TOO_MANY_OBJECTS = -10,
	VK_ERROR_FORMAT_NOT_SUPPORTED = -11,
	VK_ERROR_SURFACE_LOST_KHR = -1000000000,
	VK_ERROR_NATIVE_WINDOW_IN_USE_KHR = -1000000001,
	VK_SUBOPTIMAL_KHR = 1000001003,
	VK_ERROR_OUT_OF_DATE_KHR = -1000001004,
	VK_ERROR_INCOMPATIBLE_DISPLAY_KHR = -1000003001,
	VK_ERROR_VALIDATION_FAILED_EXT = -1000011001,
	VK_ERROR_INVALID_SHADER_NV = -1000012000,
	VK_NV_EXTENSION_1_ERROR = -1000013000,
	VK_RESULT_BEGIN_RANGE = VK_NV_EXTENSION_1_ERROR,
	VK_RESULT_END_RANGE = VK_SUBOPTIMAL_KHR,
	VK_RESULT_RANGE_SIZE = (VK_SUBOPTIMAL_KHR - VK_NV_EXTENSION_1_ERROR + 1),
	VK_RESULT_MAX_ENUM = 0x7FFFFFFF,
}
enum VkStructureType {
	VK_STRUCTURE_TYPE_APPLICATION_INFO = 0,
	VK_STRUCTURE_TYPE_INSTANCE_CREATE_INFO = 1,
	VK_STRUCTURE_TYPE_DEVICE_QUEUE_CREATE_INFO = 2,
	VK_STRUCTURE_TYPE_DEVICE_CREATE_INFO = 3,
	VK_STRUCTURE_TYPE_SUBMIT_INFO = 4,
	VK_STRUCTURE_TYPE_MEMORY_ALLOCATE_INFO = 5,
	VK_STRUCTURE_TYPE_MAPPED_MEMORY_RANGE = 6,
	VK_STRUCTURE_TYPE_BIND_SPARSE_INFO = 7,
	VK_STRUCTURE_TYPE_FENCE_CREATE_INFO = 8,
	VK_STRUCTURE_TYPE_SEMAPHORE_CREATE_INFO = 9,
	VK_STRUCTURE_TYPE_EVENT_CREATE_INFO = 10,
	VK_STRUCTURE_TYPE_QUERY_POOL_CREATE_INFO = 11,
	VK_STRUCTURE_TYPE_BUFFER_CREATE_INFO = 12,
	VK_STRUCTURE_TYPE_BUFFER_VIEW_CREATE_INFO = 13,
	VK_STRUCTURE_TYPE_IMAGE_CREATE_INFO = 14,
	VK_STRUCTURE_TYPE_IMAGE_VIEW_CREATE_INFO = 15,
	VK_STRUCTURE_TYPE_SHADER_MODULE_CREATE_INFO = 16,
	VK_STRUCTURE_TYPE_PIPELINE_CACHE_CREATE_INFO = 17,
	VK_STRUCTURE_TYPE_PIPELINE_SHADER_STAGE_CREATE_INFO = 18,
	VK_STRUCTURE_TYPE_PIPELINE_VERTEX_INPUT_STATE_CREATE_INFO = 19,
	VK_STRUCTURE_TYPE_PIPELINE_INPUT_ASSEMBLY_STATE_CREATE_INFO = 20,
	VK_STRUCTURE_TYPE_PIPELINE_TESSELLATION_STATE_CREATE_INFO = 21,
	VK_STRUCTURE_TYPE_PIPELINE_VIEWPORT_STATE_CREATE_INFO = 22,
	VK_STRUCTURE_TYPE_PIPELINE_RASTERIZATION_STATE_CREATE_INFO = 23,
	VK_STRUCTURE_TYPE_PIPELINE_MULTISAMPLE_STATE_CREATE_INFO = 24,
	VK_STRUCTURE_TYPE_PIPELINE_DEPTH_STENCIL_STATE_CREATE_INFO = 25,
	VK_STRUCTURE_TYPE_PIPELINE_COLOR_BLEND_STATE_CREATE_INFO = 26,
	VK_STRUCTURE_TYPE_PIPELINE_DYNAMIC_STATE_CREATE_INFO = 27,
	VK_STRUCTURE_TYPE_GRAPHICS_PIPELINE_CREATE_INFO = 28,
	VK_STRUCTURE_TYPE_COMPUTE_PIPELINE_CREATE_INFO = 29,
	VK_STRUCTURE_TYPE_PIPELINE_LAYOUT_CREATE_INFO = 30,
	VK_STRUCTURE_TYPE_SAMPLER_CREATE_INFO = 31,
	VK_STRUCTURE_TYPE_DESCRIPTOR_SET_LAYOUT_CREATE_INFO = 32,
	VK_STRUCTURE_TYPE_DESCRIPTOR_POOL_CREATE_INFO = 33,
	VK_STRUCTURE_TYPE_DESCRIPTOR_SET_ALLOCATE_INFO = 34,
	VK_STRUCTURE_TYPE_WRITE_DESCRIPTOR_SET = 35,
	VK_STRUCTURE_TYPE_COPY_DESCRIPTOR_SET = 36,
	VK_STRUCTURE_TYPE_FRAMEBUFFER_CREATE_INFO = 37,
	VK_STRUCTURE_TYPE_RENDER_PASS_CREATE_INFO = 38,
	VK_STRUCTURE_TYPE_COMMAND_POOL_CREATE_INFO = 39,
	VK_STRUCTURE_TYPE_COMMAND_BUFFER_ALLOCATE_INFO = 40,
	VK_STRUCTURE_TYPE_COMMAND_BUFFER_INHERITANCE_INFO = 41,
	VK_STRUCTURE_TYPE_COMMAND_BUFFER_BEGIN_INFO = 42,
	VK_STRUCTURE_TYPE_RENDER_PASS_BEGIN_INFO = 43,
	VK_STRUCTURE_TYPE_BUFFER_MEMORY_BARRIER = 44,
	VK_STRUCTURE_TYPE_IMAGE_MEMORY_BARRIER = 45,
	VK_STRUCTURE_TYPE_MEMORY_BARRIER = 46,
	VK_STRUCTURE_TYPE_LOADER_INSTANCE_CREATE_INFO = 47,
	VK_STRUCTURE_TYPE_LOADER_DEVICE_CREATE_INFO = 48,
	VK_STRUCTURE_TYPE_SWAPCHAIN_CREATE_INFO_KHR = 1000001000,
	VK_STRUCTURE_TYPE_PRESENT_INFO_KHR = 1000001001,
	VK_STRUCTURE_TYPE_DISPLAY_MODE_CREATE_INFO_KHR = 1000002000,
	VK_STRUCTURE_TYPE_DISPLAY_SURFACE_CREATE_INFO_KHR = 1000002001,
	VK_STRUCTURE_TYPE_DISPLAY_PRESENT_INFO_KHR = 1000003000,
	VK_STRUCTURE_TYPE_XLIB_SURFACE_CREATE_INFO_KHR = 1000004000,
	VK_STRUCTURE_TYPE_XCB_SURFACE_CREATE_INFO_KHR = 1000005000,
	VK_STRUCTURE_TYPE_WAYLAND_SURFACE_CREATE_INFO_KHR = 1000006000,
	VK_STRUCTURE_TYPE_MIR_SURFACE_CREATE_INFO_KHR = 1000007000,
	VK_STRUCTURE_TYPE_ANDROID_SURFACE_CREATE_INFO_KHR = 1000008000,
	VK_STRUCTURE_TYPE_WIN32_SURFACE_CREATE_INFO_KHR = 1000009000,
	VK_STRUCTURE_TYPE_DEBUG_REPORT_CALLBACK_CREATE_INFO_EXT = 1000011000,
	VK_STRUCTURE_TYPE_BEGIN_RANGE = VK_STRUCTURE_TYPE_APPLICATION_INFO,
	VK_STRUCTURE_TYPE_END_RANGE = VK_STRUCTURE_TYPE_DEBUG_REPORT_CALLBACK_CREATE_INFO_EXT,
	VK_STRUCTURE_TYPE_RANGE_SIZE = (VK_STRUCTURE_TYPE_DEBUG_REPORT_CALLBACK_CREATE_INFO_EXT - VK_STRUCTURE_TYPE_APPLICATION_INFO + 1),
	VK_STRUCTURE_TYPE_MAX_ENUM = 0x7FFFFFFF,
}
alias VkFlags = uint32_t;
alias VkInstanceCreateFlags = VkFlags;
struct VkApplicationInfo {
	VkStructureType sType;
	const(void)* pNext;
	const(char)* pApplicationName;
	uint32_t applicationVersion;
	const(char)* pEngineName;
	uint32_t engineVersion;
	uint32_t apiVersion;
}
struct VkInstanceCreateInfo {
	VkStructureType sType;
	const(void)* pNext;
	VkInstanceCreateFlags flags;
	const(VkApplicationInfo)* pApplicationInfo;
	uint32_t enabledLayerCount;
	const(char*)* ppEnabledLayerNames;
	uint32_t enabledExtensionCount;
	const(char*)* ppEnabledExtensionNames;
}
enum VkSystemAllocationScope {
	VK_SYSTEM_ALLOCATION_SCOPE_COMMAND = 0,
	VK_SYSTEM_ALLOCATION_SCOPE_OBJECT = 1,
	VK_SYSTEM_ALLOCATION_SCOPE_CACHE = 2,
	VK_SYSTEM_ALLOCATION_SCOPE_DEVICE = 3,
	VK_SYSTEM_ALLOCATION_SCOPE_INSTANCE = 4,
	VK_SYSTEM_ALLOCATION_SCOPE_BEGIN_RANGE = VK_SYSTEM_ALLOCATION_SCOPE_COMMAND,
	VK_SYSTEM_ALLOCATION_SCOPE_END_RANGE = VK_SYSTEM_ALLOCATION_SCOPE_INSTANCE,
	VK_SYSTEM_ALLOCATION_SCOPE_RANGE_SIZE = (VK_SYSTEM_ALLOCATION_SCOPE_INSTANCE - VK_SYSTEM_ALLOCATION_SCOPE_COMMAND + 1),
	VK_SYSTEM_ALLOCATION_SCOPE_MAX_ENUM = 0x7FFFFFFF,
}
alias PFN_vkAllocationFunction = void* function(
    void*                                       pUserData,
    size_t                                      size,
    size_t                                      alignment,
    VkSystemAllocationScope                     allocationScope);
alias PFN_vkReallocationFunction = void* function(
    void*                                       pUserData,
    void*                                       pOriginal,
    size_t                                      size,
    size_t                                      alignment,
    VkSystemAllocationScope                     allocationScope);
alias PFN_vkFreeFunction = void function(
    void*                                       pUserData,
    void*                                       pMemory);
enum VkInternalAllocationType {
	VK_INTERNAL_ALLOCATION_TYPE_EXECUTABLE = 0,
	VK_INTERNAL_ALLOCATION_TYPE_BEGIN_RANGE = VK_INTERNAL_ALLOCATION_TYPE_EXECUTABLE,
	VK_INTERNAL_ALLOCATION_TYPE_END_RANGE = VK_INTERNAL_ALLOCATION_TYPE_EXECUTABLE,
	VK_INTERNAL_ALLOCATION_TYPE_RANGE_SIZE = (VK_INTERNAL_ALLOCATION_TYPE_EXECUTABLE - VK_INTERNAL_ALLOCATION_TYPE_EXECUTABLE + 1),
	VK_INTERNAL_ALLOCATION_TYPE_MAX_ENUM = 0x7FFFFFFF,
}
alias PFN_vkInternalAllocationNotification = void function(
    void*                                       pUserData,
    size_t                                      size,
    VkInternalAllocationType                    allocationType,
    VkSystemAllocationScope                     allocationScope);
alias PFN_vkInternalFreeNotification = void function(
    void*                                       pUserData,
    size_t                                      size,
    VkInternalAllocationType                    allocationType,
    VkSystemAllocationScope                     allocationScope);
struct VkAllocationCallbacks {
	void* pUserData;
	PFN_vkAllocationFunction pfnAllocation;
	PFN_vkReallocationFunction pfnReallocation;
	PFN_vkFreeFunction pfnFree;
	PFN_vkInternalAllocationNotification pfnInternalAllocation;
	PFN_vkInternalFreeNotification pfnInternalFree;
}
mixin(VK_DEFINE_HANDLE!q{VkInstance});
mixin(VK_DEFINE_HANDLE!q{VkPhysicalDevice});
alias VkBool32 = uint32_t;
struct VkPhysicalDeviceFeatures {
	VkBool32 robustBufferAccess;
	VkBool32 fullDrawIndexUint32;
	VkBool32 imageCubeArray;
	VkBool32 independentBlend;
	VkBool32 geometryShader;
	VkBool32 tessellationShader;
	VkBool32 sampleRateShading;
	VkBool32 dualSrcBlend;
	VkBool32 logicOp;
	VkBool32 multiDrawIndirect;
	VkBool32 drawIndirectFirstInstance;
	VkBool32 depthClamp;
	VkBool32 depthBiasClamp;
	VkBool32 fillModeNonSolid;
	VkBool32 depthBounds;
	VkBool32 wideLines;
	VkBool32 largePoints;
	VkBool32 alphaToOne;
	VkBool32 multiViewport;
	VkBool32 samplerAnisotropy;
	VkBool32 textureCompressionETC2;
	VkBool32 textureCompressionASTC_LDR;
	VkBool32 textureCompressionBC;
	VkBool32 occlusionQueryPrecise;
	VkBool32 pipelineStatisticsQuery;
	VkBool32 vertexPipelineStoresAndAtomics;
	VkBool32 fragmentStoresAndAtomics;
	VkBool32 shaderTessellationAndGeometryPointSize;
	VkBool32 shaderImageGatherExtended;
	VkBool32 shaderStorageImageExtendedFormats;
	VkBool32 shaderStorageImageMultisample;
	VkBool32 shaderStorageImageReadWithoutFormat;
	VkBool32 shaderStorageImageWriteWithoutFormat;
	VkBool32 shaderUniformBufferArrayDynamicIndexing;
	VkBool32 shaderSampledImageArrayDynamicIndexing;
	VkBool32 shaderStorageBufferArrayDynamicIndexing;
	VkBool32 shaderStorageImageArrayDynamicIndexing;
	VkBool32 shaderClipDistance;
	VkBool32 shaderCullDistance;
	VkBool32 shaderFloat64;
	VkBool32 shaderInt64;
	VkBool32 shaderInt16;
	VkBool32 shaderResourceResidency;
	VkBool32 shaderResourceMinLod;
	VkBool32 sparseBinding;
	VkBool32 sparseResidencyBuffer;
	VkBool32 sparseResidencyImage2D;
	VkBool32 sparseResidencyImage3D;
	VkBool32 sparseResidency2Samples;
	VkBool32 sparseResidency4Samples;
	VkBool32 sparseResidency8Samples;
	VkBool32 sparseResidency16Samples;
	VkBool32 sparseResidencyAliased;
	VkBool32 variableMultisampleRate;
	VkBool32 inheritedQueries;
}
enum VkFormat {
	VK_FORMAT_UNDEFINED = 0,
	VK_FORMAT_R4G4_UNORM_PACK8 = 1,
	VK_FORMAT_R4G4B4A4_UNORM_PACK16 = 2,
	VK_FORMAT_B4G4R4A4_UNORM_PACK16 = 3,
	VK_FORMAT_R5G6B5_UNORM_PACK16 = 4,
	VK_FORMAT_B5G6R5_UNORM_PACK16 = 5,
	VK_FORMAT_R5G5B5A1_UNORM_PACK16 = 6,
	VK_FORMAT_B5G5R5A1_UNORM_PACK16 = 7,
	VK_FORMAT_A1R5G5B5_UNORM_PACK16 = 8,
	VK_FORMAT_R8_UNORM = 9,
	VK_FORMAT_R8_SNORM = 10,
	VK_FORMAT_R8_USCALED = 11,
	VK_FORMAT_R8_SSCALED = 12,
	VK_FORMAT_R8_UINT = 13,
	VK_FORMAT_R8_SINT = 14,
	VK_FORMAT_R8_SRGB = 15,
	VK_FORMAT_R8G8_UNORM = 16,
	VK_FORMAT_R8G8_SNORM = 17,
	VK_FORMAT_R8G8_USCALED = 18,
	VK_FORMAT_R8G8_SSCALED = 19,
	VK_FORMAT_R8G8_UINT = 20,
	VK_FORMAT_R8G8_SINT = 21,
	VK_FORMAT_R8G8_SRGB = 22,
	VK_FORMAT_R8G8B8_UNORM = 23,
	VK_FORMAT_R8G8B8_SNORM = 24,
	VK_FORMAT_R8G8B8_USCALED = 25,
	VK_FORMAT_R8G8B8_SSCALED = 26,
	VK_FORMAT_R8G8B8_UINT = 27,
	VK_FORMAT_R8G8B8_SINT = 28,
	VK_FORMAT_R8G8B8_SRGB = 29,
	VK_FORMAT_B8G8R8_UNORM = 30,
	VK_FORMAT_B8G8R8_SNORM = 31,
	VK_FORMAT_B8G8R8_USCALED = 32,
	VK_FORMAT_B8G8R8_SSCALED = 33,
	VK_FORMAT_B8G8R8_UINT = 34,
	VK_FORMAT_B8G8R8_SINT = 35,
	VK_FORMAT_B8G8R8_SRGB = 36,
	VK_FORMAT_R8G8B8A8_UNORM = 37,
	VK_FORMAT_R8G8B8A8_SNORM = 38,
	VK_FORMAT_R8G8B8A8_USCALED = 39,
	VK_FORMAT_R8G8B8A8_SSCALED = 40,
	VK_FORMAT_R8G8B8A8_UINT = 41,
	VK_FORMAT_R8G8B8A8_SINT = 42,
	VK_FORMAT_R8G8B8A8_SRGB = 43,
	VK_FORMAT_B8G8R8A8_UNORM = 44,
	VK_FORMAT_B8G8R8A8_SNORM = 45,
	VK_FORMAT_B8G8R8A8_USCALED = 46,
	VK_FORMAT_B8G8R8A8_SSCALED = 47,
	VK_FORMAT_B8G8R8A8_UINT = 48,
	VK_FORMAT_B8G8R8A8_SINT = 49,
	VK_FORMAT_B8G8R8A8_SRGB = 50,
	VK_FORMAT_A8B8G8R8_UNORM_PACK32 = 51,
	VK_FORMAT_A8B8G8R8_SNORM_PACK32 = 52,
	VK_FORMAT_A8B8G8R8_USCALED_PACK32 = 53,
	VK_FORMAT_A8B8G8R8_SSCALED_PACK32 = 54,
	VK_FORMAT_A8B8G8R8_UINT_PACK32 = 55,
	VK_FORMAT_A8B8G8R8_SINT_PACK32 = 56,
	VK_FORMAT_A8B8G8R8_SRGB_PACK32 = 57,
	VK_FORMAT_A2R10G10B10_UNORM_PACK32 = 58,
	VK_FORMAT_A2R10G10B10_SNORM_PACK32 = 59,
	VK_FORMAT_A2R10G10B10_USCALED_PACK32 = 60,
	VK_FORMAT_A2R10G10B10_SSCALED_PACK32 = 61,
	VK_FORMAT_A2R10G10B10_UINT_PACK32 = 62,
	VK_FORMAT_A2R10G10B10_SINT_PACK32 = 63,
	VK_FORMAT_A2B10G10R10_UNORM_PACK32 = 64,
	VK_FORMAT_A2B10G10R10_SNORM_PACK32 = 65,
	VK_FORMAT_A2B10G10R10_USCALED_PACK32 = 66,
	VK_FORMAT_A2B10G10R10_SSCALED_PACK32 = 67,
	VK_FORMAT_A2B10G10R10_UINT_PACK32 = 68,
	VK_FORMAT_A2B10G10R10_SINT_PACK32 = 69,
	VK_FORMAT_R16_UNORM = 70,
	VK_FORMAT_R16_SNORM = 71,
	VK_FORMAT_R16_USCALED = 72,
	VK_FORMAT_R16_SSCALED = 73,
	VK_FORMAT_R16_UINT = 74,
	VK_FORMAT_R16_SINT = 75,
	VK_FORMAT_R16_SFLOAT = 76,
	VK_FORMAT_R16G16_UNORM = 77,
	VK_FORMAT_R16G16_SNORM = 78,
	VK_FORMAT_R16G16_USCALED = 79,
	VK_FORMAT_R16G16_SSCALED = 80,
	VK_FORMAT_R16G16_UINT = 81,
	VK_FORMAT_R16G16_SINT = 82,
	VK_FORMAT_R16G16_SFLOAT = 83,
	VK_FORMAT_R16G16B16_UNORM = 84,
	VK_FORMAT_R16G16B16_SNORM = 85,
	VK_FORMAT_R16G16B16_USCALED = 86,
	VK_FORMAT_R16G16B16_SSCALED = 87,
	VK_FORMAT_R16G16B16_UINT = 88,
	VK_FORMAT_R16G16B16_SINT = 89,
	VK_FORMAT_R16G16B16_SFLOAT = 90,
	VK_FORMAT_R16G16B16A16_UNORM = 91,
	VK_FORMAT_R16G16B16A16_SNORM = 92,
	VK_FORMAT_R16G16B16A16_USCALED = 93,
	VK_FORMAT_R16G16B16A16_SSCALED = 94,
	VK_FORMAT_R16G16B16A16_UINT = 95,
	VK_FORMAT_R16G16B16A16_SINT = 96,
	VK_FORMAT_R16G16B16A16_SFLOAT = 97,
	VK_FORMAT_R32_UINT = 98,
	VK_FORMAT_R32_SINT = 99,
	VK_FORMAT_R32_SFLOAT = 100,
	VK_FORMAT_R32G32_UINT = 101,
	VK_FORMAT_R32G32_SINT = 102,
	VK_FORMAT_R32G32_SFLOAT = 103,
	VK_FORMAT_R32G32B32_UINT = 104,
	VK_FORMAT_R32G32B32_SINT = 105,
	VK_FORMAT_R32G32B32_SFLOAT = 106,
	VK_FORMAT_R32G32B32A32_UINT = 107,
	VK_FORMAT_R32G32B32A32_SINT = 108,
	VK_FORMAT_R32G32B32A32_SFLOAT = 109,
	VK_FORMAT_R64_UINT = 110,
	VK_FORMAT_R64_SINT = 111,
	VK_FORMAT_R64_SFLOAT = 112,
	VK_FORMAT_R64G64_UINT = 113,
	VK_FORMAT_R64G64_SINT = 114,
	VK_FORMAT_R64G64_SFLOAT = 115,
	VK_FORMAT_R64G64B64_UINT = 116,
	VK_FORMAT_R64G64B64_SINT = 117,
	VK_FORMAT_R64G64B64_SFLOAT = 118,
	VK_FORMAT_R64G64B64A64_UINT = 119,
	VK_FORMAT_R64G64B64A64_SINT = 120,
	VK_FORMAT_R64G64B64A64_SFLOAT = 121,
	VK_FORMAT_B10G11R11_UFLOAT_PACK32 = 122,
	VK_FORMAT_E5B9G9R9_UFLOAT_PACK32 = 123,
	VK_FORMAT_D16_UNORM = 124,
	VK_FORMAT_X8_D24_UNORM_PACK32 = 125,
	VK_FORMAT_D32_SFLOAT = 126,
	VK_FORMAT_S8_UINT = 127,
	VK_FORMAT_D16_UNORM_S8_UINT = 128,
	VK_FORMAT_D24_UNORM_S8_UINT = 129,
	VK_FORMAT_D32_SFLOAT_S8_UINT = 130,
	VK_FORMAT_BC1_RGB_UNORM_BLOCK = 131,
	VK_FORMAT_BC1_RGB_SRGB_BLOCK = 132,
	VK_FORMAT_BC1_RGBA_UNORM_BLOCK = 133,
	VK_FORMAT_BC1_RGBA_SRGB_BLOCK = 134,
	VK_FORMAT_BC2_UNORM_BLOCK = 135,
	VK_FORMAT_BC2_SRGB_BLOCK = 136,
	VK_FORMAT_BC3_UNORM_BLOCK = 137,
	VK_FORMAT_BC3_SRGB_BLOCK = 138,
	VK_FORMAT_BC4_UNORM_BLOCK = 139,
	VK_FORMAT_BC4_SNORM_BLOCK = 140,
	VK_FORMAT_BC5_UNORM_BLOCK = 141,
	VK_FORMAT_BC5_SNORM_BLOCK = 142,
	VK_FORMAT_BC6H_UFLOAT_BLOCK = 143,
	VK_FORMAT_BC6H_SFLOAT_BLOCK = 144,
	VK_FORMAT_BC7_UNORM_BLOCK = 145,
	VK_FORMAT_BC7_SRGB_BLOCK = 146,
	VK_FORMAT_ETC2_R8G8B8_UNORM_BLOCK = 147,
	VK_FORMAT_ETC2_R8G8B8_SRGB_BLOCK = 148,
	VK_FORMAT_ETC2_R8G8B8A1_UNORM_BLOCK = 149,
	VK_FORMAT_ETC2_R8G8B8A1_SRGB_BLOCK = 150,
	VK_FORMAT_ETC2_R8G8B8A8_UNORM_BLOCK = 151,
	VK_FORMAT_ETC2_R8G8B8A8_SRGB_BLOCK = 152,
	VK_FORMAT_EAC_R11_UNORM_BLOCK = 153,
	VK_FORMAT_EAC_R11_SNORM_BLOCK = 154,
	VK_FORMAT_EAC_R11G11_UNORM_BLOCK = 155,
	VK_FORMAT_EAC_R11G11_SNORM_BLOCK = 156,
	VK_FORMAT_ASTC_4x4_UNORM_BLOCK = 157,
	VK_FORMAT_ASTC_4x4_SRGB_BLOCK = 158,
	VK_FORMAT_ASTC_5x4_UNORM_BLOCK = 159,
	VK_FORMAT_ASTC_5x4_SRGB_BLOCK = 160,
	VK_FORMAT_ASTC_5x5_UNORM_BLOCK = 161,
	VK_FORMAT_ASTC_5x5_SRGB_BLOCK = 162,
	VK_FORMAT_ASTC_6x5_UNORM_BLOCK = 163,
	VK_FORMAT_ASTC_6x5_SRGB_BLOCK = 164,
	VK_FORMAT_ASTC_6x6_UNORM_BLOCK = 165,
	VK_FORMAT_ASTC_6x6_SRGB_BLOCK = 166,
	VK_FORMAT_ASTC_8x5_UNORM_BLOCK = 167,
	VK_FORMAT_ASTC_8x5_SRGB_BLOCK = 168,
	VK_FORMAT_ASTC_8x6_UNORM_BLOCK = 169,
	VK_FORMAT_ASTC_8x6_SRGB_BLOCK = 170,
	VK_FORMAT_ASTC_8x8_UNORM_BLOCK = 171,
	VK_FORMAT_ASTC_8x8_SRGB_BLOCK = 172,
	VK_FORMAT_ASTC_10x5_UNORM_BLOCK = 173,
	VK_FORMAT_ASTC_10x5_SRGB_BLOCK = 174,
	VK_FORMAT_ASTC_10x6_UNORM_BLOCK = 175,
	VK_FORMAT_ASTC_10x6_SRGB_BLOCK = 176,
	VK_FORMAT_ASTC_10x8_UNORM_BLOCK = 177,
	VK_FORMAT_ASTC_10x8_SRGB_BLOCK = 178,
	VK_FORMAT_ASTC_10x10_UNORM_BLOCK = 179,
	VK_FORMAT_ASTC_10x10_SRGB_BLOCK = 180,
	VK_FORMAT_ASTC_12x10_UNORM_BLOCK = 181,
	VK_FORMAT_ASTC_12x10_SRGB_BLOCK = 182,
	VK_FORMAT_ASTC_12x12_UNORM_BLOCK = 183,
	VK_FORMAT_ASTC_12x12_SRGB_BLOCK = 184,
	VK_FORMAT_BEGIN_RANGE = VK_FORMAT_UNDEFINED,
	VK_FORMAT_END_RANGE = VK_FORMAT_ASTC_12x12_SRGB_BLOCK,
	VK_FORMAT_RANGE_SIZE = (VK_FORMAT_ASTC_12x12_SRGB_BLOCK - VK_FORMAT_UNDEFINED + 1),
	VK_FORMAT_MAX_ENUM = 0x7FFFFFFF,
}
enum VkFormatFeatureFlagBits {
	VK_FORMAT_FEATURE_SAMPLED_IMAGE_BIT = 0x00000001,
	VK_FORMAT_FEATURE_STORAGE_IMAGE_BIT = 0x00000002,
	VK_FORMAT_FEATURE_STORAGE_IMAGE_ATOMIC_BIT = 0x00000004,
	VK_FORMAT_FEATURE_UNIFORM_TEXEL_BUFFER_BIT = 0x00000008,
	VK_FORMAT_FEATURE_STORAGE_TEXEL_BUFFER_BIT = 0x00000010,
	VK_FORMAT_FEATURE_STORAGE_TEXEL_BUFFER_ATOMIC_BIT = 0x00000020,
	VK_FORMAT_FEATURE_VERTEX_BUFFER_BIT = 0x00000040,
	VK_FORMAT_FEATURE_COLOR_ATTACHMENT_BIT = 0x00000080,
	VK_FORMAT_FEATURE_COLOR_ATTACHMENT_BLEND_BIT = 0x00000100,
	VK_FORMAT_FEATURE_DEPTH_STENCIL_ATTACHMENT_BIT = 0x00000200,
	VK_FORMAT_FEATURE_BLIT_SRC_BIT = 0x00000400,
	VK_FORMAT_FEATURE_BLIT_DST_BIT = 0x00000800,
	VK_FORMAT_FEATURE_SAMPLED_IMAGE_FILTER_LINEAR_BIT = 0x00001000,
	VK_FORMAT_FEATURE_SAMPLED_IMAGE_FILTER_CUBIC_BIT_IMG = 0x00002000,
}
alias VkFormatFeatureFlags = VkFlags;
struct VkFormatProperties {
	VkFormatFeatureFlags linearTilingFeatures;
	VkFormatFeatureFlags optimalTilingFeatures;
	VkFormatFeatureFlags bufferFeatures;
}
enum VkImageType {
	VK_IMAGE_TYPE_1D = 0,
	VK_IMAGE_TYPE_2D = 1,
	VK_IMAGE_TYPE_3D = 2,
	VK_IMAGE_TYPE_BEGIN_RANGE = VK_IMAGE_TYPE_1D,
	VK_IMAGE_TYPE_END_RANGE = VK_IMAGE_TYPE_3D,
	VK_IMAGE_TYPE_RANGE_SIZE = (VK_IMAGE_TYPE_3D - VK_IMAGE_TYPE_1D + 1),
	VK_IMAGE_TYPE_MAX_ENUM = 0x7FFFFFFF,
}
enum VkImageTiling {
	VK_IMAGE_TILING_OPTIMAL = 0,
	VK_IMAGE_TILING_LINEAR = 1,
	VK_IMAGE_TILING_BEGIN_RANGE = VK_IMAGE_TILING_OPTIMAL,
	VK_IMAGE_TILING_END_RANGE = VK_IMAGE_TILING_LINEAR,
	VK_IMAGE_TILING_RANGE_SIZE = (VK_IMAGE_TILING_LINEAR - VK_IMAGE_TILING_OPTIMAL + 1),
	VK_IMAGE_TILING_MAX_ENUM = 0x7FFFFFFF,
}
enum VkImageUsageFlagBits {
	VK_IMAGE_USAGE_TRANSFER_SRC_BIT = 0x00000001,
	VK_IMAGE_USAGE_TRANSFER_DST_BIT = 0x00000002,
	VK_IMAGE_USAGE_SAMPLED_BIT = 0x00000004,
	VK_IMAGE_USAGE_STORAGE_BIT = 0x00000008,
	VK_IMAGE_USAGE_COLOR_ATTACHMENT_BIT = 0x00000010,
	VK_IMAGE_USAGE_DEPTH_STENCIL_ATTACHMENT_BIT = 0x00000020,
	VK_IMAGE_USAGE_TRANSIENT_ATTACHMENT_BIT = 0x00000040,
	VK_IMAGE_USAGE_INPUT_ATTACHMENT_BIT = 0x00000080,
}
alias VkImageUsageFlags = VkFlags;
enum VkImageCreateFlagBits {
	VK_IMAGE_CREATE_SPARSE_BINDING_BIT = 0x00000001,
	VK_IMAGE_CREATE_SPARSE_RESIDENCY_BIT = 0x00000002,
	VK_IMAGE_CREATE_SPARSE_ALIASED_BIT = 0x00000004,
	VK_IMAGE_CREATE_MUTABLE_FORMAT_BIT = 0x00000008,
	VK_IMAGE_CREATE_CUBE_COMPATIBLE_BIT = 0x00000010,
}
alias VkImageCreateFlags = VkFlags;
struct VkExtent3D {
	uint32_t width;
	uint32_t height;
	uint32_t depth;
}
enum VkSampleCountFlagBits {
	VK_SAMPLE_COUNT_1_BIT = 0x00000001,
	VK_SAMPLE_COUNT_2_BIT = 0x00000002,
	VK_SAMPLE_COUNT_4_BIT = 0x00000004,
	VK_SAMPLE_COUNT_8_BIT = 0x00000008,
	VK_SAMPLE_COUNT_16_BIT = 0x00000010,
	VK_SAMPLE_COUNT_32_BIT = 0x00000020,
	VK_SAMPLE_COUNT_64_BIT = 0x00000040,
}
alias VkSampleCountFlags = VkFlags;
alias VkDeviceSize = uint64_t;
struct VkImageFormatProperties {
	VkExtent3D maxExtent;
	uint32_t maxMipLevels;
	uint32_t maxArrayLayers;
	VkSampleCountFlags sampleCounts;
	VkDeviceSize maxResourceSize;
}
enum VkPhysicalDeviceType {
	VK_PHYSICAL_DEVICE_TYPE_OTHER = 0,
	VK_PHYSICAL_DEVICE_TYPE_INTEGRATED_GPU = 1,
	VK_PHYSICAL_DEVICE_TYPE_DISCRETE_GPU = 2,
	VK_PHYSICAL_DEVICE_TYPE_VIRTUAL_GPU = 3,
	VK_PHYSICAL_DEVICE_TYPE_CPU = 4,
	VK_PHYSICAL_DEVICE_TYPE_BEGIN_RANGE = VK_PHYSICAL_DEVICE_TYPE_OTHER,
	VK_PHYSICAL_DEVICE_TYPE_END_RANGE = VK_PHYSICAL_DEVICE_TYPE_CPU,
	VK_PHYSICAL_DEVICE_TYPE_RANGE_SIZE = (VK_PHYSICAL_DEVICE_TYPE_CPU - VK_PHYSICAL_DEVICE_TYPE_OTHER + 1),
	VK_PHYSICAL_DEVICE_TYPE_MAX_ENUM = 0x7FFFFFFF,
}
struct VkPhysicalDeviceLimits {
	uint32_t maxImageDimension1D;
	uint32_t maxImageDimension2D;
	uint32_t maxImageDimension3D;
	uint32_t maxImageDimensionCube;
	uint32_t maxImageArrayLayers;
	uint32_t maxTexelBufferElements;
	uint32_t maxUniformBufferRange;
	uint32_t maxStorageBufferRange;
	uint32_t maxPushConstantsSize;
	uint32_t maxMemoryAllocationCount;
	uint32_t maxSamplerAllocationCount;
	VkDeviceSize bufferImageGranularity;
	VkDeviceSize sparseAddressSpaceSize;
	uint32_t maxBoundDescriptorSets;
	uint32_t maxPerStageDescriptorSamplers;
	uint32_t maxPerStageDescriptorUniformBuffers;
	uint32_t maxPerStageDescriptorStorageBuffers;
	uint32_t maxPerStageDescriptorSampledImages;
	uint32_t maxPerStageDescriptorStorageImages;
	uint32_t maxPerStageDescriptorInputAttachments;
	uint32_t maxPerStageResources;
	uint32_t maxDescriptorSetSamplers;
	uint32_t maxDescriptorSetUniformBuffers;
	uint32_t maxDescriptorSetUniformBuffersDynamic;
	uint32_t maxDescriptorSetStorageBuffers;
	uint32_t maxDescriptorSetStorageBuffersDynamic;
	uint32_t maxDescriptorSetSampledImages;
	uint32_t maxDescriptorSetStorageImages;
	uint32_t maxDescriptorSetInputAttachments;
	uint32_t maxVertexInputAttributes;
	uint32_t maxVertexInputBindings;
	uint32_t maxVertexInputAttributeOffset;
	uint32_t maxVertexInputBindingStride;
	uint32_t maxVertexOutputComponents;
	uint32_t maxTessellationGenerationLevel;
	uint32_t maxTessellationPatchSize;
	uint32_t maxTessellationControlPerVertexInputComponents;
	uint32_t maxTessellationControlPerVertexOutputComponents;
	uint32_t maxTessellationControlPerPatchOutputComponents;
	uint32_t maxTessellationControlTotalOutputComponents;
	uint32_t maxTessellationEvaluationInputComponents;
	uint32_t maxTessellationEvaluationOutputComponents;
	uint32_t maxGeometryShaderInvocations;
	uint32_t maxGeometryInputComponents;
	uint32_t maxGeometryOutputComponents;
	uint32_t maxGeometryOutputVertices;
	uint32_t maxGeometryTotalOutputComponents;
	uint32_t maxFragmentInputComponents;
	uint32_t maxFragmentOutputAttachments;
	uint32_t maxFragmentDualSrcAttachments;
	uint32_t maxFragmentCombinedOutputResources;
	uint32_t maxComputeSharedMemorySize;
	uint32_t maxComputeWorkGroupCount;
	uint32_t maxComputeWorkGroupInvocations;
	uint32_t maxComputeWorkGroupSize;
	uint32_t subPixelPrecisionBits;
	uint32_t subTexelPrecisionBits;
	uint32_t mipmapPrecisionBits;
	uint32_t maxDrawIndexedIndexValue;
	uint32_t maxDrawIndirectCount;
	float maxSamplerLodBias;
	float maxSamplerAnisotropy;
	uint32_t maxViewports;
	uint32_t maxViewportDimensions;
	float viewportBoundsRange;
	uint32_t viewportSubPixelBits;
	size_t minMemoryMapAlignment;
	VkDeviceSize minTexelBufferOffsetAlignment;
	VkDeviceSize minUniformBufferOffsetAlignment;
	VkDeviceSize minStorageBufferOffsetAlignment;
	int32_t minTexelOffset;
	uint32_t maxTexelOffset;
	int32_t minTexelGatherOffset;
	uint32_t maxTexelGatherOffset;
	float minInterpolationOffset;
	float maxInterpolationOffset;
	uint32_t subPixelInterpolationOffsetBits;
	uint32_t maxFramebufferWidth;
	uint32_t maxFramebufferHeight;
	uint32_t maxFramebufferLayers;
	VkSampleCountFlags framebufferColorSampleCounts;
	VkSampleCountFlags framebufferDepthSampleCounts;
	VkSampleCountFlags framebufferStencilSampleCounts;
	VkSampleCountFlags framebufferNoAttachmentsSampleCounts;
	uint32_t maxColorAttachments;
	VkSampleCountFlags sampledImageColorSampleCounts;
	VkSampleCountFlags sampledImageIntegerSampleCounts;
	VkSampleCountFlags sampledImageDepthSampleCounts;
	VkSampleCountFlags sampledImageStencilSampleCounts;
	VkSampleCountFlags storageImageSampleCounts;
	uint32_t maxSampleMaskWords;
	VkBool32 timestampComputeAndGraphics;
	float timestampPeriod;
	uint32_t maxClipDistances;
	uint32_t maxCullDistances;
	uint32_t maxCombinedClipAndCullDistances;
	uint32_t discreteQueuePriorities;
	float pointSizeRange;
	float lineWidthRange;
	float pointSizeGranularity;
	float lineWidthGranularity;
	VkBool32 strictLines;
	VkBool32 standardSampleLocations;
	VkDeviceSize optimalBufferCopyOffsetAlignment;
	VkDeviceSize optimalBufferCopyRowPitchAlignment;
	VkDeviceSize nonCoherentAtomSize;
}
struct VkPhysicalDeviceSparseProperties {
	VkBool32 residencyStandard2DBlockShape;
	VkBool32 residencyStandard2DMultisampleBlockShape;
	VkBool32 residencyStandard3DBlockShape;
	VkBool32 residencyAlignedMipSize;
	VkBool32 residencyNonResidentStrict;
}
enum VK_MAX_PHYSICAL_DEVICE_NAME_SIZE = 256;
enum VK_UUID_SIZE = 16;
struct VkPhysicalDeviceProperties {
	uint32_t apiVersion;
	uint32_t driverVersion;
	uint32_t vendorID;
	uint32_t deviceID;
	VkPhysicalDeviceType deviceType;
	char deviceName;
	uint8_t pipelineCacheUUID;
	VkPhysicalDeviceLimits limits;
	VkPhysicalDeviceSparseProperties sparseProperties;
}
enum VkQueueFlagBits {
	VK_QUEUE_GRAPHICS_BIT = 0x00000001,
	VK_QUEUE_COMPUTE_BIT = 0x00000002,
	VK_QUEUE_TRANSFER_BIT = 0x00000004,
	VK_QUEUE_SPARSE_BINDING_BIT = 0x00000008,
}
alias VkQueueFlags = VkFlags;
struct VkQueueFamilyProperties {
	VkQueueFlags queueFlags;
	uint32_t queueCount;
	uint32_t timestampValidBits;
	VkExtent3D minImageTransferGranularity;
}
enum VkMemoryPropertyFlagBits {
	VK_MEMORY_PROPERTY_DEVICE_LOCAL_BIT = 0x00000001,
	VK_MEMORY_PROPERTY_HOST_VISIBLE_BIT = 0x00000002,
	VK_MEMORY_PROPERTY_HOST_COHERENT_BIT = 0x00000004,
	VK_MEMORY_PROPERTY_HOST_CACHED_BIT = 0x00000008,
	VK_MEMORY_PROPERTY_LAZILY_ALLOCATED_BIT = 0x00000010,
}
alias VkMemoryPropertyFlags = VkFlags;
struct VkMemoryType {
	VkMemoryPropertyFlags propertyFlags;
	uint32_t heapIndex;
}
enum VkMemoryHeapFlagBits {
	VK_MEMORY_HEAP_DEVICE_LOCAL_BIT = 0x00000001,
}
alias VkMemoryHeapFlags = VkFlags;
struct VkMemoryHeap {
	VkDeviceSize size;
	VkMemoryHeapFlags flags;
}
enum VK_MAX_MEMORY_TYPES = 32;
enum VK_MAX_MEMORY_HEAPS = 16;
struct VkPhysicalDeviceMemoryProperties {
	uint32_t memoryTypeCount;
	VkMemoryType memoryTypes;
	uint32_t memoryHeapCount;
	VkMemoryHeap memoryHeaps;
}
alias PFN_vkVoidFunction = void function();
mixin(VK_DEFINE_HANDLE!q{VkDevice});
alias VkDeviceCreateFlags = VkFlags;
alias VkDeviceQueueCreateFlags = VkFlags;
struct VkDeviceQueueCreateInfo {
	VkStructureType sType;
	const(void)* pNext;
	VkDeviceQueueCreateFlags flags;
	uint32_t queueFamilyIndex;
	uint32_t queueCount;
	const(float)* pQueuePriorities;
}
struct VkDeviceCreateInfo {
	VkStructureType sType;
	const(void)* pNext;
	VkDeviceCreateFlags flags;
	uint32_t queueCreateInfoCount;
	const(VkDeviceQueueCreateInfo)* pQueueCreateInfos;
	uint32_t enabledLayerCount;
	const(char*)* ppEnabledLayerNames;
	uint32_t enabledExtensionCount;
	const(char*)* ppEnabledExtensionNames;
	const(VkPhysicalDeviceFeatures)* pEnabledFeatures;
}
enum VK_MAX_EXTENSION_NAME_SIZE = 256;
struct VkExtensionProperties {
	char extensionName;
	uint32_t specVersion;
}
enum VK_MAX_DESCRIPTION_SIZE = 256;
struct VkLayerProperties {
	char layerName;
	uint32_t specVersion;
	uint32_t implementationVersion;
	char description;
}
mixin(VK_DEFINE_HANDLE!q{VkQueue});
mixin(VK_DEFINE_NON_DISPATCHABLE_HANDLE!q{VkSemaphore});
enum VkPipelineStageFlagBits {
	VK_PIPELINE_STAGE_TOP_OF_PIPE_BIT = 0x00000001,
	VK_PIPELINE_STAGE_DRAW_INDIRECT_BIT = 0x00000002,
	VK_PIPELINE_STAGE_VERTEX_INPUT_BIT = 0x00000004,
	VK_PIPELINE_STAGE_VERTEX_SHADER_BIT = 0x00000008,
	VK_PIPELINE_STAGE_TESSELLATION_CONTROL_SHADER_BIT = 0x00000010,
	VK_PIPELINE_STAGE_TESSELLATION_EVALUATION_SHADER_BIT = 0x00000020,
	VK_PIPELINE_STAGE_GEOMETRY_SHADER_BIT = 0x00000040,
	VK_PIPELINE_STAGE_FRAGMENT_SHADER_BIT = 0x00000080,
	VK_PIPELINE_STAGE_EARLY_FRAGMENT_TESTS_BIT = 0x00000100,
	VK_PIPELINE_STAGE_LATE_FRAGMENT_TESTS_BIT = 0x00000200,
	VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT = 0x00000400,
	VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT = 0x00000800,
	VK_PIPELINE_STAGE_TRANSFER_BIT = 0x00001000,
	VK_PIPELINE_STAGE_BOTTOM_OF_PIPE_BIT = 0x00002000,
	VK_PIPELINE_STAGE_HOST_BIT = 0x00004000,
	VK_PIPELINE_STAGE_ALL_GRAPHICS_BIT = 0x00008000,
	VK_PIPELINE_STAGE_ALL_COMMANDS_BIT = 0x00010000,
}
alias VkPipelineStageFlags = VkFlags;
mixin(VK_DEFINE_HANDLE!q{VkCommandBuffer});
struct VkSubmitInfo {
	VkStructureType sType;
	const(void)* pNext;
	uint32_t waitSemaphoreCount;
	const(VkSemaphore)* pWaitSemaphores;
	const(VkPipelineStageFlags)* pWaitDstStageMask;
	uint32_t commandBufferCount;
	const(VkCommandBuffer)* pCommandBuffers;
	uint32_t signalSemaphoreCount;
	const(VkSemaphore)* pSignalSemaphores;
}
mixin(VK_DEFINE_NON_DISPATCHABLE_HANDLE!q{VkFence});
struct VkMemoryAllocateInfo {
	VkStructureType sType;
	const(void)* pNext;
	VkDeviceSize allocationSize;
	uint32_t memoryTypeIndex;
}
mixin(VK_DEFINE_NON_DISPATCHABLE_HANDLE!q{VkDeviceMemory});
alias VkMemoryMapFlags = VkFlags;
struct VkMappedMemoryRange {
	VkStructureType sType;
	const(void)* pNext;
	VkDeviceMemory memory;
	VkDeviceSize offset;
	VkDeviceSize size;
}
mixin(VK_DEFINE_NON_DISPATCHABLE_HANDLE!q{VkBuffer});
mixin(VK_DEFINE_NON_DISPATCHABLE_HANDLE!q{VkImage});
struct VkMemoryRequirements {
	VkDeviceSize size;
	VkDeviceSize alignment;
	uint32_t memoryTypeBits;
}
enum VkImageAspectFlagBits {
	VK_IMAGE_ASPECT_COLOR_BIT = 0x00000001,
	VK_IMAGE_ASPECT_DEPTH_BIT = 0x00000002,
	VK_IMAGE_ASPECT_STENCIL_BIT = 0x00000004,
	VK_IMAGE_ASPECT_METADATA_BIT = 0x00000008,
}
alias VkImageAspectFlags = VkFlags;
enum VkSparseImageFormatFlagBits {
	VK_SPARSE_IMAGE_FORMAT_SINGLE_MIPTAIL_BIT = 0x00000001,
	VK_SPARSE_IMAGE_FORMAT_ALIGNED_MIP_SIZE_BIT = 0x00000002,
	VK_SPARSE_IMAGE_FORMAT_NONSTANDARD_BLOCK_SIZE_BIT = 0x00000004,
}
alias VkSparseImageFormatFlags = VkFlags;
struct VkSparseImageFormatProperties {
	VkImageAspectFlags aspectMask;
	VkExtent3D imageGranularity;
	VkSparseImageFormatFlags flags;
}
struct VkSparseImageMemoryRequirements {
	VkSparseImageFormatProperties formatProperties;
	uint32_t imageMipTailFirstLod;
	VkDeviceSize imageMipTailSize;
	VkDeviceSize imageMipTailOffset;
	VkDeviceSize imageMipTailStride;
}
enum VkSparseMemoryBindFlagBits {
	VK_SPARSE_MEMORY_BIND_METADATA_BIT = 0x00000001,
}
alias VkSparseMemoryBindFlags = VkFlags;
struct VkSparseMemoryBind {
	VkDeviceSize resourceOffset;
	VkDeviceSize size;
	VkDeviceMemory memory;
	VkDeviceSize memoryOffset;
	VkSparseMemoryBindFlags flags;
}
struct VkSparseBufferMemoryBindInfo {
	VkBuffer buffer;
	uint32_t bindCount;
	const(VkSparseMemoryBind)* pBinds;
}
struct VkSparseImageOpaqueMemoryBindInfo {
	VkImage image;
	uint32_t bindCount;
	const(VkSparseMemoryBind)* pBinds;
}
struct VkImageSubresource {
	VkImageAspectFlags aspectMask;
	uint32_t mipLevel;
	uint32_t arrayLayer;
}
struct VkOffset3D {
	int32_t x;
	int32_t y;
	int32_t z;
}
struct VkSparseImageMemoryBind {
	VkImageSubresource subresource;
	VkOffset3D offset;
	VkExtent3D extent;
	VkDeviceMemory memory;
	VkDeviceSize memoryOffset;
	VkSparseMemoryBindFlags flags;
}
struct VkSparseImageMemoryBindInfo {
	VkImage image;
	uint32_t bindCount;
	const(VkSparseImageMemoryBind)* pBinds;
}
struct VkBindSparseInfo {
	VkStructureType sType;
	const(void)* pNext;
	uint32_t waitSemaphoreCount;
	const(VkSemaphore)* pWaitSemaphores;
	uint32_t bufferBindCount;
	const(VkSparseBufferMemoryBindInfo)* pBufferBinds;
	uint32_t imageOpaqueBindCount;
	const(VkSparseImageOpaqueMemoryBindInfo)* pImageOpaqueBinds;
	uint32_t imageBindCount;
	const(VkSparseImageMemoryBindInfo)* pImageBinds;
	uint32_t signalSemaphoreCount;
	const(VkSemaphore)* pSignalSemaphores;
}
enum VkFenceCreateFlagBits {
	VK_FENCE_CREATE_SIGNALED_BIT = 0x00000001,
}
alias VkFenceCreateFlags = VkFlags;
struct VkFenceCreateInfo {
	VkStructureType sType;
	const(void)* pNext;
	VkFenceCreateFlags flags;
}
alias VkSemaphoreCreateFlags = VkFlags;
struct VkSemaphoreCreateInfo {
	VkStructureType sType;
	const(void)* pNext;
	VkSemaphoreCreateFlags flags;
}
alias VkEventCreateFlags = VkFlags;
struct VkEventCreateInfo {
	VkStructureType sType;
	const(void)* pNext;
	VkEventCreateFlags flags;
}
mixin(VK_DEFINE_NON_DISPATCHABLE_HANDLE!q{VkEvent});
alias VkQueryPoolCreateFlags = VkFlags;
enum VkQueryType {
	VK_QUERY_TYPE_OCCLUSION = 0,
	VK_QUERY_TYPE_PIPELINE_STATISTICS = 1,
	VK_QUERY_TYPE_TIMESTAMP = 2,
	VK_QUERY_TYPE_BEGIN_RANGE = VK_QUERY_TYPE_OCCLUSION,
	VK_QUERY_TYPE_END_RANGE = VK_QUERY_TYPE_TIMESTAMP,
	VK_QUERY_TYPE_RANGE_SIZE = (VK_QUERY_TYPE_TIMESTAMP - VK_QUERY_TYPE_OCCLUSION + 1),
	VK_QUERY_TYPE_MAX_ENUM = 0x7FFFFFFF,
}
enum VkQueryPipelineStatisticFlagBits {
	VK_QUERY_PIPELINE_STATISTIC_INPUT_ASSEMBLY_VERTICES_BIT = 0x00000001,
	VK_QUERY_PIPELINE_STATISTIC_INPUT_ASSEMBLY_PRIMITIVES_BIT = 0x00000002,
	VK_QUERY_PIPELINE_STATISTIC_VERTEX_SHADER_INVOCATIONS_BIT = 0x00000004,
	VK_QUERY_PIPELINE_STATISTIC_GEOMETRY_SHADER_INVOCATIONS_BIT = 0x00000008,
	VK_QUERY_PIPELINE_STATISTIC_GEOMETRY_SHADER_PRIMITIVES_BIT = 0x00000010,
	VK_QUERY_PIPELINE_STATISTIC_CLIPPING_INVOCATIONS_BIT = 0x00000020,
	VK_QUERY_PIPELINE_STATISTIC_CLIPPING_PRIMITIVES_BIT = 0x00000040,
	VK_QUERY_PIPELINE_STATISTIC_FRAGMENT_SHADER_INVOCATIONS_BIT = 0x00000080,
	VK_QUERY_PIPELINE_STATISTIC_TESSELLATION_CONTROL_SHADER_PATCHES_BIT = 0x00000100,
	VK_QUERY_PIPELINE_STATISTIC_TESSELLATION_EVALUATION_SHADER_INVOCATIONS_BIT = 0x00000200,
	VK_QUERY_PIPELINE_STATISTIC_COMPUTE_SHADER_INVOCATIONS_BIT = 0x00000400,
}
alias VkQueryPipelineStatisticFlags = VkFlags;
struct VkQueryPoolCreateInfo {
	VkStructureType sType;
	const(void)* pNext;
	VkQueryPoolCreateFlags flags;
	VkQueryType queryType;
	uint32_t queryCount;
	VkQueryPipelineStatisticFlags pipelineStatistics;
}
mixin(VK_DEFINE_NON_DISPATCHABLE_HANDLE!q{VkQueryPool});
enum VkQueryResultFlagBits {
	VK_QUERY_RESULT_64_BIT = 0x00000001,
	VK_QUERY_RESULT_WAIT_BIT = 0x00000002,
	VK_QUERY_RESULT_WITH_AVAILABILITY_BIT = 0x00000004,
	VK_QUERY_RESULT_PARTIAL_BIT = 0x00000008,
}
alias VkQueryResultFlags = VkFlags;
enum VkBufferCreateFlagBits {
	VK_BUFFER_CREATE_SPARSE_BINDING_BIT = 0x00000001,
	VK_BUFFER_CREATE_SPARSE_RESIDENCY_BIT = 0x00000002,
	VK_BUFFER_CREATE_SPARSE_ALIASED_BIT = 0x00000004,
}
alias VkBufferCreateFlags = VkFlags;
enum VkBufferUsageFlagBits {
	VK_BUFFER_USAGE_TRANSFER_SRC_BIT = 0x00000001,
	VK_BUFFER_USAGE_TRANSFER_DST_BIT = 0x00000002,
	VK_BUFFER_USAGE_UNIFORM_TEXEL_BUFFER_BIT = 0x00000004,
	VK_BUFFER_USAGE_STORAGE_TEXEL_BUFFER_BIT = 0x00000008,
	VK_BUFFER_USAGE_UNIFORM_BUFFER_BIT = 0x00000010,
	VK_BUFFER_USAGE_STORAGE_BUFFER_BIT = 0x00000020,
	VK_BUFFER_USAGE_INDEX_BUFFER_BIT = 0x00000040,
	VK_BUFFER_USAGE_VERTEX_BUFFER_BIT = 0x00000080,
	VK_BUFFER_USAGE_INDIRECT_BUFFER_BIT = 0x00000100,
}
alias VkBufferUsageFlags = VkFlags;
enum VkSharingMode {
	VK_SHARING_MODE_EXCLUSIVE = 0,
	VK_SHARING_MODE_CONCURRENT = 1,
	VK_SHARING_MODE_BEGIN_RANGE = VK_SHARING_MODE_EXCLUSIVE,
	VK_SHARING_MODE_END_RANGE = VK_SHARING_MODE_CONCURRENT,
	VK_SHARING_MODE_RANGE_SIZE = (VK_SHARING_MODE_CONCURRENT - VK_SHARING_MODE_EXCLUSIVE + 1),
	VK_SHARING_MODE_MAX_ENUM = 0x7FFFFFFF,
}
struct VkBufferCreateInfo {
	VkStructureType sType;
	const(void)* pNext;
	VkBufferCreateFlags flags;
	VkDeviceSize size;
	VkBufferUsageFlags usage;
	VkSharingMode sharingMode;
	uint32_t queueFamilyIndexCount;
	const(uint32_t)* pQueueFamilyIndices;
}
alias VkBufferViewCreateFlags = VkFlags;
struct VkBufferViewCreateInfo {
	VkStructureType sType;
	const(void)* pNext;
	VkBufferViewCreateFlags flags;
	VkBuffer buffer;
	VkFormat format;
	VkDeviceSize offset;
	VkDeviceSize range;
}
mixin(VK_DEFINE_NON_DISPATCHABLE_HANDLE!q{VkBufferView});
enum VkImageLayout {
	VK_IMAGE_LAYOUT_UNDEFINED = 0,
	VK_IMAGE_LAYOUT_GENERAL = 1,
	VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL = 2,
	VK_IMAGE_LAYOUT_DEPTH_STENCIL_ATTACHMENT_OPTIMAL = 3,
	VK_IMAGE_LAYOUT_DEPTH_STENCIL_READ_ONLY_OPTIMAL = 4,
	VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL = 5,
	VK_IMAGE_LAYOUT_TRANSFER_SRC_OPTIMAL = 6,
	VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL = 7,
	VK_IMAGE_LAYOUT_PREINITIALIZED = 8,
	VK_IMAGE_LAYOUT_PRESENT_SRC_KHR = 1000001002,
	VK_IMAGE_LAYOUT_BEGIN_RANGE = VK_IMAGE_LAYOUT_UNDEFINED,
	VK_IMAGE_LAYOUT_END_RANGE = VK_IMAGE_LAYOUT_PRESENT_SRC_KHR,
	VK_IMAGE_LAYOUT_RANGE_SIZE = (VK_IMAGE_LAYOUT_PRESENT_SRC_KHR - VK_IMAGE_LAYOUT_UNDEFINED + 1),
	VK_IMAGE_LAYOUT_MAX_ENUM = 0x7FFFFFFF,
}
struct VkImageCreateInfo {
	VkStructureType sType;
	const(void)* pNext;
	VkImageCreateFlags flags;
	VkImageType imageType;
	VkFormat format;
	VkExtent3D extent;
	uint32_t mipLevels;
	uint32_t arrayLayers;
	VkSampleCountFlagBits samples;
	VkImageTiling tiling;
	VkImageUsageFlags usage;
	VkSharingMode sharingMode;
	uint32_t queueFamilyIndexCount;
	const(uint32_t)* pQueueFamilyIndices;
	VkImageLayout initialLayout;
}
struct VkSubresourceLayout {
	VkDeviceSize offset;
	VkDeviceSize size;
	VkDeviceSize rowPitch;
	VkDeviceSize arrayPitch;
	VkDeviceSize depthPitch;
}
alias VkImageViewCreateFlags = VkFlags;
enum VkImageViewType {
	VK_IMAGE_VIEW_TYPE_1D = 0,
	VK_IMAGE_VIEW_TYPE_2D = 1,
	VK_IMAGE_VIEW_TYPE_3D = 2,
	VK_IMAGE_VIEW_TYPE_CUBE = 3,
	VK_IMAGE_VIEW_TYPE_1D_ARRAY = 4,
	VK_IMAGE_VIEW_TYPE_2D_ARRAY = 5,
	VK_IMAGE_VIEW_TYPE_CUBE_ARRAY = 6,
	VK_IMAGE_VIEW_TYPE_BEGIN_RANGE = VK_IMAGE_VIEW_TYPE_1D,
	VK_IMAGE_VIEW_TYPE_END_RANGE = VK_IMAGE_VIEW_TYPE_CUBE_ARRAY,
	VK_IMAGE_VIEW_TYPE_RANGE_SIZE = (VK_IMAGE_VIEW_TYPE_CUBE_ARRAY - VK_IMAGE_VIEW_TYPE_1D + 1),
	VK_IMAGE_VIEW_TYPE_MAX_ENUM = 0x7FFFFFFF,
}
enum VkComponentSwizzle {
	VK_COMPONENT_SWIZZLE_IDENTITY = 0,
	VK_COMPONENT_SWIZZLE_ZERO = 1,
	VK_COMPONENT_SWIZZLE_ONE = 2,
	VK_COMPONENT_SWIZZLE_R = 3,
	VK_COMPONENT_SWIZZLE_G = 4,
	VK_COMPONENT_SWIZZLE_B = 5,
	VK_COMPONENT_SWIZZLE_A = 6,
	VK_COMPONENT_SWIZZLE_BEGIN_RANGE = VK_COMPONENT_SWIZZLE_IDENTITY,
	VK_COMPONENT_SWIZZLE_END_RANGE = VK_COMPONENT_SWIZZLE_A,
	VK_COMPONENT_SWIZZLE_RANGE_SIZE = (VK_COMPONENT_SWIZZLE_A - VK_COMPONENT_SWIZZLE_IDENTITY + 1),
	VK_COMPONENT_SWIZZLE_MAX_ENUM = 0x7FFFFFFF,
}
struct VkComponentMapping {
	VkComponentSwizzle r;
	VkComponentSwizzle g;
	VkComponentSwizzle b;
	VkComponentSwizzle a;
}
struct VkImageSubresourceRange {
	VkImageAspectFlags aspectMask;
	uint32_t baseMipLevel;
	uint32_t levelCount;
	uint32_t baseArrayLayer;
	uint32_t layerCount;
}
struct VkImageViewCreateInfo {
	VkStructureType sType;
	const(void)* pNext;
	VkImageViewCreateFlags flags;
	VkImage image;
	VkImageViewType viewType;
	VkFormat format;
	VkComponentMapping components;
	VkImageSubresourceRange subresourceRange;
}
mixin(VK_DEFINE_NON_DISPATCHABLE_HANDLE!q{VkImageView});
alias VkShaderModuleCreateFlags = VkFlags;
struct VkShaderModuleCreateInfo {
	VkStructureType sType;
	const(void)* pNext;
	VkShaderModuleCreateFlags flags;
	size_t codeSize;
	const(uint32_t)* pCode;
}
mixin(VK_DEFINE_NON_DISPATCHABLE_HANDLE!q{VkShaderModule});
alias VkPipelineCacheCreateFlags = VkFlags;
struct VkPipelineCacheCreateInfo {
	VkStructureType sType;
	const(void)* pNext;
	VkPipelineCacheCreateFlags flags;
	size_t initialDataSize;
	const(void)* pInitialData;
}
mixin(VK_DEFINE_NON_DISPATCHABLE_HANDLE!q{VkPipelineCache});
enum VkPipelineCreateFlagBits {
	VK_PIPELINE_CREATE_DISABLE_OPTIMIZATION_BIT = 0x00000001,
	VK_PIPELINE_CREATE_ALLOW_DERIVATIVES_BIT = 0x00000002,
	VK_PIPELINE_CREATE_DERIVATIVE_BIT = 0x00000004,
}
alias VkPipelineCreateFlags = VkFlags;
alias VkPipelineShaderStageCreateFlags = VkFlags;
enum VkShaderStageFlagBits {
	VK_SHADER_STAGE_VERTEX_BIT = 0x00000001,
	VK_SHADER_STAGE_TESSELLATION_CONTROL_BIT = 0x00000002,
	VK_SHADER_STAGE_TESSELLATION_EVALUATION_BIT = 0x00000004,
	VK_SHADER_STAGE_GEOMETRY_BIT = 0x00000008,
	VK_SHADER_STAGE_FRAGMENT_BIT = 0x00000010,
	VK_SHADER_STAGE_COMPUTE_BIT = 0x00000020,
	VK_SHADER_STAGE_ALL_GRAPHICS = 0x0000001F,
	VK_SHADER_STAGE_ALL = 0x7FFFFFFF,
}
struct VkSpecializationMapEntry {
	uint32_t constantID;
	uint32_t offset;
	size_t size;
}
struct VkSpecializationInfo {
	uint32_t mapEntryCount;
	const(VkSpecializationMapEntry)* pMapEntries;
	size_t dataSize;
	const(void)* pData;
}
struct VkPipelineShaderStageCreateInfo {
	VkStructureType sType;
	const(void)* pNext;
	VkPipelineShaderStageCreateFlags flags;
	VkShaderStageFlagBits stage;
	VkShaderModule _module;
	const(char)* pName;
	const(VkSpecializationInfo)* pSpecializationInfo;
}
alias VkPipelineVertexInputStateCreateFlags = VkFlags;
enum VkVertexInputRate {
	VK_VERTEX_INPUT_RATE_VERTEX = 0,
	VK_VERTEX_INPUT_RATE_INSTANCE = 1,
	VK_VERTEX_INPUT_RATE_BEGIN_RANGE = VK_VERTEX_INPUT_RATE_VERTEX,
	VK_VERTEX_INPUT_RATE_END_RANGE = VK_VERTEX_INPUT_RATE_INSTANCE,
	VK_VERTEX_INPUT_RATE_RANGE_SIZE = (VK_VERTEX_INPUT_RATE_INSTANCE - VK_VERTEX_INPUT_RATE_VERTEX + 1),
	VK_VERTEX_INPUT_RATE_MAX_ENUM = 0x7FFFFFFF,
}
struct VkVertexInputBindingDescription {
	uint32_t binding;
	uint32_t stride;
	VkVertexInputRate inputRate;
}
struct VkVertexInputAttributeDescription {
	uint32_t location;
	uint32_t binding;
	VkFormat format;
	uint32_t offset;
}
struct VkPipelineVertexInputStateCreateInfo {
	VkStructureType sType;
	const(void)* pNext;
	VkPipelineVertexInputStateCreateFlags flags;
	uint32_t vertexBindingDescriptionCount;
	const(VkVertexInputBindingDescription)* pVertexBindingDescriptions;
	uint32_t vertexAttributeDescriptionCount;
	const(VkVertexInputAttributeDescription)* pVertexAttributeDescriptions;
}
alias VkPipelineInputAssemblyStateCreateFlags = VkFlags;
enum VkPrimitiveTopology {
	VK_PRIMITIVE_TOPOLOGY_POINT_LIST = 0,
	VK_PRIMITIVE_TOPOLOGY_LINE_LIST = 1,
	VK_PRIMITIVE_TOPOLOGY_LINE_STRIP = 2,
	VK_PRIMITIVE_TOPOLOGY_TRIANGLE_LIST = 3,
	VK_PRIMITIVE_TOPOLOGY_TRIANGLE_STRIP = 4,
	VK_PRIMITIVE_TOPOLOGY_TRIANGLE_FAN = 5,
	VK_PRIMITIVE_TOPOLOGY_LINE_LIST_WITH_ADJACENCY = 6,
	VK_PRIMITIVE_TOPOLOGY_LINE_STRIP_WITH_ADJACENCY = 7,
	VK_PRIMITIVE_TOPOLOGY_TRIANGLE_LIST_WITH_ADJACENCY = 8,
	VK_PRIMITIVE_TOPOLOGY_TRIANGLE_STRIP_WITH_ADJACENCY = 9,
	VK_PRIMITIVE_TOPOLOGY_PATCH_LIST = 10,
	VK_PRIMITIVE_TOPOLOGY_BEGIN_RANGE = VK_PRIMITIVE_TOPOLOGY_POINT_LIST,
	VK_PRIMITIVE_TOPOLOGY_END_RANGE = VK_PRIMITIVE_TOPOLOGY_PATCH_LIST,
	VK_PRIMITIVE_TOPOLOGY_RANGE_SIZE = (VK_PRIMITIVE_TOPOLOGY_PATCH_LIST - VK_PRIMITIVE_TOPOLOGY_POINT_LIST + 1),
	VK_PRIMITIVE_TOPOLOGY_MAX_ENUM = 0x7FFFFFFF,
}
struct VkPipelineInputAssemblyStateCreateInfo {
	VkStructureType sType;
	const(void)* pNext;
	VkPipelineInputAssemblyStateCreateFlags flags;
	VkPrimitiveTopology topology;
	VkBool32 primitiveRestartEnable;
}
alias VkPipelineTessellationStateCreateFlags = VkFlags;
struct VkPipelineTessellationStateCreateInfo {
	VkStructureType sType;
	const(void)* pNext;
	VkPipelineTessellationStateCreateFlags flags;
	uint32_t patchControlPoints;
}
alias VkPipelineViewportStateCreateFlags = VkFlags;
struct VkViewport {
	float x;
	float y;
	float width;
	float height;
	float minDepth;
	float maxDepth;
}
struct VkOffset2D {
	int32_t x;
	int32_t y;
}
struct VkExtent2D {
	uint32_t width;
	uint32_t height;
}
struct VkRect2D {
	VkOffset2D offset;
	VkExtent2D extent;
}
struct VkPipelineViewportStateCreateInfo {
	VkStructureType sType;
	const(void)* pNext;
	VkPipelineViewportStateCreateFlags flags;
	uint32_t viewportCount;
	const(VkViewport)* pViewports;
	uint32_t scissorCount;
	const(VkRect2D)* pScissors;
}
alias VkPipelineRasterizationStateCreateFlags = VkFlags;
enum VkPolygonMode {
	VK_POLYGON_MODE_FILL = 0,
	VK_POLYGON_MODE_LINE = 1,
	VK_POLYGON_MODE_POINT = 2,
	VK_POLYGON_MODE_BEGIN_RANGE = VK_POLYGON_MODE_FILL,
	VK_POLYGON_MODE_END_RANGE = VK_POLYGON_MODE_POINT,
	VK_POLYGON_MODE_RANGE_SIZE = (VK_POLYGON_MODE_POINT - VK_POLYGON_MODE_FILL + 1),
	VK_POLYGON_MODE_MAX_ENUM = 0x7FFFFFFF,
}
enum VkCullModeFlagBits {
	VK_CULL_MODE_NONE = 0,
	VK_CULL_MODE_FRONT_BIT = 0x00000001,
	VK_CULL_MODE_BACK_BIT = 0x00000002,
	VK_CULL_MODE_FRONT_AND_BACK = 0x00000003,
}
alias VkCullModeFlags = VkFlags;
enum VkFrontFace {
	VK_FRONT_FACE_COUNTER_CLOCKWISE = 0,
	VK_FRONT_FACE_CLOCKWISE = 1,
	VK_FRONT_FACE_BEGIN_RANGE = VK_FRONT_FACE_COUNTER_CLOCKWISE,
	VK_FRONT_FACE_END_RANGE = VK_FRONT_FACE_CLOCKWISE,
	VK_FRONT_FACE_RANGE_SIZE = (VK_FRONT_FACE_CLOCKWISE - VK_FRONT_FACE_COUNTER_CLOCKWISE + 1),
	VK_FRONT_FACE_MAX_ENUM = 0x7FFFFFFF,
}
struct VkPipelineRasterizationStateCreateInfo {
	VkStructureType sType;
	const(void)* pNext;
	VkPipelineRasterizationStateCreateFlags flags;
	VkBool32 depthClampEnable;
	VkBool32 rasterizerDiscardEnable;
	VkPolygonMode polygonMode;
	VkCullModeFlags cullMode;
	VkFrontFace frontFace;
	VkBool32 depthBiasEnable;
	float depthBiasConstantFactor;
	float depthBiasClamp;
	float depthBiasSlopeFactor;
	float lineWidth;
}
alias VkPipelineMultisampleStateCreateFlags = VkFlags;
alias VkSampleMask = uint32_t;
struct VkPipelineMultisampleStateCreateInfo {
	VkStructureType sType;
	const(void)* pNext;
	VkPipelineMultisampleStateCreateFlags flags;
	VkSampleCountFlagBits rasterizationSamples;
	VkBool32 sampleShadingEnable;
	float minSampleShading;
	const(VkSampleMask)* pSampleMask;
	VkBool32 alphaToCoverageEnable;
	VkBool32 alphaToOneEnable;
}
alias VkPipelineDepthStencilStateCreateFlags = VkFlags;
enum VkCompareOp {
	VK_COMPARE_OP_NEVER = 0,
	VK_COMPARE_OP_LESS = 1,
	VK_COMPARE_OP_EQUAL = 2,
	VK_COMPARE_OP_LESS_OR_EQUAL = 3,
	VK_COMPARE_OP_GREATER = 4,
	VK_COMPARE_OP_NOT_EQUAL = 5,
	VK_COMPARE_OP_GREATER_OR_EQUAL = 6,
	VK_COMPARE_OP_ALWAYS = 7,
	VK_COMPARE_OP_BEGIN_RANGE = VK_COMPARE_OP_NEVER,
	VK_COMPARE_OP_END_RANGE = VK_COMPARE_OP_ALWAYS,
	VK_COMPARE_OP_RANGE_SIZE = (VK_COMPARE_OP_ALWAYS - VK_COMPARE_OP_NEVER + 1),
	VK_COMPARE_OP_MAX_ENUM = 0x7FFFFFFF,
}
enum VkStencilOp {
	VK_STENCIL_OP_KEEP = 0,
	VK_STENCIL_OP_ZERO = 1,
	VK_STENCIL_OP_REPLACE = 2,
	VK_STENCIL_OP_INCREMENT_AND_CLAMP = 3,
	VK_STENCIL_OP_DECREMENT_AND_CLAMP = 4,
	VK_STENCIL_OP_INVERT = 5,
	VK_STENCIL_OP_INCREMENT_AND_WRAP = 6,
	VK_STENCIL_OP_DECREMENT_AND_WRAP = 7,
	VK_STENCIL_OP_BEGIN_RANGE = VK_STENCIL_OP_KEEP,
	VK_STENCIL_OP_END_RANGE = VK_STENCIL_OP_DECREMENT_AND_WRAP,
	VK_STENCIL_OP_RANGE_SIZE = (VK_STENCIL_OP_DECREMENT_AND_WRAP - VK_STENCIL_OP_KEEP + 1),
	VK_STENCIL_OP_MAX_ENUM = 0x7FFFFFFF,
}
struct VkStencilOpState {
	VkStencilOp failOp;
	VkStencilOp passOp;
	VkStencilOp depthFailOp;
	VkCompareOp compareOp;
	uint32_t compareMask;
	uint32_t writeMask;
	uint32_t reference;
}
struct VkPipelineDepthStencilStateCreateInfo {
	VkStructureType sType;
	const(void)* pNext;
	VkPipelineDepthStencilStateCreateFlags flags;
	VkBool32 depthTestEnable;
	VkBool32 depthWriteEnable;
	VkCompareOp depthCompareOp;
	VkBool32 depthBoundsTestEnable;
	VkBool32 stencilTestEnable;
	VkStencilOpState front;
	VkStencilOpState back;
	float minDepthBounds;
	float maxDepthBounds;
}
alias VkPipelineColorBlendStateCreateFlags = VkFlags;
enum VkLogicOp {
	VK_LOGIC_OP_CLEAR = 0,
	VK_LOGIC_OP_AND = 1,
	VK_LOGIC_OP_AND_REVERSE = 2,
	VK_LOGIC_OP_COPY = 3,
	VK_LOGIC_OP_AND_INVERTED = 4,
	VK_LOGIC_OP_NO_OP = 5,
	VK_LOGIC_OP_XOR = 6,
	VK_LOGIC_OP_OR = 7,
	VK_LOGIC_OP_NOR = 8,
	VK_LOGIC_OP_EQUIVALENT = 9,
	VK_LOGIC_OP_INVERT = 10,
	VK_LOGIC_OP_OR_REVERSE = 11,
	VK_LOGIC_OP_COPY_INVERTED = 12,
	VK_LOGIC_OP_OR_INVERTED = 13,
	VK_LOGIC_OP_NAND = 14,
	VK_LOGIC_OP_SET = 15,
	VK_LOGIC_OP_BEGIN_RANGE = VK_LOGIC_OP_CLEAR,
	VK_LOGIC_OP_END_RANGE = VK_LOGIC_OP_SET,
	VK_LOGIC_OP_RANGE_SIZE = (VK_LOGIC_OP_SET - VK_LOGIC_OP_CLEAR + 1),
	VK_LOGIC_OP_MAX_ENUM = 0x7FFFFFFF,
}
enum VkBlendFactor {
	VK_BLEND_FACTOR_ZERO = 0,
	VK_BLEND_FACTOR_ONE = 1,
	VK_BLEND_FACTOR_SRC_COLOR = 2,
	VK_BLEND_FACTOR_ONE_MINUS_SRC_COLOR = 3,
	VK_BLEND_FACTOR_DST_COLOR = 4,
	VK_BLEND_FACTOR_ONE_MINUS_DST_COLOR = 5,
	VK_BLEND_FACTOR_SRC_ALPHA = 6,
	VK_BLEND_FACTOR_ONE_MINUS_SRC_ALPHA = 7,
	VK_BLEND_FACTOR_DST_ALPHA = 8,
	VK_BLEND_FACTOR_ONE_MINUS_DST_ALPHA = 9,
	VK_BLEND_FACTOR_CONSTANT_COLOR = 10,
	VK_BLEND_FACTOR_ONE_MINUS_CONSTANT_COLOR = 11,
	VK_BLEND_FACTOR_CONSTANT_ALPHA = 12,
	VK_BLEND_FACTOR_ONE_MINUS_CONSTANT_ALPHA = 13,
	VK_BLEND_FACTOR_SRC_ALPHA_SATURATE = 14,
	VK_BLEND_FACTOR_SRC1_COLOR = 15,
	VK_BLEND_FACTOR_ONE_MINUS_SRC1_COLOR = 16,
	VK_BLEND_FACTOR_SRC1_ALPHA = 17,
	VK_BLEND_FACTOR_ONE_MINUS_SRC1_ALPHA = 18,
	VK_BLEND_FACTOR_BEGIN_RANGE = VK_BLEND_FACTOR_ZERO,
	VK_BLEND_FACTOR_END_RANGE = VK_BLEND_FACTOR_ONE_MINUS_SRC1_ALPHA,
	VK_BLEND_FACTOR_RANGE_SIZE = (VK_BLEND_FACTOR_ONE_MINUS_SRC1_ALPHA - VK_BLEND_FACTOR_ZERO + 1),
	VK_BLEND_FACTOR_MAX_ENUM = 0x7FFFFFFF,
}
enum VkBlendOp {
	VK_BLEND_OP_ADD = 0,
	VK_BLEND_OP_SUBTRACT = 1,
	VK_BLEND_OP_REVERSE_SUBTRACT = 2,
	VK_BLEND_OP_MIN = 3,
	VK_BLEND_OP_MAX = 4,
	VK_BLEND_OP_BEGIN_RANGE = VK_BLEND_OP_ADD,
	VK_BLEND_OP_END_RANGE = VK_BLEND_OP_MAX,
	VK_BLEND_OP_RANGE_SIZE = (VK_BLEND_OP_MAX - VK_BLEND_OP_ADD + 1),
	VK_BLEND_OP_MAX_ENUM = 0x7FFFFFFF,
}
enum VkColorComponentFlagBits {
	VK_COLOR_COMPONENT_R_BIT = 0x00000001,
	VK_COLOR_COMPONENT_G_BIT = 0x00000002,
	VK_COLOR_COMPONENT_B_BIT = 0x00000004,
	VK_COLOR_COMPONENT_A_BIT = 0x00000008,
}
alias VkColorComponentFlags = VkFlags;
struct VkPipelineColorBlendAttachmentState {
	VkBool32 blendEnable;
	VkBlendFactor srcColorBlendFactor;
	VkBlendFactor dstColorBlendFactor;
	VkBlendOp colorBlendOp;
	VkBlendFactor srcAlphaBlendFactor;
	VkBlendFactor dstAlphaBlendFactor;
	VkBlendOp alphaBlendOp;
	VkColorComponentFlags colorWriteMask;
}
struct VkPipelineColorBlendStateCreateInfo {
	VkStructureType sType;
	const(void)* pNext;
	VkPipelineColorBlendStateCreateFlags flags;
	VkBool32 logicOpEnable;
	VkLogicOp logicOp;
	uint32_t attachmentCount;
	const(VkPipelineColorBlendAttachmentState)* pAttachments;
	float blendConstants;
}
alias VkPipelineDynamicStateCreateFlags = VkFlags;
enum VkDynamicState {
	VK_DYNAMIC_STATE_VIEWPORT = 0,
	VK_DYNAMIC_STATE_SCISSOR = 1,
	VK_DYNAMIC_STATE_LINE_WIDTH = 2,
	VK_DYNAMIC_STATE_DEPTH_BIAS = 3,
	VK_DYNAMIC_STATE_BLEND_CONSTANTS = 4,
	VK_DYNAMIC_STATE_DEPTH_BOUNDS = 5,
	VK_DYNAMIC_STATE_STENCIL_COMPARE_MASK = 6,
	VK_DYNAMIC_STATE_STENCIL_WRITE_MASK = 7,
	VK_DYNAMIC_STATE_STENCIL_REFERENCE = 8,
	VK_DYNAMIC_STATE_BEGIN_RANGE = VK_DYNAMIC_STATE_VIEWPORT,
	VK_DYNAMIC_STATE_END_RANGE = VK_DYNAMIC_STATE_STENCIL_REFERENCE,
	VK_DYNAMIC_STATE_RANGE_SIZE = (VK_DYNAMIC_STATE_STENCIL_REFERENCE - VK_DYNAMIC_STATE_VIEWPORT + 1),
	VK_DYNAMIC_STATE_MAX_ENUM = 0x7FFFFFFF,
}
struct VkPipelineDynamicStateCreateInfo {
	VkStructureType sType;
	const(void)* pNext;
	VkPipelineDynamicStateCreateFlags flags;
	uint32_t dynamicStateCount;
	const(VkDynamicState)* pDynamicStates;
}
mixin(VK_DEFINE_NON_DISPATCHABLE_HANDLE!q{VkPipelineLayout});
mixin(VK_DEFINE_NON_DISPATCHABLE_HANDLE!q{VkRenderPass});
mixin(VK_DEFINE_NON_DISPATCHABLE_HANDLE!q{VkPipeline});
struct VkGraphicsPipelineCreateInfo {
	VkStructureType sType;
	const(void)* pNext;
	VkPipelineCreateFlags flags;
	uint32_t stageCount;
	const(VkPipelineShaderStageCreateInfo)* pStages;
	const(VkPipelineVertexInputStateCreateInfo)* pVertexInputState;
	const(VkPipelineInputAssemblyStateCreateInfo)* pInputAssemblyState;
	const(VkPipelineTessellationStateCreateInfo)* pTessellationState;
	const(VkPipelineViewportStateCreateInfo)* pViewportState;
	const(VkPipelineRasterizationStateCreateInfo)* pRasterizationState;
	const(VkPipelineMultisampleStateCreateInfo)* pMultisampleState;
	const(VkPipelineDepthStencilStateCreateInfo)* pDepthStencilState;
	const(VkPipelineColorBlendStateCreateInfo)* pColorBlendState;
	const(VkPipelineDynamicStateCreateInfo)* pDynamicState;
	VkPipelineLayout layout;
	VkRenderPass renderPass;
	uint32_t subpass;
	VkPipeline basePipelineHandle;
	int32_t basePipelineIndex;
}
struct VkComputePipelineCreateInfo {
	VkStructureType sType;
	const(void)* pNext;
	VkPipelineCreateFlags flags;
	VkPipelineShaderStageCreateInfo stage;
	VkPipelineLayout layout;
	VkPipeline basePipelineHandle;
	int32_t basePipelineIndex;
}
alias VkPipelineLayoutCreateFlags = VkFlags;
mixin(VK_DEFINE_NON_DISPATCHABLE_HANDLE!q{VkDescriptorSetLayout});
alias VkShaderStageFlags = VkFlags;
struct VkPushConstantRange {
	VkShaderStageFlags stageFlags;
	uint32_t offset;
	uint32_t size;
}
struct VkPipelineLayoutCreateInfo {
	VkStructureType sType;
	const(void)* pNext;
	VkPipelineLayoutCreateFlags flags;
	uint32_t setLayoutCount;
	const(VkDescriptorSetLayout)* pSetLayouts;
	uint32_t pushConstantRangeCount;
	const(VkPushConstantRange)* pPushConstantRanges;
}
alias VkSamplerCreateFlags = VkFlags;
enum VkFilter {
	VK_FILTER_NEAREST = 0,
	VK_FILTER_LINEAR = 1,
	VK_FILTER_CUBIC_IMG = 1000015000,
	VK_FILTER_BEGIN_RANGE = VK_FILTER_NEAREST,
	VK_FILTER_END_RANGE = VK_FILTER_CUBIC_IMG,
	VK_FILTER_RANGE_SIZE = (VK_FILTER_CUBIC_IMG - VK_FILTER_NEAREST + 1),
	VK_FILTER_MAX_ENUM = 0x7FFFFFFF,
}
enum VkSamplerMipmapMode {
	VK_SAMPLER_MIPMAP_MODE_NEAREST = 0,
	VK_SAMPLER_MIPMAP_MODE_LINEAR = 1,
	VK_SAMPLER_MIPMAP_MODE_BEGIN_RANGE = VK_SAMPLER_MIPMAP_MODE_NEAREST,
	VK_SAMPLER_MIPMAP_MODE_END_RANGE = VK_SAMPLER_MIPMAP_MODE_LINEAR,
	VK_SAMPLER_MIPMAP_MODE_RANGE_SIZE = (VK_SAMPLER_MIPMAP_MODE_LINEAR - VK_SAMPLER_MIPMAP_MODE_NEAREST + 1),
	VK_SAMPLER_MIPMAP_MODE_MAX_ENUM = 0x7FFFFFFF,
}
enum VkSamplerAddressMode {
	VK_SAMPLER_ADDRESS_MODE_REPEAT = 0,
	VK_SAMPLER_ADDRESS_MODE_MIRRORED_REPEAT = 1,
	VK_SAMPLER_ADDRESS_MODE_CLAMP_TO_EDGE = 2,
	VK_SAMPLER_ADDRESS_MODE_CLAMP_TO_BORDER = 3,
	VK_SAMPLER_ADDRESS_MODE_MIRROR_CLAMP_TO_EDGE = 4,
	VK_SAMPLER_ADDRESS_MODE_BEGIN_RANGE = VK_SAMPLER_ADDRESS_MODE_REPEAT,
	VK_SAMPLER_ADDRESS_MODE_END_RANGE = VK_SAMPLER_ADDRESS_MODE_MIRROR_CLAMP_TO_EDGE,
	VK_SAMPLER_ADDRESS_MODE_RANGE_SIZE = (VK_SAMPLER_ADDRESS_MODE_MIRROR_CLAMP_TO_EDGE - VK_SAMPLER_ADDRESS_MODE_REPEAT + 1),
	VK_SAMPLER_ADDRESS_MODE_MAX_ENUM = 0x7FFFFFFF,
}
enum VkBorderColor {
	VK_BORDER_COLOR_FLOAT_TRANSPARENT_BLACK = 0,
	VK_BORDER_COLOR_INT_TRANSPARENT_BLACK = 1,
	VK_BORDER_COLOR_FLOAT_OPAQUE_BLACK = 2,
	VK_BORDER_COLOR_INT_OPAQUE_BLACK = 3,
	VK_BORDER_COLOR_FLOAT_OPAQUE_WHITE = 4,
	VK_BORDER_COLOR_INT_OPAQUE_WHITE = 5,
	VK_BORDER_COLOR_BEGIN_RANGE = VK_BORDER_COLOR_FLOAT_TRANSPARENT_BLACK,
	VK_BORDER_COLOR_END_RANGE = VK_BORDER_COLOR_INT_OPAQUE_WHITE,
	VK_BORDER_COLOR_RANGE_SIZE = (VK_BORDER_COLOR_INT_OPAQUE_WHITE - VK_BORDER_COLOR_FLOAT_TRANSPARENT_BLACK + 1),
	VK_BORDER_COLOR_MAX_ENUM = 0x7FFFFFFF,
}
struct VkSamplerCreateInfo {
	VkStructureType sType;
	const(void)* pNext;
	VkSamplerCreateFlags flags;
	VkFilter magFilter;
	VkFilter minFilter;
	VkSamplerMipmapMode mipmapMode;
	VkSamplerAddressMode addressModeU;
	VkSamplerAddressMode addressModeV;
	VkSamplerAddressMode addressModeW;
	float mipLodBias;
	VkBool32 anisotropyEnable;
	float maxAnisotropy;
	VkBool32 compareEnable;
	VkCompareOp compareOp;
	float minLod;
	float maxLod;
	VkBorderColor borderColor;
	VkBool32 unnormalizedCoordinates;
}
mixin(VK_DEFINE_NON_DISPATCHABLE_HANDLE!q{VkSampler});
alias VkDescriptorSetLayoutCreateFlags = VkFlags;
enum VkDescriptorType {
	VK_DESCRIPTOR_TYPE_SAMPLER = 0,
	VK_DESCRIPTOR_TYPE_COMBINED_IMAGE_SAMPLER = 1,
	VK_DESCRIPTOR_TYPE_SAMPLED_IMAGE = 2,
	VK_DESCRIPTOR_TYPE_STORAGE_IMAGE = 3,
	VK_DESCRIPTOR_TYPE_UNIFORM_TEXEL_BUFFER = 4,
	VK_DESCRIPTOR_TYPE_STORAGE_TEXEL_BUFFER = 5,
	VK_DESCRIPTOR_TYPE_UNIFORM_BUFFER = 6,
	VK_DESCRIPTOR_TYPE_STORAGE_BUFFER = 7,
	VK_DESCRIPTOR_TYPE_UNIFORM_BUFFER_DYNAMIC = 8,
	VK_DESCRIPTOR_TYPE_STORAGE_BUFFER_DYNAMIC = 9,
	VK_DESCRIPTOR_TYPE_INPUT_ATTACHMENT = 10,
	VK_DESCRIPTOR_TYPE_BEGIN_RANGE = VK_DESCRIPTOR_TYPE_SAMPLER,
	VK_DESCRIPTOR_TYPE_END_RANGE = VK_DESCRIPTOR_TYPE_INPUT_ATTACHMENT,
	VK_DESCRIPTOR_TYPE_RANGE_SIZE = (VK_DESCRIPTOR_TYPE_INPUT_ATTACHMENT - VK_DESCRIPTOR_TYPE_SAMPLER + 1),
	VK_DESCRIPTOR_TYPE_MAX_ENUM = 0x7FFFFFFF,
}
struct VkDescriptorSetLayoutBinding {
	uint32_t binding;
	VkDescriptorType descriptorType;
	uint32_t descriptorCount;
	VkShaderStageFlags stageFlags;
	const(VkSampler)* pImmutableSamplers;
}
struct VkDescriptorSetLayoutCreateInfo {
	VkStructureType sType;
	const(void)* pNext;
	VkDescriptorSetLayoutCreateFlags flags;
	uint32_t bindingCount;
	const(VkDescriptorSetLayoutBinding)* pBindings;
}
enum VkDescriptorPoolCreateFlagBits {
	VK_DESCRIPTOR_POOL_CREATE_FREE_DESCRIPTOR_SET_BIT = 0x00000001,
}
alias VkDescriptorPoolCreateFlags = VkFlags;
struct VkDescriptorPoolSize {
	VkDescriptorType type;
	uint32_t descriptorCount;
}
struct VkDescriptorPoolCreateInfo {
	VkStructureType sType;
	const(void)* pNext;
	VkDescriptorPoolCreateFlags flags;
	uint32_t maxSets;
	uint32_t poolSizeCount;
	const(VkDescriptorPoolSize)* pPoolSizes;
}
mixin(VK_DEFINE_NON_DISPATCHABLE_HANDLE!q{VkDescriptorPool});
alias VkDescriptorPoolResetFlags = VkFlags;
struct VkDescriptorSetAllocateInfo {
	VkStructureType sType;
	const(void)* pNext;
	VkDescriptorPool descriptorPool;
	uint32_t descriptorSetCount;
	const(VkDescriptorSetLayout)* pSetLayouts;
}
mixin(VK_DEFINE_NON_DISPATCHABLE_HANDLE!q{VkDescriptorSet});
struct VkDescriptorImageInfo {
	VkSampler sampler;
	VkImageView imageView;
	VkImageLayout imageLayout;
}
struct VkDescriptorBufferInfo {
	VkBuffer buffer;
	VkDeviceSize offset;
	VkDeviceSize range;
}
struct VkWriteDescriptorSet {
	VkStructureType sType;
	const(void)* pNext;
	VkDescriptorSet dstSet;
	uint32_t dstBinding;
	uint32_t dstArrayElement;
	uint32_t descriptorCount;
	VkDescriptorType descriptorType;
	const(VkDescriptorImageInfo)* pImageInfo;
	const(VkDescriptorBufferInfo)* pBufferInfo;
	const(VkBufferView)* pTexelBufferView;
}
struct VkCopyDescriptorSet {
	VkStructureType sType;
	const(void)* pNext;
	VkDescriptorSet srcSet;
	uint32_t srcBinding;
	uint32_t srcArrayElement;
	VkDescriptorSet dstSet;
	uint32_t dstBinding;
	uint32_t dstArrayElement;
	uint32_t descriptorCount;
}
alias VkFramebufferCreateFlags = VkFlags;
struct VkFramebufferCreateInfo {
	VkStructureType sType;
	const(void)* pNext;
	VkFramebufferCreateFlags flags;
	VkRenderPass renderPass;
	uint32_t attachmentCount;
	const(VkImageView)* pAttachments;
	uint32_t width;
	uint32_t height;
	uint32_t layers;
}
mixin(VK_DEFINE_NON_DISPATCHABLE_HANDLE!q{VkFramebuffer});
alias VkRenderPassCreateFlags = VkFlags;
enum VkAttachmentDescriptionFlagBits {
	VK_ATTACHMENT_DESCRIPTION_MAY_ALIAS_BIT = 0x00000001,
}
alias VkAttachmentDescriptionFlags = VkFlags;
enum VkAttachmentLoadOp {
	VK_ATTACHMENT_LOAD_OP_LOAD = 0,
	VK_ATTACHMENT_LOAD_OP_CLEAR = 1,
	VK_ATTACHMENT_LOAD_OP_DONT_CARE = 2,
	VK_ATTACHMENT_LOAD_OP_BEGIN_RANGE = VK_ATTACHMENT_LOAD_OP_LOAD,
	VK_ATTACHMENT_LOAD_OP_END_RANGE = VK_ATTACHMENT_LOAD_OP_DONT_CARE,
	VK_ATTACHMENT_LOAD_OP_RANGE_SIZE = (VK_ATTACHMENT_LOAD_OP_DONT_CARE - VK_ATTACHMENT_LOAD_OP_LOAD + 1),
	VK_ATTACHMENT_LOAD_OP_MAX_ENUM = 0x7FFFFFFF,
}
enum VkAttachmentStoreOp {
	VK_ATTACHMENT_STORE_OP_STORE = 0,
	VK_ATTACHMENT_STORE_OP_DONT_CARE = 1,
	VK_ATTACHMENT_STORE_OP_BEGIN_RANGE = VK_ATTACHMENT_STORE_OP_STORE,
	VK_ATTACHMENT_STORE_OP_END_RANGE = VK_ATTACHMENT_STORE_OP_DONT_CARE,
	VK_ATTACHMENT_STORE_OP_RANGE_SIZE = (VK_ATTACHMENT_STORE_OP_DONT_CARE - VK_ATTACHMENT_STORE_OP_STORE + 1),
	VK_ATTACHMENT_STORE_OP_MAX_ENUM = 0x7FFFFFFF,
}
struct VkAttachmentDescription {
	VkAttachmentDescriptionFlags flags;
	VkFormat format;
	VkSampleCountFlagBits samples;
	VkAttachmentLoadOp loadOp;
	VkAttachmentStoreOp storeOp;
	VkAttachmentLoadOp stencilLoadOp;
	VkAttachmentStoreOp stencilStoreOp;
	VkImageLayout initialLayout;
	VkImageLayout finalLayout;
}
alias VkSubpassDescriptionFlags = VkFlags;
enum VkPipelineBindPoint {
	VK_PIPELINE_BIND_POINT_GRAPHICS = 0,
	VK_PIPELINE_BIND_POINT_COMPUTE = 1,
	VK_PIPELINE_BIND_POINT_BEGIN_RANGE = VK_PIPELINE_BIND_POINT_GRAPHICS,
	VK_PIPELINE_BIND_POINT_END_RANGE = VK_PIPELINE_BIND_POINT_COMPUTE,
	VK_PIPELINE_BIND_POINT_RANGE_SIZE = (VK_PIPELINE_BIND_POINT_COMPUTE - VK_PIPELINE_BIND_POINT_GRAPHICS + 1),
	VK_PIPELINE_BIND_POINT_MAX_ENUM = 0x7FFFFFFF,
}
struct VkAttachmentReference {
	uint32_t attachment;
	VkImageLayout layout;
}
struct VkSubpassDescription {
	VkSubpassDescriptionFlags flags;
	VkPipelineBindPoint pipelineBindPoint;
	uint32_t inputAttachmentCount;
	const(VkAttachmentReference)* pInputAttachments;
	uint32_t colorAttachmentCount;
	const(VkAttachmentReference)* pColorAttachments;
	const(VkAttachmentReference)* pResolveAttachments;
	const(VkAttachmentReference)* pDepthStencilAttachment;
	uint32_t preserveAttachmentCount;
	const(uint32_t)* pPreserveAttachments;
}
enum VkAccessFlagBits {
	VK_ACCESS_INDIRECT_COMMAND_READ_BIT = 0x00000001,
	VK_ACCESS_INDEX_READ_BIT = 0x00000002,
	VK_ACCESS_VERTEX_ATTRIBUTE_READ_BIT = 0x00000004,
	VK_ACCESS_UNIFORM_READ_BIT = 0x00000008,
	VK_ACCESS_INPUT_ATTACHMENT_READ_BIT = 0x00000010,
	VK_ACCESS_SHADER_READ_BIT = 0x00000020,
	VK_ACCESS_SHADER_WRITE_BIT = 0x00000040,
	VK_ACCESS_COLOR_ATTACHMENT_READ_BIT = 0x00000080,
	VK_ACCESS_COLOR_ATTACHMENT_WRITE_BIT = 0x00000100,
	VK_ACCESS_DEPTH_STENCIL_ATTACHMENT_READ_BIT = 0x00000200,
	VK_ACCESS_DEPTH_STENCIL_ATTACHMENT_WRITE_BIT = 0x00000400,
	VK_ACCESS_TRANSFER_READ_BIT = 0x00000800,
	VK_ACCESS_TRANSFER_WRITE_BIT = 0x00001000,
	VK_ACCESS_HOST_READ_BIT = 0x00002000,
	VK_ACCESS_HOST_WRITE_BIT = 0x00004000,
	VK_ACCESS_MEMORY_READ_BIT = 0x00008000,
	VK_ACCESS_MEMORY_WRITE_BIT = 0x00010000,
}
alias VkAccessFlags = VkFlags;
enum VkDependencyFlagBits {
	VK_DEPENDENCY_BY_REGION_BIT = 0x00000001,
}
alias VkDependencyFlags = VkFlags;
struct VkSubpassDependency {
	uint32_t srcSubpass;
	uint32_t dstSubpass;
	VkPipelineStageFlags srcStageMask;
	VkPipelineStageFlags dstStageMask;
	VkAccessFlags srcAccessMask;
	VkAccessFlags dstAccessMask;
	VkDependencyFlags dependencyFlags;
}
struct VkRenderPassCreateInfo {
	VkStructureType sType;
	const(void)* pNext;
	VkRenderPassCreateFlags flags;
	uint32_t attachmentCount;
	const(VkAttachmentDescription)* pAttachments;
	uint32_t subpassCount;
	const(VkSubpassDescription)* pSubpasses;
	uint32_t dependencyCount;
	const(VkSubpassDependency)* pDependencies;
}
enum VkCommandPoolCreateFlagBits {
	VK_COMMAND_POOL_CREATE_TRANSIENT_BIT = 0x00000001,
	VK_COMMAND_POOL_CREATE_RESET_COMMAND_BUFFER_BIT = 0x00000002,
}
alias VkCommandPoolCreateFlags = VkFlags;
struct VkCommandPoolCreateInfo {
	VkStructureType sType;
	const(void)* pNext;
	VkCommandPoolCreateFlags flags;
	uint32_t queueFamilyIndex;
}
mixin(VK_DEFINE_NON_DISPATCHABLE_HANDLE!q{VkCommandPool});
enum VkCommandPoolResetFlagBits {
	VK_COMMAND_POOL_RESET_RELEASE_RESOURCES_BIT = 0x00000001,
}
alias VkCommandPoolResetFlags = VkFlags;
enum VkCommandBufferLevel {
	VK_COMMAND_BUFFER_LEVEL_PRIMARY = 0,
	VK_COMMAND_BUFFER_LEVEL_SECONDARY = 1,
	VK_COMMAND_BUFFER_LEVEL_BEGIN_RANGE = VK_COMMAND_BUFFER_LEVEL_PRIMARY,
	VK_COMMAND_BUFFER_LEVEL_END_RANGE = VK_COMMAND_BUFFER_LEVEL_SECONDARY,
	VK_COMMAND_BUFFER_LEVEL_RANGE_SIZE = (VK_COMMAND_BUFFER_LEVEL_SECONDARY - VK_COMMAND_BUFFER_LEVEL_PRIMARY + 1),
	VK_COMMAND_BUFFER_LEVEL_MAX_ENUM = 0x7FFFFFFF,
}
struct VkCommandBufferAllocateInfo {
	VkStructureType sType;
	const(void)* pNext;
	VkCommandPool commandPool;
	VkCommandBufferLevel level;
	uint32_t commandBufferCount;
}
enum VkCommandBufferUsageFlagBits {
	VK_COMMAND_BUFFER_USAGE_ONE_TIME_SUBMIT_BIT = 0x00000001,
	VK_COMMAND_BUFFER_USAGE_RENDER_PASS_CONTINUE_BIT = 0x00000002,
	VK_COMMAND_BUFFER_USAGE_SIMULTANEOUS_USE_BIT = 0x00000004,
}
alias VkCommandBufferUsageFlags = VkFlags;
enum VkQueryControlFlagBits {
	VK_QUERY_CONTROL_PRECISE_BIT = 0x00000001,
}
alias VkQueryControlFlags = VkFlags;
struct VkCommandBufferInheritanceInfo {
	VkStructureType sType;
	const(void)* pNext;
	VkRenderPass renderPass;
	uint32_t subpass;
	VkFramebuffer framebuffer;
	VkBool32 occlusionQueryEnable;
	VkQueryControlFlags queryFlags;
	VkQueryPipelineStatisticFlags pipelineStatistics;
}
struct VkCommandBufferBeginInfo {
	VkStructureType sType;
	const(void)* pNext;
	VkCommandBufferUsageFlags flags;
	const(VkCommandBufferInheritanceInfo)* pInheritanceInfo;
}
enum VkCommandBufferResetFlagBits {
	VK_COMMAND_BUFFER_RESET_RELEASE_RESOURCES_BIT = 0x00000001,
}
alias VkCommandBufferResetFlags = VkFlags;
enum VkStencilFaceFlagBits {
	VK_STENCIL_FACE_FRONT_BIT = 0x00000001,
	VK_STENCIL_FACE_BACK_BIT = 0x00000002,
	VK_STENCIL_FRONT_AND_BACK = 0x00000003,
}
alias VkStencilFaceFlags = VkFlags;
enum VkIndexType {
	VK_INDEX_TYPE_UINT16 = 0,
	VK_INDEX_TYPE_UINT32 = 1,
	VK_INDEX_TYPE_BEGIN_RANGE = VK_INDEX_TYPE_UINT16,
	VK_INDEX_TYPE_END_RANGE = VK_INDEX_TYPE_UINT32,
	VK_INDEX_TYPE_RANGE_SIZE = (VK_INDEX_TYPE_UINT32 - VK_INDEX_TYPE_UINT16 + 1),
	VK_INDEX_TYPE_MAX_ENUM = 0x7FFFFFFF,
}
struct VkBufferCopy {
	VkDeviceSize srcOffset;
	VkDeviceSize dstOffset;
	VkDeviceSize size;
}
struct VkImageSubresourceLayers {
	VkImageAspectFlags aspectMask;
	uint32_t mipLevel;
	uint32_t baseArrayLayer;
	uint32_t layerCount;
}
struct VkImageCopy {
	VkImageSubresourceLayers srcSubresource;
	VkOffset3D srcOffset;
	VkImageSubresourceLayers dstSubresource;
	VkOffset3D dstOffset;
	VkExtent3D extent;
}
struct VkImageBlit {
	VkImageSubresourceLayers srcSubresource;
	VkOffset3D[2] srcOffsets;
	VkImageSubresourceLayers dstSubresource;
	VkOffset3D[2] dstOffsets;
}
struct VkBufferImageCopy {
	VkDeviceSize bufferOffset;
	uint32_t bufferRowLength;
	uint32_t bufferImageHeight;
	VkImageSubresourceLayers imageSubresource;
	VkOffset3D imageOffset;
	VkExtent3D imageExtent;
}
union VkClearColorValue {
	float float32;
	int32_t int32;
	uint32_t uint32;
}
struct VkClearDepthStencilValue {
	float depth;
	uint32_t stencil;
}
union VkClearValue {
	VkClearColorValue color;
	VkClearDepthStencilValue depthStencil;
}
struct VkClearAttachment {
	VkImageAspectFlags aspectMask;
	uint32_t colorAttachment;
	VkClearValue clearValue;
}
struct VkClearRect {
	VkRect2D rect;
	uint32_t baseArrayLayer;
	uint32_t layerCount;
}
struct VkImageResolve {
	VkImageSubresourceLayers srcSubresource;
	VkOffset3D srcOffset;
	VkImageSubresourceLayers dstSubresource;
	VkOffset3D dstOffset;
	VkExtent3D extent;
}
struct VkMemoryBarrier {
	VkStructureType sType;
	const(void)* pNext;
	VkAccessFlags srcAccessMask;
	VkAccessFlags dstAccessMask;
}
struct VkBufferMemoryBarrier {
	VkStructureType sType;
	const(void)* pNext;
	VkAccessFlags srcAccessMask;
	VkAccessFlags dstAccessMask;
	uint32_t srcQueueFamilyIndex;
	uint32_t dstQueueFamilyIndex;
	VkBuffer buffer;
	VkDeviceSize offset;
	VkDeviceSize size;
}
struct VkImageMemoryBarrier {
	VkStructureType sType;
	const(void)* pNext;
	VkAccessFlags srcAccessMask;
	VkAccessFlags dstAccessMask;
	VkImageLayout oldLayout;
	VkImageLayout newLayout;
	uint32_t srcQueueFamilyIndex;
	uint32_t dstQueueFamilyIndex;
	VkImage image;
	VkImageSubresourceRange subresourceRange;
}
struct VkRenderPassBeginInfo {
	VkStructureType sType;
	const(void)* pNext;
	VkRenderPass renderPass;
	VkFramebuffer framebuffer;
	VkRect2D renderArea;
	uint32_t clearValueCount;
	const(VkClearValue)* pClearValues;
}
enum VkSubpassContents {
	VK_SUBPASS_CONTENTS_INLINE = 0,
	VK_SUBPASS_CONTENTS_SECONDARY_COMMAND_BUFFERS = 1,
	VK_SUBPASS_CONTENTS_BEGIN_RANGE = VK_SUBPASS_CONTENTS_INLINE,
	VK_SUBPASS_CONTENTS_END_RANGE = VK_SUBPASS_CONTENTS_SECONDARY_COMMAND_BUFFERS,
	VK_SUBPASS_CONTENTS_RANGE_SIZE = (VK_SUBPASS_CONTENTS_SECONDARY_COMMAND_BUFFERS - VK_SUBPASS_CONTENTS_INLINE + 1),
	VK_SUBPASS_CONTENTS_MAX_ENUM = 0x7FFFFFFF,
}
struct VkDispatchIndirectCommand {
	uint32_t x;
	uint32_t y;
	uint32_t z;
}
struct VkDrawIndexedIndirectCommand {
	uint32_t indexCount;
	uint32_t instanceCount;
	uint32_t firstIndex;
	int32_t vertexOffset;
	uint32_t firstInstance;
}
struct VkDrawIndirectCommand {
	uint32_t vertexCount;
	uint32_t instanceCount;
	uint32_t firstVertex;
	uint32_t firstInstance;
}
