nothrow @nogc:

// dub run erupted:computeBC --compiler=ldc2
// use Vulkan Configurator (on windows vkconfig.exe) to enable debug layers

import core.stdc.stdio;
import erupted;



int main() {

    version( D_BetterC )
        printf( "\n\nUsing betterC" );

    scope( exit ) printf( "\n\n" );

    ubyte[128]  temp_mem;
    ubyte*      temp_ptr = temp_mem.ptr;

    // load global level functions
    import erupted.vulkan_lib_loader;   // not part of erupted package, as not part of original vulkan
    loadGlobalLevelFunctions;



    //
    // Instance
    //

    // check the available implementation max api version, for our purpose v1.0.0 is sufficient,
    // but if a higher version is required this would be the way to check it (example with v1.2.0)
    uint32_t api_version;
    vkEnumerateInstanceVersion( & api_version );
    printf( "\n\nAvailable Vulkan API version: v%u.%u.%u",
        VK_VERSION_MAJOR( api_version ), VK_VERSION_MINOR( api_version ), VK_VERSION_PATCH( api_version ));

    {
        // change the version here to your needs
        uint min_version = VK_MAKE_VERSION( 1, 0, 0 );
        if( api_version >= min_version )
            api_version  = min_version;
        else {
            printf( "\nAvailable Vulkan API version lower then required: v%u.%u.%u, quitting!\n",
                VK_VERSION_MAJOR( min_version ), VK_VERSION_MINOR( min_version ), VK_VERSION_PATCH( min_version ));
            return 1;
        }
    }

    // prepare VkInstance creation
    VkApplicationInfo application_info = {
        pApplicationName    : "Vulkan Compute Example",
        applicationVersion  : VK_MAKE_VERSION( 0, 1, 0 ),
        apiVersion          : VK_MAKE_VERSION( 1, 2, 0 ),
    };

    VkInstanceCreateInfo instance_ci = {
        pApplicationInfo    : & application_info,
    };

    // create the vulkan instance
    VkInstance instance;
    if( vkCreateInstance( & instance_ci, null, & instance )
        .vkAssert( "Could not create instance, quitting!",  "\nInstance created" ) != VK_SUCCESS )
        return 1;

    // destroy the instance at scope exist
    scope( exit ) {
        printf( "\nscope exit: destroying instance" );
        vkDestroyInstance( instance, null );
    }

    // load instance level functions
    loadInstanceLevelFunctions( instance );



    //
    // Physical Device (GPU)
    //

    // enumerate physical devices
    uint physical_device_count;
    if( vkEnumeratePhysicalDevices( instance, & physical_device_count, null )
        .vkAssert( "Could not enumerate physical devices, quitting!" ) != VK_SUCCESS )
        return 1;

    if( physical_device_count == 0 ) {
        stderr.fprintf( "\nNo physical devices available." );
        return 1;
    }

    {
        const( char )* devic_, uline_;
        if( physical_device_count == 1 )    { devic_ = "e";  uline_ = "=";  }
        else                                { devic_ = "es"; uline_ = "=="; }
        printf( "\n\nFound %u physical devic%s\n======================%s\n", physical_device_count, devic_, uline_ );
    }

    // acquire physical devices
    VkPhysicalDevice physical_device;
    {
        VkPhysicalDevice[] physical_devices = ( cast( VkPhysicalDevice* )temp_ptr )[ 0 .. physical_device_count ];
        vkEnumeratePhysicalDevices( instance, & physical_device_count, physical_devices.ptr ).vkAssert;

        // select physical device who's major and minor version is equal to the API version major and minor, but with the highest patch version
        uint32_t selected_api_version = 0;

        // print information about physical devices
        foreach( i, phys_device; physical_devices ) {
            VkPhysicalDeviceProperties properties;
            vkGetPhysicalDeviceProperties( phys_device, & properties );
            printf( "\nPhysical device %llu : %s", i, properties.deviceName.ptr );
            printf( "\nAPI Version: %u.%u.%u", VK_VERSION_MAJOR( properties.apiVersion ), VK_VERSION_MINOR( properties.apiVersion ), VK_VERSION_PATCH( properties.apiVersion ) );
            printf( "\nDriver Version: %u", properties.driverVersion );
            printf( "\nDevice type: %s", properties.deviceType.toStringz );
            printf( "\n" );

            // for simplicity the first found physical device of our selected API version will be used
            if( selected_api_version < properties.apiVersion && api_version < properties.apiVersion ) {
                selected_api_version = properties.apiVersion;
                physical_device = phys_device;
            }
        }

        if( physical_device == VK_NULL_HANDLE ) {
            printf( "\nCould not find suitable physical device matching requested version, qutting!\n" );
        }

        printf( "\nChosing physical device closest to our selected API major.minor version: v%u.%u.%u\n",
            VK_VERSION_MAJOR( selected_api_version ), VK_VERSION_MINOR( selected_api_version ), VK_VERSION_PATCH( selected_api_version ));
    }



    //
    // Queue ...
    //

    // enumerate queues of first physical device
    uint queue_count;
    vkGetPhysicalDeviceQueueFamilyProperties( physical_device, & queue_count, null );
    assert( queue_count >= 1 );

    // find print information about queue families and find compute (only) queue family index
    uint queue_family_index = uint.max;
    {
        VkQueueFamilyProperties[] queueFamilyProperties = ( cast( VkQueueFamilyProperties* )temp_ptr )[ 0 .. queue_count ];
        vkGetPhysicalDeviceQueueFamilyProperties( physical_device, & queue_count, queueFamilyProperties.ptr );
        assert( queue_count >= 1 ); // queue_count can be different than the first time

        // we want compute family index, but prefer compute only (without graphics) index
        int comp_family_index = uint.max;
        int comp_only_family_index = uint.max;

        foreach( i, const ref properties; queueFamilyProperties ) {
            printf( "\nQueue Family %llu", i );
            printf( "\n\tQueues in Family         : %u", properties.queueCount );
            printf( "\n\tQueue timestampValidBits : %u", properties.timestampValidBits );

            if( properties.queueFlags & VK_QUEUE_GRAPHICS_BIT )
                printf( "\n\tVK_QUEUE_GRAPHICS_BIT" );

            if( properties.queueFlags & VK_QUEUE_COMPUTE_BIT ) {
                printf( "\n\tVK_QUEUE_COMPUTE_BIT" );
                if( comp_family_index == uint.max ) {
                    comp_family_index = cast( uint )i;
                }
            }

            if( properties.queueFlags & VK_QUEUE_TRANSFER_BIT )
                printf( "\n\tVK_QUEUE_TRANSFER_BIT" );

            if( properties.queueFlags & VK_QUEUE_SPARSE_BINDING_BIT )
                printf( "\n\tVK_QUEUE_SPARSE_BINDING_BIT" );

            printf( "\n" );

            // check for compute only
            if( comp_only_family_index == uint.max && ( properties.queueFlags & VK_QUEUE_COMPUTE_BIT ) && !( properties.queueFlags & VK_QUEUE_GRAPHICS_BIT ))
                comp_only_family_index = cast( uint )i;
        }

        // use the compute only family index if available
        if( comp_only_family_index < uint.max ) {
            printf( "\nVK_QUEUE_COMPUTE_BIT without VK_QUEUE_GRAPHICS_BIT found at queue family index %u", comp_only_family_index );
            printf( "\n================================================================================" );
            queue_family_index = comp_only_family_index;
        }

        // if no graphics queue family was found use the first available queue family
        else if( comp_family_index < uint.max ) {
            printf( "\nCombined VK_QUEUE_COMPUTE_BIT found at queue family index %u", comp_family_index );
            printf( "\n===========================================================" );
            queue_family_index = comp_family_index;
        }

        // otherwise we cannot continue
        else {
            printf( "\nNo VK_QUEUE_COMPUTE_BIT found, required compute capability not available. Quiting!" );
            return 1;
        }
        printf( "\n" );
    }

    // prepare VkDeviceQueueCreateInfo for logical device creation
    float[1] queue_priorities = [ 0.0f ];
    VkDeviceQueueCreateInfo queue_create_info = {
        queueCount        : 1,
        pQueuePriorities  : queue_priorities.ptr,
        queueFamilyIndex  : queue_family_index,
    };



    //
    // Logical Device
    //

    // prepare logical device creation
    VkDeviceCreateInfo device_ci = {
        queueCreateInfoCount : 1,
        pQueueCreateInfos    : & queue_create_info,
    };

    // create the logical device
    VkDevice device;
    if( vkCreateDevice( physical_device, & device_ci, null, & device )
        .vkAssert( "Could not create logical device, quitting!", "logical device created" ) != VK_SUCCESS )
        return 1;

    // destroy the device at scope exist
    scope( exit ) {
        printf( "\nscope exit: destroying logical device" );
        vkDestroyDevice( device, null );
    }

    // load all Vulkan functions for the device
    loadDeviceLevelFunctions( device );

    // alternatively load all Vulkan functions for all devices
    //loadDeviceLevelFunctions( instance );



    //
    // ... Queue (continued)
    //

    // get the graphics queue to submit command buffers
    VkQueue queue;
    vkGetDeviceQueue( device, queue_family_index, 0, & queue );
    printf( "\ngraphics queue retrieved" );



    //
    // Buffer for compute work
    //

    // create one compute destination buffer
    VkBufferCreateInfo buffer_ci = {
        flags   : 0,
        size    : 256 * float.sizeof,
        usage   : VK_BUFFER_USAGE_STORAGE_TEXEL_BUFFER_BIT
    };

    VkBuffer buffer;
    if( vkCreateBuffer( device, & buffer_ci, null, & buffer )
        .vkAssert( "Could not create storage texel buffer, quitting!", "storage texel buffer created" ) != VK_SUCCESS )
        return 1;

    // destroy the buffer at scope exist
    scope( exit ) {
        printf( "\nscope exit: destroying storage texel buffer" );
        vkDestroyBuffer( device, buffer, null );
    }

    // get the memory requirements for that buffer and define its memory property flags
    VkMemoryRequirements buffer_memory_requirements;
    vkGetBufferMemoryRequirements( device, buffer, & buffer_memory_requirements );

    VkMemoryPropertyFlags buffer_memory_property_flags
        = VK_MEMORY_PROPERTY_HOST_COHERENT_BIT
        | VK_MEMORY_PROPERTY_HOST_VISIBLE_BIT;

    uint32_t memory_type_bits  = buffer_memory_requirements.memoryTypeBits;
    uint32_t memory_type_index = uint.max;

    // get the memory properties of the selected device and search it for a suitable memory type
    VkPhysicalDeviceMemoryProperties physical_device_memory_properties;
    vkGetPhysicalDeviceMemoryProperties( physical_device, & physical_device_memory_properties );

    foreach( i; 0u .. physical_device_memory_properties.memoryTypeCount ) {
        VkMemoryType memory_type = physical_device_memory_properties.memoryTypes[i];
        if( memory_type_bits & 1 ) {
            if(( memory_type.propertyFlags & buffer_memory_property_flags ) == buffer_memory_property_flags ) {
                memory_type_index = i;
                break;
            }
        }
        memory_type_bits = memory_type_bits >> 1;
    }

    // we cannot continue if we did not find the required memory
    if( memory_type_index == uint.max ) {
        printf( "\nRequested host coherent and host visible storage texel buffer not available, quiting!" );
        return 1;
    } else {
        printf( "\nstorage texel buffer memory host coherent and host visible type found" );
    }

    // allocate memory for the buffer
    VkMemoryAllocateInfo memory_ai = {
        allocationSize  : buffer_memory_requirements.size,
        memoryTypeIndex : memory_type_index,
    };

    VkDeviceMemory buffer_memory;
    if( vkAllocateMemory( device, & memory_ai, null, & buffer_memory )
        .vkAssert( "Could not allocate storage texel buffer memory, quitting!", "storage texel buffer memory allocated" ) != VK_SUCCESS )
        return 1;

    // free the buffer memory at scope exist
    scope( exit ) {
        printf( "\nscope exit: freeing storage texel buffer memory" );
        vkFreeMemory( device, buffer_memory, null );
    }

    // bind the buffer to the newly created memory
    if( vkBindBufferMemory( device, buffer, buffer_memory, 0 )
        .vkAssert( "Could not bind storage texel buffer to its memory, quitting!", "storage texel buffer memory bound" ) != VK_SUCCESS )
        return 1;

    // map the buffer memory
    float[] mapped_buffer;
    {
        void* mapped_memory;
        if( vkMapMemory( device, buffer_memory, 0, buffer_memory_requirements.size, 0, & mapped_memory )
            .vkAssert( "Could not map storage texel buffer memory, quitting!", "storage texel buffer memory mapped" ) != VK_SUCCESS )
            return 1;

        mapped_buffer = ( cast( float* )mapped_memory )[ 0 .. 256 ];
    }

    // unmap the buffer memory at scope exist
    scope( exit ) {
        printf( "\nscope exit: unmapping storage texel buffer memory" );
        vkUnmapMemory( device, buffer_memory );
    }

    // initialize the mapped buffer data
    foreach( i, ref entry; mapped_buffer ) entry = i;

    // create buffer view to access the buffer in a shader
    VkBufferViewCreateInfo buffer_view_ci = {
        buffer  : buffer,
        format  : VK_FORMAT_R32_SFLOAT,
        range   : VK_WHOLE_SIZE,
    };

    VkBufferView buffer_view;
    if( vkCreateBufferView( device, & buffer_view_ci, null, & buffer_view )
        .vkAssert( "Could not create storage texel buffer view, quitting!", "storage texel buffer view created" ) != VK_SUCCESS )
        return 1;

    // destroy the buffer at scope exist
    scope( exit ) {
        printf( "\nscope exit: destroying storage texel buffer view" );
        vkDestroyBufferView( device, buffer_view, null );
    }



    //
    // Descriptor Layout / Pool / Set / Update
    //

    // create sescriptor set layout
    VkDescriptorSetLayoutBinding descriptor_set_layout_binding = {
        binding         : 0,
        descriptorType  : VK_DESCRIPTOR_TYPE_STORAGE_TEXEL_BUFFER,
        descriptorCount : 1,
        stageFlags      : VK_SHADER_STAGE_COMPUTE_BIT,
    };

    VkDescriptorSetLayoutCreateInfo descriptor_set_layout_ci = {
        bindingCount    : 1,
        pBindings       : & descriptor_set_layout_binding,
    };

    VkDescriptorSetLayout descriptor_set_layout;
    if( vkCreateDescriptorSetLayout( device, & descriptor_set_layout_ci, null, & descriptor_set_layout )
        .vkAssert( "Could not create descriptor set layout, quitting", "descriptor set layout created" ) != VK_SUCCESS )
        return 1;

    // destroy the descriptor set layout at scope exist
    scope( exit ) {
        printf( "\nscope exit: destroying descriptor set layout" );
        vkDestroyDescriptorSetLayout( device, descriptor_set_layout, null );
    }

    // create a descriptor pool
    VkDescriptorPoolSize descriptor_pool_size = {
        type            : VK_DESCRIPTOR_TYPE_STORAGE_TEXEL_BUFFER,
        descriptorCount : 1,
    };

    VkDescriptorPoolCreateInfo descriptor_pool_ci = {
        maxSets         : 1,
        poolSizeCount   : 1,
        pPoolSizes      : & descriptor_pool_size,
    };

    VkDescriptorPool descriptor_pool;
    if( vkCreateDescriptorPool( device, & descriptor_pool_ci, null, & descriptor_pool )
        .vkAssert( "Could not create descriptor pool, quitting!", "descriptor pool created" ) != VK_SUCCESS )
        return 1;

    // destroy the descriptor pool at scope exist
    scope( exit ) {
        printf( "\nscope exit: destroying descriptor pool" );
        vkDestroyDescriptorPool( device, descriptor_pool, null );
    }

    // allocate a descriptor set
    VkDescriptorSetAllocateInfo descriptor_set_ai = {
        descriptorPool      : descriptor_pool,
        descriptorSetCount  : 1,
        pSetLayouts         : & descriptor_set_layout,
    };

    VkDescriptorSet descriptor_set;
    if( vkAllocateDescriptorSets( device, & descriptor_set_ai, & descriptor_set )
        .vkAssert( "Could not allocate descriptor set, quitting!", "descriptor set allocated" ) != VK_SUCCESS )
        return 1;

    // write the descriptor set with the compute buffer
    VkDescriptorBufferInfo descriptor_buffer_info = {
        buffer : buffer,
        range  : 256 * float.sizeof,
    };

    VkWriteDescriptorSet write_descriptor_set = {
        dstSet              : descriptor_set,
        descriptorCount     : 1,
        descriptorType      : VK_DESCRIPTOR_TYPE_STORAGE_TEXEL_BUFFER,
        pBufferInfo         : & descriptor_buffer_info,
        dstArrayElement     : 0,
        dstBinding          : 0,
        pTexelBufferView    : & buffer_view,
    };

    vkUpdateDescriptorSets( device, 1, & write_descriptor_set, 0, null );



    //
    // Compute Shader
    //

    VkShaderModule shader_module;
    {
        //
        // Compled shader compute.comp into uint32_t array, contained in ascii file compute.spv with:
        //
        // glslangValidator -V -x compute.comp -o compute.spv
        //
        uint[ 202 ] compute_shader_binary = [
            0x07230203, 0x00010000, 0x0008000a, 0x00000020, 0x00000000, 0x00020011, 0x00000001, 0x00020011,
            0x0000002f, 0x0006000b, 0x00000001, 0x4c534c47, 0x6474732e, 0x3035342e, 0x00000000, 0x0003000e,
            0x00000000, 0x00000001, 0x0006000f, 0x00000005, 0x00000004, 0x6e69616d, 0x00000000, 0x0000000e,
            0x00060010, 0x00000004, 0x00000011, 0x00000100, 0x00000001, 0x00000001, 0x00030003, 0x00000002,
            0x000001c2, 0x00040005, 0x00000004, 0x6e69616d, 0x00000000, 0x00060005, 0x00000009, 0x706d6f63,
            0x5f657475, 0x66667562, 0x00007265, 0x00080005, 0x0000000e, 0x475f6c67, 0x61626f6c, 0x766e496c,
            0x7461636f, 0x496e6f69, 0x00000044, 0x00040047, 0x00000009, 0x00000022, 0x00000000, 0x00040047,
            0x00000009, 0x00000021, 0x00000000, 0x00030047, 0x00000009, 0x00000013, 0x00040047, 0x0000000e,
            0x0000000b, 0x0000001c, 0x00040047, 0x0000001f, 0x0000000b, 0x00000019, 0x00020013, 0x00000002,
            0x00030021, 0x00000003, 0x00000002, 0x00030016, 0x00000006, 0x00000020, 0x00090019, 0x00000007,
            0x00000006, 0x00000005, 0x00000000, 0x00000000, 0x00000000, 0x00000002, 0x00000003, 0x00040020,
            0x00000008, 0x00000000, 0x00000007, 0x0004003b, 0x00000008, 0x00000009, 0x00000000, 0x00040015,
            0x0000000b, 0x00000020, 0x00000000, 0x00040017, 0x0000000c, 0x0000000b, 0x00000003, 0x00040020,
            0x0000000d, 0x00000001, 0x0000000c, 0x0004003b, 0x0000000d, 0x0000000e, 0x00000001, 0x0004002b,
            0x0000000b, 0x0000000f, 0x00000000, 0x00040020, 0x00000010, 0x00000001, 0x0000000b, 0x00040015,
            0x00000013, 0x00000020, 0x00000001, 0x0004002b, 0x00000006, 0x00000015, 0x3fc00000, 0x00040017,
            0x0000001a, 0x00000006, 0x00000004, 0x0004002b, 0x0000000b, 0x0000001d, 0x00000100, 0x0004002b,
            0x0000000b, 0x0000001e, 0x00000001, 0x0006002c, 0x0000000c, 0x0000001f, 0x0000001d, 0x0000001e,
            0x0000001e, 0x00050036, 0x00000002, 0x00000004, 0x00000000, 0x00000003, 0x000200f8, 0x00000005,
            0x0004003d, 0x00000007, 0x0000000a, 0x00000009, 0x00050041, 0x00000010, 0x00000011, 0x0000000e,
            0x0000000f, 0x0004003d, 0x0000000b, 0x00000012, 0x00000011, 0x0004007c, 0x00000013, 0x00000014,
            0x00000012, 0x0004003d, 0x00000007, 0x00000016, 0x00000009, 0x00050041, 0x00000010, 0x00000017,
            0x0000000e, 0x0000000f, 0x0004003d, 0x0000000b, 0x00000018, 0x00000017, 0x0004007c, 0x00000013,
            0x00000019, 0x00000018, 0x00050062, 0x0000001a, 0x0000001b, 0x00000016, 0x00000019, 0x0005008e,
            0x0000001a, 0x0000001c, 0x0000001b, 0x00000015, 0x00040063, 0x0000000a, 0x00000014, 0x0000001c,
            0x000100fd, 0x00010038
        ];

        VkShaderModuleCreateInfo shader_module_ci = {
            codeSize    : compute_shader_binary.sizeof,
            pCode       : compute_shader_binary.ptr,
        };

        if( vkCreateShaderModule( device, & shader_module_ci, null, & shader_module )
            .vkAssert( "Could not create shader module, quitting!", "shader module created" ) != VK_SUCCESS )
            return 1;
    }

    // destroy the shader module at scope exist
    scope( exit ) {
        printf( "\nscope exit: destroying shader module" );
        vkDestroyShaderModule( device, shader_module, null );
    }



    //
    // Compute Pipelin
    //

    VkPipelineLayoutCreateInfo pipeline_layout_ci = {
        setLayoutCount  : 1,
        pSetLayouts     : & descriptor_set_layout,
    };

    VkPipelineLayout pipeline_layout;
    if( vkCreatePipelineLayout( device, & pipeline_layout_ci, null, & pipeline_layout )
        .vkAssert( "Could not create pipeline layout, quitting!", "pipeline layout created" ) != VK_SUCCESS )
        return 1;

    VkComputePipelineCreateInfo compute_pipeline_ci = {
        stage   : /*VkPipelineShaderStageCreateInfo*/ {
            stage   : VK_SHADER_STAGE_COMPUTE_BIT,
            Module  : shader_module,
            pName   : "main"    // shader entry point
        },
        layout  : pipeline_layout,
    };

    VkPipeline compute_pso;
    if( vkCreateComputePipelines( device, VK_NULL_HANDLE, 1, & compute_pipeline_ci, null, & compute_pso )
        .vkAssert( "Could not create compute pipeline (PSO), quitting!", "compute pipeline (PSO) created" ) != VK_SUCCESS )
        return 1;

    // destroy the shader module at scope exist
    scope( exit ) {
        printf( "\nscope exit: destroying shader module" );
        vkDestroyPipeline( device, compute_pso, null );
    }



    //
    // Command Pool and Command Buffer
    //

    VkCommandPoolCreateInfo command_pool_ci = {
        queueFamilyIndex : queue_family_index,
    };

    VkCommandPool command_pool;
    if( vkCreateCommandPool( device, & command_pool_ci, null, & command_pool )
        .vkAssert( "Could not create command pool, quitting!" , "command pool created" ) != VK_SUCCESS )
        return 1;

    // destroy the command pool at scope exist
    scope( exit ) {
        printf( "\nscope exit: destroying command pool" );
        vkDestroyCommandPool( device, command_pool, null );
    }

    VkCommandBufferAllocateInfo command_buffer_ai = {
        commandPool         : command_pool,
        level               : VK_COMMAND_BUFFER_LEVEL_PRIMARY,
        commandBufferCount  : 1,
    };

    VkCommandBuffer cmd_buffer;
    if( vkAllocateCommandBuffers( device, & command_buffer_ai, & cmd_buffer )
        .vkAssert( "Could not allocate command buffer, quitting!", "command buffer allocated" ) != VK_SUCCESS )
        return 1;

    VkCommandBufferBeginInfo command_buffer_bi;
    cmd_buffer.vkBeginCommandBuffer( & command_buffer_bi );
    cmd_buffer.vkCmdBindPipeline( VK_PIPELINE_BIND_POINT_COMPUTE, compute_pso );
    cmd_buffer.vkCmdBindDescriptorSets(     // VkCommandBuffer              commandBuffer
        VK_PIPELINE_BIND_POINT_COMPUTE,     // VkPipelineBindPoint          pipelineBindPoint
        pipeline_layout,                    // VkPipelineLayout             layout
        0,                                  // uint32_t                     firstSet
        1,                                  // uint32_t                     descriptorSetCount
        & descriptor_set,                   // const( VkDescriptorSet )*    pDescriptorSets
        0,                                  // uint32_t                     dynamicOffsetCount
        null                                // const( uint32_t )*           pDynamicOffsets
    );
    cmd_buffer.vkCmdDispatch( 1, 1, 1 );    // dispatch compute command, we work on one small batch of 256 floats
    cmd_buffer.vkEndCommandBuffer;          // finish recording

    printf( "\ncommand buffer commands recorded" );

    VkSubmitInfo submit_info = {
        commandBufferCount  : 1,
        pCommandBuffers     : & cmd_buffer,
    };

    printf( "\n\nInput Data:\n===========" );
    foreach( i, entry; mapped_buffer ) {
        if(( i % 16 ) == 0 )    printf( "\n" );
        if( entry < 10 )        printf( "  " );
        else if( entry < 100 )  printf( " " );
        printf( "%3.1f, ", entry );
    }

    printf( "\n\nSubmitting compute work, multiply data by 1.5, to queue!" );
    queue.vkQueueSubmit( 1, & submit_info, VK_NULL_HANDLE );    // no need for a fence when we have a on-shot command ...
    queue.vkQueueWaitIdle;                                      // ... when can use vkQueueWaitIdle instead

    printf( "\n\nCompute Result:\n===============" );
    foreach( i, entry; mapped_buffer ) {
        if(( i % 16 ) == 0 )    printf( "\n" );
        if( entry < 10 )        printf( "  " );
        else if( entry < 100 )  printf( " " );
        printf( "%3.1f, ", entry );
    }



    printf( "\n\n=========================================" );
    printf( "\nDraining work and waiting for device idle" );
    printf( "\n=========================================\n" );
    vkDeviceWaitIdle( device );


    return 0;
}



//
// helper
//

VkResult vkAssert( VkResult vk_result, const( char* ) fail_msg = null, const( char* ) success_msg = null, string file = __FILE__, size_t line = __LINE__ ) {
    if( vk_result != VK_SUCCESS ) {
        char[ 256 ] file_stringz;
        file_stringz[ 0 .. file.length ] = file;
        file_stringz[ file.length ] = '\0';

        stderr.fprintf( "\n! ERROR !\n==============\n" );
        stderr.fprintf( "\tVkResult : %s\n", vk_result.toStringz );
        stderr.fprintf( "\tFile     : %s\n", file_stringz.ptr );
        stderr.fprintf( "\tLine     : %llu\n", line );

        if( fail_msg )
            stderr.fprintf( "\n%s\n", fail_msg );
    }
    if( success_msg != null )
        printf( "\n%s", success_msg );
    return vk_result;
}


const( char )* toStringz( VkResult vk_result ) {
    switch( vk_result ) {
        case VK_SUCCESS                            : return "VK_SUCCESS";
        case VK_NOT_READY                          : return "VK_NOT_READY";
        case VK_TIMEOUT                            : return "VK_TIMEOUT";
        case VK_EVENT_SET                          : return "VK_EVENT_SET";
        case VK_EVENT_RESET                        : return "VK_EVENT_RESET";
        case VK_INCOMPLETE                         : return "VK_INCOMPLETE";
        case VK_ERROR_OUT_OF_HOST_MEMORY           : return "VK_ERROR_OUT_OF_HOST_MEMORY";
        case VK_ERROR_OUT_OF_DEVICE_MEMORY         : return "VK_ERROR_OUT_OF_DEVICE_MEMORY";
        case VK_ERROR_INITIALIZATION_FAILED        : return "VK_ERROR_INITIALIZATION_FAILED";
        case VK_ERROR_DEVICE_LOST                  : return "VK_ERROR_DEVICE_LOST";
        case VK_ERROR_MEMORY_MAP_FAILED            : return "VK_ERROR_MEMORY_MAP_FAILED";
        case VK_ERROR_LAYER_NOT_PRESENT            : return "VK_ERROR_LAYER_NOT_PRESENT";
        case VK_ERROR_EXTENSION_NOT_PRESENT        : return "VK_ERROR_EXTENSION_NOT_PRESENT";
        case VK_ERROR_FEATURE_NOT_PRESENT          : return "VK_ERROR_FEATURE_NOT_PRESENT";
        case VK_ERROR_INCOMPATIBLE_DRIVER          : return "VK_ERROR_INCOMPATIBLE_DRIVER";
        case VK_ERROR_TOO_MANY_OBJECTS             : return "VK_ERROR_TOO_MANY_OBJECTS";
        case VK_ERROR_FORMAT_NOT_SUPPORTED         : return "VK_ERROR_FORMAT_NOT_SUPPORTED";
        case VK_ERROR_FRAGMENTED_POOL              : return "VK_ERROR_FRAGMENTED_POOL";
        case VK_ERROR_SURFACE_LOST_KHR             : return "VK_ERROR_SURFACE_LOST_KHR";
        case VK_ERROR_NATIVE_WINDOW_IN_USE_KHR     : return "VK_ERROR_NATIVE_WINDOW_IN_USE_KHR";
        case VK_SUBOPTIMAL_KHR                     : return "VK_SUBOPTIMAL_KHR";
        case VK_ERROR_OUT_OF_DATE_KHR              : return "VK_ERROR_OUT_OF_DATE_KHR";
        case VK_ERROR_INCOMPATIBLE_DISPLAY_KHR     : return "VK_ERROR_INCOMPATIBLE_DISPLAY_KHR";
        case VK_ERROR_VALIDATION_FAILED_EXT        : return "VK_ERROR_VALIDATION_FAILED_EXT";
        case VK_ERROR_INVALID_SHADER_NV            : return "VK_ERROR_INVALID_SHADER_NV";
        case VK_ERROR_OUT_OF_POOL_MEMORY_KHR       : return "VK_ERROR_OUT_OF_POOL_MEMORY_KHR";
        case VK_ERROR_INVALID_EXTERNAL_HANDLE_KHR  : return "VK_ERROR_INVALID_EXTERNAL_HANDLE_KHR";
        default                                    : return "UNKNOWN_RESULT";
    }
}


const( char )* toStringz( VkPhysicalDeviceType device_type ) {
    switch( device_type ) {
        case VK_PHYSICAL_DEVICE_TYPE_OTHER           : return "VK_PHYSICAL_DEVICE_TYPE_OTHER";
        case VK_PHYSICAL_DEVICE_TYPE_INTEGRATED_GPU  : return "VK_PHYSICAL_DEVICE_TYPE_INTEGRATED_GPU";
        case VK_PHYSICAL_DEVICE_TYPE_DISCRETE_GPU    : return "VK_PHYSICAL_DEVICE_TYPE_DISCRETE_GPU";
        case VK_PHYSICAL_DEVICE_TYPE_VIRTUAL_GPU     : return "VK_PHYSICAL_DEVICE_TYPE_VIRTUAL_GPU";
        case VK_PHYSICAL_DEVICE_TYPE_CPU             : return "VK_PHYSICAL_DEVICE_TYPE_CPU";
        default                                      : return "UNKNOWN_RESULT";
    }
}
