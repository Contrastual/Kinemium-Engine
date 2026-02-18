--!strict
--!optimize 2
-- Made by FFIGen (Kinemium)

local path = "./src/external/gtk/bin/"
local zembed = require("@zembed")
if zembed.IsEmbedded() then
	path = "./"
end
local ffi = zune.ffi
local Downloader = require("@Downloader")

local structs = require("./gtk/structs")
local funcs = require("./gtk/funcs")
local constants = require("./gtk/constants")

local suffix = ffi.suffix
local libname = "gtk-4-1." .. suffix

--[[
local gtkUrl = "https://github.com/wingtk/gvsbuild/releases/download/2026.1.0/GTK4_Gvsbuild_2026.1.0_x64.zip"

print("Downloading GTK")
Downloader.downloadAndExtract(gtkUrl, dll, function(file)
	local value = string.find(file, ".dll")
	if value then
		return true
	else
		return false
	end
end)
--]]

suffix = "." .. ffi.suffix
ffi.dlopen(path .. "zlib1" .. suffix, {})
ffi.dlopen(path .. "libpng16" .. suffix, {})
ffi.dlopen(path .. "jpeg62" .. suffix, {})
ffi.dlopen(path .. "pcre2-8-0" .. suffix, {})
ffi.dlopen(path .. "turbojpeg" .. suffix, {})
ffi.dlopen(path .. "freetype-6" .. suffix, {})
ffi.dlopen(path .. "libexpat" .. suffix, {})
ffi.dlopen(path .. "tiff" .. suffix, {})
ffi.dlopen(path .. "fribidi-0" .. suffix, {})
ffi.dlopen(path .. "iconv" .. suffix, {})
ffi.dlopen(path .. "intl" .. suffix, {})
ffi.dlopen(path .. "fontconfig-1" .. suffix, {})
ffi.dlopen(path .. "fribidi-0" .. suffix, {})
ffi.dlopen(path .. "glib-2.0-0" .. suffix, {})
ffi.dlopen(path .. "ffi-8" .. suffix, {})
local gobject = ffi.dlopen(path .. "gobject-2.0-0" .. suffix, {
	g_signal_connect_data = {
		returns = ffi.types.u64,
		args = {
			ffi.types.pointer, -- instance
			ffi.types.pointer, -- signal_name
			ffi.types.pointer, -- callback
			ffi.types.pointer, -- data
			ffi.types.pointer, -- destroy_data
			ffi.types.i32, -- connect_flags
		},
	},

	g_signal_handler_disconnect = {
		returns = ffi.types.void,
		args = {
			ffi.types.pointer, -- instance
			ffi.types.u64, -- handler_id
		},
	},

	g_object_unref = {
		returns = ffi.types.void,
		args = { ffi.types.pointer },
	},

	g_object_ref = {
		returns = ffi.types.pointer,
		args = { ffi.types.pointer },
	},
})
ffi.dlopen(path .. "pixman-1-0" .. suffix, {})
ffi.dlopen(path .. "harfbuzz" .. suffix, {})
ffi.dlopen(path .. "harfbuzz-subset" .. suffix, {})
ffi.dlopen(path .. "gmodule-2.0-0" .. suffix, {})
local gio = ffi.dlopen(path .. "gio-2.0-0" .. suffix, {
	g_application_run = {
		returns = ffi.types.i32,
		args = {
			ffi.types.pointer, -- application
			ffi.types.i32, -- argc
			ffi.types.pointer, -- argv
		},
	},

	g_application_quit = {
		returns = ffi.types.void,
		args = { ffi.types.pointer },
	},
})
ffi.dlopen(path .. "gdk_pixbuf-2.0-0" .. suffix, {})
ffi.dlopen(path .. "graphene-1.0-0" .. suffix, {})
ffi.dlopen(path .. "cairo-2" .. suffix, {})
ffi.dlopen(path .. "cairo-gobject-2" .. suffix, {})
ffi.dlopen(path .. "cairo-script-interpreter-2" .. suffix, {})
ffi.dlopen(path .. "pango-1.0-0" .. suffix, {})
ffi.dlopen(path .. "pangoft2-1.0-0" .. suffix, {})
ffi.dlopen(path .. "pangowin32-1.0-0" .. suffix, {})
ffi.dlopen(path .. "pangocairo-1.0-0" .. suffix, {})
ffi.dlopen(path .. "gthread-2.0-0" .. suffix, {})
ffi.dlopen(path .. "epoxy-0" .. suffix, {}) -- OpenGL function loader (critical!)
ffi.dlopen(path .. "xml2-16" .. suffix, {}) -- XML parser
ffi.dlopen(path .. "rsvg-2-2" .. suffix, {}) -- SVG rendering (depends on many libs)
ffi.dlopen(path .. "sass" .. suffix, {}) -- CSS preprocessor
suffix = ffi.suffix

local gtk: funcs.Fns = ffi.dlopen(path .. libname, funcs)

return {
	lib = gtk,
	structs = structs,
	constants = constants,
	gio = gio,
	gobject = gobject,
}
