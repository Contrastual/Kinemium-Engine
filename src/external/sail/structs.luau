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

local sail_codec = ffi.struct({
	{ layout = ffi.types.i32 }, { handle = ffi.types.pointer }, { v8 = ffi.types.pointer },
})
export type sail_codec = typeof(sail_codec:new({}))

local sail_codec_bundle = ffi.struct({
	{ codec_info = ffi.types.pointer }, { codec = ffi.types.pointer },
})
export type sail_codec_bundle = typeof(sail_codec_bundle:new({}))

local sail_codec_bundle_node = ffi.struct({
	{ codec_bundle = ffi.types.pointer }, { next = ffi.types.pointer },
})
export type sail_codec_bundle_node = typeof(sail_codec_bundle_node:new({}))

local sail_codec_info = ffi.struct({
	{ path = ffi.types.pointer }, { layout = ffi.types.i32 }, { priority = ffi.types.pointer }, { version = ffi.types.pointer },
	{ name = ffi.types.pointer }, { description = ffi.types.pointer }, { magic_number_node = ffi.types.pointer }, { extension_node = ffi.types.pointer },
	{ mime_type_node = ffi.types.pointer }, { load_features = ffi.types.pointer }, { save_features = ffi.types.pointer },
})
export type sail_codec_info = typeof(sail_codec_info:new({}))

local sail_codec_layout_v8 = ffi.struct({
	{ load_init = ffi.types.pointer }, { load_seek_next_frame = ffi.types.pointer }, { load_frame = ffi.types.pointer }, { load_finish = ffi.types.pointer },
	{ save_init = ffi.types.pointer }, { save_seek_next_frame = ffi.types.pointer }, { save_frame = ffi.types.pointer }, { save_finish = ffi.types.pointer },
})
export type sail_codec_layout_v8 = typeof(sail_codec_layout_v8:new({}))

local sail_context = ffi.struct({
	{ initialized = ffi.types.u8 }, { codec_bundle_node = ffi.types.pointer },
})
export type sail_context = typeof(sail_context:new({}))

local hidden_state = ffi.struct({
	{ io = ffi.types.pointer }, { own_io = ffi.types.u8 }, { load_options = ffi.types.pointer }, { save_options = ffi.types.pointer },
	{ state = ffi.types.pointer }, { codec_info = ffi.types.pointer }, { codec = ffi.types.pointer },
})
export type hidden_state = typeof(hidden_state:new({}))

local structs = {
	sail_codec = sail_codec,
	sail_codec_bundle = sail_codec_bundle,
	sail_codec_bundle_node = sail_codec_bundle_node,
	sail_codec_info = sail_codec_info,
	sail_codec_layout_v8 = sail_codec_layout_v8,
	sail_context = sail_context,
	hidden_state = hidden_state,
}

return structs