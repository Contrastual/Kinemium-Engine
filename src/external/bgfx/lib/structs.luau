--!strict
--!optimize 2
--!native

local ffi = zune.ffi

-- Basic type aliases
local int = ffi.types.i32
local uint = ffi.types.u32
local bool = ffi.types.u8
local float = ffi.types.float
local double = ffi.types.double

local bgfx_allocator_interface_t = ffi.struct({
	{ vtbl = ffi.types.pointer },
})
export type bgfx_allocator_interface_t = typeof(bgfx_allocator_interface_t:new({}))

local bgfx_allocator_vtbl_t = ffi.struct({
	{ realloc = ffi.types.pointer },
})
export type bgfx_allocator_vtbl_t = typeof(bgfx_allocator_vtbl_t:new({}))

local bgfx_callback_interface_t = ffi.struct({
	{ vtbl = ffi.types.pointer },
})
export type bgfx_callback_interface_t = typeof(bgfx_callback_interface_t:new({}))

local bgfx_callback_vtbl_t = ffi.struct({
	{ fatal = ffi.types.pointer },
	{ trace_vargs = ffi.types.pointer },
	{ profiler_begin = ffi.types.pointer },
	{ profiler_begin_literal = ffi.types.pointer },
	{ profiler_end = ffi.types.pointer },
	{ cache_read_size = ffi.types.pointer },
	{ cache_read = ffi.types.pointer },
	{ cache_write = ffi.types.pointer },
	{ screen_shot = ffi.types.pointer },
	{ capture_begin = ffi.types.pointer },
	{ capture_end = ffi.types.pointer },
	{ capture_frame = ffi.types.pointer },
})
export type bgfx_callback_vtbl_t = typeof(bgfx_callback_vtbl_t:new({}))

local bgfx_dynamic_index_buffer_handle_t = ffi.struct({
	{ idx = ffi.types.u16 },
})
export type bgfx_dynamic_index_buffer_handle_t = typeof(bgfx_dynamic_index_buffer_handle_t:new({}))

local bgfx_dynamic_vertex_buffer_handle_t = ffi.struct({
	{ idx = ffi.types.u16 },
})
export type bgfx_dynamic_vertex_buffer_handle_t = typeof(bgfx_dynamic_vertex_buffer_handle_t:new({}))

local bgfx_frame_buffer_handle_t = ffi.struct({
	{ idx = ffi.types.u16 },
})
export type bgfx_frame_buffer_handle_t = typeof(bgfx_frame_buffer_handle_t:new({}))

local bgfx_index_buffer_handle_t = ffi.struct({
	{ idx = ffi.types.u16 },
})
export type bgfx_index_buffer_handle_t = typeof(bgfx_index_buffer_handle_t:new({}))

local bgfx_indirect_buffer_handle_t = ffi.struct({
	{ idx = ffi.types.u16 },
})
export type bgfx_indirect_buffer_handle_t = typeof(bgfx_indirect_buffer_handle_t:new({}))

local bgfx_occlusion_query_handle_t = ffi.struct({
	{ idx = ffi.types.u16 },
})
export type bgfx_occlusion_query_handle_t = typeof(bgfx_occlusion_query_handle_t:new({}))

local bgfx_program_handle_t = ffi.struct({
	{ idx = ffi.types.u16 },
})
export type bgfx_program_handle_t = typeof(bgfx_program_handle_t:new({}))

local bgfx_shader_handle_t = ffi.struct({
	{ idx = ffi.types.u16 },
})
export type bgfx_shader_handle_t = typeof(bgfx_shader_handle_t:new({}))

local bgfx_texture_handle_t = ffi.struct({
	{ idx = ffi.types.u16 },
})
export type bgfx_texture_handle_t = typeof(bgfx_texture_handle_t:new({}))

local bgfx_uniform_handle_t = ffi.struct({
	{ idx = ffi.types.u16 },
})
export type bgfx_uniform_handle_t = typeof(bgfx_uniform_handle_t:new({}))

local bgfx_vertex_buffer_handle_t = ffi.struct({
	{ idx = ffi.types.u16 },
})
export type bgfx_vertex_buffer_handle_t = typeof(bgfx_vertex_buffer_handle_t:new({}))

local bgfx_vertex_layout_handle_t = ffi.struct({
	{ idx = ffi.types.u16 },
})
export type bgfx_vertex_layout_handle_t = typeof(bgfx_vertex_layout_handle_t:new({}))

local bgfx_caps_gpu_t = ffi.struct({
	{ vendorId = ffi.types.u16 },
	{ deviceId = ffi.types.u16 },
})
export type bgfx_caps_gpu_t = typeof(bgfx_caps_gpu_t:new({}))

local bgfx_caps_limits_t = ffi.struct({
	{ maxDrawCalls = ffi.types.u32 },
	{ maxBlits = ffi.types.u32 },
	{ maxTextureSize = ffi.types.u32 },
	{ maxTextureLayers = ffi.types.u32 },
	{ maxViews = ffi.types.u32 },
	{ maxFrameBuffers = ffi.types.u32 },
	{ maxFBAttachments = ffi.types.u32 },
	{ maxPrograms = ffi.types.u32 },
	{ maxShaders = ffi.types.u32 },
	{ maxTextures = ffi.types.u32 },
	{ maxTextureSamplers = ffi.types.u32 },
	{ maxComputeBindings = ffi.types.u32 },
	{ maxVertexLayouts = ffi.types.u32 },
	{ maxVertexStreams = ffi.types.u32 },
	{ maxIndexBuffers = ffi.types.u32 },
	{ maxVertexBuffers = ffi.types.u32 },
	{ maxDynamicIndexBuffers = ffi.types.u32 },
	{ maxDynamicVertexBuffers = ffi.types.u32 },
	{ maxUniforms = ffi.types.u32 },
	{ maxOcclusionQueries = ffi.types.u32 },
	{ maxEncoders = ffi.types.u32 },
	{ minResourceCbSize = ffi.types.u32 },
	{ maxTransientVbSize = ffi.types.u32 },
	{ maxTansientIbSize = ffi.types.u32 },
	{ minUniformBufferSize = ffi.types.u32 },
})
export type bgfx_caps_limits_t = typeof(bgfx_caps_limits_t:new({}))

local bgfx_caps_t = ffi.struct({
	{ rendererType = ffi.types.pointer },
	{ supported = ffi.types.u64 },
	{ vendorId = ffi.types.u16 },
	{ deviceId = ffi.types.u16 },
	{ homogeneousDepth = ffi.types.u8 },
	{ originBottomLeft = ffi.types.u8 },
	{ numGPUs = ffi.types.u8 },
	{ gpu = ffi.types.pointer:array(4) },
	{ limits = bgfx_caps_limits_t },
})
export type bgfx_caps_t = typeof(bgfx_caps_t:new({}))

local bgfx_internal_data_t = ffi.struct({
	{ caps = ffi.types.pointer },
	{ context = ffi.types.pointer },
})
export type bgfx_internal_data_t = typeof(bgfx_internal_data_t:new({}))

local bgfx_platform_data_t = ffi.struct({
	{ ndt = ffi.types.pointer },
	{ nwh = ffi.types.pointer },
	{ context = ffi.types.pointer },
	{ queue = ffi.types.pointer },
	{ backBuffer = ffi.types.pointer },
	{ backBufferDS = ffi.types.pointer },
	{ type = ffi.types.pointer },
})
export type bgfx_platform_data_t = typeof(bgfx_platform_data_t:new({}))

local bgfx_resolution_t = ffi.struct({
	{ formatColor = ffi.types.pointer },
	{ formatDepthStencil = ffi.types.pointer },
	{ width = ffi.types.u32 },
	{ height = ffi.types.u32 },
	{ reset = ffi.types.u32 },
	{ numBackBuffers = ffi.types.u8 },
	{ maxFrameLatency = ffi.types.u8 },
	{ debugTextScale = ffi.types.u8 },
})
export type bgfx_resolution_t = typeof(bgfx_resolution_t:new({}))

local bgfx_init_limits_t = ffi.struct({
	{ maxEncoders = ffi.types.u16 },
	{ minResourceCbSize = ffi.types.u32 },
	{ maxTransientVbSize = ffi.types.u32 },
	{ maxTransientIbSize = ffi.types.u32 },
	{ minUniformBufferSize = ffi.types.u32 },
})
export type bgfx_init_limits_t = typeof(bgfx_init_limits_t:new({}))

local bgfx_init_t = ffi.struct({
	{ type = ffi.types.pointer },
	{ vendorId = ffi.types.u16 },
	{ deviceId = ffi.types.u16 },
	{ capabilities = ffi.types.u64 },
	{ debug = ffi.types.u8 },
	{ profile = ffi.types.u8 },
	{ fallback = ffi.types.u8 },
	{ platformData = bgfx_platform_data_t },
	{ resolution = bgfx_resolution_t },
	{ limits = bgfx_init_limits_t },
	{ callback = ffi.types.pointer },
	{ allocator = ffi.types.pointer },
})
export type bgfx_init_t = typeof(bgfx_init_t:new({}))

local bgfx_memory_t = ffi.struct({
	{ data = ffi.types.pointer },
	{ size = ffi.types.u32 },
})
export type bgfx_memory_t = typeof(bgfx_memory_t:new({}))

local bgfx_transient_index_buffer_t = ffi.struct({
	{ data = ffi.types.pointer },
	{ size = ffi.types.u32 },
	{ startIndex = ffi.types.u32 },
	{ handle = bgfx_index_buffer_handle_t },
	{ isIndex16 = ffi.types.u8 },
})
export type bgfx_transient_index_buffer_t = typeof(bgfx_transient_index_buffer_t:new({}))

local bgfx_transient_vertex_buffer_t = ffi.struct({
	{ data = ffi.types.pointer },
	{ size = ffi.types.u32 },
	{ startVertex = ffi.types.u32 },
	{ stride = ffi.types.u16 },
	{ handle = bgfx_vertex_buffer_handle_t },
	{ layoutHandle = bgfx_vertex_layout_handle_t },
})
export type bgfx_transient_vertex_buffer_t = typeof(bgfx_transient_vertex_buffer_t:new({}))

local bgfx_instance_data_buffer_t = ffi.struct({
	{ data = ffi.types.pointer },
	{ size = ffi.types.u32 },
	{ offset = ffi.types.u32 },
	{ num = ffi.types.u32 },
	{ stride = ffi.types.u16 },
	{ handle = bgfx_vertex_buffer_handle_t },
})
export type bgfx_instance_data_buffer_t = typeof(bgfx_instance_data_buffer_t:new({}))

local bgfx_texture_info_t = ffi.struct({
	{ format = ffi.types.pointer },
	{ storageSize = ffi.types.u32 },
	{ width = ffi.types.u16 },
	{ height = ffi.types.u16 },
	{ depth = ffi.types.u16 },
	{ numLayers = ffi.types.u16 },
	{ numMips = ffi.types.u8 },
	{ bitsPerPixel = ffi.types.u8 },
	{ cubeMap = ffi.types.u8 },
})
export type bgfx_texture_info_t = typeof(bgfx_texture_info_t:new({}))

local bgfx_uniform_info_t = ffi.struct({
	{ name = ffi.types.i8:array(256) },
	{ type = ffi.types.pointer },
	{ num = ffi.types.u16 },
})
export type bgfx_uniform_info_t = typeof(bgfx_uniform_info_t:new({}))

local bgfx_attachment_t = ffi.struct({
	{ access = ffi.types.pointer },
	{ handle = bgfx_texture_handle_t },
	{ mip = ffi.types.u16 },
	{ layer = ffi.types.u16 },
	{ numLayers = ffi.types.u16 },
	{ resolve = ffi.types.u8 },
})
export type bgfx_attachment_t = typeof(bgfx_attachment_t:new({}))

local bgfx_transform_t = ffi.struct({
	{ data = ffi.types.pointer },
	{ num = ffi.types.u16 },
})
export type bgfx_transform_t = typeof(bgfx_transform_t:new({}))

local bgfx_view_stats_t = ffi.struct({
	{ name = ffi.types.i8:array(256) },
	{ view = ffi.types.u16 },
	{ cpuTimeBegin = ffi.types.i64 },
	{ cpuTimeEnd = ffi.types.i64 },
	{ gpuTimeBegin = ffi.types.i64 },
	{ gpuTimeEnd = ffi.types.i64 },
	{ gpuFrameNum = ffi.types.u32 },
})
export type bgfx_view_stats_t = typeof(bgfx_view_stats_t:new({}))

local bgfx_encoder_stats_t = ffi.struct({
	{ cpuTimeBegin = ffi.types.i64 },
	{ cpuTimeEnd = ffi.types.i64 },
})
export type bgfx_encoder_stats_t = typeof(bgfx_encoder_stats_t:new({}))

local bgfx_stats_t = ffi.struct({
	{ cpuTimeFrame = ffi.types.i64 },
	{ cpuTimeBegin = ffi.types.i64 },
	{ cpuTimeEnd = ffi.types.i64 },
	{ cpuTimerFreq = ffi.types.i64 },
	{ gpuTimeBegin = ffi.types.i64 },
	{ gpuTimeEnd = ffi.types.i64 },
	{ gpuTimerFreq = ffi.types.i64 },
	{ waitRender = ffi.types.i64 },
	{ waitSubmit = ffi.types.i64 },
	{ numDraw = ffi.types.u32 },
	{ numCompute = ffi.types.u32 },
	{ numBlit = ffi.types.u32 },
	{ maxGpuLatency = ffi.types.u32 },
	{ gpuFrameNum = ffi.types.u32 },
	{ numDynamicIndexBuffers = ffi.types.u16 },
	{ numDynamicVertexBuffers = ffi.types.u16 },
	{ numFrameBuffers = ffi.types.u16 },
	{ numIndexBuffers = ffi.types.u16 },
	{ numOcclusionQueries = ffi.types.u16 },
	{ numPrograms = ffi.types.u16 },
	{ numShaders = ffi.types.u16 },
	{ numTextures = ffi.types.u16 },
	{ numUniforms = ffi.types.u16 },
	{ numVertexBuffers = ffi.types.u16 },
	{ numVertexLayouts = ffi.types.u16 },
	{ textureMemoryUsed = ffi.types.i64 },
	{ rtMemoryUsed = ffi.types.i64 },
	{ transientVbUsed = ffi.types.i32 },
	{ transientIbUsed = ffi.types.i32 },
	{ numPrims = ffi.types.u32:array(BGFX_TOPOLOGY_COUNT) },
	{ gpuMemoryMax = ffi.types.i64 },
	{ gpuMemoryUsed = ffi.types.i64 },
	{ width = ffi.types.u16 },
	{ height = ffi.types.u16 },
	{ textWidth = ffi.types.u16 },
	{ textHeight = ffi.types.u16 },
	{ numViews = ffi.types.u16 },
	{ viewStats = ffi.types.pointer },
	{ numEncoders = ffi.types.u8 },
	{ encoderStats = ffi.types.pointer },
})
export type bgfx_stats_t = typeof(bgfx_stats_t:new({}))

local bgfx_vertex_layout_t = ffi.struct({
	{ hash = ffi.types.u32 },
	{ stride = ffi.types.u16 },
	{ offset = ffi.types.u16:array(BGFX_ATTRIB_COUNT) },
	{ attributes = ffi.types.u16:array(BGFX_ATTRIB_COUNT) },
})
export type bgfx_vertex_layout_t = typeof(bgfx_vertex_layout_t:new({}))

local bgfx_interface_vtbl = ffi.struct({
	{ attachment_init = ffi.types.pointer },
	{ vertex_layout_begin = ffi.types.pointer },
	{ vertex_layout_add = ffi.types.pointer },
	{ vertex_layout_decode = ffi.types.pointer },
	{ vertex_layout_has = ffi.types.pointer },
	{ vertex_layout_skip = ffi.types.pointer },
	{ vertex_layout_end = ffi.types.pointer },
	{ vertex_layout_get_offset = ffi.types.pointer },
	{ vertex_layout_get_stride = ffi.types.pointer },
	{ vertex_layout_get_size = ffi.types.pointer },
	{ vertex_pack = ffi.types.pointer },
	{ vertex_unpack = ffi.types.pointer },
	{ vertex_convert = ffi.types.pointer },
	{ weld_vertices = ffi.types.pointer },
	{ topology_convert = ffi.types.pointer },
	{ topology_sort_tri_list = ffi.types.pointer },
	{ get_supported_renderers = ffi.types.pointer },
	{ get_renderer_name = ffi.types.pointer },
	{ init_ctor = ffi.types.pointer },
	{ init = ffi.types.pointer },
	{ shutdown = ffi.types.pointer },
	{ reset = ffi.types.pointer },
	{ frame = ffi.types.pointer },
	{ get_renderer_type = ffi.types.pointer },
	{ get_caps = ffi.types.pointer },
	{ get_stats = ffi.types.pointer },
	{ alloc = ffi.types.pointer },
	{ copy = ffi.types.pointer },
	{ make_ref = ffi.types.pointer },
	{ make_ref_release = ffi.types.pointer },
	{ set_debug = ffi.types.pointer },
	{ dbg_text_clear = ffi.types.pointer },
	{ dbg_text_printf = ffi.types.pointer },
	{ dbg_text_vprintf = ffi.types.pointer },
	{ dbg_text_image = ffi.types.pointer },
	{ create_index_buffer = ffi.types.pointer },
	{ set_index_buffer_name = ffi.types.pointer },
	{ destroy_index_buffer = ffi.types.pointer },
	{ create_vertex_layout = ffi.types.pointer },
	{ destroy_vertex_layout = ffi.types.pointer },
	{ create_vertex_buffer = ffi.types.pointer },
	{ set_vertex_buffer_name = ffi.types.pointer },
	{ destroy_vertex_buffer = ffi.types.pointer },
	{ create_dynamic_index_buffer = ffi.types.pointer },
	{ create_dynamic_index_buffer_mem = ffi.types.pointer },
	{ update_dynamic_index_buffer = ffi.types.pointer },
	{ destroy_dynamic_index_buffer = ffi.types.pointer },
	{ create_dynamic_vertex_buffer = ffi.types.pointer },
	{ create_dynamic_vertex_buffer_mem = ffi.types.pointer },
	{ update_dynamic_vertex_buffer = ffi.types.pointer },
	{ destroy_dynamic_vertex_buffer = ffi.types.pointer },
	{ get_avail_transient_index_buffer = ffi.types.pointer },
	{ get_avail_transient_vertex_buffer = ffi.types.pointer },
	{ get_avail_instance_data_buffer = ffi.types.pointer },
	{ alloc_transient_index_buffer = ffi.types.pointer },
	{ alloc_transient_vertex_buffer = ffi.types.pointer },
	{ alloc_transient_buffers = ffi.types.pointer },
	{ alloc_instance_data_buffer = ffi.types.pointer },
	{ create_indirect_buffer = ffi.types.pointer },
	{ destroy_indirect_buffer = ffi.types.pointer },
	{ create_shader = ffi.types.pointer },
	{ get_shader_uniforms = ffi.types.pointer },
	{ set_shader_name = ffi.types.pointer },
	{ destroy_shader = ffi.types.pointer },
	{ create_program = ffi.types.pointer },
	{ create_compute_program = ffi.types.pointer },
	{ destroy_program = ffi.types.pointer },
	{ is_texture_valid = ffi.types.pointer },
	{ is_frame_buffer_valid = ffi.types.pointer },
	{ calc_texture_size = ffi.types.pointer },
	{ create_texture = ffi.types.pointer },
	{ create_texture_2d = ffi.types.pointer },
	{ create_texture_2d_scaled = ffi.types.pointer },
	{ create_texture_3d = ffi.types.pointer },
	{ create_texture_cube = ffi.types.pointer },
	{ update_texture_2d = ffi.types.pointer },
	{ update_texture_3d = ffi.types.pointer },
	{ update_texture_cube = ffi.types.pointer },
	{ read_texture = ffi.types.pointer },
	{ set_texture_name = ffi.types.pointer },
	{ get_direct_access_ptr = ffi.types.pointer },
	{ destroy_texture = ffi.types.pointer },
	{ create_frame_buffer = ffi.types.pointer },
	{ create_frame_buffer_scaled = ffi.types.pointer },
	{ create_frame_buffer_from_handles = ffi.types.pointer },
	{ create_frame_buffer_from_attachment = ffi.types.pointer },
	{ create_frame_buffer_from_nwh = ffi.types.pointer },
	{ set_frame_buffer_name = ffi.types.pointer },
	{ get_texture = ffi.types.pointer },
	{ destroy_frame_buffer = ffi.types.pointer },
	{ create_uniform = ffi.types.pointer },
	{ create_uniform_with_freq = ffi.types.pointer },
	{ get_uniform_info = ffi.types.pointer },
	{ destroy_uniform = ffi.types.pointer },
	{ create_occlusion_query = ffi.types.pointer },
	{ get_result = ffi.types.pointer },
	{ destroy_occlusion_query = ffi.types.pointer },
	{ set_palette_color = ffi.types.pointer },
	{ set_palette_color_rgba32f = ffi.types.pointer },
	{ set_palette_color_rgba8 = ffi.types.pointer },
	{ set_view_name = ffi.types.pointer },
	{ set_view_rect = ffi.types.pointer },
	{ set_view_rect_ratio = ffi.types.pointer },
	{ set_view_scissor = ffi.types.pointer },
	{ set_view_clear = ffi.types.pointer },
	{ set_view_clear_mrt = ffi.types.pointer },
	{ set_view_mode = ffi.types.pointer },
	{ set_view_frame_buffer = ffi.types.pointer },
	{ set_view_transform = ffi.types.pointer },
	{ set_view_order = ffi.types.pointer },
	{ set_view_shading_rate = ffi.types.pointer },
	{ reset_view = ffi.types.pointer },
	{ encoder_begin = ffi.types.pointer },
	{ encoder_end = ffi.types.pointer },
	{ encoder_set_marker = ffi.types.pointer },
	{ encoder_set_state = ffi.types.pointer },
	{ encoder_set_condition = ffi.types.pointer },
	{ encoder_set_stencil = ffi.types.pointer },
	{ encoder_set_scissor = ffi.types.pointer },
	{ encoder_set_scissor_cached = ffi.types.pointer },
	{ encoder_set_transform = ffi.types.pointer },
	{ encoder_set_transform_cached = ffi.types.pointer },
	{ encoder_alloc_transform = ffi.types.pointer },
	{ encoder_set_uniform = ffi.types.pointer },
	{ set_view_uniform = ffi.types.pointer },
	{ set_frame_uniform = ffi.types.pointer },
	{ encoder_set_index_buffer = ffi.types.pointer },
	{ encoder_set_dynamic_index_buffer = ffi.types.pointer },
	{ encoder_set_transient_index_buffer = ffi.types.pointer },
	{ encoder_set_vertex_buffer = ffi.types.pointer },
	{ encoder_set_vertex_buffer_with_layout = ffi.types.pointer },
	{ encoder_set_dynamic_vertex_buffer = ffi.types.pointer },
	{ encoder_set_dynamic_vertex_buffer_with_layout = ffi.types.pointer },
	{ encoder_set_transient_vertex_buffer = ffi.types.pointer },
	{ encoder_set_transient_vertex_buffer_with_layout = ffi.types.pointer },
	{ encoder_set_vertex_count = ffi.types.pointer },
	{ encoder_set_instance_data_buffer = ffi.types.pointer },
	{ encoder_set_instance_data_from_vertex_buffer = ffi.types.pointer },
	{ encoder_set_instance_data_from_dynamic_vertex_buffer = ffi.types.pointer },
	{ encoder_set_instance_count = ffi.types.pointer },
	{ encoder_set_texture = ffi.types.pointer },
	{ encoder_touch = ffi.types.pointer },
	{ encoder_submit = ffi.types.pointer },
	{ encoder_submit_occlusion_query = ffi.types.pointer },
	{ encoder_submit_indirect = ffi.types.pointer },
	{ encoder_submit_indirect_count = ffi.types.pointer },
	{ encoder_set_compute_index_buffer = ffi.types.pointer },
	{ encoder_set_compute_vertex_buffer = ffi.types.pointer },
	{ encoder_set_compute_dynamic_index_buffer = ffi.types.pointer },
	{ encoder_set_compute_dynamic_vertex_buffer = ffi.types.pointer },
	{ encoder_set_compute_indirect_buffer = ffi.types.pointer },
	{ encoder_set_image = ffi.types.pointer },
	{ encoder_dispatch = ffi.types.pointer },
	{ encoder_dispatch_indirect = ffi.types.pointer },
	{ encoder_discard = ffi.types.pointer },
	{ encoder_blit = ffi.types.pointer },
	{ request_screen_shot = ffi.types.pointer },
	{ render_frame = ffi.types.pointer },
	{ set_platform_data = ffi.types.pointer },
	{ get_internal_data = ffi.types.pointer },
	{ override_internal_texture_ptr = ffi.types.pointer },
	{ override_internal_texture = ffi.types.pointer },
	{ set_marker = ffi.types.pointer },
	{ set_state = ffi.types.pointer },
	{ set_condition = ffi.types.pointer },
	{ set_stencil = ffi.types.pointer },
	{ set_scissor = ffi.types.pointer },
	{ set_scissor_cached = ffi.types.pointer },
	{ set_transform = ffi.types.pointer },
	{ set_transform_cached = ffi.types.pointer },
	{ alloc_transform = ffi.types.pointer },
	{ set_uniform = ffi.types.pointer },
	{ set_index_buffer = ffi.types.pointer },
	{ set_dynamic_index_buffer = ffi.types.pointer },
	{ set_transient_index_buffer = ffi.types.pointer },
	{ set_vertex_buffer = ffi.types.pointer },
	{ set_vertex_buffer_with_layout = ffi.types.pointer },
	{ set_dynamic_vertex_buffer = ffi.types.pointer },
	{ set_dynamic_vertex_buffer_with_layout = ffi.types.pointer },
	{ set_transient_vertex_buffer = ffi.types.pointer },
	{ set_transient_vertex_buffer_with_layout = ffi.types.pointer },
	{ set_vertex_count = ffi.types.pointer },
	{ set_instance_data_buffer = ffi.types.pointer },
	{ set_instance_data_from_vertex_buffer = ffi.types.pointer },
	{ set_instance_data_from_dynamic_vertex_buffer = ffi.types.pointer },
	{ set_instance_count = ffi.types.pointer },
	{ set_texture = ffi.types.pointer },
	{ touch = ffi.types.pointer },
	{ submit = ffi.types.pointer },
	{ submit_occlusion_query = ffi.types.pointer },
	{ submit_indirect = ffi.types.pointer },
	{ submit_indirect_count = ffi.types.pointer },
	{ set_compute_index_buffer = ffi.types.pointer },
	{ set_compute_vertex_buffer = ffi.types.pointer },
	{ set_compute_dynamic_index_buffer = ffi.types.pointer },
	{ set_compute_dynamic_vertex_buffer = ffi.types.pointer },
	{ set_compute_indirect_buffer = ffi.types.pointer },
	{ set_image = ffi.types.pointer },
	{ dispatch = ffi.types.pointer },
	{ dispatch_indirect = ffi.types.pointer },
	{ discard = ffi.types.pointer },
	{ blit = ffi.types.pointer },
})
export type bgfx_interface_vtbl = typeof(bgfx_interface_vtbl:new({}))

local structs = {
	bgfx_allocator_interface_t = bgfx_allocator_interface_t,
	bgfx_allocator_vtbl_t = bgfx_allocator_vtbl_t,
	bgfx_callback_interface_t = bgfx_callback_interface_t,
	bgfx_callback_vtbl_t = bgfx_callback_vtbl_t,
	bgfx_dynamic_index_buffer_handle_t = bgfx_dynamic_index_buffer_handle_t,
	bgfx_dynamic_vertex_buffer_handle_t = bgfx_dynamic_vertex_buffer_handle_t,
	bgfx_frame_buffer_handle_t = bgfx_frame_buffer_handle_t,
	bgfx_index_buffer_handle_t = bgfx_index_buffer_handle_t,
	bgfx_indirect_buffer_handle_t = bgfx_indirect_buffer_handle_t,
	bgfx_occlusion_query_handle_t = bgfx_occlusion_query_handle_t,
	bgfx_program_handle_t = bgfx_program_handle_t,
	bgfx_shader_handle_t = bgfx_shader_handle_t,
	bgfx_texture_handle_t = bgfx_texture_handle_t,
	bgfx_uniform_handle_t = bgfx_uniform_handle_t,
	bgfx_vertex_buffer_handle_t = bgfx_vertex_buffer_handle_t,
	bgfx_vertex_layout_handle_t = bgfx_vertex_layout_handle_t,
	bgfx_caps_gpu_t = bgfx_caps_gpu_t,
	bgfx_caps_limits_t = bgfx_caps_limits_t,
	bgfx_caps_t = bgfx_caps_t,
	bgfx_internal_data_t = bgfx_internal_data_t,
	bgfx_platform_data_t = bgfx_platform_data_t,
	bgfx_resolution_t = bgfx_resolution_t,
	bgfx_init_limits_t = bgfx_init_limits_t,
	bgfx_init_t = bgfx_init_t,
	bgfx_memory_t = bgfx_memory_t,
	bgfx_transient_index_buffer_t = bgfx_transient_index_buffer_t,
	bgfx_transient_vertex_buffer_t = bgfx_transient_vertex_buffer_t,
	bgfx_instance_data_buffer_t = bgfx_instance_data_buffer_t,
	bgfx_texture_info_t = bgfx_texture_info_t,
	bgfx_uniform_info_t = bgfx_uniform_info_t,
	bgfx_attachment_t = bgfx_attachment_t,
	bgfx_transform_t = bgfx_transform_t,
	bgfx_view_stats_t = bgfx_view_stats_t,
	bgfx_encoder_stats_t = bgfx_encoder_stats_t,
	bgfx_stats_t = bgfx_stats_t,
	bgfx_vertex_layout_t = bgfx_vertex_layout_t,
	bgfx_interface_vtbl = bgfx_interface_vtbl,
}

return structs
