module vulkan_wayland;

// to your projects dub.sdl add:
// dependency "wayland:client" version = "~>0.1.0"
public import wayland.native.client;
import erupted.platform_extensions;

// the mixed in code requires structs wl_display and wl_surface
// the later one is named differently in the dependency
// and we need t alias its name:
alias wl_surface = wl_proxy;

// mixin platform code
// drop VK_ prefix of extensions and/or platform protections
mixin Platform_Extensions!USE_PLATFORM_WAYLAND_KHR;