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

-- Struct definitions (ordered by dependencies)
-- NOTE: Some structs may have FIXME comments for array sizes that need manual definition

local AVFilter = ffi.struct({
	{ flags = ffi.types.i32 },
})
export type AVFilter = typeof(AVFilter:new({}))

local AVFilterContext = ffi.struct({
	{ nb_inputs = ffi.types.pointer },
	{ nb_outputs = ffi.types.pointer },
	{ thread_type = ffi.types.i32 },
	{ nb_threads = ffi.types.i32 },
	{ is_disabled = ffi.types.i32 },
	{ ready = ffi.types.pointer },
	{ extra_hw_frames = ffi.types.i32 },
})
export type AVFilterContext = typeof(AVFilterContext:new({}))

local AVFilterGraph = ffi.struct({
	{ nb_filters = ffi.types.pointer },
	{ thread_type = ffi.types.i32 },
	{ nb_threads = ffi.types.i32 },
	{ max_buffered_frames = ffi.types.pointer },
})
export type AVFilterGraph = typeof(AVFilterGraph:new({}))

local AVFilterInOut = ffi.struct({
	{ pad_idx = ffi.types.i32 },
})
export type AVFilterInOut = typeof(AVFilterInOut:new({}))

local AVFilterParams = ffi.struct({
	{ nb_inputs = ffi.types.pointer },
	{ nb_outputs = ffi.types.pointer },
})
export type AVFilterParams = typeof(AVFilterParams:new({}))

local AVFilterChain = ffi.struct({
	{ nb_filters = ffi.types.u64 },
})
export type AVFilterChain = typeof(AVFilterChain:new({}))

local AVFilterGraphSegment = ffi.struct({
	{ nb_chains = ffi.types.u64 },
})
export type AVFilterGraphSegment = typeof(AVFilterGraphSegment:new({}))

local AVBufferSrcParameters = ffi.struct({
	{ format = ffi.types.i32 },
	{ time_base = ffi.types.pointer },
	{ sample_aspect_ratio = ffi.types.pointer },
	{ frame_rate = ffi.types.pointer },
	{ sample_rate = ffi.types.i32 },
	{ ch_layout = ffi.types.pointer },
	{ color_space = ffi.types.pointer },
	{ color_range = ffi.types.pointer },
	{ nb_side_data = ffi.types.i32 },
})
export type AVBufferSrcParameters = typeof(AVBufferSrcParameters:new({}))

-- Function definitions
local funcs = {
	avfilter_version = { returns = ffi.types.pointer, args = {} },
	avfilter_pad_get_type = { returns = ffi.types.pointer, args = { ffi.types.pointer, ffi.types.i32 } },
	avfilter_link_get_hw_frames_ctx = { returns = ffi.types.pointer, args = { ffi.types.pointer } },
	avfilter_filter_pad_count = { returns = ffi.types.pointer, args = { ffi.types.pointer, ffi.types.i32 } },
	avfilter_link = {
		returns = ffi.types.i32,
		args = { ffi.types.pointer, ffi.types.pointer, ffi.types.pointer, ffi.types.pointer },
	},
	avfilter_process_command = {
		returns = ffi.types.i32,
		args = { ffi.types.pointer, ffi.types.pointer, ffi.types.pointer, ffi.types.i8, ffi.types.i32, ffi.types.i32 },
	},
	avfilter_init_str = { returns = ffi.types.i32, args = { ffi.types.pointer, ffi.types.pointer } },
	avfilter_init_dict = { returns = ffi.types.i32, args = { ffi.types.pointer, ffi.types.pointer } },
	avfilter_free = { returns = ffi.types.void, args = { ffi.types.pointer } },
	avfilter_insert_filter = {
		returns = ffi.types.i32,
		args = { ffi.types.pointer, ffi.types.pointer, ffi.types.pointer, ffi.types.pointer },
	},
	avfilter_graph_create_filter = {
		returns = ffi.types.i32,
		args = {
			ffi.types.pointer,
			ffi.types.pointer,
			ffi.types.pointer,
			ffi.types.pointer,
			ffi.types.pointer,
		},
	},
	avfilter_graph_set_auto_convert = { returns = ffi.types.void, args = { ffi.types.pointer, ffi.types.pointer } },
	avfilter_graph_config = { returns = ffi.types.i32, args = { ffi.types.pointer } },
	avfilter_graph_free = { returns = ffi.types.void, args = { ffi.types.pointer } },
	avfilter_inout_free = { returns = ffi.types.void, args = { ffi.types.pointer } },
	avfilter_graph_parse = {
		returns = ffi.types.i32,
		args = { ffi.types.pointer, ffi.types.pointer, ffi.types.pointer, ffi.types.pointer },
	},
	avfilter_graph_parse_ptr = {
		returns = ffi.types.i32,
		args = { ffi.types.pointer, ffi.types.pointer, ffi.types.pointer, ffi.types.pointer },
	},
	avfilter_graph_parse2 = {
		returns = ffi.types.i32,
		args = { ffi.types.pointer, ffi.types.pointer, ffi.types.pointer, ffi.types.pointer },
	},
	avfilter_graph_segment_parse = {
		returns = ffi.types.i32,
		args = { ffi.types.pointer, ffi.types.pointer, ffi.types.i32, ffi.types.pointer },
	},
	avfilter_graph_segment_create_filters = { returns = ffi.types.i32, args = { ffi.types.pointer, ffi.types.i32 } },
	avfilter_graph_segment_apply_opts = { returns = ffi.types.i32, args = { ffi.types.pointer, ffi.types.i32 } },
	avfilter_graph_segment_init = { returns = ffi.types.i32, args = { ffi.types.pointer, ffi.types.i32 } },
	avfilter_graph_segment_link = {
		returns = ffi.types.i32,
		args = { ffi.types.pointer, ffi.types.i32, ffi.types.pointer, ffi.types.pointer },
	},
	avfilter_graph_segment_apply = {
		returns = ffi.types.i32,
		args = { ffi.types.pointer, ffi.types.i32, ffi.types.pointer, ffi.types.pointer },
	},
	avfilter_graph_segment_free = { returns = ffi.types.void, args = { ffi.types.pointer } },
	avfilter_graph_send_command = {
		returns = ffi.types.i32,
		args = {
			ffi.types.pointer,
			ffi.types.pointer,
			ffi.types.pointer,
			ffi.types.pointer,
			ffi.types.i8,
			ffi.types.i32,
			ffi.types.i32,
		},
	},
	avfilter_graph_queue_command = {
		returns = ffi.types.i32,
		args = {
			ffi.types.pointer,
			ffi.types.pointer,
			ffi.types.pointer,
			ffi.types.pointer,
			ffi.types.i32,
			ffi.types.double,
		},
	},
	avfilter_graph_request_oldest = { returns = ffi.types.i32, args = { ffi.types.pointer } },
	av_buffersink_get_frame_flags = {
		returns = ffi.types.i32,
		args = { ffi.types.pointer, ffi.types.pointer, ffi.types.i32 },
	},
	av_buffersink_set_frame_size = { returns = ffi.types.void, args = { ffi.types.pointer, ffi.types.pointer } },
	av_buffersink_get_type = { returns = ffi.types.pointer, args = { ffi.types.pointer } },
	av_buffersink_get_time_base = { returns = ffi.types.pointer, args = { ffi.types.pointer } },
	av_buffersink_get_format = { returns = ffi.types.i32, args = { ffi.types.pointer } },
	av_buffersink_get_frame_rate = { returns = ffi.types.pointer, args = { ffi.types.pointer } },
	av_buffersink_get_w = { returns = ffi.types.i32, args = { ffi.types.pointer } },
	av_buffersink_get_h = { returns = ffi.types.i32, args = { ffi.types.pointer } },
	av_buffersink_get_sample_aspect_ratio = { returns = ffi.types.pointer, args = { ffi.types.pointer } },
	av_buffersink_get_colorspace = { returns = ffi.types.pointer, args = { ffi.types.pointer } },
	av_buffersink_get_color_range = { returns = ffi.types.pointer, args = { ffi.types.pointer } },
	av_buffersink_get_channels = { returns = ffi.types.i32, args = { ffi.types.pointer } },
	av_buffersink_get_ch_layout = { returns = ffi.types.i32, args = { ffi.types.pointer, ffi.types.pointer } },
	av_buffersink_get_sample_rate = { returns = ffi.types.i32, args = { ffi.types.pointer } },
	av_buffersink_get_hw_frames_ctx = { returns = ffi.types.pointer, args = { ffi.types.pointer } },
	av_buffersink_get_frame = { returns = ffi.types.i32, args = { ffi.types.pointer, ffi.types.pointer } },
	av_buffersink_get_samples = {
		returns = ffi.types.i32,
		args = { ffi.types.pointer, ffi.types.pointer, ffi.types.i32 },
	},
	av_buffersrc_get_nb_failed_requests = { returns = ffi.types.pointer, args = { ffi.types.pointer } },
	av_buffersrc_parameters_set = { returns = ffi.types.i32, args = { ffi.types.pointer, ffi.types.pointer } },
	av_buffersrc_write_frame = { returns = ffi.types.i32, args = { ffi.types.pointer, ffi.types.pointer } },
	av_buffersrc_add_frame = { returns = ffi.types.i32, args = { ffi.types.pointer, ffi.types.pointer } },
	av_buffersrc_add_frame_flags = {
		returns = ffi.types.i32,
		args = { ffi.types.pointer, ffi.types.pointer, ffi.types.i32 },
	},
	av_buffersrc_close = { returns = ffi.types.i32, args = { ffi.types.pointer, ffi.types.i64, ffi.types.pointer } },
}

local structs = {
	AVFilter = AVFilter,
	AVFilterContext = AVFilterContext,
	AVFilterGraph = AVFilterGraph,
	AVFilterInOut = AVFilterInOut,
	AVFilterParams = AVFilterParams,
	AVFilterChain = AVFilterChain,
	AVFilterGraphSegment = AVFilterGraphSegment,
	AVBufferSrcParameters = AVBufferSrcParameters,
}

return { funcs = funcs, structs = structs }
