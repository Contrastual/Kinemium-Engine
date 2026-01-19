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

-- Function definitions
local funcs = {
	swr_init = { returns = ffi.types.i32, args = { ffi.types.pointer } },
	swr_is_initialized = { returns = ffi.types.i32, args = { ffi.types.pointer } },
	swr_alloc_set_opts2 = {
		returns = ffi.types.i32,
		args = {
			ffi.types.pointer,
			ffi.types.pointer,
			ffi.types.pointer,
			ffi.types.i32,
			ffi.types.pointer,
			ffi.types.pointer,
			ffi.types.i32,
			ffi.types.i32,
			ffi.types.void,
		},
	},
	swr_free = { returns = ffi.types.void, args = { ffi.types.pointer } },
	swr_close = { returns = ffi.types.void, args = { ffi.types.pointer } },
	swr_convert = {
		returns = ffi.types.i32,
		args = { ffi.types.pointer, ffi.types.pointer, ffi.types.i32, ffi.types.pointer, ffi.types.i32 },
	},
	swr_next_pts = { returns = ffi.types.i64, args = { ffi.types.pointer, ffi.types.i64 } },
	swr_set_compensation = { returns = ffi.types.i32, args = { ffi.types.pointer, ffi.types.i32, ffi.types.i32 } },
	swr_set_channel_mapping = { returns = ffi.types.i32, args = { ffi.types.pointer, ffi.types.pointer } },
	swr_build_matrix2 = {
		returns = ffi.types.i32,
		args = {
			ffi.types.pointer,
			ffi.types.pointer,
			ffi.types.double,
			ffi.types.double,
			ffi.types.double,
			ffi.types.double,
			ffi.types.double,
			ffi.types.double,
			ffi.types.pointer,
			ffi.types.pointer,
			ffi.types.void,
		},
	},
	swr_set_matrix = { returns = ffi.types.i32, args = { ffi.types.pointer, ffi.types.pointer, ffi.types.i32 } },
	swr_drop_output = { returns = ffi.types.i32, args = { ffi.types.pointer, ffi.types.i32 } },
	swr_inject_silence = { returns = ffi.types.i32, args = { ffi.types.pointer, ffi.types.i32 } },
	swr_get_delay = { returns = ffi.types.i64, args = { ffi.types.pointer, ffi.types.i64 } },
	swr_get_out_samples = { returns = ffi.types.i32, args = { ffi.types.pointer, ffi.types.i32 } },
	swresample_version = { returns = ffi.types.pointer, args = {} },
	swr_convert_frame = { returns = ffi.types.i32, args = { ffi.types.pointer, ffi.types.pointer, ffi.types.pointer } },
	swr_config_frame = { returns = ffi.types.i32, args = { ffi.types.pointer, ffi.types.pointer, ffi.types.pointer } },
}

return funcs
