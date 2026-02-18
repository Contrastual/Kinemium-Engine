--!strict
--!optimize 2

local dll = "./src/external/raylib/native/bin/"
local ffi = zune.ffi
local platform = zune.platform

local structs = require("./raybatch/structs")
local funcs = require("./raybatch/funcs")

local libname
if platform.os == "windows" then
	libname = "raybatch.dll"
elseif platform.os == "linux" then
	libname = "raybatch.so"
elseif platform.os == "macos" then
	libname = "raybatch.dylib"
end

local rl
if platform.os == "windows" then
	rl = "raylib.dll"
elseif platform.os == "linux" then
	rl = "raylib.so"
elseif platform.os == "macos" then
	rl = "raylib.dylib"
end

ffi.dlopen(dll .. rl, {})

local raybatch: funcs.Fns = ffi.dlopen(dll .. libname, funcs)

return {
	lib = raybatch,
	structs = structs,
}
