module vulkan_xcb;

// to your projects dub.sdl add:
// dependency "xcb-d" version = "~>2.1.0"
public import xcb.xcb;
import erupted.platform_extensions;

// mixin platform code
// drop VK_ prefix of extensions and/or platform protections
mixin Platform_Extensions!USE_PLATFORM_XCB_KHR;