--!strict
--!optimize 2
--!native

local ffi = zune.ffi

-- Struct definitions (ordered by dependencies)
-- NOTE: Some structs may have FIXME comments for array sizes that need manual definition

local SwsContext = ffi.struct({
	{ flags = ffi.types.pointer },
	{ scaler_params = ffi.types.double:array(2) },
	{ threads = ffi.types.i32 },
	{ dither = ffi.types.pointer },
	{ alpha_blend = ffi.types.pointer },
	{ gamma_flag = ffi.types.i32 },
	{ src_format = ffi.types.i32 },
	{ dst_format = ffi.types.i32 },
	{ src_range = ffi.types.i32 },
	{ dst_range = ffi.types.i32 },
	{ src_v_chr_pos = ffi.types.i32 },
	{ src_h_chr_pos = ffi.types.i32 },
	{ dst_v_chr_pos = ffi.types.i32 },
	{ dst_h_chr_pos = ffi.types.i32 },
	{ intent = ffi.types.i32 },
})
export type SwsContext = typeof(SwsContext:new({}))

local SwsVector = ffi.struct({
	{ length = ffi.types.i32 },
})
export type SwsVector = typeof(SwsVector:new({}))

-- Function definitions
local funcs = {
	sws_scale_frame = { returns = ffi.types.i32, args = { ffi.types.pointer, ffi.types.pointer, ffi.types.pointer } },
	sws_isSupportedInput = { returns = ffi.types.i32, args = { ffi.types.pointer } },
	sws_isSupportedOutput = { returns = ffi.types.i32, args = { ffi.types.pointer } },
	sws_isSupportedEndiannessConversion = { returns = ffi.types.i32, args = { ffi.types.pointer } },
	sws_init_context = { returns = ffi.types.i32, args = { ffi.types.pointer, ffi.types.pointer, ffi.types.pointer } },
	sws_freeContext = { returns = ffi.types.void, args = { ffi.types.pointer } },
	sws_scale = {
		returns = ffi.types.i32,
		args = {
			ffi.types.pointer,
			ffi.types.pointer,
			ffi.types.pointer,
			ffi.types.i32,
			ffi.types.i32,
			ffi.types.pointer,
			ffi.types.pointer,
		},
	},
	sws_frame_start = { returns = ffi.types.i32, args = { ffi.types.pointer, ffi.types.pointer, ffi.types.pointer } },
	sws_frame_end = { returns = ffi.types.void, args = { ffi.types.pointer } },
	sws_send_slice = { returns = ffi.types.i32, args = { ffi.types.pointer, ffi.types.u32, ffi.types.u32 } },
	sws_receive_slice = { returns = ffi.types.i32, args = { ffi.types.pointer, ffi.types.u32, ffi.types.u32 } },
	sws_receive_slice_alignment = { returns = ffi.types.i32, args = { ffi.types.pointer } },
	sws_setColorspaceDetails = {
		returns = ffi.types.i32,
		args = {
			ffi.types.pointer,
			ffi.types.pointer,
			ffi.types.i32,
			ffi.types.pointer,
			ffi.types.i32,
			ffi.types.i32,
			ffi.types.i32,
			ffi.types.i32,
		},
	},
	sws_getColorspaceDetails = {
		returns = ffi.types.i32,
		args = {
			ffi.types.pointer,
			ffi.types.i32,
			ffi.types.i32,
			ffi.types.i32,
			ffi.types.i32,
			ffi.types.i32,
			ffi.types.i32,
			ffi.types.i32,
		},
	},
	sws_scaleVec = { returns = ffi.types.void, args = { ffi.types.pointer, ffi.types.double } },
	sws_normalizeVec = { returns = ffi.types.void, args = { ffi.types.pointer, ffi.types.double } },
	sws_freeVec = { returns = ffi.types.void, args = { ffi.types.pointer } },
	sws_freeFilter = { returns = ffi.types.void, args = { ffi.types.pointer } },
	sws_convertPalette8ToPacked32 = {
		returns = ffi.types.void,
		args = { ffi.types.pointer, ffi.types.u8, ffi.types.i32, ffi.types.pointer },
	},
	sws_convertPalette8ToPacked24 = {
		returns = ffi.types.void,
		args = { ffi.types.pointer, ffi.types.u8, ffi.types.i32, ffi.types.pointer },
	},
}

local structs = {
	SwsContext = SwsContext,
	SwsVector = SwsVector,
}

return { funcs = funcs, structs = structs }
