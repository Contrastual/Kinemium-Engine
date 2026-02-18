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

local webview_version_t = ffi.struct({
	{ major = ffi.types.u32 },
	{ minor = ffi.types.u32 },
	{ patch = ffi.types.u32 },
})
export type webview_version_t = typeof(webview_version_t:new({}))

local webview_version_info_t = ffi.struct({
	{ version = webview_version_t },
	{ version_number = ffi.types.i8:array(32) },
	{ pre_release = ffi.types.i8:array(48) },
	{ build_metadata = ffi.types.i8:array(48) },
})
export type webview_version_info_t = typeof(webview_version_info_t:new({}))

local structs = {
	webview_version_t = webview_version_t,
	webview_version_info_t = webview_version_info_t,
}

return structs
