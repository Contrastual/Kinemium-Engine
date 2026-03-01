local ffi = zune.ffi

-- Type aliases for FFI
type int = number
type float = number
type bool = boolean
type cstring = string
type FFIPointer = typeof(ffi.types.pointer)

-- Import struct types
local structs = require("./structs")
type bgfx_allocator_interface_t = structs.bgfx_allocator_interface_t
type bgfx_allocator_vtbl_t = structs.bgfx_allocator_vtbl_t
type bgfx_attachment_t = structs.bgfx_attachment_t
type bgfx_callback_interface_t = structs.bgfx_callback_interface_t
type bgfx_callback_vtbl_t = structs.bgfx_callback_vtbl_t
type bgfx_caps_gpu_t = structs.bgfx_caps_gpu_t
type bgfx_caps_limits_t = structs.bgfx_caps_limits_t
type bgfx_caps_t = structs.bgfx_caps_t
type bgfx_dynamic_index_buffer_handle_t = structs.bgfx_dynamic_index_buffer_handle_t
type bgfx_dynamic_vertex_buffer_handle_t = structs.bgfx_dynamic_vertex_buffer_handle_t
type bgfx_encoder_stats_t = structs.bgfx_encoder_stats_t
type bgfx_frame_buffer_handle_t = structs.bgfx_frame_buffer_handle_t
type bgfx_index_buffer_handle_t = structs.bgfx_index_buffer_handle_t
type bgfx_indirect_buffer_handle_t = structs.bgfx_indirect_buffer_handle_t
type bgfx_init_limits_t = structs.bgfx_init_limits_t
type bgfx_init_t = structs.bgfx_init_t
type bgfx_instance_data_buffer_t = structs.bgfx_instance_data_buffer_t
type bgfx_interface_vtbl = structs.bgfx_interface_vtbl
type bgfx_internal_data_t = structs.bgfx_internal_data_t
type bgfx_memory_t = structs.bgfx_memory_t
type bgfx_occlusion_query_handle_t = structs.bgfx_occlusion_query_handle_t
type bgfx_platform_data_t = structs.bgfx_platform_data_t
type bgfx_program_handle_t = structs.bgfx_program_handle_t
type bgfx_resolution_t = structs.bgfx_resolution_t
type bgfx_shader_handle_t = structs.bgfx_shader_handle_t
type bgfx_stats_t = structs.bgfx_stats_t
type bgfx_texture_handle_t = structs.bgfx_texture_handle_t
type bgfx_texture_info_t = structs.bgfx_texture_info_t
type bgfx_transform_t = structs.bgfx_transform_t
type bgfx_transient_index_buffer_t = structs.bgfx_transient_index_buffer_t
type bgfx_transient_vertex_buffer_t = structs.bgfx_transient_vertex_buffer_t
type bgfx_uniform_handle_t = structs.bgfx_uniform_handle_t
type bgfx_uniform_info_t = structs.bgfx_uniform_info_t
type bgfx_vertex_buffer_handle_t = structs.bgfx_vertex_buffer_handle_t
type bgfx_vertex_layout_handle_t = structs.bgfx_vertex_layout_handle_t
type bgfx_vertex_layout_t = structs.bgfx_vertex_layout_t
type bgfx_view_stats_t = structs.bgfx_view_stats_t

export type Fns = {
	bgfx_alloc: (_size: int) -> FFIPointer,
	bgfx_alloc_instance_data_buffer: (_idb: FFIPointer, _num: int, _stride: int) -> (),
	bgfx_alloc_transform: (_transform: FFIPointer, _num: int) -> int,
	bgfx_alloc_transient_buffers: (
		_tvb: FFIPointer,
		_layout: FFIPointer,
		_numVertices: int,
		_tib: FFIPointer,
		_numIndices: int,
		_index32: bool
	) -> bool,
	bgfx_alloc_transient_index_buffer: (_tib: FFIPointer, _num: int, _index32: bool) -> (),
	bgfx_alloc_transient_vertex_buffer: (_tvb: FFIPointer, _num: int, _layout: FFIPointer) -> (),
	bgfx_attachment_init: (
		_this: FFIPointer,
		_handle: bgfx_texture_handle_t,
		_access: FFIPointer,
		_layer: int,
		_numLayers: int,
		_mip: int,
		_resolve: int
	) -> (),
	bgfx_blit: (
		_id: FFIPointer,
		_dst: bgfx_texture_handle_t,
		_dstMip: int,
		_dstX: int,
		_dstY: int,
		_dstZ: int,
		_src: bgfx_texture_handle_t,
		_srcMip: int,
		_srcX: int,
		_srcY: int,
		_srcZ: int,
		_width: int,
		_height: int,
		_depth: int
	) -> (),
	bgfx_calc_texture_size: (
		_info: FFIPointer,
		_width: int,
		_height: int,
		_depth: int,
		_cubeMap: bool,
		_hasMips: bool,
		_numLayers: int,
		_format: FFIPointer
	) -> (),
	bgfx_copy: (_data: FFIPointer, _size: int) -> FFIPointer,
	bgfx_create_compute_program: (_csh: bgfx_shader_handle_t, _destroyShaders: bool) -> bgfx_program_handle_t,
	bgfx_create_dynamic_index_buffer: (_num: int, _flags: int) -> bgfx_dynamic_index_buffer_handle_t,
	bgfx_create_dynamic_index_buffer_mem: (_mem: FFIPointer, _flags: int) -> bgfx_dynamic_index_buffer_handle_t,
	bgfx_create_dynamic_vertex_buffer: (
		_num: int,
		_layout: FFIPointer,
		_flags: int
	) -> bgfx_dynamic_vertex_buffer_handle_t,
	bgfx_create_dynamic_vertex_buffer_mem: (
		_mem: FFIPointer,
		_layout: FFIPointer,
		_flags: int
	) -> bgfx_dynamic_vertex_buffer_handle_t,
	bgfx_create_frame_buffer: (
		_width: int,
		_height: int,
		_format: FFIPointer,
		_textureFlags: int
	) -> bgfx_frame_buffer_handle_t,
	bgfx_create_frame_buffer_from_attachment: (
		_num: int,
		_attachment: FFIPointer,
		_destroyTexture: bool
	) -> bgfx_frame_buffer_handle_t,
	bgfx_create_frame_buffer_from_handles: (
		_num: int,
		_handles: FFIPointer,
		_destroyTexture: bool
	) -> bgfx_frame_buffer_handle_t,
	bgfx_create_frame_buffer_from_nwh: (
		_nwh: FFIPointer,
		_width: int,
		_height: int,
		_format: FFIPointer,
		_depthFormat: FFIPointer
	) -> bgfx_frame_buffer_handle_t,
	bgfx_create_frame_buffer_scaled: (
		_ratio: FFIPointer,
		_format: FFIPointer,
		_textureFlags: int
	) -> bgfx_frame_buffer_handle_t,
	bgfx_create_index_buffer: (_mem: FFIPointer, _flags: int) -> bgfx_index_buffer_handle_t,
	bgfx_create_indirect_buffer: (_num: int) -> bgfx_indirect_buffer_handle_t,
	bgfx_create_occlusion_query: () -> bgfx_occlusion_query_handle_t,
	bgfx_create_program: (
		_vsh: bgfx_shader_handle_t,
		_fsh: bgfx_shader_handle_t,
		_destroyShaders: bool
	) -> bgfx_program_handle_t,
	bgfx_create_shader: (_mem: FFIPointer) -> bgfx_shader_handle_t,
	bgfx_create_texture: (_mem: FFIPointer, _flags: int, _skip: int, _info: FFIPointer) -> bgfx_texture_handle_t,
	bgfx_create_texture_2d: (
		_width: int,
		_height: int,
		_hasMips: bool,
		_numLayers: int,
		_format: FFIPointer,
		_flags: int,
		_mem: FFIPointer,
		_external: int
	) -> bgfx_texture_handle_t,
	bgfx_create_texture_2d_scaled: (
		_ratio: FFIPointer,
		_hasMips: bool,
		_numLayers: int,
		_format: FFIPointer,
		_flags: int
	) -> bgfx_texture_handle_t,
	bgfx_create_texture_3d: (
		_width: int,
		_height: int,
		_depth: int,
		_hasMips: bool,
		_format: FFIPointer,
		_flags: int,
		_mem: FFIPointer,
		_external: int
	) -> bgfx_texture_handle_t,
	bgfx_create_texture_cube: (
		_size: int,
		_hasMips: bool,
		_numLayers: int,
		_format: FFIPointer,
		_flags: int,
		_mem: FFIPointer,
		_external: int
	) -> bgfx_texture_handle_t,
	bgfx_create_uniform: (_name: cstring, _type: FFIPointer, _num: int) -> bgfx_uniform_handle_t,
	bgfx_create_uniform_with_freq: (
		_name: cstring,
		_freq: FFIPointer,
		_type: FFIPointer,
		_num: int
	) -> bgfx_uniform_handle_t,
	bgfx_create_vertex_buffer: (_mem: FFIPointer, _layout: FFIPointer, _flags: int) -> bgfx_vertex_buffer_handle_t,
	bgfx_create_vertex_layout: (_layout: FFIPointer) -> bgfx_vertex_layout_handle_t,
	bgfx_dbg_text_clear: (_attr: int, _small: bool) -> (),
	bgfx_dbg_text_image: (_x: int, _y: int, _width: int, _height: int, _data: FFIPointer, _pitch: int) -> (),
	bgfx_dbg_text_vprintf: (_x: int, _y: int, _attr: int, _format: cstring, _argList: FFIPointer) -> (),
	bgfx_destroy_dynamic_index_buffer: (_handle: bgfx_dynamic_index_buffer_handle_t) -> (),
	bgfx_destroy_dynamic_vertex_buffer: (_handle: bgfx_dynamic_vertex_buffer_handle_t) -> (),
	bgfx_destroy_frame_buffer: (_handle: bgfx_frame_buffer_handle_t) -> (),
	bgfx_destroy_index_buffer: (_handle: bgfx_index_buffer_handle_t) -> (),
	bgfx_destroy_indirect_buffer: (_handle: bgfx_indirect_buffer_handle_t) -> (),
	bgfx_destroy_occlusion_query: (_handle: bgfx_occlusion_query_handle_t) -> (),
	bgfx_destroy_program: (_handle: bgfx_program_handle_t) -> (),
	bgfx_destroy_shader: (_handle: bgfx_shader_handle_t) -> (),
	bgfx_destroy_texture: (_handle: bgfx_texture_handle_t) -> (),
	bgfx_destroy_uniform: (_handle: bgfx_uniform_handle_t) -> (),
	bgfx_destroy_vertex_buffer: (_handle: bgfx_vertex_buffer_handle_t) -> (),
	bgfx_destroy_vertex_layout: (_layoutHandle: bgfx_vertex_layout_handle_t) -> (),
	bgfx_discard: (_flags: int) -> (),
	bgfx_dispatch: (
		_id: FFIPointer,
		_program: bgfx_program_handle_t,
		_numX: int,
		_numY: int,
		_numZ: int,
		_flags: int
	) -> (),
	bgfx_dispatch_indirect: (
		_id: FFIPointer,
		_program: bgfx_program_handle_t,
		_indirectHandle: bgfx_indirect_buffer_handle_t,
		_start: int,
		_num: int,
		_flags: int
	) -> (),
	bgfx_encoder_alloc_transform: (_this: FFIPointer, _transform: FFIPointer, _num: int) -> int,
	bgfx_encoder_begin: (_forThread: bool) -> FFIPointer,
	bgfx_encoder_blit: (
		_this: FFIPointer,
		_id: FFIPointer,
		_dst: bgfx_texture_handle_t,
		_dstMip: int,
		_dstX: int,
		_dstY: int,
		_dstZ: int,
		_src: bgfx_texture_handle_t,
		_srcMip: int,
		_srcX: int,
		_srcY: int,
		_srcZ: int,
		_width: int,
		_height: int,
		_depth: int
	) -> (),
	bgfx_encoder_discard: (_this: FFIPointer, _flags: int) -> (),
	bgfx_encoder_dispatch: (
		_this: FFIPointer,
		_id: FFIPointer,
		_program: bgfx_program_handle_t,
		_numX: int,
		_numY: int,
		_numZ: int,
		_flags: int
	) -> (),
	bgfx_encoder_dispatch_indirect: (
		_this: FFIPointer,
		_id: FFIPointer,
		_program: bgfx_program_handle_t,
		_indirectHandle: bgfx_indirect_buffer_handle_t,
		_start: int,
		_num: int,
		_flags: int
	) -> (),
	bgfx_encoder_end: (_encoder: FFIPointer) -> (),
	bgfx_encoder_set_compute_dynamic_index_buffer: (
		_this: FFIPointer,
		_stage: int,
		_handle: bgfx_dynamic_index_buffer_handle_t,
		_access: FFIPointer
	) -> (),
	bgfx_encoder_set_compute_dynamic_vertex_buffer: (
		_this: FFIPointer,
		_stage: int,
		_handle: bgfx_dynamic_vertex_buffer_handle_t,
		_access: FFIPointer
	) -> (),
	bgfx_encoder_set_compute_index_buffer: (
		_this: FFIPointer,
		_stage: int,
		_handle: bgfx_index_buffer_handle_t,
		_access: FFIPointer
	) -> (),
	bgfx_encoder_set_compute_indirect_buffer: (
		_this: FFIPointer,
		_stage: int,
		_handle: bgfx_indirect_buffer_handle_t,
		_access: FFIPointer
	) -> (),
	bgfx_encoder_set_compute_vertex_buffer: (
		_this: FFIPointer,
		_stage: int,
		_handle: bgfx_vertex_buffer_handle_t,
		_access: FFIPointer
	) -> (),
	bgfx_encoder_set_condition: (_this: FFIPointer, _handle: bgfx_occlusion_query_handle_t, _visible: bool) -> (),
	bgfx_encoder_set_dynamic_index_buffer: (
		_this: FFIPointer,
		_handle: bgfx_dynamic_index_buffer_handle_t,
		_firstIndex: int,
		_numIndices: int
	) -> (),
	bgfx_encoder_set_dynamic_vertex_buffer: (
		_this: FFIPointer,
		_stream: int,
		_handle: bgfx_dynamic_vertex_buffer_handle_t,
		_startVertex: int,
		_numVertices: int
	) -> (),
	bgfx_encoder_set_dynamic_vertex_buffer_with_layout: (
		_this: FFIPointer,
		_stream: int,
		_handle: bgfx_dynamic_vertex_buffer_handle_t,
		_startVertex: int,
		_numVertices: int,
		_layoutHandle: bgfx_vertex_layout_handle_t
	) -> (),
	bgfx_encoder_set_image: (
		_this: FFIPointer,
		_stage: int,
		_handle: bgfx_texture_handle_t,
		_mip: int,
		_access: FFIPointer,
		_format: FFIPointer
	) -> (),
	bgfx_encoder_set_index_buffer: (
		_this: FFIPointer,
		_handle: bgfx_index_buffer_handle_t,
		_firstIndex: int,
		_numIndices: int
	) -> (),
	bgfx_encoder_set_instance_count: (_this: FFIPointer, _numInstances: int) -> (),
	bgfx_encoder_set_instance_data_buffer: (_this: FFIPointer, _idb: FFIPointer, _start: int, _num: int) -> (),
	bgfx_encoder_set_instance_data_from_dynamic_vertex_buffer: (
		_this: FFIPointer,
		_handle: bgfx_dynamic_vertex_buffer_handle_t,
		_startVertex: int,
		_num: int
	) -> (),
	bgfx_encoder_set_instance_data_from_vertex_buffer: (
		_this: FFIPointer,
		_handle: bgfx_vertex_buffer_handle_t,
		_startVertex: int,
		_num: int
	) -> (),
	bgfx_encoder_set_marker: (_this: FFIPointer, _name: cstring, _len: int) -> (),
	bgfx_encoder_set_scissor: (_this: FFIPointer, _x: int, _y: int, _width: int, _height: int) -> int,
	bgfx_encoder_set_scissor_cached: (_this: FFIPointer, _cache: int) -> (),
	bgfx_encoder_set_state: (_this: FFIPointer, _state: int, _rgba: int) -> (),
	bgfx_encoder_set_stencil: (_this: FFIPointer, _fstencil: int, _bstencil: int) -> (),
	bgfx_encoder_set_texture: (
		_this: FFIPointer,
		_stage: int,
		_sampler: bgfx_uniform_handle_t,
		_handle: bgfx_texture_handle_t,
		_flags: int
	) -> (),
	bgfx_encoder_set_transform: (_this: FFIPointer, _mtx: FFIPointer, _num: int) -> int,
	bgfx_encoder_set_transform_cached: (_this: FFIPointer, _cache: int, _num: int) -> (),
	bgfx_encoder_set_transient_index_buffer: (
		_this: FFIPointer,
		_tib: FFIPointer,
		_firstIndex: int,
		_numIndices: int
	) -> (),
	bgfx_encoder_set_transient_vertex_buffer: (
		_this: FFIPointer,
		_stream: int,
		_tvb: FFIPointer,
		_startVertex: int,
		_numVertices: int
	) -> (),
	bgfx_encoder_set_transient_vertex_buffer_with_layout: (
		_this: FFIPointer,
		_stream: int,
		_tvb: FFIPointer,
		_startVertex: int,
		_numVertices: int,
		_layoutHandle: bgfx_vertex_layout_handle_t
	) -> (),
	bgfx_encoder_set_uniform: (_this: FFIPointer, _handle: bgfx_uniform_handle_t, _value: FFIPointer, _num: int) -> (),
	bgfx_encoder_set_vertex_buffer: (
		_this: FFIPointer,
		_stream: int,
		_handle: bgfx_vertex_buffer_handle_t,
		_startVertex: int,
		_numVertices: int
	) -> (),
	bgfx_encoder_set_vertex_buffer_with_layout: (
		_this: FFIPointer,
		_stream: int,
		_handle: bgfx_vertex_buffer_handle_t,
		_startVertex: int,
		_numVertices: int,
		_layoutHandle: bgfx_vertex_layout_handle_t
	) -> (),
	bgfx_encoder_set_vertex_count: (_this: FFIPointer, _numVertices: int) -> (),
	bgfx_encoder_submit: (
		_this: FFIPointer,
		_id: FFIPointer,
		_program: bgfx_program_handle_t,
		_depth: int,
		_flags: int
	) -> (),
	bgfx_encoder_submit_indirect: (
		_this: FFIPointer,
		_id: FFIPointer,
		_program: bgfx_program_handle_t,
		_indirectHandle: bgfx_indirect_buffer_handle_t,
		_start: int,
		_num: int,
		_depth: int,
		_flags: int
	) -> (),
	bgfx_encoder_submit_indirect_count: (
		_this: FFIPointer,
		_id: FFIPointer,
		_program: bgfx_program_handle_t,
		_indirectHandle: bgfx_indirect_buffer_handle_t,
		_start: int,
		_numHandle: bgfx_index_buffer_handle_t,
		_numIndex: int,
		_numMax: int,
		_depth: int,
		_flags: int
	) -> (),
	bgfx_encoder_submit_occlusion_query: (
		_this: FFIPointer,
		_id: FFIPointer,
		_program: bgfx_program_handle_t,
		_occlusionQuery: bgfx_occlusion_query_handle_t,
		_depth: int,
		_flags: int
	) -> (),
	bgfx_encoder_touch: (_this: FFIPointer, _id: FFIPointer) -> (),
	bgfx_frame: (_flags: int) -> int,
	bgfx_get_avail_instance_data_buffer: (_num: int, _stride: int) -> int,
	bgfx_get_avail_transient_index_buffer: (_num: int, _index32: bool) -> int,
	bgfx_get_avail_transient_vertex_buffer: (_num: int, _layout: FFIPointer) -> int,
	bgfx_get_caps: () -> FFIPointer,
	bgfx_get_direct_access_ptr: (_handle: bgfx_texture_handle_t) -> FFIPointer,
	bgfx_get_interface: (_version: int) -> FFIPointer,
	bgfx_get_internal_data: () -> FFIPointer,
	bgfx_get_renderer_name: (_type: FFIPointer) -> cstring,
	bgfx_get_renderer_type: () -> FFIPointer,
	bgfx_get_result: (_handle: bgfx_occlusion_query_handle_t, _result: FFIPointer) -> FFIPointer,
	bgfx_get_shader_uniforms: (_handle: bgfx_shader_handle_t, _uniforms: FFIPointer, _max: int) -> int,
	bgfx_get_stats: () -> FFIPointer,
	bgfx_get_supported_renderers: (_max: int, _enum: FFIPointer) -> int,
	bgfx_get_texture: (_handle: bgfx_frame_buffer_handle_t, _attachment: int) -> bgfx_texture_handle_t,
	bgfx_get_uniform_info: (_handle: bgfx_uniform_handle_t, _info: FFIPointer) -> (),
	bgfx_init: (_init: FFIPointer) -> bool,
	bgfx_init_ctor: (_init: FFIPointer) -> (),
	bgfx_is_frame_buffer_valid: (_num: int, _attachment: FFIPointer) -> bool,
	bgfx_is_texture_valid: (_depth: int, _cubeMap: bool, _numLayers: int, _format: FFIPointer, _flags: int) -> bool,
	bgfx_make_ref: (_data: FFIPointer, _size: int) -> FFIPointer,
	bgfx_make_ref_release: (_data: FFIPointer, _size: int, _releaseFn: FFIPointer, _userData: FFIPointer) -> FFIPointer,
	bgfx_override_internal_texture: (
		_handle: bgfx_texture_handle_t,
		_width: int,
		_height: int,
		_numMips: int,
		_format: FFIPointer,
		_flags: int
	) -> FFIPointer,
	bgfx_override_internal_texture_ptr: (
		_handle: bgfx_texture_handle_t,
		_ptr: FFIPointer,
		_layerIndex: int
	) -> FFIPointer,
	bgfx_read_texture: (_handle: bgfx_texture_handle_t, _data: FFIPointer, _mip: int) -> int,
	bgfx_render_frame: (_msecs: int) -> FFIPointer,
	bgfx_request_screen_shot: (_handle: bgfx_frame_buffer_handle_t, _filePath: cstring) -> (),
	bgfx_reset: (_width: int, _height: int, _flags: int, _format: FFIPointer) -> (),
	bgfx_reset_view: (_id: FFIPointer) -> (),
	bgfx_set_compute_dynamic_index_buffer: (
		_stage: int,
		_handle: bgfx_dynamic_index_buffer_handle_t,
		_access: FFIPointer
	) -> (),
	bgfx_set_compute_dynamic_vertex_buffer: (
		_stage: int,
		_handle: bgfx_dynamic_vertex_buffer_handle_t,
		_access: FFIPointer
	) -> (),
	bgfx_set_compute_index_buffer: (_stage: int, _handle: bgfx_index_buffer_handle_t, _access: FFIPointer) -> (),
	bgfx_set_compute_indirect_buffer: (_stage: int, _handle: bgfx_indirect_buffer_handle_t, _access: FFIPointer) -> (),
	bgfx_set_compute_vertex_buffer: (_stage: int, _handle: bgfx_vertex_buffer_handle_t, _access: FFIPointer) -> (),
	bgfx_set_condition: (_handle: bgfx_occlusion_query_handle_t, _visible: bool) -> (),
	bgfx_set_debug: (_debug: int) -> (),
	bgfx_set_dynamic_index_buffer: (
		_handle: bgfx_dynamic_index_buffer_handle_t,
		_firstIndex: int,
		_numIndices: int
	) -> (),
	bgfx_set_dynamic_vertex_buffer: (
		_stream: int,
		_handle: bgfx_dynamic_vertex_buffer_handle_t,
		_startVertex: int,
		_numVertices: int
	) -> (),
	bgfx_set_dynamic_vertex_buffer_with_layout: (
		_stream: int,
		_handle: bgfx_dynamic_vertex_buffer_handle_t,
		_startVertex: int,
		_numVertices: int,
		_layoutHandle: bgfx_vertex_layout_handle_t
	) -> (),
	bgfx_set_frame_buffer_name: (_handle: bgfx_frame_buffer_handle_t, _name: cstring, _len: int) -> (),
	bgfx_set_frame_uniform: (_handle: bgfx_uniform_handle_t, _value: FFIPointer, _num: int) -> (),
	bgfx_set_image: (
		_stage: int,
		_handle: bgfx_texture_handle_t,
		_mip: int,
		_access: FFIPointer,
		_format: FFIPointer
	) -> (),
	bgfx_set_index_buffer: (_handle: bgfx_index_buffer_handle_t, _firstIndex: int, _numIndices: int) -> (),
	bgfx_set_index_buffer_name: (_handle: bgfx_index_buffer_handle_t, _name: cstring, _len: int) -> (),
	bgfx_set_instance_count: (_numInstances: int) -> (),
	bgfx_set_instance_data_buffer: (_idb: FFIPointer, _start: int, _num: int) -> (),
	bgfx_set_instance_data_from_dynamic_vertex_buffer: (
		_handle: bgfx_dynamic_vertex_buffer_handle_t,
		_startVertex: int,
		_num: int
	) -> (),
	bgfx_set_instance_data_from_vertex_buffer: (
		_handle: bgfx_vertex_buffer_handle_t,
		_startVertex: int,
		_num: int
	) -> (),
	bgfx_set_marker: (_name: cstring, _len: int) -> (),
	bgfx_set_palette_color_rgba32f: (_index: int, _r: float, _g: float, _b: float, _a: float) -> (),
	bgfx_set_palette_color_rgba8: (_index: int, _rgba: int) -> (),
	bgfx_set_platform_data: (_data: FFIPointer) -> (),
	bgfx_set_scissor: (_x: int, _y: int, _width: int, _height: int) -> int,
	bgfx_set_scissor_cached: (_cache: int) -> (),
	bgfx_set_shader_name: (_handle: bgfx_shader_handle_t, _name: cstring, _len: int) -> (),
	bgfx_set_state: (_state: int, _rgba: int) -> (),
	bgfx_set_stencil: (_fstencil: int, _bstencil: int) -> (),
	bgfx_set_texture: (_stage: int, _sampler: bgfx_uniform_handle_t, _handle: bgfx_texture_handle_t, _flags: int) -> (),
	bgfx_set_texture_name: (_handle: bgfx_texture_handle_t, _name: cstring, _len: int) -> (),
	bgfx_set_transform: (_mtx: FFIPointer, _num: int) -> int,
	bgfx_set_transform_cached: (_cache: int, _num: int) -> (),
	bgfx_set_transient_index_buffer: (_tib: FFIPointer, _firstIndex: int, _numIndices: int) -> (),
	bgfx_set_transient_vertex_buffer: (_stream: int, _tvb: FFIPointer, _startVertex: int, _numVertices: int) -> (),
	bgfx_set_transient_vertex_buffer_with_layout: (
		_stream: int,
		_tvb: FFIPointer,
		_startVertex: int,
		_numVertices: int,
		_layoutHandle: bgfx_vertex_layout_handle_t
	) -> (),
	bgfx_set_uniform: (_handle: bgfx_uniform_handle_t, _value: FFIPointer, _num: int) -> (),
	bgfx_set_vertex_buffer: (
		_stream: int,
		_handle: bgfx_vertex_buffer_handle_t,
		_startVertex: int,
		_numVertices: int
	) -> (),
	bgfx_set_vertex_buffer_name: (_handle: bgfx_vertex_buffer_handle_t, _name: cstring, _len: int) -> (),
	bgfx_set_vertex_buffer_with_layout: (
		_stream: int,
		_handle: bgfx_vertex_buffer_handle_t,
		_startVertex: int,
		_numVertices: int,
		_layoutHandle: bgfx_vertex_layout_handle_t
	) -> (),
	bgfx_set_vertex_count: (_numVertices: int) -> (),
	bgfx_set_view_clear: (_id: FFIPointer, _flags: int, _rgba: int, _depth: float, _stencil: int) -> (),
	bgfx_set_view_clear_mrt: (
		_id: FFIPointer,
		_flags: int,
		_depth: float,
		_stencil: int,
		_c0: int,
		_c1: int,
		_c2: int,
		_c3: int,
		_c4: int,
		_c5: int,
		_c6: int,
		_c7: int
	) -> (),
	bgfx_set_view_frame_buffer: (_id: FFIPointer, _handle: bgfx_frame_buffer_handle_t) -> (),
	bgfx_set_view_mode: (_id: FFIPointer, _mode: FFIPointer) -> (),
	bgfx_set_view_name: (_id: FFIPointer, _name: cstring, _len: int) -> (),
	bgfx_set_view_order: (_id: FFIPointer, _num: int, _order: FFIPointer) -> (),
	bgfx_set_view_rect: (_id: FFIPointer, _x: int, _y: int, _width: int, _height: int) -> (),
	bgfx_set_view_rect_ratio: (_id: FFIPointer, _x: int, _y: int, _ratio: FFIPointer) -> (),
	bgfx_set_view_scissor: (_id: FFIPointer, _x: int, _y: int, _width: int, _height: int) -> (),
	bgfx_set_view_shading_rate: (_id: FFIPointer, _shadingRate: FFIPointer) -> (),
	bgfx_set_view_transform: (_id: FFIPointer, _view: FFIPointer, _proj: FFIPointer) -> (),
	bgfx_set_view_uniform: (_id: FFIPointer, _handle: bgfx_uniform_handle_t, _value: FFIPointer, _num: int) -> (),
	bgfx_shutdown: () -> (),
	bgfx_submit: (_id: FFIPointer, _program: bgfx_program_handle_t, _depth: int, _flags: int) -> (),
	bgfx_submit_indirect: (
		_id: FFIPointer,
		_program: bgfx_program_handle_t,
		_indirectHandle: bgfx_indirect_buffer_handle_t,
		_start: int,
		_num: int,
		_depth: int,
		_flags: int
	) -> (),
	bgfx_submit_indirect_count: (
		_id: FFIPointer,
		_program: bgfx_program_handle_t,
		_indirectHandle: bgfx_indirect_buffer_handle_t,
		_start: int,
		_numHandle: bgfx_index_buffer_handle_t,
		_numIndex: int,
		_numMax: int,
		_depth: int,
		_flags: int
	) -> (),
	bgfx_submit_occlusion_query: (
		_id: FFIPointer,
		_program: bgfx_program_handle_t,
		_occlusionQuery: bgfx_occlusion_query_handle_t,
		_depth: int,
		_flags: int
	) -> (),
	bgfx_topology_convert: (
		_conversion: FFIPointer,
		_dst: FFIPointer,
		_dstSize: int,
		_indices: FFIPointer,
		_numIndices: int,
		_index32: bool
	) -> int,
	bgfx_touch: (_id: FFIPointer) -> (),
	bgfx_update_dynamic_index_buffer: (
		_handle: bgfx_dynamic_index_buffer_handle_t,
		_startIndex: int,
		_mem: FFIPointer
	) -> (),
	bgfx_update_dynamic_vertex_buffer: (
		_handle: bgfx_dynamic_vertex_buffer_handle_t,
		_startVertex: int,
		_mem: FFIPointer
	) -> (),
	bgfx_update_texture_2d: (
		_handle: bgfx_texture_handle_t,
		_layer: int,
		_mip: int,
		_x: int,
		_y: int,
		_width: int,
		_height: int,
		_mem: FFIPointer,
		_pitch: int
	) -> (),
	bgfx_update_texture_3d: (
		_handle: bgfx_texture_handle_t,
		_mip: int,
		_x: int,
		_y: int,
		_z: int,
		_width: int,
		_height: int,
		_depth: int,
		_mem: FFIPointer
	) -> (),
	bgfx_update_texture_cube: (
		_handle: bgfx_texture_handle_t,
		_layer: int,
		_side: int,
		_mip: int,
		_x: int,
		_y: int,
		_width: int,
		_height: int,
		_mem: FFIPointer,
		_pitch: int
	) -> (),
	bgfx_vertex_convert: (
		_dstLayout: FFIPointer,
		_dstData: FFIPointer,
		_srcLayout: FFIPointer,
		_srcData: FFIPointer,
		_num: int
	) -> (),
	bgfx_vertex_layout_add: (
		_this: FFIPointer,
		_attrib: FFIPointer,
		_num: int,
		_type: FFIPointer,
		_normalized: bool,
		_asInt: bool
	) -> FFIPointer,
	bgfx_vertex_layout_begin: (_this: FFIPointer, _rendererType: FFIPointer) -> FFIPointer,
	bgfx_vertex_layout_decode: (
		_this: FFIPointer,
		_attrib: FFIPointer,
		_num: FFIPointer,
		_type: FFIPointer,
		_normalized: FFIPointer,
		_asInt: FFIPointer
	) -> (),
	bgfx_vertex_layout_end: (_this: FFIPointer) -> (),
	bgfx_vertex_layout_get_offset: (_this: FFIPointer, _attrib: FFIPointer) -> int,
	bgfx_vertex_layout_get_size: (_this: FFIPointer, _num: int) -> int,
	bgfx_vertex_layout_get_stride: (_this: FFIPointer) -> int,
	bgfx_vertex_layout_has: (_this: FFIPointer, _attrib: FFIPointer) -> bool,
	bgfx_vertex_layout_skip: (_this: FFIPointer, _num: int) -> FFIPointer,
	bgfx_weld_vertices: (
		_output: FFIPointer,
		_layout: FFIPointer,
		_data: FFIPointer,
		_num: int,
		_index32: bool,
		_epsilon: float
	) -> int,
}

local funcs = {
	bgfx_attachment_init = {
		returns = ffi.types.void,
		args = {
			ffi.types.pointer,
			ffi.types.pointer,
			ffi.types.pointer,
			ffi.types.u16,
			ffi.types.u16,
			ffi.types.u16,
			ffi.types.u8,
		},
	},
	bgfx_vertex_layout_begin = { returns = ffi.types.pointer, args = { ffi.types.pointer, ffi.types.pointer } },
	bgfx_vertex_layout_add = {
		returns = ffi.types.pointer,
		args = { ffi.types.pointer, ffi.types.pointer, ffi.types.u8, ffi.types.pointer, ffi.types.u8, ffi.types.u8 },
	},
	bgfx_vertex_layout_decode = {
		returns = ffi.types.void,
		args = {
			ffi.types.pointer,
			ffi.types.pointer,
			ffi.types.pointer,
			ffi.types.pointer,
			ffi.types.pointer,
			ffi.types.pointer,
		},
	},
	bgfx_vertex_layout_has = { returns = ffi.types.u8, args = { ffi.types.pointer, ffi.types.pointer } },
	bgfx_vertex_layout_skip = { returns = ffi.types.pointer, args = { ffi.types.pointer, ffi.types.u8 } },
	bgfx_vertex_layout_end = { returns = ffi.types.void, args = { ffi.types.pointer } },
	bgfx_vertex_layout_get_offset = { returns = ffi.types.u16, args = { ffi.types.pointer, ffi.types.pointer } },
	bgfx_vertex_layout_get_stride = { returns = ffi.types.u16, args = { ffi.types.pointer } },
	bgfx_vertex_layout_get_size = { returns = ffi.types.u32, args = { ffi.types.pointer, ffi.types.u32 } },
	bgfx_vertex_pack = {
		returns = ffi.types.void,
		args = { ffi.types.float, ffi.types.u8, ffi.types.pointer, ffi.types.pointer, ffi.types.pointer, ffi.types.u32 },
	},
	bgfx_vertex_unpack = {
		returns = ffi.types.void,
		args = { ffi.types.float, ffi.types.pointer, ffi.types.pointer, ffi.types.pointer, ffi.types.u32 },
	},
	bgfx_vertex_convert = {
		returns = ffi.types.void,
		args = { ffi.types.pointer, ffi.types.pointer, ffi.types.pointer, ffi.types.pointer, ffi.types.u32 },
	},
	bgfx_weld_vertices = {
		returns = ffi.types.u32,
		args = { ffi.types.pointer, ffi.types.pointer, ffi.types.pointer, ffi.types.u32, ffi.types.u8, ffi.types.float },
	},
	bgfx_topology_convert = {
		returns = ffi.types.u32,
		args = { ffi.types.pointer, ffi.types.pointer, ffi.types.u32, ffi.types.pointer, ffi.types.u32, ffi.types.u8 },
	},
	bgfx_topology_sort_tri_list = {
		returns = ffi.types.void,
		args = {
			ffi.types.pointer,
			ffi.types.pointer,
			ffi.types.u32,
			ffi.types.float,
			ffi.types.float,
			ffi.types.pointer,
			ffi.types.u32,
			ffi.types.pointer,
			ffi.types.u32,
			ffi.types.u8,
		},
	},
	bgfx_get_supported_renderers = { returns = ffi.types.u8, args = { ffi.types.u8, ffi.types.pointer } },
	bgfx_get_renderer_name = { returns = ffi.types.pointer, args = { ffi.types.pointer } },
	bgfx_init_ctor = { returns = ffi.types.void, args = { ffi.types.pointer } },
	bgfx_init = { returns = ffi.types.u8, args = { ffi.types.pointer } },
	bgfx_shutdown = { returns = ffi.types.void, args = {} },
	bgfx_reset = { returns = ffi.types.void, args = { ffi.types.u32, ffi.types.u32, ffi.types.u32, ffi.types.pointer } },
	bgfx_frame = { returns = ffi.types.u32, args = { ffi.types.u8 } },
	bgfx_get_renderer_type = { returns = ffi.types.pointer, args = {} },
	bgfx_get_caps = { returns = ffi.types.pointer, args = {} },
	bgfx_get_stats = { returns = ffi.types.pointer, args = {} },
	bgfx_alloc = { returns = ffi.types.pointer, args = { ffi.types.u32 } },
	bgfx_copy = { returns = ffi.types.pointer, args = { ffi.types.pointer, ffi.types.u32 } },
	bgfx_make_ref = { returns = ffi.types.pointer, args = { ffi.types.pointer, ffi.types.u32 } },
	bgfx_make_ref_release = {
		returns = ffi.types.pointer,
		args = { ffi.types.pointer, ffi.types.u32, ffi.types.pointer, ffi.types.pointer },
	},
	bgfx_set_debug = { returns = ffi.types.void, args = { ffi.types.u32 } },
	bgfx_dbg_text_clear = { returns = ffi.types.void, args = { ffi.types.u8, ffi.types.u8 } },
	bgfx_dbg_text_vprintf = {
		returns = ffi.types.void,
		args = { ffi.types.u16, ffi.types.u16, ffi.types.u8, ffi.types.pointer, ffi.types.pointer },
	},
	bgfx_dbg_text_image = {
		returns = ffi.types.void,
		args = { ffi.types.u16, ffi.types.u16, ffi.types.u16, ffi.types.u16, ffi.types.pointer, ffi.types.u16 },
	},
	bgfx_create_index_buffer = { returns = ffi.types.pointer, args = { ffi.types.pointer, ffi.types.u16 } },
	bgfx_set_index_buffer_name = {
		returns = ffi.types.void,
		args = { ffi.types.pointer, ffi.types.pointer, ffi.types.i32 },
	},
	bgfx_destroy_index_buffer = { returns = ffi.types.void, args = { ffi.types.pointer } },
	bgfx_create_vertex_layout = { returns = ffi.types.pointer, args = { ffi.types.pointer } },
	bgfx_destroy_vertex_layout = { returns = ffi.types.void, args = { ffi.types.pointer } },
	bgfx_create_vertex_buffer = {
		returns = ffi.types.pointer,
		args = { ffi.types.pointer, ffi.types.pointer, ffi.types.u16 },
	},
	bgfx_set_vertex_buffer_name = {
		returns = ffi.types.void,
		args = { ffi.types.pointer, ffi.types.pointer, ffi.types.i32 },
	},
	bgfx_destroy_vertex_buffer = { returns = ffi.types.void, args = { ffi.types.pointer } },
	bgfx_create_dynamic_index_buffer = { returns = ffi.types.pointer, args = { ffi.types.u32, ffi.types.u16 } },
	bgfx_create_dynamic_index_buffer_mem = { returns = ffi.types.pointer, args = { ffi.types.pointer, ffi.types.u16 } },
	bgfx_update_dynamic_index_buffer = {
		returns = ffi.types.void,
		args = { ffi.types.pointer, ffi.types.u32, ffi.types.pointer },
	},
	bgfx_destroy_dynamic_index_buffer = { returns = ffi.types.void, args = { ffi.types.pointer } },
	bgfx_create_dynamic_vertex_buffer = {
		returns = ffi.types.pointer,
		args = { ffi.types.u32, ffi.types.pointer, ffi.types.u16 },
	},
	bgfx_create_dynamic_vertex_buffer_mem = {
		returns = ffi.types.pointer,
		args = { ffi.types.pointer, ffi.types.pointer, ffi.types.u16 },
	},
	bgfx_update_dynamic_vertex_buffer = {
		returns = ffi.types.void,
		args = { ffi.types.pointer, ffi.types.u32, ffi.types.pointer },
	},
	bgfx_destroy_dynamic_vertex_buffer = { returns = ffi.types.void, args = { ffi.types.pointer } },
	bgfx_get_avail_transient_index_buffer = { returns = ffi.types.u32, args = { ffi.types.u32, ffi.types.u8 } },
	bgfx_get_avail_transient_vertex_buffer = { returns = ffi.types.u32, args = { ffi.types.u32, ffi.types.pointer } },
	bgfx_get_avail_instance_data_buffer = { returns = ffi.types.u32, args = { ffi.types.u32, ffi.types.u16 } },
	bgfx_alloc_transient_index_buffer = {
		returns = ffi.types.void,
		args = { ffi.types.pointer, ffi.types.u32, ffi.types.u8 },
	},
	bgfx_alloc_transient_vertex_buffer = {
		returns = ffi.types.void,
		args = { ffi.types.pointer, ffi.types.u32, ffi.types.pointer },
	},
	bgfx_alloc_transient_buffers = {
		returns = ffi.types.u8,
		args = { ffi.types.pointer, ffi.types.pointer, ffi.types.u32, ffi.types.pointer, ffi.types.u32, ffi.types.u8 },
	},
	bgfx_alloc_instance_data_buffer = {
		returns = ffi.types.void,
		args = { ffi.types.pointer, ffi.types.u32, ffi.types.u16 },
	},
	bgfx_create_indirect_buffer = { returns = ffi.types.pointer, args = { ffi.types.u32 } },
	bgfx_destroy_indirect_buffer = { returns = ffi.types.void, args = { ffi.types.pointer } },
	bgfx_create_shader = { returns = ffi.types.pointer, args = { ffi.types.pointer } },
	bgfx_get_shader_uniforms = {
		returns = ffi.types.u16,
		args = { ffi.types.pointer, ffi.types.pointer, ffi.types.u16 },
	},
	bgfx_set_shader_name = { returns = ffi.types.void, args = { ffi.types.pointer, ffi.types.pointer, ffi.types.i32 } },
	bgfx_destroy_shader = { returns = ffi.types.void, args = { ffi.types.pointer } },
	bgfx_create_program = { returns = ffi.types.pointer, args = { ffi.types.pointer, ffi.types.pointer, ffi.types.u8 } },
	bgfx_create_compute_program = { returns = ffi.types.pointer, args = { ffi.types.pointer, ffi.types.u8 } },
	bgfx_destroy_program = { returns = ffi.types.void, args = { ffi.types.pointer } },
	bgfx_is_texture_valid = {
		returns = ffi.types.u8,
		args = { ffi.types.u16, ffi.types.u8, ffi.types.u16, ffi.types.pointer, ffi.types.u64 },
	},
	bgfx_is_frame_buffer_valid = { returns = ffi.types.u8, args = { ffi.types.u8, ffi.types.pointer } },
	bgfx_calc_texture_size = {
		returns = ffi.types.void,
		args = {
			ffi.types.pointer,
			ffi.types.u16,
			ffi.types.u16,
			ffi.types.u16,
			ffi.types.u8,
			ffi.types.u8,
			ffi.types.u16,
			ffi.types.pointer,
		},
	},
	bgfx_create_texture = {
		returns = ffi.types.pointer,
		args = { ffi.types.pointer, ffi.types.u64, ffi.types.u8, ffi.types.pointer },
	},
	bgfx_create_texture_2d = {
		returns = ffi.types.pointer,
		args = {
			ffi.types.u16,
			ffi.types.u16,
			ffi.types.u8,
			ffi.types.u16,
			ffi.types.pointer,
			ffi.types.u64,
			ffi.types.pointer,
			ffi.types.u64,
		},
	},
	bgfx_create_texture_2d_scaled = {
		returns = ffi.types.pointer,
		args = { ffi.types.pointer, ffi.types.u8, ffi.types.u16, ffi.types.pointer, ffi.types.u64 },
	},
	bgfx_create_texture_3d = {
		returns = ffi.types.pointer,
		args = {
			ffi.types.u16,
			ffi.types.u16,
			ffi.types.u16,
			ffi.types.u8,
			ffi.types.pointer,
			ffi.types.u64,
			ffi.types.pointer,
			ffi.types.u64,
		},
	},
	bgfx_create_texture_cube = {
		returns = ffi.types.pointer,
		args = {
			ffi.types.u16,
			ffi.types.u8,
			ffi.types.u16,
			ffi.types.pointer,
			ffi.types.u64,
			ffi.types.pointer,
			ffi.types.u64,
		},
	},
	bgfx_update_texture_2d = {
		returns = ffi.types.void,
		args = {
			ffi.types.pointer,
			ffi.types.u16,
			ffi.types.u8,
			ffi.types.u16,
			ffi.types.u16,
			ffi.types.u16,
			ffi.types.u16,
			ffi.types.pointer,
			ffi.types.u16,
		},
	},
	bgfx_update_texture_3d = {
		returns = ffi.types.void,
		args = {
			ffi.types.pointer,
			ffi.types.u8,
			ffi.types.u16,
			ffi.types.u16,
			ffi.types.u16,
			ffi.types.u16,
			ffi.types.u16,
			ffi.types.u16,
			ffi.types.pointer,
		},
	},
	bgfx_update_texture_cube = {
		returns = ffi.types.void,
		args = {
			ffi.types.pointer,
			ffi.types.u16,
			ffi.types.u8,
			ffi.types.u8,
			ffi.types.u16,
			ffi.types.u16,
			ffi.types.u16,
			ffi.types.u16,
			ffi.types.pointer,
			ffi.types.u16,
		},
	},
	bgfx_read_texture = { returns = ffi.types.u32, args = { ffi.types.pointer, ffi.types.pointer, ffi.types.u8 } },
	bgfx_set_texture_name = { returns = ffi.types.void, args = { ffi.types.pointer, ffi.types.pointer, ffi.types.i32 } },
	bgfx_get_direct_access_ptr = { returns = ffi.types.pointer, args = { ffi.types.pointer } },
	bgfx_destroy_texture = { returns = ffi.types.void, args = { ffi.types.pointer } },
	bgfx_create_frame_buffer = {
		returns = ffi.types.pointer,
		args = { ffi.types.u16, ffi.types.u16, ffi.types.pointer, ffi.types.u64 },
	},
	bgfx_create_frame_buffer_scaled = {
		returns = ffi.types.pointer,
		args = { ffi.types.pointer, ffi.types.pointer, ffi.types.u64 },
	},
	bgfx_create_frame_buffer_from_handles = {
		returns = ffi.types.pointer,
		args = { ffi.types.u8, ffi.types.pointer, ffi.types.u8 },
	},
	bgfx_create_frame_buffer_from_attachment = {
		returns = ffi.types.pointer,
		args = { ffi.types.u8, ffi.types.pointer, ffi.types.u8 },
	},
	bgfx_create_frame_buffer_from_nwh = {
		returns = ffi.types.pointer,
		args = { ffi.types.pointer, ffi.types.u16, ffi.types.u16, ffi.types.pointer, ffi.types.pointer },
	},
	bgfx_set_frame_buffer_name = {
		returns = ffi.types.void,
		args = { ffi.types.pointer, ffi.types.pointer, ffi.types.i32 },
	},
	bgfx_get_texture = { returns = ffi.types.pointer, args = { ffi.types.pointer, ffi.types.u8 } },
	bgfx_destroy_frame_buffer = { returns = ffi.types.void, args = { ffi.types.pointer } },
	bgfx_create_uniform = {
		returns = ffi.types.pointer,
		args = { ffi.types.pointer, ffi.types.pointer, ffi.types.u16 },
	},
	bgfx_create_uniform_with_freq = {
		returns = ffi.types.pointer,
		args = { ffi.types.pointer, ffi.types.pointer, ffi.types.pointer, ffi.types.u16 },
	},
	bgfx_get_uniform_info = { returns = ffi.types.void, args = { ffi.types.pointer, ffi.types.pointer } },
	bgfx_destroy_uniform = { returns = ffi.types.void, args = { ffi.types.pointer } },
	bgfx_create_occlusion_query = { returns = ffi.types.pointer, args = {} },
	bgfx_get_result = { returns = ffi.types.pointer, args = { ffi.types.pointer, ffi.types.pointer } },
	bgfx_destroy_occlusion_query = { returns = ffi.types.void, args = { ffi.types.pointer } },
	bgfx_set_palette_color = { returns = ffi.types.void, args = { ffi.types.u8, ffi.types.float } },
	bgfx_set_palette_color_rgba32f = {
		returns = ffi.types.void,
		args = { ffi.types.u8, ffi.types.float, ffi.types.float, ffi.types.float, ffi.types.float },
	},
	bgfx_set_palette_color_rgba8 = { returns = ffi.types.void, args = { ffi.types.u8, ffi.types.u32 } },
	bgfx_set_view_name = { returns = ffi.types.void, args = { ffi.types.u16, ffi.types.pointer, ffi.types.i32 } },
	bgfx_set_view_rect = {
		returns = ffi.types.void,
		args = { ffi.types.u16, ffi.types.u16, ffi.types.u16, ffi.types.u16, ffi.types.u16 },
	},
	bgfx_set_view_rect_ratio = {
		returns = ffi.types.void,
		args = { ffi.types.u16, ffi.types.u16, ffi.types.u16, ffi.types.pointer },
	},
	bgfx_set_view_scissor = {
		returns = ffi.types.void,
		args = { ffi.types.u16, ffi.types.u16, ffi.types.u16, ffi.types.u16, ffi.types.u16 },
	},
	bgfx_set_view_clear = {
		returns = ffi.types.void,
		args = { ffi.types.u16, ffi.types.u16, ffi.types.u32, ffi.types.float, ffi.types.u8 },
	},
	bgfx_set_view_clear_mrt = {
		returns = ffi.types.void,
		args = {
			ffi.types.u16,
			ffi.types.u16,
			ffi.types.float,
			ffi.types.u8,
			ffi.types.u8,
			ffi.types.u8,
			ffi.types.u8,
			ffi.types.u8,
			ffi.types.u8,
			ffi.types.u8,
			ffi.types.u8,
			ffi.types.u8,
		},
	},
	bgfx_set_view_mode = { returns = ffi.types.void, args = { ffi.types.u16, ffi.types.pointer } },
	bgfx_set_view_frame_buffer = { returns = ffi.types.void, args = { ffi.types.u16, ffi.types.pointer } },
	bgfx_set_view_transform = {
		returns = ffi.types.void,
		args = { ffi.types.u16, ffi.types.pointer, ffi.types.pointer },
	},
	bgfx_set_view_order = { returns = ffi.types.void, args = { ffi.types.u16, ffi.types.u16, ffi.types.pointer } },
	bgfx_set_view_shading_rate = { returns = ffi.types.void, args = { ffi.types.u16, ffi.types.pointer } },
	bgfx_reset_view = { returns = ffi.types.void, args = { ffi.types.u16 } },
	bgfx_encoder_begin = { returns = ffi.types.pointer, args = { ffi.types.u8 } },
	bgfx_encoder_end = { returns = ffi.types.void, args = { ffi.types.pointer } },
	bgfx_encoder_set_marker = {
		returns = ffi.types.void,
		args = { ffi.types.pointer, ffi.types.pointer, ffi.types.i32 },
	},
	bgfx_encoder_set_state = { returns = ffi.types.void, args = { ffi.types.pointer, ffi.types.u64, ffi.types.u32 } },
	bgfx_encoder_set_condition = {
		returns = ffi.types.void,
		args = { ffi.types.pointer, ffi.types.pointer, ffi.types.u8 },
	},
	bgfx_encoder_set_stencil = { returns = ffi.types.void, args = { ffi.types.pointer, ffi.types.u32, ffi.types.u32 } },
	bgfx_encoder_set_scissor = {
		returns = ffi.types.u16,
		args = { ffi.types.pointer, ffi.types.u16, ffi.types.u16, ffi.types.u16, ffi.types.u16 },
	},
	bgfx_encoder_set_scissor_cached = { returns = ffi.types.void, args = { ffi.types.pointer, ffi.types.u16 } },
	bgfx_encoder_set_transform = {
		returns = ffi.types.u32,
		args = { ffi.types.pointer, ffi.types.pointer, ffi.types.u16 },
	},
	bgfx_encoder_set_transform_cached = {
		returns = ffi.types.void,
		args = { ffi.types.pointer, ffi.types.u32, ffi.types.u16 },
	},
	bgfx_encoder_alloc_transform = {
		returns = ffi.types.u32,
		args = { ffi.types.pointer, ffi.types.pointer, ffi.types.u16 },
	},
	bgfx_encoder_set_uniform = {
		returns = ffi.types.void,
		args = { ffi.types.pointer, ffi.types.pointer, ffi.types.pointer, ffi.types.u16 },
	},
	bgfx_set_view_uniform = {
		returns = ffi.types.void,
		args = { ffi.types.u16, ffi.types.pointer, ffi.types.pointer, ffi.types.u16 },
	},
	bgfx_set_frame_uniform = {
		returns = ffi.types.void,
		args = { ffi.types.pointer, ffi.types.pointer, ffi.types.u16 },
	},
	bgfx_encoder_set_index_buffer = {
		returns = ffi.types.void,
		args = { ffi.types.pointer, ffi.types.pointer, ffi.types.u32, ffi.types.u32 },
	},
	bgfx_encoder_set_dynamic_index_buffer = {
		returns = ffi.types.void,
		args = { ffi.types.pointer, ffi.types.pointer, ffi.types.u32, ffi.types.u32 },
	},
	bgfx_encoder_set_transient_index_buffer = {
		returns = ffi.types.void,
		args = { ffi.types.pointer, ffi.types.pointer, ffi.types.u32, ffi.types.u32 },
	},
	bgfx_encoder_set_vertex_buffer = {
		returns = ffi.types.void,
		args = { ffi.types.pointer, ffi.types.u8, ffi.types.pointer, ffi.types.u32, ffi.types.u32 },
	},
	bgfx_encoder_set_vertex_buffer_with_layout = {
		returns = ffi.types.void,
		args = { ffi.types.pointer, ffi.types.u8, ffi.types.pointer, ffi.types.u32, ffi.types.u32, ffi.types.pointer },
	},
	bgfx_encoder_set_dynamic_vertex_buffer = {
		returns = ffi.types.void,
		args = { ffi.types.pointer, ffi.types.u8, ffi.types.pointer, ffi.types.u32, ffi.types.u32 },
	},
	bgfx_encoder_set_dynamic_vertex_buffer_with_layout = {
		returns = ffi.types.void,
		args = { ffi.types.pointer, ffi.types.u8, ffi.types.pointer, ffi.types.u32, ffi.types.u32, ffi.types.pointer },
	},
	bgfx_encoder_set_transient_vertex_buffer = {
		returns = ffi.types.void,
		args = { ffi.types.pointer, ffi.types.u8, ffi.types.pointer, ffi.types.u32, ffi.types.u32 },
	},
	bgfx_encoder_set_transient_vertex_buffer_with_layout = {
		returns = ffi.types.void,
		args = { ffi.types.pointer, ffi.types.u8, ffi.types.pointer, ffi.types.u32, ffi.types.u32, ffi.types.pointer },
	},
	bgfx_encoder_set_vertex_count = { returns = ffi.types.void, args = { ffi.types.pointer, ffi.types.u32 } },
	bgfx_encoder_set_instance_data_buffer = {
		returns = ffi.types.void,
		args = { ffi.types.pointer, ffi.types.pointer, ffi.types.u32, ffi.types.u32 },
	},
	bgfx_encoder_set_instance_data_from_vertex_buffer = {
		returns = ffi.types.void,
		args = { ffi.types.pointer, ffi.types.pointer, ffi.types.u32, ffi.types.u32 },
	},
	bgfx_encoder_set_instance_data_from_dynamic_vertex_buffer = {
		returns = ffi.types.void,
		args = { ffi.types.pointer, ffi.types.pointer, ffi.types.u32, ffi.types.u32 },
	},
	bgfx_encoder_set_instance_count = { returns = ffi.types.void, args = { ffi.types.pointer, ffi.types.u32 } },
	bgfx_encoder_set_texture = {
		returns = ffi.types.void,
		args = { ffi.types.pointer, ffi.types.u8, ffi.types.pointer, ffi.types.pointer, ffi.types.u32 },
	},
	bgfx_encoder_touch = { returns = ffi.types.void, args = { ffi.types.pointer, ffi.types.u16 } },
	bgfx_encoder_submit = {
		returns = ffi.types.void,
		args = { ffi.types.pointer, ffi.types.u16, ffi.types.pointer, ffi.types.u32, ffi.types.u8 },
	},
	bgfx_encoder_submit_occlusion_query = {
		returns = ffi.types.void,
		args = { ffi.types.pointer, ffi.types.u16, ffi.types.pointer, ffi.types.pointer, ffi.types.u32, ffi.types.u8 },
	},
	bgfx_encoder_submit_indirect = {
		returns = ffi.types.void,
		args = {
			ffi.types.pointer,
			ffi.types.u16,
			ffi.types.pointer,
			ffi.types.pointer,
			ffi.types.u32,
			ffi.types.u32,
			ffi.types.u32,
			ffi.types.u8,
		},
	},
	bgfx_encoder_submit_indirect_count = {
		returns = ffi.types.void,
		args = {
			ffi.types.pointer,
			ffi.types.u16,
			ffi.types.pointer,
			ffi.types.pointer,
			ffi.types.u32,
			ffi.types.pointer,
			ffi.types.u32,
			ffi.types.u32,
			ffi.types.u32,
			ffi.types.u8,
		},
	},
	bgfx_encoder_set_compute_index_buffer = {
		returns = ffi.types.void,
		args = { ffi.types.pointer, ffi.types.u8, ffi.types.pointer, ffi.types.pointer },
	},
	bgfx_encoder_set_compute_vertex_buffer = {
		returns = ffi.types.void,
		args = { ffi.types.pointer, ffi.types.u8, ffi.types.pointer, ffi.types.pointer },
	},
	bgfx_encoder_set_compute_dynamic_index_buffer = {
		returns = ffi.types.void,
		args = { ffi.types.pointer, ffi.types.u8, ffi.types.pointer, ffi.types.pointer },
	},
	bgfx_encoder_set_compute_dynamic_vertex_buffer = {
		returns = ffi.types.void,
		args = { ffi.types.pointer, ffi.types.u8, ffi.types.pointer, ffi.types.pointer },
	},
	bgfx_encoder_set_compute_indirect_buffer = {
		returns = ffi.types.void,
		args = { ffi.types.pointer, ffi.types.u8, ffi.types.pointer, ffi.types.pointer },
	},
	bgfx_encoder_set_image = {
		returns = ffi.types.void,
		args = {
			ffi.types.pointer,
			ffi.types.u8,
			ffi.types.pointer,
			ffi.types.u8,
			ffi.types.pointer,
			ffi.types.pointer,
		},
	},
	bgfx_encoder_dispatch = {
		returns = ffi.types.void,
		args = {
			ffi.types.pointer,
			ffi.types.u16,
			ffi.types.pointer,
			ffi.types.u32,
			ffi.types.u32,
			ffi.types.u32,
			ffi.types.u8,
		},
	},
	bgfx_encoder_dispatch_indirect = {
		returns = ffi.types.void,
		args = {
			ffi.types.pointer,
			ffi.types.u16,
			ffi.types.pointer,
			ffi.types.pointer,
			ffi.types.u32,
			ffi.types.u32,
			ffi.types.u8,
		},
	},
	bgfx_encoder_discard = { returns = ffi.types.void, args = { ffi.types.pointer, ffi.types.u8 } },
	bgfx_encoder_blit = {
		returns = ffi.types.void,
		args = {
			ffi.types.pointer,
			ffi.types.u16,
			ffi.types.pointer,
			ffi.types.u8,
			ffi.types.u16,
			ffi.types.u16,
			ffi.types.u16,
			ffi.types.pointer,
			ffi.types.u8,
			ffi.types.u16,
			ffi.types.u16,
			ffi.types.u16,
			ffi.types.u16,
			ffi.types.u16,
			ffi.types.u16,
		},
	},
	bgfx_request_screen_shot = { returns = ffi.types.void, args = { ffi.types.pointer, ffi.types.pointer } },
	bgfx_render_frame = { returns = ffi.types.pointer, args = { ffi.types.i32 } },
	bgfx_set_platform_data = { returns = ffi.types.void, args = { ffi.types.pointer } },
	bgfx_get_internal_data = { returns = ffi.types.pointer, args = {} },
	bgfx_override_internal_texture_ptr = {
		returns = ffi.types.pointer,
		args = { ffi.types.pointer, ffi.types.pointer, ffi.types.u16 },
	},
	bgfx_override_internal_texture = {
		returns = ffi.types.pointer,
		args = { ffi.types.pointer, ffi.types.u16, ffi.types.u16, ffi.types.u8, ffi.types.pointer, ffi.types.u64 },
	},
	bgfx_set_marker = { returns = ffi.types.void, args = { ffi.types.pointer, ffi.types.i32 } },
	bgfx_set_state = { returns = ffi.types.void, args = { ffi.types.u64, ffi.types.u32 } },
	bgfx_set_condition = { returns = ffi.types.void, args = { ffi.types.pointer, ffi.types.u8 } },
	bgfx_set_stencil = { returns = ffi.types.void, args = { ffi.types.u32, ffi.types.u32 } },
	bgfx_set_scissor = {
		returns = ffi.types.u16,
		args = { ffi.types.u16, ffi.types.u16, ffi.types.u16, ffi.types.u16 },
	},
	bgfx_set_scissor_cached = { returns = ffi.types.void, args = { ffi.types.u16 } },
	bgfx_set_transform = { returns = ffi.types.u32, args = { ffi.types.pointer, ffi.types.u16 } },
	bgfx_set_transform_cached = { returns = ffi.types.void, args = { ffi.types.u32, ffi.types.u16 } },
	bgfx_alloc_transform = { returns = ffi.types.u32, args = { ffi.types.pointer, ffi.types.u16 } },
	bgfx_set_uniform = { returns = ffi.types.void, args = { ffi.types.pointer, ffi.types.pointer, ffi.types.u16 } },
	bgfx_set_index_buffer = { returns = ffi.types.void, args = { ffi.types.pointer, ffi.types.u32, ffi.types.u32 } },
	bgfx_set_dynamic_index_buffer = {
		returns = ffi.types.void,
		args = { ffi.types.pointer, ffi.types.u32, ffi.types.u32 },
	},
	bgfx_set_transient_index_buffer = {
		returns = ffi.types.void,
		args = { ffi.types.pointer, ffi.types.u32, ffi.types.u32 },
	},
	bgfx_set_vertex_buffer = {
		returns = ffi.types.void,
		args = { ffi.types.u8, ffi.types.pointer, ffi.types.u32, ffi.types.u32 },
	},
	bgfx_set_vertex_buffer_with_layout = {
		returns = ffi.types.void,
		args = { ffi.types.u8, ffi.types.pointer, ffi.types.u32, ffi.types.u32, ffi.types.pointer },
	},
	bgfx_set_dynamic_vertex_buffer = {
		returns = ffi.types.void,
		args = { ffi.types.u8, ffi.types.pointer, ffi.types.u32, ffi.types.u32 },
	},
	bgfx_set_dynamic_vertex_buffer_with_layout = {
		returns = ffi.types.void,
		args = { ffi.types.u8, ffi.types.pointer, ffi.types.u32, ffi.types.u32, ffi.types.pointer },
	},
	bgfx_set_transient_vertex_buffer = {
		returns = ffi.types.void,
		args = { ffi.types.u8, ffi.types.pointer, ffi.types.u32, ffi.types.u32 },
	},
	bgfx_set_transient_vertex_buffer_with_layout = {
		returns = ffi.types.void,
		args = { ffi.types.u8, ffi.types.pointer, ffi.types.u32, ffi.types.u32, ffi.types.pointer },
	},
	bgfx_set_vertex_count = { returns = ffi.types.void, args = { ffi.types.u32 } },
	bgfx_set_instance_data_buffer = {
		returns = ffi.types.void,
		args = { ffi.types.pointer, ffi.types.u32, ffi.types.u32 },
	},
	bgfx_set_instance_data_from_vertex_buffer = {
		returns = ffi.types.void,
		args = { ffi.types.pointer, ffi.types.u32, ffi.types.u32 },
	},
	bgfx_set_instance_data_from_dynamic_vertex_buffer = {
		returns = ffi.types.void,
		args = { ffi.types.pointer, ffi.types.u32, ffi.types.u32 },
	},
	bgfx_set_instance_count = { returns = ffi.types.void, args = { ffi.types.u32 } },
	bgfx_set_texture = {
		returns = ffi.types.void,
		args = { ffi.types.u8, ffi.types.pointer, ffi.types.pointer, ffi.types.u32 },
	},
	bgfx_touch = { returns = ffi.types.void, args = { ffi.types.u16 } },
	bgfx_submit = { returns = ffi.types.void, args = { ffi.types.u16, ffi.types.pointer, ffi.types.u32, ffi.types.u8 } },
	bgfx_submit_occlusion_query = {
		returns = ffi.types.void,
		args = { ffi.types.u16, ffi.types.pointer, ffi.types.pointer, ffi.types.u32, ffi.types.u8 },
	},
	bgfx_submit_indirect = {
		returns = ffi.types.void,
		args = {
			ffi.types.u16,
			ffi.types.pointer,
			ffi.types.pointer,
			ffi.types.u32,
			ffi.types.u32,
			ffi.types.u32,
			ffi.types.u8,
		},
	},
	bgfx_submit_indirect_count = {
		returns = ffi.types.void,
		args = {
			ffi.types.u16,
			ffi.types.pointer,
			ffi.types.pointer,
			ffi.types.u32,
			ffi.types.pointer,
			ffi.types.u32,
			ffi.types.u32,
			ffi.types.u32,
			ffi.types.u8,
		},
	},
	bgfx_set_compute_index_buffer = {
		returns = ffi.types.void,
		args = { ffi.types.u8, ffi.types.pointer, ffi.types.pointer },
	},
	bgfx_set_compute_vertex_buffer = {
		returns = ffi.types.void,
		args = { ffi.types.u8, ffi.types.pointer, ffi.types.pointer },
	},
	bgfx_set_compute_dynamic_index_buffer = {
		returns = ffi.types.void,
		args = { ffi.types.u8, ffi.types.pointer, ffi.types.pointer },
	},
	bgfx_set_compute_dynamic_vertex_buffer = {
		returns = ffi.types.void,
		args = { ffi.types.u8, ffi.types.pointer, ffi.types.pointer },
	},
	bgfx_set_compute_indirect_buffer = {
		returns = ffi.types.void,
		args = { ffi.types.u8, ffi.types.pointer, ffi.types.pointer },
	},
	bgfx_set_image = {
		returns = ffi.types.void,
		args = { ffi.types.u8, ffi.types.pointer, ffi.types.u8, ffi.types.pointer, ffi.types.pointer },
	},
	bgfx_dispatch = {
		returns = ffi.types.void,
		args = { ffi.types.u16, ffi.types.pointer, ffi.types.u32, ffi.types.u32, ffi.types.u32, ffi.types.u8 },
	},
	bgfx_dispatch_indirect = {
		returns = ffi.types.void,
		args = { ffi.types.u16, ffi.types.pointer, ffi.types.pointer, ffi.types.u32, ffi.types.u32, ffi.types.u8 },
	},
	bgfx_discard = { returns = ffi.types.void, args = { ffi.types.u8 } },
	bgfx_blit = {
		returns = ffi.types.void,
		args = {
			ffi.types.u16,
			ffi.types.pointer,
			ffi.types.u8,
			ffi.types.u16,
			ffi.types.u16,
			ffi.types.u16,
			ffi.types.pointer,
			ffi.types.u8,
			ffi.types.u16,
			ffi.types.u16,
			ffi.types.u16,
			ffi.types.u16,
			ffi.types.u16,
			ffi.types.u16,
		},
	},
	bgfx_get_interface = { returns = ffi.types.pointer, args = { ffi.types.u32 } },
}

return funcs
