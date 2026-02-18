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

local nfdpathsetenum_t = ffi.struct({
	{ ptr = ffi.types.pointer },
})
export type nfdpathsetenum_t = typeof(nfdpathsetenum_t:new({}))

local nfdu8filteritem_t = ffi.struct({
	{ name = ffi.types.pointer },
	{ spec = ffi.types.pointer },
})
export type nfdu8filteritem_t = typeof(nfdu8filteritem_t:new({}))

local nfdnfilteritem_t = ffi.struct({
	{ name = ffi.types.pointer },
	{ spec = ffi.types.pointer },
})
export type nfdnfilteritem_t = typeof(nfdnfilteritem_t:new({}))

local nfdwindowhandle_t = ffi.struct({
	{ type = ffi.types.u64 },
	{ handle = ffi.types.pointer },
})
export type nfdwindowhandle_t = typeof(nfdwindowhandle_t:new({}))

local nfdopendialogu8args_t = ffi.struct({
	{ filterList = ffi.types.pointer },
	{ filterCount = ffi.types.u32 },
	{ defaultPath = ffi.types.pointer },
	{ parentWindow = nfdwindowhandle_t },
})
export type nfdopendialogu8args_t = typeof(nfdopendialogu8args_t:new({}))

local nfdopendialognargs_t = ffi.struct({
	{ filterList = ffi.types.pointer },
	{ filterCount = ffi.types.u32 },
	{ defaultPath = ffi.types.pointer },
	{ parentWindow = nfdwindowhandle_t },
})
export type nfdopendialognargs_t = typeof(nfdopendialognargs_t:new({}))

local nfdsavedialogu8args_t = ffi.struct({
	{ filterList = ffi.types.pointer },
	{ filterCount = ffi.types.u32 },
	{ defaultPath = ffi.types.pointer },
	{ defaultName = ffi.types.pointer },
	{ parentWindow = nfdwindowhandle_t },
})
export type nfdsavedialogu8args_t = typeof(nfdsavedialogu8args_t:new({}))

local nfdsavedialognargs_t = ffi.struct({
	{ filterList = ffi.types.pointer },
	{ filterCount = ffi.types.u32 },
	{ defaultPath = ffi.types.pointer },
	{ defaultName = ffi.types.pointer },
	{ parentWindow = nfdwindowhandle_t },
})
export type nfdsavedialognargs_t = typeof(nfdsavedialognargs_t:new({}))

local nfdpickfolderu8args_t = ffi.struct({
	{ defaultPath = ffi.types.pointer },
	{ parentWindow = nfdwindowhandle_t },
})
export type nfdpickfolderu8args_t = typeof(nfdpickfolderu8args_t:new({}))

local nfdpickfoldernargs_t = ffi.struct({
	{ defaultPath = ffi.types.pointer },
	{ parentWindow = nfdwindowhandle_t },
})
export type nfdpickfoldernargs_t = typeof(nfdpickfoldernargs_t:new({}))

local structs = {
	nfdpathsetenum_t = nfdpathsetenum_t,
	nfdu8filteritem_t = nfdu8filteritem_t,
	nfdnfilteritem_t = nfdnfilteritem_t,
	nfdwindowhandle_t = nfdwindowhandle_t,
	nfdopendialogu8args_t = nfdopendialogu8args_t,
	nfdopendialognargs_t = nfdopendialognargs_t,
	nfdsavedialogu8args_t = nfdsavedialogu8args_t,
	nfdsavedialognargs_t = nfdsavedialognargs_t,
	nfdpickfolderu8args_t = nfdpickfolderu8args_t,
	nfdpickfoldernargs_t = nfdpickfoldernargs_t,
}

return structs
