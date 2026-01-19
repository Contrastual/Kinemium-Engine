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

local AVDeviceRect = ffi.struct({
	{ x = ffi.types.i32 },
	{ y = ffi.types.i32 },
	{ width = ffi.types.i32 },
	{ height = ffi.types.i32 },
})
export type AVDeviceRect = typeof(AVDeviceRect:new({}))

local AVDeviceInfo = ffi.struct({
	{ nb_media_types = ffi.types.i32 },
})
export type AVDeviceInfo = typeof(AVDeviceInfo:new({}))

local AVDeviceInfoList = ffi.struct({
	{ nb_devices = ffi.types.i32 },
	{ default_device = ffi.types.i32 },
})
export type AVDeviceInfoList = typeof(AVDeviceInfoList:new({}))

-- Function definitions
local funcs = {
	avdevice_version = { returns = ffi.types.pointer, args = {} },
	avdevice_register_all = { returns = ffi.types.void, args = {} },
	avdevice_app_to_dev_control_message = {
		returns = ffi.types.i32,
		args = { ffi.types.pointer, ffi.types.pointer, ffi.types.void, ffi.types.u64 },
	},
	avdevice_dev_to_app_control_message = {
		returns = ffi.types.i32,
		args = { ffi.types.pointer, ffi.types.pointer, ffi.types.void, ffi.types.u64 },
	},
	avdevice_list_devices = { returns = ffi.types.i32, args = { ffi.types.pointer, ffi.types.pointer } },
	avdevice_free_list_devices = { returns = ffi.types.void, args = { ffi.types.pointer } },
	avdevice_list_input_sources = {
		returns = ffi.types.i32,
		args = { ffi.types.pointer, ffi.types.pointer, ffi.types.pointer, ffi.types.pointer },
	},
	avdevice_list_output_sinks = {
		returns = ffi.types.i32,
		args = { ffi.types.pointer, ffi.types.pointer, ffi.types.pointer, ffi.types.pointer },
	},
}

local structs = {
	AVDeviceRect = AVDeviceRect,
	AVDeviceInfo = AVDeviceInfo,
	AVDeviceInfoList = AVDeviceInfoList,
}

return { funcs = funcs, structs = structs }
