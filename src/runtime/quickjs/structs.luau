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

local JSValue = ffi.struct({
	{ u = ffi.types.pointer }, { tag = ffi.types.i64 },
})
export type JSValue = typeof(JSValue:new({}))

local JSMallocFunctions = ffi.struct({
	{ js_calloc = ffi.types.pointer }, { js_malloc = ffi.types.pointer }, { js_free = ffi.types.pointer }, { js_realloc = ffi.types.pointer },
	{ js_malloc_usable_size = ffi.types.pointer },
})
export type JSMallocFunctions = typeof(JSMallocFunctions:new({}))

local JSMemoryUsage = ffi.struct({
	{ malloc_size = ffi.types.i64 }, { malloc_limit = ffi.types.i64 }, { memory_used_size = ffi.types.i64 }, { malloc_count = ffi.types.i64 },
	{ memory_used_count = ffi.types.i64 }, { atom_count = ffi.types.i64 }, { atom_size = ffi.types.i64 }, { str_count = ffi.types.i64 },
	{ str_size = ffi.types.i64 }, { obj_count = ffi.types.i64 }, { obj_size = ffi.types.i64 }, { prop_count = ffi.types.i64 },
	{ prop_size = ffi.types.i64 }, { shape_count = ffi.types.i64 }, { shape_size = ffi.types.i64 }, { js_func_count = ffi.types.i64 },
	{ js_func_size = ffi.types.i64 }, { js_func_code_size = ffi.types.i64 }, { js_func_pc2line_count = ffi.types.i64 }, { js_func_pc2line_size = ffi.types.i64 },
	{ c_func_count = ffi.types.i64 }, { array_count = ffi.types.i64 }, { fast_array_count = ffi.types.i64 }, { fast_array_elements = ffi.types.i64 },
	{ binary_object_count = ffi.types.i64 }, { binary_object_size = ffi.types.i64 },
})
export type JSMemoryUsage = typeof(JSMemoryUsage:new({}))

local JSPropertyEnum = ffi.struct({
	{ is_enumerable = ffi.types.u8 }, { atom = ffi.types.u32 },
})
export type JSPropertyEnum = typeof(JSPropertyEnum:new({}))

local JSPropertyDescriptor = ffi.struct({
	{ flags = ffi.types.i32 }, { value = JSValue }, { getter = JSValue }, { setter = JSValue },
})
export type JSPropertyDescriptor = typeof(JSPropertyDescriptor:new({}))

local JSClassExoticMethods = ffi.struct({
	{ get_own_property = ffi.types.pointer }, { get_own_property_names = ffi.types.pointer }, { delete_property = ffi.types.pointer }, { define_own_property = ffi.types.pointer },
	{ has_property = ffi.types.pointer }, { get_property = ffi.types.pointer }, { set_property = ffi.types.pointer },
})
export type JSClassExoticMethods = typeof(JSClassExoticMethods:new({}))

local JSClassDef = ffi.struct({
	{ class_name = ffi.types.pointer }, { finalizer = ffi.types.pointer }, { gc_mark = ffi.types.pointer }, { call = ffi.types.pointer },
	{ exotic = ffi.types.pointer },
})
export type JSClassDef = typeof(JSClassDef:new({}))

local JSEvalOptions = ffi.struct({
	{ version = ffi.types.i32 }, { eval_flags = ffi.types.i32 }, { filename = ffi.types.pointer }, { line_num = ffi.types.i32 },
})
export type JSEvalOptions = typeof(JSEvalOptions:new({}))

local JSSABTab = ffi.struct({
	{ tab = ffi.types.pointer }, { len = ffi.types.u64 },
})
export type JSSABTab = typeof(JSSABTab:new({}))

local func = ffi.struct({
	{ name = ffi.types.pointer }, { prop_flags = ffi.types.u8 }, { def_type = ffi.types.u8 }, { magic = ffi.types.i16 },
	{ length = ffi.types.pointer }, { cproto = ffi.types.u8 }, { cfunc = ffi.types.pointer },
})
export type func = typeof(func:new({}))

local JSSharedArrayBufferFunctions = ffi.struct({
	{ sab_alloc = ffi.types.pointer }, { sab_free = ffi.types.pointer }, { sab_dup = ffi.types.pointer }, { sab_opaque = ffi.types.pointer },
})
export type JSSharedArrayBufferFunctions = typeof(JSSharedArrayBufferFunctions:new({}))

local structs = {
	JSValue = JSValue,
	JSMallocFunctions = JSMallocFunctions,
	JSMemoryUsage = JSMemoryUsage,
	JSPropertyEnum = JSPropertyEnum,
	JSPropertyDescriptor = JSPropertyDescriptor,
	JSClassExoticMethods = JSClassExoticMethods,
	JSClassDef = JSClassDef,
	JSEvalOptions = JSEvalOptions,
	JSSABTab = JSSABTab,
	func = func,
	JSSharedArrayBufferFunctions = JSSharedArrayBufferFunctions,
}

return structs