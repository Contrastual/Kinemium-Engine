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

local sail_conversion_options = ffi.struct({
	{ options = ffi.types.i32 }, { background48 = ffi.types.pointer }, { background24 = ffi.types.pointer },
})
export type sail_conversion_options = typeof(sail_conversion_options:new({}))

local structs = {
	sail_conversion_options = sail_conversion_options,
}

return structs