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

local RB_Instance = ffi.struct({
	{ position = ffi.types.pointer },
	{ scale = ffi.types.pointer },
	{ rotation = ffi.types.pointer },
	{ color = ffi.types.pointer },
})
export type RB_Instance = typeof(RB_Instance:new({}))

local RB_Batch = ffi.struct({
	{ maxInstances = ffi.types.i32 },
	{ instanceCount = ffi.types.i32 },
	{ instances = ffi.types.pointer },
	{ mesh = ffi.types.pointer },
	{ shader = ffi.types.pointer },
	{ instanceVbo = ffi.types.u32 },
	{ isDirty = ffi.types.u8 },
})
export type RB_Batch = typeof(RB_Batch:new({}))

local structs = {
	RB_Instance = RB_Instance,
	RB_Batch = RB_Batch,
}

return structs
