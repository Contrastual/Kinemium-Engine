--!strict
--!optimize 2

local dll = "./src/external/raylib/native/bin/"

local ffi = zune.ffi
local platform = zune.platform

local structs = require("./r3d/structs")
local funcs = require("./r3d/funcs")
local constants = require("./r3d/constants")

local libname
if platform.os == "windows" then
	libname = "r3d.dll"
elseif platform.os == "linux" then
	libname = "r3d.so"
elseif platform.os == "macos" then
	libname = "r3d.dylib"
end

local assimpname
if platform.os == "windows" then
	assimpname = "assimp-vc145-mt.dll"
elseif platform.os == "linux" then
	assimpname = "libassimp.so"
elseif platform.os == "macos" then
	assimpname = "libassimp.dylib"
end

local raylibname
if platform.os == "windows" then
	raylibname = "raylib.dll"
elseif platform.os == "linux" then
	raylibname = "libraylib.so"
elseif platform.os == "macos" then
	assimpname = "libassimp.dylib"
end

local raylib = ffi.dlopen(dll .. raylibname, {})
local assimp = ffi.dlopen(dll .. assimpname, {})
local r3d: typeof(funcs) = ffi.dlopen(dll .. libname, funcs)

return {
	lib = r3d,
	structs = structs,
	constants = constants,
}
