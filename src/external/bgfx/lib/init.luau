--!strict
--!optimize 2
-- Made by FFIGen (Kinemium)

local dll = "./src/external/bgfx/bin/"
local ffi = zune.ffi
local platform = zune.platform

local structs = require("./structs")
local funcs = require("./funcs")
local constants = require("./constants")

local libname
if platform.os == "windows" then
	libname = "bgfx.dll"
elseif platform.os == "linux" then
	libname = "bgfx.so"
elseif platform.os == "macos" then
	libname = "bgfx.dylib"
end

local bgfx: funcs.Fns = ffi.dlopen(dll .. libname, funcs)

return {
	lib = bgfx,
	structs = structs,
	constants = constants,
}
