local ffi = zune.ffi

-- Type aliases for FFI
type int = number
type float = number
type bool = boolean
type cstring = string
type FFIPointer = typeof(ffi.types.pointer)

-- Import struct types
local structs = require("./structs")
type webview_version_info_t = structs.webview_version_info_t
type webview_version_t = structs.webview_version_t

export type Fns = {
	webview_create: (debug: int, window: () -> ()) -> FFIPointer,
	webview_destroy: (w: FFIPointer) -> FFIPointer,
	webview_eval: (w: FFIPointer, js: int) -> FFIPointer,
	webview_init: (w: FFIPointer, js: int) -> FFIPointer,
	webview_navigate: (w: FFIPointer, url: int) -> FFIPointer,
	webview_return: (w: FFIPointer, id: int, status: int, result: int) -> FFIPointer,
	webview_run: (w: FFIPointer) -> FFIPointer,
	webview_set_html: (w: FFIPointer, html: int) -> FFIPointer,
	webview_set_size: (w: FFIPointer, width: int, height: int, hints: FFIPointer) -> FFIPointer,
	webview_set_title: (w: FFIPointer, title: int) -> FFIPointer,
	webview_terminate: (w: FFIPointer) -> FFIPointer,
	webview_unbind: (w: FFIPointer, name: int) -> FFIPointer,
}

local funcs = {
	webview_create = {
		returns = ffi.types.pointer,
		args = { ffi.types.i32, ffi.types.pointer },
	},
	webview_destroy = { returns = ffi.types.pointer, args = { ffi.types.pointer } },
	webview_run = { returns = ffi.types.pointer, args = { ffi.types.pointer } },
	webview_terminate = { returns = ffi.types.pointer, args = { ffi.types.pointer } },
	webview_set_title = { returns = ffi.types.pointer, args = { ffi.types.pointer, ffi.types.pointer } },
	webview_set_size = {
		returns = ffi.types.pointer,
		args = { ffi.types.pointer, ffi.types.i32, ffi.types.i32, ffi.types.pointer },
	},
	webview_navigate = { returns = ffi.types.pointer, args = { ffi.types.pointer, ffi.types.pointer } },
	webview_set_html = { returns = ffi.types.pointer, args = { ffi.types.pointer, ffi.types.pointer } },
	webview_init = { returns = ffi.types.pointer, args = { ffi.types.pointer, ffi.types.pointer } },
	webview_eval = { returns = ffi.types.pointer, args = { ffi.types.pointer, ffi.types.pointer } },
	webview_unbind = { returns = ffi.types.pointer, args = { ffi.types.pointer, ffi.types.pointer } },
	webview_return = {
		returns = ffi.types.pointer,
		args = { ffi.types.pointer, ffi.types.i8, ffi.types.i32, ffi.types.i8 },
	},
}

return funcs
