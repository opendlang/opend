module vulkan_xlib;

// to your projects dub.sdl add:
// dependency "xlib-d" version = "~>0.1.1"
public import X11.Xlib;
import erupted.platform_extensions;

// mixin platform code
// drop VK_ prefix of extensions and/or platform protections
mixin Platform_Extensions!USE_PLATFORM_XLIB_KHR;