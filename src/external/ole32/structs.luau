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

local STGOPTIONS = ffi.struct({
	{ usVersion = ffi.types.pointer },
	{ reserved = ffi.types.pointer },
	{ ulSectorSize = ffi.types.pointer },
	{ pwcsTemplateFile = ffi.types.pointer },
})
export type STGOPTIONS = typeof(STGOPTIONS:new({}))

local structs = {
	STGOPTIONS = STGOPTIONS,
}

return structs
