module vulkan_windows;

// this module is in druntime
// no need for an external dependency
public import core.sys.windows.windows;
import erupted.platform_extensions;

// mixin platform code
// drop VK_ prefix of extensions and/or platform protections
mixin Platform_Extensions!USE_PLATFORM_WIN32_KHR;